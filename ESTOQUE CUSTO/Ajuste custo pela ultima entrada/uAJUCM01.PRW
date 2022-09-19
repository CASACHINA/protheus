// ####################################################################################################################################################################################################
//
// Projeto   : Ajuste de Custo Total para o mes de Agosto/2019  
// Modulo    : Estoque / Custo
// Fonte     : uAJUCM01
// Data      : 10/10/2019
// Autor     : Valberg Moura 
// Descricao : Gera ajuste de custo na data de 31/08/2019, com base na ultima entrada do produto 
//
// ####################################################################################################################################################################################################


#include 'protheus.ch'
#include 'parmtype.ch'
#include 'topconn.ch'


user function uAJUCM01()

	If __cUserID <> "000000"
		Alert("Somente o usuario Administrador tem permissão para executar esta rotina.")
		Return()
	Endif

	If cFilAnt $ '010101,010102,010105,010108' //Filiais do parana

		Processa({|| CopiaPR() ,"Atualizando Custo de Entrada"})

	Else
		Processa({|| Ajusta() ,"Atualizando Custo de Entrada"})

	Endif



Return

Static function Ajusta()

	Local _aItem := {}
	Local _aOK    := {}
	Local _aErro  := {}
	Local _cQry   := ''
	Local _nCusto := 0
	Private lMsErroAuto := .F.
	Private _cArmazem := '01' 
	Private _dDataAjuste := Ctod('31/08/2019')



	IF !MsgNoYes( "Confirma a execução da rotina de ajuste de custo?", "Ajuste de Custo" )
		Return()
	Endif


	//SELECIONA TODOS OS PRODUTOS DA B2 COM ESTOQUE
	_cQry := " SELECT * FROM "+RetSqlName("SB2")
	_cQry += " WHERE B2_FILIAL= '"+xFilial("SB2")+"'"
	_cQry += " AND B2_LOCAL = '"+_cArmazem+"'"
	_cQry += " AND D_E_L_E_T_=''"
	_cQry += " ORDER BY B2_COD"
	Tcquery _cQry New Alias "TRSB2"

	While !TRSB2->(Eof())

		//SELECIONA A ULTIMA ENTRADA DO PRODUTO
		_cQry := " SELECT TOP 1 ROUND(D1_CUSTO/D1_QUANT,4) AS CUSTO  FROM "+RetSqlName("SD1")+ " SD1"
		_cQry += " INNER JOIN "+RetSqlName("SF4")+" SF4 ON (F4_CODIGO = D1_TES AND F4_ESTOQUE ='S' AND SF4.D_E_L_E_T_='')"
		_cQry += " WHERE D1_FILIAL= '"+xFilial("SD1")+"'"
		_cQry += " AND D1_COD = '"+TRSB2->B2_COD+"'"
		_cQry += " AND D1_TIPO ='N'"
		_cQry += " AND D1_LOCAL = '"+_cArmazem+"'"
		_cQry += " AND D1_EMISSAO <= '"+DtoS(_dDataAjuste)+"'"
		_cQry += " AND D1_FORNECE <> '999001'"
		_cQry += " AND SD1.D_E_L_E_T_=''"
		_cQry += " AND D1_QUANT > 0""
		_cQry += " ORDER BY D1_EMISSAO DESC"	
		Tcquery _cQry New Alias "TRSD1"

		_nCusto := TRSD1->CUSTO

		TRSD1->(DbcloseArea())

		//Caso não tenha nota de Entrada
		//60% do valor da tabela de preço selecionada
		_cTblPreco := '001' //002 - SC
		If _nCusto == 0 //.and. TRSB2->B2_QATU >0
			DbSelectArea('DA1')
			DbSetORder(1)
			If Dbseek(xFilial('DA1')+_cTblPreco+TRSB2->B2_COD)
				_nCusto := DA1->DA1_PRCVEN * 0.60
			Endif
		Endif

		If _nCusto > 0

			//LOCALIZA TODOS OS ARMAZENS DO PRODUTO
			_cQry := " SELECT B2_LOCAL  FROM  "+RetSqlName("SB2")
			_cQry += " WHERE B2_FILIAL='"+xFilial("SB2")+"'"
			_cQry += " AND B2_COD = '"+TRSB2->B2_COD+"'"
			_cQry += " AND B2_LOCAL <>''"
			_cQry += " AND D_E_L_E_T_=''"
			_cQry += " ORDER BY  B2_LOCAL
			Tcquery _cQry New Alias "TRARM"

			While !TRARM->(Eof())

				//VERIFICA SE JA EXISTE O AJUSTE DO PRODUTO NA DATA CORRENTE
				_cQry := " SELECT COUNT(*) AS QUANT FROM "+RetSqlName("SDQ")
				_cQry += " WHERE DQ_FILIAL= '"+xFilial("SDQ")+"'"
				_cQry += " AND DQ_COD = '"+TRSB2->B2_COD+"'"
				_cQry += " AND DQ_LOCAL = '"+TRARM->B2_LOCAL+"'"
				_cQry += " AND DQ_DATA ='"+DtoS(_dDataAjuste)+"'"
				_cQry += " AND D_E_L_E_T_=''"
				Tcquery _cQry New Alias "TRSDQ"

				If TRSDQ->QUANT == 0 

					_aItem := {}
					aAdd(_aItem,{"DQ_COD"  ,TRSB2->B2_COD,Nil})
					aAdd(_aItem,{"DQ_LOCAL",TRARM->B2_LOCAL ,Nil})
					aAdd(_aItem,{"DQ_DATA" ,_dDataAjuste ,Nil})
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

				TRARM->(Dbskip())
			Enddo
			TRARM->(DbcloseArea())
		Endif
		TRSB2->(Dbskip())
	Enddo
	TRSB2->(DbcloseArea())


return



Static Function CopiaPR()
	Local _aItem := {}
	Local _aOK    := {}
	Local _aErro  := {}
	Local _cQry   := ''
	Local _nCusto := 0
	Private lMsErroAuto := .F.
	Private _cArmazem := '01' 
	Private _dDataAjuste := Ctod('31/08/2019')

	IF !MsgNoYes( "<CopiaPR> Confirma a execução da rotina de ajuste de custo?", "Ajuste de Custo" )
		Return()
	Endif


	//SELECIONA TODOS OS PRODUTOS DA B2 COM ESTOQUE
	_cQry := " SELECT * FROM "+RetSqlName("SB2")
	_cQry += " WHERE B2_FILIAL= '"+xFilial("SB2")+"'"
	_cQry += " AND B2_LOCAL <> ''" //"+_cArmazem+"'"
	_cQry += " AND D_E_L_E_T_=''"
	_cQry += " ORDER BY B2_COD,B2_LOCAL"
	Tcquery _cQry New Alias "TRSB2"

	While !TRSB2->(Eof())

		//localizada o registro na filial 010104
		_cQry := " SELECT * FROM "+RetSqlName("SDQ")
		_cQry += " WHERE DQ_FILIAL= '010104'"
		_cQry += " AND DQ_COD = '"+TRSB2->B2_COD+"'"
		_cQry += " AND DQ_LOCAL = '"+TRSB2->B2_LOCAL+"'"
		_cQry += " AND DQ_DATA ='"+DtoS(_dDataAjuste)+"'"
		_cQry += " AND D_E_L_E_T_=''"
		Tcquery _cQry New Alias "MOVDQ"

		While !MOVDQ->(Eof())

			//VERIFICA SE JA EXISTE O AJUSTE DO PRODUTO NA DATA CORRENTE
			_cQry := " SELECT COUNT(*) AS QUANT FROM "+RetSqlName("SDQ")
			_cQry += " WHERE DQ_FILIAL= '"+xFilial("SDQ")+"'"
			_cQry += " AND DQ_COD = '"+TRSB2->B2_COD+"'"
			_cQry += " AND DQ_LOCAL = '"+TRSB2->B2_LOCAL+"'"
			_cQry += " AND DQ_DATA ='"+DtoS(_dDataAjuste)+"'"
			_cQry += " AND D_E_L_E_T_=''"
			Tcquery _cQry New Alias "TRSDQ"

			If TRSDQ->QUANT == 0 

				_aItem := {}
				aAdd(_aItem,{"DQ_COD"  ,TRSB2->B2_COD,Nil})
				aAdd(_aItem,{"DQ_LOCAL",TRSB2->B2_LOCAL ,Nil})
				aAdd(_aItem,{"DQ_DATA" ,_dDataAjuste ,Nil})
				aAdd(_aItem,{"DQ_CM1"  ,MOVDQ->DQ_CM1,Nil})


				MSExecAuto({|x,y,z| MATA338(x,y)},_aItem,3) 
				If !lMsErroAuto 
					aAdd(_aOK,{TRSB2->B2_COD,MOVDQ->DQ_CM1}) 
				Else 

					MostraErro()

					aAdd(_aErro,{TRSB2->B2_COD,MOVDQ->DQ_CM1}) 
				EndIf
			Endif
			TRSDQ->(DbcloseArea())


			MOVDQ->(Dbskip())
		Enddo
		MOVDQ->(DbcloseArea())


		TRSB2->(Dbskip())
	Enddo
	TRSB2->(DbcloseArea())


Return()