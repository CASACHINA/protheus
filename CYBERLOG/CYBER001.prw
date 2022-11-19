#INCLUDE 'PROTHEUS.CH'
#INCLUDE 'FWMVCDEF.CH'

/*/{Protheus.doc} CYBER001
Cadastro Nivel de empresa
/*/ 
User Function CYBER001()

	Local oBrowse := FWMBrowse():New()

	Private aRotina := {}

	oBrowse:SetAlias('ZA2')
	oBrowse:SetDescription('Parametrização - Cyberlog')

	oBrowse:Activate()

Return()

Static Function MenuDef()

	aRotina := {}
	
	ADD OPTION aRotina TITLE 'Visualizar' 	ACTION 'VIEWDEF.CYBER001' OPERATION 2 ACCESS 0
	ADD OPTION aRotina TITLE 'Incluir'    	ACTION 'VIEWDEF.CYBER001' OPERATION 3 ACCESS 0
	ADD OPTION aRotina TITLE 'Alterar'    	ACTION 'VIEWDEF.CYBER001' OPERATION 4 ACCESS 0
	ADD OPTION aRotina TITLE 'Excluir'    	ACTION 'VIEWDEF.CYBER001' OPERATION 5 ACCESS 0

Return(aRotina)

Static Function ModelDef()

	Local oModel
	Local oStruMaster 	:= FWFormStruct(1,"ZA2")
	Local cTitle 		:= "Parametrização - Cyberlog"

	oModel := MPFormModel():New(cTitle)
	oModel:SetDescription(cTitle)

	oModel:addFields('MASTER',,oStruMaster)

	oModel:SetPrimaryKey({"ZA2_FILIAL"})

Return(oModel)

Static Function ViewDef()

	Local oModel := FWLoadModel('CYBER001')
	Local oView
	Local oStrMas	:= FWFormStruct(2, 'ZA2')

	oView := FWFormView():New()
	oView:SetModel(oModel)

	oView:AddField('FORM_MASTER' , oStrMas,'MASTER' )

Return(oView)
