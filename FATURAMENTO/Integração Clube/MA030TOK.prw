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
            HELP(,, "Apelido não informado",, "Apelido do cliente não foi informado",1,0,,,,,, {"Informe o campo Apelido (Obrigatório quando cliente CLUBE)."})
            return .F.
        endif

        if empty(M->A1_PAIS)
            HELP(,, "País não informado",, "País do cliente não foi informado",1,0,,,,,, {"Informe o campo País (Obrigatório quando cliente CLUBE)."})
            return .F.
        endif

        if empty(M->A1_END)
            HELP(,, "Endereço não informado",, "Endereço do cliente não foi informado",1,0,,,,,, {"Informe o campo Endereço (Obrigatório quando cliente CLUBE)."})
            return .F.
        endif

        if empty(M->A1_BAIRRO)
            HELP(,, "Bairro não informado",, "Bairro do cliente não foi informado",1,0,,,,,,{ "Informe o campo Bairro (Obrigatório quando cliente CLUBE)."})
            return .F.
        endif

        if empty(M->A1_CEP)
            HELP(,, "CEP não informado",, "CEP do cliente não foi informado",1,0,,,,,, {"Informe o campo CEP (Obrigatório quando cliente CLUBE)."})
            return .F.
        endif

        if empty(M->A1_EST)
            HELP(,, "Estado não informado",, "Estado do cliente não foi informado",1,0,,,,,, {"Informe o campo Estado (Obrigatório quando cliente CLUBE)."})
            return .F.
        endif

        if empty(M->A1_MUN)
            HELP(,, "Município não informado",, "Município do cliente não foi informado",1,0,,,,,, {"Informe o campo Município (Obrigatório quando cliente CLUBE)."})
            return .F.
        endif

        if empty(M->A1_EMAIL)
            HELP(,, "E-mail não informado",, "E-mail do cliente não foi informado",1,0,,,,,, {"Informe o campo E-mail (Obrigatório quando cliente CLUBE)."})
            return .F.
        endif

        if empty(M->A1_TEL)
            HELP(,, "Telefone não informado",, "Telefone do cliente não foi informado",1,0,,,,,, {"Informe o campo Telefone (Obrigatório quando cliente CLUBE)."})
            return .F.
        endif

        if empty(M->A1_COD_MUN)
            HELP(,, "Código IBGE não informado",, "Código IBGE do cliente não foi informado",1,0,,,,,, {"Informe o campo Código IBGE (Obrigatório quando cliente CLUBE)."})
            return .F.
        endif

        if empty(M->A1_DTNASC)
            HELP(,, "Data de nascimento não informado",, "Data de nascimento do cliente não foi informado",1,0,,,,,, {"Informe o campo Data de nascimento (Obrigatório quando cliente CLUBE)."})
            return .F.
        endif

        if empty(M->A1_YSEXO)
            HELP(,, "Sexo não informado",, "Sexo do cliente não foi informado",1,0,,,,,, {"Informe o campo Sexo (Obrigatório quando cliente CLUBE)."})
            return .F.
        endif
    endif

return .T.