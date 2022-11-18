#INCLUDE "PROTHEUS.CH"
#INCLUDE "rwmake.ch"
#INCLUDE "PROTHEUS.CH"
#INCLUDE "TBICONN.CH"
#INCLUDE "TOPCONN.CH"
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
/*/{Protheus.doc} ATUTESTE
Fun��o de update de dicion�rios para compatibiliza��o

@author TOTVS Protheus
@since  28/05/2019
@obs    Gerado por EXPORDIC - V.5.2.1.0 EFS / Upd. V.4.20.15 EFS
@version 1.0
/*/
//--------------------------------------------------------------------
User Function ATUTESTE( cEmpAmb, cFilAmb )

	Local aSay      	:= {}
	Local aButton   	:= {}
	Local aMarcadas 	:= {}
	Local cTitulo   	:= "ATUALIZA��O DE DICION�RIOS E TABELAS DO SISTEMA (SIX/SX2/SX3/SX6)"
	Local cDesc1    	:= " "
	Local cDesc2    	:= "Descri��o: ESTE PROGRAMA DEVE SER EXECUTADO EM AMBIENTE TESTE"
	Local cDesc3    	:= " "
	Local cDesc4    	:= "N�O DEVE SER EXECUTADO EM AMBIENTE PRODU��O!!!!!!!!"
	Local cDesc5    	:= " "
	// Local cDesc6    	:= ""
	// Local cDesc7    	:= ""
	Local lOk       	:= .F.
	Local lAuto     	:= ( cEmpAmb <> NIL .or. cFilAmb <> NIL )
	Local nW		  	:= 0
	Local cAuxMailDev  	:= ""
	Local cNextRealease	:= "R33"

	Private cNomeAmb 	:= UPPER(GetEnvServer())
	Private cPrtSched	:= ""

	Private cIPWs       := ''
	Private cIPTSS      := ''

	Private cPrtWS		:= ''
	Private cPrtTSS		:= ''
	Private cPrtTAFRest := ''
	Private cPrtTAFHttp	:= ''

	Private aUserDev	:= {"000795"}
	Private cEmailDev	:= ""
	Private cUserDev	:= ""

	Private oMainWnd  	:= NIL
	Private oProcess  	:= NIL

	//Controle de atualiza��o em migra��es
	If cNextRealease $ cNomeAmb
		cNomeAmb := "QA"
	End

	For nW := 1 To Len(aUserDev)

		cAuxMailDev := AllTrim(UsrRetMail(aUserDev[nW]))

		If !Empty(cAuxMailDev)

			cEmailDev += If(Empty(cEmailDev), cAuxMailDev, ";" + cAuxMailDev)

		EndIf

		cUserDev += If(Empty(cUserDev), aUserDev[nW], ";" + aUserDev[nW])

	Next nW

	#IFDEF TOP
		TCInternal( 5, "*OFF" ) // Desliga Refresh no Lock do Top
	#EndIf

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

	If 'HOMOLOG' $ cNomeAmb .OR. 'TESTE' $ cNomeAmb  .OR. 'QA' $ cNomeAmb  .OR. 'DEV' $ cNomeAmb

		cIPWs := '10.1.1.108'

		cIPTSS := cIPWs // Caso o TSS esteja em outro servidor mudar aqui.

		If 'TESTE' $ cNomeAmb

			cPrtWS 			:= '9184'

			cPrtTSS 		:= "8097"

			cPrtTAFRest  	:= "8195"

			cPrtTAFHttp 	:= "8194"

			cPrtSched 		:= "1333"

		ELSEif 'HOMOLOG' $ cNomeAmb

			cPrtWS 			:= '9071'

			cPrtTSS 		:= "8097"

			cPrtTAFRest  	:= "8191"

			cPrtTAFHttp 	:= "8190"

			cPrtSched 		:= "1332"

		ElseIf 'QA' $ cNomeAmb

			cPrtWS 			:= '9189'

			cPrtTSS 		:= "8097"

			cPrtTAFRest  	:= "8191"

			cPrtTAFHttp 	:= "8190"

			cPrtSched 		:= "1331"

		ElseIf 'DEV' $ cNomeAmb

			cPrtWS 			:= '8189'

			cPrtTSS 		:= "8097"

			cPrtTAFRest  	:= "9104"

			cPrtTAFHttp 	:= "9992"

			cPrtSched 		:= "1330"

		EndIf

	EndIf

	if 'PRODUC' $ cNomeAmb
		MsgStop( "N�o � poss�vel rodar esta rotina em base de PRODU��O.", "ATUTESTE" )
	ELSE

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
				If lAuto .OR. MsgNoYes( "Confirma a atualiza��o dos dicion�rios ?", cTitulo )
					oProcess := MsNewProcess():New( { | lEnd | lOk := FSTProc( @lEnd, aMarcadas, lAuto ) }, "Atualizando", "Aguarde, atualizando ...", .F. )
					oProcess:Activate()

					If lAuto
						If lOk
							MsgStop( "Atualiza��o Realizada.", "ATUTESTE" )
						Else
							MsgStop( "Atualiza��o n�o Realizada.", "ATUTESTE" )
						EndIf
						dbCloseAll()
					Else
						If lOk
							Final( "Atualiza��o Conclu�da." )
						Else
							Final( "Atualiza��o n�o Realizada." )
						EndIf
					EndIf

				Else
					MsgStop( "Atualiza��o n�o Realizada.", "ATUTESTE" )

				EndIf

			Else
				MsgStop( "Atualiza��o n�o Realizada.", "ATUTESTE" )

			EndIf

		EndIF

	EndIf

Return NIL

Static Function PreCadCyberlog()

	Local lAdd := .T.

	dbSelectArea("ZA2")
	dbSetOrder(1) // ZA2_FILIAL, ZA2_COD, R_E_C_N_O_, D_E_L_E_T_

	AutoGrLog( Replicate( "-", 128 ) )

	lAdd := ZA2->(DBSeek("010104"))

	AutoGrLog( If(lAdd, "ZA2 Inclu�do", "ZA2 Alterado") )

	RecLock("ZA2", !lAdd)
	ZA2->ZA2_FILIAL	:= "010104"
	ZA2->ZA2_DEPOSI	:= "1"
	ZA2->ZA2_DEPB2B	:= "4"
	ZA2->ZA2_URL	:= "http://10.1.1.109:9292/cyberweb/api"
	ZA2->ZA2_CONTA	:= "sync_dep_1"
	ZA2->ZA2_SENHA	:= "5A245BEF62298E499FFD3177083B704F"
	ZA2->ZA2_CHAVE	:= "b_rcVLRUsqLRIyPneDFVpLXvUYGFVqPUKKoSyDADL5E"

	ZA2->ZA2_PVAUTO	:= "S"
	ZA2->ZA2_PNAUTO	:= "N"
	ZA2->ZA2_FOAUTO := "N"
	ZA2->ZA2_CLAUTO := "N"
	ZA2->ZA2_PRAUTO := "N"
	ZA2->ZA2_TRAUTO := "N"
	ZA2->ZA2_TOKENR	:= "IXtFDg5WXiwl30R0Pt7bOY4eizTqbYAk"

	ZA2->ZA2_MSBLQL	:= "2"
	ZA2->(MsUnLock())

	AutoGrLog( Replicate( "-", 128 ) )

Return()

Static Function AtuSchedule()

	Local cUpdate := ""
	Local nPos := Rat("_", cNomeAmb)

	RpcSetEnv("02", "01")

	If nPos > 0

		cNomeAmb := SubStr(cNomeAmb, 1, nPos-1) + "_SCHEDULE"

	Else

		cNomeAmb := cNomeAmb + "_SCHEDULE"

	EndIf

	cUpdate := " UPDATE A SET XX0_ENV = " + ValToSql(cNomeAmb) + ", XX0_IP = " + ValToSql(GetServerIP()) + ", XX0_PORTA = " + cPrtSched
	cUpdate += " FROM XX0 A "
	cUpdate += " WHERE D_E_L_E_T_ = '' "

	cUpdate := UPPER(cUpdate)

	nUpdate := TcSqlExec(cUpdate)

	If (nUpdate < 0)
		ConOut("LOG DO UPDATE: " + TCSQLError())
	EndIf

	cUpdate := " UPDATE A SET XX1_STATUS = '1', XX1_ENV = " + ValToSql(cNomeAmb)
	cUpdate += " FROM XX1 A "
	cUpdate += " WHERE D_E_L_E_T_ = '' "

	cUpdate := UPPER(cUpdate)

	nUpdate := TcSqlExec(cUpdate)

	If (nUpdate < 0)
		ConOut("LOG DO UPDATE: " + TCSQLError())
	EndIf

	RpcClearEnv()

Return()

Static Function AtuEmailUsers()

	Local cUpdate := ""
	Local cEmailFor := SubStr(cEmailDev, 1, At(";", cEmailDev))

	RpcSetEnv("02", "01")

	cUpdate := " UPDATE A SET USR_EMAIL = CASE WHEN CHARINDEX('.RELEASE', USR_EMAIL) > 0 THEN USR_EMAIL ELSE RTRIM(LTRIM(USR_EMAIL)) + '.RELEASE' END "
	cUpdate += " FROM SYS_USR A "
	cUpdate += " WHERE USR_ID <> '' "
	cUpdate += " AND USR_ID NOT IN ('000795', '000991', '000000', '000708', '000900', '001061', '001046') "
	cUpdate += " AND USR_EMAIL <> '' "

	cUpdate := UPPER(cUpdate)

	nUpdate := TcSqlExec(cUpdate)

	If (nUpdate < 0)
		ConOut("LOG DO UPDATE: " + TCSQLError())
	EndIf

	cUpdate := " UPDATE A SET USR_EMAIL = " + ValToSql(cEmailFor)
	cUpdate += " FROM SYS_USR A "
	cUpdate += " WHERE USR_ID IN ( '000000' ) "

	cUpdate := UPPER(cUpdate)

	nUpdate := TcSqlExec(cUpdate)

	If (nUpdate < 0)
		ConOut("LOG DO UPDATE: " + TCSQLError())
	EndIf

	RpcClearEnv()

Return()

//--------------------------------------------------------------------
/*/{Protheus.doc} FSTProc
Fun��o de processamento da grava��o dos arquivos

@author TOTVS Protheus
@since  28/05/2019
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

	If ( lOpen := OpenSm0Excl() )

		OpenSm0()
		dbGoTop()

		While !SM0->( EOF() )
			// S� adiciona no aRecnoSM0 se a empresa for diferente
			If aScan( aRecnoSM0, { |x| x[2] == SM0->M0_CODIGO } ) == 0 ;
					.AND. aScan( aMarcadas, { |x| x[1] == SM0->M0_CODIGO } ) > 0
				aAdd( aRecnoSM0, { Recno(), SM0->M0_CODIGO } )
			EndIf
			SM0->( dbSkip() )
		End

		SM0->( dbCloseArea() )

		If lOpen

			//AtuSchedule()

			//AtuEmailUsers()

			For nI := 1 To Len( aRecnoSM0 )

				If !( lOpen := OpenSm0Excl() )
					MsgStop( "Atualiza��o da empresa " + aRecnoSM0[nI][2] + " n�o efetuada." )
					Exit
				EndIf

				SM0->( dbGoTo( aRecnoSM0[nI][1] ) )

				RpcSetType( 3 )
				RpcSetEnv( SM0->M0_CODIGO, SM0->M0_CODFIL )

				lMsFinalAuto := .F.
				lMsHelpAuto  := .F.

				AutoGrLog( Replicate( "-", 128 ) )
				AutoGrLog( Replicate( " ", 128 ) )
				AutoGrLog( "LOG DA ATUALIZA��O DOS DICION�RIOS" )
				AutoGrLog( Replicate( " ", 128 ) )
				AutoGrLog( Replicate( "-", 128 ) )
				AutoGrLog( " " )
				AutoGrLog( " Dados Ambiente" )
				AutoGrLog( " --------------------" )
				AutoGrLog( " Empresa / Filial...: " + cEmpAnt + "/" + cFilAnt )
				AutoGrLog( " Nome Empresa.......: " + Capital( AllTrim( GetAdvFVal( "SM0", "M0_NOMECOM", cEmpAnt + cFilAnt, 1, "" ) ) ) )
				AutoGrLog( " Nome Filial........: " + Capital( AllTrim( GetAdvFVal( "SM0", "M0_FILIAL" , cEmpAnt + cFilAnt, 1, "" ) ) ) )
				AutoGrLog( " DataBase...........: " + DtoC( dDataBase ) )
				AutoGrLog( " Data / Hora �nicio.: " + DtoC( Date() )  + " / " + Time() )
				AutoGrLog( " Environment........: " + GetEnvServer()  )
				AutoGrLog( " StartPath..........: " + GetSrvProfString( "StartPath", "" ) )
				AutoGrLog( " RootPath...........: " + GetSrvProfString( "RootPath" , "" ) )
				AutoGrLog( " Vers�o.............: " + GetVersao(.T.) )
				AutoGrLog( " Usu�rio TOTVS .....: " + __cUserId + " " +  cUserName )
				AutoGrLog( " Computer Name......: " + GetComputerName() )

				aInfo   := GetUserInfo()
				If ( nPos    := aScan( aInfo,{ |x,y| x[3] == ThreadId() } ) ) > 0
					AutoGrLog( " " )
					AutoGrLog( " Dados Thread" )
					AutoGrLog( " --------------------" )
					AutoGrLog( " Usu�rio da Rede....: " + aInfo[nPos][1] )
					AutoGrLog( " Esta��o............: " + aInfo[nPos][2] )
					AutoGrLog( " Programa Inicial...: " + aInfo[nPos][5] )
					AutoGrLog( " Environment........: " + aInfo[nPos][6] )
					AutoGrLog( " Conex�o............: " + AllTrim( StrTran( StrTran( aInfo[nPos][7], Chr( 13 ), "" ), Chr( 10 ), "" ) ) )
				EndIf
				AutoGrLog( Replicate( "-", 128 ) )
				AutoGrLog( " " )

				If !lAuto
					AutoGrLog( Replicate( "-", 128 ) )
					AutoGrLog( "Empresa : " + SM0->M0_CODIGO + "/" + SM0->M0_NOME + CRLF )
				EndIf

				oProcess:SetRegua1( 8 )

				//------------------------------------
				// Atualiza o dicion�rio SX6
				//------------------------------------
				oProcess:IncRegua1( "Dicion�rio de par�metros" + " - " + SM0->M0_CODIGO + " " + SM0->M0_NOME + " ..." )
				FSAtuSX6()

				//------------------------------------
				// Pre-cadastro Cyberlog
				//------------------------------------
				oProcess:IncRegua1( "Pre-cadastro Cyberlog" + " - " + SM0->M0_CODIGO + " " + SM0->M0_NOME + " ..." )
				PreCadCyberlog()

				AutoGrLog( Replicate( "-", 128 ) )
				AutoGrLog( " Data / Hora Final.: " + DtoC( Date() ) + " / " + Time() )
				AutoGrLog( Replicate( "-", 128 ) )

				RpcClearEnv()

			Next nI

			If !lAuto

				cTexto := LeLog()

				Define Font oFont Name "Mono AS" Size 5, 12

				Define MsDialog oDlg Title "Atualiza��o concluida." From 3, 0 to 340, 417 Pixel

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
/*/{Protheus.doc} FSAtuSX6
Fun��o de processamento da grava��o do SX6 - Par�metros

@author TOTVS Protheus
@since  28/05/2019
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
	Local lTodosSim := .T.
	Local nI        := 0
	Local nJ        := 0
	Local nOpcA     := 0
	Local nTamFil   := Len( SX6->X6_FIL )
	Local nTamVar   := Len( SX6->X6_VAR )

	AutoGrLog( "�nicio da Atualiza��o" + " SX6" + CRLF )

	aEstrut := { "X6_FIL"    , "X6_VAR"    , "X6_TIPO"   , "X6_DESCRIC", "X6_DSCSPA" , "X6_DSCENG" , "X6_DESC1"  , ;
		"X6_DSCSPA1", "X6_DSCENG1", "X6_DESC2"  , "X6_DSCSPA2", "X6_DSCENG2", "X6_CONTEUD", "X6_CONTSPA", ;
		"X6_CONTENG", "X6_PROPRI" , "X6_VALID"  , "X6_INIT"   , "X6_DEFPOR" , "X6_DEFSPA" , "X6_DEFENG" , ;
		"X6_PYME"   }

	aAdd( aSX6, { ;
		'  '																	, ; //X6_FIL
	'MV_ENDWF'																, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Endere�o servidor de aplica�ao'										, ; //X6_DESCRIC
	'Endere�o servidor de aplica�ao'										, ; //X6_DSCSPA
	'Endere�o servidor de aplica�ao'										, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	cIPWs															, ; //X6_CONTEUD
	cIPWs															, ; //X6_CONTSPA
	cIPWs															, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

	aAdd( aSX6, { ;
		'  '																	, ; //X6_FIL
	'MV_SPEDURL'															, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'URL de comunica��o com o TSS'											, ; //X6_DESCRIC
	'URL de comunicacion con el TSS'										, ; //X6_DSCSPA
	'URL of commuication with TSS'											, ; //X6_DSCENG
	'URL de comunica��o com o TSS'											, ; //X6_DESC1
	'URL de comunicacion con el TSS'										, ; //X6_DSCSPA1
	'URL of commuication with TSS'											, ; //X6_DSCENG1
	'URL de comunica��o com o TSS'											, ; //X6_DESC2
	'URL de comunicacion con el TSS'										, ; //X6_DSCSPA2
	'URL of commuication with TSS'											, ; //X6_DSCENG2
	'http://'+cIPTSS+':'+cPrtTSS											, ; //X6_CONTEUD
	'http://'+cIPTSS+':'+cPrtTSS											, ; //X6_CONTSPA
	'http://'+cIPTSS+':'+cPrtTSS											, ; //X6_CONTENG
	'S'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	'S'																		} ) //X6_PYME

	aAdd( aSX6, { ;
		'01'																	, ; //X6_FIL
	'MV_TAFSURL'																, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'URL de comunicacao com o TSS no produto TAF       '												, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'http://'+cIPTSS+':'+cPrtTSS											, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

	aAdd( aSX6, { ;
		''																	, ; //X6_FIL
	'MV_TAFAMBR'																, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Identifica��o do ambiente do Reinf: 1 - Produ��o; '												, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	'2 - Produ��o Restrita - Dados Reais'									, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'2'																		, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

	aAdd( aSX6, { ;
		''																	, ; //X6_FIL
	'MV_TAFAMBE'																, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Identifica��o do Ambiente e-Social 1-Produ��o,    '					, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	'2-Produ��o restrita-dados reais;'										, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	'3-Produ��o restrita-dados fict�cios;'									, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'3'																		, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

	aAdd( aSX6, { ;
		''																	, ; //X6_FIL
	'MV_GCTPURL'																, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Servidor HTTP                                     '					, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'http://'+cIPWs+':'+cPrtTAFHttp											, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

	aAdd( aSX6, { ;
		''																	, ; //X6_FIL
	'MV_BACKEND'																, ; //X6_VAR
	'C'																		, ; //X6_TIPO
	'Servidor REST                                     '					, ; //X6_DESCRIC
	''																		, ; //X6_DSCSPA
	''																		, ; //X6_DSCENG
	''																		, ; //X6_DESC1
	''																		, ; //X6_DSCSPA1
	''																		, ; //X6_DSCENG1
	''																		, ; //X6_DESC2
	''																		, ; //X6_DSCSPA2
	''																		, ; //X6_DSCENG2
	'http://'+cIPWs+':'+cPrtTAFRest+'/rest'									, ; //X6_CONTEUD
	''																		, ; //X6_CONTSPA
	''																		, ; //X6_CONTENG
	'U'																		, ; //X6_PROPRI
	''																		, ; //X6_VALID
	''																		, ; //X6_INIT
	''																		, ; //X6_DEFPOR
	''																		, ; //X6_DEFSPA
	''																		, ; //X6_DEFENG
	''																		} ) //X6_PYME

//
// Atualizando dicion�rio
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
			AutoGrLog( "Foi inclu�do o par�metro " + aSX6[nI][1] + aSX6[nI][2] + " Conte�do [" + AllTrim( aSX6[nI][13] ) + "]" )
		Else
			lContinua := .T.
			lReclock  := .F.
			If !StrTran( SX6->X6_CONTEUD, " ", "" ) == StrTran( aSX6[nI][13], " ", "" )

				cMsg := "O par�metro " + aSX6[nI][2] + " est� com o conte�do" + CRLF + ;
					"[" + RTrim( StrTran( SX6->X6_CONTEUD, " ", "" ) ) + "]" + CRLF + ;
					", que � ser� substituido pelo NOVO conte�do " + CRLF + ;
					"[" + RTrim( StrTran( aSX6[nI][13]   , " ", "" ) ) + "]" + CRLF + ;
					"Deseja substituir ? "

				If      lTodosSim
					nOpcA := 1
				ElseIf  lTodosNao
					nOpcA := 2
				Else
					nOpcA := Aviso( "ATUALIZA��O DE DICION�RIOS E TABELAS", cMsg, { "Sim", "N�o", "Sim p/Todos", "N�o p/Todos" }, 3, "Diferen�a de conte�do - SX6" )
					lTodosSim := ( nOpcA == 3 )
					lTodosNao := ( nOpcA == 4 )

					If lTodosSim
						nOpcA := 1
						lTodosSim := MsgNoYes( "Foi selecionada a op��o de REALIZAR TODAS altera��es no SX6 e N�O MOSTRAR mais a tela de aviso." + CRLF + "Confirma a a��o [Sim p/Todos] ?" )
					EndIf

					If lTodosNao
						nOpcA := 2
						lTodosNao := MsgNoYes( "Foi selecionada a op��o de N�O REALIZAR nenhuma altera��o no SX6 que esteja diferente da base e N�O MOSTRAR mais a tela de aviso." + CRLF + "Confirma esta a��o [N�o p/Todos]?" )
					EndIf

				EndIf

				lContinua := ( nOpcA == 1 )

				If lContinua
					AutoGrLog( "Foi alterado o par�metro " + aSX6[nI][1] + aSX6[nI][2] + " de [" + ;
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

	AutoGrLog( CRLF + "Final da Atualiza��o" + " SX6" + CRLF + Replicate( "-", 128 ) + CRLF )

Return NIL


//--------------------------------------------------------------------
/*/{Protheus.doc} EscEmpresa
Fun��o gen�rica para escolha de Empresa, montada pelo SM0

@return aRet Vetor contendo as sele��es feitas.
             Se n�o for marcada nenhuma o vetor volta vazio

@author Ernani Forastieri
@since  27/09/2004
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function EscEmpresa()

//---------------------------------------------
// Par�metro  nTipo
// 1 - Monta com Todas Empresas/Filiais
// 2 - Monta s� com Empresas
// 3 - Monta s� com Filiais de uma Empresa
//
// Par�metro  aMarcadas
// Vetor com Empresas/Filiais pr� marcadas
//
// Par�metro  cEmpSel
// Empresa que ser� usada para montar sele��o
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


	If !OpenSm0Excl()
		Return aRet
	EndIf


	OpenSm0()
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

	oDlg:cToolTip := "Tela para M�ltiplas Sele��es de Empresas/Filiais"

	oDlg:cTitle   := "Selecione a(s) Empresa(s) para Atualiza��o"

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
		Message "M�scara Empresa ( ?? )"  Of oDlg
	oSay:cToolTip := oMascEmp:cToolTip

	@ 128, 10 Button oButInv    Prompt "&Inverter"  Size 32, 12 Pixel Action ( InvSelecao( @aVetor, oLbx, @lChk, oChkMar ), VerTodos( aVetor, @lChk, oChkMar ) ) ;
		Message "Inverter Sele��o" Of oDlg
	oButInv:SetCss( CSSBOTAO )
	@ 128, 50 Button oButMarc   Prompt "&Marcar"    Size 32, 12 Pixel Action ( MarcaMas( oLbx, aVetor, cMascEmp, .T. ), VerTodos( aVetor, @lChk, oChkMar ) ) ;
		Message "Marcar usando" + CRLF + "m�scara ( ?? )"    Of oDlg
	oButMarc:SetCss( CSSBOTAO )
	@ 128, 80 Button oButDMar   Prompt "&Desmarcar" Size 32, 12 Pixel Action ( MarcaMas( oLbx, aVetor, cMascEmp, .F. ), VerTodos( aVetor, @lChk, oChkMar ) ) ;
		Message "Desmarcar usando" + CRLF + "m�scara ( ?? )" Of oDlg
	oButDMar:SetCss( CSSBOTAO )
	@ 112, 157  Button oButOk   Prompt "Processar"  Size 32, 12 Pixel Action (  RetSelecao( @aRet, aVetor ), oDlg:End()  ) ;
		Message "Confirma a sele��o e efetua" + CRLF + "o processamento" Of oDlg
	oButOk:SetCss( CSSBOTAO )
	@ 128, 157  Button oButCanc Prompt "Cancelar"   Size 32, 12 Pixel Action ( IIf( lTeveMarc, aRet :=  aMarcadas, .T. ), oDlg:End() ) ;
		Message "Cancela o processamento" + CRLF + "e abandona a aplica��o" Of oDlg
	oButCanc:SetCss( CSSBOTAO )

	Activate MSDialog  oDlg Center

	RestArea( aSalvAmb )
	OpenSm0()
	dbCloseArea()

Return  aRet


//--------------------------------------------------------------------
/*/{Protheus.doc} MarcaTodos
Fun��o auxiliar para marcar/desmarcar todos os �tens do ListBox ativo

@param lMarca  Cont�udo para marca .T./.F.
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
Fun��o auxiliar para inverter a sele��o do ListBox ativo

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
Fun��o auxiliar que monta o retorno com as sele��es

@param aRet    Array que ter� o retorno das sele��es (� alterado internamente)
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
Fun��o para marcar/desmarcar usando m�scaras

@param oLbx     Objeto do ListBox
@param aVetor   Vetor do ListBox
@param cMascEmp Campo com a m�scara (???)
@param lMarDes  Marca a ser atribu�da .T./.F.

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
Fun��o auxiliar para verificar se est�o todos marcados ou n�o

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
Fun��o de processamento abertura do SM0 modo exclusivo

@author TOTVS Protheus
@since  28/05/2019
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
		MsgStop( "N�o foi poss�vel a abertura da tabela " + ;
			IIf( lShared, "de empresas (SM0).", "de empresas (SM0) de forma exclusiva." ), "ATEN��O" )
	EndIf

Return lOpen


//--------------------------------------------------------------------
/*/{Protheus.doc} LeLog
Fun��o de leitura do LOG gerado com limitacao de string

@author TOTVS Protheus
@since  28/05/2019
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
			cRet += "Tamanho de exibi��o maxima do LOG alcan�ado." + CRLF
			cRet += "LOG Completo no arquivo " + cFile + CRLF
			cRet += Replicate( "=" , 128 ) + CRLF
			Exit
		EndIf

		FT_FSKIP()
	End

	FT_FUSE()

Return cRet


/////////////////////////////////////////////////////////////////////////////
