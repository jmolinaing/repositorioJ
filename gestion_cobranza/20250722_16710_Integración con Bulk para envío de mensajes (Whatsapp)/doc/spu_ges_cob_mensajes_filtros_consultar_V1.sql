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
	declare @codigo_varchar varchar(100)
	declare @descripcion varchar(100)

	declare @ID INT
	--declare @EPL_CODIGO varchar(50) 
	declare @ECO_CODIGO numeric(5, 0) 
	declare @EFI_VALOR nvarchar(4000)



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

			PRINT 'EPL_CODIGO: ' + ISNULL(@EPL_CODIGO, 'NULL') 
			+ ', ECO_CODIGO: ' + CAST(@ECO_CODIGO AS VARCHAR) 
			+ ', EFI_VALOR: ' + ISNULL(@EFI_VALOR, 'NULL');


			SELECT @codigo_varchar =	VALUE
			FROM DBO.F_SPLITSTRING(@EFI_VALOR, '|');


			INSERT INTO #FILTRO_V2
			SELECT @EPL_CODIGO
				, @ECO_CODIGO,
				VALUE
				, NULL
			FROM DBO.F_SPLITSTRING(@EFI_VALOR, '|');

			--Codigo_Concepto
			IF @ECO_CODIGO = 2		--Supervisor
			BEGIN
				--UPDATE #FILTRO_V2
				--SET DESCRIPCION = (SELECT )
				

				----SELECT COB_NOMBRE FROM COBRADOR WITH (NOLOCK) WHERE COB_CODIGO =  
				--@descripcion

				print @codigo_varchar
			END

			-- Obtener la siguiente fila
			FETCH NEXT FROM filtro_cursor INTO @ID, @ECO_CODIGO, @EFI_VALOR;
	END



	--SELECT * FROM #FILTRO_V2;

	--Codigo_Concepto
	--Nombre_Concepto
	--Codigo_Valor
	--Nombre_Valor
	--Seleccionado	--(S/N)

	SELECT 
	--id 
	 F.ECO_CODIGO AS Codigo_Concepto 
	, C.ECO_NOMBRE AS Nombre_Concepto
	, f.valor AS Codigo_Valor
	, f.descripcion AS Nombre_Valor
	, '' AS Seleccionado
	FROM #FILTRO_V2 F
	JOIN GCO_ENVMSG_CONCEPTO C WITH (NOLOCK)
		ON F.ECO_CODIGO = C.ECO_CODIGO
	order by f.id asc, F.ECO_CODIGO asc







END
