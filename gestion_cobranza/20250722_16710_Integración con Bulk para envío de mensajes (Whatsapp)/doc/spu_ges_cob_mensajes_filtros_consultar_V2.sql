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

CREATE PROCEDURE DBO.spu_ges_cob_mensajes_filtros_consultar
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

	IF OBJECT_ID(N'tempdb..#FILTRO_V1', N'U') IS NOT NULL DROP TABLE #FILTRO_V1
	IF OBJECT_ID(N'tempdb..#FILTRO_V2', N'U') IS NOT NULL DROP TABLE #FILTRO_V2
	IF OBJECT_ID(N'tempdb..#paso', N'U') IS NOT NULL DROP TABLE #paso

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

			--Supervisor
			IF @ECO_CODIGO = 2		
			BEGIN
				UPDATE #FILTRO_V2
				SET DESCRIPCION = (SELECT COB_NOMBRE FROM DBO.COBRADOR WHERE COB_CODIGO = CAST(@VALOR_UNI AS NUMERIC(10)))
				WHERE ID = @ID 
			END

			--Tipo y Vigencia Deudor
			IF @ECO_CODIGO = 5
			BEGIN
				UPDATE #FILTRO_V2
				SET DESCRIPCION = (case @VALOR_UNI when 'V' then 'Vigente' when 'N' then 'No Vigente' when 'E' then 'Empresa' else '' end)
				WHERE ID = @ID 
			END

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

--Supervisor
INSERT #FILTRO_V2 (EPL_CODIGO, ECO_CODIGO, VALOR_UNI, DESCRIPCION, SELECCIONADO)
select top 5 @epl_codigo
, 2 --supervisor
, CAST(c.cob_codigo AS varchar(100)) --VALOR_UNI
, c.cob_nombre --DESCRIPCION
, 'N'--SELECCIONADO
from dbo.cobrador c
where (COB_INIVIG >=getdate() and (COB_FINVIG <=getdate()) or COB_FINVIG is null) 
--and cob_codigo not in (select  CAST(VALOR_UNI AS NUMERIC(10)) from #FILTRO_V2)
and not exists (
				select * from #FILTRO_V2 v
				where v.VALOR_UNI = CAST(c.cob_codigo AS varchar(100))
				)
order by c.cob_codigo


--Tipo y Vigencia Deudor
INSERT #FILTRO_V2 (EPL_CODIGO, ECO_CODIGO, VALOR_UNI, DESCRIPCION, SELECCIONADO)
select 1 --@epl_codigo
, 5 --supervisor
, 'V' --VALOR_UNI
, 'Vigente'
, 'N'--SELECCIONADO
WHERE 1 = 1
and not exists (
				select * from #FILTRO_V2 v
				where ECO_CODIGO = 5
				and v.VALOR_UNI = 'V'
				)
UNION
select 1 --@epl_codigo
, 5 --supervisor
, 'N' --VALOR_UNI
, 'No Vigente'
, 'N'--SELECCIONADO
WHERE 1 = 1
and not exists (
				select * from #FILTRO_V2 v
				where ECO_CODIGO = 5
				and v.VALOR_UNI = 'N'
				)
UNION
select 1 --@epl_codigo
, 5 --supervisor
, 'E' --VALOR_UNI
, 'No Vigente'
, 'N'--SELECCIONADO
WHERE 1 = 1
and not exists (
				select * from #FILTRO_V2 v
				where ECO_CODIGO = 5
				and v.VALOR_UNI = 'E'
				)




--GRUPO o Equipo
INSERT #FILTRO_V2 (EPL_CODIGO, ECO_CODIGO, VALOR_UNI, DESCRIPCION, SELECCIONADO)
select 1 --@epl_codigo
, 1 --supervisor
, '1' --VALOR_UNI
, 'Equipo Interno'
, 'N'--SELECCIONADO
WHERE 1 = 1
and not exists (
				select * from #FILTRO_V2 v
				where ECO_CODIGO = 1
				and v.VALOR_UNI = '1'
				)
UNION
select 1 --@epl_codigo
, 1 --supervisor
, '2' --VALOR_UNI
, 'Equipo Stock'
, 'N'--SELECCIONADO
WHERE 1 = 1
and not exists (
				select * from #FILTRO_V2 v
				where ECO_CODIGO = 1
				and v.VALOR_UNI = '2'
				)
UNION
select 1 --@epl_codigo
, 1 --supervisor
, '3' --VALOR_UNI
, 'Equipo judicial'
, 'N'--SELECCIONADO
WHERE 1 = 1
and not exists (
				select * from #FILTRO_V2 v
				where ECO_CODIGO = 1
				and v.VALOR_UNI = '3'
				)



	--SELECT * FROM #FILTRO_V2;

	--Codigo_Concepto
	--Nombre_Concepto
	--Codigo_Valor
	--Nombre_Valor
	--Seleccionado	--(S/N)

	SELECT 
	 F.ECO_CODIGO AS CODIGO_CONCEPTO 
	, C.ECO_NOMBRE AS NOMBRE_CONCEPTO
	, F.VALOR_UNI AS CODIGO_VALOR
	, F.DESCRIPCION AS NOMBRE_VALOR
	, F.SELECCIONADO AS SELECCIONADO
	FROM #FILTRO_V2 F
	JOIN GCO_ENVMSG_CONCEPTO C WITH (NOLOCK)
		ON F.ECO_CODIGO = C.ECO_CODIGO
	ORDER BY  F.ECO_CODIGO ASC

END
