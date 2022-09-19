#INCLUDE "PROTHEUS.CH"
#INCLUDE "TOPCONN.CH"

User Function MT120APV()

	Local oObjMT120APV	:= TMT120APV():New()
	Local cGrupo		:= Nil

	cGrupo := oObjMT120APV:Processa()

Return(cGrupo)
