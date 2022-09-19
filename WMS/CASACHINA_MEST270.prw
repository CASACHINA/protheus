#include 'protheus.ch'

#include 'common.ch'

user function MEst270(aParam)

	aParam := {'01','010104'}

	Conout("[" + DtoC(Date()) + " - "  + Time() + "] - [MEst270] - Schedule - Iniciado")

	IF aParam # nil

		RPCSetType( 3 )
		RPCSetEnv(aParam[1],aParam[2],,,"EST")

		MEst27Exec()

		RPCClearEnv()

	Else
		FwMsgRun(, {|| MEst27Exec() }, "Aguarde...", "Executando importação do WMS de inventário de estoque.")
	EndIF

	Conout("[" + DtoC(Date()) + " - "  + Time() + "] - [MEst270] - Schedule - Finalizado")

return



static function MEst27Exec()


	Local aInventario := GetInvs()
	Local nItem


	For nItem := 1 to len(aInventario)

		//grava a conferencia
		Grava( aInventario[nItem][1], aInventario[nItem][2])

	Next nItem


return


static function GetInvs()

	Local cAlias := GetNextAlias()

	Local aInventario := {}

	BeginSQL Alias cAlias
		%noparser%

		//column DATAINV as date

		select
			DATA_INVENTARIO as DATAINV,
			CODIGO_PRODUTO as PRODUTO,
			LOCAL_ESTOQUE as LOCAL,
			QUANTIDADE as QUANTIDADE,
			LOTE as LOTE,
			VALIDADE as VALIDADE,
			FABRICACAO as FABRICACAO

		from TOTVS_CYBERLOG_INVENTARIO CONF

		where
			CONF.PROCESSAMENTO is null

		and not exists (
			select 1
			from TOTVS_CYBERLOG_ERROS ERRO
			where
			    ERRO.ORIGEM = 'INVENTARIOS'
			and ERRO.CHAVE = convert( varchar(8), CONF.DATA_INVENTARIO,112) + CONF.CODIGO_PRODUTO
			and ERRO.PROCESSAMENTO is null
		)

		order by
			DATA_INVENTARIO

	EndSQL

	While ! (cAlias)->( Eof() )

		IF aScan( aInventario, {|nota| nota[1] == (cAlias)->DATAINV } ) == 0
			aAdd(aInventario, { (cAlias)->DATAINV, {}})
		EndIF

		aAdd( aInventario[len(aInventario)][2], {;
			(cAlias)->PRODUTO, ;
			(cAlias)->LOCAL, ;
			(cAlias)->QUANTIDADE, ;
			(cAlias)->LOTE, ;
			(cAlias)->VALIDADE, ;
			(cAlias)->FABRICACAO, ;
		}  )

		(cAlias)->(dbSkip())
	EndDO

return aInventario


static function Grava(dData, aConf)

	Local lConferido := .T.
	Local nItem

	IF valtype(dData) == 'C'
		dData := StoD(RetNum(dData))
	EndIF

	For nItem := 1 to len(aConf)

		Begin Transaction

		SB1->( dbSetOrder(1) )
		SB1->( dbSeek( xFilial("SB1") + aConf[nItem][1] ) )

		IF SB1->( Found() )

			NNR->( dbSetOrder(1) )
			NNR->( dbSeek( xFilial("NNR") + aConf[nItem][2] ) )

			IF NNR->( Found() )

				SB2->( dbSetOrder(1) )
				SB2->( dbSeek( xFilial("SB2") + SB1->B1_COD + aConf[nItem][2] ) )

				IF SB2->( Found() )
					GravaInv(dData, aConf[nItem])
				Else
					u_CChWMSError('INVENTARIOS', DtoS(dData)+alltrim(aConf[nItem][1]), 'Local de estoque "'+aConf[nItem][2]+'" não existe para o Produto "'+aConf[nItem][1]+'".')
				EndIF
			Else
				u_CChWMSError('INVENTARIOS', DtoS(dData)+alltrim(aConf[nItem][1]), 'Local de estoque "'+aConf[nItem][2]+'" não encontrado.')
			EndIF
		Else
			u_CChWMSError('INVENTARIOS', DtoS(dData)+alltrim(aConf[nItem][1]), 'Produto "'+aConf[nItem][1]+'" nao encontrado')
		EndIF
		End Transaction

	Next nItem


return


static function GravaInv(dData, aItem)

	Local aMata270 := {}

	Private lMsErroAuto := FALSE, lMsHelpAuto := lAutoErrNoFile := TRUE

	ConOut(FormDate(dData))
	varinfo('aItem', aItem)

	aAdd(aMata270, {'B7_DOC'  , DtoS(dData), Nil })
	aAdd(aMata270, {'B7_COD'  , aItem[1], Nil })
	aAdd(aMata270, {'B7_LOCAL', aItem[2], Nil })
	aAdd(aMata270, {'B7_QUANT', aItem[3], Nil })

	MsExecAuto({|campos, escolha, opcao| Mata270(campos, escolha, opcao)}, aMata270,,3)

	IF lMsErroAuto
		u_CChWMSError('INVENTARIOS', DtoS(dData)+alltrim(aItem[1]), GetExecErro())
	Else
		u_CCnInventario(dData, aItem[1] )
	EndIF

return


/*/{Protheus.doc} GetExecErro
Trata o erro do MsExecAuto

@author Rafael Ricardo Vieceli
@since 08/02/2017
@version undefined

@type function
/*/
static function GetExecErro()

	//captura o erro do execAuto
	Local aLog := GetAutoGRLog()
	Local nCont

	Local cErro := ''

	for nCont := 1 to len(aLog)
		IF nCont > 1
			cErro += '\n'//CRLF
		EndIF
		cErro += strtran(aLog[nCont],'--','')
	next nCont

return cErro

