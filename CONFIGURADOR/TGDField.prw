#INCLUDE "TOTVS.CH"

/*/{Protheus.doc} TGDField
@author Wlysses Cerqueira (WlyTech)
@since 22/02/2021  
@Project 
@version 1.0
@description 
@type Class
/*/

Class TGDField

	Data Fields

	Method New() Constructor
	Method AddField(cFieldName)
	Method FieldName(cFieldName)
	Method FieldPos(cFieldName) 
	Method Clear()
	Method GetHeader()
	Method GetTitleList() 

EndClass

Method New() Class TGDField

	::Fields := HashTable():New()

Return()

Method AddField(cFieldName) Class TGDField

	Local aArea := SX3->(GetArea())
	Local oField := TGDFieldProperties():New()
	Local aStruct := {}

	If !Empty(cFieldName)

		aStruct := FWSX3Util():GetFieldStruct(cFieldName)

		If Len(aStruct) > 0

			oField:cName := GetSx3Cache(aStruct[1], "X3_CAMPO")
			oField:cTitle := GetSx3Cache(aStruct[1], "X3_TITULO")
			oField:cPict := GetSx3Cache(aStruct[1], "X3_PICTURE")
			oField:nSize := GetSx3Cache(aStruct[1], "X3_TAMANHO")
			oField:nDecimal := GetSx3Cache(aStruct[1], "X3_DECIMAL")
			oField:cValid := GetSx3Cache(aStruct[1], "X3_VALID")
			oField:cUsed := GetSx3Cache(aStruct[1], "X3_USADO")
			oField:cType := GetSx3Cache(aStruct[1], "X3_TIPO")
			oField:cF3 := GetSx3Cache(aStruct[1], "X3_F3")
			oField:cContext := GetSx3Cache(aStruct[1], "X3_CONTEXT")
			oField:cCbox := GetSx3Cache(aStruct[1], "X3_CBOX")
			oField:cRelation := GetSx3Cache(aStruct[1], "X3_RELACAO")
			oField:cWhen := GetSx3Cache(aStruct[1], "X3_WHEN")
			oField:cVisual := GetSx3Cache(aStruct[1], "X3_VISUAL")
			oField:cVldUser := GetSx3Cache(aStruct[1], "X3_VLDUSER")
			oField:cPictVar := GetSx3Cache(aStruct[1], "X3_PICTVAR")
			oField:lObrigat := Subs(Bin2Str(GetSx3Cache(aStruct[1], "X3_OBRIGAT")),1,1) == "x"

		Else

			oField:cName := cFieldName

		EndIf

	EndIf

	::Fields:Add(cFieldName, oField)

	RestArea(aArea)

Return()

Method FieldName(cFieldName) Class TGDField

Return(::Fields:GetItem(cFieldName))

Method FieldPos(cFieldName) Class TGDField

	Local nCount := 0

	For nCount := 1 To ::Fields:GetCount()

		If AllTrim(::Fields:GetValue(nCount):cName) == AllTrim(cFieldName)

			Exit

		EndIf

	Next nCount

Return(nCount)

Method Clear() Class TGDField

	::Fields:Clear()

Return()

Method GetHeader() Class TGDField

	Local nCount
	Local aHeader := {}

	For nCount := 1 To ::Fields:GetCount()

		aAdd(aHeader, {::Fields:GetValue(nCount):cTitle, ::Fields:GetValue(nCount):cName, ::Fields:GetValue(nCount):cPict, ::Fields:GetValue(nCount):nSize,;
			::Fields:GetValue(nCount):nDecimal, ::Fields:GetValue(nCount):cValid, ::Fields:GetValue(nCount):cUsed, ::Fields:GetValue(nCount):cType,;
			::Fields:GetValue(nCount):cF3, ::Fields:GetValue(nCount):cContext, ::Fields:GetValue(nCount):cCbox, ::Fields:GetValue(nCount):cRelation,;
			::Fields:GetValue(nCount):cWhen, ::Fields:GetValue(nCount):cVisual, ::Fields:GetValue(nCount):cVldUser, ::Fields:GetValue(nCount):cPictVar,;
			::Fields:GetValue(nCount):lObrigat})
	Next

Return(aHeader)

Method GetTitleList() Class TGDField

	Local nCount	:= 0
	Local aHeader 	:= {}

	For nCount := 1 To ::Fields:GetCount()

		aAdd(aHeader, AllTrim(::Fields:GetValue(nCount):cTitle))

	Next nCount

Return(aHeader)

Class TGDFieldProperties 

 	Data cName
 	Data cTitle
	Data cPict
	Data nSize
	Data nDecimal
	Data cValid
	Data cUsed
	Data cType
	Data cF3
	Data cContext
	Data cCbox
	Data cRelation
	Data cWhen
	Data cVisual
	Data cVldUser
	Data cPictVar
	Data lObrigat
	Data nSort // 0=Sem ordenação; 1=Ascendente; 2=Descendente
		
	Method New() Constructor	
	
EndClass

Method New() Class TGDFieldProperties

 	::cName := ""
 	::cTitle := ""
	::cPict := ""
	::nSize := 0
	::nDecimal := 0
	::cValid := ""
	::cUsed := ""
	::cType := ""
	::cF3 := ""
	::cContext := ""
	::cCbox := ""
	::cRelation := ""
	::cWhen := ""
	::cVisual := ""
	::cVldUser := ""
	::cPictVar := ""
	::lObrigat := ""
	::nSort := 0

Return()
