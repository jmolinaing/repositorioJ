
select * from GCO_ENVMSG_PROGRAMA
select * from GCO_ENVMSG_PROGRAMA_LOG


EPR_CODIGO numeric(10) not null
EPL_FECHORA datetime not null
EPL_TEXTO_ERROR

declare @fecha_hoy datetime
declare @fecha_manana datetime
select @fecha_hoy = cast(cast(getdate() as date) as datetime)
set @fecha_manana = dateadd(day, 1, @fecha_hoy)
print @fecha_hoy
print @fecha_manana

select * 
from GCO_ENVMSG_PROGRAMA prog with (nolock)
join GCO_ENVMSG_PLANTILLA plant with (nolock)
	on prog.epl_codigo = plant.epl_codigo
where plant.epl_vigente = 'S'
and 
(
--programacion Una vez
(prog.EPR_TIPO_ENVIO = 'U' and (epr_inivig_envio <= @fecha_hoy and EPR_FINVIG_ENVIO is null) )
OR
--programacion Periódica
(prog.EPR_TIPO_ENVIO = 'P' and (epr_inivig_envio <= @fecha_hoy and (EPR_FINVIG_ENVIO > @fecha_manana OR EPR_FINVIG_ENVIO is null) )	)
)