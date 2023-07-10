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

	//xPutSx1(_cPerg,'01','Emissao de  ?','','','MV_CH01','D' ,08,0,0,'G','','', '','','MV_PAR01') 
	//xPutSx1(_cPerg,'02','Emissao ate ?','','','MV_CH02','D' ,08,0,0,'G','','', '','','MV_PAR02') 
	//xPutSx1(_cPerg,'03','Serie   de  ?','','','MV_CH03','C' ,03,0,0,'G','','', '','','MV_PAR03') 
	//xPutSx1(_cPerg,'04','Serie   ate ?','','','MV_CH04','C' ,03,0,0,'G','','', '','','MV_PAR04') 

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
	Local _i := 0

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


