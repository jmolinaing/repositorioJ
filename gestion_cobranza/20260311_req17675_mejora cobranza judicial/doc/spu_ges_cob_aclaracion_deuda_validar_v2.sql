/* ========================================================================================  
 TIPO DE OBJETO     : Procedimiento Almacenado  
 NOMBRE DEL OBJETO  : spu_ges_cob_aclaracion_deuda_validar  
 PARAMETROS         : @deuda_nominal = Deuda total ingresada  
  
 CREADO POR         : Jorge Molina  
 FECHA CREACIÓN     : 11/03/2026  
 DESCRIPCIÓN        : Cálculo de honorarios de Cobranzas Judiciales.  
  
 MODIFICADO POR     : 
 FECHA MODIFICADO   :  
 DESCRIPCIÓN        : 
 ========================================================================================  */

/* EJEMPLOS:
 EXECUTE spu_ges_cob_aclaracion_deuda_validar 100, 10		-- REJ_FOLIO: 10 NO ESTA INGRESADO EN TRIBUNALES 10%
 EXECUTE spu_ges_cob_aclaracion_deuda_validar 100, 5556   -- REJ_FOLIO: 5556 INGRESADA A TRIBUNALES 15%
*/


CREATE PROCEDURE spu_ges_cob_aclaracion_deuda_validar
    @epa_rut CHAR(10),
    @cot_rut CHAR(10),
    @perdesde DATETIME,
    @perhasta DATETIME,
    @usu_login VARCHAR(50)
AS
BEGIN
    DECLARE @error INT = 0;
    DECLARE @texto_error VARCHAR(500) = '';

    -- Verificar perfil 'COBDEUDA_ESPEC_JUDIC'
    IF NOT EXISTS (
        SELECT 1 FROM perfiles_usuario 
        WHERE usu_login = @usu_login AND codigo = 'COBDEUDA_ESPEC_JUDIC'
    )
    BEGIN
        IF EXISTS (
            SELECT 1 FROM DEUDA_COTIZANTE
            WHERE epa_rut = @epa_rut AND cot_rut = @cot_rut
              AND periodo BETWEEN @perdesde AND @perhasta
              AND DEC_NRORESOL IS NOT NULL
              AND dbo.F_estado_resol(DEC_NRORESOL) = 'INGRESADA A TRIBUNALES'
        )
        BEGIN
            DECLARE @nombre_cobrador VARCHAR(100) = ISNULL((
                SELECT TOP 1 usu_nombre FROM usuarios 
                WHERE root IN (SELECT root_supervisor FROM asignaciones_judicial WHERE epa_rut = @epa_rut)
            ), 'a cargo');

            SET @error = -1;
            SET @texto_error = 'No es posible registrar la solicitud ya que la empresa se encuentra en cobranza judicial, ' +
                               'por lo que debe comunicarse con la ejecutiva(o) a cargo [' + @nombre_cobrador + '].';
        END
    END

    -- Retornar vía SELECT (fácil FETCH en PB)
    SELECT @error AS error, @texto_error AS texto_error;
END
GO
