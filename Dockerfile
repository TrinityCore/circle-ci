FROM debian:12-slim AS base

ENV DEBIAN_FRONTEND=noninteractive

# Runtime only equirements
RUN apt-get update \
 && apt-get install -y \
 sudo lsb-release gnupg wget ca-certificates tar gzip ssh git \
 libboost-filesystem1.74 libboost-locale1.74 libboost-program-options1.74 libboost-regex1.74 libboost-system1.74 libboost-thread1.74 libssl3 libreadline8 zlib1g libbz2-1.0 \
 && wget https://dev.mysql.com/get/mysql-apt-config_0.8.29-1_all.deb -O /tmp/mysql-apt-config_all.deb \
 && dpkg -i /tmp/mysql-apt-config_all.deb \
 && apt-get update \
 && apt-get install -y libmysqlclient21 mysql-client \
 && echo "circleci ALL=NOPASSWD: ALL" >> /etc/sudoers.d/circleci \
 && echo "Defaults    env_keep += \"DEBIAN_FRONTEND\"" >> /etc/sudoers.d/circleci \
 && groupadd --gid=1002 circleci \
 && useradd --uid=1001 --gid=circleci --create-home circleci \
 && sudo -u circleci mkdir /home/circleci/project \
 && sudo -u circleci mkdir /home/circleci/bin \
 && sudo -u circleci mkdir -p /home/circleci/.local/bin \
 && echo "circleci:circleci" | chpasswd

# CI compile time image
FROM base AS builder

# -dev versions of all packages
RUN apt-get update \
 && apt-get install -y \
 cmake clang g++- make ninja-build \
 libboost-dev libboost-filesystem-dev libboost-locale-dev libboost-program-options-dev libboost-regex-dev libboost-system-dev libboost-thread-dev libssl-dev libreadline-dev zlib1g-dev libbz2-dev ccache \
 && install -m 0755 -d /etc/apt/keyrings \
 && wget https://download.docker.com/linux/debian/gpg -O /etc/apt/keyrings/docker.asc \
 && chmod a+r /etc/apt/keyrings/docker.asc \
 && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null \
 && apt-get update \
 && apt-get install -y libmysqlclient-dev docker-ce \
 && wget https://github.com/powerman/dockerize/releases/download/v0.8.0/dockerize-linux-x86_64 -O /usr/local/bin/dockerize \
 && chmod +x /usr/local/bin/dockerize \
 && update-alternatives --install /usr/bin/cc cc /usr/bin/clang 100 \
 && update-alternatives --install /usr/bin/c++ c++ /usr/bin/clang++ 100 \
 && rm -rf /var/lib/apt/lists/*

COPY scripts/ /scripts/
RUN chmod a+x -R /scripts

USER circleci
WORKDIR /home/circleci/project

#Setup
RUN git config --global user.email "circleci@build.bot" && git config --global user.name "Circle CI"

# Runtime image
FROM base AS runner

USER circleci
WORKDIR /home/circleci
