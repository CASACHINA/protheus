#INCLUDE "rptdef.ch"
#INCLUDE "TOTVS.CH"
#INCLUDE "TOPCONN.CH"

/*/{Protheus.doc} VMIX008
Rotina envia relatorio em anexo de titulos do tipo VL a receber.
/*/ 
User Function VMIX008(dBaixaDe_, dBaixaAte_)

	Local oReport
	Local aParam := {}
	Local cName := "VMIX008"

	Default dBaixaDe_ := dDatabase
	Default dBaixaAte_ := dDatabase 

	Private cFileName	 := cName
	Private _dBaixaDe    := dBaixaDe_
	Private _dBaixaAte   := dBaixaAte_

	If IsBlind()

		oReport := ReportDef()

	Else

		aAdd(aParam, {1, "Dt Baixa De"	, _dBaixaDe	, "@D",".T.",,".T.",50,.F.})
		aAdd(aParam, {1, "Dt Baixa Ate"	, _dBaixaAte	, "@D",".T.",,".T.",50,.F.})

		If ParamBox(aParam, "Parâmetros",,,,,,,,cName, .T., .T.)

			lRet := .T.

			_dBaixaDe    := ParamLoad(cFileName,,3, dDataBase)
			_dBaixaAte   := ParamLoad(cFileName,,4, dDataBase)

			oReport := ReportDef()
			oReport:PrintDialog()

		EndIf

	EndIf

Return()

Static Function ReportDef()

	Local oReport
	Local oSecMov
	Local cFile		:= ""
	Local cQry 		:= GetNextAlias()
	Local nTentativa:= 21
	Local cTitRel 	:= "Baixa de Títulos"

	oReport := TReport():New("VMIX008", cTitRel, {|| }, {|oReport| PrintReport(oReport, cQry)}, cTitRel)

	oSecMov := TRSection():New(oReport, "Títulos", cQry)

	//TRCell():New( oSection1, "N3_ITEM"   	, ,/*X3Titulo*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)

	TRCell():New(oSecMov, "E5_FILIAL"   , cQry, "Emp./Fil.")
	TRCell():New(oSecMov, "E5_DATA"     , cQry)
	TRCell():New(oSecMov, "A1_COD"    	, cQry)
	TRCell():New(oSecMov, "A1_LOJA"   	, cQry)
	TRCell():New(oSecMov, "A1_NOME_"   	, cQry, "Nome"		,"",40)
	TRCell():New(oSecMov, "A1_CGC_"    	, cQry, "Cpf/Cnpj"	,"",18)
	TRCell():New(oSecMov, "E5_PREFIXO"  , cQry)
	TRCell():New(oSecMov, "E5_TIPO"		, cQry)
	TRCell():New(oSecMov, "E5_NUMERO"   , cQry)
	TRCell():New(oSecMov, "E5_PARCELA"  , cQry)
	TRCell():New(oSecMov, "E5_VALOR"    , cQry)

	If IsBlind()

		oReport:cFile       := cFileName + "_" + dToS(dDataBase) + "_" + StrTran(Time(), ":", "_")
		oReport:nRemoteType := NO_REMOTE
		oReport:nDevice     := 6

		oReport:SetEnvironment(1)

		oReport:SetViewPDF(.F.)
		oReport:Print(.F.)

		cFile := "spool\" + oReport:cFile + ".pdf"

		While File(Replace(cFile, ".pdf", ".rel")) .And. nTentativa <> 0
			
			ConOut("VMIX008 - Arquivo está em processo. Aguardando..." + cValToChar(nTentativa) + "[" + cFile + "]")

			nTentativa--

			Sleep(10000)

		EndDo

		// lRet := CpyT2S(cFile, "\treport")

		// If !lRet

		// 	ConOut("ERRO AO ENVIAR ARQUIVO: " + cFile + " >>> PARA O SERVIDOR.")

		// EndIf

		// Envia o Email
		cAccount	:= GetMv("MV_RELACNT")
		cPassword	:= GetMv("MV_RELPSW")
		lAuth 		:= GetMv("MV_RELAUTH")
		nTimeOut 	:= GetMv("MV_RELTIME")
		lUseSSL 	:= GetMv("MV_RELSSL")
		lUseTLS 	:= GetMv("MV_RELTLS")
		cFrom 		:= GetMv("MV_RELFROM")
		cServer 	:= GetMv("MV_RELSERV")
		nSmtpPort 	:= GETMV("MV_PORSMTP")

		oMessage 	:= TMailMessage():New()

		cTo 		:= GetNewPar("ZZ_EMABXVL", "diego@grupocasachina.com.br")
		cCc 		:= ""
		cBcc 		:= ""
		cSubject 	:= "Relatório de baixas"
		cBody 		:= ""
		cAttachFile := "\spool\" + oReport:cFile + ".pdf"

		If (nPos := At(':', cServer)) > 0

			nSmtpPort := Val(Substr(cServer, nPos + 1, Len(cServer)))

			cServer := Substr(cServer, 0, nPos - 1)

		EndIf

		If nSmtpPort == 0

			If GETMV("MV_PORSMTP") == 0

				nSmtpPort := 25

			Else

				nSmtpPort := GETMV("MV_PORSMTP")

			EndIf

		EndIf

		oServer := TMailManager():New()

		oServer:SetUseSSL(lUseSSL)

		oServer:SetUseTLS(lUseTLS)

		oServer:Init("", cServer, cAccount, cPassword,, nSmtpPort)

		oServer:SetSmtpTimeOut(60)

		If (lRet := oServer:SmtpConnect() == 0)

			If lAuth

				lRet := oServer:SmtpAuth(cAccount, cPassword) == 0

			EndIf

			If lRet

				oMessage:cFrom := cFrom
				oMessage:cTo := cTo
				oMessage:cCc := cCc
				oMessage:cBcc := cBcc
				oMessage:cSubject := cSubject //+ If(Upper(AllTrim(GetSrvProfString("DbAlias", ""))) == "PRODUCAO", "", " - (AMBIENTE DE TESTE)")
				oMessage:cBody := cBody

				oMessage:AttachFile(cAttachFile)

				If (lRet := oMessage:Send(oServer) == 0)

					oServer:SmtpDisconnect()

				EndIf

			EndIf

		EndIf

	EndIf

Return(oReport)

Static Function PrintReport(oReport, cQry)

	Local oSecMov 	:= oReport:Section(1)
	Local cSQL 		:= ""
	Local nW		:= 0
	Local nX		:= 0
	Local cEmpFil	:= ""
	Local cCgc		:= ""
	Local aEmp 		:= FWAllGrpCompany()

	For nW := 1 To Len(aEmp)

		aFil := FWAllFilial(,,aEmp[nW])

		For nX := 1 To Len(aFil)

			If !Empty(cSQL)

				cSql += " UNION ALL "

			EndIf

			cSQL += " SELECT " + ValToSQL(aEmp[nW]) + " EMP, E5_FILIAL, E5_PREFIXO, E5_NUMERO, E5_PARCELA, E5_TIPO, A1_COD, "
			cSql += " 		 A1_LOJA, A1_NOME A1_NOME_, A1_CGC A1_CGC_, E5_TIPO, E5_VALOR, E5_DATA "
			cSQL += " FROM " + RetFullName("SE5", aEmp[nW]) + " SE5 "
			cSql += " INNER JOIN " + RetFullName("SA1", aEmp[nW]) + " SA1 ON "
			cSql += " ( "
			cSQL += " 	A1_FILIAL 			= " + ValToSQL(xFilialEmp("SA1", aEmp[nW], aEmp[nW] + aEmp[nW] + aFil[nX]))
			cSQL += " 	AND A1_COD 			= E5_CLIFOR "
			cSQL += " 	AND A1_LOJA			= E5_LOJA "
			cSQL += " 	AND E5_MOTBX		= 'VOU' "
			cSQL += " 	AND SA1.D_E_L_E_T_ 	= '' "
			cSql += " ) "
			cSQL += " WHERE E5_DATA			BETWEEN " + ValToSQL(_dBaixaDe) + " AND " + ValToSQL(_dBaixaAte)
			cSql += " AND E5_FILIAL		= " + ValToSQL(xFilialEmp("SE5", aEmp[nW], aEmp[nW] + aEmp[nW] + aFil[nX]))
			cSQL += " AND SE5.D_E_L_E_T_ 	= '' "

		Next nX

	Next nW

	cSQL += " ORDER BY 1, 2, 3, 4, 5, 6 "

	TcQuery cSQL New Alias (cQry)

	(cQry)->(DbGoTop())

	cEmpFil := (cQry)->EMP + (cQry)->E5_FILIAL

	While !(cQry)->(Eof())

		nTot := 0

		cEmpFil := (cQry)->EMP + (cQry)->E5_FILIAL

		oSecMov:Init()

		While !(cQry)->(Eof()) .And. (cQry)->EMP + (cQry)->E5_FILIAL == cEmpFil

			nTot += (cQry)->E5_VALOR

			cCgc := AllTrim((cQry)->A1_CGC_)

			If Len(cCgc) == 14

				cCgc := Transform(cCgc, "@R 99.999.999/9999-99")

			ElseIf Len(cCgc) == 11

				cCgc := Transform(cCgc, "@R 999.999.999-99")

			EndIf

			oSecMov:Cell("E5_FILIAL"	):SetValue((cQry)->E5_FILIAL    )
			oSecMov:Cell("E5_PREFIXO"	):SetValue((cQry)->E5_PREFIXO   )
			oSecMov:Cell("E5_NUMERO"   	):SetValue((cQry)->E5_NUMERO	)
			oSecMov:Cell("E5_PARCELA"	):SetValue((cQry)->E5_PARCELA   )
			oSecMov:Cell("A1_COD"  		):SetValue((cQry)->A1_COD       )
			oSecMov:Cell("A1_LOJA" 		):SetValue((cQry)->A1_LOJA      )
			oSecMov:Cell("A1_NOME_"		):SetValue((cQry)->A1_NOME_     )
			oSecMov:Cell("A1_CGC_" 		):SetValue(cCgc)
			oSecMov:Cell("E5_TIPO"  	):SetValue((cQry)->E5_TIPO      )
			oSecMov:Cell("E5_VALOR"	    ):SetValue((cQry)->E5_VALOR     )
			oSecMov:Cell("E5_DATA"		):SetValue(STOD((cQry)->E5_DATA))

			oSecMov:PrintLine()

			(cQry)->(DbSkip())

		EndDo

		oSecMov:Cell("E5_FILIAL"	):SetValue("")
		oSecMov:Cell("E5_PREFIXO"	):SetValue("")
		oSecMov:Cell("E5_NUMERO"   	):SetValue("")
		oSecMov:Cell("E5_PARCELA"	):SetValue("")
		oSecMov:Cell("A1_COD"  		):SetValue("")
		oSecMov:Cell("A1_LOJA" 		):SetValue("")
		oSecMov:Cell("A1_NOME_"		):SetValue("")
		oSecMov:Cell("A1_CGC_" 		):SetValue("")
		oSecMov:Cell("E5_TIPO"  	):SetValue("")
		oSecMov:Cell("E5_VALOR"	    ):SetValue(nTot)
		oSecMov:Cell("E5_DATA"		):SetValue("")

		oSecMov:PrintLine()

		oSecMov:Finish()

	EndDo

	(cQry)->(DbCloseArea())

Return()

Static Function xFilialEmp(cAlias, cEmp, cFil)

	Local cFilRet := Space(FWSizeFilial())

	OpenSXs( , , , ,cEmp,"SX2TMP")

	DbSelectArea("SX2TMP")
	DbSeek(Upper(cAlias))

	If SX2TMP->X2_MODO == "E"

		cFilRet := cFil

	Else

		cFilRet := cEmp + cEmp

	EndIf

	dbCloseArea()

Return( cFilRet )
