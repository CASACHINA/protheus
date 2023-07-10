#Include 'Protheus.ch'
#include "Tbiconn.ch"
#Include "TOPCONN.CH"
#Include "REPORT.ch"
#include "rptdef.ch"

/*/{Protheus.doc} VMIX014
Rotina para gerar o documento de entrada de devolucao.
/*/ 
/*
USER FUNCTION WSC()

	RPCSetType(3)

	RPCSetEnv("01","010108",,,"COM")
		U_VMIX014()
	RpcClearEnv()

RETURN()

user Function wsc1()

	StartJob( "U_WSC", GetEnvServer(),.F.)

return()
*/

User Function VMIX014()

	Local cSql          := ""
	Local cQryCabec		:= GetNextAlias()
	Local cQryItem		:= ""
	Local aCabec		:= {}
	Local aItem			:= {}
	Local lRet			:= .T.
	Local cMsg			:= ""
	Local cErro			:= ""
	Local bErro 		:= ErrorBlock( { |oErr| cErro := oErr:Description })

	//conout("[" + cEmpAnt + cFilAnt + "] " + "INTEGRACAO VMIX014 VERSAO INICIADA...")

	cSql := " SELECT * "
	cSql += " FROM " + RetSqlName("ZA0")
	cSql += " WHERE ZA0_FILIAL = " + ValToSql(xFilial("ZA0"))
	cSql += " AND ZA0_STATUS  = '0' " // 0=Aguard. Integração;1=Integrado;2=Erro
	cSql += " AND ZA0_MSBLQL <> '1' " // 1=Sim;2=Não
	cSql += " AND D_E_L_E_T_  = '' "

	TCQUERY cSql NEW ALIAS (cQryCabec)

	(cQryCabec)->(DbGoTop())

	DbSelectArea("ZA0")
	ZA0->(DBSetOrder(1)) // ZA0_FILIAL, ZA0_PROCES, R_E_C_N_O_, D_E_L_E_T_

	DbSelectArea("ZA1")
	ZA1->(DBSetOrder(1)) // ZA1_FILIAL, ZA1_PROCES, ZA1_ITEM, R_E_C_N_O_, D_E_L_E_T_
	
	DbSelectArea("SD2")
	// SD2->(DBSetOrder(3)) // D2_FILIAL, D2_DOC, D2_SERIE, D2_CLIENTE, D2_LOJA, D2_COD, D2_ITEM, R_E_C_N_O_, D_E_L_E_T_
	
	While (cQryCabec)->(!EOF())

		ZA0->(DbGoTop())

		ZA1->(DbGoTop())

		If ZA0->(DBSeek(xFilial("ZA0") + (cQryCabec)->ZA0_PROCES))

			If ZA0->(DbRLock(ZA0->(Recno())))

				Begin Sequence

					If ZA1->(DBSeek(xFilial("ZA1") + (cQryCabec)->ZA0_PROCES))

						lRet 		:= .T.
						cMsg 		:= ""
						cErro		:= ""
						aRecSD2 	:= {}
						aCabec 		:= {}
						aItens 		:= {}
						aItem 		:= {}
						
						While ZA1->(!EOF()) .And. ZA1->(ZA1_FILIAL + ZA1_PROCES) == xFilial("ZA1") + (cQryCabec)->ZA0_PROCES
							
							// SD2->(DBSetOrder(3)) // D2_FILIAL, D2_DOC, D2_SERIE, D2_CLIENTE, D2_LOJA, D2_COD, D2_ITEM, R_E_C_N_O_, D_E_L_E_T_
							// SD2->(DbGoTop())

							cQryItem := GetNextAlias()

							cSql := " SELECT R_E_C_N_O_ RECNO "
							cSql += " FROM " + RetSqlName("SD2")
							cSql += " WHERE D2_FILIAL	= " + ValToSql(xFilial("SD2"))
							cSql += " AND D2_DOC  		= " + ValToSql(ZA1->ZA1_DOC)
							cSql += " AND D2_SERIE 		= " + ValToSql(ZA1->ZA1_SERIE)
							cSql += " AND D2_CLIENTE	= " + ValToSql(ZA0->ZA0_CLICUP)
							cSql += " AND D2_LOJA  		= " + ValToSql(ZA0->ZA0_LOJCUP)
							cSql += " AND D2_COD 		= " + ValToSql(ZA1->ZA1_PRODUT)
							cSql += " AND D2_ITEMPV		= " + ValToSql(ZA1->ZA1_ITEM)
							cSql += " AND D2_PDV		= " + ValToSql(ZA1->ZA1_PDV)
							cSql += " AND D_E_L_E_T_ 	= '' "

							TCQUERY cSql NEW ALIAS (cQryItem)

							If (cQryItem)->(!EOF())

								SD2->(DBGoto((cQryItem)->RECNO))

								//If SD2->(DBSeek(ZA0->ZA0_FILIAL + ZA1->(ZA1_DOC + ZA1_SERIE) + ZA0->(ZA0_CLICUP + ZA0_LOJCUP) + ZA1->(ZA1_PRODUT + ZA1_ITEM)))

								aItem := {}
							
								aAdd(aRecSD2, { ZA1->ZA1_QUANT, SD2->(Recno())	, NIL, 0, 0})

								aAdd(aItem, { "TRB_ITEM"	, ZA1->ZA1_ITEM		, Nil }) 
								aAdd(aItem, { "TRB_CODPRO"	, ZA1->ZA1_PRODUT	, Nil }) 
								aAdd(aItem, { "TRB_QUANT"	, ZA1->ZA1_QUANT 	, Nil }) 
								aAdd(aItem, { "TRB_PRCVEN"	, ZA1->ZA1_PRCVEN 	, Nil }) 
								aAdd(aItem, { "TRB_VLRTOT"	, ZA1->ZA1_TOTAL 	, Nil }) 
								aAdd(aItem, { "TRB_UM"		, SD2->D2_UM	 	, Nil }) 
								aAdd(aItem, { "TRB_TES"		, SD2->D2_TES	 	, Nil }) 

								aAdd(aItem, { "TRB_NFORI"	, SD2->D2_DOC	 	, Nil })
								aAdd(aItem, { "TRB_SERORI"	, SD2->D2_SERIE	 	, Nil })

								aAdd(aItens, aItem)

								If ( SD2->D2_QUANT - SD2->D2_QTDEDEV == 0 )

									cMsg += "Sem saldo item " + ZA1->ZA1_ITEM + CRLF

									lRet := .F.

								EndIf

							Else

								cMsg += "Não encontrado item " + ZA1->ZA1_ITEM + CRLF

								lRet := .F.

							EndIf

							(cQryItem)->(DbCloseArea())

							ZA1->(DBSkip())

						EndDo

						If lRet

							//conout("[" + cEmpAnt + cFilAnt + "] " + "INTEGRACAO VMIX014 VOU EXECUTAR O PROCESSO: " + ZA0->ZA0_PROCES)
							ProcessaX(ZA0->ZA0_CLIENT, ZA0->ZA0_LOJA, aRecSD2, aItens)
							//conout("[" + cEmpAnt + cFilAnt + "] " + "INTEGRACAO VMIX014 FINALIZEI PROCESSO: " + ZA0->ZA0_PROCES)

						Else

							RecLock("ZA0", .F.)
							ZA0->ZA0_STATUS := "2" // 0=Aguard. Integração;1=Integrado;2=Erro
							ZA0->ZA0_OBS 	:= ZA0->ZA0_OBS + cMsg + CRLF
							ZA0->(MsUnlock())
						
						EndIf

					EndIf

				End Sequence

				ErrorBlock( bErro )

				If Empty(ZA0->ZA0_DOCDEV) .And. ( ValType(cErro) <> "U" .And. !Empty(cErro) )

					//conout("[" + cEmpAnt + cFilAnt + "] " + "INTEGRACAO VMIX014 COM ERRO: " + cErro)

					RecLock("ZA0", .F.)
					ZA0->ZA0_STATUS := "2" // 0=Aguard. Integração;1=Integrado;2=Erro
					ZA0->ZA0_OBS 	:= ZA0->ZA0_OBS + AllTrim(cErro) + CRLF
					ZA0->(MsUnlock())

				EndIf

			Else

				//conout( "[" + cEmpAnt + cFilAnt + "] " + "Nao consegui lockar ZA0_PROCES: " + ZA0->ZA0_PROCES + " Record locked by another user. " + TcInternal(53) )

			EndIf

		EndIf

		(cQryCabec)->(DbSkip())

	EndDo

	(cQryCabec)->(DbCloseArea())

	//conout("[" + cEmpAnt + cFilAnt + "] " + "INTEGRACAO VMIX014 CONCLUIDA.")

Return()

Static Function ProcessaX(cCodCli, cLojaCli, aRecSD2, aItem)

	Local cLogTxt          	:= ""
	Local aAutoErro			:= {}
	Local aCabec			:= {}

	Private lMsErroAuto     := .F.
	Private lMsHelpAuto     := .T.
	Private lAutoErrNoFile  := .T.

	aAdd(aCabec, {"nTpProc"		, 2 										, Nil })		//Tipo do processo de troca.                          
	aAdd(aCabec, {"nNfOrig"		, 1 										, Nil })		//Origem do documento de entrada                     
	aAdd(aCabec, {"cCodCli"		, cCodCli 									, Nil })		//Codigo do cliente                                   
	aAdd(aCabec, {"cLojaCli"	, cLojaCli 									, Nil })		//Codigo da loja                                      
	aAdd(aCabec, {"aRecSD2"		, aRecSD2									, Nil })		//Array com os Recnos da tabela SD2                   
	aAdd(aCabec, {"lFormul"		, .T.										, Nil })		//Indica se eh formulario proprio ou nao              
	aAdd(aCabec, {"cNumDoc"		, ""										, Nil })		//Numero do documento de entrada                      
	aAdd(aCabec, {"cSerieDoc"	, "" 										, Nil })		//Serie do documento de entrada                       
	aAdd(aCabec, {"lCompCR"		, .F.								 		, Nil })		//Indica se ira compensar a NCC com o titulo da NF.   
	aAdd(aCabec, {"lVdAssist"	, .F.		 								, Nil })		//Se a rotina foi executada pela venda assistida.     
	aAdd(aCabec, {"aDocDev"		, {}	 									, Nil })		//Armazena a serie, numero e cliente+loja da NF de devolucao e o tipo de operacao(1=troca;2=devolucao)  
	aAdd(aCabec, {"nFormaDev"	, 2											, Nil })		//Forma de devolucao ao cliente: 1-Dinheiro;2-NCC     
	// aAdd(aCabec, {"nVlrTotal", 		 									, Nil })		//Valor total de produtos a serem trocados ou devolvidos    								      
	aAdd(aCabec, {"lDevMoeda"	, .F.		 								, Nil })		//Devolve em varias moedas.                           
	aAdd(aCabec, {"nImpostos"	, 0			 								, Nil })		//Moeda corrente                                      
	aAdd(aCabec, {"cChvNFE"		, ""	 									, Nil })		//Taxa da moeda corrente                              
	aAdd(aCabec, {"cTpEspecie"	, ""	 									, Nil })		
	aAdd(aCabec, {"cCodFil"		, cFilAnt									, Nil })		 
	aAdd(aCabec, {"lDevFrete"	, .F.		 								, Nil })		
	aAdd(aCabec, {"cMensagem"	, ""										, Nil })

	MSExecAuto({|a,b,c,d,e,f,g,h,i,j| LOJA720(a,b,c,d,e,f,g,h,i,j)}, cCodCli, cLojaCli, , , 3, , cFilAnt, .T., aCabec, aItem)

	If lMsErroAuto

		aAutoErro := GetAutoGrLog()

		cLogTxt += GetErrorLog(aAutoErro)

		//conout("[" + cEmpAnt + cFilAnt + "] PROCESSO: " + ZA0->ZA0_PROCES + " VMIX014 >>> ERRO: " + cLogTxt)

		RecLock("ZA0", .F.)
		ZA0->ZA0_STATUS := "2" // 0=Aguard. Integração;1=Integrado;2=Erro
		ZA0->ZA0_OBS 	:= ZA0->ZA0_OBS + cLogTxt + CRLF
		ZA0->(MsUnlock())

	Else

		//conout("[" + cEmpAnt + cFilAnt + "] PROCESSO: " + ZA0->ZA0_PROCES + " VMIX014 >>> SUCESSO!")

		RecLock("ZA0", .F.)
		ZA0->ZA0_STATUS := "1" // 0=Aguard. Integração;1=Integrado;2=Erro
		ZA0->ZA0_DOCDEV := U_X720DOC()
		ZA0->ZA0_SERDEV := U_X720SER()
		ZA0->ZA0_OBS 	:= "Nota de devolução gerada com sucesso!"
		ZA0->(MsUnlock())

		U_X720DOCL()
		U_X720SERL()

		DBSelectArea("SF1")
		SF1->(DbSetOrder(1))  //F1_FILIAL, F1_DOC, F1_SERIE, F1_FORNECE, F1_LOJA, F1_TIPO, R_E_C_N_O_, D_E_L_E_T_

		If SF1->(DbSeek(xFilial("SF1") + ZA0->(ZA0_DOCDEV + ZA0_SERDEV + ZA0_CLIENT + ZA0_LOJA)))

			RecLock("SF1", .F.)
			SF1->F1_XPRODEV := ZA0->ZA0_PROCES
			SF1->F1_XCDVMIX := ZA0->ZA0_CDVMIX
			SF1->(MsUnlock())

		EndIf

	EndIf

Return(!lMsErroAuto)

Static Function GetErrorLog(aError)

	Local cRet := ""
	Local nX := 1

	Default aError := {}

	For nX := 1 To Len(aError)

		cRet += aError[nX] + CRLF

	Next nX

Return(cRet)

Static Function VaildLancManual()

	Local lRet := .T.

Return(lRet)
