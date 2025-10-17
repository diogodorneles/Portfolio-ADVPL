#include 'totvs.ch'
#include 'fwmvcdef.ch'
#include "topconn.ch"

    /* 
    ARQUIVO PARA DEMONSTRAÇÃO NO PORTFOLIO
    Dados sensiveis, acessos, nome de funcoes e variaveis originais foram alterados por questao de seguranca.
    Demonstracao apenas para analise por um especialista, nao funcional sem os dados completos.
    DEMONSTRACAO DE MVC MODELO SIMPLES.
    */

/*=============================================================================================
*Fonte:	 	PERIZZO()
*Autor:  	Diogo Dorneles - LF Solucoes
*Data:   	09/01/2025
*Descrição: Criar Browser da tabela de Itens. // Nome da tabela original alterado nessa copia.
=============================================================================================*/
User Function PERIZZO()
    Local nOpcPad := 2 // Opção padrão do menu.
    // Local aLegenda := {} 
    Private cCadastro := 'Cadastro de Itens' 
    Private aRotina := {} 

    aadd(aRotina,{"Pesquisar"   ,"axPesqui"   ,0,1}) 
    aadd(aRotina,{"Visualizar"  ,"axVisual"   ,0,2}) 
    aadd(aRotina,{"Incluir"     ,"U_ZZO01I" ,0,3}) 
    aadd(aRotina,{"Alterar"     ,"U_ZZO01A" ,0,4}) 
    aadd(aRotina,{"Excluir"     ,"U_ZZO01D" ,0,5}) 
    aadd(aRotina,{"Importar"    ,"U_PERIIMP"  ,0,6})  
    aadd(aRotina,{"Exportar"    ,"U_PERIEXP"  ,0,6}) 
    aadd(aRotina,{"Remover Ano" ,"U_PERIDEL"  ,0,6}) 
    // aadd(aRotina,{"Legendas"  ,"U_ZZOLEG"   ,0,6}) // Legenda - Sem uso atualmente.    
        // aadd(aLegenda,{"ZZO_ANO = '2024' ", "BR_VERDE"}) 
        // aadd(aLegenda,{"ZZO_ANO = '2025' ", "BR_AMARELO"})
        // aadd(aLegenda,{"!Empty(ZZO_ANO) .AND. !(ZZO_ANO $ '2025|2024') ", "BR_CINZA"})
        // aadd(aLegenda,{"Empty(ZZO_ANO)", "BR_VERMELHO"})
    // 

    dbSelectArea("ZZO")
    dbSetOrder(1)

    mBrowse(,,,,alias(),,,,,nOpcPad,/*aLegenda*/) 
return


/*/{Protheus.doc} U_ZZO01I
    Autor:      Diogo Dorneles - LF Solucoes
    Descrição:  Programa auxiliar para inclusão de item(Alterado na copia)
    Data:       07/01/2025
    @type Function/*/
User Function ZZO01I(cAlias,nReg,nOpc)     
    ALTERA := .F.        
Return axInclui(cAlias,nReg,nOpc,,,,"U_ZZODT()")


/*/{Protheus.doc} U_ZZO01A
    Autor:      Diogo Dorneles - LF Solucoes
    Descrição:  Programa auxiliar para alteração de item(Alterado na copia)
    Data:       07/01/2025
    @type Function/*/
User Function ZZO01A(cAlias,nReg,nOpc) 
    Local aArea     := GetArea()    
    Local dData     := SuperGetMV("MV_DATAITE", .F., "")
    Local cAno      := SubStr(DtoS(dData),1,4)
    Local cAnoAtual := ZZO->ZZO_ANO

    IF cAnoAtual <= cAno .And. !Empty(dData) .And. !Empty(cAnoAtual)
        fwAlertWarning('Ano de Itens bloqueado para Alteração.','Atenção')
        return .F.
    EndIF        
    RestArea(aArea)
Return axAltera(cAlias,nReg,nOpc,,,,,"U_ZZODT()")


/*/{Protheus.doc} U_ZZO01D
    Autor:      Diogo Dorneles - LF Solucoes
    Descrição:  Programa auxiliar para exclusão de item
    Data:       07/01/2025
    @type Function/*/
User Function ZZO01D(cAlias,nReg,nOpc) 
    Local aArea     := GetArea()    
    Local dData     := SuperGetMV("MV_DATAITE", .F., "")
    Local cAno      := SubStr(DtoS(dData),1,4)
    Local cAnoAtual := ZZO->ZZO_ANO

    IF cAnoAtual <= cAno .And. !Empty(dData) .And. !Empty(cAnoAtual)
        fwAlertWarning('Ano de Itens bloqueado para Exclusão.','Atenção')
        return .F.
    EndIF        
    RestArea(aArea)
Return axDeleta(cAlias,nReg,nOpc)


/*/{Protheus.doc} U_ZZO01I    
    Autor:      Diogo Dorneles - LF Solucoes
    Descrição:  Programa auxiliar para validar o ano do Itens.
    Data:       07/01/2025
    @type Function/*/
User Function ZZODT(cAlias,nReg,nOpc) 
    Local aArea     := GetArea()  
    Local dData     := SuperGetMV("MV_DATAITE", .F., "")
    Local cAnoParam      := SubStr(DtoS(dData),1,4)
    Local cAnoAtual := M->ZZO_ANO

    IF cAnoAtual <= cAnoParam .And. !Empty(dData) .And. !Empty(cAnoAtual) .And. IsNumeric(cAnoAtual)
        fwAlertWarning('Ano de Itens bloqueado para Inclusão/Alteração.','Atenção')
        return .F.
    Elseif cAnoAtual >= '2090' .or. Empty(cAnoAtual) .or. !IsNumeric(cAnoAtual)
        fwAlertWarning('Ano de Itens Inválido.','Atenção')
        return .F.
    EndIF        
    RestArea(aArea)
Return .T.


/*============================================================================================================================
*Fonte:	 	FSOMAUM()
*Autor:  	Diogo Dorneles - LF Solucoes
*Data:   	07/01/2025
*Descrição: Busca proximo sequencial na tabela para geração de novos Itens. Usado como valor inicial do campo e na importacao.
*Rotina:	Inicializador padrão do campo ZZO_COD.
=============================================================================================================================*/
User function FSOMAUM()
    Local xTemp2    := GetNextAlias()
    Local cQuery    := ""    
    Local cResult   := "" 

	cQuery := CRLF + "SELECT MAX(ZZO_COD) AS MAX FROM "+retsqlname('ZZO')+" WHERE D_E_L_E_T_ = ''; "	
    
    DBUseArea( .T., "TOPCONN", TCGENQRY( ,, cQuery ), xTemp2, .T., .T. )
    While !( xTemp2 )->( EOF() )      

        If Empty((xTemp2)->MAX)
            cResult := "000000"
        Else
            cResult := soma1((xTemp2)->MAX) 
        Endif         
        DBSkip()
    EndDO
    (xTemp2)->(DbCloseArea())
return cResult

/*/{Protheus.doc} U_ZZOLEG
    Autor:      Diogo Dorneles - LF Solucoes
    Descrição:  Função auxiliar para descrição das legendas. Atualmente sem uso.    
    Data:       09/01/2025
    @type Function /*/               
// User Function ZZOLEG()        
//     Local aLegenda := array(0)
//     aadd(aLegenda,{"BR_VERDE"    ,"Itens 2024" }) 
//     aadd(aLegenda,{"BR_AMARELO"  ,"Itens 2025"})
//     aadd(aLegenda,{"BR_VERMELHO" ,"Itens Sem Ano"   })
//     aadd(aLegenda,{"BR_CINZA"    ,"Itens Ano diferente"})
// Return brwLegenda("Tipos de Itens","Legenda",aLegenda)
