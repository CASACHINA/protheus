#INCLUDE "rptdef.ch"
#INCLUDE "TOTVS.CH"
#INCLUDE "TOPCONN.CH"

/*/{Protheus.doc} CYBER005
Rotina envia relatorio em anexo das integrações recebidas do Cyberlog.
/*/ 

User Function CYBER005(aParam)

	Local oReport
	Local cName := "CYBER005"

	Default aParam	:= {"01", "010101"}

	RPCSetEnv(aParam[1],aParam[2],,,"COM")

	Private cFileName	 := cName

	oReport := ReportDef()

	RPCClearEnv()

Return()

Static Function ReportDef()

	Local oReport
	Local oSecMov
	Local cFile		:= ""
	Local cQry 		:= GetNextAlias()
	Local nTentativa:= 21
	Local cTitRel 	:= "Relatório de Integrações Recebidas do Cyberlog - " + DTOC(dDataBase - 1)

	Local lMacOS	:= .F.
	Local cLibCli	:= ""
	Local cTempPath	:= ""
	Local nRemote	:= GetRemoteType(@cLibCli)

	lMacOS := Iif('MAC' $ cLibCli,.T.,.F.)

	cSep := If(lMacOS, "/", "\")

	If nRemote == 1 // Smartclient

		cTempPath := GetTempPath() + cSep + "totvsprinter" + cSep

	ElseIf nRemote == -1 // JOB

		cTempPath := Supergetmv("MV_RELT",,"\spool\")

	EndIf

	cTempPath := SubStr( cTempPath, 1, If(Len(cTempPath) == Rat(cSep, cTempPath), Rat(cSep, cTempPath) - 1, Len(cTempPath) ) )

	cTempPath := Replace(cTempPath, "\\", "\")
	cTempPath := Replace(cTempPath, "\\", "\")
	cTempPath := Replace(cTempPath, "\\", "\")
	cTempPath := Replace(cTempPath, "\\", "\")

	oReport := TReport():New("CYBER005", cTitRel, {|| }, {|oReport| PrintReport(oReport, cQry)}, cTitRel)

	oSecMov := TRSection():New(oReport, "Títulos", cQry)

	//TRCell():New( oSection1, "N3_ITEM"   	, ,/*X3Titulo*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)

	TRCell():New(oSecMov, "ZA4_FILIAL"	, cQry, "Emp./Fil.")
	TRCell():New(oSecMov, "ZA4_TABPRO"	, cQry)
	TRCell():New(oSecMov, "ZA4_CHAVE" 	, cQry)
	TRCell():New(oSecMov, "TOT"		 	, cQry)
	TRCell():New(oSecMov, "OBS"		 	, cQry)

	If IsBlind()

		oReport:cFile := cFileName + "_" + dToS(dDataBase) + "_" + StrTran(Time(), ":", "_")

		oReport:SetPreview(.F.)

		oReport:nDevice := 6

		oReport:SetViewPDF(.F.)

		cFile := cTempPath + "\" + oReport:cFile + ".pdf"

		If nRemote == -1

			oReport:nRemoteType := NO_REMOTE

			oReport:SetEnvironment(1)

		EndIf

		If nRemote == 1 // Smartclient

			oReport:Print(.F.)

		ElseIf nRemote == -1 // Job

			oReport:PrintDialog()

		Else // Outros

			oReport:Print()

		EndIf


		While File(Replace(cFile, ".pdf", ".rel")) .And. nTentativa <> 0

			ConOut("CYBER005 - Arquivo está em processo. Aguardando..." + cValToChar(nTentativa) + "[" + cFile + "]")

			nTentativa--

			Sleep(10000)

		EndDo

		lRet := CpyT2S(cFile, "\spool")

		If !lRet

			ConOut("ERRO AO ENVIAR ARQUIVO: " + cFile + " >>> PARA O SERVIDOR.")

		EndIf

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
		cSubject 	:= cTitRel
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
	Local nQtdLimProc	:= GetnewPar("ZZ_QTLIMPR", 5)

	cSQL += " SELECT ZA4_FILIAL, ZA4_TABPRO, ZA4_CHAVE, COUNT(*) TOT "
	cSQL += " FROM ZA4010 A (NOLOCK) "
	cSQL += " WHERE 1 = 1 "
	cSQL += " AND ZA4_TABPRO <> '' "
	cSQL += " AND ZA4_TIPO = 'R' "
	cSQL += " AND D_E_L_E_T_ = '' "
	cSQL += " AND ZA4_DTINC = FORMAT(DATEADD(DAY, -1, GETDATE()), 'yyyyMMdd') "
	cSQL += " GROUP BY ZA4_FILIAL, ZA4_TABPRO, ZA4_CHAVE "
	cSQL += " ORDER BY ZA4_FILIAL, ZA4_TABPRO, TOT DESC "

	TcQuery cSQL New Alias (cQry)

	(cQry)->(DbGoTop())

	While !(cQry)->(Eof())

		oSecMov:Init()

		oSecMov:Cell("ZA4_FILIAL"	):SetValue((cQry)->ZA4_FILIAL	)
		oSecMov:Cell("ZA4_TABPRO"	):SetValue((cQry)->ZA4_TABPRO   )
		oSecMov:Cell("ZA4_CHAVE"   	):SetValue((cQry)->ZA4_CHAVE	)
		oSecMov:Cell("TOT"			):SetValue((cQry)->TOT			)

		If (cQry)->TOT >= nQtdLimProc

			oSecMov:Cell("OBS"		):SetValue("Avaliar log.")

		Else

			oSecMov:Cell("OBS"		):SetValue("")

		EndIf

		oSecMov:PrintLine()

		(cQry)->(DbSkip())

	EndDo

	oSecMov:Finish()

	(cQry)->(DbCloseArea())

Return()
