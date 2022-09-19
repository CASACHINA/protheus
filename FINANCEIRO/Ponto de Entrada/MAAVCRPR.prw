/*/{Protheus.doc} MAAVCRPR
PE após analise de credito do sistema
@type function
@version 12.1.25
@author Paulo Camata (Camatech)
@since 02/10/2020
/*/
user function MAAVCRPR()
    lbloq := paramIxb[7] // Bloqueio padrao do sistema

    if SC5->C5_B2B == "S" .and. !empty(SC5->C5_YIDB2B) // Pedido B2B nao deve possuir liberacao padrao (Sempre liberado)
        return .T.
    endif
return lbloq