#INCLUDE 'PROTHEUS.CH'
#INCLUDE 'FWMVCDEF.CH'

/*/{Protheus.doc} VMIX015
Cadastro Nivel de empresa
/*/ 
User Function VMIX015()

	Local oBrowse := FWMBrowse():New()

	Private aRotina := {}

	oBrowse:SetAlias('ZA0')
	oBrowse:AddLegend( "ZA0_STATUS == '0'", "YELLOW"	, "Aguard. Integração" 	)
	oBrowse:AddLegend( "ZA0_STATUS == '1'", "GREEN" 	, "Integrado"			)
	oBrowse:AddLegend( "ZA0_STATUS == '2'", "RED"  		, "Erro"				)

	oBrowse:SetDescription('Integração Devolução - Visual Mix X Protheus')

	oBrowse:Activate()

Return()

Static Function MenuDef()

	Local aRotina := {}

	ADD OPTION aRotina TITLE 'Visualizar' 	ACTION 'VIEWDEF.VMIX015' OPERATION 2 ACCESS 0
	ADD OPTION aRotina TITLE 'Incluir'    	ACTION 'VIEWDEF.VMIX015' OPERATION 3 ACCESS 0
	ADD OPTION aRotina TITLE 'Alterar'    	ACTION 'VIEWDEF.VMIX015' OPERATION 4 ACCESS 0
	ADD OPTION aRotina TITLE 'Excluir'    	ACTION 'VIEWDEF.VMIX015' OPERATION 5 ACCESS 0
	ADD OPTION aRotina TITLE "Doc.Entrada"  ACTION "U_VMIX015X"      OPERATION 2 ACCESS 0
	ADD OPTION aRotina TITLE "Doc.Saida"  	ACTION "U_VMIX015Y"      OPERATION 2 ACCESS 0

Return(aRotina)

Static Function ModelDef()

	Local oModel
	Local oStruMaster 	:= FWFormStruct(1,"ZA0")
	Local oStruParam 	:= FWFormStruct(1,"ZA1")

	Local cTitle 		:= "Integração Devolução - Visual Mix X Protheus"

	oModel := MPFormModel():New(cTitle)
	oModel:SetDescription(cTitle)

	oStruParam:RemoveField("ZA1_FILIAL")
	oStruParam:RemoveField("ZA1_PROCES")

	oModel:addFields('MASTER',,oStruMaster)
	oModel:addGrid('DETAIL_1','MASTER',oStruParam)

	oModel:SetPrimaryKey({"ZA0_FILIAL","ZA0_PROCES"})

	oModel:SetOptional('DETAIL_1', .T.)

	oModel:SetRelation("DETAIL_1", {{"ZA1_FILIAL","ZA0_FILIAL"},{"ZA1_PROCES","ZA0_PROCES"}},ZA1->(IndexKey(1)))

Return(oModel)

Static Function ViewDef()

	Local oModel := FWLoadModel('VMIX015')
	Local oView
	Local oStrMas	:= FWFormStruct(2, 'ZA0')
	Local oStrDet1	:= FWFormStruct(2, 'ZA1')

	oView := FWFormView():New()
	oView:SetModel(oModel)

	oStrDet1:RemoveField("ZA1_FILIAL")
	oStrDet1:RemoveField("ZA1_PROCES")

	oView:AddField('FORM_MASTER' , oStrMas,'MASTER' )
	oView:AddGrid('FORM_DETAIL_1' , oStrDet1,'DETAIL_1')

	oView:CreateHorizontalBox( 'BOX_FORM_MASTER', 50)

	oView:CreateHorizontalBox('BOX_FORM_DETAIL', 50)
	oView:CreateFolder('DETAIL_FOLDER','BOX_FORM_DETAIL')

	oView:AddSheet('DETAIL_FOLDER','ABA1','Itens')
	oView:CreateHorizontalBox('BOX_FORM_DETAIL_ABA1', 100,,,'DETAIL_FOLDER','ABA1')

	oView:SetOwnerView('FORM_MASTER','BOX_FORM_MASTER')
	oView:SetOwnerView('FORM_DETAIL_1','BOX_FORM_DETAIL_ABA1')

	oView:EnableTitleView('FORM_MASTER' , "Monitor" )
	oView:SetCloseOnOk({||.T.})

Return(oView)

User Function VMIX015X()

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

	If SF1->(DbSeek(xFilial("SF1") + ZA0->(ZA0_DOCDEV + ZA0_SERDEV + ZA0_CLIENT + ZA0_LOJA)))

		A103NFiscal("SF1", SF1->(Recno()), 2, .F.)

	Else

		Alert("Nota não encontrada!")

	EndIf

	aRotina := aRotBkp

	RestArea(aAreaSF1)

Return()

User Function VMIX015Y()

	Local aAreaSD2 := SD2->(GetArea())
	Local aRotBkp	:= aClone(aRotina)

	aRotina := {}  //StaticCall(MATA920, MenuDef)
	
	DBSelectArea("SD2")
	SD2->(dbSetOrder(3)) // D2_FILIAL, D2_DOC, D2_SERIE, D2_CLIENTE, D2_LOJA, D2_COD, D2_ITEM, R_E_C_N_O_, D_E_L_E_T_

	DbSelectArea("ZA1")
	ZA1->(DBSetOrder(1)) // ZA1_FILIAL, ZA1_PROCES, ZA1_ITEM, R_E_C_N_O_, D_E_L_E_T_

	aAdd(aRotina, { ""	,"AxPesqui"	, 0 , 1 , 0 ,.F.})
	aAdd(aRotina, { "" 	,"a920NFSAI", 0 , 2 , 0 ,NIL})
	aAdd(aRotina, { ""	,"a920NFSAI", 0 , 3 , 0 ,NIL})
	aAdd(aRotina, { ""  ,"a920NFSAI", 0 , 5 , 0 ,NIL})
	aAdd(aRotina, { ""  ,"a920NFSAI", 0 , 3 , 0 ,NIL})

	If ZA1->(DbSeek(ZA0->(ZA0_FILIAL + ZA0_PROCES)))

		If SD2->(DbSeek(xFilial("SD2") + ZA1->(ZA1_DOC + ZA1_SERIE) + ZA0->(ZA0_CLICUP + ZA0_LOJCUP)))

			A920NFSAI("SD2", SD2->(RecNo()), 0)

		Else

			Alert("Nota não encontrada!")

		EndIf

	Else

		Alert("Nota não encontrada!")

	EndIf

	aRotina := aRotBkp
	
	RestArea(aAreaSD2)

Return()
