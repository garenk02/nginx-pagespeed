###
# Nginx with Pagespeed
###

FROM debian:wheezy

MAINTAINER ball6847@gmail.com

# Version
ENV NGINX_VERSION 1.9.9
ENV NPS_VERSION 1.9.32.10

# Install Build Tools & Dependence
RUN echo "deb-src http://http.debian.net/debian wheezy main\ndeb-src http://http.debian.net/debian wheezy-updates main\ndeb-src http://security.debian.org/ wheezy/updates main" >> /etc/apt/sources.list

RUN apt-get update && \
    apt-get install -y build-essential zlib1g-dev libpcre3 libpcre3-dev libssl-dev wget && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# ===========
# Build Nginx
# ===========

# Setting Up ENV
ENV MODULE_DIR /usr/src/nginx-modules

# Create Module Directory
RUN mkdir ${MODULE_DIR}

# Download Source
RUN cd /usr/src && \
    wget -q http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz && \
    tar xzf nginx-${NGINX_VERSION}.tar.gz && \
    rm -rf nginx-${NGINX_VERSION}.tar.gz && \

    # Install Addational Module
    cd ${MODULE_DIR} && \
    wget -q --no-check-certificate https://github.com/pagespeed/ngx_pagespeed/archive/release-${NPS_VERSION}-beta.tar.gz && \
    tar zxf release-${NPS_VERSION}-beta.tar.gz && \
    rm -rf release-${NPS_VERSION}-beta.tar.gz && \
    cd ngx_pagespeed-release-${NPS_VERSION}-beta/ && \
    wget -q --no-check-certificate https://dl.google.com/dl/page-speed/psol/${NPS_VERSION}.tar.gz && \
    tar zxf ${NPS_VERSION}.tar.gz && \
    rm -rf ${NPS_VERSION}.tar.gz && \

    # Compile Nginx
    cd /usr/src/nginx-${NGINX_VERSION} && \
    ./configure \
    --prefix=/etc/nginx \
    --sbin-path=/usr/sbin/nginx \
    --conf-path=/etc/nginx/nginx.conf \
    --pid-path=/var/run/nginx.pid \
    --lock-path=/var/run/nginx.lock \
    --error-log-path=/var/log/nginx/error.log \
    --http-log-path=/var/log/nginx/access.log \
    --with-http_ssl_module \
    --with-http_gzip_static_module \
    --with-http_v2_module \
    --add-module=${MODULE_DIR}/ngx_pagespeed-release-${NPS_VERSION}-beta && \

    # Install Nginx
    cd /usr/src/nginx-${NGINX_VERSION} && \
    make && make install && \

    # Clear source code to reduce container size
    rm -rf /usr/src/*

ADD conf/nginx.conf /etc/nginx/nginx.conf

# Forward requests and errors to docker logs
RUN ln -sf /dev/stdout /var/log/nginx/access.log
RUN ln -sf /dev/stderr /var/log/nginx/error.log

VOLUME ["/var/cache/nginx", "/var/cache/ngx_pagespeed"]

EXPOSE 80 443

CMD ["nginx", "-g", "daemon off;"]

