#include "totvs.ch"
#include "fwmvcdef.ch"

/*/{Protheus.doc} EC0008
Integrar Marcas
@type function
@version 12.1.25
@author Paulo Camata (Camatech)
@since 11/08/2020
/*/
user function EC0008()
    local oBrowse
    private cTitle  := "Integração Marcas E-Commerce"
	private aRotina := menuDef()

    dbSelectArea("AY2")
	AY2->(DBSetOrder(1))

    oBrowse := FWMBrowse():New()
	oBrowse:SetAlias("AY2")
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
    local aRotAux := {}

    ADD OPTION aRotAux Title 'Visualizar'    Action 'VIEWDEF.EC0007' OPERATION MODEL_OPERATION_VIEW   ACCESS 0
    ADD OPTION aRotAux Title 'Env Tray Pend' Action 'U_EC0007EN'     OPERATION MODEL_OPERATION_UPDATE ACCESS 0
    ADD OPTION aRotAux Title 'Atualiz. Tray' Action 'U_EC0007AT'     OPERATION MODEL_OPERATION_UPDATE ACCESS 0
return aRotAux

/*/{Protheus.doc} ModelDef
Definicao dos campos e seus dados
@type function
@version 12.1.25
@author Paulo Camata (Camatech)
@since 08/08/2020
/*/
static function ModelDef()
	local oModel
	local oStr1 := FWFormStruct(1, "AY2")

	oModel := MPFormModel():New("EC0007M", /*bPre*/, /*bPost*/,/*bCommit*/,/*bCancel*/)
	oModel:addFields("MASTER", , oStr1)
	oModel:GetModel("MASTER"):SetPrimaryKey({"AY2_CODIGO"})

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
	local oStr1  := FWFormStruct(2, "AY2")

	oView := FWFormView():New() // Cria o objeto de View
	oView:SetModel(oModel) // Define qual o Modelo de dados será utilizado
    oView:addField("VIEW_AY2", oStr1, "MASTER")

	oView:CreateHorizontalBox("CABEC", 100)
	oView:SetOwnerView("VIEW_AY2", "CABEC")
return oView

/*/{Protheus.doc} EC0007EN
Funcao para enviar as marcas não integradas para a Tray
@type function
@version 12.1.25
@author Paulo Camata (Camatech)
@since 10/08/2020
/*/
user function EC0007EN(nRecno)
    local cUrl    := allTrim(getNewPar("EC_URLAPI", "https://casachinaempresas.commercesuite.com.br/web_api")) // URL
    local cPath   := "/products/brands/"
    local cAliMar := getNextAlias()
    local abkpAli := AY2->(getArea())
    local aHeader := {}
    local cGetPar := ""
    local cFiltro := "%%" // Filtro caso haja recno informado
    
    default nRecno := 0

    if nRecno <> 0 // Foi enviado um recno expecifico
        cFiltro := "% AND R_E_C_N_O_ = " + cValToChar(nRecno) + "%"
    endif

    if u_EC0001() // Atualizando token
        cToken := buscaToken()
        cGetPar := 'access_token=' + escape(cToken)
    else
        msgInfo("Erro Geração Token", "ERRO")
        return nil
    endif

    AAdd(aHeader, "Content-Type: application/json; charset=ISO-8859-1")
    AAdd(aHeader, "Connection: keep-alive")
    AAdd(aHeader, "Accept: */*")

    dbSelectArea("AY2")
    AY2->(dbSetOrder(1))

    BeginSql Alias cAliMar
        SELECT R_E_C_N_O_ RECN
          FROM %table:AY2%
         WHERE D_E_L_E_T_ = ''
           AND AY2_YID = ''
           %exp:cFiltro%
         ORDER BY AY2_CODIGO
    EndSql

    while !(cAliMar)->(EoF())
        AY2->(dbGoTo((cAliMar)->RECN))

        oJson := fGetJson()

        cRet := fPost(cUrl, cPath, cGetPar, oJson:toJson(), aHeader) // Efetuar o post

        if (cRet == "401") // Unauthorized
            if u_EC0001() // Atualizando token
                cToken := buscaToken()
                cGetPar := 'access_token=' + escape(cToken)
            else
                msgInfo("Erro Geração Token", "ERRO")
                return nil
            endif

            cRet := fPost(cUrl, cPath, cGetPar, oJson:toJson(), aHeader) // Efetuar o post
        endif

        (cAliMar)->(dbSkip())
    endDo
    (cAliMar)->(dbCloseArea())
    restArea(aBkpAli)
    
    msgInfo("Integração finalizada.", "OK")
return nil

/*/{Protheus.doc} fGetJson
Funcao para retornar o json pronto da marca
@type function
@version 12.1.25
@author Paulo Camata (Camatech)
@since 10/08/2020
/*/
static function fGetJson()
    local oJson := nil

    oJson := JsonObject():New()
    oJson["Brand"] := JsonObject():New()
    oJson["Brand"]["brand"] := EncodeUtf8(allTrim(AY2->AY2_DESCR), "iso8859-1")
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
        //conout("POST Marca: " + cPostRet)
        oJsonRet := JsonObject():New()
        ret := oJsonRet:fromJson(cPostRet) // Convertendo json
        if (oJsonRet["code"] == 200 .or. oJsonRet["code"] == 201) // OK
            // Atualizando ID gerado na TRAY
            recLock("AY2", .F.)
                AY2->AY2_YID := oJsonRet["id"]
            AY2->(msUnlock())

            cRetorno := "200"
        elseif oJsonRet["code"] == 401
            cRetorno := oJsonRet["code"]

        else
            cMens := "Erro" + cValToChar(oJsonRet["code"]) + ". Mensagem: " + oJsonRet["message"]
            //conout(cMens)
            msgInfo(cMens)
            cRetorno := cMens
        endif
    else
        cMens := "Problema post: " + cHeaRet
        //conout(cMens)
        msgInfo(cMens)
        cRetorno := cMens
    endif
return cRetorno


static function buscaToken()
    Local _cToken :=  allTrim(getMv("EC_TOKEN"))
return _cToken
