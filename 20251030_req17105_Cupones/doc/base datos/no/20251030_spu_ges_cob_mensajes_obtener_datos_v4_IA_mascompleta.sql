ALTER PROCEDURE [dbo].[spu_ges_cob_mensajes_obtener_datos]   
@epl_codigo varchar(50) = null  
, @enviar char(1) = 'N'  
, @epr_codigo numeric(10) = null  
, @epl_fechora datetime = null  
AS  
BEGIN   
  SET NOCOUNT ON;
  
  DECLARE @sqlwhere nvarchar(4000);
  DECLARE @sqlfiltro nvarchar(1000);
  DECLARE @codigo_concepto numeric(5, 0);
  DECLARE @nombre_valor nvarchar(4000);
  DECLARE @uf_valor numeric(8, 2);
  DECLARE @fecha_hoy datetime;
  DECLARE @PrimerDiaDelMes datetime;
  DECLARE @PrimerDiaDelMesSgte datetime;
  DECLARE @UltDiaMesAnterior datetime;
  DECLARE @TipoDeudaCOTIZ varchar(2);
  DECLARE @TipoDeudaLUR varchar(2);
  DECLARE @TipoDeudaCHQ varchar(2);
  DECLARE @ate_codigo numeric(5);

  DECLARE @ErrorMessage NVARCHAR(4000), @ErrorSeverity INT, @ErrorState INT; -- para auditoría y debugging
  
  SET @fecha_hoy = CAST(CAST(GETDATE() AS date) AS datetime);
  SELECT 
    @PrimerDiaDelMes = CAST(DATEADD(month, DATEDIFF(month, 0, GETDATE()), 0) AS date),
    @PrimerDiaDelMesSgte = CAST(DATEADD(month, DATEDIFF(month, 0, GETDATE()) + 1, 0) AS date);
    
  SET @UltDiaMesAnterior = DATEADD(day, -1, @PrimerDiaDelMes);

  IF NOT EXISTS (SELECT 1 FROM gco_envmsg_plantilla WITH (NOLOCK) WHERE epl_codigo = @epl_codigo)
  BEGIN
    RAISERROR('No existe plantilla: %s', 16, 1, @epl_codigo);
    RETURN;
  END

  IF NOT EXISTS (SELECT 1 FROM gco_envmsg_filtro WITH (NOLOCK) WHERE epl_codigo = @epl_codigo)
  BEGIN
    RAISERROR('No existe filtros en la plantilla: %s', 16, 1, @epl_codigo);
    RETURN;
  END

  SELECT @uf_valor = uf_valor FROM uf WITH (NOLOCK) WHERE uf_fecha = @UltDiaMesAnterior;
  
  IF @uf_valor IS NULL  
  BEGIN  
    DECLARE @fecha_str VARCHAR(10);  
    SET @fecha_str = CONVERT(VARCHAR(10), @UltDiaMesAnterior, 120);  
    RAISERROR('No existe valor UF para la fecha: %s', 16, 1, @fecha_str);  
    RETURN;  
  END  

  IF @enviar = 'S'  
  BEGIN  
    SELECT @ate_codigo =  ate_codigo FROM gco_envmsg_programa WITH (NOLOCK) WHERE epr_codigo = @epr_codigo;

    IF @ate_codigo IS NULL
    BEGIN
      RAISERROR('No existe programa con api template con el código de programa(@epr_codigo): %s', 16, 1, @epr_codigo);
      RETURN;
    END

    IF @epl_fechora IS NULL
    BEGIN
      RAISERROR('Falta parámetro de entrada @epl_fechora, para el código de programa(@epr_codigo): %s', 16, 1, @epr_codigo);
      RETURN;
    END  
  END
  
  SET @sqlwhere = '';  
  SET @sqlfiltro = '';  
  SET @TipoDeudaCOTIZ = '';  
  SET @TipoDeudaLUR = '';  
  SET @TipoDeudaCHQ = '';  

  IF @sqlwhere IS NULL OR @sqlwhere = ''
  BEGIN
    RAISERROR('No existe filtros @sqlwhere en la plantilla: %s', 16, 1, @epl_codigo);
    RETURN;
  END

  -- limpieza de tablas temporales si existen
  IF OBJECT_ID('tempdb..#DEUDA_COTIZ_EMPL', 'u') IS NOT NULL DROP TABLE #DEUDA_COTIZ_EMPL;
  IF OBJECT_ID('tempdb..#TMP_DEUDA_COTIZANTE', 'u') IS NOT NULL DROP TABLE #TMP_DEUDA_COTIZANTE;
  IF OBJECT_ID('tempdb..#origen_cotiz_empl', 'u') IS NOT NULL DROP TABLE #origen_cotiz_empl;
  IF OBJECT_ID('tempdb..#origen_lur_chq', 'u') IS NOT NULL DROP TABLE #origen_lur_chq;
  IF OBJECT_ID('tempdb..#tabla_final', 'u') IS NOT NULL DROP TABLE #tabla_final;
  IF OBJECT_ID('tempdb..#tfu', 'u') IS NOT NULL DROP TABLE #tfu;
  IF OBJECT_ID('tempdb..#compromiso', 'u') IS NOT NULL DROP TABLE #compromiso;
  IF OBJECT_ID('tempdb..#cobrador_asig_lurchq', 'u') IS NOT NULL DROP TABLE #cobrador_asig_lurchq;
  IF OBJECT_ID('tempdb..#cobrador_asig_cotiz', 'u') IS NOT NULL DROP TABLE #cobrador_asig_cotiz;
  IF OBJECT_ID('tempdb..#f_supervisor_asig', 'u') IS NOT NULL DROP TABLE #f_supervisor_asig;
  IF OBJECT_ID('tempdb..#f_vigencia_personas', 'u') IS NOT NULL DROP TABLE #f_vigencia_personas;
  IF OBJECT_ID('tempdb..#f_gestion29', 'u') IS NOT NULL DROP TABLE #f_gestion29;
  IF OBJECT_ID('tempdb..#f_compromiso_vencido', 'u') IS NOT NULL DROP TABLE #f_compromiso_vencido;
  IF OBJECT_ID('tempdb..#f_deuda_lur_con_credito', 'u') IS NOT NULL DROP TABLE #f_deuda_lur_con_credito;
  IF OBJECT_ID('tempdb..#equipo_cobrador', 'u') IS NOT NULL DROP TABLE #equipo_cobrador;

  CREATE TABLE #tabla_final  
 ( rut_deudor char(10) NOT NULL  
  , nombre_deudor varchar(100) NULL  
  , email_destinatario varchar(100) NULL  
  , deuda_cotizaciones numeric(15) NULL  
  , monto_cupon numeric(15) NULL 
  , monto_posible_compensar numeric(15) NULL  
  , cob_codigo numeric(5) NULL  
  , nombre_ejecutivo varchar(100) NULL  
  , email_ejecutivo varchar(100) NULL  
  , fono_ejecutivo varchar(30) NULL  
  , url_link varchar(100) NULL  
  , url_link1 varchar(100) NULL  
  , url_link2 varchar(100) NULL  
  , fecha_compromiso datetime NULL  
  , monto_compromiso numeric(15) NULL  
  , deuda_lur numeric(15) NULL  
  , deuda_chq numeric(15) NULL  
  , cobrador_asignado_lur_chq numeric(10) NULL  
  , nom_cob_lurchq varchar(100) NULL  
  , email_cob_lurchq varchar(100) NULL  
  , fono_cob_lurchq varchar(30) NULL  
  , fono_contacto varchar(50) NULL  
  , supervisor_asig numeric(4) NULL  
  , gestion29 varchar(2) NULL  
  , ciu_codigo_reside numeric(4) NULL   
  , deuda_lur_con_credito varchar(2) NULL  
  , edad_deudor numeric(4) NULL  
  , compromiso_vencido datetime NULL  
  , dnp numeric(4) NULL  
  , dpp numeric(4) NULL  
  , ip numeric(4) NULL  
  , menor_per_deuda datetime NULL  
  , mayor_per_deuda datetime NULL  
  , tipo_deudor varchar(30) NULL  
  , tipo_empresa varchar(30) NULL   
  , equipo_cobrador varchar(20) NULL  
 );





-- Segunda parte del procedimiento spu_ges_cob_mensajes_obtener_datos

BEGIN TRY
    BEGIN TRANSACTION;

    -- Declaración variables para cupones
    DECLARE @rut_deudor CHAR(10), @tipo_empresa VARCHAR(30), @trama VARCHAR(MAX);
    DECLARE @link NVARCHAR(100), @cup_correl NUMERIC(15);
    DECLARE @desc_deudanom NUMERIC(10), @desc_reajuste NUMERIC(10), @desc_interes NUMERIC(10), @desc_recargo NUMERIC(10);

    DECLARE cursor_deudores CURSOR FOR
        SELECT rut_deudor, tipo_empresa FROM #tabla_final;

    OPEN cursor_deudores;
    FETCH NEXT FROM cursor_deudores INTO @rut_deudor, @tipo_empresa;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        IF @tipo_empresa = 'EMPRESA'
        BEGIN
            SET @desc_deudanom = 0;
            SET @desc_reajuste = 0;
            SET @desc_interes = 0;
            SET @desc_recargo = 0;

            EXEC dbo.spu_cuponpago_genera_con_descto_empleador
                @epa_rut=@rut_deudor,
                @desc_deudanom=@desc_deudanom,
                @desc_reajuste=@desc_reajuste,
                @desc_interes=@desc_interes,
                @desc_recargo=@desc_recargo,
                @usuario=NULL,
                @hon_cob=NULL,
                @correl_gescob=NULL,
                @valida_lagunas='S';

            SELECT TOP 1 @cup_correl = cup_correl FROM CUPONPAGO_COTIZ WHERE ddr_rut = @rut_deudor ORDER BY cup_fechareg DESC;
            SET @link = 'https://pcotiz.nuevamasvida.cl/?ID=' + CONVERT(VARCHAR, dbo.f_conex_encrip(@cup_correl), 1);
        END
        ELSE
        BEGIN
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
                @trama=@trama,
                @usuario=NULL,
                @hon_cob=NULL,
                @valida_lagunas='S';

            SELECT TOP 1 @cup_correl = cup_correl FROM CUPONPAGO_COTIZ WHERE ddr_rut = @rut_deudor ORDER BY cup_fechareg DESC;
            SET @link = 'https://pcotiz.nuevamasvida.cl/?ID=' + CONVERT(VARCHAR, dbo.f_conex_encrip(@cup_correl), 1);
        END

        UPDATE #tabla_final
        SET url_link = @link,
            monto_cupon = @cup_correl
        WHERE rut_deudor = @rut_deudor;

        FETCH NEXT FROM cursor_deudores INTO @rut_deudor, @tipo_empresa;
    END;

    CLOSE cursor_deudores;
    DEALLOCATE cursor_deudores;

    IF @enviar = 'N'
    BEGIN
        DECLARE @sql1 NVARCHAR(MAX) = N'
            SELECT rut_deudor,
                   nombre_deudor,
                   email_destinatario,
                   deuda_cotizaciones,
                   monto_cupon,
                   monto_posible_compensar,
                   cob_codigo,
                   nombre_ejecutivo,
                   email_ejecutivo,
                   fono_ejecutivo,
                   url_link,
                   url_link1,
                   url_link2,
                   fecha_compromiso,
                   monto_compromiso,
                   deuda_lur,
                   deuda_chq,
                   cobrador_asignado_lur_chq,
                   nom_cob_lurchq,
                   email_cob_lurchq,
                   fono_cob_lurchq,
                   fono_contacto,
                   supervisor_asig,
                   gestion29,
                   ciu_codigo_reside,
                   deuda_lur_con_credito,
                   edad_deudor,
                   compromiso_vencido,
                   dnp,
                   dpp,
                   ip,
                   menor_per_deuda,
                   mayor_per_deuda,
                   tipo_deudor,
                   tipo_empresa,
                   equipo_cobrador
            FROM #tabla_final
            WHERE 1=1 ' + @sqlwhere;

        EXEC sp_executesql @sql1;
    END
    ELSE
    BEGIN
        DECLARE @sql1 NVARCHAR(MAX) = N'
            INSERT INTO dbo.GCO_ENVMSG_MENSAJE (
                ATE_CODIGO,
                EME_FECHAREG,
                EME_FECENVIO,
                EME_ESTADO,
                RUT_DEUDOR,
                EME_NOMBRE_DEUDOR,
                EME_EMAIL_DEUDOR,
                EME_FONO_DEUDOR,
                EME_DEUDA_COTIZ,
                EME_DEUDA_LUR,
                EME_DEUDA_CHQ,
                COB_CODIGO,
                EME_DESCRIP_ENVIO,
                EPR_CODIGO,
                EPL_FECHORA)
            SELECT ' + CAST(@ATE_CODIGO AS VARCHAR(5)) + ',
                   GETDATE(),
                   NULL,
                   0,
                   RUT_DEUDOR,
                   NOMBRE_DEUDOR,
                   EMAIL_DESTINATARIO,
                   FONO_CONTACTO,
                   DEUDA_COTIZACIONES,
                   DEUDA_LUR,
                   DEUDA_CHQ,
                   CASE WHEN ''' + @TIPODEUDACOTIZ + '''= ''SI'' THEN TF.COB_CODIGO ELSE TF.COBRADOR_ASIGNADO_LUR_CHQ END,
                   NULL,
                   CAST(''' + CAST(@epr_codigo AS VARCHAR) + ''' AS NUMERIC(10)),
                   ''' + CONVERT(VARCHAR, ISNULL(@epl_fechora, '19000101'), 121) + '''
            FROM #TABLA_FINAL TF
            WHERE 1=1 ' + @sqlwhere;

        EXEC sp_executesql @sql1;
    END

    IF OBJECT_ID('tempdb..#tabla_final') IS NOT NULL DROP TABLE #tabla_final;

    -- Puedes incluir aquí limpieza adicional de tablas temporales si es necesario

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    SET @ErrorMessage = ERROR_MESSAGE();
    SET @ErrorSeverity = ERROR_SEVERITY();
    SET @ErrorState = ERROR_STATE();

    RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    RETURN;
END CATCH;
