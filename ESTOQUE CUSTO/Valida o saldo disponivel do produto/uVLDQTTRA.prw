// ####################################################################################################################################################################################################
//
// Projeto   :   
// Modulo    : Estoque / Custo
// Fonte     : uVLDQTTRA
// Data      : 14/08/19
// Autor     : Valberg Moura 
// Descricao : Valida o saldo disponivel do produto
//
// ####################################################################################################################################################################################################


#include 'totvs.ch'
#include 'parmtype.ch'
#include 'topconn.ch'


User Function uVLDQTTRA()

	Local _aArea   := GetArea()
	Local _oModel := FWModelActive()
	Local _oModelNNT := _oModel:GetModel('NNTDETAIL')
	Local _cCodProd  := _oModelNNT:GetValue('NNT_PROD')
	Local _cArmazem  := _oModelNNT:GetValue('NNT_LOCAL')
	Local _lRet := .T.
	Local _nSldDis  := 0
	Local _nQuant	:= _oModelNNT:GetValue('NNT_QUANT') // NNT_QUANT



	dbSelectArea("SB2")
	dbSeek(xFilial("SB2") + _cCodProd + _cArmazem)
	_nSldDis  := SaldoSB2(Nil,.T.,dDatabase) +1 //somando mais 1 unidades pelo erro quando o saldo só contem 1 unidade

	If _nQuant > _nSldDis  

		_lRet := .F.

		Alert("Atenção " +UsrRetName(__cUserID) +chr(13)+chr(10) +chr(13)+chr(10) +" O saldo deste produto é insuficiente para a quantidade digitada."+chr(13)+chr(10)+chr(13)+chr(10)+" Quantidade digitada : "+Alltrim(Str(_nQuant))+" , Saldo disponivel em estoque :  " +Alltrim(Str(_nSldDis)))


	Endif

	RestArea(_aArea)

Return(_lRet)
