/*========================================================================================   
 tipo de objeto  : procedimiento almacenado                                          
 nombre del objeto : spu_ges_cob_mensajes_obtener_datos                                                                                                    
 parametros   : @epl_codigo varchar(50) = código de plantilla.                                                                                      
 creado por   : jorge molina               
 fecha creación  : 09-2025                                                      
 descripción  : Lista de deudores a partir de plantillas con filtros asociados.    
   
 modificación  : jorge molina               
 fecha creación  : 22-10-2025                                                      
 descripción  : se agrego un nuevo párametro del sp :  @epl_fechora, y en la insercion   
      del envio GCO_ENVMSG_MENSAJE se agregaron las 2 columnas: ,EPR_CODIGO  
      ,EPL_FECHORA  

 modificación  : jorge molina               
 fecha creación  : 22-10-2025                                                      
 descripción  : se quito las columnas:  equipo_interno , equipo_juridico , equipo_stock , equipo_otro de la #tabla_final

  modificación  : jorge molina               
 fecha creación  : 06-11-2025                                                      
 descripción  : a) se corrige INSERT INTO dbo.GCO_ENVMSG_MENSAJE ya que el su campo EPR_CODIGO cambio de varchar a numeric
				b) Se crea #tabla_final_filtrada, copia en estructura de #tabla_final, y contendra los registros filtrados.
				c) que si el @enviar = 'S' se debe validar la existencia del parametro @epr_codigo
				d) se corrige filtro CONCEPTO 4 Grupo Deuda: VALORES A, B, C

 modificación  : jorge molina               
 fecha creación  : 07-11-2025                                                      
 descripción  : a)se corrige filtro EDAD DEUDOR

 modificación  : jorge molina               
 fecha creación  : 14-11-2025                                                      
 descripción  : Se agrega la seccion 'generar_cupones'
  
========================================================================================*/  
/*   
GRANT EXECUTE ON [spu_ges_cob_mensajes_obtener_datos] TO public;  
  
declare @epl_fechora datetime
SET @epl_fechora = '20251120'  
--insert into GCO_ENVMSG_PROGRAMA_LOG values(1, @epl_fechora, null)  
execute spu_ges_cob_mensajes_obtener_datos_cupones 1, 'S', 1, @epl_fechora , 'S' 

execute spu_ges_cob_mensajes_obtener_datos 1
execute spu_ges_cob_mensajes_obtener_datos_cupones 1, 'N', NULL, NULL, 'N'		--eran 1160 reg aprox en 45 seg aprox, EN TABLA NUEVA: 1265 

*/  
  
alter procedure [dbo].[spu_ges_cob_mensajes_obtener_datos_cupones]   
@epl_codigo varchar(50) = null  
, @enviar char(1) = 'N'  
, @epr_codigo numeric(10) = null  
, @epl_fechora datetime = null  
, @generar_cupones char(1) = 'N'
AS  
BEGIN   
 set nocount on;  
  
 declare @sqlwhere nvarchar(4000)  
 declare @sqlfiltro nvarchar(1000)  
 declare @codigo_concepto numeric(5, 0)  
 declare @nombre_valor nvarchar(4000)  
 declare @uf_valor numeric(8, 2)  
 declare @fecha_hoy datetime  
 declare @PrimerDiaDelMes datetime  
 declare @PrimerDiaDelMesSgte datetime  
 declare @UltDiaMesAnterior datetime  
 declare @TipoDeudaCOTIZ varchar(2)  
 declare @TipoDeudaLUR varchar(2)  
 declare @TipoDeudaCHQ varchar(2)  
 declare @ate_codigo numeric(5)  
 DECLARE @ErrorMessage NVARCHAR(4000), @ErrorSeverity INT, @ErrorState INT; --captura detalles para auditoría o debugging  

declare @getdate datetime
set @getdate = getdate()
   
 set @fecha_hoy = cast( ( cast(getdate() as date)) as datetime)  
 select @primerdiadelmes = cast(dateadd(month, datediff(month, 0, getdate()), 0) as date)   
 select @primerdiadelmessgte = cast(dateadd(month, datediff(month, 0, getdate()) + 1, 0) as date)   
 set @ultdiamesanterior = dateadd(day, -1, @primerdiadelmes)  
  
 --VALIDACIONES PRINCIPALES  
  
 IF NOT EXISTS (  
   SELECT 1   
   FROM gco_envmsg_plantilla WITH (NOLOCK)   
   WHERE epl_codigo = @epl_codigo  
 )  
 BEGIN  
   RAISERROR('No existe plantilla: %s', 16, 1, @epl_codigo)  
   RETURN  
 END  
  
 IF NOT EXISTS (  
   select 1 from gco_envmsg_filtro with (nolock) where epl_codigo = @epl_codigo  
 )  
 BEGIN  
   RAISERROR('No existe filtros en la plantilla: %s', 16, 1, @epl_codigo)  
   RETURN  
 END  
  
  
 select @uf_valor = uf_valor from uf with (nolock) where uf_fecha = @ultdiamesanterior  
  
 if @uf_valor is null  
 begin  
  --select 'no existe uf'  
  --return   
  DECLARE @fecha_str VARCHAR(10);  
  SET @fecha_str = CONVERT(VARCHAR(10), @ultdiamesanterior, 120);  
  
  RAISERROR('No existe valor UF para la fecha: %s', 16, 1, @fecha_str);  
  RETURN;  
 end  
  
 if @enviar = 'S'  
  begin  

   if @epr_codigo is null  
   begin   
      RAISERROR('Falta código de programa(@epr_codigo)', 16, 1)  
      RETURN  
   end  

   select @ate_codigo =  ate_codigo from GCO_ENVMSG_PROGRAMA with (nolock) where epr_codigo = @epr_codigo  
  
 -- set @ate_codigo = 1 --PRUEBA **********************

   if @ate_codigo is null  
   begin  
    --select 'no existe programa con api template'  
    --return   
	DECLARE @codigo_str varchar(20);
	SET @codigo_str = CONVERT(varchar(20), @epr_codigo);

      RAISERROR('No existe registro en GCO_ENVMSG_PROGRAMA con el código de programa(@epr_codigo):%s', 16, 1, @codigo_str) 
	  --RAISERROR('No existe programa con api template con el código de programa(@epr_codigo):', 16, 1) 
      RETURN  
   end  
  
   if @epl_fechora is null  
   begin  
      RAISERROR('Falta parámetro de entrada @epl_fechora, para el código de programa(@epr_codigo): %s', 16, 1, @codigo_str)  
      RETURN  
   end  


   --revisar @epr_codigo y @epl_fechora existan como registro en GCO_ENVMSG_PROGRAMA_LOG
   IF NOT EXISTS (  
   SELECT 1   
   FROM dbo.GCO_ENVMSG_PROGRAMA_LOG WITH (NOLOCK)   
   WHERE epr_codigo = @epr_codigo  and epl_fechora = @epl_fechora
	 )  
	 BEGIN  
	   RAISERROR('No existe registro en GCO_ENVMSG_PROGRAMA_LOG conlos parámetros @epr_codigo y @epl_fechora', 16, 1)  
	   RETURN  
	 END  

  
  end  
  
 set @sqlwhere = ''  
 set @sqlfiltro = ''  
 set @TipoDeudaCOTIZ = ''  
 set @TipoDeudaLUR = ''  
 set @TipoDeudaCHQ = ''  
  
 -- SECCION CREACION DEL WHERE. COMIENZO__________  
 --CURSOR  
 DECLARE CUR_FILTROS CURSOR FOR  
    
   SELECT ECO_CODIGO  
   , EFI_VALOR  
   FROM GCO_ENVMSG_FILTRO WITH (NOLOCK)  
   WHERE EPL_CODIGO = @epl_codigo   
   ORDER BY 1  
  
 OPEN CUR_FILTROS  
  
 FETCH NEXT FROM CUR_FILTROS INTO @CODIGO_CONCEPTO, @NOMBRE_VALOR  
  
 WHILE @@FETCH_STATUS = 0  
 BEGIN  
  
  
  
  SET @sqlfiltro = ''  
  
  IF @CODIGO_CONCEPTO = 1   
  BEGIN  
   IF @NOMBRE_VALOR LIKE '%1%'  
    SET @sqlfiltro = CASE WHEN @sqlfiltro = '' THEN 'INTERNO' ELSE @sqlfiltro + ''',''INTERNO' END  
   IF @NOMBRE_VALOR LIKE '%2%'  
    SET @sqlfiltro = CASE WHEN @sqlfiltro = '' THEN 'STOCK' ELSE @sqlfiltro + ''',''STOCK' END  
   IF @NOMBRE_VALOR LIKE '%3%'  
    SET @sqlfiltro = CASE WHEN @sqlfiltro = '' THEN 'JUDICIAL' ELSE @sqlfiltro + ''',''JUDICIAL' END  
   IF @NOMBRE_VALOR LIKE '%4%'  
    SET @sqlfiltro = CASE WHEN @sqlfiltro = '' THEN 'OTROS' ELSE @sqlfiltro + ''',''OTROS' END  
  
   --SET @sqlwhere = @sqlwhere + @sqlfiltro  
   SET @sqlwhere = @sqlwhere + ' and equipo_cobrador IN ('''+@sqlfiltro+''')' 
  END  


  
  --CONCEPTO 2: Supervisor   
  IF @CODIGO_CONCEPTO = 2   
  BEGIN  
   SET @sqlfiltro = REPLACE(@NOMBRE_VALOR, '|', ',')  
   SET @sqlwhere = @sqlwhere + ' and supervisor_asig in ('+@sqlfiltro+')'  
  END  
  
  --CONCEPTO 3: cobrador asignado  
  IF @CODIGO_CONCEPTO = 3   
  BEGIN  
   SET @sqlfiltro = REPLACE(@NOMBRE_VALOR, '|', ',')  
   SET @sqlwhere = @sqlwhere + ' and COB_CODIGO in ('+@sqlfiltro+')'  
  END  
  
  -- --CONCEPTO 4 Grupo Deuda: VALORES A, B, C  
  -- --1 Afiliados Vigentes GRUPO A (DEUDA <= A UF 1)   
  -- --2 Afiliados Vigentes GRUPO B (DEUDA <= A UF 2)   
  -- --3 Afiliados Vigentes GRUPO C (DEUDA > A UF 3)  

-- correccion
--grupo A deuda de 0 cero y menores a 1 UF(incluye 1 uf)
--grupo B deuda mayores a 1 uf y menores o iguales a 2 uf
--grupo c deudas mayores a 2 uf

  IF @CODIGO_CONCEPTO = 4   
  BEGIN  

   IF @NOMBRE_VALOR LIKE '%1%'  
    SET @sqlfiltro = @sqlfiltro + CASE WHEN @sqlfiltro = '' THEN '  (deuda_cotizaciones > 0 and deuda_cotizaciones <= '+CAST(@UF_VALOR AS VARCHAR(20))+') '  
             ELSE ' or (deuda_cotizaciones > 0 and deuda_cotizaciones <= '+CAST(@UF_VALOR AS VARCHAR(20))+') ' END  
   IF @NOMBRE_VALOR LIKE '%2%'  
    SET @sqlfiltro = @sqlfiltro + CASE WHEN @sqlfiltro = '' THEN '  (deuda_cotizaciones > '+CAST(@UF_VALOR AS VARCHAR(20))+' and deuda_cotizaciones <= '+CAST(@UF_VALOR*2 AS VARCHAR(20))  +') '
             ELSE ' or (deuda_cotizaciones > '+CAST(@UF_VALOR AS VARCHAR(20))+' and deuda_cotizaciones <= '+CAST(@UF_VALOR*2 AS VARCHAR(20))  +') ' END  
   IF @NOMBRE_VALOR LIKE '%3%'  
    SET @sqlfiltro = @sqlfiltro + CASE WHEN @sqlfiltro = '' THEN '  (deuda_cotizaciones > '+CAST(@UF_VALOR*2 AS VARCHAR(20)) +') ' 
             ELSE ' or (deuda_cotizaciones > '+CAST(@UF_VALOR*2 AS VARCHAR(20)) +') '  END  

	--cuando hay tramos
	if @sqlfiltro <> ''
	begin 
		set @sqlfiltro = ' AND ('+@sqlfiltro+') '
	end

   SET @sqlwhere = @sqlwhere + @sqlfiltro  
  END  
  
  --5 Tipo y Vigencia Deudor  
  --Vigente  1, No Vigente 2, Empresa  3  
  IF @CODIGO_CONCEPTO = 5   
  BEGIN  
   IF @NOMBRE_VALOR LIKE '%1%'  
    SET @sqlfiltro = CASE WHEN @sqlfiltro = '' THEN 'VIGENTE' ELSE @sqlfiltro + ''',''VIGENTE' END  
   IF @NOMBRE_VALOR LIKE '%2%'  
    SET @sqlfiltro = CASE WHEN @sqlfiltro = '' THEN 'NO VIGENTE' ELSE @sqlfiltro + ''',''NO VIGENTE' END  
   IF @NOMBRE_VALOR LIKE '%3%'  
    SET @sqlfiltro = CASE WHEN @sqlfiltro = '' THEN 'EMPRESA' ELSE @sqlfiltro + ''',''EMPRESA' END  
  
   SET @sqlwhere = @sqlwhere + ' and TIPO_DEUDOR IN ('''+@sqlfiltro+''')'  
  END  
    
  --6 Con Gestión Cód.. 29 M  
  --1 Con, 2 Sin   
  IF @CODIGO_CONCEPTO = 6   
  BEGIN  
   IF @NOMBRE_VALOR LIKE '%1%'  
    SET @sqlfiltro = CASE WHEN @sqlfiltro = '' THEN 'Si' ELSE @sqlfiltro + ''',''Si' END  
   IF @NOMBRE_VALOR LIKE '%2%'  
    SET @sqlfiltro = CASE WHEN @sqlfiltro = '' THEN 'No' ELSE @sqlfiltro + ''',''No' END  
  
   SET @sqlwhere = @sqlwhere + ' and gestion29 IN ('''+@sqlfiltro+''')'  
  END  
  
  --CONCEPTO = 7 Fecha Compromiso vencido  
  --1.- Vencidos (Compromiso Hoy-1)  
  --2.- No Vencidos (Compromiso >=Hoy)  
  IF @CODIGO_CONCEPTO = 7   
  BEGIN  
   IF @NOMBRE_VALOR LIKE '%1%'  
    SET @sqlfiltro = CASE WHEN @sqlfiltro = '' THEN ' and compromiso_vencido < convert(datetime, '''+CONVERT (varchar(30), @fecha_hoy , 121 ) +''', 121)'  
           ELSE @sqlfiltro + ' and compromiso_vencido < convert(datetime, '''+CONVERT (varchar(30), @fecha_hoy , 121 ) +''', 121)' END  
   IF @NOMBRE_VALOR LIKE '%2%'  
    SET @sqlfiltro = CASE WHEN @sqlfiltro = '' THEN ' and compromiso_vencido >= convert(datetime, '''+CONVERT (varchar(30), @fecha_hoy , 121 ) +''', 121)'  
           ELSE @sqlfiltro + ' and compromiso_vencido >= convert(datetime, '''+CONVERT (varchar(30), @fecha_hoy , 121 ) +''', 121)' END  
  
   SET @sqlwhere = @sqlwhere + ' AND compromiso_vencido IS NOT NULL ' +@sqlfiltro  
  END  
    
  
  --CONCEPTO 8 Tipo de Deuda  
  --1 Cotizaciones, 2 Ley de Urgencia, 3 Cheques Protestados  
  IF @CODIGO_CONCEPTO = 8   
  BEGIN  
   IF @NOMBRE_VALOR LIKE '%1%'  
   BEGIN  
    SET @sqlfiltro = CASE WHEN @sqlfiltro = '' THEN ' and deuda_cotizaciones > 0' ELSE @sqlfiltro + ' and deuda_cotizaciones > 0' END  
    SET @TipoDeudaCOTIZ = 'SI'  
   END  
   IF @NOMBRE_VALOR LIKE '%2%'  
   BEGIN  
    SET @sqlfiltro = CASE WHEN @sqlfiltro = '' THEN ' and deuda_lur > 0' ELSE @sqlfiltro + ' and deuda_lur > 0' END  
    SET @TipoDeudaLUR = 'SI'  
   END  
   IF @NOMBRE_VALOR LIKE '%3%'  
   BEGIN  
    SET @sqlfiltro = CASE WHEN @sqlfiltro = '' THEN ' and deuda_chq > 0' ELSE @sqlfiltro + ' and deuda_chq > 0' END  
    SET @TipoDeudaCHQ = 'SI'  
   END  
  
   SET @sqlwhere = @sqlwhere + @sqlfiltro  
  END  
    
  
  --CONCEPTO 9 Tipo Deuda Cotizaciones  
  --1 DNP, 2 IP, 3 DPP  
  IF @CODIGO_CONCEPTO = 9  
  BEGIN  
   IF @NOMBRE_VALOR LIKE '%1%'  
    SET @sqlfiltro = CASE WHEN @sqlfiltro = '' THEN ' and DNP > 0' ELSE @sqlfiltro + ' and DNP > 0' END  
   IF @NOMBRE_VALOR LIKE '%2%'  
    SET @sqlfiltro = CASE WHEN @sqlfiltro = '' THEN ' and IP > 0' ELSE @sqlfiltro + ' and IP > 0' END  
   IF @NOMBRE_VALOR LIKE '%3%'  
    SET @sqlfiltro = CASE WHEN @sqlfiltro = '' THEN ' and DPP > 0' ELSE @sqlfiltro + ' and DPP > 0' END  
  
   SET @sqlwhere = @sqlwhere + @sqlfiltro  
  END  
  
  
  --CONCEPTO 10: Menor Periodo de Deuda M  
  -- Marcelo: Menor periodo de deuda: hasta 6, hasta 5, hasta 4  
  IF @CODIGO_CONCEPTO = 10   
  BEGIN  
   IF @NOMBRE_VALOR LIKE '%1%'  
    SET @sqlfiltro = CASE WHEN @sqlfiltro = '' THEN ' and menor_per_deuda >= convert(datetime, '''+CONVERT (varchar(30), dateadd(month, -6, @PrimerDiaDelMes) , 121 ) +''', 121)'  
           ELSE @sqlfiltro + ' and menor_per_deuda >= convert(datetime, '''+CONVERT (varchar(30), dateadd(month, -6, @PrimerDiaDelMes) , 121 ) +''', 121)' END  
   IF @NOMBRE_VALOR LIKE '%2%'  
    SET @sqlfiltro = CASE WHEN @sqlfiltro = '' THEN ' and menor_per_deuda >= convert(datetime, '''+CONVERT (varchar(30), dateadd(month, -5, @PrimerDiaDelMes) , 121 ) +''', 121)'  
           ELSE @sqlfiltro + ' and menor_per_deuda >= convert(datetime, '''+CONVERT (varchar(30), dateadd(month, -5, @PrimerDiaDelMes) , 121 ) +''', 121)' END  
   IF @NOMBRE_VALOR LIKE '%3%'  
    SET @sqlfiltro = CASE WHEN @sqlfiltro = '' THEN ' and menor_per_deuda >= convert(datetime, '''+CONVERT (varchar(30), dateadd(month, -4, @PrimerDiaDelMes) , 121 ) +''', 121)'  
           ELSE @sqlfiltro + ' and menor_per_deuda >= convert(datetime, '''+CONVERT (varchar(30), dateadd(month, -4, @PrimerDiaDelMes) , 121 ) +''', 121)' END  
  
   SET @sqlwhere = @sqlwhere + ' AND menor_per_deuda IS NOT NULL ' +@sqlfiltro  
  END  
  
  
  --CONCEPTO 11: Mayor periodo de deuda  
  -- Marcelo: Mayor periodo de deuda: hasta 4, Hasta 3, Hasta 2  
  IF @CODIGO_CONCEPTO = 11  
  BEGIN  
   IF @NOMBRE_VALOR LIKE '%1%'  
    SET @sqlfiltro = CASE WHEN @sqlfiltro = '' THEN ' and mayor_per_deuda >= convert(datetime, '''+CONVERT (varchar(30), dateadd(month, -4, @PrimerDiaDelMes) , 121 ) +''', 121)'  
           ELSE @sqlfiltro + ' and mayor_per_deuda >= convert(datetime, '''+CONVERT (varchar(30), dateadd(month, -4, @PrimerDiaDelMes) , 121 ) +''', 121)' END  
   IF @NOMBRE_VALOR LIKE '%2%'  
    SET @sqlfiltro = CASE WHEN @sqlfiltro = '' THEN ' and mayor_per_deuda >= convert(datetime, '''+CONVERT (varchar(30), dateadd(month, -3, @PrimerDiaDelMes) , 121 ) +''', 121)'  
           ELSE @sqlfiltro + ' and mayor_per_deuda >= convert(datetime, '''+CONVERT (varchar(30), dateadd(month, -3, @PrimerDiaDelMes) , 121 ) +''', 121)' END  
   IF @NOMBRE_VALOR LIKE '%3%'  
    SET @sqlfiltro = CASE WHEN @sqlfiltro = '' THEN ' and mayor_per_deuda >= convert(datetime, '''+CONVERT (varchar(30), dateadd(month, -2, @PrimerDiaDelMes) , 121 ) +''', 121)'  
           ELSE @sqlfiltro + ' and mayor_per_deuda >= convert(datetime, '''+CONVERT (varchar(30), dateadd(month, -2, @PrimerDiaDelMes) , 121 ) +''', 121)' END  
  
   SET @sqlwhere = @sqlwhere + ' AND mayor_per_deuda IS NOT NULL ' +@sqlfiltro  
  END  
  
  
  --CONCEPTO 12: CIUDAD DE RESIDENCIA  
  IF @CODIGO_CONCEPTO = 12   
  BEGIN  
   SET @sqlfiltro = REPLACE(@NOMBRE_VALOR, '|', ',')  
  
   SET @sqlwhere = @sqlwhere + ' and CIU_CODIGO_RESIDE in ('+@sqlfiltro+')'  
  
  END  
  
  
  --CONCEPTO 13: Deudores LUR con Crédito 5%  
  --1 SI, --2 NO  
  IF @CODIGO_CONCEPTO = 13   
  BEGIN  
   IF @NOMBRE_VALOR LIKE '%1%'  
    SET @sqlfiltro = CASE WHEN @sqlfiltro = '' THEN 'Si' ELSE @sqlfiltro + ''',''Si' END  
   IF @NOMBRE_VALOR LIKE '%2%'  
    SET @sqlfiltro = CASE WHEN @sqlfiltro = '' THEN 'No' ELSE @sqlfiltro + ''',''No' END  
  
   SET @sqlwhere = @sqlwhere + ' and deuda_lur_con_credito IN ('''+@sqlfiltro+''')'  
  END  
  
  
  --CONCEPTO 16: Posible Compensar x TFU Si cuenta con saldo disponible de devolución TFU  
  --1 SI ,  --2 NO   
  IF @CODIGO_CONCEPTO = 16   
  BEGIN  
   IF @NOMBRE_VALOR LIKE '%1%'  
    SET @sqlfiltro = CASE WHEN @sqlfiltro = '' THEN ' and monto_posible_compensar > 0' ELSE @sqlfiltro + ' and monto_posible_compensar > 0' END  
   IF @NOMBRE_VALOR LIKE '%2%'  
    SET @sqlfiltro = CASE WHEN @sqlfiltro = '' THEN ' and monto_posible_compensar <= 0' ELSE @sqlfiltro + ' and monto_posible_compensar  <= 0' END  
  
   SET @SQLWHERE = @SQLWHERE + @SQLFILTRO  
  END  
  
  
  --CONCEPTO 17 EDAD DEUDOR  
  --1 18-25, 2 26-40, 3 41 - 55,4 Otros  
  IF @CODIGO_CONCEPTO = 17   
  BEGIN  

   IF @NOMBRE_VALOR LIKE '%1%'  
    SET @sqlfiltro = CASE WHEN @sqlfiltro = '' THEN ' ( EDAD_DEUDOR >= 18 and EDAD_DEUDOR <= 25 ) ' ELSE @sqlfiltro + ' OR ( EDAD_DEUDOR >= 18 and EDAD_DEUDOR <= 25 ) ' END  
   IF @NOMBRE_VALOR LIKE '%2%'  
    SET @sqlfiltro = CASE WHEN @sqlfiltro = '' THEN ' ( EDAD_DEUDOR >= 26 and EDAD_DEUDOR <= 40 ) ' ELSE @sqlfiltro + ' OR ( EDAD_DEUDOR >= 26 and EDAD_DEUDOR <= 40 ) ' END  
   IF @NOMBRE_VALOR LIKE '%3%'  
    SET @sqlfiltro = CASE WHEN @sqlfiltro = '' THEN ' ( EDAD_DEUDOR >= 41 and EDAD_DEUDOR <= 55 ) ' ELSE @sqlfiltro + ' OR ( EDAD_DEUDOR >= 41 and EDAD_DEUDOR <= 55 ) ' END  
   IF @NOMBRE_VALOR LIKE '%4%'  
    SET @sqlfiltro = CASE WHEN @sqlfiltro = '' THEN ' ( EDAD_DEUDOR > 55 ) ' ELSE @sqlfiltro + ' OR ( EDAD_DEUDOR > 55 )' END  

	--cuando hay tramos
	if @sqlfiltro <> ''
	begin 
		set @sqlfiltro = ' AND ('+@sqlfiltro+') '
	end
  
   SET @sqlwhere = @sqlwhere + @sqlfiltro  
  END  
  
  FETCH NEXT FROM CUR_FILTROS INTO @CODIGO_CONCEPTO, @NOMBRE_VALOR  
  
 END  
  
 CLOSE CUR_FILTROS  
 DEALLOCATE CUR_FILTROS  
  
 ----prueba_  
 --PRINT 'WHERE:_'+@sqlwhere+'_'  
 --PRINT 'TipoDeudaCOTIZ:_'+@TipoDeudaCOTIZ+'_'  
 --PRINT 'TipoDeudaLUR:_'+@TipoDeudaLUR+'_'  
 --PRINT 'TipoDeudaCHQ:_'+@TipoDeudaCHQ+'_'  
 --set @sqlwhere = ''  
 ----prueba_  
  
 -- Validar que @sqlwhere no esté vacío o malformado  
 -- SI NO EXISTE WHERE NO SE PODRA EJECUTAR EL PROCESO  
 IF @sqlwhere IS NULL OR @sqlwhere = ''  
 BEGIN  
  RAISERROR('No existe filtros @sqlwhere en la plantilla: %s', 16, 1, @epl_codigo)  
  RETURN  
 END  
  
  
 -- SECCION CREACION DEL WHERE. TERMINO__________  
  
  
 if object_id('tempdb..#DEUDA_COTIZ_EMPL', 'u') is not null drop table #DEUDA_COTIZ_EMPL  
 if object_id('tempdb..#TMP_DEUDA_COTIZANTE', 'u') is not null drop table #TMP_DEUDA_COTIZANTE  
 if object_id('tempdb..#origen_cotiz_empl', 'u') is not null drop table #origen_cotiz_empl  
 if object_id('tempdb..#origen_lur_chq', 'u') is not null drop table #origen_lur_chq  
 if object_id('tempdb..#tabla_final', 'u') is not null drop table #tabla_final  
 if object_id('tempdb..#tabla_final_filtrada', 'u') is not null drop table #tabla_final_filtrada
 if object_id('tempdb..#tfu', 'u') is not null drop table #tfu  
 if object_id('tempdb..#compromiso', 'u') is not null drop table #compromiso  
 if object_id('tempdb..#cobrador_asig_lurchq', 'u') is not null drop table #cobrador_asig_lurchq  
 if object_id('tempdb..#cobrador_asig_cotiz', 'u') is not null drop table #cobrador_asig_cotiz  
 if object_id('tempdb..#f_supervisor_asig', 'u') is not null drop table #f_supervisor_asig   
 if object_id('tempdb..#f_vigencia_personas', 'u') is not null drop table #f_vigencia_personas  
 if object_id('tempdb..#f_gestion29', 'u') is not null drop table #f_gestion29  
 if object_id('tempdb..#f_compromiso_vencido', 'u') is not null drop table #f_compromiso_vencido  
 if object_id('tempdb..#f_deuda_lur_con_credito', 'u') is not null drop table #f_deuda_lur_con_credito  
 if object_id('tempdb..#equipo_cobrador', 'u') is not null drop table #equipo_cobrador  
 if object_id('tempdb..#email', 'u') is not null drop table #email 
 if object_id('tempdb..#fono', 'u') is not null drop table #fono

  
 --#TABLA_FINAL: TABLA DEL RESULTADO FINAL.  
 create table #tabla_final  
 ( rut_deudor char(10) not null  
  , nombre_deudor varchar(100) null  
  , email_destinatario varchar(100) null  
  , deuda_cotizaciones numeric(15) null  
  , monto_cupon numeric(15) null --**  
  , monto_posible_compensar numeric(15) null  
  , cob_codigo numeric(5) null --**  
  , nombre_ejecutivo varchar(100) null  
  , email_ejecutivo varchar(100) null  
  , fono_ejecutivo varchar(30) null  
  , url_link varchar(1000) null  
  , url_link1 varchar(1000) null  
  , url_link2 varchar(1000) null  
  , fecha_compromiso datetime null  
  , monto_compromiso numeric(15) null  
  , deuda_lur numeric(15) null  
  , deuda_chq numeric(15) null  
  , cobrador_asignado_lur_chq numeric(10) null  
  , nom_cob_lurchq varchar(100) null  
  , email_cob_lurchq varchar(100) null  
  , fono_cob_lurchq varchar(30) null  
  , fono_contacto varchar(50) null  
  , supervisor_asig numeric(4) null --*  
  , gestion29 varchar(2) null  
  , ciu_codigo_reside numeric(4) null   
  , deuda_lur_con_credito varchar(2) null  
  , edad_deudor numeric(4) null  
  , compromiso_vencido datetime null  
  , dnp numeric(4) null  
  , dpp numeric(4) null  
  , ip numeric(4) null  
  , menor_per_deuda datetime null  
  , mayor_per_deuda datetime null  
  , tipo_deudor varchar(30) null		--Valores: VIGENTE, NO VIGENTE, EMPRESA
  , tipo_empresa varchar(30) null		--Valores: COTIZANTE, EMPRESA
  , equipo_cobrador varchar(20) null  
  , cup_correl numeric(15) null
  --, primary key (rut_deudor)  
 )  

 --Se crea #tabla_final_filtrada, copia en estructura de #tabla_final, y contendra los registros filtrados.
 select *
 into #tabla_final_filtrada
 from #tabla_final
  
 create table #DEUDA_COTIZ_EMPL  
 (  
 COT_RUT char(10) not null  
 , DEC_PERIODO datetime null  
 , DEUDA_EMPLEADOR numeric(15) null  
 )  
  
 create table #TMP_DEUDA_COTIZANTE  
 (  
 DEC_RUT char(10) not null  
 , COT_RUT char(10) not null 
 , DEC_PERIODO datetime null  
 , DEC_TIPO_DEUDA varCHAR(20)  
 , tipo_empresa varCHAR(20)  
 , DEC_TIPO_COTIZANTE CHAR(10)  
 , DEC_DEUDA numeric(15) null  
 , DEUDA_REAJUSTADA numeric(15) null  
 )  
  
  
 --1.-   
 IF @TipoDeudaCOTIZ = 'SI'  
 BEGIN   
   --1.- Obtiene la deuda de cada COTIZANTE cuya responsabilidad de pago es de algún empleador  
   INSERT #DEUDA_COTIZ_EMPL (COT_RUT, DEC_PERIODO, DEUDA_EMPLEADOR)  
   SELECT  COT_RUT,   
    DEC_PERIODO,  
    SUM(CASE WHEN EPA_RUT IS NOT NULL THEN DEC_PACTADO - DEC_PAGADO END) AS DEUDA_EMPLEADOR  
   FROM DEUDA_COTIZANTE with (nolock)  
   WHERE EPA_RUT IS NOT NULL  
   GROUP BY  COT_RUT, DEC_PERIODO  
  
   CREATE INDEX IDX_1 ON #deuda_cotiz_empl(COT_RUT,DEC_PERIODO)  
  
  
   --2.-Obtiene los registros de deudores desde DEUDA_COTIZANTE, pero restando a los registros de cotizantes (EPA_RUT IS NULL) el monto de la deuda cuya responsabilidad es de algún empleador  
   --y filtramos sólo aquellos registros que quedan con deuda > 0  
   insert into #TMP_DEUDA_COTIZANTE  
   SELECT   
    DC.DEC_RUT, 
	DC.COT_RUT,
    DC.DEC_PERIODO,  
    CASE  
     WHEN DC.DEC_TIPO_DEUDA = 'DNP' THEN 'DNP'  
      WHEN DC.DEC_TIPO_DEUDA = 'NP' AND DC.DEC_PAGADO=0 THEN 'IP'  
     ELSE 'DPP'    
    END AS DEC_TIPO_DEUDA,  
    CASE WHEN EPA_RUT  IS NOT NULL THEN 'EMPRESA' ELSE 'COTIZANTE' END AS tipo_empresa ,  --TIPO_DEUDOR se cambia a tipo_empresa  
    DEC_TIPO_COTIZANTE,  
    (coalesce(DEC_PACTADO,0) - coalesce(DEC_PAGADO,0)) - coalesce(deuda_empleador,0) as DEC_DEUDA,  
    (coalesce(DEC_PACTADO,0) - coalesce(DEC_PAGADO,0)) - coalesce(deuda_empleador,0) +   
     ROUND((CASE WHEN (INTERESES.INT_REAJUSTE < 0) OR (INTERESES.INT_REAJUSTE IS NULL) THEN 0 ELSE INTERESES.INT_REAJUSTE END) / 100 * ((coalesce(DEC_PACTADO,0) - coalesce(DEC_PAGADO,0)) - coalesce(deuda_empleador,0)), 0) +  
     ROUND((CASE WHEN (INTERESES.INT_INTERES  < 0) OR (INTERESES.INT_INTERES IS NULL ) THEN 0 ELSE INTERESES.INT_INTERES  END) / 100 * ((coalesce(DEC_PACTADO,0) - coalesce(DEC_PAGADO,0)) - coalesce(deuda_empleador,0)), 0) +  
     ROUND((CASE WHEN (INTERESES.INT_RECARGO < 0)  OR (INTERESES.INT_RECARGO IS NULL)  THEN 0 ELSE INTERESES.INT_RECARGO END)  / 100 * ((coalesce(DEC_PACTADO,0) - coalesce(DEC_PAGADO,0)) - coalesce(deuda_empleador,0)), 0)   
    AS DEUDA_REAJUSTADA  
   FROM DEUDA_COTIZANTE DC with (nolock)  
    LEFT JOIN #deuda_cotiz_empl D   
     ON DC.COT_RUT=D.COT_RUT AND DC.DEC_PERIODO=D.DEC_PERIODO AND DC.EPA_RUT IS NULL  
    LEFT JOIN INTERESES (NOLOCK) ON INTERESES.INT_PPC_PERIODO = DC.DEC_PERIODO AND INTERESES.INT_FECHA_PAGO = CONVERT(CHAR(8), GETDATE(),112)  
   WHERE (coalesce(DEC_PACTADO,0) - coalesce(DEC_PAGADO,0)) - coalesce(deuda_empleador,0) >0  
  
   CREATE INDEX ix_TMP_DEUDA_COTIZANTE ON #TMP_DEUDA_COTIZANTE(DEC_RUT)  
 END   
  
  
 --3.--#origen_cotiz_empl: TABLA_ORIGEN1: rut con deuda de cotizaciones  
 SELECT   
  d.dec_rut AS rut,  
  SUM(ISNULL(d.dec_deuda, 0)) AS deuda,  
  SUM(CASE WHEN d.dec_tipo_deuda = 'DNP' THEN 1 ELSE 0 END) AS dnp,  
  SUM(CASE WHEN d.dec_tipo_deuda = 'DPP' THEN 1 ELSE 0 END) AS dpp,  
  SUM(CASE WHEN d.dec_tipo_deuda = 'IP' THEN 1 ELSE 0 END) AS ip,  
  MIN(d.dec_periodo) AS menor_per_deuda,  
  MAX(d.dec_periodo) AS mayor_per_deuda,   
  MAX(D.tipo_empresa) as tipo_empresa  
 INTO #origen_cotiz_empl  
 FROM #TMP_DEUDA_COTIZANTE d  
 GROUP BY d.dec_rut  
  
 create nonclustered index ix_origen_cotiz_empl_rut on #origen_cotiz_empl (rut)  
  
  
 --4.- origen_lur_chq : TABLA_ORIGEN2: RUTS con deuda LUR Y/o CHQ (GCDF_DEUDA)  
 CREATE TABLE #origen_lur_chq  
 (  
 rut CHAR(10) NULL  
 , deuda_lur numeric(15) null  
 , deuda_chq numeric(15) null  
 )  
  
 IF @TipoDeudaLUR = 'SI' OR @TipoDeudaCHQ = 'SI'  
 BEGIN  
   INSERT #origen_lur_chq  
   select  
     DDR_rut as rut,  
     --sum(case when TDE_CODIGO = 1 then deu_monto else 0 end) as deuda_lur,  
     --sum(case when TDE_CODIGO = 2 then deu_monto else 0 end) as deuda_chq  
     case when @TipoDeudaLUR = 'SI' then sum(case when TDE_CODIGO = 1 then deu_monto else 0 end) else null end as deuda_lur,  
     case when @TipoDeudaCHQ = 'SI' then sum(case when TDE_CODIGO = 2 then deu_monto else 0 end) else null end as deuda_chq    
   from dbo.GCDF_DEUDA gd with (nolock)  
   where deu_monto > 0  
   and TDE_CODIGO in (1, 2)  
   group by DDR_rut  
  
   create nonclustered index ix_origen_chq_rut on #origen_lur_chq (rut)  
 END  
  
  
 --5.- INSERTAR #tabla_final LOS RUTS DE LOS 2 TABLAS_ORIGENES: #origen_cotiz_empl FULL OUTER JOIN #origen_lur_chq.  
 insert #tabla_final (rut_deudor, deuda_cotizaciones, dnp, dpp, ip, menor_per_deuda, mayor_per_deuda, deuda_lur, deuda_chq, tipo_empresa)  
 SELECT  
  COALESCE(a.rut, b.rut) AS rut,  
  a.deuda,  
  a.DNP,  
  a.DPP,  
  a.IP,  
  a.menor_per_deuda,  
  a.mayor_per_deuda,  
  b.deuda_lur,  
  b.deuda_chq,       
   a.tipo_empresa  
 FROM  
  (  
   --UNIVERSO DEUDA COTIZACIONES  
   SELECT rut,  
     deuda,  
    dnp,  
    dpp,  
    ip,  
    menor_per_deuda,  
    mayor_per_deuda  
    , tipo_empresa  
   from #origen_cotiz_empl  
  ) a  
  FULL OUTER JOIN  
  (  
   --UNIVERSO LUR/CHQ  
   SELECT  
     rut,  
    deuda_lur,  
    deuda_chq  
   FROM #origen_lur_chq  
  ) b  
 ON a.rut = b.rut;  
  
 -- crear índice no agrupado después de insertar los datos para evitar ralentizaciones durante la inserción y acelerar consultas posteriores.  
 create nonclustered index ix_tabla_final_rut on #tabla_final (rut_deudor)  
    
 --6.- TABLA TFU  
 declare @uf_mes numeric(10,2)  
 select @uf_mes = dbo.f_get_ufmes(getdate())  
  
 select dt.cot_rut rut, convert(numeric(12),sum(round(dtc_monto * @uf_mes,0)) )  as saldo_tfu   
 into #tfu  
 from devolucion_tfu_cuota dt with (nolock)  
 join #tabla_final  
  on rut_deudor = dt.cot_rut  
 where dt.afi_rut is null   
 group by dt.cot_rut  
  
 create nonclustered index ix_tfu_rut on #tfu (rut)  
  
  
 --7.- #compromiso: Obtener compromisos de pago GEC_COMPROM_MONTO y GEC_COMPROM_FECHA, tengo que ir a buscar el ultimo para e rut fecha digita  
  
 select gc.ddr_rut rut, gc.GEC_COMPROM_MONTO monto, gc.GEC_COMPROM_FECHA fecha  
 into #compromiso  
 from GESTION_COBRANZA gc with (nolock)  
 join  
 (  
  select ddr_rut, max(GEC_FECDIGITA) GEC_FECDIGITA  
  from GESTION_COBRANZA gc with (nolock)  
  join #tabla_final t  
   on gc.DDR_RUT = t.rut_deudor  
  where tgc_codigo=29  
  and GEC_COMPROM_MONTO is not null  
  and GEC_COMPROM_FECHA is not null  
  group by ddr_rut  
 ) a  
 on gc.DDR_RUT = a.DDR_RUT  
 and gc.GEC_FECDIGITA = a.GEC_FECDIGITA  
  
 create nonclustered index ix_compromiso_rut on #compromiso (rut)  
  
  
 --tabla #cobrador_asig_cotiz  
 CREATE TABLE #cobrador_asig_cotiz  
 (  
 cob_codigo numeric(5) null  
 , rut char(10) null  
 )  
  
 IF @TipoDeudaCOTIZ = 'SI'   
 BEGIN  
    
   insert #cobrador_asig_cotiz (cob_codigo, rut)  
   select distinct cob_codigo, ddr_rut rut  
   FROM DEUDOR_ASIGNADO DAU with (NOLOCK)  
   WHERE    
   (  
    deu_asig_desde <= getdate()   
    and (deu_asig_hasta >= getdate() or deu_asig_hasta is null)  
   )    
   order by ddr_rut  
  
   create nonclustered index ix_cobrador_asig_rut on #cobrador_asig_cotiz (rut)  
  
 END  
  
  
 --tabla #cobrador_asig_lurchq  
 CREATE TABLE #cobrador_asig_lurchq  
 (  
 cob_codigo numeric(5) null  
 , rut char(10) null  
 )  
  
 --#f_deuda_lur_con_credito  
 CREATE TABLE #f_deuda_lur_con_credito  
 (  
 rut CHAR(10) NULL  
 , deuda_lur_con_credito varchar(2) null  
 )  
  
 IF @TipoDeudaLUR = 'SI' OR @TipoDeudaCHQ = 'SI'  
 BEGIN  
   --8.- TABLA #cobrador_asig_lurchq: Cob. Asignado deuda LUR o CHP  
   insert #cobrador_asig_lurchq (cob_codigo, rut)  
   select distinct cob_codigo, ddr_rut rut  
   FROM GCDF_DEUDOR_ASIGNADO DAU with (NOLOCK)  
   WHERE    
   (  
    deu_asig_desde <= getdate()   
    and (deu_asig_hasta >= getdate() or deu_asig_hasta is null)  
   )    
  
   create nonclustered index ix_cobrador_asig_rut on #cobrador_asig_lurchq (rut)  
  
   --13.- FILTRO Deuda LUR con Crédito select DEU_CUOTAS, * from GCDF_DEUDA, f_deuda_lur_con_credito  
   insert into #f_deuda_lur_con_credito (rut, deuda_lur_con_credito)  
   select ddr_rut rut , case when sum(isnull(DEU_CUOTAS,0)) > 0 then 'Si' else 'No' end as deuda_lur_con_credito  
   from GCDF_DEUDA gc with (nolock)   
   join #tabla_final  
    on rut_deudor = ddr_rut  
   group by ddr_rut  
  
   create nonclustered index ix_f_deuda_lur_con_credito_rut on #f_deuda_lur_con_credito(rut)  
 END  
  
  
 --tabla de equipos de cobradores   
 select distinct deuda_cob.cob_codigo cob_codigo  
 , COALESCE(( case when coalesce(deuda_cob.cob_judicial,'N') = 'S' then 'JUDICIAL' else NULL end ), (case when coalesce(cob_dep.cob_codigo,0) = 9000 then 'STOCK' else NULL end), (case when coalesce(cob_dep.cob_codigo,0) = 9002 then 'INTERNO' else NULL end
), (case when ( (coalesce(cob_dep.cob_codigo,0) = 9002) or (coalesce(cob_dep.cob_codigo,0) = 9000) or (coalesce(deuda_cob.cob_judicial,'N') = 'S' ) ) then NULL else 'OTROS' end)    )  as equipo_cobrador  
 into #equipo_cobrador  
 from cobrador deuda_cob with (nolock)   
 left join cobrador as cob_dep  with (nolock)  on cob_dep.cob_codigo = deuda_cob.cob_codigo_dep  
  
  
 create nonclustered index ix_equipo_cobrador on #equipo_cobrador(cob_codigo)  
  
  
 --9.- FILTRO Supervisor: Obtener el SUP. vigente desde la tabla COBRADOR_SUP_ASIG  
 select c.cob_codigo cob_codigo, c.sco_codigo sco_codigo, c.csa_desde csa_desde  
 INTO #f_supervisor_asig  
 from COBRADOR_SUP_ASIG c with (nolock)  
 join  
 (  
  select cob_codigo, max(csa_desde) as csa_desde /*asignacion max*/  
  from COBRADOR_SUP_ASIG with (nolock)  
  where csa_desde <= getdate()  
  group by cob_codigo  
 ) a  
 on a.cob_codigo = c.cob_codigo  
 and a.csa_desde = c.CSA_DESDE  
  
 create nonclustered index ix_f_supervisor_asig_rut on #f_supervisor_asig(cob_codigo)  
  
  
 --10.- FILTRO Tipo Deudor: Si tiene contrato vigente es VIGENTE, si tiene contrato pero no está vigente es NO VIGENTE y en otro caso es EMPRESA  
 select distinct cot_rut AS rut  
 , case when (c.con_inivig <= getdate()  
    and (c.con_finvig >= getdate() or c.con_finvig is null)  
    ) then 'VIGENTE'  
    ELSE 'NO VIGENTE' END as vigencia  
 into #f_vigencia_personas  
 from contrato c with (nolock)  
 join #tabla_final  
  on rut_deudor = c.cot_rut  
 where con_ultimo = 'S'  
  
 create nonclustered index ix_f_vigencia_personas_rut on #f_vigencia_personas(rut)  
  
 --11.- FILTRO Gestion 29  TGC_CODIGO=29 (en el mes en curso)  
 select ddr_rut rut , case when count(*) > 0 then 'Si' else 'No' end as gestion29  
 into #f_gestion29  
 from GESTION_COBRANZA gc with (nolock)  
 join #tabla_final  
  on rut_deudor = gc.ddr_rut  
 where tgc_codigo = 29  
 and GEC_FECHA_GES >= @PrimerDiaDelMes  
 and GEC_FECHA_GES < @PrimerDiaDelMesSgte  
 group by ddr_rut  
  
 create nonclustered index ix_f_gestion29_rut on #f_gestion29(rut)  
  
  
 --12.- FILTRO Compromiso Vencido SELECT max(GEC_COMPROM_FECHA) FROM GESTION_COBRANZA  where DDR_RUT=@RUT   
 --sin (where GEC_COMPROM_FECHA is not null) : 175.932 reg en 46 seg  
 --con (where GEC_COMPROM_FECHA is not null) : 115.463 reg en 48 seg  
  
 select ddr_rut rut , max(GEC_COMPROM_FECHA) fecha  --se demora  
 into #f_compromiso_vencido  
 from GESTION_COBRANZA gc with (nolock)  
 join #tabla_final  
  on rut_deudor = gc.ddr_rut  
 where GEC_COMPROM_FECHA is not null  
 group by ddr_rut  
  
 create nonclustered index ix_f_compromiso_vencido_rut on #f_compromiso_vencido(rut);  
  
 -- FILTRO Tipo Empresa: PREGUNTAR A ALEX ******  
 -- FILTRO Rubro: PREGUNTAR A ALEX  *****  
  
  
 --------------------------------------------------------------------------------------------------------  
 -- MS: Obtiene los datos de contacto en forma masiva, sin utilizar f_get_datocontacto(), pero copiando su lógica  
 --------------------------------------------------------------------------------------------------------  
 WITH NumeradoPorGrupo AS (  
  select cto_rut  
   , ctd_email  
   ,ROW_NUMBER() OVER (PARTITION BY cto_rut ORDER BY isnull(ctd_tipo_val, 'V') desc, case when (ctd_fecreg > isnull(ctd_fecha_val, '19900101')) then ctd_fecreg  else ctd_fecha_val end desc, (case ctd_origen when 'PREVIRED' then 7  
          when 'GESCOBRANZA' then  6  
          when 'GESTION COBRANZA' then  5  
          when 'CONTRATO' then 4  
          when 'LICENCIA' then 3  
          when 'PAM' then 2  
          when 'BACK COBRANZAS' then 1  
          else 0  
          end)   
     +  
     (  
      case usu_login when 'SYSTEM' then 1  
          else 0  
          end  
      ) ) AS row_num  
   from dbo.CONTACTO_DET_GESCOB c with (nolock)  
    join #tabla_final tf on tf.rut_deudor=cto_rut  
    LEFT JOIN COMUNA CM ON C.CMN_CODIGO=CM.CMN_CODIGO  
    left join ciudad ci on ci.ciu_codigo=cm.ciu_codigo  
   WHERE ctd_email is not null  
   AND not EXISTS ( SELECT * FROM CONTACTO_DET_GESCOB c1 WITH (NOLOCK)  
       WHERE c1.cto_rut =  c.cto_rut   
        AND c1.CTD_FECREG>=c.CTD_FECREG   
        AND coalesce(c1.ctd_direccion,'') +'|'+ coalesce(CONVERT(VARCHAR(10),c1.cmn_codigo),'') +'|'+coalesce(c1.ctd_email,'')+'|'+coalesce(c1.ctd_fono,'') = coalesce(c.ctd_direccion,'') +'|'+ coalesce(CONVERT(VARCHAR(10),c.cmn_codigo),'')+ '|'+coalesce(c
.ctd_email,'')+'|'+coalesce(c.ctd_fono,'')  
        AND C1.CTD_TIPO_VAL='N' )  
   AND isnull(ctd_tipo_val, 'V')='V'  
 )  
 SELECT  
  *  
 into #email  
 FROM  
  NumeradoPorGrupo  
 WHERE  
  row_num = 1;   
  
 ------------------------------------  
  
  
 WITH NumeradoPorGrupo AS (  
  select cto_rut  
   , ctd_fono  
   ,ROW_NUMBER() OVER (PARTITION BY cto_rut ORDER BY isnull(ctd_tipo_val, 'V') desc, case when (ctd_fecreg > isnull(ctd_fecha_val, '19900101')) then ctd_fecreg  else ctd_fecha_val end desc, (case ctd_origen when 'PREVIRED' then 7  
          when 'GESCOBRANZA' then  6  
          when 'GESTION COBRANZA' then  5  
          when 'CONTRATO' then 4  
          when 'LICENCIA' then 3  
          when 'PAM' then 2  
          when 'BACK COBRANZAS' then 1  
          else 0  
          end)   
     +  
     (  
      case usu_login when 'SYSTEM' then 1  
          else 0  
          end  
      ) ) AS row_num  
   from dbo.CONTACTO_DET_GESCOB c with (nolock)  
    join #tabla_final tf on tf.rut_deudor=cto_rut  
    LEFT JOIN COMUNA CM ON C.CMN_CODIGO=CM.CMN_CODIGO  
    left join ciudad ci on ci.ciu_codigo=cm.ciu_codigo  
   WHERE ctd_fono is not null  
   AND not EXISTS ( SELECT * FROM CONTACTO_DET_GESCOB c1 WITH (NOLOCK)  
       WHERE c1.cto_rut =  c.cto_rut   
        AND c1.CTD_FECREG>=c.CTD_FECREG   
        AND coalesce(c1.ctd_direccion,'') +'|'+ coalesce(CONVERT(VARCHAR(10),c1.cmn_codigo),'') +'|'+coalesce(c1.ctd_email,'')+'|'+coalesce(c1.ctd_fono,'') = coalesce(c.ctd_direccion,'') +'|'+ coalesce(CONVERT(VARCHAR(10),c.cmn_codigo),'')+ '|'+coalesce(c
.ctd_email,'')+'|'+coalesce(c.ctd_fono,'')  
        AND C1.CTD_TIPO_VAL='N' )  
   AND isnull(ctd_tipo_val, 'V')='V'  
 )  
 SELECT  
  *  
 into #fono  
 FROM  
  NumeradoPorGrupo  
 WHERE  
  row_num = 1;   
 ------------------------------------------------------------------------  
  
 UPDATE tf  
 SET   
  monto_posible_compensar = case when ( (isnull(deuda_cotizaciones, 0) + isnull(deuda_lur, 0)) >= tu.saldo_tfu  ) then  tu.saldo_tfu else (isnull(deuda_cotizaciones, 0) + isnull(deuda_lur, 0)) end  
  , fecha_compromiso = c.fecha  
  , monto_compromiso = c.monto  
  , cobrador_asignado_lur_chq = cob_lur_chq.cob_codigo --cobrador lur chq  
  , nom_cob_lurchq = cob_lurchq.cob_nombre  
  , email_cob_lurchq = cob_lurchq.cob_email  
  , fono_cob_lurchq = cob_lurchq.cob_fono  
  , supervisor_asig = CASE WHEN @TIPODEUDACOTIZ = 'SI' THEN sup_cotiz.sco_codigo ELSE sup_lur_chq.sco_codigo END   
  , tipo_deudor = coalesce(vig.vigencia, 'EMPRESA')  
  , gestion29 = ges.gestion29  
  , compromiso_vencido = compv.fecha  
  , deuda_lur_con_credito = dlcc.deuda_lur_con_credito  
   , cob_codigo = cob_cotiz.cob_codigo      --cobrador deuda cotiz  
  , nombre_ejecutivo = cob_cotiz.cob_nombre  
  , email_ejecutivo = cob_cotiz.cob_email  
  , fono_ejecutivo = cob_cotiz.cob_fono  
  , nombre_deudor = deu.ddr_nombre      --datos deudor  
  --, email_destinatario = deu.ddr_email  
  --, fono_contacto = deu.ddr_telefono    
  , email_destinatario = em.ctd_email  
  , fono_contacto = fo.ctd_fono  
  , ciu_codigo_reside = deu.ciu_codigo  
  , edad_deudor = dbo.f_edad(benef.bnf_nacto, getdate())     
  , equipo_cobrador = CASE WHEN @TIPODEUDACOTIZ = 'SI' THEN equipo_cotiz.equipo_cobrador ELSE equipo_lurchq.equipo_cobrador END   
 from #tabla_final tf  
 left join #tfu tu with (nolock) on tf.rut_deudor = tu.rut  
 left join #compromiso c with (nolock) on tf.rut_deudor = c.rut  
 left join #cobrador_asig_lurchq cob_lur_chq with (nolock) on tf.rut_deudor = cob_lur_chq.rut  
 left join #f_supervisor_asig sup_lur_chq with (nolock) on cob_lur_chq.cob_codigo = sup_lur_chq.cob_codigo  
 left join #cobrador_asig_cotiz cob_asig_cotiz with (nolock) on cob_asig_cotiz.rut = tf.rut_deudor  
 left join #f_supervisor_asig sup_cotiz with (nolock) on sup_cotiz.cob_codigo = cob_asig_cotiz.cob_codigo  
 left join #f_vigencia_personas vig with (nolock) on tf.rut_deudor = vig.rut  
 left join #f_gestion29 ges with (nolock) on tf.rut_deudor = ges.rut  
 left join #f_compromiso_vencido compv with (nolock) on tf.rut_deudor = compv.rut  
 left join #f_deuda_lur_con_credito dlcc with (nolock) on tf.rut_deudor = dlcc.rut  
 left join deudor deu with (nolock) on tf.rut_deudor = deu.ddr_rut  
 left join cobrador cob_cotiz on cob_cotiz.cob_codigo = cob_asig_cotiz.cob_codigo  
 left join beneficiario benef with (nolock) on benef.bnf_rut = tf.rut_deudor  
 left join cobrador cob_lurchq with (nolock) on cob_lurchq.cob_codigo = cob_lur_chq.cob_codigo  
 left join #equipo_cobrador equipo_cotiz with (nolock) on equipo_cotiz.cob_codigo = cob_asig_cotiz.cob_codigo  
 left join #equipo_cobrador equipo_lurchq with (nolock) on equipo_lurchq.cob_codigo = cob_lur_chq.cob_codigo  
 left join #email em on em.cto_rut=tf.rut_deudor  
 left join #fono fo on fo.cto_rut=tf.rut_deudor  
  
 
--Traspaso de #tabla_final a #tabla_final_filtrada

declare @sqlfiltrado nvarchar(4000)  

	set @sqlfiltrado = N'
	insert into #tabla_final_filtrada
	SELECT *  
	FROM #tabla_final  
	where 1 = 1 '+@sqlwhere  
  
	BEGIN TRY  
		BEGIN TRANSACTION;  
		EXEC sp_executesql @sqlfiltrado;  
		COMMIT TRANSACTION;  
	END TRY  
	BEGIN CATCH  
		IF @@TRANCOUNT > 0  
		ROLLBACK TRANSACTION;  
  
		SELECT   
		@ErrorMessage = ERROR_MESSAGE(),  
		@ErrorSeverity = ERROR_SEVERITY(),  
		@ErrorState = ERROR_STATE();  
  
		RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);  
  
		RETURN;  
	END CATCH 
	
	create nonclustered index ix_tabla_final_filtrada_rut on #tabla_final_filtrada(rut_deudor)



----GENERAR CUPONES

--set @generar_cupones = 'S'		--prueba

IF @generar_cupones = 'S'

BEGIN


	-- Crear tabla temporal para acumular resultados con rut_deudor
	IF OBJECT_ID('tempdb..#tabla_cupones') IS NOT NULL DROP TABLE #tabla_cupones;

	CREATE TABLE #tabla_cupones (
		link VARCHAR(1000),
		cup_correl numeric(15),
		rut_deudor CHAR(10)
	);


    BEGIN TRY
        BEGIN TRANSACTION

			--insert GCO_ENVMSG_DEUDA_CUPONES
			BEGIN TRY

					INSERT INTO dbo.GCO_ENVMSG_DEUDA_CUPONES
							   (CUP_ID_BASE
							   ,COT_RUT
							   ,NOM_COTIZANTE
							   ,EPA_RUT
							   ,EPA_RAZON
							   ,DEC_PERIODO
							   ,DEC_TIPO_DEUDA
							   ,PACTADO
							   ,PAGADO
							   ,DEUDANOMINAL
							   ,REAJUSTE
							   ,INTERES
							   ,RECARGO
							   ,TOTAL_APAGAR
							   ,DESCTO_DEUDANOMINAL
							   ,DESCTO_REAJUSTE
							   ,DESCTO_INTERES
							   ,DESCTO_RECARGO)
					select
						@getdate		--(<CUP_ID_BASE, datetime,>
						, tdc.COT_RUT	--,<COT_RUT, char(10),>
						, SUBSTRING((COALESCE(rtrim(COT_NOMBRES),'') + ' '+ COALESCE(rtrim(COT_PATERNO),'') + ' '+COALESCE(rtrim(COT_MATERNO),'')), 1, 24)  -- ,<NOM_COTIZANTE, varchar(25),>
						, tdc.DEC_RUT						--   ,<EPA_RUT, char(10),>				--OBLIGATORIO EN EL OTRO SP spu_ges_cob_mensajes_generar_cupones
						, SUBSTRING(EP.EPA_RAZON, 1, 200)	--   ,<EPA_RAZON, varchar(200),>
						, tdc.DEC_PERIODO					--,<DEC_PERIODO, datetime,>
						, tdc.DEC_TIPO_DEUDA				--   ,<DEC_TIPO_DEUDA, varchar(20),>
						, 0			--   ,<PACTADO, numeric(10,0),>
						, 0			--   ,<PAGADO, numeric(10,0),>
						, tdc.DEC_DEUDA		--   ,<DEUDANOMINAL, numeric(10,0),>					--OBLIGATORIO EN EL OTRO SP spu_ges_cob_mensajes_generar_cupones
						, 0			--   ,<REAJUSTE, numeric(10,0),>
						, 0			--   ,<INTERES, numeric(10,0),>
						, 0			--   ,<RECARGO, numeric(10,0),>
						, 0			--   ,<TOTAL_APAGAR, numeric(10,0),>
						, 0			--   ,<DESCTO_DEUDANOMINAL, numeric(10,0),>
						, 0			--   ,<DESCTO_REAJUSTE, numeric(10,0),>
						, 0			--   ,<DESCTO_INTERES, numeric(10,0),>
						, 0			--   ,<DESCTO_RECARGO, numeric(10,0),>)
					FROM #TMP_DEUDA_COTIZANTE tdc
					join #tabla_final_filtrada tf on tdc.dec_rut = tf.rut_deudor
					left join dbo.cotizante ct with (nolock)  on ct.cot_rut = tdc.cot_rut
					left join dbo.entidad_pagadora ep (nolock) on ep.epa_rut = tdc.dec_rut
																and ep.epa_correl =  (select max(e.epa_correl) from dbo.entidad_pagadora e (nolock) where e.epa_rut = ep.epa_rut)

			END TRY
					BEGIN CATCH
						IF @@TRANCOUNT > 0
							ROLLBACK TRANSACTION;

							SELECT @ErrorMessage = ERROR_MESSAGE()
							RAISERROR('Fallo el INSERT en GCO_ENVMSG_DEUDA_CUPONES: %s', 16, 1, @ErrorMessage)
							RETURN
					END CATCH
			--insert GCO_ENVMSG_DEUDA_CUPONES


			BEGIN TRY
					INSERT into #tabla_cupones (link, cup_correl, rut_deudor)
					EXECUTE [MIRROR_NT].[AGENCIAS].[DBO].spu_ges_cob_mensajes_generar_cupones  @getdate;	--'2025-11-14 13:05:52.433'

					 IF NOT EXISTS (  
					   SELECT 1   
					   FROM #tabla_cupones WITH (NOLOCK)    
					 )  
					 BEGIN  
						ROLLBACK TRANSACTION;
						RAISERROR('El proceso No generó cupones.', 16, 1)  
						RETURN  
					 END

			END TRY
					BEGIN CATCH
						IF @@TRANCOUNT > 0
							ROLLBACK TRANSACTION;
							SELECT @ErrorMessage = ERROR_MESSAGE()
							RAISERROR('Fallo la generación de cupones con el SP spu_ges_cob_mensajes_generar_cupones: %s', 16, 1, @ErrorMessage)
							RETURN
					END CATCH


			BEGIN TRY
					-- Actualizar tabla filtrada con monto y URL del cupón
					UPDATE tf
					SET cup_correl = tc.cup_correl
					, url_link = tc.link
					from #tabla_final_filtrada tf
					join #tabla_cupones tc
						on tf.rut_deudor = tc.rut_deudor
			END TRY
					BEGIN CATCH
						IF @@TRANCOUNT > 0
							ROLLBACK TRANSACTION;
							SELECT @ErrorMessage = ERROR_MESSAGE()
							RAISERROR('La actualización de cup_correl y url_link falló: %s', 16, 1, @ErrorMessage)
							RETURN
					END CATCH

		COMMIT TRANSACTION;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;


        SELECT 
            @ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState = ERROR_STATE()

        --RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState)
		RAISERROR('Error proceso GENERACIÓN DE CUPONES: %s', @ErrorSeverity, @ErrorState, @ErrorMessage)
    END CATCH



END
----GENERAR CUPONES



  
 declare @sql1 nvarchar(4000)  
  
 IF @enviar = 'N'  
 BEGIN  
  
  
   set @sql1 = N'  
   SELECT rut_deudor  
     , nombre_deudor  
     , email_destinatario   
     , deuda_cotizaciones   
     , monto_cupon   
     , monto_posible_compensar   
     , cob_codigo  
     , nombre_ejecutivo   
     , email_ejecutivo   
     , fono_ejecutivo   
     , url_link   
     , url_link1   
     , url_link2  
     , fecha_compromiso   
     , monto_compromiso   
     , deuda_lur   
     , deuda_chq   
     , cobrador_asignado_lur_chq   
     , nom_cob_lurchq  
     , email_cob_lurchq  
     , fono_cob_lurchq  
     , fono_contacto   
     , supervisor_asig   
     , gestion29   
     , ciu_codigo_reside   
     , deuda_lur_con_credito   
     , edad_deudor   
     , compromiso_vencido   
     , dnp   
     , dpp   
     , ip   
     , menor_per_deuda   
     , mayor_per_deuda   
     , tipo_deudor   
     , tipo_empresa  
     , equipo_cobrador
	 , cup_correl
     FROM #tabla_final_filtrada  
     where 1 = 1 ' 
  
     BEGIN TRY  
      BEGIN TRANSACTION;  
  
      EXEC sp_executesql @sql1;  
  
      COMMIT TRANSACTION;  
     END TRY  
     BEGIN CATCH  
      IF @@TRANCOUNT > 0  
       ROLLBACK TRANSACTION;  
  
      SELECT   
       @ErrorMessage = ERROR_MESSAGE(),  
       @ErrorSeverity = ERROR_SEVERITY(),  
       @ErrorState = ERROR_STATE();  
  
      --RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState); 
	  RAISERROR('Error proceso CONSULTA PLANTILLAS: %s', @ErrorSeverity, @ErrorState, @ErrorMessage);
  
      RETURN;  
     END CATCH  
  
     -- Limpieza de tablas temporales  
     IF OBJECT_ID('tempdb..#tabla_final') IS NOT NULL DROP TABLE #tabla_final  
 END  
  
 ELSE --@enviar = 'S'  
 BEGIN  
  
   set @sql1 = N'  
    INSERT INTO dbo.GCO_ENVMSG_MENSAJE  
         (ATE_CODIGO  
         ,EME_FECHAREG  
         ,EME_FECENVIO  
         ,EME_ESTADO  
         ,RUT_DEUDOR  
         ,EME_NOMBRE_DEUDOR  
         ,EME_EMAIL_DEUDOR  
         ,EME_FONO_DEUDOR  
         ,EME_DEUDA_COTIZ  
         ,EME_DEUDA_LUR  
         ,EME_DEUDA_CHQ  
         ,COB_CODIGO  
         ,EME_DESCRIP_ENVIO  
         ,EPR_CODIGO  
         ,EPL_FECHORA
		 ,EME_LINK_CUPON
		 , cup_correl)  
     SELECT '+cast(@ATE_CODIGO as varchar(5))+' AS ATE_CODIGO  
      --, GETDATE() AS EME_FECHAREG
      , ''' + CONVERT(VARCHAR, ISNULL(@GETDATE, '19000101'), 121) + ''' AS EME_FECHAREG
      , NULL AS EME_FECENVIO  
      , 0 AS EME_ESTADO  
      , RUT_DEUDOR  
      , NOMBRE_DEUDOR AS EME_NOMBRE_DEUDOR  
      , EMAIL_DESTINATARIO AS EME_EMAIL_DEUDOR  
      , FONO_CONTACTO AS EME_FONO_DEUDOR  
      , DEUDA_COTIZACIONES AS EME_DEUDA_COTIZ  
      , DEUDA_LUR AS EME_DEUDA_LUR  
      , DEUDA_CHQ AS EME_DEUDA_CHQ  
      , CASE WHEN '''+@TIPODEUDACOTIZ+''' = ''SI'' THEN TF.COB_CODIGO ELSE TF.COBRADOR_ASIGNADO_LUR_CHQ END AS COB_CODIGO  
      , NULL  
	  , '+CAST(@epr_codigo AS VARCHAR(10))+' AS EPR_CODIGO    
      , ''' + CONVERT(VARCHAR, ISNULL(@epl_fechora, '19000101'), 121) + ''' AS EPL_FECHORA
	  , url_link
	  , cup_correl
     FROM #tabla_final_filtrada TF  
     where 1 = 1 '

	BEGIN TRY  
      BEGIN TRANSACTION;  
  
      EXEC sp_executesql @sql1;  
  
      COMMIT TRANSACTION;  
     END TRY  
     BEGIN CATCH  
      IF @@TRANCOUNT > 0  
       ROLLBACK TRANSACTION;  
  
      SELECT   
       @ErrorMessage = ERROR_MESSAGE(),  
       @ErrorSeverity = ERROR_SEVERITY(),  
       @ErrorState = ERROR_STATE();  
  
      --RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState); 
	  RAISERROR('Error proceso ENVIO PLANTILLAS: %s', @ErrorSeverity, @ErrorState, @ErrorMessage);
  
      RETURN;  
     END CATCH  
  
     -- Limpieza de tablas temporales  
     IF OBJECT_ID('tempdb..#tabla_final') IS NOT NULL DROP TABLE #tabla_final  

	 --PRUEBA
	 --SELECT * FROM dbo.GCO_ENVMSG_MENSAJE WHERE EME_FECHAREG = @GETDATE
  
 END
 
 --Borrar registros antiguos de GCO_ENVMSG_DEUDA_CUPONES
 IF @generar_cupones = 'S'
	BEGIN

		BEGIN TRY  
			BEGIN TRANSACTION;  

			DELETE DBO.GCO_ENVMSG_DEUDA_CUPONES 
			WHERE CUP_ID_BASE < DATEADD(D,-3 , GETDATE())

			COMMIT TRANSACTION;  
		END TRY  

		BEGIN CATCH
			IF @@TRANCOUNT > 0
				ROLLBACK TRANSACTION;
				SELECT @ErrorMessage = ERROR_MESSAGE()
				RAISERROR('Error en la eliminación de registros de GCO_ENVMSG_DEUDA_CUPONES: %s', 16, 1, @ErrorMessage)
				RETURN
		END CATCH

	END
  
END