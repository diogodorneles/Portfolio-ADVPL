#INCLUDE "PROTHEUS.CH"
#INCLUDE "TOPCONN.CH"
#include 'TOTVS.CH'

    /* 
    ARQUIVO PARA DEMONSTRAÇÃO NO PORTFOLIO
    Dados sensiveis, acessos, nome de funcoes e variaveis originais foram alterados por questao de seguranca.
    Demonstracao apenas para analise por um especialista, nao funcional sem os dados completos.
    DEMONSTRACAO DE PONTO DE ENTRADA.
    */

/*=============================================================================
{Protheus.doc}  CTBGRV
                Modificacões apos gravacao do lancamento contabil.
                Gravar os campos CT2_CODCLI ou CT2_CODFOR.
@type           function
@author         Diogo Dorneles
@since          03/12/2024
@hist           https://tdn.totvs.com/pages/releaseview.action?pageId=235585410 
@------------------------------------------------------------------------------
@Atualizacao:   09/01/2025 - Incrementado gravacao na CT2 com ou sem rateio.               
==============================================================================*/

/* OBSERVACAO: DETALHES E DETERMINADAS LINHAS FORAM OCULTADAS NESSA DEMONSTRACAO */

User Function CTBGRV()

    Local aArea     := GetArea()
    Local cProgr    := ParamIxb[2]
    Local cFornece  := ""
    Local cCliente  := ""
    Local cCliFor   := ""
    Local cCont     := ""
    Local cAlias    := GetNextAlias()
    Local cQueryCT2 := ""

	nOpcLct := PARAMIXB[1] // Tipo de operacao   [inclusao / alteracao / estorno do lancamento contabil]
	cProgr  := PARAMIXB[2] // Rotina

	If nOpcLct == 3     // Inclusao de CT2
        
        If Alltrim(cProgr)  ==  'MATA103'           // Rotina Documento de Entrada  
            If CT2->CT2_VALOR > 0            
                If CT2->CT2_LP $ '640|650|655|'  .AND. !Empty(CT2->CT2_KEY)
                    cFornece := SubStr(CT2->CT2_KEY,20,6)
                    CT2->CT2_CODFOR := cFornece 

                    // Se possuir rateio(SCH) e CT2_DC = 2.
                    DbSelectArea('SD1')
                    DbSetOrder(1)
                    If DbSeek(CT2->CT2_KEY)

                        DbSelectArea('SC7') 
                        DbSetOrder(2)
                        If DbSeek(SD1->D1_FILIAL+SD1->D1_COD+SD1->D1_FORNECE+SD1->D1_LOJA+SD1->D1_PEDIDO)

                            DbSelectArea('SCH') 
                            DbSetOrder(1)
                            If DbSeek(SD1->D1_FILIAL+SD1->D1_PEDIDO+SD1->D1_FORNECE+SD1->D1_LOJA+SD1->D1_ITEM)//+SCH_ITEM

                                If CT2->CT2_DC = '2'
                                    return
                                Endif                                
                            EndIf
                            CT2->CT2_XORCPR := SC7->C7_XORCAPR 
                        EndIf
                    Endif
                Elseif CT2->CT2_LP $ '641|651'  .AND. !Empty(CT2->CT2_KEY)
                    cFornece := SubStr(CT2->CT2_KEY,20,6)
                    CT2->CT2_CODFOR := cFornece 

                    // Buscando Rateio na SCH
                    DbSelectArea('SD1')
                    DbSetOrder(1)
                    If DbSeek(CT2->CT2_KEY) 

                        DbSelectArea('SCH') 
                        DbSetOrder(1)
                        If DbSeek(SD1->D1_FILIAL+SD1->D1_PEDIDO+SD1->D1_FORNECE+SD1->D1_LOJA+SD1->D1_ITEM+SubStr(CT2->CT2_LINHA,2,3))                            
                            CT2->CT2_XORCPR := SCH->CH_XORCAPR
                        EndIf
                    Endif
                Endif
            Endif 
        
        ElseIf Alltrim(cProgr)  ==  'CTBANFE'       // Rotina Documento de Entrada 
            If CT2->CT2_VALOR > 0            
                If CT2->CT2_LP $ '640|650|655|'  .AND. !Empty(CT2->CT2_KEY)
                    cFornece := SubStr(CT2->CT2_KEY,20,6)
                    CT2->CT2_CODFOR := cFornece 
                    
                    DbSelectArea('SD1')
                    DbSetOrder(1)
                    If DbSeek(CT2->CT2_KEY)

                        DbSelectArea('SC7') 
                        DbSetOrder(2)
                        If DbSeek(SD1->D1_FILIAL+SD1->D1_COD+SD1->D1_FORNECE+SD1->D1_LOJA+SD1->D1_PEDIDO)

                            DbSelectArea('SCH') 
                            DbSetOrder(1)
                            If DbSeek(SD1->D1_FILIAL+SD1->D1_PEDIDO+SD1->D1_FORNECE+SD1->D1_LOJA+SD1->D1_ITEM)//+SCH_ITEM

                                If CT2->CT2_DC = '2'
                                    return
                                Endif                                
                            EndIf
                            CT2->CT2_XORCPR := SC7->C7_XORCAPR 
                        EndIf
                    Endif
                Elseif CT2->CT2_LP $ '641|651'  .AND. !Empty(CT2->CT2_KEY)
                    cFornece := SubStr(CT2->CT2_KEY,20,6)
                    CT2->CT2_CODFOR := cFornece 

                    // Buscando Rateio na SCH
                    DbSelectArea('SD1')
                    DbSetOrder(1)
                    If DbSeek(CT2->CT2_KEY) 
                        
                        cQueryCT2 := " SELECT COUNT(*) AS CONT FROM "+retsqlname('CT2') + " "
                        cQueryCT2 += "WHERE D_E_L_E_T_ = ' ' AND CT2_KEY = '"+Alltrim(CT2->CT2_KEY)+"' AND CT2_LP != '651'; "

                        DBUseArea( .T., "TOPCONN", TCGENQRY( ,, cQueryCT2 ), cAlias, .T., .T. )
                        If !Empty((cAlias)->CONT)
                            nCont := (cAlias)->CONT
                        Endif                                                   
                        (cAlias)->(DbCloseArea()) 

                        cCont := StrZero(Val(SubStr(CT2->CT2_LINHA,2,3))-nCont,2)

                        DbSelectArea('SCH') 
                        DbSetOrder(1)   
                        If DbSeek(SD1->D1_FILIAL+SD1->D1_PEDIDO+SD1->D1_FORNECE+SD1->D1_LOJA+SD1->D1_ITEM+cCont)
                            CT2->CT2_XORCPR := SCH->CH_XORCAPR
                        EndIf
                    Endif
                Endif
            Endif 

        ElseIf Alltrim(cProgr)  ==  'CTBANFS'       // Rotina Documento de saída
            If CT2->CT2_VALOR > 0            
                If CT2->CT2_LP $ '610|620|630|635|678'  .AND. !Empty(CT2->CT2_KEY)
                    cCliente := SubStr(CT2->CT2_KEY,20,6)
                    CT2->CT2_CODCLI := cCliente
                Endif
            Endif 

        Elseif Alltrim(cProgr)  ==  'FINA040'       // Manutencao do Contas a Receber
            If CT2->CT2_LP $ '500|501|502|505' .AND. !Empty(CT2->CT2_KEY)
                cCliente := SubStr(CT2->CT2_KEY,8,6)  
                CT2->CT2_CODCLI  := cCliente
            Endif
        
        Elseif Alltrim(cProgr)  ==  'FINA050'       // Manutencao do Contas a Pagar 
            If CT2->CT2_VALOR > 0 
                If CT2->CT2_LP $ '510|511|512|513|514|515|' .AND. !Empty(CT2->CT2_KEY)
                    cFornece := SubStr(CT2->CT2_KEY,24,6)  
                    CT2->CT2_CODFOR   := cFornece
                    
                    DbSelectArea('SE2')
                    DbSetOrder(1)
                    If DbSeek(CT2->CT2_KEY)
                        If Empty(CT2->CT2_XORCPR)
                            CT2->CT2_XORCPR := SE2->E2_XORCAPR                       
                        Endif
                    Endif                    
                Endif
            Endif  

        Elseif Alltrim(cProgr)  ==  'FINA070'       // Baixa Contas a Receber
            If CT2->CT2_LP $ '520|527' .AND. !Empty(CT2->CT2_KEY)
                cCliente := SubStr(CT2->CT2_KEY,34,6)  
                CT2->CT2_CODCLI  := cCliente
            Elseif CT2->CT2_LP $ '521|522|523|524|525|526|528' .AND. !Empty(CT2->CT2_KEY)                
                DbSelectArea('SE1')
                DbSetOrder(1)
                If DbSeek(CT2->CT2_KEY)
                    cCliente := E1_CLIENTE
                    Begin Transaction
                        Reclock('CT2',.F.)
                            CT2_CODCLI := cCliente
                        CT2->(MsUnlock())
                    End Transaction
                Endif
            Endif      

        Elseif Alltrim(cProgr)  ==  'FINA080'       // Baixa de Títulos no Contas a Pagar 
            If CT2->CT2_LP $ '530|531' .AND. !Empty(CT2->CT2_KEY)
                cFornece := SubStr(CT2->CT2_KEY,34,6)  
                CT2->CT2_CODFOR  := cFornece
            Elseif CT2->CT2_LP $ '518|519|' .AND. !Empty(CT2->CT2_KEY) 
                cFornece := SubStr(CT2->CT2_KEY,24,6)  
                CT2->CT2_CODFOR  := cFornece
            Endif

            DbSelectArea('SE2')
            DbSetOrder(1)
            If DbSeek(CT2->CT2_KEY)
                If Empty(CT2->CT2_XORCPR)
                    CT2->CT2_XORCPR := SE2->E2_XORCAPR     
                Endif
            Endif  

        Elseif Alltrim(cProgr)  ==  'FINA090'       // Baixa Automatica (Bordero) Títulos no Contas a Pagar
            If CT2->CT2_LP $ '530|531|532' .AND. !Empty(CT2->CT2_KEY)
                cFornece := SubStr(CT2->CT2_KEY,34,6) 
                CT2->CT2_CODFOR  := cFornece
            Endif     

            DbSelectArea('SE2')
            DbSetOrder(1)
            If DbSeek(CT2->CT2_KEY)
                If Empty(CT2->CT2_XORCPR)
                    CT2->CT2_XORCPR := SE2->E2_XORCAPR      
                Endif
            Endif  

        Elseif Alltrim(cProgr)  ==  'FINA110'       // Baixa automatica (Bordero) Titulos no Contas a Receber
            If CT2->CT2_LP $ '520' .AND. !Empty(CT2->CT2_KEY)
                cCliente := SubStr(CT2->CT2_KEY,34,6)  
                CT2->CT2_CODCLI  := cCliente
            Elseif CT2->CT2_LP $ '521|522|523|524|525|526|528' .AND. !Empty(CT2->CT2_KEY)                
                DbSelectArea('SE1')
                DbSetOrder(1)
                If DbSeek(CT2->CT2_KEY)
                    cCliente := E1_CLIENTE
                    
                    CT2_CODCLI := cCliente                        
                Endif
            Endif  

        Elseif Alltrim(cProgr)  ==  'FINA200'       // Retorno de Comunicacao Bancaria 
            If CT2->CT2_LP $ '520' .AND. !Empty(CT2->CT2_KEY)
                cCliente := SubStr(CT2->CT2_KEY,34,6)  
                CT2->CT2_CODCLI  := cCliente
            Elseif CT2->CT2_LP $ '521|522|523|524|525|526|528' .AND. !Empty(CT2->CT2_KEY)
                DbSelectArea('SE1')
                DbSetOrder(1)
                If DbSeek(CT2->CT2_KEY)
                    cCliente := E1_CLIENTE
                    Begin Transaction
                        Reclock('CT2',.F.)
                            CT2_CODCLI := cCliente
                        CT2->(MsUnlock())
                    End Transaction
                Endif
            Endif                 

        Elseif Alltrim(cProgr)  ==  'FINA241'       // Bordero - Ele cria algumas Baixas Contas a PAGAR
            If CT2->CT2_VALOR > 0 
                If CT2->CT2_LP $ '530|531' .AND. !Empty(CT2->CT2_KEY)
                    cFornece := SubStr(CT2->CT2_KEY,34,6)  
                    CT2->CT2_CODFOR   := cFornece 
                Endif
            Endif

            DbSelectArea('SE2')
            DbSetOrder(1)
            If DbSeek(CT2->CT2_KEY)
                If Empty(CT2->CT2_XORCPR)
                    CT2->CT2_XORCPR := SE2->E2_XORCAPR      
                Endif
            Endif  

        Elseif Alltrim(cProgr)  ==  'FINA330'       // Compensacao de Adiantamento a Receber 
            If CT2->CT2_VALOR > 0 
                If CT2->CT2_LP $ '588|596|'  .AND. !Empty(CT2->CT2_KEY)
                    cCliente := SubStr(CT2->CT2_KEY,34,6)  
                    CT2->CT2_CODCLI   := cCliente                     
                Endif  
            Endif

        Elseif Alltrim(cProgr)  ==  'FINA340'       // Compensacao de Adiantamento a Pagar
            If CT2->CT2_VALOR > 0 
                If CT2->CT2_LP $ '589|597|' .AND. !Empty(CT2->CT2_KEY)
                    cFornece := SubStr(CT2->CT2_KEY,34,6)  
                    CT2->CT2_CODFOR  := cFornece
                Endif  
            Endif

        ElseIf Alltrim(cProgr)  ==  'FINA450'       // Compensacao entre Carteiras
            If CT2->CT2_VALOR > 0 
                If CT2->CT2_LP $ '594|' .AND. !Empty(CT2->CT2_KEY)
                    cCliFor := SubStr(CT2->CT2_KEY,34,6) 
                    CT2->CT2_CODFOR  := cCliFor
                    CT2->CT2_CODCLI  := cCliFor     // Receber o mesmo codigo em ambos.
                Endif
            Endif
		EndIf
	EndIf

    SE1->(dbCloseArea())
    SCH->(dbCloseArea())
    RestArea(aArea)
Return()
