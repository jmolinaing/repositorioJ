select * from Gescob_ejecutivo_cuestionado

select * from contrato with (nolock) where con_ultimo = 'S' and cot_rut = ' 145267498'


select * from fun with (nolock) where fun_tipo like '%1%' and con_folio = 1573335

insert Gescob_ejecutivo_cuestionado values ('  89455146', 'obs')


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