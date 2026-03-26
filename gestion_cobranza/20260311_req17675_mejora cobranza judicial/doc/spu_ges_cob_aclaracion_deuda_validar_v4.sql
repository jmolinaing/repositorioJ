/* ========================================================================================  
 TIPO DE OBJETO     : Procedimiento Almacenado  
 NOMBRE DEL OBJETO  : spu_ges_cob_aclaracion_deuda_validar  
 PARAMETROS         : @epa_rut 
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
 EXECUTE spu_ges_cob_aclaracion_deuda_validar ' 769633391',  'MSANHUEZ'		
 EXECUTE spu_ges_cob_aclaracion_deuda_validar ' 768410801',  'MSANHUEZ'  
 */


alter PROCEDURE spu_ges_cob_aclaracion_deuda_validar
    @epa_rut CHAR(10),
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
              AND DEC_NRORESOL IS NOT NULL
              AND dbo.f_ges_cob_estado_resoljud(DEC_NRORESOL) = 'INGRESADA A TRIBUNALES'
        )
        BEGIN
            DECLARE @nombre_cobrador VARCHAR(100) = ISNULL((
                SELECT TOP 1 cob_nombre FROM cobrador c with (nolock) 
                WHERE cob_codigo IN (select cob_codigo 
                                    from deudor_asignado_superv_cjud a with (nolock)
                                    where daj_asig_desde <= getdate()
                                    and ( daj_asig_hasta >= getdate() or daj_asig_hasta is null)
                                    and ddr_rut = @epa_rut)
            ), ' ');

            SET @error = -1;
            SET @texto_error = 'No es posible registrar la solicitud ya que la empresa se encuentra en cobranza judicial, ' +
                               'por lo que debe comunicarse con la ejecutiva(o) a cargo: [' + @nombre_cobrador + '].';
        END
    END

    SELECT @error AS error, @texto_error AS texto_error;
END
GO
