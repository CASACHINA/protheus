
// ####################################################################################################################################################################################################
//
// Projeto   :   
// Modulo    : Faturamento
// Fonte     : uJOBRWMS
// Data      : 11/10/2020
// Autor     : Valberg Moura 
// Descricao : Rotina para ajustar dados de pedidos B2B com retorno do WMS
//
// ####################################################################################################################################################################################################

#include 'totvs.ch'
#include 'parmtype.ch'
#include 'topconn.ch'


User Function uJOBRWMS()
    local _TrQRY := GetNextAlias()

    // Abre o Ambiente
    RPCSetType(3)
    RPCSetEnv('01','010104')

//Seleciona os pedidos B2B sem retorno

    _cQry := " SELECT C5_NUM FROM "+RetSqlName("SC5")
    _cQry += " WHERE C5_FILIAL ='010104'"
    _cQry += " AND C5_B2B = 'S'"
    _cQry += " AND C5_YLIBWMS <> 'S'"
    _cQry += " AND D_E_L_E_T_ =''"
    _cQry += " ORDER  BY C5_NUM"

    //Executa Query enviada no parametro
    ChangeQuery(_cQry)
    iif( SELECT(_TrQRY) > 0 ,(_TrQRY)->(DbCloseArea()),)
    TcQuery _cQry New Alias (_TrQRY)

    While (_TrQRY)->(!Eof())

        //Seleciona o registro na integração WMS

        _cQry := " SELECT Isnull(VOLUMES,0) as VOLUMES , Isnull(PESO,0) as PESO"
        _cQry += " FROM TOTVS_CYBERLOG_SAIDA"
        _cQry += " WHERE COD_CYBERLOG_SAIDA = '010104"+(_TrQRY)->C5_NUM+"'"

        //Executa Query enviada no parametro
        ChangeQuery(_cQry)
        iif( SELECT("TRWMS") > 0 ,TRWMS->(DbCloseArea()),)
        TcQuery _cQry New Alias "TRWMS"

        If TRWMS->VOLUMES>0 .or. TRWMS->PESO>0
            DbSelectArea("SC5")
            DbSetORder(1)
            If DbSeek("010104"+(_TrQRY)->C5_NUM)
                Reclock("SC5", .F.)
                SC5->C5_YRETWMS := dDataBase
                SC5->C5_YLIBWMS := "S"
                SC5->C5_VOLUME1 := TRWMS->VOLUMES
                SC5->C5_PESOL   := TRWMS->PESO
                SC5->C5_PBRUTO  := TRWMS->PESO
                SC5->C5_ESPECI1 := "VOLUMES"
                SC5->(MsUnlock())

            Endif
        Endif

        TRWMS->(DbCloseArea())

        (_TrQRY)->(DbSkip())
    Enddo
Return
