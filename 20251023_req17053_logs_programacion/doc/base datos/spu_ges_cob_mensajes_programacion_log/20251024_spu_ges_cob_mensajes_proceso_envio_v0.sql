    
/*=======================================================================================       
TIPO DE OBJETO     : Procedimiento Almacenado                                                                                                                                           
NOMBRE DEL OBJETO  : spu_ges_cob_mensajes_proceso_envio                                                                                                            
PARAMETROS         : @epl_codigo: código plantilla    
 RETORNO            : Listado de logs de programaciones.           
 CREADO POR         : Jorge Molina                  
 FECHA CREACIÓN     : 24/10/2025                                                               
 DESCRIPCIÓN        : Listado de proceso de envíos de la GCO_ENVMSG_MENSAJE, para ser exportados 
					se complemneta con los datos de cobrador y api template.
========================================================================================*/      

--GRANT EXECUTE ON [spu_ges_cob_mensajes_proceso_envio] TO public;        
--EXECUTE spu_ges_cob_mensajes_proceso_envio '1' , 10    
      
CREATE PROCEDURE [dbo].[spu_ges_cob_mensajes_proceso_envio]      
(      
@epr_codigo numeric(10)
, @EPL_FECHORA datetime 
)      
as      
BEGIN      
	set nocount on;      
       

SELECT EME_CODIGO
      ,m.ATE_CODIGO as ATE_CODIGO
      ,EME_FECHAREG
      ,EME_FECENVIO
      ,EME_ESTADO
	  , case EME_ESTADO when 0 then 'Pendiente de envío' when 1 then 'Enviado' when 2 then 'Error' else '-' end EME_ESTADO_DESCRIP
      ,RUT_DEUDOR
      ,EME_NOMBRE_DEUDOR
      ,EME_EMAIL_DEUDOR
      ,EME_FONO_DEUDOR
      ,EME_DEUDA_COTIZ
      ,EME_DEUDA_LUR
      ,EME_DEUDA_CHQ
      ,EME_DESCRIP_ENVIO
      ,EME_LINK_CUPON
      ,EPR_CODIGO
      ,EPL_FECHORA
      , M.COB_CODIGO AS COB_CODIGO
	  , COB_NOMBRE
	  , COB_FONO
	  , COB_EMAIL
	  , ATE_CODIGO_API
	  , ATE_DESCRIPCION
  FROM dbo.GCO_ENVMSG_MENSAJE m WITH (NOLOCK)
LEFT JOIN DBO.COBRADOR C WITH (NOLOCK)
	ON C.COB_CODIGO = M.COB_CODIGO
LEFT JOIN DBO.GCO_ENVMSG_API_TEMPLATE T WITH (NOLOCK)
	ON T.ATE_CODIGO = M.ATE_CODIGO
WHERE M.EPR_CODIGO = @epr_codigo
AND M.EPL_FECHORA = @EPL_FECHORA



END 