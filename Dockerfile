FROM alpine:3.12 as builder

ARG REPO=https://github.com/pvpgn/pvpgn-server.git
ARG BRANCH=1.99.7.2.1
ARG WITH_MYSQL=true
ARG WITH_LUA=true

### Install build dependencies
# hadolint ignore=DL3018
RUN apk add --no-cache \
    build-base \
    clang \
    cmake \
    git \
    lua-dev \
    make \
    mariadb-dev \
    zlib-dev \
    ;

### CMake & make
RUN git clone --single-branch --branch ${BRANCH} ${REPO} /src
WORKDIR /src/build
RUN mkdir /usr/local/pvpgn
RUN cmake \
  -D WITH_MYSQL=${WITH_MYSQL} \
  -D WITH_LUA=${WITH_LUA} \
  -D CMAKE_INSTALL_PREFIX=/usr/local/pvpgn \
  -w \
  ../

### Install
RUN make -j 10 && make -j 10 install

##########################

FROM alpine:3.12 as runner

### Install dependencies
# hadolint ignore=DL3018
RUN apk add --no-cache \
    ca-certificates \
    libgcc \
    libstdc++ \
    lua5.1-libs \
    mariadb-connector-c \
    ;

### Copy build files
COPY --from=builder /usr/local/pvpgn /usr/local/pvpgn

### Make volume folders
RUN mkdir -p \
    /usr/local/pvpgn/etc \
    /usr/local/pvpgn/var \
    ;

### persist data and configs
VOLUME /usr/local/pvpgn/var
VOLUME /usr/local/pvpgn/etc

# expose served network ports
EXPOSE 6112 4000

### RUN!
CMD ["/usr/local/pvpgn/sbin/bnetd", "-f"]
