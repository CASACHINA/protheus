#include  "TOTVS.CH"
//#include "POSCSS.CH"

User Function StValPro()
	Local lRet    := .T.
	Local cCodPrd := PARAMIXB[1]

	If ! SB1->(dbSeek(xFilial("SB1")+cCodPrd ))
		STFMessage("ItemRegistered","STOP","Produto Não Cadastrado !")
		lRet := .F.
	EndIf
Return lRet
