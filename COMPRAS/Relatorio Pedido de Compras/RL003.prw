#include "totvs.ch"

user function RL003()
	Local oReport
	local cNomRel := "RL003"

	Pergunte(cNomRel,.F.)
	oReport := ReportDef(cNomRel)
	oReport:PrintDialog()
return nil

static function ReportDef(cNomRel)
	Local oReport, oSection1, oSection2, oBreak

	oReport   := TReport():New(cNomRel, "PEDIDO DE COMPRA", cNomrel, {|oReport| reportPrint(oReport, cNomRel)}, "PEDIDO DE COMPRA")
	oReport:SetLandscape() // Paisagem
	oReport:nFontBody    := 09
	oReport:nLeftMargin  := 2
	oReport:lOnPageBreak := .T.
	oReport:SetLineHeight(50)

	oSection1 := TRSection():New(oReport, "Cabecalho", "QRY")
	oSection1:SetLineStyle( .T.) // Secao em Linha ao Inves de Coluna

	TRCell():New(oSection1, "NUMPED", "QRY", "Número Pedido", , 030, .T., , , , , .F., , .T.)
	TRCell():New(oSection1, "DATEMI", "QRY", "Emissao"      , , 020, .T., {|| STOD(QRY->DATEMI)}, , , , .T., , .T.)

	oSection2 := TRSection():New(oSection1, "", "QRY")
	oSection2:SetTotalInLine( .T.)
	oSection2:bTotalText := {|| ""}

	TRCell():New(oSection2, "ITEPED", "QRY", "Item"        , , 010, .T., , , , , , , .T.)
	TRCell():New(oSection2, "CODPRO", "QRY", "Produto"     , , 025, .T., , , , , , , .T.)
	TRCell():New(oSection2, "DESCRI", "QRY", "Descrição"   , , 040, .T., , , /*.F. QUEBRA TEXTO*/, , , , .T.)
	TRCell():New(oSection2, "PRDFOR", "QRY", "Prd. Fornec" , , 025, .T., , , , , , , .T.)
	TRCell():New(oSection2, "CODBAR", "QRY", "Codigo barra", , 025, .T., , , , , , , .T.)
	TRCell():New(oSection2, "QTDPED", "QRY", "Qtde"        , "@E 999,999,999.99", 30, .T., , , , "RIGHT", , , .T.)
	TRCell():New(oSection2, "QTDCAI", "QRY", "Qtde CX"     , "@E 999,999,999.99", 30, .T., , , , "RIGHT", , , .T.)
	TRCell():New(oSection2, "VLUNIT", "QRY", "Vl Unit"     , "@E 999,999,999.99", 30, .T., , , , "RIGHT", , , .T.)
	TRCell():New(oSection2, "PERIPI", "QRY", "Perc IPI"    , "@E 999.99", 15, .T., , , , "RIGHT", , , .T.)
	TRCell():New(oSection2, "VALTOT", "QRY", "Vl Total"    , "@E 999,999,999.99", 30, .T., , , , "RIGHT", , , .T.)
	TRCell():New(oSection2, "NUMSOL", "QRY", "Num SC", , 025, .T., , , , , , , .T.)


	oBreak := TRBreak():New(oSection1, oSection1:Cell("NUMPED"), " ", , , .T.) // Quebrando pagina
	oBreak:bTotalcanPrint := {|| .F.}
	TRFunction():New(oSection2:Cell("VALTOT"), nil, "SUM", oBreak, "Valor Total", , , .T., .F., .F.)

return oReport

Static function reportPrint(oReport, cNomRel)
	local oSection1 := oReport:Section(1)
	local oSection2 := oReport:Section(1):Section(1)

	MakeSqlExpr(padr(cNomRel, 10))
	oSection1:BeginQuery()

	BeginSql alias "QRY"
		%noparser%
		SELECT C7_NUM NUMPED, C7_EMISSAO DATEMI, C7_ITEM ITEPED, C7_PRODUTO CODPRO, RTRIM(C7_DESCRI) DESCRI, ISNULL(A5_CODPRF, '') PRDFOR,
		       B1_CODBAR CODBAR, C7_QUANT QTDPED, B1_CONV QTDCAI, C7_PRECO VLUNIT, C7_IPI PERIPI, C7_TOTAL VALTOT, C7_NUMSC NUMSOL
		  FROM %table:SC7% SC7
		  JOIN %table:SB1% SB1
		    ON B1_FILIAL = %xfilial:SB1%
		   AND B1_COD = C7_PRODUTO
		   AND SB1.%notDel%
		  LEFT JOIN %table:SA5% SA5
		    ON A5_FILIAL  = %xfilial:SA5%
		   AND A5_FORNECE = C7_FORNECE
		   AND A5_LOJA    = C7_LOJA
		   AND A5_PRODUTO = C7_PRODUTO
		   AND SA5.%notDel%
		 WHERE C7_FILIAL = %xfilial:SC7%
		   AND C7_EMISSAO BETWEEN %exp:mv_par02% AND %exp:mv_par03%
		   AND SC7.%notDel%
	EndSql

	oSection1:EndQuery({mv_par01})

	oSection2:SetParentQuery()
	oSection2:SetParentFilter({|cParam| QRY->NUMPED >= cParam .AND. QRY->NUMPED <= cParam}, {|| QRY->NUMPED})

	oSection1:Print()

return nil