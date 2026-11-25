-- Decisioni 382-386: importazione di nuovi articoli, senza aggiornamenti.
-- Lo script non seleziona il database e non inserisce anagrafiche di prova.
SET NOCOUNT ON;
SET XACT_ABORT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET NUMERIC_ROUNDABORT OFF;
BEGIN TRY
    BEGIN TRANSACTION;
    DECLARE @Versione INT=2026112506;
    DECLARE @Codice NVARCHAR(50)=N'PFW-IMPORT-ARTICOLI';
    DECLARE @Script NVARCHAR(260)=N'PFW_02_Importazione_Articoli.sql';
    -- SHA-256 del payload fra i marcatori: righe LF, Trim, UTF-8.
    DECLARE @Impronta CHAR(64)='33FBEA9AAFA3507A5ABFBA90CFF2B71C15A5CAFF8930EFBCC544013A964368FC';
    IF OBJECT_ID(N'dbo.VersioniSchema',N'U') IS NULL
        THROW 54610,'Registro VersioniSchema assente.',1;
    IF NOT EXISTS(SELECT 1 FROM dbo.VersioniSchema WITH(UPDLOCK,HOLDLOCK)
        WHERE Versione=2026112505 AND CodiceIntervento=N'PFW-LUNGHEZZE-TESTI')
        THROW 54610,'Prerequisito 2026112505 non installato.',1;
    IF EXISTS(SELECT 1 FROM dbo.VersioniSchema WHERE Versione>@Versione)
        THROW 54610,'Il database contiene una versione successiva.',1;
    IF EXISTS(SELECT 1 FROM dbo.VersioniSchema WHERE Versione=@Versione AND CodiceIntervento=@Codice AND NomeScript=@Script AND ImprontaSha256=@Impronta)
    BEGIN COMMIT TRANSACTION; RETURN; END;
    IF EXISTS(SELECT 1 FROM dbo.VersioniSchema WHERE Versione=@Versione OR CodiceIntervento=@Codice OR NomeScript=@Script)
        THROW 54610,'Versione registrata con metadati differenti.',1;
/* PAYLOAD PFW-IMPORT-ARTICOLI START */
IF OBJECT_ID(N'dbo.ArticoliImportazioni',N'U') IS NOT NULL
        THROW 54610,'La tabella ArticoliImportazioni esiste senza la versione attesa.',1;
    CREATE TABLE dbo.ArticoliImportazioni(
        IdImportazione UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_ArticoliImportazioni PRIMARY KEY,
        NomeFile NVARCHAR(260) NOT NULL,ImprontaSha256 CHAR(64) NOT NULL,Utente NVARCHAR(256) NOT NULL,
        DataOperazione DATETIME2(0) NOT NULL,Stato NVARCHAR(12) NOT NULL,
        NumeroArticoli INT NOT NULL,Messaggio NVARCHAR(2048) NOT NULL,
        CONSTRAINT CK_ArticoliImportazioni_Stato CHECK(Stato IN(N'Completata',N'Rifiutata')),
        CONSTRAINT CK_ArticoliImportazioni_Numero CHECK(
            (Stato=N'Completata' AND NumeroArticoli>0) OR (Stato=N'Rifiutata' AND NumeroArticoli=0)));
    CREATE UNIQUE INDEX UX_ArticoliImportazioni_FileCompletato
        ON dbo.ArticoliImportazioni(ImprontaSha256) WHERE Stato=N'Completata';
    DECLARE @CollationArticoli SYSNAME=(SELECT collation_name FROM sys.columns WHERE object_id=OBJECT_ID(N'dbo.Articoli') AND name=N'CodiceArticolo');
    DECLARE @CollationClienti SYSNAME=(SELECT collation_name FROM sys.columns WHERE object_id=OBJECT_ID(N'dbo.Clienti') AND name=N'CodiceCliente');
    IF @CollationArticoli IS NULL OR @CollationClienti IS NULL
        OR NOT EXISTS(SELECT 1 FROM sys.fn_helpcollations() WHERE name=@CollationArticoli)
        OR NOT EXISTS(SELECT 1 FROM sys.fn_helpcollations() WHERE name=@CollationClienti)
        THROW 54610,'Colonne codice articolo/cliente non disponibili.',1;
    DECLARE @Definizione NVARCHAR(MAX);
    SET @Definizione=N'CREATE OR ALTER PROCEDURE dbo.Anagrafiche_Articoli_Importazione_Valida
    @Righe NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    IF ISNULL(ISJSON(@Righe),0) <> 1 OR LEFT(LTRIM(@Righe),1) <> N''[''
        THROW 54601, ''Formato del contenuto articoli non valido.'', 1;
    IF EXISTS(SELECT 1 FROM OPENJSON(@Righe) WHERE type <> 5)
        THROW 54601, ''Ogni riga deve contenere i dati di un articolo.'', 1;
    DECLARE @Dati TABLE(RigaExcel INT, Codice NVARCHAR(MAX), Descrizione NVARCHAR(MAX),
        Versione NVARCHAR(MAX), Cliente NVARCHAR(MAX));
    INSERT @Dati
    SELECT TRY_CONVERT(INT,RigaExcel),LTRIM(RTRIM(Codice)),LTRIM(RTRIM(Descrizione)),
        NULLIF(LTRIM(RTRIM(Versione)),N''''),NULLIF(LTRIM(RTRIM(Cliente)),N'''')
    FROM OPENJSON(@Righe) WITH(RigaExcel NVARCHAR(MAX),Codice NVARCHAR(MAX) ''$.CodiceArticolo'',
        Descrizione NVARCHAR(MAX),Versione NVARCHAR(MAX),Cliente NVARCHAR(MAX) ''$.CodiceCliente'');
    DECLARE @Errori TABLE(RigaExcel INT, Campo NVARCHAR(100), Messaggio NVARCHAR(2048));
    IF NOT EXISTS(SELECT 1 FROM @Dati)
        INSERT @Errori VALUES(0,N''Righe'',N''Inserire almeno un articolo.'');
    INSERT @Errori SELECT ISNULL(RigaExcel,0),N''Riga'',N''Numero riga Excel non valido.''
        FROM @Dati WHERE RigaExcel IS NULL OR RigaExcel < 2 OR RigaExcel > 1048576;
    INSERT @Errori SELECT RigaExcel,N''Riga'',N''Numero riga duplicato nel file.''
        FROM @Dati GROUP BY RigaExcel HAVING COUNT(*) > 1;
    INSERT @Errori SELECT RigaExcel,N''Codice articolo'',N''Codice obbligatorio, massimo 50 caratteri.''
        FROM @Dati WHERE NULLIF(Codice,N'''') IS NULL OR DATALENGTH(Codice) > 100;
    INSERT @Errori SELECT RigaExcel,N''Descrizione'',N''Descrizione obbligatoria, massimo 200 caratteri.''
        FROM @Dati WHERE NULLIF(Descrizione,N'''') IS NULL OR DATALENGTH(Descrizione) > 400;
    INSERT @Errori SELECT RigaExcel,N''Versione articolo'',N''Massimo 20 caratteri.''
        FROM @Dati WHERE DATALENGTH(Versione) > 40;
    INSERT @Errori SELECT RigaExcel,N''Codice cliente'',N''Massimo 30 caratteri.''
        FROM @Dati WHERE DATALENGTH(Cliente) > 60;
    INSERT @Errori SELECT RigaExcel,N''Codice articolo'',N''Codice duplicato nel file.''
        FROM (SELECT RigaExcel,Codice,COUNT(*) OVER(PARTITION BY Codice COLLATE __ARTICOLI_COLLATION__) AS Numero FROM @Dati) AS d
        WHERE d.Numero > 1 AND NULLIF(d.Codice,N'''') IS NOT NULL;
    INSERT @Errori SELECT d.RigaExcel,N''Codice articolo'',N''Codice gia presente, anche se non attivo. Nessun aggiornamento automatico.''
        FROM @Dati AS d WHERE EXISTS(SELECT 1 FROM dbo.Articoli WITH(HOLDLOCK)
            WHERE CodiceArticolo = d.Codice COLLATE __ARTICOLI_COLLATION__);
    INSERT @Errori SELECT d.RigaExcel,N''Codice cliente'',N''Cliente inesistente o non attivo.''
        FROM @Dati AS d WHERE d.Cliente IS NOT NULL AND NOT EXISTS(
            SELECT 1 FROM dbo.Clienti WITH(HOLDLOCK) WHERE CodiceCliente = d.Cliente COLLATE __CLIENTI_COLLATION__ AND Attivo = 1);
    SELECT ISNULL(RigaExcel,0) AS RigaExcel,Campo,Messaggio FROM @Errori ORDER BY RigaExcel,Campo;
END;';
    SET @Definizione=REPLACE(REPLACE(@Definizione,N'__ARTICOLI_COLLATION__',@CollationArticoli),N'__CLIENTI_COLLATION__',@CollationClienti);
    EXEC sys.sp_executesql @Definizione;
    SET @Definizione=N'CREATE OR ALTER PROCEDURE dbo.Anagrafiche_Articoli_Importazione_Applica
    @IdImportazione UNIQUEIDENTIFIER,@NomeFile NVARCHAR(260),@ImprontaSha256 CHAR(64),
    @Utente NVARCHAR(256),@Righe NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    IF @@TRANCOUNT <> 0 THROW 54601,''Avviare l''''importazione senza una transazione esterna.'',1;
    SET @NomeFile = NULLIF(LTRIM(RTRIM(@NomeFile)),N'''');
    SET @Utente = NULLIF(LTRIM(RTRIM(@Utente)),N'''');
    SET @ImprontaSha256 = UPPER(@ImprontaSha256);
    IF @IdImportazione IS NULL OR @NomeFile IS NULL OR @Utente IS NULL
       OR LOWER(RIGHT(@NomeFile,5)) <> N''.xlsx'' OR @ImprontaSha256 IS NULL
       OR LEN(@ImprontaSha256) <> 64 OR @ImprontaSha256 LIKE ''%[^0-9A-F]%''
        THROW 54601,''Metadati importazione non validi.'',1;
    BEGIN TRY
        BEGIN TRANSACTION;
        DECLARE @Blocco INT;
        EXEC @Blocco = sys.sp_getapplock @Resource=N''PFW-Importazione-Articoli'',
            @LockMode=N''Exclusive'',@LockOwner=N''Transaction'',@LockTimeout=10000;
        IF @Blocco < 0 THROW 54602,''Importazione in corso. Riprovare dopo una nuova anteprima.'',1;
        IF EXISTS(SELECT 1 FROM dbo.ArticoliImportazioni WITH(UPDLOCK,HOLDLOCK)
            WHERE IdImportazione=@IdImportazione OR (ImprontaSha256=@ImprontaSha256 AND Stato=N''Completata''))
            THROW 54603,''File o operazione gia importati. Nessun articolo e stato aggiunto.'',1;
        DECLARE @Errori TABLE(RigaExcel INT,Campo NVARCHAR(100),Messaggio NVARCHAR(2048));
        INSERT @Errori EXEC dbo.Anagrafiche_Articoli_Importazione_Valida @Righe=@Righe;
        IF EXISTS(SELECT 1 FROM @Errori)
        BEGIN
            DECLARE @Errore NVARCHAR(2048);
            SELECT TOP(1) @Errore=CONCAT(N''Riga '',RigaExcel,N'' - '',Campo,N'': '',Messaggio)
                FROM @Errori ORDER BY RigaExcel,Campo;
            THROW 54604,@Errore,1;
        END;
        INSERT dbo.Articoli(CodiceArticolo,Descrizione,Versione,IdCliente,Attivo,NoteTecniche,
            DataCreazione,DataModifica,UtenteCreazione,UtenteModifica)
        SELECT LTRIM(RTRIM(d.Codice)),LTRIM(RTRIM(d.Descrizione)),NULLIF(LTRIM(RTRIM(d.Versione)),N''''),
            c.IdCliente,1,NULLIF(LTRIM(RTRIM(d.NoteTecniche)),N''''),SYSDATETIME(),NULL,@Utente,NULL
        FROM OPENJSON(@Righe) WITH(Codice NVARCHAR(MAX) ''$.CodiceArticolo'',Descrizione NVARCHAR(MAX),
            Versione NVARCHAR(MAX),Cliente NVARCHAR(MAX) ''$.CodiceCliente'',NoteTecniche NVARCHAR(MAX)) AS d
        LEFT JOIN dbo.Clienti AS c WITH(HOLDLOCK)
            ON c.CodiceCliente = NULLIF(LTRIM(RTRIM(d.Cliente)),N'''') COLLATE __CLIENTI_COLLATION__ AND c.Attivo=1;
        DECLARE @Numero INT = @@ROWCOUNT;
        INSERT dbo.ArticoliImportazioni(IdImportazione,NomeFile,ImprontaSha256,Utente,DataOperazione,Stato,NumeroArticoli,Messaggio)
            VALUES(@IdImportazione,@NomeFile,@ImprontaSha256,@Utente,SYSDATETIME(),N''Completata'',@Numero,N''Importazione completata.'');
        COMMIT TRANSACTION;
        SELECT @Numero;
    END TRY
    BEGIN CATCH
        DECLARE @Messaggio NVARCHAR(2048)=LEFT(ERROR_MESSAGE(),2048);
        IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
        IF NOT EXISTS(SELECT 1 FROM dbo.ArticoliImportazioni WHERE IdImportazione=@IdImportazione)
            INSERT dbo.ArticoliImportazioni(IdImportazione,NomeFile,ImprontaSha256,Utente,DataOperazione,Stato,NumeroArticoli,Messaggio)
                VALUES(@IdImportazione,@NomeFile,@ImprontaSha256,@Utente,SYSDATETIME(),N''Rifiutata'',0,@Messaggio);
        THROW;
    END CATCH;
END;';
    SET @Definizione=REPLACE(@Definizione,N'__CLIENTI_COLLATION__',@CollationClienti);
    EXEC sys.sp_executesql @Definizione;
    EXEC sys.sp_executesql N'CREATE OR ALTER TRIGGER dbo.TR_ArticoliImportazioni_Immutabili
        ON dbo.ArticoliImportazioni INSTEAD OF UPDATE, DELETE AS
        BEGIN SET NOCOUNT ON; THROW 54611,''Il registro importazioni non puo essere modificato o eliminato.'',1; END;';
/* PAYLOAD PFW-IMPORT-ARTICOLI END */
    INSERT dbo.VersioniSchema(Versione,CodiceIntervento,NomeScript,Descrizione,ImprontaSha256)
        VALUES(@Versione,@Codice,@Script,N'Importazione transazionale nuovi articoli da Excel, validazione e registro esiti.',@Impronta);
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
