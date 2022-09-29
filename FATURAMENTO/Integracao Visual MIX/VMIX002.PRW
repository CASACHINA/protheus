#Include 'Protheus.ch'
#include "Tbiconn.ch"
#Include "TOPCONN.CH"

/*/{Protheus.doc} VMIX002
Rotina para importar os registros do Visual Mix para o Protheus.
/*/ 
User Function VMIX002(__cEmpresa, __cFilial)

    If !Empty(__cEmpresa) .And. !Empty(__cFilial)

        Execute(__cEmpresa, __cFilial)
    
    Else                                                    

        Processa({|| Execute()}, "Aguarde...", "Iniciando importação das vendas Visual Mix...", .F.)

    EndIf

Return Nil

Static Function Execute(__cEmpresa, __cFilial)

    Local aItem     := {} 
    Local aPgto    := {}
    Local cSql      := ""
    Local qCupom    := ""
    Local qCapa     := ""
    Local qItem     := ""
    Local qFiscal   := ""
    Local qNfce     := ""
    Local qPgto     := ""
    Local qDuplic   := ""
    Local xDataBase := Nil
    Local cVMIXDB   := "" // banco de dados do visual mix
    Local cVMIXINS  := "" // instância do visual mix
    Local cVMIXTAB  := "" // tabela start do visual mix
    Local cVMIXFIL  := "" // filial do visual mix
    Local cVMIXQTD  := "" // qtde de registros para importar por execução
    Local cVMIXNTP  := "" // tipo de evento que nao deve ser importado
    Local cVMIXCTP  := "" // tipo de evento de cancelamento
    Local cVMIXKEY  := "" // chave de pesquisa no caso de cancelamento
    // Local lVMIXVNR  := "" // no caso de cancelamento se deve voltar o número para pesquisar .T. ou .F.

    Local lCapaOk   := .F.
    Local lItemOk   := .F.
    Local lPgtoOk   := .F.
    Local nRegTotal := 0
    Local nRegAtual := 0
    Local lDuplic   := .F.
    Local nItem     := 0
    Local nParcela  := 0
    Local nTotParc  := 0
    Local nVlrParc  := 0
    Local nSubTotal := 0
    Local dDataVenc := StoD("")    
    Local lCancel   := .F.
    Local lContinua := .F.

    Private __aCab      := {}
    Private __aItens    := {}
    Private __aPgtos    := {}
    Private __cMsgAdv   := ""
    Private __cMsgErro  := ""    
    Private __oError    := Nil
    Private __lJob      := .F.
    
    Default __cEmpresa  := ""
    Default __cFilial   := ""

    If !Empty(__cEmpresa) .And. !Empty(__cFilial)

        __lJob := .T.

    	RPCClearEnv()
    	RPCSetType(3)	
    	RPCSetEnv(__cEmpresa,__cFilial,,,"FIN","VMIX002")

    EndIf
    
    xDataBase := dDataBase
    cVMIXDB   := AllTrim(GetNewPar("ZZ_VMIXDB", ""))
    cVMIXTAB  := AllTrim(GetNewPar("ZZ_VMIXTAB", ""))
    cVMIXFIL  := AllTrim(GetNewPar("ZZ_VMIXFIL", ""))
    cVMIXQTD  := AllTrim(GetNewPar("ZZ_VMIXQTD", "10"))
    cVMIXNTP  := AllTrim(GetNewPar("ZZ_VMIXNTP", ""))
    cVMIXCTP  := AllTrim(GetNewPar("ZZ_VMIXCTP", ""))
    cVMIXKEY  := AllTrim(GetNewPar("ZZ_VMIXKEY", ""))
    // lVMIXVNR  := AllTrim(GetNewPar("ZZ_VMIXVNR", .F.))       
    cVMIXRDZ  := AllTrim(GetNewPar("ZZ_VMIXRDZ", "2"))

    cVMIXINS  := SubStr(cVMIXDB, At(".", cVMIXDB) + 1, Len(cVMIXDB))
    cVMIXDB   := SubStr(cVMIXDB, 1, At(".", cVMIXDB) - 1)

    //conout("")
    //conout("=================================================================")         
    //conout("INTEGRACAO VISUAL MIX VERSAO 06-02-2019 INICIADA...")

    If !__lJob

        ProcRegua(0)	
        IncProc("Calculando quantidade de registros...")
        IncProc(1)	
        IncProc(1)	

    EndIf        
        
    If Empty(cVMIXDB)
        If __lJob
            //conout("Impossível iniciar a integração com o Visual Mix, favor preecher o Parâmetro ZZ_VMIXDB com o caminho do banco de dados do Visual Mix!")
        Else
            MsgStop("Impossível iniciar a integração com o Visual Mix, favor preecher o Parâmetro ZZ_VMIXDB com o caminho do banco de dados do Visual Mix!")
        EndIf
        Return Nil
    EndIf

    If Empty(cVMIXTAB)
        If __lJob
            //conout("Impossível iniciar a integração com o Visual Mix, favor preecher o Parâmetro ZZ_VMIXTAB com a tabela de consulta do Visual Mix!")
        Else
            MsgStop("Impossível iniciar a integração com o Visual Mix, favor preecher o Parâmetro ZZ_VMIXTAB com a tabela de consulta do Visual Mix!")
        EndIf
        Return Nil
    EndIf

    If Empty(cVMIXFIL)
        If __lJob
            //conout("Impossível iniciar a integração com o Visual Mix, favor preecher o Parâmetro ZZ_VMIXFIL com a filial do Visual Mix!")
        Else
            MsgStop("Impossível iniciar a integração com o Visual Mix, favor preecher o Parâmetro ZZ_VMIXFIL com a filial do Visual Mix!")        
        EndIf
        Return Nil
    EndIf

    If Empty(cVMIXNTP)
        If __lJob
            //conout("Impossível iniciar a integração com o Visual Mix, favor preecher o Parâmetro ZZ_VMIXNTP com o(s) tipos de evento que nao serão importados!")
        Else
            MsgStop("Impossível iniciar a integração com o Visual Mix, favor preecher o Parâmetro ZZ_VMIXNTP com o(s) tipos de evento que nao serão importados!")
        EndIf
        Return Nil
    EndIf

    If Empty(cVMIXCTP)
        If __lJob
            //conout("Impossível iniciar a integração com o Visual Mix, favor preecher o Parâmetro ZZ_VMIXCTP com o(s) tipos de evento de cancelamento!")
        Else
            MsgStop("Impossível iniciar a integração com o Visual Mix, favor preecher o Parâmetro ZZ_VMIXCTP com o(s) tipos de evento de cancelamento!")
        EndIf
        Return Nil
    EndIf

    If Empty(cVMIXKEY)
        If __lJob
            //conout("Impossível iniciar a integração com o Visual Mix, favor preecher o Parâmetro ZZ_VMIXKEY com a chave de pesquisa do cancelamento!")
        Else
            MsgStop("Impossível iniciar a integração com o Visual Mix, favor preecher o Parâmetro ZZ_VMIXKEY com a chave de pesquisa do cancelamento!")
        EndIf
        Return Nil
    EndIf

    // If Empty(lVMIXVNR)
    //     If __lJob
    //         //conout("Impossível iniciar a integração com o Visual Mix, favor preecher o Parâmetro ZZ_VMIXVNR com .T. ou .F., caso verdadeiro pesquisa o número anteriror do documento para cancelamento!")
    //     Else
    //         MsgStop("Impossível iniciar a integração com o Visual Mix, favor preecher o Parâmetro ZZ_VMIXVNR com .T. ou .F., caso verdadeiro pesquisa o número anteriror do documento para cancelamento!")
    //     EndIf
    //     Return Nil
    // EndIf

    //Consulta cupons nao importados    

    cSql := "     SELECT * "
    cSql += "       FROM OPENQUERY (" + cVMIXDB + ", "
    cSql += "    'SELECT * "
    cSql += "       FROM " + cVMIXINS + "." + cVMIXTAB
    cSql += "      WHERE loja = " + cVMIXFIL
    cSql += "        AND tipo_evento NOT IN (" + cVMIXNTP + ")"
    cSql += "        AND flag = 0 "
    cSql += "   ORDER BY data_alteracao "
    cSql += "      LIMIT " + cVMIXQTD + "')"

    TCQUERY cSql NEW ALIAS qCupom

    If !__lJob

        //conout("Iniciando contagem dos registros...")

        While qCupom->(!Eof())

            nRegTotal++

            qCupom->(DbSkip())

        EndDo

        If !MsgYesNo("Foram encontradas " + AllTrim(cValToChar(nRegTotal)) + " vendas sem importação, deseja continuar?")
            MsgInfo("Processo cancelado pelo usuário!")
            qCupom->(DbCloseArea())
            Return Nil
        EndIf

    EndIf

    qCupom->(DbGoTop())

    While qCupom->(!Eof())

        //conout("=================================================================")         
        //conout("Iniciando leitura do documento:") 
        //conout("Loja...: " + cValToChar(qCupom->(loja)))
        If ValType(qCupom->(data)) == "D"
            //conout("Data...: " + SubStr(DtoS(qCupom->(data)),1,4) + "-" + SubStr(DtoS(qCupom->(data)),5,2) + "-" + SubStr(DtoS(qCupom->(data)),7,2) + " 00:00:00.0000000")
        Else
            //conout("Data...: " + qCupom->(data))
        EndIf
        //conout("Pdv....: " + cValToChar(qCupom->(num_pdv)))
        //conout("Cupom..: " + cValToChar(qCupom->(evento_cupom)))
        //conout("Nsu....: " + cValToChar(qCupom->(evento_nsu)))
        //conout("Tipo...: " + cValToChar(qCupom->(tipo_evento)))

        __cMsgAdv  := ""
        __cMsgErro := ""
    
        If !__lJob

            nRegAtual++

            ProcRegua(0)	
            IncProc("Importanto registro " + AllTrim(cValToChar(nRegAtual)) + " de " +  AllTrim(cValToChar(nRegTotal)) + "...")
            IncProc(1)	
            IncProc(1)	

        EndIf    

        cSql := "  SELECT * "
        cSql += "    FROM OPENQUERY (" + cVMIXDB + ", "
        cSql += " 'SELECT * "
        cSql += "    FROM " + cVMIXINS + "." + cVMIXTAB        
        cSql += "   WHERE loja         = " + cValToChar(qCupom->(loja))
        If ValType(qCupom->(data)) == "D"
            cSql += "     AND data         = ''" + SubStr(DtoS(qCupom->(data)),1,4) + "-" + SubStr(DtoS(qCupom->(data)),5,2) + "-" + SubStr(DtoS(qCupom->(data)),7,2) + " 00:00:00.0000000" + "''"
        Else
            cSql += "     AND data         = ''" + qCupom->(data) + "''"
        EndIf
        cSql += "     AND num_pdv      = " + cValToChar(qCupom->(num_pdv))
        cSql += "     AND evento_cupom = " + cValToChar(qCupom->(evento_cupom))
        cSql += "     AND evento_nsu   = " + cValToChar(qCupom->(evento_nsu))
        cSql += "     AND tipo_evento  = " + cValToChar(qCupom->(tipo_evento))
        cSql += "     AND flag <> 0')"

        TCQUERY cSql NEW ALIAS qDuplic    

        lDuplic := .F.    

        While qDuplic->(!Eof())

            lDuplic := .T.
            //conout("-----------------------------------------------------------------")         
            //conout("ATENCAO")         
            //conout("Este documento ja foi importado, pulando para o proximo registro!")
            //conout("=================================================================")         
            qDuplic->(DbSkip())

        EndDo

        qDuplic->(DbCloseArea())

        If lDuplic

            qCupom->(DbSkip())
            Loop

        EndIf
    
        cSql := "  UPDATE OPENQUERY (" + cVMIXDB + ", "
        cSql += " 'SELECT * "
        cSql += "    FROM " + cVMIXINS + "." + cVMIXTAB                
        cSql += "   WHERE loja         = " + cValToChar(qCupom->(loja))
        If ValType(qCupom->(data)) == "D"
            cSql += "     AND data         = ''" + SubStr(DtoS(qCupom->(data)),1,4) + "-" + SubStr(DtoS(qCupom->(data)),5,2) + "-" + SubStr(DtoS(qCupom->(data)),7,2) + " 00:00:00.0000000" + "''"        
        Else
            cSql += "     AND data         = ''" + qCupom->(data) + "''"        
        EndIf
        cSql += "     AND num_pdv      = " + cValToChar(qCupom->(num_pdv))
        cSql += "     AND evento_cupom = " + cValToChar(qCupom->(evento_cupom))
        cSql += "     AND evento_nsu   = " + cValToChar(qCupom->(evento_nsu))
        cSql += "     AND tipo_evento  = " + cValToChar(qCupom->(tipo_evento))        
        cSql += "  ') SET flag = 2 "

        TCSqlExec(cSql)               

        lCapaOk   := .F.
        lItemOk   := .F.
        lPgtoOk   := .F.         

        /*RecLock("ZV3",.T.)
        ZV3->ZV3_FILIAL := xFilial("ZV3")
        ZV3->ZV3_STATUS := "0"
        ZV3->ZV3_DTIMPO := dDataBase
        ZV3->ZV3_HRIMPO := Time()
        ZV3->ZV3_LOJA   := qCupom->(loja)
        If ValType(qCupom->(data)) == "D"
            ZV3->ZV3_DATA   := SubStr(DtoS(qCupom->(data)),1,4) + "-" + SubStr(DtoS(qCupom->(data)),5,2) + "-" + SubStr(DtoS(qCupom->(data)),7,2) + " 00:00:00.0000000"
        Else
            ZV3->ZV3_DATA   := qCupom->(data)
        EndIf
        ZV3->ZV3_PDV    := qCupom->(num_pdv)
        ZV3->ZV3_EVECUP := qCupom->(evento_cupom)
        ZV3->ZV3_EVENSU := qCupom->(evento_nsu)
        ZV3->(MsUnLock())
         */
        // Verifica se o evento é do tipo redução Z

        If cValToChar(qCupom->(tipo_evento)) $ AllTrim(cVMIXRDZ)

            // Consulta tabela vw_total_dia

            cSql := "  SELECT * "
            cSql += "    FROM OPENQUERY (" + cVMIXDB + ", "
            cSql += " 'SELECT * "
            cSql += "    FROM " + cVMIXINS + ".vw_total_dia"   
            cSql += "   WHERE loja         = " + cValToChar(qCupom->(loja))
            If ValType(qCupom->(data)) == "D"
                cSql += "     AND data         = ''" + SubStr(DtoS(qCupom->(data)),1,4) + "-" + SubStr(DtoS(qCupom->(data)),5,2) + "-" + SubStr(DtoS(qCupom->(data)),7,2) + " 00:00:00.0000000" + "''"
            Else
                cSql += "     AND data         = ''" + qCupom->(data) + "''"
            EndIf
            cSql += "     AND num_pdv      = " + cValToChar(qCupom->(num_pdv))
            cSql += "     AND evento_cupom = " + cValToChar(qCupom->(evento_cupom))
            cSql += "     AND evento_nsu   = " + cValToChar(qCupom->(evento_nsu))
            cSql += " ')"
        
            TCQUERY cSql NEW ALIAS qTotalDia
                   
            While qTotalDia->(!Eof())

                RecLock("SFI", .T.)
                SFI->FI_FILIAL  := xFilial("SFI")
                If ValType(qCupom->(data)) == "D"
                    SFI->FI_DTMOVTO := qCupom->(data)
                Else
                    SFI->FI_DTMOVTO := StoD(SubStr(StrTran(qTotalDia->(data),"-",""),1,8))
                EndIf                
                SFI->FI_SERPDV  := U_DEPARA(xFilial("SF1") + PADL(cValToChar(qTotalDia->num_pdv),3,"0"), "SERIE", 2)
                // SFI->FI_NUMERO  := GETSXENUM("SFI","FI_NUMERO",cFilAnt+"SFI"+cValToChar(qTotalDia->num_pdv))    PADL(%num_cupom%,9,"0")                                                                                                                                                                                                                                   
                SFI->FI_NUMERO  := PADL(cValToChar(qTotalDia->num_reducao),6,"0") 
                SFI->FI_PDV     := PADL(cValToChar(qTotalDia->num_pdv),3,"0")
                SFI->FI_NUMREDZ := PADL(cValToChar(qTotalDia->num_reducao),5,"0")
                SFI->FI_GTINI   := qTotalDia->gt_inicial
                SFI->FI_GTFINAL := qTotalDia->gt_final
                SFI->FI_NUMINI  := PADL(cValToChar(qTotalDia->cupom_inicial),9,"0")
                SFI->FI_NUMFIM  := PADL(cValToChar(qTotalDia->cupom_final),9,"0")
                SFI->FI_CANCEL  := qTotalDia->cancelamentos
                SFI->FI_VALCON  := qTotalDia->venda_bruta - qTotalDia->cancelamentos - qTotalDia->descontos
                SFI->FI_DESC    := qTotalDia->descontos
                SFI->FI_COO     := PADL(cValToChar(qTotalDia->evento_cupom),9,"0")
                SFI->FI_CRO     := PADL(cValToChar(qTotalDia->cro),3,"0")
               // SFI->FI_DTREDZ  := StoD(SubString(StrTran(qTotalDia->(data),"-",""),1,8))  
               	If ValType(qCupom->(data)) == "D"
                    SFI->FI_DTREDZ := qCupom->(data)
                Else
                    SFI->FI_DTREDZ := StoD(SubStr(StrTran(qTotalDia->(data),"-",""),1,8))
                EndIf        
                SFI->FI_SITUA   := "RX"                

                // Consulta tabela vw_total_dia

                cSql := "  SELECT * "
                cSql += "    FROM OPENQUERY (" + cVMIXDB + ", "
                cSql += " 'SELECT * "
                cSql += "    FROM " + cVMIXINS + ".vw_imposto_dia"   
                cSql += "   WHERE loja         = " + cValToChar(qTotalDia->(loja))
                If ValType(qTotalDia->(data)) == "D"
                    cSql += "     AND data         = ''" + SubStr(DtoS(qTotalDia->(data)),1,4) + "-" + SubStr(DtoS(qTotalDia->(data)),5,2) + "-" + SubStr(DtoS(qTotalDia->(data)),7,2) + " 00:00:00.0000000" + "''"
                Else
                    cSql += "     AND data         = ''" + qTotalDia->(data) + "''"
                EndIf
                cSql += "     AND num_pdv      = " + cValToChar(qTotalDia->(num_pdv))
                cSql += "     AND evento_cupom = " + cValToChar(qTotalDia->(evento_cupom))
                cSql += "     AND evento_nsu   = " + cValToChar(qTotalDia->(evento_nsu))
                cSql += " ')"                
            
                TCQUERY cSql NEW ALIAS qImpostoDia

                While qImpostoDia->(!Eof())

                    SFI->FI_SUBTRIB := If(AllTrim(qImpostoDia->tributacao) == "F1", qImpostoDia->base_calculo, SFI->FI_SUBTRIB)
                    SFI->FI_ISENTO  := If(AllTrim(qImpostoDia->tributacao) == "I1", qImpostoDia->base_calculo, SFI->FI_ISENTO)
                    SFI->FI_NTRIB   := If(AllTrim(qImpostoDia->tributacao) == "N1", qImpostoDia->base_calculo, SFI->FI_NTRIB)
                    //SFI->FI_IMPDEBT := If("T" $ AllTrim(qImpostoDia->tributacao),   qImpostoDia->base_calculo * 1.7, SFI->FI_IMPDEBT)
                    //SFI->FI_HRREDZ  := ""
                    //SFI->FI_COD17   := If("T" $ AllTrim(qImpostoDia->tributacao),   "T1700", SFI->FI_COD17)
                    //SFI->FI_BAS17   := If("T" $ AllTrim(qImpostoDia->tributacao),   qImpostoDia->base_calculo, SFI->FI_BAS17)
                    
                    SFI->FI_IMPDEBT := If("T" $ AllTrim(qImpostoDia->tributacao) .and. qImpostoDia->aliquota = 17 ,qImpostoDia->base_calculo * 0.17, SFI->FI_IMPDEBT)
                    SFI->FI_COD17   := If("T" $ AllTrim(qImpostoDia->tributacao) .and. qImpostoDia->aliquota = 17  ,"T1700", SFI->FI_COD17)
                    SFI->FI_BAS17   := If("T" $ AllTrim(qImpostoDia->tributacao) .and. qImpostoDia->aliquota = 17 ,qImpostoDia->base_calculo, SFI->FI_BAS17)
                    SFI->FI_IMPDEBT := If("T" $ AllTrim(qImpostoDia->tributacao) .and. qImpostoDia->aliquota = 25 ,qImpostoDia->base_calculo * 0.25, SFI->FI_IMPDEBT)
                    SFI->FI_COD25   := If("T" $ AllTrim(qImpostoDia->tributacao) .and. qImpostoDia->aliquota = 25  ,"T2500", SFI->FI_COD25)
                    SFI->FI_BAS25   := If("T" $ AllTrim(qImpostoDia->tributacao) .and. qImpostoDia->aliquota = 25 , qImpostoDia->base_calculo, SFI->FI_BAS25)
 
                    qImpostoDia->(DbSkip())

                EndDo

                qImpostoDia->(DbCloseArea())

                SFI->(MsUnLock())

                qTotalDia->(DbSkip())

            EndDo

            qTotalDia->(DbCloseArea())
           /*
            RecLock("ZV3",.F.)
            ZV3->ZV3_STATUS := "1"
            ZV3->(MsUnLock()) 
            */               

            cSql := "  UPDATE OPENQUERY (" + cVMIXDB + ", "
            cSql += " 'SELECT * "
            cSql += "    FROM " + cVMIXINS + "." + cVMIXTAB                
            cSql += "   WHERE loja         = " + cValToChar(qCupom->(loja))
            If ValType(qCupom->(data)) == "D"
                cSql += "     AND data         = ''" + SubStr(DtoS(qCupom->(data)),1,4) + "-" + SubStr(DtoS(qCupom->(data)),5,2) + "-" + SubStr(DtoS(qCupom->(data)),7,2) + " 00:00:00.0000000" + "''"        
            Else
                cSql += "     AND data         = ''" + qCupom->(data) + "''"        
            EndIf
            cSql += "     AND num_pdv      = " + cValToChar(qCupom->(num_pdv))
            cSql += "     AND evento_cupom = " + cValToChar(qCupom->(evento_cupom))
            cSql += "     AND evento_nsu   = " + cValToChar(qCupom->(evento_nsu))
            cSql += "     AND tipo_evento  = " + cValToChar(qCupom->(tipo_evento))
            cSql += "  ') SET flag = 1 "

            TCSqlExec(cSql)              

            //conout("-----------------------------------------------------------------")         
            //conout("Reducao Z concluida com sucesso!")
            //conout("=================================================================")                                       

        Else

            // Consutla tabela Nfce

            cSql := "  SELECT * "
            cSql += "    FROM OPENQUERY (" + cVMIXDB + ", "
            cSql += " 'SELECT * "
            cSql += "    FROM " + cVMIXINS + ".vw_nfce_capa"   
            cSql += "   WHERE loja         = " + cValToChar(qCupom->(loja))
            If ValType(qCupom->(data)) == "D"
                cSql += "     AND data         = ''" + SubStr(DtoS(qCupom->(data)),1,4) + "-" + SubStr(DtoS(qCupom->(data)),5,2) + "-" + SubStr(DtoS(qCupom->(data)),7,2) + " 00:00:00.0000000" + "''"
            Else
                cSql += "     AND data         = ''" + qCupom->(data) + "''"
            EndIf
            cSql += "     AND num_pdv      = " + cValToChar(qCupom->(num_pdv))
            cSql += "     AND evento_cupom = " + cValToChar(qCupom->(evento_cupom))
            cSql += "     AND evento_nsu   = " + cValToChar(qCupom->(evento_nsu))
            cSql += "     AND statusnota  IN (1,4)')"
        
            TCQUERY cSql NEW ALIAS qNfce            
                
            If cValToChar(qCupom->(tipo_evento)) $ AllTrim(cVMIXCTP)

                //conout("Evento de cancelamento!")

                // Caso seja cancelamento

                // Consulta o último cupom emitido para cancelamento
                // Cupom fiscal

                cSql := "   SELECT evento_cupom "
                cSql += "     FROM OPENQUERY (" + cVMIXDB + ", "
                cSql += "  'SELECT MAX(evento_cupom) evento_cupom "
                cSql += "     FROM " + cVMIXINS + "." + cVMIXTAB
                cSql += "    WHERE loja          = " + cValToChar(qCupom->(loja))
                cSql += "      AND num_pdv       = " + cValToChar(qCupom->(num_pdv))
                cSql += "      AND evento_cupom <= " + cValToChar(qCupom->(evento_cupom))
                cSql += "      AND tipo_evento NOT IN (" + AllTrim(cVMIXNTP) + ")"
                cSql += "      AND tipo_evento NOT IN (" + AllTrim(cVMIXCTP) + ")"
                cSql += " ')"

                TCQUERY cSql NEW ALIAS qCancel
                
                lCancel := .T.
                
                SL1->(DbSetOrder(2))

                If (SL1->(DbSeek(xFilial("SL1") + &(cVMIXKEY))))

                    If "OK" $ UPPER(SL1->L1_SITUA)

                        If "qNfce" $ cVMIXKEY

                            RecLock("SL1")
                            SL1->L1_SITUA   := 'X2'
                            SL1->L1_HORCANC := TIME()
                            SL1->L1_DOCCANC := PADL(qNfce->(numeronota),9,"0")
                            If ValType(qCupom->(data)) == "D"
                                SL1->L1_DATCANC := DTOS(qNfce->(data))
                            Else
                                SL1->L1_DATCANC := StoD(SubString(StrTran(qNfce->(data),"-",""),1,8))
                            EndIf
                            SL1->(MsUnLock())
                        
                        Else

                            RecLock("SL1")
                            SL1->L1_SITUA   := 'X2'
                            SL1->(MsUnLock())                    

                        EndIf

                        // RecLock("ZV3",.F.)
                        // ZV3->ZV3_STATUS := "1"
                        // ZV3->ZV3_L1CUP  := SL1->L1_NUM
                        // ZV3->(MsUnLock())                

                        cSql := "  UPDATE OPENQUERY (" + cVMIXDB + ", "
                        cSql += " 'SELECT * "
                        cSql += "    FROM " + cVMIXINS + "." + cVMIXTAB                
                        cSql += "   WHERE loja         = " + cValToChar(qCupom->(loja))
                        If ValType(qCupom->(data)) == "D"
                            cSql += "     AND data         = ''" + SubStr(DtoS(qCupom->(data)),1,4) + "-" + SubStr(DtoS(qCupom->(data)),5,2) + "-" + SubStr(DtoS(qCupom->(data)),7,2) + " 00:00:00.0000000" + "''"        
                        Else
                            cSql += "     AND data         = ''" + qCupom->(data) + "''"        
                        EndIf
                        cSql += "     AND num_pdv      = " + cValToChar(qCupom->(num_pdv))
                        cSql += "     AND evento_cupom = " + cValToChar(qCupom->(evento_cupom))
                        cSql += "     AND evento_nsu   = " + cValToChar(qCupom->(evento_nsu))
                        cSql += "     AND tipo_evento  = " + cValToChar(qCupom->(tipo_evento))
                        cSql += "  ') SET flag = 1 "

                        TCSqlExec(cSql)              

                        //conout("-----------------------------------------------------------------")         
                        //conout("Documento cancelado com sucesso!")
                        //conout("=================================================================")                           

                    Else

                        cSql := "  UPDATE OPENQUERY (" + cVMIXDB + ", "
                        cSql += " 'SELECT * "
                        cSql += "    FROM " + cVMIXINS + "." + cVMIXTAB                
                        cSql += "   WHERE loja         = " + cValToChar(qCupom->(loja))
                        If ValType(qCupom->(data)) == "D"
                            cSql += "     AND data         = ''" + SubStr(DtoS(qCupom->(data)),1,4) + "-" + SubStr(DtoS(qCupom->(data)),5,2) + "-" + SubStr(DtoS(qCupom->(data)),7,2) + " 00:00:00.0000000" + "''"        
                        Else
                            cSql += "     AND data         = ''" + qCupom->(data) + "''"        
                        EndIf
                        cSql += "     AND num_pdv      = " + cValToChar(qCupom->(num_pdv))
                        cSql += "     AND evento_cupom = " + cValToChar(qCupom->(evento_cupom))
                        cSql += "     AND evento_nsu   = " + cValToChar(qCupom->(evento_nsu))
                        cSql += "     AND tipo_evento  = " + cValToChar(qCupom->(tipo_evento))
                        cSql += "  ') SET flag = 0 "

                        TCSqlExec(cSql)              

                        //conout("-----------------------------------------------------------------")         
                        //conout("ATENCAO")                         
                        //conout("Documento ainda nao processado nao pode ser cancelado!")
                        //conout("=================================================================")                           

                    EndIf

                Else
                    /*
                    RecLock("ZV3",.F.)
                    ZV3->ZV3_STATUS := "3"
                    ZV3->ZV3_L1CUP  := SL1->L1_NUM                
                    ZV3->ZV3_ERROR  := "Documento para cancelamento nao foi encontrado!"
                    ZV3->(MsUnLock())                
                      */
                    //conout("-----------------------------------------------------------------")         
                    //conout("ATENCAO")                         
                    //conout("Documento para cancelamento nao foi encontrado!")         
                    //conout("=================================================================")         

                    cSql := "  UPDATE OPENQUERY (" + cVMIXDB + ", "
                    cSql += " 'SELECT * "
                    cSql += "    FROM " + cVMIXINS + "." + cVMIXTAB                
                    cSql += "   WHERE loja         = " + cValToChar(qCupom->(loja))
                    If ValType(qCupom->(data)) == "D"
                        cSql += "     AND data         = ''" + SubStr(DtoS(qCupom->(data)),1,4) + "-" + SubStr(DtoS(qCupom->(data)),5,2) + "-" + SubStr(DtoS(qCupom->(data)),7,2) + " 00:00:00.0000000" + "''"        
                    Else
                        cSql += "     AND data         = ''" + qCupom->(data) + "''"        
                    EndIf
                    cSql += "     AND num_pdv      = " + cValToChar(qCupom->(num_pdv))
                    cSql += "     AND evento_cupom = " + cValToChar(qCupom->(evento_cupom))
                    cSql += "     AND evento_nsu   = " + cValToChar(qCupom->(evento_nsu))
                    cSql += "     AND tipo_evento  = " + cValToChar(qCupom->(tipo_evento))                
                    cSql += "  ') SET flag = 3 "

                    TCSqlExec(cSql)                
                
                EndIf   

                qCancel->(DbCloseArea())         

            Else

                cSql := "  SELECT * "
                cSql += "    FROM OPENQUERY (" + cVMIXDB + ", "
                cSql += " 'SELECT * "
                cSql += "    FROM " + cVMIXINS + ".vw_total_cupom"   
                cSql += "   WHERE loja         = " + cValToChar(qCupom->(loja))
                If ValType(qCupom->(data)) == "D"
                    cSql += "     AND data         = ''" + SubStr(DtoS(qCupom->(data)),1,4) + "-" + SubStr(DtoS(qCupom->(data)),5,2) + "-" + SubStr(DtoS(qCupom->(data)),7,2) + " 00:00:00.0000000" + "''"
                Else
                    cSql += "     AND data         = ''" + qCupom->(data) + "''"
                EndIf
                cSql += "     AND num_pdv      = " + cValToChar(qCupom->(num_pdv))
                cSql += "     AND evento_cupom = " + cValToChar(qCupom->(evento_cupom))
                cSql += "     AND evento_nsu   = " + cValToChar(qCupom->(evento_nsu)) + "')"
                            
                TCQUERY cSql NEW ALIAS qCapa

                While qCapa->(!Eof())

                    qNfce->(DbGoTop())

                    __cMsgAdv := ""

                    lCapaOk := .T.
                     /*
                    RecLock("ZV3",.F.)
                    ZV3->ZV3_NUMCUP := qCapa->(num_cupom)
                    ZV3->(MsUnLock())
                     */
                    If "qNfce" $ cVMIXKEY

                        While qNfce->(!Eof())

                            lCancel := .F.
                        
                            __aCab := GetValue("qCapa", "SL1")

                            //Consulta itens cupons nao importados

                            cSql := "    SELECT * "
                            cSql += "      FROM OPENQUERY (" + cVMIXDB + ", "
                            cSql += "   'SELECT * "
                            cSql += "      FROM " + cVMIXINS + ".vw_item_venda"   
                            cSql += "     WHERE loja         = " + cValToChar(qCupom->(loja))
                            If ValType(qCupom->(data)) == "D"
                                cSql += "       AND data         = ''" + SubStr(DtoS(qCupom->(data)),1,4) + "-" + SubStr(DtoS(qCupom->(data)),5,2) + "-" + SubStr(DtoS(qCupom->(data)),7,2) + " 00:00:00.0000000" + "''"
                            Else
                                cSql += "       AND data         = ''" + qCupom->(data) + "''"
                            EndIf
                            cSql += "       AND num_pdv      = " + cValToChar(qCupom->(num_pdv))
                            cSql += "       AND evento_cupom = " + cValToChar(qCupom->(evento_cupom))
                            cSql += "       AND evento_nsu   = " + cValToChar(qCupom->(evento_nsu))       
                            cSql += "       AND cancelado   <> 1 "
                            cSql += "  ORDER BY loja, data, num_pdv, evento_cupom, evento_nsu, sequencial')"
                                        
                            TCQUERY cSql NEW ALIAS qItem

                            __aItens := {}

                            While qItem->(!Eof())

                                cSql := "    SELECT * "
                                cSql += "      FROM OPENQUERY (" + cVMIXDB + ", "
                                cSql += "   'SELECT * "
                                cSql += "      FROM " + cVMIXINS + ".vw_embalagem_loja"   
                                cSql += "     WHERE loja       = " + cValToChar(qItem->(loja))
                                cSql += "       AND produto_id = " + cValToChar(qItem->(cod_interno)) + "')"
                                
                                TCQUERY cSql NEW ALIAS qFiscal        

                                lItemOk := .T.

                                aItem := GetValue("qItem", "SL2")

                                aAdd(__aItens, aItem)

                                qFiscal->(DbCloseArea())

                                qItem->(DbSkip())

                            EndDo

                            qItem->(DbCloseArea())

                            //Consulta itens cupons nao importados

                            //---------------------------------------------
                            // Pagamento igual a dinheiro
                            //---------------------------------------------

                            cSql := "   SELECT loja, data, num_pdv, evento_cupom, evento_nsu, cod_finaliz, num_cupom, data_vencimento, cpf, cmc7, tipo_tef, sum(valor) valor, "
                            cSql += "          tipo_tef, cod_rede, cod_bandeira, cod_autorizacao, cod_sitef, bin, parcelas, dominio, nsu_host, nsu_pos "
                            cSql += "     FROM OPENQUERY (" + cVMIXDB + ", "
                            cSql += "  'SELECT * "
                            cSql += "     FROM " + cVMIXINS + ".vw_finalizadora_det"   
                            cSql += "    WHERE loja         = " + cValToChar(qCupom->(loja))
                            If ValType(qCupom->(data)) == "D"
                                cSql += "      AND data         = ''" + SubStr(DtoS(qCupom->(data)),1,4) + "-" + SubStr(DtoS(qCupom->(data)),5,2) + "-" + SubStr(DtoS(qCupom->(data)),7,2) + " 00:00:00.0000000" + "''"
                            Else
                                cSql += "      AND data         = ''" + qCupom->(data) + "''"
                            EndIf
                            cSql += "      AND num_pdv      = " + cValToChar(qCupom->(num_pdv))
                            cSql += "      AND evento_cupom = " + cValToChar(qCupom->(evento_cupom))
                            cSql += "      AND evento_nsu   = " + cValToChar(qCupom->(evento_nsu))                        
                            cSql += "      AND cod_finaliz  = 6 "
                            cSql += " ORDER BY loja, data, num_pdv, evento_cupom, evento_nsu')"
                            cSql += " GROUP BY loja, data, num_pdv, evento_cupom, evento_nsu, cod_finaliz, num_cupom, data_vencimento, cpf, cmc7, tipo_tef, "
                            cSql += "          tipo_tef, cod_rede, cod_bandeira, cod_autorizacao, cod_sitef, bin, parcelas, dominio, nsu_host, nsu_pos "
                                        
                            TCQUERY cSql NEW ALIAS qPgto

                            __aPgtos := {}

                            While qPgto->(!Eof())

                                aPgto := GetValue("qPgto", "SL4")

                                aAdd(__aPgtos, aPgto)

                                qPgto->(DbSkip())

                            EndDo

                            qPgto->(DbCloseArea())

                            //---------------------------------------------
                            // Pagamentos diferentes de dinheiro
                            //---------------------------------------------

                            cSql := "   SELECT * "
                            cSql += "     FROM OPENQUERY (" + cVMIXDB + ", "
                            cSql += "  'SELECT * "
                            cSql += "     FROM " + cVMIXINS + ".vw_finalizadora_det"   
                            cSql += "    WHERE loja         = " + cValToChar(qCupom->(loja))
                            If ValType(qCupom->(data)) == "D"
                                cSql += "      AND data         = ''" + SubStr(DtoS(qCupom->(data)),1,4) + "-" + SubStr(DtoS(qCupom->(data)),5,2) + "-" + SubStr(DtoS(qCupom->(data)),7,2) + " 00:00:00.0000000" + "''"
                            Else
                                cSql += "      AND data         = ''" + qCupom->(data) + "''"
                            EndIf
                            cSql += "      AND num_pdv      = " + cValToChar(qCupom->(num_pdv))
                            cSql += "      AND evento_cupom = " + cValToChar(qCupom->(evento_cupom))
                            cSql += "      AND evento_nsu   = " + cValToChar(qCupom->(evento_nsu))                        
                            cSql += "      AND cod_finaliz <> 6 "
                            cSql += " ORDER BY loja, data, num_pdv, evento_cupom, evento_nsu, sequencial')"
                                        
                            TCQUERY cSql NEW ALIAS qPgto

                            While qPgto->(!Eof())

                                aPgto := GetValue("qPgto", "SL4")

                                lPgtoOk   := .T.
                                dDataVenc := aPgto[aScan(aPgto, {|X| AllTrim(X[1]) == "L4_DATA"}), 2]
                                nTotParc  := qPgto->(parcelas)
                                nTotParc  := If(nTotParc == 0, 1, nTotParc)
                                nSubTotal := 0

                                For nParcela := 1 to nTotParc

                                    If AllTrim(Posicione("SAE", 1, xFilial("SAE") + aPgto[aScan(aPgto, {|X| AllTrim(X[1]) == "L4_ADMINIS"}), 2], "AE_TIPO")) == "CC"

                                        dDataVenc += 30

                                    ElseIf AllTrim(Posicione("SAE", 1, xFilial("SAE") + aPgto[aScan(aPgto, {|X| AllTrim(X[1]) == "L4_ADMINIS"}), 2], "AE_TIPO")) == "CD"

                                        dDataVenc += 1

                                    EndIf                

                                    aPgto := GetValue("qPgto", "SL4")
                    
                                    If nParcela == nTotParc

                                        aPgto[aScan(aPgto, {|X| AllTrim(X[1]) == "L4_VALOR"}), 2] := NoRound(aPgto[aScan(aPgto, {|X| AllTrim(X[1]) == "L4_VALOR"}), 2] - nSubTotal, 2)

                                    Else

                                        aPgto[aScan(aPgto, {|X| AllTrim(X[1]) == "L4_VALOR"}), 2] := NoRound(aPgto[aScan(aPgto, {|X| AllTrim(X[1]) == "L4_VALOR"}), 2] / nTotParc, 2)

                                    EndIf

                                    nSubTotal += aPgto[aScan(aPgto, {|X| AllTrim(X[1]) == "L4_VALOR"}), 2]

                                    aPgto[aScan(aPgto, {|X| AllTrim(X[1]) == "L4_DATA"}), 2] := dDataVenc

                                    aAdd(__aPgtos, aPgto)

                                Next

                                qPgto->(DbSkip())

                            EndDo

                            qPgto->(DbCloseArea())

                            If Len(__aCab) > 0 .And. Len(__aItens) > 0 .And. Len(__aPgtos) > 0

                                BEGIN TRANSACTION

                                    lItemOk := Save("SL2", __aItens)                
                                    lPgtoOk := Save("SL4", __aPgtos)                
                                    lCapaOk := Save("SL1", __aCab)                

                                    If lCapaOk .And. lItemOk .And. lPgtoOk

                                        CONFIRMSX8()

                                    Else

                                        ROLLBAKCSX8()

                                        DISARMTRANSACTION()
                                        
                                    EndIf

                                END TRANSACTION

                                If lCapaOk .And. lItemOk .And. lPgtoOk

                                    If Empty(__cMsgAdv)
                                        cStatus := "1"
                                    Else
                                        cStatus := "2"
                                    EndIf
                                   /*
                                    RecLock("ZV3",.F.)
                                    ZV3->ZV3_STATUS := cStatus
                                    ZV3->ZV3_L1CUP  := SL1->L1_NUM
                                    ZV3->ZV3_ADVERT := __cMsgAdv
                                    ZV3->(MsUnLock())                
                                     */
                                    cSql := "  UPDATE OPENQUERY (" + cVMIXDB + ", "
                                    cSql += " 'SELECT * "
                                    cSql += "    FROM " + cVMIXINS + "." + cVMIXTAB                
                                    cSql += "   WHERE loja         = " + cValToChar(qCupom->(loja))
                                    If ValType(qCupom->(data)) == "D"
                                        cSql += "     AND data         = ''" + SubStr(DtoS(qCupom->(data)),1,4) + "-" + SubStr(DtoS(qCupom->(data)),5,2) + "-" + SubStr(DtoS(qCupom->(data)),7,2) + " 00:00:00.0000000" + "''"        
                                    Else
                                        cSql += "     AND data         = ''" + qCupom->(data) + "''"                                    
                                    EndIf
                                    cSql += "     AND num_pdv      = " + cValToChar(qCupom->(num_pdv))
                                    cSql += "     AND evento_cupom = " + cValToChar(qCupom->(evento_cupom))
                                    cSql += "     AND evento_nsu   = " + cValToChar(qCupom->(evento_nsu))
                                    cSql += "     AND tipo_evento  = " + cValToChar(qCupom->(tipo_evento))                            
                                    cSql += "  ') SET flag = 1 "

                                    TCSqlExec(cSql)                
                                
                                    // If __lJob
                                        //conout("-----------------------------------------------------------------")         
                                        //conout("Visual Mix: Orcamento " + SL1->L1_NUM + " gerado com sucesso!")
                                        //conout("=================================================================")         
                                    // EndIf

                                Else

                                    __cMsgErro += "Erro na gravação!" + Chr(10)

                                    // If __lJob
                                        //conout("-----------------------------------------------------------------")         
                                        //conout("ERRO")                                                         
                                        //conout(__cMsgErro)
                                        //conout("=================================================================")         
                                    // EndIf
                                    /*
                                    RecLock("ZV3",.F.)
                                    ZV3->ZV3_STATUS := "3"
                                    ZV3->ZV3_ERROR  := __cMsgErro
                                    ZV3->(MsUnLock())                            
                                    */
                                    cSql := "  UPDATE OPENQUERY (" + cVMIXDB + ", "
                                    cSql += " 'SELECT * "
                                    cSql += "    FROM " + cVMIXINS + "." + cVMIXTAB                
                                    cSql += "   WHERE loja         = " + cValToChar(qCupom->(loja))
                                    If ValType(qCupom->(data)) == "D"
                                        cSql += "     AND data         = ''" + SubStr(DtoS(qCupom->(data)),1,4) + "-" + SubStr(DtoS(qCupom->(data)),5,2) + "-" + SubStr(DtoS(qCupom->(data)),7,2) + " 00:00:00.0000000" + "''"        
                                    Else
                                        cSql += "     AND data         = ''" + qCupom->(data) + "''"                                    
                                    EndIf
                                    cSql += "     AND num_pdv      = " + cValToChar(qCupom->(num_pdv))
                                    cSql += "     AND evento_cupom = " + cValToChar(qCupom->(evento_cupom))
                                    cSql += "     AND evento_nsu   = " + cValToChar(qCupom->(evento_nsu))
                                    cSql += "     AND tipo_evento  = " + cValToChar(qCupom->(tipo_evento))                                
                                    cSql += "  ') SET flag = 3 "

                                    TCSqlExec(cSql)                

                                EndIf                    
                                    
                            Else

                                __cMsgErro += "Erro: Cupom sem produto ou pagamento!" + Chr(10)

                                // If __lJob
                                    //conout("-----------------------------------------------------------------")         
                                    //conout("ATENCAO")                                                     
                                    //conout(__cMsgErro)
                                    //conout("=================================================================")         
                                // EndIf
                                /*
                                RecLock("ZV3",.F.)
                                ZV3->ZV3_STATUS := "3"
                                ZV3->ZV3_ERROR  := __cMsgErro
                                ZV3->(MsUnLock())                
                                 */
                                cSql := "  UPDATE OPENQUERY (" + cVMIXDB + ", "
                                cSql += " 'SELECT * "
                                cSql += "    FROM " + cVMIXINS + "." + cVMIXTAB                
                                cSql += "   WHERE loja         = " + cValToChar(qCupom->(loja))
                                If ValType(qCupom->(data)) == "D"
                                    cSql += "     AND data         = ''" + SubStr(DtoS(qCupom->(data)),1,4) + "-" + SubStr(DtoS(qCupom->(data)),5,2) + "-" + SubStr(DtoS(qCupom->(data)),7,2) + " 00:00:00.0000000" + "''"        
                                Else
                                    cSql += "     AND data         = ''" + qCupom->(data) + "''"                                
                                EndIf
                                cSql += "     AND num_pdv      = " + cValToChar(qCupom->(num_pdv))
                                cSql += "     AND evento_cupom = " + cValToChar(qCupom->(evento_cupom))
                                cSql += "     AND evento_nsu   = " + cValToChar(qCupom->(evento_nsu))
                                cSql += "     AND tipo_evento  = " + cValToChar(qCupom->(tipo_evento))                            
                                cSql += "  ') SET flag = 3 "

                                TCSqlExec(cSql)                            

                            EndIf                
                    
                            qNfce->(DbSkip())

                        EndDo

                    Else
                    
                        lCancel := .F.
                    
                        __aCab := GetValue("qCapa", "SL1")

                        //Consulta itens cupons nao importados

                        cSql := "    SELECT * "
                        cSql += "      FROM OPENQUERY (" + cVMIXDB + ", "
                        cSql += "   'SELECT * "
                        cSql += "      FROM " + cVMIXINS + ".vw_item_venda"   
                        cSql += "     WHERE loja         = " + cValToChar(qCupom->(loja))
                        If ValType(qCupom->(data)) == "D"
                            cSql += "       AND data         = ''" + SubStr(DtoS(qCupom->(data)),1,4) + "-" + SubStr(DtoS(qCupom->(data)),5,2) + "-" + SubStr(DtoS(qCupom->(data)),7,2) + " 00:00:00.0000000" + "''"
                        Else
                            cSql += "       AND data         = ''" + qCupom->(data) + "''"                        
                        EndIf
                        cSql += "       AND num_pdv      = " + cValToChar(qCupom->(num_pdv))
                        cSql += "       AND evento_cupom = " + cValToChar(qCupom->(evento_cupom))
                        cSql += "       AND evento_nsu   = " + cValToChar(qCupom->(evento_nsu))         
                        cSql += "       AND cancelado   <> 1 "                       
                        cSql += "  ORDER BY loja, data, num_pdv, evento_cupom, evento_nsu, sequencial')"
                                    
                        TCQUERY cSql NEW ALIAS qItem

                        __aItens := {}

                        While qItem->(!Eof())

                            cSql := "    SELECT * "
                            cSql += "      FROM OPENQUERY (" + cVMIXDB + ", "
                            cSql += "   'SELECT * "
                            cSql += "      FROM " + cVMIXINS + ".vw_embalagem_loja"   
                            cSql += "     WHERE loja       = " + cValToChar(qItem->(loja))
                            cSql += "       AND produto_id = " + cValToChar(qItem->(cod_interno)) + "')"
                            
                            TCQUERY cSql NEW ALIAS qFiscal        

                            lItemOk := .T.

                            aItem := GetValue("qItem", "SL2")

                            aAdd(__aItens, aItem)

                            qFiscal->(DbCloseArea())

                            qItem->(DbSkip())

                        EndDo

                        qItem->(DbCloseArea())

                        //Consulta itens cupons nao importados

                        //---------------------------------------------
                        // Pagamento igual a dinheiro
                        //---------------------------------------------

                        cSql := "   SELECT loja, data, num_pdv, evento_cupom, evento_nsu, cod_finaliz, num_cupom, data_vencimento, cpf, cmc7, tipo_tef, sum(valor) valor, "
                        cSql += "          tipo_tef, cod_rede, cod_bandeira, cod_autorizacao, cod_sitef, bin, parcelas, dominio, nsu_host, nsu_pos "
                        cSql += "     FROM OPENQUERY (" + cVMIXDB + ", "
                        cSql += "  'SELECT * "
                        cSql += "     FROM " + cVMIXINS + ".vw_finalizadora_det"   
                        cSql += "    WHERE loja         = " + cValToChar(qCupom->(loja))
                        If ValType(qCupom->(data)) == "D"
                            cSql += "      AND data         = ''" + SubStr(DtoS(qCupom->(data)),1,4) + "-" + SubStr(DtoS(qCupom->(data)),5,2) + "-" + SubStr(DtoS(qCupom->(data)),7,2) + " 00:00:00.0000000" + "''"
                        Else
                            cSql += "      AND data         = ''" + qCupom->(data) + "''"
                        EndIf
                        cSql += "      AND num_pdv      = " + cValToChar(qCupom->(num_pdv))
                        cSql += "      AND evento_cupom = " + cValToChar(qCupom->(evento_cupom))
                        cSql += "      AND evento_nsu   = " + cValToChar(qCupom->(evento_nsu))                        
                        cSql += "      AND cod_finaliz  = 6 "
                        cSql += " ORDER BY loja, data, num_pdv, evento_cupom, evento_nsu')"
                        cSql += " GROUP BY loja, data, num_pdv, evento_cupom, evento_nsu, cod_finaliz, num_cupom, data_vencimento, cpf, cmc7, tipo_tef, "
                        cSql += "          tipo_tef, cod_rede, cod_bandeira, cod_autorizacao, cod_sitef, bin, parcelas, dominio, nsu_host, nsu_pos "
                                    
                        TCQUERY cSql NEW ALIAS qPgto

                        __aPgtos := {}

                        While qPgto->(!Eof())

                            aPgto := GetValue("qPgto", "SL4")

                            aAdd(__aPgtos, aPgto)

                            qPgto->(DbSkip())

                        EndDo

                        qPgto->(DbCloseArea())

                        //---------------------------------------------
                        // Pagamentos diferentes de dinheiro
                        //---------------------------------------------

                        cSql := "   SELECT * "
                        cSql += "     FROM OPENQUERY (" + cVMIXDB + ", "
                        cSql += "  'SELECT * "
                        cSql += "     FROM " + cVMIXINS + ".vw_finalizadora_det"   
                        cSql += "    WHERE loja         = " + cValToChar(qCupom->(loja))
                        If ValType(qCupom->(data)) == "D"
                            cSql += "      AND data         = ''" + SubStr(DtoS(qCupom->(data)),1,4) + "-" + SubStr(DtoS(qCupom->(data)),5,2) + "-" + SubStr(DtoS(qCupom->(data)),7,2) + " 00:00:00.0000000" + "''"
                        Else
                            cSql += "      AND data         = ''" + qCupom->(data) + "''"
                        EndIf
                        cSql += "      AND num_pdv      = " + cValToChar(qCupom->(num_pdv))
                        cSql += "      AND evento_cupom = " + cValToChar(qCupom->(evento_cupom))
                        cSql += "      AND evento_nsu   = " + cValToChar(qCupom->(evento_nsu))                        
                        cSql += "      AND cod_finaliz <> 6 "
                        cSql += " ORDER BY loja, data, num_pdv, evento_cupom, evento_nsu, sequencial')"
                                    
                        TCQUERY cSql NEW ALIAS qPgto

                        While qPgto->(!Eof())

                            aPgto := GetValue("qPgto", "SL4")

                            lPgtoOk   := .T.
                            dDataVenc := aPgto[aScan(aPgto, {|X| AllTrim(X[1]) == "L4_DATA"}), 2]
                            nTotParc  := qPgto->(parcelas)
                            nTotParc  := If(nTotParc == 0, 1, nTotParc)
                            nSubTotal := 0

                            For nParcela := 1 to nTotParc

                                If AllTrim(Posicione("SAE", 1, xFilial("SAE") + aPgto[aScan(aPgto, {|X| AllTrim(X[1]) == "L4_ADMINIS"}), 2], "AE_TIPO")) == "CC"

                                    dDataVenc += 30

                                ElseIf AllTrim(Posicione("SAE", 1, xFilial("SAE") + aPgto[aScan(aPgto, {|X| AllTrim(X[1]) == "L4_ADMINIS"}), 2], "AE_TIPO")) == "CD"

                                    dDataVenc += 1

                                EndIf                

                                aPgto := GetValue("qPgto", "SL4")
                
                                If nParcela == nTotParc

                                    aPgto[aScan(aPgto, {|X| AllTrim(X[1]) == "L4_VALOR"}), 2] := NoRound(aPgto[aScan(aPgto, {|X| AllTrim(X[1]) == "L4_VALOR"}), 2] - nSubTotal, 2)

                                Else

                                    aPgto[aScan(aPgto, {|X| AllTrim(X[1]) == "L4_VALOR"}), 2] := NoRound(aPgto[aScan(aPgto, {|X| AllTrim(X[1]) == "L4_VALOR"}), 2] / nTotParc, 2)

                                EndIf

                                nSubTotal += aPgto[aScan(aPgto, {|X| AllTrim(X[1]) == "L4_VALOR"}), 2]

                                aPgto[aScan(aPgto, {|X| AllTrim(X[1]) == "L4_DATA"}), 2] := dDataVenc

                                aAdd(__aPgtos, aPgto)

                            Next

                            qPgto->(DbSkip())

                        EndDo

                        qPgto->(DbCloseArea())
                        
                        
                        // cSql := "   SELECT * "
                        // cSql += "     FROM OPENQUERY (" + cVMIXDB + ", "
                        // cSql += "  'SELECT * "
                        // cSql += "     FROM " + cVMIXINS + ".vw_finalizadora_det"   
                        // cSql += "    WHERE loja         = " + cValToChar(qCupom->(loja))
                        // If ValType(qCupom->(data)) == "D"
                        //     cSql += "      AND data         = ''" + SubStr(DtoS(qCupom->(data)),1,4) + "-" + SubStr(DtoS(qCupom->(data)),5,2) + "-" + SubStr(DtoS(qCupom->(data)),7,2) + " 00:00:00.0000000" + "''"
                        // Else
                        //     cSql += "      AND data         = ''" + qCupom->(data) + "''"                        
                        // EndIf
                        // cSql += "      AND num_pdv      = " + cValToChar(qCupom->(num_pdv))
                        // cSql += "      AND evento_cupom = " + cValToChar(qCupom->(evento_cupom))
                        // cSql += "      AND evento_nsu   = " + cValToChar(qCupom->(evento_nsu))                        
                        // cSql += " ORDER BY loja, data, num_pdv, evento_cupom, evento_nsu, sequencial')"
                                    
                        // TCQUERY cSql NEW ALIAS qPgto

                        // __aPgtos := {}

                        // While qPgto->(!Eof())

                        //     aPgto := GetValue("qPgto", "SL4")

                        //     lPgtoOk   := .T.
                        //     dDataVenc := aPgto[aScan(aPgto, {|X| AllTrim(X[1]) == "L4_DATA"}), 2]
                        //     nTotParc  := qPgto->(parcelas)
                        //     nTotParc  := If(nTotParc == 0, 1, nTotParc)
                        //     nSubTotal := 0

                        //     For nParcela := 1 to nTotParc

                        //         If AllTrim(Posicione("SAE", 1, xFilial("SAE") + aPgto[aScan(aPgto, {|X| AllTrim(X[1]) == "L4_ADMINIS"}), 2], "AE_TIPO")) == "CC"

                        //             dDataVenc += 30

                        //         ElseIf AllTrim(Posicione("SAE", 1, xFilial("SAE") + aPgto[aScan(aPgto, {|X| AllTrim(X[1]) == "L4_ADMINIS"}), 2], "AE_TIPO")) == "CD"

                        //             dDataVenc += 31

                        //         EndIf                

                        //         aPgto := GetValue("qPgto", "SL4")
                
                        //         If nParcela == nTotParc

                        //             aPgto[aScan(aPgto, {|X| AllTrim(X[1]) == "L4_VALOR"}), 2] := NoRound(aPgto[aScan(aPgto, {|X| AllTrim(X[1]) == "L4_VALOR"}), 2] - nSubTotal, 2)

                        //         Else

                        //             aPgto[aScan(aPgto, {|X| AllTrim(X[1]) == "L4_VALOR"}), 2] := NoRound(aPgto[aScan(aPgto, {|X| AllTrim(X[1]) == "L4_VALOR"}), 2] / nTotParc, 2)

                        //         EndIf

                        //         nSubTotal += aPgto[aScan(aPgto, {|X| AllTrim(X[1]) == "L4_VALOR"}), 2]

                        //         aPgto[aScan(aPgto, {|X| AllTrim(X[1]) == "L4_DATA"}), 2] := dDataVenc

                        //         aAdd(__aPgtos, aPgto)

                        //     Next

                        //     qPgto->(DbSkip())

                        // EndDo

                        // qPgto->(DbCloseArea())

                        If Len(__aCab) > 0 .And. Len(__aItens) > 0 .And. Len(__aPgtos) > 0

                            BEGIN TRANSACTION

                                lItemOk := Save("SL2", __aItens)                
                                lPgtoOk := Save("SL4", __aPgtos)                
                                lCapaOk := Save("SL1", __aCab)                

                                If lCapaOk .And. lItemOk .And. lPgtoOk

                                    CONFIRMSX8()

                                Else

                                    ROLLBAKCSX8()

                                    DISARMTRANSACTION()
                                    
                                EndIf

                            END TRANSACTION

                            If lCapaOk .And. lItemOk .And. lPgtoOk

                                If Empty(__cMsgAdv)
                                    cStatus := "1"
                                Else
                                    cStatus := "2"
                                EndIf
                                /*
                                RecLock("ZV3",.F.)
                                ZV3->ZV3_STATUS := cStatus
                                ZV3->ZV3_L1CUP  := SL1->L1_NUM
                                ZV3->ZV3_ADVERT := __cMsgAdv
                                ZV3->(MsUnLock())                
                                 */
                                cSql := "  UPDATE OPENQUERY (" + cVMIXDB + ", "
                                cSql += " 'SELECT * "
                                cSql += "    FROM " + cVMIXINS + "." + cVMIXTAB                
                                cSql += "   WHERE loja         = " + cValToChar(qCupom->(loja))
                                If ValType(qCupom->(data)) == "D"
                                    cSql += "     AND data         = ''" + SubStr(DtoS(qCupom->(data)),1,4) + "-" + SubStr(DtoS(qCupom->(data)),5,2) + "-" + SubStr(DtoS(qCupom->(data)),7,2) + " 00:00:00.0000000" + "''"        
                                Else
                                    cSql += "     AND data         = ''" + qCupom->(data) + "''"                            
                                EndIf
                                cSql += "     AND num_pdv      = " + cValToChar(qCupom->(num_pdv))
                                cSql += "     AND evento_cupom = " + cValToChar(qCupom->(evento_cupom))
                                cSql += "     AND evento_nsu   = " + cValToChar(qCupom->(evento_nsu))
                                cSql += "     AND tipo_evento  = " + cValToChar(qCupom->(tipo_evento))                            
                                cSql += "  ') SET flag = 1 "

                                TCSqlExec(cSql)                
                            
                                // If __lJob
                                    //conout("Visual Mix: Orcamento " + SL1->L1_NUM + " gerado com sucesso!")
                                // EndIf

                            Else

                                __cMsgErro += "Erro na gravação!" + Chr(10)

                                // If __lJob
                                    //conout("-----------------------------------------------------------------")         
                                    //conout("ERRO")                                                     
                                    //conout(__cMsgErro)
                                    //conout("=================================================================")         
                                // EndIf
                                /*
                                RecLock("ZV3",.F.)
                                ZV3->ZV3_STATUS := "3"
                                ZV3->ZV3_ERROR  := __cMsgErro
                                ZV3->(MsUnLock())                            
                                 */
                                cSql := "  UPDATE OPENQUERY (" + cVMIXDB + ", "
                                cSql += " 'SELECT * "
                                cSql += "    FROM " + cVMIXINS + "." + cVMIXTAB                
                                cSql += "   WHERE loja         = " + cValToChar(qCupom->(loja))
                                If ValType(qCupom->(data)) == "D"
                                    cSql += "     AND data         = ''" + SubStr(DtoS(qCupom->(data)),1,4) + "-" + SubStr(DtoS(qCupom->(data)),5,2) + "-" + SubStr(DtoS(qCupom->(data)),7,2) + " 00:00:00.0000000" + "''"        
                                Else
                                    cSql += "     AND data         = ''" + qCupom->(data) + "''"                                
                                EndIf
                                cSql += "     AND num_pdv      = " + cValToChar(qCupom->(num_pdv))
                                cSql += "     AND evento_cupom = " + cValToChar(qCupom->(evento_cupom))
                                cSql += "     AND evento_nsu   = " + cValToChar(qCupom->(evento_nsu))
                                cSql += "     AND tipo_evento  = " + cValToChar(qCupom->(tipo_evento))                            
                                cSql += "  ') SET flag = 3 "

                                TCSqlExec(cSql)                

                            EndIf                    
                                
                        Else

                            __cMsgErro += "Erro: Cupom sem produto ou pagamento!" + Chr(10)

                            // If __lJob
                                //conout("-----------------------------------------------------------------")         
                                //conout("ERRO")                                                                             
                                //conout(__cMsgErro)
                                //conout("=================================================================")         
                            // EndIf
                            /*
                            RecLock("ZV3",.F.)
                            ZV3->ZV3_STATUS := "3"
                            ZV3->ZV3_ERROR  := __cMsgErro
                            ZV3->(MsUnLock())                
                             */
                            cSql := "  UPDATE OPENQUERY (" + cVMIXDB + ", "
                            cSql += " 'SELECT * "
                            cSql += "    FROM " + cVMIXINS + "." + cVMIXTAB                
                            cSql += "   WHERE loja         = " + cValToChar(qCupom->(loja))
                            If ValType(qCupom->(data)) == "D"
                                cSql += "     AND data         = ''" + SubStr(DtoS(qCupom->(data)),1,4) + "-" + SubStr(DtoS(qCupom->(data)),5,2) + "-" + SubStr(DtoS(qCupom->(data)),7,2) + " 00:00:00.0000000" + "''"        
                            Else
                                cSql += "     AND data         = ''" + qCupom->(data) + "''"                            
                            EndIf
                            cSql += "     AND num_pdv      = " + cValToChar(qCupom->(num_pdv))
                            cSql += "     AND evento_cupom = " + cValToChar(qCupom->(evento_cupom))
                            cSql += "     AND evento_nsu   = " + cValToChar(qCupom->(evento_nsu))
                            cSql += "     AND tipo_evento  = " + cValToChar(qCupom->(tipo_evento))                
                            cSql += "  ') SET flag = 3 "

                            TCSqlExec(cSql)                            

                        EndIf                
                    
                    EndIf
                        
                    // lContinua := .F.            
                    // If "qNfce" $ cVMIXKEY
                    //     While qNfce->(!Eof())
                    //         lContinua := .T.
                    //         qNfce->(DbSkip())
                    //     EndDo
                    // Else
                    //     lContinua := .T.
                    // EndIf
                        
                    // If lContinua
                    
                    // EndIf
                    
                    qCapa->(DbSkip())

                EndDo

                qCapa->(DbCloseArea())

                If (!lCapaOk .Or. !lItemOk .Or. !lPgtoOk) .And. !lCancel
        
                    __cMsgErro += "Erro: Cupom nao encontrado!" + Chr(10)

                    // If __lJob
                        //conout("-----------------------------------------------------------------")         
                        //conout("ERRO")                                                                             
                        //conout("Erro: Cupom nao encontrado!")
                        //conout("=================================================================")         
                    // EndIf
                     /*
                    RecLock("ZV3",.F.)
                    ZV3->ZV3_STATUS := "3"
                    ZV3->ZV3_ERROR  := __cMsgErro
                    ZV3->(MsUnLock())                            
                      */
                    cSql := "  UPDATE OPENQUERY (" + cVMIXDB + ", "
                    cSql += " 'SELECT * "
                    cSql += "    FROM " + cVMIXINS + "." + cVMIXTAB                
                    cSql += "   WHERE loja         = " + cValToChar(qCupom->(loja))
                    If ValType(qCupom->(data)) == "D"
                        cSql += "     AND data         = ''" + SubStr(DtoS(qCupom->(data)),1,4) + "-" + SubStr(DtoS(qCupom->(data)),5,2) + "-" + SubStr(DtoS(qCupom->(data)),7,2) + " 00:00:00.0000000" + "''"        
                    Else
                        cSql += "     AND data         = ''" + qCupom->(data) + "''"                    
                    EndIf
                    cSql += "     AND num_pdv      = " + cValToChar(qCupom->(num_pdv))
                    cSql += "     AND evento_cupom = " + cValToChar(qCupom->(evento_cupom))
                    cSql += "     AND evento_nsu   = " + cValToChar(qCupom->(evento_nsu))
                    cSql += "     AND tipo_evento  = " + cValToChar(qCupom->(tipo_evento))                
                    cSql += "  ') SET flag = 3 "
                    
                    TCSqlExec(cSql)                
                    
                EndIf

            EndIf

            qNfce->(DbCloseArea())        

        EndIf

        qCupom->(DbSkip())

    EndDo

    qCupom->(DbCloseArea())

    If !__lJob
        MsgInfo("Importação concluída!")
    EndIf

    //conout("=================================================================")         
    //conout("INTEGRACAO VISUAL MIX CONCLUIDA.")
    //conout("=================================================================")         
    //conout("")

Return Nil

/*/{Protheus.doc} GetValue
Rotina para retornar o array
/*/ 
Static Function GetValue(cQuery, cTable)

    Local aArray := {}
    Local aType  := {}

    ZV1->(DbSetOrder(1))
    ZV1->(DbSeek(xFilial("ZV1") + cTable))

    //Monta array do cabeçalho
    While ZV1->(!Eof()) .And. ZV1->(ZV1_FILIAL + ZV1_TABPRO) == xFilial("ZV1") + cTable

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
                            //conout(//conout)
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
                            //conout(__cMsgAdv)
                        // EndIf

                    EndIf

                ElseIf ValType(&(cQuery + "->(" + AllTrim(ZV1->ZV1_CPOVIS)+")")) == "D"

                    xValue := &(cQuery + "->(" + AllTrim(ZV1->ZV1_CPOVIS)+")")

                Else

                    xValue := &(StrTran(AllTrim(ZV1->ZV1_FORMUL), "%" + AllTrim(ZV1->ZV1_CPOVIS) + "%", '"' + &(cQuery + "->(" + AllTrim(ZV1->ZV1_CPOVIS)+")") + '"'))

                EndIf                    

            EndIf

            aAdd(aArray, {AllTrim(ZV1->ZV1_CPOPRO), xValue, Nil})

        EndIf

        ZV1->(DbSkip())

    EndDo

Return aArray

/*/{Protheus.doc} GetValue
Rotina para retornar o array
/*/ 
Static Function Save(cAlias, aArray, lNfce)

    Local lRet     := .T.
    Local aItem    := {}
    Local nX       := 0
    Local nY       := 0

    Default lNfce  := .F.

    If cAlias == "SL1" .And. !lNfce

        RecLock(cAlias, .T.)

        For nX := 1 To Len(aArray)

            (&(cAlias))->(&(aArray[nX, 1])) := aArray[nX, 2]

        Next

        (&(cAlias))->(MsUnLock())                    

    Else

        For nY := 1 to Len(aArray)

            aItem := aArray[nY]

            RecLock(cAlias, .T.)

            For nX := 1 To Len(aItem)

                (&(cAlias))->(&(aItem[nX, 1])) := aItem[nX, 2]

            Next

            (&(cAlias))->(MsUnLock())                    

        Next

    EndIf

Return lRet
