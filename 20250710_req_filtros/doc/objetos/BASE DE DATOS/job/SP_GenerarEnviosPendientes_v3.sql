/*======================================================================================== 
 tipo de objeto		:	procedimiento almacenado                                        
 nombre del objeto	:	SP_GenerarEnviosPendientes                                                                                                  
 parametros			:			                                                                                 
 creado por			:	jorge molina													
 fecha creación		:	10-2025                                                    
 descripción		:	sp orquestador que ejecuta envios pendientes.																
========================================================================================*/

/*
GRANT EXECUTE ON [SP_GenerarEnviosPendientes] TO public;
execute SP_GenerarEnviosPendientes 


select * from GCO_ENVMSG_MENSAJE
select * from GCO_ENVMSG_PROGRAMA_LOG

delete GCO_ENVMSG_MENSAJE where eme_codigo not in(1, 2, 3, 4)
*/

alter PROCEDURE SP_GenerarEnviosPendientes
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
        @DIA_ACTUAL VARCHAR(10);

    SET @DIA_ACTUAL = DATENAME(WEEKDAY, GETDATE());

    IF OBJECT_ID('tempdb..#PROGRAMACION') IS NOT NULL
        DROP TABLE #PROGRAMACION;

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


   -- SELECT EPL_CODIGO, EPR_CODIGO, EPR_TIPO_ENVIO, EPR_HORA_ENVIO,
   --        FECHA_ENVIO, FECHA_ENVIO_TOPE, ULTIMA_FECHA_LOG, ULTIMO_TEXTO_ERROR
   -- FROM #PROGRAMACION
   -- WHERE FECHA_ENVIO <= GETDATE()
   --   AND FECHA_ENVIO_TOPE >= GETDATE();

	  --return 


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
			  AND epl_texto_error IS NULL
        )
        BEGIN
            BEGIN TRY
                BEGIN TRAN;

                EXEC dbo.spu_ges_cob_mensajes_obtener_datos @EPL_CODIGO, 'S', @EPR_CODIGO;

                INSERT INTO GCO_ENVMSG_PROGRAMA_LOG (EPR_CODIGO, EPL_FECHORA, EPL_TEXTO_ERROR)
                VALUES (@EPR_CODIGO, GETDATE(), NULL);

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
