/*
    TEC-016 - Materiali e lavorazioni
    Versione schema: 2026110302
    Prerequisito: versione 2026110301 (TEC-016-ANAGRAFICHE-BASE).

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
        THROW 53290, 'TEC-016: registro VersioniSchema non disponibile.', 1;

    IF NOT EXISTS
    (
        SELECT 1
        FROM dbo.VersioniSchema
        WHERE Versione = 2026110301
          AND CodiceIntervento = N'TEC-016-ANAGRAFICHE-BASE'
    )
        THROW 53291, 'TEC-016: versione richiesta 2026110301 non installata.', 1;

    IF EXISTS
    (
        SELECT 1
        FROM dbo.VersioniSchema
        WHERE Versione > 2026110301
          AND Versione <> 2026110302
    )
        THROW 53292, 'TEC-016: il database contiene una versione successiva non riconosciuta.', 1;

    IF OBJECT_ID(N'dbo.Materiali', N'U') IS NULL
       OR OBJECT_ID(N'dbo.Lavorazioni', N'U') IS NULL
       OR OBJECT_ID(N'dbo.UnitaMisura', N'U') IS NULL
       OR OBJECT_ID(N'dbo.Fornitori', N'U') IS NULL
       OR OBJECT_ID(N'dbo.DistintaMateriali', N'U') IS NULL
       OR OBJECT_ID(N'dbo.DistintaLavorazioni', N'U') IS NULL
       OR OBJECT_ID(N'dbo.FornitoriMateriali', N'U') IS NULL
       OR OBJECT_ID(N'dbo.FornitoriLavorazioni', N'U') IS NULL
       OR OBJECT_ID(N'dbo.OrdiniFornitoriRighe', N'U') IS NULL
       OR OBJECT_ID(N'dbo.RichiesteOffertaFornitoriRighe', N'U') IS NULL
       OR OBJECT_ID(N'dbo.PreventiviRigheMateriali', N'U') IS NULL
       OR OBJECT_ID(N'dbo.PreventiviRigheLavorazioni', N'U') IS NULL
       OR OBJECT_ID(N'dbo.ModelliCicloRighe', N'U') IS NULL
        THROW 53293, 'TEC-016: tabelle richieste non disponibili.', 1;

    /* PAYLOAD TEC-016-MATERIALI-LAVORAZIONI START */
    IF COL_LENGTH(N'dbo.Materiali', N'UtenteCreazione') IS NULL
        EXEC sys.sp_executesql N'ALTER TABLE dbo.Materiali ADD UtenteCreazione NVARCHAR(256) NULL;';

    EXEC sys.sp_executesql N'
        UPDATE dbo.Materiali
        SET UtenteCreazione = N''MIGRAZIONE-TEC-016''
        WHERE UtenteCreazione IS NULL;
        ALTER TABLE dbo.Materiali ALTER COLUMN UtenteCreazione NVARCHAR(256) NOT NULL;';

    IF COL_LENGTH(N'dbo.Materiali', N'UtenteModifica') IS NULL
        EXEC sys.sp_executesql N'ALTER TABLE dbo.Materiali ADD UtenteModifica NVARCHAR(256) NULL;';

    IF COL_LENGTH(N'dbo.Materiali', N'VersioneRiga') IS NULL
        EXEC sys.sp_executesql N'ALTER TABLE dbo.Materiali ADD VersioneRiga ROWVERSION NOT NULL;';

    IF COL_LENGTH(N'dbo.Lavorazioni', N'DataCreazione') IS NULL
        EXEC sys.sp_executesql N'ALTER TABLE dbo.Lavorazioni ADD DataCreazione DATETIME2(0) NULL;';

    EXEC sys.sp_executesql N'
        UPDATE dbo.Lavorazioni
        SET DataCreazione = SYSDATETIME()
        WHERE DataCreazione IS NULL;
        ALTER TABLE dbo.Lavorazioni ALTER COLUMN DataCreazione DATETIME2(0) NOT NULL;';

    IF NOT EXISTS
    (
        SELECT 1
        FROM sys.default_constraints AS vincolo
        INNER JOIN sys.columns AS colonna
            ON colonna.object_id = vincolo.parent_object_id
           AND colonna.column_id = vincolo.parent_column_id
        WHERE vincolo.parent_object_id = OBJECT_ID(N'dbo.Lavorazioni')
          AND colonna.name = N'DataCreazione'
    )
        EXEC sys.sp_executesql N'
        ALTER TABLE dbo.Lavorazioni
            ADD CONSTRAINT DF_Lavorazioni_DataCreazione DEFAULT SYSDATETIME() FOR DataCreazione;';

    IF COL_LENGTH(N'dbo.Lavorazioni', N'DataModifica') IS NULL
        EXEC sys.sp_executesql N'ALTER TABLE dbo.Lavorazioni ADD DataModifica DATETIME2(0) NULL;';

    IF COL_LENGTH(N'dbo.Lavorazioni', N'UtenteCreazione') IS NULL
        EXEC sys.sp_executesql N'ALTER TABLE dbo.Lavorazioni ADD UtenteCreazione NVARCHAR(256) NULL;';

    EXEC sys.sp_executesql N'
        UPDATE dbo.Lavorazioni
        SET UtenteCreazione = N''MIGRAZIONE-TEC-016''
        WHERE UtenteCreazione IS NULL;
        ALTER TABLE dbo.Lavorazioni ALTER COLUMN UtenteCreazione NVARCHAR(256) NOT NULL;';

    IF COL_LENGTH(N'dbo.Lavorazioni', N'UtenteModifica') IS NULL
        EXEC sys.sp_executesql N'ALTER TABLE dbo.Lavorazioni ADD UtenteModifica NVARCHAR(256) NULL;';

    IF COL_LENGTH(N'dbo.Lavorazioni', N'VersioneRiga') IS NULL
        EXEC sys.sp_executesql N'ALTER TABLE dbo.Lavorazioni ADD VersioneRiga ROWVERSION NOT NULL;';

    EXEC sys.sp_executesql N'
    CREATE OR ALTER PROCEDURE dbo.Anagrafiche_UnitaMisura_Lookup
        @IdCorrente INT = NULL
    AS
    BEGIN
        SET NOCOUNT ON;
        SELECT IdUM, CodiceUM, Descrizione, Attivo
        FROM dbo.UnitaMisura
        WHERE Attivo = 1 OR IdUM = @IdCorrente
        ORDER BY CodiceUM;
    END;';

    EXEC sys.sp_executesql N'
    CREATE OR ALTER PROCEDURE dbo.Anagrafiche_Fornitori_Lookup
        @IdCorrente INT = NULL
    AS
    BEGIN
        SET NOCOUNT ON;
        SELECT IdFornitore, CodiceFornitore, RagioneSociale, Attivo
        FROM dbo.Fornitori
        WHERE Attivo = 1 OR IdFornitore = @IdCorrente
        ORDER BY RagioneSociale, CodiceFornitore;
    END;';

    EXEC sys.sp_executesql N'
    CREATE OR ALTER PROCEDURE dbo.Anagrafiche_Materiali_Elenco
        @Ricerca NVARCHAR(200) = NULL,
        @SoloAttivi BIT = NULL,
        @TipoMateriale NVARCHAR(30) = NULL
    AS
    BEGIN
        SET NOCOUNT ON;
        DECLARE @Filtro NVARCHAR(200) = NULLIF(LTRIM(RTRIM(@Ricerca)), N'''');
        SET @TipoMateriale = NULLIF(LTRIM(RTRIM(@TipoMateriale)), N'''');

        SELECT materiale.IdMateriale,
               materiale.CodiceMateriale,
               materiale.Descrizione,
               materiale.TipoMateriale,
               um.CodiceUM,
               materiale.CostoUnitario,
               materiale.GestitoAAcquisto,
               materiale.Attivo
        FROM dbo.Materiali AS materiale
        INNER JOIN dbo.UnitaMisura AS um ON um.IdUM = materiale.IdUM
        WHERE (@SoloAttivi IS NULL OR materiale.Attivo = @SoloAttivi)
          AND (@TipoMateriale IS NULL OR materiale.TipoMateriale = @TipoMateriale)
          AND
          (
              @Filtro IS NULL
              OR materiale.CodiceMateriale LIKE N''%'' + @Filtro + N''%''
              OR materiale.Descrizione LIKE N''%'' + @Filtro + N''%''
          )
        ORDER BY materiale.CodiceMateriale;
    END;';

    EXEC sys.sp_executesql N'
    CREATE OR ALTER PROCEDURE dbo.Anagrafiche_Materiali_Dettaglio
        @IdMateriale INT
    AS
    BEGIN
        SET NOCOUNT ON;
        SELECT materiale.IdMateriale,
               materiale.CodiceMateriale,
               materiale.Descrizione,
               materiale.IdUM,
               um.CodiceUM,
               um.Descrizione AS DescrizioneUM,
               materiale.TipoMateriale,
               materiale.CostoUnitario,
               materiale.GestitoAAcquisto,
               materiale.IdFornitorePredefinito,
               CASE WHEN fornitore.IdFornitore IS NULL THEN NULL
                    ELSE fornitore.CodiceFornitore + N'' - '' + fornitore.RagioneSociale END AS FornitorePredefinito,
               materiale.Attivo,
               materiale.Note,
               materiale.DataCreazione,
               materiale.DataModifica,
               materiale.UtenteCreazione,
               materiale.UtenteModifica,
               materiale.VersioneRiga
        FROM dbo.Materiali AS materiale
        INNER JOIN dbo.UnitaMisura AS um ON um.IdUM = materiale.IdUM
        LEFT JOIN dbo.Fornitori AS fornitore ON fornitore.IdFornitore = materiale.IdFornitorePredefinito
        WHERE materiale.IdMateriale = @IdMateriale;
    END;';

    EXEC sys.sp_executesql N'
    CREATE OR ALTER PROCEDURE dbo.Anagrafiche_Materiali_Crea
        @CodiceMateriale NVARCHAR(50),
        @Descrizione NVARCHAR(200),
        @IdUM INT,
        @TipoMateriale NVARCHAR(30),
        @CostoUnitario DECIMAL(18,4),
        @GestitoAAcquisto BIT,
        @IdFornitorePredefinito INT = NULL,
        @Note NVARCHAR(500) = NULL,
        @Utente NVARCHAR(256)
    AS
    BEGIN
        SET NOCOUNT ON;
        SET XACT_ABORT ON;
        SET @CodiceMateriale = NULLIF(LTRIM(RTRIM(@CodiceMateriale)), N'''');
        SET @Descrizione = NULLIF(LTRIM(RTRIM(@Descrizione)), N'''');
        SET @TipoMateriale = NULLIF(LTRIM(RTRIM(@TipoMateriale)), N'''');
        SET @Note = NULLIF(LTRIM(RTRIM(@Note)), N'''');
        SET @Utente = NULLIF(LTRIM(RTRIM(@Utente)), N'''');

        IF @CodiceMateriale IS NULL OR @Descrizione IS NULL OR @IdUM IS NULL OR @IdUM <= 0
           OR @TipoMateriale IS NULL
           OR @TipoMateriale NOT IN (N''MateriaPrima'', N''Accessorio'', N''Semilavorato'')
           OR @CostoUnitario IS NULL OR @CostoUnitario < 0
           OR @GestitoAAcquisto IS NULL OR @Utente IS NULL
            THROW 53201, ''Dati materiale non validi.'', 1;
        IF @GestitoAAcquisto = 0 AND @IdFornitorePredefinito IS NOT NULL
            THROW 53205, ''Fornitore non ammesso per materiale non gestito ad acquisto.'', 1;

        BEGIN TRANSACTION;
        IF NOT EXISTS (SELECT 1 FROM dbo.UnitaMisura WITH (UPDLOCK, HOLDLOCK) WHERE IdUM = @IdUM AND Attivo = 1)
            THROW 53203, ''Unita di misura non valida o non attiva.'', 1;
        IF @IdFornitorePredefinito IS NOT NULL
           AND NOT EXISTS (SELECT 1 FROM dbo.Fornitori WITH (UPDLOCK, HOLDLOCK) WHERE IdFornitore = @IdFornitorePredefinito AND Attivo = 1)
            THROW 53204, ''Fornitore non valido o non attivo.'', 1;
        IF EXISTS (SELECT 1 FROM dbo.Materiali WITH (UPDLOCK, HOLDLOCK) WHERE CodiceMateriale = @CodiceMateriale)
            THROW 53202, ''Codice materiale gia utilizzato.'', 1;

        INSERT INTO dbo.Materiali
        (
            CodiceMateriale, Descrizione, IdUM, TipoMateriale, CostoUnitario,
            GestitoAAcquisto, IdFornitorePredefinito, Attivo, Note,
            DataCreazione, DataModifica, UtenteCreazione, UtenteModifica
        )
        VALUES
        (
            @CodiceMateriale, @Descrizione, @IdUM, @TipoMateriale, @CostoUnitario,
            @GestitoAAcquisto, @IdFornitorePredefinito, 1, @Note,
            SYSDATETIME(), NULL, @Utente, NULL
        );
        DECLARE @IdMateriale INT = CONVERT(INT, SCOPE_IDENTITY());
        COMMIT TRANSACTION;
        SELECT @IdMateriale;
    END;';

    EXEC sys.sp_executesql N'
    CREATE OR ALTER PROCEDURE dbo.Anagrafiche_Materiali_Aggiorna
        @IdMateriale INT,
        @CodiceMateriale NVARCHAR(50),
        @Descrizione NVARCHAR(200),
        @IdUM INT,
        @TipoMateriale NVARCHAR(30),
        @CostoUnitario DECIMAL(18,4),
        @GestitoAAcquisto BIT,
        @IdFornitorePredefinito INT = NULL,
        @Note NVARCHAR(500) = NULL,
        @Utente NVARCHAR(256),
        @VersioneRiga BINARY(8)
    AS
    BEGIN
        SET NOCOUNT ON;
        SET XACT_ABORT ON;
        SET @CodiceMateriale = NULLIF(LTRIM(RTRIM(@CodiceMateriale)), N'''');
        SET @Descrizione = NULLIF(LTRIM(RTRIM(@Descrizione)), N'''');
        SET @TipoMateriale = NULLIF(LTRIM(RTRIM(@TipoMateriale)), N'''');
        SET @Note = NULLIF(LTRIM(RTRIM(@Note)), N'''');
        SET @Utente = NULLIF(LTRIM(RTRIM(@Utente)), N'''');

        IF @CodiceMateriale IS NULL OR @Descrizione IS NULL OR @IdUM IS NULL OR @IdUM <= 0
           OR @TipoMateriale IS NULL
           OR @TipoMateriale NOT IN (N''MateriaPrima'', N''Accessorio'', N''Semilavorato'')
           OR @CostoUnitario IS NULL OR @CostoUnitario < 0
           OR @GestitoAAcquisto IS NULL OR @Utente IS NULL
            THROW 53201, ''Dati materiale non validi.'', 1;
        IF @GestitoAAcquisto = 0 AND @IdFornitorePredefinito IS NOT NULL
            THROW 53205, ''Fornitore non ammesso per materiale non gestito ad acquisto.'', 1;

        BEGIN TRANSACTION;
        DECLARE @IdUMCorrente INT;
        DECLARE @IdFornitoreCorrente INT;
        SELECT @IdUMCorrente = IdUM,
               @IdFornitoreCorrente = IdFornitorePredefinito
        FROM dbo.Materiali WITH (UPDLOCK, HOLDLOCK)
        WHERE IdMateriale = @IdMateriale;
        IF @IdUMCorrente IS NULL
            THROW 53206, ''Materiale non trovato.'', 1;
        IF NOT EXISTS
        (
            SELECT 1 FROM dbo.UnitaMisura WITH (UPDLOCK, HOLDLOCK)
            WHERE IdUM = @IdUM AND (Attivo = 1 OR IdUM = @IdUMCorrente)
        )
            THROW 53203, ''Unita di misura non valida o non attiva.'', 1;
        IF @IdFornitorePredefinito IS NOT NULL
           AND NOT EXISTS
           (
               SELECT 1 FROM dbo.Fornitori WITH (UPDLOCK, HOLDLOCK)
               WHERE IdFornitore = @IdFornitorePredefinito
                 AND (Attivo = 1 OR IdFornitore = @IdFornitoreCorrente)
           )
            THROW 53204, ''Fornitore non valido o non attivo.'', 1;
        IF EXISTS
        (
            SELECT 1 FROM dbo.Materiali WITH (UPDLOCK, HOLDLOCK)
            WHERE CodiceMateriale = @CodiceMateriale AND IdMateriale <> @IdMateriale
        )
            THROW 53202, ''Codice materiale gia utilizzato.'', 1;

        UPDATE dbo.Materiali
        SET CodiceMateriale = @CodiceMateriale,
            Descrizione = @Descrizione,
            IdUM = @IdUM,
            TipoMateriale = @TipoMateriale,
            CostoUnitario = @CostoUnitario,
            GestitoAAcquisto = @GestitoAAcquisto,
            IdFornitorePredefinito = @IdFornitorePredefinito,
            Note = @Note,
            DataModifica = SYSDATETIME(),
            UtenteModifica = @Utente
        WHERE IdMateriale = @IdMateriale
          AND VersioneRiga = @VersioneRiga;
        IF @@ROWCOUNT = 0
            THROW 53207, ''Materiale modificato da un altro utente.'', 1;
        COMMIT TRANSACTION;
    END;';

    EXEC sys.sp_executesql N'
    CREATE OR ALTER PROCEDURE dbo.Anagrafiche_Materiali_ImpostaStato
        @IdMateriale INT,
        @Attivo BIT,
        @Utente NVARCHAR(256),
        @VersioneRiga BINARY(8)
    AS
    BEGIN
        SET NOCOUNT ON;
        SET @Utente = NULLIF(LTRIM(RTRIM(@Utente)), N'''');
        IF @Attivo IS NULL OR @Utente IS NULL
            THROW 53201, ''Utente obbligatorio.'', 1;
        UPDATE dbo.Materiali
        SET Attivo = @Attivo,
            DataModifica = SYSDATETIME(),
            UtenteModifica = @Utente
        WHERE IdMateriale = @IdMateriale
          AND VersioneRiga = @VersioneRiga;
        IF @@ROWCOUNT = 0
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM dbo.Materiali WHERE IdMateriale = @IdMateriale)
                THROW 53206, ''Materiale non trovato.'', 1;
            THROW 53207, ''Materiale modificato da un altro utente.'', 1;
        END;
    END;';

    EXEC sys.sp_executesql N'
    CREATE OR ALTER PROCEDURE dbo.Anagrafiche_Materiali_Elimina
        @IdMateriale INT,
        @VersioneRiga BINARY(8)
    AS
    BEGIN
        SET NOCOUNT ON;
        SET XACT_ABORT ON;
        BEGIN TRANSACTION;
        IF NOT EXISTS (SELECT 1 FROM dbo.Materiali WITH (UPDLOCK, HOLDLOCK) WHERE IdMateriale = @IdMateriale)
            THROW 53206, ''Materiale non trovato.'', 1;
        IF NOT EXISTS (SELECT 1 FROM dbo.Materiali WHERE IdMateriale = @IdMateriale AND VersioneRiga = @VersioneRiga)
            THROW 53207, ''Materiale modificato da un altro utente.'', 1;
        IF EXISTS (SELECT 1 FROM dbo.DistintaMateriali WITH (UPDLOCK, HOLDLOCK) WHERE IdMateriale = @IdMateriale)
           OR EXISTS (SELECT 1 FROM dbo.FornitoriMateriali WITH (UPDLOCK, HOLDLOCK) WHERE IdMateriale = @IdMateriale)
           OR EXISTS (SELECT 1 FROM dbo.OrdiniFornitoriRighe WITH (UPDLOCK, HOLDLOCK) WHERE IdMateriale = @IdMateriale)
           OR EXISTS (SELECT 1 FROM dbo.RichiesteOffertaFornitoriRighe WITH (UPDLOCK, HOLDLOCK) WHERE IdMateriale = @IdMateriale)
           OR EXISTS (SELECT 1 FROM dbo.PreventiviRigheMateriali WITH (UPDLOCK, HOLDLOCK) WHERE IdMateriale = @IdMateriale)
            THROW 53208, ''Materiale gia utilizzato.'', 1;
        DELETE FROM dbo.Materiali
        WHERE IdMateriale = @IdMateriale AND VersioneRiga = @VersioneRiga;
        COMMIT TRANSACTION;
    END;';

    EXEC sys.sp_executesql N'
    CREATE OR ALTER PROCEDURE dbo.Anagrafiche_Lavorazioni_Elenco
        @Ricerca NVARCHAR(200) = NULL,
        @SoloAttive BIT = NULL,
        @InternaEsterna NVARCHAR(20) = NULL
    AS
    BEGIN
        SET NOCOUNT ON;
        DECLARE @Filtro NVARCHAR(200) = NULLIF(LTRIM(RTRIM(@Ricerca)), N'''');
        SET @InternaEsterna = NULLIF(LTRIM(RTRIM(@InternaEsterna)), N'''');

        SELECT IdLavorazione,
               CodiceLavorazione,
               Descrizione,
               InternaEsterna,
               CostoOrarioStandard,
               AcquistabileEsterna,
               Attiva
        FROM dbo.Lavorazioni
        WHERE (@SoloAttive IS NULL OR Attiva = @SoloAttive)
          AND (@InternaEsterna IS NULL OR InternaEsterna = @InternaEsterna)
          AND
          (
              @Filtro IS NULL
              OR CodiceLavorazione LIKE N''%'' + @Filtro + N''%''
              OR Descrizione LIKE N''%'' + @Filtro + N''%''
          )
        ORDER BY CodiceLavorazione;
    END;';

    EXEC sys.sp_executesql N'
    CREATE OR ALTER PROCEDURE dbo.Anagrafiche_Lavorazioni_Dettaglio
        @IdLavorazione INT
    AS
    BEGIN
        SET NOCOUNT ON;
        SELECT lavorazione.IdLavorazione,
               lavorazione.CodiceLavorazione,
               lavorazione.Descrizione,
               lavorazione.InternaEsterna,
               lavorazione.CostoOrarioStandard,
               lavorazione.TempoSetupMinDefault,
               lavorazione.TempoPezzoMinDefault,
               lavorazione.AcquistabileEsterna,
               lavorazione.IdFornitorePredefinito,
               CASE WHEN fornitore.IdFornitore IS NULL THEN NULL
                    ELSE fornitore.CodiceFornitore + N'' - '' + fornitore.RagioneSociale END AS FornitorePredefinito,
               lavorazione.Attiva,
               lavorazione.Note,
               lavorazione.DataCreazione,
               lavorazione.DataModifica,
               lavorazione.UtenteCreazione,
               lavorazione.UtenteModifica,
               lavorazione.VersioneRiga
        FROM dbo.Lavorazioni AS lavorazione
        LEFT JOIN dbo.Fornitori AS fornitore ON fornitore.IdFornitore = lavorazione.IdFornitorePredefinito
        WHERE lavorazione.IdLavorazione = @IdLavorazione;
    END;';

    EXEC sys.sp_executesql N'
    CREATE OR ALTER PROCEDURE dbo.Anagrafiche_Lavorazioni_Crea
        @CodiceLavorazione NVARCHAR(50),
        @Descrizione NVARCHAR(150),
        @InternaEsterna NVARCHAR(20),
        @CostoOrarioStandard DECIMAL(18,4),
        @TempoSetupMinDefault DECIMAL(18,2),
        @TempoPezzoMinDefault DECIMAL(18,4),
        @AcquistabileEsterna BIT,
        @IdFornitorePredefinito INT = NULL,
        @Note NVARCHAR(500) = NULL,
        @Utente NVARCHAR(256)
    AS
    BEGIN
        SET NOCOUNT ON;
        SET XACT_ABORT ON;
        SET @CodiceLavorazione = NULLIF(LTRIM(RTRIM(@CodiceLavorazione)), N'''');
        SET @Descrizione = NULLIF(LTRIM(RTRIM(@Descrizione)), N'''');
        SET @InternaEsterna = NULLIF(LTRIM(RTRIM(@InternaEsterna)), N'''');
        SET @Note = NULLIF(LTRIM(RTRIM(@Note)), N'''');
        SET @Utente = NULLIF(LTRIM(RTRIM(@Utente)), N'''');

        IF @CodiceLavorazione IS NULL OR @Descrizione IS NULL OR @InternaEsterna IS NULL
           OR @InternaEsterna NOT IN (N''Interna'', N''Esterna'')
           OR @CostoOrarioStandard IS NULL OR @CostoOrarioStandard < 0
           OR @TempoSetupMinDefault IS NULL OR @TempoSetupMinDefault < 0
           OR @TempoPezzoMinDefault IS NULL OR @TempoPezzoMinDefault < 0
           OR @AcquistabileEsterna IS NULL OR @Utente IS NULL
            THROW 53221, ''Dati lavorazione non validi.'', 1;
        IF @AcquistabileEsterna = 0 AND @IdFornitorePredefinito IS NOT NULL
            THROW 53225, ''Fornitore non ammesso per lavorazione non acquistabile esternamente.'', 1;

        BEGIN TRANSACTION;
        IF @IdFornitorePredefinito IS NOT NULL
           AND NOT EXISTS (SELECT 1 FROM dbo.Fornitori WITH (UPDLOCK, HOLDLOCK) WHERE IdFornitore = @IdFornitorePredefinito AND Attivo = 1)
            THROW 53224, ''Fornitore non valido o non attivo.'', 1;
        IF EXISTS (SELECT 1 FROM dbo.Lavorazioni WITH (UPDLOCK, HOLDLOCK) WHERE CodiceLavorazione = @CodiceLavorazione)
            THROW 53222, ''Codice lavorazione gia utilizzato.'', 1;

        INSERT INTO dbo.Lavorazioni
        (
            CodiceLavorazione, Descrizione, InternaEsterna,
            CostoOrarioStandard, TempoSetupMinDefault, TempoPezzoMinDefault,
            AcquistabileEsterna, IdFornitorePredefinito, Attiva, Note,
            DataCreazione, DataModifica, UtenteCreazione, UtenteModifica
        )
        VALUES
        (
            @CodiceLavorazione, @Descrizione, @InternaEsterna,
            @CostoOrarioStandard, @TempoSetupMinDefault, @TempoPezzoMinDefault,
            @AcquistabileEsterna, @IdFornitorePredefinito, 1, @Note,
            SYSDATETIME(), NULL, @Utente, NULL
        );
        DECLARE @IdLavorazione INT = CONVERT(INT, SCOPE_IDENTITY());
        COMMIT TRANSACTION;
        SELECT @IdLavorazione;
    END;';

    EXEC sys.sp_executesql N'
    CREATE OR ALTER PROCEDURE dbo.Anagrafiche_Lavorazioni_Aggiorna
        @IdLavorazione INT,
        @CodiceLavorazione NVARCHAR(50),
        @Descrizione NVARCHAR(150),
        @InternaEsterna NVARCHAR(20),
        @CostoOrarioStandard DECIMAL(18,4),
        @TempoSetupMinDefault DECIMAL(18,2),
        @TempoPezzoMinDefault DECIMAL(18,4),
        @AcquistabileEsterna BIT,
        @IdFornitorePredefinito INT = NULL,
        @Note NVARCHAR(500) = NULL,
        @Utente NVARCHAR(256),
        @VersioneRiga BINARY(8)
    AS
    BEGIN
        SET NOCOUNT ON;
        SET XACT_ABORT ON;
        SET @CodiceLavorazione = NULLIF(LTRIM(RTRIM(@CodiceLavorazione)), N'''');
        SET @Descrizione = NULLIF(LTRIM(RTRIM(@Descrizione)), N'''');
        SET @InternaEsterna = NULLIF(LTRIM(RTRIM(@InternaEsterna)), N'''');
        SET @Note = NULLIF(LTRIM(RTRIM(@Note)), N'''');
        SET @Utente = NULLIF(LTRIM(RTRIM(@Utente)), N'''');

        IF @CodiceLavorazione IS NULL OR @Descrizione IS NULL OR @InternaEsterna IS NULL
           OR @InternaEsterna NOT IN (N''Interna'', N''Esterna'')
           OR @CostoOrarioStandard IS NULL OR @CostoOrarioStandard < 0
           OR @TempoSetupMinDefault IS NULL OR @TempoSetupMinDefault < 0
           OR @TempoPezzoMinDefault IS NULL OR @TempoPezzoMinDefault < 0
           OR @AcquistabileEsterna IS NULL OR @Utente IS NULL
            THROW 53221, ''Dati lavorazione non validi.'', 1;
        IF @AcquistabileEsterna = 0 AND @IdFornitorePredefinito IS NOT NULL
            THROW 53225, ''Fornitore non ammesso per lavorazione non acquistabile esternamente.'', 1;

        BEGIN TRANSACTION;
        DECLARE @IdFornitoreCorrente INT;
        SELECT @IdFornitoreCorrente = IdFornitorePredefinito
        FROM dbo.Lavorazioni WITH (UPDLOCK, HOLDLOCK)
        WHERE IdLavorazione = @IdLavorazione;
        IF @@ROWCOUNT = 0
            THROW 53226, ''Lavorazione non trovata.'', 1;
        IF @IdFornitorePredefinito IS NOT NULL
           AND NOT EXISTS
           (
               SELECT 1 FROM dbo.Fornitori WITH (UPDLOCK, HOLDLOCK)
               WHERE IdFornitore = @IdFornitorePredefinito
                 AND (Attivo = 1 OR IdFornitore = @IdFornitoreCorrente)
           )
            THROW 53224, ''Fornitore non valido o non attivo.'', 1;
        IF EXISTS
        (
            SELECT 1 FROM dbo.Lavorazioni WITH (UPDLOCK, HOLDLOCK)
            WHERE CodiceLavorazione = @CodiceLavorazione AND IdLavorazione <> @IdLavorazione
        )
            THROW 53222, ''Codice lavorazione gia utilizzato.'', 1;

        UPDATE dbo.Lavorazioni
        SET CodiceLavorazione = @CodiceLavorazione,
            Descrizione = @Descrizione,
            InternaEsterna = @InternaEsterna,
            CostoOrarioStandard = @CostoOrarioStandard,
            TempoSetupMinDefault = @TempoSetupMinDefault,
            TempoPezzoMinDefault = @TempoPezzoMinDefault,
            AcquistabileEsterna = @AcquistabileEsterna,
            IdFornitorePredefinito = @IdFornitorePredefinito,
            Note = @Note,
            DataModifica = SYSDATETIME(),
            UtenteModifica = @Utente
        WHERE IdLavorazione = @IdLavorazione
          AND VersioneRiga = @VersioneRiga;
        IF @@ROWCOUNT = 0
            THROW 53227, ''Lavorazione modificata da un altro utente.'', 1;
        COMMIT TRANSACTION;
    END;';

    EXEC sys.sp_executesql N'
    CREATE OR ALTER PROCEDURE dbo.Anagrafiche_Lavorazioni_ImpostaStato
        @IdLavorazione INT,
        @Attivo BIT,
        @Utente NVARCHAR(256),
        @VersioneRiga BINARY(8)
    AS
    BEGIN
        SET NOCOUNT ON;
        SET @Utente = NULLIF(LTRIM(RTRIM(@Utente)), N'''');
        IF @Attivo IS NULL OR @Utente IS NULL
            THROW 53221, ''Utente obbligatorio.'', 1;
        UPDATE dbo.Lavorazioni
        SET Attiva = @Attivo,
            DataModifica = SYSDATETIME(),
            UtenteModifica = @Utente
        WHERE IdLavorazione = @IdLavorazione
          AND VersioneRiga = @VersioneRiga;
        IF @@ROWCOUNT = 0
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM dbo.Lavorazioni WHERE IdLavorazione = @IdLavorazione)
                THROW 53226, ''Lavorazione non trovata.'', 1;
            THROW 53227, ''Lavorazione modificata da un altro utente.'', 1;
        END;
    END;';

    EXEC sys.sp_executesql N'
    CREATE OR ALTER PROCEDURE dbo.Anagrafiche_Lavorazioni_Elimina
        @IdLavorazione INT,
        @VersioneRiga BINARY(8)
    AS
    BEGIN
        SET NOCOUNT ON;
        SET XACT_ABORT ON;
        BEGIN TRANSACTION;
        IF NOT EXISTS (SELECT 1 FROM dbo.Lavorazioni WITH (UPDLOCK, HOLDLOCK) WHERE IdLavorazione = @IdLavorazione)
            THROW 53226, ''Lavorazione non trovata.'', 1;
        IF NOT EXISTS (SELECT 1 FROM dbo.Lavorazioni WHERE IdLavorazione = @IdLavorazione AND VersioneRiga = @VersioneRiga)
            THROW 53227, ''Lavorazione modificata da un altro utente.'', 1;
        IF EXISTS (SELECT 1 FROM dbo.DistintaLavorazioni WITH (UPDLOCK, HOLDLOCK) WHERE IdLavorazione = @IdLavorazione)
           OR EXISTS (SELECT 1 FROM dbo.FornitoriLavorazioni WITH (UPDLOCK, HOLDLOCK) WHERE IdLavorazione = @IdLavorazione)
           OR EXISTS (SELECT 1 FROM dbo.ModelliCicloRighe WITH (UPDLOCK, HOLDLOCK) WHERE IdLavorazione = @IdLavorazione)
           OR EXISTS (SELECT 1 FROM dbo.OrdiniFornitoriRighe WITH (UPDLOCK, HOLDLOCK) WHERE IdLavorazione = @IdLavorazione)
           OR EXISTS (SELECT 1 FROM dbo.PreventiviRigheLavorazioni WITH (UPDLOCK, HOLDLOCK) WHERE IdLavorazione = @IdLavorazione)
            THROW 53228, ''Lavorazione gia utilizzata.'', 1;
        DELETE FROM dbo.Lavorazioni
        WHERE IdLavorazione = @IdLavorazione AND VersioneRiga = @VersioneRiga;
        COMMIT TRANSACTION;
    END;';
    /* PAYLOAD TEC-016-MATERIALI-LAVORAZIONI END */

    DECLARE @Versione INT = 2026110302;
    DECLARE @CodiceIntervento NVARCHAR(50) = N'TEC-016-MATERIALI-LAVORAZIONI';
    DECLARE @NomeScript NVARCHAR(260) = N'TEC-016_02_Materiali_Lavorazioni.sql';
    -- SHA-256 del contenuto fra i marcatori PAYLOAD inclusi, normalizzato con LF.
    DECLARE @ImprontaSha256 CHAR(64) = '607F8C58C1B4D9BFC6506926483DF085DAE78FB6FC9B053D7A3A5A1E9FDABD15';

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
        THROW 53299, 'TEC-016-MATERIALI-LAVORAZIONI: versione gia registrata con dati o impronta differenti.', 1;

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
        N'Gestione anagrafiche materiali e lavorazioni con audit e concorrenza.',
        @ImprontaSha256
    );

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0
        ROLLBACK TRANSACTION;
    THROW;
END CATCH;
