#INCLUDE "TOTVS.CH"

/*/{Protheus.doc} SF2460I
Ponto de entrada localizado ap�s a atualiza��o das tabelas referentes � nota fiscal (SF2/SD2). 
O Ponto de entrada � executado ap�s a exibi��o da tela de contabiliza��o On-Line, mas antes da contabiliza��o oficial. 
ATEN��O: Este ponto de entrada est� dentro da transa��o na grava��o das tabelas do documento.
@type function
@version 12.1.33
@author Wlysses Cerqueira (WlyTech)
@since 21/10/2022
/*/

User Function SF2460I()

    Local oCyberLog := TCyberLogIntegracao():New()

    oCyberLog:SetNumDocSaida()

Return()
