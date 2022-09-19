#include 'protheus.ch'
#include 'parmtype.ch'
#INCLUDE 'TOPCONN.CH'
#include 'tbiconn.ch'

/*
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
++-----------------------------------------------------------------------------++
++ Função    | MT097APR | Autor  | Anderson Jose Zelenski  | Data | 13/12/2020 ++
++-----------------------------------------------------------------------------++
++ Descrição | Continuar ou não a inclusão, alteração ou exclusão              ++
++-----------------------------------------------------------------------------++
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
*/

User Function MT097APR()
	// Chama a função para cancelar a solicitação no Fluig
	If !Empty(SCR->CR_FLUIG)
		CancelaFluig(Val(AllTrim(SCR->CR_FLUIG)), "Pedido aprovado via Protheus")	
	EndIf
			
Return .t.

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
