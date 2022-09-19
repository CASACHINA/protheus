#INCLUDE "Topconn.ch"
#INCLUDE "Protheus.ch"

/*
------------------------------------------------------------------
Programa : URELTRST
Autor    : 
Data     : 26/08/2019
Descricao: Relatorio Transferencia - Apuração ICMS
------------------------------------------------------------------
*/

User Function URELTRST()

	Private _oReport
	Private _cPerg := "URELTRST"
	Private _oTRFIL

	xPutSx1( _cPerg, "01" , "Emissao de ?", "", "", "mv_ch01", "D", 8, 0 ,  , "G" , "" , "" , "" , "" , "mv_par01", "" , "" , "" , "" , "" , "" , "" , "" , "" , "" , "" , "" , "" , "", "" , "" )
	xPutSx1( _cPerg, "02" , "Emissao ate ?", "", "", "mv_ch02", "D", 8, 0 ,  , "G" , "" , "" , "" , "" , "mv_par02", "" , "" , "" , "" , "" , "" , "" , "" , "" , "" , "" , "" , "" , "", "" , "" )

	Pergunte(_cPerg,.F.)

	_oReport := TReport():New("URELTRST","Transferencia - Apuração ICMS",_cPerg,{|_oReport| __PRPrint(_oReport)},"Relatorio Transferencia - Apuração ICMS")
	_oReport:nfontbody:=10
	_oReport:SetLandScape(.F.) // .F. Retrato, .T. Paisagem

	//--------------------------------------------------------------------
	// Definicoes da secao TRFIL
	//--------------------------------------------------------------------

	_oTRFIL := TRSection():New( _oReport ,,,,,,,,,,,,,,,,,,,,,)
	//_oTRFIL:AddTable("TRFIL")
	_oTRFIL:SetTotalInLine(.F.)


	TRCell():New(_oTRFIL,"NNT_FILDES","","",,,,,,,,,,,,)
	//_oTRFIL:Cell("NNT_FILDES"):cAlias := "TRFIL"
	_oTRFIL:Cell("NNT_FILDES"):SetTitle("Fil Destino")
	_oTRFIL:Cell("NNT_FILDES"):SetSize(6)
	_oTRFIL:Cell("NNT_FILDES"):SetPicture("@!")

	TRCell():New(_oTRFIL,"D2_EMISSAO","","",,,,,,,,,,,,)
	//_oTRFIL:Cell("D2_EMISSAO"):cAlias := "TRFIL"
	_oTRFIL:Cell("D2_EMISSAO"):SetTitle("DT Emissao")
	_oTRFIL:Cell("D2_EMISSAO"):SetSize(8)
	_oTRFIL:Cell("D2_EMISSAO"):SetPicture("@D")

	TRCell():New(_oTRFIL,"D2_DOC","","",,,,,,,,,,,,)
	//_oTRFIL:Cell("D2_DOC"):cAlias := "TRFIL"
	_oTRFIL:Cell("D2_DOC"):SetTitle("NFe Transf")
	_oTRFIL:Cell("D2_DOC"):SetSize(9)
	_oTRFIL:Cell("D2_DOC"):SetPicture("@!")

	TRCell():New(_oTRFIL,"D2_SERIE","","",,,,,,,,,,,,)
	//_oTRFIL:Cell("D2_SERIE"):cAlias := "TRFIL"
	_oTRFIL:Cell("D2_SERIE"):SetTitle("Serie")
	_oTRFIL:Cell("D2_SERIE"):SetSize(3)
	_oTRFIL:Cell("D2_SERIE"):SetPicture("@!")

	TRCell():New(_oTRFIL,"ST_EXTORN","","",,,,,,,,,,,,)
	//_oTRFIL:Cell("ST_EXTORN"):cAlias := "TRFIL"
	_oTRFIL:Cell("ST_EXTORN"):SetTitle("ST a Estornar")
	_oTRFIL:Cell("ST_EXTORN"):SetSize(14)
	_oTRFIL:Cell("ST_EXTORN"):SetPicture("@E 999,999.99")

	TRCell():New(_oTRFIL,"ICMS_TRANS","","",,,,,,,,,,,,)
	//_oTRFIL:Cell("ICMS_TRANS"):cAlias := "TRFIL"
	_oTRFIL:Cell("ICMS_TRANS"):SetTitle("ICMS Transf.")
	_oTRFIL:Cell("ICMS_TRANS"):SetSize(14)
	_oTRFIL:Cell("ICMS_TRANS"):SetPicture("@E 999,999.99")

	_oReport:PrintDialog()
Return

//--------------------------------------------------------------------
// Função de Impressao do Relatorio
//--------------------------------------------------------------------
Static Function __PRPrint(_oReport)


	//Selecao de Registros da secao TRFIL

	IIF ( Select("TRFIL") <> 0 ,TRFIL->(DbCloseArea()),)
	
	BEGIN REPORT QUERY _oReport:Section(1)
	
	BEGINSQL ALIAS "TRFIL"
		column D2_EMISSAO as Date
		%noparser%
		SELECT NNT_FILDES,D2_EMISSAO, D2_DOC, D2_SERIE, SUM(D2_DESCON) AS ST_EXTORN, SUM(D2_VALICM)AS  ICMS_TRANSF
		FROM %table:SD2%  SD2
		INNER JOIN %table:NNT%  NNT ON ( NNT_FILIAL = D2_FILIAL
		AND NNT_FILDES IN ('010106','010107','010109','010110')
		AND NNT_DOC = D2_DOC
		AND NNT_SERIE = D2_SERIE
		AND NNT_PROD = D2_COD
		AND NNT.D_E_L_E_T_ ='')
		WHERE D2_FILIAL= %xfilial:SD2%
		AND D2_EMISSAO BETWEEN %exp:MV_PAR01% AND %exp:MV_PAR02%
		AND D2_PRUNIT > D2_PRCVEN
		AND SD2.D_E_L_E_T_ =''
		GROUP BY  NNT_FILDES,D2_EMISSAO, D2_DOC, D2_SERIE
		ORDER BY  NNT_FILDES,D2_EMISSAO, D2_DOC, D2_SERIE
	ENDSQL
	
	END REPORT QUERY _oReport:Section(1)

	_oTRFIL:Init()
	While TRFIL->(!Eof())
		_oTRFIL:Cell("NNT_FILDES"):SetValue(TRFIL->NNT_FILDES)
		_oTRFIL:Cell("D2_EMISSAO"):SetValue(TRFIL->D2_EMISSAO)
		_oTRFIL:Cell("D2_DOC"):SetValue(TRFIL->D2_DOC)
		_oTRFIL:Cell("D2_SERIE"):SetValue(TRFIL->D2_SERIE)
		_oTRFIL:Cell("ST_EXTORN"):SetValue(TRFIL->ST_EXTORN)
		_oTRFIL:Cell("ICMS_TRANS"):SetValue(TRFIL->ICMS_TRANS)

		_oTRFIL:Printline()


		TRFIL->(DbSkip())

	Enddo

	_oTRFIL:finish()
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