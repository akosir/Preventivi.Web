CREATE OR ALTER PROCEDURE dbo.Clienti_Aggiorna
(
    @IdCliente INT,

    @CodiceCliente NVARCHAR(30),
    @RagioneSociale NVARCHAR(150),

    @PartitaIVA NVARCHAR(20)=NULL,
    @CodiceFiscale NVARCHAR(20)=NULL,

    @Indirizzo NVARCHAR(150)=NULL,
    @CAP NVARCHAR(10)=NULL,
    @Citta NVARCHAR(100)=NULL,
    @Provincia NVARCHAR(10)=NULL,

    @Telefono NVARCHAR(50)=NULL,
    @Email NVARCHAR(150)=NULL,

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
