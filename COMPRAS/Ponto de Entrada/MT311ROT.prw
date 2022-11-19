#INCLUDE "TOTVS.CH"

/*/{Protheus.doc} MT311ROT
PE para incluir opcao no menu
@type function
@version 12.1.25
@author Wlysses Cerqueira (WlyTech)
@since 19/08/2020
/*/
User Function MT311ROT()

    Local aMenu := {}

    aMenu := TCyberLogIntegracao():AddMenu(.F., PARAMIXB)

Return(aMenu)
