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
    @epa_rut VARCHAR(20),
    @cot_rut VARCHAR(20),
    @perdesde VARCHAR(6),  -- YYYYMM
    @perhasta VARCHAR(6),
    @usu_login VARCHAR(50),
    @error INT OUTPUT,
    @texto_error VARCHAR(500) OUTPUT
AS
BEGIN
    SET @error = 0;
    SET @texto_error = '';

    -- 1. Verificar perfil ESPECIALISTA JUDICIAL
    IF NOT EXISTS (
        SELECT 1 FROM perfiles_usuario  -- Asumir tabla; ajustar si difiere
        WHERE usu_login = @usu_login AND codigo = 'COBDEUDA_ESPEC_JUDIC'
    )
    BEGIN
        -- 2. Verificar deuda con resolución judicial en período
        IF EXISTS (
            SELECT 1 FROM DEUDA_COTIZANTE
            WHERE epa_rut = @epa_rut 
              AND cot_rut = @cot_rut
              AND periodo BETWEEN @perdesde AND @perhasta
              AND DEC_NRORESOL IS NOT NULL
              AND dbo.F_estado_resol(DEC_NRORESOL) = 'INGRESADA A TRIBUNALES'  -- Función de videos
        )
        BEGIN
            -- Obtener nombre cobrador/supervisor (TOP 1 por epa_rut)
            DECLARE @nombre_cobrador VARCHAR(100) = ISNULL((
                SELECT TOP 1 usu_nombre 
                FROM usuarios u  -- Ajustar tabla de asignaciones
                WHERE u.root = (SELECT root_supervisor FROM asignaciones_judicial WHERE epa_rut = @epa_rut)
            ), '');

            SET @error = -1;
            SET @texto_error = 'No es posible registrar la solicitud ya que la empresa se encuentra en cobranza judicial, ' +
                               'por lo que debe comunicarse con la ejecutiva(o) a cargo ' + @nombre_cobrador + '.';
            RETURN;
        END
    END
END
GO
