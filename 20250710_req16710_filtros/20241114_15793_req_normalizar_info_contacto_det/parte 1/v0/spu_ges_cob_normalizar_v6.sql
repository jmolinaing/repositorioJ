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
	--		EXEC DBO.spu_nuevo_folio 'BITACORA_COMPIN'
	--		SELECT @BCO_CORREL = CORRELATIVO FROM #CORREL

--select distinct c.cto_rut
--, c.ctd_correl
--, c.ctd_email1
--, IDENTITY(NUMERIC(10), 1,1) CLAVE  
--INTO #email 
--from
--(



/*================================================================================================= 
 CREADO POR         : Jorge Molina                                     
 FECHA CREACION     : 11-2024                                                                   
 DESCRIPCION        : Obtiene listado 
 --=================================================================================================*/

--GRANT EXECUTE ON dbo.spu_ges_cob_normalizar TO public  

--   exec spu_ges_cob_normalizar
--779.138 + 634.445 + 929.965 = 2.343.548  4 min
-- 2.048.028 7:35 MIN
-- 2.343.548 9:20 MIN

alter PROCEDURE dbo.spu_ges_cob_normalizar  

AS  
BEGIN  

SET NOCOUNT ON; 

IF OBJECT_ID(N'tempdb..#direccion', N'U') IS NOT NULL DROP TABLE #direccion
IF OBJECT_ID(N'tempdb..#email', N'U') IS NOT NULL DROP TABLE #email
IF OBJECT_ID(N'tempdb..#fono', N'U') IS NOT NULL DROP TABLE #fono


DECLARE @CTO_RUT  char(10)
DECLARE @CLAVE NUMERIC(10)
DECLARE @CTD_CORREL NUMERIC(10)
DECLARE @CTO_RUTX  char(10)



CREATE TABLE #CONTACTO_DET_NEW
(
	CTO_RUT char(10)  NOT NULL,
	CTD_CORREL numeric(4, 0)  NULL,
	CTD_DIRECCION varchar(250) NULL,
	CMN_CODIGO numeric(4, 0) NULL,
	CTD_EMAIL1 varchar(250) NULL,
	CTD_EMAIL2 varchar(250) NULL,
	CTD_FONO1 varchar(50) NULL,
	CTD_FONO2 varchar(50) NULL,
	CTD_ENCAR_REM varchar(250) NULL,
	USU_LOGIN char(30)  NULL,
	CTD_FECREG datetime  NULL,
	CTD_ORIGEN varchar(50)  NULL,
	CTD_INF_CONTACTO varchar(250) NULL
	, CLAVE NUMERIC(10) IDENTITY(1,1) --PRIMARY KEY
,
PRIMARY KEY (CTO_RUT, CLAVE)
)
--CREATE CLUSTERED INDEX IX_CC1 ON #CONTACTO_DET_NEW (CTO_RUT);


/*
----1.- DIRECCIÓN v1
--(777120 rows affected) 1 min
--(779138 rows affected)
select cto_rut, ctd_direccion, cmn_codigo--, count(*) as contador
, (select max(d.ctd_correl) from CONTACTO_DET d with (nolock) where d.cto_rut = c.cto_rut and d.ctd_direccion = c.ctd_direccion and isnull(d.cmn_codigo, 0) = isnull(c.cmn_codigo, 0)) ctd_correl
INTO #direccion
from CONTACTO_DET c with (nolock)
where ctd_direccion is not null
and ltrim(rtrim(ctd_direccion)) <> ''
group by cto_rut, ctd_direccion, cmn_codigo
order by cto_rut, ctd_direccion 


------v2
--insert into #CONTACTO_DET_NEW 
--(
--	CTO_RUT, -- char(10)  NULL,
--	CTD_CORREL, -- numeric(4, 0)  NULL,
--	CTD_DIRECCION, -- varchar(250) NULL,
--	CMN_CODIGO, -- numeric(4, 0) NULL,
--	CTD_EMAIL1, -- varchar(250) NULL,
--	CTD_EMAIL2, -- varchar(250) NULL,
--	CTD_FONO1, -- varchar(50) NULL,
--	CTD_FONO2, -- varchar(50) NULL,
--	CTD_ENCAR_REM, -- varchar(250) NULL,
--	USU_LOGIN, -- char(30)  NULL,
--	CTD_FECREG, -- datetime  NULL,
--	CTD_ORIGEN, -- varchar(50)  NULL,
--	CTD_INF_CONTACTO -- varchar(250) NULL
--)
--select d.CTO_RUT
--	, null
--	, d.ctd_direccion
--	, d.cmn_codigo
--	, null --, c.CTD_EMAIL1
--	, null --, c.CTD_EMAIL2
--	, null --, c.CTD_FONO1
--	, null --, c.CTD_FONO2
--	, c.CTD_ENCAR_REM
--	, c.USU_LOGIN
--	, c.CTD_FECREG
--	, c.CTD_ORIGEN
--	, c.CTD_INF_CONTACTO
--from CONTACTO_DET c
--JOIN
--(
--select cto_rut
--, ctd_direccion
--, cmn_codigo--, count(*) as contador
--, (select max(d.ctd_correl) from CONTACTO_DET d with (nolock) where d.cto_rut = c.cto_rut and d.ctd_direccion = c.ctd_direccion and isnull(d.cmn_codigo, 0) = isnull(c.cmn_codigo, 0)) ctd_correl
----INTO #direccion
--from CONTACTO_DET c with (nolock)
--where ctd_direccion is not null
--and ltrim(rtrim(ctd_direccion)) <> ''
--group by cto_rut, ctd_direccion, cmn_codigo
----order by cto_rut, ctd_direccion 
--) D

--	on D.cto_rut = c.cto_rut
--	and D.ctd_correl = c.ctd_correl














--2.-EMAIL TOTAL v1
--(634445 rows affected) 1min
select cto_rut, ctd_email1
, COALESCE((select max(d.ctd_correl) from CONTACTO_DET d with (nolock) where d.cto_rut = a.cto_rut and d.ctd_email1 = a.ctd_email1 ), (select max(d.ctd_correl) from CONTACTO_DET d with (nolock) where d.cto_rut = a.cto_rut and d.ctd_email2 = a.ctd_email1 ))  as ctd_correl
INTO #EMAIL
from
(
	select cto_rut, ctd_email1
	--, count(*) as contador
	--, (select max(d.ctd_correl) from CONTACTO_DET d with (nolock) where d.cto_rut = c.cto_rut and d.ctd_email1 = c.ctd_email1 ) ctd_correl
	from CONTACTO_DET c with (nolock)
	where ctd_email1 is not null
	and ltrim(rtrim(ctd_email1)) <> ''
	group by cto_rut, ctd_email1
	--order by cto_rut, ctd_email1 
	UNION
	select cto_rut, ctd_email2
	--, count(*) as contador
	--, (select max(d.ctd_correl) from CONTACTO_DET d with (nolock) where d.cto_rut = c.cto_rut and d.ctd_email2 = c.ctd_email2 ) ctd_correl
	from CONTACTO_DET c with (nolock)
	where ctd_email2 is not null
	and ltrim(rtrim(ctd_email2)) <> ''
	group by cto_rut, ctd_email2
	--order by cto_rut, ctd_email2 
) a
order by cto_rut, ctd_email1 


*/


--3.- FONO V2
--(1041940 rows affected) 1:12 min, con contador
--(1037491 rows affected) 1:03 min, sin contador
--(929965 rows affected)
select cto_rut, ctd_fono1--, contador
--, ctd_correl
--, (select max(d.ctd_correl) from CONTACTO_DET d with (nolock) where d.cto_rut = a.cto_rut and d.ctd_fono1 = a.ctd_fono1 ) ctd_correl
, COALESCE((select max(d.ctd_correl) from CONTACTO_DET d with (nolock) where d.cto_rut = a.cto_rut and d.ctd_fono1 = a.ctd_fono1 and d.ctd_fono1 is not null), (select max(d.ctd_correl) from CONTACTO_DET d with (nolock) where d.cto_rut = a.cto_rut and d.ctd_fono2 = a.ctd_fono1 and d.ctd_fono2 is not null), 99999999)  as ctd_correl
, IDENTITY(NUMERIC(10), 1,1) CLAVE -- colocamos clave ya que existian un registro con dos numeros y un mismo ctd_correl
into #fono
from
(
	-- FONO1
	--(627387 rows affected) 1 min
	select cto_rut, ctd_fono1--, count(*) as contador
	--, (select max(d.ctd_correl) from CONTACTO_DET d with (nolock) where d.cto_rut = c.cto_rut and d.ctd_fono1 = c.ctd_fono1 ) ctd_correl
	from CONTACTO_DET c with (nolock)
	where ctd_fono1 is not null
	and ltrim(rtrim(ctd_fono1)) <> ''
	and ltrim(rtrim(ctd_fono1)) <> '0'
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
	and ltrim(rtrim(ctd_fono2)) <> '0'
	group by cto_rut, ctd_fono2
	--order by cto_rut, ctd_fono2 
) a
order by cto_rut, ctd_fono1 


UPDATE a
set ctd_fono1 = 
(
case when ((isnumeric(  
replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(  
ltrim(rtrim(b.ctd_fono1))  
, '-', ''), '+', ''), '*', ''), '/', ''), '.', ''), ',', ''), ' ', ''), '$', ''), '^', ''), '%', ''), '=', ''), '<', ''), '>', ''), '[', ''), ']', ''), '{', ''), '}', ''), '@', ''), ' ', ''), '(', ''), ')', '')  
) = 1 )  

) then   
  
replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(  
ltrim(rtrim(b.ctd_fono1))  
, '-', ''), '+', ''), '*', ''), '/', ''), '.', ''), ',', ''), ' ', ''), '$', ''), '^', ''), '%', ''), '=', ''), '<', ''), '>', ''), '[', ''), ']', ''), '{', ''), '}', ''), '@', ''), ' ', ''), '(', ''), ')', '')    

else null end


)
FROM #fono as a
join #fono as b 
	on a.cto_rut = b.cto_rut 
	and a.ctd_correl = b.ctd_correl
	and a.clave = b.clave




UPDATE a
set ctd_fono1 = (CASE WHEN LEFT(b.ctd_fono1, 1) = '0' THEN SUBSTRING(b.ctd_fono1, 2, LEN(b.ctd_fono1) - 1)  ELSE b.ctd_fono1   END)
FROM #fono as a
join #fono as b 
	on a.cto_rut = b.cto_rut 
	and a.ctd_correl = b.ctd_correl
	and a.clave = b.clave
where LEFT(b.ctd_fono1, 1) = '0'

delete #fono where ctd_fono1 is null






--select * from #direccion
--select * from #EMAIL
--select * from #fono

/*
--1.- DIRECCION
insert into #CONTACTO_DET_NEW 
(
	CTO_RUT, -- char(10)  NULL,
	CTD_CORREL, -- numeric(4, 0)  NULL,
	CTD_DIRECCION, -- varchar(250) NULL,
	CMN_CODIGO, -- numeric(4, 0) NULL,
	CTD_EMAIL1, -- varchar(250) NULL,
	CTD_EMAIL2, -- varchar(250) NULL,
	CTD_FONO1, -- varchar(50) NULL,
	CTD_FONO2, -- varchar(50) NULL,
	CTD_ENCAR_REM, -- varchar(250) NULL,
	USU_LOGIN, -- char(30)  NULL,
	CTD_FECREG, -- datetime  NULL,
	CTD_ORIGEN, -- varchar(50)  NULL,
	CTD_INF_CONTACTO -- varchar(250) NULL
)
select d.CTO_RUT
	, null
	, d.ctd_direccion
	, d.cmn_codigo
	, null --, c.CTD_EMAIL1
	, null --, c.CTD_EMAIL2
	, null --, c.CTD_FONO1
	, null --, c.CTD_FONO2
	, c.CTD_ENCAR_REM
	, c.USU_LOGIN
	, c.CTD_FECREG
	, c.CTD_ORIGEN
	, c.CTD_INF_CONTACTO
from #direccion d
join CONTACTO_DET c
	on d.cto_rut = c.cto_rut
	and d.ctd_correl = c.ctd_correl


--EMAIL
insert into #CONTACTO_DET_NEW 
(
	CTO_RUT, -- char(10)  NULL,
	CTD_CORREL, -- numeric(4, 0)  NULL,
	CTD_DIRECCION, -- varchar(250) NULL,
	CMN_CODIGO, -- numeric(4, 0) NULL,
	CTD_EMAIL1, -- varchar(250) NULL,
	CTD_EMAIL2, -- varchar(250) NULL,
	CTD_FONO1, -- varchar(50) NULL,
	CTD_FONO2, -- varchar(50) NULL,
	CTD_ENCAR_REM, -- varchar(250) NULL,
	USU_LOGIN, -- char(30)  NULL,
	CTD_FECREG, -- datetime  NULL,
	CTD_ORIGEN, -- varchar(50)  NULL,
	CTD_INF_CONTACTO -- varchar(250) NULL
)
select d.CTO_RUT
	, null
	, null --, d.ctd_direccion
	, null --, d.cmn_codigo
	, d.CTD_EMAIL1
	, null --, c.CTD_EMAIL2
	, null --, c.CTD_FONO1
	, null --, c.CTD_FONO2
	, c.CTD_ENCAR_REM
	, c.USU_LOGIN
	, c.CTD_FECREG
	, c.CTD_ORIGEN
	, c.CTD_INF_CONTACTO
from #EMAIL d
join CONTACTO_DET c
	on d.cto_rut = c.cto_rut
	and d.ctd_correl = c.ctd_correl


*/
--FONO
insert into #CONTACTO_DET_NEW 
(
	CTO_RUT, -- char(10)  NULL,
	CTD_CORREL, -- numeric(4, 0)  NULL,
	CTD_DIRECCION, -- varchar(250) NULL,
	CMN_CODIGO, -- numeric(4, 0) NULL,
	CTD_EMAIL1, -- varchar(250) NULL,
	CTD_EMAIL2, -- varchar(250) NULL,
	CTD_FONO1, -- varchar(50) NULL,
	CTD_FONO2, -- varchar(50) NULL,
	CTD_ENCAR_REM, -- varchar(250) NULL,
	USU_LOGIN, -- char(30)  NULL,
	CTD_FECREG, -- datetime  NULL,
	CTD_ORIGEN, -- varchar(50)  NULL,
	CTD_INF_CONTACTO -- varchar(250) NULL
)
select d.CTO_RUT
	, null
	, null --, d.ctd_direccion
	, null --, d.cmn_codigo
	, null --, c.CTD_EMAIL1
	, null --, c.CTD_EMAIL2
	, D.CTD_FONO1
	, null --, c.CTD_FONO2
	, c.CTD_ENCAR_REM
	, c.USU_LOGIN
	, c.CTD_FECREG
	, c.CTD_ORIGEN
	, c.CTD_INF_CONTACTO
from #fono d
join CONTACTO_DET c
	on d.cto_rut = c.cto_rut
	and d.ctd_correl = c.ctd_correl







				DECLARE CURSOR_TOTAL CURSOR   
				FOR 
					SELECT CTO_RUT
					, CLAVE
					FROM #CONTACTO_DET_NEW
					ORDER BY CTO_RUT ASC, CLAVE ASC

				OPEN CURSOR_TOTAL

				FETCH NEXT FROM CURSOR_TOTAL INTO @CTO_RUT, @CLAVE

				SET @CTD_CORREL = 1
				SET @CTO_RUTX = @CTO_RUT

				WHILE @@FETCH_STATUS = 0
				BEGIN

					--select @CTD_CORREL = isnull(CTD_CORREL, 0) + 1
					--from #CONTACTO_DET_NEW
					--WHERE CTO_RUT = @CTO_RUT
					----AND CLAVE = @CLAVE

					UPDATE #CONTACTO_DET_NEW
					SET CTD_CORREL = @CTD_CORREL
					WHERE CTO_RUT = @CTO_RUT
					AND CLAVE = @CLAVE

					

					FETCH NEXT FROM CURSOR_TOTAL INTO @CTO_RUT, @CLAVE

					if (@CTO_RUTX = @CTO_RUT)
					BEGIN 
						SET @CTD_CORREL = @CTD_CORREL + 1
					END 
					ELse
					begin
						SET @CTO_RUTX = @CTO_RUT
						SET @CTD_CORREL = 1
					end

				END 

				CLOSE CURSOR_TOTAL
				DEALLOCATE CURSOR_TOTAL





if (select count(*) from #CONTACTO_DET_NEW) > 0 
begin
	delete CONTACTO_DET_NEW2
end






insert into CONTACTO_DET_NEW2 
(
	CTO_RUT, -- char(10)  NULL,
	CTD_CORREL, -- numeric(4, 0)  NULL,
	CTD_DIRECCION, -- varchar(250) NULL,
	CMN_CODIGO, -- numeric(4, 0) NULL,
	CTD_EMAIL1, -- varchar(250) NULL,
	CTD_EMAIL2, -- varchar(250) NULL,
	CTD_FONO1, -- varchar(50) NULL,
	CTD_FONO2, -- varchar(50) NULL,
	CTD_ENCAR_REM, -- varchar(250) NULL,
	USU_LOGIN, -- char(30)  NULL,
	CTD_FECREG, -- datetime  NULL,
	CTD_ORIGEN, -- varchar(50)  NULL,
	CTD_INF_CONTACTO -- varchar(250) NULL
)

SELECT CTO_RUT, -- char(10)  NULL,
	CTD_CORREL, -- numeric(4, 0)  NULL,
	CTD_DIRECCION, -- varchar(250) NULL,
	CMN_CODIGO, -- numeric(4, 0) NULL,
	CTD_EMAIL1, -- varchar(250) NULL,
	CTD_EMAIL2, -- varchar(250) NULL,
	CTD_FONO1, -- varchar(50) NULL,
	CTD_FONO2, -- varchar(50) NULL,
	CTD_ENCAR_REM, -- varchar(250) NULL,
	USU_LOGIN, -- char(30)  NULL,
	CTD_FECREG, -- datetime  NULL,
	CTD_ORIGEN, -- varchar(50)  NULL,
	CTD_INF_CONTACTO 
	from #CONTACTO_DET_NEW



	SELECT * FROM CONTACTO_DET_NEW2





end