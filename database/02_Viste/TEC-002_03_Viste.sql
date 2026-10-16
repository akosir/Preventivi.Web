/*
    TEC-002 - Viste
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

CREATE   VIEW dbo.vw_AlertAutomatici
AS

/* =========================
   RICHIESTE CLIENTI
   una sola riga per richiesta
   ========================= */
SELECT
    CASE
        WHEN r.Priorita IN ('Alta','Urgente') THEN 'Richiesta urgente non chiusa'
        WHEN r.DataScadenza IS NOT NULL
             AND r.DataScadenza <= DATEADD(DAY, 7, CAST(GETDATE() AS DATE))
             THEN 'Richiesta in scadenza'
        ELSE 'Richiesta aperta'
    END AS TipoAlert,

    'RichiestaCliente' AS Origine,
    r.IdRichiestaCliente AS IdOrigine,
    r.Oggetto AS Titolo,

    CASE
        WHEN r.Priorita IN ('Alta','Urgente') THEN
            'Richiesta con priorità alta/urgente ancora aperta'
        WHEN r.DataScadenza IS NOT NULL
             AND r.DataScadenza <= DATEADD(DAY, 7, CAST(GETDATE() AS DATE))
             THEN
            'Richiesta cliente in scadenza entro 7 giorni'
        ELSE
            'Richiesta cliente ancora aperta'
    END AS Descrizione,

    r.Priorita,
    r.Stato,
    r.DataScadenza

FROM dbo.RichiesteClienti r
WHERE r.Stato NOT IN ('Confermata','Persa','Annullata')
  AND
  (
        r.Priorita IN ('Alta','Urgente')
        OR
        (
            r.DataScadenza IS NOT NULL
            AND r.DataScadenza <= DATEADD(DAY, 7, CAST(GETDATE() AS DATE))
        )
  )

UNION ALL

/* =========================
   CAMPIONATURE
   ========================= */
SELECT
    'Campionatura aperta' AS TipoAlert,
    'Campionatura' AS Origine,
    IdCampionatura AS IdOrigine,
    Oggetto AS Titolo,
    'Campionatura ancora aperta o in verifica' AS Descrizione,
    Priorita,
    Stato,
    DataPrevistaConsegna AS DataScadenza
FROM dbo.Campionature
WHERE Stato NOT IN ('Chiusa','Annullata','Approvata','Respinta')

UNION ALL

/* =========================
   ORDINI FORNITORI
   ========================= */
SELECT
    'Ordine fornitore aperto' AS TipoAlert,
    'OrdineFornitore' AS Origine,
    IdOrdineFornitore AS IdOrigine,
    Oggetto AS Titolo,
    'Ordine fornitore non ancora ricevuto' AS Descrizione,
    'Media' AS Priorita,
    Stato,
    DataConsegnaPrevista AS DataScadenza
FROM dbo.OrdiniFornitori
WHERE Stato IN ('Bozza','Inviato','Parziale');
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE   VIEW dbo.vw_AlertCruscotto
AS
SELECT
    CAST(NULL AS INT) AS IdAlert,
    TipoAlert,
    Origine,
    IdOrigine,
    Titolo,
    Descrizione,
    Priorita,
    Stato,
    CAST(GETDATE() AS DATE) AS DataAlert,
    DataScadenza,
    CAST(0 AS BIT) AS Manuale
FROM dbo.vw_AlertAutomatici

UNION ALL

SELECT
    IdAlert,
    TipoAlert,
    Origine,
    IdOrigine,
    Titolo,
    Descrizione,
    Priorita,
    Stato,
    DataAlert,
    DataScadenza,
    CAST(1 AS BIT) AS Manuale
FROM dbo.AlertOperativi
WHERE Stato NOT IN ('Chiuso','Annullato');
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE   VIEW dbo.vw_DistintaBaseAlbero
AS
WITH DistintaTree AS
(
    SELECT
        n.IdNodoDistinta,
        n.IdArticolo,
        a.CodiceArticolo,
        a.Descrizione AS DescrizioneArticolo,
        n.IdNodoPadre,
        CAST(NULL AS INT) AS IdNodoRadice,
        n.IdTipoNodo,
        t.Descrizione AS TipoNodo,
        n.CodiceNodo,
        n.DescrizioneNodo,
        n.QuantitaBase,
        n.Livello,
        n.OrdineVisualizzazione,
        n.Attivo,
        CAST(n.DescrizioneNodo AS NVARCHAR(MAX)) AS PercorsoCompleto,
        CAST(
            RIGHT('000000' + CAST(n.OrdineVisualizzazione AS VARCHAR(6)), 6)
            AS NVARCHAR(MAX)
        ) AS ChiaveOrdinamento
    FROM dbo.DistintaBaseNodi n
    INNER JOIN dbo.Articoli a
        ON n.IdArticolo = a.IdArticolo
    INNER JOIN dbo.TipiNodoDistinta t
        ON n.IdTipoNodo = t.IdTipoNodo
    WHERE n.IdNodoPadre IS NULL

    UNION ALL

    SELECT
        c.IdNodoDistinta,
        c.IdArticolo,
        a.CodiceArticolo,
        a.Descrizione AS DescrizioneArticolo,
        c.IdNodoPadre,
        COALESCE(p.IdNodoRadice, p.IdNodoDistinta) AS IdNodoRadice,
        c.IdTipoNodo,
        t.Descrizione AS TipoNodo,
        c.CodiceNodo,
        c.DescrizioneNodo,
        c.QuantitaBase,
        c.Livello,
        c.OrdineVisualizzazione,
        c.Attivo,
        CAST(p.PercorsoCompleto + N' > ' + c.DescrizioneNodo AS NVARCHAR(MAX)) AS PercorsoCompleto,
        CAST(
            p.ChiaveOrdinamento + N'.' +
            RIGHT('000000' + CAST(c.OrdineVisualizzazione AS VARCHAR(6)), 6)
            AS NVARCHAR(MAX)
        ) AS ChiaveOrdinamento
    FROM dbo.DistintaBaseNodi c
    INNER JOIN DistintaTree p
        ON c.IdNodoPadre = p.IdNodoDistinta
    INNER JOIN dbo.Articoli a
        ON c.IdArticolo = a.IdArticolo
    INNER JOIN dbo.TipiNodoDistinta t
        ON c.IdTipoNodo = t.IdTipoNodo
)
SELECT
    IdNodoDistinta,
    IdArticolo,
    CodiceArticolo,
    DescrizioneArticolo,
    IdNodoPadre,
    IdNodoRadice = COALESCE(IdNodoRadice, IdNodoDistinta),
    IdTipoNodo,
    TipoNodo,
    CodiceNodo,
    DescrizioneNodo,
    QuantitaBase,
    Livello,
    OrdineVisualizzazione,
    Attivo,
    PercorsoCompleto,
    ChiaveOrdinamento
FROM DistintaTree;
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE   VIEW dbo.vw_DistintaBaseAlbero_Indented
AS
SELECT
    IdNodoDistinta,
    IdArticolo,
    CodiceArticolo,
    DescrizioneArticolo,
    IdNodoPadre,
    IdNodoRadice,
    IdTipoNodo,
    TipoNodo,
    CodiceNodo,
    DescrizioneNodo,
    QuantitaBase,
    Livello,
    OrdineVisualizzazione,
    Attivo,
    PercorsoCompleto,
    ChiaveOrdinamento,
    REPLICATE(N'   ', Livello) + DescrizioneNodo AS DescrizioneNodoIndented
FROM dbo.vw_DistintaBaseAlbero;
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE   VIEW dbo.vw_DashboardCommerciale
AS
SELECT
    COUNT(*) AS TotaleRichieste,

    SUM(CASE WHEN Stato IN ('Nuova','In Valutazione','Da Preventivare','Preventivata','Sospesa') THEN 1 ELSE 0 END) AS RichiesteAperte,

    SUM(CASE WHEN Priorita = 'Urgente' THEN 1 ELSE 0 END) AS RichiesteUrgenti,

    SUM(CASE WHEN Stato = 'Da Preventivare' THEN 1 ELSE 0 END) AS DaPreventivare,

    SUM(CASE WHEN Stato = 'Preventivata' THEN 1 ELSE 0 END) AS Preventivate,

    SUM(CASE WHEN Stato = 'Confermata' THEN 1 ELSE 0 END) AS Confermate,

    SUM(CASE WHEN Stato = 'Persa' THEN 1 ELSE 0 END) AS Perse,

    SUM(CASE
            WHEN DataScadenza IS NOT NULL
             AND DataScadenza <= DATEADD(day, 7, CAST(GETDATE() AS date))
             AND Stato NOT IN ('Confermata','Persa','Annullata')
            THEN 1 ELSE 0
        END) AS InScadenza7Giorni

FROM dbo.RichiesteClienti;
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE   VIEW dbo.vw_DashboardCommercialeImporti
AS
SELECT
    CAST(ISNULL(SUM(CASE WHEN Stato IN ('Bozza','Da Verificare','Pronto da Inviare') THEN TotaleVendita ELSE 0 END),0) AS DECIMAL(18,2)) AS TotaleBozze,
    CAST(ISNULL(SUM(CASE WHEN Stato = 'Inviato' THEN TotaleVendita ELSE 0 END),0) AS DECIMAL(18,2)) AS TotaleInviato,
    CAST(ISNULL(SUM(CASE WHEN Stato = 'Accettato' THEN TotaleVendita ELSE 0 END),0) AS DECIMAL(18,2)) AS TotaleAccettato,
    CAST(ISNULL(SUM(CASE WHEN Stato = 'Respinto' THEN TotaleVendita ELSE 0 END),0) AS DECIMAL(18,2)) AS TotaleRespinto,
    CAST(ISNULL(SUM(TotaleVendita),0) AS DECIMAL(18,2)) AS TotalePreventivato
FROM dbo.Preventivi;
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE   VIEW dbo.vw_DashboardPipelineStato
AS
SELECT
    Stato,
    COUNT(*) AS NumeroRichieste
FROM dbo.RichiesteClienti
GROUP BY Stato;
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE   VIEW dbo.vw_DashboardRichiesteUrgenti
AS
SELECT
    r.IdRichiestaCliente,
    r.NumeroRichiesta,
    r.Anno,
    r.DataRichiesta,
    c.RagioneSociale,
    r.Oggetto,
    r.Stato,
    r.Priorita,
    r.InteresseCliente,
    r.DataScadenza,
    CAST(ISNULL(r.ProbabilitaChiusura,0) AS DECIMAL(18,2)) AS ProbabilitaChiusura
FROM dbo.RichiesteClienti r
LEFT JOIN dbo.Clienti c
    ON r.IdCliente = c.IdCliente
WHERE r.Stato NOT IN ('Confermata','Persa','Annullata')
  AND
  (
      r.Priorita IN ('Alta','Urgente')
      OR r.DataScadenza <= DATEADD(day, 7, CAST(GETDATE() AS date))
  );
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW dbo.vw_DistintaBaseCompleta
AS
SELECT
    n.IdNodoDistinta,
    n.IdArticolo,
    a.CodiceArticolo,
    a.Descrizione AS DescrizioneArticolo,
    n.IdNodoPadre,
    n.IdTipoNodo,
    t.Descrizione AS TipoNodo,
    n.CodiceNodo,
    n.DescrizioneNodo,
    n.QuantitaBase,
    n.Livello,
    n.OrdineVisualizzazione,
    n.Attivo
FROM dbo.DistintaBaseNodi n
INNER JOIN dbo.Articoli a
    ON n.IdArticolo = a.IdArticolo
INNER JOIN dbo.TipiNodoDistinta t
    ON n.IdTipoNodo = t.IdTipoNodo;
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE   VIEW dbo.vw_KPI_AndamentoMensilePreventivi
AS
SELECT
    YEAR(DataPreventivo) AS Anno,
    MONTH(DataPreventivo) AS Mese,
    COUNT(*) AS NumeroPreventivi,
    SUM(TotaleVendita) AS TotaleVendita,
    SUM(MargineValore) AS MargineValore,
    SUM(CASE WHEN Stato = 'Accettato' THEN TotaleVendita ELSE 0 END) AS TotaleAccettato
FROM dbo.Preventivi
GROUP BY
    YEAR(DataPreventivo),
    MONTH(DataPreventivo);
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE   VIEW dbo.vw_KPI_Direzionale
AS
SELECT
    COUNT(DISTINCT p.IdPreventivo) AS NumeroPreventivi,

    SUM(CASE WHEN p.Stato = 'Accettato' THEN 1 ELSE 0 END) AS PreventiviAccettati,

    CAST(
        CASE
            WHEN COUNT(DISTINCT p.IdPreventivo) = 0 THEN 0
            ELSE ROUND(
                SUM(CASE WHEN p.Stato = 'Accettato' THEN 1 ELSE 0 END) * 100.0 /
                COUNT(DISTINCT p.IdPreventivo), 2
            )
        END
    AS DECIMAL(18,2)) AS ConversionRate,

    CAST(ISNULL(SUM(p.TotaleVendita), 0) AS DECIMAL(18,2)) AS TotalePreventivato,

    CAST(ISNULL(SUM(p.MargineValore), 0) AS DECIMAL(18,2)) AS MargineTotale,

    CAST(
        CASE
            WHEN ISNULL(SUM(p.TotaleVendita),0) = 0 THEN 0
            ELSE ROUND(SUM(p.MargineValore) * 100.0 / SUM(p.TotaleVendita), 2)
        END
    AS DECIMAL(18,2)) AS MargineMedioPerc

FROM dbo.Preventivi p;
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE   VIEW dbo.vw_KPI_RichiesteCritiche
AS
SELECT
    r.IdRichiestaCliente,
    r.NumeroRichiesta,
    r.Anno,
    r.DataRichiesta,
    c.RagioneSociale,
    r.Oggetto,
    r.Stato,
    r.Priorita,
    r.InteresseCliente,
    r.DataScadenza,
    DATEDIFF(DAY, GETDATE(), r.DataScadenza) AS GiorniAllaScadenza
FROM dbo.RichiesteClienti r
LEFT JOIN dbo.Clienti c
    ON r.IdCliente = c.IdCliente
WHERE r.Stato NOT IN ('Confermata','Persa','Annullata')
  AND
  (
        r.Priorita IN ('Alta','Urgente')
        OR r.DataScadenza <= DATEADD(DAY, 7, CAST(GETDATE() AS DATE))
  );
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE   VIEW dbo.vw_KPI_TopClienti
AS
SELECT
    c.IdCliente,
    c.RagioneSociale,

    COUNT(p.IdPreventivo) AS NumeroPreventivi,

    CAST(ISNULL(SUM(p.TotaleVendita), 0) AS DECIMAL(18,2)) AS TotalePreventivato,

    CAST(ISNULL(SUM(CASE
        WHEN p.Stato = 'Accettato' THEN p.TotaleVendita
        ELSE 0
    END), 0) AS DECIMAL(18,2)) AS TotaleAccettato,

    CAST(ISNULL(SUM(p.MargineValore), 0) AS DECIMAL(18,2)) AS MargineTotale,

    CAST(
        CASE
            WHEN ISNULL(SUM(p.TotaleVendita), 0) = 0 THEN 0
            ELSE ROUND(
                SUM(p.MargineValore) * 100.0 / SUM(p.TotaleVendita),
                2
            )
        END
    AS DECIMAL(18,2)) AS MarginePerc

FROM dbo.Preventivi p
INNER JOIN dbo.Clienti c
    ON p.IdCliente = c.IdCliente
GROUP BY
    c.IdCliente,
    c.RagioneSociale;
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE   VIEW dbo.vw_MenuApplicazione
AS
SELECT
    g.IdGruppoMenu,
    g.CodiceGruppo,
    g.Descrizione AS Gruppo,
    g.Ordine AS OrdineGruppo,

    v.IdVoceMenu,
    v.Descrizione AS VoceMenu,
    v.NomeMaschera,
    v.TipoApertura,
    v.Ordine AS OrdineVoce

FROM dbo.MenuGruppi g
INNER JOIN dbo.MenuVoci v
    ON g.IdGruppoMenu = v.IdGruppoMenu
WHERE g.Attivo = 1
  AND v.Attivo = 1;
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW dbo.vw_MenuApplicazionePermessi
AS
SELECT DISTINCT
                         u.IdUtente, u.Username, u.NomeCompleto, g.IdGruppoMenu, g.CodiceGruppo, g.Descrizione AS Gruppo, g.Ordine AS OrdineGruppo, v.IdVoceMenu, v.Descrizione AS VoceMenu, v.TipoOggetto, v.Ordine AS OrdineVoce,
                         v.NomeMaschera
FROM            dbo.UtentiApplicazione AS u INNER JOIN
                         dbo.UtentiRuoli AS ur ON u.IdUtente = ur.IdUtente INNER JOIN
                         dbo.RuoliApplicazione AS r ON ur.IdRuolo = r.IdRuolo INNER JOIN
                         dbo.MenuPermessiRuoli AS p ON r.IdRuolo = p.IdRuolo INNER JOIN
                         dbo.MenuVoci AS v ON p.IdVoceMenu = v.IdVoceMenu INNER JOIN
                         dbo.MenuGruppi AS g ON v.IdGruppoMenu = g.IdGruppoMenu
WHERE        (u.Attivo = 1) AND (r.Attivo = 1) AND (g.Attivo = 1) AND (v.Attivo = 1) AND (p.Consenti = 1)
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW dbo.vw_OrdiniFornitoriRigheDettaglio
AS
SELECT
    r.IdRigaOrdineFornitore,
    r.IdOrdineFornitore,
    r.RigaNr,
    r.TipoRiga,
    r.IdMateriale,
    m.CodiceMateriale,
    r.IdLavorazione,
    l.CodiceLavorazione,
    r.IdNodoDistinta,
    r.IdRigaPreventivo,
    r.Descrizione,
    r.UM,
    r.Quantita,
    r.PrezzoUnitario,
    r.TotaleRiga,
    r.QuantitaRicevuta,
    r.DataConsegnaPrevista,
    r.Note
FROM dbo.OrdiniFornitoriRighe r
LEFT JOIN dbo.Materiali m
    ON r.IdMateriale = m.IdMateriale
LEFT JOIN dbo.Lavorazioni l
    ON r.IdLavorazione = l.IdLavorazione;
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW dbo.vw_OrdiniFornitoriTestata
AS
SELECT
    o.IdOrdineFornitore,
    o.NumeroOrdine,
    o.Anno,
    o.DataOrdine,
    o.IdFornitore,
    f.CodiceFornitore,
    f.RagioneSociale,
    o.Oggetto,
    o.Stato,
    o.TotaleOrdine,
    o.DataConsegnaPrevista,
    o.IdPreventivo,
    o.IdRigaPreventivo
FROM dbo.OrdiniFornitori o
INNER JOIN dbo.Fornitori f
    ON o.IdFornitore = f.IdFornitore;
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW dbo.vw_PreventiviRigheDettaglio
AS
SELECT
    r.IdRigaPreventivo,
    r.IdPreventivo,
    r.RigaNr,
    r.IdArticolo,
    a.CodiceArticolo,
    a.Descrizione AS DescrizioneArticolo,
    r.IdModelloCiclo,
    mc.CodiceModelloCiclo,
    r.DescrizioneVoce,
    r.Quantita,
    r.PrezzoUnitarioVendita,
    r.TotaleVendita,
    r.TotaleCosti,
    r.MargineValore,
    r.MarginePerc
FROM dbo.PreventiviRighe r
LEFT JOIN dbo.Articoli a
    ON r.IdArticolo = a.IdArticolo
LEFT JOIN dbo.ModelliCiclo mc
    ON r.IdModelloCiclo = mc.IdModelloCiclo;
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


/* =========================================================
   VIEW UTILI PER ACCESS
   ========================================================= */

CREATE VIEW dbo.vw_PreventiviTotali
AS
SELECT
    p.IdPreventivo,
    p.NumeroPreventivo,
    p.Anno,
    p.DataPreventivo,
    p.IdCliente,
    c.RagioneSociale,
    p.IdModelloPreventivo,
    mp.CodiceModelloPreventivo,
    p.Oggetto,
    p.Stato,
    p.TotaleCosti,
    p.TotaleVendita,
    p.MargineValore,
    p.MarginePerc
FROM dbo.Preventivi p
LEFT JOIN dbo.Clienti c
    ON p.IdCliente = c.IdCliente
LEFT JOIN dbo.ModelliPreventivo mp
    ON p.IdModelloPreventivo = mp.IdModelloPreventivo;
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE   VIEW dbo.vw_PreventivoOrdiniFornitori
AS
SELECT
    o.IdOrdineFornitore,
    o.IdPreventivo,
    o.NumeroOrdine,
    o.Anno,
    o.DataOrdine,
    o.IdFornitore,
    f.RagioneSociale,
    o.Stato,
    o.TotaleOrdine,
    o.DataConsegnaPrevista,
    o.Oggetto
FROM dbo.OrdiniFornitori o
INNER JOIN dbo.Fornitori f
    ON o.IdFornitore = f.IdFornitore;
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE   VIEW dbo.vw_PreventivoRiepilogoCosti
AS

SELECT DISTINCT
    pr.IdPreventivo,
    pr.IdRigaPreventivo,
    pr.RigaNr,
    pr.DescrizioneVoce,
    'Materiale' AS TipoCosto,
    m.IdRigaMatPrev AS IdDettaglioCosto,
    m.IdNodoDistinta,
    ISNULL(c.DescrizioneNodo, 'Generale / Manuale') AS Componente,
    m.DescrizioneMateriale AS DescrizioneCosto,
    m.UM,
    m.Quantita,
    m.CostoUnitario,
    m.CostoTotale,
    CASE
        WHEN ISNULL(m.CostoUnitario,0) = 0
          OR ISNULL(m.CostoTotale,0) = 0 THEN 0
        ELSE 1
    END AS Valorizzato,
    m.DaAcquistare,
    m.IdFornitoreSuggerito,
    c.Livello,
    c.OrdineVisualizzazione
FROM dbo.PreventiviRighe pr
INNER JOIN dbo.PreventiviRigheMateriali m
    ON pr.IdRigaPreventivo = m.IdRigaPreventivo
OUTER APPLY
(
    SELECT TOP 1
        pc.DescrizioneNodo,
        pc.Livello,
        pc.OrdineVisualizzazione
    FROM dbo.PreventiviRigheComponenti pc
    WHERE pc.IdRigaPreventivo = m.IdRigaPreventivo
      AND pc.IdNodoDistinta = m.IdNodoDistinta
    ORDER BY pc.IdRigaCompPrev
) c

UNION ALL

SELECT DISTINCT
    pr.IdPreventivo,
    pr.IdRigaPreventivo,
    pr.RigaNr,
    pr.DescrizioneVoce,
    'Lavorazione' AS TipoCosto,
    l.IdRigaLavPrev AS IdDettaglioCosto,
    l.IdNodoDistinta,
    ISNULL(c.DescrizioneNodo, 'Generale / Manuale') AS Componente,
    l.DescrizioneLavorazione AS DescrizioneCosto,
    'MIN' AS UM,
    l.Quantita,
    l.CostoOrario AS CostoUnitario,
    l.CostoTotale,
    CASE
        WHEN ISNULL(l.CostoOrario,0) = 0
          OR ISNULL(l.CostoTotale,0) = 0 THEN 0
        ELSE 1
    END AS Valorizzato,
    l.DaAcquistareEsterno AS DaAcquistare,
    l.IdFornitoreSuggerito,
    c.Livello,
    c.OrdineVisualizzazione
FROM dbo.PreventiviRighe pr
INNER JOIN dbo.PreventiviRigheLavorazioni l
    ON pr.IdRigaPreventivo = l.IdRigaPreventivo
OUTER APPLY
(
    SELECT TOP 1
        pc.DescrizioneNodo,
        pc.Livello,
        pc.OrdineVisualizzazione
    FROM dbo.PreventiviRigheComponenti pc
    WHERE pc.IdRigaPreventivo = l.IdRigaPreventivo
      AND pc.IdNodoDistinta = l.IdNodoDistinta
    ORDER BY pc.IdRigaCompPrev
) c;
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE   VIEW dbo.vw_ReportDettaglioCostiPreventivo
AS
SELECT
    p.IdPreventivo,
    p.NumeroPreventivo,
    p.Anno,
    c.RagioneSociale,

    r.IdRigaPreventivo,
    r.RigaNr,
    r.DescrizioneVoce,

    'Materiale' AS TipoCosto,
    m.DescrizioneMateriale AS DescrizioneCosto,
    m.Quantita,
    m.CostoUnitario,
    m.CostoTotale

FROM dbo.Preventivi p
INNER JOIN dbo.Clienti c
    ON p.IdCliente = c.IdCliente
INNER JOIN dbo.PreventiviRighe r
    ON p.IdPreventivo = r.IdPreventivo
INNER JOIN dbo.PreventiviRigheMateriali m
    ON r.IdRigaPreventivo = m.IdRigaPreventivo

UNION ALL

SELECT
    p.IdPreventivo,
    p.NumeroPreventivo,
    p.Anno,
    c.RagioneSociale,

    r.IdRigaPreventivo,
    r.RigaNr,
    r.DescrizioneVoce,

    'Lavorazione',
    l.DescrizioneLavorazione,
    l.Quantita,
    l.CostoOrario,
    l.CostoTotale

FROM dbo.Preventivi p
INNER JOIN dbo.Clienti c
    ON p.IdCliente = c.IdCliente
INNER JOIN dbo.PreventiviRighe r
    ON p.IdPreventivo = r.IdPreventivo
INNER JOIN dbo.PreventiviRigheLavorazioni l
    ON r.IdRigaPreventivo = l.IdRigaPreventivo;
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE   VIEW dbo.vw_ReportKPICommerciali
AS
SELECT
    COUNT(DISTINCT IdPreventivo) AS NumeroPreventivi,

    SUM(CASE WHEN Stato = 'Accettato' THEN 1 ELSE 0 END) AS PreventiviAccettati,

    SUM(CASE WHEN Stato = 'Respinto' THEN 1 ELSE 0 END) AS PreventiviRespinti,

    SUM(ISNULL(TotaleVendita,0)) AS TotalePreventivato,

    AVG(ISNULL(TotaleVendita,0)) AS ValoreMedioPreventivo,

    SUM(CASE WHEN Stato = 'Accettato'
             THEN ISNULL(TotaleVendita,0)
             ELSE 0 END) AS TotaleAccettato,

    SUM(CASE WHEN Stato = 'Accettato'
             THEN ISNULL(MargineValore,0)
             ELSE 0 END) AS MargineAccettato,

    CASE
        WHEN COUNT(*) = 0 THEN 0
        ELSE ROUND(
            (SUM(CASE WHEN Stato='Accettato' THEN 1 ELSE 0 END) * 100.0)
            / COUNT(*), 2)
    END AS ConversionRate

FROM dbo.Preventivi;
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE   VIEW dbo.vw_ReportPreventiviMargini
AS
SELECT
    p.IdPreventivo,
    p.NumeroPreventivo,
    p.Anno,
    p.DataPreventivo,

    p.IdCliente,
    c.RagioneSociale,

    p.Stato,

    v.IdVariantePreventivo,
    v.CodiceVariante,
    v.DescrizioneVariante,
    v.VarianteScelta,

    ISNULL(p.TotaleCosti,0) AS TotaleCostiPreventivo,
    ISNULL(p.TotaleVendita,0) AS TotaleVenditaPreventivo,
    ISNULL(p.MargineValore,0) AS MarginePreventivo,
    ISNULL(p.MarkupPercDefault,0) AS MarkupPreventivo,

    ISNULL(v.TotaleCosti,0) AS TotaleCostiVariante,
    ISNULL(v.TotaleVendita,0) AS TotaleVenditaVariante,
    ISNULL(v.MargineValore,0) AS MargineVariante,
    ISNULL(v.MarginePerc,0) AS MarkupVariante,

    CASE
        WHEN ISNULL(v.TotaleVendita,0) = 0 THEN 0
        ELSE ROUND(
            ((ISNULL(v.TotaleVendita,0) - ISNULL(v.TotaleCosti,0))
            / NULLIF(v.TotaleVendita,0)) * 100, 2)
    END AS MarginePercVariante,

    CASE
        WHEN p.Stato = 'Accettato' THEN 1
        ELSE 0
    END AS PreventivoAccettato,

    CASE
        WHEN p.Stato = 'Respinto' THEN 1
        ELSE 0
    END AS PreventivoRespinto

FROM dbo.Preventivi p
LEFT JOIN dbo.Clienti c
    ON p.IdCliente = c.IdCliente
LEFT JOIN dbo.PreventiviVarianti v
    ON p.IdPreventivo = v.IdPreventivo;
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE   VIEW dbo.vw_RichiesteClientiCRM
AS
SELECT
    r.IdRichiestaCliente,
    r.NumeroRichiesta,
    r.Anno,
    r.DataRichiesta,
    r.IdCliente,
    c.RagioneSociale,
    r.Oggetto,
    r.Stato,
    r.Priorita,
    r.InteresseCliente,
    r.DataScadenza,
    r.DataAttivazione,
    r.DataChiusura,
    r.ProbabilitaChiusura,
    r.Note,
    COUNT(p.IdPreventivo) AS NumeroPreventivi,
    ISNULL(SUM(p.TotaleVendita),0) AS TotalePreventivato,

    CASE
        WHEN r.Priorita = 'Urgente' THEN 4
        WHEN r.Priorita = 'Alta' THEN 3
        WHEN r.Priorita = 'Media' THEN 2
        ELSE 1
    END
    +
    CASE
        WHEN r.InteresseCliente = 'Strategico' THEN 3
        WHEN r.InteresseCliente = 'Alto' THEN 2
        WHEN r.InteresseCliente = 'Medio' THEN 1
        ELSE 0
    END
    +
    CASE
        WHEN r.DataScadenza IS NOT NULL
             AND r.DataScadenza <= DATEADD(day,2,CAST(GETDATE() AS date)) THEN 3
        WHEN r.DataScadenza IS NOT NULL
             AND r.DataScadenza <= DATEADD(day,5,CAST(GETDATE() AS date)) THEN 2
        ELSE 0
    END AS ScorePriorita
FROM dbo.RichiesteClienti r
LEFT JOIN dbo.Clienti c
    ON r.IdCliente = c.IdCliente
LEFT JOIN dbo.Preventivi p
    ON r.IdRichiestaCliente = p.IdRichiestaCliente
GROUP BY
    r.IdRichiestaCliente,
    r.NumeroRichiesta,
    r.Anno,
    r.DataRichiesta,
    r.IdCliente,
    c.RagioneSociale,
    r.Oggetto,
    r.Stato,
    r.Priorita,
    r.InteresseCliente,
    r.DataScadenza,
    r.DataAttivazione,
    r.DataChiusura,
    r.ProbabilitaChiusura,
    r.Note;
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE   VIEW dbo.vw_RichiestePrioritaCalcolata
AS
SELECT
    r.*,

    CASE
        WHEN r.Priorita = 'Urgente' THEN 4
        WHEN r.Priorita = 'Alta' THEN 3
        WHEN r.Priorita = 'Media' THEN 2
        ELSE 1
    END
    +
    CASE
        WHEN r.InteresseCliente = 'Strategico' THEN 3
        WHEN r.InteresseCliente = 'Alto' THEN 2
        WHEN r.InteresseCliente = 'Medio' THEN 1
        ELSE 0
    END
    +
    CASE
        WHEN r.DataScadenza IS NOT NULL
             AND r.DataScadenza <= DATEADD(day,2,GETDATE()) THEN 3
        WHEN r.DataScadenza IS NOT NULL
             AND r.DataScadenza <= DATEADD(day,5,GETDATE()) THEN 2
        ELSE 0
    END
    AS ScorePriorita

FROM dbo.RichiesteClienti r;
GO
