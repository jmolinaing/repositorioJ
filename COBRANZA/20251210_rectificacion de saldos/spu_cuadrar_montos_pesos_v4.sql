/*
CREADOR: JORGE MOLINA
*/



--EXECUTE spu_cuadrar_montos_pesos '     15105'

---Restaurar valores iniciales
--update DEVOLUCION_TFU_CUOTA set DTC_MONTO_PESOS = DTC_MONTO_PESOS_RESP 


/*
REVISION 1 '     15105'
select * from DEVOLUCION_TFU_CUOTA where AFI_RUT='     15105'	and MCT_CORRELATIVO=2 ORDER BY DTC_PERIODO ASC
select sum(dtc_monto_pesos) AS TOTAL_dtc_monto_pesos from DEVOLUCION_TFU_CUOTA where AFI_RUT='     15105'	and MCT_CORRELATIVO=2 
select sum(dtc_monto_pesos) AS TOTAL_dtc_monto_pesos from DEVOLUCION_TFU_CUOTA where AFI_RUT='     15105'	and MCT_CORRELATIVO=2 
select mct_monto AS mct_monto_ACUADRAR from MOVIMIENTO_CTACTE where AFI_RUT='     15105'	and MCT_CORRELATIVO=2

--EXECUTE spu_cuadrar_montos_pesos '  95795684'
REVISION 1 '  95795684'
select * from DEVOLUCION_TFU_CUOTA where AFI_RUT='  95795684'	and MCT_CORRELATIVO=757 ORDER BY DTC_PERIODO ASC
select sum(dtc_monto_pesos) AS TOTAL_dtc_monto_pesos from DEVOLUCION_TFU_CUOTA where AFI_RUT='  95795684'	and MCT_CORRELATIVO=757 
select sum(dtc_monto_pesos) AS TOTAL_dtc_monto_pesos from DEVOLUCION_TFU_CUOTA where AFI_RUT='  95795684'	and MCT_CORRELATIVO=757 
select mct_monto AS mct_monto_ACUADRAR from MOVIMIENTO_CTACTE where AFI_RUT='  95795684'	and MCT_CORRELATIVO=757

*/

--EXECUTE spu_cuadrar_montos_pesos '     39322'

ALTER PROCEDURE dbo.spu_cuadrar_montos_pesos
(
    @AFI_RUT_FILTRO CHAR(10) = NULL   -- NULL = todos los RUT
)
AS
BEGIN
    SET NOCOUNT ON;

        --------------------------------------------------------------------
        -- 0. Variables
        --------------------------------------------------------------------
        DECLARE 
              @AFI_RUT            CHAR(10)
            , @CTA_FECHA_APERTURA DATETIME
            , @MCT_CORRELATIVO    INT
            , @CUOTAS             INT
            , @MCT_MONTO          NUMERIC(18,6)
            , @SUMA_DTC_MONTO_PESOS NUMERIC(15,0)
            , @DIF                NUMERIC(18,6)     --diferencia entre @MCT_MONTO - @SUMA_DTC_MONTO_PESOS
            , @SALDO              INT;              --saldo en pesos a repartir entre las cuotas

        DECLARE 
              @DTC_ID    INT
            , @MONTO_ACT NUMERIC(18,2);

        DECLARE @RegistrosActualizados INT;
        SET @RegistrosActualizados = 0;     --inicialización

    BEGIN TRY
        BEGIN TRAN;

        --------------------------------------------------------------------
        -- 1. Casos descuadrados iniciales 
        --------------------------------------------------------------------
        IF OBJECT_ID('tempdb..#Descuadres') IS NOT NULL DROP TABLE #Descuadres;

        SELECT  
              D.AFI_RUT
            , D.CTA_FECHA_APERTURA
            , D.MCT_CORRELATIVO
            , COUNT(*)                    AS CUOTAS
            , MAX(M.MCT_MONTO)            AS MCT_MONTO
            , SUM(D.dtc_monto_pesos) AS SUMA_DTC_MONTO_PESOS
			--, MAX(M.MCT_MONTO)-SUM(DTC_MONTO_PESOS) AS DIFERENCIA
        INTO #Descuadres
        FROM DEVOLUCION_TFU_CUOTA D
        JOIN MOVIMIENTO_CTACTE M
              ON  D.AFI_RUT            = M.AFI_RUT
              AND D.CTA_FECHA_APERTURA = M.CTA_FECHA_APERTURA
              AND D.MCT_CORRELATIVO    = M.MCT_CORRELATIVO
        WHERE (@AFI_RUT_FILTRO IS NULL OR D.AFI_RUT = @AFI_RUT_FILTRO)
        GROUP BY 
              D.AFI_RUT
            , D.CTA_FECHA_APERTURA
            , D.MCT_CORRELATIVO
        HAVING MAX(M.MCT_MONTO) <> SUM(D.dtc_monto_pesos);

		-- IF @@ROWCOUNT = 0
		--BEGIN  
		--    ROLLBACK TRANSACTION;
		--	RAISERROR('Proceso detenido por falta de registros en #Descuadres .', 16, 1);  
		--	RETURN;  
		--END


        --------------------------------------------------------------------
        -- 3. Cursor de casos descuadrados: 
        --------------------------------------------------------------------
        DECLARE curDescuadres CURSOR LOCAL FAST_FORWARD FOR         --Bloquea mínimamente → Otros usuarios TRABAJAN en paralelo sobre la tabla, Menos memoria + menos CPU + locks(bloqieos) mínimos = RÁPIDO
            SELECT AFI_RUT,
                   CTA_FECHA_APERTURA,
                   MCT_CORRELATIVO,
                   CUOTAS,
                   MCT_MONTO,
                   SUMA_DTC_MONTO_PESOS
            FROM #Descuadres;

        OPEN curDescuadres;

        FETCH NEXT FROM curDescuadres INTO 
              @AFI_RUT,
              @CTA_FECHA_APERTURA,
              @MCT_CORRELATIVO,
              @CUOTAS,
              @MCT_MONTO,
              @SUMA_DTC_MONTO_PESOS;

        WHILE @@FETCH_STATUS = 0
        BEGIN
			-- Inicializar siempre
			SET @DIF   = 0;
			SET @SALDO = 0;

            SET @DIF   = @MCT_MONTO - @SUMA_DTC_MONTO_PESOS;
            SET @SALDO = CAST(@DIF AS INT);   -- unidad = 1 peso (ajusta si usa decimales)

            --si existe saldo negativo ó positivo
            --Si se terminan las cuotas y aún queda saldo, el código vuelve a empezar desde la primera cuota y sigue dando vueltas hasta consumir todo el saldo
            WHILE @SALDO <> 0
            BEGIN
                
                DECLARE curCuotas CURSOR LOCAL FAST_FORWARD FOR

					--listados de cuotas para un rut, fecha_apertura y correlativo ordenados por dtc_periodo
                    SELECT DTC_ID,
                            dtc_monto_pesos
                    FROM DEVOLUCION_TFU_CUOTA WITH (NOLOCK)
                    WHERE AFI_RUT            = @AFI_RUT
                        AND CTA_FECHA_APERTURA = @CTA_FECHA_APERTURA
                        AND MCT_CORRELATIVO    = @MCT_CORRELATIVO
                    ORDER BY DTC_PERIODO ASC, DTC_ID ASC;

                OPEN curCuotas;

                FETCH NEXT FROM curCuotas INTO @DTC_ID, @MONTO_ACT;

                WHILE @@FETCH_STATUS = 0 AND @SALDO <> 0
                BEGIN
                    IF @SALDO > 0		--para saldos positivos, sumar
                    BEGIN
                        UPDATE DEVOLUCION_TFU_CUOTA
                            SET dtc_monto_pesos = dtc_monto_pesos + 1
                        WHERE DTC_ID = @DTC_ID;

                        SET @SALDO = @SALDO - 1;
                        SET @RegistrosActualizados = @RegistrosActualizados + 1;
                    END
                    ELSE IF @SALDO < 0	--para saldos negativos, restar
                    BEGIN
                        UPDATE DEVOLUCION_TFU_CUOTA
                            SET dtc_monto_pesos = dtc_monto_pesos - 1
                        WHERE DTC_ID = @DTC_ID;

                        SET @SALDO = @SALDO + 1;
                        SET @RegistrosActualizados = @RegistrosActualizados + 1;
                    END

                    FETCH NEXT FROM curCuotas INTO @DTC_ID, @MONTO_ACT;
                END

                CLOSE curCuotas;
                DEALLOCATE curCuotas;
            END


            FETCH NEXT FROM curDescuadres INTO 
                  @AFI_RUT,
                  @CTA_FECHA_APERTURA,
                  @MCT_CORRELATIVO,
                  @CUOTAS,
                  @MCT_MONTO,
                  @SUMA_DTC_MONTO_PESOS;
        END

        CLOSE curDescuadres;
        DEALLOCATE curDescuadres;

        --------------------------------------------------------------------
        -- 4. Revisión final de descuadres: reviso si la iteracion dejo algun descuadre (esto no seria correcto) pero si lo hay se hace rollback y se guarda en una tabla temporal para analizar
        --------------------------------------------------------------------
        IF OBJECT_ID('tempdb..#DescuadresFinal') IS NOT NULL  DROP TABLE #DescuadresFinal;

        SELECT  
              D.AFI_RUT
            , D.CTA_FECHA_APERTURA
            , D.MCT_CORRELATIVO
            , COUNT(*)                    AS CUOTAS
            , MAX(M.MCT_MONTO)            AS MCT_MONTO
            , SUM(D.dtc_monto_pesos) AS SUMA_DTC_MONTO_PESOS
            , MAX(M.MCT_MONTO) - SUM(D.dtc_monto_pesos) AS DIFERENCIA
        INTO #DescuadresFinal
        FROM DEVOLUCION_TFU_CUOTA D
        JOIN MOVIMIENTO_CTACTE M
              ON  D.AFI_RUT            = M.AFI_RUT
              AND D.CTA_FECHA_APERTURA = M.CTA_FECHA_APERTURA
              AND D.MCT_CORRELATIVO    = M.MCT_CORRELATIVO
        WHERE (@AFI_RUT_FILTRO IS NULL OR D.AFI_RUT = @AFI_RUT_FILTRO)
        GROUP BY 
              D.AFI_RUT
            , D.CTA_FECHA_APERTURA
            , D.MCT_CORRELATIVO
        HAVING MAX(M.MCT_MONTO) <> SUM(D.dtc_monto_pesos);

        IF EXISTS (SELECT 1 FROM #DescuadresFinal)
        BEGIN
            -- Mostrar los casos que fallaron
            SELECT *
            FROM #DescuadresFinal;

            ROLLBACK TRAN;

            RAISERROR('Persisten casos descuadrados después del ajuste. Revisar #DescuadresFinal.', 16, 1);
            RETURN;
        END

        --------------------------------------------------------------------
        -- 5. Si todo OK, commit y mensaje de registros ajustados
        --------------------------------------------------------------------
        COMMIT TRAN;

        IF @RegistrosActualizados > 0
        BEGIN
            PRINT 'Registros actualizados exitosamente en DEVOLUCION_TFU_CUOTA: ' 
                  + CAST(@RegistrosActualizados AS VARCHAR(20));
        END
        ELSE
        BEGIN
            PRINT 'No se encontraron registros descuadrados para ajustar.';
        END

    END TRY
    BEGIN CATCH

        IF @@TRANCOUNT > 0
            ROLLBACK TRAN;

        DECLARE 
              @ErrorMessage  NVARCHAR(4000),
              @ErrorSeverity INT,
              @ErrorState    INT;

        SELECT  
              @ErrorMessage  = ERROR_MESSAGE(),
              @ErrorSeverity = ERROR_SEVERITY(),
              @ErrorState    = ERROR_STATE();

        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
        RETURN;

    END CATCH;

END;
GO