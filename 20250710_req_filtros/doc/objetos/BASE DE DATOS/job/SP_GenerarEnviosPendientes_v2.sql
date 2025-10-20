CREATE PROCEDURE SP_GenerarEnviosPendientes
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE 
        @vigencia_envio NUMERIC = 60, -- duración en minutos para FECHA_ENVIO_TOPE
        @EPL_CODIGO VARCHAR(50),
        @EPR_CODIGO NUMERIC(10),
        @EPR_TIPO_ENVIO CHAR(1),
        @EPR_HORA_ENVIO DATETIME,
        @FECHA_ENVIO DATETIME,
        @FECHA_ENVIO_TOPE DATETIME,
        @ULT_EJEC DATETIME,
        @DIA_ACTUAL VARCHAR(10);

    SET @DIA_ACTUAL = DATENAME(WEEKDAY, GETDATE());

    -- CTE para calcular FECHA_ENVIO y FECHA_ENVIO_TOPE
    ;WITH ProgramacionCTE AS (
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
            ) AS FECHA_ENVIO_TOPE
        FROM GCO_ENVMSG_PROGRAMA P
        INNER JOIN GCO_ENVMSG_PLANTILLA PL ON PL.EPL_CODIGO = P.EPL_CODIGO
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
              )
    )
    -- Insertar sólo las programaciones cuyo FECHA_ENVIO_TOPE <= GETDATE()
    SELECT * INTO #PROGRAMACION FROM ProgramacionCTE WHERE FECHA_ENVIO_TOPE <= GETDATE();

    -- Cursor para iterar las programaciones
    DECLARE CUR_PROG CURSOR FOR
    SELECT EPL_CODIGO, EPR_CODIGO, EPR_TIPO_ENVIO, EPR_HORA_ENVIO, FECHA_ENVIO, FECHA_ENVIO_TOPE FROM #PROGRAMACION;

    OPEN CUR_PROG;
    FETCH NEXT FROM CUR_PROG INTO 
        @EPL_CODIGO, @EPR_CODIGO, @EPR_TIPO_ENVIO, @EPR_HORA_ENVIO, @FECHA_ENVIO, @FECHA_ENVIO_TOPE;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        IF GETDATE() >= @FECHA_ENVIO
        BEGIN
            SELECT @ULT_EJEC = MAX(EPL_FECHORA)
            FROM GCO_ENVMSG_PROGRAMA_LOG
            WHERE EPR_CODIGO = @EPR_CODIGO
              AND EPL_FECHORA < GETDATE();

            IF NOT EXISTS (
                SELECT 1
                FROM GCO_ENVMSG_PROGRAMA_LOG
                WHERE EPR_CODIGO = @EPR_CODIGO
                  AND EPL_FECHORA >= ISNULL(@ULT_EJEC, '19000101')
            )
            BEGIN
                BEGIN TRY
                    BEGIN TRAN;

                    INSERT INTO GCO_ENVMSG_MENSAJE (
                        ATE_CODIGO,
                        RUT_DEUDOR,
                        EME_EMAIL_DEUDOR,
                        EME_FONO_DEUDOR,
                        EME_DEUDA_COTIZ,
                        EME_DEUDA_LUR,
                        EME_DEUDA_CHQ,
                        COB_CODIGO,
                        EME_FECENVIO,
                        EME_ESTADO,
                        EME_DESCRIP_ENVIO
                    )
                    SELECT
                        ATE_CODIGO,
                        RUT_DEUDOR,
                        EME_EMAIL_DEUDOR,
                        EME_FONO_DEUDOR,
                        EME_DEUDA_COTIZ,
                        EME_DEUDA_LUR,
                        EME_DEUDA_CHQ,
                        COB_CODIGO,
                        GETDATE(),
                        'PEND',
                        'Generado automáticamente por SP_GenerarEnviosPendientes'
                    FROM FUENTE_MENSAJES
                    WHERE EPR_CODIGO = @EPR_CODIGO;

                    INSERT INTO GCO_ENVMSG_PROGRAMA_LOG (EPR_CODIGO, EPL_FECHORA, EPL_TEXTO_ERROR)
                    VALUES (@EPR_CODIGO, GETDATE(), NULL);

                    COMMIT TRAN;
                END TRY
                BEGIN CATCH
                    ROLLBACK TRAN;
                    INSERT INTO GCO_ENVMSG_PROGRAMA_LOG (EPR_CODIGO, EPL_FECHORA, EPL_TEXTO_ERROR)
                    VALUES (@EPR_CODIGO, GETDATE(), ERROR_MESSAGE());
                END CATCH
            END
        END

        FETCH NEXT FROM CUR_PROG INTO 
            @EPL_CODIGO, @EPR_CODIGO, @EPR_TIPO_ENVIO, @EPR_HORA_ENVIO, @FECHA_ENVIO, @FECHA_ENVIO_TOPE;
    END

    CLOSE CUR_PROG;
    DEALLOCATE CUR_PROG;

    DROP TABLE #PROGRAMACION;
END;
GO
