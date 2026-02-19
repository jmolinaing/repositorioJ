-- ========================================================================================  
-- TIPO DE OBJETO     : Procedimiento Almacenado  
-- NOMBRE DEL OBJETO  : spu_honorario_cobranza_jud  
-- PARAMETROS         : @deuda_nominal = Deuda total ingresada  
--  
-- CREADO POR         : Alberto Rozas  
-- FECHA CREACIÓN     : 21/03/2022  
-- DESCRIPCIÓN        : Cálculo de honorarios de Cobranzas Judiciales.  
--  
-- MODIFICADO POR     :  
-- FECHA CREACIÓN     :  
-- DESCRIPCIÓN        :  
-- ========================================================================================  
CREATE PROCEDURE [dbo].[spu_honorario_cobranza_jud]  
  @deuda_nominal NUMERIC(10)  
AS  
BEGIN   
 SET NOCOUNT ON;  
  
    DECLARE @porc   NUMERIC(4,2),  
   @hon_cob_jud NUMERIC(10)  
  
 SET @porc = 0.15 -- 15%  
 SET @hon_cob_jud = @deuda_nominal * @porc  
  
 SELECT @hon_cob_jud  
END  