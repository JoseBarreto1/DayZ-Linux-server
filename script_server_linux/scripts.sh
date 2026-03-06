#!/bin/bash

SERVER_DIR="$HOME/.steam/steam/steamapps/common/DayZServer"
SCRIPT_DIR="$SERVER_DIR/script_server_linux"

"$SCRIPT_DIR/mod_update_checker.sh" &
exec "$SCRIPT_DIR/start_server.sh"