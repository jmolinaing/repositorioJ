  
/* =======================================================================================
    Tipo de Objeto  : Procedimiento Almacenado             
    Nombre Objeto   : spu_prontopago_consulta             
    Parmetros       : @rut : 
                    : @fecdesde:
                    : @fechasta:   
    Sistema         : Mantención Agencias.            
    Destino         : BD ISAPRE                  
    Creado por      : Jorge Molina      
    Fecha Creacin   : 05-05-2026                
    Descripcion     : Obtiene Acuerdos firmados Pronto Pago TFU.     
                        
    Modificado      : 
    fecha           : 
    Descripción     : 

 =======================================================================================*/  
  
--execute spu_ges_cob_cju_ges_deuda null, 'S', 's', 'N', 's'
  
CREATE PROCEDURE [dbo].[spu_pront_consulta] @rut chat(10), @fecdesde datetime = null, @fecdesde datetime = null
AS  
BEGIN   
 SET NOCOUNT ON;  


 SELECT SPP_FOLIO
      ,SPP_FECHA
      ,SPP_RUT
      ,SPP_NOMBRE
      --,SPP_DIRECCION      --no
      ,SPP_EMAIL
      ,SPP_USUARIO
      ,SPP_TIPO
      ,SPP_FORMA_PAGO
      ,spp.BCO_CODIGO AS BCO_CODIGO
      , b.BCO_NOMBRE AS BCO_NOMBRE
      ,TIPO_CTA
      ,SPP_NUMCTACTE
      ,SPP_SALDO_RESTITUCION_UF
      ,SPP_SALDO_RESTITUCION_PESOS
      ,SPP_DEUDA_COTIZ
      ,SPP_DEUDA_LUR
      --,SPP_HONCOB
      ,SPP_SALDO_POST_COMPENS
      ,SPP_TASA_DCTO
      ,SPP_MONTO_DCTO
      ,SPP_TOTAL_APAGAR
      ,SPP_FECHA_AUTORIZA
      --,SPP_FECHA_PAGO
      --,SPP_PIN
  FROM dbo.SOLIC_PRONTO_PAGO_TFU spp with (nolock)
  left join dbo.banco b  with (nolock)
    on.spp.bco_codigo = b.bco_codigo




END