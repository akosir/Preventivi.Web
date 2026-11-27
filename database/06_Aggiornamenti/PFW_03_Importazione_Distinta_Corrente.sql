-- Decisioni 387-391: importazione sulla distinta corrente vuota.
-- Non modifica le distinte esistenti e non aggiorna i preventivi.
SET NOCOUNT ON;
SET XACT_ABORT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET NUMERIC_ROUNDABORT OFF;
BEGIN TRY
    BEGIN TRANSACTION;
    DECLARE @Versione INT=2026112601;
    DECLARE @Codice NVARCHAR(50)=N'PFW-IMPORT-DISTINTE-CORRENTI';
    DECLARE @Script NVARCHAR(260)=N'PFW_03_Importazione_Distinta_Corrente.sql';
    -- SHA-256 del payload: righe LF, Trim, UTF-8.
    DECLARE @Impronta CHAR(64)='18FCB6FE249069953AA391C4717C5B6355B709927FF573A174DE62F679CE1A44';
    IF OBJECT_ID(N'dbo.VersioniSchema',N'U') IS NULL THROW 54710,'Registro VersioniSchema assente.',1;
    IF NOT EXISTS(SELECT 1 FROM dbo.VersioniSchema WITH(UPDLOCK,HOLDLOCK)
        WHERE Versione=2026112506 AND CodiceIntervento=N'PFW-IMPORT-ARTICOLI')
        THROW 54710,'Prerequisito 2026112506 non installato.',1;
    IF EXISTS(SELECT 1 FROM dbo.VersioniSchema WHERE Versione>@Versione)
        THROW 54710,'Il database contiene una versione successiva.',1;
    IF EXISTS(SELECT 1 FROM dbo.VersioniSchema WHERE Versione=@Versione AND CodiceIntervento=@Codice AND NomeScript=@Script AND ImprontaSha256=@Impronta)
    BEGIN COMMIT TRANSACTION; RETURN; END;
    IF EXISTS(SELECT 1 FROM dbo.VersioniSchema WHERE Versione=@Versione OR CodiceIntervento=@Codice OR NomeScript=@Script)
        THROW 54710,'Versione registrata con metadati differenti.',1;
/* PAYLOAD PFW-IMPORT-DISTINTE-CORRENTI START */
IF OBJECT_ID(N'dbo.DistinteBaseImportazioni',N'U') IS NULL
        OR OBJECT_ID(N'dbo.Anagrafiche_Distinte_Importazioni_Applica',N'P') IS NULL
        THROW 54710,'Prerequisiti importazione distinta assenti.',1;
    IF OBJECT_ID(N'dbo.DistinteBaseImportazioniEsiti',N'U') IS NOT NULL
        THROW 54710,'Registro esiti gia presente senza la versione prevista.',1;
    -- Il registro storico dei successi resta invariato. Il registro aggiuntivo
    -- conserva tutti i nuovi tentativi, anche dopo il rollback o la rimozione del padre.
    CREATE TABLE dbo.DistinteBaseImportazioniEsiti(
        IdEsito BIGINT IDENTITY NOT NULL CONSTRAINT PK_DistinteBaseImportazioniEsiti PRIMARY KEY,
        IdImportazione UNIQUEIDENTIFIER NOT NULL,IdRevisioneDistinta INT NOT NULL,IdArticolo INT NULL,
        NomeFile NVARCHAR(260) NOT NULL,ImprontaSha256 CHAR(64) NOT NULL,Utente NVARCHAR(256) NOT NULL,
        DataOperazione DATETIME2(0) NOT NULL,Stato NVARCHAR(12) NOT NULL,
        NumeroNodi INT NOT NULL,NumeroMateriali INT NOT NULL,NumeroLavorazioni INT NOT NULL,
        Messaggio NVARCHAR(2048) NOT NULL,
        CONSTRAINT CK_DistinteBaseImportazioniEsiti_Stato CHECK(Stato IN(N'Completata',N'Rifiutata')),
        CONSTRAINT CK_DistinteBaseImportazioniEsiti_Conteggi CHECK(
            (Stato=N'Completata' AND NumeroNodi>0 AND NumeroMateriali>=0 AND NumeroLavorazioni>=0)
            OR (Stato=N'Rifiutata' AND NumeroNodi=0 AND NumeroMateriali=0 AND NumeroLavorazioni=0)));
    CREATE INDEX IX_DistinteBaseImportazioniEsiti_DistintaData
        ON dbo.DistinteBaseImportazioniEsiti(IdRevisioneDistinta,DataOperazione);
    EXEC sys.sp_executesql N'CREATE OR ALTER PROCEDURE dbo.Anagrafiche_Distinte_Importazioni_Applica
        @IdImportazione UNIQUEIDENTIFIER,
        @IdRevisioneDistinta INT,
        @NomeFile NVARCHAR(260),
        @ImprontaSha256 CHAR(64),
        @Utente NVARCHAR(256),
        @VersioneRiga BINARY(8),
        @Nodi dbo.TVP_DistintaImportazioneNodi READONLY,
        @Materiali dbo.TVP_DistintaImportazioneMateriali READONLY,
        @Lavorazioni dbo.TVP_DistintaImportazioneLavorazioni READONLY
    AS
    BEGIN
        SET NOCOUNT ON;
        SET XACT_ABORT ON;

        SELECT @NomeFile = NULLIF(LTRIM(RTRIM(@NomeFile)), N''''),
            @ImprontaSha256 = UPPER(NULLIF(LTRIM(RTRIM(@ImprontaSha256)), N'''')),
            @Utente = NULLIF(LTRIM(RTRIM(@Utente)), N'''');

        IF @IdImportazione IS NULL OR @IdImportazione = ''00000000-0000-0000-0000-000000000000'' OR @IdRevisioneDistinta IS NULL OR @IdRevisioneDistinta <= 0
           OR @NomeFile IS NULL OR LEN(@NomeFile) > 260
           OR @ImprontaSha256 IS NULL OR LEN(@ImprontaSha256) <> 64
           OR @ImprontaSha256 LIKE ''%[^0-9A-F]%''
           OR @Utente IS NULL OR @VersioneRiga IS NULL OR DATALENGTH(@VersioneRiga) <> 8
           OR NOT EXISTS (SELECT 1 FROM @Nodi)
            THROW 53701, ''Dati importazione non validi.'', 1;

        IF @@TRANCOUNT <> 0 THROW 53701, ''Avviare l importazione senza una transazione esterna.'', 1;
        DECLARE @IdArticolo INT;
        BEGIN TRY
        BEGIN TRANSACTION;
        DECLARE @Risorsa NVARCHAR(255)=CONCAT(N''PFW-Importazione-Distinta-'',@IdRevisioneDistinta), @Blocco INT;
        EXEC @Blocco=sys.sp_getapplock @Resource=@Risorsa,@LockMode=N''Exclusive'',@LockOwner=N''Transaction'',@LockTimeout=10000;
        IF @Blocco < 0 THROW 53703, ''Importazione in corso. Generare una nuova anteprima.'', 1;
        SELECT @IdArticolo = distinta.IdArticolo
        FROM dbo.DistinteBaseRevisioni AS revisione WITH (UPDLOCK, HOLDLOCK)
        INNER JOIN dbo.DistinteBase AS distinta WITH (UPDLOCK, HOLDLOCK)
            ON distinta.IdDistintaBase = revisione.IdDistintaBase
        INNER JOIN dbo.Articoli AS articolo WITH (UPDLOCK, HOLDLOCK)
            ON articolo.IdArticolo = distinta.IdArticolo
        WHERE revisione.IdRevisioneDistinta = @IdRevisioneDistinta
          AND revisione.Stato = N''Pubblicata'' AND articolo.Attivo = 1;

        IF @IdArticolo IS NULL
            THROW 53702, ''Distinta corrente non disponibile o articolo non attivo.'', 1;
        IF NOT EXISTS
        (
            SELECT 1 FROM dbo.DistinteBaseRevisioni
            WHERE IdRevisioneDistinta = @IdRevisioneDistinta
              AND VersioneRiga = @VersioneRiga
        )
            THROW 53703, ''Distinta corrente modificata dopo l anteprima.'', 1;
        IF EXISTS
        (
            SELECT 1 FROM dbo.DistintaBaseNodi WITH (UPDLOCK, HOLDLOCK)
            WHERE IdRevisioneDistinta = @IdRevisioneDistinta
        )
            THROW 53704, ''La distinta deve essere vuota.'', 1;
        IF EXISTS
        (
            SELECT 1 FROM dbo.DistinteBaseImportazioni WITH (UPDLOCK, HOLDLOCK)
            WHERE IdImportazione = @IdImportazione
               OR (IdRevisioneDistinta = @IdRevisioneDistinta AND ImprontaSha256 = @ImprontaSha256)
        )
            THROW 53705, ''File o operazione gia importati nella distinta corrente.'', 1;

        IF (SELECT COUNT(*) FROM @Nodi WHERE ChiavePadre IS NULL) <> 1
           OR EXISTS (SELECT 1 FROM @Nodi WHERE ChiavePadre IS NULL AND Attivo = 0)
           OR EXISTS (SELECT ChiaveNodo FROM @Nodi GROUP BY ChiaveNodo HAVING COUNT(*) > 1)
           OR EXISTS
              (
                  SELECT 1 FROM @Nodi AS figlio
                  LEFT JOIN @Nodi AS padre ON padre.ChiaveNodo = figlio.ChiavePadre
                  WHERE figlio.ChiavePadre IS NOT NULL
                    AND (padre.ChiaveNodo IS NULL OR figlio.ChiaveNodo = figlio.ChiavePadre)
              )
           OR EXISTS
              (
                  SELECT 1 FROM @Nodi AS figlio
                  INNER JOIN @Nodi AS padre ON padre.ChiaveNodo = figlio.ChiavePadre
                  WHERE figlio.Attivo = 1 AND padre.Attivo = 0
              )
            THROW 53706, ''Gerarchia dei nodi non valida.'', 1;

        DECLARE @NodiRaggiunti INT;
        ;WITH Albero AS
        (
            SELECT ChiaveNodo
            FROM @Nodi WHERE ChiavePadre IS NULL
            UNION ALL
            SELECT figlio.ChiaveNodo
            FROM @Nodi AS figlio
            INNER JOIN Albero AS padre ON padre.ChiaveNodo = figlio.ChiavePadre
        )
        SELECT @NodiRaggiunti = COUNT(*) FROM Albero OPTION (MAXRECURSION 32767);
        IF @NodiRaggiunti <> (SELECT COUNT(*) FROM @Nodi)
            THROW 53706, ''Gerarchia ciclica o non raggiungibile dalla radice.'', 1;

        IF EXISTS
        (
            SELECT 1 FROM @Nodi AS sorgente
            WHERE
            (
                SELECT COUNT(*) FROM dbo.TipiNodoDistinta AS tipo WITH (UPDLOCK, HOLDLOCK)
                WHERE tipo.Descrizione = sorgente.TipoNodo AND tipo.Attivo = 1
            ) <> 1
        )
           OR EXISTS
              (
                  SELECT 1 FROM @Materiali AS sorgente
                  WHERE
                  (
                      SELECT COUNT(*) FROM dbo.Materiali AS materiale WITH (UPDLOCK, HOLDLOCK)
                      WHERE materiale.CodiceMateriale = sorgente.CodiceMateriale
                        AND materiale.Attivo = 1
                  ) <> 1
              )
           OR EXISTS
              (
                  SELECT 1 FROM @Lavorazioni AS sorgente
                  WHERE
                  (
                      SELECT COUNT(*) FROM dbo.Lavorazioni AS lavorazione WITH (UPDLOCK, HOLDLOCK)
                      WHERE lavorazione.CodiceLavorazione = sorgente.CodiceLavorazione
                        AND lavorazione.Attiva = 1
                  ) <> 1
              )
            THROW 53707, ''Anagrafiche non valide o non attive.'', 1;

        IF EXISTS
        (
            SELECT 1 FROM @Nodi
            WHERE NULLIF(LTRIM(RTRIM(ChiaveNodo)),N'''') IS NULL OR NULLIF(LTRIM(RTRIM(DescrizioneNodo)),N'''') IS NULL OR QuantitaBase <= 0 OR OrdineVisualizzazione < 0
        )
           OR EXISTS
              (
                  SELECT 1 FROM @Materiali AS materiale
                  LEFT JOIN @Nodi AS nodo ON nodo.ChiaveNodo = materiale.ChiaveNodo
                  WHERE nodo.ChiaveNodo IS NULL OR materiale.Quantita <= 0
                     OR materiale.CoeffScartoPerc < 0 OR materiale.CostoUnitario < 0
              )
           OR EXISTS
              (
                  SELECT ChiaveNodo, CodiceMateriale FROM @Materiali
                  GROUP BY ChiaveNodo, CodiceMateriale HAVING COUNT(*) > 1
              )
           OR EXISTS
              (
                  SELECT 1 FROM @Lavorazioni AS lavorazione
                  LEFT JOIN @Nodi AS nodo ON nodo.ChiaveNodo = lavorazione.ChiaveNodo
                  WHERE nodo.ChiaveNodo IS NULL OR lavorazione.Sequenza <= 0
                     OR lavorazione.TempoSetupMin < 0 OR lavorazione.TempoPezzoMin < 0
                     OR lavorazione.CostoOrario < 0 OR lavorazione.CostoFisso < 0
              )
           OR EXISTS
              (
                  SELECT ChiaveNodo, Sequenza FROM @Lavorazioni
                  GROUP BY ChiaveNodo, Sequenza HAVING COUNT(*) > 1
              )
            THROW 53708, ''Valori o riferimenti del file non validi.'', 1;

        DECLARE @Mappa TABLE
        (
            ChiaveNodo NVARCHAR(50) NOT NULL PRIMARY KEY,
            IdNodoDistinta INT NOT NULL
        );
        DECLARE @Livelli TABLE
        (
            ChiaveNodo NVARCHAR(50) NOT NULL PRIMARY KEY,
            Livello INT NOT NULL
        );

        ;WITH AlberoLivelli AS
        (
            SELECT ChiaveNodo, 0 AS Livello
            FROM @Nodi WHERE ChiavePadre IS NULL
            UNION ALL
            SELECT figlio.ChiaveNodo, padre.Livello + 1
            FROM @Nodi AS figlio
            INNER JOIN AlberoLivelli AS padre ON padre.ChiaveNodo = figlio.ChiavePadre
        )
        INSERT @Livelli (ChiaveNodo, Livello)
        SELECT ChiaveNodo, Livello FROM AlberoLivelli OPTION (MAXRECURSION 32767);

        DECLARE @LivelloCorrente INT = 0,
                @LivelloMassimo INT = (SELECT MAX(Livello) FROM @Livelli);
        WHILE @LivelloCorrente <= @LivelloMassimo
        BEGIN
            MERGE dbo.DistintaBaseNodi AS destinazione
            USING
            (
                SELECT nodo.*, livello.Livello, tipo.IdTipoNodo,
                       padre.IdNodoDistinta AS IdNodoPadre
                FROM @Nodi AS nodo
                INNER JOIN @Livelli AS livello ON livello.ChiaveNodo = nodo.ChiaveNodo
                INNER JOIN dbo.TipiNodoDistinta AS tipo
                    ON tipo.Descrizione = nodo.TipoNodo AND tipo.Attivo = 1
                LEFT JOIN @Mappa AS padre ON padre.ChiaveNodo = nodo.ChiavePadre
                WHERE livello.Livello = @LivelloCorrente
            ) AS sorgente ON 1 = 0
            WHEN NOT MATCHED THEN
                INSERT
                (
                    IdArticolo, IdRevisioneDistinta, IdNodoPadre, IdTipoNodo,
                    CodiceNodo, DescrizioneNodo, QuantitaBase, Livello,
                    OrdineVisualizzazione, Attivo, Note, DataCreazione,
                    DataModifica, UtenteCreazione, UtenteModifica
                )
                VALUES
                (
                    @IdArticolo, @IdRevisioneDistinta, sorgente.IdNodoPadre,
                    sorgente.IdTipoNodo, sorgente.CodiceNodo,
                    sorgente.DescrizioneNodo, sorgente.QuantitaBase,
                    sorgente.Livello, sorgente.OrdineVisualizzazione,
                    sorgente.Attivo, sorgente.Note, SYSDATETIME(), NULL,
                    @Utente, NULL
                )
            OUTPUT sorgente.ChiaveNodo, inserted.IdNodoDistinta
                INTO @Mappa (ChiaveNodo, IdNodoDistinta);
            SET @LivelloCorrente += 1;
        END;

        IF (SELECT COUNT(*) FROM @Mappa) <> (SELECT COUNT(*) FROM @Nodi)
            THROW 53709, ''Conteggio dei nodi importati non corrispondente.'', 1;

        INSERT dbo.DistintaMateriali
        (
            IdNodoDistinta, IdMateriale, Quantita, CoeffScartoPerc,
            CostoUnitario, Note, DataCreazione, DataModifica,
            UtenteCreazione, UtenteModifica
        )
        SELECT mappa.IdNodoDistinta, materiale.IdMateriale,
               sorgente.Quantita, sorgente.CoeffScartoPerc,
               sorgente.CostoUnitario, sorgente.Note,
               SYSDATETIME(), NULL, @Utente, NULL
        FROM @Materiali AS sorgente
        INNER JOIN @Mappa AS mappa ON mappa.ChiaveNodo = sorgente.ChiaveNodo
        INNER JOIN dbo.Materiali AS materiale
            ON materiale.CodiceMateriale = sorgente.CodiceMateriale
           AND materiale.Attivo = 1;

        DECLARE @MaterialiInseriti INT=@@ROWCOUNT;
        IF @MaterialiInseriti <> (SELECT COUNT(*) FROM @Materiali)
            THROW 53709, ''Conteggio dei materiali importati non corrispondente.'', 1;

        INSERT dbo.DistintaLavorazioni
        (
            IdNodoDistinta, IdLavorazione, Sequenza, TempoSetupMin,
            TempoPezzoMin, CostoOrario, CostoFisso, IdModelloCiclo,
            Note, DataCreazione, DataModifica, UtenteCreazione, UtenteModifica
        )
        SELECT mappa.IdNodoDistinta, lavorazione.IdLavorazione,
               sorgente.Sequenza, sorgente.TempoSetupMin,
               sorgente.TempoPezzoMin, sorgente.CostoOrario,
               sorgente.CostoFisso, NULL, sorgente.Note,
               SYSDATETIME(), NULL, @Utente, NULL
        FROM @Lavorazioni AS sorgente
        INNER JOIN @Mappa AS mappa ON mappa.ChiaveNodo = sorgente.ChiaveNodo
        INNER JOIN dbo.Lavorazioni AS lavorazione
            ON lavorazione.CodiceLavorazione = sorgente.CodiceLavorazione
           AND lavorazione.Attiva = 1;

        DECLARE @LavorazioniInserite INT=@@ROWCOUNT;
        IF @LavorazioniInserite <> (SELECT COUNT(*) FROM @Lavorazioni)
            THROW 53709, ''Conteggio delle lavorazioni importate non corrispondente.'', 1;

        INSERT dbo.DistinteBaseImportazioni
        (
            IdImportazione, IdRevisioneDistinta, NomeFile,
            ImprontaSha256, NumeroNodi, NumeroMateriali,
            NumeroLavorazioni, DataImportazione, Utente
        )
        VALUES
        (
            @IdImportazione, @IdRevisioneDistinta, @NomeFile,
            @ImprontaSha256, (SELECT COUNT(*) FROM @Nodi),
            (SELECT COUNT(*) FROM @Materiali),
            (SELECT COUNT(*) FROM @Lavorazioni), SYSDATETIME(), @Utente
        );

        UPDATE dbo.DistinteBaseRevisioni
        SET DataModifica = SYSDATETIME(), UtenteModifica = @Utente
        WHERE IdRevisioneDistinta = @IdRevisioneDistinta
          AND VersioneRiga = @VersioneRiga;
        IF @@ROWCOUNT <> 1
            THROW 53703, ''Distinta corrente modificata durante l importazione.'', 1;

        INSERT dbo.DistinteBaseImportazioniEsiti(IdImportazione,IdRevisioneDistinta,IdArticolo,NomeFile,
            ImprontaSha256,Utente,DataOperazione,Stato,NumeroNodi,NumeroMateriali,NumeroLavorazioni,Messaggio)
        VALUES(@IdImportazione,@IdRevisioneDistinta,@IdArticolo,@NomeFile,@ImprontaSha256,@Utente,SYSDATETIME(),
            N''Completata'',(SELECT COUNT(*) FROM @Nodi),@MaterialiInseriti,@LavorazioniInserite,N''Importazione completata.'');
        COMMIT TRANSACTION;
        END TRY
        BEGIN CATCH
            DECLARE @Messaggio NVARCHAR(2048)=LEFT(ERROR_MESSAGE(),2048);
            IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
            INSERT dbo.DistinteBaseImportazioniEsiti(IdImportazione,IdRevisioneDistinta,IdArticolo,NomeFile,
                ImprontaSha256,Utente,DataOperazione,Stato,NumeroNodi,NumeroMateriali,NumeroLavorazioni,Messaggio)
            VALUES(@IdImportazione,@IdRevisioneDistinta,@IdArticolo,@NomeFile,@ImprontaSha256,@Utente,SYSDATETIME(),
                N''Rifiutata'',0,0,0,@Messaggio);
            THROW;
        END CATCH;
    END;';
    EXEC sys.sp_executesql N'CREATE OR ALTER TRIGGER dbo.TR_DistinteBaseImportazioniEsiti_Immutabili
        ON dbo.DistinteBaseImportazioniEsiti INSTEAD OF UPDATE, DELETE AS
        BEGIN SET NOCOUNT ON; THROW 54711,''Il registro degli esiti non puo essere modificato o eliminato.'',1; END;';
/* PAYLOAD PFW-IMPORT-DISTINTE-CORRENTI END */
    INSERT dbo.VersioniSchema(Versione,CodiceIntervento,NomeScript,Descrizione,ImprontaSha256)
        VALUES(@Versione,@Codice,@Script,N'Importazione controllata distinta corrente vuota e registro degli esiti.',@Impronta);
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
