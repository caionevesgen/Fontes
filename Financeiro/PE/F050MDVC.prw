
/*
������������������������������������������������������������������������������
������������������������������������������������������������������������������
�������������������������������������������������������������������������ͻ��
���Programa  �F050MDVC  �Autor  �Microsiga           � Data �  10/06/2021 ���
�������������������������������������������������������������������������͹��
���Desc.     �ponto de entrada da rotina fina050 para c�lculo de venc     ���
���          �de t�tulos de IR CODRET 0422                                ���
�������������������������������������������������������������������������͹��
���Uso       � Gen                                                        ���
�������������������������������������������������������������������������ͼ��
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
*/

#INCLUDE "RWMAKE.CH"
#INCLUDE "PROTHEUS.CH"

USER FUNCTION F050MDVC
Local dRetData := ParamIXB[1]
Local cImposto := ParamIXB[2]
Local dEmissao := ParamIXB[3]
Local dEmis1   := ParamIXB[4]
Local dVencRea := ParamIXB[5]  

    
    IF ALLTRIM(cImposto) == "IRRF" .AND. SE2->E2_CODRET == "0422"
        dRetData := dVencRea
    ENDIF   

RETURN dRetData
