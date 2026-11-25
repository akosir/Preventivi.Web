-- Completamento modifica e accesso alle righe delle varianti preventivo.
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
    DECLARE @Versione INT = 2026112502;
    DECLARE @Codice NVARCHAR(50) = N'TEC-009-VARIANTI-MODIFICA';
    DECLARE @Script NVARCHAR(260) = N'TEC-009_10_Modifica_Varianti.sql';
    DECLARE @Impronta CHAR(64) = 'B91837B600D68B58258D8B9131C47E1AC33538CF57F6E3644E41E22AEA5D086F';
    IF NOT EXISTS (SELECT 1 FROM dbo.VersioniSchema WITH (UPDLOCK, HOLDLOCK)
                   WHERE Versione = 2026112501 AND CodiceIntervento = N'TEC-009-MARKUP')
        THROW 53896, 'Versione prerequisito 2026112501 non installata.', 1;
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

/* PAYLOAD TEC-009-VARIANTI-MODIFICA START */
    EXEC sys.sp_executesql N'CREATE OR ALTER PROCEDURE dbo.Preventivi_Varianti_Dettaglio @IdVariantePreventivo INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT v.*,CONVERT(VARCHAR(64),HASHBYTES(''SHA2_256'',
        (SELECT v.* FOR JSON PATH,INCLUDE_NULL_VALUES,WITHOUT_ARRAY_WRAPPER)),2) AS Impronta
    FROM dbo.PreventiviVarianti v WHERE v.IdVariantePreventivo=@IdVariantePreventivo;
END;';
    EXEC sys.sp_executesql N'CREATE OR ALTER PROCEDURE dbo.Preventivi_Varianti_Righe @IdPreventivo INT,@IdVariantePreventivo INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT r.*,ISNULL(t.Descrizione,N'''') AS TipoRiga FROM dbo.PreventiviRighe r
    JOIN dbo.PreventiviVarianti v ON v.IdVariantePreventivo=r.IdVariantePreventivo AND v.IdPreventivo=r.IdPreventivo
    JOIN dbo.TipiRigaPreventivo t ON t.IdTipoRiga=r.IdTipoRiga
    WHERE r.IdPreventivo=@IdPreventivo AND v.IdVariantePreventivo=@IdVariantePreventivo ORDER BY r.RigaNr,r.IdRigaPreventivo;
END;';
    EXEC sys.sp_executesql N'CREATE OR ALTER PROCEDURE dbo.Preventivi_Varianti_Aggiorna
    @IdPreventivo INT,@IdVariantePreventivo INT,@Codice NVARCHAR(30),@Descrizione NVARCHAR(250),
    @Note NVARCHAR(MAX)=NULL,@Impronta VARCHAR(64)
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    IF NULLIF(LTRIM(RTRIM(@Codice)),N'''') IS NULL OR NULLIF(LTRIM(RTRIM(@Descrizione)),N'''') IS NULL
        THROW 54214,''Compilare codice e descrizione variante.'',1;
    BEGIN TRY
        BEGIN TRANSACTION;
        DECLARE @Stato NVARCHAR(30),@Attuale VARCHAR(64),@Attiva BIT;
        SELECT @Stato=Stato FROM dbo.Preventivi WITH(UPDLOCK,HOLDLOCK) WHERE IdPreventivo=@IdPreventivo;
        IF @Stato IS NULL THROW 54211,''Preventivo non trovato.'',1;
        IF @Stato NOT IN(N''Bozza'',N''Da Verificare'',N''Pronto da Inviare'') THROW 54212,''Preventivo non modificabile.'',1;
        SELECT @Attiva=v.Attiva,@Attuale=CONVERT(VARCHAR(64),HASHBYTES(''SHA2_256'',
            (SELECT v.* FOR JSON PATH,INCLUDE_NULL_VALUES,WITHOUT_ARRAY_WRAPPER)),2)
        FROM dbo.PreventiviVarianti v WITH(UPDLOCK,HOLDLOCK)
        WHERE v.IdVariantePreventivo=@IdVariantePreventivo AND v.IdPreventivo=@IdPreventivo;
        IF @Attiva IS NULL THROW 54211,''Variante non appartenente al preventivo.'',1;
        IF @Attiva=0 THROW 54212,''Variante non attiva.'',1;
        IF @Impronta IS NULL OR LEN(@Impronta)<>64 OR @Impronta<>@Attuale THROW 54213,''Variante modificata da altro utente.'',1;
        IF EXISTS(SELECT 1 FROM dbo.PreventiviVarianti WITH(UPDLOCK,HOLDLOCK) WHERE IdPreventivo=@IdPreventivo
            AND CodiceVariante=LTRIM(RTRIM(@Codice)) AND IdVariantePreventivo<>@IdVariantePreventivo)
            THROW 54215,''Codice variante gia utilizzato.'',1;
        UPDATE dbo.PreventiviVarianti SET CodiceVariante=LTRIM(RTRIM(@Codice)),DescrizioneVariante=LTRIM(RTRIM(@Descrizione)),
            Note=NULLIF(LTRIM(RTRIM(@Note)),N''''),DataModifica=SYSDATETIME() WHERE IdVariantePreventivo=@IdVariantePreventivo;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;';
    EXEC sys.sp_executesql N'CREATE OR ALTER PROCEDURE dbo.Preventivi_Varianti_Righe_Crea
    @IdPreventivo INT,@RigaNr INT=NULL,@IdArticolo INT=NULL,@IdModelloCiclo INT=NULL,
    @DescrizioneVoce NVARCHAR(500),@Quantita DECIMAL(18,4),@PrezzoUnitarioVendita DECIMAL(18,4),
    @Note NVARCHAR(MAX)=NULL,@MarkupPerc DECIMAL(9,2),@PrezzoManuale BIT,
    @IdVariantePreventivo INT,@CostoUnitarioLibero DECIMAL(18,4)=NULL,@IdTipoRiga INT
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        DECLARE @Stato NVARCHAR(30);
        SELECT @Stato=Stato FROM dbo.Preventivi WITH(UPDLOCK,HOLDLOCK) WHERE IdPreventivo=@IdPreventivo;
        IF @Stato IS NULL THROW 54211,''Preventivo non trovato.'',1;
        IF @Stato NOT IN(N''Bozza'',N''Da Verificare'',N''Pronto da Inviare'') THROW 54212,''Preventivo non modificabile.'',1;
        IF NOT EXISTS(SELECT 1 FROM dbo.PreventiviVarianti WITH(UPDLOCK,HOLDLOCK)
            WHERE IdVariantePreventivo=@IdVariantePreventivo AND IdPreventivo=@IdPreventivo AND Attiva=1)
            THROW 54211,''Variante non appartenente al preventivo o non attiva.'',1;
        EXEC dbo.Preventivi_Righe_Crea @IdPreventivo=@IdPreventivo,@RigaNr=@RigaNr,@IdArticolo=@IdArticolo,
            @IdModelloCiclo=@IdModelloCiclo,@DescrizioneVoce=@DescrizioneVoce,@Quantita=@Quantita,
            @PrezzoUnitarioVendita=@PrezzoUnitarioVendita,@Note=@Note,@MarkupPerc=@MarkupPerc,@PrezzoManuale=@PrezzoManuale,
            @IdVariantePreventivo=@IdVariantePreventivo,@CostoUnitarioLibero=@CostoUnitarioLibero,@IdTipoRiga=@IdTipoRiga;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;';
/* PAYLOAD TEC-009-VARIANTI-MODIFICA END */

    INSERT dbo.VersioniSchema(Versione,CodiceIntervento,NomeScript,Descrizione,ImprontaSha256)
    VALUES(@Versione,@Codice,@Script,N'Modifica controllata dei dati della variante e accesso alle relative righe.',@Impronta);
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
