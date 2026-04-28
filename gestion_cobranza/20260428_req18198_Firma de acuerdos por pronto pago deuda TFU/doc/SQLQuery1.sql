

a)	Verificar si ya tiene un acuerdo firmado, y si es así, obtener los datos de ese acuerdo y dejar bloqueados los datos del email, de la cuenta, la funcionalidad para elegir forma de pago, para "eliminar" archivos adjuntos y para "confirmar" el acuerdo.

--Obtiene el folio de la solicitud firmada (si existe)
select @folio_prontopago = MAX(SPP_FOLIO) 
from SOLIC_PRONTO_PAGO_TFU with (nolock) 
where SPP_RUT=@rut 
    and SPP_FECHA_AUTORIZA is not null

--Obtiene los datos de la solicitud con el folio obtenido en la consulta anterior:
	[dbo].[spu_ws_datos_acuerdo_prontopago_ley21674] @folio
