select * from GCDF_DEUDA where TDE_CODIGO in(3, 4)
select * from GCDF_tipo_DEUDA

--1	DEUDA LEY DE URGENCIA
--2	CHEQUE PROTESTADO
--3	DEUDA LICENCIAS REDICTAMINADAS
--4	DEUDA COBERTURA DAVITA

select * from oa


select * from oa o 
join GCDF_DEUDA d on o.DEU_CORREL = d.DEU_CORREL
where d.tde_codigo in(4)


spu_ges_cob_genera_deuda_chq
spu_ges_cob_genera_deuda_lur


TIPO 3
procesos nuevos
licencias con redictamesn o sil rechazado.
licencias medicas que la isapre pago pero no se debio haber pagado.
y se parece mucho con el cheque protestado(2	CHEQUE PROTESTADO).  habra que poner el deu_correl en la tabla licencia o licencia_contraloria.


TIPO 4
COPAGO DAVITA
es casi identico a ley de urgencias (1	DEUDA LEY DE URGENCIA)
dialisis, la isapre entrega el tratamiento y despues cobra


requerimientos:
Implementar spu_ges_cob_genera_deuda_lic , similar a spu_ges_cob_genera_deuda_chq
-identificar las nuevas licencias que generan deuda por redictamen e insertar un registro por cada licencia en la tabla gcdf_deuda.
- actualizar deu_correl de la tabla licencia_contraloria con el id de la deuda respectiva.


select * from licencia_contraloria 


Implementar spu_ges_cob_genera_deuda_dav , similar a spu_ges_cob_genera_deuda_lur
-identificar los nuevos BONOS PAM que generan deuda por COPAGO DAVITA e insertar un registro por cada PAM en la tabla gcdf_deuda.
- actualizar deu_correl de la tabla OA con el id de la deuda respectiva.

1.- En la venta "wi_gestion_cobro_deuda_financiera" que mantiene el detalle de la deuda, se debe intervenir para manejar los 2 nuevos tipos de deuda (3=Licencias Rechazadas y 4=Davita)


4=Davita ES EXACTAMENTE LO MISMO (1	DEUDA LEY DE URGENCIA SE SUPONE)