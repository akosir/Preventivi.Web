/*
    TEC-014 - Gestione Campionature
    Versione schema: 2026102702
    Prerequisito: versione 2026102701 (TEC-013-RIATTIVA).

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
        THROW 52690, 'TEC-014-BASE: registro VersioniSchema non disponibile.', 1;

    IF NOT EXISTS
    (
        SELECT 1
        FROM dbo.VersioniSchema
        WHERE Versione = 2026102701
          AND CodiceIntervento = N'TEC-013-RIATTIVA'
    )
        THROW 52691, 'TEC-014-BASE: versione richiesta 2026102701 non installata.', 1;

    IF EXISTS
    (
        SELECT 1
        FROM dbo.VersioniSchema
        WHERE Versione > 2026102701
          AND Versione <> 2026102702
    )
        THROW 52692, 'TEC-014-BASE: il database contiene una versione successiva non riconosciuta.', 1;

    IF OBJECT_ID(N'dbo.Campionature', N'U') IS NULL
       OR OBJECT_ID(N'dbo.RichiesteClienti', N'U') IS NULL
       OR OBJECT_ID(N'dbo.Clienti', N'U') IS NULL
       OR OBJECT_ID(N'dbo.Preventivi', N'U') IS NULL
       OR OBJECT_ID(N'dbo.PreventiviVarianti', N'U') IS NULL
        THROW 52693, 'TEC-014-BASE: tabelle richieste non disponibili.', 1;

    /* PAYLOAD TEC-014-BASE START */
    IF COL_LENGTH(N'dbo.Campionature', N'UtenteCreazione') IS NULL
        EXEC sys.sp_executesql N'
        ALTER TABLE dbo.Campionature
            ADD UtenteCreazione NVARCHAR(256) NULL;';

    EXEC sys.sp_executesql N'
        UPDATE dbo.Campionature
        SET UtenteCreazione = N''MIGRAZIONE-TEC-014''
        WHERE UtenteCreazione IS NULL;';

    IF EXISTS
    (
        SELECT 1
        FROM sys.columns
        WHERE object_id = OBJECT_ID(N'dbo.Campionature')
          AND name = N'UtenteCreazione'
          AND is_nullable = 1
    )
        EXEC sys.sp_executesql N'
        ALTER TABLE dbo.Campionature
            ALTER COLUMN UtenteCreazione NVARCHAR(256) NOT NULL;';

    IF NOT EXISTS
    (
        SELECT 1
        FROM sys.default_constraints AS vincolo
        INNER JOIN sys.columns AS colonna
            ON colonna.object_id = vincolo.parent_object_id
           AND colonna.column_id = vincolo.parent_column_id
        WHERE vincolo.parent_object_id = OBJECT_ID(N'dbo.Campionature')
          AND colonna.name = N'UtenteCreazione'
    )
        EXEC sys.sp_executesql N'
        ALTER TABLE dbo.Campionature
            ADD CONSTRAINT DF_Campionature_UtenteCreazione
            DEFAULT ORIGINAL_LOGIN() FOR UtenteCreazione;';

    IF COL_LENGTH(N'dbo.Campionature', N'UtenteModifica') IS NULL
        EXEC sys.sp_executesql N'
        ALTER TABLE dbo.Campionature
            ADD UtenteModifica NVARCHAR(256) NULL;';

    IF COL_LENGTH(N'dbo.Campionature', N'VersioneRiga') IS NULL
        EXEC sys.sp_executesql N'
        ALTER TABLE dbo.Campionature
            ADD VersioneRiga ROWVERSION NOT NULL;';

    EXEC sys.sp_executesql N'
    CREATE OR ALTER PROCEDURE dbo.Campionature_Elenco
        @Ricerca NVARCHAR(300) = NULL,
        @IdCliente INT = NULL,
        @IdRichiestaCliente INT = NULL,
        @Stato NVARCHAR(30) = NULL,
        @Priorita NVARCHAR(20) = NULL,
        @ConsegnaDa DATE = NULL,
        @ConsegnaA DATE = NULL
    AS
    BEGIN
        SET NOCOUNT ON;

        SET @Ricerca = NULLIF(LTRIM(RTRIM(@Ricerca)), N'''' );

        SELECT
            campionatura.IdCampionatura,
            campionatura.NumeroCampionatura,
            campionatura.Anno,
            campionatura.DataCampionatura,
            campionatura.IdRichiestaCliente,
            CONCAT(richiesta.Anno, N''-'', RIGHT(N''00000'' + CONVERT(NVARCHAR(10), richiesta.NumeroRichiesta), 5)) AS NumeroRichiesta,
            cliente.IdCliente,
            cliente.CodiceCliente,
            cliente.RagioneSociale AS Cliente,
            campionatura.Oggetto,
            campionatura.Stato,
            campionatura.Priorita,
            campionatura.DataPrevistaConsegna,
            campionatura.Esito
        FROM dbo.Campionature AS campionatura
        INNER JOIN dbo.RichiesteClienti AS richiesta
            ON richiesta.IdRichiestaCliente = campionatura.IdRichiestaCliente
        INNER JOIN dbo.Clienti AS cliente
            ON cliente.IdCliente = richiesta.IdCliente
        WHERE (@IdCliente IS NULL OR richiesta.IdCliente = @IdCliente)
          AND (@IdRichiestaCliente IS NULL OR campionatura.IdRichiestaCliente = @IdRichiestaCliente)
          AND (@Stato IS NULL OR campionatura.Stato = @Stato)
          AND (@Priorita IS NULL OR campionatura.Priorita = @Priorita)
          AND (@ConsegnaDa IS NULL OR campionatura.DataPrevistaConsegna >= @ConsegnaDa)
          AND (@ConsegnaA IS NULL OR campionatura.DataPrevistaConsegna <= @ConsegnaA)
          AND
          (
              @Ricerca IS NULL
              OR cliente.CodiceCliente LIKE N''%'' + @Ricerca + N''%''
              OR cliente.RagioneSociale LIKE N''%'' + @Ricerca + N''%''
              OR campionatura.Oggetto LIKE N''%'' + @Ricerca + N''%''
              OR campionatura.DescrizioneCampione LIKE N''%'' + @Ricerca + N''%''
              OR richiesta.Oggetto LIKE N''%'' + @Ricerca + N''%''
              OR CONCAT(campionatura.Anno, N''-'', RIGHT(N''00000'' + CONVERT(NVARCHAR(10), campionatura.NumeroCampionatura), 5)) LIKE N''%'' + @Ricerca + N''%''
              OR CONCAT(richiesta.Anno, N''-'', RIGHT(N''00000'' + CONVERT(NVARCHAR(10), richiesta.NumeroRichiesta), 5)) LIKE N''%'' + @Ricerca + N''%''
          )
        ORDER BY campionatura.DataCampionatura DESC, campionatura.Anno DESC, campionatura.NumeroCampionatura DESC;
    END;';

    EXEC sys.sp_executesql N'
    CREATE OR ALTER PROCEDURE dbo.Campionature_Dettaglio
        @IdCampionatura INT
    AS
    BEGIN
        SET NOCOUNT ON;

        SELECT
            campionatura.IdCampionatura,
            campionatura.NumeroCampionatura,
            campionatura.Anno,
            campionatura.DataCampionatura,
            campionatura.IdRichiestaCliente,
            CONCAT(richiesta.Anno, N''-'', RIGHT(N''00000'' + CONVERT(NVARCHAR(10), richiesta.NumeroRichiesta), 5)) AS NumeroRichiesta,
            cliente.IdCliente,
            cliente.CodiceCliente,
            cliente.RagioneSociale AS Cliente,
            campionatura.IdPreventivo,
            CASE WHEN preventivo.IdPreventivo IS NULL THEN NULL
                 ELSE CONCAT(preventivo.Anno, N''-'', RIGHT(N''00000'' + CONVERT(NVARCHAR(10), preventivo.NumeroPreventivo), 5)) END AS NumeroPreventivo,
            campionatura.IdVariantePreventivo,
            CASE WHEN variante.IdVariantePreventivo IS NULL THEN NULL
                 ELSE CONCAT(variante.CodiceVariante, N'' - '', variante.DescrizioneVariante) END AS VariantePreventivo,
            campionatura.Oggetto,
            campionatura.DescrizioneCampione,
            campionatura.Stato,
            campionatura.Priorita,
            campionatura.DataRichiestaCampione,
            campionatura.DataPrevistaConsegna,
            campionatura.DataConsegnaCampione,
            campionatura.DataChiusura,
            campionatura.Esito,
            campionatura.Note,
            campionatura.DataCreazione,
            campionatura.DataModifica,
            campionatura.UtenteCreazione,
            campionatura.UtenteModifica,
            campionatura.VersioneRiga
        FROM dbo.Campionature AS campionatura
        INNER JOIN dbo.RichiesteClienti AS richiesta
            ON richiesta.IdRichiestaCliente = campionatura.IdRichiestaCliente
        INNER JOIN dbo.Clienti AS cliente
            ON cliente.IdCliente = richiesta.IdCliente
        LEFT JOIN dbo.Preventivi AS preventivo
            ON preventivo.IdPreventivo = campionatura.IdPreventivo
        LEFT JOIN dbo.PreventiviVarianti AS variante
            ON variante.IdVariantePreventivo = campionatura.IdVariantePreventivo
        WHERE campionatura.IdCampionatura = @IdCampionatura;
    END;';

    EXEC sys.sp_executesql N'
    CREATE OR ALTER PROCEDURE dbo.Campionature_Richieste_Elenco
    AS
    BEGIN
        SET NOCOUNT ON;

        SELECT
            richiesta.IdRichiestaCliente,
            CONCAT(richiesta.Anno, N''-'', RIGHT(N''00000'' + CONVERT(NVARCHAR(10), richiesta.NumeroRichiesta), 5)) AS NumeroRichiesta,
            cliente.IdCliente,
            cliente.CodiceCliente,
            cliente.RagioneSociale AS Cliente,
            richiesta.Oggetto,
            richiesta.Priorita,
            richiesta.Stato
        FROM dbo.RichiesteClienti AS richiesta
        INNER JOIN dbo.Clienti AS cliente
            ON cliente.IdCliente = richiesta.IdCliente
        ORDER BY richiesta.DataRichiesta DESC, richiesta.Anno DESC, richiesta.NumeroRichiesta DESC;
    END;';

    EXEC sys.sp_executesql N'
    CREATE OR ALTER PROCEDURE dbo.Campionature_Preventivi_Elenco
    AS
    BEGIN
        SET NOCOUNT ON;

        SELECT
            preventivo.IdPreventivo,
            preventivo.IdRichiestaCliente,
            CONCAT(preventivo.Anno, N''-'', RIGHT(N''00000'' + CONVERT(NVARCHAR(10), preventivo.NumeroPreventivo), 5)) AS NumeroPreventivo,
            ISNULL(preventivo.Oggetto, N'''') AS Oggetto,
            preventivo.Stato
        FROM dbo.Preventivi AS preventivo
        WHERE preventivo.IdRichiestaCliente IS NOT NULL
        ORDER BY preventivo.DataPreventivo DESC, preventivo.Anno DESC, preventivo.NumeroPreventivo DESC;
    END;';

    EXEC sys.sp_executesql N'
    CREATE OR ALTER PROCEDURE dbo.Campionature_Varianti_Elenco
    AS
    BEGIN
        SET NOCOUNT ON;

        SELECT
            variante.IdVariantePreventivo,
            variante.IdPreventivo,
            variante.CodiceVariante,
            variante.DescrizioneVariante
        FROM dbo.PreventiviVarianti AS variante
        ORDER BY variante.IdPreventivo, variante.CodiceVariante;
    END;';

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
        IF @Stato NOT IN (N''Aperta'', N''In Lavorazione'', N''In Verifica'', N''Inviata al Cliente'', N''Approvata'', N''Respinta'', N''Chiusa'', N''Annullata'')
            THROW 52601, ''Stato della campionatura non valido.'', 1;
        IF @Priorita NOT IN (N''Bassa'', N''Media'', N''Alta'', N''Urgente'')
            THROW 52601, ''Priorita della campionatura non valida.'', 1;
        IF @Esito IS NOT NULL AND @Esito NOT IN (N''Positivo'', N''Positivo con modifiche'', N''Negativo'', N''Da rifare'')
            THROW 52601, ''Esito della campionatura non valido.'', 1;
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
            @Stato, @Priorita, @DataRichiestaCampione, @DataPrevistaConsegna,
            @DataConsegnaCampione, @DataChiusura, @Esito, NULLIF(LTRIM(RTRIM(@Note)), N''''), @Utente
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
        IF @Stato NOT IN (N''Aperta'', N''In Lavorazione'', N''In Verifica'', N''Inviata al Cliente'', N''Approvata'', N''Respinta'', N''Chiusa'', N''Annullata'')
            THROW 52601, ''Stato della campionatura non valido.'', 1;
        IF @Priorita NOT IN (N''Bassa'', N''Media'', N''Alta'', N''Urgente'')
            THROW 52601, ''Priorita della campionatura non valida.'', 1;
        IF @Esito IS NOT NULL AND @Esito NOT IN (N''Positivo'', N''Positivo con modifiche'', N''Negativo'', N''Da rifare'')
            THROW 52601, ''Esito della campionatura non valido.'', 1;
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

        DECLARE @AnnoCorrente INT;
        DECLARE @VersioneCorrente BINARY(8);

        SELECT
            @AnnoCorrente = Anno,
            @VersioneCorrente = VersioneRiga
        FROM dbo.Campionature
        WHERE IdCampionatura = @IdCampionatura;

        IF @AnnoCorrente IS NULL
            THROW 52608, ''Campionatura non trovata.'', 1;
        IF @VersioneCorrente <> @VersioneRiga
            THROW 52606, ''La campionatura e stata modificata da un altro utente.'', 1;
        IF YEAR(@DataCampionatura) <> @AnnoCorrente
            THROW 52607, ''La data deve rimanere nello stesso anno del numero progressivo.'', 1;

        UPDATE dbo.Campionature
        SET DataCampionatura = @DataCampionatura,
            IdRichiestaCliente = @IdRichiestaCliente,
            IdPreventivo = @IdPreventivo,
            IdVariantePreventivo = @IdVariantePreventivo,
            Oggetto = @Oggetto,
            DescrizioneCampione = NULLIF(LTRIM(RTRIM(@DescrizioneCampione)), N''''),
            Stato = @Stato,
            Priorita = @Priorita,
            DataRichiestaCampione = @DataRichiestaCampione,
            DataPrevistaConsegna = @DataPrevistaConsegna,
            DataConsegnaCampione = @DataConsegnaCampione,
            DataChiusura = @DataChiusura,
            Esito = @Esito,
            Note = NULLIF(LTRIM(RTRIM(@Note)), N''''),
            DataModifica = SYSDATETIME(),
            UtenteModifica = @Utente
        WHERE IdCampionatura = @IdCampionatura
          AND VersioneRiga = @VersioneRiga;

        IF @@ROWCOUNT = 0
            THROW 52606, ''La campionatura e stata modificata da un altro utente.'', 1;
    END;';
    /* PAYLOAD TEC-014-BASE END */

    DECLARE @Versione INT = 2026102702;
    DECLARE @CodiceIntervento NVARCHAR(50) = N'TEC-014-BASE';
    DECLARE @NomeScript NVARCHAR(260) = N'TEC-014_01_Gestione_Campionature.sql';
    -- SHA-256 del contenuto fra i marcatori PAYLOAD inclusi, normalizzato con LF.
    DECLARE @ImprontaSha256 CHAR(64) =
        'E77274BCFF8175A7DCBDD07DB981DF0ECC0105F8E1D2BC870EBC7BC994D999BE';

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
        THROW 52699, 'TEC-014-BASE: versione gia registrata con dati o impronta differenti.', 1;

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
        N'Gestione base delle campionature con ricerca, modifica, audit e concorrenza.',
        @ImprontaSha256
    );

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0
        ROLLBACK TRANSACTION;
    THROW;
END CATCH;
