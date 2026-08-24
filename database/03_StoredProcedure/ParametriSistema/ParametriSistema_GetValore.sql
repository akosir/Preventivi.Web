CREATE OR ALTER PROCEDURE dbo.ParametriSistema_GetValore
(
    @Chiave NVARCHAR(100)
)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT Valore
    FROM dbo.ParametriSistema
    WHERE Chiave = @Chiave;
END
GO