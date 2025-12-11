
--texto : CuadrarMontosPesos_

--Obtener casos descuadrados (diferencias)
SELECT D.AFI_RUT, 
	D.MCT_CORRELATIVO, 
	COUNT(*) AS CUOTAS, 
	MAX(M.MCT_MONTO) AS MCT_MONTO, 
	SUM(DTC_MONTO_PESOS) AS DTC_MONTO_PESOS, 
	MAX(M.MCT_MONTO)-SUM(D.DTC_MONTO_PESOS) AS DIFERENCIA1
	,SUM(DTC_MONTO_PESOS_RESP) AS DTC_MONTO_PESOS_RESP 
	, 	MAX(M.MCT_MONTO)-SUM(D.DTC_MONTO_PESOS_RESP) AS DIFERENCIA1
FROM  DEVOLUCION_TFU_CUOTA D 
 JOIN MOVIMIENTO_CTACTE M
		ON D.AFI_RUT = M.AFI_RUT
			AND D.CTA_FECHA_APERTURA = M.CTA_FECHA_APERTURA
			AND D.MCT_CORRELATIVO = M.MCT_CORRELATIVO

--where D.afi_rut in (' 129792701')

GROUP BY D.AFI_RUT, D.MCT_CORRELATIVO
HAVING MAX(M.MCT_MONTO)<> SUM(D.DTC_MONTO_PESOS)
ORDER BY D.AFI_RUT




--Revision de un caso
select * from DEVOLUCION_TFU_CUOTA where AFI_RUT=' 129792701'	and MCT_CORRELATIVO=587 ORDER BY DTC_PERIODO ASC
select sum(dtc_monto_pesos) AS TOTAL_dtc_monto_pesos from DEVOLUCION_TFU_CUOTA where AFI_RUT=' 129792701'	and MCT_CORRELATIVO=587 
select sum(dtc_monto_pesos_RESP) AS TOTAL_dtc_monto_pesos_RESP from DEVOLUCION_TFU_CUOTA where AFI_RUT=' 129792701'	and MCT_CORRELATIVO=587 
select mct_monto from MOVIMIENTO_CTACTE where AFI_RUT=' 129792701'	and MCT_CORRELATIVO=587




---Restaurar valores iniciales
update DEVOLUCION_TFU_CUOTA set DTC_MONTO_PESOS = DTC_MONTO_PESOS_RESP 

--Confeccionar Algoritmo que permita cuadrar el SUM(DTC_MONTO_PESOS) con MOVIMIENTO_CTACTE.MCT_MONTO para cada transacción o caso de la consulta inicial (consulta de diferencias)
--distribuyendo de manera uniforme la diferencia entre las cuotas de cada cada transacción (AFI_RUT, MCT_CORRELATIVO)

texto : CuadrarMontosPesos_