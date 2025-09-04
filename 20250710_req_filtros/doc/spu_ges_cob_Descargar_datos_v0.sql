/* 
======================================================================================== 
 tipo de objeto		:	procedimiento almacenado                                        
 nombre del objeto	:	spu_ges_cob_Descargar_datos                                                                                                  
 parametros			:	@epl_codigo varchar(50) = código de plantilla.			                                                                                 
 creado por			:	jorge molina													
 fecha creación		:	12-2024                                                      
 descripción		:	muestra el valor más confiable del parametro direccion, fono, email																					
========================================================================================
*/
/*
execute spu_ges_cob_Descargar_datos
*/



ALTER procedure [dbo].[spu_ges_cob_Descargar_datos] 
@epl_codigo varchar(50) = null
as
BEGIN	
	set nocount on;

	IF OBJECT_ID(N'tempdb..#tabla_final', N'U') IS NOT NULL DROP TABLE #tabla_final

	--Primera tabla traspaso: se insertaran todos los registros de los ORIGENES
	create table #tabla_final
	(
		ORIGEN varchar(30) not null
		, rut_deudor char(10) not null
		, Nombre_Deudor varchar(100) null
		, email_destinatario varchar(100) null
		, Deuda_Cotizaciones numeric(15) null
		, Monto_Cupon numeric(15) null	--**
		, Monto_Posible_compensar numeric(15) null
		, Nombre_Ejecutivo varchar(100) null
		, eMail_Ejecutivo varchar(100) null
		, Fono_Ejecutivo varchar(20) null
		, URL_Link varchar(100) null
		, URL_Link1 varchar(100) null
		, URL_Link2 varchar(100) null
		, Fecha_Compromiso datetime null
		, Monto_Compromiso numeric(15) null
		, Deuda_LUR numeric(15) null
		, Deuda_CHP numeric(15) null
		, Cobrador_Asignado_LUR_CHP numeric(10) null
		, Fono_contacto varchar(20) null
		--, primary key (rut_reudor)
	)


--Deuda Cotizaciones afiliados (personas)
INSERT INTO #tabla_final (origen, rut_deudor, Deuda_Cotizaciones)
select 'personas', cot_rut, sum(DEC_PACTADO	- DEC_PAGADO) as deuda
--, [dbo].[f_get_datocontacto](cot_rut,'mail') as deuda 
from deuda_cotizante 
where epa_rut is null
group by cot_rut
having sum(DEC_PACTADO	- DEC_PAGADO) > 0


--Deuda Cotizaciones Empresas (empleadores)
INSERT INTO #tabla_final (origen, rut_deudor, Deuda_Cotizaciones)
select 'empleadores', epa_rut, sum(DEC_PACTADO	- DEC_PAGADO) as deuda 
from deuda_cotizante 
where epa_rut is not null
group by epa_rut
having sum(DEC_PACTADO	- DEC_PAGADO) > 0

--Deuda LUR (Ley de Urgencia) y Cheques Protestados
--ley de urgencia: tipo 1 TIPO_DEUDA
-- tipo 2 cheques rotestados TIPO_DEUDA
INSERT INTO #tabla_final (origen, rut_deudor, Deuda_Cotizaciones)
--SELECT  CASE WHEN CTA_CODIGO='      101060403' THEN 1 ELSE 2 END as TIPO_DEUDA
SELECT  CASE WHEN CTA_CODIGO='      101060403' THEN 'Ley de Urgencia' ELSE 'Cheques Protestados' END as TIPO_DEUDA
			,MOVIMIENTO.EMO_RUT
			--,MOVIMIENTO.TID_CODIGO 
			--,MOVIMIENTO.DOC_FOLIO
			--,MOVIMIENTO.DOC_FECHADOC
			--,MOVIMIENTO.MOV_CUOTA
			,SUM(MOV_DEBE) - SUM(MOV_HABER)    AS SALDO
			--,CONVERT(NUMERIC(5),0) AS CUOTAS
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
	  -- GROUP BY CASE WHEN CTA_CODIGO='      101060403' THEN 1 ELSE 2 END 
	   GROUP BY CASE WHEN CTA_CODIGO='      101060403'  THEN 'Ley de Urgencia' ELSE 'Cheques Protestados' END 
			--,MOVIMIENTO.TID_CODIGO 
			,MOVIMIENTO.EMO_RUT
			--,MOVIMIENTO.DOC_FOLIO
			--,MOVIMIENTO.DOC_FECHADOC
			--,MOVIMIENTO.MOV_CUOTA
		HAVING SUM(MOV_DEBE) - SUM(MOV_HABER) > 0
	order by MOVIMIENTO.EMO_RUT






	SELECT * FROM #tabla_final



END