-- TEC-019 decisioni 367-371. Gestione utenti riservata ad ADMIN.
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
    DECLARE @Versione INT = 2026112504;
    DECLARE @Codice NVARCHAR(50) = N'TEC-019-UTENTI';
    DECLARE @Script NVARCHAR(260) = N'TEC-019_01_Gestione_Utenti.sql';
    DECLARE @Impronta CHAR(64) = 'C710B2EC56118DA227251F870E4A4809A9DE65308449ED5A4443C59DBA3B13FA';
    IF NOT EXISTS (SELECT 1 FROM dbo.VersioniSchema WITH (UPDLOCK, HOLDLOCK)
                   WHERE Versione = 2026112503 AND CodiceIntervento = N'TEC-009-VARIANTI-SCELTA')
        THROW 53896, 'Versione prerequisito 2026112503 non installata.', 1;
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

/* PAYLOAD TEC-019-UTENTI START */
    EXEC sys.sp_executesql N'ALTER TABLE dbo.UtentiApplicazione ADD VersioneRiga ROWVERSION,
    VersioneSessione UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_Utenti_VersioneSessione DEFAULT NEWID() WITH VALUES,
    DataModifica DATETIME2(0) NULL, UtenteModifica NVARCHAR(50) NULL;
CREATE TABLE dbo.UtentiGestioneAudit
(
    IdAudit BIGINT IDENTITY PRIMARY KEY,IdUtente INT NOT NULL,IdOperatore INT NOT NULL,
    Operatore NVARCHAR(50) NOT NULL,DataOperazione DATETIME2(0) NOT NULL DEFAULT SYSDATETIME(),
    Operazione NVARCHAR(30) NOT NULL,PrimaJson NVARCHAR(MAX) NULL,DopoJson NVARCHAR(MAX) NULL,
    CONSTRAINT FK_UtentiAudit_Utente FOREIGN KEY(IdUtente) REFERENCES dbo.UtentiApplicazione(IdUtente),
    CONSTRAINT FK_UtentiAudit_Operatore FOREIGN KEY(IdOperatore) REFERENCES dbo.UtentiApplicazione(IdUtente),
    CONSTRAINT CK_UtentiAudit_Json CHECK((PrimaJson IS NULL OR ISJSON(PrimaJson)=1) AND (DopoJson IS NULL OR ISJSON(DopoJson)=1))
);
CREATE INDEX IX_UtentiAudit_Utente ON dbo.UtentiGestioneAudit(IdUtente,IdAudit DESC);';
    EXEC sys.sp_executesql N'CREATE OR ALTER TRIGGER dbo.TR_UtentiGestioneAudit_Immutabile ON dbo.UtentiGestioneAudit INSTEAD OF UPDATE,DELETE
AS BEGIN SET NOCOUNT ON; THROW 54311,''Lo storico utenti non e modificabile.'',1; END;';
    EXEC sys.sp_executesql N'CREATE OR ALTER PROCEDURE dbo.Sicurezza_UtenteAccesso_Get
    @Username NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        u.IdUtente,
        u.Username,
        u.NomeCompleto,
        u.PasswordHash,
        u.Attivo,
        u.VersioneSessione
    FROM dbo.UtentiApplicazione AS u
    WHERE u.Username = @Username
      AND u.Attivo = 1;

    SELECT DISTINCT r.CodiceRuolo
    FROM dbo.UtentiApplicazione AS u
    INNER JOIN dbo.UtentiRuoli AS ur ON ur.IdUtente = u.IdUtente
    INNER JOIN dbo.RuoliApplicazione AS r ON r.IdRuolo = ur.IdRuolo
    WHERE u.Username = @Username
      AND u.Attivo = 1
      AND r.Attivo = 1
    ORDER BY r.CodiceRuolo;

    SELECT DISTINCT p.NomeMaschera
    FROM dbo.vw_MenuApplicazionePermessi AS p
    WHERE p.Username = @Username
    ORDER BY p.NomeMaschera;
END;';
    EXEC sys.sp_executesql N'CREATE OR ALTER PROCEDURE dbo.Utenti_Gestione_VerificaAdmin @IdOperatore INT,@SessioneOperatore UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS(SELECT 1 FROM dbo.UtentiApplicazione u WITH(HOLDLOCK)
        JOIN dbo.UtentiRuoli ur WITH(HOLDLOCK) ON ur.IdUtente=u.IdUtente
        JOIN dbo.RuoliApplicazione r WITH(HOLDLOCK) ON r.IdRuolo=ur.IdRuolo
        WHERE u.IdUtente=@IdOperatore AND u.Attivo=1 AND NULLIF(u.PasswordHash,N'''') IS NOT NULL
          AND u.VersioneSessione=@SessioneOperatore AND r.CodiceRuolo=N''ADMIN'' AND r.Attivo=1)
        THROW 54308,''Operazione riservata a un amministratore attivo con sessione valida.'',1;
END;';
    EXEC sys.sp_executesql N'CREATE OR ALTER PROCEDURE dbo.Utenti_Gestione_Elenco @IdOperatore INT,@SessioneOperatore UNIQUEIDENTIFIER,@Ricerca NVARCHAR(150)=NULL,@Attivo BIT=NULL
AS BEGIN SET NOCOUNT ON; EXEC dbo.Utenti_Gestione_VerificaAdmin @IdOperatore,@SessioneOperatore;
    SELECT u.IdUtente,u.Username,u.NomeCompleto,u.Attivo,u.DataCreazione,u.DataModifica,u.VersioneRiga,
        CAST(CASE WHEN NULLIF(u.PasswordHash,N'''') IS NULL THEN 0 ELSE 1 END AS BIT) AS PasswordImpostata,
        CONCAT(N''['',(SELECT STRING_AGG(CONVERT(NVARCHAR(MAX),ur.IdRuolo),N'','') FROM dbo.UtentiRuoli ur WHERE ur.IdUtente=u.IdUtente),N'']'') AS RuoliJson,
        (SELECT STRING_AGG(CONVERT(NVARCHAR(MAX),CONCAT(r.CodiceRuolo,CASE WHEN r.Attivo=0 THEN N'' (non attivo)'' ELSE N'''' END)),N'', '')
         FROM dbo.UtentiRuoli ur JOIN dbo.RuoliApplicazione r ON r.IdRuolo=ur.IdRuolo WHERE ur.IdUtente=u.IdUtente) AS Ruoli FROM dbo.UtentiApplicazione u
    WHERE (@Attivo IS NULL OR u.Attivo=@Attivo) AND (@Ricerca IS NULL OR u.Username LIKE N''%''+@Ricerca+N''%'' OR u.NomeCompleto LIKE N''%''+@Ricerca+N''%'')
    ORDER BY u.Username;
END;';
    EXEC sys.sp_executesql N'CREATE OR ALTER PROCEDURE dbo.Utenti_Gestione_Dettaglio @IdOperatore INT,@SessioneOperatore UNIQUEIDENTIFIER,@IdUtente INT
AS BEGIN SET NOCOUNT ON; EXEC dbo.Utenti_Gestione_VerificaAdmin @IdOperatore,@SessioneOperatore; SELECT u.IdUtente,u.Username,u.NomeCompleto,u.Attivo,u.DataCreazione,u.DataModifica,u.VersioneRiga,
        CAST(CASE WHEN NULLIF(u.PasswordHash,N'''') IS NULL THEN 0 ELSE 1 END AS BIT) AS PasswordImpostata,
        CONCAT(N''['',(SELECT STRING_AGG(CONVERT(NVARCHAR(MAX),ur.IdRuolo),N'','') FROM dbo.UtentiRuoli ur WHERE ur.IdUtente=u.IdUtente),N'']'') AS RuoliJson,
        (SELECT STRING_AGG(CONVERT(NVARCHAR(MAX),CONCAT(r.CodiceRuolo,CASE WHEN r.Attivo=0 THEN N'' (non attivo)'' ELSE N'''' END)),N'', '')
         FROM dbo.UtentiRuoli ur JOIN dbo.RuoliApplicazione r ON r.IdRuolo=ur.IdRuolo WHERE ur.IdUtente=u.IdUtente) AS Ruoli FROM dbo.UtentiApplicazione u WHERE u.IdUtente=@IdUtente; END;';
    EXEC sys.sp_executesql N'CREATE OR ALTER PROCEDURE dbo.Utenti_Gestione_Ruoli @IdOperatore INT,@SessioneOperatore UNIQUEIDENTIFIER
AS BEGIN SET NOCOUNT ON; EXEC dbo.Utenti_Gestione_VerificaAdmin @IdOperatore,@SessioneOperatore; SELECT IdRuolo,CodiceRuolo,Descrizione,Attivo FROM dbo.RuoliApplicazione ORDER BY CodiceRuolo; END;';
    EXEC sys.sp_executesql N'CREATE OR ALTER PROCEDURE dbo.Utenti_Gestione_Audit @IdOperatore INT,@SessioneOperatore UNIQUEIDENTIFIER,@IdUtente INT
AS BEGIN SET NOCOUNT ON; EXEC dbo.Utenti_Gestione_VerificaAdmin @IdOperatore,@SessioneOperatore;
    SELECT TOP(50) DataOperazione,Operazione,Operatore,PrimaJson,DopoJson FROM dbo.UtentiGestioneAudit WHERE IdUtente=@IdUtente ORDER BY IdAudit DESC;
END;';
    EXEC sys.sp_executesql N'CREATE OR ALTER PROCEDURE dbo.Utenti_Gestione_Salva @IdOperatore INT,@SessioneOperatore UNIQUEIDENTIFIER,@IdUtente INT=NULL,
    @Username NVARCHAR(50),@NomeCompleto NVARCHAR(150)=NULL,@Attivo BIT,@RuoliJson NVARCHAR(MAX),
    @VersioneRiga BINARY(8)=NULL,@PasswordHash NVARCHAR(255)=NULL
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    SET @Username=NULLIF(LTRIM(RTRIM(@Username)),N'''');
    IF @Username IS NULL OR @Attivo IS NULL OR ISJSON(@RuoliJson)<>1 OR LEFT(LTRIM(@RuoliJson),1)<>N''[''
        THROW 54301,''Dati utente non validi.'',1;
    IF EXISTS(SELECT 1 FROM OPENJSON(@RuoliJson) WHERE type<>2 OR TRY_CONVERT(INT,value) IS NULL)
        THROW 54301,''Ruoli non validi.'',1;
    DECLARE @Ruoli TABLE(IdRuolo INT PRIMARY KEY);
    INSERT @Ruoli SELECT DISTINCT CONVERT(INT,value) FROM OPENJSON(@RuoliJson);
    IF NOT EXISTS(SELECT 1 FROM @Ruoli) THROW 54301,''Selezionare almeno un ruolo.'',1;
    BEGIN TRY
        BEGIN TRANSACTION;
        DECLARE @Lock INT;
        EXEC @Lock=sys.sp_getapplock @Resource=N''TEC019-Utenti'',@LockMode=''Exclusive'',@LockOwner=''Transaction'',@LockTimeout=10000;
        IF @Lock<0 THROW 54304,''Altra modifica utenti in corso. Riprovare.'',1;
        EXEC dbo.Utenti_Gestione_VerificaAdmin @IdOperatore,@SessioneOperatore;
        DECLARE @Operatore NVARCHAR(50)=(SELECT Username FROM dbo.UtentiApplicazione WHERE IdUtente=@IdOperatore);
        DECLARE @Prima NVARCHAR(MAX),@Dopo NVARCHAR(MAX),@Operazione NVARCHAR(30)=N''Creazione'',@AttivoPrima BIT,@RuoliCambiati BIT=0;
        IF @IdUtente IS NOT NULL
        BEGIN
            SELECT @AttivoPrima=Attivo FROM dbo.UtentiApplicazione WITH(UPDLOCK,HOLDLOCK) WHERE IdUtente=@IdUtente;
            IF @AttivoPrima IS NULL THROW 54303,''Utente non trovato.'',1;
            IF NOT EXISTS(SELECT 1 FROM dbo.UtentiApplicazione WHERE IdUtente=@IdUtente AND VersioneRiga=@VersioneRiga)
                THROW 54304,''Utente modificato da altro amministratore.'',1;
            IF NOT EXISTS(SELECT 1 FROM dbo.UtentiApplicazione WHERE IdUtente=@IdUtente AND Username=@Username) OR @PasswordHash IS NOT NULL
                THROW 54301,''Username non modificabile. Usare la funzione reset per la password.'',1;
            IF @IdUtente=@IdOperatore AND @Attivo=0 THROW 54306,''Non disattivare il proprio account.'',1;
            IF EXISTS(SELECT IdRuolo FROM @Ruoli EXCEPT SELECT IdRuolo FROM dbo.UtentiRuoli WHERE IdUtente=@IdUtente)
                OR EXISTS(SELECT IdRuolo FROM dbo.UtentiRuoli WHERE IdUtente=@IdUtente EXCEPT SELECT IdRuolo FROM @Ruoli)
                SET @RuoliCambiati=1;
            SET @Prima=(SELECT u.IdUtente,u.Username,u.NomeCompleto,u.Attivo,
        JSON_QUERY(CONCAT(N''['',(SELECT STRING_AGG(CONVERT(NVARCHAR(MAX),ur.IdRuolo),N'','') FROM dbo.UtentiRuoli ur WHERE ur.IdUtente=u.IdUtente),N'']'')) AS Ruoli
        FROM dbo.UtentiApplicazione u WHERE u.IdUtente=@IdUtente FOR JSON PATH,WITHOUT_ARRAY_WRAPPER,INCLUDE_NULL_VALUES);
            SET @Operazione=CASE WHEN @AttivoPrima<>@Attivo THEN CASE WHEN @Attivo=1 THEN N''Riattivazione'' ELSE N''Disattivazione'' END ELSE N''Modifica'' END;
        END;
        IF EXISTS(SELECT 1 FROM @Ruoli x WHERE NOT EXISTS(SELECT 1 FROM dbo.RuoliApplicazione r WITH(HOLDLOCK)
            WHERE r.IdRuolo=x.IdRuolo AND (r.Attivo=1 OR EXISTS(SELECT 1 FROM dbo.UtentiRuoli ur WHERE ur.IdUtente=@IdUtente AND ur.IdRuolo=r.IdRuolo))))
            THROW 54305,''Selezionare ruoli attivi. I ruoli non attivi gia assegnati possono essere conservati.'',1;
        IF @IdUtente IS NOT NULL AND EXISTS(SELECT 1 FROM dbo.UtentiApplicazione u JOIN dbo.UtentiRuoli ur ON ur.IdUtente=u.IdUtente
            JOIN dbo.RuoliApplicazione r ON r.IdRuolo=ur.IdRuolo WHERE u.IdUtente=@IdUtente AND u.Attivo=1 AND r.Attivo=1 AND r.CodiceRuolo=N''ADMIN'')
          AND (@Attivo=0 OR NOT EXISTS(SELECT 1 FROM @Ruoli x JOIN dbo.RuoliApplicazione r ON r.IdRuolo=x.IdRuolo WHERE r.Attivo=1 AND r.CodiceRuolo=N''ADMIN''))
          AND NOT EXISTS(SELECT 1 FROM dbo.UtentiApplicazione u WITH(UPDLOCK,HOLDLOCK) JOIN dbo.UtentiRuoli ur ON ur.IdUtente=u.IdUtente
            JOIN dbo.RuoliApplicazione r ON r.IdRuolo=ur.IdRuolo WHERE u.IdUtente<>@IdUtente AND u.Attivo=1 AND NULLIF(u.PasswordHash,N'''') IS NOT NULL AND r.Attivo=1 AND r.CodiceRuolo=N''ADMIN'')
            THROW 54307,''Deve rimanere almeno un amministratore attivo.'',1;
        IF @IdUtente IS NULL
        BEGIN
            IF NULLIF(@PasswordHash,N'''') IS NULL THROW 54309,''Impostare la password iniziale.'',1;
            IF EXISTS(SELECT 1 FROM dbo.UtentiApplicazione WITH(UPDLOCK,HOLDLOCK) WHERE Username=@Username)
                THROW 54302,''Username gia utilizzato.'',1;
            INSERT dbo.UtentiApplicazione(Username,NomeCompleto,PasswordHash,Attivo) VALUES(@Username,@NomeCompleto,@PasswordHash,@Attivo);
            SET @IdUtente=CONVERT(INT,SCOPE_IDENTITY());
        END
        ELSE
        BEGIN
            IF @Attivo=1 AND EXISTS(SELECT 1 FROM dbo.UtentiApplicazione WHERE IdUtente=@IdUtente AND NULLIF(PasswordHash,N'''') IS NULL)
                THROW 54309,''Impostare una password prima di attivare l utente.'',1;
            UPDATE dbo.UtentiApplicazione SET NomeCompleto=@NomeCompleto,Attivo=@Attivo,DataModifica=SYSDATETIME(),UtenteModifica=@Operatore,
                VersioneSessione=CASE WHEN @AttivoPrima<>@Attivo OR @RuoliCambiati=1 THEN NEWID() ELSE VersioneSessione END WHERE IdUtente=@IdUtente;
        END;
        DELETE dbo.UtentiRuoli WHERE IdUtente=@IdUtente;
        INSERT dbo.UtentiRuoli(IdUtente,IdRuolo) SELECT @IdUtente,IdRuolo FROM @Ruoli;
        SET @Dopo=(SELECT u.IdUtente,u.Username,u.NomeCompleto,u.Attivo,
        JSON_QUERY(CONCAT(N''['',(SELECT STRING_AGG(CONVERT(NVARCHAR(MAX),ur.IdRuolo),N'','') FROM dbo.UtentiRuoli ur WHERE ur.IdUtente=u.IdUtente),N'']'')) AS Ruoli
        FROM dbo.UtentiApplicazione u WHERE u.IdUtente=@IdUtente FOR JSON PATH,WITHOUT_ARRAY_WRAPPER,INCLUDE_NULL_VALUES);
        INSERT dbo.UtentiGestioneAudit(IdUtente,IdOperatore,Operatore,Operazione,PrimaJson,DopoJson)
            VALUES(@IdUtente,@IdOperatore,@Operatore,@Operazione,@Prima,@Dopo);
        COMMIT TRANSACTION;
        SELECT @IdUtente;
    END TRY
    BEGIN CATCH
        IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;';
    EXEC sys.sp_executesql N'CREATE OR ALTER PROCEDURE dbo.Utenti_Gestione_Password @IdOperatore INT,@SessioneOperatore UNIQUEIDENTIFIER,@IdUtente INT,@VersioneRiga BINARY(8),@PasswordHash NVARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    IF NULLIF(@PasswordHash,N'''') IS NULL THROW 54309,''Password mancante.'',1;
    BEGIN TRY
        BEGIN TRANSACTION;
        DECLARE @Lock INT;
        EXEC @Lock=sys.sp_getapplock @Resource=N''TEC019-Utenti'',@LockMode=''Exclusive'',@LockOwner=''Transaction'',@LockTimeout=10000;
        IF @Lock<0 THROW 54304,''Altra modifica utenti in corso. Riprovare.'',1;
        EXEC dbo.Utenti_Gestione_VerificaAdmin @IdOperatore,@SessioneOperatore;
        IF NOT EXISTS(SELECT 1 FROM dbo.UtentiApplicazione WITH(UPDLOCK,HOLDLOCK) WHERE IdUtente=@IdUtente)
            THROW 54303,''Utente non trovato.'',1;
        IF NOT EXISTS(SELECT 1 FROM dbo.UtentiApplicazione WHERE IdUtente=@IdUtente AND VersioneRiga=@VersioneRiga)
            THROW 54304,''Utente modificato da altro amministratore.'',1;
        DECLARE @Operatore NVARCHAR(50)=(SELECT Username FROM dbo.UtentiApplicazione WHERE IdUtente=@IdOperatore);
        UPDATE dbo.UtentiApplicazione SET PasswordHash=@PasswordHash,VersioneSessione=NEWID(),DataModifica=SYSDATETIME(),UtenteModifica=@Operatore WHERE IdUtente=@IdUtente;
        INSERT dbo.UtentiGestioneAudit(IdUtente,IdOperatore,Operatore,Operazione) VALUES(@IdUtente,@IdOperatore,@Operatore,N''Reset password'');
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;';
/* PAYLOAD TEC-019-UTENTI END */

    INSERT dbo.VersioniSchema(Versione,CodiceIntervento,NomeScript,Descrizione,ImprontaSha256)
    VALUES(@Versione,@Codice,@Script,N'Gestione utenti ADMIN, ruoli esistenti, password, audit, concorrenza e revoca sessioni.',@Impronta);
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
