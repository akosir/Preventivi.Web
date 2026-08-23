CREATE OR ALTER PROCEDURE dbo.Clienti_Disattiva
(
    @IdCliente INT
)
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.Clienti
       SET Attivo = 0,
           DataModifica = SYSDATETIME()
     WHERE IdCliente = @IdCliente;
END
GO