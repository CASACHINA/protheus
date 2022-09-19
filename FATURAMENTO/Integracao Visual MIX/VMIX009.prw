#INCLUDE 'PROTHEUS.CH'
#INCLUDE 'FWMVCDEF.CH'

/*/{Protheus.doc} VMIX009
Cadastro Nivel de empresa
/*/ 

User Function VMIX009()

	Local aArea   := GetArea()
	Local oBrowse := Nil
	Local cFunBkp := FunName()

	Private cTitulo := "Cadastro Nivel de Empresa"

	SetFunName("VMIX009")

	oBrowse := FWMBrowse():New()

	oBrowse:SetAlias("SZH")
	oBrowse:SetDescription(cTitulo)
	oBrowse:Activate()

	SetFunName(cFunBkp)
	RestArea(aArea)

Return()

Static Function MenuDef()

	Local aRotina := {}

	aAdd( aRotina, { 'Visualizar'	, 'VIEWDEF.VMIX009', 0, 2, 0, NIL } )
	aAdd( aRotina, { 'Incluir' 		, 'VIEWDEF.VMIX009', 0, 3, 0, NIL } )
	aAdd( aRotina, { 'Alterar' 		, 'VIEWDEF.VMIX009', 0, 4, 0, NIL } )
	aAdd( aRotina, { 'Excluir' 		, 'VIEWDEF.VMIX009', 0, 5, 0, NIL } )
	aAdd( aRotina, { 'Imprimir' 	, 'VIEWDEF.VMIX009', 0, 8, 0, NIL } )

Return(aRotina)

Static Function ModelDef()

	Local oModel   := Nil
	Local oFormPai := FWFormStruct(1, 'SZH', {|cCampo| AllTrim(cCampo) $ "SZH_NIVEL|SZH_DESCRI|SZH_MSBLQL"})
	Local oFormFil := FWFormStruct(1, 'SZH', {|cCampo| AllTrim(cCampo) $ "SZH_CODFIL"})
	Local aSZHRel  := {}

	oFormPai:SetProperty('SZH_NIVEL'	, MODEL_FIELD_WHEN	, FwBuildFeature(STRUCT_FEATURE_WHEN	, 'If(INCLUI,.T.,.F.)'))
	oFormPai:SetProperty('SZH_MSBLQL'	, MODEL_FIELD_INIT	, FwBuildFeature(STRUCT_FEATURE_INIPAD	, '"2"'))

	oModel := MPFormModel():New('VMIX009M',{|oModel| fPreValidCad(oModel)},{|oModel| fTudoOK(oModel)},{|oModel| fCommit(oModel)},{|oModel| fCancel(oModel)} )

	oModel:AddFields("FORMCAB",/*cOwner*/,oFormPai)
	oModel:AddGrid('SZHDETAIL',"FORMCAB",oFormFil)

	aAdd(aSZHRel, {'SZH_NIVEL', 'IIf(!INCLUI, SZH->SZH_NIVEL, "")'} )

	//Criando o relacionamento
	oModel:SetRelation('SZHDETAIL', aSZHRel, SZH->(IndexKey(1)))

	//Setando o campo único da grid para não ter repetição
	oModel:GetModel('SZHDETAIL'):SetUniqueLine({"SZH_CODFIL"})

	//Setando outras informações do Modelo de Dados
	oModel:SetDescription(cTitulo)
	oModel:SetPrimaryKey({})

	oModel:GetModel("FORMCAB"):SetDescription("Formulário do Cadastro "+cTitulo)

Return oModel

Static Function ViewDef()

	Local oModel     := FWLoadModel("VMIX009")
	Local oFormPai	 := FWFormStruct(2, 'SZH', {|cCampo| AllTrim(cCampo) $ "SZH_NIVEL|SZH_DESCRI|SZH_MSBLQL"})
	Local oFormFil	 := FWFormStruct(2, 'SZH', {|cCampo| AllTrim(cCampo) $ "SZH_CODFIL"})
	Local oView      := Nil

	oView := FWFormView():New()
	oView:SetModel(oModel)

	oView:AddField("VIEW_CAB"	, oFormPai	, "FORMCAB")
	oView:AddGrid ('VIEW_SZH'	, oFormFil	, "SZHDETAIL")

	//Setando o dimensionamento de tamanho
	oView:CreateHorizontalBox('CABEC', 20)
	oView:CreateHorizontalBox('GRID' , 80)

	//Amarrando a view com as box
	oView:SetOwnerView('VIEW_CAB','CABEC')
	oView:SetOwnerView('VIEW_SZH','GRID')

	//Habilitando título
	oView:EnableTitleView('VIEW_CAB', 'Cabeçalho - Nivel')
	oView:EnableTitleView('VIEW_SZH', 'Itens - Filiais')

	//Tratativa padrão para fechar a tela
	oView:SetCloseOnOk({||.T.})

	//Remove os campos de Filial e Tabela da Grid
	//oView:SetFieldAction( 'SZH_CODFIL', { |oView, cIDView, cField, xValue| VMIX009SG1( oView, cIDView, cField, xValue, aCampInGat)})

Return oView

Static Function fLinOK(oGrid, oField, nLine)

	Local lRet 		:= .T.
	Local cChave 	:= ""
	Local nOpc 		:= oGrid:GetOperation()
	Local nRecno 	:= SZH->(Recno())
	Local aAreaSZH	:= SZH->(GetArea())

	If nOpc == MODEL_OPERATION_INSERT //.Or. nOpc == MODEL_OPERATION_UPDATE

		SZH->(dbSetOrder(1)) // SZH_FILIAL, SZH_NIVEL, SZH_CODEMP, SZH_CODFIL, R_E_C_N_O_, D_E_L_E_T_

		oGrid:GoLine(nLine)

		cChave := xFilial("SZH") + oField:GetValue('SZH_NIVEL') + cEmpAnt + oGrid:GetValue('SZH_CODFIL')

		If lRet .And. SZH->(DbSeek(cChave, .T.))

			lRet := .F.

			Help(NIL, NIL, "ATENCAO", NIL, "Registro ja existente!", 1, 0, NIL, NIL, NIL, NIL, NIL,{"Verifique os dados digitados."})

		EndIf

		SZH->(DbGoTo(nRecno))

	EndIf

	RestArea(aAreaSZH)

Return(lRet)

Static Function fPreValidCad(oModel)

	Local lRet :=.T.

	Local nOpc := oModel:getoperation()

Return(lRet)

Static Function fTudoOK(oModel)

	Local lRet		 := .T.
	Local nX   		 := 0
	Local nOpc 		 := oModel:GetOperation()
	Local oField     := oModel:GetModel("FORMCAB")
	Local oGrid      := oModel:GetModel("SZHDETAIL")

	If nOpc == MODEL_OPERATION_INSERT .or. nOpc == MODEL_OPERATION_UPDATE

		If lRet

			For nX := 1 To oGrid:GetQtdLine()

				oGrid:GoLine(nX)

				If !oGrid:IsDeleted()

					lRet := fLinOK(oGrid, oField, nX)

				EndIf

				If !lRet

					Exit

				EndIf

			Next nX

		EndIf

	EndIf

Return(lRet)

Static Function fCommit(oModel)

	Local lRet 		 := .T.
	Local oGrid		 := oModel:GetModel("SZHDETAIL")
	Local oForm		 := oModel:GetModel("FORMCAB")
	Local nX   		 := 0
	Local nY		 := 0
	Local nOpc 		 := oModel:GetOperation()
	Local aCposForm  := oForm:GetStruct():GetFields()
	Local aCposGrid  := oGrid:GetStruct():GetFields()

	For nX := 1 To oGrid:GetQtdLine()

		oGrid:GoLine(nX)

		SZH->(dbGoTo(oGrid:GetDataID()))

		If nOpc == MODEL_OPERATION_DELETE

			//-- Deleta registro
			SZH->(RecLock("SZH",.F.))
			SZH->(dbDelete())
			SZH->(MsUnLock())

		Else

			//-- Grava inclusao/alteracao
			SZH->(RecLock("SZH", SZH->(EOF())))

			If oGrid:IsDeleted()

				SZH->(dbDelete())

			Else

				//-- Grava campos do cabecalho
				For nY := 1 To Len(aCposForm)

					If SZH->(FieldPos(aCposForm[nY,3])) > 0

						SZH->&(aCposForm[nY,3]) := oForm:GetValue(aCposForm[nY,3])

					EndIf

				Next nY

				//-- Grava campos do grid
				For nY := 1 To Len(aCposGrid)

					If SZH->(FieldPos(aCposGrid[nY,3])) > 0 .And. aCposGrid[nY,3] <> "SZH_FILIAL"

						SZH->&(aCposGrid[nY,3]) := oGrid:GetValue(aCposGrid[nY,3])

					EndIf

				Next nY

			EndIf

			SZH->(MsUnLock())

			SZH->(RecLock("SZH",.F.))
			SZH->SZH_FILIAL := xFilial("SZH")
			SZH->SZH_CODEMP := cEmpAnt
			SZH->(MsUnLock())

		EndIf

	Next nX

Return(lRet)

Static Function fCancel(oModel)

	Local lRet :=.T.

	Local nOpc := oModel:getoperation()

Return(lRet)
