#include "totvs.ch"

/*/{Protheus.doc} prodRepet
PE para alterar o preço da funcao MaTabPrCom - Preço de compra
@author Paulo Cesar Camata
@since 07/02/2019
@version 12.1.17
@type function
/*/
user function CM010PCL()
    local cCodFor := paramIxb[1] // Codigo do Forncedor
    local cLojFor := paramIxb[2] // Loja Fornecedor
    local cCodTab := paramIxb[3] // Codigo da tabela de preco
    local cCodPrd := paramIxb[4] // Codigo do produto
    local nPreco  := paramIxb[6] // Preço calculado pelo sistema
    local aAreAIB := AIB->(getArea())

    if SM0->M0_ESTCOB <> "PR"
        // Verifica se na tabela de preço existe preço cadastrado para o produto/estado
       
        dbSelectArea("AIB")
        AIB->(dbSetOrder(2))
        AIB->(msSeek(xFilial("AIB") + cCodFor + cLojFor + cCodTab + cCodPrd, .T.))
        if FieldPos("AIB_YPRC" + SM0->M0_ESTCOB) > 0 // Existe campo na tabela de preço - AIB
            if AIB->(FieldGet(FieldPos("AIB_YPRC" + SM0->M0_ESTCOB))) > 0 // Preco informado
                nPreco := AIB->(FieldGet(FieldPos("AIB_YPRC" + SM0->M0_ESTCOB)))
            endif
        endif
        restArea(aAreAIB) // Restaurando recno anterior a procura
    endif
return nPreco