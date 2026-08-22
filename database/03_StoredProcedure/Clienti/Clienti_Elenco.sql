CREATE OR ALTER PROCEDURE dbo.Clienti_Elenco
    @Ricerca NVARCHAR(300) = NULL,
    @SoloAttivi BIT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        c.IdCliente,
        c.CodiceCliente,
        c.RagioneSociale,
        c.PartitaIVA,
        c.Citta,
        c.Telefono,
        c.Email,
        c.Attivo
    FROM dbo.Clienti AS c
    WHERE
        (
            @Ricerca IS NULL
            OR LTRIM(RTRIM(@Ricerca)) = ''
            OR c.CodiceCliente LIKE '%' + @Ricerca + '%'
            OR c.RagioneSociale LIKE '%' + @Ricerca + '%'
            OR c.PartitaIVA LIKE '%' + @Ricerca + '%'
        )
        AND
        (
            @SoloAttivi IS NULL
            OR c.Attivo = @SoloAttivi
        )
    ORDER BY
        c.RagioneSociale,
        c.CodiceCliente;
END;
GO