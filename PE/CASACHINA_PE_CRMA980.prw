#include 'protheus.ch'
#include 'fwmvcdef.ch'


user function CRMA980()

	//Objeto do formulário ou do modelo, conforme o caso.
	Local oModel  //ParamIXB[1]
	//ID do local de execução do ponto de entrada
	Local cIdPonto //ParamIXB[2]
	//ID do formulário
	Local cIdModel //ParamIXB[3]

	Local xRetorno := .T.

	IF ! Empty(ParamIXB)

		oModel   := ParamIXB[1]
		cIdPonto := ParamIXB[2]
		cIdModel := ParamIXB[3]

		do case

			//Antes da ativação da tela.
			case cIdPonto == "MODELVLDACTIVE"
				//exclusão
				IF oModel:nOperation == MODEL_OPERATION_DELETE
					//tem que usar Help no padrão PE MVC
					Help( ,, "HELP",, "Exclusão não permitida devido integração com WMS.", 1, 0)
					xRetorno := .F.
				EndIF

			//apos a gravação, dentro da transação
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

			case cIdPonto == "BUTTONBAR"

				xRetorno := {}

		endcase

	EndIF

return xRetorno
