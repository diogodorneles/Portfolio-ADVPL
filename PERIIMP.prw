#INCLUDE "protheus.ch"
#INCLUDE "topconn.ch"
#INCLUDE "rwmake.ch"
#INCLUDE 'tbiconn.ch'
#INCLUDE "TOTVS.CH"

#define CRLF Chr(13)+Chr(10)

    /* 
    ARQUIVO PARA DEMONSTRAÇÃO NO PORTFOLIO
    Dados sensiveis, acessos, nome de funcoes e variaveis originais foram alterados por questao de seguranca.
    Demonstracao apenas para analise por um especialista, nao funcional sem os dados completos.
    DEMONSTRACAO DE IMPORTACAO VIA ARQUIVO CSV E GRAVACAO EM TABELA.
    */

/*=============================================================================================
*Fonte:	 	PERIIMP()
*Autor:  	Diogo Dorneles
*Data:   	09/01/2025
*Descricao: Importar e ler arquivo CSV para preencher tabela de Periferico.
*Rotina:	CTB - Miscelanea - Especificos - Periferico - Outras Açoes
=============================================================================================*/
user function PERIIMP()
	Local _cArq := ""
	Local cTipo := ""
	Local aArea 	:= GetArea()

	If MsgYesNo("Tem certeza que deseja importar a Tabela de Periferico ?","Atenção")
	ELSE
		RETURN
	ENDIF

	cTipo :=         "Texto (*.CSV)          | *.CSV | "
	cTipo := cTipo + "Todos os Arquivos  (*.*) |   *.*   |"

	_cArq := cGetFile(cTipo,"Dialogo de Selecao de Arquivos",,,.T.)
	Processa({||fimpcsv(_cArq)}, "Aguarde...","Importando arquivos")

	RestArea(aArea)
return


/*=============================================================================================
*Fonte:	 	fimpcsv(cArq)
*Autor:  	Diogo Dorneles
*Data:   	09/01/2025
*Descricao: Realiza a importacao e leitura do CSV e grava o Periferico na tabela ZZO.
*Parâmetro: cArq, String, Arquivo
=============================================================================================*/
Static Function fimpcsv(cArq)
	Local aTemp 	:= {}
	Local aCab 		:= {}
	
	Local nPosCONTA    := 0
	Local nPosDESCRI   := 0
	Local nPosDEPARA   := 0
	Local nPosDEPASI   := 0
	Local nPosPACOTE   := 0
	Local nPosTIPO     := 0
	Local nPosCCDESC   := 0
	Local nPosCODCC    := 0
	Local nPosCCSINT   := 0
	Local nPosRESPON   := 0
	Local nPosJAN      := 0
	Local nPosFEV      := 0
	Local nPosMAR      := 0
	Local nPosABR      := 0
	Local nPosMAI      := 0
	Local nPosJUN      := 0
	Local nPosJUL      := 0
	Local nPosAGO      := 0
	Local nPosSET      := 0
	Local nPosOUT      := 0
	Local nPosNOV      := 0
	Local nPosDEZ      := 0
	Local nPosTOTAL    := 0
	Local nPosOBS      := 0
	Local nPosFORNEC   := 0

	Local cBuff 	:= ''
	Local nReg 		:= 0
	Local nX		:= 0
	Local nImp		:= 0
	Local cExist	:= ""
	Local cVazio	:= ""
	Local aFora		:= {}
	Local cFora		:= ""
	Local nCRLF		:= 0
	Local nCod		:= 0

	Local aPergs	:= {}
	Local aRet		:= {}
	Local cAno		:= "    "
	Local cAno2		:= ""
	Local cQuery	:= ""
	Local cCod		:= ""

	Local dData     := SuperGetMV("MV_DATAPER", .F., "")
    Local cAnoBloq  := SubStr(DtoS(dData),1,4)

	aadd(aPergs, {1, "Ano",  cAno,  "", ".T.", "", ".T.", 40,  .F.})

	If Parambox(aPergs, "Informe o Ano do Periferico", aRet)
		cAno  := aRet[1]
		cAno2 := SubStr(cAno,3,2)
	Else
		Alert("Operação Cancelada")
		Return
	Endif

	IF cAno <= cAnoBloq .And. IsNumeric(cAno) .And. !Empty(dData) .And. !Empty(cAno)
        fwAlertWarning('Ano de Periferico bloqueado para Importação.','Atenção')
        return
	Elseif Empty(cAno) .or. cAno >= '2090' .or. !IsNumeric(cAno)
		fwAlertWarning('Ano de Periferico inválido ou vazio.','Atenção')
        return 
	EndIF

	cPathEst:= "C:\temp"
	//Caso não exista o diretorio na estacao cria ele aqui.
	If !File(cPathEst)
		MAKEDIR(cPathEst)
	EndIf


	If File(cArq)
		ft_fuse(cArq)
	Else
		ApMsgAlert("Arquivo "+AllTrim(cArq)+" não foi encontrado.")
		Return
	Endif

	ProcRegua(FT_FLastRec()-1)
		
	// Percorre as linhas do arquivo e armazena a primeira linha(cabeçalho) em um array e os dados em outro array.
	do While !ft_feof()
		incproc("Processando registro... "+alltrim(str(nReg)))
		cBuff  := ft_freadln()+';'
		IF nReg < 1													
			aCab := StrTokArr2(cBuff,";",.T.)	
			If AllTrim(aCab[1]) != "CONTA"		// Verifica quando é a linha do cabecalho.
				nCod++
				if nCod > 2
					ApMsgAlert("Primeira coluna de Conta não foi encontrada.")
					Return
				Endif
				ft_fskip()
				Loop
			EndIF
			nReg++			
			ft_fskip()
			Loop
		Endif	
		aadd(aTemp,StrTokArr2(cBuff,";",.T.))
		nReg++		
		ft_fskip()
	enddo

	// Pega as posições dos cabeçalhos com base na ordem do array/planiha. Verifica se encontrou, se não, adiciona no array não encontrado(aFora).
	if !Empty(aCab)					
		Iif((nPosCONTA 	:= Ascan(aCab, {|x| At(''+/* // Ocultado nessa Copia */'', Upper(x)) > 0})  ) = 0 , aadd(aFora, ''+/* // Ocultado nessa Copia */''),"")
		Iif((nPosDESCRI	:= Ascan(aCab, {|x| At(''+/* // Ocultado nessa Copia */'', Upper(x)) > 0})  ) = 0 , aadd(aFora, ''+/* // Ocultado nessa Copia */''),"")
		Iif((nPosDEPARA	:= Ascan(aCab, {|x| At(''+/* // Ocultado nessa Copia */'', Upper(x)) > 0})  ) = 0 , aadd(aFora, ''+/* // Ocultado nessa Copia */''),"")
		Iif((nPosDEPASI	:= Ascan(aCab, {|x| At(''+/* // Ocultado nessa Copia */'', Upper(x)) > 0})  ) = 0 , aadd(aFora, ''+/* // Ocultado nessa Copia */''),"")
		Iif((nPosPACOTE	:= Ascan(aCab, {|x| At(''+/* // Ocultado nessa Copia */'', Upper(x)) > 0})  ) = 0 , aadd(aFora, ''+/* // Ocultado nessa Copia */''),"")
		Iif((nPosTIPO 	:= Ascan(aCab, {|x| At(''+/* // Ocultado nessa Copia */'', Upper(x)) > 0})  ) = 0 , aadd(aFora, ''+/* // Ocultado nessa Copia */''),"")
		Iif((nPosCCDESC	:= Ascan(aCab, {|x| At(''+/* // Ocultado nessa Copia */'', Upper(x)) > 0})  ) = 0 , aadd(aFora, ''+/* // Ocultado nessa Copia */''),"")
		Iif((nPosCODCC 	:= Ascan(aCab, {|x| At(''+/* // Ocultado nessa Copia */'', Upper(x)) > 0})  ) = 0 , aadd(aFora, ''+/* // Ocultado nessa Copia */''),"")
		Iif((nPosCCSINT	:= Ascan(aCab, {|x| At(''+/* // Ocultado nessa Copia */'', Upper(x)) > 0})  ) = 0 , aadd(aFora, ''+/* // Ocultado nessa Copia */''),"")
		Iif((nPosRESPON	:= Ascan(aCab, {|x| At(''+/* // Ocultado nessa Copia */'', Upper(x)) > 0})  ) = 0 , aadd(aFora, ''+/* // Ocultado nessa Copia */''),"")
		Iif((nPosJAN 	:= Ascan(aCab, {|x| At('JAN-'+cAno2		, Upper(x)) > 0 .or. At('JAN/'+cAno2 , Upper(x)) > 0})  ) = 0 , aadd(aFora, 'JAN-'+cAno2+' ou JAN/'+cAno2  ),"")
		Iif((nPosFEV 	:= Ascan(aCab, {|x| At('FEV-'+cAno2		, Upper(x)) > 0 .or. At('FEV/'+cAno2 , Upper(x)) > 0})  ) = 0 , aadd(aFora, 'FEV-'+cAno2+' ou FEV/'+cAno2  ),"")
		Iif((nPosMAR 	:= Ascan(aCab, {|x| At('MAR-'+cAno2		, Upper(x)) > 0 .or. At('MAR/'+cAno2 , Upper(x)) > 0})  ) = 0 , aadd(aFora, 'MAR-'+cAno2+' ou MAR/'+cAno2  ),"")
		Iif((nPosABR 	:= Ascan(aCab, {|x| At('ABR-'+cAno2		, Upper(x)) > 0 .or. At('ABR/'+cAno2 , Upper(x)) > 0})  ) = 0 , aadd(aFora, 'ABR-'+cAno2+' ou ABR/'+cAno2  ),"")
		Iif((nPosMAI 	:= Ascan(aCab, {|x| At('MAI-'+cAno2		, Upper(x)) > 0 .or. At('MAI/'+cAno2 , Upper(x)) > 0})  ) = 0 , aadd(aFora, 'MAI-'+cAno2+' ou MAI/'+cAno2  ),"")
		Iif((nPosJUN 	:= Ascan(aCab, {|x| At('JUN-'+cAno2		, Upper(x)) > 0 .or. At('JUN/'+cAno2 , Upper(x)) > 0})  ) = 0 , aadd(aFora, 'JUN-'+cAno2+' ou JUN/'+cAno2  ),"")
		Iif((nPosJUL 	:= Ascan(aCab, {|x| At('JUL-'+cAno2		, Upper(x)) > 0 .or. At('JUL/'+cAno2 , Upper(x)) > 0})  ) = 0 , aadd(aFora, 'JUL-'+cAno2+' ou JUL/'+cAno2  ),"")
		Iif((nPosAGO 	:= Ascan(aCab, {|x| At('AGO-'+cAno2		, Upper(x)) > 0 .or. At('AGO/'+cAno2 , Upper(x)) > 0})  ) = 0 , aadd(aFora, 'AGO-'+cAno2+' ou AGO/'+cAno2  ),"")
		Iif((nPosSET 	:= Ascan(aCab, {|x| At('SET-'+cAno2		, Upper(x)) > 0 .or. At('SET/'+cAno2 , Upper(x)) > 0})  ) = 0 , aadd(aFora, 'SET-'+cAno2+' ou SET/'+cAno2  ),"")
		Iif((nPosOUT 	:= Ascan(aCab, {|x| At('OUT-'+cAno2		, Upper(x)) > 0 .or. At('OUT/'+cAno2 , Upper(x)) > 0})  ) = 0 , aadd(aFora, 'OUT-'+cAno2+' ou OUT/'+cAno2  ),"")
		Iif((nPosNOV 	:= Ascan(aCab, {|x| At('NOV-'+cAno2		, Upper(x)) > 0 .or. At('NOV/'+cAno2 , Upper(x)) > 0})  ) = 0 , aadd(aFora, 'NOV-'+cAno2+' ou NOV/'+cAno2  ),"")
		Iif((nPosDEZ 	:= Ascan(aCab, {|x| At('DEZ-'+cAno2		, Upper(x)) > 0 .or. At('DEZ/'+cAno2 , Upper(x)) > 0})  ) = 0 , aadd(aFora, 'DEZ-'+cAno2+' ou DEZ/'+cAno2  ),"")
		Iif((nPosTOTAL	:= Ascan(aCab, {|x| At('TOTAL-'+cAno2	, Upper(x)) > 0 .or. At('TOTAL/'+cAno2, Upper(x)) > 0})  ) = 0 , aadd(aFora, 'TOTAL-'+cAno2 ),"")
		Iif((nPosOBS 	:= Ascan(aCab, {|x| At('OBS'			, Upper(x)) > 0 .or. At('OBS'		 , Upper(x)) > 0})  ) = 0 , aadd(aFora, 'OBS'	  ),"")		
		Iif((nPosFORNEC	:= Ascan(aCab, {|x| At('FORNECEDOR'		, Upper(x)) > 0 .or. At('FORNECEDOR' , Upper(x)) > 0})  ) = 0 , aadd(aFora, 'FORNECEDOR' ),"")
	endif

	if(len(aTemp) > 0)
		
		// Deletando Perifericos do mesmo ano para serem substituídos.
		cQuery := " UPDATE "+RetSqlName("ZZO")+" SET D_E_L_E_T_ = '*', R_E_C_D_E_L_ = R_E_C_N_O_ " 
		cQuery += " WHERE ZZO_ANO = '"+cAno+"' AND D_E_L_E_T_ = '' AND ZZO_COD != '000000'; "
		If TcSqlExec(cQuery) < 0
			cErro := TCSqlError()
			MsgAlert("Falha na exclusão do Periferico: " + cErro)
			// lRet := .F.
			Return
		EndIf

		ProcRegua(len(aTemp))
		
		for nX:= 1 to len(aTemp)
					
			incproc("Importando... Periferico Linha: "+alltrim(Str(nX)))			

			cCod := U_FSOMAUM() // Funcao customizada para pegar proximo numero

			DbSelectArea("ZZO")
			DbSetOrder(1)
			// Verificar se já existe, nesse caso armazena na variável.
			If Dbseek(Space(TamSx3("ZZO_FILIAL")[01])+cCod)
				If cExist = ''
					cExist := cCod
				Else
				
					cExist += ","+cCod
				endif

				nCRLF++
				If nCRLF = 8
					cExist += CRLF
					nCRLF := 0
				Endif
				Loop
			Else	//Realiza gravacao na tabela "ZZO"
				If !Empty(aTemp[nX]) .And. !Empty(cCod) .And. !Empty(aTemp[nX][nPosCONTA])
					Begin Transaction
						RecLock("ZZO",.T.) 
							ZZO->ZZO_COD 	:= cCod					
							Iif( nPosCONTA 	!= 0, ZZO->ZZO_CONTA    := Alltrim(aTemp[nX][nPosCONTA	]), "")
							Iif( nPosDESCRI != 0, ZZO->ZZO_DESCRI   := Alltrim(aTemp[nX][nPosDESCRI	]), "")
							Iif( nPosDEPARA != 0, ZZO->ZZO_DEPARA   := Alltrim(aTemp[nX][nPosDEPARA	]), "")
							Iif( nPosDEPASI != 0, ZZO->ZZO_DEPASI   := Alltrim(aTemp[nX][nPosDEPASI	]), "")
							Iif( nPosPACOTE != 0, ZZO->ZZO_PACOTE   := Alltrim(aTemp[nX][nPosPACOTE	]), "")
							Iif( nPosTIPO 	!= 0, ZZO->ZZO_TIPO     := Alltrim(aTemp[nX][nPosTIPO	]), "")
							Iif( nPosCCDESC != 0, ZZO->ZZO_CCDESC   := Alltrim(aTemp[nX][nPosCCDESC	]), "")
							Iif( nPosCODCC 	!= 0, ZZO->ZZO_CODCC    := Alltrim(aTemp[nX][nPosCODCC	]), "")
							Iif( nPosCCSINT != 0, ZZO->ZZO_CCSINT   := Alltrim(aTemp[nX][nPosCCSINT	]), "")
							Iif( nPosRESPON != 0, ZZO->ZZO_RESPON   := Alltrim(aTemp[nX][nPosRESPON	]), "")
							ZZO->ZZO_ANO    := cAno		
							Iif( nPosJAN 	!= 0, ZZO->ZZO_JAN      := val(fTiraPonto(alltrim(aTemp[nX][nPosJAN	]))), "")
							Iif( nPosFEV 	!= 0, ZZO->ZZO_FEV      := val(fTiraPonto(alltrim(aTemp[nX][nPosFEV	]))), "")
							Iif( nPosMAR 	!= 0, ZZO->ZZO_MAR      := val(fTiraPonto(alltrim(aTemp[nX][nPosMAR	]))), "")
							Iif( nPosABR 	!= 0, ZZO->ZZO_ABR      := val(fTiraPonto(alltrim(aTemp[nX][nPosABR	]))), "")
							Iif( nPosMAI 	!= 0, ZZO->ZZO_MAI      := val(fTiraPonto(alltrim(aTemp[nX][nPosMAI	]))), "")
							Iif( nPosJUN 	!= 0, ZZO->ZZO_JUN      := val(fTiraPonto(alltrim(aTemp[nX][nPosJUN	]))), "")
							Iif( nPosJUL 	!= 0, ZZO->ZZO_JUL      := val(fTiraPonto(alltrim(aTemp[nX][nPosJUL	]))), "")
							Iif( nPosAGO 	!= 0, ZZO->ZZO_AGO      := val(fTiraPonto(alltrim(aTemp[nX][nPosAGO	]))), "")
							Iif( nPosSET 	!= 0, ZZO->ZZO_SET      := val(fTiraPonto(alltrim(aTemp[nX][nPosSET	]))), "")
							Iif( nPosOUT 	!= 0, ZZO->ZZO_OUT      := val(fTiraPonto(alltrim(aTemp[nX][nPosOUT	]))), "")
							Iif( nPosNOV 	!= 0, ZZO->ZZO_NOV      := val(fTiraPonto(alltrim(aTemp[nX][nPosNOV	]))), "")
							Iif( nPosDEZ 	!= 0, ZZO->ZZO_DEZ      := val(fTiraPonto(alltrim(aTemp[nX][nPosDEZ	]))), "")
							Iif( nPosTOTAL	!= 0, ZZO->ZZO_TOTAL    := val(fTiraPonto(alltrim(aTemp[nX][nPosTOTAL ]))), "")
							Iif( nPosOBS 	!= 0, ZZO->ZZO_OBS      := alltrim(aTemp[nX][nPosOBS]), 	"")
							Iif( nPosFORNEC != 0, ZZO->ZZO_FORNEC   := StrZero(Val(Alltrim(aTemp[nX][nPosFORNEC	])),6), "") // NOVO
						ZZO->(MsUnLock())
						nImp++
					End Transaction
				// Armazena linhas que estão com campo obrigatório vazio.
				Elseif !Empty(cCod)
					If cVazio = ''
						cVazio := Str(nX)
					Else
						cVazio += ","+Str(nX)
					endif
				Endif
			Endif
		Next								
	Endif

	if nImp > 0
		msginfo(Alltrim(Str(nImp))+ " Perifericos "+ "de "+Alltrim(Str(Len(aTemp)))+ " importados com sucesso.")
	else
		msginfo("Nenhuma importação realizada.")
	endif

	
	If !Empty(cExist)
		MsgInfo("Perifericos já existentes não foram importados.")
		// msginfo("Perifericos já existentes não importados: "+CRLF+CRLF+Alltrim(cExist))
	Endif
	If !Empty(cVazio)
		msginfo("Perifericos não importados devido a Conta ou Campos Obrigatorios Vazios. "+CRLF+"Ordem do Periferico:"+cVazio)
	Endif
	
	// Exibe nome das colunas não encontradas.
	If !Empty(aFora)		
		For nX := 1 To Len(aFora) 	
			cFora += aFora[nX] 		
			
			If nX < Len(aFora) 
				cFora += ", " 
			EndIf 
		Next nX

		msginfo("Colunas não encontradas na Planilha: "+cFora)
	Endif
	
return      

// Corrige pontuação de casa decimal
// *Parametro: cString1, String, Valor
Static function fTiraPonto(cString1)
Local cString := ""
Local nX       := 0

For nX:= 1 to Len(cString1)
	a:= SubStr(cString1,nX,1)
	if(a = ".")
		loop
	else
		if(a = ",")
			cString += "."
		else
			cString += a
		endif
	endif
Next
return(cString)  
