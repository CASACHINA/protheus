#include 'protheus.ch'
#include 'parmtype.ch'
#include 'topconn.ch'


//-----------------------------------------------------------------------
/*/{Protheus.doc} uAJCUSTO1

Relatorio Numerações de Notas e/ou Cupons Faltantes

@author Valberg Moura (3VM Solutions) 
@since 26/03/2019
@version 1.0 
/*/
//-----------------------------------------------------------------------



User Function uRNFINUT1()

	Private _oReport
	Private _cPerg := "uRNFINUT1"
	Private _oSec01

	xPutSx1(_cPerg,'01','Emissao de  ?','','','MV_CH01','D' ,08,0,0,'G','','', '','','MV_PAR01') 
	xPutSx1(_cPerg,'02','Emissao ate ?','','','MV_CH02','D' ,08,0,0,'G','','', '','','MV_PAR02') 
	xPutSx1(_cPerg,'03','Serie   de  ?','','','MV_CH03','C' ,03,0,0,'G','','', '','','MV_PAR03') 
	xPutSx1(_cPerg,'04','Serie   ate ?','','','MV_CH04','C' ,03,0,0,'G','','', '','','MV_PAR04') 

	Pergunte(_cPerg,.f.)

	_oReport := TReport():New("uRNFINUT1","Numeração Faltantes",_cPerg,{|_oReport| PrintReport(_oReport)},"Numerações de Notas e/ou Cupons Faltantes")

	_oReport:SetLandScape(.F.) // .F. Retrato, .T. Paisagem

	//--------------------------------------------------------------------
	// Definicoes da secao Sec01
	//--------------------------------------------------------------------

	_oSec01 := TRSection():New( _oReport , "Sec01",,,,,,,,,,,,,,,,,,,,)
	_oSec01:AddTable("Sec01")
	_oSec01:SetTotalInLine(.F.)


	TRCell():New(_oSec01,"F2_DOC","","",,,,,,,,,,,,)
	_oSec01:Cell("F2_DOC"):cAlias := "Sec01"
	_oSec01:Cell("F2_DOC"):SetTitle("N Fiscal")
	_oSec01:Cell("F2_DOC"):SetSize(9)
	_oSec01:Cell("F2_DOC"):SetPicture("@!")

	TRCell():New(_oSec01,"F2_SERIE","","",,,,,,,,,,,,)
	_oSec01:Cell("F2_SERIE"):cAlias := "Sec01"
	_oSec01:Cell("F2_SERIE"):SetTitle("Serie")
	_oSec01:Cell("F2_SERIE"):SetSize(3)
	_oSec01:Cell("F2_SERIE"):SetPicture("@!")

	TRCell():New(_oSec01,"OBS","","",,,,,,,,,,,,)
	_oSec01:Cell("OBS"):cAlias := "Sec01"
	_oSec01:Cell("OBS"):SetTitle("Obs")
	_oSec01:Cell("OBS"):SetSize(20)
	_oSec01:Cell("OBS"):SetPicture("@!")

	_oReport:PrintDialog()
Return

//--------------------------------------------------------------------
// Função de Impressao do Relatorio
//--------------------------------------------------------------------
Static Function PrintReport(_oReport)

	_oSec01:Init()

	//Seleciona as serie dos parametro para loop
	IIF ( Select("TSER") <> 0 ,TSER->(DbCloseArea()),)
	BEGINSQL ALIAS "TSER"
		%noparser%
		SELECT DISTINCT F2_SERIE FROM %table:SF2%
		WHERE F2_FILIAL = %xfilial:SF2%
		AND F2_EMISSAO BETWEEN %exp:MV_PAR01% AND %exp:MV_PAR02%
		AND F2_SERIE  BETWEEN %exp:MV_PAR03% AND %exp:MV_PAR04%
		AND D_E_L_E_T_=''
		ORDER BY F2_SERIE
	ENDSQL

	While TSER->(!Eof())

		//Selecao de Registros da secao Sec01
		IIF ( Select("Sec01") <> 0 ,Sec01->(DbCloseArea()),)
		BEGINSQL ALIAS "Sec01"
			%noparser%
			SELECT * FROM %table:SF2%
			WHERE F2_FILIAL = %xfilial:SF2%
			AND F2_EMISSAO BETWEEN %exp:MV_PAR01% AND %exp:MV_PAR02%
			AND F2_SERIE  = %exp:TSER->F2_SERIE%
			AND D_E_L_E_T_=''
			ORDER BY F2_DOC, F2_SERIE
		ENDSQL


		_aFuroNF := {}
		_cAux    := ""
		_cProxNF := Alltrim(Sec01->F2_DOC)

		While Sec01->(!Eof())
			If _cProxNF < Alltrim(Sec01->F2_DOC)
				aAdd(_aFuroNF,_cProxNF)
				_cAux := _cProxNF
				_cProxNF := Soma1(_cAux)
			Else
				_cProxNF := Soma1(Alltrim(Sec01->F2_DOC))
				Sec01->(Dbskip())
			Endif
		Enddo

		For _i := 1 to Len(_aFuroNF)

			_oSec01:Cell("F2_DOC"):SetValue(_aFuroNF[_i])
			_oSec01:Cell("F2_SERIE"):SetValue(TSER->F2_SERIE)


			//Seleciona a observação da NF
			IIF ( Select("TOBS") <> 0 ,TOBS->(DbCloseArea()),)
			BEGINSQL ALIAS "TOBS"
				%noparser%
				SELECT F3_OBSERV FROM %table:SF3%
				WHERE F3_FILIAL = %xfilial:SF3%
				AND F3_NFISCAL = %exp:_aFuroNF[_i]%
				AND F3_SERIE = %exp:TSER->F2_SERIE%
				AND F3_CFO > '5000'
				AND D_E_L_E_T_=''
			ENDSQL

			_oSec01:Cell("OBS"):SetValue(TOBS->F3_OBSERV)

			_oSec01:Printline()


			Sec01->(DbSkip())

		Next _i

		TSER->(Dbskip())
	Enddo
	_oSec01:finish()
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

