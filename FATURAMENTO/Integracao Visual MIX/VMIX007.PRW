#Include 'Protheus.ch'
#include "Tbiconn.ch"
#Include "TOPCONN.CH"
#Include "REPORT.ch"
#include "rptdef.ch"

/*/{Protheus.doc} VMIX007
Rotina para Baixar titulos do tipo VL a receber.
/*/ 
User Function VMIX007(__cEmpresa, __cFilial)

	Local nW			:= 0
	Local nX			:= 0
	Local aEmp 			:= {}
	Local cDtCorte		:= ""
	Local cHoraProcI	:= ""
	Local cHoraProcF	:= ""
	Local cDTUltProc	:= ""

	Default __cEmpresa := "01"
	Default __cFilial  := "0101"

	RPCClearEnv()
	RPCSetType(3)

	RPCSetEnv(__cEmpresa,__cFilial,,,"FIN")

	cDTUltProc := GetNewPar("ZZ_DTULTPR", "")
	cDtCorte   := GetNewPar("ZZ_DTCOVOU", "20210801")
	cHoraProcI := GetNewPar("ZZ_HRCOVOI", "21:00:00")
	cHoraProcF := GetNewPar("ZZ_HRCOVOF", "21:15:00")

	If Empty(cDTUltProc)

		cDTUltProc := DTOS(dDataBase)

	EndIf

	If cDTUltProc == DTOS(dDataBase) .And. Time() >= cHoraProcI .And. Time() <= cHoraProcF

		SavePar("ZZ_DTULTPR", "C", DTOS(dDataBase + 1))

		aEmp := FWAllGrpCompany()

		For nW := 1 To Len(aEmp)

			aFil := FWAllFilial(,,aEmp[nW])

			For nX := 1 To Len(aFil)

				RPCClearEnv()
				RPCSetType(3)

				RPCSetEnv(aEmp[nW], aEmp[nW]+ aEmp[nW]+ aFil[nX],,,"FIN")

				Processa({|| Execute(cDtCorte)}, "Aguarde...", "Iniciando baixa dos titulos VL..", .F.)

			Next nX

		Next nW

		//conout("GERANDO RELATORIO. INICIO")

		U_VMIX008()

		//conout("GERANDO RELATORIO. FIM")

	EndIf

Return Nil

Static Function Execute(cDtCorte)

	Local cSql          := ""
	Local cQry			:= GetNextAlias()

	Default cDtCorte	:= DTOS(dDataBase)

	Private __aCab      := {}
	Private __aItens    := {}
	Private __aPgtos    := {}
	Private __cMsgAdv   := ""
	Private __cMsgErro  := ""
	Private __oError    := Nil

	//conout("[" + cEmpAnt + cFilAnt + "] " + "INTEGRACAO VMIX007 VERSAO INICIADA...")

	cSql := " SELECT * "
	cSql += " FROM " + RetSqlName("SE1")
	cSql += " WHERE E1_FILIAL = " + ValToSql(xFilial("SE1"))
	cSql += " AND E1_TIPO = 'CR' "
	cSql += " AND E1_SALDO > 0 "
	cSql += " AND E1_ORIGEM = 'LOJA701' "
	cSql += " AND E1_EMISSAO >= " + ValToSql(cDtCorte)
	cSql += " AND D_E_L_E_T_ = '' "

	TCQUERY cSql NEW ALIAS (cQry)

	(cQry)->(DbGoTop())

	While (cQry)->(!Eof())

		ExecBaixaCR(cQry)

		(cQry)->(DbSkip())

	EndDo

	(cQry)->(DbCloseArea())

	//conout("[" + cEmpAnt + cFilAnt + "] " + "INTEGRACAO VMIX007 CONCLUIDA.")

Return Nil

Static Function ExecBaixaCR(cQry)

	Local aTit      := {}
	Local aAutoErro := {}
	Local aPerg     := {}
	Local cLogTxt   := ""

	Private lMsErroAuto     := .F.
	Private lMsHelpAuto     := .T.
	Private lAutoErrNoFile  := .T.

	Pergunte("FIN070", .F.,,,,, @aPerg)

	// MV_PAR03 := 1
	// MV_PAR05 := 1

	//01 - Mostra Lanc Contab ?
	//02 - Aglut Lancamentos ?
	//03 - Abate Desc. Comiss. ?
	//04 - Contabiliza On Line ?
	//05 - Cons.Juros Comissao ?
	//06 - Destacar Abatimentos ?
	//07 - Replica Rateio ?
	//08 - Gera cheque p/ Adiantamento ?
	//09 - Considera Retencäo Bancaria ?
	//10 - Utiliza banco anterior ?

	__SaveParam("FIN070", aPerg)

	aAdd(aTit, {"E1_PREFIXO"    , (cQry)->E1_PREFIXO   , Nil})
	aAdd(aTit, {"E1_NUM"        , (cQry)->E1_NUM       , Nil})
	aAdd(aTit, {"E1_PARCELA"    , (cQry)->E1_PARCELA   , Nil})
	aAdd(aTit, {"E1_TIPO"       , (cQry)->E1_TIPO      , Nil})

	aAdd(aTit, {"AUTMOTBX"      , "VOU"			  , Nil})

	// aAdd(aTit, {"AUTBANCO"      , "CX1" 		      , Nil})
	// aAdd(aTit, {"AUTAGENCIA"    , "00001"     		  , Nil})
	// aAdd(aTit, {"AUTCONTA"      , "0000000001" 	      , Nil})

	aAdd(aTit, {"AUTDTBAIXA"    , dDataBase			, Nil})
	aAdd(aTit, {"AUTDTCREDITO"  , dDataBase		    , Nil})

	// aAdd(aTit, {"AUTDESCONT"    , oObj:nVlDesc      , Nil,.T.})
	// aAdd(aTit, {"AUTJUROS"      , oObj:nVlJuro      , Nil,.T.})
	// aAdd(aTit, {"AUTMULTA"      , oObj:nVlMult      , Nil,.T.})

	// aAdd(aTit, {"AUTACRESC"     , oObj:nVlOCre      , Nil})
	// aAdd(aTit, {"AUTVALREC"     , oObj:nVlRec       , Nil})

	MsExecAuto({|x,y| FINA070(x,y)}, aTit, 3)

	If lMsErroAuto

		aAutoErro := GETAUTOGRLOG()

		cLogTxt += GetErrorLog(aAutoErro)

		//conout("[" + cEmpAnt + cFilAnt + "] " + "VMIX007 >>> ERRO BAIXA AUTOMATICA (BAIXA - ERRO)- (PREF+NUM+PARC+TIPO) = "+(SE1->E1_PREFIXO+SE1->E1_NUM+SE1->E1_PARCELA+SE1->E1_TIPO)+": ERRO: "+cLogTxt)

	Else

		//conout("[" + cEmpAnt + cFilAnt + "] " + "VMIX007 >>> BAIXA AUTOMATICA (BAIXA - SUCESSO) - (PREF+NUM+PARC+TIPO) = "+(SE1->E1_PREFIXO+SE1->E1_NUM+SE1->E1_PARCELA+SE1->E1_TIPO))

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

Static Function SavePar(cPar, cTipo, cConteudo)

	Local nLenFil := 0
	Local lExist  := .F.

	If !PutMv(cPar, cConteudo)
		

	EndIf

Return()
