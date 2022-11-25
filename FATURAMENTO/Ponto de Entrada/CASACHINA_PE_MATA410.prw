#include 'protheus.ch'
#include 'common.ch'

static lWmsExclui

user function MA410MNU()

	Local aArea_	:= GetArea()
	
	aAdd(aRotina, {"Enviar para WMS", "u_CCN410Env", 0, 2, 0, nil})
	aAdd(aRotina, {"Rastreio", "u_EC0008", 0, 2, 0, nil})

	TCyberLogIntegracao():AddMenu(.T.)
	
	RestArea(aArea_)

return

user function CCN410Env()
	Local _aArea := GetArea()

	IF ! u_CChWMSAtivo()
		Alert('Integração não ativada para esta filial ('+cFilAnt+')')

		RestArea(_aArea)
		return
	EndIF


	IF ! SC5->C5_TIPO $ 'NDB'
		Alert('Tipo de pedido não pode ser enviada para WMS')

		RestArea(_aArea)
		return
	EndIF

	IF ( ! Empty(SC5->C5_NOTA) .Or. SC5->C5_LIBEROK == 'E' .And. Empty(SC5->C5_BLQ) )
		Alert('Este pedido já esta encerrado.')

		RestArea(_aArea)
		return
	EndIF

	IF ! PedMovEstoque()
		Alert('Nenhum item do pedido está ativo para integração com WMS')

		RestArea(_aArea)
		return
	EndIF

	IF SC5->C5_CYBERW == 'S' .And. Aviso('Atenção','Este pedido já foi enviado para o CyberLog por '+alltrim(SF1->F1_ENVWMS)+'. Deseja enviar novamente?',{'Enviar','Cancelar'},1) == 2
		RestArea(_aArea)
		Return
	EndIF

	//cria o log
	IF u_CChtoCyberLog('PEDIDOS', SC5->(C5_FILIAL+C5_NUM), 'I', cFilAnt)

		Reclock("SC5",.F.)
			SC5->C5_CYBERW := 'S'
		SC5->( MsUnlock() )

		MSGInfo('Enviado com Sucesso para CyberLog.')

	EndIF
	RestArea(_aArea)
return

user function M410AGRV()
	Local _aArea := GetArea()

	//antes da gravação da alteração
	IF IsInCallStack('A410Altera') .And. ! IsInCallStack('A311Efetiv')
		//verifica se antes de alterar, estava apto pra enviar
		IF u_CChWMSAtivo() .And. SC5->C5_CYBERW == 'S' .And. PedMovEstoque()
			lWmsExclui := .T.
		EndIF
	EndIF
	RestArea(_aArea)
return

/*/{Protheus.doc} M410STTS
O ponto de entrada M410STTS é executado após o o commit do pedido de venda
@author Mario Faria
@since 07/06/2017
/*/
user function M410STTS()

	Local _aArea := GetArea()
	Local oCyberLog := TCyberLogIntegracao():New()

	If !IsInCallStack('A311Efetiv') .And. SC5->C5_CYBERW == 'S'

		oCyberLog:SendPedido(IsInCallStack('A410Inclui'), IsInCallStack('A410Copia'), IsInCallStack('A410Altera'), IsInCallStack('A410Deleta'))

	EndIf

	IF u_CChWMSAtivo() .And. !IsInCallStack('A311Efetiv')

		IF SC5->C5_CYBERW == 'S' .And. PedMovEstoque()

			do case
				case IsInCallStack('A410Inclui') .Or. IsInCallStack('A410Copia')
					//cria o log
					u_CChtoCyberLog('PEDIDOS', SC5->(C5_FILIAL+C5_NUM), 'I', cFilAnt)

				case IsInCallStack('A410Altera')
					//cria o log
					u_CChtoCyberLog('PEDIDOS', SC5->(C5_FILIAL+C5_NUM), 'A', cFilAnt)

				case IsInCallStack('A410Deleta')
					//cria o log
					u_CChtoCyberLog('PEDIDOS', SC5->(C5_FILIAL+C5_NUM), 'D', cFilAnt)
			endcase
		Else
			IF IsInCallStack('A410Altera') .And. ! ISNIL(lWmsExclui) .And. lWmsExclui
				//cria o log
				u_CChtoCyberLog('PEDIDOS', SC5->(C5_FILIAL+C5_NUM), 'D', cFilAnt)
			EndIF
		EndIF

		lWmsExclui := nil
	EndIF

	RestArea(_aArea)
return

/*/{Protheus.doc} PedMovEstoque
...
@author Mario Faria
@since 07/06/2017
/*/
static function PedMovEstoque()
	Local _aArea := GetArea()

	Local lMov := FALSE

	IF SC5->C5_TIPO $ "DB"
		SA2->( dbSetOrder(1) )
		SA2->( dbSeek( xFilial("SA2") + SC5->(C5_CLIENTE+C5_LOJACLI) ) )

		IF SA2->A2_CYBERW != 'S'
			return lMov
		EndIF
	Else
		SA1->( dbSetOrder(1) )
		SA1->( dbSeek( xFilial("SA1") + SC5->(C5_CLIENTE+C5_LOJACLI) ) )

		IF SA1->A1_CYBERW != 'S'
			return lMov
		EndIF
	EndIF

	SC6->( dbSetOrder(1) )
	SC6->( dbGoTop() )
	SC6->( dbSeek( xFilial("SC6") + SC5->C5_NUM ) )

	While ! SC6->( Eof() ) .And. SC6->(C6_FILIAL+C6_NUM) == SC5->(C5_FILIAL+C5_NUM)

		SB1->( dbSetOrder(1) )
		SB1->( dbSeek( xFilial("SB1") + SC6->C6_PRODUTO ) )

		IF SB1->B1_CYBERW == 'S'

			SF4->( dbSetOrder(1) )
			SF4->( dbSeek( xFilial("SF4") + SC6->C6_TES ) )

			IF SF4->F4_ESTOQUE == 'S'
				lMov := TRUE
			EndIF

		EndIF

		SC6->( dbSkip() )
	EndDO
	RestArea(_aArea)
return lMov

/*/{Protheus.doc} MT410CPY
O ponto de entrada MT410CPY é executado após o preenchimento do acols e das variaveis da enchoice,
antes da apresentação da tela, permitindo alteração do acols e variaveis da enchoice.
@author Mario Faria
@since 07/06/2017
@see http://tdn.totvs.com/pages/releaseview.action?pageId=6784349
/*/
User Function MT410CPY()
	Local _aArea := GetArea()
	Local aArea := GetArea()

	M->C5_CYBERW := "N"
	RestArea(aArea)
	RestArea(_aArea)
Return
