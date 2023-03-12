#INCLUDE 'PROTHEUS.CH'
#INCLUDE 'TOPCONN.CH'
#include 'tbiconn.ch'
#include "RWMAKE.CH"
#include 'parmtype.ch'
#INCLUDE 'PRTOPDEF.CH'
#Include 'MATA094.ch'

User Function MT103FIM()
	Local nOpcao := PARAMIXB[1]   // Opção Escolhida pelo usuario no aRotina  3-inclui  4-altera  5-Exclui
	Local nConfirma := PARAMIXB[2]   // Se o usuario confirmou a operação de gravação da NFECODIGO DE APLICAÇÃO DO USUARIO Cancelada = 0  ou Confirmada = 1.
	// CUSTOMIZAÇÃO
	Local aCardBase	:= {}
	Local aCardData := {}
	Local nTamD1Vun	:= TamSX3("D1_VUNIT")[2]
	Local lTolerNeg := GetNewPar("MV_TOLENEG",.F.)
	Local cUserComp := ""
	Local lDescTol	:= SuperGetMv("MV_DESCTOL",.F.,.F.)
	Local cNumPC := 0
	Local nItemAprov := 0
	Local _aArea := GetArea()

	aRecnoSCR 	:= {}

	//nConfirma := 1
	//nOpcao := 3

	//------------------------------------------------------------------------------------------
	// Processo para inserir na tabela de Custo sem ST um produto novo com a primeira entrada
	//------------------------------------------------------------------------------------------
	//Habilidar a rotina em data especifica.
	If dDatabase > Ctod('07/10/2019')

		If SF1->F1_TIPO=="N" .and. cFilAnt == '010104'

			Processa( {|| PrpCust() }, "Aguarde...", "Calculando Custo para Transferencia...",.F.)

		Endif 
	Endif
	
	
	U_GTPE002() // Ponto de chamada ConexãoNF-e sempre como primeira instrução.

	AnexoGED()

	If SF1->F1_Status == "B" .And. nConfirma == 1 .And. (nOpcao == 3 .Or. nOpcao == 5)
		if nOpcao == 3
			//Adiciona no fluigo solicitação de aprovação
			if select('SD1TMP') <> 0
				SD1TMP->(dbCloseArea())
			ENDIF

			BeginSQL Alias "SD1TMP"
				SELECT SD1.D1_ITEM, SD1.D1_COD, SD1.D1_QUANT, SD1.D1_VUNIT, SD1.D1_PEDIDO, SD1.D1_ITEMPC, SD1.D1_FORNECE, SD1.D1_LOJA, SD1.D1_EMISSAO
				FROM %Table:SD1% SD1
				WHERE SD1.D1_FILIAL=%xFilial:SD1% AND ;
				SD1.D1_DOC     = %exp:CNFISCAL% AND ;
				SD1.D1_SERIE   = %exp:CSERIE% AND ;
				SD1.D1_FORNECE = %exp:cA100For% AND ;
				SD1.D1_LOJA    = %exp:CLOJA% AND ;
				SD1.%NotDel%
				ORDER BY 1
			EndSQL

			SC7->(DbSetOrder(14))
			If SC7->(dbSeek(xFilEnt(xFilial("SC7"),"SC7")+Padr(SD1TMP->D1_PEDIDO,TamSX3("C7_NUM")[1])+PadR(SD1TMP->D1_ITEMPC,TamSX3("C7_ITEM")[1])))
				aAdd(aCardBase,{'txtEmpresa',Alltrim(FWFilialName())})
				aAdd(aCardBase,{'txtPedidoFilial',SC7->C7_FILIAL})
				aAdd(aCardBase,{'txtPedidoNumero',CNFISCAL+CSERIE+cA100For+CLOJA})
				aAdd(aCardBase,{'txtPedidoNumeroSerie',CNFISCAL+'-'+CSERIE})

				cNumPC := SC7->C7_NUM
				aAdd(aCardBase,{'txtPedidoEmissao',DtoC(SC7->C7_EMISSAO)})
				aAdd(aCardBase,{'txtFornecedorNome',Alltrim(SA2->A2_NOME)})
				aAdd(aCardBase,{'pedidoStatus','P'})
				aAdd(aCardBase,{'txtComprador',Alltrim(UsrFullName(SC7->C7_USER))})
				aAdd(aCardBase,{'txtCondicaoDescricao',Alltrim(Posicione("SE4",1,xFilial("SE4")+SC7->C7_COND,"E4_DESCRI"))})
				aAdd(aCardBase,{'txtNomeFilial',Alltrim(Posicione("SA1",1,xFilial("SA1")+SC7->C7_YCLIENT,"A1_NREDUZ"))})
				aAdd(aCardBase,{'txtCodFilial',SC7->C7_YCLIENT})
				aAdd(aCardBase,{'txtCompradorEmail',UsrRetMail(Alltrim(SC7->C7_USER))})
				aAdd(aCardBase,{'txtPedidoValor',PadR(TransForm(SF1->F1_VALBRUT,'@E 999,999,999.99'),15)})

			ENDIF
			cUserComp := GetLogFlg(Alltrim(RetCodUsr()))
			dbSelectArea("SCR")
			dbSetOrder(1)

			aCardData := AClone(aCardBase)
			nItem 		:= 0
			cItem	:= Alltrim(Str(nItem))
			nPedidoTotal := 0

			SF1->(DbSetOrder(1))
			If SF1->(DbSeek(xFilial("SF1")+Substr(SD1->D1_DOC,1,Len(SF1->F1_DOC+SF1->F1_SERIE+SF1->F1_FORNECE+SF1->F1_LOJA))))
				While !SD1TMP->(EOF())
					nItem++
					cItem	:= Alltrim(Str(nItem))
					aAdd(aCardData,{'txtItem___'+cItem,SD1TMP->D1_ITEM})
					aAdd(aCardData,{'txtProduto___'+cItem,SD1TMP->D1_COD})
					aAdd(aCardData,{'txtQuantidade___'+cItem,PadR(TransForm(SD1TMP->D1_QUANT,'@E 999,999,999.99'),15)})
					aAdd(aCardData,{'txtPreco___'+cItem,PadR(TransForm(SD1TMP->D1_VUNIT,'@E 999,999,999.99'),15)})
					aAdd(aCardData,{'txtItemPed___'+cItem,SD1TMP->D1_PEDIDO})

					SC7->(DbSetOrder(14))
					If SC7->(dbSeek(xFilEnt(xFilial("SC7"),"SC7")+Padr(SD1TMP->D1_PEDIDO,TamSX3("C7_NUM")[1])+PadR(SD1TMP->D1_ITEMPC,TamSX3("C7_ITEM")[1])))
						aAdd(aCardData,{'txtPedQtd___'+cItem,PadR(TransForm(SC7->C7_QUANT,'@E 999,999,999.99'),15)})
						aAdd(aCardData,{'txtPedPrc___'+cItem,PadR(TransForm(SC7->C7_PRECO,'@E 999,999,999.99'),15)})
						aAdd(aCardData,{'txtPedQtdEnt___'+cItem,PadR(TransForm(SC7->C7_QUJE,'@E 999,999,999.99'),15)})

						// Carrega o motivo do bloqueio por tolerancia de recebimento
						nQtdItPed := SC7->C7_QUANT-SC7->C7_QUJE
						lQtd := (SD1TMP->D1_QUANT > nQtdItPed) .Or. (lTolerNeg .And. (SD1TMP->D1_QUANT < nQtdItPed))
						lVlr := (SD1TMP->D1_VUNIT > xMoeda(SC7->C7_PRECO,SC7->C7_MOEDA,1,StoD(SD1TMP->D1_EMISSAO),nTamD1Vun,SC7->C7_TXMOEDA)) .Or. (lTolerNeg .And. (SD1TMP->D1_VUNIT < xMoeda(SC7->C7_PRECO,SC7->C7_MOEDA,1,SD1TMP->D1_EMISSAO,nTamD1Vun,SC7->C7_TXMOEDA)))
						lPrazo:= (StoD(SD1TMP->D1_EMISSAO) > SC7->C7_DATPRF)

						cDiverg:=''

						If lQtd .And. lVlr
							cDiverg := STR0038
						ElseIf lQtd
							cDiverg:=STR0039
						ElseIf lVlr .Or. (lDescTol .And. Round((SC7->C7_PRECO * SC7->C7_QUANT),2) > (SC7->C7_TOTAL - SC7->C7_VLDESC))
							cDiverg := STR0040
						Elseif !lPrazo
							cDiverg:=STR0041
						EndIf

						If lPrazo
							If !Empty(cDiverg)
								cDiverg+='/'
							EndIf
							cDiverg+='Prz.Entr.'
						EndIf

						aAdd(aCardData,{'txtPedDiverge___'+cItem,OemToAnsi(cDiverg)})
					Else
						aAdd(aCardData,{'txtPedDiverge___'+cItem,OemToAnsi(STR0042)})
					EndIf
					SD1TMP->(dbSkip())
				EndDo
				aAdd(aCardData,{'numItens', cItem})
			EndIf

			//----------------A L C A D A ------------------------------------------------

			// Separa as alçadas por grupo de aprovação.
			cQryTracke := " SELECT CR_GRUPO AS GRUPO, CR_ITGRP AS ITEMGRP, CR_TIPO AS TIPO, DBL_CC AS CUSTO, CR_NIVEL AS NIVEL, CR_USER AS USUARIO, CR_APROV AS APROVADOR, AK_NOME AS NOME, AK_LOGIN AS LOGIN, CR_TOTAL AS TOTAL, SCR.R_E_C_N_O_ AS RECNOSCR"
			cQryTracke += " FROM "+RetSqlName("SCR")+" SCR "
			cQryTracke += "		LEFT JOIN "+RetSqlName("DBL")+" DBL ON DBL.DBL_FILIAL = '"+xFilial("DBL")+"' AND DBL_GRUPO = CR_GRUPO AND DBL.D_E_L_E_T_ = ' ' "
			cQryTracke += "		LEFT JOIN "+RetSqlName("SAK")+" SAK ON SAK.AK_FILIAL = '"+xFilial("SAK")+"' AND SAK.AK_COD = SCR.CR_APROV AND SAK.AK_USER = SCR.CR_USER AND SAK.D_E_L_E_T_ = ' ' "
			cQryTracke += " WHERE SCR.CR_FILIAL = '"+xFilial("SCR")+"' "
			cQryTracke += "		AND SCR.CR_NUM = '"+CNFISCAL+CSERIE+cA100For+CLOJA+"' "
			cQryTracke += "		AND SCR.CR_TIPO IN ('NF') "
			cQryTracke += " 	AND SCR.D_E_L_E_T_ = ' ' "
			// cQryTracke += " UNION "
			// cQryTracke += " SELECT CR_GRUPO AS GRUPO, CR_ITGRP AS ITEMGRP, CR_TIPO AS TIPO, DBL_CC AS CUSTO, CR_NIVEL AS NIVEL, CR_USER AS USUARIO, CR_APROV AS APROVADOR, AK_NOME AS NOME, AK_LOGIN AS LOGIN, CR_TOTAL AS TOTAL, SCR.R_E_C_N_O_ AS RECNOSCR"
			// cQryTracke += " FROM "+RetSqlName("SCR")+" SCR "
			// cQryTracke += "		LEFT JOIN "+RetSqlName("DBL")+" DBL ON DBL.DBL_FILIAL = '"+xFilial("DBL")+"' AND DBL_GRUPO = CR_GRUPO AND DBL_ITEM = CR_ITGRP AND DBL.D_E_L_E_T_ = ' ' "
			// cQryTracke += "		LEFT JOIN "+RetSqlName("SAK")+" SAK ON SAK.AK_FILIAL = '"+xFilial("SAK")+"' AND SAK.AK_COD = SCR.CR_APROV AND SAK.AK_USER = SCR.CR_USER AND SAK.D_E_L_E_T_ = ' ' "
			// cQryTracke += " WHERE SCR.CR_FILIAL = '"+xFilial("SCR")+"' "
			// cQryTracke += "		AND SCR.CR_NUM = '"+cNumPC+"' "
			// cQryTracke += "		AND SCR.CR_TIPO IN ('IP') "
			// cQryTracke += " 	AND SCR.D_E_L_E_T_ = ' ' "
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
			aAdd(aCardData,{'aprovNum', cItemAprov})
			//----------------------------------------------------------------------------
			GeraFluig(aCardData, aRecnoSCR, cUserComp)
 
		else
			// Busca os códigos das solicitações do Fluig
			cQry := " SELECT DISTINCT CR_FLUIG AS IDFLUIG "
			cQry += " FROM "+RetSqlName("SCR")+" SCR "
			cQry += " WHERE SCR.CR_FILIAL = '"+xFilial("SCR")+"' "
			cQry += "		AND SCR.CR_NUM = '"+CNFISCAL+CSERIE+cA100For+CLOJA+"' "
			cQry += "		AND SCR.CR_TIPO IN ('NF') "
			//cQry += " 	AND SCR.D_E_L_E_T_ = ' ' "
			cQry += " ORDER BY 1 "

			If Select('QRY') <> 0
				DbSelectArea('QRY')
				DbCloseArea()
			Endif

			TCQUERY cQry NEW ALIAS "QRY"

			While !QRY->(Eof())
				// Chama a função para cancelar a solicitação no Fluig
				CancelaFluig(Val(AllTrim(QRY->IDFLUIG)), "NF excluída")

				QRY->(DbSkip())
			EndDo

		endif
	ENDIF

	if nConfirma == 1 .And. (nOpcao == 3 .OR. nOpcao == 4)
		//Rotina que validase tem produtos com substituição tributária e informa por e-mail
		If ExistBlock("VLDSBTRB")
			ExecBlock("VLDSBTRB",.F.,.F.,{})
		Endif

		atuYestB2()

	endif
	
	RestArea(_aArea)
Return (NIL)

Static function atuYestB2()
	
	local _cArmCom := getNewPar("EC_ARMCOM", "90") 
	lOCAL _cFilEcom := getNewPar("EC_FILIAL", "010104") 
	IF ALLTRIM(SF1->F1_FILIAL) == ALLTRIM(_cFilEcom)
		DbSelectArea("SD1")
		SD1->(DbSetOrder(1))
		If SD1->(DbSeek(SF1->F1_FILIAL+SF1->F1_DOC+SF1->F1_SERIE+SF1->F1_FORNECE+SF1->F1_LOJA))

			While !SD1->(Eof()) .and. SD1->D1_FILIAL+SD1->D1_DOC+SD1->D1_SERIE+SD1->D1_FORNECE+SD1->D1_LOJA == SF1->F1_FILIAL+SF1->F1_DOC+SF1->F1_SERIE+SF1->F1_FORNECE+SF1->F1_LOJA
				if SD1->D1_LOCAL == _cArmCom
					DbSelectArea("SB1")
					SB1->(DbSetOrder(1))
					If SB1->(DbSeek(xFilial('SB1')+SD1->D1_COD)) .AND. ALLTRIM(SB1->B1_YB2B) == 'S'
						recLock("SB1", .F.)
							SB1->B1_YESTB2B := "S"
						SB1->(msUnlock())
					ENDIF
				ENDIF
				SD1->(DbSkip())
			Enddo

		Endif
	ENDIF
RETURN

//------------------------------------------------------------------------------------------
// Funcao para inserir na tabela de Custo sem ST um produto novo com a primeira entrada
//------------------------------------------------------------------------------------------

Static Function PrpCust()

	//Posiciona nos itens da Nota
	DbSelectArea("SD1")
	DbSetOrder(1)
	If DbSeek(SF1->F1_FILIAL+SF1->F1_DOC+SF1->F1_SERIE+SF1->F1_FORNECE+SF1->F1_LOJA)

		While !SD1->(Eof()) .and. SD1->D1_FILIAL+SD1->D1_DOC+SD1->D1_SERIE+SD1->D1_FORNECE+SD1->D1_LOJA == SF1->F1_FILIAL+SF1->F1_DOC+SF1->F1_SERIE+SF1->F1_FORNECE+SF1->F1_LOJA

			If SD1->D1_ICMSRET > 0

				//Verifica se é a primeira entrada do produto
				_cQry := " SELECT COUNT(D1_COD) AS QTENT FROM " + RetSqlName("SD1")
				_cQry += " WHERE D1_FILIAL ='"+SD1->D1_FILIAL+"'"
				_cQry += " AND D1_COD='"+SD1->D1_COD+"'"
				_cQry += " AND D1_DOC <> '"+SD1->D1_DOC+"'"
				_cQry += " AND D_E_L_E_T_=''"

				IIF ( Select("TR1SD1") <> 0 ,TR1SD1->(DbCloseArea()),)

				TcQuery _cQry New Alias "TR1SD1"

				If TR1SD1->QTENT == 0

					_nVlrST := 0
					_vCust := 0

					DbSelectArea("Z03")
					DbSetOrder(1)
					If DbSeek(xFilial("Z03")+DToS(SF1->F1_DTDIGIT)+SD1->D1_COD)
						_lNewReg := .F.
					Else
						_lNewReg := .T.
					Endif

					_nVlrST := Round((SD1->D1_ICMSRET/SD1->D1_QUANT),2)
					_vCust := Posicione("SB2",1,xFilial("SB2") + SD1->D1_COD+ "01", "B2_CM1")

					//Grava o Valor do Custo encontrado
					Reclock("Z03",_lNewReg)
					Z03->Z03_FILIAL := xFilial("Z03")
					Z03->Z03_DCUSTO := SF1->F1_DTDIGIT
					Z03->Z03_PRODUT := SD1->D1_COD
					Z03->Z03_VST    := _nVlrST
					Z03->Z03_VCUSTO := _vCust - _nVlrST
					Z03->(MsUnlock())

					//Deleta as notas anteriores
					DbSelectArea("Z04")
					DbSetOrder(1)
					If DbSeek(xFilial("Z04")+DToS(SF1->F1_DTDIGIT)+SD1->D1_COD)
						While !Z04->(Eof()) .and. Z04->Z04_FILIAL==xFilial("Z04") .and. Z04->Z04_DCUSTO==SF1->F1_DTDIGIT .and. Z04->Z04_PRODUT == SD1->D1_COD

							Reclock("Z04",.f.)
							Z04->(DbDelete())
							Z04->(MsUnlock())

							Z04->(Dbskip())

						Enddo

					Endif

					Reclock("Z04",.T.)
					Z04->Z04_FILIAL := xFilial("Z04")
					Z04->Z04_DCUSTO := SF1->F1_DTDIGIT
					Z04->Z04_PRODUT := SD1->D1_COD
					Z04->Z04_DOC    := SD1->D1_DOC
					Z04->Z04_SERIE  := SD1->D1_SERIE
					Z04->Z04_FORNEC := SD1->D1_FORNECE
					Z04->Z04_LOJA   := SD1->D1_LOJA
					Z04->(MsUnlock())

				Endif
				TR1SD1->(DbCloseArea())

			Endif

			SD1->(DbSkip())
		Enddo

	Endif

Return nil

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
	Local cProcess	:= "WFDocumentoEntrada"
	Local lmanagerMode := .F.
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

/*
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
++-----------------------------------------------------------------------------++
++ Função    | CancelaFluig | Autor | Sandro Nascimento      | Data | 01/03/22 ++
++-----------------------------------------------------------------------------++
++ Descrição | Cancela no Fluig a Solicitação do WF de Pedidos de Compras      ++
++-----------------------------------------------------------------------------++
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
*/

Static Function CancelaFluig(nIdFluig, cComentario)
	Local cFluigUsr 	:= AllTrim(GetMv("MV_FLGUSER"))
	Local cFluigPss		:= AllTrim(GetMv("MV_FLGPASS"))
	Local cFluigMatr 	:= AllTrim(GetMv("MV_FLGMATR"))
	Local nCompany		:= 1
	Local oFluigWrk
	Local cRetorno		:= ""

	// Inicia o Objeto do WebService com o Processo a ser iniciado no Fluig
	oFluigWrk := WSECMWorkflowEngineService():New()

	// Cancela o Processo no Fluig
	If oFluigWrk:cancelInstance(cFluigUsr, cFluigPss, nCompany, nIdFluig, cFluigMatr, cComentario)
		cRetorno := oFluigWrk:cresult
		conout("Cancelamento Fluig: "+cRetorno)
	Else
		conout("Processo não integrado com o Fluig")
	EndIf

Return

Static Function AnexoGED()

	Local nConfirma	:= PARAMIXB[2] // Se o usuario confirmou a operação de gravação da NFE
	Local nOpcao    := PARAMIXB[1] // Opção Escolhida pelo usuario no aRotina
	Local aAreaSD1	:= {}
	Local aAreaAC9	:= {}
	Local aAreaACB	:= {}
	Local aAreaSC7	:= {}
	Local cChaveSD1	:= ""
	Local aPedido	:= {}
	Local nPos		:= 0
	Local cAlias	:= "SF1"
	Local nReg		:= SF1->(Recno())
	Local cEntidade	:= ""
	Local cCodEnt	:= ""
	Local lRet		:= .T.

	//Anexo automatico no GED
	If  ( nConfirma == 1 .And. Alltrim(FunName())$'MATA103|U_GATI001' )

		If ExistBlock("TCCO04KM")

			If ( l103class .or. (nOpcao==3 .and. Alltrim(FUNNAME()) <> 'TC04A020'))

				cChaveSD1 := SD1->(D1_FILIAL + D1_DOC + D1_SERIE + D1_FORNECE + D1_LOJA)

				aAreaSD1 := SD1->(GetArea())
				aAreaAC9 := AC9->(GetArea())
				aAreaACB := ACB->(GetArea())
				aAreaSC7 := SC7->(GetArea())

				DBSelectArea("SF1")

				If ExistBlock("CXF0001")
					U_CXF0001(@cAlias, @nReg)
				EndIf

				DBSelectArea("SC7")
				SC7->(dbSetOrder(1)) // C7_FILIAL, C7_NUM, C7_ITEM, C7_SEQUEN, R_E_C_N_O_, D_E_L_E_T_

				DBSelectArea("SD1")
				SD1->(DBSetOrder(1)) // D1_FILIAL, D1_DOC, D1_SERIE, D1_FORNECE, D1_LOJA, D1_COD, D1_ITEM, R_E_C_N_O_, D_E_L_E_T_
				SD1->(DBGoTop())

				If SD1->(DBSeek(cChaveSD1))

					While SD1->(!EOF()) .And. SD1->(D1_FILIAL + D1_DOC + D1_SERIE + D1_FORNECE + D1_LOJA) == cChaveSD1

						If !Empty(SD1->D1_PEDIDO)

							nPos := aScan(aPedido, {|x| x == SD1->D1_PEDIDO})

							lRet := .T.

							If nPos == 0

								cEntidade := IIF(Len(cAlias) == 3, cAlias, Substr(cAlias,0,3))

								dbSelectArea( cEntidade )
								dbGoto( nReg )

								aEntidade := U_GEDENT( cEntidade )

								If Len(aEntidade) > 0

									cCodEnt := aEntidade[1]

									DBSelectArea("AC9")
									AC9->(DBSetOrder(2)) // AC9_FILIAL, AC9_ENTIDA, AC9_FILENT, AC9_CODENT, AC9_CODOBJ, R_E_C_N_O_, D_E_L_E_T_

									DBSelectArea("ACB")
									ACB->(DBSetOrder(1)) // ACB_FILIAL, ACB_CODOBJ, R_E_C_N_O_, D_E_L_E_T_

									If AC9->(DBSeek(xFilial("AC9") + cEntidade + xFilial(cEntidade) + cCodEnt))

										While AC9->(!EOF()) .And. AC9->( AC9_FILIAL + AC9_ENTIDA + AC9_FILENT) + AllTrim(AC9->AC9_CODENT) == xFilial("AC9") + cEntidade + xFilial(cEntidade) + cCodEnt .And. lRet

											If ACB->(DBSeek(xFilial("ACB") + AC9->AC9_CODOBJ))

												While ACB->(!EOF()) .And. ACB->( ACB_FILIAL + ACB_CODOBJ ) == xFilial("ACB") + AC9->AC9_CODOBJ .And. lRet

													If UPPER(AllTrim(ACB->ACB_OBJETO)) == UPPER("PC" + SD1->D1_PEDIDO + ".PDF")

														lRet := .F.

													EndIf

													ACB->(DBSkip())

												EndDo

											EndIf

											AC9->(DBSkip())

										EndDo

									EndIf

									If lRet

										If SC7->(MsSeek(xFilial("SC7")+SD1->D1_PEDIDO))
									
											ExecBlock("TCCO04KM",.F.,.F.)

										EndIf

									EndIf	

								EndIf

							Else

								aAdd(aPedido, SD1->D1_PEDIDO)

							EndIf

						EndIf

						SD1->(DBSkip())

					EndDo

				EndIf

				RestArea(aAreaSD1)
				RestArea(aAreaAC9)
				RestArea(aAreaACB)
				RestArea(aAreaSC7)

			EndIf

		EndIf

	EndIf

Return()
