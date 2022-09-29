#include 'protheus.ch'
#include 'parmtype.ch'
#include 'topconn.ch'

//-----------------------------------------------------------------------
/*/{Protheus.doc} uAJCUSTO1

Rotina, para recalculo de custo de produtos, utilizando a rotina automática MATA338. 
Para este recalculo, será utilizado a ultima entrada do produto o valor no campo D1_CUSTO e o saldo em estoque do campo B2_QATU.  
Com parâmetros de Produtos “De” “Ate“  e "Armazem"

@author Valberg Moura (3VM Solutions) 
@since 26/03/2019
@version 1.0 
/*/
//-----------------------------------------------------------------------

user function uAJCUSTO1()


	Local _oBtnCanc
	Local _oBtnConf
	Local _oClient
	Local _oNumPEd
	Local oButton1
	Static oDlg

	//xPutSx1('uAJUCUST','01','Produto de  ?','','','MV_CH01','C' ,15,0,0,'G','','SB1', '','','MV_PAR01') 
	//xPutSx1('uAJUCUST','02','Produto ate ?','','','MV_CH02','C' ,15,0,0,'G','','SB1', '','','MV_PAR02') 
	//xPutSx1('uAJUCUST','03','Armazem     ?','','','MV_CH03','C' ,02,0,0,'G','','', '','','MV_PAR03') 
	//xPutSx1('uAJUCUST','04','Tabela Base Custo?','','','MV_CH04','C' ,03,0,0,'G','','DA0', '','','MV_PAR04') 

	Pergunte('uAJUCUST',.T.)

	DEFINE MSDIALOG oDlg TITLE "Ajuste de Custo" FROM 000, 000  TO 200, 400 COLORS 0, 16777215 PIXEL

	@ 017, 010 SAY _oClient PROMPT "Esta Rotina tem por objetivo, ajustar os custos dos  produtos" SIZE 165, 007 OF oDlg COLORS 0, 16777215 PIXEL
	@ 031, 010 SAY _oNumPEd PROMPT "comforme parametros, com base na ultima entrada de Nota Fiscal" SIZE 167, 007 OF oDlg COLORS 0, 16777215 PIXEL
	
	@ 061, 005 BUTTON oButton1 PROMPT "Cancela" SIZE 055, 018 OF oDlg ACTION (oDlg:End()) PIXEL
	@ 061, 065 BUTTON _oBtnCanc PROMPT "Parametro" SIZE 055, 018 OF oDlg ACTION (Pergunte('uAJUCUST',.T.)) PIXEL
	@ 061, 125 BUTTON _oBtnConf PROMPT "Confirma" SIZE 055, 018 OF oDlg ACTION(Processa({|| Ajusta() },"Aguarde, efetuando o processo de Ajuste de Custo..."), oDlg:End())  PIXEL

	ACTIVATE MSDIALOG oDlg CENTERED


	Aviso('Atenção',AllTrim(cUserName)+', rotina para ajustar custo de produtos executada com sucesso.' + CHR(13)+CHR(10) +' ' + CHR(13)+CHR(10) + 'Faz-se necessário a execução da rotina de RECALCULO DE CUSTO MEDIO.',{'OK'},,)


Return

Static function Ajusta()

	Local _aItem := {}
	Local _aOK    := {}
	Local _aErro  := {}
	Local _cQry   := ''
	Local _nCusto := 0
	Private lMsErroAuto := .F.
	Private _cProdDe := MV_PAR01
	Private _cProdAte := MV_PAR02
	Private _cArmazem := MV_PAR03
	Private _cTblPreco := MV_PAR04


	IF !MsgNoYes( "Confirma a execução da rotina de ajuste de custo?", "Ajuste de Custo" )
		Return()
	Endif



	//SELECIONA TODOS OS PRODUTOS DA B2 COM ESTOQUE
	_cQry := " SELECT * FROM "+RetSqlName("SB2")
	_cQry += " WHERE B2_FILIAL= '"+xFilial("SB2")+"'"
	_cQry += " AND B2_COD BETWEEN '"+_cProdDe+"' AND '"+_cProdAte+"'"
	_cQry += " AND B2_QATU > 0"
	_cQry += " AND B2_LOCAL = '"+_cArmazem+"'"
	_cQry += " AND D_E_L_E_T_=''"
	_cQry += " ORDER BY B2_COD"
	Tcquery _cQry New Alias "TRSB2"

	While !TRSB2->(Eof())

		//SELECIONA A ULTIMA ENTRADA DO PRODUTO
		_cQry := " SELECT TOP 1 ROUND(D1_CUSTO/D1_QUANT,4) AS CUSTO  FROM "+RetSqlName("SD1")
		_cQry += " WHERE D1_FILIAL= '"+xFilial("SD2")+"'"
		_cQry += " AND D1_COD = '"+TRSB2->B2_COD+"'"
		_cQry += " AND D1_TIPO ='N'"
		_cQry += " AND D1_LOCAL = '"+_cArmazem+"'"
		_cQry += " AND D_E_L_E_T_=''"
		_cQry += " ORDER BY D1_EMISSAO DESC"	
		Tcquery _cQry New Alias "TRSD1"

		_nCusto := TRSD1->CUSTO
		
		//Caso não tenha nota de Entrada
		//70% do valor da tabela de preço selecionada
		If _nCusto == 0
			DbSelectArea('DA1')
			DbSetORder(1)
			If Dbseek(xFilial('DA1')+_cTblPreco+TRSB2->B2_COD)
				_nCusto := DA1->DA1_PRCVEN * 0.70
			Endif
		Endif
		

		TRSD1->(DbcloseArea())

		//VERIFICA SE JA EXISTE O AJUSTE DO PRODUTO NA DATA CORRENTE
		_cQry := " SELECT COUNT(*) AS QUANT FROM SDQ010
		_cQry += " WHERE DQ_FILIAL= '"+xFilial("SDQ")+"'"
		_cQry += " AND DQ_COD = '"+TRSB2->B2_COD+"'"
		_cQry += " AND DQ_DATA ='"+DtoS(dDATABASE)+"'"
		_cQry += " AND D_E_L_E_T_=''"
		Tcquery _cQry New Alias "TRSDQ"

		If TRSDQ->QUANT == 0


			_aItem := {}
			aAdd(_aItem,{"DQ_COD"  ,TRSB2->B2_COD,Nil})
			aAdd(_aItem,{"DQ_LOCAL",_cArmazem ,Nil})
			aAdd(_aItem,{"DQ_DATA" ,dDATABASE ,Nil})
			aAdd(_aItem,{"DQ_CM1"  ,_nCusto ,Nil})


			MSExecAuto({|x,y,z| MATA338(x,y)},_aItem,3) 
			If !lMsErroAuto 
				aAdd(_aOK,{TRSB2->B2_COD,_nCusto}) 
			Else 

				MostraErro()

				aAdd(_aErro,{TRSB2->B2_COD,_nCusto}) 
			EndIf
		Endif

		TRSDQ->(DbcloseArea())

		TRSB2->(Dbskip())
	Enddo
	TRSB2->(DbcloseArea())


return


