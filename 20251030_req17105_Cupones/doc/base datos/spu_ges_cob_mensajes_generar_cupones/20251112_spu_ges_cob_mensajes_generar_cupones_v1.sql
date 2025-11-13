/* ======================================================================================== */  
/* TIPO DE OBJETO     : Procedimiento Almacenado                                            */  
/*                                                                                          */  
/* NOMBRE DEL OBJETO  : spu_cuponpago_genera_con_descto_empleador       */  
/*                                                                                          */  
/* PARAMETROS         : @epa_rut: Rut de Entidad Pagadora         */  
/*      @desc_deudanom: Descuento Deuda Nominal        */  
/*      @desc_reajuste: Descuento Reajuste         */  
/*      @desc_interes: Descuento Interés         */  
/*      @desc_recargo: Descuento Recargo         */  
/* RETORNO            : Enlace: Corresponde a ruta del Cupón de Pago      */  
/*                       */  
/* CREADO POR         : Alberto Rozas              */  
/* FECHA CREACIÓN     : 03/02/2022                                                         */  
/* DESCRIPCIÓN        : Genera Cupón de Pago que se traducen en Planillas de Pago de  */  
/*      Cotizaciones, las cuales son creadas en PLANILLA_PAGO_COTIZ con sus */  
/*      respectivos descuentos.            */  
/* ======================================================================================== */  
/* MODIFICADO POR     : Marcelo Sanhueza             */  
/* FECHA CREACIÓN     : 26/08/2023                                                         */  
/* DESCRIPCIÓN        : Se agrega el parámetro @hon_cob para indicar un monto fijo de       */  
/*                      Honorarios de cobranza para el cupón.        */  
/* ======================================================================================== */  
--CREATE PROCEDURE [dbo].[spu_cuponpago_genera_con_descto_empleador]  
CREATE PROCEDURE [dbo].[spu_ges_cob_mensajes_generar_cupones]  
 @epa_rut  CHAR(10),  
 @desc_deudanom NUMERIC(10),  
 @desc_reajuste NUMERIC(10),  
 @desc_interes NUMERIC(10),  
 @desc_recargo NUMERIC(10),  
 @usuario varchar(100)=null,  
 @hon_cob numeric(12)=null,  
 @correl_gescob numeric(10)=null,  
 @valida_lagunas char(1)='S'  
AS  
BEGIN   
 SET NOCOUNT ON;  
      
 DECLARE  
  @sql varchar(2000),  
        @cant_reg  NUMERIC(20),  
        @ppc_folio  NUMERIC(20),  
        @cup_correl  NUMERIC(20),  
        @fec_proceso DATETIME,  
        @rut_sin_datos CHAR(10),  
        @txt_error  VARCHAR(200),  
  @ult_per_hc  DATETIME,  
  @tot_deudanom NUMERIC(10),  
  @tot_reajuste NUMERIC(10),  
  @tot_interes NUMERIC(10),  
  @tot_recargo NUMERIC(10),    
  @new_tot_dn  NUMERIC(10),  
  @new_tot_rea NUMERIC(10),  
  @new_tot_int NUMERIC(10),  
  @new_tot_rec NUMERIC(10),  
  @max_id   INT,  
  @dif   INT,  
  @epa_razon   varchar(200),    
  @n     NUMERIC(10)  
  
 --BEGIN TRAN  
 --BEGIN TRY  
  -- #PM_CUPONPAGO_DET  
  CREATE TABLE [#pm_cuponpago_det](  
   [PMC_CORREL] [numeric](10, 0) NOT NULL,  
   [PMC_RUT] [char](10) NOT NULL,  
   [PMC_PERIODO] [datetime] NOT NULL,  
   [PMC_MONTO] [numeric](15, 0) NOT NULL,  
   [PMC_INT] [numeric](15, 0) NULL,  
   [PMC_REA] [numeric](15, 0) NULL,  
   [PMC_REC] [numeric](15, 0) NULL,  
   [PMC_INT_D] [numeric](15, 0) NULL,  
   [PMC_REA_D] [numeric](15, 0) NULL,  
   [PMC_REC_D] [numeric](15, 0) NULL,  
   [PPC_FOLIO] [numeric](10, 0) NULL,  
   [PMC_LINK] [varchar](500) NULL,  
   [PMC_MONTO_D] [numeric](15, 0) NULL,  
   [GDC_TIPODEUDOR] [char](1) NULL  
  )  
  
  -- #PM_CUPONPAGO_DETTRAB  
  CREATE TABLE [#pm_cuponpago_dettrab](  
   [PMC_CORREL] [numeric](10, 0) NOT NULL,  
   [PMC_RUT] [char](10) NOT NULL,  
   [PMC_PERIODO] [datetime] NOT NULL,  
   [PMD_RUT_TRAB] [char](10) NOT NULL,  
   [PMD_MONTO] [numeric](15, 0) NOT NULL  
  )  
  
     CREATE TABLE #rut_det_pago (EPA_RUT CHAR(10))  
  INSERT INTO #rut_det_pago(EPA_RUT)  
  VALUES (@epa_rut)  
  
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
         
  SET @fec_proceso = CONVERT(CHAR(8), GETDATE(), 112)  
  --SET @fec_proceso = '20211201'  
    
  IF @correl_gescob IS NULL  
   BEGIN  
    INSERT INTO #consdeuda  
    EXEC [EVOLUTION].[ISAPRE].dbo.spu_ges_cob_consdeuda @epa_rut, @fec_proceso  
   END  
  ELSE  
   BEGIN  
    INSERT INTO #consdeuda  
    (     
     SEL       
    ,COT_RUT      
    ,NOM_COTIZANTE    
    ,EPA_RUT      
    ,EPA_RAZON     
    ,DEC_PERIODO     
    ,DEC_TIPO_DEUDA    
    ,DEC_NRORESOL    
    ,PACTADO      
    ,PAGADO      
    ,DEUDANOMINAL    
    ,REAJUSTE     
    ,INTERES      
    ,RECARGO      
    ,TOTAL_APAGAR    
    ,COBRADOR     
    ,FECHA      
    ,ANO       
    ,MES       
    ,DEUDA_HC     
    ,DESCTO_DEUDANOMINAL   
    ,DESCTO_REAJUSTE    
    ,DESCTO_INTERES    
    ,DESCTO_RECARGO    
    ,FOLIO_FUN_HAB    
    ,FECHA_FUN_HAB    
    ,REJ_FOLIO   
    )  
    SELECT   
    'S' AS SEL  
    ,[COT_RUT]  
    ,[NOM_COTIZANTE]  
    ,[EPA_RUT]  
    ,[EPA_RAZON]  
    ,[DEC_PERIODO]  
    ,[DEC_TIPO_DEUDA]  
    ,[DEC_NRORESOL]  
    ,[PACTADO]  
    ,[PAGADO]  
    ,[DEUDANOMINAL]  
    ,[REAJUSTE]  
    ,[INTERES]  
    ,[RECARGO]  
    ,[TOTAL_APAGAR]  
    ,[COBRADOR]  
    ,[FECHA]  
    ,[ANO]  
    ,[MES]  
    ,[DEUDA_HC]  
    ,[DESCTO_DEUDANOMINAL]  
    ,[DESCTO_REAJUSTE]  
    ,[DESCTO_INTERES]  
    ,[DESCTO_RECARGO]  
    ,[FOLIO_FUN_HAB]  
    ,[FECHA_FUN_HAB]  
    ,[REJ_FOLIO]  
    FROM [dbo].[CUPONPAGO_COTIZ_DEUDA]  
    WHERE CORREL=@correl_gescob  
  
    ----------------------------------------------------------------------------------------------------------------  
    ----------------- Valida lagunas de deda si está indicado por el parámetro @valida_lagunas  
    ----------------------------------------------------------------------------------------------------------------  
    IF upper(coalesce(@valida_lagunas,'N'))='S'  
    BEGIN  
  
     --Busca lagunas desde el último periodo que va a pagar hacia atrás  
     SELECT @n= COUNT(*)  
     from #consdeuda where exists (  
     select *  
     FROM EVOLUTION.ISAPRE.DBO.DEUDA_COTIZANTE  AS DEUDA_COTIZANTE  
     WHERE DEUDA_COTIZANTE.COT_RUT = #consdeuda.cot_rut    
      and (CASE  
         WHEN ( (DEUDA_COTIZANTE.EPA_RUT is NOT null and DEUDA_COTIZANTE.DEC_TIPO_COTIZANTE in ('I','V'/*,'P'*/)) or DEC_FINIQUITO='S') THEN DEUDA_COTIZANTE.COT_RUT  
         WHEN (SELECT COUNT(*) FROM EVOLUTION.ISAPRE.DBO.DEUDA_COTIZANTE P3 (NOLOCK) WHERE P3.COT_RUT = DEUDA_COTIZANTE.COT_RUT AND P3.DEC_PERIODO = DEUDA_COTIZANTE.DEC_PERIODO AND P3.EPA_RUT IS NOT NULL) > 1 THEN ''  
         ELSE COALESCE((SELECT MAX(P4.EPA_RUT) FROM EVOLUTION.ISAPRE.DBO.DEUDA_COTIZANTE P4 (NOLOCK) WHERE P4.COT_RUT = DEUDA_COTIZANTE.COT_RUT AND P4.DEC_PERIODO = DEUDA_COTIZANTE.DEC_PERIODO AND P4.EPA_RUT IS NOT NULL), DEUDA_COTIZANTE.COT_RUT)  
        END )= #consdeuda.epa_rut   
      AND DEC_PACTADO > DEC_PAGADO  
      and DEC_PERIODO NOT IN (SELECT CONVERT(DATETIME,CONVERT(CHAR(6),c2.DEC_PERIODO,112)+'01') FROM #consdeuda c2 where #consdeuda.cot_rut =c2.cot_rut   and #consdeuda.epa_rut =c2.epa_rut )  
      AND DEC_PERIODO <= (SELECT MAX(CONVERT(DATETIME,CONVERT(CHAR(6),c2.DEC_PERIODO,112)+'01')) FROM #consdeuda c2 where #consdeuda.cot_rut =c2.cot_rut   and #consdeuda.epa_rut =c2.epa_rut ) )  
  
     IF (@n>0)   
      BEGIN      
       RAISERROR ('Error: No se permite dejar periodos antiguos de deuda impagos.', 16, 1)  
       ROLLBACK  
       RETURN -1                 
      END   
  
    END  
  
   END  
    
  
  --Descarta casos sin deuda  
  delete from #consdeuda where pactado - pagado <=0  
  ---- Descarta casos con Multi-empleador  
  --DELETE  
  --FROM #consdeuda  
  --WHERE epa_rut <> @epa_rut  
  select TOP 1 @epa_razon = EPA_RAZON FROM #consdeuda WHERE EPA_RUT= @epa_rut  
  UPDATE #consdeuda SET EPA_RUT=@epa_rut, EPA_RAZON=coalesce(@epa_razon,EPA_RAZON)   
  
  
  SELECT @tot_deudanom = SUM(DEUDANOMINAL) FROM #consdeuda  
  SELECT @tot_reajuste = SUM(REAJUSTE) FROM #consdeuda  
  SELECT @tot_interes = SUM(INTERES) FROM #consdeuda  
  SELECT @tot_recargo = SUM(RECARGO) FROM #consdeuda    
      
  UPDATE #consdeuda  
  SET  DESCTO_DEUDANOMINAL = CASE WHEN @tot_deudanom > 0 THEN DEUDANOMINAL * (@desc_deudanom * 100 / @tot_deudanom) / 100 ELSE 0 END,  
    DESCTO_REAJUSTE = ROUND(CASE WHEN @tot_reajuste > 0 THEN REAJUSTE * (@desc_reajuste * 100 / @tot_reajuste) / 100 ELSE 0 END, 0),  
    DESCTO_INTERES = ROUND(CASE WHEN @tot_interes > 0 THEN INTERES * (@desc_interes * 100 / @tot_interes) / 100 ELSE 0 END, 0),  
    DESCTO_RECARGO = ROUND(CASE WHEN @tot_recargo > 0 THEN RECARGO * (@desc_recargo * 100 / @tot_recargo) / 100 ELSE 0 END, 0)    
  
  SELECT @new_tot_dn = SUM(DESCTO_DEUDANOMINAL),  
    @new_tot_rea = SUM(DESCTO_REAJUSTE),  
    @new_tot_int = SUM(DESCTO_INTERES),  
    @new_tot_rec = SUM(DESCTO_RECARGO)  
  FROM #consdeuda    
  
  SELECT @max_id = MAX(ID) FROM #consdeuda    
  
  -- Ajustes  
  SET @dif = @desc_deudanom - @new_tot_dn  
  IF @dif <> 0  
  BEGIN  
   UPDATE #consdeuda  
   SET  DESCTO_DEUDANOMINAL = DESCTO_DEUDANOMINAL + @dif  
   WHERE ID = @max_id  
  END    
  
  SET @dif = @desc_reajuste - @new_tot_rea  
  IF @dif <> 0  
  BEGIN  
   UPDATE #consdeuda  
   SET  DESCTO_REAJUSTE = DESCTO_REAJUSTE + @dif  
   WHERE ID = @max_id  
  END  
  
  SET @dif = @desc_interes - @new_tot_int  
  IF @dif <> 0  
  BEGIN  
   UPDATE #consdeuda  
   SET  DESCTO_INTERES = DESCTO_INTERES + @dif  
   WHERE ID = @max_id  
  END  
  
  SET @dif = @desc_recargo - @new_tot_rec  
  IF @dif <> 0  
  BEGIN  
   UPDATE #consdeuda  
   SET  DESCTO_RECARGO = DESCTO_RECARGO + @dif  
   WHERE ID = @max_id  
  END    
  
  -- Copiar todos los registros    
  INSERT INTO #pm_cuponpago_dettrab  
  SELECT 1,  
    EPA_RUT,  
    DEC_PERIODO,  
    COT_RUT,  
    DEUDANOMINAL  
  FROM #consdeuda  
  
  -- Copiar registros agrupados por período (un registro = una planilla)  
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
  
  -- GENERAR FOLIO PLANILLA  
     CREATE TABLE #ppc_folio (ppc_folio NUMERIC(15), ppc_folio_fin NUMERIC(15))  
  
  INSERT INTO #ppc_folio EXEC spu_nuevo_correl 'PPM', 0, @cant_reg  
    
  
  SELECT @ppc_folio = ppc_folio FROM #ppc_folio  
  
     CREATE TABLE #cup_correl (folio_ini NUMERIC(15), folio_fin NUMERIC(15))  
  
  INSERT INTO #cup_correl EXEC spu_nuevo_correl 'CUP', 0, @cant_reg  
    
  SELECT @cup_correl = folio_ini FROM #cup_correl  
  
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
      
        --DBCC checkident (#tmp_planilla_pago_cotiz, reseed, @ppc_folio)  
  
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
  
  
        --EXEC (@sql)  
  
        --DBCC checkident (#tmp_cuponpago_cotiz, reseed, @cup_correl)  
  
  CREATE TABLE #tmp_cuponpago_cotiz_detalle (   
            cup_correl         NUMERIC (15,0),  
            ppc_folio          NUMERIC (15,0),  
            )  
  
  -----------------------------------------------  
  -- INI PLANILLA -------------------------------  
  -----------------------------------------------  
  DELETE FROM VENCIM_PAGO_COTIZACION    
    
  
  INSERT INTO [VENCIM_PAGO_COTIZACION] (VPC_PERIODO, VPC_VENCIMIENTO)  
  SELECT  VPC_PERIODO, VPC_VENCIMIENTO FROM [EVOLUTION].[ISAPRE].[DBO].[VENCIM_PAGO_COTIZACION]  WITH (NOLOCK)   
  
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
     CASE WHEN (SELECT COUNT(#pm_cuponpago_dettrab.pmc_correl) FROM #pm_cuponpago_dettrab WITH (NOLOCK) WHERE #pm_cuponpago_dettrab.pmc_correl = #pm_cuponpago_det.pmc_correl AND #pm_cuponpago_dettrab.pmc_rut = #pm_cuponpago_det.pmc_rut AND #pm_cuponpago_
dettrab.pmc_periodo = #pm_cuponpago_det.pmc_periodo) > 0 THEN 1  
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
     GETDATE(),  
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
  
  UPDATE #tmp_planilla_pago_cotiz  
  SET  afecto_cob = 'S'  
  FROM #tmp_planilla_pago_cotiz p  
    JOIN #folios f ON f.ppc_folio = p.ppc_folio  
  
  DROP TABLE #folios  
  
  -- Obtener las planillas q están afectas a honorarios de cobranza  
  /*  
  select p.ppc_folio  
  into #folios2  
  from #tmp_planilla_pago_cotiz p  
    join /*[evolution].*/[isapre].[dbo].DEUDOR_ASIGNADO d with (nolock) on p.epa_rut = d.DDR_RUT  
    join /*[evolution].*/[isapre].[dbo].COBRADOR c with (nolock) on d.COB_CODIGO = c.COB_CODIGO  
    join /*[evolution].*/[isapre].[dbo].DEUDA_COTIZANTE dc with (nolock) on dc.DEC_RUT = d.DDR_RUT  
  where DEU_ASIG_DESDE <= GETDATE() and  
    (DEU_ASIG_HASTA >= GETDATE() or  
    DEU_ASIG_HASTA is null) and  
    COB_EXTERNO = 'S' and  
    afecto_cob = 'N' and  
    dc.DEC_PERIODO = p.ppc_periodo and  
    p.ppc_periodo <= @ult_per_hc  
  
  update #tmp_planilla_pago_cotiz  
  set  afecto_cob = 'S'  
  from #tmp_planilla_pago_cotiz p  
    join #folios2 f on f.ppc_folio = p.ppc_folio  
  
  drop table #folios2  
  */  
  ----------------------------------------------------------------------------------------------------------------------  
  ----------------------------------------------------------------------------------------------------------------------  
  ----------------------------------------------------------------------------------------------------------------------  
  
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
    ppc_origen)  
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
  -----------------------------------------------  
  -- FIN PLANILLA -------------------------------  
  -----------------------------------------------  
  
  -----------------------------------------------  
  -- INI ACTUALIZAR PPC_FOLIO EN TABLA PM_CUPONPAGO_DET TODAS LAS PLANILLAS GENERADAS PARA EL RUT  
  -----------------------------------------------  
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
  INSERT INTO #tmp_cuponpago_cotiz  
     (cup_correl,  
     usu_login,  
     cup_fechareg,  
     ddr_rut,  
     ddr_nombre,  
     cup_fechapago,  
     cup_foliopago,  
     cup_honorarios_cob,  
     roi_folio)  
  SELECT   ROW_NUMBER() over (PARTITION BY '' ORDER BY tmp.epa_rut, ep.epa_razon) +  @cup_correl - 1,  
     coalesce (@usuario,'SYSTEM'), --LOGIN DE '        28'       GETDATE(),  
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
  
  INSERT INTO CUPONPAGO_COTIZ  
    (cup_correl,  
    usu_login,  
    cup_fechareg,  
    ddr_rut,  
    ddr_nombre,  
    cup_fechapago,  
    cup_foliopago,  
    cup_honorarios_cob,  
    roi_folio)  
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
  -----------------------------------------------  
  -- FIN CUPON PAGO -----------------------------  
  -----------------------------------------------  
  
  -----------------------------------------------  
  -- INI CUPON PAGO -----------------------------  
  -----------------------------------------------  
  INSERT INTO #tmp_cuponpago_cotiz_detalle  
     (cup_correl,  
     ppc_folio)  
  SELECT  tcc.cup_correl,  
     tmp.ppc_folio  
  FROM  #tmp_planilla_pago_cotiz tmp WITH (NOLOCK)  
     JOIN #tmp_cuponpago_cotiz tcc WITH (NOLOCK) ON tmp.epa_rut = tcc.ddr_rut  
  WHERE  tmp.proceso = 1  
  GROUP BY tmp.epa_rut,  
     tcc.cup_correl,  
     tmp.ppc_folio  
  
  INSERT INTO cuponpago_cotiz_detalle  
    (cup_correl,  
    ppc_folio)  
  SELECT cup_correl,  
    ppc_folio  
  FROM #tmp_cuponpago_cotiz_detalle WITH (NOLOCK)  
  -----------------------------------------------  
  -- FIN CUPON PAGO -----------------------------  
  -----------------------------------------------  
  
  select distinct  
    ccd.cup_correl  
  into #paso_cupones  
  from #pm_cuponpago_det d  
    join cuponpago_cotiz_detalle ccd on d.ppc_folio = ccd.ppc_folio  
  where d.PMC_CORREL= 1  
  
  --select * from #paso_cupones    
  
  --select cup_correl, 'https://apps.nuevamasvida.cl/App_Portal_Pago/?ID=' + CONVERT(VARCHAR(MAX), dbo.f_conex_encrip(cup_correl), 1) as link   
  select cup_correl, 'https://pcotiz.nuevamasvida.cl/?ID=' + CONVERT(VARCHAR(MAX), dbo.f_conex_encrip(cup_correl), 1) as link   
  into #paso_cupones_link  
  from #paso_cupones  
   
  create index i1 on #paso_cupones_link (cup_correl)  
  
  UPDATE #pm_cuponpago_det  
  SET  pmc_link = link  
  FROM #pm_cuponpago_det pmd  
    join cuponpago_cotiz_detalle ccd on pmd.ppc_folio = ccd.ppc_folio   
    join #paso_cupones_link l on l.CUP_CORREL = ccd.cup_correl  
  WHERE pmd.PMC_CORREL = 1    
   
  -------------------------------------------------  
  -- Desglosar montos de las planillas  
  -------------------------------------------------  
  UPDATE planilla_pago_cotiz   
  SET  PPC_IMPONIBLE = CASE WHEN PPC_COTIZ_APAGAR <= ((parametros.par_valor * uf.uf_valor)) THEN ROUND(PPC_COTIZ_APAGAR / 0.07, 0) ELSE ROUND((parametros.par_valor * uf.uf_valor) / 0.07, 0) END,  
    PPC_COTIZ_LEGAL = CASE WHEN PPC_COTIZ_APAGAR <= ((parametros.par_valor * uf.uf_valor)) THEN ROUND(PPC_COTIZ_APAGAR, 0) ELSE ROUND((parametros.par_valor * uf.uf_valor) , 0) END,  
    PPC_COTIZ_ADIC = CASE WHEN PPC_COTIZ_APAGAR > ((parametros.par_valor * uf.uf_valor)) THEN ROUND((PPC_COTIZ_APAGAR - (parametros.par_valor * uf.uf_valor)), 0) ELSE 0 END  
  FROM PLANILLA_PAGO_COTIZ with (nolock)  
    JOIN #pm_cuponpago_det with (nolock) on #pm_cuponpago_det.PPC_FOLIO = planilla_pago_cotiz.PPC_FOLIO   
    LEFT JOIN parametros with (nolock) ON #pm_cuponpago_det.pmc_periodo >= parametros.par_inivig AND (#pm_cuponpago_det.pmc_periodo <= parametros.par_finvig OR parametros.par_finvig IS NULL) AND parametros.par_codigo = 'TLE'  
    LEFT JOIN uf ON uf.uf_fecha = DATEADD(DAY, -1, DATEADD(MONTH, 1, #pm_cuponpago_det.pmc_periodo))  
  WHERE #pm_cuponpago_det.PMC_CORREL = 1 and  
    not exists (select * from PLANILLA_PAGO_COTIZ_DET with (nolock) where PLANILLA_PAGO_COTIZ_DET.PPC_FOLIO = PLANILLA_PAGO_COTIZ.PPC_FOLIO)  
  
  -- Planillas con detalle  
  SELECT  PLANILLA_PAGO_COTIZ_DET.PPC_FOLIO,  
     sum(ppd_imponible) as ppd_imponible,  
     sum(ppd_cotiz_legal) as ppd_cotiz_legal,  
     sum(ppd_cotiz_adic) as ppd_cotiz_adic  
  INTO  #totales_planilla  
  FROM  PLANILLA_PAGO_COTIZ  
     JOIN #pm_cuponpago_det on #pm_cuponpago_det.PPC_FOLIO = planilla_pago_cotiz.PPC_FOLIO and #pm_cuponpago_det.PMC_CORREL= 1  
     JOIN PLANILLA_PAGO_COTIZ_DET on PLANILLA_PAGO_COTIZ_DET.PPC_FOLIO = PLANILLA_PAGO_COTIZ.PPC_FOLIO  
  GROUP BY PLANILLA_PAGO_COTIZ_DET.PPC_FOLIO    
    
  UPDATE planilla_pago_cotiz   
  SET  PPC_IMPONIBLE = ppd_imponible,  
    PPC_COTIZ_LEGAL = ppd_cotiz_legal,  
    PPC_COTIZ_ADIC = ppd_cotiz_adic  
  FROM #totales_planilla  
  WHERE #totales_planilla.PPC_FOLIO = planilla_pago_cotiz.PPC_FOLIO     
  
  --COMMIT  
  if @usuario is null  
   SELECT link  
   FROM #paso_cupones_link  
  else  
   SELECT link, cup_correl  
   FROM #paso_cupones_link  
 --END TRY  
  
 --BEGIN CATCH  
 -- --ROLLBACK  
 -- SELECT  ERROR_MESSAGE()  
 -- --'error'  
    
 --END CATCH  
END  