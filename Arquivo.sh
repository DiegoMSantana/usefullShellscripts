#
# ******************************************************************************
#   Shell Script (usando Cygwin) de automação do processo de exclusão de arquivo do dovecot.
#
#   Data modificacao: 09/02/2016
#	Criado por Diego Santana
#	
# ******************************************************************************
#

# Seta variável de ambiente
PATH="/cygdrive/c/Program Files/WinRAR:/bin:/usr/bin:/usr/sbin:." 

# Seta a variável Bash
BASH="/usr/bin/bash"

# Diretório local
# /cygdrive/c - corresponde a C:

#Diretório que contém os domínios virtuais
DIR_BASE_DOMINIOS="/cygdrive/c/dominios/"

#Arquivo a ser apagado
ARQUIVO_DEL="dovecot.log.txt"

# Diretório relativo dos arquivo de Log de saída do script
DIR_ARQ_LOG_SCRIPT="./"

# Nome arquivo de log
ARQ_LOG_SCRIPT="remocao.log"

##############################################################################################

#
# Essa função realiza o log de todos os arquivo que forem deletados ( opcional ) 
# Comentar na função principal se não quiser utilizar.
#

function log() {
    if [ ${1} = "NL" ] # NL = nova linha
        then
            echo -e "\r\n${2}" | tee -a "${DIR_ARQ_LOG_SCRIPT}"/"${ARQ_LOG_SCRIPT}"
        else
            if [ ${1} = "ML" ] # ML = mesma linha
                then
                echo -e "${2}" | tee -a "${DIR_ARQ_LOG_SCRIPT}"/"${ARQ_LOG_SCRIPT}"
                fi
        fi
    }

#
# Função responsável pela remoção e escrita em log dos arquivos removidos, uma vez modificado o caminho
# do diretório de dominios virtuais será necessário ajustar o comando cut. 
#

function apagaArquivodeLog(){

		for file in `find "${DIR_BASE_DOMINIOS}" -type f -iname "${ARQUIVO_DEL}" -print`
		  do
		  		  DOMINIO=`dirname "${file}" | cut --delimiter="/" --fields=5` >> /dev/null
		  		  USUARIO=`dirname "${file}" | cut --delimiter="/" --fields=6` >> /dev/null

		  		  log "ML" "Arquivo removido na conta do usuario ${USUARIO}"@"${DOMINIO} - `date`" >> /dev/null

		          rm -f basename "${file}"
                  #basename "${file} - ${USUARIO}"@"${DOMINIO}"
		         
		  done

}

#Executa aplicação
apagaArquivodeLog