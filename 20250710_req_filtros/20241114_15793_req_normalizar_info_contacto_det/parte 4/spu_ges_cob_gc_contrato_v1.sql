-- =============================================  
-- Author:  Marcelo Sanhueza  
-- Create date: 18-08-2021  
-- Description: Datos del contrato para ventana de gestión de cobro  
/* =======================================================================================*/    
-- Modificado por: Marcelo Sanhueza  
-- Fecha: 03/11/2023  
-- Descripción: Se incorporan 3 columnas al final con los datos del predictor de pago  
/* =======================================================================================*/    

--execute spu_ges_cob_gc_contrato '  28065396', '  28065396'  

CREATE PROCEDURE [dbo].[spu_ges_cob_gc_contrato]   
 @as_rut char(10),  
 @cot_rut char(10) =NULL  
AS  
BEGIN  
 -- SET NOCOUNT ON added to prevent extra result sets from  
 -- interfering with SELECT statements.  
 SET NOCOUNT ON;  
 DECLARE @monto_ult_pag numeric(15),  
  @forma_ult_pag varchar(200)  
  
  
 create table #CHQPROT (CHQ_ESTADO VARCHAR(500),      
   CHQ_FOLIO NUMERIC(20),      
   CHQ_RUT CHAR(10),       
   CHQ_NOMBRE VARCHAR(200),       
   CHQ_FECHADOC DATETIME,       
   CHQ_FECHAVENC DATETIME,       
   CHQ_MONTO NUMERIC(15),   
   CHQ_OBSERV VARCHAR(500))  
  
 --Obtiene los cheques protestados del deudor  
 --insert into #CHQPROT  
 --exec [150.10.10.54].[CONTAWIN_NMV].[DBO].[spu_consulta_cheques_protestados] @as_rut  
  
 --Obtener desde las cajas, el último pago de cotización  
 SELECT TOP 1   
  @monto_ult_pag=sum(RCT_MONTO),   
  @forma_ult_pag=max(COALESCE(F.FPA_DESCRIPCION,'EFECTIVO'))  
 FROM [MIRROR_NT].[AGENCIAS].[DBO].[RENDIC_COTIZACION] R  WITH (NOLOCK)   
 LEFT JOIN DETALLE_PAGO D WITH (NOLOCK) ON R.AGE_CODIGO=D.AGE_CODIGO AND R.ARA_FECHA=D.ARA_FECHA AND R.APE_CORREL=D.APE_CORREL AND R.MOV_CORREL=D.MOV_CORREL  
 LEFT JOIN FORMA_PAGO F WITH (NOLOCK) ON F.FPA_CODIGO=D.FPA_CODIGO  
 WHERE R.EPA_RUT=COALESCE(@cot_rut,@as_rut)  
 group by R.AGE_CODIGO, R.ARA_FECHA, R.APE_CORREL, R.MOV_CORREL  
 ORDER BY R.ARA_FECHA DESC  
  
 IF @cot_rut is not null  
  BEGIN  
   --Obtiene los datos del cotizante (cuando existe)  
   SELECT  C.CON_FOLIO,  
    C.CON_INIVIG,     
    C.CON_FINVIG,     
    EST.ECO_DESCRIP,    
    DEUDOR.DDR_DIRECCION,  
    DEUDOR.DDR_DIRECCION2,  
    DEUDOR.CIU_CODIGO,  
    (SELECT CIU_NOMBRE FROM CIUDAD WITH (NOLOCK)   WHERE CIU_CODIGO = DEUDOR.CIU_CODIGO) AS CIUDAD,  
    DEUDOR.CMN_CODIGO,  
    (SELECT CMN_NOMBRE FROM COMUNA WITH (NOLOCK)  WHERE CMN_CODIGO = DEUDOR.CMN_CODIGO) AS COMUNA,     
    (SELECT PLN_NOMBRE   
       FROM PLAN_CONTRATADO WITH (NOLOCK)   
       WHERE CON_FOLIO = C.CON_FOLIO   
       AND PLC_INIVIG = ( SELECT MAX(P2.PLC_INIVIG)   
             FROM PLAN_CONTRATADO P2 WITH (NOLOCK)  
           WHERE P2.PLC_INIVIG <= CONVERT(CHAR(6),GETDATE(),112)+'01'  
           AND P2.CON_FOLIO = C.CON_FOLIO ) ) AS PLN_NOMBRE,  
    COALESCE((SELECT V.TTR_CODIGO FROM V_TIPO_TRABAJADOR V  WHERE V.COT_RUT = C.COT_RUT), '-') AS TIPO_TRABAJADOR,  
    COALESCE((SELECT T.TTR_DESCRIP FROM V_TIPO_TRABAJADOR V  JOIN TIPO_TRABAJADOR T WITH (NOLOCK)  ON (V.TTR_CODIGO = T.TTR_CODIGO) WHERE V.COT_RUT = C.COT_RUT), '-') AS TTR_CODIGO2,  
    (SELECT TOP 1 FUN_FECISAPRE FROM FUN WHERE FUN.CON_FOLIO=C.CON_FOLIO AND FUN_TIPO='1') AS FECSUSC,  
    (SELECT TOP 1 FUN_FECISAPRE FROM FUN WHERE FUN.CON_FOLIO=C.CON_FOLIO AND FUN_TIPO='2') AS FECTERMINO,  
  
    ' ' AS TIPO_CONTRATO,  
    ' ' AS EST_CONTRATO,  
    convert(varchar(50),(select count(*) from #CHQPROT)) AS NUM_CHEQUE_PROT,  
    dbo.f_formatea_moneda(convert(varchar(50),(select sum(CHQ_MONTO) from #CHQPROT))) AS MTO_CHEQUE_PROT,  
    @monto_ult_pag AS ULT_MTO_PAGO,  
    @forma_ult_pag AS ULT_MED_PAGO,  
    null /*GETDATE()*/ AS FEC_CAR_FUN2,  
    convert(varchar(50),(select count(*) from CASO_AUGE where CASO_AUGE.CON_FOLIO=c.CON_FOLIO AND CAU_FECAPERTURA>=GETDATE() and (CAU_FECCIERRE >= GETDATE() or CAU_FECCIERRE is null))) AS GES_ACTIVO,  
    P.PROBABILIDAD_DE_PAGA,  
    P.PREDICCION_DIAS,  
    P.FECHA_PROCESO  
   FROM CONTRATO C WITH (NOLOCK)   
    LEFT JOIN    ESTADO_CONTRATO EST WITH (NOLOCK)   
       ON C.ECO_CODIGO = EST.ECO_CODIGO    
    LEFT JOIN DEUDOR WITH (NOLOCK) ON C.COT_RUT=DEUDOR.DDR_RUT  
    LEFT JOIN BI_RESULTADOS_MLPGD AS P ON P.TIPO_DEUDOR='AFILIADO'  
        AND P.RUT_DEUDOR=@cot_rut  
        AND P.FECHA_PROCESO=(SELECT MAX(FECHA_PROCESO) FROM BI_RESULTADOS_MLPGD AS P2 WHERE P2.RUT_DEUDOR=P.RUT_DEUDOR AND P2.TIPO_DEUDOR=P.TIPO_DEUDOR)  
   WHERE C.CON_ULTIMO='S'  
    AND C.COT_RUT = @cot_rut  
  END  
 ELSE  
  BEGIN  
   SELECT  NULL AS CON_FOLIO,  
    NULL AS CON_INIVIG,     
    NULL AS CON_FINVIG,     
    NULL AS ECO_DESCRIP,    
    DEUDOR.DDR_DIRECCION AS DDR_DIRECCION,  
    DEUDOR.DDR_DIRECCION2 AS DDR_DIRECCION2,  
    DEUDOR.CIU_CODIGO AS CIU_CODIGO,  
    (SELECT CIU_NOMBRE FROM CIUDAD WITH (NOLOCK)   WHERE CIU_CODIGO = DEUDOR.CIU_CODIGO) AS CIUDAD,  
    DEUDOR.CMN_CODIGO AS CMN_CODIGO,  
    (SELECT CMN_NOMBRE FROM COMUNA WITH (NOLOCK)  WHERE CMN_CODIGO = DEUDOR.CMN_CODIGO) AS COMUNA,     
    NULL AS PLN_NOMBRE,  
    NULL AS TIPO_TRABAJADOR,  
    NULL AS TTR_CODIGO2,  
    NULL AS FECSUSC,  
    NULL AS FECTERMINO,  
    NULL AS TIPO_CONTRATO,  
    NULL AS EST_CONTRATO,  
    convert(varchar(50),(select count(*) from #CHQPROT)) AS NUM_CHEQUE_PROT,  
    dbo.f_formatea_moneda(convert(varchar(50),(select sum(CHQ_MONTO) from #CHQPROT))) AS MTO_CHEQUE_PROT,  
    @monto_ult_pag AS ULT_MTO_PAGO,  
    @forma_ult_pag AS ULT_MED_PAGO,  
    NULL AS FEC_CAR_FUN2,  
    NULL AS GES_ACTIVO,  
    P.PROBABILIDAD_DE_PAGA,  
    P.PREDICCION_DIAS,  
    P.FECHA_PROCESO  
   FROM DEUDOR WITH (NOLOCK)   
    LEFT JOIN BI_RESULTADOS_MLPGD AS P ON P.TIPO_DEUDOR='EMPLEADOR'  
     AND P.RUT_DEUDOR=@as_rut  
     AND P.FECHA_PROCESO=(SELECT MAX(FECHA_PROCESO) FROM BI_RESULTADOS_MLPGD AS P2 WHERE P2.RUT_DEUDOR=P.RUT_DEUDOR AND P2.TIPO_DEUDOR=P.TIPO_DEUDOR)  
   WHERE DEUDOR.DDR_RUT = @as_rut  
  END  
END  