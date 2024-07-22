FROM ubuntu:22.04

# Set environment variable to make apt-get install non-interactive
ENV DEBIAN_FRONTEND=noninteractive
ENV HOME /root

# Install necessary packages
RUN apt-get update && \
    apt-get install -y \
        build-essential \
        curl \
        git \
        vim \
        nano \
        python3 \
        python3-pip \
        rustc \
        cargo \
        wget \
        tar \
        libc6 \
        automake \
        libcurl4-openssl-dev \
        make \
        file \
        libc-bin \
        libboost-all-dev \
        libevent-dev \
        libminiupnpc-dev \
        libzmq3-dev \
        libssl-dev \
        pkg-config \
        autoconf \
        libtool \
        bsdmainutils \
        g++-11 \
        libjansson-dev \
        tmux \
        libdb-dev \
        libdb++-dev \
        libsqlite3-dev

# Set g++-11 as the default compiler
RUN update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-11 100

# Clone and build the Bitcoin fork from source with wallet support
RUN git clone --branch sv2 https://github.com/Sjors/bitcoin /bitcoin-sv2 && \
    cd /bitcoin-sv2 && \
    ./autogen.sh && \
    ./configure --disable-tests --disable-bench --enable-wallet --with-gui=no && \
    make -j$(nproc) && \
    cp src/bitcoind /usr/local/bin/ && \
    cp src/bitcoin-cli /usr/local/bin/

# Clone and build cpuminer from source
RUN wget https://github.com/pooler/cpuminer/archive/refs/tags/v2.5.1.tar.gz -O /tmp/cpuminer.tar.gz && \
    mkdir -p /cpuminer && \
    tar -xvf /tmp/cpuminer.tar.gz -C /cpuminer --strip-components=1 && \
    cd /cpuminer && \
    ./autogen.sh && \
    ./configure CFLAGS="-O3" && \
    make -j$(nproc) && \
    cp minerd /usr/local/bin/

# Ensure necessary directories are created
RUN mkdir -p $HOME/.bitcoin-sv2-workshop

# Clone the Stratum repository, checkout the workshop branch, and build all roles
RUN cd $HOME && \
    git clone https://github.com/stratum-mining/stratum && \
    cd stratum && \
    git checkout workshop && \
    cd roles && \
    cargo build

# Copy and run the tmux setup script
COPY setup-tmux.sh /usr/local/bin/setup-tmux.sh
RUN chmod +x /usr/local/bin/setup-tmux.sh
RUN /usr/local/bin/setup-tmux.sh

# Set the working directory to the user's home directory
WORKDIR $HOME

CMD ["bash"]
