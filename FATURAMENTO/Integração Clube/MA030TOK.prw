/*/{Protheus.doc} MA030TOK
PE Tudo OK cadastro de cliente
@author Paulo Cesar Camata
@since 15/08/2019
@version 12.1.17
@type function
/*/
user function MA030TOK()

    if M->A1_YCLUBE == "S" // Cliente do clube china - Validar campos obrigatorios para o MercaFacil
        if empty(M->A1_NREDUZ)
            HELP(,, "Apelido n�o informado",, "Apelido do cliente n�o foi informado",1,0,,,,,, {"Informe o campo Apelido (Obrigat�rio quando cliente CLUBE)."})
            return .F.
        endif

        if empty(M->A1_PAIS)
            HELP(,, "Pa�s n�o informado",, "Pa�s do cliente n�o foi informado",1,0,,,,,, {"Informe o campo Pa�s (Obrigat�rio quando cliente CLUBE)."})
            return .F.
        endif

        if empty(M->A1_END)
            HELP(,, "Endere�o n�o informado",, "Endere�o do cliente n�o foi informado",1,0,,,,,, {"Informe o campo Endere�o (Obrigat�rio quando cliente CLUBE)."})
            return .F.
        endif

        if empty(M->A1_BAIRRO)
            HELP(,, "Bairro n�o informado",, "Bairro do cliente n�o foi informado",1,0,,,,,,{ "Informe o campo Bairro (Obrigat�rio quando cliente CLUBE)."})
            return .F.
        endif

        if empty(M->A1_CEP)
            HELP(,, "CEP n�o informado",, "CEP do cliente n�o foi informado",1,0,,,,,, {"Informe o campo CEP (Obrigat�rio quando cliente CLUBE)."})
            return .F.
        endif

        if empty(M->A1_EST)
            HELP(,, "Estado n�o informado",, "Estado do cliente n�o foi informado",1,0,,,,,, {"Informe o campo Estado (Obrigat�rio quando cliente CLUBE)."})
            return .F.
        endif

        if empty(M->A1_MUN)
            HELP(,, "Munic�pio n�o informado",, "Munic�pio do cliente n�o foi informado",1,0,,,,,, {"Informe o campo Munic�pio (Obrigat�rio quando cliente CLUBE)."})
            return .F.
        endif

        if empty(M->A1_EMAIL)
            HELP(,, "E-mail n�o informado",, "E-mail do cliente n�o foi informado",1,0,,,,,, {"Informe o campo E-mail (Obrigat�rio quando cliente CLUBE)."})
            return .F.
        endif

        if empty(M->A1_TEL)
            HELP(,, "Telefone n�o informado",, "Telefone do cliente n�o foi informado",1,0,,,,,, {"Informe o campo Telefone (Obrigat�rio quando cliente CLUBE)."})
            return .F.
        endif

        if empty(M->A1_COD_MUN)
            HELP(,, "C�digo IBGE n�o informado",, "C�digo IBGE do cliente n�o foi informado",1,0,,,,,, {"Informe o campo C�digo IBGE (Obrigat�rio quando cliente CLUBE)."})
            return .F.
        endif

        if empty(M->A1_DTNASC)
            HELP(,, "Data de nascimento n�o informado",, "Data de nascimento do cliente n�o foi informado",1,0,,,,,, {"Informe o campo Data de nascimento (Obrigat�rio quando cliente CLUBE)."})
            return .F.
        endif

        if empty(M->A1_YSEXO)
            HELP(,, "Sexo n�o informado",, "Sexo do cliente n�o foi informado",1,0,,,,,, {"Informe o campo Sexo (Obrigat�rio quando cliente CLUBE)."})
            return .F.
        endif
    endif

return .T.