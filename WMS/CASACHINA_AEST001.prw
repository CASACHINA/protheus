#Include 'Protheus.ch'
#Include 'FWMVCDef.ch'
#Include "TOPCONN.CH"

User Function AEST001()

	Local oBrowse := Nil

	oBrowse := FWMBrowse():New()
	oBrowse:SetAlias("DA1")
	oBrowse:SetDescription("Tabela de Preços")
	oBrowse:SetMenuDef('CASACHINA_AEST001')
	oBrowse:Activate()

Return

Static Function MenuDef()

	Local aRotina := {}

	aAdd(aRotina,{'Visualizar'	,'VIEWDEF.CASACHINA_AEST001',0,2,0,NIL})
	//aAdd(aRotina,{'Incluir'		,'VIEWDEF.CASACHINA_AEST001',0,3,0,NIL})
	//aAdd(aRotina,{'Alterar'		,'VIEWDEF.CASACHINA_AEST001',0,4,0,NIL})
	//aAdd(aRotina,{'Excluir'		,'VIEWDEF.CASACHINA_AEST001',0,5,0,NIL})

Return( aRotina )


//-------------------------------------------------------------------
/*/{Protheus.doc} ModelDef
Definição do modelo de Dados

@author Mario L. B. Faria

@since 27/07/2017
@version 1.0
/*/
//-------------------------------------------------------------------

Static Function ModelDef()

	Local oModel
	Local oStr1:= FWFormStruct(1,'DA1')

	oModel := MPFormModel():New('AEST001_MAIN',,{|oModel| VALPRD()})
	oModel:SetDescription('Tabela de Preços')

	oStr1:AddTrigger( 'DA1_CODTAB', 'DA1_ITEM'	, { || .T. }, {|oModel| U_AEST01IT()} )
	oStr1:AddTrigger( 'DA1_CODTAB', 'DA1_DESTAB', { || .T. }, {|oModel| U_AEST01TB()} )
	oStr1:AddTrigger( 'DA1_CODPRO', 'DA1_DESCRI', { || .T. }, {|oModel| U_AEST01PR()} )

	oModel:addFields('MODEL_DA1',,oStr1)

	oStr1:SetProperty( 'DA1_CODTAB'	,MODEL_FIELD_VALID	,{|| .T.})
	oStr1:SetProperty( 'DA1_CODPRO'	,MODEL_FIELD_VALID	,{|| .T.})
	oStr1:SetProperty( 'DA1_PRCVEN'	,MODEL_FIELD_VALID	,{|| Positivo()})
	oStr1:SetProperty( 'DA1_VLRDES'	,MODEL_FIELD_VALID	,{|| Positivo()})
	oStr1:SetProperty( 'DA1_PERDES'	,MODEL_FIELD_VALID	,{|| Positivo()})

	oStr1:SetProperty( 'DA1_CODTAB'	,MODEL_FIELD_WHEN	,{|| INCLUI })
	oStr1:SetProperty( 'DA1_CODPRO'	,MODEL_FIELD_WHEN	,{|| INCLUI })
	
	oModel:GetModel('MODEL_DA1'):GetStruct():SetProperty("DA1_CODTAB",MODEL_FIELD_VALID,{|| VALTAB() })

Return oModel
//-------------------------------------------------------------------
/*/{Protheus.doc} ViewDef
Definição do interface

@author Mario L. B. Faria

@since 27/07/2017
@version 1.0
/*/
//-------------------------------------------------------------------

Static Function ViewDef()

	Local oView
	Local oModel	:= ModelDef()
	Local oStr1		:= FWFormStruct(2, 'DA1')
	Local cCpoNot	:= "DA1_REFGRD|DA1_GRUPO|DA1_MOEDA"
	Local aStruDA1  := aClone(oStr1:GetFields())

	oView := FWFormView():New()

	oView:SetModel(oModel)
	oView:AddField('VIEW_DA1' , oStr1,'MODEL_DA1' )
	oView:CreateHorizontalBox( 'BOX_VIEW_DA1', 100)
	oView:SetOwnerView('VIEW_DA1','BOX_VIEW_DA1')

	For nX := 1 To Len(aStruDA1)
		If Alltrim(aStruDA1[nX][01]) $ cCpoNot
			oStr1:RemoveField(aStruDA1[nX][01])
		EndIf
	Next nX

Return oView

/*/{Protheus.doc} AEST01IT
Gatilho do campo DA1_CODTAB para DA1_ITEM
@author Mario L. B. Faria
@since 27/07/2017
@version 1.0

@type function
/*/
User Function AEST01IT()

	Local cRet		:= ""
	Local cQuery	:= ""
	Local oModel 	:= FWModelActive()
	Local cAlItem	:= GetNextAlias()

	cQuery := "	SELECT MAX(DA1_ITEM) ITEM " + CRLF
	cQuery += "	FROM " + RetSqlName("DA1") + " " + CRLF
	cQuery += "	WHERE " + CRLF
	cQuery += "			DA1_FILIAL = '" + xFilial("DA1") + "' " + CRLF
	cQuery += "		AND DA1_CODTAB = '" + oModel:GetModel('MODEL_DA1'):GetValue("DA1_CODTAB") + "' " + CRLF
	cQuery += "		AND D_E_L_E_T_ = ' ' " + CRLF

	TcQuery cQuery NEW ALIAS (cAlItem)

	cRet := SOMA1((cAlItem)->ITEM)

	(cAlItem)->(DbCloseArea())

Return cRet

/*/{Protheus.doc} AEST01TB
Gatilho do campo DA1_CODTAB para DA1_DESTAB
@author Mario L. B. Faria
@since 27/07/2017
@version 1.0

@type function
/*/
User Function AEST01TB()
	Local oModel 	:= FWModelActive()
	Local cRet		:= SubStr(Posicione("DA0",1,xFilial("DA0")+oModel:GetModel('MODEL_DA1'):GetValue("DA1_CODTAB"),"DA0_DESCRI"),1,TamSx3("DA1_DESTAB")[01])
Return cRet

/*/{Protheus.doc} AEST01PR
Gatilho do campo DA1_CODPRO para DA1_DESCRI
@author Mario L. B. Faria
@since 27/07/2017
@version 1.0

@type function
/*/
User Function AEST01PR()
	Local oModel 	:= FWModelActive()
	Local cRet		:= SubStr(Posicione("SB1",1,xFilial("SB1")+oModel:GetModel('MODEL_DA1'):GetValue("DA1_CODPRO"),"B1_DESC"),1,TamSx3("DA1_DESCRI")[01])
Return cRet

/*/{Protheus.doc} VALPRD
Função para validar se o produto ka esta cadastrada na tabela de preços
@author Mario L. B. Faria
@since 05/09/2017
@version undefined

@type function
/*/
Static Function VALPRD()

	Local lRet		:= .T.
	Local DA1TMP	:= ""
	Local cQuery	:= ""

	If INCLUI
	
		DA1TMP	:= GetNextAlias()
	
		cQuery := "	SELECT " + CRLF
		cQuery += "		DA1_CODPRO " + CRLF
		cQuery += "	FROM " + RetSqlName("DA1") + " " + CRLF
		cQuery += "	WHERE  " + CRLF
		cQuery += "			DA1_FILIAL = '" + xFilial("DA1") + "' " + CRLF
		cQuery += "		AND DA1_CODTAB = '" + FWFldGet('DA1_CODTAB') + "' " + CRLF
		cQuery += "		AND DA1_CODPRO = '" + FWFldGet('DA1_CODPRO') + "' " + CRLF
		cQuery += "		AND D_E_L_E_T_ = ' ' " + CRLF
		
		TCQuery cQuery New Alias (DA1TMP)
		
		If !Empty((DA1TMP)->DA1_CODPRO)
			Help("","","Tabela de Preços",,CRLF + "Produto já cadastrado nesta tabela de preços.", 1, 0)
			lRet := .F.
		EndIf
		
		(DA1TMP)->(dbCloseArea())
		
	EndIf
	
Return lRet

/*/{Protheus.doc} VALTAB
Função para validar Codigo da Tabela
@author Mario L. B. Faria
@since 05/09/2017
@version undefined

@type function
/*/
Static Function VALTAB()

	Local oModel 	:= FWModelActive()
	Local lRet		:= .T.

	If Empty(Posicione("DA0",1,xFilial("DA0")+oModel:GetModel("MODEL_DA1"):GetValue("DA1_CODTAB"),"DA0_CODTAB"))
		oModel:GetModel("MODEL_DA1"):SetValue('DA1_ITEM',Space(TamSx3("DA1_ITEM")[01]))
		oModel:GetModel("MODEL_DA1"):SetValue('DA1_DESTAB',Space(TamSx3("DA1_DESTAB")[01]))
		lRet := .F.
	EndIf

Return lRet


