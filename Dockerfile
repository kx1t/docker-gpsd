FROM ghcr.io/sdr-enthusiasts/docker-baseimage:qemu
RUN declare -rx DEBIAN_FRONTEND=noninteractive && \
declare -rx NEEDRESTART_MODE=a && \
export DEBIAN_FRONTEND && \
export NEEDRESTART_MODE && \
apt update && \
apt remove unattended-upgrades -y && \
apt install --no-install-recommends gpsd gpsd-clients ntp ntpdate -y && \
apt upgrade -y && \
apt autoremove -y && \
apt autoclean
COPY ./filesource /path/fileDest
EXPOSE 2947
#ENTRYPOINT ["/bin/sh", "-c", "/sbin/syslogd -S -O - -n & exec /usr/sbin/gpsd -N -n -G ${*}","--"]
