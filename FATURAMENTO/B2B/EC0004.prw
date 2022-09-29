#include "totvs.ch"
#INCLUDE "TOPCONN.CH"        
#INCLUDE "TBICONN.CH"
/*/{Protheus.doc} EC0004
Funcao para efetuar a integração dos clientes pendentes para o E-Commerce
@type function
@version 12.1.25
@author Paulo Camata (Camatech)
@since 27/07/2020
/*/
user function EC0004(lJob, cId)
    local cPath   := "/customers/"
    local cTokPar := ""
    local i, cFilCli, cUltCon, cUrl, cDatPes, oRest

    private cLogErr := "" // Log de retorno
    default lJob    := .T.
    default cId     := ""

    if lJob // Funcao é job
        //RpcClearEnv()
        RpcSetType(3) // Nao consumir licenças
        RpcSetEnv("01", "010104") // Montando ambiente
    else
        procRegua(0)
        incProc("Processando dados! Aguarde...")
        incProc("Processando dados! Aguarde...")
    endif

    cFilBkp := cFilAnt
    cFilAnt := "010104" // filial CD

    cUrl    := getNewPar("EC_URLAPI", "https://casachinaempresas.commercesuite.com.br/web_api") // URL
    cUltCon := allTrim(getMv("EC_HORCLI")) // Ultima consulta a cliente
    oRest   := FWRest():New(cUrl)
    cDatPes := DTOS(Date()) // Caso seja necessario trocar essa variavel para filtro da pesquisa por data de modificacao
    
    if !Empty(cId)
        cFilCli := escape(cId) + "?" // Filtro cliente: Data modificacao para dia atual
    else
        if !empty(cUltCon)
            cFilCli := "?limit=50&modified=" + escape(cUltCon) + "&" // Filtro cliente: Data modificacao para dia atual
        else
            cFilCli := "?limit=50&modified=" + escape(left(cDatPes, 4) + "-" + SubStr(cDatPes, 5, 2) + "-" + Right(cDatPes, 2)) + "&" // Filtro cliente: Data modificacao para dia atual
        endif
    endif

    if u_EC0001() // Atualizando token
        cToken := allTrim(getMv("EC_TOKEN"))
        cTokPar := "access_token=" + escape(cToken)
    else
        cLogErr := "Erro Geração Token"
        // U_EC07LOG("CLIENTE", "E", cLogErr)
        msgInfo(cLogErr, "ERRO")
        
        return nil
    endif

    oRest:setPath(cPath + cFilCli + cTokPar)
    cHorCon := left(cDatPes, 4) + "-" + SubStr(cDatPes, 5, 2) + "-" + Right(cDatPes, 2) + " " + Time()
    If (oRest:Get())
        cGetRest := oRest:GetResult()
        
        // //conout("GET Pedidos: " + cGetRest)
        oJsonRet := JsonObject():New()
        cJsonRet := oJsonRet:fromJson(cGetRest) // Convertendo json
        
        if !Empty(cId)
            fCliente(oJsonRet["Customer"])
        else
            aCliJson := oJsonRet["Customers"]
            for i := 1 to len(aCliJson)
                fCliente(aCliJson[i]["Customer"])

                buscCli(aCliJson[i]["Customer"])
            next i
        endif
        
        if (empty(cId))
            PutMv('EC_HORCLI',cHorCon)
        endif
    endif

    cFilAnt := cFilBkp
return nil

/*/{Protheus.doc} fCliente
Funcao para incluir/alterar cliente pelo id retornado no json
@type function
@version 12.1.25
@author Paulo Camata (Camatech)
@since 23/08/2020
@param oJson, object, Json do cliente
/*/
static function fCliente(oJson)
    local _nOpc, _cCpfCnp, cTipCli
    local _aCliente := {}
    local cMenErr := ""

    private lMsErroAuto := .F.

    if oJson["cnpj"] <> ""
        _cCpfCnp := StrTran(StrTran(StrTran(oJson["cnpj"], ".", ""), "-", ""), "/", "")
        cTipCli := "J"
    else
        _cCpfCnp := StrTran(StrTran(oJson["cpf"], ".", ""), "-", "")
        cTipCli := "F"
    endif

    // Buscar pelo CNPJ/CPF
    dbSelectArea("SA1")
    SA1->(dbSetOrder(3)) // FILIAL + CGC
    if SA1->(msSeek(xFilial("SA1") + padr(_cCpfCnp, tamSx3("A1_CGC")[1])))
        _nOpc := 4
        aAdd(_aCliente, {"A1_COD", SA1->A1_COD, nil})
    else
        _nOpc := 3
    endif

    aRetEnd := fGetEnderecos(cValToChar(oJson["id"])) // Buscar enderecos 

    if (!empty(oJson["company_name"])) // Se nao for CNPJ
        _cNomCli := Upper(DecodeUTF8(oJson["company_name"], "cp1252"))
    else
        _cNomCli := Upper(DecodeUTF8(oJson["name"], "cp1252"))
    endif

    aAdd(_aCliente, {"A1_LOJA"  , "01"              , nil})	
    aAdd(_aCliente, {"A1_CGC"   , _cCpfCnp          , nil})
    aAdd(_aCliente, {"A1_TIPO"  , "F"               , nil})
    aAdd(_aCliente, {"A1_PESSOA", cTipCli           , nil})
    aAdd(_aCliente, {"A1_NOME"  , left(_cNomCli, 40), nil})
    aAdd(_aCliente, {"A1_NREDUZ", left(_cNomCli, 20), nil})
    aAdd(_aCliente, {"A1_EMAIL" , DecodeUTF8(oJson["email"], "cp1252"), nil})
    aAdd(_aCliente, {"A1_PAIS"  , "105"             , nil})
    aAdd(_aCliente, {"A1_YIDB2B", oJson["id"]       , nil}) // id Cliente B2B
    aAdd(_aCliente, {"A1_CYBERW", "S"               , nil}) // Cliente WMS
    aAdd(_aCliente, {"A1_B2B"   , "1"               , nil}) // Cliente B2B
    
    if oJson["birth_date"] <> "" // Data de Nascimento
        dDatNasc := STOD(StrTran(oJson["birth_date"], "-", ""))
        aAdd(_aCliente, {"A1_DTNASC", dDatNasc, nil})
    endif

    if len(aRetEnd) > 0 // Achou endereco
        cCodCep := strTran(aRetEnd[7], "-", "")
        // Buscar codigo IBGE da Cidade/Estado
        cGetCep  := HttpGet("https://viacep.com.br/ws/" + cCodCep + "/json/")
        oJsonCep := JsonObject():New()
        cJsonCep := oJsonCep:fromJson(cGetCep) // Convertendo json

        if (oJsonCep["erro"]) // Erro consulta CEP
            cMenErr := "Erro consutla Cliente: " + _cCpfCnp + " CEP: " + cCodCep + CRLF
            return cMenErr
        endif

        cCodIbge := Right(oJsonCep["ibge"], 5) // Codigo do IBGE sem o do estado
        
        cEndereco := Upper(DecodeUTF8(allTrim(aRetEnd[1]) + ", " + allTrim(aRetEnd[2]), "cp1252"))
        aAdd(_aCliente, {"A1_END"    , cEndereco, nil})
        aAdd(_aCliente, {"A1_YNUMERO", Upper(DecodeUTF8(aRetEnd[2], "cp1252")), nil})
        aAdd(_aCliente, {"A1_COMPLEM", Upper(DecodeUTF8(aRetEnd[3], "cp1252")), nil})
        aAdd(_aCliente, {"A1_BAIRRO" , Upper(DecodeUTF8(aRetEnd[4], "cp1252")), nil})
        aAdd(_aCliente, {"A1_MUN"    , Upper(DecodeUTF8(aRetEnd[5], "cp1252")), nil})
        aAdd(_aCliente, {"A1_EST"    , Upper(DecodeUTF8(aRetEnd[6], "cp1252")), nil})
        aAdd(_aCliente, {"A1_CEP"    , cCodCep   , nil})
        aAdd(_aCliente, {"A1_CODPAIS", "01058"   , nil})
        aAdd(_aCliente, {"A1_COD_MUN", cCodIbge  , nil})

         if oJson["state_inscription"] <> "" .and. oJson["state_inscription"] <> NIL// Inscricao estadual
            _cIe := ALLTRIM(StrTran(oJson["state_inscription"], ".", ""))
            aAdd(_aCliente, {"A1_INSCR", Upper(DecodeUTF8(_cIe, "cp1252")), nil})
        endif

         if oJson["cellphone"] <> "" .and. oJson["cellphone"] <> NIL // Telefone celular
            _cTel := StrTran(oJson["cellphone"], "-", "")
            _cTel := StrTran(_cTel, "(", "")
            _cTel := StrTran(_cTel, ")", "")
            _cTel := StrTran(_cTel, ".", "")
            _cDdd := ''

            if(LEN(_cTel) > 9)
                _cDdd := SUBSTR(_cTel,1,(LEN(_cTel)-9))
                _cTel := SUBSTR(_cTel,(LEN(_cTel)-9)+1)
                
                aAdd(_aCliente, {"A1_DDD"    , _cDdd     , nil})
            ENDIF

            aAdd(_aCliente, {"A1_TEL", _cTel, nil})

        elseif oJson["phone"] <> ""  .and. oJson["phone"] <> NIL// Telefone fixo
            _cTel := StrTran(oJson["phone"], "-", "")
            _cTel := StrTran(_cTel, "(", "")
            _cTel := StrTran(_cTel, ")", "")
            _cTel := StrTran(_cTel, ".", "")
            _cDdd := ''

            if(LEN(_cTel) > 8)
                _cDdd := SUBSTR(_cTel,1,(LEN(_cTel)-8))
                _cTel := SUBSTR(_cTel,(LEN(_cTel)-8)+1)
                
                aAdd(_aCliente, {"A1_DDD"    , _cDdd     , nil})
            ENDIF

            aAdd(_aCliente, {"A1_TEL", _cTel, nil})
        elseif _nOpc == 3
            aAdd(_aCliente, {"A1_DDD"    , "999"     , nil})
            aAdd(_aCliente, {"A1_TEL"    , "99999999", nil})
        endif

    endif

    MsExecAuto({|x, y| Mata030(x, y)}, _aCliente, _nOpc)
    if lMsErroAuto // Erro ExecAuto
        RollBackSx8()
        cLogErr := left(mostraErro("\log\", "E_INC_CLIENTE.LOG"), 200)
        // U_EC07LOG("CLIENTE", "E", cLogErr)
    endif
return cMenErr

/*/{Protheus.doc} fGetEnderecos
Funcao para buscar os dados do endereco do cliente
@type function
@version 12.1.25
@author Paulo Camata (Camatech)
@since 23/08/2020
@param cId, character, ID do cliente
/*/
static function fGetEnderecos(cId)
    local cUrl    := getNewPar("EC_URLAPI", "https://casachinaempresas.commercesuite.com.br/web_api") // URL
    local cPath   := "/customers/addresses/?customer_id=" + cId + "&"
    local oRest   := FWRest():New(cUrl)
    local cTokPar := ""
    local mi

    if u_EC0001() // Atualizando token
        cToken := allTrim(getMv("EC_TOKEN"))
        cTokPar := 'access_token=' + escape(cToken)
    else
        cLogErr := "Erro Geração Token"
        // U_EC07LOG("CLIENTE", "E", cLogErr)
        msgInfo(cLogErr, "ERRO")
        
        return nil
    endif

    oRest:setPath(cPath + cTokPar)
    If (oRest:Get())
        cGetRest := oRest:GetResult()
        oJsonRet := JsonObject():New()
        cJsonRet := oJsonRet:fromJson(cGetRest) // Convertendo json

        // Retornar o primeiro endereco
        for mi := 1 to len(oJsonRet["CustomerAddresses"])
            if (oJsonRet["CustomerAddresses"][mi]["CustomerAddress"]["active"] == "1")
                aRet := {;
                    oJsonRet["CustomerAddresses"][mi]["CustomerAddress"]["address"],;
                    oJsonRet["CustomerAddresses"][mi]["CustomerAddress"]["number"],;
                    oJsonRet["CustomerAddresses"][mi]["CustomerAddress"]["complement"],;
                    oJsonRet["CustomerAddresses"][mi]["CustomerAddress"]["neighborhood"],;
                    oJsonRet["CustomerAddresses"][mi]["CustomerAddress"]["city"],;
                    oJsonRet["CustomerAddresses"][mi]["CustomerAddress"]["state"],;
                    oJsonRet["CustomerAddresses"][mi]["CustomerAddress"]["zip_code"];
                }

                exit
            endif
        next mi

        return aRet
    endif
return {}


/*/{Protheus.doc} fGetEnderecos
Funcao para buscar os dados do endereco do cliente
@type function
@version 12.1.25
@author Paulo Camata (Camatech)
@since 23/08/2020
@param cId, character, ID do cliente
/*/
static function fGetDadosCli(cId)
    local cUrl    := getNewPar("EC_URLAPI", "https://casachinaempresas.commercesuite.com.br/web_api") // URL
    local cPath   := "/customers/" + cId + "?"
    local oRest   := FWRest():New(cUrl)
    local cTokPar := ""
    local mi

    if u_EC0001() // Atualizando token
        cToken := allTrim(getMv("EC_TOKEN"))
        cTokPar := 'access_token=' + escape(cToken)
    else
        cLogErr := "Erro Geração Token"
        // U_EC07LOG("CLIENTE", "E", cLogErr)
        msgInfo(cLogErr, "ERRO")
        
        return nil
    endif

    oRest:setPath(cPath + cTokPar)
    If (oRest:Get())
        cGetRest := oRest:GetResult()
        oJsonRet := JsonObject():New()
        cJsonRet := oJsonRet:fromJson(cGetRest) // Convertendo json

        // Retornar o primeiro endereco
        for mi := 1 to len(oJsonRet["CustomerAddresses"])
            if (oJsonRet["CustomerAddresses"][mi]["CustomerAddress"]["active"] == "1")
                aRet := {;
                    oJsonRet["CustomerAddresses"][mi]["CustomerAddress"]["address"],;
                    oJsonRet["CustomerAddresses"][mi]["CustomerAddress"]["number"],;
                    oJsonRet["CustomerAddresses"][mi]["CustomerAddress"]["complement"],;
                    oJsonRet["CustomerAddresses"][mi]["CustomerAddress"]["neighborhood"],;
                    oJsonRet["CustomerAddresses"][mi]["CustomerAddress"]["city"],;
                    oJsonRet["CustomerAddresses"][mi]["CustomerAddress"]["state"],;
                    oJsonRet["CustomerAddresses"][mi]["CustomerAddress"]["zip_code"];
                }

                exit
            endif
        next mi

        return aRet
    endif
return {}

/*/{Protheus.doc} EC0004J
Funcao chamada no schedule
@type function
@version 12.1.25
@author Paulo Camata (Camatech)
@since 14/10/2020
/*/
user function EC0004J()
    U_EC0004(.T., "295")
return nil

USER Function tstVieira()

PREPARE ENVIRONMENT EMPRESA '01' FILIAL '010101' MODULO "FAT"
		
	u_EC0004(.t.,'')

	RESET ENVIRONMENT

return



/*/{Protheus.doc} buscCli
Funcao que faz a chamada da consulta de clientes por id, para que possamos atualizar campos de telefone, IE... que só vem na consulta detalhada
@type function
@version 12.1.25
@author Eduardo Vieira
@since 23/07/2022
@param oJson, object, Json do cliente
/*/
static function buscCli(oJson)


if (oJson["id"] != '' .and. oJson["id"] <> NIL) 
    U_EC0004(.T.,oJson["id"])
endif

return
