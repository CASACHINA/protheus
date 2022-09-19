User Function MT140LOK()
Local lRet := .T.

    If FwIsInCallStack('U_GATI001')
        U_GTPE012()
    EndIf

    // If !FwIsInCallStack('U_GATI001') .Or. !l103Auto
    //     Regra existente
    //     [...]
    // EndIf

Return lRet
