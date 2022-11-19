#INCLUDE 'PROTHEUS.CH'
#INCLUDE 'FWMVCDEF.CH'

/*/{Protheus.doc} CYBER003
Cadastro Nivel de empresa
/*/ 
User Function CYBER003()

	Local oBrowse := FWMBrowse():New()

	Private aRotina := {}

	oBrowse:SetAlias('ZA4')
	oBrowse:AddLegend( "ZA4_STATUS == 'P'", "YELLOW"	, "Pendente" 	)
	oBrowse:AddLegend( "ZA4_STATUS == 'S'", "GREEN" 	, "Sucesso"		)
	oBrowse:AddLegend( "ZA4_STATUS == 'E'", "RED"  		, "Erro"		)

	oBrowse:SetDescription('Monitor Integração - Cyberlog')

	oBrowse:Activate()

Return()

Static Function MenuDef()

	aRotina := {}

	ADD OPTION aRotina TITLE 'Visualizar' 	ACTION 'VIEWDEF.CYBER003' OPERATION 2 ACCESS 0
	// ADD OPTION aRotina TITLE 'Incluir'    	ACTION 'VIEWDEF.CYBER003' OPERATION 3 ACCESS 0
	// ADD OPTION aRotina TITLE 'Alterar'    	ACTION 'VIEWDEF.CYBER003' OPERATION 4 ACCESS 0
	// ADD OPTION aRotina TITLE 'Excluir'    	ACTION 'VIEWDEF.CYBER003' OPERATION 5 ACCESS 0

Return(aRotina)

Static Function ModelDef()

	Local oModel
	Local oStruMaster 	:= FWFormStruct(1,"ZA4")
	Local cTitle 		:= "Monitor Integração - Cyberlog"

	oModel := MPFormModel():New(cTitle)
	oModel:SetDescription(cTitle)

	oModel:addFields('MASTER',,oStruMaster)

	oModel:SetPrimaryKey({"ZA4_FILIAL", "ZA4_TABPRO", "ZA4_CHAVE"})

Return(oModel)

Static Function ViewDef()

	Local oModel := FWLoadModel('CYBER003')
	Local oView
	Local oStrMas	:= FWFormStruct(2, 'ZA4')

	oView := FWFormView():New()
	oView:SetModel(oModel)

	oView:AddField('FORM_MASTER' , oStrMas,'MASTER' )

Return(oView)
