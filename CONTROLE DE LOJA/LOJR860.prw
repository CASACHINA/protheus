#INCLUDE "Protheus.ch"


/*���������������������������������������������������������������������������
��� Fun��o   � LOJR860     � Autor � Vendas Clientes    � Data � 29/04/11 ���
�������������������������������������������������������������������������Ĵ��
��� Descri��o� Relatorio de Nota de Credito                               ���
�������������������������������������������������������������������������Ĵ��
���Retorno   � ExR1 - Nil                                                 ���
��������������������������������������������������������������������������ٱ�
��� Uso      � Sigaloja                                                   ���
���������������������������������������������������������������������������*/
User Function LOJR860()

Local aArea    	:= GetArea()		// Backup da Area
Local aDocDev	:= Paramixb[1]   	// Documento de Devolu��o
Local aRecSD2	:= Paramixb[2]    	// Recnos de D2
Local aDadosNCC := Paramixb[3]		// Dados de NCC
Local lContinua	:= .T.

If Len(aDocDev) == 0
	lContinua := .F.
EndIf

/*
IF lContinua
	lContinua := ! u_ReciboDev(aDocDev, aRecSD2, aDadosNCC)
EndIF
*/

If lContinua
	SetPrvt('oPrint')
	oPrint:= TMSPrinter():New("Nota de Cr�dito")
	oPrint:SetPortrait()

	oFontCN08  := TFont():New("Courier New", 08, 08, .F., .F., , , , .F., .F.)
	oFontCN08N := TFont():New("Courier New", 08, 08, .F., .T., , , , .F., .F.)
	oFontCN11N := TFont():New("Courier New", 11, 11, .F., .T., , , , .F., .F.)
	oFontCN12  := TFont():New("Courier New", 12, 12, .F., .F., , , , .F., .F.)
	oFontCN12N := TFont():New("Courier New", 12, 12, .F., .T., , , , .F., .F.)

	oFont26N := TFont():New("Tahoma", 26, 26, .F., .T., , , , .F., .F.)

	MsgRun("Gerando Visualiza��o, Aguarde...","",{|| CursorWait(), Lj850Print(oPrint,aDocDev,aRecSD2,aDadosNCC),CursorArrow()})

	oPrint:Preview()  // Visualiza antes de imprimir

	RestArea(aArea)
EndIf

Return

/*������������������������������������������������������������������������������
���Funcao    �Lj850Print� Autor �TOTVS                   � Data � 08/03/2011 ���
����������������������������������������������������������������������������Ĵ��
���Descricao �Imprime e gera a visualizacao do relatorio                     ���
����������������������������������������������������������������������������Ĵ��
���Uso       �SIGALOJA                                                       ���
������������������������������������������������������������������������������*/
Static Function Lj850Print(oPrint,aDocDev,aRecSD2,aDadosNCC)

Local nX	  := 0 		// Contador
Local nLin	  := 0		// Numero da Linha
Local cPrefixo:= ""		//Prefixo do titulo

Default oPrint   := Nil
Default aDocDev  := {}
Default aRecSD2  := {}
Default aDadosNCC:= {}

If Len(aDadosNCC) > 0
	cPrefixo := aDadosNCC[1]
Else
	cPrefixo := aDocDev[1]
EndIf

SE1->( DbSetOrder( 2 ) )
If SE1->( DbSeek( xFilial("SE1") + aDocDev[3] + aDocDev[4] + cPrefixo + aDocDev[2]  ) )

	While SE1->(!Eof()) .AND. xFilial("SE1")		== SE1->E1_FILIAL 	.AND. ;
								SE1->E1_CLIENTE		== aDocDev[3] 		.AND. ;
								SE1->E1_LOJA		== aDocDev[4]		.AND. ;
								SE1->E1_PREFIXO		== cPrefixo		.AND. ;
								SE1->E1_NUM			== aDocDev[2]

	   	If !( SE1->E1_SITUACA $ "27" .OR. SE1->E1_SALDO == 0 )

     		If ( SE1->E1_TIPO $ MV_CRNEG )

				oPrint:StartPage() // Inicia uma nova p�gina

				oPrint:Box( 0100, 0100, 3000, 2300 )
				oPrint:Say( 0180, 0875, "Nota de Cr�dito", oFont26N )
				oPrint:Box( 0300, 0100, 3000, 2300 )

				/*
				//����������������������������������������������Ŀ
				//�   ESCALA PARA POSICIONAMENTO DA IMPRESSAO    �
				//�                                              �
				//�A impressao das linhas abaixo pode ser ativada�
				//�se for necessario efetuar uma manutencao neste�
				//�relatorio                                     �
				//������������������������������������������������

				//Marcacoes de Linhas
				oPrint:Say(0300, 0110, "0300", oFontCN08)
				oPrint:Say(0400, 0110, "0400", oFontCN08)
				oPrint:Say(0500, 0110, "0500", oFontCN08)
				oPrint:Say(0600, 0110, "0600", oFontCN08)
				oPrint:Say(0700, 0110, "0700", oFontCN08)
				oPrint:Say(0800, 0110, "0800", oFontCN08)
				oPrint:Say(0900, 0110, "0900", oFontCN08)
				oPrint:Say(1000, 0110, "1000", oFontCN08)
				oPrint:Say(1100, 0110, "1100", oFontCN08)
				oPrint:Say(1200, 0110, "1200", oFontCN08)
				oPrint:Say(1300, 0110, "1300", oFontCN08)
				oPrint:Say(1400, 0110, "1400", oFontCN08)
				oPrint:Say(1500, 0110, "1500", oFontCN08)
				oPrint:Say(1600, 0110, "1600", oFontCN08)
				oPrint:Say(1700, 0110, "1700", oFontCN08)
				oPrint:Say(1800, 0110, "1800", oFontCN08)
				oPrint:Say(1900, 0110, "1900", oFontCN08)
				oPrint:Say(2000, 0110, "2000", oFontCN08)
				oPrint:Say(2100, 0110, "2100", oFontCN08)
				oPrint:Say(2200, 0110, "2200", oFontCN08)
				oPrint:Say(2300, 0110, "2300", oFontCN08)
				oPrint:Say(2400, 0110, "2400", oFontCN08)
				oPrint:Say(2500, 0110, "2500", oFontCN08)
				oPrint:Say(2600, 0110, "2600", oFontCN08)
				oPrint:Say(2700, 0110, "2700", oFontCN08)
				oPrint:Say(2800, 0110, "2800", oFontCN08)
				oPrint:Say(2900, 0110, "2900", oFontCN08)
				oPrint:Say(3000, 0110, "3000", oFontCN08)
				oPrint:Say(3100, 0110, "3100", oFontCN08)

				oPrint:Line	(0300, 0080, 0300, 0100)
				oPrint:Line	(0350, 0090, 0350, 0100)
				oPrint:Line	(0400, 0080, 0400, 0100)
				oPrint:Line	(0450, 0090, 0450, 0100)
				oPrint:Line	(0500, 0080, 0500, 0100)
				oPrint:Line	(0550, 0090, 0550, 0100)
				oPrint:Line	(0600, 0080, 0600, 0100)
				oPrint:Line	(0650, 0090, 0650, 0100)
				oPrint:Line	(0700, 0080, 0700, 0100)
				oPrint:Line	(0750, 0090, 0750, 0100)
				oPrint:Line	(0800, 0080, 0800, 0100)
				oPrint:Line	(0850, 0090, 0850, 0100)

				oPrint:Line	(0900, 0080, 0900, 0100)
				oPrint:Line	(0950, 0090, 0950, 0100)
				oPrint:Line	(1000, 0080, 1000, 0100)
				oPrint:Line	(1050, 0090, 1050, 0100)
				oPrint:Line	(1100, 0080, 1100, 0100)
				oPrint:Line	(1150, 0090, 1150, 0100)
				oPrint:Line	(1200, 0080, 1200, 0100)
				oPrint:Line	(1250, 0090, 1250, 0100)
				oPrint:Line	(1300, 0080, 1300, 0100)
				oPrint:Line	(1350, 0090, 1350, 0100)
				oPrint:Line	(1400, 0080, 1400, 0100)
				oPrint:Line	(1450, 0090, 1450, 0100)
				oPrint:Line	(1500, 0080, 1500, 0100)
				oPrint:Line	(1550, 0090, 1550, 0100)
				oPrint:Line	(1600, 0080, 1600, 0100)
				oPrint:Line	(1650, 0090, 1650, 0100)
				oPrint:Line	(1700, 0080, 1700, 0100)
				oPrint:Line	(1750, 0090, 1750, 0100)
				oPrint:Line	(1800, 0080, 1800, 0100)
				oPrint:Line	(1850, 0090, 1850, 0100)
				oPrint:Line	(1900, 0080, 1900, 0100)
				oPrint:Line	(1950, 0090, 1950, 0100)
				oPrint:Line	(2000, 0080, 2000, 0100)
				oPrint:Line	(2050, 0090, 2050, 0100)
				oPrint:Line	(2100, 0080, 2100, 0100)
				oPrint:Line	(2150, 0090, 2150, 0100)
				oPrint:Line	(2200, 0080, 2200, 0100)
				oPrint:Line	(2250, 0090, 2250, 0100)
				oPrint:Line	(2300, 0080, 2300, 0100)
				oPrint:Line	(2350, 0090, 2350, 0100)
				oPrint:Line	(2400, 0080, 2400, 0100)
				oPrint:Line	(2450, 0090, 2450, 0100)
				oPrint:Line	(2500, 0080, 2500, 0100)
				oPrint:Line	(2550, 0090, 2550, 0100)
				oPrint:Line	(2600, 0080, 2600, 0100)
				oPrint:Line	(2650, 0090, 2650, 0100)
				oPrint:Line	(2700, 0080, 2700, 0100)
				oPrint:Line	(2750, 0090, 2750, 0100)
				oPrint:Line	(2800, 0080, 2800, 0100)
				oPrint:Line	(2850, 0090, 2850, 0100)
				oPrint:Line	(2900, 0080, 2900, 0100)
				oPrint:Line	(2950, 0090, 2950, 0100)
				oPrint:Line	(3000, 0080, 3000, 0100)
				oPrint:Line	(3050, 0090, 3050, 0100)
				oPrint:Line	(3100, 0080, 3100, 0100)
				oPrint:Line	(3150, 0090, 3150, 0100)
				oPrint:Line	(3200, 0080, 3200, 0100)

				oPrint:Line	(0280, 0100, 3200, 0100)

				//Marcacoes de Colunas
				oPrint:Say(0230, 0070, "0100", oFontCN08)
				oPrint:Say(0230, 0170, "0200", oFontCN08)
				oPrint:Say(0230, 0270, "0300", oFontCN08)
				oPrint:Say(0230, 0370, "0400", oFontCN08)
				oPrint:Say(0230, 0470, "0500", oFontCN08)
				oPrint:Say(0230, 0570, "0600", oFontCN08)
				oPrint:Say(0230, 0670, "0700", oFontCN08)
				oPrint:Say(0230, 0770, "0800", oFontCN08)
				oPrint:Say(0230, 0870, "0900", oFontCN08)
				oPrint:Say(0230, 0970, "1000", oFontCN08)
				oPrint:Say(0230, 1070, "1100", oFontCN08)
				oPrint:Say(0230, 1170, "1200", oFontCN08)
				oPrint:Say(0230, 1270, "1300", oFontCN08)
				oPrint:Say(0230, 1370, "1400", oFontCN08)
				oPrint:Say(0230, 1470, "1500", oFontCN08)
				oPrint:Say(0230, 1570, "1600", oFontCN08)
				oPrint:Say(0230, 1670, "1700", oFontCN08)
				oPrint:Say(0230, 1770, "1800", oFontCN08)
				oPrint:Say(0230, 1870, "1900", oFontCN08)
				oPrint:Say(0230, 1970, "2000", oFontCN08)
				oPrint:Say(0230, 2070, "2100", oFontCN08)
				oPrint:Say(0230, 2170, "2200", oFontCN08)
				oPrint:Say(0230, 2270, "2300", oFontCN08)

				oPrint:Line	(0280, 0100, 0300, 0100)
				oPrint:Line	(0290, 0150, 0300, 0150)
				oPrint:Line	(0280, 0200, 0300, 0200)
				oPrint:Line	(0290, 0250, 0300, 0250)
				oPrint:Line	(0280, 0300, 0300, 0300)
				oPrint:Line	(0290, 0350, 0300, 0350)
				oPrint:Line	(0280, 0400, 0300, 0400)
				oPrint:Line	(0290, 0450, 0300, 0450)
				oPrint:Line	(0280, 0500, 0300, 0500)
				oPrint:Line	(0290, 0550, 0300, 0550)
				oPrint:Line	(0280, 0600, 0300, 0600)
				oPrint:Line	(0290, 0650, 0300, 0650)
				oPrint:Line	(0280, 0700, 0300, 0700)
				oPrint:Line	(0290, 0750, 0300, 0750)
				oPrint:Line	(0280, 0800, 0300, 0800)
				oPrint:Line	(0290, 0850, 0300, 0850)
				oPrint:Line	(0280, 0900, 0300, 0900)
				oPrint:Line	(0290, 0950, 0300, 0950)
				oPrint:Line	(0280, 1000, 0300, 1000)
				oPrint:Line	(0290, 1050, 0300, 1050)
				oPrint:Line	(0280, 1100, 0300, 1100)
				oPrint:Line	(0290, 1150, 0300, 1150)
				oPrint:Line	(0280, 1200, 0300, 1200)
				oPrint:Line	(0290, 1250, 0300, 1250)
				oPrint:Line	(0280, 1300, 0300, 1300)
				oPrint:Line	(0290, 1350, 0300, 1350)
				oPrint:Line	(0280, 1400, 0300, 1400)
				oPrint:Line	(0290, 1450, 0300, 1450)
				oPrint:Line	(0280, 1500, 0300, 1500)
				oPrint:Line	(0290, 1550, 0300, 1550)
				oPrint:Line	(0280, 1600, 0300, 1600)
				oPrint:Line	(0290, 1650, 0300, 1650)
				oPrint:Line	(0280, 1700, 0300, 1700)
				oPrint:Line	(0290, 1750, 0300, 1750)
				oPrint:Line	(0280, 1800, 0300, 1800)
				oPrint:Line	(0290, 1850, 0300, 1850)
				oPrint:Line	(0280, 1900, 0300, 1900)
				oPrint:Line	(0290, 1950, 0300, 1950)
				oPrint:Line	(0280, 2000, 0300, 2000)
				oPrint:Line	(0290, 2050, 0300, 2050)
				oPrint:Line	(0280, 2100, 0300, 2100)
				oPrint:Line	(0290, 2150, 0300, 2150)
				oPrint:Line	(0280, 2200, 0300, 2200)
				oPrint:Line	(0290, 2250, 0300, 2250)
				oPrint:Line	(0280, 2300, 3200, 2300)

				oPrint:Line	(0300, 0100, 0300, 2300)
				*/

				SA1->(DbSetOrder(1))
				If SA1->(DbSeek(xFilial("SA1")+aDocDev[3]+aDocDev[4] ))
					oPrint:Say( 400, 0200, "C�digo:", oFontCN12N ) //
					oPrint:Say( 400, 0500, aDocDev[3], oFontCN12 )
					oPrint:Say( 400, 0750, "Loja:", oFontCN12N ) //
					oPrint:Say( 400, 0950, aDocDev[4], oFontCN12 )
					oPrint:Say( 400, 1350, "Nome:", oFontCN12N ) //
					oPrint:Say( 400, 1500, Alltrim(SA1->A1_NOME), oFontCN12 )
				Endif

				oPrint:Say( 480, 0200, "Data de Devolu��o:", oFontCN12N ) //
				oPrint:Say( 480, 0700, DTOC(SE1->E1_EMISSAO), oFontCN12 )
				oPrint:Say( 480, 1100, "Data de Validade da NCC:", oFontCN12N ) //
				oPrint:Say( 480, 1800, DTOC(SE1->E1_VENCREA), oFontCN12 )


				oPrint:Say( 560, 0200, "Prefixo:", oFontCN12N ) //
				oPrint:Say( 560, 0500, cPrefixo, oFontCN12 )
				oPrint:Say( 560, 0750, "N�mero:", oFontCN12N ) //
				oPrint:Say( 560, 0950, aDocDev[2], oFontCN12 )

				oPrint:Say( 560, 1400, "Saldo NCC:", oFontCN12N ) //
				oPrint:Say( 560, 1800, Transform(SE1->E1_SALDO,PesqPict("SE1","E1_SALDO")), oFontCN12 )

				oPrint:Box( 0700, 0100, 3000, 2300 )

				oPrint:Say( 800, 0200, "C�digo", oFontCN12N ) //
				oPrint:Say( 800, 0750, "Descri��o", oFontCN12N ) //

				nLin := 800

				SB1->(DbSetOrder(1))
				For nX := 1 To Len(aRecSD2)

					nLin += 80
					SD2->(DbGoTo(aRecSD2[nX][2]))
					If SB1->(DbSeek(xFilial("SB1")+SD2->D2_COD))
						oPrint:Say( nLin, 0200, SD2->D2_COD, oFontCN12 )
						oPrint:Say( nLin, 0750, Alltrim(SB1->B1_DESC), oFontCN12 )
					Endif

					If nLin > 3000
						oPrint:EndPage()   	  // Finaliza a p�gina
						oPrint:StartPage()   // Inicializa a p�gina
						oPrint:Box( 0100, 0100, 3000, 2300 )
						oPrint:Say( 0180, 0875, "Nota de Cr�dito", oFont26N ) //
						nLin := 400
					EndIf

				Next nX
				oPrint:EndPage()   // Finaliza a p�gina
     		Endif
		Endif
		SE1->(DbSkip())
	End

Endif

Return