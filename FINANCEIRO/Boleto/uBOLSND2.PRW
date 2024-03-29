

// ####################################################################################################################################################################################################
//
// Projeto   :   
// Modulo    : Financeiro
// Fonte     : uBOLSND2
// Data      : 01/06/2020
// Autor     : Valberg Moura 
// Descricao : Emissao de Boleto Santander
//
// ####################################################################################################################################################################################################

#Include "rwmake.ch"
#Include "protheus.ch"
#Include "topconn.ch"
#Include "colors.ch"
#INCLUDE "Tbiconn.ch"
#INCLUDE "rptDef.ch"
#INCLUDE "FWPrintSetup.ch"

User Function uBOLSND2() 		// oBoleto
	Local aArea := GetArea()		//Grava a area
	Local cNomeRel  := ""		  	//Nome do relat�rio
	Local lAtoL		:= .F.		  	//Ajusta o relat�rio nas propor��es
	Local lDs		:= .F.		  	//Disable setup
	Local cLocal    := "\spool"   	//Local de impressao
	Local lRodou 	:= .F.

	Private nI		:= 0			//Contador
	Private oBoleto := Nil		  	//Objeto de impress�o
	Private aDados 	:= {}			//Dados dos t�tulos

	//Define o nome do relat�rio
	cNomeRel := "Boleto-" + Dtos(Date()) + StrTran(Time(), ":", "")

	//Relat�rio
	oBoleto := FWMSPrinter():New(cNomeRel, IMP_PDF, lAtoL, cLocal, lDS, , , , , , .F., )

	//Acessa o inicio da query
	TRBOL01->(dbselectArea("TRBOL01"))
	TRBOL01->(DbGoTop())
	If TRBOL01->(Eof())
		MsgAlert("N�o existe informa��es para gera��o de boleto!")
		Return Nil //Sai da rotina
	Endif

	//Loop na query
	While (!TRBOL01->(Eof()))
		IF !Empty(TRBOL01->OK)

			// Posiciona par�metro dos Bancos
			SEE->( dbSetOrder(1) )
			//SEE->( dbSeek( xFilial("SEE") + TRBOL01->E1_PORTADO + TRBOL01->E1_AGEDEP + TRBOL01->E1_CONTA) )
			_cAuxBCO := PADR("33",3)
			_cAuxAGE := PADR("3415",5)
			_cAuxCTO := PADR("130027105",10)
			SEE->( dbSeek( xFilial("SEE") + _cAuxBCO + _cAuxAGE + _cAuxCTO) )
			// Posiciona t�tulos
			SE1->( dbSetOrder(1) )
			SE1->( dbSeek( xFilial("SE1") + TRBOL01->(E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO) ) )
			// Posiciona Cliente
			SA1->( dbSetOrder(1) )
			SA1->( dbSeek( xFilial("SA1") + TRBOL01->(E1_CLIENTE+E1_LOJA) ) )

			If  BolNossoNumero()
				Do Case //Verifica qual tipo de boleto imprimir
			/*	Case (TRBOL01->E1_PORTADO == "001") //Banco do Brasil				
					U_RBol001(oBoleto) //Chama a rotina de impress�o do boleto 
					lRodou := .T.
			*/	Case (SEE->EE_CODIGO == _cAuxBCO) //Banco Santander				
					U_RBol033(oBoleto) //Chama a rotina de impress�o do boleto
					lRodou := .T.
			/*	Case (TRBOL01->E1_PORTADO == "237") //Banco Santander				
					U_RBol237(oBoleto) //Chama a rotina de impress�o do boleto 
					lRodou := .T.
				Case (TRBOL01->E1_PORTADO == "341") //Banco Itau
					U_RBol341(oBoleto) //Chama a rotina de impress�o do boleto 
					lRodou := .T.								
			*/	Otherwise
					Msginfo("Banco " + _cAuxBCO + " n�o configurado para impress�o dos boletos! T�tulo " + Alltrim(TRBOL01->E1_NUM) + " n�o ser� impresso!","Aten��o")
				EndCase
			Endif
		Endif
		//Pr�ximo registro
		TRBOL01->(DBSKIP())

	Enddo

	//Fecha a query
	TRBOL01->(DbCloseArea())


	If !lRodou // Se n�o gerou nenhum boleto sai da rotina
		Return nil
	Endif

	//Verifica se houve impressao
	If (oBoleto:nModalResult == PD_OK)
		//Verifica se foi cancelado
		If !(oBoleto:Canceled())
			//Visualiza
			oBoleto:Preview()
		EndIf
	EndIf

	//Descarrega spool
	Ms_Flush()

	//Restaura a �rea
	RestArea(aArea)

Return

Static Function BolNossoNumero()


	Local cNossoNum := ""
	Local lContinua := .T.

	If Empty(SE1->E1_NUMBCO)
		IF !Empty(SEE->EE_FAXATU)
			cNossoNum := strzero(val(SEE->EE_FAXATU)+1,10)
		else
			Aviso("Aten��o","Tabela Par�metros n�o configurada!",{"Sair"}, 2)
			lContinua := .F.
		EndIF
		IF !Empty(cNossoNum)
			IF RecLock("SEE",.F.)
				SEE->EE_FAXATU := cNossoNum
				SEE->(MsUnlock())
			EndIF
			IF RecLock("SE1",.F.)
				SE1->E1_NUMBCO := b033NossoNum(cNossoNum)
				SE1->(MsUnlock())
			EndIF
		EndIF
	Endif
Return lContinua



Static Function b033NossoNum(cNossoNum)
	Local cDig      := ""
	Local cRetorno  := ""
	Local nPeso     := 2
	Local nSoma     := 0
	Local nResto    := 0

	cNossoNum := StrZero(val(cNossoNum),7)

	IF !Empty(cNossoNum)
		For nX := len(cNossoNum) to 1 step -1
			nSoma += val(substr(cNossoNum, nX, 1)) * nPeso
			nPeso++
			If nPeso > 7
				nPeso := 2
			EndIf
		Next nX
		nResto := Mod(nSoma, 11)

		IF nResto == 0 .Or. nResto == 1
			nDig := 0
		Else
			nDig := 11 - nResto
		EndIF
		cDig := cValToChar(nDig)
	EndIF

Return(cNossoNum + cDig)


