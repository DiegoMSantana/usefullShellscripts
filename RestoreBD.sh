
# Seta variável de ambiente
PATH="/cygdrive/c/Windows/System32:/usr/gnu/bin:/usr/local/bin:/bin:/cygdrive/c/Program Files/WinRAR:/cygdrive/c/Program Files (x86)/Firebird/Firebird_2_5/bin:."

# Seta a variável Bash
BASH="/usr/bin/bash"

# Diretório local
# /cygdrive/c - corresponde a C:
# /cygdrive/d - corresponde a D:
DIR_BASE_LOCAL="/cygdrive/d/Restore_BD/AutomacaoRestoreBD"

# Diretório relativo dos arquivos RAR
DIR_ARQ_BANCO_COMPACTADO="../Entrada_Arquivos_Rar/"

# Diretório relativo dos arquivos temporarios
DIR_ARQ_REJEITADOS="../Arquivos_Rejeitados/"

# Diretório relativo dos arquivo de Log de saída do script
DIR_ARQ_LOG_SCRIPT="./"

# Extensão dos arquivos rar 
EXTENSAO_ARQ_BANCO_COMPACTADO="rar"

# Extensão dos arquivos de bancos de dados 
EXTENSAO_ARQ_BANCO="fdb"

# Extensão dos arquivos de back-up dos bancos de dados 
EXTENSAO_ARQ_BKP_BANCO="fbk"

# Nome arquivo de log
ARQ_LOG_SCRIPT="RestoreBD.log"

# Tamanho arquivo de log 1024 * 1024 = 1MB
TAM_ARQ_LOG="$[ 150 * 1024 ]"

# Quantidade máxima de arquivo de log (valor de 0 a 99 - 0 para desativado)
QUANT_MAX_ARQ_LOG=5

# Usuário de login do Firebird
USUARIO_LOGIN_FIREBIRD="UV360GRAVA"

# Senha de login do Firebird
SENHA_LOGIN_FIREBIRD="753159"

# Arquivo de Script SQL
NOME_ARQ_SCRIPT_SQL="Config_BDs.sql"

# Caminho do diretório do "Bancos_Em_Transito"
DIR_BANCOS_TRANSITO="/cygdrive/d/Restore_BD/Bancos_Em_Transito"

# Data no formato ano, mes e dia
DATA_ATUAL=`date "+%Y-%m-%d"`

# Data no formato Epoch
DATA_ATUAL_EPOCH=`date "+%s" -d "${DATA_ATUAL}"`

# Data no formato dia/mes/ano hora:min:seg
DATA_HORA="date "+%d/%m/%y--%T""

# Constante que define a quantidade de segundos tem o dia 
DIA_EM_SEGUNDOS=86400

################################################################################

# Armazena caminho de arquivos e diretório em formato MS (c:\dados\exemplo.txt)
CAMINHO_CONVERTIDO=""

# Caminho (diretório + nome_arquivo.rar) relativo do arquivo .rar
CAMINHO_RELATIVO_ARQ_RAR_CORRENTE=""

# Nome do arquivo rar (sem extensão) que está setado para processamento
NOME_ARQ_RAR_CORRENTE=""

# Diretório do arquivo rar 
DIR_ARQ_RAR_CORRENTE=""

# Nome da entidade corrente
NOME_ENTIDADE_CORRENTE=""

# Nome do arquivo de log do GBAK corrente

NOME_ARQ_LOG_GBAK_CORRENTE=""

# Chave de descompactacao do arquivo (.rar) corrente
CHAVE_ARQUIVO_RAR_CORRENTE=""

# Data de criacao do arquivo de backup do banco de dados (.fbk) corrente 
DATA_CRIACAO_ARQ_FBK_CORRENTE=""


# Verifica se o diretório existe e logo acessa-o.
if [ -d "${DIR_BASE_LOCAL}" ] 
    then
    if ! cd "${DIR_BASE_LOCAL}"
        then
        echo "Erro! Nao foi possivel acessar o diretorio ${DIR_BASE_LOCAL}."
        exit 1
        fi
    else
        echo "Erro! O diretorio ${DIR_BASE_LOCAL} nao existe."
        exit 1
 fi

################################################################################


# Retorna a diferença de dias entre a data atual e a data que foi passada como parâmetro
function retorna_quantidade_dias() {
    DATA_AUX_EPOCH=`date "+%s" -d "$1"`
    return `expr \( "${DATA_ATUAL_EPOCH}" - "${DATA_AUX_EPOCH}" \) / "${DIA_EM_SEGUNDOS}" 2> /dev/null `
    }

# Função para gerenciar a quantidade e limite de arquivos de logs
function gerenciador_arquivo_log() {
    
    if ! [ ${QUANT_MAX_ARQ_LOG} -ge 0 -a ${QUANT_MAX_ARQ_LOG} -lt 20 ]
        then
            QUANT_MAX_ARQ_LOG=0
        fi
    
    AUX_TAM=`ls "${DIR_ARQ_LOG_SCRIPT}/${ARQ_LOG_SCRIPT}" -al 2> /dev/null | cut --delimiter=" " --fields=5 2> /dev/null`
    
    if [ ! -z "${AUX_TAM}" ] && [ "${AUX_TAM}" -gt "${TAM_ARQ_LOG}" ]
        then
            QUANT=$[${QUANT_MAX_ARQ_LOG} -1 ]
            
            for i in `seq 0 ${QUANT} | tac`
                do
                if [ ${QUANT} -eq $i ] && [ -f "${DIR_ARQ_LOG_SCRIPT}"/"${ARQ_LOG_SCRIPT}${i}" ]
                    then
                    log "NL" "Removendo arquivo de log \"${ARQ_LOG_SCRIPT}${i}\"..."
                    if `rm -f "${DIR_ARQ_LOG_SCRIPT}"/"${ARQ_LOG_SCRIPT}${i}" 2> /dev/null`
                        then
                            log "ML" " removido com sucesso!"
                        else
                            log "NL" "*** Atencao erro! Nao foi possivel remover o arquivo "\${ARQ_LOG_SCRIPT}${i}"\."
                        fi    
                elif [ $i -gt 0 ]
                    then
                        mv "${DIR_ARQ_LOG_SCRIPT}"/"${ARQ_LOG_SCRIPT}${i}" "${DIR_ARQ_LOG_SCRIPT}"/"${ARQ_LOG_SCRIPT}$[${i}+1]" 2> /dev/null
                    else
                        mv "${DIR_ARQ_LOG_SCRIPT}"/"${ARQ_LOG_SCRIPT}" "${DIR_ARQ_LOG_SCRIPT}"/"${ARQ_LOG_SCRIPT}$[${i}+1]" 2> /dev/null
                    fi
            done        
        fi
    }

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

# Converte o formato do caminho de diretorio cmd/MS para shell/linux
function conversor_formato_caminho() { 
    if `grep -s -q "^/cygdrive/[a-z]" <<< cut -b -11 <<< "${1}"`
        then
            UNIDADE=`cut -b 11 <<< "${1}" 2> /dev/null`:
            UNIDADE=`tr [:lower:] [:upper:] <<< "${UNIDADE}" 2> /dev/null`
        
            CAMINHO=`cut -b 12- <<< "${1}" 2> /dev/null`
            CAMINHO=`tr "/" "\\\\" <<< "${CAMINHO}" 2> /dev/null`

            CAMINHO_CONVERTIDO="${UNIDADE}${CAMINHO}"
            return 0
        else
            log "NL" "Erro, o formato do caminho e invalido \"${1}\"."
            return 1
        fi
    }

	
function descompacta_arquivo_rar() {
	log "NL" "Descompactando ${CAMINHO_RELATIVO_ARQ_RAR_CORRENTE}... "	
	
	echo "${CAMINHO_RELATIVO_ARQ_RAR_CORRENTE}"
	
	if `rar e "${CAMINHO_RELATIVO_ARQ_RAR_CORRENTE}" "${NOME_ENTIDADE_CORRENTE}.${EXTENSAO_ARQ_BKP_BANCO}" -p"${CHAVE_ARQUIVO_RAR_CORRENTE}" -y -inul 2> /dev/null `
		then
			log "NL" "Arquivo descompactado com sucesso!" 
			tratativa_arquivos_rar_pos_processamento 'true'
			return 0
		else
			log "ML" "Erro! O arquivo nao foi descompactado, o Rar.exe retornou o codigo de erro: $?"
			tratativa_arquivos_rar_pos_processamento 'false'
			return 1
		fi
	}
	
function tratativa_arquivos_rar_pos_processamento() {
	if "${1}"
		then
			log "NL" "Deletando o arquivo \"${NOME_ARQ_RAR_CORRENTE}.${EXTENSAO_ARQ_BANCO_COMPACTADO}\""
			rm "${CAMINHO_RELATIVO_ARQ_RAR_CORRENTE}" 2> /dev/null
		else
			log "NL" "Movendo o arquivo \"${NOME_ARQ_RAR_CORRENTE}.${EXTENSAO_ARQ_BANCO_COMPACTADO}\" para \"${DIR_ARQ_REJEITADOS}\""
			mv -f "${CAMINHO_RELATIVO_ARQ_RAR_CORRENTE}" "${DIR_ARQ_REJEITADOS}" 2> /dev/null
		fi
	}
	
function tratativa_pos_restore() {
	if "${1}"
		then
			log "NL" "Deletando o arquivo \"${NOME_ENTIDADE_CORRENTE}.${EXTENSAO_ARQ_BKP_BANCO}\"..."
			rm "${NOME_ENTIDADE_CORRENTE}"."${EXTENSAO_ARQ_BKP_BANCO}" 2> /dev/null
			log "NL" "Deletando o arquivo \"${NOME_ARQ_LOG_GBAK_CORRENTE}\"..."
			rm "${NOME_ARQ_LOG_GBAK_CORRENTE}" 2> /dev/null
		else
			log "NL" "Movendo o arquivo \"${NOME_ENTIDADE_CORRENTE}.${EXTENSAO_ARQ_BKP_BANCO}\" para \"${DIR_ARQ_REJEITADOS}\"..."
			mv -f "${NOME_ENTIDADE_CORRENTE}"."${EXTENSAO_ARQ_BKP_BANCO}" "${DIR_ARQ_REJEITADOS}" 2> /dev/null
			log "NL" "Movendo o arquivo \"${NOME_ARQ_LOG_GBAK_CORRENTE}\" para  \"${DIR_ARQ_REJEITADOS}/\"..."
			mv -f "${NOME_ARQ_LOG_GBAK_CORRENTE}" "${DIR_ARQ_REJEITADOS}/" 2> /dev/null
			 
		fi
	}	
	
function restaura_banco() {
	log "NL" "Restaurando backup de BD: ${NOME_ENTIDADE_CORRENTE}.${EXTENSAO_ARQ_BKP_BANCO}..."
	if `gbak -p 4096 -c -v -r -o "${NOME_ENTIDADE_CORRENTE}"."${EXTENSAO_ARQ_BKP_BANCO}" "${NOME_ENTIDADE_CORRENTE}"."${EXTENSAO_ARQ_BANCO}" -user "${USUARIO_LOGIN_FIREBIRD}" -pass "${SENHA_LOGIN_FIREBIRD}" -y "${NOME_ARQ_LOG_GBAK_CORRENTE}" 2> /dev/null`
		then
			log "NL" "O BD foi restaurado com sucesso."
			tratativa_pos_restore 'true'
			return 0
		else
			log "NL" "Erro! O BD nao foi restaurado."
			tratativa_pos_restore 'false'
			return 1
		fi
	}	
	
function seta_data_criacao_arq_banco() {

	DATA_AUX=`ls "${NOME_ENTIDADE_CORRENTE}"."${EXTENSAO_ARQ_BKP_BANCO}" -al --time-style=long-iso 2> /dev/null | awk '{print $6" "$7}' 2> /dev/null ` # Captura o campo de data e hora do arquivo
	DATA_CRIACAO_ARQ_FBK_CORRENTE=""
	DATA_CRIACAO_ARQ_FBK_CORRENTE=`date "+%Y_%m_%d_%H%M" -d "${DATA_AUX}" 2> /dev/null `	
	}

function roda_script() {
	log "NL" "Iniciando a execucao do Script \"${NOME_ARQ_SCRIPT_SQL}\"  no BD \"${NOME_ENTIDADE_CORRENTE}.${EXTENSAO_ARQ_BANCO}\"..."
	
	if `isql -i "${NOME_ARQ_SCRIPT_SQL}" -u "${USUARIO_LOGIN_FIREBIRD}" -p "${SENHA_LOGIN_FIREBIRD}" "${NOME_ENTIDADE_CORRENTE}.${EXTENSAO_ARQ_BANCO}" 2> /dev/null`
		then
			log "NL" "Script executado com sucesso."
			return 0
		else
			log "NL" "Erro na execucao do script."
			return 1
		fi		
	}

function seta_usuario_permissao() {
	
	conversor_formato_caminho "${DIR_BANCOS_TRANSITO}"
	CAMINHO_AUX="${CAMINHO_CONVERTIDO}\\${NOME_ENTIDADE_CORRENTE}_${DATA_CRIACAO_ARQ_FBK_CORRENTE}.${EXTENSAO_ARQ_BANCO}"
	
	log "NL" "Adicionando usuario e permissoes de leitura no arquivo ${CAMINHO_AUX}..."
	
	if icacls "${CAMINHO_AUX}" /grant Todos:\(RX\) /Q > /dev/null
		then
			log "NL" "Usuario e permissoes foram setadas com sucesso."
			return 0
		else
			log "NL" "Erro, nao foi possivel setar usuario e/ou permissoes,"
			log "NL" "o \"icacl.exe\" retornou o codigo de erro: ${?}"
			return 1
		fi
	}
	
function move_arquivo_BD() {
	log "NL" "Movendo arquivos de BD para pasta \"Bancos em Transito\"..."
	if `mv "${NOME_ENTIDADE_CORRENTE}.${EXTENSAO_ARQ_BANCO}"  "${DIR_BANCOS_TRANSITO}"/"${NOME_ENTIDADE_CORRENTE}"_"${DATA_CRIACAO_ARQ_FBK_CORRENTE}"."${EXTENSAO_ARQ_BANCO}" 2> /dev/null`
		then
			log "NL" "Arquivos de BD movido com sucesso."
			return 0
		else
			log "NL" "Erro o arquivo de BD nao foi movido."
			return 1
		fi
	}
	
function processa_dados() {
	
	if descompacta_arquivo_rar
		then
		seta_data_criacao_arq_banco # Captura data de criação do backup 
		if restaura_banco
			then
			if roda_script
				then
				if move_arquivo_BD
					then
					if seta_usuario_permissao
						then
							log "NL" "Processamento concluido com sucesso." 
						fi
					fi
				fi	
			fi
		fi
	}	
	
function seta_arquivos_corrente() {
	
	log "NL" "- Iniciando sessao para processamento do arquivo "${1}"."
	
	CAMINHO_RELATIVO_ARQ_RAR_CORRENTE="${1}"
	
	NOME_ARQ_RAR_CORRENTE=`basename "${1}" 2> /dev/null | cut --delimiter="." --field=1 2> /dev/null`
	DIR_ARQ_RAR_CORRENTE=`dirname "${1}" 2> /dev/null`
	
	NOME_ARQ_LOG_GBAK_CORRENTE="${NOME_ARQ_RAR_CORRENTE}_gbak.log"
	
	NOME_ENTIDADE_CORRENTE=`cut --delimiter="_" --field=1 <<< "${NOME_ARQ_RAR_CORRENTE}" 2> /dev/null`
	CHAVE_ARQUIVO_RAR_CORRENTE=`cat Chaves.key 2> /dev/null | grep "${NOME_ENTIDADE_CORRENTE}" 2> /dev/null | cut --field=2 2> /dev/null`
	
	}	
		
function funcao_principal() {
    
    gerenciador_arquivo_log
    
    log "ML" "***** Inicio da execucao do RestoreBD - `${DATA_HORA}` *****"
	
	while true; do
		AUX_DIR_ARQ_RAR=""
		AUX_DIR_ARQ_RAR=`ls "${DIR_ARQ_BANCO_COMPACTADO}"*."${EXTENSAO_ARQ_BANCO_COMPACTADO}" -1 2> /dev/null | grep -s -m 1 -E \(CIS\|CM\|FMS\|DMAE\|IP\|PM\) 2> /dev/null `
		
		if [ ! -z "${AUX_DIR_ARQ_RAR}" ]
			then
				seta_arquivos_corrente "${AUX_DIR_ARQ_RAR}" # Seta variáveis corrente
				processa_dados 
			else
				log "NL" "Nenhum arquivo \".${EXTENSAO_ARQ_BANCO_COMPACTADO}\" para processar, abortando o processo."
				break 
			fi
		done  
		  
    log "NL" "Termino da execucao do Script - `${DATA_HORA}` " ; log "NL" "" ; log "NL" ""
    }
	
	funcao_principal  # Executa a aplicação

 