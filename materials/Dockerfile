FROM debian:stable-slim as build

ENV HOME /root

# Install necessary packages
RUN apt-get update && \
    apt-get install -y \
        build-essential \
        automake \
        libcurl4-openssl-dev \
        make \
        libssl-dev \
        pkg-config \
        autoconf \
        libtool \
        libjansson-dev \
        cmake \
        python3 \
        vim \
        nano \
        tmux \
        wget \
        tar \
        git \
        curl \
        cargo

RUN curl https://sh.rustup.rs -sSf | bash -s -- -y --default-toolchain 1.75.0 && \
    ln -s $HOME/.cargo/bin/rustc /usr/local/bin/rustc && \
    ln -s $HOME/.cargo/bin/cargo /usr/local/bin/cargo && \
    ln -s $HOME/.cargo/bin/rustup /usr/local/bin/rustup

# Clone and build cpuminer from source
RUN wget https://github.com/pooler/cpuminer/archive/refs/tags/v2.5.1.tar.gz -O /tmp/cpuminer.tar.gz && \
    mkdir -p /cpuminer && \
    tar -xvf /tmp/cpuminer.tar.gz -C /cpuminer --strip-components=1 && \
    cd /cpuminer && \
    ./autogen.sh && \
    ./configure CFLAGS="-O3" && \
    make -j$(nproc) && \
    cp minerd /usr/local/bin/

ENV BITCOIN_RELEASE_TAG=sv2-tp-0.1.17
ENV BITCOIN_DIR=bitcoin-$BITCOIN_RELEASE_TAG

RUN mkdir -p $BITCOIN_DIR

RUN ARCH=$(dpkg --print-architecture) && \
    if [ "$ARCH" = "amd64" ]; then \
        BITCOIN_URL=https://github.com/Sjors/bitcoin/releases/download/$BITCOIN_RELEASE_TAG/bitcoin-$BITCOIN_RELEASE_TAG-x86_64-linux-gnu.tar.gz; \
    elif [ "$ARCH" = "arm64" ]; then \
        BITCOIN_URL=https://github.com/Sjors/bitcoin/releases/download/$BITCOIN_RELEASE_TAG/bitcoin-$BITCOIN_RELEASE_TAG-aarch64-linux-gnu.tar.gz; \
    else \
        echo "Unsupported architecture"; exit 1; \
    fi && \
    wget $BITCOIN_URL -O /tmp/bitcoin.tar.gz

# Extract the downloaded tarball
RUN tar -xzvf /tmp/bitcoin.tar.gz -C $BITCOIN_DIR --strip-components=1

# Cleanup
RUN rm /tmp/bitcoin.tar.gz

# Make bitcoin binaries available in $PATH
RUN cp $BITCOIN_DIR/bin/bitcoind /usr/local/bin/bitcoind
RUN cp $BITCOIN_DIR/bin/bitcoin-cli /usr/local/bin/bitcoin-cli

# # Ensure necessary directories are created
RUN mkdir -p $HOME/.bitcoin-sv2-workshop

ARG CACHE_BUST

# Clone the Stratum repository, checkout the workshop branch, and build all roles
RUN cd $HOME && \
    git clone https://github.com/stratum-mining/stratum && \
    cd stratum && \
    git checkout workshop

# Copy and run the tmux setup script
COPY setup-tmux.sh /usr/local/bin/setup-tmux.sh
RUN chmod +x /usr/local/bin/setup-tmux.sh
RUN /usr/local/bin/setup-tmux.sh

# Set the working directory to the user's home directory
WORKDIR $HOME

CMD ["bash"]
