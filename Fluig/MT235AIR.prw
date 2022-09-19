#include 'protheus.ch'
#include 'parmtype.ch'
#INCLUDE 'TOPCONN.CH'
#include 'tbiconn.ch'

/*
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
++-----------------------------------------------------------------------------++
++ Função    | MT235AIR | Autor  | Sandro A Nascimento  	 Data | 29/09/2021 ++
++-----------------------------------------------------------------------------++
++ Descrição | PE elemina residuos de pedido de compra                         ++
++-----------------------------------------------------------------------------++
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
*/




User Function MT235AIR()
Local cTipo := ParamIXB[2]
Local cQry		:= ""

	If cTipo = 1 .AND. SC7->C7_CONAPRO == 'B'
		
		// Busca os códigos das solicitações do Fluig
		cQry := " SELECT MAX(CR_FLUIG)  AS IDFLUIG "
		cQry += " FROM "+RetSqlName("SCR")+" SCR "
		cQry += " WHERE SCR.CR_FILIAL = '"+xFilial("SCR")+"' "
		cQry += "		AND SCR.CR_NUM = '"+SC7->C7_NUM+"' "
		cQry += "		AND SCR.CR_TIPO IN ('PC','IP') "
		//cQry += " 	AND SCR.D_E_L_E_T_ = ' ' "
		//cQry += " ORDER BY 1 "
		
		If Select('QRY') <> 0
		DbSelectArea('QRY')
			DbCloseArea()
		Endif
		
		TCQUERY cQry NEW ALIAS "QRY"
		
		While !QRY->(Eof())
			// Chama a função para cancelar a solicitação no Fluig
			
			CancelaFluig(Val(AllTrim(QRY->IDFLUIG)), "Pedido eliminado como resíduo")
			
			
			
			QRY->(DbSkip())
		EndDo
	EndIf
Return nil

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
