FROM silentmecha/steamcmd-wine:latest

LABEL maintainer="silent@silentmecha.co.za"

ENV STEAMAPP_ID=2329680
ENV STEAMAPP=NoOneSurvived
ENV STEAMAPPDIR="${HOME}/${STEAMAPP}-dedicated"
ENV STEAM_SAVEDIR="${STEAMAPPDIR}/WRSH/Saved"
ENV STEAM_BACKUPDIR="${STEAM_SAVEDIR}/backup"
ENV STEAM_LOGIN=anonymous

USER root

COPY ./src/. ${HOME}/

ARG DEBIAN_FRONTEND=noninteractive
RUN set -x \
	&& apt-get update \
	&& apt-get install -y --no-install-recommends --no-install-suggests \
		crudini \
	&& apt-get autoremove -y \
	&& rm -rf /var/lib/apt/lists/*

RUN set -x \
	&& mkdir -p "${STEAMAPPDIR}" \
	&& mkdir -p "${STEAM_SAVEDIR}" \
 	&& mkdir -p "${STEAMAPPDIR}/_CommonRedist/vcredist/2022/" \
  	&& wget -O "${STEAMAPPDIR}/_CommonRedist/vcredist/2022/VC_redist.x64.exe" "https://aka.ms/vs/17/release/vc_redist.x64.exe" \
	&& chmod +x "${HOME}/entry.sh" \
	&& chown -R "${USER}:${USER}" "${HOME}/entry.sh" "${HOME}/Game.ini" "${STEAMAPPDIR}" \
	&& chmod -R 755 "${STEAM_SAVEDIR}" "${HOME}/Game.ini"

ENV MAP=Map01 \
	SERVERNAME=DockerTestServer \
	SERVERPASSWORD= \
	SERVERADMINPASSWORD=ChangeMe \
	MAXPLAYERS=20 \
	PORT=7777 \
	QUERYPORT=27015 \
	ADDITIONAL_ARGS=

# Switch to user
USER ${USER}

VOLUME "${STEAM_SAVEDIR}"

EXPOSE 	${PORT}/udp \
        ${QUERYPORT}/udp

WORKDIR ${HOME}

CMD ["bash", "entry.sh"]
