FROM mariadb:10.9
MAINTAINER Oriol Boix Anfosso orboan@entorn.io

LABEL version="1.0"
LABEL description="Asix - Projecte 1"

ARG language=ca_ES

ENV \
    USER=alumne \
    PASSWORD=alumne \
    LANG="${language}.UTF-8" \
    LC_CTYPE="${language}.UTF-8" \
    LC_ALL="${language}.UTF-8" \
    LANGUAGE="${language}:ca" \
    REMOVE_DASH_LINECOMMENT=true \
    SHELL=/bin/bash 
ENV \
    HOME="/home/$USER" \
    DEBIAN_FRONTEND="noninteractive" \
    RESOURCES_PATH="/resources" \
    SSL_RESOURCES_PATH="/resources/ssl"
ENV \
    WORKSPACE_HOME="${HOME}" \
    MYSQL_ALLOW_EMPTY_PASSWORD=true \
    MYSQL_USER="$USER" \ 
    MYSQL_PASSWORD="$PASSWORD"

    
# Layer cleanup script
COPY resources/scripts/*.sh  /usr/bin/
RUN chmod +x /usr/bin/clean-layer.sh /usr/bin/fix-permissions.sh


# Make folders
RUN \
    mkdir -p $RESOURCES_PATH && chmod a+rwx $RESOURCES_PATH && \
    mkdir -p $SSL_RESOURCES_PATH && chmod a+rwx $SSL_RESOURCES_PATH && \
    mkdir -p /etc/supervisor /var/lock/apache2 /var/run/apache2 /var/run/sshd /var/log/supervisor /var/logs /var/run/supervisor

## locales
RUN \
    if [ "$language" != "en_US" ]; then \
        apt-get -y update; \
        DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends locales; \
        echo "${language}.UTF-8 UTF-8" > /etc/locale.gen; \
        locale-gen; \
        dpkg-reconfigure --frontend=noninteractive locales; \
        update-locale LANG="${language}.UTF-8"; \
    fi \
    && clean-layer.sh

# install basics
RUN \
  apt update -y && \
  if ! which gpg; then \
  	apt-get install -y --no-install-recommends gnupg; \
  fi; \
  clean-layer.sh
RUN \
  apt update -y && \ 
  DEBIAN_FRONTEND=noninteractive \
  apt-get install -y --no-install-recommends \
  apt-transport-https \
  ca-certificates \
  build-essential \
  software-properties-common \
  libcurl4 \
  curl \
  apt-utils \
  vim \    
  iputils-ping \
  ssh \
  fonts-dejavu \
  git \
  wget \
  openssl \
  libssl-dev \
  libgdbm-dev \
  libncurses5-dev \
  libncursesw5-dev \
  libmysqlclient-dev \
  libpq-dev \
  bash-completion \
  zip \
  gzip \
  unzip \
  bzip2 \
  lzop \
  tzdata \
  sudo && \
  clean-layer.sh
  
RUN \
    apt update -y && \
    apt -y install supervisor openssh-server apache2 mariadb-server && \
    clean-layer.sh

# - Generate keys for ssh. 
# (This is usually done by systemd when sshd service is started)
RUN \ 
rm -rf /etc/ssh/*key* && \
ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key -N '' \
&& ssh-keygen -t dsa  -f /etc/ssh/ssh_host_dsa_key -N '' \
&& ssh-keygen -t ecdsa -f /etc/ssh/ssh_host_ecdsa_key -N '' \
&& chmod 600 /etc/ssh/*

# - Configure SSH daemon...
RUN \
  sed -i -r 's/.?UseDNS\syes/UseDNS no/' /etc/ssh/sshd_config && \
  sed -i -r 's/.?PasswordAuthentication.+/PasswordAuthentication yes/' /etc/ssh/sshd_config && \
  sed -i -r 's/.?ChallengeResponseAuthentication.+/ChallengeResponseAuthentication no/' /etc/ssh/sshd_config && \
  sed -i -r 's/.?PermitRootLogin.+/PermitRootLogin no/' /etc/ssh/sshd_config

# - Adding keyfiles configuration
RUN \
  sed -ri 's/^HostKey\ \/etc\/ssh\/ssh_host_ed25519_key/#HostKey\ \/etc\/ssh\/ssh_host_ed25519_key/g' /etc/ssh/sshd_config && \
  sed -ri 's/^#HostKey\ \/etc\/ssh\/ssh_host_dsa_key/HostKey\ \/etc\/ssh\/ssh_host_dsa_key/g' /etc/ssh/sshd_config && \
  sed -ri 's/^#HostKey\ \/etc\/ssh\/ssh_host_rsa_key/HostKey\ \/etc\/ssh\/ssh_host_rsa_key/g' /etc/ssh/sshd_config && \
  sed -ri 's/^#HostKey\ \/etc\/ssh\/ssh_host_ecdsa_key/HostKey\ \/etc\/ssh\/ssh_host_ecdsa_key/g' /etc/ssh/sshd_config && \
  sed -ri 's/UsePAM yes/#UsePAM yes/g' /etc/ssh/sshd_config

# Disable SSH strict host key checking: needed to access git via SSH in non-interactive mode
RUN \
  echo -e "StrictHostKeyChecking no" >> /etc/ssh/ssh_config


ADD resources/etc /etc/

ADD resources $RESOURCES_PATH/

RUN \
   sed -ri "s/alumne/${USER}/g" /etc/supervisor/supervisord.conf && \
   sed -ri "s/alumne/${PASSWORD}/g" /etc/supervisor/supervisord.conf


EXPOSE 22 9001 80 443 3306

RUN chmod +x $RESOURCES_PATH/config/*.sh $RESOURCES_PATH/config/init/* 

ENTRYPOINT ["/resources/config/bootstrap.sh"]

# Place VOLUME statement below all changes to /var/lib/mysql
# VOLUME /var/lib/mysql

HEALTHCHECK --start-period=5m \
  CMD mariadb -e 'SELECT @@datadir;' || exit 1
