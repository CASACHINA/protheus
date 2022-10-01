// ####################################################################################################################################################################################################
//
// Projeto   : Casa China 
// Modulo    : Faturamento
// Fonte     : uRetAcCli
// Data      : 21/01/2020
// Autor     : Valberg Moura 
// Descricao : Consulta produtos
//
// ####################################################################################################################################################################################################

#INCLUDE "Topconn.ch"
#INCLUDE "Protheus.ch"

User Function uConsPrd1()                        
	Local oBtnCons                                                       
	Local oBtnFec
	Local oProd

	Private oGetProd
	Private cGetProd := Space(50)

	Static oDlg
	Static oMSNewGet


	SetKey( VK_F5,  {|| Consulta()  } )

	DEFINE MSDIALOG oDlg TITLE "Consulta informaçoes de Produtos" FROM 000, 000  TO 800, 1400 COLORS 0, 16777215 PIXEL

	@ 016, 009 SAY oProd PROMPT "Produto ( F5 )" SIZE 040, 007 OF oDlg COLORS 0, 16777215 PIXEL
	@ 014, 045 MSGET oGetProd VAR cGetProd SIZE 344, 010 PICTURE "@!" OF oDlg COLORS 0, 16777215 PIXEL
	@ 014, 390 BUTTON oBtnCons PROMPT "Consultar" SIZE 037, 012 Action(Consulta()) OF oDlg PIXEL
	fGrid()
	@ 014, 654 BUTTON oBtnFec PROMPT "Fechar" SIZE 037, 012 Action(oDlg:End() )OF oDlg PIXEL

	ACTIVATE MSDIALOG oDlg CENTERED

Return

//------------------------------------------------ 
Static Function fGrid()
	//------------------------------------------------ 
	Local nX
	Local aHeaderEx := {}
	Local aColsEx := {}
	Local aFieldFill := {}
	Local aFields := {'B1_COD', 'B1_CODBAR', 'B1_DESC', 'B2_QATU','DA1_PRCVEN'}
	Local aAlterFields := {}

	// Define field properties
	DbSelectArea("SX3")
	SX3->(DbSetOrder(2))
	For nX := 1 to Len(aFields)
		If SX3->(DbSeek(aFields[nX]))

		Aadd(aHeaderEx, {   TRIM(FwX3Titulo(aFields[nX])),;
                        aFieldsACC[nPos],;
                        GetSx3Cache(aFields[nX], "X3_PICTURE"),;
                        GetSx3Cache(aFields[nX], "X3_TAMANHO"),;
                        GetSx3Cache(aFields[nX], "X3_DECIMAL"),;
                        GetSx3Cache(aFields[nX], "X3_VALID"),;
                        GetSx3Cache(aFields[nX], "X3_USADO" ),;
                        FWSX3Util():GetFieldType( aFields[nX]),;
                        GetSx3Cache(aFields[nX], "X3_F3"),;
                        GetSx3Cache(aFields[nX], "X3_CONTEXT"),;
                        GetSx3Cache(aFields[nX], "X3_CBOX"   ),;
                        GetSx3Cache(aFields[nX], "X3_RELACAO"),;
                        ".T."})
			//Aadd(aHeaderEx, {AllTrim(X3Titulo()),SX3->X3_CAMPO,SX3->X3_PICTURE,SX3->X3_TAMANHO,SX3->X3_DECIMAL,SX3->X3_VALID,;
			//SX3->X3_USADO,SX3->X3_TIPO,SX3->X3_F3,SX3->X3_CONTEXT,SX3->X3_CBOX,SX3->X3_RELACAO})
		Endif
	Next nX

	// Define field values
	For nX := 1 to Len(aFields)
		If DbSeek(aFields[nX])
			Aadd(aFieldFill, CriaVar(SX3->X3_CAMPO))
		Endif
	Next nX
	Aadd(aFieldFill, .F.)
	Aadd(aColsEx, aFieldFill)

	oMSNewGet := MsNewGetDados():New( 033, 009, 393, 692, /*GD_INSERT+GD_DELETE+GD_UPDATE*/, "AllwaysTrue", "AllwaysTrue", "+Field1+Field2", aAlterFields,, 999, "AllwaysTrue", "", "AllwaysTrue", oDlg, aHeaderEx, aColsEx)

Return


Static Function Consulta()
	Local _cConsulta := Alltrim(cGetProd)

	_aCols := {}

	If _cConsulta <> ""

	//FALTA referencia e fornecedor do produto

		_cQry := " SELECT B1_COD, B1_CODBAR, B1_DESC, B2_QATU FROM "+ RetSqlName("SB1") +" SB1"
		_cQry += " INNER JOIN SB2010 SB2 ON (B2_FILIAL='"+xFilial("SB2")+"' AND B2_COD= B1_COD AND B2_LOCAL= '01' AND B2_QATU > 0 AND SB2.D_E_L_E_T_ ='')"
		_cQry += " WHERE SB1.D_E_L_E_T_ =''"
		_cQry += " AND ( B1_COD LIKE '%"+_cConsulta+"%'"
		_cQry += " 		OR B1_DESC LIKE '%"+_cConsulta+"%'"
		_cQry += " 		OR B1_CODBAR LIKE '%"+_cConsulta+"%' )"
		_cQry += " AND B1_TIPO IN ('PA','ME')"
		TcQuery _cQry New Alias "TCONS"

		While !TCONS->(Eof())

			_cPreco := 0

			If SM0->M0_ESTENT == 'PR'
				_cPreco := Posicione("DA1",1,xFilial("DA1")+'001'+TCONS->B1_COD,'DA1_PRCVEN')
			Else
				_cPreco := Posicione("DA1",1,xFilial("DA1")+'002'+TCONS->B1_COD,'DA1_PRCVEN')
			Endif

			aAdd(_aCols,{ TCONS->B1_COD,TCONS->B1_CODBAR,TCONS->B1_DESC, B2_QATU, _cPreco, .F. })

			TCONS->(DbSkip())

		Enddo
		TCONS->(DbCloseArea())
	Endif

	oMSNewGet:nAT := 1 
	oMSNewGet:aCols := aClone(_aCols)
	oMSNewGet:Refresh()

	oDlg:Refresh()

	oGetProd:SetFocus()


Return
