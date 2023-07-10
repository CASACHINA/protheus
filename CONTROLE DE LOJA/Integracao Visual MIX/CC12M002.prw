#INCLUDE "PROTHEUS.CH"
#INCLUDE "TOPCONN.CH"

/*/{Protheus.doc} CC12M002
Funcao que executa a Integracao dos Dados com o Visual MIX - Retorno dos Dados.
@author 	Ricardo Tavares Ferreira
@since 		16/05/2018
@version 	12.1.17
@return 	Logico
@Obs 		Ricardo Tavares - Construcao Inicial
/*/
//==========================================================================================================
	User Function CC12M002()
//==========================================================================================================
	
	Local aRet 			:= {}
	Local aDados 		:= {}
	Local lExiste		:= .F.
	Private cNmFonte	:= FunName()
	Private nRpl		:= 150
	Private aSL1		:= {}
	Private aSL2		:= {}
	Private aSL4		:= {}
	Private aCab 		:= {} //Array do Cabeçalho do Orçamento
	Private aItem 		:= {} //Array dos Itens do Orçamento
	Private aParcelas 	:= {} //Array das Parcelas do Orçamento
	
	aRet 	:= GET_VALID()
	lExiste := aRet[1]
	aDados	:= aRet[2]
	
	If lExiste
		If aDados[1][1] == cNmFonte
			If Stod(SubStr(aDados[1][4],5,4)+SubStr(aDados[1][4],3,2)+SubStr(aDados[1][4],1,2)) > Date()
				VAL_AMB()
			Else
				////Aviso("Atencao","A Chave de Acesso Expirada",{"Fechar"},1)
				//conout(Replicate("-",nRpl))
				//conout("[CC12M002]  [" + Dtoc(DATE()) +" "+ Time()+ "]  Chave de Acesso Expirada... Procure a GAO TECNOLOGIA para geracao de uma nova chave...")
				//conout(Replicate("-",nRpl))			
			EndIf
		Else
			//Aviso("Atencao","A Chave de Acesso Encontrada nao Faz Parte desse Codigo Fonte. Coloque a chave correta no diretorio correto.",{"Fechar"},1)
			//conout(Replicate("-",nRpl))
			//conout("[CC12M002]  [" + Dtoc(DATE()) +" "+ Time()+ "]  A Chave de Acesso Encontrada nao Faz Parte desse Codigo Fonte...")
			//conout(Replicate("-",nRpl))		
		EndIf
	Else
		//Aviso("Atencao","Chave de Acesso Invalida ou nao Encontrada.",{"Fechar"},1)
		//conout(Replicate("-",nRpl))
		//conout("[CC12M002]  [" + Dtoc(DATE()) +" "+ Time()+ "]  Chave de Acesso Invalida ou nao Encontrada...")
		//conout(Replicate("-",nRpl))
	EndIf

Return

/*/{Protheus.doc} VAL_AMB
Funcao que valida de o Ambiente esta Exclusivo para execucao via JOB.
@author 	Ricardo Tavares Ferreira
@since 		16/05/2018
@version 	12.1.17
@return 	Logico
@Obs 		Ricardo Tavares - Construcao Inicial
/*/
//==========================================================================================================
	Static Function VAL_AMB()
//==========================================================================================================
	
//	Local lPrepEnv 	:= Empty(Select("SM0"))
	
	//If lPrepEnv
	//	RpcSetType(3)
	//	RpcSetEnv(cEmpAnt,cFilAnt)//Prepare Environment Empresa "01" Filial "01"
		PROC_INT()
	//Endif

Return

/*/{Protheus.doc} PROC_INT 
Função responsavel por processar a integracao
@author 	Ricardo Tavares Ferreira
@since 		16/05/2018
@version 	12.1.17
@return 	Logico
@Obs 		Ricardo Tavares - Construcao Inicial
/*/
//==========================================================================================================
	Static Function PROC_INT()
//==========================================================================================================
	
	Local nHandle 	:= 0
	Local nX		:= 0
	Local nConnERP	:= AdvConnection()
	
	nHandle := GET_CONN()
	
	If nHandle >= 0
		//Aviso("Atencao","Conexao com o Banco de Dados VM_INTEGRACAO realizada com sucesso.",{"Fechar"},1)
		//conout(Replicate("-",nRpl))
		//conout("[CC12M002][PROC_INT]  [" + Dtoc(DATE()) +" "+ Time()+ "]  Conexao com o Banco de Dados VM_INTEGRACAO Realizada com Sucesso ...")
		//conout(Replicate("-",nRpl))
		
		VMIX_SL1()
		
	Else
		//Aviso("Atencao","Nao foi possivel realizar a conexao com o banco de dados VM_INTEGRACAO.",{"Fechar"},1)
		//conout(Replicate("-",nRpl))
		//conout("[CC12M002][PROC_INT]  [" + Dtoc(DATE()) +" "+ Time()+ "]  Nao foi possivel realizar a conexao com o banco de dados VM_INTEGRACAO ...")
		//conout(Replicate("-",nRpl))
	EndIf
	
	If TCUnlink(nHandle)
		//Aviso("Atencao","Conexao com o Banco de Dados VM_INTEGRACAO finalizada com sucesso.",{"Fechar"},1)
		//conout(Replicate("-",nRpl))
		//conout("[CC12M002][PROC_INT]  [" + Dtoc(DATE()) +" "+ Time()+ "]  Conexao com o Banco de Dados VM_INTEGRACAO finalizada com sucesso ...")
		//conout(Replicate("-",nRpl))
		
		If TCSetConn(nConnERP)
			//Aviso("Atencao","Conexao com o Banco de Dados do Protheus Reestabelecida.",{"Fechar"},1)
			//conout(Replicate("-",nRpl))
			//conout("[CC12M002][PROC_INT]  [" + Dtoc(DATE()) +" "+ Time()+ "]  Conexao com o Banco de Dados do Protheus Reestabelecida ...")
			//conout(Replicate("-",nRpl))
			
			SET_TABS() // Função Responsavel por popular os dados nas tabelas temporarias criadas
			PROT_SL1() // Função responsavel por executar o exectauto de criação das vendas no modulo loja.
		Else
			//Aviso("Atencao","Falha ao Reestabelecer a conexao com o Banco de Dados do Protheus.",{"Fechar"},1)
			//conout(Replicate("-",nRpl))
			//conout("[CC12M002][PROC_INT]  [" + Dtoc(DATE()) +" "+ Time()+ "]  Falha ao Reestabelecer a conexao com o Banco de Dados do Protheus ...")
			//conout(Replicate("-",nRpl))
		EndIf
		
	Else
		//Aviso("Atencao","Falha ao finalizar a conexao com o Banco de Dados VM_INTEGRACAO.",{"Fechar"},1)
		//conout(Replicate("-",nRpl))
		//conout("[CC12M002][PROC_INT]  [" + Dtoc(DATE()) +" "+ Time()+ "]  Falha ao finalizar a conexao com o Banco de Dados VM_INTEGRACAO ...")
		//conout(Replicate("-",nRpl))	
	EndIf
Return

/*/{Protheus.doc} SET_TABS 
Função Responsavel por popular os dados nas tabelas temporarias criadas
@author 	Ricardo Tavares Ferreira
@since 		22/06/2018
@version 	12.1.17
@return 	Logico
@Obs 		Ricardo Tavares - Construcao Inicial
/*/
//==========================================================================================================
	Static Function SET_TABS() 
//==========================================================================================================

	Local nX			:= 0
	Local cCliPad		:= SuperGetMv("MV_CLIPAD",.F.,"000001")
	Local cLojaPad		:= SuperGetMv("MV_LOJAPAD",.F.,"01")
	Local cVendPad		:= SuperGetMv("MV_VENDPAD",.F.,"000001")
	Local lControl		:= .F.
	
	DbSelectArea("SZ1")
	DbSelectArea("SZ2")
	DbSelectArea("SZ4")
	
	If Len(aSL1) > 0 .and. Len(aSL2) > 0 .and. Len(aSL4) > 0
	
		For nX := 1 To Len(aSL1)
			RecLock("SZ1",.T.)
				SZ1->Z1_FILIAL		:= "010108"
				SZ1->Z1_EMISSAO  	:= Stod(SubStr(StrTran(StrTran(aSl1[nX][2],"-",""),":",""),1,8))
				SZ1->Z1_PDV	     	:= cValToChar(aSl1[nX][3])
				SZ1->Z1_NSUTEF   	:= StrZero(aSl1[nX][4],TAMSX3("L1_NSUTEF")[1])
				SZ1->Z1_NUM	     	:= StrZero(aSl1[nX][5],TAMSX3("L1_NUM")[1])
				SZ1->Z1_OPERADO  	:= StrZero(Val(aSl1[nX][6]),3)
				SZ1->Z1_DTLIM	 	:= Stod(SubStr(StrTran(StrTran(aSl1[nX][7],"-",""),":",""),1,8))
				SZ1->Z1_HORA	 	:= Alltrim(aSl1[nX][8])
				SZ1->Z1_VALBRUT  	:= aSl1[nX][9]
				SZ1->Z1_DESCONT  	:= aSl1[nX][10]
				SZ1->Z1_TROCO1   	:= aSl1[nX][11]
				SZ1->Z1_CGCCLI   	:= Alltrim(aSl1[nX][12])
				SZ1->Z1_CLIENTE  	:= cCliPad //aSl1[nX][13]
				SZ1->Z1_DOC	     	:= StrZero(aSl1[nX][14],TAMSX3("L1_DOC")[1])
				SZ1->Z1_SERIE	 	:= StrZero(aSl1[nX][15],TAMSX3("L1_SERIE")[1])
				SZ1->Z1_EMISNF   	:= Stod(SubStr(StrTran(StrTran(aSl1[nX][16],"-",""),":",""),1,8))
				SZ1->Z1_KEYNFCE  	:= Alltrim(aSl1[nX][17])
				SZ1->Z1_LOJA		:= cLojaPad
				SZ1->Z1_VEND		:= cVendPad
				SZ1->Z1_STATUS		:= "1"
			MsUnlock()
			lControl := .T.
		Next nX	
		
		If lControl
			//conout(Replicate("-",nRpl))
			//conout("[CC12M002][SET_TABS] [" + Dtoc(DATE()) +" "+ Time()+ "] Tabela SZ1 Carregada com Sucesso.")
			//conout(Replicate("-",nRpl))
		Else
			//conout(Replicate("-",nRpl))
			//conout("[CC12M002][SET_TABS] [" + Dtoc(DATE()) +" "+ Time()+ "] Falha ao Carregar a Tabela SZ1.")
			//conout(Replicate("-",nRpl))
		EndIf
		
		lControl := .F.
		
		For nX := 1 To Len(aSL2)
			RecLock("SZ2",.T.)
				SZ2->Z2_FILIAL		:= "010108"
				SZ2->Z2_EMISSAO     := Stod(SubStr(StrTran(StrTran(aSL2[nX][2],"-",""),":",""),1,8))
				SZ2->Z2_PDV	        := cValToChar(aSL2[nX][3])
				SZ2->Z2_ITEM        := StrZero(aSL2[nX][4],TAMSX3("L2_ITEM")[1])
				SZ2->Z2_NUM	        := StrZero(aSL2[nX][5],TAMSX3("L1_NUM")[1])
				SZ2->Z2_PRODUTO     := Alltrim(aSL2[nX][6])
				SZ2->Z2_UM	        := Alltrim(aSL2[nX][7])
				SZ2->Z2_CODBAR      := Posicione("SB1",1,FWXFilial("SB1")+Alltrim(aSL2[nX][6]),"B1_CODBAR")
				SZ2->Z2_QUANT	    := aSL2[nX][9]
				SZ2->Z2_VRUNIT      := aSL2[nX][10]
				SZ2->Z2_TOTAL		:= (aSL2[nX][9] * aSL2[nX][10])
				SZ2->Z2_VEND	    := cVendPad
				SZ2->Z2_VALDESC     := aSL2[nX][12]
				SZ2->Z2_CUSTO1      := aSL2[nX][13]
				SZ2->Z2_CF	        := cValToChar(aSL2[nX][14])
				SZ2->Z2_TES	        := Alltrim(aSL2[nX][15])
				SZ2->Z2_STATUS		:= "1"
			MsUnlock()
			lControl := .T.
		Next nX
		
		If lControl
			//conout(Replicate("-",nRpl))
			//conout("[CC12M002][SET_TABS] [" + Dtoc(DATE()) +" "+ Time()+ "] Tabela SZ2 Carregada com Sucesso.")
			//conout(Replicate("-",nRpl))
		Else
			//conout(Replicate("-",nRpl))
			//conout("[CC12M002][SET_TABS] [" + Dtoc(DATE()) +" "+ Time()+ "] Falha ao Carregar a Tabela SZ2.")
			//conout(Replicate("-",nRpl))
		EndIf
		
		lControl := .F.
		
		For nX := 1 To Len(aSL4)
			RecLock("SZ4",.T.)
				SZ4->Z4_FILIAL		:= "010108"
				SZ4->Z4_ITEM		:= StrZero(aSL4[nX][2],TAMSX3("L4_ITEM")[1])
				SZ4->Z4_DATA        := Stod(SubStr(StrTran(StrTran(aSL4[nX][3],"-",""),":",""),1,8))
				SZ4->Z4_NSUTEF      := StrZero(aSL4[nX][4],TAMSX3("L4_NSUTEF")[1])
				If aSL4[nX][5] == 2
					SZ4->Z4_FORMA	:= "CC"
				ElseIf aSL4[nX][5] == 3
					SZ4->Z4_FORMA	:= "CD"
				ElseIf aSL4[nX][5] == 4
					SZ4->Z4_FORMA	:= "TR"
				ElseIf aSL4[nX][5] == 6
					SZ4->Z4_FORMA	:= "R$" //Ricardo
				ElseIf aSL4[nX][5] == 9
					SZ4->Z4_FORMA	:= "VT"
				ElseIf aSL4[nX][5] == 10
					SZ4->Z4_FORMA	:= "POS"
				EndIF
				SZ4->Z4_NUM	        := StrZero(aSL4[nX][6],TAMSX3("L4_NUM")[1])
				SZ4->Z4_VALOR	    := aSL4[nX][7]
				SZ4->Z4_BANDEIR     := cValToChar(aSL4[nX][8])
				SZ4->Z4_AUTORIZ     := cValToChar(aSL4[nX][9])
				SZ4->Z4_DOCTEF      := cValToChar(aSL4[nX][10])
				SZ4->Z4_PARCTEF     := cValToChar(aSL4[nX][11])
				SZ4->Z4_STATUS		:= "1"
			MsUnlock()
			lControl := .T.
		Next nX
		
		If lControl
			//conout(Replicate("-",nRpl))
			//conout("[CC12M002][SET_TABS] [" + Dtoc(DATE()) +" "+ Time()+ "] Tabela SZ4 Carregada com Sucesso.")
			//conout(Replicate("-",nRpl))
		Else
			//conout(Replicate("-",nRpl))
			//conout("[CC12M002][SET_TABS] [" + Dtoc(DATE()) +" "+ Time()+ "] Falha ao Carregar a Tabela SZ4.")
			//conout(Replicate("-",nRpl))
		EndIf
		
		aSL1 := {}
		aSL2 := {}
		aSL4 := {}
	Else
		//conout(Replicate("-",nRpl))
		//conout("[CC12M002][SET_TABS] [" + Dtoc(DATE()) +" "+ Time()+ "]  Nao ha Registros para integracao nos Arrays aSL1,aSl2 e aSl4.")
		//conout(Replicate("-",nRpl))
	EndIf
	
Return

/*/{Protheus.doc} PROT_SL1 
Função responsavel por executar o exectauto de criação das vendas no modulo loja.
@author 	Ricardo Tavares Ferreira
@since 		23/06/2018
@version 	12.1.17
@return 	Logico
@Obs 		Ricardo Tavares - Construcao Inicial
/*/
//==========================================================================================================
	Static Function PROT_SL1() 
//==========================================================================================================
	
	Local lIntERP		:= .F.
	Local cQuery		:= ""
	Local QBLINHA		:= chr(13)+chr(10)
	Local cFilBkp		:= cFilAnt
	
	Private lMsErroAuto := .F. //Variavel que informa a ocorrência de erros no ExecAuto
	Private INCLUI 		:= .T. //Variavel necessária para o ExecAuto identificar que se trata de uma inclusão
	Private ALTERA 		:= .F. //Variavel necessária para o ExecAuto identificar que se trata de uma inclusão

	cQuery := " SELECT  "+QbLinha 
    cQuery += " Z1_FILIAL			L1FILIAL"+QbLinha 
    cQuery += " , Z1_EMISSAO 		L1EMISSAO "+QbLinha 
    cQuery += " , Z1_PDV			L1PDV "+QbLinha 
    cQuery += " , Z1_NSUTEF  		L1NSUTEF "+QbLinha 
    cQuery += " , Z1_NUM			L1NUM "+QbLinha 
    cQuery += " , Z1_OPERADO 		L1OPERADO "+QbLinha 
    cQuery += " , Z1_DTLIM			L1DTLIM "+QbLinha 
    cQuery += " , Z1_HORA			L1HORA "+QbLinha 
    cQuery += " , Z1_VALBRUT 		L1VALBRUT "+QbLinha 
    cQuery += " , Z1_DESCONT 		L1DESCONT "+QbLinha 
    cQuery += " , Z1_TROCO1  		L1TROCO1 "+QbLinha 
    cQuery += " , Z1_CGCCLI  		L1CGCCLI "+QbLinha 
    cQuery += " , Z1_CLIENTE 		L1CLIENTE "+QbLinha 
    cQuery += " , Z1_DOC	   		L1DOC  "+QbLinha 
    cQuery += " , Z1_SERIE			L1SERIE "+QbLinha 
    cQuery += " , Z1_EMISNF  		L1EMISNF "+QbLinha 
    cQuery += " , Z1_KEYNFCE 		L1KEYNFCE "+QbLinha 
    cQuery += " , Z1_LOJA			L1LOJA "+QbLinha 
    cQuery += " , Z1_VEND			L1VEND "+QbLinha 
    cQuery += " , SZ1.R_E_C_N_O_	IDSZ1 "+QbLinha 

	cQuery += "FROM "
	cQuery +=  RetSqlName("SZ1") + " SZ1 "+QBLINHA 

    cQuery += " WHERE "+QbLinha 
    cQuery += " SZ1.D_E_L_E_T_ = ' '  "+QbLinha 
    cQuery += " AND Z1_STATUS <> '2' "+QbLinha 
    //cQuery += " AND Z1_NUM = '000011' "+QbLinha 
	
	MEMOWRITE("C:/ricardo/EXEC_LOJ_SZ1.sql",cQuery)			     
	cQuery := ChangeQuery(cQuery)
	DBUSEAREA(.T.,'TOPCONN',TcGenQry(,,cQuery),"TMP1",.F.,.T.)
		
	DBSELECTAREA("TMP1")
	TMP1->(DBGOTOP())
	COUNT TO NQTREG
	TMP1->(DBGOTOP())
		
	If NQTREG <= 0
		TMP1->(DBCLOSEAREA())
		//Aviso("GET_VMIX","Não há dados do Visual Mix a serem Integrados.",{"Fechar"},1)
		//conout(Replicate("-",nRpl))
		//conout("[CC12M002][PROT_SL1]  [" + Dtoc(DATE()) +" "+ Time()+ "]  Não há dados para Integração com o Protheus ...")
		//conout(Replicate("-",nRpl))
	Else
		//Aviso("GET_SA2","Dados do Visual Mix Encontrados.",{"Fechar"},1)
		//conout(Replicate("-",nRpl))
		//conout("[CC12M002][PROT_SL1]  [" + Dtoc(DATE()) +" "+ Time()+ "]  Dados para Integração com o Protheus Encontrados ...")
		//conout(Replicate("-",nRpl))
		
		While ! TMP1->(EOF())
			
			cFilAnt := TMP1->L1FILIAL
			
			aCab := {{"LQ_COMIS" 	, 0 									,NIL},;
					 {"LQ_TIPOCLI" 	, "F" 									,NIL},;
					 {"LQ_VEND" 	, TMP1->L1VEND							,NIL},;
					 {"LQ_VLRTOT" 	, TMP1->L1VALBRUT						,NIL},;
					 {"LQ_DESCONT" 	, TMP1->L1DESCONT 						,NIL},;
					 {"LQ_VLRLIQ" 	, (TMP1->L1VALBRUT - TMP1->L1DESCONT)	,NIL},;
					 {"LQ_DTLIM" 	, Stod("20491231") 						,NIL},;
					 {"LQ_HORA" 	, TMP1->L1HORA							,NIL},;
					 {"LQ_DINHEIR" 	, 0 									,NIL},;
					 {"LQ_CONVENI" 	, TMP1->L1VALBRUT						,NIL},;
					 {"LQ_EMISSAO" 	, Stod(TMP1->L1EMISSAO)					,NIL},;
					 {"LQ_VLRDEBI" 	, 0 									,NIL},;
					 {"LQ_XNUMINT" 	, TMP1->L1NUM 							,NIL},;
					 {"LQ_SERIE" 	, TMP1->L1SERIE							,NIL},;
					 {"LQ_NUMMOV" 	, "1"									,NIL}}
		/*		
					 {"LQ_PDV" 		,TMP1->L1PDV	 	,NIL},;
					 {"LQ_NSUTEF" 	,TMP1->L1NSUTEF  	,NIL},;
					 {"LQ_XNUMINT" 	,TMP1->L1NUM	 	,NIL},;
					 {"LQ_OPERADO"	,TMP1->L1OPERADO 	,NIL},;
					 {"LQ_DTLIM" 	,TMP1->L1DTLIM		,NIL},;
					 {"LQ_HORA" 	,TMP1->L1HORA		,NIL},;
					 {"LQ_TROCO1" 	,TMP1->L1TROCO1  	,NIL},;
					 {"LQ_CGCCLI" 	,TMP1->L1CGCCLI  	,NIL},;
					 {"LQ_DOC" 		,TMP1->L1DOC	    ,NIL},;
					 {"LQ_SERIE" 	,TMP1->L1SERIE		,NIL},;
					 {"LQ_EMISNF" 	,TMP1->L1EMISNF  	,NIL},;
					 {"LQ_KEYNFCE" 	,TMP1->L1KEYNFCE 	,NIL}} 
					 {"LQ_CLIENTE" 	, TMP1->L1CLIENTE 						,NIL},;
					 {"LQ_LOJA" 	, TMP1->L1LOJA							,NIL},;
					 {"LQ_CGCCLI" 	, TMP1->L1CGCCLI  						,NIL},;
					 {"LQ_PDV" 		, TMP1->L1PDV	 						,NIL},;
					 {"LQ_NSUTEF" 	, TMP1->L1NSUTEF  						,NIL},;
					 {"LQ_OPERADO"	, TMP1->L1OPERADO 						,NIL},;
					 {"LQ_DOC" 		, TMP1->L1DOC	    					,NIL},;
					 {"LQ_SERIE" 	, TMP1->L1SERIE							,NIL},;
					 {"LQ_EMISNF" 	, TMP1->L1EMISNF  						,NIL},;
					 {"LQ_KEYNFCE" 	, TMP1->L1KEYNFCE 						,NIL},;*/
					 

			PROT_SL2(TMP1->L1FILIAL,TMP1->L1NUM,TMP1->L1PDV,TMP1->L1NSUTEF)
			PROT_SL4(TMP1->L1FILIAL,TMP1->L1NUM,TMP1->L1PDV,TMP1->L1NSUTEF)
					
			SetFunName("LOJA701")
			MSExecAuto({|a,b,c,d,e,f,g,h| Loja701(a,b,c,d,e,f,g,h)},.F.,3,"","",{},aCab,aItem,aParcelas)
			
			If lMsErroAuto
				MostraErro()
				DisarmTransaction()
				//conout(Replicate("-",nRpl))
				//conout("[CC12M002] [PROT_SL1]  [" + Dtoc(DATE()) +" "+ Time()+ "]  Erro na Execucao do ExecAlto para o Cupom N..: ("+TMP1->L1FILIAL+" - "+TMP1->L1NUM+"), Falha no Processo ...")			
				//conout(Replicate("-",nRpl))
				
				cUpd := " UPDATE " +  RetSqlName("SZ1")  +QbLinha 
			    cUpd += " SET Z1_STATUS = '3' "+QbLinha 
			    cUpd += " WHERE "+QbLinha 
			    cUpd += " D_E_L_E_T_ = ' '  "+QbLinha 
			    cUpd += " AND Z1_FILIAL = '"+TMP1->L1FILIAL+"' "+QbLinha 
			    cUpd += " AND Z1_NUM = '"+TMP1->L1NUM+"' "+QbLinha 
			    cUpd += " AND Z1_PDV = '"+TMP1->L1PDV+"' "+QbLinha 
			    
			    If (TcSqlExec(cUpd) < 0)
					//conout(Replicate("-",nRpl))
					//conout("[CC12M002] [PROT_SL1]  [" + Dtoc(DATE()) +" "+ Time()+ "]  ERRO NA EXECUCAO DO UPDATE. Erro SQL: "+Alltrim(TCSQLError())+" ...")
					//conout(Replicate("-",nRpl))
				Else
					//conout(Replicate("-",nRpl))
					//conout("[CC12M002] [PROT_SL1]  [" + Dtoc(DATE()) +" "+ Time()+ "]  Update do Cupom N..: ("+TMP1->L1FILIAL+" - "+TMP1->L1NUM+"), Tabela SZ1 Executado com Sucesso ...")			
					//conout(Replicate("-",nRpl))	
				EndIf

			    cUpd := " UPDATE "+ RetSqlName("SZ2") +QbLinha 
			    cUpd += " SET Z2_STATUS = '3' "+QbLinha 
			    cUpd += " WHERE "+QbLinha 
			    cUpd += " D_E_L_E_T_ = ' '  "+QbLinha 
			    cUpd += " AND Z2_FILIAL = '"+TMP1->L1FILIAL+"' "+QbLinha 
			    cUpd += " AND Z2_NUM = '"+TMP1->L1NUM+"' "+QbLinha 
			    cUpd += " AND Z2_PDV = '"+TMP1->L1PDV+"' "+QbLinha 
			    
			    If (TcSqlExec(cUpd) < 0)
					//conout(Replicate("-",nRpl))
					//conout("[CC12M002] [PROT_SL1]  [" + Dtoc(DATE()) +" "+ Time()+ "]  ERRO NA EXECUCAO DO UPDATE. Erro SQL: "+Alltrim(TCSQLError())+" ...")
					//conout(Replicate("-",nRpl))
				Else
					//conout(Replicate("-",nRpl))
					//conout("[CC12M002] [PROT_SL1]  [" + Dtoc(DATE()) +" "+ Time()+ "]  Update do Cupom N..: ("+TMP1->L1FILIAL+" - "+TMP1->L1NUM+"), Tabela SZ2 Executado com Sucesso ...")			
					//conout(Replicate("-",nRpl))	
				EndIf

			    cUpd := " UPDATE "+ RetSqlName("SZ4") +QbLinha 
			    cUpd += " SET Z4_STATUS = '3' "+QbLinha 
			    cUpd += " WHERE "+QbLinha 
			    cUpd += " D_E_L_E_T_ = ' '  "+QbLinha 
			    cUpd += " AND Z4_FILIAL = '"+TMP1->L1FILIAL+"' "+QbLinha 
			    cUpd += " AND Z4_NUM = '"+TMP1->L1NUM+"' "+QbLinha 
			    
			    If (TcSqlExec(cUpd) < 0)
					//conout(Replicatse("-",nRpl))
					//conout("[CC12M002] [PROT_SL1]  [" + Dtoc(DATE()) +" "+ Time()+ "]  ERRO NA EXECUCAO DO UPDATE. Erro SQL: "+Alltrim(TCSQLError())+" ...")
					//conout(Replicate("-",nRpl))
				Else
					//conout(Replicate("-",nRpl))
					//conout("[CC12M002] [PROT_SL1]  [" + Dtoc(DATE()) +" "+ Time()+ "]  Update do Cupom N..: ("+TMP1->L1FILIAL+" - "+TMP1->L1NUM+"), Tabela SZ4 Executado com Sucesso ...")			
					//conout(Replicate("-",nRpl))	
				EndIf
				
				aCab 		:= {}
				aItem 		:= {}
				aParcelas 	:= {}
			Else
				aCab 		:= {}
				aItem 		:= {}
				aParcelas 	:= {}
				//conout(Replicate("-",nRpl))
				//conout("[CC12M002][PUT_PROT]  [" + Dtoc(DATE()) +" "+ Time()+ "]  ExecAuto Executado com Sucesso ...")
				//conout(Replicate("-",nRpl))
				
				cUpd := " UPDATE " +  RetSqlName("SZ1")  +QbLinha 
			    cUpd += " SET Z1_STATUS = '2' "+QbLinha 
			    cUpd += " WHERE "+QbLinha 
			    cUpd += " D_E_L_E_T_ = ' '  "+QbLinha 
			    cUpd += " AND Z1_FILIAL = '"+TMP1->L1FILIAL+"' "+QbLinha 
			    cUpd += " AND Z1_NUM = '"+TMP1->L1NUM+"' "+QbLinha 
			    cUpd += " AND Z1_PDV = '"+TMP1->L1PDV+"' "+QbLinha 
			    
			    If (TcSqlExec(cUpd) < 0)
					//conout(Replicate("-",nRpl))
					//conout("[CC12M002] [PROT_SL1]  [" + Dtoc(DATE()) +" "+ Time()+ "]  ERRO NA EXECUCAO DO UPDATE. Erro SQL: "+Alltrim(TCSQLError())+" ...")
					//conout(Replicate("-",nRpl))
				Else
					//conout(Replicate("-",nRpl))
					//conout("[CC12M002] [PROT_SL1]  [" + Dtoc(DATE()) +" "+ Time()+ "]  Update do Cupom N..: ("+TMP1->L1FILIAL+" - "+TMP1->L1NUM+"), Tabela SZ1 Executado com Sucesso ...")			
					//conout(Replicate("-",nRpl))	
				EndIf

			    cUpd := " UPDATE "+ RetSqlName("SZ2") +QbLinha 
			    cUpd += " SET Z2_STATUS = '2' "+QbLinha 
			    cUpd += " WHERE "+QbLinha 
			    cUpd += " D_E_L_E_T_ = ' '  "+QbLinha 
			    cUpd += " AND Z2_FILIAL = '"+TMP1->L1FILIAL+"' "+QbLinha 
			    cUpd += " AND Z2_NUM = '"+TMP1->L1NUM+"' "+QbLinha 
			    cUpd += " AND Z2_PDV = '"+TMP1->L1PDV+"' "+QbLinha
			    
			    If (TcSqlExec(cUpd) < 0)
					//conout(Replicate("-",nRpl))
					//conout("[CC12M002] [PROT_SL1]  [" + Dtoc(DATE()) +" "+ Time()+ "]  ERRO NA EXECUCAO DO UPDATE. Erro SQL: "+Alltrim(TCSQLError())+" ...")
					//conout(Replicate("-",nRpl))
				Else
					//conout(Replicate("-",nRpl))
					//conout("[CC12M002] [PROT_SL1]  [" + Dtoc(DATE()) +" "+ Time()+ "]  Update do Cupom N..: ("+TMP1->L1FILIAL+" - "+TMP1->L1NUM+"), Tabela SZ2 Executado com Sucesso ...")			
					//conout(Replicate("-",nRpl))	
				EndIf

			    cUpd := " UPDATE "+ RetSqlName("SZ4") +QbLinha 
			    cUpd += " SET Z4_STATUS = '2' "+QbLinha 
			    cUpd += " WHERE "+QbLinha 
			    cUpd += " D_E_L_E_T_ = ' '  "+QbLinha 
			    cUpd += " AND Z4_FILIAL = '"+TMP1->L1FILIAL+"' "+QbLinha 
			    cUpd += " AND Z4_NUM = '"+TMP1->L1NUM+"' "+QbLinha 
			    
			    If (TcSqlExec(cUpd) < 0)
					//conout(Replicate("-",nRpl))
					//conout("[CC12M002] [PROT_SL1]  [" + Dtoc(DATE()) +" "+ Time()+ "]  ERRO NA EXECUCAO DO UPDATE. Erro SQL: "+Alltrim(TCSQLError())+" ...")
					//conout(Replicate("-",nRpl))
				Else
					//conout(Replicate("-",nRpl))
					//conout("[CC12M002] [PROT_SL1]  [" + Dtoc(DATE()) +" "+ Time()+ "]  Update do Cupom N..: ("+TMP1->L1FILIAL+" - "+TMP1->L1NUM+"), Tabela SZ4 Executado com Sucesso ...")			
					//conout(Replicate("-",nRpl))	
				EndIf
			
			lIntERP := LJGRVTUDO(.F.)
			
			If lIntERP
				//conout(Replicate("-",nRpl))
				//conout("[CC12M002] [PROT_SL1]  [" + Dtoc(DATE()) +" "+ Time()+ "]  Integração do Cupom N..: ("+TMP1->L1FILIAL+" - "+TMP1->L1NUM+"), Realizada com Sucesso ...")			
				//conout(Replicate("-",nRpl))	
			Else
				//conout(Replicate("-",nRpl))
				//conout("[CC12M002] [PROT_SL1]  [" + Dtoc(DATE()) +" "+ Time()+ "]  Falha na Integração do Cupom N..: ("+TMP1->L1FILIAL+" - "+TMP1->L1NUM+")...")			
				//conout(Replicate("-",nRpl))	
			EndIf
		EndIf
			TMP1->(DBSKIP())
		End 
		TMP1->(DBCLOSEAREA())
	EndIf 

	cFilAnt := cFilBkp	
Return 

/*/{Protheus.doc} PROT_SL2 
Função responsavel por popular o array aItens do Execauto
@author 	Ricardo Tavares Ferreira
@since 		23/06/2018
@version 	12.1.17
@return 	Logico
@Obs 		Ricardo Tavares - Construcao Inicial
/*/
//==========================================================================================================
	Static Function PROT_SL2(nFil,nNum,nPDV,nNsu)
//==========================================================================================================
	
	Local cQuery	:= ""
	Local QBLINHA	:= chr(13)+chr(10)
	Local cVendPad	:= SuperGetMv("MV_VENDPAD",.F.,"000001")
	Local cPICM		:= GetMV("MV_ICMPAD")
	Local cTabPad	:= GetMV("MV_TABPAD")
	
	Default nFil	:= ""
	Default nNum	:= ""
	Default nPDV	:= ""
	Default nNsu	:= ""
	
	cQuery := " SELECT  "+QbLinha 
    cQuery += " Z2_FILIAL			L2FILIAL	 "+QbLinha 
    cQuery += " , Z2_EMISSAO		L2EMISSAO "+QbLinha 
    cQuery += " , Z2_PDV			L2PDV	    "+QbLinha 
    cQuery += " , Z2_ITEM			L2ITEM		    "+QbLinha 
    cQuery += " , Z2_NUM			L2NUM	    "+QbLinha 
    cQuery += " , Z2_PRODUTO		L2PRODUTO "+QbLinha 
    cQuery += " , Z2_UM				L2UM	    "+QbLinha 
    cQuery += " , Z2_CODBAR 		L2CODBAR "+QbLinha 
    cQuery += " , Z2_QUANT			L2QUANT	 "+QbLinha 
    cQuery += " , Z2_VRUNIT			L2VRUNIT  "+QbLinha 
    cQuery += " , Z2_TOTAL			L2TOTAL	 "+QbLinha 
    cQuery += " , Z2_VEND			L2VEND	 "+QbLinha 
    cQuery += " , Z2_VALDESC		L2VALDESC "+QbLinha 
    cQuery += " , Z2_CUSTO1			L2CUSTO1  "+QbLinha 
    cQuery += " , Z2_CF				L2CF    "+QbLinha 
    cQuery += " , Z2_TES			L2TES	    "+QbLinha 
 //   cQuery += " , SZ2.R_E_C_N_O_	IDSZ2 "+QbLinha 

	cQuery += "FROM "
	cQuery +=  RetSqlName("SZ2") + " SZ2 "+QBLINHA

    cQuery += " WHERE "+QbLinha 
    cQuery += " SZ2.D_E_L_E_T_ = ' '  "+QbLinha 
    cQuery += " AND Z2_STATUS = '1' "+QbLinha 
    cQuery += " AND Z2_FILIAL = '"+nFil+"' "+QbLinha 
    cQuery += " AND Z2_NUM = '"+nNum+"'  "+QbLinha 
    cQuery += " AND Z2_PDV = '"+nPDV+"'  "+QbLinha 
    
    cQuery += " GROUP BY Z2_FILIAL,Z2_EMISSAO,Z2_PDV,Z2_ITEM,Z2_NUM,Z2_PRODUTO,Z2_UM,Z2_CODBAR,Z2_QUANT,Z2_VRUNIT,Z2_TOTAL,Z2_VEND,Z2_VALDESC,Z2_CUSTO1,Z2_CF,Z2_TES"+QbLinha
    cQuery += " ORDER BY 5,4 "+QbLinha
	
	MEMOWRITE("C:/ricardo/EXEC_LOJ_SZ2.sql",cQuery)			     
	cQuery := ChangeQuery(cQuery)
	DBUSEAREA(.T.,'TOPCONN',TcGenQry(,,cQuery),"TMP2",.F.,.T.)
		
	DBSELECTAREA("TMP2")
	TMP2->(DBGOTOP())
	COUNT TO NQTREG
	TMP2->(DBGOTOP())
		
	If NQTREG <= 0
		TMP2->(DBCLOSEAREA())
		//Aviso("GET_VMIX","Não há dados do Visual Mix a serem Integrados.",{"Fechar"},1)
		//conout(Replicate("-",nRpl))
		//conout("[CC12M002][PROT_SL2]  [" + Dtoc(DATE()) +" "+ Time()+ "]  Não há dados para Integração com o Protheus ...")
		//conout(Replicate("-",nRpl))
	Else
		//Aviso("GET_SA2","Dados do Visual Mix Encontrados.",{"Fechar"},1)
		//conout(Replicate("-",nRpl))
		//conout("[CC12M002][PROT_SL2]  [" + Dtoc(DATE()) +" "+ Time()+ "]  Dados para Integração com o Protheus Encontrados ...")
		//conout(Replicate("-",nRpl))
		
		aItem := {}
		
		While ! TMP2->(EOF())
			
			AADD(aItem,{{"LR_PRODUTO"	, TMP2->L2PRODUTO					,NIL},;			
						{"LR_ITEM" 		, TMP2->L2ITEM						,NIL},;			
						{"LR_UM" 		, TMP2->L2UM  						,NIL},;	
						{"LR_LOCAL" 	, "01" 								,NIL},;		
						{"LR_QUANT" 	, TMP2->L2QUANT						,NIL},;			
						{"LR_VRUNIT" 	, TMP2->L2VRUNIT					,NIL},;			
						{"LR_VLTITEM" 	, (TMP2->L2QUANT * TMP2->L2VRUNIT)	,NIL},;			
						{"LR_TES" 		, TMP2->L2TES						,NIL},;			
						{"LR_CF" 		, TMP2->L2CF	    				,NIL},;			
						{"LR_VALDESC"	, Round(TMP2->L2VALDESC,2) 			,NIL},;			
						{"LR_TABELA" 	, cTabPad 							,NIL},;			
						{"LR_DESCPRO"	, 0 								,NIL},;			      
						{"LR_PICM" 		, cPICM								,NIL},;
						{"LR_SERIE" 	, TMP1->L1SERIE						,NIL},;
						{"LR_PRCTAB" 	, Round(TMP2->L2VRUNIT,2)			,NIL}})	
			/*
			//{"LR_FILIAL"	, TMP2->L2FILIAL												,NIL},;
			  {"LR_SITTRIB" 	, Alltrim(Posicione('SF4',1,xFilial('SF4')+TMP2->L2TES,'F4_SITTRIB')) 	,NIL},;
			  {"LR_CLASFIS" 	, Alltrim(Posicione('SF4',1,xFilial('SF4')+TMP2->L2TES,'F4_SITTRIB'))	,NIL},;  		
			*/
			TMP2->(DBSKIP())
		End 
		TMP2->(DBCLOSEAREA())
	EndIf 
	
Return

/*/{Protheus.doc} PROT_SL4 
Função responsavel por popular o array aParcelas do Execauto
@author 	Ricardo Tavares Ferreira
@since 		23/06/2018
@version 	12.1.17
@return 	Logico
@Obs 		Ricardo Tavares - Construcao Inicial
/*/
//==========================================================================================================
	Static Function PROT_SL4(nFil,nNum,nPDV,nNsu)
//==========================================================================================================
	
	Local cQuery	:= ""
	Local QBLINHA	:= chr(13)+chr(10)
	Local cVendPad	:= SuperGetMv("MV_VENDPAD",.F.,"000001")
	
	Default nFil	:= ""
	Default nNum	:= ""
	Default nPDV	:= ""
	Default nNsu	:= ""
	
	cQuery += " SELECT  "+QbLinha 
    cQuery += " Z4_FILIAL			L4FILIAL "+QbLinha 
    cQuery += " , Z4_ITEM			L4ITEM	 "+QbLinha 
    cQuery += " , Z4_DATA			L4DATA "+QbLinha 
    cQuery += " , Z4_NSUTEF 		L4NSUTEF "+QbLinha 
    cQuery += " , Z4_FORMA 			L4FORMA "+QbLinha 
    cQuery += " , Z4_NUM			L4NUM "+QbLinha 
    cQuery += " , Z4_VALOR 			L4VALOR "+QbLinha 
    cQuery += " , Z4_BANDEIR		L4BANDEIR "+QbLinha 
    cQuery += " , Z4_AUTORIZ		L4AUTORIZ "+QbLinha 
    cQuery += " , Z4_DOCTEF			L4DOCTEF "+QbLinha 
    cQuery += " , Z4_PARCTEF		L4PARCTEF "+QbLinha 
    cQuery += " , SZ4.R_E_C_N_O_	IDSZ4 "+QbLinha 

	cQuery += "FROM "
	cQuery +=  RetSqlName("SZ4") + " SZ4 "+QBLINHA 
 
    cQuery += " WHERE "+QbLinha 
    cQuery += " SZ4.D_E_L_E_T_ = ' '  "+QbLinha 
    cQuery += " AND Z4_STATUS = '1' "+QbLinha 
    cQuery += " AND Z4_FILIAL = '"+nFil+"' "+QbLinha 
    cQuery += " AND Z4_NUM = '"+nNum+"'  "+QbLinha 
    cQuery += " AND Z4_NSUTEF = '"+nNsu+"'  "+QbLinha 
	
	MEMOWRITE("C:/ricardo/EXEC_LOJ_SZ4.sql",cQuery)			     
	cQuery := ChangeQuery(cQuery)
	DBUSEAREA(.T.,'TOPCONN',TcGenQry(,,cQuery),"TMP3",.F.,.T.)
		
	DBSELECTAREA("TMP3")
	TMP3->(DBGOTOP())
	COUNT TO NQTREG
	TMP3->(DBGOTOP())
		
	If NQTREG <= 0
		TMP3->(DBCLOSEAREA())
		//Aviso("GET_VMIX","Não há dados do Visual Mix a serem Integrados.",{"Fechar"},1)
		//conout(Replicate("-",nRpl))
		//conout("[CC12M002][PROT_SL4]  [" + Dtoc(DATE()) +" "+ Time()+ "]  Não há dados para Integração com o Protheus ...")
		//conout(Replicate("-",nRpl))
	Else
		//Aviso("GET_SA2","Dados do Visual Mix Encontrados.",{"Fechar"},1)
		//conout(Replicate("-",nRpl))
		//conout("[CC12M002][PROT_SL4]  [" + Dtoc(DATE()) +" "+ Time()+ "]  Dados para Integração com o Protheus Encontrados ...")
		//conout(Replicate("-",nRpl))
		
		While ! TMP3->(EOF())
			
			AADD(aParcelas,{{"L4_DATA" 		, Stod(TMP3->L4DATA),NIL},;
							{"L4_VALOR" 	, TMP3->L4VALOR		,NIL},;
							{"L4_FORMA" 	, TMP3->L4FORMA 	,NIL},;
							{"L4_ADMINIS" 	, "" 				,NIL},;
							{"L4_FORMAID" 	, "" 				,NIL},;
							{"L4_MOEDA" 	, 1					,NIL}})
							
		/*	//{"L4_FILIAL" 	, TMP3->L4FILIAL	,NIL},;
			
			
			AADD(aParcelas,{"L4_ITEM" 		, TMP3->L4ITEM		,NIL})
			AADD(aParcelas,{"L4_DATA" 		, TMP3->L4DATA		,NIL})
			AADD(aParcelas,{"L4_NSUTEF" 	, TMP3->L4NSUTEF 	,NIL})
			AADD(aParcelas,{"L4_FORMA" 		, TMP3->L4FORMA 	,NIL})
			AADD(aParcelas,{"L4_NUM" 		, TMP3->L4NUM		,NIL})
			AADD(aParcelas,{"L4_VALOR" 		, TMP3->L4VALOR 	,NIL})
			AADD(aParcelas,{"L4_BANDEIR" 	, TMP3->L4BANDEIR	,NIL})
			AADD(aParcelas,{"L4_AUTORIZ" 	, TMP3->L4AUTORIZ	,NIL})
			AADD(aParcelas,{"L4_DOCTEF" 	, TMP3->L4DOCTEF	,NIL})
			AADD(aParcelas,{"L4_PARCTEF" 	, TMP3->L4PARCTEF	,NIL})
			AADD(aParcelas,{"L4_MOEDA" 		, 1					,NIL}) */
			
						
			TMP3->(DBSKIP())
		End 
		TMP3->(DBCLOSEAREA())
	EndIf 
	
Return

/*/{Protheus.doc} VMIX_SL1 
Função responsavel por buscar os dados no banco de dados do Visual Mix
@author 	Ricardo Tavares Ferreira
@since 		20/06/2018
@version 	12.1.17
@return 	Logico
@Obs 		Ricardo Tavares - Construcao Inicial
/*/
//==========================================================================================================
	Static Function VMIX_SL1()
//==========================================================================================================
	
	Local cQuery	:= ""
	Local QBLINHA	:= chr(13)+chr(10)
	Local nX		:= 0
	Local lSl2		:= .F.
	Local lSl4		:= .F.

    cQuery := " SELECT  "+QbLinha 
    cQuery += " C1.LOJA					L1FILIAL "+QbLinha 
    cQuery += " , C1.DATA				L1EMISSAO "+QbLinha 
    cQuery += " , C1.NUM_PDV			L1PDV "+QbLinha 
    cQuery += " , C1.EVENTO_NSU			L1NSUTEF "+QbLinha 
    cQuery += " , C1.NUM_CUPOM			L1NUM "+QbLinha 
    cQuery += " , C1.OPERADOR			L1OPERADO "+QbLinha 
    cQuery += " , C1.DATA_ABERTURA		L1DTLIM "+QbLinha 
    cQuery += " , CONVERT(VARCHAR(8),C1.HORA_INICIO,114) L1HORA "+QbLinha 
    cQuery += " , C1.VENDA_BRUTA		L1VALBRUT "+QbLinha 
    cQuery += " , C1.DESCONTOS			L1DESCONT "+QbLinha 
    cQuery += " , C1.TROCO				L1TROCO1 "+QbLinha 
    cQuery += " , CONVERT(VARCHAR(11),C1.CPFCNPJCLIENTE) L1CGCCLI "+QbLinha 
    cQuery += " , C1.CLIENTE			L1CLIENTE "+QbLinha 
    cQuery += " , C3.NUMERONOTA			L1DOC "+QbLinha 
    cQuery += " , C3.SERIENOTA			L1SERIE "+QbLinha 
    cQuery += " , C3.DATAHORAEMISSAO	L1EMISNF "+QbLinha 
    cQuery += " , C3.CHAVE				L1KEYNFCE "+QbLinha 

    cQuery += " FROM VW_TOTAL_CUPOM C1 "+QbLinha 

    cQuery += " INNER JOIN VW_NFCE_CAPA C3 "+QbLinha 
    cQuery += " ON C1.LOJA = C3.LOJA "+QbLinha 
    cQuery += " AND C1.NUM_PDV = C3.NUM_PDV "+QbLinha 
    cQuery += " AND C1.NUM_CUPOM = C3.NUM_CUPOM "+QbLinha 

    cQuery += " WHERE "+QbLinha 
    cQuery += " NOT EXISTS ( "+QbLinha 
    cQuery += " SELECT  "+QbLinha 
    cQuery += " 	C6.EVENTO_CUPOM  "+QbLinha 
    cQuery += " 	, C6.LOJA  "+QbLinha 
    cQuery += " 	, C6.EVENTO_NSU  "+QbLinha 
    cQuery += " 	FROM ST_CUPOM C6 "+QbLinha 
    cQuery += " 	WHERE "+QbLinha 
    cQuery += " 	C6.EVENTO_CUPOM = C1.EVENTO_CUPOM "+QbLinha 
    cQuery += " 	AND C6.LOJA = C1.LOJA  "+QbLinha 
    cQuery += " 	AND C6.EVENTO_NSU = C1.EVENTO_NSU "+QbLinha 
    cQuery += " ) "+QbLinha 
    cQuery += " AND C1.CANCELADO = 0 "+QbLinha 
    cQuery += " AND C3.STATUSNOTA = 1 "+QbLinha 
    cQuery += " AND C3.SITUACAO IN ('00','01','06','07','08') "+QbLinha 
    
    //cQuery += " AND C1.NUM_CUPOM = 25 "+QbLinha 

    cQuery += " ORDER BY 1,5  "+QbLinha 
	
	MEMOWRITE("C:/ricardo/GET_VMIXSL1.sql",cQuery)			     
	cQuery := ChangeQuery(cQuery)
	DBUSEAREA(.T.,'TOPCONN',TcGenQry(,,cQuery),"TMP1",.F.,.T.)
		
	DBSELECTAREA("TMP1")
	TMP1->(DBGOTOP())
	COUNT TO NQTREG
	TMP1->(DBGOTOP())
		
	If NQTREG <= 0
		TMP1->(DBCLOSEAREA())
		//Aviso("GET_VMIX","Não há dados do Visual Mix a serem Integrados.",{"Fechar"},1)
		//conout(Replicate("-",nRpl))
		//conout("[CC12M002][VMIX_SL1]  [" + Dtoc(DATE()) +" "+ Time()+ "]  Não há dados do Visual Mix a serem Integrados  ...")
		//conout(Replicate("-",nRpl))
	Else
		//Aviso("GET_SA2","Dados do Visual Mix Encontrados.",{"Fechar"},1)
		//conout(Replicate("-",nRpl))
		//conout("[CC12M002][VMIX_SL1]  [" + Dtoc(DATE()) +" "+ Time()+ "]  Dados do Visual Mix Encontrados ...")
		//conout(Replicate("-",nRpl))
		
		While ! TMP1->(EOF())
			
			AADD(aSL1,{;
						TMP1->L1FILIAL  ,;
						TMP1->L1EMISSAO ,;
						TMP1->L1PDV     ,;
						TMP1->L1NSUTEF  ,;
						TMP1->L1NUM     ,;
						TMP1->L1OPERADO ,;
						TMP1->L1DTLIM   ,;
						Alltrim(TMP1->L1HORA)+":00",;
						TMP1->L1VALBRUT ,;
						TMP1->L1DESCONT ,;
						TMP1->L1TROCO1  ,;
						STRZERO(Val(TMP1->L1CGCCLI),11),;
						TMP1->L1CLIENTE ,;
						TMP1->L1DOC     ,;
						TMP1->L1SERIE   ,;
						TMP1->L1EMISNF  ,;
						TMP1->L1KEYNFCE })
			
			If VMIX_SL2(TMP1->L1FILIAL,TMP1->L1NUM,TMP1->L1PDV,TMP1->L1NSUTEF)
				lSl2 := .T.
			EndIF
			
			If VMIX_SL4(TMP1->L1FILIAL,TMP1->L1NUM,TMP1->L1PDV,TMP1->L1NSUTEF)
				lSl4 := .T.
			EndIf
			
			TMP1->(DBSKIP())
		End 
		TMP1->(DBCLOSEAREA())
	EndIf 
	
	If lSl2
		//Aviso("GET_SL2","Dados do Visual Mix Encontrados.",{"Fechar"},1)
		//conout(Replicate("-",nRpl))
		//conout("[CC12M002][VMIX_SL2]  [" + Dtoc(DATE()) +" "+ Time()+ "]  Dados do Visual Mix Encontrados ...")
		//conout(Replicate("-",nRpl))
	EndIF
	
	If lSl4
		//Aviso("GET_SL4","Não há dados do Visual Mix a serem Integrados.",{"Fechar"},1)
		//conout(Replicate("-",nRpl))
		//conout("[CC12M002][VMIX_SL4]  [" + Dtoc(DATE()) +" "+ Time()+ "]  Dados do Visual Mix Encontrados  ...")
		//conout(Replicate("-",nRpl))
	EndIF

	If Len(aSL1) > 0 
		
		For nX := 1 To Len(aSL1)
		
			cInsert	:= "INSERT INTO ST_CUPOM (LOJA,DATA,NUM_PDV,EVENTO_CUPOM,EVENTO_NSU,TIPO_EVENTO,DATA_ALTERACAO,FLAG,STATUS)" +QBLINHA
			cInsert	+= "VALUES("+ cValToChar(aSL1[nX][1]) +",CAST('"+ aSL1[nX][2] +"' AS DATE),"+ cValToChar(aSL1[nX][3]) +","+ cValToChar(aSL1[nX][5]) +","+ cValToChar(aSL1[nX][4]) +",10,GETDATE(),1,'')
			
			MEMOWRITE("C:/ricardo/INSERT_VMIXSL1.sql",cInsert)	
			
			If (TcSqlExec(cInsert) < 0)
				//Aviso("Atencao","ERRO NA INTEGRACAO. Erro SQL: "+Alltrim(TCSQLError()),{"Fechar"},1)
				//conout(Replicate("-",nRpl))
				//conout("[CC12M001][VMIX_SL1]  [" + Dtoc(DATE()) +" "+ Time()+ "]  ERRO NA GRAVACAO DA TABELA ST_CUPOM. Erro SQL: "+Alltrim(TCSQLError())+" ...")
				//conout(Replicate("-",nRpl))
				//Return .F.	
			Else
				//conout(Replicate("-",nRpl))
				//conout("[CC12M001][VMIX_SL1]  [" + Dtoc(DATE()) +" "+ Time()+ "]  Gravando Dados na Tabela  (ST_CUPOM - VMIX)..: "+ cValToChar(nX) +" de "+ cValToChar(Len(aSL1)) +" ...")			
				//conout(Replicate("-",nRpl))
			EndIf
		
		Next nX
	EndIf
	
Return 

/*/{Protheus.doc} VMIX_SL2
Funcao que busca os dados que seram salvos na tabela SL2.
@author 	Ricardo Tavares Ferreira
@since 		20/06/2018
@version 	12.1.17
@return 	Logico
@Obs 		Ricardo Tavares - Construcao Inicial
/*/
//==========================================================================================================
	Static Function VMIX_SL2(nFil,nNum,nPDV,nNsu)
//==========================================================================================================
	
	Local cQuery	:= ""
	Local QBLINHA	:= chr(13)+chr(10)
	
	Default nFil	:= 0
	Default nNum	:= 0
	Default nPDV	:= 0
	Default nNsu	:= 0
	
	cQuery := " SELECT  "+QbLinha 
    cQuery += " C2.LOJA					L2FILIAL "+QbLinha 
    cQuery += " , C2.DATA				L2EMISSAO "+QbLinha 
    cQuery += " , C2.NUM_PDV			L2PDV "+QbLinha 
    cQuery += " , C2.SEQUENCIAL			L2ITEM "+QbLinha 
    cQuery += " , C2.NUM_CUPOM			L2NUM "+QbLinha 
    cQuery += " , C5.REFERENCIA			L2PRODUTO "+QbLinha 
    cQuery += " , C3.DESCRICAO			L2UM "+QbLinha 
    cQuery += " , C2.COD_AUTOMACAO		L2CODBAR "+QbLinha 
    cQuery += " , C2.QTDE_TOTAL			L2QUANT "+QbLinha 
    cQuery += " , C2.PRECO_TOTAL		L2VRUNIT "+QbLinha 
    cQuery += " , C2.VENDEDOR			L2VEND "+QbLinha 
    cQuery += " , C2.DESCONTO			L2VALDESC "+QbLinha 
    cQuery += " , C2.PRECO_CUSTO		L2CUSTO1 "+QbLinha 
    cQuery += " , C4.CFOP				L2CF "+QbLinha 
    cQuery += " , C1.COD_INTEGRACAO		L2TES "+QbLinha 

    cQuery += " FROM  VW_ITEM_VENDA C2 "+QbLinha 

    cQuery += " INNER JOIN VW_NFCE_ITEM C4 "+QbLinha 
    cQuery += " ON C2.LOJA = C4.LOJA "+QbLinha 
    cQuery += " AND C2.NUM_PDV = C4.NUM_PDV "+QbLinha 
    cQuery += " AND C2.NUM_CUPOM = C4.NUM_CUPOM "+QbLinha 
    cQuery += " AND C2.SEQUENCIAL = C4.SEQUENCIALITEM "+QbLinha 

    cQuery += " INNER JOIN EMBALAGEM_LOJA C1 "+QbLinha 
    cQuery += " ON C1.LOJA = C2.LOJA "+QbLinha 
    cQuery += " AND C1.PRODUTO_ID = C2.COD_INTERNO "+QbLinha 

    cQuery += " INNER JOIN EMBALAGEM C3 "+QbLinha 
    cQuery += " ON C3.PRODUTO_ID = C2.COD_INTERNO "+QbLinha 
    
    cQuery += " INNER JOIN PRODUTOS C5 "+QbLinha
    cQuery += " ON C5.PRODUTO_ID = C2.COD_INTERNO "+QbLinha

    cQuery += " WHERE "+QbLinha 

    cQuery += " C2.CANCELADO = 0 "+QbLinha
    cQuery += " AND C2.LOJA = "+cValToChar(nFil)+" "+QbLinha  
    cQuery += " AND C2.NUM_CUPOM = "+cValToChar(nNum)+" "+QbLinha 
    cQuery += " AND C2.NUM_PDV = "+cValToChar(nPDV)+" "+QbLinha 
    cQuery += " AND C2.EVENTO_NSU = "+cValToChar(nNsu)+" "+QbLinha 
	
	MEMOWRITE("C:/ricardo/GET_VMIXSL2.sql",cQuery)			     
	cQuery := ChangeQuery(cQuery)
	DBUSEAREA(.T.,'TOPCONN',TcGenQry(,,cQuery),"TMP2",.F.,.T.)
		
	DBSELECTAREA("TMP2")
	TMP2->(DBGOTOP())
	COUNT TO NQTREG
	TMP2->(DBGOTOP())
		
	If NQTREG <= 0
		TMP2->(DBCLOSEAREA())
		//Aviso("GET_SL2","Não há dados do Visual Mix a serem Integrados.",{"Fechar"},1)
		//conout(Replicate("-",nRpl))
		//conout("[CC12M002][VMIX_SL2]  [" + Dtoc(DATE()) +" "+ Time()+ "]  Dados (SL2 - VMIX), Referente ao Cupom...: "+cValToChar(nNum)+",  Nao Encontrados  ...")
		//conout(Replicate("-",nRpl))
		Return .F.
	Else
			
		While ! TMP2->(EOF())
			
			AADD(aSL2,{;
						TMP2->L2FILIAL ,;
						TMP2->L2EMISSAO,;
						TMP2->L2PDV    ,;
						TMP2->L2ITEM   ,;
						TMP2->L2NUM    ,;
						TMP2->L2PRODUTO,;
						TMP2->L2UM     ,;
						TMP2->L2CODBAR ,;
						TMP2->L2QUANT  ,;
						TMP2->L2VRUNIT ,;
						TMP2->L2VEND   ,;
						TMP2->L2VALDESC,;
						TMP2->L2CUSTO1 ,;
						TMP2->L2CF     ,;
						TMP2->L2TES    })
			
			TMP2->(DBSKIP())
		End 
		TMP2->(DBCLOSEAREA())
	EndIf 
	
Return .T.

/*/{Protheus.doc} VMIX_SL4
Funcao que busca os dados que seram salvos na tabela SL2.
@author 	Ricardo Tavares Ferreira
@since 		20/06/2018
@version 	12.1.17
@return 	Logico
@Obs 		Ricardo Tavares - Construcao Inicial
/*/
//==========================================================================================================
	Static Function VMIX_SL4(nFil,nNum,nPDV,nNsu)
//==========================================================================================================
	
	Local cQuery	:= ""
	Local QBLINHA	:= chr(13)+chr(10)
	
	Default nFil	:= 0
	Default nNum	:= 0
	Default nPDV	:= 0
	Default nNsu	:= 0
	
    cQuery := " SELECT  "+QbLinha 
    cQuery += " C5.LOJA					L4FILIAL "+QbLinha 
    cQuery += " , C5.SEQUENCIAL			L4ITEM "+QbLinha
    cQuery += " , C5.DATA				L4DATA "+QbLinha 
    cQuery += " , C5.EVENTO_NSU			L4NSUTEF "+QbLinha 
    cQuery += " , C5.COD_FINALIZ		L4FORMA "+QbLinha 
    cQuery += " , C5.NUM_CUPOM			L4NUM "+QbLinha 
    cQuery += " , C5.VALOR				L4VALOR "+QbLinha 
    cQuery += " , C5.COD_BANDEIRA		L4BANDEIR "+QbLinha 
    cQuery += " , C5.COD_AUTORIZACAO	L4AUTORIZ "+QbLinha 
    cQuery += " , C5.COD_SITEF			L4DOCTEF "+QbLinha 
    cQuery += " , C5.PARCELAS			L4PARCTEF "+QbLinha 

    cQuery += " FROM  VW_FINALIZADORA_DET C5 "+QbLinha 

    cQuery += " WHERE "+QbLinha 
    cQuery += " C5.LOJA = "+cValToChar(nFil)+" "+QbLinha 
    cQuery += " AND C5.NUM_CUPOM = "+cValToChar(nNum)+" "+QbLinha 
    cQuery += " AND C5.NUM_PDV = "+cValToChar(nPDV)+" "+QbLinha 
    cQuery += " AND C5.EVENTO_NSU = "+cValToChar(nNsu)+" "+QbLinha 
	
	MEMOWRITE("C:/ricardo/GET_VMIXSL4.sql",cQuery)			     
	cQuery := ChangeQuery(cQuery)
	DBUSEAREA(.T.,'TOPCONN',TcGenQry(,,cQuery),"TMP3",.F.,.T.)
		
	DBSELECTAREA("TMP3")
	TMP3->(DBGOTOP())
	COUNT TO NQTREG
	TMP3->(DBGOTOP())
		
	If NQTREG <= 0
		//Aviso("GET_SL2","Dados do Visual Mix Encontrados.",{"Fechar"},1)
		//conout(Replicate("-",nRpl))
		//conout("[CC12M002][VMIX_SL4]  [" + Dtoc(DATE()) +" "+ Time()+ "]  Dados (SL4 - VMIX), Referente ao Cupom...: "+cValToChar(nNum)+",  Nao Encontrados  ...")
		//conout(Replicate("-",nRpl))
		TMP3->(DBCLOSEAREA())
		Return .F.
	Else		
		While ! TMP3->(EOF())
			
			AADD(aSL4,{;
						TMP3->L4FILIAL ,;
						TMP3->L4ITEM   ,;
						TMP3->L4DATA   ,;
						TMP3->L4NSUTEF ,;
						TMP3->L4FORMA  ,;
						TMP3->L4NUM    ,;
						TMP3->L4VALOR  ,;
						TMP3->L4BANDEIR,;
						TMP3->L4AUTORIZ,;
						TMP3->L4DOCTEF ,;
						TMP3->L4PARCTEF})
			
			TMP3->(DBSKIP())
		End 
		TMP3->(DBCLOSEAREA())
	EndIf 
	
Return .T.

/*/{Protheus.doc} GET_VALID
Funcao que cria o arquivo no diretorio informado.
@author 	Ricardo Tavares Ferreira
@since 		16/05/2018
@version 	12.1.17
@return 	Logico
@Obs 		Ricardo Tavares - Construcao Inicial
/*/
//==========================================================================================================
	Static Function GET_VALID()
//==========================================================================================================

	Local aDados 	:= {}
	Local aArq	    := {}
	Local aRet      := {}
	Local cDirSrv	:= Alltrim(GetSrvProfString("RootPath",""))
	Local cPath     := cDirSrv + Alltrim(SuperGetMv("GT_DIRCHV",.F.,"\CHAVE\"))
	Local aAreaSM0	:= SM0->(GetArea())
	Local lAchou	:= .F.
	Local nX		:= 0
	Local cCodCript	:= ""
	Local cDCript1	:= ""
	Local cDCript2	:= ""
	Local cDCript3 	:= ""
	Local cDCript4	:= ""
	Local cDCript5	:= ""
	Local cDCript6	:= ""
	
	DbSelectArea("SM0")
	SM0->(DbSetOrder(1))
	
	SM0->(DbGoTop())
	
	While !SM0->(EOF())
		
		IF ! lAchou 
			aRet 	:= GET_ARQ(cPath)
			lExiste	:= aRet[1]
			aArq	:= aRet[2]
			
			If lExiste
				For nX := 1 To Len(aArq)
					If SubStr(aArq[nX][1],9,14) == Alltrim(SM0->M0_CGC) .and. cNmFonte == SubStr(aArq[nX][1],1,8)
						FT_FUSE( cPath+aArq[nX][1])
						FT_FGOTOP()
						
						cCodCript	:= Alltrim(FT_FREADLN())
						cDCript1 	:= Decode64(cCodCript)
						cDCript2	:= Embaralha(cDCript1,1)
						cDCript3 	:= StrTran(StrTran(cDCript2,"@",""),"&","")
						cDCript4	:= Embaralha(cDCript3,1)
						cDCript5	:= StrTran(StrTran(cDCript4,"*",""),"$","")
						cDCript6	:= Embaralha(cDCript5,1)
						
						AADD(aDados,{SubStr(cDCript6,1,8),SubStr(cDCript6,9,14),SubStr(cDCript6,23,8),SubStr(cDCript6,31,8),SubStr(cDCript6,39,14),SubStr(cDCript6,53,8)})
						
						lAchou	:= .T.
						Exit
					EndIf
				Next nX
			EndIf
		EndIf
		SM0->(DbSkip())
	End
	
	RestArea(aAreaSM0)
	
Return ({lAchou,aDados})

/*/{Protheus.doc} GET_ARQ
Funcao que verifica se o arquivo existe no diretorio selecionado.
@author 	Ricardo Tavares Ferreira
@since 		16/05/2018
@version 	12.1.17
@return 	Array
@Obs 		Ricardo Tavares - Construcao Inicial
/*/
//==========================================================================================================
	Static Function GET_ARQ(cPath)
//==========================================================================================================

	Local  lRet := .T.
	Local  aDoc := {}
	
	aDoc := Directory(cPath + "*.gao")

	If Len(aDoc) == 0
		lRet := .F.
	EndIf

Return({lRet,aDoc})

/*/{Protheus.doc} GET_CONN
Funcao que busca a conexao com o banco de dados amarrada ao dbacess.
@author 	Ricardo Tavares Ferreira
@since 		22/04/2018
@version 	12.1.17
@return 	Caracter
@Obs 		Ricardo Tavares - Construcao Inicial
/*/
//==========================================================================================================
	Static Function GET_CONN()
//==========================================================================================================

//	Local cBcoDados	:= SuperGetMv("GT_COSGBD",.F.,"MSSQL/vsm")  	// parametro com o nome da conexao no DBAcess
//	Local cServer 	:= SuperGetMV("GT_IPSGBD",.F.,"10.1.1.102")	// IP do Servidor do banco de dados
	Local cBcoDados	:= SuperGetMv("GT_COSGBD",.F.,"MSSQL/VSM")  	// parametro com o nome da conexao no DBAcess
	Local cServer 	:= SuperGetMV("GT_IPSGBD",.F.,"LocalHost")	// IP do Servidor do banco de dados
	Local nPorta 	:= SuperGetMV("GT_PTSGBD",.F.,7890)			//Porta da conexão do dbacess
	Local nHandle 	:= TcLink(cBcoDados,cServer,nPorta)

Return nHandle
