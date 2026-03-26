CREATE TRIGGER TRG_RESOLUCION_JUDICIAL_COPY_CONTACTABILIDAD
    ON [dbo].[RESOLUCION_JUDICIAL]
    AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Aseguramos que solo procesamos si hay cambios en los campos de contactabilidad.
    -- (si quieres que el trigger se dispare solo por cambios en estos campos, habría que refinarlo)
    IF NOT EXISTS (
        SELECT 1
        FROM inserted
        WHERE REJ_DIRECCION IS NOT NULL
           OR CMN_CODIGO   IS NOT NULL
           OR REJ_FONO1    IS NOT NULL
           OR REJ_FONO2    IS NOT NULL
           OR REJ_FONO3    IS NOT NULL
           OR REJ_EMAIL    IS NOT NULL
           OR REJ_CTO_RUT  IS NOT NULL
           OR REJ_CTO_NOM  IS NOT NULL
           OR REJ_CTO_FONO IS NOT NULL
           OR REJ_CTO_TIPO IS NOT NULL
           OR RAC_CODIGO   IS NOT NULL
    )
        RETURN;

    -- Actualizamos las otras resoluciones del mismo deudor
    -- que tengan fecha de registro >= a la de la fila actualizada
    -- y que aún no estén impresas
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
        AND r.REJ_FOLIO <> i.REJ_FOLIO;  -- excluir la fila actualizada (clave: REJ_FOLIO)
END;
