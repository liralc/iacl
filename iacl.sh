#!/usr/bin/env bash
#
# iacl_dio.sh - Atomatizando a criação de infraetrutura.
#
# E-mail:     liralc@gmail.com
# Autor:      Anderson Lira
# Manutenção: Anderson Lira
#
# ************************************************************************** #
#  Atuomatizando crião de infraetrutura.
#
#  Exemplos de execução:
#      $ ./iacl.sh
#
# ************************************************************************** #
# Histórico:
#
#   v1.0 29/07/2022, Anderson Lira:
#       - Início do programa.
#
# ************************************************************************** #
# Testado em:
#   bash 5.0.3
#   Ubuntu 20.1
# ************************************************************************** #
#
# ======== VARIAVEIS ============================================================== #
export DIA_LOG=$(date +%d%m%Y-%H%M%S)
FILE_LOG="/dados/Logs/iacl_$DIA_LOG.log"
DIR_LOCAL="/mnt/driver"
USERS_SYSTEM="userList"
VERDE="\033[32;1m]"
VERMELHOP="\033[31;1;5m]"
# ================================================================================ #

# ======== TESTES ================================================================ #
if [ $(echo $UID) -ne 0 ]
then
    echo -e "${VERMELHOP}Você deve está com privilégios de ROOT para continuar com esse programa." | tee -a "$FILE_LOG"
    exit 1
fi

if [ ! $(ping www.google.com -c 3) > /dev/null ]
then
    echo -e "${VERDE}Para a instalação do VNC, a sua máquina precisa está conectada na internet. " | tee -a "$FILE_LOG"
    exit 1
fi

echo "Verificando a existência do diretório para os logs." | tee -a "$FILE_LOG"
if [ -d /dados/Logs ]; then
    echo "Diretório de logs existente." | tee -a "$FILE_LOG"
else
    echo "Criando diretório para logs..." | tee -a "$FILE_LOG"
    mkdir -p  /dados/Logs
fi
# =================================================================================== #

# ======== FUNCOES ================================================================== #
function updateSystem () {
    apt-get update ; apt-get upgrade -y ; apt-get dist-upgrade -y ; apt autoremove
}

function createDir () {
    echo "Verificando a existência do diretório $1. Por isso não será criado." | tee -a "$FILE_LOG"
    if [ -d "$1" ]; then
        echo "Diretório $1 existente." | tee -a "$FILE_LOG"
    else
        echo "Criando diretório $1..." | tee -a "$FILE_LOG"
        mkdir -p  "$1"
        [ "$?" -eq 0 ] && echo "Diretório $1 criado com sucesso!! - OK" | tee -a "$FILE_LOG"
    fi
}

function createGroup () {
    echo "Verificando a existência do Grupo $1" | tee -a "$FILE_LOG"
    cat /etc/group | grep $1
        if [ "$?" -ne 0 ]; then
        echo "O grupo $1 existente no sistema." | tee -a "$FILE_LOG"
    else
        echo "Criando GRUPO $1..." | tee -a "$FILE_LOG"
        groupadd "$1"
        [ "$?" -eq 0 ] && echo "Grupo $1 criado com sucesso!! - OK" | tee -a "$FILE_LOG"
    fi
}

createUsers () {
  while read -r line
  do
    [ "$(echo $line | cut -c1)" = "#" ] && continue
    [ ! "$line" ] && continue

    USER="$(echo $line | cut -d '-' -f 1)" | tee -a "$FILE_LOG"
    GRP="$(echo $line | cut -d '-' -f 2)" | tee -a "$FILE_LOG"

    cat /etc/passwd | grep "$USER"
    if [ "$?" -ne 0 ]; then
     echo "<<<<<<USUÁRIO $USER JÁ CADASTRADO NO SISTEMA!!!>>>>>>" | tee -a "$FILE_LOG"
    else
     useradd "$USER" -m -s /bin/bash -p $(openssl passwd -crypt senha123) -G "$GRP" | tee -a "$FILE_LOG" 
     [ "$?" -eq 0 ] && echo "Usuário $USER e associação ao Grupo $GRP criado com sucesso!! - OK" | tee -a "$FILE_LOG"
    fi 
  done < "$USERS_SYSTEM"
}
# =================================================================================== #

# ======== EXECUCAO DO PROGRAMA ===================================================== #

echo "Criando diretórios..." | tee -a "$FILE_LOG"

createDir "/publico"
createDir "/adm"
createDir "/ven"
createDir "/sec"

echo "Criando grupos de usuários..." | tee -a "$FILE_LOG"

createGroup "GRP_ADM"
createGroup "GRP_VEN"
createGroup "GRP_SEC"

echo "Criando usuários..." | tee -a "$FILE_LOG"
createUsers

echo "Especificando permissões do diretórios..." | tee -a "$FILE_LOG"

chown root:GRP_ADM /adm
chown root:GRP_VEN /ven
chown root:GRP_SEC /sec

chmod 770 /adm
chmod 770 /ven
chmod 770 /sec
chmod 770 /publico

echo "Realizando atualizações no sistema..." | tee -a "$FILE_LOG"
updateSystem

echo "Fim..."
# =================================================================================== #