USE [AGENCIAS]
GO

/****** Object:  Table [dbo].[CUPONPAGO_COTIZ_DEUDA]    Script Date: 04-11-2025 20:31:12 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[CUPONPAGO_COTIZ_DEUDA](
	[CORREL] [numeric](16, 0) NULL,
	[COT_RUT] [char](10) NULL,
	[NOM_COTIZANTE] [varchar](25) NULL,
	[EPA_RUT] [char](10) NULL,
	[EPA_RAZON] [varchar](200) NULL,
	[DEC_PERIODO] [datetime] NULL,
	[DEC_TIPO_DEUDA] [varchar](20) NULL,
	[DEC_NRORESOL] [numeric](10, 0) NULL,
	[PACTADO] [numeric](10, 0) NULL,
	[PAGADO] [numeric](10, 0) NULL,
	[DEUDANOMINAL] [numeric](10, 0) NULL,
	[REAJUSTE] [numeric](10, 0) NULL,
	[INTERES] [numeric](10, 0) NULL,
	[RECARGO] [numeric](10, 0) NULL,
	[TOTAL_APAGAR] [numeric](10, 0) NULL,
	[COBRADOR] [varchar](65) NULL,
	[FECHA] [datetime] NULL,
	[ANO] [int] NULL,
	[MES] [int] NULL,
	[DEUDA_HC] [numeric](10, 0) NULL,
	[DESCTO_DEUDANOMINAL] [numeric](10, 0) NULL,
	[DESCTO_REAJUSTE] [numeric](16, 9) NULL,
	[DESCTO_INTERES] [numeric](16, 8) NULL,
	[DESCTO_RECARGO] [numeric](16, 8) NULL,
	[FOLIO_FUN_HAB] [numeric](10, 0) NULL,
	[FECHA_FUN_HAB] [datetime] NULL,
	[REJ_FOLIO] [numeric](10, 0) NULL
) ON [PRIMARY]
GO


