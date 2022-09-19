#INCLUDE "TOTVS.CH"
#INCLUDE "TOPCONN.CH"
#INCLUDE "RWMAKE.CH"

/*/{Protheus.doc} CFACOM65

Rotina para atualizacao campos de Nota Fiscal 

@author Eduardo Vieira
@since 11/04/2022
@see X3_VLDUSER F1_DOC
/*/
User Function RT008()

        M->F1_DOC    := StrZero(Val(CNFISCAL),09)
        CNFISCAL     :=StrZero(Val(CNFISCAL),09)

Return .T.