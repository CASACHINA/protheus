#include 'protheus.ch'
#include 'parmtype.ch'
#include 'topconn.ch'


// ####################################################################################################################################################################################################
//
// Projeto   :   
// Modulo    : Faturamento
// Fonte     : uCCUST01
// Data      : 14/08/19
// Autor     : Valberg Moura 
// Descricao : Rotina para gerar tabela de custo de produto sem o ST embutido
//
// ####################################################################################################################################################################################################

User Function uCCUST01()

	Local oBtnCalc
	Local oBtnFec
	Local oBtnPar
	Local oSay1
	Local oSay2
	Local cPerg := "UCCUST01"
	Static oDlg

	Pergunte(cPerg,.F.)

	//RpcClearEnv()
	//RPCSetType(3)
	//RPCSetEnv('01','01')

	DEFINE MSDIALOG oDlg TITLE "Calculo de Custo de Tranferência" FROM 000, 000  TO 200, 500 COLORS 0, 16777215 PIXEL

	@ 015, 008 SAY oSay1 PROMPT "Esta rotina é responsável por efetuar o calculo de custo de produtos para " SIZE 196, 007 OF oDlg COLORS 0, 16777215 PIXEL
	@ 026, 008 SAY oSay2 PROMPT "transferência entre filiais sem ST no custo" SIZE 183, 007 OF oDlg COLORS 0, 16777215 PIXEL
	@ 070, 203 BUTTON oBtnFec PROMPT "Fechar" SIZE 037, 012 OF oDlg ACTION(oDlg:End()) PIXEL
	@ 070, 147 BUTTON oBtnPar PROMPT "Parametros" SIZE 037, 012 OF oDlg ACTION(Pergunte(cPerg,.T.)) PIXEL
	@ 070, 090 BUTTON oBtnCalc PROMPT "Calcular" SIZE 037, 012 OF oDlg ACTION(MsgRun("Custo de Tranferência sem ST","Gerando Custo",{|| CalcCusto()  }) , oDlg:End()) PIXEL

	ACTIVATE MSDIALOG oDlg CENTERED





Static Function CalcCusto()
	Local _cQry    := ""
	Local _dPerDe :=  Ctod('01/'+Substr(MV_PAR03,1,2) +'/'+Substr(MV_PAR03,3,4)) // Primeiro dia do mes / MV_PAR03 // -> Mes / Ano  12/2018
	Local _dPerAte  :=LastDay(_dPerDe) //Ultimo dia do Mes
	Local _dDTCusto := _dPerAte
	Local _nVlrST := 0
	Local _vCutOld := 0
	Local _cUltCalc := SuperGetMV("MV_XMESCUS", ,"")  

	//Seleciona os produtos do cadastro de produtos
	_cQry := " SELECT * FROM "+ RetSqlName("SB1")
	_cQry += " WHERE B1_FILIAL = '" + xFilial("SB1")+"'"
	_cQry += " AND B1_COD BETWEEN '"+MV_PAR01+"' AND '"+MV_PAR02+"' "
	_cQry += " AND D_E_L_E_T_ <> '*' "
	_cQry += " ORDER BY B1_COD"
	TcQuery _cQry New Alias "TSB1"

	While !TSB1->(Eof())

		_nVlrCusto := 0
		_nVlrST := 0

		//Consulta com o calculo do preço medio do produto no periodo selecionado
		_cQry := " SELECT ROUND(AVG(D1_ICMSRET/D1_QUANT),2) as VLRST FROM  "+ RetSqlName("SD1")
		_cQry += " WHERE D1_FILIAL='" + xFilial("SD1")+"'"
		_cQry += " AND D1_COD ='"+TSB1->B1_COD+"'"
		_cQry += " AND D1_DTDIGIT BETWEEN '"+DToS(_dPerDe)+"' AND '"+DToS(_dPerAte)+"'"
		_cQry += " AND D1_TIPO = 'N'
		_cQry += " AND D1_ICMSRET > 0
		_cQry += " AND D1_QUANT > 0
		_cQry += " AND D_E_L_E_T_ <>'*'


		TcQuery _cQry New Alias "TCUST"

		_nVlrST := TCUST->VLRST

		TCUST->(DBCloseArea())

		If _nVlrST >0 


			DbSelectArea("Z03")
			DbSetOrder(1)
			If DbSeek(xFilial("Z03")+DToS(_dDTCusto)+TSB1->B1_COD)
				_lNewReg := .F.
			Else
				_lNewReg := .T.
			Endif

			_vCutOld := Posicione("SB2",1,xFilial("SB2") + TSB1->B1_COD + "01", "B2_CM1")

			//Grava o Valor do Custo encontrado
			Reclock("Z03",_lNewReg)
			Z03->Z03_FILIAL := xFilial("Z03")
			Z03->Z03_DCUSTO := _dDTCusto
			Z03->Z03_PRODUT := TSB1->B1_COD
			Z03->Z03_VST    := _nVlrST
			Z03->Z03_VCUSTO := _vCutOld - _nVlrST
			MsUnlock()



			//Deleta as notas anteriores
			DbSelectArea("Z04")
			DbSetOrder(1)
			If DbSeek(xFilial("Z04")+DToS(_dDTCusto)+TSB1->B1_COD)
				While !Z04->(Eof()) .and. Z04->Z04_FILIAL==xFilial("Z04") .and. Z04->Z04_DCUSTO==_dDTCusto .and. Z04->Z04_PRODUT == TSB1->B1_COD

					Reclock("Z04",.f.)
					Z04->(DbDelete())
					Z04->(MsUnlock())

					Z04->(Dbskip())

				Enddo

			Endif


			//Seleciona as Notas que fizeram parte do calculo do custo atual

			_cQry := " SELECT D1_DOC, D1_SERIE, D1_FORNECE, D1_LOJA FROM "+ RetSqlName("SD1")
			_cQry += " WHERE D1_FILIAL= '" + xFilial("SD1")+"'"
			_cQry += " AND D1_COD ='"+TSB1->B1_COD+"'"
			_cQry += " AND D1_DTDIGIT BETWEEN '"+DToS(_dPerDe)+"' AND '"+DToS(_dPerAte)+"'"
			_cQry += " AND D1_TIPO = 'N'"
			_cQry += " AND D_E_L_E_T_ <>'*'"
			_cQry += " GROUP BY D1_DOC, D1_SERIE, D1_FORNECE, D1_LOJA "
			TcQuery _cQry New Alias "TNFENT"

			While !TNFENT->(Eof())

				//Grava as notas que foram utilizadas para gerar o valor do Custo encontrado
				Reclock("Z04",.T.)
				Z04->Z04_FILIAL := xFilial("Z04")
				Z04->Z04_DCUSTO := _dDTCusto
				Z04->Z04_PRODUT := TSB1->B1_COD
				Z04->Z04_DOC    := TNFENT->D1_DOC
				Z04->Z04_SERIE  := TNFENT->D1_SERIE
				Z04->Z04_FORNEC := TNFENT->D1_FORNECE
				Z04->Z04_LOJA   := TNFENT->D1_LOJA
				MsUnlock()
				TNFENT->(DBSkip())

			EndDo
			TNFENT->(DBCloseArea())
		EndIf
		TSB1->(DBSkip())

	EndDo
	TSB1->(DBCloseArea())

	//Salva o parametro do ultimo Calculo
	PutMv('MV_XMESCUS',MV_PAR03)


Return 