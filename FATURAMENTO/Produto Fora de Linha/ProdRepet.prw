#include "totvs.ch"

/*/{Protheus.doc} prodRepet
Funcao para efetuar validações se no grid existem produtos já inseridos
@author Paulo Cesar Camata
@since 08/08/2017
@version 12.1.14
@type function
/*/
user function prodRepet()
    local _nPosPrd, _cCodPrd, nP
    local _nLinAtu := n // linha atual selecionada

    do Case
        case allTrim(funName()) == "MATA110" .and. allTrim(readVar()) == "M->C1_PRODUTO" // Solicitação de Compras
            _nPosPrd := aScanx(aHeader, {|x| AllTrim(x[2]) == "C1_PRODUTO"})
            _cCodPrd := M->C1_PRODUTO

        case (ISINCALLSTACK("MATA121") .or. ISINCALLSTACK("MATA120")) .and. allTrim(readVar()) == "M->C7_PRODUTO" // Pedido de Compras
            _nPosPrd := aScanx(aHeader, {|x| AllTrim(x[2]) == "C7_PRODUTO"})
            _cCodPrd := M->C7_PRODUTO

        otherWise
            msgStop("Não existe tratamento para a rotina " + allTrim(funName()) + ".", "ROTINA NAO POSSUI TRATAMENTO")
            return .F.
    endCase

    for nP := 1 to len(aCols)
        if _nLinAtu <> nP .and. !aCols[nP, len(aCols[nP])] // Não é linha atual e não está deletada
            if allTrim(aCols[nP, _nPosPrd]) == allTrim(_cCodPrd)
                Help(nil, nil, "Produto já digitado anteriomente", nil, "Produto " + allTrim(_cCodPrd) + " já digitado na linha " + cValToChar(nP) + ".", 1, 0)
                return .F.
            endif
        endif
    next nP
return .T.