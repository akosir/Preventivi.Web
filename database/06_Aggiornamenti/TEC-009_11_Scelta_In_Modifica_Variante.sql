-- Scelta della variante nella modifica, con salvataggio e ricalcolo atomici.
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
    DECLARE @Versione INT = 2026112503;
    DECLARE @Codice NVARCHAR(50) = N'TEC-009-VARIANTI-SCELTA';
    DECLARE @Script NVARCHAR(260) = N'TEC-009_11_Scelta_In_Modifica_Variante.sql';
    DECLARE @Impronta CHAR(64) = '06670878448765D06D6B00ECE4F384B7573E7DB908DF4E0F3668A1AAFCBD3310';
    IF NOT EXISTS (SELECT 1 FROM dbo.VersioniSchema WITH (UPDLOCK, HOLDLOCK)
                   WHERE Versione = 2026112502 AND CodiceIntervento = N'TEC-009-VARIANTI-MODIFICA')
        THROW 53896, 'Versione prerequisito 2026112502 non installata.', 1;
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

/* PAYLOAD TEC-009-VARIANTI-SCELTA START */
    EXEC sys.sp_executesql N'CREATE OR ALTER PROCEDURE dbo.Preventivi_Varianti_Aggiorna
    @IdPreventivo INT,@IdVariantePreventivo INT,@Codice NVARCHAR(30),@Descrizione NVARCHAR(250),
    @Note NVARCHAR(MAX)=NULL,@Impronta VARCHAR(64),@VarianteScelta BIT
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    IF @VarianteScelta IS NULL THROW 54214,''Indicare la scelta della variante.'',1;
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
        IF @VarianteScelta=1
        BEGIN
            -- Liberare la scelta precedente prima di impostare la nuova rispetta l''indice filtrato.
            UPDATE dbo.PreventiviVarianti SET VarianteScelta=0,DataModifica=SYSDATETIME()
                WHERE IdPreventivo=@IdPreventivo AND Attiva=1 AND VarianteScelta=1
                    AND IdVariantePreventivo<>@IdVariantePreventivo;
            EXEC dbo.Preventivi_Varianti_Seleziona @IdVariantePreventivo=@IdVariantePreventivo;
        END
        ELSE
        BEGIN
            -- Deselezionare questa variante non cancella la scelta di un''altra variante.
            UPDATE dbo.PreventiviVarianti SET VarianteScelta=0,DataModifica=SYSDATETIME()
                WHERE IdVariantePreventivo=@IdVariantePreventivo;
            EXEC dbo.sp_RicalcolaTotaliVariante @IdVariantePreventivo=@IdVariantePreventivo;
            EXEC dbo.sp_RicalcolaTotaliPreventivo @IdPreventivo=@IdPreventivo;
        END;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;';
/* PAYLOAD TEC-009-VARIANTI-SCELTA END */

    INSERT dbo.VersioniSchema(Versione,CodiceIntervento,NomeScript,Descrizione,ImprontaSha256)
    VALUES(@Versione,@Codice,@Script,N'Scelta variante nella modifica e ricalcolo atomico del preventivo.',@Impronta);
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
