#include 'protheus.ch'
#include 'parmtype.ch'
#INCLUDE 'TOPCONN.CH'
#include 'tbiconn.ch'

/*
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
++-----------------------------------------------------------------------------++
++ Fun��o    | MT120GRV | Autor  | Anderson Jose Zelenski  | Data | 13/12/2020 ++
++-----------------------------------------------------------------------------++
++ Descri��o | Continuar ou n�o a inclus�o, altera��o ou exclus�o              ++
++-----------------------------------------------------------------------------++
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
*/

User Function MT120GRV()
Local cNumPC  	:= PARAMIXB[1] //numero do pedido
//Local lInclui  	:= PARAMIXB[2]
Local lAltera 	:= PARAMIXB[3] //se esta alterado vai estar como true
Local lExclui 	:= PARAMIXB[4] // se esta excluido 
Local lRet 		:= .T.
Local cQry		:= ""

	If lAltera .Or. lExclui
		
		// Busca os c�digos das solicita��es do Fluig
		cQry := " SELECT DISTINCT CR_FLUIG AS IDFLUIG "
		cQry += " FROM "+RetSqlName("SCR")+" SCR "
		cQry += " WHERE SCR.CR_FILIAL = '"+xFilial("SCR")+"' "
		cQry += "		AND SCR.CR_NUM = '"+cNumPC+"' "
		cQry += "		AND SCR.CR_TIPO IN ('PC','IP') "
		cQry += " 	AND SCR.D_E_L_E_T_ = ' ' "
		cQry += " ORDER BY 1 "
		
		If Select('QRY') <> 0
		DbSelectArea('QRY')
			DbCloseArea()
		Endif
		
		TCQUERY cQry NEW ALIAS "QRY"
		
		While !QRY->(Eof())
			// Chama a fun��o para cancelar a solicita��o no Fluig
			If lAltera
				CancelaFluig(Val(AllTrim(QRY->IDFLUIG)), "Pedido alterado")
			Else
				CancelaFluig(Val(AllTrim(QRY->IDFLUIG)), "Pedido exclu�do")
			EndIf
			
			QRY->(DbSkip())
		EndDo
	EndIf
Return lRet

/*
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
++-----------------------------------------------------------------------------++
++ Fun��o    | CancelaFluig | Autor | Anderson Jose Zelenski | Data | 13/12/20 ++
++-----------------------------------------------------------------------------++
++ Descri��o | Cancela no Fluig a Solicita��o do WF de Pedidos de Compras      ++
++-----------------------------------------------------------------------------++
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
*/

Static Function CancelaFluig(nIdFluig, cComentario)
Local cFluigUsr 	:= AllTrim(GetMv("MV_FLGUSER"))
Local cFluigPss		:= AllTrim(GetMv("MV_FLGPASS"))
Local cFluigMatr 	:= AllTrim(GetMv("MV_FLGMATR"))
Local nCompany		:= 1
Local oFluigWrk
Local cRetorno		:= ""

	// Inicia o Objeto do WebService com o Processo a ser iniciado no Fluig
	oFluigWrk := WSECMWorkflowEngineService():New()
	
	// Cancela o Processo no Fluig
	If oFluigWrk:cancelInstance(cFluigUsr, cFluigPss, nCompany, nIdFluig, cFluigMatr, cComentario)
		cRetorno := oFluigWrk:cresult
		conout("Cancelamento Fluig: "+cRetorno)
	Else
		conout("Processo n�o integrado com o Fluig")
	EndIf

Return
