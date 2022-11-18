#INCLUDE "TOTVS.CH"

/*/{Protheus.doc} CRM980MDEF
@author Wlysses Cerqueira (WlyTech)
@since 17/05/2022
@version 1.0
@description PE para incluir opcao no menu.
@type Class
/*/

User Function CRM980MDEF()

    Local aMenu := {}

    aMenu := TCyberLogIntegracao():AddMenu()

Return(aMenu)
