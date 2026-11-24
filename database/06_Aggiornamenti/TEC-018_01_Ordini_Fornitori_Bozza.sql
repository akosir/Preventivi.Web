-- Decisioni 347-351. Gestione ordini fornitori in Bozza.
SET NOCOUNT ON;
SET XACT_ABORT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
BEGIN TRY
    BEGIN TRANSACTION;
    DECLARE @Versione INT = 2026112302;
    DECLARE @Codice NVARCHAR(50) = N'TEC-018-ORDINI-BOZZA';
    DECLARE @Script NVARCHAR(260) = N'TEC-018_01_Ordini_Fornitori_Bozza.sql';
    DECLARE @Impronta CHAR(64) = '5A698B9051FC72F35B0351F71D62F229FB9A7F862789970B1FA13563925016F1';
    IF NOT EXISTS (SELECT 1 FROM dbo.VersioniSchema WITH (UPDLOCK, HOLDLOCK)
                   WHERE Versione = 2026112301 AND CodiceIntervento = N'TEC-017-FORNITORI')
        THROW 53896, 'Versione prerequisito 2026112301 non installata.', 1;
    IF EXISTS (SELECT 1 FROM dbo.VersioniSchema WHERE Versione > @Versione)
        THROW 53897, 'Il database contiene una versione successiva.', 1;
    IF EXISTS (SELECT 1 FROM dbo.VersioniSchema WHERE Versione = @Versione AND CodiceIntervento = @Codice
               AND NomeScript = @Script AND ImprontaSha256 = @Impronta)
    BEGIN
        COMMIT TRANSACTION;
        RETURN;
    END;
    IF EXISTS (SELECT 1 FROM dbo.VersioniSchema WHERE Versione = @Versione OR CodiceIntervento = @Codice OR NomeScript = @Script)
        THROW 53898, 'Versione gia registrata con metadati differenti.', 1;
    IF OBJECT_ID(N'dbo.OrdiniFornitori', N'U') IS NULL OR OBJECT_ID(N'dbo.OrdiniFornitoriRighe', N'U') IS NULL
        THROW 54101, 'Tabelle prerequisito mancanti.', 1;

/* PAYLOAD TEC-018-ORDINI-BOZZA START */
    IF COL_LENGTH(N'dbo.OrdiniFornitori', N'UtenteCreazione') IS NULL
        EXEC sys.sp_executesql N'ALTER TABLE dbo.OrdiniFornitori ADD UtenteCreazione NVARCHAR(256) NOT NULL CONSTRAINT DF_OrdiniFornitori_UtenteCreazione DEFAULT (N''MIGRAZIONE-TEC-018'') WITH VALUES;';
    IF COL_LENGTH(N'dbo.OrdiniFornitori', N'UtenteModifica') IS NULL
        EXEC sys.sp_executesql N'ALTER TABLE dbo.OrdiniFornitori ADD UtenteModifica NVARCHAR(256) NULL;';
    IF COL_LENGTH(N'dbo.OrdiniFornitori', N'VersioneRiga') IS NULL
        EXEC sys.sp_executesql N'ALTER TABLE dbo.OrdiniFornitori ADD VersioneRiga ROWVERSION NOT NULL;';
    IF COL_LENGTH(N'dbo.OrdiniFornitoriRighe', N'UtenteCreazione') IS NULL
        EXEC sys.sp_executesql N'ALTER TABLE dbo.OrdiniFornitoriRighe ADD UtenteCreazione NVARCHAR(256) NOT NULL CONSTRAINT DF_OrdiniFornitoriRighe_UtenteCreazione DEFAULT (N''MIGRAZIONE-TEC-018'') WITH VALUES;';
    IF COL_LENGTH(N'dbo.OrdiniFornitoriRighe', N'UtenteModifica') IS NULL
        EXEC sys.sp_executesql N'ALTER TABLE dbo.OrdiniFornitoriRighe ADD UtenteModifica NVARCHAR(256) NULL;';
    IF COL_LENGTH(N'dbo.OrdiniFornitoriRighe', N'VersioneRiga') IS NULL
        EXEC sys.sp_executesql N'ALTER TABLE dbo.OrdiniFornitoriRighe ADD VersioneRiga ROWVERSION NOT NULL;';
    IF COL_LENGTH(N'dbo.OrdiniFornitoriRighe', N'DataCreazione') IS NULL
        EXEC sys.sp_executesql N'ALTER TABLE dbo.OrdiniFornitoriRighe ADD DataCreazione DATETIME2(0) NOT NULL CONSTRAINT DF_OrdiniFornitoriRighe_DataCreazione DEFAULT (SYSDATETIME()) WITH VALUES;';
    IF COL_LENGTH(N'dbo.OrdiniFornitoriRighe', N'DataModifica') IS NULL
        EXEC sys.sp_executesql N'ALTER TABLE dbo.OrdiniFornitoriRighe ADD DataModifica DATETIME2(0) NULL;';
    IF OBJECT_ID(N'dbo.OrdiniFornitoriAudit', N'U') IS NULL
        EXEC sys.sp_executesql N'CREATE TABLE dbo.OrdiniFornitoriAudit
        (IdAudit BIGINT IDENTITY PRIMARY KEY, IdOrdineFornitore INT NOT NULL, IdRigaOrdineFornitore INT NULL,
         Operazione NVARCHAR(40) NOT NULL, Utente NVARCHAR(256) NOT NULL, DataOperazione DATETIME2(0) NOT NULL);';
    IF OBJECT_ID(N'dbo.OrdiniFornitoriProgressivi', N'U') IS NULL
        EXEC sys.sp_executesql N'CREATE TABLE dbo.OrdiniFornitoriProgressivi (Anno INT PRIMARY KEY, UltimoNumero INT NOT NULL);
        INSERT dbo.OrdiniFornitoriProgressivi SELECT Anno, MAX(NumeroOrdine) FROM dbo.OrdiniFornitori GROUP BY Anno;';
    EXEC sys.sp_executesql N'CREATE OR ALTER PROCEDURE dbo.OrdiniFornitori_Elenco
    @Numero INT = NULL, @Anno INT = NULL, @IdFornitore INT = NULL,
    @Dal DATE = NULL, @Al DATE = NULL, @Stato NVARCHAR(30) = NULL, @Oggetto NVARCHAR(250) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT o.*, f.CodiceFornitore, f.RagioneSociale, f.Indirizzo, f.CAP, f.Citta, f.Provincia, f.PartitaIVA, f.Email
    FROM dbo.OrdiniFornitori AS o JOIN dbo.Fornitori AS f ON f.IdFornitore = o.IdFornitore
    WHERE (@Numero IS NULL OR o.NumeroOrdine = @Numero) AND (@Anno IS NULL OR o.Anno = @Anno)
      AND (@IdFornitore IS NULL OR o.IdFornitore = @IdFornitore)
      AND (@Dal IS NULL OR o.DataOrdine >= @Dal) AND (@Al IS NULL OR o.DataOrdine <= @Al)
      AND (@Stato IS NULL OR o.Stato = @Stato)
      AND (@Oggetto IS NULL OR o.Oggetto LIKE N''%'' + @Oggetto + N''%'')
    ORDER BY o.Anno DESC, o.NumeroOrdine DESC;
END;';

    EXEC sys.sp_executesql N'CREATE OR ALTER PROCEDURE dbo.OrdiniFornitori_Dettaglio @IdOrdine INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT o.*, f.CodiceFornitore, f.RagioneSociale, f.Indirizzo, f.CAP, f.Citta, f.Provincia, f.PartitaIVA, f.Email
    FROM dbo.OrdiniFornitori AS o JOIN dbo.Fornitori AS f ON f.IdFornitore = o.IdFornitore WHERE o.IdOrdineFornitore = @IdOrdine;
END;';

    EXEC sys.sp_executesql N'CREATE OR ALTER PROCEDURE dbo.OrdiniFornitori_Righe_Elenco @IdOrdine INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM dbo.OrdiniFornitoriRighe WHERE IdOrdineFornitore = @IdOrdine ORDER BY RigaNr;
END;';

    EXEC sys.sp_executesql N'CREATE OR ALTER PROCEDURE dbo.OrdiniFornitori_Dipendenze @IdOrdine INT, @IdRiga INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Sql NVARCHAR(MAX);
    SELECT @Sql = STRING_AGG(CONVERT(NVARCHAR(MAX),
        N''SELECT N''''Riferimenti collegati'''' AS Tipo, COUNT_BIG(*) AS Numero FROM ''
        + QUOTENAME(SCHEMA_NAME(t.schema_id)) + N''.'' + QUOTENAME(t.name)
        + N'' WITH (UPDLOCK, HOLDLOCK) WHERE '' + QUOTENAME(c.name)
        + CASE WHEN fk.referenced_object_id = OBJECT_ID(N''dbo.OrdiniFornitori'')
               THEN N'' = @IdOrdine AND @IdRiga IS NULL''
               ELSE N'' IN (SELECT IdRigaOrdineFornitore FROM dbo.OrdiniFornitoriRighe WHERE IdOrdineFornitore = @IdOrdine
                        AND (@IdRiga IS NULL OR IdRigaOrdineFornitore = @IdRiga))'' END
        + N'' HAVING COUNT_BIG(*) > 0''), N'' UNION ALL '')
    FROM sys.foreign_key_columns AS fk
    JOIN sys.tables AS t ON t.object_id = fk.parent_object_id
    JOIN sys.columns AS c ON c.object_id = t.object_id AND c.column_id = fk.parent_column_id
    WHERE fk.referenced_object_id IN (OBJECT_ID(N''dbo.OrdiniFornitori''), OBJECT_ID(N''dbo.OrdiniFornitoriRighe''))
      AND fk.parent_object_id NOT IN (OBJECT_ID(N''dbo.OrdiniFornitoriRighe''), OBJECT_ID(N''dbo.OrdiniFornitoriAudit''));
    SET @Sql = COALESCE(@Sql + N'' UNION ALL '', N'''')
        + N''SELECT N''''Allegati'''' AS Tipo, COUNT_BIG(*) AS Numero FROM dbo.Allegati WITH (UPDLOCK, HOLDLOCK)
             WHERE (@IdRiga IS NULL AND Entita = N''''OrdiniFornitori'''' AND IdEntita = @IdOrdine)
                OR (Entita = N''''OrdiniFornitoriRighe'''' AND IdEntita IN
                    (SELECT IdRigaOrdineFornitore FROM dbo.OrdiniFornitoriRighe WHERE IdOrdineFornitore = @IdOrdine
                     AND (@IdRiga IS NULL OR IdRigaOrdineFornitore = @IdRiga))) HAVING COUNT_BIG(*) > 0'';
    EXEC sys.sp_executesql @Sql, N''@IdOrdine INT, @IdRiga INT'', @IdOrdine, @IdRiga;
END;';

    EXEC sys.sp_executesql N'CREATE OR ALTER PROCEDURE dbo.OrdiniFornitori_Salva
    @IdOrdine INT = NULL, @DataOrdine DATE, @IdFornitore INT,
    @Oggetto NVARCHAR(250) = NULL, @Note NVARCHAR(MAX) = NULL, @DataConsegnaPrevista DATE = NULL,
    @Utente NVARCHAR(256), @VersioneRiga BINARY(8) = NULL
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    IF @DataOrdine IS NULL OR @IdFornitore IS NULL OR NULLIF(LTRIM(RTRIM(@Utente)), N'''') IS NULL
        THROW 54101, ''Dati ordine incompleti.'', 1;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF @IdOrdine IS NOT NULL
        BEGIN
            DECLARE @VersioneOrdine BINARY(8) = @VersioneRiga;
        IF NOT EXISTS (SELECT 1 FROM dbo.OrdiniFornitori WITH (UPDLOCK, HOLDLOCK) WHERE IdOrdineFornitore = @IdOrdine)
            THROW 54103, ''Ordine non trovato.'', 1;
        IF NOT EXISTS (SELECT 1 FROM dbo.OrdiniFornitori WHERE IdOrdineFornitore = @IdOrdine AND Stato = N''Bozza'')
            THROW 54105, ''Operazione consentita in Bozza.'', 1;
        IF @VersioneOrdine IS NULL OR NOT EXISTS
            (SELECT 1 FROM dbo.OrdiniFornitori WHERE IdOrdineFornitore = @IdOrdine AND VersioneRiga = @VersioneOrdine)
            THROW 54104, ''Ordine modificato da altro utente.'', 1;
            IF YEAR(@DataOrdine) <> (SELECT Anno FROM dbo.OrdiniFornitori WHERE IdOrdineFornitore = @IdOrdine)
                THROW 54112, ''La data deve appartenere all anno di numerazione.'', 1;
        END;
        IF NOT EXISTS
        (
            SELECT 1 FROM dbo.Fornitori WITH (UPDLOCK, HOLDLOCK)
            WHERE IdFornitore = @IdFornitore
              AND (Attivo = 1 OR EXISTS (SELECT 1 FROM dbo.OrdiniFornitori WHERE IdOrdineFornitore = @IdOrdine AND IdFornitore = @IdFornitore))
        )
            THROW 54102, ''Fornitore non valido.'', 1;
        IF @IdOrdine IS NULL
        BEGIN
            DECLARE @Anno INT = YEAR(@DataOrdine), @Numero INT;
            SELECT @Numero = UltimoNumero FROM dbo.OrdiniFornitoriProgressivi WITH (UPDLOCK, HOLDLOCK) WHERE Anno = @Anno;
            DECLARE @Massimo INT = COALESCE((SELECT MAX(NumeroOrdine) FROM dbo.OrdiniFornitori WITH (UPDLOCK, HOLDLOCK) WHERE Anno = @Anno), 0);
            IF @Numero IS NULL
            BEGIN
                SET @Numero = @Massimo + 1;
                INSERT dbo.OrdiniFornitoriProgressivi (Anno, UltimoNumero) VALUES (@Anno, @Numero);
            END
            ELSE
            BEGIN
                SET @Numero = CASE WHEN @Numero > @Massimo THEN @Numero ELSE @Massimo END + 1;
                UPDATE dbo.OrdiniFornitoriProgressivi SET UltimoNumero = @Numero WHERE Anno = @Anno;
            END;
            INSERT dbo.OrdiniFornitori (NumeroOrdine, Anno, DataOrdine, IdFornitore, Oggetto, Stato, Note, TotaleOrdine,
                DataConsegnaPrevista, DataCreazione, UtenteCreazione)
            VALUES (@Numero, @Anno, @DataOrdine, @IdFornitore, @Oggetto, N''Bozza'', @Note, 0,
                @DataConsegnaPrevista, SYSDATETIME(), @Utente);
            SET @IdOrdine = CONVERT(INT, SCOPE_IDENTITY());
        INSERT dbo.OrdiniFornitoriAudit (IdOrdineFornitore, IdRigaOrdineFornitore, Operazione, Utente, DataOperazione)
        VALUES (@IdOrdine, NULL, N''Creazione'', @Utente, SYSDATETIME());
        END
        ELSE
        BEGIN
        UPDATE dbo.OrdiniFornitoriRighe
        SET TotaleRiga = CASE WHEN TipoRiga = N''Nota'' THEN 0 ELSE ROUND(Quantita * PrezzoUnitario, 2) END
        WHERE IdOrdineFornitore = @IdOrdine
          AND TotaleRiga <> CASE WHEN TipoRiga = N''Nota'' THEN 0 ELSE ROUND(Quantita * PrezzoUnitario, 2) END;
            UPDATE dbo.OrdiniFornitori SET DataOrdine = @DataOrdine, IdFornitore = @IdFornitore,
                Oggetto = @Oggetto, Note = @Note, DataConsegnaPrevista = @DataConsegnaPrevista,
                TotaleOrdine = (SELECT COALESCE(SUM(TotaleRiga), 0) FROM dbo.OrdiniFornitoriRighe WHERE IdOrdineFornitore = @IdOrdine),
                DataModifica = SYSDATETIME(), UtenteModifica = @Utente
            WHERE IdOrdineFornitore = @IdOrdine AND VersioneRiga = @VersioneRiga;
            IF @@ROWCOUNT <> 1 THROW 54104, ''Ordine modificato durante il salvataggio.'', 1;
        INSERT dbo.OrdiniFornitoriAudit (IdOrdineFornitore, IdRigaOrdineFornitore, Operazione, Utente, DataOperazione)
        VALUES (@IdOrdine, NULL, N''Modifica testata'', @Utente, SYSDATETIME());
        END;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
    SELECT @IdOrdine;
END;';

    EXEC sys.sp_executesql N'CREATE OR ALTER PROCEDURE dbo.OrdiniFornitori_Righe_Salva
    @IdOrdine INT, @IdRiga INT = NULL, @RigaNr INT, @TipoRiga NVARCHAR(20),
    @IdMateriale INT = NULL, @IdLavorazione INT = NULL, @Descrizione NVARCHAR(250),
    @UM NVARCHAR(10) = NULL, @Quantita DECIMAL(18,4), @PrezzoUnitario DECIMAL(18,4),
    @DataConsegnaPrevista DATE = NULL, @Note NVARCHAR(500) = NULL, @Utente NVARCHAR(256),
    @VersioneRiga BINARY(8) = NULL, @VersioneOrdine BINARY(8)
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    SET @Descrizione = NULLIF(LTRIM(RTRIM(@Descrizione)), N'''');
    IF @TipoRiga IS NULL OR @TipoRiga NOT IN (N''Materiale'', N''Lavorazione'', N''Nota'')
       OR @Descrizione IS NULL OR @RigaNr IS NULL OR @RigaNr <= 0
       OR @Quantita IS NULL OR @Quantita <= 0 OR @PrezzoUnitario IS NULL OR @PrezzoUnitario < 0
       OR NULLIF(LTRIM(RTRIM(@Utente)), N'''') IS NULL
        THROW 54101, ''Dati riga non validi.'', 1;
    IF @TipoRiga <> N''Materiale'' SET @IdMateriale = NULL;
    IF @TipoRiga <> N''Lavorazione'' SET @IdLavorazione = NULL;
    IF @TipoRiga = N''Nota'' SET @PrezzoUnitario = 0;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF NOT EXISTS (SELECT 1 FROM dbo.OrdiniFornitori WITH (UPDLOCK, HOLDLOCK) WHERE IdOrdineFornitore = @IdOrdine)
            THROW 54103, ''Ordine non trovato.'', 1;
        IF NOT EXISTS (SELECT 1 FROM dbo.OrdiniFornitori WHERE IdOrdineFornitore = @IdOrdine AND Stato = N''Bozza'')
            THROW 54105, ''Operazione consentita in Bozza.'', 1;
        IF @VersioneOrdine IS NULL OR NOT EXISTS
            (SELECT 1 FROM dbo.OrdiniFornitori WHERE IdOrdineFornitore = @IdOrdine AND VersioneRiga = @VersioneOrdine)
            THROW 54104, ''Ordine modificato da altro utente.'', 1;
        IF @IdRiga IS NOT NULL
        BEGIN
        IF NOT EXISTS (SELECT 1 FROM dbo.OrdiniFornitoriRighe WITH (UPDLOCK, HOLDLOCK)
                       WHERE IdRigaOrdineFornitore = @IdRiga AND IdOrdineFornitore = @IdOrdine)
            THROW 54106, ''Riga non appartenente all ordine.'', 1;
        IF @VersioneRiga IS NULL OR NOT EXISTS
            (SELECT 1 FROM dbo.OrdiniFornitoriRighe WHERE IdRigaOrdineFornitore = @IdRiga AND VersioneRiga = @VersioneRiga)
            THROW 54107, ''Riga modificata da altro utente.'', 1;
        END;
        IF @IdMateriale IS NOT NULL AND NOT EXISTS
        (
            SELECT 1 FROM dbo.Materiali WITH (UPDLOCK, HOLDLOCK) WHERE IdMateriale = @IdMateriale
            AND (Attivo = 1 OR EXISTS (SELECT 1 FROM dbo.OrdiniFornitoriRighe WHERE IdRigaOrdineFornitore = @IdRiga AND IdMateriale = @IdMateriale))
        )
            THROW 54108, ''Materiale non disponibile.'', 1;
        IF @IdLavorazione IS NOT NULL AND NOT EXISTS
        (
            SELECT 1 FROM dbo.Lavorazioni WITH (UPDLOCK, HOLDLOCK) WHERE IdLavorazione = @IdLavorazione
            AND (Attiva = 1 OR EXISTS (SELECT 1 FROM dbo.OrdiniFornitoriRighe WHERE IdRigaOrdineFornitore = @IdRiga AND IdLavorazione = @IdLavorazione))
        )
            THROW 54108, ''Lavorazione non disponibile.'', 1;
        IF EXISTS (SELECT 1 FROM dbo.OrdiniFornitoriRighe WITH (UPDLOCK, HOLDLOCK)
                   WHERE IdOrdineFornitore = @IdOrdine AND RigaNr = @RigaNr AND (@IdRiga IS NULL OR IdRigaOrdineFornitore <> @IdRiga))
            THROW 54109, ''Numero riga duplicato.'', 1;
        DECLARE @Totale DECIMAL(18,2) = ROUND(@Quantita * @PrezzoUnitario, 2);
        IF @IdRiga IS NULL
        BEGIN
            INSERT dbo.OrdiniFornitoriRighe (IdOrdineFornitore, RigaNr, TipoRiga, IdMateriale, IdLavorazione,
                Descrizione, UM, Quantita, PrezzoUnitario, TotaleRiga, QuantitaRicevuta, DataConsegnaPrevista,
                Note, DataCreazione, UtenteCreazione)
            VALUES (@IdOrdine, @RigaNr, @TipoRiga, @IdMateriale, @IdLavorazione, @Descrizione, @UM,
                @Quantita, @PrezzoUnitario, @Totale, 0, @DataConsegnaPrevista, @Note, SYSDATETIME(), @Utente);
            SET @IdRiga = CONVERT(INT, SCOPE_IDENTITY());
        INSERT dbo.OrdiniFornitoriAudit (IdOrdineFornitore, IdRigaOrdineFornitore, Operazione, Utente, DataOperazione)
        VALUES (@IdOrdine, @IdRiga, N''Creazione riga'', @Utente, SYSDATETIME());
        END
        ELSE
        BEGIN
            UPDATE dbo.OrdiniFornitoriRighe SET RigaNr = @RigaNr, TipoRiga = @TipoRiga, IdMateriale = @IdMateriale,
                IdLavorazione = @IdLavorazione, Descrizione = @Descrizione, UM = @UM, Quantita = @Quantita,
                PrezzoUnitario = @PrezzoUnitario, TotaleRiga = @Totale, DataConsegnaPrevista = @DataConsegnaPrevista,
                Note = @Note, DataModifica = SYSDATETIME(), UtenteModifica = @Utente
            WHERE IdRigaOrdineFornitore = @IdRiga AND VersioneRiga = @VersioneRiga;
            IF @@ROWCOUNT <> 1 THROW 54107, ''Riga modificata durante il salvataggio.'', 1;
        INSERT dbo.OrdiniFornitoriAudit (IdOrdineFornitore, IdRigaOrdineFornitore, Operazione, Utente, DataOperazione)
        VALUES (@IdOrdine, @IdRiga, N''Modifica riga'', @Utente, SYSDATETIME());
        END;
        UPDATE dbo.OrdiniFornitoriRighe
        SET TotaleRiga = CASE WHEN TipoRiga = N''Nota'' THEN 0 ELSE ROUND(Quantita * PrezzoUnitario, 2) END
        WHERE IdOrdineFornitore = @IdOrdine
          AND TotaleRiga <> CASE WHEN TipoRiga = N''Nota'' THEN 0 ELSE ROUND(Quantita * PrezzoUnitario, 2) END;
        UPDATE dbo.OrdiniFornitori
        SET TotaleOrdine = (SELECT COALESCE(SUM(TotaleRiga), 0) FROM dbo.OrdiniFornitoriRighe WHERE IdOrdineFornitore = @IdOrdine),
            DataModifica = SYSDATETIME(), UtenteModifica = @Utente
        WHERE IdOrdineFornitore = @IdOrdine;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
    SELECT @IdRiga;
END;';

    EXEC sys.sp_executesql N'CREATE OR ALTER PROCEDURE dbo.OrdiniFornitori_Elimina
    @IdOrdine INT, @VersioneOrdine BINARY(8), @Utente NVARCHAR(256)
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    IF NULLIF(LTRIM(RTRIM(@Utente)), N'''') IS NULL THROW 54101, ''Utente richiesto.'', 1;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF NOT EXISTS (SELECT 1 FROM dbo.OrdiniFornitori WITH (UPDLOCK, HOLDLOCK) WHERE IdOrdineFornitore = @IdOrdine)
            THROW 54103, ''Ordine non trovato.'', 1;
        IF NOT EXISTS (SELECT 1 FROM dbo.OrdiniFornitori WHERE IdOrdineFornitore = @IdOrdine AND Stato = N''Bozza'')
            THROW 54105, ''Operazione consentita in Bozza.'', 1;
        IF @VersioneOrdine IS NULL OR NOT EXISTS
            (SELECT 1 FROM dbo.OrdiniFornitori WHERE IdOrdineFornitore = @IdOrdine AND VersioneRiga = @VersioneOrdine)
            THROW 54104, ''Ordine modificato da altro utente.'', 1;
        DECLARE @Dipendenze TABLE (Tipo NVARCHAR(256), Numero BIGINT);
        INSERT @Dipendenze EXEC dbo.OrdiniFornitori_Dipendenze @IdOrdine, NULL;
        IF EXISTS (SELECT 1 FROM @Dipendenze) THROW 54110, ''Ordine con dipendenze.'', 1;
        INSERT dbo.OrdiniFornitoriAudit (IdOrdineFornitore, IdRigaOrdineFornitore, Operazione, Utente, DataOperazione)
        VALUES (@IdOrdine, NULL, N''Eliminazione ordine'', @Utente, SYSDATETIME());
        DELETE dbo.OrdiniFornitoriRighe WHERE IdOrdineFornitore = @IdOrdine;
        DELETE dbo.OrdiniFornitori WHERE IdOrdineFornitore = @IdOrdine;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;';

    EXEC sys.sp_executesql N'CREATE OR ALTER PROCEDURE dbo.OrdiniFornitori_Righe_Elimina
    @IdOrdine INT, @IdRiga INT, @VersioneOrdine BINARY(8), @VersioneRiga BINARY(8), @Utente NVARCHAR(256)
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    IF NULLIF(LTRIM(RTRIM(@Utente)), N'''') IS NULL THROW 54101, ''Utente richiesto.'', 1;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF NOT EXISTS (SELECT 1 FROM dbo.OrdiniFornitori WITH (UPDLOCK, HOLDLOCK) WHERE IdOrdineFornitore = @IdOrdine)
            THROW 54103, ''Ordine non trovato.'', 1;
        IF NOT EXISTS (SELECT 1 FROM dbo.OrdiniFornitori WHERE IdOrdineFornitore = @IdOrdine AND Stato = N''Bozza'')
            THROW 54105, ''Operazione consentita in Bozza.'', 1;
        IF @VersioneOrdine IS NULL OR NOT EXISTS
            (SELECT 1 FROM dbo.OrdiniFornitori WHERE IdOrdineFornitore = @IdOrdine AND VersioneRiga = @VersioneOrdine)
            THROW 54104, ''Ordine modificato da altro utente.'', 1;
        IF NOT EXISTS (SELECT 1 FROM dbo.OrdiniFornitoriRighe WITH (UPDLOCK, HOLDLOCK)
                       WHERE IdRigaOrdineFornitore = @IdRiga AND IdOrdineFornitore = @IdOrdine)
            THROW 54106, ''Riga non appartenente all ordine.'', 1;
        IF @VersioneRiga IS NULL OR NOT EXISTS
            (SELECT 1 FROM dbo.OrdiniFornitoriRighe WHERE IdRigaOrdineFornitore = @IdRiga AND VersioneRiga = @VersioneRiga)
            THROW 54107, ''Riga modificata da altro utente.'', 1;
        DECLARE @Dipendenze TABLE (Tipo NVARCHAR(256), Numero BIGINT);
        INSERT @Dipendenze EXEC dbo.OrdiniFornitori_Dipendenze @IdOrdine, @IdRiga;
        IF EXISTS (SELECT 1 FROM @Dipendenze) THROW 54110, ''Riga con dipendenze.'', 1;
        INSERT dbo.OrdiniFornitoriAudit (IdOrdineFornitore, IdRigaOrdineFornitore, Operazione, Utente, DataOperazione)
        VALUES (@IdOrdine, @IdRiga, N''Eliminazione riga'', @Utente, SYSDATETIME());
        DELETE dbo.OrdiniFornitoriRighe WHERE IdRigaOrdineFornitore = @IdRiga AND IdOrdineFornitore = @IdOrdine;
        UPDATE dbo.OrdiniFornitoriRighe
        SET TotaleRiga = CASE WHEN TipoRiga = N''Nota'' THEN 0 ELSE ROUND(Quantita * PrezzoUnitario, 2) END
        WHERE IdOrdineFornitore = @IdOrdine
          AND TotaleRiga <> CASE WHEN TipoRiga = N''Nota'' THEN 0 ELSE ROUND(Quantita * PrezzoUnitario, 2) END;
        UPDATE dbo.OrdiniFornitori
        SET TotaleOrdine = (SELECT COALESCE(SUM(TotaleRiga), 0) FROM dbo.OrdiniFornitoriRighe WHERE IdOrdineFornitore = @IdOrdine),
            DataModifica = SYSDATETIME(), UtenteModifica = @Utente
        WHERE IdOrdineFornitore = @IdOrdine;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;';

    EXEC sys.sp_executesql N'CREATE OR ALTER TRIGGER dbo.TR_Allegati_VerificaOrdineFornitore
ON dbo.Allegati AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM inserted AS a WHERE a.Entita = N''OrdiniFornitori''
               AND NOT EXISTS (SELECT 1 FROM dbo.OrdiniFornitori AS o WITH (UPDLOCK, HOLDLOCK) WHERE o.IdOrdineFornitore = a.IdEntita))
        THROW 54103, ''Ordine non trovato per l allegato.'', 1;
END;';
    DECLARE @IdGruppo INT;
    SELECT @IdGruppo = IdGruppoMenu FROM dbo.MenuGruppi WHERE CodiceGruppo = N'ACQUISTI';
    IF @IdGruppo IS NULL
    BEGIN
        INSERT dbo.MenuGruppi (CodiceGruppo, Descrizione, Ordine, Attivo) VALUES (N'ACQUISTI', N'Acquisti', 40, 1);
        SET @IdGruppo = CONVERT(INT, SCOPE_IDENTITY());
    END;
    IF NOT EXISTS (SELECT 1 FROM dbo.MenuVoci WHERE NomeMaschera = N'frmOrdiniFornitori')
        INSERT dbo.MenuVoci (IdGruppoMenu, Descrizione, NomeMaschera, TipoApertura, Ordine, Attivo, Note, TipoOggetto)
        VALUES (@IdGruppo, N'Ordini fornitori', N'frmOrdiniFornitori', N'Web', 10, 1, N'Gestione ordini fornitori in Bozza', N'Page');
    ELSE
        UPDATE dbo.MenuVoci SET Attivo = 1, TipoApertura = N'Web', TipoOggetto = N'Page'
        WHERE NomeMaschera = N'frmOrdiniFornitori';
/* PAYLOAD TEC-018-ORDINI-BOZZA END */

    INSERT dbo.VersioniSchema (Versione, CodiceIntervento, NomeScript, Descrizione, ImprontaSha256)
    VALUES (@Versione, @Codice, @Script, N'Gestione ordini fornitori in Bozza con righe, totali, audit e concorrenza.', @Impronta);
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
