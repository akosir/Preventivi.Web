/*
    TEC-009 - Diagnostica pre-ricalcolo economico

    Script esclusivamente diagnostico:
    - non modifica tabelle, procedure o dati;
    - espone le differenze rispetto alle decisioni 164-171;
    - termina con errore controllato in presenza di ambiguita bloccanti.

    Decisioni applicate alla diagnostica:
    - Quantita di materiali e lavorazioni e il totale operativo;
    - QuantitaCalcolata del componente e un riferimento, non un moltiplicatore;
    - il markup effettivo e PreventiviRighe.MarkupPerc;
    - la testata comprende righe comuni e sola variante attiva selezionata;
    - una riga libera richiede CostoUnitarioLibero valorizzato.
*/

SET NOCOUNT ON;

IF OBJECT_ID(N'dbo.Preventivi', N'U') IS NULL
   OR OBJECT_ID(N'dbo.PreventiviRighe', N'U') IS NULL
   OR OBJECT_ID(N'dbo.PreventiviRigheComponenti', N'U') IS NULL
   OR OBJECT_ID(N'dbo.PreventiviRigheMateriali', N'U') IS NULL
   OR OBJECT_ID(N'dbo.PreventiviRigheLavorazioni', N'U') IS NULL
   OR OBJECT_ID(N'dbo.PreventiviVarianti', N'U') IS NULL
   OR OBJECT_ID(N'dbo.TipiRigaPreventivo', N'U') IS NULL
BEGIN
    THROW 51901, 'TEC-009: schema richiesto non disponibile.', 1;
END;

/* 1. Quantita operative e riferimento del componente. */
SELECT
    N'Materiale' AS TipoElemento,
    materiale.IdRigaPreventivo,
    materiale.IdRigaCompPrev,
    componente.DescrizioneNodo AS Componente,
    componente.QuantitaCalcolata AS QuantitaComponente,
    materiale.IdRigaMatPrev AS IdElemento,
    materiale.DescrizioneMateriale AS DescrizioneElemento,
    materiale.Quantita AS QuantitaOperativa,
    materiale.CostoUnitario,
    materiale.CostoTotale
FROM dbo.PreventiviRigheMateriali AS materiale
LEFT JOIN dbo.PreventiviRigheComponenti AS componente
    ON componente.IdRigaPreventivo = materiale.IdRigaPreventivo
   AND componente.IdRigaCompPrev = materiale.IdRigaCompPrev

UNION ALL

SELECT
    N'Lavorazione',
    lavorazione.IdRigaPreventivo,
    lavorazione.IdRigaCompPrev,
    componente.DescrizioneNodo,
    componente.QuantitaCalcolata,
    lavorazione.IdRigaLavPrev,
    lavorazione.DescrizioneLavorazione,
    lavorazione.Quantita,
    lavorazione.CostoOrario,
    lavorazione.CostoTotale
FROM dbo.PreventiviRigheLavorazioni AS lavorazione
LEFT JOIN dbo.PreventiviRigheComponenti AS componente
    ON componente.IdRigaPreventivo = lavorazione.IdRigaPreventivo
   AND componente.IdRigaCompPrev = lavorazione.IdRigaCompPrev
ORDER BY
    IdRigaPreventivo,
    IdRigaCompPrev,
    TipoElemento,
    IdElemento;

/* 2. Totali riga attuali e valori attesi secondo le decisioni approvate. */
;WITH TotaliVoci AS
(
    SELECT
        riga.IdRigaPreventivo,
        ISNULL
        (
            (
                SELECT SUM
                (
                    ROUND
                    (
                        ISNULL(materiale.Quantita, 0)
                        * ISNULL(materiale.CostoUnitario, 0),
                        2
                    )
                )
                FROM dbo.PreventiviRigheMateriali AS materiale
                WHERE materiale.IdRigaPreventivo = riga.IdRigaPreventivo
            ),
            0
        ) AS TotaleMateriali,
        ISNULL
        (
            (
                SELECT SUM
                (
                    ROUND
                    (
                        (
                            ISNULL(lavorazione.TempoSetupMin, 0)
                            + ISNULL(lavorazione.TempoPezzoMin, 0)
                              * ISNULL(lavorazione.Quantita, 0)
                        ) / 60.0
                        * ISNULL(lavorazione.CostoOrario, 0)
                        + ISNULL(lavorazione.CostoFisso, 0),
                        2
                    )
                )
                FROM dbo.PreventiviRigheLavorazioni AS lavorazione
                WHERE lavorazione.IdRigaPreventivo = riga.IdRigaPreventivo
            ),
            0
        ) AS TotaleLavorazioni
    FROM dbo.PreventiviRighe AS riga
), ValoriAttesi AS
(
    SELECT
        riga.IdRigaPreventivo,
        riga.IdPreventivo,
        riga.RigaNr,
        tipo.Codice AS TipoRiga,
        tipo.RigaLibera,
        riga.IdVariantePreventivo,
        riga.Quantita,
        riga.CostoUnitarioLibero,
        riga.MarkupPerc,
        riga.PrezzoManuale,
        riga.PrezzoUnitarioVendita,
        riga.TotaleCosti AS TotaleCostiMemorizzato,
        riga.TotaleVendita AS TotaleVenditaMemorizzato,
        voci.TotaleMateriali,
        voci.TotaleLavorazioni,
        CONVERT
        (
            DECIMAL(18,2),
            CASE
                WHEN tipo.RigaLibera = 1
                    THEN ROUND(riga.Quantita * riga.CostoUnitarioLibero, 2)
                ELSE voci.TotaleMateriali + voci.TotaleLavorazioni
            END
        ) AS TotaleCostiAtteso
    FROM dbo.PreventiviRighe AS riga
    INNER JOIN dbo.TipiRigaPreventivo AS tipo
        ON tipo.IdTipoRiga = riga.IdTipoRiga
    INNER JOIN TotaliVoci AS voci
        ON voci.IdRigaPreventivo = riga.IdRigaPreventivo
)
SELECT
    atteso.IdRigaPreventivo,
    atteso.IdPreventivo,
    atteso.RigaNr,
    atteso.TipoRiga,
    atteso.RigaLibera,
    atteso.IdVariantePreventivo,
    atteso.Quantita,
    atteso.CostoUnitarioLibero,
    atteso.MarkupPerc,
    atteso.PrezzoManuale,
    atteso.TotaleMateriali,
    atteso.TotaleLavorazioni,
    atteso.TotaleCostiMemorizzato,
    atteso.TotaleCostiAtteso,
    atteso.TotaleCostiMemorizzato - atteso.TotaleCostiAtteso
        AS DifferenzaCosti,
    atteso.TotaleVenditaMemorizzato,
    CONVERT
    (
        DECIMAL(18,2),
        CASE
            WHEN atteso.PrezzoManuale = 1
                THEN ROUND(atteso.Quantita * atteso.PrezzoUnitarioVendita, 2)
            ELSE ROUND
            (
                atteso.TotaleCostiAtteso
                * (1 + ISNULL(atteso.MarkupPerc, 0) / 100.0),
                2
            )
        END
    ) AS TotaleVenditaAtteso
FROM ValoriAttesi AS atteso
ORDER BY
    atteso.IdPreventivo,
    atteso.RigaNr;

/* 3. Varianti attive selezionate: al massimo una per preventivo. */
SELECT
    preventivo.IdPreventivo,
    SUM
    (
        CASE
            WHEN variante.Attiva = 1 AND variante.VarianteScelta = 1 THEN 1
            ELSE 0
        END
    ) AS NumeroVariantiAttiveSelezionate
FROM dbo.Preventivi AS preventivo
LEFT JOIN dbo.PreventiviVarianti AS variante
    ON variante.IdPreventivo = preventivo.IdPreventivo
GROUP BY preventivo.IdPreventivo
ORDER BY preventivo.IdPreventivo;

/* 4. Totali testata attesi: righe comuni e sola variante attiva selezionata. */
;WITH VarianteSelezionata AS
(
    SELECT
        variante.IdPreventivo,
        MAX(variante.IdVariantePreventivo) AS IdVariantePreventivo
    FROM dbo.PreventiviVarianti AS variante
    WHERE variante.Attiva = 1
      AND variante.VarianteScelta = 1
    GROUP BY variante.IdPreventivo
    HAVING COUNT(*) = 1
)
SELECT
    preventivo.IdPreventivo,
    variante.IdVariantePreventivo AS IdVarianteSelezionata,
    preventivo.TotaleCosti AS TotaleCostiMemorizzato,
    ISNULL(SUM(riga.TotaleCosti), 0) AS TotaleCostiAtteso,
    preventivo.TotaleCosti - ISNULL(SUM(riga.TotaleCosti), 0)
        AS DifferenzaCosti,
    preventivo.TotaleVendita AS TotaleVenditaMemorizzato,
    ISNULL(SUM(riga.TotaleVendita), 0) AS TotaleVenditaAtteso,
    preventivo.TotaleVendita - ISNULL(SUM(riga.TotaleVendita), 0)
        AS DifferenzaVendita
FROM dbo.Preventivi AS preventivo
LEFT JOIN VarianteSelezionata AS variante
    ON variante.IdPreventivo = preventivo.IdPreventivo
LEFT JOIN dbo.PreventiviRighe AS riga
    ON riga.IdPreventivo = preventivo.IdPreventivo
   AND
   (
       riga.IdVariantePreventivo IS NULL
       OR riga.IdVariantePreventivo = variante.IdVariantePreventivo
   )
GROUP BY
    preventivo.IdPreventivo,
    variante.IdVariantePreventivo,
    preventivo.TotaleCosti,
    preventivo.TotaleVendita
ORDER BY preventivo.IdPreventivo;

/* 5. Ambiguita bloccanti. */
SELECT
    riga.IdRigaPreventivo,
    riga.IdPreventivo,
    riga.RigaNr,
    tipo.Codice AS TipoRiga,
    riga.CostoUnitarioLibero,
    (
        SELECT COUNT(*)
        FROM dbo.PreventiviRigheComponenti AS componente
        WHERE componente.IdRigaPreventivo = riga.IdRigaPreventivo
    ) AS NumeroComponenti,
    (
        SELECT COUNT(*)
        FROM dbo.PreventiviRigheMateriali AS materiale
        WHERE materiale.IdRigaPreventivo = riga.IdRigaPreventivo
    ) AS NumeroMateriali,
    (
        SELECT COUNT(*)
        FROM dbo.PreventiviRigheLavorazioni AS lavorazione
        WHERE lavorazione.IdRigaPreventivo = riga.IdRigaPreventivo
    ) AS NumeroLavorazioni,
    CASE
        WHEN riga.CostoUnitarioLibero IS NULL
            THEN N'Riga libera senza CostoUnitarioLibero'
        WHEN EXISTS
        (
            SELECT 1
            FROM dbo.PreventiviRigheComponenti AS componente
            WHERE componente.IdRigaPreventivo = riga.IdRigaPreventivo
        )
        OR EXISTS
        (
            SELECT 1
            FROM dbo.PreventiviRigheMateriali AS materiale
            WHERE materiale.IdRigaPreventivo = riga.IdRigaPreventivo
        )
        OR EXISTS
        (
            SELECT 1
            FROM dbo.PreventiviRigheLavorazioni AS lavorazione
            WHERE lavorazione.IdRigaPreventivo = riga.IdRigaPreventivo
        )
            THEN N'Riga libera con componenti, materiali o lavorazioni'
    END AS Anomalia
FROM dbo.PreventiviRighe AS riga
INNER JOIN dbo.TipiRigaPreventivo AS tipo
    ON tipo.IdTipoRiga = riga.IdTipoRiga
WHERE tipo.RigaLibera = 1
  AND
  (
      riga.CostoUnitarioLibero IS NULL
      OR EXISTS
      (
          SELECT 1
          FROM dbo.PreventiviRigheComponenti AS componente
          WHERE componente.IdRigaPreventivo = riga.IdRigaPreventivo
      )
      OR EXISTS
      (
          SELECT 1
          FROM dbo.PreventiviRigheMateriali AS materiale
          WHERE materiale.IdRigaPreventivo = riga.IdRigaPreventivo
      )
      OR EXISTS
      (
          SELECT 1
          FROM dbo.PreventiviRigheLavorazioni AS lavorazione
          WHERE lavorazione.IdRigaPreventivo = riga.IdRigaPreventivo
      )
  )
ORDER BY
    riga.IdPreventivo,
    riga.RigaNr;

IF EXISTS
(
    SELECT 1
    FROM dbo.PreventiviRighe AS riga
    INNER JOIN dbo.TipiRigaPreventivo AS tipo
        ON tipo.IdTipoRiga = riga.IdTipoRiga
    WHERE tipo.RigaLibera = 1
      AND
      (
          riga.CostoUnitarioLibero IS NULL
          OR EXISTS
          (
              SELECT 1
              FROM dbo.PreventiviRigheComponenti AS componente
              WHERE componente.IdRigaPreventivo = riga.IdRigaPreventivo
          )
          OR EXISTS
          (
              SELECT 1
              FROM dbo.PreventiviRigheMateriali AS materiale
              WHERE materiale.IdRigaPreventivo = riga.IdRigaPreventivo
          )
          OR EXISTS
          (
              SELECT 1
              FROM dbo.PreventiviRigheLavorazioni AS lavorazione
              WHERE lavorazione.IdRigaPreventivo = riga.IdRigaPreventivo
          )
      )
)
BEGIN
    THROW 51902, 'TEC-009: esistono righe libere da riconciliare prima del ricalcolo.', 1;
END;

IF EXISTS
(
    SELECT variante.IdPreventivo
    FROM dbo.PreventiviVarianti AS variante
    WHERE variante.Attiva = 1
      AND variante.VarianteScelta = 1
    GROUP BY variante.IdPreventivo
    HAVING COUNT(*) > 1
)
BEGIN
    THROW 51903, 'TEC-009: un preventivo ha piu varianti attive selezionate.', 1;
END;

SELECT N'OK - diagnostica TEC-009 completata senza ambiguita bloccanti.' AS Esito;
