/*/{Protheus.doc} MA260D3
PE após inclusao na tabela SD3 na Transf. Interna - Simples (MATA260)
@type function
@version 12.1.25
@author Paulo Camata (Camatech)
@since 01/09/2020
/*/
user function MA260D3()
    local cNumSeq := SD3->D3_NUMSEQ
    local aArea   := SD3->(getArea())
    local cArmCom := getNewPar("EC_ARMCOM", "90")  // Armazem de estoque para o E-Commerce

    dbSelectArea("SB1")
    SB1->(dbSetOrder(1))
    
    SD3->(dbSetOrder(4))
    if SD3->(msSeek(xFilial("SD3") + cNumSeq))
    
        while !SD3->(EoF()) .and. allTrim(xFilial("SD3") + cNumSeq) == allTrim(SD3->D3_FILIAL + SD3->D3_NUMSEQ)

            if (SD3->D3_LOCAL == cArmCom)
                if (SB1->(msSeek(xFilial("SB1") + SD3->D3_COD)))
                    recLock("SB1", .F.)
                        SB1->B1_YESTB2B := "S"
                    SB1->(msUnlock())
                endif
            endif

            SD3->(dbSkip())
        endDo
    endif
    restArea(aArea)
return nil