#include "totvs.ch"

/*/{Protheus.doc} RT001
@author unknown
@since 26/08/2017
@version 12
@type function
/*/
user function RT001()
	
	local aAreaNNR := NNR->(getArea())
	local aProc    := {}
	local i
	
	NNR->(dbGoTop())
	while !NNR->(EoF())
		
		aAdd(aProc, {NNR->NNR_CODIGO, NNR->NNR_FILIAL})
		
		NNR->(dbSkip())
	endDo
	restArea(aAreaNNR)
	
	for i := 1 to len(aProc)
		
		criaSB2(SB1->B1_COD, aProc[i, 1], aProc[i, 2]) // Criando saldo zerado na SB2   
	next i
	
return nil 

/*user function RT002()

	local aAreaNNR := NNR->(getArea())
	local aProc    := {}
	local i
    
		ALERT ("ENTROU RT002")  
		
	
	NNR->(dbGoTop())
	while !NNR->(EoF())
	
	DbSelectArea("SB2")
    SB2->(DbGoTop())
	SB2->(DbSetOrder(1))


		If !SB2->(DbSeek(xFilial("SB2")+SB2->B2_COD+SB2->B2_LOCAL))
			
			aAdd(aProc, {NNR->NNR_CODIGO, NNR->NNR_FILIAL})
		   		ALERT ("ENTROU SEGUNDA PARTE?")	
		EndIf
		NNR->(dbSkip())
	endDo
	restArea(aAreaNNR)
	
	
	for i := 1 to len(aProc)
		criaSB2(SB4->B4_COD, aProc[i, 1], aProc[i, 2]) // Criando saldo zerado na SB2   
	next i
	

return nil */    

user function RT002()
	
	local aAreaNNR := NNR->(getArea())
	local aProc    := {}
	local i
	
	NNR->(dbGoTop())
	while !NNR->(EoF())
		
		aAdd(aProc, {NNR->NNR_CODIGO, NNR->NNR_FILIAL})
		
		NNR->(dbSkip())
	endDo
	restArea(aAreaNNR)
	
	for i := 1 to len(aProc)
		//alert("entrou"+SB4->B4_COD)
		criaSB2(SB4->B4_COD, aProc[i, 1], aProc[i, 2]) // Criando saldo zerado na SB2   
	next i
	
return nil 
/*
	User Function ITEM()
	
    Local aParam 		:= PARAMIXB
    Local lRet 			:= .T.
    Local oObj 			:= ""
    Local cIdPonto 		:= ""
    Local cIdModel 		:= ""
    Local lIsGrid 		:= .F.

 
    If aParam <> NIL
        oObj := aParam[1]
        cIdPonto := aParam[2]
        cIdModel := aParam[3]
        lIsGrid := (Len(aParam) > 3)
 
        If cIdPonto == "MODELPOS"
        ElseIf cIdPonto == "FORMPOS"
        ElseIf cIdPonto == "FORMLINEPRE"
        ElseIf cIdPonto == "FORMLINEPOS"
        ElseIf cIdPonto == "MODELCOMMITTTS"
        ElseIf cIdPonto == "MODELCOMMITNTTS"
        ElseIf cIdPonto == "FORMCOMMITTTSPRE"
        ElseIf cIdPonto == "FORMCOMMITTTSPOS"
        	
        /*	If Inclui
        		U_GT12M003("SB1","INCLUI")
        	ElseIf Altera 
        		U_GT12M003("SB1","ALTERA")
        	Else
        		U_GT12M003("SB1","EXCLUI")
        	EndIf
        	
        ElseIf cIdPonto == "MODELCANCEL"
        ElseIf cIdPonto == "BUTTONBAR"
        EndIf
    EndIf
Return lRet  */





