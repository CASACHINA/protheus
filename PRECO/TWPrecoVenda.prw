#INCLUDE "TOTVS.CH"
#INCLUDE "TOPCONN.CH"

/*/{Protheus.doc} TWPrecoVenda
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

	Local lRet := .F.
	Local nTam := 1

	::bConfirm := {|| .T. }

	::aParam := {}

	::aParRet := {}

	aAdd(::aParam, {6, "Arquivo a importar" , ::cCaminho, "@!", ".T.", ".T.", 75, .T., "Arquivo * |*",,GETF_LOCALHARD+GETF_NETWORKDRIVE})

	If ParamBox(::aParam, "Operações", ::aParRet, ::bConfirm,,,,,,::cName, .T., .T.)

		lRet := .T.

		::cCaminho := ::aParRet[nTam++]

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

	::oWindow:AddButton("Carregar", {|| ::Load() },,, .T., .F., .T.)

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

	::aCols := ::oPrecoVenda:Load()

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

	// ::Pergunte()

	Processa({|| ::GDFieldData(lReLoad) }, "Aguarde...", "Carregando Arquivo...", .F.)

Return()

Method GDFieldData(lReLoad) Class TWPrecoVenda

	::LoadBrowser(lReLoad)

	::oGrid:oBrowse:Refresh()

	::oGrid:Refresh()		

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

	::oHeader:AddField("MARK")
	::oHeader:FieldName("MARK"):cTitle := ""
	::oHeader:FieldName("MARK"):cPict := "@BMP"

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

	Local aAreaSE1	:= SE1->(GetArea())
	Local aAreaSE2	:= SE2->(GetArea())
	Local nW		:= 0
	Local aItem		:= {}
	Local aRet		:= {}
	Local lRet		:= .T.

	Local nPosLote 	:= aScan(::oGrid:aHeader, {|x| AllTrim(x[2]) == "CT2_LOTE"})
	Local nPosSBLote:= aScan(::oGrid:aHeader, {|x| AllTrim(x[2]) == "CT2_SBLOTE"})
	Local nPosDoc	:= aScan(::oGrid:aHeader, {|x| AllTrim(x[2]) == "CT2_DOC"})

	Local cLote_		:= ""
	Local cSubLote_	:= ""
	Local cDoc_  	:= ""

	BEGIN TRANSACTION

		For nW := 1 To Len(::oGrid:aCols)

			If !GDdeleted(nW, ::oGrid:aHeader, ::oGrid:aCols)



			EndIf

		Next nW

	END TRANSACTION

	If lRet

		MsgInfo("Importação do arquivo " + AllTrim(::cCaminho) + " concluída com sucesso!", "Importação planilha")

		::oGrid:SetArray({}, .F.)

		::oGrid:oBrowse:Refresh()

		::oGrid:Refresh()

	EndIf

	RestArea(aAreaSE1)
	RestArea(aAreaSE2)

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

User Function PRECOCAT()

	Local nPos			:= aScan(_oObjPrc:oGrid:aHeader, {|x| AllTrim(x[2]) == "ZA9_PRODUT"})
	Local nPosDesp		:= aScan(_oObjPrc:oGrid:aHeader, {|x| AllTrim(x[2]) == "ZA9_DESPSA"})
	Local nPosMargem	:= aScan(_oObjPrc:oGrid:aHeader, {|x| AllTrim(x[2]) == "ZA9_MARGSA"})
	Local cProduto		:= ""
	Local cField 		:= ReadVar()

	If nPos > 0

		cProduto := _oObjPrc:oGrid:aCols[_oObjPrc:oGrid:nAt][nPos]

		_oObjPrc:oGrid:aCols[_oObjPrc:oGrid:nAt] := _oObjPrc:oPrecoVenda:Load(cProduto, If(cField == "M->ZA9_DESPSA", M->ZA9_DESPSA, _oObjPrc:oGrid:aCols[_oObjPrc:oGrid:nAt][nPosDesp]), If(cField == "M->ZA9_MARGSA", M->ZA9_MARGSA, _oObjPrc:oGrid:aCols[_oObjPrc:oGrid:nAt][nPosMargem]))[1]

		_oObjPrc:oGrid:oBrowse:Refresh()

		_oObjPrc:oGrid:Refresh()

	EndIf

Return(.T.)

User Function PRECOCAL()

	Local oObj 		:= TWPrecoVenda():New()
	Local aParam	:= {"01", "010104"}

	Private cCadastro := TIT_WND
	
	RPCSetEnv(aParam[1],aParam[2],,,"FAT")

	@_oObjPrc := oObj

	oObj:Activate()

	RPCClearEnv()

Return()
