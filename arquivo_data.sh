
# ******************************************************************************
#   Shell Script (usando Cygwin) de automação do processo de backup dos arquivos de  
#   assinatura digital da Prefeitura de Patrocínio
#
#   Data modificacao: 05/08/2015
#	
# ******************************************************************************


CAMINHO="C:\Users\Diego\Desktop\Desenvolvimento\Script em Shell\arquivos"

function listaArquivos(){

	for i in "${CAMINHO}"\/* 
		do
			dia_mes=`date -r "${i}" | tr " " ":" | cut --delimiter=":" --fields="2"`
			mes_do_ano=`date -r "${i}" | tr " " ":" | cut --delimiter=":" --fields="4"`
			
			   echo $mes_do_ano
			   echo $dia_mes
			   
	
		done


}


listaArquivos