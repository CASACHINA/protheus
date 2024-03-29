#Include "Protheus.ch"
#Include "FWMVCDef.ch"
#Include "TOPCONN.CH"

Static Enter   := Chr(10)
Static cTitulo := "Monitor de Integra��o Visual Mix."
 
//-------------------------------------------------------------------
/*/{Protheus.doc} VMIX004
Descri��o: Invent�rio
@author Kenny Roger Martins
/*/
//-------------------------------------------------------------------
User Function VMIX004()

	Local aArea := GetArea()

	Private oBrowse   := FWMBrowse():New()	

	oBrowse:SetAlias("ZV3")	
	oBrowse:SetDescription(cTitulo)	

    oBrowse:AddLegend("ZV3_STATUS=='0'", "BR_PRETO",    "Processando") 
    oBrowse:AddLegend("ZV3_STATUS=='1'", "BR_VERDE",    "Sucesso") 
    oBrowse:AddLegend("ZV3_STATUS=='2'", "BR_AMARELO",  "Advert�ncia") 
    oBrowse:AddLegend("ZV3_STATUS=='3'", "BR_VERMELHO", "Erro") 

    oBrowse:DisableDetails() 

	oBrowse:Activate()
	 
	RestArea(aArea)

Return Nil

//-------------------------------------------------------------------
/*/{Protheus.doc} MenuDef
Funcao generica MVC do menu
@return aRotina - Estrutura do Menu MVC
@author Kenny Roger Martins
@since 25/01/2018
@version 1.0
/*/
//-------------------------------------------------------------------
Static Function MenuDef()

    Local aRotina := {}
    	
    ADD OPTION aRotina TITLE "Visualizar"      ACTION "VIEWDEF.VMIX004" OPERATION MODEL_OPERATION_VIEW  ACCESS 0
    ADD OPTION aRotina TITLE "Legenda"         ACTION "U_VMIX004L"      OPERATION 7 ACCESS 0
    ADD OPTION aRotina TITLE "Imprimir"        ACTION "VIEWDEF.VMIX004" OPERATION 8 ACCESS 0
    	
Return aRotina

//-------------------------------------------------------------------
/*/{Protheus.doc} ModelDef
Funcao generica MVC do model
@return oModel - Objeto do Modelo MVC
@author Kenny Roger Martins
@since 25/01/2018
@version 1.0
/*/
//-------------------------------------------------------------------
Static Function ModelDef()

    Local oStMaster   := FWFormStruct(1, "ZV3") 
    Local oModel      := MPFormModel():New("VMIX004M",/*bPre*/, /*bPos*/,/*bCommit*/,/*bCancel*/)   //Instanciando o modelo
	Local cFormMaster := "FORM_MASTER"
       
    //Atribuindo formul�rios para o modelo
    oModel:AddFields(cFormMaster, /*cOwner*/, oStMaster)                       
    
    //chave prim�ria da rotina
    oModel:SetPrimaryKey({"ZV3_FILIAL", "ZV3_LOJA", "ZV3_DATA", "ZV3_PDV", "ZV3_EVECUP", "ZV3_EVENSU"})
 
    //Descri��o ao modelo
    oModel:SetDescription(cTitulo)
    
    //Descri��o do formul�rio
    oModel:GetModel(cFormMaster):SetDescription(cTitulo)

Return oModel

//-------------------------------------------------------------------
/*/{Protheus.doc} ViewDef
Funcao generica MVC do View
@return oView - Objeto da View MVC
@author Kenny Roger Martins
@since 25/01/2018
@version 1.0
/*/
//-------------------------------------------------------------------
Static Function ViewDef()
	
	Local oModel      := FWLoadModel("VMIX004")
    Local oStMaster   := FWFormStruct(2, "ZV3", /*CodeBlock*/)  
    Local oView       := FWFormView():New()
	Local cFormMaster := "FORM_MASTER"
	Local cViewMaster := "VIEW_MASTER"

    oView:SetModel(oModel)
    
    //Formul�rio para interface
    oView:AddField(cViewMaster, oStMaster, cFormMaster)
    
    //Container com nome tela com 100%
    oView:CreateHorizontalBox("TELA", 100)
     
    //T�tulo do formul�rio
    oView:EnableTitleView(cViewMaster, "Dados da " + cTitulo )  
     
    //Fechamento da janela na confirma��o
    oView:SetCloseOnOk({||.T.})
     
    //formul�rio da interface ser� colocado dentro do container
    oView:SetOwnerView(cViewMaster, "TELA")

Return oView

//-------------------------------------------------------------------
/*/{Protheus.doc} VMIX004L
Descri��o: Legenda
/*/
//-------------------------------------------------------------------
User Function VMIX004L() 
      
     Local aLegenda := {} 

     aAdd(aLegenda, {"BR_PRETO",    "Processando"}) 
     aAdd(aLegenda, {"BR_VERDE",    "Sucesso"}) 
     aAdd(aLegenda, {"BR_AMARELO",  "Advert�ncia"}) 
     aAdd(aLegenda, {"BR_VERMELHO", "Erro"}) 

     BrwLegenda(cTitulo, "Legenda", aLegenda) 

Return Nil 
