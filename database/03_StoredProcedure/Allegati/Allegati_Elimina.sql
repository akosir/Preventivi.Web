CREATE OR ALTER PROCEDURE dbo.Allegati_Elimina
(
    @IdAllegato INT
)
AS
BEGIN
    SET NOCOUNT ON;

    DELETE FROM dbo.Allegati
    WHERE IdAllegato = @IdAllegato;
END
GO