#include 'protheus.ch'



/*/{Protheus.doc} MT180Grv
Envia pro WMS como alteração, em qualquer manutenção do complemento

@author Rafael Ricardo Vieceli
@since 07/03/2017
@version undefined

@type function
/*/
user function MT180Grv()

	Local nOpcao := ParamIXB[1]

	IF u_CChWMSAtivo() .And. SB1->B1_CYBERW == 'S'
		//cria o log, qualquer manutenção pela rotina de complemento é alteração do produto
		u_CChtoCyberLog('PRODUTO', SB5->B5_COD, 'A')
	EndIF

return