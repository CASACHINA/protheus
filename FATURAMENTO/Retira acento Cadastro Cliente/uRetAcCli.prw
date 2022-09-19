

// ####################################################################################################################################################################################################
//
// Projeto   : Casa China 
// Modulo    : Faturamento
// Fonte     : uRetAcCli
// Data      : 21/01/2020
// Autor     : Valberg Moura 
// Descricao : Remoção de caracteres especiais do cadstro de cliente, devido a integração do visualmix
//
// ####################################################################################################################################################################################################

#INCLUDE "Topconn.ch"
#INCLUDE "Protheus.ch"


User Function uRetAcCli()


DbSelectArea("SA1")
DbSetOrder(1)

DbGoTop()

While !SA1->(Eof())

	If (NoAcento(SA1->A1_END )  <> SA1->A1_END) .or. (NoAcento(SA1->A1_MUN) <> SA1->A1_MUN) .or. (NoAcento(SA1->A1_BAIRRO) <> SA1->A1_BAIRRO) 
	
		Reclock("SA1", .F.)
		
		SA1->A1_END := NoAcento(SA1->A1_END ) 
		SA1->A1_MUN := NoAcento(SA1->A1_MUN ) 
		SA1->A1_BAIRRO := NoAcento(SA1->A1_BAIRRO ) 
		
		SA1->(MsUnlock())
		
	Endif

	SA1->(DbSkip())
Enddo


Return


Static FUNCTION NoAcento(cString)
Local cChar  := ""
Local nX     := 0
Local nY     := 0
Local cVogal := "aeiouAEIOU"
Local cAgudo := "áéíóú"+"ÁÉÍÓÚ"
Local cCircu := "âêîôû"+"ÂÊÎÔÛ"
Local cTrema := "äëïöü"+"ÄËÏÖÜ"
Local cCrase := "àèìòù"+"ÀÈÌÒÙ"
Local cTio   := "ãõ"
Local cCecid := "çÇ"

For nX:= 1 To Len(cString)
	cChar:=SubStr(cString, nX, 1)
	IF cChar$cAgudo+cCircu+cTrema+cCecid+cTio+cCrase
		nY:= At(cChar,cAgudo)
		If nY > 0
			cString := StrTran(cString,cChar,SubStr(cVogal,nY,1))
		EndIf
		nY:= At(cChar,cCircu)
		If nY > 0
			cString := StrTran(cString,cChar,SubStr(cVogal,nY,1))
		EndIf
		nY:= At(cChar,cTrema)
		If nY > 0
			cString := StrTran(cString,cChar,SubStr(cVogal,nY,1))
		EndIf
		nY:= At(cChar,cCrase)
		If nY > 0
			cString := StrTran(cString,cChar,SubStr(cVogal,nY,1))
		EndIf
		nY:= At(cChar,cTio)
		If nY > 0
			cString := StrTran(cString,cChar,SubStr("ao",nY,1))
		EndIf
		nY:= At(cChar,cCecid)
		If nY > 0
			cString := StrTran(cString,cChar,SubStr("cC",nY,1))
		EndIf
	Endif
Next

For nX:=1 To Len(cString)
	cChar:=SubStr(cString, nX, 1)
	If Asc(cChar) < 32 .Or. Asc(cChar) > 123 .Or. cChar $ '&'
		cString:=StrTran(cString,cChar,".")
	Endif
Next nX

cString := _NoTags(cString)


Return(cString)
