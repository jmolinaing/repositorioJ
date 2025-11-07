

--GENERAR CUPONES
IF @generar_cupones = 'S'
BEGIN
    DECLARE @rut_deudor CHAR(10), @tipo_empresa VARCHAR(30), @trama VARCHAR(MAX);
    DECLARE @link NVARCHAR(100), @correl_gescob numeric(15);
    DECLARE @desc_deudanom NUMERIC(10), @desc_reajuste NUMERIC(10), @desc_interes NUMERIC(10), @desc_recargo NUMERIC(10);

    DECLARE cursor_deudores CURSOR FOR
        SELECT rut_deudor, tipo_empresa FROM #tabla_final;

    OPEN cursor_deudores;
    FETCH NEXT FROM cursor_deudores INTO @rut_deudor, @tipo_empresa;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        IF @tipo_empresa = 'EMPRESA'
        BEGIN
            DECLARE @tmp_correlativo TABLE (correl_gescob numeric(15));

            INSERT INTO @tmp_correlativo
            EXECUTE [MIRROR_NT].[AGENCIAS].[DBO].spu_nuevo_correlativo 'CUPONPAGO_COTIZ_DEUDA';

            SELECT TOP 1 @correl_gescob = correl_gescob FROM @tmp_correlativo;

            IF @correl_gescob <= 0 or @correl_gescob is null
            BEGIN
                RAISERROR('Error en la obtención del correlativo', 16, 1);
                RETURN;
            END

            INSERT INTO [MIRROR_NT].[AGENCIAS].[DBO].CUPONPAGO_COTIZ_DEUDA
            (
                CORREL, COT_RUT, NOM_COTIZANTE, EPA_RUT, EPA_RAZON,
                DEC_PERIODO, DEC_TIPO_DEUDA, DEC_NRORESOL, PACTADO, PAGADO,
                DEUDANOMINAL, REAJUSTE, INTERES, RECARGO, TOTAL_APAGAR
            )
            SELECT
                @correl_gescob,
                tdc.DEC_RUT,
                tf.nombre_deudor,
                tdc.EPA_RUT,
                NULL,
                tdc.DEC_PERIODO,
                tdc.DEC_TIPO_DEUDA,
                NULL,
                NULL,
                NULL,
                tdc.DEUDA_REAJUSTADA,
                NULL,
                NULL,
                NULL,
                tdc.DEUDA_REAJUSTADA
            FROM #TMP_DEUDA_COTIZANTE tdc
            INNER JOIN #tabla_final tf ON tdc.DEC_RUT = tf.rut_deudor
            WHERE tf.rut_deudor = @rut_deudor;

            EXEC MIRROR_NT.AGENCIAS.dbo.spu_cuponpago_genera_con_descto_empleador
                @epa_rut = @rut_deudor,
                @correl_gescob =  @correl_gescob,
                @desc_deudanom = 0,
                @desc_reajuste = 0,
                @desc_interes = 0,
                @desc_recargo = 0,
                @usuario = NULL,
                @hon_cob = NULL,
                @valida_lagunas = 'S';

            --UPDATE #tabla_final
            --SET monto_cupon = @cup_correl,
            --    url_link = 'https://pcotiz.nuevamasvida.cl/?ID=' + CONVERT(VARCHAR, dbo.f_conex_encrip(@cup_correl), 1)
            --WHERE rut_deudor = @rut_deudor;
        END
        ELSE
        BEGIN
		print 'hola'
  /*
	-- manejo para otros tipos de deudores
            SET @trama = '';
            SELECT @trama = STRING_AGG(
                CAST(DEC_RUT AS VARCHAR) + '|' +
                CONVERT(VARCHAR, DEC_PERIODO, 112) + '|' +
                '2|' +
                CAST(DEC_DEUDA AS VARCHAR) + '|0|0|0|0|0|0|0',
                '|')
            FROM #TMP_DEUDA_COTIZANTE
            WHERE DEC_RUT = @rut_deudor AND DEC_DEUDA > 0
            ORDER BY DEC_PERIODO;

            EXEC dbo.spu_cuponpago_genera_con_descto
                @trama = @trama,
                @usuario = NULL,
                @hon_cob = NULL,
                @valida_lagunas = 'S';

            SELECT TOP 1 @cup_correl = cup_correl FROM CUPONPAGO_COTIZ WHERE ddr_rut = @rut_deudor ORDER BY cup_fechareg DESC;

            SET @link = 'https://pcotiz.nuevamasvida.cl/?ID=' + CONVERT(VARCHAR, dbo.f_conex_encrip(@cup_correl), 1);

            UPDATE #tabla_final
            SET url_link = @link,
                monto_cupon = @cup_correl
            WHERE rut_deudor = @rut_deudor;
		*/
        END


        FETCH NEXT FROM cursor_deudores INTO @rut_deudor, @tipo_empresa;
    END;

    CLOSE cursor_deudores;
    DEALLOCATE cursor_deudores;
END


--GENERAR CUPONES: FIN