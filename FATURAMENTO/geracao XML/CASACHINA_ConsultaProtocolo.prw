#include 'protheus.ch'


static cURL

user function CCConsProt()

	Local aLines := {}
	Local cFile, cDirectory

	//url do TSS
	cURL  := PadR(GetNewPar("MV_SPEDURL","http://"),250)

	IF MyPergunte()

		cFile := alltrim(mv_par01)
		cDirectory := alltrim(mv_par02)
		cDirectory := IIf( Right( cDirectory, 1 ) <> "\",  cDirectory + "\" , cDirectory )

		//le o arquivo e coloca dentro de um array
		FwMsgRun(, {|| aLines := readFile(cFile) }, "Leitura...", "Lendo arquivo CSV")

		varInfo('aLines', aLines)

		//percorre o array
		Processa({|lEnd| QueryAndExport(aLines, cDirectory, @lEnd) })

	EndIF

return


static function MyPergunte()

	Local cTitle  := "Consulta Protocolos"
	Local aFields := {}

	aAdd(aFields, { 1, "Arquivo com Entidades e ID" , space(200),"@!", "" ,"DIR", /*when*/,100,.T.})
	aAdd(aFields, { 1, "Salvar XML no Diretório" , space(200),"@!", "" ,"HSSDIR", /*when*/,100,.T.})

return ParamBox(aFields, cTitle,/*aRet*/,{|| valParams() },/*aButtons*/,/*lCentered*/,/*nPosX*/,/*nPosY*/,/*oDlgWizard*/,/*cLoad*/,.F.,.F.)


static function valParams()

	IF ! file(mv_par01)
		ShowHelpDlg("ARQUIVO", {"Arquivo com entidade e notas invalido."}, 5,{"Informe o arquivo corretamente."},5)
		Return .F.
	EndIF

	IF ! ExistDir(mv_par02)
		ShowHelpDlg("DIRETORIO", {"Diretório invalido para salvar os arquivos."}, 5,{"Informe o diretório corretamente."},5)
		Return .F.
	EndIF

return .T.



static function QueryAndExport(aLines, cDirectory, lEnd)

	Local nLine

	ProcRegua( len(aLines) * 2 )

	For nLine := 1 to len(aLines)

		//se clicar no cancelar
		IF lEnd
			Exit
		EndIF

		//se ja gerou XML, não entidadeuta novamente
		IF File(cDirectory + alltrim(aLines[nLine][2]) + ".xml")
			IncProc();IncProc()
			Loop
		EndIF

		IncProc("Processando "+cValToChar(nline)+" de "+cValToChar(len(aLines)))

		IF ConsultaProtocolo(aLines[nLine][1], aLines[nLine][2])
			ExportXML(cDirectory, aLines[nLine][1], aLines[nLine][2])
		EndIF

	Next nLine

return


static function readFile(cFile)

	Local oFile := FWFileReader():New(cFile)
	Local aLines := {}
	Local nLine

	Local cSeparator := ';'


	IF oFile:Open()

		While oFile:HasLine()

			//separa as colunas em posições num array
			aAdd(aLines, Separa(oFile:GetLine(), cSeparator, .T.))

		EndDO

		oFile:Close()

	EndIF

return aLines


static function ConsultaProtocolo(cEntidade, cNota)

	Local lOk   := .F.

	oWs := WsNFeSBra():New()
	oWs:cUserToken   := "TOTVS"
	oWs:cID_ENT      := cEntidade
	oWs:_URL         := AllTrim(cURL)+"/NFeSBRA.apw"
	oWs:cNFECONSULTAPROTOCOLOID := cNota

	lOk := oWs:ConsultaProtocoloNfe()

	IF ! lOk
		IncProc()
		//conout("SPED|" + IIf(Empty(GetWscError(3)),GetWscError(1),GetWscError(3)))
	EndIF

return lOk


static function ExportXML(cDirectory, cEntidade, cNota)


	Local oWS

	Local oXML
	Local oXmlExp
	Local oRetorno

	Local cVerNfe

	Local cDestino 	:= cDirectory + alltrim(cNota) + ".xml"

	Local lOk      	:= .F.

	Local nHandle  	:= 0
	Local nX        := 0
	Local nY		:= 0


	oWS:= WSNFeSBRA():New()
	oWS:cUSERTOKEN        := "TOTVS"
	oWS:cID_ENT           := cEntidade
	oWS:_URL              := AllTrim(cURL)+"/NFeSBRA.apw"
	oWS:cIdInicial        := cNota
	oWS:cIdFinal          := cNota
	oWS:dDATADE			  := CtoD("  /  /  ")
	oWS:dDATAATE		  := CtoD("  /  /  ")
	oWS:cCNPJDESTInicial  := ""
	oWS:cCNPJDESTFinal    := ""
	oWS:nDiasparaExclusao := 0
	lOk := oWS:RETORNAFX()
	oRetorno := oWS:oWsRetornaFxResult

	IF lOk

		//Exporta as notas
	    For nX := 1 To Len(oRetorno:OWSNOTAS:OWSNFES3)

	 		oXml    := oRetorno:OWSNOTAS:OWSNFES3[nX]
			oXmlExp := XmlParser(oRetorno:OWSNOTAS:OWSNFES3[nX]:OWSNFE:CXML,"","","")

			//versão no NFE
			cVerNfe := retVersao( oXmlExp )


	 		IF ! Empty(oXml:oWSNFe:cProtocolo)

	 			IF File(cDestino)
	 				FErase(cDestino)
	 			EndIF

	 			nHandle := FCreate(cDestino)

	 			IF nHandle > 0

	 				FWrite(nHandle,'<?xml version="1.0" encoding="UTF-8"?>')

					Do Case
						Case cVerNfe <= "1.07"
							FWrite(nHandle,'<nfeProc xmlns="http://www.portalfiscal.inf.br/nfe" xmlns:ds="http://www.w3.org/2000/09/xmldsig#" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.portalfiscal.inf.br/nfe procNFe_v1.00.xsd" versao="1.00">')
						Case cVerNfe >= "2.00" .And. "cancNFe" $ oXml:oWSNFe:cXML
							FWrite(nHandle,'<procCancNFe xmlns="http://www.portalfiscal.inf.br/nfe" versao="' + cVerNfe + '">')
						OtherWise
							FWrite(nHandle,'<nfeProc xmlns="http://www.portalfiscal.inf.br/nfe" versao="' + cVerNfe + '">')
					EndCase

		 			FWrite(nHandle,AllTrim(oXml:oWSNFe:cXML))
		 			FWrite(nHandle,AllTrim(oXml:oWSNFe:cXMLPROT))
					FWrite(nHandle,'</nfeProc>')
		 			FClose(nHandle)


		 			return .T.
		 		EndIF
		 	EndIF

		Next nX


	Else
		//conout("SPED|" + IIf(Empty(GetWscError(3)),GetWscError(1),GetWscError(3)))
		Return .F.
	EndIF


return .T.

function retVersao(oXmlExp)
Local _cVersao :=  IIf(Type("oXmlExp:_NFE:_INFNFE:_VERSAO:TEXT") <> "U", oXmlExp:_NFE:_INFNFE:_VERSAO:TEXT, '')

return _cVersao
