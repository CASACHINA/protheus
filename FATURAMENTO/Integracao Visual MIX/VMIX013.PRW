#Include 'Protheus.ch'
#include "Tbiconn.ch"
#Include "TOPCONN.CH"
#Include "REPORT.ch"
#include "rptdef.ch"

/*/{Protheus.doc} VMIX013
Rotina para popular as tabelas de devolucao ZA0 e ZA1.
/*/ 
User Function VMIX013(aParam)

	Local cSql		:= ""
	Local cQryCabec	:= ""
	Local dDtCorte	:= ""
	Local nW		:= 0
	Local aFiliais	:= {}

	Default aParam	:= {"01", "010101"}

	RPCSetEnv(aParam[1],aParam[2],,,"COM")

	// aFiliais := GetNewPar("ZZ_VMIX13C", "{'010108'}") // retirar

	aFiliais := GetNewPar("ZZ_VMIX13C", "{'010101','010102','010105','010107','010108','010109'}")

	While !MayIUseCode( "VMIX013" )

		ConOut("A rotina VMIX013 está sendo executada por outro processo!")

	EndDo
	
	aFiliais := &(aFiliais)

	For nW := 1 To Len(aFiliais)

		RPCClearEnv()

		RPCSetEnv(SubStr(aFiliais[nW], 1, 2), aFiliais[nW],,,"COM")

		cQryCabec := GetNextAlias()

		ConOut("[" + cEmpAnt + cFilAnt + "] " + "INTEGRACAO VMIX013 VERSAO INICIADA...")

		cVMIXDB   := AllTrim(GetNewPar("ZZ_VMIXDB", ""))
		cVMIXFIL  := AllTrim(GetNewPar("ZZ_VMIXFIL", ""))

		cVMIXINS  := SubStr(cVMIXDB, At(".", cVMIXDB) + 1, Len(cVMIXDB))
		cVMIXDB   := SubStr(cVMIXDB, 1, At(".", cVMIXDB) - 1)

		dDtCorte  := GetNewPar("ZZ_VMIX13A", CTOD("24/02/2022"))

		cSql := " SELECT * "
		cSql += " FROM OPENQUERY "
		cSql += " (" + cVMIXDB + ", "
		cSql += " '"
		cSql += " 	SELECT * "
		cSql += " 	FROM " + cVMIXINS + "." + "vw_devol"
		cSql += " 	WHERE loja = " + cVMIXFIL

		//cSql += " 	AND codigo BETWEEN 48312 AND 48321 "
		cSql += " 	AND situacao_data >= ''" + cValToChar(Year(dDtCorte)) + "-" + StrZero(Month(dDtCorte), 2) + "-" + StrZero(Day(dDtCorte), 2) + "''"

		cSql += " 	ORDER BY codigo "
		cSql += " ')"
		cSql += " WHERE NOT EXISTS "
		cSql += " ( "
		cSql += " 	SELECT * "
		cSql += " 	FROM " + RetSqlName("ZA0") + " A (NOLOCK) "
		cSql += " 	WHERE ZA0_FILIAL 	= " + ValToSql(xFilial("ZA0"))
		cSql += " 	AND ZA0_CDVMIX  	= codigo "
		cSql += " 	AND ZA0_STATUS  	IN ( '0', '1' ) " // 0=Aguard. Integração;1=Integrado;2=Erro
		cSql += " 	AND A.D_E_L_E_T_  	= '' "	
		cSql += " )
		cSql += " AND NOT EXISTS "
		cSql += " ( "
		cSql += " 	SELECT NULL "
		cSql += " 	FROM " + RetSqlName("SF1") + " SF1 (NOLOCK) "
		cSql += " 	WHERE F1_FILIAL 	= " + ValToSql(xFilial("SF1"))
		cSql += " 	AND F1_XCDVMIX		= codigo "
		cSql += " 	AND SF1.D_E_L_E_T_	= '' "
		cSql += "  )

		TCQUERY cSql NEW ALIAS (cQryCabec)

		(cQryCabec)->(DbGoTop())

		DbSelectArea("ZA0")
		ZA0->(DbSetOrder(2)) // ZA0_FILIAL, ZA0_CDVMIX, ZA0_PROCES, R_E_C_N_O_, D_E_L_E_T_

		While (cQryCabec)->(!Eof())

			Begin Transaction

				If ZA0->(DBSeek(xFilial("ZA0") + cValToChar((cQryCabec)->codigo) ))

					If Empty(ZA0->ZA0_CLIENT) .And. Empty(ZA0->ZA0_LOJA)

						Cliente(cQryCabec)

					EndIf

				Else

					GravarCabec(cQryCabec)

					Cliente(cQryCabec)

					Itens(cQryCabec)

				EndIf

			End Transaction

			(cQryCabec)->(DbSkip())

		EndDo

		(cQryCabec)->(DbCloseArea())

		ConOut("[" + cEmpAnt + cFilAnt + "] " + "INTEGRACAO VMIX013 CONCLUIDA.")

		U_VMIX014() // Chama a rotina para geracao das notas de devolucao.

		// RPCClearEnv()

	Next nW

	FreeUsedCode()

Return()

Static Function GravarCabec(cQryCabec)

	RecLock("ZA0", .T.)

	ZA0->ZA0_FILIAL	:= xFilial("ZA0")
	ZA0->ZA0_PROCES	:= GetSXENum("ZA0", "ZA0_PROCES")
	ZA0->ZA0_CDVMIX	:= (cQryCabec)->codigo
	ZA0->ZA0_DTDEVO	:= (cQryCabec)->situacao_data
	ZA0->ZA0_DTINC	:= dDataBase
	ZA0->ZA0_MSBLQL	:= "2" // 1=Sim;2=Não
	ZA0->ZA0_STATUS	:= "0" //0=Aguard. Integração;1=Integrado;2=Erro

	ConfirmSx8()

	ZA0->(MsUnlock())

Return()

Static Function Itens(cQryCabec)

	Local cSql          := ""
	Local cQryItem		:= GetNextAlias()

	cVMIXDB   := AllTrim(GetNewPar("ZZ_VMIXDB", ""))
	cVMIXFIL  := AllTrim(GetNewPar("ZZ_VMIXFIL", ""))

	cVMIXINS  := SubStr(cVMIXDB, At(".", cVMIXDB) + 1, Len(cVMIXDB))
	cVMIXDB   := SubStr(cVMIXDB, 1, At(".", cVMIXDB) - 1)

	cSql := " SELECT * "
	cSql += " FROM OPENQUERY "
	cSql += " (" + cVMIXDB + ", "
	cSql += " '"
	cSql += " 	SELECT * "
	cSql += " 	FROM " + cVMIXINS + "." + "vw_devol_produto"
	cSql += " 	WHERE loja = " + cVMIXFIL
	cSql += " 	AND codigo = " + cValToChar((cQryCabec)->codigo)
	cSql += " 	ORDER BY sequencial "
	cSql += " ')"

	TCQUERY cSql NEW ALIAS (cQryItem)

	(cQryItem)->(DbGoTop())

	If (cQryItem)->(!Eof())

		While (cQryItem)->(!Eof())

			GravarItem(cQryItem)

			(cQryItem)->(DbSkip())

		EndDo

	Else

		RecLock("ZA0", .F.)
		ZA0->ZA0_STATUS	:= "2" // 0=Aguard. Integração;1=Integrado;2=Erro
		ZA0->ZA0_OBS	:= ZA0->ZA0_OBS + "Não encontrado itens em vw_devol_produto." + CRLF
		ZA0->(MsUnlock())

	EndIf

	(cQryItem)->(DbCloseArea())

Return()

Static Function GravarItem(cQryItem)

	Local cSql          := ""
	Local cCupom		:= ""
	Local cCliCup		:= ""
	Local cLojaCup		:= ""

	Private cQryCupom	:= GetNextAlias()
	Private cQryNFce	:= GetNextAlias()

	cSql := " SELECT * "
	cSql += " FROM OPENQUERY "
	cSql += " (" + cVMIXDB + ", "
	cSql += " '"
	cSql += " 	SELECT * "
	cSql += " 	FROM " + cVMIXINS + "." + "vw_nfce_capa"
	cSql += " 	WHERE loja 		 = " + cVMIXFIL
	cSql += " 	AND evento_cupom = " + cValToChar((cQryItem)->coo)
	cSql += " 	AND num_pdv		 = " + cValToChar((cQryItem)->pdv)
	cSql += " ')"

	TCQUERY cSql NEW ALIAS (cQryNFce)

	(cQryNFce)->(DbGoTop())

	If (cQryNFce)->(!Eof())

		cCupom := cValToChar((cQryNFce)->numeronota)

	EndIf

	(cQryNFce)->(DbCloseArea())

	RecLock("ZA1", .T.)

	ZA1->ZA1_FILIAL	:= xFilial("ZA1")
	ZA1->ZA1_PROCES	:= ZA0->ZA0_PROCES
	ZA1->ZA1_ITEM	:= U_NewSeq(cValToChar((cQryItem)->sequencial), 2)
	ZA1->ZA1_PRODUT	:= PADL((cQryItem)->codigoproduto, 6, "0")
	ZA1->ZA1_QUANT	:= (cQryItem)->quantidade
	ZA1->ZA1_PRCVEN	:= (cQryItem)->preco_unitario
	ZA1->ZA1_TOTAL	:= (cQryItem)->preco_total

	ZA1->ZA1_DOC	:= If(Empty(cCupom)			, "", PADL(cCupom, 9, "0"))
	ZA1->ZA1_SERIE	:= If(Empty((cQryItem)->pdv), "", PADL((cQryItem)->pdv, 3, "0"))
	ZA1->ZA1_PDV	:= If(Empty((cQryItem)->pdv), "", PADL((cQryItem)->pdv, 3, "0"))

	ZA1->(MsUnlock())

	DbSelectArea("SB1")
	SB1->(DbSetOrder(1)) // B1_FILIAL, B1_COD, R_E_C_N_O_, D_E_L_E_T_

	If SB1->(DBSeek(xFilial("SB1") + ZA1->ZA1_PRODUT))

		If SB1->B1_MSBLQL == "1"

			RecLock("ZA0", .F.)
			ZA0->ZA0_STATUS	:= "2" // 0=Aguard. Integração;1=Integrado;2=Erro
			ZA0->ZA0_OBS	:= ZA0->ZA0_OBS + "Produto [" + ZA1->ZA1_PRODUT + "] bloqueado." + CRLF
			ZA0->(MsUnlock())

		EndIf

	EndIf

	cVMIXDB   := AllTrim(GetNewPar("ZZ_VMIXDB", ""))
	cVMIXFIL  := AllTrim(GetNewPar("ZZ_VMIXFIL", ""))

	cVMIXINS  := SubStr(cVMIXDB, At(".", cVMIXDB) + 1, Len(cVMIXDB))
	cVMIXDB   := SubStr(cVMIXDB, 1, At(".", cVMIXDB) - 1)

	cSql := " SELECT * "
	cSql += " FROM OPENQUERY "
	cSql += " (" + cVMIXDB + ", "
	cSql += " '"
	cSql += " 	SELECT * "
	cSql += " 	FROM " + cVMIXINS + "." + "vw_total_cupom"
	cSql += " 	WHERE loja 		 = " + cVMIXFIL
	cSql += " 	AND evento_cupom = " + cValToChar((cQryItem)->coo)
	cSql += " 	AND num_pdv		 = " + cValToChar((cQryItem)->pdv)
	cSql += " ')"

	TCQUERY cSql NEW ALIAS (cQryCupom)

	(cQryCupom)->(DbGoTop())

	If (cQryCupom)->(!Eof())

		If Empty(cCupom)

			cCupom := (cQryCupom)->num_cupom

			RecLock("ZA1", .F.)

			ZA1->ZA1_DOC := If(Empty(cCupom) , "", PADL(cCupom, 9, "0"))

			ZA1->(MsUnlock())

		EndIf

		If Empty(ZA0->ZA0_CLICUP)

			// cCliCup := GetValue("(cQryCupom)", "SL1", "L1_CLIENT")

			// cLojaCup := GetValue("(cQryCupom)", "SL1", "L1_LOJA")

			GetValue2(@cCliCup, @cLojaCup)

			RecLock("ZA0", .F.)

			ZA0->ZA0_CLICUP	:= cCliCup
			ZA0->ZA0_LOJCUP	:= cLojaCup

			ZA0->(MsUnlock())

		EndIf

	EndIf

	(cQryCupom)->(DbCloseArea())

Return()

Static Function GetValue(cQuery, cTable, cField)

	Local xValue := ""

	DbSelectArea("ZV1")
	ZV1->(DbSetOrder(2)) // ZV1_FILIAL, ZV1_TABPRO, ZV1_CPOPRO, R_E_C_N_O_, D_E_L_E_T_

	If ZV1->(DBSeek(xFilial("ZV1") + cTable + cField))

		xValue := ""

		SX3->(DbSetOrder(2))

		If SX3->(!DbSeek(AllTrim(ZV1->ZV1_CPOPRO)))

			&(AllTrim(ZV1->ZV1_FORMUL))

		Else

			If Empty(ZV1->ZV1_CPOVIS) .And. !Empty(AllTrim(ZV1->(ZV1_FORMUL)))

				xValue := &(AllTrim(ZV1->ZV1_FORMUL))

			ElseIf !Empty(ZV1->ZV1_CPOVIS) .And. !Empty(AllTrim(ZV1->(ZV1_FORMUL)))

				If ValType(&(cQuery + "->(" + AllTrim(ZV1->ZV1_CPOVIS)+")")) == "N"

					aType := TamSX3(ZV1->ZV1_CPOPRO)

					If Len(aType) > 0

						If aType[3] == "C"

							xValue := &(StrTran(AllTrim(ZV1->ZV1_FORMUL), "%" + AllTrim(ZV1->ZV1_CPOVIS) + "%", '"' + cValToChar(&(cQuery + "->(" + AllTrim(ZV1->ZV1_CPOVIS) + ")")) + '"'))

						Else

							xValue := &(StrTran(AllTrim(ZV1->ZV1_FORMUL), "%" + AllTrim(ZV1->ZV1_CPOVIS) + "%", cValToChar(&(cQuery + "->(" + AllTrim(ZV1->ZV1_CPOVIS) + ")"))))

						EndIf

					Else

						__cMsgAdv += "Advertência: Campos " + AllTrim(ZV1->ZV1_CPOPRO) + " nao encontrado!" + Chr(10)

						// If __lJob
						conout(conout)
						// EndIf

					EndIf

				Else

					xValue := &(StrTran(AllTrim(ZV1->ZV1_FORMUL), "%" + AllTrim(ZV1->ZV1_CPOVIS) + "%", '"' + &(cQuery + "->(" + AllTrim(ZV1->ZV1_CPOVIS)+")") + '"'))

				EndIf

			ElseIf !Empty(ZV1->ZV1_CPOVIS)

				If ValType(&(cQuery + "->(" + AllTrim(ZV1->ZV1_CPOVIS)+")")) == "N"

					aType := TamSX3(ZV1->ZV1_CPOPRO)

					If Len(aType) > 0

						If aType[3] == "C"

							xValue := &('"' + cValToChar(&(cQuery + "->(" + AllTrim(ZV1->ZV1_CPOVIS) + ")")) + '"')

						Else

							xValue := &(cValToChar(&(cQuery + "->(" + AllTrim(ZV1->ZV1_CPOVIS) + ")")))

						EndIf

					Else

						__cMsgAdv += "Advertência: Campos " + AllTrim(ZV1->ZV1_CPOPRO) + " nao encontrado!" + Chr(10)

						// If __lJob
						conout(__cMsgAdv)
						// EndIf

					EndIf

				ElseIf ValType(&(cQuery + "->(" + AllTrim(ZV1->ZV1_CPOVIS)+")")) == "D"

					xValue := &(cQuery + "->(" + AllTrim(ZV1->ZV1_CPOVIS)+")")

				Else

					xValue := &(StrTran(AllTrim(ZV1->ZV1_FORMUL), "%" + AllTrim(ZV1->ZV1_CPOVIS) + "%", '"' + &(cQuery + "->(" + AllTrim(ZV1->ZV1_CPOVIS)+")") + '"'))

				EndIf

			EndIf

		EndIf

	EndIf

Return(xValue)

Static Function GetValue2(cCliCup, cLojaCup)

	Local cQryCliCup := GetNextAlias()

	cSql := " SELECT D2_CLIENTE, D2_LOJA "
	cSql += " FROM " + RetSqlName("SD2")
	cSql += " WHERE D2_FILIAL	= " + ValToSql(xFilial("SD2"))
	cSql += " AND D2_DOC  		= " + ValToSql(ZA1->ZA1_DOC)
	cSql += " AND D2_SERIE 		= " + ValToSql(ZA1->ZA1_SERIE)
	// cSql += " AND D2_CLIENTE	= " + ValToSql(ZA0->ZA0_CLICUP)
	// cSql += " AND D2_LOJA  		= " + ValToSql(ZA0->ZA0_LOJCUP)
	cSql += " AND D2_COD 		= " + ValToSql(ZA1->ZA1_PRODUT)
	cSql += " AND D2_ITEMPV		= " + ValToSql(ZA1->ZA1_ITEM)
	cSql += " AND D2_PDV		= " + ValToSql(ZA1->ZA1_PDV)
	cSql += " AND D_E_L_E_T_ 	= '' "

	TCQUERY cSql NEW ALIAS (cQryCliCup)

	If (cQryCliCup)->(!EOF())

		cCliCup := (cQryCliCup)->D2_CLIENTE

		cLojaCup := (cQryCliCup)->D2_LOJA

	EndIf

	(cQryCliCup)->(DbCloseArea())

Return()

Static Function Cliente(cQryCabec)

	Local cSql := ""
	Local cQryCliente := GetNextAlias()
	Local aCliente := {}
	Local aAutoErro	:= {}
	Local cTipPessoa := "F"
	Local cLogTxt := ""
	Local cCpfCnpj := AllTrim( cValToChar((cQryCabec)->cliente_cpf_cnpj) )

	Private lMsErroAuto     := .F.
	Private lMsHelpAuto     := .T.
	Private lAutoErrNoFile  := .T.

	If Len(cCpfCnpj) == 8

		cCpfCnpj := "000" + cCpfCnpj

	ElseIf Len(cCpfCnpj) == 9

		cCpfCnpj := "00" + cCpfCnpj

	ElseIf Len(cCpfCnpj) == 10

		cCpfCnpj := "0" + cCpfCnpj

	ElseIf Len(cCpfCnpj) == 13

		cCpfCnpj := "0" + cCpfCnpj

	EndIf

	If Len(cCpfCnpj) == 11

		cTipPessoa := "F"

	ElseIf Len(cCpfCnpj) == 14

		cTipPessoa := "J"

	EndIf

	DbSelectArea("SA1")
	SA1->(DbSetOrder(3)) // A1_FILIAL, A1_CGC, R_E_C_N_O_, D_E_L_E_T_

	cCpfCnpj := PADR( cCpfCnpj, TAMSX3("A1_CGC")[1] )

	If SA1->( DBSeek(xFilial("SA1") + cCpfCnpj) )

		If Empty(ZA0->ZA0_CLIENT)

			RecLock("ZA0", .F.)
			ZA0->ZA0_CLIENT	:= SA1->A1_COD
			ZA0->ZA0_LOJA	:= SA1->A1_LOJA
			ZA0->(MsUnlock())

		EndIf

	Else

		cVMIXDB   := AllTrim(GetNewPar("ZZ_VMIXDB", ""))
		cVMIXDB   := SubStr(cVMIXDB, 1, At(".", cVMIXDB) - 1)

		cSql := " SELECT * "
		cSql += " FROM OPENQUERY "
		cSql += " (" + cVMIXDB + ", "
		cSql += " '"
		cSql += " 	SELECT * "
		cSql += " 	FROM vm_log.nfce_clientes "
		cSql += " 	WHERE cpf = " + cCpfCnpj
		cSql += " ')"

		TCQUERY cSql NEW ALIAS (cQryCliente)

		(cQryCliente)->(DbGoTop())

		If (cQryCliente)->(!Eof())

			aAdd( aCliente, { "A1_LOJA"    		, "01"               										, Nil } )
			aAdd( aCliente, { "A1_CGC"     		, cCpfCnpj													, Nil } )
			aAdd( aCliente, { "A1_NOME"    		, (cQryCabec)->cliente_nome									, Nil } )
			aAdd( aCliente, { "A1_NREDUZ"  		, Left((cQryCabec)->cliente_nome, 20) 						, Nil } )
			aAdd( aCliente, { "A1_PAIS"    		, "105"              										, Nil } )
			aAdd( aCliente, { "A1_END"     		, (cQryCabec)->cliente_endereco								, Nil } )
			aAdd( aCliente, { "A1_NATUREZA"		, "1010101"         										, Nil } )
			// aAdd( aCliente, { "A1_COMPLEM" 	, ""			      										, Nil } )
			aAdd( aCliente, { "A1_BAIRRO"  		, (cQryCabec)->cliente_bairro								, Nil } )
			aAdd( aCliente, { "A1_CEP"   	  	, (cQryCliente)->cep       									, Nil } )
			aAdd( aCliente, { "A1_EST"     		, (cQryCabec)->cliente_uf									, Nil } )
			aAdd( aCliente, { "A1_MUN"     		, (cQryCabec)->cliente_cidade								, Nil } )
			aAdd( aCliente, { "A1_CODPAIS" 		, "01058"            										, Nil } )
			aAdd( aCliente, { "A1_CONTA"		, "110200100001"       										, Nil } )
			// aAdd( aCliente, { "A1_EMAIL"   	, ""	            										, Nil } )
			// aAdd( aCliente, { "A1_DDD"     	, ""														, Nil } )
			// aAdd( aCliente, { "A1_TEL"     	, ""														, Nil })
			aAdd( aCliente, { "A1_PESSOA"  		, cTipPessoa           										, Nil } )
			aAdd( aCliente, { "A1_TIPO"    		, "F"                										, Nil } )
			aAdd( aCliente, { "A1_COD_MUN" 		, SubStr(CValToChar((cQryCliente)->codigoibge), 3, 5)		, Nil } )
			aAdd( aCliente, { "A1_DDD" 			, CValToChar((cQryCliente)->dddtelefone)					, Nil } )
			aAdd( aCliente, { "A1_TEL" 			, CValToChar((cQryCliente)->telefone)						, Nil } )
			aAdd( aCliente, { "A1_EMAIL"		, (cQryCliente)->email										, Nil } )
			// aAdd( aCliente, { "A1_DTNASC"  	, STOD(_cDatNas)     										, Nil } )
			// aAdd( aCliente, { "A1_YCLUBE"  	, "S"                										, Nil } )
			// aAdd( aCliente, { "A1_YSEXO"   	, _cSexo             										, Nil } )
			// aAdd( aCliente, { "A1_YNUMERO" 	, allTrim(_cNumero)  										, Nil } )

			MsExecAuto({|x, y| Mata030(x, y)}, aCliente, 3)

			If lMsErroAuto

				aAutoErro := GetAutoGrLog()

				cLogTxt += GetErrorLog(aAutoErro)

				ConOut("[" + cEmpAnt + cFilAnt + "] PROCESSO: " + ZA0->ZA0_PROCES + " VMIX014 >>> ERRO: " + cLogTxt)

				RecLock("ZA0", .F.)
				ZA0->ZA0_STATUS := "2" // 0=Aguard. Integração;1=Integrado;2=Erro
				ZA0->ZA0_OBS 	:= ZA0->ZA0_OBS + cLogTxt + CRLF
				ZA0->(MsUnlock())

			Else

				ConOut("[" + cEmpAnt + cFilAnt + "] PROCESSO: " + ZA0->ZA0_PROCES + " VMIX014 >>> SUCESSO!")

				RecLock("ZA0", .F.)
				ZA0->ZA0_STATUS := "0" // 0=Aguard. Integração;1=Integrado;2=Erro
				ZA0->ZA0_CLIENT	:= SA1->A1_COD
				ZA0->ZA0_LOJA	:= SA1->A1_LOJA
				ZA0->(MsUnlock())

			EndIf

		Else

			RecLock("ZA0", .F.)
			ZA0->ZA0_STATUS := "2" // 0=Aguard. Integração;1=Integrado;2=Erro
			ZA0->ZA0_OBS	:= ZA0->ZA0_OBS + "Cliente não encontrado" + CRLF
			ZA0->(MsUnlock())

		EndIf

		(cQryCliente)->(DbCloseArea())

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
