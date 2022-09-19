#INCLUDE 'protheus.ch'
#INCLUDE "rwmake.ch"

User Function MT120BRW()

	AAdd( aRotina, { 'GED', "U_GED", 0, 4 } )
	
	//Retira o conhecimento do Menu
	nPos := ASCAN(aRotina, { |x|   If(ValType(x[2])=="C",UPPER(x[2]) == "MSDOCUMENT",.F.) })
	
	If nPos > 0
	
		Adel(aRotina,nPos)
		
		Asize(aRotina,Len(aRotina)-1)
	
	EndIf
	
Return()
