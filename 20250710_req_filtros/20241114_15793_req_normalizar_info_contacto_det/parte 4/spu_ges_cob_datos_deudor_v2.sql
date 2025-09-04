/* =====================================================================================*/  
/* CREADO POR         : Alberto Rozas                          */  
/* FECHA CREACION     : 03-09-2021                                                      */  
/* DESCRIPCION        : Datos del deudor.                        */  
/*                      */  
/* FECHA MODIFICACION : 08-04-2021                                                      */  
/* DESCRIPCION        : Se agrega REJ_FOLIO a la salida del SP spu_ges_cob_consdeuda */  
/* =====================================================================================*/   
-- spu_ges_cob_datos_deudor '  28065396', '  28065396'  



alter PROCEDURE [dbo].[spu_ges_cob_datos_deudor] @ddr_rut CHAR(10), @cot_rut CHAR(10) = null  
AS  
BEGIN   
 SET NOCOUNT ON;  
  
 DECLARE @RC int  
 DECLARE @rut char(10)  
 DECLARE @saldo_exceso numeric(11,0)  
 DECLARE @fecha_hoy datetime  
  
 CREATE TABLE #DEUDA (  
  SEL char(1),  
  COT_RUT char(10),  
  NOM_COTIZANTE varchar(200),  
  EPA_RUT char(10),  
  EPA_RAZON varchar(200),  
  DEC_PERIODO datetime,  
  DEC_TIPO_DEUDA char(10),  
  DEC_NRORESOL  numeric(15),  
  PACTADO numeric(15),  
  PAGADO numeric(15),  
  DEUDANOMINAL numeric(15),  
  REAJUSTE numeric(15),  
  INTERES numeric(15),  
  RECARGO numeric(15),  
  TOTAL_APAGAR numeric(15),  
  COBRADOR varchar(200),   
  FECHA datetime,  
  ANO numeric(5),  
  MES numeric(5),  
  DEUDA_HC numeric(15),  
  DESCTO_DEUDANOMINAL numeric(15),  
  DESCTO_REAJUSTE numeric(15),  
  DESCTO_INTERES numeric(15),  
  DESCTO_RECARGO  numeric(15),  
  FOLIO_FUN_HAB numeric(15) NULL,  
  FECHA_FUN_HAB DATETIME NULL,  
  REJ_FOLIO numeric(15) NULL  
  
 )  
  
 set @fecha_hoy=convert(char(8),getdate(),112)  
  
 insert into #DEUDA  
 exec  spu_ges_cob_consdeuda @ddr_rut, @fecha_hoy, null, @cot_rut  
  
 CREATE TABLE #DESCTO_PER (periodo datetime, tipo_d char(1), d_cot numeric(3))  
  
 INSERT INTO #DESCTO_PER (periodo , tipo_d, d_cot)  
 SELECT DISTINCT DEC_PERIODO, tipo.GCD_TIPODEUDOR, 0  
 FROM #DEUDA, (SELECT GCD_TIPODEUDOR FROM GCO_DCTO_DEUDATOT) AS TIPO  
  
  
 UPDATE #DESCTO_PER  
 SET  d_cot=GCD_PORC_DEUDA  
 from DBO.GCO_DCTO_DEUDATOT p  
 where p.GCD_TIPODEUDOR = #DESCTO_PER.tipo_d  
  AND GCD_MESES_DESDE <= [dbo].[f_cob_antiguedad_deuda] (#DESCTO_PER.periodo, getdate())  
  AND ( GCD_MESES_HASTA >= [dbo].[f_cob_antiguedad_deuda] (#DESCTO_PER.periodo, getdate()) OR GCD_MESES_HASTA IS NULL)  
  
 ALTER TABLE #DEUDA ADD  GDC_TIPODEUDOR CHAR(1) NULL  
  
 UPDATE #DEUDA SET GDC_TIPODEUDOR='E' WHERE COT_RUT <> EPA_RUT  
  
 UPDATE #DEUDA SET GDC_TIPODEUDOR='V'   
 WHERE COT_RUT = EPA_RUT  
 AND GDC_TIPODEUDOR IS NULL  
 AND EXISTS (SELECT *   
   FROM CONTRATO C   
   WHERE C.COT_RUT=#DEUDA.COT_RUT AND   
    (C.CON_INIVIG <= CONVERT(CHAR(6),GETDATE(),112)+'01' ) AND  
    (C.CON_FINVIG >= CONVERT(CHAR(6),GETDATE(),112)+'01' OR C.CON_FINVIG IS NULL)  
   )  
  
 UPDATE #DEUDA SET GDC_TIPODEUDOR='N'   
 WHERE COT_RUT = EPA_RUT  
 AND GDC_TIPODEUDOR IS NULL  
 AND NOT EXISTS (SELECT *   
   FROM CONTRATO C   
   WHERE C.COT_RUT=#DEUDA.COT_RUT AND   
    (C.CON_INIVIG <= CONVERT(CHAR(6),GETDATE(),112)+'01' ) AND  
    (C.CON_FINVIG >= CONVERT(CHAR(6),GETDATE(),112)+'01' OR C.CON_FINVIG IS NULL)  
   )  
  
  
 UPDATE #DEUDA  
 SET DESCTO_DEUDANOMINAL = (COALESCE(DEUDANOMINAL,0) * d_cot / 100 )   
 from #DESCTO_PER d  
 WHERE d.PERIODO=#DEUDA.DEC_PERIODO AND  
  d.tipo_d=#DEUDA.GDC_TIPODEUDOR   
  
  
 EXECUTE @RC = [dbo].[spu_consulta_saldo_actual_exceso] @cot_rut, @saldo_exceso OUTPUT  
  
  
    SELECT DEUDOR.DDR_RUT,  
         DEUDOR.DDR_NOMBRE,  
         DEUDOR.DDR_DIRECCION,  
   DEUDOR.DDR_DIRECCION2,  
   DEUDOR.CIU_CODIGO,  
   (SELECT CIU_NOMBRE FROM CIUDAD WITH (NOLOCK)   WHERE CIU_CODIGO = DEUDOR.CIU_CODIGO) AS CIUDAD,  
   DEUDOR.CMN_CODIGO,  
   (SELECT CMN_NOMBRE FROM COMUNA WITH (NOLOCK)  WHERE CMN_CODIGO = DEUDOR.CMN_CODIGO) AS COMUNA,  
        -- DEUDOR.DDR_TELEFONO, 
		dbo.f_get_datocontacto(@ddr_rut, 'fono') DDR_TELEFONO, 
		--DEUDOR.DDR_EMAIL,  
		dbo.f_get_datocontacto(@ddr_rut, 'email') DDR_EMAIL,
         DEUDOR.DDR_INF_CONTACTO,  
         DEUDOR.DDR_CELULAR,  
   CASE  
    WHEN (SELECT COUNT(*) FROM PERFILES_USUARIO WITH (NOLOCK) WHERE USU_LOGIN = REPLACE(SYSTEM_USER, '_', '') AND PER_CODIGO = 'COBDEUDA_ADMIN') > 0 THEN [dbo].[f_obtener_scoring_contrato] (V.CON_FOLIO)  
    ELSE ''  
   END AS SCORING,  
   coalesce(@saldo_exceso,0) AS SALDO_EXCESOS,  
   coalesce(dbo.f_saldo_disponible(DEUDOR.DDR_RUT, GETDATE(), GETDATE()),0) AS SALDO_EXCEDENTES,  
   coalesce((SELECT SUM(DEUDANOMINAL) from #DEUDA),0) AS SALDO_DEUDA,  
   CASE WHEN (SELECT count(*) from #DEUDA WHERE DESCTO_DEUDANOMINAL > 0)>0 THEN 'S' ELSE 'N' END AS CAMP_CONDONACION,  
   'S' AS PAC_PAT,  
   dbo.f_edad((SELECT TOP 1 BNF_NACTO FROM BENEFICIARIO WITH (NOLOCK) WHERE BNF_RUT = DEUDOR.DDR_RUT), GETDATE()) AS EDAD,  
   V.CON_FOLIO,  
   (select SUM(dtc_monto) from DEVOLUCION_TFU_CUOTA DT WHERE DT.COT_RUT=DEUDOR.DDR_RUT AND AFI_RUT IS NULL) AS DEUDA_TFU  
 FROM DEUDOR WITH (NOLOCK)  
   LEFT JOIN V_ULTIMO_CONTRATO V WITH (NOLOCK) ON V.COT_RUT = DEUDOR.DDR_RUT  
 WHERE  DEUDOR.DDR_RUT = @ddr_rut  
  
END  