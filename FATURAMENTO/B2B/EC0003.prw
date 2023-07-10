#include "totvs.ch"
#include "fwmvcdef.ch"

/*/{Protheus.doc} EC0003
Funcao para efetuar a integração das categorias de E-Commerce
@type function
@version 12.1.25
@author Paulo Camata (Camatech)
@since 27/07/2020
/*/
user function EC0003()
    local oBrowse
    private cTitle  := "Cadastro Categorias"
	private aRotina := menuDef()

    dbSelectArea("ZZ2")
	ZZ2->(DBSetOrder(1))

    oBrowse := FWMBrowse():New()
	oBrowse:SetAlias("ZZ2")
	oBrowse:SetDescription(cTitle)
	oBrowse:Activate()
return nil

/*/{Protheus.doc} menuDef
Funcao para criar as opcoes disponiveis no menu (INCLUIR, ALTERAR, ETC)
@type function
@version 12.1.25
@author Paulo Camata (Camatech)
@since 08/08/2020
/*/
static function menuDef()
    aRotina := FWMVCMenu("EC0003")
    ADD OPTION aRotina Title 'Env Tray Pend'  Action 'U_EC0003EN'  OPERATION MODEL_OPERATION_UPDATE ACCESS 0
    ADD OPTION aRotina Title 'Atualiz. Tray'  Action 'U_EC0003AT'  OPERATION MODEL_OPERATION_UPDATE ACCESS 0
    ADD OPTION aRotina Title 'Atualiz. Todos' Action 'U_EC0003ALL' OPERATION MODEL_OPERATION_UPDATE ACCESS 0
return aRotina

/*/{Protheus.doc} ModelDef
Definicao dos campos e seus dados
@type function
@version 12.1.25
@author Paulo Camata (Camatech)
@since 08/08/2020
/*/
static function ModelDef()
	local oModel
	local oStr1 := FWFormStruct(1, "ZZ2")

	oModel := MPFormModel():New("EC0003M", /*bPre*/, /*bPost*/,/*bCommit*/,/*bCancel*/)
	oModel:addFields("MASTER", , oStr1)
	oModel:GetModel("MASTER"):SetPrimaryKey({"ZZ2_CODIGO"})

	oModel:SetDescription("Formulário de Cadastro")
return oModel

/*/{Protheus.doc} ViewDef
Definicao dos campos e desenho na tela
@type function
@version 12.1.25
@author Paulo Camata (Camatech)
@since 08/08/2020
/*/
Static Function ViewDef()
	Local oView
	Local oModel := ModelDef()
	local oStr1  := FWFormStruct(2, "ZZ2")
    // local aTree  := {}

	oView := FWFormView():New() // Cria o objeto de View
	oView:SetModel(oModel) // Define qual o Modelo de dados será utilizado
    oView:addField("VIEW_ZZ2", oStr1, "MASTER")

	oView:CreateHorizontalBox("CABEC", 100)
	oView:SetOwnerView("VIEW_ZZ2", "CABEC")
return oView

/*/{Protheus.doc} EC0003EN
Funcao para enviar as categorias não integradas para a Tray
@type function
@version 12.1.25
@author Paulo Camata (Camatech)
@since 10/08/2020
/*/
user function EC0003EN()
    local cUrl    := allTrim(getNewPar("EC_URLAPI", "https://casachinaempresas.commercesuite.com.br/web_api")) // URL
    local cPath   := "/categories/"
    local cAliCat := getNextAlias()
    local abkpAli := ZZ2->(getArea())
    local aHeader := {}
    local cGetPar := ""
    local cFilBkp := cFilAnt

    cFilAnt := "010104" // filial CD

    if u_EC0001() // Atualizando token
        cToken := buscaToken()
        cGetPar := 'access_token=' + escape(cToken)
    else
        cLogErr := "Erro Geração Token"
        U_EC07LOG("CATEGORIA", "E", cLogErr)
        msgInfo(cLogErr, "ERRO")
        
        return nil
    endif

    AAdd(aHeader, "Content-Type: application/json; charset=ISO-8859-1")
    AAdd(aHeader, "Connection: keep-alive")
    AAdd(aHeader, "Accept: */*")

    dbSelectArea("ZZ2")
    ZZ2->(dbSetOrder(1))

    BeginSql Alias cAliCat
        SELECT R_E_C_N_O_ RECN
          FROM %table:ZZ2%
         WHERE D_E_L_E_T_ = ''
           AND ZZ2_ID = ''
         ORDER BY ZZ2_CODIGO
    EndSql

    while !(cAliCat)->(EoF())
        ZZ2->(dbGoTo((cAliCat)->RECN))

        oJson := fGetJson(3)
        cRet := fPost(cUrl, cPath, cGetPar, oJson:toJson(), aHeader) // Efetuar o post

        if (cRet == "401") // Unauthorized
            if u_EC0001() // Atualizando token
                cToken := buscaToken()
                cGetPar := 'access_token=' + escape(cToken)
            else
                cLogErr := "Erro Geração Token"
                U_EC07LOG("CATEGORIA", "E", cLogErr)
                msgInfo(cLogErr, "ERRO")

                return nil
            endif

            cRet := fPost(cUrl, cPath, cGetPar, oJson:toJson(), aHeader) // Efetuar o post
        endif

        (cAliCat)->(dbSkip())
    endDo
    (cAliCat)->(dbCloseArea())
    restArea(aBkpAli)
    
    cFilAnt := cFilBkp
    msgInfo("Integração finalizada.", "OK")
return nil

/*/{Protheus.doc} fGetJson
Funcao para retornar o json pronto da categoria
@type function
@version 12.1.25
@author Paulo Camata (Camatech)
@since 10/08/2020
@params _cOper - 3-Inclusão e 4 Alteração
/*/
static function fGetJson(_cOper)
    local oJson := nil
    local aBkpAre := ZZ2->(getArea())

    oJson := JsonObject():New()
    oJson["Category"] := JsonObject():New()
    oJson["Category"]["name"] := allTrim(EncodeUtf8(ZZ2->ZZ2_DESCRI, "iso8859-1"))
    oJson["Category"]["description"] := allTrim(EncodeUtf8(ZZ2->ZZ2_DESCRI, "iso8859-1"))
    if _cOper == 4
        oJson["Category"]["order"] := cValToChar(ZZ2->ZZ2_ORDER)
    endif
    oJson["Category"]["title"] := allTrim(EncodeUtf8(ZZ2->ZZ2_TITLE, "iso8859-1"))

    if !empty(ZZ2->ZZ2_DETALH)
        oJson["Category"]["small_description"] := allTrim(EncodeUtf8(ZZ2->ZZ2_DETALH, "iso8859-1"))
    endif

    if (ZZ2->ZZ2_ACEITE == "S")
        oJson["Category"]["has_acceptance_term"] := "1"
        oJson["Category"]["acceptance_term"] := allTrim(EncodeUtf8(ZZ2->ZZ2_TERMAC, "iso8859-1"))
    else
        oJson["Category"]["has_acceptance_term"] := "0"
    endif

    cDescri := allTrim(ZZ2->ZZ2_DESCRI)
    if (!Empty(ZZ2->ZZ2_PAI))
        // Buscando ID pai
        if (ZZ2->(dbSeek(xFilial("ZZ2") + ZZ2->ZZ2_PAI)) .and. !empty(ZZ2->ZZ2_ID))
            oJson["Category"]["parent_id"] := allTrim(ZZ2->ZZ2_ID)
            oJson["Category"]["slug"] := EncodeUtf8(strTran(allTrim(ZZ2->ZZ2_DESCRI) + "/" + cDescri, " ", "-"), "iso8859-1") // Link final categoria
        else
            oJson["Category"]["parent_id"] := ""
            oJson["Category"]["slug"] := EncodeUtf8(strTran(cDescri, " ", "-"), "iso8859-1") // Link final categoria
        endif
        restArea(aBkpAre)
    else
        oJson["Category"]["parent_id"] := ""
        oJson["Category"]["slug"] := EncodeUtf8(strTran(cDescri, " ", "-"), "iso8859-1") // Link final categoria
    endif
return oJson

/*/{Protheus.doc} fPost
Funcao para efetuara o post
@type function
@version 12.1.25
@author Paulo Camata (Camatech)
@since 10/08/2020
@param oRest, object, param_description
@param aHeader, array, param_description
/*/
static function fPost(cUrlPost, cPath, cGetPar, cJson, aHeader)
    local cRetorno := ""
    local cHeaRet := ""

    cPostRet := HttpPost(cUrlPost + cPath, cGetPar, cJson, 120, aHeader, @cHeaRet) // Efetua o POST

    If !empty(cPostRet) // Retorno
        //conout("POST Categoria: " + cPostRet)
        oJsonRet := JsonObject():New()
        ret := oJsonRet:fromJson(cPostRet) // Convertendo json
        if (oJsonRet["code"] == 200 .or. oJsonRet["code"] == 201) // OK
            // Atualizando ID gerado na TRAY
            recLock("ZZ2", .F.)
                ZZ2->ZZ2_ID := oJsonRet["id"]
            ZZ2->(msUnlock())

            cRetorno := "200"
        elseif oJsonRet["code"] == 401
            cRetorno := oJsonRet["code"]

        else
            cLogErr := "Erro " + cValToChar(oJsonRet["code"]) + ". Name: " + oJsonRet["name"] + " - url: " + oJsonRet["url"]
            // U_EC07LOG("CATEGORIA", "E", cLogErr)

            msgInfo(cLogErr, "ERRO")
            cRetorno := cLogErr
        endif
    else
        cLogErr := "Problema post: " + cHeaRet
        U_EC07LOG("CATEGORIA", "E", cLogErr)

        msgInfo(cLogErr, "ERRO")
        cRetorno := cLogErr
    endif
return cRetorno

/*/{Protheus.doc} EC0003AT
Funcao para efetuar a atualizacao da categoria na Tray (PUT)
@type function
@version 12.1.25
@author Paulo Camata (Camatech)
@since 10/08/2020
/*/
user Function EC0003AT()
    local cUrl  := allTrim(getNewPar("EC_URLAPI", "https://casachinaempresas.commercesuite.com.br/web_api")) // URL
    local cPath := "/categories/"
    local aHeader := {}
    local cGetPar := ""
    local cFilBkp := cFilAnt

    cFilAnt := "010104" // filial CD

    if (Empty(ZZ2->ZZ2_ID))
        HELP(' ', 1, "Categoria não existe na Tray", , "Somente é permitido atualizara categoria quando já inserida na Tray.", 2, 0,,,,,, {"Utilize a opção Env. Tray Pend. para inserir categorias na plataforma."})
        return nil
    endif

    if u_EC0001() // Atualizando token
        cToken := buscaToken()
        cGetPar := 'access_token=' + escape(cToken)
    else
        cLogErr := "Erro Geração Token"
        U_EC07LOG("CATEGORIA", "E", cLogErr)
        msgInfo(cLogErr, "ERRO")

        return nil
    endif

    AAdd(aHeader, "Content-Type: application/json; charset=ISO-8859-1")
    AAdd(aHeader, "Connection: keep-alive")
    AAdd(aHeader, "Accept: */*")

    oJson := fGetJson(4)

    cRet := fPut(cUrl, cPath, cGetPar, oJson:ToJson(), aHeader) // Efetuar o put

    if (cRet == "401") // Unauthorized
        if u_EC0001() // Atualizando token
            cToken := buscaToken()
            cPath += "?access_token=" + cToken
        else
            cLogErr := "Erro Geração Token"
            U_EC07LOG("CATEGORIA", "E", cLogErr)
            msgInfo(cLogErr, "ERRO")

            return nil
        endif

        cRet := fPut(cUrl, cPath, cGetPar, oJson:ToJson(), aHeader) // Efetuar o put
    endif
    cFilAnt := cFilBkp
return nil

/*/{Protheus.doc} fPut
Funcao para efetuar a atualizacao (PUT)
@type function
@version 12.1.25
@author Paulo Camata (Camatech)
@since 10/08/2020
/*/
static function fPut(cUrlPut, cPath, cGetPar, cJson, aHeader)
    local oRest := FWRest():New(cUrlPut)
    local cRet  := ""

    oRest:setPath(cPath + "/" + allTrim(ZZ2->ZZ2_ID) + "?" + cGetPar)

    If (oRest:Put(aHeader, cJson)) // Efetua o POST
        //conout("PUT CATEGORIA: " + oRest:GetResult())
        oJsonRet := JsonObject():New()
        ret := oJsonRet:fromJson(oRest:GetResult()) // Convertendo json
        if (oJsonRet["code"] == 200 .or. oJsonRet["code"] == 201) // OK
            cRet := "200"

        elseif oJsonRet["code"] == 401
            cRet := oJsonRet["code"]

        else
            cLogErr := "Erro " + cValToChar(oJsonRet["code"]) + ". Name: " + oJsonRet["name"] + " - url: " + oJsonRet["url"]
            U_EC07LOG("CATEGORIA", "E", cLogErr)
            msgInfo(cLogErr, "ERRO")
            cRet := cLogErr
        endif
    else
        oJsonRet:fromJson(oRest:GetResult())
        msgInfo(oJsonRet:GetJsonText("causes"), "ERRO")
    endif
return cRet

/*/{Protheus.doc} EC0003ALL
Funcao para atualizar todas as categorias do site
@type function
@version 12.1.25
@author Paulo Camata (Camatech)
@since 10/08/2020
/*/
user function EC0003ALL()
    local cUrl    := allTrim(getNewPar("EC_URLAPI", "https://casachinaempresas.commercesuite.com.br/web_api")) // URL
    local cPath   := "/categories/"
    local cAliCat := getNextAlias()
    local abkpAli := ZZ2->(getArea())
    local aHeader := {}
    local cGetPar := ""
    local cFilBkp := cFilAnt

    cFilAnt := "010104" // filial CD

    if u_EC0001() // Atualizando token
        cToken := buscaToken()
        cGetPar := 'access_token=' + escape(cToken)
    else
        cLogErr := "Erro Geração Token"
        U_EC07LOG("CATEGORIA", "E", cLogErr)
        msgInfo(cLogErr, "ERRO")
        
        return nil
    endif

    AAdd(aHeader, "Content-Type: application/json; charset=ISO-8859-1")
    AAdd(aHeader, "Connection: keep-alive")
    AAdd(aHeader, "Accept: */*")

    dbSelectArea("ZZ2")
    ZZ2->(dbSetOrder(1))

    BeginSql Alias cAliCat
        SELECT R_E_C_N_O_ RECN
          FROM %table:ZZ2%
         WHERE D_E_L_E_T_ = ''
         ORDER BY ZZ2_PAI
    EndSql

    while !(cAliCat)->(EoF())
        ZZ2->(dbGoTo((cAliCat)->RECN))

        if empty(ZZ2->ZZ2_ID)
        
            oJson := fGetJson(3)
            cRet := fPost(cUrl, cPath, cGetPar, oJson:toJson(), aHeader) // Efetuar o post
        else
            
            oJson := fGetJson(4)
            cRet := fPut(cUrl, cPath, cGetPar, oJson:ToJson(), aHeader) // Efetuar o put
        endif

        if (cRet == "401") // Unauthorized
            if u_EC0001() // Atualizando token
                cToken := buscaToken()
                cGetPar := 'access_token=' + escape(cToken)
            else
                cLogErr := "Erro Geração Token"
                U_EC07LOG("CATEGORIA", "E", cLogErr)
                msgInfo(cLogErr, "ERRO")

                return nil
            endif

            if empty(ZZ2->ZZ2_ID)
                cRet := fPost(cUrl, cPath, cGetPar, oJson:toJson(), aHeader) // Efetuar o post
            else
                cRet := fPut(cUrl, cPath, cGetPar, oJson:ToJson(), aHeader) // Efetuar o put
            endif
        endif

        (cAliCat)->(dbSkip())
    endDo
    (cAliCat)->(dbCloseArea())
    restArea(aBkpAli)
    
    cFilAnt := cFilBkp
    msgInfo("Integração finalizada.", "OK")
return nil


static function buscaToken()
    Local _cToken :=  allTrim(getMv("EC_TOKEN"))
return _cToken
