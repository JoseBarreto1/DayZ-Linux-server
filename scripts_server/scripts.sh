#!/bin/bash

SERVER_DIR="$HOME/.steam/steam/steamapps/common/DayZServer"
SCRIPT_DIR="$SERVER_DIR/scripts_server"

"$SCRIPT_DIR/mod_update_checker.sh" &
exec "$SCRIPT_DIR/start_server.sh"