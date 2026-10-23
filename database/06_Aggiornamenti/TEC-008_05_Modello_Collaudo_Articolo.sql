/*
    TEC-008 - Modello controllato per collaudo creazione da modello

    Crea o riallinea il modello TEST-TEC008-ART con una sola riga articolo:
    - tipo riga ART;
    - articolo GAB.01.001;
    - nessun cliente predefinito.

    Non crea preventivi e non modifica modelli con altri codici.
    Lo script non seleziona il database.
*/

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET XACT_ABORT ON;
GO

IF OBJECT_ID(N'dbo.ModelliPreventivo', N'U') IS NULL
   OR OBJECT_ID(N'dbo.ModelliPreventivoRighe', N'U') IS NULL
   OR OBJECT_ID(N'dbo.TipiRigaPreventivo', N'U') IS NULL
   OR OBJECT_ID(N'dbo.Articoli', N'U') IS NULL
   OR COL_LENGTH(N'dbo.ModelliPreventivoRighe', N'IdTipoRiga') IS NULL
BEGIN
    THROW 51800, 'TEC-008: schema richiesto non disponibile.', 1;
END;
GO

DECLARE @CodiceModello NVARCHAR(50) = N'TEST-TEC008-ART';
DECLARE @CodiceTipoRiga NVARCHAR(20) = N'ART';
DECLARE @CodiceArticolo NVARCHAR(50) = N'GAB.01.001';
DECLARE @IdTipoRiga INT;
DECLARE @IdArticolo INT;
DECLARE @IdModelloPreventivo INT;

SELECT @IdTipoRiga = IdTipoRiga
FROM dbo.TipiRigaPreventivo
WHERE Codice = @CodiceTipoRiga
  AND Attiva = 1
  AND RigaArticolo = 1;

IF @IdTipoRiga IS NULL
    THROW 51820, 'Collaudo TEC-008: tipo riga ART non trovato, non attivo o non configurato come articolo.', 1;

SELECT @IdArticolo = IdArticolo
FROM dbo.Articoli
WHERE CodiceArticolo = @CodiceArticolo
  AND Attivo = 1;

IF @IdArticolo IS NULL
    THROW 51821, 'Collaudo TEC-008: articolo GAB.01.001 non trovato o non attivo.', 1;

BEGIN TRY
    BEGIN TRANSACTION;

    SELECT @IdModelloPreventivo = IdModelloPreventivo
    FROM dbo.ModelliPreventivo WITH (UPDLOCK, HOLDLOCK)
    WHERE CodiceModelloPreventivo = @CodiceModello;

    IF @IdModelloPreventivo IS NULL
    BEGIN
        INSERT INTO dbo.ModelliPreventivo
        (
            CodiceModelloPreventivo,
            Descrizione,
            IdCliente,
            Oggetto,
            Note,
            Attivo
        )
        VALUES
        (
            @CodiceModello,
            N'Collaudo TEC-008 - Riga articolo',
            NULL,
            N'Collaudo creazione da modello',
            N'Modello tecnico controllato per il collaudo TEC-008.',
            1
        );

        SET @IdModelloPreventivo = CONVERT(INT, SCOPE_IDENTITY());
    END;
    ELSE
    BEGIN
        UPDATE dbo.ModelliPreventivo
        SET Descrizione = N'Collaudo TEC-008 - Riga articolo',
            IdCliente = NULL,
            Oggetto = N'Collaudo creazione da modello',
            Note = N'Modello tecnico controllato per il collaudo TEC-008.',
            Attivo = 1,
            DataModifica = SYSDATETIME()
        WHERE IdModelloPreventivo = @IdModelloPreventivo;

        DELETE FROM dbo.ModelliPreventivoRighe
        WHERE IdModelloPreventivo = @IdModelloPreventivo;
    END;

    INSERT INTO dbo.ModelliPreventivoRighe
    (
        IdModelloPreventivo,
        RigaNr,
        IdArticolo,
        IdModelloCiclo,
        DescrizioneVoce,
        Quantita,
        PrezzoUnitarioVendita,
        Note,
        IdTipoRiga
    )
    VALUES
    (
        @IdModelloPreventivo,
        1,
        @IdArticolo,
        NULL,
        N'ESPOSITORE TEST',
        CONVERT(DECIMAL(18,4), 1),
        CONVERT(DECIMAL(18,4), 100),
        N'Riga controllata per collaudo TEC-008.',
        @IdTipoRiga
    );

    COMMIT TRANSACTION;

    SELECT
        modello.IdModelloPreventivo,
        modello.CodiceModelloPreventivo,
        modello.Descrizione,
        riga.RigaNr,
        tipo.Codice AS TipoRiga,
        articolo.CodiceArticolo,
        riga.DescrizioneVoce,
        riga.Quantita,
        riga.PrezzoUnitarioVendita
    FROM dbo.ModelliPreventivo AS modello
    INNER JOIN dbo.ModelliPreventivoRighe AS riga
        ON riga.IdModelloPreventivo = modello.IdModelloPreventivo
    INNER JOIN dbo.TipiRigaPreventivo AS tipo
        ON tipo.IdTipoRiga = riga.IdTipoRiga
    LEFT JOIN dbo.Articoli AS articolo
        ON articolo.IdArticolo = riga.IdArticolo
    WHERE modello.IdModelloPreventivo = @IdModelloPreventivo;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0
        ROLLBACK TRANSACTION;

    THROW;
END CATCH;
GO
