
/* ejemplo de espacio que no es espacio
select replace(ctd_email1, ' ', '') from CONTACTO_DET
where cto_rut = ' 175137149'


 01pedrojesus2021@gmail.com

 */

--select * from CONTACTO_DET
--where cto_rut = ' 995993406'


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

--declare @sql_insert1 nvarchar(max) 
--declare @sql_insert2 nvarchar(max) 


--IF OBJECT_ID(N'tempdb..#email', N'U') IS NOT NULL   
--DROP TABLE #email 
--GO 


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




select distinct c.cto_rut
, c.ctd_correl
, c.ctd_email1
, IDENTITY(NUMERIC(10), 1,1) CLAVE  
INTO #email 
from
(

select distinct cto_rut
, ctd_correl
, ctd_email1
from
(
	select distinct cto_rut
	, ctd_correl
	, lower(rtrim(ltrim(ctd_email1))) ctd_email1
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
	, lower(rtrim(ltrim(ctd_email2))) ctd_email2
	from dbo.CONTACTO_DET with (nolock)
	where 1 = 1
	and ctd_email2 is not null
	and ltrim(rtrim(ctd_email2)) <> ''
	--order by cto_rut desc, ctd_correl desc
) b


) c
order by c.CTO_RUT, c.CTD_CORREL


select *
from #email
--join
--(
--select d.cto_rut as cto_rut
--from
--	(
--		select cto_rut, count(*) as cont
--		from #email
--		group by ctO_rut
--		having count(*) > 1
--	) d
--) e
--on e.cto_rut = #email.cto_rut




select cto_rut, ctd_email1, count(*)
from #email
group by cto_rut, ctd_email1
having count(*) > 1



end