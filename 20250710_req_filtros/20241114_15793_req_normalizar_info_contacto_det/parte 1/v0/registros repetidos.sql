select cto_rut, CTD_FONO1, COUNT(*)
from CONTACTO_DET_NEW
where CTD_FONO1 is not null
group by cto_rut, CTD_FONO1
having COUNT(*)   > 1


select cto_rut, CTD_direccion, COUNT(*)
from CONTACTO_DET_NEW
where CTD_direccion is not null
group by cto_rut, CTD_direccion
having COUNT(*)   > 1

select cto_rut, CTD_email1, COUNT(*)
from CONTACTO_DET_NEW
where CTD_email1 is not null
group by cto_rut, CTD_email1
having COUNT(*)   > 1