#include "totvs.ch"
#include "topConn.ch"
#include "fwMvcDef.ch"

/*/{Protheus.doc} IMP002
Funcao para efetuar a importação de um arquivo CSV de provisoes no financeiro
@author Paulo Cesar Camata
@since 28/12/2020
@version 12.1.25
@type function
/*/
user function IMP002()
    local aRet, aPergs := {}

    private cSeparador := chr(9)
    private aRotina    := {}
    private INCLUI, ALTERA

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
        Processa({|| fImpArq(allTrim(mv_par01))}, "Processando...") // Inicializa a regua de processamento
    endif
return nil

/*/{Protheus.doc} fImpArq
Funcao para efetuar a importacao do arquivo
@type function
@version 12.1.25
@author Paulo Camata (Camatech)
@since 30/12/2020
/*/
static function fImpArq(cCamArq)
    Local oFile := FWFileReader():New(cCamArq)
    local aArray, nP, aLines, nTotLin, aLinAux, cFilAnt, cNumtit, cNumPar
    local cTipTit, cCodNat, cCodFor, dDatEmi, dDatVen, dDatRea, nValTit, cHistor
    local cErro := ""

    private lMsErroAuto := .F.

    oFile:Open()
    aLines := oFile:getAllLines()

    nTotLin := len(aLines) - 1
    ProcRegua(nTotLin) // Tamanho da regua de processamento

    dbSelectArea("SE2")
    incProc("Processando linha 1 de " + cValToChar(nTotLin))

    for nP := 2 to len(aLines)
        incProc("Processando linha " + cValToChar(nP) + " de " + cValToChar(nTotLin))
        aLinAux := Strtokarr2(aLines[nP], cSeparador, .T.)
        
        // Filial do arquivo
        cFilAnt := left(aLinAux[1], 6)
        cNumtit := allTrim(aLinAux[2])
        cNumPar := allTrim(aLinAux[3])
        cTipTit := allTrim(aLinAux[4])
        cCodNat := allTrim(aLinAux[5])
        cCodFor := allTrim(aLinAux[6])
		cLojFor := allTrim(aLinAux[7])
        dDatEmi := CtoD(allTrim(aLinAux[08]))
        dDatVen := CtoD(allTrim(aLinAux[09]))
        // dDatRea := CtoD(allTrim(aLinAux[10]))
        nValTit := Val(StrTran(aLinAux[11], ",", "."))
        cHistor := allTrim(aLinAux[12])

        if (dDatRea < dDatVen)
            dDatRea := dDatVen
        endif
        
        // dDatEmi := STOD(Right(aLinAux[8], 4) + SubStr(aLinAux[8], 4, 2) + left(aLinAux[8], 2))
        // dDatVen := STOD(Right(aLinAux[9], 4) + SubStr(aLinAux[9], 4, 2) + left(aLinAux[9], 2))
        
        dbSelectArea("SE2")
        SE2->(dbSetOrder(1))
        if !(SE2->(msSeek(xFilial("SE2") + "PRV" + cNumTit + cNumPar + cTipTit + cCodFor)))
            aArray := { {"E2_FILIAL" , cFilAnt, nil},;
                        {"E2_PREFIXO", "PRV"  , nil},;
                        {"E2_NUM"    , cNumTit, nil},;
                        {"E2_TIPO"   , cTipTit, nil},;
                        {"E2_PARCELA", cNumPar, nil},;
                        {"E2_NATUREZ", cCodNat, nil},;
                        {"E2_FORNECE", cCodFor, nil},;
						{"E2_LOJA"   , cLojFor, nil},;
                        {"E2_HIST"   , cHistor, nil},;
                        {"E2_EMISSAO", dDatEmi, nil},;
                        {"E2_VENCTO" , dDatVen, nil},;
                        {"E2_VALOR"  , nValTit, nil}}
            
            // {"E2_VENCREA", dDatRea, nil},;

            lMsErroAuto := .F.
            MsExecAuto({|x,y,z| FINA050(x,y,z)}, aArray, , 3)
            If lMsErroAuto
                cErro += MostraErro("c:\temp\erro.log") + CRLF
            Endif
        endif
    next nP

    if !empty(cErro)
        fMostraErro(cErro)
    endif
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