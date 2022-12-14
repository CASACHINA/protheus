#INCLUDE 'PROTHEUS.CH'
#INCLUDE 'FWMVCDEF.CH'

/*/{Protheus.doc} CYBER004
Cadastro Nivel de empresa
/*/ 
User Function CYBER004()

	Local oBrowse := FWMBrowse():New()

	Private aRotina := {}

	// Private cDocumento := ""

	oBrowse:SetAlias('ZA5')

	oBrowse:AddLegend( "ZA5->ZA5_STATUS == 'N'", "BR_VERMELHO"	,    "Não enviado" )
	oBrowse:AddLegend( "ZA5->ZA5_STATUS == 'R'", "BR_AMARELO"	,    "Aguard.Recebimento" )
	oBrowse:AddLegend( "ZA5->ZA5_STATUS == 'S'", "BR_LARANJA"	,    "Aguard.Separação" )
	oBrowse:AddLegend( "ZA5->ZA5_STATUS == 'P'", "BR_AZUL"		,    "Aguard.Transf.ERP" )
	oBrowse:AddLegend( "ZA5->ZA5_STATUS == 'T'", "BR_VERDE"		,    "Transferido" )
	oBrowse:AddLegend( "ZA5->ZA5_STATUS == 'X'", "BR_PRETO"		,    "Erro" )

	oBrowse:SetDescription("Cyberlog - Transferência entre Armazéns")

	oBrowse:Activate()

Return()

Static Function MenuDef()

	Local aRotina := {}

	ADD OPTION aRotina TITLE 'Visualizar' 				ACTION 'VIEWDEF.CYBER004' OPERATION 2 ACCESS 0
	ADD OPTION aRotina TITLE 'Incluir'    				ACTION 'VIEWDEF.CYBER004' OPERATION 3 ACCESS 0
	ADD OPTION aRotina TITLE 'Alterar'    				ACTION 'VIEWDEF.CYBER004' OPERATION 4 ACCESS 0
	ADD OPTION aRotina TITLE 'Excluir'    				ACTION 'VIEWDEF.CYBER004' OPERATION 5 ACCESS 0

	ADD OPTION aRotina TITLE 'Log'						ACTION 'U_CYBER002(1)' 	  OPERATION 4 ACCESS 0
	ADD OPTION aRotina TITLE 'Envio Cyberlog'			ACTION 'U_CYBER002(2)' 	  OPERATION 4 ACCESS 0
	ADD OPTION aRotina TITLE 'Envio Produto Cyberlog'	ACTION 'U_CYBER002(4)' 	  OPERATION 4 ACCESS 0
	ADD OPTION aRotina TITLE 'Grafico'					ACTION 'U_CYBER002(5)' 	  OPERATION 4 ACCESS 0
	ADD OPTION aRotina TITLE 'Transferir ERP'			ACTION 'U_CYBER002(6)' 	  OPERATION 4 ACCESS 0

	ADD OPTION aRotina TITLE 'Visualizar Documento'		ACTION 'U_CYBER002(7)' 	  OPERATION 4 ACCESS 0
	
Return(aRotina)

Static Function ModelDef()

	Local oModel
	Local oStruMaster 	:= FWFormStruct(1,"ZA5")
	Local oStruParam 	:= FWFormStruct(1,"ZA6")
	Local oModelEvent   := CYBER004EVENT():New()

	Local cTitle 		:= "Cyberlog - Transferência entre Armazéns"

	oModel := MPFormModel():New(cTitle)
	oModel:SetDescription(cTitle)

	oStruParam:RemoveField("ZA6_FILIAL")
	oStruParam:RemoveField("ZA6_PROCES")

	oModel:addFields('MASTER',,oStruMaster)
	oModel:addGrid('DETAIL_1','MASTER',oStruParam)

	oModel:SetPrimaryKey({"ZA5_FILIAL","ZA5_PROCES"})

	oModel:SetOptional('DETAIL_1', .T.)

	oModel:SetRelation("DETAIL_1", {{"ZA6_FILIAL","xFilial('ZA6')"},{"ZA6_PROCES","ZA5_PROCES"}},ZA6->(IndexKey(1)))

	oModel:InstallEvent("oModelEvent",,oModelEvent)

Return(oModel)

Static Function ViewDef()

	Local oModel := FWLoadModel('CYBER004')
	Local oView
	Local oStrMas	:= FWFormStruct(2, 'ZA5')
	Local oStrDet1	:= FWFormStruct(2, 'ZA6')

	oView := FWFormView():New()
	oView:SetModel(oModel)

	oStrDet1:RemoveField("ZA6_FILIAL")
	oStrDet1:RemoveField("ZA6_PROCES")

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

	oView:addIncrementField("FORM_DETAIL_1", "ZA6_ITEM")

Return(oView)
