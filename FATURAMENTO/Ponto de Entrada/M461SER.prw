#INCLUDE "TOTVS.CH"

/*/{Protheus.doc} M461SER
O ponto de entrada � executado AP�S a sele��o da s�rie na rotina de documento de sa�da.
@type function
@version 12.1.25
@author Wlysses Cerqueira (WlyTech)
@since 19/08/2020
/*/

User Function M461SER()

    // cNumero := NxtSX5Nota(cSerie,.T.,SuperGetMV("MV_TPNRNFS")) // Apenas para nao mostrar tela na JOB TRFFATAUT

    // TLogConsole():Log("Documento sendo faturado: " + cNumero, "M461SER")

    If FWIsInCallStack("U_TRFFATJOB") .Or. FWIsInCallStack("U_TRFFATAUT")

        cNumero := SD9->D9_DOC

    EndIf

Return()
