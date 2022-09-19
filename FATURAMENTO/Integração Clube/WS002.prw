#include "totvs.ch"
#include "restful.ch"

/*/{Protheus.doc} WS002
Funcao WS REST para cadastro de clientes do clube
@author Paulo Cesar Camata
@since 04/08/2019
@version 12.1.17
@type function
/*/
user function WS002()
return nil

WSRESTFUL wscliente DESCRIPTION "WS REST manipulacao de clientes" FORMAT APPLICATION_JSON
    WSMETHOD PUT PutCliente DESCRIPTION "Inserir cliente para utilizacao do clube China"  WSSYNTAX "wscliente/PutCliente" Path "/PutCliente/"
END WSRESTFUL

// Funcao put para inserir cliente caso nao existe
WSMETHOD PUT PutCliente WSSERVICE wscliente
    local oJson, oReturn

    oJson := JsonObject():new()
	oJson:fromJson(::GetContent())

    oReturn := fValida(oJson)
    cJson   := FWJsonSerialize(oReturn, .F.)

	FreeObj(oJson)
	FreeObj(oReturn)

    ::SetContentType("application/json")
	::SetResponse(cJson)
return .T.

// Funcao para efetuar validacoes do usuario
// Modelo senha para usuário (admin) senha (123123) e dia do login 02/08/19
// admin12312302/08/19 => na base64
static function fValida(oJson)
    local cUsuario  := oJson:GetJsonText("User")
	local cPassword := oJson:GetJsonText("Password") 
    local lLogin    := .F.
	local _nOpc     := 3
    local oHashRet  := THashMap():New()

    private lMsErroAuto := .F. 
    private lMsHelpAuto	:= .F.

    if empty(cUsuario) .or. empty(cPassword)
        conout("Usuario e senhas em branco")
        oHashRet:Set("Status", 0)
		oHashRet:Set("MSGRET", "TAG User/Password nao informado!")
        return oHashRet
    endif

    // Validando usuário e senha
    cPassword := Decode64(cPassword) // Deserializando password
    nTamUsu   := len(cUsuario) // tamanho 

    if cUsuario <> left(cPassword, nTamUsu)
        conout("Usuario: " + cUsuario)
        conout("Pass: " + left(cPassword, nTamUsu))
        oHashRet:Set("Status", 0)
		oHashRet:Set("mensagem", "Usuario/Senha invalidos!")
        return oHashRet
    endif
    
    cData     := right(cPassword, 8)
    cPassword := subStr(cPassword, nTamUsu + 1, len(cPassword) - nTamUsu - 8) // Retirando somente a senha

    if cData <> DTOS(date())
        conout("Data: " + cData)
        conout("Date: " + DTOC(date()))
        oHashRet:Set("Status", 0)
		oHashRet:Set("mensagem", "Usuario/Senha invalidos!")
        return oHashRet
    endif

    // Validando login
    RpcClearEnv()
	RpcSetType(3)
	lLogin := RpcSetEnv("01", "010101", cUsuario, cPassword, , GetEnvServer())
	// lLogin := RpcSetEnv("01", "0101", cUsuario, cPassword, , GetEnvServer())

    if !lLogin 
    	conout("Login invalido")
        oHashRet:Set("Status", 0)
		oHashRet:Set("mensagem", "Usuario ou Senha invalidos!")
        return oHashRet
    endif

    // Validando campos obrigatorios
    _cNomCli := oJson:GetJsonText("Nome")
    if empty(_cNomCli)
        oHashRet:Set("Status", 0)
		oHashRet:Set("mensagem", "Nome nao informado!")
        return oHashRet
    endif

    _cCpfCnp := oJson:GetJsonText("CPF")
    if empty(_cCpfCnp)
        oHashRet:Set("Status", 0)
		oHashRet:Set("mensagem", "CPF nao informado!")
        return oHashRet
    endif

    _cEmail := oJson:GetJsonText("Email")
    if empty(_cEmail)
        oHashRet:Set("Status", 0)
		oHashRet:Set("mensagem", "Email nao informado!")
        return oHashRet
    endif

    _cSexo := oJson:GetJsonText("Sexo")
    if empty(_cSexo)
        oHashRet:Set("Status", 0)
		oHashRet:Set("mensagem", "Sexo nao informado!")
        return oHashRet
    endif

    _cCep := oJson:GetJsonText("CEP")
    if empty(_cCep)
        oHashRet:Set("Status", 0)
		oHashRet:Set("mensagem", "CEP nao informado!")
        return oHashRet
    endif

    _cEndereco := oJson:GetJsonText("Endereco")
    if empty(_cEndereco)
        oHashRet:Set("Status", 0)
		oHashRet:Set("mensagem", "Endereco nao informado!")
        return oHashRet
    endif

    _cNumero := oJson:GetJsonText("Numero")
    if empty(_cNumero)
        oHashRet:Set("Status", 0)
		oHashRet:Set("mensagem", "Numero do endereco nao informado!")
        return oHashRet
    endif

    _cBairro := oJson:GetJsonText("Bairro")
    if empty(_cBairro)
        oHashRet:Set("Status", 0)
		oHashRet:Set("mensagem", "Bairro nao informado!")
        return oHashRet
    endif

    _cCidade := oJson:GetJsonText("Cidade")
    if empty(_cCidade)
        oHashRet:Set("Status", 0)
		oHashRet:Set("mensagem", "Cidade nao informado!")
        return oHashRet
    endif

    _cCodIBGE := oJson:GetJsonText("IBGE")
    if empty(_cCodIBGE)
        oHashRet:Set("Status", 0)
		oHashRet:Set("mensagem", "Codigo IBGE nao informado!")
        return oHashRet
    endif
    
    _cEstado := oJson:GetJsonText("Estado")
    if empty(_cEstado)
        oHashRet:Set("Status", 0)
		oHashRet:Set("mensagem", "Estado nao informado!")
        return oHashRet
    endif

    _cDatNas := oJson:GetJsonText("Nascimento")
    if empty(_cDatNas)
        oHashRet:Set("Status", 0)
		oHashRet:Set("mensagem", "Data de Nascimento nao informado!")
        return oHashRet
    endif 

    // _cComplemento := oJson:GetJsonText("Complemento")
    _cTelefone    := oJson:GetJsonText("Telefone")
    _cEndereco    := _cEndereco

    _cPet := oJson:GetJsonText("Pet") // Possui Pet
    if (_cPet <> "S")
        _cPet := "N"
    endif

    _cFilho := oJson:GetJsonText("Filho") // Possui Filhos
    if (_cFilho <> "S")
        _cFilho := "N"
    endif
    
    // Verificando se cliente já existe
    dbSelectArea("SA1")
    SA1->(dbSetOrder(3))
    if SA1->(msSeek(xFilial("SA1") + _cCpfCnp))
        // if SA1->A1_YCLUBE == "S"
        //     oHashRet:Set("Status", 0)
        //     oHashRet:Set("mensagem", "Cliente ja existe na base de dados!")
        //     return oHashRet
        // endif
		
		_nOpc := 4
    endif

    // Incluindo cliente
    _aCliente := {}
	
	if _nOpc == 4 // Alteracao
        aAdd(_aCliente, {"A1_COD", SA1->A1_COD        , nil})
    endif
    
    _cNomCli := upper(_cNomCli)

	aAdd(_aCliente, {"A1_LOJA"   , "01"               , nil})	
    aAdd(_aCliente, {"A1_CGC"    , _cCpfCnp           , nil})
    aAdd(_aCliente, {"A1_NOME"   , left(_cNomCli, 40) , nil})
    aAdd(_aCliente, {"A1_NREDUZ" , left(_cNomCli, 20) , nil})
    aAdd(_aCliente, {"A1_PAIS"   , "105"              , nil})
    aAdd(_aCliente, {"A1_END"    , _cEndereco         , nil})
    // aAdd(_aCliente, {"A1_COMPLEM", _cComplemento      , nil})
    aAdd(_aCliente, {"A1_BAIRRO" , _cBairro           , nil})
    aAdd(_aCliente, {"A1_CEP"    , _cCep              , nil})
    aAdd(_aCliente, {"A1_EST"    , _cEstado           , nil})
    aAdd(_aCliente, {"A1_MUN"    , _cCidade           , nil})
    aAdd(_aCliente, {"A1_CODPAIS", "01058"            , nil})
    aAdd(_aCliente, {"A1_EMAIL"  , _cEmail            , nil})
    aAdd(_aCliente, {"A1_DDD"    , left(_cTelefone, 2), nil})
    aAdd(_aCliente, {"A1_TEL"    , subStr(_cTelefone, 3, len(_cTelefone) - 2), nil})
    aAdd(_aCliente, {"A1_PESSOA" , "F"                , nil})
    aAdd(_aCliente, {"A1_TIPO"   , "F"                , nil})
    aAdd(_aCliente, {"A1_COD_MUN", _cCodIBGE          , nil})
    aAdd(_aCliente, {"A1_DTNASC" , STOD(_cDatNas)     , nil})
	aAdd(_aCliente, {"A1_YCLUBE" , "S"                , nil})
	aAdd(_aCliente, {"A1_YSEXO"  , _cSexo             , nil})
	aAdd(_aCliente, {"A1_YNUMERO", allTrim(_cNumero)  , nil})
    aAdd(_aCliente, {"A1_YPET"   , _cPet              , nil})
	aAdd(_aCliente, {"A1_YFILHO" , _cFilho            , nil})
    
    lMsErroAuto := .F.
    // MsExecAuto({|x,y,z| CRMA980(x,y,z)}, _aCliente, _nOpc, {}) // Execauto MVC Cliente
    MsExecAuto({|x, y| Mata030(x, y)}, _aCliente, _nOpc)

    if lMsErroAuto // Erro ExecAuto
        RollBackSx8()
        cMenErr := left(mostraErro("\log\", "E_INC_CLIENTE.LOG"), 200)

        oHashRet:Set("Status", 0)
		oHashRet:Set("mensagem", cMenErr)
        return oHashRet
    endif

    oHashRet:Set("Status", 1)
	oHashRet:Set("mensagem", "Cliente inserido com sucesso!")
return oHashRet