#INCLUDE "PROTHEUS.CH"
#INCLUDE "TOPCONN.CH"

/*/{Protheus.doc} M020EXC
Ponto de Entrada Executado na Exclusao do Fornecedor feito pra integrar os Dados com o Visual MIX.
@author 	Ricardo Tavares Ferreira
@since 		07/07/2018
@version 	12.1.17
@return 	Logico
@Obs 		Ricardo Tavares - Construcao Inicial
/*/
//==========================================================================================================
	User Function M020EXC()
//==========================================================================================================
	
	Local aArea := GetArea()
	
	U_GT12M003("SA2","EXCLUI")
	
	RestArea(aArea)
	
Return
	