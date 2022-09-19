User Function MT100TOK()
Local lRetorno := .T.
    // Irá fazer as validações abaixo quando não for chamado através do Importador ConexãoNfe ou Quando for pelo ConexãoNfe e
    // esteja na tela do Documento de Entrada
    If !FwIsInCallStack('U_GATI001') .Or. (FwIsInCallStack('U_GATI001') .And. !FwIsInCallStack('U_Retorna') .And. !FwIsInCallStack('GeraConhec') .And. !l103Auto)
        // If
        //     Regra existente
        //     [...]
        // EndIf
    EndIf

    If lRetorno
        // Ponto de chamada ConexãoNF-e
        lRetorno := U_GTPE005()
    EndIf

Return lRetorno
