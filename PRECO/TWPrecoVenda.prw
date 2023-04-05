#INCLUDE "TOTVS.CH"
#INCLUDE "TOPCONN.CH"

/*/{Protheus.doc} TWPrecoVenda
Rotina de Calculo do Preco de Venda.
@author Wlysses Cerqueira (WlyTech)
@since 01/03/2023
@project Automação Financeira
@version 1.0
@description 
@type class
/*/

#DEFINE TIT_WND "Processamento Preço de Venda"

Static _oObjPrc := Nil

Class TWPrecoVenda From LongClassName

	Data cCaminho
	Data cName
	Data aParam
	Data aParRet
	Data bConfirm
	Data lConfirm

	Data oWindow // Janela principal - FWDialogModal
	Data oContainer	// Divisor de janelas - FWFormContainer
	Data cHeaderBox // Identificador do cabecalho da janela
	Data cItemBox // Identificador dos itens da janela

	Data oPanel

	Data aCols
	Data aHeader
	Data aEdit

	Data oGrid
	Data oGridField

	Data oPrecoVenda

	Method New() ConStructor
	Method Processa()
	Method LoadInterface()
	Method LoadWindow()
	Method LoadContainer()
	Method LoadBrowser(lReLoad)
	Method ShowDocEntrada()
	Method Activate()

	Method GDFieldData(lReLoad)
	Method GDEdiTableField()
	Method GDFieldProperty()
	Method Valid()
	Method Confirm()
	Method Pergunte()
	Method GdSeek()
	Method Load()
	Method OrdenarGrid(nCol, oGrid)

EndClass

Method New() Class TWPrecoVenda

	::cName := "TWPrecoVenda"
	::aParam := {}
	::aParRet := {}
	::bConfirm := {|| .T.}
	::lConfirm := .F.
	::cCaminho := "C:\"

	::oWindow := Nil
	::oPanel := Nil
	::oContainer := Nil
	::cHeaderBox := ""
	::cItemBox := ""

	::aCols	:= {}
	::aHeader	:= {}
	::aEdit	:= {}
	::oGrid := Nil
	::oGridField := TGDField():New()

	::oPrecoVenda := TPrecoVenda():New()

Return()

Method Pergunte() Class TWPrecoVenda

	Local lRet		:= .F.
	Local aParRet	:= {}
	Local bConfirm	:= {|| .T.}
	Local aParam	:= {}

	aAdd(aParam, {1, "Produto de"		, ::oPrecoVenda:cProdutoDe	, X3Picture("B1_COD"), ".T.", "SB1",".T.", 100,.F.})
	aAdd(aParam, {1, "Produto ate"		, ::oPrecoVenda:cProdutoAte	, X3Picture("B1_COD"), ".T.", "SB1",".T.", 100,.F.})

	aAdd(aParam, {1, "Tipo de"			, ::oPrecoVenda:cTipoDe		, X3Picture("B1_TIPO"), ".T.", "02",".T.", 100,.F.})
	aAdd(aParam, {1, "Tipo ate"			, ::oPrecoVenda:cTipoAte	, X3Picture("B1_TIPO"), ".T.", "02",".T.", 100,.F.})

	aAdd(aParam, {3,"Filtro preço"  	, ::oPrecoVenda:nFiltroValor, {"Todos", "Preço a maior", "Preço a menor", "Preço não alterado"},80,"",.F.})

	If ParamBox(aParam, "Filtro", aParRet, bConfirm,,,,,,"TWPrecoVenda", .F., .T.)

		lRet := .T.

		::oPrecoVenda:cProdutoDe	:= aParRet[1]
		::oPrecoVenda:cProdutoAte	:= aParRet[2]

		::oPrecoVenda:cTipoDe		:= aParRet[3]
		::oPrecoVenda:cTipoAte		:= aParRet[4]

		::oPrecoVenda:nFiltroValor	:= aParRet[5]
		
	EndIf

Return(lRet)

Method LoadInterface() Class TWPrecoVenda

	::LoadWindow()

	::LoadContainer()

	::LoadBrowser()

Return()

Method LoadWindow() Class TWPrecoVenda

	// Local aCoors := MsAdvSize()
	Local aCoors := {0, 0, 2000, 300}

	::oWindow := FWDialogModal():New()

	::oWindow:SetBackground(.T.)
	::oWindow:SetTitle(TIT_WND)
	::oWindow:SetEscClose(.T.)
	::oWindow:SetSize(aCoors[4], aCoors[3] / 2)
	::oWindow:EnableFormBar(.T.)
	::oWindow:CreateDialog()
	::oWindow:CreateFormBar()

	::oWindow:AddOKButton({|| ::Confirm() })

	::oWindow:AddCloseButton()

	::oWindow:AddButton("Carregar", {|| ::Load(.T.) },,, .T., .F., .T.)

	::oWindow:AddButton("Pesquisar", {|| ::GdSeek() },,, .T., .F., .T.)

	::oWindow:AddButton("Doc.Entrada", {|| ::ShowDocEntrada() },,, .T., .F., .T.)

Return()

Method GdSeek() Class TWPrecoVenda

	GdSeek(::oGrid,,,,.F.)

Return()

Method LoadContainer() Class TWPrecoVenda

	::oContainer := FWFormContainer():New()

	//::cHeaderBox := ::oContainer:CreateHorizontalBox(30)

	::cItemBox := ::oContainer:CreateHorizontalBox(100)

	::oContainer:Activate(::oWindow:GetPanelMain(), .T.)

Return()

Method LoadBrowser(lReLoad) Class TWPrecoVenda

	Local cVldDef := "AllwayStrue"

	Default lReLoad := .F.

	::oPanel := ::oContainer:GetPanel(::cItemBox)

	::Load(.F.)

	::aEdit := ::GDEdiTableField()

	::aHeader := ::GDFieldProperty()

	::oGrid := MsNewGetDados():New(0, 0, 0, 0, GD_UPDATE, cVldDef, cVldDef, "", @::aEdit,,, cVldDef,, cVldDef, ::oPanel, @::aHeader, @::aCols)

	::oGrid:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT
	//::oGrid:oBrowse:bHeaderClick := {|oGrid, nCol| ::OrdenarGrid(nCol, @::oGrid)} // Nao usar
	::oGrid:oBrowse:lVScroll := .T.
	::oGrid:oBrowse:lHScroll := .T.

	::oGrid:oBrowse:Refresh()

	::oGrid:Refresh()

Return()

Method OrdenarGrid(nCol, oGrid) Class TWPrecoVenda

	oGrid:aCols := aSort( oGrid:aCols,,,{|x,y| x[nCol] < y[nCol]} )

	oGrid:SetArray(oGrid:aCols, .F.)

	oGrid:oBrowse:Refresh()

	oGrid:Refresh()

Return()

Method Load(lReLoad) Class TWPrecoVenda

	Default lReLoad := .T.

	If ::Pergunte()

		Processa({|| ::GDFieldData(lReLoad) }, "Aguarde...", "Carregando ...", .F.)

	EndIf

Return()

Method GDFieldData(lReLoad) Class TWPrecoVenda

	::aCols := ::oPrecoVenda:Load()

	If lReLoad

		::oGrid:oBrowse:Refresh()

		::oGrid:Refresh()

	EndIf

Return()

Method Activate() Class TWPrecoVenda

	::LoadInterface()

	::oWindow:Activate()

Return()

Method GDEdiTableField() Class TWPrecoVenda

	Local aRet := {}

	aRet := {"ZA9_MARGSA", "ZA9_DESPSA"}

Return(aRet)

Method GDFieldProperty() Class TWPrecoVenda

	Local aRet := {}

	::oGridField:Clear()

	// ::oGridField:AddField("ZA9_FILIAL")
	// ::oGridField:AddField("ZA9_CODTAB")
	// ::oGridField:AddField("ZA9_VERSAO")

	::oGridField:AddField("MARK")
	::oGridField:FieldName("MARK"):cTitle := ""
	::oGridField:FieldName("MARK"):cPict := "@BMP"

	::oGridField:AddField("ZA9_PRODUT")
	::oGridField:AddField("ZA9_ULTCOM")
	::oGridField:AddField("ZA9_FORNEC")
	::oGridField:AddField("ZA9_LOJFOR")
	::oGridField:AddField("ZA9_DOC")
	::oGridField:AddField("ZA9_SERIE")

	::oGridField:AddField("ZA9_PRCCAL")
	::oGridField:AddField("ZA9_PRCDIG")

	::oGridField:AddField("ZA9_DESPSA")
	::oGridField:AddField("ZA9_MARGSA")

	::oGridField:AddField("ZA9_PICOSA")
	::oGridField:AddField("ZA9_IPI")
	::oGridField:AddField("ZA9_MVA")
	::oGridField:AddField("ZA9_ICMSAI")
	::oGridField:AddField("ZA9_PERFRE")
	::oGridField:AddField("ZA9_ICMENT")
	::oGridField:AddField("ZA9_PICOEN")
	::oGridField:AddField("ZA9_FRETE")
	::oGridField:AddField("ZA9_IPIVLR")
	::oGridField:AddField("ZA9_CRICMS")
	::oGridField:AddField("ZA9_CRPICO")
	::oGridField:AddField("ZA9_STSICM")
	::oGridField:AddField("ZA9_CUSBRU")
	::oGridField:AddField("ZA9_BASEST")
	::oGridField:AddField("ZA9_BASTRE")
	::oGridField:AddField("ZA9_BAOPPR")
	::oGridField:AddField("ZA9_STVLR")
	::oGridField:AddField("ZA9_CUSMED")
	::oGridField:AddField("ZA9_CUBSST")
	::oGridField:AddField("ZA9_CUBCST")
	::oGridField:AddField("ZA9_LUBRST")
	::oGridField:AddField("ZA9_MRKBRU")

	//::oGridField:AddField("Space")

	aRet := ::oGridField:GetHeader()

Return(aRet)

Method Valid() Class TWPrecoVenda

	Local lRet		:= .T.
	Local nW		:= 0
	Local nX		:= 0
	Local aCampObr	:= {"CT2_LOTE", "CT2_SBLOTE", "CT2_DOC"}

	DBSelectArea("SX3")
	SX3->(DBSetOrder(2)) // X3_CAMPO, R_E_C_N_O_, D_E_L_E_T_

	For nW := 1 To Len(::oGrid:aCols)

		If !lRet

			Exit

		EndIf

		If !GDdeleted(nW, ::oGrid:aHeader, ::oGrid:aCols)

			For nX := 1 To Len(aCampObr)

				SX3->(DBSeek(aCampObr[nX]))

				nPos := aScan(::oGrid:aHeader, {|x| AllTrim(x[2]) == aCampObr[nX]})

				If nPos > 0

					If Empty(::oGrid:aCols[nW][nPos])

						MsgStop("Linha: " + AllTrim(cValToChar(nW)) + CRLF + CRLF + "Campo '" + AllTrim(::oGrid:aHeader[nPosDoc][1]) + "' não preenchido!", "Geração de Lançamento")

						::oGrid:GoTo(nW)

						::oGrid:oBrowse:SetFocus()

						lRet := .F.

						Exit

					EndIf

				Else

					MsgStop("Campo '" + AllTrim(SX3->X3_TITULO) + "-" + AllTrim(SX3->X3_CAMPO) + "' não encontrado" + " !", "Geração de Lançamento")

					::oGrid:GoTo(nW)

					::oGrid:oBrowse:SetFocus()

					lRet := .F.

					Exit

				EndIf

			Next nX

		EndIf

	Next nW

	//lRet := oGrid:TudoOk()

Return(lRet)

Method Processa() Class TWPrecoVenda

	

Return()

Method Confirm() Class TWPrecoVenda

	If ::Valid()

		If MsgYesNo("Confirma importação?")

			U_BIAMsgRun("Importando...", "Aguarde!", {|| ::Processa() })

		EndIf

	EndIf

Return()

Method ShowDocEntrada() Class TWPrecoVenda

	Local aAreaSF1	:= SF1->(GetArea())
	Local aRotBkp	:= aClone(aRotina)

	aRotina := {}  //StaticCall(MATA103, MenuDef)

	aAdd(aRotina,{"", "AxPesqui"   , 0 , 1, 0, .F.}) 		//"Pesquisar"
	aAdd(aRotina,{"", "A103NFiscal", 0 , 2, 0, nil}) 		//"Visualizar"
	aAdd(aRotina,{"", "A103NFiscal", 0 , 3, 0, nil}) 		//"Incluir"
	aAdd(aRotina,{"", "A103NFiscal", 0 , 4, 0, nil}) 		//"Classificar"
	aAdd(aRotina,{"", "A103NFiscal", 3 , 5, 0, nil})		//"Excluir"

	DBSelectArea("SF1")
	SF1->(DbSetOrder(1))  //F1_FILIAL, F1_DOC, F1_SERIE, F1_FORNECE, F1_LOJA, F1_TIPO, R_E_C_N_O_, D_E_L_E_T_

	If SF1->(DbSeek(xFilial("SF1") + ZA9->(ZA9_DOC + ZA9_SERIE + ZA9_FORNEC + ZA9_LOJFOR)))

		A103NFiscal("SF1", SF1->(Recno()), 2, .F.)

	Else

		Alert("Nota não encontrada!")

	EndIf

	aRotina := aRotBkp

	RestArea(aAreaSF1)

Return()

User Function PRECOTEL()

	Local oObj := TWPrecoVenda():New()

	oObj:oPrecoVenda:cTabela := DA0->DA0_CODTAB

	If oObj:oPrecoVenda:cTabela == "003"

		oObj:oPrecoVenda:lB2B := .T.

	EndIf

	oObj:Activate()

Return()

User Function PRECOCAT()

	Local nPos			:= aScan(_oObjPrc:oGrid:aHeader, {|x| AllTrim(x[2]) == "ZA9_PRODUT"})
	Local nPosDesp		:= aScan(_oObjPrc:oGrid:aHeader, {|x| AllTrim(x[2]) == "ZA9_DESPSA"})
	Local nPosMargem	:= aScan(_oObjPrc:oGrid:aHeader, {|x| AllTrim(x[2]) == "ZA9_MARGSA"})
	Local cField 		:= ReadVar()

	If nPos > 0

		_oObjPrc:oPrecoVenda:cProdutoDe		:= _oObjPrc:oGrid:aCols[_oObjPrc:oGrid:nAt][nPos]
		_oObjPrc:oPrecoVenda:cProdutoAte	:= _oObjPrc:oGrid:aCols[_oObjPrc:oGrid:nAt][nPos]

		// _oObjPrc:cFornece	:= ""
		// _oObjPrc:cLoja		:= ""
		// _oObjPrc:cDocumento	:= ""
		// _oObjPrc:cSerie		:= ""

		_oObjPrc:oPrecoVenda:nMargem	:= If(cField == "M->ZA9_MARGSA", M->ZA9_MARGSA, _oObjPrc:oGrid:aCols[_oObjPrc:oGrid:nAt][nPosMargem])
		_oObjPrc:oPrecoVenda:nDespesa	:= If(cField == "M->ZA9_DESPSA", M->ZA9_DESPSA, _oObjPrc:oGrid:aCols[_oObjPrc:oGrid:nAt][nPosDesp])

		_oObjPrc:oGrid:aCols[_oObjPrc:oGrid:nAt] := _oObjPrc:oPrecoVenda:Load()[1]

		_oObjPrc:oGrid:oBrowse:Refresh()

		_oObjPrc:oGrid:Refresh()

	EndIf

Return(.T.)

User Function PRECOCAL()

	Local oObj 		:= Nil
	Local aParam	:= {"01", "010104"}

	Private cCadastro := TIT_WND

	RPCSetEnv(aParam[1],aParam[2],,,"FAT")

	oObj := TWPrecoVenda():New()

	@_oObjPrc := oObj

	oObj:oPrecoVenda:cTabela	:= "003"
	oObj:oPrecoVenda:cProdutoDe	:= PADR("TESTE999", TAMSX3("B1_COD")[1], " ")
	oObj:oPrecoVenda:cProdutoAte:= PADR("TESTE999", TAMSX3("B1_COD")[1], " ")

	// oObj:Load(.F.)

	oObj:Activate()

	RPCClearEnv()

Return()

User Function PRECOFRE()

	Local aChave	:= Array(5)
	Local aM116aCol	:= Array(5)
	Local aParam	:= {"01", "010104"}

	Private ACOLS := {{"", "", NIL}}
	Private PARAMIXB := {}
	Private cCadastro := TIT_WND

	// NF produtos
	aChave[1] := "666666666"
	aChave[2] := "666"
	aChave[3] := "000001"
	aChave[4] := "01"

	aM116aCol[1] := aChave[1]
	aM116aCol[2] := aChave[2]
	aM116aCol[3] := aChave[3]
	aM116aCol[4] := aChave[4]
	aM116aCol[5] := aCols[1]

	PARAMIXB := {"cAliasSD1",1,aM116aCol}

	RPCSetEnv(aParam[1],aParam[2],,,"FAT")

	U_M116ACOL()

	RPCClearEnv()

Return()
