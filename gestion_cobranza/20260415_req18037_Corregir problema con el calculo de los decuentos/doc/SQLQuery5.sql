select * from DEUDA_COTIZANTE
where dec_rut = ' 995972603'


select * from DEUDA_COTIZANTE
where dec_rut = epa_rut
and dec_nroresol is not null
order by epa_rut