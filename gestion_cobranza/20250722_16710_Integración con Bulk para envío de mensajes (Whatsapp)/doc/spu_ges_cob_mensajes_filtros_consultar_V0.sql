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
insert into GCO_ENVMSG_FILTRO values ('1', 1, '1|2|3')

--select * from cobrador where cob_nombre like '%morales%'
--insert into GCO_ENVMSG_FILTRO values ('1', 2, 'A.SOTO|E.CABELLO|C.MORALES')
insert into GCO_ENVMSG_FILTRO values ('1', 2, '3|145|181')

--insert into GCO_ENVMSG_FILTRO values ('1', 3, 'Cob 1|Cob 2|Cob 3')
--insert into GCO_ENVMSG_FILTRO values ('1', 3, 'Cob 1|Cob 2|Cob 3')


--insert into GCO_ENVMSG_FILTRO values ('1', 4, 'A|B|C')
--insert into GCO_ENVMSG_FILTRO values ('1', 5, 'Vigente|No Vigente|Empresa')
insert into GCO_ENVMSG_FILTRO values ('1', 5, 'V|N|E')

SELECT * FROM [dbo].[f_SplitString] (
   'juanito|3|7','|')
GO


*/

--DROP TABLE #FILTRO

--EXECUTE spu_ges_cob_mensajes_filtros2 '1'

ALTER PROCEDURE DBO.spu_ges_cob_mensajes_filtros2
(
@epl_codigo varchar(50) 
)
as
BEGIN
	set nocount on;
	--DROP TABLE #FILTRO

	declare @i numeric(5)
	declare @hasta numeric(5)
	declare @codigo numeric(10)
	declare @descripcion varchar(100)
	declare @EFI_VALOR varchar(4000)


	IF OBJECT_ID(N'tempdb..#FILTRO_V1', N'U') IS NOT NULL DROP TABLE #FILTRO_V1
	IF OBJECT_ID(N'tempdb..#FILTRO_V2', N'U') IS NOT NULL DROP TABLE #FILTRO_V2
	IF OBJECT_ID(N'tempdb..#paso', N'U') IS NOT NULL DROP TABLE #paso

	CREATE TABLE #FILTRO_V1(
	ID int IDENTITY(1,1) primary key,
	EPL_CODIGO varchar(50) NOT NULL,
	ECO_CODIGO numeric(5, 0) NOT NULL,
	EFI_VALOR nvarchar(4000) NULL
	)

	CREATE TABLE #FILTRO_V2(
	ID int IDENTITY(1,1) primary key,
	EPL_CODIGO varchar(50)  NULL,
	ECO_CODIGO numeric(5, 0)  NULL,
	VALOR varchar(4000)  NULL,
	DESCRIPCION varchar(100) NULL
	)


	INSERT INTO #FILTRO_V1 (EPL_CODIGO, ECO_CODIGO, EFI_VALOR)
	SELECT 	EPL_CODIGO , ECO_CODIGO , EFI_VALOR 
	FROM GCO_ENVMSG_FILTRO
	WHERE EPL_CODIGO = @epl_codigo;

	set @i = 1
	select @hasta = count(*) from #FILTRO_V1;

	select * from #FILTRO_V1

	while @i <= @hasta
	begin




		--SELECT A.ID, B.id--, B.book_name, B.price
		--FROM #FILTRO_V1 A
		--CROSS APPLY dbo.f_SplitString((A.EFI_VALOR, '|')) B

--		SELECT OBJECT_SCHEMA_NAME(object_id), name, type_desc
--FROM sys.objects
--WHERE name = 'f_SplitString';


		--	select EFI_VALOR from #FILTRO_V1 where id = @i
		select @EFI_VALOR = EFI_VALOR from #FILTRO_V1 where id = @i


--SELECT t.ID, s.Value
--FROM #FILTRO_V1 t
--CROSS APPLY dbo.f_SplitString(t.EFI_VALOR, '|') s

		--print 'valor:'+ @EFI_VALOR

		--SELECT * FROM [dbo].[f_SplitString] (
		--   'juanito|3|7','|')
		--GO

		--SELECT * FROM [dbo].[f_SplitString] (
		--   'juanito|3|7','|')
		--GO

		-- SELECT * FROM [dbo].[f_SplitString] (@EFI_VALOR,'|')


	--	ID int IDENTITY(1,1) primary key,
	--EPL_CODIGO varchar(50)  NULL,
	--ECO_CODIGO numeric(5, 0)  NULL,
	--VALOR varchar(4000)  NULL,
	--DESCRIPCION


			insert into #FILTRO_V2
			 SELECT  null, null,
			 Value
			 , null

			FROM dbo.f_SplitString(@EFI_VALOR, '|');



			-- SELECT Value
			--INTO #FILTRO_V2
			--FROM dbo.f_SplitString(@EFI_VALOR, '|');

			-- Consultar resultados
			SELECT * FROM #FILTRO_V2;

	--INSERT INTO #FILTRO_V2 (EPL_CODIGO, ECO_CODIGO, VALOR, DESCRIPCION)
	--SELECT 	EPL_CODIGO , ECO_CODIGO , EFI_VALOR 
	--FROM GCO_ENVMSG_FILTRO
	--WHERE EPL_CODIGO = @epl_codigo;







		set @i = @i + 1
	end




	--SELECT * FROM #FILTRO

	--Codigo_Concepto
	--Nombre_Concepto
	--Codigo_Valor
	--Nombre_Valor
	--Seleccionado	--(S/N)

	--SELECT id 
	--	, F.ECO_CODIGO AS Codigo_Concepto 
	--	, C.ECO_NOMBRE AS Nombre_Concepto
	--	, '' AS Codigo_Valor
	--	, '' AS Nombre_Valor
	--	, '' AS Seleccionado
	--FROM #FILTRO_V1 F
	--JOIN GCO_ENVMSG_CONCEPTO C WITH (NOLOCK)
	--	ON F.ECO_CODIGO = C.ECO_CODIGO







END
