
// ####################################################################################################################################################################################################
//
// Projeto   :   
// Modulo    : Faturamento
// Fonte     : M460MARK
// Data      : 14/08/19
// Autor     : Valberg Moura 
// Descricao : Pondo de entrada para validar a seleceção de itens na geração da Nota
//
// ####################################################################################################################################################################################################

#include 'totvs.ch'
#include 'parmtype.ch'
#include 'topconn.ch'


User function M460MARK()

    Local _lRet     := .T.
    Local _aArea    := GetArea()
    Local oCyberLog := TCyberLogIntegracao():New()

	If !oCyberLog:ValidEnvioPedidoM460MARK(PARAMIXB)

		_lRet := .F.
	
	EndIf 

    //SC9->(DbGoTop())

    // While (SC9->(!EOF()))

        If _lRet .And. u_CChWMSAtivo() .And. SC9->(IsMark("C9_OK"))

            DBSelectArea("SC5")
            DBSetOrder(1)
            DBSeek(SC9->C9_FILIAL+SC9->C9_PEDIDO)

            If SC5->C5_B2B == 'S'


                //Verifica se o item já esta liberado no WMS

                _cQry := " SELECT * FROM TOTVS_CYBERLOG_SAIDA "
                _cQry += " WHERE COD_CYBERLOG_SAIDA = '"+ xFilial("SC9") + Alltrim(SC9->C9_PEDIDO) + "' "
                _cQry += " AND CODIGO_PRODUTO = '"+Alltrim(SC9->C9_PRODUTO)+"'"
                TcQuery _cQry New Alias "TRSC9"

                If Alltrim(TRSC9->(CODIGO_PRODUTO)) == ''

                    _lRet := .F.

                    Alert("O produto "+Alltrim(SC9->C9_PRODUTO)+ " não esta liberado pelo WMS para emissao de Nota, favor verificar a separação do produto no WMS")

                Endif

                TRSC9->(DbCloseArea())

            Endif
        Endif

       // SC9->(DbSkip())

    //EndDo

    RestArea(_aArea)

Return(_lRet)
