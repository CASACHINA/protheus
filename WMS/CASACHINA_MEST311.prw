#include 'protheus.ch'


user function MEst311(aParam)

	aParam := {'01','010104'}

	//conout("[" + DtoC(Date()) + " - "  + Time() + "] - [MEst311] - Schedule - Iniciado")

	IF aParam # nil

		RPCSetType( 3 )
		RPCSetEnv(aParam[1],aParam[2],,,"COM")

		MEst31Exec()

		RPCClearEnv()

	Else
		FwMsgRun(, {|| MEst31Exec() }, "Aguarde...", "Executando importação do WMS de conferencia de Transferencia.")
	EndIF

	//conout("[" + DtoC(Date()) + " - "  + Time() + "] - [MEst311] - Schedule - Finalizado")

return



static function MEst31Exec()


	Local aTransfs	:= GetTransfs()
	Local nItem
	Local cFilAux	:= cFilAnt

	For nItem := 1 to len(aTransfs)

		NNS->( dbSetOrder(1) )
		NNS->( dbSeek( aTransfs[nItem][1] ) )

		IF NNS->( Found() )

			cFilAnt := SubStr(aTransfs[nItem][1],1,TamSx3("F1_FILIAL")[01])

			IF NNS->NNS_STATUS != '2'
				//grava a conferencia
				Grava( aTransfs[nItem][1], aTransfs[nItem][2])
			Else
				u_CChWMSError('TRANSFERENCIA', aTransfs[nItem][1], 'Solicitação de transferencia Finalizada')
			EndIF
		Else
			u_CChWMSError('TRANSFERENCIA', aTransfs[nItem][1], 'Chave não encontrada')
		EndIF

	Next nItem

	cFilAnt := cFilAux

return


static function GetTransfs()

	Local cAlias := GetNextAlias()

	Local aTransfs := {}

	BeginSQL Alias cAlias
		%noparser%

		select
			COD_CYBERLOG_TRANSFERENCIA as CHAVENNS,
			CODIGO_PRODUTO as PRODUTO,
			QUANTIDADE as QUANTIDADE,
			LOTE as LOTE,
			VALIDADE as VALIDADE,
			FABRICACAO as FABRICACAO

		from TOTVS_CYBERLOG_TRANSFERENCIA CONF

		where
			CONF.PROCESSAMENTO is null

		and not exists (
			select 1
			from TOTVS_CYBERLOG_ERROS ERRO
			where
			    ERRO.ORIGEM = 'TRANSFERENCIA'
			and ERRO.CHAVE = CONF.COD_CYBERLOG_TRANSFERENCIA
			and ERRO.PROCESSAMENTO is null
		)

		order by
			COD_CYBERLOG_TRANSFERENCIA

	EndSQL

	While ! (cAlias)->( Eof() )

		IF aScan( aTransfs, {|nota| nota[1] == (cAlias)->CHAVENNS } ) == 0
			aAdd(aTransfs, { (cAlias)->CHAVENNS, {}})
		EndIF

		aAdd( aTransfs[len(aTransfs)][2], {;
			(cAlias)->PRODUTO, ;
			(cAlias)->QUANTIDADE, ;
			(cAlias)->LOTE, ;
			(cAlias)->VALIDADE, ;
			(cAlias)->FABRICACAO, ;
		}  )


		(cAlias)->(dbSkip())
	EndDO

return aTransfs


static function Grava(cChave, aConf)

	Local nItem
	Local cErro := ''

	NNT->( dbSetOrder(1) )
	NNT->( dbSeek( NNS->(NNS_FILIAL+NNS_COD) ) )

	Begin Transaction

	While ! NNT->( Eof() ) .And. NNT->(NNT_FILIAL+NNT_COD) == NNS->(NNS_FILIAL+NNS_COD)

		nItem := aScan(aConf, {|item| alltrim(item[1]) == alltrim(NNT->NNT_PROD) })

		IF nItem > 0

			Reclock("NNT",.F.)
			NNT->NNT_QTDWMS := aConf[nItem][2]
			NNT->( MsUnlock() )

			//zero a quantidade conferida
			aConf[nItem][2] := 0

		EndIF

		NNT->(dbSkip())
	EndDO

	Reclock("NNS",.F.)
	NNS->NNS_CYBERS := "R"
	NNS->( MsUnlock() )

	u_CCnTransferencia(cChave)

	For nItem := 1 to len(aConf)
		IF aConf[nItem][2] > 0
			IF ! Empty(cErro)
				cErro += ", "
			EndIF
			cErro += 'Produto ' + aConf[nItem][1] + ' não existe na solicitação'
		EndIF
	Next nItem

	IF ! Empty(cErro)
		DisarmTransaction()
	EndIF

	End Transaction

	IF ! Empty(cErro)
		u_CChWMSError('TRANSFERENCIA', cChave, cErro)
	EndIF

return
