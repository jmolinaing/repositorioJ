
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


-- DIRECCIÓN
--(777120 rows affected) 1 min
--(779138 rows affected)
select cto_rut, ctd_direccion, cmn_codigo, count(*) as contador
, (select max(d.ctd_correl) from CONTACTO_DET d with (nolock) where d.cto_rut = c.cto_rut and d.ctd_direccion = c.ctd_direccion and isnull(d.cmn_codigo, 0) = isnull(c.cmn_codigo, 0)) ctd_correl
from CONTACTO_DET c with (nolock)
where ctd_direccion is not null
and ltrim(rtrim(ctd_direccion)) <> ''
group by cto_rut, ctd_direccion, cmn_codigo
order by cto_rut, ctd_direccion 



-- EMAIL1
--(634445 rows affected) 1 min
select cto_rut, ctd_email1, count(*) as contador
, (select max(d.ctd_correl) from CONTACTO_DET d with (nolock) where d.cto_rut = c.cto_rut and d.ctd_email1 = c.ctd_email1 ) ctd_correl
from CONTACTO_DET c with (nolock)
where ctd_email1 is not null
and ltrim(rtrim(ctd_email1)) <> ''
group by cto_rut, ctd_email1
order by cto_rut, ctd_email1 


-- EMAIL2
--(634445 rows affected) 1 min
select cto_rut, ctd_email2, count(*) as contador
, (select max(d.ctd_correl) from CONTACTO_DET d with (nolock) where d.cto_rut = c.cto_rut and d.ctd_email2 = c.ctd_email2 ) ctd_correl
from CONTACTO_DET c with (nolock)
where ctd_email2 is not null
and ltrim(rtrim(ctd_email2)) <> ''
group by cto_rut, ctd_email2
order by cto_rut, ctd_email2 

-- EMAIL TOTAL
--(634445 rows affected) 1min
select cto_rut, ctd_email1, contador, ctd_correl
from
(
	select cto_rut, ctd_email1, count(*) as contador
	, (select max(d.ctd_correl) from CONTACTO_DET d with (nolock) where d.cto_rut = c.cto_rut and d.ctd_email1 = c.ctd_email1 ) ctd_correl
	from CONTACTO_DET c with (nolock)
	where ctd_email1 is not null
	and ltrim(rtrim(ctd_email1)) <> ''
	group by cto_rut, ctd_email1
	--order by cto_rut, ctd_email1 
	UNION
	select cto_rut, ctd_email2, count(*) as contador
	, (select max(d.ctd_correl) from CONTACTO_DET d with (nolock) where d.cto_rut = c.cto_rut and d.ctd_email2 = c.ctd_email2 ) ctd_correl
	from CONTACTO_DET c with (nolock)
	where ctd_email2 is not null
	and ltrim(rtrim(ctd_email2)) <> ''
	group by cto_rut, ctd_email2
	--order by cto_rut, ctd_email2 
) a






-- FONO1
--(627387 rows affected) 1 min
select cto_rut, ctd_fono1, count(*) as contador
, (select max(d.ctd_correl) from CONTACTO_DET d with (nolock) where d.cto_rut = c.cto_rut and d.ctd_fono1 = c.ctd_fono1 ) ctd_correl
from CONTACTO_DET c with (nolock)
where ctd_fono1 is not null
and ltrim(rtrim(ctd_fono1)) <> ''
group by cto_rut, ctd_fono1
order by cto_rut, ctd_fono1 


-- FONO2
--(426957 rows affected)
select cto_rut, ctd_fono2, count(*) as contador
, (select max(d.ctd_correl) from CONTACTO_DET d with (nolock) where d.cto_rut = c.cto_rut and d.ctd_fono2 = c.ctd_fono2 ) ctd_correl
from CONTACTO_DET c with (nolock)
where ctd_fono2 is not null
and ltrim(rtrim(ctd_fono2)) <> ''
group by cto_rut, ctd_fono2
order by cto_rut, ctd_fono2 

--V1
--(1041940 rows affected) 1:12 min, con contador
--(1037491 rows affected) 1:03 min, sin contador
select cto_rut, ctd_fono1--, contador
, ctd_correl
from
(
	-- FONO1
	--(627387 rows affected) 1 min
	select cto_rut, ctd_fono1--, count(*) as contador
	, (select max(d.ctd_correl) from CONTACTO_DET d with (nolock) where d.cto_rut = c.cto_rut and d.ctd_fono1 = c.ctd_fono1 ) ctd_correl
	from CONTACTO_DET c with (nolock)
	where ctd_fono1 is not null
	and ltrim(rtrim(ctd_fono1)) <> ''
	group by cto_rut, ctd_fono1
	--order by cto_rut, ctd_fono1 
	UNION
	-- FONO2
	--(426957 rows affected)
	select cto_rut, ctd_fono2--, count(*) as contador
	, (select max(d.ctd_correl) from CONTACTO_DET d with (nolock) where d.cto_rut = c.cto_rut and d.ctd_fono2 = c.ctd_fono2 ) ctd_correl
	from CONTACTO_DET c with (nolock)
	where ctd_fono2 is not null
	and ltrim(rtrim(ctd_fono2)) <> ''
	group by cto_rut, ctd_fono2
	--order by cto_rut, ctd_fono2 
) a
order by cto_rut, ctd_fono1 





--V2
--(1041940 rows affected) 1:12 min, con contador
--(1037491 rows affected) 1:03 min, sin contador
--(929965 rows affected)
select cto_rut, ctd_fono1--, contador
--, ctd_correl
--, (select max(d.ctd_correl) from CONTACTO_DET d with (nolock) where d.cto_rut = a.cto_rut and d.ctd_fono1 = a.ctd_fono1 ) ctd_correl
, COALESCE((select max(d.ctd_correl) from CONTACTO_DET d with (nolock) where d.cto_rut = a.cto_rut and d.ctd_fono1 = a.ctd_fono1 and d.ctd_fono1 is not null), (select max(d.ctd_correl) from CONTACTO_DET d with (nolock) where d.cto_rut = a.cto_rut and d.ctd_fono2 = a.ctd_fono1 and d.ctd_fono2 is not null), 99999999)  as ctd_correl

from
(
	-- FONO1
	--(627387 rows affected) 1 min
	select cto_rut, ctd_fono1--, count(*) as contador
	--, (select max(d.ctd_correl) from CONTACTO_DET d with (nolock) where d.cto_rut = c.cto_rut and d.ctd_fono1 = c.ctd_fono1 ) ctd_correl
	from CONTACTO_DET c with (nolock)
	where ctd_fono1 is not null
	and ltrim(rtrim(ctd_fono1)) <> ''
	group by cto_rut, ctd_fono1
	--order by cto_rut, ctd_fono1 
	UNION
	-- FONO2
	--(426957 rows affected)
	select cto_rut, ctd_fono2--, count(*) as contador
	--, (select max(d.ctd_correl) from CONTACTO_DET d with (nolock) where d.cto_rut = c.cto_rut and d.ctd_fono2 = c.ctd_fono2 ) ctd_correl
	from CONTACTO_DET c with (nolock)
	where ctd_fono2 is not null
	and ltrim(rtrim(ctd_fono2)) <> ''
	group by cto_rut, ctd_fono2
	--order by cto_rut, ctd_fono2 
) a
order by cto_rut, ctd_fono1 






end