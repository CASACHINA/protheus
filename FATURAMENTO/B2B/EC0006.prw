#include "totvs.ch"

/*/{Protheus.doc} EC0006
Funcao para efetuar a integração dos pedidos pendentes do E-Commerce
@type function
@version 12.1.25
@author Paulo Camata (Camatech)
@since 27/07/2020
@param lJob, boolean, indica se a chamada da funcao foi via job
/*/
user function EC0006(lJob, cId)
    local cUrl, cPath, cFilPed
    local cTokPar := ""
    // local cStatus
    // local i
    
    private cLogErr  := "" // Log de retorno
    default lJob := .T.
    default cId     := ""

    if lJob
        conout("Inicio JOB EC0006")
    endif

    if lJob // Funcao é job
        RpcClearEnv()
        RpcSetType(3) // Nao consumir licenças
        RpcSetEnv("01", "010104") // Montando ambiente
    else
        procRegua(0)
        incProc("Processando dados! Aguarde...")
        incProc("Processando dados! Aguarde...")
    endif

    if !u_EC0001() // Atualizando token
        cLogErr := "Erro Geração Token"
        U_EC07LOG("PEDIDO", "E", cLogErr)

        if !lJob
            msgErro(cLogErr, "ERRO")
        endif
        
        return nil
    endif

    // cStatus := getNewPar("EC_STAPED", "A ENVIAR#A ENVIAR MASTER#A ENVIAR YAPAY") // Status a serem considerados paraimportacao dos pedidos
    cToken := allTrim(getMv("EC_TOKEN"))
    cTokPar := ""
    cTokPar := 'access_token=' + escape(cToken)

    cUrl    := getNewPar("EC_URLAPI", "https://casachinaempresas.commercesuite.com.br/web_api") // URL
    cPath   := "/orders/"

    // aStatus := Strtokarr2(allTrim(cStatus), "#", .F.)

    // for i := 1 to len(aStatus)
    //     if !u_EC0001() // Atualizando token
    //         cLogErr := "Erro Geração Token"
    //         U_EC07LOG("PEDIDO", "E", cLogErr)

    //         if !lJob
    //             msgErro(cLogErr, "ERRO")
    //         endif
            
    //         return nil
    //     endif

        if !u_EC0001() // Atualizando token
            cLogErr := "Erro Geração Token"
            U_EC07LOG("PEDIDO", "E", cLogErr)

            if !lJob
                msgErro(cLogErr, "ERRO")
            endif
            
            return nil
        endif

        if !Empty(cId)
            cFilPed := escape(cId) + "?" 
        else
            cFilPed := "?limit=50&status=" + escape("A ENVIAR%") + "&" // Filtro pedido: Limite 50
        endif

        oRest   := FWRest():New(cUrl)

        oRest:setPath(cPath + cFilPed + cTokPar)

        If (oRest:Get())
            cGetRest := oRest:GetResult()

            // Conout("GET Pedidos: " + cGetRet)
            oJsonRet := JsonObject():New()
            cJsonRet := oJsonRet:fromJson(cGetRest) // Convertendo json
            fPedidos(oJsonRet, lJob)
        else
            cLogErr := "Problema GetPedido: " + oRest:GetLastError()
            U_EC07LOG("PEDIDO", "E", cLogErr)

            if !lJob
                msgInfo(cLogErr, "ERRO")
            endif
            
            cRetorno := cLogErr
        endif
    // next i

    if lJob
        conout("Fim JOB EC0006")
    endif
return nil

/*/{Protheus.doc} fPedidos
Funcao para criar pedidos caso nao existam
@type function
@version 12.1.25
@author Paulo Camata (Camatech)
@since 23/08/2020
@param oObjJson, object, 
/*/
static function fPedidos(oObjJson, lJob)
    local cNumId, i
    local aPedidos := {}
    local lErro := .F.
    
    if !LockByName("FPEDIDOS", .T., .F.)
        return nil
    endif

    dbSelectArea("SC5")
    SC5->(DBOrderNickname("IDB2B"))

    aPedidos := oObjJson["Orders"] // Buscando todos os objetos pedidos
    for i := 1 to len(aPedidos)
        cNumId := cValToChar(aPedidos[i]["Order"]["id"]) // Numero ID do pedido

        if !SC5->(msSeek(xFilial("SC5") + padr(cNumId, tamSx3("C5_YIDB2B")[1]))) // Nao encontrou ID preenchido
            lRet := fInsPedido(cNumId, lJob) // Inserir pedido

            if !lRet
                lErro := .T.
            endif
        else
            lRet := fAltStatus(cNumId, lJob) // Alterar status pois o pedido ja existe na base (Houve algum problema na atualizacao)

            if lRet
                lRet := u_CCN410Env() // Enviando pedido para WMS (Envio automático)
            endif

            if !lRet
                lErro := .T.
            endif
        endif
    next i

    if !lErro
        U_EC07LOG("PEDIDO", "O", "") // Finalizado com sucesso
    endif

    UnlockByName("FPEDIDOS", .T., .F., .F.)
return .T.

/*/{Protheus.doc} fInsPedido
Funcao para criar pedidos caso nao existam
@type function
@version 12.1.25
@author Paulo Camata (Camatech)
@since 23/08/2020
@param cId, String, ID Pedido
/*/
static function fInsPedido(cId, lJob)
    local cNumPed  := GetSxeNum("SC5", "C5_NUM")
    local aCabec   := {}
    local aItens   := {}
    local aLinha   := {}
    local cArmCom  := getNewPar("EC_ARMCOM", "90")  // Armazem de estoque para o E-Commerce
    local cCondPag := "001" // Condicao de Pagto
    local cOper    := "08"  // VENDA DE MERCADORIA - 08 - TES Inteligente
    local cUrl     := getNewPar("EC_URLAPI", "https://casachinaempresas.commercesuite.com.br/web_api") // URL
    //Tipo de operação para os pedidos vindos do site
    local _cOperPd := getNewPar("EC_OPPADR", "08") 
    local cPath    := "/orders/" + cId + "/complete/?"
    local j, nCount

    private lMsErroAuto := .F.

    if u_EC0001() // Atualizando token
        cToken := allTrim(getMv("EC_TOKEN"))
        cTokPar := 'access_token=' + escape(cToken)
    else
        cLogErr := "Erro Geração Token"
        U_EC07LOG("PEDIDO", "E", cLogErr)
        
        if !lJob
            msgInfo(cLogErr, "ERRO")
        endif
        
        return .F.
    endif

    // Efetuando consulta completa do pedido - Listagem dos itens
    cGetPed  := HttpGet(cUrl + cPath + cTokPar)
    oJsonPed := JsonObject():New()
    oJsonPed:fromJson(cGetPed) // Convertendo json

    DBSelectArea("SA1")
    SA1->(dbOrderNickname("IDB2B"))
    cId := cValToChar(oJsonPed["Order"]["customer_id"])
    if !SA1->(msSeek(xFilial("SA1") + padR(cId, tamSx3("A1_YIDB2B")[1])))
        U_EC0004(lJob, cId)
        
        SA1->(dbOrderNickname("IDB2B"))
        if !SA1->(msSeek(xFilial("SA1") + padR(cId, tamSx3("A1_YIDB2B")[1])))
            cLogErr := "Cliente ID: " + cValToChar(oJsonPed["Order"]["customer_id"]) + " não encontrado. Será importado na próxima execução aut."
            U_EC07LOG("PEDIDO", "A", cLogErr)

            if lJob
                conout("Erro pedido. Erro: " + cLogErr)
            endif

            return .F. // Nao achou o cliente - Aguardar a proxima integracao
        endif
    endif

    // Atualizacao do endereco de entrega do cliente caso esteja diferente
    cEndereco := allTrim(oJsonPed["Order"]["Customer"]["CustomerAddresses"][1]["CustomerAddress"]["address"]) + ", "
    cEndereco += allTrim(oJsonPed["Order"]["Customer"]["CustomerAddresses"][1]["CustomerAddress"]["number"])
    cEndereco := DecodeUTF8(cEndereco, "cp1252")

    // Se endereco estiver diferente sera atualizado
    if allTrim(SA1->A1_END) <> allTrim(cEndereco)
        cNumero := DecodeUTF8(oJsonPed["Order"]["Customer"]["CustomerAddresses"][1]["CustomerAddress"]["number"], "cp1252")
        cComple := DecodeUTF8(oJsonPed["Order"]["Customer"]["CustomerAddresses"][1]["CustomerAddress"]["complement"], "cp1252")
        cBairro := DecodeUTF8(oJsonPed["Order"]["Customer"]["CustomerAddresses"][1]["CustomerAddress"]["neighborhood"], "cp1252")
        cCidade := DecodeUTF8(oJsonPed["Order"]["Customer"]["CustomerAddresses"][1]["CustomerAddress"]["city"], "cp1252")
        cUF     := DecodeUTF8(oJsonPed["Order"]["Customer"]["CustomerAddresses"][1]["CustomerAddress"]["state"], "cp1252")
        cCep    := strTran(DecodeUTF8(oJsonPed["Order"]["Customer"]["CustomerAddresses"][1]["CustomerAddress"]["zip_code"], "cp1252"), "-", "")

        recLock("SA1", .F.)
            SA1->A1_END     := upper(cEndereco)
            SA1->A1_YNUMERO := allTrim(cNumero)
            SA1->A1_COMPLEM := upper(allTrim(cComple))
            SA1->A1_BAIRRO  := upper(allTrim(cBairro))
            SA1->A1_MUN     := upper(allTrim(cCidade))
            SA1->A1_EST     := upper(allTrim(cUF))
            SA1->A1_CEP     := upper(allTrim(cCep))
        SA1->(msUnlock())
    EndIf
    

    // Lista de-para transportadoras
    cCodTra := ""
    lIndRes := .F.
    cTipFre := "C"

    cFreteB2b := DecodeUTF8(upper(oJsonPed["Order"]["shipment"]), "cp1252")
    if ("SEDEX" $ cFreteB2b)
        cCodTra := "000003"

    elseif ("FRETE GR" $ cFreteB2b)
        cCodTra := "000001"

    elseif ("ASAP LOG" $ cFreteB2b)
        cCodTra := "000004"

    elseif ("RETIRE" $ cFreteB2b)
        cCodTra := "000002"
        cTipFre := "S"
        
        // Tratamento de retira no CD
        if val(oJsonPed["Order"]["shipment_value"]) == 0 .and. val(oJsonPed["Order"]["total"]) < 250
           lIndRes := .T.
        endif
    else
        cCodTra := "000005"
    endif

    // Definindo condicao de pagto de acordo com parcelas e tipo
    cCondPag := "001"
    nTaxAdm  := 0
    cAdmFin  := ""
    idMetodo := -1

    // if (upper(oJsonPed["Order"]["payment_method_type"]) == "CREDIT_CARD")
    cMetodo  := upper(DecodeUTF8(upper(oJsonPed["Order"]["payment_method"]), "cp1252"))
    if (oJsonPed["Order"]["payment_method_id"] != '' .and. oJsonPed["Order"]["payment_method_id"] <> NIL) 
        idMetodo := upper(DecodeUTF8(upper(oJsonPed["Order"]["payment_method_id"]), "cp1252"))
    ENDIF

    // if ("CART" $ cMetodo)
        nQtdParc := val(oJsonPed["Order"]["installment"])
        if nQtdParc > 0 
            if nQtdParc == 1
                cCondPag := "B04"
            elseif nQtdParc == 2
                cCondPag := "B05"
            elseif nQtdParc == 3
                cCondPag := "B06"
            elseif nQtdParc == 4
                cCondPag := "B07"
            elseif nQtdParc == 5
                cCondPag := "B08"
            elseif nQtdParc == 6
                cCondPag := "B09"
            elseif nQtdParc == 7
                cCondPag := "B10"
            elseif nQtdParc == 8
                cCondPag := "B11"
            elseif nQtdParc == 9
                cCondPag := "B12"
            elseif nQtdParc == 10
                cCondPag := "B13"
            elseif nQtdParc == 11
                cCondPag := "B14"
            elseif nQtdParc == 12
                cCondPag := "B15"
            endif
        else
            cCondPag := "B04" // Cartao 1x => pagamento sera considerado por padrao qd cartao credito
        endif
        
        // Definindo a operador e bandeira
        cAdmFin := buscaAdm(idMetodo)

        if!empty(cAdmFin)
            cAdmFin := cAdmFin
        elseif "MASTERCARD" $ cMetodo
            cAdmFin := "001"
        elseif "VISA" $ cMetodo
            cAdmFin := "002"
        elseif "HIPER" $ cMetodo
            cAdmFin := "010"
        elseif "AMEX" $ cMetodo
            cAdmFin := "011"
        elseif "ELO" $ cMetodo
            cAdmFin := "016"
        elseif "YAPAY" $ cMetodo
            cAdmFin := "027"
        endif

        // Buscar taxa administrativa
        if !empty(cAdmFin)
            nTaxAdm := fGetTax(cAdmFin, nQtdParc)
        endif
    // endif

    cIdPed  := cValToChar(oJsonPed["Order"]["id"])
    cMenPed := DecodeUTF8(oJsonPed["Order"]["store_note"], "cp1252")

    nVlrFrete := val(oJsonPed["Order"]["shipment_value"]) // Itens vendidos
    nValDesc := val(oJsonPed["Order"]["partial_total"]) + nVlrFrete - val(oJsonPed["Order"]["total"])

    aadd(aCabec, {"C5_NUM"    , cNumPed     , nil})
    aadd(aCabec, {"C5_TIPO"   , "N"         , nil})
    aadd(aCabec, {"C5_CLIENTE", SA1->A1_COD , nil})
    aadd(aCabec, {"C5_LOJACLI", SA1->A1_LOJA, nil})
    aadd(aCabec, {"C5_LOJAENT", SA1->A1_LOJA, nil})
    aadd(aCabec, {"C5_CONDPAG", cCondPag    , nil})
    aadd(aCabec, {"C5_B2B"    , "S"         , nil})    
    aadd(aCabec, {"C5_YIDB2B" , cIdPed      , nil})
    aadd(aCabec, {"C5_ESPECI1", "Volume(s)" , nil})
    aadd(aCabec, {"C5_FRETE"  , nVlrFrete   , nil})
    aadd(aCabec, {"C5_TPFRETE", cTipFre     , nil})
    aadd(aCabec, {"C5_TRANSP" , cCodTra     , nil})

    // Campos personalizados
    aadd(aCabec, {"C5_YADMFIN", cAdmFin     , nil})
    aadd(aCabec, {"C5_YTAXADM", nTaxAdm     , nil})

    if (nValDesc > 0)
        aadd(aCabec, {"C5_DESCONT", nValDesc, nil})
    endif

    if lIndRes
        aadd(aCabec, {"C5_INDPRES" , "1"    , nil})
    endif

    aIteJson := oJsonPed["Order"]["ProductsSold"] // Itens vendidos

    dbSelectArea("SB1")
    SB1->(dbOrderNickname("IDB2B"))

    for j := 1 to len(aIteJson)
        // Buscando o produto pelo ID fornecido
        cIdProd := cValToChar(aIteJson[j]["ProductsSold"]["product_id"])
        if !SB1->(msSeek(xFilial("SB1") + padR(cIdProd, tamSx3("B1_YID")[1])))
            cLogErr := "Produto com ID " + cIdProd + " não encontrado na base de dados."

            if lJob
                conout("Erro pedido: " + cIdPed + " Erro: " + cLogErr)
            endif

            U_EC07LOG("PEDIDO", "E", cLogErr)
            return .F.
        endif

        // Buscando TES conforme TES inteligente
        cCodTes := MaTesInt(2, cOper, SA1->A1_COD, SA1->A1_LOJA, "C", SB1->B1_COD, , "F")
        
        if empty(cCodTes)
            // Gravando log para TES Inteligente nao encontrada
            cLogErr := "Não foi encontrado TES inteligente para OPER: " + cOper + " CLIENTE: " + SA1->A1_COD + "/" + SA1->A1_LOJA + " PRODUTO: " + SB1->B1_COD
            U_EC07LOG("PEDIDO", "A", cLogErr)
            if lJob
                conout("Erro pedido: " + cIdPed + " Erro: " + cLogErr)
            endif

            cCodTes := "602"
        endif

        nQtdIte := val(aIteJson[j]["ProductsSold"]["quantity"])
        nPrcIte := val(aIteJson[j]["ProductsSold"]["price"])

        aLinha  := {}
        aadd(aLinha,{"C6_ITEM"   , StrZero(j,2)     , nil})
        aadd(aLinha,{"C6_PRODUTO", SB1->B1_COD      , nil})
        aadd(aLinha,{"C6_OPER"   , _cOperPd     , nil})
        aadd(aLinha,{"C6_QTDVEN" , nQtdIte          , nil})
        aadd(aLinha,{"C6_PRCVEN" , nPrcIte          , nil})
        aadd(aLinha,{"C6_PRUNIT" , nPrcIte          , nil})
        aadd(aLinha,{"C6_VALOR"  , nQtdIte * nPrcIte, nil})
        aadd(aLinha,{"C6_TES"    , cCodTes          , nil})
        aadd(aLinha,{"C6_LOCAL"  , cArmCom          , nil})
        aadd(aItens, aLinha)
    next j
    
    lRet := .T.

    BEGIN TRANSACTION
        MSExecAuto({|a, b, c, d| MATA410(a, b, c, d)}, aCabec, aItens, 3, .F.)
        If !lMsErroAuto
            lRet := fAltStatus(cIdPed, lJob) // Alterando status do pedido para EM SEPARACAO
            
            if lRet
                lRet := u_CCN410Env() // Enviando pedido para WMS (Envio automático)
            endif
        else
            DisarmTransaction()

            cLogErr := ""
            aErroAuto := GetAutoGRLog()
            For nCount := 1 To Len(aErroAuto)
                cLogErr += StrTran(StrTran(aErroAuto[nCount], "<", ""), "-", "") + " "
            Next nCount

            if lJob
                conout("Erro pedido: " + cIdPed + " Erro: " + cLogErr)
            endif

            U_EC07LOG("PEDIDO", "E", cLogErr)
            lRet := .F.
        EndIf
    END TRANSACTION
return lRet

/*/{Protheus.doc} fAltStatus
Funcao para alterar o status do pedido no B2B para EM SEPARACAO (Nesse status o cliente não poderá efetuar alteração no pedido - Somente via contato)
@type function
@version 12.1.25
@author Paulo Camata (Camatech)
@since 23/08/2020
@param cId, String, Id Pedido para que o status seja alterado para EM SEPARACAO
/*/
static function fAltStatus(cId, lJob)
    local cIdStatus := getNewPar("EC_STASEP", "349") // 349 - EM SEPARACAO - Status criado para que o pedido nao possa ser alterado apos integrado
    local cUrl      := getNewPar("EC_URLAPI", "https://casachinaempresas.commercesuite.com.br/web_api") // URL
    local cPath     := "/orders/" + cId + "/?"
    local aHeader   := {}
    local oRest     := FWRest():New(cUrl)

    if u_EC0001() // Atualizando token
        cToken := allTrim(getMv("EC_TOKEN"))
        cTokPar := 'access_token=' + escape(cToken)
    else
        cLogErr := "Erro Geração Token"
        U_EC07LOG("PEDIDO", "E", cLogErr)
        msgInfo(cLogErr, "ERRO")
        
        return .F.
    endif

    oJson := JsonObject():New()
    oJson["Order"] := JsonObject():New()
    oJson["Order"]["status_id"] := cIdStatus

    AAdd(aHeader, "Content-Type: application/json; charset=ISO-8859-1")
    AAdd(aHeader, "Connection: keep-alive")
    AAdd(aHeader, "Accept: */*")

    oRest:setPath(cPath + cTokPar)
    If (oRest:Put(aHeader, oJson:ToJson())) // Efetua o PUT
        return .T.
    else
        cLogErr := "Erro ao atualizar status pedido " + cId + " Erro: " + allTrim(oRest:GetLastError())
        U_EC07LOG("PEDIDO", "E", cLogErr)
        return .F.
    endif

return .T.

/*/{Protheus.doc} EC006ENV
Funcao responsavel em atualizar as informacoes do pedido (Apos faturamento ou informar Rastreio)
@type function
@version 12.1.25
@author Paulo Camata (Camatech)
@since 14/09/2020
/*/
user function EC006ENV(aParametro)
    local cTokPar := ""
    local cPath, oRest, cUrl
    
    private cLogErr := "" // Log de retorno
    default aParametro := {.T., 0}

    nRecno := aParametro[2]
    lJob := aParametro[1]
    if lJob // Funcao é job
        RpcClearEnv()
        RpcSetType(3) // Nao consumir licenças
        RpcSetEnv("01", "010104") // Montando ambiente
    else
        procRegua(0)
        incProc("Processando dados! Aguarde...")
        incProc("Processando dados! Aguarde...")
    endif

    cUrl  := getNewPar("EC_URLAPI", "https://casachinaempresas.commercesuite.com.br/web_api") // URL
    oRest := FWRest():New(cUrl)

    if u_EC0001() // Atualizando token
        cToken := allTrim(getMv("EC_TOKEN"))
        cTokPar := 'access_token=' + escape(cToken)
    else
        cLogErr := "Erro Geração Token"
        U_EC07LOG("PEDIDO", "E", cLogErr)

        if !lJob
            msgErro(cLogErr, "ERRO")
        endif
        
        return nil
    endif

    DBSelectArea("SC5")
    SC5->(dbSetOrder(1))
    SC5->(dbGoTo(nRecno))

    cPath   := "/orders/" + allTrim(SC5->C5_YIDB2B) + "/?"

    oJson := JsonObject():New()
    oJson["Order"] := JsonObject():New()

    if !empty(SC5->C5_YRASTRE) // Status Enviado
        cDatEnv := DTOS(SC5->C5_YDTENVI)

        oJson["Order"]["status_id"]    := getNewPar("EC_STAENV", "342")
        oJson["Order"]["sending_code"] := allTrim(SC5->C5_YRASTRE)
        oJson["Order"]["sending_date"] := left(cDatEnv, 4) + "-" + SubStr(cDatEnv, 5, 2) + "-" + Right(cDatEnv, 2)
    
    elseif !empty(SC5->C5_NOTA) // Faturado - EM PREPARACAO
        oJson["Order"]["status_id"] := getNewPar("EC_STAPRE", "349") 
    endif

    aHeader := {}
    AAdd(aHeader, "Content-Type: application/json; charset=ISO-8859-1")
    AAdd(aHeader, "Connection: keep-alive")
    AAdd(aHeader, "Accept: */*")

    oRest:setPath(cPath + cTokPar)
    If (oRest:Put(aHeader, oJson:ToJson())) // Efetua o PUT
        return .T.
    else
        cLogErr := "Erro ao atualizar status pedido " + cId + " Erro: " + allTrim(oRest:GetLastError())
        U_EC07LOG("PEDIDO", "E", cLogErr)
        return .F.
    endif
return .F.

/*/{Protheus.doc} EC006NF
Funcao responsavel em atualizar as informacoes do pedido (Apos faturamento ou informar Rastreio)
@type function
@version 12.1.25
@author Paulo Camata (Camatech)
@since 14/09/2020
/*/
user function EC006NF(lJob, nRecno, lEnvJob)
    local cUrl
    local cTokPar := ""
    local oRest   := FWRest():New(cUrl)
    local aHeader := {}
    local cPath
    
    private cLogErr := "" // Log de retorno
    default lJob    := .T.
    default lEnvJob := .F.

    if lJob // Funcao é job
        RpcClearEnv()
        RpcSetType(3) // Nao consumir licenças
        RpcSetEnv("01", "010104") // Montando ambiente
    elseIf !lEnvJob
        procRegua(0)
        incProc("Processando dados! Aguarde...")
        incProc("Processando dados! Aguarde...")
    endif

    cUrl := getNewPar("EC_URLAPI", "https://casachinaempresas.commercesuite.com.br/web_api") // URL

    if u_EC0001() // Atualizando token
        cToken := allTrim(getMv("EC_TOKEN"))
        cTokPar := 'access_token=' + escape(cToken)
    else
        cLogErr := "Erro Geração Token"
        U_EC07LOG("PEDIDO", "E", cLogErr)

        if !lJob .and. !lEnvJob
            msgErro(cLogErr, "ERRO")
        endif
        
        return nil
    endif

    DBSelectArea("SC5")
    SC5->(dbSetOrder(1))
    SC5->(dbGoTo(nRecno))

    DBSelectArea("SD2")
    SD2->(dbSetOrder(3))

    DBSelectArea("SB1")
    SB1->(dbSetOrder(1))

    DBSelectArea("SF2")
    SF2->(dbSetOrder(1))
    if SF2->(msSeek(xFilial("SF2") + SC5->C5_NOTA + SC5->C5_SERIE + SC5->C5_CLIENTE + SC5->C5_LOJACLI)) .and. !empty(SF2->F2_CHVNFE)
        cXmlNf := fGetXml()
        cDatEmi := DTOS(SF2->F2_EMISSAO)

        cPath   := "/orders/" + allTrim(SC5->C5_YIDB2B) + "/invoices/"

        oJson := JsonObject():New()
        oJson["issue_date"] := left(cDatEmi, 4) + "-" + SubStr(cDatEmi, 5, 2) + "-" + Right(cDatEmi, 2)
        oJson["number"]     := padL(allTrim(SF2->F2_DOC), 9, "0")
        oJson["serie"]      := allTrim(SF2->F2_SERIE)
        oJson["value"]      := SF2->F2_VALMERC
        oJson["key"]        := SF2->F2_CHVNFE
        oJson["xml_danfe"]  := cXmlNf

        aProds := {} // Array json de produtos
        SD2->(msSeek(xFilial("SD2") + SF2->F2_DOC + SF2->F2_SERIE + SF2->F2_CLIENTE + SF2->F2_LOJA))

        while !SD2->(EoF()) .and. allTrim(SD2->D2_FILIAL + SD2->D2_DOC + SD2->D2_SERIE + SD2->D2_CLIENTE + SD2->D2_LOJA) ==;
              allTrim(SF2->F2_FILIAL + SF2->F2_DOC + SF2->F2_SERIE + SF2->F2_CLIENTE + SF2->F2_LOJA)

            SB1->(msSeek(xFilial("SB1") + SD2->D2_COD))

            aAdd(aProds, JsonObject():New())
            nPos := len(aProds)

            aProds[nPos]["product_id"]   := val(SB1->B1_YID)
            aProds[nPos]["variation_id"] := 0
            aProds[nPos]["cfop"]         := val(SD2->D2_CF)

            SD2->(dbSkip())
        endDo

        oJson["ProductCfop"] := JsonObject():New()
        oJson["ProductCfop"] := aProds

        AAdd(aHeader, "Content-Type: application/json; charset=ISO-8859-1")
        AAdd(aHeader, "Connection: keep-alive")
        AAdd(aHeader, "Accept: */*")

        cJson := oJson:ToJson()
        cJson := EncodeUtf8(cJson, "iso8859-1")
        cHeaRet := ""

        cPostRet := HttpPost(cUrl + cPath, cTokPar, cJson, 120, aHeader, @cHeaRet) // Efetua o POST

        If !empty(cPostRet) // Retorno
            Conout("POST Cad. Nota Fiscal: " + cPostRet)
            oJsonRet := JsonObject():New()
            ret := oJsonRet:fromJson(cPostRet) // Convertendo json
            if (oJsonRet["code"] == 200 .or. oJsonRet["code"] == 201) // OK
                BEGIN TRANSACTION
                    if U_EC006ENV({.F., SC5->(recno())}) // Alterando status pedido tray
                        recLock("SC5", .F.)
                            SC5->C5_YENVNFE := "S"
                        SC5->(msUnlock())
                    endif
                END TRANSACTION
            else
                // Verifica se ja possui nota cadastrada (Se houver somente deverá ser alterado o status e campo no protheus)
                if oJsonRet["code"] == 400 .and. ("ALREADY" $ upper(oJsonRet["causes"][1]))
                    BEGIN TRANSACTION
                        if U_EC006ENV({.F., SC5->(recno())}) // Alterando status pedido tray
                            recLock("SC5", .F.)
                                SC5->C5_YENVNFE := "S"
                            SC5->(msUnlock())
                        endif
                    END TRANSACTION
                endif
            endif

            return .T.
        else
            cLogErr := "Erro ao atualizar status pedido " + SC5->C5_YIDB2B + " Erro: " + allTrim(oRest:GetLastError())
            U_EC07LOG("PEDIDO", "E", cLogErr)
            return .F.
        endif
    endif
return .F.

/*/{Protheus.doc} fGetXml
Funcao para retornar o xml da NF
@type function
@version 12.1.25
@author Paulo Camata (Camatech)
@since 14/09/2020
/*/
static function fGetXml()
    local _cXml   := ""
    local cIdEnt  := RetIdEnti() // id da empresa
    local cNumNfe := SF2->F2_SERIE + SF2->F2_DOC

    BeginSql Alias "XMLNFE"
        %noparser%
        SELECT cast(cast(XML_SIG as varbinary(max))as varchar(max)) XML
          FROM SPED.dbo.SPED050 
         WHERE ID_ENT = %Exp:cIdEnt%
           AND NFE_ID = %Exp:cNumNfe%
           AND %notdel%
    EndSql

    if !XMLNFE->(EoF())
        _cXml := XMLNFE->XML
    endif
    XMLNFE->(dbCloseArea())
return _cXml

/*/{Protheus.doc} EC0006J
Funcao para ser chamada via JOB
@type function
@version 12.1.25
@author Paulo Camata (Camatech)
@since 14/09/2020
/*/
user function EC0006J()
    U_EC0006(.T.)
return nil

/*/{Protheus.doc} EC006JNF
Funcao de job para enviar NF para portal Tray
@type function
@version 12.1.25
@author Paulo Camata (Camatech)
@since 05/10/2020
/*/
user function EC006JNF()
    conout("Inicio JOB EC006JNF........")

    RpcClearEnv()
    RpcSetType(3) // Nao consumir licenças
    RpcSetEnv("01", "010104") // Montando ambiente
    
    dbSelectArea("SC5")

    BeginSql Alias "PEDNF"
        SELECT SC5.R_E_C_N_O_ RECN
          FROM %table:SC5% SC5
          JOIN %table:SF2% SF2
            ON F2_FILIAL  = %xFilial:SF2%
           AND F2_DOC     = C5_NOTA
           AND F2_SERIE   = C5_SERIE
           AND F2_CLIENTE = C5_CLIENTE
           AND F2_LOJA    = C5_LOJACLI
           AND F2_CHVNFE  <> ''
           AND SF2.%notdel%
         WHERE SC5.%notdel%
           AND C5_FILIAL  = %xFilial:SC5%
           AND C5_YIDB2B  <> ''
           AND C5_B2B     = 'S'
           AND C5_YENVNFE <> 'S'
    EndSql
    
    while !PEDNF->(EoF())
        U_EC006NF(.F., PEDNF->RECN, .T.) // Funcao para enviar a NF para a tray

        PEDNF->(dbSkip())
    endDo
    PEDNF->(DBCloseArea())
    
    conout("Fim JOB EC006JNF........")
return nil

/*/{Protheus.doc} fGetTax
Funcao para buscar a taxa da adm financeira
@type function
@version 12.1.25
@author Paulo Camata (Camatech)
@since 24/11/2020
@param cAdmFin, character, param_description
@param nQtdParc, numeric, param_description
/*/
static function fGetTax(cAdmFin, nQtdParc)
    local nTaxa := 0
    local cAliAux := getNextAlias()

    BeginSql Alias cAliAux
        SELECT MEN_TAXADM
          FROM %table:MEN% MEN (NOLOCK)
         WHERE MEN_FILIAL = %xFilial:MEN%
           AND MEN_CODADM = %Exp:cAdmFin%
           AND MEN_PARINI <= %Exp:nQtdParc%
           AND MEN_PARFIN >= %Exp:nQtdParc%
           AND %NOTDEL%
    EndSql

    if !(cAliAux)->(EoF()) .and. (cAliAux)->MEN_TAXADM > 0
        nTaxa := (cAliAux)->MEN_TAXADM
    endif
    (cAliAux)->(DBCloseArea())
return nTaxa

static function buscaAdm(idMetodo)
    local idAdm := ''
    local cAliAux := getNextAlias()

    BeginSql Alias cAliAux
        SELECT AE_COD
          FROM %table:SAE% SAE (NOLOCK)
         WHERE AE_FILIAL = %xFilial:SAE%
           AND AE_YECOM = %Exp:idMetodo%
           AND %NOTDEL%
    EndSql

    if !(cAliAux)->(EoF()) 
        idAdm := (cAliAux)->AE_COD
    endif
    (cAliAux)->(DBCloseArea())

return idAdm
