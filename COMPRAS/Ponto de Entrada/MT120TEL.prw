#include "totvs.ch"

/*/{Protheus.doc} MT120TEL
PE para inclusao de campos no cabecalho do pedido de compra
@author Paulo Cesar Camata (CAMATECH)
@since 26/02/2019
@version 12.1.17
@type function
/*/
User Function MT120TEL()
	Local aArea     := GetArea()
	Local oDlg      := PARAMIXB[1]
	Local aPosGet   := PARAMIXB[2]
	Local nOpcx     := PARAMIXB[4]
	Local nRecPC    := PARAMIXB[5]
	Local lEdit     := IIF(nOpcx == 3 .Or. nOpcx == 4 .Or. nOpcx ==  9, .T., .F.) //Somente será editável, na Inclusão, Alteração e Cópia
	Local oCliCyb, oDesCli, oDesB2B
	Public cCliCyb := ""
	Public cDesCli := ""
	Public cDesB2B := ""

	//Define o conteúdo para os campos
	SC7->(DbGoTo(nRecPC))
	If nOpcx == 3
		cCliCyb := CriaVar("C7_YCLIENT", .F.)
		cDesCli := CriaVar("A1_NREDUZ", .F.)
		cDesB2B := CriaVar("C7_B2B", .F.)
	Else
		cCliCyb := SC7->C7_YCLIENT
		cDesCli := posicione("SA1", 1, xFilial("SA1") + cCliCyb, "A1_NREDUZ")
		cDesB2B := SC7->C7_B2B
	EndIf

	//Criando na janela o campo OBS
	@062, aPosGet[01, 08] - 012 SAY Alltrim(RetTitle("C7_YCLIENT")) SIZE 050,006 OF oDlg PIXEL
	@061, aPosGet[01, 09] - 006 MSGET oCliCyb VAR cCliCyb VALID left(cCliCyb, 6) == "999001" .and. existCpo("SA1") .and. fNameCyb(cCliCyb) ;
		SIZE 20, 006 OF oDlg F3 "SA1CYB" COLORS 0, 16777215 PIXEL
	@061, aPosGet[01, 09] + 037 MSGET oDesCli VAR cDesCli SIZE 100, 006 OF oDlg COLORS 0, 16777215 PIXEL

	@062, aPosGet[01, 09] + 150 SAY "B2B (S/N)? " SIZE 050,006 OF oDlg PIXEL
	@061, aPosGet[01, 09] + 180 MSGET oDesB2B VAR cDesB2B SIZE 20, 006 OF oDlg COLORS 0, 16777215 PIXEL


	oCliCyb:bHelp := {|| ShowHelpCpo( "C7_YCLIENT", {GetHlpSoluc("C7_YCLIENT")[1]}, 5)}

	//Se não houver edição, desabilita os gets
	If !lEdit
		oCliCyb:lActive := .F.
		oDesB2B:lActive := .F.
	EndIf
	oDesCli:lActive := .F.

	RestArea(aArea)
Return

static function fNameCyb(cCliCyb)
	cDesCli := posicione("SA1", 1, xFilial("SA1") + cCliCyb, "A1_NREDUZ")
return .T.
