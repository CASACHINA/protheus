#Include "protheus.ch"
#include "rwmake.ch"
#include "topconn.ch"
//#include "Directry.ch"  

User function ImpCad() 
	Processa({||ImpCadF(),"Importa��o da Ficha de Registro" })
Return

Static Function ImpCadF()

Local aRegMes   := {}
Local nCount	:= 0
Local cMat		:= Space(6)

Local cNomeArq	:= ""
Local cNomeTXT	:= ""

Local nPos		:= 0  

Local cNomePai	:= ""
Local cNomeMae	:= ""
Local cNascim	:= ""
Local cSexo		:= ""
Local cEstCiv	:= ""
Local cRaca		:= ""  
Local cCPF		:= ""

cTipo := "Arquivos Texto  (*.TXT)  | *.TXT | "
cNomeTXT := cGetFile(cTipo,OemToAnsi("Selecionar Arquivo..."))

if Empty(cNomeTXT)
	Return
EndIF

	AADD(aRegMes,{"LINHA","C",132,0})

	//cNomeArq:=CriaTrab(aRegMes, .t. )
	//dbUseArea(.T.,__LocalDriver,cNomeArq,"CAD",.F.,.F.)  
	oTempTable := FWTemporaryTable():New( "CAD" )
	oTemptable:SetFields( aRegMes )
	// oTemptable:AddIndex("1", {"ZLG_FILIAL","ZLG_PEDIDO" })
	oTempTable:Create()

	ProcRegua(Len(aRegMes))     

	Append from &cNomeTXT SDF

	DbSelectArea("CAD")
	DbGoTop()

	While !Eof() 

		IncProc("Processando arquivo... ")
	  
		If SubStr(AllTrim(CAD->LINHA),1,5)="Nome:"   
			nPos	:= AT("C�digo: ",AllTrim(CAD->LINHA))  
			cMat	:= StrZero(Val(SubStr(AllTrim(CAD->LINHA),nPos+8,6)),6,0)
			While !Eof()   
				DbSkip()
				If "Ficha de Registro de Empregado" $ CAD->LINHA 
					DbSelectArea("SRA")
					DbSetOrder(13)
					DbGoTop()
					DbSeek(cMat,.f.)
					If SRA->RA_MAT==cMat  
						RecLock("SRA",.f.)
						SRA->RA_PAI		:= cNomePai
						SRA->RA_MAE		:= cNomeMae    
						SRA->RA_NASC	:= Ctod(cNascim)
						SRA->RA_SEXO	:= Upper(SubStr(cSexo,1,1))
						MsUnLock()    
						nCount++
					EndIf
					cNomePai   		:= ""
					cNomeMae		:= ""
					cNascim			:= ""
					cSexo			:= ""
					cEstCiv			:= ""
					cRaca			:= ""
					Exit  
				EndIf
				If "Pai:" $ CAD->LINHA 
					cNomePai	:= SubStr(CAD->LINHA,22,40)
				EndIf  
				If "M�e:" $ CAD->LINHA 
					cNomeMae	:= SubStr(CAD->LINHA,22,40)
				EndIf  
				If "Nascimento:" $ CAD->LINHA 
					cNascim		:= SubStr(CAD->LINHA,22,10)
					nPos   		:= AT("Sexo: ",AllTrim(CAD->LINHA))  
					cSexo		:= SubStr(AllTrim(CAD->LINHA),nPos+6,10)
				EndIf  
				If "CPF:" $ CAD->LINHA 
					cNascim		:= SubStr(CAD->LINHA,22,10)
					nPos   		:= AT("Sexo: ",AllTrim(CAD->LINHA))  
					cSexo		:= SubStr(AllTrim(CAD->LINHA),nPos+6,10)
				EndIf  
				DbSelectArea("CAD") 
				DbSkip()
			End 
		EndIf

		DbSelectArea("CAD")
		DbSkip()
	End 

	
DbSelectArea("CAD")
DbCloseArea()

MsgAlert("Conclu�do. Gravados: "+Str(nCount))

Return       

