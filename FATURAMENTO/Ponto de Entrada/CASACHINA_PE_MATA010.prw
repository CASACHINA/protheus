#include 'protheus.ch'
#include 'fwmvcdef.ch'


/*/{Protheus.doc} ITEM
Ponto de entrada da rotina de Cadastro de Produtos

@author Rafael Ricardo Vieceli
@since 26/03/2018
@version 1.0

@type function
/*/
user function ITEM()

	//Objeto do formulário ou do modelo, conforme o caso.
	Local oModel  //ParamIXB[1]
	//ID do local de execução do ponto de entrada
	Local cIdPonto //ParamIXB[2]
	//ID do formulário
	Local cIdModel //ParamIXB[3]

	Local xRetorno := .T.
	Local oObjCyberLog := Nil
	Local cFilBkp := ""

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

			IF u_CChWMSAtivo() .And. oModel:GetValue("SB1MASTER","B1_CYBERW") == 'S'

				IF oModel:getOperation() == MODEL_OPERATION_INSERT
					//cria o log
					u_CChtoCyberLog('PRODUTOS', oModel:GetValue("SB1MASTER","B1_COD"), 'I')
				EndIF
				IF oModel:getOperation() == MODEL_OPERATION_UPDATE
					//cria o log
					u_CChtoCyberLog('PRODUTOS', oModel:GetValue("SB1MASTER","B1_COD"), 'A')
				EndIF
			EndIF

			If oModel:GetValue("SB1MASTER","B1_CYBERW") == "S"

				// O WS para o fluig starta a filial 010101, logo ao fazer um cad de produtos
				// nao entra na integracao pois a parametrizacao na ZA2, esta para 010104
				// Como o cadastro é compartilhado, optei por fazer dessa forma, sem ter que 
				// alterar o fonte WsPedCom, pois existe outro fornecedor trabalhando no mesmo.
				If cFilAnt <> "010104"

					cFilBkp := cFilAnt

					cFilAnt := "010104"

				EndIf

				oObjCyberLog := TCyberlogIntegracao():New()

				oObjCyberLog:SendProduct(oModel:getOperation() == MODEL_OPERATION_INSERT, .F., oModel:getOperation() == MODEL_OPERATION_UPDATE, oModel:getOperation() == MODEL_OPERATION_DELETE)

				If !Empty(oObjCyberLog:oEmpAuth:cDepositoB2B)
				
					oObjCyberLog:cDeposito := oObjCyberLog:oEmpAuth:cDepositoB2B

					oObjCyberLog:SendProduct(oModel:getOperation() == MODEL_OPERATION_INSERT, .F., oModel:getOperation() == MODEL_OPERATION_UPDATE, oModel:getOperation() == MODEL_OPERATION_DELETE)
				
				EndIf

				cFilAnt := cFilBkp

			EndIf

		Case cIdPonto == "FORMCOMMITTTSPOS"

			  /*	If Inclui
					U_GT12M003("SB1","INCLUI")
		ElseIf Altera
					U_GT12M003("SB1","ALTERA")
		Else
					U_GT12M003("SB1","EXCLUI")
		EndIf
                */

		case cIdPonto == "BUTTONBAR"

			xRetorno := {}

		endcase

	EndIF

return xRetorno



/*/{Protheus.doc} MTA010Ok
Desabilita a exclusao de produto devido a integração com WMS

@author Rafael Ricardo Vieceli
@since 07/03/2017
@version undefined

@type function
/*/
user function MTA010Ok()

	Local lRetorno := .T.

	IF u_CChWMSAtivo()
		//tem que usar Help no padrão PE MVC
		Help( ,, "HELP",, "Exclusão não permitida devido integração com WMS.", 1, 0)
		lRetorno := .F.
	EndIF

Return lRetorno




/*/{Protheus.doc} MT010INC
Envia para o WMS na inclusao

@author Rafael Ricardo Vieceli
@since 07/03/2017
@version undefined

@type function
/*/
user function MT010INC()

	Local aArea := GetArea()

	If INCLUI
		DbSelectArea("CTH")
		CTH->(DbSetOrder(1))

		If !(CTH->(DbSeek(xFilial("CTH")+"F"+ALLTRIM(SA2->A2_COD)+ALLTRIM(SA2->A2_LOJA))))
			RecLock("CTH",.T.)
			CTH->CTH_FILIAL	:= xFilial("CTH")
			CTH->CTH_CLVL	:= "F"+ALLTRIM(SA2->A2_COD)+ALLTRIM(SA2->A2_LOJA)
			CTH->CTH_CLASSE	:= "2"
			CTH->CTH_DESC01	:= SA2->A2_NOME
			CTH->CTH_NORMAL := "1"
			CTH->CTH_DTEXIS := CTOD("01/01/18")
			CTH->CTH_CLVLLP := "F"+ALLTRIM(SA2->A2_COD)+ALLTRIM(SA2->A2_LOJA)
			CTH->CTH_CLSUP  := 'F'
			CTH->(MsUnLock())
		Else
			RecLock("CTH",.F.)
			CTH->CTH_FILIAL	:= xFilial("CTH")
			CTH->CTH_CLVL	:= "F"+ALLTRIM(SA2->A2_COD)+ALLTRIM(SA2->A2_LOJA)
			CTH->CTH_CLASSE	:= "2"
			CTH->CTH_DESC01	:= SA2->A2_NOME
			CTH->CTH_NORMAL := "1"
			CTH->CTH_DTEXIS := CTOD("01/01/18")
			CTH->CTH_CLVLLP := "F"+ALLTRIM(SA2->A2_COD)+ALLTRIM(SA2->A2_LOJA)
			CTH->CTH_CLSUP  := 'F'
			CTH->(MsUnLock())
		EndIF


	EndIf
//RestArea(aArea)

	U_RT002() // Funcao para inserir saldo zerado na SB2 (Utilizado pela transferencia entre filiais)

	IF u_CChWMSAtivo() .And. SB1->B1_CYBERW == 'S'
		//cria o log
		u_CChtoCyberLog('PRODUTOS', SB1->B1_COD, 'I')
	EndIF

	RestArea(aArea)

return




/*/{Protheus.doc} MT010ALT
Envia para o WMS na alteração

@author Rafael Ricardo Vieceli
@since 07/03/2017
@version undefined

@type function
/*/
user function MT010ALT()

	U_RT002() // Funcao para inserir saldo zerado na SB2 (Utilizado pela transferencia entre filiais)


	IF u_CChWMSAtivo() .And. SB1->B1_CYBERW == 'S'
		//cria o log
		u_CChtoCyberLog('PRODUTOS', SB1->B1_COD, 'A')
	EndIF

return
