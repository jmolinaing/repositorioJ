En un entorno de una gran empresa con alta concurrencia y necesidad de robustez, escalabilidad y trazabilidad, la mejor opción suele ser la segunda: generar un error (RAISERROR) para que el proceso entre en CATCH y se maneje la excepción de forma estricta.

Aquí algunas razones detalladas:

Opción RAISERROR y manejo estricto (opción 2)
Consistencia transaccional: Si la generación de mensajes es crítica, forzar rollback ante fallo evita estados intermedios inconsistentes que puedan causar problemas luego.

Visibilidad clara de errores: Las excepciones quedan registradas de manera uniforme, lo que facilita monitoreo y alertas instantáneas.

Evita falsos positivos: No hay riesgo de seguir adelante con una ejecución que en realidad no produjo resultados válidos.

Buenas prácticas: En bases de datos críticas se recomienda abortar procesos parciales ante fallo, simplificando depuración.

Opción actualización parcial (opción 1)
Más tolerancia: No para el proceso completo ni revierte todo, puede ser útil si el contexto permite no generar mensajes sin impedir todo el ciclo.

Posible confusión: Se registran errores en campos específicos, pero sin levantar error real, puede pasar desapercibido para sistemas automáticos de monitoreo.

Mayor complejidad: Lleva a manejar estados intermedios que pueden ser difíciles de interpretar para operaciones siguientes, además de complicar la lógica de reintentos o auditoría.

Recomendación final
Si la ausencia de generación de mensajes representa un fallo a nivel negocio o sistema, la opción 2 con RAISERROR es la mejor.

Si el sistema puede tolerar ejecuciones fallidas parciales sin detener todo el proceso, la opción 1 vale para evitar caídas mayores.

En sistemas críticos, lo habitual es usar transacciones atómicas con rollback en error y RAISERROR en lugar de solo actualizar estados.


/*======================================================================================== 
 tipo de objeto		:	procedimiento almacenado                                        
 nombre del objeto	:	spu_ges_cob_mensajes_ejecutar_programaciones                                                                                                  
 parametros			:			                                                                                 
 creado por			:	jorge molina													
 fecha creación		:	10-2025                                                    
 descripción		:	sp orquestador que ejecuta envios pendientes.																
========================================================================================*/

/*
GRANT EXECUTE ON [spu_ges_cob_mensajes_ejecutar_programaciones] TO public;
execute spu_ges_cob_mensajes_ejecutar_programaciones 


select * from GCO_ENVMSG_MENSAJE
select * from GCO_ENVMSG_PROGRAMA_LOG

delete GCO_ENVMSG_MENSAJE where eme_codigo not in(1, 2, 3, 4)
*/


CREATE PROCEDURE spu_ges_cob_mensajes_ejecutar_programaciones_opcion2
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE 
        @vigencia_envio NUMERIC = 60, 
        @EPL_CODIGO VARCHAR(50),
        @EPR_CODIGO NUMERIC(10),
        @EPR_TIPO_ENVIO CHAR(1),
        @EPR_HORA_ENVIO DATETIME,
        @FECHA_ENVIO DATETIME,
        @FECHA_ENVIO_TOPE DATETIME,
        @ULTIMA_FECHA_LOG DATETIME,
        @ULTIMO_TEXTO_ERROR VARCHAR(1000),
        @DIA_ACTUAL VARCHAR(10),
        @EPL_FECHORA DATETIME;

    SET @DIA_ACTUAL = DATENAME(WEEKDAY, GETDATE());

    IF OBJECT_ID('tempdb..#PROGRAMACION') IS NOT NULL
        DROP TABLE #PROGRAMACION;

    -- Carga la tabla temporal de programaciones (igual para ambas versiones)
    SELECT 
        P.EPL_CODIGO,
        P.EPR_CODIGO,
        P.EPR_TIPO_ENVIO,
        P.EPR_HORA_ENVIO,
        CASE 
            WHEN P.EPR_TIPO_ENVIO = 'U' THEN 
                DATEADD(HOUR, DATEPART(HOUR, P.EPR_HORA_ENVIO), 
                    DATEADD(MINUTE, DATEPART(MINUTE, P.EPR_HORA_ENVIO), 
                        CAST(CONVERT(CHAR(10), P.EPR_INIVIG_ENVIO, 120) AS DATETIME)))
            ELSE 
                DATEADD(HOUR, DATEPART(HOUR, P.EPR_HORA_ENVIO), 
                    DATEADD(MINUTE, DATEPART(MINUTE, P.EPR_HORA_ENVIO), 
                        CAST(CONVERT(CHAR(10), GETDATE(), 120) AS DATETIME)))
        END AS FECHA_ENVIO,
        DATEADD(MINUTE, @vigencia_envio,
            CASE 
                WHEN P.EPR_TIPO_ENVIO = 'U' THEN 
                    DATEADD(HOUR, DATEPART(HOUR, P.EPR_HORA_ENVIO), 
                        DATEADD(MINUTE, DATEPART(MINUTE, P.EPR_HORA_ENVIO), 
                            CAST(CONVERT(CHAR(10), P.EPR_INIVIG_ENVIO, 120) AS DATETIME)))
                ELSE 
                    DATEADD(HOUR, DATEPART(HOUR, P.EPR_HORA_ENVIO), 
                        DATEADD(MINUTE, DATEPART(MINUTE, P.EPR_HORA_ENVIO), 
                            CAST(CONVERT(CHAR(10), GETDATE(), 120) AS DATETIME)))
            END
        ) AS FECHA_ENVIO_TOPE,
        L1.EPL_FECHORA AS ULTIMA_FECHA_LOG,
        L1.EPL_TEXTO_ERROR AS ULTIMO_TEXTO_ERROR
    INTO #PROGRAMACION
    FROM GCO_ENVMSG_PROGRAMA P
    JOIN GCO_ENVMSG_PLANTILLA PL ON PL.EPL_CODIGO = P.EPL_CODIGO
    LEFT JOIN (
        SELECT L.EPR_CODIGO, L.EPL_FECHORA, L.EPL_TEXTO_ERROR
        FROM GCO_ENVMSG_PROGRAMA_LOG L
        JOIN (
            SELECT EPR_CODIGO, MAX(EPL_FECHORA) AS MaxFecha
            FROM GCO_ENVMSG_PROGRAMA_LOG
            WHERE EPL_FECHORA <= GETDATE()
            GROUP BY EPR_CODIGO
        ) LM ON L.EPR_CODIGO = LM.EPR_CODIGO AND L.EPL_FECHORA = LM.MaxFecha
    ) L1 ON L1.EPR_CODIGO = P.EPR_CODIGO
    WHERE PL.EPL_VIGENTE = 'S'
      AND P.EPR_INIVIG_ENVIO <= GETDATE()
      AND (P.EPR_FINVIG_ENVIO IS NULL OR P.EPR_FINVIG_ENVIO >= GETDATE())
      AND (
            (P.EPR_TIPO_ENVIO = 'U')
            OR
            (P.EPR_TIPO_ENVIO = 'P' AND (
                (@DIA_ACTUAL = 'Monday' AND P.EPR_LUNES = 'S') OR
                (@DIA_ACTUAL = 'Tuesday' AND P.EPR_MARTES = 'S') OR
                (@DIA_ACTUAL = 'Wednesday' AND P.EPR_MIERCOLES = 'S') OR
                (@DIA_ACTUAL = 'Thursday' AND P.EPR_JUEVES = 'S') OR
                (@DIA_ACTUAL = 'Friday' AND P.EPR_VIERNES = 'S') OR
                (@DIA_ACTUAL = 'Saturday' AND P.EPR_SABADO = 'S') OR
                (@DIA_ACTUAL = 'Sunday' AND P.EPR_DOMINGO = 'S')
            ))
          );

/*
----PARA VERIFICAR SE DESCOMENTA
	-- SELECT * FROM #PROGRAMACION
	-- WHERE FECHA_ENVIO <= GETDATE()
	-- AND FECHA_ENVIO_TOPE >= GETDATE();

	--return
----PARA VERIFICAR SE DESCOMENTA
*/

    DECLARE CUR_PROG CURSOR FOR
    SELECT EPL_CODIGO, EPR_CODIGO, EPR_TIPO_ENVIO, EPR_HORA_ENVIO,
           FECHA_ENVIO, FECHA_ENVIO_TOPE, ULTIMA_FECHA_LOG, ULTIMO_TEXTO_ERROR
    FROM #PROGRAMACION
    WHERE FECHA_ENVIO <= GETDATE()
      AND FECHA_ENVIO_TOPE >= GETDATE();

    OPEN CUR_PROG;
    FETCH NEXT FROM CUR_PROG INTO 
        @EPL_CODIGO, @EPR_CODIGO, @EPR_TIPO_ENVIO, @EPR_HORA_ENVIO, 
        @FECHA_ENVIO, @FECHA_ENVIO_TOPE, @ULTIMA_FECHA_LOG, @ULTIMO_TEXTO_ERROR;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        IF NOT EXISTS (
            SELECT 1
            FROM GCO_ENVMSG_PROGRAMA_LOG
            WHERE EPR_CODIGO = @EPR_CODIGO
              AND EPL_FECHORA >= ISNULL(@ULTIMA_FECHA_LOG, '19000101')
			  --AND epl_texto_error IS NULL
        )
        BEGIN
            BEGIN TRY
                BEGIN TRAN;

                SET @EPL_FECHORA = GETDATE();

                INSERT INTO GCO_ENVMSG_PROGRAMA_LOG (EPR_CODIGO, EPL_FECHORA, EPL_TEXTO_ERROR)
                VALUES (@EPR_CODIGO, @EPL_FECHORA, NULL);

                EXEC dbo.spu_ges_cob_mensajes_obtener_datos @EPL_CODIGO, 'S', @EPR_CODIGO, @EPL_FECHORA;

				-- Contar cantidad de mensajes generados
                DECLARE @InsertCount INT;
                SELECT @InsertCount = COUNT(*)
                FROM GCO_ENVMSG_MENSAJE
                WHERE EPR_CODIGO = @EPR_CODIGO
                  AND EME_FECENVIO >= @EPL_FECHORA;

                IF @InsertCount = 0
                BEGIN
                    RAISERROR('No se generaron mensajes en esta ejecución para EPR_CODIGO %d.', 16, 1, @EPR_CODIGO);
                END

                COMMIT TRAN;
            END TRY
            BEGIN CATCH
                IF @@TRANCOUNT > 0
                    ROLLBACK TRAN;

                DECLARE @ErrorMessage NVARCHAR(4000), @ErrorSeverity INT, @ErrorState INT;

                SELECT @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();

                INSERT INTO GCO_ENVMSG_PROGRAMA_LOG (EPR_CODIGO, EPL_FECHORA, EPL_TEXTO_ERROR)
                VALUES (@EPR_CODIGO, GETDATE(), @ErrorMessage);

                RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);

                RETURN;
            END CATCH
        END

        FETCH NEXT FROM CUR_PROG INTO 
            @EPL_CODIGO, @EPR_CODIGO, @EPR_TIPO_ENVIO, @EPR_HORA_ENVIO, 
            @FECHA_ENVIO, @FECHA_ENVIO_TOPE, @ULTIMA_FECHA_LOG, @ULTIMO_TEXTO_ERROR;
    END

    CLOSE CUR_PROG;
    DEALLOCATE CUR_PROG;

    DROP TABLE #PROGRAMACION;
END;
GO
