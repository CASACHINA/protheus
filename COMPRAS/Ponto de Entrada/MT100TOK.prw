#INCLUDE "TOTVS.CH"

/*/{Protheus.doc} SF1140I
PE para incluir opcao no menu
@type function
@version 12.1.25
@author Wlysses Cerqueira (WlyTech)
@since 19/08/2020
/*/

User Function MT100TOK()

	Local lRetorno := .T.
    Local oCyberLog := TCyberLogIntegracao():New()

	// Ir� fazer as valida��es abaixo quando n�o for chamado atrav�s do Importador Conex�oNfe ou Quando for pelo Conex�oNfe e
	// esteja na tela do Documento de Entrada
	If !FwIsInCallStack('U_GATI001') .Or. (FwIsInCallStack('U_GATI001') .And. !FwIsInCallStack('U_Retorna') .And. !FwIsInCallStack('GeraConhec') .And. !l103Auto)
		// If
		//     Regra existente
		//     [...]
		// EndIf

        lRetorno := oCyberLog:ValidEnvioPreNota(.T.)

	EndIf

	If lRetorno

		// Ponto de chamada Conex�oNF-e
		lRetorno := U_GTPE005()
	
    EndIf

Return(lRetorno)
