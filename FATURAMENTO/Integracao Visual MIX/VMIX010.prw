#INCLUDE 'PROTHEUS.CH'
#INCLUDE 'FWMVCDEF.CH'

/*/{Protheus.doc} VMIX010
Filtro consulta padra SB1NIV
/*/ 

User Function VMIX010()

	Local cRet := "1 == 2"
	Local cFil := cFilAnt

	If FWIsInCallStack("MATA311")

		cFil := FWFldGet("NNT_FILDES")

	Else

		cFil := cFilAnt

	EndIf

	DbSelectArea("SZH")
	SZH->(dbSetOrder(2)) // SZH_FILIAL, SZH_CODEMP, SZH_CODFIL, SZH_NIVEL, R_E_C_N_O_, D_E_L_E_T_

	If SZH->(DbSeek(xFilial("SZH") + cEmpAnt + cFil))

		If SZH->SZH_MSBLQL == "1"

			cRet := "1 == 1"

		Else

			If SZH->SZH_NIVEL == "1"

				cRet := "SB1->B1_YNIVELJ $ '1|2|3|4|5'"

			ElseIf SZH->SZH_NIVEL == "2"

				cRet := "SB1->B1_YNIVELJ $ '2|3|4|5'"

			ElseIf SZH->SZH_NIVEL == "3"

				cRet := "SB1->B1_YNIVELJ $ '3|4|5'"

			ElseIf SZH->SZH_NIVEL == "4"

				cRet := "SB1->B1_YNIVELJ $ '4|5'"

			ElseIf SZH->SZH_NIVEL == "5"

				cRet := "SB1->B1_YNIVELJ $ '5'"

			EndIf

		EndIf

	EndIf

Return(cRet)
