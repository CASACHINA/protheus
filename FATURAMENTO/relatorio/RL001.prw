#include "totvs.ch"
#include "topConn.ch"

/*/{Protheus.doc} RL001
Relatório de Produtos x Fornecedores
@author unknown
@since 17/08/2017
@version 12.1.14
@type function
/*/
user function RL001()
	local oReport
	private cReport := "RL001"

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
	local cTitulo := "RELATÓRIO POR FORNECEDOR"
	local cDescri := "RELATÓRIO POR FORNECEDOR"
	local oSection1, oSection2, oBreak

	fAjustaSX1(cReport) // Criar grupo de Perguntas (SX1)
	pergunte(cReport, .F.)

	oReport  := TReport():New( cReport, cTitulo, cReport, {|oReport| ReportPrint(oReport) }, cDescri )

//	oReport:setPortrait()  // Retrato
	oReport:setLandScape() // Paisagem
	oReport:nFontBody    := 8
	oReport:nLeftMargin  := 0
	oReport:lOnPageBreak := .T.
	oReport:SetLineHeight(50)

	oSection1 := TRSection():New(oReport, "FORNECEDORES", {"FORNECEDORES"}) // Secao Contratos
//	oSection1:SetTotalInLine( .F. )

	TRCell():New(oSection1, "D1_FORNECE", "FORNECEDORES", "Fornecedor"    , /*Picture*/, 20, /*lPixel*/, /*{|| code-block de impressao }*/)
	TRCell():New(oSection1, "D1_LOJA"   , "FORNECEDORES", "Loja"          , /*Picture*/, 10, /*lPixel*/, /*{|| code-block de impressao }*/)
	TRCell():New(oSection1, "RAZAO"     , "FORNECEDORES", "Razao Social"  , /*Picture*/, 50, /*lPixel*/, /*{|| code-block de impressao }*/)

	oSection2 := TRSection():New(oSection1, "FORNECEDORES", {"FORNECEDORES"}) // Secao Contratos
	TRCell():New(oSection2, "D1_DOC"      , "FORNECEDORES", "NF"          , /*Picture*/, 20, /*lPixel*/, /*{|| code-block de impressao }*/)
	TRCell():New(oSection2, "E4_DESCRI"   , "FORNECEDORES", "Cond. Pag"   , /*Picture*/, 30, /*lPixel*/, /*{|| code-block de impressao }*/)
	TRCell():New(oSection2, "PRODUTO"     , "FORNECEDORES", "Produto"     , /*Picture*/, 20, /*lPixel*/, /*{|| code-block de impressao }*/)
	TRCell():New(oSection2, "PROD_FORN"   , "FORNECEDORES", "Prod Forn"   , /*Picture*/, 15, /*lPixel*/, /*{|| code-block de impressao }*/)
	TRCell():New(oSection2, "CODBAR"      , "FORNECEDORES", "Cod Barra"   , /*Picture*/, 15, /*lPixel*/, /*{|| code-block de impressao }*/)
	TRCell():New(oSection2, "NCM"         , "FORNECEDORES", "NCM"         , ""/*Picture*/, 10, /*lPixel*/, /*{|| code-block de impressao }*/)
	TRCell():New(oSection2, "D1_TES"      , "FORNECEDORES", "TES"         , "@!"/*Picture*/, 40, /*lPixel*/, /*{|| code-block de impressao }*/)
	TRCell():New(oSection2, "DESCPRD"     , "FORNECEDORES", "Descricao"   , /*Picture*/, 40, /*lPixel*/, /*{|| code-block de impressao }*/)
	TRCell():New(oSection2, "LOCAL"       , "FORNECEDORES", "Armaz"       , "@E 999"/*Picture*/, 10, /*lPixel*/, /*{|| code-block de impressao }*/)
	TRCell():New(oSection2, "CUSTO_MEDIO" , "FORNECEDORES", "Custo Medio" , "@E 999,999,999.99"/*Picture*/, 20, /*lPixel*/, /*{|| code-block de impressao }*/)
	// TRCell():New(oSection2, "QTD_EST"     , "FORNECEDORES", "Qtde Estoque", "@E 999,999,999.99"/*Picture*/, 20, /*lPixel*/, /*{|| code-block de impressao }*/)
	// TRCell():New(oSection2, "ULT_COMPRA"  , "FORNECEDORES", "Ult Compra"  , "@E 999,999,999.99"/*Picture*/, 20, /*lPixel*/, /*{|| code-block de impressao }*/)
	
	TRCell():New(oSection2, "D1_QUANT"    , "FORNECEDORES", "Qtde"        , "@E 999,999,999.99"/*Picture*/, 20, /*lPixel*/, /*{|| code-block de impressao }*/)
	TRCell():New(oSection2, "D1_VUNIT"    , "FORNECEDORES", "Vlr Unit"    , "@E 999,999,999.99"/*Picture*/, 20, /*lPixel*/, /*{|| code-block de impressao }*/)
	TRCell():New(oSection2, "PRCVENPR"    , "FORNECEDORES", "Prc Venda PR", "@E 999,999,999.99"/*Picture*/, 20, /*lPixel*/, /*{|| code-block de impressao }*/)
	TRCell():New(oSection2, "PRCVENSC"    , "FORNECEDORES", "Prc Venda SC", "@E 999,999,999.99"/*Picture*/, 20, /*lPixel*/, /*{|| code-block de impressao }*/)
	// TRCell():New(oSection2, "PRC_PROMO"   , "FORNECEDORES", "Preço Promo" , "@E 999,999,999.99"/*Picture*/, 20, /*lPixel*/, /*{|| code-block de impressao }*/)
	// TRCell():New(oSection2, "D1_VALIPI"   , "FORNECEDORES", "Vlr IPI"     , "@E 999,999,999.99"/*Picture*/, 20, /*lPixel*/, /*{|| code-block de impressao }*/)
	// TRCell():New(oSection2, "D1_VALICM"   , "FORNECEDORES", "Vlr ICMS"    , "@E 999,999,999.99"/*Picture*/, 20, /*lPixel*/, /*{|| code-block de impressao }*/)
	TRCell():New(oSection2, "D1_ALQCOF"   , "FORNECEDORES", "% COFINS"    , "@E 999,999,999.99"/*Picture*/, 20, /*lPixel*/, /*{|| code-block de impressao }*/)
	TRCell():New(oSection2, "D1_ALQPIS"   , "FORNECEDORES", "% PIS"       , "@E 999,999,999.99"/*Picture*/, 20, /*lPixel*/, /*{|| code-block de impressao }*/)
	TRCell():New(oSection2, "D1_ICMSRET"  , "FORNECEDORES", "ICMS Ret"    , "@E 999,999,999.99"/*Picture*/, 20, /*lPixel*/, /*{|| code-block de impressao }*/)
	TRCell():New(oSection2, "D1_PICM"     , "FORNECEDORES", "% ICMS"      , "@E 999,999,999.99"/*Picture*/, 20, /*lPixel*/, /*{|| code-block de impressao }*/)
	TRCell():New(oSection2, "D1_IPI"      , "FORNECEDORES", "% IPI"       , "@E 999,999,999.99"/*Picture*/, 20, /*lPixel*/, /*{|| code-block de impressao }*/)
	TRCell():New(oSection2, "F1_TPFRETE"  , "FORNECEDORES", "Tipo Frete"  , "@!"/*Picture*/, 10, /*lPixel*/, /*{|| code-block de impressao }*/)
	// TRCell():New(oSection2, "F1_FRETE"    , "FORNECEDORES", "Vlr Frete"   , "@E 999,999,999.99"/*Picture*/, 20, /*lPixel*/, /*{|| code-block de impressao }*/)

	TRCell():New(oSection2, "MARKUP"      , "FORNECEDORES", "Markup PR"   , "@E 9,999.9999"/*Picture*/, 15, /*lPixel*/, {|| PRCVENPR / CUSTO_MEDIO * 100 - 100})
	TRCell():New(oSection2, "MARKUP"      , "FORNECEDORES", "Markup SC"   , "@E 9,999.9999"/*Picture*/, 15, /*lPixel*/, {|| PRCVENSC / CUSTO_MEDIO * 100 - 100})
	// TRCell():New(oSection2, "MARKUP_PROMO", "FORNECEDORES", "Markup Promo", "@E 999,999.99"/*Picture*/, 15, /*lPixel*/, /*{|| code-block de impressao }*/)
	TRCell():New(oSection2, "CST"         , "FORNECEDORES", "CST"         , ""/*Picture*/, 10, /*lPixel*/, /*{|| code-block de impressao }*/)
	
	// TRCell():New(oSection2, "COD_CAT"     , "FORNECEDORES", "Categoria"   , ""/*Picture*/, 10, /*lPixel*/, /*{|| code-block de impressao }*/)
	// TRCell():New(oSection2, "DES_CAT"     , "FORNECEDORES", "Descrição"   , ""/*Picture*/, 40, /*lPixel*/, /*{|| code-block de impressao }*/)

	oBreak := TRBreak():New(oSection1,oSection1:Cell("D1_FORNECE"),"Sub Total Fornecedores", , , .T.) // Quebrando pagina

	// TRFunction():New(oSection2:Cell("QTD_EST"), nil, "SUM"    , oBreak)
	TRFunction():New(oSection2:Cell("MARKUP") , nil, "AVERAGE", oBreak)
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
	local oSection1, oSection2

	oSection1 := oReport:Section(1)
	oSection2 := oReport:Section(1):Section(1)

	oSection2:SetParentQuery()
	oSection2:SetParentFilter({|cParam| FORNECEDORES->D1_FORNECE >= cParam .AND. FORNECEDORES->D1_FORNECE <= cParam},{|| FORNECEDORES->D1_FORNECE})

	_cSelect += "SELECT DISTINCT D1_FORNECE, D1_LOJA, A2_NOME RAZAO, D1_DOC, B1_COD PRODUTO, B1_DESC DESCPRD, A5_CODPRF PROD_FORN, B1_CODBAR CODBAR, B2_LOCAL LOCAL, " + CRLF
	// _cSelect += "       B2_QATU QTD_EST, ROUND(D1_VUNIT, 2) ULT_COMPRA, ROUND(B2_CM1, 2) CUSTO_MEDIO, DA1.DA1_PRCVEN PRCVEN, DA1CLUBE.DA1_PRCVEN PRC_PROMO, " + CRLF
	// _cSelect += "       B2_QATU QTD_EST, ROUND(D1_VUNIT, 2) ULT_COMPRA, DA1.DA1_PRCVEN PRCVEN, DA1CLUBE.DA1_PRCVEN PRC_PROMO, " + CRLF
	_cSelect += "       E4_DESCRI, B2_QATU QTD_EST, ROUND(D1_VUNIT, 2) ULT_COMPRA, DA1PR.DA1_PRCVEN PRCVENPR, DA1SC.DA1_PRCVEN PRCVENSC, " + CRLF
	// _cSelect += "	    ROUND(((DA1.DA1_PRCVEN/IIF(B2_CM1>0,ROUND(B2_CM1, 2),0.0001))*100)-100, 2) MARKUP, " + CRLF
	// _cSelect += "	    ROUND((((DA1CLUBE.DA1_PRCVEN)/IIF(B2_CM1>0,B2_CM1,0.0001)) * 100) - 100, 2) MARKUP_PROMO, " + CRLF
	_cSelect += "	    D1_CLASFIS CST, B1_POSIPI NCM, D1_TES, " + CRLF
	// _cSelect += "	    D1_CLASFIS CST, B1_POSIPI NCM, ZZ2_DESCRI DES_CAT, ZZ2_CODIGO COD_CAT, " + CRLF
	_cSelect += "	    D1_VUNIT, D1_VALIPI, D1_VALICM, D1_ALQCOF, D1_ALQPIS, D1_ICMSRET, D1_QUANT, D1_PICM, D1_IPI, F1_TPFRETE, F1_FRETE, " + CRLF
	// _cSelect += "	    (D1_VUNIT + (D1_VALIPI / IIF(D1_QUANT > 0, D1_QUANT, 1)) - (D1_VALICM / IIF(D1_QUANT > 0, D1_QUANT, 1)) - (D1_VUNIT * D1_ALQPIS) - (D1_VUNIT * D1_ALQCOF) + (D1_ICMSRET / D1_QUANT)) CUSTO_MEDIO " + CRLF
	// _cSelect += "	    (D1_VUNIT + (D1_VALIPI / IIF(D1_QUANT > 0, D1_QUANT, 1)) - (D1_VALICM / IIF(D1_QUANT > 0, D1_QUANT, 1)) - (D1_VUNIT * (D1_ALQPIS / 100)) - (D1_VUNIT * (D1_ALQCOF / 100)) + (D1_ICMSRET / IIF(D1_QUANT > 0, D1_QUANT, 1))) CUSTO_MEDIO " + CRLF
	_cSelect += "	    IIF(D1_ICMSRET = 0, (D1_VUNIT - (D1_VALDESC / IIF(D1_QUANT <= 0, 1, D1_QUANT)) + (D1_VALIPI / IIF(D1_QUANT <= 0, 1, D1_QUANT))  - (D1_VALICM / IIF(D1_QUANT <= 0, 1, D1_QUANT))  - (D1_VUNIT * (D1_ALQPIS / 100)) - (D1_VUNIT * (D1_ALQCOF / 100))), " + CRLF
	_cSelect += "	                        (D1_VUNIT - (D1_VALDESC / IIF(D1_QUANT <= 0, 1, D1_QUANT)) + (D1_VALIPI / IIF(D1_QUANT <= 0, 1, D1_QUANT)) - (D1_VUNIT * D1_ALQPIS/100) - (D1_VUNIT * D1_ALQCOF/100) + (D1_ICMSRET / IIF(D1_QUANT <= 0, 1, D1_QUANT)))) CUSTO_MEDIO " + CRLF
	
	_cSelect += "  FROM " + retSqlName("SD1") + " SD1 (NOLOCK) " + CRLF
	
	_cSelect += "  JOIN " + retSqlName("SF1") + " SF1 (NOLOCK) " + CRLF
	_cSelect += "    ON F1_FILIAL  = " + valToSql(xFilial("SF1")) + CRLF
	_cSelect += "   AND F1_DOC     = D1_DOC " + CRLF
	_cSelect += "   AND F1_SERIE   = D1_SERIE " + CRLF
	_cSelect += "   AND F1_FORNECE = D1_FORNECE " + CRLF
	_cSelect += "   AND F1_LOJA    = D1_LOJA " + CRLF
	_cSelect += "   AND F1_ESPECIE = 'SPED' " + CRLF
	_cSelect += "   AND F1_STATUS  <> '' " + CRLF
	_cSelect += "   AND SF1.D_E_L_E_T_ = '' " + CRLF
	
	_cSelect += "  JOIN " + retSqlName("SA2") + " SA2 (NOLOCK) " + CRLF
	_cSelect += "    ON A2_FILIAL = " + valToSql(xFilial("SA2")) + CRLF
	_cSelect += "   AND A2_COD    = D1_FORNECE " + CRLF
	_cSelect += "   AND A2_LOJA   = D1_LOJA " + CRLF
	_cSelect += "   AND SA2.D_E_L_E_T_ = '' " + CRLF

	_cSelect += "  JOIN " + retSqlName("SB1") + " SB1 (NOLOCK) " + CRLF
	_cSelect += "    ON B1_FILIAL = " + valToSql(xFilial("SB1")) + CRLF
	_cSelect += "   AND B1_COD    = D1_COD " + CRLF
	_cSelect += "   AND B1_MSBLQL <> '1' " + CRLF
	_cSelect += "   AND B1_TIPO   IN ('PA','ME') " + CRLF
	_cSelect += "   AND B1_GRUPO  BETWEEN " + valToSql(mv_par01) + " AND " + valToSql(mv_Par02) + CRLF
	_cSelect += "   AND SB1.D_E_L_E_T_ = '' " + CRLF
	
	if mv_par15 == 2 // Produto B2B
		_cSelect += "   AND B1_YID <> '' " + CRLF
	endif

	_cSelect += "  JOIN " + retSqlName("SB2") + " SB2 (NOLOCK) " + CRLF
	_cSelect += "    ON B2_FILIAL = " + valToSql(xFilial("SB2")) + CRLF
	_cSelect += "   AND B2_COD    = D1_COD " + CRLF
	_cSelect += "   AND B2_LOCAL  = D1_LOCAL " + CRLF
	_cSelect += "   AND B2_LOCAL BETWEEN " + valToSql(mv_par12) + " AND " + valToSql(mv_par13) + CRLF
	_cSelect += "   AND SB2.D_E_L_E_T_ = '' " + CRLF

	// if mv_par14 == 2
	// 	_cSelect += "   AND B2_QATU > 0 " + CRLF
	// endif

	_cSelect += "  JOIN " + retSqlName("SE4") + " SE4 (NOLOCK) " + CRLF
	_cSelect += "    ON E4_FILIAL = " + valToSql(xFilial("SE4")) + CRLF
	_cSelect += "   AND E4_CODIGO = F1_COND " + CRLF
	_cSelect += "   AND SE4.D_E_L_E_T_ = '' " + CRLF

	_cSelect += "  LEFT JOIN " + retSqlName("DA1") + " DA1PR (NOLOCK) " + CRLF
	_cSelect += "    ON DA1PR.DA1_FILIAL = " + valToSql(xFilial("DA1")) + CRLF
	_cSelect += "   AND DA1PR.DA1_CODPRO = D1_COD " + CRLF
	_cSelect += "   AND DA1PR.D_E_L_E_T_ = '' " + CRLF
	_cSelect += "   AND DA1PR.DA1_CODTAB = '001' " + CRLF
	
	_cSelect += "  LEFT JOIN " + retSqlName("DA1") + " DA1SC (NOLOCK) " + CRLF
	_cSelect += "    ON DA1SC.DA1_FILIAL = " + valToSql(xFilial("DA1")) + CRLF
	_cSelect += "   AND DA1SC.DA1_CODPRO = D1_COD " + CRLF
	_cSelect += "   AND DA1SC.D_E_L_E_T_ = '' " + CRLF
	_cSelect += "   AND DA1SC.DA1_CODTAB = '002' " + CRLF

	// _cSelect += "  LEFT JOIN " + retSqlName("DA1") + " DA1CLUBE (NOLOCK) " + CRLF
	// _cSelect += "    ON DA1CLUBE.DA1_FILIAL = " + valToSql(xFilial("DA1")) + CRLF
	// _cSelect += "   AND DA1CLUBE.DA1_CODPRO = D1_COD " + CRLF
	// _cSelect += "   AND DA1CLUBE.DA1_CODTAB = '100'" + CRLF
	// _cSelect += "   AND DA1CLUBE.D_E_L_E_T_ = '' " + CRLF

	_cSelect += "  LEFT JOIN " + retSqlName("SA5") + " SA5 (NOLOCK) " + CRLF
	_cSelect += "    ON A5_FILIAL  = " + valToSql(xFilial("SA5")) + CRLF
	_cSelect += "   AND A5_PRODUTO = D1_COD " + CRLF
	_cSelect += "   AND A5_FORNECE = D1_FORNECE " + CRLF
	_cSelect += "   AND A5_LOJA    = D1_LOJA " + CRLF
	_cSelect += "   AND SA5.D_E_L_E_T_ = '' " + CRLF

	// _cSelect += "  LEFT JOIN " + retSqlName("ZZ2") + " ZZ2 (NOLOCK) " + CRLF
	// _cSelect += "    ON ZZ2_FILIAL = " + valToSql(xFilial("ZZ2")) + CRLF
	// _cSelect += "   AND ZZ2_CODIGO = B1_YCATECO " + CRLF
	// _cSelect += "   AND ZZ2.D_E_L_E_T_ = '' " + CRLF

	// _cSelect += "  LEFT JOIN " + retSqlName("MB8") + " MB8 (NOLOCK) " + CRLF
	// _cSelect += "    ON MB8_FILIAL = " + valToSql(xFilial("MB8")) + CRLF
	// _cSelect += "   AND MB8_CODPRO = B1_COD " + CRLF
	// _cSelect += "   AND MB8.D_E_L_E_T_ = '' " + CRLF
	// _cSelect += "  LEFT JOIN " + retSqlName("MEI") + " MEI (NOLOCK) " + CRLF
	// _cSelect += "    ON MEI_FILIAL = " + valToSql(xFilial("MEI")) + CRLF
	// _cSelect += "   AND MEI_CODREG = MB8_CODREG " + CRLF
	// _cSelect += "   AND MEI_DATATE >= " + valToSql(dDataBase) + CRLF
	// _cSelect += "   AND MEI.D_E_L_E_T_ = '' " + CRLF
	_cSelect += " WHERE D1_FILIAL  = " + valToSql(xFilial("SD1")) + CRLF
	_cSelect += "   AND D1_FORNECE BETWEEN " + valToSql(mv_par03) + " AND " + valToSql(mv_Par05) + CRLF
	_cSelect += "   AND D1_LOJA    BETWEEN " + valToSql(mv_par04) + " AND " + valToSql(mv_Par06) + CRLF
	_cSelect += "   AND D1_DTDIGIT BETWEEN " + valToSql(mv_par07) + " AND " + valToSql(mv_Par08) + CRLF
	_cSelect += "   AND D1_DOC     BETWEEN " + valToSql(mv_par09) + " AND " + valToSql(mv_Par10) + CRLF
	// _cSelect += "   AND D1_DOC = (SELECT MAX(D1_DOC) " + CRLF
	// _cSelect += "                   FROM " + retSqlName("SD1I") + " SD1I (NOLOCK) " + CRLF
	// _cSelect += "                  WHERE D1_FILIAL = SD1.D1_FILIAL " + CRLF
	// _cSelect += "                    AND D1_COD    = SD1.D1_COD " + CRLF
	// _cSelect += "                    AND SD1I.D_E_L_E_T_ = '') " + CRLF
	_cSelect += "   AND SD1.D_E_L_E_T_ = '' " + CRLF
	_cSelect += " ORDER BY 2,3 " + CRLF

	tcQuery _cSelect new alias "FORNECEDORES"

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
		aAdd(aRegs,{cPerg,"01","Grupo Prd   De?","","","mv_ch1","C",04,0,1,"G","","mv_par01","","","","","","","","","","","","","","","","","","","","","","","","","SBM"})
		aAdd(aRegs,{cPerg,"02","Grupo Prd  Ate?","","","mv_ch2","C",04,0,1,"G","","mv_par02","","","","","","","","","","","","","","","","","","","","","","","","","SBM"})
		aAdd(aRegs,{cPerg,"03","Fornecedor  De?","","","mv_ch3","C",08,0,1,"G","","mv_par03","","","","","","","","","","","","","","","","","","","","","","","","","SA2"})
		aAdd(aRegs,{cPerg,"04","Loja Forne  De?","","","mv_ch4","C",02,0,1,"G","","mv_par04","","","","","","","","","","","","","","","","","","","","","","","","",""})
		aAdd(aRegs,{cPerg,"05","Fornecedor Ate?","","","mv_ch5","C",08,0,1,"G","","mv_par05","","","","","","","","","","","","","","","","","","","","","","","","","SA2"})
		aAdd(aRegs,{cPerg,"06","Loja Forne Ate?","","","mv_ch6","C",02,0,1,"G","","mv_par06","","","","","","","","","","","","","","","","","","","","","","","","",""})
		aAdd(aRegs,{cPerg,"07","Data Digit  De?","","","mv_ch 7","D",08,0,1,"G","","mv_par07","","","","","","","","","","","","","","","","","","","","","","","","",""})
		aAdd(aRegs,{cPerg,"08","Data Digit Ate?","","","mv_ch8","D",08,0,1,"G","","mv_par08","","","","","","","","","","","","","","","","","","","","","","","","",""})
		aAdd(aRegs,{cPerg,"09","Numero NF   De?","","","mv_ch9","C",09,0,1,"G","","mv_par09","","","","","","","","","","","","","","","","","","","","","","","","","","SF1"})
		aAdd(aRegs,{cPerg,"10","Numero NF  Ate?","","","mv_cha","C",09,0,1,"G","","mv_par10","","","","","","","","","","","","","","","","","","","","","","","","","","SF1"})
		aAdd(aRegs,{cPerg,"11","Tabela Preco  ?","","","mv_chb","C",03,0,1,"G","","mv_par11","","","","","","","","","","","","","","","","","","","","","","","","","","DA0"})
		aAdd(aRegs,{cPerg,"12","Armazem     De?","","","mv_chc","C",02,0,1,"G","","mv_par12","","","","","","","","","","","","","","","","","","","","","","","","","","NNR"})
		aAdd(aRegs,{cPerg,"13","Armazem    Ate?","","","mv_chd","C",02,0,1,"G","","mv_par13","","","","","","","","","","","","","","","","","","","","","","","","","","NNR"})
		aAdd(aRegs,{cPerg,"14","Saldo Zero    ?","","","mv_che","N",01,0,1,"C","","mv_par14","Não","","","","","Sim","","","","","","","","","","","","","","","","","","","",""})
		aAdd(aRegs,{cPerg,"15","Somente B2B   ?","","","mv_chf","N",01,0,1,"C","","mv_par15","Não","","","","","Sim","","","","","","","","","","","","","","","","","","","",""})

		for i := 1 to Len(aRegs)
			RecLock("SX1", .T.)
				for j := 1 to SX1->(FCount())
					If j <= Len(aRegs[i])
						FieldPut(j, aRegs[i, j])
					Endif
				next j
			SX1->(MsUnlock())
		next i
	endif

return nil