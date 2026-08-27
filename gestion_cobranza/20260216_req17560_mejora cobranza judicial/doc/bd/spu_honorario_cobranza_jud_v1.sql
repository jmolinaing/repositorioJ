-- ========================================================================================  
-- TIPO DE OBJETO     : Procedimiento Almacenado  
-- NOMBRE DEL OBJETO  : spu_honorario_cobranza_jud  
-- PARAMETROS         : @deuda_nominal = Deuda total ingresada  
--  
-- CREADO POR         : Alberto Rozas  
-- FECHA CREACIÓN     : 21/03/2022  
-- DESCRIPCIÓN        : Cálculo de honorarios de Cobranzas Judiciales.  
--  
-- MODIFICADO POR     : Jorge Molina 
-- FECHA MODIFICADO   : 18/02/2026 
-- DESCRIPCIÓN        : Se agrega parametro de entrada  @ref_folio NUMERIC(15) = NULL
-- ========================================================================================  

/* EJEMPLOS:
 EXECUTE spu_honorario_cobranza_jud 100, 10		-- REJ_FOLIO: 10 NO ESTA INGRESADO EN TRIBUNALES 10%
 EXECUTE spu_honorario_cobranza_jud 100, 5556   -- REJ_FOLIO: 5556 INGRESADA A TRIBUNALES 15%
*/

ALTER PROCEDURE [dbo].[spu_honorario_cobranza_jud]  
  @deuda_nominal NUMERIC(10)  
  , @ref_folio NUMERIC(15) = NULL  -- Nuevo parámetro opcional
AS  
BEGIN   
 SET NOCOUNT ON;  
  
    DECLARE @porc   NUMERIC(4,2)  
   , @hon_cob_jud NUMERIC(10)  
   , @estado_resolucion VARCHAR(50)		--nueva variable
  
	--verion original
	/*
	SET @porc = 0.15 -- 15%  
	SET @hon_cob_jud = @deuda_nominal * @porc  
  
	SELECT @hon_cob_jud 
	*/


	-- Lógica según videos 2.mp4, 3.mp4, 4.mp4:
	IF @ref_folio IS NULL
	BEGIN
		SET @porc = 0.15  -- 15%
	END
	ELSE
	BEGIN
		-- Verificar estado de la resolución usando función
		SET @estado_resolucion = dbo.f_ges_cob_estado_resoljud(@ref_folio)

		PRINT @estado_resolucion

		IF @estado_resolucion = 'INGRESADA A TRIBUNALES'
		BEGIN
				SET @porc = 0.15  -- 15%
		END
		ELSE
		BEGIN
				SET @porc = 0.10  -- 10%
		END

	END
  
	SET @hon_cob_jud = @deuda_nominal * @porc  
  
	SELECT @hon_cob_jud		--honorario_cobranza


END  