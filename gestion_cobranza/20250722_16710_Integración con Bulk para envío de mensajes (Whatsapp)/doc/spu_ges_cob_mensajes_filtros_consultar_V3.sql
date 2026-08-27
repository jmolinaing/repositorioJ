/*
Lectura de Filtros:
Implementar un SP spu_ges_cob_mensajes_filtros_consultar (@epl_codigo) que devuelva una estructura con las siguientes columnas:
•	Codigo Concepto
•	Nombre Concepto
•	Codigo Valor
•	Nombre Valor
•	Seleccionado (S/N)
Utilizar ese SP para armar el Datawindows Treeview de los filtros.



select * from GCO_ENVMSG_PLANTILLA
select * from GCO_ENVMSG_CONCEPTO
select * from GCO_ENVMSG_FILTRO
select * from GCO_ENVMSG_programa




TIPO ENVIO
LINK
GRUPO o Equipo
Supervisor
Cobrador Asignado
Grupo Deuda
7Tipo y Vigencia Deudor
8Con Gestión Cód.. 29
9Fecha Compromiso vencido
10Tipo de Deuda
11Tipo Deuda Cotizaciones
12Menor Periodo de Deuda
13Cuidad Residencia
14Deudores LUR con Crédito 5%
15Tipo de Empresa
16Rubro Empresa
17Posible Compensar x TFU
18Edad Deudor

--DELETE GCO_ENVMSG_FILTRO
--DELETE GCO_ENVMSG_CONCEPTO

--ECO_TIPO_SELECCION M, S
insert into GCO_ENVMSG_CONCEPTO values (1, 'TIPO ENVIO', 'S')
insert into GCO_ENVMSG_CONCEPTO values (2, 'LINK', 'S')
insert into GCO_ENVMSG_CONCEPTO values (3, 'GRUPO o Equipo', 'M')
insert into GCO_ENVMSG_CONCEPTO values (4, 'Supervisor', 'M')
insert into GCO_ENVMSG_CONCEPTO values (5, 'Cobrador Asignado', 'M')
insert into GCO_ENVMSG_CONCEPTO values (6, 'Grupo Deuda', 'M')
insert into GCO_ENVMSG_CONCEPTO values (7, 'Tipo y Vigencia Deudor', 'M')
insert into GCO_ENVMSG_CONCEPTO values (8, 'Con Gestión Cód.. 29', 'M')
insert into GCO_ENVMSG_CONCEPTO values (9, 'Fecha Compromiso vencido', 'M')
insert into GCO_ENVMSG_CONCEPTO values (10, 'Tipo de Deuda', 'S')
insert into GCO_ENVMSG_CONCEPTO values (11, 'Tipo Deuda Cotizaciones', 'M')
insert into GCO_ENVMSG_CONCEPTO values (12, 'Menor Periodo de Deuda', 'M')
insert into GCO_ENVMSG_CONCEPTO values (13, 'Mayor Periodo de Deuda', 'M')
insert into GCO_ENVMSG_CONCEPTO values (14, 'Cuidad Residencia', 'M')
insert into GCO_ENVMSG_CONCEPTO values (15, 'Deudores LUR con Crédito 5%', 'M')
insert into GCO_ENVMSG_CONCEPTO values (16, 'Tipo de Empresa', 'M')
insert into GCO_ENVMSG_CONCEPTO values (17, 'Rubro Empresa', 'M')
insert into GCO_ENVMSG_CONCEPTO values (18, 'Posible Compensar x TFU', 'M')
insert into GCO_ENVMSG_CONCEPTO values (19, 'Edad Deudor', 'M')








delete GCO_ENVMSG_FILTRO

--insert into GCO_ENVMSG_FILTRO values ('1', 1, 'Equipo Interno|Equipo Stock|Equipo judicial')
insert into GCO_ENVMSG_FILTRO values ('1', 1, '1|3')

--select * from cobrador where cob_nombre like '%morales%'
--insert into GCO_ENVMSG_FILTRO values ('1', 2, 'A.SOTO|E.CABELLO|C.MORALES')
insert into GCO_ENVMSG_FILTRO values ('1', 2, '3|145|181')

--insert into GCO_ENVMSG_FILTRO values ('1', 3, 'Cob 1|Cob 2|Cob 3')
--insert into GCO_ENVMSG_FILTRO values ('1', 3, 'Cob 1|Cob 2|Cob 3')


--insert into GCO_ENVMSG_FILTRO values ('1', 4, 'A|B|C')
--insert into GCO_ENVMSG_FILTRO values ('1', 5, 'Vigente|No Vigente|Empresa')
insert into GCO_ENVMSG_FILTRO values ('1', 5, 'V|N')

SELECT * FROM [dbo].[f_SplitString] (
   'juanito|3|7','|')
GO


*/

--DROP TABLE #FILTRO

--EXECUTE spu_ges_cob_mensajes_filtros_consultar '1'

ALTER PROCEDURE DBO.spu_ges_cob_mensajes_filtros_consultar
(
@epl_codigo varchar(50)		--código plantilla
)
as
BEGIN
	set nocount on;
	--DROP TABLE #FILTRO

	declare @i numeric(5)
	declare @hasta numeric(5)
	declare @codigo_varchar varchar(100)
	declare @descripcion varchar(100)
	declare @VALOR_UNI varchar(100)
	

	declare @ID INT
	--declare @EPL_CODIGO varchar(50) 
	declare @ECO_CODIGO numeric(5, 0)		--código concepto
	declare @EFI_VALOR nvarchar(4000)

	IF OBJECT_ID(N'tempdb..#TOTAL', N'U') IS NOT NULL DROP TABLE #TOTAL
	IF OBJECT_ID(N'tempdb..#FILTRO_V1', N'U') IS NOT NULL DROP TABLE #FILTRO_V1
	IF OBJECT_ID(N'tempdb..#FILTRO_V2', N'U') IS NOT NULL DROP TABLE #FILTRO_V2
	IF OBJECT_ID(N'tempdb..#paso', N'U') IS NOT NULL DROP TABLE #paso

	CREATE TABLE #TOTAL(
	ID int IDENTITY(1,1) primary key,
	CODIGO_CONCEPTO numeric(5, 0) NOT NULL,
	NOMBRE_CONCEPTO varchar(100) NULL,
	CODIGO_VALOR varchar(100)  NULL,
	NOMBRE_VALOR varchar(100)  NULL,
	SELECCIONADO VARCHAR(1) NULL
	)

	CREATE TABLE #FILTRO_V1(
	ID int IDENTITY(1,1) primary key,
	EPL_CODIGO varchar(50) NOT NULL,
	ECO_CODIGO numeric(5, 0) NOT NULL,
	EFI_VALOR nvarchar(4000) NULL,
	)

	CREATE TABLE #FILTRO_V2(
	ID int IDENTITY(1,1) primary key,
	EPL_CODIGO varchar(50)  NULL,
	ECO_CODIGO numeric(5, 0)  NULL,
	VALOR_UNI varchar(100)  NULL,
	DESCRIPCION varchar(100) NULL,
	SELECCIONADO VARCHAR(1) NULL
	)



	-- TIPO ENVIO
	INSERT #TOTAL (CODIGO_CONCEPTO, NOMBRE_CONCEPTO, CODIGO_VALOR, NOMBRE_VALOR, SELECCIONADO)
				SELECT 1, NULL, 1, 'correo'	, NULL UNION
				SELECT 1, NULL, 2, 'wsp'	, NULL

	-- LINK
	INSERT #TOTAL (CODIGO_CONCEPTO, NOMBRE_CONCEPTO, CODIGO_VALOR, NOMBRE_VALOR, SELECCIONADO)
				SELECT 2, NULL, 1, 'Con cupón'	, NULL UNION
				SELECT 2, NULL, 2, 'Sin cupón'	, NULL

	-- GRUPO o Equipo
	INSERT #TOTAL (CODIGO_CONCEPTO, NOMBRE_CONCEPTO, CODIGO_VALOR, NOMBRE_VALOR, SELECCIONADO)
				SELECT 3, NULL, 1, 'Equipo Interno'	, NULL UNION
				SELECT 3, NULL, 2, 'Equipo Stock'	, NULL UNION
				SELECT 3, NULL, 3, 'Equipo judicial'	, NULL UNION
				SELECT 3, NULL, 4, 'Otros'	, NULL



	--SUPERVISOR
	INSERT #TOTAL (CODIGO_CONCEPTO, NOMBRE_CONCEPTO, CODIGO_VALOR, NOMBRE_VALOR, SELECCIONADO)
	SELECT 4, NULL, S.SCO_CODIGO, S.USU_LOGIN, NULL
	FROM DBO.SUPERVISOR_COB S WITH (NOLOCK)
	WHERE EXISTS (SELECT * FROM USUARIO U WITH (NOLOCK) 
					WHERE USU_FINVIG IS NULL AND S.USU_LOGIN = U.USU_LOGIN)

	--Cobrador Asignado
	INSERT #TOTAL (CODIGO_CONCEPTO, NOMBRE_CONCEPTO, CODIGO_VALOR, NOMBRE_VALOR, SELECCIONADO)
	SELECT 5, NULL, COB_CODIGO, COB_NOMBRE, NULL
	FROM COBRADOR WHERE COB_FINVIG IS NULL AND EXISTS (SELECT * FROM USUARIO WHERE USU_FINVIG IS NULL AND COBRADOR.COB_RUT=USUARIO.USU_RUT)

	-- GRUPO o Equipo
	INSERT #TOTAL (CODIGO_CONCEPTO, NOMBRE_CONCEPTO, CODIGO_VALOR, NOMBRE_VALOR, SELECCIONADO)
				SELECT 6, NULL, 1, 'A'	, NULL UNION
				SELECT 6, NULL, 2, 'B'	, NULL UNION
				SELECT 6, NULL, 3, 'C'	, NULL

	-- Tipo y Vigencia Deudor
	INSERT #TOTAL (CODIGO_CONCEPTO, NOMBRE_CONCEPTO, CODIGO_VALOR, NOMBRE_VALOR, SELECCIONADO)
				SELECT 7, NULL, 1, 'Vigente'	, NULL UNION
				SELECT 7, NULL, 2, 'No Vigente'	, NULL UNION
				SELECT 7, NULL, 3, 'Empresa'	, NULL

	-- Con Gestión Cód.. 29
	INSERT #TOTAL (CODIGO_CONCEPTO, NOMBRE_CONCEPTO, CODIGO_VALOR, NOMBRE_VALOR, SELECCIONADO)
				SELECT 8, NULL, 1, 'Con'	, NULL UNION
				SELECT 8, NULL, 2, 'Sin'	, NULL 



	INSERT INTO #FILTRO_V1 (EPL_CODIGO, ECO_CODIGO, EFI_VALOR)
	SELECT 	EPL_CODIGO , ECO_CODIGO , EFI_VALOR 
	FROM GCO_ENVMSG_FILTRO
	WHERE EPL_CODIGO = @epl_codigo;


DECLARE filtro_cursor CURSOR FOR
	SELECT ID 
		--EPL_CODIGO 
		, ECO_CODIGO 
		, EFI_VALOR 
	FROM #FILTRO_V1;

	OPEN filtro_cursor;

	FETCH NEXT FROM filtro_cursor INTO @ID, @ECO_CODIGO, @EFI_VALOR

	WHILE @@FETCH_STATUS = 0
	BEGIN

			INSERT INTO #FILTRO_V2
			SELECT @EPL_CODIGO
				, @ECO_CODIGO,
				VALUE
				, null
				, 'S'
			FROM DBO.F_SPLITSTRING(@EFI_VALOR, '|');

			FETCH NEXT FROM filtro_cursor INTO @ID, @ECO_CODIGO, @EFI_VALOR;
	END

CLOSE filtro_cursor;
DEALLOCATE filtro_cursor;



DECLARE filtro_cursor2 CURSOR FOR
	SELECT ID 
		--EPL_CODIGO 
		, ECO_CODIGO 
		, ISNULL(VALOR_UNI, '')
	FROM #FILTRO_V2;

	OPEN filtro_cursor2;

	FETCH NEXT FROM filtro_cursor2 INTO @ID, @ECO_CODIGO, @VALOR_UNI

	WHILE @@FETCH_STATUS = 0
	BEGIN

			--GRUPO o Equipo
			IF @ECO_CODIGO = 1		
			BEGIN
				UPDATE #FILTRO_V2
				SET DESCRIPCION = (case @VALOR_UNI when '1' then 'Equipo Interno' when '2' then 'Equipo Stock' when '3' then 'Equipo judicial' else '' end)
				WHERE ID = @ID 
			END

			----Supervisor
			--IF @ECO_CODIGO = 2		
			--BEGIN
			--	UPDATE #FILTRO_V2
			--	SET DESCRIPCION = (SELECT COB_NOMBRE FROM DBO.COBRADOR WHERE COB_CODIGO = CAST(@VALOR_UNI AS NUMERIC(10)))
			--	WHERE ID = @ID 
			--END

			----Tipo y Vigencia Deudor
			--IF @ECO_CODIGO = 5
			--BEGIN
			--	UPDATE #FILTRO_V2
			--	SET DESCRIPCION = (case @VALOR_UNI when 'V' then 'Vigente' when 'N' then 'No Vigente' when 'E' then 'Empresa' else '' end)
			--	WHERE ID = @ID 
			--END

			FETCH NEXT FROM filtro_cursor2 INTO @ID, @ECO_CODIGO, @VALOR_UNI;
	END

CLOSE filtro_cursor2;
DEALLOCATE filtro_cursor2;


	--CREATE TABLE #FILTRO_V2(
	--ID int IDENTITY(1,1) primary key,
	--EPL_CODIGO varchar(50)  NULL,
	--ECO_CODIGO numeric(5, 0)  NULL,
	--VALOR_UNI varchar(100)  NULL,
	--DESCRIPCION varchar(100) NULL,
	--SELECCIONADO VARCHAR(1) NULL





	--SELECT * FROM #FILTRO_V2;

	--Codigo_Concepto
	--Nombre_Concepto
	--Codigo_Valor
	--Nombre_Valor
	--Seleccionado	--(S/N)

	--SELECT 
	-- F.ECO_CODIGO AS CODIGO_CONCEPTO 
	--, C.ECO_NOMBRE AS NOMBRE_CONCEPTO
	--, F.VALOR_UNI AS CODIGO_VALOR
	--, F.DESCRIPCION AS NOMBRE_VALOR
	--, F.SELECCIONADO AS SELECCIONADO
	--FROM #FILTRO_V2 F
	--JOIN GCO_ENVMSG_CONCEPTO C WITH (NOLOCK)
	--	ON F.ECO_CODIGO = C.ECO_CODIGO
	--ORDER BY  F.ECO_CODIGO ASC

	SELECT 
	 CODIGO_CONCEPTO 
	, C.ECO_NOMBRE NOMBRE_CONCEPTO
	, CODIGO_VALOR
	, NOMBRE_VALOR
	, CASE WHEN ISNULL(F.ID, 0)= 0 THEN 'N' ELSE 'S' END AS SELECCIONADO
	FROM #TOTAL T
	JOIN GCO_ENVMSG_CONCEPTO C WITH (NOLOCK)
		ON T.CODIGO_CONCEPTO = C.ECO_CODIGO
	LEFT JOIN #FILTRO_V2 F
		ON F.VALOR_UNI = T.CODIGO_VALOR
		AND T.CODIGO_CONCEPTO = F.ECO_CODIGO
	ORDER BY T.CODIGO_CONCEPTO ASC



END
