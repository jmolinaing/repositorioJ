  
  
  
/* =======================================================================================*/  
/*  Tipo de Objeto     : Procedimiento Almacenado            */  
/*  Nombre Objeto      : spu_ges_cob_cju_ges_deuda            */  
/*  Parmetros          : @p_cod_cob : codigo de cobrador judicial, ->0 para anular filtro */  
/*        : @p_ind_rjud: indicador de exclusión de deudores sin resolución   */  
/*           judicial, ->S Excluye ->N no excluye      */  
/*  Sistema            : PB10 Gestion Cobranza             */  
/*  Destino            : BD ISAPRE                */  
/*  Creado por         : Proveedor Externo Aligare - Pablo Melo         */  
/*  Fecha Creacin      : 12-04-2022                */  
/*  Descripcion        : Obtiene deudores en cobranza judicial a quienes se puede    */  
/*       generar resoluciones nuevas o complementarias.       */  
/* =======================================================================================*/  
  
-- spu_ges_cob_cju_ges_deuda 27,S  
-- spu_ges_cob_cju_ges_deuda 27,N  
-- spu_ges_cob_cju_ges_deuda 0,S  
-- spu_ges_cob_cju_ges_deuda 0,N  

--execute spu_ges_cob_cju_ges_deuda null, 'S'
  
alter PROCEDURE [dbo].[spu_ges_cob_cju_ges_deuda] @p_cod_cob numeric(4), @p_ind_rjud char(1)  
AS  
BEGIN   
 SET NOCOUNT ON;  
   
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
	, mdeu.ddr_mediatica ddr_mediatica
	, mdeu.ddr_quiebra ddr_quiebra
	, (select max(ppc_fecha_pago) from dbo.planilla pp with (nolock) where pp.epa_rut = mdeu.ddr_rut  ) as ult_fecha_pago
  into #deuda  
  from cobrador as mcob WITH (NOLOCK)  
   join deudor_asignado as odasg WITH (NOLOCK) on odasg.cob_codigo = mcob.cob_codigo and odasg.deu_asig_desde < getdate() and ( odasg.deu_asig_hasta >= getdate() or odasg.deu_asig_hasta is null)  
   join deuasig_periodo as odasgper WITH (NOLOCK) on odasgper.deu_correl = odasg.deu_correl  
   join deudor as mdeu WITH (NOLOCK) on mdeu.ddr_rut = odasg.ddr_rut  
  where mcob.cob_judicial ='S'  
   and (mcob.cob_codigo=@p_cod_cob or  @p_cod_cob is null)  
   and (@p_ind_rjud ='N' or not exists (  
      select 1  
     from DEUDA_COTIZANTE dc WITH (NOLOCK) where dc.DEC_RUT=odasg.DDR_RUT and dc.COT_RUT=odasgper.COT_RUT and dc.DEC_PERIODO= odasgper.DEC_PERIODO and DEC_NRORESOL > 0  
      ))  
  
  
  update #deuda set deuda=0 where deuda <0 or deuda is null  
  update #deuda set dnp=0 where dnp <0 or dnp is null  
  
  select   
  cob_codigo, pcheck, deudor_rut, deudor_nombre, DEC_PERIODO, 'NP' as tipo_deuda, (deuda - dnp) as deuda , deu_correl, cob_nom, cob_rju_vig  
 , ddr_mediatica, ddr_quiebra, ult_fecha_pago
  into #respuesta  
  from #deuda where deuda > dnp  
  
  union all  
  
  select   
  cob_codigo, pcheck, deudor_rut, deudor_nombre, DEC_PERIODO, 'DNP' as tipo_deuda, dnp as deuda , deu_correl, cob_nom, cob_rju_vig 
   , ddr_mediatica, ddr_quiebra , ult_fecha_pago
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
  , case when ddr_mediatica = 'S' then 'Si' else 'No' end as ddr_mediatica
  , case when ddr_quiebra = 'S' then 'Si' else 'No' end as ddr_quiebra
  , ult_fecha_pago
  from #respuesta  
  group by cob_codigo,pcheck, deudor_rut, deudor_nombre, deu_correl , cob_nom, cob_rju_vig  
    , ddr_quiebra
  , ddr_mediatica
  , ult_fecha_pago
  --having  (@p_ind_rjud ='N' or not exists (  
  --    select 1  
  --   from resolucion_judicial rjud WITH (NOLOCK)  
  --    where rjud.deu_correl = #respuesta.deu_correl  
  --    ) )  
  order by 4 asc  
    
    
END  