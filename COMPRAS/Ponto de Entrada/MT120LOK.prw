/*/{Protheus.doc} MT120LOK
PE para validar linha do pedido de compra
@author Paulo Cesar Camata
@since 09/10/2018
@type function
/*/
user function MT120LOK()
	local nLin := n
    local nPosPrd := aScan(aHeader,{|x| AllTrim(x[2]) == "C7_PRODUTO"})

    if !aCols[nLin, Len(aHeader) + 1] // Linha nao deletada
        dbSelectArea("SB1")
        SB1->(dbSetOrder(1))
        if SB1->(dbSeek(xFilial("SB1") + aCols[nLin, nPosPrd]))
            if SB1->B1_YFORLIN == "S"
                msgStop("Produto fora de linha. Não é permitido inserir pedido de compra.")
                return .F.
            endif
        else
            msgStop("Produto digitado não encontrado. Produto: " + aCols[nLin, nPosPrd])
            return .F.
        endif
    endif
return .T.