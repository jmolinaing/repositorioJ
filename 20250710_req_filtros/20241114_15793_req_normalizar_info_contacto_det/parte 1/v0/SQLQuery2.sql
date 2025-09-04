/*
--TOTAL: (1047078 rows affected) 4:25 min
select top 100 * from CONTACTO_DET with (nolock)
select * from CONTACTO_DET_new


*/

-- 1.- dirección

--PRIMERA OPCION : BUSCAR SOLO DIRECCIONES CON SU COMUNA
--(779138 rows affected)  1min
-- distinc
select distinct cto_rut
, ctd_direccion
, cmn_codigo
from dbo.CONTACTO_DET with (nolock)
where 1 = 1
and ctd_direccion is not null
and ltrim(rtrim(ctd_direccion)) <> ''
order by cto_rut desc

--(857543 rows affected)  1min
-- sin distinc
/*
ejemplo 
 995952009	MAGDALENA 140 1700	1308
 995952009	MAGDALENA 140 1700	1308
*/


select cto_rut
, ctd_direccion
, cmn_codigo
from dbo.CONTACTO_DET with (nolock)
where 1 = 1
and ctd_direccion is not null
and ltrim(rtrim(ctd_direccion)) <> ''
order by cto_rut desc


-- con ctd_correl y sin distinct
--(857543 rows affected) 1:16
select cto_rut
, ctd_correl
, ctd_direccion
, cmn_codigo
from dbo.CONTACTO_DET with (nolock)
where 1 = 1
and ctd_direccion is not null
and ltrim(rtrim(ctd_direccion)) <> ''
order by cto_rut desc, ctd_correl

-- con ctd_correl y con distinct
--(857543 rows affected) 1:16
select distinct cto_rut
, ctd_correl
, ctd_direccion
, cmn_codigo
from dbo.CONTACTO_DET with (nolock)
where 1 = 1
and ctd_direccion is not null
and ltrim(rtrim(ctd_direccion)) <> ''
order by cto_rut desc, ctd_correl

---__________________________________________________________






select c.*
from CONTACTO_DET c with (nolock)
join
(
	select distinct cto_rut
	, ctd_direccion
	, cmn_codigo
	--into #direccion
	from dbo.CONTACTO_DET with (nolock)
	where 1 = 1
	and ctd_direccion is not null
	and ltrim(rtrim(ctd_direccion)) <> ''
	--order by cto_rut desc
) b
	on c.cto_rut = b.CTO_RUT
	and c.ctd_direccion = b.ctd_direccion
	and isnull(c.CMN_CODIGO, 0) = isnull(b.CMN_CODIGO, 0)








--2 .-email
-- SOLO EMAIL
--(634445 rows affected)  50 seg
select distinct cto_rut
, ctd_email1
from dbo.CONTACTO_DET with (nolock)
where 1 = 1
and ctd_email1 is not null
and ltrim(rtrim(ctd_email1)) <> ''
--order by cto_rut desc

--(786027 rows affected)  1min
select distinct cto_rut
, ctd_correl
, ctd_email1
from dbo.CONTACTO_DET with (nolock)
where 1 = 1
and ctd_email1 is not null
and ltrim(rtrim(ctd_email1)) <> ''
order by cto_rut desc, ctd_correl


--(786027 rows affected)  1min,   con distinct o sin distinct da lo mismo
select  cto_rut
, ctd_correl
, ctd_email1
from dbo.CONTACTO_DET with (nolock)
where 1 = 1
and ctd_email1 is not null
and ltrim(rtrim(ctd_email1)) <> ''
order by cto_rut desc, ctd_correl desc



--opcion uno
--(634445 rows affected) 49 seg
select cto_rut
, ctd_email1
from
(
select distinct cto_rut
, ctd_email1
--into #direccion
from dbo.CONTACTO_DET with (nolock)
where 1 = 1
and ctd_email1 is not null
and ltrim(rtrim(ctd_email1)) <> ''
--order by cto_rut desc
) a

union

select cto_rut
, ctd_email2
from
(
select distinct cto_rut
, ctd_email2
--into #direccion
from dbo.CONTACTO_DET with (nolock)
where 1 = 1
and ctd_email2 is not null
and ltrim(rtrim(ctd_email2)) <> ''
--order by cto_rut desc
) b




--opcion dos
--(786027 rows affected) 1:16 min 
select cto_rut
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

select cto_rut
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





--opcion 3
--(786027 rows affected)  1min, da lo mismo el distinct
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




--opcion 4 (786027 rows affected)

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





--fono
--(929965 rows affected)

select cto_rut
, ctd_fono1
from
(
select distinct cto_rut
, ctd_fono1
--into #direccion
from dbo.CONTACTO_DET with (nolock)
where 1 = 1
and ctd_fono1 is not null
and ltrim(rtrim(ctd_fono1)) <> ''
--order by cto_rut desc
) a

union

select cto_rut
, ctd_fono2
from
(
select distinct cto_rut
, ctd_fono2
--into #direccion
from dbo.CONTACTO_DET with (nolock)
where 1 = 1
and ctd_fono2 is not null
and ltrim(rtrim(ctd_fono2)) <> ''
--order by cto_rut desc
) b







