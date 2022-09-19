#include 'protheus.ch'
#include 'fwmvcdef.ch'


user function MATA020()

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

			IF u_CChWMSAtivo() .And. oModel:GetValue("MATA020_SA2","A2_CYBERW") == 'S'

				IF oModel:getOperation() == MODEL_OPERATION_INSERT
					//cria o log
					u_CChtoCyberLog('FORNECEDORES', oModel:GetValue("MATA020_SA2","A2_COD") + oModel:GetValue("MATA020_SA2","A2_LOJA"), 'I')
				EndIF
				IF oModel:getOperation() == MODEL_OPERATION_UPDATE
					//cria o log
					u_CChtoCyberLog('FORNECEDORES', oModel:GetValue("MATA020_SA2","A2_COD") + oModel:GetValue("MATA020_SA2","A2_LOJA"), 'A')
				EndIF
			EndIF

		case cIdPonto == "BUTTONBAR"

			xRetorno := {}

		endcase

	EndIF

return xRetorno



user function A020DELE()

	Local lRetorno := .T.

	IF u_CChWMSAtivo()

		//tem que usar Help no padrão PE MVC
		Help( ,, "HELP",, "Exclusão não permitida devido integração com WMS.", 1, 0)

		lRetorno := .F.
	EndIF

Return lRetorno


user function M020INC()

	Local aArea := GetArea()
	Local aButtons := {{.F.,Nil},{.F.,Nil},{.F.,Nil},{.T.,Nil},{.T.,Nil},{.T.,Nil},{.T.,"Salvar"},{.T.,"Cancelar"},{.T.,Nil},{.T.,Nil},{.T.,Nil},{.T.,Nil},{.T.,Nil},{.T.,Nil}}

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
	RestArea(aArea)

	//Return(.T.)

	IF u_CChWMSAtivo() .And. SA2->A2_CYBERW == 'S'
		//cria o log
		u_CChtoCyberLog('FORNECEDORES', SA2->(A2_COD+A2_LOJA), 'I')
	EndIF
	
	If INCLUI .AND. alltrim(funname()) == "MATA020" 
		nOpcao:= Aviso("Casa China","Deseja vincular este fornecedor aos seus produtos?",{"Não","Sim"},3)					
			
		If nOpcao == 2
			FWExecView("GRADE DE PRODUTOS","MATA061",MODEL_OPERATION_INSERT,, { || .T. }, , ,aButtons ) 
		Endif
			
	Endif	
	
return



//user function M020ALT()

//	IF u_CChWMSAtivo() .And. SA2->A2_CYBERW == 'S'
	//cria o log
//		u_CChtoCyberLog('FORNECEDORES', SA2->(A2_COD+A2_LOJA), 'A')
	//	EndIF

//return
