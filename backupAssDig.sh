# ******************************************************************************
#   Shell Script (usando Cygwin) de automa��o do processo de backup dos arquivos de  
#   assinatura digital da Prefeitura de Patroc�nio
#
#   Data modificacao: 05/08/2015
#	Criado por Diego Santana
#	
# ******************************************************************************

# Seta vari�vel de ambiente
PATH="/cygdrive/c/Windows/System32:cygdrive/c/Program Files/WinRAR:/bin:/usr/bin:/usr/sbin:."

# Seta a vari�vel Bash
BASH="/usr/bin/bash"

# Diret�rio local
# /cygdrive/c - corresponde a C:

#Diret�rio de arquivos compactados
DIR_BASE_LOCAL_BACKUP="/cygdrive/c/Arquivos_Compactados"

#Diret�rio das assinaturas
DIR_ASSINATURA="/cygdrive/c/Dir_Assinatura"

# Diret�rio relativo dos arquivo de Log de sa�da do script
DIR_ARQ_LOG_SCRIPT="./"

# Nome arquivo de log
ARQ_LOG_SCRIPT="BackupAssinatura.log"

#######################################################################


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

function seta_usuario_permissao() {
	
	if icacls $1 \/grant Todos:\(RX\) /Q > /dev/null
		then
			log "NL" "Usuario e permissoes foram setadas com sucesso no diret�rio {$1}"
			return 0
		else
			log "NL" "Erro, nao foi possivel setar usuario e/ou permissoes,"
			log "NL" "o \"icacl.exe\" retornou o codigo de erro: ${?}"
			return 1
		fi
	}

function criaDiretorio(){

DIRETORIO=$1

	if ! cd "${DIR_ASSINATURA}"; then
		
			echo -e "impossivel acessar diretorio"
			exit 1
	else
			if [ -d "${DIRETORIO}" ]; then 
			
						echo -e "Diretorio ja existe..\n"
							log "NL" "Diretorio acessado as $(date +%H:%M:%S)"
						# rotina a ser escrita...
						
						exit 0
				else 
						 echo -e "Diretorio ser� criado...\n"
						  
						 mkdir "${DIRETORIO}" > /dev/null
							seta_usuario_permissao "${DIRETORIO}"
						 exit 0
			fi
	fi
}

criaDiretorio Rafael

