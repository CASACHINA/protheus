User Function MTA103MNU()

	Local nPos := 0

	AAdd( aRotina, { 'GED', "U_GED", 0, 4 } )

	//Retira o conhecimento do Menu
	nPos := ASCAN(aRotina, { |x|   If(ValType(x[2])=="C",UPPER(x[2]) == "MSDOCUMENT",.F.) })

	If nPos > 0

		Adel(aRotina,nPos)

		Asize(aRotina,Len(aRotina)-1)

	EndIf

	TCyberLogIntegracao():AddMenu(.T.)

	// Ponto de chamada ConexãoNF-e
	U_GTPE010()

Return
