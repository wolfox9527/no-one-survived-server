FROM silentmecha/no-one-survived-server:latest

ENV AUTO_UPDATE=False

RUN bash steamcmd \
	+@sSteamCmdForcePlatformType windows \
	+force_install_dir "${STEAMAPPDIR}" \
	+login ${STEAM_LOGIN} \
	+app_update "${STEAMAPP_ID}" validate \
	+quit
