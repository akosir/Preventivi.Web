/*
    TEC-016 - Anagrafiche di base
    Versione schema: 2026110301
    Prerequisito: versione 2026110201 (TEC-015-CAMPIONATURA-WORKFLOW).

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
        THROW 53190, 'TEC-016: registro VersioniSchema non disponibile.', 1;

    IF NOT EXISTS
    (
        SELECT 1
        FROM dbo.VersioniSchema
        WHERE Versione = 2026110201
          AND CodiceIntervento = N'TEC-015-CAMPIONATURA-WORKFLOW'
    )
        THROW 53191, 'TEC-016: versione richiesta 2026110201 non installata.', 1;

    IF EXISTS
    (
        SELECT 1
        FROM dbo.VersioniSchema
        WHERE Versione > 2026110201
          AND Versione <> 2026110301
    )
        THROW 53192, 'TEC-016: il database contiene una versione successiva non riconosciuta.', 1;

    IF OBJECT_ID(N'dbo.UnitaMisura', N'U') IS NULL
       OR OBJECT_ID(N'dbo.TipiNodoDistinta', N'U') IS NULL
       OR OBJECT_ID(N'dbo.Materiali', N'U') IS NULL
       OR OBJECT_ID(N'dbo.DistintaBaseNodi', N'U') IS NULL
        THROW 53193, 'TEC-016: tabelle richieste non disponibili.', 1;

    /* PAYLOAD TEC-016-ANAGRAFICHE-BASE START */
    IF COL_LENGTH(N'dbo.UnitaMisura', N'Attivo') IS NULL
        EXEC sys.sp_executesql N'ALTER TABLE dbo.UnitaMisura ADD Attivo BIT NULL;';

    EXEC sys.sp_executesql N'
        UPDATE dbo.UnitaMisura SET Attivo = 1 WHERE Attivo IS NULL;
        ALTER TABLE dbo.UnitaMisura ALTER COLUMN Attivo BIT NOT NULL;';

    IF NOT EXISTS
    (
        SELECT 1
        FROM sys.default_constraints AS vincolo
        INNER JOIN sys.columns AS colonna
            ON colonna.object_id = vincolo.parent_object_id
           AND colonna.column_id = vincolo.parent_column_id
        WHERE vincolo.parent_object_id = OBJECT_ID(N'dbo.UnitaMisura')
          AND colonna.name = N'Attivo'
    )
        EXEC sys.sp_executesql N'
        ALTER TABLE dbo.UnitaMisura
            ADD CONSTRAINT DF_UnitaMisura_Attivo DEFAULT (1) FOR Attivo;';

    IF COL_LENGTH(N'dbo.UnitaMisura', N'DataCreazione') IS NULL
        EXEC sys.sp_executesql N'ALTER TABLE dbo.UnitaMisura ADD DataCreazione DATETIME2(0) NULL;';

    EXEC sys.sp_executesql N'
        UPDATE dbo.UnitaMisura SET DataCreazione = SYSDATETIME() WHERE DataCreazione IS NULL;
        ALTER TABLE dbo.UnitaMisura ALTER COLUMN DataCreazione DATETIME2(0) NOT NULL;';

    IF NOT EXISTS
    (
        SELECT 1
        FROM sys.default_constraints AS vincolo
        INNER JOIN sys.columns AS colonna
            ON colonna.object_id = vincolo.parent_object_id
           AND colonna.column_id = vincolo.parent_column_id
        WHERE vincolo.parent_object_id = OBJECT_ID(N'dbo.UnitaMisura')
          AND colonna.name = N'DataCreazione'
    )
        EXEC sys.sp_executesql N'
        ALTER TABLE dbo.UnitaMisura
            ADD CONSTRAINT DF_UnitaMisura_DataCreazione DEFAULT SYSDATETIME() FOR DataCreazione;';

    IF COL_LENGTH(N'dbo.UnitaMisura', N'DataModifica') IS NULL
        EXEC sys.sp_executesql N'ALTER TABLE dbo.UnitaMisura ADD DataModifica DATETIME2(0) NULL;';

    IF COL_LENGTH(N'dbo.UnitaMisura', N'UtenteCreazione') IS NULL
        EXEC sys.sp_executesql N'ALTER TABLE dbo.UnitaMisura ADD UtenteCreazione NVARCHAR(256) NULL;';

    EXEC sys.sp_executesql N'
        UPDATE dbo.UnitaMisura SET UtenteCreazione = N''MIGRAZIONE-TEC-016'' WHERE UtenteCreazione IS NULL;
        ALTER TABLE dbo.UnitaMisura ALTER COLUMN UtenteCreazione NVARCHAR(256) NOT NULL;';

    IF COL_LENGTH(N'dbo.UnitaMisura', N'UtenteModifica') IS NULL
        EXEC sys.sp_executesql N'ALTER TABLE dbo.UnitaMisura ADD UtenteModifica NVARCHAR(256) NULL;';

    IF COL_LENGTH(N'dbo.UnitaMisura', N'VersioneRiga') IS NULL
        EXEC sys.sp_executesql N'ALTER TABLE dbo.UnitaMisura ADD VersioneRiga ROWVERSION NOT NULL;';

    IF COL_LENGTH(N'dbo.TipiNodoDistinta', N'DataCreazione') IS NULL
        EXEC sys.sp_executesql N'ALTER TABLE dbo.TipiNodoDistinta ADD DataCreazione DATETIME2(0) NULL;';

    EXEC sys.sp_executesql N'
        UPDATE dbo.TipiNodoDistinta SET DataCreazione = SYSDATETIME() WHERE DataCreazione IS NULL;
        ALTER TABLE dbo.TipiNodoDistinta ALTER COLUMN DataCreazione DATETIME2(0) NOT NULL;';

    IF NOT EXISTS
    (
        SELECT 1
        FROM sys.default_constraints AS vincolo
        INNER JOIN sys.columns AS colonna
            ON colonna.object_id = vincolo.parent_object_id
           AND colonna.column_id = vincolo.parent_column_id
        WHERE vincolo.parent_object_id = OBJECT_ID(N'dbo.TipiNodoDistinta')
          AND colonna.name = N'DataCreazione'
    )
        EXEC sys.sp_executesql N'
        ALTER TABLE dbo.TipiNodoDistinta
            ADD CONSTRAINT DF_TipiNodoDistinta_DataCreazione DEFAULT SYSDATETIME() FOR DataCreazione;';

    IF COL_LENGTH(N'dbo.TipiNodoDistinta', N'DataModifica') IS NULL
        EXEC sys.sp_executesql N'ALTER TABLE dbo.TipiNodoDistinta ADD DataModifica DATETIME2(0) NULL;';

    IF COL_LENGTH(N'dbo.TipiNodoDistinta', N'UtenteCreazione') IS NULL
        EXEC sys.sp_executesql N'ALTER TABLE dbo.TipiNodoDistinta ADD UtenteCreazione NVARCHAR(256) NULL;';

    EXEC sys.sp_executesql N'
        UPDATE dbo.TipiNodoDistinta SET UtenteCreazione = N''MIGRAZIONE-TEC-016'' WHERE UtenteCreazione IS NULL;
        ALTER TABLE dbo.TipiNodoDistinta ALTER COLUMN UtenteCreazione NVARCHAR(256) NOT NULL;';

    IF COL_LENGTH(N'dbo.TipiNodoDistinta', N'UtenteModifica') IS NULL
        EXEC sys.sp_executesql N'ALTER TABLE dbo.TipiNodoDistinta ADD UtenteModifica NVARCHAR(256) NULL;';

    IF COL_LENGTH(N'dbo.TipiNodoDistinta', N'VersioneRiga') IS NULL
        EXEC sys.sp_executesql N'ALTER TABLE dbo.TipiNodoDistinta ADD VersioneRiga ROWVERSION NOT NULL;';

    EXEC sys.sp_executesql N'
    CREATE OR ALTER PROCEDURE dbo.UnitaMisura_Elenco
        @Ricerca NVARCHAR(100) = NULL,
        @SoloAttivi BIT = NULL
    AS
    BEGIN
        SET NOCOUNT ON;
        DECLARE @Filtro NVARCHAR(100) = NULLIF(LTRIM(RTRIM(@Ricerca)), N'''');
        SELECT IdUM AS Id, CodiceUM AS Codice, Descrizione, Attivo
        FROM dbo.UnitaMisura
        WHERE (@SoloAttivi IS NULL OR Attivo = @SoloAttivi)
          AND (@Filtro IS NULL OR CodiceUM LIKE N''%'' + @Filtro + N''%'' OR Descrizione LIKE N''%'' + @Filtro + N''%'')
        ORDER BY CodiceUM;
    END;';

    EXEC sys.sp_executesql N'
    CREATE OR ALTER PROCEDURE dbo.UnitaMisura_Dettaglio
        @IdUM INT
    AS
    BEGIN
        SET NOCOUNT ON;
        SELECT IdUM AS Id, CodiceUM AS Codice, Descrizione, Attivo,
               DataCreazione, DataModifica, UtenteCreazione, UtenteModifica, VersioneRiga
        FROM dbo.UnitaMisura
        WHERE IdUM = @IdUM;
    END;';

    EXEC sys.sp_executesql N'
    CREATE OR ALTER PROCEDURE dbo.UnitaMisura_Crea
        @CodiceUM NVARCHAR(10),
        @Descrizione NVARCHAR(50),
        @Utente NVARCHAR(256)
    AS
    BEGIN
        SET NOCOUNT ON;
        SET XACT_ABORT ON;
        SET @CodiceUM = NULLIF(LTRIM(RTRIM(@CodiceUM)), N'''');
        SET @Descrizione = NULLIF(LTRIM(RTRIM(@Descrizione)), N'''');
        SET @Utente = NULLIF(LTRIM(RTRIM(@Utente)), N'''');
        IF @CodiceUM IS NULL OR @Descrizione IS NULL OR @Utente IS NULL
            THROW 53101, ''Campi obbligatori mancanti.'', 1;
        BEGIN TRANSACTION;
        IF EXISTS (SELECT 1 FROM dbo.UnitaMisura WITH (UPDLOCK, HOLDLOCK) WHERE CodiceUM = @CodiceUM)
            THROW 53102, ''Codice unita di misura gia utilizzato.'', 1;
        INSERT INTO dbo.UnitaMisura (CodiceUM, Descrizione, Attivo, DataCreazione, UtenteCreazione)
        VALUES (@CodiceUM, @Descrizione, 1, SYSDATETIME(), @Utente);
        DECLARE @IdUM INT = CONVERT(INT, SCOPE_IDENTITY());
        COMMIT TRANSACTION;
        SELECT @IdUM;
    END;';

    EXEC sys.sp_executesql N'
    CREATE OR ALTER PROCEDURE dbo.UnitaMisura_Aggiorna
        @IdUM INT,
        @CodiceUM NVARCHAR(10),
        @Descrizione NVARCHAR(50),
        @Utente NVARCHAR(256),
        @VersioneRiga BINARY(8)
    AS
    BEGIN
        SET NOCOUNT ON;
        SET XACT_ABORT ON;
        SET @CodiceUM = NULLIF(LTRIM(RTRIM(@CodiceUM)), N'''');
        SET @Descrizione = NULLIF(LTRIM(RTRIM(@Descrizione)), N'''');
        SET @Utente = NULLIF(LTRIM(RTRIM(@Utente)), N'''');
        IF @CodiceUM IS NULL OR @Descrizione IS NULL OR @Utente IS NULL
            THROW 53101, ''Campi obbligatori mancanti.'', 1;
        BEGIN TRANSACTION;
        IF NOT EXISTS (SELECT 1 FROM dbo.UnitaMisura WITH (UPDLOCK, HOLDLOCK) WHERE IdUM = @IdUM)
            THROW 53104, ''Unita di misura non trovata.'', 1;
        IF EXISTS (SELECT 1 FROM dbo.UnitaMisura WITH (UPDLOCK, HOLDLOCK) WHERE CodiceUM = @CodiceUM AND IdUM <> @IdUM)
            THROW 53102, ''Codice unita di misura gia utilizzato.'', 1;
        UPDATE dbo.UnitaMisura
        SET CodiceUM = @CodiceUM, Descrizione = @Descrizione,
            DataModifica = SYSDATETIME(), UtenteModifica = @Utente
        WHERE IdUM = @IdUM AND VersioneRiga = @VersioneRiga;
        IF @@ROWCOUNT = 0
            THROW 53105, ''Unita di misura modificata da un altro utente.'', 1;
        COMMIT TRANSACTION;
    END;';

    EXEC sys.sp_executesql N'
    CREATE OR ALTER PROCEDURE dbo.UnitaMisura_ImpostaStato
        @IdUM INT,
        @Attivo BIT,
        @Utente NVARCHAR(256),
        @VersioneRiga BINARY(8)
    AS
    BEGIN
        SET NOCOUNT ON;
        UPDATE dbo.UnitaMisura
        SET Attivo = @Attivo, DataModifica = SYSDATETIME(), UtenteModifica = @Utente
        WHERE IdUM = @IdUM AND VersioneRiga = @VersioneRiga;
        IF @@ROWCOUNT = 0
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM dbo.UnitaMisura WHERE IdUM = @IdUM)
                THROW 53104, ''Unita di misura non trovata.'', 1;
            THROW 53105, ''Unita di misura modificata da un altro utente.'', 1;
        END;
    END;';

    EXEC sys.sp_executesql N'
    CREATE OR ALTER PROCEDURE dbo.UnitaMisura_Elimina
        @IdUM INT,
        @VersioneRiga BINARY(8)
    AS
    BEGIN
        SET NOCOUNT ON;
        SET XACT_ABORT ON;
        BEGIN TRANSACTION;
        IF NOT EXISTS (SELECT 1 FROM dbo.UnitaMisura WITH (UPDLOCK, HOLDLOCK) WHERE IdUM = @IdUM)
            THROW 53104, ''Unita di misura non trovata.'', 1;
        IF NOT EXISTS (SELECT 1 FROM dbo.UnitaMisura WHERE IdUM = @IdUM AND VersioneRiga = @VersioneRiga)
            THROW 53105, ''Unita di misura modificata da un altro utente.'', 1;
        IF EXISTS (SELECT 1 FROM dbo.Materiali WITH (UPDLOCK, HOLDLOCK) WHERE IdUM = @IdUM)
            THROW 53106, ''Unita di misura utilizzata da materiali.'', 1;
        DELETE FROM dbo.UnitaMisura WHERE IdUM = @IdUM AND VersioneRiga = @VersioneRiga;
        COMMIT TRANSACTION;
    END;';

    EXEC sys.sp_executesql N'
    CREATE OR ALTER PROCEDURE dbo.TipiNodoDistinta_Elenco
        @Ricerca NVARCHAR(100) = NULL,
        @SoloAttivi BIT = NULL
    AS
    BEGIN
        SET NOCOUNT ON;
        DECLARE @Filtro NVARCHAR(100) = NULLIF(LTRIM(RTRIM(@Ricerca)), N'''');
        SELECT IdTipoNodo AS Id, CAST(NULL AS NVARCHAR(10)) AS Codice, Descrizione, Attivo
        FROM dbo.TipiNodoDistinta
        WHERE (@SoloAttivi IS NULL OR Attivo = @SoloAttivi)
          AND (@Filtro IS NULL OR Descrizione LIKE N''%'' + @Filtro + N''%'')
        ORDER BY Descrizione;
    END;';

    EXEC sys.sp_executesql N'
    CREATE OR ALTER PROCEDURE dbo.TipiNodoDistinta_Dettaglio
        @IdTipoNodo INT
    AS
    BEGIN
        SET NOCOUNT ON;
        SELECT IdTipoNodo AS Id, CAST(NULL AS NVARCHAR(10)) AS Codice, Descrizione, Attivo,
               DataCreazione, DataModifica, UtenteCreazione, UtenteModifica, VersioneRiga
        FROM dbo.TipiNodoDistinta
        WHERE IdTipoNodo = @IdTipoNodo;
    END;';

    EXEC sys.sp_executesql N'
    CREATE OR ALTER PROCEDURE dbo.TipiNodoDistinta_Crea
        @Descrizione NVARCHAR(100),
        @Utente NVARCHAR(256)
    AS
    BEGIN
        SET NOCOUNT ON;
        SET XACT_ABORT ON;
        SET @Descrizione = NULLIF(LTRIM(RTRIM(@Descrizione)), N'''');
        SET @Utente = NULLIF(LTRIM(RTRIM(@Utente)), N'''');
        IF @Descrizione IS NULL OR @Utente IS NULL
            THROW 53111, ''Campi obbligatori mancanti.'', 1;
        BEGIN TRANSACTION;
        IF EXISTS (SELECT 1 FROM dbo.TipiNodoDistinta WITH (UPDLOCK, HOLDLOCK) WHERE Descrizione = @Descrizione)
            THROW 53113, ''Descrizione tipo nodo gia utilizzata.'', 1;
        INSERT INTO dbo.TipiNodoDistinta (Descrizione, Attivo, DataCreazione, UtenteCreazione)
        VALUES (@Descrizione, 1, SYSDATETIME(), @Utente);
        DECLARE @IdTipoNodo INT = CONVERT(INT, SCOPE_IDENTITY());
        COMMIT TRANSACTION;
        SELECT @IdTipoNodo;
    END;';

    EXEC sys.sp_executesql N'
    CREATE OR ALTER PROCEDURE dbo.TipiNodoDistinta_Aggiorna
        @IdTipoNodo INT,
        @Descrizione NVARCHAR(100),
        @Utente NVARCHAR(256),
        @VersioneRiga BINARY(8)
    AS
    BEGIN
        SET NOCOUNT ON;
        SET XACT_ABORT ON;
        SET @Descrizione = NULLIF(LTRIM(RTRIM(@Descrizione)), N'''');
        SET @Utente = NULLIF(LTRIM(RTRIM(@Utente)), N'''');
        IF @Descrizione IS NULL OR @Utente IS NULL
            THROW 53111, ''Campi obbligatori mancanti.'', 1;
        BEGIN TRANSACTION;
        IF NOT EXISTS (SELECT 1 FROM dbo.TipiNodoDistinta WITH (UPDLOCK, HOLDLOCK) WHERE IdTipoNodo = @IdTipoNodo)
            THROW 53114, ''Tipo nodo non trovato.'', 1;
        IF EXISTS (SELECT 1 FROM dbo.TipiNodoDistinta WITH (UPDLOCK, HOLDLOCK) WHERE Descrizione = @Descrizione AND IdTipoNodo <> @IdTipoNodo)
            THROW 53113, ''Descrizione tipo nodo gia utilizzata.'', 1;
        UPDATE dbo.TipiNodoDistinta
        SET Descrizione = @Descrizione, DataModifica = SYSDATETIME(), UtenteModifica = @Utente
        WHERE IdTipoNodo = @IdTipoNodo AND VersioneRiga = @VersioneRiga;
        IF @@ROWCOUNT = 0
            THROW 53115, ''Tipo nodo modificato da un altro utente.'', 1;
        COMMIT TRANSACTION;
    END;';

    EXEC sys.sp_executesql N'
    CREATE OR ALTER PROCEDURE dbo.TipiNodoDistinta_ImpostaStato
        @IdTipoNodo INT,
        @Attivo BIT,
        @Utente NVARCHAR(256),
        @VersioneRiga BINARY(8)
    AS
    BEGIN
        SET NOCOUNT ON;
        UPDATE dbo.TipiNodoDistinta
        SET Attivo = @Attivo, DataModifica = SYSDATETIME(), UtenteModifica = @Utente
        WHERE IdTipoNodo = @IdTipoNodo AND VersioneRiga = @VersioneRiga;
        IF @@ROWCOUNT = 0
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM dbo.TipiNodoDistinta WHERE IdTipoNodo = @IdTipoNodo)
                THROW 53114, ''Tipo nodo non trovato.'', 1;
            THROW 53115, ''Tipo nodo modificato da un altro utente.'', 1;
        END;
    END;';

    EXEC sys.sp_executesql N'
    CREATE OR ALTER PROCEDURE dbo.TipiNodoDistinta_Elimina
        @IdTipoNodo INT,
        @VersioneRiga BINARY(8)
    AS
    BEGIN
        SET NOCOUNT ON;
        SET XACT_ABORT ON;
        BEGIN TRANSACTION;
        IF NOT EXISTS (SELECT 1 FROM dbo.TipiNodoDistinta WITH (UPDLOCK, HOLDLOCK) WHERE IdTipoNodo = @IdTipoNodo)
            THROW 53114, ''Tipo nodo non trovato.'', 1;
        IF NOT EXISTS (SELECT 1 FROM dbo.TipiNodoDistinta WHERE IdTipoNodo = @IdTipoNodo AND VersioneRiga = @VersioneRiga)
            THROW 53115, ''Tipo nodo modificato da un altro utente.'', 1;
        IF EXISTS (SELECT 1 FROM dbo.DistintaBaseNodi WITH (UPDLOCK, HOLDLOCK) WHERE IdTipoNodo = @IdTipoNodo)
            THROW 53116, ''Tipo nodo utilizzato da una distinta.'', 1;
        DELETE FROM dbo.TipiNodoDistinta WHERE IdTipoNodo = @IdTipoNodo AND VersioneRiga = @VersioneRiga;
        COMMIT TRANSACTION;
    END;';

    DECLARE @IdGruppoAnagrafiche INT;
    SELECT @IdGruppoAnagrafiche = IdGruppoMenu
    FROM dbo.MenuGruppi
    WHERE CodiceGruppo = N'ANAGRAFICHE';

    IF @IdGruppoAnagrafiche IS NULL
    BEGIN
        INSERT INTO dbo.MenuGruppi (CodiceGruppo, Descrizione, Ordine, Attivo)
        VALUES (N'ANAGRAFICHE', N'Anagrafiche', 30, 1);
        SET @IdGruppoAnagrafiche = CONVERT(INT, SCOPE_IDENTITY());
    END;

    DECLARE @IdVoceAnagrafiche INT;
    SELECT @IdVoceAnagrafiche = IdVoceMenu
    FROM dbo.MenuVoci
    WHERE NomeMaschera = N'frmAnagrafiche';

    IF @IdVoceAnagrafiche IS NULL
    BEGIN
        INSERT INTO dbo.MenuVoci
            (IdGruppoMenu, Descrizione, NomeMaschera, TipoApertura, Ordine, Attivo, Note, TipoOggetto)
        VALUES
            (@IdGruppoAnagrafiche, N'Gestione anagrafiche', N'frmAnagrafiche', N'Web', 20, 1,
             N'Unita di misura e tipi nodo distinta', N'Page');
        SET @IdVoceAnagrafiche = CONVERT(INT, SCOPE_IDENTITY());
    END;

    INSERT INTO dbo.MenuPermessiRuoli (IdRuolo, IdVoceMenu, Consenti)
    SELECT ruolo.IdRuolo, @IdVoceAnagrafiche, 1
    FROM dbo.RuoliApplicazione AS ruolo
    WHERE ruolo.CodiceRuolo = N'ADMIN'
      AND NOT EXISTS
      (
          SELECT 1
          FROM dbo.MenuPermessiRuoli AS permesso
          WHERE permesso.IdRuolo = ruolo.IdRuolo
            AND permesso.IdVoceMenu = @IdVoceAnagrafiche
      );
    /* PAYLOAD TEC-016-ANAGRAFICHE-BASE END */

    DECLARE @Versione INT = 2026110301;
    DECLARE @CodiceIntervento NVARCHAR(50) = N'TEC-016-ANAGRAFICHE-BASE';
    DECLARE @NomeScript NVARCHAR(260) = N'TEC-016_01_Anagrafiche_Base.sql';
    -- SHA-256 del contenuto fra i marcatori PAYLOAD inclusi, normalizzato con LF.
    DECLARE @ImprontaSha256 CHAR(64) = '0E5606014B6ED3C471B547813DFA2715CCC93E7324B7B710296FA2417E10E2F6';

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
        THROW 53199, 'TEC-016-ANAGRAFICHE-BASE: versione gia registrata con dati o impronta differenti.', 1;

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
        N'Gestione di unita di misura e tipi nodo distinta con audit e concorrenza.',
        @ImprontaSha256
    );

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0
        ROLLBACK TRANSACTION;
    THROW;
END CATCH;
