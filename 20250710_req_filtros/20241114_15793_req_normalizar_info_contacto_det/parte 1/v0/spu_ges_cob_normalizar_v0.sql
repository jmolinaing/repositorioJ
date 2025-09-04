




/*================================================================================================= 
 CREADO POR         : Jorge Molina                                     
 FECHA CREACION     : 25-04-2024                                                                   
 DESCRIPCION        : Obtiene listado de deudas por rut para poder asignar/reasignar a cobradores  
 --=================================================================================================*/

--GRANT EXECUTE ON [dbo].[spu_ges_cob_normalizar] TO [public]  

--   exec spu_ges_cob_normalizar
-- 786.027 1 min

alter PROCEDURE [dbo].[spu_ges_cob_normalizar]  

AS  
BEGIN  

 SET NOCOUNT ON; 

declare @sql_insert1 nvarchar(max) 
declare @sql_insert2 nvarchar(max) 


--IF OBJECT_ID(N'tempdb..#rutcondeuda', N'U') IS NOT NULL   
--DROP TABLE #rutcondeuda 
----GO 


		--SELECT C.USU_LOGIN AS USU_LOGIN  
		----, IDENTITY(NUMERIC(10), 1,1) CLAVE_USU  
		--INTO #USUARIO_ASIGNADOS  
		--FROM DBO.CONTRALORIA_ASIG_USUARIO C WITH (NOLOCK)  


	--CREATE TABLE #CORREL (
	--	CORRELATIVO NUMERIC(10)
	--)

	----BEGIN TRAN COMPIN


	----BEGIN TRY
	--		INSERT INTO #CORREL
	--		EXEC [DBO].spu_nuevo_folio 'BITACORA_COMPIN'
	
	--		SELECT @BCO_CORREL = CORRELATIVO FROM #CORREL




select distinct cto_rut
, ctd_correl
, ctd_email1
from
(

select distinct cto_rut
, ctd_correl
, ctd_email1
from
(
select distinct cto_rut
, ctd_correl
, ctd_email1
from dbo.CONTACTO_DET with (nolock)
where 1 = 1
and ctd_email1 is not null
and ltrim(rtrim(ctd_email1)) <> ''
--order by cto_rut desc, ctd_correl desc
) a

union

select distinct cto_rut
, ctd_correl
, ctd_email2
from
(
select distinct cto_rut
, ctd_correl
, ctd_email2
from dbo.CONTACTO_DET with (nolock)
where 1 = 1
and ctd_email2 is not null
and ltrim(rtrim(ctd_email2)) <> ''
--order by cto_rut desc, ctd_correl desc
) b


) c
order by c.CTO_RUT, c.CTD_CORREL





end