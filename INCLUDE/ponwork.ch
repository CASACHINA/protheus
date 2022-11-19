#ifdef SPANISH
	#define STR0001 "Iniciando U_PonScheduler()..."
	#define STR0002 "Preparando Ambiente de la Empresa. Espere... "
	#define STR0003 "Inicio de la Lectura/Apuntes en: "
	#define STR0004 " las "
	#define STR0005 "Empresa: "
	#define STR0006 "Filial:  "
	#define STR0007 "Final de la Lectura/Apunte en: "
	#define STR0008 "Cerrando Ambiente de la Empresa. Espere... "
	#define STR0009 "No se pudo concluir el proceso. Empresa o Filial Invalidas."
	#define STR0010 "Inicio de la Lectura en: "
	#define STR0011 "Final de la lectura en: "
	#define STR0012 "Inicio del apuntamiento en: "
	#define STR0013 "Final del apuntamiento en: "
#else
	#ifdef ENGLISH
		#define STR0001 "Initiating U_PonScheduler()..."
		#define STR0002 "Preparing Company Environment. Please, wait..."
		#define STR0003 "Start Reading/Annotation on: "
		#define STR0004 " at "
		#define STR0005 "Company: "
		#define STR0006 "Branch:  "
		#define STR0007 "End Reading/Annotation on: "
		#define STR0008 "Concluding Company Environment. Please, wait..."
		#define STR0009 "It was not possible to conclude the process. Company or Branch not valid."
		#define STR0010 "Read Start in: "
		#define STR0011 "Read End in: "
		#define STR0012 "Appointment Start in: "
		#define STR0013 "Appointment End in: "
	#else
		#define STR0001 If( cPaisLoc $ "ANG|PTG", "A Iniciar U_ponscheduler()...", "Iniciando U_PonScheduler()..." )
		#define STR0002 If( cPaisLoc $ "ANG|PTG", "A preparar ambiente da empresa, aguardar...", "Preparando Ambiente da Empresa. Aguarde... " )
		#define STR0003 If( cPaisLoc $ "ANG|PTG", "Início da leitura/registo em:", "Inicio da Leitura/Apontamento em: " )
		#define STR0004 " as "
		#define STR0005 "Empresa: "
		#define STR0006 If( cPaisLoc $ "ANG|PTG", "Filial:", "Filial:  " )
		#define STR0007 If( cPaisLoc $ "ANG|PTG", "Final da leitura/registo em:", "Final da Leitura/Apontamento em: " )
		#define STR0008 If( cPaisLoc $ "ANG|PTG", "A encerrar ambiente da empresa, aguardar...", "Encerrando Ambiente da Empresa. Aguarde... " )
		#define STR0009 If( cPaisLoc $ "ANG|PTG", "Não Foi Possível Concluir O Processo. Empresa Ou Filial Inválidas.", "Nao foi possivel concluir o processo. Empresa ou Filial Invalidas." )
		#define STR0010 "Inicio da Leitura em: "
		#define STR0011 "Final da Leitura em: "
		#define STR0012 "Inicio do Apontamento em: "
		#define STR0013 "Final do Apontamento em: "
	#endif
#endif
