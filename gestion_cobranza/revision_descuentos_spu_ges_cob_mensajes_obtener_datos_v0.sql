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
  
 modificación  : jorge molina                   
 fecha creación  : 02-02-2026                                                      
 descripción  : Se agrega #periodo_descuentos para el @TipoDeudor: VIGENTE, NOVIGENTE, EMPRESA    
                para el calculo de DESCTO_DEUDANOMINAL , DESCTO_REAJUSTE , DESCTO_INTERES , DESCTO_RECARGO  
  
  
      
========================================================================================*/      
/*       
GRANT EXECUTE ON [spu_ges_cob_mensajes_obtener_datos] TO public;      
    
--DEUDA COTIZACIONES________________________________________________________________________    
--EJ1: Plantilla:10, Filtros: Deuda cotizaciones y grupo cobrador interno , SOLO CONSULTA    
execute spu_ges_cob_mensajes_obtener_datos 1, 'N', NULL, NULL, 'N'  --5884 REG, 1,26MIN     
    
--EJ2: Plantilla:10, Filtros: Deuda cotizaciones y grupo INTERNO , OPCION ENVIAR(se necesita cod de programa:@epr_codigo y @epl_fechora de GCO_ENVMSG_PROGRAMA_LOG)    
declare @epl_fechora datetime    
declare @epr_codigo integer    
SET @epl_fechora = '20260129'    
SET @epr_codigo = 1    
--insert into GCO_ENVMSG_PROGRAMA_LOG values(@epr_codigo, @epl_fechora, null)     
execute spu_ges_cob_mensajes_obtener_datos 2, 'S', @epr_codigo, @epl_fechora, 'N'  --5884 REG, 1,26MIN     
    
REVISION EJ2: select * from GCO_ENVMSG_MENSAJE where eme_fechareg = '2025-12-05 16:08:38.790' --5884 REG OK     
    
--EJ3: Plantilla:10, Filtros: Deuda cotizaciones y grupo cobrador interno , SOLO GENERACION DE CUPONES    
execute spu_ges_cob_mensajes_obtener_datos 10, 'N', NULL, NULL, 'S'  --5884 REG, 1,35MIN con su url_link y cup_correl OK    
    
    
--DEUDA LUR________________________________________________________________________    
--EJ1: Plantilla:20, Filtros: Deuda LUR, SOLO CONSULTA    
execute spu_ges_cob_mensajes_obtener_datos 20, 'N', NULL, NULL, 'N'  --4577 REG, 1MIN     
    
--EJ2: Plantilla:20, Filtros: Deuda LUR , OPCION ENVIAR(se necesita cod de programa:@epr_codigo y @epl_fechora de GCO_ENVMSG_PROGRAMA_LOG)    
declare @epl_fechora datetime    
declare @epr_codigo integer    
SET @epl_fechora = '20251205'    
SET @epr_codigo = 2    
--hay que crear el registro GCO_ENVMSG_PROGRAMA via la aplicación    
insert into GCO_ENVMSG_PROGRAMA_LOG values(@epr_codigo, @epl_fechora, null)     
execute spu_ges_cob_mensajes_obtener_datos 20, 'S', @epr_codigo, @epl_fechora, 'N'  --4577 REG, 1,26MIN     
    
REVISION EJ2: select * from GCO_ENVMSG_MENSAJE where eme_fechareg = '2025-12-05 16:34:23.890' --4577 REG OK     
    
--EJ3: Plantilla:20, Filtros: , SOLO GENERACION DE CUPONES    
execute spu_ges_cob_mensajes_obtener_datos 2, 'N', NULL, NULL, 'S'  --4577 REG, 1,35MIN con su url_link y cup_correl OK    
    
    
    
--DEUDA CHQ________________________________________________________________________    
--EJ1: Plantilla:30, Filtros: Deuda CHQ, SOLO CONSULTA    
execute spu_ges_cob_mensajes_obtener_datos 30, 'N', NULL, NULL, 'N'  --945 REG, 20SEG     
    
--EJ2: Plantilla:30, Filtros: Deuda CHQ, OPCION ENVIAR(se necesita cod de programa:@epr_codigo y @epl_fechora de GCO_ENVMSG_PROGRAMA_LOG)    
declare @epl_fechora datetime    
declare @epr_codigo integer    
SET @epl_fechora = '20251205'    
SET @epr_codigo = 3    
--hay que crear el registro GCO_ENVMSG_PROGRAMA via la aplicación    
insert into GCO_ENVMSG_PROGRAMA_LOG values(@epr_codigo, @epl_fechora, null)     
execute spu_ges_cob_mensajes_obtener_datos 30, 'S', @epr_codigo, @epl_fechora, 'N'    
    
REVISION EJ2: select * from GCO_ENVMSG_MENSAJE where eme_fechareg = '2025-12-05 16:39:19.630' --945 REG OK     
    
--EJ3: Plantilla:30, Filtros: , SOLO GENERACION DE CUPONES    
execute spu_ges_cob_mensajes_obtener_datos 30, 'N', NULL, NULL, 'S'  --945 REG, 19SEG con su url_link y cup_correl OK    
    
*/      
      
CREATE procedure [dbo].[spu_ges_cob_mensajes_obtener_datos]       
@epl_codigo varchar(50)      
, @enviar char(1) = 'N'      
, @epr_codigo numeric(10) = null      
, @epl_fechora datetime = null      
, @generar_cupones char(1) = 'N'    
AS      
BEGIN       
 set nocount on;     
 set ansi_warnings on;    
 set ansi_nulls on;    
    
  declare @sqlwhere nvarchar(4000)      
 declare @sqlfiltro nvarchar(1000)      
 declare @codigo_concepto numeric(5, 0)      
 declare @nombre_valor nvarchar(4000)      
 declare @uf_valor numeric(8, 2)      
 declare @fecha_hoy datetime      
 declare @PrimerDiaDelMes datetime      
 declare @PrimerDiaDelMesSgte datetime      
 declare @UltDiaMesAnterior datetime      
 declare @ult_periodo_cc datetime    
 declare @TipoDeudaCOTIZ varchar(2)      
 declare @TipoDeudaLUR varchar(2)      
 declare @TipoDeudaCHQ varchar(2)      
 declare @ate_codigo numeric(5)      
 DECLARE @ErrorMessage NVARCHAR(4000), @ErrorSeverity INT, @ErrorState INT; --captura detalles para auditoría o debugging      
 declare @OPERACION varchar(300)    
 declare @TipoDeudor varchar(30) --Valores: VIGENTE, NOVIGENTE, EMPRESA    
    
declare @getdate datetime    
set @getdate = getdate()    
       
 set @fecha_hoy = cast( ( cast(getdate() as date)) as datetime)      
 select @primerdiadelmes = cast(dateadd(month, datediff(month, 0, getdate()), 0) as date)     
     
 select @primerdiadelmessgte = cast(dateadd(month, datediff(month, 0, getdate()) + 1, 0) as date)       
 set @ultdiamesanterior = dateadd(day, -1, @primerdiadelmes)      
      
 --periodo cierre contable    
 select top 1 @ult_periodo_cc =    
        case     
            when getdate() < vpc_vencimiento then     
                dateadd(month, -1, vpc_periodo)  -- antes del vencimiento: período anterior    
            else     
                vpc_periodo                       -- después del vencimiento: período original    
        end     
    from vencim_pago_cotizacion with (nolock)    
    where convert(char(6), vpc_vencimiento, 112) = convert(char(6), getdate(), 112);    
    
    
    
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
    
    
  --periodo cierre contable    
  if @ult_periodo_cc is null      
 begin       
    
  RAISERROR('No existe periodo cierre contable', 16, 1) ;    
  RETURN;      
 end      
    
    
    
      
 if @enviar = 'S'      
  begin      
    
   if @epr_codigo is null      
   begin       
      RAISERROR('Falta código de programa(@epr_codigo)', 16, 1)      
      RETURN      
   end    
   else    
   begin    
  --revisar si es codigo de programa @epr_codigo esta vinculado a la plantilla @epl_codigo    
    IF NOT EXISTS (      
     SELECT 1       
     FROM dbo.GCO_ENVMSG_PROGRAMA WITH (NOLOCK)       
     WHERE epr_codigo = @epr_codigo  and epl_codigo = @epl_codigo    
    )      
    BEGIN      
      RAISERROR('No existe registro en GCO_ENVMSG_PROGRAMA con los parámetros codigo de programa: @epr_codigo y codigo plantilla:@epl_codigo', 16, 1)      
      RETURN      
    END     
    
   end    
    
   select @ate_codigo =  ate_codigo from GCO_ENVMSG_PROGRAMA with (nolock) where epr_codigo = @epr_codigo      
      
    
    
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
    RAISERROR('No existe registro en GCO_ENVMSG_PROGRAMA_LOG con los parámetros @epr_codigo y @epl_fechora', 16, 1)      
    RETURN      
  END      
    
    
   --revisar @epr_codigo y @epl_fechora existan como registro en GCO_ENVMSG_PROGRAMA_LOG Y ESTEN VINCULADOS A LA PLANTILLA DE LA TABLA GCO_ENVMSG_PROGRAMA    
   IF NOT EXISTS (      
   SELECT 1       
   FROM dbo.GCO_ENVMSG_PROGRAMA_LOG l WITH (NOLOCK)    
   join dbo.GCO_ENVMSG_PROGRAMA p WITH (NOLOCK)    
   on l.EPR_CODIGO = p.EPR_CODIGO    
   WHERE l.epr_codigo = @epr_codigo  and l.epl_fechora = @epl_fechora and p.epl_codigo = @epl_codigo    
  )      
  BEGIN      
    RAISERROR('No existe registro en GCO_ENVMSG_PROGRAMA_LOG con los parámetros @epr_codigo y @epl_fechora vinculados con el codigo plantilla:@epl_codigo', 16, 1)      
    RETURN      
  END     
    
    
      
  end      
      
 set @sqlwhere = ''      
 set @sqlfiltro = ''      
 set @TipoDeudaCOTIZ = ''      
 set @TipoDeudaLUR = ''      
 set @TipoDeudaCHQ = ''      
 set @TipoDeudor = ''      
     
      
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
      
  --5 Tipo y Vigencia Deudor  (EXCLUYENTE)    
  --Vigente  1, No Vigente 2, Empresa  3     
      
  IF @CODIGO_CONCEPTO = 5       
  BEGIN      
   IF @NOMBRE_VALOR LIKE '%1%'      
  SET @sqlfiltro = CASE WHEN @sqlfiltro = '' THEN 'VIGENTE' ELSE @sqlfiltro + ''',''VIGENTE' END      
  SET @TipoDeudor = 'VIGENTE'    
   IF @NOMBRE_VALOR LIKE '%2%'      
  SET @sqlfiltro = CASE WHEN @sqlfiltro = '' THEN 'NO VIGENTE' ELSE @sqlfiltro + ''',''NO VIGENTE' END     
  SET @TipoDeudor = 'NOVIGENTE'    
   IF @NOMBRE_VALOR LIKE '%3%'      
  SET @sqlfiltro = CASE WHEN @sqlfiltro = '' THEN 'EMPRESA' ELSE @sqlfiltro + ''',''EMPRESA' END      
  SET @TipoDeudor = 'EMPRESA'    
      
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
    SET @sqlfiltro = CASE WHEN @sqlfiltro = '' THEN ' and menor_per_deuda >= convert(datetime, '''+CONVERT (varchar(30), dateadd(month, -6, @ult_periodo_cc) , 121 ) +''', 121)'      
           ELSE @sqlfiltro + ' and menor_per_deuda >= convert(datetime, '''+CONVERT (varchar(30), dateadd(month, -6, @ult_periodo_cc) , 121 ) +''', 121)' END      
   IF @NOMBRE_VALOR LIKE '%2%'      
    SET @sqlfiltro = CASE WHEN @sqlfiltro = '' THEN ' and menor_per_deuda >= convert(datetime, '''+CONVERT (varchar(30), dateadd(month, -5, @ult_periodo_cc) , 121 ) +''', 121)'      
           ELSE @sqlfiltro + ' and menor_per_deuda >= convert(datetime, '''+CONVERT (varchar(30), dateadd(month, -5, @ult_periodo_cc) , 121 ) +''', 121)' END      
   IF @NOMBRE_VALOR LIKE '%3%'      
    SET @sqlfiltro = CASE WHEN @sqlfiltro = '' THEN ' and menor_per_deuda >= convert(datetime, '''+CONVERT (varchar(30), dateadd(month, -4, @ult_periodo_cc) , 121 ) +''', 121)'      
           ELSE @sqlfiltro + ' and menor_per_deuda >= convert(datetime, '''+CONVERT (varchar(30), dateadd(month, -4, @ult_periodo_cc) , 121 ) +''', 121)' END      
      
   SET @sqlwhere = @sqlwhere + ' AND menor_per_deuda IS NOT NULL ' +@sqlfiltro      
  END      
      
      
  --CONCEPTO 11: Mayor periodo de deuda      
  -- Marcelo: Mayor periodo de deuda: hasta 4, Hasta 3, Hasta 2      
  IF @CODIGO_CONCEPTO = 11      
  BEGIN      
   IF @NOMBRE_VALOR LIKE '%1%'      
    SET @sqlfiltro = CASE WHEN @sqlfiltro = '' THEN ' and mayor_per_deuda >= convert(datetime, '''+CONVERT (varchar(30), dateadd(month, -4, @ult_periodo_cc) , 121 ) +''', 121)'      
           ELSE @sqlfiltro + ' and mayor_per_deuda >= convert(datetime, '''+CONVERT (varchar(30), dateadd(month, -4, @ult_periodo_cc) , 121 ) +''', 121)' END      
   IF @NOMBRE_VALOR LIKE '%2%'      
    SET @sqlfiltro = CASE WHEN @sqlfiltro = '' THEN ' and mayor_per_deuda >= convert(datetime, '''+CONVERT (varchar(30), dateadd(month, -3, @ult_periodo_cc) , 121 ) +''', 121)'      
           ELSE @sqlfiltro + ' and mayor_per_deuda >= convert(datetime, '''+CONVERT (varchar(30), dateadd(month, -3, @ult_periodo_cc) , 121 ) +''', 121)' END      
   IF @NOMBRE_VALOR LIKE '%3%'      
    SET @sqlfiltro = CASE WHEN @sqlfiltro = '' THEN ' and mayor_per_deuda >= convert(datetime, '''+CONVERT (varchar(30), dateadd(month, -2, @ult_periodo_cc) , 121 ) +''', 121)'      
           ELSE @sqlfiltro + ' and mayor_per_deuda >= convert(datetime, '''+CONVERT (varchar(30), dateadd(month, -2, @ult_periodo_cc) , 121 ) +''', 121)' END      
      
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
      
 ------prueba_      
 --PRINT 'WHERE:_'+@sqlwhere+'_'      
 --PRINT 'TipoDeudaCOTIZ:_'+@TipoDeudaCOTIZ+'_'      
 --PRINT 'TipoDeudaLUR:_'+@TipoDeudaLUR+'_'      
 --PRINT 'TipoDeudaCHQ:_'+@TipoDeudaCHQ+'_'      
 ----set @sqlwhere = ''      
 ------prueba_      
      
 -- Validar que @sqlwhere no esté vacío o malformado      
 -- SI NO EXISTE WHERE NO SE PODRA EJECUTAR EL PROCESO      
 IF @sqlwhere IS NULL OR @sqlwhere = ''      
 BEGIN      
  RAISERROR('No existe filtros @sqlwhere en la plantilla: %s', 16, 1, @epl_codigo)      
  RETURN      
 END      
    
 --VALIDACIONES DE LOS FILTROS    
    
 IF @TipoDeudaCOTIZ = '' and @TipoDeudaLUR = '' and @TipoDeudaCHQ = ''      
 BEGIN      
  RAISERROR('Falta Tipo de Deuda en la plantilla: %s', 16, 1, @epl_codigo)      
  RETURN      
 END     
    
--@TipoDeudor --Valores: VIGENTE, NOVIGENTE, EMPRESA    
 IF @TipoDeudor = ''       
 BEGIN      
  RAISERROR('Falta Tipo Deudor en la plantilla: VIGENTE, NOVIGENTE ó EMPRESA', 16, 1)      
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
  , tipo_deudor varchar(30) null  --Valores: VIGENTE, NO VIGENTE, EMPRESA    
  , tipo_empresa varchar(30) null  --Valores: COTIZANTE, EMPRESA    
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
 , REAJUSTE numeric(15,4) null    
 , INTERES numeric(15,4) null    
 , RECARGO numeric(15,4) null    
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
     , ROUND((CASE WHEN (INTERESES.INT_REAJUSTE < 0) OR (INTERESES.INT_REAJUSTE IS NULL) THEN 0 ELSE INTERESES.INT_REAJUSTE END) / 100 * ((coalesce(DEC_PACTADO,0) - coalesce(DEC_PAGADO,0)) - coalesce(deuda_empleador,0)), 0)    
     , ROUND((CASE WHEN (INTERESES.INT_INTERES  < 0) OR (INTERESES.INT_INTERES IS NULL ) THEN 0 ELSE INTERESES.INT_INTERES  END) / 100 * ((coalesce(DEC_PACTADO,0) - coalesce(DEC_PAGADO,0)) - coalesce(deuda_empleador,0)), 0)    
     , ROUND((CASE WHEN (INTERESES.INT_RECARGO < 0)  OR (INTERESES.INT_RECARGO IS NULL)  THEN 0 ELSE INTERESES.INT_RECARGO END)  / 100 * ((coalesce(DEC_PACTADO,0) - coalesce(DEC_PAGADO,0)) - coalesce(deuda_empleador,0)), 0)      
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
    
    
 create table #TMP_DEUDA_FINANCIERA      
 (    
 ID_DEUDA numeric(10) not null    
 , RUT_DEUDOR char(10) not null      
 , NOMBRE_DEUDOR char(250) null     
 , TDE_CODIGO numeric(2) null    
 , TIPO_DEUDA varCHAR(50)  null    
 , FOLIO_DOCUMENTO char(50) null    
 , FECHA_DEUDA datetime null    
 , FECHA_COBRO datetime null    
 , MONTO_DEUDA numeric(10) null    
 , MONTO_PAGADO numeric(10) null     
 , SALDO numeric(10) null    
 , CANT_CUOTAS numeric(5) null    
 , FECHA_ULT_PAGO datetime null    
 , FECHA_ULT_GEST datetime null    
 , DDR_TELEFONO char(50) null    
 , DDR_CELULAR varchar(50) null    
 , DDR_EMAIL varchar(50) null      
 )    
    
 --V1    
 IF @TipoDeudaLUR = 'SI' OR @TipoDeudaCHQ = 'SI'      
 BEGIN      
    
    INSERT #TMP_DEUDA_FINANCIERA    
    SELECT   DISTINCT GD.DEU_CORREL AS ID_DEUDA    
                         ,GD.DDR_RUT   AS RUT_DEUDOR    
                         ,D.DDR_NOMBRE AS NOMBRE_DEUDOR    
                         ,TD.TDE_CODIGO    
                         ,TD.TDE_DESCRIPCION AS TIPO_DEUDA    
                         ,cast(ltrim(rtrim(GD.DEU_FOLIODOC)) as varchar(50)) AS FOLIO_DOCUMENTO    
                         ,GD.DEU_FECHA AS FECHA_DEUDA    
                         ,GD.DEU_FECCOBRO AS FECHA_COBRO    
                         ,GD.DEU_MONTO AS MONTO_DEUDA    
                         ,(SELECT COALESCE(SUM(PD.PAD_MONTO),0) FROM GCDF_PAGO_DEUDA PD with (NOLOCK) WHERE PD.DEU_CORREL = GD.DEU_CORREL) AS MONTO_PAGADO    
                         ,(COALESCE(GD.DEU_MONTO,0) - (SELECT COALESCE(SUM(PD.PAD_MONTO ),0) FROM GCDF_PAGO_DEUDA PD with (NOLOCK) WHERE PD.DEU_CORREL = GD.DEU_CORREL) ) AS SALDO    
                         ,GD.DEU_CUOTAS as CANT_CUOTAS    
                         ,(SELECT MAX(PAD_FECHA) FROM GCDF_PAGO_DEUDA with (NOLOCK) WHERE DEU_CORREL=GD.DEU_CORREL) AS FECHA_ULT_PAGO    
                         ,(SELECT MAX(GEC_FECHA_GES) FROM GESTION_COBRANZA with (NOLOCK) WHERE DDR_RUT=GD.DDR_RUT AND TGC_CODIGO IN (80,90)) AS FECHA_ULT_GEST    
                         ,D.DDR_TELEFONO    
                         ,D.DDR_CELULAR    
                         ,D.DDR_EMAIL    
    FROM GCDF_DEUDA GD with (NOLOCK)    
           LEFT JOIN DEUDOR D with (NOLOCK) ON GD.DDR_RUT = D.DDR_RUT    
           LEFT JOIN GCDF_TIPO_DEUDA TD with (NOLOCK) ON GD.TDE_CODIGO = TD.TDE_CODIGO        
           LEFT JOIN GCDF_DEUDOR_ASIGNADO DA on DA.DDR_RUT=GD.DDR_RUT AND DA.DEU_ASIG_DESDE <= GETDATE() AND (DA.DEU_ASIG_HASTA >= CONVERT(CHAR(8),GETDATE(),112) OR DA.DEU_ASIG_HASTA IS NULL)    
    
    CREATE INDEX ix_TMP_DEUDA_FINANCIERA ON #TMP_DEUDA_FINANCIERA(RUT_DEUDOR)      
      
   INSERT #origen_lur_chq      
   select      
     RUT_DEUDOR as rut      
     , case when @TipoDeudaLUR = 'SI' then sum(case when TDE_CODIGO = 1 then SALDO else 0 end) else null end as deuda_lur     
     , case when @TipoDeudaCHQ = 'SI' then sum(case when TDE_CODIGO = 2 then SALDO else 0 end) else null end as deuda_chq        
   from #TMP_DEUDA_FINANCIERA gd with (nolock)      
   where SALDO > 0      
   and TDE_CODIGO in (1, 2)      
   group by RUT_DEUDOR     
       
     if @TipoDeudaLUR = 'SI'      
     begin     
            delete #origen_lur_chq where deuda_lur = 0     
     end    
    
     if @TipoDeudaCHQ = 'SI'      
     begin     
            delete #origen_lur_chq where deuda_chq = 0     
     end    
    
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
     
 IF @@ROWCOUNT = 0    
BEGIN      
   -- ROLLBACK TRANSACTION;    
    RAISERROR('Proceso detenido por falta de registros en #tabla_final .', 16, 1);      
    RETURN;      
END    
      
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
 , COALESCE(( case when coalesce(deuda_cob.cob_judicial,'N') = 'S' then 'JUDICIAL' else NULL end ), (case when coalesce(cob_dep.cob_codigo,0) = 9000 then 'STOCK' else NULL end), (case when coalesce(cob_dep.cob_codigo,0) = 9002 then 'INTERNO' else NULL en
d    
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
        AND coalesce(c1.ctd_direccion,'') +'|'+ coalesce(CONVERT(VARCHAR(10),c1.cmn_codigo),'') +'|'+coalesce(c1.ctd_email,'')+'|'+coalesce(c1.ctd_fono,'') = coalesce(c.ctd_direccion,'') +'|'+ coalesce(CONVERT(VARCHAR(10),c.cmn_codigo),'')+ '|'+coalesce(
c  
    
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
  monto_posible_compensar = case when ( (isnull(deuda_cotizaciones, 0) + isnull(deuda_lur, 0)) >= coalesce(tu.saldo_tfu,0)   ) then  coalesce(tu.saldo_tfu,0)  else (isnull(deuda_cotizaciones, 0) + isnull(deuda_lur, 0)) end      
  , fecha_compromiso = c.fecha      
  , monto_compromiso = c.monto      
  , cobrador_asignado_lur_chq = cob_lur_chq.cob_codigo --cobrador lur chq      
  , nom_cob_lurchq = cob_lurchq.cob_nombre      
  , email_cob_lurchq = cob_lurchq.cob_email      
  , fono_cob_lurchq = cob_lurchq.cob_fono      
  , supervisor_asig = CASE WHEN @TIPODEUDACOTIZ = 'SI' THEN sup_cotiz.sco_codigo ELSE sup_lur_chq.sco_codigo END       
  , tipo_deudor = coalesce(vig.vigencia, 'EMPRESA')      
  , gestion29 = coalesce(ges.gestion29,'No')      
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
  --BEGIN TRANSACTION;      
    
  set @OPERACION = 'EXEC sp_executesql @sqlfiltrado'    
  EXEC sp_executesql @sqlfiltrado;      
    
  IF @@ROWCOUNT = 0    
  BEGIN      
   ROLLBACK TRANSACTION;    
   RAISERROR('Proceso detenido por falta de registros en #tabla_final_filtrada.', 16, 1);      
   RETURN;      
  END    
    
    
  --COMMIT TRANSACTION;      
 END TRY      
 BEGIN CATCH      
  --IF @@TRANCOUNT > 0      
  --ROLLBACK TRANSACTION;      
      
  SELECT       
  @ErrorMessage = ERROR_MESSAGE(),      
  @ErrorSeverity = ERROR_SEVERITY(),      
  @ErrorState = ERROR_STATE();      
      
  --RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);      
    
   DECLARE    
    @ErrorNumber    INT = ERROR_NUMBER(),    -- Captura el código numérico del error (ej: 8134 para división por cero) .    
    --@ErrorSeverity  INT = ERROR_SEVERITY(),    -- Guarda la gravedad del error (10-25, donde 16+ son errores de usuario).    
    --@ErrorState     INT = ERROR_STATE(),    -- Registra el estado interno del error (diferencia variantes del mismo error).    
    @ErrorProcedure NVARCHAR(128) = ERROR_PROCEDURE(), -- Nombre del SP, trigger o función donde falló la sentencia.    
    @ErrorLine      INT = ERROR_LINE(),     -- Número exacto de línea donde ocurrió el error en el código    
   -- @ErrorMessage   NVARCHAR(4000) = ERROR_MESSAGE(), -- Texto completo del mensaje de error con detalles (columnas, valores, etc.)    
    @MensajeFinal   NVARCHAR(4000)    
    
   SET @MensajeFinal = 'Error Proceso: ' + ISNULL(@OPERACION, '') +     
                   ' . Nº: ' + CAST(@ErrorNumber AS VARCHAR(10)) +     
                   ', Sp_trigger_funcion: ' + ISNULL(@ErrorProcedure, '') +     
                   ', Línea: ' + CAST(@ErrorLine AS VARCHAR(10)) +    
       ', Línea: ' + ISNULL(@ErrorProcedure, '') +    
                   ', Detalle error: ' + ISNULL(@ErrorMessage, '');    
    
   RAISERROR(@MensajeFinal, 16, 1);    
    
      
  RETURN;     
 END CATCH     
     
 create nonclustered index ix_tabla_final_filtrada_rut on #tabla_final_filtrada(rut_deudor)    
    
    
---------------------------------------------------------------------------------------------------------------    
---------------------------------------------------------------------------------------------------------------    
----GENERAR CUPONES    
    
--set @generar_cupones = 'N'  --Marcha Blanca    
    
IF @generar_cupones = 'S'    
    
BEGIN    
    
 -- Crear tabla temporal para acumular resultados con rut_deudor    
 IF OBJECT_ID('tempdb..#tabla_cupones') IS NOT NULL DROP TABLE #tabla_cupones;    
    
 CREATE TABLE #tabla_cupones (    
  link VARCHAR(1000),    
  cup_correl numeric(15),    
  rut_deudor CHAR(10)    
 );    
    
    IF @TipoDeudaCOTIZ = 'SI'       
    BEGIN    
    
            BEGIN TRY    
                --BEGIN TRANSACTION    
    
           --insert GCO_ENVMSG_DEUDA_CUPONES    
           BEGIN TRY    
    
    
       select distinct tdc.DEC_PERIODO as periodo, cast(null as numeric(10)) DESCTO_DEUDANOMINAL, cast(null as numeric(10)) DESCTO_REAJUSTE, cast(null as numeric(10)) DESCTO_INTERES, cast(null as numeric(10)) DESCTO_RECARGO    
       into #periodo_descuentos    
       FROM #TMP_DEUDA_COTIZANTE tdc    
       join #tabla_final_filtrada tf on tdc.dec_rut = tf.rut_deudor    
    
       --@TipoDeudor --Valores: VIGENTE, NOVIGENTE, EMPRESA    
        IF @TipoDeudor = 'VIGENTE'       
        BEGIN      
    
         update #periodo_descuentos     
         set DESCTO_DEUDANOMINAL = g.GCD_PORC_DEUDA    
         , DESCTO_REAJUSTE = g.GCD_PORC_REAJ    
         , DESCTO_INTERES = g.GCD_PORC_INT    
         , DESCTO_RECARGO = g.GCD_PORC_REC    
         from GCO_DCTO_DEUDATOT g    
          where GCD_TIPODEUDOR = 'V'    
           AND GCD_MESES_DESDE <= dbo.f_cob_antiguedad_deuda (#periodo_descuentos.periodo, getdate())    
           AND ( GCD_MESES_HASTA >= dbo.f_cob_antiguedad_deuda (#periodo_descuentos.periodo, getdate()) OR GCD_MESES_HASTA IS NULL)    
    
        END    
            
        IF @TipoDeudor = 'NOVIGENTE'       
        BEGIN      
         update #periodo_descuentos     
         set DESCTO_DEUDANOMINAL = g.GCD_PORC_DEUDA    
         , DESCTO_REAJUSTE = g.GCD_PORC_REAJ    
         , DESCTO_INTERES = g.GCD_PORC_INT    
         , DESCTO_RECARGO = g.GCD_PORC_REC    
         from GCO_DCTO_DEUDATOT g    
          where GCD_TIPODEUDOR = 'N'    
           AND GCD_MESES_DESDE <= dbo.f_cob_antiguedad_deuda (#periodo_descuentos.periodo, getdate())    
           AND ( GCD_MESES_HASTA >= dbo.f_cob_antiguedad_deuda (#periodo_descuentos.periodo, getdate()) OR GCD_MESES_HASTA IS NULL)    
    
        END     
    
        IF @TipoDeudor = 'EMPRESA'       
        BEGIN      
         update #periodo_descuentos     
         set DESCTO_DEUDANOMINAL = g.GCD_PORC_DEUDA    
         , DESCTO_REAJUSTE = g.GCD_PORC_REAJ    
         , DESCTO_INTERES = g.GCD_PORC_INT    
         , DESCTO_RECARGO = g.GCD_PORC_REC    
         from GCO_DCTO_DEUDATOT g    
          where GCD_TIPODEUDOR = 'E'    
           AND GCD_MESES_DESDE <= dbo.f_cob_antiguedad_deuda (#periodo_descuentos.periodo, getdate())    
           AND ( GCD_MESES_HASTA >= dbo.f_cob_antiguedad_deuda (#periodo_descuentos.periodo, getdate()) OR GCD_MESES_HASTA IS NULL)    
     
        END     
    
        -- select * from #periodo_descuentos    
    
    
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
              @getdate  --(<CUP_ID_BASE, datetime,>    
              , tdc.COT_RUT --,<COT_RUT, char(10),>    
              , SUBSTRING((COALESCE(rtrim(COT_NOMBRES),'') + ' '+ COALESCE(rtrim(COT_PATERNO),'') + ' '+COALESCE(rtrim(COT_MATERNO),'')), 1, 24)  -- ,<NOM_COTIZANTE, varchar(25),>    
              , tdc.DEC_RUT      --   ,<EPA_RUT, char(10),>    --OBLIGATORIO EN EL OTRO SP spu_ges_cob_mensajes_generar_cupones    
              , SUBSTRING(EP.EPA_RAZON, 1, 200) --   ,<EPA_RAZON, varchar(200),>    
              , tdc.DEC_PERIODO     --,<DEC_PERIODO, datetime,>    
              , tdc.DEC_TIPO_DEUDA    --   ,<DEC_TIPO_DEUDA, varchar(20),>    
              , 0   --   ,<PACTADO, numeric(10,0),>    
              , 0   --   ,<PAGADO, numeric(10,0),>    
              , tdc.DEC_DEUDA  --   ,<DEUDANOMINAL, numeric(10,0),>     --OBLIGATORIO EN EL OTRO SP spu_ges_cob_mensajes_generar_cupones    
              , tdc.REAJUSTE   --   ,<REAJUSTE, numeric(10,0),>    
              , tdc.INTERES   --   ,<INTERES, numeric(10,0),>    
              , tdc.RECARGO   --   ,<RECARGO, numeric(10,0),>    
              , tdc.DEC_DEUDA + coalesce(tdc.REAJUSTE,0) + coalesce(tdc.INTERES,0) + coalesce(tdc.RECARGO,0)  --   ,<TOTAL_APAGAR, numeric(10,0),>    
              , CONVERT(NUMERIC(15),tdc.DEC_DEUDA * pd.DESCTO_DEUDANOMINAL / 100)   --MODIFICAR CON EL ALIAS DE LA TABLA DE DESCUENTOS    
              , CONVERT(NUMERIC(15),tdc.DEC_DEUDA * pd.DESCTO_REAJUSTE / 100)   --   ,<DESCTO_REAJUSTE, numeric(10,0),>    
              , CONVERT(NUMERIC(15),tdc.DEC_DEUDA * pd.DESCTO_INTERES / 100)   --   ,<DESCTO_INTERES, numeric(10,0),>    
              , CONVERT(NUMERIC(15),tdc.DEC_DEUDA * pd.DESCTO_RECARGO / 100)   --   ,<DESCTO_INTERES, numeric(10,0),>)    
             FROM #TMP_DEUDA_COTIZANTE tdc    
             join #tabla_final_filtrada tf on tdc.dec_rut = tf.rut_deudor    
             left join #periodo_descuentos pd on tdc.DEC_PERIODO = pd.periodo    
             left join dbo.cotizante ct with (nolock)  on ct.cot_rut = tdc.cot_rut    
             left join dbo.entidad_pagadora ep (nolock) on ep.epa_rut = tdc.dec_rut    
                        and ep.epa_correl =  (select max(e.epa_correl) from dbo.entidad_pagadora e (nolock) where e.epa_rut = ep.epa_rut)    
       where tdc.DEC_DEUDA > 0 --reforzar    
    
    
                            -- Nuevo Validar que se hayan insertado filas    
                            IF @@ROWCOUNT = 0    
                            BEGIN    
                                --IF @@TRANCOUNT > 0    
                                   -- ROLLBACK TRANSACTION;    
    
                                RAISERROR('No se insertó ningún registro en GCO_ENVMSG_DEUDA_CUPONES.', 16, 1);    
                                RETURN;    
                            END    
    
           END TRY    
             BEGIN CATCH    
              IF @@TRANCOUNT > 0    
               ROLLBACK TRANSACTION;    
    
               SELECT @ErrorMessage = ERROR_MESSAGE()    
               RAISERROR('Fallo el INSERT en GCO_ENVMSG_DEUDA_CUPONES: %s', 16, 1, @ErrorMessage)    
               RETURN    
             END CATCH    
    
    
    
             EXECUTE [MIRROR_NT].[AGENCIAS].[DBO].spu_ges_cob_mensajes_generar_cupones  @getdate; --'2025-11-14 13:05:52.433'    
    
       INSERT into #tabla_cupones (link, cup_correl, rut_deudor)    
       SELECT link, cup_correl, rut_deudor FROM [MIRROR_NT].[AGENCIAS].[DBO].GESCOB_MSG_TMP_TABLA_CUPONES WHERE ID=@getdate    
    
    
        IF (select count(*) from #tabla_cupones) = 0    
              BEGIN      
              RAISERROR('El proceso No generó cupones.', 16, 1)      
              RETURN      
              END    
        ELSE    
        DELETE FROM [MIRROR_NT].[AGENCIAS].[DBO].GESCOB_MSG_TMP_TABLA_CUPONES WHERE ID=@getdate    
    
    
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
              -- ROLLBACK TRANSACTION;    
               SELECT @ErrorMessage = ERROR_MESSAGE()    
               RAISERROR('La actualización de cup_correl y url_link falló: %s', 16, 1, @ErrorMessage)    
               RETURN    
             END CATCH    
    
         -- COMMIT TRANSACTION;    
    
            END TRY    
            BEGIN CATCH    
                IF @@TRANCOUNT > 0    
                   ROLLBACK TRANSACTION;    
    
    
                SELECT     
                    @ErrorMessage = ERROR_MESSAGE(),    
                    @ErrorSeverity = ERROR_SEVERITY(),    
                    @ErrorState = ERROR_STATE()    
    
                --RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState)    
          RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState)    
    RETURN    
            END CATCH    
    
    END     --IF @TipoDeudaCOTIZ = 'SI'    
    
    
    IF @TipoDeudaLUR = 'SI' OR @TipoDeudaCHQ = 'SI'       
    BEGIN    
    
            BEGIN TRY    
                --BEGIN TRANSACTION    
    
           --insert GCO_ENVMSG_DEUDA_CUPONES_DEUFIN    
           BEGIN TRY    
       --Tabla de paso     
             INSERT INTO dbo.GCO_ENVMSG_DEUDA_CUPONES_DEUFIN    
                  (CUP_ID_BASE    
                  ,COT_RUT    
                  ,NOM_DEUDOR      --VARCHAR(200) NULL       
                  ,DEU_CORREL      --NUMERIC(15) NULL     
                  ,DEU_MONTO       --NUMERIC(15) NULL -- MONTO_DEUDA    
                  ,DEU_DESCUENTO   --NUMERIC(15) NULL     
                                       )    
             select    
              @getdate      
              , tdf.RUT_DEUDOR     
              , SUBSTRING((COALESCE(rtrim(COT_NOMBRES),'') + ' '+ COALESCE(rtrim(COT_PATERNO),'') + ' '+COALESCE(rtrim(COT_MATERNO),'')), 1, 200)      
              , tdf.ID_DEUDA      
              , tdf.MONTO_DEUDA     
              , 0  -- Marcelo: 0 por el momento    
             FROM #TMP_DEUDA_FINANCIERA tdf    
             join #tabla_final_filtrada tf on tdf.RUT_DEUDOR = tf.rut_deudor    
             left join dbo.cotizante ct with (nolock)  on ct.cot_rut = tdf.RUT_DEUDOR    
    
    
                            -- Nuevo Validar que se hayan insertado filas    
                            IF @@ROWCOUNT = 0    
                            BEGIN    
                                --IF @@TRANCOUNT > 0    
                                -- -   ROLLBACK TRANSACTION;    
    
                                RAISERROR('No se insertó ningún registro en GCO_ENVMSG_DEUDA_CUPONES_DEUFIN.', 16, 1);    
                                RETURN;    
                            END    
    
           END TRY    
             BEGIN CATCH    
              --IF @@TRANCOUNT > 0    
             --  ROLLBACK TRANSACTION;    
    
               SELECT @ErrorMessage = ERROR_MESSAGE()    
               RAISERROR('Fallo el INSERT en GCO_ENVMSG_DEUDA_CUPONES_DEUFIN: %s', 16, 1, @ErrorMessage)    
               RETURN    
             END CATCH    
           --insert GCO_ENVMSG_DEUDA_CUPONES_DEUFIN    
    
    
    
    
           BEGIN TRY    
    
    
             EXECUTE [MIRROR_NT].[AGENCIAS].[DBO].spu_ges_cob_mensajes_generar_cupones_deufin  @getdate; --'2025-11-14 13:05:52.433'    
    
       INSERT into #tabla_cupones (link, cup_correl, rut_deudor)    
       SELECT link, cup_correl, rut_deudor FROM [MIRROR_NT].[AGENCIAS].[DBO].GESCOB_MSG_TMP_TABLA_CUPONES WHERE ID=@getdate    
    
    
        IF (select count(*) from #tabla_cupones) = 0    
              BEGIN      
              RAISERROR('El proceso No generó cupones.', 16, 1)      
              RETURN      
              END    
        ELSE    
        DELETE FROM [MIRROR_NT].[AGENCIAS].[DBO].GESCOB_MSG_TMP_TABLA_CUPONES WHERE ID=@getdate    
    
    
           END TRY    
             BEGIN CATCH    
              --IF @@TRANCOUNT > 0    
             --  ROLLBACK TRANSACTION;    
               SELECT @ErrorMessage = ERROR_MESSAGE()    
               RAISERROR('Fallo la generación de cupones con el SP spu_ges_cob_mensajes_generar_cupones_deufin: %s', 16, 1, @ErrorMessage)    
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
              --IF @@TRANCOUNT > 0    
              -- ROLLBACK TRANSACTION;    
               SELECT @ErrorMessage = ERROR_MESSAGE()    
               RAISERROR('DEUDA FINANCIERA: La actualización de cup_correl y url_link falló: %s', 16, 1, @ErrorMessage)    
               RETURN    
             END CATCH    
    
          --COMMIT TRANSACTION;    
                                END TRY    
            BEGIN CATCH    
                --IF @@TRANCOUNT > 0    
                   -- ROLLBACK TRANSACTION;    
    
                SELECT     
                    @ErrorMessage = ERROR_MESSAGE(),    
                    @ErrorSeverity = ERROR_SEVERITY(),    
                    @ErrorState = ERROR_STATE()    
    
                --RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState)    
          RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState)    
    RETURN    
            END CATCH    
    
    END     --IF @TipoDeudaCOTIZ = 'SI'    
    
END    
----GENERAR CUPONES    
---------------------------------------------------------------------------------------------------------------    
---------------------------------------------------------------------------------------------------------------    
    
    
      
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
     , substring(url_link,1,37) as url_link      
     , substring(url_link,38,48) as url_link1      
  , substring(url_link,86,1000) as url_link2    
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
      --BEGIN TRANSACTION;      
      
      EXEC sp_executesql @sql1;      
      
      --COMMIT TRANSACTION;      
     END TRY      
     BEGIN CATCH      
      --IF @@TRANCOUNT > 0      
       --ROLLBACK TRANSACTION;      
      
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
      --BEGIN TRANSACTION;      
      
      EXEC sp_executesql @sql1;      
      
      --COMMIT TRANSACTION;      
     END TRY      
     BEGIN CATCH      
      --IF @@TRANCOUNT > 0      
       --ROLLBACK TRANSACTION;      
      
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
     
 --Borrar registros antiguos de GCO_ENVMSG_DEUDA_CUPONES y GCO_ENVMSG_DEUDA_CUPONES_DEUFIN    
 IF @generar_cupones = 'S'    
 BEGIN    
    
  BEGIN TRY      
   --BEGIN TRANSACTION;      
    
   IF @TipoDeudaCOTIZ = 'SI'       
   BEGIN    
    DELETE DBO.GCO_ENVMSG_DEUDA_CUPONES     
    WHERE CUP_ID_BASE < DATEADD(D,-30 , GETDATE())    
   END    
    
   IF @TipoDeudaLUR = 'SI' OR @TipoDeudaCHQ = 'SI'       
   BEGIN    
    DELETE DBO.GCO_ENVMSG_DEUDA_CUPONES_DEUFIN     
    WHERE CUP_ID_BASE < DATEADD(D,-30 , GETDATE())    
   END    
    
   --COMMIT TRANSACTION;      
  END TRY      
    
  BEGIN CATCH    
   --IF @@TRANCOUNT > 0    
    --ROLLBACK TRANSACTION;    
    SELECT @ErrorMessage = ERROR_MESSAGE()    
    RAISERROR('Error en la eliminación de registros de GCO_ENVMSG_DEUDA_CUPONES(_DEUFIN): %s', 16, 1, @ErrorMessage)    
    RETURN    
  END CATCH    
    
 END    
      
END 