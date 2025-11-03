select * from GCO_ENVMSG_PLANTILLA
select * from GCO_ENVMSG_CONCEPTO
select * from GCO_ENVMSG_FILTRO2





insert into GCO_ENVMSG_PLANTILLA values ('1', 'plantilla 1', 'S')

delete GCO_ENVMSG_CONCEPTO
delete GCO_ENVMSG_CONCEPTO  where ECO_CODIGO = 5

--insert into GCO_ENVMSG_CONCEPTO values (1, 'DÍA', 'S')
--insert into GCO_ENVMSG_CONCEPTO values (2, 'HORA', 'S')
--insert into GCO_ENVMSG_CONCEPTO values (3, 'TIPO ENVIO CORREO', 'S')
--insert into GCO_ENVMSG_CONCEPTO values (4, 'TIPO ENVIO WSP', 'S')
--insert into GCO_ENVMSG_CONCEPTO values (5, 'LINK CON CUPÓN', 'S')
--insert into GCO_ENVMSG_CONCEPTO values (6, 'LINK SIN CUPÓN', 'S')
--insert into GCO_ENVMSG_CONCEPTO values (6, 'LINK SIN CUPÓN', 'S')






insert into GCO_ENVMSG_CONCEPTO values (1, 'GRUPO o Equipo', 'M')
insert into GCO_ENVMSG_CONCEPTO values (2, 'Supervisor', 'M')
insert into GCO_ENVMSG_CONCEPTO values (3, 'Cobrador Asignado', 'M')
insert into GCO_ENVMSG_CONCEPTO values (4, 'Grupo Deuda', 'M')
insert into GCO_ENVMSG_CONCEPTO values (5, 'Tipo y Vigencia Deudor', 'M')

--delete GCO_ENVMSG_FILTRO
insert into GCO_ENVMSG_FILTRO2 values ('1', 1, 'Equipo Interno')
insert into GCO_ENVMSG_FILTRO2 values ('1', 1, 'Equipo Stock')
insert into GCO_ENVMSG_FILTRO2 values ('1', 1, 'Equipo judicial')

insert into GCO_ENVMSG_FILTRO2 values ('1', 2, 'A.SOTO')
insert into GCO_ENVMSG_FILTRO2 values ('1', 2, 'E.CABELLO')
insert into GCO_ENVMSG_FILTRO2 values ('1', 2, 'C.MORALES')

insert into GCO_ENVMSG_FILTRO2 values ('1', 3, 'Cob 1')
insert into GCO_ENVMSG_FILTRO2 values ('1', 3, 'Cob 2')
insert into GCO_ENVMSG_FILTRO2 values ('1', 3, 'Cob 3')

insert into GCO_ENVMSG_FILTRO2 values ('1', 4, 'A')
insert into GCO_ENVMSG_FILTRO2 values ('1', 4, 'B')
insert into GCO_ENVMSG_FILTRO2 values ('1', 4, 'C')

insert into GCO_ENVMSG_FILTRO2 values ('1', 5, 'Vigente')
insert into GCO_ENVMSG_FILTRO2 values ('1', 5, 'No Vigente')
insert into GCO_ENVMSG_FILTRO2 values ('1', 5, 'Empresa')

--HORA	Hora de envío según calendario	Selección única
--TIPO ENVIO		Selección única
--correo		
--wsp		
--LINK		Selección única
--Con cupón		
--Sin cupón		
GRUPO o Equipo		Múltiple
Equipo Interno		
Equipo Stock		
Equipo judicial		
Otros		
Supervisor		Múltiple
A.SOTO		
E.CABELLO		
C.MORALES		
M.SOLAR		
V.BECERRA		
C.DELGADO		
P.VILLOUTA		
C.VALDEBENITO		
J.JAMASMIE		
J.VICTORIA		
H.GUZMAN		
C.SAAVEDRA		
J.ROJAS		
J.CORTES		
C.UZCATEGUI		
C.VERDUGO		
A.ARAYA		
S.ALFONZO		
E.BOCAZ		
E.SEPULVEDA		
S.OLAVE		
Cobrador Asignado		Múltiple
Grupo Deuda	Agrupación por montos s/UF	Múltiple
Tipo y Vigencia Deudor		Múltiple
Con Gestión Cód.. 29	Identificando la ultima gestión 29 del mes	Múltiple
Fecha Compromiso vencido	Identificación de Gestión 29 vencida	Múltiple
Tipo de Deuda	Selección tipo deuda	Selección única
Tipo Deuda Cotizaciones		Múltiple
Menor Periodo de Deuda	Representa el periodo mas antiguo de deuda	Múltiple
Cuidad Residencia	Ciudad de residencia del deudor	Múltiple
Deudores LUR con Crédito 5%	Si tiene crédito (Cuotas)	Múltiple
Tipo de Empresa	Falta el Mantenedor (crear para alimentar)	Múltiple
Rubro Empresa	Falta el Mantenedor (crear para alimentar)	Múltiple
Posible Compensar x TFU	Si cuenta con saldo disponible de devolución TFU	Múltiple
Edad Deudor		Múltiple



  SELECT ECO_CODIGO,   
         ECO_NOMBRE,   
         ECO_TIPO_SELECCION  
		 , case ECO_TIPO_SELECCION when 'M' then 'Multiple' else 'Única' end as accion
    FROM GCO_ENVMSG_CONCEPTO   