/*
    TEC-001 - Diagnostica pre-migrazione della gerarchia dei componenti

    Scopo:
    - verificare che componenti, materiali e lavorazioni siano riconducibili
      senza ambiguita alla nuova identita operativa IdRigaCompPrev;
    - ricostruire il candidato padre operativo senza modificare i dati;
    - evidenziare le quantita calcolate non allineate alla gerarchia approvata.

    Lo script e intenzionalmente di sola lettura.
    Non seleziona autonomamente un database: deve essere eseguito nel database
    esplicitamente scelto dall'operatore.
*/

SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @ErroreStrutturale BIT = 0;

SELECT
    DB_NAME() AS DatabaseCorrente,
    CONVERT(NVARCHAR(128), SERVERPROPERTY('ServerName')) AS ServerCorrente,
    SYSDATETIME() AS DataVerifica;

IF OBJECT_ID(N'dbo.PreventiviRighe', N'U') IS NULL
   OR OBJECT_ID(N'dbo.PreventiviRigheComponenti', N'U') IS NULL
   OR OBJECT_ID(N'dbo.PreventiviRigheMateriali', N'U') IS NULL
   OR OBJECT_ID(N'dbo.PreventiviRigheLavorazioni', N'U') IS NULL
   OR OBJECT_ID(N'dbo.DistintaBaseNodi', N'U') IS NULL
BEGIN
    THROW 51001, 'TEC-001: una o piu tabelle richieste non esistono nel database corrente.', 1;
END;

IF COL_LENGTH(N'dbo.PreventiviRigheComponenti', N'IdRigaCompPrev') IS NULL
   OR COL_LENGTH(N'dbo.PreventiviRigheComponenti', N'IdRigaPreventivo') IS NULL
   OR COL_LENGTH(N'dbo.PreventiviRigheComponenti', N'IdNodoDistinta') IS NULL
   OR COL_LENGTH(N'dbo.PreventiviRigheComponenti', N'IdNodoPadre') IS NULL
   OR COL_LENGTH(N'dbo.PreventiviRigheMateriali', N'IdRigaPreventivo') IS NULL
   OR COL_LENGTH(N'dbo.PreventiviRigheMateriali', N'IdNodoDistinta') IS NULL
   OR COL_LENGTH(N'dbo.PreventiviRigheLavorazioni', N'IdRigaPreventivo') IS NULL
   OR COL_LENGTH(N'dbo.PreventiviRigheLavorazioni', N'IdNodoDistinta') IS NULL
BEGIN
    THROW 51002, 'TEC-001: lo schema corrente non contiene tutte le colonne richieste dalla diagnostica.', 1;
END;

SELECT
    'Righe preventivo' AS Voce,
    COUNT_BIG(*) AS Quantita
FROM dbo.PreventiviRighe
UNION ALL
SELECT 'Componenti', COUNT_BIG(*)
FROM dbo.PreventiviRigheComponenti
UNION ALL
SELECT 'Materiali', COUNT_BIG(*)
FROM dbo.PreventiviRigheMateriali
UNION ALL
SELECT 'Lavorazioni', COUNT_BIG(*)
FROM dbo.PreventiviRigheLavorazioni;

/* Componenti che condividono la coppia storica riga-nodo. */
SELECT
    c.IdRigaPreventivo,
    c.IdNodoDistinta,
    COUNT_BIG(*) AS NumeroComponenti,
    STRING_AGG(CONVERT(NVARCHAR(MAX), c.IdRigaCompPrev), N', ')
        WITHIN GROUP (ORDER BY c.IdRigaCompPrev) AS IdComponenti
FROM dbo.PreventiviRigheComponenti AS c
GROUP BY
    c.IdRigaPreventivo,
    c.IdNodoDistinta
HAVING COUNT_BIG(*) > 1;

IF EXISTS
(
    SELECT 1
    FROM dbo.PreventiviRigheComponenti AS c
    GROUP BY
        c.IdRigaPreventivo,
        c.IdNodoDistinta
    HAVING COUNT_BIG(*) > 1
)
BEGIN
    SET @ErroreStrutturale = 1;
END;

/* Riferimenti alla distinta non piu disponibili. */
SELECT
    c.IdRigaCompPrev,
    c.IdRigaPreventivo,
    c.IdNodoDistinta,
    c.IdNodoPadre,
    c.DescrizioneNodo,
    CASE
        WHEN c.IdNodoDistinta IS NOT NULL AND nodo.IdNodoDistinta IS NULL
            THEN N'IdNodoDistinta inesistente'
        WHEN c.IdNodoPadre IS NOT NULL AND padre.IdNodoDistinta IS NULL
            THEN N'IdNodoPadre inesistente'
    END AS Anomalia
FROM dbo.PreventiviRigheComponenti AS c
LEFT JOIN dbo.DistintaBaseNodi AS nodo
    ON nodo.IdNodoDistinta = c.IdNodoDistinta
LEFT JOIN dbo.DistintaBaseNodi AS padre
    ON padre.IdNodoDistinta = c.IdNodoPadre
WHERE (c.IdNodoDistinta IS NOT NULL AND nodo.IdNodoDistinta IS NULL)
   OR (c.IdNodoPadre IS NOT NULL AND padre.IdNodoDistinta IS NULL);

IF EXISTS
(
    SELECT 1
    FROM dbo.PreventiviRigheComponenti AS c
    LEFT JOIN dbo.DistintaBaseNodi AS nodo
        ON nodo.IdNodoDistinta = c.IdNodoDistinta
    LEFT JOIN dbo.DistintaBaseNodi AS padre
        ON padre.IdNodoDistinta = c.IdNodoPadre
    WHERE (c.IdNodoDistinta IS NOT NULL AND nodo.IdNodoDistinta IS NULL)
       OR (c.IdNodoPadre IS NOT NULL AND padre.IdNodoDistinta IS NULL)
)
BEGIN
    SET @ErroreStrutturale = 1;
END;

/* Candidato padre operativo ricavato dal riferimento storico alla distinta. */
SELECT
    figlio.IdRigaCompPrev,
    figlio.IdRigaPreventivo,
    figlio.IdNodoDistinta,
    figlio.IdNodoPadre,
    figlio.DescrizioneNodo,
    COUNT(padre.IdRigaCompPrev) AS NumeroPadriCandidati,
    MIN(padre.IdRigaCompPrev) AS IdRigaCompPrevPadreCandidato
FROM dbo.PreventiviRigheComponenti AS figlio
LEFT JOIN dbo.PreventiviRigheComponenti AS padre
    ON padre.IdRigaPreventivo = figlio.IdRigaPreventivo
   AND padre.IdNodoDistinta = figlio.IdNodoPadre
WHERE figlio.IdNodoPadre IS NOT NULL
GROUP BY
    figlio.IdRigaCompPrev,
    figlio.IdRigaPreventivo,
    figlio.IdNodoDistinta,
    figlio.IdNodoPadre,
    figlio.DescrizioneNodo
ORDER BY
    figlio.IdRigaPreventivo,
    figlio.IdRigaCompPrev;

IF EXISTS
(
    SELECT 1
    FROM dbo.PreventiviRigheComponenti AS figlio
    LEFT JOIN dbo.PreventiviRigheComponenti AS padre
        ON padre.IdRigaPreventivo = figlio.IdRigaPreventivo
       AND padre.IdNodoDistinta = figlio.IdNodoPadre
    WHERE figlio.IdNodoPadre IS NOT NULL
    GROUP BY figlio.IdRigaCompPrev
    HAVING COUNT(padre.IdRigaCompPrev) <> 1
)
BEGIN
    SET @ErroreStrutturale = 1;
END;

/*
    Materiali: per la migrazione automatica serve un solo candidato.
    Zero candidati richiede la classificazione esplicita come elemento comune.
*/
SELECT
    materiale.IdRigaMatPrev,
    materiale.IdRigaPreventivo,
    materiale.IdNodoDistinta,
    materiale.DescrizioneMateriale,
    COUNT(componente.IdRigaCompPrev) AS NumeroComponentiCandidati,
    MIN(componente.IdRigaCompPrev) AS IdRigaCompPrevCandidato
FROM dbo.PreventiviRigheMateriali AS materiale
LEFT JOIN dbo.PreventiviRigheComponenti AS componente
    ON componente.IdRigaPreventivo = materiale.IdRigaPreventivo
   AND
   (
       componente.IdNodoDistinta = materiale.IdNodoDistinta
       OR
       (
           componente.IdNodoDistinta IS NULL
           AND materiale.IdNodoDistinta IS NULL
       )
   )
GROUP BY
    materiale.IdRigaMatPrev,
    materiale.IdRigaPreventivo,
    materiale.IdNodoDistinta,
    materiale.DescrizioneMateriale
ORDER BY materiale.IdRigaMatPrev;

IF EXISTS
(
    SELECT 1
    FROM dbo.PreventiviRigheMateriali AS materiale
    LEFT JOIN dbo.PreventiviRigheComponenti AS componente
        ON componente.IdRigaPreventivo = materiale.IdRigaPreventivo
       AND
       (
           componente.IdNodoDistinta = materiale.IdNodoDistinta
           OR
           (
               componente.IdNodoDistinta IS NULL
               AND materiale.IdNodoDistinta IS NULL
           )
       )
    GROUP BY materiale.IdRigaMatPrev
    HAVING COUNT(componente.IdRigaCompPrev) <> 1
)
BEGIN
    SET @ErroreStrutturale = 1;
END;

/*
    Lavorazioni: per la migrazione automatica serve un solo candidato.
    Zero candidati richiede la classificazione esplicita come elemento comune.
*/
SELECT
    lavorazione.IdRigaLavPrev,
    lavorazione.IdRigaPreventivo,
    lavorazione.IdNodoDistinta,
    lavorazione.DescrizioneLavorazione,
    COUNT(componente.IdRigaCompPrev) AS NumeroComponentiCandidati,
    MIN(componente.IdRigaCompPrev) AS IdRigaCompPrevCandidato
FROM dbo.PreventiviRigheLavorazioni AS lavorazione
LEFT JOIN dbo.PreventiviRigheComponenti AS componente
    ON componente.IdRigaPreventivo = lavorazione.IdRigaPreventivo
   AND
   (
       componente.IdNodoDistinta = lavorazione.IdNodoDistinta
       OR
       (
           componente.IdNodoDistinta IS NULL
           AND lavorazione.IdNodoDistinta IS NULL
       )
   )
GROUP BY
    lavorazione.IdRigaLavPrev,
    lavorazione.IdRigaPreventivo,
    lavorazione.IdNodoDistinta,
    lavorazione.DescrizioneLavorazione
ORDER BY lavorazione.IdRigaLavPrev;

IF EXISTS
(
    SELECT 1
    FROM dbo.PreventiviRigheLavorazioni AS lavorazione
    LEFT JOIN dbo.PreventiviRigheComponenti AS componente
        ON componente.IdRigaPreventivo = lavorazione.IdRigaPreventivo
       AND
       (
           componente.IdNodoDistinta = lavorazione.IdNodoDistinta
           OR
           (
               componente.IdNodoDistinta IS NULL
               AND lavorazione.IdNodoDistinta IS NULL
           )
       )
    GROUP BY lavorazione.IdRigaLavPrev
    HAVING COUNT(componente.IdRigaCompPrev) <> 1
)
BEGIN
    SET @ErroreStrutturale = 1;
END;

/*
    Componenti senza nodo: l'origine Articolo e l'origine Libero non sono
    distinguibili dai dati storici. Devono essere classificati esplicitamente
    prima di rendere obbligatorio TipoOrigineComponente.
*/
SELECT
    c.IdRigaCompPrev,
    c.IdRigaPreventivo,
    c.DescrizioneNodo,
    c.QuantitaBase,
    c.QuantitaCalcolata,
    N'Classificare come Articolo o Libero' AS AzioneRichiesta
FROM dbo.PreventiviRigheComponenti AS c
WHERE c.IdNodoDistinta IS NULL
ORDER BY
    c.IdRigaPreventivo,
    c.IdRigaCompPrev;

/* Quantita attesa secondo la gerarchia approvata dalla Decisione 161. */
;WITH MappaPadri AS
(
    SELECT
        figlio.IdRigaCompPrev,
        figlio.IdRigaPreventivo,
        MIN(padre.IdRigaCompPrev) AS IdRigaCompPrevPadre
    FROM dbo.PreventiviRigheComponenti AS figlio
    LEFT JOIN dbo.PreventiviRigheComponenti AS padre
        ON padre.IdRigaPreventivo = figlio.IdRigaPreventivo
       AND padre.IdNodoDistinta = figlio.IdNodoPadre
    GROUP BY
        figlio.IdRigaCompPrev,
        figlio.IdRigaPreventivo
),
QuantitaGerarchiche AS
(
    SELECT
        componente.IdRigaCompPrev,
        componente.IdRigaPreventivo,
        componente.DescrizioneNodo,
        componente.QuantitaBase,
        componente.QuantitaCalcolata,
        CONVERT(DECIMAL(38,8), riga.Quantita * componente.QuantitaBase)
            AS QuantitaAttesa,
        0 AS Profondita,
        CONVERT(NVARCHAR(MAX), N'|' + CONVERT(NVARCHAR(20), componente.IdRigaCompPrev) + N'|')
            AS Percorso
    FROM dbo.PreventiviRigheComponenti AS componente
    INNER JOIN dbo.PreventiviRighe AS riga
        ON riga.IdRigaPreventivo = componente.IdRigaPreventivo
    INNER JOIN MappaPadri AS mappa
        ON mappa.IdRigaCompPrev = componente.IdRigaCompPrev
    WHERE mappa.IdRigaCompPrevPadre IS NULL

    UNION ALL

    SELECT
        figlio.IdRigaCompPrev,
        figlio.IdRigaPreventivo,
        figlio.DescrizioneNodo,
        figlio.QuantitaBase,
        figlio.QuantitaCalcolata,
        CONVERT(DECIMAL(38,8), padre.QuantitaAttesa * figlio.QuantitaBase),
        padre.Profondita + 1,
        CONVERT(
            NVARCHAR(MAX),
            padre.Percorso + CONVERT(NVARCHAR(20), figlio.IdRigaCompPrev) + N'|'
        )
    FROM QuantitaGerarchiche AS padre
    INNER JOIN MappaPadri AS mappa
        ON mappa.IdRigaCompPrevPadre = padre.IdRigaCompPrev
       AND mappa.IdRigaPreventivo = padre.IdRigaPreventivo
    INNER JOIN dbo.PreventiviRigheComponenti AS figlio
        ON figlio.IdRigaCompPrev = mappa.IdRigaCompPrev
    WHERE padre.Profondita < 100
      AND CHARINDEX(
            N'|' + CONVERT(NVARCHAR(20), figlio.IdRigaCompPrev) + N'|',
            padre.Percorso
          ) = 0
)
SELECT
    IdRigaCompPrev,
    IdRigaPreventivo,
    DescrizioneNodo,
    QuantitaBase,
    QuantitaCalcolata,
    CONVERT(DECIMAL(18,4), QuantitaAttesa) AS QuantitaAttesa,
    CONVERT(DECIMAL(18,4), QuantitaCalcolata - QuantitaAttesa) AS Differenza,
    Profondita
FROM QuantitaGerarchiche
WHERE QuantitaCalcolata <> CONVERT(DECIMAL(18,4), QuantitaAttesa)
ORDER BY
    IdRigaPreventivo,
    Profondita,
    IdRigaCompPrev
OPTION (MAXRECURSION 100);

/* Componenti non raggiunti da una radice: possibile ciclo nella gerarchia. */
;WITH MappaPadri AS
(
    SELECT
        figlio.IdRigaCompPrev,
        figlio.IdRigaPreventivo,
        MIN(padre.IdRigaCompPrev) AS IdRigaCompPrevPadre
    FROM dbo.PreventiviRigheComponenti AS figlio
    LEFT JOIN dbo.PreventiviRigheComponenti AS padre
        ON padre.IdRigaPreventivo = figlio.IdRigaPreventivo
       AND padre.IdNodoDistinta = figlio.IdNodoPadre
    GROUP BY
        figlio.IdRigaCompPrev,
        figlio.IdRigaPreventivo
),
Raggiungibili AS
(
    SELECT
        mappa.IdRigaCompPrev,
        mappa.IdRigaPreventivo,
        0 AS Profondita
    FROM MappaPadri AS mappa
    WHERE mappa.IdRigaCompPrevPadre IS NULL

    UNION ALL

    SELECT
        figlio.IdRigaCompPrev,
        figlio.IdRigaPreventivo,
        padre.Profondita + 1
    FROM Raggiungibili AS padre
    INNER JOIN MappaPadri AS figlio
        ON figlio.IdRigaCompPrevPadre = padre.IdRigaCompPrev
       AND figlio.IdRigaPreventivo = padre.IdRigaPreventivo
    WHERE padre.Profondita < 100
)
SELECT
    componente.IdRigaCompPrev,
    componente.IdRigaPreventivo,
    componente.IdNodoDistinta,
    componente.IdNodoPadre,
    componente.DescrizioneNodo,
    N'Componente non raggiungibile da una radice' AS Anomalia
FROM dbo.PreventiviRigheComponenti AS componente
WHERE NOT EXISTS
(
    SELECT 1
    FROM Raggiungibili AS raggiungibile
    WHERE raggiungibile.IdRigaCompPrev = componente.IdRigaCompPrev
)
ORDER BY
    componente.IdRigaPreventivo,
    componente.IdRigaCompPrev
OPTION (MAXRECURSION 100);

DECLARE @ComponentiNonRaggiungibili BIGINT;

;WITH MappaPadri AS
(
    SELECT
        figlio.IdRigaCompPrev,
        figlio.IdRigaPreventivo,
        MIN(padre.IdRigaCompPrev) AS IdRigaCompPrevPadre
    FROM dbo.PreventiviRigheComponenti AS figlio
    LEFT JOIN dbo.PreventiviRigheComponenti AS padre
        ON padre.IdRigaPreventivo = figlio.IdRigaPreventivo
       AND padre.IdNodoDistinta = figlio.IdNodoPadre
    GROUP BY
        figlio.IdRigaCompPrev,
        figlio.IdRigaPreventivo
),
Raggiungibili AS
(
    SELECT
        mappa.IdRigaCompPrev,
        mappa.IdRigaPreventivo,
        0 AS Profondita
    FROM MappaPadri AS mappa
    WHERE mappa.IdRigaCompPrevPadre IS NULL

    UNION ALL

    SELECT
        figlio.IdRigaCompPrev,
        figlio.IdRigaPreventivo,
        padre.Profondita + 1
    FROM Raggiungibili AS padre
    INNER JOIN MappaPadri AS figlio
        ON figlio.IdRigaCompPrevPadre = padre.IdRigaCompPrev
       AND figlio.IdRigaPreventivo = padre.IdRigaPreventivo
    WHERE padre.Profondita < 100
)
SELECT
    @ComponentiNonRaggiungibili = COUNT_BIG(*)
FROM dbo.PreventiviRigheComponenti AS componente
WHERE NOT EXISTS
(
    SELECT 1
    FROM Raggiungibili AS raggiungibile
    WHERE raggiungibile.IdRigaCompPrev = componente.IdRigaCompPrev
)
OPTION (MAXRECURSION 100);

IF @ComponentiNonRaggiungibili > 0
BEGIN
    SET @ErroreStrutturale = 1;
END;

IF @ErroreStrutturale = 1
BEGIN
    THROW 51003, 'TEC-001: diagnostica non superata. Correggere o classificare le anomalie prima della migrazione.', 1;
END;

SELECT
    N'OK' AS Esito,
    N'Nessuna associazione strutturale mancante o multipla rilevata. Verificare separatamente classificazione origine e differenze quantitative mostrate.'
        AS Messaggio;
