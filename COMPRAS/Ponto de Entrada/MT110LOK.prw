#include "totvs.ch"

/*/{Protheus.doc} MT110TOK
PE chamado a cada linha do GRID da tela Solicitacao de compra
@author Paulo Cesar Camata
@since 02/12/2017
@version 12
@type function
/*/
user function MT110LOK()
	local _nPosPro := aScan(aHeader, {|x| AllTrim(x[2]) == "C1_PRODUTO"}) // Posicao do campo Centro de Custo no aCols
	local _cForLin

	if aCols[n, Len(aCols[n])] // Linha deletada nao deve ser efetuada validacao
		Return .T.
	endif

	_cForLin := Posicione("SB1", 1, xFilial("SB1") + aCols[n, _nPosPro], "B1_YFORLIN") // Produto fora de linha
    
	if _cForLin == "S" // Nao permitir inclusao da linha se produto fora de linha
		msgStop("Produto fora de linha. Não é possível efetuar solicitação de compra.")
		return .F.
	endif

return .T.