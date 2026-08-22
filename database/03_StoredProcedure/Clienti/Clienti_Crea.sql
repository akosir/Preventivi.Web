CREATE OR ALTER PROCEDURE dbo.Clienti_Crea
(
    @CodiceCliente      NVARCHAR(50),
    @RagioneSociale     NVARCHAR(200),
    @PartitaIVA         NVARCHAR(30)=NULL,
    @CodiceFiscale      NVARCHAR(30)=NULL,
    @Indirizzo          NVARCHAR(200)=NULL,
    @CAP                NVARCHAR(10)=NULL,
    @Citta              NVARCHAR(100)=NULL,
    @Provincia          NVARCHAR(10)=NULL,
    @Telefono           NVARCHAR(50)=NULL,
    @Email              NVARCHAR(200)=NULL,
    @Attivo             BIT = 1
)
AS
BEGIN

    SET NOCOUNT ON;

    INSERT INTO dbo.Clienti
    (
        CodiceCliente,
        RagioneSociale,
        PartitaIVA,
        CodiceFiscale,
        Indirizzo,
        CAP,
        Citta,
        Provincia,
        Telefono,
        Email,
        Attivo
    )
    VALUES
    (
        @CodiceCliente,
        @RagioneSociale,
        @PartitaIVA,
        @CodiceFiscale,
        @Indirizzo,
        @CAP,
        @Citta,
        @Provincia,
        @Telefono,
        @Email,
        @Attivo
    );

    SELECT SCOPE_IDENTITY() AS IdCliente;

END
GO