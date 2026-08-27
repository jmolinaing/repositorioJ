/* ========================================================================================  
TIPO DE OBJETO     : Procedimiento
NOMBRE DEL OBJETO  : spu_ges_cob_cju_deshacer_emision
PARAMETROS         : @rej_folio = Correlativo de la resolución judicial a deshacer la emisión.
 
CREADO POR         : Jorge Molina  
FECHA CREACIÓN     : 25/03/2026
DESCRIPCIÓN        : Permita validar si la RJ puede ser dejada nuevamente en estado pendiente.
 
MODIFICADO POR     : 
FECHA MODIFICADO   : 
DESCRIPCIÓN        : 
 ========================================================================================  */


CREATE PROCEDURE [dbo].[spu_ges_cob_cju_deshacer_emision]
    @rej_folio INT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @error_code INT = 0;
    DECLARE @error_msg VARCHAR(500) = '';
    DECLARE @fec_imprime DATETIME;
    DECLARE @fec_anula DATETIME;
    DECLARE @fec_recauda DATETIME;
    DECLARE @estado_resolucion VARCHAR(50)

/* 
 if @ldt_fecrecauda is not null  set @ls_estado='RECAUDADA'  
 if @ldt_fecanula is not null    set @ls_estado='ANULADA'  
 if @ldt_fecingtrib is not null  set @ls_estado='INGRESADA A TRIBUNALES'  ????
 if @ldt_fecimprime is not null  set @ls_estado='EMITIDA'  
 else @ls_estado='PENDIENTE' 
 */

    SET @estado_resolucion = dbo.f_ges_cob_estado_resoljud(@ref_folio);

    -- Una sola consulta para validar
    SELECT 
        @fec_imprime = REJ_FECIMPRIME,
        @fec_anula = REJ_FECANULA,
        @fec_recauda = REJ_FECRECAUDA
    FROM dbo.RESOLUCION_JUDICIAL 
    WHERE REJ_FOLIO = @rej_folio;

    -- Validaciones consolidadas
    IF @fec_imprime IS NULL
    BEGIN
        SET @error_code = -1;
        SET @error_msg = 'Resolución Judicial no existe o no está EMITIDA.';
    END
    ELSE IF @fec_anula IS NOT NULL
    BEGIN
        SET @error_code = -2;
        SET @error_msg = 'No se puede: resolución ANULADA.';
    END
    ELSE IF @fec_recauda IS NOT NULL
    BEGIN
        SET @error_code = -3;
        SET @error_msg = 'No se puede: resolución RECAUDADA.';
    END
    ELSE
    BEGIN
        BEGIN TRANSACTION;
        BEGIN TRY

            --Para deshacer la emisión, se debería dejar en NULL al menos las siguientes columnas:
            --REJ_FECIMPRIME, REJ_USUIMPRIME, REJ_FECINGTRIB, REJ_USUINGTRIB, RJT_CODIGO, REJ_NUMCAUSA, IMG_CORREL

            UPDATE dbo.RESOLUCION_JUDICIAL 
            SET 
                REJ_FECIMPRIME = NULL,
                REJ_USUIMPRIME = NULL,
                REJ_FECINGTRIB = NULL,
                REJ_USUINGTRIB = NULL,
                RJT_CODIGO = NULL,
                REJ_NUMCAUSA = NULL,
                IMG_CORREL = NULL,
            WHERE REJ_FOLIO = @rej_folio;

            IF @@ROWCOUNT = 0
            BEGIN
                --THROW 50001, 'No se actualizó ningún registro.', 1;
                RAISERROR('Error, No se actualizó ningún registro.', 16, 1);  
                RETURN;
            END

            COMMIT TRANSACTION;
            SET @error_msg = 'OK';
        END TRY
        BEGIN CATCH
            ROLLBACK TRANSACTION;
            SET @error_code = ERROR_NUMBER();
            SET @error_msg = ERROR_MESSAGE();
        END CATCH
    END

    SELECT @error_code AS error_code, @error_msg AS error_msg;
END
GO