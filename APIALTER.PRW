#include 'protheus.ch'
#include 'parmtype.ch'

    /* 
    ARQUIVO PARA DEMONSTRAÇÃO NO PORTFOLIO
    DADOS SENSIVEIS,ACESSOS, NOME DE FUNCOES E VARIAVEIS ORIGINAIS FORAM ALTERADOS POR QUESTAO DE SEGURANCA
    DEMONSTRACAO APENAS PARA ANALISE POR UM ESPECIALISTA, NAO FUNCIONAL SEM OS DADOS COMPLETOS
    DEMONSTRACAO DE API SIMPLES.
    */


/*/{Protheus.doc} APIALTER
 Integração para obter os dados da batida de ponto dos funcionarios ativos.
@type user function
@author Diogo Dorneles
@since 11/10/2024
@version 1.0
/*/
User Function APIALTER()
    Local cMetodo       := "GET"
    Local cBody         := ""
    Local cType         := "" // Ocultado nessa demonstracao!
    local cEndpoint     := "" 
    local aPisFind      := {} 
    local aResult       := {}
    local cDateApi      := Date() 

    local cTotal        := ""  
    local cResult       := ""
    local cStatus       := ""
    local cDevice       := ""
    local cId           := ""
    local cPis          := ""
    local cTime         := ""
    local cData         := ""
    local cHora         := ""
    local cSerial       := ""
    local cLatitude     := ""
    local cLongitude    := ""
    local cTipo         := ""  
    local cReason       := ""  

    local oRestClient
    local oJsonRet      := JsonObject():New()
    local nX            := 0
    local nZ            := 0

    RpcSetType(3)
    RpcSetEnv("W","X","Y","Z")

    //Data Atual para o formato do Endpoint
    cDateApi := Alltrim(Str(Year(Date())))+"-"+Alltrim(StrZero(Month(Date()),2))+"-"+Alltrim(StrZero(Day(Date()),2))

    //  Buscando CPFs dos funcionários ativos
    aPisFind := FindPis()

    For nX := 1 to Len(aPisFind)

    // **** API extremamente limitada que aceita apenas 1 requisicao por vez, sem permitir processar via multi-thread ****.
        If nX = 950
            Sleep(70000) // Sleep para não ultrapassar limite de 1000 consultas por minuto.(Limites da API).
        Elseif nX = 1900
            Sleep(70000) 
        Elseif nX = 2800 
            Sleep(70000) 
        Endif

        cEndPoint := "" // Ocultado nessa demonstracao!
        oRestClient := U_ApiConect(cMetodo, cEndPoint, cBody, cType )

        cStatus := oRestClient:GetHttpCode()
	
        Do Case
            Case cStatus == "200"
                oJsonRet:FromJson(oRestClient:GetResult())
                aResult := oJsonRet['data']
                cTotal := oJsonRet['total']
                cResult := "Success"
            Case cStatus == "404"
                cResult := "result 404"
            Otherwise
                oJsonRet:FromJson(oRestClient:GetLastError())
                cResult := '{"erro": "' + cStatus + ' - ' + DecodeUtf8(oRestClient:GetLastError()) + '" }'
        EndCase

        If Len(aResult) > 0 
            For nZ := 1 to Len(aResult)
                cDevice      := "" // Ocultado nessa demonstracao!
                cId          := "" // Ocultado nessa demonstracao!
                cPis         := "" // Ocultado nessa demonstracao!
                cTime        := "" // Ocultado nessa demonstracao!
                cData        := "" // Ocultado nessa demonstracao!
                cHora        := "" // Ocultado nessa demonstracao!
                cTipo        := "" // Ocultado nessa demonstracao!
                cSerial      := "" // Ocultado nessa demonstracao!
                cLatitude    := "" // Ocultado nessa demonstracao!
                cLongitude   := "" // Ocultado nessa demonstracao!
                cReason      := "" // Ocultado nessa demonstracao!

                //Passando dados para gravar nas tabelas        
                GravaZDs(cPis,cDevice,cId,cData,cHora,cSerial,cLatitude,cLongitude,cTipo,cReason) 
            Next
        
        Endif

    Next

    DbcloseArea()

Return 


User function ApiConect(cMethod, cEndPoint, cBody, cContentType)
    
    /* FORMAS DE ACESSOS E VARIAVEIS OCULTADAS NESSA DEMONSTRACAO */
    // Local Endpoint
    // Local Path
    // Local UserAuth
    // Local UsePsw

	Local oRequest    
	Local aHeaders    

	Default cBody := ''

	cBody := EncodeUtf8(cBody)

	oRequest := FWRest():New(cUrl)  
	oRequest:SetPath(cEndPoint)     

	aHeaders := {}
	AAdd(aHeaders, "") // Ocultado nessa demonstracao!

	If !Empty(cContentType)
		AAdd(aHeaders, "") // Ocultado nessa demonstracao! 
	End

	// Envia a requisição de acordo com o método definido
	If cMethod == 'GET'
		oRequest:Get(aHeaders) 
	End

Return oRequest

/*/{Protheus.doc} GravaZDs
    Inclusão dos dados de batida de ponto nas tabelas ZD3 e ZD4.
    @author Diogo Dorneles - LF Solucoes
    @since 11/10/2024
    @Parâmetros Recebidos ao chamar a função.
/*/
Static function GravaZDs(cPis,cDevice,cId,cData,cHora,cSerial,cLatitude,cLongitude,cTipo,cReason)

    Local cQuery := ""
    Local cTempAlias := GetNextAlias()

    Default cSerial     := ""
    Default cLatitude   := ""
    Default cLongitude  := ""
    Default cTipo       := ""
    Default cReason     := ""

    RpcSetType(3)
    RpcSetEnv("W","X","Y","Z")

    cQuery := "" // Query Ocultada nessa demonstracao!

    cQuery := ChangeQuery(cQuery)
    dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),cTempAlias,.T.,.T.)

    While !(cTempAlias)->(EoF())
        
        DbSelectArea('ZD3')                    
        DbSetOrder(3)

        If Empty(cSerial) 
            cSerial := "" 
        Endif

        If  dbseek((cTempAlias)->RA_FILIAL+(cTempAlias)->RA_PIS+cSerial)
            
            (cTempAlias)->(dbSkip())
            Loop
        Else
            // Inclusão nas tabelas ZD3 e ZD4
            DbSelectArea('ZD3')                    
            DbSetOrder(1)

            Begin Transaction
                RecLock('ZD3', .T.)
                    ZD3->ZD3_FILIAL := (cTempAlias)->RA_FILIAL
                    ZD3->ZD3_NOME   := (cTempAlias)->RA_NOME
                    ZD3->ZD3_PIS    := (cTempAlias)->RA_PIS
                    ZD3->ZD3_DTEXT  := Date() 
                    ZD3->ZD3_HREXT  := Time() 
                    ZD3->ZD3_CARGO  := (cTempAlias)->RA_CARGO
                    ZD3->ZD3_LATITU := cValToChar(cLatitude)  
                    ZD3->ZD3_LONGIT := cValToChar(cLongitude)
                    ZD3->ZD3_DEPART := (cTempAlias)->RA_DEPTO
                    ZD3->ZD3_CC     := (cTempAlias)->RA_CC
                    ZD3->ZD3_MAT    := (cTempAlias)->RA_MAT
                    ZD3->ZD3_DTBATI := StoD(cData)
                    ZD3->ZD3_HRBATI := cHora 
                    ZD3->ZD3_SERIAL := cSerial
                    ZD3->ZD3_DEVICE := cDevice
                    ZD3->ZD3_IDAPI  := cId
                    ZD3->ZD3_TIPO   := cTipo  
                    ZD3->ZD3_RAZAO  := cReason
                ZD3->(MsUnlock()) 
            End Transaction

            DbSelectArea('ZD4')                    
            DbSetOrder(1)

            Begin Transaction
                RecLock('ZD4', .T.)
                    ZD4->ZD4_FILIAL := (cTempAlias)->RA_FILIAL
                    ZD4->ZD4_NOME   := (cTempAlias)->RA_NOME
                    ZD4->ZD4_PIS    := (cTempAlias)->RA_PIS
                    ZD4->ZD4_DTEXT  := Date() 
                    ZD4->ZD4_HREXT  := Time() 
                    ZD4->ZD4_CARGO  := (cTempAlias)->RA_CARGO
                    ZD4->ZD4_LATITU := cValToChar(cLatitude)  
                    ZD4->ZD4_LONGIT := cValToChar(cLongitude)
                    ZD4->ZD4_DEPART := (cTempAlias)->RA_DEPTO
                    ZD4->ZD4_CC     := (cTempAlias)->RA_CC
                    ZD4->ZD4_MAT    := (cTempAlias)->RA_MAT
                    ZD4->ZD4_DTBATI := StoD(cData)
                    ZD4->ZD4_HRBATI := cHora 
                    ZD4->ZD4_SERIAL := cSerial
                    ZD4->ZD4_DEVICE := cDevice 
                    ZD4->ZD4_IDAPI  := cId
                    ZD4->ZD4_TIPO   := cTipo  
                    ZD4->ZD4_RAZAO  := cReason  
                ZD4->(MsUnlock())  
            End Transaction
        Endif

        (cTempAlias)->(dbSkip())   

    EndDo
    (cTempAlias)->(DbCloseArea())

return

static function FindPis()
    Local aPis := {}
    Local cQuery := ""
    Local cTempAlias := GetNextAlias()

    cQuery := "" // Ocultado nessa demonstracao!

    cQuery := ChangeQuery(cQuery)

    dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),cTempAlias,.T.,.T.)

    While !(cTempAlias)->(EoF())
        
        aadd(aPis, Alltrim((cTempAlias)->RA_PIS ))
        (cTempAlias)->(dbSkip())   

    EndDo
    (cTempAlias)->(DbCloseArea())

return aPis
