#INCLUDE 'PROTHEUS.CH'


// Exporta dados de Clientes e Fornecedores para a tabela CTH (CLASSE DE VALOR)
User Function ExportCTH()
Private oProcess

If MsgYesNo("Deseja realmente exportar os dados de clientes/fornecedores para a tabela CTH?","Alerta")
	oProcess := MsNewProcess():New({|lEnd| fExportCTH()})
	oProcess:Activate()
EndIf

Return()


Static Function fExportCTH()
ExportSA1()
ExportSA2()
Return(.T.)


// Exporta Clientes
Static Function ExportSA1()
Local aAreaSA1 := SA1->(GetArea())
Local aAreaCTH := CTH->(GetArea())

DbSelectArea("SA1")
DbSetOrder(1)
DbGoTop()

oProcess:SetRegua1(SA1->(RecCount()))
oProcess:SetRegua2(SA1->(RecCount()))

oProcess:IncRegua1("Exportando dados de clientes...")

While !SA1->(EOF())
	
	oProcess:IncRegua1("Exportando dados de clientes...")
	
	DbSelectArea("CTH")
	CTH->(DbSetOrder(1))
	
	If !(CTH->(DbSeek(xfilial("CTH")+"C"+ALLTRIM(SA1->A1_COD)+ALLTRIM(SA1->A1_LOJA))))
		
		oProcess:IncRegua2("Cliente: " + ALLTRIM(SA1->A1_COD)+ALLTRIM(SA1->A1_LOJA)+ " - " + AllTrim(SA1->A1_NOME))
		
		RecLock("CTH",.T.)
		CTH->CTH_FILIAL	:= xfilial("CTH")
		CTH->CTH_CLVL	:= "C"+ALLTRIM(SA1->A1_COD)+ALLTRIM(SA1->A1_LOJA)
		CTH->CTH_CLASSE	:= "2"
		CTH->CTH_NORMAL	:= "2"
		CTH->CTH_DESC01	:= SA1->A1_NOME
		CTH->CTH_BLOQ	:= "2"
		CTH->CTH_CLVLLP := "C"+ALLTRIM(SA1->A1_COD)+ALLTRIM(SA1->A1_LOJA)
		CTH->CTH_DTEXIS := CTOD("01/01/18") 
		CTH->CTH_CLSUP  := 'C'
		
		CTH->(MsUnLock())
		
	EndIf
	

	
	SA1->(DbSkip())
	
EndDo

oProcess:IncRegua2("")
oProcess:IncRegua1("Exportação de clientes concluida...")

RestArea(aAreaSA1)
RestArea(aAreaCTH)

Return()


// Exporta Fornecedores
Static Function ExportSA2()
Local aAreaSA2 := SA2->(GetArea())
Local aAreaCTH := CTH->(GetArea())

DbSelectArea("SA2")
DbSetOrder(1)
DbGoTop()

oProcess:SetRegua1(SA2->(RecCount()))
oProcess:SetRegua2(SA2->(RecCount()))

oProcess:IncRegua1("Exportando dados de fornecedores...")

While !SA2->(EOF())
	
	oProcess:IncRegua1("Exportando dados de fornecedores...")
	
	DbSelectArea("CTH")
	CTH->(DbSetOrder(1))
	
	If !(CTH->(DbSeek(xFilial("CTH")+"F"+ALLTRIM(SA2->A2_COD)+ALLTRIM(SA2->A2_LOJA))))
		
		oProcess:IncRegua2("Fornecedor: " + ALLTRIM(SA2->A2_COD)+ALLTRIM(SA2->A2_LOJA)+ " - " + AllTrim(SA2->A2_NOME))
		
		RecLock("CTH",.T.)
		CTH->CTH_FILIAL	:= xFilial("CTH")
		CTH->CTH_CLVL	:= "F"+ALLTRIM(SA2->A2_COD)+ALLTRIM(SA2->A2_LOJA)
		CTH->CTH_CLASSE	:= "2"
		CTH->CTH_NORMAL	:= "1"
		CTH->CTH_DESC01	:= SA2->A2_NOME
		CTH->CTH_BLOQ	:= "2"
		CTH->CTH_CLVLLP := "F"+ALLTRIM(SA2->A2_COD)+ALLTRIM(SA2->A2_LOJA)
		CTH->CTH_DTEXIS := CTOD("01/01/18")
		CTH->CTH_CLSUP  := 'F'
		CTH->(MsUnLock())
		
	EndIf
	

	SA2->(DbSkip())
EndDo


oProcess:IncRegua2("")
oProcess:IncRegua1("Exportação de fornecedores concluida...")

RestArea(aAreaSA2)
RestArea(aAreaCTH)

Return()
