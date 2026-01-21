select * from Gescob_ejecutivo_cuestionado

select * from contrato with (nolock) where con_ultimo = 'S' and cot_rut = ' 145267498'


select * from fun with (nolock) where fun_tipo like '%1%' and con_folio = 1573335

insert Gescob_ejecutivo_cuestionado values ('  89455146', 'obs')

select * from dbo.COTIZACION_PAGADA cp with (nolock)

select max(ppc_fecha_pago) from dbo.COTIZACION_PAGADA cp with (nolock) where cp.epa_rut = ' 763717674'
select max(ppc_fecha_pago) from dbo.planilla pp with (nolock) where pp.epa_rut = ' 763717674'

SELECT MAX(fecha_pago) AS max_fecha_pago
FROM (
    SELECT cp.ppc_fecha_pago AS fecha_pago
    FROM dbo.COTIZACION_PAGADA cp WITH (NOLOCK) 
    WHERE cp.epa_rut = ' 763717674'
    
    UNION ALL
    
    SELECT pp.ppc_fecha_pago
    FROM dbo.planilla pp WITH (NOLOCK) 
    WHERE pp.epa_rut = ' 763717674'
) t


(
SELECT t1.epa_rut, MAX(t1.fecha_pago) AS ppc_fecha_pago
FROM (
    SELECT  epa_rut, max(cp.ppc_fecha_pago) AS fecha_pago
    FROM dbo.COTIZACION_PAGADA cp WITH (NOLOCK)
    group by epa_rut
    --WHERE cp.epa_rut = mdeu.ddr_rut
    
    UNION ALL
    
    SELECT epa_rut, max(pp.ppc_fecha_pago)
    FROM dbo.planilla pp WITH (NOLOCK) 
    group by epa_rut
    --WHERE pp.epa_rut = mdeu.ddr_rut
) t1
group by t1.epa_rut
) ufp

select *
from dbo.contrato c with (nolock)   
join dbo.fun f with (nolock) 
    on f.con_folio= c.con_folio    
         --left join cotizante  (nolock) on cotizante.cot_rut=c.cot_rut  
         --left join ejecutivo e (nolock) on e.eje_rut=f2.eje_rut  
join dbo.Gescob_ejecutivo_cuestionado g with (nolock)
       on g.eje_rut = f.eje_rut
where f.fun_tipo like ( '%1%')
and c.con_ultimo = 'S'
and c.cot_rut
   
   (c.con_inivig <  dateadd(month,3, convert(char(6),@ultimo_dia, 112)+'01')  and  
  (c.con_finvig >= dateadd(month,2, convert(char(6),@ultimo_dia, 112)+'01') or c.con_finvig is null)) and  
  (f2.fun_nulo<>'s' or f2.fun_nulo is null) and  
    and   
  (f2.fun_estado='I' or (f2.fun_estado='R' and f2.fun_origfoto='2')) and  
          f2.fun_fecisapre >=@primer_dia and f2.fun_fecisapre <=@ultimo_dia and   
          cf.cfn_inivig = (select max(cf2.cfn_inivig)  
               from contrato_funcionario cf2 (nolock)     
              where cf2.fnc_rut = cf.fnc_rut and  
                    (substring(cf.tco_codigo,1,5)='E-COM' or   
                    substring(cf.tco_codigo,1,5)='E-CTA')) and   
          not exists ( select 1  
                  from det_haberes_ejecutivo  de (nolock)    
          where de.fun_folio=f2.fun_folio  
        )   and    
         (f2.age_codigo = @age or coalesce(@age,0) = 0) and   
         (f2.eje_rut = @rut_ejecutivo or coalesce(@rut_ejecutivo,'') = '' )  



         select * from parametros where par_codigo='ucc'






--Contable cerrado
	select par_finvig from parametros where par_codigo='ucc'

    select dateadd(m, -60,  par_finvig)  from parametros where par_codigo='ucc'
		
--Deuda Total
	SELECT DEC_RUT, DEC_PERIODO, COT_RUT, DEC_PACTADO - DEC_PAGADO AS DEUDA FROM DEUDA_COTIZANTE

--Deuda con RJ
	SELECT DDR_RUT, RJD_PERIODO, COT_RUT FROM RESOLUCION_JUDICIAL R
			JOIN RJUD_DEUDA RD ON R.REJ_FOLIO=RD.REJ_FOLIO

