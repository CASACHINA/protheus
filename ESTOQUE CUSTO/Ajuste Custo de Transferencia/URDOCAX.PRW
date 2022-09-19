#INCLUDE "Topconn.ch"
#INCLUDE "Protheus.ch"

/*
------------------------------------------------------------------
Programa : URDOCAX
Autor    : 
Data     : 26/08/2019
Descricao: Relatorio Transferencia - Origem do Calculo
------------------------------------------------------------------
*/

User Function URDOCAX()

	Private _oReport
	Private _cPerg := "URDOCAX"
	Private _oSECDOC
	Private _oSECPROD
	Private _oSECORI

	xPutSx1( _cPerg, "01" , "Emissao de?", "", "", "mv_ch01", "D", 8, 0 ,  , "G" , "" , "" , "" , "" , "mv_par01", "" , "" , "" , "" , "" , "" , "" , "" , "" , "" , "" , "" , "" , "", "" , "" )
	xPutSx1( _cPerg, "02" , "Emissao ate?", "", "", "mv_ch02", "D", 8, 0 ,  , "G" , "" , "" , "" , "" , "mv_par02", "" , "" , "" , "" , "" , "" , "" , "" , "" , "" , "" , "" , "" , "", "" , "" )

	Pergunte(_cPerg,.f.)

	_oReport := TReport():New("URDOCAX","Transferencia - Origem do Calc",_cPerg,{|_oReport| PrintReport(_oReport)},"Relatorio Transferencia - Origem do Calculo")

	_oReport:SetLandScape(.F.) // .F. Retrato, .T. Paisagem

	//--------------------------------------------------------------------
	// Definicoes da secao SECDOC
	//--------------------------------------------------------------------

	_oSECDOC := TRSection():New( _oReport , ,,,,,,,,,,,,,,,,,,,,)
	//_oSECDOC:AddTable("SECDOC")
	_oSECDOC:SetTotalInLine(.F.)


	TRCell():New(_oSECDOC,"D2_EMISSAO","","",,,,,,,,,,,,)
	_oSECDOC:Cell("D2_EMISSAO"):cAlias := "SECDOC"
	_oSECDOC:Cell("D2_EMISSAO"):SetTitle("DT Emissao")
	_oSECDOC:Cell("D2_EMISSAO"):SetSize(8)
	_oSECDOC:Cell("D2_EMISSAO"):SetPicture("@D")

	TRCell():New(_oSECDOC,"NNT_FILDES","","",,,,,,,,,,,,)
	_oSECDOC:Cell("NNT_FILDES"):cAlias := "SECDOC"
	_oSECDOC:Cell("NNT_FILDES"):SetTitle("Filial Destino")
	_oSECDOC:Cell("NNT_FILDES"):SetSize(6)
	_oSECDOC:Cell("NNT_FILDES"):SetPicture("@!")

	TRCell():New(_oSECDOC,"D2_DOC","","",,,,,,,,,,,,)
	_oSECDOC:Cell("D2_DOC"):cAlias := "SECDOC"
	_oSECDOC:Cell("D2_DOC"):SetTitle("NFe Transf.")
	_oSECDOC:Cell("D2_DOC"):SetSize(9)
	_oSECDOC:Cell("D2_DOC"):SetPicture("@!")

	TRCell():New(_oSECDOC,"D2_SERIE","","",,,,,,,,,,,,)
	_oSECDOC:Cell("D2_SERIE"):cAlias := "SECDOC"
	_oSECDOC:Cell("D2_SERIE"):SetTitle("Serie")
	_oSECDOC:Cell("D2_SERIE"):SetSize(3)
	_oSECDOC:Cell("D2_SERIE"):SetPicture("@!")


	//--------------------------------------------------------------------
	// Definicoes da secao SECPROD
	//--------------------------------------------------------------------

	_oSECPROD := TRSection():New( _oSECDOC , "SECPROD",,,,,,,,,,,,,,,,,,,,)
	_oSECPROD:AddTable("SECPROD")
	_oSECPROD:SetTotalInLine(.F.)


	TRCell():New(_oSECPROD,"QB01","","",,,,,,,,,,,,)
	_oSECPROD:Cell("QB01"):cAlias := "SECPROD"
	_oSECPROD:Cell("QB01"):SetTitle("     ")
	_oSECPROD:Cell("QB01"):SetSize(5)
	_oSECPROD:Cell("QB01"):SetPicture("@!")

	TRCell():New(_oSECPROD,"D2_COD","","",,,,,,,,,,,,)
	_oSECPROD:Cell("D2_COD"):cAlias := "SECPROD"
	_oSECPROD:Cell("D2_COD"):SetTitle("Cod Produto")
	_oSECPROD:Cell("D2_COD"):SetSize(15)
	_oSECPROD:Cell("D2_COD"):SetPicture("@!")

	TRCell():New(_oSECPROD,"B1_DESC","","",,,,,,,,,,,,)
	_oSECPROD:Cell("B1_DESC"):cAlias := "SECPROD"
	_oSECPROD:Cell("B1_DESC"):SetTitle("Produto")
	_oSECPROD:Cell("B1_DESC"):SetSize(60)
	_oSECPROD:Cell("B1_DESC"):SetPicture("@!")


	//--------------------------------------------------------------------
	// Definicoes da secao SECORI
	//--------------------------------------------------------------------

	_oSECORI := TRSection():New( _oSECPROD , "SECORI",,,,,,,,,,,,,,,,,,,,)
	_oSECORI:AddTable("SECORI")
	_oSECORI:SetTotalInLine(.F.)


	TRCell():New(_oSECORI,"QB02","","",,,,,,,,,,,,)
	_oSECORI:Cell("QB02"):cAlias := "SECORI"
	_oSECORI:Cell("QB02"):SetTitle("         ")
	_oSECORI:Cell("QB02"):SetSize(10)
	_oSECORI:Cell("QB02"):SetPicture("@!")

	TRCell():New(_oSECORI,"F1_EMISSAO","","",,,,,,,,,,,,)
	_oSECORI:Cell("F1_EMISSAO"):cAlias := "SECORI"
	_oSECORI:Cell("F1_EMISSAO"):SetTitle("DT Emissao")
	_oSECORI:Cell("F1_EMISSAO"):SetSize(8)
	_oSECORI:Cell("F1_EMISSAO"):SetPicture("@D")


	TRCell():New(_oSECORI,"F1_DOC","","",,,,,,,,,,,,)
	_oSECORI:Cell("F1_DOC"):cAlias := "SECORI"
	_oSECORI:Cell("F1_DOC"):SetTitle("NFe")
	_oSECORI:Cell("F1_DOC"):SetSize(9)
	_oSECORI:Cell("F1_DOC"):SetPicture("@!")

	TRCell():New(_oSECORI,"F1_SERIE","","",,,,,,,,,,,,)
	_oSECORI:Cell("F1_SERIE"):cAlias := "SECORI"
	_oSECORI:Cell("F1_SERIE"):SetTitle("Serie")
	_oSECORI:Cell("F1_SERIE"):SetSize(3)
	_oSECORI:Cell("F1_SERIE"):SetPicture("@!")

	TRCell():New(_oSECORI,"F1_CHVNFE","","",,,,,,,,,,,,)
	_oSECORI:Cell("F1_CHVNFE"):cAlias := "SECORI"
	_oSECORI:Cell("F1_CHVNFE"):SetTitle("Chave NFe")
	_oSECORI:Cell("F1_CHVNFE"):SetSize(44)
	_oSECORI:Cell("F1_CHVNFE"):SetPicture("@!")

	TRCell():New(_oSECORI,"F1_FORNECE","","",,,,,,,,,,,,)
	_oSECORI:Cell("F1_FORNECE"):cAlias := "SECORI"
	_oSECORI:Cell("F1_FORNECE"):SetTitle("Cod Fornecedor")
	_oSECORI:Cell("F1_FORNECE"):SetSize(6)
	_oSECORI:Cell("F1_FORNECE"):SetPicture("@!")

	TRCell():New(_oSECORI,"F1_LOJA","","",,,,,,,,,,,,)
	_oSECORI:Cell("F1_LOJA"):cAlias := "SECORI"
	_oSECORI:Cell("F1_LOJA"):SetTitle("Loja")
	_oSECORI:Cell("F1_LOJA"):SetSize(2)
	_oSECORI:Cell("F1_LOJA"):SetPicture("@!")

	TRCell():New(_oSECORI,"A2_NOME","","",,,,,,,,,,,,)
	_oSECORI:Cell("A2_NOME"):cAlias := "SECORI"
	_oSECORI:Cell("A2_NOME"):SetTitle("Fornecedor")
	_oSECORI:Cell("A2_NOME"):SetSize(50)
	_oSECORI:Cell("A2_NOME"):SetPicture("@!")

	TRCell():New(_oSECORI,"A2_CGC","","",,,,,,,,,,,,)
	_oSECORI:Cell("A2_CGC"):cAlias := "SECORI"
	_oSECORI:Cell("A2_CGC"):SetTitle("CNPJ")
	_oSECORI:Cell("A2_CGC"):SetSize(13)
	_oSECORI:Cell("A2_CGC"):SetPicture("@!")

	TRCell():New(_oSECORI,"A2_EST","","",,,,,,,,,,,,)
	_oSECORI:Cell("A2_EST"):cAlias := "SECORI"
	_oSECORI:Cell("A2_EST"):SetTitle("UF")
	_oSECORI:Cell("A2_EST"):SetSize(2)
	_oSECORI:Cell("A2_EST"):SetPicture("@!")

	TRCell():New(_oSECORI,"D1_CF","","",,,,,,,,,,,,)
	_oSECORI:Cell("D1_CF"):cAlias := "SECORI"
	_oSECORI:Cell("D1_CF"):SetTitle("CFOP")
	_oSECORI:Cell("D1_CF"):SetSize(4)
	_oSECORI:Cell("D1_CF"):SetPicture("@!")

	TRCell():New(_oSECORI,"D1_QUANT","","",,,,,,,,,,,,)
	_oSECORI:Cell("D1_QUANT"):cAlias := "SECORI"
	_oSECORI:Cell("D1_QUANT"):SetTitle("Quant")
	_oSECORI:Cell("D1_QUANT"):SetSize(8)
	_oSECORI:Cell("D1_QUANT"):SetPicture("@e 99999.999")

	TRCell():New(_oSECORI,"D1_UM","","",,,,,,,,,,,,)
	_oSECORI:Cell("D1_UM"):cAlias := "SECORI"
	_oSECORI:Cell("D1_UM"):SetTitle("UM")
	_oSECORI:Cell("D1_UM"):SetSize(2)
	_oSECORI:Cell("D1_UM"):SetPicture("@!")

	TRCell():New(_oSECORI,"D1_TOTAL","","",,,,,,,,,,,,)
	_oSECORI:Cell("D1_TOTAL"):cAlias := "SECORI"
	_oSECORI:Cell("D1_TOTAL"):SetTitle("Vlr Item")
	_oSECORI:Cell("D1_TOTAL"):SetSize(8)
	_oSECORI:Cell("D1_TOTAL"):SetPicture("@e 99999.99")

	TRCell():New(_oSECORI,"D1_BASEICM","","",,,,,,,,,,,,)
	_oSECORI:Cell("D1_BASEICM"):cAlias := "SECORI"
	_oSECORI:Cell("D1_BASEICM"):SetTitle("Base ICMS")
	_oSECORI:Cell("D1_BASEICM"):SetSize(8)
	_oSECORI:Cell("D1_BASEICM"):SetPicture("@e 99999.99")

	TRCell():New(_oSECORI,"D1_PICM","","",,,,,,,,,,,,)
	_oSECORI:Cell("D1_PICM"):cAlias := "SECORI"
	_oSECORI:Cell("D1_PICM"):SetTitle("Aliquota")
	_oSECORI:Cell("D1_PICM"):SetSize(6)
	_oSECORI:Cell("D1_PICM"):SetPicture("@e 999.99")

	TRCell():New(_oSECORI,"D1_BRICMS","","",,,,,,,,,,,,)
	_oSECORI:Cell("D1_BRICMS"):cAlias := "SECORI"
	_oSECORI:Cell("D1_BRICMS"):SetTitle("Base Cálculo ST")
	_oSECORI:Cell("D1_BRICMS"):SetSize(10)
	_oSECORI:Cell("D1_BRICMS"):SetPicture("@e 999,999.99")

	TRCell():New(_oSECORI,"D1_ICMSRET","","",,,,,,,,,,,,)
	_oSECORI:Cell("D1_ICMSRET"):cAlias := "SECORI"
	_oSECORI:Cell("D1_ICMSRET"):SetTitle("ICMS ST")
	_oSECORI:Cell("D1_ICMSRET"):SetSize(10)
	_oSECORI:Cell("D1_ICMSRET"):SetPicture("@e 999,999.99")


	_oReport:PrintDialog()
Return

//--------------------------------------------------------------------
// Função de Impressao do Relatorio
//--------------------------------------------------------------------
Static Function PrintReport(_oReport)


	//Selecao de Registros da secao SECDOC

	IIF ( Select("SECDOC") <> 0 ,SECDOC->(DbCloseArea()),)
	BEGINSQL ALIAS "SECDOC"
		column D2_EMISSAO as Date
		%noparser%
		SELECT D2_EMISSAO,NNT_FILDES, D2_DOC, D2_SERIE
		FROM %table:SD2% SD2
		INNER JOIN %table:NNT% NNT ON ( NNT_FILIAL = D2_FILIAL
		AND NNT_FILDES IN ('010106','010107','010109','010110')
		AND NNT_DOC = D2_DOC
		AND NNT_SERIE = D2_SERIE
		AND NNT_PROD = D2_COD
		AND NNT.D_E_L_E_T_ ='')
		WHERE D2_FILIAL= %xfilial:SD2%
		AND D2_EMISSAO BETWEEN %exp:MV_PAR01% AND %exp:MV_PAR02%
		AND D2_PRUNIT > D2_PRCVEN
		AND SD2.D_E_L_E_T_ =''
		GROUP BY D2_CLIENTE, NNT_FILDES,D2_EMISSAO, D2_DOC, D2_SERIE
		ORDER BY  D2_CLIENTE,NNT_FILDES,D2_EMISSAO, D2_DOC, D2_SERIE
	ENDSQL

	_oSECDOC:Init()
	While SECDOC->(!Eof())
		_oSECDOC:Cell("D2_EMISSAO"):SetValue(SECDOC->D2_EMISSAO)
		_oSECDOC:Cell("NNT_FILDES"):SetValue(SECDOC->NNT_FILDES)
		_oSECDOC:Cell("D2_DOC"):SetValue(SECDOC->D2_DOC)
		_oSECDOC:Cell("D2_SERIE"):SetValue(SECDOC->D2_SERIE)

		_oSECDOC:Printline()


		//Selecao de Registros da secao SECPROD

		IIF ( Select("SECPROD") <> 0 ,SECPROD->(DbCloseArea()),)
		BEGINSQL ALIAS "SECPROD"
			%noparser%
			SELECT D2_COD, B1_DESC FROM %table:SD2% SD2
			INNER JOIN %table:SB1% SB1 ON (B1_COD = D2_COD AND SB1.D_E_L_E_T_='')
			WHERE D2_FILIAL = %xfilial:SD2%
			AND D2_DOC = %exp:SECDOC->D2_DOC%
			AND D2_SERIE = %exp:SECDOC->D2_SERIE%
			AND SD2.D_E_L_E_T_ =''
		ENDSQL

		_oSECPROD:Init()
		While SECPROD->(!Eof())


			//Localiza a ultima data de calculo de custo
			IIF ( Select("DTCUSTO") <> 0 ,DTCUSTO->(DbCloseArea()),)
			BEGINSQL ALIAS "DTCUSTO"
				column Z04_DCUSTO as Date
				%noparser%
				SELECT MAX(Z04_DCUSTO) AS Z04_DCUSTO FROM Z04010
				WHERE Z04_FILIAL = %xfilial:Z04%
				AND Z04_DCUSTO <= %exp:SECDOC->D2_EMISSAO%
				AND Z04_PRODUT = %exp:SECPROD->D2_COD%
				AND D_E_L_E_T_ =''
			ENDSQL



			//Selecao de Registros da secao SECORI
			IIF ( Select("SECORI") <> 0 ,SECORI->(DbCloseArea()),)
			BEGINSQL ALIAS "SECORI"
				column F1_EMISSAO as Date
				%noparser%
				SELECT F1_EMISSAO,F1_DOC,F1_SERIE,F1_CHVNFE,F1_FORNECE,F1_LOJA, A2_NOME, A2_CGC, D1_CF, A2_EST, D1_QUANT, D1_UM ,D1_TOTAL,D1_BASEICM, D1_PICM, D1_BRICMS,D1_ICMSRET 
				FROM %table:Z04% Z04
				INNER JOIN %table:SF1% SF1 ON (F1_FILIAL=Z04_FILIAL AND F1_DOC=Z04_DOC AND F1_SERIE=Z04_SERIE AND F1_FORNECE=Z04_FORNEC AND F1_LOJA = Z04_LOJA AND SF1.D_E_L_E_T_='')
				INNER JOIN %table:SA2% SA2 ON (A2_COD = F1_FORNECE AND A2_LOJA = F1_LOJA AND SA2.D_E_L_E_T_ ='')
				INNER JOIN %table:SD1% SD1 ON (D1_FILIAL=Z04_FILIAL AND D1_DOC=Z04_DOC AND D1_SERIE=Z04_SERIE AND D1_FORNECE=Z04_FORNEC AND D1_LOJA = Z04_LOJA AND D1_COD=Z04_PRODUT AND SD1.D_E_L_E_T_='')
				WHERE Z04_FILIAL = %xfilial:Z04%
				AND Z04_DCUSTO = %exp:DTCUSTO->Z04_DCUSTO%
				AND Z04_PRODUT = %exp:SECPROD->D2_COD%
				AND Z04.D_E_L_E_T_ =''
			ENDSQL


//				INNER JOIN %table:SB1% SB1 ON (B1_COD=Z04_PRODUT AND SB1.D_E_L_E_T_='')

			If !Empty(SECORI->F1_EMISSAO)

				_oSECPROD:Cell("D2_COD"):SetValue(SECPROD->D2_COD)
				_oSECPROD:Cell("B1_DESC"):SetValue(SECPROD->B1_DESC)

				_oSECPROD:Printline()

				_oSECORI:Init()
				While SECORI->(!Eof())

					_oSECORI:Cell("F1_EMISSAO"):SetValue(SECORI->F1_EMISSAO)
					_oSECORI:Cell("F1_DOC"):SetValue(SECORI->F1_DOC)
					_oSECORI:Cell("F1_SERIE"):SetValue(SECORI->F1_SERIE)
					_oSECORI:Cell("F1_CHVNFE"):SetValue(SECORI->F1_CHVNFE)
					_oSECORI:Cell("F1_FORNECE"):SetValue(SECORI->F1_FORNECE)
					_oSECORI:Cell("F1_LOJA"):SetValue(SECORI->F1_LOJA)
					_oSECORI:Cell("A2_NOME"):SetValue(SECORI->A2_NOME)
					_oSECORI:Cell("A2_CGC"):SetValue(SECORI->A2_CGC)
					_oSECORI:Cell("A2_EST"):SetValue(A2_EST)
					_oSECORI:Cell("D1_CF"):SetValue(SECORI->D1_CF)
					_oSECORI:Cell("D1_QUANT"):SetValue(SECORI->D1_QUANT)
					_oSECORI:Cell("D1_UM"):SetValue(SECORI->D1_UM)
					_oSECORI:Cell("D1_TOTAL"):SetValue(SECORI->D1_TOTAL)
					_oSECORI:Cell("D1_BASEICM"):SetValue(SECORI->D1_BASEICM)
					_oSECORI:Cell("D1_PICM"):SetValue(SECORI->D1_PICM)
					_oSECORI:Cell("D1_BRICMS"):SetValue(SECORI->D1_BRICMS)
					_oSECORI:Cell("D1_ICMSRET"):SetValue(SECORI->D1_ICMSRET)


					_oSECORI:Printline()


					SECORI->(DbSkip())

				Enddo


				_oSECORI:finish()

			Endif

			_oReport:ThinLine()

			SECPROD->(DbSkip())

		Enddo


		_oSECPROD:finish()


		SECDOC->(DbSkip())

	Enddo

	_oSECDOC:finish()
Return




Static Function xPutSx1(cGrupo,cOrdem,cPergunt,cPerSpa,cPerEng,cVar,; 
	cTipo ,nTamanho,nDecimal,nPresel,cGSC,cValid,; 
	cF3, cGrpSxg,cPyme,; 
	cVar01,cDef01,cDefSpa1,cDefEng1,cCnt01,; 
	cDef02,cDefSpa2,cDefEng2,; 
	cDef03,cDefSpa3,cDefEng3,; 
	cDef04,cDefSpa4,cDefEng4,; 
	cDef05,cDefSpa5,cDefEng5,; 
	aHelpPor,aHelpEng,aHelpSpa,cHelp) 

	LOCAL aArea := GetArea() 
	Local cKey 
	Local lPort := .f. 
	Local lSpa := .f. 
	Local lIngl := .f. 

	cKey := "P." + AllTrim( cGrupo ) + AllTrim( cOrdem ) + "." 

	cPyme    := Iif( cPyme           == Nil, " ", cPyme          ) 
	cF3      := Iif( cF3           == NIl, " ", cF3          ) 
	cGrpSxg := Iif( cGrpSxg     == Nil, " ", cGrpSxg     ) 
	cCnt01   := Iif( cCnt01          == Nil, "" , cCnt01      ) 
	cHelp      := Iif( cHelp          == Nil, "" , cHelp          ) 

	dbSelectArea( "SX1" ) 
	dbSetOrder( 1 ) 

	cGrupo := PadR( cGrupo , Len( SX1->X1_GRUPO ) , " " ) 

	If !( DbSeek( cGrupo + cOrdem )) 

		cPergunt:= If(! "?" $ cPergunt .And. ! Empty(cPergunt),Alltrim(cPergunt)+" ?",cPergunt) 
		cPerSpa     := If(! "?" $ cPerSpa .And. ! Empty(cPerSpa) ,Alltrim(cPerSpa) +" ?",cPerSpa) 
		cPerEng     := If(! "?" $ cPerEng .And. ! Empty(cPerEng) ,Alltrim(cPerEng) +" ?",cPerEng) 

		Reclock( "SX1" , .T. ) 

		Replace X1_GRUPO   With cGrupo 
		Replace X1_ORDEM   With cOrdem 
		Replace X1_PERGUNT With cPergunt 
		Replace X1_PERSPA With cPerSpa 
		Replace X1_PERENG With cPerEng 
		Replace X1_VARIAVL With cVar 
		Replace X1_TIPO    With cTipo 
		Replace X1_TAMANHO With nTamanho 
		Replace X1_DECIMAL With nDecimal 
		Replace X1_PRESEL With nPresel 
		Replace X1_GSC     With cGSC 
		Replace X1_VALID   With cValid 

		Replace X1_VAR01   With cVar01 

		Replace X1_F3      With cF3 
		Replace X1_GRPSXG With cGrpSxg 

		If Fieldpos("X1_PYME") > 0 
			If cPyme != Nil 
				Replace X1_PYME With cPyme 
			Endif 
		Endif 

		Replace X1_CNT01   With cCnt01 
		If cGSC == "C"               // Mult Escolha 
			Replace X1_DEF01   With cDef01 
			Replace X1_DEFSPA1 With cDefSpa1 
			Replace X1_DEFENG1 With cDefEng1 

			Replace X1_DEF02   With cDef02 
			Replace X1_DEFSPA2 With cDefSpa2 
			Replace X1_DEFENG2 With cDefEng2 

			Replace X1_DEF03   With cDef03 
			Replace X1_DEFSPA3 With cDefSpa3 
			Replace X1_DEFENG3 With cDefEng3 

			Replace X1_DEF04   With cDef04 
			Replace X1_DEFSPA4 With cDefSpa4 
			Replace X1_DEFENG4 With cDefEng4 

			Replace X1_DEF05   With cDef05 
			Replace X1_DEFSPA5 With cDefSpa5 
			Replace X1_DEFENG5 With cDefEng5 
		Endif 

		Replace X1_HELP With cHelp 

		PutSX1Help(cKey,aHelpPor,aHelpEng,aHelpSpa) 

		MsUnlock() 
	Else 

		lPort := ! "?" $ X1_PERGUNT .And. ! Empty(SX1->X1_PERGUNT) 
		lSpa := ! "?" $ X1_PERSPA .And. ! Empty(SX1->X1_PERSPA) 
		lIngl := ! "?" $ X1_PERENG .And. ! Empty(SX1->X1_PERENG) 

		If lPort .Or. lSpa .Or. lIngl 
			RecLock("SX1",.F.) 
			If lPort 
				SX1->X1_PERGUNT:= Alltrim(SX1->X1_PERGUNT)+" ?" 
			EndIf 
			If lSpa 
				SX1->X1_PERSPA := Alltrim(SX1->X1_PERSPA) +" ?" 
			EndIf 
			If lIngl 
				SX1->X1_PERENG := Alltrim(SX1->X1_PERENG) +" ?" 
			EndIf 
			SX1->(MsUnLock()) 
		EndIf 
	Endif 

	RestArea( aArea ) 

Return