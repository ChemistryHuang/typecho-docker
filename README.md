# typecho-docker
docker typecho ssl证书设置
创建镜像

```shell
docker build -t chemistryhuang/typecho .
```
证书命名规范
www.example.com_public.crt ---->server.crt
www.example.com_chain.crt ----->ca.crt
www.example.com.key --->server.key

创建容器

```shell
docker run -d --name=typecho --restart=always  -p 80:80 -p 443:443 -v /typecho/path/:/var/www/html -v /ssl/path/ssl/:/etc/apache2/ssl/ chemistryhuang/typecho
```

