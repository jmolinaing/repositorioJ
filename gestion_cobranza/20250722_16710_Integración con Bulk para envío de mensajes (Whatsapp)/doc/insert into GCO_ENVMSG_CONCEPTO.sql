--ECO_TIPO_SELECCION M, S  
insert into GCO_ENVMSG_CONCEPTO values (1, 'TIPO ENVIO', 'S')
insert into GCO_ENVMSG_CONCEPTO values (2, 'LINK', 'S')
insert into GCO_ENVMSG_CONCEPTO values (3, 'GRUPO o Equipo', 'M')
insert into GCO_ENVMSG_CONCEPTO values (4, 'Supervisor', 'M')
insert into GCO_ENVMSG_CONCEPTO values (5, 'Cobrador Asignado', 'M')
insert into GCO_ENVMSG_CONCEPTO values (6, 'Grupo Deuda', 'M')
insert into GCO_ENVMSG_CONCEPTO values (7, 'Tipo y Vigencia Deudor', 'M')
insert into GCO_ENVMSG_CONCEPTO values (8, 'Con Gestión Cód.. 29', 'M')
insert into GCO_ENVMSG_CONCEPTO values (9, 'Fecha Compromiso vencido', 'M')
insert into GCO_ENVMSG_CONCEPTO values (10, 'Tipo de Deuda', 'S')
insert into GCO_ENVMSG_CONCEPTO values (11, 'Tipo Deuda Cotizaciones', 'M')
insert into GCO_ENVMSG_CONCEPTO values (12, 'Menor Periodo de Deuda', 'M')
insert into GCO_ENVMSG_CONCEPTO values (13, 'Mayor Periodo de Deuda', 'M')
insert into GCO_ENVMSG_CONCEPTO values (14, 'Cuidad Residencia', 'M')
insert into GCO_ENVMSG_CONCEPTO values (15, 'Deudores LUR con Crédito 5%', 'M')
insert into GCO_ENVMSG_CONCEPTO values (16, 'Tipo de Empresa', 'M')
insert into GCO_ENVMSG_CONCEPTO values (17, 'Rubro Empresa', 'M')
insert into GCO_ENVMSG_CONCEPTO values (18, 'Posible Compensar x TFU', 'M')
insert into GCO_ENVMSG_CONCEPTO values (19, 'Edad Deudor', 'M')



TIPO ENVIO  
LINK  
GRUPO o Equipo  
Supervisor  
Cobrador Asignado  
Grupo Deuda  
Tipo y Vigencia Deudor  
Con Gestión Cód.. 29  
Fecha Compromiso vencido  
Tipo de Deuda  
Tipo Deuda Cotizaciones  
Menor Periodo de Deuda  
Cuidad Residencia  
Deudores LUR con Crédito 5%  
Tipo de Empresa  
Rubro Empresa  
Posible Compensar x TFU  
Edad Deudor  
  
--DELETE GCO_ENVMSG_FILTRO  
--DELETE GCO_ENVMSG_CONCEPTO  

select * from GCO_ENVMSG_PLANTILLA  
select * from GCO_ENVMSG_CONCEPTO  
select * from GCO_ENVMSG_FILTRO  
select * from GCO_ENVMSG_programa 
select * from gco_envmsg_api_template


update GCO_ENVMSG_CONCEPTO set ECO_TIPO_SELECCION = 'S' where eco_codigo in (3, 4)


select ate_codigo, ate_codigo_api, ate_descripcion from gco_envmsg_api_template with (nolock)


insert into gco_envmsg_api_template values (1, 'abcakbsabas', 'primer api')
  
  
delete GCO_ENVMSG_FILTRO  
  
--insert into GCO_ENVMSG_FILTRO values ('1', 1, 'Equipo Interno|Equipo Stock|Equipo judicial')  
insert into GCO_ENVMSG_FILTRO values ('1', 1, '1|3')  
  
--select * from cobrador where cob_nombre like '%morales%'  
--insert into GCO_ENVMSG_FILTRO values ('1', 2, 'A.SOTO|E.CABELLO|C.MORALES')  
insert into GCO_ENVMSG_FILTRO values ('1', 2, '3|145|181')  
  
--insert into GCO_ENVMSG_FILTRO values ('1', 3, 'Cob 1|Cob 2|Cob 3')  
--insert into GCO_ENVMSG_FILTRO values ('1', 3, 'Cob 1|Cob 2|Cob 3')  
  
  
--insert into GCO_ENVMSG_FILTRO values ('1', 4, 'A|B|C')  
--insert into GCO_ENVMSG_FILTRO values ('1', 5, 'Vigente|No Vigente|Empresa')  
insert into GCO_ENVMSG_FILTRO values ('1', 5, 'V|N')  
  
SELECT * FROM [dbo].[f_SplitString] (  
   'juanito|3|7','|')  
GO  