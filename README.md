# typecho-docker
docker typecho ssl证书设置
创建镜像

```shell
docker# docker build -t chemistryhuang/typecho .
```

创建容器

```shell
docker# docker run -d --name=typecho --restart=always  -p 80:80 -p 443:443 -v /typecho/path/:/var/www/html -v /ssl/path/ssl/:/etc/apache2/ssl/ chemistryhuang/typecho
```

