User Function MT103CWH()
Local lRetorno:= .T.
    // If
    //     Regra existente
    //     [...]
    // EndIf

    If lRetorno
        // Ponto de chamada Conex�oNF-e
        lRetorno := U_GTPE006()
    EndIf

Return lRetorno
