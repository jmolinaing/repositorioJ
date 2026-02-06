USE [ISAPRE]
GO

/****** Object:  Table [dbo].[GCO_ENVMSG_DEUDA_CUPONES]    Script Date: 29-01-2026 20:07:37 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[GCO_ENVMSG_DEUDA_CUPONES](
	[CUP_ID_BASE] [datetime] NOT NULL,
	[COT_RUT] [char](10) NULL,
	[NOM_COTIZANTE] [varchar](25) NULL,
	[EPA_RUT] [char](10) NULL,
	[EPA_RAZON] [varchar](200) NULL,
	[DEC_PERIODO] [datetime] NULL,
	[DEC_TIPO_DEUDA] [varchar](20) NULL,
	[PACTADO] [numeric](10, 0) NULL,
	[PAGADO] [numeric](10, 0) NULL,
	[DEUDANOMINAL] [numeric](10, 0) NULL,
	[REAJUSTE] [numeric](10, 0) NULL,
	[INTERES] [numeric](10, 0) NULL,
	[RECARGO] [numeric](10, 0) NULL,
	[TOTAL_APAGAR] [numeric](10, 0) NULL,
	[DESCTO_DEUDANOMINAL] [numeric](10, 0) NULL,
	[DESCTO_REAJUSTE] [numeric](10, 0) NULL,
	[DESCTO_INTERES] [numeric](10, 0) NULL,
	[DESCTO_RECARGO] [numeric](10, 0) NULL
) ON [PRIMARY]
GO


