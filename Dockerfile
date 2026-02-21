FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y \
    curl git build-essential libpcre3 libpcre3-dev zlib1g zlib1g-dev \
    libssl-dev pkg-config ca-certificates && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /usr/src

RUN curl -O https://nginx.org/download/nginx-1.16.1.tar.gz && \
    tar xzf nginx-1.16.1.tar.gz

RUN git clone --recursive https://github.com/cloudflare/quiche

WORKDIR /usr/src/nginx-1.16.1
RUN patch -p01 < ../quiche/extras/nginx/nginx-1.16.patch

RUN ./configure \
    --prefix=/etc/nginx \
    --sbin-path=/usr/sbin/nginx \
    --modules-path=/usr/lib/nginx/modules \
    --conf-path=/etc/nginx/nginx.conf \
    --error-log-path=/var/log/nginx/error.log \
    --http-log-path=/var/log/nginx/access.log \
    --pid-path=/var/run/nginx.pid \
    --lock-path=/var/run/nginx.lock \
    --with-http_ssl_module \
    --with-http_v2_module \
    --with-http_v3_module \
    --with-openssl=../quiche/deps/boringssl \
    --with-quiche=../quiche && \
    make && make install

WORKDIR /etc/nginx

EXPOSE 80 443/tcp 443/udp

CMD ["nginx", "-g", "daemon off;"]