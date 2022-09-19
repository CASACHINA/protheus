#INCLUDE 'PROTHEUS.CH'
#INCLUDE 'TOPCONN.CH'
#include 'tbiconn.ch'
#include "RWMAKE.CH"
#include 'parmtype.ch'

/*
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
++-----------------------------------------------------------------------------++
++ Função    | MT120FIM | Autor  | Anderson Jose Zelenski  | Data | 13/12/2020 ++
++-----------------------------------------------------------------------------++
++ Descrição | Iniciar a solicitação no Fluig                                  ++
++-----------------------------------------------------------------------------++
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
*/

User Function MT120FIM()
Local nOpcao := PARAMIXB[1]   // Opção Escolhida pelo usuario 3-inclui  4-altera  5-Exclui
Local cNumPC := PARAMIXB[2]   // Numero do Pedido de Compras
Local nOpcA  := PARAMIXB[3]   // Indica se a ação foi Cancelada = 0  ou Confirmada = 1.

Local lRet		:= .T.

Local aCardBase	:= {}
Local aCardData	:= {}
Local cQryTracke:= ""
Local cQryItens := ""
Local aRecnoSCR := {}

Local cItemAprov := '0'
Local nItemAprov := 0
Local cItem 	:= '0'
Local nItem 	:= 0
Local cUserComp := ""

// Inclusao ou alteração do Pedido de compras
If nOpcA == 1 .And. (nOpcao == 3 .Or. nOpcao == 4)

	SC7->(DbSetOrder(1))
	SC7->(DbSeek(xFilial("SC7")+cNumPC))
  
	DbSelectArea("SA2")
	SA2->(DbSetOrder(1))
	SA2->(DbSeek(xFilial("SA2")+SC7->C7_FORNECE+SC7->C7_LOJA))
	
	aAdd(aCardBase,{'txtEmpresa',Alltrim(FWFilialName())})
	aAdd(aCardBase,{'txtPedidoFilial',SC7->C7_FILIAL})
	aAdd(aCardBase,{'txtPedidoNumero',SC7->C7_NUM})
	aAdd(aCardBase,{'txtPedidoEmissao',DtoC(SC7->C7_EMISSAO)})
	
	aAdd(aCardBase,{'txtFornCodigo',Alltrim(SA2->A2_COD)})
	aAdd(aCardBase,{'txtFornLoja',Alltrim(SA2->A2_LOJA)})
	aAdd(aCardBase,{'txtFornecedorNome',Alltrim(SA2->A2_NOME)})
	aAdd(aCardBase,{'txtFornRazaoSocial',Alltrim(SA2->A2_NOME)})
	aAdd(aCardBase,{'txtCNPJ',Alltrim(Transform(SA2->A2_CGC,PesqPict('SA2','A2_CGC')))})
	
	aAdd(aCardBase,{'txtEndereco',Alltrim(SA2->A2_END)})
	aAdd(aCardBase,{'txtCEP',Alltrim(Transform(SA2->A2_CEP,PesqPict('SA2','A2_CEP')))})
	aAdd(aCardBase,{'txtBairro',Alltrim(SA2->A2_BAIRRO)})
	aAdd(aCardBase,{'txtCidade',Alltrim(SA2->A2_MUN)})
	aAdd(aCardBase,{'txtUF',Alltrim(SA2->A2_EST)})
	
	aAdd(aCardBase,{'txtComplemento',Alltrim(SA2->A2_COMPLEM)})
	aAdd(aCardBase,{'txtInscMunicipal',Alltrim(SA2->A2_INSCRM)})
	aAdd(aCardBase,{'txtInscEstadual',Alltrim(SA2->A2_INSCR)})
	
	aAdd(aCardBase,{'txtContato',Alltrim(SC7->C7_CONTATO)})
	aAdd(aCardBase,{'txtEmailContato',Alltrim(SA2->A2_EMAIL)})
	aAdd(aCardBase,{'txtDDD',Alltrim(SA2->A2_DDD)})
	aAdd(aCardBase,{'txtTelefone',Alltrim(SA2->A2_TEL)})
	
	aAdd(aCardBase,{'txtComprador',Alltrim(UsrFullName(SC7->C7_USER))})
	aAdd(aCardBase,{'txtCondicaoDescricao',Alltrim(Posicione("SE4",1,xFilial("SE4")+SC7->C7_COND,"E4_DESCRI"))})
	
	aAdd(aCardBase,{'pedidoStatus','P'})

	aAdd(aCardBase,{'txtNomeFilial',Alltrim(Posicione("SA1",1,xFilial("SA1")+SC7->C7_YCLIENT,"A1_NREDUZ"))})
	aAdd(aCardBase,{'txtCodFilial',SC7->C7_YCLIENT})
	aAdd(aCardBase,{'txtCompradorEmail',UsrRetMail(Alltrim(SC7->C7_USER))})
	cUserComp := GetLogFlg(Alltrim(SC7->C7_USER))

	
	// Separa as alçadas por grupo de aprovação.
	cQryTracke := " SELECT CR_GRUPO AS GRUPO, CR_ITGRP AS ITEMGRP, CR_TIPO AS TIPO, DBL_CC AS CUSTO, CR_NIVEL AS NIVEL, CR_USER AS USUARIO, CR_APROV AS APROVADOR, AK_NOME AS NOME, AK_LOGIN AS LOGIN, CR_TOTAL AS TOTAL, SCR.R_E_C_N_O_ AS RECNOSCR"
	cQryTracke += " FROM "+RetSqlName("SCR")+" SCR "
	cQryTracke += "		LEFT JOIN "+RetSqlName("DBL")+" DBL ON DBL.DBL_FILIAL = '"+xFilial("DBL")+"' AND DBL_GRUPO = CR_GRUPO AND DBL.D_E_L_E_T_ = ' ' "
	cQryTracke += "		LEFT JOIN "+RetSqlName("SAK")+" SAK ON SAK.AK_FILIAL = '"+xFilial("SAK")+"' AND SAK.AK_COD = SCR.CR_APROV AND SAK.AK_USER = SCR.CR_USER AND SAK.D_E_L_E_T_ = ' ' "
	cQryTracke += " WHERE SCR.CR_FILIAL = '"+xFilial("SCR")+"' "
	cQryTracke += "		AND SCR.CR_NUM = '"+cNumPC+"' "
	cQryTracke += "		AND SCR.CR_TIPO IN ('PC') "
	cQryTracke += " 	AND SCR.D_E_L_E_T_ = ' ' "
	cQryTracke += " UNION "
	cQryTracke += " SELECT CR_GRUPO AS GRUPO, CR_ITGRP AS ITEMGRP, CR_TIPO AS TIPO, DBL_CC AS CUSTO, CR_NIVEL AS NIVEL, CR_USER AS USUARIO, CR_APROV AS APROVADOR, AK_NOME AS NOME, AK_LOGIN AS LOGIN, CR_TOTAL AS TOTAL, SCR.R_E_C_N_O_ AS RECNOSCR"
	cQryTracke += " FROM "+RetSqlName("SCR")+" SCR "
	cQryTracke += "		LEFT JOIN "+RetSqlName("DBL")+" DBL ON DBL.DBL_FILIAL = '"+xFilial("DBL")+"' AND DBL_GRUPO = CR_GRUPO AND DBL_ITEM = CR_ITGRP AND DBL.D_E_L_E_T_ = ' ' "
	cQryTracke += "		LEFT JOIN "+RetSqlName("SAK")+" SAK ON SAK.AK_FILIAL = '"+xFilial("SAK")+"' AND SAK.AK_COD = SCR.CR_APROV AND SAK.AK_USER = SCR.CR_USER AND SAK.D_E_L_E_T_ = ' ' "
	cQryTracke += " WHERE SCR.CR_FILIAL = '"+xFilial("SCR")+"' "
	cQryTracke += "		AND SCR.CR_NUM = '"+cNumPC+"' "
	cQryTracke += "		AND SCR.CR_TIPO IN ('IP') "
	cQryTracke += " 	AND SCR.D_E_L_E_T_ = ' ' "
	cQryTracke += " ORDER BY CR_GRUPO, CR_ITGRP, CR_NIVEL, CR_USER "

	If Select('QRY') <> 0
		DbSelectArea('QRY')
		DbCloseArea()
	Endif

	TCQUERY cQryTracke NEW ALIAS "QRY"
	
	cGrpAprov 	:= ""
	cItemAprov 	:= '0'
	aRecnoSCR 	:= {}
	
	While !QRY->(Eof())
		// Valida 
		If cGrpAprov <> QRY->GRUPO+QRY->ITEMGRP
			// Valida se possui mais do que 1 grupo para gerar a solicitação
			If !Empty(cGrpAprov)
				// Salva o Numero de Itens do Pedido
				aAdd(aCardData,{'numItens', cItem})
				
				// Salva o Numero de Aprovadores
				aAdd(aCardData,{'aprovNum', cItemAprov})
				
				// Chama a função para gerar a solicitação no Fluig
				GeraFluig(aCardData, aRecnoSCR, cUserComp)
				
			EndIf
			
			// Salva o array base dos dados do Pedido
			aCardData := AClone(aCardBase)
			//aCardData := aCardBase
			aRecnoSCR := {}
			
			// Monta os itens do Pedido de acordo com o Centro de Custo
			cQryItens := " SELECT C7_ITEM AS ITEM, C7_PRODUTO AS PRODUTO, C7_DESCRI AS DESCRICAO, C7_QUANT AS QUANT, C7_UM AS UM, C7_PRECO AS PRECO, CTT_DESC01 AS CC, CT1_DESC01 AS CONTA, C7_OBS AS OBS, "
			cQryItens += 	" C7_VLDESC AS DESCONTO, " 
			cQryItens += 	" CASE WHEN C7_TPFRETE = 'C' THEN C7_FRETE ELSE 0 END AS FRETE, " 
			cQryItens += 	" C7_VALIPI AS IPI, "
			cQryItens += 	" C7_TOTAL AS TOTAL "
			cQryItens += " FROM "+RetSqlName("SC7")+" SC7 "
			cQryItens += "	LEFT JOIN "+RetSqlName("CTT")+" CTT ON CTT.CTT_FILIAL = '"+xFilial("CTT")+"' AND CTT.CTT_CUSTO = SC7.C7_CC AND CTT.D_E_L_E_T_ = ' ' "
			cQryItens += "	LEFT JOIN "+RetSqlName("CT1")+" CT1 ON CT1.CT1_FILIAL = '"+xFilial("CT1")+"' AND CT1.CT1_CONTA = SC7.C7_CONTA AND CT1.D_E_L_E_T_ = ' ' "
			cQryItens += " WHERE C7_FILIAL = '"+xFilial("SC7")+"'"
			cQryItens += 	" AND SC7.C7_NUM = '"+cNumPC+"' "
			//cQryItens += 	" AND SC7.C7_CC = '"+QRY->CUSTO+"' "
			cQryItens += 	" AND SC7.D_E_L_E_T_ = ' ' "
			cQryItens += " ORDER BY C7_ITEM " 
			
			If Select('QRYITEM') <> 0
				DbSelectArea('QRYITEM')
				DbCloseArea()
			EndIf
			
			TCQUERY cQryItens NEW ALIAS "QRYITEM"
			
			nItem 		:= 0
			cItem		:= Alltrim(Str(nItem))
			nPedidoTotal := 0

			While !QRYITEM->(Eof())
				
				nItem++
				cItem	:= Alltrim(Str(nItem))
				
				nVTotal := QRYITEM->TOTAL - QRYITEM->DESCONTO + QRYITEM->IPI + QRYITEM->FRETE
	
				aAdd(aCardData,{'txtItem___'+cItem,QRYITEM->ITEM})
				aAdd(aCardData,{'txtProduto___'+cItem, Alltrim(QRYITEM->PRODUTO)+' - '+Alltrim(QRYITEM->DESCRICAO)})
				aAdd(aCardData,{'txtQuantidade___'+cItem, PadR(TransForm(QRYITEM->QUANT,'@E 999,999,999.99'),15)})
				//aAdd(aCardData,{'txtUnidadeMedida___'+cItem, Alltrim(QRYITEM->UM)})
				aAdd(aCardData,{'txtPreco___'+cItem, PadR(TransForm(QRYITEM->PRECO,'@E 999,999,999.99'),15)})
				//aAdd(aCardData,{'txtCentroCusto___'+cItem, AllTrim(QRYITEM->CC)})
				//aAdd(aCardData,{'txtContaContabil___'+cItem, AllTrim(QRYITEM->CONTA)})
				//aAdd(aCardData,{'txtItemDesconto___'+cItem, PadR(TransForm(QRYITEM->DESCONTO,'@E 999,999,999.99'),15)})
				//aAdd(aCardData,{'txtItemFrete___'+cItem, PadR(TransForm(QRYITEM->FRETE,'@E 999,999,999.99'),15)})
				aAdd(aCardData,{'txtItemTotal___'+cItem, PadR(TransForm(nVTotal,'@E 999,999,999.99'),15)})
				//aAdd(aCardData,{'txtItemObs___'+cItem, AllTrim(QRYITEM->OBS)})
		
				nPedidoTotal += nVTotal					
				
				QRYITEM->(DbSkip())
			EndDo
	
			aAdd(aCardData,{'txtPedidoValor',Alltrim(Transform(nPedidoTotal,PesqPict('SC7','C7_TOTAL')))})
			aCondPag := condicao(nPedidoTotal,SC7->C7_COND,0,SC7->C7_DATPRF)
			if Len(aCondPag) > 0  
				cDataVen := DtoC(aCondPag[1,1])
			Else
				cDataVen := DtoC(Date())
			EndIf
			aAdd(aCardData,{'txtDataVencimento', cDataVen})
			
			nItemAprov := 0
			cItemAprov	:= Alltrim(Str(nItemAprov))
		
			// Salva o Grupo
			cGrpAprov := QRY->GRUPO+QRY->ITEMGRP
		EndIf
		
		nItemAprov++
		cItemAprov	:= Alltrim(Str(nItemAprov))
		
		// Monta a Tracker com os aprovadores
		aAdd(aCardData,{'txtAprNivel___'+cItemAprov, QRY->NIVEL})
		aAdd(aCardData,{'txtAprNome___'+cItemAprov, Alltrim(QRY->NOME)})
		aAdd(aCardData,{'txtAprLogin___'+cItemAprov, GetLogFlg(Alltrim(QRY->USUARIO))})  
		aAdd(aCardData,{'txtAprGrupo___'+cItemAprov, QRY->GRUPO})
		aAdd(aCardData,{'txtAprItemGrp___'+cItemAprov, QRY->ITEMGRP})
		aAdd(aCardData,{'txtAprStatus___'+cItemAprov, 'Pendente'})
		aAdd(aCardData,{'txtAprRecno___'+cItemAprov, AllTrim(Str(QRY->RECNOSCR))})
		
		// Salva o Recno da Alçada 
		aAdd(aRecnoSCR, QRY->RECNOSCR)

		QRY->(DbSkip())
	EndDo
	
	// Valida se possui mais do que 1 grupo para gerar a solicitação
	If !Empty(cGrpAprov)
		// Salva o Numero de Itens do Pedido
		aAdd(aCardData,{'numItens', cItem})
		
		// Salva o Numero de Aprovadores
		aAdd(aCardData,{'aprovNum', cItemAprov})
		
		// Chama a função para gerar a solicitação no Fluig
		GeraFluig(aCardData, aRecnoSCR, cUserComp)
	EndIf

	QRY->(DBCloseArea())

EndIf

Return(lRet)

/*
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
++-----------------------------------------------------------------------------++
++ Função    | GeraFluig | Autor  | Anderson Jose Zelenski | Data | 02/06/2020 ++
++-----------------------------------------------------------------------------++
++ Descrição | Gerar no Fluig a Solicitação do WF de Pedidos de Compras        ++
++-----------------------------------------------------------------------------++
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
*/

Static Function GeraFluig(aCardData, aRecnoSCR, cFluigMatr)
Local cFluigUsr 	:= AllTrim(GetMv("MV_FLGUSER"))
Local cFluigPss		:= AllTrim(GetMv("MV_FLGPASS"))
Local nCompany		:= 1
Local oFluigWrk
Local oObjAnxArr
Local oObjItArr
Local oObjItem
Local oObjLeagId
Local oObjAnexos
Local oObjAppoin
Local oObjRetorno
Local oObjRetItem
Local aItens	:= {}
Local cComments	:= ""
Local cProcess	:= "WFPedidoCompras" 
Local lmanagerMode := .T.
Local lComplete := .T.
//Local cHoje		:= DtoC(Date())+" - "+Time()
Local nI		:= 1
Local cIdProcess:= ""



				
	// Inicia o Objeto do WebService com o Processo a ser iniciado no Fluig
	oFluigWrk := WSECMWorkflowEngineService():New()
				
	// Cria o Objeto com os anexos 
	oObjAnxArr := WsClassNew("ECMWorkflowEngineService_processAttachmentDtoArray")
	
	// Cria o objeto com os array dos itens
	oObjItArr := WsClassNew("ECMWorkflowEngineService_keyValueDtoArray")
				
	// Percorre o array pra montar os objetos
	For nI := 1 To Len(aCardData)
		oObjItem := WsClassNew("ECMWorkflowEngineService_keyValueDto")
	
		oObjItem:ckey := aCardData[nI,1]
		oObjItem:cvalue := aCardData[nI,2]
		
		aAdd(aItens, oObjItem)
	Next
				
	// Adiciona o array de Itens no Objeto
	oObjItArr:oWSitem := aItens
	oFluigWrk:oWSstartProcessClassiccardData := oObjItArr
				
	// Inicia o Processo no Fluig
	If oFluigWrk:startProcessClassic(cFluigUsr, cFluigPss, nCompany, cProcess, 0, oObjLeagId, cComments, cFluigMatr, lComplete, oObjAnexos, oObjItArr, oObjAppoin, lmanagerMode)
		
		oObjRetorno := WsClassNew("ECMWorkflowEngineService_keyValueDtoArray")
		oObjRetorno := oFluigWrk:OWSSTARTPROCESSCLASSICRESULT
		
		oObjRetItem := WsClassNew("ECMWorkflowEngineService_keyValueDto")
		oObjRetItem := oObjRetorno:oWSitem[1]
		if oObjRetItem:cKey == "ERROR"
			conout("Erro Integração com o Fluig ")
			conout("Erro: "+oObjRetItem:cValue)
		Else
			oObjRetItem := oObjRetorno:oWSitem[6]
			cIdProcess := oObjRetItem:cValue
			
			For nI := 1 To Len(aRecnoSCR)
				SCR->(DbGoTo(aRecnoSCR[nI]))
				RecLock("SCR",.F.)
					SCR->CR_FLUIG := cIdProcess
				SCR->(MsUnlock())
			Next
		
			conout("idProcess "+cIdProcess)
		EndIf
	Else
		conout("Processo não integrado com o Fluig")
	EndIf

Return

Static function GetLogFlg(cLogin)
	Local cFluigUsr 	:= AllTrim(GetMv("MV_FLGUSER"))
	Local cFluigPss		:= AllTrim(GetMv("MV_FLGPASS"))
	Local nCompany		:= 1
	Local cEmail 		:= UsrRetMail(cLogin)
	Local cLogFluig		:= ''

	// Inicia o Objeto do WebService com o Processo a ser iniciado no Fluig  getColleaguesMail
	oFluigUsu := WSECMColleagueService():New()
				
				
	// Inicia o Processo no Fluig
	If oFluigUsu:getColleaguesMail(cFluigUsr, cFluigPss, nCompany, cEmail)
		
		oObjRetorno := WsClassNew("ECMColleagueService_colleagueDtoArray")
		oObjRetorno := oFluigUsu:oWSgetColleaguesMailresult
		
		
		oObjRetItem := WsClassNew("ECMColleagueService_colleagueDto")
		oObjRetItem := oObjRetorno:oWSitem[1]
		if !Empty(oObjRetItem:cLogin) 
			oObjRetItem := oObjRetorno:oWSitem[1]
			cLogFluig := oObjRetItem:cColleagueId
		
			conout("cLogFluig "+cLogFluig)
		else
			conout("Erro e-mail ")
			cLogFluig := AllTrim(GetMv("MV_FLGMATR"))
		EndIf
	Else
		conout("Processo não integrado com o Fluig")
	EndIf


Return cLogFluig
