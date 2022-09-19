#INCLUDE 'PROTHEUS.CH'
#INCLUDE 'FWMVCDEF.CH'

/*/{Protheus.doc} LJ720CABEC
Cadastro Nivel de empresa
/*/ 

Static _cDoc_ := ""
Static _cSerie_ := ""

User Function LJ720CABEC()

	Local aAreaTRB  := TRB->(GetArea())
	Local nW        := 0
	Local nPosNfOri := 0
	Local nPosSeOri := 0
	Local nPosDoc	:= 0
	Local nPosSerie	:= 0
	Local aCabec_	:= PARAMIXB[1]
	// Local aItens_	:= PARAMIXB[2]

	If FWIsInCallStack("U_VMIX014")

		nPosNfOri := aScan(aItens[1], {|x| AllTrim( x[1] ) == "TRB_NFORI"})
		nPosSeOri := aScan(aItens[1], {|x| AllTrim( x[1] ) == "TRB_SERORI"})

		TRB->(DBGoTop())

		For nW := 1 To Len(aItens)

			RecLock("TRB", .F.)
			TRB->TRB_NFORI  := aItens[nw][nPosNfOri][2]
			TRB->TRB_SERORI := aItens[nw][nPosSeOri][2]
			TRB->(MsUnlock())

			TRB->(DBSkip())

		Next nW

		nPosDoc 	:= aScan(aCabec_, {|x| AllTrim( x[1] ) == "F1_DOC"})
		nPosSerie 	:= aScan(aCabec_, {|x| AllTrim( x[1] ) == "F1_SERIE"})

		_cDoc_ 		:= aCabec_[nPosDoc][2]
		_cSerie_ 	:= aCabec_[nPosSerie][2]

	EndIf

	RestArea(aAreaTRB)

Return(PARAMIXB[1])

User Function X720DOC()
Return(_cDoc_)

User Function X720SER()
Return(_cSerie_)

User Function X720DOCL()
	_cDoc_ := ""
Return()

User Function X720SERL()
	_cSerie_ := ""
Return()
