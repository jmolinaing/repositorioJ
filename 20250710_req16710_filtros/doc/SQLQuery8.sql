USE ISAPRE
GO

SELECT EPR_CODIGO
      ,EPL_CODIGO
      ,EPR_DESCRIP
      ,EPR_INIVIG_ENVIO
      ,EPR_FINVIG_ENVIO
      ,EPR_TEMPLATE_API
      ,EPR_HORA_ENVIO
      ,EPR_LUNES
      ,EPR_MARTES
      ,EPR_MIERCOLES
      ,EPR_JUEVES
      ,EPR_VIERNES
      ,EPR_SABADO
      ,EPR_DOMINGO
  FROM dbo.GCO_ENVMSG_PROGRAMA

GO



USE [ISAPRE]
GO

INSERT INTO [dbo].[GCO_ENVMSG_PROGRAMA]
           ([EPR_CODIGO]
           ,[EPL_CODIGO]
           ,[EPR_DESCRIP]
           ,[EPR_INIVIG_ENVIO]
           ,[EPR_FINVIG_ENVIO]
           ,[EPR_TEMPLATE_API]
           ,[EPR_HORA_ENVIO]
           ,[EPR_LUNES]
           ,[EPR_MARTES]
           ,[EPR_MIERCOLES]
           ,[EPR_JUEVES]
           ,[EPR_VIERNES]
           ,[EPR_SABADO]
           ,[EPR_DOMINGO])
     VALUES
           (1
           ,1
           ,'PROGRAMACION 1'
           ,GETDATE()
           ,GETDATE()
           ,'TEMPLATE1'
           ,GETDATE()
           ,'S'
           ,'S'
           ,'S'
           ,'S'
           ,'S'
           ,'S'
           ,'S')
GO



