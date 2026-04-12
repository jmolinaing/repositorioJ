-- =============================================  
-- Author:  Marcelo Sanhueza   
-- Create date: 20-04-2022  
-- Description: Genera una resolucion juducual a partir de la deuda asignada a un cobrador judicial  
-- =============================================  
-- Modificado Por: Marcelo Sanhueza   
-- Fecha: 29-08-2022  
-- Descripcion: Para la deuda DNP, la desagrega en NP y DNP en caso de existir deuda mixta, ya que en esos casos el spu_ges_cob_consdeuda devuelve un solo registro con el total de la deuda con la marca DNP.  Para el valor preciso se consulta el DNP_SALDO 

--Modificado      : Jorge Molina <jorge.molina@nuevamasvida.cl>  
--fecha           : 30-03-2026  
--Descripción     : Req#17675  
--                  1.- de DEUDA_COTIZANTE, DEC_RUT <> dc.COT_RUT, el rut del deudor debe ser siempre distinto al rut del afiliado
--                     , por que eso nunca debemos considerar.
--                  resumen:   delete from #consdeuda_sp where COT_RUT = EPA_RUT 

-- =============================================  
ALTER PROCEDURE [dbo].[spu_ges_cob_genera_resoljud_deuda]  
 @deu_correl numeric(10) --Id de la deuda asignada para la cual se generará la resolución  
AS  
BEGIN  
 SET NOCOUNT ON;  
-- BEGIN TRY  
  
  DECLARE @epa_rut  CHAR(10),  
   @fec_proceso  DATETIME,  
   @cob_codigo   NUMERIC(4) ,  
   @cob_judicial  char(1),  
   @cot_rut   char(10),  
   @epa_razon   varchar(200),  
   @resol_ant   NUMERIC(15),  
   @cant_reg   NUMERIC(10) ,  
   @rej_folio   NUMERIC(15),  
   @n      NUMERIC(4)   
  
  
  
  CREATE TABLE #consdeuda_sp(  
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
         
  SELECT @epa_rut=DEUDOR_ASIGNADO.DDR_RUT,  
   @cob_codigo=DEUDOR_ASIGNADO.COB_CODIGO,  
   @cob_judicial=COBRADOR.COB_JUDICIAL,  
   @cot_rut=CONTRATO.COT_RUT  
  FROM DEUDOR_ASIGNADO WITH (NOLOCK)  
  JOIN COBRADOR WITH (NOLOCK) ON COBRADOR.COB_CODIGO=DEUDOR_ASIGNADO.COB_CODIGO  
  left join CONTRATO WITH (NOLOCK) on CONTRATO.COT_RUT=DEUDOR_ASIGNADO.DDR_RUT  
  WHERE DEU_CORREL=@deu_correl  
  
  IF @epa_rut IS NULL   
   BEGIN  
    SELECT -1 AS ERROR_CODE, 'Id de deuda no válido' AS ERROR_TEXT  
    RETURN -1                 
   END  
  
  IF coalesce(@cob_judicial,'N') ='N'  
   BEGIN  
    SELECT -1 AS ERROR_CODE, 'Deudor no está asigmado a un estudio juridico.' AS ERROR_TEXT  
    RETURN -1                 
   END  
  
  
  IF @cot_rut IS NOT NULL  
   BEGIN  
    --SELECT -1 AS ERROR_CODE, 'No se permite generar resoluciones para Afiliados/ex Afiliados.' AS ERROR_TEXT  
    SELECT 0 AS ERROR_CODE, '' AS ERR_TEXT    
    RETURN 0  
   END    
  
  
  SET @fec_proceso = CONVERT(CHAR(8), GETDATE(), 112)  
  --SET @fec_proceso = '20211201'  
    
  INSERT INTO #consdeuda_sp  
  EXEC dbo.spu_ges_cob_consdeuda @epa_rut, @fec_proceso  
  
  delete from #consdeuda_sp  
  where DEUDANOMINAL <=0  

  delete from #consdeuda_sp     --Req#17675
  where COT_RUT = EPA_RUT  

  
  ---- Modifica los casos con Multi-empleador (fuerza al RUT del empleador)  
  select TOP 1 @epa_razon = EPA_RAZON FROM #consdeuda_sp WHERE EPA_RUT= @epa_rut  
  UPDATE #consdeuda_sp SET EPA_RUT=@epa_rut, EPA_RAZON=coalesce(@epa_razon,EPA_RAZON)   
  
  -- Descarta los que tienen una Resolución Judicial  
  DELETE  
  FROM #consdeuda_sp  
  WHERE REJ_FOLIO IS NOT NULL  
  
  ------------------------------------------------------------------------------------------  
  --Actualiza los datos con la deuda real del DNP actualizada  
  ------------------------------------------------------------------------------------------  
  ALTER TABLE #consdeuda_sp ADD DNP_DECLARADO NUMERIC(10), DNP_SALDO NUMERIC(10)  
  
    
  update #consdeuda_sp  
  set DNP_DECLARADO=(select sum(DD.DPP_COTIZ_APAGAR) from DNP join  DNP_DETALLE dd on dd.PPC_FOLIO=dnp.PPC_FOLIO where epa_rut =#consdeuda_sp.EPA_RUT and cot_rut =#consdeuda_sp.COT_RUT and dd.PPC_PERIODO=#consdeuda_sp.DEC_PERIODO),  
   DNP_SALDO=(select sum(DD.DDT_SALDO) from DNP join  DNP_DETALLE dd on dd.PPC_FOLIO=dnp.PPC_FOLIO where epa_rut =#consdeuda_sp.EPA_RUT and cot_rut =#consdeuda_sp.COT_RUT and dd.PPC_PERIODO=#consdeuda_sp.DEC_PERIODO)  
  ------------------------------------------------------------------------------------------  
  ------------------------------------------------------------------------------------------  
  
  
  ------------------------------------------------------------------------------------------  
  --Desagrega la deuda en NP y DNP para aquellos casos en que el periodo tiene deuda mixta para un mismo trabajador/empleador  
  ------------------------------------------------------------------------------------------  
  CREATE TABLE #consdeuda(  
     COT_RUT    CHAR(10),  
     EPA_RUT    CHAR(10),  
     EPA_RAZON   VARCHAR(200),  
     DEC_PERIODO   DATETIME,  
     DEC_TIPO_DEUDA  VARCHAR(20),  
     DEUDANOMINAL  NUMERIC(10)  
     )  
  
  insert into #consdeuda(  
     COT_RUT,  
     EPA_RUT,  
     EPA_RAZON,  
     DEC_PERIODO,  
     DEC_TIPO_DEUDA,  
     DEUDANOMINAL  
     )  
  select COT_RUT,  
    EPA_RUT,  
    EPA_RAZON,  
    DEC_PERIODO,  
    'NP',  
    DEUDANOMINAL - coalesce(DNP_DECLARADO,0)  
  from #consdeuda_sp  
  where DEUDANOMINAL - coalesce(DNP_DECLARADO,0) > 0  
  
  
  insert into #consdeuda(  
     COT_RUT,  
     EPA_RUT,  
     EPA_RAZON,  
     DEC_PERIODO,  
     DEC_TIPO_DEUDA,  
     DEUDANOMINAL  
     )  
  select COT_RUT,  
    EPA_RUT,  
    EPA_RAZON,  
    DEC_PERIODO,  
    'DNP',  
    DNP_SALDO  
  from #consdeuda_sp  
  where DNP_SALDO > 0  
  ------------------------------------------------------------------------------------------  
  ------------------------------------------------------------------------------------------  
  
  
  
  CREATE TABLE #resolucion(  
   [REJ_FOLIO] [numeric](10, 0) NOT NULL,  
   [DDR_RUT] [char](10) NOT NULL,   
   [REJ_TIPODEUDA] [varchar](4) NOT NULL,  
   [REJ_FECREG] [datetime] NOT NULL,  
   [REJ_USUREG] [varchar](100) NOT NULL,  
   [REJ_RAZONSOC] [varchar](250) NULL,  
   [REJ_DIRECCION] [varchar](250) NULL,  
   [CMN_CODIGO] [numeric](5, 0) NULL,  
   [REJ_FONO1] [varchar](50) NULL,  
   [REJ_FONO2] [varchar](50) NULL,  
   [REJ_FONO3] [varchar](50) NULL,  
   [REJ_EMAIL] [varchar](50) NULL,  
   [REJ_CTO_RUT] [char](10) NULL,  
   [REJ_CTO_NOM] [varchar](200) NULL,  
   [REJ_CTO_FONO] [varchar](50) NULL,  
   [REJ_CTO_TIPO] [char](1) NULL,  
   [DEU_CORREL] [numeric](10, 0) NULL,  
   [RAC_CODIGO] [numeric](10, 0) NULL  
  )  
  
  
  
  
  CREATE TABLE #deuda(  
   [REJ_FOLIO] [numeric](15, 0) NOT NULL,  
   [COT_RUT] [char](10) NOT NULL,  
   [RJD_PERIODO] [datetime] NOT NULL,  
   [RJD_NOMBRE] [varchar](200)  NULL,  
   [RJD_IMPONIBLE] [numeric](12, 0)  NULL,  
   [RJD_LEGAL] [numeric](12, 0)  NULL,  
   [RJD_ADICIONAL] [numeric](12, 0)  NULL,  
   [RJD_DEUDA] [numeric](15, 0)  
  )  
  
  
  INSERT INTO #resolucion(  
   [REJ_FOLIO],  
   [DDR_RUT],  
   [REJ_TIPODEUDA],  
   [REJ_FECREG],  
   [REJ_USUREG],  
   [REJ_RAZONSOC],  
   [REJ_DIRECCION],  
   [CMN_CODIGO],  
   [REJ_FONO1],  
   [REJ_FONO2],  
   [REJ_FONO3],  
   [REJ_EMAIL],  
   [REJ_CTO_RUT],  
   [REJ_CTO_NOM],  
   [REJ_CTO_FONO],  
   [REJ_CTO_TIPO],  
   [DEU_CORREL]  
   )  
  
  select ROW_NUMBER() over (PARTITION BY '' ORDER BY EPA_RUT) as rej_folio,  
   EPA_RUT,  
   DEC_TIPO_DEUDA,  
   GETDATE(),  
   SYSTEM_USER,  
   MAX(EPA_RAZON),  
   NULL,  
   NULL,  
   NULL,  
   NULL,  
   NULL,  
   NULL,  
   NULL,  
   NULL,  
   NULL,  
   NULL,  
   @deu_correl  
  from #consdeuda  
  group by EPA_RUT,  
   DEC_TIPO_DEUDA  
  
  
  
  INSERT INTO #deuda(  
   [REJ_FOLIO],  
   [COT_RUT],  
   [RJD_PERIODO],  
   [RJD_NOMBRE],  
   [RJD_IMPONIBLE],  
   [RJD_LEGAL],  
   [RJD_ADICIONAL],  
   [RJD_DEUDA]  
  )  
  SELECT R.REJ_FOLIO  
       ,D.COT_RUT  
       ,D.DEC_PERIODO  
       ,COALESCE(C.COT_NOMBRES,'') +' '+ COALESCE(C.COT_PATERNO,'') +' '+ COALESCE(C.COT_MATERNO ,'')  
       ,0  
       ,0  
       ,0  
       ,SUM(D.DEUDANOMINAL)  
  FROM #consdeuda D  
   JOIN #resolucion R ON D.EPA_RUT=R.DDR_RUT AND D.DEC_TIPO_DEUDA=R.REJ_TIPODEUDA  
   JOIN COTIZANTE C WITH (NOLOCK) ON C.COT_RUT = D.COT_RUT  
  GROUP BY  R.REJ_FOLIO  
       ,D.COT_RUT  
       ,D.DEC_PERIODO  
       ,COALESCE(C.COT_NOMBRES,'') +' '+ COALESCE(C.COT_PATERNO,'') +' '+ COALESCE(C.COT_MATERNO ,'')  
  
  update #deuda   
  set RJD_IMPONIBLE= CASE   
   WHEN RJD_DEUDA <= ((parametros.par_valor * uf.uf_valor) )  
    THEN ROUND(RJD_DEUDA / 0.07, 0)  
   ELSE ROUND((parametros.par_valor * uf.uf_valor)  / 0.07, 0)  
   END ,  
   RJD_LEGAL= CASE   
   WHEN RJD_DEUDA <= ((parametros.par_valor * uf.uf_valor) )  
    THEN ROUND(RJD_DEUDA, 0)  
   ELSE ROUND((parametros.par_valor * uf.uf_valor) , 0)  
   END,  
   RJD_ADICIONAL= CASE   
   WHEN RJD_DEUDA > ((parametros.par_valor * uf.uf_valor) )  
    THEN ROUND((RJD_DEUDA - (parametros.par_valor * uf.uf_valor) ), 0)  
   ELSE 0  
   END  
  FROM #deuda D  
   LEFT JOIN parametros  with (nolock) ON D.RJD_PERIODO >= parametros.par_inivig  
     AND (  
      D.RJD_PERIODO <= parametros.par_finvig  
      OR parametros.par_finvig IS NULL  
      )  
     AND parametros.par_codigo = 'TLE'  
   LEFT JOIN uf WITH (NOLOCK) ON uf.uf_fecha = DATEADD(DAY, -1, DATEADD(MONTH, 1, D.RJD_PERIODO))  
  
  
  --Actuializa con los datos de la última resolución anterior  
  SELECT TOP 1 @resol_ant=REJ_FOLIO  
  FROM RESOLUCION_JUDICIAL A1 WITH (NOLOCK)   
  WHERE A1.DDR_RUT=@epa_rut  
  ORDER BY REJ_FOLIO DESC  
  
  
  IF @resol_ant IS NOT NULL   
   BEGIN  
    UPDATE #resolucion  
    SET REJ_DIRECCION = A.REJ_DIRECCION,  
     CMN_CODIGO = A.CMN_CODIGO,  
     REJ_FONO1 = A.REJ_FONO1,  
     REJ_FONO2 = A.REJ_FONO2,  
     REJ_FONO3 = A.REJ_FONO3,  
     REJ_EMAIL = A.REJ_EMAIL,  
     REJ_CTO_RUT = A.REJ_CTO_RUT,  
     REJ_CTO_NOM = A.REJ_CTO_NOM,  
     REJ_CTO_FONO = A.REJ_CTO_FONO,  
     REJ_CTO_TIPO = A.REJ_CTO_TIPO,  
     RAC_CODIGO = A.RAC_CODIGO  
    FROM RESOLUCION_JUDICIAL A WITH (NOLOCK)  
    WHERE A.REJ_FOLIO = @resol_ant  
   END  
  ELSE  
     
   BEGIN  
    --Actuializa preferentemente con oos datos del deudor si existe,, en caso contrario los obtiene desde la entidad pagadora  
    SELECT @n=count(*)  
    FROM DEUDOR  WITH (NOLOCK)  
    WHERE DDR_RUT=@epa_rut  
  
     
    IF @n > 0  
     BEGIN  
      UPDATE #resolucion  
      SET REJ_DIRECCION = D.DDR_DIRECCION,  
       CMN_CODIGO = D.CMN_CODIGO,  
       REJ_FONO1 = D.DDR_CELULAR,  
       REJ_FONO2 = D.DDR_TELEFONO,  
       REJ_EMAIL = D.DDR_EMAIL,  
       REJ_CTO_RUT = D.DDR_RUT_REPR,  
       REJ_CTO_NOM = D.DDR_NOM_REPR,  
       REJ_CTO_TIPO = D.DDR_TIPO_REPR,  
       RAC_CODIGO = D.RAC_CODIGO  
      FROM DEUDOR D WITH (NOLOCK)  
      WHERE D.DDR_RUT = @epa_rut  
     END  
    ELSE  
     BEGIN  
      UPDATE #resolucion  
      SET REJ_DIRECCION = P.EPA_DIRPOSTAL+' '+coalesce(P.EPA_DIRPOSTAL2,''),  
       CMN_CODIGO = P.CMN_CODIGO,  
       REJ_FONO1 = P.EPA_FONO,  
       REJ_FONO2 = NULL,  
       REJ_FONO3 = NULL,  
       REJ_EMAIL = P.EPA_EMAIL,  
       REJ_CTO_RUT = P.REN_RUT,  
       REJ_CTO_NOM = R.REN_NOMBRE,  
       REJ_CTO_FONO = NULL,  
       REJ_CTO_TIPO = case when P.REN_RUT is not null then 'L' else null end,  
       RAC_CODIGO = NULL  
      FROM ENTIDAD_PAGADORA P WITH (NOLOCK) LEFT JOIN REPRESENTANTE_EPA R WITH (NOLOCK) ON P.REN_RUT=R.REN_RUT  
      WHERE P.EPA_RUT=#resolucion.DDR_RUT  
      AND P.EPA_CORREL=(SELECT TOP 1 EPA_CORREL  FROM ENTIDAD_PAGADORA P1 WITH (NOLOCK) WHERE P1.EPA_RUT=P.EPA_RUT)  
     END  
   END  
    
  --Agrega las resoluciones  
  SELECT @cant_reg = COUNT(*)  
        FROM #resolucion    
  
  if @cant_reg>0  
  BEGIN  
    CREATE TABLE #rej_folio (rej_folio NUMERIC(15), rej_folio_fin NUMERIC(15) null)  
      
    INSERT INTO #rej_folio (rej_folio, rej_folio_fin) EXEC spu_nuevo_correl 'REJ',  @cant_reg  
  
    SELECT @rej_folio = rej_folio FROM #rej_folio  
  
    INSERT INTO RESOLUCION_JUDICIAL(  
     REJ_FOLIO,  
     DDR_RUT,  
     REJ_TIPODEUDA,  
     REJ_FECREG,  
     REJ_USUREG,  
     REJ_RAZONSOC,  
     REJ_DIRECCION,  
     CMN_CODIGO,  
     REJ_FONO1,  
     REJ_FONO2,  
     REJ_FONO3,  
     REJ_EMAIL,  
     REJ_CTO_RUT,  
     REJ_CTO_NOM,  
     REJ_CTO_FONO,  
     REJ_CTO_TIPO,  
     DEU_CORREL,  
     RAC_CODIGO,  
     REJ_GESTION  
     )  
    SELECT @rej_folio + REJ_FOLIO,  
     DDR_RUT,  
     REJ_TIPODEUDA,  
     REJ_FECREG,  
     REJ_USUREG,  
     REJ_RAZONSOC,  
     REJ_DIRECCION,  
     CMN_CODIGO,  
     REJ_FONO1,  
     REJ_FONO2,  
     REJ_FONO3,  
     REJ_EMAIL,  
     REJ_CTO_RUT,  
     REJ_CTO_NOM,  
     REJ_CTO_FONO,  
     REJ_CTO_TIPO,  
     DEU_CORREL,  
     RAC_CODIGO,  
     null  
    FROM #resolucion  
  
    INSERT INTO dbo.RJUD_DEUDA  
         (REJ_FOLIO  
         ,COT_RUT  
         ,RJD_PERIODO  
         ,RJD_NOMBRE  
         ,RJD_IMPONIBLE  
         ,RJD_LEGAL  
         ,RJD_ADICIONAL  
         ,RJD_DEUDA)  
    SELECT @rej_folio + REJ_FOLIO,  
      COT_RUT,  
      RJD_PERIODO,  
      RJD_NOMBRE,  
      RJD_IMPONIBLE,  
      RJD_LEGAL,  
      RJD_ADICIONAL,  
      RJD_DEUDA  
    FROM #deuda  
  
      
  END  
  
 --END TRY  
  
 --BEGIN CATCH  
 -- SELECT -2 AS ERROR_CODE, 'Error en la linea ' +convert(varchar(100),ERROR_LINE()) +', '+ ERROR_MESSAGE() AS ERROR_TEXT  
   
 --END CATCH  
 SELECT 0 AS ERROR_CODE, '' AS ERR_TEXT  
END  