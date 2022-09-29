#include "totvs.ch"
#include "topConn.ch"
#include "restful.ch"
#include "fileio.ch"

/*/{Protheus.doc} WS001
Funcao WS REST para consulta de produtos do clube (somente serao listados os 10 primeiros - Conforme parametro)
@author Paulo Cesar Camata
@since 02/08/2019
@version 12.1.17
@type function
/*/
WSRESTFUL wsgetproduto DESCRIPTION "WS REST para consulta dos produtos do Clube China" FORMAT APPLICATION_JSON
    WSMETHOD GET GetProduct DESCRIPTION "Consulta produtos do clube China" WSSYNTAX "wsgetproduto/GetProduct" Path "/GetProduct/"
END WSRESTFUL

// Funcao get para retornar os produtos
WSMETHOD GET GetProduct WSSERVICE wsgetproduto
    local oJson, oReturn

    oJson := JsonObject():new()
	oJson:fromJson(::GetContent())
    
    oReturn := fValida(oJson)
    cJson   := FWJsonSerialize(oReturn, .F.)
	FreeObj(oJson)
	FreeObj(oReturn)

    ::SetContentType("application/json")
	::setResponse(cJson)
Return .T.

// Funcao para efetuar validacoes do usuario
// Modelo senha para usuário (admin) senha (123123) e dia do login 02/08/19
// admin12312302/08/19 => na base64
static function fValida(oJson)
    local cUsuario  := oJson:GetJsonText("User")
	local cPassword := oJson:GetJsonText("Password") 
    local lLogin    := .F.
    local cAliasSB1 := getNextAlias()
    local aRetPrd   := {}
    local oHashRet  := THashMap():New()

    if empty(cUsuario) .or. empty(cPassword)
        //conout("Usuario e senhas em branco")
        oHashRet:Set("Status", 0)
		oHashRet:Set("MSGRET", "TAG User/Password nao informado!")
        return oHashRet
    endif

    // Validando usuário e senha
    cPassword := Decode64(cPassword) // Deserializando password
    nTamUsu   := len(cUsuario) // tamanho 

    if cUsuario <> left(cPassword, nTamUsu)
        //conout("Usuario: " + cUsuario)
        //conout("Pass: " + left(cPassword, nTamUsu))
        oHashRet:Set("Status", 0)
		oHashRet:Set("mensagem", "Usuario/Senha invalidos!")
        return oHashRet
    endif
    
    cData     := right(cPassword, 8)
    cPassword := subStr(cPassword, nTamUsu + 1, len(cPassword) - nTamUsu - 8) // Retirando somente a senha

    if cData <> DTOS(date())
        //conout("Data: " + cData)
        //conout("Date: " + DTOS(date()))
        oHashRet:Set("Status", 0)
		oHashRet:Set("mensagem", "Usuario/Senha invalidos!")
        return oHashRet
    endif

    // Validando login
    RpcClearEnv()	
	RpcSetType(3)
	lLogin := RpcSetEnv("01", "0101", cUsuario, cPassword, , GetEnvServer())

    if !lLogin
        //conout("falha login")
        oHashRet:Set("Status", 0)
		oHashRet:Set("mensagem", "Usuario/Senha invalidos!")
        return oHashRet
    endif

    beginSql alias cAliasSB1
        SELECT B1_COD, B1_DESC, ISNULL(B5_CEME, '') B5_CEME, DA1PADRAO.DA1_PRCVEN PRECO_PADRAO, DA1CLUBE.DA1_PRCVEN PRECO_CLUBE
          FROM %table:SB1% SB1
          LEFT JOIN %table:SB5% SB5
            ON B5_FILIAL = %xFilial:SB5%
           AND B5_COD = B1_COD
           AND SB5.%notdel%
          JOIN %table:DA1% DA1PADRAO
            ON DA1PADRAO.DA1_FILIAL = %xFilial:DA1%
           AND DA1PADRAO.DA1_CODTAB = '001'
           AND DA1PADRAO.DA1_CODPRO = B1_COD
           AND DA1PADRAO.%notdel%
          JOIN %table:DA1% DA1CLUBE
            ON DA1CLUBE.DA1_FILIAL = %xFilial:DA1%
           AND DA1CLUBE.DA1_CODTAB = '100'
           AND DA1CLUBE.DA1_CODPRO = B1_COD
           AND DA1CLUBE.%notdel%
         WHERE B1_FILIAL = %xFilial:SB1%
           AND B1_YCLUBE = 'S'
           AND SB1.%notdel%
         ORDER BY 1
    endSql

    if (cAliasSB1)->(EoF()) // Nao encontrou produto
        (cAliasSB1)->(dbCloseArea())
        oHashRet:Set("Status", 0)
		oHashRet:Set("mensagem", "Nao existem produtos cadastrados para o clube!")
        return oHashRet
    else
        oHashRet:Set("Status", 1)
    endif
    
    while !(cAliasSB1)->(EoF())
        cImagem := "" // Imagem do produto
        aFiles  := {}
        aSizes  := {}

        aDir("\system\fotos\" + allTrim((cAliasSB1)->B1_COD) + ".*", @aFiles, @aSizes) // Buscando todos os arquivos com o nome do produto

        if len(aFiles) > 0 // Encontrou pelo menos uma imagem com o código do produto
            nHandle := fopen("\system\fotos\" + aFiles[1], FO_READWRITE + FO_SHARED)
            cString := ""
            FRead( nHandle, cString, aSizes[1] ) //Carrega na variável cString, a string ASCII do arquivo.
            cImagem := Encode64(cString) // Compactando e Criptografando imagem para envio
            fclose(nHandle)
        endif

        oHashProd := THashMap():New()
        oHashProd:Set("Codigo"      , allTrim((cAliasSB1)->B1_COD))
        oHashProd:Set("Descricao"   , allTrim((cAliasSB1)->B1_DESC))
        oHashProd:Set("Completa"    , allTrim((cAliasSB1)->B5_CEME))
        oHashProd:Set("Preco_Padrao", (cAliasSB1)->PRECO_PADRAO)
        oHashProd:Set("Preco_Clube" , (cAliasSB1)->PRECO_CLUBE)
        oHashProd:Set("Imagem"      , cImagem)

        aAdd(aRetPrd, oHashProd)

        (cAliasSB1)->(dbSkip())
    endDo
    (cAliasSB1)->(dbCloseArea())
    oHashRet:Set("Items", aRetPrd)
return oHashRet


user function WS001TESTE()
    local cAliasSB1 := getNextAlias()
    local aRetPrd   := {}

    beginSql alias cAliasSB1
        SELECT B1_COD, B1_DESC, ISNULL(B5_CEME, '') B5_CEME, DA1PADRAO.DA1_PRCVEN PRECO_PADRAO, DA1CLUBE.DA1_PRCVEN PRECO_CLUBE
          FROM %table:SB1% SB1
          LEFT JOIN %table:SB5% SB5
            ON B5_FILIAL = %xFilial:SB5%
           AND B5_COD = B1_COD
           AND SB5.%notdel%
          JOIN %table:DA1% DA1PADRAO
            ON DA1PADRAO.DA1_FILIAL = %xFilial:DA1%
           AND DA1PADRAO.DA1_CODTAB = '001'
           AND DA1PADRAO.DA1_CODPRO = B1_COD
           AND DA1PADRAO.%notdel%
          JOIN %table:DA1% DA1CLUBE
            ON DA1CLUBE.DA1_FILIAL = %xFilial:DA1%
           AND DA1CLUBE.DA1_CODTAB = '100'
           AND DA1CLUBE.DA1_CODPRO = B1_COD
           AND DA1CLUBE.%notdel%
         WHERE B1_FILIAL = %xFilial:SB1%
           AND B1_YCLUBE = 'S'
           AND SB1.%notdel%
         ORDER BY 1
    endSql
    
    while !(cAliasSB1)->(EoF())
        cImagem := "" // Imagem do produto
        aFiles  := {}
        aSizes  := {}

        aDir("\system\fotos\" + allTrim((cAliasSB1)->B1_COD) + ".*", @aFiles, @aSizes) // Buscando todos os arquivos com o nome do produto

        if len(aFiles) > 0 // Encontrou pelo menos uma imagem com o código do produto
            nHandle := fopen("\system\fotos\" + aFiles[1], FO_READWRITE + FO_SHARED)
            cString := ""
            FRead( nHandle, cString, aSizes[1] ) //Carrega na variável cString, a string ASCII do arquivo.
            cImagem := Encode64(cString) // Compactando e Criptografando imagem para envio
            fclose(nHandle)
        endif

        aRetAux := {allTrim((cAliasSB1)->B1_COD),;
                    allTrim((cAliasSB1)->B1_DESC),;
                    allTrim((cAliasSB1)->B5_CEME),;
                    (cAliasSB1)->PRECO_PADRAO,;
                    (cAliasSB1)->PRECO_CLUBE,;
                    cImagem}

        aAdd(aRetPrd, aRetAux)

        (cAliasSB1)->(dbSkip())
    endDo
    (cAliasSB1)->(dbCloseArea())
return aRetPrd
