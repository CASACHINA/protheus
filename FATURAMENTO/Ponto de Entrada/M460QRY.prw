#INCLUDE "TOTVS.CH"

/*/{Protheus.doc} M460QRY
PE para incluir opcao no menu
@type function
@version 12.1.25
@author Wlysses Cerqueira (WlyTech)
@since 19/08/2020
/*/

Static _cM460QRY_ := ""

User function M460QRY()

    Local cQuery := PARAMIXB[1]

    // ATENCAO: se for ajustar o codigo avalie o metodo ValidEnvioPedidoM460MARK!
    _cM460QRY_ := cQuery

Return(cQuery)

User Function XM460QRY()
Return(_cM460QRY_)
