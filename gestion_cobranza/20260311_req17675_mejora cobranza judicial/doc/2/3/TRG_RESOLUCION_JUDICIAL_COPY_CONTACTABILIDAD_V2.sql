CREATE TRIGGER TRG_RESOLUCION_JUDICIAL_COPY_CONTACTABILIDAD
    ON [dbo].[RESOLUCION_JUDICIAL]
    AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Si ninguno de los campos de contactabilidad cambió, no hacemos nada
    IF NOT EXISTS (
        SELECT 1
        FROM inserted i
        INNER JOIN deleted d
            ON i.REJ_FOLIO = d.REJ_FOLIO
        WHERE
            i.REJ_DIRECCION <> d.REJ_DIRECCION
            OR (i.REJ_DIRECCION IS NOT NULL AND d.REJ_DIRECCION IS NULL)
            OR (i.REJ_DIRECCION IS NULL AND d.REJ_DIRECCION IS NOT NULL)

            OR i.CMN_CODIGO <> d.CMN_CODIGO
            OR (i.CMN_CODIGO IS NOT NULL AND d.CMN_CODIGO IS NULL)
            OR (i.CMN_CODIGO IS NULL AND d.CMN_CODIGO IS NOT NULL)

            OR i.REJ_FONO1 <> d.REJ_FONO1
            OR (i.REJ_FONO1 IS NOT NULL AND d.REJ_FONO1 IS NULL)
            OR (i.REJ_FONO1 IS NULL AND d.REJ_FONO1 IS NOT NULL)

            OR i.REJ_FONO2 <> d.REJ_FONO2
            OR (i.REJ_FONO2 IS NOT NULL AND d.REJ_FONO2 IS NULL)
            OR (i.REJ_FONO2 IS NULL AND d.REJ_FONO2 IS NOT NULL)

            OR i.REJ_FONO3 <> d.REJ_FONO3
            OR (i.REJ_FONO3 IS NOT NULL AND d.REJ_FONO3 IS NULL)
            OR (i.REJ_FONO3 IS NULL AND d.REJ_FONO3 IS NOT NULL)

            OR i.REJ_EMAIL <> d.REJ_EMAIL
            OR (i.REJ_EMAIL IS NOT NULL AND d.REJ_EMAIL IS NULL)
            OR (i.REJ_EMAIL IS NULL AND d.REJ_EMAIL IS NOT NULL)

            OR i.REJ_CTO_RUT <> d.REJ_CTO_RUT
            OR (i.REJ_CTO_RUT IS NOT NULL AND d.REJ_CTO_RUT IS NULL)
            OR (i.REJ_CTO_RUT IS NULL AND d.REJ_CTO_RUT IS NOT NULL)

            OR i.REJ_CTO_NOM <> d.REJ_CTO_NOM
            OR (i.REJ_CTO_NOM IS NOT NULL AND d.REJ_CTO_NOM IS NULL)
            OR (i.REJ_CTO_NOM IS NULL AND d.REJ_CTO_NOM IS NOT NULL)

            OR i.REJ_CTO_FONO <> d.REJ_CTO_FONO
            OR (i.REJ_CTO_FONO IS NOT NULL AND d.REJ_CTO_FONO IS NULL)
            OR (i.REJ_CTO_FONO IS NULL AND d.REJ_CTO_FONO IS NOT NULL)

            OR i.REJ_CTO_TIPO <> d.REJ_CTO_TIPO
            OR (i.REJ_CTO_TIPO IS NOT NULL AND d.REJ_CTO_TIPO IS NULL)
            OR (i.REJ_CTO_TIPO IS NULL AND d.REJ_CTO_TIPO IS NOT NULL)

            OR i.RAC_CODIGO <> d.RAC_CODIGO
            OR (i.RAC_CODIGO IS NOT NULL AND d.RAC_CODIGO IS NULL)
            OR (i.RAC_CODIGO IS NULL AND d.RAC_CODIGO IS NOT NULL)
    )
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
