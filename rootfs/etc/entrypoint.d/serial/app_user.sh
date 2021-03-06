#!/bin/bash

export APP_UID="${APP_UID:-10000}"
export APP_GID="${APP_GID:-${APP_UID}}"
export APP_USER="${APP_USER:-cyclops}"
export APP_HOME="${APP_HOME:-/home/${APP_USER}}"
export APP_GROUP="${APP_GROUP:-${APP_USER}}"
export APP_EMAIL="${APP_EMAIL:-${APP_USER}}"
export APP_SUDO="${APP_SUDO}"
export APP_SSH="${APP_SSH:-${APP_HOME}/.ssh}"
export APP_KEY="${APP_KEY:-${APP_SSH}/id_rsa}"
export APP_AUTH="${APP_AUTH:-${APP_SSH}/authorized_keys}"
export APP_SECRET="${APP_SECRET:-/var/run/secrets/app_password}"
export CRON_MAILTO="${CRON_MAILTO:-${APP_EMAIL}}"

# script name for logging
TAG="$(basename $0 '.sh')"

# creeate user
if [ -n "$(getent passwd ${APP_USER})" ]; then
    echo "${TAG}: User exists ${APP_USER} skipping creation"
else
    echo "${TAG}: Creating user ${APP_USER} (${APP_UID}) in group ${APP_GROUP} (${APP_GID})"
    if [ "${APP_UID}" -lt 256000 ]; then
        addgroup -g ${APP_GID} ${APP_GROUP}
        adduser -D -u ${APP_UID} -G ${APP_USER} -s /bin/bash ${APP_USER}
    else 
        # Create user https://stackoverflow.com/questions/41807026/cant-add-a-user-with-a-high-uid-in-docker-alpine
        echo "${APP_USER}:x:${APP_UID}:${APP_GID}::${APP_HOME}:/bin/bash" >> /etc/passwd
        echo "${APP_USER}:!:$(($(date +%s) / 60 / 60 / 24)):0:99999:7:::" >> /etc/shadow
        echo "${APP_GROUP}:x:${APP_GID}:" >> /etc/group
        cp -a /etc/skel ${APP_HOME}
        chown -R ${APP_USER}:${APP_GROUP} ${APP_HOME}
    fi

    # Get/change passwd (for sudo)
    if [ -z "${APP_PASSWD}" ]; then
        # Create password if it does not exist
        if [ ! -f "${APP_SECRET}" ]; then
            mkdir -p "$(dirname ${APP_SECRET})"
            openssl rand -base64 10 > ${APP_SECRET}
        fi
        APP_PASSWD="$(echo -n $(cat ${APP_SECRET}))"
    fi
    echo "${TAG}: Setting password for ${APP_USER}"
    echo "${APP_USER}:${APP_PASSWD}" | chpasswd

    # update sudoers
    if [ -n "${APP_SUDO}" ]; then
        echo "${TAG}: Adding sudo for ${APP_SUDO}"
        echo "${APP_SUDO} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
    fi

    # APP user can sudo supervisorctl
    echo "${TAG}: Adding sudo for supervisorctl for ${APP_USER}"
    echo "${APP_USER} ALL=(ALL) NOPASSWD: /usr/bin/supervisorctl" >> /etc/sudoers

    # add ssh key
    echo "${TAG}: Adding ssh key in ${APP_SSH}"
    mkdir -p ${APP_SSH}
    if [ -f "${APP_KEY}" ]; then
        cp ${APP_KEY} ${APP_SSH}/$(basename ${APP_KEY})
        chmod 400 ${APP_SSH}/$(basename ${APP_KEY})
        if [ -f "${APP_KEY}.pub" ]; then
            cat "${APP_KEY}.pub" >> ${APP_AUTH}
        else
            ssh-keygen -y -f ${APP_KEY} >> ${APP_AUTH}
        fi
    else
        ssh-keygen -q -t rsa -N '' -f ${APP_KEY}
        cat ${APP_KEY}.pub >> ${APP_AUTH}
    fi
fi

# needed for setup.ini
echo "${TAG}: Setting ownership for ${APP_HOME}"
chown -R ${APP_USER}:${APP_GROUP} ${APP_HOME}

# msmtp
touch /var/log/msmtp/${APP_USER}.log
chown -R ${APP_USER}:${APP_GROUP} /var/log/msmtp/${APP_USER}.log

# use APP_HOME as HOME
export HOME="${APP_HOME}"

