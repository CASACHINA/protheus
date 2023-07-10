
/*
Ponto de entrada para 
*/
User Function GT1OPDF()

	Local cAlias 	:= "SF1"
	Local nReg 		:= SF1->(Recno())
	Local aAreaAC9	:= AC9->(GetArea())
	Local cCodObj	:= AC9->AC9_CODOBJ
	Local aEntidade	:= {}

	//conout("GT1OPDF -> Objeto: " + AC9->AC9_CODOBJ + " Recno ->" + cValToChar(nReg))

	If ExistBlock("CXF0001")

		U_CXF0001(@cAlias, @nReg)

		DBSelectArea( cAlias )
		DBGoto( nReg )

		aEntidade := U_GEDENT( cAlias )

		If Len(aEntidade) > 0

			//conout("GT1OPDF -> Objeto: " + AC9->AC9_CODOBJ + " Chave : " + xFilial("AC9") + cCodObj + cAlias + xFilial(cAlias) + aEntidade[1])

			DBSelectArea("AC9")
			AC9->(DBSetOrder(1)) // AC9_FILIAL, AC9_CODOBJ, AC9_ENTIDA, AC9_FILENT, AC9_CODENT, R_E_C_N_O_, D_E_L_E_T_

			If AC9->(DBSeek(xFilial("AC9") + cCodObj + cAlias + xFilial(cAlias) + aEntidade[1]))

				//conout("GT1OPDF -> Objeto: " + AC9->AC9_CODOBJ + " Chave já atualizada!")

			Else

				RestArea(aAreaAC9)

				RecLock("AC9", .F.)
				AC9->AC9_ENTIDA	:= cAlias
				AC9->AC9_CODENT := aEntidade[1]
				AC9->AC9_XDATA  := Date()
				AC9->(MsUnLock())

				//conout("GT1OPDF -> Objeto: " + AC9->AC9_CODOBJ + " atualizado para " + cAlias + " Entidade: " + aEntidade[1])

			EndIf

		Else

			//conout("GT1OPDF -> Objeto: " + AC9->AC9_CODOBJ + " Nao carregou aEntidade")

		EndIf

	EndIf

	RestArea(aAreaAC9)

Return()
