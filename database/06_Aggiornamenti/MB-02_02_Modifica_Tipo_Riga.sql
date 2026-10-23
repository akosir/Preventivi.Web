/*
    MB-02 - Modifica del tipo riga preventivo

    Consente alla pagina di modifica riga di aggiornare IdTipoRiga e applica
    la regola del costo unitario libero in base al nuovo tipo selezionato.

    Lo script non seleziona il database.
*/

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET NUMERIC_ROUNDABORT OFF;
GO

IF OBJECT_ID(N'dbo.PreventiviRighe', N'U') IS NULL
   OR OBJECT_ID(N'dbo.TipiRigaPreventivo', N'U') IS NULL
   OR OBJECT_ID(N'dbo.sp_RicalcolaQuantitaComponentiRiga', N'P') IS NULL
   OR OBJECT_ID(N'dbo.sp_RicalcolaTotaliRigaPreventivo', N'P') IS NULL
BEGIN
    THROW 52000, 'MB-02: schema richiesto non disponibile.', 1;
END;
GO

CREATE OR ALTER PROCEDURE dbo.Preventivi_Righe_Aggiorna
    @IdRigaPreventivo INT,
    @RigaNr INT,
    @DescrizioneVoce NVARCHAR(250),
    @Quantita DECIMAL(18,4),
    @PrezzoUnitarioVendita DECIMAL(18,4),
    @Note NVARCHAR(MAX) = NULL,
    @MarkupPerc DECIMAL(9,2),
    @PrezzoManuale BIT,
    @CostoUnitarioLibero DECIMAL(18,4) = NULL,
    @IdTipoRiga INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @RigaLibera BIT;

    IF NOT EXISTS
    (
        SELECT 1
        FROM dbo.PreventiviRighe
        WHERE IdRigaPreventivo = @IdRigaPreventivo
    )
        THROW 52004, 'Riga preventivo non trovata.', 1;

    SELECT @RigaLibera = RigaLibera
    FROM dbo.TipiRigaPreventivo
    WHERE IdTipoRiga = @IdTipoRiga
      AND Attiva = 1;

    IF @RigaLibera IS NULL
        THROW 52015, 'Tipo riga non trovato o non attivo.', 1;

    IF @RigaNr <= 0 OR @Quantita <= 0
        THROW 52005, 'Numero riga e quantita devono essere maggiori di zero.', 1;

    IF NULLIF(LTRIM(RTRIM(@DescrizioneVoce)), N'') IS NULL
        THROW 52006, 'La descrizione della riga e obbligatoria.', 1;

    IF @RigaLibera = 1 AND @CostoUnitarioLibero IS NULL
        THROW 52007, 'La riga libera richiede il costo unitario libero.', 1;

    IF @RigaLibera = 0
        SET @CostoUnitarioLibero = NULL;

    BEGIN TRY
        BEGIN TRANSACTION;

        UPDATE dbo.PreventiviRighe
        SET IdTipoRiga = @IdTipoRiga,
            RigaNr = @RigaNr,
            DescrizioneVoce = LTRIM(RTRIM(@DescrizioneVoce)),
            Quantita = @Quantita,
            PrezzoUnitarioVendita = @PrezzoUnitarioVendita,
            Note = NULLIF(LTRIM(RTRIM(@Note)), N''),
            MarkupPerc = @MarkupPerc,
            PrezzoManuale = @PrezzoManuale,
            CostoUnitarioLibero = @CostoUnitarioLibero,
            DataModifica = SYSDATETIME()
        WHERE IdRigaPreventivo = @IdRigaPreventivo;

        EXEC dbo.sp_RicalcolaQuantitaComponentiRiga
            @IdRigaPreventivo = @IdRigaPreventivo;

        EXEC dbo.sp_RicalcolaTotaliRigaPreventivo
            @IdRigaPreventivo = @IdRigaPreventivo;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH;
END;
GO
