select * from GCO_ENVMSG_PLANTILLA
select * from GCO_ENVMSG_CONCEPTO
select * from GCO_ENVMSG_FILTRO2


select * from GCO_ENVMSG_FILTRO2
select * from GCO_ENVMSG_PROGRAMA


select p.epl_codigo
	, p.epl_nombre
	, p.epl_vigente
	, c.eco_codigo
	, c.eco_nombre
	, c.eco_tipo_seleccion
	, case ECO_TIPO_SELECCION when 'M' then 'Multiple' else 'Única' end as accion
	, f.efi_valor
from GCO_ENVMSG_PLANTILLA p
join GCO_ENVMSG_FILTRO2 f
	on p.EPL_CODIGO = f.EPL_CODIGO
join GCO_ENVMSG_CONCEPTO c
	on c.ECO_CODIGO = f.ECO_CODIGO

