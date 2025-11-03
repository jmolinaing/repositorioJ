-- =================================================================
-- Author:		Jorge Molina
-- Create date: 23-12-2024
-- Description:	devuelva el dato de contacto mas confiable del tipo indicado.
-- =================================================================
CREATE FUNCTION [dbo].[f_get_datocontacto](@rut char(10), @tipocontacto varchar(50))
RETURNS varchar(200)
AS
BEGIN	

declare @valor varchar(200)

		--Primera tabla traspaso: se insertaran todos los registros de los ORIGENES
	create table #contacto_det_paso
	(
		cto_rut char(10)  not null
		--, ctd_correl numeric(20) identity(1,1)
		, ctd_correl numeric(10) not null
		, tipo varchar(50) not null		--“fono”, “email” o “direccion” = @tipoContacto
		, valor varchar(500) not null
		, cmn_codigo numeric(4) null
		, cmn_nombre varchar(100) null
		, usu_login char(30)  null
		, ctd_fecreg datetime  null
		, ctd_origen varchar(50) null	
		, ctd_tipo_val char(1) null 
		, usu_login_val varchar(100) null 	
		, ctd_fecha_val datetime null
		, ctd_origen_val varchar(100) null
		, ctd_descrip_val varchar(500) null
		, orden integer null
		, fecha_reciente datetime  null
		, primary key (cto_rut, ctd_correl)
	)

	insert into #contacto_det_paso
	exec spu_ges_cob_contactdeu_listar @rut, @tipocontacto;

	select top 1 @valor = valor from #contacto_det_paso
	--declare @ldt_fecimprime datetime
	--	,@ldt_fecanula datetime
	--	,@ldt_fecrecauda datetime
	--	,@ldt_fecingtrib datetime
	--	,@ls_estado varchar(50)

	--select @ldt_fecimprime=REJ_FECIMPRIME 
	--	,@ldt_fecanula=REJ_FECANULA
	--	,@ldt_fecrecauda=REJ_FECRECAUDA
	--	,@ldt_fecingtrib=REJ_FECINGTRIB
	--from RESOLUCION_JUDICIAL
	--where REJ_FOLIO=@rej_folio

	--IF @@ROWCOUNT=0
	--	set @ls_estado=''
	--else if @ldt_fecrecauda is not null 
	--	set @ls_estado='RECAUDADA'
	--else if @ldt_fecanula is not null 
	--	set @ls_estado='ANULADA'
	--else if @ldt_fecingtrib is not null 
	--	set @ls_estado='INGRESADA A TRIBUNALES'
	--else if @ldt_fecimprime is not null 
	--	set @ls_estado='EMITIDA'
	--else
	--	set @ls_estado='PENDIENTE'

	RETURN @valor
END

GO


