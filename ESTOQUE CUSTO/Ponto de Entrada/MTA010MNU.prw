/*/{Protheus.doc} MTA010MNU
PE para incluir opcao no menu
@type function
@version 12.1.25
@author Paulo Camata (Camatech)
@since 19/08/2020
/*/
User Function MTA010MNU()

    Local aTray := {}

    AAdd(aTray, {"Atualiz. Prod."         , "U_EC0002PR", 0, 2, 0, NIL})
    AAdd(aTray, {"Atualiz. Todos Produtos", "U_EC0002AL", 0, 2, 0, NIL})

    AAdd(aRotina, {"Rotina Tray", aTray, 0, 2, 0, NIL})

    TCyberLogIntegracao():AddMenu(.T.)

Return()
