#include 'protheus.ch'
#include "fwbrowse.ch"


user function CCnLogErro()


	Local oModal, oBrowse
	Local cAlias


	oModal := FWDialogModal():New()
	oModal:SetEscClose(.T.)
	oModal:SetTitle("Consulta Log")
	oModal:EnableAllClient()
	oModal:CreateDialog()
	oModal:createFormBar()
	//oModal:addButtons({{'', 'Processar', {|| lOk := .T., oModal:Deactivate() },'Clique aqui para processar as baixas', ,.T.,.T.}})
	oModal:addCloseButton()

	oBrowseTotais := FWBrowse():New()
	oBrowseTotais:SetOwner( oModal:getPanelMain() )
	oBrowseTotais:SetDataQuery(.T.)
	oBrowseTotais:SetQuery( MakeQuery() )
	oBrowseTotais:SetAlias( cAlias := GetNextAlias() )
	oBrowseTotais:DisableConfig()
	oBrowseTotais:DisableReport()
	//seta as colunas
	oBrowseTotais:SetColumns({;
		addColumn({|| (cAlias)->ORIGEM   },"Origem",20,,"C") ,;
		addColumn({|| (cAlias)->CHAVE    },"Chave",50,0,"C") ,;
		addColumn({|| (cAlias)->INC_DATA },"Inc. Data",8,0,"D") ,;
		addColumn({|| (cAlias)->INC_HORA },"Inc. Hora",8,0,"C") ,;
		addColumn({|| (cAlias)->PROC_DATA },"Proc. Data",8,0,"D") ,;
		addColumn({|| (cAlias)->PROC_HORA },"Proc. Hora",8,0,"C") ,;
		addColumn({|| (cAlias)->ERRO },"Erro",100,0,"C") })

	oModal:Activate()

return


static function MakeQuery(lAtivos)

	Local cQuery := ''

	default lAtivos := .F.

	cQuery += ' SELECT  ORIGEM '
    cQuery += '   , CHAVE, '
	cQuery += ' INC_DATA, '
	cQuery += ' INC_HORA, '
	cQuery += ' PROC_DATA, '
	cQuery += ' PROC_HORA, '
    cQuery += '   ERRO '
    cQuery += ' FROM TOTVS_CYBERLOG_ERROS_VIEW '

    IF lAtivos
    	cQuery += 'where PROCESSAMENTO is not null'
    EndIF

return cQuery


/*/{Protheus.doc} addColumn
Função generica para adicionar objeto de coluna

@author Rafael Ricardo Vieceli
@since 04/01/2017
@version undefined
@param bData, block, Codeblock da coluna
@param cTitulo, characters, Titulo da coluna
@param nTamanho, numeric, Tamanho da coluna
@param cTipo, characters, Tipo de coluna
@type function
/*/
Static Function addColumn(bData,cTitulo,nTamanho,nDecimal,cTipo,cPicture)

	Local oColumn

	oColumn := FWBrwColumn():New()
	oColumn:SetData( bData )
	oColumn:SetTitle(cTitulo)
	oColumn:SetSize(nTamanho)
	IF nDecimal != Nil
		oColumn:SetDecimal(nDecimal)
	EndIF
	oColumn:SetType(cTipo)
	IF cPicture != Nil
		oColumn:SetPicture(cPicture)
	EndIF

Return oColumn