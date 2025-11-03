/* ======================================================================================== 
 tipo de objeto		:	procedimiento almacenado                                        
 nombre del objeto	:	spu_ges_cob_Descargar_datos                                                                                                  
 parametros			:	@epl_codigo varchar(50) = código de plantilla.			                                                                                 
 creado por			:	jorge molina													
 fecha creación		:	12-2024                                                      
 descripción		:	muestra el valor más confiable del parametro direccion, fono, email																					
========================================================================================
*/
/*
--191.130 17seg
execute spu_ges_cob_Descargar_datos


select * from cobrador
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
		origen varchar(30) not null
		, rut_deudor char(10) not null
		, nombre_deudor varchar(100) null
		, email_destinatario varchar(100) null
		, deuda_cotizaciones numeric(15) null
		, monto_cupon numeric(15) null	--**
		, monto_posible_compensar numeric(15) null
		, nombre_ejecutivo varchar(100) null
		, email_ejecutivo varchar(100) null
		, fono_ejecutivo varchar(20) null
		, url_link varchar(100) null
		, url_link1 varchar(100) null
		, url_link2 varchar(100) null
		, fecha_compromiso datetime null
		, monto_compromiso numeric(15) null
		, deuda_lur numeric(15) null
		, deuda_chp numeric(15) null
		, cobrador_asignado_lur_chp numeric(10) null
		, fono_contacto varchar(20) null
		--, primary key (rut_reudor)
	)


--select * from deuda_cotizante 
--select * from deudor 
--select * from deudor_asignado 
--select * from cobrador


--select [dbo].[f_get_datocontacto]  ' 130267599','mail'
--Deuda Cotizaciones afiliados (personas)
--(158680 rows affected)
--(158680 rows affected) join deudor 18 sg
--(158680 rows affected) otros  join deudor 18 sg
INSERT INTO #tabla_final (origen, rut_deudor, nombre_deudor, email_destinatario,Deuda_Cotizaciones, nombre_ejecutivo)
select 
--top 5 
'personas', cot_rut
,d.ddr_nombre
, [dbo].[f_get_datocontacto](cot_rut,'email') email
, sum(DEC_PACTADO	- DEC_PAGADO) as deuda
, c.cob_nombre
from deuda_cotizante dc with (nolock)
join deudor d with (nolock)
	on dc.cot_rut = d.ddr_rut 
left join deudor_asignado da with (nolock)
	on da.DDR_RUT = dc.cot_rut
	and (
		(da.DEU_ASIG_DESDE <= GETDATE() 
		and ( da.DEU_ASIG_HASTA > GETDATE() OR da.DEU_ASIG_HASTA IS NULL) 
		)) 
left join cobrador c with (nolock)
	on c.COB_CODIGO = da.COB_CODIGO
where epa_rut is null
group by cot_rut
, d.ddr_nombre
, c.cob_nombre
having sum(DEC_PACTADO	- DEC_PAGADO) > 0


--Deuda Cotizaciones Empresas (empleadores)
--(29055 rows affected) 2 seg sin join
--(29791 rows affected) 5 seg

--select *  from ENTIDAD_PAGADORA

INSERT INTO #tabla_final (origen, rut_deudor, nombre_deudor, email_destinatario,Deuda_Cotizaciones)
 select top 5 'empleadores'
, dc.epa_rut
, ep.epa_razon
, [dbo].[f_get_datocontacto](dc.epa_rut,'email') email
, sum(DEC_PACTADO	- DEC_PAGADO) as deuda 
from deuda_cotizante dc with (nolock)
left JOIN ENTIDAD_PAGADORA ep with (nolock)		--left o no left		
  ON ep.EPA_RUT = dc.EPA_RUT
	AND ep.EPA_CORREL = dc.EPA_CORREL
where dc.epa_rut is not null
group by dc.epa_rut
, ep.epa_razon
having sum(DEC_PACTADO	- DEC_PAGADO) > 0



--select * from CONTAWIN_NMV.DBO.COMPROBANTE
--select * from CONTAWIN_NMV.DBO.MOVIMIENTO

--Deuda LUR (Ley de Urgencia) y Cheques Protestados
--ley de urgencia: tipo 1 TIPO_DEUDA
-- tipo 2 cheques rotestados TIPO_DEUDA
--(3395 rows affected) 0 seg  sin join adicionales




--INSERT INTO #tabla_final (origen, rut_deudor, Deuda_Cotizaciones)
----SELECT  CASE WHEN CTA_CODIGO='      101060403' THEN 1 ELSE 2 END as TIPO_DEUDA
--SELECT  CASE WHEN CTA_CODIGO='      101060403' THEN 'Ley de Urgencia' ELSE 'Cheques Protestados' END as TIPO_DEUDA
--			,MOVIMIENTO.EMO_RUT
--			--,MOVIMIENTO.TID_CODIGO 
--			--,MOVIMIENTO.DOC_FOLIO
--			--,MOVIMIENTO.DOC_FECHADOC
--			--,MOVIMIENTO.MOV_CUOTA

--			, EMO_RAZON
--			,SUM(MOV_DEBE) - SUM(MOV_HABER)    AS SALDO
--			--,CONVERT(NUMERIC(5),0) AS CUOTAS
--	   FROM CONTAWIN_NMV.DBO.COMPROBANTE AS COMPROBANTE (nolock)  
--		  JOIN CONTAWIN_NMV.DBO.MOVIMIENTO AS MOVIMIENTO (nolock)
--			 ON MOVIMIENTO.EMP_CODIGO = COMPROBANTE.EMP_CODIGO
--			 and MOVIMIENTO.COM_CORREL = COMPROBANTE.COM_CORREL  
--		  JOIN CONTAWIN_NMV.DBO.CUENTA AS CUENTA (nolock)
--			 ON MOVIMIENTO.EMP_CODIGO_CT = CUENTA.EMP_CODIGO
--			 and MOVIMIENTO.CTA_CORREL_CT = CUENTA.CTA_CORREL   


--	   WHERE ( CUENTA.EMP_CODIGO = 5 )
--		  and ( MOVIMIENTO.EJE_INICIO < getdate() )
--		  and ( MOVIMIENTO.MOV_FECCIERRE >= getdate()  )
--		  and CTA_CODIGO in ('      101060403', -- Credito Ley de Urgencia 
--							'      10106008K',--- Cheques Protestados
--							'      101060438'
--							)--- Cheques En Cobranza Judicial
--		  and MOVIMIENTO.emo_rut is not null
--		  AND CASE WHEN CTA_CODIGO ='      101060403' AND MOVIMIENTO.DOC_FECHADOC<='20170401' THEN 'N' ELSE 'S' END ='S' --EXCLUYE LEY DE URGENCIA DE LA EX MASVIDA
--	  -- GROUP BY CASE WHEN CTA_CODIGO='      101060403' THEN 1 ELSE 2 END 
--	   GROUP BY CASE WHEN CTA_CODIGO='      101060403'  THEN 'Ley de Urgencia' ELSE 'Cheques Protestados' END 
--			--,MOVIMIENTO.TID_CODIGO 
--			,MOVIMIENTO.EMO_RUT
--			--,MOVIMIENTO.DOC_FOLIO
--			--,MOVIMIENTO.DOC_FECHADOC
--			--,MOVIMIENTO.MOV_CUOTA
--		HAVING SUM(MOV_DEBE) - SUM(MOV_HABER) > 0
--	order by MOVIMIENTO.EMO_RUT


--		SELECT top 1 EMO_RAZON
--		into :ls_nombre
--		FROM ENTIDAD_MOVIMIENTO with (NOLOCK)
--		WHERE EMO_RUT = :ls_rut

--(20746 rows affected)sin join 3 seg
--(20746 rows affected) con join
--select distinct tde_codigo from GCDF_DEUDA
--select * from GCDF_DEUDA
--select * from deudor

INSERT INTO #tabla_final (origen, rut_deudor, nombre_deudor, email_destinatario,Deuda_Cotizaciones)
select top 5
case gd.tde_codigo when 1 then 'Ley de Urgencia' ELSE 'Cheques Protestados' END as TIPO_DEUDA
, gd.ddr_rut 
, d.DDR_NOMBRE
, [dbo].[f_get_datocontacto]( gd.ddr_rut,'email') email
, deu_monto 
from dbo.GCDF_DEUDA gd with (nolock)
join deudor d with (nolock)
	on gd.ddr_rut = d.ddr_rut 



SELECT * FROM #tabla_final



END