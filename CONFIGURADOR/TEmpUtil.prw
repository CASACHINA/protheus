#INCLUDE "TOTVS.CH"

/*/{Protheus.doc} MT140ROT
PE para incluir opcao no menu
@type function
@version 12.1.25
@author Wlysses Cerqueira (WlyTech)
@since 19/08/2020
/*/

Class TEmpUtil

	Data lFilial
	Data cCgc
	Data cCodFilial
	Data lCliente
	Data cCodCliente
	Data cLojCliente
	Data cNomeCliente
	Data cEstCliente
	Data lFornecedor
	Data cCodFornecedor
	Data cLojFornecedor
	Data cNomeFornecedor
	Data cEstFornecedor


	Method New() //Construtor
	Method Load()

	Method SeekFil(cCgc)
	Method SeekFor(cEmp)
	Method ForCod(cCod,cLoja)
	Method CliCod(cCod,cLoja)
	Method SeekEmpFil(cCodFil)

EndClass

Method New() Class TEmpUtil

Return Self

Method Load() Class TEmpUtil

	::lFilial				:=	.F.
	::cCgc					:=	""
	::cCodFilial			:=	""
	::lCliente				:=	.F.
	::cCodCliente			:=	""
	::cLojCliente			:=	""
	::cNomeCliente   		:=	""
	::cEstCliente			:=	""
	::lFornecedor			:=	.F.
	::cCodFornecedor		:=	""
	::cLojFornecedor		:=	""
	::cNomeFornecedor		:=	""
	::cEstFornecedor		:=	""

Return()

Method SeekFil(cCgc) Class TEmpUtil

	Local cChave :=	xFilial("SA2") + cCgc
	Local aAreaM0 := SM0->(GetArea())
	Local aAreaA2 := SA2->(GetArea())
	Local aAreaA1 := SA1->(GetArea())

	::Load()

	::cCgc := cCgc

	DbSelectArea("SM0")
	SM0->(DbSetOrder(1))
	SM0->(DbSeek(cEmpAnt))

	While (SM0->(!EOF()) .And. (SM0->M0_CODIGO == cEmpAnt))

		If(SM0->M0_CGC == ::cCgc)
			::cCodFilial := SM0->M0_CODFIL
			::lFilial := .T.
			Exit
		EndIf

		SM0->(DbSkip())

	EndDo

	If (!(::lFilial))
		Return()
	EndIF

	DbSelectArea("SA2")
	SA2->(DbSetOrder(3)) // A2_FILIAL, A2_CGC, R_E_C_N_O_, D_E_L_E_T_

	If SA2->(DbSeek(cChave))
		::lFornecedor		:=	.T.
		::cCodFornecedor	:=	SA2->A2_COD
		::cLojFornecedor	:=	SA2->A2_LOJA
		::cNomeFornecedor	:=	SA2->A2_NOME
		::cEstFornecedor	:=	SA2->A2_EST
	EndIf

	DbSelectArea("SA1")
	SA1->(DbSetOrder(3)) // A1_FILIAL, A1_CGC, R_E_C_N_O_, D_E_L_E_T_

	If SA1->(DbSeek(cChave))
		::lCliente			:=	.T.
		::cCodCliente		:=	SA1->A1_COD
		::cLojCliente		:=	SA1->A1_LOJA
		::cNomeCliente 		:=	SA1->A1_NOME
		::cEstCliente		:=	SA1->A1_EST
	EndIf

	RestArea(aAreaA1)
	RestArea(aAreaA2)
	RestArea(aAreaM0)

Return()

Method SeekEmpFil(cCodFil) Class TEmpUtil

	Local cChave  := ""
	Local aAreaM0 := SM0->(GetArea())
	Local aAreaA2 := SA2->(GetArea())
	Local aAreaA1 := SA1->(GetArea())

	::Load()

	DbSelectArea("SM0")
	SM0->(DbSetOrder(1))
	SM0->(DbGoTop())

	While SM0->(!EOF())

		If AllTrim(SM0->M0_CODFIL) == cCodFil

			cChave := SM0->M0_CGC

			::cCodFilial := SM0->M0_CODFIL

			::lFilial := .T.

			Exit

		EndIf

		SM0->(DbSkip())

	EndDo

	If ::lFilial

		DbSelectArea("SA2")
		SA2->(DbSetOrder(3)) // A2_FILIAL, A2_CGC, R_E_C_N_O_, D_E_L_E_T_

		If SA2->(DbSeek(xFilial("SA2") + cChave))

			::lFornecedor		:=	.T.
			::cCodFornecedor	:=	SA2->A2_COD
			::cLojFornecedor	:=	SA2->A2_LOJA
			::cNomeFornecedor	:=	SA2->A2_NOME
			::cEstFornecedor	:=	SA2->A2_EST

		EndIf

		DbSelectArea("SA1")
		SA1->(DbSetOrder(3)) // A1_FILIAL, A1_CGC, R_E_C_N_O_, D_E_L_E_T_

		If SA1->(DbSeek(xFilial("SA1") + cChave))

			::lCliente			:=	.T.
			::cCodCliente		:=	SA1->A1_COD
			::cLojCliente		:=	SA1->A1_LOJA
			::cNomeCliente 		:=	SA1->A1_NOME
			::cEstCliente		:=	SA1->A1_EST

		EndIf

	EndIf

	RestArea(aAreaA1)
	RestArea(aAreaA2)
	RestArea(aAreaM0)

Return()

Method SeekFor(cEmp) Class TEmpUtil

	Local cChave := cEmpAnt + cEmp
	Local aAreaM0 := SM0->(GetArea())

	::Load()

	DbSelectArea("SM0")
	SM0->(DbSetOrder(1))

	If(SM0->(DbSeek(cChave)))
		::SeekFil(SM0->M0_CGC)
	EndIf

	RestArea(aAreaM0)

Return()

Method CliCod(cCod,cLoja) Class TEmpUtil

	Local cChave := xFilial("SA1") + cCod + cLoja
	Local aAreaA1 := SA1->(GetArea())

	::Load()

	DbSelectArea("SA1")
	SA1->(DbSetOrder(1))

	If SA1->(DbSeek(cChave))

		::SeekFil(SA1->A1_CGC)

		If (::lCliente)
			::cCodCliente		:=	SA1->A1_COD
			::cLojCliente		:=	SA1->A1_LOJA
		EndIf

	EndIf

	RestArea(aAreaA1)

Return()

Method ForCod(cCod,cLoja) Class TEmpUtil

	Local cChave := xFilial("SA2") + cCod + cLoja
	Local aAreaA2 := SA2->(GetArea())

	::Load()
	DbSelectArea("SA2")
	SA2->(DbSetOrder(1))

	If SA2->(DbSeek(cChave))

		::SeekFil(SA2->A2_CGC)

		If (::lFornecedor)
			::cCodFornecedor	:=	SA2->A2_COD
			::cLojFornecedor	:=	SA2->A2_LOJA
		EndIf

	EndIf

	RestArea(aAreaA2)

Return()
