#INCLUDE "Protheus.CH"
#include 'Parmtype.Ch'
#Include 'FwMvcDef.Ch'
#INCLUDE "FILEIO.CH"
#INCLUDE "TBICONN.CH"
#INCLUDE "FWFILTER.CH"

    /* 
    ARQUIVO PARA DEMONSTRAÇÃO NO PORTFOLIO
    Dados sensiveis, acessos, nome de funcoes e variaveis originais foram alterados por questao de seguranca.
    Demonstracao apenas para analise por um especialista, nao funcional sem os dados completos.
    DEMONSTRACAO DE MULTI-THREAD E JOB AUTOMATICO VIA SCHEDULE, COM ENVIO DE EMAIL.
    */

/*=================================================================================================================
*Fonte:	 	ATUCLISA1
*Autor:  	Diogo Dorneles
*Data:   	09/05/2025
*Descrição: Atualiza o saldo pendente a pagar e o saldo atrasado a ser pago pelo cliente via Job com MultiThreadds.
*Rotina:	Schedule
==================================================================================================================*/

User Function ATUCLISA1()    
    Local cInicio   := "Inicio: "
    Local cFim      := "Fim: "
    Local W         := '' // Ocultado Nessa demonstracao!
	Local X         := '' // Ocultado Nessa demonstracao!
	Local Y         := '' // Ocultado Nessa demonstracao!
	Local Z         := '' // Ocultado Nessa demonstracao!

    RpcClearEnv()
    RpcSetType(3)
    RpcSetEnv(W,X,Y,Z) // Variaveis alteradas na demonstracao

    cInicio   += cValToChar(Time())+". "
    fCallAtu()
    cFim      += cValToChar(Time())+". "
    EnvMail("Saldo de clientes atualizado com sucesso. "+cInicio+cFim)

    RpcClearEnv()    
Return

Static Function fCallAtu() 

    Local cAliasCount   := GetNextAlias()  
    Local cAliasCli     := GetNextAlias()  
    Local cStartPath	:= "" // Ocultado Nessa demonstracao!
    Local cJobFile	    := ""
    Local cCliStart     := "      "
    Local cCliEnd       := "      "
    Local cQry          := "" 
    Local aDados        := {}
    Local aJobAux       := {}
    Local nHdl          := 0
    Local nCont         := 0
    Local nTotCli       := 0
    Local X             := 0    
    Local nRetry_0      := 0   
    Local nRetry_1      := 0   
    Local nRetry_2      := 0   

    cCliEnd := "ZZZZZZ" 

    cQry := " SELECT count(*) CONTAGEM FROM "+retsqlname("SA1")+ " (NOLOCK) WHERE D_E_L_E_T_ = '' AND A1_MSBLQL != 1 "
    cQry += " AND A1_COD BETWEEN '"+cCliStart+"' AND '"+cCliEnd+"' AND A1_COD != '000001' AND A1_COD != '900000' "
    dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQry),cAliasCount,.T.,.T.)
    nTotCli := (cAliasCount)->CONTAGEM
    (cAliasCount)->(DbCloseArea()) 

    // Busca clientes 
    cQry := " SELECT A1_COD,A1_LOJA FROM "+retsqlname("SA1")+ " (NOLOCK) WHERE D_E_L_E_T_ = '' AND A1_MSBLQL != 1 "
    cQry += " AND A1_COD != '000001' AND A1_COD != '900000' "
    dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQry),cAliasCli,.T.,.T.)     
    
    //Prepara array de cliente e loja para thread;
    While !(cAliasCli)->(EoF()) .and. nCont <= nTotCli        
        aadd(aDados, {(cAliasCli)->A1_COD, (cAliasCli)->A1_LOJA} )

        (cAliasCli)->(DbSkip())
        nCont++
    End
    (cAliasCli)->(DbCloseArea())  

    aThreads := fThreads(aDados)
    Conout("Threads Definidas "+Time())

    For X := 1 to Len(aThreads)        
        
        Conout("MENSAGEM: Iniciando Thread" + cValToChar( X ))

        // Informacoes do semaforo        
        cJobFile := cStartPath + "AttSaldoCli"+ CriaTrab(Nil,.F.)+StrZero( X , 2 )+".job"
        
        If File(cJobFile)
            fErase(cJobFile)
        EndIf

        // Criacao do arquivo de controle de threads
        // Utilizado Arquivo como controle. Variavel global nao garantiu a mesma estabilidade nos jobs.
        nHdl := FCreate(cJobFile)
        FClose(nHdl)  

        If !File(cJobFile)
            nHdl := FCreate(cJobFile)
            FClose(nHdl)
        EndIf          
                
        // status 0 = Criado com sucesso arquivo inicial para log de thread.
        nHdl := FOpen( cJobFile, FO_WRITE + FO_SHARED)                                
        If nHdl > -1
            FSeek(nHdl, 0, FS_END)
            fWrite(nHdl,"0",10)                
            FClose(nHdl)  
        Else
            Conout("Erro na gravação inicial do Log -> Log 0: "+cJobFile+". Erro: "+str(ferror(),4))
        EndIf                
        Sleep(1000)
        // Adiciona o nome do arquivo de Job no array aJobAux
        aAdd( aJobAux , { StrZero( X , 2 ) , cJobFile } )
                                                                
        // Dispara thread para Stored Procedure
        StartJob("U_JOBSA1ATU" , GetEnvServer() , .F. , cJobFile , StrZero( X , 2 ) , aThreads[X] )  

        Sleep(1000)
    Next X

    nThreads := Len(aThreads)

    //==============================================*
    // Controle de Seguranca para Multi-Thread
    //==============================================*
    cLog := ''
    nCont := 0
    
    While .T. .and. nCont <= 3000

        For X := 1 To Len(aThreads)
    
            Conout("Processando Informações | Job numero -> " + StrZero( X , 2 )+". "+Time() )
    
            nPos := aScan( aJobAux , { |Y| Y[1] == StrZero( X , 2 ) } )
                    
            // Informacoes do semaforo
            cJobFile := aJobAux[nPos][2]
    
            // Leitura do arquivo controle de thread
            nHdl := FOpen( cJobFile, FO_READ )                                
            If nHdl > -1
                FRead( nHdl,cLog, 1024 )
                cLog := Right(cLog,1)
                FClose(nHdl)
            Else
                IF !File(cJobFile) 
                    Loop
                Endif
                Conout("Erro ao tentar ler os logs do semaforo "+cValToChar(X)+": "+cJobFile+". Erro: "+str(ferror(),4))
            EndIf
            
            //==================================
            // Analise das Threads em Execucao
            //==================================
            Do Case
                // Tratamento para erro de subida da Thread
                Case cLog = '0'                         
                    If nRetry_0 > 50  
                        Conout(Replicate("-",60))
                        Conout("CP Atualiza Cliente: Não foi possivel realizar a subida da thread" + " " + StrZero( X , 3 ) )
                        Conout(Replicate("-",60))
                        cMsg := "Erro CP Atualiza Cliente: Não foi possivel realizar a subida da thread" + " " + StrZero( X , 3 );
                        +". Threads restantes: "+StrZero(nThreads, 2 )
                        EnvMail(cMsg)
                        Final("Não foi possivel realizar a subida da thread") 							
                    Else
                        nRetry_0 ++ 
                        IF File(cJobFile) .AND. nJob < Len(aThreads)      
                            nJob++                            
                            Conout("Recall | Job numero -> " + StrZero( X , 2 )+". Log 0")
                            StartJob("U_JOBSA1ATU" , GetEnvServer() , .F. , cJobFile , StrZero( X , 2 ) , aThreads[X] )
                            Sleep(1000)
                        Endif
                    EndIf   

                // Tratamento para erro de subida da Thread
                Case Empty(cLog)                        
                    If nRetry_1 > 50
                    Conout(Replicate("-",60))
                    Conout("CP Atualiza Cliente: Não foi possivel realizar a leitura(vazio) da thread" + " " + StrZero( X , 3 ) )
                    Conout(Replicate("-",60))
                    cMsg := "Erro CP Atualiza Cliente: Não foi possivel realizar a leitura(vazio) da thread" + " " + StrZero( X , 3 );
                    +". Threads restantes: "+StrZero(nThreads, 2 )
                    EnvMail(cMsg)
                    Final("Não foi possivel realizar a leitura da thread, log vazio")                                       
                    Else
                        nRetry_1 ++
                        IF File(cJobFile) .AND. nJob < Len(aThreads)
                            nJob++                            
                            Conout("Recall | Job numero -> " + StrZero( X , 2 )+". Empt")                            
                            StartJob("U_JOBSA1ATU" , GetEnvServer() , .F. , cJobFile , StrZero( X , 2 ) , aThreads[X] , aParametros )
                            Sleep(1000)
                        Endif
                    EndIf  

                // Tratamento para erro de inicializacao da Thread
                Case cLog = '2'
                    If nRetry_2 >= 3000 
                        Conout(Replicate("-",60))				
                        Conout("CP Atualiza Cliente: Erro de aplicacao na thread (Erro: Log 2. nCont >= 3000)")
                        Conout("Thread numero : "+cJobFile)					
                        Conout(Replicate("-",60))  				                        
                        cMsg := "Erro de aplicacao na Thread (Erro: Log 2. nCont >= 3000) | Thread: " + StrZero( X , 2 ) + ". Log 2.";
                        +". Threads restantes: "+StrZero(nThreads, 2 )
                        EnvMail(cMsg)
                        Final("CP Atualiza Cliente: Erro de aplicacao na thread (Verifique error.log). Log 2")	
                    Else
                        nRetry_2++
                        Sleep(5000)
                    EndIf 

                // Thread processada
                Case cLog = '3'                    
                    // Limpa arquivo de controle da thread
                    If File(cJobFile)                            
                        nHdl := FOpen( cJobFile, FO_READ )                                
                        If nHdl > -1                                
                            FClose(nHdl)
                            fErase(cJobFile)    //
                            Conout("Finalizado Thread "+StrZero(X,2)+": "+cJobFile+". Log excluido com sucesso.")
                            nRetry_2 := 1
                        Else
                            Conout("Erro ao tentar Excluir log final "+cJobFile+". Erro: "+str(ferror(),4))                             
                        EndIf                                
                    EndIf
                                                
                    // Atualiza o log de andamento do processo			                                            
                    Conout("Termino | Job numero -> " + StrZero( X , 2 ))                    
                    nThreads--
            EndCase
            
            Sleep(2500)                    
        Next X
            
        nCont++

        // Encerrar monitor de seguranca
        If nThreads <= 0
            Exit
        EndIf

    End While

    Conout("Atualização de saldo finalizada. Total de "+Alltrim(Str(nTotCli))+" cliente atualizado.","Mensagem")
Return

/*=============================================================================================
*Autor:  	Diogo Dorneles
*Data:   	09/05/2025
*Descrição: Recebe os dados e separa em array para as Threads.
=============================================================================================*/
Static Function fThreads( xTotReg )
    Local aAreaAnt   := GetArea()
    Local aThreads   := {}
    Local X          := 0
    Local nThreads   := GetMV('') // Ocultado Nessa demonstracao!  // Parametro com numero de Threads.
    Local nCont      := 0
    Local nContTotal := 1
    Local nEach      := 0

    //Maximo de Threads
    If nThreads > 40 
        nThreads := 40
    EndIf

    //Analisa a quantidade de Threads X nRegistros
    If Len(xTotReg) == 0
        nThreads := 0
    ElseIf Len(xTotReg) < nThreads // Uma thread
        nThreads := 1		
    EndIf

    nEach := Int(Len(xTotReg)/nThreads ) // Clientes por Thread
    nResto := Len(xTotReg) - (nEach * nThreads)
    If nResto > 0
        nEach := nEach + 1 
    EndIf

    For  X := 1 to nThreads 
        aAdd(aThreads, {})
        If X = nThreads .and. nResto > 0
            nEach = nEach - ( (nEach * nThreads) - Len(xTotReg) )
        Endif

        While nCont < nEach .AND. nContTotal <= Len(xTotReg)  
            aAdd(aThreads[X], {xTotReg[nContTotal][1],xTotReg[nContTotal][2]}) 

            nCont++       // Por Thread
            nContTotal++  // Registros Totais
        End
        nCont := 0                  
    Next X

    RestArea(aAreaAnt)
Return( aThreads )

/*====================================================================================================
*Autor:  	Diogo Dorneles - LF Solucoes
*Data:   	09/05/2025
*Descrição: Job realizando atualização de saldo dos clientes e gravando status do job em arquivo .log
======================================================================================================*/
User Function JOBSA1ATU( cJobFile , cThread , aThread )    
    Local nHd1          As Numeric 
    Local W             := '' // Ocultado Nessa demonstracao!
	Local X             := '' // Ocultado Nessa demonstracao!
	Local Y             := '' // Ocultado Nessa demonstracao!
	Local Z             := '' // Ocultado Nessa demonstracao!
	Local cCliente      := ""
	Local cLoja         := ""
	Local nX            := 0

    Sleep(1000)
    // Cria arquivo se nao existir
    If !File(cJobFile)
        nHd1 := FCreate(cJobFile)
        FClose(nHd1)
    EndIf

    RpcSetType(3)
    RpcSetEnv(W,X,Y,Z) // Variaveis alteradas na demonstracao

    // status 2 = Conexao efetuada com sucesso
    nHdl := FOpen( cJobFile, FO_WRITE + FO_SHARED)                                
    If nHdl > -1
        FSeek(nHdl, 0, FS_END)
        fWrite(nHdl,"2",10)     // 2=Em Andamento
        Conout("Iniciado processamento do Job "+cJobFile)

        For nX := 1 To Len(aThread)
            cCliente := aThread[nX][1]
            cLoja    := aThread[nX][2]

            DbSelectArea("SA1")
            SA1->( DbSetOrder( 1 ) )  

            If !SA1->( DbSeek( xFilial("SA1") + cCliente + cLoja ) )
                Break
            EndIf                        
                        
            // Chama meu outro fonte para atualizar os campos A1_ATR,A1_SALDUP do cliente, usando regras e query de analise adaptado para a empresa.
            U_AtuSaldoCli(cCliente,cLoja)
        Next
        
        // status 3 = Processamento finalizado com sucesso
        Conout("Finalizado processamento do Job "+cJobFile)
        fWrite(nHdl,"3",10)
        FClose(nHdl)   
        Conout("MENSAGEM: Encerrado a THREAD "+cThread+". "+cJobFile)
        Sleep(1000)
    Else
        Conout("Erro ao tentar gravar log de Semaforo -> Log 2-3: "+cJobFile+". Erro: "+str(ferror(),4))
    EndIf    

Return

/*======================================================
Autor - Diogo Dorneles - LF Solucoes
Data - 09/05/2025
Descrição: Envio de email com as informações recebidas.
========================================================*/
Static Function EnvMail(cMsg)
	Local cMailMsg := ""
    Local _cDest := SuperGetMV("MV_ENVMAIL",.F.,"")

	cMailMsg := '<body>'
	cMailMsg += '<div align="center"><h1>NOME DA EMPRESA</h1>'
	cMailMsg += '<h2>Atualizacao Saldo de Clientes NOME DA EMPRESA</h2></div>'
	cMailMsg += '<p> Filial no sistema: '+cFilAnt+'</p>'
	cMailMsg += '<p> Via Schedule </p>'
				
	cMailMsg += '<p> ' + cMsg + ' </p>'
	cMailMsg += '<p> Dia processamento: '+DtoC(Date()) + ' </p>'	
    If "Erro" $ cMsg
        cMailMsg += '<p> Hora da tentativa final: '+cValToChar(Time()) + ' </p>'
    Endif
	cMailMsg += '</body>'

    cAssunto := 'NOME DA EMPRESA - Atualizacao Saldo de Clientes Finalizada'
    If "Erro" $ cMsg
        cAssunto := 'NOME DA EMPRESA - Erro na Atualizacao de Clientes'
    Endif

    If !Empty(_cDest)
	    _lOK := U_iEnvMail(,,,,_cDest,cAssunto,cMailMsg,,,.F.)  //Função externa para envio de email.
    Endif
Return

