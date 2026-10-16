/*
    TEC-002 - Stored procedure
    Origine: schema installato di PreventiviProduzione
    Contenuto: solo DDL, senza dati, utenti, ruoli, permessi o credenziali
*/
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET ARITHABORT ON;
SET NUMERIC_ROUNDABORT OFF;
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE   PROCEDURE dbo.Allegati_Crea
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

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE   PROCEDURE dbo.Allegati_Dettaglio
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

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE   PROCEDURE dbo.Allegati_Elenco
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

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE   PROCEDURE dbo.Allegati_Elimina
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

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE   PROCEDURE dbo.Articoli_Dettaglio_Lookup
    @IdArticolo INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        IdArticolo,
        CodiceArticolo,
        Descrizione,
        Versione
    FROM dbo.Articoli
    WHERE IdArticolo = @IdArticolo;
END;
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE   PROCEDURE dbo.Articoli_Ricerca
    @Ricerca NVARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP (50)
        IdArticolo,
        CodiceArticolo,
        Descrizione,
        Versione
    FROM dbo.Articoli
    WHERE Attivo = 1
      AND (
            @Ricerca IS NULL
            OR CodiceArticolo LIKE '%' + @Ricerca + '%'
            OR Descrizione LIKE '%' + @Ricerca + '%'
          )
    ORDER BY CodiceArticolo, Descrizione;
END;
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE   PROCEDURE dbo.Clienti_Aggiorna
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

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE   PROCEDURE dbo.Clienti_Crea
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

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE   PROCEDURE dbo.Clienti_Dettaglio
(
    @IdCliente INT
)
AS
BEGIN

    SET NOCOUNT ON;

    SELECT
        IdCliente,
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
    FROM dbo.Clienti
    WHERE IdCliente = @IdCliente;

END
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE   PROCEDURE dbo.Clienti_Disattiva
(
    @IdCliente INT
)
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.Clienti
       SET Attivo = 0,
           DataModifica = SYSDATETIME()
     WHERE IdCliente = @IdCliente;
END
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE   PROCEDURE dbo.Clienti_Elenco
    @Ricerca NVARCHAR(300) = NULL,
    @SoloAttivi BIT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        c.IdCliente,
        c.CodiceCliente,
        c.RagioneSociale,
        c.PartitaIVA,
        c.Citta,
        c.Telefono,
        c.Email,
        c.Attivo
    FROM dbo.Clienti AS c
    WHERE
        (
            @Ricerca IS NULL
            OR LTRIM(RTRIM(@Ricerca)) = ''
            OR c.CodiceCliente LIKE '%' + @Ricerca + '%'
            OR c.RagioneSociale LIKE '%' + @Ricerca + '%'
            OR c.PartitaIVA LIKE '%' + @Ricerca + '%'
        )
        AND
        (
            @SoloAttivi IS NULL
            OR c.Attivo = @SoloAttivi
        )
    ORDER BY
        c.RagioneSociale,
        c.CodiceCliente;
END;
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE   PROCEDURE dbo.DistintaBaseNodi_Dettaglio
    @IdNodoDistinta INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        n.IdNodoDistinta,
        n.IdArticolo,
        n.IdNodoPadre,
        n.CodiceNodo,
        n.DescrizioneNodo,
        n.Livello,
        n.QuantitaBase,
        n.OrdineVisualizzazione,
        ISNULL(t.Descrizione, '') AS TipoNodo
    FROM dbo.DistintaBaseNodi AS n
    LEFT JOIN dbo.TipiNodoDistinta AS t
        ON t.IdTipoNodo = n.IdTipoNodo
    WHERE n.IdNodoDistinta = @IdNodoDistinta;
END;
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE   PROCEDURE dbo.DistintaBaseNodi_Elenco
    @IdArticolo INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        n.IdNodoDistinta,
        n.IdArticolo,
        n.IdNodoPadre,
        n.CodiceNodo,
        n.DescrizioneNodo,
        n.Livello,
        n.QuantitaBase,
        n.OrdineVisualizzazione,
        ISNULL(t.Descrizione, '') AS TipoNodo
    FROM dbo.DistintaBaseNodi AS n
    LEFT JOIN dbo.TipiNodoDistinta AS t
        ON t.IdTipoNodo = n.IdTipoNodo
    WHERE n.IdArticolo = @IdArticolo
      AND n.Attivo = 1
    ORDER BY n.OrdineVisualizzazione, n.IdNodoDistinta;
END;
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE   PROCEDURE dbo.DistintaLavorazioni_Dettaglio
    @IdDistintaLavorazione INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        dl.IdDistintaLavorazione,
        dl.IdNodoDistinta,
        dl.IdLavorazione,
        ISNULL(l.CodiceLavorazione, '') AS CodiceLavorazione,
        ISNULL(l.Descrizione, '') AS DescrizioneLavorazione,
        dl.Sequenza,
        dl.TempoSetupMin,
        dl.TempoPezzoMin,
        dl.CostoOrario,
        dl.CostoFisso,
        ISNULL(l.AcquistabileEsterna, 0) AS DaAcquistareEsterno,
        l.IdFornitorePredefinito AS IdFornitoreSuggerito
    FROM dbo.DistintaLavorazioni AS dl
    INNER JOIN dbo.Lavorazioni AS l
        ON l.IdLavorazione = dl.IdLavorazione
    WHERE dl.IdDistintaLavorazione = @IdDistintaLavorazione;
END;
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE   PROCEDURE dbo.DistintaLavorazioni_Elenco
    @IdNodoDistinta INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        dl.IdDistintaLavorazione,
        dl.IdNodoDistinta,
        dl.IdLavorazione,
        ISNULL(l.CodiceLavorazione, '') AS CodiceLavorazione,
        ISNULL(l.Descrizione, '') AS DescrizioneLavorazione,
        dl.Sequenza,
        dl.TempoSetupMin,
        dl.TempoPezzoMin,
        dl.CostoOrario,
        dl.CostoFisso,
        ISNULL(l.AcquistabileEsterna, 0) AS DaAcquistareEsterno,
        l.IdFornitorePredefinito AS IdFornitoreSuggerito
    FROM dbo.DistintaLavorazioni AS dl
    INNER JOIN dbo.Lavorazioni AS l
        ON l.IdLavorazione = dl.IdLavorazione
    WHERE dl.IdNodoDistinta = @IdNodoDistinta
    ORDER BY dl.Sequenza, l.CodiceLavorazione;
END;
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE   PROCEDURE dbo.DistintaMateriali_Dettaglio
    @IdDistintaMateriale INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        dm.IdDistintaMateriale,
        dm.IdNodoDistinta,
        dm.IdMateriale,
        ISNULL(m.CodiceMateriale, '') AS CodiceMateriale,
        ISNULL(m.Descrizione, '') AS DescrizioneMateriale,
        m.TipoMateriale,
        CONVERT(NVARCHAR(20), m.IdUM) AS UM,
        dm.Quantita,
        ISNULL(m.CostoUnitario, 0) AS CostoUnitario,
        ISNULL(m.GestitoAAcquisto, 0) AS DaAcquistare,
        m.IdFornitorePredefinito AS IdFornitoreSuggerito
    FROM dbo.DistintaMateriali AS dm
    INNER JOIN dbo.Materiali AS m
        ON m.IdMateriale = dm.IdMateriale
    WHERE dm.IdDistintaMateriale = @IdDistintaMateriale;
END;
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE   PROCEDURE dbo.DistintaMateriali_Elenco
    @IdNodoDistinta INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        dm.IdDistintaMateriale,
        dm.IdNodoDistinta,
        dm.IdMateriale,
        ISNULL(m.CodiceMateriale, '') AS CodiceMateriale,
        ISNULL(m.Descrizione, '') AS DescrizioneMateriale,
        m.TipoMateriale,
        CONVERT(NVARCHAR(20), m.IdUM) AS UM,
        dm.Quantita,
        ISNULL(m.CostoUnitario, 0) AS CostoUnitario,
        ISNULL(m.GestitoAAcquisto, 0) AS DaAcquistare,
        m.IdFornitorePredefinito AS IdFornitoreSuggerito
    FROM dbo.DistintaMateriali AS dm
    INNER JOIN dbo.Materiali AS m
        ON m.IdMateriale = dm.IdMateriale
    WHERE dm.IdNodoDistinta = @IdNodoDistinta
    ORDER BY m.CodiceMateriale, m.Descrizione;
END;
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE   PROCEDURE dbo.Lavorazioni_Dettaglio_Lookup
    @IdLavorazione INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        IdLavorazione,
        CodiceLavorazione,
        Descrizione,
        InternaEsterna,
        CostoOrarioStandard,
        TempoSetupMinDefault,
        TempoPezzoMinDefault,
        AcquistabileEsterna,
        IdFornitorePredefinito
    FROM dbo.Lavorazioni
    WHERE IdLavorazione = @IdLavorazione;
END;
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE   PROCEDURE dbo.Lavorazioni_Ricerca
    @Ricerca NVARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP (50)
        IdLavorazione,
        CodiceLavorazione,
        Descrizione,
        InternaEsterna,
        CostoOrarioStandard,
        TempoSetupMinDefault,
        TempoPezzoMinDefault,
        AcquistabileEsterna,
        IdFornitorePredefinito
    FROM dbo.Lavorazioni
    WHERE Attiva = 1
      AND (
            @Ricerca IS NULL
            OR CodiceLavorazione LIKE '%' + @Ricerca + '%'
            OR Descrizione LIKE '%' + @Ricerca + '%'
          )
    ORDER BY CodiceLavorazione, Descrizione;
END;
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE   PROCEDURE dbo.Materiali_Dettaglio_Lookup
    @IdMateriale INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        IdMateriale,
        CodiceMateriale,
        Descrizione,
        TipoMateriale,
        CONVERT(NVARCHAR(20), IdUM) AS UM,
        CostoUnitario,
        GestitoAAcquisto,
        IdFornitorePredefinito
    FROM dbo.Materiali
    WHERE IdMateriale = @IdMateriale;
END;
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE   PROCEDURE dbo.Materiali_Ricerca
    @Ricerca NVARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP (50)
        IdMateriale,
        CodiceMateriale,
        Descrizione,
        TipoMateriale,
        CONVERT(NVARCHAR(20), IdUM) AS UM,
        CostoUnitario,
        GestitoAAcquisto,
        IdFornitorePredefinito
    FROM dbo.Materiali
    WHERE Attivo = 1
      AND (
            @Ricerca IS NULL
            OR CodiceMateriale LIKE '%' + @Ricerca + '%'
            OR Descrizione LIKE '%' + @Ricerca + '%'
          )
    ORDER BY CodiceMateriale, Descrizione;
END;
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE   PROCEDURE dbo.ParametriSistema_GetValore
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

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE   PROCEDURE dbo.Preventivi_Dettaglio
    @IdPreventivo INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        p.IdPreventivo,
        p.NumeroPreventivo,
        p.Anno,
        p.DataPreventivo,
        p.IdCliente,
        ISNULL(c.RagioneSociale, '') AS Cliente,
        ISNULL(p.Oggetto, '') AS Oggetto,
        ISNULL(p.Note, '') AS Note,
        p.Stato,
        p.TotaleCosti,
        p.TotaleVendita,
        p.MargineValore,
        p.MarginePerc,
        p.MarkupPercDefault,
        p.IdRichiestaCliente
    FROM dbo.Preventivi AS p
    LEFT JOIN dbo.Clienti AS c
        ON c.IdCliente = p.IdCliente
    WHERE p.IdPreventivo = @IdPreventivo;
END;
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE   PROCEDURE dbo.Preventivi_Elenco
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        p.IdPreventivo,
        p.NumeroPreventivo,
        p.Anno,
        p.DataPreventivo,
        ISNULL(c.RagioneSociale, '') AS Cliente,
        ISNULL(p.Oggetto, '') AS Oggetto,
        p.TotaleVendita,
        p.Stato
    FROM dbo.Preventivi AS p
    LEFT JOIN dbo.Clienti AS c
        ON c.IdCliente = p.IdCliente
    ORDER BY
        p.Anno DESC,
        p.NumeroPreventivo DESC;
END;
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER OFF
GO


CREATE   PROCEDURE dbo.Preventivi_Righe_Componenti_Crea
    @IdRigaPreventivo INT,
    @IdRigaCompPrevPadre INT = NULL,
    @TipoOrigineComponente NVARCHAR(20),
    @IdArticoloOrigine INT = NULL,
    @IdNodoDistinta INT = NULL,
    @IdNodoPadre INT = NULL,
    @DescrizioneNodo NVARCHAR(400),
    @Livello INT,
    @QuantitaBase DECIMAL(18,4),
    @OrdineVisualizzazione INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE
        @QuantitaRiga DECIMAL(18,4),
        @QuantitaPadre DECIMAL(18,4),
        @QuantitaCalcolata DECIMAL(18,4),
        @RigaLibera BIT,
        @IdRigaCompPrev INT;

    BEGIN TRY
        BEGIN TRANSACTION;

        SELECT
            @QuantitaRiga = riga.Quantita,
            @RigaLibera = tipo.RigaLibera
        FROM dbo.PreventiviRighe AS riga
        INNER JOIN dbo.TipiRigaPreventivo AS tipo
            ON tipo.IdTipoRiga = riga.IdTipoRiga
        WHERE riga.IdRigaPreventivo = @IdRigaPreventivo;

        IF @QuantitaRiga IS NULL
        BEGIN
            THROW 51201, 'Riga preventivo non trovata.', 1;
        END;

        IF @RigaLibera = 1
        BEGIN
            THROW 51932, 'Una riga libera non puo contenere componenti.', 1;
        END;

        IF @QuantitaBase <= 0
        BEGIN
            THROW 51202, 'La quantita base deve essere maggiore di zero.', 1;
        END;

        IF @TipoOrigineComponente IS NULL
           OR @TipoOrigineComponente NOT IN (N'Distinta', N'Articolo', N'Libero')
           OR (@TipoOrigineComponente = N'Distinta' AND (@IdNodoDistinta IS NULL OR @IdArticoloOrigine IS NULL))
           OR (@TipoOrigineComponente = N'Articolo' AND (@IdNodoDistinta IS NOT NULL OR @IdArticoloOrigine IS NULL))
           OR (@TipoOrigineComponente = N'Libero' AND (@IdNodoDistinta IS NOT NULL OR @IdArticoloOrigine IS NOT NULL))
        BEGIN
            THROW 51203, 'Origine componente non coerente con articolo e nodo distinta.', 1;
        END;

        IF @Livello < 0
        BEGIN
            THROW 51206, 'Il livello del componente non puo essere negativo.', 1;
        END;

        IF @TipoOrigineComponente = N'Distinta'
           AND NOT EXISTS
           (
               SELECT 1
               FROM dbo.DistintaBaseNodi
               WHERE IdNodoDistinta = @IdNodoDistinta
                 AND IdArticolo = @IdArticoloOrigine
           )
        BEGIN
            THROW 51204, 'Il nodo distinta non appartiene all''articolo indicato.', 1;
        END;

        IF @IdRigaCompPrevPadre IS NOT NULL
        BEGIN
            SELECT @QuantitaPadre = QuantitaCalcolata
            FROM dbo.PreventiviRigheComponenti
            WHERE IdRigaCompPrev = @IdRigaCompPrevPadre
              AND IdRigaPreventivo = @IdRigaPreventivo;

            IF @QuantitaPadre IS NULL
            BEGIN
                THROW 51205, 'Il componente padre non appartiene alla riga indicata.', 1;
            END;
        END;

        SET @QuantitaCalcolata =
            CASE
                WHEN @IdRigaCompPrevPadre IS NULL THEN @QuantitaRiga * @QuantitaBase
                ELSE @QuantitaPadre * @QuantitaBase
            END;

        INSERT INTO dbo.PreventiviRigheComponenti
        (
            IdRigaPreventivo,
            IdRigaCompPrevPadre,
            TipoOrigineComponente,
            IdArticoloOrigine,
            IdNodoDistinta,
            IdNodoPadre,
            DescrizioneNodo,
            Livello,
            QuantitaBase,
            QuantitaCalcolata,
            OrdineVisualizzazione
        )
        VALUES
        (
            @IdRigaPreventivo,
            @IdRigaCompPrevPadre,
            @TipoOrigineComponente,
            @IdArticoloOrigine,
            @IdNodoDistinta,
            @IdNodoPadre,
            @DescrizioneNodo,
            @Livello,
            @QuantitaBase,
            @QuantitaCalcolata,
            ISNULL(@OrdineVisualizzazione, 10)
        );

        SET @IdRigaCompPrev = CONVERT(INT, SCOPE_IDENTITY());

        COMMIT TRANSACTION;

        SELECT @IdRigaCompPrev;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
        BEGIN
            ROLLBACK TRANSACTION;
        END;

        THROW;
    END CATCH;
END;
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE   PROCEDURE dbo.Preventivi_Righe_Componenti_Dettaglio
    @IdRigaCompPrev INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        IdRigaCompPrev,
        IdRigaPreventivo,
        IdRigaCompPrevPadre,
        TipoOrigineComponente,
        IdArticoloOrigine,
        IdNodoDistinta,
        IdNodoPadre,
        DescrizioneNodo,
        Livello,
        QuantitaBase,
        QuantitaCalcolata,
        OrdineVisualizzazione
    FROM dbo.PreventiviRigheComponenti
    WHERE IdRigaCompPrev = @IdRigaCompPrev;
END;
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE   PROCEDURE dbo.Preventivi_Righe_Componenti_Elenco
    @IdRigaPreventivo INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        IdRigaCompPrev,
        IdRigaPreventivo,
        IdRigaCompPrevPadre,
        TipoOrigineComponente,
        IdArticoloOrigine,
        IdNodoDistinta,
        IdNodoPadre,
        DescrizioneNodo,
        Livello,
        QuantitaBase,
        QuantitaCalcolata,
        OrdineVisualizzazione
    FROM dbo.PreventiviRigheComponenti
    WHERE IdRigaPreventivo = @IdRigaPreventivo
    ORDER BY OrdineVisualizzazione, IdRigaCompPrev;
END;
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER OFF
GO


CREATE   PROCEDURE dbo.Preventivi_Righe_Componenti_Elimina
    @IdRigaCompPrev INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @IdRigaPreventivo INT;

    BEGIN TRY
        BEGIN TRANSACTION;

        SELECT @IdRigaPreventivo = IdRigaPreventivo
        FROM dbo.PreventiviRigheComponenti
        WHERE IdRigaCompPrev = @IdRigaCompPrev;

        IF @IdRigaPreventivo IS NULL
        BEGIN
            THROW 51933, 'Componente preventivo non trovato.', 1;
        END;

        DELETE FROM dbo.PreventiviRigheLavorazioni
        WHERE IdRigaCompPrev = @IdRigaCompPrev;

        DELETE FROM dbo.PreventiviRigheMateriali
        WHERE IdRigaCompPrev = @IdRigaCompPrev;

        DELETE FROM dbo.PreventiviRigheComponenti
        WHERE IdRigaCompPrev = @IdRigaCompPrev;

        EXEC dbo.sp_RicalcolaTotaliRigaPreventivo
            @IdRigaPreventivo = @IdRigaPreventivo;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
        BEGIN
            ROLLBACK TRANSACTION;
        END;

        THROW;
    END CATCH;
END;
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER OFF
GO


CREATE   PROCEDURE dbo.Preventivi_Righe_Crea
    @IdPreventivo INT,
    @RigaNr INT = NULL,
    @IdArticolo INT = NULL,
    @IdModelloCiclo INT = NULL,
    @DescrizioneVoce NVARCHAR(500),
    @Quantita DECIMAL(18,4),
    @PrezzoUnitarioVendita DECIMAL(18,4),
    @Note NVARCHAR(MAX) = NULL,
    @MarkupPerc DECIMAL(9,2),
    @PrezzoManuale BIT,
    @IdVariantePreventivo INT = NULL,
    @CostoUnitarioLibero DECIMAL(18,4) = NULL,
    @IdTipoRiga INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE
        @NumeroRiga INT,
        @RigaLibera BIT,
        @TotaleCosti DECIMAL(18,2),
        @TotaleVendita DECIMAL(18,2),
        @MargineValore DECIMAL(18,2),
        @MarginePerc DECIMAL(9,2),
        @IdRigaPreventivo INT;

    BEGIN TRY
        BEGIN TRANSACTION;

        IF NOT EXISTS
        (
            SELECT 1
            FROM dbo.Preventivi
            WHERE IdPreventivo = @IdPreventivo
        )
        BEGIN
            THROW 51942, 'Preventivo non trovato.', 1;
        END;

        SELECT @RigaLibera = RigaLibera
        FROM dbo.TipiRigaPreventivo
        WHERE IdTipoRiga = @IdTipoRiga
          AND Attiva = 1;

        IF @RigaLibera IS NULL
        BEGIN
            THROW 51943, 'Tipo riga non trovato o non attivo.', 1;
        END;

        IF @IdVariantePreventivo IS NOT NULL
           AND NOT EXISTS
           (
               SELECT 1
               FROM dbo.PreventiviVarianti
               WHERE IdVariantePreventivo = @IdVariantePreventivo
                 AND IdPreventivo = @IdPreventivo
                 AND Attiva = 1
           )
        BEGIN
            THROW 51944, 'La variante non appartiene al preventivo o non e attiva.', 1;
        END;

        IF @Quantita <= 0
        BEGIN
            THROW 51945, 'La quantita deve essere maggiore di zero.', 1;
        END;

        IF @RigaLibera = 1 AND @CostoUnitarioLibero IS NULL
        BEGIN
            THROW 51946, 'La riga libera richiede il costo unitario libero.', 1;
        END;

        IF @RigaLibera = 0
        BEGIN
            SET @CostoUnitarioLibero = NULL;
            SET @TotaleCosti = 0;
        END
        ELSE
        BEGIN
            SET @TotaleCosti = ROUND(@Quantita * @CostoUnitarioLibero, 2);
        END;

        IF @PrezzoManuale = 1
        BEGIN
            SET @TotaleVendita = ROUND(@Quantita * @PrezzoUnitarioVendita, 2);
        END
        ELSE
        BEGIN
            SET @TotaleVendita =
                ROUND(@TotaleCosti * (1 + @MarkupPerc / 100.0), 2);

            SET @PrezzoUnitarioVendita =
                CASE
                    WHEN @Quantita = 0 THEN 0
                    ELSE ROUND(@TotaleVendita / @Quantita, 4)
                END;
        END;

        SET @MargineValore = @TotaleVendita - @TotaleCosti;
        SET @MarginePerc =
            CASE
                WHEN @TotaleVendita = 0 THEN 0
                ELSE ROUND((@MargineValore / @TotaleVendita) * 100, 2)
            END;

        SET @NumeroRiga =
            ISNULL
            (
                @RigaNr,
                ISNULL
                (
                    (
                        SELECT MAX(RigaNr)
                        FROM dbo.PreventiviRighe WITH (UPDLOCK, HOLDLOCK)
                        WHERE IdPreventivo = @IdPreventivo
                    ),
                    0
                ) + 1
            );

        INSERT INTO dbo.PreventiviRighe
        (
            IdPreventivo,
            RigaNr,
            IdArticolo,
            IdModelloCiclo,
            DescrizioneVoce,
            Quantita,
            PrezzoUnitarioVendita,
            TotaleVendita,
            TotaleCosti,
            MargineValore,
            MarginePerc,
            Note,
            DataCreazione,
            MarkupPerc,
            PrezzoManuale,
            IdVariantePreventivo,
            CostoUnitarioLibero,
            IdTipoRiga
        )
        VALUES
        (
            @IdPreventivo,
            @NumeroRiga,
            @IdArticolo,
            @IdModelloCiclo,
            @DescrizioneVoce,
            @Quantita,
            @PrezzoUnitarioVendita,
            @TotaleVendita,
            @TotaleCosti,
            @MargineValore,
            @MarginePerc,
            @Note,
            SYSDATETIME(),
            @MarkupPerc,
            @PrezzoManuale,
            @IdVariantePreventivo,
            @CostoUnitarioLibero,
            @IdTipoRiga
        );

        SET @IdRigaPreventivo = CONVERT(INT, SCOPE_IDENTITY());

        IF @IdVariantePreventivo IS NOT NULL
        BEGIN
            EXEC dbo.sp_RicalcolaTotaliVariante
                @IdVariantePreventivo = @IdVariantePreventivo;
        END;

        EXEC dbo.sp_RicalcolaTotaliPreventivo
            @IdPreventivo = @IdPreventivo;

        COMMIT TRANSACTION;

        SELECT @IdRigaPreventivo;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
        BEGIN
            ROLLBACK TRANSACTION;
        END;

        THROW;
    END CATCH;
END;
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE   PROCEDURE dbo.Preventivi_Righe_Dettaglio
    @IdRigaPreventivo INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        r.IdRigaPreventivo,
        r.IdPreventivo,
        r.RigaNr,
        r.IdArticolo,
        r.IdModelloCiclo,
        r.DescrizioneVoce,
        r.Quantita,
        r.PrezzoUnitarioVendita,
        r.TotaleVendita,
        r.TotaleCosti,
        r.MargineValore,
        r.MarginePerc,
        r.Note,
        r.MarkupPerc,
        r.PrezzoManuale,
        r.IdVariantePreventivo,
        r.CostoUnitarioLibero,
        r.IdTipoRiga,
        ISNULL(t.Descrizione, '') AS TipoRiga
    FROM dbo.PreventiviRighe AS r
    INNER JOIN dbo.TipiRigaPreventivo AS t
        ON t.IdTipoRiga = r.IdTipoRiga
    WHERE r.IdRigaPreventivo = @IdRigaPreventivo;
END;
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE   PROCEDURE dbo.Preventivi_Righe_Elenco
    @IdPreventivo INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        r.IdRigaPreventivo,
        r.RigaNr,
        r.IdTipoRiga,
        ISNULL(t.Descrizione, '') AS TipoRiga,
        r.DescrizioneVoce,
        r.Quantita,
        r.TotaleCosti,
        r.PrezzoUnitarioVendita,
        r.TotaleVendita,
        r.MargineValore,
        r.MarginePerc,
        r.PrezzoManuale
    FROM dbo.PreventiviRighe AS r
    INNER JOIN dbo.TipiRigaPreventivo AS t
        ON t.IdTipoRiga = r.IdTipoRiga
    WHERE r.IdPreventivo = @IdPreventivo
    ORDER BY
        r.RigaNr,
        r.IdRigaPreventivo;
END;
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER OFF
GO


CREATE   PROCEDURE dbo.Preventivi_Righe_Elimina
    @IdRigaPreventivo INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE
        @IdPreventivo INT,
        @IdVariantePreventivo INT;

    BEGIN TRY
        BEGIN TRANSACTION;

        SELECT
            @IdPreventivo = IdPreventivo,
            @IdVariantePreventivo = IdVariantePreventivo
        FROM dbo.PreventiviRighe
        WHERE IdRigaPreventivo = @IdRigaPreventivo;

        IF @IdPreventivo IS NULL
        BEGIN
            THROW 51947, 'Riga preventivo non trovata.', 1;
        END;

        DELETE FROM dbo.PreventiviRigheLavorazioni
        WHERE IdRigaPreventivo = @IdRigaPreventivo;

        DELETE FROM dbo.PreventiviRigheMateriali
        WHERE IdRigaPreventivo = @IdRigaPreventivo;

        DELETE FROM dbo.PreventiviRigheComponenti
        WHERE IdRigaPreventivo = @IdRigaPreventivo;

        DELETE FROM dbo.PreventiviRighe
        WHERE IdRigaPreventivo = @IdRigaPreventivo;

        IF @IdVariantePreventivo IS NOT NULL
        BEGIN
            EXEC dbo.sp_RicalcolaTotaliVariante
                @IdVariantePreventivo = @IdVariantePreventivo;
        END;

        EXEC dbo.sp_RicalcolaTotaliPreventivo
            @IdPreventivo = @IdPreventivo;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
        BEGIN
            ROLLBACK TRANSACTION;
        END;

        THROW;
    END CATCH;
END;
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER OFF
GO


CREATE   PROCEDURE dbo.Preventivi_Righe_Lavorazioni_Crea
    @IdRigaPreventivo INT,
    @IdRigaCompPrev INT = NULL,
    @IdNodoDistinta INT = NULL,
    @IdLavorazione INT = NULL,
    @DescrizioneLavorazione NVARCHAR(300),
    @Sequenza INT = NULL,
    @TempoSetupMin DECIMAL(18,2),
    @TempoPezzoMin DECIMAL(18,4),
    @Quantita DECIMAL(18,4),
    @CostoOrario DECIMAL(18,4),
    @CostoFisso DECIMAL(18,4),
    @DaAcquistareEsterno BIT,
    @IdFornitoreSuggerito INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE
        @TempoTotaleMin DECIMAL(18,4),
        @IdRigaLavPrev INT;

    BEGIN TRY
        BEGIN TRANSACTION;

        IF NOT EXISTS
        (
            SELECT 1
            FROM dbo.PreventiviRighe AS riga
            INNER JOIN dbo.TipiRigaPreventivo AS tipo
                ON tipo.IdTipoRiga = riga.IdTipoRiga
            WHERE riga.IdRigaPreventivo = @IdRigaPreventivo
              AND tipo.RigaLibera = 0
        )
        BEGIN
            THROW 51936, 'La riga non esiste oppure e una riga libera.', 1;
        END;

        IF @IdRigaCompPrev IS NOT NULL
           AND NOT EXISTS
           (
               SELECT 1
               FROM dbo.PreventiviRigheComponenti
               WHERE IdRigaCompPrev = @IdRigaCompPrev
                 AND IdRigaPreventivo = @IdRigaPreventivo
           )
        BEGIN
            THROW 51222, 'Il componente non appartiene alla riga indicata.', 1;
        END;

        SET @TempoTotaleMin = @TempoSetupMin + @TempoPezzoMin * @Quantita;

        INSERT INTO dbo.PreventiviRigheLavorazioni
        (
            IdRigaPreventivo,
            IdRigaCompPrev,
            IdNodoDistinta,
            IdLavorazione,
            DescrizioneLavorazione,
            Sequenza,
            TempoSetupMin,
            TempoPezzoMin,
            Quantita,
            TempoTotaleMin,
            CostoOrario,
            CostoFisso,
            CostoTotale,
            DaAcquistareEsterno,
            IdFornitoreSuggerito
        )
        VALUES
        (
            @IdRigaPreventivo,
            @IdRigaCompPrev,
            @IdNodoDistinta,
            @IdLavorazione,
            @DescrizioneLavorazione,
            ISNULL(@Sequenza, 10),
            @TempoSetupMin,
            @TempoPezzoMin,
            @Quantita,
            @TempoTotaleMin,
            @CostoOrario,
            @CostoFisso,
            ROUND((@TempoTotaleMin / 60) * @CostoOrario + @CostoFisso, 2),
            @DaAcquistareEsterno,
            @IdFornitoreSuggerito
        );

        SET @IdRigaLavPrev = CONVERT(INT, SCOPE_IDENTITY());

        EXEC dbo.sp_RicalcolaTotaliRigaPreventivo
            @IdRigaPreventivo = @IdRigaPreventivo;

        COMMIT TRANSACTION;

        SELECT @IdRigaLavPrev;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
        BEGIN
            ROLLBACK TRANSACTION;
        END;

        THROW;
    END CATCH;
END;
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE   PROCEDURE dbo.Preventivi_Righe_Lavorazioni_Dettaglio
    @IdRigaLavPrev INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        IdRigaLavPrev,
        IdRigaPreventivo,
        IdRigaCompPrev,
        IdNodoDistinta,
        IdLavorazione,
        DescrizioneLavorazione,
        Sequenza,
        TempoSetupMin,
        TempoPezzoMin,
        Quantita,
        TempoTotaleMin,
        CostoOrario,
        CostoFisso,
        CostoTotale,
        DaAcquistareEsterno,
        IdFornitoreSuggerito
    FROM dbo.PreventiviRigheLavorazioni
    WHERE IdRigaLavPrev = @IdRigaLavPrev;
END;
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE   PROCEDURE dbo.Preventivi_Righe_Lavorazioni_Elenco
    @IdRigaPreventivo INT,
    @IdRigaCompPrev INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        IdRigaLavPrev,
        IdRigaPreventivo,
        IdRigaCompPrev,
        IdNodoDistinta,
        IdLavorazione,
        DescrizioneLavorazione,
        Sequenza,
        TempoSetupMin,
        TempoPezzoMin,
        Quantita,
        TempoTotaleMin,
        CostoOrario,
        CostoFisso,
        CostoTotale,
        DaAcquistareEsterno,
        IdFornitoreSuggerito
    FROM dbo.PreventiviRigheLavorazioni
    WHERE IdRigaPreventivo = @IdRigaPreventivo
      AND (
            IdRigaCompPrev = @IdRigaCompPrev
            OR (IdRigaCompPrev IS NULL AND @IdRigaCompPrev IS NULL)
          )
    ORDER BY Sequenza, IdRigaLavPrev;
END;
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER OFF
GO


CREATE   PROCEDURE dbo.Preventivi_Righe_Lavorazioni_Elimina
    @IdRigaLavPrev INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @IdRigaPreventivo INT;

    BEGIN TRY
        BEGIN TRANSACTION;

        SELECT @IdRigaPreventivo = IdRigaPreventivo
        FROM dbo.PreventiviRigheLavorazioni
        WHERE IdRigaLavPrev = @IdRigaLavPrev;

        IF @IdRigaPreventivo IS NULL
        BEGIN
            THROW 51937, 'Lavorazione preventivo non trovata.', 1;
        END;

        DELETE FROM dbo.PreventiviRigheLavorazioni
        WHERE IdRigaLavPrev = @IdRigaLavPrev;

        EXEC dbo.sp_RicalcolaTotaliRigaPreventivo
            @IdRigaPreventivo = @IdRigaPreventivo;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
        BEGIN
            ROLLBACK TRANSACTION;
        END;

        THROW;
    END CATCH;
END;
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER OFF
GO


CREATE   PROCEDURE dbo.Preventivi_Righe_Materiali_Crea
    @IdRigaPreventivo INT,
    @IdRigaCompPrev INT = NULL,
    @IdNodoDistinta INT = NULL,
    @IdMateriale INT = NULL,
    @DescrizioneMateriale NVARCHAR(400),
    @TipoMateriale NVARCHAR(60) = NULL,
    @UM NVARCHAR(20) = NULL,
    @Quantita DECIMAL(18,4),
    @CostoUnitario DECIMAL(18,4),
    @DaAcquistare BIT,
    @IdFornitoreSuggerito INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @IdRigaMatPrev INT;

    BEGIN TRY
        BEGIN TRANSACTION;

        IF NOT EXISTS
        (
            SELECT 1
            FROM dbo.PreventiviRighe AS riga
            INNER JOIN dbo.TipiRigaPreventivo AS tipo
                ON tipo.IdTipoRiga = riga.IdTipoRiga
            WHERE riga.IdRigaPreventivo = @IdRigaPreventivo
              AND tipo.RigaLibera = 0
        )
        BEGIN
            THROW 51934, 'La riga non esiste oppure e una riga libera.', 1;
        END;

        IF @IdRigaCompPrev IS NOT NULL
           AND NOT EXISTS
           (
               SELECT 1
               FROM dbo.PreventiviRigheComponenti
               WHERE IdRigaCompPrev = @IdRigaCompPrev
                 AND IdRigaPreventivo = @IdRigaPreventivo
           )
        BEGIN
            THROW 51212, 'Il componente non appartiene alla riga indicata.', 1;
        END;

        INSERT INTO dbo.PreventiviRigheMateriali
        (
            IdRigaPreventivo,
            IdRigaCompPrev,
            IdNodoDistinta,
            IdMateriale,
            DescrizioneMateriale,
            TipoMateriale,
            UM,
            Quantita,
            CostoUnitario,
            CostoTotale,
            DaAcquistare,
            IdFornitoreSuggerito
        )
        VALUES
        (
            @IdRigaPreventivo,
            @IdRigaCompPrev,
            @IdNodoDistinta,
            @IdMateriale,
            @DescrizioneMateriale,
            @TipoMateriale,
            @UM,
            @Quantita,
            @CostoUnitario,
            ROUND(@Quantita * @CostoUnitario, 2),
            @DaAcquistare,
            @IdFornitoreSuggerito
        );

        SET @IdRigaMatPrev = CONVERT(INT, SCOPE_IDENTITY());

        EXEC dbo.sp_RicalcolaTotaliRigaPreventivo
            @IdRigaPreventivo = @IdRigaPreventivo;

        COMMIT TRANSACTION;

        SELECT @IdRigaMatPrev;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
        BEGIN
            ROLLBACK TRANSACTION;
        END;

        THROW;
    END CATCH;
END;
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE   PROCEDURE dbo.Preventivi_Righe_Materiali_Dettaglio
    @IdRigaMatPrev INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        IdRigaMatPrev,
        IdRigaPreventivo,
        IdRigaCompPrev,
        IdNodoDistinta,
        IdMateriale,
        DescrizioneMateriale,
        TipoMateriale,
        UM,
        Quantita,
        CostoUnitario,
        CostoTotale,
        DaAcquistare,
        IdFornitoreSuggerito
    FROM dbo.PreventiviRigheMateriali
    WHERE IdRigaMatPrev = @IdRigaMatPrev;
END;
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE   PROCEDURE dbo.Preventivi_Righe_Materiali_Elenco
    @IdRigaPreventivo INT,
    @IdRigaCompPrev INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        IdRigaMatPrev,
        IdRigaPreventivo,
        IdRigaCompPrev,
        IdNodoDistinta,
        IdMateriale,
        DescrizioneMateriale,
        TipoMateriale,
        UM,
        Quantita,
        CostoUnitario,
        CostoTotale,
        DaAcquistare,
        IdFornitoreSuggerito
    FROM dbo.PreventiviRigheMateriali
    WHERE IdRigaPreventivo = @IdRigaPreventivo
      AND (
            IdRigaCompPrev = @IdRigaCompPrev
            OR (IdRigaCompPrev IS NULL AND @IdRigaCompPrev IS NULL)
          )
    ORDER BY DescrizioneMateriale, IdRigaMatPrev;
END;
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER OFF
GO


CREATE   PROCEDURE dbo.Preventivi_Righe_Materiali_Elimina
    @IdRigaMatPrev INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @IdRigaPreventivo INT;

    BEGIN TRY
        BEGIN TRANSACTION;

        SELECT @IdRigaPreventivo = IdRigaPreventivo
        FROM dbo.PreventiviRigheMateriali
        WHERE IdRigaMatPrev = @IdRigaMatPrev;

        IF @IdRigaPreventivo IS NULL
        BEGIN
            THROW 51935, 'Materiale preventivo non trovato.', 1;
        END;

        DELETE FROM dbo.PreventiviRigheMateriali
        WHERE IdRigaMatPrev = @IdRigaMatPrev;

        EXEC dbo.sp_RicalcolaTotaliRigaPreventivo
            @IdRigaPreventivo = @IdRigaPreventivo;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
        BEGIN
            ROLLBACK TRANSACTION;
        END;

        THROW;
    END CATCH;
END;
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER OFF
GO


CREATE   PROCEDURE dbo.Preventivi_Varianti_Crea
    @IdPreventivo INT,
    @CodiceVariante NVARCHAR(60),
    @DescrizioneVariante NVARCHAR(500),
    @Note NVARCHAR(MAX) = NULL,
    @VarianteScelta BIT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @IdVariantePreventivo INT;

    BEGIN TRY
        BEGIN TRANSACTION;

        IF NOT EXISTS
        (
            SELECT 1
            FROM dbo.Preventivi
            WHERE IdPreventivo = @IdPreventivo
        )
        BEGIN
            THROW 51952, 'Preventivo non trovato.', 1;
        END;

        IF @VarianteScelta = 1
        BEGIN
            UPDATE dbo.PreventiviVarianti
            SET VarianteScelta = 0,
                DataModifica = SYSDATETIME()
            WHERE IdPreventivo = @IdPreventivo
              AND Attiva = 1
              AND VarianteScelta = 1;
        END;

        INSERT INTO dbo.PreventiviVarianti
        (
            IdPreventivo,
            CodiceVariante,
            DescrizioneVariante,
            Note,
            VarianteScelta,
            Attiva,
            TotaleCosti,
            TotaleVendita,
            MargineValore,
            MarginePerc,
            DataCreazione
        )
        VALUES
        (
            @IdPreventivo,
            @CodiceVariante,
            @DescrizioneVariante,
            @Note,
            @VarianteScelta,
            1,
            0,
            0,
            0,
            0,
            SYSDATETIME()
        );

        SET @IdVariantePreventivo = CONVERT(INT, SCOPE_IDENTITY());

        EXEC dbo.sp_RicalcolaTotaliVariante
            @IdVariantePreventivo = @IdVariantePreventivo;

        EXEC dbo.sp_RicalcolaTotaliPreventivo
            @IdPreventivo = @IdPreventivo;

        COMMIT TRANSACTION;

        SELECT @IdVariantePreventivo;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
        BEGIN
            ROLLBACK TRANSACTION;
        END;

        THROW;
    END CATCH;
END;
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE   PROCEDURE dbo.Preventivi_Varianti_Dettaglio
    @IdVariantePreventivo INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        IdVariantePreventivo,
        IdPreventivo,
        CodiceVariante,
        DescrizioneVariante,
        VarianteScelta,
        TotaleCosti,
        TotaleVendita,
        MargineValore,
        MarginePerc
    FROM dbo.PreventiviVarianti
    WHERE IdVariantePreventivo = @IdVariantePreventivo;
END;
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE   PROCEDURE dbo.Preventivi_Varianti_Elenco
    @IdPreventivo INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        IdVariantePreventivo,
        IdPreventivo,
        CodiceVariante,
        DescrizioneVariante,
        VarianteScelta,
        TotaleCosti,
        TotaleVendita,
        MargineValore,
        MarginePerc
    FROM dbo.PreventiviVarianti
    WHERE IdPreventivo = @IdPreventivo
      AND Attiva = 1
    ORDER BY CodiceVariante, IdVariantePreventivo;
END;
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER OFF
GO


CREATE   PROCEDURE dbo.Preventivi_Varianti_Elimina
    @IdVariantePreventivo INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @IdPreventivo INT;

    BEGIN TRY
        BEGIN TRANSACTION;

        SELECT @IdPreventivo = IdPreventivo
        FROM dbo.PreventiviVarianti
        WHERE IdVariantePreventivo = @IdVariantePreventivo
          AND Attiva = 1;

        IF @IdPreventivo IS NULL
        BEGIN
            THROW 51954, 'Variante preventivo non trovata o non attiva.', 1;
        END;

        UPDATE dbo.PreventiviVarianti
        SET VarianteScelta = 0,
            Attiva = 0,
            DataModifica = SYSDATETIME()
        WHERE IdVariantePreventivo = @IdVariantePreventivo;

        EXEC dbo.sp_RicalcolaTotaliPreventivo
            @IdPreventivo = @IdPreventivo;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
        BEGIN
            ROLLBACK TRANSACTION;
        END;

        THROW;
    END CATCH;
END;
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER OFF
GO


CREATE   PROCEDURE dbo.Preventivi_Varianti_Seleziona
    @IdVariantePreventivo INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @IdPreventivo INT;

    BEGIN TRY
        BEGIN TRANSACTION;

        SELECT @IdPreventivo = IdPreventivo
        FROM dbo.PreventiviVarianti
        WHERE IdVariantePreventivo = @IdVariantePreventivo
          AND Attiva = 1;

        IF @IdPreventivo IS NULL
        BEGIN
            THROW 51953, 'Variante preventivo non trovata o non attiva.', 1;
        END;

        UPDATE dbo.PreventiviVarianti
        SET VarianteScelta =
                CASE
                    WHEN IdVariantePreventivo = @IdVariantePreventivo THEN 1
                    ELSE 0
                END,
            DataModifica = SYSDATETIME()
        WHERE IdPreventivo = @IdPreventivo
          AND Attiva = 1;

        EXEC dbo.sp_RicalcolaTotaliVariante
            @IdVariantePreventivo = @IdVariantePreventivo;

        EXEC dbo.sp_RicalcolaTotaliPreventivo
            @IdPreventivo = @IdPreventivo;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
        BEGIN
            ROLLBACK TRANSACTION;
        END;

        THROW;
    END CATCH;
END;
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE   PROCEDURE dbo.sp_AggiornaStatoPreventivo
    @IdPreventivo INT,
    @NuovoStato NVARCHAR(30)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @IdRichiestaCliente INT;

    UPDATE dbo.Preventivi
    SET Stato = @NuovoStato,
        DataModifica = SYSDATETIME()
    WHERE IdPreventivo = @IdPreventivo;

    SELECT @IdRichiestaCliente = IdRichiestaCliente
    FROM dbo.Preventivi
    WHERE IdPreventivo = @IdPreventivo;

    IF @IdRichiestaCliente IS NOT NULL
    BEGIN
        IF @NuovoStato = 'Accettato'
        BEGIN
            UPDATE dbo.RichiesteClienti
            SET Stato = 'Confermata',
                DataChiusura = CAST(GETDATE() AS DATE),
                DataModifica = SYSDATETIME()
            WHERE IdRichiestaCliente = @IdRichiestaCliente;
        END

        IF @NuovoStato = 'Respinto'
        BEGIN
            UPDATE dbo.RichiesteClienti
            SET Stato = 'Persa',
                DataChiusura = CAST(GETDATE() AS DATE),
                DataModifica = SYSDATETIME()
            WHERE IdRichiestaCliente = @IdRichiestaCliente;
        END

        IF @NuovoStato = 'Inviato'
        BEGIN
            UPDATE dbo.RichiesteClienti
            SET Stato = 'Preventivata',
                DataModifica = SYSDATETIME()
            WHERE IdRichiestaCliente = @IdRichiestaCliente;
        END
    END
END;
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE   PROCEDURE dbo.sp_ApplicaModelloCicloARigaPreventivo
    @IdRigaPreventivo INT,
    @IdModelloCiclo INT,
    @SovrascriviLavorazioni BIT = 1,
    @AggiornaIdModelloCicloSuRiga BIT = 1
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @QuantitaRiga DECIMAL(18,4);

    IF NOT EXISTS
    (
        SELECT 1
        FROM dbo.PreventiviRighe
        WHERE IdRigaPreventivo = @IdRigaPreventivo
    )
    BEGIN
        RAISERROR('IdRigaPreventivo non trovato.', 16, 1);
        RETURN;
    END

    IF NOT EXISTS
    (
        SELECT 1
        FROM dbo.ModelliCiclo
        WHERE IdModelloCiclo = @IdModelloCiclo
    )
    BEGIN
        RAISERROR('IdModelloCiclo non trovato.', 16, 1);
        RETURN;
    END

    SELECT @QuantitaRiga = Quantita
    FROM dbo.PreventiviRighe
    WHERE IdRigaPreventivo = @IdRigaPreventivo;

    IF @AggiornaIdModelloCicloSuRiga = 1
    BEGIN
        UPDATE dbo.PreventiviRighe
           SET IdModelloCiclo = @IdModelloCiclo,
               DataModifica = SYSDATETIME()
         WHERE IdRigaPreventivo = @IdRigaPreventivo;
    END

    IF @SovrascriviLavorazioni = 1
    BEGIN
        DELETE FROM dbo.PreventiviRigheLavorazioni
        WHERE IdRigaPreventivo = @IdRigaPreventivo;
    END

    INSERT INTO dbo.PreventiviRigheLavorazioni
    (
        IdRigaPreventivo,
        IdNodoDistinta,
        IdLavorazione,
        DescrizioneLavorazione,
        Sequenza,
        TempoSetupMin,
        TempoPezzoMin,
        Quantita,
        TempoTotaleMin,
        CostoOrario,
        CostoFisso,
        CostoTotale,
        DaAcquistareEsterno,
        IdFornitoreSuggerito
    )
    SELECT
        @IdRigaPreventivo,
        NULL,
        r.IdLavorazione,
        l.Descrizione,
        r.Sequenza,
        r.TempoSetupMin,
        r.TempoPezzoMin,
        @QuantitaRiga,
        (r.TempoSetupMin + (r.TempoPezzoMin * @QuantitaRiga)),
        r.CostoOrario,
        r.CostoFisso,
        ROUND((((r.TempoSetupMin + (r.TempoPezzoMin * @QuantitaRiga)) / 60.0) * r.CostoOrario) + r.CostoFisso, 2),
        l.AcquistabileEsterna,
        l.IdFornitorePredefinito
    FROM dbo.ModelliCicloRighe r
    INNER JOIN dbo.Lavorazioni l
        ON r.IdLavorazione = l.IdLavorazione
    WHERE r.IdModelloCiclo = @IdModelloCiclo
    ORDER BY r.Sequenza, r.RigaNr;

    EXEC dbo.sp_RicalcolaTotaliRigaPreventivo
        @IdRigaPreventivo = @IdRigaPreventivo;
END
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE   PROCEDURE dbo.sp_ApplicaOffertaFornitoreAlPreventivo
    @IdRichiestaOfferta INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @IdPreventivo INT;

    SELECT @IdPreventivo = IdPreventivo
    FROM dbo.RichiesteOffertaFornitori
    WHERE IdRichiestaOfferta = @IdRichiestaOfferta;

    UPDATE pm
       SET pm.CostoUnitario = r.PrezzoOfferto,
           pm.CostoTotale = ROUND(pm.Quantita * r.PrezzoOfferto, 2),
           pm.IdFornitoreSuggerito = ro.IdFornitore
    FROM dbo.PreventiviRigheMateriali pm
    INNER JOIN dbo.RichiesteOffertaFornitoriRighe r
        ON pm.IdRigaMatPrev = r.IdRigaMatPrev
    INNER JOIN dbo.RichiesteOffertaFornitori ro
        ON r.IdRichiestaOfferta = ro.IdRichiestaOfferta
    WHERE r.IdRichiestaOfferta = @IdRichiestaOfferta
      AND r.Accettata = 1
      AND r.PrezzoOfferto > 0;

    UPDATE dbo.RichiesteOffertaFornitoriRighe
       SET TotaleOfferto = ROUND(Quantita * PrezzoOfferto, 2)
     WHERE IdRichiestaOfferta = @IdRichiestaOfferta;

    UPDATE dbo.RichiesteOffertaFornitori
       SET Stato = 'Accettata',
           DataRisposta = ISNULL(DataRisposta, CAST(GETDATE() AS DATE)),
           TotaleOfferta =
           (
                SELECT ISNULL(SUM(TotaleOfferto), 0)
                FROM dbo.RichiesteOffertaFornitoriRighe
                WHERE IdRichiestaOfferta = @IdRichiestaOfferta
                  AND Accettata = 1
           )
     WHERE IdRichiestaOfferta = @IdRichiestaOfferta;

    DECLARE @IdRigaPreventivo INT;

    DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
        SELECT DISTINCT IdRigaPreventivo
        FROM dbo.RichiesteOffertaFornitoriRighe
        WHERE IdRichiestaOfferta = @IdRichiestaOfferta
          AND Accettata = 1
          AND IdRigaPreventivo IS NOT NULL;

    OPEN cur;
    FETCH NEXT FROM cur INTO @IdRigaPreventivo;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        EXEC dbo.sp_RicalcolaTotaliRigaPreventivo
            @IdRigaPreventivo = @IdRigaPreventivo;

        FETCH NEXT FROM cur INTO @IdRigaPreventivo;
    END

    CLOSE cur;
    DEALLOCATE cur;

    IF @IdPreventivo IS NOT NULL
        EXEC dbo.sp_RicalcolaTotaliPreventivo @IdPreventivo = @IdPreventivo;
END;
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



/* =========================================================
   CHIUDI CAMPIONATURA
   ========================================================= */

CREATE   PROCEDURE dbo.sp_ChiudiCampionatura
    @IdCampionatura INT,
    @Esito NVARCHAR(30)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS
    (
        SELECT 1
        FROM dbo.Campionature
        WHERE IdCampionatura = @IdCampionatura
    )
    BEGIN
        RAISERROR('Campionatura non trovata.', 16, 1);
        RETURN;
    END

    IF @Esito NOT IN ('Positivo','Positivo con modifiche','Negativo','Da rifare')
    BEGIN
        RAISERROR('Esito campionatura non valido.', 16, 1);
        RETURN;
    END

    UPDATE dbo.Campionature
       SET Stato = 'Chiusa',
           Esito = @Esito,
           DataChiusura = CAST(GETDATE() AS DATE),
           DataModifica = SYSDATETIME()
     WHERE IdCampionatura = @IdCampionatura;
END
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



/* =========================================================
   CREA ADEGUAMENTO PREVENTIVO DA RILIEVO
   ========================================================= */

CREATE   PROCEDURE dbo.sp_CreaAdeguamentoDaRilievo
    @IdRilievoCampionatura INT,
    @DescrizioneAdeguamento NVARCHAR(MAX),
    @ImpattoCostoStimato DECIMAL(18,2) = 0,
    @ImpattoVenditaStimato DECIMAL(18,2) = 0
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE
        @IdCampionatura INT,
        @IdPreventivo INT,
        @IdVariantePreventivo INT;

    SELECT
        @IdCampionatura = r.IdCampionatura,
        @IdPreventivo = c.IdPreventivo,
        @IdVariantePreventivo = c.IdVariantePreventivo
    FROM dbo.CampionatureRilievi r
    INNER JOIN dbo.Campionature c
        ON r.IdCampionatura = c.IdCampionatura
    WHERE r.IdRilievoCampionatura = @IdRilievoCampionatura;

    IF @IdCampionatura IS NULL
    BEGIN
        RAISERROR('Rilievo campionatura non trovato.', 16, 1);
        RETURN;
    END

    INSERT INTO dbo.CampionatureAdeguamentiPreventivo
    (
        IdCampionatura,
        IdRilievoCampionatura,
        IdPreventivo,
        IdVariantePreventivo,
        DescrizioneAdeguamento,
        ImpattoCostoStimato,
        ImpattoVenditaStimato,
        Applicato
    )
    VALUES
    (
        @IdCampionatura,
        @IdRilievoCampionatura,
        @IdPreventivo,
        @IdVariantePreventivo,
        @DescrizioneAdeguamento,
        ISNULL(@ImpattoCostoStimato, 0),
        ISNULL(@ImpattoVenditaStimato, 0),
        0
    );

    UPDATE dbo.CampionatureRilievi
       SET RichiedeAdeguamentoPreventivo = 1,
           Stato = 'Soluzione Proposta'
     WHERE IdRilievoCampionatura = @IdRilievoCampionatura;
END
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


/* =========================================================
   CREA CAMPIONATURA DA RICHIESTA CLIENTE
   ========================================================= */

CREATE   PROCEDURE dbo.sp_CreaCampionaturaDaRichiesta
    @IdRichiestaCliente INT,
    @IdPreventivo INT = NULL,
    @IdVariantePreventivo INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE
        @NumeroCampionatura INT,
        @Anno INT,
        @IdCliente INT,
        @Oggetto NVARCHAR(250),
        @Priorita NVARCHAR(20);

    IF NOT EXISTS
    (
        SELECT 1
        FROM dbo.RichiesteClienti
        WHERE IdRichiestaCliente = @IdRichiestaCliente
    )
    BEGIN
        RAISERROR('Richiesta cliente non trovata.', 16, 1);
        RETURN;
    END

    SET @Anno = YEAR(GETDATE());

    SELECT
        @NumeroCampionatura = ISNULL(MAX(NumeroCampionatura), 0) + 1
    FROM dbo.Campionature
    WHERE Anno = @Anno;

    SELECT
        @IdCliente = IdCliente,
        @Oggetto = Oggetto,
        @Priorita = Priorita
    FROM dbo.RichiesteClienti
    WHERE IdRichiestaCliente = @IdRichiestaCliente;

    INSERT INTO dbo.Campionature
    (
        NumeroCampionatura,
        Anno,
        DataCampionatura,
        IdRichiestaCliente,
        IdPreventivo,
        IdVariantePreventivo,
        Oggetto,
        DescrizioneCampione,
        Stato,
        Priorita,
        DataRichiestaCampione
    )
    VALUES
    (
        @NumeroCampionatura,
        @Anno,
        CAST(GETDATE() AS DATE),
        @IdRichiestaCliente,
        @IdPreventivo,
        @IdVariantePreventivo,
        @Oggetto,
        NULL,
        'Aperta',
        ISNULL(@Priorita, 'Media'),
        CAST(GETDATE() AS DATE)
    );

    UPDATE dbo.RichiesteClienti
       SET Stato = 'In Valutazione',
           DataAttivazione = ISNULL(DataAttivazione, CAST(GETDATE() AS DATE)),
           DataModifica = SYSDATETIME()
     WHERE IdRichiestaCliente = @IdRichiestaCliente;
END
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


/* =========================================================
   STORED PROCEDURE: CREA PREVENTIVO DA MODELLO
   ========================================================= */

CREATE   PROCEDURE dbo.sp_CreaPreventivoDaModello
    @IdModelloPreventivo INT,
    @NumeroPreventivo INT,
    @Anno INT,
    @DataPreventivo DATE,
    @IdCliente INT = NULL,
    @Oggetto NVARCHAR(250) = NULL,
    @IdPreventivoCreato INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.Preventivi
    (
        NumeroPreventivo,
        Anno,
        DataPreventivo,
        IdCliente,
        IdModelloPreventivo,
        Oggetto,
        Note,
        Stato
    )
    SELECT
        @NumeroPreventivo,
        @Anno,
        @DataPreventivo,
        COALESCE(@IdCliente, mp.IdCliente),
        mp.IdModelloPreventivo,
        COALESCE(@Oggetto, mp.Oggetto),
        mp.Note,
        'Bozza'
    FROM dbo.ModelliPreventivo mp
    WHERE mp.IdModelloPreventivo = @IdModelloPreventivo;

    SET @IdPreventivoCreato = SCOPE_IDENTITY();

    INSERT INTO dbo.PreventiviRighe
    (
        IdPreventivo,
        RigaNr,
        IdArticolo,
        IdModelloCiclo,
        DescrizioneVoce,
        Quantita,
        PrezzoUnitarioVendita,
        TotaleVendita,
        TotaleCosti,
        MargineValore,
        MarginePerc,
        Note
    )
    SELECT
        @IdPreventivoCreato,
        mr.RigaNr,
        mr.IdArticolo,
        mr.IdModelloCiclo,
        mr.DescrizioneVoce,
        mr.Quantita,
        mr.PrezzoUnitarioVendita,
        0, 0, 0, 0,
        mr.Note
    FROM dbo.ModelliPreventivoRighe mr
    WHERE mr.IdModelloPreventivo = @IdModelloPreventivo
    ORDER BY mr.RigaNr;

    EXEC dbo.sp_RicalcolaTotaliPreventivo @IdPreventivo = @IdPreventivoCreato;
END
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE   PROCEDURE dbo.sp_CreaPreventivoDaRichiesta
    @IdRichiestaCliente INT,
    @NumeroPreventivo INT,
    @Anno INT,
    @DataPreventivo DATE,
    @IdPreventivoCreato INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @IdCliente INT;
    DECLARE @Oggetto NVARCHAR(250);

    SELECT
        @IdCliente = IdCliente,
        @Oggetto = Oggetto
    FROM dbo.RichiesteClienti
    WHERE IdRichiestaCliente = @IdRichiestaCliente;

    INSERT INTO dbo.Preventivi
    (
        NumeroPreventivo,
        Anno,
        DataPreventivo,
        IdCliente,
        IdRichiestaCliente,
        Oggetto,
        Stato
    )
    VALUES
    (
        @NumeroPreventivo,
        @Anno,
        @DataPreventivo,
        @IdCliente,
        @IdRichiestaCliente,
        @Oggetto,
        'Bozza'
    );

    SET @IdPreventivoCreato = SCOPE_IDENTITY();

    UPDATE dbo.RichiesteClienti
    SET Stato = 'Preventivata',
        DataAttivazione = ISNULL(DataAttivazione, CAST(GETDATE() AS DATE)),
        DataModifica = SYSDATETIME()
    WHERE IdRichiestaCliente = @IdRichiestaCliente;
END;
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE   PROCEDURE dbo.sp_CreaRichiestaDaPreventivo
    @IdPreventivo INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE
        @IdCliente INT,
        @Oggetto NVARCHAR(250),
        @NumeroRichiesta INT,
        @Anno INT,
        @IdRichiestaCliente INT;

    IF NOT EXISTS
    (
        SELECT 1
        FROM dbo.Preventivi
        WHERE IdPreventivo = @IdPreventivo
    )
    BEGIN
        RAISERROR('Preventivo non trovato.', 16, 1);
        RETURN;
    END

    SELECT
        @IdCliente = IdCliente,
        @Oggetto = Oggetto
    FROM dbo.Preventivi
    WHERE IdPreventivo = @IdPreventivo;

    SET @Anno = YEAR(GETDATE());

    SELECT @NumeroRichiesta = ISNULL(MAX(NumeroRichiesta), 0) + 1
    FROM dbo.RichiesteClienti
    WHERE Anno = @Anno;

    INSERT INTO dbo.RichiesteClienti
    (
        NumeroRichiesta,
        Anno,
        DataRichiesta,
        IdCliente,
        Oggetto,
        DescrizioneRichiesta,
        Stato,
        Priorita,
        InteresseCliente,
        DataAttivazione
    )
    VALUES
    (
        @NumeroRichiesta,
        @Anno,
        CAST(GETDATE() AS DATE),
        @IdCliente,
        ISNULL(@Oggetto, 'Richiesta generata da preventivo'),
        'Richiesta generata automaticamente dal preventivo ' + CAST(@IdPreventivo AS NVARCHAR(20)),
        'Preventivata',
        'Media',
        'Medio',
        CAST(GETDATE() AS DATE)
    );

    SET @IdRichiestaCliente = SCOPE_IDENTITY();

    UPDATE dbo.Preventivi
    SET IdRichiestaCliente = @IdRichiestaCliente,
        DataModifica = SYSDATETIME()
    WHERE IdPreventivo = @IdPreventivo;
END;
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE   PROCEDURE dbo.sp_CreaRichiestaOffertaFornitoreDaPreventivo
    @IdPreventivo INT,
    @IdFornitore INT,
    @Anno INT,
    @DataRichiesta DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @DataRichiesta IS NULL
        SET @DataRichiesta = CAST(GETDATE() AS DATE);

    DECLARE
        @NumeroRichiesta INT,
        @IdRichiestaOfferta INT;

    SELECT @NumeroRichiesta = ISNULL(MAX(NumeroRichiesta),0) + 1
    FROM dbo.RichiesteOffertaFornitori
    WHERE Anno = @Anno;

    INSERT INTO dbo.RichiesteOffertaFornitori
    (
        NumeroRichiesta,
        Anno,
        DataRichiesta,
        IdFornitore,
        IdPreventivo,
        Oggetto,
        Stato
    )
    VALUES
    (
        @NumeroRichiesta,
        @Anno,
        @DataRichiesta,
        @IdFornitore,
        @IdPreventivo,
        N'Richiesta offerta materiali per preventivo ' + CAST(@IdPreventivo AS NVARCHAR(20)),
        'Bozza'
    );

    SET @IdRichiestaOfferta = SCOPE_IDENTITY();

    INSERT INTO dbo.RichiesteOffertaFornitoriRighe
    (
        IdRichiestaOfferta,
        RigaNr,
        IdRigaPreventivo,
        IdRigaMatPrev,
        IdMateriale,
        DescrizioneMateriale,
        UM,
        Quantita,
        PrezzoRichiesto,
        PrezzoOfferto,
        TotaleOfferto
    )
    SELECT
        @IdRichiestaOfferta,
        ROW_NUMBER() OVER (ORDER BY pr.RigaNr, pm.DescrizioneMateriale),
        pm.IdRigaPreventivo,
        pm.IdRigaMatPrev,
        pm.IdMateriale,
        pm.DescrizioneMateriale,
        pm.UM,
        pm.Quantita,
        pm.CostoUnitario,
        0,
        0
    FROM dbo.PreventiviRigheMateriali pm
    INNER JOIN dbo.PreventiviRighe pr
        ON pm.IdRigaPreventivo = pr.IdRigaPreventivo
    WHERE pr.IdPreventivo = @IdPreventivo
      AND pm.DaAcquistare = 1
      AND
      (
          pm.IdFornitoreSuggerito = @IdFornitore
          OR pm.IdFornitoreSuggerito IS NULL
      );

    IF NOT EXISTS
    (
        SELECT 1
        FROM dbo.RichiesteOffertaFornitoriRighe
        WHERE IdRichiestaOfferta = @IdRichiestaOfferta
    )
    BEGIN
        DELETE FROM dbo.RichiesteOffertaFornitori
        WHERE IdRichiestaOfferta = @IdRichiestaOfferta;

        RAISERROR('Nessun materiale da richiedere a questo fornitore.',16,1);
        RETURN;
    END
END;
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE   PROCEDURE dbo.sp_CreaVarianteDaAdeguamentoCampionatura
    @IdAdeguamento INT,
    @CodiceNuovaVariante NVARCHAR(30),
    @DescrizioneNuovaVariante NVARCHAR(250)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE
        @IdPreventivo INT,
        @IdVarianteOrigine INT,
        @IdNuovaVariante INT,
        @OldIdRiga INT,
        @NewIdRiga INT;

    SELECT
        @IdPreventivo = IdPreventivo,
        @IdVarianteOrigine = IdVariantePreventivo
    FROM dbo.CampionatureAdeguamentiPreventivo
    WHERE IdAdeguamento = @IdAdeguamento;

    IF @IdPreventivo IS NULL
    BEGIN
        RAISERROR('Adeguamento non collegato a un preventivo.', 16, 1);
        RETURN;
    END

    IF EXISTS
    (
        SELECT 1
        FROM dbo.PreventiviVarianti
        WHERE IdPreventivo = @IdPreventivo
          AND CodiceVariante = @CodiceNuovaVariante
    )
    BEGIN
        RAISERROR('Codice variante già esistente per questo preventivo.', 16, 1);
        RETURN;
    END

    CREATE TABLE #MappaRighe
    (
        OldIdRigaPreventivo INT NOT NULL,
        NewIdRigaPreventivo INT NOT NULL
    );

    INSERT INTO dbo.PreventiviVarianti
    (
        IdPreventivo,
        CodiceVariante,
        DescrizioneVariante,
        VarianteScelta,
        Attiva
    )
    VALUES
    (
        @IdPreventivo,
        @CodiceNuovaVariante,
        @DescrizioneNuovaVariante,
        0,
        1
    );

    SET @IdNuovaVariante = SCOPE_IDENTITY();

    DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
        SELECT IdRigaPreventivo
        FROM dbo.PreventiviRighe
        WHERE IdPreventivo = @IdPreventivo
          AND
          (
              @IdVarianteOrigine IS NULL
              OR IdVariantePreventivo = @IdVarianteOrigine
          )
        ORDER BY RigaNr;

    OPEN cur;
    FETCH NEXT FROM cur INTO @OldIdRiga;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        INSERT INTO dbo.PreventiviRighe
        (
            IdPreventivo,
            IdVariantePreventivo,
            RigaNr,
            IdArticolo,
            IdModelloCiclo,
            DescrizioneVoce,
            Quantita,
            PrezzoUnitarioVendita,
            TotaleVendita,
            TotaleCosti,
            MargineValore,
            MarginePerc,
            MarkupPerc,
            PrezzoManuale,
            Note
        )
        SELECT
            IdPreventivo,
            @IdNuovaVariante,
            RigaNr,
            IdArticolo,
            IdModelloCiclo,
            DescrizioneVoce,
            Quantita,
            PrezzoUnitarioVendita,
            TotaleVendita,
            TotaleCosti,
            MargineValore,
            MarginePerc,
            MarkupPerc,
            PrezzoManuale,
            ISNULL(Note,'') + CHAR(13) + CHAR(10) + 'Variante generata da adeguamento campionatura'
        FROM dbo.PreventiviRighe
        WHERE IdRigaPreventivo = @OldIdRiga;

        SET @NewIdRiga = SCOPE_IDENTITY();

        INSERT INTO #MappaRighe
        (
            OldIdRigaPreventivo,
            NewIdRigaPreventivo
        )
        VALUES
        (
            @OldIdRiga,
            @NewIdRiga
        );

        INSERT INTO dbo.PreventiviRigheComponenti
        (
            IdRigaPreventivo,
            IdNodoDistinta,
            IdNodoPadre,
            DescrizioneNodo,
            Livello,
            QuantitaBase,
            QuantitaCalcolata,
            OrdineVisualizzazione
        )
        SELECT
            @NewIdRiga,
            IdNodoDistinta,
            IdNodoPadre,
            DescrizioneNodo,
            Livello,
            QuantitaBase,
            QuantitaCalcolata,
            OrdineVisualizzazione
        FROM dbo.PreventiviRigheComponenti
        WHERE IdRigaPreventivo = @OldIdRiga;

        INSERT INTO dbo.PreventiviRigheMateriali
        (
            IdRigaPreventivo,
            IdNodoDistinta,
            IdMateriale,
            DescrizioneMateriale,
            TipoMateriale,
            UM,
            Quantita,
            CostoUnitario,
            CostoTotale,
            DaAcquistare,
            IdFornitoreSuggerito
        )
        SELECT
            @NewIdRiga,
            IdNodoDistinta,
            IdMateriale,
            DescrizioneMateriale,
            TipoMateriale,
            UM,
            Quantita,
            CostoUnitario,
            CostoTotale,
            DaAcquistare,
            IdFornitoreSuggerito
        FROM dbo.PreventiviRigheMateriali
        WHERE IdRigaPreventivo = @OldIdRiga;

        INSERT INTO dbo.PreventiviRigheLavorazioni
        (
            IdRigaPreventivo,
            IdNodoDistinta,
            IdLavorazione,
            DescrizioneLavorazione,
            Sequenza,
            TempoSetupMin,
            TempoPezzoMin,
            Quantita,
            TempoTotaleMin,
            CostoOrario,
            CostoFisso,
            CostoTotale,
            DaAcquistareEsterno,
            IdFornitoreSuggerito
        )
        SELECT
            @NewIdRiga,
            IdNodoDistinta,
            IdLavorazione,
            DescrizioneLavorazione,
            Sequenza,
            TempoSetupMin,
            TempoPezzoMin,
            Quantita,
            TempoTotaleMin,
            CostoOrario,
            CostoFisso,
            CostoTotale,
            DaAcquistareEsterno,
            IdFornitoreSuggerito
        FROM dbo.PreventiviRigheLavorazioni
        WHERE IdRigaPreventivo = @OldIdRiga;

        EXEC dbo.sp_RicalcolaTotaliRigaPreventivo
            @IdRigaPreventivo = @NewIdRiga;

        FETCH NEXT FROM cur INTO @OldIdRiga;
    END

    CLOSE cur;
    DEALLOCATE cur;

    UPDATE dbo.CampionatureAdeguamentiPreventivo
       SET Applicato = 1,
           DataApplicazione = CAST(GETDATE() AS DATE),
           IdVariantePreventivo = @IdNuovaVariante
     WHERE IdAdeguamento = @IdAdeguamento;

    EXEC dbo.sp_RicalcolaTotaliVariante
        @IdVariantePreventivo = @IdNuovaVariante;

    EXEC dbo.sp_RicalcolaTotaliPreventivo
        @IdPreventivo = @IdPreventivo;
END
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE   PROCEDURE dbo.sp_DuplicaRigaPreventivo
    @IdRigaPreventivoOrigine INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE
        @IdPreventivo INT,
        @NuovaRigaNr INT,
        @IdRigaPreventivoNuova INT;

    SELECT @IdPreventivo = IdPreventivo
    FROM dbo.PreventiviRighe
    WHERE IdRigaPreventivo = @IdRigaPreventivoOrigine;

    IF @IdPreventivo IS NULL
    BEGIN
        RAISERROR('Riga preventivo origine non trovata.', 16, 1);
        RETURN;
    END

    SELECT @NuovaRigaNr = ISNULL(MAX(RigaNr), 0) + 1
    FROM dbo.PreventiviRighe
    WHERE IdPreventivo = @IdPreventivo;

    INSERT INTO dbo.PreventiviRighe
    (
        IdPreventivo,
        RigaNr,
        IdArticolo,
        IdModelloCiclo,
        DescrizioneVoce,
        Quantita,
        PrezzoUnitarioVendita,
        TotaleVendita,
        TotaleCosti,
        MargineValore,
        MarginePerc,
        MarkupPerc,
        PrezzoManuale,
        Note
    )
    SELECT
        IdPreventivo,
        @NuovaRigaNr,
        IdArticolo,
        IdModelloCiclo,
        DescrizioneVoce + N' - copia',
        Quantita,
        PrezzoUnitarioVendita,
        TotaleVendita,
        TotaleCosti,
        MargineValore,
        MarginePerc,
        MarkupPerc,
        PrezzoManuale,
        Note
    FROM dbo.PreventiviRighe
    WHERE IdRigaPreventivo = @IdRigaPreventivoOrigine;

    SET @IdRigaPreventivoNuova = SCOPE_IDENTITY();

    INSERT INTO dbo.PreventiviRigheComponenti
    (
        IdRigaPreventivo,
        IdNodoDistinta,
        IdNodoPadre,
        DescrizioneNodo,
        Livello,
        QuantitaBase,
        QuantitaCalcolata,
        OrdineVisualizzazione
    )
    SELECT
        @IdRigaPreventivoNuova,
        IdNodoDistinta,
        IdNodoPadre,
        DescrizioneNodo,
        Livello,
        QuantitaBase,
        QuantitaCalcolata,
        OrdineVisualizzazione
    FROM dbo.PreventiviRigheComponenti
    WHERE IdRigaPreventivo = @IdRigaPreventivoOrigine;

    INSERT INTO dbo.PreventiviRigheMateriali
    (
        IdRigaPreventivo,
        IdNodoDistinta,
        IdMateriale,
        DescrizioneMateriale,
        TipoMateriale,
        UM,
        Quantita,
        CostoUnitario,
        CostoTotale,
        DaAcquistare,
        IdFornitoreSuggerito
    )
    SELECT
        @IdRigaPreventivoNuova,
        IdNodoDistinta,
        IdMateriale,
        DescrizioneMateriale,
        TipoMateriale,
        UM,
        Quantita,
        CostoUnitario,
        CostoTotale,
        DaAcquistare,
        IdFornitoreSuggerito
    FROM dbo.PreventiviRigheMateriali
    WHERE IdRigaPreventivo = @IdRigaPreventivoOrigine;

    INSERT INTO dbo.PreventiviRigheLavorazioni
    (
        IdRigaPreventivo,
        IdNodoDistinta,
        IdLavorazione,
        DescrizioneLavorazione,
        Sequenza,
        TempoSetupMin,
        TempoPezzoMin,
        Quantita,
        TempoTotaleMin,
        CostoOrario,
        CostoFisso,
        CostoTotale,
        DaAcquistareEsterno,
        IdFornitoreSuggerito
    )
    SELECT
        @IdRigaPreventivoNuova,
        IdNodoDistinta,
        IdLavorazione,
        DescrizioneLavorazione,
        Sequenza,
        TempoSetupMin,
        TempoPezzoMin,
        Quantita,
        TempoTotaleMin,
        CostoOrario,
        CostoFisso,
        CostoTotale,
        DaAcquistareEsterno,
        IdFornitoreSuggerito
    FROM dbo.PreventiviRigheLavorazioni
    WHERE IdRigaPreventivo = @IdRigaPreventivoOrigine;

    EXEC dbo.sp_RicalcolaTotaliRigaPreventivo @IdRigaPreventivo = @IdRigaPreventivoNuova;
    EXEC dbo.sp_RicalcolaTotaliPreventivo @IdPreventivo = @IdPreventivo;
END
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE   PROCEDURE dbo.sp_EliminaOrdineFornitore
    @IdOrdineFornitore INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Stato NVARCHAR(30);

    SELECT @Stato = Stato
    FROM dbo.OrdiniFornitori
    WHERE IdOrdineFornitore = @IdOrdineFornitore;

    IF @Stato IS NULL
    BEGIN
        RAISERROR('Ordine fornitore non trovato.', 16, 1);
        RETURN;
    END

    IF @Stato <> 'Bozza'
    BEGIN
        RAISERROR('Impossibile eliminare l''ordine: l''ordine non è in stato Bozza.', 16, 1);
        RETURN;
    END

    DELETE FROM dbo.OrdiniFornitoriRighe
    WHERE IdOrdineFornitore = @IdOrdineFornitore;

    DELETE FROM dbo.OrdiniFornitori
    WHERE IdOrdineFornitore = @IdOrdineFornitore;
END
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE   PROCEDURE dbo.sp_EliminaRigaOrdineFornitore
    @IdRigaOrdineFornitore INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @IdOrdineFornitore INT;
    DECLARE @Stato NVARCHAR(30);

    SELECT
        @IdOrdineFornitore = r.IdOrdineFornitore,
        @Stato = o.Stato
    FROM dbo.OrdiniFornitoriRighe r
    INNER JOIN dbo.OrdiniFornitori o
        ON r.IdOrdineFornitore = o.IdOrdineFornitore
    WHERE r.IdRigaOrdineFornitore = @IdRigaOrdineFornitore;

    IF @IdOrdineFornitore IS NULL
    BEGIN
        RAISERROR('Riga ordine fornitore non trovata.', 16, 1);
        RETURN;
    END

    IF @Stato <> 'Bozza'
    BEGIN
        RAISERROR('Impossibile eliminare la riga: l''ordine non è in stato Bozza.', 16, 1);
        RETURN;
    END

    DELETE FROM dbo.OrdiniFornitoriRighe
    WHERE IdRigaOrdineFornitore = @IdRigaOrdineFornitore;

    EXEC dbo.sp_RicalcolaTotaliOrdineFornitore
        @IdOrdineFornitore = @IdOrdineFornitore;
END
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE   PROCEDURE dbo.sp_EliminaRigaPreventivo
    @IdRigaPreventivo INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @IdPreventivo INT;

    SELECT @IdPreventivo = IdPreventivo
    FROM dbo.PreventiviRighe
    WHERE IdRigaPreventivo = @IdRigaPreventivo;

    IF @IdPreventivo IS NULL
    BEGIN
        RAISERROR('Riga preventivo non trovata.', 16, 1);
        RETURN;
    END

    IF EXISTS
    (
        SELECT 1
        FROM dbo.OrdiniFornitori o
        WHERE o.IdRigaPreventivo = @IdRigaPreventivo
          AND o.Stato IN ('Bozza','Inviato','Parziale')
    )
    BEGIN
        RAISERROR(
            'Impossibile eliminare la riga: esistono ordini fornitore aperti collegati.',
            16,
            1
        );
        RETURN;
    END

    IF EXISTS
    (
        SELECT 1
        FROM dbo.OrdiniFornitoriRighe r
        INNER JOIN dbo.OrdiniFornitori o
            ON r.IdOrdineFornitore = o.IdOrdineFornitore
        WHERE r.IdRigaPreventivo = @IdRigaPreventivo
          AND o.Stato IN ('Bozza','Inviato','Parziale')
    )
    BEGIN
        RAISERROR(
            'Impossibile eliminare la riga: esistono righe ordine fornitore aperte collegate.',
            16,
            1
        );
        RETURN;
    END

    DELETE r
    FROM dbo.OrdiniFornitoriRighe r
    INNER JOIN dbo.OrdiniFornitori o
        ON r.IdOrdineFornitore = o.IdOrdineFornitore
    WHERE r.IdRigaPreventivo = @IdRigaPreventivo
      AND o.Stato IN ('Annullato','Ricevuto');

    DELETE FROM dbo.PreventiviRigheLavorazioni
    WHERE IdRigaPreventivo = @IdRigaPreventivo;

    DELETE FROM dbo.PreventiviRigheMateriali
    WHERE IdRigaPreventivo = @IdRigaPreventivo;

    DELETE FROM dbo.PreventiviRigheComponenti
    WHERE IdRigaPreventivo = @IdRigaPreventivo;

    DELETE FROM dbo.PreventiviRighe
    WHERE IdRigaPreventivo = @IdRigaPreventivo;

    EXEC dbo.sp_RicalcolaTotaliPreventivo @IdPreventivo = @IdPreventivo;
END
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


/* =========================================================
   PROCEDURA: ESPLODI DISTINTA SU RIGA PREVENTIVO
   ========================================================= */

CREATE   PROCEDURE dbo.sp_EsplodiDistintaSuRigaPreventivo
    @IdRigaPreventivo INT,
    @SovrascriviSnapshot BIT = 1
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE
        @IdArticolo INT,
        @QuantitaRiga DECIMAL(18,4),
        @IdModelloCiclo INT;

    SELECT
        @IdArticolo = IdArticolo,
        @QuantitaRiga = Quantita,
        @IdModelloCiclo = IdModelloCiclo
    FROM dbo.PreventiviRighe
    WHERE IdRigaPreventivo = @IdRigaPreventivo;

    IF @IdArticolo IS NULL AND @IdModelloCiclo IS NULL
    BEGIN
        RAISERROR('La riga preventivo non ha né articolo né modello ciclo associato.', 16, 1);
        RETURN;
    END

    IF @SovrascriviSnapshot = 1
    BEGIN
        DELETE FROM dbo.PreventiviRigheComponenti
        WHERE IdRigaPreventivo = @IdRigaPreventivo;

        DELETE FROM dbo.PreventiviRigheMateriali
        WHERE IdRigaPreventivo = @IdRigaPreventivo;

        DELETE FROM dbo.PreventiviRigheLavorazioni
        WHERE IdRigaPreventivo = @IdRigaPreventivo;
    END

    /* =====================================================
       1) ESPLOSIONE COMPONENTI + MATERIALI + LAVORAZIONI DA DISTINTA
       ===================================================== */
    IF @IdArticolo IS NOT NULL
    BEGIN
        ;WITH DistintaCTE AS
        (
            SELECT
                n.IdNodoDistinta,
                n.IdNodoPadre,
                n.DescrizioneNodo,
                n.QuantitaBase,
                CAST(n.QuantitaBase AS DECIMAL(18,4)) AS QuantitaMoltiplicata,
                n.Livello,
                n.OrdineVisualizzazione
            FROM dbo.DistintaBaseNodi n
            WHERE n.IdArticolo = @IdArticolo
              AND n.IdNodoPadre IS NULL

            UNION ALL

            SELECT
                c.IdNodoDistinta,
                c.IdNodoPadre,
                c.DescrizioneNodo,
                c.QuantitaBase,
                CAST(p.QuantitaMoltiplicata * c.QuantitaBase AS DECIMAL(18,4)) AS QuantitaMoltiplicata,
                c.Livello,
                c.OrdineVisualizzazione
            FROM dbo.DistintaBaseNodi c
            INNER JOIN DistintaCTE p
                ON c.IdNodoPadre = p.IdNodoDistinta
        )
        INSERT INTO dbo.PreventiviRigheComponenti
        (
            IdRigaPreventivo,
            IdNodoDistinta,
            IdNodoPadre,
            DescrizioneNodo,
            Livello,
            QuantitaBase,
            QuantitaCalcolata,
            OrdineVisualizzazione
        )
        SELECT
            @IdRigaPreventivo,
            d.IdNodoDistinta,
            d.IdNodoPadre,
            d.DescrizioneNodo,
            d.Livello,
            d.QuantitaBase,
            d.QuantitaMoltiplicata * @QuantitaRiga,
            d.OrdineVisualizzazione
        FROM DistintaCTE d;

        ;WITH DistintaCTE AS
        (
            SELECT
                n.IdNodoDistinta,
                CAST(n.QuantitaBase AS DECIMAL(18,4)) AS QuantitaMoltiplicata
            FROM dbo.DistintaBaseNodi n
            WHERE n.IdArticolo = @IdArticolo
              AND n.IdNodoPadre IS NULL

            UNION ALL

            SELECT
                c.IdNodoDistinta,
                CAST(p.QuantitaMoltiplicata * c.QuantitaBase AS DECIMAL(18,4))
            FROM dbo.DistintaBaseNodi c
            INNER JOIN DistintaCTE p
                ON c.IdNodoPadre = p.IdNodoDistinta
        )
        INSERT INTO dbo.PreventiviRigheMateriali
        (
            IdRigaPreventivo,
            IdNodoDistinta,
            IdMateriale,
            DescrizioneMateriale,
            TipoMateriale,
            UM,
            Quantita,
            CostoUnitario,
            CostoTotale,
            DaAcquistare,
            IdFornitoreSuggerito
        )
        SELECT
            @IdRigaPreventivo,
            dm.IdNodoDistinta,
            m.IdMateriale,
            m.Descrizione,
            m.TipoMateriale,
            um.CodiceUM,
            ((dm.Quantita * (1 + (dm.CoeffScartoPerc / 100.0))) * d.QuantitaMoltiplicata) * @QuantitaRiga,
            m.CostoUnitario,
            ROUND((((dm.Quantita * (1 + (dm.CoeffScartoPerc / 100.0))) * d.QuantitaMoltiplicata) * @QuantitaRiga) * m.CostoUnitario, 2),
            m.GestitoAAcquisto,
            m.IdFornitorePredefinito
        FROM dbo.DistintaMateriali dm
        INNER JOIN DistintaCTE d
            ON dm.IdNodoDistinta = d.IdNodoDistinta
        INNER JOIN dbo.Materiali m
            ON dm.IdMateriale = m.IdMateriale
        INNER JOIN dbo.UnitaMisura um
            ON m.IdUM = um.IdUM;

        ;WITH DistintaCTE AS
        (
            SELECT
                n.IdNodoDistinta,
                CAST(n.QuantitaBase AS DECIMAL(18,4)) AS QuantitaMoltiplicata
            FROM dbo.DistintaBaseNodi n
            WHERE n.IdArticolo = @IdArticolo
              AND n.IdNodoPadre IS NULL

            UNION ALL

            SELECT
                c.IdNodoDistinta,
                CAST(p.QuantitaMoltiplicata * c.QuantitaBase AS DECIMAL(18,4))
            FROM dbo.DistintaBaseNodi c
            INNER JOIN DistintaCTE p
                ON c.IdNodoPadre = p.IdNodoDistinta
        )
        INSERT INTO dbo.PreventiviRigheLavorazioni
        (
            IdRigaPreventivo,
            IdNodoDistinta,
            IdLavorazione,
            DescrizioneLavorazione,
            Sequenza,
            TempoSetupMin,
            TempoPezzoMin,
            Quantita,
            TempoTotaleMin,
            CostoOrario,
            CostoFisso,
            CostoTotale,
            DaAcquistareEsterno,
            IdFornitoreSuggerito
        )
        SELECT
            @IdRigaPreventivo,
            dl.IdNodoDistinta,
            l.IdLavorazione,
            l.Descrizione,
            dl.Sequenza,
            dl.TempoSetupMin,
            dl.TempoPezzoMin,
            d.QuantitaMoltiplicata * @QuantitaRiga,
            (dl.TempoSetupMin + ((dl.TempoPezzoMin) * (d.QuantitaMoltiplicata * @QuantitaRiga))),
            dl.CostoOrario,
            dl.CostoFisso,
            ROUND((((dl.TempoSetupMin + ((dl.TempoPezzoMin) * (d.QuantitaMoltiplicata * @QuantitaRiga))) / 60.0) * dl.CostoOrario) + dl.CostoFisso, 2),
            l.AcquistabileEsterna,
            l.IdFornitorePredefinito
        FROM dbo.DistintaLavorazioni dl
        INNER JOIN DistintaCTE d
            ON dl.IdNodoDistinta = d.IdNodoDistinta
        INNER JOIN dbo.Lavorazioni l
            ON dl.IdLavorazione = l.IdLavorazione;
    END

    /* =====================================================
       2) SE NON C'È ARTICOLO MA C'È MODELLO CICLO, COPIA SOLO LAVORAZIONI
       ===================================================== */
    IF @IdArticolo IS NULL AND @IdModelloCiclo IS NOT NULL
    BEGIN
        INSERT INTO dbo.PreventiviRigheLavorazioni
        (
            IdRigaPreventivo,
            IdNodoDistinta,
            IdLavorazione,
            DescrizioneLavorazione,
            Sequenza,
            TempoSetupMin,
            TempoPezzoMin,
            Quantita,
            TempoTotaleMin,
            CostoOrario,
            CostoFisso,
            CostoTotale,
            DaAcquistareEsterno,
            IdFornitoreSuggerito
        )
        SELECT
            @IdRigaPreventivo,
            NULL,
            r.IdLavorazione,
            l.Descrizione,
            r.Sequenza,
            r.TempoSetupMin,
            r.TempoPezzoMin,
            @QuantitaRiga,
            (r.TempoSetupMin + (r.TempoPezzoMin * @QuantitaRiga)),
            r.CostoOrario,
            r.CostoFisso,
            ROUND((((r.TempoSetupMin + (r.TempoPezzoMin * @QuantitaRiga)) / 60.0) * r.CostoOrario) + r.CostoFisso, 2),
            l.AcquistabileEsterna,
            l.IdFornitorePredefinito
        FROM dbo.ModelliCicloRighe r
        INNER JOIN dbo.Lavorazioni l
            ON r.IdLavorazione = l.IdLavorazione
        WHERE r.IdModelloCiclo = @IdModelloCiclo;
    END

    EXEC dbo.sp_RicalcolaTotaliRigaPreventivo @IdRigaPreventivo = @IdRigaPreventivo;
END
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE   PROCEDURE dbo.sp_GeneraOrdineFornitoreDaRigaPreventivo
    @IdRigaPreventivo INT,
    @Anno INT,
    @DataOrdine DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @DataOrdine IS NULL
        SET @DataOrdine = CAST(GETDATE() AS DATE);

    DECLARE @IdPreventivo INT;

    SELECT @IdPreventivo = IdPreventivo
    FROM dbo.PreventiviRighe
    WHERE IdRigaPreventivo = @IdRigaPreventivo;

    IF @IdPreventivo IS NULL
    BEGIN
        RAISERROR('Riga preventivo non trovata.', 16, 1);
        RETURN;
    END

    /* BLOCCO DUPLICAZIONE ORDINI APERTI */
    IF EXISTS
    (
        SELECT 1
        FROM dbo.OrdiniFornitori
        WHERE IdRigaPreventivo = @IdRigaPreventivo
          AND Stato IN ('Bozza','Inviato','Parziale')
    )
    BEGIN
        RAISERROR(
            'Esistono già ordini fornitore aperti per questa riga preventivo. Gestire prima gli ordini esistenti.',
            16,
            1
        );
        RETURN;
    END

    IF OBJECT_ID('tempdb..#DaOrdinare') IS NOT NULL
        DROP TABLE #DaOrdinare;

    CREATE TABLE #DaOrdinare
    (
        IdFornitore INT NOT NULL,
        TipoRiga NVARCHAR(20) NOT NULL,
        IdMateriale INT NULL,
        IdLavorazione INT NULL,
        IdNodoDistinta INT NULL,
        Descrizione NVARCHAR(250) NOT NULL,
        UM NVARCHAR(10) NULL,
        Quantita DECIMAL(18,4) NOT NULL,
        PrezzoUnitario DECIMAL(18,4) NOT NULL
    );

    INSERT INTO #DaOrdinare
    (
        IdFornitore,
        TipoRiga,
        IdMateriale,
        IdLavorazione,
        IdNodoDistinta,
        Descrizione,
        UM,
        Quantita,
        PrezzoUnitario
    )
    SELECT
        COALESCE(pm.IdFornitoreSuggerito, fm.IdFornitore),
        'Materiale',
        pm.IdMateriale,
        NULL,
        pm.IdNodoDistinta,
        pm.DescrizioneMateriale,
        pm.UM,
        pm.Quantita,
        COALESCE(fm.PrezzoUnitario, pm.CostoUnitario, 0)
    FROM dbo.PreventiviRigheMateriali pm
    OUTER APPLY
    (
        SELECT TOP 1 fm.*
        FROM dbo.FornitoriMateriali fm
        WHERE fm.IdMateriale = pm.IdMateriale
          AND fm.Attivo = 1
        ORDER BY fm.FornitorePredefinito DESC, fm.IdFornitoreMateriale
    ) fm
    WHERE pm.IdRigaPreventivo = @IdRigaPreventivo
      AND pm.DaAcquistare = 1
      AND COALESCE(pm.IdFornitoreSuggerito, fm.IdFornitore) IS NOT NULL;

    INSERT INTO #DaOrdinare
    (
        IdFornitore,
        TipoRiga,
        IdMateriale,
        IdLavorazione,
        IdNodoDistinta,
        Descrizione,
        UM,
        Quantita,
        PrezzoUnitario
    )
    SELECT
        COALESCE(pl.IdFornitoreSuggerito, fl.IdFornitore),
        'Lavorazione',
        NULL,
        pl.IdLavorazione,
        pl.IdNodoDistinta,
        pl.DescrizioneLavorazione,
        'PZ',
        pl.Quantita,
        COALESCE(fl.PrezzoUnitario, 0)
    FROM dbo.PreventiviRigheLavorazioni pl
    OUTER APPLY
    (
        SELECT TOP 1 fl.*
        FROM dbo.FornitoriLavorazioni fl
        WHERE fl.IdLavorazione = pl.IdLavorazione
          AND fl.Attivo = 1
        ORDER BY fl.FornitorePredefinito DESC, fl.IdFornitoreLavorazione
    ) fl
    WHERE pl.IdRigaPreventivo = @IdRigaPreventivo
      AND pl.DaAcquistareEsterno = 1
      AND COALESCE(pl.IdFornitoreSuggerito, fl.IdFornitore) IS NOT NULL;

    IF NOT EXISTS (SELECT 1 FROM #DaOrdinare)
    BEGIN
        RAISERROR('Nessun materiale/lavorazione da ordinare per questa riga preventivo.', 16, 1);
        RETURN;
    END

    DECLARE @IdFornitore INT;
    DECLARE @IdOrdineFornitore INT;
    DECLARE @NumeroOrdine INT;

    DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
        SELECT DISTINCT IdFornitore
        FROM #DaOrdinare;

    OPEN cur;
    FETCH NEXT FROM cur INTO @IdFornitore;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        SELECT @NumeroOrdine = ISNULL(MAX(NumeroOrdine), 0) + 1
        FROM dbo.OrdiniFornitori
        WHERE Anno = @Anno;

        INSERT INTO dbo.OrdiniFornitori
        (
            NumeroOrdine,
            Anno,
            DataOrdine,
            IdFornitore,
            Oggetto,
            Stato,
            TotaleOrdine,
            IdPreventivo,
            IdRigaPreventivo
        )
        VALUES
        (
            @NumeroOrdine,
            @Anno,
            @DataOrdine,
            @IdFornitore,
            N'Ordine generato da riga preventivo ' + CAST(@IdRigaPreventivo AS NVARCHAR(20)),
            'Bozza',
            0,
            @IdPreventivo,
            @IdRigaPreventivo
        );

        SET @IdOrdineFornitore = SCOPE_IDENTITY();

        ;WITH RigheOrdine AS
        (
            SELECT
                ROW_NUMBER() OVER (ORDER BY TipoRiga, Descrizione) AS RigaNr,
                *
            FROM #DaOrdinare
            WHERE IdFornitore = @IdFornitore
        )
        INSERT INTO dbo.OrdiniFornitoriRighe
        (
            IdOrdineFornitore,
            RigaNr,
            TipoRiga,
            IdMateriale,
            IdLavorazione,
            IdNodoDistinta,
            IdRigaPreventivo,
            Descrizione,
            UM,
            Quantita,
            PrezzoUnitario,
            TotaleRiga,
            QuantitaRicevuta
        )
        SELECT
            @IdOrdineFornitore,
            RigaNr,
            TipoRiga,
            IdMateriale,
            IdLavorazione,
            IdNodoDistinta,
            @IdRigaPreventivo,
            Descrizione,
            UM,
            Quantita,
            PrezzoUnitario,
            ROUND(Quantita * PrezzoUnitario, 2),
            0
        FROM RigheOrdine;

        EXEC dbo.sp_RicalcolaTotaliOrdineFornitore
            @IdOrdineFornitore = @IdOrdineFornitore;

        FETCH NEXT FROM cur INTO @IdFornitore;
    END

    CLOSE cur;
    DEALLOCATE cur;
END
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE   PROCEDURE dbo.sp_GeneraOrdiniFornitoriDaPreventivo
    @IdPreventivo INT,
    @Anno INT,
    @DataOrdine DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @DataOrdine IS NULL
        SET @DataOrdine = CAST(GETDATE() AS DATE);

    IF NOT EXISTS
    (
        SELECT 1
        FROM dbo.Preventivi
        WHERE IdPreventivo = @IdPreventivo
    )
    BEGIN
        RAISERROR('Preventivo non trovato.', 16, 1);
        RETURN;
    END

    IF EXISTS
    (
        SELECT 1
        FROM dbo.OrdiniFornitori
        WHERE IdPreventivo = @IdPreventivo
          AND Stato IN ('Bozza','Inviato','Parziale')
    )
    BEGIN
        RAISERROR(
            'Esistono già ordini fornitore aperti per questo preventivo. Gestire prima gli ordini esistenti.',
            16,
            1
        );
        RETURN;
    END

    IF OBJECT_ID('tempdb..#DaOrdinare') IS NOT NULL
        DROP TABLE #DaOrdinare;

    CREATE TABLE #DaOrdinare
    (
        IdRigaPreventivo INT NOT NULL,
        IdFornitore INT NOT NULL,
        TipoRiga NVARCHAR(20) NOT NULL,
        IdMateriale INT NULL,
        IdLavorazione INT NULL,
        IdNodoDistinta INT NULL,
        Descrizione NVARCHAR(250) NOT NULL,
        UM NVARCHAR(10) NULL,
        Quantita DECIMAL(18,4) NOT NULL,
        PrezzoUnitario DECIMAL(18,4) NOT NULL
    );

    /* Materiali ordinabili */
    INSERT INTO #DaOrdinare
    (
        IdRigaPreventivo,
        IdFornitore,
        TipoRiga,
        IdMateriale,
        IdLavorazione,
        IdNodoDistinta,
        Descrizione,
        UM,
        Quantita,
        PrezzoUnitario
    )
    SELECT
        pm.IdRigaPreventivo,
        COALESCE(pm.IdFornitoreSuggerito, fm.IdFornitore),
        'Materiale',
        pm.IdMateriale,
        NULL,
        pm.IdNodoDistinta,
        pm.DescrizioneMateriale,
        pm.UM,
        pm.Quantita,
        COALESCE(fm.PrezzoUnitario, pm.CostoUnitario, 0)
    FROM dbo.PreventiviRigheMateriali pm
    INNER JOIN dbo.PreventiviRighe pr
        ON pm.IdRigaPreventivo = pr.IdRigaPreventivo
    OUTER APPLY
    (
        SELECT TOP 1 fm.*
        FROM dbo.FornitoriMateriali fm
        WHERE fm.IdMateriale = pm.IdMateriale
          AND fm.Attivo = 1
        ORDER BY fm.FornitorePredefinito DESC, fm.IdFornitoreMateriale
    ) fm
    WHERE pr.IdPreventivo = @IdPreventivo
      AND pm.DaAcquistare = 1
      AND COALESCE(pm.IdFornitoreSuggerito, fm.IdFornitore) IS NOT NULL;

    /* Lavorazioni esterne ordinabili */
    INSERT INTO #DaOrdinare
    (
        IdRigaPreventivo,
        IdFornitore,
        TipoRiga,
        IdMateriale,
        IdLavorazione,
        IdNodoDistinta,
        Descrizione,
        UM,
        Quantita,
        PrezzoUnitario
    )
    SELECT
        pl.IdRigaPreventivo,
        COALESCE(pl.IdFornitoreSuggerito, fl.IdFornitore),
        'Lavorazione',
        NULL,
        pl.IdLavorazione,
        pl.IdNodoDistinta,
        pl.DescrizioneLavorazione,
        'PZ',
        pl.Quantita,
        COALESCE(fl.PrezzoUnitario, 0)
    FROM dbo.PreventiviRigheLavorazioni pl
    INNER JOIN dbo.PreventiviRighe pr
        ON pl.IdRigaPreventivo = pr.IdRigaPreventivo
    OUTER APPLY
    (
        SELECT TOP 1 fl.*
        FROM dbo.FornitoriLavorazioni fl
        WHERE fl.IdLavorazione = pl.IdLavorazione
          AND fl.Attivo = 1
        ORDER BY fl.FornitorePredefinito DESC, fl.IdFornitoreLavorazione
    ) fl
    WHERE pr.IdPreventivo = @IdPreventivo
      AND pl.DaAcquistareEsterno = 1
      AND COALESCE(pl.IdFornitoreSuggerito, fl.IdFornitore) IS NOT NULL;

    IF NOT EXISTS (SELECT 1 FROM #DaOrdinare)
    BEGIN
        RAISERROR('Nessun materiale/lavorazione da ordinare per questo preventivo.', 16, 1);
        RETURN;
    END

    DECLARE @IdFornitore INT;
    DECLARE @IdOrdineFornitore INT;
    DECLARE @NumeroOrdine INT;

    DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
        SELECT DISTINCT IdFornitore
        FROM #DaOrdinare;

    OPEN cur;
    FETCH NEXT FROM cur INTO @IdFornitore;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        SELECT @NumeroOrdine = ISNULL(MAX(NumeroOrdine), 0) + 1
        FROM dbo.OrdiniFornitori
        WHERE Anno = @Anno;

        INSERT INTO dbo.OrdiniFornitori
        (
            NumeroOrdine,
            Anno,
            DataOrdine,
            IdFornitore,
            Oggetto,
            Stato,
            TotaleOrdine,
            IdPreventivo,
            IdRigaPreventivo
        )
        VALUES
        (
            @NumeroOrdine,
            @Anno,
            @DataOrdine,
            @IdFornitore,
            N'Ordine generato da preventivo ' + CAST(@IdPreventivo AS NVARCHAR(20)),
            'Bozza',
            0,
            @IdPreventivo,
            NULL
        );

        SET @IdOrdineFornitore = SCOPE_IDENTITY();

        ;WITH RigheOrdine AS
        (
            SELECT
                ROW_NUMBER() OVER
                (
                    ORDER BY IdRigaPreventivo, TipoRiga, Descrizione
                ) AS RigaNr,
                *
            FROM #DaOrdinare
            WHERE IdFornitore = @IdFornitore
        )
        INSERT INTO dbo.OrdiniFornitoriRighe
        (
            IdOrdineFornitore,
            RigaNr,
            TipoRiga,
            IdMateriale,
            IdLavorazione,
            IdNodoDistinta,
            IdRigaPreventivo,
            Descrizione,
            UM,
            Quantita,
            PrezzoUnitario,
            TotaleRiga,
            QuantitaRicevuta
        )
        SELECT
            @IdOrdineFornitore,
            RigaNr,
            TipoRiga,
            IdMateriale,
            IdLavorazione,
            IdNodoDistinta,
            IdRigaPreventivo,
            Descrizione,
            UM,
            Quantita,
            PrezzoUnitario,
            ROUND(Quantita * PrezzoUnitario, 2),
            0
        FROM RigheOrdine;

        EXEC dbo.sp_RicalcolaTotaliOrdineFornitore
            @IdOrdineFornitore = @IdOrdineFornitore;

        FETCH NEXT FROM cur INTO @IdFornitore;
    END

    CLOSE cur;
    DEALLOCATE cur;
END
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


/* =========================================================
   STORED PROCEDURE: IMPORTA / AGGIORNA MODELLI CICLO
   ========================================================= */

CREATE   PROCEDURE dbo.sp_ImportaModelliCicloDaStaging
    @BatchId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    MERGE dbo.ModelliCiclo AS T
    USING
    (
        SELECT DISTINCT CodiceModelloCiclo, Descrizione, Note
        FROM dbo.ImportModelliCiclo_Testata
        WHERE BatchId = @BatchId
    ) AS S
    ON T.CodiceModelloCiclo = S.CodiceModelloCiclo
    WHEN MATCHED THEN
        UPDATE SET
            T.Descrizione = S.Descrizione,
            T.Note = S.Note,
            T.DataModifica = SYSDATETIME()
    WHEN NOT MATCHED THEN
        INSERT (CodiceModelloCiclo, Descrizione, Note)
        VALUES (S.CodiceModelloCiclo, S.Descrizione, S.Note);

    DELETE r
    FROM dbo.ModelliCicloRighe r
    INNER JOIN dbo.ModelliCiclo m
        ON r.IdModelloCiclo = m.IdModelloCiclo
    INNER JOIN dbo.ImportModelliCiclo_Righe i
        ON i.CodiceModelloCiclo = m.CodiceModelloCiclo
       AND i.BatchId = @BatchId;

    INSERT INTO dbo.ModelliCicloRighe
    (
        IdModelloCiclo,
        RigaNr,
        IdLavorazione,
        Sequenza,
        TempoSetupMin,
        TempoPezzoMin,
        CostoOrario,
        CostoFisso,
        Note
    )
    SELECT
        m.IdModelloCiclo,
        i.RigaNr,
        l.IdLavorazione,
        i.Sequenza,
        ISNULL(i.TempoSetupMin,0),
        ISNULL(i.TempoPezzoMin,0),
        ISNULL(i.CostoOrario,0),
        ISNULL(i.CostoFisso,0),
        i.Note
    FROM dbo.ImportModelliCiclo_Righe i
    INNER JOIN dbo.ModelliCiclo m
        ON i.CodiceModelloCiclo = m.CodiceModelloCiclo
    INNER JOIN dbo.Lavorazioni l
        ON i.CodiceLavorazione = l.CodiceLavorazione
    WHERE i.BatchId = @BatchId;
END
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


/* =========================================================
   STORED PROCEDURE: IMPORTA / AGGIORNA MODELLI PREVENTIVO
   ========================================================= */

CREATE   PROCEDURE dbo.sp_ImportaModelliPreventivoDaStaging
    @BatchId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    MERGE dbo.ModelliPreventivo AS T
    USING
    (
        SELECT DISTINCT
            i.CodiceModelloPreventivo,
            i.Descrizione,
            c.IdCliente,
            i.Oggetto,
            i.Note
        FROM dbo.ImportModelliPreventivo_Testata i
        LEFT JOIN dbo.Clienti c
            ON i.CodiceCliente = c.CodiceCliente
        WHERE i.BatchId = @BatchId
    ) AS S
    ON T.CodiceModelloPreventivo = S.CodiceModelloPreventivo
    WHEN MATCHED THEN
        UPDATE SET
            T.Descrizione = S.Descrizione,
            T.IdCliente = S.IdCliente,
            T.Oggetto = S.Oggetto,
            T.Note = S.Note,
            T.DataModifica = SYSDATETIME()
    WHEN NOT MATCHED THEN
        INSERT (CodiceModelloPreventivo, Descrizione, IdCliente, Oggetto, Note)
        VALUES (S.CodiceModelloPreventivo, S.Descrizione, S.IdCliente, S.Oggetto, S.Note);

    DELETE r
    FROM dbo.ModelliPreventivoRighe r
    INNER JOIN dbo.ModelliPreventivo m
        ON r.IdModelloPreventivo = m.IdModelloPreventivo
    INNER JOIN dbo.ImportModelliPreventivo_Righe i
        ON i.CodiceModelloPreventivo = m.CodiceModelloPreventivo
       AND i.BatchId = @BatchId;

    INSERT INTO dbo.ModelliPreventivoRighe
    (
        IdModelloPreventivo,
        RigaNr,
        IdArticolo,
        IdModelloCiclo,
        DescrizioneVoce,
        Quantita,
        PrezzoUnitarioVendita,
        Note
    )
    SELECT
        mp.IdModelloPreventivo,
        i.RigaNr,
        a.IdArticolo,
        mc.IdModelloCiclo,
        i.DescrizioneVoce,
        ISNULL(i.Quantita,1),
        ISNULL(i.PrezzoUnitarioVendita,0),
        i.Note
    FROM dbo.ImportModelliPreventivo_Righe i
    INNER JOIN dbo.ModelliPreventivo mp
        ON i.CodiceModelloPreventivo = mp.CodiceModelloPreventivo
    LEFT JOIN dbo.Articoli a
        ON i.CodiceArticolo = a.CodiceArticolo
    LEFT JOIN dbo.ModelliCiclo mc
        ON i.CodiceModelloCiclo = mc.CodiceModelloCiclo
    WHERE i.BatchId = @BatchId;
END
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE   PROCEDURE dbo.sp_RicalcolaTotaliOrdineFornitore
    @IdOrdineFornitore INT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.OrdiniFornitoriRighe
       SET TotaleRiga = ROUND(ISNULL(Quantita,0) * ISNULL(PrezzoUnitario,0), 2)
     WHERE IdOrdineFornitore = @IdOrdineFornitore;

    UPDATE o
       SET o.TotaleOrdine = x.TotaleOrdine,
           o.DataModifica = SYSDATETIME()
    FROM dbo.OrdiniFornitori o
    CROSS APPLY
    (
        SELECT ISNULL(SUM(TotaleRiga), 0) AS TotaleOrdine
        FROM dbo.OrdiniFornitoriRighe r
        WHERE r.IdOrdineFornitore = o.IdOrdineFornitore
    ) x
    WHERE o.IdOrdineFornitore = @IdOrdineFornitore;
END
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE   PROCEDURE dbo.sp_RicalcolaTotaliPreventivo
    @IdPreventivo INT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS
    (
        SELECT 1
        FROM dbo.Preventivi
        WHERE IdPreventivo = @IdPreventivo
    )
    BEGIN
        THROW 51925, 'Preventivo non trovato.', 1;
    END;

    IF
    (
        SELECT COUNT(*)
        FROM dbo.PreventiviVarianti
        WHERE IdPreventivo = @IdPreventivo
          AND Attiva = 1
          AND VarianteScelta = 1
    ) > 1
    BEGIN
        THROW 51926, 'Il preventivo ha piu varianti attive selezionate.', 1;
    END;

    DECLARE
        @IdVarianteSelezionata INT,
        @TotaleCosti DECIMAL(18,2),
        @TotaleVendita DECIMAL(18,2),
        @MargineValore DECIMAL(18,2),
        @MarginePerc DECIMAL(9,2);

    SELECT @IdVarianteSelezionata = variante.IdVariantePreventivo
    FROM dbo.PreventiviVarianti AS variante
    WHERE variante.IdPreventivo = @IdPreventivo
      AND variante.Attiva = 1
      AND variante.VarianteScelta = 1;

    SELECT
        @TotaleCosti = ISNULL(SUM(riga.TotaleCosti), 0),
        @TotaleVendita = ISNULL(SUM(riga.TotaleVendita), 0)
    FROM dbo.PreventiviRighe AS riga
    WHERE riga.IdPreventivo = @IdPreventivo
      AND
      (
          riga.IdVariantePreventivo IS NULL
          OR riga.IdVariantePreventivo = @IdVarianteSelezionata
      );

    SET @MargineValore = @TotaleVendita - @TotaleCosti;
    SET @MarginePerc =
        CASE
            WHEN @TotaleVendita = 0 THEN 0
            ELSE ROUND((@MargineValore / @TotaleVendita) * 100, 2)
        END;

    UPDATE dbo.Preventivi
    SET TotaleCosti = @TotaleCosti,
        TotaleVendita = @TotaleVendita,
        MargineValore = @MargineValore,
        MarginePerc = @MarginePerc,
        DataModifica = SYSDATETIME()
    WHERE IdPreventivo = @IdPreventivo;
END;
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE   PROCEDURE dbo.sp_RicalcolaTotaliRigaPreventivo
    @IdRigaPreventivo INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE
        @TotaleMateriali DECIMAL(18,2) = 0,
        @TotaleLavorazioni DECIMAL(18,2) = 0,
        @TotaleCosti DECIMAL(18,2) = 0,
        @Quantita DECIMAL(18,4),
        @MarkupPerc DECIMAL(9,2),
        @PrezzoManuale BIT,
        @PrezzoUnitarioVendita DECIMAL(18,4),
        @TotaleVendita DECIMAL(18,2),
        @MargineValore DECIMAL(18,2),
        @MarginePerc DECIMAL(9,2),
        @IdPreventivo INT,
        @IdVariantePreventivo INT,
        @RigaLibera BIT,
        @CostoUnitarioLibero DECIMAL(18,4);

    SELECT
        @Quantita = riga.Quantita,
        @MarkupPerc = riga.MarkupPerc,
        @PrezzoManuale = riga.PrezzoManuale,
        @PrezzoUnitarioVendita = riga.PrezzoUnitarioVendita,
        @IdPreventivo = riga.IdPreventivo,
        @IdVariantePreventivo = riga.IdVariantePreventivo,
        @RigaLibera = tipo.RigaLibera,
        @CostoUnitarioLibero = riga.CostoUnitarioLibero
    FROM dbo.PreventiviRighe AS riga
    INNER JOIN dbo.TipiRigaPreventivo AS tipo
        ON tipo.IdTipoRiga = riga.IdTipoRiga
    WHERE riga.IdRigaPreventivo = @IdRigaPreventivo;

    IF @IdPreventivo IS NULL
    BEGIN
        THROW 51927, 'Riga preventivo non trovata o priva di tipo riga valido.', 1;
    END;

    IF @RigaLibera = 1
       AND
       (
           @CostoUnitarioLibero IS NULL
           OR EXISTS
           (
               SELECT 1
               FROM dbo.PreventiviRigheComponenti
               WHERE IdRigaPreventivo = @IdRigaPreventivo
           )
           OR EXISTS
           (
               SELECT 1
               FROM dbo.PreventiviRigheMateriali
               WHERE IdRigaPreventivo = @IdRigaPreventivo
           )
           OR EXISTS
           (
               SELECT 1
               FROM dbo.PreventiviRigheLavorazioni
               WHERE IdRigaPreventivo = @IdRigaPreventivo
           )
       )
    BEGIN
        THROW 51928, 'La riga libera richiede un costo unitario e non puo contenere componenti, materiali o lavorazioni.', 1;
    END;

    BEGIN TRY
        BEGIN TRANSACTION;

        IF @RigaLibera = 0
        BEGIN
            UPDATE dbo.PreventiviRigheMateriali
            SET CostoTotale = ROUND(ISNULL(Quantita, 0) * ISNULL(CostoUnitario, 0), 2)
            WHERE IdRigaPreventivo = @IdRigaPreventivo;

            UPDATE dbo.PreventiviRigheLavorazioni
            SET TempoTotaleMin =
                    ISNULL(TempoSetupMin, 0)
                    + ISNULL(TempoPezzoMin, 0) * ISNULL(Quantita, 0),
                CostoTotale = ROUND
                (
                    (
                        ISNULL(TempoSetupMin, 0)
                        + ISNULL(TempoPezzoMin, 0) * ISNULL(Quantita, 0)
                    ) / 60.0 * ISNULL(CostoOrario, 0)
                    + ISNULL(CostoFisso, 0),
                    2
                )
            WHERE IdRigaPreventivo = @IdRigaPreventivo;

            SELECT @TotaleMateriali = ISNULL(SUM(CostoTotale), 0)
            FROM dbo.PreventiviRigheMateriali
            WHERE IdRigaPreventivo = @IdRigaPreventivo;

            SELECT @TotaleLavorazioni = ISNULL(SUM(CostoTotale), 0)
            FROM dbo.PreventiviRigheLavorazioni
            WHERE IdRigaPreventivo = @IdRigaPreventivo;

            SET @TotaleCosti = @TotaleMateriali + @TotaleLavorazioni;

            UPDATE dbo.PreventiviRighe
            SET CostoUnitarioLibero = NULL
            WHERE IdRigaPreventivo = @IdRigaPreventivo
              AND CostoUnitarioLibero IS NOT NULL;
        END
        ELSE
        BEGIN
            SET @TotaleCosti = ROUND(@Quantita * @CostoUnitarioLibero, 2);
        END;

        IF @PrezzoManuale = 1
        BEGIN
            SET @TotaleVendita = ROUND(@Quantita * @PrezzoUnitarioVendita, 2);
        END
        ELSE
        BEGIN
            SET @TotaleVendita =
                ROUND(@TotaleCosti * (1 + @MarkupPerc / 100.0), 2);

            SET @PrezzoUnitarioVendita =
                CASE
                    WHEN @Quantita = 0 THEN 0
                    ELSE ROUND(@TotaleVendita / @Quantita, 4)
                END;
        END;

        SET @MargineValore = @TotaleVendita - @TotaleCosti;
        SET @MarginePerc =
            CASE
                WHEN @TotaleVendita = 0 THEN 0
                ELSE ROUND((@MargineValore / @TotaleVendita) * 100, 2)
            END;

        UPDATE dbo.PreventiviRighe
        SET TotaleCosti = @TotaleCosti,
            PrezzoUnitarioVendita = @PrezzoUnitarioVendita,
            TotaleVendita = @TotaleVendita,
            MargineValore = @MargineValore,
            MarginePerc = @MarginePerc,
            DataModifica = SYSDATETIME()
        WHERE IdRigaPreventivo = @IdRigaPreventivo;

        IF @IdVariantePreventivo IS NOT NULL
        BEGIN
            EXEC dbo.sp_RicalcolaTotaliVariante
                @IdVariantePreventivo = @IdVariantePreventivo;
        END;

        EXEC dbo.sp_RicalcolaTotaliPreventivo
            @IdPreventivo = @IdPreventivo;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
        BEGIN
            ROLLBACK TRANSACTION;
        END;

        THROW;
    END CATCH;
END;
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE   PROCEDURE dbo.sp_RicalcolaTotaliVariante
    @IdVariantePreventivo INT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS
    (
        SELECT 1
        FROM dbo.PreventiviVarianti
        WHERE IdVariantePreventivo = @IdVariantePreventivo
    )
    BEGIN
        THROW 51924, 'Variante preventivo non trovata.', 1;
    END;

    DECLARE
        @TotaleCosti DECIMAL(18,2),
        @TotaleVendita DECIMAL(18,2),
        @MargineValore DECIMAL(18,2),
        @MarginePerc DECIMAL(9,2);

    SELECT
        @TotaleCosti = ISNULL(SUM(riga.TotaleCosti), 0),
        @TotaleVendita = ISNULL(SUM(riga.TotaleVendita), 0)
    FROM dbo.PreventiviRighe AS riga
    WHERE riga.IdVariantePreventivo = @IdVariantePreventivo;

    SET @MargineValore = @TotaleVendita - @TotaleCosti;
    SET @MarginePerc =
        CASE
            WHEN @TotaleVendita = 0 THEN 0
            ELSE ROUND((@MargineValore / @TotaleVendita) * 100, 2)
        END;

    UPDATE dbo.PreventiviVarianti
    SET TotaleCosti = @TotaleCosti,
        TotaleVendita = @TotaleVendita,
        MargineValore = @MargineValore,
        MarginePerc = @MarginePerc,
        DataModifica = SYSDATETIME()
    WHERE IdVariantePreventivo = @IdVariantePreventivo;
END;
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE   PROCEDURE dbo.sp_RicalcolaVarianteCompleta
    @IdVariantePreventivo INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @IdRigaPreventivo INT;

    DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
        SELECT IdRigaPreventivo
        FROM dbo.PreventiviRighe
        WHERE IdVariantePreventivo = @IdVariantePreventivo;

    OPEN cur;
    FETCH NEXT FROM cur INTO @IdRigaPreventivo;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        EXEC dbo.sp_RicalcolaTotaliRigaPreventivo
            @IdRigaPreventivo = @IdRigaPreventivo;

        FETCH NEXT FROM cur INTO @IdRigaPreventivo;
    END

    CLOSE cur;
    DEALLOCATE cur;

    EXEC dbo.sp_RicalcolaTotaliVariante
        @IdVariantePreventivo = @IdVariantePreventivo;
END
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE   PROCEDURE dbo.sp_RicalcolaVariantiPreventivo
    @IdPreventivo INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @IdVariantePreventivo INT;

    DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
        SELECT IdVariantePreventivo
        FROM dbo.PreventiviVarianti
        WHERE IdPreventivo = @IdPreventivo;

    OPEN cur;
    FETCH NEXT FROM cur INTO @IdVariantePreventivo;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        EXEC dbo.sp_RicalcolaVarianteCompleta
            @IdVariantePreventivo = @IdVariantePreventivo;

        FETCH NEXT FROM cur INTO @IdVariantePreventivo;
    END

    CLOSE cur;
    DEALLOCATE cur;

    EXEC dbo.sp_RicalcolaTotaliPreventivo
        @IdPreventivo = @IdPreventivo;
END
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE   PROCEDURE [dbo].[sp_RigeneraDistintaRigaPreventivo]
    @IdRigaPreventivo INT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS
    (
        SELECT 1
        FROM dbo.PreventiviRighe
        WHERE IdRigaPreventivo = @IdRigaPreventivo
    )
    BEGIN
        RAISERROR('Riga preventivo non trovata.', 16, 1);
        RETURN;
    END

    IF EXISTS
    (
        SELECT 1
        FROM dbo.OrdiniFornitori o
        WHERE o.IdRigaPreventivo = @IdRigaPreventivo
          AND o.Stato IN ('Bozza','Inviato','Parziale')
    )
    BEGIN
        RAISERROR(
            'Impossibile rigenerare la distinta: esistono ordini fornitore aperti collegati alla riga.',
            16,
            1
        );
        RETURN;
    END

    IF EXISTS
    (
        SELECT 1
        FROM dbo.OrdiniFornitoriRighe r
        INNER JOIN dbo.OrdiniFornitori o
            ON r.IdOrdineFornitore = o.IdOrdineFornitore
        WHERE r.IdRigaPreventivo = @IdRigaPreventivo
          AND o.Stato IN ('Bozza','Inviato','Parziale')
    )
    BEGIN
        RAISERROR(
            'Impossibile rigenerare la distinta: esistono righe ordine fornitore aperte collegate.',
            16,
            1
        );
        RETURN;
    END
    IF EXISTS
(
    SELECT 1
    FROM dbo.RichiesteOffertaFornitoriRighe rof
    INNER JOIN dbo.PreventiviRigheMateriali prm
        ON rof.IdRigaMatPrev = prm.IdRigaMatPrev
    INNER JOIN dbo.RichiesteOffertaFornitori ro
        ON rof.IdRichiestaOfferta = ro.IdRichiestaOfferta
    WHERE prm.IdRigaPreventivo = @IdRigaPreventivo
      AND ro.Stato IN ('Bozza','Inviata','Risposta ricevuta','Accettata')
)
BEGIN
    RAISERROR(
        'Impossibile esplodere o rigenerare la distinta: esistono richieste offerta fornitore collegate ai materiali della riga.',
        16,
        1
    );
    RETURN;
END

    DELETE FROM dbo.PreventiviRigheLavorazioni
    WHERE IdRigaPreventivo = @IdRigaPreventivo;

    DELETE FROM dbo.PreventiviRigheMateriali
    WHERE IdRigaPreventivo = @IdRigaPreventivo;

    DELETE FROM dbo.PreventiviRigheComponenti
    WHERE IdRigaPreventivo = @IdRigaPreventivo;

    EXEC dbo.sp_EsplodiDistintaSuRigaPreventivo
        @IdRigaPreventivo = @IdRigaPreventivo,
        @SovrascriviSnapshot = 1;

    EXEC dbo.sp_RicalcolaTotaliRigaPreventivo
        @IdRigaPreventivo = @IdRigaPreventivo;
END
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE   PROCEDURE dbo.TipiAllegato_Elenco
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

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER OFF
GO


CREATE   PROCEDURE dbo.TipiRigaPreventivo_Elenco
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        IdTipoRiga,
        Codice,
        Descrizione,
        RigaLibera
    FROM dbo.TipiRigaPreventivo
    WHERE Attiva = 1
    ORDER BY Ordinamento, Descrizione;
END;
GO
