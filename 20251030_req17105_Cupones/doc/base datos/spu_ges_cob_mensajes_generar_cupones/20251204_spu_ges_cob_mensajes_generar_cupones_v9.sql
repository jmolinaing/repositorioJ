--AGENCIAS
/*========================================================================================   
 tipo de objeto  : procedimiento almacenado                                          
 nombre del objeto : spu_ges_cob_mensajes_generar_cupones                                                                                                   
 parametros   : @cup_id_base : fecha con que se guarda los reg. de [isapre].dbo.GCO_ENVMSG_DEUDA_CUPONES                                                                                    
 creado por   : jorge molina               
 fecha creación  : 11-2025                                                      
 descripción  : simil al sp spu_cuponpago_genera_con_descto_empleador 
				lista los link(Enlace) Corresponde a ruta del Cupón de Pago
				Genera Cupón de Pago que se traducen en Planillas de Pago de   
				Cotizaciones, las cuales son creadas en PLANILLA_PAGO_COTIZ con sus  
				respectivos descuentos. 
========================================================================================*/  
--GRANT EXECUTE ON OBJECT::dbo.spu_ges_cob_mensajes_generar_cupones TO PUBLIC;
/*
EXECUTE spu_ges_cob_mensajes_generar_cupones '2025-11-14 13:45:26.683'

--REVISION EJERCICIO1
select * FROM [evolution].[ISAPRE].DBO.GCO_ENVMSG_DEUDA_CUPONES where cup_id_base = '2025-12-04 12:35:21.207'

--select * from PLANILLA_PAGO_COTIZ 
*/

alter PROCEDURE [dbo].[spu_ges_cob_mensajes_generar_cupones]  
	@cup_id_base datetime  
AS  
BEGIN   
	SET NOCOUNT ON; 
	--SET XACT_ABORT ON
 
 	DECLARE @OPERACION VARCHAR(100);
 	DECLARE @CANT_REG_TABLAPASO NUMERIC(20);

	DECLARE  
	--@sql varchar(2000),  
	@cant_reg  NUMERIC(20),  
	@ppc_folio  NUMERIC(20),  
	@cup_correl  NUMERIC(20),
	@ppc_folio_fin  NUMERIC(20),  
	@cup_correl_fin  NUMERIC(20),  	
	@fec_proceso DATETIME,  
	--@rut_sin_datos CHAR(10),  
	--@txt_error  VARCHAR(200),  
	@ult_per_hc  DATETIME,  
	@tot_deudanom NUMERIC(10),  
	@tot_reajuste NUMERIC(10),  
	@tot_interes NUMERIC(10),  
	@tot_recargo NUMERIC(10),    
	@new_tot_dn  NUMERIC(10),  
	@new_tot_rea NUMERIC(10),  
	@new_tot_int NUMERIC(10),  
	@new_tot_rec NUMERIC(10),  
	@max_id   INT--,  
	--@dif   INT,  
	--@epa_razon   varchar(200),    
	--@n     NUMERIC(10)  

	SET @fec_proceso = CONVERT(CHAR(8), GETDATE(), 112)  
	SET @OPERACION = ''

    --si existen tablas temporales con el nombre indicado en tempdb, eliminarla.
	IF OBJECT_ID('TEMPDB..#pm_cuponpago_det', 'U') IS NOT NULL DROP TABLE #pm_cuponpago_det
	IF OBJECT_ID('TEMPDB..#pm_cuponpago_dettrab', 'U') IS NOT NULL DROP TABLE #pm_cuponpago_dettrab
	IF OBJECT_ID('TEMPDB..#consdeuda', 'U') IS NOT NULL DROP TABLE #consdeuda
	IF OBJECT_ID('TEMPDB..#tmp_planilla_pago_cotiz', 'U') IS NOT NULL DROP TABLE #tmp_planilla_pago_cotiz
	IF OBJECT_ID('TEMPDB..#tmp_planilla_pago_cotiz_det', 'U') IS NOT NULL DROP TABLE #tmp_planilla_pago_cotiz_det
	IF OBJECT_ID('TEMPDB..#tmp_cuponpago_cotiz', 'U') IS NOT NULL DROP TABLE #tmp_cuponpago_cotiz
	IF OBJECT_ID('TEMPDB..#tmp_cuponpago_cotiz_detalle', 'U') IS NOT NULL DROP TABLE #tmp_cuponpago_cotiz_detalle
	IF OBJECT_ID('TEMPDB..#ppc_folio', 'U') IS NOT NULL DROP TABLE #ppc_folio
	IF OBJECT_ID('TEMPDB..#CUP_CORREL', 'U') IS NOT NULL DROP TABLE #CUP_CORREL 


	--CREACION TABLAS TEMPORALES
	CREATE TABLE #pm_cuponpago_det(  
	PMC_CORREL numeric(10, 0) NOT NULL,  
	PMC_RUT char(10) NOT NULL,  
	PMC_PERIODO datetime NOT NULL,  
	PMC_MONTO numeric(15, 0) NOT NULL,  
	PMC_INT numeric(15, 0) NULL,  
	PMC_REA numeric(15, 0) NULL,  
	PMC_REC numeric(15, 0) NULL,  
	PMC_INT_D numeric(15, 0) NULL,  
	PMC_REA_D numeric(15, 0) NULL,  
	PMC_REC_D numeric(15, 0) NULL,  
	PPC_FOLIO numeric(10, 0) NULL,  
	PMC_LINK varchar(500) NULL,  
	PMC_MONTO_D numeric(15, 0) NULL,  
	GDC_TIPODEUDOR char(1) NULL  
	)  
  
	-- #PM_CUPONPAGO_DETTRAB								
	CREATE TABLE #pm_cuponpago_dettrab(  
	PMC_CORREL numeric(10, 0) NOT NULL,  
	PMC_RUT char(10) NOT NULL,  
	PMC_PERIODO datetime NOT NULL,  
	PMD_RUT_TRAB char(10) NOT NULL,  
	PMD_MONTO numeric(15, 0) NOT NULL  
	)  
    
	CREATE TABLE #consdeuda(  
	SEL     CHAR(1),  
	COT_RUT    CHAR(10),  
	NOM_COTIZANTE  VARCHAR(25),  
	EPA_RUT    CHAR(10),  
	EPA_RAZON   VARCHAR(200),  
	DEC_PERIODO   DATETIME,  
	DEC_TIPO_DEUDA  VARCHAR(20),  
	DEC_NRORESOL  NUMERIC(10),  
	PACTADO    NUMERIC(10),  
	PAGADO    NUMERIC(10),  
	DEUDANOMINAL  NUMERIC(10),  
	REAJUSTE   NUMERIC(10),  
	INTERES    NUMERIC(10),  
	RECARGO    NUMERIC(10),  
	TOTAL_APAGAR  NUMERIC(10),  
	COBRADOR   VARCHAR(65),  
	FECHA    DATETIME,  
	ANO     INT,  
	MES     INT,  
	DEUDA_HC   NUMERIC(10),  
	DESCTO_DEUDANOMINAL NUMERIC(10),  
	DESCTO_REAJUSTE  NUMERIC(16,9),  
	DESCTO_INTERES  NUMERIC(16,8),  
	DESCTO_RECARGO  NUMERIC(16,8),  
	FOLIO_FUN_HAB  NUMERIC(10),  
	FECHA_FUN_HAB  DATETIME,  
	REJ_FOLIO   NUMERIC(10),  
	ID     NUMERIC IDENTITY (1, 1)  
	)
	

	CREATE TABLE #tmp_planilla_pago_cotiz (  
	ppc_folio         NUMERIC (12),  
	epa_rut           CHAR(10),  
	epa_correl        NUMERIC(2,0),  
	age_codigo        NUMERIC(4,0),  
	tpa_codigo        NUMERIC(2,0),  
	tpg_codigo        NUMERIC(2,0),  
	ppc_periodo       DATETIME,  
	ppc_imponible     NUMERIC(10,0),  
	ppc_pactado       NUMERIC(10,0),  
	ppc_deuda         NUMERIC(10,0),  
	ppc_cotiz_legal   NUMERIC(10,0),  
	ppc_cotiz_adic    NUMERIC(10,0),  
	ppc_cotiz_apagar  NUMERIC(10,0),  
	ppc_reajustes     NUMERIC(10,0),  
	ppc_intereses     NUMERIC(10,0),  
	ppc_recargos      NUMERIC(10,0),  
	ppc_subtotal      NUMERIC(10,0),  
	ppc_descto_cotiz  NUMERIC(10,0),  
	ppc_descto_int    NUMERIC(10,0),  
	ppc_descto_rea    NUMERIC(10,0),  
	ppc_descto_rec    NUMERIC(10,0),  
	ppc_total         NUMERIC(10,0),  
	opa_codigo        NUMERIC(1,0),  
	ppc_digita        VARCHAR(100),  
	ppc_fecha_digita  DATETIME,  
	ppc_caja          CHAR(1),  
	ppc_origen        CHAR(1),  
	afecto_cob        CHAR(1), -- Campo auxiliar que indica si está afecto a honorarios de cobranza  
	proceso           NUMERIC(15,0) -- Campo auxiliar que indica el número del proceso  
	)  
      
	--DBCC checkident (#tmp_planilla_pago_cotiz, reseed, @ppc_folio)	--JMOLINA: reinicia el valor actual del contador de identidad (seed) de la columna IDENTITY en la tabla temporal #tmp_planilla_pago_cotiz al valor especificado en la variable @ppc_folio.
  
	CREATE TABLE #tmp_planilla_pago_cotiz_det (  
	ppc_folio         NUMERIC(10,0),  
	ppd_correl        NUMERIC(10),  
	cot_rut           CHAR(10),  
	ppd_imponible     NUMERIC(12,0),  
	ppd_cotiz_legal   NUMERIC(12,0),  
	ppd_cotiz_adic    NUMERIC(12,0),  
	ppd_cotiz_apagar  NUMERIC(12,0),  
	ppd_cotiz_pactada NUMERIC(12,0)  
	)      
      
	CREATE TABLE #tmp_cuponpago_cotiz (   
	cup_correl         NUMERIC (10),  
	usu_login          CHAR(20),  
	cup_fechareg       DATETIME,  
	ddr_rut            CHAR(10),  
	ddr_nombre         VARCHAR(100),  
	cup_fechapago      DATETIME,  
	cup_foliopago      VARCHAR(20),  
	cup_honorarios_cob NUMERIC(10,0),  
	roi_folio          NUMERIC(15,0),  
	)  

	--DBCC checkident (#tmp_cuponpago_cotiz, reseed, @cup_correl)  
  
	CREATE TABLE #tmp_cuponpago_cotiz_detalle (   
	cup_correl         NUMERIC (15,0),  
	ppc_folio          NUMERIC (15,0),  
	)

	CREATE TABLE #ppc_folio (ppc_folio NUMERIC(15), ppc_folio_fin NUMERIC(15)) 
	CREATE TABLE #cup_correl (folio_ini NUMERIC(15), folio_fin NUMERIC(15))  



	BEGIN TRY
	
			BEGIN TRAN;

			---- AGREGAR ANTES del INSERT #consdeuda:
			--SELECT @CANT_REG = COUNT(*) FROM [evolution].[ISAPRE].dbo.GCO_ENVMSG_DEUDA_CUPONES 
			--WHERE CUP_ID_BASE = @cup_id_base
			--PRINT 'Registros origen: ' + CAST(@CANT_REG AS VARCHAR(10))

			--declare @cup_id_base_var varchar(50)
			--set @cup_id_base_var = cast(@cup_id_base as varchar(30))

			--IF @CANT_REG = 0
			--BEGIN
			--	RAISERROR('NO HAY DATOS en GCO_ENVMSG_DEUDA_CUPONES para @cup_id_base=%s', 16, 1, @cup_id_base_var);
			--	RETURN;
			--END

			--1.-Traspasar los registros de evolution TABLA PASO GCO_ENVMSG_DEUDA_CUPONES
			SET @OPERACION = 'INSERT #CONSDEUDA'
			INSERT INTO #consdeuda  
			(     
				SEL       
				,COT_RUT      
				,NOM_COTIZANTE    
				,EPA_RUT      
				,EPA_RAZON     
				,DEC_PERIODO     
				,DEC_TIPO_DEUDA    
				--,DEC_NRORESOL    
				,PACTADO      
				,PAGADO      
				,DEUDANOMINAL    
				,REAJUSTE     
				,INTERES      
				,RECARGO      
				,TOTAL_APAGAR    
				--,COBRADOR     
				--,FECHA      
				--,ANO       
				--,MES       
				--,DEUDA_HC     
				,DESCTO_DEUDANOMINAL   
				,DESCTO_REAJUSTE    
				,DESCTO_INTERES    
				,DESCTO_RECARGO    
				--,FOLIO_FUN_HAB    
				--,FECHA_FUN_HAB    
				--,REJ_FOLIO   
			)  
			SELECT   
			'S' AS SEL  
			,COT_RUT  
			,NOM_COTIZANTE  
			,EPA_RUT  
			,EPA_RAZON  
			,DEC_PERIODO  
			,DEC_TIPO_DEUDA  
			--,DEC_NRORESOL  
			,PACTADO  
			,PAGADO  
			,DEUDANOMINAL  
			,REAJUSTE  
			,INTERES  
			,RECARGO  
			,TOTAL_APAGAR  
			--,COBRADOR  
			--,FECHA  
			--,ANO  
			--,MES  
			--,DEUDA_HC  
			,DESCTO_DEUDANOMINAL  
			,DESCTO_REAJUSTE  
			,DESCTO_INTERES  
			,DESCTO_RECARGO  
			--,FOLIO_FUN_HAB  
			--,FECHA_FUN_HAB  
			--,REJ_FOLIO  
			FROM [evolution].[ISAPRE].DBO.GCO_ENVMSG_DEUDA_CUPONES  
			WHERE CUP_ID_BASE=@cup_id_base  

			-- Nuevo Validar que se hayan insertado filas
			SET @CANT_REG_TABLAPASO = @@ROWCOUNT

			IF @CANT_REG_TABLAPASO = 0
			BEGIN
				IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

				RAISERROR('No se insertó ningún registro en #CONSDEUDA.', 16, 1);
				RETURN;
			END

			--
			-- Verificar si transacción está "muerta"
			IF @@TRANCOUNT > 0 AND XACT_STATE() <= 0
			BEGIN
				ROLLBACK TRANSACTION;
				RAISERROR('Transacción muerta después de #consdeuda.', 16, 1);
				RETURN;
			END

			----Descarta casos sin deuda 
			--DECLARE @filas_delete INT

			--SET @OPERACION = 'DELETE FROM #CONSDEUDA'			
			--DELETE FROM #CONSDEUDA WHERE PACTADO - PAGADO < = 0;					---** COMENTAR POR PRUEBA YA QUE LOS REGISTROS TRAEN CERO******
			--SET @filas_delete = @@ROWCOUNT

			---- DESPUÉS del DELETE y ANTES del SELECT @CANT_REG:
			--PRINT 'Después DELETE - XACT_STATE: ' + CAST(XACT_STATE() AS VARCHAR(10))

			----Revisión de cuantos registros quedan para el proceso
			--SELECT @CANT_REG = COUNT(*) FROM #CONSDEUDA;
			--PRINT @CANT_REG;

			---- DESPUÉS del SELECT @CANT_REG:
			--PRINT 'CANT_REG: ' + CAST(@CANT_REG AS VARCHAR(10))
			--PRINT 'TRANCOUNT: ' + CAST(@@TRANCOUNT AS VARCHAR(10))

			--IF XACT_STATE() < 0
			--BEGIN
			--	PRINT '!!! TRANSACCIÓN MUERTA - SALTA IF !!!'
			--	ROLLBACK TRANSACTION
			--	RETURN
			--END

			--IF @CANT_REG = 0  or (@filas_delete = @CANT_REG_TABLAPASO)
			--BEGIN
			--	IF @@TRANCOUNT > 0	ROLLBACK TRANSACTION;

			--	RAISERROR('No queda registro en #CONSDEUDA para procesar.', 16, 1);
			--	RETURN;
			--END

			---- Descarta casos con Multi-empleador  
			--DELETE FROM #consdeuda WHERE epa_rut <> @epa_rut  

			SELECT @tot_deudanom = SUM(DEUDANOMINAL) FROM #consdeuda  
			SELECT @tot_reajuste = SUM(REAJUSTE) FROM #consdeuda  
			SELECT @tot_interes = SUM(INTERES) FROM #consdeuda  
			SELECT @tot_recargo = SUM(RECARGO) FROM #consdeuda    
  
  
			SELECT @new_tot_dn = SUM(DESCTO_DEUDANOMINAL),  
			@new_tot_rea = SUM(DESCTO_REAJUSTE),  
			@new_tot_int = SUM(DESCTO_INTERES),  
			@new_tot_rec = SUM(DESCTO_RECARGO)  
			FROM #consdeuda    
  
			SELECT @max_id = MAX(ID) FROM #consdeuda    
  
			-- Copiar todos los registros 
			SET @OPERACION = 'INSERT INTO #pm_cuponpago_dettrab'			
			INSERT INTO #pm_cuponpago_dettrab  
				SELECT 1,  
				EPA_RUT,  
				DEC_PERIODO,  
				COT_RUT,  
				DEUDANOMINAL  
			FROM #consdeuda  
  
			-- Copiar registros agrupados por período (un registro = una planilla) 
  			SET @OPERACION = 'INSERT INTO #pm_cuponpago_det'
			INSERT INTO #pm_cuponpago_det  
				(PMC_CORREL,  
				PMC_RUT,  
				PMC_PERIODO,  
				PMC_MONTO,  
				PMC_INT,  
				PMC_REA,  
				PMC_REC,  
				PMC_MONTO_D,  
				PMC_INT_D,  
				PMC_REA_D,  
				PMC_REC_D)  
				SELECT  1,  
				EPA_RUT,  
				DEC_PERIODO,  
				SUM(DEUDANOMINAL),  
				SUM(INTERES),  
				SUM(REAJUSTE),  
				SUM(RECARGO),  
				SUM(DESCTO_DEUDANOMINAL),  
				SUM(DESCTO_INTERES),  
				SUM(DESCTO_REAJUSTE),  
				SUM(DESCTO_RECARGO)  
			FROM  #consdeuda  
			GROUP BY EPA_RUT,  
			DEC_PERIODO  
    
			SELECT @cant_reg = COUNT(pmc_correl)  
			FROM #pm_cuponpago_det WITH (NOLOCK)  
			WHERE pmc_correl = 1
			
			--Revisión de cuantos registros quedan para el proceso
			--Jmolina: Si @cant_reg = 0 los sgtes dos insert se caen, ya que los sp debieran traer dos columnas pero si @cant_reg = 0 solo traen una columna.
			IF @CANT_REG = 0
			BEGIN
				IF @@TRANCOUNT > 0	ROLLBACK TRANSACTION;

				RAISERROR('No queda registro en #pm_cuponpago_det para procesar.', 16, 1);
				RETURN;
			END

			-- AGREGAR AQUÍ:
			IF @@TRANCOUNT > 0 AND XACT_STATE() <= 0
			BEGIN
				ROLLBACK TRANSACTION;
				RAISERROR('Transacción muerta después de #pm_cuponpago_det.', 16, 1);
				RETURN;
			END

			-- GENERAR FOLIO PLANILLA  
			SET @OPERACION = 'INSERT #ppc_folio'
			INSERT INTO #ppc_folio EXEC spu_nuevo_correl 'PPM', 0, @cant_reg  
			SELECT @ppc_folio = ppc_folio
					, @ppc_folio_fin = ppc_folio_fin	--nuevo
			FROM #ppc_folio 
			
			-- Validar FOLIO_INI y FOLIO_FIN
			IF @ppc_folio = 0 OR @ppc_folio_fin = 0 OR @ppc_folio IS NULL OR @ppc_folio_fin IS NULL
			BEGIN
				IF @@TRANCOUNT > 0	ROLLBACK TRANSACTION;

				RAISERROR('Error No se asignaron ppc_folio: ppc_folio_ini ó ppc_folio_fin.', 16, 1);
				RETURN;
			END

			SET @OPERACION = 'INSERT #CUP_CORREL'
			INSERT INTO #cup_correl EXEC spu_nuevo_correl 'CUP', 0, @cant_reg  
			SELECT @cup_correl = folio_ini 
					, @cup_correl_fin = folio_fin 
			FROM #cup_correl  
  
			-- Validar FOLIO_INI y FOLIO_FIN
			IF @cup_correl = 0 OR @cup_correl_fin = 0 OR @cup_correl IS NULL OR @cup_correl_fin IS NULL
			BEGIN
				IF @@TRANCOUNT > 0	ROLLBACK TRANSACTION;

				RAISERROR('Error No se asignaron cup_correl: FOLIO_INI ó FOLIO_FIN.', 16, 1);
				RETURN;
			END
  
  
			-----------------------------------------------  
			-- INI PLANILLA -------------------------------  
			-----------------------------------------------  
			SET @OPERACION = 'DELETE FROM VENCIM_PAGO_COTIZACION'
			DELETE FROM VENCIM_PAGO_COTIZACION    
    
			SET @OPERACION = 'INSERT INTO VENCIM_PAGO_COTIZACION'
			INSERT INTO [VENCIM_PAGO_COTIZACION] (VPC_PERIODO, VPC_VENCIMIENTO)  
			SELECT  VPC_PERIODO, VPC_VENCIMIENTO FROM [EVOLUTION].[ISAPRE].[DBO].[VENCIM_PAGO_COTIZACION]  WITH (NOLOCK)   
 
			SET @OPERACION = 'INSERT INTO #tmp_planilla_pago_cotiz'
			INSERT INTO #tmp_planilla_pago_cotiz (  
				ppc_folio,  
				epa_rut,  
				epa_correl,  
				age_codigo,  
				tpa_codigo,  
				tpg_codigo,  
				ppc_periodo,  
				ppc_imponible,  
				ppc_pactado,  
				ppc_deuda,  
				ppc_cotiz_legal,  
				ppc_cotiz_adic,  
				ppc_cotiz_apagar,  
				ppc_reajustes,  
				ppc_intereses,  
				ppc_recargos,  
				ppc_subtotal,  
				ppc_descto_cotiz,  
				ppc_descto_int,  
				ppc_descto_rea,  
				ppc_descto_rec,  
				ppc_total,  
				opa_codigo,  
				ppc_digita,  
				ppc_fecha_digita,  
				ppc_caja,  
				ppc_origen,  
				afecto_cob,  
				proceso  
				)  
				SELECT   ROW_NUMBER() over (PARTITION BY '' ORDER BY pmc_rut, pmc_periodo) +  @ppc_folio - 1,  
				pmc_rut,  
				1,  
				7777,  
				1,  
				CASE WHEN (SELECT COUNT(#pm_cuponpago_dettrab.pmc_correl) FROM #pm_cuponpago_dettrab WITH (NOLOCK) WHERE #pm_cuponpago_dettrab.pmc_correl = #pm_cuponpago_det.pmc_correl AND #pm_cuponpago_dettrab.pmc_rut = #pm_cuponpago_det.pmc_rut AND #pm_cuponpago_dettrab.pmc_periodo = #pm_cuponpago_det.pmc_periodo) > 0 THEN 1  
				ELSE 3 END,  
				pmc_periodo,  
				0,  
				COALESCE(pmc_monto, 0),  
				COALESCE(pmc_monto, 0),  
				0,  
				COALESCE(pmc_monto, 0),  
				COALESCE(pmc_monto, 0),  
				COALESCE(pmc_rea, 0),  
				COALESCE(pmc_int, 0),  
				COALESCE(pmc_rec, 0),  
				COALESCE(pmc_monto, 0) + COALESCE(pmc_rea, 0) + COALESCE(pmc_int, 0) + COALESCE(pmc_rec, 0),  
				COALESCE(pmc_monto_d, 0),  
				COALESCE(pmc_int_d, 0),  
				COALESCE(pmc_rea_d, 0),  
				COALESCE(pmc_rec_d, 0),  
				(COALESCE(pmc_monto, 0) + COALESCE(pmc_rea, 0) + COALESCE(pmc_int, 0) + COALESCE(pmc_rec, 0)) - ( COALESCE(pmc_monto_d, 0) + COALESCE(pmc_int_d, 0) + COALESCE(pmc_rea_d, 0) + COALESCE(pmc_rec_d, 0)),  
				CASE WHEN @fec_proceso > VPC.vpc_vencimiento  THEN 2  
				WHEN @fec_proceso < CONVERT(CHAR(6), VPC.vpc_vencimiento, 112) + '01'  THEN 3  
				ELSE 1 END,  
				'SYSTEM',  
				@cup_id_base, --GETDATE(),  
				'N',  
				'C',  
				'N', -- afecto_cob (valor inicial)  
				1  
			FROM  #pm_cuponpago_det WITH (NOLOCK)  
			LEFT JOIN [VENCIM_PAGO_COTIZACION] VPC WITH (NOLOCK) ON VPC.vpc_periodo = #pm_cuponpago_det.PMC_PERIODO  
			WHERE  pmc_correl = 1 and  
			pmc_monto > 0  
			ORDER BY pmc_rut,  
			pmc_periodo      
  
			--Verifica si está directamente asignado como deudor a un cobrador externo  
			SELECT @ult_per_hc = DATEADD(MONTH, -1, MAX(DEC_PERIODO)) FROM [EVOLUTION].[ISAPRE].[dbo].DEUDA_COTIZANTE WITH (NOLOCK)  


			SET @OPERACION = 'INSERT INTO #folios'  
			SELECT p.ppc_folio  
			INTO #folios  
			FROM #tmp_planilla_pago_cotiz p  
			JOIN [evolution].[isapre].[dbo].DEUDOR_ASIGNADO d (NOLOCK) ON p.epa_rut=d.DDR_RUT  
			JOIN [evolution].[isapre].[dbo].COBRADOR c (NOLOCK) ON d.COB_CODIGO=c.COB_CODIGO  
			WHERE DEU_ASIG_DESDE <= GETDATE() AND  
				(DEU_ASIG_HASTA >= GETDATE() OR  
				DEU_ASIG_HASTA IS NULL) AND  
				COB_EXTERNO = 'S' AND  
				p.ppc_periodo <= @ult_per_hc  

			SET @OPERACION = 'UPDATE #tmp_planilla_pago_cotiz'    
			UPDATE #tmp_planilla_pago_cotiz  
				SET  afecto_cob = 'S'  
			FROM #tmp_planilla_pago_cotiz p  
			JOIN #folios f ON f.ppc_folio = p.ppc_folio  
  
			SET @OPERACION = 'DROP TABLE #folios'
			DROP TABLE #folios  
  
			----------------------------------------------------------------------------------------------------------------------  
			----------------------------------------------------------------------------------------------------------------------  
			----------------------------------------------------------------------------------------------------------------------  
			SET @OPERACION = 'INSERT INTO planilla_pago_cotiz' 
			INSERT INTO planilla_pago_cotiz  
				(ppc_folio,  
				epa_rut,  
				epa_correl,  
				age_codigo,  
				tpa_codigo,  
				tpg_codigo,  
				ppc_periodo,  
				ppc_imponible,  
				ppc_pactado,  
				ppc_deuda,  
				ppc_cotiz_legal,  
				ppc_cotiz_adic,  
				ppc_cotiz_apagar,  
				ppc_reajustes,  
				ppc_intereses,  
				ppc_recargos,  
				ppc_subtotal,  
				ppc_descto_cotiz,  
				ppc_descto_int,  
				ppc_descto_rea,  
				ppc_descto_rec,  
				ppc_total,  
				opa_codigo,  
				ppc_digita,  
				ppc_fecha_digita,  
				ppc_caja,  
				ppc_origen
				)  
				SELECT ppc_folio,  
				epa_rut,  
				epa_correl,  
				age_codigo,  
				tpa_codigo,  
				tpg_codigo,  
				ppc_periodo,  
				ppc_imponible,  
				ppc_pactado,  
				ppc_deuda,  
				ppc_cotiz_legal,  
				ppc_cotiz_adic,  
				ppc_cotiz_apagar,  
				ppc_reajustes,  
				ppc_intereses,  
				ppc_recargos,  
				ppc_subtotal,  
				ppc_descto_cotiz,  
				ppc_descto_int,  
				ppc_descto_rea,  
				ppc_descto_rec,  
				ppc_total,  
				opa_codigo,  
				ppc_digita,  
				ppc_fecha_digita,  
				ppc_caja,  
				ppc_origen  
			FROM #tmp_planilla_pago_cotiz  

			IF @@TRANCOUNT > 0 AND XACT_STATE() <= 0
			BEGIN
				ROLLBACK TRANSACTION;
				RAISERROR('Transacción muerta después de planilla_pago_cotiz.', 16, 1);
				RETURN;
			END
			-----------------------------------------------  
			-- FIN PLANILLA -------------------------------  
			-----------------------------------------------  
  
			-----------------------------------------------  
			-- INI ACTUALIZAR PPC_FOLIO EN TABLA PM_CUPONPAGO_DET TODAS LAS PLANILLAS GENERADAS PARA EL RUT  
			----------------------------------------------- 
  			SET @OPERACION = 'UPDATE #pm_cuponpago_det'
			UPDATE #pm_cuponpago_det  
				SET  #pm_cuponpago_det.ppc_folio = #tmp_planilla_pago_cotiz.ppc_folio  
			FROM #tmp_planilla_pago_cotiz  
			WHERE #pm_cuponpago_det.pmc_rut = #tmp_planilla_pago_cotiz.EPA_RUT AND  
				#pm_cuponpago_det.pmc_periodo = #tmp_planilla_pago_cotiz.ppc_periodo AND  
				#pm_cuponpago_det.pmc_correl = 1  
			-----------------------------------------------  
			-- FIN ACTUALIZAR PPC_FOLIO EN TABLA PM_CUPONPAGO_DET TODAS LAS PLANILLAS GENERADAS PARA EL RUT  
			-----------------------------------------------  
  
			-----------------------------------------------  
			-- INI PLANILLA DETALLE -----------------------  
			-----------------------------------------------  
  			SET @OPERACION = 'INSERT INTO #tmp_planilla_pago_cotiz_det'
			INSERT INTO #tmp_planilla_pago_cotiz_det  
			(ppc_folio,  
			ppd_correl,  
			cot_rut,  
			ppd_imponible,  
			ppd_cotiz_legal,  
			ppd_cotiz_adic,  
			ppd_cotiz_apagar,  
			ppd_cotiz_pactada)     
			SELECT  #pm_cuponpago_det.ppc_folio,  
				row_number() over (partition by #pm_cuponpago_det.ppc_folio order by #pm_cuponpago_det.ppc_folio),  
				#pm_cuponpago_dettrab.pmd_rut_trab,  
				CASE   
				WHEN pmd_monto <= ((parametros.par_valor * uf.uf_valor)) THEN ROUND(pmd_monto / 0.07, 0)  
				ELSE ROUND((parametros.par_valor * uf.uf_valor)  / 0.07, 0)  
				END AS ppd_imponible,  
				CASE   
				WHEN pmd_monto <= ((parametros.par_valor * uf.uf_valor)) THEN ROUND(pmd_monto, 0)  
				ELSE ROUND((parametros.par_valor * uf.uf_valor) , 0)  
				END AS ppd_cotiz_legal,  
				CASE   
				WHEN pmd_monto > ((parametros.par_valor * uf.uf_valor)) THEN ROUND((pmd_monto - (parametros.par_valor * uf.uf_valor)), 0)  
				ELSE 0  
				END AS ppd_cotiz_adic,  
				pmd_monto AS ppd_cotiz_apagar,  
				0 AS ppd_cotiz_pactada  
			FROM  #pm_cuponpago_det  
				JOIN #pm_cuponpago_dettrab ON #pm_cuponpago_det.pmc_correl = #pm_cuponpago_dettrab.pmc_correl AND #pm_cuponpago_det.pmc_rut = #pm_cuponpago_dettrab.pmc_rut AND #pm_cuponpago_det.pmc_periodo = #pm_cuponpago_dettrab.pmc_periodo  
				LEFT JOIN parametros  WITH (NOLOCK) ON #pm_cuponpago_det.pmc_periodo >= parametros.par_inivig AND (#pm_cuponpago_det.pmc_periodo <= parametros.par_finvig OR parametros.par_finvig IS NULL) AND parametros.par_codigo = 'TLE'  
				LEFT JOIN uf  WITH (NOLOCK) ON uf.uf_fecha = DATEADD(DAY, -1, DATEADD(MONTH, 1, #pm_cuponpago_det.pmc_periodo))  
			WHERE  #pm_cuponpago_det.pmc_correl = 1  
			ORDER BY #pm_cuponpago_det.pmc_rut,  
				#pm_cuponpago_det.pmc_periodo  
  
    		SET @OPERACION = 'INSERT INTO planilla_pago_cotiz_det'
			INSERT INTO planilla_pago_cotiz_det  
				(ppc_folio,  
				ppd_correl,  
				cot_rut,  
				ppd_imponible,  
				ppd_cotiz_legal,  
				ppd_cotiz_adic,  
				ppd_cotiz_apagar,  
				ppd_cotiz_pactada)  
				SELECT ppc_folio,  
				ppd_correl,  
				cot_rut,  
				ppd_imponible,  
				ppd_cotiz_legal,  
				ppd_cotiz_adic,  
				ppd_cotiz_apagar,  
				ppd_cotiz_pactada  
			FROM #tmp_planilla_pago_cotiz_det  
			-----------------------------------------------  
			-- FIN PLANILLA DETALLE -----------------------  
			-----------------------------------------------  
  
			-----------------------------------------------  
			-- INI CUPON PAGO -----------------------------  
			-----------------------------------------------  

			--JMOLINA CREE ESTE PARAMETRO POR Q SE NECESITABA
			DECLARE @usuario VARCHAR(30)		--antiguamente era un parametro de entrada
			DECLARE @hon_cob NUMERIC(10)		--antiguamente era un parametro de entrada

			SET @OPERACION = 'INSERT INTO #tmp_cuponpago_cotiz'
			INSERT INTO #tmp_cuponpago_cotiz  
				(cup_correl,  
				usu_login,  
				cup_fechareg,  
				ddr_rut,  
				ddr_nombre,  
				cup_fechapago,  
				cup_foliopago,  
				cup_honorarios_cob,  
				roi_folio
				)  
				SELECT   ROW_NUMBER() over (PARTITION BY '' ORDER BY tmp.epa_rut, ep.epa_razon) +  @cup_correl - 1,  
				coalesce (@usuario,'SYSTEM'), --LOGIN DE '        28'       GETDATE(),
				@cup_id_base,	--GETDATE(), 
				tmp.epa_rut,  
				COALESCE(left(ep.epa_razon,65),''),  
				NULL,  
				NULL,  
				CASE  
				WHEN @hon_cob >=0 THEN @hon_cob  
				WHEN MAX(tmp.afecto_cob) = 'N' THEN 0  
				ELSE dbo.f_honorario_cobranza_masivo(SUM(case when tmp.afecto_cob = 'N' then 0 else tmp.ppc_pactado end))  
				END,  
				NULL  
			FROM  #tmp_planilla_pago_cotiz tmp WITH (NOLOCK)  
			LEFT JOIN entidad_pagadora ep WITH (NOLOCK) ON tmp.epa_rut = ep.epa_rut AND ep.epa_correl = 1  
			WHERE  tmp.proceso = 1  
			GROUP BY tmp.epa_rut,  
				ep.epa_razon  

			SET @OPERACION = 'INSERT INTO CUPONPAGO_COTIZ'
			INSERT INTO CUPONPAGO_COTIZ  
				(cup_correl,  
				usu_login,  
				cup_fechareg,  
				ddr_rut,  
				ddr_nombre,  
				cup_fechapago,  
				cup_foliopago,  
				cup_honorarios_cob,  
				roi_folio
				)  
				SELECT cup_correl,  
				usu_login ,  
				cup_fechareg,  
				ddr_rut,  
				ddr_nombre,  
				cup_fechapago,  
				cup_foliopago,  
				cup_honorarios_cob,  
				roi_folio  
			FROM #tmp_cuponpago_cotiz  

			-- Validar que se hayan insertado filas
			IF @@ROWCOUNT = 0
			BEGIN
				IF @@TRANCOUNT > 0	ROLLBACK TRANSACTION;

				RAISERROR('No se registro en CUPONPAGO_COTIZ.', 16, 1);
				RETURN;
			END

			-----------------------------------------------  
			-- FIN CUPON PAGO -----------------------------  
			-----------------------------------------------  
  
			-----------------------------------------------  
			-- INI CUPON PAGO DETALLE----------------------  
			-----------------------------------------------  
			SET @OPERACION = 'INSERT INTO #tmp_cuponpago_cotiz_detalle'
			INSERT INTO #tmp_cuponpago_cotiz_detalle  
				(cup_correl,  
				ppc_folio
				)  
				SELECT  tcc.cup_correl,  
				tmp.ppc_folio  
			FROM  #tmp_planilla_pago_cotiz tmp WITH (NOLOCK)  
			JOIN #tmp_cuponpago_cotiz tcc WITH (NOLOCK) ON tmp.epa_rut = tcc.ddr_rut  
			WHERE  tmp.proceso = 1  
			GROUP BY tmp.epa_rut,  
				tcc.cup_correl,  
				tmp.ppc_folio  
 
 			SET @OPERACION = 'INSERT INTO CUPONPAGO_COTIZ_DETALLE'
			INSERT INTO CUPONPAGO_COTIZ_DETALLE  
				(cup_correl,  
				ppc_folio
				)  
				SELECT cup_correl,  
				ppc_folio  
			FROM #tmp_cuponpago_cotiz_detalle WITH (NOLOCK) 
			
			-- Validar que se hayan insertado filas
			IF @@ROWCOUNT = 0
			BEGIN
				IF @@TRANCOUNT > 0	ROLLBACK TRANSACTION;

				RAISERROR('No se registro en CUPONPAGO_COTIZ_DETALLE.', 16, 1);
				RETURN;
			END
			-----------------------------------------------  
			-- FIN CUPON PAGO -----------------------------  
			-----------------------------------------------  

 			SET @OPERACION = 'INSERT INTO #paso_cupones'
			select distinct  
				ccd.cup_correl  
				, PMC_RUT AS RUT		--JMOLINA: agregar esta linea
			into #paso_cupones  
			from #pm_cuponpago_det d  
			join cuponpago_cotiz_detalle ccd on d.ppc_folio = ccd.ppc_folio  
			where d.PMC_CORREL= 1  
     
 			SET @OPERACION = 'INSERT INTO #paso_cupones_link'
			--select cup_correl, 'https://apps.nuevamasvida.cl/App_Portal_Pago/?ID=' + CONVERT(VARCHAR(MAX), dbo.f_conex_encrip(cup_correl), 1) as link   
			--select cup_correl, 'https://pcotiz.nuevamasvida.cl/?ID=' + CONVERT(VARCHAR(MAX), dbo.f_conex_encrip(cup_correl), 1) as link		--JMOLINA V0
			select cup_correl, 'https://pcotiz.nuevamasvida.cl/?ID=' + CONVERT(VARCHAR(MAX), dbo.f_conex_encrip(cup_correl), 1) as link, RUT		--JMOLINA V1
			into #paso_cupones_link  
			from #paso_cupones  
   
			create index i1 on #paso_cupones_link (cup_correl)  
  
			SET @OPERACION = 'UPDATE #pm_cuponpago_det'
			UPDATE #pm_cuponpago_det  
				SET  pmc_link = link  
			FROM #pm_cuponpago_det pmd  
			join cuponpago_cotiz_detalle ccd on pmd.ppc_folio = ccd.ppc_folio   
			join #paso_cupones_link l on l.CUP_CORREL = ccd.cup_correl  
			WHERE pmd.PMC_CORREL = 1    
   
			-------------------------------------------------  
			-- Desglosar montos de las planillas  
			------------------------------------------------- 
			SET @OPERACION = 'UPDATE planilla_pago_cotiz'
			UPDATE planilla_pago_cotiz   
				SET  PPC_IMPONIBLE = CASE WHEN PPC_COTIZ_APAGAR <= ((parametros.par_valor * uf.uf_valor)) THEN ROUND(PPC_COTIZ_APAGAR / 0.07, 0) ELSE ROUND((parametros.par_valor * uf.uf_valor) / 0.07, 0) END,  
				PPC_COTIZ_LEGAL = CASE WHEN PPC_COTIZ_APAGAR <= ((parametros.par_valor * uf.uf_valor)) THEN ROUND(PPC_COTIZ_APAGAR, 0) ELSE ROUND((parametros.par_valor * uf.uf_valor) , 0) END,  
				PPC_COTIZ_ADIC = CASE WHEN PPC_COTIZ_APAGAR > ((parametros.par_valor * uf.uf_valor)) THEN ROUND((PPC_COTIZ_APAGAR - (parametros.par_valor * uf.uf_valor)), 0) ELSE 0 END  
			FROM PLANILLA_PAGO_COTIZ with (nolock)  
			JOIN #pm_cuponpago_det with (nolock) on #pm_cuponpago_det.PPC_FOLIO = planilla_pago_cotiz.PPC_FOLIO   
			LEFT JOIN parametros with (nolock) ON #pm_cuponpago_det.pmc_periodo >= parametros.par_inivig AND (#pm_cuponpago_det.pmc_periodo <= parametros.par_finvig OR parametros.par_finvig IS NULL) AND parametros.par_codigo = 'TLE'  
			LEFT JOIN uf ON uf.uf_fecha = DATEADD(DAY, -1, DATEADD(MONTH, 1, #pm_cuponpago_det.pmc_periodo))  
			WHERE #pm_cuponpago_det.PMC_CORREL = 1 
				and not exists (select * from PLANILLA_PAGO_COTIZ_DET with (nolock) where PLANILLA_PAGO_COTIZ_DET.PPC_FOLIO = PLANILLA_PAGO_COTIZ.PPC_FOLIO)  
  
			-- Planillas con detalle 
 			SET @OPERACION = 'INSERT INTO #totales_planilla'
			SELECT  PLANILLA_PAGO_COTIZ_DET.PPC_FOLIO,  
				sum(ppd_imponible) as ppd_imponible,  
				sum(ppd_cotiz_legal) as ppd_cotiz_legal,  
				sum(ppd_cotiz_adic) as ppd_cotiz_adic  
			INTO  #totales_planilla  
			FROM  PLANILLA_PAGO_COTIZ  
			JOIN #pm_cuponpago_det on #pm_cuponpago_det.PPC_FOLIO = planilla_pago_cotiz.PPC_FOLIO and #pm_cuponpago_det.PMC_CORREL= 1  
			JOIN PLANILLA_PAGO_COTIZ_DET on PLANILLA_PAGO_COTIZ_DET.PPC_FOLIO = PLANILLA_PAGO_COTIZ.PPC_FOLIO  
			GROUP BY PLANILLA_PAGO_COTIZ_DET.PPC_FOLIO    
  
  			SET @OPERACION = 'UPDATE planilla_pago_cotiz'
			UPDATE planilla_pago_cotiz   
				SET  PPC_IMPONIBLE = ppd_imponible,  
				PPC_COTIZ_LEGAL = ppd_cotiz_legal,  
				PPC_COTIZ_ADIC = ppd_cotiz_adic  
			FROM #totales_planilla  
			WHERE #totales_planilla.PPC_FOLIO = planilla_pago_cotiz.PPC_FOLIO     

			-- AGREGAR AQUÍ (última verificación):
			IF @@TRANCOUNT > 0 AND XACT_STATE() <= 0
			BEGIN
				ROLLBACK TRANSACTION;
				RAISERROR('Transacción muerta antes de COMMIT.', 16, 1);
				RETURN;
			END
  

			COMMIT TRAN;  

			-- JMOLINA
			SELECT LINK
			, CUP_CORREL
			, RUT 
			FROM #PASO_CUPONES_LINK  


	END TRY      
      
    --Atrapar
	BEGIN CATCH 
			--Si hay transacciones abiertas
			IF @@TRANCOUNT > 0 ROLLBACK TRAN;

			-- Verificar XACT_STATE()
			IF XACT_STATE() <= 0  SELECT 'TRANSACCIÓN MUERTA' AS Estado;

			DECLARE
				@ErrorNumber    INT = ERROR_NUMBER(),				-- Captura el código numérico del error (ej: 8134 para división por cero) .
				@ErrorSeverity  INT = ERROR_SEVERITY(),				-- Guarda la gravedad del error (10-25, donde 16+ son errores de usuario).
				@ErrorState     INT = ERROR_STATE(),				-- Registra el estado interno del error (diferencia variantes del mismo error).
				@ErrorProcedure NVARCHAR(128) = ERROR_PROCEDURE(),	-- Nombre del SP, trigger o función donde falló la sentencia.
				@ErrorLine      INT = ERROR_LINE(),					-- Número exacto de línea donde ocurrió el error en el código
				@ErrorMessage   NVARCHAR(4000) = ERROR_MESSAGE(),	-- Texto completo del mensaje de error con detalles (columnas, valores, etc.)
				@MensajeFinal   NVARCHAR(4000)

			SET @MensajeFinal = 'Error Proceso: ' + ISNULL(@OPERACION, '') + 
                   ' . Nº: ' + CAST(@ErrorNumber AS VARCHAR(10)) + 
                   ', Sp_trigger_funcion: ' + ISNULL(@ErrorProcedure, '') + 
                   ', Línea: ' + CAST(@ErrorLine AS VARCHAR(10)) +
				   ', Línea: ' + ISNULL(@ErrorProcedure, '') +
                   ', Detalle error: ' + ISNULL(@ErrorMessage, '');

			RAISERROR(@MensajeFinal, 16, 1);
			RETURN;

	END CATCH
    
END     