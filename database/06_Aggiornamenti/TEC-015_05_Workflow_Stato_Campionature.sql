/*
    TEC-015 - Workflow controllato dello stato campionatura
    Versione schema: 2026110201
    Prerequisito: versione 2026103002 (TEC-015-APPLICAZIONE).

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
        THROW 53090, 'TEC-015-CAMPIONATURA-WORKFLOW: registro VersioniSchema non disponibile.', 1;

    IF NOT EXISTS
    (
        SELECT 1
        FROM dbo.VersioniSchema
        WHERE Versione = 2026103002
          AND CodiceIntervento = N'TEC-015-APPLICAZIONE'
    )
        THROW 53091, 'TEC-015-CAMPIONATURA-WORKFLOW: versione richiesta 2026103002 non installata.', 1;

    IF EXISTS
    (
        SELECT 1
        FROM dbo.VersioniSchema
        WHERE Versione > 2026103002
          AND Versione <> 2026110201
    )
        THROW 53092, 'TEC-015-CAMPIONATURA-WORKFLOW: il database contiene una versione successiva non riconosciuta.', 1;

    IF OBJECT_ID(N'dbo.Campionature', N'U') IS NULL
       OR OBJECT_ID(N'dbo.CampionatureRilievi', N'U') IS NULL
       OR OBJECT_ID(N'dbo.CampionatureAdeguamentiPreventivo', N'U') IS NULL
       OR COL_LENGTH(N'dbo.Campionature', N'VersioneRiga') IS NULL
        THROW 53093, 'TEC-015-CAMPIONATURA-WORKFLOW: struttura richiesta non disponibile.', 1;

    /* PAYLOAD TEC-015-CAMPIONATURA-WORKFLOW START */
    IF OBJECT_ID(N'dbo.CampionatureCorrezioniStato', N'U') IS NULL
        EXEC sys.sp_executesql N'
        CREATE TABLE dbo.CampionatureCorrezioniStato
        (
            IdCorrezioneStato BIGINT IDENTITY(1,1) NOT NULL
                CONSTRAINT PK_CampionatureCorrezioniStato PRIMARY KEY,
            IdCampionatura INT NOT NULL,
            StatoPrecedente NVARCHAR(30) NOT NULL,
            StatoNuovo NVARCHAR(30) NOT NULL,
            Motivazione NVARCHAR(500) NOT NULL,
            DataCorrezione DATETIME2(0) NOT NULL
                CONSTRAINT DF_CampionatureCorrezioniStato_DataCorrezione
                DEFAULT (SYSDATETIME()),
            UtenteCorrezione NVARCHAR(256) NOT NULL,
            CONSTRAINT FK_CampionatureCorrezioniStato_Campionature
                FOREIGN KEY (IdCampionatura)
                REFERENCES dbo.Campionature (IdCampionatura)
        );';

    IF NOT EXISTS
    (
        SELECT 1
        FROM sys.indexes
        WHERE object_id = OBJECT_ID(N'dbo.CampionatureCorrezioniStato')
          AND name = N'IX_CampionatureCorrezioniStato_Campionatura'
    )
        EXEC sys.sp_executesql N'
        CREATE INDEX IX_CampionatureCorrezioniStato_Campionatura
            ON dbo.CampionatureCorrezioniStato
            (
                IdCampionatura,
                IdCorrezioneStato DESC
            );';

    EXEC sys.sp_executesql N'
    CREATE OR ALTER PROCEDURE dbo.Campionature_Crea
        @DataCampionatura DATE,
        @IdRichiestaCliente INT,
        @IdPreventivo INT = NULL,
        @IdVariantePreventivo INT = NULL,
        @Oggetto NVARCHAR(250),
        @DescrizioneCampione NVARCHAR(MAX) = NULL,
        @Stato NVARCHAR(30),
        @Priorita NVARCHAR(20),
        @DataRichiestaCampione DATE = NULL,
        @DataPrevistaConsegna DATE = NULL,
        @DataConsegnaCampione DATE = NULL,
        @DataChiusura DATE = NULL,
        @Esito NVARCHAR(30) = NULL,
        @Note NVARCHAR(MAX) = NULL,
        @Utente NVARCHAR(256)
    AS
    BEGIN
        SET NOCOUNT ON;
        SET XACT_ABORT ON;

        SET @Oggetto = NULLIF(LTRIM(RTRIM(@Oggetto)), N'''');
        SET @Stato = NULLIF(LTRIM(RTRIM(@Stato)), N'''');
        SET @Priorita = NULLIF(LTRIM(RTRIM(@Priorita)), N'''');
        SET @Esito = NULLIF(LTRIM(RTRIM(@Esito)), N'''');
        SET @Utente = NULLIF(LTRIM(RTRIM(@Utente)), N'''');

        IF @DataCampionatura IS NULL OR @Oggetto IS NULL OR @Utente IS NULL
            THROW 52601, ''Dati obbligatori della campionatura mancanti.'', 1;
        IF @Stato <> N''Aperta'' OR @Esito IS NOT NULL OR @DataChiusura IS NOT NULL
            THROW 52601, ''Una nuova campionatura deve essere aperta e senza esito o data di chiusura.'', 1;
        IF @DataConsegnaCampione IS NOT NULL
            THROW 52601, ''La consegna effettiva viene registrata dal workflow.'', 1;
        IF @Priorita NOT IN (N''Bassa'', N''Media'', N''Alta'', N''Urgente'')
            THROW 52601, ''Priorita della campionatura non valida.'', 1;
        IF NOT EXISTS (SELECT 1 FROM dbo.RichiesteClienti WHERE IdRichiestaCliente = @IdRichiestaCliente)
            THROW 52602, ''Richiesta cliente non trovata.'', 1;
        IF @IdPreventivo IS NOT NULL AND NOT EXISTS
        (
            SELECT 1 FROM dbo.Preventivi
            WHERE IdPreventivo = @IdPreventivo
              AND IdRichiestaCliente = @IdRichiestaCliente
        )
            THROW 52603, ''Il preventivo non appartiene alla richiesta selezionata.'', 1;
        IF @IdVariantePreventivo IS NOT NULL AND
           (@IdPreventivo IS NULL OR NOT EXISTS
           (
               SELECT 1 FROM dbo.PreventiviVarianti
               WHERE IdVariantePreventivo = @IdVariantePreventivo
                 AND IdPreventivo = @IdPreventivo
           ))
            THROW 52604, ''La variante non appartiene al preventivo selezionato.'', 1;

        DECLARE @Anno INT = YEAR(@DataCampionatura);
        DECLARE @NumeroCampionatura INT;
        DECLARE @EsitoLock INT;
        DECLARE @RisorsaLock NVARCHAR(255) = CONCAT(N''Campionature_Numero_'', @Anno);

        BEGIN TRANSACTION;
        EXEC @EsitoLock = sys.sp_getapplock
            @Resource = @RisorsaLock,
            @LockMode = N''Exclusive'',
            @LockOwner = N''Transaction'',
            @LockTimeout = 10000;

        IF @EsitoLock < 0
            THROW 52605, ''Impossibile assegnare il numero della campionatura.'', 1;

        SELECT @NumeroCampionatura = ISNULL(MAX(NumeroCampionatura), 0) + 1
        FROM dbo.Campionature WITH (UPDLOCK, HOLDLOCK)
        WHERE Anno = @Anno;

        INSERT INTO dbo.Campionature
        (
            NumeroCampionatura, Anno, DataCampionatura, IdRichiestaCliente,
            IdPreventivo, IdVariantePreventivo, Oggetto, DescrizioneCampione,
            Stato, Priorita, DataRichiestaCampione, DataPrevistaConsegna,
            DataConsegnaCampione, DataChiusura, Esito, Note, UtenteCreazione
        )
        VALUES
        (
            @NumeroCampionatura, @Anno, @DataCampionatura, @IdRichiestaCliente,
            @IdPreventivo, @IdVariantePreventivo, @Oggetto, NULLIF(LTRIM(RTRIM(@DescrizioneCampione)), N''''),
            N''Aperta'', @Priorita, @DataRichiestaCampione, @DataPrevistaConsegna,
            NULL, NULL, NULL, NULLIF(LTRIM(RTRIM(@Note)), N''''), @Utente
        );

        DECLARE @IdCampionatura INT = CONVERT(INT, SCOPE_IDENTITY());
        COMMIT TRANSACTION;
        SELECT @IdCampionatura;
    END;';

    EXEC sys.sp_executesql N'
    CREATE OR ALTER PROCEDURE dbo.Campionature_Aggiorna
        @IdCampionatura INT,
        @DataCampionatura DATE,
        @IdRichiestaCliente INT,
        @IdPreventivo INT = NULL,
        @IdVariantePreventivo INT = NULL,
        @Oggetto NVARCHAR(250),
        @DescrizioneCampione NVARCHAR(MAX) = NULL,
        @Stato NVARCHAR(30),
        @Priorita NVARCHAR(20),
        @DataRichiestaCampione DATE = NULL,
        @DataPrevistaConsegna DATE = NULL,
        @DataConsegnaCampione DATE = NULL,
        @DataChiusura DATE = NULL,
        @Esito NVARCHAR(30) = NULL,
        @Note NVARCHAR(MAX) = NULL,
        @Utente NVARCHAR(256),
        @VersioneRiga BINARY(8)
    AS
    BEGIN
        SET NOCOUNT ON;
        SET XACT_ABORT ON;

        SET @Oggetto = NULLIF(LTRIM(RTRIM(@Oggetto)), N'''');
        SET @Stato = NULLIF(LTRIM(RTRIM(@Stato)), N'''');
        SET @Priorita = NULLIF(LTRIM(RTRIM(@Priorita)), N'''');
        SET @Esito = NULLIF(LTRIM(RTRIM(@Esito)), N'''');
        SET @Utente = NULLIF(LTRIM(RTRIM(@Utente)), N'''');

        IF @DataCampionatura IS NULL OR @Oggetto IS NULL OR @Utente IS NULL OR @VersioneRiga IS NULL
            THROW 52601, ''Dati obbligatori della campionatura mancanti.'', 1;
        IF @Priorita NOT IN (N''Bassa'', N''Media'', N''Alta'', N''Urgente'')
            THROW 52601, ''Priorita della campionatura non valida.'', 1;
        IF NOT EXISTS (SELECT 1 FROM dbo.RichiesteClienti WHERE IdRichiestaCliente = @IdRichiestaCliente)
            THROW 52602, ''Richiesta cliente non trovata.'', 1;
        IF @IdPreventivo IS NOT NULL AND NOT EXISTS
        (
            SELECT 1 FROM dbo.Preventivi
            WHERE IdPreventivo = @IdPreventivo
              AND IdRichiestaCliente = @IdRichiestaCliente
        )
            THROW 52603, ''Il preventivo non appartiene alla richiesta selezionata.'', 1;
        IF @IdVariantePreventivo IS NOT NULL AND
           (@IdPreventivo IS NULL OR NOT EXISTS
           (
               SELECT 1 FROM dbo.PreventiviVarianti
               WHERE IdVariantePreventivo = @IdVariantePreventivo
                 AND IdPreventivo = @IdPreventivo
           ))
            THROW 52604, ''La variante non appartiene al preventivo selezionato.'', 1;

        BEGIN TRANSACTION;

        DECLARE @AnnoCorrente INT;
        DECLARE @StatoCorrente NVARCHAR(30);
        DECLARE @DataConsegnaCorrente DATE;
        DECLARE @DataChiusuraCorrente DATE;
        DECLARE @EsitoCorrente NVARCHAR(30);
        DECLARE @VersioneCorrente BINARY(8);

        SELECT
            @AnnoCorrente = Anno,
            @StatoCorrente = Stato,
            @DataConsegnaCorrente = DataConsegnaCampione,
            @DataChiusuraCorrente = DataChiusura,
            @EsitoCorrente = Esito,
            @VersioneCorrente = VersioneRiga
        FROM dbo.Campionature WITH (UPDLOCK, HOLDLOCK)
        WHERE IdCampionatura = @IdCampionatura;

        IF @AnnoCorrente IS NULL
            THROW 52608, ''Campionatura non trovata.'', 1;
        IF @VersioneCorrente <> @VersioneRiga
            THROW 52606, ''La campionatura e stata modificata da un altro utente.'', 1;
        IF YEAR(@DataCampionatura) <> @AnnoCorrente
            THROW 52607, ''La data deve rimanere nello stesso anno del numero progressivo.'', 1;
        IF ISNULL(@Stato, N'''') <> ISNULL(@StatoCorrente, N'''')
           OR ISNULL(@DataConsegnaCampione, CONVERT(DATE, ''19000101'')) <> ISNULL(@DataConsegnaCorrente, CONVERT(DATE, ''19000101''))
           OR ISNULL(@DataChiusura, CONVERT(DATE, ''19000101'')) <> ISNULL(@DataChiusuraCorrente, CONVERT(DATE, ''19000101''))
           OR ISNULL(@Esito, N'''') <> ISNULL(@EsitoCorrente, N'''')
            THROW 52628, ''Stato, esito e date di workflow devono essere aggiornati dalla procedura dedicata.'', 1;

        UPDATE dbo.Campionature
        SET DataCampionatura = @DataCampionatura,
            IdRichiestaCliente = @IdRichiestaCliente,
            IdPreventivo = @IdPreventivo,
            IdVariantePreventivo = @IdVariantePreventivo,
            Oggetto = @Oggetto,
            DescrizioneCampione = NULLIF(LTRIM(RTRIM(@DescrizioneCampione)), N''''),
            Priorita = @Priorita,
            DataRichiestaCampione = @DataRichiestaCampione,
            DataPrevistaConsegna = @DataPrevistaConsegna,
            Note = NULLIF(LTRIM(RTRIM(@Note)), N''''),
            DataModifica = SYSDATETIME(),
            UtenteModifica = @Utente
        WHERE IdCampionatura = @IdCampionatura
          AND VersioneRiga = @VersioneRiga;

        IF @@ROWCOUNT = 0
            THROW 52606, ''La campionatura e stata modificata da un altro utente.'', 1;

        COMMIT TRANSACTION;
    END;';

    EXEC sys.sp_executesql N'
    CREATE OR ALTER PROCEDURE dbo.Campionature_Stato_Aggiorna
        @IdCampionatura INT,
        @Stato NVARCHAR(30),
        @DataConsegnaCampione DATE = NULL,
        @Esito NVARCHAR(30) = NULL,
        @VersioneRiga BINARY(8),
        @Utente NVARCHAR(256),
        @Amministratore BIT = 0,
        @MotivazioneCorrezione NVARCHAR(500) = NULL
    AS
    BEGIN
        SET NOCOUNT ON;
        SET XACT_ABORT ON;

        SET @Stato = NULLIF(LTRIM(RTRIM(@Stato)), N'''');
        SET @Esito = NULLIF(LTRIM(RTRIM(@Esito)), N'''');
        SET @Utente = NULLIF(LTRIM(RTRIM(@Utente)), N'''');
        SET @MotivazioneCorrezione = NULLIF(LTRIM(RTRIM(@MotivazioneCorrezione)), N'''');

        IF @Stato IS NULL OR @VersioneRiga IS NULL OR @Utente IS NULL
            THROW 52620, ''Dati obbligatori del cambio stato mancanti.'', 1;
        IF @Stato NOT IN (N''Aperta'', N''In Lavorazione'', N''In Verifica'', N''Inviata al Cliente'', N''Approvata'', N''Respinta'', N''Chiusa'', N''Annullata'')
            THROW 52622, ''Stato della campionatura non valido.'', 1;

        BEGIN TRANSACTION;

        DECLARE @StatoCorrente NVARCHAR(30);
        DECLARE @DataConsegnaCorrente DATE;
        DECLARE @EsitoCorrente NVARCHAR(30);
        DECLARE @VersioneCorrente BINARY(8);

        SELECT
            @StatoCorrente = Stato,
            @DataConsegnaCorrente = DataConsegnaCampione,
            @EsitoCorrente = Esito,
            @VersioneCorrente = VersioneRiga
        FROM dbo.Campionature WITH (UPDLOCK, HOLDLOCK)
        WHERE IdCampionatura = @IdCampionatura;

        IF @VersioneCorrente IS NULL
            THROW 52620, ''Campionatura non trovata.'', 1;
        IF @VersioneCorrente <> @VersioneRiga
            THROW 52621, ''La campionatura e stata modificata da un altro utente.'', 1;
        IF @StatoCorrente = @Stato
            THROW 52622, ''Selezionare uno stato differente.'', 1;

        DECLARE @TransizioneOrdinaria BIT = CASE
            WHEN @StatoCorrente = N''Aperta'' AND @Stato IN (N''In Lavorazione'', N''Annullata'') THEN 1
            WHEN @StatoCorrente = N''In Lavorazione'' AND @Stato IN (N''In Verifica'', N''Annullata'') THEN 1
            WHEN @StatoCorrente = N''In Verifica'' AND @Stato IN (N''In Lavorazione'', N''Inviata al Cliente'', N''Annullata'') THEN 1
            WHEN @StatoCorrente = N''Inviata al Cliente'' AND @Stato IN (N''In Verifica'', N''In Lavorazione'', N''Approvata'', N''Respinta'') THEN 1
            WHEN @StatoCorrente = N''Approvata'' AND @Stato = N''Chiusa'' THEN 1
            WHEN @StatoCorrente = N''Respinta'' AND @Stato = N''Chiusa'' THEN 1
            ELSE 0
        END;

        IF @TransizioneOrdinaria = 0 AND @Amministratore = 0
            THROW 52622, ''La transizione di stato non e consentita.'', 1;
        IF @TransizioneOrdinaria = 0 AND @MotivazioneCorrezione IS NULL
            THROW 52623, ''La correzione amministrativa richiede una motivazione.'', 1;

        DECLARE @DataConsegnaNuova DATE = COALESCE(@DataConsegnaCampione, @DataConsegnaCorrente);

        IF @Stato = N''Inviata al Cliente'' AND @DataConsegnaNuova IS NULL
            THROW 52624, ''Indicare la data di consegna effettiva.'', 1;

        IF @Stato = N''Approvata'' AND @Esito NOT IN (N''Positivo'', N''Positivo con modifiche'')
            THROW 52625, ''Una campionatura approvata richiede un esito positivo.'', 1;
        IF @Stato = N''Respinta'' AND ISNULL(@Esito, N'''') <> N''Negativo''
            THROW 52625, ''Una campionatura respinta richiede esito Negativo.'', 1;
        IF @Stato = N''In Lavorazione'' AND @Esito IS NOT NULL AND @Esito <> N''Da rifare''
            THROW 52625, ''Il ritorno in lavorazione ammette soltanto l''''esito Da rifare.'', 1;
        IF @Stato = N''Chiusa'' AND @Esito NOT IN (N''Positivo'', N''Positivo con modifiche'', N''Negativo'')
            THROW 52625, ''La chiusura richiede un esito conclusivo.'', 1;
        IF @Stato NOT IN (N''Approvata'', N''Respinta'', N''In Lavorazione'', N''Chiusa'')
            SET @Esito = NULL;

        IF @Stato IN (N''Approvata'', N''Respinta'', N''Chiusa'')
        BEGIN
            IF EXISTS
            (
                SELECT 1
                FROM dbo.CampionatureRilievi WITH (UPDLOCK, HOLDLOCK)
                WHERE IdCampionatura = @IdCampionatura
                  AND Stato NOT IN (N''Respinto'', N''Chiuso'')
            )
                THROW 52626, ''Sono presenti rilievi non conclusi.'', 1;

        END;

        IF @Stato = N''Chiusa'' AND EXISTS
        (
            SELECT 1
            FROM dbo.CampionatureAdeguamentiPreventivo WITH (UPDLOCK, HOLDLOCK)
            WHERE IdCampionatura = @IdCampionatura
              AND Applicato = 0
        )
            THROW 52627, ''Sono presenti adeguamenti non applicati.'', 1;

        UPDATE dbo.Campionature
        SET Stato = @Stato,
            DataConsegnaCampione = @DataConsegnaNuova,
            Esito = @Esito,
            DataChiusura = CASE
                WHEN @Stato IN (N''Chiusa'', N''Annullata'') THEN CONVERT(DATE, GETDATE())
                ELSE NULL
            END,
            DataModifica = SYSDATETIME(),
            UtenteModifica = @Utente
        WHERE IdCampionatura = @IdCampionatura
          AND VersioneRiga = @VersioneRiga;

        IF @@ROWCOUNT = 0
            THROW 52621, ''La campionatura e stata modificata da un altro utente.'', 1;

        IF @TransizioneOrdinaria = 0
        BEGIN
            INSERT INTO dbo.CampionatureCorrezioniStato
            (
                IdCampionatura,
                StatoPrecedente,
                StatoNuovo,
                Motivazione,
                DataCorrezione,
                UtenteCorrezione
            )
            VALUES
            (
                @IdCampionatura,
                @StatoCorrente,
                @Stato,
                @MotivazioneCorrezione,
                SYSDATETIME(),
                @Utente
            );
        END;

        COMMIT TRANSACTION;
    END;';

    EXEC sys.sp_executesql N'
    CREATE OR ALTER PROCEDURE dbo.Campionature_CorrezioniStato_Elenco
        @IdCampionatura INT
    AS
    BEGIN
        SET NOCOUNT ON;

        SELECT
            IdCorrezioneStato,
            StatoPrecedente,
            StatoNuovo,
            Motivazione,
            DataCorrezione,
            UtenteCorrezione
        FROM dbo.CampionatureCorrezioniStato
        WHERE IdCampionatura = @IdCampionatura
        ORDER BY IdCorrezioneStato DESC;
    END;';
    /* PAYLOAD TEC-015-CAMPIONATURA-WORKFLOW END */

    DECLARE @Versione INT = 2026110201;
    DECLARE @CodiceIntervento NVARCHAR(50) = N'TEC-015-CAMPIONATURA-WORKFLOW';
    DECLARE @NomeScript NVARCHAR(260) = N'TEC-015_05_Workflow_Stato_Campionature.sql';
    -- SHA-256 del contenuto fra i marcatori PAYLOAD inclusi, normalizzato con LF.
    DECLARE @ImprontaSha256 CHAR(64) = '5C531ADB84122B955E8F97FCC79F5D9A51CDD1701199D45AA8DAD835F749A1C3';

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
        THROW 53099, 'TEC-015-CAMPIONATURA-WORKFLOW: versione gia registrata con dati o impronta differenti.', 1;

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
        N'Workflow controllato dello stato della campionatura e audit amministrativo.',
        @ImprontaSha256
    );

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0
        ROLLBACK TRANSACTION;
    THROW;
END CATCH;
