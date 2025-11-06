CREATE PROCEDURE SP_GenerarEnviosPendientes
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @EPR_CODIGO NUMERIC(10);
    DECLARE @ULT_EJEC DATETIME;
    DECLARE @DIA_ACTUAL VARCHAR(10);
    SET @DIA_ACTUAL = DATENAME(WEEKDAY, GETDATE());

    DECLARE CUR_PROG CURSOR FOR
    SELECT P.EPR_CODIGO
    FROM GCO_ENVMSG_PROGRAMA P
    INNER JOIN GCO_ENVMSG_PLANTILLA PL ON PL.EPL_CODIGO = P.EPL_CODIGO
    WHERE PL.EPL_VIGENTE = 'S'
      AND P.EPR_INIVIG_ENVIO <= GETDATE()
      AND (P.EPR_FINVIG_ENVIO IS NULL OR P.EPR_FINVIG_ENVIO >= GETDATE())
      AND (
            (@DIA_ACTUAL = 'Monday' AND P.EPR_LUNES = 'S') OR
            (@DIA_ACTUAL = 'Tuesday' AND P.EPR_MARTES = 'S') OR
            (@DIA_ACTUAL = 'Wednesday' AND P.EPR_MIERCOLES = 'S') OR
            (@DIA_ACTUAL = 'Thursday' AND P.EPR_JUEVES = 'S') OR
            (@DIA_ACTUAL = 'Friday' AND P.EPR_VIERNES = 'S') OR
            (@DIA_ACTUAL = 'Saturday' AND P.EPR_SABADO = 'S') OR
            (@DIA_ACTUAL = 'Sunday' AND P.EPR_DOMINGO = 'S')
          );

    OPEN CUR_PROG;
    FETCH NEXT FROM CUR_PROG INTO @EPR_CODIGO;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        SELECT @ULT_EJEC = MAX(EPL_FECHORA)
        FROM GCO_ENVMSG_PROGRAMA_LOG
        WHERE EPR_CODIGO = @EPR_CODIGO
          AND EPL_FECHORA < GETDATE();

        IF NOT EXISTS (
            SELECT 1
            FROM GCO_ENVMSG_PROGRAMA_LOG
            WHERE EPR_CODIGO = @EPR_CODIGO
              AND EPL_FECHORA >= ISNULL(@ULT_EJEC, '19000101')
        )
        BEGIN
            BEGIN TRY
                INSERT INTO GCO_ENVMSG_MENSAJE (
                    -- colocar los campos reales
                )
                SELECT
                    -- origen de los datos
                FROM
                    -- fuentes aplicables
                WHERE
                    -- filtros específicos;

                INSERT INTO GCO_ENVMSG_PROGRAMA_LOG (EPR_CODIGO, EPL_FECHORA, EPL_TEXTO_ERROR)
                VALUES (@EPR_CODIGO, GETDATE(), NULL);
            END TRY
            BEGIN CATCH
                INSERT INTO GCO_ENVMSG_PROGRAMA_LOG (EPR_CODIGO, EPL_FECHORA, EPL_TEXTO_ERROR)
                VALUES (@EPR_CODIGO, GETDATE(), ERROR_MESSAGE());
            END CATCH
        END

        FETCH NEXT FROM CUR_PROG INTO @EPR_CODIGO;
    END

    CLOSE CUR_PROG;
    DEALLOCATE CUR_PROG;
END;
GO