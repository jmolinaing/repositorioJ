select distinct deuda_cob.cob_codigo
, deuda_cob.cob_externo
,case when deuda_cob.cob_externo ='S' then 'SI' else 'NO' end as externo
,case when deuda_cob.cob_externo ='S' then 'NO' else 'SI' end as equipo_interno
,case when coalesce(deuda_cob.cob_judicial,'N') = 'S' then 'SI' else 'NO' end equipo_juridico
,case when coalesce(cob_dep.cob_codigo,0) = 9000 then 'SI' else 'NO' end equipo_stock
,cob_dep.cob_codigo as rel_cob_cod
--into #equipo
, case when ( (deuda_cob.cob_externo = 'N') or (coalesce(cob_dep.cob_codigo,0) = 9000) or (coalesce(deuda_cob.cob_judicial,'N') = 'S' ) ) then 'NO' else 'SI' end as equipo_otro
from cobrador deuda_cob with (nolock) 
	  left join cobrador as cob_dep  with (nolock)  on cob_dep.cob_codigo = deuda_cob.cob_codigo_dep
where deuda_cob.cob_codigo in (194
,579
,218)
	  /*
Luego, relacionar con la tabla de resultado y evaluar estas condiciones (en el Where)
Interno: cobrador_externo = 'NO'
Stock: rel_cob_cod=9000
Judicial: cobrador_estudio_juridico='SI'
Otros: Not ((cobrador_externo = 'NO') or (rel_cob_cod=9000) or (cobrador_estudio_juridico='SI'))
*/