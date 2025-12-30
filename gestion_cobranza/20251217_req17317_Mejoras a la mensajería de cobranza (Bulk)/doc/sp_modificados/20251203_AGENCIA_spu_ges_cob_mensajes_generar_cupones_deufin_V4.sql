/*
========================================================================================     
 TIPO DE OBJETO     : Procedimiento Almacenado                                                                                                                                           
 NOMBRE DEL OBJETO  : spu_ges_cob_mensajes_generar_cupones_deufin                                                                                                       
 PARAMETROS         : @cup_id_base: parameto fecha                          
 RETORNO            : Listado de link_cupones.          
 CREADO POR         : Jorge Molina                
 FECHA CREACIÓN     : 04/03/2024                                                             
 DESCRIPCIÓN        : Procesa registros de descuentos de cupones desde:
						[evolution].[ISAPRE].DBO.GCO_ENVMSG_DEUDA_CUPONES_DEUFIN
						a CUPONPAGO_DEUFIN y CUPONPAGO_DEUFIN_DETALLE      
 ========================================================================================
 */     
--GRANT EXECUTE ON OBJECT::dbo.spu_ges_cob_mensajes_generar_cupones_deufin TO PUBLIC;
/* 
--EJERCICIO1
EXECUTE spu_ges_cob_mensajes_generar_cupones_deufin '2025-12-02 19:42:27.327'

--REVISION EJERCICIO1
SELECT * FROM dbo.CUPONPAGO_DEUFIN where cup_fechareg = '2025-12-04 12:35:21.207'   
SELECT * FROM dbo.CUPONPAGO_DEUFIN_DETALLE where cup_correl in (SELECT cup_correl FROM dbo.CUPONPAGO_DEUFIN where cup_fechareg = '2025-12-04 12:35:21.207' )
select * FROM [evolution].[ISAPRE].DBO.GCO_ENVMSG_DEUDA_CUPONES_DEUFIN where cup_id_base = '2025-12-04 12:35:21.207'

*/    

ALTER PROCEDURE [dbo].[spu_ges_cob_mensajes_generar_cupones_deufin] 
	@cup_id_base datetime
AS    
BEGIN    
	SET NOCOUNT ON;
	--SET XACT_ABORT ON;		--para rollback automático en errores.
            
	DECLARE @CUP_CORREL NUMERIC(15)
	DECLARE @FOLIO_FIN NUMERIC(15)   	
	DECLARE @FECHA_HOY DATETIME 
	DECLARE @CANT_REG  NUMERIC(20)
	DECLARE @OPERACION VARCHAR(100);
 
	SET @FECHA_HOY = CAST(CONVERT(VARCHAR(8), GETDATE(), 112) AS DATETIME)
	SET @OPERACION = ''
	
    --si existen tablas temporales con el nombre indicado en tempdb, eliminarla.
	IF OBJECT_ID('TEMPDB..#DEUDA_CUPONES_DEUFIN_DETALLE', 'U') IS NOT NULL DROP TABLE #DEUDA_CUPONES_DEUFIN_DETALLE 
	IF OBJECT_ID('TEMPDB..#DEUDA_CUPONES_DEUFIN_AGRUPADA', 'U') IS NOT NULL DROP TABLE #DEUDA_CUPONES_DEUFIN_AGRUPADA
	IF OBJECT_ID('TEMPDB..#CUP_CORREL', 'U') IS NOT NULL DROP TABLE #CUP_CORREL 
	IF OBJECT_ID('TEMPDB..#TMP_CUPONPAGO_DEUFIN', 'U') IS NOT NULL DROP TABLE #TMP_CUPONPAGO_DEUFIN


	--Creación de tablas temporales
	CREATE TABLE #DEUDA_CUPONES_DEUFIN_DETALLE(
		CUP_ID_BASE datetime NOT NULL,
		COT_RUT char(10) NOT NULL,
		NOM_DEUDOR varchar(200) NULL,
		DEU_CORREL numeric(15, 0) NULL,
		DEU_MONTO numeric(15, 0) NULL,
		DEU_DESCUENTO numeric(15, 0) NULL,
		CUP_CORREL NUMERIC(15, 0) NULL--, 
		--LINK_CUPON VARCHAR(200) NULL
	) 

	CREATE TABLE #DEUDA_CUPONES_DEUFIN_AGRUPADA(
		USU_LOGIN char(50) NULL,
		CUP_FECHAREG datetime NULL,
		DDR_RUT char(10) NULL,
		DDR_NOMBRE varchar(100) NULL,
		CUP_FECHAPAGO datetime NULL,
		CUP_CORREL numeric(15, 0) NULL
	)

	CREATE TABLE #CUP_CORREL (FOLIO_INI NUMERIC(15), FOLIO_FIN NUMERIC(15))  

	CREATE TABLE #TMP_CUPONPAGO_DEUFIN(
		CUP_CORREL numeric(15, 0) NULL,
		USU_LOGIN char(50) NULL,
		CUP_FECHAREG datetime NULL,
		DDR_RUT char(10) NULL,
		DDR_NOMBRE varchar(100) NULL,
		CUP_FECHAPAGO datetime NULL
	)


	--BEGIN TRY
	
	--		BEGIN TRAN;

			--1.-Traspasar los registros de evolution TABLA PASO GCO_ENVMSG_DEUDA_CUPONES_DEUFIN
			SET @OPERACION = 'INSERT #DEUDA_CUPONES_DEUFIN_DETALLE'

			INSERT INTO #DEUDA_CUPONES_DEUFIN_DETALLE
						(CUP_ID_BASE
						, COT_RUT
						, NOM_DEUDOR
						, DEU_CORREL
						, DEU_MONTO
						, DEU_DESCUENTO
						, CUP_CORREL
						--, LINK_CUPON
						)
			SELECT CUP_ID_BASE
					, COT_RUT
					, SUBSTRING(NOM_DEUDOR, 1, 200)      --VARCHAR(200) NULL   
					, DEU_CORREL      --NUMERIC(15) NULL 
					, DEU_MONTO       --NUMERIC(15) NULL -- MONTO_DEUDA
					, DEU_DESCUENTO   --NUMERIC(15) NULL
					, NULL
					--, NULL
			FROM [evolution].[ISAPRE].DBO.GCO_ENVMSG_DEUDA_CUPONES_DEUFIN WITH (NOLOCK)
			WHERE CUP_ID_BASE = @cup_id_base

			-- Nuevo Validar que se hayan insertado filas
			IF @@ROWCOUNT = 0
			BEGIN
				--IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

				RAISERROR('No se insertó ningún registro en #DEUDA_CUPONES_DEUFIN_DETALLE.', 16, 1);
				RETURN;
			END

			SET @OPERACION = 'INSERT #DEUDA_CUPONES_DEUFIN_AGRUPADA'

			INSERT INTO #DEUDA_CUPONES_DEUFIN_AGRUPADA    
			   ( USU_LOGIN    
			   , CUP_FECHAREG    
			   , DDR_RUT    
			   , DDR_NOMBRE    
			   , CUP_FECHAPAGO
			   , CUP_CORREL)     
			SELECT DISTINCT SYSTEM_USER     
				, @cup_id_base		--@FECHA_HOY     
				, COT_RUT
				, SUBSTRING(NOM_DEUDOR, 1, 100) 
				, NULL
				, NULL    
			FROM #DEUDA_CUPONES_DEUFIN_DETALLE

			-- Validar que se hayan insertado filas
			SET @CANT_REG = @@ROWCOUNT;

			IF @CANT_REG = 0
			BEGIN
				--IF @@TRANCOUNT > 0	ROLLBACK TRANSACTION;

				RAISERROR('No se insertó ningún registro en #DEUDA_CUPONES_DEUFIN_AGRUPADA.', 16, 1);
				RETURN;
			END


			SET @OPERACION = 'INSERT #CUP_CORREL'
			INSERT INTO #CUP_CORREL EXEC spu_nuevo_correl 'CUPONPAGO_DEUFIN', 0, @CANT_REG  

			SELECT @cup_correl = folio_ini 
					, @FOLIO_FIN = folio_FIN
			FROM #cup_correl
			
			-- Validar FOLIO_INI y FOLIO_FIN
			IF @cup_correl = 0 OR @FOLIO_FIN = 0 OR @cup_correl IS NULL OR @FOLIO_FIN IS NULL
			BEGIN
				--IF @@TRANCOUNT > 0	ROLLBACK TRANSACTION;

				RAISERROR('Error No se asignaron cup_correl: FOLIO_INI ó FOLIO_FIN.', 16, 1);
				RETURN;
			END


			SET @OPERACION = 'INSERT #TMP_CUPONPAGO_DEUFIN'
			INSERT INTO #TMP_CUPONPAGO_DEUFIN
				( CUP_CORREL
				, USU_LOGIN    
				, CUP_FECHAREG    
				, DDR_RUT    
				, DDR_NOMBRE    
				, CUP_FECHAPAGO
			   )
			SELECT (ROW_NUMBER() over (PARTITION BY '' ORDER BY DDR_NOMBRE) +  @cup_correl - 1)  AS CUP_CORREL
				, USU_LOGIN    
				, CUP_FECHAREG    
				, DDR_RUT    
				, DDR_NOMBRE    
				, CUP_FECHAPAGO
			FROM #DEUDA_CUPONES_DEUFIN_AGRUPADA


			SET @OPERACION = 'UPDATE #DEUDA_CUPONES_DEUFIN_DETALLE'
			UPDATE DC
			SET CUP_CORREL = TMP.CUP_CORREL
			FROM #DEUDA_CUPONES_DEUFIN_DETALLE DC
			JOIN #TMP_CUPONPAGO_DEUFIN TMP
				ON TMP.DDR_RUT = DC.COT_RUT


			SET @OPERACION = 'INSERT CUPONPAGO_DEUFIN'
			INSERT INTO dbo.CUPONPAGO_DEUFIN    
			   (CUP_CORREL    
			   , USU_LOGIN    
			   , CUP_FECHAREG    
			   , DDR_RUT    
			   , DDR_NOMBRE    
			   , CUP_FECHAPAGO
			   )     
			SELECT CUP_CORREL     
				, 'SYSTEM'	--USU_LOGIN     
				, CUP_FECHAREG     
				, DDR_RUT
				, DDR_NOMBRE  
				, CUP_FECHAPAGO    
			FROM #tmp_CUPONPAGO_DEUFIN

			-- Validar que se hayan insertado filas
			IF @@ROWCOUNT = 0
			BEGIN
				--IF @@TRANCOUNT > 0	ROLLBACK TRANSACTION;

				RAISERROR('No se insertó ningún registro en CUPONPAGO_DEUFIN.', 16, 1);
				RETURN;
			END

			SET @OPERACION = 'INSERT CUPONPAGO_DEUFIN_DETALLE '
			INSERT INTO CUPONPAGO_DEUFIN_DETALLE     
			   (    
			   CUP_CORREL    
			   , DEU_CORREL    
			   , CDD_MONTO_REBAJA    
			   , CDD_DESCUENTO      
			   )    
			SELECT 
				CUP_CORREL
				, DEU_CORREL
				, DEU_MONTO
				, DEU_DESCUENTO   
			FROM #DEUDA_CUPONES_DEUFIN_DETALLE

			-- Validar que se hayan insertado filas
			IF @@ROWCOUNT = 0
			BEGIN
				--IF @@TRANCOUNT > 0	ROLLBACK TRANSACTION;

				RAISERROR('No se insertó ningún registro en CUPONPAGO_DEUFIN_DETALLE.', 16, 1);
				RETURN;
			END

			--COMMIT TRAN;

			SELECT 'https://pcotiz.nuevamasvida.cl/?ID=' + CONVERT(VARCHAR(MAX), dbo.f_conex_encrip(CUP_CORREL), 1)   --LINK_CUPON
			, CUP_CORREL
			, COT_RUT 
			FROM #DEUDA_CUPONES_DEUFIN_DETALLE  

	--END TRY      
      
    --Atrapar
	--BEGIN CATCH 
	--		--Si hay transacciones abiertas
	--		IF @@TRANCOUNT > 0 ROLLBACK TRAN;

	--		DECLARE
	--			@ErrorNumber    INT = ERROR_NUMBER(),				-- Captura el código numérico del error (ej: 8134 para división por cero) .
	--			@ErrorSeverity  INT = ERROR_SEVERITY(),				-- Guarda la gravedad del error (10-25, donde 16+ son errores de usuario).
	--			@ErrorState     INT = ERROR_STATE(),				-- Registra el estado interno del error (diferencia variantes del mismo error).
	--			@ErrorProcedure NVARCHAR(128) = ERROR_PROCEDURE(),	-- Nombre del SP, trigger o función donde falló la sentencia.
	--			@ErrorLine      INT = ERROR_LINE(),					-- Número exacto de línea donde ocurrió el error en el código
	--			@ErrorMessage   NVARCHAR(4000) = ERROR_MESSAGE(),	-- Texto completo del mensaje de error con detalles (columnas, valores, etc.)
	--			@MensajeFinal   NVARCHAR(4000)

	--		SET @MensajeFinal = 'Error Proceso: ' + ISNULL(@OPERACION, '') + 
 --                  ' . Nº: ' + CAST(@ErrorNumber AS VARCHAR(10)) + 
 --                  ', Sp_trigger_funcion: ' + ISNULL(@ErrorProcedure, '') + 
 --                  ', Línea: ' + CAST(@ErrorLine AS VARCHAR(10)) +
	--			   ', Línea: ' + ISNULL(@ErrorProcedure, '') +
 --                  ', Detalle error: ' + ISNULL(@ErrorMessage, '');

	--		RAISERROR(@MensajeFinal, 16, 1);
	--		RETURN;

	--END CATCH
    
END     
    
    