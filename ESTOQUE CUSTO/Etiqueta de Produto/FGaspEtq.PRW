#Include "Protheus.ch"
#include "topconn.ch"


User Function GaspEtq()
	
	Local aParam  		:= {}
	Local aRet     		:= {}
	Local aMascGrd      := Separa(GetMv("MV_MASCGRD"),",")
	
	Local cMascara 		:= GetMv("MV_MASCGRD",,'9,2,2')
	Local cTamanho      := ""
	Local cCor 			:= ""
	Local cDescCor 		:= ""
	Local cDescCol 		:= ""
	Local cMarca   		:= ""
	Local cCat1	 		:= ""
	Local cCat2	 		:= ""
	Local cCat3	 		:= ""
	Local cCat4	 		:= ""
	Local cCat5	 		:= ""
	Local cQuery 		:= ""
	Local nPrecoVen		:= 0
	Local clCodBar		:= ''
	Local clPar01		:= ''
	Local clPar02		:= ''
	
	Private cPerg		:= "FGASPET"
	Private nTamRef 	:= Val(Substr(cMascara,1,2))
	Private nTamLin 	:= Val(Substr(cMascara,4,2))
	Private nTamCol 	:= Val(Substr(cMascara,7,2))
	Private nTamProd	:= 0
	Private aEtiquetas  := {}
	Private nFiltro		:= 0
//	Private nCod		:= Val(aMascGrd[1])+Val(aMascGrd[2])+Val(aMascGrd[3]) +Val(aMascGrd[4])
  	Private nCod		:= Val(aMascGrd[1])+Val(aMascGrd[2])+Val(aMascGrd[3])
	Private nCod1		:= Val(aMascGrd[1])
	Private nCod2		:= Val(aMascGrd[2])
	Private nCod3		:= Val(aMascGrd[3])
 //	Private nCod4		:= Val(aMascGrd[4])
	Private nlTamCod    := GetSX3Cache('B4_COD','X3_TAMANHO')
	
	
	AjustaSx1(@cPerg)
	If Pergunte(cPerg, .T.)
		
		clPar01 := PADR(AllTrim(Mv_Par01),nCod)
		
		//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
		//ณConsulta produtosณ
		//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
		cQuery := "	SELECT "
		cQuery += "		SB1.B1_COD , "
		cQuery += "		SB1.B1_PRV1 , "
		cQuery += "		SB1.B1_CODBAR ,"
		cQuery += "		SB1.B1_01DREF , "
		cQuery += "		SB4.B4_DESC , "
		cQuery += "		(SELECT AY0.AY0_DESC FROM "  + RetSqlName("AY0") + " AY0 WHERE AY0.AY0_FILIAL = '" + xFilial("AY0") + "' AND AY0.AY0_CODIGO = SB4.B4_01CAT1 AND AY0.D_E_L_E_T_ = '' ) DESCCAT1, "
		cQuery += "		(SELECT AY0.AY0_DESC FROM "  + RetSqlName("AY0") + " AY0 WHERE AY0.AY0_FILIAL = '" + xFilial("AY0") + "' AND AY0.AY0_CODIGO = SB4.B4_01CAT2 AND AY0.D_E_L_E_T_ = '') DESCCAT2, "
		cQuery += "		(SELECT AY0.AY0_DESC FROM "  + RetSqlName("AY0") + " AY0 WHERE AY0.AY0_FILIAL = '" + xFilial("AY0") + "' AND AY0.AY0_CODIGO = SB4.B4_01CAT3 AND AY0.D_E_L_E_T_ = '') DESCCAT3, "
		cQuery += "		(SELECT AY0.AY0_DESC FROM "  + RetSqlName("AY0") + " AY0 WHERE AY0.AY0_FILIAL = '" + xFilial("AY0") + "' AND AY0.AY0_CODIGO = SB4.B4_01CAT4 AND AY0.D_E_L_E_T_ = '') DESCCAT4, "
		cQuery += "		(SELECT AY0.AY0_DESC FROM "  + RetSqlName("AY0") + " AY0 WHERE AY0.AY0_FILIAL = '" + xFilial("AY0") + "' AND AY0.AY0_CODIGO = SB4.B4_01CAT5 AND AY0.D_E_L_E_T_ = '') DESCCAT5, "
		cQuery += "		(SELECT AY2.AY2_DESCR FROM " + RetSqlName("AY2") + " AY2 WHERE AY2.AY2_FILIAL = '" + xFilial("AY2") + "' AND AY2.AY2_CODIGO = SB4.B4_01CODMA AND AY2.D_E_L_E_T_ = '') MARCA, "
		cQuery += "		(SELECT SBV.BV_DESCRI FROM " + RetSqlName("SBV") + " SBV WHERE SBV.BV_FILIAL = '"  + xFilial("SBV") + "' AND SBV.BV_TABELA = SB4.B4_LINHA AND SBV.BV_CHAVE = SB1.B1_01LNGRD AND D_E_L_E_T_ = '') COR, "
		cQuery += "		(SELECT SBV.BV_DESCRI FROM " + RetSqlName("SBV") + " SBV WHERE SBV.BV_FILIAL = '"  + xFilial("SBV") + "' AND SBV.BV_TABELA = SB4.B4_COLUNA AND SBV.BV_CHAVE = SB1.B1_01CLGRD AND D_E_L_E_T_ = '') TAMANHO, "
		cQuery += "		(SELECT SB0.B0_PRV1 FROM "   + RetSqlName("SB0") + " SB0 WHERE SB0.B0_FILIAL = '"  + xFilial("SB0") + "' AND SB0.B0_COD = SB1.B1_COD AND SB0.D_E_L_E_T_ = '' ) PRECO, "
		cQuery += "		(SELECT SLK.LK_CODBAR FROM " + RetSqlName("SLK") + " SLK WHERE SLK.LK_FILIAL = '"  + xFilial("SLK") + "' AND SLK.LK_CODIGO = SB1.B1_COD AND SLK.D_E_L_E_T_ = '') CODBAR "
		cQuery += "	FROM "
		cQuery += "		" + RetSqlName("SB4") + " SB4 "
		cQuery += "	INNER JOIN " + RetSqlName("SB1") + " SB1 ON SB1.B1_FILIAL = '" + xFilial("SB1") + "' AND SUBSTRING(SB1.B1_COD,1," + Alltrim(Str(nTamRef)) + ") = SB4.B4_COD AND SB4.D_E_L_E_T_ = '' "
		cQuery += "	WHERE "
		cQuery += "		SB4.B4_FILIAL = '" + xFilial("SB1") + "' AND "
		cQuery += "		SB4.B4_COD = '" + mv_par01 + "' AND "
		cQuery += "		SB4.D_E_L_E_T_ = '' "
		cQuery += "	ORDER BY SB4.B4_COD "
		
		If Select("TMP") > 0
			TMP->( dbCloseArea() )
		EndIf
		
		dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),"TMP",.T.,.T.)
		
		If TMP->( Eof() )
			MsgInfo("Nใo hแ dados para impressใo das etiquetas, verifique o parโmetro informado.",,"INFO")
			Return .F.
		Endif
		
		ProcRegua(TMP->( RecCount() ))
		While TMP->( !Eof() )
			
			IncProc( -1 )
			
			If Empty(TMP->PRECO)
				clPreco := PADL(Alltrim(Transform(TMP->B1_PRV1,PesqPict("SB1","B1_PRV1"))),10)
			Else
				clPreco := PADL(Alltrim(Transform(TMP->PRECO,PesqPict("SB1","B1_PRV1"))),10)
			EndIf
			
			aAdd(aEtiquetas	,{ 	Padr(TMP->DESCCAT3,10)				 				,;		//[1]Secao
			Padr(TMP->DESCCAT4,10)				 				,;		//[2]Marca
			PadR(AllTrim(Left(TMP->MARCA,12)),12)				,;		//[3]Especie
			PadR(AllTrim(TMP->B1_01DREF) ,16)	 				,;		//[4]Referencia
			Alltrim(TMP->COR)					 				,;	   	//[5]Cor
			Alltrim(TMP->TAMANHO)							 	,;		//[6]Tamanho
			Iif(Empty(TMP->CODBAR),TMP->B1_CODBAR,TMP->CODBAR)	,;		//[7]Cod Barras
			AllTrim(clPreco)									,;		//[8]Preco
			TMP->B1_COD											,;		//[9]Produto
			MV_PAR03											})		//[10]Quantidade
			TMP->(dbSkip())
			
		EndDo
		
		If Len(aEtiquetas) > 0
			If mv_par03 == 2
				Processa({||PrintEtq04(aEtiquetas)},"Imprimindo Etiquetas...")
			Else
				FMontaGrd(aEtiquetas)
			EndIf
		Endif
		
	EndIf
	
Return Nil

Static Function FMontaGrd(_aEtiqtas)
	
	Local alEtq  	:= {}
	Local nlOpc     := GD_INSERT + GD_UPDATE + GD_DELETE
	Local clFlag  	:= .F.
	Local clDel   	:= .T.
	Local nlAux     := 0
	Local alAux     := {}
	Local aCombo  	:= {"Modelo Zebra","Outras"}
	Local oFont
	Local nI
	Local nX
	Private apHeadEt 	:= {}
	Private apColsEq 	:= {}
	Private lRefresh
	Private cCombo 		:= ""

	For nX := 1 To Len(_aEtiqtas)
		aSize(_aEtiqtas[nX],Len(_aEtiqtas[nX])+1)
		nlAux := Len(_aEtiqtas[nX])
		_aEtiqtas[nX][nlAux] := .F.
		For nI := 1 To Len(_aEtiqtas[nX])
			If nI <> 7 .And. nI <> 8
				aAdd(alAux,_aEtiqtas[nX][nI])
			EndIf
		Next nI
		aAdd(apColsEq,alAux)
		alAux := {}
	Next nX
	
	Aadd(apHeadEt,{'Secao'		,'AY0_DESC'		,'@!'	,15						,,,'','C','',''})
	Aadd(apHeadEt,{'Marca'		,'AY2_DESCR'	,''		,15						,,,'','C','',''})
	Aadd(apHeadEt,{'Especie'	,'AY0_DESC'		,''		,15						,,,'','C','',''})
	Aadd(apHeadEt,{'Referencia'	,'B1_01DREF'	,''		,15						,,,'','C','',''})
	Aadd(apHeadEt,{'Cor'		,'B4_01CAT1'	,''		,08						,,,'','C','',''})
	Aadd(apHeadEt,{'Tamanho'	,'B4_01CAT2'	,''		,3 						,,,'','C','',''})
	Aadd(apHeadEt,{'Produto'	,'B1_COD'		,''		,16						,,,'','C','',''})
	Aadd(apHeadEt,{'Quantidade'	,'B2_QATU'		,''		,3 						,,,'','N','',''})
	
	
	Define MsDialog oDlg From 0,0 To 450,800 Pixel Title OemToAnsi('Etiquetas')
	
	oFont := TFont():New( "Calibri"	    ,        ,        -15,        ,      .T.,        ,        ,        ,       .F. ,           .F. )
	
	oFWLayer := FWLayer():New()
	oFWLayer:Init(oDlg)
	
	oFWLayer:addLine('Lin01',99.9,.F.)
	oFWLayer:addCollumn('Etiquetas',99.9,.F.,'Lin01')
	
	oFWLayer:addWindow ('Etiquetas','Cabec','',25,.F.,.F., {||},'Lin01')
	oWin01 := oFWLayer:GetWinPanel('Etiquetas','Cabec','Lin01')
	
	oFWLayer:addWindow ('Etiquetas','Grid','',75,.F.,.F., {||},'Lin01')
	oWin02 := oFWLayer:GetWinPanel('Etiquetas','Grid','Lin01')
	
	oSay1 := TSay():New( 002, 003, {|| 'PRODUTO : ' + Posicione("SB4",1,xFilial("SB4") + PadR(mv_par01,TamSx3("B4_COD")[1]),"B4_DESC") } ,oWin01 ,, oFont ,,,, .T. , CLR_BLUE ,, 200,010 )
	
	oSay2 := TSay():New( 018, 003, {|| 'IMPRESSORA : ' } ,oWin01 ,, oFont ,,,, .T. , CLR_BLUE ,, 200,010 )
	bSetGet:= {|u| Iif( PCount()==0,cCombo,cCombo := u) }
	oComBox	:= 	TComboBox():New(018,055,bSetGet,aCombo,080,044,oWin01,,/*{|| }*/, , , ,.T.,,,,)
	
	oBtn1 := TButton():New( 015,280, 'Imprimir' , oWin01, {|| SyVldImp() ,oDlg:End() },35,13,,,.F.,.T.,.F.,,.F.,,,.F. )
	oBtn2 := TButton():New( 015,350, 'Cancela'	, oWin01, {|| oDlg:End()},35,13,,,.F.,.T.,.F.,,.F.,,,.F. )
	
	oGetDados := MsNewGetDados():New(0,0,180,400,nlOpc,"Allwaystrue","AllWaysTrue","",{'B2_QATU'},,Len(apColsEq),/*fieldok*/,/*superdel*/,/*del*/,oWin02,@apHeadEt,@apColsEq)
	
	Activate MsDialog oDlg Centered
	
Return (alEtq)


/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณSyVldImp  บAutor  ณSYMM Consultoria    บ Data ณ  02/27/14   บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณ                                                            บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/
Static Function SyVldImp()
	Local aDados := oGetDados:aCols
	Local nPos	 := 0
	Local nX1
	
	For nX1 := 1 To Len(aDados)
		nPos := aScan(aEtiquetas,{|x| Alltrim(x[9]) == Alltrim(aDados[nX1][7]) })
		If nPos > 0
			aEtiquetas[nPos][10] := aDados[nX1][8]
		EndIf
	Next nX1
	
	If cCombo == "Modelo Zebra"
		zebrinha(aEtiquetas)
	Else
		PrintEtq04(aEtiquetas)
	EndIf
	
Return .T.

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณFGASPETQ  บAutor  ณMicrosiga           บ Data ณ  02/27/14   บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณ                                                            บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/
Static Function PrintEtq04(aDados)
	
	Local aArea	  	:= GetArea()
	Local aColuna 	:= {}
	Local aLinha  	:= {}
	Local nEtq    	:= 0
	Local cMsg	  	:= 'Manter etiqueta em caso de troca'  //'Manter esta etiqueta em caso de troca'
	Local aMasc   	:= Separa(GetMv("MV_MASCGRD"),",")
	Local nCor    	:= Val(aMasc[1])+Val(aMasc[2])+1
	Local cPorta  	:= GetMv("MV_ETQPRT",,'LPT1')
	Local lImpPrc 	:= .F.
	Local lRet 		:= .F.
	Local cAuxPrc   := ''
	Local cAuxPrc1  := ''
	Local clData    := ''
	Local nZ
	Local nY
	Local nX
	
	aColuna := {{01,15,22,28,31,39},{54,66,74,81,82,90}}
	aLinha  := { 04;   // [1]Logo
	,13;   // [2]Secao
	,15;   // [3]Marca
	,17;   // [4]Especie
	,18;   // [5]Referencia
	,21;   // [6]Cor
	,25.5; // [7]Mensagem
	,29;   // [8]Tamanho/Cod Barras
	,41;   // [9]Linha Pontilhada
	,44}   // [10]Pre็o
	
	
	clData := DTOS(dDataBase)
	clData := Substr(clData,5,2) + ' ' + Substr(clData,3,2)
	
	//MSCBPRINTER("Z4M",cPorta,,120,.F.,,,,,,.T.)
	
	MSCBPRINTER("ELTRON",cPorta,,120,.F.,,,,,,)
	MSCBCHKStatus(.F.)
	//MSCBLOADGRF('DIGASPB.GRF')
	
	//MSCBBEGIN (1,3)
	
	For nX := 1 To Len(aDados)
		For nY := 1 To aDados[nX,10]
			nEtq += 1
			If ( nEtq = 1)
				MSCBBEGIN(1,4)
			EndIf
			For nZ := 1 To Len(aDados[nX,08])
				If Substr(aDados[nX,08],nZ,1) <> ','
					cAuxPrc += Substr(aDados[nX,08],nZ,1)
				Else
					cAuxPrc1 := Substr(aDados[nX,08],nZ,Len(aDados[nX,08])-Len(cAuxPrc))
					nZ := Len(aDados[nX,08])+1
				EndIf
			Next nZ
			
			//MSCBGRAFIC(aColuna[nEtq,1],aLinha[1],'DIGASPB')
			
			MSCBSAY(aColuna[nEtq,6]		,aLinha[1]  ,clData		 			,"I","2","015,025",.T.)  		 // Mes/Ano
			MSCBSAY(aColuna[nEtq,1]		,aLinha[2]  ,aDados[nX,01] 			,"N","2","025,035",.T.)  		 // Se็ใo
			MSCBSAY(aColuna[nEtq,4]		,aLinha[3]	,aDados[nX,03]			,"N","2","023,033",.T.,,,,.T.)	 // Marca
			MSCBSAY(aColuna[nEtq,1]		,aLinha[4]  ,aDados[nX,02] 			,"N","2","025,035",.T.)  		 // Esp้cie
			MSCBSAY(aColuna[nEtq,4]  	,aLinha[5]	,aDados[nX,04]			,"N","2","019,024",.T.,,,,.T.)   // Descri็ใo da Referencia
			MSCBSAY(aColuna[nEtq,1]		,aLinha[6]	,aDados[nX,05]     		,"N","2","035,045",.T.)          // Descri็ใo da Cor
			MSCBSAY(aColuna[nEtq,1]   	,aLinha[7]	,cMsg					,"N","C","017,009",.T.)          // Mensagem
			//MSCBBOX(aColuna[nEtq,1]		,aLinha[8]	,aColuna[nEtq,1]+14,aLinha[8]+11)                        // Box Tamanho
			MSCBSAY(aColuna[nEtq,1]+1.5	,aLinha[8]+1,'Tamanho'		 		,"N","2","019,024",.T.)
			If Len(aDados[nX,06]) == 1
				MSCBSAY(aColuna[nEtq,1]+05,aLinha[8]+3.5	,aDados[nX,06]		,"N","2","055,065",.T.)       // Tamanho 1 Caracter
			Else
				MSCBSAY(aColuna[nEtq,1]+03,aLinha[8]+3.5	,aDados[nX,06]		,"N","2","055,065",.T.)       // Tamanho 2 Caracteres
			EndIf
			MSCBSAYBAR(aColuna[nEtq,3]		,aLinha[8]	,aDados[nX,07]    		,"N","MB04",09,.F.,.T.,.F.,,2,2,.F.,.F.,"1",.T.) // Codigo de Barras
			MSCBSAY(aColuna[nEtq,1]		,aLinha[9]		,Replicate('-',32)	,"N","2","018,010",.T.)                              // Linha Pontilhada
			
			MSCBSAY(aColuna[nEtq,2]		,aLinha[10]	  	,'R$'		 		,"N","2","025,035",.T.)
			MSCBSAY(aColuna[nEtq,2]+2	,aLinha[10]+3.5	,cAuxPrc	 		,"N","2","080,090",.T.)								// Preco de Venda
			MSCBSAY(aColuna[nEtq,2]+13	,aLinha[10]+3.5	,cAuxPrc1	 		,"N","2","050,060",.T.)
			
			lRet:= .F.
			If ( nEtq = 2)
				MSCBEND()
				nEtq := 0
				lRet:= .T.
			EndIf
			cAuxPrc := ''
			cAuxPrc1 := ''
		Next nY
	Next nX
	
	//If !lRet //nEtq <> 0
	MSCBEND()
	//EndIf
	
	MSCBCLOSEPRINTER()
	
	/*
	MSCBPRINTER("ELTRON","LPT1",,,.F.)
	MSCbModelo("EPL","ELTRON") //Seta o ponto para conversaum
	MSCBCHKStatus(.F.)
	MSCBBOX(aColuna[1,1]		,aLinha[8]	,aColuna[1,1]+14,aLinha[8]+11)                           // Box Tamanho
	MSCBSAY(aColuna[1,6]		,aLinha[1]  ,"02/2014"	 			,"I","0","015,025",.T.)  		 // Mes/Ano
	MSCBSAY(aColuna[1,1]		,aLinha[2]  ,"SECAO 1"	 			,"N","0","025,035",.T.)  		 // Se็ใo
	MSCBSAY(aColuna[1,4]		,aLinha[3]	,"AZALEIA"				,"N","0","023,033",.T.,,,,.T.)	 // Marca
	MSCBSAY(aColuna[1,1]		,aLinha[4]  ,"BOTA"		 			,"N","0","025,035",.T.)  		 // Esp้cie
	MSCBSAY(aColuna[1,4]  		,aLinha[5]	,"BOTA ALTA"			,"N","0","019,024",.T.,,,,.T.)   // Descri็ใo da Referencia
	MSCBSAY(aColuna[1,1]		,aLinha[6]	,"PRETA"	     		,"N","0","035,045",.T.)          // Descri็ใo da Cor
	MSCBSAY(aColuna[1,1]   		,aLinha[7]	,"TESTE IMPRESSORA"		,"N","C","017,009",.T.)          // Mensagem
	MSCBSAY(aColuna[1,1]+1.5	,aLinha[8]+1,'Tamanho'		 		,"N","0","019,024",.T.)
	MSCBEND()
	MSCBCLOSEPRINTER()
	*/
	RestArea(aArea)
	
Return()

Static Function zebrinha(aDados)
	
	Local aArea	  	:= GetArea()
	Local aColuna 	:= {}
	Local aLinha  	:= {}
	Local nEtq    	:= 0
	Local cMsg	  	:= 'Manter etiqueta em caso de troca'  //'Manter esta etiqueta em caso de troca'
	Local aMasc   	:= Separa(GetMv("MV_MASCGRD"),",")
	Local nCor    	:= Val(aMasc[1])+Val(aMasc[2])+1
	Local cPorta  	:= GetMv("MV_ETQPRT",,'LPT1')
	Local lImpPrc 	:= .F.
	Local lRet 		:= .F.
	Local cAuxPrc   := ''
	Local cAuxPrc1  := ''
	Local nZ
	Local nY
	Local nX
	
	Private nlTpEtq
	
	nlTpEtq := 2
	
	If nlTpEtq == 1
		aColuna := {{02,16,18.5,28,32,40},{57,71,73.5,83,87,95}}
		aLinha  := { 02;   // [1]Logo
		,12;   // [2]Secao
		,14;   // [3]Marca
		,16;   // [4]Especie
		,18;   // [5]Referencia
		,20;   // [6]Cor
		,24;   // [7]Mensagem
		,27;   // [8]Tamanho/Cod Barras
		,39;   // [9]Linha Pontilhada
		,42}   // [10]Pre็o
		
	ElseIf nlTpEtq == 2
		aColuna := {{01.5,16,20.1,27,33,39},{54.5,69.5,73.5,81,85,93}}
		aLinha  := { 02;   // [1]Logo
		,11;   // [2]Secao
		,13;   // [3]Marca
		,15;   // [4]Especie
		,17;   // [5]Referencia
		,19;   // [6]Cor
		,23;   // [7]Mensagem
		,26;   // [8]Tamanho/Cod Barras
		,38;   // [9]Linha Pontilhada
		,41}   // [10]Pre็o
	ElseIf nlTpEtq == 3
		aColuna := {{18},{61.2}}
		aLinha  := {1.5}
	EndIf
	
	
	MSCBPRINTER('ZEBRA',cPorta,,)//MSCBPRINTER("TLP 2844",cPorta,,,.F.)
	MSCBCHKStatus(.F.)
	//MSCBLOADGRF('DIGASP2.GRF')
	
	If nlTpEtq <> 3
		For nX := 1 To Len(aDados)
			For nY := 1 To aDados[nX,10]
				/* Quantidade de etiquetas impressa por vez. */
				nEtq += 1
				If ( nEtq = 1)
					MSCBBEGIN(1,3)//QUANTIDADE,VELOCIDADE,LARGURA,ALTURA
				EndIf
				/* Quebra Pre็o na vํrgula para impressใo */
				For nZ := 1 To Len(aDados[nX,08])
					If Substr(aDados[nX,08],nZ,1) <> ','
						cAuxPrc += Substr(aDados[nX,08],nZ,1)
					Else
						cAuxPrc1 := Substr(aDados[nX,08],nZ,Len(aDados[nX,08])-Len(cAuxPrc))
						nZ := Len(aDados[nX,08])+1
					EndIf
				Next nZ
				
				//MSCBGRAFIC(aColuna[nEtq,1],aLinha[1],'DIGASP2')
				
				MSCBSAY(aColuna[nEtq,1]		,aLinha[2]  ,ALLTRIM(aDados[nX,01]) 			,"N","D","1") 									 			/* Se็ใo */
				MSCBSAY(aColuna[nEtq,4]		,aLinha[3]	,ALLTRIM(aDados[nX,03])			,"N","D","1")					 							/* Marca */
				MSCBSAY(aColuna[nEtq,1]		,aLinha[4]  ,ALLTRIM(aDados[nX,02]) 			,"N","D","1") 									 			/* Esp้cie */
				MSCBSAY(aColuna[nEtq,4]		,aLinha[5]	,ALLTRIM(aDados[nX,04])			,"N","D","1")						 						/* Descri็ใo da Referencia */
				MSCBSAY(aColuna[nEtq,1]		,aLinha[6]	,ALLTRIM(aDados[nX,05])     		,"N","D","1") 								   	 			/* Descri็ใo da Cor */
				MSCBSAY(aColuna[nEtq,1]   	,aLinha[7]	,ALLTRIM(cMsg)					,"N","D","1")     										   	/* Mensagem */
				//MSCBBOX(aColuna[nEtq,1]		,aLinha[8]	,aColuna[nEtq,1]+14,aLinha[8]+11)  													/* Box Tamanho */
				MSCBSAY(aColuna[nEtq,1]+1.5	,aLinha[8]+1,'Tamanho'		 		,"N","D","1")
				If Len(aDados[nX,06]) == 1
					MSCBSAY(aColuna[nEtq,1]+05,aLinha[8]+3.5	,aDados[nX,06]		,"N","D","1")      											/* Tamanho 1 Caracter*/
				Else
					MSCBSAY(aColuna[nEtq,1]+03,aLinha[8]+3.5	,aDados[nX,06]		,"N","D","1")      											/* Tamanho 2 Caracteres*/
				EndIf
				MSCBSAYBAR(aColuna[nEtq,3]		,aLinha[8]		,aDados[nX,07]    	,"N","MB04",10,.F.,.T.,.T.,,2,2,.F.,.F.,"1",.T.)        	/* Codigo de Barras */
				MSCBSAY(aColuna[nEtq,1]		,aLinha[9]		,Replicate('-',32)	,"N","D","1")     									  		/* Linha Pontilhada */
				
				MSCBSAY(aColuna[nEtq,2]		,aLinha[10]	  	,'R$'		 		,"N","D","1")
				MSCBSAY(aColuna[nEtq,2]+2	,aLinha[10]+3.5	,cAuxPrc	 		,"N","D","2")     								   	   		/* Preco de Venda */
				MSCBSAY(aColuna[nEtq,2]+11	,aLinha[10]+3.5	,cAuxPrc1	 		,"N","D","2")
				
				lRet:= .F.
				If ( nEtq = 2)
					MSCBEND()
					nEtq := 0
					lRet:= .T.
				EndIf
				cAuxPrc := ''
				cAuxPrc1 := ''
			Next nY
		Next nX
	Else
		For nX := 1 To Len(aDados)
			For nY := 1 To aDados[nX,9]
				/* Quantidade de etiquetas impressa por vez. */
				nEtq += 1
				If ( nEtq = 1)
					MSCBBEGIN(1,3)
				EndIf
				
				MSCBSAYBAR(aColuna[nEtq,1],aLinha[1],aDados[nX,07],"N","MB04",10,.F.,.T.,.T.,,2,2,.F.,.F.,"1",.T.)        	/* Codigo de Barras */
				
				lRet:= .F.
				If ( nEtq = 2)
					MSCBEND()
					nEtq := 0
					lRet:= .T.
				EndIf
			Next nY
		Next nX
	EndIf
	
	If !lRet //nEtq <> 0
		MSCBEND()
	EndIf
	MSCBCLOSEPRINTER()
	RestArea(aArea)
Return()

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณAjustaSx1 บAutor  ณMicrosiga           บ Data ณ  27/02/14   บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณ Cria parametros relatorio                                  บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/
Static Function AjustaSx1(cPerg)
	
	Local aHelp := {}
	
	aHelp := {"Imprimir etiquetas com pre็o ?","Sim","Nใo"}
	
	PutSx1( cPerg, "01", "Produto ?"		  	, "Produto ?"			, "Produto ?"			, "mv_ch1", "C", nlTamCod	, 0	, 0	, "G", "","SB4"	, "", "", "mv_par01",	  ,	    ,	  ,,	 ,	   , 	 ,,,,,,,,,,{"Codigo do Produto Inicial."			  , "", ""},{},{} )
	PutSx1( cPerg, "02", "Quantidade ?"		  	, "Quantidade ?"		, "Quantidade ?"		, "mv_ch2", "N", 04	 		, 0	, 0	, "G", "","   "	, "", "", "mv_par02",	  ,	    ,	  ,,	 ,	   ,	 ,,,,,,,,,,{"Quantidade de Etiquetas por Produto."	  , "", ""},{},{} )
	PutSx1(	cPerg, "03", "Mostra Produtos ?"	, "Mostra Produtos ?"	, "Mostra Produtos ?" 	, "mv_ch3", "N", 01   		, 0	, 0	, "C", "","" 	, "", "", "mv_par03","Sim","Sim","Sim","","Nใo","Nใo","Nใo","","","","","","","","","",aHelp,aHelp,aHelp)
	
Return Nil
