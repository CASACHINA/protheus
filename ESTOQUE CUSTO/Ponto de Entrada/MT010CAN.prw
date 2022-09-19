/*/{Protheus.doc} MT010CAN
PE chamado apos o cadastro de produto (INCLUI, ALTERA E DELETA)
@type function
@version 12.1.25
@author Paulo Camata (Camatech)
@since 20/08/2020
/*/
user function MT010CAN()
    local nOpcao := paramIxb[1]

    if ALTERA .and. SB1->B1_YB2B == "S" .and. nOpcao == 1 // Confirmou OK
        recLock("SB1", .F.)
            SB1->B1_YALTB2B := "S" // Campo que controla alteração da platafroma B2B
        SB1->(msUnlock())
    endif
return nil