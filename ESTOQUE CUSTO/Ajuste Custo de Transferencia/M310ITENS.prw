#include 'totvs.ch'
#include 'parmtype.ch'
#include 'topconn.ch'


// ####################################################################################################################################################################################################
//
// Projeto   :   
// Modulo    : Faturamento
// Fonte     : M310ITENS
// Data      : 14/08/19
// Autor     : Valberg Moura 
// Descricao : PE para alterar dados dos itens transferido
//
//    LOCALIZAÇÃO  : Function A310Proc() - Função utilizada para executar a transferência.
//    EM QUE PONTO : Executada após a montagem do array AItens antes das chamadas das rotinas automáticas que irão gerar os itens do pedido de vendas, 
//                   do documento de entrada ou da fatura de entrada (localizado). É utilizado para permitir que o usuário manipule o array aItens que 
//					 contém os itens do cabeçalho do pedido de vendas, documento de entrada ou fatura de entrada. É passado um parâmetro para identificar a rotina 
//					 a ser executada após o ponto de entrada.
//
// ####################################################################################################################################################################################################


User  Function M310ITENS()
	Local _aArea := GetArea()
	Local _cCodProd := ""
	Local _nPerICMS := 0
	Local _nPrcVen  := 0
	Local _nQuant   := 0
	Local _nPrcTot  := 0
	Local _nx
	Local _nz
	Local _cProg := PARAMIXB[1]
	Local _aItens := PARAMIXB[2]
	
	
	//Habilidar a rotina em data especifica.
	If dDatabase < Ctod('07/10/2019')
		Return(_aItens)
	Endif

	If _cProg == 'MATA410'


		//Ajsuta o custo apenas para transferencia para as lojas de SC

		If cFilAnt == "010104" // CD do PR 
			For _nx:=1 to Len(_aItens)

				//Alimenta as variaveis com informaçoes do Array de itens
				For _nz:=1 to Len(_aItens[_nx])
					If "C6_PRODUTO" $ _aItens[_nx,_nz,1]
						_cCodProd := _aItens[_nx,_nz,2]	
					ElseIf "C6_PRCVEN" $ _aItens[_nx,_nz,1]
						_nPrcVen := _aItens[_nx,_nz,2]
					ElseIf "C6_QTDVEN" $ _aItens[_nx,_nz,1]
						_nQuant := _aItens[_nx,_nz,2]
					ElseIf "C6_VALOR" $ _aItens[_nx,_nz,1]
						_nPrcTot := _aItens[_nx,_nz,2]
					EndIf
				Next _nz

				DbSelectArea("NNT")
				DbSetOrder(1)
				If DbSeek(xFilial("NNT")+NNS_COD)

					If NNT->NNT_FILDES $ "010106,010107,010109,010110"

						//Localiza o ultimo custo calculado para o produto
						_cQry := "SELECT TOP 1 * FROM " +RetSqlName("Z03")
						_cQry += " WHERE Z03_FILIAL = '"+xFilial("Z03")+"' " 
						_cQry += " AND  Z03_PRODUT = '"+_cCodProd+"' " 
						_cQry += " ORDER BY Z03_DCUSTO DESC "
						TcQuery _cQry New Alias "TZ03" 

						If TZ03->Z03_VCUSTO > 0

							//Grava o novo valor do custo
							For _nz:=1 to Len(_aItens[_nx])
								If"C6_PRCVEN" $ _aItens[_nx,_nz,1]
									_aItens[_nx,_nz,2] := TZ03->Z03_VCUSTO
								ElseIf "C6_VALOR" $ _aItens[_nx,_nz,1]
									_aItens[_nx,_nz,2] := TZ03->Z03_VCUSTO * _nQuant
								Endif
							Next _nz

						Endif

						TZ03->(DbCloseArea())

					Endif

				Endif

			Next _nx
		Endif
	EndIf

	RestArea(_aArea)

Return(_aItens)
