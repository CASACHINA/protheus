#include "totvs.ch"

/*/{Protheus.doc} FLSOLCOMPRA
Validar digitação do produto na solicitação de compra
@author Paulo Cesar Camata
@since 03/12/2017
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
user function VLDFORALINHA()

	local _cCodPro := &(__Readvar) // Codigo do produto digitado

	if !empty(_cCodPro) // Digitou algum produto
		if posicione("SB1", 1, xFilial("SB1") + _cCodPro, "B1_YFORLIN") == "S"
			msgStop("Produto digitado está fora de linha. Não é possível efetuar a inclusão.")
			return .F.
		endif
	endif

return .T.