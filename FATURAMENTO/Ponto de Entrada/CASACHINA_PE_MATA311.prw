#include 'protheus.ch'
#include 'fwmvcdef.ch'

/*/{Protheus.doc} MATA311
PEs da rotina MVC de Solicitação de Transferencia
@author Rafael Ricardo Vieceli
@since 02/2017
@version undefined
@type function
/*/

Static cFilDest_ := ""

user function MATA311()

	//validar que todos os destinos sejam diferente da origem, mas igual entre si
	//Objeto do formulário ou do modelo, conforme o caso.
	Local oModel  //ParamIXB[1]
	//ID do local de execução do ponto de entrada
	Local cIdPonto //ParamIXB[2]
	//ID do formulário
	Local cIdModel //ParamIXB[3]
	Local xRetorno := .T.
	// Local aInfo := {}

	Local oObjCyberLog := Nil

	IF ! Empty(ParamIXB)

		oModel   := ParamIXB[1]
		cIdPonto := ParamIXB[2]
		cIdModel := ParamIXB[3]

		do case
		case cIdPonto == "FORMLINEPOS"

			If cIdModel == "NNTDETAIL"

				xRetorno = U_VMIX011(FWFldGet("NNT_FILDES"), FWFldGet("NNT_PRODD"))

				// Validacao produto
				IF !xRetorno

					Help('',1,'CCHINA-SOL.PROD TRANSF',,'O produto destino não é valido para a empresa destino! (linha '+cValToChar(ParamIXB[4])+').',4)

				EndIF

			EndIf

			//na validação total do formulario
		case cIdPonto == "FORMPOS"
			//validação dos itens
			IF cIdModel == 'NNTDETAIL'
				//valida alteração e efetivação
				xRetorno := vModeloDetail(oModel)
			EndIF

			//apos a gravação, dentro da transação
		case cIdPonto $ "MODELCOMMITTTS"
			
			If !IsInCallStack('A311Efetiv') .And. !IsInCallStack('U_TRFFATAUT') .And. !IsInCallStack('U_TRFFATJOB')

				oObjCyberLog := TCyberlogIntegracao():New()

				If oModel:GetValue('NNSMASTER', "NNS_CYBERW") == 'S'

					oObjCyberLog:SendTransferencia(oModel:getOperation() == MODEL_OPERATION_INSERT, .F., oModel:getOperation() == MODEL_OPERATION_UPDATE, oModel:getOperation() == MODEL_OPERATION_DELETE)

				Else

					oObjCyberLog:SetPedidoConferenciaStatus("S", .T.)

				EndIf

			EndIf

			//na efetivação
			IF IsInCallStack('A311Efetiv')
				// Chamada função por Paulo Camata - 23/04/2019
				//Adicionada atualização do B1_YESTB2B para não precisar repetir o looping - Eduardo Vieira
				u_RT004NF(oModel:GetValue('NNSMASTER', 'NNS_COD')) // atualizar NF da central de compras (Z01)

				//na inclusao/alteração
			ElseIF oModel:GetValue('NNSMASTER', "NNS_CYBERW") == 'S' .And. oModel:GetValue('NNSMASTER', "NNS_CYBERS") != "R"
				do case
				case oModel:GetOperation() == MODEL_OPERATION_INSERT
					u_CChtoCyberLog('TRANSFERENCIA', cFilAnt + oModel:GetValue('NNSMASTER', 'NNS_COD') , 'I', cFilAnt)

					Reclock("NNS",.F.)
					NNS->NNS_CYBERS := "E"
					NNS->( MsUnlock() )

				case oModel:GetOperation() == MODEL_OPERATION_UPDATE
					u_CChtoCyberLog('TRANSFERENCIA', cFilAnt + oModel:GetValue('NNSMASTER', 'NNS_COD') , 'A', cFilAnt)

					Reclock("NNS",.F.)
					NNS->NNS_CYBERS := "E"
					NNS->( MsUnlock() )

				case oModel:GetOperation() == MODEL_OPERATION_DELETE
					u_CChtoCyberLog('TRANSFERENCIA', cFilAnt + oModel:GetValue('NNSMASTER', 'NNS_COD') , 'D', cFilAnt)

					Reclock("NNS",.F.)
					NNS->NNS_CYBERS := "E"
					NNS->( MsUnlock() )

				endcase
			EndIF

		case cIdPonto == 'MODELPOS' .And. cIdModel == 'MATA311'

			IF IsInCallStack('A311Efetiv') .Or. oModel:GetOperation() == MODEL_OPERATION_UPDATE

				oObjCyberLog := TCyberlogIntegracao():New()

				xRetorno := oObjCyberLog:ValidEnvioTransferencia()

			EndIf

			IF xRetorno .And. !IsBlind() .And. ( oModel:GetOperation() == MODEL_OPERATION_INSERT .Or. oModel:GetOperation() == MODEL_OPERATION_UPDATE )
				IF TesNaoInformada(oModel:GetModel('NNTDETAIL'))
					xRetorno := .F.
					Help('',1,'CASA-SOL.TRANSF',,'A TES precisa ser informado onde o campo estiver com conteúdo "***".',4)
				EndIF
			EndIF

			// case cIdPonto == 'MODELPRE' .And. cIdModel == 'MATA311'
			// 	IF IsInCallStack('A311Altera')
			// 		oModel:GetModel('NNSMASTER'):GetStruct():SetProperty("NNS_TRANSP",MODEL_FIELD_WHEN,{||.T.})
			// 	EndIF
			
		case cIdPonto == 'MODELVLDACTIVE' .And. cIdModel == 'MATA311'

			oModel:GetModel('NNSMASTER'):SetFldNoCopy( {'NNS_STATUS', 'NNS_SOLICT', 'NNS_DATA', 'NNS_CYBERS'} )

			oModel:GetModel('NNTDETAIL'):SetFldNoCopy( {'NNT_DOC', 'NNT_SERIE', "NNT_QTDWMS"} )

			//grava quantidade original
			oModel:GetModel('NNTDETAIL'):GetStruct():AddTrigger('NNT_QUANT','NNT_QTDORI',{|model|  model:GetDataID() == 0 }, {|model| model:GetValue('NNT_QUANT') }, "")

			If oModel:GetOperation() == MODEL_OPERATION_INSERT .And. !IsBlind() //.Or. oModel:GetOperation() == MODEL_OPERATION_UPDATE

				If INCLUI

					While !PergunteFilial()
					EndDo

				Else // Significa que eh copia

					DbSelectArea("NNT")
					NNT->(DbSetOrder(1)) // NNT_FILIAL, NNT_COD, NNT_FILORI, NNT_PROD, NNT_LOCAL, NNT_LOCALI, NNT_NSERIE, NNT_LOTECT, NNT_NUMLOT, NNT_FILDES, NNT_PRODD, NNT_LOCLD, NNT_LOCDES, NNT_LOTED, R_E_C_N_O_, D_E_L_E_T_

					If NNT->(DBSeek(NNS->NNS_FILIAL + NNS->NNS_COD))

						cFilDest_ := NNT->NNT_FILDES

					EndIf

				EndIf

				If !Empty(cFilDest_)

					oModel:GetModel("NNTDETAIL"):GetStruct():SetProperty('NNT_FILDES'	, MODEL_FIELD_INIT, {|| cFilDest_ })

					oModel:GetModel("NNTDETAIL"):GetStruct():SetProperty('NNT_FILDES'	, MODEL_FIELD_WHEN, {|| .F. })

				EndIf

			EndIf

		case cIdPonto == "BUTTONBAR"

			xRetorno := {}
			aAdd( xRetorno, {'Importa TXT'       , 'IMPORTAR', { |oModel| U_MEST001(oModel) }, 'Importação de Arquivo TXT de Transferência entre filiais' } )
			aAdd( xRetorno, {'Ajustar quantidade', 'WIZARD'  , { |oModel| AjusteQuantidadeWMS(oModel) }, 'Ajuste da quantidade conforme a quantidade separada pelo WMS' ,,{MODEL_OPERATION_UPDATE}} )

		endcase

	EndIF

return xRetorno

Static Function PergunteFilial()

	Local cLoad	    := "MATA311" + cEmpAnt
	Local cFileName := RetCodUsr() +"_"+ cLoad
	Local lRet		:= .F.
	Local aPergs	:=	{}

	MV_PAR01 := "      "

	cFilDest_ := MV_PAR01

	aAdd( aPergs, { 1, "Filial", MV_PAR01, "", "NAOVAZIO()", "TAFSM0", ".T.", 50, .F. })

	If ParamBox(aPergs ,"Escolha a filial",,,,,,,,cLoad,.T.,.T.)

		lRet := .T.

		MV_PAR01 := ParamLoad(cFileName, ,1 , MV_PAR01)

		cFilDest_ := MV_PAR01

	EndIf

Return(lRet)

/*/{Protheus.doc} AjusteQuantidadeWMS
Função para validar e perguntar se deseja ajustar a quantidade conforme WMS
@author Rafael Ricardo Vieceli
@since 07/07/2017
@version undefined
@param oModel, object, descricao
@type function
/*/
static function AjusteQuantidadeWMS(oModel)
	IF oModel:GetValue('NNSMASTER', "NNS_CYBERS") == "R"
		IF Aviso('Ajuste quantidade','Deseja ajustar a quantidade conforme a quantidade separada pelo WMS e excluir itens não sepados?',{'Ajustar', 'Cancelar'},2) == 1
			FwMsgRun(, {|| Ajusta(oModel) }, "Ajustando...", "Ajustando as quantidades")
		EndIF
	Else
		Help("","","CASACHINA-WMS",,'Está solicitação de transferencia não teve retorno do WMS.', 1, 0)
	EndIF
return

/*/{Protheus.doc} Ajusta
Função para fazer o ajuste
@author Rafael Ricardo Vieceli
@since 07/07/2017
@version undefined
@param oModel, object, descricao
@type function
/*/
static function Ajusta(oModel)
	Local nLinha
	Local oModelNNT := oModel:GetModel('NNTDETAIL')

	For nLinha := 1 to oModelNNT:Length()
		oModelNNT:GoLine(nLinha)
		IF ! oModelNNT:isDeleted()
			do case
				//se a quantidade estiver zero
			case oModelNNT:GetValue('NNT_QTDWMS') == 0
				//exclui a linha
				oModelNNT:DeleteLine()

				//se a quantidade estiver divergente
			case oModelNNT:GetValue('NNT_QTDWMS') != oModelNNT:GetValue('NNT_QUANT')
				//ajusta a quantidade conforme separado pelo WMS
				oModelNNT:loadValue('NNT_QUANT', oModelNNT:GetValue('NNT_QTDWMS'))
			endcase
		EndIF
	Next nLinha
return

/*/{Protheus.doc} vModeloDetail
Validação do Modelo
@author Rafael Ricardo Vieceli
@since 02/2017
@version undefined
@param oModel, object, descricao
@type function
/*/
static function vModeloDetail(oModel)
	Local lValid := .T.
	Local nItem
	Local cFilialDestino

	//percorre todos os itens
	for nItem := 1 to oModel:Length()
		//posiciona na linha
		oModel:GoLine(nItem)

		//se a linha estiver deletada
		IF oModel:IsDeleted()
			//e existir WMS e a quantidade separada for maior que zero
			IF FWFldGet("NNS_CYBERW") == 'S' .And. FWFldGet("NNS_CYBERS") != 'N' .And. oModel:GetValue('NNT_QTDWMS') != 0
				lValid := .F.
				Help('',1,'CCHINA-SOL.TRANSF',,'Com a integração com o WMS, não pode excluir uma linha que tenha quantidade separada pelo WMS (linha '+cValToChar(nItem)+').',4)
				Exit
			EndIF
		Else
			//na primera linha, pega a filial
			IF Empty(cFilialDestino)
				cFilialDestino := oModel:GetValue('NNT_FILDES')
			EndIF
			//e compara com as demais, para não transferir para mais de uma filial na mesma solicitação
			IF cFilialDestino != oModel:GetValue('NNT_FILDES')
				lValid := .F.
				Help('',1,'CCHINA-SOL.TRANSF',,'Com a integração com o WMS, não pode transferir para mais de uma filial na mesma solicitação.',4)
				Exit
			EndIF

			//e existir WMS
			IF FWFldGet("NNS_CYBERW") == 'S' .And. FWFldGet("NNS_CYBERS") == 'R'
				//se a quantidade for diferente da quantidade separado no WMS
				//isso trata quantidade difirente e item não separado
				IF oModel:GetValue('NNT_QUANT') != oModel:GetValue('NNT_QTDWMS')
					//não permite a efetivação
					lValid := .F.
					Help('',1,'CCHINA-SOL.T.QUANT',,'Com a integração com o WMS, não pode transferir quantidade diferente da quantidade do WMS (linha '+cValToChar(nItem)+').',4)
					Exit
				EndIF
			EndIF

			lValid = U_VMIX011(FWFldGet("NNT_FILDES"), FWFldGet("NNT_PRODD"))

			// Validacao produto
			IF !lValid

				Help('',1,'CCHINA-SOL.PROD TRANSF',,'O produto destino não é valido para a empresa destino! (linha '+cValToChar(nItem)+').',4)

				Exit

			EndIF

		EndIF

	next nItem

return lValid

/*/{Protheus.doc} TesNaoInformada
Validação da TES não informada ***
@author Rafael Ricardo Vieceli
@since 30/05/2017
@version undefined
@param oModel, object, descricao
@type function
/*/
static function TesNaoInformada(oModel)
	Local nItem
	Local lInformada := .F.

	//percorre todos os itens
	for nItem := 1 to oModel:Length()
		oModel:GoLine(nItem) //posiciona na linha

		//se a linha estiver deletada
		IF ! oModel:IsDeleted()
			IF oModel:GetValue( 'NNT_TS' ) == '***' .Or. oModel:GetValue( 'NNT_TE' ) == '***'
				lInformada := .T.
			EndIF
		EndIF
	next nItem
return lInformada

User Function XGETFILD()
Return(cFilDest_)
