select * from CONTACTO_DET
where cto_rut = ' 175137149'



select replace(ctd_email1, ' ', '') from CONTACTO_DET
where cto_rut = ' 175137149'


 01pedrojesus2021@gmail.com


 ' 01pedrojesus2021@gmail.com'


 select * from CONTACTO_DET
where cto_rut = ' 175137149'

 select * from CONTACTO_DET where ctd_email1)) = ltrim(rtrim(' 01pedrojesus2021@gmail.com'))


  select * from CONTACTO_DET
where cto_rut = ' 175137149'


 select * from CONTACTO_DET
where cto_rut = '  68626528'




 select * from CONTACTO_DET
where cto_rut = '     14184'



--(764980 rows affected) 1 min
select cto_rut, ctd_email1, count(*) from CONTACTO_DET
where ctd_email1 is not null
group by cto_rut, ctd_email1

--(634445 rows affected) 1 min
select cto_rut, ctd_email1, count(*)
, (select max(d.ctd_correl) from CONTACTO_DET d with (nolock) where d.cto_rut = c.cto_rut and d.ctd_email1 = c.ctd_email1 ) ctd_correl
from CONTACTO_DET c with (nolock)
where ctd_email1 is not null
and ltrim(rtrim(ctd_email1)) <> ''
group by cto_rut, ctd_email1
order by cto_rut, ctd_email1 
