CREATE OR ALTER PROCEDURE dbo.TipiAllegato_Elenco
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        CodiceTipo,
        Descrizione
    FROM dbo.TipiAllegato
    WHERE Attivo = 1
    ORDER BY Descrizione;
END
GO