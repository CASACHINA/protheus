#INCLUDE 'PROTHEUS.CH'
#INCLUDE 'FWMVCDEF.CH'

/*/{Protheus.doc} VMIX011
Valid produtos nivel empresa
/*/ 

User Function VMIX011(cFil, cProduto)

	Local lRet 		:= .F.
	LOCAL cCampo 	:= ReadVar()
	
	Default cFil		:= cEmpAnt
	Default cProduto	:= &(cCampo)

	If FWIsInCallStack("MATA311")

		cFil := FWFldGet("NNT_FILDES")

	Else

		cFil := cFilAnt

	EndIf

	DbSelectArea("SZH")
	SZH->(dbSetOrder(2)) // SZH_FILIAL, SZH_CODEMP, SZH_CODFIL, SZH_NIVEL, R_E_C_N_O_, D_E_L_E_T_

	If SZH->(DbSeek(xFilial("SZH") + cEmpAnt + cFil))

		If SZH->SZH_MSBLQL == "1"

			lRet := .T.

		Else

			DbSelectArea("SB1")
			SB1->(dbSetOrder(1)) // B1_FILIAL, B1_COD, R_E_C_N_O_, D_E_L_E_T_

			If SB1->(DbSeek(xFilial("SB1") + cProduto))

				If SZH->SZH_NIVEL == "1"

					lRet := SB1->B1_YNIVELJ $ '1|2|3|4|5'

				ElseIf SZH->SZH_NIVEL == "2"

					lRet := SB1->B1_YNIVELJ $ '2|3|4|5'

				ElseIf SZH->SZH_NIVEL == "3"

					lRet := SB1->B1_YNIVELJ $ '3|4|5'

				ElseIf SZH->SZH_NIVEL == "4"

					lRet := SB1->B1_YNIVELJ $ '4|5'

				ElseIf SZH->SZH_NIVEL == "5"

					lRet := SB1->B1_YNIVELJ $ '5'

				EndIf

			EndIf

		EndIf

	EndIf

Return(lRet)
