CREATE OR ALTER PROCEDURE dbo.Preventivi_Elenco
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        p.IdPreventivo,
        p.NumeroPreventivo,
        p.Anno,
        p.DataPreventivo,
        ISNULL(c.RagioneSociale, '') AS Cliente,
        ISNULL(p.Oggetto, '') AS Oggetto,
        p.TotaleVendita,
        p.Stato
    FROM dbo.Preventivi AS p
    LEFT JOIN dbo.Clienti AS c
        ON c.IdCliente = p.IdCliente
    ORDER BY
        p.Anno DESC,
        p.NumeroPreventivo DESC;
END;
GO