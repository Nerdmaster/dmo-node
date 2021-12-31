FROM ubuntu:bionic AS build

WORKDIR /dynamo

RUN apt-get update -y
RUN apt-get install -y build-essential libtool autotools-dev automake pkg-config bsdmainutils python3
RUN apt-get install -y libevent-dev libboost-dev libboost-system-dev libboost-filesystem-dev libboost-test-dev libdb++-dev
RUN apt-get install -y git
RUN git clone -b v1.0 https://github.com/dynamofoundation/dynamo-core.git
WORKDIR /dynamo/dynamo-core
RUN echo "#!/bin/bash" > make-dynamo.sh
RUN echo "/usr/bin/make " >> make-dynamo.sh
RUN echo "exit 0" >> make-dynamo.sh
RUN chmod 755 ./make-dynamo.sh
RUN ./autogen.sh
RUN ./configure --with-incompatible-bdb
RUN ./make-dynamo.sh || echo "failed!"

FROM ubuntu:bionic AS production

EXPOSE 6432 6433

RUN apt-get update -y && apt-get install -y \
  libevent-dev libboost-dev libboost-system-dev libboost-filesystem-dev libboost-test-dev libdb++-dev && \
  apt-get autoremove -y && \
  apt-get clean && rm -rf /var/lib/apt/lists/* 
RUN mkdir ~/.dynamo
WORKDIR /dynamo/dynamo-core
COPY --from=build /dynamo/dynamo-core/src/bitcoind /bin/dynamo-core
COPY --from=build /dynamo/dynamo-core/src/bitcoin-cli /bin/dynamo-cli
COPY get-info.sh /bin/ 

CMD ["dynamo-core"]

