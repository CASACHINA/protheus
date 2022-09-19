
// ####################################################################################################################################################################################################
//
// Projeto   :   
// Modulo    : Faturamento
// Fonte     : M410PVNF
// Data      : 14/08/19
// Autor     : Valberg Moura 
// Descricao : Pondo de entrada na preparacao do documento de saida pela rotina de pedido de venda
//
// ####################################################################################################################################################################################################


#include 'totvs.ch'
#include 'parmtype.ch'
#include 'topconn.ch'


User Function M410PVNF()

    Local _lRet := .T.
    Local _aArea := GetArea()

    If SC5->C5_B2B == 'S'

        _lRet := .F.

        Alert("Pedido de Venda do tipo B2B não poderá ser gerado nota atraves desta rotina, favor gerar a nota pela rotina de Documento de Saida!")

    Endif

    RestArea(_aArea)

Return(_lRet)
