

--GENERAR CUPONES
IF @generar_cupones = 'S'
BEGIN
    DECLARE @rut_deudor CHAR(10), @tipo_empresa VARCHAR(30), @trama VARCHAR(MAX);
    DECLARE @link NVARCHAR(100), @correl_gescob numeric(15);
    DECLARE @desc_deudanom NUMERIC(10), @desc_reajuste NUMERIC(10), @desc_interes NUMERIC(10), @desc_recargo NUMERIC(10);

	--primero saco el correlativo comun para los de tipo empresa que se insertaran en [MIRROR_NT].[AGENCIAS].[DBO].CUPONPAGO_COTIZ_DEUDA
    DECLARE @tmp_correlativo TABLE (correl_gescob numeric(15));

    INSERT INTO @tmp_correlativo
    EXECUTE [MIRROR_NT].[AGENCIAS].[DBO].spu_nuevo_correlativo 'CUPONPAGO_COTIZ_DEUDA';

    SELECT TOP 1 @correl_gescob = correl_gescob FROM @tmp_correlativo;

    IF @correl_gescob <= 0 or @correl_gescob is null
    BEGIN
        RAISERROR('Error en la obtención del correlativo para CUPONPAGO_COTIZ_DEUDA', 16, 1);
        RETURN;
    END

    DECLARE cursor_deudores CURSOR FOR

		--tipo_deudor varchar(30) null		--Valores: VIGENTE, NO VIGENTE, EMPRESA
		--tipo_empresa varchar(30) null		--Valores: COTIZANTE, EMPRESA

	SELECT rut_deudor, tipo_empresa FROM #tabla_final_filtrada;

    OPEN cursor_deudores;
    FETCH NEXT FROM cursor_deudores INTO @rut_deudor, @tipo_empresa;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        IF @tipo_empresa = 'EMPRESA'
        BEGIN

			--SELECT * FROM [MIRROR_NT].[AGENCIAS].[DBO].CUPONPAGO_COTIZ_DEUDA
			INSERT INTO [MIRROR_NT].[AGENCIAS].[DBO].CUPONPAGO_COTIZ_DEUDA
					   (CORREL
					   ,COT_RUT
					   ,NOM_COTIZANTE
					   ,EPA_RUT
					   ,EPA_RAZON
					   ,DEC_PERIODO
					   ,DEC_TIPO_DEUDA
					   ,DEC_NRORESOL
					   ,PACTADO
					   ,PAGADO
					   ,DEUDANOMINAL
					   ,REAJUSTE
					   ,INTERES
					   ,RECARGO
					   ,TOTAL_APAGAR
					   ,COBRADOR
					   ,FECHA
					   ,ANO
					   ,MES
					   ,DEUDA_HC
					   ,DESCTO_DEUDANOMINAL
					   ,DESCTO_REAJUSTE
					   ,DESCTO_INTERES
					   ,DESCTO_RECARGO
					   ,FOLIO_FUN_HAB
					   ,FECHA_FUN_HAB
					   ,REJ_FOLIO)
				 --VALUES   (
				 SELECT
					   @correl_gescob	--<CORREL, numeric(16,0),>
					   , tf.rut_deudor	--<COT_RUT, char(10),>
					   , tf.nombre_deudor	--<NOM_COTIZANTE, varchar(25),>
					   , tf.rut_deudor	-- DUDA: IGUAL QUE EL COT_RUT??	--<EPA_RUT, char(10),>
					   , tf.nombre_deudor	-- DUDA: IGUAL QUE EL nombre_deudor??	--<EPA_RAZON, varchar(200),>
					   , tdc.DEC_PERIODO	--<DEC_PERIODO, datetime,>
					   , tdc.DEC_TIPO_DEUDA	--<DEC_TIPO_DEUDA, varchar(20),>
					   , NULL				--<DEC_NRORESOL, numeric(10,0),>
					   , NULL				--<PACTADO, numeric(10,0),>
					   , NULL				--<PAGADO, numeric(10,0),>
					   , NULL				--<DEUDANOMINAL, numeric(10,0),>
					   , NULL				--<REAJUSTE, numeric(10,0),>
					   , NULL				--<INTERES, numeric(10,0),>
					   , NULL				--<RECARGO, numeric(10,0),>
					   , NULL				--<TOTAL_APAGAR, numeric(10,0),>
					   , COALESCE(tf.nombre_ejecutivo, nom_cob_lurchq)	--DUDA				--<COBRADOR, varchar(65),>
					   , NULL				--<FECHA, datetime,>
					   , NULL				--<ANO, int,>
					   , NULL				--<MES, int,>
					   , NULL				--<DEUDA_HC, numeric(10,0),>
					   , NULL				--<DESCTO_DEUDANOMINAL, numeric(10,0),>
					   , NULL				--<DESCTO_REAJUSTE, numeric(16,9),>
					   , NULL				--<DESCTO_INTERES, numeric(16,8),>
					   , NULL				--<DESCTO_RECARGO, numeric(16,8),>
					   , NULL				--<FOLIO_FUN_HAB, numeric(10,0),>
					   , NULL				--<FECHA_FUN_HAB, datetime,>
					   , NULL				--<REJ_FOLIO, numeric(10,0),>
					   --)
				FROM #TMP_DEUDA_COTIZANTE tdc
				JOIN #tabla_final_filtrada tf ON tdc.DEC_RUT = tf.rut_deudor
				WHERE tf.rut_deudor = @rut_deudor;

			-- Declara variables para almacenar los resultados
			DECLARE @link VARCHAR(100);  -- ajuste tipo y tamaño según tu necesidad
			DECLARE @cup_correl INT;

			-- Crea tabla temporal para capturar salida del SP
			CREATE TABLE #ResultadosTemp (link VARCHAR(MAX), cup_correl numeric(15));

			-- Inserta en la tabla temporal la salida del procedimiento almacenado
			INSERT INTO #ResultadosTemp
            EXEC MIRROR_NT.AGENCIAS.dbo.spu_cuponpago_genera_con_descto_empleador
                @epa_rut = @rut_deudor,
                @correl_gescob =  @correl_gescob,
                @desc_deudanom = 0,
                @desc_reajuste = 0,
                @desc_interes = 0,
                @desc_recargo = 0,
                @usuario = SYSTEM_USER,		--el usuario no debe ser null para que pase el cup_correl
                @hon_cob = NULL,
                @valida_lagunas = 'S';

			-- Asigna los valores de la tabla temporal a variables (por ejemplo, primer registro)
			SELECT TOP 1
				@link = link,
				@cup_correl = cup_correl
			FROM #ResultadosTemp;

            UPDATE #tabla_final_filtrada
            SET monto_cupon = @cup_correl,
                url_link = @link
            WHERE rut_deudor = @rut_deudor;

        END
        ELSE		--COTIZANTE
        BEGIN
			--print 'hola'
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
                @usuario = SYSTEM_USER,		--el usuario no debe ser null para que pase el cup_correl
                @hon_cob = NULL,
                @valida_lagunas = 'S';

            SELECT TOP 1 @cup_correl = cup_correl FROM CUPONPAGO_COTIZ WHERE ddr_rut = @rut_deudor ORDER BY cup_fechareg DESC;

            SET @link = 'https://pcotiz.nuevamasvida.cl/?ID=' + CONVERT(VARCHAR, dbo.f_conex_encrip(@cup_correl), 1);

            UPDATE #tabla_final_filtrada
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