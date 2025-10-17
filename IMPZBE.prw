#include "protheus.ch"
#include "topconn.ch"
#include "rwmake.ch"
#include "aarray.ch"
#Include 'tbiconn.ch'
#include 'parmtype.ch'

    /* 
    ARQUIVO PARA DEMONSTRAÇÃO NO PORTFOLIO
    Dados sensiveis, acessos, nome de funcoes e variaveis originais foram alterados por questao de seguranca.
    Demonstracao apenas para analise por um especialista, nao funcional sem os dados completos.
    DEMONSTRACAO DE CONEXAO FTP E IMPORTACAO CSV.
    */

/*/{Protheus.doc} IMPZBE
    Função para importar dados de arquivos .csv no servidor via FTP e inserir na tabela 'ZBE' do Protheus).
    @type  Function
    @author Diogo Dorneles
    @since 13/08/2024
    @version 1.0
    /*/
User Function IMPZBE()

    Local aArea        := GetArea()
    
    Local aParsedCSV   := {}
	Local lMsgCSV      := .F.
	Local lImporCSV    := .F.
	Local aCampos      := {}
	Local aDados       := {}
	Local nX           := 0
	Local nX1          := 0
	Local nX2          := 0

    Local W             := '' // Ocultado Nessa demonstracao!
	Local X             := '' // Ocultado Nessa demonstracao!
	Local Y             := '' // Ocultado Nessa demonstracao!
	Local Z             := '' // Ocultado Nessa demonstracao!    
    Local xPath        := ""
    Local cArqPath    := ""
     
    Local cData        := ""
    Local aLojas       := {}

    local nPosData     := 0 
    local nPosFilial   := 0 
    local nPosSku      := 0 
    local nPosDescri   := 0 
    local nPosUC       := 0 
    local nPosQtd      := 0 
    local nPosTipo     := 0 
    local nPosAcao     := 0 
    local nPosCurva    := 0 
    local nPosVenda    := 0 
    local nPosEmpurr   := 0 

    Private cDataHj    := ""
    Private aArquivos  := {}
    Private cArqServ   := ""
    Private cArqServ2  := ""
    Private aMSGErr := {}

    RpcSetType(3)
    RpcSetEnv(W,X,Y,Z) // Variaveis alteradas na demonstracao
    DbSelectArea('ZBE')
    
    FGetLojas( @aLojas ) // Obtendo todas as filiais

	cFilAtu := cFilAnt
    cDataHj := dtos(dDatabase)  

    // Processamento da rotina por filial
    For nX1 := 1 To Len( aLojas )

        cFilAtu := aLojas[nX1,1]
        cLojaNome := Alltrim(aLojas[nX1,2])

        xPath := "\"+/*// Ocultado nessa demonstracao!*/"\"      // Caminho local
        cArqServ := ""+/*// Ocultado nessa demonstracao!*/" - " + cLojaNome + " - " + cDataHj + ".csv" // Nome no servidor em UTF8
        cArqServ2 := ""+/*// Ocultado nessa demonstracao!*/" - " + cLojaNome + " - " + cDataHj + ".csv" // Nome na local e sem UTF8.

        // demonstracao o arquivo do servidor para a maquina local
        If !demonstracaoFtp(cLojaNome)
			Loop
		EndIf

        if !Empty(aArquivos)

            For nX2 := 1 To Len( aArquivos )
                
                cArqPath := xPath + cArqServ2

                // Realiza a leitura do Arquivo CSV
                lMsgCSV   := .F. 
                lImporCSV := U_ExtCsvRead(@aParsedCSV,cArqPath,lMsgCSV) // User function customizada para leitura de CSV.

                // Importa os dados para a tabela ZBE
                If lImporCSV 
                    aCampos := aParsedCSV[#'campos']
                    aDados  := aParsedCSV[#'dados']

                    // Nome das colunas no arquivo csv ocultados nessa demonstracao.
                    nPosData     := AScan(aCampos,''+/*// Ocultado nessa demonstracao!*/'') 
                    nPosFilial   := AScan(aCampos,''+/*// Ocultado nessa demonstracao!*/'')
                    nPosSku      := AScan(aCampos,''+/*// Ocultado nessa demonstracao!*/'')
                    nPosDescri   := AScan(aCampos,''+/*// Ocultado nessa demonstracao!*/'')
                    nPosUC       := AScan(aCampos,''+/*// Ocultado nessa demonstracao!*/'')
                    nPosQtd      := AScan(aCampos,''+/*// Ocultado nessa demonstracao!*/'')
                    nPosTipo     := AScan(aCampos,''+/*// Ocultado nessa demonstracao!*/'')
                    nPosAcao     := AScan(aCampos,''+/*// Ocultado nessa demonstracao!*/'')
                    nPosCurva    := AScan(aCampos,''+/*// Ocultado nessa demonstracao!*/'')
                    nPosVenda    := AScan(aCampos,''+/*// Ocultado nessa demonstracao!*/'')
                    nPosEmpurr   := AScan(aCampos,''+/*// Ocultado nessa demonstracao!*/'')

                    For nX := 1 To Len(aDados) 

                        cData     := SToD(AllTrim(aDados[nX][nPosData]))
                        cFili     := AllTrim(aDados[nX][nPosFilial])
                        cSku      := AllTrim(aDados[nX][nPosSku])
                        cDescri   := AllTrim(aDados[nX][nPosDescri])
                        cUC       := AllTrim(aDados[nX][nPosUC])
                        nQtd      := Val(StrTran((aDados[nX][nPosQtd]),",","."))
                        cTipo     := AllTrim(aDados[nX][nPosTipo])
                        cAcao     := AllTrim(aDados[nX][nPosAcao])
                        cCurva    := AllTrim(aDados[nX][nPosCurva])
                        nVenda    := Round(Val(StrTran((aDados[nX][nPosVenda]),",",".")),4)
                        cEmpurr   := AllTrim(aDados[nX][nPosEmpurr])
                        
                        if cData = Date()

                            DbSelectArea('ZBE')
                            RecLock('ZBE', .T.)

                                ZBE->ZBE_DATA     := cData
                                ZBE->ZBE_FILIAL   := cFili
                                ZBE->ZBE_SKU      := cSku
                                ZBE->ZBE_DESC     := cDescri
                                ZBE->ZBE_UC       := cUC
                                ZBE->ZBE_QTD      := nQtd
                                ZBE->ZBE_TIPO     := cTipo
                                ZBE->ZBE_ACAO     := cAcao
                                ZBE->ZBE_CURVA    := cCurva
                                ZBE->ZBE_VENDA    := nVenda
                                ZBE->ZBE_EMPUR    := cEmpurr

                            MsUnlock()

                        Else
                            MsgInfo("Data diferente de hoje","Aviso")
                        Endif

                    Next nX

                Endif

            Next nX2    
        else
            MsgInfo("Pasta vazia","Aviso")
        endif

    Next nX1

    RestArea(aArea)

    DbCloseArea()
	RpcClearEnv()

return

/*/{Protheus.doc} FGetLojas()
    Auto: Diogo Dorneles
    Função para obter as filiais com o código e o nome.
    @type  Static Function
    @param aLojas, Array, número das filiais.
    /*/
Static Function FGetLojas(aLojas)
	Local _cQuery 	:= ""
	Local cAlias	:= GetNextAlias()

	_cQuery += "SELECT CODFIL, FILIAL "
	_cQuery += "FROM "+/*// Ocultado nessa demonstracao!*/" "
	_cQuery += "WHERE PRIORIDADE IS NOT NULL "
	_cQuery += "ORDER BY PRIORIDADE "
	TCQuery _cQuery New Alias (cAlias)

	While !Eof()         
		IF (cAlias)->CODFIL = ''+/*// Ocultado nessa demonstracao!*/'' 
            AADD(aLojas, {(cAlias)->CODFIL,''+/*// Ocultado nessa demonstracao!*/''})
        elseif (cAlias)->CODFIL = ''+/*// Ocultado nessa demonstracao!*/'' 
            AADD(aLojas, {(cAlias)->CODFIL,''+/*// Ocultado nessa demonstracao!*/''})        
        Else 
            AADD(aLojas, {(cAlias)->CODFIL,(cAlias)->FILIAL})                   
        EndIf

		DbSkip()
	End
	DbCloseArea()
Return

/*/{Protheus.doc} demonstracaoFtp()
    Auto: Diogo Dorneles
    Função para acessar servidor via FTP e copiar o arquivo para maquina local.
    @type  Static Function
    @param cLojaNome, Caracter, Nome da Filial.
    /*/
Static Function demonstracaoFtp(cLojaNome)

	/*
        FORMA DE RECEBER DADOS DE ACESSO OCULTADOS NESSA demonstracao!
    */
	Local lRet      := .T.
	Local n
	Local oFTPHandle As Object

    Local cDestino		:= '' // Ocultados nessa demonstracao!
    Local xDiretorio := "" // Ocultados nessa demonstracao!
    

	xDiretorio 		:= ""  // Ocultados nessa demonstracao!

	Begin Sequence

		oFTPHandle := TFtpClient():New()
        oFTPHandle:bFirewallMode := '' // Ocultados nessa demonstracao! // Ajuste apos migracao do banco de dados para o Tcloud

 		If oFTPHandle:FTPConnect( /*Login*/ , /*Porta*/ , /*Login*/ , /*Senha*/ ,/*[cAccount]*/ ) # 0	// Ocultados nessa demonstracao!	
            U_FXCONOUT( oFTPHandle:GetLastResponse() )  // Funcao customizada para conout.
			Break
		EndIf

		If oFTPHandle:ChDir(xDiretorio ) # 0

			U_FXCONOUT(""+xDiretorio)

			U_FXCONOUT('Não foi possivel acessar local do arquivo' )

			U_FXCONOUT( oFTPHandle:GetLastResponse() )

			aAdd(aMSGErr,"Filial " + cFilAtu + " > Não foi possivel acessar local do arquivo: "+xDiretorio)

			aAdd(aMSGErr,"Retorno do Servidor FTP - " + oFTPHandle:GetLastResponse() )
			
			Break   

		EndIf
		
		aArquivos := oFTPHandle:Directory( cArqServ ) // Passando o arquivo do dia

		If Len(aArquivos) == 0

			U_FXCONOUT('Nenhum pedido encontrado ' + xDiretorio )

			Break

		EndIf

		For N := 1 to Len(aArquivos)

			Begin Sequence

				If aArquivos[N][2] == 0
					Break
				EndIf

				If oFTPHandle:ReceiveFile( aArquivos[n][1] , cDestino + cArqServ2 ) # 0

					aAdd(aMSGErr,"Filial " + cFilAtu + 'Erro ao copiar arquivo '+ cArqServ2)
					aAdd(aMSGErr,"Retorno do Servidor FTP - " + oFTPHandle:GetLastResponse() )

					U_FXCONOUT('Erro ao copiar arquivo '+ cArqServ2 )
					U_FXCONOUT( oFTPHandle:GetLastResponse() )

					Break

				EndIf

                //Renomeando arquivo para backup
                If oFTPHandle:RenameFile( aArquivos[n][1], Strtran(cArqServ2, '.csv', '.bkp') ) # 0
                    aAdd(aMSGErr,"Filial " + cFilAtu + ' - Erro ao renomear arquivo '+ aArquivos[n][1] )
                    aAdd(aMSGErr,"Retorno do Servidor FTP - " + oFTPHandle:GetLastResponse() )

                    U_FXCONOUT('Erro ao renomear o arquivo '+ aArquivos[n][1] )
                    U_FXCONOUT( oFTPHandle:GetLastResponse() )                
                EndIf


			End Sequence

		Next N

	Recover
	
		lRet := .f.

	End Sequence

Return lRet
