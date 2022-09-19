#include 'protheus.ch'
#include 'fwmvcdef.ch'


user function MEst141()

	Local oBrowse

	IF u_CChWMSAtivo()

		oBrowse := FWMBrowse():New()
		oBrowse:SetAlias( "SF1" )
		oBrowse:SetDescription( "Liberação de conferência" )

		oBrowse:SetFilterDefault( "F1_FILIAL = '"+cFilAnt+"' .And. F1_TIPO $ 'NDB' .And. Empty(F1_STATUS)" )

		oBrowse:AddLegend('F1_STATCON $ " 1"','GREEN' ,"NF conferida")
		oBrowse:AddLegend('F1_STATCON == "0"','BLUE'  ,"NF nao conferida")
		oBrowse:AddLegend('F1_STATCON == "2"','RED'   ,"NF com divergencia")
		oBrowse:AddLegend('F1_STATCON == "3"','YELLOW',"NF em conferencia")
		oBrowse:AddLegend('F1_STATCON == "4"','BLACK' ,"NF Clas. C/ Diver.")

		oBrowse:SetMenuDef('CASACHINA_MEST141')

		oBrowse:Activate()

	Else
		Alert('Integração não ativada para esta filial ('+cFilAnt+')')
	EndIF

return



Static Function MenuDef()

	Local aRotina := {}

	//ADD OPTION aRotina Title "Visualizar" Action 'VIEWDEF.CASACHINA_MEST141.prw' OPERATION MODEL_OPERATION_VIEW   ACCESS 0
	ADD OPTION aRotina Title "Liberar"    Action 'u_MEst14Lib' OPERATION MODEL_OPERATION_UPDATE ACCESS 0

Return aRotina


user function MEst14Lib()

	IF ! F1_STATCON $ " 1"

		IF Aviso('Liberação','Confirma a liberação da conferencia?',{'Liberar','Cancelar'},1) == 1

			Reclock("SF1",.F.)
			SF1->F1_STATCON := '1'
			SF1->F1_LIBCONF := cUserName + " em " + FormDate(Date()) + " as " + Time()
			SF1->( MsUnlock() )

		EndIF

	Else
		Aviso('Atenção','Documento já foi conferido.',{'Sair'},1)
	EndIF

return