
/*================================================================================================= 
 CREADO POR         : Jorge Molina                                     
 FECHA CREACION     : 11-2024                                                                   
 DESCRIPCION        : Obtiene listado 
 --=================================================================================================*/

--GRANT EXECUTE ON dbo.spu_ges_cob_normalizar TO public 
--exec spu_ges_cob_normalizar


--select * from CONTACTO_DET with (nolock) where  CHARINDEX(' ', ctd_email1) > 0
--select * from CONTACTO_DET with (nolock) where len(ltrim(rtrim(CTD_DIRECCION))) < 4 order by ctd_direccion desc
--select * from CONTACTO_DET with (nolock) where len(ctd_email1) < 5 order by ctd_email1 desc
--'fannyta1987@gmail.com '


alter PROCEDURE dbo.spu_ges_cob_normalizar  

AS  
BEGIN  

SET NOCOUNT ON; 

IF OBJECT_ID(N'tempdb..#direccion', N'U') IS NOT NULL DROP TABLE #direccion
IF OBJECT_ID(N'tempdb..#email', N'U') IS NOT NULL DROP TABLE #email
IF OBJECT_ID(N'tempdb..#fono', N'U') IS NOT NULL DROP TABLE #fono
IF OBJECT_ID(N'tempdb..#fono_v2', N'U') IS NOT NULL DROP TABLE #fono_v2

DECLARE @CTO_RUT  char(10)
DECLARE @CLAVE NUMERIC(10)
DECLARE @CTD_CORREL NUMERIC(10)
DECLARE @CTO_RUTX  char(10)

CREATE TABLE #CONTACTO_DET_NEW_V0
(
	CTO_RUT char(10)  NOT NULL,
	CTD_CORREL numeric(4, 0)  not NULL,
	CTD_DIRECCION varchar(250) NULL,
	CTD_DIRECCION_V2 varchar(250) NULL,
	CMN_CODIGO numeric(4, 0) NULL,
	CTD_EMAIL1 varchar(250) NULL,
	CTD_EMAIL1_V2 varchar(250) NULL,
	CTD_EMAIL2 varchar(250) NULL,
	CTD_EMAIL2_V2 varchar(250) NULL,
	CTD_FONO1 varchar(50) NULL,
	CTD_FONO2 varchar(50) NULL,
	CTD_ENCAR_REM varchar(250) NULL,		--NO SE TRASPASA
	USU_LOGIN char(30)  NULL,
	CTD_FECREG datetime  NULL,
	CTD_ORIGEN varchar(50)  NULL,
	CTD_INF_CONTACTO varchar(250) NULL		--NO SE TRASPASA
	--, CLAVE NUMERIC(10) IDENTITY(1,1) --PRIMARY KEY
,
PRIMARY KEY (CTO_RUT, CTD_CORREL)
)


INSERT INTO #CONTACTO_DET_NEW_V0
(
	CTO_RUT ,
	CTD_CORREL ,
	CTD_DIRECCION ,
	--CTD_DIRECCION_V2,
	CMN_CODIGO ,
	CTD_EMAIL1 ,
	--CTD_EMAIL1_V2 ,
	CTD_EMAIL2 ,
	--CTD_EMAIL2_V2 ,
	CTD_FONO1 ,
	CTD_FONO2 ,
	CTD_ENCAR_REM ,
	USU_LOGIN ,
	CTD_FECREG ,
	CTD_ORIGEN ,
	CTD_INF_CONTACTO 
	)
SELECT 	CTO_RUT ,
	CTD_CORREL ,
	ltrim(rtrim(CTD_DIRECCION)) ,
	CMN_CODIGO ,
	replace(ltrim(rtrim(CTD_EMAIL1)) , ' ', '') ,
	replace(ltrim(rtrim(CTD_EMAIL2)) , ' ', '') ,
	(
case when ((isnumeric(  
replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(  
ltrim(rtrim(ctd_fono1))  
, '-', ''), '+', ''), '*', ''), '/', ''), '.', ''), ',', ''), ' ', ''), '$', ''), '^', ''), '%', ''), '=', ''), '<', ''), '>', ''), '[', ''), ']', ''), '{', ''), '}', ''), '@', ''), ' ', ''), '(', ''), ')', '')  
) = 1 )  

) then   
  
replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(  
ltrim(rtrim(ctd_fono1))  
, '-', ''), '+', ''), '*', ''), '/', ''), '.', ''), ',', ''), ' ', ''), '$', ''), '^', ''), '%', ''), '=', ''), '<', ''), '>', ''), '[', ''), ']', ''), '{', ''), '}', ''), '@', ''), ' ', ''), '(', ''), ')', '')    

else null end
) ,
(
case when ((isnumeric(  
replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(  
ltrim(rtrim(ctd_fono2))  
, '-', ''), '+', ''), '*', ''), '/', ''), '.', ''), ',', ''), ' ', ''), '$', ''), '^', ''), '%', ''), '=', ''), '<', ''), '>', ''), '[', ''), ']', ''), '{', ''), '}', ''), '@', ''), ' ', ''), '(', ''), ')', '')  
) = 1 )  

) then   
  
replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(  
ltrim(rtrim(ctd_fono2))  
, '-', ''), '+', ''), '*', ''), '/', ''), '.', ''), ',', ''), ' ', ''), '$', ''), '^', ''), '%', ''), '=', ''), '<', ''), '>', ''), '[', ''), ']', ''), '{', ''), '}', ''), '@', ''), ' ', ''), '(', ''), ')', '')    

else null end
) ,
	NULL ,		--NO SE TRASPASA
	USU_LOGIN ,
	CTD_FECREG ,
	CTD_ORIGEN ,
	NULL
FROM CONTACTO_DET



--LIMPIEZAS
--1.- DIRECCION: limpiar los que tienen len() < 5
UPDATE a
set ctd_direccion = null
FROM #CONTACTO_DET_NEW_V0 as a
join #CONTACTO_DET_NEW_V0 as b 
	on a.cto_rut = b.cto_rut 
	and a.ctd_correl = b.ctd_correl
where (len(b.ctd_direccion) < 5 )

--2.- EMAIL1: limpiar los que tienen len() < 5
UPDATE a
set ctd_email1 = null
FROM #CONTACTO_DET_NEW_V0 as a
join #CONTACTO_DET_NEW_V0 as b 
	on a.cto_rut = b.cto_rut 
	and a.ctd_correl = b.ctd_correl
where (len(b.ctd_email1) < 5 )

--3.- EMAIL2: limpiar los que tienen len() < 5
UPDATE a
set ctd_email2 = null
FROM #CONTACTO_DET_NEW_V0 as a
join #CONTACTO_DET_NEW_V0 as b 
	on a.cto_rut = b.cto_rut 
	and a.ctd_correl = b.ctd_correl
where (len(b.ctd_email2) < 5 )


--Limpiar los 0 de principio de los fono1
UPDATE a
set ctd_fono1 = (CASE WHEN LEFT(b.ctd_fono1, 1) = '0' THEN SUBSTRING(b.ctd_fono1, 2, LEN(b.ctd_fono1) - 1)  ELSE b.ctd_fono1   END)
FROM #CONTACTO_DET_NEW_V0 as a
join #CONTACTO_DET_NEW_V0 as b 
	on a.cto_rut = b.cto_rut 
	and a.ctd_correl = b.ctd_correl
where LEFT(b.ctd_fono1, 1) = '0'

--Limpiar los 0 de principio de los fono2
UPDATE a
set ctd_fono1 = (CASE WHEN LEFT(b.ctd_fono2, 1) = '0' THEN SUBSTRING(b.ctd_fono2, 2, LEN(b.ctd_fono2) - 1)  ELSE b.ctd_fono2   END)
FROM #CONTACTO_DET_NEW_V0 as a
join #CONTACTO_DET_NEW_V0 as b 
	on a.cto_rut = b.cto_rut 
	and a.ctd_correl = b.ctd_correl
where LEFT(b.ctd_fono2, 1) = '0'


--Solo los fonos con len()= 11 y que comiencen con '56', se elimina el '56' y se traspasa sus 9 digitos
UPDATE a
set ctd_fono1 = (CASE WHEN LEFT(b.ctd_fono1, 2) = '56' THEN SUBSTRING(b.ctd_fono1, 3, LEN(b.ctd_fono1) - 2)  ELSE b.ctd_fono1   END)
FROM #CONTACTO_DET_NEW_V0 as a
join #CONTACTO_DET_NEW_V0 as b 
	on a.cto_rut = b.cto_rut 
	and a.ctd_correl = b.ctd_correl
where LEFT(b.ctd_fono1, 2) = '56'
and len(b.ctd_fono1) = 11

UPDATE a
set ctd_fono2 = (CASE WHEN LEFT(b.ctd_fono2, 2) = '56' THEN SUBSTRING(b.ctd_fono2, 3, LEN(b.ctd_fono2) - 2)  ELSE b.ctd_fono2   END)
FROM #CONTACTO_DET_NEW_V0 as a
join #CONTACTO_DET_NEW_V0 as b 
	on a.cto_rut = b.cto_rut 
	and a.ctd_correl = b.ctd_correl
where LEFT(b.ctd_fono2, 2) = '56'
and len(b.ctd_fono2) = 11


UPDATE a
set ctd_fono1 = null
FROM #CONTACTO_DET_NEW_V0 as a
join #CONTACTO_DET_NEW_V0 as b 
	on a.cto_rut = b.cto_rut 
	and a.ctd_correl = b.ctd_correl
where (len(b.ctd_fono1) < 9 or len(b.ctd_fono1) > 9)

UPDATE a
set ctd_fono2 = null
FROM #CONTACTO_DET_NEW_V0 as a
join #CONTACTO_DET_NEW_V0 as b 
	on a.cto_rut = b.cto_rut 
	and a.ctd_correl = b.ctd_correl
where (len(b.ctd_fono2) < 9 or len(b.ctd_fono2) > 9)


--TRASPASAR V2
UPDATE a
set ctd_direccion_v2 = replace(b.ctd_direccion, ' ', '')
FROM #CONTACTO_DET_NEW_V0 as a
join #CONTACTO_DET_NEW_V0 as b 
	on a.cto_rut = b.cto_rut 
	and a.ctd_correl = b.ctd_correl


--hasta aqui
--1.047.078 reg 3 min



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

--ORGANIZAR DIRECCION
--(779138 rows affected) 1:11 min
--V1  779mil reg
--select cto_rut, ctd_direccion, cmn_codigo--, count(*) as contador
--, (select max(d.ctd_correl) from #CONTACTO_DET_NEW_V0 d with (nolock) where d.cto_rut = c.cto_rut and d.ctd_direccion = c.ctd_direccion and isnull(d.cmn_codigo, 0) = isnull(c.cmn_codigo, 0)) ctd_correl
----into #direccion
--from #CONTACTO_DET_NEW_V0 c with (nolock)
--where ctd_direccion is not null
----and ltrim(rtrim(ctd_direccion)) <> ''
--group by cto_rut, ctd_direccion, cmn_codigo
--order by cto_rut, ctd_direccion 

--V2  774 mil reg
select cto_rut, ctd_direccion_v2, cmn_codigo--, count(*) as contador
, (select max(d.ctd_correl) from #CONTACTO_DET_NEW_V0 d with (nolock) where d.cto_rut = c.cto_rut and d.ctd_direccion_v2 = c.ctd_direccion_v2 and isnull(d.cmn_codigo, 0) = isnull(c.cmn_codigo, 0)) ctd_correl
into #direccion
from #CONTACTO_DET_NEW_V0 c with (nolock)
where ctd_direccion_v2 is not null
--and ltrim(rtrim(ctd_direccion)) <> ''
group by cto_rut, ctd_direccion_v2, cmn_codigo
order by cto_rut, ctd_direccion_v2 



--2.-EMAIL  
--(633mil reg
select cto_rut, ctd_email1
, COALESCE((select max(d.ctd_correl) from #CONTACTO_DET_NEW_V0 d with (nolock) where d.cto_rut = a.cto_rut and d.ctd_email1 = a.ctd_email1 ), (select max(d.ctd_correl) from #CONTACTO_DET_NEW_V0 d with (nolock) where d.cto_rut = a.cto_rut and d.ctd_email2 = a.ctd_email1 ))  as ctd_correl
INTO #EMAIL
from
(
	select cto_rut, ctd_email1
	--, count(*) as contador
	--, (select max(d.ctd_correl) from CONTACTO_DET d with (nolock) where d.cto_rut = c.cto_rut and d.ctd_email1 = c.ctd_email1 ) ctd_correl
	from #CONTACTO_DET_NEW_V0 c with (nolock)
	where ctd_email1 is not null
	--and ltrim(rtrim(ctd_email1)) <> ''
	group by cto_rut, ctd_email1
	--order by cto_rut, ctd_email1 
	UNION
	select cto_rut, ctd_email2
	--, count(*) as contador
	--, (select max(d.ctd_correl) from CONTACTO_DET d with (nolock) where d.cto_rut = c.cto_rut and d.ctd_email2 = c.ctd_email2 ) ctd_correl
	from #CONTACTO_DET_NEW_V0 c with (nolock)
	where ctd_email2 is not null
	--and ltrim(rtrim(ctd_email2)) <> ''
	group by cto_rut, ctd_email2
	--order by cto_rut, ctd_email2 
) a
order by cto_rut, ctd_email1 





--3.- FONO 
-- (290 rows affected) 19 seg
select cto_rut, ctd_fono1--, contador
--, ctd_correl
--, (select max(d.ctd_correl) from contacto_det d with (nolock) where d.cto_rut = a.cto_rut and d.ctd_fono1 = a.ctd_fono1 ) ctd_correl
, coalesce((select max(d.ctd_correl) from #CONTACTO_DET_NEW_V0 d with (nolock) where d.cto_rut = a.cto_rut and d.ctd_fono1 = a.ctd_fono1 and d.ctd_fono1 is not null), (select max(d.ctd_correl) from #CONTACTO_DET_NEW_V0 d with (nolock) where d.cto_rut = a.cto_rut and d.ctd_fono2 = a.ctd_fono1 and d.ctd_fono2 is not null), 99999999)  as ctd_correl
, identity(numeric(10), 1,1) clave -- colocamos clave ya que existian un registro con dos numeros y un mismo ctd_correl
into #fono
from
(
	-- fono1
	--(627387 rows affected) 1 min
	select cto_rut, ctd_fono1--, count(*) as contador
	--, (select max(d.ctd_correl) from contacto_det d with (nolock) where d.cto_rut = c.cto_rut and d.ctd_fono1 = c.ctd_fono1 ) ctd_correl
	from #CONTACTO_DET_NEW_V0 c with (nolock)
	where ctd_fono1 is not null
	--and ltrim(rtrim(ctd_fono1)) <> ''
	--and ltrim(rtrim(ctd_fono1)) <> '0'
	--and len(ctd_fono1) > 8
	group by cto_rut, ctd_fono1
	--order by cto_rut, ctd_fono1 
	union
	-- fono2
	--(426957 rows affected)
	select cto_rut, ctd_fono2--, count(*) as contador
	--, (select max(d.ctd_correl) from contacto_det d with (nolock) where d.cto_rut = c.cto_rut and d.ctd_fono2 = c.ctd_fono2 ) ctd_correl
	from #CONTACTO_DET_NEW_V0 c with (nolock)
	where ctd_fono2 is not null
	--and ltrim(rtrim(ctd_fono2)) <> ''
	--and ltrim(rtrim(ctd_fono2)) <> '0'
	--and len(ctd_fono2) > 8
	group by cto_rut, ctd_fono2
	--order by cto_rut, ctd_fono2 
) a
order by cto_rut, ctd_fono1 



/*

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

--Solo los fonos con len()= 11 y que comiencen con '56', se elimina el '56' y se traspasa sus 9 digitos
UPDATE a
set ctd_fono1 = (CASE WHEN LEFT(b.ctd_fono1, 2) = '56' THEN SUBSTRING(b.ctd_fono1, 3, LEN(b.ctd_fono1) - 2)  ELSE b.ctd_fono1   END)
FROM #fono as a
join #fono as b 
	on a.cto_rut = b.cto_rut 
	and a.ctd_correl = b.ctd_correl
	and a.clave = b.clave
where LEFT(b.ctd_fono1, 2) = '56'
and len(ctd_fono1) = 11

--Borrar fono nulos y menores a 9 digitos
delete #fono where ctd_fono1 is null		--eliminar fonos nulos
delete #fono where len(ctd_fono1) < 9		--eliminar fonos menores a 9 digitos
delete #fono where len(ctd_fono1) > 9		--eliminar fonos mayores a 9 digitos


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
*/


	--SELECT * FROM #CONTACTO_DET_NEW_V0


end