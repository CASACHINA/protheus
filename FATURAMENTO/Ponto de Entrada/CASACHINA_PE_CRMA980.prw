#include 'protheus.ch'
#include 'fwmvcdef.ch'

/*/{Protheus.doc} CRMA980
@author Wlysses Cerqueira (WlyTech)
@since 17/05/2022
@version 1.0
@description PE Cadastro de clientes.
@type Class
/*/

user function CRMA980()

	//Objeto do formul�rio ou do modelo, conforme o caso.
	Local oModel  //ParamIXB[1]
	//ID do local de execu��o do ponto de entrada
	Local cIdPonto //ParamIXB[2]
	//ID do formul�rio
	Local cIdModel //ParamIXB[3]

	Local xRetorno := .T.

	Local oObjCyberLog := Nil

	IF ! Empty(ParamIXB)

		oModel   := ParamIXB[1]
		cIdPonto := ParamIXB[2]
		cIdModel := ParamIXB[3]

		do case

			//Antes da ativa��o da tela.
		case cIdPonto == "MODELVLDACTIVE"
			//exclus�o
			IF oModel:nOperation == MODEL_OPERATION_DELETE
				//tem que usar Help no padr�o PE MVC
				Help( ,, "HELP",, "Exclus�o n�o permitida devido integra��o com WMS.", 1, 0)
				xRetorno := .F.
			EndIF

			//apos a grava��o, dentro da transa��o
		case cIdPonto $ "MODELCOMMITTTS"

			IF u_CChWMSAtivo() .And. oModel:GetValue("SA1MASTER","A1_CYBERW") == 'S'

				IF oModel:getOperation() == MODEL_OPERATION_INSERT
					//cria o log
					u_CChtoCyberLog('CLIENTES', oModel:GetValue("SA1MASTER","A1_COD") + oModel:GetValue("SA1MASTER","A1_LOJA"), 'I')
				EndIF
				IF oModel:getOperation() == MODEL_OPERATION_UPDATE
					//cria o log
					u_CChtoCyberLog('CLIENTES', oModel:GetValue("SA1MASTER","A1_COD") + oModel:GetValue("SA1MASTER","A1_LOJA"), 'A')
				EndIF
			EndIF

		Case cIdPonto == "MODELCOMMITNTTS"

			//If oModel:GetValue("SA1MASTER","A1_CYBERW") == 'S'

				oObjCyberLog := TCyberlogIntegracao():New()

				oObjCyberLog:SendCustomer(oModel:getOperation() == MODEL_OPERATION_INSERT, .F., oModel:getOperation() == MODEL_OPERATION_UPDATE, oModel:getOperation() == MODEL_OPERATION_DELETE)

				If !Empty(oObjCyberLog:oEmpAuth:cDepositoB2B)

					oObjCyberLog:cDeposito := oObjCyberLog:oEmpAuth:cDepositoB2B

					oObjCyberLog:SendCustomer(oModel:getOperation() == MODEL_OPERATION_INSERT, .F., oModel:getOperation() == MODEL_OPERATION_UPDATE, oModel:getOperation() == MODEL_OPERATION_DELETE)

				EndIf

			//EndIf

		case cIdPonto == "BUTTONBAR"

			xRetorno := {}

		endcase

	EndIF

return xRetorno
