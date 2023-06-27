#include 'protheus.ch'
#include 'fwmvcdef.ch'


/*/{Protheus.doc} MLoj040
Função para reimpressão do Contra Vale

@author Rafael Ricardo Vieceli
@since 07/07/2017
@version undefined

@type function
/*/
user function MLoj040()

	Local oBrowse
	Local oModal
	Local oLayer

	IF MyPergunte()

		Private cAlias := GetNextAlias()


		oModal	:= FWDialogModal():New()
		oModal:SetEscClose(.T.)
		oModal:setTitle("Reimpressão de Contra Vale")
		oModal:enableAllClient()
		oModal:createDialog()
		oModal:createFormBar()

		oLayer := FWLayer():New()
		oLayer:Init( oModal:getPanelMain(), .F.)

		oLayer:AddLine('Up'  ,15,.F.)

		//cliente
		TGet():New(10, 10, bSetGet(SA1->A1_COD) ,oLayer:GetLinePanel('Up'),  30, 12 , "",,,,,.F.,,.T.,,.F.,{|| .F. },.F.,.F.,,.F.,.F.,,'SA1->A1_COD' ,,,,,,,'Codigo',1)
		TGet():New(10, 50, bSetGet(SA1->A1_LOJA),oLayer:GetLinePanel('Up'),  30, 12 , "",,,,,.F.,,.T.,,.F.,{|| .F. },.F.,.F.,,.F.,.F.,,'SA1->A1_LOJA',,,,,,,'Loja',1)
		TGet():New(10, 90, bSetGet(SA1->A1_NOME),oLayer:GetLinePanel('Up'), 200, 12 , "",,,,,.F.,,.T.,,.F.,{|| .F. },.F.,.F.,,.F.,.F.,,'SA1->A1_NOME',,,,,,,'Nome',1)
		TGet():New(10,300, bSetGet(TransForm(SA1->A1_CGC,PicPesFJ(SA1->A1_PESSOA))) ,oLayer:GetLinePanel('Up'),  70, 12 , "",,,,,.F.,,.T.,,.F.,{|| .F. },.F.,.F.,,.F.,.F.,,'SA1->A1_CGC' ,,,,,,,'CPF/CNPJ',1)

		oLayer:AddLine('Down',85,.F.)


		oBrowse := FWmBrowse():New()
		oBrowse:SetOwner( oLayer:GetLinePanel('Down'))
		oBrowse:SetDataQuery(.T.)
		oBrowse:SetQuery( MakeQuery() )

		oBrowse:SetColumns( MakeColumns() )
		oBrowse:SetAlias( cAlias )
		oBrowse:SetUseFilter(.F.)
		oBrowse:SetMenuDef('')
		oBrowse:DisableReport()
		oBrowse:DisableConfig()


		oBrowse:Activate()

		oModal:addButtons({{'', 'Cancelar'             , {|| oModal:Deactivate() },'Clique aqui para Cancelar', ,.T.,.T.}})
		oModal:addButtons({{'', "Buscar Outro Cliente" , {|| _Refresh(oBrowse)   },'Clique aqui para Buscar outro cliente', ,.T.,.T.}})
		oModal:addButtons({{'', "Imprimir"             , {|| Imprime()           },'Clique aqui para Buscar outro cliente', ,.T.,.T.}})
		oModal:Activate()

	EndIF

return


/*/{Protheus.doc} Imprime
Função para verificar se pode e preparar a impressão

@author Rafael Ricardo Vieceli
@since 07/07/2017
@version undefined

@type function
/*/
static function Imprime()
	//fUNCAO de impressão já estava comentada... Comentei o restante para não gerar erros
	Alert('Função de impressão desabilitada.')
	// IF ! Empty((cAlias)->E1_FILIAL)

	// 	//muda a filial
	// 	cFilAnt := (cAlias)->E1_FILIAL

	// 	SM0->( dbSetOrder(1) )
	// 	SM0->( dbSeek( cEmpAnt + cFilAnt ) )

	// 	//posiciona na nota
	//   	SE1->( dbGoTo( (cAlias)->SF1RECNO ) )

	// 	//cria a variavel se não existe
	// 	IF type('oAutocom') == 'U'
	// 		oAutocom := Autocom():New()
	// 	EndIF

	// 	//chama a impressão
	// 	//FwMsgRun(, {|| u_ReciboDev() }, "Imprimindo...", "Imprimindo Contra Vale")

	// EndIF

return


/*/{Protheus.doc} _Refresh
Função para fezer refresh no Browse

@author Rafael Ricardo Vieceli
@since 07/07/2016
@version undefined
@param oBrowse, object, Objeto do browse
@type function
/*/
Static Function _Refresh(oBrowse)


	IF MyPergunte()

		FwMsgRun(, {|| ;
			oBrowse:SetQuery( MakeQuery() ), ;
			oBrowse:GoTop(), ;
			oBrowse:Refresh() ;
		}, "Cliente...", "Selecionando titulos do cliente")

	EndIF

Return



/*/{Protheus.doc} MyPergunte
Função para abrir tela de perguntas

@author Rafael Ricardo Vieceli
@since 07/07/2017
@version undefined

@type function
/*/
static function MyPergunte()

	Local cTitle  := "Informe o codigo do Cliente"
	Local aFields := {}


	aAdd(aFields, { 1, "Codigo", space(TamSX3('A1_COD')[1]) ,/*picture*/, /*validacao*/,"SA1" , /*when*/,40,.T.})
	aAdd(aFields, { 1, "Loja"  , space(TamSX3('A1_LOJA')[1]),/*picture*/, /*validacao*/,/*F3*/, /*when*/,20,.T.})


return ParamBox(aFields, cTitle,,,,,,,,.F.,.F.)



/*/{Protheus.doc} MakeQuery
Função que monta a consulta para o browse

@author Rafael Ricardo Vieceli
@since 07/07/2017
@version undefined

@type function
/*/
static function MakeQuery()

	Local cCampoPrefixo := '%'+StrTran(GetMV("MV_2DUPREF"),"->",".")+'%'


	SetExecSql(.F.)

	BeginSQL Alias 'DONTNEED'

		select
		 	//SF1.F1_FILIAL,
		   	//SF1.F1_DOC,
			//SF1.F1_SERIE,
			//SF1.F1_EMISSAO,
			SE1.E1_TIPO,
			SE1.E1_PARCELA,
			SE1.E1_VALOR,
			SE1.E1_SALDO
		   //	SF1.R_E_C_N_O_ as SF1RECNO

		//cliente
		from %table:SA1% SA1

			//nota de entrada de devolução
		/*	inner join %table:SF1% SF1
				on  left(SF1.F1_FILIAL,len(SA1.A1_FILIAL)) = rtrim(SA1.A1_FILIAL)
				and SF1.F1_FORNECE = SA1.A1_COD
				and SF1.F1_LOJA    = SA1.A1_LOJA
				and SF1.F1_TIPO    = 'D' //devolução
			 	and SF1.D_E_L_E_T_ = ' '
          */
			//titulo a receber de Nota de Credito
			inner join %table:SE1% SE1
				//on  SE1.E1_FILIAL  = SF1.F1_FILIAL
				//and	SE1.E1_PREFIXO = %Exp: cCampoPrefixo %
				//and SE1.E1_NUM     = SF1.F1_DOC
				ON SE1.E1_TIPO    = 'NCC'
				and SE1.E1_CLIENTE = SA1.A1_COD
				and SE1.E1_LOJA    = SA1.A1_LOJA
				and SE1.E1_SALDO   > 0
				and SE1.D_E_L_E_T_ = ' '

		where
			SA1.A1_FILIAL  = %xFilial:SA1%
		and SA1.A1_COD     = %Exp: mv_par01%
		and SA1.A1_LOJA    = %Exp: mv_par02%
		and SA1.D_E_L_E_T_ = ' '
	EndSQL

	SetExecSql(.T.)

	//posiciona no cliente
	SA1->( dbSetOrder(1) )
	SA1->( dbSeek( xFilial("SA1") + mv_par01 + mv_par02 ) )

Return GetLastQuery()[2]


/*/{Protheus.doc} GetColumns
Função para montar as colunas para o FWBrowse

@author Rafael Ricardo Vieceli
@since 07/07/2017
@version undefined
@type function
/*/
Static Function MakeColumns()

  //	Local aFields  := {'F1_FILIAL', 'F1_DOC', 'F1_SERIE', 'F1_EMISSAO', 'E1_TIPO', 'E1_PARCELA', 'E1_VALOR','E1_SALDO'}
    Local aFields  := {'E1_TIPO', 'E1_PARCELA', 'E1_VALOR','E1_SALDO'}
	Local aColumns := {}
	Local oColumn
	Local n1

	SX3->( dbSetOrder(2) )

	For n1 := 1 to len(aFields)

		SX3->( dbSeek( aFields[n1]) )

		IF SX3->( Found() )


			oColumn := FWBrwColumn():New()

			oColumn:SetType(FWSX3Util():GetFieldType( aFields[n1] ))
			oColumn:SetTitle( X3Titulo() )
			oColumn:SetSize(TamSx3(aFields[n1])[1])
			oColumn:SetDecimal(TamSx3(aFields[n1])[2])

			do case
				case "_FILIAL" $ aFields[n1]
					oColumn:SetData(&("{|| " + aFields[n1] + " + '-' + FWFilialName(,"+aFields[n1]+") }"))
					oColumn:SetSize(40)
				case FWSX3Util():GetFieldType( aFields[n1] ) == "D"
					oColumn:SetData(&("{|| StoD(" + aFields[n1] + ")}"))
				otherwise
					oColumn:SetData(&("{||" + aFields[n1] + "}"))
			endcase
			// PesqPict(SX3->X3_ARQUIVO, cCampoAtu)
			oColumn:SetPicture(PesqPict('SE1', aFields[n1]))
			oColumn:SetAlign( IIF(FWSX3Util():GetFieldType( aFields[n1] ) == "N",COLUMN_ALIGN_RIGHT,IIF(FWSX3Util():GetFieldType( aFields[n1] ) == "D",COLUMN_ALIGN_CENTER,COLUMN_ALIGN_LEFT)) )

			IF ! Empty( X3Cbox() )
				oColumn:SetOptions( STRTOKARR ( X3Cbox() , ';' ) )
			EndIF

			aAdd(aColumns, oColumn)

		EndIF
	Next n1
	SX3->( dbSetOrder(1) )

Return aColumns
