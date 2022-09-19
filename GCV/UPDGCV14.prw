#INCLUDE "PROTHEUS.CH"

#DEFINE SIMPLES Char( 39 )
#DEFINE DUPLAS  Char( 34 )

#DEFINE CSSBOTAO	"QPushButton { color: #024670; "+;
"    border-image: url(rpo:fwstd_btn_nml.png) 3 3 3 3 stretch; "+;
"    border-top-width: 3px; "+;
"    border-left-width: 3px; "+;
"    border-right-width: 3px; "+;
"    border-bottom-width: 3px }"+;
"QPushButton:pressed {	color: #FFFFFF; "+;
"    border-image: url(rpo:fwstd_btn_prd.png) 3 3 3 3 stretch; "+;
"    border-top-width: 3px; "+;
"    border-left-width: 3px; "+;
"    border-right-width: 3px; "+;
"    border-bottom-width: 3px }"

//--------------------------------------------------------------------
/*/{Protheus.doc} UPDGCV14
Função de update de dicionários para compatibilização

@author TOTVS Protheus
@since  16/12/2016
@obs    Gerado por EXPORDIC - V.5.2.1.0 EFS / Upd. V.4.20.15 EFS
@version 1.0
/*/
//--------------------------------------------------------------------
User Function UPDGCV14( cEmpAmb, cFilAmb )

Local   aSay      := {}
Local   aButton   := {}
Local   aMarcadas := {}
Local   cTitulo   := "ATUALIZAÇÃO DE DICIONÁRIOS E TABELAS"
Local   cDesc1    := "Esta rotina tem como função fazer  a atualização  dos dicionários do Sistema ( SX?/SIX )"
Local   cDesc2    := "Este processo deve ser executado em modo EXCLUSIVO, ou seja não podem haver outros"
Local   cDesc3    := "usuários  ou  jobs utilizando  o sistema.  É EXTREMAMENTE recomendavél  que  se  faça um"
Local   cDesc4    := "BACKUP  dos DICIONÁRIOS  e da  BASE DE DADOS antes desta atualização, para que caso "
Local   cDesc5    := "ocorram eventuais falhas, esse backup possa ser restaurado."
Local   cDesc6    := ""
Local   cDesc7    := ""
Local   lOk       := .F.
Local   lAuto     := ( cEmpAmb <> NIL .or. cFilAmb <> NIL )

Private oMainWnd  := NIL
Private oProcess  := NIL

#IFDEF TOP
    TCInternal( 5, "*OFF" ) // Desliga Refresh no Lock do Top
#ENDIF

__cInterNet := NIL
__lPYME     := .F.

Set Dele On

// Mensagens de Tela Inicial
aAdd( aSay, cDesc1 )
aAdd( aSay, cDesc2 )
aAdd( aSay, cDesc3 )
aAdd( aSay, cDesc4 )
aAdd( aSay, cDesc5 )
//aAdd( aSay, cDesc6 )
//aAdd( aSay, cDesc7 )

// Botoes Tela Inicial
aAdd(  aButton, {  1, .T., { || lOk := .T., FechaBatch() } } )
aAdd(  aButton, {  2, .T., { || lOk := .F., FechaBatch() } } )

If lAuto
	lOk := .T.
Else
	FormBatch(  cTitulo,  aSay,  aButton )
EndIf

If lOk
	If lAuto
		aMarcadas :={{ cEmpAmb, cFilAmb, "" }}
	Else
		aMarcadas := EscEmpresa()
	EndIf

	If !Empty( aMarcadas )
		If lAuto .OR. MsgNoYes( "Confirma a atualização dos dicionários ?", cTitulo )
			oProcess := MsNewProcess():New( { | lEnd | lOk := FSTProc( @lEnd, aMarcadas, lAuto ) }, "Atualizando", "Aguarde, atualizando ...", .F. )
			oProcess:Activate()

			If lAuto
				If lOk
					MsgStop( "Atualização Realizada.", "UPDGCV14" )
				Else
					MsgStop( "Atualização não Realizada.", "UPDGCV14" )
				EndIf
				dbCloseAll()
			Else
				If lOk
					Final( "Atualização Concluída." )
				Else
					Final( "Atualização não Realizada." )
				EndIf
			EndIf

		Else
			MsgStop( "Atualização não Realizada.", "UPDGCV14" )

		EndIf

	Else
		MsgStop( "Atualização não Realizada.", "UPDGCV14" )

	EndIf

EndIf

Return NIL


//--------------------------------------------------------------------
/*/{Protheus.doc} FSTProc
Função de processamento da gravação dos arquivos

@author TOTVS Protheus
@since  16/12/2016
@obs    Gerado por EXPORDIC - V.5.2.1.0 EFS / Upd. V.4.20.15 EFS
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function FSTProc( lEnd, aMarcadas, lAuto )
Local   aInfo     := {}
Local   aRecnoSM0 := {}
Local   cAux      := ""
Local   cFile     := ""
Local   cFileLog  := ""
Local   cMask     := "Arquivos Texto" + "(*.TXT)|*.txt|"
Local   cTCBuild  := "TCGetBuild"
Local   cTexto    := ""
Local   cTopBuild := ""
Local   lOpen     := .F.
Local   lRet      := .T.
Local   nI        := 0
Local   nPos      := 0
Local   nRecno    := 0
Local   nX        := 0
Local   oDlg      := NIL
Local   oFont     := NIL
Local   oMemo     := NIL

Private aArqUpd   := {}

If ( lOpen := MyOpenSm0(.T.) )

	dbSelectArea( "SM0" )
	dbGoTop()

	While !SM0->( EOF() )
		// Só adiciona no aRecnoSM0 se a empresa for diferente
		If aScan( aRecnoSM0, { |x| x[2] == SM0->M0_CODIGO } ) == 0 ;
		   .AND. aScan( aMarcadas, { |x| x[1] == SM0->M0_CODIGO } ) > 0
			aAdd( aRecnoSM0, { Recno(), SM0->M0_CODIGO } )
		EndIf
		SM0->( dbSkip() )
	End

	SM0->( dbCloseArea() )

	If lOpen

		For nI := 1 To Len( aRecnoSM0 )

			If !( lOpen := MyOpenSm0(.F.) )
				MsgStop( "Atualização da empresa " + aRecnoSM0[nI][2] + " não efetuada." )
				Exit
			EndIf

			SM0->( dbGoTo( aRecnoSM0[nI][1] ) )

			RpcSetType( 3 )
			RpcSetEnv( SM0->M0_CODIGO, SM0->M0_CODFIL )

			lMsFinalAuto := .F.
			lMsHelpAuto  := .F.

			AutoGrLog( Replicate( "-", 128 ) )
			AutoGrLog( Replicate( " ", 128 ) )
			AutoGrLog( "LOG DA ATUALIZAÇÃO DOS DICIONÁRIOS" )
			AutoGrLog( Replicate( " ", 128 ) )
			AutoGrLog( Replicate( "-", 128 ) )
			AutoGrLog( " " )
			AutoGrLog( " Dados Ambiente" )
			AutoGrLog( " --------------------" )
			AutoGrLog( " Empresa / Filial...: " + cEmpAnt + "/" + cFilAnt )
			AutoGrLog( " Nome Empresa.......: " + Capital( AllTrim( GetAdvFVal( "SM0", "M0_NOMECOM", cEmpAnt + cFilAnt, 1, "" ) ) ) )
			AutoGrLog( " Nome Filial........: " + Capital( AllTrim( GetAdvFVal( "SM0", "M0_FILIAL" , cEmpAnt + cFilAnt, 1, "" ) ) ) )
			AutoGrLog( " DataBase...........: " + DtoC( dDataBase ) )
			AutoGrLog( " Data / Hora Ínicio.: " + DtoC( Date() )  + " / " + Time() )
			AutoGrLog( " Environment........: " + GetEnvServer()  )
			AutoGrLog( " StartPath..........: " + GetSrvProfString( "StartPath", "" ) )
			AutoGrLog( " RootPath...........: " + GetSrvProfString( "RootPath" , "" ) )
			AutoGrLog( " Versão.............: " + GetVersao(.T.) )
			AutoGrLog( " Usuário TOTVS .....: " + __cUserId + " " +  cUserName )
			AutoGrLog( " Computer Name......: " + GetComputerName() )

			aInfo   := GetUserInfo()
			If ( nPos    := aScan( aInfo,{ |x,y| x[3] == ThreadId() } ) ) > 0
				AutoGrLog( " " )
				AutoGrLog( " Dados Thread" )
				AutoGrLog( " --------------------" )
				AutoGrLog( " Usuário da Rede....: " + aInfo[nPos][1] )
				AutoGrLog( " Estação............: " + aInfo[nPos][2] )
				AutoGrLog( " Programa Inicial...: " + aInfo[nPos][5] )
				AutoGrLog( " Environment........: " + aInfo[nPos][6] )
				AutoGrLog( " Conexão............: " + AllTrim( StrTran( StrTran( aInfo[nPos][7], Chr( 13 ), "" ), Chr( 10 ), "" ) ) )
			EndIf
			AutoGrLog( Replicate( "-", 128 ) )
			AutoGrLog( " " )

			If !lAuto
				AutoGrLog( Replicate( "-", 128 ) )
				AutoGrLog( "Empresa : " + SM0->M0_CODIGO + "/" + SM0->M0_NOME + CRLF )
			EndIf

			oProcess:SetRegua1( 8 )

			//------------------------------------
			// Atualiza o dicionário SX2
			//------------------------------------
			oProcess:IncRegua1( "Dicionário de arquivos" + " - " + SM0->M0_CODIGO + " " + SM0->M0_NOME + " ..." )
			FSAtuSX2()

			//------------------------------------
			// Atualiza o dicionário SX3
			//------------------------------------
			FSAtuSX3()

			//------------------------------------
			// Atualiza o dicionário SIX
			//------------------------------------
			oProcess:IncRegua1( "Dicionário de índices" + " - " + SM0->M0_CODIGO + " " + SM0->M0_NOME + " ..." )
			FSAtuSIX()

			oProcess:IncRegua1( "Dicionário de dados" + " - " + SM0->M0_CODIGO + " " + SM0->M0_NOME + " ..." )
			oProcess:IncRegua2( "Atualizando campos/índices" )

			// Alteração física dos arquivos
			__SetX31Mode( .F. )

			If FindFunction(cTCBuild)
				cTopBuild := &cTCBuild.()
			EndIf

			For nX := 1 To Len( aArqUpd )

				If cTopBuild >= "20090811" .AND. TcInternal( 89 ) == "CLOB_SUPPORTED"
					If ( ( aArqUpd[nX] >= "NQ " .AND. aArqUpd[nX] <= "NZZ" ) .OR. ( aArqUpd[nX] >= "O0 " .AND. aArqUpd[nX] <= "NZZ" ) ) .AND.;
						!aArqUpd[nX] $ "NQD,NQF,NQP,NQT"
						TcInternal( 25, "CLOB" )
					EndIf
				EndIf

				If Select( aArqUpd[nX] ) > 0
					dbSelectArea( aArqUpd[nX] )
					dbCloseArea()
				EndIf

				X31UpdTable( aArqUpd[nX] )

				If __GetX31Error()
					Alert( __GetX31Trace() )
					MsgStop( "Ocorreu um erro desconhecido durante a atualização da tabela : " + aArqUpd[nX] + ". Verifique a integridade do dicionário e da tabela.", "ATENÇÃO" )
					AutoGrLog( "Ocorreu um erro desconhecido durante a atualização da estrutura da tabela : " + aArqUpd[nX] )
				EndIf

				If cTopBuild >= "20090811" .AND. TcInternal( 89 ) == "CLOB_SUPPORTED"
					TcInternal( 25, "OFF" )
				EndIf

			Next nX

			//------------------------------------
			// Atualiza o dicionário SX6
			//------------------------------------
			oProcess:IncRegua1( "Dicionário de parâmetros" + " - " + SM0->M0_CODIGO + " " + SM0->M0_NOME + " ..." )
			FSAtuSX6()

			//------------------------------------
			// Atualiza o dicionário SX7
			//------------------------------------
			oProcess:IncRegua1( "Dicionário de gatilhos" + " - " + SM0->M0_CODIGO + " " + SM0->M0_NOME + " ..." )
			FSAtuSX7()

			//------------------------------------
			// Atualiza o dicionário SXB
			//------------------------------------
			oProcess:IncRegua1( "Dicionário de consultas padrão" + " - " + SM0->M0_CODIGO + " " + SM0->M0_NOME + " ..." )
			FSAtuSXB()

			//------------------------------------
			// Atualiza os helps
			//------------------------------------
			oProcess:IncRegua1( "Helps de Campo" + " - " + SM0->M0_CODIGO + " " + SM0->M0_NOME + " ..." )
			FSAtuHlp()

			AutoGrLog( Replicate( "-", 128 ) )
			AutoGrLog( " Data / Hora Final.: " + DtoC( Date() ) + " / " + Time() )
			AutoGrLog( Replicate( "-", 128 ) )

			RpcClearEnv()

		Next nI

		If !lAuto

			cTexto := LeLog()

			Define Font oFont Name "Mono AS" Size 5, 12

			Define MsDialog oDlg Title "Atualização concluida." From 3, 0 to 340, 417 Pixel

			@ 5, 5 Get oMemo Var cTexto Memo Size 200, 145 Of oDlg Pixel
			oMemo:bRClicked := { || AllwaysTrue() }
			oMemo:oFont     := oFont

			Define SButton From 153, 175 Type  1 Action oDlg:End() Enable Of oDlg Pixel // Apaga
			Define SButton From 153, 145 Type 13 Action ( cFile := cGetFile( cMask, "" ), If( cFile == "", .T., ;
			MemoWrite( cFile, cTexto ) ) ) Enable Of oDlg Pixel

			Activate MsDialog oDlg Center

		EndIf

	EndIf

Else

	lRet := .F.

EndIf

Return lRet


//--------------------------------------------------------------------
/*/{Protheus.doc} FSAtuSX2
Função de processamento da gravação do SX2 - Arquivos

@author TOTVS Protheus
@since  16/12/2016
@obs    Gerado por EXPORDIC - V.5.2.1.0 EFS / Upd. V.4.20.15 EFS
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function FSAtuSX2()
Local aEstrut   := {}
Local aSX2      := {}
Local cAlias    := ""
Local cCpoUpd   := "X2_ROTINA /X2_UNICO  /X2_DISPLAY/X2_SYSOBJ /X2_USROBJ /X2_POSLGT /"
Local cEmpr     := ""
Local cPath     := ""
Local nI        := 0
Local nJ        := 0

AutoGrLog( "Ínicio da Atualização" + " SX2" + CRLF )

aEstrut := { "X2_CHAVE"  , "X2_PATH"   , "X2_ARQUIVO", "X2_NOME"   , "X2_NOMESPA", "X2_NOMEENG", "X2_MODO"   , ;
             "X2_TTS"    , "X2_ROTINA" , "X2_PYME"   , "X2_UNICO"  , "X2_DISPLAY", "X2_SYSOBJ" , "X2_USROBJ" , ;
             "X2_POSLGT" , "X2_CLOB"   , "X2_AUTREC" , "X2_MODOEMP", "X2_MODOUN" , "X2_MODULO" }


dbSelectArea( "SX2" )
SX2->( dbSetOrder( 1 ) )
SX2->( dbGoTop() )
cPath := SX2->X2_PATH
cPath := IIf( Right( AllTrim( cPath ), 1 ) <> "\", PadR( AllTrim( cPath ) + "\", Len( cPath ) ), cPath )
cEmpr := Substr( SX2->X2_ARQUIVO, 4 )

//
// Tabela AXC
//
aAdd( aSX2, { ;
	'AXC'																	, ; //X2_CHAVE
	cPath																	, ; //X2_PATH
	'AXC'+cEmpr																, ; //X2_ARQUIVO
	'Pre-Pedido Compra Grade'												, ; //X2_NOME
	'Pre-Pedido Compra Grade'												, ; //X2_NOMESPA
	'Pre-Pedido Compra Grade'												, ; //X2_NOMEENG
	'E'																		, ; //X2_MODO
	''																		, ; //X2_TTS
	''																		, ; //X2_ROTINA
	'N'																		, ; //X2_PYME
	''																		, ; //X2_UNICO
	''																		, ; //X2_DISPLAY
	''																		, ; //X2_SYSOBJ
	''																		, ; //X2_USROBJ
	'2'																		, ; //X2_POSLGT
	'2'																		, ; //X2_CLOB
	'2'																		, ; //X2_AUTREC
	'E'																		, ; //X2_MODOEMP
	'E'																		, ; //X2_MODOUN
	90																		} ) //X2_MODULO

//
// Tabela AXD
//
aAdd( aSX2, { ;
	'AXD'																	, ; //X2_CHAVE
	cPath																	, ; //X2_PATH
	'AXD'+cEmpr																, ; //X2_ARQUIVO
	'Distribuicao Pre-Pedido Compra'										, ; //X2_NOME
	'Distribuicao Pre-Pedido Compra'										, ; //X2_NOMESPA
	'Distribuicao Pre-Pedido Compra'										, ; //X2_NOMEENG
	'C'																		, ; //X2_MODO
	''																		, ; //X2_TTS
	''																		, ; //X2_ROTINA
	'N'																		, ; //X2_PYME
	''																		, ; //X2_UNICO
	''																		, ; //X2_DISPLAY
	''																		, ; //X2_SYSOBJ
	''																		, ; //X2_USROBJ
	'2'																		, ; //X2_POSLGT
	'2'																		, ; //X2_CLOB
	'2'																		, ; //X2_AUTREC
	'C'																		, ; //X2_MODOEMP
	'C'																		, ; //X2_MODOUN
	90																		} ) //X2_MODULO

//
// Tabela AXE
//
aAdd( aSX2, { ;
	'AXE'																	, ; //X2_CHAVE
	cPath																	, ; //X2_PATH
	'AXE'+cEmpr																, ; //X2_ARQUIVO
	'Produtos Novos Pre-Pedido'												, ; //X2_NOME
	'Produtos Novos Pre-Pedido'												, ; //X2_NOMESPA
	'Produtos Novos Pre-Pedido'												, ; //X2_NOMEENG
	'C'																		, ; //X2_MODO
	''																		, ; //X2_TTS
	''																		, ; //X2_ROTINA
	'N'																		, ; //X2_PYME
	''																		, ; //X2_UNICO
	''																		, ; //X2_DISPLAY
	''																		, ; //X2_SYSOBJ
	''																		, ; //X2_USROBJ
	'2'																		, ; //X2_POSLGT
	'2'																		, ; //X2_CLOB
	'2'																		, ; //X2_AUTREC
	'C'																		, ; //X2_MODOEMP
	'C'																		, ; //X2_MODOUN
	90																		} ) //X2_MODULO

//
// Tabela AXH
//
aAdd( aSX2, { ;
	'AXH'																	, ; //X2_CHAVE
	cPath																	, ; //X2_PATH
	'AXH'+cEmpr																, ; //X2_ARQUIVO
	'Cabecalho Verba de Compras'											, ; //X2_NOME
	'Cabecalho Verba de Compras'											, ; //X2_NOMESPA
	'Cabecalho Verba de Compras'											, ; //X2_NOMEENG
	'C'																		, ; //X2_MODO
	''																		, ; //X2_TTS
	''																		, ; //X2_ROTINA
	''																		, ; //X2_PYME
	''																		, ; //X2_UNICO
	''																		, ; //X2_DISPLAY
	''																		, ; //X2_SYSOBJ
	''																		, ; //X2_USROBJ
	''																		, ; //X2_POSLGT
	''																		, ; //X2_CLOB
	''																		, ; //X2_AUTREC
	'C'																		, ; //X2_MODOEMP
	'C'																		, ; //X2_MODOUN
	0																		} ) //X2_MODULO

//
// Tabela AXI
//
aAdd( aSX2, { ;
	'AXI'																	, ; //X2_CHAVE
	cPath																	, ; //X2_PATH
	'AXI'+cEmpr																, ; //X2_ARQUIVO
	'Verba de Compra por Nivel'												, ; //X2_NOME
	'Verba de Compra por Nivel'												, ; //X2_NOMESPA
	'Verba de Compra por Nivel'												, ; //X2_NOMEENG
	'C'																		, ; //X2_MODO
	''																		, ; //X2_TTS
	''																		, ; //X2_ROTINA
	''																		, ; //X2_PYME
	''																		, ; //X2_UNICO
	''																		, ; //X2_DISPLAY
	''																		, ; //X2_SYSOBJ
	''																		, ; //X2_USROBJ
	''																		, ; //X2_POSLGT
	''																		, ; //X2_CLOB
	''																		, ; //X2_AUTREC
	'C'																		, ; //X2_MODOEMP
	'C'																		, ; //X2_MODOUN
	0																		} ) //X2_MODULO

//
// Tabela AXJ
//
aAdd( aSX2, { ;
	'AXJ'																	, ; //X2_CHAVE
	cPath																	, ; //X2_PATH
	'AXJ'+cEmpr																, ; //X2_ARQUIVO
	'Cabecalho Meta de Vendas'												, ; //X2_NOME
	'Cabecalho Meta de Vendas'												, ; //X2_NOMESPA
	'Cabecalho Meta de Vendas'												, ; //X2_NOMEENG
	'C'																		, ; //X2_MODO
	''																		, ; //X2_TTS
	''																		, ; //X2_ROTINA
	''																		, ; //X2_PYME
	''																		, ; //X2_UNICO
	''																		, ; //X2_DISPLAY
	''																		, ; //X2_SYSOBJ
	''																		, ; //X2_USROBJ
	''																		, ; //X2_POSLGT
	''																		, ; //X2_CLOB
	''																		, ; //X2_AUTREC
	'C'																		, ; //X2_MODOEMP
	'C'																		, ; //X2_MODOUN
	0																		} ) //X2_MODULO

//
// Tabela AXK
//
aAdd( aSX2, { ;
	'AXK'																	, ; //X2_CHAVE
	cPath																	, ; //X2_PATH
	'AXK'+cEmpr																, ; //X2_ARQUIVO
	'Meta de Venda por Nivel'												, ; //X2_NOME
	'Meta de Venda por Nivel'												, ; //X2_NOMESPA
	'Meta de Venda por Nivel'												, ; //X2_NOMEENG
	'C'																		, ; //X2_MODO
	''																		, ; //X2_TTS
	''																		, ; //X2_ROTINA
	''																		, ; //X2_PYME
	''																		, ; //X2_UNICO
	''																		, ; //X2_DISPLAY
	''																		, ; //X2_SYSOBJ
	''																		, ; //X2_USROBJ
	''																		, ; //X2_POSLGT
	''																		, ; //X2_CLOB
	''																		, ; //X2_AUTREC
	'C'																		, ; //X2_MODOEMP
	'C'																		, ; //X2_MODOUN
	0																		} ) //X2_MODULO

//
// Tabela AXL
//
aAdd( aSX2, { ;
	'AXL'																	, ; //X2_CHAVE
	cPath																	, ; //X2_PATH
	'AXL'+cEmpr																, ; //X2_ARQUIVO
	'DIVERGENCIA DE FORNECEDOR'												, ; //X2_NOME
	'DIVERGENCIA DE FORNECEDOR'												, ; //X2_NOMESPA
	'DIVERGENCIA DE FORNECEDOR'												, ; //X2_NOMEENG
	'C'																		, ; //X2_MODO
	''																		, ; //X2_TTS
	''																		, ; //X2_ROTINA
	''																		, ; //X2_PYME
	'AXL_FILIAL+AXL_NUM'													, ; //X2_UNICO
	''																		, ; //X2_DISPLAY
	''																		, ; //X2_SYSOBJ
	''																		, ; //X2_USROBJ
	''																		, ; //X2_POSLGT
	''																		, ; //X2_CLOB
	''																		, ; //X2_AUTREC
	'C'																		, ; //X2_MODOEMP
	'C'																		, ; //X2_MODOUN
	0																		} ) //X2_MODULO

//
// Tabela AXM
//
aAdd( aSX2, { ;
	'AXM'																	, ; //X2_CHAVE
	cPath																	, ; //X2_PATH
	'AXM'+cEmpr																, ; //X2_ARQUIVO
	'TIPO DE DIVERGENCIA FORNECEDOR'										, ; //X2_NOME
	'TIPO DE DIVERGENCIA FORNECEDOR'										, ; //X2_NOMESPA
	'TIPO DE DIVERGENCIA FORNECEDOR'										, ; //X2_NOMEENG
	'C'																		, ; //X2_MODO
	''																		, ; //X2_TTS
	''																		, ; //X2_ROTINA
	''																		, ; //X2_PYME
	''																		, ; //X2_UNICO
	''																		, ; //X2_DISPLAY
	''																		, ; //X2_SYSOBJ
	''																		, ; //X2_USROBJ
	''																		, ; //X2_POSLGT
	''																		, ; //X2_CLOB
	''																		, ; //X2_AUTREC
	'C'																		, ; //X2_MODOEMP
	'C'																		, ; //X2_MODOUN
	0																		} ) //X2_MODULO

//
// Atualizando dicionário
//
oProcess:SetRegua2( Len( aSX2 ) )

dbSelectArea( "SX2" )
dbSetOrder( 1 )

For nI := 1 To Len( aSX2 )

	oProcess:IncRegua2( "Atualizando Arquivos (SX2)..." )

	If !SX2->( dbSeek( aSX2[nI][1] ) )

		If !( aSX2[nI][1] $ cAlias )
			cAlias += aSX2[nI][1] + "/"
			AutoGrLog( "Foi incluída a tabela " + aSX2[nI][1] )
		EndIf

		RecLock( "SX2", .T. )
		For nJ := 1 To Len( aSX2[nI] )
			If FieldPos( aEstrut[nJ] ) > 0
				If AllTrim( aEstrut[nJ] ) == "X2_ARQUIVO"
					FieldPut( FieldPos( aEstrut[nJ] ), SubStr( aSX2[nI][nJ], 1, 3 ) + cEmpAnt +  "0" )
				Else
					FieldPut( FieldPos( aEstrut[nJ] ), aSX2[nI][nJ] )
				EndIf
			EndIf
		Next nJ
		MsUnLock()

	Else

		If  !( StrTran( Upper( AllTrim( SX2->X2_UNICO ) ), " ", "" ) == StrTran( Upper( AllTrim( aSX2[nI][12]  ) ), " ", "" ) )
			RecLock( "SX2", .F. )
			SX2->X2_UNICO := aSX2[nI][12]
			MsUnlock()

			If MSFILE( RetSqlName( aSX2[nI][1] ),RetSqlName( aSX2[nI][1] ) + "_UNQ"  )
				TcInternal( 60, RetSqlName( aSX2[nI][1] ) + "|" + RetSqlName( aSX2[nI][1] ) + "_UNQ" )
			EndIf

			AutoGrLog( "Foi alterada a chave única da tabela " + aSX2[nI][1] )
		EndIf

		RecLock( "SX2", .F. )
		For nJ := 1 To Len( aSX2[nI] )
			If FieldPos( aEstrut[nJ] ) > 0
				If PadR( aEstrut[nJ], 10 ) $ cCpoUpd
					FieldPut( FieldPos( aEstrut[nJ] ), aSX2[nI][nJ] )
				EndIf

			EndIf
		Next nJ
		MsUnLock()

	EndIf

Next nI

AutoGrLog( CRLF + "Final da Atualização" + " SX2" + CRLF + Replicate( "-", 128 ) + CRLF )

Return NIL


//--------------------------------------------------------------------
/*/{Protheus.doc} FSAtuSX3
Função de processamento da gravação do SX3 - Campos

@author TOTVS Protheus
@since  16/12/2016
@obs    Gerado por EXPORDIC - V.5.2.1.0 EFS / Upd. V.4.20.15 EFS
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function FSAtuSX3()
Local aEstrut   := {}
Local aSX3      := {}
Local cAlias    := ""
Local cAliasAtu := ""
Local cMsg      := ""
Local cSeqAtu   := ""
Local cX3Campo  := ""
Local cX3Dado   := ""
Local lTodosNao := .F.
Local lTodosSim := .F.
Local nI        := 0
Local nJ        := 0
Local nOpcA     := 1
Local nPosArq   := 0
Local nPosCpo   := 0
Local nPosOrd   := 0
Local nPosSXG   := 0
Local nPosTam   := 0
Local nPosVld   := 0
Local nSeqAtu   := 0
Local nTamSeek  := Len( SX3->X3_CAMPO )

Local nTamFil		:= POSICIONE("SXG",1,"033","XG_SIZE")
Local nTamSKU		:= POSICIONE("SXG",1,"030","XG_SIZE")
Local nTamPai		:= POSICIONE("SXG",1,"G01","XG_SIZE")
Local nTamCliFor	:= POSICIONE("SXG",1,"001","XG_SIZE")
Local nTamLoja		:= POSICIONE("SXG",1,"002","XG_SIZE")

AutoGrLog( "Ínicio da Atualização" + " SX3" + CRLF )

aEstrut := { { "X3_ARQUIVO", 0 }, { "X3_ORDEM"  , 0 }, { "X3_CAMPO"  , 0 }, { "X3_TIPO"   , 0 }, { "X3_TAMANHO", 0 }, { "X3_DECIMAL", 0 }, { "X3_TITULO" , 0 }, ;
             { "X3_TITSPA" , 0 }, { "X3_TITENG" , 0 }, { "X3_DESCRIC", 0 }, { "X3_DESCSPA", 0 }, { "X3_DESCENG", 0 }, { "X3_PICTURE", 0 }, { "X3_VALID"  , 0 }, ;
             { "X3_USADO"  , 0 }, { "X3_RELACAO", 0 }, { "X3_F3"     , 0 }, { "X3_NIVEL"  , 0 }, { "X3_RESERV" , 0 }, { "X3_CHECK"  , 0 }, { "X3_TRIGGER", 0 }, ;
             { "X3_PROPRI" , 0 }, { "X3_BROWSE" , 0 }, { "X3_VISUAL" , 0 }, { "X3_CONTEXT", 0 }, { "X3_OBRIGAT", 0 }, { "X3_VLDUSER", 0 }, { "X3_CBOX"   , 0 }, ;
             { "X3_CBOXSPA", 0 }, { "X3_CBOXENG", 0 }, { "X3_PICTVAR", 0 }, { "X3_WHEN"   , 0 }, { "X3_INIBRW" , 0 }, { "X3_GRPSXG" , 0 }, { "X3_FOLDER" , 0 }, ;
             { "X3_CONDSQL", 0 }, { "X3_CHKSQL" , 0 }, { "X3_IDXSRV" , 0 }, { "X3_ORTOGRA", 0 }, { "X3_TELA"   , 0 }, { "X3_POSLGT" , 0 }, { "X3_IDXFLD" , 0 }, ;
             { "X3_AGRUP"  , 0 }, { "X3_MODAL"  , 0 }, { "X3_PYME"   , 0 } }

aEval( aEstrut, { |x| x[2] := SX3->( FieldPos( x[1] ) ) } )

//
// --- ATENÇÃO ---
// Coloque .F. na 2a. posição de cada elemento do array, para os dados do SX3
// que não serão atualizados quando o campo já existir.
//

//
// Campos Tabela AXC
//
aAdd( aSX3, { ;
	{ 'AXC'																	, .F. }, ; //X3_ARQUIVO
	{ '01'																	, .F. }, ; //X3_ORDEM
	{ 'AXC_FILIAL'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ nTamFil																, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Filial'																, .F. }, ; //X3_TITULO
	{ 'Sucursal'															, .F. }, ; //X3_TITSPA
	{ 'Branch'																, .F. }, ; //X3_TITENG
	{ 'Filial do Sistema'													, .F. }, ; //X3_DESCRIC
	{ 'Sucursal del Sistema'												, .F. }, ; //X3_DESCSPA
	{ 'System Branch'														, .F. }, ; //X3_DESCENG
	{ ''																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(128) + Chr(128)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'V'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ '033'																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ 'N'																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ '1'																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ 'N'																	, .F. }, ; //X3_MODAL
	{ 'S'																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXC'																	, .F. }, ; //X3_ARQUIVO
	{ '02'																	, .F. }, ; //X3_ORDEM
	{ 'AXC_NUM'																, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 6																		, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Numero PC'															, .F. }, ; //X3_TITULO
	{ 'Nr.PedCompra'														, .F. }, ; //X3_TITSPA
	{ 'PO Number'															, .F. }, ; //X3_TITENG
	{ 'Numero do pedido de compr'											, .F. }, ; //X3_DESCRIC
	{ 'Num. del Pedido de Compra'											, .F. }, ; //X3_DESCSPA
	{ 'Purchase Order Number'												, .F. }, ; //X3_DESCENG
	{ '@!'																	, .F. }, ; //X3_PICTURE
	{ 'NaoVazio(M->AXC_NUM).And.ExistChav("AXC",M->AXC_NUM)'				, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128)					, .T. }, ; //X3_USADO
	{ 'GETSXENUM("SC7","C7_NUM",,1)'										, .T. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(65)													, .T. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ 'INCLUI'																, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ 'S'																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ '1'																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ 'S'																	, .F. }, ; //X3_MODAL
	{ 'S'																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXC'																	, .F. }, ; //X3_ARQUIVO
	{ '03'																	, .F. }, ; //X3_ORDEM
	{ 'AXC_EMISSA'															, .F. }, ; //X3_CAMPO
	{ 'D'																	, .F. }, ; //X3_TIPO
	{ 8																		, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'DT Emissao'															, .F. }, ; //X3_TITULO
	{ 'Fch Emision'															, .F. }, ; //X3_TITSPA
	{ 'Issue Date'															, .F. }, ; //X3_TITENG
	{ 'Data de Emissao'														, .F. }, ; //X3_DESCRIC
	{ 'Fecha de Emision'													, .F. }, ; //X3_DESCSPA
	{ 'Issue Date'															, .F. }, ; //X3_DESCENG
	{ ''																	, .F. }, ; //X3_PICTURE
	{ 'NaoVazio(M->AXC_EMISSA)'												, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128)					, .F. }, ; //X3_USADO
	{ 'dDatabase'															, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(144) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'V'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ 'INCLUI'																, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ 'N'																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ '1'																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ 'N'																	, .F. }, ; //X3_MODAL
	{ 'S'																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXC'																	, .F. }, ; //X3_ARQUIVO
	{ '04'																	, .F. }, ; //X3_ORDEM
	{ 'AXC_DTVERB'															, .F. }, ; //X3_CAMPO
	{ 'D'																	, .F. }, ; //X3_TIPO
	{ 8																		, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Data Verba'															, .F. }, ; //X3_TITULO
	{ 'Data Verba'															, .F. }, ; //X3_TITSPA
	{ 'Data Verba'															, .F. }, ; //X3_TITENG
	{ 'Data da Verba de Compra'												, .F. }, ; //X3_DESCRIC
	{ 'Data da Verba de Compra'												, .F. }, ; //X3_DESCSPA
	{ 'Data da Verba de Compra'												, .F. }, ; //X3_DESCENG
	{ ''																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(65)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'S'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ '€'																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXC'																	, .F. }, ; //X3_ARQUIVO
	{ '05'																	, .F. }, ; //X3_ORDEM
	{ 'AXC_FORNEC'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ nTamCliFor															, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Fornecedor'															, .F. }, ; //X3_TITULO
	{ 'Proveedor'															, .F. }, ; //X3_TITSPA
	{ 'Supplier'															, .F. }, ; //X3_TITENG
	{ 'Codigo do fornecedor'												, .F. }, ; //X3_DESCRIC
	{ 'Codigo del Proveedor'												, .F. }, ; //X3_DESCSPA
	{ 'Supplier´s Code'														, .F. }, ; //X3_DESCENG
	{ '@!'																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ 'FOR'																	, .F. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(65)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ 'S'																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ 'Vazio() .OR. T_SyValForn(M->AXC_FORNEC, @M->AXC_LOJA)'				, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ 'INCLUI'																, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ '001'																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ 'S'																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ '1'																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ 'S'																	, .F. }, ; //X3_MODAL
	{ 'S'																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXC'																	, .F. }, ; //X3_ARQUIVO
	{ '06'																	, .F. }, ; //X3_ORDEM
	{ 'AXC_LOJA'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ nTamLoja																, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Loja'																, .F. }, ; //X3_TITULO
	{ 'Tienda'																, .F. }, ; //X3_TITSPA
	{ 'Unit'																, .F. }, ; //X3_TITENG
	{ 'Loja do fornecedor'													, .F. }, ; //X3_DESCRIC
	{ 'Tienda del Proveedor'												, .F. }, ; //X3_DESCSPA
	{ "Supplier's Unit"														, .F. }, ; //X3_DESCENG
	{ '@!'																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(65)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ 'S'																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ "Vazio() .OR. ExistCpo('SA2',M->(AXC_FORNEC+AXC_LOJA),1)"				, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ '002'																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ 'N'																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ '1'																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ 'N'																	, .F. }, ; //X3_MODAL
	{ 'S'																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXC'																	, .F. }, ; //X3_ARQUIVO
	{ '07'																	, .F. }, ; //X3_ORDEM
	{ 'AXC_NOMFOR'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 40																	, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Nome Forn.'															, .F. }, ; //X3_TITULO
	{ 'Nome Forn.'															, .F. }, ; //X3_TITSPA
	{ 'Nome Forn.'															, .F. }, ; //X3_TITENG
	{ 'Nome do Fornecedor'													, .F. }, ; //X3_DESCRIC
	{ 'Nome do Fornecedor'													, .F. }, ; //X3_DESCSPA
	{ 'Nome do Fornecedor'													, .F. }, ; //X3_DESCENG
	{ ''																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ 'IIF(INCLUI,"",POSICIONE("SA2",1,XFILIAL("SA2")+AXC_FORNEC+AXC_LOJA,"A2_NOME"))', .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(65)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ 'S'																	, .F. }, ; //X3_BROWSE
	{ 'V'																	, .F. }, ; //X3_VISUAL
	{ 'V'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ 'POSICIONE("SA2",1,XFILIAL("SA2")+AXC_FORNEC+AXC_LOJA,"A2_NOME")'		, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXC'																	, .F. }, ; //X3_ARQUIVO
	{ '08'																	, .F. }, ; //X3_ORDEM
	{ 'AXC_COND'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 3																		, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Cond. Pagto'															, .F. }, ; //X3_TITULO
	{ 'Cond. Pago'															, .F. }, ; //X3_TITSPA
	{ 'Payment Term'														, .F. }, ; //X3_TITENG
	{ 'Codigo da condicao de Pgt'											, .F. }, ; //X3_DESCRIC
	{ 'Codigo Condicion de Pago'											, .F. }, ; //X3_DESCSPA
	{ 'Payment Term Code'													, .F. }, ; //X3_DESCENG
	{ '@!'																	, .F. }, ; //X3_PICTURE
	{ 'NaoVazio() .And. ExistCpo("SE4")'									, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ 'SE4'																	, .F. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(65)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ 'S'																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ ''																	, .F. }, ; //X3_VISUAL
	{ ''																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ 'N'																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ '1'																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ 'N'																	, .F. }, ; //X3_MODAL
	{ 'S'																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXC'																	, .F. }, ; //X3_ARQUIVO
	{ '09'																	, .F. }, ; //X3_ORDEM
	{ 'AXC_DESCPG'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 15																	, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Desc. Pgto'															, .F. }, ; //X3_TITULO
	{ 'Desc. Pgto'															, .F. }, ; //X3_TITSPA
	{ 'Desc. Pgto'															, .F. }, ; //X3_TITENG
	{ 'Descrição da Cond. Pgto'												, .F. }, ; //X3_DESCRIC
	{ 'Descrição da Cond. Pgto'												, .F. }, ; //X3_DESCSPA
	{ 'Descrição da Cond. Pgto'												, .F. }, ; //X3_DESCENG
	{ ''																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ 'IIF(INCLUI,"",POSICIONE("SE4",1,XFILIAL("SE4")+AXC_COND,"E4_DESCRI"))'	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(65)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'V'																	, .F. }, ; //X3_VISUAL
	{ 'V'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ 'POSICIONE("SE4",1,XFILIAL("SE4")+AXC_COND,"E4_DESCRI")'				, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXC'																	, .F. }, ; //X3_ARQUIVO
	{ '10'																	, .F. }, ; //X3_ORDEM
	{ 'AXC_CONTAT'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 15																	, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Contato'																, .F. }, ; //X3_TITULO
	{ 'Contacto'															, .F. }, ; //X3_TITSPA
	{ 'Contact'																, .F. }, ; //X3_TITENG
	{ 'Contato'																, .F. }, ; //X3_DESCRIC
	{ 'Contacto'															, .F. }, ; //X3_DESCSPA
	{ 'Contact'																, .F. }, ; //X3_DESCENG
	{ '@!'																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(65)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ ''																	, .F. }, ; //X3_VISUAL
	{ ''																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ 'N'																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ '1'																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ 'N'																	, .F. }, ; //X3_MODAL
	{ 'S'																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXC'																	, .T. }, ; //X3_ARQUIVO
	{ '11'																	, .T. }, ; //X3_ORDEM
	{ 'AXC_SEMANA'															, .T. }, ; //X3_CAMPO
	{ 'C'																	, .T. }, ; //X3_TIPO
	{ 6																		, .T. }, ; //X3_TAMANHO
	{ 0																		, .T. }, ; //X3_DECIMAL
	{ 'Semana'																, .T. }, ; //X3_TITULO
	{ 'Semana'																, .T. }, ; //X3_TITSPA
	{ 'Week'																, .T. }, ; //X3_TITENG
	{ 'Semana'																, .T. }, ; //X3_DESCRIC
	{ 'Semana'																, .T. }, ; //X3_DESCSPA
	{ 'Week'																, .T. }, ; //X3_DESCENG
	{ '@R 99/9999'															, .T. }, ; //X3_PICTURE
	{ ''																	, .T. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .T. }, ; //X3_USADO
	{ ''																	, .T. }, ; //X3_RELACAO
	{ 'AY6'																	, .T. }, ; //X3_F3
	{ 0																		, .T. }, ; //X3_NIVEL
	{ Chr(254) + Chr(65)													, .T. }, ; //X3_RESERV
	{ ''																	, .T. }, ; //X3_CHECK
	{ ''																	, .T. }, ; //X3_TRIGGER
	{ ''																	, .T. }, ; //X3_PROPRI
	{ 'N'																	, .T. }, ; //X3_BROWSE
	{ 'A'																	, .T. }, ; //X3_VISUAL
	{ 'R'																	, .T. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ 'T_SyVldSemana(M->AXC_SEMANA)'										, .F. }, ; //X3_VLDUSER
	{ ''																	, .T. }, ; //X3_CBOX
	{ ''																	, .T. }, ; //X3_CBOXSPA
	{ ''																	, .T. }, ; //X3_CBOXENG
	{ ''																	, .T. }, ; //X3_PICTVAR
	{ '!lDataIni'															, .F. }, ; //X3_WHEN
	{ ''																	, .T. }, ; //X3_INIBRW
	{ ''																	, .T. }, ; //X3_GRPSXG
	{ ''																	, .T. }, ; //X3_FOLDER
	{ ''																	, .T. }, ; //X3_CONDSQL
	{ ''																	, .T. }, ; //X3_CHKSQL
	{ 'N'																	, .T. }, ; //X3_IDXSRV
	{ 'N'																	, .T. }, ; //X3_ORTOGRA
	{ ''																	, .T. }, ; //X3_TELA
	{ ''																	, .T. }, ; //X3_POSLGT
	{ 'N'																	, .T. }, ; //X3_IDXFLD
	{ ''																	, .T. }, ; //X3_AGRUP
	{ 'N'																	, .T. }, ; //X3_MODAL
	{ 'S'																	, .T. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXC'																	, .F. }, ; //X3_ARQUIVO
	{ '12'																	, .F. }, ; //X3_ORDEM
	{ 'AXC_EMAIL'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 30																	, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'E-mail Forn.'														, .F. }, ; //X3_TITULO
	{ 'E-mail Forn.'														, .F. }, ; //X3_TITSPA
	{ 'E-mail Forn.'														, .F. }, ; //X3_TITENG
	{ 'E-mail do Fornecedor'												, .F. }, ; //X3_DESCRIC
	{ 'E-mail do Fornecedor'												, .F. }, ; //X3_DESCSPA
	{ 'E-mail do Fornecedor'												, .F. }, ; //X3_DESCENG
	{ ''																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .T. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(65)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .T. }, ; //X3_VISUAL
	{ 'R'																	, .T. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .T. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXC'																	, .F. }, ; //X3_ARQUIVO
	{ '13'																	, .F. }, ; //X3_ORDEM
	{ 'AXC_CODCOM'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 3																		, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Comprador'															, .F. }, ; //X3_TITULO
	{ 'Comprador'															, .F. }, ; //X3_TITSPA
	{ 'Buyer'																, .F. }, ; //X3_TITENG
	{ 'Comprador'															, .F. }, ; //X3_DESCRIC
	{ 'Comprador'															, .F. }, ; //X3_DESCSPA
	{ 'Buyer'																, .F. }, ; //X3_DESCENG
	{ '@!'																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ 'SY1'																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(65)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ 'S'																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ '€'																	, .F. }, ; //X3_OBRIGAT
	{ 'ExistCpo("SY1",M->AXC_CODCOM,1)'										, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ 'N'																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ 'N'																	, .F. }, ; //X3_MODAL
	{ 'S'																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXC'																	, .F. }, ; //X3_ARQUIVO
	{ '14'																	, .F. }, ; //X3_ORDEM
	{ 'AXC_NOMCOM'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 40																	, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Nome. Comp.'															, .F. }, ; //X3_TITULO
	{ 'Nome. Comp.'															, .F. }, ; //X3_TITSPA
	{ 'Nome. Comp.'															, .F. }, ; //X3_TITENG
	{ 'Nome do Comprador'													, .F. }, ; //X3_DESCRIC
	{ 'Nome do Comprador'													, .F. }, ; //X3_DESCSPA
	{ 'Nome do Comprador'													, .F. }, ; //X3_DESCENG
	{ ''																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ 'IIF(INCLUI,"",POSICIONE("SY1",1,XFILIAL("SY1")+AXC_CODCOM,"Y1_NOME"))'	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(65)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'V'																	, .F. }, ; //X3_VISUAL
	{ 'V'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ 'POSICIONE("SY1",1,XFILIAL("SY1")+AXC_CODCOM,"Y1_NOME")'				, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXC'																	, .F. }, ; //X3_ARQUIVO
	{ '15'																	, .F. }, ; //X3_ORDEM
	{ 'AXC_LOCENT'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 1																		, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Local Entreg'														, .F. }, ; //X3_TITULO
	{ 'Lugar Entreg'														, .F. }, ; //X3_TITSPA
	{ 'Delivery Loc'														, .F. }, ; //X3_TITENG
	{ 'Local de Entrega'													, .F. }, ; //X3_DESCRIC
	{ 'Lugar de entrega'													, .F. }, ; //X3_DESCSPA
	{ 'Delivery Location'													, .F. }, ; //X3_DESCENG
	{ '@!'																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ '"F"'																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(65)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ 'S'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ '€'																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ 'F=Filiais;C=CD'														, .F. }, ; //X3_CBOX
	{ 'F=Filiais;C=CD'														, .F. }, ; //X3_CBOXSPA
	{ 'F=Filiais;C=CD'														, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXC'																	, .F. }, ; //X3_ARQUIVO
	{ '16'																	, .F. }, ; //X3_ORDEM
	{ 'AXC_QUALID'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 1																		, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Qualidade'															, .F. }, ; //X3_TITULO
	{ 'Calidad'																, .F. }, ; //X3_TITSPA
	{ 'Quality'																, .F. }, ; //X3_TITENG
	{ 'Qualidade'															, .F. }, ; //X3_DESCRIC
	{ 'Calidad'																, .F. }, ; //X3_DESCSPA
	{ 'Quality'																, .F. }, ; //X3_DESCENG
	{ '@!'																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128)					, .F. }, ; //X3_USADO
	{ '"A"'																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(65)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ 'A;B;F'																, .F. }, ; //X3_CBOX
	{ 'A;B;F'																, .F. }, ; //X3_CBOXSPA
	{ 'A;B;F'																, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXC'																	, .F. }, ; //X3_ARQUIVO
	{ '17'																	, .F. }, ; //X3_ORDEM
	{ 'AXC_DESCF'															, .F. }, ; //X3_CAMPO
	{ 'N'																	, .F. }, ; //X3_TIPO
	{ 6																		, .F. }, ; //X3_TAMANHO
	{ 2																		, .F. }, ; //X3_DECIMAL
	{ 'Desc.Finance'														, .F. }, ; //X3_TITULO
	{ 'Desc.Financ.'														, .F. }, ; //X3_TITSPA
	{ 'Finances Des'														, .F. }, ; //X3_TITENG
	{ 'Desconto Financeiro'													, .F. }, ; //X3_DESCRIC
	{ 'Descuento financiero'												, .F. }, ; //X3_DESCSPA
	{ 'Finances Desc.'														, .F. }, ; //X3_DESCENG
	{ '@E 999.99'															, .F. }, ; //X3_PICTURE
	{ 'Positivo()'															, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(65)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ 'N'																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ 'N'																	, .F. }, ; //X3_MODAL
	{ 'S'																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXC'																	, .F. }, ; //X3_ARQUIVO
	{ '18'																	, .F. }, ; //X3_ORDEM
	{ 'AXC_TPFRET'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 1																		, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Tipo Frete'															, .F. }, ; //X3_TITULO
	{ 'Tp.Pag.Flete'														, .F. }, ; //X3_TITSPA
	{ 'Freight Type'														, .F. }, ; //X3_TITENG
	{ 'Tipo do Frete Utilizado'												, .F. }, ; //X3_DESCRIC
	{ 'Tipo de Pago de Flete'												, .F. }, ; //X3_DESCSPA
	{ 'Type of Freight'														, .F. }, ; //X3_DESCENG
	{ 'X'																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(65)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ 'F=FOB;C=CIF'															, .F. }, ; //X3_CBOX
	{ 'F=FOB;C=CIF'															, .F. }, ; //X3_CBOXSPA
	{ 'F=FOB;C=CIF'															, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ 'N'																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ '1'																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ 'N'																	, .F. }, ; //X3_MODAL
	{ 'S'																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXC'																	, .F. }, ; //X3_ARQUIVO
	{ '19'																	, .F. }, ; //X3_ORDEM
	{ 'AXC_FRETE'															, .F. }, ; //X3_CAMPO
	{ 'N'																	, .F. }, ; //X3_TIPO
	{ 12																	, .F. }, ; //X3_TAMANHO
	{ 2																		, .F. }, ; //X3_DECIMAL
	{ 'Vlr.Frete'															, .F. }, ; //X3_TITULO
	{ 'Vlr. Flete'															, .F. }, ; //X3_TITSPA
	{ 'Freight Val.'														, .F. }, ; //X3_TITENG
	{ 'Valor do frete combinado'											, .F. }, ; //X3_DESCRIC
	{ 'Valor del Flete Acertado'											, .F. }, ; //X3_DESCSPA
	{ 'Agreed Freight Value'												, .F. }, ; //X3_DESCENG
	{ '@E 999,999,999.99'													, .F. }, ; //X3_PICTURE
	{ 'Positivo()'															, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(65)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ 'N'																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ '1'																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ 'N'																	, .F. }, ; //X3_MODAL
	{ 'S'																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXC'																	, .F. }, ; //X3_ARQUIVO
	{ '20'																	, .F. }, ; //X3_ORDEM
	{ 'AXC_TRANSP'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 6																		, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Cod. Transp.'														, .F. }, ; //X3_TITULO
	{ 'Cod. Transp.'														, .F. }, ; //X3_TITSPA
	{ 'Code Carrier'														, .F. }, ; //X3_TITENG
	{ 'Codigo da Transportadora'											, .F. }, ; //X3_DESCRIC
	{ 'Codigo de la transportado'											, .F. }, ; //X3_DESCSPA
	{ 'Carrier Code'														, .F. }, ; //X3_DESCENG
	{ '@!'																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ 'SA4'																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(65)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ 'S'																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ 'ExistCpo("SA4")'														, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXC'																	, .F. }, ; //X3_ARQUIVO
	{ '21'																	, .F. }, ; //X3_ORDEM
	{ 'AXC_NOMTRA'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 40																	, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Nome Transp.'														, .F. }, ; //X3_TITULO
	{ 'Nomb. Transp'														, .F. }, ; //X3_TITSPA
	{ 'Carrier Name'														, .F. }, ; //X3_TITENG
	{ 'Nome da Transportadora'												, .F. }, ; //X3_DESCRIC
	{ 'Nombre de la transportado'											, .F. }, ; //X3_DESCSPA
	{ 'Carrier Name'														, .F. }, ; //X3_DESCENG
	{ ''																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ 'IIF(INCLUI,"",POSICIONE("SA4",1,XFILIAL("SA4")+AXC_TRANSP,"A4_NOME"))'	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(65)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'V'																	, .F. }, ; //X3_VISUAL
	{ 'V'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ 'POSICIONE("SA4",1,XFILIAL("SA4")+AXC_TRANSP,"A4_NOME")'				, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXC'																	, .F. }, ; //X3_ARQUIVO
	{ '22'																	, .F. }, ; //X3_ORDEM
	{ 'AXC_DTAGE'															, .F. }, ; //X3_CAMPO
	{ 'D'																	, .F. }, ; //X3_TIPO
	{ 8																		, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Agendamento'															, .F. }, ; //X3_TITULO
	{ 'Program. en'															, .F. }, ; //X3_TITSPA
	{ 'Schedule'															, .F. }, ; //X3_TITENG
	{ 'Agendamento'															, .F. }, ; //X3_DESCRIC
	{ 'Program. en agenda'													, .F. }, ; //X3_DESCSPA
	{ 'Schedule'															, .F. }, ; //X3_DESCENG
	{ ''																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(65)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ 'N'																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ 'N'																	, .F. }, ; //X3_MODAL
	{ 'S'																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXC'																	, .F. }, ; //X3_ARQUIVO
	{ '23'																	, .F. }, ; //X3_ORDEM
	{ 'AXC_CDAPR'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 3																		, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Aprovador'															, .F. }, ; //X3_TITULO
	{ 'Aprobador'															, .F. }, ; //X3_TITSPA
	{ 'Approver'															, .F. }, ; //X3_TITENG
	{ 'Aprovador'															, .F. }, ; //X3_DESCRIC
	{ 'Aprobador'															, .F. }, ; //X3_DESCSPA
	{ 'Approver'															, .F. }, ; //X3_DESCENG
	{ '@!'																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ 'SY1'																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(65)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ 'N'																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ 'N'																	, .F. }, ; //X3_MODAL
	{ 'S'																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXC'																	, .F. }, ; //X3_ARQUIVO
	{ '24'																	, .F. }, ; //X3_ORDEM
	{ 'AXC_NOMAPR'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 40																	, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Nome Aprov.'															, .F. }, ; //X3_TITULO
	{ 'Nome Aprov.'															, .F. }, ; //X3_TITSPA
	{ 'Nome Aprov.'															, .F. }, ; //X3_TITENG
	{ 'Nome do Aprovador'													, .F. }, ; //X3_DESCRIC
	{ 'Nome do Aprovador'													, .F. }, ; //X3_DESCSPA
	{ 'Nome do Aprovador'													, .F. }, ; //X3_DESCENG
	{ ''																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128)					, .F. }, ; //X3_USADO
	{ 'IIF(INCLUI,"",POSICIONE("SY1",1,XFILIAL("SY1")+AXC_CDAPR,"Y1_NOME"))'	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(65)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'V'																	, .F. }, ; //X3_VISUAL
	{ 'V'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ 'POSICIONE("SY1",1,XFILIAL("SY1")+AXC_CDAPR,"Y1_NOME")'				, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXC'																	, .F. }, ; //X3_ARQUIVO
	{ '25'																	, .F. }, ; //X3_ORDEM
	{ 'AXC_DTAPR'															, .F. }, ; //X3_CAMPO
	{ 'D'																	, .F. }, ; //X3_TIPO
	{ 8																		, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Dt Aprovacao'														, .F. }, ; //X3_TITULO
	{ 'Fch Aprobaci'														, .F. }, ; //X3_TITSPA
	{ 'Approval Dt'															, .F. }, ; //X3_TITENG
	{ 'Dt Aprovacao'														, .F. }, ; //X3_DESCRIC
	{ 'Fch Aprobacion'														, .F. }, ; //X3_DESCSPA
	{ 'Approval Dt'															, .F. }, ; //X3_DESCENG
	{ ''																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(65)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'V'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ 'N'																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ 'N'																	, .F. }, ; //X3_MODAL
	{ 'S'																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXC'																	, .T. }, ; //X3_ARQUIVO
	{ '26'																	, .T. }, ; //X3_ORDEM
	{ 'AXC_DTINI'															, .T. }, ; //X3_CAMPO
	{ 'D'																	, .T. }, ; //X3_TIPO
	{ 8																		, .T. }, ; //X3_TAMANHO
	{ 0																		, .T. }, ; //X3_DECIMAL
	{ 'Dt.Inicial'															, .T. }, ; //X3_TITULO
	{ 'Dt.Inicial'															, .T. }, ; //X3_TITSPA
	{ 'Dt.Inicial'															, .T. }, ; //X3_TITENG
	{ 'Periodo Inicial Entrega'												, .T. }, ; //X3_DESCRIC
	{ 'Periodo Inicial Entrega'												, .T. }, ; //X3_DESCSPA
	{ 'Periodo Inicial Entrega'												, .T. }, ; //X3_DESCENG
	{ ''																	, .T. }, ; //X3_PICTURE
	{ ''																	, .T. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .T. }, ; //X3_USADO
	{ ''																	, .T. }, ; //X3_RELACAO
	{ ''																	, .T. }, ; //X3_F3
	{ 1																		, .T. }, ; //X3_NIVEL
	{ Chr(254) + Chr(65)													, .T. }, ; //X3_RESERV
	{ ''																	, .T. }, ; //X3_CHECK
	{ ''																	, .T. }, ; //X3_TRIGGER
	{ ''																	, .T. }, ; //X3_PROPRI
	{ 'N'																	, .T. }, ; //X3_BROWSE
	{ 'A'																	, .T. }, ; //X3_VISUAL
	{ 'R'																	, .T. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .T. }, ; //X3_CBOX
	{ ''																	, .T. }, ; //X3_CBOXSPA
	{ ''																	, .T. }, ; //X3_CBOXENG
	{ ''																	, .T. }, ; //X3_PICTVAR
	{ 'lDataIni'															, .F. }, ; //X3_WHEN
	{ ''																	, .T. }, ; //X3_INIBRW
	{ ''																	, .T. }, ; //X3_GRPSXG
	{ ''																	, .T. }, ; //X3_FOLDER
	{ ''																	, .T. }, ; //X3_CONDSQL
	{ ''																	, .T. }, ; //X3_CHKSQL
	{ ''																	, .T. }, ; //X3_IDXSRV
	{ 'N'																	, .T. }, ; //X3_ORTOGRA
	{ ''																	, .T. }, ; //X3_TELA
	{ ''																	, .T. }, ; //X3_POSLGT
	{ 'N'																	, .T. }, ; //X3_IDXFLD
	{ ''																	, .T. }, ; //X3_AGRUP
	{ ''																	, .T. }, ; //X3_MODAL
	{ ''																	, .T. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXC'																	, .T. }, ; //X3_ARQUIVO
	{ '27'																	, .T. }, ; //X3_ORDEM
	{ 'AXC_DATPRF'															, .T. }, ; //X3_CAMPO
	{ 'D'																	, .T. }, ; //X3_TIPO
	{ 8																		, .T. }, ; //X3_TAMANHO
	{ 0																		, .T. }, ; //X3_DECIMAL
	{ 'Dt. Entrega'															, .T. }, ; //X3_TITULO
	{ 'Fch Entrega'															, .T. }, ; //X3_TITSPA
	{ 'Delivery Dt.'														, .T. }, ; //X3_TITENG
	{ 'Data Entrega'														, .T. }, ; //X3_DESCRIC
	{ 'Fecha de Entrega'													, .T. }, ; //X3_DESCSPA
	{ 'Delivery Date'														, .T. }, ; //X3_DESCENG
	{ ''																	, .T. }, ; //X3_PICTURE
	{ ''																	, .T. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .T. }, ; //X3_USADO
	{ ''																	, .T. }, ; //X3_RELACAO
	{ ''																	, .T. }, ; //X3_F3
	{ 1																		, .T. }, ; //X3_NIVEL
	{ Chr(254) + Chr(65)													, .T. }, ; //X3_RESERV
	{ ''																	, .T. }, ; //X3_CHECK
	{ 'S'																	, .T. }, ; //X3_TRIGGER
	{ ''																	, .T. }, ; //X3_PROPRI
	{ 'N'																	, .T. }, ; //X3_BROWSE
	{ 'A'																	, .T. }, ; //X3_VISUAL
	{ 'R'																	, .T. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ 'T_VA102DATA()'														, .F. }, ; //X3_VLDUSER
	{ ''																	, .T. }, ; //X3_CBOX
	{ ''																	, .T. }, ; //X3_CBOXSPA
	{ ''																	, .T. }, ; //X3_CBOXENG
	{ ''																	, .T. }, ; //X3_PICTVAR
	{ 'lDataIni'															, .F. }, ; //X3_WHEN
	{ ''																	, .T. }, ; //X3_INIBRW
	{ ''																	, .T. }, ; //X3_GRPSXG
	{ ''																	, .T. }, ; //X3_FOLDER
	{ ''																	, .T. }, ; //X3_CONDSQL
	{ ''																	, .T. }, ; //X3_CHKSQL
	{ 'N'																	, .T. }, ; //X3_IDXSRV
	{ 'N'																	, .T. }, ; //X3_ORTOGRA
	{ ''																	, .T. }, ; //X3_TELA
	{ '1'																	, .T. }, ; //X3_POSLGT
	{ 'N'																	, .T. }, ; //X3_IDXFLD
	{ ''																	, .T. }, ; //X3_AGRUP
	{ 'N'																	, .T. }, ; //X3_MODAL
	{ 'S'																	, .T. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXC'																	, .F. }, ; //X3_ARQUIVO
	{ '28'																	, .F. }, ; //X3_ORDEM
	{ 'AXC_REPRE'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 1																		, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Represen.'															, .F. }, ; //X3_TITULO
	{ 'Represen.'															, .F. }, ; //X3_TITSPA
	{ 'Represen.'															, .F. }, ; //X3_TITENG
	{ 'Representante'														, .F. }, ; //X3_DESCRIC
	{ 'Representante'														, .F. }, ; //X3_DESCSPA
	{ 'Representante'														, .F. }, ; //X3_DESCENG
	{ ''																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ '"N"'																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(65)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ 'S=Sim;N=Nao'															, .F. }, ; //X3_CBOX
	{ 'S=Si;N=No'															, .F. }, ; //X3_CBOXSPA
	{ 'S=Yes;N=No'															, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXC'																	, .F. }, ; //X3_ARQUIVO
	{ '29'																	, .F. }, ; //X3_ORDEM
	{ 'AXC_FLUXO'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 1																		, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Fluxo Caixa'															, .F. }, ; //X3_TITULO
	{ 'Flujo Caja'															, .F. }, ; //X3_TITSPA
	{ 'Cashflow'															, .F. }, ; //X3_TITENG
	{ 'Fluxo de Caixa (S/N)'												, .F. }, ; //X3_DESCRIC
	{ 'Flujo de Caja (S/N)'													, .F. }, ; //X3_DESCSPA
	{ 'Cashflow (Y/N)'														, .F. }, ; //X3_DESCENG
	{ '@!'																	, .F. }, ; //X3_PICTURE
	{ 'Pertence("SN")'														, .F. }, ; //X3_VALID
	{ Chr(168) + Chr(128) + Chr(144) + Chr(128) + Chr(128) + ;
	Chr(129) + Chr(176) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128)					, .F. }, ; //X3_USADO
	{ '"S"'																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(65)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ ''																	, .F. }, ; //X3_VISUAL
	{ ''																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ 'S=Sim;N=Nao'															, .F. }, ; //X3_CBOX
	{ 'S=Si;N=No'															, .F. }, ; //X3_CBOXSPA
	{ 'S=Yes;N=No'															, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ 'N'																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ '1'																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ 'N'																	, .F. }, ; //X3_MODAL
	{ 'S'																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXC'																	, .F. }, ; //X3_ARQUIVO
	{ '30'																	, .F. }, ; //X3_ORDEM
	{ 'AXC_MOEDA'															, .F. }, ; //X3_CAMPO
	{ 'N'																	, .F. }, ; //X3_TIPO
	{ 2																		, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Moeda'																, .F. }, ; //X3_TITULO
	{ 'Moneda'																, .F. }, ; //X3_TITSPA
	{ 'Currency'															, .F. }, ; //X3_TITENG
	{ 'Moeda'																, .F. }, ; //X3_DESCRIC
	{ 'Moneda'																, .F. }, ; //X3_DESCSPA
	{ 'Currency'															, .F. }, ; //X3_DESCENG
	{ '99'																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128)					, .F. }, ; //X3_USADO
	{ '1'																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(65)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ 'M->AXC_MOEDA <= MoedFin().And. M->AXC_MOEDA <> 0 .And. T_VA102DMoed(M->AXC_MOEDA)', .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ 'N'																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ '1'																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ 'N'																	, .F. }, ; //X3_MODAL
	{ 'S'																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXC'																	, .F. }, ; //X3_ARQUIVO
	{ '31'																	, .F. }, ; //X3_ORDEM
	{ 'AXC_TXMOED'															, .F. }, ; //X3_CAMPO
	{ 'N'																	, .F. }, ; //X3_TIPO
	{ 11																	, .F. }, ; //X3_TAMANHO
	{ 4																		, .F. }, ; //X3_DECIMAL
	{ 'Taxa Moeda'															, .F. }, ; //X3_TITULO
	{ 'Tasa Moneda'															, .F. }, ; //X3_TITSPA
	{ 'Currenc.Rate'														, .F. }, ; //X3_TITENG
	{ 'Taxa Moeda'															, .F. }, ; //X3_DESCRIC
	{ 'Tasa Moneda'															, .F. }, ; //X3_DESCSPA
	{ 'Currency Rate'														, .F. }, ; //X3_DESCENG
	{ '@E 999999.9999'														, .F. }, ; //X3_PICTURE
	{ 'Positivo()'															, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128)					, .F. }, ; //X3_USADO
	{ '1'																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(65)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ ''																	, .F. }, ; //X3_VISUAL
	{ ''																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ 'N'																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ '1'																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ 'N'																	, .F. }, ; //X3_MODAL
	{ 'S'																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXC'																	, .F. }, ; //X3_ARQUIVO
	{ '32'																	, .F. }, ; //X3_ORDEM
	{ 'AXC_DMOEDA'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 15																	, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Desc.Moeda'															, .F. }, ; //X3_TITULO
	{ 'Desc.Moeda'															, .F. }, ; //X3_TITSPA
	{ 'Desc.Moeda'															, .F. }, ; //X3_TITENG
	{ 'Descrição da Moeda'													, .F. }, ; //X3_DESCRIC
	{ 'Descrição da Moeda'													, .F. }, ; //X3_DESCSPA
	{ 'Descrição da Moeda'													, .F. }, ; //X3_DESCENG
	{ ''																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ 'SUPERGETMV("MV_MOEDA"+ALLTRIM(STR(AXC_MOEDA,2)))'					, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(65)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'V'																	, .F. }, ; //X3_VISUAL
	{ 'V'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ 'SuperGetMv("MV_MOEDA"+AllTrim(Str(AXC_MOEDA,2)))'					, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXC'																	, .F. }, ; //X3_ARQUIVO
	{ '33'																	, .F. }, ; //X3_ORDEM
	{ 'AXC_ITEM'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 4																		, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Item'																, .F. }, ; //X3_TITULO
	{ 'Item'																, .F. }, ; //X3_TITSPA
	{ 'Item'																, .F. }, ; //X3_TITENG
	{ 'Item do pedido de compra'											, .F. }, ; //X3_DESCRIC
	{ 'Item del Pedido de Compra'											, .F. }, ; //X3_DESCSPA
	{ 'Purchase Order Item'													, .F. }, ; //X3_DESCENG
	{ '@!'																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(65)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ 'S'																	, .F. }, ; //X3_BROWSE
	{ 'V'																	, .F. }, ; //X3_VISUAL
	{ ''																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ 'N'																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ '1'																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ 'N'																	, .F. }, ; //X3_MODAL
	{ 'S'																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXC'																	, .F. }, ; //X3_ARQUIVO
	{ '34'																	, .F. }, ; //X3_ORDEM
	{ 'AXC_SKU'																, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ nTamSKU																, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Produto'																, .F. }, ; //X3_TITULO
	{ 'Producto'															, .F. }, ; //X3_TITSPA
	{ 'Product'																, .F. }, ; //X3_TITENG
	{ 'Codigo do produto'													, .F. }, ; //X3_DESCRIC
	{ 'Codigo del Producto'													, .F. }, ; //X3_DESCSPA
	{ 'Product Code'														, .F. }, ; //X3_DESCENG
	{ '@!'																	, .F. }, ; //X3_PICTURE
	{ 'A093PROD().And.A120COD().And.A120Tabela() .And. A120Produto(M->AXC_SKU)'	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ 'SB1'																	, .F. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(65)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ 'S'																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ 'S'																	, .F. }, ; //X3_BROWSE
	{ ''																	, .F. }, ; //X3_VISUAL
	{ ''																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ '030'																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ 'S'																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ '1'																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ 'S'																	, .F. }, ; //X3_MODAL
	{ 'S'																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXC'																	, .F. }, ; //X3_ARQUIVO
	{ '35'																	, .F. }, ; //X3_ORDEM
	{ 'AXC_UM'																, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 2																		, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Unidade'																, .F. }, ; //X3_TITULO
	{ 'Unidad'																, .F. }, ; //X3_TITSPA
	{ 'Measure Unit'														, .F. }, ; //X3_TITENG
	{ 'Unidade de medida'													, .F. }, ; //X3_DESCRIC
	{ 'Unidad de Medida'													, .F. }, ; //X3_DESCSPA
	{ 'Unit of Measure'														, .F. }, ; //X3_DESCENG
	{ '@!'																	, .F. }, ; //X3_PICTURE
	{ 'ExistCpo("SAH")'														, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ 'SAH'																	, .F. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(65)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ 'S'																	, .F. }, ; //X3_BROWSE
	{ 'V'																	, .F. }, ; //X3_VISUAL
	{ ''																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ 'N'																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ '1'																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ 'N'																	, .F. }, ; //X3_MODAL
	{ 'S'																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXC'																	, .F. }, ; //X3_ARQUIVO
	{ '36'																	, .F. }, ; //X3_ORDEM
	{ 'AXC_SEGUM'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 2																		, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Segunda UM'															, .F. }, ; //X3_TITULO
	{ 'Segunda U.M.'														, .F. }, ; //X3_TITSPA
	{ '2nd U.Meas.'															, .F. }, ; //X3_TITENG
	{ 'Segunda Unidade de Medida'											, .F. }, ; //X3_DESCRIC
	{ 'Segunda Unidad de Medida'											, .F. }, ; //X3_DESCSPA
	{ '2nd. Unit of Measure'												, .F. }, ; //X3_DESCENG
	{ '@!'																	, .F. }, ; //X3_PICTURE
	{ 'ExistCpo("SAH")'														, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ 'SAH'																	, .F. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(65)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ 'S'																	, .F. }, ; //X3_BROWSE
	{ 'V'																	, .F. }, ; //X3_VISUAL
	{ ''																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ 'N'																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ '1'																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ 'N'																	, .F. }, ; //X3_MODAL
	{ 'S'																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXC'																	, .F. }, ; //X3_ARQUIVO
	{ '37'																	, .F. }, ; //X3_ORDEM
	{ 'AXC_QUANT'															, .F. }, ; //X3_CAMPO
	{ 'N'																	, .F. }, ; //X3_TIPO
	{ 12																	, .F. }, ; //X3_TAMANHO
	{ 2																		, .F. }, ; //X3_DECIMAL
	{ 'Quantidade'															, .F. }, ; //X3_TITULO
	{ 'Cantidad'															, .F. }, ; //X3_TITSPA
	{ 'Quantity'															, .F. }, ; //X3_TITENG
	{ 'Quantidade pedida'													, .F. }, ; //X3_DESCRIC
	{ 'Cantidad Pedida'														, .F. }, ; //X3_DESCSPA
	{ 'Loss Quantity'														, .F. }, ; //X3_DESCENG
	{ '@E 999999999.99'														, .F. }, ; //X3_PICTURE
	{ 'A120QTDGRA().AND.Positivo().And.A120Quant(M->AXC_QUANT).And.a120Tabela()', .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(65)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ 'S'																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ 'S'																	, .F. }, ; //X3_BROWSE
	{ ''																	, .F. }, ; //X3_VISUAL
	{ ''																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ 'N'																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ '1'																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ 'N'																	, .F. }, ; //X3_MODAL
	{ 'S'																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXC'																	, .F. }, ; //X3_ARQUIVO
	{ '38'																	, .F. }, ; //X3_ORDEM
	{ 'AXC_CODTAB'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 3																		, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Tab.Preco'															, .F. }, ; //X3_TITULO
	{ 'Tabl.Precio'															, .F. }, ; //X3_TITSPA
	{ 'Price List'															, .F. }, ; //X3_TITENG
	{ 'Tabela de Preco'														, .F. }, ; //X3_DESCRIC
	{ 'Tabla de Precio'														, .F. }, ; //X3_DESCSPA
	{ 'Price List'															, .F. }, ; //X3_DESCENG
	{ ''																	, .F. }, ; //X3_PICTURE
	{ 'MaVldTabCom(M->cA120Forn,M->cA120Loj,M->C7_CODTAB,M->cCondicao,,M->dA120Emis).And.A120Tabela()', .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ 'AIA'																	, .F. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(65)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ ''																	, .F. }, ; //X3_BROWSE
	{ ''																	, .F. }, ; //X3_VISUAL
	{ ''																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ 'N'																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ '1'																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ 'N'																	, .F. }, ; //X3_MODAL
	{ 'S'																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXC'																	, .F. }, ; //X3_ARQUIVO
	{ '39'																	, .F. }, ; //X3_ORDEM
	{ 'AXC_PRECO'															, .F. }, ; //X3_CAMPO
	{ 'N'																	, .F. }, ; //X3_TIPO
	{ 14																	, .F. }, ; //X3_TAMANHO
	{ 2																		, .F. }, ; //X3_DECIMAL
	{ 'Prc Unitario'														, .F. }, ; //X3_TITULO
	{ 'Prc.Unitario'														, .F. }, ; //X3_TITSPA
	{ 'Unit Price'															, .F. }, ; //X3_TITENG
	{ 'Preco unitario do item'												, .F. }, ; //X3_DESCRIC
	{ 'Precio Unitario del Item'											, .F. }, ; //X3_DESCSPA
	{ 'Unit Price of Item'													, .F. }, ; //X3_DESCENG
	{ '@E 99,999,999,999.99'												, .F. }, ; //X3_PICTURE
	{ 'Positivo().and.A120Preco(M->AXC_PRECO) .And.  MTA121TROP(n)'			, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(65)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ 'S'																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ ''																	, .F. }, ; //X3_VISUAL
	{ ''																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ 'N'																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ '1'																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ 'N'																	, .F. }, ; //X3_MODAL
	{ 'S'																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXC'																	, .F. }, ; //X3_ARQUIVO
	{ '40'																	, .F. }, ; //X3_ORDEM
	{ 'AXC_TOTAL'															, .F. }, ; //X3_CAMPO
	{ 'N'																	, .F. }, ; //X3_TIPO
	{ 14																	, .F. }, ; //X3_TAMANHO
	{ 2																		, .F. }, ; //X3_DECIMAL
	{ 'Vlr.Total'															, .F. }, ; //X3_TITULO
	{ 'Valor Total'															, .F. }, ; //X3_TITSPA
	{ 'Total Value'															, .F. }, ; //X3_TITENG
	{ 'Valor total do item'													, .F. }, ; //X3_DESCRIC
	{ 'Valor Total del Item'												, .F. }, ; //X3_DESCSPA
	{ 'Item Total Value'													, .F. }, ; //X3_DESCENG
	{ '@E 999,999,999.99'													, .F. }, ; //X3_PICTURE
	{ 'A120Total(M->AXC_TOTAL)'												, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(65)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ ''																	, .F. }, ; //X3_VISUAL
	{ ''																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ 'N'																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ '1'																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ 'N'																	, .F. }, ; //X3_MODAL
	{ 'S'																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXC'																	, .F. }, ; //X3_ARQUIVO
	{ '41'																	, .F. }, ; //X3_ORDEM
	{ 'AXC_QTSEGU'															, .F. }, ; //X3_CAMPO
	{ 'N'																	, .F. }, ; //X3_TIPO
	{ 11																	, .F. }, ; //X3_TAMANHO
	{ 2																		, .F. }, ; //X3_DECIMAL
	{ 'Qtd. 2a UM'															, .F. }, ; //X3_TITULO
	{ 'Ctd 2a. UM'															, .F. }, ; //X3_TITSPA
	{ '2nd Unit Mea'														, .F. }, ; //X3_TITENG
	{ 'Qtde na Segunda Unidade'												, .F. }, ; //X3_DESCRIC
	{ 'Cantidad 2a.Unidad Medida'											, .F. }, ; //X3_DESCSPA
	{ 'Quantity in Second Unit'												, .F. }, ; //X3_DESCENG
	{ '@E 99999999.99'														, .F. }, ; //X3_PICTURE
	{ 'A120QtdGra().and.(Positivo().or.Vazio()).and.A100Segum().And.a120Tabela()', .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(65)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ ''																	, .F. }, ; //X3_VISUAL
	{ ''																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ 'N'																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ '1'																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ 'N'																	, .F. }, ; //X3_MODAL
	{ 'S'																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXC'																	, .F. }, ; //X3_ARQUIVO
	{ '42'																	, .F. }, ; //X3_ORDEM
	{ 'AXC_IPI'																, .F. }, ; //X3_CAMPO
	{ 'N'																	, .F. }, ; //X3_TIPO
	{ 5																		, .F. }, ; //X3_TAMANHO
	{ 2																		, .F. }, ; //X3_DECIMAL
	{ 'Aliq. IPI'															, .F. }, ; //X3_TITULO
	{ 'Alic. IPI'															, .F. }, ; //X3_TITSPA
	{ 'IPI Tx Rate'															, .F. }, ; //X3_TITENG
	{ 'Alíquota de IPI'														, .F. }, ; //X3_DESCRIC
	{ 'Alicuota de IPI'														, .F. }, ; //X3_DESCSPA
	{ 'IPI Tax Rate'														, .F. }, ; //X3_DESCENG
	{ '@E 99.99'															, .F. }, ; //X3_PICTURE
	{ 'MaFisRef("IT_ALIQIPI","MT120",M->C7_IPI)'							, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(65)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ ''																	, .F. }, ; //X3_VISUAL
	{ ''																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ 'Positivo()'															, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ 'N'																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ '1'																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ 'N'																	, .F. }, ; //X3_MODAL
	{ 'S'																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXC'																	, .F. }, ; //X3_ARQUIVO
	{ '43'																	, .F. }, ; //X3_ORDEM
	{ 'AXC_LOCAL'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 2																		, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Armazem'																, .F. }, ; //X3_TITULO
	{ 'Deposito'															, .F. }, ; //X3_TITSPA
	{ 'Warehouse'															, .F. }, ; //X3_TITENG
	{ 'Armazem'																, .F. }, ; //X3_DESCRIC
	{ 'Deposito'															, .F. }, ; //X3_DESCSPA
	{ 'Warehouse'															, .F. }, ; //X3_DESCENG
	{ '@!'																	, .F. }, ; //X3_PICTURE
	{ 'ExistCpo("NNR")'														, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ 'NNR'																	, .F. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(65)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ ''																	, .F. }, ; //X3_VISUAL
	{ ''																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ '024'																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ 'N'																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ '1'																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ 'N'																	, .F. }, ; //X3_MODAL
	{ 'S'																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXC'																	, .F. }, ; //X3_ARQUIVO
	{ '44'																	, .F. }, ; //X3_ORDEM
	{ 'AXC_OBS'																, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 30																	, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Observacoes'															, .F. }, ; //X3_TITULO
	{ 'Observac.'															, .F. }, ; //X3_TITSPA
	{ 'Note'																, .F. }, ; //X3_TITENG
	{ 'Observacoes'															, .F. }, ; //X3_DESCRIC
	{ 'Observaciones'														, .F. }, ; //X3_DESCSPA
	{ 'Observations'														, .F. }, ; //X3_DESCENG
	{ '@!'																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(65)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ ''																	, .F. }, ; //X3_VISUAL
	{ ''																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ 'S'																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ '1'																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ 'S'																	, .F. }, ; //X3_MODAL
	{ 'S'																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXC'																	, .F. }, ; //X3_ARQUIVO
	{ '45'																	, .F. }, ; //X3_ORDEM
	{ 'AXC_CC'																, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 9																		, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Centro Custo'														, .F. }, ; //X3_TITULO
	{ 'Centro Costo'														, .F. }, ; //X3_TITSPA
	{ 'Cost Center'															, .F. }, ; //X3_TITENG
	{ 'Centro de Custo'														, .F. }, ; //X3_DESCRIC
	{ 'Centro de Costo'														, .F. }, ; //X3_DESCSPA
	{ 'Cost Center'															, .F. }, ; //X3_DESCENG
	{ '@!'																	, .F. }, ; //X3_PICTURE
	{ 'Vazio() .Or. Ctb105CC()'												, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ 'CTT'																	, .F. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(65)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ ''																	, .F. }, ; //X3_VISUAL
	{ ''																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ '004'																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ 'N'																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ '1'																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ 'N'																	, .F. }, ; //X3_MODAL
	{ 'S'																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXC'																	, .F. }, ; //X3_ARQUIVO
	{ '46'																	, .F. }, ; //X3_ORDEM
	{ 'AXC_CONTA'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 20																	, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Cta Contabil'														, .F. }, ; //X3_TITULO
	{ 'Cta.Contable'														, .F. }, ; //X3_TITSPA
	{ 'Ledger Acct.'														, .F. }, ; //X3_TITENG
	{ 'Conta Contabil do Produto'											, .F. }, ; //X3_DESCRIC
	{ 'Cta.Contable del Producto'											, .F. }, ; //X3_DESCSPA
	{ 'Product Ledger Account'												, .F. }, ; //X3_DESCENG
	{ '@!'																	, .F. }, ; //X3_PICTURE
	{ 'Vazio() .Or. Ctb105Cta()'											, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ 'CT1'																	, .F. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(65)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ ''																	, .F. }, ; //X3_VISUAL
	{ ''																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ '003'																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ 'N'																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ '1'																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ 'N'																	, .F. }, ; //X3_MODAL
	{ 'S'																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXC'																	, .F. }, ; //X3_ARQUIVO
	{ '47'																	, .F. }, ; //X3_ORDEM
	{ 'AXC_ITEMCT'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 9																		, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Item Conta'															, .F. }, ; //X3_TITULO
	{ 'Item Cuenta'															, .F. }, ; //X3_TITSPA
	{ 'Account Item'														, .F. }, ; //X3_TITENG
	{ 'Item da Conta Contabil'												, .F. }, ; //X3_DESCRIC
	{ 'Item de la Cuenta'													, .F. }, ; //X3_DESCSPA
	{ 'Ledger Account Item'													, .F. }, ; //X3_DESCENG
	{ '@!'																	, .F. }, ; //X3_PICTURE
	{ 'Vazio() .Or. Ctb105Item()'											, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ 'CTD'																	, .F. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(65)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ ''																	, .F. }, ; //X3_VISUAL
	{ ''																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ '005'																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ 'N'																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ '1'																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ 'N'																	, .F. }, ; //X3_MODAL
	{ 'S'																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXC'																	, .F. }, ; //X3_ARQUIVO
	{ '48'																	, .F. }, ; //X3_ORDEM
	{ 'AXC_FILENT'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 2																		, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Filial Entr.'														, .F. }, ; //X3_TITULO
	{ 'Suc. Entrega'														, .F. }, ; //X3_TITSPA
	{ 'Branch Deliv'														, .F. }, ; //X3_TITENG
	{ 'Filial para Entrega'													, .F. }, ; //X3_DESCRIC
	{ 'Sucursal para Entrega'												, .F. }, ; //X3_DESCSPA
	{ 'Branch to Delivery'													, .F. }, ; //X3_DESCENG
	{ ''																	, .F. }, ; //X3_PICTURE
	{ 'A120FilEnt(M->AXC_FILENT)'											, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128)					, .F. }, ; //X3_USADO
	{ 'xFilial("AXC")'														, .F. }, ; //X3_RELACAO
	{ 'SM0_01'																, .F. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(65)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ ''																	, .F. }, ; //X3_VISUAL
	{ ''																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ '033'																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ 'N'																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ '1'																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ 'N'																	, .F. }, ; //X3_MODAL
	{ 'S'																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXC'																	, .F. }, ; //X3_ARQUIVO
	{ '49'																	, .F. }, ; //X3_ORDEM
	{ 'AXC_DESC1'															, .F. }, ; //X3_CAMPO
	{ 'N'																	, .F. }, ; //X3_TIPO
	{ 5																		, .F. }, ; //X3_TAMANHO
	{ 2																		, .F. }, ; //X3_DECIMAL
	{ 'Desconto 1'															, .F. }, ; //X3_TITULO
	{ 'Descuento 1'															, .F. }, ; //X3_TITSPA
	{ 'Discount 1'															, .F. }, ; //X3_TITENG
	{ 'Desconto 1 em cascata'												, .F. }, ; //X3_DESCRIC
	{ 'Descuento 1 en Cascada'												, .F. }, ; //X3_DESCSPA
	{ 'Discount 1 in Cascade'												, .F. }, ; //X3_DESCENG
	{ '@E 99.99'															, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(65)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ ''																	, .F. }, ; //X3_VISUAL
	{ ''																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ 'Positivo()'															, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ 'N'																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ '1'																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ 'N'																	, .F. }, ; //X3_MODAL
	{ 'S'																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXC'																	, .F. }, ; //X3_ARQUIVO
	{ '50'																	, .F. }, ; //X3_ORDEM
	{ 'AXC_DESC2'															, .F. }, ; //X3_CAMPO
	{ 'N'																	, .F. }, ; //X3_TIPO
	{ 5																		, .F. }, ; //X3_TAMANHO
	{ 2																		, .F. }, ; //X3_DECIMAL
	{ 'Desconto 2'															, .F. }, ; //X3_TITULO
	{ 'Descuento 2'															, .F. }, ; //X3_TITSPA
	{ 'Discount 2'															, .F. }, ; //X3_TITENG
	{ 'Desconto 2 em cascata'												, .F. }, ; //X3_DESCRIC
	{ 'Descuento 2 en Cascada'												, .F. }, ; //X3_DESCSPA
	{ 'Discount 2 in Cascade'												, .F. }, ; //X3_DESCENG
	{ '@E 99.99'															, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(65)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ ''																	, .F. }, ; //X3_VISUAL
	{ ''																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ 'Positivo()'															, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ 'N'																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ '1'																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ 'N'																	, .F. }, ; //X3_MODAL
	{ 'S'																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXC'																	, .F. }, ; //X3_ARQUIVO
	{ '51'																	, .F. }, ; //X3_ORDEM
	{ 'AXC_DESC3'															, .F. }, ; //X3_CAMPO
	{ 'N'																	, .F. }, ; //X3_TIPO
	{ 5																		, .F. }, ; //X3_TAMANHO
	{ 2																		, .F. }, ; //X3_DECIMAL
	{ 'Desconto 3'															, .F. }, ; //X3_TITULO
	{ 'Descuento 3'															, .F. }, ; //X3_TITSPA
	{ 'Discount 3'															, .F. }, ; //X3_TITENG
	{ 'Desconto 3 em cascata'												, .F. }, ; //X3_DESCRIC
	{ 'Descuento 3 en Cascada'												, .F. }, ; //X3_DESCSPA
	{ 'Discount 3 in Cascade'												, .F. }, ; //X3_DESCENG
	{ '@E 99.99'															, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(65)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ ''																	, .F. }, ; //X3_VISUAL
	{ ''																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ 'Positivo()'															, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ 'N'																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ '1'																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ 'N'																	, .F. }, ; //X3_MODAL
	{ 'S'																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXC'																	, .F. }, ; //X3_ARQUIVO
	{ '52'																	, .F. }, ; //X3_ORDEM
	{ 'AXC_DESCRI'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 30																	, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Descricao'															, .F. }, ; //X3_TITULO
	{ 'Descripcion'															, .F. }, ; //X3_TITSPA
	{ 'Description'															, .F. }, ; //X3_TITENG
	{ 'Descricao do Produto'												, .F. }, ; //X3_DESCRIC
	{ 'Descripcion del Producto'											, .F. }, ; //X3_DESCSPA
	{ 'Description of Product'												, .F. }, ; //X3_DESCENG
	{ '@!'																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(65)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ ''																	, .F. }, ; //X3_VISUAL
	{ ''																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ 'texto()'																, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ 'N'																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ '1'																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ 'N'																	, .F. }, ; //X3_MODAL
	{ 'S'																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXC'																	, .F. }, ; //X3_ARQUIVO
	{ '53'																	, .F. }, ; //X3_ORDEM
	{ 'AXC_VALFRE'															, .F. }, ; //X3_CAMPO
	{ 'N'																	, .F. }, ; //X3_TIPO
	{ 14																	, .F. }, ; //X3_TAMANHO
	{ 2																		, .F. }, ; //X3_DECIMAL
	{ 'Vlr.Frete'															, .F. }, ; //X3_TITULO
	{ 'Vlr.Flete'															, .F. }, ; //X3_TITSPA
	{ 'Freight Val.'														, .F. }, ; //X3_TITENG
	{ 'Valor do frete do item'												, .F. }, ; //X3_DESCRIC
	{ 'Valor del Flete del item'											, .F. }, ; //X3_DESCSPA
	{ 'Item Freight Value'													, .F. }, ; //X3_DESCENG
	{ '@E 999,999,999.99'													, .F. }, ; //X3_PICTURE
	{ 'Positivo()'															, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(65)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ ''																	, .F. }, ; //X3_BROWSE
	{ ''																	, .F. }, ; //X3_VISUAL
	{ ''																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ 'N'																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ '1'																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ 'N'																	, .F. }, ; //X3_MODAL
	{ 'S'																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXC'																	, .F. }, ; //X3_ARQUIVO
	{ '54'																	, .F. }, ; //X3_ORDEM
	{ 'AXC_VLDESC'															, .F. }, ; //X3_CAMPO
	{ 'N'																	, .F. }, ; //X3_TIPO
	{ 14																	, .F. }, ; //X3_TAMANHO
	{ 2																		, .F. }, ; //X3_DECIMAL
	{ 'Vl. Desconto'														, .F. }, ; //X3_TITULO
	{ 'Vl.Descuento'														, .F. }, ; //X3_TITSPA
	{ 'Discount Val'														, .F. }, ; //X3_TITENG
	{ 'Valor do Desconto do item'											, .F. }, ; //X3_DESCRIC
	{ 'Valor del Descuento'													, .F. }, ; //X3_DESCSPA
	{ 'Discount Value'														, .F. }, ; //X3_DESCENG
	{ '@E 999,999,999.99'													, .F. }, ; //X3_PICTURE
	{ 'Positivo().And.A120ZeraDesc()'										, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(65)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ 'S'																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ ''																	, .F. }, ; //X3_VISUAL
	{ ''																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ 'N'																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ '1'																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ 'N'																	, .F. }, ; //X3_MODAL
	{ 'S'																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXC'																	, .F. }, ; //X3_ARQUIVO
	{ '55'																	, .F. }, ; //X3_ORDEM
	{ 'AXC_CONAPR'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 1																		, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Controle Ap.'														, .F. }, ; //X3_TITULO
	{ 'Control Ap.'															, .F. }, ; //X3_TITSPA
	{ 'Approv Contr'														, .F. }, ; //X3_TITENG
	{ 'Controle de Aprovacao'												, .F. }, ; //X3_DESCRIC
	{ 'Control de Aprobacion'												, .F. }, ; //X3_DESCSPA
	{ 'Approval Control'													, .F. }, ; //X3_DESCENG
	{ '@!'																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(144) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(65)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'V'																	, .F. }, ; //X3_VISUAL
	{ ''																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ 'N'																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ '1'																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ 'N'																	, .F. }, ; //X3_MODAL
	{ 'S'																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXC'																	, .F. }, ; //X3_ARQUIVO
	{ '56'																	, .F. }, ; //X3_ORDEM
	{ 'AXC_USER'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 6																		, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Cod. Usuario'														, .F. }, ; //X3_TITULO
	{ 'Usuario'																, .F. }, ; //X3_TITSPA
	{ 'User´s Code'															, .F. }, ; //X3_TITENG
	{ 'Codigo do Usuario'													, .F. }, ; //X3_DESCRIC
	{ 'Codigo del Usuario'													, .F. }, ; //X3_DESCSPA
	{ 'Code of the User'													, .F. }, ; //X3_DESCENG
	{ '@!'																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(65)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'V'																	, .F. }, ; //X3_VISUAL
	{ ''																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ 'N'																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ '1'																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ 'N'																	, .F. }, ; //X3_MODAL
	{ 'S'																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXC'																	, .F. }, ; //X3_ARQUIVO
	{ '57'																	, .F. }, ; //X3_ORDEM
	{ 'AXC_VALIPI'															, .F. }, ; //X3_CAMPO
	{ 'N'																	, .F. }, ; //X3_TIPO
	{ 14																	, .F. }, ; //X3_TAMANHO
	{ 2																		, .F. }, ; //X3_DECIMAL
	{ 'Vlr.IPI'																, .F. }, ; //X3_TITULO
	{ 'Vlr.IPI'																, .F. }, ; //X3_TITSPA
	{ 'IPI Value'															, .F. }, ; //X3_TITENG
	{ 'Valor do IPI do Item'												, .F. }, ; //X3_DESCRIC
	{ 'Valor de IPI del Item'												, .F. }, ; //X3_DESCSPA
	{ 'Item IPI Value'														, .F. }, ; //X3_DESCENG
	{ '@E 999,999,999.99'													, .F. }, ; //X3_PICTURE
	{ 'Positivo()'															, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(65)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ ''																	, .F. }, ; //X3_VISUAL
	{ ''																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ 'N'																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ '1'																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ 'N'																	, .F. }, ; //X3_MODAL
	{ 'S'																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXC'																	, .F. }, ; //X3_ARQUIVO
	{ '58'																	, .F. }, ; //X3_ORDEM
	{ 'AXC_VALICM'															, .F. }, ; //X3_CAMPO
	{ 'N'																	, .F. }, ; //X3_TIPO
	{ 14																	, .F. }, ; //X3_TAMANHO
	{ 2																		, .F. }, ; //X3_DECIMAL
	{ 'Vlr.ICMS'															, .F. }, ; //X3_TITULO
	{ 'Vlr. ICMS'															, .F. }, ; //X3_TITSPA
	{ 'ICMS Value'															, .F. }, ; //X3_TITENG
	{ 'Valor do ICMS do item'												, .F. }, ; //X3_DESCRIC
	{ 'Valor del ICMS del item'												, .F. }, ; //X3_DESCSPA
	{ 'Item ICMS Value'														, .F. }, ; //X3_DESCENG
	{ '@E 999,999,999.99'													, .F. }, ; //X3_PICTURE
	{ 'Positivo()'															, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(65)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ ''																	, .F. }, ; //X3_VISUAL
	{ ''																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ 'N'																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ '1'																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ 'N'																	, .F. }, ; //X3_MODAL
	{ 'S'																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXC'																	, .F. }, ; //X3_ARQUIVO
	{ '59'																	, .F. }, ; //X3_ORDEM
	{ 'AXC_DESC'															, .F. }, ; //X3_CAMPO
	{ 'N'																	, .F. }, ; //X3_TIPO
	{ 5																		, .F. }, ; //X3_TAMANHO
	{ 2																		, .F. }, ; //X3_DECIMAL
	{ '% Desc.Item'															, .F. }, ; //X3_TITULO
	{ '% Desc.Item'															, .F. }, ; //X3_TITSPA
	{ '%Disc. Item'															, .F. }, ; //X3_TITENG
	{ 'Desconto no item'													, .F. }, ; //X3_DESCRIC
	{ 'Descuento en el Item'												, .F. }, ; //X3_DESCSPA
	{ 'Discount on the item'												, .F. }, ; //X3_DESCENG
	{ '@E 99.99'															, .F. }, ; //X3_PICTURE
	{ 'Positivo()'															, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(65)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ 'S'																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ ''																	, .F. }, ; //X3_VISUAL
	{ ''																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ 'N'																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ '1'																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ 'N'																	, .F. }, ; //X3_MODAL
	{ 'S'																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXC'																	, .F. }, ; //X3_ARQUIVO
	{ '60'																	, .F. }, ; //X3_ORDEM
	{ 'AXC_PICM'															, .F. }, ; //X3_CAMPO
	{ 'N'																	, .F. }, ; //X3_TIPO
	{ 5																		, .F. }, ; //X3_TAMANHO
	{ 2																		, .F. }, ; //X3_DECIMAL
	{ 'Aliq.ICMS'															, .F. }, ; //X3_TITULO
	{ 'Alic. ICMS'															, .F. }, ; //X3_TITSPA
	{ 'ICMS TaxRate'														, .F. }, ; //X3_TITENG
	{ 'Aliquota de ICMS'													, .F. }, ; //X3_DESCRIC
	{ 'Alicuota de ICMS'													, .F. }, ; //X3_DESCSPA
	{ 'ICMS Tax Rate'														, .F. }, ; //X3_DESCENG
	{ '@E 99.99'															, .F. }, ; //X3_PICTURE
	{ 'Positivo().And.VldAliqIcm(M->AXC_PICM)'								, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(65)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ ''																	, .F. }, ; //X3_VISUAL
	{ ''																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ 'N'																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ '1'																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ 'N'																	, .F. }, ; //X3_MODAL
	{ 'S'																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXC'																	, .F. }, ; //X3_ARQUIVO
	{ '61'																	, .F. }, ; //X3_ORDEM
	{ 'AXC_DESPES'															, .F. }, ; //X3_CAMPO
	{ 'N'																	, .F. }, ; //X3_TIPO
	{ 14																	, .F. }, ; //X3_TAMANHO
	{ 2																		, .F. }, ; //X3_DECIMAL
	{ 'Vlr.Despesas'														, .F. }, ; //X3_TITULO
	{ 'Vlr.Gastos'															, .F. }, ; //X3_TITSPA
	{ 'Expenses Vl.'														, .F. }, ; //X3_TITENG
	{ 'Valor das Despesas'													, .F. }, ; //X3_DESCRIC
	{ 'Valor de los Gastos'													, .F. }, ; //X3_DESCSPA
	{ 'Expenses Value'														, .F. }, ; //X3_DESCENG
	{ '@E 999,999,999.99'													, .F. }, ; //X3_PICTURE
	{ 'Positivo()'															, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(65)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ ''																	, .F. }, ; //X3_VISUAL
	{ ''																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ 'N'																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ '1'																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ 'N'																	, .F. }, ; //X3_MODAL
	{ 'S'																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXC'																	, .F. }, ; //X3_ARQUIVO
	{ '62'																	, .F. }, ; //X3_ORDEM
	{ 'AXC_SOLICI'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 30																	, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Solicitante'															, .F. }, ; //X3_TITULO
	{ 'Solicitante'															, .F. }, ; //X3_TITSPA
	{ 'Requestor'															, .F. }, ; //X3_TITENG
	{ 'Nome Solicitante'													, .F. }, ; //X3_DESCRIC
	{ 'Nombre solicitante'													, .F. }, ; //X3_DESCSPA
	{ 'Requestor Name'														, .F. }, ; //X3_DESCENG
	{ '@!'																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(65)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'V'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ 'N'																	, .F. }, ; //X3_IDXSRV
	{ ''																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ '1'																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ 'N'																	, .F. }, ; //X3_MODAL
	{ 'S'																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXC'																	, .F. }, ; //X3_ARQUIVO
	{ '63'																	, .F. }, ; //X3_ORDEM
	{ 'AXC_GRADE'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 1																		, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Grade'																, .F. }, ; //X3_TITULO
	{ 'Grilla'																, .F. }, ; //X3_TITSPA
	{ 'Grid'																, .F. }, ; //X3_TITENG
	{ 'Grade'																, .F. }, ; //X3_DESCRIC
	{ 'Grilla'																, .F. }, ; //X3_DESCSPA
	{ 'Grid'																, .F. }, ; //X3_DESCENG
	{ 'Grade'																, .F. }, ; //X3_PICTURE
	{ 'Pertence("S N")'														, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(168)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(65)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'V'																	, .F. }, ; //X3_VISUAL
	{ ''																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ 'S=Sim;N=Nao'															, .F. }, ; //X3_CBOX
	{ 'S=Si;N=No'															, .F. }, ; //X3_CBOXSPA
	{ 'S=Yes;N=No'															, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ 'N'																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ '1'																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ 'N'																	, .F. }, ; //X3_MODAL
	{ 'S'																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXC'																	, .F. }, ; //X3_ARQUIVO
	{ '64'																	, .F. }, ; //X3_ORDEM
	{ 'AXC_ITEMGR'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 3																		, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Item grade'															, .F. }, ; //X3_TITULO
	{ 'Item grilla'															, .F. }, ; //X3_TITSPA
	{ 'Grid item'															, .F. }, ; //X3_TITENG
	{ 'Item da grade'														, .F. }, ; //X3_DESCRIC
	{ 'Item de grilla'														, .F. }, ; //X3_DESCSPA
	{ 'Grid item'															, .F. }, ; //X3_DESCENG
	{ '@!'																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(168)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(65)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'V'																	, .F. }, ; //X3_VISUAL
	{ ''																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ 'N'																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ '1'																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ 'N'																	, .F. }, ; //X3_MODAL
	{ 'S'																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXC'																	, .F. }, ; //X3_ARQUIVO
	{ '65'																	, .F. }, ; //X3_ORDEM
	{ 'AXC_CODGRP'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 4																		, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Grupo'																, .F. }, ; //X3_TITULO
	{ 'Grupo'																, .F. }, ; //X3_TITSPA
	{ 'Group'																, .F. }, ; //X3_TITENG
	{ 'Grupo Veiculos/Oficina'												, .F. }, ; //X3_DESCRIC
	{ 'Grupo Vehiculos/Taller'												, .F. }, ; //X3_DESCSPA
	{ 'Vehicle/Repair Shop Group'											, .F. }, ; //X3_DESCENG
	{ '@!!!!'																, .F. }, ; //X3_PICTURE
	{ 'VldAuxCod1("AXC_CODGRP","AXC_CODITE")'								, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128)					, .F. }, ; //X3_USADO
	{ 'IniAuxCod(AXC->AXC_SKU,"AXC_CODGRP")'								, .F. }, ; //X3_RELACAO
	{ 'SBM'																	, .F. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(65)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ 'S'																	, .F. }, ; //X3_BROWSE
	{ ''																	, .F. }, ; //X3_VISUAL
	{ 'V'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ 'IniAuxCod(AXC->AXC_SKU,"AXC_CODGRP")'								, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ 'N'																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ '1'																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ 'N'																	, .F. }, ; //X3_MODAL
	{ 'S'																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXC'																	, .F. }, ; //X3_ARQUIVO
	{ '66'																	, .F. }, ; //X3_ORDEM
	{ 'AXC_ORIGIM'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 3																		, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Origem'																, .F. }, ; //X3_TITULO
	{ 'Origen'																, .F. }, ; //X3_TITSPA
	{ 'Origin'																, .F. }, ; //X3_TITENG
	{ 'Origem'																, .F. }, ; //X3_DESCRIC
	{ 'Origen'																, .F. }, ; //X3_DESCSPA
	{ 'Origin'																, .F. }, ; //X3_DESCENG
	{ '@!'																	, .F. }, ; //X3_PICTURE
	{ 'ExistCpo("DBD",M->AXC_ORIGIM,2)'										, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ 'DBD'																	, .F. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(65)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ 'S'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ 'N'																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ '1'																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ 'N'																	, .F. }, ; //X3_MODAL
	{ 'S'																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXC'																	, .F. }, ; //X3_ARQUIVO
	{ '67'																	, .F. }, ; //X3_ORDEM
	{ 'AXC_COMPRA'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 3																		, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Cod.Comprad.'														, .F. }, ; //X3_TITULO
	{ 'Cod.Comprad.'														, .F. }, ; //X3_TITSPA
	{ 'Buyer Cd'															, .F. }, ; //X3_TITENG
	{ 'Comprador'															, .F. }, ; //X3_DESCRIC
	{ 'Comprador'															, .F. }, ; //X3_DESCSPA
	{ 'Buyer'																, .F. }, ; //X3_DESCENG
	{ '@!'																	, .F. }, ; //X3_PICTURE
	{ 'ExistCpo("SY1",M->AXC_COMPRA)'										, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ 'SY1'																	, .F. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(65)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ 'N'																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ '1'																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ 'N'																	, .F. }, ; //X3_MODAL
	{ 'S'																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXC'																	, .F. }, ; //X3_ARQUIVO
	{ '68'																	, .F. }, ; //X3_ORDEM
	{ 'AXC_ARMAZE'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 7																		, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Armazem'																, .F. }, ; //X3_TITULO
	{ 'Almacen'																, .F. }, ; //X3_TITSPA
	{ 'Warehouse'															, .F. }, ; //X3_TITENG
	{ 'Armazem'																, .F. }, ; //X3_DESCRIC
	{ 'Almacen'																, .F. }, ; //X3_DESCSPA
	{ 'Warehouse'															, .F. }, ; //X3_DESCENG
	{ '9999999'																, .F. }, ; //X3_PICTURE
	{ 'Vazio().Or.ExistCpo("DBE",M->AXC_ARMAZE)'							, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ 'DBEADU'																, .F. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(65)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ 'N'																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ '1'																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ 'N'																	, .F. }, ; //X3_MODAL
	{ 'S'																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXC'																	, .F. }, ; //X3_ARQUIVO
	{ '69'																	, .F. }, ; //X3_ORDEM
	{ 'AXC_FABRIC'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 6																		, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Fabricante'															, .F. }, ; //X3_TITULO
	{ 'Fabricante'															, .F. }, ; //X3_TITSPA
	{ 'Manufacturer'														, .F. }, ; //X3_TITENG
	{ 'Fabricante'															, .F. }, ; //X3_DESCRIC
	{ 'Fabricante'															, .F. }, ; //X3_DESCSPA
	{ 'Manufacturer'														, .F. }, ; //X3_DESCENG
	{ '@!'																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(65)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'V'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ '001'																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ 'N'																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ '1'																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ 'N'																	, .F. }, ; //X3_MODAL
	{ 'S'																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXC'																	, .F. }, ; //X3_ARQUIVO
	{ '70'																	, .F. }, ; //X3_ORDEM
	{ 'AXC_FILCEN'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 2																		, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Fil.Central.'														, .F. }, ; //X3_TITULO
	{ 'Suc.Central.'														, .F. }, ; //X3_TITSPA
	{ 'Cent.Branch'															, .F. }, ; //X3_TITENG
	{ 'Fil.Centraliz.Ped.Compra'											, .F. }, ; //X3_DESCRIC
	{ 'Suc.Centraliz.Ped.Compra'											, .F. }, ; //X3_DESCSPA
	{ 'Purch.Ord.Centered Branch'											, .F. }, ; //X3_DESCENG
	{ ''																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(65)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ ''																	, .F. }, ; //X3_BROWSE
	{ ''																	, .F. }, ; //X3_VISUAL
	{ ''																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ '033'																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ 'N'																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ '1'																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ 'N'																	, .F. }, ; //X3_MODAL
	{ 'S'																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXC'																	, .F. }, ; //X3_ARQUIVO
	{ '71'																	, .F. }, ; //X3_ORDEM
	{ 'AXC_PRODP'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ nTamPai																, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Produto Pai'															, .F. }, ; //X3_TITULO
	{ 'Prod Princip'														, .F. }, ; //X3_TITSPA
	{ 'Parent Produ'														, .F. }, ; //X3_TITENG
	{ 'Produto Pai'															, .F. }, ; //X3_DESCRIC
	{ 'Prod Principal'														, .F. }, ; //X3_DESCSPA
	{ 'Parent Product'														, .F. }, ; //X3_DESCENG
	{ ''																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(65)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ 'S'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ 'G01'																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXC'																	, .F. }, ; //X3_ARQUIVO
	{ '72'																	, .F. }, ; //X3_ORDEM
	{ 'AXC_LOJFAB'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ nTamLoja																, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Fabric. Loja'														, .F. }, ; //X3_TITULO
	{ 'Fabric. Tda.'														, .F. }, ; //X3_TITSPA
	{ 'Unit Manuf.'															, .F. }, ; //X3_TITENG
	{ 'Loja do Fabricante'													, .F. }, ; //X3_DESCRIC
	{ 'Tienda del Fabricante'												, .F. }, ; //X3_DESCSPA
	{ 'Manufacturer Unit'													, .F. }, ; //X3_DESCENG
	{ '@!'																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(65)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'V'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ '002'																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ 'N'																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ '1'																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ 'N'																	, .F. }, ; //X3_MODAL
	{ 'S'																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXC'																	, .F. }, ; //X3_ARQUIVO
	{ '73'																	, .F. }, ; //X3_ORDEM
	{ 'AXC_PACK'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 4																		, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Packs'																, .F. }, ; //X3_TITULO
	{ 'Packs'																, .F. }, ; //X3_TITSPA
	{ 'Packs'																, .F. }, ; //X3_TITENG
	{ 'Packs Padroes da grade'												, .F. }, ; //X3_DESCRIC
	{ 'Packs estandar de la gril'											, .F. }, ; //X3_DESCSPA
	{ 'Packs Grid Standards'												, .F. }, ; //X3_DESCENG
	{ '@!'																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(65)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXC'																	, .F. }, ; //X3_ARQUIVO
	{ '74'																	, .F. }, ; //X3_ORDEM
	{ 'AXC_MULTI'															, .F. }, ; //X3_CAMPO
	{ 'N'																	, .F. }, ; //X3_TIPO
	{ 3																		, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Mult. Grade'															, .F. }, ; //X3_TITULO
	{ 'Mult. Grilla'														, .F. }, ; //X3_TITSPA
	{ 'Mult. Grid'															, .F. }, ; //X3_TITENG
	{ 'Mult. Grade'															, .F. }, ; //X3_DESCRIC
	{ 'Multiplicador de la grill'											, .F. }, ; //X3_DESCSPA
	{ 'Mult. Grid'															, .F. }, ; //X3_DESCENG
	{ '@E 999'																, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(65)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXC'																	, .T. }, ; //X3_ARQUIVO
	{ '75'																	, .T. }, ; //X3_ORDEM
	{ 'AXC_BONIFI'															, .T. }, ; //X3_CAMPO
	{ 'C'																	, .T. }, ; //X3_TIPO
	{ 1																		, .T. }, ; //X3_TAMANHO
	{ 0																		, .T. }, ; //X3_DECIMAL
	{ 'Bonificado'															, .T. }, ; //X3_TITULO
	{ 'Bonificado'															, .T. }, ; //X3_TITSPA
	{ 'Bonificado'															, .T. }, ; //X3_TITENG
	{ 'Pedido Bonificado'													, .T. }, ; //X3_DESCRIC
	{ 'Pedido Bonificado'													, .T. }, ; //X3_DESCSPA
	{ 'Pedido Bonificado'													, .T. }, ; //X3_DESCENG
	{ '@!'																	, .T. }, ; //X3_PICTURE
	{ ''																	, .T. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .T. }, ; //X3_USADO
	{ '"N"'																	, .T. }, ; //X3_RELACAO
	{ ''																	, .T. }, ; //X3_F3
	{ 1																		, .T. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .T. }, ; //X3_RESERV
	{ ''																	, .T. }, ; //X3_CHECK
	{ ''																	, .T. }, ; //X3_TRIGGER
	{ 'U'																	, .T. }, ; //X3_PROPRI
	{ 'S'																	, .T. }, ; //X3_BROWSE
	{ 'A'																	, .T. }, ; //X3_VISUAL
	{ 'R'																	, .T. }, ; //X3_CONTEXT
	{ '€'																	, .F. }, ; //X3_OBRIGAT
	{ 'PERTENCE("SN")'														, .F. }, ; //X3_VLDUSER
	{ 'S=Sim;N=Nao'															, .T. }, ; //X3_CBOX
	{ ''																	, .T. }, ; //X3_CBOXSPA
	{ ''																	, .T. }, ; //X3_CBOXENG
	{ ''																	, .T. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .T. }, ; //X3_INIBRW
	{ ''																	, .T. }, ; //X3_GRPSXG
	{ ''																	, .T. }, ; //X3_FOLDER
	{ ''																	, .T. }, ; //X3_CONDSQL
	{ ''																	, .T. }, ; //X3_CHKSQL
	{ ''																	, .T. }, ; //X3_IDXSRV
	{ 'N'																	, .T. }, ; //X3_ORTOGRA
	{ ''																	, .T. }, ; //X3_TELA
	{ ''																	, .T. }, ; //X3_POSLGT
	{ 'N'																	, .T. }, ; //X3_IDXFLD
	{ ''																	, .T. }, ; //X3_AGRUP
	{ ''																	, .T. }, ; //X3_MODAL
	{ ''																	, .T. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXC'																	, .T. }, ; //X3_ARQUIVO
	{ '76'																	, .T. }, ; //X3_ORDEM
	{ 'AXC_CONSI'															, .T. }, ; //X3_CAMPO
	{ 'C'																	, .T. }, ; //X3_TIPO
	{ 1																		, .T. }, ; //X3_TAMANHO
	{ 0																		, .T. }, ; //X3_DECIMAL
	{ 'Consignado'															, .T. }, ; //X3_TITULO
	{ 'Consignado'															, .T. }, ; //X3_TITSPA
	{ 'Consignee'															, .T. }, ; //X3_TITENG
	{ 'Consignado'															, .T. }, ; //X3_DESCRIC
	{ 'Consignado'															, .T. }, ; //X3_DESCSPA
	{ 'Consignee'															, .T. }, ; //X3_DESCENG
	{ '@!'																	, .T. }, ; //X3_PICTURE
	{ ''																	, .T. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .T. }, ; //X3_USADO
	{ '"N"'																	, .T. }, ; //X3_RELACAO
	{ ''																	, .T. }, ; //X3_F3
	{ 0																		, .T. }, ; //X3_NIVEL
	{ Chr(254) + Chr(65)													, .T. }, ; //X3_RESERV
	{ ''																	, .T. }, ; //X3_CHECK
	{ ''																	, .T. }, ; //X3_TRIGGER
	{ ''																	, .T. }, ; //X3_PROPRI
	{ 'N'																	, .T. }, ; //X3_BROWSE
	{ 'V'																	, .T. }, ; //X3_VISUAL
	{ 'R'																	, .T. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ 'S=Sim;N=Nao'															, .T. }, ; //X3_CBOX
	{ 'S=Si;N=No'															, .T. }, ; //X3_CBOXSPA
	{ 'S=Yes;N=No'															, .T. }, ; //X3_CBOXENG
	{ ''																	, .T. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .T. }, ; //X3_INIBRW
	{ ''																	, .T. }, ; //X3_GRPSXG
	{ ''																	, .T. }, ; //X3_FOLDER
	{ ''																	, .T. }, ; //X3_CONDSQL
	{ ''																	, .T. }, ; //X3_CHKSQL
	{ 'N'																	, .T. }, ; //X3_IDXSRV
	{ 'N'																	, .T. }, ; //X3_ORTOGRA
	{ ''																	, .T. }, ; //X3_TELA
	{ ''																	, .T. }, ; //X3_POSLGT
	{ 'N'																	, .T. }, ; //X3_IDXFLD
	{ ''																	, .T. }, ; //X3_AGRUP
	{ 'N'																	, .T. }, ; //X3_MODAL
	{ 'S'																	, .T. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXC'																	, .F. }, ; //X3_ARQUIVO
	{ '76'																	, .F. }, ; //X3_ORDEM
	{ 'AXC_CODINT'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 6																		, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Pedido Clien'														, .F. }, ; //X3_TITULO
	{ 'Pedido Clien'														, .F. }, ; //X3_TITSPA
	{ 'Customer Ord'														, .F. }, ; //X3_TITENG
	{ 'Pedido Cliente'														, .F. }, ; //X3_DESCRIC
	{ 'Pedido cliente'														, .F. }, ; //X3_DESCSPA
	{ 'Customer Order'														, .F. }, ; //X3_DESCENG
	{ '@!'																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(65)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ 'S'																	, .F. }, ; //X3_BROWSE
	{ 'V'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXC'																	, .F. }, ; //X3_ARQUIVO
	{ '77'																	, .F. }, ; //X3_ORDEM
	{ 'AXC_BLOCK'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 1																		, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Bloq.Meta'															, .F. }, ; //X3_TITULO
	{ 'Bloq.Meta'															, .F. }, ; //X3_TITSPA
	{ 'Bloq.Meta'															, .F. }, ; //X3_TITENG
	{ 'Bloqueio por Meta'													, .F. }, ; //X3_DESCRIC
	{ 'Bloqueio por Meta'													, .F. }, ; //X3_DESCSPA
	{ 'Bloqueio por Meta'													, .F. }, ; //X3_DESCENG
	{ ''																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(65)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXC'																	, .F. }, ; //X3_ARQUIVO
	{ '78'																	, .F. }, ; //X3_ORDEM
	{ 'AXC_DESCCA'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 50																	, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Desconto 2'															, .F. }, ; //X3_TITULO
	{ 'Descuento 2'															, .F. }, ; //X3_TITSPA
	{ 'Discount 2'															, .F. }, ; //X3_TITENG
	{ 'Desconto 2'															, .F. }, ; //X3_DESCRIC
	{ 'Descuento 2'															, .F. }, ; //X3_DESCSPA
	{ 'Discount 2'															, .F. }, ; //X3_DESCENG
	{ '@S20'																, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(65)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXC'																	, .F. }, ; //X3_ARQUIVO
	{ '79'																	, .F. }, ; //X3_ORDEM
	{ 'AXC_PERCE'															, .F. }, ; //X3_CAMPO
	{ 'N'																	, .F. }, ; //X3_TIPO
	{ 6																		, .F. }, ; //X3_TAMANHO
	{ 2																		, .F. }, ; //X3_DECIMAL
	{ '% Qualidade'															, .F. }, ; //X3_TITULO
	{ '% Calidad'															, .F. }, ; //X3_TITSPA
	{ '% Quality'															, .F. }, ; //X3_TITENG
	{ '% Qualidade'															, .F. }, ; //X3_DESCRIC
	{ '% Calidad'															, .F. }, ; //X3_DESCSPA
	{ '% Quality'															, .F. }, ; //X3_DESCENG
	{ '@E 999.99'															, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(65)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXC'																	, .F. }, ; //X3_ARQUIVO
	{ '80'																	, .F. }, ; //X3_ORDEM
	{ 'AXC_ACREP'															, .F. }, ; //X3_CAMPO
	{ 'N'																	, .F. }, ; //X3_TIPO
	{ 5																		, .F. }, ; //X3_TAMANHO
	{ 2																		, .F. }, ; //X3_DECIMAL
	{ 'Acrescimo'															, .F. }, ; //X3_TITULO
	{ 'Aumento'																, .F. }, ; //X3_TITSPA
	{ 'Addition'															, .F. }, ; //X3_TITENG
	{ 'Acrescimo'															, .F. }, ; //X3_DESCRIC
	{ 'Aumento'																, .F. }, ; //X3_DESCSPA
	{ 'Addition'															, .F. }, ; //X3_DESCENG
	{ '@E 99.99'															, .F. }, ; //X3_PICTURE
	{ 'Positivo()'															, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(65)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ 'S'																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'V'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ 'N'																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ 'N'																	, .F. }, ; //X3_MODAL
	{ 'S'																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXC'																	, .F. }, ; //X3_ARQUIVO
	{ '81'																	, .F. }, ; //X3_ORDEM
	{ 'AXC_DESCP'															, .F. }, ; //X3_CAMPO
	{ 'N'																	, .F. }, ; //X3_TIPO
	{ 5																		, .F. }, ; //X3_TAMANHO
	{ 2																		, .F. }, ; //X3_DECIMAL
	{ 'Desconto'															, .F. }, ; //X3_TITULO
	{ 'Descuento'															, .F. }, ; //X3_TITSPA
	{ 'Discount'															, .F. }, ; //X3_TITENG
	{ 'Desconto'															, .F. }, ; //X3_DESCRIC
	{ 'Descuento'															, .F. }, ; //X3_DESCSPA
	{ 'Discount'															, .F. }, ; //X3_DESCENG
	{ '@E 99.99'															, .F. }, ; //X3_PICTURE
	{ 'Positivo()'															, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(65)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ 'S'																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'V'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ 'N'																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ 'N'																	, .F. }, ; //X3_MODAL
	{ 'S'																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXC'																	, .F. }, ; //X3_ARQUIVO
	{ '82'																	, .F. }, ; //X3_ORDEM
	{ 'AXC_01MKP'															, .F. }, ; //X3_CAMPO
	{ 'N'																	, .F. }, ; //X3_TIPO
	{ 12																	, .F. }, ; //X3_TAMANHO
	{ 2																		, .F. }, ; //X3_DECIMAL
	{ '% Mkp Venda'															, .F. }, ; //X3_TITULO
	{ '% Mkp Venta'															, .F. }, ; //X3_TITSPA
	{ 'Sales Mkp %'															, .F. }, ; //X3_TITENG
	{ '% Markup de Venda'													, .F. }, ; //X3_DESCRIC
	{ '% Markup de venta'													, .F. }, ; //X3_DESCSPA
	{ 'Sales Markup %'														, .F. }, ; //X3_DESCENG
	{ '@E 999,999,999.99'													, .F. }, ; //X3_PICTURE
	{ 'Positivo()'															, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(65)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'V'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ 'N'																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ 'N'																	, .F. }, ; //X3_MODAL
	{ 'S'																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXC'																	, .F. }, ; //X3_ARQUIVO
	{ '83'																	, .F. }, ; //X3_ORDEM
	{ 'AXC_PRCCP'															, .F. }, ; //X3_CAMPO
	{ 'N'																	, .F. }, ; //X3_TIPO
	{ 14																	, .F. }, ; //X3_TAMANHO
	{ 4																		, .F. }, ; //X3_DECIMAL
	{ 'Preco Compra'														, .F. }, ; //X3_TITULO
	{ 'Precio compr'														, .F. }, ; //X3_TITSPA
	{ 'Purchase Pri'														, .F. }, ; //X3_TITENG
	{ 'Preco Compra'														, .F. }, ; //X3_DESCRIC
	{ 'Precio compra'														, .F. }, ; //X3_DESCSPA
	{ 'Purchase Price'														, .F. }, ; //X3_DESCENG
	{ '@E 999,999,999.9999'													, .F. }, ; //X3_PICTURE
	{ 'Positivo()'															, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(65)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'V'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ 'N'																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ 'N'																	, .F. }, ; //X3_MODAL
	{ 'S'																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXC'																	, .F. }, ; //X3_ARQUIVO
	{ '84'																	, .F. }, ; //X3_ORDEM
	{ 'AXC_REFER'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 2																		, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Referencia'															, .F. }, ; //X3_TITULO
	{ 'Referencia'															, .F. }, ; //X3_TITSPA
	{ 'Reference'															, .F. }, ; //X3_TITENG
	{ 'Referencia do Fornecedor'											, .F. }, ; //X3_DESCRIC
	{ 'Referencia del proveedor'											, .F. }, ; //X3_DESCSPA
	{ 'Supplier Reference'													, .F. }, ; //X3_DESCENG
	{ '@!'																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(65)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'V'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ 'N'																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ 'N'																	, .F. }, ; //X3_MODAL
	{ 'S'																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXC'																	, .F. }, ; //X3_ARQUIVO
	{ '85'																	, .F. }, ; //X3_ORDEM
	{ 'AXC_FILDES'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 10																	, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Filial Dest.'														, .F. }, ; //X3_TITULO
	{ 'Suc. Dest.'															, .F. }, ; //X3_TITSPA
	{ 'Dest. Branch'														, .F. }, ; //X3_TITENG
	{ 'Filial Destino'														, .F. }, ; //X3_DESCRIC
	{ 'Sucursal destino'													, .F. }, ; //X3_DESCSPA
	{ 'Destination Branch'													, .F. }, ; //X3_DESCENG
	{ '@!'																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(65)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'V'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ 'N'																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ 'N'																	, .F. }, ; //X3_MODAL
	{ 'S'																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXC'																	, .F. }, ; //X3_ARQUIVO
	{ '86'																	, .F. }, ; //X3_ORDEM
	{ 'AXC_GRDQTD'															, .F. }, ; //X3_CAMPO
	{ 'N'																	, .F. }, ; //X3_TIPO
	{ 10																	, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Mult. Grade'															, .F. }, ; //X3_TITULO
	{ 'Mult. Grilla'														, .F. }, ; //X3_TITSPA
	{ 'Mult. Grid'															, .F. }, ; //X3_TITENG
	{ 'Multiplicador da Grade'												, .F. }, ; //X3_DESCRIC
	{ 'Multiplicador de la grill'											, .F. }, ; //X3_DESCSPA
	{ 'Grid Multiplier'														, .F. }, ; //X3_DESCENG
	{ '@E 9,999,999,999'													, .F. }, ; //X3_PICTURE
	{ 'Positivo()'															, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(65)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'V'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ 'N'																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ 'N'																	, .F. }, ; //X3_MODAL
	{ 'S'																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXC'																	, .F. }, ; //X3_ARQUIVO
	{ '87'																	, .F. }, ; //X3_ORDEM
	{ 'AXC_IDGRD'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 10																	, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'ID Grade'															, .F. }, ; //X3_TITULO
	{ 'ID Grilla'															, .F. }, ; //X3_TITSPA
	{ 'ID Grid'																, .F. }, ; //X3_TITENG
	{ 'ID da Grade'															, .F. }, ; //X3_DESCRIC
	{ 'ID de la grilla'														, .F. }, ; //X3_DESCSPA
	{ 'ID Grid'																, .F. }, ; //X3_DESCENG
	{ '@!'																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(65)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'V'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ 'N'																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ 'N'																	, .F. }, ; //X3_MODAL
	{ 'S'																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXC'																	, .F. }, ; //X3_ARQUIVO
	{ '88'																	, .F. }, ; //X3_ORDEM
	{ 'AXC_01MRG'															, .F. }, ; //X3_CAMPO
	{ 'N'																	, .F. }, ; //X3_TIPO
	{ 6																		, .F. }, ; //X3_TAMANHO
	{ 2																		, .F. }, ; //X3_DECIMAL
	{ 'Mrg Desejada'														, .F. }, ; //X3_TITULO
	{ 'Mrg Deseada'															, .F. }, ; //X3_TITSPA
	{ 'Desired Msg'															, .F. }, ; //X3_TITENG
	{ 'Margem Desejada'														, .F. }, ; //X3_DESCRIC
	{ 'Margen deseada'														, .F. }, ; //X3_DESCSPA
	{ 'Desired Margin'														, .F. }, ; //X3_DESCENG
	{ '@E 999.99'															, .F. }, ; //X3_PICTURE
	{ 'Positivo()'															, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(65)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'V'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ 'N'																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ 'N'																	, .F. }, ; //X3_MODAL
	{ 'S'																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXC'																	, .F. }, ; //X3_ARQUIVO
	{ '89'																	, .F. }, ; //X3_ORDEM
	{ 'AXC_PILOT'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 1																		, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Peca Piloto'															, .F. }, ; //X3_TITULO
	{ 'Pieza piloto'														, .F. }, ; //X3_TITSPA
	{ 'Pilot Part'															, .F. }, ; //X3_TITENG
	{ 'Peca Piloto'															, .F. }, ; //X3_DESCRIC
	{ 'Pieza piloto'														, .F. }, ; //X3_DESCSPA
	{ 'Pilot Part'															, .F. }, ; //X3_DESCENG
	{ '@!'																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128)					, .F. }, ; //X3_USADO
	{ '"N"'																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(65)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'V'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ 'S=Sim;N=Nao'															, .F. }, ; //X3_CBOX
	{ 'S=Si;N=No'															, .F. }, ; //X3_CBOXSPA
	{ 'S=Yes;N=No'															, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ 'N'																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ 'N'																	, .F. }, ; //X3_MODAL
	{ 'S'																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXC'																	, .F. }, ; //X3_ARQUIVO
	{ '90'																	, .F. }, ; //X3_ORDEM
	{ 'AXC_01MEMO'															, .F. }, ; //X3_CAMPO
	{ 'M'																	, .F. }, ; //X3_TIPO
	{ 80																	, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Observacoes'															, .F. }, ; //X3_TITULO
	{ 'Observacione'														, .F. }, ; //X3_TITSPA
	{ 'Notes'																, .F. }, ; //X3_TITENG
	{ 'Observacoes'															, .F. }, ; //X3_DESCRIC
	{ 'Observaciones'														, .F. }, ; //X3_DESCSPA
	{ 'Notes'																, .F. }, ; //X3_DESCENG
	{ '@!'																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128)					, .F. }, ; //X3_USADO
	{ 'IF(INCLUI,"",MSMM(AXC->AXC_MEMOC))'									, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(65)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'V'																	, .F. }, ; //X3_VISUAL
	{ 'V'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ 'N'																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ 'N'																	, .F. }, ; //X3_MODAL
	{ 'S'																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXC'																	, .F. }, ; //X3_ARQUIVO
	{ '91'																	, .F. }, ; //X3_ORDEM
	{ 'AXC_PRCVND'															, .F. }, ; //X3_CAMPO
	{ 'N'																	, .F. }, ; //X3_TIPO
	{ 10																	, .F. }, ; //X3_TAMANHO
	{ 2																		, .F. }, ; //X3_DECIMAL
	{ 'Preco Venda'															, .F. }, ; //X3_TITULO
	{ 'Precio venta'														, .F. }, ; //X3_TITSPA
	{ 'Sales Price'															, .F. }, ; //X3_TITENG
	{ 'Novo Preco de Venda'													, .F. }, ; //X3_DESCRIC
	{ 'Nuevo precio de venta'												, .F. }, ; //X3_DESCSPA
	{ 'New Sales Price'														, .F. }, ; //X3_DESCENG
	{ '@E 9,999,999.99'														, .F. }, ; //X3_PICTURE
	{ 'Positivo()'															, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(65)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'V'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ 'N'																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ 'N'																	, .F. }, ; //X3_MODAL
	{ 'S'																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXC'																	, .F. }, ; //X3_ARQUIVO
	{ '92'																	, .F. }, ; //X3_ORDEM
	{ 'AXC_MEMOC'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 6																		, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Cod. Memo'															, .F. }, ; //X3_TITULO
	{ 'Cod. Memo'															, .F. }, ; //X3_TITSPA
	{ 'Code Memo'															, .F. }, ; //X3_TITENG
	{ 'Cod. Memo'															, .F. }, ; //X3_DESCRIC
	{ 'Cod. Memo'															, .F. }, ; //X3_DESCSPA
	{ 'Code Memo'															, .F. }, ; //X3_DESCENG
	{ '@!'																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(65)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'V'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ 'N'																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ 'N'																	, .F. }, ; //X3_MODAL
	{ 'S'																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXC'																	, .F. }, ; //X3_ARQUIVO
	{ '93'																	, .F. }, ; //X3_ORDEM
	{ 'AXC_GRPFIL'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 6																		, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Grupo Filiai'														, .F. }, ; //X3_TITULO
	{ 'Grupo Suc.'															, .F. }, ; //X3_TITSPA
	{ 'Branch Group'														, .F. }, ; //X3_TITENG
	{ 'Grupo de Filiais'													, .F. }, ; //X3_DESCRIC
	{ 'Grupo de sucursales'													, .F. }, ; //X3_DESCSPA
	{ 'Group of Branches'													, .F. }, ; //X3_DESCENG
	{ '@!'																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ 'Z4'																	, .F. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(65)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ "!NaoVazio() .OR. ExistCpo('SX5','Z4'+M->AXC_GRPFIL,1)"				, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXC'																	, .F. }, ; //X3_ARQUIVO
	{ '94'																	, .F. }, ; //X3_ORDEM
	{ 'AXC_PERINI'															, .F. }, ; //X3_CAMPO
	{ 'D'																	, .F. }, ; //X3_TIPO
	{ 8																		, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Per.Inicial'															, .F. }, ; //X3_TITULO
	{ 'Per.Inicial'															, .F. }, ; //X3_TITSPA
	{ 'Per.Inicial'															, .F. }, ; //X3_TITENG
	{ 'Periodo Inicial de Vendas'											, .F. }, ; //X3_DESCRIC
	{ 'Periodo Inicial de Vendas'											, .F. }, ; //X3_DESCSPA
	{ 'Periodo Inicial de Vendas'											, .F. }, ; //X3_DESCENG
	{ ''																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(65)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXC'																	, .F. }, ; //X3_ARQUIVO
	{ '95'																	, .F. }, ; //X3_ORDEM
	{ 'AXC_PERFIM'															, .F. }, ; //X3_CAMPO
	{ 'D'																	, .F. }, ; //X3_TIPO
	{ 8																		, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Per.Final'															, .F. }, ; //X3_TITULO
	{ 'Per.Final'															, .F. }, ; //X3_TITSPA
	{ 'Per.Final'															, .F. }, ; //X3_TITENG
	{ 'Periodo Final de Vendas'												, .F. }, ; //X3_DESCRIC
	{ 'Periodo Final de Vendas'												, .F. }, ; //X3_DESCSPA
	{ 'Periodo Final de Vendas'												, .F. }, ; //X3_DESCENG
	{ ''																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(65)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXC'																	, .F. }, ; //X3_ARQUIVO
	{ '96'																	, .F. }, ; //X3_ORDEM
	{ 'AXC_DTPC1'															, .F. }, ; //X3_CAMPO
	{ 'D'																	, .F. }, ; //X3_TIPO
	{ 8																		, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Dt.Ult.PC'															, .F. }, ; //X3_TITULO
	{ 'Dt.Ult.PC'															, .F. }, ; //X3_TITSPA
	{ 'Dt.Ult.PC'															, .F. }, ; //X3_TITENG
	{ 'Data do Ultimo Pedido'												, .F. }, ; //X3_DESCRIC
	{ 'Data do Ultimo Pedido'												, .F. }, ; //X3_DESCSPA
	{ 'Data do Ultimo Pedido'												, .F. }, ; //X3_DESCENG
	{ ''																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(65)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXC'																	, .F. }, ; //X3_ARQUIVO
	{ '97'																	, .F. }, ; //X3_ORDEM
	{ 'AXC_DTPC2'															, .F. }, ; //X3_CAMPO
	{ 'D'																	, .F. }, ; //X3_TIPO
	{ 8																		, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Dt.Penult.PC'														, .F. }, ; //X3_TITULO
	{ 'Dt.Penult.PC'														, .F. }, ; //X3_TITSPA
	{ 'Dt.Penult.PC'														, .F. }, ; //X3_TITENG
	{ 'Data do Penultimo Pedido'											, .F. }, ; //X3_DESCRIC
	{ 'Data do Penultimo Pedido'											, .F. }, ; //X3_DESCSPA
	{ 'Data do Penultimo Pedido'											, .F. }, ; //X3_DESCENG
	{ ''																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(65)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXC'																	, .F. }, ; //X3_ARQUIVO
	{ '98'																	, .F. }, ; //X3_ORDEM
	{ 'AXC_CATEG'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 10																	, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Categoria'															, .F. }, ; //X3_TITULO
	{ 'Categoria'															, .F. }, ; //X3_TITSPA
	{ 'Categoria'															, .F. }, ; //X3_TITENG
	{ 'Codigo da Categoria'													, .F. }, ; //X3_DESCRIC
	{ 'Codigo da Categoria'													, .F. }, ; //X3_DESCSPA
	{ 'Codigo da Categoria'													, .F. }, ; //X3_DESCENG
	{ ''																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ 'AY1'																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(65)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ 'Vazio() .Or. ExistCpo("AY0",M->AXC_CATEG,1)'							, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXC'																	, .F. }, ; //X3_ARQUIVO
	{ '99'																	, .F. }, ; //X3_ORDEM
	{ 'AXC_CODMAR'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 6																		, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Marca'																, .F. }, ; //X3_TITULO
	{ 'Marca'																, .F. }, ; //X3_TITSPA
	{ 'Marca'																, .F. }, ; //X3_TITENG
	{ 'Codigo da Marca'														, .F. }, ; //X3_DESCRIC
	{ 'Codigo da Marca'														, .F. }, ; //X3_DESCSPA
	{ 'Codigo da Marca'														, .F. }, ; //X3_DESCENG
	{ ''																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ 'AY2'																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(65)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ 'Vazio() .Or. ExistCpo("AY2",M->AXC_CODMAR,1)'						, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXC'																	, .F. }, ; //X3_ARQUIVO
	{ 'A0'																	, .F. }, ; //X3_ORDEM
	{ 'AXC_COLECA'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 6																		, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Colecao'																, .F. }, ; //X3_TITULO
	{ 'Colecao'																, .F. }, ; //X3_TITSPA
	{ 'Colecao'																, .F. }, ; //X3_TITENG
	{ 'Codigo da Colecao'													, .F. }, ; //X3_DESCRIC
	{ 'Codigo da Colecao'													, .F. }, ; //X3_DESCSPA
	{ 'Codigo da Colecao'													, .F. }, ; //X3_DESCENG
	{ ''																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ 'AYH'																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(65)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ 'ExistCpo("AYH",M->AXC_COLECA,1)'										, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXC'																	, .F. }, ; //X3_ARQUIVO
	{ 'A1'																	, .F. }, ; //X3_ORDEM
	{ 'AXC_STATUS'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 1																		, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Status'																, .F. }, ; //X3_TITULO
	{ 'Status'																, .F. }, ; //X3_TITSPA
	{ 'Status'																, .F. }, ; //X3_TITENG
	{ 'Status do Pre-Pedido'												, .F. }, ; //X3_DESCRIC
	{ 'Status do Pre-Pedido'												, .F. }, ; //X3_DESCSPA
	{ 'Status do Pre-Pedido'												, .F. }, ; //X3_DESCENG
	{ '@!'																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128)					, .F. }, ; //X3_USADO
	{ '"1"'																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(65)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ '1=Em Negociacao;2=Em Cadastro;3=Encerrado;4=Cancelado'				, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXC'																	, .F. }, ; //X3_ARQUIVO
	{ 'A2'																	, .F. }, ; //X3_ORDEM
	{ 'AXC_FFORNE'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 1																		, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Filtra Forn.'														, .F. }, ; //X3_TITULO
	{ 'Filtra Forn.'														, .F. }, ; //X3_TITSPA
	{ 'Filtra Forn.'														, .F. }, ; //X3_TITENG
	{ 'Filtra Produtos do Forn.'											, .F. }, ; //X3_DESCRIC
	{ 'Filtra Produtos do Forn.'											, .F. }, ; //X3_DESCSPA
	{ 'Filtra Produtos do Forn.'											, .F. }, ; //X3_DESCENG
	{ ''																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ '"S"'																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(65)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ 'Pertence("SN")'														, .F. }, ; //X3_VLDUSER
	{ 'S=Sim;N=Nao'															, .F. }, ; //X3_CBOX
	{ 'S=Si;N=No'															, .F. }, ; //X3_CBOXSPA
	{ 'S=Yes;N=No'															, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXC'																	, .F. }, ; //X3_ARQUIVO
	{ 'A3'																	, .F. }, ; //X3_ORDEM
	{ 'AXC_OBSMEM'															, .F. }, ; //X3_CAMPO
	{ 'M'																	, .F. }, ; //X3_TIPO
	{ 10																	, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Observação'															, .F. }, ; //X3_TITULO
	{ 'Observação'															, .F. }, ; //X3_TITSPA
	{ 'Observação'															, .F. }, ; //X3_TITENG
	{ 'Observação'															, .F. }, ; //X3_DESCRIC
	{ 'Observação'															, .F. }, ; //X3_DESCSPA
	{ 'Observação'															, .F. }, ; //X3_DESCENG
	{ ''																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ 'IIF(INCLUI,"",MSMM(AXC_MEMOC,60))'									, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(65)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'V'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXC'																	, .F. }, ; //X3_ARQUIVO
	{ 'A4'																	, .F. }, ; //X3_ORDEM
	{ 'AXC_ITPROD'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 4																		, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Item Produto'														, .F. }, ; //X3_TITULO
	{ 'Item Produto'														, .F. }, ; //X3_TITSPA
	{ 'Item Produto'														, .F. }, ; //X3_TITENG
	{ 'Item do Produto'														, .F. }, ; //X3_DESCRIC
	{ 'Item do Produto'														, .F. }, ; //X3_DESCSPA
	{ 'Item do Produto'														, .F. }, ; //X3_DESCENG
	{ '@R 9999'																, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ '"0001"'																, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(65)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXC'																	, .F. }, ; //X3_ARQUIVO
	{ 'A5'																	, .F. }, ; //X3_ORDEM
	{ 'AXC_UTGRD'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 1																		, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Utiliza Grd.'														, .F. }, ; //X3_TITULO
	{ 'Utiliza Grd.'														, .F. }, ; //X3_TITSPA
	{ 'Utiliza Grd.'														, .F. }, ; //X3_TITENG
	{ 'Utiliza Grade'														, .F. }, ; //X3_DESCRIC
	{ 'Utiliza Grade'														, .F. }, ; //X3_DESCSPA
	{ 'Utiliza Grade'														, .F. }, ; //X3_DESCENG
	{ '@!'																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(65)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ 'S=Sim;N=Nao'															, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXC'																	, .F. }, ; //X3_ARQUIVO
	{ 'A6'																	, .F. }, ; //X3_ORDEM
	{ 'AXC_COLUNA'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 2																		, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Tabela Colun'														, .F. }, ; //X3_TITULO
	{ 'Tabela Colun'														, .F. }, ; //X3_TITSPA
	{ 'Tabela Colun'														, .F. }, ; //X3_TITENG
	{ 'Tabela que indica a colun'											, .F. }, ; //X3_DESCRIC
	{ 'Tabela que indica a colun'											, .F. }, ; //X3_DESCSPA
	{ 'Tabela que indica a colun'											, .F. }, ; //X3_DESCENG
	{ '@!'																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ 'SBV'																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(65)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXC'																	, .F. }, ; //X3_ARQUIVO
	{ 'A7'																	, .F. }, ; //X3_ORDEM
	{ 'AXC_LINHA'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 2																		, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Tabela Linha'														, .F. }, ; //X3_TITULO
	{ 'Tabela Linha'														, .F. }, ; //X3_TITSPA
	{ 'Tabela Linha'														, .F. }, ; //X3_TITENG
	{ 'Tabela que indica a linha'											, .F. }, ; //X3_DESCRIC
	{ 'Tabela que indica a linha'											, .F. }, ; //X3_DESCSPA
	{ 'Tabela que indica a linha'											, .F. }, ; //X3_DESCENG
	{ '@!'																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ 'SBV'																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(65)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXC'																	, .F. }, ; //X3_ARQUIVO
	{ 'A8'																	, .F. }, ; //X3_ORDEM
	{ 'AXC_CHVCOL'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 6																		, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Chave Coluna'														, .F. }, ; //X3_TITULO
	{ 'Chave Coluna'														, .F. }, ; //X3_TITSPA
	{ 'Chave Coluna'														, .F. }, ; //X3_TITENG
	{ 'Chave Coluna'														, .F. }, ; //X3_DESCRIC
	{ 'Chave Coluna'														, .F. }, ; //X3_DESCSPA
	{ 'Chave Coluna'														, .F. }, ; //X3_DESCENG
	{ ''																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(65)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXC'																	, .F. }, ; //X3_ARQUIVO
	{ 'A9'																	, .F. }, ; //X3_ORDEM
	{ 'AXC_NUMPC'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 6																		, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Num. PC'																, .F. }, ; //X3_TITULO
	{ 'Num. PC'																, .F. }, ; //X3_TITSPA
	{ 'Num. PC'																, .F. }, ; //X3_TITENG
	{ 'Numero Pedido de Compra'												, .F. }, ; //X3_DESCRIC
	{ 'Numero Pedido de Compra'												, .F. }, ; //X3_DESCSPA
	{ 'Numero Pedido de Compra'												, .F. }, ; //X3_DESCENG
	{ ''																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(65)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'S'																	, .F. }, ; //X3_BROWSE
	{ 'V'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

//
// Campos Tabela AXD
//
aAdd( aSX3, { ;
	{ 'AXD'																	, .F. }, ; //X3_ARQUIVO
	{ '01'																	, .F. }, ; //X3_ORDEM
	{ 'AXD_FILIAL'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ nTamFil																, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Filial'																, .F. }, ; //X3_TITULO
	{ 'Sucursal'															, .F. }, ; //X3_TITSPA
	{ 'Branch'																, .F. }, ; //X3_TITENG
	{ 'Filial do Sistema'													, .F. }, ; //X3_DESCRIC
	{ 'Sucursal del sistema'												, .F. }, ; //X3_DESCSPA
	{ 'System Branch'														, .F. }, ; //X3_DESCENG
	{ ''																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(158) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ ''																	, .F. }, ; //X3_VISUAL
	{ ''																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ '033'																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ 'N'																	, .F. }, ; //X3_IDXSRV
	{ ''																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ '2'																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ 'N'																	, .F. }, ; //X3_MODAL
	{ 'N'																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXD'																	, .F. }, ; //X3_ARQUIVO
	{ '02'																	, .F. }, ; //X3_ORDEM
	{ 'AXD_NUM'																, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 6																		, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Pedido'																, .F. }, ; //X3_TITULO
	{ 'Pedido'																, .F. }, ; //X3_TITSPA
	{ 'Order'																, .F. }, ; //X3_TITENG
	{ 'Pedido de Compra'													, .F. }, ; //X3_DESCRIC
	{ 'Pedido de Compra'													, .F. }, ; //X3_DESCSPA
	{ 'Purchase Order'														, .F. }, ; //X3_DESCENG
	{ ''																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(158) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ 'S'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ 'N'																	, .F. }, ; //X3_IDXSRV
	{ ''																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ '2'																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ 'N'																	, .F. }, ; //X3_MODAL
	{ 'N'																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXD'																	, .F. }, ; //X3_ARQUIVO
	{ '03'																	, .F. }, ; //X3_ORDEM
	{ 'AXD_FILDES'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 10																	, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Filial Dest.'														, .F. }, ; //X3_TITULO
	{ 'Suc. Dest.'															, .F. }, ; //X3_TITSPA
	{ 'Target Branc'														, .F. }, ; //X3_TITENG
	{ 'Filial Destino'														, .F. }, ; //X3_DESCRIC
	{ 'Sucursal Destino'													, .F. }, ; //X3_DESCSPA
	{ 'Target Branch'														, .F. }, ; //X3_DESCENG
	{ ''																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(158) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ 'S'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ 'N'																	, .F. }, ; //X3_IDXSRV
	{ ''																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ '2'																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ 'N'																	, .F. }, ; //X3_MODAL
	{ 'N'																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXD'																	, .F. }, ; //X3_ARQUIVO
	{ '04'																	, .F. }, ; //X3_ORDEM
	{ 'AXD_GRADE'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 10																	, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'ID Grade'															, .F. }, ; //X3_TITULO
	{ 'ID Grilla'															, .F. }, ; //X3_TITSPA
	{ 'Grid ID'																, .F. }, ; //X3_TITENG
	{ 'ID Grade'															, .F. }, ; //X3_DESCRIC
	{ 'ID Grilla'															, .F. }, ; //X3_DESCSPA
	{ 'ID Grid'																, .F. }, ; //X3_DESCENG
	{ '@!'																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(158) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ 'S'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ 'N'																	, .F. }, ; //X3_IDXSRV
	{ ''																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ '2'																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ 'N'																	, .F. }, ; //X3_MODAL
	{ 'N'																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXD'																	, .F. }, ; //X3_ARQUIVO
	{ '05'																	, .F. }, ; //X3_ORDEM
	{ 'AXD_PRODP'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ nTamPai																, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Produto Pai'															, .F. }, ; //X3_TITULO
	{ 'Prod. Princ.'														, .F. }, ; //X3_TITSPA
	{ 'Parent Prod'															, .F. }, ; //X3_TITENG
	{ 'Produto Pai'															, .F. }, ; //X3_DESCRIC
	{ 'Producto principal'													, .F. }, ; //X3_DESCSPA
	{ 'Parent Product'														, .F. }, ; //X3_DESCENG
	{ ''																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(158) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ 'S'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ 'G01'																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ 'N'																	, .F. }, ; //X3_IDXSRV
	{ ''																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ '2'																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ 'N'																	, .F. }, ; //X3_MODAL
	{ 'N'																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXD'																	, .F. }, ; //X3_ARQUIVO
	{ '06'																	, .F. }, ; //X3_ORDEM
	{ 'AXD_MULTI'															, .F. }, ; //X3_CAMPO
	{ 'N'																	, .F. }, ; //X3_TIPO
	{ 5																		, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Mult-Grade'															, .F. }, ; //X3_TITULO
	{ 'Multigrilla'															, .F. }, ; //X3_TITSPA
	{ 'Multi grid'															, .F. }, ; //X3_TITENG
	{ 'Mult-Grade'															, .F. }, ; //X3_DESCRIC
	{ 'Multigrilla'															, .F. }, ; //X3_DESCSPA
	{ 'Multi-Grid'															, .F. }, ; //X3_DESCENG
	{ '@E 99999'															, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(158) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ 'N'																	, .F. }, ; //X3_IDXSRV
	{ ''																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ '2'																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ 'N'																	, .F. }, ; //X3_MODAL
	{ 'N'																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXD'																	, .F. }, ; //X3_ARQUIVO
	{ '07'																	, .F. }, ; //X3_ORDEM
	{ 'AXD_GRDQT'															, .F. }, ; //X3_CAMPO
	{ 'N'																	, .F. }, ; //X3_TIPO
	{ 5																		, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Qtd Grade'															, .F. }, ; //X3_TITULO
	{ 'Ctd. Grilla'															, .F. }, ; //X3_TITSPA
	{ 'Grid Qty'															, .F. }, ; //X3_TITENG
	{ 'Qtd Grade'															, .F. }, ; //X3_DESCRIC
	{ 'Ctd. Grilla'															, .F. }, ; //X3_DESCSPA
	{ 'Qty Grid'															, .F. }, ; //X3_DESCENG
	{ '@E 99999'															, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(158) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ 'N'																	, .F. }, ; //X3_IDXSRV
	{ ''																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ '2'																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ 'N'																	, .F. }, ; //X3_MODAL
	{ 'N'																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXD'																	, .F. }, ; //X3_ARQUIVO
	{ '08'																	, .F. }, ; //X3_ORDEM
	{ 'AXD_TOTAL'															, .F. }, ; //X3_CAMPO
	{ 'N'																	, .F. }, ; //X3_TIPO
	{ 14																	, .F. }, ; //X3_TAMANHO
	{ 2																		, .F. }, ; //X3_DECIMAL
	{ 'Valor Total'															, .F. }, ; //X3_TITULO
	{ 'Valor Total'															, .F. }, ; //X3_TITSPA
	{ 'Total Value'															, .F. }, ; //X3_TITENG
	{ 'Valor Total'															, .F. }, ; //X3_DESCRIC
	{ 'Valor Total'															, .F. }, ; //X3_DESCSPA
	{ 'Total Value'															, .F. }, ; //X3_DESCENG
	{ '@E 99,999,999,999.99'												, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(158) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ 'N'																	, .F. }, ; //X3_IDXSRV
	{ ''																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ '2'																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ 'N'																	, .F. }, ; //X3_MODAL
	{ 'N'																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXD'																	, .F. }, ; //X3_ARQUIVO
	{ '09'																	, .F. }, ; //X3_ORDEM
	{ 'AXD_VLRIPI'															, .F. }, ; //X3_CAMPO
	{ 'N'																	, .F. }, ; //X3_TIPO
	{ 14																	, .F. }, ; //X3_TAMANHO
	{ 2																		, .F. }, ; //X3_DECIMAL
	{ 'Valor IPI'															, .F. }, ; //X3_TITULO
	{ 'Valor IPI'															, .F. }, ; //X3_TITSPA
	{ 'IPI Value'															, .F. }, ; //X3_TITENG
	{ 'Valor IPI'															, .F. }, ; //X3_DESCRIC
	{ 'Valor IPI'															, .F. }, ; //X3_DESCSPA
	{ 'IPI Value'															, .F. }, ; //X3_DESCENG
	{ '@E 99,999,999,999.99'												, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(158) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ 'N'																	, .F. }, ; //X3_IDXSRV
	{ ''																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ '2'																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ 'N'																	, .F. }, ; //X3_MODAL
	{ 'N'																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXD'																	, .F. }, ; //X3_ARQUIVO
	{ '10'																	, .F. }, ; //X3_ORDEM
	{ 'AXD_VLRDES'															, .F. }, ; //X3_CAMPO
	{ 'N'																	, .F. }, ; //X3_TIPO
	{ 14																	, .F. }, ; //X3_TAMANHO
	{ 2																		, .F. }, ; //X3_DECIMAL
	{ 'Vlr.Desconto'														, .F. }, ; //X3_TITULO
	{ 'Vlr.Descuent'														, .F. }, ; //X3_TITSPA
	{ 'Disc Value'															, .F. }, ; //X3_TITENG
	{ 'Vlr.Desconto'														, .F. }, ; //X3_DESCRIC
	{ 'Vlr.Descuento'														, .F. }, ; //X3_DESCSPA
	{ 'Discount Vl'															, .F. }, ; //X3_DESCENG
	{ '@E 99,999,999,999.99'												, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(158) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ 'N'																	, .F. }, ; //X3_IDXSRV
	{ ''																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ '2'																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ 'N'																	, .F. }, ; //X3_MODAL
	{ 'N'																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXD'																	, .F. }, ; //X3_ARQUIVO
	{ '11'																	, .F. }, ; //X3_ORDEM
	{ 'AXD_VLRFRE'															, .F. }, ; //X3_CAMPO
	{ 'N'																	, .F. }, ; //X3_TIPO
	{ 14																	, .F. }, ; //X3_TAMANHO
	{ 2																		, .F. }, ; //X3_DECIMAL
	{ 'Vlr. Frete'															, .F. }, ; //X3_TITULO
	{ 'Vlr. Flete'															, .F. }, ; //X3_TITSPA
	{ 'Freight Vl'															, .F. }, ; //X3_TITENG
	{ 'Vlr. Frete'															, .F. }, ; //X3_DESCRIC
	{ 'Vlr. Flete'															, .F. }, ; //X3_DESCSPA
	{ 'Freight Vl'															, .F. }, ; //X3_DESCENG
	{ '@E 99,999,999,999.99'												, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(158) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ 'N'																	, .F. }, ; //X3_IDXSRV
	{ ''																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ '2'																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ 'N'																	, .F. }, ; //X3_MODAL
	{ 'N'																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXD'																	, .F. }, ; //X3_ARQUIVO
	{ '12'																	, .F. }, ; //X3_ORDEM
	{ 'AXD_SKU'																, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ nTamSKU																, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'SKU'																	, .F. }, ; //X3_TITULO
	{ 'SKU'																	, .F. }, ; //X3_TITSPA
	{ 'SKU'																	, .F. }, ; //X3_TITENG
	{ 'SKU'																	, .F. }, ; //X3_DESCRIC
	{ 'SKU'																	, .F. }, ; //X3_DESCSPA
	{ 'SKU'																	, .F. }, ; //X3_DESCENG
	{ '@!'																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(158) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ '030'																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ 'N'																	, .F. }, ; //X3_IDXSRV
	{ ''																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ '2'																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ 'N'																	, .F. }, ; //X3_MODAL
	{ 'N'																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXD'																	, .F. }, ; //X3_ARQUIVO
	{ '13'																	, .F. }, ; //X3_ORDEM
	{ 'AXD_QUANT'															, .F. }, ; //X3_CAMPO
	{ 'N'																	, .F. }, ; //X3_TIPO
	{ 12																	, .F. }, ; //X3_TAMANHO
	{ 2																		, .F. }, ; //X3_DECIMAL
	{ 'Quantidade'															, .F. }, ; //X3_TITULO
	{ 'Cantidad'															, .F. }, ; //X3_TITSPA
	{ 'Quantity'															, .F. }, ; //X3_TITENG
	{ 'Quantidade'															, .F. }, ; //X3_DESCRIC
	{ 'Cantidad'															, .F. }, ; //X3_DESCSPA
	{ 'Quantity'															, .F. }, ; //X3_DESCENG
	{ '@E 999999999.99'														, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(158) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ 'N'																	, .F. }, ; //X3_IDXSRV
	{ ''																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ '2'																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ 'N'																	, .F. }, ; //X3_MODAL
	{ 'N'																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXD'																	, .F. }, ; //X3_ARQUIVO
	{ '14'																	, .F. }, ; //X3_ORDEM
	{ 'AXD_FILORI'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ nTamFil																, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Fil. Origem'															, .F. }, ; //X3_TITULO
	{ 'Suc. Origen'															, .F. }, ; //X3_TITSPA
	{ 'Source Branc'														, .F. }, ; //X3_TITENG
	{ 'Filial de Origem'													, .F. }, ; //X3_DESCRIC
	{ 'Sucursal de origen'													, .F. }, ; //X3_DESCSPA
	{ 'Source Branch'														, .F. }, ; //X3_DESCENG
	{ ''																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(158) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ '033'																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ 'N'																	, .F. }, ; //X3_IDXSRV
	{ ''																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ '2'																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ 'N'																	, .F. }, ; //X3_MODAL
	{ 'N'																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXD'																	, .F. }, ; //X3_ARQUIVO
	{ '15'																	, .F. }, ; //X3_ORDEM
	{ 'AXD_FORNEC'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ nTamCliFor															, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Fornecedor'															, .F. }, ; //X3_TITULO
	{ 'Proveedor'															, .F. }, ; //X3_TITSPA
	{ 'Supplier'															, .F. }, ; //X3_TITENG
	{ 'Fornecedor'															, .F. }, ; //X3_DESCRIC
	{ 'Proveedor'															, .F. }, ; //X3_DESCSPA
	{ 'Supplier'															, .F. }, ; //X3_DESCENG
	{ '@!'																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(158) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ '001'																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ 'N'																	, .F. }, ; //X3_IDXSRV
	{ ''																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ '2'																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ 'N'																	, .F. }, ; //X3_MODAL
	{ 'N'																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXD'																	, .F. }, ; //X3_ARQUIVO
	{ '16'																	, .F. }, ; //X3_ORDEM
	{ 'AXD_LOJA'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ nTamLoja																, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Loja'																, .F. }, ; //X3_TITULO
	{ 'Tienda'																, .F. }, ; //X3_TITSPA
	{ 'Store'																, .F. }, ; //X3_TITENG
	{ 'Loja do Fornecedor'													, .F. }, ; //X3_DESCRIC
	{ 'TIenda del proveedor'												, .F. }, ; //X3_DESCSPA
	{ 'Supplier Store'														, .F. }, ; //X3_DESCENG
	{ '@!'																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(158) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ '002'																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ 'N'																	, .F. }, ; //X3_IDXSRV
	{ ''																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ '2'																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ 'N'																	, .F. }, ; //X3_MODAL
	{ 'N'																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXD'																	, .F. }, ; //X3_ARQUIVO
	{ '17'																	, .F. }, ; //X3_ORDEM
	{ 'AXD_NFILDE'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 30																	, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Nome Filial'															, .F. }, ; //X3_TITULO
	{ 'Nome Filial'															, .F. }, ; //X3_TITSPA
	{ 'Nome Filial'															, .F. }, ; //X3_TITENG
	{ 'Nome Filial Destino'													, .F. }, ; //X3_DESCRIC
	{ 'Nome Filial Destino'													, .F. }, ; //X3_DESCSPA
	{ 'Nome Filial Destino'													, .F. }, ; //X3_DESCENG
	{ ''																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXD'																	, .F. }, ; //X3_ARQUIVO
	{ '18'																	, .F. }, ; //X3_ORDEM
	{ 'AXD_DTULTE'															, .F. }, ; //X3_CAMPO
	{ 'D'																	, .F. }, ; //X3_TIPO
	{ 8																		, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Dt.Ult.Ent.'															, .F. }, ; //X3_TITULO
	{ 'Dt.Ult.Ent.'															, .F. }, ; //X3_TITSPA
	{ 'Dt.Ult.Ent.'															, .F. }, ; //X3_TITENG
	{ 'Data Ultima Entrega'													, .F. }, ; //X3_DESCRIC
	{ 'Data Ultima Entrega'													, .F. }, ; //X3_DESCSPA
	{ 'Data Ultima Entrega'													, .F. }, ; //X3_DESCENG
	{ ''																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXD'																	, .F. }, ; //X3_ARQUIVO
	{ '19'																	, .F. }, ; //X3_ORDEM
	{ 'AXD_QTDEST'															, .F. }, ; //X3_CAMPO
	{ 'N'																	, .F. }, ; //X3_TIPO
	{ 9																		, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Qtd. Estoque'														, .F. }, ; //X3_TITULO
	{ 'Qtd. Estoque'														, .F. }, ; //X3_TITSPA
	{ 'Qtd. Estoque'														, .F. }, ; //X3_TITENG
	{ 'Quantida em Estoque'													, .F. }, ; //X3_DESCRIC
	{ 'Quantida em Estoque'													, .F. }, ; //X3_DESCSPA
	{ 'Quantida em Estoque'													, .F. }, ; //X3_DESCENG
	{ '@E 999,999,999'														, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXD'																	, .F. }, ; //X3_ARQUIVO
	{ '20'																	, .F. }, ; //X3_ORDEM
	{ 'AXD_QTDENT'															, .F. }, ; //X3_CAMPO
	{ 'N'																	, .F. }, ; //X3_TIPO
	{ 9																		, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Qtd.Ult.Entr'														, .F. }, ; //X3_TITULO
	{ 'Qtd.Ult.Entr'														, .F. }, ; //X3_TITSPA
	{ 'Qtd.Ult.Entr'														, .F. }, ; //X3_TITENG
	{ 'Quantidade Ultima Entrada'											, .F. }, ; //X3_DESCRIC
	{ 'Quantidade Ultima Entrada'											, .F. }, ; //X3_DESCSPA
	{ 'Quantidade Ultima Entrada'											, .F. }, ; //X3_DESCENG
	{ '@E 999,999,999'														, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXD'																	, .F. }, ; //X3_ARQUIVO
	{ '21'																	, .F. }, ; //X3_ORDEM
	{ 'AXD_QTDVEN'															, .F. }, ; //X3_CAMPO
	{ 'N'																	, .F. }, ; //X3_TIPO
	{ 9																		, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Qtd.Vendida'															, .F. }, ; //X3_TITULO
	{ 'Qtd.Vendida'															, .F. }, ; //X3_TITSPA
	{ 'Qtd.Vendida'															, .F. }, ; //X3_TITENG
	{ 'Quantidade Vendida'													, .F. }, ; //X3_DESCRIC
	{ 'Quantidade Vendida'													, .F. }, ; //X3_DESCSPA
	{ 'Quantidade Vendida'													, .F. }, ; //X3_DESCENG
	{ '@E 999,999,999'														, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXD'																	, .F. }, ; //X3_ARQUIVO
	{ '22'																	, .F. }, ; //X3_ORDEM
	{ 'AXD_QTDSUG'															, .F. }, ; //X3_CAMPO
	{ 'N'																	, .F. }, ; //X3_TIPO
	{ 9																		, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Qtd.Sugerida'														, .F. }, ; //X3_TITULO
	{ 'Qtd.Sugerida'														, .F. }, ; //X3_TITSPA
	{ 'Qtd.Sugerida'														, .F. }, ; //X3_TITENG
	{ 'Quantidade Sugerida'													, .F. }, ; //X3_DESCRIC
	{ 'Quantidade Sugerida'													, .F. }, ; //X3_DESCSPA
	{ 'Quantidade Sugerida'													, .F. }, ; //X3_DESCENG
	{ '@E 999,999,999'														, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXD'																	, .F. }, ; //X3_ARQUIVO
	{ '23'																	, .F. }, ; //X3_ORDEM
	{ 'AXD_PRCVEN'															, .F. }, ; //X3_CAMPO
	{ 'N'																	, .F. }, ; //X3_TIPO
	{ 9																		, .F. }, ; //X3_TAMANHO
	{ 2																		, .F. }, ; //X3_DECIMAL
	{ 'Prc.Venda'															, .F. }, ; //X3_TITULO
	{ 'Prc.Venda'															, .F. }, ; //X3_TITSPA
	{ 'Prc.Venda'															, .F. }, ; //X3_TITENG
	{ 'Preco de Venda'														, .F. }, ; //X3_DESCRIC
	{ 'Preco de Venda'														, .F. }, ; //X3_DESCSPA
	{ 'Preco de Venda'														, .F. }, ; //X3_DESCENG
	{ '@E 999,999.99'														, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXD'																	, .F. }, ; //X3_ARQUIVO
	{ '24'																	, .F. }, ; //X3_ORDEM
	{ 'AXD_VLRVEN'															, .F. }, ; //X3_CAMPO
	{ 'N'																	, .F. }, ; //X3_TIPO
	{ 14																	, .F. }, ; //X3_TAMANHO
	{ 2																		, .F. }, ; //X3_DECIMAL
	{ 'Vlr.Vendas'															, .F. }, ; //X3_TITULO
	{ 'Vlr.Vendas'															, .F. }, ; //X3_TITSPA
	{ 'Vlr.Vendas'															, .F. }, ; //X3_TITENG
	{ 'Valor das Vendas'													, .F. }, ; //X3_DESCRIC
	{ 'Valor das Vendas'													, .F. }, ; //X3_DESCSPA
	{ 'Valor das Vendas'													, .F. }, ; //X3_DESCENG
	{ '@E 99,999,999,999.99'												, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXD'																	, .F. }, ; //X3_ARQUIVO
	{ '25'																	, .F. }, ; //X3_ORDEM
	{ 'AXD_MARKUP'															, .F. }, ; //X3_CAMPO
	{ 'N'																	, .F. }, ; //X3_TIPO
	{ 12																	, .F. }, ; //X3_TAMANHO
	{ 2																		, .F. }, ; //X3_DECIMAL
	{ 'Mkp.Real'															, .F. }, ; //X3_TITULO
	{ 'Mkp.Real'															, .F. }, ; //X3_TITSPA
	{ 'Mkp.Real'															, .F. }, ; //X3_TITENG
	{ 'Markup Real'															, .F. }, ; //X3_DESCRIC
	{ 'Markup Real'															, .F. }, ; //X3_DESCSPA
	{ 'Markup Real'															, .F. }, ; //X3_DESCENG
	{ '@E 999,999,999.99'													, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXD'																	, .F. }, ; //X3_ARQUIVO
	{ '26'																	, .F. }, ; //X3_ORDEM
	{ 'AXD_GIRO'															, .F. }, ; //X3_CAMPO
	{ 'N'																	, .F. }, ; //X3_TIPO
	{ 9																		, .F. }, ; //X3_TAMANHO
	{ 2																		, .F. }, ; //X3_DECIMAL
	{ '% Giro'																, .F. }, ; //X3_TITULO
	{ '% Giro'																, .F. }, ; //X3_TITSPA
	{ '% Giro'																, .F. }, ; //X3_TITENG
	{ 'Percentual de Giro'													, .F. }, ; //X3_DESCRIC
	{ 'Percentual de Giro'													, .F. }, ; //X3_DESCSPA
	{ 'Percentual de Giro'													, .F. }, ; //X3_DESCENG
	{ '@E 999,999.99'														, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXD'																	, .F. }, ; //X3_ARQUIVO
	{ '27'																	, .F. }, ; //X3_ORDEM
	{ 'AXD_CSTVEN'															, .F. }, ; //X3_CAMPO
	{ 'N'																	, .F. }, ; //X3_TIPO
	{ 14																	, .F. }, ; //X3_TAMANHO
	{ 2																		, .F. }, ; //X3_DECIMAL
	{ 'Cust.Venda'															, .F. }, ; //X3_TITULO
	{ 'Cust.Venda'															, .F. }, ; //X3_TITSPA
	{ 'Cust.Venda'															, .F. }, ; //X3_TITENG
	{ 'Custo das Vendas'													, .F. }, ; //X3_DESCRIC
	{ 'Custo das Vendas'													, .F. }, ; //X3_DESCSPA
	{ 'Custo das Vendas'													, .F. }, ; //X3_DESCENG
	{ '@E 99,999,999,999.99'												, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXD'																	, .F. }, ; //X3_ARQUIVO
	{ '28'																	, .F. }, ; //X3_ORDEM
	{ 'AXD_ITPROD'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 4																		, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Item Produto'														, .F. }, ; //X3_TITULO
	{ 'Item Produto'														, .F. }, ; //X3_TITSPA
	{ 'Item Produto'														, .F. }, ; //X3_TITENG
	{ 'Item do Produto'														, .F. }, ; //X3_DESCRIC
	{ 'Item do Produto'														, .F. }, ; //X3_DESCSPA
	{ 'Item do Produto'														, .F. }, ; //X3_DESCENG
	{ '@R 9999'																, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXD'																	, .F. }, ; //X3_ARQUIVO
	{ '29'																	, .F. }, ; //X3_ORDEM
	{ 'AXD_CHVCOL'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 6																		, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Chave Coluna'														, .F. }, ; //X3_TITULO
	{ 'Chave Coluna'														, .F. }, ; //X3_TITSPA
	{ 'Chave Coluna'														, .F. }, ; //X3_TITENG
	{ 'Chave Coluna'														, .F. }, ; //X3_DESCRIC
	{ 'Chave Coluna'														, .F. }, ; //X3_DESCSPA
	{ 'Chave Coluna'														, .F. }, ; //X3_DESCENG
	{ ''																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXD'																	, .F. }, ; //X3_ARQUIVO
	{ '30'																	, .F. }, ; //X3_ORDEM
	{ 'AXD_QTDCAR'															, .F. }, ; //X3_CAMPO
	{ 'N'																	, .F. }, ; //X3_TIPO
	{ 9																		, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Carteira'															, .F. }, ; //X3_TITULO
	{ 'Carteira'															, .F. }, ; //X3_TITSPA
	{ 'Carteira'															, .F. }, ; //X3_TITENG
	{ 'Quantidade Carteira'													, .F. }, ; //X3_DESCRIC
	{ 'Quantidade Carteira'													, .F. }, ; //X3_DESCSPA
	{ 'Quantidade Carteira'													, .F. }, ; //X3_DESCENG
	{ '@E 999,999,999'														, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

//
// Campos Tabela AXE
//
aAdd( aSX3, { ;
	{ 'AXE'																	, .F. }, ; //X3_ARQUIVO
	{ '01'																	, .F. }, ; //X3_ORDEM
	{ 'AXE_FILIAL'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ nTamFil																, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Filial'																, .F. }, ; //X3_TITULO
	{ 'Sucursal'															, .F. }, ; //X3_TITSPA
	{ 'Branch'																, .F. }, ; //X3_TITENG
	{ 'Filial do Sistema'													, .F. }, ; //X3_DESCRIC
	{ 'Sucursal del Sistema'												, .F. }, ; //X3_DESCSPA
	{ 'System Branch'														, .F. }, ; //X3_DESCENG
	{ ''																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(128) + Chr(128)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ '033'																	, .F. }, ; //X3_GRPSXG
	{ '1'																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ 'N'																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ '1'																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ 'N'																	, .F. }, ; //X3_MODAL
	{ 'S'																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXE'																	, .F. }, ; //X3_ARQUIVO
	{ '02'																	, .F. }, ; //X3_ORDEM
	{ 'AXE_NUMPRE'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 6																		, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Num. Pre PC'															, .F. }, ; //X3_TITULO
	{ 'Num. Pre PC'															, .F. }, ; //X3_TITSPA
	{ 'Num. Pre PC'															, .F. }, ; //X3_TITENG
	{ 'Num. Pre Pedido Compra'												, .F. }, ; //X3_DESCRIC
	{ 'Num. Pre Pedido Compra'												, .F. }, ; //X3_DESCSPA
	{ 'Num. Pre Pedido Compra'												, .F. }, ; //X3_DESCENG
	{ '@!'																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'V'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXE'																	, .F. }, ; //X3_ARQUIVO
	{ '03'																	, .F. }, ; //X3_ORDEM
	{ 'AXE_ITPROD'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 4																		, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Item Produto'														, .F. }, ; //X3_TITULO
	{ 'Item Produto'														, .F. }, ; //X3_TITSPA
	{ 'Item Produto'														, .F. }, ; //X3_TITENG
	{ 'Item Produto'														, .F. }, ; //X3_DESCRIC
	{ 'Item Produto'														, .F. }, ; //X3_DESCSPA
	{ 'Item Produto'														, .F. }, ; //X3_DESCENG
	{ '@!'																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'V'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXE'																	, .F. }, ; //X3_ARQUIVO
	{ '04'																	, .F. }, ; //X3_ORDEM
	{ 'AXE_COD'																, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ nTamPai																, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Codigo'																, .F. }, ; //X3_TITULO
	{ 'Codigo'																, .F. }, ; //X3_TITSPA
	{ 'Code'																, .F. }, ; //X3_TITENG
	{ 'Codigo do Produto'													, .F. }, ; //X3_DESCRIC
	{ 'Codigo del Producto'													, .F. }, ; //X3_DESCSPA
	{ 'Product Code'														, .F. }, ; //X3_DESCENG
	{ '@!'																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(176)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(128) + Chr(128)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ 'S'																	, .F. }, ; //X3_BROWSE
	{ 'V'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ 'G01'																	, .F. }, ; //X3_GRPSXG
	{ '1'																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ 'S'																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ '1'																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ 'S'																	, .F. }, ; //X3_MODAL
	{ 'S'																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXE'																	, .F. }, ; //X3_ARQUIVO
	{ '05'																	, .F. }, ; //X3_ORDEM
	{ 'AXE_DESC'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 30																	, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Descricao'															, .F. }, ; //X3_TITULO
	{ 'Descripcion'															, .F. }, ; //X3_TITSPA
	{ 'Description'															, .F. }, ; //X3_TITENG
	{ 'Descricao do Produto'												, .F. }, ; //X3_DESCRIC
	{ 'Descripcion del Producto'											, .F. }, ; //X3_DESCSPA
	{ 'Description of Product'												, .F. }, ; //X3_DESCENG
	{ '@!'																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(147) + Chr(128)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ 'S'																	, .F. }, ; //X3_BROWSE
	{ 'V'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ 'texto()'																, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ '1'																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ 'S'																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ '1'																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ 'S'																	, .F. }, ; //X3_MODAL
	{ 'S'																	, .F. }} ) //X3_PYME
	
aAdd( aSX3, { ;
	{ 'AXE'																	, .T. }, ; //X3_ARQUIVO
	{ '06'																	, .T. }, ; //X3_ORDEM
	{ 'AXE_01DREF'															, .T. }, ; //X3_CAMPO
	{ 'C'																	, .T. }, ; //X3_TIPO
	{ 20																	, .T. }, ; //X3_TAMANHO
	{ 0																		, .T. }, ; //X3_DECIMAL
	{ 'EXTRA'																, .T. }, ; //X3_TITULO
	{ 'EXTRA'																, .T. }, ; //X3_TITSPA
	{ 'EXTRA'																, .T. }, ; //X3_TITENG
	{ 'Referencia do Fornecedor'											, .T. }, ; //X3_DESCRIC
	{ 'Referencia do Fornecedor'											, .T. }, ; //X3_DESCSPA
	{ 'Referencia do Fornecedor'											, .T. }, ; //X3_DESCENG
	{ ''																	, .T. }, ; //X3_PICTURE
	{ ''																	, .T. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .T. }, ; //X3_USADO
	{ ''																	, .T. }, ; //X3_RELACAO
	{ ''																	, .T. }, ; //X3_F3
	{ 0																		, .T. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .T. }, ; //X3_RESERV
	{ ''																	, .T. }, ; //X3_CHECK
	{ ''																	, .T. }, ; //X3_TRIGGER
	{ 'U'																	, .T. }, ; //X3_PROPRI
	{ 'S'																	, .T. }, ; //X3_BROWSE
	{ 'A'																	, .T. }, ; //X3_VISUAL
	{ 'R'																	, .T. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .T. }, ; //X3_CBOX
	{ ''																	, .T. }, ; //X3_CBOXSPA
	{ ''																	, .T. }, ; //X3_CBOXENG
	{ ''																	, .T. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .T. }, ; //X3_INIBRW
	{ ''																	, .T. }, ; //X3_GRPSXG
	{ ''																	, .T. }, ; //X3_FOLDER
	{ ''																	, .T. }, ; //X3_CONDSQL
	{ ''																	, .T. }, ; //X3_CHKSQL
	{ ''																	, .T. }, ; //X3_IDXSRV
	{ 'N'																	, .T. }, ; //X3_ORTOGRA
	{ ''																	, .T. }, ; //X3_TELA
	{ ''																	, .T. }, ; //X3_POSLGT
	{ 'N'																	, .T. }, ; //X3_IDXFLD
	{ ''																	, .T. }, ; //X3_AGRUP
	{ ''																	, .T. }, ; //X3_MODAL
	{ ''																	, .T. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXE'																	, .F. }, ; //X3_ARQUIVO
	{ '06'																	, .F. }, ; //X3_ORDEM
	{ 'AXE_01UTGR'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 1																		, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Util. Grade?'														, .F. }, ; //X3_TITULO
	{ '¿Util. Grill'														, .F. }, ; //X3_TITSPA
	{ 'Use Grid?'															, .F. }, ; //X3_TITENG
	{ 'Utiliza Grade'														, .F. }, ; //X3_DESCRIC
	{ 'Util. Grilla'														, .F. }, ; //X3_DESCSPA
	{ 'Use Grid'															, .F. }, ; //X3_DESCENG
	{ '@!'																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ '"N"'																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'S'																	, .F. }, ; //X3_BROWSE
	{ 'V'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ '€'																	, .F. }, ; //X3_OBRIGAT
	{ 'Pertence("SN")'														, .F. }, ; //X3_VLDUSER
	{ 'S=Sim;N=Nao'															, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ '1'																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ 'N'																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ 'N'																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXE'																	, .F. }, ; //X3_ARQUIVO
	{ '07'																	, .F. }, ; //X3_ORDEM
	{ 'AXE_COLUNA'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 2																		, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Tabela Colun'														, .F. }, ; //X3_TITULO
	{ 'Tabl.Columna'														, .F. }, ; //X3_TITSPA
	{ 'Column Table'														, .F. }, ; //X3_TITENG
	{ 'Tabela que indica a colun'											, .F. }, ; //X3_DESCRIC
	{ 'Tabla que Indica Columna'											, .F. }, ; //X3_DESCSPA
	{ 'Table referring to Column'											, .F. }, ; //X3_DESCENG
	{ '@!'																	, .F. }, ; //X3_PICTURE
	{ 'a550Verif() .And. A550Monta()'										, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ 'SBV'																	, .F. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(145) + Chr(128)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'V'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ 'INCLUI'																, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ '1'																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ 'N'																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ '1'																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ 'N'																	, .F. }, ; //X3_MODAL
	{ 'S'																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXE'																	, .F. }, ; //X3_ARQUIVO
	{ '08'																	, .F. }, ; //X3_ORDEM
	{ 'AXE_LINHA'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 2																		, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Tabela Linha'														, .F. }, ; //X3_TITULO
	{ 'Tabla Linea'															, .F. }, ; //X3_TITSPA
	{ 'Line Table'															, .F. }, ; //X3_TITENG
	{ 'Tabela que indica a linha'											, .F. }, ; //X3_DESCRIC
	{ 'Tabla que Indica la Linea'											, .F. }, ; //X3_DESCSPA
	{ 'Table referring to Line'												, .F. }, ; //X3_DESCENG
	{ '@!'																	, .F. }, ; //X3_PICTURE
	{ 'a550Verif() .And. A550Monta()'										, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ 'SBV'																	, .F. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(145) + Chr(128)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'V'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ 'INCLUI'																, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ '1'																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ 'N'																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ '1'																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ 'N'																	, .F. }, ; //X3_MODAL
	{ 'S'																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXE'																	, .F. }, ; //X3_ARQUIVO
	{ '09'																	, .F. }, ; //X3_ORDEM
	{ 'AXE_01CAT1'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 10																	, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Grupo Linha'															, .F. }, ; //X3_TITULO
	{ 'Grupo linea'															, .F. }, ; //X3_TITSPA
	{ 'Line Group'															, .F. }, ; //X3_TITENG
	{ 'Grupo Linha'															, .F. }, ; //X3_DESCRIC
	{ 'Grupo linea'															, .F. }, ; //X3_DESCSPA
	{ 'Line Group'															, .F. }, ; //X3_DESCENG
	{ '@!'																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ 'AXECA1'																, .T. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ 'S'																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ '€'																	, .F. }, ; //X3_OBRIGAT
	{ 'Vazio() .Or. T_SyVldCateg(1)'										, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ 'INCLUI'																, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ '1'																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXE'																	, .F. }, ; //X3_ARQUIVO
	{ '10'																	, .F. }, ; //X3_ORDEM
	{ 'AXE_01CAT2'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 10																	, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Linha'																, .F. }, ; //X3_TITULO
	{ 'Linea'																, .F. }, ; //X3_TITSPA
	{ 'Row'																	, .F. }, ; //X3_TITENG
	{ 'Linha'																, .F. }, ; //X3_DESCRIC
	{ 'Linea'																, .F. }, ; //X3_DESCSPA
	{ 'Row'																	, .F. }, ; //X3_DESCENG
	{ '@!'																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ 'AXECA2'																, .T. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ 'S'																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ '€'																	, .F. }, ; //X3_OBRIGAT
	{ 'Vazio() .Or. T_SyVldCateg(2)'										, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ 'INCLUI'																, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ '1'																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXE'																	, .F. }, ; //X3_ARQUIVO
	{ '11'																	, .F. }, ; //X3_ORDEM
	{ 'AXE_01CAT3'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 10																	, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Seção'																, .F. }, ; //X3_TITULO
	{ 'Seccion'																, .F. }, ; //X3_TITSPA
	{ 'Section'																, .F. }, ; //X3_TITENG
	{ 'Seção'																, .F. }, ; //X3_DESCRIC
	{ 'Seccion'																, .F. }, ; //X3_DESCSPA
	{ 'Section'																, .F. }, ; //X3_DESCENG
	{ '@!'																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ 'AXECA3'																, .T. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ 'S'																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ '€'																	, .F. }, ; //X3_OBRIGAT
	{ 'Vazio() .Or. T_SyVldCateg(3)'										, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ 'INCLUI'																, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ '1'																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXE'																	, .F. }, ; //X3_ARQUIVO
	{ '12'																	, .F. }, ; //X3_ORDEM
	{ 'AXE_01CAT4'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 10																	, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Espécie'																, .F. }, ; //X3_TITULO
	{ 'Especie'																, .F. }, ; //X3_TITSPA
	{ 'Species'																, .F. }, ; //X3_TITENG
	{ 'Espécie'																, .F. }, ; //X3_DESCRIC
	{ 'Especie'																, .F. }, ; //X3_DESCSPA
	{ 'Species'																, .F. }, ; //X3_DESCENG
	{ '@!'																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ 'AXECA4'																, .T. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ 'S'																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ 'Vazio() .Or. T_SyVldCateg(4)'										, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ 'INCLUI'																, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ '1'																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXE'																	, .F. }, ; //X3_ARQUIVO
	{ '13'																	, .F. }, ; //X3_ORDEM
	{ 'AXE_01CAT5'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 10																	, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Sub-Espécie'															, .F. }, ; //X3_TITULO
	{ 'Subespecie'															, .F. }, ; //X3_TITSPA
	{ 'Sub-Species'															, .F. }, ; //X3_TITENG
	{ 'Sub-Espécie'															, .F. }, ; //X3_DESCRIC
	{ 'Subespecie'															, .F. }, ; //X3_DESCSPA
	{ 'Sub-Species'															, .F. }, ; //X3_DESCENG
	{ '@!'																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ 'AXECA5'																, .T. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ 'S'																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ 'Vazio() .Or. T_SyVldCateg(5)'										, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ 'INCLUI'																, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ '1'																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXE'																	, .T. }, ; //X3_ARQUIVO
	{ '14'																	, .T. }, ; //X3_ORDEM
	{ 'AXE_01CODM'															, .T. }, ; //X3_CAMPO
	{ 'C'																	, .T. }, ; //X3_TIPO
	{ 6																		, .T. }, ; //X3_TAMANHO
	{ 0																		, .T. }, ; //X3_DECIMAL
	{ 'Marca'																, .T. }, ; //X3_TITULO
	{ 'Marca'																, .T. }, ; //X3_TITSPA
	{ 'Brand'																, .T. }, ; //X3_TITENG
	{ 'Marca'																, .T. }, ; //X3_DESCRIC
	{ 'Marca'																, .T. }, ; //X3_DESCSPA
	{ 'Brand'																, .T. }, ; //X3_DESCENG
	{ '@!'																	, .T. }, ; //X3_PICTURE
	{ ''																	, .T. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128)					, .T. }, ; //X3_USADO
	{ ''																	, .T. }, ; //X3_RELACAO
	{ 'AXEAY2'																, .T. }, ; //X3_F3
	{ 1																		, .T. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .T. }, ; //X3_RESERV
	{ ''																	, .T. }, ; //X3_CHECK
	{ 'S'																	, .T. }, ; //X3_TRIGGER
	{ 'U'																	, .T. }, ; //X3_PROPRI
	{ 'N'																	, .T. }, ; //X3_BROWSE
	{ 'A'																	, .T. }, ; //X3_VISUAL
	{ 'R'																	, .T. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ 'ExistCpo("AY2")'														, .F. }, ; //X3_VLDUSER
	{ ''																	, .T. }, ; //X3_CBOX
	{ ''																	, .T. }, ; //X3_CBOXSPA
	{ ''																	, .T. }, ; //X3_CBOXENG
	{ ''																	, .T. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .T. }, ; //X3_INIBRW
	{ ''																	, .T. }, ; //X3_GRPSXG
	{ '1'																	, .T. }, ; //X3_FOLDER
	{ ''																	, .T. }, ; //X3_CONDSQL
	{ ''																	, .T. }, ; //X3_CHKSQL
	{ 'N'																	, .T. }, ; //X3_IDXSRV
	{ 'N'																	, .T. }, ; //X3_ORTOGRA
	{ ''																	, .T. }, ; //X3_TELA
	{ ''																	, .T. }, ; //X3_POSLGT
	{ 'N'																	, .T. }, ; //X3_IDXFLD
	{ ''																	, .T. }, ; //X3_AGRUP
	{ 'N'																	, .T. }, ; //X3_MODAL
	{ ''																	, .T. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXE'																	, .T. }, ; //X3_ARQUIVO
	{ '15'																	, .T. }, ; //X3_ORDEM
	{ 'AXE_TIPO'															, .T. }, ; //X3_CAMPO
	{ 'C'																	, .T. }, ; //X3_TIPO
	{ 2																		, .T. }, ; //X3_TAMANHO
	{ 0																		, .T. }, ; //X3_DECIMAL
	{ 'Tipo'																, .T. }, ; //X3_TITULO
	{ 'Tipo'																, .T. }, ; //X3_TITSPA
	{ 'Type'																, .T. }, ; //X3_TITENG
	{ 'Tipo de Produto (MP,PA,.)'											, .T. }, ; //X3_DESCRIC
	{ 'Tipo de Producto (MP.PA.)'											, .T. }, ; //X3_DESCSPA
	{ 'Type of Product'														, .T. }, ; //X3_DESCENG
	{ '@!'																	, .T. }, ; //X3_PICTURE
	{ 'A010Tipo()'															, .T. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .T. }, ; //X3_USADO
	{ '"PA"'																, .T. }, ; //X3_RELACAO
	{ '02'																	, .T. }, ; //X3_F3
	{ 1																		, .T. }, ; //X3_NIVEL
	{ Chr(254) + Chr(65)													, .T. }, ; //X3_RESERV
	{ ''																	, .T. }, ; //X3_CHECK
	{ ''																	, .T. }, ; //X3_TRIGGER
	{ ''																	, .T. }, ; //X3_PROPRI
	{ 'N'																	, .T. }, ; //X3_BROWSE
	{ 'A'																	, .T. }, ; //X3_VISUAL
	{ 'R'																	, .T. }, ; //X3_CONTEXT
	{ '€'																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .T. }, ; //X3_CBOX
	{ ''																	, .T. }, ; //X3_CBOXSPA
	{ ''																	, .T. }, ; //X3_CBOXENG
	{ ''																	, .T. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .T. }, ; //X3_INIBRW
	{ ''																	, .T. }, ; //X3_GRPSXG
	{ '1'																	, .T. }, ; //X3_FOLDER
	{ ''																	, .T. }, ; //X3_CONDSQL
	{ ''																	, .T. }, ; //X3_CHKSQL
	{ 'N'																	, .T. }, ; //X3_IDXSRV
	{ 'N'																	, .T. }, ; //X3_ORTOGRA
	{ ''																	, .T. }, ; //X3_TELA
	{ '1'																	, .T. }, ; //X3_POSLGT
	{ 'N'																	, .T. }, ; //X3_IDXFLD
	{ ''																	, .T. }, ; //X3_AGRUP
	{ 'N'																	, .T. }, ; //X3_MODAL
	{ 'S'																	, .T. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXE'																	, .F. }, ; //X3_ARQUIVO
	{ '16'																	, .F. }, ; //X3_ORDEM
	{ 'AXE_UM'																, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 2																		, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Unidade'																, .F. }, ; //X3_TITULO
	{ 'Unidad'																, .F. }, ; //X3_TITSPA
	{ 'Measure Unit'														, .F. }, ; //X3_TITENG
	{ 'Unidade de Medida'													, .F. }, ; //X3_DESCRIC
	{ 'Unidad de Medida'													, .F. }, ; //X3_DESCSPA
	{ 'Unit of Measure'														, .F. }, ; //X3_DESCENG
	{ '@!'																	, .F. }, ; //X3_PICTURE
	{ 'ExistCpo("SAH")'														, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ 'SAH'																	, .F. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(131) + Chr(128)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ '1'																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ 'N'																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ '1'																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ 'N'																	, .F. }, ; //X3_MODAL
	{ 'S'																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXE'																	, .F. }, ; //X3_ARQUIVO
	{ '17'																	, .F. }, ; //X3_ORDEM
	{ 'AXE_01COLE'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 6																		, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Coleção'																, .F. }, ; //X3_TITULO
	{ 'Coleccion'															, .F. }, ; //X3_TITSPA
	{ 'Collection'															, .F. }, ; //X3_TITENG
	{ 'Coleção'																, .F. }, ; //X3_DESCRIC
	{ 'Coleccion'															, .F. }, ; //X3_DESCSPA
	{ 'Collection'															, .F. }, ; //X3_DESCENG
	{ '@!'																	, .F. }, ; //X3_PICTURE
	{ 'ExistCpo("AYH")'														, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ 'AYH'																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ '1'																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXE'																	, .F. }, ; //X3_ARQUIVO
	{ '18'																	, .F. }, ; //X3_ORDEM
	{ 'AXE_LOCPAD'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 2																		, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Armazem Pad.'														, .F. }, ; //X3_TITULO
	{ 'Depos.Estand'														, .F. }, ; //X3_TITSPA
	{ 'Std.Warehous'														, .F. }, ; //X3_TITENG
	{ 'Armazem Padrao p/Requis.'											, .F. }, ; //X3_DESCRIC
	{ 'Deposito Estandar'													, .F. }, ; //X3_DESCSPA
	{ 'Standard Warehouse'													, .F. }, ; //X3_DESCENG
	{ '@!'																	, .F. }, ; //X3_PICTURE
	{ 'ExistCpo("NNR")'														, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ 'NNR'																	, .F. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(131) + Chr(128)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ '024'																	, .F. }, ; //X3_GRPSXG
	{ '1'																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ 'N'																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ '1'																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ 'N'																	, .F. }, ; //X3_MODAL
	{ 'S'																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXE'																	, .F. }, ; //X3_ARQUIVO
	{ '19'																	, .F. }, ; //X3_ORDEM
	{ 'AXE_PROC'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ nTamCliFor															, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Fornecedor'															, .F. }, ; //X3_TITULO
	{ 'Prove.Estand'														, .F. }, ; //X3_TITSPA
	{ 'Supplier'															, .F. }, ; //X3_TITENG
	{ 'Fornecedor Padrao'													, .F. }, ; //X3_DESCRIC
	{ 'Proveedor Estandar'													, .F. }, ; //X3_DESCSPA
	{ 'Standard Supplier'													, .F. }, ; //X3_DESCENG
	{ '@!'																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ 'SA2_2'																, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ 'S'																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'S'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ '€'																	, .F. }, ; //X3_OBRIGAT
	{ 'EXISTCPO("SA2")'														, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ '1'																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ 'N'																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ 'N'																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXE'																	, .F. }, ; //X3_ARQUIVO
	{ '20'																	, .F. }, ; //X3_ORDEM
	{ 'AXE_LOJPRO'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ nTamLoja																, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Loja Forn.'															, .F. }, ; //X3_TITULO
	{ 'Loja Padrao'															, .F. }, ; //X3_TITSPA
	{ 'Loja Forn.'															, .F. }, ; //X3_TITENG
	{ 'Loja Fornecedor Padrao'												, .F. }, ; //X3_DESCRIC
	{ 'Loja Fornecedor Padrao'												, .F. }, ; //X3_DESCSPA
	{ 'Loja Fornecedor Padrao'												, .F. }, ; //X3_DESCENG
	{ '@!'																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ 'S'																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ '€'																	, .F. }, ; //X3_OBRIGAT
	{ 'ExistCpo("SA2",M->AXE_PROC+M->AXE_LOJPRO)'							, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ '1'																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ 'N'																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ 'N'																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXE'																	, .F. }, ; //X3_ARQUIVO
	{ '21'																	, .F. }, ; //X3_ORDEM
	{ 'AXE_01MKP'															, .F. }, ; //X3_CAMPO
	{ 'N'																	, .F. }, ; //X3_TIPO
	{ 12																	, .T. }, ; //X3_TAMANHO
	{ 2																		, .F. }, ; //X3_DECIMAL
	{ 'Markup'																, .F. }, ; //X3_TITULO
	{ 'Markup'																, .F. }, ; //X3_TITSPA
	{ 'Markup'																, .F. }, ; //X3_TITENG
	{ 'Markup Desejado'														, .F. }, ; //X3_DESCRIC
	{ 'Markup deseado'														, .F. }, ; //X3_DESCSPA
	{ 'Desired Markup'														, .F. }, ; //X3_DESCENG
	{ '@E 999,999,999.99'													, .T. }, ; //X3_PICTURE
	{ 'Positivo()'															, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ '€'																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ '1'																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ 'N'																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ 'N'																	, .F. }, ; //X3_MODAL
	{ 'S'																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXE'																	, .T. }, ; //X3_ARQUIVO
	{ '22'																	, .T. }, ; //X3_ORDEM
	{ 'AXE_01MRG'															, .T. }, ; //X3_CAMPO
	{ 'N'																	, .T. }, ; //X3_TIPO
	{ 12																	, .T. }, ; //X3_TAMANHO
	{ 2																		, .T. }, ; //X3_DECIMAL
	{ 'Mrg Desejada'														, .T. }, ; //X3_TITULO
	{ 'Mrg Deseada'															, .T. }, ; //X3_TITSPA
	{ 'Desired Msg'															, .T. }, ; //X3_TITENG
	{ 'Margem Desejada'														, .T. }, ; //X3_DESCRIC
	{ 'Margen deseada'														, .T. }, ; //X3_DESCSPA
	{ 'Desired Margin'														, .T. }, ; //X3_DESCENG
	{ '@E 999,999,999.99'													, .T. }, ; //X3_PICTURE
	{ 'Positivo()'															, .T. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128)					, .T. }, ; //X3_USADO
	{ ''																	, .T. }, ; //X3_RELACAO
	{ ''																	, .T. }, ; //X3_F3
	{ 1																		, .T. }, ; //X3_NIVEL
	{ Chr(254) + Chr(65)													, .T. }, ; //X3_RESERV
	{ ''																	, .T. }, ; //X3_CHECK
	{ ''																	, .T. }, ; //X3_TRIGGER
	{ 'U'																	, .T. }, ; //X3_PROPRI
	{ 'N'																	, .T. }, ; //X3_BROWSE
	{ 'A'																	, .T. }, ; //X3_VISUAL
	{ 'R'																	, .T. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .T. }, ; //X3_CBOX
	{ ''																	, .T. }, ; //X3_CBOXSPA
	{ ''																	, .T. }, ; //X3_CBOXENG
	{ ''																	, .T. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .T. }, ; //X3_INIBRW
	{ ''																	, .T. }, ; //X3_GRPSXG
	{ '1'																	, .T. }, ; //X3_FOLDER
	{ ''																	, .T. }, ; //X3_CONDSQL
	{ ''																	, .T. }, ; //X3_CHKSQL
	{ 'N'																	, .T. }, ; //X3_IDXSRV
	{ 'N'																	, .T. }, ; //X3_ORTOGRA
	{ ''																	, .T. }, ; //X3_TELA
	{ ''																	, .T. }, ; //X3_POSLGT
	{ 'N'																	, .T. }, ; //X3_IDXFLD
	{ ''																	, .T. }, ; //X3_AGRUP
	{ 'N'																	, .T. }, ; //X3_MODAL
	{ 'S'																	, .T. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXE'																	, .F. }, ; //X3_ARQUIVO
	{ '23'																	, .F. }, ; //X3_ORDEM
	{ 'AXE_GRUPO'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 4																		, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Grupo'																, .F. }, ; //X3_TITULO
	{ 'Grupo'																, .F. }, ; //X3_TITSPA
	{ 'Group'																, .F. }, ; //X3_TITENG
	{ 'Grupo de Estoque'													, .F. }, ; //X3_DESCRIC
	{ 'Grupo de Stock'														, .F. }, ; //X3_DESCSPA
	{ 'Inventory Group'														, .F. }, ; //X3_DESCENG
	{ ''																	, .F. }, ; //X3_PICTURE
	{ 'Vazio() .Or. A010Grupo()'											, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ 'SBM'																	, .F. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(130) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ 'N'																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ '1'																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ 'N'																	, .F. }, ; //X3_MODAL
	{ 'S'																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXE'																	, .F. }, ; //X3_ARQUIVO
	{ '24'																	, .F. }, ; //X3_ORDEM
	{ 'AXE_CLASFI'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 2																		, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Class.Fiscal'														, .F. }, ; //X3_TITULO
	{ 'Clas. Fiscal'														, .F. }, ; //X3_TITSPA
	{ 'Tax Category'														, .F. }, ; //X3_TITENG
	{ 'Classificacao fiscal'												, .F. }, ; //X3_DESCRIC
	{ 'Clasificacion fiscal'												, .F. }, ; //X3_DESCSPA
	{ 'Tax Category'														, .F. }, ; //X3_DESCENG
	{ '@!'																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(130) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ '2'																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ 'N'																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ '1'																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ 'N'																	, .F. }, ; //X3_MODAL
	{ 'S'																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXE'																	, .F. }, ; //X3_ARQUIVO
	{ '25'																	, .F. }, ; //X3_ORDEM
	{ 'AXE_CODISS'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 9																		, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Cod.Serv.ISS'														, .F. }, ; //X3_TITULO
	{ 'Cod.Serv.ISS'														, .F. }, ; //X3_TITSPA
	{ 'ISS Serv.Cod'														, .F. }, ; //X3_TITENG
	{ 'Código de Serviço do ISS'											, .F. }, ; //X3_DESCRIC
	{ 'Codigo de Servicio de ISS'											, .F. }, ; //X3_DESCSPA
	{ 'ISS Service Code'													, .F. }, ; //X3_DESCENG
	{ '@9'																	, .F. }, ; //X3_PICTURE
	{ 'Vazio() .Or. ExistCpo("SX5","60"+M->AXE_CODISS)'						, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ '60'																	, .F. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(144) + Chr(128)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ ''																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ '023'																	, .F. }, ; //X3_GRPSXG
	{ '2'																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ 'N'																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ '1'																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ 'N'																	, .F. }, ; //X3_MODAL
	{ 'S'																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXE'																	, .F. }, ; //X3_ARQUIVO
	{ '26'																	, .F. }, ; //X3_ORDEM
	{ 'AXE_CONV'															, .F. }, ; //X3_CAMPO
	{ 'N'																	, .F. }, ; //X3_TIPO
	{ 5																		, .F. }, ; //X3_TAMANHO
	{ 2																		, .F. }, ; //X3_DECIMAL
	{ 'Fator Conv.'															, .F. }, ; //X3_TITULO
	{ 'Factor Conv.'														, .F. }, ; //X3_TITSPA
	{ 'Factor Conv.'														, .F. }, ; //X3_TITENG
	{ 'Fator de Conversao de UM'											, .F. }, ; //X3_DESCRIC
	{ 'Factor Conversion de UM'												, .F. }, ; //X3_DESCSPA
	{ 'Convers.Factor Un.Measure'											, .F. }, ; //X3_DESCENG
	{ '@E 99.99'															, .F. }, ; //X3_PICTURE
	{ 'Positivo()'															, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(154) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ 'N'																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ '1'																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ 'N'																	, .F. }, ; //X3_MODAL
	{ 'S'																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXE'																	, .F. }, ; //X3_ARQUIVO
	{ '27'																	, .F. }, ; //X3_ORDEM
	{ 'AXE_FORAES'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 1																		, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Fora estado'															, .F. }, ; //X3_TITULO
	{ 'Fuera Estado'														, .F. }, ; //X3_TITSPA
	{ 'Out of State'														, .F. }, ; //X3_TITENG
	{ 'S-se comprado fora estado'											, .F. }, ; //X3_DESCRIC
	{ 'S:si Comprado Fuera Estad'											, .F. }, ; //X3_DESCSPA
	{ 'Y-if Purch. out of State'											, .F. }, ; //X3_DESCENG
	{ '!'																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(130) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ 'pertence("SN")'														, .F. }, ; //X3_VLDUSER
	{ 'S=Sim;N=Nao'															, .F. }, ; //X3_CBOX
	{ 'S=Si;N=No'															, .F. }, ; //X3_CBOXSPA
	{ 'S=Yes;N=No'															, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ '2'																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ 'N'																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ '1'																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ 'N'																	, .F. }, ; //X3_MODAL
	{ 'S'																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXE'																	, .F. }, ; //X3_ARQUIVO
	{ '28'																	, .F. }, ; //X3_ORDEM
	{ 'AXE_IPI'																, .F. }, ; //X3_CAMPO
	{ 'N'																	, .F. }, ; //X3_TIPO
	{ 5																		, .F. }, ; //X3_TAMANHO
	{ 2																		, .F. }, ; //X3_DECIMAL
	{ 'Aliq. IPI'															, .F. }, ; //X3_TITULO
	{ 'Alic. IPI'															, .F. }, ; //X3_TITSPA
	{ 'IPI Tax Rate'														, .F. }, ; //X3_TITENG
	{ 'Alíquota de IPI'														, .F. }, ; //X3_DESCRIC
	{ 'Alicuota de IPI'														, .F. }, ; //X3_DESCSPA
	{ 'IPI Tax Rate'														, .F. }, ; //X3_DESCENG
	{ '@E 99.99'															, .F. }, ; //X3_PICTURE
	{ 'Positivo()'															, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(130) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ '2'																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ 'N'																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ '1'																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ 'N'																	, .F. }, ; //X3_MODAL
	{ 'S'																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXE'																	, .F. }, ; //X3_ARQUIVO
	{ '29'																	, .F. }, ; //X3_ORDEM
	{ 'AXE_IRRF'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 1																		, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Impos.Renda'															, .F. }, ; //X3_TITULO
	{ 'Imp.Ganancia'														, .F. }, ; //X3_TITSPA
	{ 'Income Tax'															, .F. }, ; //X3_TITENG
	{ 'Incide imposto renda'												, .F. }, ; //X3_DESCRIC
	{ 'Incide Imp. a las Gananc.'											, .F. }, ; //X3_DESCSPA
	{ 'Income Tax Incidence'												, .F. }, ; //X3_DESCENG
	{ '@!'																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(144) + Chr(128)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ 'Pertence("SN")'														, .F. }, ; //X3_VLDUSER
	{ 'S=Sim;N=Nao'															, .F. }, ; //X3_CBOX
	{ 'S=Si;N=No'															, .F. }, ; //X3_CBOXSPA
	{ 'S=Yes;N=No'															, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ '2'																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ 'N'																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ '1'																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ 'N'																	, .F. }, ; //X3_MODAL
	{ 'S'																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXE'																	, .F. }, ; //X3_ARQUIVO
	{ '30'																	, .F. }, ; //X3_ORDEM
	{ 'AXE_LOCALI'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 1																		, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Contr.Endere'														, .F. }, ; //X3_TITULO
	{ 'Contr.Ubicac'														, .F. }, ; //X3_TITSPA
	{ 'Address Ct.'															, .F. }, ; //X3_TITENG
	{ 'Controla Enderecamento'												, .F. }, ; //X3_DESCRIC
	{ 'Controla Ubicacion'													, .F. }, ; //X3_DESCSPA
	{ 'Addressing Control'													, .F. }, ; //X3_DESCENG
	{ '@!'																	, .F. }, ; //X3_PICTURE
	{ 'Pertence("SN")'														, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ '"N"'																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(130) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ 'S=Sim;N=Nao'															, .F. }, ; //X3_CBOX
	{ 'S=Si;N=No'															, .F. }, ; //X3_CBOXSPA
	{ 'S=Yes;N=No'															, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ 'N'																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ '1'																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ 'N'																	, .F. }, ; //X3_MODAL
	{ 'S'																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXE'																	, .F. }, ; //X3_ARQUIVO
	{ '31'																	, .F. }, ; //X3_ORDEM
	{ 'AXE_PESO'															, .F. }, ; //X3_CAMPO
	{ 'N'																	, .F. }, ; //X3_TIPO
	{ 11																	, .F. }, ; //X3_TAMANHO
	{ 4																		, .F. }, ; //X3_DECIMAL
	{ 'Peso Liquido'														, .F. }, ; //X3_TITULO
	{ 'Peso Neto'															, .F. }, ; //X3_TITSPA
	{ 'Net Weight'															, .F. }, ; //X3_TITENG
	{ 'Peso Liquido p/ calc N.F.'											, .F. }, ; //X3_DESCRIC
	{ 'Peso Neto pa.Calc.Factura'											, .F. }, ; //X3_DESCSPA
	{ 'Net Weight for calc. Inv.'											, .F. }, ; //X3_DESCENG
	{ '@E 999,999.9999'														, .F. }, ; //X3_PICTURE
	{ 'Positivo()'															, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(154) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ 'N'																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ '1'																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ 'N'																	, .F. }, ; //X3_MODAL
	{ 'S'																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXE'																	, .F. }, ; //X3_ARQUIVO
	{ '32'																	, .F. }, ; //X3_ORDEM
	{ 'AXE_PICM'															, .F. }, ; //X3_CAMPO
	{ 'N'																	, .F. }, ; //X3_TIPO
	{ 5																		, .F. }, ; //X3_TAMANHO
	{ 2																		, .F. }, ; //X3_DECIMAL
	{ 'Aliq. ICMS'															, .F. }, ; //X3_TITULO
	{ 'Alic. ICMS'															, .F. }, ; //X3_TITSPA
	{ 'ICMS Tx.Rate'														, .F. }, ; //X3_TITENG
	{ 'Alíquota de ICMS'													, .F. }, ; //X3_DESCRIC
	{ 'Alicuota de ICMS'													, .F. }, ; //X3_DESCSPA
	{ 'ICMS Tax Rate'														, .F. }, ; //X3_DESCENG
	{ '@E 99.99'															, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(130) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ 'pertence("0,7,12,17,18,25")'											, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ '2'																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ 'N'																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ '1'																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ 'N'																	, .F. }, ; //X3_MODAL
	{ 'S'																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXE'																	, .F. }, ; //X3_ARQUIVO
	{ '33'																	, .F. }, ; //X3_ORDEM
	{ 'AXE_PICMEN'															, .F. }, ; //X3_CAMPO
	{ 'N'																	, .F. }, ; //X3_TIPO
	{ 6																		, .F. }, ; //X3_TAMANHO
	{ 2																		, .F. }, ; //X3_DECIMAL
	{ 'Solid. Entr.'														, .F. }, ; //X3_TITULO
	{ 'Solid.Entrad'														, .F. }, ; //X3_TITSPA
	{ 'Solid.Inflow'														, .F. }, ; //X3_TITENG
	{ '% Lucro Calc. Solid.Entr.'											, .F. }, ; //X3_DESCRIC
	{ '%Ganc.Calc. Solid.Entrada'											, .F. }, ; //X3_DESCSPA
	{ 'Solid. Infl. Prof.Calc. %'											, .F. }, ; //X3_DESCENG
	{ '@E 999.99'															, .F. }, ; //X3_PICTURE
	{ 'Positivo()'															, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(154) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ '2'																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ 'N'																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ '1'																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ 'N'																	, .F. }, ; //X3_MODAL
	{ 'S'																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXE'																	, .F. }, ; //X3_ARQUIVO
	{ '34'																	, .F. }, ; //X3_ORDEM
	{ 'AXE_PICMRE'															, .F. }, ; //X3_CAMPO
	{ 'N'																	, .F. }, ; //X3_TIPO
	{ 6																		, .F. }, ; //X3_TAMANHO
	{ 2																		, .F. }, ; //X3_DECIMAL
	{ 'Solid. Saida'														, .F. }, ; //X3_TITULO
	{ 'Solid.Salida'														, .F. }, ; //X3_TITSPA
	{ 'Solid.Outfl.'														, .F. }, ; //X3_TITENG
	{ '% Lucro Calc. Solid.Saida'											, .F. }, ; //X3_DESCRIC
	{ '%Ganc.Calc. Solid.Salida'											, .F. }, ; //X3_DESCSPA
	{ 'Solid. Outf. Prof.Calc. %'											, .F. }, ; //X3_DESCENG
	{ '@E 999.99'															, .F. }, ; //X3_PICTURE
	{ 'Positivo()'															, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(154) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ '2'																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ 'N'																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ '1'																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ 'N'																	, .F. }, ; //X3_MODAL
	{ 'S'																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXE'																	, .F. }, ; //X3_ARQUIVO
	{ '35'																	, .F. }, ; //X3_ORDEM
	{ 'AXE_POSIPI'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 10																	, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Posicao IPI'															, .F. }, ; //X3_TITULO
	{ 'Posicion IPI'														, .F. }, ; //X3_TITSPA
	{ 'IPI Status'															, .F. }, ; //X3_TITENG
	{ 'Posicao / Inciso de IPI'												, .F. }, ; //X3_DESCRIC
	{ 'Posicion/Parrafo de IPI'												, .F. }, ; //X3_DESCSPA
	{ 'IPI Incision / Status'												, .F. }, ; //X3_DESCENG
	{ '@!'																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ 'SYD'																	, .F. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(146) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ '2'																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ 'N'																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ '1'																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ 'N'																	, .F. }, ; //X3_MODAL
	{ 'S'																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXE'																	, .F. }, ; //X3_ARQUIVO
	{ '36'																	, .F. }, ; //X3_ORDEM
	{ 'AXE_PRV1'															, .F. }, ; //X3_CAMPO
	{ 'N'																	, .F. }, ; //X3_TIPO
	{ 12																	, .F. }, ; //X3_TAMANHO
	{ 2																		, .F. }, ; //X3_DECIMAL
	{ 'Preco Venda'															, .F. }, ; //X3_TITULO
	{ 'Precio Venta'														, .F. }, ; //X3_TITSPA
	{ 'Sales Price'															, .F. }, ; //X3_TITENG
	{ 'Preco de Venda'														, .F. }, ; //X3_DESCRIC
	{ 'Precio de Venta'														, .F. }, ; //X3_DESCSPA
	{ 'Sales Price'															, .F. }, ; //X3_DESCENG
	{ '@E 999,999,999.99'													, .F. }, ; //X3_PICTURE
	{ 'Positivo()'															, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(154) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ '1'																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ 'N'																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ '1'																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ 'N'																	, .F. }, ; //X3_MODAL
	{ 'S'																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXE'																	, .F. }, ; //X3_ARQUIVO
	{ '37'																	, .F. }, ; //X3_ORDEM
	{ 'AXE_RASTRO'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 1																		, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Rastro'																, .F. }, ; //X3_TITULO
	{ 'Rastro'																, .F. }, ; //X3_TITSPA
	{ 'Track'																, .F. }, ; //X3_TITENG
	{ 'Rastreabilidade Produto'												, .F. }, ; //X3_DESCRIC
	{ 'Rastreabilidad Producto'												, .F. }, ; //X3_DESCSPA
	{ 'Product Traceability'												, .F. }, ; //X3_DESCENG
	{ '!'																	, .F. }, ; //X3_PICTURE
	{ 'Pertence("SLN")'														, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ '"N"'																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(144) + Chr(128)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ 'S=SubLote;L=Lote;N=Nao Utiliza'										, .F. }, ; //X3_CBOX
	{ 'S=SubLote;L=Lote;N=No Utiliza'										, .F. }, ; //X3_CBOXSPA
	{ 'S=SubLot;L=Lot;N=Not Used'											, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ 'N'																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ '1'																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ 'N'																	, .F. }, ; //X3_MODAL
	{ 'S'																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXE'																	, .F. }, ; //X3_ARQUIVO
	{ '38'																	, .F. }, ; //X3_ORDEM
	{ 'AXE_SEGUM'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 2																		, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Seg.Un.Medi.'														, .F. }, ; //X3_TITULO
	{ '2a.Unid.Med.'														, .F. }, ; //X3_TITSPA
	{ '2nd U.Meas.'															, .F. }, ; //X3_TITENG
	{ 'Segunda Unidade de Medida'											, .F. }, ; //X3_DESCRIC
	{ 'Segunda Unidad de Medida'											, .F. }, ; //X3_DESCSPA
	{ '2nd. Unit of Measure'												, .F. }, ; //X3_DESCENG
	{ '@!'																	, .F. }, ; //X3_PICTURE
	{ 'Vazio() .Or. ExistCpo("SAH")'										, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ 'SAH'																	, .F. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(144) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ 'N'																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ '1'																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ 'N'																	, .F. }, ; //X3_MODAL
	{ 'S'																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXE'																	, .F. }, ; //X3_ARQUIVO
	{ '39'																	, .F. }, ; //X3_ORDEM
	{ 'AXE_TE'																, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 3																		, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'TE Padrao'															, .F. }, ; //X3_TITULO
	{ 'TE Estandar'															, .F. }, ; //X3_TITSPA
	{ 'Inflow Type'															, .F. }, ; //X3_TITENG
	{ 'Codigo de Entrada padrao'											, .F. }, ; //X3_DESCRIC
	{ 'Codigo Entrada Estandar'												, .F. }, ; //X3_DESCSPA
	{ 'Standard Inflow Code'												, .F. }, ; //X3_DESCENG
	{ '@9'																	, .F. }, ; //X3_PICTURE
	{ 'vazio().or.existcpo("SF4").And.M->AXE_TE<"500"'						, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ 'SF4'																	, .F. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(130) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ 'N'																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ '1'																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ 'N'																	, .F. }, ; //X3_MODAL
	{ 'S'																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXE'																	, .F. }, ; //X3_ARQUIVO
	{ '40'																	, .F. }, ; //X3_ORDEM
	{ 'AXE_TIPCON'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 1																		, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Tipo de Conv'														, .F. }, ; //X3_TITULO
	{ 'Tipo de Conv'														, .F. }, ; //X3_TITSPA
	{ 'Type'																, .F. }, ; //X3_TITENG
	{ 'Tipo de Conversao da UM'												, .F. }, ; //X3_DESCRIC
	{ 'Tipo de Conversion UM'												, .F. }, ; //X3_DESCSPA
	{ 'Type of UOM Conversion'												, .F. }, ; //X3_DESCENG
	{ '@!'																	, .F. }, ; //X3_PICTURE
	{ 'Pertence("MD")'														, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128)					, .F. }, ; //X3_USADO
	{ '"M"'																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(146) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ 'M=Multiplicador;D=Divisor'											, .F. }, ; //X3_CBOX
	{ 'M=Multiplicador;D=Divisor'											, .F. }, ; //X3_CBOXSPA
	{ 'M=Multiplier;D=Divisor'												, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ 'N'																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ '1'																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ 'N'																	, .F. }, ; //X3_MODAL
	{ 'S'																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXE'																	, .F. }, ; //X3_ARQUIVO
	{ '41'																	, .F. }, ; //X3_ORDEM
	{ 'AXE_TS'																, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 3																		, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'TS Padrao'															, .F. }, ; //X3_TITULO
	{ 'TS Estandar'															, .F. }, ; //X3_TITSPA
	{ 'Outflow Type'														, .F. }, ; //X3_TITENG
	{ 'Codigo de Saida padrao'												, .F. }, ; //X3_DESCRIC
	{ 'Codigo Salida Estandar'												, .F. }, ; //X3_DESCSPA
	{ 'Standard Outflow Code'												, .F. }, ; //X3_DESCENG
	{ '@9'																	, .F. }, ; //X3_PICTURE
	{ 'vazio().or.existcpo("SF4").And.M->AXE_TS>="500"'						, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ 'SF4'																	, .F. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(130) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ ''																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ 'N'																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ '1'																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ 'N'																	, .F. }, ; //X3_MODAL
	{ 'S'																	, .F. }} ) //X3_PYME

//
// Campos Tabela AXH
//
aAdd( aSX3, { ;
	{ 'AXH'																	, .F. }, ; //X3_ARQUIVO
	{ '01'																	, .F. }, ; //X3_ORDEM
	{ 'AXH_FILIAL'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ nTamFil																, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Filial'																, .F. }, ; //X3_TITULO
	{ 'Sucursal'															, .F. }, ; //X3_TITSPA
	{ 'Branch'																, .F. }, ; //X3_TITENG
	{ 'Filial do Sistema'													, .F. }, ; //X3_DESCRIC
	{ 'Sucursal'															, .F. }, ; //X3_DESCSPA
	{ 'Branch of the System'												, .F. }, ; //X3_DESCENG
	{ '@!'																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ ''																	, .F. }, ; //X3_VISUAL
	{ ''																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ '033'																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ ''																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ ''																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXH'																	, .F. }, ; //X3_ARQUIVO
	{ '02'																	, .F. }, ; //X3_ORDEM
	{ 'AXH_NUM'																, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 8																		, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Num. Verba'															, .F. }, ; //X3_TITULO
	{ 'Num. Verba'															, .F. }, ; //X3_TITSPA
	{ 'Num. Verba'															, .F. }, ; //X3_TITENG
	{ 'Numero da Verba'														, .F. }, ; //X3_DESCRIC
	{ 'Numero da Verba'														, .F. }, ; //X3_DESCSPA
	{ 'Numero da Verba'														, .F. }, ; //X3_DESCENG
	{ '@!'																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ 'GETSXENUM("AXH","AXH_NUM",,1)'										, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'S'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ '€'																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXH'																	, .F. }, ; //X3_ARQUIVO
	{ '03'																	, .F. }, ; //X3_ORDEM
	{ 'AXH_ANO'																, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 4																		, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Ano'																	, .F. }, ; //X3_TITULO
	{ 'Ano'																	, .F. }, ; //X3_TITSPA
	{ 'Ano'																	, .F. }, ; //X3_TITENG
	{ 'Ano da Verba'														, .F. }, ; //X3_DESCRIC
	{ 'Ano da Verba'														, .F. }, ; //X3_DESCSPA
	{ 'Ano da Verba'														, .F. }, ; //X3_DESCENG
	{ '@R 9999'																, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'S'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ '€'																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXH'																	, .F. }, ; //X3_ARQUIVO
	{ '04'																	, .F. }, ; //X3_ORDEM
	{ 'AXH_MES'																, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 2																		, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Mes'																	, .F. }, ; //X3_TITULO
	{ 'Mes'																	, .F. }, ; //X3_TITSPA
	{ 'Mes'																	, .F. }, ; //X3_TITENG
	{ 'Mes da Verba'														, .F. }, ; //X3_DESCRIC
	{ 'Mes da Verba'														, .F. }, ; //X3_DESCSPA
	{ 'Mes da Verba'														, .F. }, ; //X3_DESCENG
	{ '@R 99'																, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'S'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ '€'																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXH'																	, .F. }, ; //X3_ARQUIVO
	{ '05'																	, .F. }, ; //X3_ORDEM
	{ 'AXH_CSTANT'															, .F. }, ; //X3_CAMPO
	{ 'N'																	, .F. }, ; //X3_TIPO
	{ 12																	, .F. }, ; //X3_TAMANHO
	{ 2																		, .F. }, ; //X3_DECIMAL
	{ 'Custo Ant.'															, .F. }, ; //X3_TITULO
	{ 'Custo Ant.'															, .F. }, ; //X3_TITSPA
	{ 'Custo Ant.'															, .F. }, ; //X3_TITENG
	{ 'Custo do Periodo Anterior'											, .F. }, ; //X3_DESCRIC
	{ 'Custo do Periodo Anterior'											, .F. }, ; //X3_DESCSPA
	{ 'Custo do Periodo Anterior'											, .F. }, ; //X3_DESCENG
	{ '@E 999,999,999.99'													, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'S'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXH'																	, .F. }, ; //X3_ARQUIVO
	{ '06'																	, .F. }, ; //X3_ORDEM
	{ 'AXH_VNDANT'															, .F. }, ; //X3_CAMPO
	{ 'N'																	, .F. }, ; //X3_TIPO
	{ 12																	, .F. }, ; //X3_TAMANHO
	{ 2																		, .F. }, ; //X3_DECIMAL
	{ 'Venda Ant.'															, .F. }, ; //X3_TITULO
	{ 'Venda Ant.'															, .F. }, ; //X3_TITSPA
	{ 'Venda Ant.'															, .F. }, ; //X3_TITENG
	{ 'Venda do Periodo Anterior'											, .F. }, ; //X3_DESCRIC
	{ 'Venda do Periodo Anterior'											, .F. }, ; //X3_DESCSPA
	{ 'Venda do Periodo Anterior'											, .F. }, ; //X3_DESCENG
	{ '@E 999,999,999.99'													, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'S'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXH'																	, .F. }, ; //X3_ARQUIVO
	{ '07'																	, .F. }, ; //X3_ORDEM
	{ 'AXH_VERANT'															, .F. }, ; //X3_CAMPO
	{ 'N'																	, .F. }, ; //X3_TIPO
	{ 12																	, .F. }, ; //X3_TAMANHO
	{ 2																		, .F. }, ; //X3_DECIMAL
	{ 'Verba Ant.'															, .F. }, ; //X3_TITULO
	{ 'Verba Ant.'															, .F. }, ; //X3_TITSPA
	{ 'Verba Ant.'															, .F. }, ; //X3_TITENG
	{ 'Verba do Periodo Anterior'											, .F. }, ; //X3_DESCRIC
	{ 'Verba do Periodo Anterior'											, .F. }, ; //X3_DESCSPA
	{ 'Verba do Periodo Anterior'											, .F. }, ; //X3_DESCENG
	{ '@E 999,999,999.99'													, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'S'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXH'																	, .F. }, ; //X3_ARQUIVO
	{ '08'																	, .F. }, ; //X3_ORDEM
	{ 'AXH_VERBA'															, .F. }, ; //X3_CAMPO
	{ 'N'																	, .F. }, ; //X3_TIPO
	{ 12																	, .F. }, ; //X3_TAMANHO
	{ 2																		, .F. }, ; //X3_DECIMAL
	{ 'Verba Dest.'															, .F. }, ; //X3_TITULO
	{ 'Verba Dest.'															, .F. }, ; //X3_TITSPA
	{ 'Verba Dest.'															, .F. }, ; //X3_TITENG
	{ 'Verba Destinada'														, .F. }, ; //X3_DESCRIC
	{ 'Verba Destinada'														, .F. }, ; //X3_DESCSPA
	{ 'Verba Destinada'														, .F. }, ; //X3_DESCENG
	{ '@E 999,999,999.99'													, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'S'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ '€'																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

//
// Campos Tabela AXI
//
aAdd( aSX3, { ;
	{ 'AXI'																	, .F. }, ; //X3_ARQUIVO
	{ '01'																	, .F. }, ; //X3_ORDEM
	{ 'AXI_FILIAL'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ nTamFil																, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Filial'																, .F. }, ; //X3_TITULO
	{ 'Sucursal'															, .F. }, ; //X3_TITSPA
	{ 'Branch'																, .F. }, ; //X3_TITENG
	{ 'Filial do Sistema'													, .F. }, ; //X3_DESCRIC
	{ 'Sucursal'															, .F. }, ; //X3_DESCSPA
	{ 'Branch of the System'												, .F. }, ; //X3_DESCENG
	{ '@!'																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ ''																	, .F. }, ; //X3_VISUAL
	{ ''																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ '033'																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ ''																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ ''																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXI'																	, .F. }, ; //X3_ARQUIVO
	{ '02'																	, .F. }, ; //X3_ORDEM
	{ 'AXI_NUM'																, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 8																		, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Num. Verba'															, .F. }, ; //X3_TITULO
	{ 'Num. Verba'															, .F. }, ; //X3_TITSPA
	{ 'Num. Verba'															, .F. }, ; //X3_TITENG
	{ 'Numero da Verba'														, .F. }, ; //X3_DESCRIC
	{ 'Numero da Verba'														, .F. }, ; //X3_DESCSPA
	{ 'Numero da Verba'														, .F. }, ; //X3_DESCENG
	{ ''																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXI'																	, .F. }, ; //X3_ARQUIVO
	{ '03'																	, .F. }, ; //X3_ORDEM
	{ 'AXI_ANO'																, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 4																		, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Ano'																	, .F. }, ; //X3_TITULO
	{ 'Ano'																	, .F. }, ; //X3_TITSPA
	{ 'Ano'																	, .F. }, ; //X3_TITENG
	{ 'Ano da Verba'														, .F. }, ; //X3_DESCRIC
	{ 'Ano da Verba'														, .F. }, ; //X3_DESCSPA
	{ 'Ano da Verba'														, .F. }, ; //X3_DESCENG
	{ ''																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXI'																	, .F. }, ; //X3_ARQUIVO
	{ '04'																	, .F. }, ; //X3_ORDEM
	{ 'AXI_MES'																, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 2																		, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Mes'																	, .F. }, ; //X3_TITULO
	{ 'Mes'																	, .F. }, ; //X3_TITSPA
	{ 'Mes'																	, .F. }, ; //X3_TITENG
	{ 'Mes da Verba'														, .F. }, ; //X3_DESCRIC
	{ 'Mes da Verba'														, .F. }, ; //X3_DESCSPA
	{ 'Mes da Verba'														, .F. }, ; //X3_DESCENG
	{ ''																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXI'																	, .F. }, ; //X3_ARQUIVO
	{ '05'																	, .F. }, ; //X3_ORDEM
	{ 'AXI_TIPREG'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 1																		, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Tipo Reg.'															, .F. }, ; //X3_TITULO
	{ 'Tipo Reg.'															, .F. }, ; //X3_TITSPA
	{ 'Tipo Reg.'															, .F. }, ; //X3_TITENG
	{ 'Tipo de Registro'													, .F. }, ; //X3_DESCRIC
	{ 'Tipo de Registro'													, .F. }, ; //X3_DESCSPA
	{ 'Tipo de Registro'													, .F. }, ; //X3_DESCENG
	{ ''																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ '1=Departamento;2=Filial;3=Secao;4=Grupo;5=Subgrupo'					, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXI'																	, .F. }, ; //X3_ARQUIVO
	{ '06'																	, .F. }, ; //X3_ORDEM
	{ 'AXI_CODSUP'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 10																	, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Cod.Superior'														, .F. }, ; //X3_TITULO
	{ 'Cod.Superior'														, .F. }, ; //X3_TITSPA
	{ 'Cod.Superior'														, .F. }, ; //X3_TITENG
	{ 'Codigo Nivel Superior'												, .F. }, ; //X3_DESCRIC
	{ 'Codigo Nivel Superior'												, .F. }, ; //X3_DESCSPA
	{ 'Codigo Nivel Superior'												, .F. }, ; //X3_DESCENG
	{ ''																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXI'																	, .F. }, ; //X3_ARQUIVO
	{ '07'																	, .F. }, ; //X3_ORDEM
	{ 'AXI_CODFIL'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ nTamFil																, .T. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Cod.Filial'															, .F. }, ; //X3_TITULO
	{ 'Cod.Filial'															, .F. }, ; //X3_TITSPA
	{ 'Cod.Filial'															, .F. }, ; //X3_TITENG
	{ 'Codigo da Filial'													, .F. }, ; //X3_DESCRIC
	{ 'Codigo da Filial'													, .F. }, ; //X3_DESCSPA
	{ 'Codigo da Filial'													, .F. }, ; //X3_DESCENG
	{ ''																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXI'																	, .F. }, ; //X3_ARQUIVO
	{ '08'																	, .F. }, ; //X3_ORDEM
	{ 'AXI_CODIGO'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 10																	, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Departamento'														, .F. }, ; //X3_TITULO
	{ 'Departamento'														, .F. }, ; //X3_TITSPA
	{ 'Departamento'														, .F. }, ; //X3_TITENG
	{ 'Codigo do Departamento'												, .F. }, ; //X3_DESCRIC
	{ 'Codigo do Departamento'												, .F. }, ; //X3_DESCSPA
	{ 'Codigo do Departamento'												, .F. }, ; //X3_DESCENG
	{ ''																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXI'																	, .F. }, ; //X3_ARQUIVO
	{ '09'																	, .F. }, ; //X3_ORDEM
	{ 'AXI_DESCRI'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 30																	, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Descricao'															, .F. }, ; //X3_TITULO
	{ 'Descricao'															, .F. }, ; //X3_TITSPA
	{ 'Descricao'															, .F. }, ; //X3_TITENG
	{ 'Descricao'															, .F. }, ; //X3_DESCRIC
	{ 'Descricao'															, .F. }, ; //X3_DESCSPA
	{ 'Descricao'															, .F. }, ; //X3_DESCENG
	{ ''																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXI'																	, .F. }, ; //X3_ARQUIVO
	{ '10'																	, .F. }, ; //X3_ORDEM
	{ 'AXI_VLREFE'															, .F. }, ; //X3_CAMPO
	{ 'N'																	, .F. }, ; //X3_TIPO
	{ 12																	, .F. }, ; //X3_TAMANHO
	{ 2																		, .F. }, ; //X3_DECIMAL
	{ 'Verba Efetua'														, .F. }, ; //X3_TITULO
	{ 'Verba Efetua'														, .F. }, ; //X3_TITSPA
	{ 'Verba Efetua'														, .F. }, ; //X3_TITENG
	{ 'Verba Efetuada'														, .F. }, ; //X3_DESCRIC
	{ 'Verba Efetuada'														, .F. }, ; //X3_DESCSPA
	{ 'Verba Efetuada'														, .F. }, ; //X3_DESCENG
	{ '@E 999,999,999.99'													, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXI'																	, .F. }, ; //X3_ARQUIVO
	{ '11'																	, .F. }, ; //X3_ORDEM
	{ 'AXI_VLRSUG'															, .F. }, ; //X3_CAMPO
	{ 'N'																	, .F. }, ; //X3_TIPO
	{ 12																	, .F. }, ; //X3_TAMANHO
	{ 2																		, .F. }, ; //X3_DECIMAL
	{ 'Verba Suger.'														, .F. }, ; //X3_TITULO
	{ 'Verba Suger.'														, .F. }, ; //X3_TITSPA
	{ 'Verba Suger.'														, .F. }, ; //X3_TITENG
	{ 'Verba Sugerida'														, .F. }, ; //X3_DESCRIC
	{ 'Verba Sugerida'														, .F. }, ; //X3_DESCSPA
	{ 'Verba Sugerida'														, .F. }, ; //X3_DESCENG
	{ '@E 999,999,999.99'													, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXI'																	, .F. }, ; //X3_ARQUIVO
	{ '12'																	, .F. }, ; //X3_ORDEM
	{ 'AXI_PERVER'															, .F. }, ; //X3_CAMPO
	{ 'N'																	, .F. }, ; //X3_TIPO
	{ 10																	, .F. }, ; //X3_TAMANHO
	{ 6																		, .F. }, ; //X3_DECIMAL
	{ '% Verba'																, .F. }, ; //X3_TITULO
	{ '% Verba'																, .F. }, ; //X3_TITSPA
	{ '% Verba'																, .F. }, ; //X3_TITENG
	{ 'Percentual de Verba'													, .F. }, ; //X3_DESCRIC
	{ 'Percentual de Verba'													, .F. }, ; //X3_DESCSPA
	{ 'Percentual de Verba'													, .F. }, ; //X3_DESCENG
	{ '@E 999.999999'														, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXI'																	, .F. }, ; //X3_ARQUIVO
	{ '13'																	, .F. }, ; //X3_ORDEM
	{ 'AXI_VLRCST'															, .F. }, ; //X3_CAMPO
	{ 'N'																	, .F. }, ; //X3_TIPO
	{ 12																	, .F. }, ; //X3_TAMANHO
	{ 2																		, .F. }, ; //X3_DECIMAL
	{ 'Custo Ant.'															, .F. }, ; //X3_TITULO
	{ 'Custo Ant.'															, .F. }, ; //X3_TITSPA
	{ 'Custo Ant.'															, .F. }, ; //X3_TITENG
	{ 'Custo do Periodo Anterior'											, .F. }, ; //X3_DESCRIC
	{ 'Custo do Periodo Anterior'											, .F. }, ; //X3_DESCSPA
	{ 'Custo do Periodo Anterior'											, .F. }, ; //X3_DESCENG
	{ '@E 999,999,999.99'													, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXI'																	, .F. }, ; //X3_ARQUIVO
	{ '14'																	, .F. }, ; //X3_ORDEM
	{ 'AXI_VLRVEN'															, .F. }, ; //X3_CAMPO
	{ 'N'																	, .F. }, ; //X3_TIPO
	{ 12																	, .F. }, ; //X3_TAMANHO
	{ 2																		, .F. }, ; //X3_DECIMAL
	{ 'Venda Ant.'															, .F. }, ; //X3_TITULO
	{ 'Venda Ant.'															, .F. }, ; //X3_TITSPA
	{ 'Venda Ant.'															, .F. }, ; //X3_TITENG
	{ 'Venda do Periodo Anterior'											, .F. }, ; //X3_DESCRIC
	{ 'Venda do Periodo Anterior'											, .F. }, ; //X3_DESCSPA
	{ 'Venda do Periodo Anterior'											, .F. }, ; //X3_DESCENG
	{ '@E 999,999,999.99'													, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXI'																	, .F. }, ; //X3_ARQUIVO
	{ '15'																	, .F. }, ; //X3_ORDEM
	{ 'AXI_PERVEN'															, .F. }, ; //X3_CAMPO
	{ 'N'																	, .F. }, ; //X3_TIPO
	{ 10																	, .F. }, ; //X3_TAMANHO
	{ 6																		, .F. }, ; //X3_DECIMAL
	{ '% Venda'																, .F. }, ; //X3_TITULO
	{ '% Venda'																, .F. }, ; //X3_TITSPA
	{ '% Venda'																, .F. }, ; //X3_TITENG
	{ '% Venda Periodo Anterior'											, .F. }, ; //X3_DESCRIC
	{ '% Venda Periodo Anterior'											, .F. }, ; //X3_DESCSPA
	{ '% Venda Periodo Anterior'											, .F. }, ; //X3_DESCENG
	{ '@E 999.999999'														, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXI'																	, .F. }, ; //X3_ARQUIVO
	{ '16'																	, .F. }, ; //X3_ORDEM
	{ 'AXI_CAT1'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 10																	, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Categoria 1'															, .F. }, ; //X3_TITULO
	{ 'Categoria 1'															, .F. }, ; //X3_TITSPA
	{ 'Category 1'															, .F. }, ; //X3_TITENG
	{ 'Categoria 1'															, .F. }, ; //X3_DESCRIC
	{ 'Categoria 1'															, .F. }, ; //X3_DESCSPA
	{ 'Category 1'															, .F. }, ; //X3_DESCENG
	{ ''																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXI'																	, .F. }, ; //X3_ARQUIVO
	{ '17'																	, .F. }, ; //X3_ORDEM
	{ 'AXI_CAT2'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 10																	, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Categoria 2'															, .F. }, ; //X3_TITULO
	{ 'Categoria 2'															, .F. }, ; //X3_TITSPA
	{ 'Categoria 2'															, .F. }, ; //X3_TITENG
	{ 'Categoria 2'															, .F. }, ; //X3_DESCRIC
	{ 'Categoria 2'															, .F. }, ; //X3_DESCSPA
	{ 'Categoria 2'															, .F. }, ; //X3_DESCENG
	{ ''																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXI'																	, .F. }, ; //X3_ARQUIVO
	{ '18'																	, .F. }, ; //X3_ORDEM
	{ 'AXI_CAT3'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 10																	, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Categoria 3'															, .F. }, ; //X3_TITULO
	{ 'Categoria 3'															, .F. }, ; //X3_TITSPA
	{ 'Categoria 3'															, .F. }, ; //X3_TITENG
	{ 'Categoria 3'															, .F. }, ; //X3_DESCRIC
	{ 'Categoria 3'															, .F. }, ; //X3_DESCSPA
	{ 'Categoria 3'															, .F. }, ; //X3_DESCENG
	{ ''																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXI'																	, .F. }, ; //X3_ARQUIVO
	{ '19'																	, .F. }, ; //X3_ORDEM
	{ 'AXI_CAT4'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 10																	, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Categoria 4'															, .F. }, ; //X3_TITULO
	{ 'Categoria 4'															, .F. }, ; //X3_TITSPA
	{ 'Categoria 4'															, .F. }, ; //X3_TITENG
	{ 'Categoria 4'															, .F. }, ; //X3_DESCRIC
	{ 'Categoria 4'															, .F. }, ; //X3_DESCSPA
	{ 'Categoria 4'															, .F. }, ; //X3_DESCENG
	{ ''																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXI'																	, .F. }, ; //X3_ARQUIVO
	{ '20'																	, .F. }, ; //X3_ORDEM
	{ 'AXI_CAT5'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 10																	, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Categoria 5'															, .F. }, ; //X3_TITULO
	{ 'Categoria 5'															, .F. }, ; //X3_TITSPA
	{ 'Categoria 5'															, .F. }, ; //X3_TITENG
	{ 'Categoria 5'															, .F. }, ; //X3_DESCRIC
	{ 'Categoria 5'															, .F. }, ; //X3_DESCSPA
	{ 'Categoria 5'															, .F. }, ; //X3_DESCENG
	{ ''																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME


//
// Campos Tabela AXJ
//
aAdd( aSX3, { ;
	{ 'AXJ'																	, .F. }, ; //X3_ARQUIVO
	{ '01'																	, .F. }, ; //X3_ORDEM
	{ 'AXJ_FILIAL'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ nTamFil																, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Filial'																, .F. }, ; //X3_TITULO
	{ 'Sucursal'															, .F. }, ; //X3_TITSPA
	{ 'Branch'																, .F. }, ; //X3_TITENG
	{ 'Filial do Sistema'													, .F. }, ; //X3_DESCRIC
	{ 'Sucursal'															, .F. }, ; //X3_DESCSPA
	{ 'Branch of the System'												, .F. }, ; //X3_DESCENG
	{ '@!'																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ ''																	, .F. }, ; //X3_VISUAL
	{ ''																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ '033'																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ ''																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ ''																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXJ'																	, .F. }, ; //X3_ARQUIVO
	{ '02'																	, .F. }, ; //X3_ORDEM
	{ 'AXJ_ANO'																, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 4																		, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Ano Meta'															, .F. }, ; //X3_TITULO
	{ 'Ano Meta'															, .F. }, ; //X3_TITSPA
	{ 'Ano Meta'															, .F. }, ; //X3_TITENG
	{ 'Ano da Meta'															, .F. }, ; //X3_DESCRIC
	{ 'Ano da Meta'															, .F. }, ; //X3_DESCSPA
	{ 'Ano da Meta'															, .F. }, ; //X3_DESCENG
	{ '@R 9999'																, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'S'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXJ'																	, .F. }, ; //X3_ARQUIVO
	{ '03'																	, .F. }, ; //X3_ORDEM
	{ 'AXJ_MES'																, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 2																		, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Mes Meta'															, .F. }, ; //X3_TITULO
	{ 'Mes Meta'															, .F. }, ; //X3_TITSPA
	{ 'Mes Meta'															, .F. }, ; //X3_TITENG
	{ 'Mes da Meta'															, .F. }, ; //X3_DESCRIC
	{ 'Mes da Meta'															, .F. }, ; //X3_DESCSPA
	{ 'Mes da Meta'															, .F. }, ; //X3_DESCENG
	{ '@R 99'																, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'S'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXJ'																	, .F. }, ; //X3_ARQUIVO
	{ '04'																	, .F. }, ; //X3_ORDEM
	{ 'AXJ_CRESCI'															, .F. }, ; //X3_CAMPO
	{ 'N'																	, .F. }, ; //X3_TIPO
	{ 6																		, .F. }, ; //X3_TAMANHO
	{ 2																		, .F. }, ; //X3_DECIMAL
	{ '%Crescimento'														, .F. }, ; //X3_TITULO
	{ '%Crescimento'														, .F. }, ; //X3_TITSPA
	{ '%Crescimento'														, .F. }, ; //X3_TITENG
	{ 'Percentual de Crescimento'											, .F. }, ; //X3_DESCRIC
	{ 'Percentual de Crescimento'											, .F. }, ; //X3_DESCSPA
	{ 'Percentual de Crescimento'											, .F. }, ; //X3_DESCENG
	{ '@E 999.99'															, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'S'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXJ'																	, .F. }, ; //X3_ARQUIVO
	{ '05'																	, .F. }, ; //X3_ORDEM
	{ 'AXJ_HVNDLI'															, .F. }, ; //X3_CAMPO
	{ 'N'																	, .F. }, ; //X3_TIPO
	{ 12																	, .F. }, ; //X3_TAMANHO
	{ 2																		, .F. }, ; //X3_DECIMAL
	{ 'Vnd. Liquida'														, .F. }, ; //X3_TITULO
	{ 'Vnd. Liquida'														, .F. }, ; //X3_TITSPA
	{ 'Vnd. Liquida'														, .F. }, ; //X3_TITENG
	{ 'Venda Liquida Historico'												, .F. }, ; //X3_DESCRIC
	{ 'Venda Liquida Historico'												, .F. }, ; //X3_DESCSPA
	{ 'Venda Liquida Historico'												, .F. }, ; //X3_DESCENG
	{ '@E 999,999,999.99'													, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXJ'																	, .F. }, ; //X3_ARQUIVO
	{ '06'																	, .F. }, ; //X3_ORDEM
	{ 'AXJ_HMKPPE'															, .F. }, ; //X3_CAMPO
	{ 'N'																	, .F. }, ; //X3_TIPO
	{ 12																	, .T. }, ; //X3_TAMANHO
	{ 2																		, .F. }, ; //X3_DECIMAL
	{ '%Markup Hist'														, .F. }, ; //X3_TITULO
	{ '%Markup Hist'														, .F. }, ; //X3_TITSPA
	{ '%Markup Hist'														, .F. }, ; //X3_TITENG
	{ 'Percentual Markup Histori'											, .F. }, ; //X3_DESCRIC
	{ 'Percentual Markup Histori'											, .F. }, ; //X3_DESCSPA
	{ 'Percentual Markup Histori'											, .F. }, ; //X3_DESCENG
	{ '@E 999,999,999.99'													, .T. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXJ'																	, .F. }, ; //X3_ARQUIVO
	{ '07'																	, .F. }, ; //X3_ORDEM
	{ 'AXJ_HMKPVL'															, .F. }, ; //X3_CAMPO
	{ 'N'																	, .F. }, ; //X3_TIPO
	{ 12																	, .F. }, ; //X3_TAMANHO
	{ 2																		, .F. }, ; //X3_DECIMAL
	{ 'Markup Vlr.'															, .F. }, ; //X3_TITULO
	{ 'Markup Vlr.'															, .F. }, ; //X3_TITSPA
	{ 'Markup Vlr.'															, .F. }, ; //X3_TITENG
	{ 'Markup Valor Historico'												, .F. }, ; //X3_DESCRIC
	{ 'Markup Valor Historico'												, .F. }, ; //X3_DESCSPA
	{ 'Markup Valor Historico'												, .F. }, ; //X3_DESCENG
	{ '@E 999,999,999.99'													, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXJ'																	, .F. }, ; //X3_ARQUIVO
	{ '08'																	, .F. }, ; //X3_ORDEM
	{ 'AXJ_HSLDZE'															, .F. }, ; //X3_CAMPO
	{ 'N'																	, .F. }, ; //X3_TIPO
	{ 12																	, .F. }, ; //X3_TAMANHO
	{ 2																		, .F. }, ; //X3_DECIMAL
	{ 'Saldo Zero H'														, .F. }, ; //X3_TITULO
	{ 'Saldo Zero H'														, .F. }, ; //X3_TITSPA
	{ 'Saldo Zero H'														, .F. }, ; //X3_TITENG
	{ 'Saldo Zero Historico'												, .F. }, ; //X3_DESCRIC
	{ 'Saldo Zero Historico'												, .F. }, ; //X3_DESCSPA
	{ 'Saldo Zero Historico'												, .F. }, ; //X3_DESCENG
	{ '@E 999,999,999.99'													, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXJ'																	, .F. }, ; //X3_ARQUIVO
	{ '09'																	, .F. }, ; //X3_ORDEM
	{ 'AXJ_HQTVEN'															, .F. }, ; //X3_CAMPO
	{ 'N'																	, .F. }, ; //X3_TIPO
	{ 12																	, .F. }, ; //X3_TAMANHO
	{ 2																		, .F. }, ; //X3_DECIMAL
	{ 'Qtd.Vend.His'														, .F. }, ; //X3_TITULO
	{ 'Qtd.Vend.His'														, .F. }, ; //X3_TITSPA
	{ 'Qtd.Vend.His'														, .F. }, ; //X3_TITENG
	{ 'Quantidade Vendida Histor'											, .F. }, ; //X3_DESCRIC
	{ 'Quantidade Vendida Histor'											, .F. }, ; //X3_DESCSPA
	{ 'Quantidade Vendida Histor'											, .F. }, ; //X3_DESCENG
	{ '@E 999,999,999.99'													, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXJ'																	, .F. }, ; //X3_ARQUIVO
	{ '10'																	, .F. }, ; //X3_ORDEM
	{ 'AXJ_HQTCAD'															, .F. }, ; //X3_CAMPO
	{ 'N'																	, .F. }, ; //X3_TIPO
	{ 12																	, .F. }, ; //X3_TAMANHO
	{ 2																		, .F. }, ; //X3_DECIMAL
	{ 'Qtd.Cad.Hist'														, .F. }, ; //X3_TITULO
	{ 'Qtd.Cad.Hist'														, .F. }, ; //X3_TITSPA
	{ 'Qtd.Cad.Hist'														, .F. }, ; //X3_TITENG
	{ 'Quantidade Cadastros Hist'											, .F. }, ; //X3_DESCRIC
	{ 'Quantidade Cadastros Hist'											, .F. }, ; //X3_DESCSPA
	{ 'Quantidade Cadastros Hist'											, .F. }, ; //X3_DESCENG
	{ '@E 999,999,999.99'													, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXJ'																	, .F. }, ; //X3_ARQUIVO
	{ '11'																	, .F. }, ; //X3_ORDEM
	{ 'AXJ_HRECEB'															, .F. }, ; //X3_CAMPO
	{ 'N'																	, .F. }, ; //X3_TIPO
	{ 12																	, .F. }, ; //X3_TAMANHO
	{ 2																		, .F. }, ; //X3_DECIMAL
	{ 'Receb.Hist.'															, .F. }, ; //X3_TITULO
	{ 'Receb.Hist.'															, .F. }, ; //X3_TITSPA
	{ 'Receb.Hist.'															, .F. }, ; //X3_TITENG
	{ 'Valor Recebimentos Histor'											, .F. }, ; //X3_DESCRIC
	{ 'Valor Recebimentos Histor'											, .F. }, ; //X3_DESCSPA
	{ 'Valor Recebimentos Histor'											, .F. }, ; //X3_DESCENG
	{ '@E 999,999,999.99'													, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXJ'																	, .F. }, ; //X3_ARQUIVO
	{ '12'																	, .F. }, ; //X3_ORDEM
	{ 'AXJ_HJUROS'															, .F. }, ; //X3_CAMPO
	{ 'N'																	, .F. }, ; //X3_TIPO
	{ 12																	, .F. }, ; //X3_TAMANHO
	{ 2																		, .F. }, ; //X3_DECIMAL
	{ 'Juros Hist.'															, .F. }, ; //X3_TITULO
	{ 'Juros Hist.'															, .F. }, ; //X3_TITSPA
	{ 'Juros Hist.'															, .F. }, ; //X3_TITENG
	{ 'Valor Juros Historico'												, .F. }, ; //X3_DESCRIC
	{ 'Valor Juros Historico'												, .F. }, ; //X3_DESCSPA
	{ 'Valor Juros Historico'												, .F. }, ; //X3_DESCENG
	{ '@E 999,999,999.99'													, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXJ'																	, .F. }, ; //X3_ARQUIVO
	{ '13'																	, .F. }, ; //X3_ORDEM
	{ 'AXJ_MVNDLI'															, .F. }, ; //X3_CAMPO
	{ 'N'																	, .F. }, ; //X3_TIPO
	{ 12																	, .F. }, ; //X3_TAMANHO
	{ 2																		, .F. }, ; //X3_DECIMAL
	{ 'Vnd.Liquida'															, .F. }, ; //X3_TITULO
	{ 'Vnd.Liquida'															, .F. }, ; //X3_TITSPA
	{ 'Vnd.Liquida'															, .F. }, ; //X3_TITENG
	{ 'Venda Liquida Meta'													, .F. }, ; //X3_DESCRIC
	{ 'Venda Liquida Meta'													, .F. }, ; //X3_DESCSPA
	{ 'Venda Liquida Meta'													, .F. }, ; //X3_DESCENG
	{ '@E 999,999,999.99'													, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXJ'																	, .F. }, ; //X3_ARQUIVO
	{ '14'																	, .F. }, ; //X3_ORDEM
	{ 'AXJ_MMKPPE'															, .F. }, ; //X3_CAMPO
	{ 'N'																	, .F. }, ; //X3_TIPO
	{ 12																	, .T. }, ; //X3_TAMANHO
	{ 2																		, .F. }, ; //X3_DECIMAL
	{ '%Markup Meta'														, .F. }, ; //X3_TITULO
	{ '%Markup Meta'														, .F. }, ; //X3_TITSPA
	{ '%Markup Meta'														, .F. }, ; //X3_TITENG
	{ 'Percentual Markup Meta'												, .F. }, ; //X3_DESCRIC
	{ 'Percentual Markup Meta'												, .F. }, ; //X3_DESCSPA
	{ 'Percentual Markup Meta'												, .F. }, ; //X3_DESCENG
	{ '@E 999,999,999.99'													, .T. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXJ'																	, .F. }, ; //X3_ARQUIVO
	{ '15'																	, .F. }, ; //X3_ORDEM
	{ 'AXJ_MMKPVL'															, .F. }, ; //X3_CAMPO
	{ 'N'																	, .F. }, ; //X3_TIPO
	{ 12																	, .F. }, ; //X3_TAMANHO
	{ 2																		, .F. }, ; //X3_DECIMAL
	{ 'Markup Vlr.M'														, .F. }, ; //X3_TITULO
	{ 'Markup Vlr.M'														, .F. }, ; //X3_TITSPA
	{ 'Markup Vlr.M'														, .F. }, ; //X3_TITENG
	{ 'Markup Valor Meta'													, .F. }, ; //X3_DESCRIC
	{ 'Markup Valor Meta'													, .F. }, ; //X3_DESCSPA
	{ 'Markup Valor Meta'													, .F. }, ; //X3_DESCENG
	{ '@E 999,999,999.99'													, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXJ'																	, .F. }, ; //X3_ARQUIVO
	{ '16'																	, .F. }, ; //X3_ORDEM
	{ 'AXJ_MSLDZE'															, .F. }, ; //X3_CAMPO
	{ 'N'																	, .F. }, ; //X3_TIPO
	{ 12																	, .F. }, ; //X3_TAMANHO
	{ 2																		, .F. }, ; //X3_DECIMAL
	{ 'Saldo Zero M'														, .F. }, ; //X3_TITULO
	{ 'Saldo Zero M'														, .F. }, ; //X3_TITSPA
	{ 'Saldo Zero M'														, .F. }, ; //X3_TITENG
	{ 'Saldo Zero Meta'														, .F. }, ; //X3_DESCRIC
	{ 'Saldo Zero Meta'														, .F. }, ; //X3_DESCSPA
	{ 'Saldo Zero Meta'														, .F. }, ; //X3_DESCENG
	{ '@E 999,999,999.99'													, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXJ'																	, .F. }, ; //X3_ARQUIVO
	{ '17'																	, .F. }, ; //X3_ORDEM
	{ 'AXJ_MQTVEN'															, .F. }, ; //X3_CAMPO
	{ 'N'																	, .F. }, ; //X3_TIPO
	{ 12																	, .F. }, ; //X3_TAMANHO
	{ 2																		, .F. }, ; //X3_DECIMAL
	{ 'Qtd. Vendida'														, .F. }, ; //X3_TITULO
	{ 'Qtd. Vendida'														, .F. }, ; //X3_TITSPA
	{ 'Qtd. Vendida'														, .F. }, ; //X3_TITENG
	{ 'Quantidade Vendida Meta'												, .F. }, ; //X3_DESCRIC
	{ 'Quantidade Vendida Meta'												, .F. }, ; //X3_DESCSPA
	{ 'Quantidade Vendida Meta'												, .F. }, ; //X3_DESCENG
	{ '@E 999,999,999.99'													, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXJ'																	, .F. }, ; //X3_ARQUIVO
	{ '18'																	, .F. }, ; //X3_ORDEM
	{ 'AXJ_MQTCAD'															, .F. }, ; //X3_CAMPO
	{ 'N'																	, .F. }, ; //X3_TIPO
	{ 12																	, .F. }, ; //X3_TAMANHO
	{ 2																		, .F. }, ; //X3_DECIMAL
	{ 'Qtd.Cad.Meta'														, .F. }, ; //X3_TITULO
	{ 'Qtd.Cad.Meta'														, .F. }, ; //X3_TITSPA
	{ 'Qtd.Cad.Meta'														, .F. }, ; //X3_TITENG
	{ 'Quantidade Cadastros Meta'											, .F. }, ; //X3_DESCRIC
	{ 'Quantidade Cadastros Meta'											, .F. }, ; //X3_DESCSPA
	{ 'Quantidade Cadastros Meta'											, .F. }, ; //X3_DESCENG
	{ '@E 999,999,999.99'													, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXJ'																	, .F. }, ; //X3_ARQUIVO
	{ '19'																	, .F. }, ; //X3_ORDEM
	{ 'AXJ_MRECEB'															, .F. }, ; //X3_CAMPO
	{ 'N'																	, .F. }, ; //X3_TIPO
	{ 12																	, .F. }, ; //X3_TAMANHO
	{ 2																		, .F. }, ; //X3_DECIMAL
	{ 'Receb.Meta'															, .F. }, ; //X3_TITULO
	{ 'Receb.Meta'															, .F. }, ; //X3_TITSPA
	{ 'Receb.Meta'															, .F. }, ; //X3_TITENG
	{ 'Valor Recebimentos Meta'												, .F. }, ; //X3_DESCRIC
	{ 'Valor Recebimentos Meta'												, .F. }, ; //X3_DESCSPA
	{ 'Valor Recebimentos Meta'												, .F. }, ; //X3_DESCENG
	{ '@E 999,999,999.99'													, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXJ'																	, .F. }, ; //X3_ARQUIVO
	{ '20'																	, .F. }, ; //X3_ORDEM
	{ 'AXJ_MJUROS'															, .F. }, ; //X3_CAMPO
	{ 'N'																	, .F. }, ; //X3_TIPO
	{ 12																	, .F. }, ; //X3_TAMANHO
	{ 2																		, .F. }, ; //X3_DECIMAL
	{ 'Juros Meta'															, .F. }, ; //X3_TITULO
	{ 'Juros Meta'															, .F. }, ; //X3_TITSPA
	{ 'Juros Meta'															, .F. }, ; //X3_TITENG
	{ 'Valor Juros Meta'													, .F. }, ; //X3_DESCRIC
	{ 'Valor Juros Meta'													, .F. }, ; //X3_DESCSPA
	{ 'Valor Juros Meta'													, .F. }, ; //X3_DESCENG
	{ '@E 999,999,999.99'													, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

//
// Campos Tabela AXK
//
aAdd( aSX3, { ;
	{ 'AXK'																	, .F. }, ; //X3_ARQUIVO
	{ '01'																	, .F. }, ; //X3_ORDEM
	{ 'AXK_FILIAL'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 2																		, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Filial'																, .F. }, ; //X3_TITULO
	{ 'Sucursal'															, .F. }, ; //X3_TITSPA
	{ 'Branch'																, .F. }, ; //X3_TITENG
	{ 'Filial do Sistema'													, .F. }, ; //X3_DESCRIC
	{ 'Sucursal'															, .F. }, ; //X3_DESCSPA
	{ 'Branch of the System'												, .F. }, ; //X3_DESCENG
	{ '@!'																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ ''																	, .F. }, ; //X3_VISUAL
	{ ''																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ '033'																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ ''																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ ''																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXK'																	, .F. }, ; //X3_ARQUIVO
	{ '02'																	, .F. }, ; //X3_ORDEM
	{ 'AXK_ANO'																, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 4																		, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Ano Meta'															, .F. }, ; //X3_TITULO
	{ 'Ano Meta'															, .F. }, ; //X3_TITSPA
	{ 'Ano Meta'															, .F. }, ; //X3_TITENG
	{ 'Ano da Meta'															, .F. }, ; //X3_DESCRIC
	{ 'Ano da Meta'															, .F. }, ; //X3_DESCSPA
	{ 'Ano da Meta'															, .F. }, ; //X3_DESCENG
	{ '@R 9999'																, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXK'																	, .F. }, ; //X3_ARQUIVO
	{ '03'																	, .F. }, ; //X3_ORDEM
	{ 'AXK_MES'																, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 2																		, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Mes Meta'															, .F. }, ; //X3_TITULO
	{ 'Mes Meta'															, .F. }, ; //X3_TITSPA
	{ 'Mes Meta'															, .F. }, ; //X3_TITENG
	{ 'Mes da Meta'															, .F. }, ; //X3_DESCRIC
	{ 'Mes da Meta'															, .F. }, ; //X3_DESCSPA
	{ 'Mes da Meta'															, .F. }, ; //X3_DESCENG
	{ '@R 99'																, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXK'																	, .F. }, ; //X3_ARQUIVO
	{ '04'																	, .F. }, ; //X3_ORDEM
	{ 'AXK_TIPREG'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 1																		, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Tipo Reg.'															, .F. }, ; //X3_TITULO
	{ 'Tipo Reg.'															, .F. }, ; //X3_TITSPA
	{ 'Tipo Reg.'															, .F. }, ; //X3_TITENG
	{ 'Tipo Registro'														, .F. }, ; //X3_DESCRIC
	{ 'Tipo Registro'														, .F. }, ; //X3_DESCSPA
	{ 'Tipo Registro'														, .F. }, ; //X3_DESCENG
	{ ''																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ 'F=Filial;D=Diario;1=Departamento;2=Secao;3=Grupo;4=Subgrupo'			, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXK'																	, .F. }, ; //X3_ARQUIVO
	{ '05'																	, .F. }, ; //X3_ORDEM
	{ 'AXK_CODFIL'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ nTamFil																, .T. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Cod.Filial'															, .F. }, ; //X3_TITULO
	{ 'Cod.Filial'															, .F. }, ; //X3_TITSPA
	{ 'Cod.Filial'															, .F. }, ; //X3_TITENG
	{ 'Codigo da Filial'													, .F. }, ; //X3_DESCRIC
	{ 'Codigo da Filial'													, .F. }, ; //X3_DESCSPA
	{ 'Codigo da Filial'													, .F. }, ; //X3_DESCENG
	{ ''																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXK'																	, .F. }, ; //X3_ARQUIVO
	{ '06'																	, .F. }, ; //X3_ORDEM
	{ 'AXK_CODSUP'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 10																	, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Cod.Superior'														, .F. }, ; //X3_TITULO
	{ 'Cod.Superior'														, .F. }, ; //X3_TITSPA
	{ 'Cod.Superior'														, .F. }, ; //X3_TITENG
	{ 'Codigo do Superior'													, .F. }, ; //X3_DESCRIC
	{ 'Codigo do Superior'													, .F. }, ; //X3_DESCSPA
	{ 'Codigo do Superior'													, .F. }, ; //X3_DESCENG
	{ ''																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXK'																	, .F. }, ; //X3_ARQUIVO
	{ '07'																	, .F. }, ; //X3_ORDEM
	{ 'AXK_CODIGO'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 10																	, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Codigo'																, .F. }, ; //X3_TITULO
	{ 'Codigo'																, .F. }, ; //X3_TITSPA
	{ 'Codigo'																, .F. }, ; //X3_TITENG
	{ 'Codigo do Nivel'														, .F. }, ; //X3_DESCRIC
	{ 'Codigo do Nivel'														, .F. }, ; //X3_DESCSPA
	{ 'Codigo do Nivel'														, .F. }, ; //X3_DESCENG
	{ ''																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXK'																	, .F. }, ; //X3_ARQUIVO
	{ '08'																	, .F. }, ; //X3_ORDEM
	{ 'AXK_DESCRI'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 30																	, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Descricao'															, .F. }, ; //X3_TITULO
	{ 'Descricao'															, .F. }, ; //X3_TITSPA
	{ 'Descricao'															, .F. }, ; //X3_TITENG
	{ 'Descricao'															, .F. }, ; //X3_DESCRIC
	{ 'Descricao'															, .F. }, ; //X3_DESCSPA
	{ 'Descricao'															, .F. }, ; //X3_DESCENG
	{ ''																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXK'																	, .F. }, ; //X3_ARQUIVO
	{ '09'																	, .F. }, ; //X3_ORDEM
	{ 'AXK_HVNDLI'															, .F. }, ; //X3_CAMPO
	{ 'N'																	, .F. }, ; //X3_TIPO
	{ 12																	, .F. }, ; //X3_TAMANHO
	{ 2																		, .F. }, ; //X3_DECIMAL
	{ 'Vnd.Liq.Hist'														, .F. }, ; //X3_TITULO
	{ 'Vnd.Liq.Hist'														, .F. }, ; //X3_TITSPA
	{ 'Vnd.Liq.Hist'														, .F. }, ; //X3_TITENG
	{ 'Venda Liquida Historico'												, .F. }, ; //X3_DESCRIC
	{ 'Venda Liquida Historico'												, .F. }, ; //X3_DESCSPA
	{ 'Venda Liquida Historico'												, .F. }, ; //X3_DESCENG
	{ '@E 999,999,999.99'													, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXK'																	, .F. }, ; //X3_ARQUIVO
	{ '10'																	, .F. }, ; //X3_ORDEM
	{ 'AXK_HMKPVL'															, .F. }, ; //X3_CAMPO
	{ 'N'																	, .F. }, ; //X3_TIPO
	{ 12																	, .F. }, ; //X3_TAMANHO
	{ 2																		, .F. }, ; //X3_DECIMAL
	{ 'Vlr.Mkp.Hist'														, .F. }, ; //X3_TITULO
	{ 'Vlr.Mkp.Hist'														, .F. }, ; //X3_TITSPA
	{ 'Vlr.Mkp.Hist'														, .F. }, ; //X3_TITENG
	{ 'Valor de Markup Historico'											, .F. }, ; //X3_DESCRIC
	{ 'Valor de Markup Historico'											, .F. }, ; //X3_DESCSPA
	{ 'Valor de Markup Historico'											, .F. }, ; //X3_DESCENG
	{ '@E 999,999,999.99'													, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXK'																	, .F. }, ; //X3_ARQUIVO
	{ '11'																	, .F. }, ; //X3_ORDEM
	{ 'AXK_HMKPPE'															, .F. }, ; //X3_CAMPO
	{ 'N'																	, .F. }, ; //X3_TIPO
	{ 12																	, .T. }, ; //X3_TAMANHO
	{ 2																		, .F. }, ; //X3_DECIMAL
	{ '% Mkp. Hist.'														, .F. }, ; //X3_TITULO
	{ '% Mkp. Hist.'														, .F. }, ; //X3_TITSPA
	{ '% Mkp. Hist.'														, .F. }, ; //X3_TITENG
	{ 'Percentual Markup Histori'											, .F. }, ; //X3_DESCRIC
	{ 'Percentual Markup Histori'											, .F. }, ; //X3_DESCSPA
	{ 'Percentual Markup Histori'											, .F. }, ; //X3_DESCENG
	{ '@E 999,999,999.99'													, .T. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXK'																	, .F. }, ; //X3_ARQUIVO
	{ '12'																	, .F. }, ; //X3_ORDEM
	{ 'AXK_HSLDZE'															, .F. }, ; //X3_CAMPO
	{ 'N'																	, .F. }, ; //X3_TIPO
	{ 12																	, .F. }, ; //X3_TAMANHO
	{ 2																		, .F. }, ; //X3_DECIMAL
	{ 'Sald.Zero H'															, .F. }, ; //X3_TITULO
	{ 'Sald.Zero H'															, .F. }, ; //X3_TITSPA
	{ 'Sald.Zero H'															, .F. }, ; //X3_TITENG
	{ 'Saldo Zero Historico'												, .F. }, ; //X3_DESCRIC
	{ 'Saldo Zero Historico'												, .F. }, ; //X3_DESCSPA
	{ 'Saldo Zero Historico'												, .F. }, ; //X3_DESCENG
	{ '@E 999,999,999.99'													, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXK'																	, .F. }, ; //X3_ARQUIVO
	{ '13'																	, .F. }, ; //X3_ORDEM
	{ 'AXK_HQTVEN'															, .F. }, ; //X3_CAMPO
	{ 'N'																	, .F. }, ; //X3_TIPO
	{ 12																	, .F. }, ; //X3_TAMANHO
	{ 2																		, .F. }, ; //X3_DECIMAL
	{ 'Qtd.Vnd.Hist'														, .F. }, ; //X3_TITULO
	{ 'Qtd.Vnd.Hist'														, .F. }, ; //X3_TITSPA
	{ 'Qtd.Vnd.Hist'														, .F. }, ; //X3_TITENG
	{ 'Quantidade Venda Historic'											, .F. }, ; //X3_DESCRIC
	{ 'Quantidade Venda Historic'											, .F. }, ; //X3_DESCSPA
	{ 'Quantidade Venda Historic'											, .F. }, ; //X3_DESCENG
	{ '@E 999,999,999.99'													, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXK'																	, .F. }, ; //X3_ARQUIVO
	{ '14'																	, .F. }, ; //X3_ORDEM
	{ 'AXK_HQTCAD'															, .F. }, ; //X3_CAMPO
	{ 'N'																	, .F. }, ; //X3_TIPO
	{ 12																	, .F. }, ; //X3_TAMANHO
	{ 2																		, .F. }, ; //X3_DECIMAL
	{ 'Qtd.Cad.Hist'														, .F. }, ; //X3_TITULO
	{ 'Qtd.Cad.Hist'														, .F. }, ; //X3_TITSPA
	{ 'Qtd.Cad.Hist'														, .F. }, ; //X3_TITENG
	{ 'Quantidade Cadastro Hist.'											, .F. }, ; //X3_DESCRIC
	{ 'Quantidade Cadastro Hist.'											, .F. }, ; //X3_DESCSPA
	{ 'Quantidade Cadastro Hist.'											, .F. }, ; //X3_DESCENG
	{ '@E 999,999,999.99'													, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXK'																	, .F. }, ; //X3_ARQUIVO
	{ '15'																	, .F. }, ; //X3_ORDEM
	{ 'AXK_HRECEB'															, .F. }, ; //X3_CAMPO
	{ 'N'																	, .F. }, ; //X3_TIPO
	{ 12																	, .F. }, ; //X3_TAMANHO
	{ 2																		, .F. }, ; //X3_DECIMAL
	{ 'Receb.Hist.'															, .F. }, ; //X3_TITULO
	{ 'Receb.Hist.'															, .F. }, ; //X3_TITSPA
	{ 'Receb.Hist.'															, .F. }, ; //X3_TITENG
	{ 'Recebimentos Historico'												, .F. }, ; //X3_DESCRIC
	{ 'Recebimentos Historico'												, .F. }, ; //X3_DESCSPA
	{ 'Recebimentos Historico'												, .F. }, ; //X3_DESCENG
	{ '@E 999,999,999.99'													, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXK'																	, .F. }, ; //X3_ARQUIVO
	{ '16'																	, .F. }, ; //X3_ORDEM
	{ 'AXK_HJUROS'															, .F. }, ; //X3_CAMPO
	{ 'N'																	, .F. }, ; //X3_TIPO
	{ 12																	, .F. }, ; //X3_TAMANHO
	{ 2																		, .F. }, ; //X3_DECIMAL
	{ 'Juros Hist.'															, .F. }, ; //X3_TITULO
	{ 'Juros Hist.'															, .F. }, ; //X3_TITSPA
	{ 'Juros Hist.'															, .F. }, ; //X3_TITENG
	{ 'Juros Historico'														, .F. }, ; //X3_DESCRIC
	{ 'Juros Historico'														, .F. }, ; //X3_DESCSPA
	{ 'Juros Historico'														, .F. }, ; //X3_DESCENG
	{ '@E 999,999,999.99'													, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXK'																	, .F. }, ; //X3_ARQUIVO
	{ '17'																	, .F. }, ; //X3_ORDEM
	{ 'AXK_MVNDLI'															, .F. }, ; //X3_CAMPO
	{ 'N'																	, .F. }, ; //X3_TIPO
	{ 12																	, .F. }, ; //X3_TAMANHO
	{ 2																		, .F. }, ; //X3_DECIMAL
	{ 'Vnd.Liq.Meta'														, .F. }, ; //X3_TITULO
	{ 'Vnd.Liq.Meta'														, .F. }, ; //X3_TITSPA
	{ 'Vnd.Liq.Meta'														, .F. }, ; //X3_TITENG
	{ 'Venda Liquida Meta'													, .F. }, ; //X3_DESCRIC
	{ 'Venda Liquida Meta'													, .F. }, ; //X3_DESCSPA
	{ 'Venda Liquida Meta'													, .F. }, ; //X3_DESCENG
	{ '@E 999,999,999.99'													, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXK'																	, .F. }, ; //X3_ARQUIVO
	{ '18'																	, .F. }, ; //X3_ORDEM
	{ 'AXK_MMKPVL'															, .F. }, ; //X3_CAMPO
	{ 'N'																	, .F. }, ; //X3_TIPO
	{ 12																	, .F. }, ; //X3_TAMANHO
	{ 2																		, .F. }, ; //X3_DECIMAL
	{ 'Vlr.Mkp.Meta'														, .F. }, ; //X3_TITULO
	{ 'Vlr.Mkp.Meta'														, .F. }, ; //X3_TITSPA
	{ 'Vlr.Mkp.Meta'														, .F. }, ; //X3_TITENG
	{ 'Valor Markup Meta'													, .F. }, ; //X3_DESCRIC
	{ 'Valor Markup Meta'													, .F. }, ; //X3_DESCSPA
	{ 'Valor Markup Meta'													, .F. }, ; //X3_DESCENG
	{ '@E 999,999,999.99'													, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXK'																	, .F. }, ; //X3_ARQUIVO
	{ '19'																	, .F. }, ; //X3_ORDEM
	{ 'AXK_MMKPPE'															, .F. }, ; //X3_CAMPO
	{ 'N'																	, .F. }, ; //X3_TIPO
	{ 12																	, .T. }, ; //X3_TAMANHO
	{ 2																		, .F. }, ; //X3_DECIMAL
	{ '% Mkp. Meta'															, .F. }, ; //X3_TITULO
	{ '% Mkp. Meta'															, .F. }, ; //X3_TITSPA
	{ '% Mkp. Meta'															, .F. }, ; //X3_TITENG
	{ 'Percentual Markup Meta'												, .F. }, ; //X3_DESCRIC
	{ 'Percentual Markup Meta'												, .F. }, ; //X3_DESCSPA
	{ 'Percentual Markup Meta'												, .F. }, ; //X3_DESCENG
	{ '@E 999,999,999.99'													, .T. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXK'																	, .F. }, ; //X3_ARQUIVO
	{ '20'																	, .F. }, ; //X3_ORDEM
	{ 'AXK_MSLDZE'															, .F. }, ; //X3_CAMPO
	{ 'N'																	, .F. }, ; //X3_TIPO
	{ 12																	, .F. }, ; //X3_TAMANHO
	{ 2																		, .F. }, ; //X3_DECIMAL
	{ 'Sld.Zero Met'														, .F. }, ; //X3_TITULO
	{ 'Sld.Zero Met'														, .F. }, ; //X3_TITSPA
	{ 'Sld.Zero Met'														, .F. }, ; //X3_TITENG
	{ 'Saldo Zero Meta'														, .F. }, ; //X3_DESCRIC
	{ 'Saldo Zero Meta'														, .F. }, ; //X3_DESCSPA
	{ 'Saldo Zero Meta'														, .F. }, ; //X3_DESCENG
	{ '@E 999,999,999.99'													, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXK'																	, .F. }, ; //X3_ARQUIVO
	{ '21'																	, .F. }, ; //X3_ORDEM
	{ 'AXK_MQTVEN'															, .F. }, ; //X3_CAMPO
	{ 'N'																	, .F. }, ; //X3_TIPO
	{ 12																	, .F. }, ; //X3_TAMANHO
	{ 2																		, .F. }, ; //X3_DECIMAL
	{ 'Qtd.Vnd.Meta'														, .F. }, ; //X3_TITULO
	{ 'Qtd.Vnd.Meta'														, .F. }, ; //X3_TITSPA
	{ 'Qtd.Vnd.Meta'														, .F. }, ; //X3_TITENG
	{ 'Quantidade Vendas Meta'												, .F. }, ; //X3_DESCRIC
	{ 'Quantidade Vendas Meta'												, .F. }, ; //X3_DESCSPA
	{ 'Quantidade Vendas Meta'												, .F. }, ; //X3_DESCENG
	{ '@E 999,999,999.99'													, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXK'																	, .F. }, ; //X3_ARQUIVO
	{ '22'																	, .F. }, ; //X3_ORDEM
	{ 'AXK_MQTCAD'															, .F. }, ; //X3_CAMPO
	{ 'N'																	, .F. }, ; //X3_TIPO
	{ 12																	, .F. }, ; //X3_TAMANHO
	{ 2																		, .F. }, ; //X3_DECIMAL
	{ 'Qtd.Cad.Meta'														, .F. }, ; //X3_TITULO
	{ 'Qtd.Cad.Meta'														, .F. }, ; //X3_TITSPA
	{ 'Qtd.Cad.Meta'														, .F. }, ; //X3_TITENG
	{ 'Quantidade Cadastro Meta'											, .F. }, ; //X3_DESCRIC
	{ 'Quantidade Cadastro Meta'											, .F. }, ; //X3_DESCSPA
	{ 'Quantidade Cadastro Meta'											, .F. }, ; //X3_DESCENG
	{ '@E 999,999,999.99'													, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXK'																	, .F. }, ; //X3_ARQUIVO
	{ '23'																	, .F. }, ; //X3_ORDEM
	{ 'AXK_MRECEB'															, .F. }, ; //X3_CAMPO
	{ 'N'																	, .F. }, ; //X3_TIPO
	{ 12																	, .F. }, ; //X3_TAMANHO
	{ 2																		, .F. }, ; //X3_DECIMAL
	{ 'Receb.Meta'															, .F. }, ; //X3_TITULO
	{ 'Receb.Meta'															, .F. }, ; //X3_TITSPA
	{ 'Receb.Meta'															, .F. }, ; //X3_TITENG
	{ 'Recebimentos Meta'													, .F. }, ; //X3_DESCRIC
	{ 'Recebimentos Meta'													, .F. }, ; //X3_DESCSPA
	{ 'Recebimentos Meta'													, .F. }, ; //X3_DESCENG
	{ '@E 999,999,999.99'													, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXK'																	, .F. }, ; //X3_ARQUIVO
	{ '24'																	, .F. }, ; //X3_ORDEM
	{ 'AXK_MJUROS'															, .F. }, ; //X3_CAMPO
	{ 'N'																	, .F. }, ; //X3_TIPO
	{ 12																	, .F. }, ; //X3_TAMANHO
	{ 2																		, .F. }, ; //X3_DECIMAL
	{ 'Juros Meta'															, .F. }, ; //X3_TITULO
	{ 'Juros Meta'															, .F. }, ; //X3_TITSPA
	{ 'Juros Meta'															, .F. }, ; //X3_TITENG
	{ 'Juros Meta'															, .F. }, ; //X3_DESCRIC
	{ 'Juros Meta'															, .F. }, ; //X3_DESCSPA
	{ 'Juros Meta'															, .F. }, ; //X3_DESCENG
	{ '@E 999,999,999.99'													, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXK'																	, .F. }, ; //X3_ARQUIVO
	{ '25'																	, .F. }, ; //X3_ORDEM
	{ 'AXK_CAT1'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 10																	, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Categoria 1'															, .F. }, ; //X3_TITULO
	{ 'Categoria 1'															, .F. }, ; //X3_TITSPA
	{ 'Category 1'															, .F. }, ; //X3_TITENG
	{ 'Categoria 1'															, .F. }, ; //X3_DESCRIC
	{ 'Categoria 1'															, .F. }, ; //X3_DESCSPA
	{ 'Category 1'															, .F. }, ; //X3_DESCENG
	{ ''																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXK'																	, .F. }, ; //X3_ARQUIVO
	{ '26'																	, .F. }, ; //X3_ORDEM
	{ 'AXK_CAT2'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 10																	, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Categoria 2'															, .F. }, ; //X3_TITULO
	{ 'Categoria 2'															, .F. }, ; //X3_TITSPA
	{ 'Categoria 2'															, .F. }, ; //X3_TITENG
	{ 'Categoria 2'															, .F. }, ; //X3_DESCRIC
	{ 'Categoria 2'															, .F. }, ; //X3_DESCSPA
	{ 'Categoria 2'															, .F. }, ; //X3_DESCENG
	{ ''																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXK'																	, .F. }, ; //X3_ARQUIVO
	{ '27'																	, .F. }, ; //X3_ORDEM
	{ 'AXK_CAT3'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 10																	, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Categoria 3'															, .F. }, ; //X3_TITULO
	{ 'Categoria 3'															, .F. }, ; //X3_TITSPA
	{ 'Categoria 3'															, .F. }, ; //X3_TITENG
	{ 'Categoria 3'															, .F. }, ; //X3_DESCRIC
	{ 'Categoria 3'															, .F. }, ; //X3_DESCSPA
	{ 'Categoria 3'															, .F. }, ; //X3_DESCENG
	{ ''																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXK'																	, .F. }, ; //X3_ARQUIVO
	{ '28'																	, .F. }, ; //X3_ORDEM
	{ 'AXK_CAT4'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 10																	, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Categoria 4'															, .F. }, ; //X3_TITULO
	{ 'Categoria 4'															, .F. }, ; //X3_TITSPA
	{ 'Categoria 4'															, .F. }, ; //X3_TITENG
	{ 'Categoria 4'															, .F. }, ; //X3_DESCRIC
	{ 'Categoria 4'															, .F. }, ; //X3_DESCSPA
	{ 'Categoria 4'															, .F. }, ; //X3_DESCENG
	{ ''																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXK'																	, .F. }, ; //X3_ARQUIVO
	{ '29'																	, .F. }, ; //X3_ORDEM
	{ 'AXK_CAT5'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 10																	, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Categoria 5'															, .F. }, ; //X3_TITULO
	{ 'Categoria 5'															, .F. }, ; //X3_TITSPA
	{ 'Categoria 5'															, .F. }, ; //X3_TITENG
	{ 'Categoria 5'															, .F. }, ; //X3_DESCRIC
	{ 'Categoria 5'															, .F. }, ; //X3_DESCSPA
	{ 'Categoria 5'															, .F. }, ; //X3_DESCENG
	{ ''																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

//
// Campos Tabela AYM
//
aAdd( aSX3, { ;
	{ 'AYM'																	, .F. }, ; //X3_ARQUIVO
	{ '19'																	, .F. }, ; //X3_ORDEM
	{ 'AYM_NFILDE'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 30																	, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Nome Filial'															, .F. }, ; //X3_TITULO
	{ 'Nome Filial'															, .F. }, ; //X3_TITSPA
	{ 'Nome Filial'															, .F. }, ; //X3_TITENG
	{ 'Nome Filial Destino'													, .F. }, ; //X3_DESCRIC
	{ 'Nome Filial Destino'													, .F. }, ; //X3_DESCSPA
	{ 'Nome Filial Destino'													, .F. }, ; //X3_DESCENG
	{ ''																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AYM'																	, .F. }, ; //X3_ARQUIVO
	{ '20'																	, .F. }, ; //X3_ORDEM
	{ 'AYM_DTULTE'															, .F. }, ; //X3_CAMPO
	{ 'D'																	, .F. }, ; //X3_TIPO
	{ 8																		, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Dt.Ult.Ent.'															, .F. }, ; //X3_TITULO
	{ 'Dt.Ult.Ent.'															, .F. }, ; //X3_TITSPA
	{ 'Dt.Ult.Ent.'															, .F. }, ; //X3_TITENG
	{ 'Data Ultima Entrega'													, .F. }, ; //X3_DESCRIC
	{ 'Data Ultima Entrega'													, .F. }, ; //X3_DESCSPA
	{ 'Data Ultima Entrega'													, .F. }, ; //X3_DESCENG
	{ ''																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AYM'																	, .F. }, ; //X3_ARQUIVO
	{ '21'																	, .F. }, ; //X3_ORDEM
	{ 'AYM_QTDEST'															, .F. }, ; //X3_CAMPO
	{ 'N'																	, .F. }, ; //X3_TIPO
	{ 9																		, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Qtd. Estoque'														, .F. }, ; //X3_TITULO
	{ 'Qtd. Estoque'														, .F. }, ; //X3_TITSPA
	{ 'Qtd. Estoque'														, .F. }, ; //X3_TITENG
	{ 'Quantida em Estoque'													, .F. }, ; //X3_DESCRIC
	{ 'Quantida em Estoque'													, .F. }, ; //X3_DESCSPA
	{ 'Quantida em Estoque'													, .F. }, ; //X3_DESCENG
	{ '@E 999,999,999'														, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AYM'																	, .F. }, ; //X3_ARQUIVO
	{ '22'																	, .F. }, ; //X3_ORDEM
	{ 'AYM_QTDENT'															, .F. }, ; //X3_CAMPO
	{ 'N'																	, .F. }, ; //X3_TIPO
	{ 9																		, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Qtd.Ult.Entr'														, .F. }, ; //X3_TITULO
	{ 'Qtd.Ult.Entr'														, .F. }, ; //X3_TITSPA
	{ 'Qtd.Ult.Entr'														, .F. }, ; //X3_TITENG
	{ 'Quantidade Ultima Entrada'											, .F. }, ; //X3_DESCRIC
	{ 'Quantidade Ultima Entrada'											, .F. }, ; //X3_DESCSPA
	{ 'Quantidade Ultima Entrada'											, .F. }, ; //X3_DESCENG
	{ '@E 999,999,999'														, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AYM'																	, .F. }, ; //X3_ARQUIVO
	{ '23'																	, .F. }, ; //X3_ORDEM
	{ 'AYM_QTDVEN'															, .F. }, ; //X3_CAMPO
	{ 'N'																	, .F. }, ; //X3_TIPO
	{ 9																		, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Qtd.Vendida'															, .F. }, ; //X3_TITULO
	{ 'Qtd.Vendida'															, .F. }, ; //X3_TITSPA
	{ 'Qtd.Vendida'															, .F. }, ; //X3_TITENG
	{ 'Quantidade Vendida'													, .F. }, ; //X3_DESCRIC
	{ 'Quantidade Vendida'													, .F. }, ; //X3_DESCSPA
	{ 'Quantidade Vendida'													, .F. }, ; //X3_DESCENG
	{ '@E 999,999,999'														, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AYM'																	, .F. }, ; //X3_ARQUIVO
	{ '24'																	, .F. }, ; //X3_ORDEM
	{ 'AYM_QTDSUG'															, .F. }, ; //X3_CAMPO
	{ 'N'																	, .F. }, ; //X3_TIPO
	{ 9																		, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Qtd.Sugerida'														, .F. }, ; //X3_TITULO
	{ 'Qtd.Sugerida'														, .F. }, ; //X3_TITSPA
	{ 'Qtd.Sugerida'														, .F. }, ; //X3_TITENG
	{ 'Quantidade Sugerida'													, .F. }, ; //X3_DESCRIC
	{ 'Quantidade Sugerida'													, .F. }, ; //X3_DESCSPA
	{ 'Quantidade Sugerida'													, .F. }, ; //X3_DESCENG
	{ '@E 999,999,999'														, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AYM'																	, .F. }, ; //X3_ARQUIVO
	{ '25'																	, .F. }, ; //X3_ORDEM
	{ 'AYM_PRCVEN'															, .F. }, ; //X3_CAMPO
	{ 'N'																	, .F. }, ; //X3_TIPO
	{ 9																		, .F. }, ; //X3_TAMANHO
	{ 2																		, .F. }, ; //X3_DECIMAL
	{ 'Prc.Venda'															, .F. }, ; //X3_TITULO
	{ 'Prc.Venda'															, .F. }, ; //X3_TITSPA
	{ 'Prc.Venda'															, .F. }, ; //X3_TITENG
	{ 'Preco de Venda'														, .F. }, ; //X3_DESCRIC
	{ 'Preco de Venda'														, .F. }, ; //X3_DESCSPA
	{ 'Preco de Venda'														, .F. }, ; //X3_DESCENG
	{ '@E 999,999.99'														, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AYM'																	, .F. }, ; //X3_ARQUIVO
	{ '26'																	, .F. }, ; //X3_ORDEM
	{ 'AYM_VLRVEN'															, .F. }, ; //X3_CAMPO
	{ 'N'																	, .F. }, ; //X3_TIPO
	{ 14																	, .F. }, ; //X3_TAMANHO
	{ 2																		, .F. }, ; //X3_DECIMAL
	{ 'Vlr.Vendas'															, .F. }, ; //X3_TITULO
	{ 'Vlr.Vendas'															, .F. }, ; //X3_TITSPA
	{ 'Vlr.Vendas'															, .F. }, ; //X3_TITENG
	{ 'Valor das Vendas'													, .F. }, ; //X3_DESCRIC
	{ 'Valor das Vendas'													, .F. }, ; //X3_DESCSPA
	{ 'Valor das Vendas'													, .F. }, ; //X3_DESCENG
	{ '@E 99,999,999,999.99'												, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AYM'																	, .F. }, ; //X3_ARQUIVO
	{ '27'																	, .F. }, ; //X3_ORDEM
	{ 'AYM_MARKUP'															, .F. }, ; //X3_CAMPO
	{ 'N'																	, .F. }, ; //X3_TIPO
	{ 12																	, .T. }, ; //X3_TAMANHO
	{ 2																		, .F. }, ; //X3_DECIMAL
	{ 'Mkp.Real'															, .F. }, ; //X3_TITULO
	{ 'Mkp.Real'															, .F. }, ; //X3_TITSPA
	{ 'Mkp.Real'															, .F. }, ; //X3_TITENG
	{ 'Markup Real'															, .F. }, ; //X3_DESCRIC
	{ 'Markup Real'															, .F. }, ; //X3_DESCSPA
	{ 'Markup Real'															, .F. }, ; //X3_DESCENG
	{ '@E 999,999,999.99'													, .T. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AYM'																	, .F. }, ; //X3_ARQUIVO
	{ '28'																	, .F. }, ; //X3_ORDEM
	{ 'AYM_GIRO'															, .F. }, ; //X3_CAMPO
	{ 'N'																	, .F. }, ; //X3_TIPO
	{ 9																		, .F. }, ; //X3_TAMANHO
	{ 2																		, .F. }, ; //X3_DECIMAL
	{ '% Giro'																, .F. }, ; //X3_TITULO
	{ '% Giro'																, .F. }, ; //X3_TITSPA
	{ '% Giro'																, .F. }, ; //X3_TITENG
	{ 'Percentual de Giro'													, .F. }, ; //X3_DESCRIC
	{ 'Percentual de Giro'													, .F. }, ; //X3_DESCSPA
	{ 'Percentual de Giro'													, .F. }, ; //X3_DESCENG
	{ '@E 999,999.99'														, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AYM'																	, .F. }, ; //X3_ARQUIVO
	{ '29'																	, .F. }, ; //X3_ORDEM
	{ 'AYM_CSTVEN'															, .F. }, ; //X3_CAMPO
	{ 'N'																	, .F. }, ; //X3_TIPO
	{ 14																	, .F. }, ; //X3_TAMANHO
	{ 2																		, .F. }, ; //X3_DECIMAL
	{ 'Cust.Venda'															, .F. }, ; //X3_TITULO
	{ 'Cust.Venda'															, .F. }, ; //X3_TITSPA
	{ 'Cust.Venda'															, .F. }, ; //X3_TITENG
	{ 'Custo das Vendas'													, .F. }, ; //X3_DESCRIC
	{ 'Custo das Vendas'													, .F. }, ; //X3_DESCSPA
	{ 'Custo das Vendas'													, .F. }, ; //X3_DESCENG
	{ '@E 99,999,999,999.99'												, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

//
// Campos Tabela SC7
//
aAdd( aSX3, { ;
	{ 'SC7'																	, .F. }, ; //X3_ARQUIVO
	{ 'L1'																	, .F. }, ; //X3_ORDEM
	{ 'C7_01PERIN'															, .F. }, ; //X3_CAMPO
	{ 'D'																	, .F. }, ; //X3_TIPO
	{ 8																		, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Per.Inicial'															, .F. }, ; //X3_TITULO
	{ 'Per.Inicial'															, .F. }, ; //X3_TITSPA
	{ 'Per.Inicial'															, .F. }, ; //X3_TITENG
	{ 'Periodo Inicial de Vendas'											, .F. }, ; //X3_DESCRIC
	{ 'Periodo Inicial de Vendas'											, .F. }, ; //X3_DESCSPA
	{ 'Periodo Inicial de Vendas'											, .F. }, ; //X3_DESCENG
	{ ''																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'SC7'																	, .F. }, ; //X3_ARQUIVO
	{ 'L2'																	, .F. }, ; //X3_ORDEM
	{ 'C7_01PERFI'															, .F. }, ; //X3_CAMPO
	{ 'D'																	, .F. }, ; //X3_TIPO
	{ 8																		, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Per.Final'															, .F. }, ; //X3_TITULO
	{ 'Per.Final'															, .F. }, ; //X3_TITSPA
	{ 'Per.Final'															, .F. }, ; //X3_TITENG
	{ 'Periodo Final de Vendas'												, .F. }, ; //X3_DESCRIC
	{ 'Periodo Final de Vendas'												, .F. }, ; //X3_DESCSPA
	{ 'Periodo Final de Vendas'												, .F. }, ; //X3_DESCENG
	{ ''																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'SC7'																	, .F. }, ; //X3_ARQUIVO
	{ 'L3'																	, .F. }, ; //X3_ORDEM
	{ 'C7_01DTPC1'															, .F. }, ; //X3_CAMPO
	{ 'D'																	, .F. }, ; //X3_TIPO
	{ 8																		, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Dt.Ult.PC'															, .F. }, ; //X3_TITULO
	{ 'Dt.Ult.PC'															, .F. }, ; //X3_TITSPA
	{ 'Dt.Ult.PC'															, .F. }, ; //X3_TITENG
	{ 'Data do Ultimo Pedido'												, .F. }, ; //X3_DESCRIC
	{ 'Data do Ultimo Pedido'												, .F. }, ; //X3_DESCSPA
	{ 'Data do Ultimo Pedido'												, .F. }, ; //X3_DESCENG
	{ ''																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'SC7'																	, .F. }, ; //X3_ARQUIVO
	{ 'L4'																	, .F. }, ; //X3_ORDEM
	{ 'C7_01DTPC2'															, .F. }, ; //X3_CAMPO
	{ 'D'																	, .F. }, ; //X3_TIPO
	{ 8																		, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Dt.Penult.PC'														, .F. }, ; //X3_TITULO
	{ 'Dt.Penult.PC'														, .F. }, ; //X3_TITSPA
	{ 'Dt.Penult.PC'														, .F. }, ; //X3_TITENG
	{ 'Data do Penultimo Pedido'											, .F. }, ; //X3_DESCRIC
	{ 'Data do Penultimo Pedido'											, .F. }, ; //X3_DESCSPA
	{ 'Data do Penultimo Pedido'											, .F. }, ; //X3_DESCENG
	{ ''																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'SC7'																	, .F. }, ; //X3_ARQUIVO
	{ 'L5'																	, .F. }, ; //X3_ORDEM
	{ 'C7_01CATEG'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 10																	, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Categoria'															, .F. }, ; //X3_TITULO
	{ 'Categoria'															, .F. }, ; //X3_TITSPA
	{ 'Categoria'															, .F. }, ; //X3_TITENG
	{ 'Codigo da Categoria'													, .F. }, ; //X3_DESCRIC
	{ 'Codigo da Categoria'													, .F. }, ; //X3_DESCSPA
	{ 'Codigo da Categoria'													, .F. }, ; //X3_DESCENG
	{ ''																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ 'AY1'																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ 'Vazio() .Or. ExistCpo("AY0",M->C7_01CATEG,1)'						, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'SC7'																	, .F. }, ; //X3_ARQUIVO
	{ 'L6'																	, .F. }, ; //X3_ORDEM
	{ 'C7_01CODMA'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 6																		, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Marca'																, .F. }, ; //X3_TITULO
	{ 'Marca'																, .F. }, ; //X3_TITSPA
	{ 'Marca'																, .F. }, ; //X3_TITENG
	{ 'Codigo da Marca'														, .F. }, ; //X3_DESCRIC
	{ 'Codigo da Marca'														, .F. }, ; //X3_DESCSPA
	{ 'Codigo da Marca'														, .F. }, ; //X3_DESCENG
	{ ''																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ 'AY2'																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ 'Vazio() .Or. ExistCpo("AY2",M->C7_01CODMA,1)'						, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'SC7'																	, .F. }, ; //X3_ARQUIVO
	{ 'L7'																	, .F. }, ; //X3_ORDEM
	{ 'C7_01FFORN'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 1																		, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Filtra Forn.'														, .F. }, ; //X3_TITULO
	{ 'Filtra Forn.'														, .F. }, ; //X3_TITSPA
	{ 'Filtra Forn.'														, .F. }, ; //X3_TITENG
	{ 'Filtra Produtos do Forn.'											, .F. }, ; //X3_DESCRIC
	{ 'Filtra Produtos do Forn.'											, .F. }, ; //X3_DESCSPA
	{ 'Filtra Produtos do Forn.'											, .F. }, ; //X3_DESCENG
	{ ''																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ "'S'"																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ 'Pertence("SN")'														, .F. }, ; //X3_VLDUSER
	{ 'S=Sim;N=Nao'															, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'SC7'																	, .F. }, ; //X3_ARQUIVO
	{ 'L8'																	, .F. }, ; //X3_ORDEM
	{ 'C7_01PREPC'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 6																		, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Num. Pre PC'															, .F. }, ; //X3_TITULO
	{ 'Num. Pre PC'															, .F. }, ; //X3_TITSPA
	{ 'Num. Pre PC'															, .F. }, ; //X3_TITENG
	{ 'Numero Pre Pedido Compra'											, .F. }, ; //X3_DESCRIC
	{ 'Numero Pre Pedido Compra'											, .F. }, ; //X3_DESCSPA
	{ 'Numero Pre Pedido Compra'											, .F. }, ; //X3_DESCENG
	{ '@!'																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'S'																	, .F. }, ; //X3_BROWSE
	{ 'V'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'SC7'																	, .F. }, ; //X3_ARQUIVO
	{ 'L9'																	, .F. }, ; //X3_ORDEM
	{ 'C7_01DTVRB'															, .F. }, ; //X3_CAMPO
	{ 'D'																	, .F. }, ; //X3_TIPO
	{ 8																		, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Data Verba'															, .F. }, ; //X3_TITULO
	{ 'Data Verba'															, .F. }, ; //X3_TITSPA
	{ 'Data Verba'															, .F. }, ; //X3_TITENG
	{ 'Data da Verba de Compra'												, .F. }, ; //X3_DESCRIC
	{ 'Data da Verba de Compra'												, .F. }, ; //X3_DESCSPA
	{ 'Data da Verba de Compra'												, .F. }, ; //X3_DESCENG
	{ ''																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'S'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ '€'																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'SC7'																	, .T. }, ; //X3_ARQUIVO
	{ 'M0'																	, .T. }, ; //X3_ORDEM
	{ 'C7_01BONIF'															, .T. }, ; //X3_CAMPO
	{ 'C'																	, .T. }, ; //X3_TIPO
	{ 1																		, .T. }, ; //X3_TAMANHO
	{ 0																		, .T. }, ; //X3_DECIMAL
	{ 'Bonificado'															, .T. }, ; //X3_TITULO
	{ 'Bonificado'															, .T. }, ; //X3_TITSPA
	{ 'Bonificado'															, .T. }, ; //X3_TITENG
	{ 'Pedido Bonificado'													, .T. }, ; //X3_DESCRIC
	{ 'Pedido Bonificado'													, .T. }, ; //X3_DESCSPA
	{ 'Pedido Bonificado'													, .T. }, ; //X3_DESCENG
	{ '@!'																	, .T. }, ; //X3_PICTURE
	{ ''																	, .T. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .T. }, ; //X3_USADO
	{ '"N"'																	, .T. }, ; //X3_RELACAO
	{ ''																	, .T. }, ; //X3_F3
	{ 1																		, .T. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .T. }, ; //X3_RESERV
	{ ''																	, .T. }, ; //X3_CHECK
	{ ''																	, .T. }, ; //X3_TRIGGER
	{ 'U'																	, .T. }, ; //X3_PROPRI
	{ 'S'																	, .T. }, ; //X3_BROWSE
	{ 'A'																	, .T. }, ; //X3_VISUAL
	{ 'R'																	, .T. }, ; //X3_CONTEXT
	{ '€'																	, .F. }, ; //X3_OBRIGAT
	{ 'PERTENCE("SN")'														, .F. }, ; //X3_VLDUSER
	{ 'S=Sim;N=Nao'															, .T. }, ; //X3_CBOX
	{ ''																	, .T. }, ; //X3_CBOXSPA
	{ ''																	, .T. }, ; //X3_CBOXENG
	{ ''																	, .T. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .T. }, ; //X3_INIBRW
	{ ''																	, .T. }, ; //X3_GRPSXG
	{ ''																	, .T. }, ; //X3_FOLDER
	{ ''																	, .T. }, ; //X3_CONDSQL
	{ ''																	, .T. }, ; //X3_CHKSQL
	{ ''																	, .T. }, ; //X3_IDXSRV
	{ 'N'																	, .T. }, ; //X3_ORTOGRA
	{ ''																	, .T. }, ; //X3_TELA
	{ ''																	, .T. }, ; //X3_POSLGT
	{ 'N'																	, .T. }, ; //X3_IDXFLD
	{ ''																	, .T. }, ; //X3_AGRUP
	{ ''																	, .T. }, ; //X3_MODAL
	{ ''																	, .T. }} ) //X3_PYME

//
// Campos Tabela SY1
//
aAdd( aSX3, { ;
	{ 'SY1'																	, .F. }, ; //X3_ARQUIVO
	{ '15'																	, .F. }, ; //X3_ORDEM
	{ 'Y1_01APRPC'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 1																		, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Aprov.PC'															, .F. }, ; //X3_TITULO
	{ 'Aprov.PC'															, .F. }, ; //X3_TITSPA
	{ 'Aprov.PC'															, .F. }, ; //X3_TITENG
	{ 'Aprovacao Pedido de Compr'											, .F. }, ; //X3_DESCRIC
	{ 'Aprovacao Pedido de Compr'											, .F. }, ; //X3_DESCSPA
	{ 'Aprovacao Pedido de Compr'											, .F. }, ; //X3_DESCENG
	{ ''																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ '"N"'																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ 'S=Sim;N=Nao'															, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'SY1'																	, .F. }, ; //X3_ARQUIVO
	{ '16'																	, .F. }, ; //X3_ORDEM
	{ 'Y1_01PREPC'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 1																		, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Pre-Pedido'															, .F. }, ; //X3_TITULO
	{ 'Pre-Pedido'															, .F. }, ; //X3_TITSPA
	{ 'Pre-Pedido'															, .F. }, ; //X3_TITENG
	{ 'Inclusão de Pré-Pedido'												, .F. }, ; //X3_DESCRIC
	{ 'Inclusão de Pré-Pedido'												, .F. }, ; //X3_DESCSPA
	{ 'Inclusão de Pré-Pedido'												, .F. }, ; //X3_DESCENG
	{ '@!'																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ '"N"'																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ 'S=Sim;N=Nao'															, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'SY1'																	, .F. }, ; //X3_ARQUIVO
	{ '17'																	, .F. }, ; //X3_ORDEM
	{ 'Y1_01APPRE'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 1																		, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Aprov.Pre PC'														, .F. }, ; //X3_TITULO
	{ 'Aprov.Pre PC'														, .F. }, ; //X3_TITSPA
	{ 'Aprov.Pre PC'														, .F. }, ; //X3_TITENG
	{ 'Aprova Pré-Pedido Compra'											, .F. }, ; //X3_DESCRIC
	{ 'Aprova Pré-Pedido Compra'											, .F. }, ; //X3_DESCSPA
	{ 'Aprova Pré-Pedido Compra'											, .F. }, ; //X3_DESCENG
	{ '@!'																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ '"N"'																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ 'S=Sim;N=Nao'															, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'SY1'																	, .F. }, ; //X3_ARQUIVO
	{ '18'																	, .F. }, ; //X3_ORDEM
	{ 'Y1_01CDPRE'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 1																		, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Prod. Pre-PC'														, .F. }, ; //X3_TITULO
	{ 'Prod. Pre-PC'														, .F. }, ; //X3_TITSPA
	{ 'Prod. Pre-PC'														, .F. }, ; //X3_TITENG
	{ 'Cad. Produto Pre-Pedio PC'											, .F. }, ; //X3_DESCRIC
	{ 'Cad. Produto Pre-Pedio PC'											, .F. }, ; //X3_DESCSPA
	{ 'Cad. Produto Pre-Pedio PC'											, .F. }, ; //X3_DESCENG
	{ '@!'																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ '"N"'																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ 'S=Sim;N=Nao'															, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

//
// Campos Tabela AY8
//
aAdd( aSX3, { ;
	{ 'AY8'																	, .F. }, ; //X3_ARQUIVO
	{ '05'																	, .F. }, ; //X3_ORDEM
	{ 'AY8_TIPO'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 1																		, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Operacao'															, .F. }, ; //X3_TITULO
	{ 'Operacion'															, .F. }, ; //X3_TITSPA
	{ 'Operation'															, .F. }, ; //X3_TITENG
	{ 'Operacao'															, .F. }, ; //X3_DESCRIC
	{ 'Operacion'															, .F. }, ; //X3_DESCSPA
	{ 'Operation'															, .F. }, ; //X3_DESCENG
	{ '@!'																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128)					, .F. }, ; //X3_USADO
	{ "'2'"																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'V'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ 'Pertence("123")'														, .F. }, ; //X3_VLDUSER
	{ '1=Lote;2=Produto;3=Manutencao'										, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ '1'																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ 'S'																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

//
// Campos Tabela AYB
//
aAdd( aSX3, { ;
	{ 'AYB'																	, .F. }, ; //X3_ARQUIVO
	{ '23'																	, .F. }, ; //X3_ORDEM
	{ 'AYB_UPRC'															, .F. }, ; //X3_CAMPO
	{ 'N'																	, .F. }, ; //X3_TIPO
	{ 14																	, .F. }, ; //X3_TAMANHO
	{ 2																		, .F. }, ; //X3_DECIMAL
	{ 'Ult Prc Comp'														, .F. }, ; //X3_TITULO
	{ 'Ult Prc Comp'														, .F. }, ; //X3_TITSPA
	{ 'Ult Prc Comp'														, .F. }, ; //X3_TITENG
	{ 'Ult Prc Comp'														, .F. }, ; //X3_DESCRIC
	{ 'Ult Prc Comp'														, .F. }, ; //X3_DESCSPA
	{ 'Ult Prc Comp'														, .F. }, ; //X3_DESCENG
	{ '@E 99,999,999,999.99'												, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'V'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ '1'																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ 'S'																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AYB'																	, .F. }, ; //X3_ARQUIVO
	{ '24'																	, .F. }, ; //X3_ORDEM
	{ 'AYB_MKP'																, .F. }, ; //X3_CAMPO
	{ 'N'																	, .F. }, ; //X3_TIPO
	{ 12																	, .T. }, ; //X3_TAMANHO
	{ 2																		, .F. }, ; //X3_DECIMAL
	{ 'Markup'																, .F. }, ; //X3_TITULO
	{ 'Markup'																, .F. }, ; //X3_TITSPA
	{ 'Markup'																, .F. }, ; //X3_TITENG
	{ 'Markup'																, .F. }, ; //X3_DESCRIC
	{ 'Markup'																, .F. }, ; //X3_DESCSPA
	{ 'Markup'																, .F. }, ; //X3_DESCENG
	{ '@E 999,999,999.99'													, .T. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'V'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ '1'																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ 'S'																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AYB'																	, .F. }, ; //X3_ARQUIVO
	{ '25'																	, .F. }, ; //X3_ORDEM
	{ 'AYB_VLRDES'															, .F. }, ; //X3_CAMPO
	{ 'N'																	, .F. }, ; //X3_TIPO
	{ 14																	, .F. }, ; //X3_TAMANHO
	{ 2																		, .F. }, ; //X3_DECIMAL
	{ 'Vlr. Descont'														, .F. }, ; //X3_TITULO
	{ 'Vlr. Descont'														, .F. }, ; //X3_TITSPA
	{ 'Vlr. Descont'														, .F. }, ; //X3_TITENG
	{ 'Vlr. Descont'														, .F. }, ; //X3_DESCRIC
	{ 'Vlr. Descont'														, .F. }, ; //X3_DESCSPA
	{ 'Vlr. Descont'														, .F. }, ; //X3_DESCENG
	{ '@E 99,999,999,999.99'												, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'V'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ '1'																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ 'S'																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AYB'																	, .F. }, ; //X3_ARQUIVO
	{ '26'																	, .F. }, ; //X3_ORDEM
	{ 'AYB_IDADE'															, .F. }, ; //X3_CAMPO
	{ 'N'																	, .F. }, ; //X3_TIPO
	{ 6																		, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Idade'																, .F. }, ; //X3_TITULO
	{ 'Idade'																, .F. }, ; //X3_TITSPA
	{ 'Idade'																, .F. }, ; //X3_TITENG
	{ 'Idade'																, .F. }, ; //X3_DESCRIC
	{ 'Idade'																, .F. }, ; //X3_DESCSPA
	{ 'Idade'																, .F. }, ; //X3_DESCENG
	{ '@E 999,999'															, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ '1'																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ 'S'																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AYB'																	, .F. }, ; //X3_ARQUIVO
	{ '27'																	, .F. }, ; //X3_ORDEM
	{ 'AYB_QTDEST'															, .F. }, ; //X3_CAMPO
	{ 'N'																	, .F. }, ; //X3_TIPO
	{ 14																	, .F. }, ; //X3_TAMANHO
	{ 2																		, .F. }, ; //X3_DECIMAL
	{ 'Qtd Estoque'															, .F. }, ; //X3_TITULO
	{ 'Qtd Estoque'															, .F. }, ; //X3_TITSPA
	{ 'Qtd Estoque'															, .F. }, ; //X3_TITENG
	{ 'Qtd Estoque'															, .F. }, ; //X3_DESCRIC
	{ 'Qtd Estoque'															, .F. }, ; //X3_DESCSPA
	{ 'Qtd Estoque'															, .F. }, ; //X3_DESCENG
	{ '@E 99,999,999,999.99'												, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'V'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ '1'																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ 'S'																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AYB'																	, .F. }, ; //X3_ARQUIVO
	{ '28'																	, .F. }, ; //X3_ORDEM
	{ 'AYB_QTDVEN'															, .F. }, ; //X3_CAMPO
	{ 'N'																	, .F. }, ; //X3_TIPO
	{ 14																	, .F. }, ; //X3_TAMANHO
	{ 2																		, .F. }, ; //X3_DECIMAL
	{ 'Qtd. Vendas'															, .F. }, ; //X3_TITULO
	{ 'Qtd. Vendas'															, .F. }, ; //X3_TITSPA
	{ 'Qtd. Vendas'															, .F. }, ; //X3_TITENG
	{ 'Qtd. Vendas'															, .F. }, ; //X3_DESCRIC
	{ 'Qtd. Vendas'															, .F. }, ; //X3_DESCSPA
	{ 'Qtd. Vendas'															, .F. }, ; //X3_DESCENG
	{ '@E 99,999,999,999.99'												, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'V'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ '1'																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ 'S'																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AYB'																	, .F. }, ; //X3_ARQUIVO
	{ '29'																	, .F. }, ; //X3_ORDEM
	{ 'AYB_MDIARI'															, .F. }, ; //X3_CAMPO
	{ 'N'																	, .F. }, ; //X3_TIPO
	{ 5																		, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Media Diari.'														, .F. }, ; //X3_TITULO
	{ 'Media Diari.'														, .F. }, ; //X3_TITSPA
	{ 'Media Diari.'														, .F. }, ; //X3_TITENG
	{ 'Media Diari.'														, .F. }, ; //X3_DESCRIC
	{ 'Media Diari.'														, .F. }, ; //X3_DESCSPA
	{ 'Media Diari.'														, .F. }, ; //X3_DESCENG
	{ '@E 99,999'															, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'V'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ '1'																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ 'S'																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AYB'																	, .F. }, ; //X3_ARQUIVO
	{ '30'																	, .F. }, ; //X3_ORDEM
	{ 'AYB_GIRO'															, .F. }, ; //X3_CAMPO
	{ 'N'																	, .F. }, ; //X3_TIPO
	{ 12																	, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Giro'																, .F. }, ; //X3_TITULO
	{ 'Giro'																, .F. }, ; //X3_TITSPA
	{ 'Giro'																, .F. }, ; //X3_TITENG
	{ 'Giro'																, .F. }, ; //X3_DESCRIC
	{ 'Giro'																, .F. }, ; //X3_DESCSPA
	{ 'Giro'																, .F. }, ; //X3_DESCENG
	{ '@E 999,999,999,999'													, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'V'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ '1'																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ 'S'																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AYB'																	, .F. }, ; //X3_ARQUIVO
	{ '31'																	, .F. }, ; //X3_ORDEM
	{ 'AYB_QTDDEV'															, .F. }, ; //X3_CAMPO
	{ 'N'																	, .F. }, ; //X3_TIPO
	{ 14																	, .F. }, ; //X3_TAMANHO
	{ 2																		, .F. }, ; //X3_DECIMAL
	{ 'Qtd. Devol.'															, .F. }, ; //X3_TITULO
	{ 'Qtd. Devol.'															, .F. }, ; //X3_TITSPA
	{ 'Qtd. Devol.'															, .F. }, ; //X3_TITENG
	{ 'Qtd. Devol.'															, .F. }, ; //X3_DESCRIC
	{ 'Qtd. Devol.'															, .F. }, ; //X3_DESCSPA
	{ 'Qtd. Devol.'															, .F. }, ; //X3_DESCENG
	{ '@E 99,999,999,999.99'												, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'V'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ '1'																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ 'S'																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AYB'																	, .F. }, ; //X3_ARQUIVO
	{ '32'																	, .F. }, ; //X3_ORDEM
	{ 'AYB_QTDCOM'															, .F. }, ; //X3_CAMPO
	{ 'N'																	, .F. }, ; //X3_TIPO
	{ 14																	, .F. }, ; //X3_TAMANHO
	{ 2																		, .F. }, ; //X3_DECIMAL
	{ 'Qtd. Compra'															, .F. }, ; //X3_TITULO
	{ 'Qtd. Compra'															, .F. }, ; //X3_TITSPA
	{ 'Qtd. Compra'															, .F. }, ; //X3_TITENG
	{ 'Qtd. Compra'															, .F. }, ; //X3_DESCRIC
	{ 'Qtd. Compra'															, .F. }, ; //X3_DESCSPA
	{ 'Qtd. Compra'															, .F. }, ; //X3_DESCENG
	{ '@E 99,999,999,999.99'												, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'V'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ '1'																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ 'S'																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AYB'																	, .F. }, ; //X3_ARQUIVO
	{ '33'																	, .F. }, ; //X3_ORDEM
	{ 'AYB_PENDEN'															, .F. }, ; //X3_CAMPO
	{ 'N'																	, .F. }, ; //X3_TIPO
	{ 14																	, .F. }, ; //X3_TAMANHO
	{ 2																		, .F. }, ; //X3_DECIMAL
	{ 'Qtd Pendente'														, .F. }, ; //X3_TITULO
	{ 'Qtd Pendente'														, .F. }, ; //X3_TITSPA
	{ 'Qtd. Pendent'														, .F. }, ; //X3_TITENG
	{ 'Qtd Pendente'														, .F. }, ; //X3_DESCRIC
	{ 'Qtd Pendente'														, .F. }, ; //X3_DESCSPA
	{ 'Qtd Pendente'														, .F. }, ; //X3_DESCENG
	{ '@E 99,999,999,999.99'												, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'V'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ '1'																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ 'S'																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AYB'																	, .F. }, ; //X3_ARQUIVO
	{ '34'																	, .F. }, ; //X3_ORDEM
	{ 'AYB_CANC'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 1																		, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Cancelado'															, .F. }, ; //X3_TITULO
	{ 'Cancelado'															, .F. }, ; //X3_TITSPA
	{ 'Cancelado'															, .F. }, ; //X3_TITENG
	{ 'Cancelado'															, .F. }, ; //X3_DESCRIC
	{ 'Cancelado'															, .F. }, ; //X3_DESCSPA
	{ 'Cancelado'															, .F. }, ; //X3_DESCENG
	{ ''																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'V'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ '1'																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ 'S'																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

//
// Campos Tabela SB4
//
aAdd( aSX3, { ;
	{ 'SB4'																	, .F. }, ; //X3_ARQUIVO
	{ '02'																	, .F. }, ; //X3_ORDEM
	{ 'B4_01CAT1'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 10																	, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Grupo Linha'															, .F. }, ; //X3_TITULO
	{ 'Grupo linea'															, .F. }, ; //X3_TITSPA
	{ 'Line Group'															, .F. }, ; //X3_TITENG
	{ 'Grupo Linha'															, .F. }, ; //X3_DESCRIC
	{ 'Grupo linea'															, .F. }, ; //X3_DESCSPA
	{ 'Line Group'															, .F. }, ; //X3_DESCENG
	{ '@!'																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ 'CATEG1'																, .T. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ 'S'																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ '€'																	, .F. }, ; //X3_OBRIGAT
	{ 'Vazio() .Or. ExistCpo("AY0",M->B4_01CAT1,1)'							, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ 'INCLUI'																, .T. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .T. }, ; //X3_GRPSXG
	{ '1'																	, .T. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ '1'																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ 'S'																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'SB4'																	, .F. }, ; //X3_ARQUIVO
	{ '04'																	, .F. }, ; //X3_ORDEM
	{ 'B4_01CAT2'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 10																	, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Linha'																, .F. }, ; //X3_TITULO
	{ 'Linea'																, .F. }, ; //X3_TITSPA
	{ 'Row'																	, .F. }, ; //X3_TITENG
	{ 'Linha'																, .F. }, ; //X3_DESCRIC
	{ 'Linea'																, .F. }, ; //X3_DESCSPA
	{ 'Row'																	, .F. }, ; //X3_DESCENG
	{ '@!'																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ 'CATEG2'																, .T. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ 'S'																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ '€'																	, .F. }, ; //X3_OBRIGAT
	{ 'Vazio() .Or. ExistCpo("AY1",M->B4_01CAT1+M->B4_01CAT2,1)'			, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ 'INCLUI'																, .T. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .T. }, ; //X3_GRPSXG
	{ '1'																	, .T. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ '1'																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ 'S'																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'SB4'																	, .F. }, ; //X3_ARQUIVO
	{ '06'																	, .F. }, ; //X3_ORDEM
	{ 'B4_01CAT3'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 10																	, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Seção'																, .F. }, ; //X3_TITULO
	{ 'Seccion'																, .F. }, ; //X3_TITSPA
	{ 'Section'																, .F. }, ; //X3_TITENG
	{ 'Seção'																, .F. }, ; //X3_DESCRIC
	{ 'Seccion'																, .F. }, ; //X3_DESCSPA
	{ 'Section'																, .F. }, ; //X3_DESCENG
	{ '@!'																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ 'CATEG3'																, .T. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ 'S'																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ '€'																	, .F. }, ; //X3_OBRIGAT
	{ 'Vazio() .Or. ExistCpo("AY1",M->B4_01CAT2+M->B4_01CAT3,1)'			, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ 'INCLUI'																, .T. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .T. }, ; //X3_GRPSXG
	{ '1'																	, .T. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ '1'																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ 'S'																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'SB4'																	, .F. }, ; //X3_ARQUIVO
	{ '08'																	, .F. }, ; //X3_ORDEM
	{ 'B4_01CAT4'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 10																	, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Espécie'																, .F. }, ; //X3_TITULO
	{ 'Especie'																, .F. }, ; //X3_TITSPA
	{ 'Species'																, .F. }, ; //X3_TITENG
	{ 'Espécie'																, .F. }, ; //X3_DESCRIC
	{ 'Especie'																, .F. }, ; //X3_DESCSPA
	{ 'Species'																, .F. }, ; //X3_DESCENG
	{ '@!'																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ 'CATEG4'																, .T. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ 'S'																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ 'Vazio() .Or. ExistCpo("AY1",M->B4_01CAT3+M->B4_01CAT4,1)'			, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ 'INCLUI'																, .T. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .T. }, ; //X3_GRPSXG
	{ '1'																	, .T. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ '1'																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ 'S'																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'SB4'																	, .F. }, ; //X3_ARQUIVO
	{ '10'																	, .F. }, ; //X3_ORDEM
	{ 'B4_01CAT5'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 10																	, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Sub-Espécie'															, .F. }, ; //X3_TITULO
	{ 'Subespecie'															, .F. }, ; //X3_TITSPA
	{ 'Sub-Species'															, .F. }, ; //X3_TITENG
	{ 'Sub-Espécie'															, .F. }, ; //X3_DESCRIC
	{ 'Subespecie'															, .F. }, ; //X3_DESCSPA
	{ 'Sub-Species'															, .F. }, ; //X3_DESCENG
	{ '@!'																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ 'CATEG5'																, .T. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ 'S'																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ 'Vazio() .Or. ExistCpo("AY1",M->B4_01CAT4+M->B4_01CAT5,1)'			, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ 'INCLUI'																, .T. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .T. }, ; //X3_GRPSXG
	{ '1'																	, .T. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ '1'																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ 'S'																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME
	
aAdd( aSX3, { ;
	{ 'SB4'																	, .F. }, ; //X3_ARQUIVO
	{ '75'																	, .F. }, ; //X3_ORDEM
	{ 'B4_XTIPO'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 1																		, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Tipo'																, .F. }, ; //X3_TITULO
	{ 'Tipo'																, .F. }, ; //X3_TITSPA
	{ 'Tipo'																, .F. }, ; //X3_TITENG
	{ 'Tipo'																, .F. }, ; //X3_DESCRIC
	{ 'Tipo'																, .F. }, ; //X3_DESCSPA
	{ 'Tipo'																, .F. }, ; //X3_DESCENG
	{ ''																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ '"1"'																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ '1=PADRAO;2=SALDOZERO'												, .F. }, ; //X3_CBOX
	{ '1=PADRAO;2=SALDOZERO'												, .F. }, ; //X3_CBOXSPA
	{ '1=PADRAO;2=SALDOZERO'												, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ '1'																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ 'S'																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

//
// Campos Tabela AYK
//
aAdd( aSX3, { ;
	{ 'AYK'																	, .F. }, ; //X3_ARQUIVO
	{ '65'																	, .F. }, ; //X3_ORDEM
	{ 'AYK_GRUPO'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 4																		, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Grupo Produt'														, .F. }, ; //X3_TITULO
	{ 'Grupo Produt'														, .F. }, ; //X3_TITSPA
	{ 'Grupo Produt'														, .F. }, ; //X3_TITENG
	{ 'Grupo do Produto'													, .F. }, ; //X3_DESCRIC
	{ 'Grupo do Produto'													, .F. }, ; //X3_DESCSPA
	{ 'Grupo do Produto'													, .F. }, ; //X3_DESCENG
	{ '@!'																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'S'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ '1'																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ 'S'																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AYK'																	, .F. }, ; //X3_ARQUIVO
	{ '66'																	, .F. }, ; //X3_ORDEM
	{ 'AYK_DGRUPO'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 40																	, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Desc.Grupo'															, .F. }, ; //X3_TITULO
	{ 'Desc.Grupo'															, .F. }, ; //X3_TITSPA
	{ 'Desc.Grupo'															, .F. }, ; //X3_TITENG
	{ 'Descricao do Grupo'													, .F. }, ; //X3_DESCRIC
	{ 'Descricao do Grupo'													, .F. }, ; //X3_DESCSPA
	{ 'Descricao do Grupo'													, .F. }, ; //X3_DESCENG
	{ '@!'																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ '1'																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ 'S'																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

//
// Campos Tabela AXL
//
aAdd( aSX3, { ;
	{ 'AXL'																	, .F. }, ; //X3_ARQUIVO
	{ '01'																	, .F. }, ; //X3_ORDEM
	{ 'AXL_FILIAL'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ nTamFil																		, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Filial'																, .F. }, ; //X3_TITULO
	{ 'Sucursal'															, .F. }, ; //X3_TITSPA
	{ 'Branch'																, .F. }, ; //X3_TITENG
	{ 'Filial do Sistema'													, .F. }, ; //X3_DESCRIC
	{ 'Sucursal'															, .F. }, ; //X3_DESCSPA
	{ 'Branch of the System'												, .F. }, ; //X3_DESCENG
	{ '@!'																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ ''																	, .F. }, ; //X3_VISUAL
	{ ''																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ '033'																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ ''																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ ''																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXL'																	, .F. }, ; //X3_ARQUIVO
	{ '02'																	, .F. }, ; //X3_ORDEM
	{ 'AXL_NUM'																, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 6																		, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Numero'																, .F. }, ; //X3_TITULO
	{ 'Numero'																, .F. }, ; //X3_TITSPA
	{ 'Numero'																, .F. }, ; //X3_TITENG
	{ 'Numero da Divergencia'												, .F. }, ; //X3_DESCRIC
	{ 'Numero da Divergencia'												, .F. }, ; //X3_DESCSPA
	{ 'Numero da Divergencia'												, .F. }, ; //X3_DESCENG
	{ '@!'																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ 'GETSXENUM("AXL","AXL_NUM",,1)'										, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'S'																	, .F. }, ; //X3_BROWSE
	{ 'V'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXL'																	, .F. }, ; //X3_ARQUIVO
	{ '03'																	, .F. }, ; //X3_ORDEM
	{ 'AXL_EMISSA'															, .F. }, ; //X3_CAMPO
	{ 'D'																	, .F. }, ; //X3_TIPO
	{ 8																		, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Emissao'																, .F. }, ; //X3_TITULO
	{ 'Emissao'																, .F. }, ; //X3_TITSPA
	{ 'Emissao'																, .F. }, ; //X3_TITENG
	{ 'Data de Emissao'														, .F. }, ; //X3_DESCRIC
	{ 'Data de Emissao'														, .F. }, ; //X3_DESCSPA
	{ 'Data de Emissao'														, .F. }, ; //X3_DESCENG
	{ ''																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ 'DDATABASE'															, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'S'																	, .F. }, ; //X3_BROWSE
	{ 'V'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXL'																	, .F. }, ; //X3_ARQUIVO
	{ '04'																	, .F. }, ; //X3_ORDEM
	{ 'AXL_HORA'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 5																		, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Hora'																, .F. }, ; //X3_TITULO
	{ 'Hora'																, .F. }, ; //X3_TITSPA
	{ 'Hora'																, .F. }, ; //X3_TITENG
	{ 'Hora Inclusao'														, .F. }, ; //X3_DESCRIC
	{ 'Hora Inclusao'														, .F. }, ; //X3_DESCSPA
	{ 'Hora Inclusao'														, .F. }, ; //X3_DESCENG
	{ '@!'																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ 'TIME()'																, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'S'																	, .F. }, ; //X3_BROWSE
	{ 'V'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXL'																	, .F. }, ; //X3_ARQUIVO
	{ '05'																	, .F. }, ; //X3_ORDEM
	{ 'AXL_USER'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 25																	, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Usuário'																, .F. }, ; //X3_TITULO
	{ 'Usuário'																, .F. }, ; //X3_TITSPA
	{ 'Usuário'																, .F. }, ; //X3_TITENG
	{ 'Usuário'																, .F. }, ; //X3_DESCRIC
	{ 'Usuário'																, .F. }, ; //X3_DESCSPA
	{ 'Usuário'																, .F. }, ; //X3_DESCENG
	{ ''																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ 'CUSERNAME'															, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'S'																	, .F. }, ; //X3_BROWSE
	{ 'V'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXL'																	, .F. }, ; //X3_ARQUIVO
	{ '06'																	, .F. }, ; //X3_ORDEM
	{ 'AXL_TIPO'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 3																		, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Tipo'																, .F. }, ; //X3_TITULO
	{ 'Tipo'																, .F. }, ; //X3_TITSPA
	{ 'Tipo'																, .F. }, ; //X3_TITENG
	{ 'Tipo da Divergencia'													, .F. }, ; //X3_DESCRIC
	{ 'Tipo da Divergencia'													, .F. }, ; //X3_DESCSPA
	{ 'Tipo da Divergencia'													, .F. }, ; //X3_DESCENG
	{ '@!'																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ 'AXM'																	, .F. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ 'S'																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'S'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ '€'																	, .F. }, ; //X3_OBRIGAT
	{ 'Vazio() .OR. ExistCpo("AXM",M->AXL_TIPO,1)'							, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXL'																	, .F. }, ; //X3_ARQUIVO
	{ '07'																	, .F. }, ; //X3_ORDEM
	{ 'AXL_DESCTP'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 30																	, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Desc. Tipo'															, .F. }, ; //X3_TITULO
	{ 'Desc. Tipo'															, .F. }, ; //X3_TITSPA
	{ 'Desc. Tipo'															, .F. }, ; //X3_TITENG
	{ 'Descrição do Tipo'													, .F. }, ; //X3_DESCRIC
	{ 'Descrição do Tipo'													, .F. }, ; //X3_DESCSPA
	{ 'Descrição do Tipo'													, .F. }, ; //X3_DESCENG
	{ ''																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ 'IIF(INCLUI,"",POSICIONE("AXM",1,XFILIAL("AXM")+M->AXL_TIPO,"AXM_DESCRI"))', .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'S'																	, .F. }, ; //X3_BROWSE
	{ 'V'																	, .F. }, ; //X3_VISUAL
	{ 'V'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ 'POSICIONE("AXM",1,XFILIAL("AXM")+AXL->AXL_TIPO,"AXM_DESCRI")'		, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXL'																	, .F. }, ; //X3_ARQUIVO
	{ '08'																	, .F. }, ; //X3_ORDEM
	{ 'AXL_CODFOR'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 6																		, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Cod.Forn.'															, .F. }, ; //X3_TITULO
	{ 'Cod.Forn.'															, .F. }, ; //X3_TITSPA
	{ 'Cod.Forn.'															, .F. }, ; //X3_TITENG
	{ 'Codigo do Fornecedor'												, .F. }, ; //X3_DESCRIC
	{ 'Codigo do Fornecedor'												, .F. }, ; //X3_DESCSPA
	{ 'Codigo do Fornecedor'												, .F. }, ; //X3_DESCENG
	{ ''																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ 'IIF(INCLUI .AND. TYPE("_CCODFORN")<>"U",M->AXC_FORNEC,"")'			, .F. }, ; //X3_RELACAO
	{ 'FOR'																	, .F. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ 'S'																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'S'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ '€'																	, .F. }, ; //X3_OBRIGAT
	{ 'Vazio() .OR. T_SyValForn(M->AXL_CODFOR, @M->AXL_LOJFOR)'				, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXL'																	, .F. }, ; //X3_ARQUIVO
	{ '09'																	, .F. }, ; //X3_ORDEM
	{ 'AXL_LOJFOR'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 2																		, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Loja Forn.'															, .F. }, ; //X3_TITULO
	{ 'Loja Forn.'															, .F. }, ; //X3_TITSPA
	{ 'Loja Forn.'															, .F. }, ; //X3_TITENG
	{ 'Loja do Fornecedor'													, .F. }, ; //X3_DESCRIC
	{ 'Loja do Fornecedor'													, .F. }, ; //X3_DESCSPA
	{ 'Loja do Fornecedor'													, .F. }, ; //X3_DESCENG
	{ ''																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ 'IIF(INCLUI .AND. TYPE("_CLOJFORN")<>"U",M->AXC_LOJA,"")'				, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ 'S'																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'S'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ '€'																	, .F. }, ; //X3_OBRIGAT
	{ "Vazio() .OR. ExistCpo('SA2',M->(AXL_CODFOR+AXL_LOJFOR),1)"			, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXL'																	, .F. }, ; //X3_ARQUIVO
	{ '10'																	, .F. }, ; //X3_ORDEM
	{ 'AXL_NOMFOR'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 40																	, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Nome Forn.'															, .F. }, ; //X3_TITULO
	{ 'Nome Forn.'															, .F. }, ; //X3_TITSPA
	{ 'Nome Forn.'															, .F. }, ; //X3_TITENG
	{ 'Nome do Fornecedor'													, .F. }, ; //X3_DESCRIC
	{ 'Nome do Fornecedor'													, .F. }, ; //X3_DESCSPA
	{ 'Nome do Fornecedor'													, .F. }, ; //X3_DESCENG
	{ ''																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ 'IIF(INCLUI,"",POSICIONE("SA2",1,XFILIAL("SA2")+M->(AXL_CODFOR+AXL_LOJFOR),"A2_NOME"))', .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'S'																	, .F. }, ; //X3_BROWSE
	{ 'V'																	, .F. }, ; //X3_VISUAL
	{ 'V'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ 'POSICIONE("SA2",1,XFILIAL("SA2")+AXL->(AXL_CODFOR+AXL_LOJFOR),"A2_NOME")', .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXL'																	, .F. }, ; //X3_ARQUIVO
	{ '11'																	, .F. }, ; //X3_ORDEM
	{ 'AXL_NUMPRE'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 6																		, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Pre-Pedido'															, .F. }, ; //X3_TITULO
	{ 'Pre-Pedido'															, .F. }, ; //X3_TITSPA
	{ 'Pre-Pedido'															, .F. }, ; //X3_TITENG
	{ 'Numero do Pre-Pedido'												, .F. }, ; //X3_DESCRIC
	{ 'Numero do Pre-Pedido'												, .F. }, ; //X3_DESCSPA
	{ 'Numero do Pre-Pedido'												, .F. }, ; //X3_DESCENG
	{ ''																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ 'IIF(INCLUI .AND. TYPE("_CPREPC")<>"U",M->AXC_NUM,"")'				, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'S'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXL'																	, .F. }, ; //X3_ARQUIVO
	{ '12'																	, .F. }, ; //X3_ORDEM
	{ 'AXL_TITULO'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 30																	, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Titulo'																, .F. }, ; //X3_TITULO
	{ 'Titulo'																, .F. }, ; //X3_TITSPA
	{ 'Titulo'																, .F. }, ; //X3_TITENG
	{ 'Titulo da Divergencia'												, .F. }, ; //X3_DESCRIC
	{ 'Titulo da Divergencia'												, .F. }, ; //X3_DESCSPA
	{ 'Titulo da Divergencia'												, .F. }, ; //X3_DESCENG
	{ ''																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'S'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ '€'																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXL'																	, .F. }, ; //X3_ARQUIVO
	{ '13'																	, .F. }, ; //X3_ORDEM
	{ 'AXL_OBSERV'															, .F. }, ; //X3_CAMPO
	{ 'M'																	, .F. }, ; //X3_TIPO
	{ 10																	, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Observação'															, .F. }, ; //X3_TITULO
	{ 'Observação'															, .F. }, ; //X3_TITSPA
	{ 'Observação'															, .F. }, ; //X3_TITENG
	{ 'Observação'															, .F. }, ; //X3_DESCRIC
	{ 'Observação'															, .F. }, ; //X3_DESCSPA
	{ 'Observação'															, .F. }, ; //X3_DESCENG
	{ ''																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ '€'																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME
	
aAdd( aSX3, { ;
	{ 'AXL'																	, .T. }, ; //X3_ARQUIVO
	{ '14'																	, .T. }, ; //X3_ORDEM
	{ 'AXL_STATUS'															, .T. }, ; //X3_CAMPO
	{ 'C'																	, .T. }, ; //X3_TIPO
	{ 1																		, .T. }, ; //X3_TAMANHO
	{ 0																		, .T. }, ; //X3_DECIMAL
	{ 'Status'																, .T. }, ; //X3_TITULO
	{ 'Status'																, .T. }, ; //X3_TITSPA
	{ 'Status'																, .T. }, ; //X3_TITENG
	{ 'Status'																, .T. }, ; //X3_DESCRIC
	{ 'Status'																, .T. }, ; //X3_DESCSPA
	{ 'Status'																, .T. }, ; //X3_DESCENG
	{ '@!'																	, .T. }, ; //X3_PICTURE
	{ ''																	, .T. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .T. }, ; //X3_USADO
	{ '"1"'																	, .T. }, ; //X3_RELACAO
	{ ''																	, .T. }, ; //X3_F3
	{ 1																		, .T. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .T. }, ; //X3_RESERV
	{ ''																	, .T. }, ; //X3_CHECK
	{ ''																	, .T. }, ; //X3_TRIGGER
	{ 'U'																	, .T. }, ; //X3_PROPRI
	{ 'N'																	, .T. }, ; //X3_BROWSE
	{ 'A'																	, .T. }, ; //X3_VISUAL
	{ 'R'																	, .T. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ 'PERTENCE("123")'														, .F. }, ; //X3_VLDUSER
	{ '1=Aberto;2=Em Tratamento;3=Finalizado'								, .T. }, ; //X3_CBOX
	{ ''																	, .T. }, ; //X3_CBOXSPA
	{ ''																	, .T. }, ; //X3_CBOXENG
	{ ''																	, .T. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .T. }, ; //X3_INIBRW
	{ ''																	, .T. }, ; //X3_GRPSXG
	{ ''																	, .T. }, ; //X3_FOLDER
	{ ''																	, .T. }, ; //X3_CONDSQL
	{ ''																	, .T. }, ; //X3_CHKSQL
	{ ''																	, .T. }, ; //X3_IDXSRV
	{ 'N'																	, .T. }, ; //X3_ORTOGRA
	{ ''																	, .T. }, ; //X3_TELA
	{ ''																	, .T. }, ; //X3_POSLGT
	{ 'N'																	, .T. }, ; //X3_IDXFLD
	{ ''																	, .T. }, ; //X3_AGRUP
	{ ''																	, .T. }, ; //X3_MODAL
	{ ''																	, .T. }} ) //X3_PYME

//
// Campos Tabela AXM
//
aAdd( aSX3, { ;
	{ 'AXM'																	, .F. }, ; //X3_ARQUIVO
	{ '01'																	, .F. }, ; //X3_ORDEM
	{ 'AXM_FILIAL'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ nTamFil																, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Filial'																, .F. }, ; //X3_TITULO
	{ 'Sucursal'															, .F. }, ; //X3_TITSPA
	{ 'Branch'																, .F. }, ; //X3_TITENG
	{ 'Filial do Sistema'													, .F. }, ; //X3_DESCRIC
	{ 'Sucursal'															, .F. }, ; //X3_DESCSPA
	{ 'Branch of the System'												, .F. }, ; //X3_DESCENG
	{ '@!'																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'N'																	, .F. }, ; //X3_BROWSE
	{ ''																	, .F. }, ; //X3_VISUAL
	{ ''																	, .F. }, ; //X3_CONTEXT
	{ ''																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ '033'																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ ''																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ ''																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXM'																	, .F. }, ; //X3_ARQUIVO
	{ '02'																	, .F. }, ; //X3_ORDEM
	{ 'AXM_CODIGO'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 3																		, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Codigo'																, .F. }, ; //X3_TITULO
	{ 'Codigo'																, .F. }, ; //X3_TITSPA
	{ 'Codigo'																, .F. }, ; //X3_TITENG
	{ 'Codigo'																, .F. }, ; //X3_DESCRIC
	{ 'Codigo'																, .F. }, ; //X3_DESCSPA
	{ 'Codigo'																, .F. }, ; //X3_DESCENG
	{ '@!'																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ 'GETSXENUM("AXM","AXM_CODIGO",,1)'									, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 0																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'S'																	, .F. }, ; //X3_BROWSE
	{ 'V'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ '€'																	, .F. }, ; //X3_OBRIGAT
	{ 'ExistChav("AXM",M->AXM_CODIGO,1)'									, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME

aAdd( aSX3, { ;
	{ 'AXM'																	, .F. }, ; //X3_ARQUIVO
	{ '03'																	, .F. }, ; //X3_ORDEM
	{ 'AXM_DESCRI'															, .F. }, ; //X3_CAMPO
	{ 'C'																	, .F. }, ; //X3_TIPO
	{ 30																	, .F. }, ; //X3_TAMANHO
	{ 0																		, .F. }, ; //X3_DECIMAL
	{ 'Descrição'															, .F. }, ; //X3_TITULO
	{ 'Descrição'															, .F. }, ; //X3_TITSPA
	{ 'Descrição'															, .F. }, ; //X3_TITENG
	{ 'Descrição'															, .F. }, ; //X3_DESCRIC
	{ 'Descrição'															, .F. }, ; //X3_DESCSPA
	{ 'Descrição'															, .F. }, ; //X3_DESCENG
	{ ''																	, .F. }, ; //X3_PICTURE
	{ ''																	, .F. }, ; //X3_VALID
	{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
	Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, .F. }, ; //X3_USADO
	{ ''																	, .F. }, ; //X3_RELACAO
	{ ''																	, .F. }, ; //X3_F3
	{ 1																		, .F. }, ; //X3_NIVEL
	{ Chr(254) + Chr(192)													, .F. }, ; //X3_RESERV
	{ ''																	, .F. }, ; //X3_CHECK
	{ ''																	, .F. }, ; //X3_TRIGGER
	{ 'U'																	, .F. }, ; //X3_PROPRI
	{ 'S'																	, .F. }, ; //X3_BROWSE
	{ 'A'																	, .F. }, ; //X3_VISUAL
	{ 'R'																	, .F. }, ; //X3_CONTEXT
	{ '€'																	, .F. }, ; //X3_OBRIGAT
	{ ''																	, .F. }, ; //X3_VLDUSER
	{ ''																	, .F. }, ; //X3_CBOX
	{ ''																	, .F. }, ; //X3_CBOXSPA
	{ ''																	, .F. }, ; //X3_CBOXENG
	{ ''																	, .F. }, ; //X3_PICTVAR
	{ ''																	, .F. }, ; //X3_WHEN
	{ ''																	, .F. }, ; //X3_INIBRW
	{ ''																	, .F. }, ; //X3_GRPSXG
	{ ''																	, .F. }, ; //X3_FOLDER
	{ ''																	, .F. }, ; //X3_CONDSQL
	{ ''																	, .F. }, ; //X3_CHKSQL
	{ ''																	, .F. }, ; //X3_IDXSRV
	{ 'N'																	, .F. }, ; //X3_ORTOGRA
	{ ''																	, .F. }, ; //X3_TELA
	{ ''																	, .F. }, ; //X3_POSLGT
	{ 'N'																	, .F. }, ; //X3_IDXFLD
	{ ''																	, .F. }, ; //X3_AGRUP
	{ ''																	, .F. }, ; //X3_MODAL
	{ ''																	, .F. }} ) //X3_PYME


//
// Atualizando dicionário
//
nPosArq := aScan( aEstrut, { |x| AllTrim( x[1] ) == "X3_ARQUIVO" } )
nPosOrd := aScan( aEstrut, { |x| AllTrim( x[1] ) == "X3_ORDEM"   } )
nPosCpo := aScan( aEstrut, { |x| AllTrim( x[1] ) == "X3_CAMPO"   } )
nPosTam := aScan( aEstrut, { |x| AllTrim( x[1] ) == "X3_TAMANHO" } )
nPosSXG := aScan( aEstrut, { |x| AllTrim( x[1] ) == "X3_GRPSXG"  } )
nPosVld := aScan( aEstrut, { |x| AllTrim( x[1] ) == "X3_VALID"   } )

aSort( aSX3,,, { |x,y| x[nPosArq][1]+x[nPosOrd][1]+x[nPosCpo][1] < y[nPosArq][1]+y[nPosOrd][1]+y[nPosCpo][1] } )

oProcess:SetRegua2( Len( aSX3 ) )

dbSelectArea( "SX3" )
dbSetOrder( 2 )
cAliasAtu := ""

For nI := 1 To Len( aSX3 )

	//
	// Verifica se o campo faz parte de um grupo e ajusta tamanho
	//
	If !Empty( aSX3[nI][nPosSXG][1] )
		SXG->( dbSetOrder( 1 ) )
		If SXG->( MSSeek( aSX3[nI][nPosSXG][1] ) )
			If aSX3[nI][nPosTam][1] <> SXG->XG_SIZE
				aSX3[nI][nPosTam][1] := SXG->XG_SIZE
				AutoGrLog( "O tamanho do campo " + aSX3[nI][nPosCpo][1] + " NÃO atualizado e foi mantido em [" + ;
				AllTrim( Str( SXG->XG_SIZE ) ) + "]" + CRLF + ;
				" por pertencer ao grupo de campos [" + SXG->XG_GRUPO + "]" + CRLF )
			EndIf
		EndIf
	EndIf

	SX3->( dbSetOrder( 2 ) )

	If !( aSX3[nI][nPosArq][1] $ cAlias )
		cAlias += aSX3[nI][nPosArq][1] + "/"
		aAdd( aArqUpd, aSX3[nI][nPosArq][1] )
	EndIf

	If !SX3->( dbSeek( PadR( aSX3[nI][nPosCpo][1], nTamSeek ) ) )

		//
		// Busca ultima ocorrencia do alias
		//
		If ( aSX3[nI][nPosArq][1] <> cAliasAtu )
			cSeqAtu   := "00"
			cAliasAtu := aSX3[nI][nPosArq][1]

			dbSetOrder( 1 )
			SX3->( dbSeek( cAliasAtu + "ZZ", .T. ) )
			dbSkip( -1 )

			If ( SX3->X3_ARQUIVO == cAliasAtu )
				cSeqAtu := SX3->X3_ORDEM
			EndIf

			nSeqAtu := Val( RetAsc( cSeqAtu, 3, .F. ) )
		EndIf

		nSeqAtu++
		cSeqAtu := RetAsc( Str( nSeqAtu ), 2, .T. )

		RecLock( "SX3", .T. )
		For nJ := 1 To Len( aSX3[nI] )
			If     nJ == nPosOrd  // Ordem
				SX3->( FieldPut( FieldPos( aEstrut[nJ][1] ), cSeqAtu ) )

			ElseIf aEstrut[nJ][2] > 0
				SX3->( FieldPut( FieldPos( aEstrut[nJ][1] ), aSX3[nI][nJ][1] ) )

			EndIf
		Next nJ

		dbCommit()
		MsUnLock()

		AutoGrLog( "Criado campo " + aSX3[nI][nPosCpo][1] )

	Else

		//
		// Verifica se o campo faz parte de um grupo e ajsuta tamanho
		//
		If !Empty( SX3->X3_GRPSXG ) .AND. SX3->X3_GRPSXG <> aSX3[nI][nPosSXG][1]
			SXG->( dbSetOrder( 1 ) )
			If SXG->( MSSeek( SX3->X3_GRPSXG ) )
				If aSX3[nI][nPosTam][1] <> SXG->XG_SIZE
					aSX3[nI][nPosTam][1] := SXG->XG_SIZE
					AutoGrLog( "O tamanho do campo " + aSX3[nI][nPosCpo][1] + " NÃO atualizado e foi mantido em [" + ;
					AllTrim( Str( SXG->XG_SIZE ) ) + "]"+ CRLF + ;
					"   por pertencer ao grupo de campos [" + SX3->X3_GRPSXG + "]" + CRLF )
				EndIf
			EndIf
		EndIf

		//
		// Verifica todos os campos
		//
		For nJ := 1 To Len( aSX3[nI] )

			//
			// Se o campo estiver diferente da estrutura
			//
			If aSX3[nI][nJ][2]
				cX3Campo := AllTrim( aEstrut[nJ][1] )
				cX3Dado  := SX3->( FieldGet( aEstrut[nJ][2] ) )

				If  aEstrut[nJ][2] > 0 .AND. ;
					PadR( StrTran( AllToChar( cX3Dado ), " ", "" ), 250 ) <> ;
					PadR( StrTran( AllToChar( aSX3[nI][nJ][1] ), " ", "" ), 250 ) .AND. ;
					!cX3Campo == "X3_ORDEM"

					cMsg := "O campo " + aSX3[nI][nPosCpo][1] + " está com o " + cX3Campo + ;
					" com o conteúdo" + CRLF + ;
					"[" + RTrim( AllToChar( cX3Dado ) ) + "]" + CRLF + ;
					"que será substituído pelo NOVO conteúdo" + CRLF + ;
					"[" + RTrim( AllToChar( aSX3[nI][nJ][1] ) ) + "]" + CRLF + ;
					"Deseja substituir ? "
					/*
					If      lTodosSim
						nOpcA := 1
					ElseIf  lTodosNao
						nOpcA := 2
					Else
						nOpcA := Aviso( "ATUALIZAÇÃO DE DICIONÁRIOS E TABELAS", cMsg, { "Sim", "Não", "Sim p/Todos", "Não p/Todos" }, 3, "Diferença de conteúdo - SX3" )
						lTodosSim := ( nOpcA == 3 )
						lTodosNao := ( nOpcA == 4 )

						If lTodosSim
							nOpcA := 1
							lTodosSim := MsgNoYes( "Foi selecionada a opção de REALIZAR TODAS alterações no SX3 e NÃO MOSTRAR mais a tela de aviso." + CRLF + "Confirma a ação [Sim p/Todos] ?" )
						EndIf

						If lTodosNao
							nOpcA := 2
							lTodosNao := MsgNoYes( "Foi selecionada a opção de NÃO REALIZAR nenhuma alteração no SX3 que esteja diferente da base e NÃO MOSTRAR mais a tela de aviso." + CRLF + "Confirma esta ação [Não p/Todos]?" )
						EndIf

					EndIf
					*/
					If nOpcA == 1
						AutoGrLog( "Alterado campo " + aSX3[nI][nPosCpo][1] + CRLF + ;
						"   " + PadR( cX3Campo, 10 ) + " de [" + AllToChar( cX3Dado ) + "]" + CRLF + ;
						"            para [" + AllToChar( aSX3[nI][nJ][1] )           + "]" + CRLF )

						RecLock( "SX3", .F. )
						FieldPut( FieldPos( aEstrut[nJ][1] ), aSX3[nI][nJ][1] )
						MsUnLock()
					EndIf

				EndIf

			EndIf

		Next

	EndIf

	oProcess:IncRegua2( "Atualizando Campos de Tabelas (SX3)..." )

Next nI

AutoGrLog( CRLF + "Final da Atualização" + " SX3" + CRLF + Replicate( "-", 128 ) + CRLF )

Return NIL


//--------------------------------------------------------------------
/*/{Protheus.doc} FSAtuSIX
Função de processamento da gravação do SIX - Indices

@author TOTVS Protheus
@since  16/12/2016
@obs    Gerado por EXPORDIC - V.5.2.1.0 EFS / Upd. V.4.20.15 EFS
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function FSAtuSIX()
Local aEstrut   := {}
Local aSIX      := {}
Local lAlt      := .F.
Local lDelInd   := .F.
Local nI        := 0
Local nJ        := 0

AutoGrLog( "Ínicio da Atualização" + " SIX" + CRLF )

aEstrut := { "INDICE" , "ORDEM" , "CHAVE", "DESCRICAO", "DESCSPA"  , ;
             "DESCENG", "PROPRI", "F3"   , "NICKNAME" , "SHOWPESQ" }

//
// Tabela AXC
//
aAdd( aSIX, { ;
	'AXC'																	, ; //INDICE
	'1'																		, ; //ORDEM
	'AXC_FILIAL+AXC_NUM+AXC_ITEM'											, ; //CHAVE
	'Numero PC + Item'														, ; //DESCRICAO
	'Nr.PedCompra + Item'													, ; //DESCSPA
	'PO Number + Item'														, ; //DESCENG
	'S'																		, ; //PROPRI
	''																		, ; //F3
	''																		, ; //NICKNAME
	'S'																		} ) //SHOWPESQ

aAdd( aSIX, { ;
	'AXC'																	, ; //INDICE
	'2'																		, ; //ORDEM
	'AXC_FILIAL+AXC_SKU+AXC_FORNEC+AXC_LOJA+AXC_NUM'						, ; //CHAVE
	'Produto + Fornecedor + Loja + Numero PC'								, ; //DESCRICAO
	'Producto + Proveedor + Tienda + Nr.PedCompra'							, ; //DESCSPA
	'Product + Supplier + Unit + PO Number'									, ; //DESCENG
	'S'																		, ; //PROPRI
	'SB1+FOR'																, ; //F3
	''																		, ; //NICKNAME
	'S'																		} ) //SHOWPESQ

aAdd( aSIX, { ;
	'AXC'																	, ; //INDICE
	'3'																		, ; //ORDEM
	'AXC_FILIAL+AXC_FORNEC+AXC_LOJA+AXC_NUM'								, ; //CHAVE
	'Fornecedor + Loja + Numero PC'											, ; //DESCRICAO
	'Proveedor + Tienda + Nr.PedCompra'										, ; //DESCSPA
	'Supplier + Unit + PO Number'											, ; //DESCENG
	'S'																		, ; //PROPRI
	'FOR'																	, ; //F3
	''																		, ; //NICKNAME
	'S'																		} ) //SHOWPESQ

aAdd( aSIX, { ;
	'AXC'																	, ; //INDICE
	'4'																		, ; //ORDEM
	'AXC_FILIAL+AXC_SKU+AXC_NUM+AXC_ITEM'									, ; //CHAVE
	'Produto + Numero PC + Item'											, ; //DESCRICAO
	'Producto + Nr.PedCompra + Item'										, ; //DESCSPA
	'Product + PO Number + Item'											, ; //DESCENG
	'S'																		, ; //PROPRI
	'SB1'																	, ; //F3
	''																		, ; //NICKNAME
	'S'																		} ) //SHOWPESQ

aAdd( aSIX, { ;
	'AXC'																	, ; //INDICE
	'5'																		, ; //ORDEM
	'AXC_FILIAL+DTOS(AXC_EMISSA)+AXC_NUM+AXC_ITEM'							, ; //CHAVE
	'DT Emissao + Numero PC + Item'											, ; //DESCRICAO
	'Fch Emision + Nr.PedCompra + Item'										, ; //DESCSPA
	'Issue Date + PO Number + Item'											, ; //DESCENG
	'S'																		, ; //PROPRI
	''																		, ; //F3
	''																		, ; //NICKNAME
	'S'																		} ) //SHOWPESQ

aAdd( aSIX, { ;
	'AXC'																	, ; //INDICE
	'6'																		, ; //ORDEM
	'AXC_FILENT+AXC_SKU+AXC_FORNEC+AXC_LOJA+AXC_NUM'						, ; //CHAVE
	'Filial Entr. + Produto + Fornecedor + Loja + Numero PC'				, ; //DESCRICAO
	'Suc. Entrega + Producto + Proveedor + Tienda + Nr.PedCompra'			, ; //DESCSPA
	'Branch Deliv + Product + Supplier + Unit + PO Number'					, ; //DESCENG
	'S'																		, ; //PROPRI
	'XXX+SB1+FOR'															, ; //F3
	''																		, ; //NICKNAME
	'S'																		} ) //SHOWPESQ

aAdd( aSIX, { ;
	'AXC'																	, ; //INDICE
	'7'																		, ; //ORDEM
	'AXC_FILIAL+AXC_SKU+DTOS(AXC_DATPRF)'									, ; //CHAVE
	'Produto + Dt. Entrega'													, ; //DESCRICAO
	'Producto + Fch Entrega'												, ; //DESCSPA
	'Product + Delivery Dt.'												, ; //DESCENG
	'S'																		, ; //PROPRI
	'SB1'																	, ; //F3
	''																		, ; //NICKNAME
	'S'																		} ) //SHOWPESQ

aAdd( aSIX, { ;
	'AXC'																	, ; //INDICE
	'8'																		, ; //ORDEM
	'AXC_FILENT+AXC_FORNEC+AXC_LOJA+AXC_NUM'								, ; //CHAVE
	'Filial Entr. + Fornecedor + Loja + Numero PC'							, ; //DESCRICAO
	'Suc. Entrega + Proveedor + Tienda + Nr.PedCompra'						, ; //DESCSPA
	'Branch Deliv + Supplier + Unit + PO Number'							, ; //DESCENG
	'S'																		, ; //PROPRI
	'XXX+FOR'																, ; //F3
	''																		, ; //NICKNAME
	'S'																		} ) //SHOWPESQ

aAdd( aSIX, { ;
	'AXC'																	, ; //INDICE
	'9'																		, ; //ORDEM
	'AXC_FILENT+AXC_SKU+AXC_FORNEC+AXC_NUM'									, ; //CHAVE
	'Filial Entr. + Produto + Fornecedor + Numero PC'						, ; //DESCRICAO
	'Suc. Entrega + Producto + Proveedor + Nr.PedCompra'					, ; //DESCSPA
	'Branch Deliv + Product + Supplier + PO Number'							, ; //DESCENG
	'S'																		, ; //PROPRI
	'XXX+SB1+FOR'															, ; //F3
	''																		, ; //NICKNAME
	'S'																		} ) //SHOWPESQ

aAdd( aSIX, { ;
	'AXC'																	, ; //INDICE
	'A'																		, ; //ORDEM
	'AXC_FILENT+AXC_NUM+AXC_ITEM'											, ; //CHAVE
	'Filial Entr. + Numero PC + Item'										, ; //DESCRICAO
	'Suc. Entrega + Nr.PedCompra + Item'									, ; //DESCSPA
	'Branch Deliv + PO Number + Item'										, ; //DESCENG
	'S'																		, ; //PROPRI
	''																		, ; //F3
	''																		, ; //NICKNAME
	'S'																		} ) //SHOWPESQ

aAdd( aSIX, { ;
	'AXC'																	, ; //INDICE
	'B'																		, ; //ORDEM
	'AXC_FILIAL+DTOS(AXC_DATPRF)+AXC_SKU+AXC_NUM+AXC_ITEM'					, ; //CHAVE
	'Dt. Entrega + Produto + Numero PC + Item'								, ; //DESCRICAO
	'Fch Entrega + Producto + Nr.PedCompra + Item'							, ; //DESCSPA
	'Delivery Dt. + Product + PO Number + Item'								, ; //DESCENG
	'S'																		, ; //PROPRI
	''																		, ; //F3
	''																		, ; //NICKNAME
	'S'																		} ) //SHOWPESQ

aAdd( aSIX, { ;
	'AXC'																	, ; //INDICE
	'C'																		, ; //ORDEM
	'AXC_FILENT+AXC_FORNEC+AXC_LOJA+AXC_SKU'								, ; //CHAVE
	'Filial Entr. + Fornecedor + Loja + Produto'							, ; //DESCRICAO
	'Suc. Entrega + Proveedor + Tienda + Producto'							, ; //DESCSPA
	'Branch Deliv + Supplier + Unit + Product'								, ; //DESCENG
	'S'																		, ; //PROPRI
	'XXX+SA2+XXX+SB1'														, ; //F3
	''																		, ; //NICKNAME
	'S'																		} ) //SHOWPESQ

aAdd( aSIX, { ;
	'AXC'																	, ; //INDICE
	'D'																		, ; //ORDEM
	'AXC_FILENT+AXC_FORNEC+AXC_SKU'											, ; //CHAVE
	'Filial Entr. + Fornecedor + Produto'									, ; //DESCRICAO
	'Suc. Entrega + Proveedor + Producto'									, ; //DESCSPA
	'Branch Deliv + Supplier + Product'										, ; //DESCENG
	'S'																		, ; //PROPRI
	'XXX+SA2+SB1'															, ; //F3
	''																		, ; //NICKNAME
	'S'																		} ) //SHOWPESQ

aAdd( aSIX, { ;
	'AXC'																	, ; //INDICE
	'E'																		, ; //ORDEM
	'AXC_FILENT+AXC_SKU+AXC_NUM+AXC_ITEM'									, ; //CHAVE
	'Filial Entr. + Produto + Numero PC + Item'								, ; //DESCRICAO
	'Suc. Entrega + Producto + Nr.PedCompra + Item'							, ; //DESCSPA
	'Branch Deliv + Product + PO Number + Item'								, ; //DESCENG
	'S'																		, ; //PROPRI
	'XXX+SB1'																, ; //F3
	''																		, ; //NICKNAME
	'S'																		} ) //SHOWPESQ

aAdd( aSIX, { ;
	'AXC'																	, ; //INDICE
	'F'																		, ; //ORDEM
	'AXC_FILIAL+AXC_NUM+AXC_PRODP+AXC_IDGRD+AXC_FILDES'						, ; //CHAVE
	'Pedido+Produto Pai+Grade+Filial Destino'								, ; //DESCRICAO
	'Pedido+Produto Pai+Grade+Filial Destino'								, ; //DESCSPA
	'Pedido+Produto Pai+Grade+Filial Destino'								, ; //DESCENG
	'S'																		, ; //PROPRI
	''																		, ; //F3
	'SYMMAXC01'																, ; //NICKNAME
	'N'																		} ) //SHOWPESQ

aAdd( aSIX, { ;
	'AXC'																	, ; //INDICE
	'G'																		, ; //ORDEM
	'AXC_FILIAL+AXC_NUM+AXC_SKU+AXC_IDGRD'									, ; //CHAVE
	'Numero PC + Produto + ID Grade'										, ; //DESCRICAO
	'Numero PC + Produto + ID Grade'										, ; //DESCSPA
	'Numero PC + Produto + ID Grade'										, ; //DESCENG
	'S'																		, ; //PROPRI
	''																		, ; //F3
	'SYMMAXC02'																, ; //NICKNAME
	'N'																		} ) //SHOWPESQ

aAdd( aSIX, { ;
	'AXC'																	, ; //INDICE
	'H'																		, ; //ORDEM
	'AXC_FILIAL+AXC_NUM+AXC_ITPROD+AXC_IDGRD+AXC_FILDES'					, ; //CHAVE
	'Numero PC+Item Produto+ID Grade+Filial Dest.'							, ; //DESCRICAO
	'Nr.PedCompra+Item Produto+ID Grilla+Suc. Dest.'						, ; //DESCSPA
	'PO Number+Item Produto+ID Grilla+Suc. Dest.'							, ; //DESCENG
	'U'																		, ; //PROPRI
	''																		, ; //F3
	'SYMMAXC03'																, ; //NICKNAME
	'S'																		} ) //SHOWPESQ

//
// Tabela AXD
//
aAdd( aSIX, { ;
	'AXD'																	, ; //INDICE
	'1'																		, ; //ORDEM
	'AXD_FILIAL+AXD_NUM+AXD_PRODP+AXD_GRADE+AXD_FILDES'						, ; //CHAVE
	'Pedido+Produto Pai+ID Grade+Filial Dest.'								, ; //DESCRICAO
	'Pedido+Produto Pai+ID Grade+Filial Dest.'								, ; //DESCSPA
	'Pedido+Produto Pai+ID Grade+Filial Dest.'								, ; //DESCENG
	'S'																		, ; //PROPRI
	''																		, ; //F3
	''																		, ; //NICKNAME
	'S'																		} ) //SHOWPESQ

aAdd( aSIX, { ;
	'AXD'																	, ; //INDICE
	'2'																		, ; //ORDEM
	'AXD_FILIAL+AXD_NUM+AXD_SKU+AXD_FILDES+AXD_GRADE'						, ; //CHAVE
	'Pedido + SKU + Filial Dest. + ID Grade'								, ; //DESCRICAO
	'Pedido + SKU + Filial Dest. + ID Grade'								, ; //DESCSPA
	'Pedido + SKU + Filial Dest. + ID Grade'								, ; //DESCENG
	'S'																		, ; //PROPRI
	''																		, ; //F3
	''																		, ; //NICKNAME
	'S'																		} ) //SHOWPESQ

aAdd( aSIX, { ;
	'AXD'																	, ; //INDICE
	'3'																		, ; //ORDEM
	'AXD_FILIAL+AXD_FILORI+AXD_NUM+AXD_PRODP+AXD_GRADE+AXD_FILDES'			, ; //CHAVE
	'Fil. Origem + Pedido + Produto Pai + ID Grade + Filial Dest.'			, ; //DESCRICAO
	'Fil. Origem + Pedido + Produto Pai + ID Grade + Filial Dest.'			, ; //DESCSPA
	'Fil. Origem + Pedido + Produto Pai + ID Grade + Filial Dest.'			, ; //DESCENG
	'S'																		, ; //PROPRI
	''																		, ; //F3
	''																		, ; //NICKNAME
	'S'																		} ) //SHOWPESQ

aAdd( aSIX, { ;
	'AXD'																	, ; //INDICE
	'4'																		, ; //ORDEM
	'AXD_FILIAL+AXD_FILORI+AXD_NUM+AXD_ITPROD+AXD_GRADE+AXD_FILDES'			, ; //CHAVE
	'Fil. Origem+Pedido+Item Produto+ID Grade+Filial Dest.'					, ; //DESCRICAO
	'Suc. Origen+Pedido+Item Produto+ID Grilla+Suc. Dest.'					, ; //DESCSPA
	'Source Branc+Pedido+Item Produto+ID Grilla+Suc. Dest.'					, ; //DESCENG
	'U'																		, ; //PROPRI
	''																		, ; //F3
	''																		, ; //NICKNAME
	'S'																		} ) //SHOWPESQ

//
// Tabela AXE
//
aAdd( aSIX, { ;
	'AXE'																	, ; //INDICE
	'1'																		, ; //ORDEM
	'AXE_FILIAL+AXE_NUMPRE+AXE_ITPROD'										, ; //CHAVE
	'Num. Pre PC+Item Produto'												, ; //DESCRICAO
	'Num. Pre PC+Item Produto'												, ; //DESCSPA
	'Num. Pre PC+Item Produto'												, ; //DESCENG
	'U'																		, ; //PROPRI
	''																		, ; //F3
	''																		, ; //NICKNAME
	'S'																		} ) //SHOWPESQ

//
// Tabela AXH
//
aAdd( aSIX, { ;
	'AXH'																	, ; //INDICE
	'1'																		, ; //ORDEM
	'AXH_FILIAL+AXH_NUM+AXH_ANO+AXH_MES'									, ; //CHAVE
	'Num. Verba+Ano+Mes'													, ; //DESCRICAO
	'Num. Verba+Ano+Mes'													, ; //DESCSPA
	'Num. Verba+Ano+Mes'													, ; //DESCENG
	'U'																		, ; //PROPRI
	''																		, ; //F3
	''																		, ; //NICKNAME
	'S'																		} ) //SHOWPESQ

aAdd( aSIX, { ;
	'AXH'																	, ; //INDICE
	'2'																		, ; //ORDEM
	'AXH_FILIAL+AXH_ANO+AXH_MES+AXH_NUM'									, ; //CHAVE
	'Ano+Mes+Num. Verba'													, ; //DESCRICAO
	'Ano+Mes+Num. Verba'													, ; //DESCSPA
	'Ano+Mes+Num. Verba'													, ; //DESCENG
	'U'																		, ; //PROPRI
	''																		, ; //F3
	''																		, ; //NICKNAME
	'S'																		} ) //SHOWPESQ

//
// Tabela AXI
//
aAdd( aSIX, { ;
	'AXI'																	, ; //INDICE
	'1'																		, ; //ORDEM
	'AXI_FILIAL+AXI_NUM+AXI_ANO+AXI_MES+AXI_TIPREG+AXI_CODSUP+AXI_CODFIL+AXI_CODIGO', ; //CHAVE
	'Num. Verba+Ano+Mes+Tipo Reg.+Cod.Superior+Cod.Filial+Departamento'		, ; //DESCRICAO
	'Num. Verba+Ano+Mes+Tipo Reg.+Cod.Superior+Cod.Filial+Departamento'		, ; //DESCSPA
	'Num. Verba+Ano+Mes+Tipo Reg.+Cod.Superior+Cod.Filial+Departamento'		, ; //DESCENG
	'U'																		, ; //PROPRI
	''																		, ; //F3
	''																		, ; //NICKNAME
	'S'																		} ) //SHOWPESQ

//
// Tabela AXJ
//
aAdd( aSIX, { ;
	'AXJ'																	, ; //INDICE
	'1'																		, ; //ORDEM
	'AXJ_FILIAL+AXJ_ANO+AXJ_MES'											, ; //CHAVE
	'Ano Meta+Mes Meta'														, ; //DESCRICAO
	'Ano Meta+Mes Meta'														, ; //DESCSPA
	'Ano Meta+Mes Meta'														, ; //DESCENG
	'U'																		, ; //PROPRI
	''																		, ; //F3
	''																		, ; //NICKNAME
	'S'																		} ) //SHOWPESQ

//
// Tabela AXK
//
aAdd( aSIX, { ;
	'AXK'																	, ; //INDICE
	'1'																		, ; //ORDEM
	'AXK_FILIAL+AXK_ANO+AXK_MES+DTOS(AXK_DTMETA)'							, ; //CHAVE
	'Ano+Mes+Data'															, ; //DESCRICAO
	'Ano+Mes+Data'															, ; //DESCSPA
	'Ano+Mes+Data'															, ; //DESCENG
	'U'																		, ; //PROPRI
	''																		, ; //F3
	''																		, ; //NICKNAME
	'S'																		} ) //SHOWPESQ

//
// Tabela AXL
//
aAdd( aSIX, { ;
	'AXL'																	, ; //INDICE
	'1'																		, ; //ORDEM
	'AXL_FILIAL+AXL_NUM'													, ; //CHAVE
	'Numero'																, ; //DESCRICAO
	'Numero'																, ; //DESCSPA
	'Numero'																, ; //DESCENG
	'U'																		, ; //PROPRI
	''																		, ; //F3
	''																		, ; //NICKNAME
	'S'																		} ) //SHOWPESQ

aAdd( aSIX, { ;
	'AXL'																	, ; //INDICE
	'2'																		, ; //ORDEM
	'AXL_FILIAL+AXL_CODFOR+AXL_LOJFOR+AXL_NUM'								, ; //CHAVE
	'Cod.Forn.+Loja Forn.+Numero'											, ; //DESCRICAO
	'Cod.Forn.+Loja Forn.+Numero'											, ; //DESCSPA
	'Cod.Forn.+Loja Forn.+Numero'											, ; //DESCENG
	'U'																		, ; //PROPRI
	''																		, ; //F3
	''																		, ; //NICKNAME
	'S'																		} ) //SHOWPESQ

aAdd( aSIX, { ;
	'AXL'																	, ; //INDICE
	'3'																		, ; //ORDEM
	'AXL_FILIAL+AXL_CODFOR+AXL_LOJFOR+DTOS(AXL_EMISSA)+AXL_HORA'			, ; //CHAVE
	'Cod.Forn.+Loja Forn.+Emissao+Hora'										, ; //DESCRICAO
	'Cod.Forn.+Loja Forn.+Emissao+Hora'										, ; //DESCSPA
	'Cod.Forn.+Loja Forn.+Emissao+Hora'										, ; //DESCENG
	'U'																		, ; //PROPRI
	''																		, ; //F3
	''																		, ; //NICKNAME
	'S'																		} ) //SHOWPESQ

//
// Tabela AXM
//
aAdd( aSIX, { ;
	'AXM'																	, ; //INDICE
	'1'																		, ; //ORDEM
	'AXM_FILIAL+AXM_CODIGO+AXM_DESCRI'										, ; //CHAVE
	'Codigo+Descrição'														, ; //DESCRICAO
	'Codigo+Descrição'														, ; //DESCSPA
	'Codigo+Descrição'														, ; //DESCENG
	'U'																		, ; //PROPRI
	''																		, ; //F3
	''																		, ; //NICKNAME
	'S'																		} ) //SHOWPESQ

//
// Atualizando dicionário
//
oProcess:SetRegua2( Len( aSIX ) )

dbSelectArea( "SIX" )
SIX->( dbSetOrder( 1 ) )

For nI := 1 To Len( aSIX )

	lAlt    := .F.
	lDelInd := .F.

	If !SIX->( dbSeek( aSIX[nI][1] + aSIX[nI][2] ) )
		AutoGrLog( "Índice criado " + aSIX[nI][1] + "/" + aSIX[nI][2] + " - " + aSIX[nI][3] )
	Else
		lAlt := .T.
		aAdd( aArqUpd, aSIX[nI][1] )
		If !StrTran( Upper( AllTrim( CHAVE )       ), " ", "" ) == ;
		    StrTran( Upper( AllTrim( aSIX[nI][3] ) ), " ", "" )
			AutoGrLog( "Chave do índice alterado " + aSIX[nI][1] + "/" + aSIX[nI][2] + " - " + aSIX[nI][3] )
			lDelInd := .T. // Se for alteração precisa apagar o indice do banco
		EndIf
	EndIf

	RecLock( "SIX", !lAlt )
	For nJ := 1 To Len( aSIX[nI] )
		If FieldPos( aEstrut[nJ] ) > 0
			FieldPut( FieldPos( aEstrut[nJ] ), aSIX[nI][nJ] )
		EndIf
	Next nJ
	MsUnLock()

	dbCommit()

	If lDelInd
		TcInternal( 60, RetSqlName( aSIX[nI][1] ) + "|" + RetSqlName( aSIX[nI][1] ) + aSIX[nI][2] )
	EndIf

	oProcess:IncRegua2( "Atualizando índices..." )

Next nI

AutoGrLog( CRLF + "Final da Atualização" + " SIX" + CRLF + Replicate( "-", 128 ) + CRLF )

Return NIL


//--------------------------------------------------------------------
/*/{Protheus.doc} FSAtuSX6
Função de processamento da gravação do SX6 - Parâmetros

@author TOTVS Protheus
@since  16/12/2016
@obs    Gerado por EXPORDIC - V.5.2.1.0 EFS / Upd. V.4.20.15 EFS
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function FSAtuSX6()
Local aEstrut   := {}
Local aSX6      := {}
Local cAlias    := ""
Local cMsg      := ""
Local lContinua := .T.
Local lReclock  := .T.
Local lTodosNao := .F.
Local lTodosSim := .F.
Local nI        := 0
Local nJ        := 0
Local nOpcA     := 0
Local nTamFil   := Len( SX6->X6_FIL )
Local nTamVar   := Len( SX6->X6_VAR )

AutoGrLog( "Ínicio da Atualização" + " SX6" + CRLF )

aEstrut := { "X6_FIL"    , "X6_VAR"    , "X6_TIPO"   , "X6_DESCRIC", "X6_DSCSPA" , "X6_DSCENG" , "X6_DESC1"  , ;
             "X6_DSCSPA1", "X6_DSCENG1", "X6_DESC2"  , "X6_DSCSPA2", "X6_DSCENG2", "X6_CONTEUD", "X6_CONTSPA", ;
             "X6_CONTENG", "X6_PROPRI" , "X6_VALID"  , "X6_INIT"   , "X6_DEFPOR" , "X6_DEFSPA" , "X6_DEFENG" , ;
             "X6_PYME"   }

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'SY_NEWVERB'															, ; //X6_VAR
	'L'																		, ; //X6_TIPO
	'Habilita novo processo de verba de compras.'							, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'.T.'																	, ; //X6_CONTEUD
	'.T.'																	, ; //X6_CONTSPA
	'.T.'																	, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'SY_VA100A'																, ; //X6_VAR
	'N'																		, ; //X6_TIPO
	'Bloqueios: 1=Envia um alerta e gera pedido normal;'					, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	'2=Gera pedido normal, mas bloqueia pedido;'							, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	'3=Nao inclui pedido de compra'											, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'2'																		, ; //X6_CONTEUD
	'2'																		, ; //X6_CONTSPA
	'2'																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

aAdd( aSX6, { ;
	'  '																	, ; //X6_FIL
	'SY_NVLVERB'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Nivel da categoria para validacao da verba'							, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	'de compras nos pedidos.'												, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'4'																		, ; //X6_CONTEUD
	'4'																		, ; //X6_CONTSPA
	'4'																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

//
// Atualizando dicionário
//
oProcess:SetRegua2( Len( aSX6 ) )

dbSelectArea( "SX6" )
dbSetOrder( 1 )

For nI := 1 To Len( aSX6 )
	lContinua := .F.
	lReclock  := .F.

	If !SX6->( dbSeek( PadR( aSX6[nI][1], nTamFil ) + PadR( aSX6[nI][2], nTamVar ) ) )
		lContinua := .T.
		lReclock  := .T.
		AutoGrLog( "Foi incluído o parâmetro " + aSX6[nI][1] + aSX6[nI][2] + " Conteúdo [" + AllTrim( aSX6[nI][13] ) + "]" )
	Else
		lContinua := .T.
		lReclock  := .F.
		If !StrTran( SX6->X6_CONTEUD, " ", "" ) == StrTran( aSX6[nI][13], " ", "" )

			cMsg := "O parâmetro " + aSX6[nI][2] + " está com o conteúdo" + CRLF + ;
			"[" + RTrim( StrTran( SX6->X6_CONTEUD, " ", "" ) ) + "]" + CRLF + ;
			", que é será substituido pelo NOVO conteúdo " + CRLF + ;
			"[" + RTrim( StrTran( aSX6[nI][13]   , " ", "" ) ) + "]" + CRLF + ;
			"Deseja substituir ? "

			If      lTodosSim
				nOpcA := 1
			ElseIf  lTodosNao
				nOpcA := 2
			Else
				nOpcA := Aviso( "ATUALIZAÇÃO DE DICIONÁRIOS E TABELAS", cMsg, { "Sim", "Não", "Sim p/Todos", "Não p/Todos" }, 3, "Diferença de conteúdo - SX6" )
				lTodosSim := ( nOpcA == 3 )
				lTodosNao := ( nOpcA == 4 )

				If lTodosSim
					nOpcA := 1
					lTodosSim := MsgNoYes( "Foi selecionada a opção de REALIZAR TODAS alterações no SX6 e NÃO MOSTRAR mais a tela de aviso." + CRLF + "Confirma a ação [Sim p/Todos] ?" )
				EndIf

				If lTodosNao
					nOpcA := 2
					lTodosNao := MsgNoYes( "Foi selecionada a opção de NÃO REALIZAR nenhuma alteração no SX6 que esteja diferente da base e NÃO MOSTRAR mais a tela de aviso." + CRLF + "Confirma esta ação [Não p/Todos]?" )
				EndIf

			EndIf

			lContinua := ( nOpcA == 1 )

			If lContinua
				AutoGrLog( "Foi alterado o parâmetro " + aSX6[nI][1] + aSX6[nI][2] + " de [" + ;
				AllTrim( SX6->X6_CONTEUD ) + "]" + " para [" + AllTrim( aSX6[nI][13] ) + "]" )
			EndIf

		Else
			lContinua := .F.
		EndIf
	EndIf

	If lContinua
		If !( aSX6[nI][1] $ cAlias )
			cAlias += aSX6[nI][1] + "/"
		EndIf

		RecLock( "SX6", lReclock )
		For nJ := 1 To Len( aSX6[nI] )
			If FieldPos( aEstrut[nJ] ) > 0
				FieldPut( FieldPos( aEstrut[nJ] ), aSX6[nI][nJ] )
			EndIf
		Next nJ
		dbCommit()
		MsUnLock()
	EndIf

	oProcess:IncRegua2( "Atualizando Arquivos (SX6)..." )

Next nI

AutoGrLog( CRLF + "Final da Atualização" + " SX6" + CRLF + Replicate( "-", 128 ) + CRLF )

Return NIL


//--------------------------------------------------------------------
/*/{Protheus.doc} FSAtuSX7
Função de processamento da gravação do SX7 - Gatilhos

@author TOTVS Protheus
@since  16/12/2016
@obs    Gerado por EXPORDIC - V.5.2.1.0 EFS / Upd. V.4.20.15 EFS
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function FSAtuSX7()
Local aEstrut   := {}
Local aAreaSX3  := SX3->( GetArea() )
Local aSX7      := {}
Local cAlias    := ""
Local nI        := 0
Local nJ        := 0
Local nTamSeek  := Len( SX7->X7_CAMPO )

AutoGrLog( "Ínicio da Atualização" + " SX7" + CRLF )

aEstrut := { "X7_CAMPO", "X7_SEQUENC", "X7_REGRA", "X7_CDOMIN", "X7_TIPO", "X7_SEEK", ;
             "X7_ALIAS", "X7_ORDEM"  , "X7_CHAVE", "X7_PROPRI", "X7_CONDIC" }

//
// Campo AXC_CODCOM
//
aAdd( aSX7, { ;
	'AXC_CODCOM'															, ; //X7_CAMPO
	'001'																	, ; //X7_SEQUENC
	'POSICIONE("SY1",1,XFILIAL("SY1")+M->AXC_CODCOM,"Y1_NOME")'				, ; //X7_REGRA
	'AXC_NOMCOM'															, ; //X7_CDOMIN
	'P'																		, ; //X7_TIPO
	'N'																		, ; //X7_SEEK
	''																		, ; //X7_ALIAS
	0																		, ; //X7_ORDEM
	''																		, ; //X7_CHAVE
	'U'																		, ; //X7_PROPRI
	''																		} ) //X7_CONDIC

//
// Campo AXC_COND
//
aAdd( aSX7, { ;
	'AXC_COND'																, ; //X7_CAMPO
	'001'																	, ; //X7_SEQUENC
	'POSICIONE("SE4",1,XFILIAL("SE4")+M->AXC_COND,"E4_DESCRI")'				, ; //X7_REGRA
	'AXC_DESCPG'															, ; //X7_CDOMIN
	'P'																		, ; //X7_TIPO
	'N'																		, ; //X7_SEEK
	''																		, ; //X7_ALIAS
	0																		, ; //X7_ORDEM
	''																		, ; //X7_CHAVE
	'U'																		, ; //X7_PROPRI
	''																		} ) //X7_CONDIC

//
// Campo AXC_FORNEC
//
aAdd( aSX7, { ;
	'AXC_FORNEC'															, ; //X7_CAMPO
	'001'																	, ; //X7_SEQUENC
	'POSICIONE("SA2",1,XFILIAL("SA2")+M->(AXC_FORNEC+AXC_LOJA),"A2_NOME")'		, ; //X7_REGRA
	'AXC_NOMFOR'															, ; //X7_CDOMIN
	'P'																		, ; //X7_TIPO
	'N'																		, ; //X7_SEEK
	''																		, ; //X7_ALIAS
	0																		, ; //X7_ORDEM
	''																		, ; //X7_CHAVE
	'U'																		, ; //X7_PROPRI
	''																		} ) //X7_CONDIC

aAdd( aSX7, { ;
	'AXC_FORNEC'															, ; //X7_CAMPO
	'002'																	, ; //X7_SEQUENC
	'POSICIONE("SA2",1,XFILIAL("SA2")+M->(AXC_FORNEC+AXC_LOJA),"A2_EMAIL")'		, ; //X7_REGRA
	'AXC_EMAIL'																, ; //X7_CDOMIN
	'P'																		, ; //X7_TIPO
	'N'																		, ; //X7_SEEK
	''																		, ; //X7_ALIAS
	0																		, ; //X7_ORDEM
	''																		, ; //X7_CHAVE
	'U'																		, ; //X7_PROPRI
	''																		} ) //X7_CONDIC

aAdd( aSX7, { ;
	'AXC_FORNEC'															, ; //X7_CAMPO
	'003'																	, ; //X7_SEQUENC
	'POSICIONE("SA2",1,XFILIAL("SA2")+M->(AXC_FORNEC+AXC_LOJA),"A2_CONTATO")'	, ; //X7_REGRA
	'AXC_CONTAT'															, ; //X7_CDOMIN
	'P'																		, ; //X7_TIPO
	'N'																		, ; //X7_SEEK
	''																		, ; //X7_ALIAS
	0																		, ; //X7_ORDEM
	''																		, ; //X7_CHAVE
	'U'																		, ; //X7_PROPRI
	''																		} ) //X7_CONDIC

//
// Campo AXC_LOJA
//
aAdd( aSX7, { ;
	'AXC_LOJA'																, ; //X7_CAMPO
	'001'																	, ; //X7_SEQUENC
	'POSICIONE("SA2",1,XFILIAL("SA2")+M->(AXC_FORNEC+AXC_LOJA),"A2_NOME")'		, ; //X7_REGRA
	'AXC_NOMFOR'															, ; //X7_CDOMIN
	'P'																		, ; //X7_TIPO
	'N'																		, ; //X7_SEEK
	''																		, ; //X7_ALIAS
	0																		, ; //X7_ORDEM
	''																		, ; //X7_CHAVE
	'U'																		, ; //X7_PROPRI
	''																		} ) //X7_CONDIC

aAdd( aSX7, { ;
	'AXC_LOJA'																, ; //X7_CAMPO
	'002'																	, ; //X7_SEQUENC
	'POSICIONE("SA2",1,XFILIAL("SA2")+M->(AXC_FORNEC+AXC_LOJA),"A2_EMAIL")'		, ; //X7_REGRA
	'AXC_EMAIL'																, ; //X7_CDOMIN
	'P'																		, ; //X7_TIPO
	'N'																		, ; //X7_SEEK
	''																		, ; //X7_ALIAS
	0																		, ; //X7_ORDEM
	''																		, ; //X7_CHAVE
	'U'																		, ; //X7_PROPRI
	''																		} ) //X7_CONDIC

aAdd( aSX7, { ;
	'AXC_LOJA'																, ; //X7_CAMPO
	'003'																	, ; //X7_SEQUENC
	'POSICIONE("SA2",1,XFILIAL("SA2")+M->(AXC_FORNEC+AXC_LOJA),"A2_CONTATO")'	, ; //X7_REGRA
	'AXC_CONTAT'															, ; //X7_CDOMIN
	'P'																		, ; //X7_TIPO
	'N'																		, ; //X7_SEEK
	''																		, ; //X7_ALIAS
	0																		, ; //X7_ORDEM
	''																		, ; //X7_CHAVE
	'U'																		, ; //X7_PROPRI
	''																		} ) //X7_CONDIC

//
// Campo AXC_TRANSP
//
aAdd( aSX7, { ;
	'AXC_TRANSP'															, ; //X7_CAMPO
	'001'																	, ; //X7_SEQUENC
	'POSICIONE("SA4",1,XFILIAL("SA4")+M->AXC_TRANSP,"A4_NOME")'				, ; //X7_REGRA
	'AXC_NOMTRA'															, ; //X7_CDOMIN
	'P'																		, ; //X7_TIPO
	'N'																		, ; //X7_SEEK
	''																		, ; //X7_ALIAS
	0																		, ; //X7_ORDEM
	''																		, ; //X7_CHAVE
	'U'																		, ; //X7_PROPRI
	''																		} ) //X7_CONDIC

//
// Campo AXL_CODFOR
//
aAdd( aSX7, { ;
	'AXL_CODFOR'															, ; //X7_CAMPO
	'001'																	, ; //X7_SEQUENC
	'POSICIONE("SA2",1,XFILIAL("SA2")+M->(AXL_CODFOR+AXL_LOJFOR),"A2_NOME")'	, ; //X7_REGRA
	'AXL_NOMFOR'															, ; //X7_CDOMIN
	'P'																		, ; //X7_TIPO
	'N'																		, ; //X7_SEEK
	''																		, ; //X7_ALIAS
	0																		, ; //X7_ORDEM
	''																		, ; //X7_CHAVE
	'U'																		, ; //X7_PROPRI
	''																		} ) //X7_CONDIC

//
// Campo AXL_LOJFOR
//
aAdd( aSX7, { ;
	'AXL_LOJFOR'															, ; //X7_CAMPO
	'001'																	, ; //X7_SEQUENC
	'POSICIONE("SA2",1,XFILIAL("SA2")+M->(AXL_CODFOR+AXL_LOJFOR),"A2_NOME")'	, ; //X7_REGRA
	'AXL_NOMFOR'															, ; //X7_CDOMIN
	'P'																		, ; //X7_TIPO
	'N'																		, ; //X7_SEEK
	''																		, ; //X7_ALIAS
	0																		, ; //X7_ORDEM
	''																		, ; //X7_CHAVE
	'U'																		, ; //X7_PROPRI
	''																		} ) //X7_CONDIC

//
// Campo AXL_TIPO
//
aAdd( aSX7, { ;
	'AXL_TIPO'																, ; //X7_CAMPO
	'001'																	, ; //X7_SEQUENC
	'POSICIONE("AXM",1,xFilial("AXM")+M->AXL_TIPO,"AXM_DESCRI")'			, ; //X7_REGRA
	'AXL_DESCTP'															, ; //X7_CDOMIN
	'P'																		, ; //X7_TIPO
	'N'																		, ; //X7_SEEK
	''																		, ; //X7_ALIAS
	0																		, ; //X7_ORDEM
	''																		, ; //X7_CHAVE
	'U'																		, ; //X7_PROPRI
	''																		} ) //X7_CONDIC

//
// Atualizando dicionário
//
oProcess:SetRegua2( Len( aSX7 ) )

dbSelectArea( "SX3" )
dbSetOrder( 2 )

dbSelectArea( "SX7" )
dbSetOrder( 1 )

For nI := 1 To Len( aSX7 )

	If !SX7->( dbSeek( PadR( aSX7[nI][1], nTamSeek ) + aSX7[nI][2] ) )

		If !( aSX7[nI][1] $ cAlias )
			cAlias += aSX7[nI][1] + "/"
			AutoGrLog( "Foi incluído o gatilho " + aSX7[nI][1] + "/" + aSX7[nI][2] )
		EndIf

		RecLock( "SX7", .T. )
	Else

		If !( aSX7[nI][1] $ cAlias )
			cAlias += aSX7[nI][1] + "/"
			AutoGrLog( "Foi alterado o gatilho " + aSX7[nI][1] + "/" + aSX7[nI][2] )
		EndIf

		RecLock( "SX7", .F. )
	EndIf

	For nJ := 1 To Len( aSX7[nI] )
		If FieldPos( aEstrut[nJ] ) > 0
			FieldPut( FieldPos( aEstrut[nJ] ), aSX7[nI][nJ] )
		EndIf
	Next nJ

	dbCommit()
	MsUnLock()

	If SX3->( dbSeek( SX7->X7_CAMPO ) )
		RecLock( "SX3", .F. )
		SX3->X3_TRIGGER := "S"
		MsUnLock()
	EndIf

	oProcess:IncRegua2( "Atualizando Arquivos (SX7)..." )

Next nI

RestArea( aAreaSX3 )

AutoGrLog( CRLF + "Final da Atualização" + " SX7" + CRLF + Replicate( "-", 128 ) + CRLF )

Return NIL


//--------------------------------------------------------------------
/*/{Protheus.doc} FSAtuSXB
Função de processamento da gravação do SXB - Consultas Padrao

@author TOTVS Protheus
@since  16/12/2016
@obs    Gerado por EXPORDIC - V.5.2.1.0 EFS / Upd. V.4.20.15 EFS
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function FSAtuSXB()
Local aEstrut   := {}
Local aSXB      := {}
Local cAlias    := ""
Local cMsg      := ""
Local lTodosNao := .F.
Local lTodosSim := .F.
Local nI        := 0
Local nJ        := 0
Local nOpcA     := 0

AutoGrLog( "Ínicio da Atualização" + " SXB" + CRLF )

aEstrut := { "XB_ALIAS"  , "XB_TIPO"   , "XB_SEQ"    , "XB_COLUNA" , "XB_DESCRI" , "XB_DESCSPA", "XB_DESCENG", ;
             "XB_WCONTEM", "XB_CONTEM" }


//
// Consulta AXEAY2
//
aAdd( aSXB, { ;
	'AXEAY2'																, ; //XB_ALIAS
	'1'																		, ; //XB_TIPO
	'01'																	, ; //XB_SEQ
	'DB'																	, ; //XB_COLUNA
	'Cadastro de Marcas'													, ; //XB_DESCRI
	'Cadastro de Marcas'													, ; //XB_DESCSPA
	'Cadastro de Marcas'													, ; //XB_DESCENG
	''																		, ; //XB_WCONTEM
	'AY2'																	} ) //XB_CONTEM

aAdd( aSXB, { ;
	'AXEAY2'																, ; //XB_ALIAS
	'2'																		, ; //XB_TIPO
	'01'																	, ; //XB_SEQ
	'01'																	, ; //XB_COLUNA
	'Codigo'																, ; //XB_DESCRI
	'Codigo'																, ; //XB_DESCSPA
	'Codigo'																, ; //XB_DESCENG
	''																		, ; //XB_WCONTEM
	''																		} ) //XB_CONTEM

aAdd( aSXB, { ;
	'AXEAY2'																, ; //XB_ALIAS
	'2'																		, ; //XB_TIPO
	'02'																	, ; //XB_SEQ
	'02'																	, ; //XB_COLUNA
	'Descricao+codigo'														, ; //XB_DESCRI
	'Descricao+codigo'														, ; //XB_DESCSPA
	'Descricao+codigo'														, ; //XB_DESCENG
	''																		, ; //XB_WCONTEM
	''																		} ) //XB_CONTEM

aAdd( aSXB, { ;
	'AXEAY2'																, ; //XB_ALIAS
	'4'																		, ; //XB_TIPO
	'01'																	, ; //XB_SEQ
	'01'																	, ; //XB_COLUNA
	'Codigo'																, ; //XB_DESCRI
	'Código'																, ; //XB_DESCSPA
	'Code'																	, ; //XB_DESCENG
	''																		, ; //XB_WCONTEM
	'AY2_CODIGO'															} ) //XB_CONTEM

aAdd( aSXB, { ;
	'AXEAY2'																, ; //XB_ALIAS
	'4'																		, ; //XB_TIPO
	'01'																	, ; //XB_SEQ
	'02'																	, ; //XB_COLUNA
	'Descricao'																, ; //XB_DESCRI
	'Descripción'															, ; //XB_DESCSPA
	'Description'															, ; //XB_DESCENG
	''																		, ; //XB_WCONTEM
	'AY2_DESCR'																} ) //XB_CONTEM

aAdd( aSXB, { ;
	'AXEAY2'																, ; //XB_ALIAS
	'4'																		, ; //XB_TIPO
	'02'																	, ; //XB_SEQ
	'01'																	, ; //XB_COLUNA
	'Descricao'																, ; //XB_DESCRI
	'Descripción'															, ; //XB_DESCSPA
	'Description'															, ; //XB_DESCENG
	''																		, ; //XB_WCONTEM
	'AY2_DESCR'																} ) //XB_CONTEM

aAdd( aSXB, { ;
	'AXEAY2'																, ; //XB_ALIAS
	'4'																		, ; //XB_TIPO
	'02'																	, ; //XB_SEQ
	'02'																	, ; //XB_COLUNA
	'Codigo'																, ; //XB_DESCRI
	'Código'																, ; //XB_DESCSPA
	'Code'																	, ; //XB_DESCENG
	''																		, ; //XB_WCONTEM
	'AY2_CODIGO'															} ) //XB_CONTEM

aAdd( aSXB, { ;
	'AXEAY2'																, ; //XB_ALIAS
	'5'																		, ; //XB_TIPO
	'01'																	, ; //XB_SEQ
	''																		, ; //XB_COLUNA
	''																		, ; //XB_DESCRI
	''																		, ; //XB_DESCSPA
	''																		, ; //XB_DESCENG
	''																		, ; //XB_WCONTEM
	'AY2->AY2_CODIGO'														} ) //XB_CONTEM

//
// Consulta AXEDEP
//
aAdd( aSXB, { ;
	'AXEDEP'																, ; //XB_ALIAS
	'1'																		, ; //XB_TIPO
	'01'																	, ; //XB_SEQ
	'DB'																	, ; //XB_COLUNA
	'Consulta Categorias'													, ; //XB_DESCRI
	'Consulta Categorias'													, ; //XB_DESCSPA
	'Consulta Categorias'													, ; //XB_DESCENG
	''																		, ; //XB_WCONTEM
	'AY0'																	} ) //XB_CONTEM

aAdd( aSXB, { ;
	'AXEDEP'																, ; //XB_ALIAS
	'2'																		, ; //XB_TIPO
	'01'																	, ; //XB_SEQ
	'01'																	, ; //XB_COLUNA
	'Codigo'																, ; //XB_DESCRI
	'Codigo'																, ; //XB_DESCSPA
	'Codigo'																, ; //XB_DESCENG
	''																		, ; //XB_WCONTEM
	'AY0_001'																} ) //XB_CONTEM

aAdd( aSXB, { ;
	'AXEDEP'																, ; //XB_ALIAS
	'4'																		, ; //XB_TIPO
	'01'																	, ; //XB_SEQ
	'01'																	, ; //XB_COLUNA
	'Codigo'																, ; //XB_DESCRI
	'Código'																, ; //XB_DESCSPA
	'Code'																	, ; //XB_DESCENG
	''																		, ; //XB_WCONTEM
	'AY0_CODIGO'															} ) //XB_CONTEM

aAdd( aSXB, { ;
	'AXEDEP'																, ; //XB_ALIAS
	'4'																		, ; //XB_TIPO
	'01'																	, ; //XB_SEQ
	'02'																	, ; //XB_COLUNA
	'Descricao'																, ; //XB_DESCRI
	'Descripción'															, ; //XB_DESCSPA
	'Description'															, ; //XB_DESCENG
	''																		, ; //XB_WCONTEM
	'AY0_DESC'																} ) //XB_CONTEM

aAdd( aSXB, { ;
	'AXEDEP'																, ; //XB_ALIAS
	'5'																		, ; //XB_TIPO
	'01'																	, ; //XB_SEQ
	''																		, ; //XB_COLUNA
	''																		, ; //XB_DESCRI
	''																		, ; //XB_DESCSPA
	''																		, ; //XB_DESCENG
	''																		, ; //XB_WCONTEM
	'AY0->AY0_CODIGO'														} ) //XB_CONTEM

aAdd( aSXB, { ;
	'AXEDEP'																, ; //XB_ALIAS
	'6'																		, ; //XB_TIPO
	'01'																	, ; //XB_SEQ
	''																		, ; //XB_COLUNA
	''																		, ; //XB_DESCRI
	''																		, ; //XB_DESCSPA
	''																		, ; //XB_DESCENG
	''																		, ; //XB_WCONTEM
	'AY0->AY0_TIPO == "1"'													} ) //XB_CONTEM

//
// Consulta AXEESP
//
aAdd( aSXB, { ;
	'AXEESP'																, ; //XB_ALIAS
	'1'																		, ; //XB_TIPO
	'01'																	, ; //XB_SEQ
	'DB'																	, ; //XB_COLUNA
	'Consulta Categorias'													, ; //XB_DESCRI
	'Consulta Categorias'													, ; //XB_DESCSPA
	'Consulta Categorias'													, ; //XB_DESCENG
	''																		, ; //XB_WCONTEM
	'AY1'																	} ) //XB_CONTEM

aAdd( aSXB, { ;
	'AXEESP'																, ; //XB_ALIAS
	'2'																		, ; //XB_TIPO
	'01'																	, ; //XB_SEQ
	'02'																	, ; //XB_COLUNA
	'Sub.categor.+codigo'													, ; //XB_DESCRI
	'Sub.categor.+codigo'													, ; //XB_DESCSPA
	'Sub.categor.+codigo'													, ; //XB_DESCENG
	''																		, ; //XB_WCONTEM
	'AY1_002'																} ) //XB_CONTEM

aAdd( aSXB, { ;
	'AXEESP'																, ; //XB_ALIAS
	'4'																		, ; //XB_TIPO
	'01'																	, ; //XB_SEQ
	'01'																	, ; //XB_COLUNA
	'Código'																, ; //XB_DESCRI
	'Código'																, ; //XB_DESCSPA
	'Código'																, ; //XB_DESCENG
	''																		, ; //XB_WCONTEM
	'AY1_SUBCAT'															} ) //XB_CONTEM

aAdd( aSXB, { ;
	'AXEESP'																, ; //XB_ALIAS
	'4'																		, ; //XB_TIPO
	'01'																	, ; //XB_SEQ
	'02'																	, ; //XB_COLUNA
	'Descrição'																, ; //XB_DESCRI
	'Descrição'																, ; //XB_DESCSPA
	'Descrição'																, ; //XB_DESCENG
	''																		, ; //XB_WCONTEM
	'AY1_DESCSU'															} ) //XB_CONTEM

aAdd( aSXB, { ;
	'AXEESP'																, ; //XB_ALIAS
	'5'																		, ; //XB_TIPO
	'01'																	, ; //XB_SEQ
	''																		, ; //XB_COLUNA
	''																		, ; //XB_DESCRI
	''																		, ; //XB_DESCSPA
	''																		, ; //XB_DESCENG
	''																		, ; //XB_WCONTEM
	'AY1->AY1_SUBCAT'														} ) //XB_CONTEM

aAdd( aSXB, { ;
	'AXEESP'																, ; //XB_ALIAS
	'6'																		, ; //XB_TIPO
	'01'																	, ; //XB_SEQ
	''																		, ; //XB_COLUNA
	''																		, ; //XB_DESCRI
	''																		, ; //XB_DESCSPA
	''																		, ; //XB_DESCENG
	''																		, ; //XB_WCONTEM
	'T_SyFilCateg(4)'														} ) //XB_CONTEM

//
// Consulta AXELIN
//
aAdd( aSXB, { ;
	'AXELIN'																, ; //XB_ALIAS
	'1'																		, ; //XB_TIPO
	'01'																	, ; //XB_SEQ
	'DB'																	, ; //XB_COLUNA
	'Consulta Categorias'													, ; //XB_DESCRI
	'Consulta Categorias'													, ; //XB_DESCSPA
	'Consulta Categorias'													, ; //XB_DESCENG
	''																		, ; //XB_WCONTEM
	'AY1'																	} ) //XB_CONTEM

aAdd( aSXB, { ;
	'AXELIN'																, ; //XB_ALIAS
	'2'																		, ; //XB_TIPO
	'01'																	, ; //XB_SEQ
	'02'																	, ; //XB_COLUNA
	'Sub.categor.+codigo'													, ; //XB_DESCRI
	'Sub.categor.+codigo'													, ; //XB_DESCSPA
	'Sub.categor.+codigo'													, ; //XB_DESCENG
	''																		, ; //XB_WCONTEM
	'AY1_002'																} ) //XB_CONTEM

aAdd( aSXB, { ;
	'AXELIN'																, ; //XB_ALIAS
	'4'																		, ; //XB_TIPO
	'01'																	, ; //XB_SEQ
	'01'																	, ; //XB_COLUNA
	'Codigo'																, ; //XB_DESCRI
	'Codigo'																, ; //XB_DESCSPA
	'Codigo'																, ; //XB_DESCENG
	''																		, ; //XB_WCONTEM
	'AY1_SUBCAT'															} ) //XB_CONTEM

aAdd( aSXB, { ;
	'AXELIN'																, ; //XB_ALIAS
	'4'																		, ; //XB_TIPO
	'01'																	, ; //XB_SEQ
	'02'																	, ; //XB_COLUNA
	'Descrição'																, ; //XB_DESCRI
	'Descrição'																, ; //XB_DESCSPA
	'Descrição'																, ; //XB_DESCENG
	''																		, ; //XB_WCONTEM
	'AY1_DESCSU'															} ) //XB_CONTEM

aAdd( aSXB, { ;
	'AXELIN'																, ; //XB_ALIAS
	'5'																		, ; //XB_TIPO
	'01'																	, ; //XB_SEQ
	''																		, ; //XB_COLUNA
	''																		, ; //XB_DESCRI
	''																		, ; //XB_DESCSPA
	''																		, ; //XB_DESCENG
	''																		, ; //XB_WCONTEM
	'AY1->AY1_SUBCAT'														} ) //XB_CONTEM

aAdd( aSXB, { ;
	'AXELIN'																, ; //XB_ALIAS
	'6'																		, ; //XB_TIPO
	'01'																	, ; //XB_SEQ
	''																		, ; //XB_COLUNA
	''																		, ; //XB_DESCRI
	''																		, ; //XB_DESCSPA
	''																		, ; //XB_DESCENG
	''																		, ; //XB_WCONTEM
	'T_SyFilCateg(2)'														} ) //XB_CONTEM

//
// Consulta AXESEC
//
aAdd( aSXB, { ;
	'AXESEC'																, ; //XB_ALIAS
	'1'																		, ; //XB_TIPO
	'01'																	, ; //XB_SEQ
	'DB'																	, ; //XB_COLUNA
	'Consulta Categorias'													, ; //XB_DESCRI
	'Consulta Categorias'													, ; //XB_DESCSPA
	'Consulta Categorias'													, ; //XB_DESCENG
	''																		, ; //XB_WCONTEM
	'AY1'																	} ) //XB_CONTEM

aAdd( aSXB, { ;
	'AXESEC'																, ; //XB_ALIAS
	'2'																		, ; //XB_TIPO
	'01'																	, ; //XB_SEQ
	'02'																	, ; //XB_COLUNA
	'Sub.categor.+codigo'													, ; //XB_DESCRI
	'Sub.categor.+codigo'													, ; //XB_DESCSPA
	'Sub.categor.+codigo'													, ; //XB_DESCENG
	''																		, ; //XB_WCONTEM
	'AY1_002'																} ) //XB_CONTEM

aAdd( aSXB, { ;
	'AXESEC'																, ; //XB_ALIAS
	'4'																		, ; //XB_TIPO
	'01'																	, ; //XB_SEQ
	'01'																	, ; //XB_COLUNA
	'Código'																, ; //XB_DESCRI
	'Código'																, ; //XB_DESCSPA
	'Código'																, ; //XB_DESCENG
	''																		, ; //XB_WCONTEM
	'AY1_SUBCAT'															} ) //XB_CONTEM

aAdd( aSXB, { ;
	'AXESEC'																, ; //XB_ALIAS
	'4'																		, ; //XB_TIPO
	'01'																	, ; //XB_SEQ
	'02'																	, ; //XB_COLUNA
	'Descrição'																, ; //XB_DESCRI
	'Descrição'																, ; //XB_DESCSPA
	'Descrição'																, ; //XB_DESCENG
	''																		, ; //XB_WCONTEM
	'AY1_DESCSU'															} ) //XB_CONTEM

aAdd( aSXB, { ;
	'AXESEC'																, ; //XB_ALIAS
	'5'																		, ; //XB_TIPO
	'01'																	, ; //XB_SEQ
	''																		, ; //XB_COLUNA
	''																		, ; //XB_DESCRI
	''																		, ; //XB_DESCSPA
	''																		, ; //XB_DESCENG
	''																		, ; //XB_WCONTEM
	'AY1->AY1_SUBCAT'														} ) //XB_CONTEM

aAdd( aSXB, { ;
	'AXESEC'																, ; //XB_ALIAS
	'6'																		, ; //XB_TIPO
	'01'																	, ; //XB_SEQ
	''																		, ; //XB_COLUNA
	''																		, ; //XB_DESCRI
	''																		, ; //XB_DESCSPA
	''																		, ; //XB_DESCENG
	''																		, ; //XB_WCONTEM
	'T_SyFilCateg(3)'														} ) //XB_CONTEM

//
// Consulta AXESUB
//
aAdd( aSXB, { ;
	'AXESUB'																, ; //XB_ALIAS
	'1'																		, ; //XB_TIPO
	'01'																	, ; //XB_SEQ
	'DB'																	, ; //XB_COLUNA
	'Consulta Categorias'													, ; //XB_DESCRI
	'Consulta Categorias'													, ; //XB_DESCSPA
	'Consulta Categorias'													, ; //XB_DESCENG
	''																		, ; //XB_WCONTEM
	'AY1'																	} ) //XB_CONTEM

aAdd( aSXB, { ;
	'AXESUB'																, ; //XB_ALIAS
	'2'																		, ; //XB_TIPO
	'01'																	, ; //XB_SEQ
	'02'																	, ; //XB_COLUNA
	'Sub.categor.+codigo'													, ; //XB_DESCRI
	'Sub.categor.+codigo'													, ; //XB_DESCSPA
	'Sub.categor.+codigo'													, ; //XB_DESCENG
	''																		, ; //XB_WCONTEM
	'AY1_002'																} ) //XB_CONTEM

aAdd( aSXB, { ;
	'AXESUB'																, ; //XB_ALIAS
	'4'																		, ; //XB_TIPO
	'01'																	, ; //XB_SEQ
	'01'																	, ; //XB_COLUNA
	'Código'																, ; //XB_DESCRI
	'Código'																, ; //XB_DESCSPA
	'Código'																, ; //XB_DESCENG
	''																		, ; //XB_WCONTEM
	'AY1_SUBCAT'															} ) //XB_CONTEM

aAdd( aSXB, { ;
	'AXESUB'																, ; //XB_ALIAS
	'4'																		, ; //XB_TIPO
	'01'																	, ; //XB_SEQ
	'02'																	, ; //XB_COLUNA
	'Descrição'																, ; //XB_DESCRI
	'Descrição'																, ; //XB_DESCSPA
	'Descrição'																, ; //XB_DESCENG
	''																		, ; //XB_WCONTEM
	'AY1_DESCSU'															} ) //XB_CONTEM

aAdd( aSXB, { ;
	'AXESUB'																, ; //XB_ALIAS
	'5'																		, ; //XB_TIPO
	'01'																	, ; //XB_SEQ
	''																		, ; //XB_COLUNA
	''																		, ; //XB_DESCRI
	''																		, ; //XB_DESCSPA
	''																		, ; //XB_DESCENG
	''																		, ; //XB_WCONTEM
	'AY1->AY1_SUBCAT'														} ) //XB_CONTEM

aAdd( aSXB, { ;
	'AXESUB'																, ; //XB_ALIAS
	'6'																		, ; //XB_TIPO
	'01'																	, ; //XB_SEQ
	''																		, ; //XB_COLUNA
	''																		, ; //XB_DESCRI
	''																		, ; //XB_DESCSPA
	''																		, ; //XB_DESCENG
	''																		, ; //XB_WCONTEM
	'T_SyFilCateg(5)'														} ) //XB_CONTEM

//
// Consulta BVCOR4
//
aAdd( aSXB, { ;
	'BVCOR4'																, ; //XB_ALIAS
	'1'																		, ; //XB_TIPO
	'01'																	, ; //XB_SEQ
	'RE'																	, ; //XB_COLUNA
	'Grade de Cores'														, ; //XB_DESCRI
	'Grade de Cores'														, ; //XB_DESCSPA
	'Grade de Cores'														, ; //XB_DESCENG
	''																		, ; //XB_WCONTEM
	''																		} ) //XB_CONTEM
	
aAdd( aSXB, { ;
	'BVCOR4'																, ; //XB_ALIAS
	'2'																		, ; //XB_TIPO
	'01'																	, ; //XB_SEQ
	'01'																	, ; //XB_COLUNA
	''																		, ; //XB_DESCRI
	''																		, ; //XB_DESCSPA
	''																		, ; //XB_DESCENG
	''																		, ; //XB_WCONTEM
	'T_A102SXBCOR()'														} ) //XB_CONTEM
	
aAdd( aSXB, { ;
	'BVCOR4'																, ; //XB_ALIAS
	'5'																		, ; //XB_TIPO
	'01'																	, ; //XB_SEQ
	''																		, ; //XB_COLUNA
	''																		, ; //XB_DESCRI
	''																		, ; //XB_DESCSPA
	''																		, ; //XB_DESCENG
	''																		, ; //XB_WCONTEM
	'T_A102RCOR()'															} ) //XB_CONTEM
	
aAdd( aSXB, { ;
	'BVCOR4'																, ; //XB_ALIAS
	'5'																		, ; //XB_TIPO
	'02'																	, ; //XB_SEQ
	''																		, ; //XB_COLUNA
	''																		, ; //XB_DESCRI
	''																		, ; //XB_DESCSPA
	''																		, ; //XB_DESCENG
	''																		, ; //XB_WCONTEM
	'T_A102RDES()'															} ) //XB_CONTEM

//
// Consulta AY701
//
aAdd( aSXB, { ;	
	'AY701'																	, ; //XB_ALIAS
	'1'																		, ; //XB_TIPO
	'01'																	, ; //XB_SEQ
	'RE'																	, ; //XB_COLUNA
	'Consulta de Packs'														, ; //XB_DESCRI
	'Consulta de Packs'														, ; //XB_DESCSPA
	'Consulta de Packs'														, ; //XB_DESCENG
	''																		, ; //XB_WCONTEM
	''																		} ) //XB_CONTEM
	
aAdd( aSXB, { ;
	'AY701'																	, ; //XB_ALIAS
	'2'																		, ; //XB_TIPO
	'01'																	, ; //XB_SEQ
	'01'																	, ; //XB_COLUNA
	''																		, ; //XB_DESCRI
	''																		, ; //XB_DESCSPA
	''																		, ; //XB_DESCENG
	''																		, ; //XB_WCONTEM
	'T_A102SXBPACK()'														} ) //XB_CONTEM
	
aAdd( aSXB, { ;
	'AY701'																	, ; //XB_ALIAS
	'5'																		, ; //XB_TIPO
	'01'																	, ; //XB_SEQ
	''																		, ; //XB_COLUNA
	''																		, ; //XB_DESCRI
	''																		, ; //XB_DESCSPA
	''																		, ; //XB_DESCENG
	''																		, ; //XB_WCONTEM
	'T_A102RETPACK()'														} ) //XB_CONTEM

//
// Consulta AY701
//
aAdd( aSXB, { ;	
	'AY701'																	, ; //XB_ALIAS
	'1'																		, ; //XB_TIPO
	'01'																	, ; //XB_SEQ
	'RE'																	, ; //XB_COLUNA
	'Consulta de Packs'														, ; //XB_DESCRI
	'Consulta de Packs'														, ; //XB_DESCSPA
	'Consulta de Packs'														, ; //XB_DESCENG
	''																		, ; //XB_WCONTEM
	''																		} ) //XB_CONTEM
	
aAdd( aSXB, { ;
	'AY701'																	, ; //XB_ALIAS
	'2'																		, ; //XB_TIPO
	'01'																	, ; //XB_SEQ
	'01'																	, ; //XB_COLUNA
	''																		, ; //XB_DESCRI
	''																		, ; //XB_DESCSPA
	''																		, ; //XB_DESCENG
	''																		, ; //XB_WCONTEM
	'T_A102SXBPACK()'														} ) //XB_CONTEM
	
aAdd( aSXB, { ;
	'AY701'																	, ; //XB_ALIAS
	'5'																		, ; //XB_TIPO
	'01'																	, ; //XB_SEQ
	''																		, ; //XB_COLUNA
	''																		, ; //XB_DESCRI
	''																		, ; //XB_DESCSPA
	''																		, ; //XB_DESCENG
	''																		, ; //XB_WCONTEM
	'T_A102RETPACK()'														} ) //XB_CONTEM
	
//
// Consulta CATEG1
//
aAdd( aSXB, { ;	
	'CATEG1'																, ; //XB_ALIAS
	'1'																		, ; //XB_TIPO
	'01'																	, ; //XB_SEQ
	'RE'																	, ; //XB_COLUNA
	'Consulta Categorias'													, ; //XB_DESCRI
	'Consulta Categorias'													, ; //XB_DESCSPA
	'Consulta Categorias'													, ; //XB_DESCENG
	''																		, ; //XB_WCONTEM
	'AY1'																	} ) //XB_CONTEM
	
aAdd( aSXB, { ;
	'CATEG1'																, ; //XB_ALIAS
	'2'																		, ; //XB_TIPO
	'01'																	, ; //XB_SEQ
	'01'																	, ; //XB_COLUNA
	''																		, ; //XB_DESCRI
	''																		, ; //XB_DESCSPA
	''																		, ; //XB_DESCENG
	''																		, ; //XB_WCONTEM
	'T_SYVC009C()'															} ) //XB_CONTEM
	
aAdd( aSXB, { ;
	'CATEG1'																, ; //XB_ALIAS
	'5'																		, ; //XB_TIPO
	'01'																	, ; //XB_SEQ
	''																		, ; //XB_COLUNA
	''																		, ; //XB_DESCRI
	''																		, ; //XB_DESCSPA
	''																		, ; //XB_DESCENG
	''																		, ; //XB_WCONTEM
	'T_VA009CCOD()'															} ) //XB_CONTEM
	
//
// Consulta CATEG2
//
aAdd( aSXB, { ;	
	'CATEG2'																, ; //XB_ALIAS
	'1'																		, ; //XB_TIPO
	'01'																	, ; //XB_SEQ
	'RE'																	, ; //XB_COLUNA
	'Consulta Categorias'													, ; //XB_DESCRI
	'Consulta Categorias'													, ; //XB_DESCSPA
	'Consulta Categorias'													, ; //XB_DESCENG
	''																		, ; //XB_WCONTEM
	'AY1'																	} ) //XB_CONTEM
	
aAdd( aSXB, { ;
	'CATEG2'																, ; //XB_ALIAS
	'2'																		, ; //XB_TIPO
	'01'																	, ; //XB_SEQ
	'01'																	, ; //XB_COLUNA
	''																		, ; //XB_DESCRI
	''																		, ; //XB_DESCSPA
	''																		, ; //XB_DESCENG
	''																		, ; //XB_WCONTEM
	'T_SYVC009C(M->B4_01CAT1)'												} ) //XB_CONTEM
	
aAdd( aSXB, { ;
	'CATEG2'																, ; //XB_ALIAS
	'5'																		, ; //XB_TIPO
	'01'																	, ; //XB_SEQ
	''																		, ; //XB_COLUNA
	''																		, ; //XB_DESCRI
	''																		, ; //XB_DESCSPA
	''																		, ; //XB_DESCENG
	''																		, ; //XB_WCONTEM
	'T_VA009CCOD()'															} ) //XB_CONTEM
	
//
// Consulta CATEG3
//
aAdd( aSXB, { ;	
	'CATEG3'																, ; //XB_ALIAS
	'1'																		, ; //XB_TIPO
	'01'																	, ; //XB_SEQ
	'RE'																	, ; //XB_COLUNA
	'Consulta Categorias'													, ; //XB_DESCRI
	'Consulta Categorias'													, ; //XB_DESCSPA
	'Consulta Categorias'													, ; //XB_DESCENG
	''																		, ; //XB_WCONTEM
	'AY1'																	} ) //XB_CONTEM
	
aAdd( aSXB, { ;
	'CATEG3'																, ; //XB_ALIAS
	'2'																		, ; //XB_TIPO
	'01'																	, ; //XB_SEQ
	'01'																	, ; //XB_COLUNA
	''																		, ; //XB_DESCRI
	''																		, ; //XB_DESCSPA
	''																		, ; //XB_DESCENG
	''																		, ; //XB_WCONTEM
	'T_SYVC009C(M->B4_01CAT2)'												} ) //XB_CONTEM
	
aAdd( aSXB, { ;
	'CATEG3'																, ; //XB_ALIAS
	'5'																		, ; //XB_TIPO
	'01'																	, ; //XB_SEQ
	''																		, ; //XB_COLUNA
	''																		, ; //XB_DESCRI
	''																		, ; //XB_DESCSPA
	''																		, ; //XB_DESCENG
	''																		, ; //XB_WCONTEM
	'T_VA009CCOD()'															} ) //XB_CONTEM
	
//
// Consulta CATEG4
//
aAdd( aSXB, { ;	
	'CATEG4'																, ; //XB_ALIAS
	'1'																		, ; //XB_TIPO
	'01'																	, ; //XB_SEQ
	'RE'																	, ; //XB_COLUNA
	'Consulta Categorias'													, ; //XB_DESCRI
	'Consulta Categorias'													, ; //XB_DESCSPA
	'Consulta Categorias'													, ; //XB_DESCENG
	''																		, ; //XB_WCONTEM
	'AY1'																	} ) //XB_CONTEM
	
aAdd( aSXB, { ;
	'CATEG4'																, ; //XB_ALIAS
	'2'																		, ; //XB_TIPO
	'01'																	, ; //XB_SEQ
	'01'																	, ; //XB_COLUNA
	''																		, ; //XB_DESCRI
	''																		, ; //XB_DESCSPA
	''																		, ; //XB_DESCENG
	''																		, ; //XB_WCONTEM
	'T_SYVC009C(M->B4_01CAT3)'												} ) //XB_CONTEM
	
aAdd( aSXB, { ;
	'CATEG4'																, ; //XB_ALIAS
	'5'																		, ; //XB_TIPO
	'01'																	, ; //XB_SEQ
	''																		, ; //XB_COLUNA
	''																		, ; //XB_DESCRI
	''																		, ; //XB_DESCSPA
	''																		, ; //XB_DESCENG
	''																		, ; //XB_WCONTEM
	'T_VA009CCOD()'															} ) //XB_CONTEM
	
//
// Consulta CATEG5
//
aAdd( aSXB, { ;	
	'CATEG5'																, ; //XB_ALIAS
	'1'																		, ; //XB_TIPO
	'01'																	, ; //XB_SEQ
	'RE'																	, ; //XB_COLUNA
	'Consulta Categorias'													, ; //XB_DESCRI
	'Consulta Categorias'													, ; //XB_DESCSPA
	'Consulta Categorias'													, ; //XB_DESCENG
	''																		, ; //XB_WCONTEM
	'AY1'																	} ) //XB_CONTEM
	
aAdd( aSXB, { ;
	'CATEG5'																, ; //XB_ALIAS
	'2'																		, ; //XB_TIPO
	'01'																	, ; //XB_SEQ
	'01'																	, ; //XB_COLUNA
	''																		, ; //XB_DESCRI
	''																		, ; //XB_DESCSPA
	''																		, ; //XB_DESCENG
	''																		, ; //XB_WCONTEM
	'T_SYVC009C(M->B4_01CAT4)'												} ) //XB_CONTEM
	
aAdd( aSXB, { ;
	'CATEG5'																, ; //XB_ALIAS
	'5'																		, ; //XB_TIPO
	'01'																	, ; //XB_SEQ
	''																		, ; //XB_COLUNA
	''																		, ; //XB_DESCRI
	''																		, ; //XB_DESCSPA
	''																		, ; //XB_DESCENG
	''																		, ; //XB_WCONTEM
	'T_VA009CCOD()'															} ) //XB_CONTEM

//
// Consulta AXECA1
//
aAdd( aSXB, { ;	
	'AXECA1'																, ; //XB_ALIAS
	'1'																		, ; //XB_TIPO
	'01'																	, ; //XB_SEQ
	'RE'																	, ; //XB_COLUNA
	'Consulta Categorias'													, ; //XB_DESCRI
	'Consulta Categorias'													, ; //XB_DESCSPA
	'Consulta Categorias'													, ; //XB_DESCENG
	''																		, ; //XB_WCONTEM
	'AY1'																	} ) //XB_CONTEM
	
aAdd( aSXB, { ;
	'AXECA1'																, ; //XB_ALIAS
	'2'																		, ; //XB_TIPO
	'01'																	, ; //XB_SEQ
	'01'																	, ; //XB_COLUNA
	''																		, ; //XB_DESCRI
	''																		, ; //XB_DESCSPA
	''																		, ; //XB_DESCENG
	''																		, ; //XB_WCONTEM
	'T_SYVC009C()'															} ) //XB_CONTEM
	
aAdd( aSXB, { ;
	'AXECA1'																, ; //XB_ALIAS
	'5'																		, ; //XB_TIPO
	'01'																	, ; //XB_SEQ
	''																		, ; //XB_COLUNA
	''																		, ; //XB_DESCRI
	''																		, ; //XB_DESCSPA
	''																		, ; //XB_DESCENG
	''																		, ; //XB_WCONTEM
	'T_VA009CCOD()'															} ) //XB_CONTEM
	
//
// Consulta AXECA2
//
aAdd( aSXB, { ;	
	'AXECA2'																, ; //XB_ALIAS
	'1'																		, ; //XB_TIPO
	'01'																	, ; //XB_SEQ
	'RE'																	, ; //XB_COLUNA
	'Consulta Categorias'													, ; //XB_DESCRI
	'Consulta Categorias'													, ; //XB_DESCSPA
	'Consulta Categorias'													, ; //XB_DESCENG
	''																		, ; //XB_WCONTEM
	'AY1'																	} ) //XB_CONTEM
	
aAdd( aSXB, { ;
	'AXECA2'																, ; //XB_ALIAS
	'2'																		, ; //XB_TIPO
	'01'																	, ; //XB_SEQ
	'01'																	, ; //XB_COLUNA
	''																		, ; //XB_DESCRI
	''																		, ; //XB_DESCSPA
	''																		, ; //XB_DESCENG
	''																		, ; //XB_WCONTEM
	'T_SYVC009C(oCadProd:aCols[oCadProd:nAt][AScan(oCadProd:aHeader,{|x|AllTrim(x[2])=="AXE_01CAT1"})])'	} ) //XB_CONTEM
	
aAdd( aSXB, { ;
	'AXECA2'																, ; //XB_ALIAS
	'5'																		, ; //XB_TIPO
	'01'																	, ; //XB_SEQ
	''																		, ; //XB_COLUNA
	''																		, ; //XB_DESCRI
	''																		, ; //XB_DESCSPA
	''																		, ; //XB_DESCENG
	''																		, ; //XB_WCONTEM
	'T_VA009CCOD()'															} ) //XB_CONTEM
	
//
// Consulta AXECA3
//
aAdd( aSXB, { ;	
	'AXECA3'																, ; //XB_ALIAS
	'1'																		, ; //XB_TIPO
	'01'																	, ; //XB_SEQ
	'RE'																	, ; //XB_COLUNA
	'Consulta Categorias'													, ; //XB_DESCRI
	'Consulta Categorias'													, ; //XB_DESCSPA
	'Consulta Categorias'													, ; //XB_DESCENG
	''																		, ; //XB_WCONTEM
	'AY1'																	} ) //XB_CONTEM
	
aAdd( aSXB, { ;
	'AXECA3'																, ; //XB_ALIAS
	'2'																		, ; //XB_TIPO
	'01'																	, ; //XB_SEQ
	'01'																	, ; //XB_COLUNA
	''																		, ; //XB_DESCRI
	''																		, ; //XB_DESCSPA
	''																		, ; //XB_DESCENG
	''																		, ; //XB_WCONTEM
	'T_SYVC009C(oCadProd:aCols[oCadProd:nAt][AScan(oCadProd:aHeader,{|x|AllTrim(x[2])=="AXE_01CAT2"})])'	} ) //XB_CONTEM
	
aAdd( aSXB, { ;
	'AXECA3'																, ; //XB_ALIAS
	'5'																		, ; //XB_TIPO
	'01'																	, ; //XB_SEQ
	''																		, ; //XB_COLUNA
	''																		, ; //XB_DESCRI
	''																		, ; //XB_DESCSPA
	''																		, ; //XB_DESCENG
	''																		, ; //XB_WCONTEM
	'T_VA009CCOD()'															} ) //XB_CONTEM
	
//
// Consulta AXECA4
//
aAdd( aSXB, { ;	
	'AXECA4'																, ; //XB_ALIAS
	'1'																		, ; //XB_TIPO
	'01'																	, ; //XB_SEQ
	'RE'																	, ; //XB_COLUNA
	'Consulta Categorias'													, ; //XB_DESCRI
	'Consulta Categorias'													, ; //XB_DESCSPA
	'Consulta Categorias'													, ; //XB_DESCENG
	''																		, ; //XB_WCONTEM
	'AY1'																	} ) //XB_CONTEM
	
aAdd( aSXB, { ;
	'AXECA4'																, ; //XB_ALIAS
	'2'																		, ; //XB_TIPO
	'01'																	, ; //XB_SEQ
	'01'																	, ; //XB_COLUNA
	''																		, ; //XB_DESCRI
	''																		, ; //XB_DESCSPA
	''																		, ; //XB_DESCENG
	''																		, ; //XB_WCONTEM
	'T_SYVC009C(oCadProd:aCols[oCadProd:nAt][AScan(oCadProd:aHeader,{|x|AllTrim(x[2])=="AXE_01CAT3"})])'	} ) //XB_CONTEM
	
aAdd( aSXB, { ;
	'AXECA4'																, ; //XB_ALIAS
	'5'																		, ; //XB_TIPO
	'01'																	, ; //XB_SEQ
	''																		, ; //XB_COLUNA
	''																		, ; //XB_DESCRI
	''																		, ; //XB_DESCSPA
	''																		, ; //XB_DESCENG
	''																		, ; //XB_WCONTEM
	'T_VA009CCOD()'															} ) //XB_CONTEM
	
//
// Consulta AXECA5
//
aAdd( aSXB, { ;	
	'AXECA5'																, ; //XB_ALIAS
	'1'																		, ; //XB_TIPO
	'01'																	, ; //XB_SEQ
	'RE'																	, ; //XB_COLUNA
	'Consulta Categorias'													, ; //XB_DESCRI
	'Consulta Categorias'													, ; //XB_DESCSPA
	'Consulta Categorias'													, ; //XB_DESCENG
	''																		, ; //XB_WCONTEM
	'AY1'																	} ) //XB_CONTEM
	
aAdd( aSXB, { ;
	'AXECA5'																, ; //XB_ALIAS
	'2'																		, ; //XB_TIPO
	'01'																	, ; //XB_SEQ
	'01'																	, ; //XB_COLUNA
	''																		, ; //XB_DESCRI
	''																		, ; //XB_DESCSPA
	''																		, ; //XB_DESCENG
	''																		, ; //XB_WCONTEM
	'T_SYVC009C(oCadProd:aCols[oCadProd:nAt][AScan(oCadProd:aHeader,{|x|AllTrim(x[2])=="AXE_01CAT4"})])'	} ) //XB_CONTEM
	
aAdd( aSXB, { ;
	'AXECA5'																, ; //XB_ALIAS
	'5'																		, ; //XB_TIPO
	'01'																	, ; //XB_SEQ
	''																		, ; //XB_COLUNA
	''																		, ; //XB_DESCRI
	''																		, ; //XB_DESCSPA
	''																		, ; //XB_DESCENG
	''																		, ; //XB_WCONTEM
	'T_VA009CCOD()'															} ) //XB_CONTEM
	
//
// Consulta AXM
//
aAdd( aSXB, { ;	
	'AXM'																	, ; //XB_ALIAS
	'1'																		, ; //XB_TIPO
	'01'																	, ; //XB_SEQ
	'DB'																	, ; //XB_COLUNA
	'Tipo de Divergencia'													, ; //XB_DESCRI
	'Tipo de Divergencia'													, ; //XB_DESCSPA
	'Tipo de Divergencia'													, ; //XB_DESCENG
	''																		, ; //XB_WCONTEM
	'AXM'																	} ) //XB_CONTEM
	
aAdd( aSXB, { ;	
	'AXM'																	, ; //XB_ALIAS
	'2'																		, ; //XB_TIPO
	'01'																	, ; //XB_SEQ
	'01'																	, ; //XB_COLUNA
	'Codigo+descricao'														, ; //XB_DESCRI
	'Codigo+descricao'														, ; //XB_DESCSPA
	'Codigo+descricao'														, ; //XB_DESCENG
	''																		, ; //XB_WCONTEM
	''																		} ) //XB_CONTEM
	
aAdd( aSXB, { ;	
	'AXM'																	, ; //XB_ALIAS
	'3'																		, ; //XB_TIPO
	'01'																	, ; //XB_SEQ
	'01'																	, ; //XB_COLUNA
	'Cadastra Novo'															, ; //XB_DESCRI
	'Cadastra Novo'															, ; //XB_DESCSPA
	'Cadastra Novo'															, ; //XB_DESCENG
	''																		, ; //XB_WCONTEM
	'01'																	} ) //XB_CONTEM
	
aAdd( aSXB, { ;	
	'AXM'																	, ; //XB_ALIAS
	'4'																		, ; //XB_TIPO
	'01'																	, ; //XB_SEQ
	'01'																	, ; //XB_COLUNA
	'Codigo'																, ; //XB_DESCRI
	'Codigo'																, ; //XB_DESCSPA
	'Codigo'																, ; //XB_DESCENG
	''																		, ; //XB_WCONTEM
	'AXM_CODIGO'															} ) //XB_CONTEM
	
aAdd( aSXB, { ;	
	'AXM'																	, ; //XB_ALIAS
	'4'																		, ; //XB_TIPO
	'01'																	, ; //XB_SEQ
	'02'																	, ; //XB_COLUNA
	'Descrição'																, ; //XB_DESCRI
	'Descrição'																, ; //XB_DESCSPA
	'Descrição'																, ; //XB_DESCENG
	''																		, ; //XB_WCONTEM
	'AXM_DESCRI'															} ) //XB_CONTEM
	
aAdd( aSXB, { ;	
	'AXM'																	, ; //XB_ALIAS
	'5'																		, ; //XB_TIPO
	'01'																	, ; //XB_SEQ
	''																		, ; //XB_COLUNA
	''																		, ; //XB_DESCRI
	''																		, ; //XB_DESCSPA
	''																		, ; //XB_DESCENG
	''																		, ; //XB_WCONTEM
	'AXM->AXM_CODIGO'														} ) //XB_CONTEM

//
// Atualizando dicionário
//
oProcess:SetRegua2( Len( aSXB ) )

dbSelectArea( "SXB" )
dbSetOrder( 1 )

For nI := 1 To Len( aSXB )

	If !Empty( aSXB[nI][1] )

		If !SXB->( dbSeek( PadR( aSXB[nI][1], Len( SXB->XB_ALIAS ) ) + aSXB[nI][2] + aSXB[nI][3] + aSXB[nI][4] ) )

			If !( aSXB[nI][1] $ cAlias )
				cAlias += aSXB[nI][1] + "/"
				AutoGrLog( "Foi incluída a consulta padrão " + aSXB[nI][1] )
			EndIf

			RecLock( "SXB", .T. )

			For nJ := 1 To Len( aSXB[nI] )
				If FieldPos( aEstrut[nJ] ) > 0
					FieldPut( FieldPos( aEstrut[nJ] ), aSXB[nI][nJ] )
				EndIf
			Next nJ

			dbCommit()
			MsUnLock()

		Else

			//
			// Verifica todos os campos
			//
			For nJ := 1 To Len( aSXB[nI] )

				//
				// Se o campo estiver diferente da estrutura
				//
				If aEstrut[nJ] == SXB->( FieldName( nJ ) ) .AND. ;
					!StrTran( AllToChar( SXB->( FieldGet( nJ ) ) ), " ", "" ) == ;
					 StrTran( AllToChar( aSXB[nI][nJ]            ), " ", "" )

					cMsg := "A consulta padrão " + aSXB[nI][1] + " está com o " + SXB->( FieldName( nJ ) ) + ;
					" com o conteúdo" + CRLF + ;
					"[" + RTrim( AllToChar( SXB->( FieldGet( nJ ) ) ) ) + "]" + CRLF + ;
					", e este é diferente do conteúdo" + CRLF + ;
					"[" + RTrim( AllToChar( aSXB[nI][nJ] ) ) + "]" + CRLF +;
					"Deseja substituir ? "

					If      lTodosSim
						nOpcA := 1
					ElseIf  lTodosNao
						nOpcA := 2
					Else
						nOpcA := Aviso( "ATUALIZAÇÃO DE DICIONÁRIOS E TABELAS", cMsg, { "Sim", "Não", "Sim p/Todos", "Não p/Todos" }, 3, "Diferença de conteúdo - SXB" )
						lTodosSim := ( nOpcA == 3 )
						lTodosNao := ( nOpcA == 4 )

						If lTodosSim
							nOpcA := 1
							lTodosSim := MsgNoYes( "Foi selecionada a opção de REALIZAR TODAS alterações no SXB e NÃO MOSTRAR mais a tela de aviso." + CRLF + "Confirma a ação [Sim p/Todos] ?" )
						EndIf

						If lTodosNao
							nOpcA := 2
							lTodosNao := MsgNoYes( "Foi selecionada a opção de NÃO REALIZAR nenhuma alteração no SXB que esteja diferente da base e NÃO MOSTRAR mais a tela de aviso." + CRLF + "Confirma esta ação [Não p/Todos]?" )
						EndIf

					EndIf

					If nOpcA == 1
						RecLock( "SXB", .F. )
						FieldPut( FieldPos( aEstrut[nJ] ), aSXB[nI][nJ] )
						dbCommit()
						MsUnLock()

							If !( aSXB[nI][1] $ cAlias )
								cAlias += aSXB[nI][1] + "/"
								AutoGrLog( "Foi alterada a consulta padrão " + aSXB[nI][1] )
							EndIf

					EndIf

				EndIf

			Next

		EndIf

	EndIf

	oProcess:IncRegua2( "Atualizando Consultas Padrões (SXB)..." )

Next nI

AutoGrLog( CRLF + "Final da Atualização" + " SXB" + CRLF + Replicate( "-", 128 ) + CRLF )

Return NIL


//--------------------------------------------------------------------
/*/{Protheus.doc} FSAtuHlp
Função de processamento da gravação dos Helps de Campos

@author TOTVS Protheus
@since  16/12/2016
@obs    Gerado por EXPORDIC - V.5.2.1.0 EFS / Upd. V.4.20.15 EFS
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function FSAtuHlp()
Local aHlpPor   := {}
Local aHlpEng   := {}
Local aHlpSpa   := {}

AutoGrLog( "Ínicio da Atualização" + " " + "Helps de Campos" + CRLF )


oProcess:IncRegua2( "Atualizando Helps de Campos ..." )

//
// Helps Tabela AXC
//
aHlpPor := {}
aAdd( aHlpPor, 'Data da verba de compra que será' )
aAdd( aHlpPor, 'utilizada.' )
aHlpEng := {}
aHlpSpa := {}

PutHelp( "PAXC_DTVERB", aHlpPor, aHlpEng, aHlpSpa, .T. )
AutoGrLog( "Atualizado o Help do campo " + "AXC_DTVERB" )

aHlpPor := {}
aAdd( aHlpPor, 'Nome do Fornecedor' )
aHlpEng := {}
aHlpSpa := {}

PutHelp( "PAXC_NOMFOR", aHlpPor, aHlpEng, aHlpSpa, .T. )
AutoGrLog( "Atualizado o Help do campo " + "AXC_NOMFOR" )

aHlpPor := {}
aAdd( aHlpPor, 'Descrição da Condição de Pagamento.' )
aHlpEng := {}
aHlpSpa := {}

PutHelp( "PAXC_DESCPG", aHlpPor, aHlpEng, aHlpSpa, .T. )
AutoGrLog( "Atualizado o Help do campo " + "AXC_DESCPG" )

aHlpPor := {}
aAdd( aHlpPor, 'E-mail do Fornecedor' )
aHlpEng := {}
aHlpSpa := {}

PutHelp( "PAXC_EMAIL ", aHlpPor, aHlpEng, aHlpSpa, .T. )
AutoGrLog( "Atualizado o Help do campo " + "AXC_EMAIL" )

aHlpPor := {}
aAdd( aHlpPor, 'Nome do Comprador' )
aHlpEng := {}
aHlpSpa := {}

PutHelp( "PAXC_NOMCOM", aHlpPor, aHlpEng, aHlpSpa, .T. )
AutoGrLog( "Atualizado o Help do campo " + "AXC_NOMCOM" )

aHlpPor := {}
aAdd( aHlpPor, 'Nome do Aprovador' )
aHlpEng := {}
aHlpSpa := {}

PutHelp( "PAXC_NOMAPR", aHlpPor, aHlpEng, aHlpSpa, .T. )
AutoGrLog( "Atualizado o Help do campo " + "AXC_NOMAPR" )

aHlpPor := {}
aAdd( aHlpPor, 'Descrição da Moeda' )
aHlpEng := {}
aHlpSpa := {}

PutHelp( "PAXC_DMOEDA", aHlpPor, aHlpEng, aHlpSpa, .T. )
AutoGrLog( "Atualizado o Help do campo " + "AXC_DMOEDA" )

aHlpPor := {}
aAdd( aHlpPor, 'Codigo da Coleção.' )
aHlpEng := {}
aHlpSpa := {}

PutHelp( "PAXC_COLECA", aHlpPor, aHlpEng, aHlpSpa, .T. )
AutoGrLog( "Atualizado o Help do campo " + "AXC_COLECA" )

aHlpPor := {}
aAdd( aHlpPor, 'Status do Pre-Pedido de Compra com' )
aAdd( aHlpPor, 'Grade.' )
aAdd( aHlpPor, '1=Em Negociação' )
aAdd( aHlpPor, '2=Em Cadastro' )
aAdd( aHlpPor, '3=Encerrado' )
aAdd( aHlpPor, '4=Cancelado' )
aHlpEng := {}
aHlpSpa := {}

PutHelp( "PAXC_STATUS", aHlpPor, aHlpEng, aHlpSpa, .T. )
AutoGrLog( "Atualizado o Help do campo " + "AXC_STATUS" )

aHlpPor := {}
aAdd( aHlpPor, 'Observação' )
aHlpEng := {}
aHlpSpa := {}

PutHelp( "PAXC_OBSMEM", aHlpPor, aHlpEng, aHlpSpa, .T. )
AutoGrLog( "Atualizado o Help do campo " + "AXC_OBSMEM" )

aHlpPor := {}
aAdd( aHlpPor, 'Item do Produto' )
aHlpEng := {}
aHlpSpa := {}

PutHelp( "PAXC_ITPROD", aHlpPor, aHlpEng, aHlpSpa, .T. )
AutoGrLog( "Atualizado o Help do campo " + "AXC_ITPROD" )

aHlpPor := {}
aAdd( aHlpPor, 'Produto Utiliza Grade:' )
aAdd( aHlpPor, 'S=Sim ou N=Nao' )
aHlpEng := {}
aHlpSpa := {}

PutHelp( "PAXC_UTGRD ", aHlpPor, aHlpEng, aHlpSpa, .T. )
AutoGrLog( "Atualizado o Help do campo " + "AXC_UTGRD" )

aHlpPor := {}
aAdd( aHlpPor, 'Digite o número da tabela,já cadastrada' )
aAdd( aHlpPor, 'no Configurador, que definiram as colu-' )
aAdd( aHlpPor, 'nas da grade.' )
aHlpEng := {}
aHlpSpa := {}

PutHelp( "PAXC_COLUNA", aHlpPor, aHlpEng, aHlpSpa, .T. )
AutoGrLog( "Atualizado o Help do campo " + "AXC_COLUNA" )

aHlpPor := {}
aAdd( aHlpPor, 'Digite o número da tabela,já cadastrada' )
aAdd( aHlpPor, 'no configurador, que definiram as' )
aAdd( aHlpPor, 'linhasde sua grade.' )
aHlpEng := {}
aHlpSpa := {}

PutHelp( "PAXC_LINHA ", aHlpPor, aHlpEng, aHlpSpa, .T. )
AutoGrLog( "Atualizado o Help do campo " + "AXC_LINHA" )

aHlpPor := {}
aAdd( aHlpPor, 'Chave Coluna' )
aHlpEng := {}
aHlpSpa := {}

PutHelp( "PAXC_CHVCOL", aHlpPor, aHlpEng, aHlpSpa, .T. )
AutoGrLog( "Atualizado o Help do campo " + "AXC_CHVCOL" )

aHlpPor := {}
aAdd( aHlpPor, 'Numero do Pedido de Compra.' )
aHlpEng := {}
aHlpSpa := {}

PutHelp( "PAXC_NUMPC ", aHlpPor, aHlpEng, aHlpSpa, .T. )
AutoGrLog( "Atualizado o Help do campo " + "AXC_NUMPC" )

//
// Helps Tabela AXD
//
aHlpPor := {}
aAdd( aHlpPor, 'Item do Produto' )
aHlpEng := {}
aHlpSpa := {}

PutHelp( "PAXD_ITPROD", aHlpPor, aHlpEng, aHlpSpa, .T. )
AutoGrLog( "Atualizado o Help do campo " + "AXD_ITPROD" )

aHlpPor := {}
aAdd( aHlpPor, 'Chave Coluna' )
aHlpEng := {}
aHlpSpa := {}

PutHelp( "PAXD_CHVCOL", aHlpPor, aHlpEng, aHlpSpa, .T. )
AutoGrLog( "Atualizado o Help do campo " + "AXD_CHVCOL" )

aHlpPor := {}
aAdd( aHlpPor, 'Quantidade Carteira.' )
aHlpEng := {}
aHlpSpa := {}

PutHelp( "PAXD_QTDCAR", aHlpPor, aHlpEng, aHlpSpa, .T. )
AutoGrLog( "Atualizado o Help do campo " + "AXD_QTDCAR" )

//
// Helps Tabela AXE
//
aHlpPor := {}
aAdd( aHlpPor, 'Numero do Pré-Pedido de Compra.' )
aHlpEng := {}
aHlpSpa := {}

PutHelp( "PAXE_NUMPRE", aHlpPor, aHlpEng, aHlpSpa, .T. )
AutoGrLog( "Atualizado o Help do campo " + "AXE_NUMPRE" )

aHlpPor := {}
aAdd( aHlpPor, 'Item Produto no Pré-pedido de Compra.' )
aHlpEng := {}
aHlpSpa := {}

PutHelp( "PAXE_ITPROD", aHlpPor, aHlpEng, aHlpSpa, .T. )
AutoGrLog( "Atualizado o Help do campo " + "AXE_ITPROD" )

//
// Helps Tabela AXH
//
//
// Helps Tabela AXI
//
//
// Helps Tabela AXJ
//
//
// Helps Tabela AXK
//
//
// Helps Tabela AYM
//
//
// Helps Tabela SC7
//
aHlpPor := {}
aAdd( aHlpPor, 'Numero do Pré Pedido de Compra.' )
aHlpEng := {}
aHlpSpa := {}

PutHelp( "PC7_01PREPC", aHlpPor, aHlpEng, aHlpSpa, .T. )
AutoGrLog( "Atualizado o Help do campo " + "C7_01PREPC" )

aHlpPor := {}
aAdd( aHlpPor, 'Data da verba de compra a ser utilizada.' )
aHlpEng := {}
aHlpSpa := {}

PutHelp( "PC7_01DTVRB", aHlpPor, aHlpEng, aHlpSpa, .T. )
AutoGrLog( "Atualizado o Help do campo " + "C7_01DTVRB" )

//
// Helps Tabela SY1
//
aHlpPor := {}
aAdd( aHlpPor, 'Permissão para inclusão de Pré-Pedido' )
aAdd( aHlpPor, 'deCompra.' )
aHlpEng := {}
aHlpSpa := {}

PutHelp( "PY1_01PREPC", aHlpPor, aHlpEng, aHlpSpa, .T. )
AutoGrLog( "Atualizado o Help do campo " + "Y1_01PREPC" )

aHlpPor := {}
aAdd( aHlpPor, 'Permissão para aprovar Pré-Pedido de' )
aAdd( aHlpPor, 'Compra.' )
aHlpEng := {}
aHlpSpa := {}

PutHelp( "PY1_01APPRE", aHlpPor, aHlpEng, aHlpSpa, .T. )
AutoGrLog( "Atualizado o Help do campo " + "Y1_01APPRE" )

aHlpPor := {}
aAdd( aHlpPor, 'Permissão para completar o cadastro dos' )
aAdd( aHlpPor, 'produtos novos do Pré-Pedido de Compra.' )
aHlpEng := {}
aHlpSpa := {}

PutHelp( "PY1_01CDPRE", aHlpPor, aHlpEng, aHlpSpa, .T. )
AutoGrLog( "Atualizado o Help do campo " + "Y1_01CDPRE" )

//
// Helps Tabela AXL
//
aHlpPor := {}
aAdd( aHlpPor, 'Numero da Divergencia' )
aHlpEng := {}
aHlpSpa := {}

PutHelp( "PAXL_NUM   ", aHlpPor, aHlpEng, aHlpSpa, .T. )
AutoGrLog( "Atualizado o Help do campo " + "AXL_NUM" )

aHlpPor := {}
aAdd( aHlpPor, 'Data de Emissao do Ticket de' )
aAdd( aHlpPor, 'Divergencia.' )
aHlpEng := {}
aHlpSpa := {}

PutHelp( "PAXL_EMISSA", aHlpPor, aHlpEng, aHlpSpa, .T. )
AutoGrLog( "Atualizado o Help do campo " + "AXL_EMISSA" )

aHlpPor := {}
aAdd( aHlpPor, 'Hora da Inclusao do Ticket.' )
aHlpEng := {}
aHlpSpa := {}

PutHelp( "PAXL_HORA  ", aHlpPor, aHlpEng, aHlpSpa, .T. )
AutoGrLog( "Atualizado o Help do campo " + "AXL_HORA" )

aHlpPor := {}
aAdd( aHlpPor, 'Usuário' )
aHlpEng := {}
aHlpSpa := {}

PutHelp( "PAXL_USER  ", aHlpPor, aHlpEng, aHlpSpa, .T. )
AutoGrLog( "Atualizado o Help do campo " + "AXL_USER" )

aHlpPor := {}
aAdd( aHlpPor, 'Tipo da Divergencia' )
aHlpEng := {}
aHlpSpa := {}

PutHelp( "PAXL_TIPO  ", aHlpPor, aHlpEng, aHlpSpa, .T. )
AutoGrLog( "Atualizado o Help do campo " + "AXL_TIPO" )

aHlpPor := {}
aAdd( aHlpPor, 'Descrição do Tipo' )
aHlpEng := {}
aHlpSpa := {}

PutHelp( "PAXL_DESCTP", aHlpPor, aHlpEng, aHlpSpa, .T. )
AutoGrLog( "Atualizado o Help do campo " + "AXL_DESCTP" )

aHlpPor := {}
aAdd( aHlpPor, 'Codigo do Fornecedor' )
aHlpEng := {}
aHlpSpa := {}

PutHelp( "PAXL_CODFOR", aHlpPor, aHlpEng, aHlpSpa, .T. )
AutoGrLog( "Atualizado o Help do campo " + "AXL_CODFOR" )

aHlpPor := {}
aAdd( aHlpPor, 'Loja do Fornecedor' )
aHlpEng := {}
aHlpSpa := {}

PutHelp( "PAXL_LOJFOR", aHlpPor, aHlpEng, aHlpSpa, .T. )
AutoGrLog( "Atualizado o Help do campo " + "AXL_LOJFOR" )

aHlpPor := {}
aAdd( aHlpPor, 'Nome do Fornecedor' )
aHlpEng := {}
aHlpSpa := {}

PutHelp( "PAXL_NOMFOR", aHlpPor, aHlpEng, aHlpSpa, .T. )
AutoGrLog( "Atualizado o Help do campo " + "AXL_NOMFOR" )

aHlpPor := {}
aAdd( aHlpPor, 'Numero do Pre-Pedido de Compra.' )
aHlpEng := {}
aHlpSpa := {}

PutHelp( "PAXL_NUMPRE", aHlpPor, aHlpEng, aHlpSpa, .T. )
AutoGrLog( "Atualizado o Help do campo " + "AXL_NUMPRE" )

aHlpPor := {}
aAdd( aHlpPor, 'Titulo da Divergencia' )
aHlpEng := {}
aHlpSpa := {}

PutHelp( "PAXL_TITULO", aHlpPor, aHlpEng, aHlpSpa, .T. )
AutoGrLog( "Atualizado o Help do campo " + "AXL_TITULO" )

aHlpPor := {}
aAdd( aHlpPor, 'Observação. Detalhe a divergência.' )
aHlpEng := {}
aHlpSpa := {}

PutHelp( "PAXL_OBSERV", aHlpPor, aHlpEng, aHlpSpa, .T. )
AutoGrLog( "Atualizado o Help do campo " + "AXL_OBSERV" )

//
// Helps Tabela AXM
//
aHlpPor := {}
aAdd( aHlpPor, 'Codigo' )
aHlpEng := {}
aHlpSpa := {}

PutHelp( "PAXM_CODIGO", aHlpPor, aHlpEng, aHlpSpa, .T. )
AutoGrLog( "Atualizado o Help do campo " + "AXM_CODIGO" )

aHlpPor := {}
aAdd( aHlpPor, 'Descrição' )
aHlpEng := {}
aHlpSpa := {}

PutHelp( "PAXM_DESCRI", aHlpPor, aHlpEng, aHlpSpa, .T. )
AutoGrLog( "Atualizado o Help do campo " + "AXM_DESCRI" )

AutoGrLog( CRLF + "Final da Atualização" + " " + "Helps de Campos" + CRLF + Replicate( "-", 128 ) + CRLF )

Return {}


//--------------------------------------------------------------------
/*/{Protheus.doc} EscEmpresa
Função genérica para escolha de Empresa, montada pelo SM0

@return aRet Vetor contendo as seleções feitas.
             Se não for marcada nenhuma o vetor volta vazio

@author Ernani Forastieri
@since  27/09/2004
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function EscEmpresa()

//---------------------------------------------
// Parâmetro  nTipo
// 1 - Monta com Todas Empresas/Filiais
// 2 - Monta só com Empresas
// 3 - Monta só com Filiais de uma Empresa
//
// Parâmetro  aMarcadas
// Vetor com Empresas/Filiais pré marcadas
//
// Parâmetro  cEmpSel
// Empresa que será usada para montar seleção
//---------------------------------------------
Local   aRet      := {}
Local   aSalvAmb  := GetArea()
Local   aSalvSM0  := {}
Local   aVetor    := {}
Local   cMascEmp  := "??"
Local   cVar      := ""
Local   lChk      := .F.
Local   lOk       := .F.
Local   lTeveMarc := .F.
Local   oNo       := LoadBitmap( GetResources(), "LBNO" )
Local   oOk       := LoadBitmap( GetResources(), "LBOK" )
Local   oDlg, oChkMar, oLbx, oMascEmp, oSay
Local   oButDMar, oButInv, oButMarc, oButOk, oButCanc

Local   aMarcadas := {}


If !MyOpenSm0(.F.)
	Return aRet
EndIf


dbSelectArea( "SM0" )
aSalvSM0 := SM0->( GetArea() )
dbSetOrder( 1 )
dbGoTop()

While !SM0->( EOF() )

	If aScan( aVetor, {|x| x[2] == SM0->M0_CODIGO} ) == 0
		aAdd(  aVetor, { aScan( aMarcadas, {|x| x[1] == SM0->M0_CODIGO .and. x[2] == SM0->M0_CODFIL} ) > 0, SM0->M0_CODIGO, SM0->M0_CODFIL, SM0->M0_NOME, SM0->M0_FILIAL } )
	EndIf

	dbSkip()
End

RestArea( aSalvSM0 )

Define MSDialog  oDlg Title "" From 0, 0 To 280, 395 Pixel

oDlg:cToolTip := "Tela para Múltiplas Seleções de Empresas/Filiais"

oDlg:cTitle   := "Selecione a(s) Empresa(s) para Atualização"

@ 10, 10 Listbox  oLbx Var  cVar Fields Header " ", " ", "Empresa" Size 178, 095 Of oDlg Pixel
oLbx:SetArray(  aVetor )
oLbx:bLine := {|| {IIf( aVetor[oLbx:nAt, 1], oOk, oNo ), ;
aVetor[oLbx:nAt, 2], ;
aVetor[oLbx:nAt, 4]}}
oLbx:BlDblClick := { || aVetor[oLbx:nAt, 1] := !aVetor[oLbx:nAt, 1], VerTodos( aVetor, @lChk, oChkMar ), oChkMar:Refresh(), oLbx:Refresh()}
oLbx:cToolTip   :=  oDlg:cTitle
oLbx:lHScroll   := .F. // NoScroll

@ 112, 10 CheckBox oChkMar Var  lChk Prompt "Todos" Message "Marca / Desmarca"+ CRLF + "Todos" Size 40, 007 Pixel Of oDlg;
on Click MarcaTodos( lChk, @aVetor, oLbx )

// Marca/Desmarca por mascara
@ 113, 51 Say   oSay Prompt "Empresa" Size  40, 08 Of oDlg Pixel
@ 112, 80 MSGet oMascEmp Var  cMascEmp Size  05, 05 Pixel Picture "@!"  Valid (  cMascEmp := StrTran( cMascEmp, " ", "?" ), oMascEmp:Refresh(), .T. ) ;
Message "Máscara Empresa ( ?? )"  Of oDlg
oSay:cToolTip := oMascEmp:cToolTip

@ 128, 10 Button oButInv    Prompt "&Inverter"  Size 32, 12 Pixel Action ( InvSelecao( @aVetor, oLbx, @lChk, oChkMar ), VerTodos( aVetor, @lChk, oChkMar ) ) ;
Message "Inverter Seleção" Of oDlg
oButInv:SetCss( CSSBOTAO )
@ 128, 50 Button oButMarc   Prompt "&Marcar"    Size 32, 12 Pixel Action ( MarcaMas( oLbx, aVetor, cMascEmp, .T. ), VerTodos( aVetor, @lChk, oChkMar ) ) ;
Message "Marcar usando" + CRLF + "máscara ( ?? )"    Of oDlg
oButMarc:SetCss( CSSBOTAO )
@ 128, 80 Button oButDMar   Prompt "&Desmarcar" Size 32, 12 Pixel Action ( MarcaMas( oLbx, aVetor, cMascEmp, .F. ), VerTodos( aVetor, @lChk, oChkMar ) ) ;
Message "Desmarcar usando" + CRLF + "máscara ( ?? )" Of oDlg
oButDMar:SetCss( CSSBOTAO )
@ 112, 157  Button oButOk   Prompt "Processar"  Size 32, 12 Pixel Action (  RetSelecao( @aRet, aVetor ), oDlg:End()  ) ;
Message "Confirma a seleção e efetua" + CRLF + "o processamento" Of oDlg
oButOk:SetCss( CSSBOTAO )
@ 128, 157  Button oButCanc Prompt "Cancelar"   Size 32, 12 Pixel Action ( IIf( lTeveMarc, aRet :=  aMarcadas, .T. ), oDlg:End() ) ;
Message "Cancela o processamento" + CRLF + "e abandona a aplicação" Of oDlg
oButCanc:SetCss( CSSBOTAO )

Activate MSDialog  oDlg Center

RestArea( aSalvAmb )
dbSelectArea( "SM0" )
dbCloseArea()

Return  aRet


//--------------------------------------------------------------------
/*/{Protheus.doc} MarcaTodos
Função auxiliar para marcar/desmarcar todos os ítens do ListBox ativo

@param lMarca  Contéudo para marca .T./.F.
@param aVetor  Vetor do ListBox
@param oLbx    Objeto do ListBox

@author Ernani Forastieri
@since  27/09/2004
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function MarcaTodos( lMarca, aVetor, oLbx )
Local  nI := 0

For nI := 1 To Len( aVetor )
	aVetor[nI][1] := lMarca
Next nI

oLbx:Refresh()

Return NIL


//--------------------------------------------------------------------
/*/{Protheus.doc} InvSelecao
Função auxiliar para inverter a seleção do ListBox ativo

@param aVetor  Vetor do ListBox
@param oLbx    Objeto do ListBox

@author Ernani Forastieri
@since  27/09/2004
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function InvSelecao( aVetor, oLbx )
Local  nI := 0

For nI := 1 To Len( aVetor )
	aVetor[nI][1] := !aVetor[nI][1]
Next nI

oLbx:Refresh()

Return NIL


//--------------------------------------------------------------------
/*/{Protheus.doc} RetSelecao
Função auxiliar que monta o retorno com as seleções

@param aRet    Array que terá o retorno das seleções (é alterado internamente)
@param aVetor  Vetor do ListBox

@author Ernani Forastieri
@since  27/09/2004
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function RetSelecao( aRet, aVetor )
Local  nI    := 0

aRet := {}
For nI := 1 To Len( aVetor )
	If aVetor[nI][1]
		aAdd( aRet, { aVetor[nI][2] , aVetor[nI][3], aVetor[nI][2] +  aVetor[nI][3] } )
	EndIf
Next nI

Return NIL


//--------------------------------------------------------------------
/*/{Protheus.doc} MarcaMas
Função para marcar/desmarcar usando máscaras

@param oLbx     Objeto do ListBox
@param aVetor   Vetor do ListBox
@param cMascEmp Campo com a máscara (???)
@param lMarDes  Marca a ser atribuída .T./.F.

@author Ernani Forastieri
@since  27/09/2004
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function MarcaMas( oLbx, aVetor, cMascEmp, lMarDes )
Local cPos1 := SubStr( cMascEmp, 1, 1 )
Local cPos2 := SubStr( cMascEmp, 2, 1 )
Local nPos  := oLbx:nAt
Local nZ    := 0

For nZ := 1 To Len( aVetor )
	If cPos1 == "?" .or. SubStr( aVetor[nZ][2], 1, 1 ) == cPos1
		If cPos2 == "?" .or. SubStr( aVetor[nZ][2], 2, 1 ) == cPos2
			aVetor[nZ][1] := lMarDes
		EndIf
	EndIf
Next

oLbx:nAt := nPos
oLbx:Refresh()

Return NIL


//--------------------------------------------------------------------
/*/{Protheus.doc} VerTodos
Função auxiliar para verificar se estão todos marcados ou não

@param aVetor   Vetor do ListBox
@param lChk     Marca do CheckBox do marca todos (referncia)
@param oChkMar  Objeto de CheckBox do marca todos

@author Ernani Forastieri
@since  27/09/2004
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function VerTodos( aVetor, lChk, oChkMar )
Local lTTrue := .T.
Local nI     := 0

For nI := 1 To Len( aVetor )
	lTTrue := IIf( !aVetor[nI][1], .F., lTTrue )
Next nI

lChk := IIf( lTTrue, .T., .F. )
oChkMar:Refresh()

Return NIL


//--------------------------------------------------------------------
/*/{Protheus.doc} MyOpenSM0
Função de processamento abertura do SM0 modo exclusivo

@author TOTVS Protheus
@since  16/12/2016
@obs    Gerado por EXPORDIC - V.5.2.1.0 EFS / Upd. V.4.20.15 EFS
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function MyOpenSM0(lShared)

Local lOpen := .F.
Local nLoop := 0

For nLoop := 1 To 20
	dbUseArea( .T., , "SIGAMAT.EMP", "SM0", lShared, .F. )

	If !Empty( Select( "SM0" ) )
		lOpen := .T.
		dbSetIndex( "SIGAMAT.IND" )
		Exit
	EndIf

	Sleep( 500 )

Next nLoop

If !lOpen
	MsgStop( "Não foi possível a abertura da tabela " + ;
	IIf( lShared, "de empresas (SM0).", "de empresas (SM0) de forma exclusiva." ), "ATENÇÃO" )
EndIf

Return lOpen


//--------------------------------------------------------------------
/*/{Protheus.doc} LeLog
Função de leitura do LOG gerado com limitacao de string

@author TOTVS Protheus
@since  16/12/2016
@obs    Gerado por EXPORDIC - V.5.2.1.0 EFS / Upd. V.4.20.15 EFS
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function LeLog()
Local cRet  := ""
Local cFile := NomeAutoLog()
Local cAux  := ""

FT_FUSE( cFile )
FT_FGOTOP()

While !FT_FEOF()

	cAux := FT_FREADLN()

	If Len( cRet ) + Len( cAux ) < 1048000
		cRet += cAux + CRLF
	Else
		cRet += CRLF
		cRet += Replicate( "=" , 128 ) + CRLF
		cRet += "Tamanho de exibição maxima do LOG alcançado." + CRLF
		cRet += "LOG Completo no arquivo " + cFile + CRLF
		cRet += Replicate( "=" , 128 ) + CRLF
		Exit
	EndIf

	FT_FSKIP()
End

FT_FUSE()

Return cRet


/////////////////////////////////////////////////////////////////////////////
