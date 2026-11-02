/*
    TEC-015 - Applicazione controllata degli adeguamenti
    Versione schema: 2026103002
    Prerequisito: versione 2026103001 (TEC-015-WORKFLOW).

    Lo script non contiene USE e deve essere eseguito sul database Preventivi
    dell'ambiente di destinazione dopo una copia di sicurezza verificata.
*/

SET NOCOUNT ON;
SET XACT_ABORT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;

BEGIN TRY
    BEGIN TRANSACTION;

    IF OBJECT_ID(N'dbo.VersioniSchema', N'U') IS NULL
        THROW 52990, 'TEC-015-APPLICAZIONE: registro VersioniSchema non disponibile.', 1;

    IF NOT EXISTS
    (
        SELECT 1
        FROM dbo.VersioniSchema
        WHERE Versione = 2026103001
          AND CodiceIntervento = N'TEC-015-WORKFLOW'
    )
        THROW 52991, 'TEC-015-APPLICAZIONE: versione richiesta 2026103001 non installata.', 1;

    IF EXISTS
    (
        SELECT 1
        FROM dbo.VersioniSchema
        WHERE Versione > 2026103001
          AND Versione <> 2026103002
    )
        THROW 52992, 'TEC-015-APPLICAZIONE: il database contiene una versione successiva non riconosciuta.', 1;

    IF OBJECT_ID(N'dbo.CampionatureAdeguamentiPreventivo', N'U') IS NULL
       OR OBJECT_ID(N'dbo.CampionatureRilievi', N'U') IS NULL
       OR OBJECT_ID(N'dbo.PreventiviVarianti', N'U') IS NULL
       OR OBJECT_ID(N'dbo.PreventiviRighe', N'U') IS NULL
       OR OBJECT_ID(N'dbo.PreventiviRigheComponenti', N'U') IS NULL
       OR OBJECT_ID(N'dbo.PreventiviRigheMateriali', N'U') IS NULL
       OR OBJECT_ID(N'dbo.PreventiviRigheLavorazioni', N'U') IS NULL
       OR COL_LENGTH(N'dbo.CampionatureAdeguamentiPreventivo', N'VersioneRiga') IS NULL
       OR COL_LENGTH(N'dbo.PreventiviRigheComponenti', N'IdRigaCompPrevPadre') IS NULL
       OR COL_LENGTH(N'dbo.PreventiviRigheMateriali', N'IdRigaCompPrev') IS NULL
       OR COL_LENGTH(N'dbo.PreventiviRigheLavorazioni', N'IdRigaCompPrev') IS NULL
       OR OBJECT_ID(N'dbo.sp_RicalcolaTotaliRigaPreventivo', N'P') IS NULL
       OR OBJECT_ID(N'dbo.sp_RicalcolaTotaliVariante', N'P') IS NULL
       OR OBJECT_ID(N'dbo.sp_RicalcolaTotaliPreventivo', N'P') IS NULL
        THROW 52993, 'TEC-015-APPLICAZIONE: struttura richiesta non disponibile.', 1;

    /* PAYLOAD TEC-015-APPLICAZIONE START */
    IF COL_LENGTH(N'dbo.CampionatureAdeguamentiPreventivo', N'IdVarianteGenerata') IS NULL
        EXEC sys.sp_executesql N'
        ALTER TABLE dbo.CampionatureAdeguamentiPreventivo
            ADD IdVarianteGenerata INT NULL;';

    IF COL_LENGTH(N'dbo.CampionatureAdeguamentiPreventivo', N'DataPreparazione') IS NULL
        EXEC sys.sp_executesql N'
        ALTER TABLE dbo.CampionatureAdeguamentiPreventivo
            ADD DataPreparazione DATETIME2(0) NULL;';

    IF COL_LENGTH(N'dbo.CampionatureAdeguamentiPreventivo', N'UtentePreparazione') IS NULL
        EXEC sys.sp_executesql N'
        ALTER TABLE dbo.CampionatureAdeguamentiPreventivo
            ADD UtentePreparazione NVARCHAR(256) NULL;';

    IF COL_LENGTH(N'dbo.CampionatureAdeguamentiPreventivo', N'UtenteApplicazione') IS NULL
        EXEC sys.sp_executesql N'
        ALTER TABLE dbo.CampionatureAdeguamentiPreventivo
            ADD UtenteApplicazione NVARCHAR(256) NULL;';

    EXEC sys.sp_executesql N'
    UPDATE dbo.CampionatureAdeguamentiPreventivo
    SET IdVarianteGenerata = IdVariantePreventivo,
        DataPreparazione = COALESCE(DataPreparazione, DataModifica, DataCreazione),
        UtentePreparazione = COALESCE(UtentePreparazione, UtenteModifica, UtenteCreazione),
        UtenteApplicazione = COALESCE(UtenteApplicazione, UtenteModifica, UtenteCreazione)
    WHERE Applicato = 1
      AND IdVarianteGenerata IS NULL
      AND IdVariantePreventivo IS NOT NULL;';

    IF NOT EXISTS
    (
        SELECT 1
        FROM sys.foreign_keys
        WHERE parent_object_id = OBJECT_ID(N'dbo.CampionatureAdeguamentiPreventivo')
          AND name = N'FK_CampionatureAdeguamenti_VarianteGenerata'
    )
        EXEC sys.sp_executesql N'
        ALTER TABLE dbo.CampionatureAdeguamentiPreventivo WITH CHECK
            ADD CONSTRAINT FK_CampionatureAdeguamenti_VarianteGenerata
            FOREIGN KEY (IdVarianteGenerata)
            REFERENCES dbo.PreventiviVarianti (IdVariantePreventivo);';

    EXEC sys.sp_executesql N'
    CREATE OR ALTER PROCEDURE dbo.Campionature_Adeguamenti_Elenco
        @IdCampionatura INT
    AS
    BEGIN
        SET NOCOUNT ON;

        SELECT
            adeguamento.IdAdeguamento,
            adeguamento.IdCampionatura,
            adeguamento.IdRilievoCampionatura,
            rilievo.RigaNr AS RigaNrRilievo,
            adeguamento.DescrizioneAdeguamento,
            adeguamento.ImpattoCostoStimato,
            adeguamento.ImpattoVenditaStimato,
            adeguamento.Applicato,
            adeguamento.DataApplicazione,
            adeguamento.IdVarianteGenerata,
            varianteGenerata.CodiceVariante AS CodiceVarianteGenerata
        FROM dbo.CampionatureAdeguamentiPreventivo AS adeguamento
        INNER JOIN dbo.CampionatureRilievi AS rilievo
            ON rilievo.IdRilievoCampionatura = adeguamento.IdRilievoCampionatura
        LEFT JOIN dbo.PreventiviVarianti AS varianteGenerata
            ON varianteGenerata.IdVariantePreventivo = adeguamento.IdVarianteGenerata
        WHERE adeguamento.IdCampionatura = @IdCampionatura
        ORDER BY adeguamento.IdAdeguamento DESC;
    END;';

    EXEC sys.sp_executesql N'
    CREATE OR ALTER PROCEDURE dbo.Campionature_Adeguamenti_Dettaglio
        @IdAdeguamento INT
    AS
    BEGIN
        SET NOCOUNT ON;

        SELECT
            adeguamento.IdAdeguamento,
            adeguamento.IdCampionatura,
            adeguamento.IdRilievoCampionatura,
            rilievo.RigaNr AS RigaNrRilievo,
            rilievo.DescrizioneProblema,
            adeguamento.IdPreventivo,
            adeguamento.IdVariantePreventivo,
            adeguamento.IdVarianteGenerata,
            varianteGenerata.CodiceVariante AS CodiceVarianteGenerata,
            varianteGenerata.DescrizioneVariante AS DescrizioneVarianteGenerata,
            adeguamento.DescrizioneAdeguamento,
            adeguamento.ImpattoCostoStimato,
            adeguamento.ImpattoVenditaStimato,
            adeguamento.Applicato,
            adeguamento.DataApplicazione,
            adeguamento.DataPreparazione,
            adeguamento.UtentePreparazione,
            adeguamento.UtenteApplicazione,
            adeguamento.Note,
            adeguamento.VersioneRiga,
            rilievo.VersioneRiga AS VersioneRilievo
        FROM dbo.CampionatureAdeguamentiPreventivo AS adeguamento
        INNER JOIN dbo.CampionatureRilievi AS rilievo
            ON rilievo.IdRilievoCampionatura = adeguamento.IdRilievoCampionatura
        LEFT JOIN dbo.PreventiviVarianti AS varianteGenerata
            ON varianteGenerata.IdVariantePreventivo = adeguamento.IdVarianteGenerata
        WHERE adeguamento.IdAdeguamento = @IdAdeguamento;
    END;';

    EXEC sys.sp_executesql N'
    CREATE OR ALTER PROCEDURE dbo.Campionature_Adeguamenti_Elimina
        @IdAdeguamento INT,
        @VersioneRiga BINARY(8),
        @VersioneRilievo BINARY(8),
        @Utente NVARCHAR(256)
    AS
    BEGIN
        SET NOCOUNT ON;
        SET XACT_ABORT ON;

        SET @Utente = NULLIF(LTRIM(RTRIM(@Utente)), N'''');
        IF @VersioneRiga IS NULL OR @VersioneRilievo IS NULL OR @Utente IS NULL
            THROW 52728, ''Dati obbligatori dell''''adeguamento mancanti.'', 1;

        BEGIN TRANSACTION;

        DECLARE @IdRilievoCampionatura INT;
        DECLARE @Applicato BIT;
        DECLARE @IdVarianteGenerata INT;
        DECLARE @VersioneAdeguamentoCorrente BINARY(8);
        DECLARE @VersioneRilievoCorrente BINARY(8);

        SELECT
            @IdRilievoCampionatura = adeguamento.IdRilievoCampionatura,
            @Applicato = adeguamento.Applicato,
            @IdVarianteGenerata = adeguamento.IdVarianteGenerata,
            @VersioneAdeguamentoCorrente = adeguamento.VersioneRiga
        FROM dbo.CampionatureAdeguamentiPreventivo AS adeguamento WITH (UPDLOCK, HOLDLOCK)
        WHERE adeguamento.IdAdeguamento = @IdAdeguamento;

        IF @IdRilievoCampionatura IS NULL
            THROW 52729, ''Adeguamento non trovato.'', 1;
        IF @VersioneAdeguamentoCorrente <> @VersioneRiga
            THROW 52730, ''L''''adeguamento e stato modificato da un altro utente.'', 1;
        IF @Applicato = 1
            THROW 52731, ''Un adeguamento applicato non puo essere eliminato.'', 1;
        IF @IdVarianteGenerata IS NOT NULL
            THROW 52751, ''Annullare prima la variante preparata.'', 1;
        IF EXISTS
        (
            SELECT 1
            FROM dbo.Allegati WITH (UPDLOCK, HOLDLOCK)
            WHERE Entita = N''CampionatureAdeguamenti''
              AND IdEntita = @IdAdeguamento
        )
            THROW 52737, ''L''''adeguamento possiede allegati e non puo essere eliminato.'', 1;

        SELECT @VersioneRilievoCorrente = VersioneRiga
        FROM dbo.CampionatureRilievi WITH (UPDLOCK, HOLDLOCK)
        WHERE IdRilievoCampionatura = @IdRilievoCampionatura;

        IF @VersioneRilievoCorrente IS NULL
            THROW 52723, ''Rilievo non trovato.'', 1;
        IF @VersioneRilievoCorrente <> @VersioneRilievo
            THROW 52724, ''Il rilievo e stato modificato da un altro utente.'', 1;

        DELETE FROM dbo.CampionatureAdeguamentiPreventivo
        WHERE IdAdeguamento = @IdAdeguamento
          AND VersioneRiga = @VersioneRiga;

        IF @@ROWCOUNT = 0
            THROW 52730, ''L''''adeguamento e stato modificato da un altro utente.'', 1;

        IF NOT EXISTS
        (
            SELECT 1
            FROM dbo.CampionatureAdeguamentiPreventivo
            WHERE IdRilievoCampionatura = @IdRilievoCampionatura
        )
        BEGIN
            UPDATE dbo.CampionatureRilievi
            SET RichiedeAdeguamentoPreventivo = 0,
                Stato = CASE WHEN Stato = N''Soluzione Proposta'' THEN N''In Analisi'' ELSE Stato END,
                DataChiusura = CASE WHEN Stato = N''Soluzione Proposta'' THEN NULL ELSE DataChiusura END,
                DataModifica = SYSDATETIME(),
                UtenteModifica = @Utente
            WHERE IdRilievoCampionatura = @IdRilievoCampionatura
              AND VersioneRiga = @VersioneRilievo;

            IF @@ROWCOUNT = 0
                THROW 52724, ''Il rilievo e stato modificato da un altro utente.'', 1;
        END;

        COMMIT TRANSACTION;
    END;';

    EXEC sys.sp_executesql N'
    CREATE OR ALTER PROCEDURE dbo.Campionature_Adeguamenti_PreparaVariante
        @IdAdeguamento INT,
        @CodiceVariante NVARCHAR(30),
        @DescrizioneVariante NVARCHAR(250),
        @VersioneRiga BINARY(8),
        @Utente NVARCHAR(256)
    AS
    BEGIN
        SET NOCOUNT ON;
        SET XACT_ABORT ON;

        SET @CodiceVariante = NULLIF(LTRIM(RTRIM(@CodiceVariante)), N'''');
        SET @DescrizioneVariante = NULLIF(LTRIM(RTRIM(@DescrizioneVariante)), N'''');
        SET @Utente = NULLIF(LTRIM(RTRIM(@Utente)), N'''');

        IF @CodiceVariante IS NULL OR @DescrizioneVariante IS NULL
           OR @VersioneRiga IS NULL OR @Utente IS NULL
            THROW 52740, ''Compilare tutti i dati obbligatori della variante.'', 1;

        BEGIN TRANSACTION;

        DECLARE @IdPreventivo INT;
        DECLARE @IdVarianteOrigine INT;
        DECLARE @IdVarianteGenerata INT;
        DECLARE @Applicato BIT;
        DECLARE @VersioneCorrente BINARY(8);

        SELECT
            @IdPreventivo = IdPreventivo,
            @IdVarianteOrigine = IdVariantePreventivo,
            @IdVarianteGenerata = IdVarianteGenerata,
            @Applicato = Applicato,
            @VersioneCorrente = VersioneRiga
        FROM dbo.CampionatureAdeguamentiPreventivo WITH (UPDLOCK, HOLDLOCK)
        WHERE IdAdeguamento = @IdAdeguamento;

        IF @VersioneCorrente IS NULL
            THROW 52740, ''Adeguamento non trovato.'', 1;
        IF @VersioneCorrente <> @VersioneRiga
            THROW 52741, ''L''''adeguamento e stato modificato da un altro utente.'', 1;
        IF @Applicato = 1
            THROW 52742, ''L''''adeguamento e gia applicato.'', 1;
        IF @IdVarianteGenerata IS NOT NULL
            THROW 52743, ''Esiste gia una variante preparata.'', 1;
        IF @IdPreventivo IS NULL
            THROW 52744, ''L''''adeguamento non e collegato a un preventivo.'', 1;

        IF NOT EXISTS
        (
            SELECT 1
            FROM dbo.Preventivi WITH (UPDLOCK, HOLDLOCK)
            WHERE IdPreventivo = @IdPreventivo
        )
            THROW 52744, ''Il preventivo collegato non esiste.'', 1;

        IF @IdVarianteOrigine IS NOT NULL
           AND NOT EXISTS
           (
               SELECT 1
               FROM dbo.PreventiviVarianti WITH (UPDLOCK, HOLDLOCK)
               WHERE IdVariantePreventivo = @IdVarianteOrigine
                 AND IdPreventivo = @IdPreventivo
                 AND Attiva = 1
           )
            THROW 52745, ''La variante origine non e disponibile.'', 1;

        IF EXISTS
        (
            SELECT 1
            FROM dbo.PreventiviVarianti WITH (UPDLOCK, HOLDLOCK)
            WHERE IdPreventivo = @IdPreventivo
              AND CodiceVariante = @CodiceVariante
        )
            THROW 52746, ''Il codice variante esiste gia per il preventivo.'', 1;

        INSERT INTO dbo.PreventiviVarianti
        (
            IdPreventivo, CodiceVariante, DescrizioneVariante, Note,
            VarianteScelta, Attiva, TotaleCosti, TotaleVendita,
            MargineValore, MarginePerc, DataCreazione
        )
        VALUES
        (
            @IdPreventivo, @CodiceVariante, @DescrizioneVariante,
            CONCAT(N''Generata dall''''adeguamento campionatura '', @IdAdeguamento),
            0, 1, 0, 0, 0, 0, SYSDATETIME()
        );

        SET @IdVarianteGenerata = CONVERT(INT, SCOPE_IDENTITY());

        DECLARE @RigaNrMassima INT;
        SELECT @RigaNrMassima = ISNULL(MAX(RigaNr), 0)
        FROM dbo.PreventiviRighe WITH (UPDLOCK, HOLDLOCK)
        WHERE IdPreventivo = @IdPreventivo;

        CREATE TABLE #MappaRighe
        (
            IdRigaOrigine INT NOT NULL PRIMARY KEY,
            IdRigaGenerata INT NOT NULL UNIQUE
        );

        ;WITH RigheOrigine AS
        (
            SELECT
                riga.*,
                @RigaNrMassima + ROW_NUMBER() OVER
                    (ORDER BY riga.RigaNr, riga.IdRigaPreventivo) AS NuovoRigaNr
            FROM dbo.PreventiviRighe AS riga WITH (HOLDLOCK)
            WHERE riga.IdPreventivo = @IdPreventivo
              AND
              (
                  (@IdVarianteOrigine IS NULL AND riga.IdVariantePreventivo IS NULL)
                  OR riga.IdVariantePreventivo = @IdVarianteOrigine
              )
        )
        MERGE dbo.PreventiviRighe AS destinazione
        USING RigheOrigine AS origine
            ON 1 = 0
        WHEN NOT MATCHED THEN
            INSERT
            (
                IdPreventivo, RigaNr, IdArticolo, IdModelloCiclo,
                DescrizioneVoce, Quantita, PrezzoUnitarioVendita,
                TotaleVendita, TotaleCosti, MargineValore, MarginePerc,
                Note, DataCreazione, DataModifica, MarkupPerc,
                PrezzoManuale, IdVariantePreventivo, CostoUnitarioLibero,
                IdTipoRiga
            )
            VALUES
            (
                origine.IdPreventivo, origine.NuovoRigaNr, origine.IdArticolo,
                origine.IdModelloCiclo, origine.DescrizioneVoce, origine.Quantita,
                origine.PrezzoUnitarioVendita, origine.TotaleVendita,
                origine.TotaleCosti, origine.MargineValore, origine.MarginePerc,
                origine.Note, SYSDATETIME(), NULL, origine.MarkupPerc,
                origine.PrezzoManuale, @IdVarianteGenerata,
                origine.CostoUnitarioLibero, origine.IdTipoRiga
            )
        OUTPUT origine.IdRigaPreventivo, inserted.IdRigaPreventivo
            INTO #MappaRighe (IdRigaOrigine, IdRigaGenerata);

        CREATE TABLE #MappaComponenti
        (
            IdComponenteOrigine INT NOT NULL PRIMARY KEY,
            IdComponenteGenerato INT NOT NULL UNIQUE
        );

        MERGE dbo.PreventiviRigheComponenti AS destinazione
        USING
        (
            SELECT
                componente.*,
                mappaRiga.IdRigaGenerata
            FROM dbo.PreventiviRigheComponenti AS componente WITH (HOLDLOCK)
            INNER JOIN #MappaRighe AS mappaRiga
                ON mappaRiga.IdRigaOrigine = componente.IdRigaPreventivo
        ) AS origine
            ON 1 = 0
        WHEN NOT MATCHED THEN
            INSERT
            (
                IdRigaPreventivo, IdNodoDistinta, IdNodoPadre,
                DescrizioneNodo, Livello, QuantitaBase, QuantitaCalcolata,
                OrdineVisualizzazione, IdRigaCompPrevPadre,
                TipoOrigineComponente, IdArticoloOrigine
            )
            VALUES
            (
                origine.IdRigaGenerata, origine.IdNodoDistinta,
                origine.IdNodoPadre, origine.DescrizioneNodo, origine.Livello,
                origine.QuantitaBase, origine.QuantitaCalcolata,
                origine.OrdineVisualizzazione, NULL,
                origine.TipoOrigineComponente, origine.IdArticoloOrigine
            )
        OUTPUT origine.IdRigaCompPrev, inserted.IdRigaCompPrev
            INTO #MappaComponenti (IdComponenteOrigine, IdComponenteGenerato);

        UPDATE componenteGenerato
        SET IdRigaCompPrevPadre = mappaPadre.IdComponenteGenerato
        FROM dbo.PreventiviRigheComponenti AS componenteGenerato
        INNER JOIN #MappaComponenti AS mappaComponente
            ON mappaComponente.IdComponenteGenerato = componenteGenerato.IdRigaCompPrev
        INNER JOIN dbo.PreventiviRigheComponenti AS componenteOrigine
            ON componenteOrigine.IdRigaCompPrev = mappaComponente.IdComponenteOrigine
        INNER JOIN #MappaComponenti AS mappaPadre
            ON mappaPadre.IdComponenteOrigine = componenteOrigine.IdRigaCompPrevPadre;

        INSERT INTO dbo.PreventiviRigheMateriali
        (
            IdRigaPreventivo, IdNodoDistinta, IdMateriale,
            DescrizioneMateriale, TipoMateriale, UM, Quantita,
            CostoUnitario, CostoTotale, DaAcquistare,
            IdFornitoreSuggerito, IdRigaCompPrev
        )
        SELECT
            mappaRiga.IdRigaGenerata, materiale.IdNodoDistinta,
            materiale.IdMateriale, materiale.DescrizioneMateriale,
            materiale.TipoMateriale, materiale.UM, materiale.Quantita,
            materiale.CostoUnitario, materiale.CostoTotale,
            materiale.DaAcquistare, materiale.IdFornitoreSuggerito,
            mappaComponente.IdComponenteGenerato
        FROM dbo.PreventiviRigheMateriali AS materiale WITH (HOLDLOCK)
        INNER JOIN #MappaRighe AS mappaRiga
            ON mappaRiga.IdRigaOrigine = materiale.IdRigaPreventivo
        LEFT JOIN #MappaComponenti AS mappaComponente
            ON mappaComponente.IdComponenteOrigine = materiale.IdRigaCompPrev;

        INSERT INTO dbo.PreventiviRigheLavorazioni
        (
            IdRigaPreventivo, IdNodoDistinta, IdLavorazione,
            DescrizioneLavorazione, Sequenza, TempoSetupMin,
            TempoPezzoMin, Quantita, TempoTotaleMin, CostoOrario,
            CostoFisso, CostoTotale, DaAcquistareEsterno,
            IdFornitoreSuggerito, IdRigaCompPrev
        )
        SELECT
            mappaRiga.IdRigaGenerata, lavorazione.IdNodoDistinta,
            lavorazione.IdLavorazione, lavorazione.DescrizioneLavorazione,
            lavorazione.Sequenza, lavorazione.TempoSetupMin,
            lavorazione.TempoPezzoMin, lavorazione.Quantita,
            lavorazione.TempoTotaleMin, lavorazione.CostoOrario,
            lavorazione.CostoFisso, lavorazione.CostoTotale,
            lavorazione.DaAcquistareEsterno,
            lavorazione.IdFornitoreSuggerito,
            mappaComponente.IdComponenteGenerato
        FROM dbo.PreventiviRigheLavorazioni AS lavorazione WITH (HOLDLOCK)
        INNER JOIN #MappaRighe AS mappaRiga
            ON mappaRiga.IdRigaOrigine = lavorazione.IdRigaPreventivo
        LEFT JOIN #MappaComponenti AS mappaComponente
            ON mappaComponente.IdComponenteOrigine = lavorazione.IdRigaCompPrev;

        DECLARE @IdRigaGenerata INT;
        DECLARE righeGenerate CURSOR LOCAL FAST_FORWARD FOR
            SELECT IdRigaGenerata FROM #MappaRighe ORDER BY IdRigaGenerata;
        OPEN righeGenerate;
        FETCH NEXT FROM righeGenerate INTO @IdRigaGenerata;
        WHILE @@FETCH_STATUS = 0
        BEGIN
            EXEC dbo.sp_RicalcolaTotaliRigaPreventivo
                @IdRigaPreventivo = @IdRigaGenerata;
            FETCH NEXT FROM righeGenerate INTO @IdRigaGenerata;
        END;
        CLOSE righeGenerate;
        DEALLOCATE righeGenerate;

        EXEC dbo.sp_RicalcolaTotaliVariante
            @IdVariantePreventivo = @IdVarianteGenerata;
        EXEC dbo.sp_RicalcolaTotaliPreventivo
            @IdPreventivo = @IdPreventivo;

        UPDATE dbo.CampionatureAdeguamentiPreventivo
        SET IdVarianteGenerata = @IdVarianteGenerata,
            DataPreparazione = SYSDATETIME(),
            UtentePreparazione = @Utente,
            DataModifica = SYSDATETIME(),
            UtenteModifica = @Utente
        WHERE IdAdeguamento = @IdAdeguamento
          AND VersioneRiga = @VersioneRiga;

        IF @@ROWCOUNT = 0
            THROW 52741, ''L''''adeguamento e stato modificato da un altro utente.'', 1;

        COMMIT TRANSACTION;
        SELECT @IdVarianteGenerata;
    END;';

    EXEC sys.sp_executesql N'
    CREATE OR ALTER PROCEDURE dbo.Campionature_Adeguamenti_Preparazione_Annulla
        @IdAdeguamento INT,
        @VersioneRiga BINARY(8),
        @Utente NVARCHAR(256)
    AS
    BEGIN
        SET NOCOUNT ON;
        SET XACT_ABORT ON;

        SET @Utente = NULLIF(LTRIM(RTRIM(@Utente)), N'''');
        IF @VersioneRiga IS NULL OR @Utente IS NULL
            THROW 52740, ''Dati obbligatori mancanti.'', 1;

        BEGIN TRANSACTION;

        DECLARE @IdPreventivo INT;
        DECLARE @IdVarianteGenerata INT;
        DECLARE @Applicato BIT;
        DECLARE @VersioneCorrente BINARY(8);

        SELECT
            @IdPreventivo = IdPreventivo,
            @IdVarianteGenerata = IdVarianteGenerata,
            @Applicato = Applicato,
            @VersioneCorrente = VersioneRiga
        FROM dbo.CampionatureAdeguamentiPreventivo WITH (UPDLOCK, HOLDLOCK)
        WHERE IdAdeguamento = @IdAdeguamento;

        IF @VersioneCorrente IS NULL
            THROW 52740, ''Adeguamento non trovato.'', 1;
        IF @VersioneCorrente <> @VersioneRiga
            THROW 52741, ''L''''adeguamento e stato modificato da un altro utente.'', 1;
        IF @Applicato = 1
            THROW 52742, ''L''''adeguamento e gia applicato.'', 1;
        IF @IdVarianteGenerata IS NULL
            THROW 52750, ''Non esiste una preparazione da annullare.'', 1;

        UPDATE dbo.PreventiviVarianti
        SET VarianteScelta = 0,
            Attiva = 0,
            DataModifica = SYSDATETIME()
        WHERE IdVariantePreventivo = @IdVarianteGenerata
          AND IdPreventivo = @IdPreventivo
          AND Attiva = 1;

        IF @@ROWCOUNT = 0
            THROW 52747, ''La variante preparata non e disponibile.'', 1;

        UPDATE dbo.CampionatureAdeguamentiPreventivo
        SET IdVarianteGenerata = NULL,
            DataPreparazione = NULL,
            UtentePreparazione = NULL,
            DataModifica = SYSDATETIME(),
            UtenteModifica = @Utente
        WHERE IdAdeguamento = @IdAdeguamento
          AND VersioneRiga = @VersioneRiga;

        IF @@ROWCOUNT = 0
            THROW 52741, ''L''''adeguamento e stato modificato da un altro utente.'', 1;

        EXEC dbo.sp_RicalcolaTotaliPreventivo
            @IdPreventivo = @IdPreventivo;

        COMMIT TRANSACTION;
    END;';

    EXEC sys.sp_executesql N'
    CREATE OR ALTER PROCEDURE dbo.Campionature_Adeguamenti_Applicazione_Conferma
        @IdAdeguamento INT,
        @VersioneRiga BINARY(8),
        @VersioneRilievo BINARY(8),
        @Utente NVARCHAR(256)
    AS
    BEGIN
        SET NOCOUNT ON;
        SET XACT_ABORT ON;

        SET @Utente = NULLIF(LTRIM(RTRIM(@Utente)), N'''');
        IF @VersioneRiga IS NULL OR @VersioneRilievo IS NULL OR @Utente IS NULL
            THROW 52740, ''Dati obbligatori mancanti.'', 1;

        BEGIN TRANSACTION;

        DECLARE @IdPreventivo INT;
        DECLARE @IdRilievoCampionatura INT;
        DECLARE @IdVarianteGenerata INT;
        DECLARE @Applicato BIT;
        DECLARE @VersioneCorrente BINARY(8);
        DECLARE @VersioneRilievoCorrente BINARY(8);
        DECLARE @StatoRilievo NVARCHAR(30);

        SELECT
            @IdPreventivo = IdPreventivo,
            @IdRilievoCampionatura = IdRilievoCampionatura,
            @IdVarianteGenerata = IdVarianteGenerata,
            @Applicato = Applicato,
            @VersioneCorrente = VersioneRiga
        FROM dbo.CampionatureAdeguamentiPreventivo WITH (UPDLOCK, HOLDLOCK)
        WHERE IdAdeguamento = @IdAdeguamento;

        IF @VersioneCorrente IS NULL
            THROW 52740, ''Adeguamento non trovato.'', 1;
        IF @VersioneCorrente <> @VersioneRiga
            THROW 52741, ''L''''adeguamento e stato modificato da un altro utente.'', 1;
        IF @Applicato = 1
            THROW 52742, ''L''''adeguamento e gia applicato.'', 1;
        IF @IdVarianteGenerata IS NULL
            THROW 52747, ''La variante preparata non e disponibile.'', 1;
        IF NOT EXISTS
        (
            SELECT 1
            FROM dbo.PreventiviVarianti WITH (UPDLOCK, HOLDLOCK)
            WHERE IdVariantePreventivo = @IdVarianteGenerata
              AND IdPreventivo = @IdPreventivo
              AND Attiva = 1
        )
            THROW 52747, ''La variante preparata non e disponibile.'', 1;

        SELECT
            @VersioneRilievoCorrente = VersioneRiga,
            @StatoRilievo = Stato
        FROM dbo.CampionatureRilievi WITH (UPDLOCK, HOLDLOCK)
        WHERE IdRilievoCampionatura = @IdRilievoCampionatura;

        IF @VersioneRilievoCorrente IS NULL
            THROW 52723, ''Rilievo non trovato.'', 1;
        IF @VersioneRilievoCorrente <> @VersioneRilievo
            THROW 52749, ''Il rilievo e stato modificato da un altro utente.'', 1;
        IF @StatoRilievo <> N''Soluzione Proposta''
            THROW 52748, ''Il rilievo deve essere in Soluzione Proposta.'', 1;

        DECLARE @IdRigaPreventivo INT;
        DECLARE righeVariante CURSOR LOCAL FAST_FORWARD FOR
            SELECT IdRigaPreventivo
            FROM dbo.PreventiviRighe WITH (HOLDLOCK)
            WHERE IdPreventivo = @IdPreventivo
              AND IdVariantePreventivo = @IdVarianteGenerata
            ORDER BY IdRigaPreventivo;
        OPEN righeVariante;
        FETCH NEXT FROM righeVariante INTO @IdRigaPreventivo;
        WHILE @@FETCH_STATUS = 0
        BEGIN
            EXEC dbo.sp_RicalcolaTotaliRigaPreventivo
                @IdRigaPreventivo = @IdRigaPreventivo;
            FETCH NEXT FROM righeVariante INTO @IdRigaPreventivo;
        END;
        CLOSE righeVariante;
        DEALLOCATE righeVariante;

        EXEC dbo.sp_RicalcolaTotaliVariante
            @IdVariantePreventivo = @IdVarianteGenerata;
        EXEC dbo.sp_RicalcolaTotaliPreventivo
            @IdPreventivo = @IdPreventivo;

        UPDATE dbo.CampionatureAdeguamentiPreventivo
        SET Applicato = 1,
            DataApplicazione = CONVERT(DATE, GETDATE()),
            UtenteApplicazione = @Utente,
            DataModifica = SYSDATETIME(),
            UtenteModifica = @Utente
        WHERE IdAdeguamento = @IdAdeguamento
          AND VersioneRiga = @VersioneRiga;

        IF @@ROWCOUNT = 0
            THROW 52741, ''L''''adeguamento e stato modificato da un altro utente.'', 1;

        UPDATE dbo.CampionatureRilievi
        SET Stato = N''Risolto'',
            DataChiusura = NULL,
            DataModifica = SYSDATETIME(),
            UtenteModifica = @Utente
        WHERE IdRilievoCampionatura = @IdRilievoCampionatura
          AND VersioneRiga = @VersioneRilievo;

        IF @@ROWCOUNT = 0
            THROW 52749, ''Il rilievo e stato modificato da un altro utente.'', 1;

        COMMIT TRANSACTION;
    END;';

    EXEC sys.sp_executesql N'
    CREATE OR ALTER PROCEDURE dbo.Preventivi_Varianti_Elimina
        @IdVariantePreventivo INT
    AS
    BEGIN
        SET NOCOUNT ON;
        SET XACT_ABORT ON;

        DECLARE @IdPreventivo INT;

        BEGIN TRANSACTION;

        SELECT @IdPreventivo = IdPreventivo
        FROM dbo.PreventiviVarianti WITH (UPDLOCK, HOLDLOCK)
        WHERE IdVariantePreventivo = @IdVariantePreventivo
          AND Attiva = 1;

        IF @IdPreventivo IS NULL
            THROW 51954, ''Variante preventivo non trovata o non attiva.'', 1;

        IF EXISTS
        (
            SELECT 1
            FROM dbo.CampionatureAdeguamentiPreventivo WITH (UPDLOCK, HOLDLOCK)
            WHERE IdVarianteGenerata = @IdVariantePreventivo
        )
            THROW 52752, ''La variante e collegata a un adeguamento di campionatura.'', 1;

        UPDATE dbo.PreventiviVarianti
        SET VarianteScelta = 0,
            Attiva = 0,
            DataModifica = SYSDATETIME()
        WHERE IdVariantePreventivo = @IdVariantePreventivo;

        EXEC dbo.sp_RicalcolaTotaliPreventivo
            @IdPreventivo = @IdPreventivo;

        COMMIT TRANSACTION;
    END;';
    /* PAYLOAD TEC-015-APPLICAZIONE END */

    DECLARE @Versione INT = 2026103002;
    DECLARE @CodiceIntervento NVARCHAR(50) = N'TEC-015-APPLICAZIONE';
    DECLARE @NomeScript NVARCHAR(260) = N'TEC-015_04_Applicazione_Adeguamenti.sql';
    -- SHA-256 del contenuto fra i marcatori PAYLOAD inclusi, normalizzato con LF.
    DECLARE @ImprontaSha256 CHAR(64) = '2C36C5F5D6EEAB388413D4A41A677AD22DDE169B6FA744CF3B2A0063081607B3';

    IF EXISTS
    (
        SELECT 1
        FROM dbo.VersioniSchema
        WHERE Versione = @Versione
          AND CodiceIntervento = @CodiceIntervento
          AND NomeScript = @NomeScript
          AND ImprontaSha256 = @ImprontaSha256
    )
    BEGIN
        COMMIT TRANSACTION;
        RETURN;
    END;

    IF EXISTS
    (
        SELECT 1
        FROM dbo.VersioniSchema
        WHERE Versione = @Versione
           OR CodiceIntervento = @CodiceIntervento
           OR NomeScript = @NomeScript
    )
        THROW 52999, 'TEC-015-APPLICAZIONE: versione gia registrata con dati o impronta differenti.', 1;

    INSERT INTO dbo.VersioniSchema
    (
        Versione,
        CodiceIntervento,
        NomeScript,
        Descrizione,
        ImprontaSha256
    )
    VALUES
    (
        @Versione,
        @CodiceIntervento,
        @NomeScript,
        N'Applicazione controllata degli adeguamenti tramite variante dedicata.',
        @ImprontaSha256
    );

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0
        ROLLBACK TRANSACTION;
    THROW;
END CATCH;
