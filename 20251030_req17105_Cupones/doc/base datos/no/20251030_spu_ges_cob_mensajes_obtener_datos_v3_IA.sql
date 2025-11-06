ALTER PROCEDURE [dbo].[spu_ges_cob_mensajes_obtener_datos]   
    @epl_codigo varchar(50) = null  
  , @enviar char(1) = 'N'  
  , @epr_codigo numeric(10) = null  
  , @epl_fechora datetime = null  
AS  
BEGIN   
    SET NOCOUNT ON; 
    
    -- Declaraciones, limpieza y obtención de datos original aquí...

    -- Después de generar y llenar #tabla_final con los datos de deudores
    
    DECLARE @rut_deudor CHAR(10), @tipo_empresa VARCHAR(30), @trama VARCHAR(MAX)
    DECLARE @link NVARCHAR(500), @cup_correl NUMERIC(15)
    DECLARE @desc_deudanom NUMERIC(10), @desc_reajuste NUMERIC(10), @desc_interes NUMERIC(10), @desc_recargo NUMERIC(10)
    
    DECLARE cursor_deudores CURSOR FOR
    SELECT rut_deudor, tipo_empresa FROM #tabla_final
    
    OPEN cursor_deudores
    FETCH NEXT FROM cursor_deudores INTO @rut_deudor, @tipo_empresa
    
    WHILE @@FETCH_STATUS = 0
    BEGIN
        IF @tipo_empresa = 'EMPRESA'
        BEGIN
            -- Aquí deberías asignar los valores de descuentos de acuerdo a tu base o lógica
            SET @desc_deudanom = 0
            SET @desc_reajuste = 0
            SET @desc_interes = 0
            SET @desc_recargo = 0
    
            EXEC dbo.spu_cuponpago_genera_con_descto_empleador
                @epa_rut = @rut_deudor,
                @desc_deudanom = @desc_deudanom,
                @desc_reajuste = @desc_reajuste,
                @desc_interes = @desc_interes,
                @desc_recargo = @desc_recargo,
                @usuario = NULL,
                @hon_cob = NULL,
                @correl_gescob = NULL,
                @valida_lagunas = 'S'
            -- Se asume que spu_cuponpago_genera_con_descto_empleador deja el correlativo guardado o devuelto (se puede ajustar para OUTPUT)
            
            SET @link = 'https://pcotiz.nuevamasvida.cl/?ID=' + CONVERT(VARCHAR, dbo.f_conex_encrip(@cup_correl), 1)
        END
        ELSE
        BEGIN
            -- Construir la trama @trama concatenando datos de #detalle_cuotas para @rut_deudor
            SET @trama = ''
            SELECT @trama = STRING_AGG(
                CAST(RUT AS VARCHAR) + '|' +
                CAST(Periodo AS VARCHAR) + '|' +
                CAST(OportunidadPago AS VARCHAR) + '|' +
                CAST(MontoCotizacion AS VARCHAR) + '|' +
                CAST(Dscto_MontoCot AS VARCHAR) + '|' +
                CAST(Reajuste AS VARCHAR) + '|' +
                CAST(DsctoReajuste AS VARCHAR) + '|' +
                CAST(Interes AS VARCHAR) + '|' +
                CAST(DsctoInteres AS VARCHAR) + '|' +
                CAST(Recargo AS VARCHAR) + '|' +
                CAST(DsctoRecargo AS VARCHAR),
            '|')
            FROM #detalle_cuotas
            WHERE RUT = @rut_deudor
            ORDER BY Periodo
    
            EXEC dbo.spu_cuponpago_genera_con_descto
                @trama = @trama,
                @usuario = NULL,
                @hon_cob = NULL,
                @valida_lagunas = 'S'
            -- Se asume que spu_cuponpago_genera_con_descto devuelve cup_correl
    
            SET @link = 'https://pcotiz.nuevamasvida.cl/?ID=' + CONVERT(VARCHAR, dbo.f_conex_encrip(@cup_correl), 1)
        END
    
        -- Actualizar tabla con el link y correlativo generados
        UPDATE #tabla_final
        SET url_link = @link,
            monto_cupon = @cup_correl
        WHERE rut_deudor = @rut_deudor
    
        FETCH NEXT FROM cursor_deudores INTO @rut_deudor, @tipo_empresa
    END
    
    CLOSE cursor_deudores
    DEALLOCATE cursor_deudores
    
    -- Continuar lógica original de envío o retorno de datos
    
END
