// ####################################################################################################################################################################################################
//
// Projeto   :   
// Modulo    : Financeiro
// Fonte     : uBOLSND1
// Data      : 01/06/2020
// Autor     : Valberg Moura 
// Descricao : Emissao de Boleto Santander Posicionado na SF2
//
// ####################################################################################################################################################################################################

#INCLUDE "RWMAKE.CH"
#INCLUDE "PROTHEUS.CH"
#INCLUDE "TOPCONN.CH"
#INCLUDE "TOTVS.CH"
#Include "colors.ch"
#INCLUDE "Tbiconn.ch"

User Function uBOLSND3()

    Local cQry
    Private _cBanco   := "033"
    Private _cAgencia := "3415"
    Private _cConta   := "0130027105"

    If !MSGYESNO( "Deseja imprimir o booleto Santader da Nota : " + SF2->F2_DOC + " Serie : " + SF2->F2_SERIE + " ? ")
        Return()
    Endif

//--- Seleciona os titulus no contas a receber.

    cQry:= " SELECT 'XX' AS 'OK', E1_FILIAL, E1_PREFIXO, E1_NUM, E1_PARCELA, E1_TIPO, E1_SALDO,E1_VALJUR, E1_NUMBCO, "
    cQry+= " E1_EMISSAO,E1_VENCREA, E1_CLIENTE, E1_LOJA,E1_PORTADO, E1_AGEDEP, E1_CONTA, R_E_C_N_O_ AS 'RECNO'
    cQry+= " FROM "+RetSqlName("SE1")
    cQry+= " WHERE E1_FILIAL = '" + xFilial("SE1") + "' "
    cQry+= " AND E1_PREFIXO  = '" + SF2->F2_SERIE + "' "
    cQry+= " AND E1_NUM 	 = '" + SF2->F2_DOC + "' "
    cQry+= " AND E1_CLIENTE  = '" + SF2->F2_CLIENTE + "' "
    cQry+= " AND E1_LOJA     = '" + SF2->F2_LOJA + "' "
    cQry+= " AND D_E_L_E_T_ = ' ' "
    cQry+= " AND E1_SALDO > 0 "

    if Select("TRBOL01")<>0
        TRBOL01->(DBCloseArea())
    EndIF

    TcQuery cQry New Alias "TRBOL01"

    TRBOL01->(DBSELECTAREA('TRBOL01'))
    TRBOL01->(DBGOTOP())

    //--- Chama rotina de impressao de boleto
    U_uBOLSND2()

Return()
