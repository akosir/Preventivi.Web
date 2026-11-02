/*
    TEC-015 - Rilievi e adeguamenti campionatura
    Versione schema: 2026102901
    Prerequisito: versione 2026102702 (TEC-014-BASE).

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
        THROW 52790, 'TEC-015: registro VersioniSchema non disponibile.', 1;

    IF NOT EXISTS
    (
        SELECT 1
        FROM dbo.VersioniSchema
        WHERE Versione = 2026102702
          AND CodiceIntervento = N'TEC-014-BASE'
    )
        THROW 52791, 'TEC-015: versione richiesta 2026102702 non installata.', 1;

    IF EXISTS
    (
        SELECT 1
        FROM dbo.VersioniSchema
        WHERE Versione > 2026102702
          AND Versione <> 2026102901
    )
        THROW 52792, 'TEC-015: il database contiene una versione successiva non riconosciuta.', 1;

    IF OBJECT_ID(N'dbo.Campionature', N'U') IS NULL
       OR OBJECT_ID(N'dbo.CampionatureRilievi', N'U') IS NULL
       OR OBJECT_ID(N'dbo.CampionatureAdeguamentiPreventivo', N'U') IS NULL
       OR OBJECT_ID(N'dbo.TipiProblematicheQualita', N'U') IS NULL
       OR OBJECT_ID(N'dbo.ProblematicheStandard', N'U') IS NULL
        THROW 52793, 'TEC-015: tabelle richieste non disponibili.', 1;

    /* PAYLOAD TEC-015 START */
    IF COL_LENGTH(N'dbo.CampionatureRilievi', N'DataCreazione') IS NULL
        EXEC sys.sp_executesql N'
        ALTER TABLE dbo.CampionatureRilievi
            ADD DataCreazione DATETIME2(0) NULL;';

    EXEC sys.sp_executesql N'
        UPDATE dbo.CampionatureRilievi
        SET DataCreazione = SYSDATETIME()
        WHERE DataCreazione IS NULL;

        ALTER TABLE dbo.CampionatureRilievi
            ALTER COLUMN DataCreazione DATETIME2(0) NOT NULL;';

    IF NOT EXISTS
    (
        SELECT 1
        FROM sys.default_constraints AS vincolo
        INNER JOIN sys.columns AS colonna
            ON colonna.object_id = vincolo.parent_object_id
           AND colonna.column_id = vincolo.parent_column_id
        WHERE vincolo.parent_object_id = OBJECT_ID(N'dbo.CampionatureRilievi')
          AND colonna.name = N'DataCreazione'
    )
        EXEC sys.sp_executesql N'
        ALTER TABLE dbo.CampionatureRilievi
            ADD CONSTRAINT DF_CampionatureRilievi_DataCreazione
            DEFAULT SYSDATETIME() FOR DataCreazione;';

    IF COL_LENGTH(N'dbo.CampionatureRilievi', N'DataModifica') IS NULL
        EXEC sys.sp_executesql N'
        ALTER TABLE dbo.CampionatureRilievi
            ADD DataModifica DATETIME2(0) NULL;';

    IF COL_LENGTH(N'dbo.CampionatureRilievi', N'UtenteCreazione') IS NULL
        EXEC sys.sp_executesql N'
        ALTER TABLE dbo.CampionatureRilievi
            ADD UtenteCreazione NVARCHAR(256) NULL;';

    EXEC sys.sp_executesql N'
        UPDATE dbo.CampionatureRilievi
        SET UtenteCreazione = N''MIGRAZIONE-TEC-015''
        WHERE UtenteCreazione IS NULL;

        ALTER TABLE dbo.CampionatureRilievi
            ALTER COLUMN UtenteCreazione NVARCHAR(256) NOT NULL;';

    IF COL_LENGTH(N'dbo.CampionatureRilievi', N'UtenteModifica') IS NULL
        EXEC sys.sp_executesql N'
        ALTER TABLE dbo.CampionatureRilievi
            ADD UtenteModifica NVARCHAR(256) NULL;';

    IF COL_LENGTH(N'dbo.CampionatureRilievi', N'VersioneRiga') IS NULL
        EXEC sys.sp_executesql N'
        ALTER TABLE dbo.CampionatureRilievi
            ADD VersioneRiga ROWVERSION NOT NULL;';

    IF COL_LENGTH(N'dbo.CampionatureAdeguamentiPreventivo', N'DataCreazione') IS NULL
        EXEC sys.sp_executesql N'
        ALTER TABLE dbo.CampionatureAdeguamentiPreventivo
            ADD DataCreazione DATETIME2(0) NULL;';

    EXEC sys.sp_executesql N'
        UPDATE dbo.CampionatureAdeguamentiPreventivo
        SET DataCreazione = SYSDATETIME()
        WHERE DataCreazione IS NULL;

        ALTER TABLE dbo.CampionatureAdeguamentiPreventivo
            ALTER COLUMN DataCreazione DATETIME2(0) NOT NULL;';

    IF NOT EXISTS
    (
        SELECT 1
        FROM sys.default_constraints AS vincolo
        INNER JOIN sys.columns AS colonna
            ON colonna.object_id = vincolo.parent_object_id
           AND colonna.column_id = vincolo.parent_column_id
        WHERE vincolo.parent_object_id = OBJECT_ID(N'dbo.CampionatureAdeguamentiPreventivo')
          AND colonna.name = N'DataCreazione'
    )
        EXEC sys.sp_executesql N'
        ALTER TABLE dbo.CampionatureAdeguamentiPreventivo
            ADD CONSTRAINT DF_CampAdeguamenti_DataCreazione
            DEFAULT SYSDATETIME() FOR DataCreazione;';

    IF COL_LENGTH(N'dbo.CampionatureAdeguamentiPreventivo', N'UtenteCreazione') IS NULL
        EXEC sys.sp_executesql N'
        ALTER TABLE dbo.CampionatureAdeguamentiPreventivo
            ADD UtenteCreazione NVARCHAR(256) NULL;';

    EXEC sys.sp_executesql N'
        UPDATE dbo.CampionatureAdeguamentiPreventivo
        SET UtenteCreazione = N''MIGRAZIONE-TEC-015''
        WHERE UtenteCreazione IS NULL;

        ALTER TABLE dbo.CampionatureAdeguamentiPreventivo
            ALTER COLUMN UtenteCreazione NVARCHAR(256) NOT NULL;';

    IF COL_LENGTH(N'dbo.CampionatureAdeguamentiPreventivo', N'VersioneRiga') IS NULL
        EXEC sys.sp_executesql N'
        ALTER TABLE dbo.CampionatureAdeguamentiPreventivo
            ADD VersioneRiga ROWVERSION NOT NULL;';

    IF EXISTS
    (
        SELECT 1
        FROM dbo.CampionatureRilievi
        GROUP BY IdCampionatura, RigaNr
        HAVING COUNT(*) > 1
    )
        THROW 52794, 'TEC-015: numeri rilievo duplicati presenti nei dati esistenti.', 1;

    IF NOT EXISTS
    (
        SELECT 1
        FROM sys.indexes
        WHERE object_id = OBJECT_ID(N'dbo.CampionatureRilievi')
          AND name = N'UX_CampionatureRilievi_Campionatura_RigaNr'
    )
        EXEC sys.sp_executesql N'
        CREATE UNIQUE INDEX UX_CampionatureRilievi_Campionatura_RigaNr
            ON dbo.CampionatureRilievi (IdCampionatura, RigaNr);';

    EXEC sys.sp_executesql N'
    CREATE OR ALTER PROCEDURE dbo.Campionature_Rilievi_Elenco
        @IdCampionatura INT
    AS
    BEGIN
        SET NOCOUNT ON;

        SELECT
            rilievo.IdRilievoCampionatura,
            rilievo.IdCampionatura,
            rilievo.RigaNr,
            rilievo.DataRilevazione,
            tipo.Descrizione AS TipoProblematica,
            standard.DescrizioneProblematica AS ProblematicaStandard,
            rilievo.DescrizioneProblema,
            rilievo.Gravita,
            rilievo.Stato,
            rilievo.RichiedeAdeguamentoPreventivo,
            rilievo.RichiedeNuovoCampione
        FROM dbo.CampionatureRilievi AS rilievo
        INNER JOIN dbo.TipiProblematicheQualita AS tipo
            ON tipo.IdTipoProblematica = rilievo.IdTipoProblematica
        LEFT JOIN dbo.ProblematicheStandard AS standard
            ON standard.IdProblematicaStandard = rilievo.IdProblematicaStandard
        WHERE rilievo.IdCampionatura = @IdCampionatura
        ORDER BY rilievo.RigaNr;
    END;';

    EXEC sys.sp_executesql N'
    CREATE OR ALTER PROCEDURE dbo.Campionature_Rilievi_Dettaglio
        @IdRilievoCampionatura INT
    AS
    BEGIN
        SET NOCOUNT ON;

        SELECT
            rilievo.IdRilievoCampionatura,
            rilievo.IdCampionatura,
            rilievo.RigaNr,
            rilievo.IdTipoProblematica,
            tipo.Descrizione AS TipoProblematica,
            rilievo.IdProblematicaStandard,
            standard.DescrizioneProblematica AS ProblematicaStandard,
            rilievo.DescrizioneProblema,
            rilievo.Gravita,
            rilievo.CausaPresunta,
            rilievo.SoluzioneProposta,
            rilievo.RichiedeAdeguamentoPreventivo,
            rilievo.RichiedeNuovoCampione,
            rilievo.Stato,
            rilievo.EsitoVerifica,
            rilievo.NoteCliente,
            rilievo.NoteInterne,
            rilievo.DataRilevazione,
            rilievo.DataChiusura,
            rilievo.VersioneRiga
        FROM dbo.CampionatureRilievi AS rilievo
        INNER JOIN dbo.TipiProblematicheQualita AS tipo
            ON tipo.IdTipoProblematica = rilievo.IdTipoProblematica
        LEFT JOIN dbo.ProblematicheStandard AS standard
            ON standard.IdProblematicaStandard = rilievo.IdProblematicaStandard
        WHERE rilievo.IdRilievoCampionatura = @IdRilievoCampionatura;
    END;';

    EXEC sys.sp_executesql N'
    CREATE OR ALTER PROCEDURE dbo.Campionature_Rilievi_Tipi_Elenco
    AS
    BEGIN
        SET NOCOUNT ON;

        SELECT IdTipoProblematica, CodiceTipo, Descrizione
        FROM dbo.TipiProblematicheQualita
        WHERE Attivo = 1
        ORDER BY Descrizione, CodiceTipo;
    END;';

    EXEC sys.sp_executesql N'
    CREATE OR ALTER PROCEDURE dbo.Campionature_Rilievi_Problematiche_Elenco
    AS
    BEGIN
        SET NOCOUNT ON;

        SELECT
            IdProblematicaStandard,
            IdTipoProblematica,
            CodiceProblematica,
            DescrizioneProblematica,
            SoluzioneStandard
        FROM dbo.ProblematicheStandard
        WHERE Attiva = 1
        ORDER BY IdTipoProblematica, DescrizioneProblematica, CodiceProblematica;
    END;';

    EXEC sys.sp_executesql N'
    CREATE OR ALTER PROCEDURE dbo.Campionature_Rilievi_Crea
        @IdCampionatura INT,
        @DataRilevazione DATE,
        @IdTipoProblematica INT,
        @IdProblematicaStandard INT = NULL,
        @DescrizioneProblema NVARCHAR(MAX),
        @Gravita NVARCHAR(20),
        @CausaPresunta NVARCHAR(MAX) = NULL,
        @SoluzioneProposta NVARCHAR(MAX) = NULL,
        @RichiedeNuovoCampione BIT = 0,
        @NoteCliente NVARCHAR(MAX) = NULL,
        @NoteInterne NVARCHAR(MAX) = NULL,
        @Utente NVARCHAR(256)
    AS
    BEGIN
        SET NOCOUNT ON;
        SET XACT_ABORT ON;

        SET @DescrizioneProblema = NULLIF(LTRIM(RTRIM(@DescrizioneProblema)), N'''');
        SET @Gravita = NULLIF(LTRIM(RTRIM(@Gravita)), N'''');
        SET @Utente = NULLIF(LTRIM(RTRIM(@Utente)), N'''');

        IF @DataRilevazione IS NULL OR @DescrizioneProblema IS NULL OR @Utente IS NULL
            THROW 52701, ''Dati obbligatori del rilievo mancanti.'', 1;
        IF @Gravita NOT IN (N''Bassa'', N''Media'', N''Alta'', N''Critica'')
            THROW 52701, ''Gravita del rilievo non valida.'', 1;
        IF NOT EXISTS (SELECT 1 FROM dbo.Campionature WHERE IdCampionatura = @IdCampionatura)
            THROW 52702, ''Campionatura non trovata.'', 1;
        IF NOT EXISTS
        (
            SELECT 1 FROM dbo.TipiProblematicheQualita
            WHERE IdTipoProblematica = @IdTipoProblematica AND Attivo = 1
        )
            THROW 52703, ''Tipo di problematica non trovato o non attivo.'', 1;
        IF @IdProblematicaStandard IS NOT NULL AND NOT EXISTS
        (
            SELECT 1 FROM dbo.ProblematicheStandard
            WHERE IdProblematicaStandard = @IdProblematicaStandard
              AND IdTipoProblematica = @IdTipoProblematica
              AND Attiva = 1
        )
            THROW 52704, ''Problematica standard non coerente con il tipo selezionato.'', 1;

        BEGIN TRANSACTION;

        DECLARE @EsitoLock INT;
        DECLARE @RigaNr INT;
        DECLARE @Risorsa NVARCHAR(255) = N''CampionatureRilievi:'' + CONVERT(NVARCHAR(20), @IdCampionatura);

        EXEC @EsitoLock = sys.sp_getapplock
            @Resource = @Risorsa,
            @LockMode = ''Exclusive'',
            @LockOwner = ''Transaction'',
            @LockTimeout = 10000;

        IF @EsitoLock < 0
            THROW 52705, ''Impossibile assegnare il numero del rilievo.'', 1;

        SELECT @RigaNr = ISNULL(MAX(RigaNr), 0) + 1
        FROM dbo.CampionatureRilievi WITH (UPDLOCK, HOLDLOCK)
        WHERE IdCampionatura = @IdCampionatura;

        INSERT INTO dbo.CampionatureRilievi
        (
            IdCampionatura, RigaNr, IdTipoProblematica, IdProblematicaStandard,
            DescrizioneProblema, Gravita, CausaPresunta, SoluzioneProposta,
            RichiedeAdeguamentoPreventivo, RichiedeNuovoCampione, Stato,
            EsitoVerifica, NoteCliente, NoteInterne, DataRilevazione,
            DataChiusura, UtenteCreazione
        )
        VALUES
        (
            @IdCampionatura, @RigaNr, @IdTipoProblematica, @IdProblematicaStandard,
            @DescrizioneProblema, @Gravita, NULLIF(LTRIM(RTRIM(@CausaPresunta)), N''''),
            NULLIF(LTRIM(RTRIM(@SoluzioneProposta)), N''''), 0,
            @RichiedeNuovoCampione, N''Aperto'', NULL,
            NULLIF(LTRIM(RTRIM(@NoteCliente)), N''''),
            NULLIF(LTRIM(RTRIM(@NoteInterne)), N''''), @DataRilevazione,
            NULL, @Utente
        );

        DECLARE @IdRilievoCampionatura INT = CONVERT(INT, SCOPE_IDENTITY());
        COMMIT TRANSACTION;
        SELECT @IdRilievoCampionatura;
    END;';

    EXEC sys.sp_executesql N'
    CREATE OR ALTER PROCEDURE dbo.Campionature_Rilievi_Stato_Aggiorna
        @IdRilievoCampionatura INT,
        @Stato NVARCHAR(30),
        @VersioneRiga BINARY(8),
        @Utente NVARCHAR(256)
    AS
    BEGIN
        SET NOCOUNT ON;
        SET XACT_ABORT ON;

        SET @Stato = NULLIF(LTRIM(RTRIM(@Stato)), N'''');
        SET @Utente = NULLIF(LTRIM(RTRIM(@Utente)), N'''');

        IF @Stato NOT IN (N''Aperto'', N''In Analisi'', N''Soluzione Proposta'', N''Risolto'', N''Respinto'', N''Chiuso'')
            THROW 52706, ''Stato del rilievo non valido.'', 1;
        IF @VersioneRiga IS NULL OR @Utente IS NULL
            THROW 52701, ''Dati obbligatori del rilievo mancanti.'', 1;

        DECLARE @StatoCorrente NVARCHAR(30);
        DECLARE @VersioneCorrente BINARY(8);

        SELECT
            @StatoCorrente = Stato,
            @VersioneCorrente = VersioneRiga
        FROM dbo.CampionatureRilievi
        WHERE IdRilievoCampionatura = @IdRilievoCampionatura;

        IF @StatoCorrente IS NULL
            THROW 52707, ''Rilievo non trovato.'', 1;
        IF @VersioneCorrente <> @VersioneRiga
            THROW 52708, ''Il rilievo e stato modificato da un altro utente.'', 1;
        IF @StatoCorrente IN (N''Respinto'', N''Chiuso'') AND @Stato <> @StatoCorrente
            THROW 52709, ''Il rilievo e gia in uno stato finale.'', 1;

        UPDATE dbo.CampionatureRilievi
        SET Stato = @Stato,
            DataChiusura = CASE WHEN @Stato IN (N''Respinto'', N''Chiuso'')
                                THEN CONVERT(DATE, GETDATE()) ELSE NULL END,
            DataModifica = SYSDATETIME(),
            UtenteModifica = @Utente
        WHERE IdRilievoCampionatura = @IdRilievoCampionatura
          AND VersioneRiga = @VersioneRiga;

        IF @@ROWCOUNT = 0
            THROW 52708, ''Il rilievo e stato modificato da un altro utente.'', 1;
    END;';

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
            adeguamento.DataApplicazione
        FROM dbo.CampionatureAdeguamentiPreventivo AS adeguamento
        INNER JOIN dbo.CampionatureRilievi AS rilievo
            ON rilievo.IdRilievoCampionatura = adeguamento.IdRilievoCampionatura
        WHERE adeguamento.IdCampionatura = @IdCampionatura
        ORDER BY adeguamento.IdAdeguamento DESC;
    END;';

    EXEC sys.sp_executesql N'
    CREATE OR ALTER PROCEDURE dbo.Campionature_Adeguamenti_Crea
        @IdRilievoCampionatura INT,
        @DescrizioneAdeguamento NVARCHAR(MAX),
        @ImpattoCostoStimato DECIMAL(18,2) = 0,
        @ImpattoVenditaStimato DECIMAL(18,2) = 0,
        @Note NVARCHAR(MAX) = NULL,
        @VersioneRilievo BINARY(8),
        @Utente NVARCHAR(256)
    AS
    BEGIN
        SET NOCOUNT ON;
        SET XACT_ABORT ON;

        SET @DescrizioneAdeguamento = NULLIF(LTRIM(RTRIM(@DescrizioneAdeguamento)), N'''');
        SET @Utente = NULLIF(LTRIM(RTRIM(@Utente)), N'''');

        IF @DescrizioneAdeguamento IS NULL OR @VersioneRilievo IS NULL OR @Utente IS NULL
            THROW 52710, ''Dati obbligatori dell''''adeguamento mancanti.'', 1;

        BEGIN TRANSACTION;

        DECLARE @IdCampionatura INT;
        DECLARE @IdPreventivo INT;
        DECLARE @IdVariantePreventivo INT;
        DECLARE @StatoRilievo NVARCHAR(30);
        DECLARE @VersioneCorrente BINARY(8);

        SELECT
            @IdCampionatura = rilievo.IdCampionatura,
            @StatoRilievo = rilievo.Stato,
            @VersioneCorrente = rilievo.VersioneRiga,
            @IdPreventivo = campionatura.IdPreventivo,
            @IdVariantePreventivo = campionatura.IdVariantePreventivo
        FROM dbo.CampionatureRilievi AS rilievo WITH (UPDLOCK, HOLDLOCK)
        INNER JOIN dbo.Campionature AS campionatura
            ON campionatura.IdCampionatura = rilievo.IdCampionatura
        WHERE rilievo.IdRilievoCampionatura = @IdRilievoCampionatura;

        IF @IdCampionatura IS NULL
            THROW 52707, ''Rilievo non trovato.'', 1;
        IF @VersioneCorrente <> @VersioneRilievo
            THROW 52708, ''Il rilievo e stato modificato da un altro utente.'', 1;
        IF @StatoRilievo IN (N''Respinto'', N''Chiuso'')
            THROW 52709, ''Il rilievo e gia in uno stato finale.'', 1;

        INSERT INTO dbo.CampionatureAdeguamentiPreventivo
        (
            IdCampionatura, IdRilievoCampionatura, IdPreventivo,
            IdVariantePreventivo, DescrizioneAdeguamento,
            ImpattoCostoStimato, ImpattoVenditaStimato, Applicato,
            DataApplicazione, Note, UtenteCreazione
        )
        VALUES
        (
            @IdCampionatura, @IdRilievoCampionatura, @IdPreventivo,
            @IdVariantePreventivo, @DescrizioneAdeguamento,
            ISNULL(@ImpattoCostoStimato, 0), ISNULL(@ImpattoVenditaStimato, 0),
            0, NULL, NULLIF(LTRIM(RTRIM(@Note)), N''''), @Utente
        );

        DECLARE @IdAdeguamento INT = CONVERT(INT, SCOPE_IDENTITY());

        UPDATE dbo.CampionatureRilievi
        SET RichiedeAdeguamentoPreventivo = 1,
            Stato = N''Soluzione Proposta'',
            DataChiusura = NULL,
            DataModifica = SYSDATETIME(),
            UtenteModifica = @Utente
        WHERE IdRilievoCampionatura = @IdRilievoCampionatura
          AND VersioneRiga = @VersioneRilievo;

        IF @@ROWCOUNT = 0
            THROW 52708, ''Il rilievo e stato modificato da un altro utente.'', 1;

        COMMIT TRANSACTION;
        SELECT @IdAdeguamento;
    END;';
    /* PAYLOAD TEC-015 END */

    DECLARE @Versione INT = 2026102901;
    DECLARE @CodiceIntervento NVARCHAR(50) = N'TEC-015';
    DECLARE @NomeScript NVARCHAR(260) = N'TEC-015_01_Rilievi_Adeguamenti_Campionature.sql';
    -- SHA-256 del contenuto fra i marcatori PAYLOAD inclusi, normalizzato con LF.
    DECLARE @ImprontaSha256 CHAR(64) =
        'C469AB844982908574BF730AC6545B51FB9EDF1C3E318458C199EE7688A49AF1';

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
        THROW 52799, 'TEC-015: versione gia registrata con dati o impronta differenti.', 1;

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
        N'Rilievi campionatura e adeguamenti preventivo proposti, non applicati automaticamente.',
        @ImprontaSha256
    );

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0
        ROLLBACK TRANSACTION;
    THROW;
END CATCH;
