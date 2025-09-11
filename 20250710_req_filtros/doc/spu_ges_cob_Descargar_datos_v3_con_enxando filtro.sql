/* ======================================================================================== 
 tipo de objeto		:	procedimiento almacenado                                        
 nombre del objeto	:	spu_ges_cob_Descargar_datos                                                                                                  
 parametros			:	@epl_codigo varchar(50) = código de plantilla.			                                                                                 
 creado por			:	jorge molina													
 fecha creación		:	                                                    
 descripción		:																		
========================================================================================
*/

/*
execute spu_ges_cob_Descargar_datos_
v3
--193.588 EN 7:15 SEG, 5:45, 5MIN
*/

ALTER procedure [dbo].[spu_ges_cob_Descargar_datos_v3] 
@epl_codigo varchar(50) = null
as
BEGIN	
	set nocount on;
	
	declare @PrimerDiaDelMes datetime
	declare @PrimerDiaDelMesSgte datetime

	SELECT @PrimerDiaDelMes = CAST(DATEADD(month, DATEDIFF(month, 0, GETDATE()), 0) AS DATE) 
	SELECT @PrimerDiaDelMesSgte = CAST(DATEADD(month, DATEDIFF(month, 0, GETDATE()) + 1, 0) AS DATE) 

	if object_id('tempdb..#tabla_final', 'u') is not null drop table #tabla_final
	if object_id('tempdb..#origen_cotiz_empl', 'u') is not null drop table #origen_cotiz_empl
	if object_id('tempdb..#origen_lur', 'u') is not null drop table #origen_lur
	if object_id('tempdb..#origen_chq', 'u') is not null drop table #origen_chq
	if object_id('tempdb..#tfu', 'u') is not null drop table #tfu
	if object_id('tempdb..#compromiso', 'u') is not null drop table #compromiso
	if object_id('tempdb..#cobrador_asig', 'u') is not null drop table #cobrador_asig
	if object_id('tempdb..#f_supervisor_asig', 'u') is not null drop table #f_supervisor_asig 
	if object_id('tempdb..#f_vigencia_personas', 'u') is not null drop table #f_vigencia_personas
	if object_id('tempdb..#f_gestion29', 'u') is not null drop table #f_gestion29
	if object_id('tempdb..#f_compromiso_vencido', 'u') is not null drop table #f_compromiso_vencido
	if object_id('tempdb..#f_tipo_deuda', 'u') is not null drop table #f_tipo_deuda
	if object_id('tempdb..#f_menor_mayor_deuda', 'u') is not null drop table #f_menor_mayor_deuda
	if object_id('tempdb..#f_deuda_lur_con_credito', 'u') is not null drop table #f_deuda_lur_con_credito


	--1.- SE CREA #TABLA_FINAL: CONTIENE EL RESULTADO SALIDA DE ESTE SP, CONCENTRARA LOS RUT DE LOS 3 ORIGENES: COTIZANTE EMPLEADOR, LEY LUR Y CHEQUES.

	create table #tabla_final
	(
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
		, f_dnp varchar(4) null
		, f_dpp varchar(4) null
		, f_ip varchar(4) null
		, f_menor_per_deuda datetime null
		, f_mayor_per_deuda datetime null
		, f_tipo_deudor varchar(30) null
		--, primary key (rut_deudor)
	)

--TABLAS ORIGENES _____________________________________________________________________

--1.- ORIGEN1: COTIZANTE EMPLEADOR

select a.rut rut, sum(a.deuda) deuda
into #origen_cotiz_empl
from
(
		--deuda cotizaciones afiliados (personas)
		select 
		--top 100 
		cot_rut as rut, sum(dec_pactado	- dec_pagado) as deuda
		from deuda_cotizante with (nolock)
		where epa_rut is null
		--and cot_rut = ' 127968284'
		group by cot_rut
		having sum(dec_pactado	- dec_pagado) > 0
		union
		--deuda cotizaciones empresas (empleadores)
		select
		--top 100 
		epa_rut as rut, sum(dec_pactado	- dec_pagado) as deuda 
		from deuda_cotizante with (nolock) 
		where epa_rut is not null
		--and epa_rut = ' 127968284'
		group by epa_rut
		having sum(dec_pactado	- dec_pagado) > 0
) a
group by rut

-- Crear índice no agrupado después de insertar los datos para evitar ralentizaciones durante la inserción y acelerar consultas posteriores.
create nonclustered index ix_origen_cotiz_empl_rut on #origen_cotiz_empl (rut)


--2.- ORIGEN2: LUR 

select 
--top 100 
DDR_rut rut, sum(deu_monto) deuda_lur
INTO #origen_lur
from dbo.GCDF_DEUDA gd with (nolock)
where deu_monto > 0
and TDE_CODIGO = 1
group by DDR_rut

-- Crear índice no agrupado después de insertar los datos para evitar ralentizaciones durante la inserción y acelerar consultas posteriores.
create nonclustered index ix_origen_lur_rut on #origen_lur (rut)

--3.- ORIGEN3: CHQ 

select
--top 100 
DDR_rut RUT, sum(deu_monto) deuda_chq
INTO #origen_chq
from dbo.GCDF_DEUDA gd with (nolock)
where deu_monto > 0
and TDE_CODIGO = 2
group by DDR_rut

-- Crear índice no agrupado después de insertar los datos para evitar ralentizaciones durante la inserción y acelerar consultas posteriores.
create nonclustered index ix_origen_chq_rut on #origen_chq (rut)

--TABLAS ORIGENES _____________________________________________________________________



--______________INSERT TABLA FINAL _________________________

-- INSERTAREMOS , POR AHORA, EL CONJUNTO TOTAL DE RUTS DE LOS 3 ORIGENES CON LOS QUE VOY A TRABAJAR, CON UN UNION DESCARTAMOS LOS REPETIDOS
insert #tabla_final (rut_deudor)
select rut from #origen_cotiz_empl
union
select rut from #origen_lur
union
select rut from #origen_chq

-- crear índice no agrupado después de insertar los datos para evitar ralentizaciones durante la inserción y acelerar consultas posteriores.
create nonclustered index ix_tabla_final_rut on #tabla_final (rut_deudor)

--______________INSERT TABLA FINAL _________________________


--LUEGO QUE TENEMOS EL CONJUNTO FINAL DE RUT SIN REPETIR , HAREMOS UNA TEMPORAL TFU
-- Nota: 20.437 reg pero todos me dan cero.
select
--top 100 
dt.cot_rut rut, convert(numeric(12),sum(round(dtc_monto * dbo.f_get_ufmes(getdate()),0)) )  as saldo_tfu 
into #tfu
from devolucion_tfu_cuota dt with (nolock)
join #tabla_final
	on rut_deudor = dt.cot_rut
where dt.afi_rut is null 
group by dt.cot_rut
	--and cot_rut = @rut

-- crear índice no agrupado después de insertar los datos para evitar ralentizaciones durante la inserción y acelerar consultas posteriores.
create nonclustered index ix_tfu_rut on #tfu (rut)

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

-- UPDATE nombre_deudor, email_destinatario, nombre_ejecutivo, email_ejecutivo, fono_ejecutivo, fono_contacto, CIU_CODIGO, EDAD
UPDATE #tabla_final
set nombre_deudor = d.ddr_nombre
--, email_destinatario = [dbo].[f_get_datocontacto](rut_deudor,'email') 
, nombre_ejecutivo = c.cob_nombre
, email_ejecutivo = c.cob_EMAIL
, fono_ejecutivo = c.cob_FONO
, fono_contacto = c.cob_celular
, f_ciu_codigo_reside = d.CIU_CODIGO		----Ciudad Residencia	CIU_CODIGO del DEUDOR
, f_edad_deudor = dbo.f_edad((SELECT TOP 1 BNF_NACTO FROM BENEFICIARIO WITH (NOLOCK) WHERE BNF_RUT = d.DDR_RUT), GETDATE())   --Edad Deudor	Diferencia en meses/12 de la fecha de nacimiento que está en BENEFICIARIO con respecto a la fecha actual
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



--- Obtener loscompromisos de pago GEC_COMPROM_MONTO	y GEC_COMPROM_FECHA, tengo que ir a buscar el ultimo para e rut fecha digita

	select gc.ddr_rut rut, gc.GEC_COMPROM_MONTO monto, gc.GEC_COMPROM_FECHA fecha
	into #compromiso
	from GESTION_COBRANZA gc with (nolock)
	join
	(
		select ddr_rut, max(GEC_FECDIGITA) GEC_FECDIGITA
		from GESTION_COBRANZA gc with (nolock)
		join #tabla_final t
			on gc.DDR_RUT = t.rut_deudor
		where tgc_codigo=29
		group by ddr_rut
	) a
	on gc.DDR_RUT = a.DDR_RUT
	and gc.GEC_FECDIGITA = a.GEC_FECDIGITA

-- crear índice no agrupado después de insertar los datos para evitar ralentizaciones durante la inserción y acelerar consultas posteriores.
create nonclustered index ix_compromiso_rut on #compromiso (rut)


-- UPDATE fecha_compromiso, monto_compromiso
UPDATE #tabla_final 
SET fecha_compromiso = #compromiso.fecha
, monto_compromiso = #compromiso.monto
from #compromiso
where rut_deudor = #compromiso.rut

--UPDATE: Cob. Asignado deuda LUR o CHP
select distinct cob_codigo, ddr_rut rut--, deu_asig_desde
into #cobrador_asig
FROM GCDF_DEUDOR_ASIGNADO DAU with (NOLOCK)
WHERE  
(
	deu_asig_desde <= getdate() 
	and (deu_asig_hasta >= getdate() or deu_asig_hasta is null)
	
)  

-- crear índice no agrupado después de insertar los datos para evitar ralentizaciones durante la inserción y acelerar consultas posteriores.
create nonclustered index ix_cobrador_asig_rut on #cobrador_asig (rut)


--UPDATE cobrador_asignado_lur_chq
UPDATE #tabla_final 
SET cobrador_asignado_lur_chq = #cobrador_asig.COB_CODIGO
from #cobrador_asig
where rut_deudor = #cobrador_asig.rut




-- FILTROS: COLUMNAS EN LA SALIDA PARA FITRAR ____________________________________________________________________________
		
--1.- FILTRO Equipo : CONSULTAR A ALEX

--2.- FILTRO Supervisor: Obtener el SUP. vigente desde la tabla COBRADOR_SUP_ASIG

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

-- crear índice no agrupado después de insertar los datos para evitar ralentizaciones durante la inserción y acelerar consultas posteriores.
create nonclustered index ix_f_supervisor_asig_rut on #f_supervisor_asig(cob_codigo)

UPDATE #tabla_final 
SET f_supervisor_asig = #f_supervisor_asig.sco_codigo
from #f_supervisor_asig
where cobrador_asignado_lur_chq = #f_supervisor_asig.cob_codigo


--3.- FILTRO Tipo Deudor: Si tiene contrato vigente es VIGENTE, si tiene contrato pero no está vigente es NO VIGENTE y en otro caso es EMPRESA
select distinct cot_rut AS rut
, case when (c.con_inivig <= getdate()
         and (c.con_finvig >= getdate() or c.con_finvig is null)
		 ) then 'VIGENTE'
		 ELSE 'NO VIGENTE' END as vigencia
into #f_vigencia_personas
from contrato c with (nolock)
join #tabla_final
	on rut_deudor = c.cot_rut
where con_ultimo = 'S'

-- crear índice no agrupado después de insertar los datos para evitar ralentizaciones durante la inserción y acelerar consultas posteriores.
create nonclustered index ix_f_vigencia_personas_rut on #f_vigencia_personas(rut)

UPDATE #tabla_final 
SET f_tipo_deudor = #f_vigencia_personas.vigencia
from #f_vigencia_personas
where rut_deudor = #f_vigencia_personas.rut

UPDATE #tabla_final 
SET f_tipo_deudor = 'EMPRESA'
from #tabla_final
where f_tipo_deudor IS NULL


--4.- FILTRO Gestion 29	SELECT * FROM GESTION_COBRANZA WHERE TGC_CODIGO=29 (en el mes en curso)

select ddr_rut rut , case when count(*) > 0 then 'Si' else 'No' end as gestion29
into #f_gestion29
from GESTION_COBRANZA gc with (nolock)
join #tabla_final
	on rut_deudor = gc.ddr_rut
where tgc_codigo = 29
and GEC_FECHA_GES >= @PrimerDiaDelMes
and GEC_FECHA_GES < @PrimerDiaDelMesSgte
group by ddr_rut

-- crear índice no agrupado después de insertar los datos para evitar ralentizaciones durante la inserción y acelerar consultas posteriores.
create nonclustered index ix_f_gestion29_rut on #f_gestion29(rut)

UPDATE #tabla_final 
SET f_gestion29 = #f_gestion29.gestion29
from #f_gestion29
where rut_deudor = #f_gestion29.rut


--5.- FILTRO Compromiso Vencido	SELECT max(GEC_COMPROM_FECHA) FROM GESTION_COBRANZA  where DDR_RUT=@RUT 

select ddr_rut rut , max(GEC_COMPROM_FECHA) fecha		--se demora
into #f_compromiso_vencido
from GESTION_COBRANZA gc with (nolock)
join #tabla_final
	on rut_deudor = gc.ddr_rut
where GEC_COMPROM_FECHA is not null
group by ddr_rut

-- crear índice no agrupado después de insertar los datos para evitar ralentizaciones durante la inserción y acelerar consultas posteriores.
create nonclustered index ix_f_compromiso_vencido_rut on #f_compromiso_vencido(rut)

UPDATE #tabla_final 
SET f_compromiso_vencido = #f_compromiso_vencido.fecha
from #f_compromiso_vencido
where rut_deudor = #f_compromiso_vencido.rut


--6.- FILTRO Tipos Deuda (DNP, IP, DPP)

SELECT 
    cot_rut AS rut,
    MAX(CASE WHEN DEC_TIPO_DEUDA = 'DNP' THEN DEC_TIPO_DEUDA ELSE NULL END) AS DNP,
    MAX(CASE WHEN DEC_TIPO_DEUDA = 'NP' AND DEC_PAGADO > 0 THEN 'DPP' ELSE NULL END) AS DPP,
    MAX(CASE WHEN DEC_TIPO_DEUDA = 'NP' AND DEC_PAGADO = 0 THEN 'IP' ELSE NULL END) AS IP
into #f_tipo_deuda
FROM DEUDA_COTIZANTE WITH (NOLOCK)
join #tabla_final
	on rut_deudor = cot_rut
GROUP BY cot_rut

-- crear índice no agrupado después de insertar los datos para evitar ralentizaciones durante la inserción y acelerar consultas posteriores.
create nonclustered index ix_f_tipo_deuda_rut on #f_tipo_deuda(rut)

UPDATE #tabla_final 
SET f_dnp = #f_tipo_deuda.dnp
, f_dpp = #f_tipo_deuda.dpp
, f_ip = #f_tipo_deuda.ip
from #f_tipo_deuda
where rut_deudor = #f_tipo_deuda.rut


--7.- FILTRO : Menor y mayor Periodo Deuda

select 
--top 100 
cot_rut as rut, MIN(DEC_PERIODO) as menor_per_deuda, MAX(DEC_PERIODO) mayor_per_deuda
into #f_menor_mayor_deuda
from deuda_cotizante with (nolock)
join #tabla_final
	on rut_deudor = cot_rut
--where epa_rut is null
group by cot_rut

-- crear índice no agrupado después de insertar los datos para evitar ralentizaciones durante la inserción y acelerar consultas posteriores.
create nonclustered index ix_f_menor_mayor_deuda_rut on #f_menor_mayor_deuda(rut)

UPDATE #tabla_final 
SET f_menor_per_deuda = #f_menor_mayor_deuda.menor_per_deuda
, f_mayor_per_deuda = #f_menor_mayor_deuda.mayor_per_deuda
from #f_menor_mayor_deuda
where rut_deudor = #f_menor_mayor_deuda.rut


--8.- FILTRO Deuda LUR con Crédito	select DEU_CUOTAS, * from GCDF_DEUDA, f_deuda_lur_con_credito

select ddr_rut rut , case when sum(isnull(DEU_CUOTAS,0)) > 0 then 'Si' else 'No' end as deuda_lur_con_credito
into #f_deuda_lur_con_credito
from GCDF_DEUDA gc with (nolock)
join #tabla_final
	on rut_deudor = ddr_rut
group by ddr_rut

-- crear índice no agrupado después de insertar los datos para evitar ralentizaciones durante la inserción y acelerar consultas posteriores.
create nonclustered index ix_f_deuda_lur_con_credito_rut on #f_deuda_lur_con_credito(rut)

UPDATE #tabla_final 
SET f_deuda_lur_con_credito = #f_deuda_lur_con_credito.deuda_lur_con_credito
from #f_deuda_lur_con_credito
where rut_deudor = #f_deuda_lur_con_credito.rut

--9.- FILTRO Tipo Empresa: PREGUNTAR A ALEX	
--10.- FILTRO Rubro: PREGUNTAR A ALEX		

--SELECT * FROM #origen_cotiz_empl
--SELECT * FROM #origen_lur
--SELECT * FROM #origen_chq
--SELECT * FROM #TFU

SELECT 		rut_deudor
		, nombre_deudor
		, email_destinatario 
		, deuda_cotizaciones 
		, monto_cupon 
		, monto_posible_compensar 
		, nombre_ejecutivo 
		, email_ejecutivo 
		, fono_ejecutivo 
		, url_link 
		, url_link1 
		, url_link2
		, fecha_compromiso 
		, monto_compromiso 
		, deuda_lur 
		, deuda_chq 
		, cobrador_asignado_lur_chq 
		, fono_contacto 
		, f_supervisor_asig 
		, f_gestion29 
		, f_ciu_codigo_reside 
		, f_deuda_lur_con_credito 
		, f_edad_deudor 
		, f_compromiso_vencido 
		, f_dnp 
		, f_dpp 
		, f_ip 
		, f_menor_per_deuda 
		, f_mayor_per_deuda 
		, f_tipo_deudor 
		FROM #tabla_final



END