FROM ubuntu:18.04
MAINTAINER Xinran Chen

ENV DEBIAN_FRONTEND=noninteractive

# ====== upgrade apt-get ======
RUN apt-get update && \
    apt-get install -y git lsb-core software-properties-common  build-essential xz-utils ocaml ocamlbuild automake autoconf libtool wget python libssl-dev libcurl4-openssl-dev protobuf-compiler libprotobuf-dev sudo kmod vim curl git-core libprotobuf-c0-dev libboost-thread-dev libboost-system-dev liblog4cpp5-dev libjsoncpp-dev alien uuid-dev libxml2-dev cmake pkg-config expect systemd-sysv gdb \
        nginx

WORKDIR /root

# ====== install Rust ======
RUN curl https://sh.rustup.rs -sSf | sh -s -- -y && \
	export PATH="$PATH:$HOME/.cargo/bin" && \
	rustup toolchain install nightly && \
	rustup target add wasm32-unknown-unknown --toolchain nightly

# ====== install sgx-sdk ======

ENV sdk_bin https://download.01.org/intel-sgx/sgx-linux/2.7.1/distro/ubuntu18.04-server/sgx_linux_x64_sdk_2.7.101.3.bin
ENV psw_deb https://download.01.org/intel-sgx/sgx-linux/2.7.1/distro/ubuntu18.04-server/libsgx-enclave-common_2.7.101.3-bionic1_amd64.deb
ENV psw_dev_deb https://download.01.org/intel-sgx/sgx-linux/2.7.1/distro/ubuntu18.04-server/libsgx-enclave-common-dev_2.7.101.3-bionic1_amd64.deb
ENV psw_dbgsym_deb https://download.01.org/intel-sgx/sgx-linux/2.7.1/distro/ubuntu18.04-server/libsgx-enclave-common-dbgsym_2.7.101.3-bionic1_amd64.ddeb
ENV rust_toolchain nightly-2019-11-25

RUN mkdir /root/sgx && \
    mkdir -p /etc/init && \
    wget -O /root/sgx/psw.deb ${psw_deb} && \
    wget -O /root/sgx/psw_dev.deb ${psw_dev_deb} && \
    wget -O /root/sgx/psw_dbgsym.deb ${psw_dbgsym_deb} && \
    wget -O /root/sgx/sdk.bin ${sdk_bin} && \
    cd /root/sgx && \
    dpkg -i /root/sgx/psw.deb && \
    dpkg -i /root/sgx/psw_dev.deb && \
    dpkg -i /root/sgx/psw_dbgsym.deb && \
    chmod +x /root/sgx/sdk.bin && \
    echo -e 'no\n/opt' | /root/sgx/sdk.bin && \
    echo 'source /opt/sgxsdk/environment' >> /root/.bashrc && \
    rm -rf /root/sgx/* && \
    /bin/bash -c "source /opt/sgxsdk/environment"

ENV SGX_SDK /opt/sgxsdk
ENV PATH /root/.cargo/bin:$PATH:$SGX_SDK/bin:$SGX_SDK/bin/x64
ENV PKG_CONFIG_PATH $PKG_CONFIG_PATH:$SGX_SDK/pkgconfig
ENV  LD_LIBRARY_PATH $SGX_SDK/sdk_libs

# ====== install llvm-9 ======
RUN wget https://apt.llvm.org/llvm.sh && chmod +x llvm.sh && ./llvm.sh 9

# ====== clean up ======
RUN rm -rf /var/lib/apt/lists/* && \
    rm -rf /var/cache/apt/archives/*

# ====== download Phala ======
RUN git clone https://github.com/Phala-Network/phala-pruntime.git && \
    git clone https://github.com/Phala-Network/phala-blockchain.git

# ====== build phala ======

RUN echo "*********build blockchain********"
RUN cd phala-blockchain && git submodule update --init
COPY ./substrate.diff  phala-blockchain/substrate/

RUN cd phala-blockchain/substrate/ && git apply substrate.diff
RUN cd phala-blockchain/node && sh ./scripts/console.sh wrap-build

RUN echo "*********build phost**********"
RUN cd phala-blockchain/phost && sh ./scripts/console.sh build --release 

RUN echo "*********build pruntime**********"
RUN cd phala-pruntime && git submodule update --init && SGX_MODE=SW make

# ====== clean up ======

COPY ./cleanup.sh .
RUN bash cleanup.sh

# ====== start phala ======
COPY startup.sh .
COPY apis.conf /etc/nginx/sites-enabled/default
CMD sh ./startup.sh
