  
/*=======================================================================================     
TIPO DE OBJETO     : Procedimiento Almacenado                                                                                                                                         
NOMBRE DEL OBJETO  : spu_ges_cob_mensajes_filtros_consultar                                                                                                           
PARAMETROS         : @vigencia: 'VIGENTE', 'TODAS'  
 RETORNO            : Listado de conceptos y sus filtros.         
 CREADO POR         : Jorge Molina                
 FECHA CREACIÓN     : 01/08/2025                                                             
 DESCRIPCIÓN        : devuelva una estructura con las siguientes columnas:    
      • Codigo Concepto    
      • Nombre Concepto    
      • Codigo Valor    
      • Nombre Valor    
      • Seleccionado (S/N)    
     Utilizar ese SP para armar el Datawindows Treeview de los filtros.    
  
MODIFICACION  : Se agrega columna: GENERAR_CUPON  
FECHA    : 29/12/2025  
MODIF. POR   : Jorge Molina  

MODIFICACION  : Se agrega columna: CUPON_DESCUENTO  
FECHA    : 11/02/2026  
MODIF. POR   : Jorge Molina  
  
========================================================================================*/    
  
/*  
GRANT EXECUTE ON [spu_ges_cob_mensajes_plantillas] TO public;  
  
EXECUTE spu_ges_cob_mensajes_plantillas 'VIGENTES'  
EXECUTE spu_ges_cob_mensajes_plantillas 'TODAS'  
*/  
  
--insert into GCO_ENVMSG_PLANTILLA values (2, 'planilla 2', 'N')  
  
  
    
ALTER PROCEDURE [dbo].[spu_ges_cob_mensajes_plantillas]   
(    
@vigencia varchar(10)      
)    
as    
BEGIN    
 set nocount on;    
    
 DECLARE @FECHA_HOY DATETIME  
 declare @ID INT      
 declare @ECO_CODIGO numeric(5, 0)  -- código concepto    
 declare @EFI_VALOR nvarchar(4000)  -- Valores de filtros agrupados concatenados con '|'  
  
SELECT @FECHA_HOY = CAST(GETDATE() AS DATE)  
  
  
--PROGRAMAS TIPO_ENVIO: Unico  
SELECT G.EPR_CODIGO, G.EPL_CODIGO, G.EPR_TIPO_ENVIO, G.EPR_INIVIG_ENVIO, G.EPR_FINVIG_ENVIO   
INTO #PROGRAMA_TIPO_U  
FROM DBO.GCO_ENVMSG_PROGRAMA G WITH (NOLOCK)  
JOIN GCO_ENVMSG_PLANTILLA P with (nolock)  
 ON G.EPL_CODIGO = P.EPL_CODIGO  
WHERE   
(  
(P.EPL_VIGENTE = 'S' AND @vigencia = 'VIGENTES')  
OR @vigencia = 'TODAS'  
)  
AND EPR_TIPO_ENVIO = 'U'  
AND EPR_FINVIG_ENVIO IS NULL  
AND EPR_INIVIG_ENVIO >= @FECHA_HOY  
  
  
--SELECT * FROM #PROGRAMA_TIPO_U  
  
  
SELECT EPL_CODIGO as CODIGO,     
         EPL_NOMBRE AS NOMBRE,     
         CASE EPL_VIGENTE WHEN 'S' THEN 'Si' ELSE 'No' END AS HABILITADA  
   , CASE WHEN (SELECT COUNT(*) FROM #PROGRAMA_TIPO_U U WHERE U.EPL_CODIGO = P.EPL_CODIGO ) > 0 THEN 'Si' ELSE 'No' END AS PROGR_VIG  
   , CASE EPL_CUPON WHEN 'S' THEN 'Si' ELSE 'No' END AS GENERAR_CUPON
   , CASE EPL_DESCUENTOS WHEN 'S' THEN 'Si' ELSE 'No' END AS CUPON_DESCUENTO   
  FROM GCO_ENVMSG_PLANTILLA P with (nolock)  
WHERE   
(  
(EPL_VIGENTE = 'S' AND @vigencia = 'VIGENTES')  
OR @vigencia = 'TODAS'  
)  
    
  
END    