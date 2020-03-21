FROM php:apache

ENV TYPECHO_URL="http://typecho.org/build.tar.gz"

RUN set -x \
  && mkdir -p /usr/src/typecho \
  && apt-get update && apt-get install -y --no-install-recommends ca-certificates wget && rm -rf /var/lib/apt/lists/* \
  && wget -qO- "$TYPECHO_URL" | tar -xz -C /usr/src/typecho/ --strip-components=1 \
  && apt-get purge -y --auto-remove ca-certificates wget \
  && rm -rf /tmp/*

WORKDIR /var/www/html

COPY entrypoint.sh /usr/local/bin/

RUN a2enmod rewrite
RUN a2enmod ssl

RUN sed -i \
        -e 's/\/etc\/ssl\/certs\/ssl-cert-snakeoil.pem/\/etc\/apache2\/ssl\/server.crt/g' \
        -e 's/\/etc\/ssl\/private\/ssl-cert-snakeoil.key/\/etc\/apache2\/ssl\/server.key/g' \
        -e 's/\/etc\/apache2\/ssl.crt\/server-ca.crt/\/etc\/apache2\/ssl\/ca.crt/g' \
        -e 's/#SSLCertificateChainFile/SSLCertificateChainFile/g' \
        /etc/apache2/sites-available/default-ssl.conf

RUN sed -i \
        -e '13a <Directory "/var/www/html">' \
        -e '13a RewriteEngine   on' \
        -e '13a RewriteBase /' \
        -e '13a # FORCE HTTPS' \
        -e '13a RewriteCond %{HTTPS} !=on' \
        -e '13a RewriteRule ^/?(.*) https://%{SERVER_NAME}/$1 [R,L]' \
        -e '13a </Directory>' \
        /etc/apache2/sites-available/000-default.conf

RUN ln -s /etc/apache2/sites-available/default-ssl.conf /etc/apache2/sites-enabled/default-ssl.conf

EXPOSE 80
EXPOSE 443

ENTRYPOINT ["entrypoint.sh"]
CMD ["apache2-foreground"]
