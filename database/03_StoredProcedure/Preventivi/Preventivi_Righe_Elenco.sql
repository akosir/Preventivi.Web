USE PreventiviProduzione;
GO

CREATE OR ALTER PROCEDURE dbo.Preventivi_Righe_Elenco
    @IdPreventivo INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        r.IdRigaPreventivo,
        r.RigaNr,
        r.IdTipoRiga,
        ISNULL(t.Descrizione, '') AS TipoRiga,
        r.DescrizioneVoce,
        r.Quantita,
        r.TotaleCosti,
        r.PrezzoUnitarioVendita,
        r.TotaleVendita,
        r.MargineValore,
        r.MarginePerc,
        r.PrezzoManuale
    FROM dbo.PreventiviRighe AS r
    INNER JOIN dbo.TipiRigaPreventivo AS t
        ON t.IdTipoRiga = r.IdTipoRiga
    WHERE r.IdPreventivo = @IdPreventivo
    ORDER BY
        r.RigaNr,
        r.IdRigaPreventivo;
END;
GO