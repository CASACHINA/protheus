

// ####################################################################################################################################################################################################
//
// Projeto   :   
// Modulo    : Financeiro
// Fonte     : RBol033
// Data      : 01/06/2020
// Autor     : Valberg Moura 
// Descricao : Emissao de Boleto Santander
//
// ####################################################################################################################################################################################################

#include 'protheus.ch'


#define __codBanco "033"
#define __nomBanco "Santander"

#define nLarg  (605-35)
#define nAlt   842


User Function RBol033( oBoleto )

	Local nBloco1 := 0
	Local nBloco2 := 0
	Local nBloco3 := 0

	Private oArial06  := TFont():New('Arial',06,06,,.F.,,,,.T.,.F.,.F.)
	Private oArial09N := TFont():New('Arial',10,10,,.T.,,,,.T.,.F.,.F.)
	Private oArial12N := TFont():New('Arial',12,12,,.T.,,,,.T.,.F.,.F.)
	Private oArial14  := TFont():New('Arial',16,16,,.F.,,,,.T.,.F.,.F.)
	Private oArial18N := TFont():New('Arial',21,21,,.T.,,,,.T.,.F.,.F.)


	Private _cBanco   := "033"
	Private _cAgencia := "3415"
	Private _cConta   := "0130027105"

	//calcula o valor dos abatimentos
	Private nValorAbatimentos :=  SomaAbat(SE1->E1_PREFIXO,SE1->E1_NUM,SE1->E1_PARCELA,"R",1,,SE1->E1_CLIENTE,SE1->E1_LOJA)
	//calculo valor total
	Private nValorDocumento := Round((((SE1->E1_SALDO+SE1->E1_ACRESC)-SE1->E1_DECRESC)*100)-(nValorAbatimentos*100),0)/100

	//nosso numero
	Private cNossoNumero := SE1->E1_NUMBCO
	Private cLinhaDigitavel := ""
	//codigo de barras
	Private cCodigoBarra := BolCodBar(nValorDocumento)

	Private lEnderecoCobranca := !Empty(SA1->A1_ENDCOB) .and. !Empty(SA1->A1_BAIRROC) .and. !Empty(SA1->A1_MUNC) .and. !Empty(SA1->A1_ESTC) .and. !Empty(SA1->A1_CEPC)


	//inicia pagina
	oBoleto:StartPage()

	//Nome do Banco
	oBoleto:Say(nBloco1+33,25,"Santander",oArial12N )
	//logo
	oBoleto:SayBitmap(nBloco1+20, 20, "\boletos\logos\logo-banco-033.jpg", 75, 20)
	//Line(linha_inicial, coluna_inicial, linha final, coluna final)
	oBoleto:Line( nBloco1+20,  95, nBloco1+40,  95,,"01")
	oBoleto:Line( nBloco1+20, 146, nBloco1+40, 146,,"01")

	//Numero do Banco
	oBoleto:Say(nBloco1+35,99,"033-7", oArial18N )

	//adiciona mais dois ao depois
	nBloco1 += 3

	oBoleto:Say(nBloco1+33,455,"Comprovante de Entrega",oArial09N)

	//nome da empresa
	oBoleto:Say(nBloco1+45,25 ,"Cedente",oArial06)
	oBoleto:Say(nBloco1+53,25 ,substr(alltrim(SM0->M0_NOMECOM),1,47),oArial09N)
	oBoleto:Say(nBloco1+60,25 ,alltrim(SM0->M0_ENDCOB),oArial09N)

	oBoleto:Say(nBloco1+45,250,"Agência/Código Cedente",oArial06)
	oBoleto:Say(nBloco1+57,250,alltrim(_cAgencia)+"/"+SEE->EE_CODEMP ,oArial09N)

	oBoleto:Say(nBloco1+45,350,"Nro. Documento",oArial06)
	oBoleto:Say(nBloco1+57,350,SE1->E1_PREFIXO+alltrim(SE1->E1_NUM)+alltrim(SE1->E1_PARCELA) ,oArial09N) //Prefixo +Numero+Parcela

	oBoleto:Say(nBloco1+70,25,"Sacado",oArial06)
	oBoleto:Say(nBloco1+82,25,SA1->A1_NOME ,oArial09N)				//Nome

	oBoleto:Say(nBloco1+70,250,"Vencimento",oArial06)
	oBoleto:Say(nBloco1+82,250, FormDate(SE1->E1_VENCREA),oArial09N)

	oBoleto:Say(nBloco1+70,350,"Valor do Documento",oArial06)
	oBoleto:Say(nBloco1+82,350,Transform(nValorDocumento,"@E 999,999,999.99"),oArial09N)

	oBoleto:Say(nBloco1+105,25,"Recebi(emos) o bloqueto/título",oArial09N)
	oBoleto:Say(nBloco1+117,25,"com as características acima.",oArial09N)

	oBoleto:Say(nBloco1+95,250,"Data",oArial06)
	oBoleto:Say(nBloco1+95,330,"Assinatura",oArial06)

	oBoleto:Say(nBloco1+120,250,"Data",oArial06)
	oBoleto:Say(nBloco1+120,330,"Entregador",oArial06)

	oBoleto:Say(nBloco1+ 50,455,"(  ) Mudou-se"                 ,oArial06)
	oBoleto:Say(nBloco1+ 60,455,"(  ) Ausente"                  ,oArial06)
	oBoleto:Say(nBloco1+ 70,455,"(  ) Não existe nº indicado"   ,oArial06)
	oBoleto:Say(nBloco1+ 80,455,"(  ) Recusado"                 ,oArial06)
	oBoleto:Say(nBloco1+ 90,455,"(  ) Não procurado"            ,oArial06)
	oBoleto:Say(nBloco1+100,455,"(  ) Endereço insuficiente"    ,oArial06)
	oBoleto:Say(nBloco1+110,455,"(  ) Desconhecido"             ,oArial06)
	oBoleto:Say(nBloco1+120,455,"(  ) Falecido"                 ,oArial06)
	oBoleto:Say(nBloco1+130,455,"(  ) Outros (anotar no verso)"  ,oArial06)

	//linhas horizontais
	oBoleto:Line(nBloco1+ 37,  20,nBloco1+ 37,nLarg,,"01")
	oBoleto:Line(nBloco1+ 62,  20,nBloco1+ 62, 450 ,,"01")
	oBoleto:Line(nBloco1+ 87,  20,nBloco1+ 87, 450 ,,"01")
	oBoleto:Line(nBloco1+112, 247,nBloco1+112, 450 ,,"01")
	oBoleto:Line(nBloco1+137,  20,nBloco1+137,nLarg ,,"01")

	//linhas vericais
	oBoleto:Line(nBloco1+ 37,247,nBloco1+137,247 ,,"01")
	oBoleto:Line(nBloco1+ 87,327,nBloco1+137,327 ,,"01")
	oBoleto:Line(nBloco1+ 37,347,nBloco1+ 87,347 ,,"01")
	oBoleto:Line(nBloco1+ 37,450,nBloco1+137,450 ,,"01")

	//ajuste fino
	nBloco2 += 5
	//Pontilhado separador
	For nPont := 10 to nLarg+10 Step 4
		oBoleto:Line(nBloco2+147, nPont,nBloco2+147, nPont+2,,)
	Next nPont

	//Nome do Banco
	oBoleto:Say(nBloco2+170,25,"Santander",oArial12N )
	//logo
	oBoleto:SayBitmap(nBloco2+157, 20, "\boletos\logos\logo-banco-033.jpg", 75, 20)
	//Line(linha_inicial, coluna_inicial, linha final, coluna final)
	oBoleto:Line( nBloco2+157,  95, nBloco2+177,  95,,"01")
	oBoleto:Line( nBloco2+157, 146, nBloco2+177, 146,,"01")
	oBoleto:Line( nBloco2+177,  20, nBloco2+177,nLarg,,"01")

	//Numero do Banco
	oBoleto:Say(nBloco2+174,99,"033-7",oArial18N )

	//adiciona mais dois ao depois
	nBloco1 += 3

	oBoleto:Say(nBloco2+174,420,"Recibo do Sacado",oArial09N)

	ImprimeBloco(oBoleto, nBloco2)

	//oBoleto:Say(480,25,cCodigoBarra,oArial09N)
	//CODIGO DE BARRAS
	//oBoleto:Code128C(485,25,cCodigoBarra, 45 )

	//BLOCO 3
	//Pontilhado separador

	oBoleto:FWMSBAR("INT25" ,60,1.7, cCodigoBarra ,oBoleto,.F.,,.T.,0.02,1,.F.,"Arial",NIL,.F.,2,2,.F.)
	//oBoleto:Code128C(485,25,cCodigoBarra, 30 )


	For nPont := 10 to nLarg+10 Step 4
		oBoleto:Line(nBloco3+465, nPont,nBloco3+465, nPont+2,,)
	Next nPont

	//Nome do Banco
	oBoleto:Say(nBloco2+485,25,"Santander",oArial12N )
	//logo
	oBoleto:SayBitmap(nBloco2+472, 20, "\boletos\logos\logo-banco-033.jpg", 75, 20)
	//Line(linha_inicial, coluna_inicial, linha final, coluna final)
	oBoleto:Line( nBloco2+472,  95, nBloco2+492,  95,,"01")
	oBoleto:Line( nBloco2+472, 146, nBloco2+492, 146,,"01")
	oBoleto:Line( nBloco2+492,  20, nBloco2+492,nLarg,,"01")

	//Numero do Banco
	oBoleto:Say(nBloco2+489,99,"033-7",oArial18N )
	//linha digitavel
	oBoleto:SayAlign(nBloco2+477,155,cLinhaDigitavel,oArial14,400,,,1)



	ImprimeBloco(oBoleto, nBloco3 + 320 )



	//Finaliza pagina
	oBoleto:EndPage()


Return





Static Function ImprimeBloco(oBoleto, nBloco)

	//bloco 2 linha 1 ->
	oBoleto:Say(nBloco+185,25 ,"Local de Pagamento",oArial06)
	oBoleto:Say(nBloco+197,90 ,"PAGÁVEL NA REDE BANCÁRIA ATÉ O VENCIMENTO",oArial09N)

	oBoleto:Say(nBloco+185,425 ,"Vencimento",oArial06)
	oBoleto:SayAlign(nBloco+187,435,FormDate(SE1->E1_VENCREA),oArial09N,100,10,,1)

	//bloco 2 linha 2 ->
	oBoleto:Line( nBloco+202,  20, nBloco+202,nLarg,,"01")
	oBoleto:Say(nBloco+210,25 , "Cedente",oArial06)
	oBoleto:Say(nBloco+222,25 , SM0->M0_NOMECOM + " - CNPJ: " + transform(SM0->M0_CGC,"@R 99.999.999/9999-99") ,oArial09N)

	oBoleto:Say(nBloco+210,425 ,"Agência/Código Cedente",oArial06)
	oBoleto:SayAlign(nBloco+212,435,alltrim(_cAgencia)+"/"+alltrim(SEE->EE_CODEMP),oArial09N,100,10,,1)


	//bloco 2 linha 4 ->
	oBoleto:Line( nBloco+227,  20, nBloco+227,nLarg,,"01")
	oBoleto:Say(nBloco+233,25, "Data do Documento" ,oArial06)
	oBoleto:Say(nBloco+243,25, FormDate(SE1->E1_EMISSAO), oArial09N)

	oBoleto:Line(nBloco+227, 110, nBloco+247,110,,"01")
	oBoleto:Say(nBloco+233,115, "Nro. Documento"                                  ,oArial06)
	oBoleto:Say(nBloco+243,115, SE1->E1_PREFIXO+alltrim(SE1->E1_NUM)+alltrim(SE1->E1_PARCELA) ,oArial09N)

	oBoleto:Line(nBloco+227, 232, nBloco+247,232,,"01")
	oBoleto:Say(nBloco+233,237, "Espécie Doc."                                   ,oArial06)
	oBoleto:Say(nBloco+243,237, "DM"										,oArial09N) //Tipo do Titulo

	oBoleto:Line(nBloco+227, 293, nBloco+247,293,,"01")
	oBoleto:Say(nBloco+233,298, "Aceite"                                         ,oArial06)
	oBoleto:Say(nBloco+243,298, "N"                                             ,oArial09N)

	oBoleto:Line(nBloco+227, 339, nBloco+247,339,,"01")
	oBoleto:Say(nBloco+233,344, "Data do Processamento"                          ,oArial06)
	oBoleto:Say(nBloco+243,344, FormDate(dDataBase),oArial09N) // Data impressao

	oBoleto:Say(nBloco+233,425 ,"+ Número",oArial06)
	oBoleto:SayAlign(nBloco+234,435,cNossoNumero,oArial09N,100,10,,1)

	//bloco 2 linha 5 ->
	oBoleto:Line( nBloco+247,  20, nBloco+247,nLarg,,"01")
	oBoleto:Say(nBloco+253,25,"Uso do Banco"                                   ,oArial06)
	oBoleto:Say(nBloco+263,25,"CLIENTE"                                   ,oArial09N)

	oBoleto:Line(nBloco+247,110, nBloco+267,110,,"01")
	oBoleto:Say(nBloco+253,115 ,"Carteira"                                       ,oArial06)
	oBoleto:Say(nBloco+263,115 ,"101"                                  	,oArial09N)

	oBoleto:Line(nBloco+247, 171, nBloco+267,171,,"01")
	oBoleto:Say(nBloco+253,176 ,"Espécie"                                        ,oArial06)
	oBoleto:Say(nBloco+263,176 ,"R$"                                             ,oArial09N)

	oBoleto:Line(nBloco+247, 232, nBloco+267,232,,"01")
	oBoleto:Say(nBloco+253,237,"Quantidade"                                     ,oArial06)
	oBoleto:Line(nBloco+247,339, nBloco+267,339,,"01")
	oBoleto:Say(nBloco+253,344,"Valor"                                          ,oArial06)

	oBoleto:Say(nBloco+253,425 ,"Valor do Documento",oArial06)
	oBoleto:SayAlign(nBloco+254,435,Transform(nValorDocumento,"@E 999,999,999.99"),oArial09N,100,10,,1)


	//bloco 2 linha 6 ->
	oBoleto:Line( nBloco+267,  20, nBloco+267,nLarg,,"01")
	oBoleto:Say( nBloco+273,25, "Instruções (INSTRUÇÕES DE RESPONSABILIDADE DO BENEFICIÁRIO. QUALQUER DÚVIDA SOBRE ESTE BOLETO, CONTATE O BENEFICIÁRIO.)" , oArial06)
	oBoleto:Say(nBloco+283,0025, "Após o Vencimento, multa de 2%" ,oArial09N)

	If ! Empty(SEE->EE_FORMEN1)
		oBoleto:Say(nBloco+303,0025, &(Alltrim(SEE->EE_FORMEN1)),oArial09N)
	Endif

	If ! Empty(SEE->EE_FORMEN2)
		oBoleto:Say(nBloco+318,0025, &(Alltrim(SEE->EE_FORMEN2)),oArial09N)
	Endif

	If ! Empty(SEE->EE_FOREXT1)
		oBoleto:Say(nBloco+333,0025, &(Alltrim(SEE->EE_FOREXT1)),oArial09N)
	Endif

	If ! Empty(SEE->EE_FOREXT2)
		oBoleto:Say(nBloco+348,0025, &(Alltrim(SEE->EE_FOREXT2)),oArial09N)
	Endif


	oBoleto:Say(nBloco+273,425,"(-)Desconto/Abatimento",oArial06)

	//bloco 2 linha 7 ->
	oBoleto:Line( nBloco+287,  420, nBloco+287,nLarg,,"01")
	oBoleto:Say(nBloco+293,425,"(-)Outras Deduções",oArial06)

	//bloco 2 linha 8 ->
	oBoleto:Line( nBloco+307,  420, nBloco+307,nLarg,,"01")
	oBoleto:Say(nBloco+313,425,"(+)Mora/Multa",oArial06)

	//bloco 2 linha 9 ->
	oBoleto:Line( nBloco+327,  420, nBloco+327,nLarg,,"01")
	oBoleto:Say(nBloco+333,425,"(+)Outros Acréscimos",oArial06)

	//bloco 2 linha 10 ->
	oBoleto:Line( nBloco+347,  420, nBloco+347,nLarg,,"01")
	oBoleto:Say(nBloco+353,425,"(=)Valor Cobrado",oArial06)
	oBoleto:Line( nBloco+177,  420, nBloco+367,420,,"01")

	//bloco 2 Sacado ->
	oBoleto:Line( nBloco+367,  20, nBloco+367,nLarg,,"01")
	oBoleto:Say(nBloco+376,25 ,"Sacado",oArial06)
	oBoleto:Say(nBloco+376,90 ,alltrim(SA1->A1_NOME) + " (" +SA1->A1_COD+" - "+SA1->A1_LOJA+")",oArial09N)
	oBoleto:Say(nBloco+386,90 ,IIF(lEnderecoCobranca,SA1->A1_ENDCOB,SA1->A1_END) + " - " + IIF(lEnderecoCobranca,SA1->A1_BAIRROC,SA1->A1_BAIRRO) ,oArial09N)
	oBoleto:Say(nBloco+396,90 ,transform(IIF(lEnderecoCobranca,SA1->A1_CEPC,SA1->A1_CEP),"@R 99999-999")+ " - " + alltrim(IIF(lEnderecoCobranca,SA1->A1_MUNC,SA1->A1_MUN))+"/"+IIF(lEnderecoCobranca,SA1->A1_ESTC,SA1->A1_EST) ,oArial09N)
	IF SA1->A1_PESSOA == "J"
		oBoleto:Say(nBloco+406,90 ,"CNPJ: " + transform(SA1->A1_CGC,"@R 99.999.999/9999-99") ,oArial09N)
	Else
		oBoleto:Say(nBloco+406,90 ,"CPF: " + transform(SA1->A1_CGC,"@R 999.999.999-99") ,oArial09N)
	EndIF
	oBoleto:Say(nBloco+406,430 ,cNossoNumero ,oArial09N)

	//bloco 2 Sacado - autenticação ->
	oBoleto:Say(nBloco+406, 25, "Sacado/Avalista" , oArial06)
	oBoleto:Line( nBloco+410,  20, nBloco+410,nLarg,,"01")
	oBoleto:Say(nBloco+416,435, "Autenticação Mecânica - Ficha de compensação" , oArial06)

Return



Static Function BolCodBar(nValor)

	Local cValorFinal := StrZero(Round(nValor*100,0),10)
	Local nDvnn			:= 0
	Local nDvcb			:= 0
	Local nDv			:= 0
	Local cNN			:= ''
	Local cRN			:= ''
	Local cCB			:= ''
	Local cS			:= ''
	Local cFator      := strzero(SE1->E1_VENCREA - ctod("07/10/97"),4)
	Local cCart			:= "112"
	Local cFixo  := '9'
	Local cMoeda := '9'
	Local cProdut := '3'
	Local cCedente := ' '
	Local cBse := AllTrim(SEE->EE_CODEMP)
	Local cIOS := '0'
	Local cCarteira := '101'
	Local cInd := '0'
	Local cSeq := '02'
	Local cDigV := '8'

	// Definicao do NOSSO NUMERO
	cNN     := SubStr(AllTrim(SE1->E1_NUMBCO),1,7)
	nDvnn   := SubStr(AllTrim(SE1->E1_NUMBCO),-1)
	cNroDoc := "00000"+SubStr(AllTrim(SE1->E1_NUMBCO),1,7)+SubStr(AllTrim(SE1->E1_NUMBCO),-1)

	//Definicao do CODIGO DE BARRAS
	cS := _cBanco+ "9" + cFator +  cValorFinal + cFixo  + cBse + cNroDoc + cIOS + cCarteira// cDigV
	nDvcb := modulo11(cS)
	cCB   := SubStr(cS, 1, 4) + AllTrim(Str(nDvcb)) + SubStr(cS,5,39)

	//-------- Definicao da LINHA DIGITAVEL (Representacao Numerica)
	//	Campo 1			Campo 2			Campo 3			Campo 4		Campo 5
	//	AAABC.DDDDX		DDDEE.EEEEEY	FFFFF.FGHHZ	    K			UUUUVVVVVVVVVV

	// 	CAMPO 1:
	//	AAA	= Codigo do banco na Camara de Compensacao
	//	  B = Codigo da moeda, sempre 9
	//	  C = Fixo (9)
	//	DDDD = 4 Posiçoes do Codigo Cedente padrao
	//   X = DAC que amarra o campo, calculado pelo Modulo 10 da String do campo

	cS    := _cBanco + "9" + cFixo + SubStr(cBse,1,4)
	nDv   := modulo10(cS)
	cRN   := SubStr(cS, 1, 5) + '.' + SubStr(cS, 6, 4) + AllTrim(Str(nDv)) + '  '

	// 	CAMPO 2:
	//	 DDD = Restante Cod Cedente
	//	   EEEEEEE = 7 primeiros campos do N/N
	//	     Y = DAC que amarra o campo, calculado pelo Modulo 10 da String do campo

	cS := Substr(cBse,5,3) + SubStr(cNroDoc,1,7)
	//cS := Substr(cBse,2,5) + cSeq + cDigV +SubStr(cNroDoc,1,2)
	nDv:= modulo10(cS)
	cRN := cRN + SubStr(cS,1,5)+'.'+SubStr(cS,6,5)+ AllTrim(Str(nDv)) + '  '

	// 	CAMPO 3:
	// FFFFFF = Restante do N/N (6 digitos)
	//      G = Sempre '0' quando nao se tratar de Seguradora
	//    HHH = Tipo de Modalidade Carteira
	//	        Z = DAC que amarra o campo, calculado pelo Modulo 10 da String do campo
	cS    := Subs(cNroDoc,8,6)+cIOS+cCarteira
	nDv   := modulo10(cS)
	cRN   := cRN + Subs(cS,1,5)+'.'+Subs(cS,6,5) + Alltrim(Str(nDv)) + '  '

	//	CAMPO 4:
	//	     K = DAC do Codigo de Barras
	cRN   := cRN + ' ' + AllTrim(Str(nDvcb)) + '  '

	// 	CAMPO 5:
	//	      UUUU = Fator de Vencimento
	//	VVVVVVVVVV = Valor do Titulo
	cRN   := cRN + cFator + StrZero(Round(nValor * 100,0),14-Len(cFator))

	cLinhaDigitavel := cRN

Return cCB

Static Function Modulo11(cData)
	LOCAL L, D, P , R := 0
	L := Len(cdata)
	D := 0
	P := 2
	While L > 0
		D := D + (Val(SubStr(cData, L, 1)) * P)
		If P = 9
			P := 1
		End
		P := P + 1
		L := L - 1
	End
	R := (mod(D*10,11))   //resto
	If (R == 0 .Or. R == 1 .Or. R == 10 )
		D := 1
	Else
		D := R
	End
Return(D)


Static Function Modulo10(cData)
	Local nNum  := ""
	Local nSeq  := 2
	Local nTSoma := 0
	Local nSoma  := 0
	Local nSubt  := 0
	Local nResult := 0

	nNum := ALLTRIM(cData)
	FOR i:= LEN(nNum) TO 1 STEP -1
		nTSoma := val(SUBSTR(nNum,i,1)) * nSeq
		IF nTSoma >= 10
			nSoma += val(left(StrZero(nTSoma,2),1))+val(Right(StrZero(nTSoma,2),1))
		ELSE
			nSoma += nTSoma
		ENDIF
		IF nSeq = 2
			nSeq := 1
		ELSE
			nSeq++
		ENDIF
	NEXT
	nSubt := nSoma%10
	nResult := 10 - nSubt
	IF nResult >= 10
		nResult := 0
	ENDIF
Return(nResult)



