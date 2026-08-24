DECLARE @NomeVincolo SYSNAME;
DECLARE @Sql NVARCHAR(MAX);

SELECT
    @NomeVincolo = dc.name
FROM sys.default_constraints dc
INNER JOIN sys.columns c
    ON c.default_object_id = dc.object_id
WHERE dc.parent_object_id = OBJECT_ID(N'dbo.Allegati')
  AND c.name = N'Attivo';

IF @NomeVincolo IS NOT NULL
BEGIN
    SET @Sql =
        N'ALTER TABLE dbo.Allegati DROP CONSTRAINT '
        + QUOTENAME(@NomeVincolo)
        + N';';

    EXEC sys.sp_executesql @Sql;
END;
GO

IF COL_LENGTH(N'dbo.Allegati', N'Attivo') IS NOT NULL
BEGIN
    ALTER TABLE dbo.Allegati
    DROP COLUMN Attivo;
END;
GO