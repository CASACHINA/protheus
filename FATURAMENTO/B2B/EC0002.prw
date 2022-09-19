#include "totvs.ch"

/*/{Protheus.doc} EC0002
Funcao para efetuar a integração dos produtos com a plataforma E-Commerce
@type function
@version 12.1.25
@author Paulo Camata (Camatech)
@since 27/07/2020
/*/
user function EC0002(nRecInf, lJob, lAll)
    private aHeader := {}
    private cWhere  := ""
    private cLogErr  := "" // Log de retorno
    private cAliProd := getNextAlias()
    private cPath    := "/products/"
    private nRecPrd, cArmCom, cTabCom, cUrl

    default nRecInf := 0
    default lJob    := .T.
    default lAll    := .F.

    if lJob // Funcao é job
        conout("Inicio JOB EC0002")
        RpcClearEnv()
        RpcSetType(3) // Nao consumir licenças
        RpcSetEnv("01", "010104") // Montando ambiente
    else
        procRegua(0)
        incProc("Processando dados! Aguarde...")
        incProc("Processando dados! Aguarde...")
    endif

    cArmCom := allTrim(getNewPar("EC_ARMCOM", "90"))  // Armazem de estoque para o E-Commerce
    cTabCom := allTrim(getNewPar("EC_TABCOM", "003")) // Tabela de preço para o E-Commerce
    cUrl    := allTrim(getNewPar("EC_URLAPI", "https://casachinaempresas.commercesuite.com.br/web_api")) // URL

    cFilAnt := "010104" // filial CD
    nRecPrd := nRecInf

    if u_EC0001() // Atualizando token
        cToken := allTrim(getMv("EC_TOKEN"))
        cGetPar := 'access_token=' + escape(cToken)
    else
        cMenErr := "Erro Geração Token"
        // U_EC07LOG("PRODUTO", "E", cMenErr)
        
        if !Job
            msgInfo(cMenErr, "ERRO")
        endif

        return nil
    endif
    
    AAdd(aHeader, "Content-Type: application/json; charset=ISO-8859-1")
    AAdd(aHeader, "Connection: keep-alive")
    AAdd(aHeader, "Accept: */*")

    if lAll
        cWhere := "% AND B1_YID <> '' %" // Atualizar todos os já cadastrados
    elseif empty(nRecPrd) // Listar produtos sem ID
        cWhere := "% AND (B1_YID = '' OR B1_YALTB2B = 'S' OR ISNULL(DA1_PRCVEN, 99999.99) <> B1_YPRVB2B OR B1_YESTB2B = 'S') %" // Atualizar os nao cadastrados, com flag de alterado ou com preco na tabela diferente do site
    else
        cWhere := "% AND SB1.R_E_C_N_O_ = " + cValToChar(nRecPrd) + " %"
    endif

    // Buscar todos os produtos marcados como B2B porém não integrados (CAMPO B1_YIDCOM em branco)
    // Será considerado todos os saldos (Filiais) no armazem 90 (EC_ARMCOM)
    BeginSql Alias cAliProd
        SELECT B1_DESC, B4_POSIPI, ISNULL(ZZ2_ID, 0) ID_CATEGORIA, AY2_DESCR MARCA,
               (B1_PESO * 1000) B1_PESO, B5_LARG, B5_COMPR, B5_ALTURA, ISNULL(B2_QATU - B2_RESERVA, 0) B2_QATU, 0 B4_IPI, B1_COD,
               ISNULL(DA1_PRCVEN, 99999.99) DA1_PRCVEN, SB1.R_E_C_N_O_ B1_RECN, B1_YID, B1_YPRVB2B, 
               IIF(B4_CODBAR <> '', B4_CODBAR, B1_CODBAR) B4_CODBAR,
               ISNULL((SELECT TOP 1 A5_CODPRF
	                     FROM %Table:SA5% SA5 (NOLOCK)
		                WHERE A5_FILIAL = LEFT(B1_FILIAL, 4)
		                  AND A5_PRODUTO = B1_COD
		                  AND %notdel%), '') REFERENCIA
          FROM %Table:SB1% SB1 (NOLOCK)
          JOIN %Table:SB4% SB4 (NOLOCK)
            ON B4_FILIAL = %xFilial:SB4%
           AND B4_COD = B1_COD
           AND B4_STATUS = 'A'
           AND SB4.%notdel%
          LEFT JOIN %Table:AY2% AY2 (NOLOCK)
            ON AY2_FILIAL = %xFilial:AY2%
           AND AY2_CODIGO = B4_01CODMA
           AND AY2.%notdel%
          LEFT JOIN %Table:ZZ2% ZZ2 (NOLOCK)
            ON ZZ2_FILIAL = %xFilial:ZZ2%
           AND ZZ2_CODIGO = B1_YCATECO
           AND ZZ2.%notdel%
          LEFT JOIN %Table:SB2% SB2 (NOLOCK)
            ON B2_FILIAL = %xFilial:SB2%
           AND B2_LOCAL = %exp:cArmCom%
           AND B2_COD = B4_COD
           AND SB2.%notdel%
          LEFT JOIN %Table:DA1% DA1 (NOLOCK)
            ON DA1_FILIAL = B4_FILIAL
           AND DA1_CODTAB = %exp:cTabCom%
           AND DA1_CODPRO = B4_COD
           AND DA1.%notdel%
          LEFT JOIN %Table:SB5% SB5 (NOLOCK)
            ON B5_FILIAL = B1_FILIAL
           AND B5_COD = B1_COD
           AND SB5.%notdel%
         WHERE B1_FILIAL = %xFilial:SB1%
           AND B1_MSBLQL <> '1'
           AND B1_YB2B = 'S'
               %Exp:cWhere%
         ORDER BY B1_COD
    EndSql

    if (cAliProd)->(EoF()) // Nao foi encontrato nenhum registro
        (cAliProd)->(DbCloseArea())
        cMenErr := "Não foi encontrato nenhum produto apto a integrar."
        // U_EC07LOG("PRODUTO", "E", cMenErr)

        if !lJob
            HELP(' ', 1, "Não Encontrado", , "Nenhum produto foi encontrato para atualizar.", 2, 0,,,,,, {"Verifique se o campo B2B está com S ou foi informado categoria B2B (Obrigatórios)."})
        endif
    else
        Processa({|| fExecDados(lJob)}, "Atualizando produtos. Aguarde...") // Funcao para executar os dados
    endif

    if !empty(cLogErr)
        // U_EC07LOG("PRODUTO", "E", cLogErr)

        if !lJob
            msgInfo(cLogErr, "Erro Cad. Produto")
        endif
    elseif !lJob
        // U_EC07LOG("PRODUTO", "O", "")
        msgInfo("Atualização efetuada com sucesso!", "E-Commerce")
    endif

    if lJob
        RpcClearEnv() // Finalizando conexao caso seja job
        conout("Fim JOB EC0002")
    endif
return nil

/*/{Protheus.doc} fExecDados
Funcao para processamento da regua
@type function
@version 12.1.25
@author Paulo Camata (Camatech)
@since 19/10/2020
@param lJob, logical, param_description
/*/
static function fExecDados(lJob)
    local nTotReg := 0
    local nRegAtu := 0
    local lCatID  := .F.

    while !(cAliProd)->(EoF())
        nTotReg++

        if empty((cAliProd)->ID_CATEGORIA)
            lCatID := .T.
        endif

        (cAliProd)->(dbSkip())
    endDo

    if lCatID
        U_EC0003EN()
    endif

    procRegua(nTotReg + 1) // Tamanho da regua de processamento
	incproc("Processando registros... aguarde")

    (cAliProd)->(dbGoTop())
    // Montagem do JSON com as informações necessarias
    while !(cAliProd)->(EoF())
        nRegAtu++

        incProc("Processando registro " + cValToChar(nRegAtu) + " / " + cValToChar(nTotReg))

        oJson := fGetJson() // Gerar Json do produto para envio conforme dado do produto

        // Verificando se categoria foi informada
        if (fValidPrd(lJob))
            if empty((cAliProd)->B1_YID)
                cRet := fPost(cUrl, cPath, cGetPar, oJson:toJson(), aHeader, lJob) // Efetuar o post
            else
                cRet := fPut(cUrl, cPath + allTrim((cAliProd)->B1_YID) + "/", cGetPar, oJson:toJson(), aHeader, lJob) // Efetuar o post
            endif

            if (cRet == "401") // Unauthorized
                if u_EC0001() // Atualizando token
                    cToken := allTrim(getMv("EC_TOKEN"))
                    cGetPar := 'access_token=' + escape(cToken)
                else
                    cMenErr := "Erro Geração Token"
                    // U_EC07LOG("PRODUTO", "E", cMenErr)
                    
                    if !Job
                        msgInfo(cMenErr, "ERRO")
                    endif
                    (cAliProd)->(DbCloseArea())
                    return nil
                endif

                if empty((cAliProd)->B1_YID)
                    cRet := fPost(cUrl, cPath, cGetPar, oJson:toJson(), aHeader, lJob) // Efetuar o post
                else
                    cRet := fPut(cUrl, cPath + allTrim((cAliProd)->B1_YID) + "/", cGetPar, oJson:toJson(), aHeader, lJob) // Efetuar o post
                endif
            endif
        endif

        (cAliProd)->(dbSkip())
    endDo
    (cAliProd)->(DbCloseArea())
return nil

/*/{Protheus.doc} fValidPrd
Funcao para efetuar a validacao do produto
@type function
@version 12.1.25
@author Paulo Camata (Camatech)
@since 27/07/2020
/*/
static function fValidPrd(lJob)
    if ((cAliProd)->ID_CATEGORIA == 0) // Sem categoria
        cLogErr += "Produto " + allTrim((cAliProd)->B1_COD) + " - " + allTrim((cAliProd)->B1_DESC) + " NÃO POSSUI CATEGORIA (B1_YCATECO)." + CRLF
        // U_EC07LOG("PRODUTO", "E", cLogErr)
        if !lJob
            HELP(' ', 1, "Categoria", , "Cagetoria não informado. Produto: " + allTrim((cAliProd)->B1_COD), 2, 0,,,,,, {"Para produtos B2B a categoria é obrigatória."})
        endif

        return .F.
    endif

    if (cAliProd)->B1_PESO == 0
        cLogErr += "Produto " + allTrim((cAliProd)->B1_COD) + " - " + allTrim((cAliProd)->B1_DESC) + " NAO POSSUI PESO (B1_PESO)." + CRLF
        // U_EC07LOG("PRODUTO", "E", cLogErr)
        if !lJob
            HELP(' ', 1, "Peso", , "Peso do produto " + allTrim((cAliProd)->B1_COD) + " não informado.", 2, 0,,,,,, {"Para produtos B2B o peso é obrigatório."})
        endif
        
        return .F.
    endif

    if (cAliProd)->B5_LARG == 0 .or. (cAliProd)->B5_COMPR == 0 .or. (cAliProd)->B5_ALTURA == 0
        cLogErr += "Produto " + allTrim((cAliProd)->B1_COD) + " - " + allTrim((cAliProd)->B1_DESC) + " não possui dimensões informadas (B5_LARG, B5_COMPR, B5_ALTURA)." + CRLF
        // U_EC07LOG("PRODUTO", "E", cLogErr)
        if !lJob
            HELP(' ', 1, "Dimensões Inválidas", , "Dimensões do produto " + allTrim((cAliProd)->B1_COD) + " não informado.", 2, 0,,,,,, {"Para produtos B2B as dimensões são obrigatórias. Complemento de produto (B5_LARG, B5_COMPR, B5_ALTURA)"})
        endif
        
        return .F.
    endif
return .T.

/*/{Protheus.doc} fGetJson
Funcao responsavel em enviar os dados do produto para a plataforma do E-Commerce
@type function
@version 12.1.25
@author Paulo Camata (Camatech)
@since 27/07/2020
/*/
static function fGetJson()
    local oJson := JsonObject():New()
    local cDesc := allTrim((cAliProd)->B1_DESC)
    local cDescComp := ""

    dbSelectArea("SB1")
    SB1->(dbSetOrder(1))
    SB1->(dbGoTo((cAliProd)->B1_RECN)) // Posicionando no produto

    oJson["Product"] := JsonObject():New()
    oJson["Product"]["ean"] := allTrim((cAliProd)->B4_CODBAR)
    oJson["Product"]["name"] := cDesc
    oJson["Product"]["description_small"] := cDesc
    oJson["Product"]["ncm"] := alltrim((cAliProd)->B4_POSIPI)
    oJson["Product"]["price"] := (cAliProd)->DA1_PRCVEN
    oJson["Product"]["ipi_value"] := (cAliProd)->B4_IPI
    oJson["Product"]["category_id"] := (cAliProd)->ID_CATEGORIA
 
    if !empty((cAliProd)->MARCA)
        oJson["Product"]["brand"] := allTrim((cAliProd)->MARCA)
    endif

    if !empty((cAliProd)->REFERENCIA)
        oJson["Product"]["reference"] := allTrim((cAliProd)->REFERENCIA)
    endif

    if ((cAliProd)->B5_ALTURA > 0)
        oJson["Product"]["height"] := round((cAliProd)->B5_ALTURA, 0)
        cDescComp += "<b>Altura:</b> " + cValToChar(oJson["Product"]["height"]) + "cm <br>"
    endif

    if ((cAliProd)->B5_LARG > 0)
        oJson["Product"]["length"] := round((cAliProd)->B5_LARG, 0)
        cDescComp += "<b>Largura:</b> " + cValToChar(oJson["Product"]["length"]) + "cm <br>"
    endif

    if ((cAliProd)->B5_COMPR > 0)
        oJson["Product"]["width"] := round((cAliProd)->B5_COMPR, 0)
        cDescComp += "<b>Comprimento:</b> " + cValToChar(oJson["Product"]["width"]) + "cm <br>"
    endif
    
    if ((cAliProd)->B1_PESO > 0)
        oJson["Product"]["weight"] := round((cAliProd)->B1_PESO, 0)
        cDescComp += "<b>Peso:</b> " + cValToChar(oJson["Product"]["weight"]) + "g <br>"
    endif
    
    if empty(SB1->B1_YDESDET)
        if (!Empty(cDescComp))
            cDescComp := "<b>Dimensões com embalagem:</b> <br>" + cDescComp
            cDescComp := cDesc + "<br><br>" + cDescComp

            oJson["Product"]["description"] := cDescComp
        endif
    else
        oJson["Product"]["description"] := strTran(allTrim(SB1->B1_YDESDET), chr(13) + chr(10), "<br>")
    endif

    oJson["Product"]["stock"] := (cAliProd)->B2_QATU
    oJson["Product"]["available"] := 1
    oJson["Product"]["virtual_product"] := 0
return oJson

/*/{Protheus.doc} fPost
Funcao para efetuara o post
@type function
@version 12.1.25
@author Paulo Camata (Camatech)
@since 10/08/2020
/*/
static function fPost(cUrlPost, cPath, cGetPar, cJson, aHeader, lJob)
    local cRetorno := ""
    local cHeaRet := ""

    cJson := EncodeUtf8(cJson, "iso8859-1")

    cPostRet := HttpPost(cUrlPost + cPath, cGetPar, cJson, 120, aHeader, @cHeaRet) // Efetua o POST

    If !empty(cPostRet) // Retorno
        Conout("POST Produto: " + cPostRet)
        oJsonRet := JsonObject():New()
        ret := oJsonRet:fromJson(cPostRet) // Convertendo json
        if (oJsonRet["code"] == 200 .or. oJsonRet["code"] == 201) // OK
            // Atualizando ID gerado na TRAY
            recLock("SB1", .F.)
                SB1->B1_YID := oJsonRet["id"]
                SB1->B1_YALTB2B := "N"
                SB1->B1_YESTB2B := "N"
                SB1->B1_YPRVB2B := (cAliProd)->DA1_PRCVEN
            SB1->(msUnlock())

            cRetorno := "200"
        elseif oJsonRet["code"] == 401
            cRetorno := "401"

        else
            cLogErr := "Erro " + cValToChar(cValToChar(oJsonRet["code"])) + ". Produto: " + allTrim((cAliProd)->B1_COD) + ". Causa: " + oJsonRet:GetJsonText("causes") + CRLF
            // U_EC07LOG("PRODUTO", "E", cLogErr)

            if !lJob
                msgInfo(cLogErr, "ERRO")
            endif
            cRetorno := cLogErr
        endif
    else
        cLogErr := "Problema post: " + cHeaRet
        // U_EC07LOG("PRODUTO", "E", cLogErr)

        if !lJob
            msgInfo(cLogErr, "ERRO")
        endif
        cRetorno := cLogErr
    endif
return cRetorno

/*/{Protheus.doc} fPut
Funcao para efetuar a atualizacao (PUT)
@type function
@version 12.1.25
@author Paulo Camata (Camatech)
@since 10/08/2020
/*/
static function fPut(cUrlPut, cPath, cGetPar, cJson, aHeader, lJob)
    local oRest := FWRest():New(cUrlPut)
    local cRet  := ""

    cJson := EncodeUtf8(cJson, "iso8859-1")

    oRest:setPath(cPath + "?" + cGetPar)
    If (oRest:Put(aHeader, cJson)) // Efetua o POST
        Conout("PUT PRODUTO: " + oRest:GetResult())
        oJsonRet := JsonObject():New()
        ret := oJsonRet:fromJson(oRest:GetResult()) // Convertendo json
        if (oJsonRet["code"] == 200 .or. oJsonRet["code"] == 201) // OK
            
            recLock("SB1", .F.) 
                SB1->B1_YALTB2B := "N" // Atualizando campo para nao alterar novamente
                SB1->B1_YESTB2B := "N"
                SB1->B1_YPRVB2B := (cAliProd)->DA1_PRCVEN // Preco de venda
            SB1->(msUnlock())
            cRet := "200"

        elseif oJsonRet["code"] == 401
            cRet := "401"

        else
            cLogErr := "Erro " + cValToChar(cValToChar(oJsonRet["code"])) + ". Produto: " + allTrim((cAliProd)->B1_COD) + ". Causa: " + oJsonRet:GetJsonText("causes") + CRLF
            // U_EC07LOG("PRODUTO", "E", cLogErr)

            if !lJob
                msgInfo(cLogErr, "ERRO")
            endif
            cRet := cLogErr
        endif
    Else
        oJsonRet := JsonObject():New()
        ret := oJsonRet:fromJson(oRest:GetResult()) // Convertendo json

        cLogErr := "Erro " + cValToChar(cValToChar(oJsonRet["code"])) + ". Produto: " + allTrim((cAliProd)->B1_COD) + ". Causa: " + oJsonRet:GetJsonText("causes") + CRLF
        // U_EC07LOG("PRODUTO", "E", cLogErr)

        if !lJob
            msgInfo(cLogErr, "ERRO")
        endif
        cRet := cLogErr
    endif
return cRet

/*/{Protheus.doc} EC0002PR
Funcao chamada pelo PE MTA010MNU
@type function
@version 12.1.25
@author Paulo Camata (Camatech)
@since 27/07/2020
/*/
user function EC0002PR()
    u_EC0002(SB1->(Recno()), .F., .F.)
return nil

/*/{Protheus.doc} EC0002AL
Funcao chamada pelo PE MTA010MNU Para atualizar todos os produtos
@type function
@version 12.1.25
@author Paulo Camata (Camatech)
@since 27/07/2020
/*/
user function EC0002AL()
    if msgYesNo("Confirma atualização de todos os itens?")
        u_EC0002(0, .F., .T.)
    endif
    // u_EC0002(0, .T., .F.)
return nil

/*/{Protheus.doc} EC0002J
Funcao chamada pelo Schedule
@type function
@version 12.1.25
@author Paulo Camata (Camatech)
@since 27/07/2020
/*/
user function EC0002J()
    u_EC0002(0, .T., .F.)
return nil