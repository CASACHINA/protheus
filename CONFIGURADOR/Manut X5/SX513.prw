/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Funcao    ³ SX5L2TpTar     ³ Autor ³ Sidnei Vides      ³ Data ³  09/05/05  ±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descricao ³ Tela de manutencao da tabela 63 do SX5 de Tipos de tarefa     ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
User Function SX513()
cCadastro := "Tabela Grupo Tributário"
aAutoCab    := {}
aAutoItens  := {}
PRIVATE aRotina := { { "" ,  "AxPesqui"  , 0 , 1},;  // "Pesquisar"
       				  { "",   "C160Visual", 0 , 2},;  // "Visualizar"
					  { "",   "C160Inclui", 0 , 3},;  // "Incluir"
					  { "",   "C160Altera", 0 , 4},;  // "Alterar"
					  { "",   "C160Deleta", 0 , 5} }  // "Excluir"
DbSelectArea("SX5")           
DbSetOrder(1)
If !DbSeek(xFilial("SX5")+"13",.F.)
   MsgAlert(xFilial("SX5"))
   MsgAlert("Nao foi possivel localizar a tabela 13 no cadastro de tabelas (SX5) !")
Else   
   c160altera("SX5",,3)
Endif   
return  