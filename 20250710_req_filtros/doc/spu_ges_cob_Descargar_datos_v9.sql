/*======================================================================================== 
 tipo de objeto		:	procedimiento almacenado                                        
 nombre del objeto	:	spu_ges_cob_Descargar_datos                                                                                                  
 parametros			:	@epl_codigo varchar(50) = código de plantilla.			                                                                                 
 creado por			:	jorge molina													
 fecha creación		:	                                                    
 descripción		:																		
========================================================================================*/
/*	execute spu_ges_cob_Descargar_datos_v9 19

--177.234 filas en 2:30 min	*/

alter procedure [dbo].[spu_ges_cob_Descargar_datos_v9] 
@epl_codigo varchar(50) = null
as
BEGIN	
	set nocount on;

declare @sqlwhere nvarchar(4000)
set @sqlwhere = ''

----0.- PLANILLA_____________________________
---- REVISAR SI EXISTE 

IF NOT EXISTS (SELECT 1 FROM GCO_ENVMSG_PLANTILLA WITH (NOLOCK) WHERE EPL_CODIGO = @EPL_CODIGO)
BEGIN
	SELECT 'NO EXISTE PLANTILLA'
	RETURN 
END

IF NOT EXISTS (SELECT 1 FROM GCO_ENVMSG_FILTRO WITH (NOLOCK) WHERE EPL_CODIGO = @EPL_CODIGO)
BEGIN
	SELECT 'NO EXISTE FILTROS EN LA PLANTILLA'
	RETURN 
END

--/*
---- SELECT * FROM GCO_ENVMSG_CONCEPTO
--ECO_CODIGO numeric(5) not null	ECO_NOMBRE varchar(200) not null	ECO_TIPO_SELECCION
--1	TIPO ENVIO	S
--2	LINK	S
--3	GRUPO o Equipo	S
--4	Supervisor	S
--5	Cobrador Asignado	M
--6	Grupo Deuda	M
--7	Tipo y Vigencia Deudor	M
--8	Con Gestión Cód.. 29	M
--9	Fecha Compromiso vencido	M
--10	Tipo de Deuda	S
--11	Tipo Deuda Cotizaciones	M
--12	Menor Periodo de Deuda	M
--13	Mayor Periodo de Deuda	M
--14	Cuidad Residencia	M
--15	Deudores LUR con Crédito 5%	M
--16	Tipo de Empresa	M
--17	Rubro Empresa	M
--18	Posible Compensar x TFU	M
--19	Edad Deudor	M
--*/

if object_id('tempdb..#FILTROS', 'u') is not null drop table #FILTROS

DECLARE @CODIGO_CONCEPTO numeric(5, 0)
DECLARE @NOMBRE_VALOR NVARCHAR(4000)
DECLARE @UF_VALOR NUMERIC(8, 2)

declare @fecha_hoy datetime
set @fecha_hoy = CAST( ( CAST(GETDATE() AS DATE)) AS DATETIME)
print @fecha_hoy

----@UF_VALOR = CAST(GETDATE() AS DATE)
SELECT @UF_VALOR = UF_VALOR FROM UF WITH (NOLOCK) WHERE UF_FECHA = CAST( ( CAST(GETDATE() AS DATE)) AS DATETIME)

IF @UF_VALOR IS NULL
BEGIN
	SELECT 'NO EXISTE UF'
	RETURN 
END

----v1
-- --CREATE TABLE #FILTROS(       
-- --CODIGO_CONCEPTO numeric(5, 0) NOT NULL,    
-- --NOMBRE_CONCEPTO varchar(100) NULL,    
-- --CODIGO_VALOR varchar(100)  NULL,    
-- --NOMBRE_VALOR varchar(100)  NULL,    
-- --SELECCIONADO VARCHAR(1) NULL  
-- --, ECO_TIPO_SELECCION VARCHAR(1) NULL  
-- --)    


-- --INSERT #FILTROS
-- --EXECUTE spu_ges_cob_mensajes_filtros_consultar @epl_codigo
-- --DELETE #FILTROS WHERE SELECCIONADO = 'N'

-- --SELECT * FROM #FILTROS

-- --v2




--CURSOR
DECLARE CUR_FILTROS CURSOR FOR
	 
	 --SELECT CODIGO_CONCEPTO
	 --, NOMBRE_VALOR
	 --FROM #FILTROS

	 SELECT ECO_CODIGO
	 , EFI_VALOR
	 FROM GCO_ENVMSG_FILTRO WITH (NOLOCK)
	 WHERE EPL_CODIGO = @epl_codigo 
	 ORDER BY 1

OPEN CUR_FILTROS

FETCH NEXT FROM CUR_FILTROS INTO @CODIGO_CONCEPTO, @NOMBRE_VALOR

WHILE @@FETCH_STATUS = 0
BEGIN

--	--PRINT @CODIGO_CONCEPTO
--	--PRINT @NOMBRE_VALOR

--	--CONCEPTO 3: GRUPO o Equipo
--		--Equipo Interno
--		--Equipo Stock
--		--Equipo judicial


--	--CONCEPTO 4:	Supervisor	S
--		--A.SOTO
--		--E.CABELLO
--		--C.MORALES

--	--select * from gco_envmsg_filtro WHERE epl_codigo  = 4
--	--select * from gco_envmsg_concepto where eco_codigo = 4
--update gco_envmsg_concepto SET eco_tipo_seleccion = 'M'  where eco_codigo = 4


	DECLARE @F_SUPERVISOR VARCHAR(500)
	SET @F_SUPERVISOR = ''

	IF @CODIGO_CONCEPTO = 4 
	BEGIN
		SET @F_SUPERVISOR = replace(@NOMBRE_VALOR, '|', ',')

		set @sqlwhere = @sqlwhere + ' and supervisor_asig in ('+@F_SUPERVISOR+')'

	END


--	--select * from gco_envmsg_concepto where eco_codigo = 5
--	--select * from gco_envmsg_filtro where eco_codigo = 5

--	--CONCEPTO 5 Cobrador Asignado	M

	DECLARE @F_COBRADOR VARCHAR(500)
	SET @F_COBRADOR = ''

	IF @CODIGO_CONCEPTO = 5 
	BEGIN
		SET @F_COBRADOR = replace(@NOMBRE_VALOR, '|', ',')

		set @sqlwhere = @sqlwhere + ' and COB_CODIGO in ('+@F_COBRADOR+')'

	END



--	--CONCEPTO 6 Grupo Deuda: VALORES A, B, C
--	--1 Afiliados Vigentes GRUPO A (DEUDA <= A UF 1)	
--	--2 Afiliados Vigentes GRUPO B (DEUDA <= A UF 2)	
--	--3 Afiliados Vigentes GRUPO C (DEUDA > A UF 3)
--	--select * from gco_envmsg_filtro where EPL_codigo = '1'

	DECLARE @GRUPO_DEUDA VARCHAR(100)
	SET @GRUPO_DEUDA = ''

	IF @CODIGO_CONCEPTO = 6 
	BEGIN

		IF @NOMBRE_VALOR LIKE '%1%'	-- Afiliados Vigentes GRUPO A (DEUDA <= A UF 1)	
		BEGIN
			IF @GRUPO_DEUDA = ''
			BEGIN
				SET @GRUPO_DEUDA = ' and deuda_cotizaciones <= '+cast(@UF_VALOR as varchar(20))
			END
			ELSE
			BEGIN
				set @GRUPO_DEUDA = @GRUPO_DEUDA + ' and deuda_cotizaciones <= '+cast(@UF_VALOR as varchar(20))
			END
		END

		IF @NOMBRE_VALOR LIKE '%2%'		--2 Afiliados Vigentes GRUPO B (DEUDA <= A UF 2)
		BEGIN
			IF @GRUPO_DEUDA = ''
			BEGIN
				SET @GRUPO_DEUDA = ' and deuda_cotizaciones <= '+cast(@UF_VALOR*2 as varchar(20))
			END
			ELSE
			BEGIN
				set @GRUPO_DEUDA = @GRUPO_DEUDA + ' and deuda_cotizaciones <= '+cast(@UF_VALOR*2 as varchar(20))
			END
		END

		IF @NOMBRE_VALOR LIKE '%3%'		--3 Afiliados Vigentes GRUPO C (DEUDA > A UF 3)
		BEGIN
			IF @GRUPO_DEUDA = ''
			BEGIN
				SET @GRUPO_DEUDA = ' and deuda_cotizaciones > '+cast(@UF_VALOR*3 as varchar(20))
			END
			ELSE
			BEGIN
				set @GRUPO_DEUDA = @GRUPO_DEUDA + ' and deuda_cotizaciones > '+cast(@UF_VALOR*3 as varchar(20))
			END
		END

		--set @sqlwhere = @sqlwhere + ' and TIPO_DEUDOR = '''+@NOMBRE_VALOR+''''
		set @sqlwhere = @sqlwhere + @GRUPO_DEUDA
	END


--	IF @CODIGO_CONCEPTO = 6 
--	BEGIN
--		--IF @NOMBRE_VALOR = 'A'
--		IF @NOMBRE_VALOR = '1'
--		BEGIN
--			set @sqlwhere = @sqlwhere + ' and deuda_cotizaciones <= '+cast(@UF_VALOR as varchar(20))
--		END

--		--IF @NOMBRE_VALOR = 'B'
--		IF @NOMBRE_VALOR = '2'
--		BEGIN
--			set @sqlwhere = @sqlwhere + ' and deuda_cotizaciones <= '+cast(@UF_VALOR*2 as varchar(20))
--		END

--		--IF @NOMBRE_VALOR = 'C'
--		IF @NOMBRE_VALOR = '3'
--		BEGIN
--			set @sqlwhere = @sqlwhere + ' and deuda_cotizaciones > '+cast(@UF_VALOR*3 as varchar(20))
--		END
--	END






	--7	Tipo y Vigencia Deudor
	--Vigente		1
	--No Vigente	2
	--Empresa		3
	--select * from gco_envmsg_filtro where EPL_codigo = '1'
	--select * from gco_envmsg_CONCEPTO where ECO_CODIGO  = 7
	DECLARE @TIPO_DEUDOR_VIG VARCHAR(100)
	SET @TIPO_DEUDOR_VIG = ''

	IF @CODIGO_CONCEPTO = 7 
	BEGIN

		IF @NOMBRE_VALOR LIKE '%1%'
		BEGIN
			IF @TIPO_DEUDOR_VIG = ''
			BEGIN
				SET @TIPO_DEUDOR_VIG = 'VIGENTE'
			END
			ELSE
			BEGIN
				SET @TIPO_DEUDOR_VIG = @TIPO_DEUDOR_VIG+''','''+'VIGENTE'
			END
		END

		IF @NOMBRE_VALOR LIKE '%2%'
		BEGIN
			IF @TIPO_DEUDOR_VIG = ''
			BEGIN
				SET @TIPO_DEUDOR_VIG = 'NO VIGENTE'
			END
			ELSE
			BEGIN
				SET @TIPO_DEUDOR_VIG = @TIPO_DEUDOR_VIG+''','''+'NO VIGENTE'
			END
		END

		IF @NOMBRE_VALOR LIKE '%3%'
		BEGIN
			IF @TIPO_DEUDOR_VIG = ''
			BEGIN
				SET @TIPO_DEUDOR_VIG = 'EMPRESA'
			END
			ELSE
			BEGIN
				SET @TIPO_DEUDOR_VIG = @TIPO_DEUDOR_VIG+''','''+'EMPRESA'
			END
		END

		--set @sqlwhere = @sqlwhere + ' and TIPO_DEUDOR = '''+@NOMBRE_VALOR+''''
		set @sqlwhere = @sqlwhere + ' and TIPO_DEUDOR IN ('''+@TIPO_DEUDOR_VIG+''')'
	END
		

--8	Con Gestión Cód.. 29	M
--1 Con 
--2 Sin 

	DECLARE @F_GESTION VARCHAR(100)
	SET @F_GESTION = ''

	IF @CODIGO_CONCEPTO = 8 
	BEGIN

		IF @NOMBRE_VALOR LIKE '%1%'
		BEGIN
			IF @F_GESTION = ''
			BEGIN
				SET @F_GESTION = 'Si'
			END
			ELSE
			BEGIN
				SET @F_GESTION = @F_GESTION+''','''+'Si'
			END
		END

		IF @NOMBRE_VALOR LIKE '%2%'
		BEGIN
			IF @F_GESTION = ''
			BEGIN
				SET @F_GESTION = 'No'
			END
			ELSE
			BEGIN
				SET @F_GESTION = @F_GESTION+''','''+'No'
			END
		END

		set @sqlwhere = @sqlwhere + ' and gestion29 IN ('''+@F_GESTION+''')'
	END

--CONCEPTO = 9 Fecha Compromiso vencido
--1.- Vencidos (Compromiso Hoy-1)
--2.- No Vencidos (Compromiso >=Hoy)


	DECLARE @F_COMPVENCIDO VARCHAR(300)
	SET @F_COMPVENCIDO = ''

	IF @CODIGO_CONCEPTO = 9 
	BEGIN

		IF @NOMBRE_VALOR LIKE '%1%'
		BEGIN
			IF @F_COMPVENCIDO = ''
			BEGIN
				--SET @F_COMPVENCIDO = ' and compromiso_vencido < '+cast@fecha_hoy
				SET @F_COMPVENCIDO = ' and compromiso_vencido < convert(datetime, '''+CONVERT (varchar(30), @fecha_hoy , 121 ) +''', 121)'
			END
			ELSE
			BEGIN
				SET @F_COMPVENCIDO = @F_COMPVENCIDO+' and compromiso_vencido < convert(datetime, '''+CONVERT (varchar(30), @fecha_hoy , 121 ) +''', 121)'
			END
		END

		IF @NOMBRE_VALOR LIKE '%2%'
		BEGIN
			IF @F_COMPVENCIDO = ''
			BEGIN
				SET @F_COMPVENCIDO = ' and compromiso_vencido >= convert(datetime, '''+CONVERT (varchar(30), @fecha_hoy , 121 ) +''', 121)'
			END
			ELSE
			BEGIN
				SET @F_COMPVENCIDO = @F_COMPVENCIDO+' and compromiso_vencido >= convert(datetime, '''+CONVERT (varchar(30), @fecha_hoy , 121 ) +''', 121)'
			END
		END

		set @sqlwhere = @sqlwhere + ' AND compromiso_vencido IS NOT NULL ' +@F_COMPVENCIDO
	END
		


--CONCEPTO 10 Tipo de Deuda
--1 Cotizaciones
--2 Ley de Urgencia
--3 Cheques Protestados
--update gco_envmsg_concepto SET eco_tipo_seleccion = 'M'  where eco_codigo = 10


	DECLARE @F_TIPODEUDA VARCHAR(300)
	SET @F_TIPODEUDA = ''

	IF @CODIGO_CONCEPTO = 10 
	BEGIN

		IF @NOMBRE_VALOR LIKE '%1%'
		BEGIN
			IF @F_TIPODEUDA = ''
			BEGIN
				SET @F_TIPODEUDA = ' and deuda_cotizaciones > 0'
			END
			ELSE
			BEGIN
				SET @F_TIPODEUDA = @F_TIPODEUDA+' and deuda_cotizaciones > 0'
			END
		END

		IF @NOMBRE_VALOR LIKE '%2%'
		BEGIN
			IF @F_TIPODEUDA = ''
			BEGIN
				SET @F_TIPODEUDA = ' and deuda_lur > 0'
			END
			ELSE
			BEGIN
				SET @F_TIPODEUDA = @F_TIPODEUDA+' and deuda_lur > 0'
			END
		END

		IF @NOMBRE_VALOR LIKE '%3%'
		BEGIN
			IF @F_TIPODEUDA = ''
			BEGIN
				SET @F_TIPODEUDA = ' and deuda_chq > 0'
			END
			ELSE
			BEGIN
				SET @F_TIPODEUDA = @F_TIPODEUDA+' and deuda_chq > 0'
			END
		END

		set @sqlwhere = @sqlwhere + @F_TIPODEUDA
	END
		


--CONCEPTO 11 Tipo Deuda Cotizaciones
--1 DNP
--2 IP
--3 DPP



	SET @F_TIPODEUDA = ''

	IF @CODIGO_CONCEPTO = 11 
	BEGIN

		IF @NOMBRE_VALOR LIKE '%1%'
		BEGIN
			IF @F_TIPODEUDA = ''
			BEGIN
				SET @F_TIPODEUDA = ' and DNP > 0'
			END
			ELSE
			BEGIN
				SET @F_TIPODEUDA = @F_TIPODEUDA+' and DNP > 0'
			END
		END

		IF @NOMBRE_VALOR LIKE '%2%'
		BEGIN
			IF @F_TIPODEUDA = ''
			BEGIN
				SET @F_TIPODEUDA = ' and IP > 0'
			END
			ELSE
			BEGIN
				SET @F_TIPODEUDA = @F_TIPODEUDA+' and IP > 0'
			END
		END

		IF @NOMBRE_VALOR LIKE '%3%'
		BEGIN
			IF @F_TIPODEUDA = ''
			BEGIN
				SET @F_TIPODEUDA = ' and DPP > 0'
			END
			ELSE
			BEGIN
				SET @F_TIPODEUDA = @F_TIPODEUDA+' and DPP > 0'
			END
		END

		set @sqlwhere = @sqlwhere + @F_TIPODEUDA
	END





--	--CONCEPTO 14 CIUDAD DE RESIDENCIA

	SET @F_COBRADOR = ''

	IF @CODIGO_CONCEPTO = 14 
	BEGIN
		SET @F_COBRADOR = replace(@NOMBRE_VALOR, '|', ',')

		set @sqlwhere = @sqlwhere + ' and CIU_CODIGO_RESIDE in ('+@F_COBRADOR+')'

	END




--CONCEPTO 19 EDAD DEUDOR
--1 18-25
--2 26-40
--3 41 - 55
--4 Otros

	SET @F_TIPODEUDA = ''

	IF @CODIGO_CONCEPTO = 19 
	BEGIN

		IF @NOMBRE_VALOR LIKE '%1%'
		BEGIN
			IF @F_TIPODEUDA = ''
			BEGIN
				SET @F_TIPODEUDA = ' and EDAD_DEUDOR >= 18 and EDAD_DEUDOR <= 25 '
			END
			ELSE
			BEGIN
				SET @F_TIPODEUDA = @F_TIPODEUDA+' and EDAD_DEUDOR >= 18 and EDAD_DEUDOR <= 25 '
			END
		END

		IF @NOMBRE_VALOR LIKE '%2%'
		BEGIN
			IF @F_TIPODEUDA = ''
			BEGIN
				SET @F_TIPODEUDA = ' and EDAD_DEUDOR >= 26 and EDAD_DEUDOR <= 40 '
			END
			ELSE
			BEGIN
				SET @F_TIPODEUDA = @F_TIPODEUDA+' and EDAD_DEUDOR >= 26 and EDAD_DEUDOR <= 40 '
			END
		END

		IF @NOMBRE_VALOR LIKE '%3%'
		BEGIN
			IF @F_TIPODEUDA = ''
			BEGIN
				SET @F_TIPODEUDA = ' and EDAD_DEUDOR >= 41 and EDAD_DEUDOR <= 55 '
			END
			ELSE
			BEGIN
				SET @F_TIPODEUDA = @F_TIPODEUDA+' and EDAD_DEUDOR >= 41 and EDAD_DEUDOR <= 55 '
			END
		END

		IF @NOMBRE_VALOR LIKE '%4%'
		BEGIN
			IF @F_TIPODEUDA = ''
			BEGIN
				SET @F_TIPODEUDA = ' and EDAD_DEUDOR < 18 and EDAD_DEUDOR > 55 '
			END
			ELSE
			BEGIN
				SET @F_TIPODEUDA = @F_TIPODEUDA+' and EDAD_DEUDOR < 18 and EDAD_DEUDOR > 55 '
			END
		END

		set @sqlwhere = @sqlwhere + @F_TIPODEUDA
	END









	FETCH NEXT FROM CUR_FILTROS INTO @CODIGO_CONCEPTO, @NOMBRE_VALOR

END

CLOSE CUR_FILTROS
DEALLOCATE CUR_FILTROS




--REGLA SI NO HAY FILTROS, NO TRAER NADA
IF isnull(@sqlwhere, '') = '' 
BEGIN
	SET @sqlwhere = 'AND 1 = 2'
END

PRINT '_'+@sqlwhere+'_'

--return
--0.- PLANILLA_____________________________




	
	if object_id('tempdb..#DEUDA_COTIZ_EMPL', 'u') is not null drop table #DEUDA_COTIZ_EMPL
	if object_id('tempdb..#TMP_DEUDA_COTIZANTE', 'u') is not null drop table #TMP_DEUDA_COTIZANTE
	if object_id('tempdb..#origen_cotiz_empl', 'u') is not null drop table #origen_cotiz_empl
	if object_id('tempdb..#origen_lur_chq', 'u') is not null drop table #origen_lur_chq
	if object_id('tempdb..#tabla_final', 'u') is not null drop table #tabla_final
	if object_id('tempdb..#tfu', 'u') is not null drop table #tfu
	if object_id('tempdb..#compromiso', 'u') is not null drop table #compromiso
	if object_id('tempdb..#cobrador_asig', 'u') is not null drop table #cobrador_asig
	if object_id('tempdb..#f_supervisor_asig', 'u') is not null drop table #f_supervisor_asig 
	if object_id('tempdb..#f_vigencia_personas', 'u') is not null drop table #f_vigencia_personas
	if object_id('tempdb..#f_gestion29', 'u') is not null drop table #f_gestion29
	if object_id('tempdb..#f_compromiso_vencido', 'u') is not null drop table #f_compromiso_vencido
	if object_id('tempdb..#f_deuda_lur_con_credito', 'u') is not null drop table #f_deuda_lur_con_credito


--#TABLA_FINAL: TABLA DEL RESULTADO FINAL.



	create table #tabla_final
	(	rut_deudor char(10) not null
		, nombre_deudor varchar(100) null
		, email_destinatario varchar(100) null
		, deuda_cotizaciones numeric(15) null
		, monto_cupon numeric(15) null	--**
		, monto_posible_compensar numeric(15) null
		, cob_codigo numeric(5) null	--**
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
		, supervisor_asig numeric(4) null	--*
		, gestion29 varchar(2) null
		, ciu_codigo_reside numeric(4) null 
		, deuda_lur_con_credito varchar(2) null
		, edad_deudor numeric(4) null
		, compromiso_vencido datetime null
		, dnp numeric(4) null
		, dpp numeric(4) null
		, ip numeric(4) null
		, menor_per_deuda datetime null
		, mayor_per_deuda datetime null
		, tipo_deudor varchar(30) null
		, tipo_empresa varchar(30) null
		--, primary key (rut_deudor)
	)


--1.- Obtiene la deuda de cada COTIZANTE cuya responsabilidad de pago es de algún empleador

SELECT  COT_RUT, 
	DEC_PERIODO,
	SUM(CASE WHEN EPA_RUT IS NOT NULL THEN DEC_PACTADO - DEC_PAGADO END) AS DEUDA_EMPLEADOR
INTO #DEUDA_COTIZ_EMPL
FROM DEUDA_COTIZANTE with (nolock)
WHERE EPA_RUT IS NOT NULL
GROUP BY  COT_RUT, DEC_PERIODO

CREATE INDEX IDX_1 ON #deuda_cotiz_empl(COT_RUT,DEC_PERIODO)
-- select * FROM #DEUDA_COTIZ_EMPL		--343.790 reg en 9 seg


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
	CASE WHEN EPA_RUT  IS NOT NULL THEN 'EMPRESA' ELSE 'COTIZANTE' END AS tipo_empresa ,		--TIPO_DEUDOR se cambia a tipo_empresa
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
--select * from #TMP_DEUDA_COTIZANTE ORDER BY 1		--1.555.725 reg en 3min
--SELECT * FROM #TMP_DEUDA_COTIZANTE WHERE DEC_RUT = '  85213016'


--3.- --1.-TABLA_ORIGEN1: solo debe haber un rut por registro , se guardara en #origen_cotiz_empl
SELECT 
    d.dec_rut AS rut,
    SUM(ISNULL(d.dec_deuda, 0)) AS deuda,
    SUM(CASE WHEN d.dec_tipo_deuda = 'DNP' THEN 1 ELSE 0 END) AS dnp,
    SUM(CASE WHEN d.dec_tipo_deuda = 'DPP' THEN 1 ELSE 0 END) AS dpp,
    SUM(CASE WHEN d.dec_tipo_deuda = 'IP' THEN 1 ELSE 0 END) AS ip,
    MIN(d.dec_periodo) AS menor_per_deuda,
    MAX(d.dec_periodo) AS mayor_per_deuda, 
	MAX(D.tipo_empresa) as tipo_empresa
INTO #origen_cotiz_empl
FROM #TMP_DEUDA_COTIZANTE d
GROUP BY d.dec_rut

-- Crear índice no agrupado después de insertar los datos para evitar ralentizaciones durante la inserción y acelerar consultas posteriores.
create nonclustered index ix_origen_cotiz_empl_rut on #origen_cotiz_empl (rut)
--select * from #origen_cotiz_empl		--170.898 reg en 16 seg


--4.- TABLA_ORIGEN2: RUTS DE LUR Y CHQ (GCDF_DEUDA)

select
  DDR_rut as rut,
  sum(case when TDE_CODIGO = 1 then deu_monto else 0 end) as deuda_lur,
  sum(case when TDE_CODIGO = 2 then deu_monto else 0 end) as deuda_chq
INTO #origen_lur_chq
from dbo.GCDF_DEUDA gd with (nolock)
where deu_monto > 0
and TDE_CODIGO in (1, 2)
group by DDR_rut

create nonclustered index ix_origen_chq_rut on #origen_lur_chq (rut)
--select * from #origen_lur_chq		--9.425 reg en 0 seg.


--5.- INSERTAR #tabla_final LOS RUTS DE LOS 2 TABLAS_ORIGENES: #origen_cotiz_empl FULL OUTER JOIN #origen_lur_chq.

insert #tabla_final (rut_deudor, deuda_cotizaciones, dnp, dpp, ip, menor_per_deuda, mayor_per_deuda, deuda_lur, deuda_chq, tipo_empresa)
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
	, a.tipo_empresa
FROM
    (
		--UNIVERSO DEUDA COTIZACIONES
		SELECT rut,
			 deuda,
			dnp,
			dpp,
			ip,
			menor_per_deuda,
			mayor_per_deuda
			, tipo_empresa
		from #origen_cotiz_empl
    ) a
	FULL OUTER JOIN
    (
		--UNIVERSO LUR
        SELECT
             rut,
            deuda_lur,
             deuda_chq
		FROM #origen_lur_chq
    ) b
ON a.rut = b.rut;

-- crear índice no agrupado después de insertar los datos para evitar ralentizaciones durante la inserción y acelerar consultas posteriores.
create nonclustered index ix_tabla_final_rut on #tabla_final (rut_deudor)
--select * from #tabla_final		--177.234 reg en 16 seg

/* ejemplos de rut que estan en los dos universos:  130367534,  130381049
SELECT c.rut, *
from
#origen_cotiz_empl C
join #origen_lur_chq L
	on c.rut = l.rut
where  c.rut = ' 130367534'

select * from #tabla_final where rut_deudor = ' 130367534'
*/

--6.- TABLA TFU
declare @uf_mes numeric(10,2)
select @uf_mes = dbo.f_get_ufmes(getdate())

select dt.cot_rut rut, convert(numeric(12),sum(round(dtc_monto * @uf_mes,0)) )  as saldo_tfu 
into #tfu
from devolucion_tfu_cuota dt with (nolock)
join #tabla_final
	on rut_deudor = dt.cot_rut
where dt.afi_rut is null 
group by dt.cot_rut

create nonclustered index ix_tfu_rut on #tfu (rut)
-- select * from #tfu		--17.850 REG EN 0 seg


--7.- #compromiso: Obtener compromisos de pago GEC_COMPROM_MONTO y GEC_COMPROM_FECHA, tengo que ir a buscar el ultimo para e rut fecha digita

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
--select * from #compromiso		--42.212 reg en 2 seg


--8.- TABLA #cobrador_asig: Cob. Asignado deuda LUR o CHP

select distinct cob_codigo, ddr_rut rut--, deu_asig_desde
into #cobrador_asig
FROM GCDF_DEUDOR_ASIGNADO DAU with (NOLOCK)
WHERE  
(
	deu_asig_desde <= getdate() 
	and (deu_asig_hasta >= getdate() or deu_asig_hasta is null)
)  

create nonclustered index ix_cobrador_asig_rut on #cobrador_asig (rut)
--select * from #cobrador_asig		--15 reg en 0 seg


-- ZONA DE TABLAS FILTROS: COLUMNAS EN LA SALIDA PARA FITRAR 

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

create nonclustered index ix_f_supervisor_asig_rut on #f_supervisor_asig(cob_codigo)
-- select * from #f_supervisor_asig		--456 reg en 0 seg


--10.- FILTRO Tipo Deudor: Si tiene contrato vigente es VIGENTE, si tiene contrato pero no está vigente es NO VIGENTE y en otro caso es EMPRESA

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
--select * from #f_vigencia_personas		--148.109 reg en 7 seg


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

create nonclustered index ix_f_gestion29_rut on #f_gestion29(rut)
--select * from #f_gestion29		--0 reg en 0 seg


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
--select * from #f_compromiso_vencido		--115.463 reg en 5 seg


--13.- FILTRO Deuda LUR con Crédito	select DEU_CUOTAS, * from GCDF_DEUDA, f_deuda_lur_con_credito

select ddr_rut rut , case when sum(isnull(DEU_CUOTAS,0)) > 0 then 'Si' else 'No' end as deuda_lur_con_credito
into #f_deuda_lur_con_credito
from GCDF_DEUDA gc with (nolock)
join #tabla_final
	on rut_deudor = ddr_rut
group by ddr_rut

create nonclustered index ix_f_deuda_lur_con_credito_rut on #f_deuda_lur_con_credito(rut)
--select * from #f_deuda_lur_con_credito		--9.425 reg en 0 seg

-- FILTRO Tipo Empresa: PREGUNTAR A ALEX	******
-- FILTRO Rubro: PREGUNTAR A ALEX		*****
-- FILTRO Equipo : CONSULTAR A ALEX *************


--15 177.234 filas en 8 seg
UPDATE tf
SET 
	monto_posible_compensar = case when ( (isnull(DEUDA_cotizaciones, 0) + isnull(DEUDA_lur, 0)) >= tu.saldo_tfu  ) then  tu.saldo_tfu else (isnull(DEUDA_cotizaciones, 0) + isnull(DEUDA_lur, 0)) end,
    fecha_compromiso = c.fecha,
    monto_compromiso = c.monto,
    cobrador_asignado_lur_chq = c_asig.cob_codigo,
    supervisor_asig = sup.sco_codigo,
    tipo_deudor = COALESCE(vig.vigencia, 'EMPRESA'),
   -- gestion29 = COALESCE(ges.gestion29, 'No'),
    gestion29 = ges.gestion29,
    compromiso_vencido = compv.fecha,
    deuda_lur_con_credito = dlcc.deuda_lur_con_credito,
    nombre_deudor = d.ddr_nombre,
	cob_codigo = c2.COB_CODIGO,		--new
    nombre_ejecutivo = c2.cob_nombre,
    email_ejecutivo = c2.cob_EMAIL,
    fono_ejecutivo = c2.cob_FONO,
    fono_contacto = c2.cob_celular,
    ciu_codigo_reside = d.CIU_CODIGO
   , edad_deudor = dbo.f_edad(b.BNF_NACTO, GETDATE())		--***
   --, edad_deudor = (DATEDIFF(year,b.BNF_NACTO,GETDATE() )+ case when	( Month(GETDATE()) < Month(b.BNF_NACTO) Or (Month(GETDATE()) = Month(b.BNF_NACTO) And Day(GETDATE()) < day(b.BNF_NACTO))) Then -1 else 0 end)
FROM #tabla_final tf
LEFT JOIN #tfu tu ON tf.rut_deudor = tu.rut
LEFT JOIN #compromiso c ON tf.rut_deudor = c.rut
LEFT JOIN #cobrador_asig c_asig ON tf.rut_deudor = c_asig.rut
LEFT JOIN #f_supervisor_asig sup ON c_asig.cob_codigo = sup.cob_codigo
LEFT JOIN #f_vigencia_personas vig ON tf.rut_deudor = vig.rut
LEFT JOIN #f_gestion29 ges ON tf.rut_deudor = ges.rut
LEFT JOIN #f_compromiso_vencido compv ON tf.rut_deudor = compv.rut
LEFT JOIN #f_deuda_lur_con_credito dlcc ON tf.rut_deudor = dlcc.rut
LEFT JOIN deudor d ON tf.rut_deudor = d.ddr_rut
LEFT JOIN deudor_asignado da ON da.DDR_RUT = d.DDR_RUT 
   AND (da.DEU_ASIG_DESDE <= GETDATE() AND (da.DEU_ASIG_HASTA > GETDATE() OR da.DEU_ASIG_HASTA IS NULL))
LEFT JOIN cobrador c2 ON c2.COB_CODIGO = da.COB_CODIGO
LEFT JOIN BENEFICIARIO b ON b.BNF_RUT = d.DDR_RUT;


--select * #tabla_final		--177.234 reg en 1:14 seg


--SELECT 	rut_deudor
--		, nombre_deudor
--		, email_destinatario 
--		, deuda_cotizaciones 
--		, monto_cupon 
--		, monto_posible_compensar 
--		, cob_codigo
--		, nombre_ejecutivo 
--		, email_ejecutivo 
--		, fono_ejecutivo 
--		, url_link 
--		, url_link1 
--		, url_link2
--		, fecha_compromiso 
--		, monto_compromiso 
--		, deuda_lur 
--		, deuda_chq 
--		, cobrador_asignado_lur_chq 
--		, fono_contacto 
--		, supervisor_asig 
--		, gestion29 
--		, ciu_codigo_reside 
--		, deuda_lur_con_credito 
--		, edad_deudor 
--		, compromiso_vencido 
--		, dnp 
--		, dpp 
--		, ip 
--		, menor_per_deuda 
--		, mayor_per_deuda 
--		, tipo_deudor 
--		FROM #tabla_final


declare @sql1 nvarchar(4000)

set @sql1 = N'
SELECT 	rut_deudor
		, nombre_deudor
		, email_destinatario 
		, deuda_cotizaciones 
		, monto_cupon 
		, monto_posible_compensar 
		, cob_codigo
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
		, supervisor_asig 
		, gestion29 
		, ciu_codigo_reside 
		, deuda_lur_con_credito 
		, edad_deudor 
		, compromiso_vencido 
		, dnp 
		, dpp 
		, ip 
		, menor_per_deuda 
		, mayor_per_deuda 
		, tipo_deudor 
		, tipo_empresa
		FROM #tabla_final
		where 1 = 1 '+@sqlwhere

		exec sp_executesql @sql1
		if @@ERROR<>0
			begin
					rollback
					return 
			end


END