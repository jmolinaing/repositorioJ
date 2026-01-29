  
/* =======================================================================================
    Tipo de Objeto  : Procedimiento Almacenado             
    Nombre Objeto   : spu_ges_cob_cju_ges_deuda             
    Parmetros       : @p_cod_cob : codigo de cobrador judicial, ->0 para anular filtro 
                    : @p_ind_rjud: indicador de exclusión de deudores sin resolución     
                       judicial, ->S Excluye ->N no excluye        
    Sistema         : PB10 Gestion Cobranza             
    Destino         : BD ISAPRE                  
    Creado por      : Proveedor Externo Aligare - Pablo Melo         
    Fecha Creacin   : 12-04-2022                
    Descripcion     : Obtiene deudores en cobranza judicial a quienes se puede     
                      generar resoluciones nuevas o complementarias.     
                        
    Modificado      : Jorge Molina <jorge.molina@nuevamasvida.cl>
    fecha           : 23-01-2026
    Descripción     : Req_#17333 
					  Se agrega 3 parámetros @excluir_mediatica, @excluir_quiebra, @excluir_venta
                      Se agrega 5 columnas en la salida:
                      	1.- Empresa Mediatica (X)
	                    2.- Empresa En Quiebra (X)
	                    3.- Ventas Cuestionadas (X)	
	                    4.- Fecha último pago (La mayor fecha entre COTIZACION_PAGADA y PLANILLA, buscando por EPA_RUT)
	                    5.- Deuda ultimos 5 años (excluir deuda con RJ y ventas cuentionadas. Además considerar sólo 60 meses desde el ultimo contable cerrado)

 =======================================================================================*/  
  
-- spu_ges_cob_cju_ges_deuda 27,S  
-- spu_ges_cob_cju_ges_deuda 27,N  
-- spu_ges_cob_cju_ges_deuda 0,S  
-- spu_ges_cob_cju_ges_deuda 0,N  

--execute spu_ges_cob_cju_ges_deuda null, 'S', 's', 'N', 's'
  
alter PROCEDURE [dbo].[spu_ges_cob_cju_ges_deuda] @p_cod_cob numeric(4), @p_ind_rjud char(1)  , @excluir_mediatica char(1) = null, @excluir_quiebra char(1) = null, @excluir_venta char(1) = null
AS  
BEGIN   
 SET NOCOUNT ON;  


	--Req_#17333 =======================================================================================
	declare @ult_periodo_cc datetime 

    --Periodo Contable cerrado v1
	--select @ult_periodo_cc = par_finvig from parametros where par_codigo='ucc'

    --Periodo Contable cerrado v2
    --Con esta consulta se obtiene el vencimiento actual:

    select top 1 @ult_periodo_cc =
        case 
            when getdate() < vpc_vencimiento then 
                dateadd(month, -1, vpc_periodo)  -- antes del vencimiento: período anterior
            else 
                vpc_periodo                       -- después del vencimiento: período original
        end 
    from vencim_pago_cotizacion with (nolock)
    where convert(char(6), vpc_vencimiento, 112) = convert(char(6), getdate(), 112);


     if (@ult_periodo_cc is null)
     begin
          RAISERROR('No existe periodo contable cerrado.', 16, 1)    
          RETURN  
     end

     set @ult_periodo_cc = dateadd(m, -60,  @ult_periodo_cc)  

    IF OBJECT_ID('tempdb..#afiliado_vta_cuestionada') IS NOT NULL DROP TABLE #afiliado_vta_cuestionada;
    IF OBJECT_ID('tempdb..#deuda5_total') IS NOT NULL DROP TABLE #deuda5_total;
    IF OBJECT_ID('tempdb..#deuda_rj') IS NOT NULL DROP TABLE #deuda_rj;
    IF OBJECT_ID('tempdb..#deuda5_sin_rj') IS NOT NULL DROP TABLE #deuda5_sin_rj;
    IF OBJECT_ID('tempdb..#deuda5_filtrada') IS NOT NULL DROP TABLE #deuda5_filtrada;
    
    --Listado afiliados con ventas cuestionadas
    SELECT distinct c.cot_rut
    into #afiliado_vta_cuestionada
    FROM dbo.contrato c WITH (NOLOCK)   
    JOIN dbo.fun f WITH (NOLOCK) 
        ON f.con_folio = c.con_folio    
    JOIN dbo.Gescob_ejecutivo_cuestionado g WITH (NOLOCK)
        ON g.eje_rut = f.eje_rut
    WHERE f.fun_tipo LIKE '%1%'
        AND c.con_ultimo = 'S'

    --Deuda Total 5 años, SIN ventas cuestionadas
	SELECT DEC_RUT, DEC_PERIODO, dc.COT_RUT, DEC_PACTADO - DEC_PAGADO AS DEUDA 
    into #deuda5_total
    FROM DEUDA_COTIZANTE dc with (nolock)
    left join #afiliado_vta_cuestionada avc
        on dc.COT_RUT = avc.COT_RUT
    where DEC_PERIODO >= @ult_periodo_cc
    and avc.cot_rut is null  

    --1.085.136
    --1.084.411
   -- select * from #deuda5_total

    --Deuda con RJ
	SELECT DDR_RUT, RJD_PERIODO, COT_RUT 
    into #deuda_rj
    FROM RESOLUCION_JUDICIAL R with (nolock)
	JOIN RJUD_DEUDA RD  with (nolock)
        ON R.REJ_FOLIO=RD.REJ_FOLIO
    where RJD_PERIODO >= @ult_periodo_cc

    --Deuda Total 5 años,SIN ventas cuestionadas, sin RJ
    SELECT d.DEC_RUT, d.DEC_PERIODO, d.COT_RUT, d.DEUDA
    INTO #deuda5_sin_rj
    FROM #deuda5_total d WITH (NOLOCK)
    LEFT JOIN #deuda_rj r WITH (NOLOCK)
        ON d.DEC_RUT = r.DDR_RUT 
        AND d.DEC_PERIODO = r.RJD_PERIODO
        AND d.COT_RUT = r.COT_RUT
    WHERE r.DDR_RUT IS NULL  -- Excluye coincidencias

    --Suma deuda , con su dec_rut
    select dec_rut, sum(isnull(deuda, 0)) as deuda_sum 
    into #deuda5_filtrada
    from #deuda5_sin_rj 
    group by dec_rut
    --order by DEC_RUT, DEC_PERIODO

	--Req_#17333 =======================================================================================

   
select mcob.cob_codigo  
   ,0 as pcheck  
   ,mdeu.ddr_rut as deudor_rut  
   ,upper(rtrim(ltrim(mdeu.ddr_nombre))) as deudor_nombre  
   ,odasgper.DEC_PERIODO  
   ,(select sum (dec_pactado - dec_pagado) from DEUDA_COTIZANTE dc WITH (NOLOCK) where dc.DEC_RUT=odasg.DDR_RUT and dc.COT_RUT=odasgper.COT_RUT and dc.DEC_PERIODO= odasgper.DEC_PERIODO) as deuda  
   ,(select sum(DD.DDT_SALDO) from DNP WITH (NOLOCK) join  DNP_DETALLE dd WITH (NOLOCK) on dd.PPC_FOLIO=dnp.PPC_FOLIO where dnp.epa_rut =odasg.DDR_RUT and cot_rut =odasgper.COT_RUT and dd.PPC_PERIODO=odasgper.DEC_PERIODO) as dnp  
   ,case when COALESCE(odasgper.dec_tipo_deuda,'NP') ='NP' then COALESCE(odasgper.dec_deuda,0) else 0 end as deuda_monto_np  
   ,case when COALESCE(odasgper.dec_tipo_deuda,'NP') ='DNP' then COALESCE(odasgper.dec_deuda,0) else 0 end as deuda_monto_dnp  
   ,odasg.deu_correl as deu_correl  
   ,upper(rtrim(ltrim(mcob.cob_nombre))) as cob_nom  
   ,( select case when count(rjud.rej_folio)>0 then 1 else 0 end   
        from resolucion_judicial rjud WITH (NOLOCK)  
       where rjud.ddr_rut = mdeu.ddr_rut  
     ) as cob_rju_vig
	, mdeu.ddr_mediatica ddr_mediatica   --Req_#17333
	, mdeu.ddr_quiebra ddr_quiebra		 --Req_#17333
	  , CASE 
    WHEN EXISTS (
        SELECT 1
        FROM dbo.contrato c WITH (NOLOCK)   
        JOIN dbo.fun f WITH (NOLOCK) 
            ON f.con_folio = c.con_folio    
        JOIN dbo.Gescob_ejecutivo_cuestionado g WITH (NOLOCK)
            ON g.eje_rut = f.eje_rut
        WHERE f.fun_tipo LIKE '%1%'
            AND c.con_ultimo = 'S'
            AND c.cot_rut = mdeu.ddr_rut
    ) THEN 'X' 
    ELSE '' 
END AS venta_cuestionada					--Req_#17333
, ufp.ppc_fecha_pago as ult_fecha_pago		--Req_#17333
, isnull(deuda_sum, 0) as deuda5anos		--Req_#17333
  into #deuda_pre  
  from cobrador as mcob WITH (NOLOCK)  
   join deudor_asignado as odasg WITH (NOLOCK) 
        on odasg.cob_codigo = mcob.cob_codigo and odasg.deu_asig_desde < getdate() and ( odasg.deu_asig_hasta >= getdate() or odasg.deu_asig_hasta is null)  
   join deuasig_periodo as odasgper WITH (NOLOCK) 
        on odasgper.deu_correl = odasg.deu_correl  
   join deudor as mdeu WITH (NOLOCK) 
        on mdeu.ddr_rut = odasg.ddr_rut  

   left join 
   (
    SELECT t1.epa_rut, MAX(t1.fecha_pago) AS ppc_fecha_pago
    FROM (
        SELECT  epa_rut, max(cp.ppc_fecha_pago) AS fecha_pago
        FROM dbo.COTIZACION_PAGADA cp WITH (NOLOCK)
        group by epa_rut   
        UNION --ALL
        SELECT epa_rut, max(pp.ppc_fecha_pago)
        FROM dbo.planilla pp WITH (NOLOCK) 
        group by epa_rut
    ) t1
    group by t1.epa_rut
    ) ufp
    on ufp.epa_rut = mdeu.ddr_rut
 left join #deuda5_filtrada
        on dec_rut = mdeu.ddr_rut
  where mcob.cob_judicial ='S'  
    and (mcob.cob_codigo=@p_cod_cob or  @p_cod_cob is null)  
    and (@p_ind_rjud ='N' or not exists (  
      select 1  
     from DEUDA_COTIZANTE dc WITH (NOLOCK) where dc.DEC_RUT=odasg.DDR_RUT and dc.COT_RUT=odasgper.COT_RUT and dc.DEC_PERIODO= odasgper.DEC_PERIODO and DEC_NRORESOL > 0  
      ))  
    and ( (@excluir_mediatica = 'S' and (mdeu.ddr_mediatica = 'N' or mdeu.ddr_mediatica is null))
            or @excluir_mediatica = 'N' or @excluir_mediatica is null
            )
    and ( (@excluir_quiebra = 'S' and (mdeu.ddr_quiebra = 'N' or mdeu.ddr_quiebra is null )   )
            or @excluir_quiebra = 'N' or @excluir_quiebra is null
            )



    select *
	into #deuda
	from #deuda_pre 
	where ( (@excluir_venta = 'S' and (venta_cuestionada = '' or venta_cuestionada is null )   )
            or @excluir_venta = 'N' or @excluir_venta is null
            )
  
  update #deuda set deuda=0 where deuda <0 or deuda is null  
  update #deuda set dnp=0 where dnp <0 or dnp is null  
  
  select   
  cob_codigo, pcheck, deudor_rut, deudor_nombre, DEC_PERIODO, 'NP' as tipo_deuda, (deuda - dnp) as deuda , deu_correl, cob_nom, cob_rju_vig  
 , ddr_mediatica, ddr_quiebra, venta_cuestionada, ult_fecha_pago, deuda5anos
  into #respuesta  
  from #deuda where deuda > dnp  
  
  union all  
  
  select   
  cob_codigo, pcheck, deudor_rut, deudor_nombre, DEC_PERIODO, 'DNP' as tipo_deuda, dnp as deuda , deu_correl, cob_nom, cob_rju_vig 
   , ddr_mediatica, ddr_quiebra , venta_cuestionada, ult_fecha_pago, deuda5anos
  from #deuda where dnp > 0  
  
  
  select   
   cob_codigo,   
   pcheck,   
   deudor_rut,   
   deudor_nombre,   
   count (distinct case when tipo_deuda ='NP' then DEC_PERIODO else null end) as deuda_tipo_np_ind,  
   count (distinct case when tipo_deuda ='DNP' then DEC_PERIODO else null end) as deuda_tipo_dnp_ind,  
   sum(case when tipo_deuda ='NP' then deuda else 0 end) as deuda_monto_np,  
   sum(case when tipo_deuda ='DNP' then deuda else 0 end) as deuda_monto_dnp,  
   deu_correl,   
   cob_nom,   
   cob_rju_vig  
  , case when ddr_mediatica = 'S' then 'X' else '' end as ddr_mediatica
  , case when ddr_quiebra = 'S' then 'X' else '' end as ddr_quiebra
  , venta_cuestionada
  , ult_fecha_pago
  , isnull(deuda5anos, 0) as deuda5anos
  from #respuesta  
  group by cob_codigo,pcheck, deudor_rut, deudor_nombre, deu_correl , cob_nom, cob_rju_vig  
    , ddr_quiebra
  , ddr_mediatica
  , venta_cuestionada
  , ult_fecha_pago
  , deuda5anos
  --having  (@p_ind_rjud ='N' or not exists (  
  --    select 1  
  --   from resolucion_judicial rjud WITH (NOLOCK)  
  --    where rjud.deu_correl = #respuesta.deu_correl  
  --    ) )  
  order by 4 asc  
    
    
END  