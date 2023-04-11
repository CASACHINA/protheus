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
	Method Excel()
	Method Legend()
	Method GetVersao()
	Method GetProxItemDA1(cTabela)
	Method Activate()

	Method GetFieldData(lReLoad)
	Method GetEdiTableField()
	Method GetFieldProperty()
	Method Valid()
	Method Confirm()
	Method AplicarPreco()
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

	aAdd(aParam, {3,"Filtro preço"  	, ::oPrecoVenda:nFiltroValor, {"Todos", "Preço a maior", "Preço a menor", "Preço sem alteração"},80,"",.F.})

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
	Local aCoors := {}
	
	If FWIsInCallStack("U_PRECOCAL")

		aCoors := {0, 0, 2000, 300}

	Else

		aCoors := MsAdvSize()

	EndIf
	
	::oWindow := FWDialogModal():New()

	::oWindow:SetBackground(.T.)
	::oWindow:SetTitle(TIT_WND + " [" + DA0->DA0_CODTAB + "] - " + AllTrim(DA0->DA0_DESCRI))
	::oWindow:SetEscClose(.T.)
	::oWindow:SetSize(aCoors[4], aCoors[3])
	::oWindow:EnableFormBar(.T.)
	::oWindow:CreateDialog()
	::oWindow:CreateFormBar()

	::oWindow:AddOKButton({|| ::Confirm() }, "Aplicar")

	::oWindow:AddCloseButton()

	::oWindow:AddButton("Legenda"			, {|| ::Legend() }			,,, .T., .F., .T.)

	::oWindow:AddButton("Exportar Excel"	, {|| ::Excel() }			,,, .T., .F., .T.)

	::oWindow:AddButton("Carregar"			, {|| ::Load(.T.) }			,,, .T., .F., .T.)

	::oWindow:AddButton("Pesquisar"			, {|| ::GdSeek() }			,,, .T., .F., .T.)

	::oWindow:AddButton("Doc.Entrada"		, {|| ::ShowDocEntrada() }	,,, .T., .F., .T.)

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

	::aEdit := ::GetEdiTableField()

	::aHeader := ::GetFieldProperty()

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

		Processa({|| ::GetFieldData(lReLoad) }, "Aguarde...", "Carregando ...", .F.)

	EndIf

Return()

Method GetFieldData(lReLoad) Class TWPrecoVenda

	::aCols := ::oPrecoVenda:Load()

	If lReLoad

		::oGrid:SetArray(::aCols, .F.)

		::oGrid:oBrowse:Refresh()

		::oGrid:Refresh()

	EndIf

Return()

Method Activate() Class TWPrecoVenda

	::LoadInterface()

	::oWindow:Activate()

Return()

Method GetEdiTableField() Class TWPrecoVenda

	Local aRet := {}

	aRet := {"ZA9_MARGSA", "ZA9_DESPSA", "ZA9_FRETE", "ZA9_PRCDIG"}

Return(aRet)

Method GetFieldProperty() Class TWPrecoVenda

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
	::oGridField:AddField("DA1_PRCVEN")

	::oGridField:AddField("ZA9_PRCCAL")
	::oGridField:AddField("ZA9_PRCDIG")

	::oGridField:AddField("ZA9_DESPSA")
	::oGridField:AddField("ZA9_MARGSA")

	::oGridField:AddField("ZA9_PICOSA")
	::oGridField:AddField("ZA9_IPI")
	::oGridField:AddField("ZA9_MVA")
	::oGridField:AddField("ZA9_ICMSAI")
	// ::oGridField:AddField("ZA9_PERFRE")
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

	DBSelectArea("SX3")
	SX3->(DBSetOrder(2)) // X3_CAMPO, R_E_C_N_O_, D_E_L_E_T_

	For nW := 1 To Len(::oGrid:aCols)

		If !lRet

			Exit

		EndIf

		If !GDdeleted(nW, ::oGrid:aHeader, ::oGrid:aCols)



		EndIf

	Next nW

	//lRet := oGrid:TudoOk()

Return(lRet)

Method Processa() Class TWPrecoVenda
	
	Local nW 		:= 0
	Local nX 		:= 0
	Local cField 	:= ""
	Local cVersao	:= ""
	Local lAchouZA8	:= .F.
	Local lNoIgual	:= .F.

	Begin Transaction

		cVersao := ::GetVersao()

		For nW := 1 To Len(::oGrid:aCols)

			RecLock("ZA9", .T.)
			ZA9->ZA9_FILIAL := xFilial("ZA9")
			ZA9->ZA9_CODTAB	:= ::oPrecoVenda:cTabela	
			ZA9->ZA9_VERSAO	:= cVersao
				
			For nX := 1 To Len(::oGrid:aHeader)

				cField := ::oGrid:aHeader[nX][2]

				If cField == "MARK"

					lNoIgual := ::oGrid:aCols[nW][nX] == "BR_VERDE"

				EndIf

				If FieldPos(cField) > 0 .And. SubStr(cField, 1, 3) == "ZA9"
					
					FieldPut( FieldPos(cField), ::oGrid:aCols[nW][nX])

				EndIf

			Next nX

			ZA9->(MSUnlock())

			ZA8->(DBSetorder(1)) // ZA8_FILIAL, ZA8_CODTAB, ZA8_PRODUT, R_E_C_N_O_, D_E_L_E_T_

			lAchouZA8 := ZA8->(DBSeek(xFilial("ZA8") + ZA9->ZA9_CODTAB + ZA9->ZA9_PRODUT))

			If !lNoIgual

				RecLock("ZA8", !lAchouZA8)
				ZA8->ZA8_FILIAL	:= xFilial("ZA8")
				ZA8->ZA8_CODTAB	:= ZA9->ZA9_CODTAB
				ZA8->ZA8_PRODUT	:= ZA9->ZA9_PRODUT
				ZA8->ZA8_PRCCAL	:= ZA9->ZA9_PRCCAL
				ZA8->ZA8_PRCDIG	:= ZA9->ZA9_PRCDIG
				ZA8->ZA8_PRCVEN	:= If(ZA9->ZA9_PRCDIG > 0, ZA9->ZA9_PRCDIG, ZA9->ZA9_PRCCAL)
				ZA8->(MSUnlock())

			EndIf

		Next nW

	End Transaction

	Begin Transaction

		::AplicarPreco(::oPrecoVenda:cTabela)

	End Transaction

Return()

Method AplicarPreco(cTabela) Class TWPrecoVenda

	Local lAchouDA1 := .F.

	DBSelectArea("DA1")
	DA1->(DBSetOrder(1)) // DA1_FILIAL, DA1_CODTAB, DA1_CODPRO, DA1_INDLOT, DA1_ITEM, R_E_C_N_O_, D_E_L_E_T_
	DA1->(DBGoTop())

	DBSelectArea("ZA8")
	ZA8->(DBSetOrder(1)) // ZA8_FILIAL, ZA8_CODTAB, ZA8_PRODUT, R_E_C_N_O_, D_E_L_E_T_
	ZA8->(DBGoTop())

	If ZA8->(DBSeek(xFilial("ZA8") + cTabela))

		While ZA8->(!EOF()) .And. ZA8->(ZA8_FILIAL + ZA8_CODTAB) == xFilial("ZA8") + cTabela

			lAchouDA1 := !DA1->(DBSeek(xFilial("DA1") + cTabela + ZA8->ZA8_PRODUT))

			RecLock("DA1", lAchouDA1)
			DA1->DA1_FILIAL	:= xFilial("DA1")
			DA1->DA1_PRCVEN := ZA8->ZA8_PRCVEN
			DA1->DA1_ITEM	:= If(lAchouDA1, ::GetProxItemDA1(cTabela), DA1->DA1_ITEM)
			DA1->DA1_CODTAB	:= cTabela
			DA1->DA1_CODPRO	:= ZA8->ZA8_PRODUT
			DA1->DA1_ATIVO	:= "1"
			DA1->DA1_TPOPER	:= "4"
			DA1->DA1_MOEDA	:= 1
			DA1->(MSUnlock())

			ZA8->(DBSkip())

		EndDo

	EndIf

Return()

Method Confirm() Class TWPrecoVenda

	If ::Valid()

		If MsgYesNo("Confirma?")

			FwMsgRun(, {|| ::Processa() }, "Aguarde...", "Atualizando novos preços...")

			::oWindow:oOwner:End()

		EndIf

	EndIf

Return()

Method ShowDocEntrada() Class TWPrecoVenda

	Local aAreaSF1	:= SF1->(GetArea())
	Local aRotBkp	:= aClone(aRotina)

	Local nPosDoc	:= aScan(::oGrid:aHeader, {|x| AllTrim(x[2]) == "ZA9_DOC"})
	Local nPosSerie	:= aScan(::oGrid:aHeader, {|x| AllTrim(x[2]) == "ZA9_SERIE"})
	Local nPosForn	:= aScan(::oGrid:aHeader, {|x| AllTrim(x[2]) == "ZA9_FORNEC"})
	Local nPosLoja	:= aScan(::oGrid:aHeader, {|x| AllTrim(x[2]) == "ZA9_LOJFOR"})

	aRotina := {}  //StaticCall(MATA103, MenuDef)
	INCLUI := .F.
	ALTERA := .F.
	
	aAdd(aRotina,{"", "AxPesqui"   , 0 , 1, 0, .F.}) 		//"Pesquisar"
	aAdd(aRotina,{"", "A103NFiscal", 0 , 2, 0, nil}) 		//"Visualizar"
	aAdd(aRotina,{"", "A103NFiscal", 0 , 3, 0, nil}) 		//"Incluir"
	aAdd(aRotina,{"", "A103NFiscal", 0 , 4, 0, nil}) 		//"Classificar"
	aAdd(aRotina,{"", "A103NFiscal", 3 , 5, 0, nil})		//"Excluir"

	DBSelectArea("SF1")
	SF1->(DbSetOrder(1))  //F1_FILIAL, F1_DOC, F1_SERIE, F1_FORNECE, F1_LOJA, F1_TIPO, R_E_C_N_O_, D_E_L_E_T_

	If Len(::oGrid:aCols) > 0

		If SF1->(DbSeek(xFilial("SF1") + ::oGrid:aCols[::oGrid:nAt][nPosDoc] + ::oGrid:aCols[::oGrid:nAt][nPosSerie] + ::oGrid:aCols[::oGrid:nAt][nPosForn] + ::oGrid:aCols[::oGrid:nAt][nPosLoja]))

			A103NFiscal("SF1", SF1->(Recno()), 2, .F.)

		Else

			Alert("Nota não encontrada!")

		EndIf

	EndIf

	aRotina := aRotBkp

	RestArea(aAreaSF1)

Return()

Method Excel() Class TWPrecoVenda

	DlgToExcel({{"GETDADOS", "Grid de Preços", ::GetFieldProperty(), ::aCols}})

Return()

Method Legend() Class TWPrecoVenda

	Local aLegend := {}
	
	aAdd(aLegend, {"BR_VERDE"	, "Preço sem alteração"})
	aAdd(aLegend, {"BR_VERMELHO", "Preço com alteração"})
	
	BrwLegenda(TIT_WND, "Legenda", aLegend)

Return()

Method GetVersao() Class TWPrecoVenda

	Local cVersao	:= "001"
	Local cAlias_	:= GetNextAlias()

	BeginSQL Alias cAlias_

		%noparser%

		SELECT MAX(ZA7_VERSAO) ZA7_VERSAO_MAX
		FROM ZA7010 
		WHERE 1 = 1
		AND ZA7_FILIAL 	= %Exp:xFilial("ZA7")%
		AND ZA7_CODTAB	= %Exp:Self:oPrecoVenda:cTabela%
		AND D_E_L_E_T_	= ''

	EndSQL

	If !(cAlias_)->(EOF())

		cVersao := Soma1((cAlias_)->ZA7_VERSAO_MAX)

	EndIf

	RecLock("ZA7", .T.)
	ZA7->ZA7_FILIAL	:= xFilial("ZA7")
	ZA7->ZA7_CODTAB	:= ::oPrecoVenda:cTabela
	ZA7->ZA7_VERSAO	:= cVersao
	ZA7->ZA7_DTGERA	:= Date()
	ZA7->ZA7_DTAPLI	:= Date()
	ZA7->ZA7_STATUS	:= "2"
	ZA7->(MSUnlock())
	
Return(cVersao)

Method GetProxItemDA1(cTabela) Class TWPrecoVenda

	Local cProximo	:= "0001"
	Local cAlias_	:= GetNextAlias()

	BeginSQL Alias cAlias_

		%noparser%

		SELECT MAX(DA1_ITEM) DA1_ITEM_MAX
		FROM DA1010 
		WHERE 1 = 1
		AND DA1_FILIAL 	= %Exp:xFilial("DA1")%
		AND DA1_CODTAB	= %Exp:cTabela%
		AND D_E_L_E_T_	= ''

	EndSQL

	If !(cAlias_)->(EOF())

		cProximo := Soma1((cAlias_)->DA1_ITEM_MAX)

	EndIf
	
Return(cProximo)

User Function PRECOTEL()

	Local oObj := Nil
	
	If DA0->DA0_ATIVO == "1"

		Private cCadastro := TIT_WND
		
		oObj := TWPrecoVenda():New()

		_oObjPrc := @oObj

		oObj:oPrecoVenda:cTabela := DA0->DA0_CODTAB

		If oObj:oPrecoVenda:cTabela == "003"

			oObj:oPrecoVenda:lB2B := .T.

		EndIf

		oObj:Activate()

	Else

		Help(NIL, NIL, "HELP", NIL, "A tabela de preço " + DA0->DA0_CODTAB + " está bloqueada!" , 1, 0, NIL, NIL, NIL, NIL, NIL, {"Verifique."})

	EndIf

Return()

User Function PRECOCAT()

	Local nPos			:= aScan(_oObjPrc:oGrid:aHeader, {|x| AllTrim(x[2]) == "ZA9_PRODUT"})
	Local nPosDesp		:= aScan(_oObjPrc:oGrid:aHeader, {|x| AllTrim(x[2]) == "ZA9_DESPSA"})
	Local nPosMargem	:= aScan(_oObjPrc:oGrid:aHeader, {|x| AllTrim(x[2]) == "ZA9_MARGSA"})
	Local nPosFrete		:= aScan(_oObjPrc:oGrid:aHeader, {|x| AllTrim(x[2]) == "ZA9_FRETE"})
	Local cField 		:= ReadVar()

	If nPos > 0

		_oObjPrc:oPrecoVenda:cProdutoDe		:= _oObjPrc:oGrid:aCols[_oObjPrc:oGrid:nAt][nPos]
		_oObjPrc:oPrecoVenda:cProdutoAte	:= _oObjPrc:oGrid:aCols[_oObjPrc:oGrid:nAt][nPos]

		// _oObjPrc:cFornece	:= ""
		// _oObjPrc:cLoja		:= ""
		// _oObjPrc:cDocumento	:= ""
		// _oObjPrc:cSerie		:= ""

		_oObjPrc:oPrecoVenda:nMargem	:= If(cField == "M->ZA9_MARGSA", M->ZA9_MARGSA	, _oObjPrc:oGrid:aCols[_oObjPrc:oGrid:nAt][nPosMargem])
		_oObjPrc:oPrecoVenda:nDespesa	:= If(cField == "M->ZA9_DESPSA", M->ZA9_DESPSA	, _oObjPrc:oGrid:aCols[_oObjPrc:oGrid:nAt][nPosDesp])
		_oObjPrc:oPrecoVenda:nFrete		:= If(cField == "M->ZA9_FRETE", M->ZA9_FRETE	, _oObjPrc:oGrid:aCols[_oObjPrc:oGrid:nAt][nPosFrete])

		_oObjPrc:oGrid:aCols[_oObjPrc:oGrid:nAt] := _oObjPrc:oPrecoVenda:Load()[1]

		_oObjPrc:oGrid:oBrowse:Refresh()

		_oObjPrc:oGrid:Refresh()

	EndIf

Return(.T.)

User Function PRECOCAL()

	Local oObj 		:= Nil
	Local cTabela	:= "003"
	Local aParam	:= {"01", "010104"}

	Private cCadastro := TIT_WND

	RPCSetEnv(aParam[1],aParam[2],,,"FAT")

	DBSelectArea("DA0")

	DA0->(DBSeek(xFilial("DA0") + cTabela))

	oObj := TWPrecoVenda():New()

	_oObjPrc := @oObj

	oObj:oPrecoVenda:cTabela	:= cTabela
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
