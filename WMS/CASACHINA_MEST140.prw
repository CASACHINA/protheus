#include 'protheus.ch'


user function MEst140(aParam)

	aParam := {'01','010104'}

	Conout("[" + DtoC(Date()) + " - "  + Time() + "] - [MEst140] - Schedule - Iniciado")

	IF aParam # nil

		RPCSetType( 3 )
		RPCSetEnv(aParam[1],aParam[2],,,"COM")

		MEst14Exec()

		RPCClearEnv()

	Else
		FwMsgRun(, {|| MEst14Exec() }, "Aguarde...", "Executando importação do WMS de conferencia de recebimento.")
	EndIF

	Conout("[" + DtoC(Date()) + " - "  + Time() + "] - [MEst140] - Schedule - Finalizado")

return



static function MEst14Exec()


	Local aNotas 	:= GetNotas()
	Local nItem
	Local cFilAux	:= cFilAnt
	
	For nItem := 1 to len(aNotas)

		SF1->( dbSetOrder(1) )
		SF1->( dbSeek( aNotas[nItem][1] ) )

		IF SF1->( Found() )
		
			cFilAnt := SubStr(aNotas[nItem][1],1,TamSx3("F1_FILIAL")[01])
		
			IF Empty(SF1->F1_STATUS)
				//grava a conferencia
				Grava( aNotas[nItem][1], aNotas[nItem][2])
			Else
				u_CChWMSError('RECEBIMENTOS', aNotas[nItem][1], 'Documento de entrada Classificado')
			EndIF
			
		Else
			u_CChWMSError('RECEBIMENTOS', aNotas[nItem][1], 'Chave não encontrada')
		EndIF

	Next nItem

	cFilAnt := cFilAux

return


static function GetNotas()

	Local cAlias := GetNextAlias()
	Local aNotas := {}

	BeginSQL Alias cAlias
		%noparser%

		select
			COD_CYBERLOG_RECEBIMENTO as CHAVESF1,
			CODIGO_PRODUTO as PRODUTO,
			QUANTIDADE as QUANTIDADE,
			LOTE as LOTE,
			VALIDADE as VALIDADE,
			FABRICACAO as FABRICACAO

		from TOTVS_CYBERLOG_RECEBIMENTO CONF

		where
			CONF.PROCESSAMENTO is null

		and not exists (
			select 1
			from TOTVS_CYBERLOG_ERROS ERRO
			where
			    ERRO.ORIGEM = 'RECEBIMENTOS'
			and ERRO.CHAVE = CONF.COD_CYBERLOG_RECEBIMENTO
			and ERRO.PROCESSAMENTO is null
		)

		order by
			COD_CYBERLOG_RECEBIMENTO

	EndSQL

	While ! (cAlias)->( Eof() )

		IF aScan( aNotas, {|nota| nota[1] == (cAlias)->CHAVESF1 } ) == 0
			aAdd(aNotas, { (cAlias)->CHAVESF1, {}})
		EndIF

		aAdd( aNotas[len(aNotas)][2], {;
			(cAlias)->PRODUTO, ;
			(cAlias)->QUANTIDADE, ;
			(cAlias)->LOTE, ;
			(cAlias)->VALIDADE, ;
			(cAlias)->FABRICACAO, ;
		}  )


		(cAlias)->(dbSkip())
	EndDO

return aNotas


static function Grava(cChave, aConf)

	Local lConferido := .T.
	Local nItem
	Local cErro := ''

	SD1->( dbSetOrder(1) )
	SD1->( dbSeek( SF1->(F1_FILIAL+F1_DOC+F1_SERIE+F1_FORNECE+F1_LOJA) ) )

	Begin Transaction

	While ! SD1->( Eof() ) .And. SD1->(D1_FILIAL+D1_DOC+D1_SERIE+D1_FORNECE+D1_LOJA) == SF1->(F1_FILIAL+F1_DOC+F1_SERIE+F1_FORNECE+F1_LOJA)

		nItem := aScan(aConf, {|item| alltrim(item[1]) == alltrim(SD1->D1_COD) })

		IF nItem > 0

			Reclock("SD1",.F.)
			SD1->D1_QTDCONF := aConf[nItem][2]
			SD1->( MsUnlock() )

			aConf[nItem][2] := 0
		EndIF

		IF lConferido
			IF SD1->D1_QTDCONF != SD1->D1_QUANT
				lConferido := .F.
			EndIF
		EndIF

		SD1->(dbSkip())
	EndDO

	Reclock("SF1",.F.)
	SF1->F1_STATCON := IIF(lConferido, '1' , '2')
	SF1->F1_QTDCONF := 1
	SF1->( MsUnlock() )

	u_CCnRecebimento(cChave)

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
	EndIF

	End Transaction

	IF ! Empty(cErro)
		u_CChWMSError('RECEBIMENTOS', cChave, cErro)
	EndIF

return