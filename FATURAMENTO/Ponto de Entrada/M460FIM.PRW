#include "totvs.ch"

/*/{Protheus.doc} M460FIM
Ponto de Entrada após a geração da Nota Fiscal
@type function
@version 12.1.25
@author Valberg Moura
@since 01/07/2020
/*/
User Function M460FIM()
    If SC5->C5_B2B == "S"
        cOrigem := 'NOTAFISCAL'
        cChave  := SC5->C5_NUM
        cOpcao  := "A"
        cFilInt := cFilAnt

        U_CChtoCyberLog(cOrigem, cChave, cOpcao, cFilInt)

        // Alterando financeiro caso seja cartao
        if !empty(SC5->C5_YADMFIN)
            nTaxa = SC5->C5_YTAXADM // Retorna taxa do cartao

            DBSelectArea("SAE") // Adm Financeira
            SAE->(dbSetOrder(1))
            IF SAE->(msSeek(xFilial("SAE") + SC5->C5_YADMFIN)) 

                dbSelectArea("SE1")
                SE1->(dbSetOrder(1))
                if SE1->(msSeek(xFilial("SE1") + SF2->F2_SERIE + SF2->F2_DOC))
                    while !SE1->(EoF()) .and. SE1->E1_FILIAL + SE1->E1_PREFIXO + SE1->E1_NUM == xFilial("SE1") + SF2->F2_SERIE + SF2->F2_DOC
                        nVlrAtu := SE1->E1_VALOR - (SE1->E1_VALOR * nTaxa / 100)
                        nVlrOri := SE1->E1_VALOR

                        recLock("SE1", .F.)
                        
                        IF SAE->AE_YCLIFIN == 'S'
                            SE1->E1_CLIENTE := SAE->AE_CODCLI
                            SE1->E1_LOJA    := SAE->AE_LOJCLI
                            SE1->E1_NOMCLI  := SAE->AE_DESC
                        ENDIF
                        IF nTaxa > 0
                            SE1->E1_VLRREAL := nVlrOri
                            SE1->E1_VALOR   := nVlrAtu 
                            SE1->E1_SALDO   := nVlrAtu
                            SE1->E1_VLCRUZ  := nVlrAtu
                        ENDIF
                            
                            SE1->E1_NATUREZ := if(!empty(SAE->AE_YNATURE),SAE->AE_YNATURE,SE1->E1_NATUREZ)
                        SE1->(msUnlock())

                        SE1->(dbSkip())
                    endDo
                endif
            ENDIF
        endif
    Endif
Return nil

/* UPDATE MANUAL
BEGIN TRANSACTION
UPDATE SE1010 
   SET E1_VLRREAL = E1_VALOR, 
       E1_VALOR = E1_VALOR - (E1_VALOR * 2.5 / 100), 
	   E1_CLIENTE = '001', 
	   E1_LOJA = '01', 
	   E1_NOMCLI = 'GETNET VISA'
 WHERE E1_NUM = '000136196' 
   AND E1_PREFIXO = '1'
   AND D_E_L_E_T_ = ''
--COMMIT
*/
