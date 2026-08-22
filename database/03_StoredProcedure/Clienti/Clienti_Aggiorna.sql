CREATE OR ALTER PROCEDURE dbo.Clienti_Aggiorna
(
    @IdCliente INT,

    @CodiceCliente NVARCHAR(50),
    @RagioneSociale NVARCHAR(200),

    @PartitaIVA NVARCHAR(30)=NULL,
    @CodiceFiscale NVARCHAR(30)=NULL,

    @Indirizzo NVARCHAR(200)=NULL,
    @CAP NVARCHAR(10)=NULL,
    @Citta NVARCHAR(100)=NULL,
    @Provincia NVARCHAR(10)=NULL,

    @Telefono NVARCHAR(50)=NULL,
    @Email NVARCHAR(200)=NULL,

    @Attivo BIT
)
AS
BEGIN

    SET NOCOUNT ON;

    UPDATE dbo.Clienti
       SET CodiceCliente   = @CodiceCliente,
           RagioneSociale  = @RagioneSociale,
           PartitaIVA      = @PartitaIVA,
           CodiceFiscale   = @CodiceFiscale,
           Indirizzo       = @Indirizzo,
           CAP             = @CAP,
           Citta           = @Citta,
           Provincia       = @Provincia,
           Telefono        = @Telefono,
           Email           = @Email,
           Attivo          = @Attivo
     WHERE IdCliente = @IdCliente;

END
GO