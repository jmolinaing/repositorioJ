--Deuda Cotizaciones afiliados (personas)
select cot_rut as rut, sum(DEC_PACTADO	- DEC_PAGADO) as deuda
from deuda_cotizante 
where epa_rut is null
and cot_rut = ' 127968284'
group by cot_rut
having sum(DEC_PACTADO	- DEC_PAGADO) > 0
union  --INTERSECT
--Deuda Cotizaciones Empresas (empleadores)
select epa_rut as rut, sum(DEC_PACTADO	- DEC_PAGADO) as deuda 
from deuda_cotizante 
where epa_rut is not null
and epa_rut = ' 127968284'
group by epa_rut
having sum(DEC_PACTADO	- DEC_PAGADO) > 0



--(187610 rows affected)
select a.rut, sum(a.deuda) deuda
from
(
--Deuda Cotizaciones afiliados (personas)
select cot_rut as rut, sum(DEC_PACTADO	- DEC_PAGADO) as deuda
from deuda_cotizante 
where epa_rut is null
--and cot_rut = ' 127968284'
group by cot_rut
having sum(DEC_PACTADO	- DEC_PAGADO) > 0
union
--Deuda Cotizaciones Empresas (empleadores)
select epa_rut as rut, sum(DEC_PACTADO	- DEC_PAGADO) as deuda 
from deuda_cotizante 
where epa_rut is not null
--and epa_rut = ' 127968284'
group by epa_rut
having sum(DEC_PACTADO	- DEC_PAGADO) > 0
) a
group by rut


-- lur
select DDR_rut, count(DDR_rut)
from dbo.GCDF_DEUDA gd with (nolock)
where deu_monto > 0
and TDE_CODIGO = 1
group by DDR_rut

-- chq
select DDR_rut, count(DDR_rut)
from dbo.GCDF_DEUDA gd with (nolock)
where deu_monto > 0
and TDE_CODIGO = 2
group by DDR_rut


select DDR_rut, deu_monto
from dbo.GCDF_DEUDA gd with (nolock)
where deu_monto > 0
and ddr_rut = '  98765891'


select DDR_rut, sum(deu_monto)
from dbo.GCDF_DEUDA gd with (nolock)
where deu_monto > 0
and ddr_rut = '  98765891'
group by DDR_rut


--CONJUNTO LUR y chq  (9425 rows affected)
select DDR_rut, sum(deu_monto)
from dbo.GCDF_DEUDA gd with (nolock)
where deu_monto > 0
group by DDR_rut

--CONJUNTO LUR  (7491 rows affected)
select DDR_rut, sum(deu_monto)
from dbo.GCDF_DEUDA gd with (nolock)
where deu_monto > 0
and TDE_CODIGO = 1
group by DDR_rut

--CONJUNTO chq  (2029 rows affected)
select DDR_rut, sum(deu_monto)
from dbo.GCDF_DEUDA gd with (nolock)
where deu_monto > 0
and TDE_CODIGO = 2
group by DDR_rut


--select * from dbo.GCDF_DEUDA gd with (nolock)


-- UNION ALL : (197035 rows affected)   (187610 rows affected) + (9425 rows affected)
select a.rut
from
(
--Deuda Cotizaciones afiliados (personas)
select cot_rut as rut, sum(DEC_PACTADO	- DEC_PAGADO) as deuda
from deuda_cotizante 
where epa_rut is null
--and cot_rut = ' 127968284'
group by cot_rut
having sum(DEC_PACTADO	- DEC_PAGADO) > 0
union
--Deuda Cotizaciones Empresas (empleadores)
select epa_rut as rut, sum(DEC_PACTADO	- DEC_PAGADO) as deuda 
from deuda_cotizante 
where epa_rut is not null
--and epa_rut = ' 127968284'
group by epa_rut
having sum(DEC_PACTADO	- DEC_PAGADO) > 0
) a
group by rut
UNION ALL
select DDR_rut
from dbo.GCDF_DEUDA gd with (nolock)
where deu_monto > 0
group by DDR_rut


-- INTERSECT (3447 rows affected)
select a.rut
from
(
--Deuda Cotizaciones afiliados (personas)
select cot_rut as rut, sum(DEC_PACTADO	- DEC_PAGADO) as deuda
from deuda_cotizante 
where epa_rut is null
--and cot_rut = ' 127968284'
group by cot_rut
having sum(DEC_PACTADO	- DEC_PAGADO) > 0
union
--Deuda Cotizaciones Empresas (empleadores)
select epa_rut as rut, sum(DEC_PACTADO	- DEC_PAGADO) as deuda 
from deuda_cotizante 
where epa_rut is not null
--and epa_rut = ' 127968284'
group by epa_rut
having sum(DEC_PACTADO	- DEC_PAGADO) > 0
) a
group by rut
intersect
select DDR_rut
from dbo.GCDF_DEUDA gd with (nolock)
where deu_monto > 0
group by DDR_rut
