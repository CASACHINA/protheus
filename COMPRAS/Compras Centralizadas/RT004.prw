#include "totvs.ch"
#include "fwmvcdef.ch"
#include "topConn.ch"

/*/{Protheus.doc} RT004
Tela de informacoes centralizadas de Compras (Solicitacao Transferencia / Pedido de compra)
@author Paulo Cesar Camata
@since 31/03/2019
@version 12.1.17
@type function
/*/
User function RT004()
	local oBrowse
	private cCadastro := "Compras Centralizadas"
	private aRotina   := menuDef()

	oBrowse := FWMBrowse():New()
	oBrowse:SetAlias("Z01")
	oBrowse:SetDescription(cCadastro)
	oBrowse:AddLegend("!empty(Z01->Z01_NUMNFS)", "BR_VERMELHO", "Processo faturado" )
	oBrowse:AddLegend("!empty(Z01->Z01_PEDIDO) .or. !empty(Z01->Z01_SOLTRA)", "BR_AMARELO" , "Pedido/SolicitaÁ„o gerados")
	oBrowse:AddLegend("empty(Z01->Z01_SOLTRA) .AND. empty(Z01->Z01_PEDIDO)", "BR_VERDE", "SolicitaÁ„o em Aberto")
	oBrowse:Activate()
return nil

// Definicao dos menus disponiveis para a rotina
static function menuDef()
    local aRotAux := FWMVCMenu("RT004")

	ADD OPTION aRotAux TITLE "Finalizar"  		  ACTION "U_RT004FIN" OPERATION MODEL_OPERATION_UPDATE ACCESS 0
	ADD OPTION aRotAux TITLE "Visualizar Pedido"  ACTION "U_RT004VPE" OPERATION MODEL_OPERATION_UPDATE ACCESS 0
return aRotAux

static function ModelDef()
	local oModel
	local aRel1 := {}
	local aRel2 := {}
	local oStr1 := FWFormStruct(1, "Z01")
	local oStr2 := FWFormStruct(1, "Z02")
	local oStr3 := FWFormStruct(1, "Z02")

	oStr2:SetProperty("Z02_TIPO", MODEL_FIELD_INIT, {|| "1"}) 
	oStr2:SetProperty("Z02_CODIGO", MODEL_FIELD_INIT, FWBuildFeature(STRUCT_FEATURE_INIPAD, "if(INCLUI, M->Z01_CODIGO, Z01->Z01_CODIGO)"))
	oStr2:SetProperty("Z02_PRODUT", MODEL_FIELD_VALID, FWBuildFeature(STRUCT_FEATURE_VALID, "U_RT004VPRD('1')"))
	oStr2:AddTrigger("Z02_PRODUT", "Z02_ESTOQ" , , {|| fEstPedido(M->Z02_PRODUT)}) // Estoque do produto para Pedido de compra
	oStr2:AddTrigger("Z02_PRODUT", "Z02_PRCVEN", , {|| fPrcVen(M->Z02_PRODUT)}) // Preco de venda do produto
	oStr2:AddTrigger("Z02_PRODUT", "Z02_PRCCOM", , {|| fPrcCom(M->Z02_PRODUT, M->Z01_CODFOR, M->Z02_PRCVEN)}) // Preco de compra do produto

	oStr3:SetProperty("Z02_TIPO", MODEL_FIELD_INIT, {|| "2"})
	oStr3:SetProperty("Z02_CODIGO", MODEL_FIELD_INIT, FWBuildFeature(STRUCT_FEATURE_INIPAD, "if(INCLUI, M->Z01_CODIGO, Z01->Z01_CODIGO)"))
	oStr3:SetProperty("Z02_PRODUT", MODEL_FIELD_VALID, FWBuildFeature(STRUCT_FEATURE_VALID, "U_RT004VPRD('2')"))
	oStr3:AddTrigger("Z02_PRODUT", "Z02_ESTOQ" , , {|| fEstTransf(M->Z02_PRODUT)}) // Estoque do produto para Solic. Transferencia
	oStr3:AddTrigger("Z02_PRODUT", "Z02_PRCVEN", , {|| fPrcVen(M->Z02_PRODUT)}) // Preco de venda do produto
	oStr3:AddTrigger("Z02_PRODUT", "Z02_PRCCOM", , {|| fPrcCom(M->Z02_PRODUT, M->Z01_CODFOR, , M->Z02_PRCVEN)}) // Preco de compra do produto

	oModel := MPFormModel():New('RT004M', /*bPre*/, /*bPost*/,/*bCommit*/,/*bCancel*/)
	oModel:addFields("MASTER", , oStr1)
	oModel:SetPrimaryKey({"Z01_CODIGO"})

	oModel:addGrid("DETAIL01", "MASTER", oStr2)
	oModel:GetModel("DETAIL01"):SetUniqueLine({"Z02_PRODUT"})
	oModel:GetModel("DETAIL01"):SetLoadFilter({{"Z02_TIPO", "'1'", MVC_LOADFILTER_EQUAL}})
	oModel:GetModel("DETAIL01"):SetOptional(.T.)

	aAdd(aRel1, {"Z02_FILIAL", "xFilial('Z02')"})
	aAdd(aRel1, {"Z02_CODIGO", "Z01_CODIGO"})
	oModel:SetRelation("DETAIL01", aRel1, Z02->(IndexKey(1)))
	
	oModel:addGrid("DETAIL02", "MASTER", oStr3)
	oModel:GetModel("DETAIL02"):SetUniqueLine({"Z02_PRODUT"})
	oModel:GetModel("DETAIL02"):SetLoadFilter({{"Z02_TIPO", "'2'", MVC_LOADFILTER_EQUAL}})
	oModel:GetModel("DETAIL02"):SetOptional(.T.)
	
	aAdd(aRel2, {"Z02_FILIAL", "xFilial('Z02')"})
	aAdd(aRel2, {"Z02_CODIGO", "Z01_CODIGO"})
	oModel:SetRelation("DETAIL02", aRel2, Z02->(IndexKey(1)))

	oModel:getModel("MASTER"):SetDescription("Compras Centralizadas")
	oModel:SetDescription("Formulario de Cadastro - Compras Centralizadas")
return oModel

Static Function ViewDef()
	Local oView, bImpSol, bImpPed
	Local oModel := ModelDef()
	Local oStr1  := FWFormStruct(2, "Z01")
	Local oStr2  := FWFormStruct(2, "Z02", {|x| !(alltrim(x) + "|" $ "Z02_FILIAL|Z02_CODIGO|Z02_TIPO|")})
	Local oStr3  := FWFormStruct(2, "Z02", {|x| !(alltrim(x) + "|" $ "Z02_FILIAL|Z02_CODIGO|Z02_TIPO|Z02_CUSTOM|")})

	oView := FWFormView():New()
	oView:SetModel(oModel)
	oView:addField("VIEW_Z01", oStr1, "MASTER")
	oView:addGrid( "VIEW_Z02", oStr2, "DETAIL01")
	oView:addGrid( "VIEW_Z03", oStr3, "DETAIL02")
	oView:CreateHorizontalBox("CABEC"  , 20)
	oView:CreateHorizontalBox("ITENS01", 40)
	oView:CreateHorizontalBox("ITENS02", 40)
	oView:SetOwnerView("VIEW_Z01", "CABEC")
	oView:SetOwnerView("VIEW_Z02", "ITENS01")
	oView:SetOwnerView("VIEW_Z03", "ITENS02")

	oView:AddIncrementField("VIEW_Z02", "Z02_ITEM")
	oView:AddIncrementField("VIEW_Z03", "Z02_ITEM")

	oView:EnableTitleView("VIEW_Z02", "Pedido de Compras")
	oView:EnableTitleView("VIEW_Z03", "SolicitaÁ„o de TransferÍncia")

	// Adicionando botao de usu·rio
	bImpPed := {|oView, oModel| fImpGrid(oView, 1)}
	oView:AddUserButton("Importar Pedido", "MAGIC_BMP", bImpPed, "Importar itens para GRID Pedido Compra", , {MODEL_OPERATION_INSERT})

	bImpSol := {|oView, oModel| fImpGrid(oView, 2)}
	oView:AddUserButton("Importar Sol. Transf", "MAGIC_BMP", bImpSol, "Importar itens para GRID Solic. Transf", , {MODEL_OPERATION_INSERT})
return oView

// Funcao para efetuar a busca do estoque para produtos no GRID de Pedido de Compras
static function fEstPedido(cCodPro)
	local cArmEst := getNewPar("CH_ARMDIS", "01")
return CalcEst(cCodPro, cArmEst, dDataBase)[1]

// Funcao para buscar o saldo em estoque do produto na filial de distribuicao conforme parametro CH_FILDES
static function fEstTransf(cCodPro)
	local cArmEst := getNewPar("CH_ARMDIS", "01")
	local cFilDis := getNewPar("CH_FILDIS", "010104") // Parametro referente a filial de distribuicao (Pedido de compra sera criado nessa filial)
	local cBkpFil := cFilAnt
	local nQtdEst := 0

	cFilAnt := cFilDis // Alterando filial para buscar saldo corrente
	nQtdEst := CalcEst(cCodPro, cArmEst, dDataBase)[1] // Saldo em estoque do produto

	dbSelectArea("SB2")
	SB2->(dbSetOrder(1))
	if SB2->(dbSeek(xFilial("SB2") + cCodPro + cArmEst))
		nQtdEst -= SB2->B2_QEMP
	endif

	cFilAnt := cBkpFil // Voltando para filial ativa do sistema
return nQtdEst

// Funcao para buscar o preÁo de venda do produto
static function fPrcVen(cCodPro)
	local nPrcVen := 0 // preco de venda a ser retornado pela funcao
	local cTabVen := getNewPar("MV_TABPAD", "") // tabela de preco de venda padrao da filial
	local cArmEst := getNewPar("CH_ARMDIS", "01")

	if empty(cTabVen) // Parametro invalido
		msgInfo("Par‚metro tabela de preÁo de venda n„o preenchido corretamente (MV_TABPAD). Verifique.")
		return 0
	endif

	dbSelectArea("DA1")
	DA1->(dbSetOrder(1)) // DA1_FILIAL+DA1_CODTAB+DA1_CODPRO
	if DA1->(dbSeek(xFilial("DA1") + cTabVen + cCodPro)) .and. DA1->DA1_PRCVEN > 0
		nPrcVen := DA1->DA1_PRCVEN 
	endif
return nPrcVen

// Funcao para efetuar a finalizacao da rotina em aberto
user Function RT004FIN()
	if !empty(Z01->Z01_NUMNFS)
		msgStop("Registro FATURADO. Verifique.")
        return nil
	endif

	// Validacoes
    if !empty(Z01->Z01_PEDIDO) // Pedido de compra ja gerado
        msgStop("Pedido de Compra No: " + Z01->Z01_PEDIDO + " j· gerado. Verifique.")
        return nil
    endif

    if !empty(Z01->Z01_SOLTRA) // Solicitacao de transferencia
        msgStop("SolicitaÁ„o de transferÍncia No: " + Z01->Z01_SOLTRA + " j· gerado. Verifique.")
        return nil
    endif

	Processa({|| fFinaliza()}, "Finalizando solicitaÁ„o. Aguarde...") // Finalizando solicitaÁ„o
return nil

// Funcao chamada na validaÁ„o do campo Z02_PRODUT
user function RT004VPRD(cTipo)
	dbSelectArea("SB1")
	SB1->(dbSetOrder(1))
	if SB1->(msSeek(xFilial("SB1") + M->Z02_PRODUT, .F.)) // Produto informado existe no cadastro
		if cTipo == "1" // GRID pedido de compra
			if SB1->B1_TIPO <> "ME" .and. !msgYesNo("Produto " + M->Z02_PRODUT + " n„o È do tipo ME - Produto Acabado. Desenha Continuar?")
				return .F.
			endif
		elseif cTipo == "2" // GRID Solicitacao de transferencia
			if SB1->B1_TIPO <> "PA" .and. !msgYesNo("Produto " + M->Z02_PRODUT + " n„o È do tipo PA - Mercadoria para Revenda. Desenha Continuar?")
				return .F.
			endif
		endif
	endif
return .T.

// Funcao para buscar o preÁo de compra do produto na tabela de preÁo do fornecedor
static function fPrcCom(cCodPro, cCodFor, nPrcVen)
	local nPrcCom := 0

	default nPrcVen := 0

	dbSelectArea("AIB") // Itens da tabela de preÁo de compra
	AIB->(dbSetOrder(3)) // AIB_FILIAL+AIB_CODFOR+AIB_CODPRO
	if AIB->(dbSeek(xFilial("AIB") + cCodFor + cCodPro))
		nPrcCom := AIB->AIB_PRCCOM
	else
		msgInfo("N„o foi encontrado tabela de preÁo para o Fornecedor " + cCodFor + " e produto " + cCodPro + " informado.")
	endif

	if nPrcVen > 0 .and. nPrcCom > 0 .and. nPrcCom >= nPrcVen
		msgInfo("PreÁo de compra maior ou igual ao preÁo de venda. Verifique.")
	endif
return nPrcCom

// Funcao para finalizar a solicitaÁ„o de compras (Barra de processamento)
static function fFinaliza()
	local cFilDis  := getNewPar("CH_FILDIS", "010104")
	local cItem    := "0000"
	local aItens   := {}
	local aIteAux  := {}
	local aCabec   := {}
	local cBkpFil  := cFilAnt
	local cArmEst  := getNewPar("CH_ARMDIS", "01")
	local cNumPed  := GetNumSC7(.T.)
	local nPreco, nTotal, oModel

	private lMsErroAuto := .F.

	procRegua(3) // Tamanho da regua de processamento
	incproc()
	Begin Transaction

	incproc("Criando pedido de compra. Aguarde... (1/2)")
	
	dbSelectArea("SB1")
	SB1->(dbSetOrder(1))

	// Gerar pedido de compra
	dbSelectArea("Z02")
	Z02->(dbSetOrder(2))
	Z02->(dbGoTop())
	if Z02->(dbSeek(xFilial("Z02") + Z01->Z01_CODIGO + "1")) // Buscando todos os itens 
		while !Z02->(EoF()) .and. allTrim(xFilial("Z02") + Z01->Z01_CODIGO + "1") == allTrim(Z02->Z02_FILIAL + Z02->Z02_CODIGO + Z02->Z02_TIPO)
			cItem := soma1(cItem)

			nPreco := fPrcCom(Z02->Z02_PRODUT, Z01->Z01_CODFOR, Z02->Z02_PRCVEN)
			nTotal := Z02->Z02_QUANT * nPreco

			SB1->(msSeek(xFilial("SB1") + Z02->Z02_PRODUT)) // Posicionando no produto (Erro execauto)

			aIteAux := {}
			aAdd(aIteAux, {"C7_ITEM"   , cItem, nil})
			aAdd(aIteAux, {"C7_PRODUTO", Z02->Z02_PRODUT, nil})
			aAdd(aIteAux, {"C7_QUANT"  , Z02->Z02_QUANT , nil})
			// aAdd(aIteAux, {"C7_PRECO"  , nPreco, nil})
			// aAdd(aIteAux, {"C7_TOTAL"  , nTotal, nil})
			aadd(aIteAux, {"C7_YCLIENT", "999001" + subStr(cFilAnt, 5, 2), nil})

			aAdd(aItens, aIteAux)

			Z02->(dbSkip())
		endDo
	endif

	if len(aItens) > 0 // Achou itens para inserir pedido de compra
		cFilAnt := cFilDis // Trocando filial para CD
		dbSelectArea("SA2")
		SA2->(dbSetOrder(1))
		SA2->(msSeek(xFilial("SA2") + Z01->Z01_CODFOR + Z01->Z01_LOJFOR, .F.))

		aCabec := {}
		aAdd(aCabec, {"C7_NUM"    , cNumPed        , nil})
		aAdd(aCabec, {"C7_EMISSAO", dDataBase      , nil})
		aAdd(aCabec, {"C7_FORNECE", Z01->Z01_CODFOR, nil})
		aAdd(aCabec, {"C7_LOJA"   , Z01->Z01_LOJFOR, nil})
		aadd(aCabec, {"C7_COND"   , SA2->A2_COND   , nil})
		aadd(aCabec, {"C7_CONTATO", "AUTO"         , nil})
		aadd(aCabec, {"C7_FILENT" , xFilial("SC7") , nil})

		MSExecAuto({|v,x,y,z| MATA120(v,x,y,z)}, 1, aCabec, aItens, 3) // Inserir pedido de compra
		cFilAnt := cBkpFil // Voltando para filial original
		if !lMsErroAuto
			recLock("Z01", .F.)
				Z01->Z01_PEDIDO := SC7->C7_NUM
			Z01->(msUnlock())
		else
			disarmTransaction()
			mostraErro()
			msgStop("Erro ao criar pedido de compra")
			return nil
		endif
	endif
	
	incproc("Criando SolicitaÁ„o de transferÍncia. Aguarde... (2/2)")
	// Gerar solicitaÁ„o de transferencia
	dbSelectArea("Z02")
	Z02->(dbSetOrder(2))
	Z02->(dbGoTop())
	if Z02->(msSeek(xFilial("Z02") + Z01->Z01_CODIGO + "2", .F.)) // Buscando todos os itens 
		oModel := FwLoadModel("MATA311")
		aItens := {}
 
		// Adicionando os dados do ExecAuto cab
		aCabec := {}
		aAdd(aCabec, {"NNS_FILIAL", cFilDis, Nil})
		aAdd(aCabec, {"NNS_DATA"  , dDataBase, Nil})
		aAdd(aCabec, {"NNS_SOLICT", __cUserID, Nil})
		aAdd(aCabec, {"NNS_CLASS" , criaVar("NNS_CLASS", .T.), Nil})
		aAdd(aCabec, {"NNS_ESPECI", criaVar("NNS_ESPECI", .T.), Nil})

		while !Z02->(EoF()) .and. allTrim(xFilial("Z02") + Z01->Z01_CODIGO + "2") == allTrim(Z02->Z02_FILIAL + Z02->Z02_CODIGO + Z02->Z02_TIPO)

			// Verificando se o saldo em estoque È suficiente para atender todo a quantidade solicitada
			nQtdEst := fEstTransf(Z02->Z02_PRODUT) // Recalculando saldo
			if nQtdEst <> Z02->Z02_ESTOQ
				recLock("Z02", .F.)
					Z02->Z02_ESTOQ := nQtdEst
				Z02->(msUnlock())
			endif
			
			// solicitacao de transferencia nao pode possuir qtde maior que o saldo em estoque.
			nQtdSol := min(Z02->Z02_QUANT, Z02->Z02_ESTOQ)

			if nQtdSol > 0
				// Adicionando os dados do ExecAuto Item
				aIteAux := {}
				aAdd(aIteAux, {"NNT_FILIAL", cFilDis, Nil})
				aAdd(aIteAux, {"NNT_FILORI", cFilDis, Nil})
				aAdd(aIteAux, {"NNT_PROD"  , Z02->Z02_PRODUT, Nil})
				aAdd(aIteAux, {"NNT_LOCAL" , cArmEst, Nil})
				aAdd(aIteAux, {"NNT_LOCALI", criaVar("NNT_LOCALI", .F.), Nil})
				aAdd(aIteAux, {"NNT_QUANT" , nQtdSol, Nil})
				aAdd(aIteAux, {"NNT_FILDES", cFilAnt, Nil})
				aAdd(aIteAux, {"NNT_PRODD" , Z02->Z02_PRODUT, Nil})
				aAdd(aIteAux, {"NNT_LOCLD" , cArmEst, Nil})

				// no item o array precisa de um nivel superior.
				aAdd(aItens, aIteAux)
			else
				disarmTransaction()
				msgInfo("Produto " + allTrim(Z02->Z02_PRODUT) + " n„o possui saldo no CD. N„o ser· criada solicitaÁ„o de transferÍncia para este produto." )
			endif

			Z02->(dbSkip())
		endDo

		if len(aItens) > 0
			cFilAnt := cFilDis // Trocando filial para CD
			lMsErroAuto := .F. // Chamando a inclus„o - Modelo 1
			
			FWMVCRotAuto(oModel, "NNS", 3, {{"NNSMASTER", aCabec}, {"NNTDETAIL", aItens}})
			cFilAnt := cBkpFil // Voltando para filial original
			if !lMsErroAuto
				recLock("Z01", .F.)
					Z01->Z01_SOLTRA := NNS->NNS_COD
				Z01->(msUnlock())

			else // Se houve erro no ExecAuto, mostra mensagem
				disarmTransaction()
				mostraErro()
				msgStop("Erro ao criar solicitaÁ„o de transferÍncia.")
				return nil
			EndIf
		endif
	endif
	end Transaction

	MsgInfo("Registro finalizado com SUCESSO.", "Sucesso")
return nil

// Funcao para importar arquivo para grid Pedido
static function fImpGrid(oView, nGrid)
	local aPergs     := {}
    local cSeparador := chr(9)
	local oModelMas  := oView:getModel("MASTER")
	local aRet
	
	default nGrid := 1

	// Verificando se os campos Fornecedor e loja estao preenchidos
	if empty(oModelMas:getValue("Z01_CODFOR")) .or. empty(oModelMas:getValue("Z01_LOJFOR"))
		HELP(' ', 1, "Fornecedor n„o informado", , "Informe o fornecedor no cabeÁalho.", 2, 0,,,,,, "Informe os campos CÛdigo e Loja do fornecedor.")
		return nil
	endif

    aAdd(aPergs, {6, "Caminho Arquivo: ", space(200), , , , 90, .T., "Arquivo CSV | *.CSV", , GETF_LOCALHARD + GETF_NETWORKDRIVE})
    If ParamBox(aPergs, "Parametros ", aRet) // Usu·rio confirmou a tela de parametro
        if !file(mv_par01) // Arquivo nao existe
            msgStop("Arquivo n„o encontrado.", "ARQUIVO NAO EXISTE")
            return nil
        endIf

        if !upper(right(allTrim(mv_par01), 3)) $ "CSV"
            msgStop("Extens„o do arquivo informado n„o È CSV. Verifique.", "EXTENSAO INVALIDA")
            return nil
        endif
        
        // Funcao para efetuar a importaÁ„o do arquivo
        Processa({|| fImpArq(allTrim(mv_par01), oView, nGrid)}, "Importando...") // Inicializa a regua de processamento
    endif
return nil

// Funcao para efetuar a importaÁ„o do arquivo
static function fImpArq(cCamArq, oView, nGrid)
	local oFile      := FWFileReader():New(cCamArq)
	local oModGri1   := oView:getModel("DETAIL01") // Model Grid1 PC
	local oModGri2   := oView:getModel("DETAIL02") // Model Grid2 Sol Transf
	local cSeparador := ";"
	local nTotLin, aLines, aLinAux, nUltLin, nNewLin, nP
	
	oFile:Open()
    aLines := oFile:getAllLines()

	nTotLin := len(aLines) + 1
    ProcRegua(nTotLin) // Tamanho da regua de processamento

	incProc("Processando linha 1 de " + cValToChar(nTotLin))

	dbSelectArea("SB1")
	SB1->(dbSetOrder(1))

	for nP := 1 to len(aLines)
        incProc("Processando linha " + cValToChar(nP) + " de " + cValToChar(nTotLin))
        aLinAux := Strtokarr2(aLines[nP], cSeparador, .T.)

		if SB1->(msSeek(xFilial("SB1") + padR(aLinAux[1], tamSx3("B1_COD")[1]), .F.))
			if nGrid == 1 // GRID 1 - PEDIDO DE COMPRA
				
				nUltLin := oModGri1:length()
				oModGri1:goline(nUltLin)
				if !empty(oModGri1:getValue("Z02_PRODUT"))
					nNewLin := oModGri1:addLine()

					if nUltLin == nNewLin
						msgStop("ERRO AO INCLUIR LINHA GRID 1")
						return nil
					endif
					// oModGri1:goLine(nNewLin)
				endif
				
				if !oModGri1:SetValue("Z02_PRODUT", aLinAux[1]) // Produto
					return .F.
				endif

				if !oModGri1:SetValue("Z02_QUANT" , val(strTran(aLinAux[2], ",", "."))) // Quantidade
					return .F.
				endif

			elseif nGrid == 2 // GRID 2 - SOLICITACAO DE TRANSFERENCIA
				nUltLin := oModGri2:length()
				oModGri2:goline(nUltLin)

				if !empty(oModGri2:getValue("Z02_PRODUT"))
					nNewLin := oModGri2:addLine()

					if nUltLin == nNewLin
						msgStop("ERRO AO INCLUIR LINHA GRID 2")
						return nil
					endif
					oModGri2:goLine(nNewLin)
				endif
				
				oModGri2:SetValue("Z02_PRODUT", aLinAux[1]) // Produto
				oModGri2:SetValue("Z02_QUANT" , val(strTran(aLinAux[2], ",", "."))) // Quantidade
			endif
		else
			msgInfo("Produto " + aLinAux[1] + " n„o encontrado no cadastro. Verifique arquivo.")
		endif
	next nP

	// Retornando para a primeira linha de todas as GRIDs
	oModGri1:goline(1)
	oModGri2:goline(1)
return nil

// Funcao para visualizar o pedido de compra j· gerado
user function RT004VPE(cAlias, nRet, nOpcX)
	local cFilDis := getNewPar("CH_FILDIS", "010104") // Parametro referente a filial de distribuicao (Pedido de compra sera criado nessa filial)
	local cFilBkp := cFilAnt
	local cNumPed := Z01->Z01_PEDIDO
	local aArea   := SC7->(getArea())

	if empty(cNumPed)
		msgStop("Pedido de compra n„o gerado. Verifique.", "COMPRA SEM PEDIDO")
		return nil
	endif

	cFilAnt := cFilDis
	dbSelectArea("SC7")
	SC7->(dbSetOrder(1))
	if SC7->(msSeek(xFilial("SC7") + cNumPed, .F.))
		mata120(1, nil, nil, 2) // Visualizar pedido de Compra
	else
		msgStop("Pedido n„o encontrado na filial Distribuidora. Verifique.")
	endif
	cFilAnt := cFilBkp
	restArea(aArea)
return nil

/*/{Protheus.doc} RT004
Funcao para efetuar alterar o campo NF de transferencia da solicitaÁ„o (Central de compras) na efetivacao da solicitaÁ„o de transferencia
Funcao chamada no PE MATA311
@author Paulo Cesar Camata
@since 20/04/2019
@version 12.1.17
@type function
/*/
user function RT004NF(cNumSol)
	local aArea  := NNT->(getArea())
	local lAchou := .F.
	local _cArmCom := getNewPar("EC_ARMCOM", "90") 
	
	lOCAL _cFilEcom := getNewPar("EC_FILIAL", "010104") 

	dbSelectArea("Z01")
	Z01->(dbSetOrder(3)) // Z01_FILIAL+Z01_SOLTRA

	dbSelectArea("NNT")
	NNT->(dbSetOrder(1))
	NNT->(dbGoTop())
	NNT->(msSeek(xFilial("NNT") + cNumSol, .F.))

	while !NNT->(EoF()) .and. !lAchou .and. allTrim(NNT->NNT_FILIAL + NNT->NNT_COD) == allTrim(xFilial("NNT") + cNumSol)
		
		if ALLTRIM(NNT->NNT_LOCLD) == ALLTRIM(_cArmCom) .AND. ALLTRIM(NNT->NNT_FILIAL) == ALLTRIM(_cFilEcom)
			DbSelectArea("SB1")
			SB1->(DbSetOrder(1))
			If SB1->(DbSeek(xFilial('SB1')+NNT->NNT_PROD)) .AND. ALLTRIM(SB1->B1_YB2B)   == 'S'
				recLock("SB1", .F.)
					SB1->B1_YESTB2B := "S"
				SB1->(msUnlock())
			ENDIF
		ENDIF
		if !empty(NNT->NNT_DOC) // N?mero da nota fiscal faturada
			if Z01->(msSeek(NNT->NNT_FILDES + cNumSol, .F.)) // Caso solicitacao nao tenha sido gerado da central de compras
				recLock("Z01", .F.)
					Z01->Z01_NUMNFS := NNT->NNT_DOC
				Z01->(msUnlock())

				lAchou := .T. // Flag para sair do while
			endIf
		endIf

		NNT->(dbSkip())
	endDo
	restArea(aArea)
return .T.
