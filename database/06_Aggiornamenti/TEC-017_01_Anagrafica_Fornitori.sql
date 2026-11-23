-- Decisioni 341-345. Eseguire sul database di test dopo 2026111901.
SET NOCOUNT ON;
SET XACT_ABORT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;

BEGIN TRY
    BEGIN TRANSACTION;
    DECLARE @Versione INT = 2026112301;
    DECLARE @Codice NVARCHAR(50) = N'TEC-017-FORNITORI';
    DECLARE @Script NVARCHAR(260) = N'TEC-017_01_Anagrafica_Fornitori.sql';
    DECLARE @Impronta CHAR(64) = '7E6046C6A4703CB4FF29934E7EB03E650C67031A4B2B2B7BD67A72F5F7E4F997';
    IF NOT EXISTS (SELECT 1 FROM dbo.VersioniSchema WITH (UPDLOCK, HOLDLOCK)
                   WHERE Versione = 2026111901 AND CodiceIntervento = N'TEC-016-DUPLICA-CORRENTE')
        THROW 53896, 'Versione prerequisito 2026111901 non installata.', 1;
    IF EXISTS (SELECT 1 FROM dbo.VersioniSchema WHERE Versione > @Versione)
        THROW 53897, 'Il database contiene una versione successiva.', 1;
    IF EXISTS (SELECT 1 FROM dbo.VersioniSchema WHERE Versione = @Versione
               AND CodiceIntervento = @Codice AND NomeScript = @Script AND ImprontaSha256 = @Impronta)
    BEGIN
        COMMIT TRANSACTION;
        RETURN;
    END;
    IF EXISTS (SELECT 1 FROM dbo.VersioniSchema WHERE Versione = @Versione
               OR CodiceIntervento = @Codice OR NomeScript = @Script)
        THROW 53898, 'Versione gia registrata con metadati differenti.', 1;
    IF OBJECT_ID(N'dbo.Fornitori', N'U') IS NULL OR OBJECT_ID(N'dbo.Allegati', N'U') IS NULL
        THROW 54001, 'Tabelle prerequisito mancanti.', 1;

/* PAYLOAD TEC-017-FORNITORI START */
    IF COL_LENGTH(N'dbo.Fornitori', N'UtenteCreazione') IS NULL
        EXEC sys.sp_executesql N'ALTER TABLE dbo.Fornitori ADD UtenteCreazione NVARCHAR(256) NOT NULL CONSTRAINT DF_Fornitori_UtenteCreazione DEFAULT (N''MIGRAZIONE-TEC-017'') WITH VALUES;';
    IF COL_LENGTH(N'dbo.Fornitori', N'UtenteModifica') IS NULL
        EXEC sys.sp_executesql N'ALTER TABLE dbo.Fornitori ADD UtenteModifica NVARCHAR(256) NULL;';
    IF COL_LENGTH(N'dbo.Fornitori', N'VersioneRiga') IS NULL
        EXEC sys.sp_executesql N'ALTER TABLE dbo.Fornitori ADD VersioneRiga ROWVERSION NOT NULL;';
    IF OBJECT_ID(N'dbo.FornitoriAudit', N'U') IS NULL
        EXEC sys.sp_executesql N'CREATE TABLE dbo.FornitoriAudit
        (
            IdAudit BIGINT IDENTITY PRIMARY KEY, IdFornitore INT NOT NULL,
            Operazione NVARCHAR(30) NOT NULL, Utente NVARCHAR(256) NOT NULL,
            DataOperazione DATETIME2(0) NOT NULL
        );';
    EXEC sys.sp_executesql N'CREATE OR ALTER PROCEDURE dbo.Anagrafiche_Fornitori_Elenco
    @Ricerca NVARCHAR(200) = NULL, @SoloAttivi BIT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET @Ricerca = NULLIF(LTRIM(RTRIM(@Ricerca)), N'''');
    SELECT *
    FROM dbo.Fornitori
    WHERE (@SoloAttivi IS NULL OR Attivo = @SoloAttivi)
      AND (@Ricerca IS NULL OR CodiceFornitore LIKE N''%'' + @Ricerca + N''%''
           OR RagioneSociale LIKE N''%'' + @Ricerca + N''%''
           OR PartitaIVA LIKE N''%'' + @Ricerca + N''%''
           OR CodiceFiscale LIKE N''%'' + @Ricerca + N''%'')
    ORDER BY RagioneSociale, CodiceFornitore;
END;';

    EXEC sys.sp_executesql N'CREATE OR ALTER PROCEDURE dbo.Anagrafiche_Fornitori_Dettaglio
    @IdFornitore INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM dbo.Fornitori WHERE IdFornitore = @IdFornitore;
END;';

    EXEC sys.sp_executesql N'CREATE OR ALTER PROCEDURE dbo.Anagrafiche_Fornitori_Dipendenze
    @IdFornitore INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Sql NVARCHAR(MAX);
    SELECT @Sql = STRING_AGG(CONVERT(NVARCHAR(MAX),
        N''SELECT N'''''' + REPLACE(
            CASE t.name
                WHEN N''FornitoriMateriali'' THEN N''Associazioni materiali''
                WHEN N''FornitoriLavorazioni'' THEN N''Associazioni lavorazioni''
                WHEN N''Materiali'' THEN N''Fornitore predefinito materiali''
                WHEN N''Lavorazioni'' THEN N''Fornitore predefinito lavorazioni''
                WHEN N''PreventiviRigheMateriali'' THEN N''Materiali dei preventivi''
                WHEN N''PreventiviRigheLavorazioni'' THEN N''Lavorazioni dei preventivi''
                WHEN N''OrdiniFornitori'' THEN N''Ordini fornitori''
                WHEN N''RichiesteOffertaFornitori'' THEN N''Richieste di offerta''
                ELSE N''Altri collegamenti''
            END, N'''''''', N'''''''''''') + N'''''' AS Tipo, COUNT_BIG(*) AS Numero FROM ''
        + QUOTENAME(SCHEMA_NAME(t.schema_id)) + N''.'' + QUOTENAME(t.name)
        + N'' WITH (UPDLOCK, HOLDLOCK) WHERE '' + QUOTENAME(c.name) + N'' = @IdFornitore HAVING COUNT_BIG(*) > 0''), N'' UNION ALL '')
    FROM sys.tables AS t
    JOIN sys.columns AS c ON c.object_id = t.object_id
    WHERE t.is_ms_shipped = 0 AND t.name NOT IN (N''Fornitori'', N''FornitoriAudit'')
      AND
      (
          c.name IN (N''IdFornitore'', N''IdFornitorePredefinito'', N''IdFornitoreSuggerito'')
          OR EXISTS
          (
              SELECT 1 FROM sys.foreign_key_columns AS fk
              WHERE fk.parent_object_id = t.object_id AND fk.parent_column_id = c.column_id
                AND fk.referenced_object_id = OBJECT_ID(N''dbo.Fornitori'')
          )
      );
    SET @Sql = COALESCE(@Sql + N'' UNION ALL '', N'''')
        + N''SELECT N''''Allegati'''' AS Tipo, COUNT_BIG(*) AS Numero FROM dbo.Allegati WITH (UPDLOCK, HOLDLOCK)
            WHERE Entita = N''''Fornitori'''' AND IdEntita = @IdFornitore HAVING COUNT_BIG(*) > 0'';
    EXEC sys.sp_executesql @Sql, N''@IdFornitore INT'', @IdFornitore;
END;';

    EXEC sys.sp_executesql N'CREATE OR ALTER PROCEDURE dbo.Anagrafiche_Fornitori_Crea
    @CodiceFornitore NVARCHAR(30),
    @RagioneSociale NVARCHAR(150),
    @PartitaIVA NVARCHAR(20) = NULL,
    @CodiceFiscale NVARCHAR(20) = NULL,
    @Indirizzo NVARCHAR(150) = NULL,
    @CAP NVARCHAR(10) = NULL,
    @Citta NVARCHAR(100) = NULL,
    @Provincia NVARCHAR(10) = NULL,
    @Telefono NVARCHAR(50) = NULL,
    @Email NVARCHAR(150) = NULL,
    @Referente NVARCHAR(100) = NULL,
    @Utente NVARCHAR(256)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET @CodiceFornitore = NULLIF(LTRIM(RTRIM(@CodiceFornitore)), N'''');
    SET @RagioneSociale = NULLIF(LTRIM(RTRIM(@RagioneSociale)), N'''');
    SET @PartitaIVA = NULLIF(LTRIM(RTRIM(@PartitaIVA)), N'''');
    SET @CodiceFiscale = NULLIF(LTRIM(RTRIM(@CodiceFiscale)), N'''');
    SET @Indirizzo = NULLIF(LTRIM(RTRIM(@Indirizzo)), N'''');
    SET @CAP = NULLIF(LTRIM(RTRIM(@CAP)), N'''');
    SET @Citta = NULLIF(LTRIM(RTRIM(@Citta)), N'''');
    SET @Provincia = NULLIF(LTRIM(RTRIM(@Provincia)), N'''');
    SET @Telefono = NULLIF(LTRIM(RTRIM(@Telefono)), N'''');
    SET @Email = NULLIF(LTRIM(RTRIM(@Email)), N'''');
    SET @Referente = NULLIF(LTRIM(RTRIM(@Referente)), N'''');
    SET @Utente = NULLIF(LTRIM(RTRIM(@Utente)), N'''');
    IF @CodiceFornitore IS NULL OR @RagioneSociale IS NULL OR @Utente IS NULL
        THROW 54001, ''Compilare i campi obbligatori.'', 1;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF EXISTS (SELECT 1 FROM dbo.Fornitori WITH (UPDLOCK, HOLDLOCK) WHERE CodiceFornitore = @CodiceFornitore)
            THROW 54002, ''Codice fornitore gia utilizzato.'', 1;
        INSERT dbo.Fornitori (CodiceFornitore, RagioneSociale, PartitaIVA, CodiceFiscale, Indirizzo, CAP, Citta, Provincia, Telefono, Email, Referente, Attivo, DataCreazione, UtenteCreazione)
        VALUES (@CodiceFornitore, @RagioneSociale, @PartitaIVA, @CodiceFiscale, @Indirizzo, @CAP, @Citta, @Provincia, @Telefono, @Email, @Referente, 1, SYSDATETIME(), @Utente);
        DECLARE @IdFornitore INT = CONVERT(INT, SCOPE_IDENTITY());
        INSERT dbo.FornitoriAudit (IdFornitore, Operazione, Utente, DataOperazione)
        VALUES (@IdFornitore, N''Creazione'', @Utente, SYSDATETIME());
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
    SELECT @IdFornitore;
END;';

    EXEC sys.sp_executesql N'CREATE OR ALTER PROCEDURE dbo.Anagrafiche_Fornitori_Aggiorna
    @IdFornitore INT,
    @CodiceFornitore NVARCHAR(30),
    @RagioneSociale NVARCHAR(150),
    @PartitaIVA NVARCHAR(20) = NULL,
    @CodiceFiscale NVARCHAR(20) = NULL,
    @Indirizzo NVARCHAR(150) = NULL,
    @CAP NVARCHAR(10) = NULL,
    @Citta NVARCHAR(100) = NULL,
    @Provincia NVARCHAR(10) = NULL,
    @Telefono NVARCHAR(50) = NULL,
    @Email NVARCHAR(150) = NULL,
    @Referente NVARCHAR(100) = NULL,
    @Utente NVARCHAR(256), @VersioneRiga BINARY(8)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET @CodiceFornitore = NULLIF(LTRIM(RTRIM(@CodiceFornitore)), N'''');
    SET @RagioneSociale = NULLIF(LTRIM(RTRIM(@RagioneSociale)), N'''');
    SET @PartitaIVA = NULLIF(LTRIM(RTRIM(@PartitaIVA)), N'''');
    SET @CodiceFiscale = NULLIF(LTRIM(RTRIM(@CodiceFiscale)), N'''');
    SET @Indirizzo = NULLIF(LTRIM(RTRIM(@Indirizzo)), N'''');
    SET @CAP = NULLIF(LTRIM(RTRIM(@CAP)), N'''');
    SET @Citta = NULLIF(LTRIM(RTRIM(@Citta)), N'''');
    SET @Provincia = NULLIF(LTRIM(RTRIM(@Provincia)), N'''');
    SET @Telefono = NULLIF(LTRIM(RTRIM(@Telefono)), N'''');
    SET @Email = NULLIF(LTRIM(RTRIM(@Email)), N'''');
    SET @Referente = NULLIF(LTRIM(RTRIM(@Referente)), N'''');
    SET @Utente = NULLIF(LTRIM(RTRIM(@Utente)), N'''');
    IF @CodiceFornitore IS NULL OR @RagioneSociale IS NULL OR @Utente IS NULL
        THROW 54001, ''Compilare i campi obbligatori.'', 1;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF NOT EXISTS (SELECT 1 FROM dbo.Fornitori WITH (UPDLOCK, HOLDLOCK) WHERE IdFornitore = @IdFornitore)
            THROW 54003, ''Fornitore non trovato.'', 1;
        IF @VersioneRiga IS NULL OR NOT EXISTS (SELECT 1 FROM dbo.Fornitori WHERE IdFornitore = @IdFornitore AND VersioneRiga = @VersioneRiga)
            THROW 54004, ''Fornitore modificato da altro utente.'', 1;
        IF EXISTS (SELECT 1 FROM dbo.Fornitori WITH (UPDLOCK, HOLDLOCK) WHERE CodiceFornitore = @CodiceFornitore AND IdFornitore <> @IdFornitore)
            THROW 54002, ''Codice fornitore gia utilizzato.'', 1;
        UPDATE dbo.Fornitori SET
            CodiceFornitore = @CodiceFornitore,
            RagioneSociale = @RagioneSociale,
            PartitaIVA = @PartitaIVA,
            CodiceFiscale = @CodiceFiscale,
            Indirizzo = @Indirizzo,
            CAP = @CAP,
            Citta = @Citta,
            Provincia = @Provincia,
            Telefono = @Telefono,
            Email = @Email,
            Referente = @Referente,
            DataModifica = SYSDATETIME(), UtenteModifica = @Utente
        WHERE IdFornitore = @IdFornitore AND VersioneRiga = @VersioneRiga;
        INSERT dbo.FornitoriAudit (IdFornitore, Operazione, Utente, DataOperazione)
        VALUES (@IdFornitore, N''Modifica'', @Utente, SYSDATETIME());
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;';

    EXEC sys.sp_executesql N'CREATE OR ALTER PROCEDURE dbo.Anagrafiche_Fornitori_ImpostaStato
    @IdFornitore INT, @Attivo BIT, @Utente NVARCHAR(256), @VersioneRiga BINARY(8)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET @Utente = NULLIF(LTRIM(RTRIM(@Utente)), N'''');
    IF @Utente IS NULL OR @Attivo IS NULL THROW 54001, ''Dati stato non validi.'', 1;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF NOT EXISTS (SELECT 1 FROM dbo.Fornitori WITH (UPDLOCK, HOLDLOCK) WHERE IdFornitore = @IdFornitore)
            THROW 54003, ''Fornitore non trovato.'', 1;
        IF @VersioneRiga IS NULL OR NOT EXISTS (SELECT 1 FROM dbo.Fornitori WHERE IdFornitore = @IdFornitore AND VersioneRiga = @VersioneRiga)
            THROW 54004, ''Fornitore modificato da altro utente.'', 1;
        UPDATE dbo.Fornitori SET Attivo = @Attivo, DataModifica = SYSDATETIME(), UtenteModifica = @Utente
        WHERE IdFornitore = @IdFornitore AND VersioneRiga = @VersioneRiga;
        INSERT dbo.FornitoriAudit (IdFornitore, Operazione, Utente, DataOperazione)
        VALUES (@IdFornitore, CASE WHEN @Attivo = 1 THEN N''Riattivazione'' ELSE N''Disattivazione'' END, @Utente, SYSDATETIME());
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;';

    EXEC sys.sp_executesql N'CREATE OR ALTER PROCEDURE dbo.Anagrafiche_Fornitori_Elimina
    @IdFornitore INT, @Utente NVARCHAR(256), @VersioneRiga BINARY(8)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    IF NULLIF(LTRIM(RTRIM(@Utente)), N'''') IS NULL THROW 54001, ''Utente richiesto.'', 1;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF NOT EXISTS (SELECT 1 FROM dbo.Fornitori WITH (UPDLOCK, HOLDLOCK) WHERE IdFornitore = @IdFornitore)
            THROW 54003, ''Fornitore non trovato.'', 1;
        IF @VersioneRiga IS NULL OR NOT EXISTS (SELECT 1 FROM dbo.Fornitori WHERE IdFornitore = @IdFornitore AND VersioneRiga = @VersioneRiga)
            THROW 54004, ''Fornitore modificato da altro utente.'', 1;
        DECLARE @Dipendenze TABLE (Tipo NVARCHAR(256), Numero BIGINT);
        INSERT @Dipendenze EXEC dbo.Anagrafiche_Fornitori_Dipendenze @IdFornitore;
        IF EXISTS (SELECT 1 FROM @Dipendenze WHERE Numero > 0)
            THROW 54005, ''Il fornitore ha riferimenti collegati.'', 1;
        INSERT dbo.FornitoriAudit (IdFornitore, Operazione, Utente, DataOperazione)
        VALUES (@IdFornitore, N''Eliminazione'', @Utente, SYSDATETIME());
        DELETE dbo.Fornitori WHERE IdFornitore = @IdFornitore AND VersioneRiga = @VersioneRiga;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;';

    EXEC sys.sp_executesql N'CREATE OR ALTER TRIGGER dbo.TR_Allegati_VerificaFornitore
ON dbo.Allegati
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS
    (
        SELECT 1 FROM inserted AS a
        WHERE a.Entita = N''Fornitori''
          AND NOT EXISTS (SELECT 1 FROM dbo.Fornitori AS f WITH (UPDLOCK, HOLDLOCK) WHERE f.IdFornitore = a.IdEntita)
    )
        THROW 54003, ''Fornitore non trovato per l allegato.'', 1;
END;';
/* PAYLOAD TEC-017-FORNITORI END */

    INSERT dbo.VersioniSchema (Versione, CodiceIntervento, NomeScript, Descrizione, ImprontaSha256)
    VALUES (@Versione, @Codice, @Script, N'Anagrafica fornitori con audit, concorrenza, allegati e cancellazione controllata.', @Impronta);
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
