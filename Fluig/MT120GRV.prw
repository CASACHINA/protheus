#include 'protheus.ch'
#include 'parmtype.ch'
#INCLUDE 'TOPCONN.CH'
#include 'tbiconn.ch'

/*
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
++-----------------------------------------------------------------------------++
++ Função    | MT120GRV | Autor  | Anderson Jose Zelenski  | Data | 13/12/2020 ++
++-----------------------------------------------------------------------------++
++ Descrição | Continuar ou não a inclusão, alteração ou exclusão              ++
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
		
		// Busca os códigos das solicitações do Fluig
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
			// Chama a função para cancelar a solicitação no Fluig
			If lAltera
				CancelaFluig(Val(AllTrim(QRY->IDFLUIG)), "Pedido alterado")
			Else
				CancelaFluig(Val(AllTrim(QRY->IDFLUIG)), "Pedido excluído")
			EndIf
			
			QRY->(DbSkip())
		EndDo
	EndIf
Return lRet

/*
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
++-----------------------------------------------------------------------------++
++ Função    | CancelaFluig | Autor | Anderson Jose Zelenski | Data | 13/12/20 ++
++-----------------------------------------------------------------------------++
++ Descrição | Cancela no Fluig a Solicitação do WF de Pedidos de Compras      ++
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
		conout("Processo não integrado com o Fluig")
	EndIf

Return
