
--(1047078 rows affected) 4:25 min
select * from CONTACTO_DET with (nolock)
select * from CONTACTO_DET_new


select * from CONTACTO_DET with (nolock)
where cto_rut = ' 18428975K'

select cto_rut
--, ctd_correl
, count(*)
from CONTACTO_DET with (nolock)
group by cto_rut--, ctd_correl
having count(*) > 1
order by cto_rut





