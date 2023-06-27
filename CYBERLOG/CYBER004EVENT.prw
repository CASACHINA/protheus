#INCLUDE "TOTVS.CH"
#INCLUDE "FWMVCDEF.CH"
#INCLUDE "FWEVENTVIEWCONSTS.CH"


Class CYBER004EVENT FROM FWModelEvent

	Method New() CONSTRUCTOR

	Method VldActivate(oModel, cModelId)
	Method ModelPosVld(oModel, cModelId)
	Method InTTS(oModel, cModelId)
	// Method GridLinePosVld(oModel,cModelId)

End Class

Method New() Class CYBER004EVENT
Return( self )

Method VldActivate(oModel, cModelId) Class CYBER004EVENT

	Local lReturn   := .T.


Return( lReturn )

Method ModelPosVld(oModel, cModelId) Class CYBER004EVENT

	Local lRet 		:= .T.
	Local oObjAuth	:= TCyberlogApiAuth():New()
	Local cLocalOri	:= ""
	Local cLocalDes	:= ""
	Local nX		:= 0

	Local oCab		:= oModel:GetModel("MASTER")
	Local oGrid		:= oModel:GetModel("DETAIL_1")

	oCab:SetValue("ZA5_HORA", Time())

	For nX := 1 To oGrid:GetQtdLine()

		oGrid:GoLine(nX)

		If !oGrid:IsDeleted()

			If Empty(oGrid:GetValue("ZA6_LOCORI")) .Or. Empty(oGrid:GetValue("ZA6_LOCDES"))

				lRet := .F.

				Help(NIL, NIL, "HELP", NIL, "O preenchimento do almoxarifado é obrigatório!", 1, 0, NIL, NIL, NIL, NIL, NIL, {"Verifique a linha " + cValToChar(nX) + "!"})

			EndIf

			If oGrid:GetValue("ZA6_LOCORI") == oGrid:GetValue("ZA6_LOCDES")

				lRet := .F.

				Help(NIL, NIL, "HELP", NIL, "Nescessário informar almoxarifados diferentes!", 1, 0, NIL, NIL, NIL, NIL, NIL, {"Verifique a linha " + cValToChar(nX) + "!"})

			EndIf

			cLocalOri := oGrid:GetValue("ZA6_LOCORI")
			
			cLocalDes := oGrid:GetValue("ZA6_LOCDES")

		EndIf

		If !lRet

			Exit

		EndIf

	Next nX

	If lRet

		If cLocalOri == oObjAuth:cLocalPadrao

			oCab:SetValue("ZA5_DEPPED", oObjAuth:cDeposito)

		ElseIf cLocalOri == oObjAuth:cLocalB2B

			oCab:SetValue("ZA5_DEPPED", oObjAuth:cDepositoB2B)

		EndIf

		If cLocalDes == oObjAuth:cLocalPadrao

			oCab:SetValue("ZA5_DEPREC", oObjAuth:cDeposito)

		ElseIf cLocalDes == oObjAuth:cLocalB2B

			oCab:SetValue("ZA5_DEPREC", oObjAuth:cDepositoB2B)

		EndIf

	EndIf

Return(lRet)

Method InTTS(oModel, cModelId, nOperation) Class CYBER004EVENT

	Local lRet := .T.


Return(lRet)
