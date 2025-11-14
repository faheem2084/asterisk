FROM debian:12-slim
ENV DEBIAN_FRONTEND=noninteractive ASTERISK_VERSION=22.6.0
RUN groupadd -r asterisk && useradd -r -g asterisk asterisk && apt-get update && apt-get install -y --no-install-recommends \
    build-essential wget git subversion pkg-config python3 ca-certificates libncurses5-dev libssl-dev libxml2-dev \
    libsqlite3-dev unixodbc-dev libjansson-dev uuid-dev libedit-dev libsndfile1-dev libcurl4-openssl-dev libgsm1-dev \
    libogg-dev libvorbis-dev libnewt-dev libpopt-dev libical-dev libspeex-dev libspeexdsp-dev liblua5.1-0-dev \
    libcorosync-common-dev && rm -rf /var/lib/apt/lists/* && apt-get clean && cd /usr/src && \
    wget -q https://downloads.asterisk.org/pub/telephony/asterisk/releases/asterisk-${ASTERISK_VERSION}.tar.gz && \
    tar xf asterisk-${ASTERISK_VERSION}.tar.gz && rm asterisk-${ASTERISK_VERSION}.tar.gz && \
    cd asterisk-${ASTERISK_VERSION} && ./configure --with-jansson-bundled && make menuselect.makeopts && \
    menuselect/menuselect --enable res_odbc --enable cdr_adaptive_odbc --enable app_voicemail --enable pbx_realtime menuselect.makeopts && \
    make -j$(nproc) && make install && make samples && make config && ldconfig && \
    apt-get purge -y --auto-remove build-essential wget git subversion pkg-config && apt-get autoremove -y && \
    rm -rf /usr/src/asterisk-${ASTERISK_VERSION} /var/lib/apt/lists/* && mkdir -p /etc/asterisk /var/lib/asterisk /var/log/asterisk /var/spool/asterisk && \
    chown -R asterisk:asterisk /etc/asterisk /var/lib/asterisk /var/log/asterisk /var/spool/asterisk
EXPOSE 5060/udp 5060/tcp 5061/tcp 10000-20000/udp
USER asterisk
ENTRYPOINT ["/usr/sbin/asterisk", "-f", "-U", "asterisk", "-G", "asterisk", "-vvv"]





