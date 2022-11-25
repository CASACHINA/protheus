#INCLUDE "TOTVS.CH"

/*/{Protheus.doc} M461SER
O ponto de entrada � executado ap�s a sele��o da s�rie na rotina de documento de sa�da.
@type function
@version 12.1.25
@author Wlysses Cerqueira (WlyTech)
@since 19/08/2020
/*/

User Function M461SER()

    cNumero := NxtSX5Nota(cSerie,.T.,SuperGetMV("MV_TPNRNFS")) // Apenas para nao mostrar tela na JOB TRFFATAUT

Return()
