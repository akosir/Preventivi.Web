CREATE OR ALTER PROCEDURE dbo.Allegati_Elenco
(
    @Entita NVARCHAR(50),
    @IdEntita INT
)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        IdAllegato,
        TipoAllegato,
        Descrizione,
        NomeFileOriginale,
        Estensione,
        DataAllegato,
        UtenteInserimento,
        Note
    FROM dbo.Allegati
    WHERE Entita = @Entita
      AND IdEntita = @IdEntita
    ORDER BY
        DataAllegato DESC,
        NomeFileOriginale;
END
GO