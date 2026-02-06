SELECT * FROM GCO_DCTO_DEUDATOT



							 	select tdc.DEC_PERIODO, descto_cotiz= coalesce(GCD_PORC_DEUDA, 0), descto_rea=coalesce(GCD_PORC_REAJ, 0), descto_int=coalesce(GCD_PORC_INT, 0), descto_rec=coalesce(GCD_PORC_REC,0)
								FROM #TMP_DEUDA_COTIZANTE tdc
								join #tabla_final_filtrada tf
									on tdc.dec_rut = tf.rut_deudor
								left join GCO_DCTO_DEUDATOT g with (nolock)
									on 
								where GCD_TIPODEUDOR = 'V'
									--AND GCD_MESES_DESDE <= dbo.f_cob_antiguedad_deuda ('20250201', getdate())
									--AND ( GCD_MESES_HASTA >= dbo.f_cob_antiguedad_deuda ('20250201', getdate())	OR GCD_MESES_HASTA IS NULL)
								order by GCD_MESES_DESDE DESC;

								--numeric(10,0)
							 --          ,DESCTO_DEUDANOMINAL
							 --          ,DESCTO_REAJUSTE
							 --          ,DESCTO_INTERES
							 --          ,DESCTO_RECARGO

								--(1786234 rows affected)
								select distinct dec_periodo as periodo, cast(null as numeric(10)) descto_cotiz, cast(null as numeric(10)) descto_rea, cast(null as numeric(10)) descto_int, cast(null as numeric(10)) descto_rec
								into #periodo_descuentos
								FROM DEUDA_COTIZANTE DC with (nolock) 
								--left join GCO_DCTO_DEUDATOT g with (nolock)
								--on dc.DEC_PERIODO = 


							--	select * from #periodo_descuentos


							update #periodo_descuentos 
							set descto_cotiz = g.GCD_PORC_DEUDA
							, descto_rea = g.GCD_PORC_REAJ
							, descto_int = g.GCD_PORC_INT
							, descto_rec = g.GCD_PORC_REC
							from GCO_DCTO_DEUDATOT g
								where GCD_TIPODEUDOR = 'V'
									AND GCD_MESES_DESDE <= dbo.f_cob_antiguedad_deuda (#periodo_descuentos.periodo, getdate())
									AND ( GCD_MESES_HASTA >= dbo.f_cob_antiguedad_deuda (#periodo_descuentos.periodo, getdate())	OR GCD_MESES_HASTA IS NULL)
								order by GCD_MESES_DESDE DESC;



							 	select top 1 '20250201' AS PERIODO, descto_cotiz= coalesce(GCD_PORC_DEUDA, 0), descto_rea=coalesce(GCD_PORC_REAJ, 0), descto_int=coalesce(GCD_PORC_INT, 0), descto_rec=coalesce(GCD_PORC_REC,0)
								from GCO_DCTO_DEUDATOT
								where GCD_TIPODEUDOR = 'V'
									AND GCD_MESES_DESDE <= dbo.f_cob_antiguedad_deuda ('20250201', getdate())
									AND ( GCD_MESES_HASTA >= dbo.f_cob_antiguedad_deuda ('20250201', getdate())	OR GCD_MESES_HASTA IS NULL)
								order by GCD_MESES_DESDE DESC;
