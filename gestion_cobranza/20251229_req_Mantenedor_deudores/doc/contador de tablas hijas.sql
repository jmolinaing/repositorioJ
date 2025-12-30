SELECT 
    fk.name                               AS nombre_fk,
    OBJECT_SCHEMA_NAME(fk.parent_object_id) AS esquema_tabla_hija,
    OBJECT_NAME(fk.parent_object_id)        AS tabla_hija,
    cpa.name                              AS columna_hija
FROM sys.foreign_keys fk
JOIN sys.foreign_key_columns fkc 
      ON fk.object_id = fkc.constraint_object_id
JOIN sys.columns cpa 
      ON fkc.parent_object_id = cpa.object_id 
     AND fkc.parent_column_id = cpa.column_id
WHERE fk.referenced_object_id = OBJECT_ID(N'dbo.DEUDOR')   -- ajusta esquema si es otro
ORDER BY esquema_tabla_hija, tabla_hija;



SELECT 
    'SELECT ''' + OBJECT_SCHEMA_NAME(fk.parent_object_id) + '.' + 
                  OBJECT_NAME(fk.parent_object_id) + ''' AS tabla_hija, ' +
    'COUNT(*) AS registros_con_RUT_' + @RUT + 
    ' FROM ' + OBJECT_SCHEMA_NAME(fk.parent_object_id) + '.' + 
               OBJECT_NAME(fk.parent_object_id) + 
    ' WHERE ' + cpa.name + ' = ''' + @RUT + ''';' AS consulta_count
FROM sys.foreign_keys fk
JOIN sys.foreign_key_columns fkc ON fk.object_id = fkc.constraint_object_id
JOIN sys.columns cpa ON fkc.parent_object_id = cpa.object_id 
                    AND fkc.parent_column_id = cpa.column_id
WHERE fk.referenced_object_id = OBJECT_ID(N'dbo.DEUDOR')
ORDER BY OBJECT_NAME(fk.parent_object_id);



SELECT 
    OBJECT_SCHEMA_NAME(fk.parent_object_id) + '.' + 
    OBJECT_NAME(fk.parent_object_id) AS tabla_hija,
    cpa.name AS columna_fk
FROM sys.foreign_keys fk
JOIN sys.foreign_key_columns fkc ON fk.object_id = fkc.constraint_object_id
JOIN sys.columns cpa ON fkc.parent_object_id = cpa.object_id 
                    AND fkc.parent_column_id = cpa.column_id
WHERE fk.referenced_object_id = OBJECT_ID(N'dbo.DEUDOR')
ORDER BY tabla_hija;



SELECT 
    'SELECT ''' + OBJECT_SCHEMA_NAME(fk.parent_object_id) + '.' + 
                  OBJECT_NAME(fk.parent_object_id) + ''' AS tabla_hija, ' +
    'COUNT(*) AS total_registros ' +
    'FROM ' + OBJECT_SCHEMA_NAME(fk.parent_object_id) + '.' + 
             OBJECT_NAME(fk.parent_object_id) + ';' AS consulta_count
FROM sys.foreign_keys fk
JOIN sys.foreign_key_columns fkc ON fk.object_id = fkc.constraint_object_id
JOIN sys.columns cpa ON fkc.parent_object_id = cpa.object_id 
                    AND fkc.parent_column_id = cpa.column_id
WHERE fk.referenced_object_id = OBJECT_ID(N'dbo.DEUDOR')
ORDER BY OBJECT_NAME(fk.parent_object_id);



SELECT 
    OBJECT_SCHEMA_NAME(fk.parent_object_id) + '.' + 
    OBJECT_NAME(fk.parent_object_id) AS tabla_hija,
    cpa.name AS columna_fk,
    (SELECT COUNT(*) 
     FROM sys.tables t 
     WHERE t.object_id = fk.parent_object_id) AS total_registros
FROM sys.foreign_keys fk
JOIN sys.foreign_key_columns fkc ON fk.object_id = fkc.constraint_object_id
JOIN sys.columns cpa ON fkc.parent_object_id = cpa.object_id 
                    AND fkc.parent_column_id = cpa.column_id
WHERE fk.referenced_object_id = OBJECT_ID(N'dbo.DEUDOR')
ORDER BY tabla_hija;


DECLARE @sql NVARCHAR(MAX) = '';

SELECT @sql = @sql + 
    'SELECT ''' + OBJECT_SCHEMA_NAME(fk.parent_object_id) + '.' + 
                   OBJECT_NAME(fk.parent_object_id) + ''' AS tabla_hija, ' +
    'COUNT(*) AS total_registros ' +
    'FROM ' + QUOTENAME(OBJECT_SCHEMA_NAME(fk.parent_object_id)) + '.' + 
             QUOTENAME(OBJECT_NAME(fk.parent_object_id)) + '; ' +
    CHAR(13) + CHAR(10)
FROM sys.foreign_keys fk
JOIN sys.foreign_key_columns fkc ON fk.object_id = fkc.constraint_object_id
JOIN sys.columns cpa ON fkc.parent_object_id = cpa.object_id 
                    AND fkc.parent_column_id = cpa.column_id
WHERE fk.referenced_object_id = OBJECT_ID(N'dbo.DEUDOR')
ORDER BY OBJECT_NAME(fk.parent_object_id);

PRINT @sql;
-- Descomenta la siguiente línea para ejecutar directamente
-- EXEC sp_executesql @sql;





SELECT 
    OBJECT_SCHEMA_NAME(fk.parent_object_id) + '.' + 
    OBJECT_NAME(fk.parent_object_id) AS tabla_hija,
    cpa.name AS columna_fk,
    (SELECT COUNT(*) 
     FROM sys.objects t 
     WHERE t.object_id = fk.parent_object_id
     AND t.type = 'U') AS total_registros_real
FROM sys.foreign_keys fk
JOIN sys.foreign_key_columns fkc ON fk.object_id = fkc.constraint_object_id
JOIN sys.columns cpa ON fkc.parent_object_id = cpa.object_id 
                    AND fkc.parent_column_id = cpa.column_id
WHERE fk.referenced_object_id = OBJECT_ID(N'dbo.DEUDOR')
ORDER BY tabla_hija;






DECLARE @sql NVARCHAR(MAX);
DECLARE @tabla_hija NVARCHAR(256);
DECLARE @columna_fk NVARCHAR(128);
DECLARE @schema_name NVARCHAR(128);

CREATE TABLE #Resultados (
    tabla_hija NVARCHAR(256),
    columna_fk NVARCHAR(128),
    total_registros INT
);

DECLARE tabla_cursor CURSOR FOR
SELECT 
    OBJECT_SCHEMA_NAME(fk.parent_object_id) + '.' + 
    OBJECT_NAME(fk.parent_object_id),
    cpa.name,
    OBJECT_SCHEMA_NAME(fk.parent_object_id)
FROM sys.foreign_keys fk
JOIN sys.foreign_key_columns fkc ON fk.object_id = fkc.constraint_object_id
JOIN sys.columns cpa ON fkc.parent_object_id = cpa.object_id 
                    AND fkc.parent_column_id = cpa.column_id
WHERE fk.referenced_object_id = OBJECT_ID(N'dbo.DEUDOR')
ORDER BY OBJECT_SCHEMA_NAME(fk.parent_object_id), OBJECT_NAME(fk.parent_object_id);

OPEN tabla_cursor;
FETCH NEXT FROM tabla_cursor INTO @tabla_hija, @columna_fk, @schema_name;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @sql = 'INSERT #Resultados (tabla_hija, columna_fk, total_registros) ' +
               'SELECT ''' + @tabla_hija + ''', ''' + @columna_fk + ''', COUNT(*) ' +
               'FROM ' + QUOTENAME(@schema_name) + '.' + QUOTENAME(OBJECT_NAME(OBJECT_ID(@tabla_hija)));
    
    BEGIN TRY
        EXEC sp_executesql @sql;
    END TRY
    BEGIN CATCH
        PRINT 'Error en tabla: ' + @tabla_hija + ' - ' + ERROR_MESSAGE();
    END CATCH
    
    FETCH NEXT FROM tabla_cursor INTO @tabla_hija, @columna_fk, @schema_name;
END

CLOSE tabla_cursor;
DEALLOCATE tabla_cursor;

SELECT tabla_hija, columna_fk, total_registros 
FROM #Resultados 
ORDER BY tabla_hija;

DROP TABLE #Resultados;













DECLARE @sql NVARCHAR(MAX);
DECLARE @tabla_hija NVARCHAR(256);
DECLARE @columna_fk NVARCHAR(128);
DECLARE @schema_name NVARCHAR(128);
DECLARE @RUT VARCHAR(20) = '        51';  -- <-- PON EL RUT AQUÍ

CREATE TABLE #Resultados (
    tabla_hija NVARCHAR(256),
    columna_fk NVARCHAR(128),
    registros_con_rut INT
);

DECLARE tabla_cursor CURSOR FOR
SELECT 
    OBJECT_SCHEMA_NAME(fk.parent_object_id) + '.' + 
    OBJECT_NAME(fk.parent_object_id),
    cpa.name,
    OBJECT_SCHEMA_NAME(fk.parent_object_id)
FROM sys.foreign_keys fk
JOIN sys.foreign_key_columns fkc ON fk.object_id = fkc.constraint_object_id
JOIN sys.columns cpa ON fkc.parent_object_id = cpa.object_id 
                    AND fkc.parent_column_id = cpa.column_id
WHERE fk.referenced_object_id = OBJECT_ID(N'dbo.DEUDOR')
ORDER BY OBJECT_SCHEMA_NAME(fk.parent_object_id), OBJECT_NAME(fk.parent_object_id);

OPEN tabla_cursor;
FETCH NEXT FROM tabla_cursor INTO @tabla_hija, @columna_fk, @schema_name;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @sql = 'INSERT #Resultados (tabla_hija, columna_fk, registros_con_rut) ' +
               'SELECT ''' + @tabla_hija + ''', ''' + @columna_fk + ''', COUNT(*) ' +
               'FROM ' + QUOTENAME(@schema_name) + '.' + QUOTENAME(PARSENAME(@tabla_hija,1)) + 
               ' WHERE ' + QUOTENAME(@columna_fk) + ' = ''' + @RUT + '''';
    
    BEGIN TRY
        EXEC sp_executesql @sql;
    END TRY
    BEGIN CATCH
        PRINT 'Error en tabla: ' + @tabla_hija + ' - ' + ERROR_MESSAGE();
    END CATCH
    
    FETCH NEXT FROM tabla_cursor INTO @tabla_hija, @columna_fk, @schema_name;
END

CLOSE tabla_cursor;
DEALLOCATE tabla_cursor;

SELECT tabla_hija, columna_fk, registros_con_rut 
FROM #Resultados 
ORDER BY tabla_hija;

DROP TABLE #Resultados;






DECLARE @sql NVARCHAR(MAX);
DECLARE @tabla_hija NVARCHAR(256);
DECLARE @columna_fk NVARCHAR(128);
DECLARE @schema_name NVARCHAR(128);
DECLARE @RUT VARCHAR(20) = '        51';  -- <-- PON EL RUT AQUÍ

CREATE TABLE #Resultados (
    tabla_hija NVARCHAR(256),
    columna_fk NVARCHAR(128),
    registros_con_rut INT
);

DECLARE tabla_cursor CURSOR FOR
SELECT 
    OBJECT_SCHEMA_NAME(fk.parent_object_id) + '.' + 
    OBJECT_NAME(fk.parent_object_id),
    cpa.name,
    OBJECT_SCHEMA_NAME(fk.parent_object_id)
FROM sys.foreign_keys fk
JOIN sys.foreign_key_columns fkc ON fk.object_id = fkc.constraint_object_id
JOIN sys.columns cpa ON fkc.parent_object_id = cpa.object_id 
                    AND fkc.parent_column_id = cpa.column_id
WHERE fk.referenced_object_id = OBJECT_ID(N'dbo.DEUDOR')
ORDER BY OBJECT_SCHEMA_NAME(fk.parent_object_id), OBJECT_NAME(fk.parent_object_id);

OPEN tabla_cursor;
FETCH NEXT FROM tabla_cursor INTO @tabla_hija, @columna_fk, @schema_name;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @sql = 'INSERT #Resultados (tabla_hija, columna_fk, registros_con_rut) ' +
               'SELECT ''' + @tabla_hija + ''', ''' + @columna_fk + ''', COUNT(*) ' +
               'FROM ' + QUOTENAME(@schema_name) + '.' + QUOTENAME(PARSENAME(@tabla_hija,1)) + 
               ' WHERE ' + QUOTENAME(@columna_fk) + ' = ''' + @RUT + '''';
    
    BEGIN TRY
        EXEC sp_executesql @sql;
    END TRY
    BEGIN CATCH
        PRINT 'Error en tabla: ' + @tabla_hija + ' - ' + ERROR_MESSAGE();
    END CATCH
    
    FETCH NEXT FROM tabla_cursor INTO @tabla_hija, @columna_fk, @schema_name;
END

CLOSE tabla_cursor;
DEALLOCATE tabla_cursor;

-- **SOLO TABLAS CON REGISTROS > 0**
SELECT tabla_hija, columna_fk, registros_con_rut 
FROM #Resultados 
WHERE registros_con_rut > 0
ORDER BY registros_con_rut DESC, tabla_hija;

DROP TABLE #Resultados;







DECLARE @sql NVARCHAR(MAX);
DECLARE @tabla_hija NVARCHAR(256);
DECLARE @columna_fk NVARCHAR(128);
DECLARE @schema_name NVARCHAR(128);
DECLARE @RUT VARCHAR(20) = '        51';  -- <-- PON EL RUT AQUÍ

CREATE TABLE #Resultados (
    tabla_hija NVARCHAR(256),
    columna_fk NVARCHAR(128),
    registros_con_rut INT,
    mensaje VARCHAR(500)
);

DECLARE tabla_cursor CURSOR FOR
SELECT 
    OBJECT_SCHEMA_NAME(fk.parent_object_id) + '.' + 
    OBJECT_NAME(fk.parent_object_id),
    cpa.name,
    OBJECT_SCHEMA_NAME(fk.parent_object_id)
FROM sys.foreign_keys fk
JOIN sys.foreign_key_columns fkc ON fk.object_id = fkc.constraint_object_id
JOIN sys.columns cpa ON fkc.parent_object_id = cpa.object_id 
                    AND fkc.parent_column_id = cpa.column_id
WHERE fk.referenced_object_id = OBJECT_ID(N'dbo.DEUDOR')
ORDER BY OBJECT_SCHEMA_NAME(fk.parent_object_id), OBJECT_NAME(fk.parent_object_id);

OPEN tabla_cursor;
FETCH NEXT FROM tabla_cursor INTO @tabla_hija, @columna_fk, @schema_name;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @sql = 'INSERT #Resultados (tabla_hija, columna_fk, registros_con_rut, mensaje) ' +
               'SELECT ''' + @tabla_hija + ''', ''' + @columna_fk + ''', COUNT(*), ' +
               '''En la tabla ' + @tabla_hija + ' existen '' + CAST(COUNT(*) AS VARCHAR(10)) + '' registros'' ' +
               'FROM ' + QUOTENAME(@schema_name) + '.' + QUOTENAME(PARSENAME(@tabla_hija,1)) + 
               ' WHERE ' + QUOTENAME(@columna_fk) + ' = ''' + @RUT + '''';
    
    BEGIN TRY
        EXEC sp_executesql @sql;
    END TRY
    BEGIN CATCH
        PRINT 'Error en tabla: ' + @tabla_hija + ' - ' + ERROR_MESSAGE();
    END CATCH
    
    FETCH NEXT FROM tabla_cursor INTO @tabla_hija, @columna_fk, @schema_name;
END

CLOSE tabla_cursor;
DEALLOCATE tabla_cursor;

-- **SOLO TABLAS CON REGISTROS > 0**
SELECT 
    tabla_hija, 
    columna_fk, 
    registros_con_rut,
    mensaje
FROM #Resultados 
WHERE registros_con_rut > 0
ORDER BY registros_con_rut DESC, tabla_hija;

DROP TABLE #Resultados;