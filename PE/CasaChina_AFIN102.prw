/**********************************************************************************************************************************/
/** Funcao AFIN102                                                                            			 			   				   **/
/** Esta funcao tem por finalidade validar tamanho, tipo e divergencias entre valores do titulo e codigo de barras		 		   **/
/** Data: 25/09/2015                                                                                              					**/
/** Totvs                                                                                                 		 					**/
/**********************************************************************************************************************************/
/** Data       | Responsável                    | Descrição                                                        		 			**/
/**********************************************************************************************************************************/
/** 25/09/2015 | Reinaldo Maurício Santos       | Criação da rotina/procedimento.                                     				**/
/**********************************************************************************************************************************/
#include 'totvs.ch'

User Function AFIN102()

	Local nValor 	:= M->E2_VALOR			// valor do Titulo que esta aberto
	Local nValor2 := 0
	Local cCod		:= ALLTRIM(M->E2_CODBAR)	// Codigo de barras (Inteiro)  
	Local lRet		:= .F.						// variavel de retorno	
	Local nAcres	:= M->E2_ACRESC
	Local nDecres	:= M->E2_DECRESC
	Local nSoma := 0
		
	//Verifica a quantidade de caracteres do codigo de barras
	If Len(cCod) >= 44

		SA6->(DbSetOrder(1))
		
		//Se encontrar o codigo do banco na tabela, entra no IF (Ex: 858)
		if SA6->(DbSeek(xFilial("SA6") + SUBSTR(cCod,1,3),.T. )) .or. SUBSTR(cCod,1,3) $ "001/033/104/237/341/389"
						          
			// Variavel recebe apenas o valor do Titulo. Inicia no caracter 10 e conta 10 caracteres apartir deste. 
			cCod := val(SUBSTR(cCod,10,10))/100				
		Else
			// Variavel recebe apenas o valor do Titulo. Inicia no caracter 6 e conta 10 caracteres apartir deste.	  
			cCod := val(SUBSTR(cCod,6,10))/100	
		ENDIF			
		
		//Compara para ver se os valores sao diferentes
		If nValor <> cCod
			//Imprime mensagem com as divergencias
			//MsgAlert( 'Divergências encontradas:'+ CRLF + 'Valor do Titulo: ' + cValtoChar(nValor) + CRLF + 'Valor Cod.Barras: ' + cValtoChar(cCod), 'TOTVS' )

			If !Empty(nAcres)
			
				nSoma := nValor + nAcres
			
			ElseIf !Empty(nDecres)
			
				nSoma := nValor - nDecres
			
			EndIF
			
			nAcreDecr := IIF(!Empty(nAcres), nAcres,nDecres)

			If 	MsgYesNo( 	'Divergências Encontradas:'	+ CRLF + ;
							'- Valor do Titulo:-----------------'+ cValtoChar(nValor)+ CRLF +; 
							'- Valor Cod.Barras:-------------'+ cValtoChar(cCod)+ CRLF +;	
							'- Valor Acrecimo/Decrecimo:--'+ cValtoChar(nAcreDecr)+ CRLF + CRLF +;	
							'- Valor Alterado: '  		     + IIF(!Empty(nAcreDecr),cValtoChar(nSoma)," Sem Acrescimo/Decrecimo! ")+ CRLF + CRLF +;
							'-----------Aceitar Valores?----------- ','TOTVS')
				
				lRet := .T.	
			EndIf		
		
		Else	
			//Se valores forem iguais retorna verdadeiro
			lRet := .T.	
		EndIf
	Else
		
		MsgAlert("Quantidade de digitos do codigo de barras invalido!")
			
	EndIf
	
	SA6->(DbCloseArea())
	
//Enquanto for falso o focus permanece no campo Codigo de Barras
Return lRet