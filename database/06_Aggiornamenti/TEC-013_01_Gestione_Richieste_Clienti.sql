/*
    TEC-013 - Gestione Richieste Clienti
    Versione schema: 2026102602
    Prerequisito: versione 2026102601 (TEC-012-BASELINE).

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
        THROW 52590, 'TEC-013: registro VersioniSchema non disponibile.', 1;

    IF NOT EXISTS
    (
        SELECT 1
        FROM dbo.VersioniSchema
        WHERE Versione = 2026102601
          AND CodiceIntervento = N'TEC-012-BASELINE'
    )
        THROW 52591, 'TEC-013: versione richiesta 2026102601 non installata.', 1;

    IF EXISTS
    (
        SELECT 1
        FROM dbo.VersioniSchema
        WHERE Versione > 2026102601
          AND Versione <> 2026102602
    )
        THROW 52592, 'TEC-013: il database contiene una versione successiva non riconosciuta.', 1;

    IF OBJECT_ID(N'dbo.RichiesteClienti', N'U') IS NULL
       OR OBJECT_ID(N'dbo.Clienti', N'U') IS NULL
       OR OBJECT_ID(N'dbo.Preventivi', N'U') IS NULL
       OR OBJECT_ID(N'dbo.Campionature', N'U') IS NULL
        THROW 52593, 'TEC-013: tabelle richieste non disponibili.', 1;

    /* PAYLOAD TEC-013 START */
    IF COL_LENGTH(N'dbo.RichiesteClienti', N'UtenteCreazione') IS NULL
        EXEC sys.sp_executesql N'
        ALTER TABLE dbo.RichiesteClienti
            ADD UtenteCreazione NVARCHAR(256) NULL;';

    EXEC sys.sp_executesql N'
        UPDATE dbo.RichiesteClienti
        SET UtenteCreazione = N''MIGRAZIONE-TEC-013''
        WHERE UtenteCreazione IS NULL;';

    IF EXISTS
    (
        SELECT 1
        FROM sys.columns
        WHERE object_id = OBJECT_ID(N'dbo.RichiesteClienti')
          AND name = N'UtenteCreazione'
          AND is_nullable = 1
    )
        EXEC sys.sp_executesql N'
        ALTER TABLE dbo.RichiesteClienti
            ALTER COLUMN UtenteCreazione NVARCHAR(256) NOT NULL;';

    IF NOT EXISTS
    (
        SELECT 1
        FROM sys.default_constraints AS vincolo
        INNER JOIN sys.columns AS colonna
            ON colonna.object_id = vincolo.parent_object_id
           AND colonna.column_id = vincolo.parent_column_id
        WHERE vincolo.parent_object_id = OBJECT_ID(N'dbo.RichiesteClienti')
          AND colonna.name = N'UtenteCreazione'
    )
        EXEC sys.sp_executesql N'
        ALTER TABLE dbo.RichiesteClienti
            ADD CONSTRAINT DF_RichiesteClienti_UtenteCreazione
            DEFAULT ORIGINAL_LOGIN() FOR UtenteCreazione;';

    IF COL_LENGTH(N'dbo.RichiesteClienti', N'UtenteModifica') IS NULL
        ALTER TABLE dbo.RichiesteClienti
            ADD UtenteModifica NVARCHAR(256) NULL;

    IF COL_LENGTH(N'dbo.RichiesteClienti', N'VersioneRiga') IS NULL
        ALTER TABLE dbo.RichiesteClienti
            ADD VersioneRiga ROWVERSION NOT NULL;

    IF EXISTS
    (
        SELECT 1
        FROM dbo.RichiesteClienti
        WHERE ProbabilitaChiusura IS NOT NULL
          AND ProbabilitaChiusura NOT BETWEEN 0 AND 100
    )
        THROW 52594, 'TEC-013: esistono probabilita di chiusura fuori intervallo 0-100.', 1;

    IF OBJECT_ID(N'dbo.CK_RichiesteClienti_ProbabilitaChiusura', N'C') IS NULL
    BEGIN
        ALTER TABLE dbo.RichiesteClienti WITH CHECK
            ADD CONSTRAINT CK_RichiesteClienti_ProbabilitaChiusura
            CHECK (ProbabilitaChiusura IS NULL OR ProbabilitaChiusura BETWEEN 0 AND 100);
        ALTER TABLE dbo.RichiesteClienti
            CHECK CONSTRAINT CK_RichiesteClienti_ProbabilitaChiusura;
    END;

    EXEC sys.sp_executesql N'
    CREATE OR ALTER PROCEDURE dbo.RichiesteClienti_Elenco
        @Ricerca NVARCHAR(300) = NULL,
        @IdCliente INT = NULL,
        @Stato NVARCHAR(30) = NULL,
        @Priorita NVARCHAR(20) = NULL,
        @InteresseCliente NVARCHAR(20) = NULL,
        @ScadenzaDa DATE = NULL,
        @ScadenzaA DATE = NULL
    AS
    BEGIN
        SET NOCOUNT ON;

        SET @Ricerca = NULLIF(LTRIM(RTRIM(@Ricerca)), N'''' );

        SELECT
            richiesta.IdRichiestaCliente,
            richiesta.NumeroRichiesta,
            richiesta.Anno,
            richiesta.DataRichiesta,
            richiesta.IdCliente,
            ISNULL(cliente.RagioneSociale, N'''') AS Cliente,
            richiesta.Oggetto,
            richiesta.Stato,
            richiesta.Priorita,
            richiesta.InteresseCliente,
            richiesta.DataScadenza,
            richiesta.ProbabilitaChiusura,
            (SELECT COUNT(*) FROM dbo.Preventivi AS p WHERE p.IdRichiestaCliente = richiesta.IdRichiestaCliente) AS NumeroPreventivi,
            (SELECT COUNT(*) FROM dbo.Campionature AS c WHERE c.IdRichiestaCliente = richiesta.IdRichiestaCliente) AS NumeroCampionature
        FROM dbo.RichiesteClienti AS richiesta
        LEFT JOIN dbo.Clienti AS cliente
            ON cliente.IdCliente = richiesta.IdCliente
        WHERE (@IdCliente IS NULL OR richiesta.IdCliente = @IdCliente)
          AND (@Stato IS NULL OR richiesta.Stato = @Stato)
          AND (@Priorita IS NULL OR richiesta.Priorita = @Priorita)
          AND (@InteresseCliente IS NULL OR richiesta.InteresseCliente = @InteresseCliente)
          AND (@ScadenzaDa IS NULL OR richiesta.DataScadenza >= @ScadenzaDa)
          AND (@ScadenzaA IS NULL OR richiesta.DataScadenza <= @ScadenzaA)
          AND
          (
              @Ricerca IS NULL
              OR cliente.CodiceCliente LIKE N''%'' + @Ricerca + N''%''
              OR cliente.RagioneSociale LIKE N''%'' + @Ricerca + N''%''
              OR richiesta.Oggetto LIKE N''%'' + @Ricerca + N''%''
              OR richiesta.DescrizioneRichiesta LIKE N''%'' + @Ricerca + N''%''
              OR CONCAT(richiesta.Anno, N''-'', RIGHT(N''00000'' + CONVERT(NVARCHAR(10), richiesta.NumeroRichiesta), 5)) LIKE N''%'' + @Ricerca + N''%''
          )
        ORDER BY richiesta.DataRichiesta DESC, richiesta.Anno DESC, richiesta.NumeroRichiesta DESC;
    END;';

    EXEC sys.sp_executesql N'
    CREATE OR ALTER PROCEDURE dbo.RichiesteClienti_Dettaglio
        @IdRichiestaCliente INT
    AS
    BEGIN
        SET NOCOUNT ON;

        SELECT
            richiesta.IdRichiestaCliente,
            richiesta.NumeroRichiesta,
            richiesta.Anno,
            richiesta.DataRichiesta,
            richiesta.IdCliente,
            ISNULL(cliente.CodiceCliente, N'''') AS CodiceCliente,
            ISNULL(cliente.RagioneSociale, N'''') AS Cliente,
            CONVERT(BIT, ISNULL(cliente.Attivo, 0)) AS ClienteAttivo,
            richiesta.Oggetto,
            richiesta.DescrizioneRichiesta,
            richiesta.Stato,
            richiesta.Priorita,
            richiesta.InteresseCliente,
            richiesta.DataScadenza,
            richiesta.DataAttivazione,
            richiesta.DataChiusura,
            richiesta.ProbabilitaChiusura,
            richiesta.Note,
            richiesta.DataCreazione,
            richiesta.DataModifica,
            richiesta.UtenteCreazione,
            richiesta.UtenteModifica,
            richiesta.VersioneRiga,
            (SELECT COUNT(*) FROM dbo.Preventivi AS p WHERE p.IdRichiestaCliente = richiesta.IdRichiestaCliente) AS NumeroPreventivi,
            (SELECT COUNT(*) FROM dbo.Campionature AS c WHERE c.IdRichiestaCliente = richiesta.IdRichiestaCliente) AS NumeroCampionature
        FROM dbo.RichiesteClienti AS richiesta
        LEFT JOIN dbo.Clienti AS cliente
            ON cliente.IdCliente = richiesta.IdCliente
        WHERE richiesta.IdRichiestaCliente = @IdRichiestaCliente;
    END;';

    EXEC sys.sp_executesql N'
    CREATE OR ALTER PROCEDURE dbo.RichiesteClienti_Crea
        @DataRichiesta DATE,
        @IdCliente INT,
        @Oggetto NVARCHAR(250),
        @DescrizioneRichiesta NVARCHAR(MAX) = NULL,
        @Stato NVARCHAR(30),
        @Priorita NVARCHAR(20),
        @InteresseCliente NVARCHAR(20) = NULL,
        @DataScadenza DATE = NULL,
        @ProbabilitaChiusura INT = NULL,
        @Note NVARCHAR(MAX) = NULL,
        @Utente NVARCHAR(256)
    AS
    BEGIN
        SET NOCOUNT ON;
        SET XACT_ABORT ON;

        SET @Oggetto = NULLIF(LTRIM(RTRIM(@Oggetto)), N'''' );
        SET @Utente = NULLIF(LTRIM(RTRIM(@Utente)), N'''' );

        IF @DataRichiesta IS NULL OR @Oggetto IS NULL OR @Utente IS NULL
            THROW 52500, ''Data, oggetto e utente sono obbligatori.'', 1;
        IF NOT EXISTS (SELECT 1 FROM dbo.Clienti WHERE IdCliente = @IdCliente AND Attivo = 1)
            THROW 52502, ''Cliente non trovato o non attivo.'', 1;
        IF @Stato NOT IN (N''Nuova'', N''In Valutazione'', N''Da Preventivare'', N''Preventivata'', N''Confermata'', N''Sospesa'', N''Persa'', N''Annullata'')
            THROW 52503, ''Stato richiesta non valido.'', 1;
        IF @Priorita NOT IN (N''Bassa'', N''Media'', N''Alta'', N''Urgente'')
            THROW 52503, ''Priorita richiesta non valida.'', 1;
        IF @InteresseCliente IS NOT NULL AND @InteresseCliente NOT IN (N''Basso'', N''Medio'', N''Alto'', N''Strategico'')
            THROW 52503, ''Interesse cliente non valido.'', 1;
        IF @ProbabilitaChiusura IS NOT NULL AND @ProbabilitaChiusura NOT BETWEEN 0 AND 100
            THROW 52503, ''Probabilita di chiusura non valida.'', 1;

        DECLARE @Anno INT = YEAR(@DataRichiesta);
        DECLARE @NumeroRichiesta INT;
        DECLARE @IdRichiestaCliente INT;
        DECLARE @EsitoLock INT;
        DECLARE @RisorsaLock NVARCHAR(255) = CONCAT(N''RichiesteClienti_Numero_'', @Anno);

        BEGIN TRY
            BEGIN TRANSACTION;

            IF NOT EXISTS
            (
                SELECT 1
                FROM dbo.Clienti WITH (UPDLOCK, HOLDLOCK)
                WHERE IdCliente = @IdCliente
                  AND Attivo = 1
            )
                THROW 52502, ''Cliente non trovato o non attivo.'', 1;

            EXEC @EsitoLock = sys.sp_getapplock
                @Resource = @RisorsaLock,
                @LockMode = N''Exclusive'',
                @LockOwner = N''Transaction'',
                @LockTimeout = 10000;
            IF @EsitoLock < 0
                THROW 52504, ''Impossibile assegnare il numero progressivo.'', 1;

            SELECT @NumeroRichiesta = ISNULL(MAX(NumeroRichiesta), 0) + 1
            FROM dbo.RichiesteClienti WITH (UPDLOCK, HOLDLOCK)
            WHERE Anno = @Anno;

            INSERT INTO dbo.RichiesteClienti
            (
                NumeroRichiesta, Anno, DataRichiesta, IdCliente, Oggetto,
                DescrizioneRichiesta, Stato, Priorita, InteresseCliente,
                DataScadenza, DataAttivazione, DataChiusura,
                ProbabilitaChiusura, Note, DataCreazione, UtenteCreazione
            )
            VALUES
            (
                @NumeroRichiesta, @Anno, @DataRichiesta, @IdCliente, @Oggetto,
                @DescrizioneRichiesta, @Stato, @Priorita, @InteresseCliente,
                @DataScadenza,
                CASE WHEN @Stato <> N''Nuova'' THEN @DataRichiesta END,
                CASE WHEN @Stato IN (N''Confermata'', N''Persa'', N''Annullata'') THEN @DataRichiesta END,
                @ProbabilitaChiusura, @Note, SYSDATETIME(), @Utente
            );

            SET @IdRichiestaCliente = CONVERT(INT, SCOPE_IDENTITY());
            COMMIT TRANSACTION;
            SELECT @IdRichiestaCliente;
        END TRY
        BEGIN CATCH
            IF XACT_STATE() <> 0
                ROLLBACK TRANSACTION;
            THROW;
        END CATCH;
    END;';

    EXEC sys.sp_executesql N'
    CREATE OR ALTER PROCEDURE dbo.RichiesteClienti_Aggiorna
        @IdRichiestaCliente INT,
        @DataRichiesta DATE,
        @IdCliente INT,
        @Oggetto NVARCHAR(250),
        @DescrizioneRichiesta NVARCHAR(MAX) = NULL,
        @Stato NVARCHAR(30),
        @Priorita NVARCHAR(20),
        @InteresseCliente NVARCHAR(20) = NULL,
        @DataScadenza DATE = NULL,
        @ProbabilitaChiusura INT = NULL,
        @Note NVARCHAR(MAX) = NULL,
        @Utente NVARCHAR(256),
        @VersioneRiga BINARY(8)
    AS
    BEGIN
        SET NOCOUNT ON;
        SET XACT_ABORT ON;

        DECLARE @StatoCorrente NVARCHAR(30);
        DECLARE @IdClienteCorrente INT;
        DECLARE @DataAttivazione DATE;
        DECLARE @AnnoCorrente INT;

        BEGIN TRY
            BEGIN TRANSACTION;

            SELECT
                @StatoCorrente = Stato,
                @IdClienteCorrente = IdCliente,
                @DataAttivazione = DataAttivazione,
                @AnnoCorrente = Anno
            FROM dbo.RichiesteClienti WITH (UPDLOCK, HOLDLOCK)
            WHERE IdRichiestaCliente = @IdRichiestaCliente;

        IF @StatoCorrente IS NULL
            THROW 52505, ''Richiesta cliente non trovata.'', 1;
        IF @DataRichiesta IS NULL OR NULLIF(LTRIM(RTRIM(@Oggetto)), N'''') IS NULL
            THROW 52500, ''Data e oggetto sono obbligatori.'', 1;
        IF YEAR(@DataRichiesta) <> @AnnoCorrente
            THROW 52510, ''La data richiesta non puo cambiare l anno del numero progressivo.'', 1;
        IF @Stato NOT IN (N''Nuova'', N''In Valutazione'', N''Da Preventivare'', N''Preventivata'', N''Confermata'', N''Sospesa'', N''Persa'', N''Annullata'')
            THROW 52503, ''Stato richiesta non valido.'', 1;
        IF @Priorita NOT IN (N''Bassa'', N''Media'', N''Alta'', N''Urgente'')
            THROW 52503, ''Priorita richiesta non valida.'', 1;
        IF @InteresseCliente IS NOT NULL AND @InteresseCliente NOT IN (N''Basso'', N''Medio'', N''Alto'', N''Strategico'')
            THROW 52503, ''Interesse cliente non valido.'', 1;
        IF @ProbabilitaChiusura IS NOT NULL AND @ProbabilitaChiusura NOT BETWEEN 0 AND 100
            THROW 52503, ''Probabilita di chiusura non valida.'', 1;
        IF @IdCliente <> ISNULL(@IdClienteCorrente, -1)
           AND EXISTS
           (
               SELECT 1 FROM dbo.Preventivi WITH (UPDLOCK, HOLDLOCK) WHERE IdRichiestaCliente = @IdRichiestaCliente
               UNION ALL
               SELECT 1 FROM dbo.Campionature WITH (UPDLOCK, HOLDLOCK) WHERE IdRichiestaCliente = @IdRichiestaCliente
           )
            THROW 52507, ''Cliente non modificabile in presenza di documenti collegati.'', 1;
        IF @IdCliente <> ISNULL(@IdClienteCorrente, -1)
           AND NOT EXISTS
           (
               SELECT 1 FROM dbo.Clienti WITH (UPDLOCK, HOLDLOCK)
               WHERE IdCliente = @IdCliente AND Attivo = 1
           )
            THROW 52502, ''Cliente non trovato o non attivo.'', 1;
        IF @StatoCorrente IN (N''Confermata'', N''Persa'', N''Annullata'')
           AND @Stato <> @StatoCorrente
            THROW 52508, ''Uno stato finale non puo essere riaperto.'', 1;

        UPDATE dbo.RichiesteClienti
        SET DataRichiesta = @DataRichiesta,
            IdCliente = @IdCliente,
            Oggetto = LTRIM(RTRIM(@Oggetto)),
            DescrizioneRichiesta = NULLIF(LTRIM(RTRIM(@DescrizioneRichiesta)), N''''),
            Stato = @Stato,
            Priorita = @Priorita,
            InteresseCliente = @InteresseCliente,
            DataScadenza = @DataScadenza,
            DataAttivazione = CASE
                WHEN @DataAttivazione IS NOT NULL THEN @DataAttivazione
                WHEN @Stato <> N''Nuova'' THEN CAST(GETDATE() AS DATE)
            END,
            DataChiusura = CASE
                WHEN @Stato IN (N''Confermata'', N''Persa'', N''Annullata'')
                    THEN ISNULL(DataChiusura, CAST(GETDATE() AS DATE))
                ELSE NULL
            END,
            ProbabilitaChiusura = @ProbabilitaChiusura,
            Note = NULLIF(LTRIM(RTRIM(@Note)), N''''),
            DataModifica = SYSDATETIME(),
            UtenteModifica = NULLIF(LTRIM(RTRIM(@Utente)), N'''')
        WHERE IdRichiestaCliente = @IdRichiestaCliente
          AND VersioneRiga = @VersioneRiga;

        IF @@ROWCOUNT = 0
            THROW 52506, ''La richiesta e stata modificata da un altro utente.'', 1;

            COMMIT TRANSACTION;
        END TRY
        BEGIN CATCH
            IF XACT_STATE() <> 0
                ROLLBACK TRANSACTION;
            THROW;
        END CATCH;
    END;';

    EXEC sys.sp_executesql N'
    CREATE OR ALTER PROCEDURE dbo.RichiesteClienti_Annulla
        @IdRichiestaCliente INT,
        @VersioneRiga BINARY(8),
        @Utente NVARCHAR(256)
    AS
    BEGIN
        SET NOCOUNT ON;

        IF EXISTS
        (
            SELECT 1 FROM dbo.RichiesteClienti
            WHERE IdRichiestaCliente = @IdRichiestaCliente
              AND Stato IN (N''Confermata'', N''Persa'', N''Annullata'')
        )
            THROW 52509, ''La richiesta e gia in uno stato finale.'', 1;

        UPDATE dbo.RichiesteClienti
        SET Stato = N''Annullata'',
            DataAttivazione = ISNULL(DataAttivazione, CAST(GETDATE() AS DATE)),
            DataChiusura = CAST(GETDATE() AS DATE),
            DataModifica = SYSDATETIME(),
            UtenteModifica = NULLIF(LTRIM(RTRIM(@Utente)), N'''')
        WHERE IdRichiestaCliente = @IdRichiestaCliente
          AND VersioneRiga = @VersioneRiga;

        IF @@ROWCOUNT = 0
            THROW 52506, ''La richiesta e stata modificata da un altro utente.'', 1;
    END;';

    EXEC sys.sp_executesql N'
    CREATE OR ALTER PROCEDURE dbo.RichiesteClienti_Preventivi_Elenco
        @IdRichiestaCliente INT
    AS
    BEGIN
        SET NOCOUNT ON;
        SELECT IdPreventivo, NumeroPreventivo, Anno, DataPreventivo, Stato, TotaleVendita
        FROM dbo.Preventivi
        WHERE IdRichiestaCliente = @IdRichiestaCliente
        ORDER BY DataPreventivo DESC, NumeroPreventivo DESC;
    END;';

    EXEC sys.sp_executesql N'
    CREATE OR ALTER PROCEDURE dbo.RichiesteClienti_Campionature_Elenco
        @IdRichiestaCliente INT
    AS
    BEGIN
        SET NOCOUNT ON;
        SELECT IdCampionatura, NumeroCampionatura, Anno, DataCampionatura, Stato, Priorita
        FROM dbo.Campionature
        WHERE IdRichiestaCliente = @IdRichiestaCliente
        ORDER BY DataCampionatura DESC, NumeroCampionatura DESC;
    END;';

    EXEC sys.sp_executesql N'
    CREATE OR ALTER PROCEDURE dbo.Preventivi_Creazione_Richieste_Elenco
    AS
    BEGIN
        SET NOCOUNT ON;
        SELECT
            richiesta.IdRichiestaCliente,
            richiesta.NumeroRichiesta,
            richiesta.Anno,
            richiesta.IdCliente,
            ISNULL(cliente.RagioneSociale, N'''') AS Cliente,
            CONVERT(BIT, ISNULL(cliente.Attivo, 0)) AS ClienteAttivo,
            richiesta.Oggetto,
            richiesta.Stato
        FROM dbo.RichiesteClienti AS richiesta
        LEFT JOIN dbo.Clienti AS cliente ON cliente.IdCliente = richiesta.IdCliente
        WHERE richiesta.Stato IN (N''Nuova'', N''In Valutazione'', N''Da Preventivare'', N''Preventivata'')
        ORDER BY richiesta.Anno DESC, richiesta.NumeroRichiesta DESC;
    END;';

    EXEC sys.sp_executesql N'
    CREATE OR ALTER PROCEDURE dbo.RichiesteClienti_Preventivo_Crea
        @Origine NVARCHAR(20),
        @DataPreventivo DATE,
        @IdCliente INT = NULL,
        @IdRichiestaCliente INT = NULL,
        @IdModelloPreventivo INT = NULL,
        @Oggetto NVARCHAR(250),
        @Note NVARCHAR(MAX) = NULL,
        @MarkupPercDefault DECIMAL(9,2),
        @Utente NVARCHAR(256)
    AS
    BEGIN
        SET NOCOUNT ON;
        SET XACT_ABORT ON;

        IF @Origine <> N''Richiesta'' OR @IdRichiestaCliente IS NULL
            THROW 51811, ''La richiesta cliente non e valida per la creazione del preventivo.'', 1;

        IF NULLIF(LTRIM(RTRIM(@Utente)), N'''') IS NULL
            THROW 51811, ''Utente non disponibile per la creazione del preventivo.'', 1;

        DECLARE @Esito TABLE (IdPreventivo INT NOT NULL);
        DECLARE @StatoRichiesta NVARCHAR(30);

        BEGIN TRY
            BEGIN TRANSACTION;

            SELECT @StatoRichiesta = Stato
            FROM dbo.RichiesteClienti WITH (UPDLOCK, HOLDLOCK)
            WHERE IdRichiestaCliente = @IdRichiestaCliente;

            IF @StatoRichiesta IS NULL
               OR @StatoRichiesta NOT IN (N''Nuova'', N''In Valutazione'', N''Da Preventivare'', N''Preventivata'')
                THROW 51811, ''Lo stato della richiesta non consente la creazione del preventivo.'', 1;

            INSERT INTO @Esito (IdPreventivo)
            EXEC dbo.Preventivi_Crea
                @Origine = @Origine,
                @DataPreventivo = @DataPreventivo,
                @IdCliente = @IdCliente,
                @IdRichiestaCliente = @IdRichiestaCliente,
                @IdModelloPreventivo = @IdModelloPreventivo,
                @Oggetto = @Oggetto,
                @Note = @Note,
                @MarkupPercDefault = @MarkupPercDefault;

            UPDATE dbo.RichiesteClienti
            SET DataModifica = SYSDATETIME(),
                UtenteModifica = NULLIF(LTRIM(RTRIM(@Utente)), N'''')
            WHERE IdRichiestaCliente = @IdRichiestaCliente;

            COMMIT TRANSACTION;

            SELECT IdPreventivo FROM @Esito;
        END TRY
        BEGIN CATCH
            IF XACT_STATE() <> 0
                ROLLBACK TRANSACTION;
            THROW;
        END CATCH;
    END;';
    /* PAYLOAD TEC-013 END */

    DECLARE @Versione INT = 2026102602;
    DECLARE @CodiceIntervento NVARCHAR(50) = N'TEC-013';
    DECLARE @NomeScript NVARCHAR(260) = N'TEC-013_01_Gestione_Richieste_Clienti.sql';
    -- SHA-256 del contenuto fra i marcatori PAYLOAD inclusi, normalizzato con LF.
    DECLARE @ImprontaSha256 CHAR(64) =
        '7A529A99D7749DE25D08736CD55180280A9431C8B2BAC040F1B4DB72FC71067D';

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
        THROW 52595, 'TEC-013: versione gia registrata con dati o impronta differenti.', 1;

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
        N'Gestione completa delle richieste clienti, concorrenza e audit.',
        @ImprontaSha256
    );

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0
        ROLLBACK TRANSACTION;
    THROW;
END CATCH;
