#include "totvs.ch"
#include "topConn.ch"

/*/{Protheus.doc} RL002
Relatório Saldo Estoque por Fornecedor
@author unknown
@since 17/08/2017
@version 12
@type function
/*/
user function RL002()
	
	local oReport
	private cReport := "RL002"
	
	oReport := ReportDef(cReport)
	oReport:PrintDialog()

return nil

/*/{Protheus.doc} ReportDef
Montagem secoes do relatorio
@author unknown
@since 17/05/2017
@version 12.1.14
@type function
/*/
static function ReportDef(cReport)
	
	local oReport
	local cTitulo := "SALDO ESTOQUE POR FORNECEDOR"
	local oSection1, oSection2, oBreak
	
	fAjustaSX1(cReport) // Criar grupo de Perguntas (SX1)
	pergunte(cReport, .F.)

	oReport  := TReport():New( cReport, cTitulo, cReport, {|oReport| ReportPrint(oReport) }, cTitulo )

//	oReport:setPortrait()  // Retrato
	oReport:setLandScape() // Paisagem
	oReport:nFontBody    := 8
	oReport:nLeftMargin  := 0
	oReport:lOnPageBreak := .T.
	oReport:SetLineHeight(50)

	oSection1 := TRSection():New(oReport, "PRODUTOS", {"PRODFORN"}) // Secao Contratos
//	oSection1:SetTotalInLine( .F. )

	TRCell():New(oSection1, "B1_COD"    , "PRODFORN", "Produto"     , /*Picture*/, 15, /*lPixel*/, /*{|| code-block de impressao }*/)
	TRCell():New(oSection1, "A5_CODPRF" , "PRODFORN", "Prod Forn"   , /*Picture*/, 15, /*lPixel*/, /*{|| code-block de impressao }*/)
	TRCell():New(oSection1, "B1_DESC"   , "PRODFORN", "Descricao"   , /*Picture*/, 40, /*lPixel*/, /*{|| code-block de impressao }*/)
	TRCell():New(oSection1, "B2_LOCAL"  , "PRODFORN", "Armaz"       , /*Picture*/, 10, /*lPixel*/, /*{|| code-block de impressao }*/)
	TRCell():New(oSection1, "B2_QATU"   , "PRODFORN", "Qtde Estoque", /*Picture*/, 15, /*lPixel*/, /*{|| code-block de impressao }*/)
	TRCell():New(oSection1, "DA1_PRCVEN", "PRODFORN", "Preco Venda" , "@E 999,999,999.99"/*Picture*/, 20, /*lPixel*/, /*{|| code-block de impressao }*/)
	TRCell():New(oSection1, "MEI_CODREG", "PRODFORN", "Promocao"    , /*Picture*/, 10, /*lPixel*/, /*{|| code-block de impressao }*/)
	TRCell():New(oSection1, "MB8_DESCVL", "PRODFORN", "Desconto"    , "@E 999,999,999.99"/*Picture*/, 20, /*lPixel*/, /*{|| code-block de impressao }*/)
	TRCell():New(oSection1, "MEI_DATATE", "PRODFORN", "Valid Desc"  , /*Picture*/, 20, /*lPixel*/, {|| STOD(PRODFORN->MEI_DATATE )})
	
	
return oReport

/*/{Protheus.doc} reportPrint
Funcao para impressao das secoes
@author unknown
@since 17/05/2017
@version 12.1.14
@param oReport, object, descricao
@type function
/*/
Static function reportPrint(oReport)
	local _cSelect  := ""
	local oSection1
	
	oSection1 := oReport:Section(1)
	
	_cSelect += "SELECT DISTINCT B1_COD, ISNULL(A5_CODPRF, '') A5_CODPRF, B1_DESC, B2_LOCAL, B2_QATU, DA1_PRCVEN, (DA1_PRCVEN - MB8_DESCVL) MB8_DESCVL, MEI_DATATE, MEI_CODREG " + CRLF
	_cSelect += "  FROM " + retSqlName("SB1") + " SB1 (NOLOCK) " + CRLF
	_cSelect += "  JOIN " + retSqlName("SB2") + " SB2 (NOLOCK) " + CRLF
	_cSelect += "    ON B2_FILIAL = " + valToSql(xFilial("SB2")) + CRLF
	_cSelect += "   AND B2_COD   = B1_COD " + CRLF
	_cSelect += "   AND B2_LOCAL BETWEEN " + valToSql(mv_par03) + " AND " + valToSql(mv_Par04) + CRLF
	
	if mv_par09 == 2 // listar saldo zerado
		_cSelect += "   AND B2_QATU > 0 " + CRLF
	endif
	
	_cSelect += "   AND SB2.D_E_L_E_T_ = '' " + CRLF
	_cSelect += "  JOIN " + retSqlName("SA5") + " SA5 (NOLOCK) " + CRLF
	_cSelect += "    ON A5_FILIAL  = " + valToSql(xFilial("SA5")) + CRLF
	_cSelect += "   AND A5_PRODUTO = B1_COD " + CRLF
	_cSelect += "   AND A5_FORNECE BETWEEN " + valToSql(mv_par05) + " AND " + valToSql(mv_Par07) + CRLF
	_cSelect += "   AND A5_LOJA    BETWEEN " + valToSql(mv_par06) + " AND " + valToSql(mv_Par08) + CRLF
	_cSelect += "   AND SA5.D_E_L_E_T_ = '' " + CRLF
	_cSelect += "  LEFT JOIN " + retSqlName("DA11") + " DA11 (NOLOCK) " + CRLF
	_cSelect += "    ON DA11.DA1_FILIAL = " + valToSql(xFilial("DA1")) + CRLF
	_cSelect += "   AND DA11.DA1_CODPRO = B1_COD " + CRLF
	_cSelect += "   AND DA11.D_E_L_E_T_ = '' " + CRLF
	_cSelect += "  LEFT JOIN " + retSqlName("MB8") + " MB8 (NOLOCK) " + CRLF
	_cSelect += "    ON MB8_FILIAL = " + valToSql(xFilial("MB8")) + CRLF
	_cSelect += "   AND MB8_CODPRO = B1_COD " + CRLF
	_cSelect += "   AND MB8.D_E_L_E_T_ = '' " + CRLF
	_cSelect += "  LEFT JOIN " + retSqlName("MEI") + " MEI (NOLOCK) " + CRLF
	_cSelect += "    ON MEI_FILIAL = " + valToSql(xFilial("MEI")) + CRLF
	_cSelect += "   AND MEI_CODREG = MB8_CODREG " + CRLF
	_cSelect += "   AND MEI_DATATE >= " + valToSql(dDataBase) + CRLF
	_cSelect += "   AND MEI.D_E_L_E_T_ = '' " + CRLF
	_cSelect += " WHERE B1_FILIAL = " + valToSql(xFilial("SB1")) + CRLF
	_cSelect += "   AND B1_COD    BETWEEN " + valToSql(mv_par01) + " AND " + valToSql(mv_Par02) + CRLF
	_cSelect += "   AND B1_MSBLQL <> '1' " + CRLF
	_cSelect += "   AND SB1.D_E_L_E_T_ = '' " + CRLF
	_cSelect += " ORDER BY 2,3 " + CRLF
	
	tcQuery _cSelect alias "PRODFORN" new
	
	oSection1:Print()
	
return nil

/*/{Protheus.doc} fAjustaSX1
Funcao para criar sx1 caso nao exista
@author unknown
@since 17/08/2017
@version 12.1.14
@param cPerg, characters, descricao
@type function
/*/
static function fAjustaSX1(cPerg)
	local aRegs := { }
	local i, j
	cPerg := padr(cPerg, 10)

	dbSelectArea("SX1")
	SX1->(dbSetOrder(1) )
	
	if !SX1->(dbSeek(cPerg))
	
		// Grupo/Ordem/Pergunta/Variavel/Tipo/Tamanho/Decimal/Presel/GSC/Valid/Var01/Def01/Cnt01/Var02/Def02/Cnt02/Var03/Def03/Cnt03/Var04/Def04/Cnt04/Var05/Def05/Cnt05/F3
		aAdd(aRegs,{cPerg,"01","Produto     De?","","","mv_ch1","C",15,0,1,"G","","mv_par01","","","","","","","","","","","","","","","","","","","","","","","","","SB1"})
		aAdd(aRegs,{cPerg,"02","Produto    Ate?","","","mv_ch2","C",15,0,1,"G","","mv_par02","","","","","","","","","","","","","","","","","","","","","","","","","SB1"})
		aAdd(aRegs,{cPerg,"03","Armazem     De?","","","mv_ch3","C",02,0,1,"G","","mv_par03","","","","","","","","","","","","","","","","","","","","","","","","","NNR"})
		aAdd(aRegs,{cPerg,"04","Armazem    Ate?","","","mv_ch4","C",02,0,1,"G","","mv_par04","","","","","","","","","","","","","","","","","","","","","","","","","NNR"})
		aAdd(aRegs,{cPerg,"05","Fornecedor  De?","","","mv_ch5","C",06,0,1,"G","","mv_par05","","","","","","","","","","","","","","","","","","","","","","","","","SA2"})
		aAdd(aRegs,{cPerg,"06","Loja Forne  De?","","","mv_ch6","C",02,0,1,"G","","mv_par06","","","","","","","","","","","","","","","","","","","","","","","","",""})
		aAdd(aRegs,{cPerg,"07","Fornecedor Ate?","","","mv_ch7","C",06,0,1,"G","","mv_par07","","","","","","","","","","","","","","","","","","","","","","","","","SA2"})
		aAdd(aRegs,{cPerg,"08","Loja Forne Ate?","","","mv_ch8","C",02,0,1,"G","","mv_par08","","","","","","","","","","","","","","","","","","","","","","","","",""})
		aAdd(aRegs,{cPerg,"09","Saldo Zero    ?","","","mv_chc","N",01,0,1,"C","","mv_par09","Não","","","","","Sim","","","","","","","","","","","","","","","","","","","",""})
		
		for i := 1 to Len(aRegs)
			RecLock("SX1", .T.)
	
			for j := 1 to SX1->(FCount())
				If j <= Len(aRegs[i])
					FieldPut(j, aRegs[i, j])
				Endif
			next
			SX1->(MsUnlock())
		next
	endif

return nil