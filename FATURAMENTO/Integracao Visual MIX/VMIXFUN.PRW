
User Function eNewSeq()

    Local cReturn
    Local nSequencia := 100
    Local nTamanho   := 2
    Local nX

    For nX := 1 To 10

        cReturn := U_NewSeq(nSequencia, nTamanho)

        //conout(cReturn)

        nSequencia++

    Next

Return Nil

User Function NewSeq(cSequencia, nTamanho)

    Local cReturn
    Local nSalto, nX
    Local nSequencia := Val(cSequencia)
    
    cReturn := StrZero(nSequencia, nTamanho)

    If nSequencia > Val(PadL("", nTamanho, "9"))

        cReturn := PadL("", nTamanho, "9")

        nSalto  := nSequencia - Val(cReturn)

        For nX := 1 To nSalto

            cReturn := Soma1(cReturn, nTamanho)

        Next

    EndIf

Return cReturn
