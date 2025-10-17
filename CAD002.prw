
//Bibliotecas
#Include 'Protheus.ch'
#Include 'FWMVCDef.ch'
 
Static cTitulo := "Cadastro de material"
 
    /* 
    ARQUIVO PARA DEMONSTRAÇÃO NO PORTFOLIO
    Dados sensiveis, acessos, nome de funcoes e variaveis originais foram alterados por questao de seguranca.
    Demonstracao apenas para analise por um especialista, nao funcional sem os dados completos.
    DEMONSTRACAO DE TELA MVC E GERACAO DE RELATORIO SIMPLES.
    */


/*/{Protheus.doc} U_CAD002
Função para cadastro de Materiais e Partes envolvidas.
@type user function
@author Diogo Dorneles
@since 06/05/2024
@version 1.0
/*/
User Function CAD002()

    Local cUser   := Alltrim(SuperGetMV("MV_XUSRCUR", .F.,"000001")) 
    Local aArea   := GetArea()
    Local oBrowse := FwLoadBrw("CAD002")
    Local cFunBkp := FunName()
    // local cUserAtu := usrretname(__cUserID) // verificar pelo nome do usuário
    

    IF __cUserID $ cUser
        MsgAlert("Usuário Autorizado!", "Atenção")

        SetFunName("CAD002")

        oBrowse := FWMBrowse():New()
        oBrowse:SetAlias("SZS")
        oBrowse:SetDescription(cTitulo)

        //aadd(aLegenda, {"SZS->ZS_UNIDAD == 'ES' ", "BR_AMARELO"}) 
        oBrowse:AddLegend( "SZS->ZS_UNIDAD == 'ES' ", "BR_AMARELO")
        oBrowse:AddLegend( "SZS->ZS_UNIDAD == 'MG' ", "BR_VERDE")
        oBrowse:AddLegend( "SZS->ZS_UNIDAD == 'RJ' ", "BR_AZUL")
        oBrowse:AddLegend( "SZS->ZS_UNIDAD == 'SP' ", "BR_VERMELHO")
        oBrowse:AddLegend( "aScan({'ES','MG','RJ','SP'}, SZS->ZS_UNIDAD) == 0 ", "BR_CINZA")

        oBrowse:Activate()
        SetFunName(cFunBkp)
        RestArea(aArea)

    Else
        MsgAlert("Usuário não possui permissão!", "Atenção")
    EndIf

Return Nil
  
Static Function BrowseDef()
    Local oBrowse := FwMBrowse():New()

    oBrowse:SetAlias("SZS")
    oBrowse:SetDescription("Material Protheus 02")

   oBrowse:SetMenuDef("CAD002")
Return (oBrowse)

Static Function MenuDef()
    Local aRot := {}
    //Adicionando opções
    ADD OPTION aRot TITLE 'Visualizar'    ACTION 'VIEWDEF.CAD002' OPERATION MODEL_OPERATION_VIEW   ACCESS 0 //OPERATION 1
    ADD OPTION aRot TITLE 'Inserir'       ACTION 'VIEWDEF.CAD002' OPERATION MODEL_OPERATION_INSERT ACCESS 0 //OPERATION 3
    ADD OPTION aRot TITLE 'Alterar'       ACTION 'VIEWDEF.CAD002' OPERATION MODEL_OPERATION_UPDATE ACCESS 0 //OPERATION 4
    ADD OPTION aRot TITLE 'Excluir'       ACTION 'VIEWDEF.CAD002' OPERATION MODEL_OPERATION_DELETE ACCESS 0 //OPERATION 5
    // ADD OPTION aRot TITLE 'Imprimir'      ACTION 'U_fFuncExp'     OPERATION MODEL_OPERATION_DELETE ACCESS 0 //OPERATION 5
    ADD OPTION aRot TITLE 'Legenda'       ACTION 'U_SZSLEG'        OPERATION 6                      ACCESS 0 //OPERATION 6
    ADD OPTION aRot TITLE 'Gerar Excel'   ACTION 'U_fGeraExcel'    OPERATION MODEL_OPERATION_UPDATE ACCESS 0 //OPERATION 5    

Return aRot
 
 
Static Function ModelDef() 

    Local oModel     
    oModel := MPFormModel():New("MODELSZS",/*bPre*/, /*bPos*/,/*bCommit*/,/*bCancel*/) 

    // Instancia os submodelos
    Local oStSZS := FWFormStruct(1, "SZS")
    Local oStSZZ := FwFormStruct(1, "SZZ") 
    //Local aSZZrel := {}
    //Local oForm

    // Field ou grid
    oModel:AddFields("SZSMASTER",/*cOwner*/,oStSZS)
    oModel:AddGrid("SZZDETAIL", "SZSMASTER", oStSZZ)

    // Relação entre os submodelos
    oModel:SetRelation("SZZDETAIL", {{"ZZ_FILIAL", "FwXFilial('SZZ')"}, {"ZZ_MATERIA", "ZS_COD"/*, {zZ_...}*/}}, SZZ->(IndexKey(1)))

    oModel:SetPrimaryKey({})

    // Descrição do modelo
    oModel:SetDescription(cTitulo)

    // Descrição dos submodelos
    oModel:GetModel("SZSMASTER"):SetDescription(cTitulo)
    oModel:GetModel("SZZDETAIL"):SetDescription("Dados das partes")

    /*oForm := MPForm():New(oModel)
    oForm:CreateForm()
    oForm:Show()*/


Return oModel
 
 
Static Function ViewDef()
     
    // Cria a View
    Local oView := FWFormView():New()

    // Cria as subviews
    Local oStSZS := FWFormStruct(2, "SZS")  //pode-se usar um terceiro parâmetro para filtrar os campos exibidos { |cCampo| cCampo $ 'SZZS_NOME|SZZS_DTAFAL|'}
    Local oStSZZ := FwFormStruct(2, "SZZ") 

    // Recebe o modelo de dados
    Local oModel := FwLoadModel("CAD002")

    // Indica o modelo da view
    oView:SetModel(oModel)

    // Cria estrutura visual de campos
    oView:AddField("VIEW_SZS", oStSZS, "SZSMASTER")
    oView:AddGrid("VIEW_SZZ", oStSZZ, "SZZDETAIL")

    // Cria boxes horizontais
    oView:CreateHorizontalBox("SUPERIOR", 40)
    oView:CreateHorizontalBox("INFERIOR", 60)

    // Relaciona os boxes com as estruturas visuais
    oView:SetOwnerView("VIEW_SZS", "SUPERIOR")
    oView:SetOwnerView("VIEW_SZZ", "INFERIOR")
     
    //oView:SetCloseOnOk({||.T.})

    //oView:SetOwnerView("VIEW_SZS","TELA")

    // Define auto-incremento ao campo
    //oView:AddIncrementField("VIEW_SZZ", "ZZ_ITEM") // incremento
    
    // Define os títulos das subviews
    oView:EnableTitleView("VIEW_SZZ", "Cadastro de partes" )  

Return oView



/*/{Protheus.doc} U_SZSLEG
Função para criar botão com descrição das legendas.
@type user function
@author Diogo Dorneles
@since 06/05/2024
@version 1.0
@return return_var, return_type, return_description
/*/
User Function SZSLEG()

    Local aLegenda := {}
    aAdd(aLegenda,{"BR_AMARELO",  "Espírito Santos"})
    aAdd(aLegenda,{"BR_VERDE",  "Minas Gerais"})
    aAdd(aLegenda,{"BR_AZUL",  "Rio de Janeiro"})
    aAdd(aLegenda,{"BR_VERMELHO",  "São Paulo"})
    aAdd(aLegenda,{"BR_CINZA",  "Estado fora do sudeste"})
    BrwLegenda("Descrição Legendas",, aLegenda) // Título, subtítulo(não funciona), array Legendas

Return

/*/{Protheus.doc} U_fGeraExcel
Função para gerar tabela excel com dados das partes da tabela SZZ e os materiais da tabela SZS.
@type user function
@author Diogo Dorneles
@since 23/05/2024
@version 1.0
@return Arquivo xml
/*/
User Function fGeraExcel()

    Local aArea := GetArea()
    Local cArquivo		:= GetTempPath()+'CADASTRO MATERIAL E PARTE.xml'
    Local oExcel := FWMsExcelEx():New()

    // Cadastro de partes protheus - SZZ
    oExcel:AddworkSheet("Cadastro de partes")
    oExcel:AddTable ("Cadastro de partes","partes cadastradas")
    oExcel:AddColumn("Cadastro de partes","partes cadastradas","Código"         ,2,1)
    oExcel:AddColumn("Cadastro de partes","partes cadastradas","Nome da Parte"  ,2,1)
    oExcel:AddColumn("Cadastro de partes","partes cadastradas","RG"             ,2,2)
    oExcel:AddColumn("Cadastro de partes","partes cadastradas","Idade"          ,2,1)

    DBSelectArea("SZZ")
    DBSetOrder(1) 
    Dbgotop() 
    
    While SZZ->(!eof())                
        DBSelectArea("SZZ")

        oExcel:AddRow("Cadastro de partes","partes cadastradas",{SZZ->ZZ_COD,ZZ_NOME,ZZ_RG,ZZ_IDADE})
        
        DBSkip()
    EndDO

    // Cadastro de material protheus - SZS
    DBSelectArea("SZS")
    DBSetOrder(1) 
    Dbgotop() 

    oExcel:AddworkSheet("Cadastro de material")
    oExcel:AddTable ("Cadastro de material","material cadastrado")
    oExcel:AddColumn("Cadastro de material","material cadastrado","Código"             ,2,1)
    oExcel:AddColumn("Cadastro de material","material cadastrado","Nome do Material"   ,2,1)
    oExcel:AddColumn("Cadastro de material","material cadastrado","Unidade"            ,2,1)
    oExcel:AddColumn("Cadastro de material","material cadastrado","Professor"          ,2,1)

    While SZS->(!eof())                
        DBSelectArea("SZS")

        oExcel:AddRow("Cadastro de material","material cadastrado",{SZS->ZS_COD,ZS_DESCRI,ZS_UNIDAD,ZS_NOMEPRO})
        
        DBSkip()
    EndDO

    MsgInfo("Gerado Arquivo XML","Aviso")

    oExcel:Activate()
    oExcel:GetXMLFile(cArquivo)

    //Abrindo o excel e abrindo o arquivo xml
	oFWMsExcel := MsExcel():New() 			//Abre uma nova conexão com Excel
	oFWMsExcel:WorkBooks:Open(cArquivo) 	//Abre uma planilha
	oFWMsExcel:SetVisible(.T.) 				//Visualiza a planilha
	oFWMsExcel:Destroy()					//Encerra o processo do gerenciador de tarefas

    RestArea(aArea)
Return
