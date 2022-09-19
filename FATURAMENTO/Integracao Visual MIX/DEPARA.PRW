#Include 'Protheus.ch'

/*/{Protheus.doc} DEPARA
Rotina de para genérico
/*/ 
User Function DEPARA(xValue, cOptions, nTipo)

    Local nX       := 0
    Local xReturn  := ""
    Local aOptions := {}
    
    Default nTipo  := 1

    If nTipo == 1

        aOptions := StrTokArr(cOptions, ";")

        For nX := 1 To Len(aOptions)

            If AllTrim(xValue) == &(AllTrim(StrTokArr(aOptions[nX],"=")[1]))

                xReturn := &(AllTrim(StrTokArr(aOptions[nX],"=")[2]))

            EndIf

        Next

    Else

        ZV5->(DbSetOrder(1))    
        ZV5->(DbSeek(xFilial("ZV5") + AllTrim(cOptions)))

        While ZV5->(!Eof()) .And. AllTrim(ZV5->(ZV5_FILIAL + ZV5_CODIGO)) == xFilial("ZV5") + AllTrim(cOptions)

            If AllTrim(xValue) == &(AllTrim(ZV5->ZV5_VALDE))

                xReturn := &(AllTrim(ZV5->ZV5_VALPAR))

            EndIf

            ZV5->(DbSkip())

        EndDo

    EndIf

Return xReturn
