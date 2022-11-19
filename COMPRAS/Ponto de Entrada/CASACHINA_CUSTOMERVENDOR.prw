#INCLUDE "TOTVS.CH"
#INCLUDE "TOPCONN.CH"

/*/{Protheus.doc} MVC_ITEM
@author Wlysses Cerqueira (WlyTech)
@since 09/03/2021
@version 1.0
@description Pontos de entrada MVC da rotina MATA020 - Fornecedor - O ID do modelo da dados da rotina MATA020 é CUSTOMERVENDOR.
@type function
/*/

User Function CUSTOMERVENDOR()

	Local aParam 		:= ParamIxb
	Local xRet 			:= .T.
	Local oObj 			:= ""
	Local cIdPonto 		:= ""
	Local cIdModel 		:= ""
	Local nOp 			:= 0
	Local oObjCyberLog	:= Nil
	Local aArea 		:= GetArea()

	If !Empty(aParam)

		oObj		:= aParam[1]
		cIdPonto 	:= aParam[2]
		cIdModel 	:= aParam[3]
		nOp 		:= oObj:GetOperation()

		// Chamada na ativação do modelo de dados
		If cIdPonto == "MODELVLDACTIVE"

			// Chamada na validação total do modelo
		ElseIf cIdPonto == "MODELPOS"

			xRet := .T.

			// Chamada na validação total do formulário
		ElseIf cIdPonto == "FORMPOS"


			// Chamada na pré validação da linha do formulário
		ElseIf cIdPonto == "FORMLINEPRE"

			// Chamada na validação da linha do formulário.
		ElseIf cIdPonto == "FORMLINEPOS"

			// Chamada após a gravação total do modelo e dentro da transação
		ElseIf cIdPonto == "MODELCOMMITTTS"

			// Incluir
			If nOp == 3 .Or. nOp == 4

				// Excluir
			ElseIf nOp == 5

			EndIf

			// Chamada após a gravação total do modelo e fora da transação
		ElseIf cIdPonto == "MODELCOMMITNTTS"

			oObjCyberLog := TCyberlogIntegracao():New()

			oObjCyberLog:SendProvider(M->A2_CYBERW == "S", FWIsInCallStack("A020Inclui"), FWIsInCallStack("A020Copia"), FWIsInCallStack("A020Altera"), FWIsInCallStack("A020Exclui"))

			If !Empty(oObjCyberLog:oEmpAuth:cDepositoB2B)
			
				oObjCyberLog:cDeposito := oObjCyberLog:oEmpAuth:cDepositoB2B

				oObjCyberLog:SendProvider(M->A2_CYBERW == "S", FWIsInCallStack("A020Inclui"), FWIsInCallStack("A020Copia"), FWIsInCallStack("A020Altera"), FWIsInCallStack("A020Exclui"))

			EndIf

			// Chamada após a gravação da tabela do formulário
		ElseIf cIdPonto == "FORMCOMMITTTSPRE"

			// Chamada após a gravação da tabela do formulário
		ElseIf cIdPonto == "FORMCOMMITTTSPOS"

			// Chamada no Botão Cancelar
		ElseIf cIdPonto == "MODELCANCEL"

			// Adicionando Botao na Barra de Botoes (BUTTONBAR)
		ElseIf cIdPonto == "BUTTONBAR"

		EndIf

	EndIf

	RestArea(aArea)

Return(xRet)
