CREATE OR ALTER PROCEDURE dbo.Allegati_Disattiva
(
    @IdAllegato INT
)
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.Allegati
       SET Attivo = 0
     WHERE IdAllegato = @IdAllegato;
END
GO