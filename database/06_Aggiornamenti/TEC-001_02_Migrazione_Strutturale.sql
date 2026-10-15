/*
    TEC-001 - Migrazione strutturale della gerarchia dei componenti

    PREREQUISITI OPERATIVI OBBLIGATORI
    ---------------------------------
    1. Eseguire prima TEC-001_01_Diagnostica_PreMigrazione.sql.
    2. Verificare che la diagnostica termini con esito OK.
    3. Eseguire in una finestra di manutenzione senza scritture applicative.
    4. Avere pronta la versione C# che valorizza i nuovi campi.
    5. Eseguire un backup e identificare esplicitamente l'ambiente.
    6. Utilizzare un client che interpreti i separatori di batch GO.
    7. Eseguire subito dopo TEC-001_03_Procedure_Operative.sql.

    Lo script NON seleziona autonomamente il database.
    Tutte le modifiche sono racchiuse in una sola transazione.

    Classificazione storica approvata:
    - IdRigaCompPrev 10: origine Libero.
*/

SET NOCOUNT ON;
SET XACT_ABORT ON;
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;

BEGIN TRY
    BEGIN TRANSACTION;

    IF OBJECT_ID(N'dbo.PreventiviRighe', N'U') IS NULL
       OR OBJECT_ID(N'dbo.PreventiviRigheComponenti', N'U') IS NULL
       OR OBJECT_ID(N'dbo.PreventiviRigheMateriali', N'U') IS NULL
       OR OBJECT_ID(N'dbo.PreventiviRigheLavorazioni', N'U') IS NULL
       OR OBJECT_ID(N'dbo.DistintaBaseNodi', N'U') IS NULL
       OR OBJECT_ID(N'dbo.Articoli', N'U') IS NULL
    BEGIN
        THROW 51101, 'TEC-001: una o piu tabelle richieste non esistono nel database corrente.', 1;
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
        THROW 51102, 'TEC-001: lo schema corrente non contiene tutte le colonne storiche richieste.', 1;
    END;

    IF COL_LENGTH(N'dbo.PreventiviRigheComponenti', N'IdRigaCompPrevPadre') IS NULL
    BEGIN
        ALTER TABLE dbo.PreventiviRigheComponenti
            ADD IdRigaCompPrevPadre INT NULL;
    END;

    IF COL_LENGTH(N'dbo.PreventiviRigheComponenti', N'TipoOrigineComponente') IS NULL
    BEGIN
        ALTER TABLE dbo.PreventiviRigheComponenti
            ADD TipoOrigineComponente NVARCHAR(20) NULL;
    END;

    IF COL_LENGTH(N'dbo.PreventiviRigheComponenti', N'IdArticoloOrigine') IS NULL
    BEGIN
        ALTER TABLE dbo.PreventiviRigheComponenti
            ADD IdArticoloOrigine INT NULL;
    END;

    IF COL_LENGTH(N'dbo.PreventiviRigheMateriali', N'IdRigaCompPrev') IS NULL
    BEGIN
        ALTER TABLE dbo.PreventiviRigheMateriali
            ADD IdRigaCompPrev INT NULL;
    END;

    IF COL_LENGTH(N'dbo.PreventiviRigheLavorazioni', N'IdRigaCompPrev') IS NULL
    BEGIN
        ALTER TABLE dbo.PreventiviRigheLavorazioni
            ADD IdRigaCompPrev INT NULL;
    END;

    /*
        La transazione resta aperta oltre GO. Il secondo batch viene compilato
        quando le nuove colonne sono gia visibili nella stessa sessione.
    */
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0
    BEGIN
        ROLLBACK TRANSACTION;
    END;

    THROW;
END CATCH;
GO

DECLARE @NomeVincoloOrigine SYSNAME = N'CK_PreventiviRigheComponenti_Origine';
DECLARE @EseguireMigrazioneDati BIT =
    CASE
        WHEN EXISTS
        (
            SELECT 1
            FROM sys.check_constraints
            WHERE parent_object_id = OBJECT_ID(N'dbo.PreventiviRigheComponenti')
              AND name = @NomeVincoloOrigine
        )
            THEN 0
        ELSE 1
    END;

BEGIN TRY
    IF XACT_STATE() <> 1
    BEGIN
        THROW 51100, 'TEC-001: transazione di migrazione non attiva. Eseguire lo script completo con un client compatibile con GO.', 1;
    END;

    IF @EseguireMigrazioneDati = 1
    BEGIN
        DECLARE @ClassificazioniStoriche TABLE
        (
            IdRigaCompPrev INT NOT NULL PRIMARY KEY,
            IdRigaPreventivoAtteso INT NOT NULL,
            DescrizioneAttesa NVARCHAR(400) NOT NULL,
            TipoOrigineComponente NVARCHAR(20) NOT NULL,
            IdArticoloOrigine INT NULL
        );

        INSERT INTO @ClassificazioniStoriche
        (
            IdRigaCompPrev,
            IdRigaPreventivoAtteso,
            DescrizioneAttesa,
            TipoOrigineComponente,
            IdArticoloOrigine
        )
        VALUES
        (
            10,
            4,
            N'Prova componente',
            N'Libero',
            NULL
        );

        IF EXISTS
        (
            SELECT 1
            FROM @ClassificazioniStoriche AS classificazione
            LEFT JOIN dbo.PreventiviRigheComponenti AS componente
                ON componente.IdRigaCompPrev = classificazione.IdRigaCompPrev
            WHERE componente.IdRigaCompPrev IS NULL
               OR componente.IdRigaPreventivo <> classificazione.IdRigaPreventivoAtteso
               OR componente.DescrizioneNodo <> classificazione.DescrizioneAttesa
               OR componente.IdNodoDistinta IS NOT NULL
        )
        BEGIN
            THROW 51103, 'TEC-001: la classificazione storica approvata non corrisponde ai dati correnti.', 1;
        END;

        IF EXISTS
        (
            SELECT 1
            FROM dbo.PreventiviRigheComponenti AS componente
            LEFT JOIN @ClassificazioniStoriche AS classificazione
                ON classificazione.IdRigaCompPrev = componente.IdRigaCompPrev
            WHERE componente.IdNodoDistinta IS NULL
              AND componente.TipoOrigineComponente IS NULL
              AND classificazione.IdRigaCompPrev IS NULL
        )
        BEGIN
            THROW 51104, 'TEC-001: esistono componenti senza nodo e senza classificazione storica approvata.', 1;
        END;

        IF EXISTS
        (
            SELECT 1
            FROM dbo.PreventiviRigheComponenti AS componente
            GROUP BY
                componente.IdRigaPreventivo,
                componente.IdNodoDistinta
            HAVING COUNT_BIG(*) > 1
        )
        BEGIN
            THROW 51105, 'TEC-001: componenti duplicati per riga e nodo impediscono la migrazione automatica.', 1;
        END;

        IF EXISTS
        (
            SELECT 1
            FROM dbo.PreventiviRigheComponenti AS componente
            LEFT JOIN dbo.DistintaBaseNodi AS nodo
                ON nodo.IdNodoDistinta = componente.IdNodoDistinta
            WHERE componente.IdNodoDistinta IS NOT NULL
              AND nodo.IdNodoDistinta IS NULL
        )
        BEGIN
            THROW 51106, 'TEC-001: uno o piu componenti riferiscono nodi distinta inesistenti.', 1;
        END;

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
            THROW 51107, 'TEC-001: uno o piu componenti non hanno un padre operativo univoco.', 1;
        END;

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
            THROW 51108, 'TEC-001: uno o piu materiali non hanno un componente candidato univoco.', 1;
        END;

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
            THROW 51109, 'TEC-001: una o piu lavorazioni non hanno un componente candidato univoco.', 1;
        END;

        UPDATE componente
        SET
            TipoOrigineComponente = N'Distinta',
            IdArticoloOrigine = nodo.IdArticolo
        FROM dbo.PreventiviRigheComponenti AS componente
        INNER JOIN dbo.DistintaBaseNodi AS nodo
            ON nodo.IdNodoDistinta = componente.IdNodoDistinta
        WHERE componente.IdNodoDistinta IS NOT NULL;

        UPDATE componente
        SET
            TipoOrigineComponente = classificazione.TipoOrigineComponente,
            IdArticoloOrigine = classificazione.IdArticoloOrigine
        FROM dbo.PreventiviRigheComponenti AS componente
        INNER JOIN @ClassificazioniStoriche AS classificazione
            ON classificazione.IdRigaCompPrev = componente.IdRigaCompPrev;

        UPDATE figlio
        SET IdRigaCompPrevPadre = padre.IdRigaCompPrev
        FROM dbo.PreventiviRigheComponenti AS figlio
        INNER JOIN dbo.PreventiviRigheComponenti AS padre
            ON padre.IdRigaPreventivo = figlio.IdRigaPreventivo
           AND padre.IdNodoDistinta = figlio.IdNodoPadre
        WHERE figlio.IdNodoPadre IS NOT NULL;

        UPDATE materiale
        SET IdRigaCompPrev = componente.IdRigaCompPrev
        FROM dbo.PreventiviRigheMateriali AS materiale
        INNER JOIN dbo.PreventiviRigheComponenti AS componente
            ON componente.IdRigaPreventivo = materiale.IdRigaPreventivo
           AND
           (
               componente.IdNodoDistinta = materiale.IdNodoDistinta
               OR
               (
                   componente.IdNodoDistinta IS NULL
                   AND materiale.IdNodoDistinta IS NULL
               )
           );

        UPDATE lavorazione
        SET IdRigaCompPrev = componente.IdRigaCompPrev
        FROM dbo.PreventiviRigheLavorazioni AS lavorazione
        INNER JOIN dbo.PreventiviRigheComponenti AS componente
            ON componente.IdRigaPreventivo = lavorazione.IdRigaPreventivo
           AND
           (
               componente.IdNodoDistinta = lavorazione.IdNodoDistinta
               OR
               (
                   componente.IdNodoDistinta IS NULL
                   AND lavorazione.IdNodoDistinta IS NULL
               )
           );

        IF EXISTS
        (
            SELECT 1
            FROM dbo.PreventiviRigheMateriali
            WHERE IdRigaCompPrev IS NULL
        )
           OR EXISTS
        (
            SELECT 1
            FROM dbo.PreventiviRigheLavorazioni
            WHERE IdRigaCompPrev IS NULL
        )
        BEGIN
            THROW 51113, 'TEC-001: la migrazione iniziale ha lasciato materiali o lavorazioni da classificare.', 1;
        END;

        DECLARE @QuantitaAttese TABLE
        (
            IdRigaCompPrev INT NOT NULL PRIMARY KEY,
            QuantitaAttesa DECIMAL(18,4) NOT NULL
        );

        ;WITH QuantitaGerarchiche AS
        (
            SELECT
                componente.IdRigaCompPrev,
                componente.IdRigaPreventivo,
                CONVERT(DECIMAL(38,8), riga.Quantita * componente.QuantitaBase)
                    AS QuantitaAttesa,
                0 AS Profondita,
                CONVERT(
                    NVARCHAR(MAX),
                    N'|' + CONVERT(NVARCHAR(20), componente.IdRigaCompPrev) + N'|'
                ) AS Percorso
            FROM dbo.PreventiviRigheComponenti AS componente
            INNER JOIN dbo.PreventiviRighe AS riga
                ON riga.IdRigaPreventivo = componente.IdRigaPreventivo
            WHERE componente.IdRigaCompPrevPadre IS NULL

            UNION ALL

            SELECT
                figlio.IdRigaCompPrev,
                figlio.IdRigaPreventivo,
                CONVERT(DECIMAL(38,8), padre.QuantitaAttesa * figlio.QuantitaBase),
                padre.Profondita + 1,
                CONVERT(
                    NVARCHAR(MAX),
                    padre.Percorso + CONVERT(NVARCHAR(20), figlio.IdRigaCompPrev) + N'|'
                )
            FROM QuantitaGerarchiche AS padre
            INNER JOIN dbo.PreventiviRigheComponenti AS figlio
                ON figlio.IdRigaCompPrevPadre = padre.IdRigaCompPrev
               AND figlio.IdRigaPreventivo = padre.IdRigaPreventivo
            WHERE padre.Profondita < 100
              AND CHARINDEX(
                    N'|' + CONVERT(NVARCHAR(20), figlio.IdRigaCompPrev) + N'|',
                    padre.Percorso
                  ) = 0
        )
        INSERT INTO @QuantitaAttese
        (
            IdRigaCompPrev,
            QuantitaAttesa
        )
        SELECT
            IdRigaCompPrev,
            CONVERT(DECIMAL(18,4), QuantitaAttesa)
        FROM QuantitaGerarchiche
        OPTION (MAXRECURSION 100);

        IF
        (
            SELECT COUNT_BIG(*)
            FROM @QuantitaAttese
        ) <>
        (
            SELECT COUNT_BIG(*)
            FROM dbo.PreventiviRigheComponenti
        )
        BEGIN
            THROW 51110, 'TEC-001: la gerarchia contiene componenti non raggiungibili o ciclici.', 1;
        END;

        UPDATE componente
        SET QuantitaCalcolata = quantita.QuantitaAttesa
        FROM dbo.PreventiviRigheComponenti AS componente
        INNER JOIN @QuantitaAttese AS quantita
            ON quantita.IdRigaCompPrev = componente.IdRigaCompPrev
        WHERE componente.QuantitaCalcolata <> quantita.QuantitaAttesa;
    END;

    IF EXISTS
    (
        SELECT 1
        FROM dbo.PreventiviRigheComponenti
        WHERE TipoOrigineComponente IS NULL
    )
    BEGIN
        THROW 51111, 'TEC-001: esistono componenti privi del tipo origine.', 1;
    END;

    IF EXISTS
    (
        SELECT 1
        FROM dbo.PreventiviRigheComponenti
        WHERE QuantitaBase <= 0
           OR QuantitaCalcolata <= 0
           OR IdRigaCompPrevPadre = IdRigaCompPrev
    )
    BEGIN
        THROW 51112, 'TEC-001: quantita non positive o riferimenti del componente a se stesso.', 1;
    END;

    IF NOT EXISTS
    (
        SELECT 1
        FROM sys.indexes
        WHERE object_id = OBJECT_ID(N'dbo.PreventiviRigheComponenti')
          AND name = N'UX_PreventiviRigheComponenti_RigaComponente'
    )
    BEGIN
        CREATE UNIQUE INDEX UX_PreventiviRigheComponenti_RigaComponente
            ON dbo.PreventiviRigheComponenti
            (
                IdRigaPreventivo,
                IdRigaCompPrev
            );
    END;

    IF NOT EXISTS
    (
        SELECT 1
        FROM sys.indexes
        WHERE object_id = OBJECT_ID(N'dbo.PreventiviRigheComponenti')
          AND name = N'IX_PreventiviRigheComponenti_RigaPadre'
    )
    BEGIN
        CREATE INDEX IX_PreventiviRigheComponenti_RigaPadre
            ON dbo.PreventiviRigheComponenti
            (
                IdRigaPreventivo,
                IdRigaCompPrevPadre
            );
    END;

    IF NOT EXISTS
    (
        SELECT 1
        FROM sys.indexes
        WHERE object_id = OBJECT_ID(N'dbo.PreventiviRigheMateriali')
          AND name = N'IX_PreventiviRigheMateriali_RigaComponente'
    )
    BEGIN
        CREATE INDEX IX_PreventiviRigheMateriali_RigaComponente
            ON dbo.PreventiviRigheMateriali
            (
                IdRigaPreventivo,
                IdRigaCompPrev
            );
    END;

    IF NOT EXISTS
    (
        SELECT 1
        FROM sys.indexes
        WHERE object_id = OBJECT_ID(N'dbo.PreventiviRigheLavorazioni')
          AND name = N'IX_PreventiviRigheLavorazioni_RigaComponente'
    )
    BEGIN
        CREATE INDEX IX_PreventiviRigheLavorazioni_RigaComponente
            ON dbo.PreventiviRigheLavorazioni
            (
                IdRigaPreventivo,
                IdRigaCompPrev
            );
    END;

    ALTER TABLE dbo.PreventiviRigheComponenti
        ALTER COLUMN TipoOrigineComponente NVARCHAR(20) NOT NULL;

    IF NOT EXISTS
    (
        SELECT 1
        FROM sys.check_constraints
        WHERE parent_object_id = OBJECT_ID(N'dbo.PreventiviRigheComponenti')
          AND name = N'CK_PreventiviRigheComponenti_Origine'
    )
    BEGIN
        ALTER TABLE dbo.PreventiviRigheComponenti WITH CHECK
            ADD CONSTRAINT CK_PreventiviRigheComponenti_Origine
            CHECK
            (
                (
                    TipoOrigineComponente = N'Distinta'
                    AND IdNodoDistinta IS NOT NULL
                    AND IdArticoloOrigine IS NOT NULL
                )
                OR
                (
                    TipoOrigineComponente = N'Articolo'
                    AND IdNodoDistinta IS NULL
                    AND IdArticoloOrigine IS NOT NULL
                )
                OR
                (
                    TipoOrigineComponente = N'Libero'
                    AND IdNodoDistinta IS NULL
                    AND IdArticoloOrigine IS NULL
                )
            );
    END;

    IF NOT EXISTS
    (
        SELECT 1
        FROM sys.check_constraints
        WHERE parent_object_id = OBJECT_ID(N'dbo.PreventiviRigheComponenti')
          AND name = N'CK_PreventiviRigheComponenti_Quantita'
    )
    BEGIN
        ALTER TABLE dbo.PreventiviRigheComponenti WITH CHECK
            ADD CONSTRAINT CK_PreventiviRigheComponenti_Quantita
            CHECK
            (
                QuantitaBase > 0
                AND QuantitaCalcolata > 0
            );
    END;

    IF NOT EXISTS
    (
        SELECT 1
        FROM sys.check_constraints
        WHERE parent_object_id = OBJECT_ID(N'dbo.PreventiviRigheComponenti')
          AND name = N'CK_PreventiviRigheComponenti_PadreDiverso'
    )
    BEGIN
        ALTER TABLE dbo.PreventiviRigheComponenti WITH CHECK
            ADD CONSTRAINT CK_PreventiviRigheComponenti_PadreDiverso
            CHECK
            (
                IdRigaCompPrevPadre IS NULL
                OR IdRigaCompPrevPadre <> IdRigaCompPrev
            );
    END;

    IF NOT EXISTS
    (
        SELECT 1
        FROM sys.foreign_keys
        WHERE parent_object_id = OBJECT_ID(N'dbo.PreventiviRigheComponenti')
          AND name = N'FK_PreventiviRigheComponenti_ArticoloOrigine'
    )
    BEGIN
        ALTER TABLE dbo.PreventiviRigheComponenti WITH CHECK
            ADD CONSTRAINT FK_PreventiviRigheComponenti_ArticoloOrigine
            FOREIGN KEY (IdArticoloOrigine)
            REFERENCES dbo.Articoli (IdArticolo);
    END;

    IF NOT EXISTS
    (
        SELECT 1
        FROM sys.foreign_keys
        WHERE parent_object_id = OBJECT_ID(N'dbo.PreventiviRigheComponenti')
          AND name = N'FK_PreventiviRigheComponenti_NodoDistintaOrigine'
    )
    BEGIN
        ALTER TABLE dbo.PreventiviRigheComponenti WITH CHECK
            ADD CONSTRAINT FK_PreventiviRigheComponenti_NodoDistintaOrigine
            FOREIGN KEY (IdNodoDistinta)
            REFERENCES dbo.DistintaBaseNodi (IdNodoDistinta);
    END;

    IF NOT EXISTS
    (
        SELECT 1
        FROM sys.foreign_keys
        WHERE parent_object_id = OBJECT_ID(N'dbo.PreventiviRigheComponenti')
          AND name = N'FK_PreventiviRigheComponenti_PadreOperativo'
    )
    BEGIN
        ALTER TABLE dbo.PreventiviRigheComponenti WITH CHECK
            ADD CONSTRAINT FK_PreventiviRigheComponenti_PadreOperativo
            FOREIGN KEY
            (
                IdRigaPreventivo,
                IdRigaCompPrevPadre
            )
            REFERENCES dbo.PreventiviRigheComponenti
            (
                IdRigaPreventivo,
                IdRigaCompPrev
            );
    END;

    IF NOT EXISTS
    (
        SELECT 1
        FROM sys.foreign_keys
        WHERE parent_object_id = OBJECT_ID(N'dbo.PreventiviRigheMateriali')
          AND name = N'FK_PreventiviRigheMateriali_Componente'
    )
    BEGIN
        ALTER TABLE dbo.PreventiviRigheMateriali WITH CHECK
            ADD CONSTRAINT FK_PreventiviRigheMateriali_Componente
            FOREIGN KEY
            (
                IdRigaPreventivo,
                IdRigaCompPrev
            )
            REFERENCES dbo.PreventiviRigheComponenti
            (
                IdRigaPreventivo,
                IdRigaCompPrev
            );
    END;

    IF NOT EXISTS
    (
        SELECT 1
        FROM sys.foreign_keys
        WHERE parent_object_id = OBJECT_ID(N'dbo.PreventiviRigheLavorazioni')
          AND name = N'FK_PreventiviRigheLavorazioni_Componente'
    )
    BEGIN
        ALTER TABLE dbo.PreventiviRigheLavorazioni WITH CHECK
            ADD CONSTRAINT FK_PreventiviRigheLavorazioni_Componente
            FOREIGN KEY
            (
                IdRigaPreventivo,
                IdRigaCompPrev
            )
            REFERENCES dbo.PreventiviRigheComponenti
            (
                IdRigaPreventivo,
                IdRigaCompPrev
            );
    END;

    ALTER TABLE dbo.PreventiviRigheComponenti WITH CHECK
        CHECK CONSTRAINT
            CK_PreventiviRigheComponenti_Origine,
            CK_PreventiviRigheComponenti_Quantita,
            CK_PreventiviRigheComponenti_PadreDiverso,
            FK_PreventiviRigheComponenti_ArticoloOrigine,
            FK_PreventiviRigheComponenti_NodoDistintaOrigine,
            FK_PreventiviRigheComponenti_PadreOperativo;

    ALTER TABLE dbo.PreventiviRigheMateriali WITH CHECK
        CHECK CONSTRAINT FK_PreventiviRigheMateriali_Componente;

    ALTER TABLE dbo.PreventiviRigheLavorazioni WITH CHECK
        CHECK CONSTRAINT FK_PreventiviRigheLavorazioni_Componente;

    COMMIT TRANSACTION;

    SELECT
        N'OK' AS Esito,
        N'Migrazione strutturale TEC-001 completata.' AS Messaggio;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0
    BEGIN
        ROLLBACK TRANSACTION;
    END;

    THROW;
END CATCH;
