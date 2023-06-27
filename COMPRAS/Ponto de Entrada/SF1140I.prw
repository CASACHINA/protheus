#INCLUDE "TOTVS.CH"

/*/{Protheus.doc} SF1140I
PE para incluir opcao no menu
@type function
@version 12.1.25
@author Wlysses Cerqueira (WlyTech)
@since 19/08/2020
/*/
User Function SF1140I()

    Local oCyberLog := TCyberLogIntegracao():New()

    oCyberLog:SendDocEntrada(INCLUI, .F., ALTERA, .F.)

Return()
