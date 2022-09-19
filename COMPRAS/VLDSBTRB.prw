#INCLUDE 'PROTHEUS.CH'

User function VLDSBTRB()

//Estados que nao tem convenio
Local _cEstSub := GETNEWPAR('ZZ_ESTSCN',"")
//Tes que tem substituicao tributaria
Local _cTesSub := GETNEWPAR('ZZ_TESSUB',"")
Local _cWhere  := '%'

IF !EMPTY(_cEstSub) .AND. !EMPTY(_cTesSub)
    //Adiciona no fluigo solicitação de aprovação
    if select('SD1TMP2') <> 0
        SD1TMP2->(dbCloseArea())
    ENDIF

    _cWhere += ' AND A2_EST IN ('+_cEstSub+')'
    _cWhere += ' AND Z1_TES IN ('+_cTesSub+')'
    _cWhere += '%'

    BeginSQL Alias "SD1TMP2"
        COLUMN F1_EMISSAO AS DATE
        SELECT 
        F1_DOC,F1_SERIE,F1_EMISSAO,A2_EST,A2_NREDUZ,D1_COD,D1_QUANT,D1_VUNIT,D1_TOTAL,A2_CGC,
        B1_DESC,F1_VALBRUT,F1_FILIAL,D1_PEDIDO
        FROM %Table:SF1% SF1
        INNER JOIN %table:SD1% SD1 ON (D1_FILIAL=F1_FILIAL AND D1_DOC=F1_DOC AND D1_SERIE=F1_SERIE AND D1_FORNECE=F1_FORNECE AND D1_LOJA = F1_LOJA )
        INNER JOIN %Table:SB1% SB1 ON B1_COD = D1_COD  
        INNER JOIN %Table:SA2% SA2 ON A2_COD=F1_FORNECE AND A2_LOJA = F1_LOJA  
        INNER JOIN %Table:SZ1% SZ1 ON Z1_PRODUTO = D1_COD AND Z1_MSBLQL != '1'  
        WHERE SD1.D1_FILIAL=%xFilial:SD1% AND ;
        SD1.D1_DOC     = %exp:CNFISCAL% AND ;
        SD1.D1_SERIE   = %exp:CSERIE% AND ;
        SD1.D1_FORNECE = %exp:cA100For% AND ;
        SD1.D1_LOJA    = %exp:CLOJA% AND ;
        SF1.%NotDel% AND ;
        SD1.%NotDel% AND ;
        SF1.%NotDel% AND ;
        SA2.%NotDel% AND ;
        SB1.%NotDel% AND ;
        SZ1.%NotDel% ;
        %exp:_cWhere% ;

    EndSQL

    if !SD1TMP2->(EOF())     
        
        envMail()
        
        Aviso("SUBSTITUICAO_TRIBUTARIA","Esta nota possui produtos com substituição tributária.",{"Fechar"},1)

    ENDIF

    SD1TMP2->(dbCloseArea())
ENDIF
return


/*/{Protheus.doc} envMail
worflow de NOTAS com produto com substituicao tributaria
@type  User Function
@author Eduardo Vieira
@since 01/04/2020
/*/

Static Function envMail()
    
    //Local cLocLogo      := "/ws/images/china-brand-cm-port.png"
    Local cHtmlMod      := ""
    
    Local _cMailSubs := GETNEWPAR('ZZ_MAILSUB',"")
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

    cHtmlMod      := "\workflow\HTML\WFSUBSTITUICAOTRIB.html"
    _cAssMail := SD1TMP2->F1_FILIAL+" - NF com Subst. Tributária - "+ALLTRIM(SD1TMP2->A2_NREDUZ)+ " - NF " + SD1TMP2->F1_DOC 
    oProc := TWFProcess():New( "000001",_cAssMail )
    oProc:NewTask( "Criando WF de aprovação de substituição tributária", cHtmlMod )
    oProc:cSubject := _cAssMail

    oHtml := oProc:oHtml

    If ( valtype(oHtml) != "U" .and. !empty(_cMailSubs))

        oHtml:ValByName("cNota", SD1TMP2->F1_DOC )
        oHtml:ValByName("cSerie", SD1TMP2->F1_SERIE )
        oHtml:ValByName("nomeFornecedor", SD1TMP2->A2_NREDUZ )
        oHtml:ValByName("cnpjFornece",  Transform(SD1TMP2->A2_CGC,PesqPict("SA2","A2_CGC")) )
        oHtml:ValByName("ufFornec", SD1TMP2->A2_EST )
        oHtml:ValByName("dtEmissao", SD1TMP2->F1_EMISSAO )
    
        
        
        _cChvEnt := SD1TMP2->F1_FILIAL+SD1TMP2->D1_PEDIDO

        cAttachFile := attachFiles(@oProc,SD1TMP2->F1_FILIAL, _cChvEnt)
        
		cSubject 	:= _cAssMail
        _nTotProd := 0 
        While !SD1TMP2->(EOF())     
            
            AADD((oHtml:ValByName("ap.produto")),SD1TMP2->D1_COD)
            AADD((oHtml:ValByName("ap.descricao")),SD1TMP2->B1_DESC)
            AADD((oHtml:ValByName("ap.qtd")),PadR(TransForm(SD1TMP2->D1_QUANT,'@E 999,999,999.99'),15) )
            AADD((oHtml:ValByName("ap.vlunit")), PadR(TransForm(SD1TMP2->D1_VUNIT,'@E 999,999,999.99'),15) )
            AADD((oHtml:ValByName("ap.vltotal")),PadR(TransForm(SD1TMP2->D1_TOTAL,'@E 999,999,999.99'),15) )
            _nTotProd += SD1TMP2->D1_TOTAL
            SD1TMP2->(dbSkip())
        EndDo

        oHtml:ValByName("totalNota", PadR(TransForm(_nTotProd,'@E 999,999,999.99'),15) )

        oProc:cTo := _cMailSubs

        oProc:Start()

        cTo 		:= _cMailSubs
		cCc 		:= ""
		cBcc 		:= ""
		cBody 		:=  ohtml:HtmlCode()

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

    
    FreeObj(oProc)

     
    FreeObj(oHtml)

Return( Nil )

/*/{Protheus.doc} attachFiles
Função responsavel por buscar os arquivos anexados a solicitação no GED.
@type function
@version 1.0
@author Kaique Mathias
@since 6/23/2020
@param oProc, object, param_description
@return return_type, return_description
/*/

Static Function attachFiles(oProc,_cFilPd,_cChvEnt)

    Local cAliasAx  := GetNextAlias()
    Local cDirDoc   := MsDocPath()
    Local _cWrAnex  := "% AND AC9_CODENT LIKE '"+_cChvEnt+"%' %"
    Local _cArqEnv := ''
    BeginSQL Alias cAliasAx
	 
    SELECT ACB_OBJETO
    FROM %TABLE:AC9% AC9
    INNER JOIN %TABLE:ACB% ACB ON ACB_FILIAL = AC9_FILIAL AND AC9_CODOBJ = ACB_CODOBJ AND ACB.%NotDel% 
    WHERE AC9.%NotDel% AND AC9_ENTIDA='SC7' %EXP:_cWrAnex%
    AND AC9_FILENT = %EXP:_cFilPd% AND ACB_DESCRI LIKE 'DANFE%'

    EndSQL

    WHILE !(cAliasAx)->(Eof())
        cFile := cDirDoc + "\" + alltrim((cAliasAx)->ACB_OBJETO)
        _cArqEnv := cFile
        oProc:AttachFile(cFile)
        (cAliasAx)->(dbSkip())
    EndDo

Return( _cArqEnv )


