#INCLUDE "Protheus.ch"
#INCLUDE "Rwmake.ch"
#DEFINE X3_USADO_EMUSO " "
#DEFINE X3_USADO_NAOUSADO ""   
#DEFINE X3_OBRIGAT "Α" 
#DEFINE X3_NAOOBRIGAT "ΐ"

/*/{Protheus.doc} GZP0014
@author Fabiano Filla
@since 09/07/2013
@version 1.0
@return null,  
@description 
Rotina para importacao de arquivo da Folha de Pagamento do sistema EBS para contabilidade

@see
CAMPOS: CTT_CCEBS - Centro de Custo EBS - Char(6) 
MENU: Contabilidade Gerencial -> Miscelanea -> Integracoes -> Importa Folha do EBS
 
/*/
User Function GZP0014()
	Local oDlgLeTxt
	Local lRet		:= .T.
	Local dLanc     := dDatabase
	Private _lCancelar := .F.
	Private aHeader  	 := {}
	Private aCols    	 := {}
	Private _lRet      := .F.
	Private LinDeb     := 0.00
	Private LinCre     := 0.00

	Private nTotDeb    := 0.00
	Private nTotCre    := 0.00
	Private nTotDif	 := 0.00
	
	Private _iPosLinha := 1
	Private _iPosData  := 2
	Private _iPosConta := 3
	Private _iPosDesCt := 4
	Private _iPosCC    := 5
	Private _iPosDebVlr:= 6
	Private _iPosCreVlr:= 7
	Private _iPosHistor:= 8

	nomeprog:= "GZS0017"
	cPerg   := "GZS0017"
	cPerg   += Space( Len(Sx1->x1_grupo) - Len(cPerg) )
	wnrel   := "GZS0017"
   
	//VerPerg()
 	
	While .T.
		@ 200, 001 to 350, 400 dialog oDlgLeTxt Title "Importaηγo Folha do EBS"
		@ 013, 007 Say "Data Lancamento: "
		@ 010, 053 MSGET dLanc 		Size 050,010 	OF oDlgLeTxt  PIXEL
		@ 035, 007 Say "Arquivo TXT" 	SIZE 039, 007 OF oDlgLeTxt	 		PIXEL
		@ 032, 053 MSGET 	MV_PAR02		SIZE 120, 010 OF oDlgLeTxt  			PICTURE "@!"			PIXEL
		@ 032, 176 BUTTON "..." 			SIZE 013, 011 OF oDlgLeTxt 			PIXEL ;
	    				ACTION MV_PAR02:=cGetFile( "Arquivo TXT|*.TXT" , "Abrir arquivo", 1, "C:\", .T. , , .F. )
	    					
		@ 058, 128 bmpButton type 01 action close(oDlgLeTxt)
		@ 058, 158 bmpButton type 02 action (lRet:= .F.,close(oDlgLeTxt))
		Activate dialog oDlgLeTxt centered
		
		If !lRet
			Return .F.
		EndIf
		
		Mv_Par01 := dLanc
		
		/*If !Pergunte(cPerg,.T.)
			Return
		EndIf*/
   
		MV_PAR02 := AllTrim( MV_PAR02 )
   	
		If Empty( Mv_Par01 )
			Alert("Informar a Data de Lanηamento !")
			Loop
		EndIf

		If !File(MV_PAR02)
			Alert("Arquivo " + MV_PAR02 + " Nγo Encontrado !")
			Loop
		EndIf
		
		Exit //Sair do While
	Enddo

	//
	// MONTA ARRAY COM CABECALHOS DO GRID
	//
	AADD(aHeader,{"Linha"		 	,"CT2_LINHA"	,""	,TamSX3("CT2_LINHA")[1] ,0,"","ΗΗΗΗΗΗΗΗΗΗΗΗΗΗα","D","R"})
	AADD(aHeader,{"Data"			 	,"CT2_DATA"		,""	,TamSX3("CT2_DATA")[1]  ,0,"","ΗΗΗΗΗΗΗΗΗΗΗΗΗΗα","D","R"})
	AADD(aHeader,{"Conta"	    	,"B0H_CONTA"	,"@!"	,TamSX3("B0H_CONTA")[1] ,0,"","ΗΗΗΗΗΗΗΗΗΗΗΗΗΗα","C","R"})
	AADD(aHeader,{"Descricao"	 	,"B0H_DESCTA"	,"@!"	,TamSX3("B0H_DESCTA")[1],0,"","ΗΗΗΗΗΗΗΗΗΗΗΗΗΗα","C","R"})
	AADD(aHeader,{"Centro Custo"	,"CT2_CCD" 	   ,"@!"	,TamSX3("CT2_CCD")[1],0 ,"","ΗΗΗΗΗΗΗΗΗΗΗΗΗΗα","C","R"})
	AADD(aHeader,{"Valor Dιbito"	,"LinDeb","@E 999,999,999.99",17,2,"U_GZS17SL('D')","ΗΗΗΗΗΗΗΗΗΗΗΗΗΗα","N","R"})
	AADD(aHeader,{"Valor Crιdito"	,"LinCre","@E 999,999,999.99",17,2,"U_GZS17SL('C')","ΗΗΗΗΗΗΗΗΗΗΗΗΗΗα","N","R"})
	AADD(aHeader,{"Historico"		,"CT2_HIST","@!",40,0,"","ΗΗΗΗΗΗΗΗΗΗΗΗΗΗα","C","R"})
	
//--------------------- Inicio Importaηγo de Dados -----------------------------------------
	//Ler Arquivo de Dados
	Processa({||VerArqDados()})

	nTotDif := nTotDeb - nTotCre
//--------------------- Fim Importaηγo de Dados -----------------------------------------

	nOpcx := 6
	cTitulo := "Lanηamentos Contabeis com Layout"

	// aC[n,1] = Nome da Variavel Ex.:l.cClientelK
	// aC[n,2] = Array com coordenadas do Get [x,y], em
	// Windows estao em PIXEL
	// aC[n,3] = Titulo do Campo
	// aC[n,4] = Picture
	// aC[n,5] = Validacao
	// aC[n,6] = F3
	// aC[n,7] = Se campo e editavel .t. se nao .f.

	aC := {}

	// aR[n,1] = Nome da Variavel Ex.:l.cClientelK
	// aR[n,2] = Array com coordenadas do Get [x,y], em
	// Windows estao em PIXEL
	// aR[n,3] = Titulo do Campo
	// aR[n,4] = Picture
	// aR[n,5] = Validacao
	// aR[n,6] = F3
	// aR[n,7] = Se campo e editavel .t. se nao .f.

	aR := {}
	Aadd(aR,{"nTotDeb",{120,010},"Total Dιbito : "	, "@E 999,999,999.99",,,.F.})
	Aadd(aR,{"nTotCre",{120,150},"Total Crιdito :"	, "@E 999,999,999.99",,,.F.})
	Aadd(aR,{"nTotDif",{120,300},"Diferenηa Total :"	, "@E 999,999,999.99",,,.F.})

	aCGD:={34,5,100,315}
	
	cLinhaOk := "AllwaysTrue()"
	cTudoOk  := "U_GZS17GI()"
		
	If Len( aCols ) = 0
		Alert("Nγo Foi Encontrado Registros Vαlidos no Arquivo " + MV_PAR02 + " !")
		Return
	EndIf

	_lRet := U_ModIIGuazzelli(cTitulo,aC,aR,aCGD,nOpcx,cLinhaOk,cTudoOk,{"B0H_CONTA","CT2_CCD","LinDeb","LinCre","I2_HIST"},,,999,,.T.,,,,,"U_GZS17ITCALC()")
Return(_lRet)


/*/{Protheus.doc} GZS17GI
@author Fabiano Filla
@since 09/07/2013
@version 1.0
@return null,  
@description 
Funcao para validacao final e gravacao do lancamentos importados 
 
/*/
User Function GZS17GI()
	Local _iLinha, _iCount
	
	CT1->(DbSetOrder(1)) //Filial + Conta
		
	For _iLinha := 1 to Len(aCols)
		If !aCols[_iLinha, Len(aCols[1])]
			If aCols[_iLinha][_iPosDebVlr] > 0 .And. aCols[_iLinha][_iPosCreVlr] > 0
				Alert("Lanηamento Com Valor em Dιbito e Crιdito na Linha " + aCols[_iLinha][_iPosLinha] + ". Favor Corrigir!")
				Return(.F.)
			EndIf
			
			If aCols[_iLinha][_iPosDebVlr] = 0 .And. aCols[_iLinha][_iPosCreVlr] = 0
				Alert("Lanηamento Sem Valor em Dιbito e Crιdito na Linha " + aCols[_iLinha][_iPosLinha] + ". Favor Corrigir!")
				Return(.F.)
			EndIf

			If Empty(aCols[_iLinha][_iPosConta])
				Alert("Conta em Branco na Linha " + aCols[_iLinha][_iPosLinha] + ". Favor Corrigir!")
				Return(.F.)
			EndIf

			If !CT1->(DbSeek(xFilial("CT1")+aCols[_iLinha][_iPosConta],.F.))
				Alert("Nγo Encontrado a Conta " + AllTrim(aCols[_iLinha][_iPosConta]) + " na Linha " + aCols[_iLinha][_iPosLinha] + ". Favor Corrigir!")
				Return(.F.)
			EndIf
		EndIf
	Next
	
	nTotDeb	:= 0
	nTotCre	:= 0
	
	For _iCount := 1 To Len(aCols)
		If !aCols[_iCount, Len(aCols[_iCount])]
			nTotDeb += aCols[_iCount][_iPosDebVlr]
			nTotCre += aCols[_iCount][_iPosCreVlr]
		EndIf
	Next

	nTotDif := nTotDeb - nTotCre
	GetdRefresh()
	
	If nTotDif <> 0
		Alert("Existe Diferenηa Entre Dιbito e Crιdito. Impossνvel Gravar!")
		Return(.F.)
	EndIf
			
	Processa({|| GZS17ExAuto() })
	   
	MsgInfo("Gravaηγo Concluνda !")
	
Return(.T.)


/*/{Protheus.doc} GZS17ExAuto
@author Fabiano Filla
@since 09/07/2013
@version 1.0
@return null,  
@description Funcao para execucao do Exceauto CTBA102  

/*/
Static Function GZS17ExAuto()
	Local _iLinha
	Local _cLote := "008890", _cSubLote := "0001", _iCount

	CT2->(DbSetOrder(1)) //Filial + Dtos(CT2_DATA) + CT2_LOTE + CT2_SBLOTE + CT2_DOC
	For _iCount := 8890 To 999999
		If !CT2->(DbSeek(xFilial("CT2")+Dtos(Mv_Par01)+StrZero(_iCount,6),.F.))
			_cLote := StrZero(_iCount,6)
			Exit
		EndIf
	Next
	
	ProcRegua(0)
	
	Begin Transaction //Incio de Transaηγo

		aItens 	:= {}
		aCab 	:= { 	{'DDATALANC' ,Mv_Par01		,NIL},;
						{'CLOTE' 		,_cLote 			,NIL},;
						{'CSUBLOTE' 	,_cSubLote 		,NIL},;
						{'CDOC' 		,"0000000001" 	,NIL},;
						{'CPADRAO' 	,'' 				,NIL},;
						{'NTOTINF' 	,0 				,NIL},;
						{'NTOTINFLOT',0 				,NIL} }

		//Gravar dados
		For _iLinha := 1 to Len(aCols)

			IncProc("Gravando Movimentaηγo")

			If !aCols[_iLinha, Len(aCols[1])]
				If aCols[_iLinha][_iPosDebVlr] <> 0.00 //Debito
					aAdd(aItens,{	{'CT2_FILIAL'	,xFilial("CT2")   				, NIL},;
						{'CT2_LINHA'	,aCols[_iLinha][_iPosLinha]		, NIL},;
						{'CT2_MOEDLC'	,'01'   							, NIL},;
						{'CT2_DC'		,'1'   								, NIL},;
						{'CT2_DEBITO'	,aCols[_iLinha][_iPosConta] 		, NIL},;
						{'CT2_CCD'		,aCols[_iLinha][_iPosCC] 		, NIL},;
						{'CT2_VALOR'	,aCols[_iLinha][_iPosDebVlr]	, NIL},;
						{'CT2_ORIGEM'	,'GZSP0017'						, NIL},;
						{'CT2_HP'		,''   								, NIL},;
						{'CT2_HIST'	,aCols[_iLinha][_iPosHistor]	, NIL} } )
				EndIf
				If aCols[_iLinha][_iPosCreVlr] <> 0.00 //Credito
					aAdd(aItens,{  {'CT2_FILIAL'  ,xFilial("CT2")   				, NIL},;
						{'CT2_LINHA'  	,aCols[_iLinha][_iPosLinha]   , NIL},;
						{'CT2_MOEDLC'  ,'01'   								, NIL},;
						{'CT2_DC'   	,'2'   								, NIL},;
						{'CT2_CREDIT'  ,aCols[_iLinha][_iPosConta] 	, NIL},;
						{'CT2_CCC'		,aCols[_iLinha][_iPosCC] 	   , NIL},;
						{'CT2_VALOR'  	,aCols[_iLinha][_iPosCreVlr]  , NIL},;
						{'CT2_ORIGEM' 	,'GZSP0017'							, NIL},;
						{'CT2_HP'   	,''   								, NIL},;
						{'CT2_HIST'   	,aCols[_iLinha][_iPosHistor]	, NIL} } )
				EndIf
			EndIf
		Next
	
		DbSelectArea("CT2")
	
		Private lMsErroAuto := .F.
		MSExecAuto( {|X,Y,Z| CTBA102(X,Y,Z)} ,aCab ,aItens, 3)
	
		If lMsErroAuto
			DisarmTransaction()
			MostraErro()
			Return(.F.)
		EndIF

	End Transaction //Fim de Transaηγo
Return


/*/{Protheus.doc} Cancelar
@author Fabiano Filla
@since 09/07/2013
@version 1.0
@return null,  
@description Funcao para cancelamento da rotina 

/*/
Static Function Cancelar()
	Close(oDlg1)
	_lCancelar := .T.
Return


/*/{Protheus.doc} GZS17SL
@author Fabiano Filla
@since 09/07/2013
@version 1.0
@return null,  
@description Funcao para dos totais 

/*/
User Function GZS17SL(cColuna)
	If cColuna == "D"
		nTotDeb := ( nTotDeb - aCols[N][_iPosDebVlr] ) + M->LinDeb
	ElseIf cColuna == "C"
		nTotCre := ( nTotCre - aCols[N][_iPosCreVlr] ) + M->LinCre
	EndIf
	
	nTotDif := nTotDeb - nTotCre
Return(.T.)


/*/{Protheus.doc} VerPerg
@author Fabiano Filla
@since 09/07/2013
@version 1.0
@return null,  
@description Funcao para verificar/criar as perguntas 

/*/
Static Function VerPerg()
	SX1->(DbSetOrder(1))
	IF ! SX1->(DbSeek(cPerg+"01",.F.))
		RecLock("SX1",.T.)
		SX1->X1_GRUPO   := cPerg
		SX1->X1_ORDEM   := "01"
		SX1->X1_PERGUNT := "Data Lancamento    ?"
		SX1->X1_VARIAVL := "Mv_ch1"
		SX1->X1_TIPO    := "D"
		SX1->X1_TAMANHO := 8
		SX1->X1_DECIMAL := 0
		SX1->X1_GSC     := "G"
		SX1->X1_VAR01   := "Mv_Par01"
		SX1->X1_DEF01   := ""
		SX1->X1_DEF02   := ""
		SX1->X1_F3      := ""
		MsUnLock("SX1")
	EndIf
	IF ! SX1->(DbSeek(cPerg+"02",.F.))
		RecLock("SX1",.T.)
		SX1->X1_GRUPO   := cPerg
		SX1->X1_ORDEM   := "02"
		SX1->X1_PERGUNT := "Arquivo Orig. Dados?"
		SX1->X1_VARIAVL := "Mv_ch2"
		SX1->X1_TIPO    := "C"
		SX1->X1_TAMANHO := 99
		SX1->X1_DECIMAL := 0
		SX1->X1_GSC     := "G"
		SX1->X1_VAR01   := "Mv_Par02"
		SX1->X1_DEF01   := ""
		SX1->X1_DEF02   := ""
		SX1->X1_F3      := ""
		MsUnLock("SX1")
	EndIf
Return


/*/{Protheus.doc} ReadLn
@author Fabiano Filla
@since 09/07/2013
@version 1.0
@return null,  
@description Funcao para ler linha do arquivo da folha 

/*/
Static Function ReadLn(_nHandle)
	_cCaracter := " "
	_cVlrLinha := ""
   
	While .T.
		FRead(_nHandle, @_cCaracter, 1)
		If ( !_cCaracter == Chr(10) ) .And. ( !_cCaracter == "" )
			_cVlrLinha += _cCaracter
		Else
			Exit
		EndIf
	Enddo
Return(_cVlrLinha)


/*/{Protheus.doc} VerArqDados
@author Fabiano Filla
@since 09/07/2013
@version 1.0
@return null,  
@description Funcao para ler arquivo da folha 

/*/
Static Function VerArqDados()
	Local _aErro
	Local _aSemConta := {}
			
	ProcRegua(0)
 	
	_nHdImpEst := Fopen(Mv_Par02)
	If FERROR() <> 0
		Alert("Erro Na Leitura do Arquivo " + MV_PAR02 + " !")
		Return
	End
   
	CT1->(DbSetOrder(2)) //Filial + RES
	CTT->(DBOrderNickName("GZS001")) //Filial + CCEBS

	_aErro  	:= {}
	_cLinha 	:= ReadLn(_nHdImpEst)
	_iLinha 	:= 1
	_iSemCtDb:= 0
	While !Empty(_cLinha)
		_aLinha		:= StrTokArr( _cLinha, "|" )
		_nZerosCD	:= TamSX3("CT1_RES")[1] - Len(_aLinha[3])
		_nZerosCC	:= TamSX3("CT1_RES")[1] - Len(_aLinha[4])
		_cCTDebito	:= _aLinha[3] + Space( TamSX3("CT1_RES")[1] - Len(_aLinha[3]) ) //SubStr(_cLinha,12,5)+Space(TamSX3("CT1_RES")[1]-5)
		_cCTCredito	:= _aLinha[4] + Space( TamSX3("CT1_RES")[1] - Len(_aLinha[4]) ) //SubStr(_cLinha,18,5)+Space(TamSX3("CT1_RES")[1]-5)
		_nValor		:= Val( _aLinha[5] )
		_cCC		:= Alltrim(Str( Val(_aLinha[8]) )) + Space( TamSX3("CTT_CCEBS")[1] - Len( Alltrim( Str( Val(_aLinha[8]) ) ) ) )
		_cHistorico	:= Alltrim( SubStr( _aLinha[7], 2, 50) )
		_lCtDebito	:= .T.
		_lCtCredito	:= .T.
		_lCC		:= .T.
		
		_lCC := CTT->( DbSeek( xFilial("CTT") + _cCC, .F. ) )

		If CT1->( DbSeek( xFilial("CT1") + Replicate('0',_nZerosCD) + _cCTDebito, .F. ) ) .Or. (SubStr(_cCTDebito,1,5) == '00000' .And. SubStr(_cCTCredito,1,5) == '00000' .And. _iSemCtDb == 0)
			If _lCC
				AADD(aCols, { StrZero(len(aCols)+1, TamSX3("CT2_LINHA")[1] ), ;
					Mv_Par01, ;
					Iif( _cCTDebito == "00000", Space( TamSX3("CT1_CONTA")[1]), CT1->CT1_CONTA ), ;
					Iif( _cCTDebito == "00000", "", CT1->CT1_DESC01), ;
					CTT->CTT_CUSTO, ;
					_nValor, ;
					0, ;
					_cHistorico, ;
					.F. } )
		 		         
				nTotCre 	+= _nValor
				_iSemCtDb   := 1
			EndIf
		ElseIf ! _cCTDebito == '00000'
			_lCtDebito	:= .F.
		EndIf
	   
		If CT1->( DbSeek( xFilial("CT1") + Replicate('0',_nZerosCC) + _cCTCredito, .F. ) ) .Or. ( _cCTDebito == '00000' .And. _cCTCredito == '00000' .And. _iSemCtDb == 2)
			If _lCC
				AADD(aCols, {StrZero(len(aCols)+1, TamSX3("CT2_LINHA")[1]), ;
					Mv_Par01, ;
					Iif( _cCTCredito == "00000", Space(TamSX3("CT1_CONTA")[1]),CT1->CT1_CONTA), ;
					Iif( _cCTCredito == "00000", "", CT1->CT1_DESC01), ;
					CTT->CTT_CUSTO, ;
					0,;
					_nValor, ;
					_cHistorico, ;
					.F.})
			 					 
				nTotDeb 	+= _nValor
				_iSemCtDb   := 0
			EndIf
		ElseIf ! _cCTCredito == '00000'
			_lCtCredito := .F.
		ElseIf _iSemCtDb = 1
			_iSemCtDb   := 2
		EndIf
			   
		If ! _lCC
			Aadd(_aErro, { _iLinha, "T", _cCC, _nValor  } )
		EndIf

		If ( ! _cCTDebito == "00000" ) .And. ( ! _lCTDebito )
			Aadd(_aErro,{  _iLinha, "D", _cCTDebito, _nValor } )
		EndIf
   
		If ( ! _cCTCredito == "00000" ) .And. ( ! _lCTCredito )
			Aadd(_aErro, { _iLinha, "C", _cCTCredito, _nValor } )
		EndIf

	   //Ler prσxima linha 
		_cLinha := ReadLn(_nHdImpEst)
		_iLinha += 1
		IncProc()
	Enddo
	Fclose(_nHdImpEst)
	
	If Len( _aErro ) > 0
		RelErro(_aErro)
	EndIF
	
Return


/*/{Protheus.doc} RelErro
@author Fabiano Filla
@since 09/07/2013
@version 1.0
@return null,  
@description
Funcao para gerar relatorio de erros na importacao do arquivo da folha 
/*/
Static Function RelErro(_aErros)
	Local _iCount
	Private _aErros
	//ΪΔΔΔΔΔΔΔΔΔΔΔΔΔΔΔΔΔΔΔΔΔΔΔΔΔΔΔΔΔΔΔΔΔΔΔΔΔΔΔΔΔΔΔΔΔΔΔΔΔΔΔΔΔΔΔΔΔΔΔΔΔΔΔΔΔΔΔΔΔΏ
	//³ Variaveis                                                           ³
	//ΐΔΔΔΔΔΔΔΔΔΔΔΔΔΔΔΔΔΔΔΔΔΔΔΔΔΔΔΔΔΔΔΔΔΔΔΔΔΔΔΔΔΔΔΔΔΔΔΔΔΔΔΔΔΔΔΔΔΔΔΔΔΔΔΔΔΔΔΔΔΩ

	wnrel	:= ""
	nOrdem  := ""
	tamanho := "P"
	limite  := 80
	titulo  := "Lista de Erros na Importaηγo da Folha"
	cDesc1  := "RELERRO"
	cDesc2  := ""
	cDesc3  := ""
	nomeprog:= "RELERRO"
	cString := "SB1"
	cMoeda  := ""
	cPerg   := "RELERRO"
	aReturn := { "Especial", 1,"Administracao", 1, 2, 1,"",1 }
	nLastKey:= 0
	wnrel   := "RELERRO"+Space(3)
	m_pag   := 1
	wnrel:=SetPrint(cString,wnrel,cPerg,Titulo,cDesc1,cDesc2,cDesc3,.T.,,,,,.F.)

	If ( nLastKey == 27 .Or. LastKey() == 27 )
		Return(.F.)
	EndIf

	SetDefault(aReturn,cString)
	nTipo := IIF(aReturn[4]==1,15,18)

	If ( nLastKey == 27 .Or. LastKey() == 27 )
		Return(.F.)
	EndIf
	
	Cabec1 := " LINHA PROBLEMA                             CONTA                          VALOR"
//LINHA PROBLEMA                             CONTA                          VALOR
//00001 12345678901234567890123456789012345  12345678901234567890  999,999,999.99
//1     7                                    44                    66
	Cabec2 := ""
   
	For _iCount := 1 To Len( _aErros )
	
		If pRow() > 60 .Or. _iCount  == 1
			Cabec(titulo,cabec1,cabec2,nomeprog,tamanho,nTipo)
		EndIf

		@ pRow()+1, 001 pSay StrZero(_aErros[_iCount,1],4)
  
		If _aErros[_iCount,2]=="D"
			@ pRow()  , 007 pSay "Conta Debito Inexistente"
		ElseIf _aErros[_iCount,2]=="C"
			@ pRow()  , 007 pSay "Conta Credito Inexistente"
		ElseIf _aErros[_iCount,2]=="T"
			@ pRow()  , 007 pSay "Centro de Custo Inexistente"
		Else
			@ pRow()  , 007 pSay "Sem Conta Credito ou Debito"
		EndIf
		
		@ pRow()  , 044 pSay _aErros[_iCount,3]
		@ pRow()  , 066 pSay Trans(_aErros[_iCount,4],"@E 999,999,999.99")
	Next

	Set Device To Screen

	If aReturn[5] == 1
		Set Printer TO
		dbcommitAll()
		ourspool(wnrel)
	Endif

	MS_FLUSH()
Return


/*/{Protheus.doc} GZS17ITCALC
@author Fabiano Filla
@since 09/07/2013
@version 1.0
@return null,  
@description
Funcao para calcular Total do aCols 

/*/
User Function GZS17ITCALC()
	Local _iCount
	
	nTotDeb	:= 0
	nTotCre	:= 0
	
	For _iCount := 1 To Len(aCols)
		If !aCols[_iCount, Len(aCols[_iCount])]
			nTotDeb += aCols[_iCount][_iPosDebVlr]
			nTotCre += aCols[_iCount][_iPosCreVlr]
		EndIf
	Next
	
	nTotDif := nTotDeb - nTotCre
	GetdRefresh()
Return(.T.)


/*/{Protheus.doc} UPDZ0017
@author Aridnei do Carmo
@since 22/10/2014
@version 1.0
@return null,  
@description
Programa compatibilizador para atualizacao do Dicionαrio com customizacoes Guazzelli

@example
Programa: U_UPDZ0017
Array
[1] - Tabela SX2
[2] - Campos SX3
[3] - Indices SIX
[4] - Parametros SX6

/*/
User Function UPDZ0017( lModo )
	Local aSX2 := {}
	Local aSX3 := {}
	Local aSIX := {}
	Local aSX6 := {}
	Local aSXB := {}
	Local aSX7 := {}
	Local aRet := {}
	Local cPath
	Local cNome
	
	If !lModo .OR. lModo == NIL
		Return "Importacao Folha de Pagamento p/ EBS"
	Endif
	
	dbSelectArea("SX2")
	SX2->(DbSetOrder(1))
	MsSeek("SC5")
	cPath := SX2->X2_PATH
	cNome := Substr(SX2->X2_ARQUIVO,4,5)
	
	// Campos para SX3
	Aadd(aSX3,{"CTT",;			//Arquivo
	"",;						//Ordem
	"CTT_CCEBS",;				//Campo
	"C",;						//Tipo
	6,;							//Tamanho
	0,;							//Decimal
	"CC EBS",;					//Titulo
	"CC EBS",;					//Titulo SPA
	"CC EBS",;					//Titulo ENG
	"Centro Custo EBS",;		//Descricao
	"Centro Custo EBS",;		//Descricao SPA
	"Centro Custo EBS",;		//Descricao ENG
	"@!",;						//Picture
	"",;						//VALID
	X3_USADO_EMUSO,;			//USADO
	"",;						//RELACAO
	"",;						//F3
	1,;							//NIVEL
	X3_NAOOBRIGAT,;				//RESERV
	"",;						//CHECK
	"",;						//TRIGGER
	"U",;						//PROPRI
	"N",;						//BROWSE
	"A",;						//VISUAL
	"R",;						//CONTEXT
	"",;						//OBRIGAT
	"",;						//VLDUSER
	"",;						//CBOX
	"",;						//CBOX SPA
	"",;						//CBOX ENG
	"",;						//PICTVAR
	"",;						//WHEN
	"",;						//INIBRW
	"",;						//SXG
	"",;						//FOLDER
	""})						//PYME
	
	
	Aadd( aRet, aSX2 ) // Indice 1
	Aadd( aRet, aSX3 ) // Indice 2
	Aadd( aRet, aSIX ) // Indice 3
	Aadd( aRet, aSX6 ) // Indice 4
	Aadd( aRet, aSXB ) // Indice 5
	Aadd( aRet, aSX7 ) // Indice 6

Return aRet