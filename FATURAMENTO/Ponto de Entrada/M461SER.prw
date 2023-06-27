#INCLUDE "TOTVS.CH"

/*/{Protheus.doc} M461SER
O ponto de entrada é executado APÓS a seleção da série na rotina de documento de saída.
@type function
@version 12.1.25
@author Wlysses Cerqueira (WlyTech)
@since 19/08/2020
/*/

User Function M461SER()

    // TLogConsole():Log("Documento sendo faturado: " + cNumero, "M461SER")

    If FWIsInCallStack("U_TRFFATJOB") .Or. FWIsInCallStack("U_TRFFATAUT") // Apenas para faturamento automatico efertivacao de transferencias da filial 010104.

        cNumero := SD9->D9_DOC

    Else

        cNumero := NxtSX5Nota(cSerie,.T.,SuperGetMV("MV_TPNRNFS"))

    EndIf

 Return()
