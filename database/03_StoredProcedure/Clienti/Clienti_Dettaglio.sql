CREATE OR ALTER PROCEDURE dbo.Clienti_Dettaglio
(
    @IdCliente INT
)
AS
BEGIN

    SET NOCOUNT ON;

    SELECT
        IdCliente,
        CodiceCliente,
        RagioneSociale,
        PartitaIVA,
        CodiceFiscale,
        Indirizzo,
        CAP,
        Citta,
        Provincia,
        Telefono,
        Email,
        Attivo
    FROM dbo.Clienti
    WHERE IdCliente = @IdCliente;

END
GO