# ---------- STAGE 1: Build Asterisk ----------
FROM debian:12-slim AS builder

ENV ASTERISK_VERSION=20.14.0 \
    DEBIAN_FRONTEND=noninteractive

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    wget \
    subversion \
    libedit-dev \
    libssl-dev \
    libxml2-dev \
    libsqlite3-dev \
    uuid-dev \
    libjansson-dev \
    libcurl4-openssl-dev \
    libspeex-dev \
    libspeexdsp-dev \
    libsrtp2-dev \
    libopus-dev \
    libgsm1-dev \
    libpq-dev \
    libical-dev \
    libspandsp-dev \
    pkg-config \
    libncurses-dev \
    ncurses-bin \
    libmpg123-dev \
    ca-certificates

# Download and build Asterisk
RUN cd /usr/src && \
    wget -q https://downloads.asterisk.org/pub/telephony/asterisk/asterisk-${ASTERISK_VERSION}.tar.gz && \
    tar xf asterisk-${ASTERISK_VERSION}.tar.gz && \
    rm asterisk-${ASTERISK_VERSION}.tar.gz && \
    cd asterisk-${ASTERISK_VERSION} && \
    contrib/scripts/get_mp3_source.sh && \
    ./configure --with-jansson-bundled && \
    make menuselect.makeopts && \
    menuselect/menuselect --disable BUILD_NATIVE \
                          --enable chan_pjsip \
                          --disable chan_sip \
                          --disable res_http_websocket \
                          --disable app_voicemail \
                          --enable format_mp3 \
                          --disable MOH-OPSOUND-WAV \
                          --disable MOH-OPSOUND-ULAW \
                          --disable MOH-OPSOUND-ALAW \
                          --disable MOH-OPSOUND-GSM \
                          --disable CORE-SOUNDS-EN-GSM \
                          --disable CORE-SOUNDS-EN-ULAW \
                          --disable CORE-SOUNDS-EN-ALAW \
                          --enable CORE-SOUNDS-EN-WAV \
                          --disable extras \
                          menuselect.makeopts && \
    make -j$(nproc) && \
    make install && \
    make config

# ---------- STAGE 2: Runtime Image ----------
FROM debian:12-slim

ENV DEBIAN_FRONTEND=noninteractive

# Install runtime dependencies only
RUN apt-get update && apt-get install -y --no-install-recommends \
    libedit2 \
    libssl3 \
    libxml2 \
    libsqlite3-0 \
    uuid-runtime \
    libjansson4 \
    libcurl4 \
    libspeex1 \
    libspeexdsp1 \
    libsrtp2-1 \
    libopus0 \
    libgsm1 \
    libpq5 \
    libical3 \
    libspandsp2 \
    libncurses6 \
    libmpg123-0 \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Copy Asterisk from builder
COPY --from=builder /usr/sbin/asterisk /usr/sbin/asterisk
COPY --from=builder /usr/lib/ /usr/lib/
COPY --from=builder /var/lib/asterisk /var/lib/asterisk
COPY --from=builder /etc/asterisk /etc/asterisk
COPY --from=builder /var/spool/asterisk /var/spool/asterisk
COPY --from=builder /var/log/asterisk /var/log/asterisk
COPY --from=builder /usr/share/asterisk /usr/share/asterisk

# Create user and fix permissions
RUN useradd -r -d /var/lib/asterisk -M asterisk && \
    chown -R asterisk:asterisk /etc/asterisk /var/lib/asterisk /var/log/asterisk /var/spool/asterisk /usr/lib/asterisk

EXPOSE 5060/udp 5060/tcp 10000-10020/udp

USER asterisk
WORKDIR /var/lib/asterisk

CMD ["asterisk", "-f"]
