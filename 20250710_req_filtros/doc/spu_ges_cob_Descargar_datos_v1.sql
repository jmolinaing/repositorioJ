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
--197130 total
--Haciendo un union 193.588 reg
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
		--origen varchar(30) not null
		rut_deudor char(10) not null
		, nombre_deudor varchar(100) null
		, email_destinatario varchar(100) null
		, deuda_cotizaciones numeric(15) null
		, monto_cupon numeric(15) null	--**
		, monto_posible_compensar numeric(15) null
		, nombre_ejecutivo varchar(100) null
		, email_ejecutivo varchar(100) null
		, fono_ejecutivo varchar(30) null
		, url_link varchar(100) null
		, url_link1 varchar(100) null
		, url_link2 varchar(100) null
		, fecha_compromiso datetime null
		, monto_compromiso numeric(15) null
		, deuda_lur numeric(15) null
		, deuda_chq numeric(15) null
		, cobrador_asignado_lur_chq numeric(10) null
		, fono_contacto varchar(30) null
		--, primary key (rut_reudor)
	)


--1.- ORIGEN COTIZANTE EMPLEADOR
--(187610 rows affected)
select a.rut rut, sum(a.deuda) deuda
into #origen_cotiz_empl
from
(
--Deuda Cotizaciones afiliados (personas)
select cot_rut as rut, sum(DEC_PACTADO	- DEC_PAGADO) as deuda
from deuda_cotizante 
where epa_rut is null
--and cot_rut = ' 127968284'
group by cot_rut
having sum(DEC_PACTADO	- DEC_PAGADO) > 0
union
--Deuda Cotizaciones Empresas (empleadores)
select epa_rut as rut, sum(DEC_PACTADO	- DEC_PAGADO) as deuda 
from deuda_cotizante 
where epa_rut is not null
--and epa_rut = ' 127968284'
group by epa_rut
having sum(DEC_PACTADO	- DEC_PAGADO) > 0
) a
group by rut


--2.- ORIGEN LUR 
--CONJUNTO LUR  (7491 rows affected)
select DDR_rut rut, sum(deu_monto) deuda_lur
INTO #origen_lur
from dbo.GCDF_DEUDA gd with (nolock)
where deu_monto > 0
and TDE_CODIGO = 1
group by DDR_rut

--2.- ORIGEN CHQ 
--CONJUNTO chq  (2029 rows affected)
select DDR_rut RUT, sum(deu_monto) deuda_chq
INTO #origen_chq
from dbo.GCDF_DEUDA gd with (nolock)
where deu_monto > 0
and TDE_CODIGO = 2
group by DDR_rut


--______________INSERT TABLA FINAL _________________________

-- INSERTAREMOS , POR AHORA, SOLO LOS RUT, CON UN UNION DESCARTAMOS LOS REPETIDOS
INSERT #tabla_final (RUT_DEUDOR)
SELECT RUT FROM #origen_cotiz_empl
UNION
SELECT RUT FROM #origen_lur
UNION
SELECT RUT FROM #origen_chq


--lUEGO QUE TENEMOS EL CONJUNTO FINAL DE RUT SIN REPETIR , HAREMOS UNA TEMPORAL TFU
-- Nota: 20.437 reg pero todos me dan cero.
select dt.cot_rut rut, convert(numeric(12),SUM(ROUND(DTC_MONTO * dbo.f_get_ufmes(getdate()),0)) )  as saldo_tfu 
into #TFU
from DEVOLUCION_TFU_CUOTA dt with (nolock)
join #tabla_final
	on RUT_DEUDOR = dt.cot_rut
where dt.afi_rut is null 
group by dt.cot_rut
	--and cot_rut = @rut




--UPDATE DEUDAS
UPDATE #tabla_final 
SET DEUDA_cotizaciones = #origen_cotiz_empl.DEUDA
from #origen_cotiz_empl
where rut_deudor = #origen_cotiz_empl.rut

UPDATE #tabla_final 
SET DEUDA_lur = #origen_lur.DEUDA_LUR
from #origen_lur
where rut_deudor = #origen_lur.rut

UPDATE #tabla_final 
SET DEUDA_chq = #origen_chq.DEUDA_chq
from #origen_chq
where rut_deudor = #origen_chq.rut

--____________________
-- UPDATE nombre_deudor Y email_destinatario
UPDATE #tabla_final
set nombre_deudor = d.ddr_nombre
--, email_destinatario = [dbo].[f_get_datocontacto](rut_deudor,'email') 
, nombre_ejecutivo = c.cob_nombre
, email_ejecutivo = c.cob_EMAIL
, fono_ejecutivo = c.cob_FONO
, fono_contacto = c.cob_celular
from deudor d with (nolock)
left join deudor_asignado da with (nolock)
	on da.DDR_RUT = D.DDR_RUT
	and (
		(da.DEU_ASIG_DESDE <= GETDATE() 
		and ( da.DEU_ASIG_HASTA > GETDATE() OR da.DEU_ASIG_HASTA IS NULL) 
		)) 
left join cobrador c with (nolock)
	on c.COB_CODIGO = da.COB_CODIGO
where rut_deudor = d.ddr_rut 



UPDATE #tabla_final
set monto_posible_compensar = case when ( (isnull(DEUDA_cotizaciones, 0) + isnull(DEUDA_lur, 0)) >= #tfu.saldo_tfu  ) then  #tfu.saldo_tfu else (isnull(DEUDA_cotizaciones, 0) + isnull(DEUDA_lur, 0)) end
from #tfu
where rut_deudor = #tfu.rut



---Obtener loscompromisos de pago GEC_COMPROM_MONTO	y GEC_COMPROM_FECHA
-- tengo que ir a buscar el ultimo para e rut fecha digita
/*

select * from GESTION_COBRANZA where tgc_codigo=29

 datetime null
		, 

UPDATE #tabla_final 
SET fecha_compromiso = #origen_chq.DEUDA_chq
, monto_compromiso
from 
(

select gc.ddr_rut, GEC_COMPROM_MONTO, GEC_COMPROM_FECHA
from GESTION_COBRANZA gc with (nolock)
join
(
	select ddr_rut, max(GEC_FECDIGITA) GEC_FECDIGITA
	from GESTION_COBRANZA gc with (nolock)
	--join #tabla_final t
	--	on gc.DDR_RUT = t.rut_deudor
	where tgc_codigo=29
	group by ddr_rut
) a
on gc.DDR_RUT = a.DDR_RUT
and gc.GEC_FECDIGITA = a.GEC_FECDIGITA




)





where rut_deudor = #origen_chq.rut
*/

--SELECT * FROM cobrador


--SELECT * FROM #origen_cotiz_empl
--SELECT * FROM #origen_lur
--SELECT * FROM #origen_chq
--SELECT * FROM #TFU
SELECT * FROM #tabla_final



END