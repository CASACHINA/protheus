#include 'protheus.ch'
#include 'topconn.ch'


user function MTA140MNU()

	aAdd( aRotina, { "Enviar para WMS","u_CCN140Env"	, 0 , 2, 0, nil } )

return


user function CCN140Env()
	Local _aArea := GetArea()
	IF ! u_CChWMSAtivo()
		Alert('Integração não ativada para esta filial ('+cFilAnt+')')

		RestArea(_aArea)
		return
	EndIF


	IF ! SF1->F1_TIPO $ 'NDB'
		Alert('Tipo de nota não pode ser enviada para WMS')

		RestArea(_aArea)
		return

	EndIF

	IF ! Empty(SF1->F1_STATUS)
		Alert('Esta pre-nota já foi classificada.')

		RestArea(_aArea)
		return
	EndIF

	IF ! PedMovEstoque()
		Alert('Nenhum item da Pré-Nota está ativo para integração com WMS')

		RestArea(_aArea)
		return
	EndIF

	IF ! Empty(SF1->F1_ENVWMS) .And. Aviso('Atenção','Esta pre-nota já foi enviada para o CyberLog por '+alltrim(SF1->F1_ENVWMS)+'. Deseja enviar novamente?',{'Enviar','Cancelar'},1) == 2
		RestArea(_aArea)
		Return
	EndIF


	//cria o log
	cChave := SF1->(F1_FILIAL+F1_DOC+F1_SERIE+F1_FORNECE+F1_LOJA+F1_TIPO)

	IF u_CChtoCyberLog('RECEBIMENTOS', cChave, IIF( Empty(SF1->F1_ENVWMS), 'I', 'A' ), cFilAnt , pedB2B(cChave))

		Reclock("SF1",.F.)
		SF1->F1_ENVWMS := cUserName + " em " + FormDate(Date()) + " as " + Time()
		SF1->( MsUnlock() )

		MSGInfo('Enviado com Sucesso para CyberLog.')

	EndIF
	RestArea(_aArea)
return
/*
user function SF1140I()

	Local lInclui := ParamIXB[1]
	Local lAltera := ParamIXB[2]

	IF u_CChWMSAtivo() .And. PedMovEstoque()

		IF lInclui
			//cria o log
			u_CChtoCyberLog('RECEBIMENTOS', SF1->(F1_FILIAL+F1_DOC+F1_SERIE+F1_FORNECE+F1_LOJA+F1_TIPO), 'I', cFilAnt)
		EndIF

		IF lAltera
			//cria o log
			u_CChtoCyberLog('RECEBIMENTOS', SF1->(F1_FILIAL+F1_DOC+F1_SERIE+F1_FORNECE+F1_LOJA+F1_TIPO), 'A', cFilAnt)
		EndIF

	EndIF

return
*/

user function MT140APV()

	Local _aArea := GetArea()

	IF ! INCLUI .And. ! ALTERA
		IF u_CChWMSAtivo() .And. PedMovEstoque()

			cChave := SF1->(F1_FILIAL+F1_DOC+F1_SERIE+F1_FORNECE+F1_LOJA+F1_TIPO)
			//cria o log
			u_CChtoCyberLog('RECEBIMENTOS',cChave , 'D', cFilAnt, pedB2B(cChave))

		EndIF
	EndIF

RestArea(_aArea)

return ParamIXB[1]




static function PedMovEstoque()
	Local _aArea := GetArea()
	Local lMov := .F.

	IF ! SF1->F1_TIPO $ "DB"
		SA2->( dbSetOrder(1) )
		SA2->( dbSeek( xFilial("SA2") + SF1->(F1_FORNECE+F1_LOJA) ) )

		IF SA2->A2_CYBERW != 'S'
			RestArea(_aArea)
			return lMov
		EndIF
	Else
		SA1->( dbSetOrder(1) )
		SA1->( dbSeek( xFilial("SA1") + SF1->(F1_FORNECE+F1_LOJA) ) )

		IF SA1->A1_CYBERW != 'S'
			RestArea(_aArea)
			return lMov
		EndIF
	EndIF

	SD1->( dbSetOrder(1) )
	SD1->( dbGoTop() )
	SD1->( dbSeek( SF1->(F1_FILIAL+F1_DOC+F1_SERIE+F1_FORNECE+F1_LOJA) ) )

	While ! SD1->( Eof() ) .And. SD1->(D1_FILIAL+D1_DOC+D1_SERIE+D1_FORNECE+D1_LOJA) == SF1->(F1_FILIAL+F1_DOC+F1_SERIE+F1_FORNECE+F1_LOJA)

		SB1->( dbSetOrder(1) )
		SB1->( dbSeek( xFilial("SB1") + SD1->D1_COD ) )

		IF SB1->B1_CYBERW == 'S'
			lMov := .T.
		EndIF

		SD1->( dbSkip() )
	EndDO

	RestArea(_aArea)
return lMov



//verifica se a nota é refente a um pedido B2B
Static Function pedB2B(cChave)
	Local _cQry := ""
	Local _lRet := "N"

	_cQry := " SELECT TOP 1 C7_B2B FROM "+ RetSqlName("SC7")
	_cQry += " WHERE C7_FILIAL ='"+SUBSTR(cChave,1,6)+"'"
	_cQry += " AND C7_NUM IN ("
	_cQry += " 				SELECT TOP 1 D1_PEDIDO FROM "+ RetSqlName("SD1")
	_cQry += " 				WHERE D1_FILIAL+D1_DOC+D1_SERIE+D1_FORNECE+D1_LOJA+D1_TIPO = '"+cChave+"'"
	_cQry += " 				AND  D1_PEDIDO <> ''"
	_cQry += " 				AND  D_E_L_E_T_ =  ''"
	_cQry += " 				)
	_cQry += " AND  D_E_L_E_T_ =  ''"

	Iif(SELECT("TRB2B") > 0, TRB2B->(DbCloseArea()), )

	TcQuery _cQry New Alias "TRB2B"

	if TRB2B->C7_B2B == "S"
		_lRet := "S"
	Endif

	TRB2B->(DbCloseArea())

Return _lRet

