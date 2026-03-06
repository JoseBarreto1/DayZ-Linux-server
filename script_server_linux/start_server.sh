#!/bin/bash

# ===== CONFIGURAÇÕES =====
SERVER_DIR="$HOME/steamcmd/dayzserver"
PROTON_RUN="$SERVER_DIR/proton"
SERVER_EXE="DayZServer_x64.exe"
SCRIPT_DIR="$SERVER_DIR/script_server_linux"
MOD_ID_FILE="mod_ids.txt"

USER_STEAM=
PASSWORD_STEAM=""

SERVER_MODS='-serverMod=servermod'
SERVER_PORT='-port=2302'
SERVER_CPU='-cpuCount=2'
SERVER_OTHERS='' #'-dologs -adminlog -netlog -freezecheck'

CONFIG="-config=serverDZ.cfg"
PROFILES="-profiles=profiles"

# ===== PREPARA A LISTA DE MODS =====
MODS_SUBDIR="md/"

if [ ! -f "$SCRIPT_DIR/$MOD_ID_FILE" ]; then
    echo "❌ Arquivo mod_ids.txt não encontrado!"
    exit 1
fi

MODS_ID=$(<"$SCRIPT_DIR/$MOD_ID_FILE")
MODS_ID="${MODS_ID//\"/}"  # Remove aspas
MODS_ID="${MODS_ID// /}"   # Remove espaços
MODS_ID="${MODS_ID//$'\n'/}"  # Remove quebras de linha
MODS_ID="${MODS_ID//$'\t'/}"  # (Opcional) Remove tabs

MODS_PARAM_TEMP=""
IFS=';' read -ra IDS <<< "$MODS_ID"
for id in "${IDS[@]}"; do
    MODS_PARAM_TEMP+="${MODS_SUBDIR}${id};"
done

if [[ -z "$MODS_PARAM_TEMP" ]]; then
    echo "⚠️ Nenhum mod foi carregado, verifique o arquivo mod_ids.txt"
    exit 1
fi

# ===== Remove o último ponto e vírgula =====
MODS_PARAM_TEMP="${MODS_PARAM_TEMP::-1}"

MODS="-mod=${MODS_PARAM_TEMP}"
echo "✅ Todos os mods foram formatados."

DOWNLOAD_COMMANDS=""

# ===== PREFIXO E VARIÁVEIS NECESSÁRIAS =====
STEAM_COMPAT_DATA_PATH=$HOME/steamcmd/compatdata/dayzserver
STEAM_COMPAT_CLIENT_INSTALL_PATH="$HOME/.steam/steamcmd"

validate_dayz_server() {
    local STEAMCMD="$HOME/.steam/steamcmd/steamcmd.sh"

    if [ -x "$SERVER_DIR/DayZServer_x64.exe" ]; then
        echo "✅ dayzserver já instalado"
        return
    fi

    mkdir -p $HOME/steamcmd/compatdata/dayzserver

    # Não existe em lugar nenhum → baixar
    ensure_steamcmd

    echo "⬇️ Instalando dayzserver..."
    
    "$STEAMCMD" \
        +force_install_dir "$SERVER_DIR" \
        +login $USER_STEAM $PASSWORD_STEAM \
        +app_update 223350 validate \
        +quit

    cp -f "$SERVER_DIR/serverDZ.cfg.example" "$SERVER_DIR/serverDZ.cfg"
    
    echo "✅ Dayzserver está pronto!"
}

ensure_steamcmd() {
    if [ -x "$HOME/.steam/steamcmd/steamcmd.sh" ]; then
        echo "✅ steamcmd já instalado"
        return
    fi

    echo "⬇️ Instalando steamcmd..."
    mkdir -p "$HOME/.steam/steamcmd"
    cd "$HOME/.steam/steamcmd" || exit 1

    wget https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz
    tar -xzf steamcmd_linux.tar.gz
    rm steamcmd_linux.tar.gz
}

ensure_mod() {
    local MOD_ID="$1"
    local SERVER_MOD_DIR="$SERVER_DIR/md/$MOD_ID"

    # Já existe no servidor
    if [ -d "$SERVER_MOD_DIR" ]; then
        echo "✅ Mod $MOD_ID já existe no servidor"
        return
    fi

    echo "📦 Mod $MOD_ID precisa ser baixado"

    # adiciona comando na lista
    DOWNLOAD_COMMANDS="$DOWNLOAD_COMMANDS+workshop_download_item 221100 $MOD_ID "
}

download_mods() {
    if [[ -z "$DOWNLOAD_COMMANDS" ]]; then
        echo "✅ Nenhum mod precisa ser baixado"
        return
    fi

    ensure_steamcmd

    local STEAMCMD="$HOME/.steam/steamcmd/steamcmd.sh"

    echo "⬇️ Baixando mods necessários..."

    if [ ! -d "$HOME/steamcmd/mods" ]; then
        mkdir -p "$HOME/steamcmd/mods"
    fi
    
    "$STEAMCMD" +force_install_dir "$HOME/steamcmd/mods" +login $USER_STEAM $PASSWORD_STEAM $DOWNLOAD_COMMANDS +quit
}

copy_mods() {
    IFS=';' read -ra IDS <<< "$MODS_ID"

    for MOD_ID in "${IDS[@]}"; do
        local SERVER_MOD_DIR="$SERVER_DIR/md/$MOD_ID"
        local CLIENT_MOD_DIR="$HOME/steamcmd/mods/steamapps/workshop/content/221100/$MOD_ID"

        if [ -d "$CLIENT_MOD_DIR" ] && [ ! -d "$SERVER_MOD_DIR" ]; then
            echo "📂 Copiando mod $MOD_ID para servidor"
            cp -r "$CLIENT_MOD_DIR" "$SERVER_DIR/md/"
        fi
    done
}

prepare_mods() {
    echo "🔍 Verificando status dos mods..."

    if [ ! -d "$SERVER_DIR/md" ]; then
        mkdir -p "$SERVER_DIR/md"
    fi

    IFS=';' read -ra IDS <<< "$MODS_ID"
    for id in "${IDS[@]}"; do
        ensure_mod "$id"
    done

    download_mods
    copy_mods

    echo "✅ Todos os mods estão prontos"
}

monitorar() {
    echo "✅ Iniciou monitoramento do servidor em segundo plano"
    while true; do
        for pid in $SERVER_PIDS; do
            if ! ps -p "$pid" > /dev/null; then
                echo "❌ Servidor caiu!"

                prepare_mods
                sleep 2       
                
                kill -9 $$                
                sleep 2
                
                echo "(Monitoramento) Servidor reiniciando..."
                exec "$SCRIPT_DIR/start_server.sh"
            fi
        done
        sleep 300
    done
}

calc_restart_time() {
    # Obtém hora e minuto atuais
    nowHour=$((10#$(date +%H)))
    nowMin=$((10#$(date +%M)))

    echo "Hora atual: $nowHour:$nowMin"

    # Converte hora atual para minutos desde a meia-noite
    totalNowMins=$((nowHour * 60 + nowMin))
    echo "Minutos desde meia-noite: $totalNowMins"

    # Intervalo de reinício (6 em 6 horas = 360 minutos)
    interval=360

    # Calcula o próximo horário de reinício em minutos desde a meia-noite
    nextRestart=$(( (totalNowMins / interval + 1) * interval ))

    # Ajusta para o limite do dia (1440 minutos)
    if [ "$nextRestart" -ge 1440 ]; then
        nextRestart=1440
        echo "Ajuste para o restart da meia-noite: $nextRestart"
    fi

    # Calcula os minutos restantes até o próximo reinício
    waitMins=$((nextRestart - totalNowMins))
    echo "Minutos restantes: $waitMins"

    # Converte para segundos
    waitSecs=$((waitMins * 60))
    echo "Próximo restart em $waitMins minutos ($waitSecs segundos)."

    # Aguarda até o próximo reinício
    sleep "$waitSecs"
}

main() {
    export STEAM_COMPAT_DATA_PATH
    export STEAM_COMPAT_CLIENT_INSTALL_PATH

    while true; do
        # ===== LIMPEZA DE LOGS =====
        echo "🧹 Apagando arquivos .RPT, .log e .mdmp em: $SERVER_DIR/profiles"
        rm -f "$SERVER_DIR"/profiles/*.RPT "$SERVER_DIR"/profiles/*.ADM "$SERVER_DIR"/profiles/*.log "$SERVER_DIR"/profiles/*.mdmp
        rm -f "$SERVER_DIR"/profiles/WebApiLog/*.log "$SERVER_DIR"/profiles/LBmaster/Data/Core/Players/*.json "$SERVER_DIR"/profiles/ExpansionMod/Logs/*.log "$SERVER_DIR"/profiles/EventManagerLog/*.log "$SERVER_DIR"/profiles/CBD_LootSystem/Logging/Logs/*.log "$SERVER_DIR"/profiles/BXDCarLock/CarLockLogging/Logs/*.log
        rm -rf "$SERVER_DIR"/profiles/CodeLock/Logs
        echo "✅ Limpeza concluída."

        # ===== EXECUÇÃO =====
        cd "$SERVER_DIR" || { echo "❌ Não foi possível entrar no diretório do servidor."; exit 1; }

        echo "🚀 Iniciando servidor DayZ com Proton..."
        "$PROTON_RUN" run "./$SERVER_EXE" $CONFIG $PROFILES "$MODS" "$SERVER_MODS" "$SERVER_PORT" "$SERVER_CPU" "$SERVER_OTHERS" &

        SERVER_LAUNCH_PID=$!

        if ! kill -0 "$SERVER_LAUNCH_PID" 2>/dev/null; then
            echo "❌ Falha ao iniciar o servidor com Proton."
            exit 1
        fi

        # Aguarda um pouco para o processo iniciar
        sleep 5

        # Captura todos os PIDs do processo real (filhos do Proton)
        SERVER_PIDS=$(pgrep -u "$USER" -f "$SERVER_EXE")

        # Verifica se o PID foi capturado com sucesso
        if [[ -n "$SERVER_PIDS" ]]; then
            echo "✅ Servidor iniciado com os PIDs: $SERVER_PIDS"
        else
            echo "❌ Não foi possível capturar o PID do servidor."
        fi

        # Realiza o monitoramento caso o servidor caia durante execução
        monitorar &
        MONITOR_PID=$!

        echo "✅ Processo em background PID: $MONITOR_PID"

        # ===== CÁLCULO DO TEMPO ATÉ O PRÓXIMO REINÍCIO =====
        calc_restart_time

        # Encerra o monitoramento
        echo "Encerrando monitoramento (PID: $MONITOR_PID)..."
        if [[ -n "$MONITOR_PID" ]]; then
            kill -9 "$MONITOR_PID"
        fi

        # Encerra processos (ajuste conforme o nome do processo real)
        echo "Encerrando servidor..."

        if [[ -n "$SERVER_PIDS" ]]; then
            echo "🛑 Encerrando os seguintes PIDs: $SERVER_PIDS"
            kill $SERVER_PIDS
            sleep 2
            for pid in $SERVER_PIDS; do
                if ps -p "$pid" > /dev/null; then
                    kill -9 "$pid"
                fi
            done
        else
            echo "⚠️ Nenhum processo do servidor encontrado para encerrar."
        fi

        echo "$(date +%T) Servidor reiniciando..."

        # Aguarda 10 segundos antes de reiniciar
        sleep 10
    done
}

validate_dayz_server

prepare_mods

main
