ARG         ALPINE_VERSION="${ALPINE_VERSION:-edge-amd64}"
FROM        alpine:"${ALPINE_VERSION}"

LABEL       maintainer="https://github.com/starwarsfan"
LABEL       org.label-schema.description="Extended fork of Hermsi1337/docker-sshd"

ARG         OPENSSH_VERSION="${OPENSSH_VERSION:-8.8_p1-r4}"
ENV         CONF_VOLUME="/conf.d"
ENV         OPENSSH_VERSION="${OPENSSH_VERSION}" \
            CACHED_SSH_DIRECTORY="${CONF_VOLUME}/ssh" \
            AUTHORIZED_KEYS_VOLUME="${CONF_VOLUME}/authorized_keys" \
            ROOT_KEYPAIR_LOGIN_ENABLED="false" \
            ROOT_LOGIN_UNLOCKED="false" \
            USER_LOGIN_SHELL="/bin/zsh" \
            USER_LOGIN_SHELL_FALLBACK="/bin/bash"

RUN         apk add --upgrade --no-cache \
                    alpine-zsh-config \
                    bash \
                    bash-completion \
                    curl \
                    git \
                    htop \
                    mc \
                    nano \
                    rsync \
                    openssh=${OPENSSH_VERSION} \
                    zsh \
            && \
            mkdir -p /root/.ssh "${CONF_VOLUME}" "${AUTHORIZED_KEYS_VOLUME}" \
            && \
            cp -a /etc/ssh "${CACHED_SSH_DIRECTORY}" \
            && \
            rm -rf /var/cache/apk/*

# Install oh-my-zsh
RUN cd /root/ \
 && sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

COPY entrypoint.sh /
COPY root/ /root/
COPY etc/motd /etc/

# - Set permissions of oh-my-zsh directory
# - Set zsh as shell for root
# - Redirect /var/log/wtmp as it is not existing
RUN chmod 755 /root/.oh-my-zsh \
 && sed -i "s#/bin/ash#/bin/zsh#g" /etc/passwd \
 && ln -s /dev/null /var/log/wtmp

EXPOSE      22
VOLUME      ["/etc/ssh"]
ENTRYPOINT  ["/entrypoint.sh"]
