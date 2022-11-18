#INCLUDE "TOTVS.CH"

/*/{Protheus.doc} SF2460I
Ponto de entrada localizado após a atualização das tabelas referentes à nota fiscal (SF2/SD2). 
O Ponto de entrada é executado após a exibição da tela de contabilização On-Line, mas antes da contabilização oficial. 
ATENÇÃO: Este ponto de entrada está dentro da transação na gravação das tabelas do documento.
@type function
@version 12.1.33
@author Wlysses Cerqueira (WlyTech)
@since 21/10/2022
/*/

User Function SF2460I()

    Local oCyberLog := TCyberLogIntegracao():New()

    oCyberLog:SetNumDocSaida()

Return()
