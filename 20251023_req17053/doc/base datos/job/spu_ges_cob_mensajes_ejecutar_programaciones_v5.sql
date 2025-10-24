/*======================================================================================== 
 tipo de objeto		:	procedimiento almacenado                                        
 nombre del objeto	:	spu_ges_cob_mensajes_ejecutar_programaciones                                                                                                  
 parametros			:			                                                                                 
 creado por			:	jorge molina													
 fecha creación		:	23-10-2025                                                    
 descripción		:	sp orquestador que ejecuta envios pendientes.
 descripcion detallada:

Busca programaciones activas en GCO_ENVMSG_PROGRAMA que no tengan un log exitoso reciente (sin error).
Para cada programación:
	1.Inserta un log con fecha actual y texto de error NULL.
	2.Ejecuta el SP spu_ges_cob_mensajes_obtener_datos.
	3.Cuenta los mensajes generados en GCO_ENVMSG_MENSAJE después del log.
	4.Si no hay mensajes generados:
		Actualiza log con texto de error (opción 1).
		Lanza error RAISERROR para forzar rollback y captura (opción 2).
	5.Maneja error de transacción y registra excepción en log si ocurre.
========================================================================================*/

/*
GRANT EXECUTE ON [spu_ges_cob_mensajes_ejecutar_programaciones] TO public;
execute spu_ges_cob_mensajes_ejecutar_programaciones 


select * from GCO_ENVMSG_MENSAJE
select * from GCO_ENVMSG_PROGRAMA_LOG

delete GCO_ENVMSG_MENSAJE where eme_codigo not in(1, 2, 3, 4)

--EJECUCION DEL SP MENSAJES
declare @epl_fechora datetime = getdate()
insert into GCO_ENVMSG_PROGRAMA_LOG values(5, @epl_fechora, null)
execute spu_ges_cob_mensajes_obtener_datos 1, 'S', 5, @epl_fechora

*/

ALTER PROCEDURE spu_ges_cob_mensajes_ejecutar_programaciones
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
		@EPL_FECHORA DATETIME,
		@FECHA_HOY DATETIME;

    SET @DIA_ACTUAL = DATENAME(WEEKDAY, GETDATE());
	set @fecha_hoy = cast( ( cast(getdate() as date)) as datetime)

    IF OBJECT_ID('tempdb..#PROGRAMACION') IS NOT NULL
        DROP TABLE #PROGRAMACION;

	-- Carga la tabla temporal de programaciones
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


------PARA VERIFICAR SE DESCOMENTA
--	 SELECT * FROM #PROGRAMACION
--	 WHERE FECHA_ENVIO <= GETDATE()
--	 AND FECHA_ENVIO_TOPE >= GETDATE();

--	return
------PARA VERIFICAR SE DESCOMENTA



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

		--Si el campo EPL_TEXTO_ERROR está nulo, significa que la programación se ejecutó correctamente y no debe reintentar. 
		--Si tiene un error (no nulo), entonces sí puede reintentarse, evitando así ejecuciones repetidas innecesarias y posibles ciclos infinitos.
        IF NOT EXISTS (
            SELECT 1
            FROM GCO_ENVMSG_PROGRAMA_LOG
            WHERE EPR_CODIGO = @EPR_CODIGO
              AND EPL_FECHORA >= ISNULL(@ULTIMA_FECHA_LOG, '19000101')
			  AND EPL_FECHORA >= @fecha_hoy
			  AND epl_texto_error IS NULL
        )
        BEGIN
            BEGIN TRY
                BEGIN TRAN;

				/*V0
                EXEC dbo.spu_ges_cob_mensajes_obtener_datos @EPL_CODIGO, 'S', @EPR_CODIGO;
                INSERT INTO GCO_ENVMSG_PROGRAMA_LOG (EPR_CODIGO, EPL_FECHORA, EPL_TEXTO_ERROR)
                VALUES (@EPR_CODIGO, GETDATE(), NULL);
				*/

                SET @EPL_FECHORA = GETDATE();
				
				----1.Inserta un log con fecha actual y texto de error NULL.
                INSERT INTO GCO_ENVMSG_PROGRAMA_LOG (EPR_CODIGO, EPL_FECHORA, EPL_TEXTO_ERROR)
                VALUES (@EPR_CODIGO, @EPL_FECHORA, NULL);

				----2.Ejecuta el SP spu_ges_cob_mensajes_obtener_datos.

				--print 'EPL_CODIGO_'+@EPL_CODIGO+'_'
				--print 'EPR_CODIGO_'+@EPR_CODIGO+'_'
				--print 'EPL_FECHORA_'+@EPL_FECHORA+'_'

                EXEC dbo.spu_ges_cob_mensajes_obtener_datos @EPL_CODIGO, 'S', @EPR_CODIGO, @EPL_FECHORA;

				----3.Cuenta los mensajes generados en GCO_ENVMSG_MENSAJE después del log.
                DECLARE @InsertCount numeric(10);
                SELECT @InsertCount = COUNT(*)
                FROM GCO_ENVMSG_MENSAJE
                WHERE EPR_CODIGO = @EPR_CODIGO
                  AND EPL_FECHORA = @EPL_FECHORA;

				--4.Si no hay mensajes generados:
				--	Actualiza log con texto de error (opción 1).
				--	Lanza error RAISERROR para forzar rollback y captura (opción 2).
                IF @InsertCount = 0
                BEGIN

				--	--V1
				--	--Opción actualización parcial (opción 1)
				--	--Más tolerancia: No para el proceso completo ni revierte todo, puede ser útil si el contexto permite no generar mensajes sin impedir todo el ciclo.
				--	--Posible confusión: Se registran errores en campos específicos, pero sin levantar error real, puede pasar desapercibido para sistemas automáticos de monitoreo.
				--	--Mayor complejidad: Lleva a manejar estados intermedios que pueden ser difíciles de interpretar para operaciones siguientes, además de complicar la lógica de reintentos o auditoría.
    --                /*UPDATE GCO_ENVMSG_PROGRAMA_LOG
    --                SET EPL_TEXTO_ERROR = 'No se generaron mensajes en esta ejecución.'
    --                WHERE EPR_CODIGO = @EPR_CODIGO
    --                  AND EPL_FECHORA = @EPL_FECHORA;*/

				--	--V2: PARA alta concurrencia y necesidad de robustez, escalabilidad y trazabilidad: generar un error (RAISERROR) para que el proceso entre en CATCH y se maneje la excepción de forma estricta.
				--	--Consistencia transaccional: Si la generación de mensajes es crítica, forzar rollback ante fallo evita estados intermedios inconsistentes que puedan causar problemas luego.
				--	--Visibilidad clara de errores: Las excepciones quedan registradas de manera uniforme, lo que facilita monitoreo y alertas instantáneas.
				--	--Evita falsos positivos: No hay riesgo de seguir adelante con una ejecución que en realidad no produjo resultados válidos.
				--	--Buenas prácticas: En bases de datos críticas se recomienda abortar procesos parciales ante fallo, simplificando depuración.
    --                --RAISERROR('No se generaron mensajes en esta ejecución para EPR_CODIGO %d.', 16, 1, @EPR_CODIGO);
						RAISERROR('Ejecución correcta pero sin registros generados.', 16, 1);

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
