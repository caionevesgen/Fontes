#INCLUDE "Protheus.Ch"

/*
?????????????????????????????????????????????????????????????????????????????
?????????????????????????????????????????????????????????????????????????????
?????????????????????????????????????????????????????????????????????????ͻ??
???Programa  ?A410CONS  ?Autor  ?Microsiga           ? Data ?  08/12/15   ???
?????????????????????????????????????????????????????????????????????????͹??
???Desc.     ?                                                            ???
???          ?                                                            ???
?????????????????????????????????????????????????????????????????????????͹??
???Uso       ? AP                                                         ???
?????????????????????????????????????????????????????????????????????????ͼ??
?????????????????????????????????????????????????????????????????????????????
?????????????????????????????????????????????????????????????????????????????
*/


User Function A410Cons() 
         
Local aButtons := {}

AADD(aButtons, {"DOWN",	{|| U_GENA028(.F.)}, "Importar"})

Return(aButtons)       