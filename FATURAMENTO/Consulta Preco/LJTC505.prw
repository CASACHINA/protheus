#INCLUDE "PROTHEUS.CH"   
#INCLUDE "LJTC505.CH"
#INCLUDE "TOPCONN.CH"

#DEFINE SEPARADOR "|"                          // utilizado com delimitador na geração do arquivo

User Function LJTC505()                        // "dummy" function - Internal Use
	Local oArqTC505 := Nil                     // objeto da Classe LJCGeraArqTC505
	oArqTC505 := LJCGeraArqTC505():New()  
Return

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºClasse    ³LJCGeraArqTC505  ºAutor  ³Vendas Clientes     º Data ³  23/06/08   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³Classe responsavel em gerar arquivo de produtos                    º±±
±±º          ³sera lido pelo Terminal de Consulta TC505 da GERTEC       	     º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³SigaLoja                                                  		 º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Class LJCGeraArqTC505     

	Data oArquivo                                              //Objeto para manupulacao de dados
	Data cPath                                                 //Caminho para o arquivo
	Data cNomeArq                                              //Nome do arquivo
	Data cArquivo                                              //Nome do arquivo + Path
	Data lRetorno                                              //Passa retorno dos metodos
    Data aProdutos                                             //Array onde será armazenado Codigo, Descrição e Preço
	
	Method New()                                               //Construtor da Classe
	Method Executar()                                          //Method que Executa os Metodos outros Metodos da Classe e Verifica os Retornos
	Method PegaPath()                                          //Metodo responsavel em pegar path do arquivo informado pelo usuario
	Method RenCriar()                                          //Metodo que renomeia e cria um arquivo novo
	Method BuscaProd()                                         //Metodo que busca os produtos 
    Method Escreve()                                           //Metodo que escreve no arquivo
    Method FormatVal()                                         //Metodo que formata o preço dos produtos

EndClass

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºMetodo    ³New       ºAutor  ³Vendas Clientes     º Data ³  23/06/08   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³Construtor da classe LJCGeraArqTC505  		              º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³SigaLoja                                                    º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºParametros³                                              			  º±±
±±º          ³                                          			      º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Method New() Class LJCGeraArqTC505     
    ::oArquivo:= Nil
	::cPath:= "" 
	::cNomeArq:= ""
	::cArquivo:= ""
	::lRetorno:= .F.      
    ::aProdutos:= {}      
	::Executar() 
Return Self

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºMetodo    ³Executar  ºAutor  ³Vendas Clientes     º Data ³  23/06/08   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³Executa os Metodos da Classe e Verifica os Retornos         º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³SigaLoja                                                    º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºParametros³                                                            º±±
±±º          ³   			                                              º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Method Executar() Class LJCGeraArqTC505    
	
	Local lRet := .F.								//Controle do processa    

	//não tem path ou foi precionado a tecla cancela
	If ::PegaPath() == .F.
	    Return()
	EndIf
	
	::oArquivo:= LJCArquivo():New(::cArquivo)

	//nao conseguiu renomear ou criar o arquivo 	
	If ::RenCriar() == .F.     
	    Alert(STR0001)
	    Return()
	EndIf

    //carrega array aProdutos
    Processa({|| lRet := ::BuscaProd()},"")
    
    //não consegui escrever no arquivo
    If !lRet
	    Alert(STR0002)
	    Return()
    EndIf      
      
    //não consegui fechar o arquivo
   	If ::oArquivo:Fechar() == .F.         
	    Alert(STR0003)		// "Não foi possivel fechar o arquivo"
	    Return()
   	EndIf        
   	                                
   	//apresenta mensagem de Sucesso
   	MsgAlert(STR0004,STR0005)	//"Arquivo Gerado com Sucesso" "Geração de Arquivo Texto"

Return Nil 

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºMetodo    ³PegaPath  ºAutor  ³Vendas Clientes     º Data ³  23/06/08   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³Monta tela e pega o Path do Arquivo informado pelo Usuario  º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³SigaLoja                                                    º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºParametros³                                               			  º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍº±±
±±ºRetorno   ³::lRetorno:= retorno logico do Metodo                       º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Method PegaPath() Class LJCGeraArqTC505

   Local cMask  := PadR('Texto (*.txt)',27) + '|*.txt|' + PadR('Todos (*.*)',27)+ '|*.*|'     // mascara passada para Função cGetFile
   Local oGrupo := Nil                                                                         // objeto grupo box
   Local oGet   := Nil                                                                         // objeto caixa de texto
   Local oDlg   := Nil                                                                         // objeto janela de dialogo
   Local nOpca  := 0                                                                           // indica que botão foi precionado

   DEFINE MSDIALOG oDlg TITLE STR0006 FROM 323,412 TO 450,800 PIXEL STYLE DS_MODALFRAME STATUS	//"Gera Arquivo"

   oGrupo := TGroup():New(5,2,62,195, STR0007 ,,,,.T.)											// "Arquivo de Preço de Produtos"
   
   oGet := TGet():New(14,8, bSETGET(::cArquivo),,150,10,,,,,,,,.T.,,,,,,,.T.,,,)

   SButton():New(14,160,14,{|| ::cArquivo := cGetFile(cMask, STR0008,0,,.F.,GETF_LOCALHARD + GETF_OVERWRITEPROMPT)},)//"Selecione o Arquivo"
 
   DEFINE SBUTTON FROM 45, 70 TYPE 1 ACTION (nOpca:= 1, oDlg:End());
   ENABLE OF oDlg
    
   DEFINE SBUTTON FROM 45, 101 TYPE 2 ACTION (nOpca:= 2, oDlg:End());
   ENABLE OF oDlg
      
   ACTIVATE MSDIALOG oDlg CENTERED                         
   
   If nOpca == 1 .AND. ::cArquivo <> ""
      ::lRetorno:= .T.
   EndIf
	
Return(::lRetorno) 

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºMetodo    ³RenCriar  ºAutor  ³Vendas Clientes     º Data ³  23/06/08   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     |Renomeia o arquivo ******_old.*** e cria um novo            º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³SigaLoja                                                    º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºParametros³                                              			  º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍº±±
±±ºRetorno   ³::lRetorno:= retorno logico do Metodo                       º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Method RenCriar()Class LJCGeraArqTC505   

	Local nRetorno:= 0                        // recebe o retorno da função Remonear do objeto ::oArquivo
	
  	//deleta arquivo anterior se existir xxxxxxxxx_OLD.txt
   	If ::oArquivo:Existe(Stuff(::cArquivo,RAT(".",::cArquivo),1,"_OLD."))
   		nRetorno := FERASE(Stuff(::cArquivo,RAT(".",::cArquivo),1,"_OLD."))
   	EndIf

	If ::oArquivo:Existe(::cArquivo)                     
	    
	    // renomeia o arquivo adicionando "_OLD" no seu fim
	    nRetorno:= ::oArquivo:Renomear(Stuff(::cArquivo,RAT(".",::cArquivo),1,"_OLD."))
	    
		If(nRetorno > -1)
		   ::lRetorno:= ::oArquivo:Criar()	
		Else
		   ::lRetorno:= .F.   
		EndIf
	Else
		::lRetorno:= ::oArquivo:Criar()	
	EndIf      
	
Return(::lRetorno) 
          
/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºMetodo    ³BuscaProd ºAutor  ³Vendas Clientes     º Data ³  23/06/08    º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³Busca os Produtos no formato:                                º±±
±±º          ³    - Codigo de Barras|Descrição|Preço de Venda|             º±±
±±º          ³Carrega array aProdutos                                      º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³SigaLoja                                                     º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºParametros³                                              			   º±±
±±º          ³                                          			       º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Method BuscaProd() Class LJCGeraArqTC505
	
	Local cCodBar    	:= ""                   				// recebe codigo de barras da tabela SLK
	Local cCodBarB1    	:= ""                   				// recebe codigo de barras da tabela SB1->B1_CODBAR
	Local lRetorno		:= .F.									//Retorno do metodo
	Local cDescricao 	:= ""                   				// recebe a descricao do produto da tabela SB1->B1_DESC
	Local nPreco     	:= 0                    				// recebe o preco do produto da tabela SB1->B1_PRV1 
	Local cTabPad		:= AllTrim(SuperGetMv("MV_TABPAD"))		//Tabela de preco padrao    
    Local nPrecoFin    	:= 0                    				//Preco SBO x quantidade SLK
    Local cTexto		:= ""									//String que será gravada no arquivo
    Local aBtn			:= {}
    Local nSelected		:= 0
    Local lCenVenda		:= SuperGetMv("MV_LJCNVDA",,.F.)		//Indica se existe integracao com cenario de vendas
    Local lB1_MSBLQL	:= .F.
    Local lEnvia		:= .T.
    Local nDesc         := 0                
    Local cQuery        := ""

	
	cQuery := "SELECT " + CRLF 
    cQuery += "DISTINCT (B1_COD) ,B1_DESC, B1_CODBAR,  DA1_PRCVEN, " + CRLF 
  
    cQuery += "(SELECT TOP (1) " + CRLF  
    cQuery += "MB8_DESCVL  " + CRLF 
	
    cQuery += "FROM " + RetSqlName("MEI") + " MEI " + CRLF 
    cQuery += "INNER JOIN "  + RetSqlName("MB8") + " MB8 " + CRLF 
    cQuery += "    ON MB8_FILIAL = '" + xFilial("MB8") + "' " + CRLF
    cQuery += "    AND MB8_CODREG = MEI_CODREG " + CRLF
    cQuery += "    AND MB8_CODPRO = SB1.B1_COD " + CRLF
    cQuery += "AND MB8.D_E_L_E_T_ <> '*' " + CRLF 
    cQuery += "INNER JOIN "  + RetSqlName("MB3") + " MB3 " + CRLF
    cQuery += "    ON MB3_FILIAL = '" + xFilial("MB3") + "' " + CRLF
    cQuery += "    AND MB3_CODREG = MEI_CODREG " + CRLF
    cQuery += "    AND MB3_CODFIL = '" + FWCodFil() + "' " + CRLF
    cQuery += "    AND MB3.D_E_L_E_T_ <> '*' " + CRLF
    cQuery += "WHERE " + CRLF  
    cQuery += "    MEI_FILIAL = '" + xFilial("MEI") + "' " + CRLF
    cQuery += "    AND MEI_CODTAB = '" + cTabPad + "' " + CRLF
    cQuery += "    AND (MEI_DATDE <= '" + Dtos(dDataBase) + "' AND MEI_DATATE >= '" + Dtos(dDataBase) + "') " + CRLF 
    cQuery += "AND MEI.D_E_L_E_T_ <> '*'  ) MB8_DESCVL" + CRLF 
 
    cQuery += "FROM " + RetSqlName("SB1") + " SB1 " + CRLF  
    cQuery += "INNER JOIN "  + RetSqlName("DA1") + " DA1 " + CRLF 
    cQuery += "    ON DA1_FILIAL = '" + xFilial("DA1") + "' " + CRLF 
    cQuery += "	   AND B1_COD = DA1_CODPRO " + CRLF
    cQuery += "	   AND DA1_CODTAB = '" + cTabPad + "' " + CRLF
    cQuery += "    AND DA1.D_E_L_E_T_ <> '*' " + CRLF 
   
    cQuery += "WHERE  " + CRLF 
	cQuery += "	   B1_FILIAL = '" + xFilial("SB1") + "' " + CRLF
    cQuery += "	   AND B1_MSBLQL <> '1'  " + CRLF
    cQuery += "	   Order By SB1.B1_COD " + CRLF
	
	dbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery), 'QRY', .F., .T.)
	dbSelectArea("QRY")
	QRY->(dbGoTop())
	
	While !QRY->(Eof())
		
		cCodBarB1   := QRY->B1_CODBAR
		cDescricao	:= QRY->B1_DESC
		
		If QRY->MB8_DESCVL <> 0
			nPreco := QRY->DA1_PRCVEN - QRY->MB8_DESCVL
		Else
			nPreco := QRY->DA1_PRCVEN
		Endif

		cTexto:= ALLTRIM(cCodBarB1) + SEPARADOR + RTRIM(cDescricao) + SEPARADOR ;
		+ ::FormatVal(nPreco) + SEPARADOR
		
		lRetorno:= ::oArquivo:Escrever(cTexto)

		//"Caso nao consiga gravar o txt pergunta se deve continuar
		If !lRetorno .AND. nSelected <> 2
			//# "Sim" # "Sim para Todos" #"Cancelar"
			aBtn := {STR0010,STR0011,STR0012}
			//"N foi possivel Incluir o produto : " # "Deseja continuar mesmo assim ? "
			nSelected := Aviso(STR0013,STR0014+cDescricao+CHR(13)+CHR(10)+STR0015,aBtn,2)
			If nSelected == 3 .OR. nSelected == 0
				Exit
			EndIf
		EndIf
		
		IncProc(STR0009)		// "Aguarde, Gerando arquivo de pre GERTEC..."
		QRY->(dbSkip())
	Enddo
	QRY->(dbClosearea())
	
Return lRetorno

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºMetodo    ³Escreve   ºAutor  ³Vendas Clientes     º Data ³  23/06/08   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³Adciona informações no Arquivo                              º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³SigaLoja                                                    º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºParametros³                                               			  º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍº±±
±±ºRetorno   ³::lRetorno:= retorno logico do Metodo                       º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Method Escreve() Class LJCGeraArqTC505

	Local cTexto := ""                       // linha de informacao que será gravada no arquivo
	Local nCont  := 0                        // variavel auxiliar utilizada no For                       	

	ProcRegua(Len(::aProdutos))    

	For nCont:= 1 To Len(::aProdutos)
		
		IncProc( STR0009 )					// "Aguarde, Gerando arquivo de preço GERTEC..."
		
		//contatena codigo do produto com descricao e preco formado pelo metodo FormatVal()
		cTexto:= ::aProdutos[nCont][1] + SEPARADOR + ::aProdutos[nCont][2] + SEPARADOR ;
		         + ::FormatVal(::aProdutos[nCont][3]) + SEPARADOR
		         
	    ::lRetorno:= ::oArquivo:Escrever(cTexto)
	Next	    
	
Return(::lRetorno)

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºMetodo    ³FormatVal ºAutor  ³Vendas Clientes     º Data ³  23/06/08   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     |Formata o preco com 2 casas decimais  		              º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³SigaLoja                                                    º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºParametros³nPreco:= preco não formatado                     			  º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍº±±
±±ºRetorno   ³xRetorno:= Retorna um caracter como valor com 2 casas       º±±
±±º          ³           decimais                                         º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Method FormatVal(nPreco) Class LJCGeraArqTC505  

	Local xRetorno:= 0                       // o retorno do metodo que recebe um numero e retorno um caracter
	
	// Parametro "@E" transforma em moeda nao sendo necessario a multiplicacao por 100
	// para formatacao dos valores          	
	xRetorno:= Transform(nPreco, "@E 9999999999.99")		
	
Return(ALLTRIM(CVALTOCHAR(xRetorno)))
\
