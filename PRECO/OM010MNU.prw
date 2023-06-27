#INCLUDE "TOTVS.CH"

/*/{Protheus.doc} OM010MNU
PE para incluir opcao no menu
@type function
@version 12.1.25
@author Wlysses Cerqueira (WlyTech)
@since 04/04/2023
/*/
User Function OM010MNU()

    Local aMenu := {}

    aAdd(aMenu, {"Manutencao", "U_PRECOTEL", 0, 3, 32, NIL})

    aAdd(aRotina, {"Proc. Preço Casa China", aMenu, 0, 2, 0, NIL})

Return()
