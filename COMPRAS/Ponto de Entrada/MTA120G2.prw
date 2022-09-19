#include "totvs.ch"

/*/{Protheus.doc} MTA120G2
PE para alteracao de campos na confirmacao do pedido de compra
@author Paulo Cesar Camata (CAMATECH)
@since 26/02/2019
@version 12.1.17
@type function
/*/
User Function MTA120G2()
	Local aArea

	if type("CCLICYB") == "C" // Somente chamar alterar valor do campo caso variavel exista
		aArea := GetArea()
		SC7->C7_YCLIENT := cCliCyb // Atualiza o codigo do cliente, com a variável pública criada no ponto de entrada MT120TEL
		RestArea(aArea)
	endif

	if type("cDesB2B") == "C" // Somente chamar alterar valor do campo caso variavel exista
		aArea := GetArea()
		SC7->C7_B2B := cDesB2B // Atualiza o codigo do cliente, com a variável pública criada no ponto de entrada MT120TEL
		RestArea(aArea)
	endif

Return nil
