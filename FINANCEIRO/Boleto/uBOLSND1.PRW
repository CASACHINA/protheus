
// ####################################################################################################################################################################################################
//
// Projeto   :   
// Modulo    : Financeiro
// Fonte     : uBOLSND1
// Data      : 01/06/2020
// Autor     : Valberg Moura 
// Descricao : Emissao de Boleto Santander
//
// ####################################################################################################################################################################################################

#INCLUDE "RWMAKE.CH"
#INCLUDE "PROTHEUS.CH"
#INCLUDE "TOPCONN.CH"
#INCLUDE "TOTVS.CH"
#Include "colors.ch"
#INCLUDE "Tbiconn.ch"

User Function uBOLSND1()
	Local oDlg1
	Local oBtnGerar
	Local oBtnSair
	Local aDesc      := {	"Este programa imprime os boletos de",;
		"cobranca bancaria de acordo com",;
		"os parametros informados"}

	Private cPerg := "uBOLSND1"

	Private _cBanco   := "033"
	Private _cAgencia := "3415"
	Private _cConta   := "0130027105"

	//validPerg()
	Pergunte (cPerg,.F.)


	DEFINE MSDIALOG oDlg1 TITLE "Impressão de Boletos" FROM 000, 000  TO 150, 300 PIXEL

	@ 014, 002 SAY "Programa para emissão de boletos." PIXEL
	//@ 026, 002 SAY "Todos os títulos deverão estar em bordero." PIXEL
	@ 055, 010 BUTTON oBtnParam PROMPT "Parametros" SIZE 030, 010 ACTION Eval({|| Pergunte(cPerg) }) OF oDlg1 PIXEL
	@ 055, 060 BUTTON oBtnGerar PROMPT "Gerar" SIZE 030, 010 ACTION Eval({|| SELSE1(),close(oDlg1) }) OF oDlg1 PIXEL
	@ 055, 120 BUTTON oBtnSair  PROMPT "Sair" SIZE 030, 010 action Eval({|| close(oDlg1) }) OF oDlg1 PIXEL

	ACTIVATE MSDIALOG oDlg1 CENTERED


Return nil



/*/{Protheus.doc} SELSE1
(MarkBrowse para a selecao de titulos )
@author Valberg Moura
@since 06/06/2020
@version 1.0
/*/
Static Function SELSE1()
	Local aEstr		:= SE1->(DbStruct())
	Private cMarca := GetMark(), lInverte := .f.

	aCampos := {}

	cQry:= " SELECT E1_FILIAL, E1_PREFIXO, E1_NUM, E1_PARCELA, E1_TIPO, E1_SALDO,E1_VALJUR, E1_NUMBCO, "
	cQry+= " E1_EMISSAO,E1_VENCREA, E1_CLIENTE, E1_LOJA,E1_PORTADO, E1_AGEDEP, E1_CONTA
	cQry+= " FROM "+RetSqlName("SE1") + " SE1 "
	cQry+= " WHERE E1_FILIAL = '" + xFilial("SE1") + "' "
	cQry+= " AND E1_PREFIXO Between '" + MV_PAR01 + "' AND '" + MV_PAR02 + "' "
	cQry+= " AND E1_NUM 	Between '" + MV_PAR03 + "' AND '" + MV_PAR04 + "' "
	cQry+= " AND E1_PARCELA Between '" + MV_PAR05 + "' AND '" + MV_PAR06 + "' "
	cQry+= " AND E1_NUMBOR 	Between '" + MV_PAR13 + "' AND '" + MV_PAR14 + "' "
	cQry+= " AND E1_CLIENTE Between '" + MV_PAR07 + "' AND '" + MV_PAR08 + "' "
	cQry+= " AND E1_EMISSAO Between '" + DTOS(MV_PAR11) + "' AND '" + DTOS(MV_PAR12) + "' "
	cQry+= " AND E1_VENCREA Between '" + DTOS(MV_PAR09) + "' AND '" + DTOS(MV_PAR10) + "' "
//	cQry+= " AND E1_PORTADO <> ''"
	cQry+= " AND SE1.D_E_L_E_T_ = ' ' "
	cQry+= " AND E1_SALDO > 0 "


	Aadd(aEstr, {"OK","C",2,0})
	Aadd(aEstr, {"RECNO","N",10,0})

	//cNomeArq := CriaTrab(aEstr)

	if Select("TRBOL01")<>0
		TRBOL01->(DBCloseArea())
	EndIF

	//dbUseArea(.T.,__LocalDriver,cNomeArq,'TRBOL01',.F.)

	oTempTable := FWTemporaryTable():New( "TRBOL01" )
	oTemptable:SetFields( aEstr )
	oTempTable:Create()

	Processa({||SqlToTrb(cQry, aEstr, "TRBOL01")}) // Cria arquivo temporario

	IndRegua ('TRBOL01',cNomeArq,"TRBOL01->E1_FILIAL+TRBOL01->E1_NUM+TRBOL01->E1_PARCELA",,,"Selecionando Registros...")

	aCampos := {}
	AADD(aCampos,{"OK",""," "})
	AADD(aCampos,{"E1_NUM","","Titulo"})
	AADD(aCampos,{"E1_PARCELA","","Parcela"})   // Nao precisa por Picture
	AADD(aCampos,{"E1_EMISSAO","","Emissao"})
	AADD(aCampos,{"E1_VENCREA","","Vencimento"})
	AADD(aCampos,{"E1_CLIENTE","","Cliente"})
	AADD(aCampos,{"E1_LOJA","","Loja"})
	AADD(aCampos,{"E1_PORTADO","","Portador"})

	TRBOL01->(DBSELECTAREA('TRBOL01'))
	TRBOL01->(DBGOTOP())
	@ 001,001 TO 400,700 DIALOG oDlg TITLE "Selecao de Titulos"

	oMark := MsSelect():New("TRBOL01","OK",,aCampos,@lInverte,@cMarca,{18,3,180,350})
	oMark:oBrowse:bHeaderClick := {|oBrw,nCol| marcdesm(oDlg),oMark:oBrowse:SetFocus(),oMark:oBrowse:Refresh()}
	AddColMark(oMark,"OK")
	@ 18,10 BUTTON "Inverte"  SIZE 33,10 ACTION marcdesm(oDlg)
	@ 18,40 BUTTON "Cancelar" SIZE 33,10 ACTION (Exec := .F.,Close(oDlg))
	@ 18,60 BUTTON "Imprimir" SIZE 33,10 ACTION (Exec := .T.,filtrabol(oDlg))
	ACTIVATE DIALOG oDlg CENTERED

Return

Static Function filtrabol(oDlg)
	U_uBOLSND2()
	Close(oDlg)
Return

Static Function  marcdesm(oDlg)
	dbSelectArea("TRBOL01")
	DBGotop()
	WHILE !TRBOL01->(EOF())
		If !Empty(TRBOL01->OK)
			RECLOCK("TRBOL01",.F.)
			TRBOL01->OK := ""
			MsUnlock()
		Else
			RECLOCK("TRBOL01",.F.)
			TRBOL01->OK := GetMark()
			MsUnlock()
		EndIF
		DbSkip()
	EndDo

	dlgRefresh(oDlg)
	dbgotop()
return

Static Function ValidPerg

	_cAlias := Alias()
	cPerg := "uBOLSND1"
	//xPutSx1(cPerg, "01", "Prefixo de"             , "", "", "mv_ch1" , "C", 03,  0, 0, "G", "", ""   , "", "", "mv_par01", "","","","","","","","","","","","","","","","")
	//xPutSx1(cPerg, "02", "Prefixo Ate"            , "", "", "mv_ch2" , "C", 03,  0, 0, "G", "", ""   , "", "", "mv_par02", "","","","","","","","","","","","","","","","")
	//xPutSx1(cPerg, "03", "Titulo de"              , "", "", "mv_ch3" , "C", 09,  0, 0, "G", "", "SE1", "", "", "mv_par03", "","","","","","","","","","","","","","","","")
	//xPutSx1(cPerg, "04", "Titulo Ate"             , "", "", "mv_ch4" , "C", 09,  0, 0, "G", "", "SE1", "", "", "mv_par04", "","","","","","","","","","","","","","","","")
	//xPutSx1(cPerg, "05", "Parcela De"             , "", "", "mv_ch5" , "C", 02,  0, 0, "G", "", "", "", "", "mv_par05", "","","","","","","","","","","","","","","","")
	//xPutSx1(cPerg, "06", "Parcela Ate"            , "", "", "mv_ch6" , "C", 02,  0, 0, "G", "", ""   , "", "", "mv_par06", "","","","","","","","","","","","","","","","")
	//xPutSx1(cPerg, "07", "Cliente de"             , "", "", "mv_ch7" , "C", 09,  0, 0, "G", "", "SA1", "", "", "mv_par07", "","","","","","","","","","","","","","","","")
	//xPutSx1(cPerg, "08", "Cliente Ate"            , "", "", "mv_ch8" , "C", 09,  0, 0, "G", "", "SA1", "", "", "mv_par08", "","","","","","","","","","","","","","","","")
	//xPutSx1(cPerg, "09", "Vencimento de"          , "", "", "mv_ch9" , "D", 08,  0, 0, "G", "", ""   , "", "", "mv_par09", "","","","","","","","","","","","","","","","")
	//xPutSx1(cPerg, "10", "Vencimento ate"         , "", "", "mv_ch10", "D", 08,  0, 0, "G", "", ""   , "", "", "mv_par10", "","","","","","","","","","","","","","","","")
	//xPutSx1(cPerg, "11", "Emissao de"          	 , "", "", "mv_ch11", "D", 08,  0, 0, "G", "", ""   , "", "", "mv_par11", "","","","","","","","","","","","","","","","")
	//xPutSx1(cPerg, "12", "Emissao de"          	 , "", "", "mv_ch12", "D", 08,  0, 0, "G", "", ""   , "", "", "mv_par12", "","","","","","","","","","","","","","","","")
	//xPutSx1(cPerg, "13", "Bodero de"              , "", "", "mv_ch13" , "C", 06,  0, 0, "G", "", "", "", "", "mv_par13", "","","","","","","","","","","","","","","","")
	//xPutSx1(cPerg, "14", "Bordero Ate"            , "", "", "mv_ch14" , "C", 06,  0, 0, "G", "", "", "", "", "mv_par14", "","","","","","","","","","","","","","","","")

	dbSelectArea(_cAlias)
Return


