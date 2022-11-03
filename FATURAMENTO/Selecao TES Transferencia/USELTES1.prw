// ####################################################################################################################################################################################################
//
// Projeto   :   
// Modulo    : Estoque / Custo
// Fonte     : USELTES1
// Data      : 14/08/19
// Autor     : Valberg Moura 
// Descricao : Gatilho para selecao de TES entrada / saida na rotina de transferencia MATA311
//
// ####################################################################################################################################################################################################
/*
ORIGEM	DESTINO	B1_YSTPR	B1_YSTSC	SAIDA	ENTRADA
PR		PR		SIM			SIM			509		253



*/
#include 'totvs.ch'
#include 'parmtype.ch'
#include 'topconn.ch'


User function USELTES1(_cTpTES)
	Local _aArea   := GetArea() 
	Local _oModel := FWModelActive()
	Local _oModelNNT := _oModel:GetModel('NNTDETAIL') 
	Local _cFilOri := Posicione("SM0",1,cEmpAnt + _oModelNNT:GetValue('NNT_FILORI'),"M0_ESTENT")
	Local _cFilDes := Posicione("SM0",1,cEmpAnt + _oModelNNT:GetValue('NNT_FILDES'),"M0_ESTENT")
	Local _cYSTPR  := Posicione("SB1",1,xFilial("SB1") + _oModelNNT:GetValue('NNT_PROD'),"B1_YSTPR")
	Local _cYSTSC  := Posicione("SB1",1,xFilial("SB1") + _oModelNNT:GetValue('NNT_PROD'),"B1_YSTSC")
	Local _aVar    := {}
	Local aSaveLines:= {}
	Local _cRet := ""
	Local _i := 0


	If Alltrim(_cYSTPR) == ""
		_cYSTPR:= "2"
	Endif
	If Alltrim(_cYSTSC) == ""
		_cYSTSC:= "2"
	Endif

	//Alert(_cFilOri+ "."+_cFilDes+ "."+_cYSTPR+ "."+_cYSTSC)

	aAdd(_aVar,{'PR','PR','1','1','509','253'})
	aAdd(_aVar,{'PR','PR','1','2','509','253'})
	aAdd(_aVar,{'PR','PR','2','2','704','333'})
	aAdd(_aVar,{'PR','PR','3','3','671','254'})
	aAdd(_aVar,{'PR','SC','1','1','509','253'})
	aAdd(_aVar,{'PR','SC','1','2','505','251'})
	aAdd(_aVar,{'PR','SC','2','2','505','251'})
	aAdd(_aVar,{'PR','SC','3','3','671','254'})
	aAdd(_aVar,{'PR','SC','5','12','505','251'})
	aAdd(_aVar,{'SC','SC','1','1','509','253'})
	aAdd(_aVar,{'SC','SC','2','2','705','334'})
	aAdd(_aVar,{'SC','SC','1','2','505','251'})
	aAdd(_aVar,{'SC','SC','3','3','671','254'})
	aAdd(_aVar,{'SC','PR','1','2','505','251'})
	aAdd(_aVar,{'SC','PR','2','2','505','251'})
	aAdd(_aVar,{'SC','PR','3','3','671','254'})
	aAdd(_aVar,{'SC','PR','1','1','509','253'})
	aAdd(_aVar,{'PR','PR','4','4','686','317'})
	aAdd(_aVar,{'PR','SC','4','4','686','317'})
	aAdd(_aVar,{'SC','PR','4','4','686','317'})
	aAdd(_aVar,{'SC','SC','4','4','686','317'})
//
	aAdd(_aVar,{'PR','PR','4','2','686','317'})
	aAdd(_aVar,{'PR','SC','4','2','686','251'})
	aAdd(_aVar,{'SC','PR','4','2','505','251'})
	aAdd(_aVar,{'SC','SC','4','2','505','251'})


	For _i := 1 to Len(_aVar)

		If _cFilOri == _aVar[_i,1] .and. _cFilDes == _aVar[_i,2] .and. _cYSTPR == _aVar[_i,3] .and. _cYSTSC == _aVar[_i,4]

			if _cTpTES =="E"
				_cRet := _aVar[_i,6]
			Endif
			if _cTpTES =="S"
				_cRet := _aVar[_i,5]
			Endif
		Endif

	Next _i

	FWRestRows( aSaveLines )
	RestArea(_aArea)
Return(_cRet)
