FROM ubuntu:bionic AS build

RUN apt-get update -y && apt-get install -y \
    build-essential libtool autotools-dev automake pkg-config bsdmainutils \
    python3 libevent-dev libboost-dev libboost-system-dev \
    libboost-filesystem-dev libboost-test-dev libdb++-dev git

RUN git clone -b v1.0 https://github.com/dynamofoundation/dynamo-core.git /dynamo/dynamo-core

WORKDIR /dynamo/dynamo-core
RUN ./autogen.sh
RUN ./configure --with-incompatible-bdb

# The makefile fails, but the binaries we need get built - wtf?
RUN make || true

FROM ubuntu:bionic AS production

# Stolen from mariadb dockerfile: add our user and group first to make sure
# their IDs get assigned consistently
RUN groupadd -r dmo && useradd -r -g dmo dmo

EXPOSE 6432 6433

RUN apt-get update -y && apt-get install -y \
  libevent-dev libboost-dev libboost-system-dev libboost-filesystem-dev libboost-test-dev libdb++-dev && \
  apt-get autoremove -y && \
  apt-get clean && rm -rf /var/lib/apt/lists/* 

WORKDIR /dynamo
COPY --from=build /dynamo/dynamo-core/src/bitcoind /bin/dynamo-core
COPY --from=build /dynamo/dynamo-core/src/bitcoin-cli /bin/dynamo-cli
COPY cli /bin/ 
RUN chmod +x /bin/cli
COPY dynamo.conf /dynamo/dynamo.conf
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
RUN mkdir -p /dynamo/data
RUN chown -R dmo:dmo /dynamo
VOLUME /dynamo/data

USER dmo
ENTRYPOINT ["/entrypoint.sh"]
