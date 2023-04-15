FROM        debian:buster-slim

LABEL       MAINTAINER="https://github.com/Hermsi1337/"

ARG         ARK_TOOLS_VERSION="1.6.61a"
ARG         IMAGE_VERSION="dev"
ARG         PUID=1000

ENV         USER steam
ENV         HOMEDIR "/home/${USER}"
ENV         STEAMCMDDIR "${HOMEDIR}/steamcmd"

ENV         IMAGE_VERSION="${IMAGE_VERSION}" \
            SESSION_NAME="Dockerized ARK Server by github.com/hermsi1337" \
            SERVER_MAP="TheIsland" \
            SERVER_PASSWORD="YouShallNotPass" \
            ADMIN_PASSWORD="Th155houldD3f1n3tlyB3Chang3d" \
            MAX_PLAYERS="20" \
            GAME_MOD_IDS="" \
            UPDATE_ON_START="false" \
            BACKUP_ON_STOP="false" \
            PRE_UPDATE_BACKUP="true" \
            WARN_ON_STOP="true" \
            ARK_TOOLS_VERSION="${ARK_TOOLS_VERSION}" \
            ARK_SERVER_VOLUME="/app" \
            TEMPLATE_DIRECTORY="/conf.d" \
            GAME_CLIENT_PORT="7777" \
            UDP_SOCKET_PORT="7778" \
            RCON_PORT="27020" \
            SERVER_LIST_PORT="27015" \
            STEAM_HOME="/home/${USER}" \
            STEAM_USER="${USER}" \
            STEAM_LOGIN="anonymous"

ENV         ARK_TOOLS_DIR="${ARK_SERVER_VOLUME}/arkmanager"

RUN         set -x && \
            apt-get update && \
            apt-get install -y --no-install-recommends --no-install-suggests \
                                lib32stdc++6 \
                                ca-certificates \
                                locales \
                                perl-modules \
                                curl \
                                lsof \
                                libc6-i386 \
                                lib32gcc1 \
                                bzip2 \
                                gosu \
                                cron && \
            sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
            dpkg-reconfigure --frontend=noninteractive locales && \
            useradd -u "${PUID}" -m "${USER}" && \            
            su "${USER}" -c \
		"mkdir -p \"${STEAMCMDDIR}\" \
		&& curl -fsSL 'https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz' | tar xvzf - -C \"${STEAMCMDDIR}\" \
		&& \"./${STEAMCMDDIR}/steamcmd.sh\" +quit \
		&& mkdir -p \"${HOMEDIR}/.steam/sdk32\" \
		&& ln -s \"${STEAMCMDDIR}/linux32/steamclient.so\" \"${HOMEDIR}/.steam/sdk32/steamclient.so\" \
		&& ln -s \"${STEAMCMDDIR}/linux32/steamcmd\" \"${STEAMCMDDIR}/linux32/steam\" \
		&& ln -s \"${STEAMCMDDIR}/steamcmd.sh\" \"${STEAMCMDDIR}/steam.sh\"" && \
            ln -s "${STEAMCMDDIR}/linux64/steamclient.so" "/usr/lib/x86_64-linux-gnu/steamclient.so" && \
            curl -L "https://github.com/arkmanager/ark-server-tools/archive/v${ARK_TOOLS_VERSION}.tar.gz" \
                | tar -xvzf - -C /tmp/ && \
            bash -c "cd /tmp/ark-server-tools-${ARK_TOOLS_VERSION}/tools && bash -x install.sh ${USER}" && \
            ln -s /usr/local/bin/arkmanager /usr/bin/arkmanager && \
            install -d -o ${USER} ${ARK_SERVER_VOLUME} && \
            su ${USER} -c "bash -x ${STEAMCMDDIR}/steamcmd.sh +login anonymous +quit" && \
            apt-get -qq autoclean && apt-get -qq autoremove && apt-get -qq clean && \
            rm -rf /tmp/* /var/cache/* /var/lib/apt/lists/*

COPY        bin/    /
COPY        conf.d  ${TEMPLATE_DIRECTORY}

EXPOSE      ${GAME_CLIENT_PORT}/udp ${UDP_SOCKET_PORT}/udp ${SERVER_LIST_PORT}/udp ${RCON_PORT}/tcp

VOLUME      ["${ARK_SERVER_VOLUME}"]
WORKDIR     ${ARK_SERVER_VOLUME}

ENTRYPOINT  ["/docker-entrypoint.sh"]
CMD         []
