#INCLUDE "TOTVS.CH"
#INCLUDE "TOPCONN.CH"
#INCLUDE "RWMAKE.CH"
#include 'fwmvcdef.ch'

/*/{Protheus.doc} 



@author Eduardo Vieira
@since 11/04/2022
@see 
/*/
User Function MA020ROT()
Local aRotUser := {}
//Define Array contendo as Rotinas a executar do programa     // ----------- Elementos contidos por dimensao ------------    
// 1. Nome a aparecer no cabecalho                             // 2. Nome da Rotina associada                                 
// 3. Usado pela rotina                                        // 4. Tipo de Transacao a ser efetuada                         
//    1 - Pesquisa e Posiciona em um Banco de Dados            //    2 - Simplesmente Mostra os Campos                        
//    3 - Inclui registros no Bancos de Dados                  //    4 - Altera o registro corrente                           
//    5 - Remove o registro corrente do Banco de Dados         //    6 - Altera determinados campos sem incluir novos Regs     
AAdd( aRotUser, { 'Produto x Fornecedor', 'U_XMA020RT()', 0, 4 } )
Return (aRotUser)

user function XMA020RT()
Local aButtons := {{.F.,Nil},{.F.,Nil},{.F.,Nil},{.T.,Nil},{.T.,Nil},{.T.,Nil},{.T.,"Salvar"},{.T.,"Cancelar"},{.T.,Nil},{.T.,Nil},{.T.,Nil},{.T.,Nil},{.T.,Nil},{.T.,Nil}}

    FWExecView("GRADE DE PRODUTOS","MATA061",MODEL_OPERATION_INSERT,, { || .T. }, , ,aButtons ) 
RETURN
