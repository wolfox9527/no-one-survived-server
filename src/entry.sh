#!/bin/bash

# Function to clean up on SIGTERM and SIGINT
function clean_up() {
    echo "Shutting down server..."
    kill -SIGINT "$serverPID"    # Gracefully stop the server
    kill "$tailPID"              # Stop tail
    wait "$serverPID"             # Wait for server process to exit
    exit 0
}

# Function to check if VC++ Redistributable is installed via Wine registry
function is_vcredist_installed {
    wine reg query "HKLM\\Software\\Microsoft\\VisualStudio\\14.0\\VC\\Runtimes\\x64" /v Installed > /dev/null 2>&1
    return $?
}

# Set up trap for SIGTERM and SIGINT
trap "clean_up" SIGTERM SIGINT

if [ $AUTO_UPDATE ]; then
    steamcmd \
	+@sSteamCmdForcePlatformType windows \
	+force_install_dir "${STEAMAPPDIR}" \
	+login ${STEAM_LOGIN} \
	+app_update "${STEAMAPP_ID}" validate \
	+quit
fi

# Define the log file path
LOG_FILE="${STEAM_SAVEDIR}/Logs/WRSH.log"

# Define server ini settings paths
GAME_INI="${STEAM_SAVEDIR}/Config/WindowsServer/Game.ini"
ENGINE_INI="${STEAM_SAVEDIR}/Config/WindowsServer/Engine.ini"

# Check if the log file exists; create it if it doesn't
if [ ! -f "$LOG_FILE" ]; then
    echo "Log file does not exist, creating $LOG_FILE"
    touch "$LOG_FILE"
fi

# Check if Game.ini exists
if [ ! -f "$GAME_INI" ]; then
    cp "${HOME}/Game.ini" "${GAME_INI}"
fi

# Initial Wine configuration
if [ ! -d "${HOME}/.wine" ]; then
    echo "Configuring wine for the first time"
    xvfb-run wine wineboot --init
fi

# Install VC++ Redistributable if not detected in the registry
if ! is_vcredist_installed; then
    echo "Installing VC++ Redistributable"
    xvfb-run wine "${STEAMAPPDIR}/_CommonRedist/vcredist/2022/VC_redist.x64.exe" /quiet /install
fi

# Change to the application directory
cd "${STEAMAPPDIR}"

# Check if MAP is valid map name
if [[ "${MAP}" != "Map01" && "${MAP}" != "Map02" ]]; then
    echo "Using default map"
    MAP="Map01"
fi

# Configure Server Game.ini using crudini
crudini --set "${GAME_INI}" "ServerSetting" "ServerName" "${SERVERNAME}"
crudini --set "${GAME_INI}" "ServerSetting" "OpenMap" "${MAP}"
crudini --set "${GAME_INI}" "ServerSetting" "MaxPlayers" "${MAXPLAYERS}"
crudini --set "${GAME_INI}" "ServerSetting" "AdminPassword" "${SERVERADMINPASSWORD}"

# Configure Server Engine.ini using crudini
crudini --set "${ENGINE_INI}" "URL" "Port" "${PORT}"
crudini --set "${ENGINE_INI}" "OnlineSubsystemSteam" "GameServerQueryPort" "${QUERYPORT}"

# Enable server password if set using crudini
if [ -z "${SERVERPASSWORD}" ]; then
    crudini --set "${GAME_INI}" "ServerSetting" "NeedPassword" False
else
    crudini --set "${GAME_INI}" "ServerSetting" "NeedPassword" True
    crudini --set "${GAME_INI}" "ServerSetting" "Password" "${SERVERPASSWORD}"
fi


# Start the server with Wine and capture its PID
xvfb-run wine StartServer.bat > /dev/null 2>&1 & 
serverPID=$!

# Tail the log file and capture the PID for cleanup
tail -f "$LOG_FILE" &
tailPID=$!

# Wait for the server process to exit
wait "$serverPID"

# Cleanup in case of server exit
clean_up
