#INCLUDE "TOTVS.CH"

/*/{Protheus.doc} SF1140I
PE para incluir opcao no menu
@type function
@version 12.1.25
@author Wlysses Cerqueira (WlyTech)
@since 19/08/2020
/*/

User Function CYBER002(nAcao)

	Local aArea		:= GetArea()
	Local oCyberLog := TCyberLogIntegracao():New()

	oCyberLog:GenericRun(nAcao)

	RestArea(aArea)

Return()
