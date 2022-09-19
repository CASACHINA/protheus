#include 'protheus.ch'


user function MEst410(aParam)

	aParam := {'01','010104'}

	Conout("[" + DtoC(Date()) + " - "  + Time() + "] - [MEst410] - Schedule - Iniciado")


	IF aParam # nil

		RPCSetType( 3 )
		RPCSetEnv(aParam[1],aParam[2],,,"FAT")

		MEst41Exec()

		RPCClearEnv()

	Else
		FwMsgRun(, {|| MEst41Exec() }, "Aguarde...", "Executando importação do WMS de conferencia de saida.")
	EndIF

	Conout("[" + DtoC(Date()) + " - "  + Time() + "] - [MEst410] - Schedule - Finalizado")

return



static function MEst41Exec()


	Local aPedidos := GetPedidos()
	Local nItem
	Local cFilAux	:= cFilAnt

	For nItem := 1 to len(aPedidos)

		SC5->( dbSetOrder(1) )
		SC5->( dbSeek( aPedidos[nItem][1] ) )

		IF SC5->( Found() )

			cFilAnt := SubStr(aPedidos[nItem][1],1,TamSx3("F1_FILIAL")[01])

			IF ! ( ! Empty(SC5->C5_NOTA) .Or. SC5->C5_LIBEROK == 'E' .And. Empty(SC5->C5_BLQ) )
				//grava a conferencia
				Grava( aPedidos[nItem][1], aPedidos[nItem][2])
			Else
				u_CChWMSError('SAIDAS', aPedidos[nItem][1], 'Pedido de venda encerrado.')
			EndIF
		Else
			u_CChWMSError('SAIDAS', aPedidos[nItem][1], 'Chave não encontrada')
		EndIF

	Next nItem

	cFilAnt := cFilAux

return


static function GetPedidos()

	Local cAlias := GetNextAlias()

	Local aPedidos := {}

	BeginSQL Alias cAlias
		%noparser%

		select
			COD_CYBERLOG_SAIDA as CHAVESC5,
			CODIGO_PRODUTO as PRODUTO,
			QUANTIDADE as QUANTIDADE,
			LOTE as LOTE,
			VALIDADE as VALIDADE,
			FABRICACAO as FABRICACAO

		from TOTVS_CYBERLOG_SAIDA CONF

		where
			CONF.PROCESSAMENTO is null

		and not exists (
			select 1
			from TOTVS_CYBERLOG_ERROS ERRO
			where
			    ERRO.ORIGEM = 'SAIDAS'
			and ERRO.CHAVE = CONF.COD_CYBERLOG_SAIDA
			and ERRO.PROCESSAMENTO is null
		)

		order by
			COD_CYBERLOG_SAIDA

	EndSQL

	While ! (cAlias)->( Eof() )

		IF aScan( aPedidos, {|nota| nota[1] == (cAlias)->CHAVESC5 } ) == 0
			aAdd(aPedidos, { (cAlias)->CHAVESC5, {}})
		EndIF

		aAdd( aPedidos[len(aPedidos)][2], {;
			(cAlias)->PRODUTO, ;
			(cAlias)->QUANTIDADE, ;
			(cAlias)->LOTE, ;
			(cAlias)->VALIDADE, ;
			(cAlias)->FABRICACAO, ;
		}  )


		(cAlias)->(dbSkip())
	EndDO

return aPedidos



static function Grava(cChave, aConf)

	Local lConferido := .T.
	Local nItem
	Local cErro := ''

	SC6->( dbSetOrder(1) )
	SC6->( dbSeek( SC5->(C5_FILIAL+C5_NUM) ) )

	Begin Transaction

	While ! SC6->( Eof() ) .And. SC6->(C6_FILIAL+C6_NUM) == SC5->(C5_FILIAL+C5_NUM)

		nItem := aScan(aConf, {|item| alltrim(item[1]) == alltrim(SC6->C6_PRODUTO) })

		IF nItem > 0

			Reclock("SC6",.F.)
			SC6->C6_QTDCONF := aConf[nItem][2]
			SC6->( MsUnlock() )

			aConf[nItem][2] := 0

			SC9->( dbSetOrder(1) )
			SC9->( dbSeek( xFilial("SC9") + SC6->(C6_NUM+C6_ITEM) ) )

			While ! SC9->( Eof() ) .And. SC9->(C9_FILIAL+C9_PEDIDO+C9_ITEM) == SC6->(C6_FILIAL+C6_NUM+C6_ITEM)

				a460Estorna()

				SC9->(dbSkip())
			EndDO

			//libera o item do pedido
			MaLibDoFat( SC6->( RecNo() ),SC6->C6_QTDCONF,.F.,.F.,.T.,.T.,.T.,.F.,NIL,NIL,NIL,NIL,NIL,NIL)

		EndIF

		SC6->(dbSkip())
	EndDO

	u_CCnSaida(cChave)

	For nItem := 1 to len(aConf)
		IF aConf[nItem][2] > 0
			IF ! Empty(cErro)
				cErro += ", "
			EndIF
			cErro += 'Produto "' + alltrim(aConf[nItem][1]) + '" não existe no recebimento'
		EndIF
	Next nItem

	IF ! Empty(cErro)
		DisarmTransaction()
	Else
		SC6->(MaLiberOk({SC5->C5_NUM},.F.))
	EndIF

	End Transaction

	IF ! Empty(cErro)
		u_CChWMSError('SAIDAS', cChave, cErro)
	EndIF

return