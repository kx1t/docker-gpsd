FROM debian:bullseye-20230208-slim

ENV S6_BEHAVIOUR_IF_STAGE2_FAILS=2 \
    S6OVERLAY_VERSION=v2.2.0.3

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# hadolint ignore=DL3008,SC2086
RUN set -x && \
    TEMP_PACKAGES=() && \
    KEPT_PACKAGES=() && \
    # packages needed to install
    TEMP_PACKAGES+=(git) && \
    # logging
    KEPT_PACKAGES+=(gawk) && \
    KEPT_PACKAGES+=(pv) && \
    # required for S6 overlay
    # curl kept for healthcheck
    TEMP_PACKAGES+=(file) && \
    KEPT_PACKAGES+=(curl) && \
    TEMP_PACKAGES+=(xz-utils) && \
    KEPT_PACKAGES+=(ca-certificates) && \
    # bc for scrips and healthchecks
    KEPT_PACKAGES+=(bc) && \
    # packages for network stuff
    KEPT_PACKAGES+=(socat) && \
    KEPT_PACKAGES+=(ncat) && \
    KEPT_PACKAGES+=(net-tools) && \
    KEPT_PACKAGES+=(wget) && \
    # process management
    KEPT_PACKAGES+=(procps) && \
    # install packages
    KEPT_PACKAGES+=(dnsutils) && \
    KEPT_PACKAGES+=(gpsd) && \
    KEPT_PACKAGES+=(gpsd-clients) && \
    KEPT_PACKAGES+=(htop) && \
    KEPT_PACKAGES+=(ntp) && \
    KEPT_PACKAGES+=(ntpdate) && \
    KEPT_PACKAGES+=(screen) && \
    KEPT_PACKAGES+=(telnet) && \
    KEPT_PACKAGES+=(tzdata) && \
    ## Builder fixes...
    mkdir -p /usr/sbin/ && \
    ln -s /usr/bin/dpkg-split /usr/sbin/dpkg-split && \
    ln -s /usr/bin/dpkg-deb /usr/sbin/dpkg-deb && \
    ln -s /bin/tar /usr/sbin/tar && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        "${KEPT_PACKAGES[@]}" \
        "${TEMP_PACKAGES[@]}" \
        && \
    # install S6 Overlay
    curl --location --output /tmp/deploy-s6-overlay.sh https://raw.githubusercontent.com/mikenye/deploy-s6-overlay/master/deploy-s6-overlay.sh && \
    sh /tmp/deploy-s6-overlay.sh && \
    rm -f /tmp/deploy-s6-overlay.sh && \
    # deploy healthchecks framework
    git clone \
      --depth=1 \
      https://github.com/mikenye/docker-healthchecks-framework.git \
      /opt/healthchecks-framework \
      && \
    rm -rf \
      /opt/healthchecks-framework/.git* \
      /opt/healthchecks-framework/*.md \
      /opt/healthchecks-framework/tests \
      && \
    # Clean up
    apt-get remove -y "${TEMP_PACKAGES[@]}" && \
    apt-get autoremove -y && \
    rm -rf /src/* /tmp/* /var/lib/apt/lists/*

ADD https://raw.githubusercontent.com/sdr-enthusiasts/Buster-Docker-Fixes/main/00-libseccomp2 /etc/cont-init.d/00-libsecomp2
#
COPY --chown=root:root ./rootfs/ /
# Expose gpsd port tcp://2947
EXPOSE 2947
# Launch init (s6-overlay) when starting container
ENTRYPOINT [ "/init", "--" ]