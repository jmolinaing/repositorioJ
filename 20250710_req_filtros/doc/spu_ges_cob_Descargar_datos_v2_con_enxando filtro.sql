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
-- total 193.588 reg en 4:37 min
execute spu_ges_cob_Descargar_datos_v2
--396
*/


ALTER procedure [dbo].[spu_ges_cob_Descargar_datos_v2] 
@epl_codigo varchar(50) = null
as
BEGIN	
	set nocount on;
	
	declare @PrimerDiaDelMes datetime
	declare @PrimerDiaDelMesSgte datetime

	SELECT @PrimerDiaDelMes = CAST(DATEADD(month, DATEDIFF(month, 0, GETDATE()), 0) AS DATE) 
	SELECT @PrimerDiaDelMesSgte = CAST(DATEADD(month, DATEDIFF(month, 0, GETDATE()) + 1, 0) AS DATE) 


	IF OBJECT_ID(N'tempdb..#tabla_final', N'U') IS NOT NULL DROP TABLE #tabla_final
	IF OBJECT_ID(N'tempdb..#origen_cotiz_empl', N'U') IS NOT NULL DROP TABLE #origen_cotiz_empl
	IF OBJECT_ID(N'tempdb..#origen_lur', N'U') IS NOT NULL DROP TABLE #origen_lur
	IF OBJECT_ID(N'tempdb..#origen_chq', N'U') IS NOT NULL DROP TABLE #origen_chq
	IF OBJECT_ID(N'tempdb..TFU', N'U') IS NOT NULL DROP TABLE #TFU

	--1.- Se crea #tabla_final: contiene el resultado salida de este sp, concentrara los rut de los origenes: COTIZANTE EMPLEADOR, ley lur y cheques.
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
		, f_supervisor_asig numeric(4) null
		, f_gestion29 varchar(2) null
		, f_ciu_codigo_reside numeric(4) null 
		, f_deuda_lur_con_credito varchar(2) null
		, f_edad_deudor numeric(4) null
		, f_compromiso_vencido datetime null
		, primary key (rut_deudor)
	)


--1.- ORIGEN COTIZANTE EMPLEADOR
--(187610 rows affected)
select a.rut rut, sum(a.deuda) deuda
into #origen_cotiz_empl
from
(
--Deuda Cotizaciones afiliados (personas)
select top 100 cot_rut as rut, sum(DEC_PACTADO	- DEC_PAGADO) as deuda
from deuda_cotizante with (nolock)
where epa_rut is null
--and cot_rut = ' 127968284'
group by cot_rut
having sum(DEC_PACTADO	- DEC_PAGADO) > 0
union
--Deuda Cotizaciones Empresas (empleadores)
select top 100 epa_rut as rut, sum(DEC_PACTADO	- DEC_PAGADO) as deuda 
from deuda_cotizante with (nolock) 
where epa_rut is not null
--and epa_rut = ' 127968284'
group by epa_rut
having sum(DEC_PACTADO	- DEC_PAGADO) > 0
) a
group by rut

-- Crear índice no agrupado en la tabla temporal
CREATE NONCLUSTERED INDEX IX_origen_cotiz_empl_rut ON #origen_cotiz_empl (rut)


--2.- ORIGEN LUR 
--CONJUNTO LUR  (7491 rows affected)
select top 100 DDR_rut rut, sum(deu_monto) deuda_lur
INTO #origen_lur
from dbo.GCDF_DEUDA gd with (nolock)
where deu_monto > 0
and TDE_CODIGO = 1
group by DDR_rut

-- Crear índice no agrupado en la tabla temporal
CREATE NONCLUSTERED INDEX IX_origen_lur_rut ON #origen_lur (rut)

--2.- ORIGEN CHQ 
--CONJUNTO chq  (2029 rows affected)
select top 100 DDR_rut RUT, sum(deu_monto) deuda_chq
INTO #origen_chq
from dbo.GCDF_DEUDA gd with (nolock)
where deu_monto > 0
and TDE_CODIGO = 2
group by DDR_rut


-- Crear índice no agrupado en la tabla temporal
CREATE NONCLUSTERED INDEX IX_origen_chq_rut ON #origen_chq (rut)

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
select TOP 100 dt.cot_rut rut, convert(numeric(12),SUM(ROUND(DTC_MONTO * dbo.f_get_ufmes(getdate()),0)) )  as saldo_tfu 
into #TFU
from DEVOLUCION_TFU_CUOTA dt with (nolock)
join #tabla_final
	on RUT_DEUDOR = dt.cot_rut
where dt.afi_rut is null 
group by dt.cot_rut
	--and cot_rut = @rut


-- Crear índice no agrupado en la tabla temporal
CREATE NONCLUSTERED INDEX IX_TFU_rut ON #TFU (rut)


--UPDATE DEUDA_cotizaciones
UPDATE #tabla_final 
SET DEUDA_cotizaciones = #origen_cotiz_empl.DEUDA
from #origen_cotiz_empl
where rut_deudor = #origen_cotiz_empl.rut

--UPDATE DEUDA_lur
UPDATE #tabla_final 
SET DEUDA_lur = #origen_lur.DEUDA_LUR
from #origen_lur
where rut_deudor = #origen_lur.rut

--UPDATE DEUDA_chq
UPDATE #tabla_final 
SET DEUDA_chq = #origen_chq.DEUDA_chq
from #origen_chq
where rut_deudor = #origen_chq.rut

--____________________
--select * from deudor
-- UPDATE nombre_deudor, email_destinatario, nombre_ejecutivo, email_ejecutivo, fono_ejecutivo, fono_contacto
UPDATE #tabla_final
set nombre_deudor = d.ddr_nombre
--, email_destinatario = [dbo].[f_get_datocontacto](rut_deudor,'email') 
, nombre_ejecutivo = c.cob_nombre
, email_ejecutivo = c.cob_EMAIL
, fono_ejecutivo = c.cob_FONO
, fono_contacto = c.cob_celular
, f_ciu_codigo_reside = d.CIU_CODIGO
, f_edad_deudor = dbo.f_edad((SELECT TOP 1 BNF_NACTO FROM BENEFICIARIO WITH (NOLOCK) WHERE BNF_RUT = d.DDR_RUT), GETDATE()) 
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


-- UPDATE monto_posible_compensar
UPDATE #tabla_final
set monto_posible_compensar = case when ( (isnull(DEUDA_cotizaciones, 0) + isnull(DEUDA_lur, 0)) >= #tfu.saldo_tfu  ) then  #tfu.saldo_tfu else (isnull(DEUDA_cotizaciones, 0) + isnull(DEUDA_lur, 0)) end
from #tfu
where rut_deudor = #tfu.rut



---Obtener loscompromisos de pago GEC_COMPROM_MONTO	y GEC_COMPROM_FECHA
-- tengo que ir a buscar el ultimo para e rut fecha digita


--select * from GESTION_COBRANZA where tgc_codigo=29


-- UPDATE fecha_compromiso, monto_compromiso
UPDATE #tabla_final 
SET fecha_compromiso = m.GEC_COMPROM_FECHA
, monto_compromiso = m.GEC_COMPROM_MONTO
from 
(

		select gc.ddr_rut rut, GEC_COMPROM_MONTO, GEC_COMPROM_FECHA
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
) m
where rut_deudor = m.rut


select distinct cob_codigo, ddr_rut rut--, deu_asig_desde
into #cob_asig
FROM GCDF_DEUDOR_ASIGNADO DAU with (NOLOCK)
WHERE  
(
	deu_asig_desde <= getdate() 
	and (deu_asig_hasta >= getdate() or deu_asig_hasta is null)
	
)  


--UPDATE cobrador_asignado_lur_chq
UPDATE #tabla_final 
SET cobrador_asignado_lur_chq = #cob_asig.COB_CODIGO
from #cob_asig
where rut_deudor = #cob_asig.rut




-- FILTROS COMO COLUMNAS EN LA SALIDA PARA FITRAR
		
--	Equipo	
--Supervisor	Obtener el vigente desde la tabla COBRADOR_SUP_ASIG

select c.cob_codigo cob_codigo, c.sco_codigo sco_codigo, c.csa_desde csa_desde
INTO #f_supervisor_asig
from COBRADOR_SUP_ASIG c with (nolock)
join
(
	select cob_codigo, max(csa_desde) as csa_desde	/*asignacion max*/
	from COBRADOR_SUP_ASIG with (nolock)
	where csa_desde <= getdate()
	group by cob_codigo
) a
on a.cob_codigo = c.cob_codigo
and a.csa_desde = c.CSA_DESDE


--UPDATE cobrador_asignado_lur_chq
UPDATE #tabla_final 
SET f_supervisor_asig = #f_supervisor_asig.sco_codigo
from #f_supervisor_asig
where cobrador_asignado_lur_chq = #f_supervisor_asig.cob_codigo

/*
	Tipo Deudor	Si tiene contrato no vigente es VIGENTE, si tiene contrato pero no está vigente es NO VIGENTE y en otro caso es EMPRESA
*/

--	Gestion 29	SELECT * FROM GESTION_COBRANZA WHERE TGC_CODIGO=29 (en el mes en curso)


select ddr_rut rut , case when count(*) > 0 then 'Si' else 'No' end as gestion29
into #f_gestion29
from GESTION_COBRANZA gc with (nolock)
where tgc_codigo = 29
and GEC_FECHA_GES >= @PrimerDiaDelMes
and GEC_FECHA_GES < @PrimerDiaDelMesSgte
group by ddr_rut

UPDATE #tabla_final 
SET f_gestion29 = #f_gestion29.gestion29
from #f_gestion29
where rut_deudor = #f_gestion29.rut


--	Compromiso Vencido	SELECT max(GEC_COMPROM_FECHA) FROM GESTION_COBRANZA  where DDR_RUT=@RUT 

select ddr_rut rut , max(GEC_COMPROM_FECHA) fecha		--se demora
into #f_compromiso_vencido
from GESTION_COBRANZA gc with (nolock)
where GEC_COMPROM_FECHA is not null
group by ddr_rut

UPDATE #tabla_final 
SET f_compromiso_vencido = #f_compromiso_vencido.fecha
from #f_compromiso_vencido
where rut_deudor = #f_compromiso_vencido.rut



/*	Tipos Deuda (DNP, IP, DPP)	"SELECT DISTINCT 
	CASE WHEN DEC_TIPO_DEUDA='DNP' THEN  DEC_TIPO_DEUDA 
	 WHEN DEC_TIPO_DEUDA='NP' AND DEC_PAGADO>0 THEN 'DPP' 
	 WHEN DEC_TIPO_DEUDA='NP' AND DEC_PAGADO=0 THEN 'IP' END 
FROM DEUDA_COTIZANTE"

*/
--	Menor Periodo Deuda (cotiozaciones)	DEUDA_COTIZANTE, MIN(PPC_PERIODO)
--	Mayor Periodo Deuda (cotiozaciones)	DEUDA_COTIZANTE, MAX(PPC_PERIODO)
--select * from deuda_cotizante

--select top 100 cot_rut as rut, MIN(PPC_PERIODO) as min_ppc_periodo, MAX(PPC_PERIODO) max_ppc_periodo
--from deuda_cotizante with (nolock)
--where epa_rut is null
--group by cot_rut
--having sum(DEC_PACTADO	- DEC_PAGADO) > 0




	--Ciudad Residencia	CIU_CODIGO del DEUDOR



--	Deuda LUR con Crédito	select DEU_CUOTAS, * from GCDF_DEUDA, f_deuda_lur_con_credito

select ddr_rut rut , case when sum(isnull(DEU_CUOTAS,0)) > 0 then 'Si' else 'No' end as deuda_lur_con_credito
into #f_deuda_lur_con_credito
from GCDF_DEUDA gc with (nolock)
group by ddr_rut

UPDATE #tabla_final 
SET f_deuda_lur_con_credito = #f_deuda_lur_con_credito.deuda_lur_con_credito
from #f_deuda_lur_con_credito
where rut_deudor = #f_deuda_lur_con_credito.rut

/*
	Tipo Empresa	
	Rubro	
	Edad Deudor	Diferencia en meses/12 de la fecha de nacimiento que está en BENEFICIARIO con respecto a la fecha actual

*/





--SELECT * FROM #origen_cotiz_empl
--SELECT * FROM #origen_lur
--SELECT * FROM #origen_chq
--SELECT * FROM #TFU
SELECT * FROM #tabla_final



END