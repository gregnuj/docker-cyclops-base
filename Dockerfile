FROM debian:stretch-slim
LABEL MAINTAINER="Greg Junge <gregnuj@gmail.com>"
USER root

# To enable build behind proxy
ARG http_proxy

# Install packages
RUN set -ex \
	&& apt-get update \
	&& apt-get install -y \
        apt-transport-https \
        ca-certificates \
        curl \
        cron \
        git \
        ssh \
        openssl \
        socat \
        sudo \
        supervisor \
        vim \
        wget \
	--no-install-recommends \
	&& rm -r /var/lib/apt/lists/*

# Add files
ADD ./rootfs /

RUN /usr/sbin/adduser -D -u 999 -G wheel -s /bin/bash cyclops && \
    echo '%wheel ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers

ENV SHELL=/bin/bash \
    EDITOR=/usr/local/bin/vim

USER cyclops
WORKDIR /home/cyclops
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["/bin/bash", "-l"]

