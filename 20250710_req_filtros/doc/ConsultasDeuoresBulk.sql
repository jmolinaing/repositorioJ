




--Deuda Cotizaciones afiliados (personas)
select cot_rut, sum(DEC_PACTADO	- DEC_PAGADO) as deuda
--, [dbo].[f_get_datocontacto](cot_rut,'mail') as deuda 
from deuda_cotizante 
where epa_rut is null
group by cot_rut
having sum(DEC_PACTADO	- DEC_PAGADO) > 0

--Deuda Cotizaciones Empresas (empleadores)
select epa_rut, sum(DEC_PACTADO	- DEC_PAGADO) as deuda 
from deuda_cotizante 
where epa_rut is not null
group by epa_rut
having sum(DEC_PACTADO	- DEC_PAGADO) > 0

--Deuda LUR (Ley de Urgencia) y Cheques Protestados
--ley de urgencia: tipo 1 TIPO_DEUDA
-- tipo 2 cheques rotestados TIPO_DEUDA


select * from deudor

SELECT  CASE WHEN CTA_CODIGO='      101060403' THEN 1 ELSE 2 END as TIPO_DEUDA
			,MOVIMIENTO.EMO_RUT
			,MOVIMIENTO.TID_CODIGO 
			,MOVIMIENTO.DOC_FOLIO
			,MOVIMIENTO.DOC_FECHADOC
			,MOVIMIENTO.MOV_CUOTA
			,SUM(MOV_DEBE) - SUM(MOV_HABER)    AS SALDO
			,CONVERT(NUMERIC(5),0) AS CUOTAS
	   FROM CONTAWIN_NMV.DBO.COMPROBANTE AS COMPROBANTE (nolock)  
		  JOIN CONTAWIN_NMV.DBO.MOVIMIENTO AS MOVIMIENTO (nolock)
			 ON MOVIMIENTO.EMP_CODIGO = COMPROBANTE.EMP_CODIGO
			 and MOVIMIENTO.COM_CORREL = COMPROBANTE.COM_CORREL  
		  JOIN CONTAWIN_NMV.DBO.CUENTA AS CUENTA (nolock)
			 ON MOVIMIENTO.EMP_CODIGO_CT = CUENTA.EMP_CODIGO
			 and MOVIMIENTO.CTA_CORREL_CT = CUENTA.CTA_CORREL   
	   WHERE ( CUENTA.EMP_CODIGO = 5 )
		  and ( MOVIMIENTO.EJE_INICIO < getdate() )
		  and ( MOVIMIENTO.MOV_FECCIERRE >= getdate()  )
		  and CTA_CODIGO in ('      101060403', -- Credito Ley de Urgencia 
							'      10106008K',--- Cheques Protestados
							'      101060438'
							)--- Cheques En Cobranza Judicial
		  and MOVIMIENTO.emo_rut is not null
		  AND CASE WHEN CTA_CODIGO ='      101060403' AND MOVIMIENTO.DOC_FECHADOC<='20170401' THEN 'N' ELSE 'S' END ='S' --EXCLUYE LEY DE URGENCIA DE LA EX MASVIDA
	   GROUP BY CASE WHEN CTA_CODIGO='      101060403' THEN 1 ELSE 2 END 
			,MOVIMIENTO.TID_CODIGO 
			,MOVIMIENTO.EMO_RUT
			,MOVIMIENTO.DOC_FOLIO
			,MOVIMIENTO.DOC_FECHADOC
			,MOVIMIENTO.MOV_CUOTA
		HAVING SUM(MOV_DEBE) - SUM(MOV_HABER) > 0
	order by MOVIMIENTO.EMO_RUT




----Saldo de restitucion TFU:

select @saldo_restitucion = convert(numeric(12),SUM(ROUND(DTC_MONTO * dbo.f_get_ufmes(getdate()),0)) )
from DEVOLUCION_TFU_CUOTA 
where afi_rut is null 
	and cot_rut = @rut


---Obtener loscompromisos de pago GEC_COMPROM_MONTO	y GEC_COMPROM_FECHA
-- tengo que ir a buscar el ultimo para e rut fecha digita

select * from GESTION_COBRANZA where tgc_codigo=29

--Obtener el cobrador asignado a LUR o CHP
select * from GCDF_DEUDOR_ASIGNADO