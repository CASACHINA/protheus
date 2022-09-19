#include "Protheus.ch"
#include "TopConn.ch"

/*/{Protheus.doc} MT100LOK
PE para validar linha na digitacao no Documento de Entrada
@author Paulo Cesar Camata
@since 03/12/2017
@version 12
@type function
/*/
user function MT100LOK()

	//	local nLin     := n   
	
	// Ponto de chamada ConexãoNF-e
	If FwIsInCallStack('U_GATI001')
		U_GTPE004()
	EndIf

	If !FwIsInCallStack('U_GATI001') .Or. !l103Auto
		/*dbSelectArea("SB1")
		SB1->(dbSetOrder(1))
		if !aCols[nLin, Len(aHeader) + 1] // Linha nao deletada
			if SB1->(dbSeek(xFilial("SB1") + xFilial("SB1") + aCols[nLin, gdFieldPos("D1_COD")])) .and. SB1->B1_YFORLIN == "S"
				msgStop("Não é possível inserir um produto fora de linha. Verifique.")
				return .F.
			endif
		endif    */
	EndIf

return .T.

/*/{Protheus.doc} fProjet
Funcao para verificar se a SC do Pedido possui Projeto informado
@author Paulo Cesar Camata
@since 14/06/2017
@version 12.1.14
@param cNumPed, characters, Numero Pedido
@param cItePed, characters, Item Pedido
@type function
/*/
static function fProjet(cNumPed, cItePed)

	local _lAchou := .F.
	local _cSelect

	if !empty(cNumPed) .AND. !empty(cItePed) // Numero do Pedido e Item devem estar preenchidos

		_cSelect := "SELECT COUNT(1) C1_QTDE " + CRLF
		_cSelect += "  FROM " + retSqlName("SC7") + " SC7 " + CRLF
		_cSelect += "  JOIN " + retSqlName("SC1") + " SC1 " + CRLF
		_cSelect += "    ON C1_FILIAL      = C7_FILIAL " + CRLF
		_cSelect += "   AND C1_NUM         = C7_NUMSC  " + CRLF
		_cSelect += "   AND C1_ITEM        = C7_ITEMSC " + CRLF
		_cSelect += "   AND SC1.D_E_L_E_T_ = '' " + CRLF
		_cSelect += "  JOIN " + retSqlName("AFG") + " AFG " + CRLF
		_cSelect += "    ON AFG_FILIAL     = C1_FILIAL " + CRLF
		_cSelect += "   AND AFG_NUMSC      = C1_NUM " + CRLF
		_cSelect += "   AND AFG_ITEMSC     = C1_ITEM " + CRLF
		_cSelect += "   AND AFG.D_E_L_E_T_ = '' " + CRLF
		_cSelect += " WHERE C7_FILIAL      = " + valToSql(xFilial("SC7")) + CRLF
		_cSelect += "   AND C7_NUM         = " + valToSql(cNumPed) + CRLF
		_cSelect += "   AND C7_ITEM        = " + valToSql(cItePed) + CRLF
		_cSelect += "   AND SC7.D_E_L_E_T_ = '' " + CRLF

		tcQuery _cSelect Alias "PROJET" new

		if !PROJET->(EoF()) .AND. PROJET->C1_QTDE > 0
			_lAchou := .T.
		endIf
		PROJET->(dbCloseArea())
	endif

return _lAchou

/*/{Protheus.doc} AltAFN
Funcao para atualizar aRATAFN
@author Paulo Cesar Camata
@since 26/09/2017
@version 12
@type function
/*/
user function AltAFN()
	local nLin := n

	if len(aRatAFN) > 0 .AND. !empty(aCols[nLin, gdFieldPos("D1_PEDIDO")])
		posicione("SC7", 1, xFilial("SC7") + aCols[nLin, gdFieldPos("D1_PEDIDO")] + aCols[nLin, gdFieldPos("D1_ITEMPC")], "FOUND()")
		if posicione("AFG", 2, xFilial("AFG") + SC7->C7_NUMSC + SC7->C7_ITEMSC, "FOUND()") // Verificando se a SC possui projeto
			aRatAFN[nLin, 2, 1] := { AFG->AFG_PROJET, AFG->AFG_TAREFA, aCols[nLin, gdFieldPos("D1_QUANT")], AFG->AFG_TRT, AFG->AFG_REVISA, AFG->AFG_QTSEGU, "1", criaVar("AFN_ID", .F.), criaVar("AFN_CONTRA", .F.), "AFN", 0, .F.}
		endif
	endif

return .T.
