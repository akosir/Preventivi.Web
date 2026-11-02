/*
    TEC-015 - Workflow stati, correzioni amministrative e allegati puntuali
    Versione schema: 2026103001
    Prerequisito: versione 2026102902 (TEC-015-MODIFICA).

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
        THROW 52890, 'TEC-015-WORKFLOW: registro VersioniSchema non disponibile.', 1;

    IF NOT EXISTS
    (
        SELECT 1
        FROM dbo.VersioniSchema
        WHERE Versione = 2026102902
          AND CodiceIntervento = N'TEC-015-MODIFICA'
    )
        THROW 52891, 'TEC-015-WORKFLOW: versione richiesta 2026102902 non installata.', 1;

    IF EXISTS
    (
        SELECT 1
        FROM dbo.VersioniSchema
        WHERE Versione > 2026102902
          AND Versione <> 2026103001
    )
        THROW 52892, 'TEC-015-WORKFLOW: il database contiene una versione successiva non riconosciuta.', 1;

    IF OBJECT_ID(N'dbo.CampionatureRilievi', N'U') IS NULL
       OR OBJECT_ID(N'dbo.CampionatureAdeguamentiPreventivo', N'U') IS NULL
       OR OBJECT_ID(N'dbo.Allegati', N'U') IS NULL
       OR COL_LENGTH(N'dbo.CampionatureRilievi', N'VersioneRiga') IS NULL
       OR COL_LENGTH(N'dbo.CampionatureAdeguamentiPreventivo', N'VersioneRiga') IS NULL
        THROW 52893, 'TEC-015-WORKFLOW: struttura TEC-015 non disponibile.', 1;

    /* PAYLOAD TEC-015-WORKFLOW START */
    IF OBJECT_ID(N'dbo.CampionatureRilieviCorrezioniStato', N'U') IS NULL
        EXEC sys.sp_executesql N'
        CREATE TABLE dbo.CampionatureRilieviCorrezioniStato
        (
            IdCorrezioneStato BIGINT IDENTITY(1,1) NOT NULL
                CONSTRAINT PK_CampionatureRilieviCorrezioniStato PRIMARY KEY,
            IdRilievoCampionatura INT NOT NULL,
            IdCampionatura INT NOT NULL,
            RigaNr INT NOT NULL,
            StatoPrecedente NVARCHAR(30) NOT NULL,
            StatoNuovo NVARCHAR(30) NOT NULL,
            Motivazione NVARCHAR(500) NOT NULL,
            DataCorrezione DATETIME2(0) NOT NULL
                CONSTRAINT DF_CampionatureRilieviCorrezioniStato_DataCorrezione
                DEFAULT (SYSDATETIME()),
            UtenteCorrezione NVARCHAR(256) NOT NULL
        );';

    IF NOT EXISTS
    (
        SELECT 1
        FROM sys.indexes
        WHERE object_id = OBJECT_ID(N'dbo.CampionatureRilieviCorrezioniStato')
          AND name = N'IX_CampionatureRilieviCorrezioniStato_Rilievo'
    )
        EXEC sys.sp_executesql N'
        CREATE INDEX IX_CampionatureRilieviCorrezioniStato_Rilievo
            ON dbo.CampionatureRilieviCorrezioniStato
            (
                IdRilievoCampionatura,
                IdCorrezioneStato DESC
            );';

    EXEC sys.sp_executesql N'
    CREATE OR ALTER PROCEDURE dbo.Campionature_Rilievi_Stato_Aggiorna
        @IdRilievoCampionatura INT,
        @Stato NVARCHAR(30),
        @VersioneRiga BINARY(8),
        @Utente NVARCHAR(256),
        @Amministratore BIT = 0,
        @MotivazioneCorrezione NVARCHAR(500) = NULL
    AS
    BEGIN
        SET NOCOUNT ON;
        SET XACT_ABORT ON;

        SET @Stato = NULLIF(LTRIM(RTRIM(@Stato)), N'''');
        SET @Utente = NULLIF(LTRIM(RTRIM(@Utente)), N'''');
        SET @MotivazioneCorrezione = NULLIF(LTRIM(RTRIM(@MotivazioneCorrezione)), N'''');

        IF @Stato NOT IN
        (
            N''Aperto'', N''In Analisi'', N''Soluzione Proposta'',
            N''Risolto'', N''Respinto'', N''Chiuso''
        )
            THROW 52706, ''Stato del rilievo non valido.'', 1;
        IF @VersioneRiga IS NULL OR @Utente IS NULL
            THROW 52701, ''Dati obbligatori del rilievo mancanti.'', 1;

        BEGIN TRANSACTION;

        DECLARE @StatoCorrente NVARCHAR(30);
        DECLARE @VersioneCorrente BINARY(8);
        DECLARE @IdCampionatura INT;
        DECLARE @RigaNr INT;

        SELECT
            @StatoCorrente = Stato,
            @VersioneCorrente = VersioneRiga,
            @IdCampionatura = IdCampionatura,
            @RigaNr = RigaNr
        FROM dbo.CampionatureRilievi WITH (UPDLOCK, HOLDLOCK)
        WHERE IdRilievoCampionatura = @IdRilievoCampionatura;

        IF @StatoCorrente IS NULL
            THROW 52707, ''Rilievo non trovato.'', 1;
        IF @VersioneCorrente <> @VersioneRiga
            THROW 52708, ''Il rilievo e stato modificato da un altro utente.'', 1;
        IF @StatoCorrente = @Stato
            THROW 52734, ''Il nuovo stato coincide con quello corrente.'', 1;

        DECLARE @TransizioneOrdinaria BIT =
            CASE
                WHEN @StatoCorrente = N''Aperto''
                     AND @Stato IN (N''In Analisi'', N''Respinto'') THEN 1
                WHEN @StatoCorrente = N''In Analisi''
                     AND @Stato IN (N''Soluzione Proposta'', N''Respinto'') THEN 1
                WHEN @StatoCorrente = N''Soluzione Proposta''
                     AND @Stato IN (N''In Analisi'', N''Risolto'') THEN 1
                WHEN @StatoCorrente = N''Risolto''
                     AND @Stato IN (N''In Analisi'', N''Chiuso'') THEN 1
                ELSE 0
            END;

        IF @TransizioneOrdinaria = 0 AND ISNULL(@Amministratore, 0) = 0
            THROW 52734, ''La transizione di stato non e consentita.'', 1;
        IF @TransizioneOrdinaria = 0 AND @MotivazioneCorrezione IS NULL
            THROW 52735, ''La correzione amministrativa richiede una motivazione.'', 1;

        UPDATE dbo.CampionatureRilievi
        SET Stato = @Stato,
            DataChiusura = CASE
                WHEN @Stato IN (N''Respinto'', N''Chiuso'')
                    THEN CONVERT(DATE, GETDATE())
                ELSE NULL
            END,
            DataModifica = SYSDATETIME(),
            UtenteModifica = @Utente
        WHERE IdRilievoCampionatura = @IdRilievoCampionatura
          AND VersioneRiga = @VersioneRiga;

        IF @@ROWCOUNT = 0
            THROW 52708, ''Il rilievo e stato modificato da un altro utente.'', 1;

        IF @TransizioneOrdinaria = 0
        BEGIN
            INSERT INTO dbo.CampionatureRilieviCorrezioniStato
            (
                IdRilievoCampionatura,
                IdCampionatura,
                RigaNr,
                StatoPrecedente,
                StatoNuovo,
                Motivazione,
                DataCorrezione,
                UtenteCorrezione
            )
            VALUES
            (
                @IdRilievoCampionatura,
                @IdCampionatura,
                @RigaNr,
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
    CREATE OR ALTER PROCEDURE dbo.Campionature_Rilievi_CorrezioniStato_Elenco
        @IdRilievoCampionatura INT
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
        FROM dbo.CampionatureRilieviCorrezioniStato
        WHERE IdRilievoCampionatura = @IdRilievoCampionatura
        ORDER BY IdCorrezioneStato DESC;
    END;';

    EXEC sys.sp_executesql N'
    CREATE OR ALTER PROCEDURE dbo.Campionature_Rilievi_Elimina
        @IdRilievoCampionatura INT,
        @VersioneRiga BINARY(8)
    AS
    BEGIN
        SET NOCOUNT ON;
        SET XACT_ABORT ON;

        BEGIN TRANSACTION;

        DECLARE @Stato NVARCHAR(30);
        DECLARE @VersioneCorrente BINARY(8);

        SELECT @Stato = Stato, @VersioneCorrente = VersioneRiga
        FROM dbo.CampionatureRilievi WITH (UPDLOCK, HOLDLOCK)
        WHERE IdRilievoCampionatura = @IdRilievoCampionatura;

        IF @Stato IS NULL
            THROW 52723, ''Rilievo non trovato.'', 1;
        IF @VersioneRiga IS NULL OR @VersioneCorrente <> @VersioneRiga
            THROW 52724, ''Il rilievo e stato modificato da un altro utente.'', 1;
        IF @Stato <> N''Aperto''
            THROW 52726, ''E possibile eliminare soltanto un rilievo ancora Aperto.'', 1;
        IF EXISTS
        (
            SELECT 1
            FROM dbo.CampionatureAdeguamentiPreventivo WITH (UPDLOCK, HOLDLOCK)
            WHERE IdRilievoCampionatura = @IdRilievoCampionatura
        )
            THROW 52727, ''Il rilievo possiede adeguamenti e non puo essere eliminato.'', 1;
        IF EXISTS
        (
            SELECT 1
            FROM dbo.Allegati WITH (UPDLOCK, HOLDLOCK)
            WHERE Entita = N''CampionatureRilievi''
              AND IdEntita = @IdRilievoCampionatura
        )
            THROW 52736, ''Il rilievo possiede allegati e non puo essere eliminato.'', 1;

        DELETE FROM dbo.CampionatureRilievi
        WHERE IdRilievoCampionatura = @IdRilievoCampionatura
          AND VersioneRiga = @VersioneRiga;

        IF @@ROWCOUNT = 0
            THROW 52724, ''Il rilievo e stato modificato da un altro utente.'', 1;

        COMMIT TRANSACTION;
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
        DECLARE @VersioneAdeguamentoCorrente BINARY(8);
        DECLARE @VersioneRilievoCorrente BINARY(8);

        SELECT
            @IdRilievoCampionatura = adeguamento.IdRilievoCampionatura,
            @Applicato = adeguamento.Applicato,
            @VersioneAdeguamentoCorrente = adeguamento.VersioneRiga
        FROM dbo.CampionatureAdeguamentiPreventivo AS adeguamento WITH (UPDLOCK, HOLDLOCK)
        WHERE adeguamento.IdAdeguamento = @IdAdeguamento;

        IF @IdRilievoCampionatura IS NULL
            THROW 52729, ''Adeguamento non trovato.'', 1;
        IF @VersioneAdeguamentoCorrente <> @VersioneRiga
            THROW 52730, ''L''''adeguamento e stato modificato da un altro utente.'', 1;
        IF @Applicato = 1
            THROW 52731, ''Un adeguamento applicato non puo essere eliminato.'', 1;
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
    /* PAYLOAD TEC-015-WORKFLOW END */

    DECLARE @Versione INT = 2026103001;
    DECLARE @CodiceIntervento NVARCHAR(50) = N'TEC-015-WORKFLOW';
    DECLARE @NomeScript NVARCHAR(260) = N'TEC-015_03_Workflow_Stati_Allegati.sql';
    -- SHA-256 del contenuto fra i marcatori PAYLOAD inclusi, normalizzato con LF.
    DECLARE @ImprontaSha256 CHAR(64) = '69411D69433CF8581EBA21EE87C2AC9F670873730B928FD430C84789BD0CBA9A';

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
        THROW 52899, 'TEC-015-WORKFLOW: versione gia registrata con dati o impronta differenti.', 1;

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
        N'Workflow rilievi, correzioni amministrative e allegati di rilievi e adeguamenti.',
        @ImprontaSha256
    );

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0
        ROLLBACK TRANSACTION;
    THROW;
END CATCH;
