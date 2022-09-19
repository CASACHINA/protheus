#Include "protheus.ch"
#include "rwmake.ch"
#include "topconn.ch"
//#include "Directry.ch"  

User function ImpFun() 
	Processa({||ImpFun1(),"Importação de Histórico Mensal" })
Return

Static Function ImpFun1()

Local aRegMes   := {}
Local nCount	:= 0
Local cNomeArq	:= ""
Local cNomeTXT	:= ""

Local cAuxFil	:= Space(6)
Local cMat		:= Space(6)
Local cNome		:= Space(40)         
Local cAdmissao	:= Space(10) 
Local nSalario	:= 0.00	   

cTipo := "Arquivos Texto  (*.TXT)  | *.TXT | "
cNomeTXT := cGetFile(cTipo,OemToAnsi("Selecionar Arquivo..."))

if Empty(cNomeTXT)
	Return
EndIF

	AADD(aRegMes,{"LINHA","C",128,0})

	cNomeArq:=CriaTrab(aRegMes, .t. )
	dbUseArea(.T.,__LocalDriver,cNomeArq,"IMP",.F.,.F.)  

	ProcRegua(Len(aRegMes))     

	Append from &cNomeTXT SDF

	DbSelectArea("IMP")
	DbGoTop()

	While !Eof() 

 		IncProc("Processando arquivo... ")

		If SubStr(IMP->LINHA,1,8)=="Filial: "   
			cAuxFil		:= "01010"+SubStr(IMP->LINHA,9,1)  
		Else
			cMat   		:= StrZero(Val(SubStr(IMP->LINHA,1,15)),6,0)	  
			cNome		:= SubStr(IMP->LINHA,17,40)		
			cAdmissao	:= SubStr(IMP->LINHA,58,10)  
			nSalario	:= Val(SubStr(IMP->LINHA,117,10))
			RecLock("SRA",.t.)
			SRA->RA_FILIAL	:= cAuxFil
			SRA->RA_MAT		:= cMat
			SRA->RA_NOME	:= cNome
			SRA->RA_ADMISSA	:= Ctod(cAdmissao) 
			SRA->RA_SALARIO	:= nSalario
			MsUnLock()
		EndIf
		DbSelectArea("IMP")
		DbSkip()
	End 
			
DbSelectArea("IMP")
DbCloseArea()

MsgAlert("Concluído. Gravados: "+Str(nCount))

Return       
