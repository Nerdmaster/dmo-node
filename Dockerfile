FROM ubuntu:bionic

EXPOSE 6432 6433

WORKDIR /dynamo

RUN apt-get update && \
    apt-get install -y build-essential libtool autotools-dev automake pkg-config bsdmainutils python3 && \
    apt-get install -y libevent-dev libboost-dev libboost-system-dev libboost-filesystem-dev libboost-test-dev libdb++-dev && \
    apt-get install -y git && \
    mkdir ~/.dynamo && \
    git clone -b v1.0 https://github.com/dynamofoundation/dynamo-core.git && \
    cd dynamo-core && \
    echo "#!/bin/bash" > make-dynamo.sh && \
    echo "/usr/bin/make " >> make-dynamo.sh && \
    echo "exit 0" >> make-dynamo.sh && \
    chmod 755 ./make-dynamo.sh && \
    ./autogen.sh && \
    ./configure --with-incompatible-bdb && \
    ./make-dynamo.sh || echo "failed!" && \
    cp ./src/bitcoind /bin/dynamo-core && \
    cp ./src/bitcoin-cli /bin/dynamo-cli && \
    cd .. && rm -rfv dynamo-core && \
    apt-get remove -y build-essential libtool autotools-dev automake pkg-config bsdmainutils python3 && \
    apt-get autoremove -y && \
    apt-get clean && rm -rf /var/lib/apt/lists/* 

COPY get-info.sh /bin/ 
	
	
CMD ["dynamo-core"]

