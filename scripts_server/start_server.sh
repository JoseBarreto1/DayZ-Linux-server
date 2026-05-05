#!/bin/bash

# ===== CONFIGURAÇÕES =====
PROJECT="dayzserver" #name project/folder
SERVER_DIR="$HOME/steamcmd/$PROJECT"
PROTON_RUN="$SERVER_DIR/proton"
SERVER_EXE="DayZServer_x64.exe" #Stable branch 
#SERVER_EXE="DayZServer" #Experimental branch
SCRIPT_DIR="$SERVER_DIR/scripts_server"
GAME_ID="223350" #Stable branch 
#GAME_ID="1042420" #Experimental branch

MOD_ID_FILE="mod_ids.txt"
MOD_SERVER_DIR="$SERVER_DIR/md"
MOD_GAME_DIR="$HOME/steamcmd/mods/steamapps/workshop/content/221100/"

ENV_CONFIG="$SCRIPT_DIR/config.env"

LOG_DIR="$SCRIPT_DIR/logs"
CACHE_FILE="$LOG_DIR/dayz_check_mod_update"
LOG_FILE="$LOG_DIR/changes"

BOT_SCRIPT="$SCRIPT_DIR/bot.py"
BOT_PID_FILE="$LOG_DIR/discord_bot.pid"
BOT_VENV="$SCRIPT_DIR/.venv"

SERVER_RESTART_TIME_IN_MIN=360 #(6 horas = 360 minutos)
TIME_CHECK_MOD_UPDATES_IN_SEC=600 #(10 minutos = 600 segundos)
TIME_CHECK_SERVER_CRASHED_IN_SEC=120 #(2 minutos = 120 segundos)

SERVER_MODS='-serverMod=servermod'
SERVER_PORT='-port=2302'
SERVER_CPU='-cpuCount=2'
SERVER_OTHERS='-nologs' #'-dologs -adminlog -netlog -freezecheck'

CONFIG="-config=serverDZ.cfg"
PROFILES="-profiles=profiles"

# ===== PREPARA A LISTA DE MODS =====
MODS_SUBDIR="md/"

if [ ! -f "$SCRIPT_DIR/$MOD_ID_FILE" ]; then
    echo "❌ File mod_ids.txt not found!"
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
    echo "⚠️ No mods were loaded, check the mod_ids.txt file."
    exit 1
fi

# ===== Remove o último ponto e vírgula =====
MODS_PARAM_TEMP="${MODS_PARAM_TEMP::-1}"

MODS="-mod=${MODS_PARAM_TEMP}"

DOWNLOAD_COMMANDS=""

# ===== PREFIX AND NECESSARY VARIABLES =====
STEAM_COMPAT_DATA_PATH=$HOME/steamcmd/compatdata/dayzserver
STEAM_COMPAT_CLIENT_INSTALL_PATH="$HOME/.steam/steamcmd"

load_credentials() {
    if [ ! -f "$ENV_CONFIG" ]; then
        echo
        echo "📝 Initial setup..."

        echo
        echo "🆔 Enter your Steam username:"
        read USER_STEAM

        echo "Confirm the entered value.: $USER_STEAM. Digite: y/n?"
        read CONFIRM_USER

        if [ "$CONFIRM_USER" == "n" ]; then
            echo
            echo "🆔 Enter your Steam username again:"
            read USER_STEAM
        fi

        echo
        echo "🔐 Enter your Steam password:"
        read PASSWORD_STEAM        

        echo "Confirmar valor digitado: $PASSWORD_STEAM. Digite: y/n?"
        read CONFIRM_PASSWORD

        if [ "$CONFIRM_PASSWORD" == "n" ]; then
            echo "🔐 Enter your Steam password again:"
            read PASSWORD_STEAM
        fi

        echo
        echo "✅ Saving configuration..."

        echo "USER_STEAM=\"$USER_STEAM\"" > $ENV_CONFIG
        echo "PASSWORD_STEAM=\"$PASSWORD_STEAM\"" >> $ENV_CONFIG
        echo "DISCORD_BOT_TOKEN=\"\"" >> $ENV_CONFIG
        echo "DISCORD_BOT_IP=\"\"" >> $ENV_CONFIG
        echo "WEBHOOK_URL_SERVER=\"\"" >> $ENV_CONFIG
        echo "WEBHOOK_URL_MOD=\"\"" >> $ENV_CONFIG
    fi

    source $ENV_CONFIG
    chmod 600 $ENV_CONFIG

    echo "💾 Usuário carregado: $USER_STEAM"
}

# ── Funções do Discord Bot ────────────────────────────────────────────────────

bot_enabled() {
    # Retorna 0 (true) somente se TOKEN e IP estiverem preenchidos
    [[ -n "${DISCORD_BOT_TOKEN}" && -n "${DISCORD_BOT_IP}" ]]
}

start_discord_bot() {
    if ! bot_enabled; then
        echo "⚠️  Discord Bot desativado (DISCORD_BOT_TOKEN ou DISCORD_BOT_IP vazio no config.env)."
        return
    fi
 
    if [ -f "$BOT_PID_FILE" ] && kill -0 "$(cat "$BOT_PID_FILE")" 2>/dev/null; then
        echo "✅ Discord Bot já está em execução (PID $(cat "$BOT_PID_FILE"))."
        return
    fi
 
    # Verifica Python 3
    if ! command -v python3 &>/dev/null; then
        echo "⬇️  Python 3 não encontrado. Instalando..."
        if   command -v apt-get &>/dev/null; then sudo apt-get update -qq && sudo apt-get install -y python3 python3-venv python3-full
        elif command -v dnf     &>/dev/null; then sudo dnf install -y python3
        elif command -v pacman  &>/dev/null; then sudo pacman -S --noconfirm python
        elif command -v brew    &>/dev/null; then brew install python3
        else echo "❌ Gerenciador de pacotes não reconhecido. Instale o Python 3 manualmente." ; return 1
        fi
    fi
 
    # Garante que python3-venv está instalado (necessário no Ubuntu 24.04)
    if ! python3 -m venv --help &>/dev/null; then
        echo "⬇️  Instalando python3-venv..."
        sudo apt-get install -y python3-venv python3-full 2>/dev/null || true
    fi
 
    # Cria o ambiente virtual se não existir
    if [ ! -d "$BOT_VENV" ]; then
        echo "🐍 Criando ambiente virtual em $BOT_VENV ..."
        python3 -m venv "$BOT_VENV"
    fi
 
    # Instala módulos dentro do venv se necessário
    _install_if_missing() {
        local import_name="$1" pkg_name="$2" flags="$3"
        if ! "$BOT_VENV/bin/python" -c "import ${import_name}" &>/dev/null; then
            echo "⬇️  Instalando ${pkg_name} no venv..."
            "$BOT_VENV/bin/pip" install $flags "${pkg_name}"
        fi
    }
    _install_if_missing "discord" "discord.py" "-U"
    _install_if_missing "a2s"     "python-a2s" ""
 
    if [ ! -f "$BOT_SCRIPT" ]; then
        echo "❌ bot.py não encontrado em: $BOT_SCRIPT"
        return 1
    fi
 
    echo "🤖 Iniciando Discord Bot..."
    mkdir -p "$LOG_DIR"
 
    DISCORD_BOT_TOKEN="$DISCORD_BOT_TOKEN" \
    DISCORD_BOT_IP="$DISCORD_BOT_IP" \
    DISCORD_BOT_PORT="$DISCORD_BOT_PORT" \
    "$BOT_VENV/bin/python" "$BOT_SCRIPT" >> "$LOG_DIR/discord_bot.log" 2>&1 &
 
    echo $! > "$BOT_PID_FILE"
    echo "✅ Discord Bot iniciado (PID $!)."
}

stop_discord_bot() {
    if [ -f "$BOT_PID_FILE" ]; then
        local PID
        PID=$(cat "$BOT_PID_FILE")
        if kill -0 "$PID" 2>/dev/null; then
            echo "🛑 Encerrando Discord Bot (PID $PID)..."
            kill "$PID" && rm -f "$BOT_PID_FILE"
        else
            rm -f "$BOT_PID_FILE"
        fi
    fi
}

validate_dayz_server() {
    local STEAMCMD="$HOME/.steam/steamcmd/steamcmd.sh"

    if [ -x "$SERVER_DIR/$SERVER_EXE" ]; then
        echo "✅ dayzserver. Ok!"
        return
    fi

    mkdir -p $HOME/steamcmd/compatdata/dayzserver

    ensure_steamcmd

    echo "⬇️ Installing DayZ Server..."
    
    "$STEAMCMD" \
        +force_install_dir "$SERVER_DIR" \
        +login $USER_STEAM $PASSWORD_STEAM \
        +app_update $GAME_ID validate \
        +quit

    cp -f "$SERVER_DIR/mpmissions/dayzOffline.chernarusplus/db/events.example.xml" "$SERVER_DIR/mpmissions/dayzOffline.chernarusplus/db/events.xml"
    cp -f "$SERVER_DIR/mpmissions/dayzOffline.chernarusplus/db/types.example.xml" "$SERVER_DIR/mpmissions/dayzOffline.chernarusplus/db/types.xml"
    cp -f "$SERVER_DIR/mpmissions/dayzOffline.chernarusplus/env/zombie_territories.example.xml" "$SERVER_DIR/mpmissions/dayzOffline.chernarusplus/env/zombie_territories.xml"
    cp -f "$SERVER_DIR/mpmissions/dayzOffline.chernarusplus/cfgeconomycore.example.xml" "$SERVER_DIR/mpmissions/dayzOffline.chernarusplus/cfgeconomycore.xml"
    cp -f "$SERVER_DIR/mpmissions/dayzOffline.chernarusplus/cfgeffectarea.example.json" "$SERVER_DIR/mpmissions/dayzOffline.chernarusplus/cfgeffectarea.json"
    cp -f "$SERVER_DIR/mpmissions/dayzOffline.chernarusplus/cfgignorelist.example.xml" "$SERVER_DIR/mpmissions/dayzOffline.chernarusplus/cfgignorelist.xml"
    cp -f "$SERVER_DIR/mpmissions/dayzOffline.chernarusplus/cfgundergroundtriggers.example.json" "$SERVER_DIR/mpmissions/dayzOffline.chernarusplus/cfgundergroundtriggers.json"
    cp -f "$SERVER_DIR/serverDZ.cfg.example" "$SERVER_DIR/serverDZ.cfg"
    
    echo "✅ DayZ Server is ready!"
}

ensure_steamcmd() {
    if [ -x "$HOME/.steam/steamcmd/steamcmd.sh" ]; then
        echo "✅ steamcmd already installed"
        return
    fi

    echo "⬇️ Installing steamcmd..."
    mkdir -p "$HOME/.steam/steamcmd"
    cd "$HOME/.steam/steamcmd" || exit 1

    wget https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz
    tar -xzf steamcmd_linux.tar.gz
    rm steamcmd_linux.tar.gz
}

ensure_mod() {
    local MOD_ID="$1"
    local SERVER_MOD_DIR="$MOD_SERVER_DIR/$MOD_ID"

    # Já existe no servidor
    if [ -d "$SERVER_MOD_DIR" ]; then
        return
    fi

    echo "📦 The mod $MOD_ID needs to be downloaded."

    # adiciona comando na lista
    DOWNLOAD_COMMANDS="$DOWNLOAD_COMMANDS+workshop_download_item 221100 $MOD_ID "
}

download_mods() {
    if [[ -z "$DOWNLOAD_COMMANDS" ]]; then
        return
    fi

    ensure_steamcmd

    local STEAMCMD="$HOME/.steam/steamcmd/steamcmd.sh"

    echo "⬇️ Downloading necessary mods..."

    if [ ! -d "$HOME/steamcmd/mods" ]; then
        mkdir -p "$HOME/steamcmd/mods"
    fi
    
    "$STEAMCMD" +force_install_dir "$HOME/steamcmd/mods" +login $USER_STEAM $PASSWORD_STEAM $DOWNLOAD_COMMANDS +quit
}

copy_mods() {
    IFS=';' read -ra IDS <<< "$MODS_ID"

    for MOD_ID in "${IDS[@]}"; do
        local SERVER_MOD_DIR="$MOD_SERVER_DIR/$MOD_ID"
        local CLIENT_MOD_DIR="$HOME/steamcmd/mods/steamapps/workshop/content/221100/$MOD_ID"

        if [ -d "$CLIENT_MOD_DIR" ] && [ ! -d "$SERVER_MOD_DIR" ]; then
            echo "📂 Copying mod $MOD_ID to server"
            cp -r "$CLIENT_MOD_DIR" "$MOD_SERVER_DIR/"
            rm -rf "$CLIENT_MOD_DIR"
        fi
    done
}

cleanup_removed_mods() {
    for dir in "$MOD_SERVER_DIR/"*; do
        [ -d "$dir" ] || continue

        MOD_FOLDER=$(basename "$dir")

        if [[ ";$MODS_ID;" != *";$MOD_FOLDER;"* ]]; then
            echo "🗑️ Removing old mod: $MOD_FOLDER"
            rm -rf "$dir"
        fi
    done
}

prepare_mods() {
    if [ ! -d "$MOD_SERVER_DIR" ]; then
        mkdir -p "$MOD_SERVER_DIR"
    fi

    cleanup_removed_mods

    IFS=';' read -ra IDS <<< "$MODS_ID"
    for id in "${IDS[@]}"; do
        ensure_mod "$id"
    done

    download_mods
    copy_mods

    DOWNLOAD_COMMANDS=""

    echo "✅ All mods are ready."
}

check_dayz_update() {
    LOCAL_BUILD=$(grep -oP '"buildid"\s+"\K[^"]+' "$SERVER_DIR/steamapps/appmanifest_$GAME_ID.acf")

    REMOTE_BUILD=$(curl -s "https://api.steamcmd.net/v1/info/$GAME_ID" \
| jq -r ".data.\"$GAME_ID\".depots.branches.public.buildid")

    if [[ -z "$REMOTE_BUILD" || ! "$REMOTE_BUILD" =~ ^[0-9]+$ ]]; then
        echo "Error: Could not retrieve the remote build."
        return 0
    fi

    if [ "$LOCAL_BUILD" != "$REMOTE_BUILD" ]; then
        return 1
    fi
    return 0
}

check_mod_update() {
    mkdir -p "$(dirname "$CACHE_FILE")"
    touch "$CACHE_FILE"
    touch "$LOG_FILE"

    while true; do
        echo "🔄 Checking for mod updates... ($(date))"

        check_dayz_update
        VALOR_UPDATE=$?
        if [ "$VALOR_UPDATE" -eq 1 ]; then
            # Captura todos os PIDs do processo real (filhos do Proton)
            SERVER_PIDS=$(pgrep -u "$USER" -f "$SERVER_EXE")
            # Verifica se o PID foi capturado com sucesso
            if [[ -n "$SERVER_PIDS" ]]; then
                echo "🛑 Closing the following PIDs: $SERVER_PIDS"
                kill $SERVER_PIDS
                sleep 2
                for pid in $SERVER_PIDS; do
                    if ps -p "$pid" > /dev/null; then
                        kill -9 "$pid"
                    fi
                done
            fi
        fi
        
        for id in "${IDS[@]}"; do
            [[ -z "$id" ]] && continue  # pula entradas vazias (como a última)
            
            MOD_URL="https://steamcommunity.com/sharedfiles/filedetails/?id=$id"
            
            HTML=$(curl -s "$MOD_URL")

            # Extrai o nome do mod
            MOD_NAME=$(echo "$HTML" | grep -oP '<div class="workshopItemTitle">.*?</div>' | sed -e 's/<[^>]*>//g' | xargs)

            # Extrai a data da última atualização
            UPDATED_DATE=$(echo "$HTML" | grep -oP '<div class="detailsStatRight">.*?</div>' | sed -e 's/<[^>]*>//g' | sed -n '3p' | xargs)

            # Converte a data para timestamp (Unix time)
            if [[ -n "$UPDATED_DATE" ]]; then
                UPDATED_DATE_EN=$(echo "$UPDATED_DATE" | sed -e 's/jan\./Jan/' -e 's/fev\./Feb/' -e 's/mar\./Mar/' -e 's/abr\./Apr/' \
                                                -e 's/mai\./May/' -e 's/jun\./Jun/' -e 's/jul\./Jul/' -e 's/ago\./Aug/' \
                                                -e 's/set\./Sep/' -e 's/out\./Oct/' -e 's/nov\./Nov/' -e 's/dez\./Dec/')

            # Remove vírgulas e "@"
            UPDATED_DATE_CLEAN=$(echo "$UPDATED_DATE" | sed -E 's/,//g; s/@//g' | xargs)

            # Se já contém ano explícito
            if [[ "$UPDATED_DATE_CLEAN" =~ [0-9]{4} ]]; then
                DATE_TO_PARSE="$UPDATED_DATE_CLEAN"
            else
                CURRENT_YEAR=$(date +%Y)
                # Move o horário para o fim: ex: "28 Feb 8:02am" -> "28 Feb 2025 8:02am"
                DATE_TO_PARSE=$(echo "$UPDATED_DATE_CLEAN $CURRENT_YEAR" | awk '{print $1, $2, $4, $3}')
            fi

            # Converte para timestamp
            MOD_TIMESTAMP=$(date -d "$DATE_TO_PARSE" +%s 2>/dev/null)
            
            else
                MOD_TIMESTAMP=0
            fi
            
            # Verifica se a conversão foi bem-sucedida
            if [[ -z "$MOD_TIMESTAMP" ]]; then
                echo "⚠️ [$id] $MOD_NAME — Error converting date.: '$UPDATED_DATE' (tratada: '$DATE_TO_PARSE')"
            fi

            # Carrega timestamp salvo
            LAST_TIMESTAMP=$(grep "^$id:" "$CACHE_FILE" | cut -d: -f2)

            # Verificação de atualização
            if [[ -z "$LAST_TIMESTAMP" ]]; then
                if [[ "$MOD_TIMESTAMP" -gt 0 ]]; then
                echo "$id:$MOD_TIMESTAMP" >> "$CACHE_FILE"
            fi
            elif [[ "$MOD_TIMESTAMP" -gt "$LAST_TIMESTAMP" ]]; then
                echo "✅ [$id] $MOD_NAME — UPDATED! New date: $UPDATED_DATE"
                sed -i "s/^$id:.*/$id:$MOD_TIMESTAMP/" "$CACHE_FILE"
                
                # Prepara mensagem
                MOD_TIMESTAMP_LOCAL=$((MOD_TIMESTAMP + 14400))
                ORIGINAL_DATE=$(date -d "@$MOD_TIMESTAMP_LOCAL" "+%d/%m/%Y %H:%M:%S")
                
                # Salva informações no log para registro de histórico e auditoria
                echo "Updated mod: $MOD_NAME - ID: $id - Data: $ORIGINAL_DATE" >> "$LOG_FILE"
                echo "------------------------------" >> "$LOG_FILE"

                # Captura todos os PIDs do processo real (filhos do Proton)
                SERVER_PIDS=$(pgrep -u "$USER" -f "$SERVER_EXE")

                # Verifica se o PID foi capturado com sucesso
                if [[ -n "$SERVER_PIDS" ]]; then
                    echo "🛑 Closing the following PIDs: $SERVER_PIDS"
                    kill $SERVER_PIDS
                    sleep 2
                    for pid in $SERVER_PIDS; do
                        if ps -p "$pid" > /dev/null; then
                            kill -9 "$pid"
                        fi
                    done
                fi
                
                # Apaga pasta do mod desatualizado
                rm -rf "$MOD_SERVER_DIR/$id"
                rm -rf "$MOD_GAME_DIR/$id"
                
                # Envia notificação ao Discord
                curl -s -X POST "$WEBHOOK_URL_MOD" \
                    -H "Content-Type: application/json" \
                    -d @- <<EOF
{
"username": "DayZ Mod Watcher",
"content": "🧩 **Updated mod!**\n📌 Nome: **$MOD_NAME**\n🆔 ID: \`$id\`\n📅 Updated on: $ORIGINAL_DATE\n🔗 $MOD_URL\n@everyone"
}
EOF
            fi

            sleep 2  # Atraso entre as requisições
        done

        sleep "$TIME_CHECK_MOD_UPDATES_IN_SEC"
    done
}

calc_restart_time() {
    nowHour=$((10#$(date +%H)))
    nowMin=$((10#$(date +%M)))

    totalNowMins=$((nowHour * 60 + nowMin))
    interval=$SERVER_RESTART_TIME_IN_MIN

    nextRestart=$(( (totalNowMins / interval + 1) * interval ))

    (( nextRestart >= 1440 )) && nextRestart=1440

    waitMins=$((nextRestart - totalNowMins))
    waitSecs=$((waitMins * 60))

    echo "$waitSecs"
}

main() {
    export STEAM_COMPAT_DATA_PATH
    export STEAM_COMPAT_CLIENT_INSTALL_PATH

    while true; do
        # ===== CÁLCULO DO TEMPO ATÉ O PRÓXIMO REINÍCIO =====
        TIME_RESTART=$(calc_restart_time | tail -n1)
        echo "⏱️ Time until next restart: $TIME_RESTART seconds"

        # Captura todos os PIDs do processo real (filhos do Proton)
        SERVER_PIDS=$(pgrep -u "$USER" -f "$SERVER_EXE")

        WAITING_TIME=$((TIME_CHECK_SERVER_CRASHED_IN_SEC + 30))

        if [[ $TIME_RESTART -lt $WAITING_TIME || -z $SERVER_PIDS ]]; then
            # ===== LIMPEZA DE LOGS =====
            echo "🧹 Deleting files .RPT, .log e .mdmp em: $SERVER_DIR/profiles"
            rm -f "$SERVER_DIR"/profiles/*.RPT "$SERVER_DIR"/profiles/*.ADM "$SERVER_DIR"/profiles/*.log "$SERVER_DIR"/profiles/*.mdmp
            rm -f "$SERVER_DIR"/profiles/WebApiLog/*.log "$SERVER_DIR"/profiles/LBmaster/Data/Core/Players/*.json "$SERVER_DIR"/profiles/ExpansionMod/Logs/*.log "$SERVER_DIR"/profiles/EventManagerLog/*.log "$SERVER_DIR"/profiles/CBD_LootSystem/Logging/Logs/*.log "$SERVER_DIR"/profiles/Bastardo_HC/logs/*.log
            rm -rf "$SERVER_DIR"/profiles/CodeLock/Logs

            if [[ -z $SERVER_PIDS ]]; then
                prepare_mods

                check_dayz_update
                VALOR_UPDATE=$?
                if [ "$VALOR_UPDATE" -eq 1 ]; then
                    echo "⬇️ Update available"
                    validate_dayz_server
                    curl -s -X POST "$WEBHOOK_URL_SERVER" \
                        -H "Content-Type: application/json" \
                        -d @- <<EOF
{
"username": "DayZ Server",
"content": "⬇️ The server has been updated!"
}
EOF
                fi
            fi

            # ===== EXECUÇÃO =====
            cd "$SERVER_DIR" || { echo "❌ Unable to access the server directory.."; exit 1; }

            if [[ -n "$SERVER_PIDS" ]]; then
                echo "🛑 Closing ongoing processes"
                kill $SERVER_PIDS
                sleep 2
                for pid in $SERVER_PIDS; do
                    if ps -p "$pid" > /dev/null; then
                        kill -9 "$pid"
                    fi
                done
            fi

            echo "🚀 Starting a DayZ server..."            
            "$PROTON_RUN" run "./$SERVER_EXE" $CONFIG $PROFILES "$MODS" "$SERVER_MODS" "$SERVER_PORT" "$SERVER_CPU" "$SERVER_OTHERS" &
            #"./$SERVER_EXE" $CONFIG $PROFILES "$MODS" "$SERVER_MODS" "$SERVER_PORT" "$SERVER_CPU" "$SERVER_OTHERS" & #Experimental branch

            SERVER_LAUNCH_PID=$!

            if ! kill -0 "$SERVER_LAUNCH_PID" 2>/dev/null; then
                echo "❌ Failed to start the server."
                exit 1
            fi

            # Aguarda um pouco para o processo iniciar
            sleep 5

            # Captura todos os PIDs do processo real (filhos do Proton)
            SERVER_PIDS=$(pgrep -u "$USER" -f "$SERVER_EXE")

            # Verifica se o PID foi capturado com sucesso
            if [[ -n "$SERVER_PIDS" ]]; then
                echo "✅ Server started with PIDs: $SERVER_PIDS"
                
                # Envia notificação ao Discord
                curl -s -X POST "$WEBHOOK_URL_SERVER" \
                    -H "Content-Type: application/json" \
                    -d @- <<EOF
{
"username": "DayZ Server",
"content": "✅ Server started successfully!"
}
EOF
            else
                echo "❌ Unable to capture the server's PID."
            fi
        fi
        sleep "$TIME_CHECK_SERVER_CRASHED_IN_SEC"
    done
}

load_credentials

validate_dayz_server

start_discord_bot

check_mod_update &

main