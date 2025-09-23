/*======================================================================================== 
 tipo de objeto		:	procedimiento almacenado                                        
 nombre del objeto	:	spu_ges_cob_Descargar_datos                                                                                                  
 parametros			:	@epl_codigo varchar(50) = código de plantilla.			                                                                                 
 creado por			:	jorge molina													
 fecha creación		:	                                                    
 descripción		:																		
========================================================================================*/
/*
execute spu_ges_cob_Descargar_datos_v7
--193.588 EN 7:15 SEG, 5:45, 5MIN
4min
--177.234 filas en 4:30 min
--177.234 filas en 2:43 min
*/

ALTER procedure [dbo].[spu_ges_cob_Descargar_datos_v7] 
@epl_codigo varchar(50) = null
as
BEGIN	
	set nocount on;
	
	--declare @PrimerDiaDelMes datetime
	--declare @PrimerDiaDelMesSgte datetime

	--SELECT @PrimerDiaDelMes = CAST(DATEADD(month, DATEDIFF(month, 0, GETDATE()), 0) AS DATE) 
	--SELECT @PrimerDiaDelMesSgte = CAST(DATEADD(month, DATEDIFF(month, 0, GETDATE()) + 1, 0) AS DATE) 

	if object_id('tempdb..#DEUDA_COTIZ_EMPL', 'u') is not null drop table #DEUDA_COTIZ_EMPL
	if object_id('tempdb..#TMP_DEUDA_COTIZANTE', 'u') is not null drop table #TMP_DEUDA_COTIZANTE

	if object_id('tempdb..#tabla_final', 'u') is not null drop table #tabla_final
	if object_id('tempdb..#origen_cotiz_empl', 'u') is not null drop table #origen_cotiz_empl
	--if object_id('tempdb..#origen_lur', 'u') is not null drop table #origen_lur
	--if object_id('tempdb..#origen_chq', 'u') is not null drop table #origen_chq
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

--1.- #TABLA_FINAL: CONTENDRA LOS RUT DE LAS 3 TABLAS_ORIGENES: COTIZANTE EMPLEADOR, LEY LUR Y CHEQUES.

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
		, f_dnp numeric(4) null
		, f_dpp numeric(4) null
		, f_ip numeric(4) null
		, f_menor_per_deuda datetime null
		, f_mayor_per_deuda datetime null
		, f_tipo_deudor varchar(30) null
		--, primary key (rut_deudor)
	)


--TABLAS_ORIGENES INICIO_____________________________________________________________________

--1.-TABLAS_ORIGENES1: RUTS DE COTIZANTE Y RUTS DE EMPLEADOR

--select 343.790 reg 9 seg
--con insert 1 seg
--Obtiene la deuda de cada COTIZANTE cuya responsabilidad de pago es de algún empleador
SELECT  COT_RUT, 
	DEC_PERIODO,
	SUM(CASE WHEN EPA_RUT IS NOT NULL THEN DEC_PACTADO - DEC_PAGADO END) AS DEUDA_EMPLEADOR
INTO #DEUDA_COTIZ_EMPL
FROM DEUDA_COTIZANTE with (nolock)
WHERE EPA_RUT IS NOT NULL
GROUP BY  COT_RUT, DEC_PERIODO

CREATE INDEX IDX_1 ON #deuda_cotiz_empl(COT_RUT,DEC_PERIODO)

--2.-Obtiene los registros de deudores desde DEUDA_COTIZANTE, pero restando a los registros de cotizantes (EPA_RUT IS NULL) el monto de la deuda cuya responsabilidad es de algún empleador
--y filtramos sólo aquellos registros que quedan con deuda > 0

SELECT 
	DC.DEC_RUT,
	DC.DEC_PERIODO,
	CASE
		WHEN DC.DEC_TIPO_DEUDA = 'DNP' THEN 'DNP'
			WHEN DC.DEC_TIPO_DEUDA = 'NP' AND DC.DEC_PAGADO=0 THEN 'IP'
		ELSE 'DPP'	 
	END AS DEC_TIPO_DEUDA,
	CASE WHEN EPA_RUT  IS NOT NULL THEN 'EMPRESA' ELSE 'COTIZANTE' END AS TIPO_DEUDOR ,
	DEC_TIPO_COTIZANTE,
	(coalesce(DEC_PACTADO,0) - coalesce(DEC_PAGADO,0)) - coalesce(deuda_empleador,0) as DEC_DEUDA,
	(coalesce(DEC_PACTADO,0) - coalesce(DEC_PAGADO,0)) - coalesce(deuda_empleador,0) + 
		ROUND((CASE WHEN (INTERESES.INT_REAJUSTE < 0) OR (INTERESES.INT_REAJUSTE IS NULL) THEN 0 ELSE INTERESES.INT_REAJUSTE END) / 100 * ((coalesce(DEC_PACTADO,0) - coalesce(DEC_PAGADO,0)) - coalesce(deuda_empleador,0)), 0) +
		ROUND((CASE WHEN (INTERESES.INT_INTERES  < 0) OR (INTERESES.INT_INTERES IS NULL ) THEN 0 ELSE INTERESES.INT_INTERES  END) / 100 * ((coalesce(DEC_PACTADO,0) - coalesce(DEC_PAGADO,0)) - coalesce(deuda_empleador,0)), 0) +
		ROUND((CASE WHEN (INTERESES.INT_RECARGO < 0)  OR (INTERESES.INT_RECARGO IS NULL)  THEN 0 ELSE INTERESES.INT_RECARGO END)  / 100 * ((coalesce(DEC_PACTADO,0) - coalesce(DEC_PAGADO,0)) - coalesce(deuda_empleador,0)), 0) 
	AS DEUDA_REAJUSTADA
INTO #TMP_DEUDA_COTIZANTE
FROM DEUDA_COTIZANTE DC with (nolock)
	LEFT JOIN #deuda_cotiz_empl D 
		ON DC.COT_RUT=D.COT_RUT AND DC.DEC_PERIODO=D.DEC_PERIODO AND DC.EPA_RUT IS NULL
	LEFT JOIN INTERESES (NOLOCK) ON INTERESES.INT_PPC_PERIODO = DC.DEC_PERIODO AND INTERESES.INT_FECHA_PAGO = CONVERT(CHAR(8), GETDATE(),112)
WHERE (coalesce(DEC_PACTADO,0) - coalesce(DEC_PAGADO,0)) - coalesce(deuda_empleador,0) >0

CREATE INDEX ix_TMP_DEUDA_COTIZANTE ON #TMP_DEUDA_COTIZANTE(DEC_RUT)
--select * from #TMP_DEUDA_COTIZANTE

--select 170.898 reg en 16 seg
--3.- solo debe haber un rut por registro , se guardara en #origen_cotiz_empl
SELECT 
    base.dec_rut as rut,
    base.dec_deuda as deuda,
    tipo.DNP dnp,
    tipo.DPP dpp,
    tipo.IP ip,
    peri.menor_per_deuda as menor_per_deuda,
    peri.mayor_per_deuda as mayor_per_deuda
into #origen_cotiz_empl
FROM 
    (SELECT dec_rut , 
           SUM(isnull(DEC_DEUDA, 0)) AS dec_deuda
     FROM  #TMP_DEUDA_COTIZANTE WITH (NOLOCK)
     GROUP BY dec_rut
     --HAVING SUM(DEC_DEUDA) > 0
    ) base
LEFT JOIN
    (SELECT dec_rut AS rut,
		sum(CASE WHEN DEC_TIPO_DEUDA = 'DNP' THEN 1 ELSE 0 END) AS DNP,
		sum(CASE WHEN DEC_TIPO_DEUDA = 'DPP'  THEN 1 ELSE 0 END) AS DPP,
		sum(CASE WHEN DEC_TIPO_DEUDA = 'IP'  THEN 1 ELSE 0 END) AS IP
     FROM #TMP_DEUDA_COTIZANTE WITH (NOLOCK)
     GROUP BY dec_rut
    ) tipo
    ON base.dec_rut = tipo.rut
LEFT JOIN
    (SELECT dec_rut AS rut, 
         MIN(DEC_PERIODO) AS menor_per_deuda, 
         MAX(DEC_PERIODO) AS mayor_per_deuda
     FROM #TMP_DEUDA_COTIZANTE WITH (NOLOCK)
     GROUP BY dec_rut
    ) peri
 ON base.dec_rut = peri.rut

-- Crear índice no agrupado después de insertar los datos para evitar ralentizaciones durante la inserción y acelerar consultas posteriores.
create nonclustered index ix_origen_cotiz_empl_rut on #origen_cotiz_empl (rut)


--select * from #TMP_DEUDA_COTIZANTE
--select * from #origen_cotiz_empl order by 1 


--4.- TABLAS_ORIGENES2: RUTS DE LUR Y CHQ 
--(9425 rows affected) 0seg
select
  DDR_rut as rut,
  sum(case when TDE_CODIGO = 1 then deu_monto else 0 end) as deuda_lur,
  sum(case when TDE_CODIGO = 2 then deu_monto else 0 end) as deuda_chq
INTO #origen_lur_chq
from dbo.GCDF_DEUDA gd with (nolock)
where deu_monto > 0
and TDE_CODIGO in (1, 2)
group by DDR_rut
--order by 1

create nonclustered index ix_origen_chq_rut on #origen_lur_chq (rut)

--select * from #origen_lur_chq

--TABLAS_ORIGENES FIN ________________________________________________


--177.234 reg en 16 seg
--5.- INSERTAR LOS RUTS DE LAS 3 TABLAS_ORIGENES EN #tabla_final  INI_________________________

insert #tabla_final (rut_deudor, deuda_cotizaciones, f_dnp, f_dpp, f_ip, f_menor_per_deuda, f_mayor_per_deuda, deuda_lur, deuda_chq)
SELECT
    COALESCE(a.rut, b.rut) AS rut,
    a.deuda,
    a.DNP,
    a.DPP,
    a.IP,
    a.menor_per_deuda,
    a.mayor_per_deuda,
    b.deuda_lur,
    b.deuda_chq
FROM
    (
		SELECT rut,
			 deuda,
			dnp,
			dpp,
			ip,
			menor_per_deuda,
			mayor_per_deuda
		from #origen_cotiz_empl
    ) a
FULL OUTER JOIN
    (
        SELECT
             rut,
            deuda_lur,
             deuda_chq
		FROM #origen_lur_chq
    ) b
ON a.rut = b.rut;



-- crear índice no agrupado después de insertar los datos para evitar ralentizaciones durante la inserción y acelerar consultas posteriores.
create nonclustered index ix_tabla_final_rut on #tabla_final (rut_deudor)

--select * from #tabla_final


--5.- INSERTAR LOS RUTS DE LAS 3 TABLAS_ORIGENES EN #tabla_final  FIN_________________________


--ZONA DE TABLAS DE RELLENO INI __________________________
--6.- TABLA TFU
-- Nota: select 17.850 reg pero todos me dan cero.
----v1
--select
----top 100 
--dt.cot_rut rut, convert(numeric(12),sum(round(dtc_monto * dbo.f_get_ufmes(getdate()),0)) )  as saldo_tfu 
--into #tfu
--from devolucion_tfu_cuota dt with (nolock)
--join #tabla_final
--	on rut_deudor = dt.cot_rut
--where dt.afi_rut is null 
--group by dt.cot_rut
--	--and cot_rut = @rut

--v2
-- drop table #tfu
declare @uf_mes numeric(10,2)
select @uf_mes = dbo.f_get_ufmes(getdate())
--select * from uf 
--insert into uf
--select * from [150.10.10.9].[isapre].[dbo].uf where uf_fecha > '20241231'

select
--top 100 
dt.cot_rut rut, convert(numeric(12),sum(round(dtc_monto * @uf_mes,0)) )  as saldo_tfu 
into #tfu
from devolucion_tfu_cuota dt with (nolock)
join #tabla_final
	on rut_deudor = dt.cot_rut
where dt.afi_rut is null 
group by dt.cot_rut
	--and cot_rut = @rut


create nonclustered index ix_tfu_rut on #tfu (rut)
--select * from #tfu


--7.- TABLA #compromiso: Obtener compromisos de pago GEC_COMPROM_MONTO	y GEC_COMPROM_FECHA, tengo que ir a buscar el ultimo para e rut fecha digita
--42.212 seg

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
		and GEC_COMPROM_MONTO is not null
		and GEC_COMPROM_FECHA is not null
		group by ddr_rut
	) a
	on gc.DDR_RUT = a.DDR_RUT
	and gc.GEC_FECDIGITA = a.GEC_FECDIGITA


create nonclustered index ix_compromiso_rut on #compromiso (rut)
--select * from #compromiso


--8.- TABLA #cobrador_asig: Cob. Asignado deuda LUR o CHP
--15 reg 0 seg

select distinct cob_codigo, ddr_rut rut--, deu_asig_desde
into #cobrador_asig
FROM GCDF_DEUDOR_ASIGNADO DAU with (NOLOCK)
WHERE  
(
	deu_asig_desde <= getdate() 
	and (deu_asig_hasta >= getdate() or deu_asig_hasta is null)
	
)  

create nonclustered index ix_cobrador_asig_rut on #cobrador_asig (rut)

--ZONA DE TABLAS DE RELLENO FIN __________________________


-- ZONA DE TABLAS FILTROS: COLUMNAS EN LA SALIDA PARA FITRAR INI_____________________________________________________
		
--1.- FILTRO Equipo : CONSULTAR A ALEX

--9.- FILTRO Supervisor: Obtener el SUP. vigente desde la tabla COBRADOR_SUP_ASIG

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

--create nonclustered index ix_f_supervisor_asig_rut on #f_supervisor_asig(cob_codigo)


--10.- FILTRO Tipo Deudor: Si tiene contrato vigente es VIGENTE, si tiene contrato pero no está vigente es NO VIGENTE y en otro caso es EMPRESA
--148109 reg 1seg

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

create nonclustered index ix_f_vigencia_personas_rut on #f_vigencia_personas(rut)
--select * from #f_vigencia_personas


--11.- FILTRO Gestion 29	SELECT * FROM GESTION_COBRANZA WHERE TGC_CODIGO=29 (en el mes en curso)

	declare @PrimerDiaDelMes datetime
	declare @PrimerDiaDelMesSgte datetime

	SELECT @PrimerDiaDelMes = CAST(DATEADD(month, DATEDIFF(month, 0, GETDATE()), 0) AS DATE) 
	SELECT @PrimerDiaDelMesSgte = CAST(DATEADD(month, DATEDIFF(month, 0, GETDATE()) + 1, 0) AS DATE) 

	--select @PrimerDiaDelMes, @PrimerDiaDelMesSgte

select ddr_rut rut , case when count(*) > 0 then 'Si' else 'No' end as gestion29
into #f_gestion29
from GESTION_COBRANZA gc with (nolock)
join #tabla_final
	on rut_deudor = gc.ddr_rut
where tgc_codigo = 29
and GEC_FECHA_GES >= @PrimerDiaDelMes
and GEC_FECHA_GES < @PrimerDiaDelMesSgte
group by ddr_rut

--create nonclustered index ix_f_gestion29_rut on #f_gestion29(rut)


--12.- FILTRO Compromiso Vencido	SELECT max(GEC_COMPROM_FECHA) FROM GESTION_COBRANZA  where DDR_RUT=@RUT 
--sin (where GEC_COMPROM_FECHA is not null) : 175.932 reg en 46 seg
--con (where GEC_COMPROM_FECHA is not null) : 115.463 reg en 48 seg

select ddr_rut rut , max(GEC_COMPROM_FECHA) fecha		--se demora
into #f_compromiso_vencido
from GESTION_COBRANZA gc with (nolock)
join #tabla_final
	on rut_deudor = gc.ddr_rut
where GEC_COMPROM_FECHA is not null
group by ddr_rut

create nonclustered index ix_f_compromiso_vencido_rut on #f_compromiso_vencido(rut)
--select * from #f_compromiso_vencido




--create nonclustered index ix_f_tipo_deuda_rut on #f_tipo_deuda(rut)




--create nonclustered index ix_f_menor_mayor_deuda_rut on #f_menor_mayor_deuda(rut)


--13.- FILTRO Deuda LUR con Crédito	select DEU_CUOTAS, * from GCDF_DEUDA, f_deuda_lur_con_credito

select ddr_rut rut , case when sum(isnull(DEU_CUOTAS,0)) > 0 then 'Si' else 'No' end as deuda_lur_con_credito
into #f_deuda_lur_con_credito
from GCDF_DEUDA gc with (nolock)
join #tabla_final
	on rut_deudor = ddr_rut
group by ddr_rut

create nonclustered index ix_f_deuda_lur_con_credito_rut on #f_deuda_lur_con_credito(rut)

--9.- FILTRO Tipo Empresa: PREGUNTAR A ALEX	
--10.- FILTRO Rubro: PREGUNTAR A ALEX		

-- ZONA DE FILTROS: COLUMNAS EN LA SALIDA PARA FITRAR FIN_____________________________________________________


--ZONA DE UPDATES EN #TABLA_FINAL INI____________________________________________________________

--14 UPDATE monto_posible_compensar
--17.850 en 1 seg
UPDATE #tabla_final
set monto_posible_compensar = case when ( (isnull(DEUDA_cotizaciones, 0) + isnull(DEUDA_lur, 0)) >= #tfu.saldo_tfu  ) then  #tfu.saldo_tfu else (isnull(DEUDA_cotizaciones, 0) + isnull(DEUDA_lur, 0)) end
from #tfu
where rut_deudor = #tfu.rut

--UPDATE #tabla_final 
--SET f_tipo_deudor = 'EMPRESA'
--from #tabla_final
--where f_tipo_deudor IS NULL


--15 177.234 filas en 8 seg
UPDATE tf
SET 
--    DEUDA_cotizaciones = oc.deuda,
--    DEUDA_lur = ol.deuda_lur,
    --DEUDA_chq = och.deuda_chq,
--    DEUDA_chq = ol.deuda_chq,
    fecha_compromiso = c.fecha,
    monto_compromiso = c.monto,
    cobrador_asignado_lur_chq = c_asig.cob_codigo,
    f_supervisor_asig = sup.sco_codigo,
    f_tipo_deudor = vig.vigencia,
    f_gestion29 = ges.gestion29,
    f_compromiso_vencido = compv.fecha,
    --f_dnp = td.dnp,
    --f_dpp = td.dpp,
    --f_ip = td.ip,
    --f_menor_per_deuda = mmd.menor_per_deuda,
    --f_mayor_per_deuda = mmd.mayor_per_deuda,
    --f_dnp = oc.dnp,
    --f_dpp = oc.dpp,
    --f_ip = oc.ip,
    --f_menor_per_deuda = oc.menor_per_deuda,
    --f_mayor_per_deuda = oc.mayor_per_deuda,
    f_deuda_lur_con_credito = dlcc.deuda_lur_con_credito,
    nombre_deudor = d.ddr_nombre,
    nombre_ejecutivo = c2.cob_nombre,
    email_ejecutivo = c2.cob_EMAIL,
    fono_ejecutivo = c2.cob_FONO,
    fono_contacto = c2.cob_celular,
    f_ciu_codigo_reside = d.CIU_CODIGO
   --, f_edad_deudor = dbo.f_edad(b.BNF_NACTO, GETDATE())
FROM #tabla_final tf
--LEFT JOIN #origen_cotiz_empl oc ON tf.rut_deudor = oc.rut
--LEFT JOIN #origen_lur ol ON tf.rut_deudor = ol.rut
--LEFT JOIN #origen_chq och ON tf.rut_deudor = och.rut
--LEFT JOIN #origen_lur_chq ol ON tf.rut_deudor = ol.rut
LEFT JOIN #compromiso c ON tf.rut_deudor = c.rut
LEFT JOIN #cobrador_asig c_asig ON tf.rut_deudor = c_asig.rut
LEFT JOIN #f_supervisor_asig sup ON c_asig.cob_codigo = sup.cob_codigo
LEFT JOIN #f_vigencia_personas vig ON tf.rut_deudor = vig.rut
LEFT JOIN #f_gestion29 ges ON tf.rut_deudor = ges.rut
LEFT JOIN #f_compromiso_vencido compv ON tf.rut_deudor = compv.rut
--LEFT JOIN #f_tipo_deuda td ON tf.rut_deudor = td.rut
--LEFT JOIN #f_menor_mayor_deuda mmd ON tf.rut_deudor = mmd.rut
LEFT JOIN #f_deuda_lur_con_credito dlcc ON tf.rut_deudor = dlcc.rut
LEFT JOIN deudor d ON tf.rut_deudor = d.ddr_rut
LEFT JOIN deudor_asignado da ON da.DDR_RUT = d.DDR_RUT 
   AND (da.DEU_ASIG_DESDE <= GETDATE() AND (da.DEU_ASIG_HASTA > GETDATE() OR da.DEU_ASIG_HASTA IS NULL))
LEFT JOIN cobrador c2 ON c2.COB_CODIGO = da.COB_CODIGO
LEFT JOIN BENEFICIARIO b ON b.BNF_RUT = d.DDR_RUT;

--ZONA DE UPDATES EN #TABLA_FINAL FIN____________________________________________________________


--SELECT * FROM #origen_cotiz_empl
--SELECT * FROM #origen_lur
--SELECT * FROM #origen_chq
--SELECT * FROM #TFU


--177.234 reg en 3:38 seg
--16 SELECT FINAL
SELECT 	rut_deudor
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