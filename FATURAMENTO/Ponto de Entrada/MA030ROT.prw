#INCLUDE "TOTVS.CH"

/*/{Protheus.doc} MA030ROT
PE para incluir opcao no menu
@type function
@version 12.1.25
@author Paulo Camata (Camatech)
@since 19/08/2020
/*/

User Function MA030ROT()

    Local aMenu := {}

    aMenu := TCyberLogIntegracao():AddMenu()

Return(aMenu)
