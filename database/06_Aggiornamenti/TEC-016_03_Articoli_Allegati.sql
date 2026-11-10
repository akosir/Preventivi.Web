/*
    TEC-016 - Articoli e relativi allegati
    Versione schema: 2026110401
    Prerequisito: versione 2026110302 (TEC-016-MATERIALI-LAVORAZIONI).

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
        THROW 53390, 'TEC-016: registro VersioniSchema non disponibile.', 1;

    IF NOT EXISTS
    (
        SELECT 1
        FROM dbo.VersioniSchema
        WHERE Versione = 2026110302
          AND CodiceIntervento = N'TEC-016-MATERIALI-LAVORAZIONI'
    )
        THROW 53391, 'TEC-016: versione richiesta 2026110302 non installata.', 1;

    IF EXISTS
    (
        SELECT 1
        FROM dbo.VersioniSchema
        WHERE Versione > 2026110302
          AND Versione <> 2026110401
    )
        THROW 53392, 'TEC-016: il database contiene una versione successiva non riconosciuta.', 1;

    IF OBJECT_ID(N'dbo.Articoli', N'U') IS NULL
       OR OBJECT_ID(N'dbo.Clienti', N'U') IS NULL
       OR OBJECT_ID(N'dbo.DistintaBaseNodi', N'U') IS NULL
       OR OBJECT_ID(N'dbo.ModelliPreventivoRighe', N'U') IS NULL
       OR OBJECT_ID(N'dbo.PreventiviRighe', N'U') IS NULL
       OR OBJECT_ID(N'dbo.PreventiviRigheComponenti', N'U') IS NULL
       OR OBJECT_ID(N'dbo.Allegati', N'U') IS NULL
        THROW 53393, 'TEC-016: tabelle richieste non disponibili.', 1;

    /* PAYLOAD TEC-016-ARTICOLI-ALLEGATI START */
    IF COL_LENGTH(N'dbo.Articoli', N'UtenteCreazione') IS NULL
        EXEC sys.sp_executesql N'ALTER TABLE dbo.Articoli ADD UtenteCreazione NVARCHAR(256) NULL;';

    EXEC sys.sp_executesql N'
        UPDATE dbo.Articoli
        SET UtenteCreazione = N''MIGRAZIONE-TEC-016''
        WHERE UtenteCreazione IS NULL;
        ALTER TABLE dbo.Articoli ALTER COLUMN UtenteCreazione NVARCHAR(256) NOT NULL;';

    IF COL_LENGTH(N'dbo.Articoli', N'UtenteModifica') IS NULL
        EXEC sys.sp_executesql N'ALTER TABLE dbo.Articoli ADD UtenteModifica NVARCHAR(256) NULL;';

    IF COL_LENGTH(N'dbo.Articoli', N'VersioneRiga') IS NULL
        EXEC sys.sp_executesql N'ALTER TABLE dbo.Articoli ADD VersioneRiga ROWVERSION NOT NULL;';

    EXEC sys.sp_executesql N'
    CREATE OR ALTER PROCEDURE dbo.Anagrafiche_Clienti_Lookup
        @IdCorrente INT = NULL
    AS
    BEGIN
        SET NOCOUNT ON;
        SELECT IdCliente, CodiceCliente, RagioneSociale, Attivo
        FROM dbo.Clienti
        WHERE Attivo = 1 OR IdCliente = @IdCorrente
        ORDER BY RagioneSociale, CodiceCliente;
    END;';

    EXEC sys.sp_executesql N'
    CREATE OR ALTER PROCEDURE dbo.Anagrafiche_Articoli_Elenco
        @Ricerca NVARCHAR(200) = NULL,
        @SoloAttivi BIT = NULL,
        @IdCliente INT = NULL
    AS
    BEGIN
        SET NOCOUNT ON;
        DECLARE @Filtro NVARCHAR(200) = NULLIF(LTRIM(RTRIM(@Ricerca)), N'''');

        SELECT articolo.IdArticolo,
               articolo.CodiceArticolo,
               articolo.Descrizione,
               articolo.Versione,
               CASE WHEN cliente.IdCliente IS NULL THEN NULL
                    ELSE cliente.CodiceCliente + N'' - '' + cliente.RagioneSociale END AS Cliente,
               articolo.Attivo
        FROM dbo.Articoli AS articolo
        LEFT JOIN dbo.Clienti AS cliente ON cliente.IdCliente = articolo.IdCliente
        WHERE (@SoloAttivi IS NULL OR articolo.Attivo = @SoloAttivi)
          AND (@IdCliente IS NULL OR articolo.IdCliente = @IdCliente)
          AND
          (
              @Filtro IS NULL
              OR articolo.CodiceArticolo LIKE N''%'' + @Filtro + N''%''
              OR articolo.Descrizione LIKE N''%'' + @Filtro + N''%''
              OR articolo.Versione LIKE N''%'' + @Filtro + N''%''
          )
        ORDER BY articolo.CodiceArticolo;
    END;';

    EXEC sys.sp_executesql N'
    CREATE OR ALTER PROCEDURE dbo.Anagrafiche_Articoli_Dettaglio
        @IdArticolo INT
    AS
    BEGIN
        SET NOCOUNT ON;
        SELECT articolo.IdArticolo,
               articolo.CodiceArticolo,
               articolo.Descrizione,
               articolo.Versione,
               articolo.IdCliente,
               CASE WHEN cliente.IdCliente IS NULL THEN NULL
                    ELSE cliente.CodiceCliente + N'' - '' + cliente.RagioneSociale END AS Cliente,
               articolo.Attivo,
               articolo.NoteTecniche,
               articolo.DataCreazione,
               articolo.DataModifica,
               articolo.UtenteCreazione,
               articolo.UtenteModifica,
               articolo.VersioneRiga
        FROM dbo.Articoli AS articolo
        LEFT JOIN dbo.Clienti AS cliente ON cliente.IdCliente = articolo.IdCliente
        WHERE articolo.IdArticolo = @IdArticolo;
    END;';

    EXEC sys.sp_executesql N'
    CREATE OR ALTER PROCEDURE dbo.Anagrafiche_Articoli_Crea
        @CodiceArticolo NVARCHAR(50),
        @Descrizione NVARCHAR(200),
        @Versione NVARCHAR(20) = NULL,
        @IdCliente INT = NULL,
        @NoteTecniche NVARCHAR(MAX) = NULL,
        @Utente NVARCHAR(256)
    AS
    BEGIN
        SET NOCOUNT ON;
        SET XACT_ABORT ON;
        SET @CodiceArticolo = NULLIF(LTRIM(RTRIM(@CodiceArticolo)), N'''');
        SET @Descrizione = NULLIF(LTRIM(RTRIM(@Descrizione)), N'''');
        SET @Versione = NULLIF(LTRIM(RTRIM(@Versione)), N'''');
        SET @NoteTecniche = NULLIF(LTRIM(RTRIM(@NoteTecniche)), N'''');
        SET @Utente = NULLIF(LTRIM(RTRIM(@Utente)), N'''');

        IF @CodiceArticolo IS NULL OR @Descrizione IS NULL OR @Utente IS NULL
            THROW 53301, ''Dati articolo non validi.'', 1;

        BEGIN TRANSACTION;
        IF @IdCliente IS NOT NULL
           AND NOT EXISTS
           (
               SELECT 1 FROM dbo.Clienti WITH (UPDLOCK, HOLDLOCK)
               WHERE IdCliente = @IdCliente AND Attivo = 1
           )
            THROW 53303, ''Cliente non valido o non attivo.'', 1;
        IF EXISTS
        (
            SELECT 1 FROM dbo.Articoli WITH (UPDLOCK, HOLDLOCK)
            WHERE CodiceArticolo = @CodiceArticolo
        )
            THROW 53302, ''Codice articolo gia utilizzato.'', 1;

        INSERT INTO dbo.Articoli
        (
            CodiceArticolo, Descrizione, Versione, IdCliente, Attivo,
            NoteTecniche, DataCreazione, DataModifica,
            UtenteCreazione, UtenteModifica
        )
        VALUES
        (
            @CodiceArticolo, @Descrizione, @Versione, @IdCliente, 1,
            @NoteTecniche, SYSDATETIME(), NULL, @Utente, NULL
        );
        DECLARE @IdArticolo INT = CONVERT(INT, SCOPE_IDENTITY());
        COMMIT TRANSACTION;
        SELECT @IdArticolo;
    END;';

    EXEC sys.sp_executesql N'
    CREATE OR ALTER PROCEDURE dbo.Anagrafiche_Articoli_Aggiorna
        @IdArticolo INT,
        @CodiceArticolo NVARCHAR(50),
        @Descrizione NVARCHAR(200),
        @Versione NVARCHAR(20) = NULL,
        @IdCliente INT = NULL,
        @NoteTecniche NVARCHAR(MAX) = NULL,
        @Utente NVARCHAR(256),
        @VersioneRiga BINARY(8)
    AS
    BEGIN
        SET NOCOUNT ON;
        SET XACT_ABORT ON;
        SET @CodiceArticolo = NULLIF(LTRIM(RTRIM(@CodiceArticolo)), N'''');
        SET @Descrizione = NULLIF(LTRIM(RTRIM(@Descrizione)), N'''');
        SET @Versione = NULLIF(LTRIM(RTRIM(@Versione)), N'''');
        SET @NoteTecniche = NULLIF(LTRIM(RTRIM(@NoteTecniche)), N'''');
        SET @Utente = NULLIF(LTRIM(RTRIM(@Utente)), N'''');

        IF @CodiceArticolo IS NULL OR @Descrizione IS NULL OR @Utente IS NULL
            THROW 53301, ''Dati articolo non validi.'', 1;

        BEGIN TRANSACTION;
        DECLARE @IdClienteCorrente INT;
        DECLARE @Esiste BIT = 0;
        SELECT @IdClienteCorrente = IdCliente, @Esiste = 1
        FROM dbo.Articoli WITH (UPDLOCK, HOLDLOCK)
        WHERE IdArticolo = @IdArticolo;
        IF @Esiste = 0
            THROW 53304, ''Articolo non trovato.'', 1;
        IF @IdCliente IS NOT NULL
           AND NOT EXISTS
           (
               SELECT 1 FROM dbo.Clienti WITH (UPDLOCK, HOLDLOCK)
               WHERE IdCliente = @IdCliente
                 AND (Attivo = 1 OR IdCliente = @IdClienteCorrente)
           )
            THROW 53303, ''Cliente non valido o non attivo.'', 1;
        IF EXISTS
        (
            SELECT 1 FROM dbo.Articoli WITH (UPDLOCK, HOLDLOCK)
            WHERE CodiceArticolo = @CodiceArticolo AND IdArticolo <> @IdArticolo
        )
            THROW 53302, ''Codice articolo gia utilizzato.'', 1;

        UPDATE dbo.Articoli
        SET CodiceArticolo = @CodiceArticolo,
            Descrizione = @Descrizione,
            Versione = @Versione,
            IdCliente = @IdCliente,
            NoteTecniche = @NoteTecniche,
            DataModifica = SYSDATETIME(),
            UtenteModifica = @Utente
        WHERE IdArticolo = @IdArticolo
          AND VersioneRiga = @VersioneRiga;
        IF @@ROWCOUNT = 0
            THROW 53305, ''Articolo modificato da un altro utente.'', 1;
        COMMIT TRANSACTION;
    END;';

    EXEC sys.sp_executesql N'
    CREATE OR ALTER PROCEDURE dbo.Anagrafiche_Articoli_ImpostaStato
        @IdArticolo INT,
        @Attivo BIT,
        @Utente NVARCHAR(256),
        @VersioneRiga BINARY(8)
    AS
    BEGIN
        SET NOCOUNT ON;
        SET @Utente = NULLIF(LTRIM(RTRIM(@Utente)), N'''');
        IF @Attivo IS NULL OR @Utente IS NULL
            THROW 53301, ''Dati stato non validi.'', 1;
        UPDATE dbo.Articoli
        SET Attivo = @Attivo,
            DataModifica = SYSDATETIME(),
            UtenteModifica = @Utente
        WHERE IdArticolo = @IdArticolo
          AND VersioneRiga = @VersioneRiga;
        IF @@ROWCOUNT = 0
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM dbo.Articoli WHERE IdArticolo = @IdArticolo)
                THROW 53304, ''Articolo non trovato.'', 1;
            THROW 53305, ''Articolo modificato da un altro utente.'', 1;
        END;
    END;';

    EXEC sys.sp_executesql N'
    CREATE OR ALTER PROCEDURE dbo.Anagrafiche_Articoli_Elimina
        @IdArticolo INT,
        @VersioneRiga BINARY(8)
    AS
    BEGIN
        SET NOCOUNT ON;
        SET XACT_ABORT ON;
        BEGIN TRANSACTION;
        IF NOT EXISTS
        (
            SELECT 1 FROM dbo.Articoli WITH (UPDLOCK, HOLDLOCK)
            WHERE IdArticolo = @IdArticolo
        )
            THROW 53304, ''Articolo non trovato.'', 1;
        IF NOT EXISTS
        (
            SELECT 1 FROM dbo.Articoli
            WHERE IdArticolo = @IdArticolo AND VersioneRiga = @VersioneRiga
        )
            THROW 53305, ''Articolo modificato da un altro utente.'', 1;
        IF EXISTS (SELECT 1 FROM dbo.DistintaBaseNodi WITH (UPDLOCK, HOLDLOCK) WHERE IdArticolo = @IdArticolo)
           OR EXISTS (SELECT 1 FROM dbo.ModelliPreventivoRighe WITH (UPDLOCK, HOLDLOCK) WHERE IdArticolo = @IdArticolo)
           OR EXISTS (SELECT 1 FROM dbo.PreventiviRighe WITH (UPDLOCK, HOLDLOCK) WHERE IdArticolo = @IdArticolo)
           OR EXISTS (SELECT 1 FROM dbo.PreventiviRigheComponenti WITH (UPDLOCK, HOLDLOCK) WHERE IdArticoloOrigine = @IdArticolo)
           OR EXISTS
              (
                  SELECT 1 FROM dbo.Allegati WITH (UPDLOCK, HOLDLOCK)
                  WHERE Entita = N''Articoli'' AND IdEntita = @IdArticolo
              )
            THROW 53306, ''Articolo utilizzato o con allegati.'', 1;
        DELETE FROM dbo.Articoli
        WHERE IdArticolo = @IdArticolo AND VersioneRiga = @VersioneRiga;
        COMMIT TRANSACTION;
    END;';
    /* PAYLOAD TEC-016-ARTICOLI-ALLEGATI END */

    DECLARE @Versione INT = 2026110401;
    DECLARE @CodiceIntervento NVARCHAR(50) = N'TEC-016-ARTICOLI-ALLEGATI';
    DECLARE @NomeScript NVARCHAR(260) = N'TEC-016_03_Articoli_Allegati.sql';
    -- SHA-256 del contenuto fra i marcatori PAYLOAD inclusi, normalizzato con LF.
    DECLARE @ImprontaSha256 CHAR(64) = '267585C6E94793F8412977720320115A850097CF74B2D55B05259C736D2F20C0';

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
        THROW 53399, 'TEC-016-ARTICOLI-ALLEGATI: versione gia registrata con dati o impronta differenti.', 1;

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
        N'Gestione anagrafica articoli e integrazione allegati MB-01.',
        @ImprontaSha256
    );

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0
        ROLLBACK TRANSACTION;
    THROW;
END CATCH;
