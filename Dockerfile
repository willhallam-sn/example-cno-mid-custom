# ################
# 1st Stage: Use openjdk 8 to verify signature w/ jarsigner
# ################
FROM openjdk:8-jdk AS download_verification

RUN apt-get -q update && \
		apt-get install -qy wget && \
        apt-get clean && \
        rm -rf /var/lib/apt/lists/* && \
        rm -rf /tmp/*

ARG MID_INSTALLATION_URL=<your MID install URL here>
ARG MID_INSTALLATION_FILE
ARG MID_SIGNATURE_VERIFICATION="TRUE"

WORKDIR /opt/snc_mid_server/

COPY asset/*.zip asset/download.sh asset/validate_signature.sh ./

# download.sh and validate_signature.sh
RUN chmod 6750 /opt/snc_mid_server/*.sh

RUN echo "Check MID installer URL: ${MID_INSTALLATION_URL} or Local installer: ${MID_INSTALLATION_FILE}"

# Download the installation ZIP file or using the local one
RUN if [ -z "$MID_INSTALLATION_FILE" ] ; \
    then /opt/snc_mid_server/download.sh $MID_INSTALLATION_URL ; \
    else echo "Use local file: $MID_INSTALLATION_FILE" && ls -alF /opt/snc_mid_server/ && mv /opt/snc_mid_server/$MID_INSTALLATION_FILE /tmp/mid.zip ; fi

# Verify mid.zip signature
RUN if [ "$MID_SIGNATURE_VERIFICATION" = "TRUE" ] ; \
    then echo "Verify the signature of the installation file" && /opt/snc_mid_server/validate_signature.sh /tmp/mid.zip; \
    else echo "Skip signature validation of the installation file "; fi

RUN unzip -d /opt/snc_mid_server/ /tmp/mid.zip && \
    rm -rf /tmp/mid.zip /opt/snc_mid_server/agent/jre



# ################
# Final Stage (using the downloaded ZIP file from previous stage)
# ################
FROM almalinux:latest

ENV JAVA_HOME=/opt/java/openjdk
COPY --from=eclipse-temurin:11 $JAVA_HOME $JAVA_HOME

RUN yum install -y dnf
RUN dnf install -y 'dnf-command(config-manager)' && \
    dnf config-manager --set-enabled crb && \
    dnf install -y epel-release

RUN dnf upgrade -y && \
    dnf install -y bind-utils \
                    xmlstarlet \
                    procps \
                    net-tools && \
    dnf clean packages && \
    rm -rf /tmp/*
# ##########################
# Build argument definition
# ##########################

# To maintain one recipe for OpenShift and K8S cluster we have added parameter MID_GROUP
# Based on this parameter the non root container of OpenShift will run with orbotrary use and group root
# For other K8S cluster we will run user 1001 and group 1001 by default.
# Do not forget to specify the user and group inside the deployment YAML
ARG MID_USERNAME=mid
ARG MID_GROUP=mid
ARG GROUP_ID=1001
ARG USER_ID=1001

# ############################
# Runtime Env Var Definition
# ############################

# Mandatory Env Var
ENV MID_INSTANCE_URL="" \
    MID_INSTANCE_USERNAME="" \
    MID_INSTANCE_PASSWORD="" \
    MID_SERVER_NAME="" \
# Optional Env Var
    MID_PROXY_HOST="" \
    MID_PROXY_PORT="" \
    MID_PROXY_USERNAME="" \
    MID_PROXY_PASSWORD="" \
    MID_SECRETS_FILE="" \
    MID_MUTUAL_AUTH_PEM_FILE="" \
    MID_WRAPPER_wrapper.java.command="/opt/java/openjdk/bin/java"

# only copy needed scripts and .container
COPY asset/init asset/.container asset/check_health.sh asset/backup_config.sh asset/pre_stop.sh /opt/snc_mid_server/

# Allow running as an unprivileged user:
# - General case is the $MID_USERNAME user
# - OpenShift uses a random UID for user and group root
#
# Containerd does not preserve permissions when mounting a volume on top
# of an empty folder. Creating .placeholder files as a workaround.
#
# ============= OpenShift ============================
RUN if [ "$MID_GROUP" = "root" ]; then \
      echo "Building OpenShift container" && \
      adduser --system --no-create-home --shell=/sbin/nologin --gid $MID_GROUP $MID_USERNAME && \
      chmod -R g+wrx /opt/snc_mid_server/ && \
      chown -R $MID_USERNAME:$MID_GROUP /opt/snc_mid_server/; \
  else \
# ============= Other K8S Cluster ============================ \
    echo "Building K8S container" && \
    if [[ -z "${GROUP_ID}" ]]; then GROUP_ID=1001; fi && \
    		if [[ -z "${USER_ID}" ]]; then USER_ID=1001; fi && \
            echo "Add GROUP id: ${GROUP_ID}, USER id: ${USER_ID} for username: ${MID_USERNAME}" && \
    groupadd -g $GROUP_ID $MID_USERNAME && \
    useradd -c "MID container user" -r -m -u $USER_ID -g $MID_GROUP $MID_USERNAME && \
    # 6:setuid + setgid, 750: a:rwx, g:rx, o:
    chmod 6750 /opt/snc_mid_server/* && \
    chown -R $MID_USERNAME:$MID_GROUP /opt/snc_mid_server/;\
  fi

# Copy agent/ from download_verification
COPY --chown=$MID_USERNAME:$MID_GROUP  --from=download_verification /opt/snc_mid_server/agent/ /opt/snc_mid_server/agent/

# Check if the wrapper PID file exists and a HeartBeat is processed in the last 30 minutes
HEALTHCHECK --interval=5m --start-period=3m --retries=3 --timeout=15s \
    CMD bash check_health.sh || exit 1

WORKDIR /opt/snc_mid_server/

USER $MID_USERNAME


ENTRYPOINT ["/opt/snc_mid_server/init", "start"]

