#### step1、entrypoint.sh编写

```bash
#!/bin/bash

set -e


if [ "$1" = 'apache2-foreground' ] && [ "$(id -u)" = '0' ]; then
	chown -R www-data /var/www/html
	chmod -R 777 /var/www/html/    
fi


if [ ! -e '/var/www/html/index.php' ]; then
	su - www-data -s /bin/bash -c 'cp -a /usr/src/typecho/* /var/www/html/'
fi


exec "$@"
```

注：

> 修改该文件的权限，否则可能在创建容器阶段，无法成功
>
> ```shell
> # root 用户下
> chmod 777 entrypoint.sh
> ```

#### step2、Dockerfile编写

```dockerfile
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
```

注：

> `/etc/apache2/ssl`为存放证书的路径，创建容器时需要将该路径映射出来。该路径下文件命名规则如下：
>
> | 初始证书名                                                   | 修改后证书名 |
> | ------------------------------------------------------------ | ------------ |
> | [www.example.com_public.crt](http://www.example.com_public.crt/) | server.crt   |
> | [www.example.com_chain.crt](http://www.example.com_chain.crt/) | ca.crt       |
> | [www.example.com.key](http://www.example.com.key/)           | server.key   |
>

创建镜像

```shell
docker build -t chemistryhuang/typecho .
```

创建容器

```shell
docker run -d --name=typecho --restart=always  -p 80:80 -p 443:443 -v /typecho/path/:/var/www/html -v /ssl/path/ssl/:/etc/apache2/ssl/ chemistryhuang/typecho
```

注：

> 运行上述创建容器命令前，确保`/ssl/path/ssl/`路径下的证书文件已经存在且已修改证书名，方可成功
