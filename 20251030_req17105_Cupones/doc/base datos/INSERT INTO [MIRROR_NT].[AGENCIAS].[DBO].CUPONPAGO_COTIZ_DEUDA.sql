			--SELECT * FROM [MIRROR_NT].[AGENCIAS].[DBO].CUPONPAGO_COTIZ_DEUDA
			INSERT INTO [MIRROR_NT].[AGENCIAS].[DBO].CUPONPAGO_COTIZ_DEUDA
					   (CORREL
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
					   ,REJ_FOLIO)
				 --VALUES   (
				 SELECT
					   @correl_gescob	--<CORREL, numeric(16,0),>
					   , tf.rut_deudor	--<COT_RUT, char(10),>
					   , tf.nombre_deudor	--<NOM_COTIZANTE, varchar(25),>
					   , tf.rut_deudor	-- DUDA: IGUAL QUE EL COT_RUT??	--<EPA_RUT, char(10),>
					   , tf.nombre_deudor	-- DUDA: IGUAL QUE EL nombre_deudor??	--<EPA_RAZON, varchar(200),>
					   , tdc.DEC_PERIODO	--<DEC_PERIODO, datetime,>
					   , tdc.DEC_TIPO_DEUDA	--<DEC_TIPO_DEUDA, varchar(20),>
					   , NULL				--<DEC_NRORESOL, numeric(10,0),>
					   , NULL				--<PACTADO, numeric(10,0),>
					   , NULL				--<PAGADO, numeric(10,0),>
					   , NULL				--<DEUDANOMINAL, numeric(10,0),>
					   , NULL				--<REAJUSTE, numeric(10,0),>
					   , NULL				--<INTERES, numeric(10,0),>
					   , NULL				--<RECARGO, numeric(10,0),>
					   , NULL				--<TOTAL_APAGAR, numeric(10,0),>
					   , COALESCE(tf.nombre_ejecutivo, nom_cob_lurchq)	--DUDA				--<COBRADOR, varchar(65),>
					   , NULL				--<FECHA, datetime,>
					   , NULL				--<ANO, int,>
					   , NULL				--<MES, int,>
					   , NULL				--<DEUDA_HC, numeric(10,0),>
					   , NULL				--<DESCTO_DEUDANOMINAL, numeric(10,0),>
					   , NULL				--<DESCTO_REAJUSTE, numeric(16,9),>
					   , NULL				--<DESCTO_INTERES, numeric(16,8),>
					   , NULL				--<DESCTO_RECARGO, numeric(16,8),>
					   , NULL				--<FOLIO_FUN_HAB, numeric(10,0),>
					   , NULL				--<FECHA_FUN_HAB, datetime,>
					   , NULL				--<REJ_FOLIO, numeric(10,0),>
					   --)
				FROM #TMP_DEUDA_COTIZANTE tdc
				JOIN #tabla_final_filtrada tf ON tdc.DEC_RUT = tf.rut_deudor
				WHERE tf.rut_deudor = @rut_deudor;




-- DOS TABLAS 
 create table #DEUDA_COTIZ_EMPL  
 (  
 COT_RUT char(10) not null  
 , DEC_PERIODO datetime null  
 , DEUDA_EMPLEADOR numeric(15) null  
 )  
  
 create table #TMP_DEUDA_COTIZANTE  
 (  
 DEC_RUT char(10) not null  
 , DEC_PERIODO datetime null  
 , DEC_TIPO_DEUDA varCHAR(20)  
 , tipo_empresa varCHAR(20)  
 , DEC_TIPO_COTIZANTE CHAR(10)  
 , DEC_DEUDA numeric(15) null  
 , DEUDA_REAJUSTADA numeric(15) null  
 )  
  
  
 --1.-   
 IF @TipoDeudaCOTIZ = 'SI'  
 BEGIN   
   --1.- Obtiene la deuda de cada COTIZANTE cuya responsabilidad de pago es de algún empleador  
   INSERT #DEUDA_COTIZ_EMPL (COT_RUT, DEC_PERIODO, DEUDA_EMPLEADOR)  
   SELECT  COT_RUT,   
    DEC_PERIODO,  
    SUM(CASE WHEN EPA_RUT IS NOT NULL THEN DEC_PACTADO - DEC_PAGADO END) AS DEUDA_EMPLEADOR  
   FROM DEUDA_COTIZANTE with (nolock)  
   WHERE EPA_RUT IS NOT NULL  
   GROUP BY  COT_RUT, DEC_PERIODO  
  
   CREATE INDEX IDX_1 ON #deuda_cotiz_empl(COT_RUT,DEC_PERIODO)  
  
  
   --2.-Obtiene los registros de deudores desde DEUDA_COTIZANTE, pero restando a los registros de cotizantes (EPA_RUT IS NULL) el monto de la deuda cuya responsabilidad es de algún empleador  
   --y filtramos sólo aquellos registros que quedan con deuda > 0  
   insert into #TMP_DEUDA_COTIZANTE  
   SELECT   
    DC.DEC_RUT,  
    DC.DEC_PERIODO,  
    CASE  
     WHEN DC.DEC_TIPO_DEUDA = 'DNP' THEN 'DNP'  
      WHEN DC.DEC_TIPO_DEUDA = 'NP' AND DC.DEC_PAGADO=0 THEN 'IP'  
     ELSE 'DPP'    
    END AS DEC_TIPO_DEUDA,  
    CASE WHEN EPA_RUT  IS NOT NULL THEN 'EMPRESA' ELSE 'COTIZANTE' END AS tipo_empresa ,  --TIPO_DEUDOR se cambia a tipo_empresa  
    DEC_TIPO_COTIZANTE,  
    (coalesce(DEC_PACTADO,0) - coalesce(DEC_PAGADO,0)) - coalesce(deuda_empleador,0) as DEC_DEUDA,  
    (coalesce(DEC_PACTADO,0) - coalesce(DEC_PAGADO,0)) - coalesce(deuda_empleador,0) +   
     ROUND((CASE WHEN (INTERESES.INT_REAJUSTE < 0) OR (INTERESES.INT_REAJUSTE IS NULL) THEN 0 ELSE INTERESES.INT_REAJUSTE END) / 100 * ((coalesce(DEC_PACTADO,0) - coalesce(DEC_PAGADO,0)) - coalesce(deuda_empleador,0)), 0) +  
     ROUND((CASE WHEN (INTERESES.INT_INTERES  < 0) OR (INTERESES.INT_INTERES IS NULL ) THEN 0 ELSE INTERESES.INT_INTERES  END) / 100 * ((coalesce(DEC_PACTADO,0) - coalesce(DEC_PAGADO,0)) - coalesce(deuda_empleador,0)), 0) +  
     ROUND((CASE WHEN (INTERESES.INT_RECARGO < 0)  OR (INTERESES.INT_RECARGO IS NULL)  THEN 0 ELSE INTERESES.INT_RECARGO END)  / 100 * ((coalesce(DEC_PACTADO,0) - coalesce(DEC_PAGADO,0)) - coalesce(deuda_empleador,0)), 0)   
    AS DEUDA_REAJUSTADA  
   FROM DEUDA_COTIZANTE DC with (nolock)  
    LEFT JOIN #deuda_cotiz_empl D   
     ON DC.COT_RUT=D.COT_RUT AND DC.DEC_PERIODO=D.DEC_PERIODO AND DC.EPA_RUT IS NULL  
    LEFT JOIN INTERESES (NOLOCK) ON INTERESES.INT_PPC_PERIODO = DC.DEC_PERIODO AND INTERESES.INT_FECHA_PAGO = CONVERT(CHAR(8), GETDATE(),112)  
   WHERE (coalesce(DEC_PACTADO,0) - coalesce(DEC_PAGADO,0)) - coalesce(deuda_empleador,0) >0  
  
   CREATE INDEX ix_TMP_DEUDA_COTIZANTE ON #TMP_DEUDA_COTIZANTE(DEC_RUT)  
 END   
  
  
 --3.--#origen_cotiz_empl: TABLA_ORIGEN1: rut con deuda de cotizaciones  
 SELECT   
  d.dec_rut AS rut,  
  SUM(ISNULL(d.dec_deuda, 0)) AS deuda,  
  SUM(CASE WHEN d.dec_tipo_deuda = 'DNP' THEN 1 ELSE 0 END) AS dnp,  
  SUM(CASE WHEN d.dec_tipo_deuda = 'DPP' THEN 1 ELSE 0 END) AS dpp,  
  SUM(CASE WHEN d.dec_tipo_deuda = 'IP' THEN 1 ELSE 0 END) AS ip,  
  MIN(d.dec_periodo) AS menor_per_deuda,  
  MAX(d.dec_periodo) AS mayor_per_deuda,   
  MAX(D.tipo_empresa) as tipo_empresa  
 INTO #origen_cotiz_empl  
 FROM #TMP_DEUDA_COTIZANTE d  
 GROUP BY d.dec_rut  
  
 create nonclustered index ix_origen_cotiz_empl_rut on #origen_cotiz_empl (rut) 