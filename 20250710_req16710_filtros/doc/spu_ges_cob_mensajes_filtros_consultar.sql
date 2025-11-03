/*=======================================================================================     
TIPO DE OBJETO     : Procedimiento Almacenado                                                                                                                                         
NOMBRE DEL OBJETO  : spu_ges_cob_mensajes_filtros_consultar                                                                                                           
PARAMETROS         : @epl_codigo: código plantilla  
 RETORNO            : Listado de conceptos y sus filtros.         
 CREADO POR         : Jorge Molina                
 FECHA CREACIÓN     : 01/08/2025                                                             
 DESCRIPCIÓN        : devuelva una estructura con las siguientes columnas:    
      • Codigo Concepto    
      • Nombre Concepto    
      • Codigo Valor    
      • Nombre Valor    
      • Seleccionado (S/N)    
     Utilizar ese SP para armar el Datawindows Treeview de los filtros.    
========================================================================================*/    
  
--EXECUTE spu_ges_cob_mensajes_filtros_consultar '1'    
--SELECT * FROM COBRADOR WHERE COB_CODIGO = 9000
    
CREATE PROCEDURE DBO.spu_ges_cob_mensajes_filtros_consultar    
(    
@epl_codigo varchar(50)      
)    
as    
BEGIN    
 set nocount on;    
     
 declare @ID INT      
 declare @ECO_CODIGO numeric(5, 0)  -- código concepto    
 declare @EFI_VALOR nvarchar(4000)  -- Valores de filtros agrupados concatenados con '|'  
    
 IF OBJECT_ID(N'tempdb..#TOTAL', N'U') IS NOT NULL DROP TABLE #TOTAL    
 IF OBJECT_ID(N'tempdb..#FILTRO_V1', N'U') IS NOT NULL DROP TABLE #FILTRO_V1    
 IF OBJECT_ID(N'tempdb..#FILTRO_V2', N'U') IS NOT NULL DROP TABLE #FILTRO_V2    
   
  
 --TABLA QUE DESPLEGARA TODOS LOS CONCEPTOS Y SUS FILTROS INDEPENDIENTE DE LOS SELECCIONADOS  
 CREATE TABLE #TOTAL(    
 ID int IDENTITY(1,1) primary key,    
 CODIGO_CONCEPTO numeric(5, 0) NOT NULL,    
 NOMBRE_CONCEPTO varchar(100) NULL,    
 CODIGO_VALOR varchar(100)  NULL,    
 NOMBRE_VALOR varchar(100)  NULL,    
 SELECCIONADO VARCHAR(1) NULL    
 )    
   
 --TABLA PASO DONDE SE VACIAN LOS REGISTROS DE LA TABLA GCO_ENVMSG_FILTRO  
 CREATE TABLE #FILTRO_V1(    
 ID int IDENTITY(1,1) primary key,    
 EPL_CODIGO varchar(50) NOT NULL,    
 ECO_CODIGO numeric(5, 0) NOT NULL,    
 EFI_VALOR nvarchar(4000) NULL,    
 )    
  
 --TABLA PASO2 DONDE SE DESGLOSAN LOS VALORES (EFI_VALOR) DE LA TABLA #FILTRO_V1  
 CREATE TABLE #FILTRO_V2(    
 ID int IDENTITY(1,1) primary key,    
 EPL_CODIGO varchar(50)  NULL,    
 ECO_CODIGO numeric(5, 0)  NULL,    
 VALOR_UNI varchar(100)  NULL,    
 DESCRIPCION varchar(100) NULL,    
 SELECCIONADO VARCHAR(1) NULL    
 )    
    
    
-- INSERT #TOTAL ______________________________  
 -- TIPO ENVIO    
 INSERT #TOTAL (CODIGO_CONCEPTO, NOMBRE_CONCEPTO, CODIGO_VALOR, NOMBRE_VALOR, SELECCIONADO)    
    SELECT 1, NULL, 1, 'correo' , NULL UNION    
    SELECT 1, NULL, 2, 'wsp' , NULL    
    
 -- LINK    
 INSERT #TOTAL (CODIGO_CONCEPTO, NOMBRE_CONCEPTO, CODIGO_VALOR, NOMBRE_VALOR, SELECCIONADO)    
    SELECT 2, NULL, 1, 'Con cupón' , NULL UNION    
    SELECT 2, NULL, 2, 'Sin cupón' , NULL    
    
 -- GRUPO o Equipo    
 INSERT #TOTAL (CODIGO_CONCEPTO, NOMBRE_CONCEPTO, CODIGO_VALOR, NOMBRE_VALOR, SELECCIONADO)    
    SELECT 3, NULL, 1, 'Equipo Interno' , NULL UNION    
    SELECT 3, NULL, 2, 'Equipo Stock' , NULL UNION    
    SELECT 3, NULL, 3, 'Equipo judicial' , NULL UNION    
    SELECT 3, NULL, 4, 'Otros' , NULL    
    
    
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
    SELECT 6, NULL, 1, 'A' , NULL UNION    
    SELECT 6, NULL, 2, 'B' , NULL UNION    
    SELECT 6, NULL, 3, 'C' , NULL    
    
 -- Tipo y Vigencia Deudor  , ALEX  
 INSERT #TOTAL (CODIGO_CONCEPTO, NOMBRE_CONCEPTO, CODIGO_VALOR, NOMBRE_VALOR, SELECCIONADO)    
    SELECT 7, NULL, 1, 'Vigente' , NULL UNION    
    SELECT 7, NULL, 2, 'No Vigente' , NULL UNION    
    SELECT 7, NULL, 3, 'Empresa' , NULL    
    
 -- Con Gestión Cód.. 29    
 INSERT #TOTAL (CODIGO_CONCEPTO, NOMBRE_CONCEPTO, CODIGO_VALOR, NOMBRE_VALOR, SELECCIONADO)    
    SELECT 8, NULL, 1, 'Con' , NULL UNION    
    SELECT 8, NULL, 2, 'Sin' , NULL     
  
 -- Fecha Compromiso vencido    
 INSERT #TOTAL (CODIGO_CONCEPTO, NOMBRE_CONCEPTO, CODIGO_VALOR, NOMBRE_VALOR, SELECCIONADO)    
    SELECT 9, NULL, 1, 'Vencidos (Compromiso Hoy-1)' , NULL UNION    
    SELECT 9, NULL, 2, 'No Vencidos (Compromiso >=Hoy)' , NULL     
    
 -- Tipo de Deuda    
 INSERT #TOTAL (CODIGO_CONCEPTO, NOMBRE_CONCEPTO, CODIGO_VALOR, NOMBRE_VALOR, SELECCIONADO)    
    SELECT 10, NULL, 1, 'Cotizaciones' , NULL UNION    
    SELECT 10, NULL, 2, 'Ley de Urgencia' , NULL UNION    
    SELECT 10, NULL, 3, 'Cheques Protestados' , NULL    
  
 -- Tipo Deuda Cotizaciones   
 INSERT #TOTAL (CODIGO_CONCEPTO, NOMBRE_CONCEPTO, CODIGO_VALOR, NOMBRE_VALOR, SELECCIONADO)    
    SELECT 11, NULL, 1, 'DNP' , NULL UNION    
    SELECT 11, NULL, 2, 'IP' , NULL UNION    
    SELECT 11, NULL, 3, 'DPP' , NULL    
  
 -- Menor Periodo de Deuda  ALEX  
 INSERT #TOTAL (CODIGO_CONCEPTO, NOMBRE_CONCEPTO, CODIGO_VALOR, NOMBRE_VALOR, SELECCIONADO)    
    SELECT 12, NULL, 1, 'Mes (Hoy - 180)' , NULL UNION    
    SELECT 12, NULL, 2, 'Mes (Hoy - 179)' , NULL UNION    
    SELECT 12, NULL, 3, 'Mes (Hoy - 178)' , NULL UNION    
    SELECT 12, NULL, 4, 'Otros' , NULL    
  
 -- Mayor Periodo de Deuda  ALEX  
 INSERT #TOTAL (CODIGO_CONCEPTO, NOMBRE_CONCEPTO, CODIGO_VALOR, NOMBRE_VALOR, SELECCIONADO)    
    SELECT 13, NULL, 1, 'Mes (Hoy - 2)' , NULL UNION    
    SELECT 13, NULL, 2, 'Mes (Hoy - 3)' , NULL UNION    
    SELECT 13, NULL, 3, 'Mes (Hoy - 4)' , NULL UNION    
    SELECT 13, NULL, 4, 'Otros' , NULL    
  
 --Ciudad de residencia del deudor  
 --select * from ciudad  
 INSERT #TOTAL (CODIGO_CONCEPTO, NOMBRE_CONCEPTO, CODIGO_VALOR, NOMBRE_VALOR, SELECCIONADO)    
 SELECT 14, NULL, CIU_CODIGO, CIU_NOMBRE, NULL    
 FROM CIUDAD WITH (NOLOCK) ORDER BY CIU_CODIGO    
  
  -- Deudores LUR con Crédito 5%    
 INSERT #TOTAL (CODIGO_CONCEPTO, NOMBRE_CONCEPTO, CODIGO_VALOR, NOMBRE_VALOR, SELECCIONADO)    
    SELECT 15, NULL, 1, 'SI' , NULL UNION    
    SELECT 15, NULL, 2, 'NO' , NULL     
  
  -- Tipo de Empresa  ALEX  
 INSERT #TOTAL (CODIGO_CONCEPTO, NOMBRE_CONCEPTO, CODIGO_VALOR, NOMBRE_VALOR, SELECCIONADO)    
    SELECT 16, NULL, 1, 'Publica' , NULL UNION    
    SELECT 16, NULL, 2, 'Privada' , NULL     
  
 -- Rubro Empresa ALEX  
 INSERT #TOTAL (CODIGO_CONCEPTO, NOMBRE_CONCEPTO, CODIGO_VALOR, NOMBRE_VALOR, SELECCIONADO)    
    SELECT 17, NULL, 1, 'Fundaciones' , NULL UNION    
    SELECT 17, NULL, 2, 'Corporaciones' , NULL UNION    
    SELECT 17, NULL, 3, 'Telecomunicaciones' , NULL UNION    
    SELECT 17, NULL, 4, 'Otras' , NULL  
  
  -- Posible Compensar x TFU    
 INSERT #TOTAL (CODIGO_CONCEPTO, NOMBRE_CONCEPTO, CODIGO_VALOR, NOMBRE_VALOR, SELECCIONADO)    
    SELECT 18, NULL, 1, 'SI' , NULL UNION    
    SELECT 18, NULL, 2, 'NO' , NULL     
  
 -- Edad Deudor  ALEX  
 INSERT #TOTAL (CODIGO_CONCEPTO, NOMBRE_CONCEPTO, CODIGO_VALOR, NOMBRE_VALOR, SELECCIONADO)    
    SELECT 19, NULL, 1, '18-25' , NULL UNION    
    SELECT 19, NULL, 2, '26-40' , NULL UNION    
    SELECT 19, NULL, 3, '41 - 55' , NULL UNION    
    SELECT 19, NULL, 4, 'Otros' , NULL  
  
  
  
 -- INSERT #FILTRO_V1 ________________________________  
 INSERT INTO #FILTRO_V1 (EPL_CODIGO, ECO_CODIGO, EFI_VALOR)    
 SELECT EPL_CODIGO , ECO_CODIGO , EFI_VALOR     
 FROM GCO_ENVMSG_FILTRO    
 WHERE EPL_CODIGO = @epl_codigo;    
  
  
  
 -- DESGLOSE DE VALORES E INSERT #FILTRO_V2 _________________________  
 DECLARE filtro_cursor CURSOR FOR    
 SELECT ID       
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
    
  
  
 --SELECT FINAL ______________  
 SELECT     
 CODIGO_CONCEPTO     
 , C.ECO_NOMBRE NOMBRE_CONCEPTO    
 , CODIGO_VALOR    
 , NOMBRE_VALOR    
 , CASE WHEN ISNULL(F.ID, 0)= 0 THEN 'N' ELSE 'S' END AS SELECCIONADO    
 , ECO_TIPO_SELECCION  
 FROM #TOTAL T    
 JOIN GCO_ENVMSG_CONCEPTO C WITH (NOLOCK)    
 ON T.CODIGO_CONCEPTO = C.ECO_CODIGO    
 LEFT JOIN #FILTRO_V2 F    
 ON F.VALOR_UNI = T.CODIGO_VALOR    
 AND T.CODIGO_CONCEPTO = F.ECO_CODIGO    
 ORDER BY T.CODIGO_CONCEPTO ASC    
    
  
END 