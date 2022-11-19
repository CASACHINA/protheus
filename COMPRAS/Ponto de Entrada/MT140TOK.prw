User Function MT140TOK()
	
    Local lRetorno := .T.

	If lRetorno

		// Ponto de chamada ConexãoNF-e
		lRetorno := U_GTPE011()
	
    EndIf

Return(lRetorno)
