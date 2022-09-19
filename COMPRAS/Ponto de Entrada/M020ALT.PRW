user function M020ALT()

	IF u_CChWMSAtivo() .And. SA2->A2_CYBERW == 'S'
		//cria o log
		u_CChtoCyberLog('FORNECEDORES', SA2->(A2_COD+A2_LOJA), 'A')
	EndIF

return