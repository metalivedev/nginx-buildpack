#!/bin/bash
# Build NGINX and modules on Heroku.
# This program is designed to run in a web dyno provided by Heroku.
# We would like to build an NGINX binary for the builpack on the
# exact machine in which the binary will run.
# Our motivation for running in a web dyno is that we need a way to
# download the binary once it is built so we can vendor it in the buildpack.
#
# Once the dyno has is 'up' you can open your browser and navigate
# this dyno's directory structure to download the nginx binary.

# dotCloud nginx version is 1.2.1. 
# Nearest from http://nginx.org/en/download.html is 1.2.9
# Latest                                         is 1.7.4
NGINX_VERSION=1.2.9

nginx_tarball_url=http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz
temp_dir=$(mktemp -d /tmp/nginx.XXXXXXXXXX)

echo "Serving files from /tmp on $PORT"
cd /tmp
python -m SimpleHTTPServer $PORT &

cd $temp_dir
echo "Temp dir: $temp_dir"

echo "Downloading $nginx_tarball_url"
curl -L $nginx_tarball_url | tar xzv

# dotCloud configuration 
# $ nginx -V 
# nginx version: nginx/1.2.1 
# TLS SNI support enabled 
# configure arguments: 
# --add-module=/build/buildd/nginx-1.2.1/debian/modules/nginx-auth-pam
# --add-module=/build/buildd/nginx-1.2.1/debian/modules/nginx-dav-ext-module
# --add-module=/build/buildd/nginx-1.2.1/debian/modules/nginx-echo
# --add-module=/build/buildd/nginx-1.2.1/debian/modules/nginx-upstream-fair
# --conf-path=/etc/nginx/nginx.conf
# --error-log-path=/var/log/nginx/error.log
# --http-client-body-temp-path=/var/lib/nginx/body
# --http-fastcgi-temp-path=/var/lib/nginx/fastcgi
# --http-log-path=/var/log/nginx/access.log
# --http-proxy-temp-path=/var/lib/nginx/proxy
# --http-scgi-temp-path=/var/lib/nginx/scgi
# --http-uwsgi-temp-path=/var/lib/nginx/uwsgi
# --lock-path=/var/lock/nginx.lock 
# --pid-path=/var/run/nginx.pid
# --prefix=/etc/nginx
# --with-debug 
# --with-http_addition_module
# --with-http_dav_module 
# --with-http_geoip_module
# --with-http_gzip_static_module 
# --with-http_image_filter_module
# --with-http_realip_module 
# --with-http_ssl_module 
# --with-http_stub_status_module
# --with-http_sub_module
# --with-http_xslt_module 
# --with-ipv6 
# --with-mail 
# --with-mail_ssl_module
# --with-md5=/usr/include/openssl 
# --with-pcre-jit 
# --with-sha1=/usr/include/openssl

# Removed for successful build
#
# --with-http_geoip_module \
# ./configure: error: the GeoIP module requires the GeoIP library.
# --with-http_image_filter_module 
# ./configure: error: the HTTP image filter module requires the GD library.
#	    --with-md5=/usr/include/openssl \
#	    --with-sha1=/usr/include/openssl
# libmd5.a and libsha.a are not on the pinky system under /usr/lib/

(
	cd nginx-${NGINX_VERSION}

	chmod +x ./configure

	./configure \
	    --prefix=/tmp/nginx \
	    --with-pcre-jit \
 	    --with-debug \
	    --with-http_addition_module \
	    --with-http_gzip_static_module \
	    --with-http_realip_module \
	    --with-ipv6 \
	    --with-http_stub_status_module \
	    --with-http_sub_module \
	    --with-http_xslt_module \
	    --with-http_dav_module

	make install

	# verify build. Will show in logs.
	echo "--- VERIFY BUILD:"
	./objs/nginx -V 
	echo "--- ------ ------"
)

while true
do
	sleep 1
	echo "."
done
