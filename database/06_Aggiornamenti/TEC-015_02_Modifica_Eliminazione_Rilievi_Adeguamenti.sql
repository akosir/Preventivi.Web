/*
    TEC-015 - Modifica ed eliminazione rilievi e adeguamenti
    Versione schema: 2026102902
    Prerequisito: versione 2026102901 (TEC-015).

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
        THROW 52790, 'TEC-015-MODIFICA: registro VersioniSchema non disponibile.', 1;

    IF NOT EXISTS
    (
        SELECT 1
        FROM dbo.VersioniSchema
        WHERE Versione = 2026102901
          AND CodiceIntervento = N'TEC-015'
    )
        THROW 52791, 'TEC-015-MODIFICA: versione richiesta 2026102901 non installata.', 1;

    IF EXISTS
    (
        SELECT 1
        FROM dbo.VersioniSchema
        WHERE Versione > 2026102901
          AND Versione <> 2026102902
    )
        THROW 52792, 'TEC-015-MODIFICA: il database contiene una versione successiva non riconosciuta.', 1;

    IF OBJECT_ID(N'dbo.CampionatureRilievi', N'U') IS NULL
       OR OBJECT_ID(N'dbo.CampionatureAdeguamentiPreventivo', N'U') IS NULL
       OR COL_LENGTH(N'dbo.CampionatureRilievi', N'VersioneRiga') IS NULL
       OR COL_LENGTH(N'dbo.CampionatureAdeguamentiPreventivo', N'VersioneRiga') IS NULL
        THROW 52793, 'TEC-015-MODIFICA: struttura TEC-015 non disponibile.', 1;

    /* PAYLOAD TEC-015-MODIFICA START */
    IF COL_LENGTH(N'dbo.CampionatureAdeguamentiPreventivo', N'DataModifica') IS NULL
        EXEC sys.sp_executesql N'
        ALTER TABLE dbo.CampionatureAdeguamentiPreventivo
            ADD DataModifica DATETIME2(0) NULL;';

    IF COL_LENGTH(N'dbo.CampionatureAdeguamentiPreventivo', N'UtenteModifica') IS NULL
        EXEC sys.sp_executesql N'
        ALTER TABLE dbo.CampionatureAdeguamentiPreventivo
            ADD UtenteModifica NVARCHAR(256) NULL;';

    EXEC sys.sp_executesql N'
    CREATE OR ALTER PROCEDURE dbo.Campionature_Rilievi_Aggiorna
        @IdRilievoCampionatura INT,
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
        @VersioneRiga BINARY(8),
        @Utente NVARCHAR(256)
    AS
    BEGIN
        SET NOCOUNT ON;
        SET XACT_ABORT ON;

        SET @DescrizioneProblema = NULLIF(LTRIM(RTRIM(@DescrizioneProblema)), N'''');
        SET @Gravita = NULLIF(LTRIM(RTRIM(@Gravita)), N'''');
        SET @Utente = NULLIF(LTRIM(RTRIM(@Utente)), N'''');

        IF @DataRilevazione IS NULL OR @DescrizioneProblema IS NULL
           OR @VersioneRiga IS NULL OR @Utente IS NULL
            THROW 52720, ''Dati obbligatori del rilievo mancanti.'', 1;
        IF @Gravita NOT IN (N''Bassa'', N''Media'', N''Alta'', N''Critica'')
            THROW 52720, ''Gravita del rilievo non valida.'', 1;
        IF NOT EXISTS
        (
            SELECT 1 FROM dbo.TipiProblematicheQualita
            WHERE IdTipoProblematica = @IdTipoProblematica AND Attivo = 1
        )
            THROW 52721, ''Tipo di problematica non trovato o non attivo.'', 1;
        IF @IdProblematicaStandard IS NOT NULL AND NOT EXISTS
        (
            SELECT 1 FROM dbo.ProblematicheStandard
            WHERE IdProblematicaStandard = @IdProblematicaStandard
              AND IdTipoProblematica = @IdTipoProblematica
              AND Attiva = 1
        )
            THROW 52722, ''Problematica standard non coerente con il tipo selezionato.'', 1;

        DECLARE @Stato NVARCHAR(30);
        DECLARE @VersioneCorrente BINARY(8);

        SELECT @Stato = Stato, @VersioneCorrente = VersioneRiga
        FROM dbo.CampionatureRilievi
        WHERE IdRilievoCampionatura = @IdRilievoCampionatura;

        IF @Stato IS NULL
            THROW 52723, ''Rilievo non trovato.'', 1;
        IF @VersioneCorrente <> @VersioneRiga
            THROW 52724, ''Il rilievo e stato modificato da un altro utente.'', 1;
        IF @Stato IN (N''Respinto'', N''Chiuso'')
            THROW 52725, ''Un rilievo concluso non puo essere modificato.'', 1;

        UPDATE dbo.CampionatureRilievi
        SET DataRilevazione = @DataRilevazione,
            IdTipoProblematica = @IdTipoProblematica,
            IdProblematicaStandard = @IdProblematicaStandard,
            DescrizioneProblema = @DescrizioneProblema,
            Gravita = @Gravita,
            CausaPresunta = NULLIF(LTRIM(RTRIM(@CausaPresunta)), N''''),
            SoluzioneProposta = NULLIF(LTRIM(RTRIM(@SoluzioneProposta)), N''''),
            RichiedeNuovoCampione = @RichiedeNuovoCampione,
            NoteCliente = NULLIF(LTRIM(RTRIM(@NoteCliente)), N''''),
            NoteInterne = NULLIF(LTRIM(RTRIM(@NoteInterne)), N''''),
            DataModifica = SYSDATETIME(),
            UtenteModifica = @Utente
        WHERE IdRilievoCampionatura = @IdRilievoCampionatura
          AND VersioneRiga = @VersioneRiga;

        IF @@ROWCOUNT = 0
            THROW 52724, ''Il rilievo e stato modificato da un altro utente.'', 1;
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

        DELETE FROM dbo.CampionatureRilievi
        WHERE IdRilievoCampionatura = @IdRilievoCampionatura
          AND VersioneRiga = @VersioneRiga;

        IF @@ROWCOUNT = 0
            THROW 52724, ''Il rilievo e stato modificato da un altro utente.'', 1;

        COMMIT TRANSACTION;
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
            adeguamento.DescrizioneAdeguamento,
            adeguamento.ImpattoCostoStimato,
            adeguamento.ImpattoVenditaStimato,
            adeguamento.Applicato,
            adeguamento.DataApplicazione,
            adeguamento.Note,
            adeguamento.VersioneRiga,
            rilievo.VersioneRiga AS VersioneRilievo
        FROM dbo.CampionatureAdeguamentiPreventivo AS adeguamento
        INNER JOIN dbo.CampionatureRilievi AS rilievo
            ON rilievo.IdRilievoCampionatura = adeguamento.IdRilievoCampionatura
        WHERE adeguamento.IdAdeguamento = @IdAdeguamento;
    END;';

    EXEC sys.sp_executesql N'
    CREATE OR ALTER PROCEDURE dbo.Campionature_Adeguamenti_Aggiorna
        @IdAdeguamento INT,
        @DescrizioneAdeguamento NVARCHAR(MAX),
        @ImpattoCostoStimato DECIMAL(18,2),
        @ImpattoVenditaStimato DECIMAL(18,2),
        @Note NVARCHAR(MAX) = NULL,
        @VersioneRiga BINARY(8),
        @Utente NVARCHAR(256)
    AS
    BEGIN
        SET NOCOUNT ON;
        SET XACT_ABORT ON;

        SET @DescrizioneAdeguamento = NULLIF(LTRIM(RTRIM(@DescrizioneAdeguamento)), N'''');
        SET @Utente = NULLIF(LTRIM(RTRIM(@Utente)), N'''');

        IF @DescrizioneAdeguamento IS NULL OR @VersioneRiga IS NULL OR @Utente IS NULL
            THROW 52728, ''Dati obbligatori dell''''adeguamento mancanti.'', 1;

        DECLARE @Applicato BIT;
        DECLARE @VersioneCorrente BINARY(8);

        SELECT @Applicato = Applicato, @VersioneCorrente = VersioneRiga
        FROM dbo.CampionatureAdeguamentiPreventivo
        WHERE IdAdeguamento = @IdAdeguamento;

        IF @Applicato IS NULL
            THROW 52729, ''Adeguamento non trovato.'', 1;
        IF @VersioneCorrente <> @VersioneRiga
            THROW 52730, ''L''''adeguamento e stato modificato da un altro utente.'', 1;
        IF @Applicato = 1
            THROW 52731, ''Un adeguamento applicato non puo essere modificato.'', 1;

        UPDATE dbo.CampionatureAdeguamentiPreventivo
        SET DescrizioneAdeguamento = @DescrizioneAdeguamento,
            ImpattoCostoStimato = ISNULL(@ImpattoCostoStimato, 0),
            ImpattoVenditaStimato = ISNULL(@ImpattoVenditaStimato, 0),
            Note = NULLIF(LTRIM(RTRIM(@Note)), N''''),
            DataModifica = SYSDATETIME(),
            UtenteModifica = @Utente
        WHERE IdAdeguamento = @IdAdeguamento
          AND VersioneRiga = @VersioneRiga;

        IF @@ROWCOUNT = 0
            THROW 52730, ''L''''adeguamento e stato modificato da un altro utente.'', 1;
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
    /* PAYLOAD TEC-015-MODIFICA END */

    DECLARE @Versione INT = 2026102902;
    DECLARE @CodiceIntervento NVARCHAR(50) = N'TEC-015-MODIFICA';
    DECLARE @NomeScript NVARCHAR(260) = N'TEC-015_02_Modifica_Eliminazione_Rilievi_Adeguamenti.sql';
    -- SHA-256 del contenuto fra i marcatori PAYLOAD inclusi, normalizzato con LF.
    DECLARE @ImprontaSha256 CHAR(64) =
        'D947F6E217A458CF27AB3E3CFB6F2468E9B0949C696EA630BCF2DA9174D705C9';

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
        THROW 52799, 'TEC-015-MODIFICA: versione gia registrata con dati o impronta differenti.', 1;

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
        N'Modifica ed eliminazione controllata di rilievi e adeguamenti campionatura.',
        @ImprontaSha256
    );

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0
        ROLLBACK TRANSACTION;
    THROW;
END CATCH;
