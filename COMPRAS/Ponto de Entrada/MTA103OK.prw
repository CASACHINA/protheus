// ####################################################################################################################################################################################################
//
// Projeto   :   
// Modulo    : Compras
// Fonte     : uCCUST01
// Data      : 14/08/19
// Autor     : Valberg Moura 
// Descricao : Ponto de entrada para validação no momento da confirmacao do documento 
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

                _cMsg := "ATEN��O" + CHR(13)+CHR(10)
                _cMsg += "" + CHR(13)+CHR(10)
                _cMsg += "Classifica��o CFOP 1102/2102"+ CHR(13)+CHR(10)
                _cMsg += "" + CHR(13)+CHR(10)
                _cMsg += "com destaque de ICMS ST Solid�rio"+ CHR(13)+CHR(10)
                _cMsg += "" + CHR(13)+CHR(10)
                _cMsg += "FAVOR CONFERIR O LAN�AMENTO"+ CHR(13)+CHR(10)

                Alert(_cMsg)


            Endif


        Endif
    Next


    RestArea(_aArea)

Return(_lRet)