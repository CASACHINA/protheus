#Include "Protheus.ch"
#Include "FWMVCDef.ch"
#Include "TopConn.ch"
//denni

User Function MEST001(oModel)

	Local oProcess	:= Nil
	Local bProcess	:= {|oSelf| MEST01EX(oSelf,oModel) }
	Local cPerg		:= Padr("MEST001",10)

	CriaSX1(cPerg)

	oProcess := tNewProcess():New(cPerg,"Importação de dados para transferência entre filiais.",bProcess,;
	"Efetua carga de dados para transferência entre filiais.",cPerg,,.F.,,,.T.,.T.)

Return


Static Function MEST01EX(oProc,oModel)

	Local cNomArq := MV_PAR01
	Local cNomNew := ""
	Local aLinha  := {}
	Local cLinha  := ""
	Local nLinha  := 0

	Private cLog	:= ''
	Private nQtdCpo := 4
	Private cPosPro := 01	//Código do Produto
	Private cPosAmz := 02	//Armazem Origem
	Private cPosQtd := 03	//Quantidade
	Private cPosFil := 04	//Filial Destino

	FT_FUSE(cNomArq)

	oProc:SetRegua1( FT_FLastRec() )

	While !FT_FEof()

		nLinha++
		cLinha := FT_FReadLn()
		oProc:IncRegua1("Lendo arquivo linha: " + cValToChar(nLinha))

		IF ! Empty(cLinha)

			aLinha := Separa(cLinha,";")

			IF Len(aLinha) != nQtdCpo
				GERALOG(nLinha,"","",;
					"Quantidade campos incorreta. Quantidade enviada: " + cValToChar(Len(aLinha)) + ". Quantidade requerida: " + cValToChar(nQtdCpo),;
					"","Dados Incorretos" )

			Else
				lRet := ValDad(aLinha,nLinha,oProc)
				IF lRet
					IncNNT(oModel,aLinha)
				EndIF
			EndIF

		EndIF

		FT_FSkip()

	EndDO

	FT_FUSE()

	//Renomeia o arquivo
	cNomNew := SubStr(cNomArq,1,Rat(".",cNomArq)) + "CS_"
	//	nRet := fRename(cNomArq,cNomNew)

	IF ! Empty(cLog)
		Aviso("Importação de transferência entre filiais.","Processo finalizado com os erros abaixo. " + CRLF + cLog, {"Ok"}, 3,"",1,,.F.)
	Else
		Aviso("Importação de transferência entre filiais.","Processo finalizado com sucesso.", {"Ok"}, 3,"",1,,.F.)
	EndIF
Return

Static Function ValDad(aLinha,nLinha,oProc)

	Local lCont 	:= .T.

	Local cFilDest := aLinha[cPosFil]
	Local cFilTela := U_XGETFILD()
	Local cProduto := Padr(aLinha[cPosPro],TamSx3("B1_COD")[01])
	Local cArmazem := Padr(aLinha[cPosAmz],TamSx3("NNR_CODIGO")[01])

	SB1->( dbSetOrder(1) )
	NNR->( dbSetOrder(1) )
	SB2->( dbSetOrder(1) )

	Do Case
	Case cFilTela <> cFilDest

		GERALOG(;
			nLinha,;
			"Filial Destino",;
			aLinha[cPosFil],;
			"Filial do arquivo (" + cFilDest + ") diferente da escolhido na abertura da tela (" + cFilTela + ").",;
			"",;
			"Dados Incorretos";
		)
		lCont := .F.

	Case ! FWFilExist(,cFilDest)
		GERALOG(;
			nLinha,;
			"Filial Destino",;
			aLinha[cPosFil],;
			"Filial Invalida",;
			"",;
			"Dados Incorretos";
		)
		lCont := .F.

	Case ! SB1->( dbSeek( xFilial("SB1") + cProduto ) )
		GERALOG(;
			nLinha,;
			"Produto",;
			aLinha[cPosPro],;
			"Produto inválido",;
			"",;
			"Dados Incorretos";
		)
		lCont := .F.

	Case ! NNR->( dbSeek( xFilial("NNR") + cArmazem ) )
		GERALOG(;
			nLinha,;
			"Armazém",;
			aLinha[cPosAmz],;
			"Armazém inválido",;
			"",;
			"Dados Incorretos";
		)
		lCont := .F.

	Case ! SB2->( dbSeek( xFilial('SB2')          + cProduto + cArmazem ) )
		GERALOG(;
			nLinha,;
			"Local Origem",;
			aLinha[cPosAmz],;
			"Local não existe para o produto na Filial Origem",;
			"",;
			"Dados Incorretos";
		)
		lCont := .F.

	Case ! SB2->( dbSeek( xFilial('SB2',cFilDest) + cProduto + "01" ) )
		GERALOG(;
			nLinha,;
			"Local Destino",;
			aLinha[cPosAmz],;
			"Local não existe para o produto na Filial Destino",;
			"",;
			"Dados Incorretos";
		)
		lCont := .F.

	Case Val(aLinha[cPosQtd]) <= 0
		GERALOG(;
			nLinha,;
			"Quantidade",;
			aLinha[cPosQtd],;
			"Quantidade inválida",;
			"",;
			"Dados Incorretos";
		)
		lCont := .F.
	EndCase

Return lCont



Static Function IncNNT(oModel,aLinha)

	Local oView		:= FWViewActive()
	Local oModelNNT := oModel:GetModel('NNTDETAIL')

	Local nLinha	:= oModelNNT:Length()

	IF (oModelNNT:Length() == 1 .And. ! Empty(Alltrim(oModel:GetValue('NNTDETAIL', 'NNT_PROD')))) .Or. oModelNNT:Length() > 1
		//adiciona uma linha
		IF oModelNNT:AddLine() > nLinha
			oModelNNT:GoLine(nLinha+1)
		Else
			oModelNNT:DeleteLine()
			IF oModelNNT:AddLine() > nLinha
				oModelNNT:GoLine(nLinha+1)
			EndIF
		EndIF
	EndIF

	oModelNNT:SetValue('NNT_PROD', aLinha[cPosPro])
	oModelNNT:SetValue('NNT_LOCAL', aLinha[cPosAmz])
	oModelNNT:SetValue('NNT_QUANT', Val(aLinha[cPosQtd]))
	//oModelNNT:SetValue('NNT_FILDES', aLinha[cPosFil])

	SB1->( dbSetOrder(1) )
	SB1->( dbSeek( xFilial("SB1") + aLinha[cPosPro] ) )

	oModelNNT:SetValue('NNT_PRODD' , SB1->B1_COD )
	oModelNNT:SetValue('NNT_LOCLD' , SB1->B1_LOCPAD ) //local de destino

	IF Empty(oModelNNT:GetValue('NNT_TS'))
		oModelNNT:LoadValue('NNT_TS', '***' ) //tipo de saida
	EndIF
	IF Empty(oModelNNT:GetValue('NNT_TE'))
		oModelNNT:LoadValue('NNT_TE', '***' ) //tipo de entrada
	EndIF

Return


Static Function GERALOG(nLinha, cCampo, cConteudo, cMensagem, cErro, cStatus)


	cLog += 'Linha: ' + cValToChar(nLinha) + CRLF
	IF ! Empty(cCampo)
		cLog += ' Campo: ' + cCampo + CRLF
	EndIF
	IF ! Empty(cConteudo)
		cLog += ' Conteudo: ' + cConteudo + CRLF
	EndIF
	IF ! Empty(cMensagem)
		cLog += ' Mensagem: ' + cMensagem + CRLF
	EndIF
	IF ! Empty(cErro)
		cLog += ' Erro: ' + cErro + CRLF
	EndIF
	IF ! Empty(cStatus)
		cLog += ' Status: ' + cStatus + CRLF
	EndIF

	cLog += CRLF

Return


Static Function CriaSX1(cPerg)
	U_PUTSX1(cPerg,"01","Arquivo?"			,"Arquivo?"			,"Arquivo?"			,"mv_ch1","C",99,0,0,"G","U_AEST01VA()","DIR"	,"","","mv_par01","","","","","","","","","","","","","","","","",{"Informe o arquivo para importação,","obrigatóriamente deve ser .CSV","",""},{"","","",""},{"","",""},"")
Return

User Function AEST01VA(cChama)

	Local lRet		:= .T.
	Local cMsg		:= ""
	Local cParAux	:= ""

	cParAux := MV_PAR01

	If SubStr(cParAux,2,2) != ":\"
		cMsg := "A pasta informada é inválida"
	EndIf

	If !File(cParAux)
		cMsg += CRLF + "O Arquivo Informado não existe"
	ElseIf ! Upper(Right(AllTrim(cParAux),4)) $ ".CSV|.TXT"
		cMsg += CRLF + "A extensão do arquivo deve ser .CSV|.TXT"
	EndIf

	If !Empty(cMsg)
		Help("","","Informações Incorretas",,CRLF + cMsg, 1, 0)
		lRet := .F.
	EndIf

Return lRet
