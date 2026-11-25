-- Integrazione approvata alla decisione 170. Applicazione esplicita del markup alle righe.
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
    DECLARE @Versione INT = 2026112501;
    DECLARE @Codice NVARCHAR(50) = N'TEC-009-MARKUP';
    DECLARE @Script NVARCHAR(260) = N'TEC-009_09_Markup_Righe_Esistenti.sql';
    DECLARE @Impronta CHAR(64) = '9501DC60546AF00ED257C9D7DFEAA9ECB7B851DFD8D512B7083576A3171FC5E0';
    IF NOT EXISTS (SELECT 1 FROM dbo.VersioniSchema WITH (UPDLOCK, HOLDLOCK)
                   WHERE Versione = 2026112402 AND CodiceIntervento = N'TEC-018-GENERAZIONE')
        THROW 53896, 'Versione prerequisito 2026112402 non installata.', 1;
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

/* PAYLOAD TEC-009-MARKUP START */
    EXEC sys.sp_executesql N'CREATE OR ALTER PROCEDURE dbo.Preventivi_Markup_Impronta
    @IdPreventivo INT, @Impronta VARCHAR(64) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    -- Le chiamanti mantengono la transazione per tutta l''anteprima o applicazione.
    DECLARE @Testata NVARCHAR(MAX)=(SELECT p.* FROM dbo.Preventivi p WITH(HOLDLOCK)
        WHERE p.IdPreventivo=@IdPreventivo FOR JSON PATH,INCLUDE_NULL_VALUES);
    DECLARE @Righe NVARCHAR(MAX)=(SELECT r.* FROM dbo.PreventiviRighe r WITH(HOLDLOCK)
        WHERE r.IdPreventivo=@IdPreventivo ORDER BY r.IdRigaPreventivo FOR JSON PATH,INCLUDE_NULL_VALUES);
    DECLARE @Materiali NVARCHAR(MAX)=(SELECT m.* FROM dbo.PreventiviRigheMateriali m WITH(HOLDLOCK)
        JOIN dbo.PreventiviRighe r ON r.IdRigaPreventivo=m.IdRigaPreventivo
        WHERE r.IdPreventivo=@IdPreventivo ORDER BY m.IdRigaMatPrev FOR JSON PATH,INCLUDE_NULL_VALUES);
    DECLARE @Lavorazioni NVARCHAR(MAX)=(SELECT l.* FROM dbo.PreventiviRigheLavorazioni l WITH(HOLDLOCK)
        JOIN dbo.PreventiviRighe r ON r.IdRigaPreventivo=l.IdRigaPreventivo
        WHERE r.IdPreventivo=@IdPreventivo ORDER BY l.IdRigaLavPrev FOR JSON PATH,INCLUDE_NULL_VALUES);
    DECLARE @Varianti NVARCHAR(MAX)=(SELECT v.* FROM dbo.PreventiviVarianti v WITH(HOLDLOCK)
        WHERE v.IdPreventivo=@IdPreventivo ORDER BY v.IdVariantePreventivo FOR JSON PATH,INCLUDE_NULL_VALUES);
    SET @Impronta=CONVERT(VARCHAR(64),HASHBYTES(''SHA2_256'',CONCAT(@Testata,N''|'',@Righe,N''|'',@Materiali,N''|'',@Lavorazioni,N''|'',@Varianti)),2);
END;';
    EXEC sys.sp_executesql N'CREATE OR ALTER PROCEDURE dbo.Preventivi_Markup_Anteprima @IdPreventivo INT
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        DECLARE @Impronta VARCHAR(64);
        EXEC dbo.Preventivi_Markup_Impronta @IdPreventivo,@Impronta OUTPUT;
        SELECT p.IdPreventivo,p.Stato,p.MarkupPercDefault,@Impronta AS Impronta,
            r.IdRigaPreventivo,r.RigaNr,r.DescrizioneVoce,v.CodiceVariante,
            r.PrezzoManuale,r.MarkupPerc,r.TotaleCosti,r.TotaleVendita
        FROM dbo.Preventivi p LEFT JOIN dbo.PreventiviRighe r ON r.IdPreventivo=p.IdPreventivo
        LEFT JOIN dbo.PreventiviVarianti v ON v.IdVariantePreventivo=r.IdVariantePreventivo
        WHERE p.IdPreventivo=@IdPreventivo ORDER BY r.RigaNr,r.IdRigaPreventivo;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;';
    EXEC sys.sp_executesql N'CREATE OR ALTER PROCEDURE dbo.Preventivi_Markup_Applica
    @IdPreventivo INT,@Markup DECIMAL(9,2),@Impronta VARCHAR(64)
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    IF @Markup IS NULL OR @Markup<0 THROW 54204,''Markup non valido.'',1;
    BEGIN TRY
        BEGIN TRANSACTION;
        DECLARE @Stato NVARCHAR(30);
        SELECT @Stato=Stato FROM dbo.Preventivi WITH(UPDLOCK,HOLDLOCK) WHERE IdPreventivo=@IdPreventivo;
        IF @Stato IS NULL THROW 54201,''Preventivo non trovato.'',1;
        IF @Stato NOT IN(N''Bozza'',N''Da Verificare'',N''Pronto da Inviare'')
            THROW 54202,''Lo stato del preventivo non consente aggiornamenti del markup.'',1;
        DECLARE @Blocco INT;
        SELECT @Blocco=r.IdRigaPreventivo FROM dbo.PreventiviRighe r WITH(UPDLOCK,HOLDLOCK) WHERE r.IdPreventivo=@IdPreventivo;
        SELECT @Blocco=m.IdRigaMatPrev FROM dbo.PreventiviRigheMateriali m WITH(UPDLOCK,HOLDLOCK)
            JOIN dbo.PreventiviRighe r ON r.IdRigaPreventivo=m.IdRigaPreventivo WHERE r.IdPreventivo=@IdPreventivo;
        SELECT @Blocco=l.IdRigaLavPrev FROM dbo.PreventiviRigheLavorazioni l WITH(UPDLOCK,HOLDLOCK)
            JOIN dbo.PreventiviRighe r ON r.IdRigaPreventivo=l.IdRigaPreventivo WHERE r.IdPreventivo=@IdPreventivo;
        SELECT @Blocco=v.IdVariantePreventivo FROM dbo.PreventiviVarianti v WITH(UPDLOCK,HOLDLOCK) WHERE v.IdPreventivo=@IdPreventivo;
        DECLARE @Attuale VARCHAR(64);
        EXEC dbo.Preventivi_Markup_Impronta @IdPreventivo,@Attuale OUTPUT;
        IF @Impronta IS NULL OR LEN(@Impronta)<>64 OR @Impronta<>@Attuale
            THROW 54203,''Preventivo modificato dopo l anteprima.'',1;
        UPDATE dbo.Preventivi SET MarkupPercDefault=@Markup,DataModifica=SYSDATETIME() WHERE IdPreventivo=@IdPreventivo;
        UPDATE dbo.PreventiviRighe SET MarkupPerc=@Markup,DataModifica=SYSDATETIME()
            WHERE IdPreventivo=@IdPreventivo AND PrezzoManuale=0;
        -- Il ricalcolo TEC-009 conserva il prezzo unitario quando PrezzoManuale=1.
        DECLARE @IdRiga INT;
        DECLARE righe CURSOR LOCAL FAST_FORWARD FOR
            SELECT IdRigaPreventivo FROM dbo.PreventiviRighe WHERE IdPreventivo=@IdPreventivo ORDER BY IdRigaPreventivo;
        OPEN righe; FETCH NEXT FROM righe INTO @IdRiga;
        WHILE @@FETCH_STATUS=0
        BEGIN
            EXEC dbo.sp_RicalcolaTotaliRigaPreventivo @IdRigaPreventivo=@IdRiga;
            FETCH NEXT FROM righe INTO @IdRiga;
        END;
        CLOSE righe; DEALLOCATE righe;
        DECLARE @IdVariante INT;
        DECLARE varianti CURSOR LOCAL FAST_FORWARD FOR
            SELECT IdVariantePreventivo FROM dbo.PreventiviVarianti WHERE IdPreventivo=@IdPreventivo ORDER BY IdVariantePreventivo;
        OPEN varianti; FETCH NEXT FROM varianti INTO @IdVariante;
        WHILE @@FETCH_STATUS=0
        BEGIN
            EXEC dbo.sp_RicalcolaTotaliVariante @IdVariantePreventivo=@IdVariante;
            FETCH NEXT FROM varianti INTO @IdVariante;
        END;
        CLOSE varianti; DEALLOCATE varianti;
        EXEC dbo.sp_RicalcolaTotaliPreventivo @IdPreventivo=@IdPreventivo;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;';
/* PAYLOAD TEC-009-MARKUP END */

    INSERT dbo.VersioniSchema(Versione,CodiceIntervento,NomeScript,Descrizione,ImprontaSha256)
    VALUES(@Versione,@Codice,@Script,N'Applicazione esplicita del markup alle righe esistenti con conservazione dei prezzi manuali e ricalcolo atomico.',@Impronta);
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
