#include "totvs.ch"
#include "fwmvcdef.ch"

/*/{Protheus.doc} EC0007
Funcao para listagem do arquivo de log
@type function
@version 12.1.25
@author Paulo Camata (Camatech)
@since 25/08/2020
/*/
user function EC0007()
    local oBrowse
    private cTitle  := "Log Integração B2B/E-Commerce"
	private aRotina := menuDef()

    dbSelectArea("ZZ3")
	ZZ2->(DBSetOrder(1))

    oBrowse := FWMBrowse():New()
	oBrowse:SetAlias("ZZ3")
	oBrowse:SetDescription(cTitle)
    oBrowse:AddLegend("ZZ3->ZZ3_STATUS == 'E'", "BR_VERMELHO", "Erro")
    oBrowse:AddLegend("ZZ3->ZZ3_STATUS == 'O'", "BR_VERDE"   , "OK")
    oBrowse:AddLegend("ZZ3->ZZ3_STATUS == 'A'", "BR_AMARELO" , "Atenção")
	oBrowse:Activate()
return nil

/*/{Protheus.doc} menuDef
Funcao para criar as opcoes disponiveis no menu (INCLUIR, ALTERAR, ETC)
@type function
@version 12.1.25
@author Paulo Camata (Camatech)
@since 25/08/2020
/*/
static function menuDef()
    aRotina := FWMVCMenu("EC0007")

    ADD OPTION aRotina Title 'Atualiz Produtos' Action 'U_EC0007EX(1)' OPERATION MODEL_OPERATION_UPDATE ACCESS 0
    ADD OPTION aRotina Title 'Importar Pedidos' Action 'U_EC0007EX(2)' OPERATION MODEL_OPERATION_UPDATE ACCESS 0
return aRotina

/*/{Protheus.doc} ModelDef
Definicao dos campos e seus dados
@type function
@version 12.1.25
@author Paulo Camata (Camatech)
@since 25/08/2020
/*/
static function ModelDef()
	local oModel
	local oStr1 := FWFormStruct(1, "ZZ3")

	oModel := MPFormModel():New("EC0007M", /*bPre*/, /*bPost*/,/*bCommit*/,/*bCancel*/)
	oModel:addFields("MASTER", , oStr1)
	oModel:GetModel("MASTER"):SetPrimaryKey({"ZZ3_DATA", "ZZ3_HORA", "ZZ3_ROTINA"})

	oModel:SetDescription("Formulário de Cadastro")
return oModel

/*/{Protheus.doc} ViewDef
Definicao dos campos e desenho na tela
@type function
@version 12.1.25
@author Paulo Camata (Camatech)
@since 25/08/2020
/*/
Static Function ViewDef()
	Local oView
	Local oModel := ModelDef()
	local oStr1  := FWFormStruct(2, "ZZ3")

	oView := FWFormView():New() // Cria o objeto de View
	oView:SetModel(oModel) // Define qual o Modelo de dados será utilizado
    oView:addField("VIEW_ZZ3", oStr1, "MASTER")

	oView:CreateHorizontalBox("CABEC", 100)
	oView:SetOwnerView("VIEW_ZZ3", "CABEC")
return oView

/*/{Protheus.doc} EC07LOG
Funcao para efetuar a inclusao de log do B2B/E-Commerce
@type function
@version 12.1.25
@author Paulo Camata (Camatech)
@since 25/08/2020
@param cRotina, character, Nome da Rotina
@param cStatus, character, Status (E=Erro, A=Atencao, O=OK)
@param cTexto, character, Texto caso status diferente de O=OK
/*/
user function EC07LOG(cCodigo, cRotina, cStatus, cTexto, cSeq)
    default cSeq := "0000"
    
    // if cSeq == "0000" // Nao informado
    //     cSeq := fLastSeq(cCodigo) // buscar proxima sequencia disponivel
    // endif

    // recLock("ZZ3", .T.)
    //     ZZ3->ZZ3_FILIAL := xFilial("ZZ3")
    //     ZZ3->ZZ3_CODIGO := cCodigo
    //     ZZ3->ZZ3_SEQ    := cSeq
    //     ZZ3->ZZ3_DATA   := dDataBase
    //     ZZ3->ZZ3_HORA   := Time()
    //     ZZ3->ZZ3_ROTINA := cRotina
    //     ZZ3->ZZ3_STATUS := cStatus
    //     ZZ3->ZZ3_TEXTO  := cTexto
    // ZZ3->(msUnlock())
return cSeq

/*/{Protheus.doc} EC0007EX
Funcao para executar as funcoes de integracoes
@type function
@version 12.1.25
@author Paulo Camata (Camatech)
@since 25/08/2020
@param nTipo, numeric, Tipo de execucao (1=Produto, 2=Pedido)
/*/
user function EC0007EX(nTipo)
    if nTipo == 1 // Produto
        Processa({|| U_EC0002(0, .F.)}, "Atualizando produtos. Aguarde...") // Finalizando solicitação
    elseif nTipo == 2 // Pedido
        Processa({|| U_EC0007(.F.)}, "Importanto pedidos. Aguarde...") // Finalizando solicitação
    endif
return nil

/*/{Protheus.doc} fLastSeq
Funcao para buscar a proxima sequencia disponivel pelo codigo enviado
@type function
@version 12.1.25
@author Paulo Camata (Camatech)
@since 31/08/2020
@param cCodLog, character, Codigo do log que sera buscado a prox sequencia
/*/
static function fLastSeq(cCodLog)
    local cAliTemp := getNextAlias()

    BeginSql Alias cAliTemp
        SELECT MAX(ZZ3_SEQ) ZZ3_SEQ
          FROM %table:ZZ3%
         WHERE ZZ3_CODIGO = %Exp:cCodLog%
           AND ZZ3_FILIAL = %xFilial:ZZ3%
           AND %notdel%
    EndSql

    if (cAliTemp)->ZZ3_SEQ > 0
        _cSeq := soma1((cAliTemp)->ZZ3_SEQ)
    else
        _cSeq := "0001"
    endif
    (cAliTemp)->(DBCloseArea())
return _cSeq