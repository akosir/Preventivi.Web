/*
    TEC-007 - Eliminazioni coordinate della gerarchia e degli allegati

    Prerequisiti:
    - TEC-001 applicata (IdRigaCompPrev e gerarchia componenti);
    - TEC-009 applicata (procedure di ricalcolo economico);
    - tabella dbo.Allegati disponibile.

    Lo script non seleziona il database. Eseguirlo esplicitamente
    sull'ambiente di test verificato.
*/

SET NOCOUNT ON;

IF COL_LENGTH(N'dbo.PreventiviRigheComponenti', N'IdRigaCompPrevPadre') IS NULL
   OR COL_LENGTH(N'dbo.PreventiviRigheMateriali', N'IdRigaCompPrev') IS NULL
   OR COL_LENGTH(N'dbo.PreventiviRigheLavorazioni', N'IdRigaCompPrev') IS NULL
BEGIN
    THROW 52001, 'TEC-007: applicare prima la migrazione TEC-001.', 1;
END;

IF OBJECT_ID(N'dbo.sp_RicalcolaTotaliRigaPreventivo', N'P') IS NULL
   OR OBJECT_ID(N'dbo.sp_RicalcolaTotaliVariante', N'P') IS NULL
   OR OBJECT_ID(N'dbo.sp_RicalcolaTotaliPreventivo', N'P') IS NULL
BEGIN
    THROW 52002, 'TEC-007: applicare prima il ricalcolo economico TEC-009.', 1;
END;

IF TYPE_ID(N'dbo.IdAllegatoElenco') IS NULL
BEGIN
    EXEC(N'CREATE TYPE dbo.IdAllegatoElenco AS TABLE
    (
        IdAllegato INT NOT NULL PRIMARY KEY
    );');
END;
GO

CREATE OR ALTER PROCEDURE dbo.Preventivi_Eliminazione_Prepara
    @TipoEliminazione TINYINT,
    @IdEntita INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Entita TABLE
    (
        Entita NVARCHAR(50) NOT NULL,
        IdEntita INT NOT NULL,
        PRIMARY KEY (Entita, IdEntita)
    );

    IF @TipoEliminazione = 1
    BEGIN
        IF NOT EXISTS
        (
            SELECT 1
            FROM dbo.PreventiviRighe
            WHERE IdRigaPreventivo = @IdEntita
        )
        BEGIN
            THROW 52003, 'Riga preventivo non trovata.', 1;
        END;

        INSERT INTO @Entita (Entita, IdEntita)
        SELECT N'PreventiviRigheComponenti', IdRigaCompPrev
        FROM dbo.PreventiviRigheComponenti
        WHERE IdRigaPreventivo = @IdEntita;

        INSERT INTO @Entita (Entita, IdEntita)
        SELECT N'PreventiviRigheMateriali', IdRigaMatPrev
        FROM dbo.PreventiviRigheMateriali
        WHERE IdRigaPreventivo = @IdEntita;

        INSERT INTO @Entita (Entita, IdEntita)
        SELECT N'PreventiviRigheLavorazioni', IdRigaLavPrev
        FROM dbo.PreventiviRigheLavorazioni
        WHERE IdRigaPreventivo = @IdEntita;
    END
    ELSE IF @TipoEliminazione = 2
    BEGIN
        IF NOT EXISTS
        (
            SELECT 1
            FROM dbo.PreventiviRigheComponenti
            WHERE IdRigaCompPrev = @IdEntita
        )
        BEGIN
            THROW 52004, 'Componente preventivo non trovato.', 1;
        END;

        IF EXISTS
        (
            SELECT 1
            FROM dbo.PreventiviRigheComponenti
            WHERE IdRigaCompPrevPadre = @IdEntita
        )
        BEGIN
            THROW 52005, 'Il componente contiene componenti figli. Eliminare prima i figli.', 1;
        END;

        INSERT INTO @Entita VALUES (N'PreventiviRigheComponenti', @IdEntita);

        INSERT INTO @Entita (Entita, IdEntita)
        SELECT N'PreventiviRigheMateriali', IdRigaMatPrev
        FROM dbo.PreventiviRigheMateriali
        WHERE IdRigaCompPrev = @IdEntita;

        INSERT INTO @Entita (Entita, IdEntita)
        SELECT N'PreventiviRigheLavorazioni', IdRigaLavPrev
        FROM dbo.PreventiviRigheLavorazioni
        WHERE IdRigaCompPrev = @IdEntita;
    END
    ELSE IF @TipoEliminazione = 3
    BEGIN
        IF NOT EXISTS
        (
            SELECT 1
            FROM dbo.PreventiviRigheMateriali
            WHERE IdRigaMatPrev = @IdEntita
        )
        BEGIN
            THROW 52006, 'Materiale preventivo non trovato.', 1;
        END;

        INSERT INTO @Entita VALUES (N'PreventiviRigheMateriali', @IdEntita);
    END
    ELSE IF @TipoEliminazione = 4
    BEGIN
        IF NOT EXISTS
        (
            SELECT 1
            FROM dbo.PreventiviRigheLavorazioni
            WHERE IdRigaLavPrev = @IdEntita
        )
        BEGIN
            THROW 52007, 'Lavorazione preventivo non trovata.', 1;
        END;

        INSERT INTO @Entita VALUES (N'PreventiviRigheLavorazioni', @IdEntita);
    END
    ELSE
    BEGIN
        THROW 52008, 'Tipo eliminazione non valido.', 1;
    END;

    SELECT
        allegato.IdAllegato,
        allegato.PercorsoFile,
        allegato.NomeFileArchiviato
    FROM dbo.Allegati AS allegato
    INNER JOIN @Entita AS entita
        ON entita.Entita = allegato.Entita
       AND entita.IdEntita = allegato.IdEntita
    ORDER BY allegato.IdAllegato;
END;
GO

CREATE OR ALTER PROCEDURE dbo.Preventivi_Eliminazione_Conferma
    @TipoEliminazione TINYINT,
    @IdEntita INT,
    @IdAllegatiAttesi dbo.IdAllegatoElenco READONLY
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;

    DECLARE
        @IdRigaPreventivo INT,
        @IdPreventivo INT,
        @IdVariantePreventivo INT;

    DECLARE @Entita TABLE
    (
        Entita NVARCHAR(50) NOT NULL,
        IdEntita INT NOT NULL,
        PRIMARY KEY (Entita, IdEntita)
    );

    DECLARE @IdAllegatiCorrenti TABLE
    (
        IdAllegato INT NOT NULL PRIMARY KEY
    );

    BEGIN TRY
        BEGIN TRANSACTION;

        IF @TipoEliminazione = 1
        BEGIN
            SELECT
                @IdPreventivo = IdPreventivo,
                @IdVariantePreventivo = IdVariantePreventivo
            FROM dbo.PreventiviRighe WITH (UPDLOCK, HOLDLOCK)
            WHERE IdRigaPreventivo = @IdEntita;

            IF @IdPreventivo IS NULL
            BEGIN
                THROW 52003, 'Riga preventivo non trovata.', 1;
            END;

            INSERT INTO @Entita (Entita, IdEntita)
            SELECT N'PreventiviRigheComponenti', IdRigaCompPrev
            FROM dbo.PreventiviRigheComponenti WITH (UPDLOCK, HOLDLOCK)
            WHERE IdRigaPreventivo = @IdEntita;

            INSERT INTO @Entita (Entita, IdEntita)
            SELECT N'PreventiviRigheMateriali', IdRigaMatPrev
            FROM dbo.PreventiviRigheMateriali WITH (UPDLOCK, HOLDLOCK)
            WHERE IdRigaPreventivo = @IdEntita;

            INSERT INTO @Entita (Entita, IdEntita)
            SELECT N'PreventiviRigheLavorazioni', IdRigaLavPrev
            FROM dbo.PreventiviRigheLavorazioni WITH (UPDLOCK, HOLDLOCK)
            WHERE IdRigaPreventivo = @IdEntita;
        END
        ELSE IF @TipoEliminazione = 2
        BEGIN
            SELECT @IdRigaPreventivo = IdRigaPreventivo
            FROM dbo.PreventiviRigheComponenti WITH (UPDLOCK, HOLDLOCK)
            WHERE IdRigaCompPrev = @IdEntita;

            IF @IdRigaPreventivo IS NULL
            BEGIN
                THROW 52004, 'Componente preventivo non trovato.', 1;
            END;

            IF EXISTS
            (
                SELECT 1
                FROM dbo.PreventiviRigheComponenti WITH (UPDLOCK, HOLDLOCK)
                WHERE IdRigaCompPrevPadre = @IdEntita
            )
            BEGIN
                THROW 52005, 'Il componente contiene componenti figli. Eliminare prima i figli.', 1;
            END;

            INSERT INTO @Entita VALUES (N'PreventiviRigheComponenti', @IdEntita);

            INSERT INTO @Entita (Entita, IdEntita)
            SELECT N'PreventiviRigheMateriali', IdRigaMatPrev
            FROM dbo.PreventiviRigheMateriali WITH (UPDLOCK, HOLDLOCK)
            WHERE IdRigaCompPrev = @IdEntita;

            INSERT INTO @Entita (Entita, IdEntita)
            SELECT N'PreventiviRigheLavorazioni', IdRigaLavPrev
            FROM dbo.PreventiviRigheLavorazioni WITH (UPDLOCK, HOLDLOCK)
            WHERE IdRigaCompPrev = @IdEntita;
        END
        ELSE IF @TipoEliminazione = 3
        BEGIN
            SELECT @IdRigaPreventivo = IdRigaPreventivo
            FROM dbo.PreventiviRigheMateriali WITH (UPDLOCK, HOLDLOCK)
            WHERE IdRigaMatPrev = @IdEntita;

            IF @IdRigaPreventivo IS NULL
            BEGIN
                THROW 52006, 'Materiale preventivo non trovato.', 1;
            END;

            INSERT INTO @Entita VALUES (N'PreventiviRigheMateriali', @IdEntita);
        END
        ELSE IF @TipoEliminazione = 4
        BEGIN
            SELECT @IdRigaPreventivo = IdRigaPreventivo
            FROM dbo.PreventiviRigheLavorazioni WITH (UPDLOCK, HOLDLOCK)
            WHERE IdRigaLavPrev = @IdEntita;

            IF @IdRigaPreventivo IS NULL
            BEGIN
                THROW 52007, 'Lavorazione preventivo non trovata.', 1;
            END;

            INSERT INTO @Entita VALUES (N'PreventiviRigheLavorazioni', @IdEntita);
        END
        ELSE
        BEGIN
            THROW 52008, 'Tipo eliminazione non valido.', 1;
        END;

        INSERT INTO @IdAllegatiCorrenti (IdAllegato)
        SELECT allegato.IdAllegato
        FROM dbo.Allegati AS allegato WITH (UPDLOCK, HOLDLOCK)
        INNER JOIN @Entita AS entita
            ON entita.Entita = allegato.Entita
           AND entita.IdEntita = allegato.IdEntita;

        IF EXISTS
        (
            SELECT IdAllegato FROM @IdAllegatiCorrenti
            EXCEPT
            SELECT IdAllegato FROM @IdAllegatiAttesi
        )
        OR EXISTS
        (
            SELECT IdAllegato FROM @IdAllegatiAttesi
            EXCEPT
            SELECT IdAllegato FROM @IdAllegatiCorrenti
        )
        BEGIN
            THROW 52009, 'Gli allegati sono cambiati durante l''operazione. Ripetere l''eliminazione.', 1;
        END;

        DELETE allegato
        FROM dbo.Allegati AS allegato
        INNER JOIN @IdAllegatiCorrenti AS corrente
            ON corrente.IdAllegato = allegato.IdAllegato;

        IF @TipoEliminazione = 1
        BEGIN
            DELETE FROM dbo.PreventiviRigheLavorazioni
            WHERE IdRigaPreventivo = @IdEntita;

            DELETE FROM dbo.PreventiviRigheMateriali
            WHERE IdRigaPreventivo = @IdEntita;

            DELETE FROM dbo.PreventiviRigheComponenti
            WHERE IdRigaPreventivo = @IdEntita;

            DELETE FROM dbo.PreventiviRighe
            WHERE IdRigaPreventivo = @IdEntita;

            IF @IdVariantePreventivo IS NOT NULL
            BEGIN
                EXEC dbo.sp_RicalcolaTotaliVariante
                    @IdVariantePreventivo = @IdVariantePreventivo;
            END;

            EXEC dbo.sp_RicalcolaTotaliPreventivo
                @IdPreventivo = @IdPreventivo;
        END
        ELSE IF @TipoEliminazione = 2
        BEGIN
            DELETE FROM dbo.PreventiviRigheLavorazioni
            WHERE IdRigaCompPrev = @IdEntita;

            DELETE FROM dbo.PreventiviRigheMateriali
            WHERE IdRigaCompPrev = @IdEntita;

            DELETE FROM dbo.PreventiviRigheComponenti
            WHERE IdRigaCompPrev = @IdEntita;

            EXEC dbo.sp_RicalcolaTotaliRigaPreventivo
                @IdRigaPreventivo = @IdRigaPreventivo;
        END
        ELSE IF @TipoEliminazione = 3
        BEGIN
            DELETE FROM dbo.PreventiviRigheMateriali
            WHERE IdRigaMatPrev = @IdEntita;

            EXEC dbo.sp_RicalcolaTotaliRigaPreventivo
                @IdRigaPreventivo = @IdRigaPreventivo;
        END
        ELSE
        BEGIN
            DELETE FROM dbo.PreventiviRigheLavorazioni
            WHERE IdRigaLavPrev = @IdEntita;

            EXEC dbo.sp_RicalcolaTotaliRigaPreventivo
                @IdRigaPreventivo = @IdRigaPreventivo;
        END;

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
