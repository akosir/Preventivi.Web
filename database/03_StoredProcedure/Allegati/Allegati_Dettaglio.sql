CREATE OR ALTER PROCEDURE dbo.Allegati_Dettaglio
(
    @IdAllegato INT
)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT *
    FROM dbo.Allegati
    WHERE IdAllegato = @IdAllegato;
END
GO