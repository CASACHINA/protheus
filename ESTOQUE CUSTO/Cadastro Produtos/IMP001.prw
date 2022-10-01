#include "totvs.ch"
#include "topConn.ch"
#include "fwMvcDef.ch"

/*/{Protheus.doc} IMP001
Funcao para efetuar a importação de um arquivo CSV de produtos
@author Paulo Cesar Camata
@since 07/02/2019
@version 12.1.17
@type functionF
/*/
user function IMP001()
    local aRet, aPergs := {}

    private cSeparador := chr(9)
    private aRotina    := {}
    private INCLUI, ALTERA

    aAdd(aPergs, {6, "Caminho TXT: ", space(200), , , , 90, .T., "Arquivos .TXT |*.TXT", , GETF_LOCALHARD + GETF_NETWORKDRIVE})
    If ParamBox(aPergs, "Parametros ", aRet) // Usuário confirmou a tela de parametro
        if !file(mv_par01) // Arquivo nao existe
            msgStop("Arquivo não encontrado.", "ARQUIVO NAO EXISTE")
            return nil
        endIf

        if upper(right(allTrim(mv_par01), 3)) <> "TXT"
            msgStop("Extensão do arquivo informado não é TXT. Verifique.", "EXTENSAO INVALIDA")
            return nil
        endif

        // Funcao para efetuar a importação do arquivo
        Processa({|| fImpArq(allTrim(mv_par01))}, "Processando...") // Inicializa a regua de processamento
    endif
return nil

// Funcao para efetuar a importação do arquivo
static function fImpArq(cCamArq)
    Local oFile := FWFileReader():New(cCamArq)
    local aLines, aCabec, nPosBar, nP, nI, nY, oModel, aProduto, nPosRef, lIncAlter
    local nPosPro    := 0
    local cLogErro   := ""
    local cLogProd   := ""
    local cLogVenda  := ""
    local cLogCompra := ""
    local cLogTES    := ""
    local cLogLiga   := ""
    local cCodTab    := ""
    local cCpoAlter  := "B1_CODBAR |B1_COD    |B1_PROC   |B1_LOJPROC" // Campos que não serao considerados alteracao
    local aTabVen    := {}
    local aTabCom    := {}
    local lCpoB2B    := .F.

    private lMsErroAuto := .F.

    oFile:Open()
    aLines := oFile:getAllLines()

    nTotLin := len(aLines) - 1
    ProcRegua(nTotLin) // Tamanho da regua de processamento

    // Cabecalho (1a linha do arquivo)
    aCabec := Strtokarr2(aLines[1], cSeparador, .F.)

    nPosFil := aScan(aCabec, {|x| allTrim(x) == "B1_FILIAL" }) // Caso arquivo tenha filial devera ser alterada para a filial corrente
    nPosPro := aScan(aCabec, {|x| allTrim(x) == "B1_COD"    }) // Caso arquivo tenha Codigo do produto devera ser alterada para a filial corrente
    nPosBar := aScan(aCabec, {|x| allTrim(x) == "B1_CODBAR" })
    nPosRef := aScan(aCabec, {|x| allTrim(x) == "B1_CODREF" })
    nPosFor := aScan(aCabec, {|x| allTrim(x) == "B1_PROC"   })
    nPosLoj := aScan(aCabec, {|x| allTrim(x) == "B1_LOJPROC"})
    
    lCpoFis := (aScan(aCabec, {|x| allTrim(left(x, 5)) == "Z1_UF"}) > 0)

    lCpoB2B := fCpoB2B(aCabec) // Verifica se algum campo importante 

    // Buscando dados das tabelas de vendas
    for nY := 1 to len(aCabec)
        if left(aCabec[nY], 9) == "B1_PRCVEN"
            aAdd(aTabVen, {subStr(aCabec[nY], 10, 3), nY})
        endif
    next nY

    // Buscando dados das tabelas de compras
    for nI := 1 to len(aCabec)
        if left(aCabec[nI], 9) == "B1_TABCOM"
            cCodTab := subStr(aCabec[nI], 10, 3)

            if len(aCabec[nI]) > 12 .and. subStr(aCabec[nI], 13, 2) <> "PR" // Possui Estado
                cEstTab := subStr(aCabec[nI], 13, 2)
            else
                cEstTab := ""
            endif

            aAdd(aTabCom, {cCodTab, cEstTab, nI})
        endif
    next nI

    dbSelectArea("SB1")
    incProc("Processando linha 1 de " + cValToChar(nTotLin))

    for nP := 2 to len(aLines)
        incProc("Processando linha " + cValToChar(nP) + " de " + cValToChar(nTotLin))
        aLinAux := Strtokarr2(aLines[nP], cSeparador, .T.)

        if nPosFil > 0 // Arquivo possui coluna FILIAL
            cFilAnt := aLines[nPosFil]
        endif

        lIncAlter := .F. // Variavel q identifica se existe algum campo para ser alterado no cadastro do produto

        dbSelectArea("SX3")
        SX3->(dbSetOrder(2)) // X3_CAMPO
        aProduto := {} // Array do produto da rotina automatica
        for nI := 1 to len(aCabec)
            if nI <> nPosFil .and. !empty(aLinAux[nI]) .and. left(aCabec[nI], 3) == "B1_" .and. left(aCabec[nI], 9) <> "B1_TABCOM" // Nao considerar campo filial e tabela de compras
                // Verificando se o campo informado no cabecalho existe no arquivo SX3 e nao é virtual
                if SX3->(msSeek(padR(aCabec[nI], 10))) .and. SX3->X3_CONTEXT <> "V"
                    if allTrim(SX3->X3_CAMPO) == "B1_01CAT4" // Tratamento para mercadologico
                        aAdd(aProduto, {"B1_01CAT1", left(aLinAux[nI], 2), nil})
                        aAdd(aProduto, {"B1_01CAT2", left(aLinAux[nI], 4), nil})
                        aAdd(aProduto, {"B1_01CAT3", left(aLinAux[nI], 6), nil})
                        aAdd(aProduto, {"B1_01CAT4", left(aLinAux[nI], 8), nil})

                    elseif SX3->X3_TIPO == "C"
                        aAdd(aProduto, {aCabec[nI], aLinAux[nI], nil})
                    elseif SX3->X3_TIPO == "D"
                        aAdd(aProduto, {aCabec[nI], STOD(aLinAux[nI]), nil})
                    elseif SX3->X3_TIPO == "N"
                        aAdd(aProduto, {aCabec[nI], val(strTran(aLinAux[nI], ",", ".")), nil})
                    endif

                    // Verificando se o campo informado não esta nos campos q sao considerados para alteracao
                    if !padr(SX3->X3_CAMPO, 10) $ cCpoAlter
                        lIncAlter := .T.
                    endif
                endif
            endif
        next nI

        if lCpoFis // Campos Fiscais (SZ1)
            nPosFis := AScanX(aCabec, {|x| allTrim(left(x, 5)) == "Z1_UF"})
            dbSelectArea("SZ1")
            SZ1->(dbSetOrder(1))
            
            while nPosFis > 0
                cEstFis := aLinAux[nPosFis]

                nRecFis := fExisteSZ1(cEstFis, aLinAux[nPosPro])
                if nRecFis > 0
                    SZ1->(dbGoTo(nRecFis))
                    recLock("SZ1", .F.)
                else
                    recLock("SZ1", .T.)
                endif
                
                dbSelectArea("SX3")
                SX3->(dbSetOrder(1))
                SX3->(msSeek("SZ1")) // Buscar todos os campos
                
                // Percorrer todos os campos da tabela
                while !SX3->(EoF()) .and. allTrim(SX3->X3_ARQUIVO) == "SZ1"
                    // Valores fixos (Estado e Produto)
                    if allTrim(SX3->X3_CAMPO) == "Z1_FILIAL"
                        SZ1->Z1_FILIAL := xFilial("SZ1")
                    elseif allTrim(SX3->X3_CAMPO) == "Z1_PRODUTO"
                        SZ1->Z1_PRODUTO := aLinAux[nPosPro]
                    else
                        nPosCpo := AScanX(aCabec, {|x| allTrim(x) == allTrim(SX3->X3_CAMPO) + cEstFis})
                        if nPosCpo > 0
                            if SX3->X3_TIPO == "C"
                                &("SZ1->" + allTrim(SX3->X3_CAMPO)) := aLinAux[nPosCpo]
                            elseif SX3->X3_TIPO == "D"
                                &("SZ1->" + allTrim(SX3->X3_CAMPO)) := STOD(aLinAux[nPosCpo])
                            elseif SX3->X3_TIPO == "N"
                                &("SZ1->" + allTrim(SX3->X3_CAMPO)) := val(strTran(aLinAux[nPosCpo], ",", "."))
                            endif
                        endif
                    endif

                    SX3->(dbSkip())
                enddo

                SZ1->(msUnlock())

                nPosFis := AScanX(aCabec, {|x| allTrim(left(x, 5)) == "Z1_UF"}, nPosFis + 1)
            endDo
        endif
        // Fim Campos SZ1

        if len(aProduto) > 0 // alterar o codigo de barras + algum campo
            lErro  := .F.
            lMsErroAuto := .F.
            oModel := FwLoadModel("MATA010")
            SB1->(dbSetOrder(5))

            begin transaction
                if SB1->(msSeek(xFilial("SB1") + aLinAux[nPosBar])) // Encontrando produto
                    if lIncAlter
                        if nPosPro > 0 // Existe campo de código
                            if !empty(allTrim(aLinAux[nPosPro]))
                                if allTrim(aLinAux[nPosPro]) <> allTrim(SB1->B1_COD)
                                    cLogErro += "Erro Linha " + cValToChar(nP) + " ao alterar o produto. Código de barras " + aLinAux[nPosBar] + " já existe e possui o Código " + allTrim(SB1->B1_COD) + " e não " + aLinAux[nPosPro] + CRLF
                                    lErro := .T.
                                endif
                            else
                                aAdd(aProduto, {"B1_COD", SB1->B1_COD, nil})  // Incluindo codigo do produto para alteracao
                            endif
                        else
                            aAdd(aProduto, {"B1_COD", SB1->B1_COD, nil}) // Incluindo codigo do produto para alteracao
                        endif

                        if !lErro
                            if empty(SB1->B1_GARANT) // Inserindo campo GARANTIA ESTENDIDA caso não esteja preenchido. Campo obrigatório não cadastrado pelo GCV.
                                aAdd(aProduto, {"B1_GARANT", "2", nil})
                            endif

                            FWMVCRotAuto(oModel, "SB1", MODEL_OPERATION_UPDATE, {{"SB1MASTER", aProduto}})
                            if !lMsErroAuto .and. SB1->B1_YB2B == "S" .and. lCpoB2B // Confirmou OK, produto é B2B e algum campo ref ao B2B foi alterado
                                recLock("SB1", .F.)
                                    SB1->B1_YALTB2B := "S" // Campo que controla alteração da platafroma B2B
                                SB1->(msUnlock())
                            endif
                        endif
                    endif
                else
                    FWMVCRotAuto(oModel, "SB1", MODEL_OPERATION_INSERT, {{"SB1MASTER", aProduto}})
                endif

                if !lErro
                    if lMsErroAuto
                        cLogErro += "Erro Linha " + cValToChar(nP) + " ao incluir/alterar o produto. "

                        if (oModel:GetErrorMessage()[2] <> nil)
                            cLogErro += "Campo: " + oModel:GetErrorMessage()[2] + " "
                        endif

                        if (oModel:GetErrorMessage()[6] <> nil)
                            cLogErro += "Erro: " + oModel:GetErrorMessage()[6] + " "
                        endif

                        if (oModel:GetErrorMessage()[9] <> nil)
                            cLogErro += "CONTEUDO: " + oModel:GetErrorMessage()[9] + " "
                        endif
                        cLogErro += CRLF

                        lErro := .T.
                    elseif SB1->B1_MSBLQL == "1"
                        recLock("SB1", .F.)
                            SB1->B1_MSBLQL := "2"
                        SB1->(msUnlock())
                    endif
                endif

                if nPosFor > 0
                    cCodFor := padL(allTrim(aLinAux[nPosFor]), tamSx3("A2_COD")[1], "0")
                endif

                if nPosLoj > 0
                    cLojFor := padL(allTrim(aLinAux[nPosLoj]), tamSx3("A2_LOJA")[1], "0")
                endif

                if !lErro
                    if lIncAlter
                        u_RT001() // Criar saldo SB2

                        fAtualizSB4() // Atualizar campos da tabela SB4
                    endif

                    if len(aTabVen) > 0
                        aRet := fIncTabPV(aLinAux, aTabVen) // Incluir produto na tabela de preço de venda
                        if !aRet[1] // Nao retornou erro
                            cLogVenda += "Erro Linha " + cValToChar(nP) + ": " + aRet[2] + CRLF
                            lErro := .T.
                        endif
                    endif
                endif

                if !lErro .and. len(aTabCom) > 0 .and. !empty(cCodFor)
                    // Verificar tabela de preço de compra
                    for nI := 1 to len(aTabCom)
                        cCodTab := aTabCom[nI, 1] // Codigo da tabela de compra
                        cEstTab := aTabCom[nI, 2] // Estado da tabela de compra
                        nPosTab := aTabCom[nI, 3] // Posicao no cabecalho da tabela de compra

                        if !empty(aLinAux[nPosTab])
                            aRet := fTabCompras(cCodFor, cLojFor, cCodTab, cEstTab, SB1->B1_COD, val(strTran(aLinAux[nPosTab], ",", "."))) // Incluir/Alterar tabela de preço de compra
                            if !aRet[1] // Nao retornou erro
                                cLogCompra += "Erro Linha " + cValToChar(nP) + ": " + aRet[2] + CRLF
                                lErro := .T.
                            endif
                        endif
                    next nI
                endif

                if !lErro .and. !empty(cCodFor) .and. nPosRef > 0
                    aRet := fProdFornec(cCodFor, cLojFor, aLinAux[nPosRef], cCodTab) // incluir lig produto x fornecedor
                    if !aRet[1] // Nao retornou erro
                        cLogLiga += "Erro Linha " + cValToChar(nP) + ": " + aRet[2] + CRLF
                        lErro := .T.
                    endif
                endif

                if !lErro
                    aRet := fTESIntelig()
                    if !aRet[1] // Nao retornou erro
                        cLogTES += "Erro Linha " + cValToChar(nP) + ": " + aRet[2] + CRLF
                        lErro := .T.
                    endif
                endif

                //--- Atualiza SB5
                dbSelectArea("SB5")
                SB5->(dbSetOrder(1))
                if SB5->(msSeek(xFilial("SB5") + SB1->B1_COD)) // Ja Existe Cadastro
                    recLock("SB5", .F.)
                else
                    recLock("SB5", .T.)
                    SB5->B5_FILIAL  := xFilial("SB5")
                    SB5->B5_COD     := SB1->B1_COD
                endif

                dbSelectArea("SX3")
                SX3->(dbSetOrder(2)) // X3_CAMPO
                aDados := {} // Array do produto da rotina automatica

                for nI := 1 to len(aCabec)
                    if Substr(aCabec[nI],1,2) == "B5"
                        _cCampo = PADR(aCabec[nI], 10)
                        _aTpCpo := TamSX3(_cCampo)

                        If _aTpCpo[3] == "C"
                            aAdd(aDados, {aCabec[nI], aLinAux[nI], nil})
                        elseif _aTpCpo[3] == "D"
                            aAdd(aDados, {aCabec[nI], STOD(aLinAux[nI]), nil})
                        elseif _aTpCpo[3] == "N"
                            aAdd(aDados, {aCabec[nI], val(strTran(aLinAux[nI], ",", ".")), nil})
                        endif
                    endif

                next nI

                for nI := 1 to len(aDados)
                    &("SB5->" + aDados[nI,1]) := aDados[nI,2]
                next nI

                SB5->(msUnlock())

                if lErro
                    disarmTransaction()
                endif
            end transaction
        else
            cLogErro += "Linha: " + cValToChar(nP) + " - Cabeçalho do arquivo inválido ou não foram encontrados registros a serem inseridos." + CRLF
        endif
    next nP

    do case
        case !empty(cLogProd)
            cLogErro += "ERRO INCLUSAO PRODUTO:" + CRLF
            cLogErro += cLogProd

        case !empty(cLogVenda)
            cLogErro += "ERRO TABELA DE PREÇO DE VENDA:" + CRLF
            cLogErro += cLogVenda

        case !empty(cLogCompra)
            cLogErro += "ERRO TABELA DE PRECO DE COMPRA:" + CRLF
            cLogErro += cLogCompra

        case !empty(cLogLiga)
            cLogErro += "ERRO LIG. PRODUTO X FORNECEDOR:" + CRLF
            cLogErro += cLogLiga

        case !empty(cLogTES)
            cLogErro += "ALERTA TES INTELIGENTE:" + CRLF
            cLogErro += cLogTES
    endCase

    if !empty(cLogErro)
        msgStop(cLogErro, "LOG ERRO PRODTUO")
    else
        msgInfo("Planilha importada sem erros.")
    endif
return nil

// Funcao para efetuar atualizacao da tabela SB4
Static Function fAtualizSB4()
    local cCampo

    dbSelectArea("SB4")
    SB4->(dbSetOrder(1))
    if SB4->(msSeek(xFilial("SB4") + SB1->B1_COD)) // Ja Existe Cadastro
        recLock("SB4", .F.)
        SB4->B4_STATUS  := "A"
        SB4->B4_01UTGRD := "N"
    else
        recLock("SB4", .T.)
        SB4->B4_FILIAL  := xFilial("SB4")
        SB4->B4_COD     := SB1->B1_COD
        SB4->B4_STATUS  := "A"
        SB4->B4_01UTGRD := "N"
    endif

    dbSelectArea("SX3")
    SX3->(dbSetOrder(1))
    SX3->(dbGoTop())
    SX3->(msSeek("SB4"))
    while !SX3->(Eof()) .and. allTrim(SX3->X3_ARQUIVO) == "SB4"
        if !allTrim(SX3->X3_CAMPO) $ "B4_FILIAL|B4_COD" .and. SX3->X3_CONTEXT <> "V"
            cCampo := "B1_" + subStr(SX3->X3_CAMPO, 4, 7)

            if SB1->(FieldPos(cCampo)) > 0 // campo existe na tabela SB1
                &("SB4->" + SX3->X3_CAMPO) := SB1->(FieldGet(FieldPos(cCampo)))
            endif
        endif

        SX3->(dbSkip())
    endDo
    SB4->(msUnlock())
Return nil



// Funcao para incluir/alterar o produto na tabela de preço de venda padrao
static function fIncTabPV(aLinha, aTabVen)
    local _aRet := {.T., ""}
    local nY, cTabVen

    for nY := 1 to len(aTabVen)
        cTabVen := aTabVen[nY, 1]
        nPosTab := aTabVen[nY, 2]

        if !empty(aLinha[nPosTab])
            dbSelectArea("DA0")
            DA0->(dbSetOrder(1))
            if DA0->(msSeek(xFilial("DA0") + cTabVen))
                dbSelectArea("DA1")
                DA1->(dbSetOrder(1))
                if DA1->(msSeek(xFilial("DA1") + cTabVen + SB1->B1_COD))
                    recLock("DA1", .F.)
                    DA1->DA1_PRCVEN := val(strTran(aLinha[nPosTab], ",", "."))
                    DA1->(msUnlock())
                else
                    cItem := soma1(fUltItem(cTabVen, "DA1")) // Proximo item disponivel

                    recLock("DA1", .T.)
                    DA1->DA1_FILIAL := xFilial("DA1")
                    DA1->DA1_CODTAB := cTabVen
                    DA1->DA1_ITEM   := cItem
                    DA1->DA1_CODPRO := SB1->B1_COD
                    DA1->DA1_PRCVEN := val(strTran(aLinha[nPosTab], ",", "."))
                    DA1->DA1_ATIVO  := "1"
                    DA1->DA1_TPOPER := "4"
                    DA1->DA1_QTDLOT := 999999.99
                    DA1->(msUnlock())
                endif
            else
                _aRet := {.F., "Tabela de venda " + cTabVen + " não encontrada."}
                exit
            endif
        endif
    next nY
return _aRet

// funcao para buscar o ultimo item da tabela de preço
static function fUltItem(cTabela, cTabSX3)
    local cLastItem := "0000"

    default cTabSX3 := "DA1"

    if cTabSX3 == "DA1"
        _cSelect := "SELECT MAX(DA1_ITEM) ZZ_MAXITE" + CRLF
        _cSelect += "  FROM " + retSqlName("DA1") + " (NOLOCK) " + CRLF
        _cSelect += " WHERE DA1_FILIAL = " + valToSql(xFilial("DA1")) + CRLF
        _cSelect += "   AND DA1_CODTAB = " + valToSql(cTabela) + CRLF
        _cSelect += "   AND D_E_L_E_T_ = '' " + CRLF
    elseif cTabSX3 == "AIB"
        _cSelect := "SELECT MAX(AIB_ITEM) ZZ_MAXITE " + CRLF
        _cSelect += "  FROM " + retSqlName("AIB") + " (NOLOCK) " + CRLF
        _cSelect += " WHERE AIB_FILIAL = " + valToSql(xFilial("AIB")) + CRLF
        _cSelect += "   AND AIB_CODTAB = " + valToSql(cTabela) + CRLF
        _cSelect += "   AND D_E_L_E_T_ = '' " + CRLF
    endif

    tcQuery _cSelect new alias "TABAUX"
    if !TABAUX->(EoF())
        cLastItem := TABAUX->ZZ_MAXITE
    endif
    TABAUX->(dbCloseArea())
return cLastItem

// Funcao para incluir/alterar item da tabela de preço de compra
static function fTabCompras(cCodFor, cLojFor, cCodTab, cEstTab, cCodPro, nPreco)
    local aRet   := {.T., ""}
//    local cCampo := ""

    // Cabecalho
    dbSelectArea("AIA")
    AIA->(dbSetOrder(1))
    AIA->(dbGoTop())
    if AIA->(msSeek(xFilial("AIA") + cCodFor + cLojFor + cCodTab))
        dbSelectArea("AIB")
        AIB->(dbSetOrder(2))
        AIB->(dbGoTop())
        if AIB->(msSeek(xFilial("AIB") + cCodFor + cLojFor + cCodTab + cCodPro)) // Tabela já possui o item
            recLock("AIB", .F.)
            if !empty(cEstTab) // Se o estado for informado no arquivo devera atualizar o preço do estado
                &("AIB->AIB_YPRC" + cEstTab) := nPreco
            else
                AIB->AIB_PRCCOM := nPreco
            endif
            AIB->(msUnlock())
        else
            recLock("AIB", .T.)
            cItem   := soma1(fUltItem(cCodTab, "AIB"))

            AIB->AIB_FILIAL := xFilial("AIB")
            AIB->AIB_CODFOR := cCodFor
            AIB->AIB_LOJFOR := cLojFor
            AIB->AIB_CODTAB := cCodTab
            AIB->AIB_ITEM   := cItem
            AIB->AIB_CODPRO := cCodPro
            AIB->AIB_QTDLOT := 999999.99
            AIB->AIB_INDLOT := '000000000999999.99'
            AIB->AIB_DATVIG := AIA->AIA_DATDE
            if !empty(cEstTab) // Se o estado for informado no arquivo devera atualizar o preço do estado
                &("AIB->AIB_YPRC" + cEstTab) := nPreco
            else
                AIB->AIB_PRCCOM := nPreco
            endif
            AIB->(msUnlock())
        endiF
    else // Tabela de preço de compra nao existe (Erro - Deve ser cadastrado previamente)
        aRet := {.F., "Tabela de preço de compra não encontrada. Tabela: " + cCodTab + " Fornecedor: " + cCodFor + " Loja: " + cLojFor}
    endif
return aRet

// Funcao para incluir lig. produto x fornecedor
static function fProdFornec(cCodFor, cLojFor, cProdFor, cCodTab)
    local _aRet := {.T., ""}

    default cCodFor := "" // Codigo Fornecedor
    default cLojFor := "" // Loja fornecedor
    default cCodTab := ""

    // incluir lig produto x fornecedor caso nao exista
    dbSelectArea("SA5")
    SA5->(dbSetOrder(1)) // A5_FILIAL+A5_FORNECE+A5_LOJA+A5_PRODUTO
    if SA5->(msSeek(xFilial("SA5") + cCodFor + cLojFor + SB1->B1_COD))
        if allTrim(SA5->A5_CODPRF) <> allTrim(cProdFor)
            recLock("SA5", .F.)
                SA5->A5_CODPRF := cProdFor
            SA5->(msUnlock())
        endif
    else
        DBSelectArea("SA2")
        SA2->(dbSetOrder(1))
        SA2->(msSeek(xFilial("SA2") + cCodFor + cLojFor))
        // Alterado pois o execauto padrao nao esta funcionando corretamente
        recLock("SA5", .T.)
            SA5->A5_FILIAL  := xFilial("SA5")
            SA5->A5_FORNECE := cCodFor
            SA5->A5_LOJA    := cLojFor
            SA5->A5_NOMEFOR := SA2->A2_NOME
            SA5->A5_PRODUTO := SB1->B1_COD
            SA5->A5_NOMPROD := SB1->B1_DESC
            SA5->A5_CODTAB  := cCodTab
            SA5->A5_CODPRF  := cProdFor
        SA5->(msUnlock())

        // oModel := FWLoadModel('MATA061')
        // oModel:SetOperation(3) // Inclusao
        // oModel:Activate()

        // // Cabeçalho
        // oModel:SetValue('MdFieldSA5', 'A5_PRODUTO', SB1->B1_COD)
        // oModel:SetValue('MdFieldSA5', 'A5_NOMPROD', SB1->B1_DESC)

        // // Grid
        // oModel:SetValue('MdGridSA5', 'A5_FORNECE', cCodFor)
        // oModel:SetValue('MdGridSA5', 'A5_LOJA'   , cLojFor)

        // If oModel:VldData()
        //     oModel:CommitData()
        //     if !empty(cCodTab)
        //         SA5->(dbSetOrder(1)) // A5_FILIAL+A5_FORNECE+A5_LOJA+A5_PRODUTO
        //         if SA5->(msSeek(xFilial("SA5") + cCodFor + cLojFor + SB1->B1_COD))
        //             if allTrim(SA5->A5_CODTAB) <> allTrim(cCodTab)
        //                 recLock("SA5", .F.)
        //                     SA5->A5_CODTAB := cCodTab
        //                 SA5->(msUnlock())
        //             endif
        //         endif
        //     endif
        // else
        //     _aRet := {.F., "Erro Produto x Fornecedor - Fornecedor: " + SA2->A2_COD + "/" + SA2->A2_LOJA + " Produto: " + SB1->B1_COD}
        // Endif

        // oModel:DeActivate()
        // oModel:Destroy()

        // lMsErroAuto := .F.
        // aLigForn    := {}
        // aadd(aLigForn, {"A5_FORNECE", cCodFor    , nil})
        // aadd(aLigForn, {"A5_LOJA"   , cLojFor    , nil})
        // aadd(aLigForn, {"A5_PRODUTO", SB1->B1_COD, nil})
        // aadd(aLigForn, {"A5_CODPRF" , cProdFor   , nil})

        // MSExecAuto({|x,y| mata060(x,y)}, aLigForn, 3)
        // if lMsErroAuto // erro
        //     _aRet := {.F., "Erro Produto x Fornecedor - Fornecedor: " + SA2->A2_COD + "/" + SA2->A2_LOJA + " Produto: " + SB1->B1_COD}
        // endif

        // if !empty(cCodTab)
        //     SA5->(msSeek(xFilial("SA5") + cCodFor + cLojFor + SB1->B1_COD))
        //     recLock("SA5", .F.)
        //     SA5->A5_CODTAB := cCodTab
        //     SA5->(msUnlock())
        // endif
    endif
return _aRet

// Funcao para verificar se o NCM do produto cadastrado possui TES inteligente cadastrado
static function fTESIntelig()
    local _aRet := {.T., ""}

    dbSelectArea("SFM")
    SFM->(dbSetOrder(4)) // FM_FILIAL+FM_POSIPI -> Personalizado
    if !SFM->(msSeek(xFilial("SFM") + SB1->B1_POSIPI))
        _aRet := {.F., "Não existe TES inteligente para o produto: " + SB1->B1_COD + " NCM: " + SB1->B1_POSIPI}
    endif
return _aRet

/*/{Protheus.doc} fCpoB2B
Funcao para verificar se algum campo que foi alterado devera atualizar o cadastro do produto no B2B
@type function
@version 12.1.25
@author Paulo Camata (Camatech)
@since 01/09/2020
@param aCabArq, Array, Cabecalho
/*/
static function fCpoB2B(aCabArq)
    // Campos que serao analisados. Caso seja necessario inserir validacao somente adicione o campo no array
    local aCampos := {"B1_CODBAR", "B1_DESC", "B4_01CODMA", "B1_PESO", "B5_LARG", "B5_COMPR", "B5_ALTURA", "B1_IPI", "B1_YCATECO", "A5_CODPRF"}
    local i, nPos

    for i := 1 to len(aCampos)
        nPos := aScan(aCabArq, {|x| allTrim(x) == aCampos[i]})

        if nPos > 0 // Encontrou
            return .T.
        endif
    next i

return .F.

/*/{Protheus.doc} fExisteSZ1
Funcao para verificar se o registro já existe na tabela SZ1
@type function
@version 12.1.25
@author Paulo Camata (Camatech)
@since 08/02/2021
/*/
static function fExisteSZ1(cEstFis, cCodPro)
    local cAliAux := getNextAlias()
    local nRecFis := 0

    BeginSql Alias cAliAux
        SELECT R_E_C_N_O_ RECN
          FROM %table:SZ1%
         WHERE Z1_FILIAL  = %xFilial:SZ1%
           AND Z1_UF      = %exp:cEstFis%
           AND Z1_PRODUTO = %exp:cCodPro%
           AND %notdel%
    EndSql

    if !(cAliAux)->(EoF()) .AND. (cAliAux)->RECN > 0
        nRecFis := (cAliAux)->RECN
    endif
    (cAliAux)->(dbCloseArea())
return nRecFis
