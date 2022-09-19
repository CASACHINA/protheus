#INCLUDE "APWEBSRV.CH"
#INCLUDE "PROTHEUS.CH"
#INCLUDE "TBICONN.CH"
#INCLUDE "TOPCONN.CH"
#INCLUDE 'FWMVCDef.ch'

/*---------------------------------------------------------------------------+
!                       FICHA TECNICA DO PROGRAMA                            !
+------------------+---------------------------------------------------------+
!Tipo              ! Web Service	                               			 !
!Módulo            ! Protheus x Fluig			       	                     !
!Cliente	       ! Ademicon    										     !
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
	WSDATA Login				AS String optional
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

// WebService FluigProtheus
WSSERVICE FluigProtheus DESCRIPTION 'Fluig x Protheus - Workflow'
	WSDATA oAprovacao		AS oAprovacao
    WSDATA aCentrosCustos 	AS oCentrosCustos
	WSDATA aProdutos 		AS oProdutos
	WSDATA oSolicitacao		AS oSolicitacao
	WSDATA aEmpresas		AS oEmpresas
	WSDATA aFornecedores	AS oFornecedores
	WSDATA oProdutoProtheus AS oProdutoProtheus
	WSDATA aCadClientes		AS oCadClientes

	WSDATA cStatus			AS String
	WSDATA SCRRecno			AS String
	WSDATA cCodigo			AS String	
	WSDATA nSaldo			AS float
	
	WSMETHOD AprovWFPC			DESCRIPTION 'Aprovar Workflow de Pedido de Compras'
	WSMETHOD LiberarPC			DESCRIPTION 'Liberar Pedido de Compras'
    WSMETHOD CentrosCustos		DESCRIPTION 'Listas todos os Centros de Custos'
	WSMETHOD Produtos			DESCRIPTION 'Listas todos os Produtos'
	WSMETHOD GerarSC			DESCRIPTION 'Gera a Solicitação de Compras'
	WSMETHOD ValidaSaldo		DESCRIPTION 'Valida o saldo do aprovador'
	WSMETHOD Empresas			DESCRIPTION 'Lista todas as empresas'
	WSMETHOD Fornecedores		DESCRIPTION 'Busca os Fornecedores'
	WSMETHOD GetValidaSaldo		DESCRIPTION 'Pega o saldo pelo dia'
	WSMETHOD GravarProduto		DESCRIPTION 'Grava o Produto'

ENDWSSERVICE

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
	
	cQuery := " SELECT B1_FILIAL, B1_COD, B1_DESC, B1_TIPO, B1_UM " 
	cQuery += " FROM "+RetSqlName('SB1')+" SB1" 
	cQuery += " WHERE SB1.B1_MSBLQL <> '1'" 
	cQuery += " 	AND SB1.D_E_L_E_T_ = ' ' " 
	cQuery += " ORDER BY B1_FILIAL, B1_COD "

	cQuery := ChangeQuery(cQuery)
	
	TcQuery cQuery New Alias (cAlias)
		
	dbSelectArea(cAlias)
	
	While (cAlias)->(!Eof())

		oProduto := WSClassNew("oProduto")

		oProduto:Filial 	:= (cAlias)->B1_FILIAL
		oProduto:Codigo 	:= Alltrim((cAlias)->B1_COD)
		oProduto:Descricao	:= Alltrim((cAlias)->B1_DESC)
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


/*/ Sava o Produto 
@author Sandro Antonio do Nascimento
@since 09/03/2022
/*/
// Estrutura do Produto
WSSTRUCT oProdutoProtheus
	WSDATA AliquotaIPI		AS Float Optional
	WSDATA Filial			AS String
	WSDATA Descricao		AS String
	WSDATA Tipo				AS String 
	WSDATA UnidadeMedida	AS String 
	WSDATA SegundaUM		AS String Optional
	WSDATA TipoConversaoUM	AS String Optional
	WSDATA FatorConversaoUM	AS Float Optional
	WSDATA Grupo			AS String Optional
	WSDATA PesoLiquido		AS Float Optional
	WSDATA CodigoBarra		AS String Optional
	WSDATA ForaLinha		As String
	WSDATA PrecoVenda		AS Float Optional
	WSDATA ArmazemPadrao	AS String
	WSDATA Rastreabilidade	AS String Optional
	WSDATA SubstTributaria	AS String Optional
	WSDATA GrupoTributacao 	AS String
	WSDATA QtdEmbalagem 	As Float Optional
	WSDATA CatNivelQuat		AS String Optional	//CatNivel4
	WSDATA CatNivelCinc		AS String Optional	//CatNivel5 WSProtheusPC
	WSDATA ContaContabil	AS String
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
	WSDATA NivelProduto		As String
	WSDATA PosIpi			As String
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
		
		if !empty(oProdutoProtheus:CodigoBarra)

			conout("######03!")
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
				oCadCliente:Codigo := ''
				oCadCliente:Status :='ERRO'
				oCadCliente:Erro :='Código de Barra já cadastrado!'

				Aadd(::aCadClientes:Itens, oCadCliente)
				lOk := .F.			
			EndIf
			(cAlias)->(dbCloseArea()) 
		EndIf			
		

		if lOk
			oModelSB1  := FwLoadModel ("MATA010")
			conout("######03!")
			oModelSB1:SetOperation(MODEL_OPERATION_INSERT)
			conout("######!04   " +varInfo('oModelSB1',oModelSB1:GetErrorMessage(), ,.F.))
			oModelSB1:Activate()
			conout("######05!")

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
			oModelSB1:SetValue("SB1MASTER","B1_CODBAR"		,oProdutoProtheus:CodigoBarra)
			oModelSB1:SetValue("SB1MASTER","B1_01CAT1"		,left(oProdutoProtheus:CatNivelCinc, 2))
			oModelSB1:SetValue("SB1MASTER","B1_01CAT2"		,left(oProdutoProtheus:CatNivelCinc, 4))
			oModelSB1:SetValue("SB1MASTER","B1_01CAT3"		,left(oProdutoProtheus:CatNivelCinc, 6))
			oModelSB1:SetValue("SB1MASTER","B1_01CAT4"		,oProdutoProtheus:CatNivelQuat)
			oModelSB1:SetValue("SB1MASTER","B1_01CAT5"		,oProdutoProtheus:CatNivelCinc)
			oModelSB1:SetValue("SB1MASTER","B1_YFORLIN"		,oProdutoProtheus:ForaLinha)
			oModelSB1:SetValue("SB1MASTER","B1_01CODMA"		,oProdutoProtheus:CODMA)
			
			oModelSB1:SetValue("SB1MASTER","B1_YSTPR"		,AsString(oProdutoProtheus:StPr))
			oModelSB1:SetValue("SB1MASTER","B1_YSTSC"		,AsString(oProdutoProtheus:StSc))
			conout("######06! StPr " + VALTYPE(oProdutoProtheus:StPr))
			conout("######06! StSc " + VALTYPE(oProdutoProtheus:StSc))
			
			//oModelSB1:SetValue("SB1MASTER","B1_YSTPR"		,'2')			
			//oModelSB1:SetValue("SB1MASTER","B1_YSTSC"		,'2')
			oModelSB1:SetValue("SB1MASTER","B1_GARANT"		,'2')
			oModelSB1:SetValue("SB1MASTER","B1_YALTB2B"		,'N')	
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
				oCadCliente:Erro 	:=''

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
					oCadCliente:Codigo := ''
					oCadCliente:Status := aArrayAIA[1,1]
					oCadCliente:Erro := aArrayAIA[1,2]
					::aCadClientes:Itens :={}
					Aadd(::aCadClientes:Itens, oCadCliente)
				endif
			endif

		
		endif
	END TRANSACTION
	
Return .T.

static function saveSB4()
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


static function saveSB5(cCodSB1, oProdutoProtheus, oObjWS)
	Local oModelSB5	:= Nil
	oModelSB5 := FwLoadModel("MATA180")
	oModelSB5:SetOperation(MODEL_OPERATION_INSERT)
	oModelSB5:Activate()

	conout("###### Codigo " + cCodSB1)
	oModelSB5:SetValue("SB5MASTER","B5_COD"		,cCodSB1)
	oModelSB5:SetValue("SB5MASTER","B5_CEME"	,oProdutoProtheus:Descricao)
	oModelSB5:SetValue("SB5MASTER","B5_COMPR" 	,oProdutoProtheus:VlComprimento)
	oModelSB5:SetValue("SB5MASTER","B5_LARG" 	,oProdutoProtheus:VlLagM)
	oModelSB5:SetValue("SB5MASTER","B5_ALTURA" 	,oProdutoProtheus:VlAltura)

	If oModelSB5:VldData()
		oModelSB5:CommitData()
		conout("Registro INCLUIDO na SB5!")
	Else
		conout("Erro ao incluir SB1: "+varInfo('oModelSB5',oModelSB5:GetErrorMessage(), ,.F.))
		//::cCodigo := "ERRO"
		oModelSB5:DeActivate()
		oModelSB5:Destroy()
		oModelSB5 := NIL

		oObjWS:oCadCliente:Codigo := ''
		oObjWS:oCadCliente:Status :='ERRO'
		oObjWS:oCadCliente:Erro := ("Erro ao incluir SB1: "+varInfo('oModelSB5',oModelSB5:GetErrorMessage(), ,.F.))
		oObjWS:aCadClientes:Itens :={}
		Aadd(oObjWS:aCadClientes:Itens, oCadCliente)
		DisarmTransaction()
	EndIf

	oModelSB5:DeActivate()
	oModelSB5:Destroy()
	oModelSB5 := NIL
return


static function saveSZ1(oProdutoProtheus)
	conout("###### UFPR! " + oProdutoProtheus:UFPR)
	if oProdutoProtheus:UFPR <> ''
		dbSelectArea("SZ1")
		if recLock("SZ1", .T.)
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
			SZ1->(msUnlock())
		EndIf
	EndIf

	if oProdutoProtheus:UFSC <> ''
		dbSelectArea("SZ1")
		if recLock("SZ1", .T.)
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
			SZ1->(msUnlock())
		EndIf
	EndIf
return

static function saveDA0(oProdutoProtheus, oObjWS)
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
				DA1->DA1_PRCVEN := oProdutoProtheus:PRCVENA
				DA1->(msUnlock())
			else
			// cItem := soma1(fUltItem(oProdutoProtheus:CodTabPR, "DA1")) // Proximo item disponivel

				_cSelect := "SELECT MAX(DA1_ITEM) ZZ_MAXITE" + CRLF
				_cSelect += "  FROM " + retSqlName("DA1") + " (NOLOCK) " + CRLF
				_cSelect += " WHERE DA1_FILIAL = " + valToSql(xFilial("DA1")) + CRLF
				_cSelect += "   AND DA1_CODTAB = " + valToSql(oProdutoProtheus:CODVENA) + CRLF
				_cSelect += "   AND D_E_L_E_T_ = '' " + CRLF

				tcQuery _cSelect new alias "TABAUX"
				if !TABAUX->(EoF())
					cItem := TABAUX->ZZ_MAXITE
				endif
				TABAUX->(dbCloseArea())

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
				DA1->DA1_PRCVEN := oProdutoProtheus:PRCVENB
				DA1->(msUnlock())
			else
				//cItem := soma1(fUltItem(oProdutoProtheus:CodTabPR, "DA1")) // Proximo item disponivel

				_cSelect := "SELECT MAX(DA1_ITEM) ZZ_MAXITE" + CRLF
				_cSelect += "  FROM " + retSqlName("DA1") + " (NOLOCK) " + CRLF
				_cSelect += " WHERE DA1_FILIAL = " + valToSql(xFilial("DA1")) + CRLF
				_cSelect += "   AND DA1_CODTAB = " + valToSql(oProdutoProtheus:CODVENB) + CRLF
				_cSelect += "   AND D_E_L_E_T_ = '' " + CRLF

				tcQuery _cSelect new alias "TABAUX"
				if !TABAUX->(EoF())
					cItem := TABAUX->ZZ_MAXITE
				endif
				TABAUX->(dbCloseArea())

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
return aErroDA0

static function saveSA5(oProdutoProtheus, oObjWS)
	dbSelectArea("SA5")
	SA5->(dbSetOrder(1)) // A5_FILIAL+A5_FORNECE+A5_LOJA+A5_PRODUTO
	if SA5->(msSeek(xFilial("SA5") + SB1->B1_PROC +  SB1->B1_LOJPROC + SB1->B1_COD))
		if allTrim(SA5->A5_CODPRF) <> allTrim(SB1->B1_LOJPROC)
			recLock("SA5", .F.)
				SA5->A5_CODPRF :=  oProdutoProtheus:CODREF
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
				SA5->A5_CODPRF :=  oProdutoProtheus:CODREF
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

static function saveAIA(oProdutoProtheus)
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
			if !empty(oProdutoProtheus:CodTabPR) // Se o estado for informado no arquivo devera atualizar o preço do estado
				&("AIB->AIB_YPRC" + oProdutoProtheus:CodTabPR) := oProdutoProtheus:PRCVENA
			else
				AIB->AIB_PRCCOM := oProdutoProtheus:PRCVENA
			endif
			AIB->(msUnlock())
		else
			conout ( "@@@@@ 04 ")		
			recLock("AIB", .T.)
			cItem   := soma1(fUltItem(oProdutoProtheus:CodTabPR, "AIB"))
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
			/*if !empty(oProdutoProtheus:CodTabPR) // Se o estado for informado no arquivo devera atualizar o preço do estado
				conout ( "@@@@@ 06 ")
				&("AIB->AIB_YPRC" + oProdutoProtheus:CodTabPR) := oProdutoProtheus:PRCVENA
			else*/
				conout ( "@@@@@ 07 ")
				AIB->AIB_PRCCOM := oProdutoProtheus:PRCVENA
			//endif
			conout ( "@@@@@ 08 ")
			AIB->(msUnlock())
		endiF
	else // Tabela de preço de compra nao existe (Erro - Deve ser cadastrado previamente)
		conout ( "Tabela de preço de compra não encontrada. Tabela: ")
		Aadd(aArrayAIA,{'ERRO','Tabela de preço de compra não encontrada.'})
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
			//if !empty(oProdutoProtheus:CodTabSC) // Se o estado for informado no arquivo devera atualizar o preço do estado
				//&("AIB->AIB_YPRC" + oProdutoProtheus:CodTabSC) := oProdutoProtheus:PRCVENA
				AIB->AIB_YPRCSC := oProdutoProtheus:PRCVENA
			/*else
				AIB->AIB_PRCCOM := oProdutoProtheus:PRCVENA
			endif*/
			AIB->(msUnlock())
		else
			recLock("AIB", .T.)
			cItem   := soma1(fUltItem(oProdutoProtheus:CodTabSC, "AIB"))

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
				&("AIB->AIB_YPRC" + oProdutoProtheus:CodTabSC) := oProdutoProtheus:PRCVENA
			else
				AIB->AIB_PRCCOM := oProdutoProtheus:PRCVENA
			endif
			AIB->(msUnlock())
		endiF
	else // Tabela de preço de compra nao existe (Erro - Deve ser cadastrado previamente)
		conout ( "Tabela de preço de compra não encontrada. Tabela: ")		
		Aadd(aArrayAIA,{'ERRO','Tabela de preço de compra não encontrada.'})
	endif
return aArrayAIA


static function fUltItem(cTabela, cTabSX3)
    local cLastItem := "0000"

    default cTabSX3 := "DA1"

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
        cLastItem := TABAUX->ZZ_MAXITE
    endif
    TABAUX->(dbCloseArea())
return cLastItem
