#include 'protheus.ch'


user function LJ7053()

return u_FTVD7053()

user function FTVD7053()

	Local aRotina := {}

		aAdd( aRotina, {"NÃO USAR - Retransmite nota perdida", "u_dontUse", 0 , 2 , , .T. } )

return aRotina


user function dontUse()

	Local cKeyNfce  := ''
	Local cDescErro := ""

	//Local lErroNFCe := ! Lj701CNFCe( SL1->L1_FILIAL, SL1->L1_NUM, SL1->L1_DOC, SL1->L1_SERIE, SL1->L1_PDV, .T., @cKeyNFCe, @cDescErro)
	Local cCodFil := SL1->L1_FILIAL
	Local cNumOrc := SL1->L1_NUM
	Local nNFCeRet := LjNFCeGera(cCodFil, cNumOrc, @cKeyNFCe, Nil, Nil, @cDescErro)


return