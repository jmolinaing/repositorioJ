USE [ISAPRE]
GO
/****** Object:  Trigger [dbo].[tr_reg_gestion_ins]    Script Date: 19-03-2026 17:12:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


/* ==========================================================
  Author:		Jorge Molina
  Create date: 19-03-2026
  Description:	Actualiza DATOS DE CONTACTABILIDAD para resoluciones 
  del mismo deudor con REJ_FECREG >= fecha y que no estén impresas
 ============================================================*/

create TRIGGER dbo.tr_resoljud_actualiza_datos_contacto
    ON dbo.RESOLUCION_JUDICIAL
    AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Si no hay filas actualizadas, no hacemos nada
    IF NOT EXISTS (SELECT 1 FROM inserted)
        RETURN;

    -- Actualizar "otras" resoluciones del mismo deudor con REJ_FECREG >= fecha de la fila actualizada
    -- y que no estén impresas
    UPDATE r
    SET
        r.REJ_DIRECCION = i.REJ_DIRECCION,
        r.CMN_CODIGO    = i.CMN_CODIGO,
        r.REJ_FONO1     = i.REJ_FONO1,
        r.REJ_FONO2     = i.REJ_FONO2,
        r.REJ_FONO3     = i.REJ_FONO3,
        r.REJ_EMAIL     = i.REJ_EMAIL,
        r.REJ_CTO_RUT   = i.REJ_CTO_RUT,
        r.REJ_CTO_NOM   = i.REJ_CTO_NOM,
        r.REJ_CTO_FONO  = i.REJ_CTO_FONO,
        r.REJ_CTO_TIPO  = i.REJ_CTO_TIPO,
        r.RAC_CODIGO    = i.RAC_CODIGO
    FROM [dbo].[RESOLUCION_JUDICIAL] r
    INNER JOIN inserted i
        ON r.DDR_RUT = i.DDR_RUT
    WHERE
        r.REJ_FECREG >= i.REJ_FECREG
        AND r.REJ_FECIMPRIME IS NULL
        AND r.REJ_FOLIO <> i.REJ_FOLIO;
END;
