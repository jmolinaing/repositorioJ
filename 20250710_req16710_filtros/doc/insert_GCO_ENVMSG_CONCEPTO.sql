select * from GCO_ENVMSG_PLANTILLA
select * from GCO_ENVMSG_CONCEPTO
select * from GCO_ENVMSG_FILTRO

delete GCO_ENVMSG_FILTRO
delete GCO_ENVMSG_CONCEPTO
delete GCO_ENVMSG_CONCEPTO  where ECO_CODIGO in (1, 2)

insert into GCO_ENVMSG_PLANTILLA values ('1', 'plantilla 1', 'S')


insert into GCO_ENVMSG_CONCEPTO values (1, 'GRUPO o Equipo', 'M')
insert into GCO_ENVMSG_CONCEPTO values (2, 'Supervisor', 'M')
insert into GCO_ENVMSG_CONCEPTO values (3, 'Cobrador Asignado', 'M')
insert into GCO_ENVMSG_CONCEPTO values (4, 'Grupo Deuda', 'M')
insert into GCO_ENVMSG_CONCEPTO values (5, 'Tipo y Vigencia Deudor', 'M')
insert into GCO_ENVMSG_CONCEPTO values (6, 'Con Gestión Cód. 29', 'M')
insert into GCO_ENVMSG_CONCEPTO values (7, 'Fecha Compromiso vencido', 'M')
insert into GCO_ENVMSG_CONCEPTO values (8, 'Tipo de Deuda', 'M')
insert into GCO_ENVMSG_CONCEPTO values (9, 'Tipo Deuda Cotizaciones', 'M')
insert into GCO_ENVMSG_CONCEPTO values (10, 'Menor Periodo de Deuda', 'M')
insert into GCO_ENVMSG_CONCEPTO values (11, 'Mayor Periodo de Deuda', 'M')
insert into GCO_ENVMSG_CONCEPTO values (12, 'Cuidad Residencia', 'M')
insert into GCO_ENVMSG_CONCEPTO values (13, 'Deudores LUR con Crédito 5%', 'M')
insert into GCO_ENVMSG_CONCEPTO values (14, 'Tipo de Empresa', 'M')
insert into GCO_ENVMSG_CONCEPTO values (15, 'Rubro Empresa', 'M')
insert into GCO_ENVMSG_CONCEPTO values (16, 'Posible Compensar x TFU', 'M')
insert into GCO_ENVMSG_CONCEPTO values (17, 'Edad Deudor', 'M')



GRANT INSERT, UPDATE, DELETE ON [GCO_ENVMSG_PROGRAMA] TO public;

