#!/bin/bash

PERCENTUAL=$(df -h / | awk '{print $5}' | grep "^\([0-9][0-9]\|100\)%" | tr -d '%')



function envia_email(){

        ASSUNTO=$1
        MENSAGEM=$2

        USER_SENDER="someuser@someuser.com"
        DESTINATARIO_1="someuser@someuser.com"
        DESTINATARIO_2="carloszix@hotmail.com"
        DESTINATARIO_3="someuser@someuser.com"

        SMTP="somesmtpserver:587"
        USER="someuser@someuser.com"
        SENHA="###############"

        sendEmail -f "${USER_SENDER}" -t "${DESTINATARIO_1}" -u "${ASSUNTO}" -m "${MENSAGEM}" -s "${SMTP}" -xu "${USER_SENDER}" -xp "${SENHA}"
        sendEmail -f "${USER_SENDER}" -t "${DESTINATARIO_2}" -u "${ASSUNTO}" -m "${MENSAGEM}" -s "${SMTP}" -xu "${USER_SENDER}" -xp "${SENHA}"
        sendEmail -f "${USER_SENDER}" -t "${DESTINATARIO_3}" -u "${ASSUNTO}" -m "${MENSAGEM}" -s "${SMTP}" -xu "${USER_SENDER}" -xp "${SENHA}"

}

function verifica_espaco(){

        if [ "${PERCENTUAL}" -gt 30 ]
                then
                        envia_email "WARNING - Problema com particao - zixcard" "A particao / (raiz) esta com mais de 60% cheia"
        else
                exit 0
        fi


}

verifica_espaco
