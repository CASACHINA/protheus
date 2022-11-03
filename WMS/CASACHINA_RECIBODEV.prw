#include 'protheus.ch'


#Define cCRLF Chr(10)



/*/{Protheus.doc} ReciboDev
Função para imprimir o contra vale na Impressão Não Fiscal

@author Rafael Ricardo Vieceli
@since 07/07/2017
@version undefined
@param aDocDev, array, descricao
@param aRecSD2, array, descricao
@param aDadosNCC, array, descricao
@type function
/*/
user function ReciboDev(aDocDev, aRecSD2, aDadosNCC)

	Local cTexto := ""
	Local cTextoAux

	Local cImpressora    := "BEMATECH MP-4200 TH 01.00.00(S)"
	Local cPorta         := "COM3"

	Local lGuil			:= SuperGetMV("MV_FTTEFGU",, .T.)	// Ativa guilhotina
	Local nSaltoLn		:= SuperGetMV("MV_FTTEFLI",, 1)		// Linha pula entre comprovante
	Local cPrefixo
	lOCAL nX
	Local nOldModulo := nModulo

	IF valtype(aDocDev) != "A"

		IF SF1->F1_TIPO != "D"
			MSGInfo('Está nota não é de devolução')
			return
		EndIF

		aDocDev   := SF1->({ F1_SERIE, F1_DOC, F1_FORNECE, F1_LOJA })
		aRecSD2   := {}
		aDadosNCC := SF1->({ F1_PREFIXO })

		Aviso('Imprimir','Deseja imprimir agora na impressora Bematech?',{'Sim','Cancelar'},1) == 1

	EndIF

	nModulo := 5
	//abre conexao com a impressora
	IF INFAbrir(cImpressora,cPorta) != 0
		nModulo := nOldModulo
		return .F.
	EndIF

	IF Len(aDadosNCC) > 0
		cPrefixo := aDadosNCC[1]
	Else
		cPrefixo := aDocDev[1]
	EndIF


	SA1->( dbSetOrder(1) )
	SA1->( dbSeek( xFilial("SA1") + SF1->(F1_FORNECE + F1_LOJA) ) )

	//Razão social do Emitente
	cTextoAux := Negrito(AllTrim(SM0->M0_NOMECOM))

	cTexto += cTextoAux
	cTexto += cCRLF

	//CNPJ: 99.999.999/9999-99
	cTextoAux := "CNPJ: " + Transform(SM0->M0_CGC, "@R 99.999.999/9999-99")

	cTexto += cTextoAux
	cTexto += cCRLF


	/* Endereço Completo, nro, bairro, Município - UF */
	cTextoAux := AllTrim(SM0->M0_ENDENT) 	+ ", "
	cTextoAux += AllTrim(SM0->M0_BAIRENT)   + ", "
	cTextoAux += AllTrim(SM0->M0_CIDENT)	+ ", "
	cTextoAux += AllTrim(SM0->M0_ESTENT)

	cTexto += Condensado(cTextoAux)
	cTexto += cCRLF+cCRLF

	cTextoAux := I18N("Nome: #1 #2 #3",SA1->({A1_COD,A1_LOJA,alltrim(A1_NOME)}))
	cTexto += Negrito(cTextoAux) + cCRLF

	cTextoAux := "CNPJ/CPF: " + TransForm(SA1->A1_CGC, IIF( len(alltrim(SA1->A1_CGC)) != 11 ,"@R 99.999.999/9999-99","@R 999.999.999-99"))
	cTexto += Negrito(cTextoAux)

	cTexto += cCRLF+cCRLF

	cTexto += "Data Devolução: " + FormDate(SF1->F1_EMISSAO) + cCRLF
	cTexto += "Nota Fiscal Devolução: "+SF1->F1_DOC+" Série: " + SF1->F1_SERIE

	cTexto += cCRLF+cCRLF

	cTexto += Negrito(Centralizado("*********  RECIBO DE DEVOLUÇÃO  *********"))
	cTexto += cCRLF+cCRLF


	Produtos(@cTexto)

	SE1->( DbSetOrder( 2 ) )
	IF SE1->( DbSeek( xFilial("SE1") + aDocDev[3] + aDocDev[4] + cPrefixo + aDocDev[2]  ) )

		cTexto += Direita(Negrito("Valor Total do Crédito R$ " + alltrim(Transform(SE1->E1_SALDO,PesqPict("SE1","E1_SALDO")))))
		cTexto += cCRLF+cCRLF

	EndIF

	cTexto += Condensado(Centralizado("Crédito válido por 30 dias após a emissão da devolução."))
	cTexto += cCRLF+cCRLF

	cTexto += Condensado("Responsável pela Devolução: " + UsrFullName(cUserName))
	cTexto += cCRLF+cCRLF


	// Salta linha extra
	For nX := 1 to (nSaltoLn + 2)
		cTexto += cCRLF
	Next nX

	//Inclui a TAG que Faz o corte do papel, apos a impressao da DANFE
	IF lGuil
		cTexto += Guilhotina()	//aciona a guilhotina
	EndIF

	//imprime
	INFTexto(cTexto)

	nModulo := nOldModulo

return .T.



/*/{Protheus.doc} Produtos
Função para buscar e montar os produtos da nota de devolução

@author Rafael Ricardo Vieceli
@since 07/07/2017
@version undefined
@param cTexto, characters, descricao
@type function
/*/
static function Produtos(cTexto)


	Local aColDiv2      := {}
	Local cL2ItemPic

	Local nContItImp := 0

	Local cLinha := ''

	//48 colunas
	cTexto += Negrito(Condensado("Codigo     Descrição                 Qtd UN Vlr Unit. Vlr Total"))
	cTexto += cCRLF

	// ATENCAO: se alterar algum valor do array, deve-se alterar o cabecalho acima tambem
	aAdd(aColDiv2, 10)	// Codigo
	aAdd(aColDiv2, 25)	// Descricao
	aAdd(aColDiv2, 03)	// Qtd
	aAdd(aColDiv2, 02)	// Un
	aAdd(aColDiv2, 09)	// VlUnit.
	aAdd(aColDiv2, 09)	// VlTotal

	cL2ItemPic := "@E " + Right( "@E 999,999,999.99", aColDiv2[5] )

	SD1->( dbSetOrder(1) )
	SD1->( dbSeek( SF1->(F1_FILIAL+F1_DOC+F1_SERIE+F1_FORNECE+F1_LOJA) ) )

	While ! SD1->( Eof() ) .And. SD1->(D1_FILIAL+D1_DOC+D1_SERIE+D1_FORNECE+D1_LOJA) == SF1->(F1_FILIAL+F1_DOC+F1_SERIE+F1_FORNECE+F1_LOJA)

		SB1->( dbSetOrder(1) )
		SB1->( dbSeek( xFilial("SB1") + SD1->D1_COD ) )

		nContItImp++

		// Codigo
		cLinha := substr( SD1->D1_COD,1, aColDiv2[1] ) + " "

		// Descricao
		cLinha += substr(SB1->B1_DESC,1,aColDiv2[2]) + " "

		// Qtd - quantidade
		cConteudo := cValToChar(SD1->D1_QUANT)
		cLinha += PadL(cConteudo, aColDiv2[3]) + " "

		// Un - unidade de medida
		cLinha += PadL(SD1->D1_UM, aColDiv2[4]) + " "

		// VlUnit. - valor unitario
		cConteudo := Transform((SD1->D1_TOTAL-SD1->D1_VALDESC)/SD1->D1_QUANT, cL2ItemPic) + " "
		cLinha += cConteudo

		// VlTotal - valor total
		cConteudo := Transform(SD1->D1_TOTAL-SD1->D1_VALDESC, '@E 99,999.99')
		cLinha += cConteudo

		cTexto += Condensado(cLinha)
		cTexto += cCRLF

		//Tratamento necessário pois dependendo tamanho das informações dos itens a serem impressos,
		//apos um determinado tamanho o texto não é impresso, gerenado o erro de DEBUG/TOTVSAPI na DLL.
		//para isso foi quebrada a impressão em 50 itens.
		IF nContItImp == 30
			//Envia comando para a Impressora
			INFTexto(cTexto)
			cTexto		:= ""
			nContItImp	:= 0
		EndIF

		SD1->(dbSkip())
	EndDO

	cTexto += cCRLF+cCRLF

return cTexto


/*
funções para formatar texto para impressora
nomes autoexplicativos
*/

static function Centralizado(cTexto)
return "<ce>"+cTexto+"</ce>"

static function Direita(cTexto)
return "<ad>"+cTexto+"</ad>"


static function Negrito(cTexto)
return "<b>"+cTexto+"</b>"


static function Guilhotina()
return "<gui></gui>"

static function Condensado(cTexto)
return "<c>"+cTexto+"</c>"
