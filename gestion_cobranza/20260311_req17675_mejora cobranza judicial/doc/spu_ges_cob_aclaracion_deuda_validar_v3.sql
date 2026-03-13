/* ========================================================================================  
 TIPO DE OBJETO     : Procedimiento Almacenado  
 NOMBRE DEL OBJETO  : spu_ges_cob_aclaracion_deuda_validar  
 PARAMETROS         : @epa_rut 
                        , @cot_rut
                        , @perdesde
                        , @perhasta
                        , @usu_login
  
 CREADO POR         : Jorge Molina  
 FECHA CREACIÓN     : 12/03/2026  
 DESCRIPCIÓN        : Validar que un cobrador que no sea ESPECIALISTA JUDICIAL 
                        no pueda grabar una solicitud de aclaración para 
                        una deuda que está con Resolución Judicial en estado INGRESADA A TRIBUNALES.  
  
 MODIFICADO POR     : 
 FECHA MODIFICADO   :  
 DESCRIPCIÓN        : 
 ========================================================================================  */

 --GRANT EXECUTE ON OBJECT::[dbo].[spu_ges_cob_aclaracion_deuda_validar] TO [public];


/* EJEMPLOS:
 EXECUTE spu_ges_cob_aclaracion_deuda_validar ' 769633391', ' 154972323' , '20260101', null, 'MASANHUEZ'		-- REJ_FOLIO: 10 NO ESTA INGRESADO EN TRIBUNALES 10%
 EXECUTE spu_ges_cob_aclaracion_deuda_validar 100, 5556   -- REJ_FOLIO: 5556 INGRESADA A TRIBUNALES 15%
*/


CREATE PROCEDURE spu_ges_cob_aclaracion_deuda_validar
    @epa_rut CHAR(10),
    @cot_rut CHAR(10),
    @perdesde DATETIME = NULL,
    @perhasta DATETIME = NULL,
    @usu_login VARCHAR(50)
AS
BEGIN
    DECLARE @error INT = 0;
    DECLARE @texto_error VARCHAR(500) = '';

    -- Primero ver Perfil
    IF NOT EXISTS (
        SELECT 1 FROM perfiles_usuario 
        WHERE usu_login = @usu_login AND per_codigo = 'COBDEUDA_ESPEC_JUDIC'
    )
    BEGIN
        -- EXISTS con filtro dinámico por NULLs
        IF EXISTS (
            SELECT 1 FROM DEUDA_COTIZANTE
            WHERE epa_rut = @epa_rut 
              AND cot_rut = @cot_rut
              AND (@perdesde IS NULL OR dec_periodo >= @perdesde)
              AND (@perhasta IS NULL OR dec_periodo <= @perhasta)
              AND DEC_NRORESOL IS NOT NULL
              AND dbo.f_ges_cob_estado_resoljud(DEC_NRORESOL) = 'INGRESADA A TRIBUNALES'
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

    SELECT @error AS error, @texto_error AS texto_error;
END
GO
