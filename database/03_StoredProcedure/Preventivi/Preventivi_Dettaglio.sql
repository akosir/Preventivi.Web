USE PreventiviProduzione;
GO

CREATE OR ALTER PROCEDURE dbo.Preventivi_Dettaglio
    @IdPreventivo INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        p.IdPreventivo,
        p.NumeroPreventivo,
        p.Anno,
        p.DataPreventivo,
        p.IdCliente,
        ISNULL(c.RagioneSociale, '') AS Cliente,
        ISNULL(p.Oggetto, '') AS Oggetto,
        ISNULL(p.Note, '') AS Note,
        p.Stato,
        p.TotaleCosti,
        p.TotaleVendita,
        p.MargineValore,
        p.MarginePerc,
        p.MarkupPercDefault,
        p.IdRichiestaCliente
    FROM dbo.Preventivi AS p
    LEFT JOIN dbo.Clienti AS c
        ON c.IdCliente = p.IdCliente
    WHERE p.IdPreventivo = @IdPreventivo;
END;
GO