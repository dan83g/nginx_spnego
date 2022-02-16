FROM alpine:3.12

ENV NGINX_VERSION 1.21.6

RUN set -ex \
  && apk add --no-cache \
    git \
    nano \
    krb5 \
    krb5-dev \
    ca-certificates \
    openssl \
    pcre \
    zlib \
    mercurial \
    # timezone
    tzdata \
    # envsubst
    gettext \
  && apk add --no-cache --virtual .build-deps \
    build-base \
    linux-headers \
    openssl-dev \
    pcre-dev \
    wget \
    zlib-dev \
    perl-dev \
    libxml2-dev \
    libxslt-dev \
  && cd /tmp \
  && wget http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz \
  && tar xzf nginx-${NGINX_VERSION}.tar.gz \
  && git clone https://github.com/stnoonan/spnego-http-auth-nginx-module.git nginx-${NGINX_VERSION}/spnego-http-auth-nginx-module \
  && git clone https://github.com/arut/nginx-dav-ext-module.git nginx-${NGINX_VERSION}/nginx-dav-ext-module \
  && hg clone http://hg.nginx.org/njs nginx-${NGINX_VERSION}/ngx_http_js_module

  RUN cd /tmp/nginx-${NGINX_VERSION} \
  && ./configure \
    \
    --prefix=/etc/nginx \
    --sbin-path=/usr/sbin/nginx \
    --conf-path=/etc/nginx/nginx.conf \
    --modules-path=/usr/lib/nginx/modules \
    --error-log-path=/var/log/nginx/error.log \
    --http-log-path=/var/log/nginx/access.log \
    --pid-path=/var/run/nginx.pid \
    --lock-path=/var/run/nginx.lock \
    --user=nginx \
    --group=nginx \
    --with-compat \
    --with-threads \
    --with-file-aio \
    --with-http_ssl_module \
    --with-http_v2_module \
    --with-http_realip_module \
    --with-http_addition_module \
    --with-http_sub_module \
    --with-http_dav_module \
    --with-http_flv_module \
    --with-http_mp4_module \
    --with-http_gunzip_module \
    --with-http_gzip_static_module \
    --with-http_auth_request_module \
    --with-http_random_index_module \
    --with-http_secure_link_module \
    --with-http_slice_module \
    --with-http_stub_status_module \
    --http-client-body-temp-path=/var/cache/nginx/client_temp \
    --http-proxy-temp-path=/var/cache/nginx/proxy_temp \
    --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
    --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
    --http-scgi-temp-path=/var/cache/nginx/scgi_temp \
    --with-mail \
    --with-mail_ssl_module \
    --with-stream \
    --with-stream_ssl_module \
    --with-stream_realip_module \
    --with-stream_ssl_preread_module \
    --add-module=nginx-dav-ext-module \
    --add-module=spnego-http-auth-nginx-module \
    --add-module=ngx_http_js_module/nginx \
    --with-cc-opt='-Os -fomit-frame-pointer' \
    --with-ld-opt=-Wl,--as-needed \
  && make -j$(getconf _NPROCESSORS_ONLN) \
  && make install \
  && sed -i -e 's/#access_log  logs\/access.log  main;/access_log \/dev\/stdout;/' -e 's/#error_log  logs\/error.log  notice;/error_log stderr notice;/' /etc/nginx/nginx.conf \
  && adduser -D nginx \
  && mkdir -p /var/cache/nginx \
  && apk del .build-deps \
  && rm -rf /tmp/* \
  && addgroup -S docker \
  && adduser -D -S -g docker dockeruser \
  && mkdir -p /var/lib/nginx /var/log/nginx /var/cache/nginx \
  && chown -R dockeruser:docker /var/lib/nginx /var/log/nginx /var/cache/nginx \
  && chmod -R 755 /var/lib/nginx /var/log/nginx /var/cache/nginx \ 
  && touch /var/run/nginx.pid /var/run/nginx.lock \
  && chown -R dockeruser:docker /var/run/nginx.pid /var/run/nginx.lock

  USER dockeruser
  WORKDIR /etc/nginx
  EXPOSE 80 443
  CMD ["nginx", "-g", "daemon off;"]
