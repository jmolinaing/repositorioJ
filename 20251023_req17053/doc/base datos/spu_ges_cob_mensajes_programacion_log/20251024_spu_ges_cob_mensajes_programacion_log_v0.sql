    
/*=======================================================================================       
TIPO DE OBJETO     : Procedimiento Almacenado                                                                                                                                           
NOMBRE DEL OBJETO  : spu_ges_cob_mensajes_programacion_log                                                                                                             
PARAMETROS         : @epl_codigo: código plantilla    
 RETORNO            : Listado de logs de programaciones.           
 CREADO POR         : Jorge Molina                  
 FECHA CREACIÓN     : 24/10/2025                                                               
 DESCRIPCIÓN        : Listado de logs de programaciones.     
========================================================================================*/      

--GRANT EXECUTE ON [spu_ges_cob_mensajes_programacion_log] TO public;        
--EXECUTE spu_ges_cob_mensajes_programacion_log '1'      

CREATE PROCEDURE [dbo].[spu_ges_cob_mensajes_programacion_log]      
(      
@epl_codigo varchar(50) 
, @epr_codigo numeric(10) = null
)      
as      
BEGIN      
	set nocount on;      
       
	SELECT p.epr_descrip
		  ,l.EPL_FECHORA
		  ,l.EPL_TEXTO_ERROR
		  , (select count(*) from dbo.GCO_ENVMSG_MENSAJE m with (nolock) where m.epr_codigo = l.epr_codigo and m.epl_fechora = l.EPL_FECHORA) as total_mensajes
		  , (select count(*) from dbo.GCO_ENVMSG_MENSAJE m with (nolock) where m.epr_codigo = l.epr_codigo and m.epl_fechora = l.EPL_FECHORA and m.EME_ESTADO = 0) as cont_pendenv
		  , (select count(*) from dbo.GCO_ENVMSG_MENSAJE m with (nolock) where m.epr_codigo = l.epr_codigo and m.epl_fechora = l.EPL_FECHORA and m.EME_ESTADO = 1) as cont_enviado
		  , (select count(*) from dbo.GCO_ENVMSG_MENSAJE m with (nolock) where m.epr_codigo = l.epr_codigo and m.epl_fechora = l.EPL_FECHORA and m.EME_ESTADO = 2) as cont_error
		  ,l.EPR_CODIGO
	FROM dbo.GCO_ENVMSG_PROGRAMA_LOG l with (nolock)
	join dbo.GCO_ENVMSG_PROGRAMA p with (nolock)
		  on l.epr_codigo = p.epr_codigo
	where p.epl_codigo = @epl_codigo
	and (p.EPR_CODIGO = @epr_codigo or @epr_codigo is null)
	order by l.epr_codigo, l.epl_fechora desc

END 