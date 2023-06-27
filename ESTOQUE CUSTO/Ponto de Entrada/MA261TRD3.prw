/*/{Protheus.doc} MA261TRD3
PE após salvar registros da transferencia multipla
@type function
@version 12.1.25
@author Paulo Camata (Camatech)
@since 01/09/2020
/*/
Static _cDocSD3_ := ""

user function MA261TRD3()
    local aRecn   := paramIxb[1] // Recnos salvos
    local cArmCom := getNewPar("EC_ARMCOM", "90")  // Armazem de estoque para o E-Commerce
    local aArea   := SD3->(getArea())
    local i

    DBSelectArea("SB1")
    SB1->(dbSetOrder(1))

    DBSelectArea("SD3")

    for i := 1 to len(aRecn)
        SD3->(dbGoTo(aRecn[i, 1]))

        if (SD3->D3_LOCAL == cArmCom)
            if (SB1->(msSeek(xFilial("SB1") + SD3->D3_COD)))
                recLock("SB1", .F.)
                    SB1->B1_YESTB2B := "S"
                SB1->(msUnlock())
            endif
        endif

        SD3->(dbGoTo(aRecn[i, 2]))

        if (SD3->D3_LOCAL == cArmCom)
            if (SB1->(msSeek(xFilial("SB1") + SD3->D3_COD)))
                recLock("SB1", .F.)
                    SB1->B1_YESTB2B := "S"
                SB1->(msUnlock())
            endif
        endif
    next i

    _cDocSD3_ := cDocumento

    restArea(aArea)
return nil

User Function XMA261TR()
Return(_cDocSD3_)
