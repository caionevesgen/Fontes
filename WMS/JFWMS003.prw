#INCLUDE "PROTHEUS.CH"
#INCLUDE "TOPCONN.CH"
#INCLUDE "RWMAKE.CH"
#INCLUDE "TBICONN.CH"
#INCLUDE "aarray.CH"
#INCLUDE "json.CH"
#INCLUDE "shash.CH"

/*
?????????????????????????????????????????????????????????????????????????????
?????????????????????????????????????????????????????????????????????????????
?????????????????????????????????????????????????????????????????????????ͻ??
???Programa  ?JFILAWMS  ?Autor  ?Cleuto Lima         ? Data ?  05/16/16   ???
?????????????????????????????????????????????????????????????????????????͹??
???Desc.     ?Processa fila de cancelamento de nota fiscal WMS.           ???
???          ?                                                            ???
?????????????????????????????????????????????????????????????????????????͹??
???Uso       ? GEN.                                                       ???
?????????????????????????????????????????????????????????????????????????ͼ??
?????????????????????????????????????????????????????????????????????????????
?????????????????????????????????????????????????????????????????????????????
*/


User Function JFWMS003()

Local alEmp 		:= {}
Local lEmp			:= Type('cFilAnt') == "C" .AND. Select("SM0") <> 0
Local nAuxEmp		:= 0
Local nX			:= 0
Local nLimite		:= 50  

Conout("JFWMS003 - Iniciando Job - fila de processos WMS - "+Time()+".")

If !lEmp		
	RpcSetType(2)
	lOpenSM0 := RpcSetEnv( "00" , "1022")
	If !lOpenSM0
		ConOut("")
	   	ConOut(Replicate("+",nLimite))
	   	ConOut(Padc("JFWMS003 - Nao foi possivel incializar ambiente confirme a senha/usuario digitado. "+Dtoc(Date())+" "+Time(),nLimite))
	   	ConOut(Replicate("+",nLimite))
	   	ConOut("") 
	   	RpcClearEnv()
		Return Nil
	Else
		Conout("JFWMS003 - Abrindo empresa "+SM0->M0_CODIGO+" '"+AllTrim(SM0->M0_NOMECOM)+"'"+" e filial "+SM0->M0_CODFIL+" '"+AllTrim(SM0->M0_FILIAL)+"' "+DTOC(DDataBase)+" "+Time())		
	EndIf
EndIF   

While !LockByName("JFWMS003",.T.,.T.,.T.)
    nX++
	Sleep(10)
	If nX > 2     
		Conout("JFWMS003 - N?o foi poss?vel executar a fila WMS neste momento pois a fun??o JFWMS003 j? esta sendo executada por outra processamento!"+DTOC(DDataBase)+" "+Time())
		Return .F.
    EndIf
EndDo

ProcFila()

If !lEmp .AND. Type('cFilAnt') == "C"
	Conout("JFWMS003 - Fechando empresa "+SM0->M0_CODIGO+" '"+AllTrim(SM0->M0_NOMECOM)+"'"+" e filial "+SM0->M0_CODFIL+" '"+AllTrim(SM0->M0_FILIAL)+"' "+DTOC(DDataBase)+" "+Time())	
	RpcClearEnv()
EndIF

UnLockByName("JFWMS003",.T.,.T.,.T.)

Conout("JFWMS003 - Finalizando Job - fila de processos WMS - "+Time()+".")

Return nil



/*
?????????????????????????????????????????????????????????????????????????????
?????????????????????????????????????????????????????????????????????????????
?????????????????????????????????????????????????????????????????????????ͻ??
???Programa  ?JFILAWMS  ?Autor  ?Microsiga           ? Data ?  05/16/16   ???
?????????????????????????????????????????????????????????????????????????͹??
???Desc.     ?                                                            ???
???          ?                                                            ???
?????????????????????????????????????????????????????????????????????????͹??
???Uso       ? AP                                                         ???
?????????????????????????????????????????????????????????????????????????ͼ??
?????????????????????????????????????????????????????????????????????????????
?????????????????????????????????????????????????????????????????????????????
*/
Static Function ProcFila()

Local cAliasZZ5 := GetNextAlias()
Local cSqlZZ5 	:= ""
Local cQuebra	:= Chr(13)+Chr(10)
Local nRegProc	:= 0  
Local aPvlNfs	:= {}
Local lCanNfe	:= .F.
Local cMotivo	:= ""

Local _cServ	:= SuperGetmv("GEN_FAT110",.f.,"10.1.0.243")//IP do servidor
Local _nPort	:= SuperGetmv("GEN_FAT111",.f.,1888) //Porta de conex?o do servidor
Local _cAmb		:= SuperGetmv("GEN_FAT112",.f.,"SCHEDULE") //Ambiente do servidor

DbSelectArea("ZZ5")
DbSelectArea("SC5")

// N?o usei RetSqlName na tabela ZZ5000 apenas por quest?o de desempenho
cSqlZZ5 := " SELECT ZZ5.R_E_C_N_O_ ZZ5REC FROM ZZ5000 ZZ5 "+cQuebra
cSqlZZ5 += " WHERE ZZ5_FILIAL IN ( "+cQuebra
cSqlZZ5 += " '1001', "+cQuebra
cSqlZZ5 += " '1012', "+cQuebra
cSqlZZ5 += " '1022', "+cQuebra
cSqlZZ5 += " '2001', "+cQuebra
cSqlZZ5 += " '2012', "+cQuebra
cSqlZZ5 += " '2022', "+cQuebra
cSqlZZ5 += " '3022', "+cQuebra
cSqlZZ5 += " '4012', "+cQuebra
cSqlZZ5 += " '4022', "+cQuebra
cSqlZZ5 += " '6001', "+cQuebra
cSqlZZ5 += " '6022', "+cQuebra
cSqlZZ5 += " '9022' "+cQuebra
cSqlZZ5 += " ) "+cQuebra     
cSqlZZ5 += " AND ZZ5_IDFUNC = '0003' "+cQuebra
cSqlZZ5 += " AND ZZ5_STATUS = '00' "+cQuebra//00=Aguardando processamento;01=Processo finalizad;99=Falha de processamento
cSqlZZ5 += " AND ZZ5.D_E_L_E_T_ <> '*' "+cQuebra
cSqlZZ5 += " ORDER BY ZZ5.R_E_C_N_O_ "+cQuebra
		
DbUseArea(.T.,"TOPCONN",TcGenQry(,,cSqlZZ5),cAliasZZ5,.T.,.T.)

Conout("JFWMS003 - Iniciando processamento da tabela ZZ5 "+Time())

(cAliasZZ5)->(DbGoTop())
While (cAliasZZ5)->(!EOF())

	nRegProc++
	
	ZZ5->(DbGoTo((cAliasZZ5)->ZZ5REC))
    
    IF ZZ5->(!EOF())
    	If SOFTLOCK("ZZ5") 
    	
    		//aaParam	:= FromJson(Alltrim(ZZ5->ZZ5_DADOS))
    	
			Conout("JFWMS003 - Iniciando processamento do registro "+ZZ5->ZZ5_IDFILA+" "+Time())
    	    
    		SC5->(DbSetOrder(1))
    		
    		cChaveSC5	:= ZZ5->ZZ5_FILIAL+ZZ5->ZZ5_PEDIDO
    		If SC5->(DbSeek( cChaveSC5 ))
    		    
    		    If SC5->C5_XROMANE == 0
    		    	RecLock("SC5",.F.)
    		    	SC5->C5_XROMANE	:= ZZ5->ZZ5_ROMANE
    		    	SC5->(MsUnLock())
    		    EndIf
    		    /*
				_cServ	:= "10.3.0.72"			//IP do servidor
				_nPort	:= 1229           		//Porta de conex?o do servidor
				_cAmb	:= "HML_WMS"     //Ambiente do servidor
				*/
				_cEmpCd	:= "00"          		//Empresa de conex?o
				_cEmpFl	:= ZZ5->ZZ5_FILIAL		//Filial de conex?o
				lCorte	:= .F.							
				
				CREATE RPCCONN _oServer ON  SERVER _cServ 			;   //IP do servidor
				PORT  _nPort           								;   //Porta de conex?o do servidor
				ENVIRONMENT _cAmb       							;   //Ambiente do servidor
				EMPRESA _cEmpCd          							;   //Empresa de conex?o
				FILIAL  _cEmpFl          							;   //Filial de conex?o
				TABLES  "SC5,SC6,SA1,SF4,SB1,SE5,SA2,SC9,SF2,SD2"	;   //Tabela que ser?o abertas
				MODULO  "SIGAFAT"               					//M?dulo de conex?o
					
				If ValType(_oServer) == "O"														
					_oServer:CallProc("RPCSetType", 2)					
					lCanNfe	:= _oServer:CallProc("U_JFWMS03B",SC5->(RECNO()),ZZ5->(Recno()),Alltrim(ZZ5->ZZ5_DADOS),@cMotivo)
 
					//?????????????????????????????????????????????????????????????????Ŀ
					//?Realizando a nova conex?o para entrar na empresa e filial correta?
					//???????????????????????????????????????????????????????????????????
					//Fecha a Conexao com o Servidor
					RESET ENVIRONMENT IN SERVER _oServer
					CLOSE RPCCONN _oServer
					_oServer := Nil
				EndIf    			
    		    
    			If lCanNfe

    		    	RecLock("SC5",.F.)
    		    	SC5->C5_XROMANE	:= 0
    		    	SC5->(MsUnLock())
	    			  
		    		RecLock("ZZ5",.F.)
		    		ZZ5->ZZ5_QTDPRC	:= ZZ5->ZZ5_QTDPRC+1               
		    		ZZ5->ZZ5_STATUS	:= "01"
		    		ZZ5->ZZ5_DTUPDA	:= DDATABASE
		    		ZZ5->ZZ5_HRUPDA	:= Time()
		    		ZZ5->ZZ5_MSG	:= "Nota Cancelada com sucesso no Protheus!"
		    		ZZ5->(MsUnLock())
		    	Else
		    		RecLock("ZZ5",.F.)
		    		ZZ5->ZZ5_QTDPRC	:= ZZ5->ZZ5_QTDPRC+1
		    		ZZ5->(MsUnLock())		    		
    			EndIF
    		
    		Else 
	    		RecLock("ZZ5",.F.)
	    		ZZ5->ZZ5_QTDPRC	:= ZZ5->ZZ5_QTDPRC+1
	    		ZZ5->(MsUnLock())
    			Conout("JFWMS003 - Pedido n?o localizado na base "+ZZ5->ZZ5_IDFILA+" "+Time())
    		EndIF
    	       	
    	Else
    		Conout("JFWMS003 - N?o foi poss?vel obter acesso exclusivo ao registro "+ZZ5->ZZ5_IDFILA+" "+Time())		
    	EndIF
    Else
    	Conout("JFWMS003 - Falha ao posicionar registro na tabela ZZ5 "+" "+Time())		
    EndIf

	(cAliasZZ5)->(DbSkip())
EndDo


(cAliasZZ5)->(DbCloseArea())

Return nil  

/*
?????????????????????????????????????????????????????????????????????????????
?????????????????????????????????????????????????????????????????????????????
?????????????????????????????????????????????????????????????????????????ͻ??
???Programa  ?JFILAWMS  ?Autor  ?Microsiga           ? Data ?  05/17/16   ???
?????????????????????????????????????????????????????????????????????????͹??
???Desc.     ?                                                            ???
???          ?                                                            ???
?????????????????????????????????????????????????????????????????????????͹??
???Uso       ? AP                                                         ???
?????????????????????????????????????????????????????????????????????????ͼ??
?????????????????????????????????????????????????????????????????????????????
?????????????????????????????????????????????????????????????????????????????
*/


User Function JFWMS03B(cRecSC5,nRecZZ5,cParam,cMotivo) 

Local lRet	:= .F.
Local nOpCanc	:= 0
Local aRegSD2	:= {}
Local aRegSE1	:= {}
Local aRegSE2	:= {}  
Local lContinua	:= .F.
Local cFilPed	:= ""
Local cPedido	:= ""

DbSelectArea("SF2")
SF2->(DbSetOrder(1))

SC5->(DbGoTo(cRecSC5))

cFilPed	:= SC5->C5_FILIAL
cPedido	:= SC5->C5_NUM

If Empty(SC5->C5_NOTA)
	lContinua	:= .T.
ElseIf SF2->(DbSeek( SC5->C5_FILIAL+SC5->C5_NOTA+SC5->C5_SERIE ))
	cCliente 	:= SF2->F2_CLIENTE
	cLojaCli 	:= SF2->F2_LOJA 
	cNf			:= SF2->F2_DOC
	cSerie		:= SF2->F2_SERIE 
	dEmissao	:= SF2->F2_EMISSAO		
	lMsErroAuto	:= .F.
	
	IF MaCanDelF2("SF2",SF2->(Recno()),@aRegSD2,@aRegSE1,@aRegSE2) .And. MA521VerSC6(SF2->F2_FILIAL,SF2->F2_DOC,SF2->F2_SERIE,SF2->F2_CLIENTE,SF2->F2_LOJA)
	
		//?????????????????????????????????????????????????????????????????????Ŀ
		//? Exclui documento fiscal                                             ?
		//??????????????????????????????????????????????????????????????????????? 
		MaDelNFS(aRegSD2,aRegSE1,aRegSE2,.F.,.F.,.F.,.F.)
		If !lMsErroAuto
			lContinua	:= .T.
		EndIf	
			
	Else
		cMotivo	:= "Exclus?o n?o pode ser executada!"
		lRet	:= .F.	
	EndIf
EndIf

If lContinua
	
	cMotivo	:= "Exclus?o n?o pode ser executada!"
	lRet	:= .T.
	
	_cAliSC9:= GetNextAlias()			
	//Verifica se o pedido ficou bloqueado
	_cQuery := " SELECT C9_FILIAL "
	_cQuery += " ,C9_PEDIDO "
	_cQuery += " ,C9_BLCRED "
	_cQuery += " ,R_E_C_N_O_ SC9RECNO "
	_cQuery += " FROM "+RetSqlName("SC9")+" SC9 "
	_cQuery += " WHERE SC9.C9_FILIAL = '"+SC5->C5_FILIAL+"' "
	_cQuery += " AND SC9.C9_PEDIDO = '"+SC5->C5_NUM+"' "
	//_cQuery += " AND (SC9.C9_BLEST NOT IN('  ','10') "
	//_cQuery += " OR SC9.C9_BLCRED NOT IN('  ','09','10') )"
	_cQuery += " AND SC9.D_E_L_E_T_ = ' ' "
	DbUseArea(.T.,"TOPCONN",TcGenQry(,,_cQuery),_cAliSC9,.T.,.T.)
	(_cAliSC9)->(DbGoTop())
	
	If (_cAliSC9)->(Eof())

		SC6->(DbSetOrder(1)) 
		SC6->(DbSeek(cFilPed+cPedido))
		While SC6->(!EOF()) .AND. SC6->C6_FILIAL+SC6->C6_NUM == SC5->C5_FILIAL+SC5->C5_NUM
		
			nQtdLibToFat	:= 0
			nQtdLibToFat	:= MaLibDoFat(SC6->(Recno()),SC6->C6_QTDVEN)
			
			RecLock("SC6",.F.)
			SC6->C6_QTDLIB	:= nQtdLibToFat
			SC6->C6_BLOQUEI	:= " "
			SC6->(msUnlock())
		
			SC6->(DbSkip())
			
		EndDo
                
		(_cAliSC9)->(DbCloseArea())				
		DbUseArea(.T.,"TOPCONN",TcGenQry(,,_cQuery),_cAliSC9,.T.,.T.)
		(_cAliSC9)->(DbGoTop())
		
	EndIf
	
	//Percorre todos itens bloqueados no pedido
	While !(_cAliSC9)->(Eof())
		
		//Posiciona a SC9
		SC9->(DbGoTo((_cAliSC9)->SC9RECNO))
		IF 	SC9->(Recno()) == (_cAliSC9)->SC9RECNO
			
			If !Empty(SC9->C9_BLCRED) .AND. SC9->C9_BLCRED <> "09" .AND. SC9->C9_BLCRED <> "10"
				
				//??????????????????????????????????????????????????????????????????????????????
				//???          ?Rotina de atualizacao da liberacao de credito                ???
				//??????????????????????????????????????????????????????????????????????????Ĵ??
				//???Parametros?ExpN1: 1 - Liberacao                                         ???
				//???          ?       2 - Rejeicao                                          ???
				//???          ?ExpL2: Indica uma Liberacao de Credito                       ???
				//???          ?ExpL3: Indica uma liberacao de Estoque                       ???
				//???          ?ExpL4: Indica se exibira o help da liberacao                 ???
				//???          ?ExpA5: Saldo dos lotes a liberar                             ???
				//???          ?ExpA6: Forca analise da liberacao de estoque                 ???
				//??????????????????????????????????????????????????????????????????????????Ĵ??
				//???Descri??o ?Esta rotina realiza a atualizacao da liberacao de pedido de   ???
				//???          ?venda com base na tabela SC9.                                ???
				//??????????????????????????????????????????????????????????????????????????????
				
				a450Grava(1,.T.,.F.,.F.)
				//a450Grava(1,.T.,.T.,.F.) apenas libera??o de credito
			EndIF
				
		EndIf
		
		(_cAliSC9)->(DbSkip())
	EndDo			

Else
	cMotivo	:= "Exclus?o n?o pode ser executada!"
	lRet	:= .F.				
EndIF	

SC5->(DbGoTo(cRecSC5))
If lRet
	RecLock("SC5",.F.)
	SC5->C5_XROMANE	:= 0
	MsUnLock() 	
EndIf		

Return lRet
  
