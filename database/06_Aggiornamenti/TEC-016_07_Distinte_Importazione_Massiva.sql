/*
    TEC-016 - Importazione massiva distinte base (decisione 334)
    Versione schema: 2026111203
    Prerequisito: versione 2026111202 (TEC-016-DISTINTE-REVISIONI).

    Eseguire sul database Preventivi dell'ambiente di destinazione dopo una
    copia di sicurezza verificata. Lo script non contiene USE.
*/

SET NOCOUNT ON;
SET XACT_ABORT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET NUMERIC_ROUNDABORT OFF;

BEGIN TRY
    BEGIN TRANSACTION;

    IF OBJECT_ID(N'dbo.VersioniSchema', N'U') IS NULL
        THROW 53790, 'TEC-016-IMPORTAZIONE: registro VersioniSchema non disponibile.', 1;

    IF NOT EXISTS
    (
        SELECT 1 FROM dbo.VersioniSchema
        WHERE Versione = 2026111202
          AND CodiceIntervento = N'TEC-016-DISTINTE-REVISIONI'
    )
        THROW 53791, 'TEC-016-IMPORTAZIONE: versione richiesta 2026111202 non installata.', 1;

    IF EXISTS
    (
        SELECT 1 FROM dbo.VersioniSchema
        WHERE Versione > 2026111202
          AND Versione <> 2026111203
    )
        THROW 53792, 'TEC-016-IMPORTAZIONE: il database contiene una versione successiva non riconosciuta.', 1;

    IF OBJECT_ID(N'dbo.DistinteBaseRevisioni', N'U') IS NULL
       OR OBJECT_ID(N'dbo.DistinteBase', N'U') IS NULL
       OR OBJECT_ID(N'dbo.DistintaBaseNodi', N'U') IS NULL
       OR OBJECT_ID(N'dbo.DistintaMateriali', N'U') IS NULL
       OR OBJECT_ID(N'dbo.DistintaLavorazioni', N'U') IS NULL
       OR OBJECT_ID(N'dbo.TipiNodoDistinta', N'U') IS NULL
       OR OBJECT_ID(N'dbo.Materiali', N'U') IS NULL
       OR OBJECT_ID(N'dbo.Lavorazioni', N'U') IS NULL
        THROW 53793, 'TEC-016-IMPORTAZIONE: tabelle richieste non disponibili.', 1;

    /* PAYLOAD TEC-016-DISTINTE-IMPORTAZIONE START */
    IF TYPE_ID(N'dbo.TVP_DistintaImportazioneNodi') IS NULL
        EXEC sys.sp_executesql N'
        CREATE TYPE dbo.TVP_DistintaImportazioneNodi AS TABLE
        (
            RigaExcel INT NOT NULL,
            ChiaveNodo NVARCHAR(50) NOT NULL,
            ChiavePadre NVARCHAR(50) NULL,
            TipoNodo NVARCHAR(100) NOT NULL,
            CodiceNodo NVARCHAR(50) NULL,
            DescrizioneNodo NVARCHAR(200) NOT NULL,
            QuantitaBase DECIMAL(18,4) NOT NULL,
            OrdineVisualizzazione INT NOT NULL,
            Attivo BIT NOT NULL,
            Note NVARCHAR(500) NULL
        );';

    IF TYPE_ID(N'dbo.TVP_DistintaImportazioneMateriali') IS NULL
        EXEC sys.sp_executesql N'
        CREATE TYPE dbo.TVP_DistintaImportazioneMateriali AS TABLE
        (
            RigaExcel INT NOT NULL,
            ChiaveNodo NVARCHAR(50) NOT NULL,
            CodiceMateriale NVARCHAR(50) NOT NULL,
            Quantita DECIMAL(18,4) NOT NULL,
            CoeffScartoPerc DECIMAL(9,2) NOT NULL,
            CostoUnitario DECIMAL(18,4) NOT NULL,
            Note NVARCHAR(500) NULL
        );';

    IF TYPE_ID(N'dbo.TVP_DistintaImportazioneLavorazioni') IS NULL
        EXEC sys.sp_executesql N'
        CREATE TYPE dbo.TVP_DistintaImportazioneLavorazioni AS TABLE
        (
            RigaExcel INT NOT NULL,
            ChiaveNodo NVARCHAR(50) NOT NULL,
            CodiceLavorazione NVARCHAR(50) NOT NULL,
            Sequenza INT NOT NULL,
            TempoSetupMin DECIMAL(18,2) NOT NULL,
            TempoPezzoMin DECIMAL(18,4) NOT NULL,
            CostoOrario DECIMAL(18,4) NOT NULL,
            CostoFisso DECIMAL(18,4) NOT NULL,
            Note NVARCHAR(500) NULL
        );';

    IF OBJECT_ID(N'dbo.DistinteBaseImportazioni', N'U') IS NULL
    BEGIN
        CREATE TABLE dbo.DistinteBaseImportazioni
        (
            IdImportazione UNIQUEIDENTIFIER NOT NULL
                CONSTRAINT PK_DistinteBaseImportazioni PRIMARY KEY,
            IdRevisioneDistinta INT NOT NULL,
            NomeFile NVARCHAR(260) NOT NULL,
            ImprontaSha256 CHAR(64) NOT NULL,
            NumeroNodi INT NOT NULL,
            NumeroMateriali INT NOT NULL,
            NumeroLavorazioni INT NOT NULL,
            DataImportazione DATETIME2(0) NOT NULL,
            Utente NVARCHAR(256) NOT NULL,
            CONSTRAINT FK_DistinteBaseImportazioni_Revisioni
                FOREIGN KEY (IdRevisioneDistinta)
                REFERENCES dbo.DistinteBaseRevisioni(IdRevisioneDistinta),
            CONSTRAINT UQ_DistinteBaseImportazioni_RevisioneImpronta
                UNIQUE (IdRevisioneDistinta, ImprontaSha256),
            CONSTRAINT CK_DistinteBaseImportazioni_Conteggi
                CHECK (NumeroNodi > 0 AND NumeroMateriali >= 0 AND NumeroLavorazioni >= 0)
        );
    END;

    EXEC sys.sp_executesql N'
    CREATE OR ALTER PROCEDURE dbo.Anagrafiche_Distinte_Importazioni_Applica
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

        IF @IdImportazione IS NULL OR @IdRevisioneDistinta <= 0
           OR @NomeFile IS NULL OR LEN(@NomeFile) > 260
           OR @ImprontaSha256 IS NULL OR LEN(@ImprontaSha256) <> 64
           OR @ImprontaSha256 LIKE ''%[^0-9A-F]%''
           OR @Utente IS NULL OR DATALENGTH(@VersioneRiga) <> 8
           OR NOT EXISTS (SELECT 1 FROM @Nodi)
            THROW 53701, ''Dati importazione non validi.'', 1;

        BEGIN TRANSACTION;

        DECLARE @IdArticolo INT;
        SELECT @IdArticolo = distinta.IdArticolo
        FROM dbo.DistinteBaseRevisioni AS revisione WITH (UPDLOCK, HOLDLOCK)
        INNER JOIN dbo.DistinteBase AS distinta
            ON distinta.IdDistintaBase = revisione.IdDistintaBase
        WHERE revisione.IdRevisioneDistinta = @IdRevisioneDistinta
          AND revisione.Stato = N''Bozza'';

        IF @IdArticolo IS NULL
            THROW 53702, ''Revisione non trovata o non modificabile.'', 1;
        IF NOT EXISTS
        (
            SELECT 1 FROM dbo.DistinteBaseRevisioni
            WHERE IdRevisioneDistinta = @IdRevisioneDistinta
              AND VersioneRiga = @VersioneRiga
        )
            THROW 53703, ''Revisione modificata da altro utente.'', 1;
        IF EXISTS
        (
            SELECT 1 FROM dbo.DistintaBaseNodi WITH (UPDLOCK, HOLDLOCK)
            WHERE IdRevisioneDistinta = @IdRevisioneDistinta
        )
            THROW 53704, ''La revisione deve essere vuota.'', 1;
        IF EXISTS
        (
            SELECT 1 FROM dbo.DistinteBaseImportazioni WITH (UPDLOCK, HOLDLOCK)
            WHERE IdRevisioneDistinta = @IdRevisioneDistinta
              AND ImprontaSha256 = @ImprontaSha256
        )
            THROW 53705, ''File gia importato nella revisione.'', 1;

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
                SELECT COUNT(*) FROM dbo.TipiNodoDistinta AS tipo
                WHERE tipo.Descrizione = sorgente.TipoNodo AND tipo.Attivo = 1
            ) <> 1
        )
           OR EXISTS
              (
                  SELECT 1 FROM @Materiali AS sorgente
                  WHERE
                  (
                      SELECT COUNT(*) FROM dbo.Materiali AS materiale
                      WHERE materiale.CodiceMateriale = sorgente.CodiceMateriale
                        AND materiale.Attivo = 1
                  ) <> 1
              )
           OR EXISTS
              (
                  SELECT 1 FROM @Lavorazioni AS sorgente
                  WHERE
                  (
                      SELECT COUNT(*) FROM dbo.Lavorazioni AS lavorazione
                      WHERE lavorazione.CodiceLavorazione = sorgente.CodiceLavorazione
                        AND lavorazione.Attiva = 1
                  ) <> 1
              )
            THROW 53707, ''Anagrafiche non valide o non attive.'', 1;

        IF EXISTS
        (
            SELECT 1 FROM @Nodi
            WHERE QuantitaBase <= 0 OR OrdineVisualizzazione < 0
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
            THROW 53703, ''Revisione modificata durante l importazione.'', 1;

        COMMIT TRANSACTION;
    END;';
    /* PAYLOAD TEC-016-DISTINTE-IMPORTAZIONE END */

    DECLARE @Versione INT = 2026111203;
    DECLARE @CodiceIntervento NVARCHAR(50) = N'TEC-016-DISTINTE-IMPORTAZIONE';
    DECLARE @NomeScript NVARCHAR(260) = N'TEC-016_07_Distinte_Importazione_Massiva.sql';
    -- SHA-256 del contenuto fra i marcatori PAYLOAD inclusi, normalizzato con LF.
    DECLARE @ImprontaSha256 CHAR(64) = 'E51CB0F8A391AFADF49AFFFE7B58DC785F64F6C7896A6191C9D64E2460A53747';

    IF EXISTS
    (
        SELECT 1 FROM dbo.VersioniSchema
        WHERE Versione = @Versione AND CodiceIntervento = @CodiceIntervento
          AND NomeScript = @NomeScript AND ImprontaSha256 = @ImprontaSha256
    )
    BEGIN
        COMMIT TRANSACTION;
        RETURN;
    END;

    IF EXISTS
    (
        SELECT 1 FROM dbo.VersioniSchema
        WHERE Versione = @Versione OR CodiceIntervento = @CodiceIntervento
           OR NomeScript = @NomeScript
    )
        THROW 53799, 'TEC-016-IMPORTAZIONE: versione gia registrata con dati o impronta differenti.', 1;

    INSERT dbo.VersioniSchema
    (
        Versione, CodiceIntervento, NomeScript,
        Descrizione, ImprontaSha256
    )
    VALUES
    (
        @Versione, @CodiceIntervento, @NomeScript,
        N'Importazione massiva e transazionale delle distinte base da Excel.',
        @ImprontaSha256
    );

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
