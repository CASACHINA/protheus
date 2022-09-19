// ####################################################################################################################################################################################################
//
// Projeto   :   
// Modulo    : Compras
// Fonte     : uCCUST01
// Data      : 14/08/19
// Autor     : Valberg Moura 
// Descricao : Ponto de entrada para validaÃ§Ã£o no momento da confirmacao do documento 
//
// ####################################################################################################################################################################################################


#INCLUDE "PROTHEUS.CH"


User Function MTA103OK()
    Local _aArea     := GetArea()
    Local _lRet := .T.

    For nI := 1 To Len(aCols)
        _cCF := Alltrim( GdFieldGet("D1_CF",nI) )
        IF _cCF $ "1102,2102"

            IF GdFieldGet("D1_ICMSRET",nI) > 0

                _lRet := .F.

                _cMsg := "ATENÇÃO" + CHR(13)+CHR(10)
                _cMsg += "" + CHR(13)+CHR(10)
                _cMsg += "Classificação CFOP 1102/2102"+ CHR(13)+CHR(10)
                _cMsg += "" + CHR(13)+CHR(10)
                _cMsg += "com destaque de ICMS ST Solidário"+ CHR(13)+CHR(10)
                _cMsg += "" + CHR(13)+CHR(10)
                _cMsg += "FAVOR CONFERIR O LANÇAMENTO"+ CHR(13)+CHR(10)

                Alert(_cMsg)


            Endif


        Endif
    Next


    RestArea(_aArea)

Return(_lRet)