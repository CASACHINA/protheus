#INCLUDE "APWEBSRV.CH"
#INCLUDE "PROTHEUS.CH"
#INCLUDE "TBICONN.CH"
#INCLUDE "TOPCONN.CH"
#INCLUDE 'FWMVCDef.ch'
#INCLUDE "TOTVS.CH"
#INCLUDE "RWMAKE.CH"
#INCLUDE "TBICODE.CH"
#INCLUDE "FWPrintSetup.ch"
#INCLUDE "RPTDEF.CH"
#INCLUDE "FILEIO.CH"
#Include "Colors.ch"

/*---------------------------------------------------------------------------+
!                       FICHA TECNICA DO PROGRAMA  - 31/01/2023              !
+------------------+---------------------------------------------------------+
!Tipo              ! Web Service	                               			 !
!Módulo            ! Protheus x Fluig			       	                     !
!Cliente	       ! Casa China    										     !
!Data de Criacao   ! 07/12/2020												 !
!Autor             ! Anderson José Zelenski - SMSTI		                     !
+------------------+---------------------------------------------------------+
!   						   MANUTENCAO        						     !
+---------+-----------------+------------------------------------------------+
!Data     ! Consultor		! Descricao                                      !
+---------+-----------------+------------------------------------------------+
!         !          		! 											     !
+---------+-----------------+-----------------------------------------------*/

// Estrutura de Aprovação
WSSTRUCT oAprovacao
	WSDATA Filial			AS String
	WSDATA Pedido			AS String
	WSDATA Nivel			AS String
	WSDATA Acao				AS String
	WSDATA Grupo			AS String
	WSDATA ItemGrupo		AS String
	WSDATA Login			AS String optional
	WSDATA SCRRecno			AS String
	WSDATA Comentario		AS String optional
ENDWSSTRUCT

// Estrutura do Centro de Custo
WSSTRUCT oCentroCusto
	WSDATA Filial			AS String
	WSDATA Codigo			AS String
	WSDATA Descricao		AS String
	WSDATA DescWeb			AS String
ENDWSSTRUCT

// Estrutura dos Centros de Custos
WSSTRUCT oCentrosCustos
	WSDATA Itens AS ARRAY OF oCentroCusto
ENDWSSTRUCT

// Estrutura do Produto
WSSTRUCT oCadCliente
	WSDATA Codigo			AS String
	WSDATA Status			AS String
	WSDATA Erro				AS String
ENDWSSTRUCT

WSSTRUCT oCadClientes
	WSDATA Itens AS ARRAY OF oCadCliente
ENDWSSTRUCT

// Estrutura do Produto
WSSTRUCT oProduto
	WSDATA Filial			AS String
	WSDATA Codigo			AS String
	WSDATA CodBarras		AS String
	WSDATA Descricao		AS String
	WSDATA DescWeb			AS String
	WSDATA Tipo				AS String
	WSDATA UM				AS String
ENDWSSTRUCT

// Estrutura dos Protudots
WSSTRUCT oProdutos
	WSDATA Itens AS ARRAY OF oProduto
ENDWSSTRUCT

// Estrutura da Solicitação
WSSTRUCT oSolicitacao
	WSDATA Filial			AS String
	WSDATA Usuario			AS String
	WSDATA CentroCusto		AS String
	WSDATA IdFluig			AS String

	WSDATA Itens			AS Array Of oItemSC
ENDWSSTRUCT

// Estruta dos Itens da Solicitação
WSSTRUCT oItemSC
	WSDATA Codigo			AS String
	WSDATA Necessidade		As Date
	WSDATA Quantidade		AS Float
	WSDATA Observacao		AS String optional
ENDWSSTRUCT

// Estrutura da solicitacao de gerar nota de doacao
WSSTRUCT oNFCab
	WSDATA ORIGEM 		AS String optional
	WSDATA CLICOD 		AS String optional
	WSDATA CLILOJA 		AS String optional
	WSDATA IDFLUIG		AS String optional
	WSDATA TIPO			AS String optional

	WSDATA ITENS 		AS ARRAY OF oItemNF optional
ENDWSSTRUCT

// Estrutura dos itens da solicitacao de gerar nota de doacao
WSSTRUCT oItemNF
	WSDATA PRODCOD		AS String optional
	WSDATA QUANTIDADE	AS Float optional
ENDWSSTRUCT

// WebService FluigProtheus
WSSERVICE FluigProtheus DESCRIPTION 'Fluig x Protheus - Workflow'
	WSDATA oAprovacao			AS oAprovacao
	WSDATA aCentrosCustos 		AS oCentrosCustos
	WSDATA aProdutos 			AS oProdutos
	WSDATA oSolicitacao			AS oSolicitacao
	WSDATA aEmpresas			AS oEmpresas
	WSDATA aFornecedores		AS oFornecedores
	WSDATA aClientes			AS oClientes
	WSDATA oProdutoProtheus 	AS oProdutoProtheus
	WSDATA oProdutoSiteProtheus AS oProdutoSiteProtheus

	WSDATA oNFCab				AS oNFCab

	WSDATA aCadClientes			AS oCadClientes

	WSDATA cStatus			AS String
	WSDATA SCRRecno			AS String
	WSDATA cCodigo			AS String
	WSDATA nSaldo			AS float
	WSDATA nNumPed			AS String
	WSDATA cOrigem			AS String
	WSDATA cNotaFiscal		AS String
	WSDATA cBase64			AS String

	WSMETHOD AprovWFPC					DESCRIPTION 'Aprovar Workflow de Pedido de Compras'
	WSMETHOD LiberarPC					DESCRIPTION 'Liberar Pedido de Compras'
	WSMETHOD CentrosCustos				DESCRIPTION 'Listas todos os Centros de Custos'
	WSMETHOD Produtos					DESCRIPTION 'Listas todos os Produtos'
	WSMETHOD GerarSC					DESCRIPTION 'Gera a Solicitação de Compras'
	WSMETHOD ValidaSaldo				DESCRIPTION 'Valida o saldo do aprovador'
	WSMETHOD Empresas					DESCRIPTION 'Lista todas as empresas'
	WSMETHOD Fornecedores				DESCRIPTION 'Busca os Fornecedores'
	WSMETHOD Clientes					DESCRIPTION 'Busca os Clientes'
	WSMETHOD GetValidaSaldo				DESCRIPTION 'Pega o saldo pelo dia'
	WSMETHOD GravarProduto				DESCRIPTION 'Grava o Produto'
	WSMETHOD GravarProdutoSite			DESCRIPTION 'Grava o Produto Site'
	WSMETHOD SolicitacaoAlmoxarifado	DESCRIPTION 'Solcita produto almoxarifado MATA105'
	WSMETHOD NFTransferencia			DESCRIPTION 'Gera Pedido e NF - MATA410'
	WSMETHOD MOVIMENTACAOINTERNA		DESCRIPTION 'Gera Movimentacao Interna - MATA241'
	WSMETHOD TRANSFFILIAL				DESCRIPTION 'Gera Transferencia para CD - MATA311'

ENDWSSERVICE

WSMETHOD SolicitacaoAlmoxarifado WSRECEIVE oNFCab WSSEND cStatus WSSERVICE FluigProtheus
	Local lError 		:= .T.
	Local nI			:= 1
	Local aItem 		:= {}
	Local _aCab			:= {}
	Local _aItens		:= {}
	Local _nOpc			:= 3
	Local aRecSCP 		:= {}
	Local bBloco 		:= {|| .T.}
	Local aCamposSCP	:= {}
	Local aCamposSD3	:= {}
	Local aRelProj 		:= {}

	PRIVATE lMsErroAutoaRecSCP 		:= {} := .F.

	conout("Solicitação Almoxarifado")

	BEGIN TRANSACTION

		cFilAnt := oNFCab['ORIGEM']

		_cNum := GetSx8Num('SCP', 'CP_NUM')

		_aCab:={;
			{"CP_FILIAL"	,oNFCab['ORIGEM']	, Nil},;
			{"CP_NUM"		,_cNum 				, NIL },;
			{"CP_EMISSAO"	,dDataBase 			, NIL};
		}

		For nI := 1 To Len(oNFCab['ITENS'])
			oItemNF := WSClassNew("oItemNF")
			aItem := {}
			aItem := oNFCab['ITENS']
			oItem := aItem[nI]

			Aadd( _aItens, {;
				{"CP_ITEM"		, StrZero(nI, 2)			, Nil},;
				{"CP_PRODUTO"	, oItem['PRODCOD']			, Nil},;
				{"CP_QUANT"		, oItem['QUANTIDADE']		, Nil},;
				{"CP_FLUIG"		, oNFCab['IDFLUIG']			, Nil},;
				{"CP_OBS"		, "Fluig: "+oNFCab['IDFLUIG'], Nil};
			})

		Next nI

		MsExecAuto( { | x, y, z | Mata105( x, y , z ) }, _aCab, _aItens , _nOpc )

		IF lMsErroAuto
			rollbacksx8()
			conout(MostraErro())
			lError := .T.
		ELSE
			Confirmsx8()
			lError := .F.

			::cStatus := _cNum

			SCP->(DbGoTop())
			SCP->(DbSetOrder(1))
			SCP->(DbSeek(xFilial("SCP")+_cNum))

			While !SCP->(Eof()) .And. SCP->CP_FILIAL+SCP->CP_NUM = xFilial("SCP")+_cNum
				aAdd(aRecSCP, SCP->(Recno()))

				aCamposSCP := { {"CP_NUM" ,SCP->CP_NUM ,Nil },;
								{"CP_ITEM" ,SCP->CP_ITEM ,Nil },;
								{"CP_QUANT" ,SCP->CP_QUANT ,Nil }}

				aCamposSD3 := { {"D3_TM" ,"501" ,Nil },; // Tipo do Mov.
								{"D3_COD" ,SCP->CP_PRODUTO,Nil },;
								{"D3_LOCAL" ,SCP->CP_LOCAL ,Nil },;
								{"D3_DOC" ,"" ,Nil },; // No.do Docto.
								{"D3_EMISSAO" ,DDATABASE ,Nil }}

				SCP->(DbSkip())
			EndDo

			// Geracao das Pré-Requisições - MATA106
			MaSaPreReq(.T., .F., bBloco, .F., .F., .T., , , .F., .F., 1, .T., .F., aRecSCP, .F.)
			
			lMSHelpAuto := .F.
			lMsErroAuto := .F.

			// Baixar Pré-Requisições - MATA185
			MSExecAuto({|v,x,y,z,w| mata185(v,x,y,z,w)},aCamposSCP,aCamposSD3,1,,aRelProj)   // 1 = BAIXA (ROT.AUT)

			If lMsErroAuto
				lError := .T.
			EndIf
		ENDIF

	END TRANSACTION

	If lError
		cMens := "Erro ao gravar a Solicitação do Almoxarifado"
		conout('[' + DToC(Date()) + " " + Time() + "] SolicitarAlmoxarifado > " + cMens)
		SetSoapFault("Erro", cMens)
		Return .F.
	EndIf

Return .T.

// Gera Pedido e NF - MATA410
WSMETHOD NFTransferencia WSRECEIVE oNFCab WSSEND cStatus WSSERVICE FluigProtheus
	Local lError 	:= .T.
	Local nI		:= 1
	Local aItem 	:= {}
	Local cOper		:= '09'
	Local cTipoPed	:= 'N'
	Local cTipoCli	:= 'F'
	Local cCondPag	:= '001'
	Local _aCab		:= {}
	Local _aItens	:= {}
	Local _nOpc		:= 3
	Local nValCusto := 0
	Local cMenNota 	:= ""

	PRIVATE lMsErroAuto := .F.

	conout("Gerar NF Transferencia ")

	BEGIN TRANSACTION
		SC5->(DbGoTop())
		SC5->(DbSetOrder(1))

		If Posicione("SA1",1,xFilial("SA1")+oNFCab['CLICOD']+oNFCab['CLILOJA'],"A1_EST") == "SC"
			cMenNota 	:= "ICMS Estorno - Não Ocorrência do Fato Gerador Conforme Art. 1º RICMS/SC e Art. 180º Anexo V RICMS/SC."
		else
			cMenNota 	:= "ICMS Estorno - Não Ocorrência do Fato Gerador Conforme Art. 2º do RICMS/PR e Art. 213, IV, alínea a e § 11, I do RICMS/PR. "
			cMenNota 	+= "PIS Estorno - Não Ocorrência do Fato Gerador Conforme Art. 3º Lei 10.833/03. "
			cMenNota 	+= "COFINS Estorno - Não Ocorrência do Fato Gerador Conforme Art. 1º Lei 10.637/02."
		Endif

		conout(cMenNota)

		cFilAnt := oNFCab['ORIGEM']

		_aCab:={;
			{"C5_FILIAL"	,oNFCab['ORIGEM']	, Nil},;
			{"C5_TIPO"		,cTipoPed			, NIL},;
			{"C5_CLIENTE"	,oNFCab['CLICOD']	, NIL},;
			{"C5_LOJACLI"	,oNFCab['CLILOJA']	, NIL},;
			{"C5_TIPOCLI"	,cTipoCli			, NIL},;
			{"C5_CONDPAG"	,cCondPag			, NIL},;
			{"C5_EMISSAO"	,dDataBase 			, NIL},;
			{"C5_FLUIG"		,oNFCab['IDFLUIG']	, NIL};
		}

		For nI := 1 To Len(oNFCab['ITENS'])
			oItemNF := WSClassNew("oItemNF")
			aItem := {}
			aItem := oNFCab['ITENS']
			oItem := aItem[nI]

			nValCusto := Posicione("SB2",1,xFilial("SB2")+oItem['PRODCOD'], "B2_CM1")
			
			conout("@@@ SB2: " + cValToChar(nValCusto))
			
			Aadd( _aItens, {;
				{"C6_ITEM"		, StrZero(nI, 2)		, Nil},;
				{"C6_PRODUTO"	, oItem['PRODCOD']		, Nil},;
				{"C6_QTDVEN"	, oItem['QUANTIDADE']	, Nil},;
				{"C6_PRCVEN"	, SB2->B2_CM1			, Nil},;
				{"C6_OPER"		, cOper					, Nil},;
				{"C6_QTDLIB"	, oItem['QUANTIDADE']	, Nil},;
				{"C6_PRUNIT"	, SB2->B2_CM1			, Nil};
			})
		Next nI

		MsExecAuto( { | x, y, z | MATA410( x, y , z ) }, _aCab, _aItens , _nOpc )

		IF lMsErroAuto
			cError := MostraErro() 
			ConOut("Error: "+ cError)
			
			lError := .T.
		ELSE
			lError := .F.
			
			cPedFil := SC5->C5_FILIAL
			cPedNum := SC5->C5_NUM

			RecLock("SC5", .f.)
				SC5->C5_MENNOTA := cMenNota
			SC5->(MsUnlock())
		ENDIF

	END TRANSACTION

	If lError
		cMens := "Erro ao Gerar Pedido!"
		conout('[' + DToC(Date()) + " " + Time() + "] GerarPedido > " + cMens)
		SetSoapFault("Erro", cMens)
		Return .F.
	else 
		// Retorna o Pedido e NF
		::cStatus := cPedNum+"|"+CCGeraNf(cPedFil, cPedNum)
	EndIf

Return .T.

Static Function CCGeraNf(cFilPed, cPedido)
	Local _aArea := GetArea()
	Local cSerie := Alltrim(GetMv("MV_NFSERTR"))
    Local aPvlNfs := {}
	Local _dIni := Date()
	Local _dFim := Date()
	Local _cHrIni := Time()
	Local _cHrFim := Time()
	Local _nI
	Local cNota := ""

	SC9->(dbSetOrder(1))
	SC5->(dbSetOrder(1))
	SC6->(dbSetOrder(1))
	SE4->(dbSetOrder(1))
	SB1->(dbSetOrder(1))
	SB2->(dbSetOrder(1))
	SF4->(dbSetOrder(1))
	
	BEGIN TRANSACTION
		// Verifica se o pedido esta totalmente liberado
		_lPedLib := .T.
		_aRecSC9 := {}
		cFilAnt := cFilPed
		SC9->(dbGoTop())
		SC9->(dbSeek(xFilial("SC9")+cPedido ))
		While !SC9->(EOF()) .And. Alltrim(SC9->C9_FILIAL+SC9->C9_PEDIDO) == Alltrim(xFilial("SC9")+ cPedido)
				// Se tiver algum bloqueio, nÃ£o gera a nota
			If !Empty(SC9->C9_BLEST) .Or. !Empty(SC9->C9_BLCRED)
				_lPedLib := .F.
				Exit
			Endif

			AADD(_aRecSC9,SC9->(Recno()))	
			SC9->(dbSkip())
		Enddo
		If _lPedLib
			// Recupera a data/hora inÃ­cio
			_dIni := Date()
			_cHrIni := Time()
			_dFim := Date()
			_cHrFim := Time()

			// Gera a NF
			aPvlNfs := {}
			For _nI := 1 to Len(_aRecSC9)
				SC9->(dbGoTo(_aRecSC9[_nI]))

				SC5->(dbGoTop())
				SC5->(dbSeek(xFilial("SC5")+SC9->C9_PEDIDO))

				SC6->(dbGoTop())
				SC6->(dbSeek(xFilial("SC6")+SC9->C9_PEDIDO+SC9->C9_ITEM+SC9->C9_PRODUTO))

				SE4->(dbGoTop())
				SE4->(dbSeek(xFilial("SE4")+SC5->C5_CONDPAG))

				SB1->(dbGoTop())
				SB1->(dbSeek(xFilial("SB1")+SC9->C9_PRODUTO))

				SB2->(dbGoTop())
				SB2->(dbSeek(xFilial("SB2")+SC9->C9_PRODUTO+SC6->C6_LOCAL))

				SF4->(dbGoTop())
				SF4->(dbSeek(xFilial("SF4")+SC6->C6_TES))
				AADD(aPvlNfs,{SC9->C9_PEDIDO,;
				SC9->C9_ITEM,;
				SC9->C9_SEQUEN,;
				SC9->C9_QTDLIB,;
				SC9->C9_PRCVEN,;
				SC9->C9_PRODUTO,;
				.F.,;
				SC9->(RecNo()),;
				SC5->(RecNo()),;
				SC6->(RecNo()),;
				SE4->(RecNo()),;
				SB1->(RecNo()),;
				SB2->(RecNo()),;
				SF4->(RecNo())})
			Next _nI

			If Len(aPvlNfs) > 0
				lMostraCtb := .F.
				lAglutCtb := .F.
				lCtbOnLine := .T.
				lCtbCusto := .T.
				lReajuste := .F.

				//cNota := MaPvlNfs(aPvlNfs,cSerie, .F.      , .F.     , .T.      , .T.     , .F.     , 0      , 0          , .T.   , .F.,"")
				cNota := MaPvlNfs(aPvlNfs,cSerie,lMostraCtb,lAglutCtb,lCtbOnLine,lCtbCusto,lReajuste, 0, 0, .T., .F.,"")
			Endif
		Endif

		// Transmite para o Sefaz a NFE
		AtuSefaz(cNota, cSerie, "SF2")
	
	END TRANSACTION

	RestArea(_aArea)

	return cNota
Return

// Gera Movimentacao Interna - MATA241
WSMETHOD MOVIMENTACAOINTERNA WSRECEIVE oNFCab WSSEND cStatus WSSERVICE FluigProtheus
	Local lError 	:= .T.
	Local nI		:= 1
	Local aItem 	:= {}
	Local _aCab		:= {}
	Local _aItens	:= {}
	Local _nOpc		:= 3
	Local cDoc		:= ""

	PRIVATE lMsErroAuto := .F.

	conout("Gerar Movimentação Interna ")

	BEGIN TRANSACTION
		_aCab:={;
			{"D3_DOC"		,'FLUIG'+oNFCab['IDFLUIG']	, Nil},;
			{"D3_TM"		,'501'						, Nil},;
			{"D3_EMISSAO"	,dDataBase					, NIL};
		}

		For nI := 1 To Len(oNFCab['ITENS'])
			oItemNF := WSClassNew("oItemNF")
			aItem := {}
			aItem := oNFCab['ITENS']
			oItem := aItem[nI]

			Aadd( _aItens, {;
				{"D3_COD"		, oItem['PRODCOD']		, Nil},;
				{"D3_QUANT"		, oItem['QUANTIDADE']	, Nil};
			})
		Next nI

		cFilAnt := oNFCab['ORIGEM']

		MsExecAuto( { | x, y, z | MATA241( x, y , z ) }, _aCab, _aItens , _nOpc )

		IF lMsErroAuto
			cError := MostraErro() 
			ConOut("Error: "+ cError)
			
			lError := .T.
		ELSE
			lError := .F.
			
			cDoc := 'FLUIG'+oNFCab['IDFLUIG']
		ENDIF

	END TRANSACTION

	If lError
		cMens := "Erro ao Movimentação Interna!"
		conout('[' + DToC(Date()) + " " + Time() + "] MovimentacaoInterna > " + cMens)
		SetSoapFault("Erro", cMens)
		Return .F.
	else 
		// Retorna o numero do DOC gerado
		::cStatus := cDoc
	EndIf

Return .T.


// Gera Transferencia para CD - MATA311
WSMETHOD TRANSFFILIAL WSRECEIVE oNFCab WSSEND cStatus WSSERVICE FluigProtheus
	Local nI		:= 1
	Local aItem 	:= {}
	Local cNota		:= ""
	Local oModel
	Local cFilDes	:= "010104"
	Local cArmDes	:= "09"
	Local aCposDet	:= {}
//	Local cTESPad	:= "509"
	Local cMens		:= ""

	Private lMsErroAuto := .F.
	Private cOpId311 := "C"
	Private lAuto311 := .T.
	Private aRotina

	nModulo := 4  //estoque/custos
	
	//inicializa variaveis estaticas
	__cNNTFil := "" 
    __cNNTCod := ""
	
	//Instancia o Model do MATA311
	oModel := FwLoadModel("MATA311")

	//Campos do cabeçalho
	aCposCab := {}

	cFilAnt := oNFCab['ORIGEM']

	aAdd(aCposCab,{"NNS_FILIAL"  ,oNFCab['ORIGEM']})
	aAdd(aCposCab,{"NNS_DATA"  ,dDataBase})
	aAdd(aCposCab,{"NNS_SOLICT","000000"})  
	aAdd(aCposCab,{"NNS_STATUS","1"})  //estamos enviando status como "2", porque invertem o valor na função A311ActMod()
	aAdd(aCposCab,{"NNS_CLASS" ,"2"})
	aAdd(aCposCab,{"NNS_CYBERW" ,"N"})
	aAdd(aCposCab,{"NNS_FLUIG" ,oNFCab['IDFLUIG']})

	aCposDet := {}

	For nI := 1 To Len(oNFCab['ITENS'])
		oItemNF := WSClassNew("oItemNF")
		aItem := {}
		aItem := oNFCab['ITENS']
		oItem := aItem[nI]

		aAux := {}
		aAdd(aAux,{"NNT_FILORI", oNFCab['ORIGEM'] })
		aAdd(aAux,{"NNT_FILDES", cFilDes      })
		aAdd(aAux,{"NNT_PROD"  , oItem['PRODCOD'] })
		aAdd(aAux,{"NNT_LOCAL" , "01" }) //Local de origem
		aAdd(aAux,{"NNT_QUANT" , oItem['QUANTIDADE']})
	
		aAdd(aAux,{"NNT_PRODD" , oItem['PRODCOD'] })
		aAdd(aAux,{"NNT_LOCLD" , cArmDes }) //Local do tipo de operação (destino)

		//aAdd(aAux,{"NNT_TS" , cTESPad }) 
		aAdd(aAux,{"NNT_SERIE" , "1" }) 

		aAdd(aAux,{"NNT_OBS"   , "Fluig: "+oNFCab['IDFLUIG']})
		
		aAdd(aCposDet,aAux)

	Next nI

	NNS->(dbSetOrder(1))
	NNT->(dbSetOrder(1))

	//Seta operação de Inclusão
	oModel:SetOperation(3)
	//Ativa o modelo
	oModel:Activate()

	//Instancia o modelo referente ao cabeçalho
	oAux := oModel:GetModel( 'NNSMASTER' )
	//Obtem a estrutura de dados do cabeçalho
	oStruct := oAux:GetStruct()

	aAux := oStruct:GetFields()
	lRet := .T.
	For nI := 1 To Len(aCposCab)
		// Verifica se os campos passados existem na estrutura do cabeçalho
		If ( nPos := aScan( aAux, { |x| AllTrim( x[3] ) == AllTrim( aCposCab[nI][1] ) } ) ) > 0
			// É feita a atribuição do dado ao campo do Model do cabeçalho
			If !( lAux := oModel:SetValue( 'NNSMASTER', aCposCab[nI][1],aCposCab[nI][2] ) )
				// Caso a atribuição não possa ser feita, por algum motivo (validação, por exemplo)
				// o método SetValue retorna .F.
				lRet := .F.
				Exit
			EndIf
		EndIf
	Next nI

	If lRet
		// Instanciamos apenas a parte do modelo referente aos dados do item
		oAux := oModel:GetModel( 'NNTDETAIL' )
		// Obtemos a estrutura de dados do item
		oStruct := oAux:GetStruct()
		aAux := oStruct:GetFields()

		For nI := 1 To Len( aCposDet[1] )
			// Verifica se os campos passados existem na estrutura de item
			If ( nPos := aScan( aAux, { |x| AllTrim( x[3] ) == AllTrim( aCposDet[1][nI][1] ) } ) ) > 0
				If !( lAux := oModel:SetValue( 'NNTDETAIL', aCposDet[1][nI][1], aCposDet[1][nI][2] ) )
					// Caso a atribuição não possa ser feita, por algum motivo (validação, por exemplo)
					// o método SetValue retorna .F.
					lRet := .F.
					Exit
				EndIf
			EndIf
		Next
	EndIf

	If lRet
		// Faz-se a validação dos dados, note que diferentemente das tradicionais "rotinas automáticas"
		// neste momento os dados não são gravados, são somente validados.
		If ( lRet := oModel:VldData() )
			// Se os dados foram validados faz-se a gravação efetiva dos
			// dados (commit)
			lRet := FWFormCommit(oModel)
		EndIf
	EndIf

	If !lRet
		// Se os dados não foram validados obtemos a descrição do erro para gerar
		// LOG ou mensagem de aviso
		aErro := {}
		aErro := oModel:GetErrorMessage()

		for nI := 1 to len(aErro)
			conout(aErro[nI])

			cMens += aErro[nI]
		next

		SetSoapFault("Erro", cMens)
	Else
		__cNNTFil := NNS->NNS_FILIAL  //filial da transferência
		__cNNTCod := NNS->NNS_COD     //código da transferência 

		cNota := efetivarTransf(__cNNTFil, __cNNTCod)

		
	EndIf
	
	// Desativamos o Model
	oModel:DeActivate()

	NNS->(dbCloseArea())
	NNT->(dbCloseArea())

	::cStatus := __cNNTCod+"|"+cNota

Return .T.

Static Function efetivarTransf(cTransFil, cTransNum)
	Local cNota := ""
	Local aArea     := GetArea()
	Local oModel
	Local aDadoscab	:= {}
	Local cSerie	:= "1"

    Private cOpId311 := "011"
	Private OP_EFE := "011"
    Private lMsErroAuto := .F.

	conout("efetivarTransf")
    
    nModulo := 4  //estoque/custos
    
    //Instancia o Model do MATA311
    oModel := FwLoadModel("MATA311")
    
    aRotina := {}
    
    NNS->(DbSetOrder(1))
	NNS->(DbSeek(FWxFilial("NNS",cTransFil) + cTransNum))
	
	aAdd(aDadoscab, {"NNS_CLASS", '2' , Nil})
	aAdd(aDadoscab, {"NNS_COD", cTransNum , Nil})
	
	FWMVCRotAuto( oModel,"NNS",4,{{"NNSMASTER", aDadoscab}})
	
	//Se houve erro no ExecAuto, mostra mensagem
	If !lMsErroAuto
		cNota := Posicione("NNT", 1, FWxFilial("NNT",cTransFil)+cTransNum, "NNT_DOC")

		// Transmite para o Sefaz a NFE
		AtuSefaz(cNota, cSerie, "SF2")
	EndIf
	    
    // Desativamos o Model
    oModel:DeActivate()
    
    RestArea(aArea)

Return cNota

/*
Funcao para Transmissão Automática da NF para SEFAZ
*/
Static Function AtuSefaz(_cNota,_cSerNF, cTipo)
Local _cChv		:= ""
Local _IDNfe	:= ''
Local cModel	:= "55"  
Local lEnd		:= .F.

	conout("AtuSefaz")

	_cChv := padr(_cSerNF,3,' ')+_cNota
	
	_IDNfe	:= RetIdEnti()

	conout(_IDNfe)

	cURL := PadR(GetNewPar("MV_SPEDURL","http://"),250)

	conout(cURL)

	If !Empty(_IDNfe)
		
		// Obtem o ambiente de execucao do Totvs Services SPED
		oWS := WsSpedCfgNFe():New()
		oWS:cUSERTOKEN:= "TOTVS"
		oWS:cID_ENT := _IDNfe
		oWS:nAmbiente   := 0
		oWS:_URL        := AllTrim(cURL)+"/SPEDCFGNFe.apw"
		oWS:cModelo := cModel
		lOk             := oWS:CFGAMBIENTE()
		_cAmbiente      :=  oWS:cCfgAmbienteResult
		
		// Obtem a modalidade de execucao do Totvs Services SPED
		If lOk
			oWS:cUSERTOKEN  := "TOTVS"
			oWS:cID_ENT     := _IDNfe
			oWS:nModalidade := 0
			oWS:_URL            := AllTrim(cURL)+"/SPEDCFGNFe.apw"
			lOk                 := oWS:CFGModalidade()
			_cModalidade        := oWS:cCfgModalidadeResult
		EndIf
		
		// Obtem a versao de trabalho da NFe do Totvs Services SPED
		If lOk
			oWS:cUSERTOKEN  := "TOTVS"
			oWS:cID_ENT     := _IDNfe
			oWS:cVersao     := "0.00"
			oWS:_URL            := AllTrim(cURL)+"/SPEDCFGNFe.apw"
			lOk                 := oWS:CFGVersao()
			_cVersao            := oWS:cCfgVersaoResult
		EndIf

		If lOK
			SpedNFeTrf(cTipo ,_cSerNF,_cNota  ,_cNota  ,_IDNfe,_cAmbiente,_cModalidade,_cVersao,@lEnd,.F. ,.T.)
		Else
			conout(" Falha ao realizar a transmissão automatica da NFE! Efetue o procedimento manual.")
		EndIf
	Else
		conout('Erro: ID não localizado na tabela SPED050 com base na Chave informada.('+_cChv+')')
	EndIf

Return Nil


WSMETHOD GetValidaSaldo WSRECEIVE SCRRecno WSSEND nSaldo WSSERVICE FluigProtheus
	Local lError 	:= .T.
	Local aSaldo	:= {}

	BEGIN TRANSACTION

		SCR->(DbGoTo(Val(::SCRRecno)))
		cFilAnt 	:= SCR->CR_FILIAL

		aSaldo 		:= MaSalAlc(SCR->CR_APROV,dDataBase,.T.)

		conout("cFilAnt: " + cFilAnt)

		::nSaldo 	:= 'nOk'
		conout("SCR->CR_TOTAL: " + str(SCR->CR_TOTAL))
		conout("aSaldo[1]: " + str(aSaldo[1]))

		if aSaldo[1] > SCR->CR_TOTAL
			conout("Entrou ")
			::nSaldo := aSaldo[1]
		endif

		lError := .F.

	END TRANSACTION

	If lError
		cMens := "Erro ao aprovaro alçada SCR"
		conout('[' + DToC(Date()) + " " + Time() + "] Aprovar SCR > " + cMens)
		SetSoapFault("Erro", cMens)
		Return .F.
	EndIf

Return .T.

/*/{Protheus.doc} ValidaSaldo
Aprova o item da alçada do Pedido de Compras
@author Sandro Antonio do Nascimento
@since 13/07/2021
/*/
WSMETHOD ValidaSaldo WSRECEIVE SCRRecno WSSEND cStatus WSSERVICE FluigProtheus
	Local lError 	:= .T.
	Local aSaldo	:= {}

	conout("Valida Saldo")

	BEGIN TRANSACTION

		SCR->(DbGoTo(Val(::SCRRecno)))
		cFilAnt 	:= SCR->CR_FILIAL

		aSaldo 		:= MaSalAlc(SCR->CR_APROV,dDataBase,.T.)

		conout("cFilAnt: " + cFilAnt)

		::cStatus 	:= 'nOk'
		conout("SCR->CR_TOTAL: " + str(SCR->CR_TOTAL))
		conout("aSaldo[1]: " + str(aSaldo[1]))

		if aSaldo[1] > SCR->CR_TOTAL
			conout("Entrou ")
			::cStatus := 'ok'
		endif

		lError := .F.

	END TRANSACTION

	If lError
		cMens := "Erro ao aprovaro alçada SCR"
		conout('[' + DToC(Date()) + " " + Time() + "] Aprovar SCR > " + cMens)
		SetSoapFault("Erro", cMens)
		Return .F.
	EndIf
Return .T.

/*/{Protheus.doc} AprovWFPC
Aprova o item da alçada do Pedido de Compras
@author Anderson José Zelenski
@since 07/12/2020
/*/

WSMETHOD AprovWFPC WSRECEIVE oAprovacao WSSEND cStatus WSSERVICE FluigProtheus
	Local lError 	:= .T.
	Local nAcao 	:= 4
	Local cAprovador:= ""
	Local cUsuario	:= ""

	conout("Aprovar Pedido")

	BEGIN TRANSACTION

		SCR->(DbGoTo(Val(oAprovacao['SCRRecno'])))
		cFilAnt 	:= SCR->CR_FILIAL
		cTipo		:= SCR->CR_TIPO
		cPedido 	:= SCR->CR_NUM
		cAprovador	:= SCR->CR_APROV
		cUsuario	:= SCR->CR_USER
		cNivel		:= SCR->CR_NIVEL

		conout("Ação: "+oAprovacao['Acao'])

		If oAprovacao['Acao'] == "A"
			MaAlcDoc({SCR->CR_NUM, SCR->CR_TIPO, SCR->CR_TOTAL, cAprovador, cUsuario, SCR->CR_GRUPO,,,,,oAprovacao['Comentario']},dDataBase,nAcao,,,SCR->CR_ITGRP)
		ElseIf oAprovacao['Acao'] == "R"
			nAcao 	:= 6
			conout(SCR->CR_NUM, SCR->CR_TIPO, SCR->CR_TOTAL, cUsuario, cAprovador, SCR->CR_GRUPO, oAprovacao['Comentario'],SCR->CR_ITGRP)

			MaAlcDoc({SCR->CR_NUM, SCR->CR_TIPO, SCR->CR_TOTAL, cAprovador, cUsuario, SCR->CR_GRUPO,,,,,oAprovacao['Comentario']},dDataBase,nAcao,,,SCR->CR_ITGRP)

			/*
			RecLock("SCR", .F.)
				SCR->CR_STATUS 	:= "4"
				SCR->CR_OBS 	:= oAprovacao['Comentario']
			SCR->(MsUnlock())
			*/
		EndIf

		conout("Login Aprovador: "+oAprovacao['Login'])

		// Valida se foi aprovado por um usuario alternativo
		SAK->(DbSetOrder(4)) //AK_FILIAL+AK_Login
		If SAK->(DbSeek(xFilial("SAK")+oAprovacao['Login']))
			If cUsuario != SAK->AK_USER
				SCR->(DbSetOrder(1)) //CR_FILIAL+CR_TIPO+CR_NUM+CR_NIVEL
				SCR->(DbGoTop())
				SCR->(DbSeek(cFilAnt+cTipo+cPedido+cNivel))

				While !SCR->(EoF()) .And. SCR->CR_FILIAL+SCR->CR_TIPO+SCR->CR_NUM+SCR->CR_NIVEL == cFilAnt+cTipo+cPedido+cNivel
					RecLock("SCR", .F.)
					SCR->CR_LIBAPRO := SAK->AK_COD
					SCR->CR_USERLIB := SAK->AK_USER
					SCR->(MsUnlock())

					SCR->(DbSkip())
				EndDo

			EndIf
		EndIf

		lError := .F.

		::cStatus := "OK"

	END TRANSACTION

	If lError
		cMens := "Erro ao aprovaro alçada SCR"
		conout('[' + DToC(Date()) + " " + Time() + "] Aprovar SCR > " + cMens)
		SetSoapFault("Erro", cMens)
		Return .F.
	EndIf

Return .T.

/*/{Protheus.doc} LiberarPC
Libera Pedido de Compras
@author Anderson José Zelenski
@since 07/12/2020
/*/

WSMETHOD LiberarPC WSRECEIVE SCRRecno WSSEND cStatus WSSERVICE FluigProtheus
	Local lError 	:= .T.

	conout("Liberar Pedido")

	BEGIN TRANSACTION

		// Posiciona na Alçada
		SCR->(DbGoTo(Val(::SCRRecno)))
		cFilAnt := SCR->CR_FILIAL
		conout(SCR->CR_NUM, SCR->CR_TIPO, SCR->CR_TOTAL, SCR->CR_APROV, SCR->CR_USER, SCR->CR_GRUPO, SCR->CR_ITGRP)
		if SCR->CR_TIPO == 'PC'
			//conout(SCR->CR_NUM, SCR->CR_TIPO, SCR->CR_TOTAL, SCR->CR_APROV, SCR->CR_USER, SCR->CR_GRUPO, SCR->CR_ITGRP)

			// Busca o Centro de Custo
			/*If Empty(SCR->CR_ITGRP)
				DBL->(DbSetOrder(1))
				DBL->(DbSeek(xFilial('DBL')+SCR->CR_GRUPO))
			Else
				DBL->(DbSetOrder(1))
				DBL->(DbSeek(xFilial('DBL')+SCR->CR_GRUPO+SCR->CR_ITGRP))
			EndIf

			conout("CC "+AllTrim(DBL->DBL_CC))*/

			// Posiciona no Pedido de Compras
			SC7->(DbSetOrder(1))
			SC7->(DbSeek(xFilial("SC7")+AllTrim(SCR->CR_NUM)))

			// Percorre os Itens do Pedido de Compras
			While !SC7->(EoF()) .And. SC7->C7_FILIAL+AllTrim(SC7->C7_NUM) == xFilial("SC7")+AllTrim(SCR->CR_NUM)

				conout(AllTrim(SC7->C7_CC)+" == "+AllTrim(DBL->DBL_CC))

				//If AllTrim(SC7->C7_CC) == AllTrim(DBL->DBL_CC)
				// Libera o Item de acordo com o Centro de Custo da alçada aprovada
				RecLock("SC7", .F.)
				SC7->C7_CONAPRO := "L"
				SC7->(MsUnlock())
				//EndIf

				SC7->(DbSkip())
			EndDo
		else
			//F1_FILIAL+F1_DOC+F1_SERIE+F1_FORNECE+F1_LOJA+F1_TIPO

			conout("Liberar Nota")
			SF1->(DbSetOrder(1))

			if SF1->(DbSeek(SCR->CR_FILIAL+AllTrim(SCR->CR_NUM), .T.))

				conout("Liberar Pedido" + SF1->F1_COND)
				RecLock("SF1", .F.)
				SF1->F1_STATUS := 'A'
				SF1->(MsUnlock())
			EndIf

		EndIf




		lError := .F.

		::cStatus := "OK"

	END TRANSACTION

	If lError
		cMens := "Erro ao liberar pedido de compras"
		conout('[' + DToC(Date()) + " " + Time() + "] Liberar PC > " + cMens)
		SetSoapFault("Erro", cMens)
		Return .F.
	EndIf

Return .T.

/*/{Protheus.doc} CentrosCustos
Retorna os Centros de Custos
@author Anderson José Zelenski
@since 07/12/2020
/*/
WSMETHOD CentrosCustos WSRECEIVE NULLPARAM WSSEND aCentrosCustos WSSERVICE FluigProtheus
	Local oCentroCusto
	Local cAlias	:= GetNextAlias()
	Local cQuery	:= ''

	::aCentrosCustos := WSClassNew("oCentrosCustos")
	::aCentrosCustos:Itens := {}

	cQuery := " SELECT CTT_FILIAL, CTT_CUSTO, CTT_DESC01 "
	cQuery += " FROM "+RetSqlName('CTT')+" CTT"
	cQuery += " WHERE CTT.CTT_BLOQ <> '1'"
	cQuery += " 	AND CTT.CTT_CLASSE = '2' "
	cQuery += " 	AND CTT.D_E_L_E_T_ = ' ' "
	cQuery += " ORDER BY CTT_FILIAL, CTT_CUSTO "

	cQuery := ChangeQuery(cQuery)

	TcQuery cQuery New Alias (cAlias)

	dbSelectArea(cAlias)

	While (cAlias)->(!Eof())

		oCentroCusto := WSClassNew("oCentroCusto")

		oCentroCusto:Filial 	:= (cAlias)->CTT_FILIAL
		oCentroCusto:Codigo 	:= (cAlias)->CTT_CUSTO
		oCentroCusto:Descricao	:= (cAlias)->CTT_DESC01
		oCentroCusto:DescWeb	:= AllTrim((cAlias)->CTT_CUSTO)+" - "+AllTrim((cAlias)->CTT_DESC01)

		aAdd(::aCentrosCustos:Itens, oCentroCusto)

		(cAlias)->(dbSkip())
	EndDo

	(cAlias)->(dbCloseArea())

Return .T.

/*/{Protheus.doc} Produtos
Retorna os Produtos
@author Anderson José Zelenski
@since 09/12/2020
/*/
WSMETHOD Produtos WSRECEIVE NULLPARAM WSSEND aProdutos WSSERVICE FluigProtheus
	Local oProduto
	Local cAlias	:= GetNextAlias()
	Local cQuery	:= ''

	::aProdutos := WSClassNew("oProdutos")
	::aProdutos:Itens := {}

	cQuery := " SELECT B1_FILIAL, B1_COD, B1_DESC, B1_TIPO, B1_UM, B1_CODBAR "
	cQuery += " FROM "+RetSqlName('SB1')+" SB1"
	cQuery += " WHERE SB1.B1_MSBLQL <> '1'"
	cQuery += " AND SB1.D_E_L_E_T_ = ' ' "
	cQuery += " ORDER BY B1_FILIAL, B1_COD "
	cQuery += " OFFSET 1 ROWS FETCH NEXT 100 ROWS ONLY "

	cQuery := ChangeQuery(cQuery)

	TcQuery cQuery New Alias (cAlias)

	dbSelectArea(cAlias)

	While (cAlias)->(!Eof())

		oProduto := WSClassNew("oProduto")

		oProduto:Filial 	:= (cAlias)->B1_FILIAL
		oProduto:Codigo 	:= Alltrim((cAlias)->B1_COD)
		oProduto:Descricao	:= Alltrim((cAlias)->B1_DESC)
		oProduto:CodBarras  := Alltrim((cAlias)->B1_CODBAR)
		oProduto:DescWeb	:= Alltrim((cAlias)->B1_COD)+" - "+Alltrim((cAlias)->B1_DESC)
		oProduto:Tipo		:= (cAlias)->B1_TIPO
		oProduto:UM			:= (cAlias)->B1_UM

		aAdd(::aProdutos:Itens, oProduto)

		(cAlias)->(dbSkip())
	EndDo

	(cAlias)->(dbCloseArea())

Return .T.

/*/{Protheus.doc} GerarSC
Gera a Solicitação de Compras no Protheus
@author Anderson José Zelenski
@since 11/12/2020
/*/

WSMETHOD GerarSC WSRECEIVE oSolicitacao WSSEND cCodigo WSSERVICE FluigProtheus
	Local lError 	:= .T.
	Local aCab		:= {}
	Local aItem		:= {}
	Local nI		:= 1
	Local cNum 		:= ''
	Local cCentroCusto := ''
	Local cIdFluig	:= ''
	Local cSolicitante := ''
	Local aItemSC 	:= {}

	PRIVATE lMsErroAuto := .F.

	conout("Gera Solicitação de Compras")

	BEGIN TRANSACTION

		cFilAnt 		:= oSolicitacao['Filial']
		cSolicitante	:= oSolicitacao['Usuario']
		cCentroCusto 	:= oSolicitacao['CentroCusto']
		cIdFluig 		:= oSolicitacao['IdFluig']

		cNum := GetNumSC1()

		aCab:= {;
			{"C1_FILIAL",	oSolicitacao['Filial'],		NIL},;
			{"C1_NUM",		cNum,						NIL},;
			{"C1_SOLICIT",	oSolicitacao['Usuario'],	NIL},;
			{"C1_EMISSAO",	dDatabase,					NIL},;
			{"C1_USER",		'000000',					NIL};
			;
			}

		SB1->(DbSetOrder(1))

		For nI := 1 To Len(oSolicitacao['Itens'])
			oItemSC := WSClassNew("oItemSC")

			aItemSC := {}
			aItemSC := oSolicitacao['Itens']
			oItemSC := aItemSC[nI]

			SB1->(DbSeek(xFilial("SB1")+oItemSC:Codigo))
			//Adiciona os Itens da SC
			Aadd(aItem, {;
				{"C1_ITEM",		StrZero(nI, 4),				NIL},;
				{"C1_ITEMGRD",	space(2),					NIL},;
				{"C1_PRODUTO", 	SB1->B1_COD, 				NIL},;
				{"C1_DESCRI",	SB1->B1_DESC,				NIL},;
				{"C1_LOCAL",	SB1->B1_LOCPAD, 			NIL},;
				{"C1_UM", 		SB1->B1_UM, 				NIL},;
				{"C1_DATPRF",	oItemSC:Necessidade,		NIL},;
				{"C1_QUANT",	oItemSC:Quantidade,			NIL},;
				{"C1_VUNIT", 	0.00, 						NIL},;
				{"C1_CONTA", 	SB1->B1_CONTA, 				NIL},;
				{"C1_CC", 		cCentroCusto, 				NIL},;
				{"C1_XCLASSE", 	"000001",					NIL},;
				{"C1_OBS", 		oItemSC:Observacao,			NIL},;
				{"C1_IDFLUIG",	cIdFluig,					NIL};
				})
		Next nI

		MSExecAuto({|x,y,z| Mata110(x,y,z)},aCab,aItem,3) //Inclusao

		IF lMsErroAuto
			rollbacksx8()
			// DisarmTransaction()
			conout(MostraErro())
			lError := .T.
		ELSE
			Confirmsx8()
			lError := .F.
		ENDIF

	END TRANSACTION

	::cCodigo := cNum

	If lError
		cMens := "Erro ao gravar a Solicitação de Compras"
		conout('[' + DToC(Date()) + " " + Time() + "] GravarSolicitacaoCompras > " + cMens)
		SetSoapFault("Erro", cMens)
		Return .F.
	EndIf

Return .T.

/*/ Empresas
@author Sandro Antonio do Nascimento
@since 31/08/2021
/*/
// Estrutura de Empresa
WSSTRUCT oEmpresa
	WSDATA Codigo			AS String
	WSDATA Empresa			AS String
ENDWSSTRUCT

// Estrutura das Empresa
WSSTRUCT oEmpresas
	WSDATA Itens AS ARRAY OF oEmpresa
ENDWSSTRUCT

// WebService de Empresas
WSMETHOD Empresas WSRECEIVE NULLPARAM WSSEND aEmpresas WSSERVICE FluigProtheus
	Local oEmpresa
	Local cModulo := 'CFG'
	Local cTabs := 'SM0'
	Local aParam:= {'01','010101'}

	If Select("SX2") <= 0
		//Abre o ambiente
		RpcSetType(3)
		Prepare Environment EMPRESA aParam[1] FILIAL aParam[2] MODULO cModulo Tables cTabs
	EndIf

	::aEmpresas := WSClassNew("oEmpresas")
	::aEmpresas:Itens := {}

	SM0->(dbGotop())

	While SM0->(!Eof())

		oEmpresa := WSClassNew("oEmpresa")
		oEmpresa:Codigo 	:= SM0->M0_CODFIL
		oEmpresa:Empresa 	:= Alltrim(FWFilialName(SM0->M0_CODIGO,SM0->M0_CODFIL))

		//oEmpresa:Empresa 	:= Alltrim(FWEmpName(SM0->M0_CODIGO))

		aAdd(::aEmpresas:Itens, oEmpresa)
		SM0->(dbSkip())
	EndDo

Return .T.

/*/ Fornecedores
@author Sandro Antonio do Nascimento
@since 08/11/2021
/*/
// Estrutura do Fornecedor
WSSTRUCT oFornecedor
	WSDATA Filial			AS String
	WSDATA Codigo			AS String
	WSDATA Loja				AS String
	WSDATA RazaoSocial		AS String
	WSDATA CNPJ				AS String
	WSDATA CEP				AS String
	WSDATA Endereco			AS String
	WSDATA Bairro			AS String
	WSDATA Cidade			AS String
	WSDATA UF				AS String
	WSDATA DescWeb			AS String
ENDWSSTRUCT

// Estrutura dos Fornecedores
WSSTRUCT oFornecedores
	WSDATA Itens AS ARRAY OF oFornecedor
ENDWSSTRUCT


// Webservice Fornecedor
WSMETHOD Fornecedores WSRECEIVE NULLPARAM WSSEND aFornecedores WSSERVICE FluigProtheus
	Local oFornecedor
	Local cAlias	:= GetNextAlias()
	Local cQuery	:= ''
	Local cModulo := 'COM'
	Local cTabs := 'SA2'
	Local aParam:= {'01','010101'}

	If Select("SX2") <= 0
		//Abre o ambiente
		RpcSetType(3)
		Prepare Environment EMPRESA aParam[1] FILIAL aParam[2] MODULO cModulo Tables cTabs
	EndIf

	::aFornecedores := WSClassNew("oFornecedores")
	::aFornecedores:Itens := {}

	cQuery := " SELECT A2_FILIAL, A2_COD, A2_LOJA, A2_NOME, A2_CGC, A2_CEP, A2_END, A2_BAIRRO, A2_MUN, A2_EST "
	cQuery += " FROM "+RetSqlName('SA2')+" SA2"
	cQuery += " WHERE SA2.A2_FILIAL = '"+xFilial("SA2")+"' "
	cQuery += " 	AND SA2.A2_MSBLQL <> '1' "
	cQuery += " 	AND SA2.D_E_L_E_T_ = ' ' "
	cQuery += " ORDER BY A2_FILIAL, A2_COD, A2_LOJA "

	cQuery := ChangeQuery(cQuery)

	TcQuery cQuery New Alias (cAlias) //conexao com o banco


	dbSelectArea(cAlias)

	While (cAlias)->(!Eof())

		oFornecedor := WSClassNew("oFornecedor")

		oFornecedor:Filial 		:= (cAlias)->A2_FILIAL
		oFornecedor:Codigo 		:= (cAlias)->A2_COD
		oFornecedor:Loja 		:= (cAlias)->A2_LOJA
		oFornecedor:RazaoSocial := Alltrim((cAlias)->A2_NOME)
		oFornecedor:CNPJ		:= Transform((cAlias)->A2_CGC,PesqPict("SA2","A2_CGC"))
		oFornecedor:CEP			:= (cAlias)->A2_CEP
		oFornecedor:Endereco	:= (cAlias)->A2_END
		oFornecedor:Bairro		:= (cAlias)->A2_BAIRRO
		oFornecedor:Cidade		:= (cAlias)->A2_MUN
		oFornecedor:UF			:= (cAlias)->A2_EST
		oFornecedor:DescWeb		:= (cAlias)->A2_COD + ' - ' + Alltrim((cAlias)->A2_NOME)

		aAdd(::aFornecedores:Itens, oFornecedor)

		(cAlias)->(dbSkip())
	EndDo

	(cAlias)->(dbCloseArea())

Return .T.


/*/ Fornecedores
@author Sandro Antonio do Nascimento
@since 08/11/2021
/*/
// Estrutura do Clientes
WSSTRUCT oCliente
	WSDATA Filial			AS String
	WSDATA Codigo			AS String
	WSDATA Loja				AS String
	WSDATA RazaoSocial		AS String
	WSDATA CNPJ				AS String
	WSDATA CEP				AS String
	WSDATA Endereco			AS String
	WSDATA Bairro			AS String
	WSDATA Cidade			AS String
	WSDATA UF				AS String
	WSDATA DescWeb			AS String
ENDWSSTRUCT

// Estrutura dos Clientes
WSSTRUCT oClientes
	WSDATA Itens AS ARRAY OF oCliente
ENDWSSTRUCT


// Webservice Clientes
WSMETHOD Clientes WSRECEIVE NULLPARAM WSSEND aClientes WSSERVICE FluigProtheus
	Local oCliente
	Local cAlias	:= GetNextAlias()
	Local cQuery	:= ''
	Local cModulo := 'COM'
	Local cTabs := 'SA1'
	Local aParam:= {'01','010101'}

	If Select("SX2") <= 0
		//Abre o ambiente
		RpcSetType(3)
		Prepare Environment EMPRESA aParam[1] FILIAL aParam[2] MODULO cModulo Tables cTabs
	EndIf

	::aClientes := WSClassNew("oClientes")
	::aClientes:Itens := {}

	cQuery := " SELECT A1_FILIAL, A1_COD, A1_LOJA, A1_NOME, A1_CGC, A1_CEP, A1_END, A1_BAIRRO, A1_MUN, A1_EST "
	cQuery += " FROM "+RetSqlName('SA1')+" SA1"
	cQuery += " WHERE SA1.A1_FILIAL = '"+xFilial("SA1")+"' "
	cQuery += " 	AND SA1.A1_MSBLQL <> '1' "
	cQuery += " 	AND SA1.D_E_L_E_T_ = ' ' "
	cQuery += " ORDER BY A1_FILIAL, A1_COD, A1_LOJA "
	cQuery += " OFFSET 1 ROWS FETCH NEXT 100 ROWS ONLY "

	cQuery := ChangeQuery(cQuery)

	TcQuery cQuery New Alias (cAlias) //conexao com o banco


	dbSelectArea(cAlias)

	While (cAlias)->(!Eof())

		oCliente := WSClassNew("oCliente")

		oCliente:Filial 	:= (cAlias)->A1_FILIAL
		oCliente:Codigo 	:= (cAlias)->A1_COD
		oCliente:Loja 		:= (cAlias)->A1_LOJA
		oCliente:RazaoSocial:= Alltrim((cAlias)->A1_NOME)
		oCliente:CNPJ		:= Transform((cAlias)->A1_CGC,PesqPict("SA1","A1_CGC"))
		oCliente:CEP		:= (cAlias)->A1_CEP
		oCliente:Endereco	:= (cAlias)->A1_END
		oCliente:Bairro		:= (cAlias)->A1_BAIRRO
		oCliente:Cidade		:= (cAlias)->A1_MUN
		oCliente:UF			:= (cAlias)->A1_EST
		oCliente:DescWeb	:= (cAlias)->A1_COD + ' - ' + Alltrim((cAlias)->A1_NOME)

		aAdd(::aClientes:Itens, oCliente)

		(cAlias)->(dbSkip())
	EndDo

	(cAlias)->(dbCloseArea())

Return .T.


/* Atualizar Produtos para o Site
@author Sandro Antonio do Nascimento
16/12/2022
*/
WSSTRUCT oProdutoSiteProtheus
	WSDATA CodigoBarra		AS String Optional
	WSDATA FornPadrao		As String Optional
	WSDATA LojaPadrao		As String Optional
	WSDATA YB2B				As String Optional
	WSDATA YCATECO			As String Optional
	WSDATA YDESDET			As String Optional
	WSDATA VlComprimento	AS Float Optional
	WSDATA VLLARG			AS Float Optional
	WSDATA VlLagM			AS Float Optional
	WSDATA PESOLIQUIDO		AS Float Optional
	WSDATA PESBRU			AS Float Optional
	WSDATA PRCVEN003		AS Float Optional
ENDWSSTRUCT

WSMETHOD GravarProdutoSite WSRECEIVE oProdutoSiteProtheus WSSEND aCadClientes WSSERVICE FluigProtheus
	Local cCodSB1	:= ""
	Local oModelSB1	:= Nil
	Local cAlias	:= GetNextAlias()
	local lOK       := .t.
	Local oCadCliente := WSClassNew("oCadCliente")
	PRIVATE lMsErroAuto := .F.
	PRIVATE inclui := .T.
	PRIVATE altera := .F.

	::aCadClientes := WSClassNew("oCadClientes")
	::aCadClientes:Itens := {}

	conout("######01!")

	BEGIN TRANSACTION
		conout("######02!")
		conout("######02! CODPROD " + cValToChar(oProdutoSiteProtheus:CodigoBarra))
		if !empty(oProdutoSiteProtheus:CodigoBarra)

			conout("######03.2!")
			cQuery := " SELECT B1_COD, B1_DESC "
			cQuery += " FROM "+RetSqlName('SB1')+" SB1"
			cQuery += " WHERE SB1.B1_CODBAR = '"+oProdutoSiteProtheus:CodigoBarra +"' "
			cQuery += " 	AND SB1.B1_PROC = '"+oProdutoSiteProtheus:FornPadrao+"' "
			cQuery += " 	AND SB1.B1_LOJPROC = '"+oProdutoSiteProtheus:LojaPadrao+"' "
			cQuery += " 	AND SB1.D_E_L_E_T_ = ' ' "
			cQuery += " ORDER BY B1_COD "

			cQuery := ChangeQuery(cQuery)

			TcQuery cQuery New Alias (cAlias) //conexao com o banco

			conout("######04!")
			dbSelectArea(cAlias)

			if (cAlias)->(!Eof())
				conout("######05.0!")
				SB1->(DbSetOrder(1))
				SB1->(DbSeek(xFilial("SB1") + (cAlias)->B1_COD))
				oModelSB1  := FwLoadModel ("MATA010")
				conout("######05.1!")
				oModelSB1:SetOperation(MODEL_OPERATION_UPDATE)
				conout("######!5.2   " +varInfo('oModelSB1',oModelSB1:GetErrorMessage(), ,.F.))
				oModelSB1:Activate()
				conout("######05.3!")

				if !empty(oProdutoSiteProtheus:YB2B) .or. trim(oProdutoSiteProtheus:YB2B) != ''
					oModelSB1:SetValue("SB1MASTER","B1_YB2B"		,AsString(oProdutoSiteProtheus:YB2B))
				endif
				
				if !empty(oProdutoSiteProtheus:YCATECO) .or. trim(oProdutoSiteProtheus:YCATECO) != ''
					oModelSB1:SetValue("SB1MASTER","B1_YCATECO"		,AsString(oProdutoSiteProtheus:YCATECO))
				endif
				
				if !empty(oProdutoSiteProtheus:YDESDET) .or. trim(oProdutoSiteProtheus:YDESDET) != ''
					oModelSB1:SetValue("SB1MASTER","B1_YDESDET" 	,AsString(oProdutoSiteProtheus:YDESDET))
				endif
				
					if !empty(oProdutoSiteProtheus:PesoLiquido)
					oModelSB1:SetValue("SB1MASTER","B1_PESO"		,oProdutoSiteProtheus:PesoLiquido)
				endif
				
				if !empty(oProdutoSiteProtheus:PESBRU)
					oModelSB1:SetValue("SB1MASTER","B1_PESBRU"	,	oProdutoSiteProtheus:PESBRU)
				endif
				
				if !empty(oProdutoSiteProtheus:PRCVEN003) .and. trim(oProdutoSiteProtheus:YB2B) == 'S'
					oModelSB1:SetValue("SB1MASTER","B1_YPRVB2B"	,	oProdutoSiteProtheus:PRCVEN003)
				endif

				


				If oModelSB1:VldData()
					conout("######5.4!")
					oModelSB1:CommitData()
					conout("Registro atualizado na SB1! = " + SB1->B1_COD)
					//Confirmsx8()
					//::cCodigo := SB1->B1_COD
					cCodSB1 := SB1->B1_COD

					oCadCliente:Codigo := SB1->B1_COD
					oCadCliente:Status :='OK'
					oCadCliente:Erro 	:='Produto atualizado com sucesso!'

					Aadd(::aCadClientes:Itens, oCadCliente)

				Else
					conout("######5.5!")
					conout("Erro ao atualizar SB1: "+varInfo('oModelSB1',oModelSB1:GetErrorMessage(), ,.F.))
					//Rollbacksx8()
					::cCodigo := "ERRO"
					// Return .F.
					oCadCliente:Codigo := SB1->B1_COD
					oCadCliente:Status :='ERRO'
					oCadCliente:Erro :=("Erro ao atualizar SB1: "+varInfo('oModelSB1',oModelSB1:GetErrorMessage(), ,.F.))
					Aadd(::aCadClientes:Itens, oCadCliente)
					DisarmTransaction()
				EndIf

				//Verificar se o item cadastro na SB1 esta lock, se estiver habilita
				if SB1->B1_MSBLQL == "1"
					recLock("SB1", .F.)
					SB1->B1_MSBLQL := "2"
					SB1->(msUnlock())
				endif

				oModelSB1:DeActivate()
				oModelSB1:Destroy()
				oModelSB1 := NIL
				// Fim SB1
 
				saveSB5Site(cCodSB1, oProdutoSiteProtheus, self)
				//aErroDA0 :=	saveDA0(oProdutoSiteProtheus)


				/*if lOk
					saveSA5(oProdutoSiteProtheus, self)
					conout ( "@@@@@ 00 ")
					aArrayAIA := saveAIA(oProdutoSiteProtheus)
					if len(aArrayAIA) > 0
						oCadCliente:Codigo := oProdutoSiteProtheus:CODPROD
						oCadCliente:Status := aArrayAIA[1,1]
						oCadCliente:Erro := aArrayAIA[1,2]
						::aCadClientes:Itens :={}
						Aadd(::aCadClientes:Itens, oCadCliente)
					endif
				endif*/

				Aadd(::aCadClientes:Itens, oCadCliente)

				lOk := .F.
			else
				oCadCliente:Codigo := oProdutoSiteProtheus:CODPROD
				oCadCliente:Status := "ERRO"
				oCadCliente:Erro := "Não foi encontrado produto com as informações inseridas, verifique os campos COD. DO PRODUTO, COD. BARRAS, FORNECEDOR PADRAO e LOJA PADRAO"
				::aCadClientes:Itens :={}
				Aadd(::aCadClientes:Itens, oCadCliente)
				lOk := .F.
			EndIf
			(cAlias)->(dbCloseArea())
		EndIf		
	END TRANSACTION

Return .T.

Static Function saveSB5Site(cCodSB1, oProdutoProtheus, oObjWS)
	Local oModelSB5	:= Nil
	dbSelectArea("SB5")
	SB5->(dbSetOrder(1))
	if SB5->(msSeek(xFilial("SB5") + cCodSB1)) // Ja Existe Cadastro
		oModelSB5 := FwLoadModel("MATA180")
		oModelSB5:SetOperation(MODEL_OPERATION_UPDATE)
		oModelSB5:Activate()

		conout("###### Codigo " + cCodSB1)

		if empty(SB5->B5_CEME)
			oModelSB5:SetValue("SB5MASTER","B5_CEME"		,SB1->B1_DESC)
		else
			oModelSB5:SetValue("SB5MASTER","B5_CEME"		,SB5->B5_CEME)
		endif
		
		if !empty(oProdutoProtheus:VlComprimento)
			oModelSB5:SetValue("SB5MASTER","B5_COMPR" 	,oProdutoProtheus:VlComprimento)
		endif

		if !empty(oProdutoProtheus:VlLagM)
			oModelSB5:SetValue("SB5MASTER","B5_LARG" 	,oProdutoProtheus:VlLagM)
		endif


		if !empty(oProdutoProtheus:VLLARG)
			oModelSB5:SetValue("SB5MASTER","B5_ALTURA" 	,oProdutoProtheus:VLLARG)
		endif

		oModelSB5:SetValue("SB5MASTER","B5_UMIND" 	, '1')

		If oModelSB5:VldData()
			oModelSB5:CommitData()
			conout("Registro ATUALIZADO na SB5!")
		Else
			conout("Erro ao atualizar SB5: "+varInfo('oModelSB5',oModelSB5:GetErrorMessage(), ,.F.))
			//::cCodigo := "ERRO"
			oModelSB5:DeActivate()
			oModelSB5:Destroy()
			oModelSB5 := NIL

			oObjWS:oCadCliente:Codigo := ''
			oObjWS:oCadCliente:Status :='ERRO'
			oObjWS:oCadCliente:Erro := ("Erro ao atualizar SB5: "+varInfo('oModelSB5',oModelSB5:GetErrorMessage(), ,.F.))
			oObjWS:aCadClientes:Itens :={}
			Aadd(oObjWS:aCadClientes:Itens, oCadCliente)
			DisarmTransaction()
		EndIf
	ELSE
		dbSelectArea("SB5")
		oModelSB5 := FwLoadModel("MATA180")
		oModelSB5:SetOperation(MODEL_OPERATION_INSERT)
		oModelSB5:Activate()

		conout("###### Codigo " + cCodSB1)
		oModelSB5:SetValue("SB5MASTER","B5_COD"		,cCodSB1)
		//oModelSB5:SetValue("SB5MASTER","B5_CEME"	,oProdutoProtheus:Descricao)
		oModelSB5:SetValue("SB5MASTER","B5_COMPR" 	,oProdutoProtheus:VlComprimento)
		oModelSB5:SetValue("SB5MASTER","B5_LARG" 	,oProdutoProtheus:VlLagM)
		oModelSB5:SetValue("SB5MASTER","B5_ALTURA" 	,oProdutoProtheus:VlAltura)
		oModelSB5:SetValue("SB5MASTER","B5_UMIND" 	, '1')

		If oModelSB5:VldData()
			oModelSB5:CommitData()
			conout("Registro INCLUIDO na SB5!")
		Else
			conout("Erro ao incluir SB5: "+varInfo('oModelSB5',oModelSB5:GetErrorMessage(), ,.F.))
			//::cCodigo := "ERRO"
			oModelSB5:DeActivate()
			oModelSB5:Destroy()
			oModelSB5 := NIL

			oObjWS:oCadCliente:Codigo := ''
			oObjWS:oCadCliente:Status :='ERRO'
			oObjWS:oCadCliente:Erro := ("Erro ao incluir SB5: "+varInfo('oModelSB5',oModelSB5:GetErrorMessage(), ,.F.))
			oObjWS:aCadClientes:Itens :={}
			Aadd(oObjWS:aCadClientes:Itens, oCadCliente)
			DisarmTransaction()
		EndIf
	ENDIF
	oModelSB5:DeActivate()
	oModelSB5:Destroy()
	oModelSB5 := NIL
return

/*/ Sava o Produto
@author Sandro Antonio do Nascimento
@since 09/03/2022
/*/
// Estrutura do Produto
WSSTRUCT oProdutoProtheus
	WSDATA CODPROD			AS String Optional
	WSDATA AliquotaIPI		AS Float Optional
	WSDATA Filial			AS String Optional
	WSDATA Descricao		AS String Optional
	WSDATA Tipo				AS String Optional
	WSDATA UnidadeMedida	AS String Optional
	WSDATA SegundaUM		AS String Optional
	WSDATA TipoConversaoUM	AS String Optional
	WSDATA FatorConversaoUM	AS Float Optional
	WSDATA Grupo			AS String Optional
	WSDATA PesoLiquido		AS Float Optional
	WSDATA CodigoBarra		AS String Optional
	WSDATA ForaLinha		As String Optional
	WSDATA PrecoVenda		AS Float Optional
	WSDATA ArmazemPadrao	AS String Optional
	WSDATA Rastreabilidade	AS String Optional
	WSDATA SubstTributaria	AS String Optional
	WSDATA GrupoTributacao 	AS String Optional
	WSDATA QtdEmbalagem 	As Float Optional
	WSDATA CatNivelQuat		AS String Optional	//CatNivel4
	WSDATA CatNivelCinc		AS String Optional	//CatNivel5 WSProtheusPC
	WSDATA ContaContabil	AS String Optional
	WSDATA CentroCusto		AS String Optional
	WSDATA VlComprimento	AS Float Optional
	WSDATA VlAltura			AS Float Optional
	WSDATA VlLagM			AS Float Optional
	WSDATA Ecommerce		AS String Optional
	WSDATA CyberlogWMS		As String Optional
	WSDATA Te				As String Optional
	WSDATA FornPadrao		As String Optional
	WSDATA LojaPadrao		As String Optional
	WSDATA OrigemProduto	As String Optional
	WSDATA NivelProduto		As String Optional 
	WSDATA PosIpi			As String Optional
	WSDATA CODVENA			As String Optional
	WSDATA PRCVENA			As Float Optional //PRCVEN001
	WSDATA CODVENB			As String Optional
	WSDATA PRCVENB			As Float Optional //PRCVEN002
	WSDATA StPr				As Float Optional
	WSDATA StSc				As Float Optional
	WSDATA UFPR				As String Optional
	WSDATA PERIMPPR			As Float Optional
	WSDATA TESPR			As String Optional
	WSDATA ALIQREDPR		As Float Optional
	WSDATA PERBASEPR		As Float Optional
	WSDATA CODAJUPR			As String Optional
	WSDATA PERICMEPR		As Float Optional
	WSDATA MOTDESPR			As String Optional
	WSDATA UFSC				As String Optional
	WSDATA PERIMPSC			As Float Optional
	WSDATA TESSC			As String Optional
	WSDATA ALIQREDSC		As Float Optional
	WSDATA PERBASESC		As Float Optional
	WSDATA CODAJUSC			As String Optional
	WSDATA PERICMESC		As Float Optional
	WSDATA MOTDESC			As String Optional
	WSDATA CodTabPR			As String Optional
	WSDATA CodValPR			As Float Optional
	WSDATA CodTabSC			As String Optional
	WSDATA CodValSC			As Float Optional
	WSDATA CODREF			As String Optional
	WSDATA CODMA			As String Optional
	WSDATA UBLQB2B			As String Optional
	WSDATA YB2B				As String Optional
	WSDATA YCATECO			As String Optional
	WSDATA YID				As String Optional
	WSDATA PESBRU			AS Float Optional
	WSDATA YDESDET			As String Optional
	WSDATA YALTB2B			As String Optional
	WSDATA YESTB2B			As String Optional
	WSDATA YPRVB2B			As Float Optional
ENDWSSTRUCT

// Webservice Gravar Produto

WSMETHOD GravarProduto WSRECEIVE oProdutoProtheus WSSEND aCadClientes WSSERVICE FluigProtheus
	Local cCodSB1	:= ""
	Local oModelSB1	:= Nil
	Local cAlias	:= GetNextAlias()
	local lOK       := .t.
	Local oCadCliente := WSClassNew("oCadCliente")
	PRIVATE lMsErroAuto := .F.
	PRIVATE inclui := .T.
	PRIVATE altera := .F.

	::aCadClientes := WSClassNew("oCadClientes")
	::aCadClientes:Itens := {}

	conout("######01!")

	BEGIN TRANSACTION
		conout("######02!")
		conout("######02! CODPROD " + cValToChar(oProdutoProtheus:CODPROD))
		if empty(oProdutoProtheus:CODPROD)

			conout("######03.1!")
			cQuery := " SELECT B1_COD "
			cQuery += " FROM "+RetSqlName('SB1')+" SB1"
			cQuery += " WHERE SB1.B1_CODBAR = '"+oProdutoProtheus:CodigoBarra+"' "
			cQuery += " 	AND SB1.B1_MSBLQL <> '1' "
			cQuery += " 	AND SB1.D_E_L_E_T_ = ' ' "
			cQuery += " ORDER BY B1_COD "

			cQuery := ChangeQuery(cQuery)

			TcQuery cQuery New Alias (cAlias) //conexao com o banco

			conout("######04!")
			dbSelectArea(cAlias)

			if (cAlias)->(!Eof())
				conout("######05!")
				conout("######05! CODPROD " + cValToChar(oProdutoProtheus:CODPROD))
				oCadCliente:Codigo := ''
				oCadCliente:Status :='ERRO'
				oCadCliente:Erro :='Código de Barra já cadastrado!'

				Aadd(::aCadClientes:Itens, oCadCliente)
				lOk := .F.
			EndIf
			(cAlias)->(dbCloseArea())
		EndIf

		if !empty(oProdutoProtheus:CODPROD)

			conout("######03.2!")
			cQuery := " SELECT B1_COD, B1_DESC "
			cQuery += " FROM "+RetSqlName('SB1')+" SB1"
			cQuery += " WHERE SB1.B1_COD = '"+oProdutoProtheus:CODPROD+"' "
			cQuery += " 	AND SB1.B1_CODBAR = '"+oProdutoProtheus:CodigoBarra +"' "
			cQuery += " 	AND SB1.B1_PROC = '"+oProdutoProtheus:FornPadrao+"' "
			cQuery += " 	AND SB1.B1_LOJPROC = '"+oProdutoProtheus:LojaPadrao+"' "
			cQuery += " 	AND SB1.D_E_L_E_T_ = ' ' "
			cQuery += " ORDER BY B1_COD "

			cQuery := ChangeQuery(cQuery)

			TcQuery cQuery New Alias (cAlias) //conexao com o banco

			conout("######04!")
			dbSelectArea(cAlias)

			if (cAlias)->(!Eof())
				conout("######05.0!")
				SB1->(DbSetOrder(1))
				SB1->(DbSeek(xFilial("SB1") + oProdutoProtheus:CODPROD))
				oModelSB1  := FwLoadModel ("MATA010")
				conout("######05.1!")
				oModelSB1:SetOperation(MODEL_OPERATION_UPDATE)
				conout("######!5.2   " +varInfo('oModelSB1',oModelSB1:GetErrorMessage(), ,.F.))
				oModelSB1:Activate()
				conout("######05.3!")

				if !empty(oProdutoProtheus:Descricao) .or. trim(oProdutoProtheus:Descricao) != ''
					oModelSB1:SetValue("SB1MASTER","B1_DESC"		,oProdutoProtheus:Descricao)
				endif

				if !empty(oProdutoProtheus:Tipo) .or. trim(oProdutoProtheus:Tipo) != ''
					oModelSB1:SetValue("SB1MASTER","B1_TIPO"		,oProdutoProtheus:Tipo)
				endif

				if !empty(oProdutoProtheus:UnidadeMedida) .or. trim(oProdutoProtheus:UnidadeMedida) != ''
					oModelSB1:SetValue("SB1MASTER","B1_UM"			,oProdutoProtheus:UnidadeMedida)
				endif

				if !empty(oProdutoProtheus:CyberlogWMS) .or. trim(oProdutoProtheus:CyberlogWMS) != ''
					oModelSB1:SetValue("SB1MASTER","B1_CYBERW"		,oProdutoProtheus:CyberlogWMS)
				endif

				if !empty(oProdutoProtheus:ArmazemPadrao) .or. trim(oProdutoProtheus:ArmazemPadrao) != ''
					oModelSB1:SetValue("SB1MASTER","B1_LOCPAD"		,oProdutoProtheus:ArmazemPadrao)
				endif

				if !empty(oProdutoProtheus:Te) .or. trim(oProdutoProtheus:Te) != ''
					oModelSB1:SetValue("SB1MASTER","B1_TE"			,oProdutoProtheus:Te)
				endif

				if !empty(oProdutoProtheus:SegundaUM) .or. trim(oProdutoProtheus:SegundaUM) != ''
					oModelSB1:SetValue("SB1MASTER","B1_SEGUM"		,oProdutoProtheus:SegundaUM)
				endif

				if !empty(oProdutoProtheus:TipoConversaoUM) .or. trim(oProdutoProtheus:TipoConversaoUM) != ''
					oModelSB1:SetValue("SB1MASTER","B1_TIPCONV"		,oProdutoProtheus:TipoConversaoUM)
				endif

				if !empty(oProdutoProtheus:FatorConversaoUM)
					oModelSB1:SetValue("SB1MASTER","B1_CONV"		,oProdutoProtheus:FatorConversaoUM)
				endif

				if !empty(oProdutoProtheus:PesoLiquido)
					oModelSB1:SetValue("SB1MASTER","B1_PESO"		,oProdutoProtheus:PesoLiquido)
				endif

				if !empty(oProdutoProtheus:ContaContabil) .or. trim(oProdutoProtheus:ContaContabil) != ''
					oModelSB1:SetValue("SB1MASTER","B1_CONTA"		,oProdutoProtheus:ContaContabil)
				endif

				if !empty(oProdutoProtheus:CentroCusto) .or. trim(oProdutoProtheus:CentroCusto) != ''
					oModelSB1:SetValue("SB1MASTER","B1_CC"			,oProdutoProtheus:CentroCusto)
				endif

				if !empty(oProdutoProtheus:NivelProduto) .or. trim(oProdutoProtheus:NivelProduto) != ''
					oModelSB1:SetValue("SB1MASTER","B1_YNIVELJ"		,oProdutoProtheus:NivelProduto)
				endif

				if !empty(oProdutoProtheus:PosIpi) .or. trim(oProdutoProtheus:PosIpi) != ''
					oModelSB1:SetValue("SB1MASTER","B1_POSIPI"		,oProdutoProtheus:PosIpi)
				endif

				if !empty(oProdutoProtheus:AliquotaIPI)
					oModelSB1:SetValue("SB1MASTER","B1_IPI"			,oProdutoProtheus:AliquotaIPI)
				endif

				if !empty(oProdutoProtheus:OrigemProduto) .or. trim(oProdutoProtheus:OrigemProduto) != ''
					oModelSB1:SetValue("SB1MASTER","B1_ORIGEM"		,oProdutoProtheus:OrigemProduto)
				endif

				if !empty(oProdutoProtheus:GrupoTributacao) .or. trim(oProdutoProtheus:GrupoTributacao) != ''
					oModelSB1:SetValue("SB1MASTER","B1_GRTRIB"		,oProdutoProtheus:GrupoTributacao)
				endif

				if !empty(oProdutoProtheus:QtdEmbalagem)
					oModelSB1:SetValue("SB1MASTER","B1_QE"			,oProdutoProtheus:QtdEmbalagem)
				endif

				if !empty(oProdutoProtheus:SubstTributaria) .or. trim(oProdutoProtheus:SubstTributaria) != ''
					oModelSB1:SetValue("SB1MASTER","B1_CEST"		,oProdutoProtheus:SubstTributaria)
				endif

				if !empty(oProdutoProtheus:Rastreabilidade) .or. trim(oProdutoProtheus:Rastreabilidade) != ''
					oModelSB1:SetValue("SB1MASTER","B1_RASTRO"		,oProdutoProtheus:Rastreabilidade)
				endif

				if !empty(oProdutoProtheus:CatNivelCinc) .or. trim(oProdutoProtheus:CatNivelCinc) != ''
					oModelSB1:SetValue("SB1MASTER","B1_01CAT1"		,left(oProdutoProtheus:CatNivelCinc, 2))
				endif

				if !empty(oProdutoProtheus:CatNivelCinc) .or. trim(oProdutoProtheus:CatNivelCinc) != ''
					oModelSB1:SetValue("SB1MASTER","B1_01CAT2"		,left(oProdutoProtheus:CatNivelCinc, 4))
				endif

				if !empty(oProdutoProtheus:CatNivelCinc) .or. trim(oProdutoProtheus:CatNivelCinc) != ''
					oModelSB1:SetValue("SB1MASTER","B1_01CAT3"		,left(oProdutoProtheus:CatNivelCinc, 6))
				endif

				if !empty(oProdutoProtheus:CatNivelQuat) .or. trim(oProdutoProtheus:CatNivelQuat) != ''
					oModelSB1:SetValue("SB1MASTER","B1_01CAT4"		,oProdutoProtheus:CatNivelQuat)
				endif

				if !empty(oProdutoProtheus:CatNivelCinc) .or. trim(oProdutoProtheus:CatNivelCinc) != ''
					oModelSB1:SetValue("SB1MASTER","B1_01CAT5"		,oProdutoProtheus:CatNivelCinc)
				endif

				if !empty(oProdutoProtheus:ForaLinha)
					oModelSB1:SetValue("SB1MASTER","B1_YFORLIN"		,oProdutoProtheus:ForaLinha)
				endif

				if !empty(oProdutoProtheus:CODMA) .or. trim(oProdutoProtheus:CODMA) != ''
					oModelSB1:SetValue("SB1MASTER","B1_01CODMA"		,oProdutoProtheus:CODMA)
				endif

				if !empty(oProdutoProtheus:StPr) 
					oModelSB1:SetValue("SB1MASTER","B1_YSTPR"		,AsString(oProdutoProtheus:StPr))
				endif

				if !empty(oProdutoProtheus:StSc) 
					oModelSB1:SetValue("SB1MASTER","B1_YSTSC"		,oProdutoProtheus:StSc)
				endif

				if !empty(oProdutoProtheus:UBLQB2B) .or. trim(oProdutoProtheus:UBLQB2B) != ''
					oModelSB1:SetValue("SB1MASTER","B1_UBLQB2B"		,AsString(oProdutoProtheus:UBLQB2B))
				endif

				if !empty(oProdutoProtheus:YB2B) .or. trim(oProdutoProtheus:YB2B) != ''
					oModelSB1:SetValue("SB1MASTER","B1_YB2B"		,AsString(oProdutoProtheus:YB2B))
				endif

				if !empty(oProdutoProtheus:YCATECO) .or. trim(oProdutoProtheus:YCATECO) != ''
					oModelSB1:SetValue("SB1MASTER","B1_YCATECO"		,AsString(oProdutoProtheus:YCATECO))
				endif

				if !empty(oProdutoProtheus:YID) .or. trim(oProdutoProtheus:YID) != ''
					oModelSB1:SetValue("SB1MASTER","B1_YID"			,AsString(oProdutoProtheus:YID))
				endif

				if !empty(oProdutoProtheus:PESBRU)
					oModelSB1:SetValue("SB1MASTER","B1_PESBRU"	,	oProdutoProtheus:PESBRU)
				endif

				if !empty(oProdutoProtheus:YALTB2B) .or. trim(oProdutoProtheus:YALTB2B) != ''
					oModelSB1:SetValue("SB1MASTER","B1_YALTB2B"		,AsString(oProdutoProtheus:YALTB2B))
				endif

				if !empty(oProdutoProtheus:YESTB2B) .or. trim(oProdutoProtheus:YESTB2B) != ''
					oModelSB1:SetValue("SB1MASTER","B1_YESTB2B"		,AsString(oProdutoProtheus:YESTB2B))
				endif

				if !empty(oProdutoProtheus:YPRVB2B) 
					oModelSB1:SetValue("SB1MASTER","B1_YPRVB2B"		, oProdutoProtheus:YPRVB2B)
				endif

				if !empty(oProdutoProtheus:YDESDET) .or. trim(oProdutoProtheus:YDESDET) != ''
					oModelSB1:SetValue("SB1MASTER","B1_YDESDET" 	,AsString(oProdutoProtheus:YDESDET))
				endif

				conout("######5.3.1! StPr " + VALTYPE(oProdutoProtheus:StPr))
				conout("######5.3.2! StSc " + VALTYPE(oProdutoProtheus:StSc))

				//oModelSB1:SetValue("SB1MASTER","B1_YSTPR"		,'2')
				//oModelSB1:SetValue("SB1MASTER","B1_YSTSC"		,'2')
				//oModelSB1:SetValue("SB1MASTER","B1_YALTB2B"	,'N')
				oModelSB1:SetValue("SB1MASTER","B1_GARANT"		,'2')
				conout("######5.3.3!")


				If oModelSB1:VldData()
					conout("######5.4!")
					oModelSB1:CommitData()
					conout("Registro atualizado na SB1! = " + SB1->B1_COD)
					//Confirmsx8()
					//::cCodigo := SB1->B1_COD
					cCodSB1 := SB1->B1_COD

					oCadCliente:Codigo := SB1->B1_COD
					oCadCliente:Status :='OK'
					oCadCliente:Erro 	:='Produto atualizado com sucesso!'

					Aadd(::aCadClientes:Itens, oCadCliente)

				Else
					conout("######5.5!")
					conout("Erro ao atualizar SB1: "+varInfo('oModelSB1',oModelSB1:GetErrorMessage(), ,.F.))
					//Rollbacksx8()
					::cCodigo := "ERRO"
					// Return .F.
					oCadCliente:Codigo := SB1->B1_COD
					oCadCliente:Status :='ERRO'
					oCadCliente:Erro :=("Erro ao atualizar SB1: "+varInfo('oModelSB1',oModelSB1:GetErrorMessage(), ,.F.))
					Aadd(::aCadClientes:Itens, oCadCliente)
					DisarmTransaction()
				EndIf

				//Verificar se o item cadastro na SB1 esta lock, se estiver habilita
				if SB1->B1_MSBLQL == "1"
					recLock("SB1", .F.)
					SB1->B1_MSBLQL := "2"
					SB1->(msUnlock())
				endif

				oModelSB1:DeActivate()
				oModelSB1:Destroy()
				oModelSB1 := NIL
				// Fim SB1

				saveSB4()

				saveSB5(cCodSB1, oProdutoProtheus, self)

				saveSZ1(oProdutoProtheus)

				aErroDA0 :=	saveDA0(oProdutoProtheus)

				if len(aErroDA0) > 0
					oCadCliente:Codigo := oProdutoProtheus:CODPROD
					oCadCliente:Status := aErroDA0[1,1]
					oCadCliente:Erro := aErroDA0[1,2]
					::aCadClientes:Itens :={}
					Aadd(::aCadClientes:Itens, oCadCliente)
					lOk := .F.
				endif

				if lOk
					saveSA5(oProdutoProtheus, self)
					conout ( "@@@@@ 00 ")
					aArrayAIA := saveAIA(oProdutoProtheus)
					if len(aArrayAIA) > 0
						oCadCliente:Codigo := oProdutoProtheus:CODPROD
						oCadCliente:Status := aArrayAIA[1,1]
						oCadCliente:Erro := aArrayAIA[1,2]
						::aCadClientes:Itens :={}
						Aadd(::aCadClientes:Itens, oCadCliente)
					endif
				endif

				Aadd(::aCadClientes:Itens, oCadCliente)

				lOk := .F.
			else
				oCadCliente:Codigo := oProdutoProtheus:CODPROD
				oCadCliente:Status := "ERRO"
				oCadCliente:Erro := "Não foi encontrado produto com as informações inseridas, verifique os campos COD. DO PRODUTO, COD. BARRAS, FORNECEDOR PADRAO e LOJA PADRAO"
				::aCadClientes:Itens :={}
				Aadd(::aCadClientes:Itens, oCadCliente)
				lOk := .F.
			EndIf
			(cAlias)->(dbCloseArea())
		EndIf

		if lOk
			DbSelectArea("SB1")
			oModelSB1  := FwLoadModel ("MATA010")
			conout("######03! caiu em incluir")
			oModelSB1:SetOperation(MODEL_OPERATION_INSERT)
			conout("######!04   " +varInfo('oModelSB1',oModelSB1:GetErrorMessage(), ,.F.))
			conout("######04.123!")
			oModelSB1:Activate()
			conout("######05.123!")

			oModelSB1:SetValue("SB1MASTER","B1_DESC"		,oProdutoProtheus:Descricao)
			oModelSB1:SetValue("SB1MASTER","B1_TIPO"		,oProdutoProtheus:Tipo)
			oModelSB1:SetValue("SB1MASTER","B1_UM"			,oProdutoProtheus:UnidadeMedida)
			oModelSB1:SetValue("SB1MASTER","B1_CYBERW"		,oProdutoProtheus:CyberlogWMS)
			oModelSB1:SetValue("SB1MASTER","B1_LOCPAD"		,oProdutoProtheus:ArmazemPadrao)
			oModelSB1:SetValue("SB1MASTER","B1_TE"			,oProdutoProtheus:Te)
			oModelSB1:SetValue("SB1MASTER","B1_SEGUM"		,oProdutoProtheus:SegundaUM)
			oModelSB1:SetValue("SB1MASTER","B1_TIPCONV"		,oProdutoProtheus:TipoConversaoUM)
			oModelSB1:SetValue("SB1MASTER","B1_CONV"		,oProdutoProtheus:FatorConversaoUM)
			//oModelSB1:SetValue("SB1MASTER","B1_CONV"		,50)
			oModelSB1:SetValue("SB1MASTER","B1_PESO"		,oProdutoProtheus:PesoLiquido)
			oModelSB1:SetValue("SB1MASTER","B1_CONTA"		,oProdutoProtheus:ContaContabil)
			oModelSB1:SetValue("SB1MASTER","B1_CC"			,oProdutoProtheus:CentroCusto)
			oModelSB1:SetValue("SB1MASTER","B1_PROC"		,oProdutoProtheus:FornPadrao)
			oModelSB1:SetValue("SB1MASTER","B1_LOJPROC"		,oProdutoProtheus:LojaPadrao)
			oModelSB1:SetValue("SB1MASTER","B1_CODBAR"		,oProdutoProtheus:CodigoBarra)
			oModelSB1:SetValue("SB1MASTER","B1_YNIVELJ"		,oProdutoProtheus:NivelProduto)
			oModelSB1:SetValue("SB1MASTER","B1_POSIPI"		,oProdutoProtheus:PosIpi)
			oModelSB1:SetValue("SB1MASTER","B1_IPI"			,oProdutoProtheus:AliquotaIPI)
			oModelSB1:SetValue("SB1MASTER","B1_ORIGEM"		,oProdutoProtheus:OrigemProduto)
			oModelSB1:SetValue("SB1MASTER","B1_GRTRIB"		,oProdutoProtheus:GrupoTributacao)
			oModelSB1:SetValue("SB1MASTER","B1_QE"			,oProdutoProtheus:QtdEmbalagem)
			oModelSB1:SetValue("SB1MASTER","B1_CEST"		,oProdutoProtheus:SubstTributaria)
			oModelSB1:SetValue("SB1MASTER","B1_RASTRO"		,oProdutoProtheus:Rastreabilidade)

			oModelSB1:SetValue("SB1MASTER","B1_01CAT1"		,left(oProdutoProtheus:CatNivelCinc, 2))
			oModelSB1:SetValue("SB1MASTER","B1_01CAT2"		,left(oProdutoProtheus:CatNivelCinc, 4))
			oModelSB1:SetValue("SB1MASTER","B1_01CAT3"		,left(oProdutoProtheus:CatNivelCinc, 6))
			oModelSB1:SetValue("SB1MASTER","B1_01CAT4"		,oProdutoProtheus:CatNivelQuat)
			oModelSB1:SetValue("SB1MASTER","B1_01CAT5"		,oProdutoProtheus:CatNivelCinc)
			oModelSB1:SetValue("SB1MASTER","B1_YFORLIN"		,oProdutoProtheus:ForaLinha)
			oModelSB1:SetValue("SB1MASTER","B1_01CODMA"		,oProdutoProtheus:CODMA)

			oModelSB1:SetValue("SB1MASTER","B1_YSTPR"		,oProdutoProtheus:StPr)
			oModelSB1:SetValue("SB1MASTER","B1_YSTSC"		,oProdutoProtheus:StSc)

			oModelSB1:SetValue("SB1MASTER","B1_UBLQB2B"		,AsString(oProdutoProtheus:UBLQB2B))
			oModelSB1:SetValue("SB1MASTER","B1_YB2B"		,AsString(oProdutoProtheus:YB2B))
			oModelSB1:SetValue("SB1MASTER","B1_YCATECO"		,AsString(oProdutoProtheus:YCATECO))
			oModelSB1:SetValue("SB1MASTER","B1_YID"			,AsString(oProdutoProtheus:YID))
			oModelSB1:SetValue("SB1MASTER","B1_PESBRU"		,oProdutoProtheus:PESBRU)
			oModelSB1:SetValue("SB1MASTER","B1_YALTB2B"		,AsString(oProdutoProtheus:YALTB2B))
			oModelSB1:SetValue("SB1MASTER","B1_YESTB2B"		,AsString(oProdutoProtheus:YESTB2B))
			oModelSB1:SetValue("SB1MASTER","B1_YPRVB2B"		,oProdutoProtheus:YPRVB2B)
			oModelSB1:SetValue("SB1MASTER","B1_YDESDET" 	,AsString(oProdutoProtheus:YDESDET))

			conout("######06! StPr " + VALTYPE(oProdutoProtheus:StPr))
			conout("######06! StSc " + VALTYPE(oProdutoProtheus:StSc))

			//oModelSB1:SetValue("SB1MASTER","B1_YSTPR"		,'2')
			//oModelSB1:SetValue("SB1MASTER","B1_YSTSC"		,'2')
			//oModelSB1:SetValue("SB1MASTER","B1_YALTB2B"	,'N')
			oModelSB1:SetValue("SB1MASTER","B1_GARANT"		,'2')
			conout("######06!")

			If oModelSB1:VldData()
				conout("######07!")
				oModelSB1:CommitData()
				conout("Registro INCLUIDO na SB1! = " + SB1->B1_COD)
				//Confirmsx8()
				//::cCodigo := SB1->B1_COD
				cCodSB1 := SB1->B1_COD

				oCadCliente:Codigo := SB1->B1_COD
				oCadCliente:Status :='OK'
				oCadCliente:Erro 	:='Produto incluido com sucesso!'

				Aadd(::aCadClientes:Itens, oCadCliente)

			Else
				conout("######08!")
				conout("Erro ao incluir SB1: "+varInfo('oModelSB1',oModelSB1:GetErrorMessage(), ,.F.))
				//Rollbacksx8()
				::cCodigo := "ERRO"
				// Return .F.
				oCadCliente:Codigo := ''
				oCadCliente:Status :='ERRO'
				oCadCliente:Erro :=("Erro ao incluir SB1: "+varInfo('oModelSB1',oModelSB1:GetErrorMessage(), ,.F.))
				Aadd(::aCadClientes:Itens, oCadCliente)
				DisarmTransaction()
			EndIf

			//Verificar se o item cadastro na SB1 esta lock, se estiver habilita
			if SB1->B1_MSBLQL == "1"
				recLock("SB1", .F.)
				SB1->B1_MSBLQL := "2"
				SB1->(msUnlock())
			endif

			oModelSB1:DeActivate()
			oModelSB1:Destroy()
			oModelSB1 := NIL
			// Fim SB1
			u_RT001() // Criar saldo SB2

			saveSB4()

			saveSB5(cCodSB1, oProdutoProtheus, self)

			saveSZ1(oProdutoProtheus)

			aErroDA0 :=	saveDA0(oProdutoProtheus)

			if len(aErroDA0) > 0
				oCadCliente:Codigo := ''
				oCadCliente:Status := aErroDA0[1,1]
				oCadCliente:Erro := aErroDA0[1,2]
				::aCadClientes:Itens :={}
				Aadd(::aCadClientes:Itens, oCadCliente)
				lOk := .F.
			endif


			if lOk
				saveSA5(oProdutoProtheus, self)
				conout ( "@@@@@ 00 ")
				aArrayAIA := saveAIA(oProdutoProtheus)
				if len(aArrayAIA) > 0
					oCadCliente:Codigo := SB1->B1_COD
					oCadCliente:Status := aArrayAIA[1,1]
					oCadCliente:Erro := aArrayAIA[1,2]
					::aCadClientes:Itens :={}
					Aadd(::aCadClientes:Itens, oCadCliente)
				endif
			endif

		endif
	END TRANSACTION

Return .T.

Static Function saveSB4()
	dbSelectArea("SB4")
	SB4->(dbSetOrder(1))
	if SB4->(msSeek(xFilial("SB4") + SB1->B1_COD)) // Ja Existe Cadastro
		recLock("SB4", .F.)
		SB4->B4_STATUS  := "A"
		SB4->B4_01UTGRD := "N"
	else
		recLock("SB4", .T.)
		SB4->B4_FILIAL  := xFilial("SB4")
		SB4->B4_COD     := SB1->B1_COD
		SB4->B4_STATUS  := "A"
		SB4->B4_01UTGRD := "N"
	endif

	SB4->B4_CODBAR		:= SB1->B1_CODBAR
	SB4->B4_DESC		:= SB1->B1_DESC
	SB4->B4_CONV		:= SB1->B1_CONV
	SB4->B4_TIPCONV		:= SB1->B1_TIPCONV
	SB4->B4_QE			:= SB1->B1_QE
	SB4->B4_SEGUM 		:= SB1->B1_SEGUM
	SB4->B4_UM			:= SB1->B1_UM
	SB4->B4_CC			:= SB1->B1_CC
	SB4->B4_01CAT1		:= SB1->B1_01CAT1
	SB4->B4_01CAT2		:= SB1->B1_01CAT2
	SB4->B4_01CAT3		:= SB1->B1_01CAT3
	SB4->B4_01CAT4		:= SB1->B1_01CAT4
	SB4->B4_01CAT5		:= SB1->B1_01CAT5
	SB4->B4_IPI			:= SB1->B1_IPI
	//SB4->B4_PRCVEN001	:= SB1->PRCVENA
	//SB4->B4_PRCVEN002	:= SB1->PRCVENB
	SB4->B4_CYBERW		:= SB1->B1_CYBERW
	SB4->B4_01CODMA		:= SB1->B1_01CODMA
	SB4->B4_PROC		:= SB1->B1_PROC
	SB4->B4_LOJPROC		:= SB1->B1_LOJPROC
	SB4->B4_ORIGEM		:= SB1->B1_ORIGEM
	SB4->B4_TIPO		:= SB1->B1_TIPO
	SB4->B4_LOCPAD		:= SB1->B1_LOCPAD
	SB4->B4_POSIPI		:= SB1->B1_POSIPI
	SB4->B4_CEST		:= SB1->B1_CEST
	SB4->B4_YSTPR		:= SB1->B1_YSTPR
	SB4->B4_YSTSC		:= SB1->B1_YSTSC

	SB4->(msUnlock())
return


Static Function saveSB5(cCodSB1, oProdutoProtheus, oObjWS)
	Local oModelSB5	:= Nil
	dbSelectArea("SB5")
	SB5->(dbSetOrder(1))
	if SB5->(msSeek(xFilial("SB5") + cCodSB1)) // Ja Existe Cadastro
		oModelSB5 := FwLoadModel("MATA180")
		oModelSB5:SetOperation(MODEL_OPERATION_UPDATE)
		oModelSB5:Activate()

		conout("###### Codigo " + cCodSB1)
		
		if !empty(oProdutoProtheus:Descricao) .and. trim(oProdutoProtheus:Descricao) != ''
			oModelSB5:SetValue("SB5MASTER","B5_CEME"		,oProdutoProtheus:Descricao)
		endif
		
		if !empty(oProdutoProtheus:VlComprimento)
			oModelSB5:SetValue("SB5MASTER","B5_COMPR" 	,oProdutoProtheus:VlComprimento)
		endif

		if !empty(oProdutoProtheus:VlLagM)
			oModelSB5:SetValue("SB5MASTER","B5_LARG" 	,oProdutoProtheus:VlLagM)
		endif


		if !empty(oProdutoProtheus:VlAltura)
			oModelSB5:SetValue("SB5MASTER","B5_ALTURA" 	,oProdutoProtheus:VlAltura)
		endif

		oModelSB5:SetValue("SB5MASTER","B5_UMIND" 	, '1')

		If oModelSB5:VldData()
			oModelSB5:CommitData()
			conout("Registro ATUALIZADO na SB5!")
		Else
			conout("Erro ao atualizar SB5: "+varInfo('oModelSB5',oModelSB5:GetErrorMessage(), ,.F.))
			//::cCodigo := "ERRO"
			oModelSB5:DeActivate()
			oModelSB5:Destroy()
			oModelSB5 := NIL

			oObjWS:oCadCliente:Codigo := ''
			oObjWS:oCadCliente:Status :='ERRO'
			oObjWS:oCadCliente:Erro := ("Erro ao atualizar SB5: "+varInfo('oModelSB5',oModelSB5:GetErrorMessage(), ,.F.))
			oObjWS:aCadClientes:Itens :={}
			Aadd(oObjWS:aCadClientes:Itens, oCadCliente)
			DisarmTransaction()
		EndIf
	ELSE
		dbSelectArea("SB5")
		oModelSB5 := FwLoadModel("MATA180")
		oModelSB5:SetOperation(MODEL_OPERATION_INSERT)
		oModelSB5:Activate()

		conout("###### Codigo " + cCodSB1)
		oModelSB5:SetValue("SB5MASTER","B5_COD"		,cCodSB1)
		oModelSB5:SetValue("SB5MASTER","B5_CEME"	,oProdutoProtheus:Descricao)
		oModelSB5:SetValue("SB5MASTER","B5_COMPR" 	,oProdutoProtheus:VlComprimento)
		oModelSB5:SetValue("SB5MASTER","B5_LARG" 	,oProdutoProtheus:VlLagM)
		oModelSB5:SetValue("SB5MASTER","B5_ALTURA" 	,oProdutoProtheus:VlAltura)
		oModelSB5:SetValue("SB5MASTER","B5_UMIND" 	, '1')

		If oModelSB5:VldData()
			oModelSB5:CommitData()
			conout("Registro INCLUIDO na SB5!")
		Else
			conout("Erro ao incluir SB5: "+varInfo('oModelSB5',oModelSB5:GetErrorMessage(), ,.F.))
			//::cCodigo := "ERRO"
			oModelSB5:DeActivate()
			oModelSB5:Destroy()
			oModelSB5 := NIL

			oObjWS:oCadCliente:Codigo := ''
			oObjWS:oCadCliente:Status :='ERRO'
			oObjWS:oCadCliente:Erro := ("Erro ao incluir SB5: "+varInfo('oModelSB5',oModelSB5:GetErrorMessage(), ,.F.))
			oObjWS:aCadClientes:Itens :={}
			Aadd(oObjWS:aCadClientes:Itens, oCadCliente)
			DisarmTransaction()
		EndIf
	ENDIF
	oModelSB5:DeActivate()
	oModelSB5:Destroy()
	oModelSB5 := NIL
return


Static Function saveSZ1(oProdutoProtheus)
	conout("###### UFPR! " + oProdutoProtheus:UFPR)
	if oProdutoProtheus:UFPR <> ''
		dbSelectArea("SZ1")
		SZ1->(dbSetOrder(3))
		IF SZ1->(msSeek(xFilial("SZ1") + SB1->B1_COD + oProdutoProtheus:UFPR)) // Já existe cadastro
			recLock("SZ1", .F.)
			SZ1->Z1_FILIAL := xFilial("SZ1")

			if !empty(oProdutoProtheus:UFPR) .or. trim(oProdutoProtheus:UFPR) != ''
				SZ1->Z1_UF			:= oProdutoProtheus:UFPR
			endif

			if !empty(oProdutoProtheus:PERIMPPR)
				SZ1->Z1_PERIMP		:= oProdutoProtheus:PERIMPPR
			endif

			if !empty(oProdutoProtheus:TESPR) .or. trim(oProdutoProtheus:TESPR) != ''
				SZ1->Z1_TES			:= oProdutoProtheus:TESPR
			endif

			if !empty(oProdutoProtheus:ALIQREDPR)
				SZ1->Z1_ALIQRED		:= oProdutoProtheus:ALIQREDPR
			endif

			if !empty(oProdutoProtheus:PERBASEPR)
				SZ1->Z1_PERBASE		:= oProdutoProtheus:PERBASEPR
			endif

			if !empty(oProdutoProtheus:CODAJUPR) .or. trim(oProdutoProtheus:CODAJUPR) != ''
				SZ1->Z1_CODAJU		:= oProdutoProtheus:CODAJUPR
			endif
			
			if !empty(oProdutoProtheus:PERICMEPR)
				SZ1->Z1_PERICME		:= oProdutoProtheus:PERICMEPR
			endif

			if !empty(oProdutoProtheus:MOTDESPR) .or. trim(oProdutoProtheus:MOTDESPR) != ''
				SZ1->Z1_MOTDES		:= oProdutoProtheus:MOTDESPR
			endif
		ELSE
			recLock("SZ1", .T.)
			SZ1->Z1_FILIAL := xFilial("SZ1")
			SZ1->Z1_UF			:= oProdutoProtheus:UFPR
			SZ1->Z1_PRODUTO 	:= SB1->B1_COD
			SZ1->Z1_PERIMP		:= oProdutoProtheus:PERIMPPR
			SZ1->Z1_TES			:= oProdutoProtheus:TESPR
			SZ1->Z1_ALIQRED		:= oProdutoProtheus:ALIQREDPR
			SZ1->Z1_PERBASE		:= oProdutoProtheus:PERBASEPR
			SZ1->Z1_CODAJU		:= oProdutoProtheus:CODAJUPR
			SZ1->Z1_PERICME		:= oProdutoProtheus:PERICMEPR
			SZ1->Z1_MOTDES		:= oProdutoProtheus:MOTDESPR
		ENDIF
		SZ1->(msUnlock())
	EndIf

	if oProdutoProtheus:UFSC <> ''
		dbSelectArea("SZ1")
		SZ1->(dbSetOrder(3))
		IF SZ1->(msSeek(xFilial("SZ1") + SB1->B1_COD + oProdutoProtheus:UFSC )) // Já existe cadastro
			recLock("SZ1", .F.)
			SZ1->Z1_FILIAL := xFilial("SZ1")
			
			if !empty(oProdutoProtheus:UFSC) .or. trim(oProdutoProtheus:UFSC) != ''
				SZ1->Z1_UF			:= oProdutoProtheus:UFSC
			endif

			if !empty(oProdutoProtheus:PERIMPSC) 
				SZ1->Z1_PERIMP		:= oProdutoProtheus:PERIMPSC
			endif

			if !empty(oProdutoProtheus:TESSC) .or. trim(oProdutoProtheus:TESSC) != ''
				SZ1->Z1_TES			:= oProdutoProtheus:TESSC
			endif

			if !empty(oProdutoProtheus:ALIQREDSC)
				SZ1->Z1_ALIQRED		:= oProdutoProtheus:ALIQREDSC
			endif

			if !empty(oProdutoProtheus:PERBASESC)
				SZ1->Z1_PERBASE		:= oProdutoProtheus:PERBASESC
			endif

			if !empty(oProdutoProtheus:CODAJUSC) .or. trim(oProdutoProtheus:CODAJUSC) != ''
				SZ1->Z1_CODAJU		:= oProdutoProtheus:CODAJUSC
			endif
			
			if !empty(oProdutoProtheus:PERICMESC)
				SZ1->Z1_PERICME		:= oProdutoProtheus:PERICMESC
			endif

			if !empty(oProdutoProtheus:MOTDESC) .or. trim(oProdutoProtheus:MOTDESC) != ''
				SZ1->Z1_MOTDES		:= oProdutoProtheus:MOTDESC
			endif
		ELSE
			recLock("SZ1", .T.)
			SZ1->Z1_FILIAL := xFilial("SZ1")
			SZ1->Z1_UF			:= oProdutoProtheus:UFSC
			SZ1->Z1_PRODUTO 	:= SB1->B1_COD
			SZ1->Z1_PERIMP		:= oProdutoProtheus:PERIMPSC
			SZ1->Z1_TES			:= oProdutoProtheus:TESSC
			SZ1->Z1_ALIQRED		:= oProdutoProtheus:ALIQREDSC
			SZ1->Z1_PERBASE		:= oProdutoProtheus:PERBASESC
			SZ1->Z1_CODAJU		:= oProdutoProtheus:CODAJUSC
			SZ1->Z1_PERICME		:= oProdutoProtheus:PERICMESC
			SZ1->Z1_MOTDES		:= oProdutoProtheus:MOTDESC
		ENDIF
		SZ1->(msUnlock())
	EndIf
return

Static Function saveDA0(oProdutoProtheus, oObjWS)
	// ---------------------------------------------------------------- Tabela de PReço
	Local aErroDA0 	:= {}
	if oProdutoProtheus:CODVENA <> ''
		dbSelectArea("DA0")
		DA0->(dbSetOrder(1))
		if DA0->(msSeek(xFilial("DA0") + oProdutoProtheus:CODVENA))
			dbSelectArea("DA1")
			DA1->(dbSetOrder(1))
			if DA1->(msSeek(xFilial("DA1") + oProdutoProtheus:CODVENA + SB1->B1_COD))
				recLock("DA1", .F.)
				if !empty(oProdutoProtheus:PRCVENA)
					DA1->DA1_PRCVEN := oProdutoProtheus:PRCVENA
				endif

				DA1->(msUnlock())
			else
				cItem := fUltItem(oProdutoProtheus:CODVENA, "DA1") // Proximo item disponivel

				recLock("DA1", .T.)
				DA1->DA1_FILIAL := xFilial("DA1")
				DA1->DA1_CODTAB := oProdutoProtheus:CODVENA
				DA1->DA1_ITEM   := cItem
				DA1->DA1_CODPRO := SB1->B1_COD
				DA1->DA1_PRCVEN := oProdutoProtheus:PRCVENA
				DA1->DA1_ATIVO  := "1"
				DA1->DA1_TPOPER := "4"
				DA1->DA1_QTDLOT := 999999.99
				DA1->(msUnlock())
			endif
		else
			conout( "Tabela de venda não encontrada.")
			Aadd(aErroDA0,{'ERRO','Tabela de venda não encontrada.'})
		endif
	endif

	if oProdutoProtheus:CODVENB <> ''
		dbSelectArea("DA0")
		DA0->(dbSetOrder(1))
		if DA0->(msSeek(xFilial("DA0") + oProdutoProtheus:CODVENB))
			dbSelectArea("DA1")
			DA1->(dbSetOrder(1))
			if DA1->(msSeek(xFilial("DA1") + oProdutoProtheus:CODVENB + SB1->B1_COD))
				recLock("DA1", .F.)
				if !empty(oProdutoProtheus:PRCVENB)
					DA1->DA1_PRCVEN := oProdutoProtheus:PRCVENB
				endif

				DA1->(msUnlock())
			else
				cItem := fUltItem(oProdutoProtheus:CODVENB, "DA1") // Proximo item disponivel

				recLock("DA1", .T.)
				DA1->DA1_FILIAL := xFilial("DA1")
				DA1->DA1_CODTAB := oProdutoProtheus:CODVENB
				DA1->DA1_ITEM   := cItem
				DA1->DA1_CODPRO := SB1->B1_COD
				DA1->DA1_PRCVEN := oProdutoProtheus:PRCVENB
				DA1->DA1_ATIVO  := "1"
				DA1->DA1_TPOPER := "4"
				DA1->DA1_QTDLOT := 999999.99
				DA1->(msUnlock())
			endif
		else
			conout( "Tabela de venda não encontrada.")
			Aadd(aErroDA0,{'ERRO','Tabela de venda não encontrada.'})
		endif
	endif

	if !empty(oProdutoProtheus:YPRVB2B)
		dbSelectArea("DA0")
		DA0->(dbSetOrder(1))
		if DA0->(msSeek(xFilial("DA0") + '003'))
			dbSelectArea("DA1")
			DA1->(dbSetOrder(1))
			if DA1->(msSeek(xFilial("DA1") + '003' + SB1->B1_COD))
				recLock("DA1", .F.)
				if !empty(oProdutoProtheus:YPRVB2B) 
					DA1->DA1_PRCVEN := oProdutoProtheus:YPRVB2B
				endif
				DA1->(msUnlock())
			else
				cItem := fUltItem('003', "DA1") // Proximo item disponivel

				recLock("DA1", .T.)
				DA1->DA1_FILIAL := xFilial("DA1")
				DA1->DA1_CODTAB := '003'
				DA1->DA1_ITEM   := cItem
				DA1->DA1_CODPRO := SB1->B1_COD
				DA1->DA1_PRCVEN := oProdutoProtheus:YPRVB2B
				DA1->DA1_ATIVO  := "1"
				DA1->DA1_TPOPER := "4"
				DA1->DA1_QTDLOT := 999999.99
				DA1->(msUnlock())
			endif
		else
			conout( "Tabela de venda não encontrada.")
			Aadd(aErroDA0,{'ERRO','Tabela de venda não encontrada.'})
		endif
	endif

return aErroDA0

Static Function saveSA5(oProdutoProtheus, oObjWS)
	dbSelectArea("SA5")
	SA5->(dbSetOrder(1)) // A5_FILIAL+A5_FORNECE+A5_LOJA+A5_PRODUTO
	if SA5->(msSeek(xFilial("SA5") + SB1->B1_PROC +  SB1->B1_LOJPROC + SB1->B1_COD))
		if allTrim(SA5->A5_CODPRF) <> allTrim(SB1->B1_LOJPROC)
			recLock("SA5", .F.)
			if !empty(oProdutoProtheus:CODREF) .or. trim(oProdutoProtheus:CODREF) != ''
				SA5->A5_CODPRF :=  oProdutoProtheus:CODREF
			endif

			if !empty(oProdutoProtheus:Descricao) .or. trim(oProdutoProtheus:Descricao) != ''
				SA5->A5_NOMPROD := oProdutoProtheus:Descricao
			endif

			if !empty(oProdutoProtheus:CodTabPR) .or. trim(oProdutoProtheus:CodTabPR) != ''
				SA5->A5_CODTAB  := oProdutoProtheus:CodTabPR
			endif
			SA5->(msUnlock())
		endif
	else
		DBSelectArea("SA2")
		SA2->(dbSetOrder(1))
		SA2->(msSeek(xFilial("SA2") + SB1->B1_PROC + SB1->B1_LOJPROC))
		// Alterado pois o execauto padrao nao esta funcionando corretamente
		recLock("SA5", .T.)
		SA5->A5_FILIAL  := xFilial("SA5")
		SA5->A5_FORNECE := SB1->B1_PROC
		SA5->A5_LOJA    := SB1->B1_LOJPROC
		SA5->A5_NOMEFOR := SA2->A2_NOME
		SA5->A5_PRODUTO := SB1->B1_COD
		SA5->A5_NOMPROD := SB1->B1_DESC
		SA5->A5_CODTAB  := oProdutoProtheus:CodTabPR
		SA5->A5_CODPRF  := oProdutoProtheus:CODREF
		SA5->(msUnlock())
	endif

	dbSelectArea("SA5")
	SA5->(dbSetOrder(1)) // A5_FILIAL+A5_FORNECE+A5_LOJA+A5_PRODUTO
	if SA5->(msSeek(xFilial("SA5") + SB1->B1_PROC +  SB1->B1_LOJPROC + SB1->B1_COD))
		if allTrim(SA5->A5_CODPRF) <> allTrim(SB1->B1_LOJPROC)
			recLock("SA5", .F.)
			if !empty(oProdutoProtheus:CODREF) .or. trim(oProdutoProtheus:CODREF) != ''
				SA5->A5_CODPRF :=  oProdutoProtheus:CODREF
			endif

			SA5->(msUnlock())
		endif
	else
		DBSelectArea("SA2")
		SA2->(dbSetOrder(1))
		SA2->(msSeek(xFilial("SA2") + SB1->B1_PROC + SB1->B1_LOJPROC))
		// Alterado pois o execauto padrao nao esta funcionando corretamente
		recLock("SA5", .T.)
		SA5->A5_FILIAL  := xFilial("SA5")
		SA5->A5_FORNECE := SB1->B1_PROC
		SA5->A5_LOJA    := SB1->B1_LOJPROC
		SA5->A5_NOMEFOR := SA2->A2_NOME
		SA5->A5_PRODUTO := SB1->B1_COD
		SA5->A5_NOMPROD := SB1->B1_DESC
		SA5->A5_CODTAB  := oProdutoProtheus:CodTabSC
		SA5->A5_CODPRF  := oProdutoProtheus:CODREF
		SA5->(msUnlock())
	endif
return

Static Function saveAIA(oProdutoProtheus)
	Local aArrayAIA := {}
	conout ( "@@@@@ 01 ")
	// Cabecalho
	dbSelectArea("AIA")
	AIA->(dbSetOrder(1))
	AIA->(dbGoTop())
	if AIA->(msSeek(xFilial("AIA") + SB1->B1_PROC + SB1->B1_LOJPROC + oProdutoProtheus:CodTabPR))
		conout ( "@@@@@ 02 ")
		dbSelectArea("AIB")
		AIB->(dbSetOrder(2))
		AIB->(dbGoTop())
		if AIB->(msSeek(xFilial("AIB") + SB1->B1_PROC + SB1->B1_LOJPROC + oProdutoProtheus:CodTabPR + SB1->B1_COD)) // Tabela já possui o item
			conout ( "@@@@@ 03 ")
			recLock("AIB", .F.)
			if !empty(oProdutoProtheus:CodTabPR) .or. trim(oProdutoProtheus:CodTabPR) != ''
				AIB->AIB_CODTAB := oProdutoProtheus:CodTabPR
			endif

			if !empty(oProdutoProtheus:CodValPR)// Se o estado for informado no arquivo devera atualizar o preço do estado
				AIB->AIB_PRCCOM := oProdutoProtheus:CodValPR
			endif

			AIB->AIB_DATVIG := AIA->AIA_DATDE

			AIB->(msUnlock())
		else
			conout ( "@@@@@ 04 ")
			recLock("AIB", .T.)
			cItem   := fUltItem(oProdutoProtheus:CodTabPR, "AIB")
			conout ( "@@@@@ 05 ")
			AIB->AIB_FILIAL := xFilial("AIB")
			AIB->AIB_CODFOR := SB1->B1_PROC
			AIB->AIB_LOJFOR := SB1->B1_LOJPROC
			AIB->AIB_CODTAB := oProdutoProtheus:CodTabPR
			AIB->AIB_ITEM   := cItem
			AIB->AIB_CODPRO := SB1->B1_COD
			AIB->AIB_QTDLOT := 999999.99
			AIB->AIB_INDLOT := '000000000999999.99'
			AIB->AIB_DATVIG := AIA->AIA_DATDE
			conout ( "@@@@@ 06 ")
			if !empty(oProdutoProtheus:CodTabPR) // Se o estado for informado no arquivo devera atualizar o preço do estado
				conout ( "@@@@@ 07 ")
				//AIB_YPRCSC := oProdutoProtheus:CodValPR
			endif
			conout ( "@@@@@ 08 ")
			AIB->AIB_PRCCOM := oProdutoProtheus:CodValPR
			AIB->(msUnlock())
		endiF
	else // Tabela de preço de compra nao existe (Erro - Deve ser cadastrado previamente)
		conout ( "Tabela de preço de compra não encontrada. Tabela: ")
		Aadd(aArrayAIA,{'ERRO','Tabela de preço de compra não encontrada. Deve ser cadastrado previamente'})
	endif

	// Cabecalho
	dbSelectArea("AIA")
	AIA->(dbSetOrder(1))
	AIA->(dbGoTop())
	if AIA->(msSeek(xFilial("AIA") + SB1->B1_PROC + SB1->B1_LOJPROC + oProdutoProtheus:CodTabSC))
		dbSelectArea("AIB")
		AIB->(dbSetOrder(2))
		AIB->(dbGoTop())
		if AIB->(msSeek(xFilial("AIB") + SB1->B1_PROC + SB1->B1_LOJPROC + oProdutoProtheus:CodTabSC + SB1->B1_COD)) // Tabela já possui o item
			recLock("AIB", .F.)
			if !empty(oProdutoProtheus:CodTabSC) .or. trim(oProdutoProtheus:CodTabSC) != ''
				AIB->AIB_CODTAB := oProdutoProtheus:CodTabSC
			endif

			if !empty(oProdutoProtheus:CodValSC) // Se o estado for informado no arquivo devera atualizar o preço do estado
				AIB->AIB_YPRCSC := oProdutoProtheus:CodValSC
			endif
				
			AIB->AIB_DATVIG := AIA->AIA_DATDE
			
			AIB->(msUnlock())
		else
			recLock("AIB", .T.)
			cItem   := fUltItem(oProdutoProtheus:CodTabSC, "AIB")
			AIB->AIB_FILIAL := xFilial("AIB")
			AIB->AIB_CODFOR := SB1->B1_PROC
			AIB->AIB_LOJFOR := SB1->B1_LOJPROC
			AIB->AIB_CODTAB := oProdutoProtheus:CodTabSC
			AIB->AIB_ITEM   := cItem
			AIB->AIB_CODPRO := SB1->B1_COD
			AIB->AIB_QTDLOT := 999999.99
			AIB->AIB_INDLOT := '000000000999999.99'
			AIB->AIB_DATVIG := AIA->AIA_DATDE
			if !empty(oProdutoProtheus:CodTabSC) // Se o estado for informado no arquivo devera atualizar o preço do estado
				AIB->AIB_YPRCSC := oProdutoProtheus:CodValSC
			endif
			AIB->AIB_PRCCOM := oProdutoProtheus:CodValPR
			AIB->(msUnlock())
		endiF
	else // Tabela de preço de compra nao existe (Erro - Deve ser cadastrado previamente)
		conout ( "Tabela de preço de compra não encontrada. Tabela: ")
		Aadd(aArrayAIA,{'ERRO','Tabela de preço de compra não encontrada. Deve ser cadastrado previamente'})
	endif
return aArrayAIA


Static Function fUltItem(cTabela, cTabSX3)
	local cLastItem := ""

	if cTabSX3 == "DA1"
		_cSelect := "SELECT MAX(DA1_ITEM) ZZ_MAXITE" + CRLF
		_cSelect += "  FROM " + retSqlName("DA1") + " (NOLOCK) " + CRLF
		_cSelect += " WHERE DA1_FILIAL = " + valToSql(xFilial("DA1")) + CRLF
		_cSelect += "   AND DA1_CODTAB = " + valToSql(cTabela) + CRLF
		_cSelect += "   AND D_E_L_E_T_ = '' " + CRLF
	elseif cTabSX3 == "AIB"
		_cSelect := "SELECT MAX(AIB_ITEM) ZZ_MAXITE " + CRLF
		_cSelect += "  FROM " + retSqlName("AIB") + " (NOLOCK) " + CRLF
		_cSelect += " WHERE AIB_FILIAL = " + valToSql(xFilial("AIB")) + CRLF
		_cSelect += "   AND AIB_CODTAB = " + valToSql(cTabela) + CRLF
		_cSelect += "   AND D_E_L_E_T_ = '' " + CRLF
	endif

	tcQuery _cSelect new alias "TABAUX"
	if !TABAUX->(EoF())
		cLastItem := Soma1(TABAUX->ZZ_MAXITE)
	endif
	TABAUX->(dbCloseArea())
return cLastItem

