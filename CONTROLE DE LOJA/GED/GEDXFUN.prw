#INCLUDE "rwmake.ch"
#INCLUDE "PROTHEUS.CH"
#INCLUDE "TBICONN.CH"
#INCLUDE "TOPCONN.CH"

User Function CXF0001(cAlias,nReg, nOpc)

	Local _aArea := GetArea()
	Local _cNumPc   := ''
	Private cAlDoc := cAlias
	Private nRegDoc := nReg


	//Busca Solicitação de Compras pela Cotação
	If cAlias == 'SC8'
		DbSelectArea("SC1")
		SC1->(DbSetOrder(1))
		If SC1->(DbSeek(xFilial("SC1")+SC8->C8_NUMSC+SC8->C8_ITEMSC))
			cAlDoc := "SC1"
			nRegDoc := SC1->(Recno())
		Else
			Alert("Solicitação de Compras Nro: "+SC8->C8_NUMSC+" - Item: "+SC8->C8_ITEMSC+" não Localizada!")
			Return .F.
		EndIf
	EndIf

	//Busca Solicitação de Compras pela Pedido de Compras
	If cAlias == 'SC7'

		DbSelectArea("SC1")
		SC1->(DbSetOrder(1))
		If SC1->(DbSeek(xFilial("SC1")+SC7->C7_NUMSC+SC7->C7_ITEMSC))
			cAlDoc := "SC1"
			nRegDoc := SC1->(Recno())
		Elseif !Empty(SC7->C7_MEDICAO )
			//CND_FILIAL+CND_CONTRA+CND_REVISA+CND_NUMERO+CND_NUMMED
			DBSelectArea('CND')
			DBSetorder(4)
			DBSeek(xFilial('CND')+SC7->C7_MEDICAO)
			cAlDoc := "CND"
			nRegDoc := CND->(Recno())
			//					Alert("Solicitação de Compras Nro: "+SC7->C7_NUMSC+" - Item: "+SC7->C7_ITEMSC+" não Localizada!")
			//					Return .F.
		EndIf
	EndIf

	//Busca Solicitação de Compras pela NF Entrada
	If cAlias == 'SF1'

		//Busca Item de NF de Entrada
		DbSelectArea("SD1")
		SD1->(DbSetOrder(1))
		If SD1->(DbSeek(xFilial("SD1")+SF1->F1_DOC+SF1->F1_SERIE+SF1->F1_FORNECE+SF1->F1_LOJA))

			//Busca Pedido de Compra
			DbSelectArea("SC7")
			SC7->(DbSetOrder(1))
			If SC7->(DbSeek(xFilial("SC7")+SD1->D1_PEDIDO+SD1->D1_ITEMPC))

				if !Empty(SC7->C7_MEDICAO )
					//CND_FILIAL+CND_CONTRA+CND_REVISA+CND_NUMERO+CND_NUMMED
					DBSelectArea('CND')
					DBSetorder(4)
					DBSeek(xFilial('CND')+SC7->C7_MEDICAO)
					cAlDoc := "CND"
					nRegDoc := CND->(Recno())
				Else

					//Busca Colicitação de Compras
					DbSelectArea("SC1")
					SC1->(DbSetOrder(1))
					If SC1->(DbSeek(xFilial("SC1")+SC7->C7_NUMSC+SC7->C7_ITEMSC))
						cAlDoc := "SC1"
						nRegDoc := SC1->(Recno())
					Else
						//Se não encontrar Solicitação de Compras, busca posiciona pedido de compras
						cAlDoc := "SC7"
						nRegDoc := SC7->(Recno())
						//Alert("Solicitação de Compras Nro: "+SC7->C7_NUMSC+" - Item: "+SC7->C7_ITEMSC+" não Localizada!")
						//Return .F.
					EndIf
				EndIF
			EndIf

		EndIf

	EndIf

	If cAlias == "SE2"

		//Busca Item de NF de Entrada
		DbSelectArea("SD1")
		SD1->(DbSetOrder(1))
		//				If SD1->(DbSeek(xFilial("SD1")+SE2->E2_NUM+SE2->E2_PREFIXO))
		//D1_FILIAL+D1_DOC+D1_SERIE+D1_FORNECE+D1_LOJA+D1_COD+D1_ITEM
		If SD1->(DbSeek(xFilial("SD1")+SE2->E2_NUM+SE2->E2_PREFIXO+SE2->E2_FORNECE+SE2->E2_LOJA))
			//Busca Pedido de Compra
			DbSelectArea("SC7")
			SC7->(DbSetOrder(1))
			If SC7->(DbSeek(xFilial("SC7")+SD1->D1_PEDIDO+SD1->D1_ITEMPC))

				if !Empty(SC7->C7_MEDICAO )
					//CND_FILIAL+CND_CONTRA+CND_REVISA+CND_NUMERO+CND_NUMMED
					DBSelectArea('CND')
					DBSetorder(4)
					DBSeek(xFilial('CND')+SC7->C7_MEDICAO)
					cAlDoc := "CND"
					nRegDoc := CND->(Recno())
				Else
					//Busca Colicitação de Compras
					DbSelectArea("SC1")
					SC1->(DbSetOrder(1))
					If SC1->(DbSeek(xFilial("SC1")+SC7->C7_NUMSC+SC7->C7_ITEMSC))
						cAlDoc := "SC1"
						nRegDoc := SC1->(Recno())
					Else
						cAlDoc := "SC7"
						nRegDoc := SC7->(Recno())
					EndIf
				EndIF
			EndIf

		EndIf

	EndIf

	cAlias := cAlDoc
	nReg   := nRegDoc

	//MTVLDACE - Valida acesso à rotina de conhecimento ( [ ] ) --> lRet
	//MTCONHEC - Ponto de entrada para bloquear o botão "Banco Conhecimento para alguns usuários - lRet

	//MsDocument(cAlDoc,nRegDoc, 4)

	RestArea(_aArea)

Return( Nil )

/*
+-----------------------------------------------------------------------------+
! Função     ! MSDOCVIS     ! Autor ! Alexandre Effting  ! Data !  18/03/2013 !
+------------+--------------+-------+--------------------+------+-------------+
! Parâmetros ! lRet -> .T. Somente visualiza e inclui, .F. sem bloqueio       !
+------------+----------------------------------------------------------------+
! Descricao  ! Bloqueia manipulação de dados dependendo da função da usuario. !
!            ! Se Título CP estiver baixado, não permite exclusão.            !
+------------+----------------------------------------------------------------+
*/

User Function MSDOCVIS()

	Local lRet := .F.
	Local _aArea := GetArea()
	// Local cMsg := "Processo de Compras Concluído!"
	/*
	//Busca Título do Contas a Paagar Pela Solicitação de Compras
	If ( FunName() == "MATA110" )

		If Empty(SC1->C1_PEDIDO)

			lRet := .F.

		ElseIf !ExisteSaldoPedidoOuTitulo(SC1->C1_PEDIDO)

			lRet := .T.

		EndIf

	EndIf

	//Busca Título do Contas a Pagar Pela Solicitação de Compras
	If ( FunName() == "MATA150" ) .OR. ( FunName() == "MATA130" )

		If FunName() == "MATA150"

			If Empty(SC8->C8_NUMPED)

				lRet := .F.

			ElseIf SC8->C8_NUMPED == "XXXXXX"

				lRet := .F.

			ElseIf !ExisteSaldoPedidoOuTitulo(SC8->C8_NUMPED)

				lRet := .T.

			EndIf

		Else

			If Empty(SC1->C1_PEDIDO)

				lRet := .F.

			ElseIf !ExisteSaldoPedidoOuTitulo(SC1->C1_PEDIDO)

				lRet := .T.

			EndIf

		EndIf

	EndIf

	//Busca Título do Contas a Pagar Pela Solicitação de Compras
	If ( FunName() == "MATA121" )

		If !ExisteSaldoPedidoOuTitulo(SC7->C7_NUM)

			lRet := .T.

		EndIf

	EndIf

	//Busca Título do Contas a Pagar Pela Solicitação de Compras
	If ( FunName() $'MATA103|U_GATI001' )

		If !ExisteSaldoPedidoOuTitulo(, SF1->F1_DOC, SF1->F1_SERIE, SF1->F1_FORNECE, SF1->F1_LOJA)

			lRet := .T.

		EndIf

	EndIf

	//Busca Título do Contas a Pagar Pela Solicitação de Compras
	If ( FunName() == "FINA050" ) .OR. ( FunName() == "FINA750" )

		If !ExisteSaldoPedidoOuTitulo(, SE2->E2_NUM, SE2->E2_PREFIXO, SE2->E2_FORNECE, SE2->E2_LOJA)

			lRet := .F.

		EndIf

	EndIf

	If IsInCallStack("CNTA121")

		DBSelectArea("CNE")
		CNE->(DBSetOrder(5)) // CNE_FILIAL, CNE_CONTRA, CNE_REVISA, CNE_NUMMED, R_E_C_N_O_, D_E_L_E_T_

		If CNE->(DBSeek(xFilial("CNE") + CND->( CND_CONTRA + CND_REVISA + CND_NUMMED )))

			If !Empty(CNE->CNE_PEDIDO) .And. !ExisteSaldoPedidoOuTitulo(CNE->CNE_PEDIDO)

				lRet := .T.

			EndIf

		Else

			lRet := .F.

		EndIf

	EndIf

	//Só é permitido Manipulação de Documentos com Título Baixado se Usuário estiver contido em parâmetro
	If lRet
		//		If UsrRetName(__cUserID) $ SuperGetMV("MV_TCPDOCU",,"Administrador")
		If cUserName $ SuperGetMV("MV_TCPDOCU",,"Administrador")
			lRet := .F.
		EndIf
	EndIf

	//Apresenta Mensagem ao usuário quando não permitir deleção de Documentos
	If lRet
		Alert(cMsg + CRLF + CRLF + " Não é permitido a inclusão ou exclusão de documentos." + CRLF + "Usuário não possui permissão.")
	EndIf
	*/
	RestArea(_aArea)
	
Return(lRet)

Static Function ExisteSaldoPedidoOuTitulo(cNumPC, cDoc, cSerie, cFornece, cLoja)

	Local cAlias1	:= GetNextAlias()
	Local lRet		:= .T.
	Local cSql      := ""

	Default cNumPC		:= ""
	Default cDoc		:= ""
	Default cSerie		:= ""
	Default cFornece	:= ""
	Default cLoja		:= ""

	cSql := " SELECT ISNULL(SUM(C7_QUANT - C7_QUJE), 0) SALDO_SC7, ISNULL(SUM(E2_SALDO), 0) SALDO_SE2 "
	cSql += " FROM " + RetSqlName("SC7") + " SC7 "

	cSql += If(Empty(cNumPC), "INNER", "LEFT") + " JOIN " + RetSqlName("SD1") + " SD1 ON "
	cSql += " ( "
	cSql += "	SD1.D1_FILIAL 		= SC7.C7_FILIAL "
	cSql += " 	AND SD1.D1_PEDIDO	= SC7.C7_NUM "
	cSql += " 	AND SD1.D1_ITEMPC	= SC7.C7_ITEM "
	cSql += " 	AND SD1.D_E_L_E_T_	= '' "
	cSql += " ) "

	cSql += " LEFT JOIN " + RetSqlName("SE2") + " SE2 ON "
	cSql += " ( "
	cSql += "	SE2.E2_FILIAL 		= SD1.D1_FILIAL "
	cSql += " 	AND SE2.E2_NUM 		= SD1.D1_DOC "
	cSql += " 	AND SE2.E2_PREFIXO 	= SD1.D1_SERIE "
	cSql += " 	AND SE2.D_E_L_E_T_	= '' "
	cSql += " ) "

	cSql += " WHERE C7_FILIAL		= " + ValToSql(xFilial("SC7"))

	If Empty(cNumPC)

		cSql += "AND D1_DOC		 	= " + ValToSql(cDoc)
		cSql += "AND D1_SERIE	 	= " + ValToSql(cSerie)
		cSql += "AND D1_FORNECE 	= " + ValToSql(cFornece)
		cSql += "AND D1_LOJA	 	= " + ValToSql(cLoja)

	Else

		cSql += " AND C7_NUM		= " + ValToSql(cNumPC)

	EndIf

	//cSql += " AND C7_ITEM			= " + ValToSql(cItemPC)
	//cSql += " AND C7_QUANT - C7_QUJE	> 0 "

	cSql += " AND C7_RESIDUO		= '' "
	cSql += " AND SC7.D_E_L_E_T_	= '' "

	TCQUERY cSQL NEW ALIAS (cAlias1)

	lRet := ( (cAlias1)->SALDO_SC7 > 0 .Or. (cAlias1)->SALDO_SE2 > 0 )

	(cAlias1)->(DbCloseArea())

Return(lRet)

/*
+-----------------------------------------------------------------------------+
! Função     ! CXF0002      ! Autor ! Alexandre Effting  ! Data !  21/03/2013 !
+------------+--------------+-------+--------------------+------+-------------+
! Parâmetros !                                                                !
+------------+----------------------------------------------------------------+
! Descricao  ! Efetua o filtro de Objetos na Consulta Padrão (ACB)            !
+------------+----------------------------------------------------------------+
*/

User Function CXF0002(cObj)
	Local lRet := .T.
	Local _aArea := GetArea()

	If FunName() $ "MATA110|FINA050|MATA103|MATA121|MATA150|MATA130|FINA750|U_GATI001"

		if Select ( "TRB2" ) <> 0
			dbSelectArea("TRB2")
			TRB2->(dbCloseArea())
		EndIf

		//Busca se Objeto já está em uso em outra Entidade
		cQuery := " SELECT COUNT(AC9.AC9_CODOBJ) AS QTD "
		cQuery += "   FROM "+RetSqlName("AC9")+" AC9 "
		cQuery += "  WHERE AC9.AC9_CODOBJ = '"+cObj+"' "
		cQuery += "    AND AC9.D_E_L_E_T_ <> '*' "

		TCQuery cQuery NEW ALIAS "TRB2"

		DbSelectArea("TRB2")
		TRB2->(DbGotop())

		If TRB2->QTD > 0
			lRet := .F.
		EndIF

	EndIf

	RestArea(_aArea)
Return lRet

user function criaCon(_cEmp,_cFil)

	RpcSetType(3)

	If Type('cEmpAnt') == 'U'
		RpcClearEnv()
		PREPARE ENVIRONMENT EMPRESA _cEmp FILIAL _cFil MODULO "SIGAMDI" TABLES "SCR"
	ElseIf !(_cEmp == cEmpAnt)
		RpcClearEnv()
		PREPARE ENVIRONMENT EMPRESA _cEmp FILIAL _cFil MODULO "SIGAMDI" TABLES "SCR"
	ElseIf !(_cFil == cFilAnt)
		cFilAnt := _cFil
	EndIf
return
