#include "Tbiconn.ch"
#Include "TOPCONN.CH"
#Include 'Protheus.ch'

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³VMIXINUT  ºAutor  ³Fabiano Filla       º Data ³  01/24/19   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³ Programa para inutizar numeração inutiliadas/canceladas    º±±
±±º          ³ no Visual Mix.                                              º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ AP                                                        º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/

User Function VMIXINUT(aParam)
    If Type("aParam") <> "U" .And. ValType(aParam) == "A"
        For _iCount := 1 To Len(aParam) 
	  If ValType(aParam[_iCount]) == "C"
              ConOut("aParam " + StrZero(_iCount) + " --> " + aParam[_iCount])
	  ElseIf ValType(aParam[_iCount]) == "N"
              ConOut("aParam " + StrZero(_iCount) + " --> " + Str(aParam[_iCount]))
	  ElseIf ValType(aParam[_iCount]) == "D"
              ConOut("aParam " + StrZero(_iCount) + " --> " + Dtoc(aParam[_iCount]))
	  EndIf
        Next
	
	__cEmpresa := aParam[1]
	__cFilial  := aParam[2]
    EndIf

    If !Empty(__cEmpresa) .And. !Empty(__cFilial)
        Execute(__cEmpresa, __cFilial)
    Else
        Processa({|| Execute()}, "Aguarde...", "Iniciando inutilização de numeração feita no Visual Mix...", .F.)
    EndIf

Return Nil

Static Function Execute(__cEmpresa, __cFilial)

    Local cSql      := ""
	Local nRegTotal := 0
	Local nRegAtual	:= 0

    Local cVMIXDB   := "" // banco de dados do visual mix
    Local cVMIXINS  := "" // instância do visual mix
    Local cVMIXTAB  := "" // tabela start do visual mix
    Local cVMIXCAPA := "" // tabela capa visual mix - dados da nota
    Local cVMIXFIL  := "" // filial do visual mix
    Local cVMIXQTD  := "" // qtde de registros para importar por execução
    Local cVMIXNTP  := "102" // tipo de evento que deve ser importado
    Local cVMIXCTP  := "" // tipo de evento de cancelamento
    Local cVMIXKEY  := "" // chave de pesquisa no caso de cancelamento
    // Local lVMIXVNR  := "" // no caso de cancelamento se deve voltar o número para pesquisar .T. ou .F.

    Default __cEmpresa  := ""
    Default __cFilial   := ""

    If !Empty(__cEmpresa) .And. !Empty(__cFilial)
        __lJob := .T.

    	RPCClearEnv()
    	RPCSetType(3)	
    	RPCSetEnv(__cEmpresa,__cFilial,,,"FIN","VMIX002")
	Else
		__lJob := .F.
    EndIf
    
    xDataBase := dDataBase
    cVMIXDB   := AllTrim(GetNewPar("ZZ_VMIXDB", "")) // retirar depois dos testes
    //cVMIXDB   := "pg_visualmix_ls_prod.visualmix.vm_integracao" //fixando área de produção
    cVMIXTAB  := AllTrim(GetNewPar("ZZ_VMIXTAB", ""))
    cVMIXCAPA := AllTrim(GetNewPar("ZZ_VMIXCAP", ""))
    cVMIXFIL  := AllTrim(GetNewPar("ZZ_VMIXFIL", ""))
    cVMIXQTD  := AllTrim(GetNewPar("ZZ_VMIXQTD", "10"))
    cVMIXCTP  := AllTrim(GetNewPar("ZZ_VMIXCTP", ""))
    cVMIXKEY  := AllTrim(GetNewPar("ZZ_VMIXKEY", ""))

    cVMIXINS  := SubStr(cVMIXDB, At(".", cVMIXDB) + 1, Len(cVMIXDB))
    cVMIXDB   := SubStr(cVMIXDB, 1, At(".", cVMIXDB) - 1)

    Conout("INTEGRACAO VISUAL MIX VERSÃO 2.00 INICIADA - INUTILIZAÇÃO...")

    If !__lJob

        ProcRegua(0)	
        IncProc("Calculando quantidade de registros...")
        IncProc(1)	
        IncProc(1)	

    EndIf        
        
    If Empty(cVMIXDB)
        If __lJob
            ConOut("Impossível iniciar a integração com o Visual Mix, favor preecher o Parâmetro ZZ_VMIXDB com o caminho do banco de dados do Visual Mix!")
        Else
            MsgStop("Impossível iniciar a integração com o Visual Mix, favor preecher o Parâmetro ZZ_VMIXDB com o caminho do banco de dados do Visual Mix!")
        EndIf
        Return Nil
    EndIf

    If Empty(cVMIXTAB)
        If __lJob
            ConOut("Impossível iniciar a integração com o Visual Mix, favor preecher o Parâmetro ZZ_VMIXTAB com a tabela de consulta do Visual Mix!")
        Else
            MsgStop("Impossível iniciar a integração com o Visual Mix, favor preecher o Parâmetro ZZ_VMIXTAB com a tabela de consulta do Visual Mix!")
        EndIf
        Return Nil
    EndIf

    If Empty(cVMIXCAPA)
        If __lJob
            ConOut("Impossível iniciar a integração com o Visual Mix, favor preecher o Parâmetro ZZ_VMIXCAP com a tabela de consulta do Visual Mix Notas Fiscais!")
        Else
            MsgStop("Impossível iniciar a integração com o Visual Mix, favor preecher o Parâmetro ZZ_VMIXCAP com a tabela de consulta do Visual Mix Notas Fiscais!")
        EndIf
        Return Nil
    EndIf

    If Empty(cVMIXFIL)
        If __lJob
            ConOut("Impossível iniciar a integração com o Visual Mix, favor preecher o Parâmetro ZZ_VMIXFIL com a filial do Visual Mix!")
        Else
            MsgStop("Impossível iniciar a integração com o Visual Mix, favor preecher o Parâmetro ZZ_VMIXFIL com a filial do Visual Mix!")        
        EndIf
        Return Nil
    EndIf

    If Empty(cVMIXNTP)
        If __lJob
            ConOut("Impossível iniciar a integração com o Visual Mix, favor preecher o Parâmetro ZZ_VMIXNTP com o(s) tipos de evento que não serão importados!")
        Else
            MsgStop("Impossível iniciar a integração com o Visual Mix, favor preecher o Parâmetro ZZ_VMIXNTP com o(s) tipos de evento que não serão importados!")
        EndIf
        Return Nil
    EndIf

    If Empty(cVMIXCTP)
        If __lJob
            ConOut("Impossível iniciar a integração com o Visual Mix, favor preecher o Parâmetro ZZ_VMIXCTP com o(s) tipos de evento de cancelamento!")
        Else
            MsgStop("Impossível iniciar a integração com o Visual Mix, favor preecher o Parâmetro ZZ_VMIXCTP com o(s) tipos de evento de cancelamento!")
        EndIf
        Return Nil
    EndIf

    If Empty(cVMIXKEY)
        If __lJob
            ConOut("Impossível iniciar a integração com o Visual Mix, favor preecher o Parâmetro ZZ_VMIXKEY com a chave de pesquisa do cancelamento!")
        Else
            MsgStop("Impossível iniciar a integração com o Visual Mix, favor preecher o Parâmetro ZZ_VMIXKEY com a chave de pesquisa do cancelamento!")
        EndIf
        Return Nil
    EndIf

    //Consulta cupons inutilizados/cancelados - parei

    cSql := "     SELECT * "
    cSql += "       FROM OPENQUERY (" + cVMIXDB + ", "
    cSql += "    'SELECT * "
    cSql += "       FROM " + cVMIXINS + "." + cVMIXTAB
    cSql += "      WHERE loja = " + cVMIXFIL + " "
    cSql += "        AND tipo_evento IN (" + cVMIXNTP + ")"
    cSql += "        AND flag = 0 "
    cSql += "   ORDER BY data_alteracao "
    If !Empty(cVMIXQTD) .And. cVMIXQTD <> "0"
		cSql += "      LIMIT " + cVMIXQTD + "')"
	EndIf
    TCQUERY cSql NEW ALIAS qCupom

    If !__lJob

        ConOut("Iniciando contagem dos registros...")
		
        While qCupom->(!Eof())

            nRegTotal++

            qCupom->(DbSkip())
        EndDo

        If !MsgYesNo("Foram encontradas " + AllTrim(Str(nRegTotal)) + " inutilizações sem importação, deseja continuar?")
            MsgInfo("Processo cancelado pelo usuário!")
            qCupom->(DbCloseArea())
            Return Nil
        EndIf

    EndIf

    qCupom->(DbGoTop())

    While qCupom->(!Eof())

        ConOut("Iniciando leitura do documento:") 
        ConOut("Loja...: " + cValToChar(qCupom->(loja)))
        ConOut("Pdv....: " + cValToChar(qCupom->(num_pdv)))
        ConOut("Cupom..: " + cValToChar(qCupom->(evento_cupom)))
        ConOut("Nsu....: " + cValToChar(qCupom->(evento_nsu)))

        __cMsgAdv  := ""
        __cMsgErro := ""
    
        If !__lJob

            nRegAtual++

            ProcRegua(0)	
            IncProc("Importanto registro " + AllTrim(cValToChar(nRegAtual)) + " de " +  AllTrim(cValToChar(nRegTotal)) + "...")
            IncProc(1)	
            IncProc(1)	

        EndIf    

        //Consulta dos dados ca nota
        cSql := "  SELECT * "
        cSql += "    FROM OPENQUERY (" + cVMIXDB + ", "
        cSql += " 'SELECT * "
        cSql += "    FROM " + cVMIXINS + "." + cVMIXCAPA
        cSql += "   WHERE loja         = " + cValToChar(qCupom->(loja))
        cSql += "     AND num_pdv      = " + cValToChar(qCupom->(num_pdv))
        cSql += "     AND evento_cupom = " + cValToChar(qCupom->(evento_cupom))
        cSql += "     AND statusnota in (3) "
        cSql += "     AND tipoemissao = 1 ')"
        TCQUERY cSql NEW ALIAS qNota

        While qNota->(!Eof())   
	        If ValType(qNota->datahoraemissao) == "D"
         	  //	dDataBase := DTOS(qNota->datahoraemissao) 
         	  dDataBase := qNota->datahoraemissao
           	Else
            	dDataBase := StoD(SubString(StrTran(qNota->datahoraemissao,"-",""),1,8))
            EndIf
			//dDataBase   := Stod(SubStr(qNota->datahoraemissao,1,4) + SubStr(qNota->datahoraemissao,6,2) + SubStr(qNota->datahoraemissao,9,2))

	        cSql := "  UPDATE OPENQUERY (" + cVMIXDB + ", "
    	    cSql += " 'SELECT * "
	        cSql += "    FROM " + cVMIXINS + "." + cVMIXTAB                
    	    cSql += "   WHERE loja         = " + cValToChar(qCupom->(loja))
	        cSql += "     AND num_pdv      = " + cValToChar(qCupom->(num_pdv))
    		cSql += "     AND tipo_evento IN (" + cVMIXNTP + ")"
    	    cSql += "     AND evento_cupom = " + cValToChar(qCupom->(evento_cupom))
	        cSql += "     AND evento_nsu   = " + cValToChar(qCupom->(evento_nsu))
	        cSql += "  ') SET flag = 2 "
    	    TCSqlExec(cSql)               

          /*	RecLock("ZV3",.T.)
        	ZV3->ZV3_FILIAL := xFilial("ZV3")
	        ZV3->ZV3_STATUS := "0"
    	    ZV3->ZV3_DTIMPO := dDataBase
	        ZV3->ZV3_HRIMPO := Time()
    	    ZV3->ZV3_LOJA   := qCupom->(loja)
	        ZV3->ZV3_DATA   := qCupom->(data)
    	    ZV3->ZV3_PDV    := qCupom->(num_pdv)
	        ZV3->ZV3_EVECUP := qCupom->(evento_cupom)
    	    ZV3->ZV3_EVENSU := qCupom->(evento_nsu)
    	    zv3->ZV3_ADVERT	:= "Inutilização/Cancelamento"
        	ZV3->(MsUnLock())    */
        	
        	
        	//Gerar inutilização
        	Inutilizar()

	        cSql := "  UPDATE OPENQUERY (" + cVMIXDB + ", "
    	    cSql += " 'SELECT * "
            cSql += "    FROM " + cVMIXINS + "." + cVMIXTAB                
            cSql += "   WHERE loja         = " + cValToChar(qCupom->(loja))
            cSql += "     AND num_pdv      = " + cValToChar(qCupom->(num_pdv))
            cSql += "     AND evento_cupom = " + cValToChar(qCupom->(evento_cupom))
            cSql += "     AND evento_nsu   = " + cValToChar(qCupom->(evento_nsu))
            cSql += "  ') SET flag = 1 "
            TCSqlExec(cSql)                
            
            qNota->(DbSkip())
        EndDo

        qNota->(DbCloseArea())


        qCupom->(DbSkip())

    EndDo

    qCupom->(DbCloseArea())

    If !__lJob
        MsgInfo("Importação das nota inutilizadas/canceladas concluída!")
    EndIf

    Conout("Importação das nota inutilizadas/canceladas concluída!")
	
	dDataBase := xDataBase
Return Nil

//Função para gerar a inutilziação da NFCe
Static Function Inutilizar()
	Local _cCliente := SuperGetMV("MV_INUTCLI", .F., "")//SuperGetMV("MV_CLIPAD", .F., "")
	Local _cLoja	:= SuperGetMV("MV_INUTLOJ", .F., "")//SuperGetMV("MV_LOJAPAD", .F., "")
	Local _cProduto := SuperGetMV("MV_INUTPRO", .F., "")
	Local _cTES     := SuperGetMV("MV_INUTTES", .F., "")
	Local _cEspec   := "NFCE"
	local aAreaSF3	:= SF3->(GetArea())
	
	// Inclui a nota na base pela rotina automática MATA920
	_aCabec := {}
	_aItens := {}
	
	_cDoc 		:= StrZero(qNota->numeronota, Len(SF2->F2_DOC))
	_cSerie  	:= StrZero(qNota->serienota, Len(SF2->F2_SERIE))
	_cNumPDV	:= StrZero(qNota->num_pdv, Len(SF2->F2_PDV))
	
	AADD(_aCabec, {"F2_TIPO"		, "N"		, Nil})     Å
	AADD(_aCabec, {"F2_FORMUL"	, " "		, Nil})
	AADD(_aCabec, {"F2_DOC"		, _cDoc		, Nil})
	AADD(_aCabec, {"F2_SERIE"	, _cSerie	, Nil})
	AADD(_aCabec, {"F2_EMISSAO"	, dDataBase	, Nil})
	AADD(_aCabec, {"F2_CLIENTE"	, _cCliente	, Nil})
	AADD(_aCabec, {"F2_LOJA"	, _cLoja	, Nil})
	AADD(_aCabec, {"F2_ESPECIE"	, "NFCE "	, Nil})
	AADD(_aCabec, {"F2_COND"	, "1"		, Nil})
	AADD(_aCabec, {"F2_PDV"		, _cNumPDV	, Nil})
	AADD(_aCabec, {"F2_DESCONT"	, 0			, Nil})
	AADD(_aCabec, {"F2_FRETE"	, 0			, Nil})
	AADD(_aCabec, {"F2_SEGURO"	, 0			, Nil})
	AADD(_aCabec, {"F2_DESPESA" , 0			, Nil})
	
	_aLinha := {}
	AADD(_aLinha, {"D2_COD"		, _cProduto	, Nil})
	AADD(_aLinha, {"D2_QUANT"	, 1			, Nil})
	AADD(_aLinha, {"D2_PRCVEN"	, 1			, Nil})
	AADD(_aLinha, {"D2_TOTAL"	, 1			, Nil})
	AADD(_aLinha, {"D2_TES"		, _cTES		, Nil})
	AADD(_aItens, _aLinha)

	MATA920(_aCabec, _aItens)
		
	// Exclui a nota na base pela rotina automática MATA920
	MATA920(_aCabec, _aItens, 5)

	aAreaSF3	:= SF3->(GetArea())
	 	
	If SF3->(FieldPos("F3_CODRET")) > 0
		SF3->( dbSetOrder(4) ) //F3_FILIAL+F3_CLIEFOR+F3_LOJA+F3_NFISCAL+F3_SERIE                                                                                                                
		If SF3->( dbSeek( xFilial("SF3")+_cCliente+_cLoja+_cDoc+_cSerie,.F.))
			RecLock("SF3",.F.)
			SF3->F3_CODRET := "T"	// Transmitido
			MsUnlock()
		Endif
	Endif
	
	RestArea( aAreaSF3 )	    
Return