#include "totvs.ch"
#include "fwmvcdef.ch"

Static cTitulo := "Lojas Clube Desconto"

/*/{Protheus.doc} RT004
Tela para cadastramento das filiais que estarão habilitadas na integração Mercafácil (clube desconto)
@author Paulo Cesar Camata
@since 19/06/2019
@version 12.1.17
@type function
/*/
user function RT005()
    local oBrowse
	local aArea := getArea()

	oBrowse := FWMBrowse():New()
	oBrowse:SetAlias("ZZ1")
	oBrowse:SetDescription(cTitulo)
	oBrowse:AddLegend("ZZ1->ZZ1_MSBLQL == '1'", "BR_VERMELHO", "Filial Bloqueada")
	oBrowse:AddLegend("ZZ1->ZZ1_MSBLQL <> '1'", "BR_VERDE"   , "Filial Liberada" )
	oBrowse:Activate()
	
	RestArea(aArea)
return nil

// Definicao dos menus disponiveis para a rotina
static function menuDef()
Return FWMVCMenu("RT005")

// Modelo de dados
static function ModelDef()
	Local oModel
	Local oStZZ1 := FWFormStruct(1, "ZZ1")
	
	oModel := MPFormModel():New("ZTR005",/*bPre*/, /*bPos*/,/*bCommit*/,/*bCancel*/) 
	
	oModel:AddFields("FORMZZ1",/*cOwner*/,oStZZ1)
	oModel:SetPrimaryKey({'ZZ1_FILIAL','ZZ1_CODFIL'})
	oModel:SetDescription("Modelo de Dados do Cadastro " + cTitulo)
	oModel:GetModel("FORMZZ1"):SetDescription("Formulário do Cadastro " + cTitulo)
return oModel

// Modelo Visual
static function ViewDef()
	Local oModel := FWLoadModel("RT005")
	Local oStZZ1 := FWFormStruct(2, "ZZ1")
	Local oView := Nil

	oView := FWFormView():New()
	oView:SetModel(oModel)
	oView:AddField("VIEW_ZZ1", oStZZ1, "FORMZZ1")
	oView:CreateHorizontalBox("TELA", 100)
	oView:EnableTitleView('VIEW_ZZ1', 'Dados do Grupo de Produtos' )  
	oView:SetCloseOnOk({||.T.})
	oView:SetOwnerView("VIEW_ZZ1","TELA")
return oView