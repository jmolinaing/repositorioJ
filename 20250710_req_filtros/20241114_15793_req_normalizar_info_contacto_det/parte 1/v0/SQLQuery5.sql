select top 100 * from CONTACTO_DET with (nolock)


--(779138 rows affected) sin ctd_correl
--(857543 rows affected) con ctd_correl
--(857543 rows affected) con , usu_login , ctd_fecreg  2min
select distinct cto_rut
, ctd_correl
, ctd_direccion
, cmn_codigo
, usu_login
, ctd_fecreg
from dbo.CONTACTO_DET with (nolock)
where 1 = 1
and ctd_direccion is not null
and ltrim(rtrim(ctd_direccion)) <> ''
order by cto_rut asc, ctd_correl asc



--(857543 rows affected), 4 min
select *
from CONTACTO_DET c with (nolock)
join
(
	select distinct cto_rut
	, ctd_correl
	, ctd_direccion
	, cmn_codigo
	--into #direccion
	from dbo.CONTACTO_DET with (nolock)
	where 1 = 1
	and ctd_direccion is not null
	and ltrim(rtrim(ctd_direccion)) <> ''
	--order by cto_rut asc, ctd_correl asc
) b
	on c.cto_rut = b.cto_rut
	and c.CTD_CORREL = b.CTD_CORREL
	