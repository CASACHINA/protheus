#include "totvs.ch"

/*/{Protheus.doc} MT010INC
PE chamado após a inclusao de produtos
@author unknown
@since 26/08/2017
@version 12
@type function
/*/


user function VA006FIM() 

   /*	U_RT002() // Funcao para inserir saldo zerado na SB2 (Utilizado pela transferencia entre filiais) 
  	If Inclui
   		U_GT12M003("SB1","INCLUI")

    ElseIf Altera
        U_GT12M003("SB1","ALTERA")
    Else

        U_GT12M003("SB1","EXCLUI")
   EndIf  */
	  

	IF u_CChWMSAtivo() .And. SB1->B1_CYBERW == 'S'
		//cria o log
	   	LJMsgRun("Criando cadastro no WMS!!!")
		u_CChtoCyberLog('PRODUTOS', SB1->B1_COD, 'I')
	EndIF
	
	LJMsgRun("Criando Ligacao Produto x Armazem", , { || 	U_RT002()}) // Funcao para inserir saldo zerado na SB2 (Utilizado pela transferencia entre filiais)
	
	
	
	
return
