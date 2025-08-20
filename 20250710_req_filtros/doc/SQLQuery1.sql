select * from GCO_ENVMSG_PLANTILLA
select * from GCO_ENVMSG_CONCEPTO
select * from GCO_ENVMSG_FILTRO2





insert into GCO_ENVMSG_PLANTILLA values ('1', 'plantilla 1', 'S')

delete GCO_ENVMSG_CONCEPTO
delete GCO_ENVMSG_CONCEPTO  where ECO_CODIGO = 5

--insert into GCO_ENVMSG_CONCEPTO values (1, 'D�A', 'S')
--insert into GCO_ENVMSG_CONCEPTO values (2, 'HORA', 'S')
--insert into GCO_ENVMSG_CONCEPTO values (3, 'TIPO ENVIO CORREO', 'S')
--insert into GCO_ENVMSG_CONCEPTO values (4, 'TIPO ENVIO WSP', 'S')
--insert into GCO_ENVMSG_CONCEPTO values (5, 'LINK CON CUP�N', 'S')
--insert into GCO_ENVMSG_CONCEPTO values (6, 'LINK SIN CUP�N', 'S')
--insert into GCO_ENVMSG_CONCEPTO values (6, 'LINK SIN CUP�N', 'S')






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

--HORA	Hora de env�o seg�n calendario	Selecci�n �nica
--TIPO ENVIO		Selecci�n �nica
--correo		
--wsp		
--LINK		Selecci�n �nica
--Con cup�n		
--Sin cup�n		
GRUPO o Equipo		M�ltiple
Equipo Interno		
Equipo Stock		
Equipo judicial		
Otros		
Supervisor		M�ltiple
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
Cobrador Asignado		M�ltiple
Grupo Deuda	Agrupaci�n por montos s/UF	M�ltiple
Tipo y Vigencia Deudor		M�ltiple
Con Gesti�n C�d.. 29	Identificando la ultima gesti�n 29 del mes	M�ltiple
Fecha Compromiso vencido	Identificaci�n de Gesti�n 29 vencida	M�ltiple
Tipo de Deuda	Selecci�n tipo deuda	Selecci�n �nica
Tipo Deuda Cotizaciones		M�ltiple
Menor Periodo de Deuda	Representa el periodo mas antiguo de deuda	M�ltiple
Cuidad Residencia	Ciudad de residencia del deudor	M�ltiple
Deudores LUR con Cr�dito 5%	Si tiene cr�dito (Cuotas)	M�ltiple
Tipo de Empresa	Falta el Mantenedor (crear para alimentar)	M�ltiple
Rubro Empresa	Falta el Mantenedor (crear para alimentar)	M�ltiple
Posible Compensar x TFU	Si cuenta con saldo disponible de devoluci�n TFU	M�ltiple
Edad Deudor		M�ltiple



  SELECT ECO_CODIGO,   
         ECO_NOMBRE,   
         ECO_TIPO_SELECCION  
		 , case ECO_TIPO_SELECCION when 'M' then 'Multiple' else '�nica' end as accion
    FROM GCO_ENVMSG_CONCEPTO   