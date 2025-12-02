    
--GRANT EXECUTE ON [dbo].[spu_ges_cob_genera_cupon_deufin] TO [public]    
    
--========================================================================================     
-- TIPO DE OBJETO     : Procedimiento Almacenado                                                
--                                                                                              
-- NOMBRE DEL OBJETO  : spu_ges_cob_genera_cupon_deufin               
--                                                                                              
-- PARAMETROS         : @trama: compuesta por:                         
--      deu_correl1 | monto a rebajar1 | descuento1| deu_correl2 | monto a rebajar2 | descuento2|……..    
-- RETORNO            : 1: Exito , -1 Error          
-- CREADO POR         : Jorge Molina                
-- FECHA CREACIÓN     : 04/03/2024                                                             
-- DESCRIPCIÓN        : Procesa trama de descuentos de cupones que se guardan en CUPONPAGO_DEUFIN y CUPONPAGO_DEUFIN_DETALLE      
-- ========================================================================================     
    
    
--execute spu_ges_cob_genera_cupon_deufin '  67541111','OCATAVIO VEGA', '14601|100|0|14602|100|6'    
--execute spu_ges_cob_genera_cupon_deufin '  67541111','OCATAVIO VEGA', '14601|100|1'    
--execute spu_ges_cob_genera_cupon_deufin '  67541111','OCATAVIO VEGA', '14'    
/*    
SELECT * FROM dbo.CUPONPAGO_DEUFIN    
SELECT * FROM dbo.CUPONPAGO_DEUFIN_DETALLE    
*/    
--GRANT EXECUTE ON OBJECT::dbo.spu_ges_cob_mensajes_generar_cupones_deufin TO PUBLIC;  
--EXECUTE spu_ges_cob_mensajes_generar_cupones_deufin '2025-12-02 19:42:27.327'
    
--create PROCEDURE [dbo].[spu_ges_cob_genera_cupon_deufin] (@rut_deudor varchar(10), @nombre_deudor varchar(100), @trama varchar(8000))   
ALTER PROCEDURE [dbo].[spu_ges_cob_mensajes_generar_cupones_deufin] 
--(@rut_deudor varchar(10), @nombre_deudor varchar(100), @trama varchar(8000)) 
	@cup_id_base datetime
AS    
BEGIN    
 set nocount on;    
    
 DECLARE @trama2 varchar(8000)    
 DECLARE @posini int, @posfind int    
 DECLARE @largo int    
 DECLARE @deu_correl varchar(10)    
 DECLARE @monto_rebaja varchar(16)    
 DECLARE @descuento varchar(16)    
 DECLARE @cup_correl NUMERIC(15)    
   
 DECLARE @epa_rut CHAR(10)    
 DECLARE @epa_correl NUMERIC(2)    
 DECLARE @epa_razon varchar(200)    
 DECLARE @FECHA_HOY DATETIME 
 
 SET @FECHA_HOY = cast(CONVERT(varchar(8), GETDATE(), 112) as datetime) 
 --print @FECHA_HOY


BEGIN TRY     
       
 IF (OBJECT_ID('TEMPDB..#CORREL') IS NOT NULL)    
   DROP TABLE #correl    
   CREATE TABLE #correl (correl numeric(15))    
    
    IF (OBJECT_ID('TEMPDB..#TEMP_CUPON') IS NOT NULL)    
  DROP TABLE #TEMP_CUPON    
  create table #TEMP_CUPON (deu_correl numeric(10), monto_rebaja numeric(16), descuento numeric(16) )    

 --SELECT * FROM #TEMP_CUPON    
 --RETURN 1    

 --select * FROM [evolution].[ISAPRE].DBO.GCO_ENVMSG_DEUDA_CUPONES_DEUFIN
 
	--1.-Traspasar los registros de evolution
	SELECT CUP_ID_BASE
			,COT_RUT
			,NOM_DEUDOR      --VARCHAR(200) NULL   
			,DEU_CORREL      --NUMERIC(15) NULL 
			,DEU_MONTO       --NUMERIC(15) NULL -- MONTO_DEUDA
			,DEU_DESCUENTO   --NUMERIC(15) NULL
	INTO #DEUDA_CUPONES_DEUFIN
	FROM [evolution].[ISAPRE].DBO.GCO_ENVMSG_DEUDA_CUPONES_DEUFIN WITH (NOLOCK)
	WHERE CUP_ID_BASE = @cup_id_base

    -- Nuevo Validar que se hayan insertado filas
    IF @@ROWCOUNT = 0
    BEGIN
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        RAISERROR('No se insertó ningún registro en #DEUDA_CUPONES_DEUFIN.', 16, 1);
        RETURN;
    END



 --GENERAR CORRELATIVO CUPON    
 DELETE FROM #correl    
    
 INSERT INTO #correl    
 EXEC EVOLUTION.ISAPRE.dbo.spu_nuevo_correl 'CUPONPAGO_DEUFIN'  --EVOLUTION.ISAPRE    
    
 SELECT @cup_correl = correl from #correl    
    
 --PRINT @cup_correl    
    
 IF (@@error <> 0) OR (@cup_correl=0) OR (@cup_correl IS NULL)     
 BEGIN    
  --RAISERROR ('Error: No fue posible obtener un número CORRELATIVO DEL CUPON DE PAGO.', 16, 1)    
  --ROLLBACK    
  --RETURN -1     
  SELECT -1, 'Error: No fue posible obtener un número CORRELATIVO DEL CUPON DE PAGO.'    
  RETURN      
 END     
      
    
 -- INSERT _____________________________________________________    
 --CUPONPAGO_DEUFIN    
 --select * from CUPONPAGO_DEUFIN    
 --CUP_CORREL numeric(15) not null    
 --USU_LOGIN char(50) not null    
 --CUP_FECHAREG datetime not null    
 --DDR_RUT char(10) not null    
 --DDR_NOMBRE varchar(100) not null    
 --CUP_FECHAPAGO datetime null    
    
 ----V0   
 --INSERT INTO CUPONPAGO_DEUFIN     
 --  (CUP_CORREL    
 --  , USU_LOGIN    
 --  , CUP_FECHAREG    
 --  , DDR_RUT    
 --  , DDR_NOMBRE    
 --  , CUP_FECHAPAGO)     
 --VALUES     
 --  (    
 --  @CUP_CORREL,     
 --   SYSTEM_USER,     
 --   @FECHA_HOY,     
 --   @RUT_DEUDOR,				--YA NO VA
 --   @NOMBRE_DEUDOR,				--YA NO VA
 --   NULL    
 --   ) 
 

  --V1   
 INSERT INTO      
   (CUP_CORREL    
   , USU_LOGIN    
   , CUP_FECHAREG    
   , DDR_RUT    
   , DDR_NOMBRE    
   , CUP_FECHAPAGO)     
SELECT DISTINCT @CUP_CORREL     
    , SYSTEM_USER     
    , @cup_id_base		--@FECHA_HOY     
	, COT_RUT
	, NOM_DEUDOR      --VARCHAR(200) NULL  
    , NULL    
FROM #DEUDA_CUPONES_DEUFIN

    
    
  --CUPONPAGO_DEUFIN_DETALLE    
  --select * from CUPONPAGO_DEUFIN_DETALLE    
  --CUP_CORREL numeric(15) not null    
  --DEU_CORREL numeric(10) not null    
  --CDD_MONTO_REBAJA numeric(16) not null    
  --CDD_DESCUENTO numeric(16) not null    
    
  --CREAR REGISTROS PLANILLAS DEL CUPON DE PAGO  
 ---- -V0
 -- INSERT INTO CUPONPAGO_DEUFIN_DETALLE     
 --  (    
 --  CUP_CORREL    
 --  , DEU_CORREL    
 --  , CDD_MONTO_REBAJA    
 --  , CDD_DESCUENTO      
 --  )    
 -- SELECT @cup_correl    
 --  , deu_correl    
 --  , monto_rebaja    
 --  , descuento     
 -- FROM #TEMP_CUPON    

   INSERT INTO CUPONPAGO_DEUFIN_DETALLE     
   (    
   CUP_CORREL    
   , DEU_CORREL    
   , CDD_MONTO_REBAJA    
   , CDD_DESCUENTO      
   )    
  SELECT @cup_correl    
   , deu_correl    
   , DEU_MONTO    
   , DEU_DESCUENTO     
 FROM #DEUDA_CUPONES_DEUFIN


    
  ----GENERAR LINK CUPON DE PAGO    
     
  ----SELECT 1, 'EXITO'   
  ----SELECT 1, 'https://deufinqa.nuevamasvida.cl/?ID=' + CONVERT(VARCHAR(MAX), DBO.F_CONEX_ENCRIP(@cup_correl),1)  --En ambiente de QA  
  --SELECT 1, 'https://deufin.nuevamasvida.cl/?ID=' + CONVERT(VARCHAR(MAX), DBO.F_CONEX_ENCRIP(@cup_correl),1) --En ambiente de Prod  


  select DISTINCT cup_correl
	  , 'https://pcotiz.nuevamasvida.cl/?ID=' + CONVERT(VARCHAR(MAX), dbo.f_conex_encrip(cup_correl), 1) as link
	  , COT_RUT		--JMOLINA V1
  into #paso_cupones_link  
  from #DEUDA_CUPONES_DEUFIN  
   
  create index i1 on #paso_cupones_link (cup_correl)  

	SELECT link, cup_correl , rut 
	FROM #paso_cupones_link  

    
END TRY      
      
    
BEGIN CATCH      
  SELECT -1, ERROR_MESSAGE()    
END CATCH      
    
    
     
END     
    
    