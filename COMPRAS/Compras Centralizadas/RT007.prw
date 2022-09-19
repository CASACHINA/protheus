#include "totvs.ch"
#include "fwmvcdef.ch"

Static cTitulo := "Bloqueio Produto x Filial"

/*/{Protheus.doc} RT007
Tela para que seja informado quais produtos serão bloqueados (Nao permitido) compra/movimentação entre filiais.
@type function
@version 12.1.25
@author Paulo Camata (Camatech)
@since 11/01/2021
/*/
user function RT007()
    local oBrowse
	local aArea := getArea()

	oBrowse := FWMBrowse():New()
	oBrowse:SetAlias("ZZ4")
	oBrowse:SetDescription(cTitulo)

	oBrowse:Activate()
	
	RestArea(aArea)
return nil

/*/{Protheus.doc} menuDef
Definicao dos menus disponiveis para a rotina
@type function
@version 12.1.25
@author Paulo Camata (Camatech)
@since 11/01/2021
/*/
static function menuDef()
    local aRotAux := FWMVCMenu("RT007")

    ADD OPTION aRotAux TITLE "Importar TXT" ACTION "U_RT007IMP" OPERATION MODEL_OPERATION_UPDATE ACCESS 0
Return aRotAux

/*/{Protheus.doc} ModelDef
Modelo de Dados
@type function
@version 12.1.25
@author Paulo Camata (Camatech)
@since 11/01/2021
/*/
static function ModelDef()
	Local oModel
	Local oStZZ4 := FWFormStruct(1, "ZZ4")
	
	oModel := MPFormModel():New("ZTR007",/*bPre*/, /*bPos*/,/*bCommit*/,/*bCancel*/) 
	
	oModel:AddFields("FORMZZ4",/*cOwner*/,oStZZ4)
	oModel:SetPrimaryKey({"ZZ4_FILIAL","ZZ4_CODPRO"})
	oModel:SetDescription("Modelo de Dados do Cadastro " + cTitulo)
	oModel:GetModel("FORMZZ4"):SetDescription("Formulário do Cadastro " + cTitulo)
return oModel

/*/{Protheus.doc} ViewDef
Modelo Visual
@type function
@version 12.1.25
@author Paulo Camata (Camatech)
@since 11/01/2021
/*/
static function ViewDef()
	Local oModel := FWLoadModel("RT007")
	Local oStZZ4 := FWFormStruct(2, "ZZ4")
	Local oView  := Nil

	oView := FWFormView():New()
	oView:SetModel(oModel)
	oView:AddField("VIEW_ZZ4", oStZZ4, "FORMZZ4")
	oView:CreateHorizontalBox("TELA", 100)
	oView:EnableTitleView("VIEW_ZZ4", "Dados Bloqueio Prod x Filial" )  
	oView:SetCloseOnOk({||.T.})
	oView:SetOwnerView("VIEW_ZZ4","TELA")
return oView

/*/{Protheus.doc} RT007IMP
Funcao para efetuar a importacao dos dados
@type function
@version 12.1.25
@author Paulo Camata (Camatech)
@since 11/01/2021
/*/
user function RT007IMP()
    local aPergs := {}
	local aRet

    msgInfo("Arquivo Txt deve possuir 2 colunas separadas por TAB (CODIGO FILIAL e CODIGO PRODUTO)")

    aAdd(aPergs, {6, "Caminho TXT: ", space(200), , , , 90, .T., "Arquivos .TXT |*.TXT", , GETF_LOCALHARD + GETF_NETWORKDRIVE})
    If ParamBox(aPergs, "Parametros ", aRet) // Usuário confirmou a tela de parametro
        if !file(mv_par01) // Arquivo nao existe
            msgStop("Arquivo não encontrado.", "ARQUIVO NAO EXISTE")
            return nil
        endIf

        if upper(right(allTrim(mv_par01), 3)) <> "TXT"
            msgStop("Extensão do arquivo informado não é TXT. Verifique.", "EXTENSAO INVALIDA")
            return nil
        endif
        
        // Funcao para efetuar a importação do arquivo
        Processa({|| fImpArq(allTrim(mv_par01))}, "Importando...") // Inicializa a regua de processamento
    endif
return nil

/*/{Protheus.doc} fImpArq
Funcao para importar o arquivo TXT (2 colunas - FILIAL | CODIGO PRODUTO)
@type function
@version 12.1.25
@author Paulo Camata (Camatech)
@since 11/01/2021
@param cCamArq, character, Caminho do arquivo a ser importado
/*/
static function fImpArq(cCamArq)
    local oFile := FWFileReader():New(cCamArq)
    local cSeparador := chr(9)
    local cLogErro := ""
    local aLines, nTotLin, nP
    local aBkpZZ4 := ZZ4->(getArea())

    oFile:Open()
    aLines := oFile:getAllLines()

    nTotLin := len(aLines) + 1
    ProcRegua(nTotLin) // Tamanho da regua de processamento

	incProc("Processando linha 1 de " + cValToChar(nTotLin))

	dbSelectArea("SB1")
	SB1->(dbSetOrder(1))

    ZZ4->(dbSetOrder(1))

	for nP := 1 to len(aLines)
        incProc("Processando linha " + cValToChar(nP) + " de " + cValToChar(nTotLin))
        aLinAux := Strtokarr2(aLines[nP], cSeparador, .T.)

        if (FWFilExist(FwCodEmp(), aLinAux[1]))
            cFilAnt := aLinAux[1] // Trocando filial

            if SB1->(msSeek(xFilial("SB1") + padR(aLinAux[2], tamSx3("B1_COD")[1]), .F.))
                if ZZ4->(msSeek(cFilAnt + padR(SB1->B1_COD, tamSx3("ZZ4_CODPRO")[1])))
                    lInclui := .F.
                else
                    lInclui := .T.
                endif

                recLock("ZZ4", lInclui)
                    ZZ4->ZZ4_FILIAL := aLinAux[1]
                    ZZ4->ZZ4_CODPRO := aLinAux[2]
                    ZZ4->ZZ4_MSBLQL := "2" // desbloqueando registro caso já tenha sido importado anteriormente.
                ZZ4->(msUnlock())
            else
                cLogErro += "Linha: " + cValToChar(nP) + " - Produto " + allTrim(aLinAux[2]) + " não encontrado." + CRLF
            endif
        else
            cLogErro += "Linha: " + cValToChar(nP) + " - Filial " + allTrim(aLinAux[1]) + " não encontrado." + CRLF
        endif

    next nP

    if !empty(cLogErro)
        msgStop("Importação efetuada com erros.")
        fMostraErro(cLogErro)
    else
        msgInfo("Importação efetuada com SUCESSO sem erros.")
    endif
    restArea(aBkpZZ4)
    ZZ4->(dbGoTop())

return nil

/*/{Protheus.doc} fMostraErro
Funcao para apresetnar a mensagem de log
@type function
@version 12.1.25
@author Paulo Camata (Camatech)
@since 06/07/2020
/*/
static function fMostraErro(texto)
    Local oDlg, oFont
    local cMemo := texto

    DEFINE FONT oFont NAME "Courier New" SIZE 5,0
    DEFINE MSDIALOG oDlg TITLE "Arquivo Log" From 3,0 to 340,417 PIXEL

    @ 5, 5 GET oMemo VAR cMemo MEMO SIZE 200, 145 OF oDlg PIXEL
    oMemo:bRClicked := {|| AllwaysTrue()}
    oMemo:oFont := oFont

    DEFINE SBUTTON FROM 153,175 TYPE 1 ACTION oDlg:End() ENABLE OF oDlg PIXEL

    ACTIVATE MSDIALOG oDlg CENTER
Return cMemo

/*/{Protheus.doc} RT007VLD
Funcao para validar se o produto est� bloqueado na filial atual
@type function
@version 12.1.25
@author Paulo Camata (Camatech)
@since 13/01/2021
@param cCodProd, character, Codigo do Produto
/*/
user function RT007VLD(cCodProd)
    // Validacao se filial corrente possui permissao para movimentar/comprar produto
    dbSelectArea("ZZ4")
    ZZ4->(dbSetOrder(1))
    if (ZZ4->(msSeek(xFilial("ZZ4") + padR(cCodProd, tamSx3("ZZ4_CODPRO")[1])))) .and. ZZ4->ZZ4_MSBLQL <> "1"
        HELP(,, "Produto Bloqueado x Filial",, "O produto " + allTrim(cCodProd) + " est� bloqueado para compras nessa filial.",1,0,,,,,, {"Verifique com a �rea respons�vel porque o produto est� bloqueado para movimenta��o."})
        return .T.
    endif
return .F.