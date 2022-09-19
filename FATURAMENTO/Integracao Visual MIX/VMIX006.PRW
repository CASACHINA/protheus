#Include "Protheus.ch"
#Include "FWMVCDef.ch"
 
Static cTitle     := "Operadores Visual Mix"
Static cTabMaster := "ZV6"
Static cTabDetail := "ZV7"
 
/*/{Protheus.doc} VMIX006
Cadastro das matriz de para.
/*/ 
User Function VMIX006()

    Local aArea   := GetArea()
    Local oBrowse

    oBrowse := FWMBrowse():New()
    oBrowse:SetAlias(cTabMaster)
    oBrowse:SetDescription(cTitle)
    oBrowse:Activate()
     
    RestArea(aArea)

Return Nil

/*/{Protheus.doc} VMIX006

/*/
Static Function MenuDef()

    Local aRotina := FWMVCMenu("VMIX006")

Return aRotina
 
/*/{Protheus.doc} VMIX006

/*/
Static Function ModelDef()

    Local oModel    := Nil
    Local oStMaster := FWFormStruct(1, cTabMaster)
    Local oStDetail := FWFormStruct(1, cTabDetail)
    Local aRel      := {}
        
    oModel := MPFormModel():New("VMIX006M")
    oModel:AddFields("MASTER",/*cOwner*/,oStMaster)
    oModel:AddGrid("DETAIL","MASTER",oStDetail,/*bLinePre*/, /*bLinePost*/,/*bPre - Grid Inteiro*/,/*bLoad - Carga do modelo manualmente*/)
     
    aAdd(aRel, {"ZV7_FILIAL", 'xFilial("ZV7")'})
    aAdd(aRel, {"ZV7_CODIGO", "ZV6_CODIGO"})
     
    oModel:SetRelation("DETAIL", aRel, &(cTabDetail)->(IndexKey(1)))
    oModel:GetModel("DETAIL"):SetUniqueLine({"ZV7_FILIAL", "ZV7_CODIGO", "ZV7_LOJA"})
    oModel:SetPrimaryKey({})
     
    oModel:SetDescription(cTitle)
    oModel:GetModel("MASTER"):SetDescription("Operador")
    oModel:GetModel("DETAIL"):SetDescription("Filiais")

Return oModel
 
/*/{Protheus.doc} VMIX006

/*/
Static Function ViewDef()

    Local oView     := Nil
    Local oModel    := FWLoadModel("VMIX006")
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
         
    oStDetail:RemoveField("ZV7_CODIGO")

Return oView
 
