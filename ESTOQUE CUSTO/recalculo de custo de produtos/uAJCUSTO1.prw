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

	xPutSx1('uAJUCUST','01','Produto de  ?','','','MV_CH01','C' ,15,0,0,'G','','SB1', '','','MV_PAR01') 
	xPutSx1('uAJUCUST','02','Produto ate ?','','','MV_CH02','C' ,15,0,0,'G','','SB1', '','','MV_PAR02') 
	xPutSx1('uAJUCUST','03','Armazem     ?','','','MV_CH03','C' ,02,0,0,'G','','', '','','MV_PAR03') 
	xPutSx1('uAJUCUST','04','Tabela Base Custo?','','','MV_CH04','C' ,03,0,0,'G','','DA0', '','','MV_PAR04') 

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



Static Function xPutSx1(cGrupo,cOrdem,cPergunt,cPerSpa,cPerEng,cVar,; 
	cTipo ,nTamanho,nDecimal,nPresel,cGSC,cValid,; 
	cF3, cGrpSxg,cPyme,; 
	cVar01,cDef01,cDefSpa1,cDefEng1,cCnt01,; 
	cDef02,cDefSpa2,cDefEng2,; 
	cDef03,cDefSpa3,cDefEng3,; 
	cDef04,cDefSpa4,cDefEng4,; 
	cDef05,cDefSpa5,cDefEng5,; 
	aHelpPor,aHelpEng,aHelpSpa,cHelp) 

	LOCAL aArea := GetArea() 
	Local cKey 
	Local lPort := .f. 
	Local lSpa := .f. 
	Local lIngl := .f. 

	cKey := "P." + AllTrim( cGrupo ) + AllTrim( cOrdem ) + "." 

	cPyme    := Iif( cPyme           == Nil, " ", cPyme          ) 
	cF3      := Iif( cF3           == NIl, " ", cF3          ) 
	cGrpSxg := Iif( cGrpSxg     == Nil, " ", cGrpSxg     ) 
	cCnt01   := Iif( cCnt01          == Nil, "" , cCnt01      ) 
	cHelp      := Iif( cHelp          == Nil, "" , cHelp          ) 

	dbSelectArea( "SX1" ) 
	dbSetOrder( 1 ) 

	cGrupo := PadR( cGrupo , Len( SX1->X1_GRUPO ) , " " ) 

	If !( DbSeek( cGrupo + cOrdem )) 

		cPergunt:= If(! "?" $ cPergunt .And. ! Empty(cPergunt),Alltrim(cPergunt)+" ?",cPergunt) 
		cPerSpa     := If(! "?" $ cPerSpa .And. ! Empty(cPerSpa) ,Alltrim(cPerSpa) +" ?",cPerSpa) 
		cPerEng     := If(! "?" $ cPerEng .And. ! Empty(cPerEng) ,Alltrim(cPerEng) +" ?",cPerEng) 

		Reclock( "SX1" , .T. ) 

		Replace X1_GRUPO   With cGrupo 
		Replace X1_ORDEM   With cOrdem 
		Replace X1_PERGUNT With cPergunt 
		Replace X1_PERSPA With cPerSpa 
		Replace X1_PERENG With cPerEng 
		Replace X1_VARIAVL With cVar 
		Replace X1_TIPO    With cTipo 
		Replace X1_TAMANHO With nTamanho 
		Replace X1_DECIMAL With nDecimal 
		Replace X1_PRESEL With nPresel 
		Replace X1_GSC     With cGSC 
		Replace X1_VALID   With cValid 

		Replace X1_VAR01   With cVar01 

		Replace X1_F3      With cF3 
		Replace X1_GRPSXG With cGrpSxg 

		If Fieldpos("X1_PYME") > 0 
			If cPyme != Nil 
				Replace X1_PYME With cPyme 
			Endif 
		Endif 

		Replace X1_CNT01   With cCnt01 
		If cGSC == "C"               // Mult Escolha 
			Replace X1_DEF01   With cDef01 
			Replace X1_DEFSPA1 With cDefSpa1 
			Replace X1_DEFENG1 With cDefEng1 

			Replace X1_DEF02   With cDef02 
			Replace X1_DEFSPA2 With cDefSpa2 
			Replace X1_DEFENG2 With cDefEng2 

			Replace X1_DEF03   With cDef03 
			Replace X1_DEFSPA3 With cDefSpa3 
			Replace X1_DEFENG3 With cDefEng3 

			Replace X1_DEF04   With cDef04 
			Replace X1_DEFSPA4 With cDefSpa4 
			Replace X1_DEFENG4 With cDefEng4 

			Replace X1_DEF05   With cDef05 
			Replace X1_DEFSPA5 With cDefSpa5 
			Replace X1_DEFENG5 With cDefEng5 
		Endif 

		Replace X1_HELP With cHelp 

		PutSX1Help(cKey,aHelpPor,aHelpEng,aHelpSpa) 

		MsUnlock() 
	Else 

		lPort := ! "?" $ X1_PERGUNT .And. ! Empty(SX1->X1_PERGUNT) 
		lSpa := ! "?" $ X1_PERSPA .And. ! Empty(SX1->X1_PERSPA) 
		lIngl := ! "?" $ X1_PERENG .And. ! Empty(SX1->X1_PERENG) 

		If lPort .Or. lSpa .Or. lIngl 
			RecLock("SX1",.F.) 
			If lPort 
				SX1->X1_PERGUNT:= Alltrim(SX1->X1_PERGUNT)+" ?" 
			EndIf 
			If lSpa 
				SX1->X1_PERSPA := Alltrim(SX1->X1_PERSPA) +" ?" 
			EndIf 
			If lIngl 
				SX1->X1_PERENG := Alltrim(SX1->X1_PERENG) +" ?" 
			EndIf 
			SX1->(MsUnLock()) 
		EndIf 
	Endif 

	RestArea( aArea ) 

Return