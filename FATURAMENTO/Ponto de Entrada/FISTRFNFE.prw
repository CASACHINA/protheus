
// ####################################################################################################################################################################################################
//
// Projeto   :   
// Modulo    : Faturamento
// Fonte     : FISTRFNFE
// Data      : 02/07/2020
// Autor     : Valberg Moura 
// Descricao : Ponto de Entrada para inclusao de itns no menu SPEDNFE
//
// ####################################################################################################################################################################################################


#INCLUDE "TOTVS.CH"


User Function FISTRFNFE

	Local _aArea := GetArea()

	If IsInCallStack("SPEDNFE")

		aAdd(aRotina, {"Boleto Santander"	,"U_uBOLSND3",0,2,0,Nil})

	EndIf

	RestArea(_aArea)

Return
