
/*================================================================================================= 
 CREADO POR         : Jorge Molina                                     
 FECHA CREACION     : 11-2024                                                                   
 DESCRIPCION        : Obtiene listado 
 --=================================================================================================*/

--GRANT EXECUTE ON dbo.spu_ges_cob_normalizar TO public 
--exec spu_ges_cob_normalizar


--1.708.332 reg   7:19 min
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


--1.- DIRECCIÓN v1
--(779138 rows affected) 1:11 min

select cto_rut, ctd_direccion, cmn_codigo--, count(*) as contador
, (select max(d.ctd_correl) from contacto_det d with (nolock) where d.cto_rut = c.cto_rut and d.ctd_direccion = c.ctd_direccion and isnull(d.cmn_codigo, 0) = isnull(c.cmn_codigo, 0)) ctd_correl
into #direccion
from contacto_det c with (nolock)
where ctd_direccion is not null
and ltrim(rtrim(ctd_direccion)) <> ''
group by cto_rut, ctd_direccion, cmn_codigo
order by cto_rut, ctd_direccion 



--2.-EMAIL  v1
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





--3.- FONO V2
-- (316719 rows affected) 19 seg
select cto_rut, ctd_fono1--, contador
--, ctd_correl
--, (select max(d.ctd_correl) from contacto_det d with (nolock) where d.cto_rut = a.cto_rut and d.ctd_fono1 = a.ctd_fono1 ) ctd_correl
, coalesce((select max(d.ctd_correl) from contacto_det d with (nolock) where d.cto_rut = a.cto_rut and d.ctd_fono1 = a.ctd_fono1 and d.ctd_fono1 is not null), (select max(d.ctd_correl) from contacto_det d with (nolock) where d.cto_rut = a.cto_rut and d.ctd_fono2 = a.ctd_fono1 and d.ctd_fono2 is not null), 99999999)  as ctd_correl
, identity(numeric(10), 1,1) clave -- colocamos clave ya que existian un registro con dos numeros y un mismo ctd_correl
into #fono
from
(
	-- fono1
	--(627387 rows affected) 1 min
	select cto_rut, ctd_fono1--, count(*) as contador
	--, (select max(d.ctd_correl) from contacto_det d with (nolock) where d.cto_rut = c.cto_rut and d.ctd_fono1 = c.ctd_fono1 ) ctd_correl
	from contacto_det c with (nolock)
	where ctd_fono1 is not null
	and ltrim(rtrim(ctd_fono1)) <> ''
	and ltrim(rtrim(ctd_fono1)) <> '0'
	and len(ctd_fono1) > 8
	group by cto_rut, ctd_fono1
	--order by cto_rut, ctd_fono1 
	union
	-- fono2
	--(426957 rows affected)
	select cto_rut, ctd_fono2--, count(*) as contador
	--, (select max(d.ctd_correl) from contacto_det d with (nolock) where d.cto_rut = c.cto_rut and d.ctd_fono2 = c.ctd_fono2 ) ctd_correl
	from contacto_det c with (nolock)
	where ctd_fono2 is not null
	and ltrim(rtrim(ctd_fono2)) <> ''
	and ltrim(rtrim(ctd_fono2)) <> '0'
	and len(ctd_fono2) > 8
	group by cto_rut, ctd_fono2
	--order by cto_rut, ctd_fono2 
) a
order by cto_rut, ctd_fono1 


--Limpiar los fonos con simbolos
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



--Limpiar los 0 de principio de los fonos
UPDATE a
set ctd_fono1 = (CASE WHEN LEFT(b.ctd_fono1, 1) = '0' THEN SUBSTRING(b.ctd_fono1, 2, LEN(b.ctd_fono1) - 1)  ELSE b.ctd_fono1   END)
FROM #fono as a
join #fono as b 
	on a.cto_rut = b.cto_rut 
	and a.ctd_correl = b.ctd_correl
	and a.clave = b.clave
where LEFT(b.ctd_fono1, 1) = '0'


--Borrar fono nulos y menores a 9 digitos
delete #fono where ctd_fono1 is null
delete #fono where len(ctd_fono1) < 9



--select * from #direccion
--select * from #EMAIL
--select * from #fono


--1.- DIRECCION
insert into #contacto_det_new 
(
	cto_rut, 
	ctd_correl, 
	ctd_direccion, 
	cmn_codigo, 
	ctd_email1, 
	ctd_email2, 
	ctd_fono1, 
	ctd_fono2, 
	ctd_encar_rem, 
	usu_login, 
	ctd_fecreg, 
	ctd_origen, 
	ctd_inf_contacto 
)
select d.cto_rut
	, null
	, d.ctd_direccion
	, d.cmn_codigo
	, null --, c.ctd_email1
	, null --, c.ctd_email2
	, null --, c.ctd_fono1
	, null --, c.ctd_fono2
	, c.ctd_encar_rem
	, c.usu_login
	, c.ctd_fecreg
	, c.ctd_origen
	, c.ctd_inf_contacto
from #direccion d
join contacto_det c
	on d.cto_rut = c.cto_rut
	and d.ctd_correl = c.ctd_correl


--EMAIL
insert into #contacto_det_new 
(
	cto_rut, 
	ctd_correl, 
	ctd_direccion, 
	cmn_codigo, 
	ctd_email1, 
	ctd_email2, 
	ctd_fono1, 
	ctd_fono2, 
	ctd_encar_rem, 
	usu_login, 
	ctd_fecreg, 
	ctd_origen, 
	ctd_inf_contacto 
)
select d.cto_rut
	, null
	, null --, d.ctd_direccion
	, null --, d.cmn_codigo
	, d.ctd_email1
	, null --, c.ctd_email2
	, null --, c.ctd_fono1
	, null --, c.ctd_fono2
	, c.ctd_encar_rem
	, c.usu_login
	, c.ctd_fecreg
	, c.ctd_origen
	, c.ctd_inf_contacto
from #email d
join contacto_det c
	on d.cto_rut = c.cto_rut
	and d.ctd_correl = c.ctd_correl


--FONO
insert into #contacto_det_new 
(
	cto_rut, 
	ctd_correl, 
	ctd_direccion, 
	cmn_codigo, 
	ctd_email1, 
	ctd_email2, 
	ctd_fono1, 
	ctd_fono2, 
	ctd_encar_rem, 
	usu_login, 
	ctd_fecreg, 
	ctd_origen, 
	ctd_inf_contacto 
)
select d.cto_rut
	, null
	, null --, d.ctd_direccion
	, null --, d.cmn_codigo
	, null --, c.ctd_email1
	, null --, c.ctd_email2
	, d.ctd_fono1
	, null --, c.ctd_fono2
	, c.ctd_encar_rem
	, c.usu_login
	, c.ctd_fecreg
	, c.ctd_origen
	, c.ctd_inf_contacto
from #fono d
join contacto_det c
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


insert into CONTACTO_DET_NEW
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



	SELECT * FROM CONTACTO_DET_NEW






end