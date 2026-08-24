CREATE OR ALTER PROCEDURE dbo.Allegati_Crea
(
    @Entita              NVARCHAR(50),
    @IdEntita            INT,
    @TipoAllegato        NVARCHAR(50) = NULL,
    @Descrizione         NVARCHAR(250) = NULL,
    @NomeFileOriginale   NVARCHAR(255),
    @PercorsoFile        NVARCHAR(500),
    @Estensione          NVARCHAR(20) = NULL,
    @DataAllegato        DATE,
    @UtenteInserimento   NVARCHAR(100) = NULL,
    @Note                NVARCHAR(MAX) = NULL,
    @NomeFileArchiviato  NVARCHAR(255),
    @DimensioneFile      BIGINT = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

   INSERT INTO dbo.Allegati
(
    Entita,
    IdEntita,
    TipoAllegato,
    Descrizione,
    NomeFileOriginale,
    PercorsoFile,
    Estensione,
    DataAllegato,
    UtenteInserimento,
    Note,
    NomeFileArchiviato,
    DimensioneFile
)
VALUES
(
    @Entita,
    @IdEntita,
    @TipoAllegato,
    @Descrizione,
    @NomeFileOriginale,
    @PercorsoFile,
    @Estensione,
    @DataAllegato,
    @UtenteInserimento,
    @Note,
    @NomeFileArchiviato,
    @DimensioneFile
);

SELECT CONVERT(INT, SCOPE_IDENTITY()) AS IdAllegato;
END
GO