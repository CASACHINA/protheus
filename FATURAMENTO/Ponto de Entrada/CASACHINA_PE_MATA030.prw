#include 'protheus.ch'
#include 'fwmvcdef.ch'


user function MATA030()

	//Objeto do formulário ou do modelo, conforme o caso.
	Local oModel  //ParamIXB[1]
	//ID do local de execução do ponto de entrada
	Local cIdPonto //ParamIXB[2]
	//ID do formulário
	Local cIdModel //ParamIXB[3]

	Local xRetorno := .T.

	Local oObjCyberLog := Nil

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

			IF u_CChWMSAtivo() .And. oModel:GetValue("MATA030_SA1","A1_CYBERW") == 'S'

				IF oModel:getOperation() == MODEL_OPERATION_INSERT
					//cria o log
					u_CChtoCyberLog('CLIENTES', oModel:GetValue("MATA030_SA1","A1_COD") + oModel:GetValue("MATA030_SA1","A1_LOJA"), 'I')
				EndIF
				IF oModel:getOperation() == MODEL_OPERATION_UPDATE
					//cria o log
					u_CChtoCyberLog('CLIENTES', oModel:GetValue("MATA030_SA1","A1_COD") + oModel:GetValue("MATA030_SA1","A1_LOJA"), 'A')
				EndIF
			EndIF

			//If oModel:GetValue("MATA030_SA1","A1_CYBERW") == 'S'

				oObjCyberLog := TCyberlogIntegracao():New()

				oObjCyberLog:SendCustomer(oModel:getOperation() == MODEL_OPERATION_INSERT, .F., oModel:getOperation() == MODEL_OPERATION_UPDATE, oModel:getOperation() == MODEL_OPERATION_DELETE)
				
				If !Empty(oObjCyberLog:oEmpAuth:cDepositoB2B)
				
					oObjCyberLog:cDeposito := oObjCyberLog:oEmpAuth:cDepositoB2B

					oObjCyberLog:SendCustomer(oModel:getOperation() == MODEL_OPERATION_INSERT, .F., oModel:getOperation() == MODEL_OPERATION_UPDATE, oModel:getOperation() == MODEL_OPERATION_DELETE)
				
				EndIf

			//EndIf

		Case cIdPonto == "FORMCOMMITTTSPOS"

		case cIdPonto == "BUTTONBAR"

			xRetorno := {}

		endcase

	EndIF

return xRetorno


user function M030DEL()

	Local lRetorno := .T.

	IF u_CChWMSAtivo()

		//tem que usar Help no padrão PE MVC
		Help( ,, "HELP",, "Exclusão não permitida devido integração com WMS.", 1, 0)

		lRetorno := .F.
	EndIF

Return lRetorno



user function M030INC()


	Local aArea := GetArea()
	Local oObjCyberLog := Nil

	DbSelectArea("CTH")
	CTH->(DbSetOrder(1))
	If !(CTH->(DbSeek(xFilial("CTH")+"C"+ALLTRIM(SA1->A1_COD)+ALLTRIM(SA1->A1_LOJA))))
		RecLock("CTH",.T.)
		CTH->CTH_FILIAL	:= xFilial("CTH")
		CTH->CTH_CLVL	:= "C"+ALLTRIM(SA1->A1_COD)+ALLTRIM(SA1->A1_LOJA)
		CTH->CTH_CLASSE	:= "2"
		CTH->CTH_DESC01	:= SA1->A1_NOME
		CTH->CTH_NORMAL := "2"
		CTH->CTH_DTEXIS := CTOD("01/01/18")
		CTH->CTH_CLVLLP := "C"+ALLTRIM(SA1->A1_COD)+ALLTRIM(SA1->A1_LOJA)
		CTH->CTH_CLSUP  := 'C'
		CTH->(MsUnLock())
	Else
		RecLock("CTH",.F.)
		CTH->CTH_FILIAL	:= xFilial("CTH")
		CTH->CTH_CLVL	:= "C"+ALLTRIM(SA1->A1_COD)+ALLTRIM(SA1->A1_LOJA)
		CTH->CTH_CLASSE	:= "2"
		CTH->CTH_DESC01	:= SA1->A1_NOME
		CTH->CTH_NORMAL := "2"
		CTH->CTH_DTEXIS := CTOD("01/01/18")
		CTH->CTH_CLVLLP := "C"+ALLTRIM(SA1->A1_COD)+ALLTRIM(SA1->A1_LOJA)
		CTH->CTH_CLSUP  := 'C'
		CTH->(MsUnLock())
	EndIF

	RestArea(aArea)

//Return(.T.)



	IF u_CChWMSAtivo() .And. SA1->A1_CYBERW == 'S'
		//cria o log
		u_CChtoCyberLog('CLIENTES', SA1->(A1_COD+A1_LOJA), 'I')
	EndIF

	If PARAMIXB == 0 // Clicou em OK

		oObjCyberLog := TCyberlogIntegracao():New()

		oObjCyberLog:SendCustomer(INCLUI, .F., ALTERA, .F.)

	ElseIf PARAMIXB == 3 // Clicou em cancelar

	EndIf

return

user function MALTCLI()

	Local oObjCyberLog := Nil

	IF u_CChWMSAtivo() .And. SA1->A1_CYBERW == 'S'
		//cria o log
		u_CChtoCyberLog('CLIENTES', SA1->(A1_COD+A1_LOJA), 'A')
	EndIF

	oObjCyberLog := TCyberlogIntegracao():New()

	oObjCyberLog:SendCustomer(INCLUI, .F., ALTERA, .F.)

return
