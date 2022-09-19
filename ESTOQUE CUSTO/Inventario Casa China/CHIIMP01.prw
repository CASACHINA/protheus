#Include 'Protheus.ch'
#include "fileio.ch"
#include "tbiconn.ch"

/*/{Protheus.doc} CHIIMP01
//TODO Rotina criada para importação dos registros de inventario na SB7 e processamento de inventario.
@author Emerson
@since 17/03/2022
@version undefined

@type function
/*/

User Function CHIIMP01()
	Local oGetAD    
	local oDlg
	local cGetAD
	Local aOpc		:= {}
	Local oComboBox
	
	Private cLocal	:= '   '
	Private cOpcao
	Private cCnt := 0
	Private cCntErr := 0
	
	aAdd(aOpc , "S=SIM")
	aAdd(aOpc , "N=NÃO")
	
	private cCaminho  := space(100)
	                                                    
	DEFINE MSDIALOG oDlg FROM 000,000  TO 180,400 TITLE "Selecione o Arquivo:" Pixel
	@ 008, 004 SAY "Esta rotina tem como objetivo importar os produtos de um arquivo CSV." SIZE 280,010 OF oDlg PIXEL
	@ 028, 004 MSGET oGetAD VAR cGetAD  WHEN .t. SIZE 100, 010 OF oDlg PIXEL HASBUTTON
	@ 028 ,105 BUTTON "Selecione o Arquivo" SIZE 065,010  FONT oDlg:oFont ACTION( validaArq(@cGetAd))  OF oDlg PIXEL   

	@ 048, 004 SAY "Zerar itens não digitados?" SIZE 280,010 OF oDlg PIXEL  
	@ 048, 74 MSCOMBOBOX oComboBox VAR cOpcao ITEMS aOpc SIZE 040,10 OF oDlg PIXEL

	@ 049, 124 SAY "Local?" SIZE 280,010 OF oDlg PIXEL  
	@ 048, 144 MSGET oGetAD VAR cLocal  WHEN .t. SIZE 020, 010 F3 "NNR" OF oDlg PIXEL

	@ 065 ,030   BUTTON "Importar" SIZE 065,010  FONT oDlg:oFont ACTION ( !EMPTY(cGetAd) .AND.  Processa({||procArq(@cGetAd) },"Importando Lançamentos...") , oDlg:End() )  OF oDlg PIXEL
	@ 065 ,100   BUTTON "Cancelar" SIZE 065,010  FONT oDlg:oFont ACTION oDlg:End()  OF oDlg PIXEL
	
	ACTIVATE MSDIALOG oDlg CENTERED
	
Return


/*/{Protheus.doc} validaArq
//TODO Função para validar existencia do arquivo selecionado.
@author Emerson
@since 17/03/2022
@version undefined
@param cGetAd, characters, descricao
@type function
/*/
Static Function validaArq(cGetAd)  

	Private cCaminho := ""    
	
	cGetAd:= cGetFile( '*.csv', "Selecione o Arquivo",,cCaminho,.T., )
	
	IF(Empty(cGetAd))   
		RETURN .F.
	ENDIF  
	
	If !File(cGetAd)
		Alert("Arquivo Não Encontrado !!!")
		Return .f.
	Endif   

Return .t.         

/*/{Protheus.doc} procArq
//TODO Função para realizar o processamento do .CSV e gerar os registros na SB7 via execauto
@author Emerson
@since 17/03/2022
@version undefined
@param cGetAd, characters, descricao
@type function
/*/
static function procArq(cGetAd)                          
	Local nHandle
	Local cLinha
	local aLinha
    Local aSb7			:= {}	
    
	Local aProds		:= {}
	Local lErro 		:= .F.
	Local lAdd			:= .T.
	Local nPrima		:= 1
	Local _cDir			:= "C:\TEMP\INVENTARIO"
    
    Private cDoc			:= GetSx8Num("SB7","B7_DOC")
    private lMsErroAuto 	:= .F.
    PRIVATE lAutoErrNoFile 	:= .T.
        
	nHandle := FT_FUSE(cGetAd)
	
	If nHandle < 0	
		Return .F.
	Endif
	
	WriteLog(" Inicio Importação CSV inventário")
	
	procregua(nHandle)
	
	FT_FGOTOP()
	
	DO while !FT_FEOF()
		//Contas a quantidade de linhas
		cLinha  := FT_FREADLN()
		aLinha	:= StrTokArr(cLinha,";") //Tranforma em array  
		lAdd	:= .T.
		nPrima++//Pula cabeçalho
	    //Verifica se tem pelo menos 2 posições preenchidas
		IF(LEN(aLinha) > 1 .AND. !EMPTY(aLinha[1]) ) .AND. nPrima > 2
			incproc("Pre-validação produto " + ALLTRIM(aLinha[1]))
			SB1->(DbSetOrder(1))
			If SB1->(MsSeek(xFilial("SB1")+ALLTRIM(aLinha[1])))
				If SB1->B1_MSBLQL == '1'
					lAdd	:= .F.
					WriteLog(" Produto BLOQUEADO: " + ALLTRIM(aLinha[1]),3)
				EndIf
		    Else
		     	WriteLog(" Produto: " + ALLTRIM(aLinha[1]) + " não localizado na base de dados",3)
		     	lAdd	:= .F.
		    EndIf
		   
		    //Adiciona item para processamento.	
		    If lAdd
		    	aSb7 := {;
			            {"B7_FILIAL" , xFilial("SB7")							,Nil},;
			            {"B7_COD"	 ,ALLTRIM(aLinha[1])			   			,Nil},; // Deve ter o tamanho exato do campo B7_COD, pois faz parte da chave do indice 1 da SB7
			            {"B7_DOC"    ,cDoc							 			,Nil},;
			            {"B7_QUANT"  ,Val(StrTran(aLinha[2],',','.'))			,Nil},;
			            {"B7_LOCAL"  ,cLocal									,Nil},; // Deve ter o tamanho exato do campo B7_LOCAL, pois faz parte da chave do indice 1 da SB7
			            {"B7_DATA"   ,dDataBase									,Nil} } // Deve ter o tamanho exato do campo B7_DATA, pois faz parte da chave do indice 1 da SB7
		    	
		    	aAdd(aProds,aSb7)
		    Else
		    	lErro := .T. // Marca para não processar
		    EndIf	        	   	
		ENDIF
		FT_FSKIP()  
	enddo  
	
	FT_FUSE()
	
	//Não teve erros nos registros?
	If lErro .AND. MsgYesNo("O sistema encontrou problemas em itens da planilha, o aqruivo de log foi salvo em: C:\TEMP\INVENTARIO. Deseja continuar? " , "ERRO")
		lErro := .F.
	EndIF

	if !lErro
		IF Executa(aProds) .AND. cOpcao == 'S'
			IF SELECT("QSB7") != 0
				QSB7->(dbCloseArea())
			EndIF

			aProds := {}
			BeginSql Alias "QSB7"
				SELECT B2_COD, B2_QEMP+B2_RESERVA EMPENHO FROM %Table:SB2% B2
				WHERE B2_LOCAL = %Exp:cLocal%
				AND B2_QATU-B2_QEMP-B2_RESERVA > 0 
				AND B2_FILIAL = %xFilial:SB2%
				AND NOT EXISTS (
				SELECT B7_COD FROM 
				%Table:SB7% B7
				WHERE B7_FILIAL = %xFilial:SB7%
				AND B7_DATA = %Exp:dDataBase%
				AND B7_COD = B2_COD
				AND B7_LOCAL = B2_LOCAL
				AND B7.D_E_L_E_T_ = ' '
				)
				AND B2.D_E_L_E_T_ = ' '
			ENDSQL

			WHILE QSB7->(!Eof())
				lAdd	:= .T.
				incproc("Pre-validação produto " + ALLTRIM(QSB7->B2_COD))
				SB1->(DbSetOrder(1))
				If SB1->(MsSeek(xFilial("SB1")+ALLTRIM(QSB7->B2_COD)))
					If SB1->B1_MSBLQL == '1'
						lAdd	:= .F.
						WriteLog(" Produto BLOQUEADO: " + ALLTRIM(QSB7->B2_COD),3)
					EndIf
				Else
					WriteLog(" Produto: " + ALLTRIM(QSB7->B2_COD) + " não localizado na base de dados",3)
					lAdd	:= .F.
				EndIf
			
				//Adiciona item para processamento.	
				If lAdd
					aSb7 := {;
							{"B7_FILIAL" , xFilial("SB7")		,Nil},;
							{"B7_COD"	 ,QSB7->B2_COD			,Nil},; // Deve ter o tamanho exato do campo B7_COD, pois faz parte da chave do indice 1 da SB7
							{"B7_DOC"    ,cDoc					,Nil},;
							{"B7_QUANT"  ,QSB7->EMPENHO			,Nil},;
							{"B7_LOCAL"  ,cLocal				,Nil},; // Deve ter o tamanho exato do campo B7_LOCAL, pois faz parte da chave do indice 1 da SB7
							{"B7_DATA"   ,dDataBase				,Nil} } // Deve ter o tamanho exato do campo B7_DATA, pois faz parte da chave do indice 1 da SB7
					aAdd(aProds,aSb7)
				eNDif
				QSB7->(DbSkip())
			EndDo
			//Tem registros? 
			if len(aProds) > 0
				Executa(aProds)
			EndIF
		EndIf
	Else
		Alert ("Divergências encontradas na pre-validação dos itens, para maiores detalhes consultar pasta de log em '"+_cDir+"\CHECK\'")
	EndIf
	//Tem registros para serem processados?
	If cCnt > 0
		WriteLog(" Inicio processamento de inventário")
		//Chama função para processar inventario
		incproc("Processando inventário " + cDoc )
	    IF Aviso("Registro de inventário: " + cDoc , "Documento: " + cDoc + CHR(10) + AllTrim(STR(cCnt)) + " produtos incluídos com sucesso!" + CHR(10) + AllTrim(STR(cCntErr)) + " produtos não foram incluídos!" + CHR(10) + CHR(10) + "Para maiores detalhes consultar pasta de log em '"+_cDir+"\ERRO\' "+ CHR(10) + CHR(10) + "Deseja processar o acerto de inventário agora? ",{"SIM","NÃO"},3) == 1
	    	//Realizado o processo do inventario
	    	procinv(cDoc)
	    	WriteLog(" Fim processamento de inventário")
	    Else
	    	WriteLog(" **Fim processamento de inventário - Cancelado pelo usuário!")
	    EndIF
	    ConfirmSx8()
	Else
		RollbackSx8()
		Alert ("Não houve produtos registrados, verificar itens no arquivo CSV!")
	EndIf
	
	WriteLog(" Fim Importação CSV inventário")
return          

/*/{Protheus.doc} procinv
//TODO Rotina que realizado a chamado na função padrão para processamento do inventario
@author Emerson
@since 17/03/2022
@version undefined
@param cCodInv, characters, descricao
@type function
/*/
Static Function procinv(cCodInv)
	Local lRet 	:= .F.
	Local lOk 	:= .T.
	
	SB7->(DbSetOrder(3))
	//Verifica se inventario foi gerado
	If !SB7->(MsSeek(xFilial("SB7")+cCodInv))	
		lOk := .F.	
		WriteLog("Cadastrar inventário: "+cCodInv)
		SB7->(DbGoTop())
	EndIf
	
	if lOk
		//Grava logs
		WriteLog(" Documento de inventário: "+cCodInv)
		WriteLog(" Hora Inicio: "+Time())
		//Acerta as perguntas com o documento de inventario gerado no processamento
		zAtuPerg("MTA340", "mv_par01", date())
		zAtuPerg("MTA340", "mv_par05", '               ')
		zAtuPerg("MTA340", "mv_par06", 'ZZZZZZZZZZZZZZZ')
		zAtuPerg("MTA340", "mv_par07", '  ')
		zAtuPerg("MTA340", "mv_par08", 'ZZ')
		zAtuPerg("MTA340", "mv_par09", '    ')
		zAtuPerg("MTA340", "mv_par10", 'ZZZZ')
		zAtuPerg("MTA340", "mv_par11", cCodInv)
		zAtuPerg("MTA340", "mv_par12", cCodInv)
		
		//Chama função padrão para executar o acerto de inventario
		MATA340()
		//Grava logs
		WriteLog(" Hora Fim  : "+Time())
	EndIf
	
Return lRet     

/*/{Protheus.doc} WriteLog
//TODO Função para salvar os LOG
@author Emerson
@since 17/03/2022
@version undefined
@param cText, characters, descricao
@param cErro, characters, descricao
@type function
/*/
Static Function WriteLog(cText,nOper)
	
	Local cFileLog 	:= ""
	Local nAux		 
	Local _Arqv		:= "TCPIMP01" 
	Local _cDir		:= "C:\TEMP\INVENTARIO"
	
	//Erro?
	If nOper == 2
		_cDir	:= _cDir+"\ERRO\"
		_Arqv	:= "ERRO-"+_Arqv
	ElseIf nOper == 3
		_cDir	:= _cDir+"\CHECK\"
		_Arqv	:= "CHK-"+_Arqv
	Else
		_cDir	:= _cDir+"\IMPORTACAO\"
		_Arqv	:= "IMP-"+_Arqv
	EndIf
	
	cFileLog += _cDir
	//Inclui as pastas
	montaDir(_cDir)
	
	MakeDir(cFileLog)	                                                                                        
	
	//Apagar o log do dia posterior
	Ferase(cFileLog + _Arqv + cEmpAnt + cFilAnt + "-"+ AllTrim( DtoS(Date()+1) ) + ".LOG")
	cFileLog += _Arqv + cEmpAnt + cFilAnt + "-" +AllTrim( DtoS(Date()) ) + ".LOG"
	
	If File(cFileLog)
		nAux := fOpen(cFileLog, FO_READWRITE+FO_SHARED)		
	Else
		nAux := fCreate(cFileLog,0)
	EndIf
	
	If nAux != -1
	   	FSeek(nAux,0,2)
		FWrite(nAux, AllTrim(DtoS(Date())) + " | " + TIME() + " | " + cText + CRLF)
		FClose(nAux)
	EndIf
	
Return NIL

/*/{Protheus.doc} zAtuPerg
//TODO Função utilizada para gravar as perguntas padrões utilizadas no processamento do inventario
@author Emerson
@since 17/03/2022
@version undefined
@param cPergAux, characters, descricao
@param cParAux, characters, descricao
@param xConteud, , descricao
@type function
/*/
Static Function zAtuPerg(cPergAux, cParAux, xConteud)
	Local aArea      := GetArea()
	Local nPosPar    := 14
	Local nLinEncont := 0
	Local aPergAux   := {}
	Default xConteud := ''
	
	//Se não tiver pergunta, ou não tiver ordem
	If Empty(cPergAux) .Or. Empty(cParAux)
		Return
	EndIf
	
	//Chama a pergunta em memória
	Pergunte(cPergAux, .F., /*cTitle*/, /*lOnlyView*/, /*oDlg*/, /*lUseProf*/, @aPergAux)
	
	//Procura a posição do MV_PAR
	nLinEncont := aScan(aPergAux, {|x| Upper(Alltrim(x[nPosPar])) == Upper(cParAux) })
	
	//Se encontrou o parâmetro
	If nLinEncont > 0
		//Caracter
		If ValType(xConteud) == 'C'
			&(cParAux+" := '"+xConteud+"'")
		
		//Data
		ElseIf ValType(xConteud) == 'D'
			&(cParAux+" := sToD('"+dToS(xConteud)+"')")
			
		//Numérico ou Lógico
		ElseIf ValType(xConteud) == 'N' .Or. ValType(xConteud) == 'L'
			&(cParAux+" := "+cValToChar(xConteud)+"")
		
		EndIf
		
		//Chama a rotina para salvar os parâmetros
		__SaveParam(cPergAux, aPergAux)
	EndIf
	
	RestArea(aArea)
Return

Static Function Executa(aProds)
	Local nI 		:= 0
	Local nX 		:= 0
	Local aErro		:= {} 
	Local cErro	  	:= ""	
	Local cMsgErro	:= ''
	Local lRet		:= .F.

	//Roda execauto
	For nI := 1 To Len(aProds)
		incproc("Incluindo produto " + aProds[nI][2][2] )
		//Chama execauto para incluir registro de inventario
		MSExecAuto({|x,y,z| mata270(x,y,z)},aProds[nI],.T.,3)
		//Não conseguiu gerar?
		If lMsErroAuto
			//MostraErro()
			cMsgErro := ""
			aErro := GetAutoGRLog()
			//Lê mensagem erro array
			For nX := 1 To Len(aErro)
				//Grava linha na variavel
				cErro += aErro[nX] + Chr(13)+Chr(10)
				//Contem Invalido?
				IF "Invalido" $ aErro[nX]
					//Mensagem que vai para API
					cMsgErro += "Invalido - "+ aErro[nX]
				EndIf
			Next nX
			//Grava erro em arquivo log
			WriteLog(" **ERRO SB7 Produto: " + aProds[nI][2][2] + " " + cMsgErro )
			//Grava Error.log em outra pasta
			WriteLog(" ERRO SB7 Produto: " + aProds[nI][2][2] +  Chr(13) + cErro, 2 )
			//Conta erros
			cCntErr++
		else
			lRet := .T. //Gerou pelo menos 1 registro?
			cCnt++
		EndIf
		lMsErroAuto := .F.
	Next nI 

Return lRet
