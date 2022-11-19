//Bibliotecas
#Include "Totvs.ch"
#Include "FWMVCDef.ch"

//Variveis Estaticas
Static cTitulo := "Parametros Fiscais -  Visual Mix"
Static cTabPai := "SZ1"
Static cTabFilho := "SZ1"

/*/{Protheus.doc} User Function CCFI001
Função responsavel por realizar as configurações Fiscais a serem consideradas no Visual Mix
@author Kaique
@since 30/11/2020
@version 1.0
@type function
/*/

User Function CCFI001()
	Local aArea   := GetArea()
	Local oBrowse
	Private aRotina := {}

	//Definicao do menu
	aRotina := MenuDef()

	//Instanciando o browse
	oBrowse := FWMBrowse():New()
	oBrowse:SetAlias(cTabPai)
	oBrowse:SetDescription(cTitulo)

	//Adicionando as Legendas
	oBrowse:AddLegend( "SZ1->Z1_MSBLQL == '1'", "RED",    "Bloqueado" )
	oBrowse:AddLegend( "SZ1->Z1_MSBLQL == '2' .OR.  EMPTY(SZ1->Z1_MSBLQL )", "GREEN",    "Ativo" )

	//Ativa a Browse
	oBrowse:Activate()

	RestArea(aArea)
Return Nil

/*/{Protheus.doc} MenuDef
Menu de opcoes na funcao CCFI001
@author Kaique
@since 30/11/2020
@version 1.0
@type function
/*/

Static Function MenuDef()
	Local aRotina := {}

	//Adicionando opcoes do menu
	ADD OPTION aRotina TITLE "Visualizar" ACTION "VIEWDEF.CCFI001" OPERATION 1 ACCESS 0
	ADD OPTION aRotina TITLE "Incluir" ACTION "VIEWDEF.CCFI001" OPERATION 3 ACCESS 0
	ADD OPTION aRotina TITLE "Alterar" ACTION "VIEWDEF.CCFI001" OPERATION 4 ACCESS 0
	ADD OPTION aRotina TITLE "Excluir" ACTION "VIEWDEF.CCFI001" OPERATION 5 ACCESS 0

Return aRotina

/*/{Protheus.doc} ModelDef
Modelo de dados na funcao CCFI001
@author Kaique
@since 30/11/2020
@version 1.0
@type function
/*/

Static Function ModelDef()
	Local oStruPai := FWFormStruct(1, cTabPai, {|x| Alltrim(x) $ 'Z1_PRODUTO~Z1_DESCRIC' })
	Local oStruFilho := FWFormStruct(1, cTabFilho, {|x| !(Alltrim(x) $ 'Z1_PRODUTO~Z1_DESCRIC')}  ) 
	Local aRelation := {}
	Local oModel
	Local bPre := Nil
	Local bPos := Nil
	Local bCommit := Nil
	Local bCancel := Nil
	Local aAux :=   FwStruTrigger(;
					"Z1_PRODUTO" ,; // Campo Dominio
					"Z1_DESCRIC  " ,; // Campo de Contradominio
					"Posicione('SB1',1,xFilial('SB1')+M->Z1_PRODUTO,'B1_DESC')",; // Regra de Preenchimento
					.F. ,; // Se posicionara ou nao antes da execucao do gatilhos
					"" ,; // Alias da tabela a ser posicionada
					0 ,; // Ordem da tabela a ser posicionada
					"" ,; // Chave de busca da tabela a ser posicionada
					NIL ,; // Condicao para execucao do gatilho
					"001" ) // Sequencia do gatilho (usado para identificacao no caso de erro)


	oStruPai:AddTrigger(aAux[1],aAux[2],aAux[3],aAux[4])

	//Cria o modelo de dados para cadastro
	oModel := MPFormModel():New("CCFI001M", bPre, bPos, bCommit, bCancel)
	oModel:AddFields("SZ1MASTER", /*cOwner*/, oStruPai)
	oModel:AddGrid("SZ1DETAIL","SZ1MASTER",oStruFilho,/*bLinePre*/, /*bLinePost*/,/*bPre - Grid Inteiro*/,/*bPos - Grid Inteiro*/,/*bLoad - Carga do modelo manualmente*/)
	oModel:SetDescription("Modelo de dados - " + cTitulo)
	oModel:GetModel("SZ1MASTER"):SetDescription( "Dados de - " + cTitulo)
	//oModel:GetModel("SZ1DETAIL"):SetDescription( "Grid de - " + cTitulo)
	oModel:SetPrimaryKey({"Z1_FILIAL","Z1_PRODUTO"})

	//Fazendo o relacionamento
	aAdd(aRelation, {"Z1_FILIAL", "FWxFilial('SZ1')"} )
	//aAdd(aRelation, {"Z1_FILCFG", "Z1_FILCFG"})
	aAdd(aRelation, {"Z1_PRODUTO", "Z1_PRODUTO"})
	oModel:SetRelation("SZ1DETAIL", aRelation, SZ1->(IndexKey(1)))
	oModel:GetModel("SZ1DETAIL"):SetUniqueLine({"Z1_UF"})

Return oModel

/*/{Protheus.doc} ViewDef
Visualizacao de dados na funcao CCFI001
@author Kaique
@since 30/11/2020
@version 1.0
@type function
/*/

Static Function ViewDef()
	Local oModel := FWLoadModel("CCFI001")
	Local oStruPai := FWFormStruct(2, cTabPai, {|x| Alltrim(x) $ 'Z1_PRODUTO~Z1_DESCRIC' })
	Local oStruFilho := FWFormStruct(2, cTabFilho, {|x| !(Alltrim(x) $ 'Z1_PRODUTO~Z1_DESCRIC') })
	Local oView

	//Cria a visualizacao do cadastro
	oView := FWFormView():New()
	oView:SetModel(oModel)
	oView:AddField("VIEW_SZ1", oStruPai, "SZ1MASTER")
	oView:AddGrid("VIEW_GRID",  oStruFilho,  "SZ1DETAIL")

	//Partes da tela
	oView:CreateHorizontalBox("CABEC", 30)
	oView:CreateHorizontalBox("GRID", 70)
	oView:SetOwnerView("VIEW_SZ1", "CABEC")
	oView:SetOwnerView("VIEW_GRID", "GRID")

	//Titulos
	//oView:EnableTitleView("VIEW_SZ1", "")
	oView:EnableTitleView("VIEW_GRID", "Configurações por Filial")

Return oView
