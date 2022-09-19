#include "totvs.ch"

/*/{Protheus.doc} FLSOLCOMPRA
Validar digita��o do produto na solicita��o de compra
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
			msgStop("Produto digitado est� fora de linha. N�o � poss�vel efetuar a inclus�o.")
			return .F.
		endif
	endif

return .T.