// ####################################################################################################################################################################################################
//
// Projeto   : Casa China 
// Modulo    : Faturamento
// Fonte     : uConsPB2B
// Data      : 21/01/2020
// Autor     : Valberg Moura 
// Descricao : Consulta pedido B2B
//
// ####################################################################################################################################################################################################

#INCLUDE "Topconn.ch"
#INCLUDE "Protheus.ch"

User Function uConsPB2B()
	Local oBtnCons
	Local oBtnFec
	Local oProd

	Private oGetProd
	Private cGetProd := Space(50)

	Static oDlg
	Static oMSNewGet


	SetKey( VK_F5,  {|| Consulta()  } )

	DEFINE MSDIALOG oDlg TITLE "Consulta Pedidos B2B" FROM 000, 000  TO 800, 1400 COLORS 0, 16777215 PIXEL

	@ 016, 009 SAY oProd PROMPT "Pedido ( F5 )" SIZE 040, 007 OF oDlg COLORS 0, 16777215 PIXEL
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
	Local aFields := {'C5_NUM', 'C5_CLIENTE', 'C5_LOJACLI', 'C5_XNREDUZ','C5_NOTA', 'C5_SERIE'}
	Local aAlterFields := {}


	//adicona o campo de data processamenteo WMS
	DbSelectArea("SX3")
	SX3->(DbSetOrder(2))
	SX3->(DbSeek("C5_XNREDUZ"))
	Aadd(aHeaderEx, {"LIB WMS",SX3->X3_CAMPO,SX3->X3_PICTURE,10,SX3->X3_DECIMAL,SX3->X3_VALID,;
		SX3->X3_USADO,SX3->X3_TIPO,SX3->X3_F3,SX3->X3_CONTEXT,SX3->X3_CBOX,SX3->X3_RELACAO})

	// Define field properties
	DbSelectArea("SX3")
	SX3->(DbSetOrder(2))
	For nX := 1 to Len(aFields)
		If SX3->(DbSeek(aFields[nX]))
			Aadd(aHeaderEx, {AllTrim(X3Titulo()),SX3->X3_CAMPO,SX3->X3_PICTURE,SX3->X3_TAMANHO,SX3->X3_DECIMAL,SX3->X3_VALID,;
				SX3->X3_USADO,SX3->X3_TIPO,SX3->X3_F3,SX3->X3_CONTEXT,SX3->X3_CBOX,SX3->X3_RELACAO})
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


	//funcao de consulta do pedido
	Consulta()

Return


Static Function Consulta()
	Local _cConsulta := Alltrim(cGetProd)

	_aCols := {}



	//FALTA referencia e fornecedor do produto

	_cQry := " SELECT DISTINCT "
	_cQry += " C5_NUM, "
	_cQry += " C5_CLIENTE,"
	_cQry += " C5_LOJACLI,"
	_cQry += " C5_XNREDUZ,"
	_cQry += " C5_NOTA,"
	_cQry += " C5_SERIE,"
	_cQry += " (SELECT TOP 1 PROCESSAMENTO FROM TOTVS_CYBERLOG_SAIDA WHERE COD_CYBERLOG_SAIDA = C5_FILIAL+C5_NUM ) AS WMS "
	_cQry += " FROM SC5010 "
	_cQry += " WHERE C5_FILIAL ='010104'"
	If Alltrim(_cConsulta) <> ''
		_cQry += " AND C5_NUM = '"+_cConsulta+"'"
	Endif
	_cQry += " AND C5_B2B='S'"
	_cQry += " AND D_E_L_E_T_ =''"
	_cQry += " ORDER BY C5_NUM"

	TcQuery _cQry New Alias "TCONS"

	While !TCONS->(Eof())


		aAdd(_aCols,{  TCONS->WMS, TCONS->C5_NUM,TCONS->C5_CLIENTE,TCONS->C5_LOJACLI, TCONS->C5_XNREDUZ, TCONS->C5_NOTA, TCONS->C5_SERIE,.F. })

		TCONS->(DbSkip())

	Enddo
	TCONS->(DbCloseArea())


	oMSNewGet:nAT := 1
	oMSNewGet:aCols := aClone(_aCols)
	oMSNewGet:Refresh()

	oDlg:Refresh()

	oGetProd:SetFocus()


Return
