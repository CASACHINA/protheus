#include 'protheus.ch'
#include 'common.ch'


user function CChWMSAtivo()
return SuperGetMV("CC_CYBERW",,.F.)



user function CChtoCyberLog(cOrigem, cChave, cOpcao, cFilInt, cB2B)

	Local lSuccess := TRUE
	Local cScript  := ''

	DEFAULT cB2B := "F"

	/*
	create table TOTVS_CYBERLOG (
		ORIGEM varchar(25) NOT NULL,
		FILIAL varchar(06),
		CHAVE varchar(50) NOT NULL,
		OPERACAO varchar(1) NOT NULL,
		INCLUSAO datetime NOT NULL default GetDate(),
		PROCESSAMENTO datetime
	)
	*/
	
	If ValType(cFilInt) == "U"
		cFilInt := Space(TamSx3("C5_FILIAL")[01])
	EndIf

	cScript := 'INSERT INTO TOTVS_CYBERLOG '
	cScript += ' (ORIGEM, FILIAL, CHAVE, OPERACAO, B2B) '
	cScript += ' VALUES '
	cScript += " ('" +cOrigem+ "','" +cFilInt+ "','" +cChave+ "','" +cOpcao+ "','" +cB2B+  "') "

	IF ! ( lSuccess := ! TCSQLExec(cScript) < 0)
		//conout(TCSQLError())
	EndIF

return lSuccess



user function CChWMSError(cOrigem, cChave, cErro)

	Local lSuccess := TRUE
	Local cScript  := ''

	/*
	create table TOTVS_CYBERLOG_ERROS (
		ORIGEM varchar(25) NOT NULL,
		CHAVE varchar(50) NOT NULL,
		INCLUSAO datetime NOT NULL default GetDate(),
		PROCESSAMENTO datetime,
		ERRO varchar(2000)
	)
	*/

	cScript := 'INSERT INTO TOTVS_CYBERLOG_ERROS '
	cScript += ' (ORIGEM, CHAVE, ERRO) '
	cScript += ' VALUES '
	cScript += " ('" +cOrigem+ "','" +cChave+ "', '"+ ajusta(cErro) +"') "

	IF TCSQLExec(cScript) < 0
		//conout(TCSQLError())
	EndIF

return lSuccess



user function CCnRecebimento(cChave)

	Local lSuccess := TRUE
	Local cScript  := ''

	/*
	create table TOTVS_CYBERLOG_RECEBIMENTO (
		COD_CYBERLOG_RECEBIMENTO varchar(50) NOT NULL,
		CODIGO_PRODUTO varchar(15) NOT NULL,
		QUANTIDADE decimal(14,4) NOT NULL,
		LOTE varchar(10),
		VALIDADE date,
		FABRICACAO date,
		INCLUSAO datetime NOT NULL default GetDate(),
		PROCESSAMENTO datetime
	)
	*/

	cScript := 'UPDATE TOTVS_CYBERLOG_RECEBIMENTO '
	cScript += ' set PROCESSAMENTO = GetDate() '
	cScript += " where COD_CYBERLOG_RECEBIMENTO = '" +cChave+ "' and PROCESSAMENTO is null "

	IF TCSQLExec(cScript) < 0
		//conout(TCSQLError())
	EndIF

return



user function CCnSaida(cChave)

	Local lSuccess := TRUE
	Local cScript  := ''

	/*
	create table TOTVS_CYBERLOG_SAIDA (
		COD_CYBERLOG_SAIDA varchar(50) NOT NULL,
		CODIGO_PRODUTO varchar(15) NOT NULL,
		QUANTIDADE decimal(14,4) NOT NULL,
		LOTE varchar(10),
		VALIDADE date,
		FABRICACAO date,
		INCLUSAO datetime NOT NULL default GetDate(),
		PROCESSAMENTO datetime
	)
	*/

	cScript := ' UPDATE TOTVS_CYBERLOG_SAIDA '
	cScript += ' set PROCESSAMENTO = GetDate() '
	cScript += " where COD_CYBERLOG_SAIDA = '" +cChave+ "' and PROCESSAMENTO is null "

	IF TCSQLExec(cScript) < 0
		//conout(TCSQLError())
	EndIF

return



user function CCnInventario(dData, cProduto)

	Local lSuccess := TRUE
	Local cScript  := ''

	/*
	create table TOTVS_CYBERLOG_INVENTARIO (
		DATA_INVENTARIO date NOT NULL,
		CODIGO_PRODUTO varchar(15) NOT NULL,
		LOCAL_ESTOQUE varchar(2) NOT NULL,
		QUANTIDADE decimal(14,4) NOT NULL,
		LOTE varchar(10),
		VALIDADE date,
		FABRICACAO date,
		INCLUSAO datetime NOT NULL default GetDate(),
		PROCESSAMENTO datetime
	)
	*/

	cScript := ' UPDATE TOTVS_CYBERLOG_INVENTARIO '
	cScript += ' set PROCESSAMENTO = GetDate() '
	cScript += " where DATA_INVENTARIO = cast('" +DtoS(dData)+ "' as date) and CODIGO_PRODUTO = '"+cProduto+"' and PROCESSAMENTO is null "

	IF TCSQLExec(cScript) < 0
		//conout(TCSQLError())
	EndIF

return



user function CCnTransferencia(cChave)

	Local lSuccess := TRUE
	Local cScript  := ''

	/*
	create table TOTVS_CYBERLOG_TRANSFERENCIA (
		COD_CYBERLOG_TRANSFERENCIA varchar(50) NOT NULL,
		CODIGO_PRODUTO varchar(15) NOT NULL,
		QUANTIDADE decimal(14,4) NOT NULL,
		LOTE varchar(10),
		VALIDADE date,
		FABRICACAO date,
		INCLUSAO datetime NOT NULL default GetDate(),
		PROCESSAMENTO datetime
	)
	*/

	cScript := 'UPDATE TOTVS_CYBERLOG_TRANSFERENCIA '
	cScript += ' set PROCESSAMENTO = GetDate() '
	cScript += " where COD_CYBERLOG_TRANSFERENCIA = '" +cChave+ "' and PROCESSAMENTO is null "

	IF TCSQLExec(cScript) < 0
		//conout(TCSQLError())
	EndIF

return


user function CCnCreate()
/*
	TCSQLExec('create table TOTVS_CYBERLOG               ( ORIGEM varchar(25) NOT NULL, FILIAL varchar(06), CHAVE varchar(50) NOT NULL, OPERACAO varchar(1) NOT NULL, INCLUSAO datetime NOT NULL default GetDate(),PROCESSAMENTO datetime)')
	TCSQLExec('create table TOTVS_CYBERLOG_ERROS         ( ORIGEM varchar(25) NOT NULL, CHAVE varchar(50) NOT NULL, INCLUSAO datetime NOT NULL default GetDate(), PROCESSAMENTO datetime,ERRO varchar(2000))')
	TCSQLExec('create table TOTVS_CYBERLOG_RECEBIMENTO   ( COD_CYBERLOG_RECEBIMENTO varchar(50) NOT NULL, CODIGO_PRODUTO varchar(15) NOT NULL, QUANTIDADE decimal(14,4) NOT NULL, LOTE varchar(10), VALIDADE date, FABRICACAO date, INCLUSAO datetime NOT NULL default GetDate(), PROCESSAMENTO datetime)')
	TCSQLExec('create table TOTVS_CYBERLOG_SAIDA         ( COD_CYBERLOG_SAIDA varchar(50) NOT NULL, CODIGO_PRODUTO varchar(15) NOT NULL, QUANTIDADE decimal(14,4) NOT NULL, LOTE varchar(10), VALIDADE date, FABRICACAO date, INCLUSAO datetime NOT NULL default GetDate(), PROCESSAMENTO datetime )')
	TCSQLExec('create table TOTVS_CYBERLOG_INVENTARIO    ( DATA_INVENTARIO date NOT NULL, CODIGO_PRODUTO varchar(15) NOT NULL, LOCAL_ESTOQUE varchar(2) NOT NULL, QUANTIDADE decimal(14,4) NOT NULL, LOTE varchar(10), VALIDADE date, FABRICACAO date, INCLUSAO datetime NOT NULL default GetDate(), PROCESSAMENTO datetime )')
	TCSQLExec('create table TOTVS_CYBERLOG_TRANSFERENCIA ( COD_CYBERLOG_TRANSFERENCIA varchar(50) NOT NULL, CODIGO_PRODUTO varchar(15) NOT NULL, QUANTIDADE decimal(14,4) NOT NULL, LOTE varchar(10), VALIDADE date, FABRICACAO date, INCLUSAO datetime NOT NULL default GetDate(), PROCESSAMENTO datetime)')
*/
	Alert('Feito!')

return


static function ajusta(cString)

	cString := strtran(cString,"'","'+char(39)+'")

return cString
