#Include "Protheus.ch"
#Include "FWMVCDef.ch"
 
Static cTitle     := "Configuração Integração Visual Mix"
Static cTabMaster := "ZV0"
Static cTabDetail := "ZV1"
 
/*/{Protheus.doc} VMIX001
Cadastro das tabelas e campos que serão importados do Visual Mix para o Protheus.
/*/ 
User Function VMIX001()

    Local aArea   := GetArea()
    Local oBrowse

    oBrowse := FWMBrowse():New()
    oBrowse:SetAlias(cTabMaster)
    oBrowse:SetDescription(cTitle)
    oBrowse:Activate()
     
    RestArea(aArea)

Return Nil

/*/{Protheus.doc} VMIX001

/*/
Static Function MenuDef()

    Local aRotina := FWMVCMenu("VMIX001")

Return aRotina
 
/*/{Protheus.doc} VMIX001

/*/
Static Function ModelDef()

    Local oModel    := Nil
    Local oStMaster := FWFormStruct(1, cTabMaster)
    Local oStDetail := FWFormStruct(1, cTabDetail)
    Local aRel      := {}
        
    oModel := MPFormModel():New("VMIX001M")
    oModel:AddFields("MASTER",/*cOwner*/,oStMaster)
    oModel:AddGrid("DETAIL","MASTER",oStDetail,/*bLinePre*/, /*bLinePost*/,/*bPre - Grid Inteiro*/,/*bLoad - Carga do modelo manualmente*/)
     
    aAdd(aRel, {"ZV1_FILIAL", 'xFilial("ZV1")'})
    aAdd(aRel, {"ZV1_TABPRO", "ZV0_TABPRO"})
     
    oModel:SetRelation("DETAIL", aRel, &(cTabDetail)->(IndexKey(1)))
    oModel:GetModel("DETAIL"):SetUniqueLine({"ZV1_FILIAL", "ZV1_TABPRO", "ZV1_SEQUEN" ,"ZV1_CPOPRO"})
    oModel:SetPrimaryKey({})
     
    oModel:SetDescription(cTitle)
    oModel:GetModel("MASTER"):SetDescription("TABELAS")
    oModel:GetModel("DETAIL"):SetDescription("CAMPOS")

Return oModel
 
/*/{Protheus.doc} VMIX001

/*/
Static Function ViewDef()

    Local oView     := Nil
    Local oModel    := FWLoadModel("VMIX001")
    Local oStMaster := FWFormStruct(2, cTabMaster)
    Local oStDetail := FWFormStruct(2, cTabDetail)
     
    oView := FWFormView():New()
    oView:SetModel(oModel)
     
    oView:AddField("VIEW_MAS", oStMaster, "MASTER")
    oView:AddGrid("VIEW_DET", oStDetail, "DETAIL")
     
    oView:CreateHorizontalBox("CABEC", 20)
    oView:CreateHorizontalBox("GRID", 80)
     
    oView:SetOwnerView("VIEW_MAS", "CABEC")
    oView:SetOwnerView("VIEW_DET", "GRID")
          
    oView:SetCloseOnOk({||.T.})
    
    oView:AddIncrementField( "VIEW_DET", "ZV1_SEQUEN" )
     
    oStDetail:RemoveField("ZV1_TABPRO")

Return oView
 
