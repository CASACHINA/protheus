User Function A140EXC()

    Local oCyberLog := TCyberLogIntegracao():New()

    oCyberLog:SendDocEntrada(.F., .F., .F., .T.)

    // If
    //     Regra existente
    //     [...]
    // EndIf

    // Ponto de chamada ConexãoNF-e
    U_GTPE003()

Return .T.
