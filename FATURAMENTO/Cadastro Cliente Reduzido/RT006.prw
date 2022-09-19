#include "totvs.ch"
#include "fwmvcdef.ch
#include "topConn.ch"

/*/{Protheus.doc} WS001
Funcao para mostrar tela de clientes simplificada para cadastro no clube (somente campos necessários)
@author Paulo Cesar Camata
@since 02/11/2019
@version 12.1.17
@type function
/*/
user function RT006(nOpcao)
    local oBrowse
	private cCadastro := "Cliente Clube Casa China"
	private nOpcAux   := 0
	private aRotina   := menuDef()
	
	default nOpcao := 1

	nOpcAux := nOpcao

	oBrowse := FWMBrowse():New()
	oBrowse:SetAlias("SA1")
	oBrowse:SetDescription(cCadastro)

	oBrowse:AddLegend("SA1->A1_MSBLQL == '1'", "BR_VERMELHO", "Bloqueado")
	oBrowse:AddLegend("SA1->A1_MSBLQL != '1'", "BR_VERDE"   , "Liberado" )

	if nOpcao == 1
		oBrowse:SetFilterDefault("SA1->A1_YCLUBE = 'S'")
	endif

	oBrowse:Activate()
return nil

// Definicao dos menus disponiveis para a rotina
static function menuDef()
return FWMVCMenu("RT006")

static function ModelDef()
	local oModel
	local oStr := FWFormStruct(1, "SA1")

	// Desabilitando campos que serao obtidos a partir do CEP
	oStr:SetProperty("A1_BAIRRO" , MODEL_FIELD_WHEN, {|| .F.})
	oStr:SetProperty("A1_END"    , MODEL_FIELD_WHEN, {|| .F.})
	oStr:SetProperty("A1_EST"    , MODEL_FIELD_WHEN, {|| .F.})
	oStr:SetProperty("A1_MUN"    , MODEL_FIELD_WHEN, {|| .F.})
	oStr:SetProperty("A1_COD_MUN", MODEL_FIELD_WHEN, {|| .F.})

	if nOpcAux == 1
		oStr:SetProperty("A1_YCLUBE" , MODEL_FIELD_INIT, {|| "S"})
	else
		oStr:SetProperty("A1_YCLUBE" , MODEL_FIELD_INIT, {|| "N"})
	endif

	oStr:SetProperty("A1_PESSOA" , MODEL_FIELD_INIT, {|| "F"})
	oStr:SetProperty("A1_TIPO"   , MODEL_FIELD_INIT, {|| "F"})
	oStr:SetProperty("A1_PAIS"   , MODEL_FIELD_INIT, {|| "105"})
	
	oStr:SetProperty("A1_YSEXO"  , MODEL_FIELD_OBRIGAT, .T.)

	// Validacao do CEP
	oStr:SetProperty("A1_CEP"    , MODEL_FIELD_VALID, FWBuildFeature(STRUCT_FEATURE_VALID, "U_RT006VCEP()"))
	
	oStr:AddTrigger("A1_NOME", "A1_NREDUZ" , , {|| left(M->A1_NOME, tamSx3("A1_NREDUZ")[1])}) // Estoque do produto para Pedido de compra

	oModel := MPFormModel():New('RT006M', /*bPre*/, /*bPost*/,/*bCommit*/,/*bCancel*/)
	oModel:addFields("MASTER", , oStr)
	oModel:SetPrimaryKey({"A1_CGC"})

	if nOpcAux == 1
		oModel:getModel("MASTER"):SetDescription("Cliente Clube")
		oModel:SetDescription("Formulario de Cadastro - Cliente Clube")
	else
		oModel:getModel("MASTER"):SetDescription("Cliente")
		oModel:SetDescription("Formulario de Cadastro - Cliente")
	endif
return oModel

Static Function ViewDef()
	Local oModel := ModelDef()
	local oStr   := FWFormStruct(2, "SA1", {|x| (alltrim(x) + "|" $ "A1_NOME|A1_EMAIL|A1_CGC|A1_DTNASC|A1_END|A1_BAIRRO|A1_CEP|A1_EST|A1_MUN|A1_DDD|A1_TEL|A1_COD_MUN|A1_YSEXO|A1_COMPLEM|A1_YNUMERO|")})
	// local bBlocoImport

	oView := FWFormView():New()
	oView:SetModel(oModel)
	oView:addField("VIEW", oStr, "MASTER")
	oView:CreateHorizontalBox("CABEC"  , 100)
	oView:SetOwnerView("VIEW", "CABEC")

	if nOpcAux == 1
		oView:EnableTitleView("VIEW", "Cliente Clube China")
	else
		oView:EnableTitleView("VIEW", "Cliente")
	endif

	// bBlocoImport := {|oView| fConsultCEP(oView)}
	// oView:AddUserButton("Consultar CEP", "MAGIC_BMP", bBlocoImport, "Consultar CEP", , {MODEL_OPERATION_INSERT})
return oView

// Funcao para buscar os dados do CEP informado
user function RT006VCEP()
	local cReturn  := ""
	local cHeadRet := ""
	local oXml

	if len(M->A1_CEP) <> 8 // Tamanho invalido
		Help(nil, nil, "CEP Inválido", NIL, "Tamanho do CEP Inválido. Verifique.", 1, 0, nil, nil, nil, nil, nil, {"CEP deve possuir 8 caracteres"})
		return .F.
	endif

	// Buscando dados do cep pelo webservice
	cReturn  := HttpGet("https://viacep.com.br/ws/" + M->A1_CEP + "/xml/", "", 120, {}, @cHeadRet)
	If !empty(cReturn)
		cError := ""
		cWarning := ""

		oXml := XmlParser(cReturn, "_", @cError, @cWarning)
		If (oXml == nil)
			MsgStop("Falha ao gerar Objeto XML : " + cError + " / " + cWarning)
			Return .F.
		Endif

		if at("<erro>true</erro>", cReturn) > 0
			Help(nil, nil, "CEP Inválido", NIL, "CPF informado não é válido. Verifique.", 1, 0, nil, nil, nil, nil, nil, {"CEP informado não encontrado."})
			return .F.
		endif

		M->A1_END     := oXml:_xmlcep:_logradouro:Text
		M->A1_BAIRRO  := oXml:_xmlcep:_bairro:Text
		M->A1_MUN     := oXml:_xmlcep:_localidade:Text
		M->A1_EST     := oXml:_xmlcep:_uf:Text
		M->A1_COD_MUN := right(oXml:_xmlcep:_ibge:Text, 5)
	else
		Alert("Errado: " + cHeadRet)
	endif
return .T.

static function fConsultCEP(oView)
	local cUrl  := getNewPar("CH_URLCEP", "http://www.buscacep.correios.com.br/sistemas/buscacep/BuscaCepEndereco.cfm")
	local aSize := MsAdvSize()
	local aObject := fRetStruct(aSize) // Cria o objeto de divisao da tela
	local oDlg, oTiBrowse

	define dialog oDlg title "Consulta CEP Correios" from aSize[7],0 to aSize[6],aSize[5] PIXEL

	oTiBrowse := TIBrowser():New(aPosObj[1,1],aPosObj[1,2], aPosObj[1,3],aPosObj[1,4], cUrl, oDlg)

	ACTIVATE DIALOG oDlg CENTERED
return nil

/*/{Protheus.doc} fRetStruct
Funcao para dividir a tela em percentuais
@author Paulo Cesar Camata
@since 02/11/2019
@version 12
@param aSize, array, descricao
@type function
/*/
static function fRetStruct(aSize)
	Local aObjects := {}
	Local aInfo    := {}
	Local aPosObj  := {}

	AAdd(aObjects, {100, 100, .T., .T. } )

	aInfo   := { aSize[1], aSize[2], aSize[3], aSize[4], 5, 5}
	aPosObj := MsObjSize(aInfo, aObjects, .T. )
return aPosObj