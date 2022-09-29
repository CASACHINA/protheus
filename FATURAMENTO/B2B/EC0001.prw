/*/{Protheus.doc} EC0001
Funcao para efetuar a atualizacao do token de conexão com a Tray caso necessário
@type function
@version 12.1.25
@author Paulo Camata (Camatech)
@since 27/07/2020
/*/
user function EC0001()
    local cVencto := getMv("EC_EXPIRAT") // DateTime vencimento token E-Commerce
    local lRet := .F.

    cFilAnt := "010104" // filial CD

    if empty(cVencto) .or. cVencto <= fwTimeStamp() // Token vencido
        lRet := fGerarToken() // Gerar novo token
    else
        lRet := .T.
    endif
return lRet

/*/{Protheus.doc} fGerarToken
Funcao para gerar um novo token de acesos ao E-Commerce
@type function
@version 12.1.25
@author Paulo Camata (Camatech)
@since 27/07/2020
/*/
static function fGerarToken()
    local cUrl    := getNewPar("EC_URLAPI", "https://casachinaempresas.commercesuite.com.br/web_api") // URL
    local cPath   := "/auth/"
    Local aHeader := {}
    local cHeaRet := ""

    // PREENCHE CABEÇALHO DA REQUISIÇÃO
    AAdd(aHeader, "Content-Type: application/json; charset=UTF-8")
    AAdd(aHeader, "Accept: */*")
    
    cPostRet := HttpPost(cUrl + cPath, , getJson(), 120, aHeader, @cHeaRet)

    if !empty(cPostRet)
        //conout("POST Auth: " + cPostRet)
        oJsonRet := JsonObject():New()
        ret := oJsonRet:fromJson(cPostRet) // Convertendo json
        if (oJsonRet["code"] == 200 .or. oJsonRet["code"] == 201) // OK
            cToken := oJsonRet["access_token"]
            cExpir := oJsonRet["date_expiration_access_token"]
            cRefre := oJsonRet["refresh_token"]

            // Retirando caracteres expir
            cExpir := StrTran(cExpir, "-","")
            cExpir := StrTran(cExpir, ":","")
            cExpir := StrTran(cExpir, " ","")

            // Atualizando parametros
            putMv("EC_TOKEN"  , cToken)
            putMv("EC_REFRESH", cRefre) // Refresh token
            putMv("EC_EXPIRAT", cExpir)

            return .T.
        else
            // //conout("Erro" + cValToChar(oJsonRet["code"]) + ". Mensagem: " + oJsonRet["message"])
            // msgInfo("Erro" + cValToChar(oJsonRet["code"]) + ". Mensagem: " + oJsonRet["message"], "Erro")
            return .F.
        endif
        
    Else
        // //conout("Erro POST Auth: " + cHeadRet)
        return .F.
    EndIf
return .T.

/*/{Protheus.doc} GetJson
Funcao para criar o json a ser enviado
@type function
@version 12.1.25
@author Paulo Camata (Camatech)
@since 10/08/2020
/*/
Static Function GetJson()
    local oJson   := JsonObject():New()
    local cKey    := getNewPar("EC_KEY"   , "5a9fa4f5283671c91c645a553dd1121ec219e8ede6a109bdcab3c62b8f53a2c7")
    local cSecret := getNewPar("EC_SECRET", "d934e2a74e86821cfa5d489e33a1dfd589e42e6a292b9506e6fe2cb8fb1c8ebb")
    local cCode   := getNewPar("EC_CODE"  , "a6bfde73f879a8b99c550e1edc008f77f7ee3c9c72355387c6b808a13a583e1c") // Producao
    // local cCode   := getNewPar("EC_CODE"  , "0e62985f96161fbe909689953391746ca1318df054b6ea7f97ea7e155eab27e4") // Teste

    oJson["consumer_key"] := cKey
    oJson["consumer_secret"] := cSecret
    oJson["code"] := cCode
Return (oJson:ToJson())
