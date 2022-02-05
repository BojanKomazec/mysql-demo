ARG DOCKER_REPOSITORY_URL=docker.io
ARG BASE_DOCKER_IMAGE_NAME=ubuntu
ARG BASE_DOCKER_IMAGE_TAG=latest

FROM ${DOCKER_REPOSITORY_URL}/${BASE_DOCKER_IMAGE_NAME}:${BASE_DOCKER_IMAGE_TAG}

LABEL maintainer="bojan.komazec@gmail.com"

ARG DOCKER_ENTRYPOINT=docker-entrypoint.sh
ARG APP_NAME=mysqlsh-demo
COPY ./${DOCKER_ENTRYPOINT} /usr/src/${APP_NAME}/

WORKDIR /usr/src/${APP_NAME}/
RUN chmod +x /usr/src/${APP_NAME}/${DOCKER_ENTRYPOINT}

# Use for debugging only: ARG substitution test
# RUN pwd && ls -la /usr/src/$APP_NAME/

# If using Alpine:
# RUN apk update && apk add --no-cache mysql-client
# RUN apt-get update && apt-get install mysql-apt-config

# If using Ubuntu:
# (MySQL APT config package download url is obtained from https://dev.mysql.com/downloads/repo/apt/)
RUN apt update && \
    apt install -y wget && \
    wget https://dev.mysql.com/get/mysql-apt-config_0.8.22-1_all.deb && \
    apt install -y lsb-release && \
    apt install -y gnupg && \
    DEBIAN_FRONTEND=noninteractive dpkg -i ./mysql-apt-config_0.8.22-1_all.deb && \
    rm -f ./mysql-apt-config_0.8.22-1_all.deb
RUN apt-get update && apt-get install -y mysql-shell

# ARGs are available only in build time but not runtime so we need to pass their values to ENVs:
ENV APP_NAME=${APP_NAME}
ENV DOCKER_ENTRYPOINT=${DOCKER_ENTRYPOINT}

ENTRYPOINT "/usr/src/${APP_NAME}/${DOCKER_ENTRYPOINT}"