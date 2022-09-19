// ####################################################################################################################################################################################################
//
// Projeto   :   
// Modulo    : Faturamento
// Fonte     : uPEDVCSV
// Data      : 28/05/2020
// Autor     : Valberg Moura 
// Descricao : Rotina para gerar Pedido de venda por importação de arquivo CSV
//
// ####################################################################################################################################################################################################


#Include "TOTVS.CH"

User Function uPEDVCSV()

	Local oButton1
	Local oButton2
	Local oGetArq
	Local oSay1
	Static oDlg
	Private cGetArq := SPACE(100)
	Private cGetTab := SPACE(3)
	Private _aCabec := {}
	Private _aitens := {}

	DEFINE MSDIALOG oDlg TITLE "Importar Arquivo CSV" FROM 000, 000  TO 200, 500 COLORS 0, 16777215 PIXEL

	@ 014, 006 SAY oSay1 PROMPT "Arquivo :" SIZE 025, 007 OF oDlg COLORS 0, 16777215 PIXEL
	@ 014, 036 MSGET oGetArq VAR cGetArq SIZE 202, 010 OF oDlg COLORS 0, 16777215 PIXEL
	@ 063, 131 BUTTON oButton1 PROMPT "Confirma" Action(Processa( {|| ConfCSV() }, "Importando Arquivo...", "Aguarde..."),oDlg:End()) SIZE 072, 021 OF oDlg PIXEL
	@ 063, 025 BUTTON oButton2 PROMPT "Fechar" Action(oDlg:End()) SIZE 072, 022 OF oDlg PIXEL

	ACTIVATE MSDIALOG oDlg CENTERED


Return

Static Function ConfCSV()

	Local cArq    := Alltrim(cGetArq)
	Local cDir    := ""
	Local cLinha  := ""
	Local lPrim   := .T.
	Local aCampos := {}
	Local aDados  := {}
	Local i := 1
	Private aErro := {}


	If !MSGYESNO( "Confirma a execução da rotina ?", "Importa CSV" )
		Return()
	Endif

	If !File(cDir+cArq)
		MsgStop("O arquivo " +cDir+cArq + " não foi encontrado. A importação será abortada!","[AEST901] - ATENCAO")
		Return
	EndIf

	FT_FUSE(cDir+cArq)
	ProcRegua(FT_FLASTREC())
	FT_FGOTOP()
	While !FT_FEOF()

		IncProc("Lendo arquivo texto...")

		cLinha := FT_FREADLN()

		If lPrim
			aCampos := Separa(cLinha,";",.T.)
			lPrim := .F.
		Else
			AADD(aDados,Separa(cLinha,";",.T.))
		EndIf

		FT_FSKIP()
	EndDo
	FT_FUSE()

	If Len(aDados) > 99
		Alert("A T E N Ç Ã O , só é possivel ter no maximo 99 itens no arquivo")
		Return()
	Endif

	//-----------------------------------------------------------------------------------
	// Montando Arry para gerar SC5
	//-----------------------------------------------------------------------------------
	_cCliente := aDados[1,2]
	_cLoja    := aDados[1,3]
	_aCabPED := {}
	aAdd(_aCabPED,{"C5_TIPO"   	,"N"         			,Nil}) // Tipo de pedido
	aAdd(_aCabPED,{"C5_CLIENTE"	,_cCliente      		,Nil}) // Codigo do cliente
	aAdd(_aCabPED,{"C5_LOJACLI"	,_cLoja         		,Nil}) // Loja do cliente
	aAdd(_aCabPED,{"C5_CLIENT" 	,_cCliente              ,Nil}) // Codigo do cliente
	aAdd(_aCabPED,{"C5_LOJAENT"	,_cLoja                	,Nil}) // Loja para entrada
	aAdd(_aCabPED,{"C5_CONDPAG"	,"001"  		        ,Nil}) // Codigo da condicao de pagamanto - SE4
	//aAdd(_aCabPED,{"C5_EMISSAO"	,dDataBase          	,Nil}) // Data de emissao
	aAdd(_aCabPED,{"C5_TIPLIB" 	,"1"              	   	,Nil})
	aAdd(_aCabPED,{"C5_MOEDA"  	,1                		,Nil}) // Moeda
	aAdd(_aCabPED,{"C5_LIBEROK"	,"S"              		,Nil}) // Liberacao Total


	IncProc("Importando Tabela Generica...")


	ProcRegua(Len(aDados))

	_aItemPed := {}
	For i:=1 to Len(aDados)

		_C6_PRODUTO := aDados[i,4]
		_C6_QTDVEN  := val(aDados[i,8])
		_C6_PRCVEN  := val(aDados[i,10])
		_C6_TES     := aDados[i,6]
		_C6_LOCAL   := aDados[i,7]
		_C6_PRUNIT  := val(aDados[i,11])
		_C6_OPER    := aDados[i,12]

		//TES inteligente
		If Alltrim(_C6_OPER) <> ""
			_C6_TES := MATESINT( 2, _C6_OPER, _cCliente, _cLoja, "C", _C6_PRODUTO )
		ENDIF

		_aItemAux:={}
		aAdd(_aItemAux,{"C6_ITEM"   , StrZero(i,2)     			,Nil})
		aAdd(_aItemAux,{"C6_PRODUTO", _C6_PRODUTO   			,Nil})
		aAdd(_aItemAux,{"C6_LOCAL"  , _C6_LOCAL          		,Nil})
		//aAdd(_aItemAux,{"C6_ENTREG" , dDataBase          		,Nil})
		aAdd(_aItemAux,{"C6_QTDVEN" , _C6_QTDVEN  				,Nil})
		aAdd(_aItemAux,{"C6_PRCVEN" , _C6_PRCVEN				,Nil})
		aAdd(_aItemAux,{"C6_VALOR"  , _C6_QTDVEN * _C6_PRCVEN 	,Nil})
		If Alltrim(_C6_TES) <> ""
			aAdd(_aItemAux,{"C6_TES"    , _C6_TES				,Nil})
		Endif
		aAdd(_aItemAux,{"C6_PRUNIT" , _C6_PRUNIT				,Nil})
		aAdd(_aItemAux,{"C6_OPER"   , _C6_OPER					,Nil})
		aAdd(_aItemPed,_aItemAux)

	Next i

	lMsErroAuto := .F.
	MsExecAuto({|x,y,z| Mata410(x,y,z)},_aCabPED,_aItemPed,3)

	If lMsErroAuto
		MostraErro()
		RETURN
	EndIf


	ApMsgInfo("Pedido de VEnda N. "+SC5->C5_NUM+" gerado com sucesso!","[PEDCSV001] - SUCESSO")

Return

