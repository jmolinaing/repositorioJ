
/* ========================================================================================  
TIPO DE OBJETO     : Función (Tabla-Escalar)
NOMBRE DEL OBJETO  : f_ges_cob_rj_costas_estadio
PARAMETROS         : @rco_correl = Correlativo de la costa judicial (RCO_CORREL)
 
CREADO POR         : Jorge Molina  
FECHA CREACIÓN     : 25/03/2026
DESCRIPCIÓN        : Tareas #17675: Obtiene el estado de pago de una costa judicial (PENDIENTE o LIQUIDADA).
 
MODIFICADO POR     : 
FECHA MODIFICADO   : 
DESCRIPCIÓN        : 
 ========================================================================================  */

create FUNCTION [dbo].[f_ges_cob_rj_costas_estado](@rco_correl numeric(10))
RETURNS VARCHAR(20)
AS
BEGIN
    DECLARE @estado VARCHAR(20) = 'PENDIENTE';
    
    IF EXISTS (SELECT 1 FROM dbo.RJUD_COSTAS WHERE RCO_CORREL = @rco_correl AND RLC_CORREL IS NOT NULL)
        SET @estado = 'LIQUIDADA';
    
    RETURN @estado;
END
GO