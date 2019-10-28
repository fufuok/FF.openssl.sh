#!/bin/bash
# author: Fufu, 2019-10-28
# CA 自签发证书, 支持 IOS 13
#
export PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin

# 建立 CA 证书目录
mkdir -p ./demoCA/{private,newcerts} &&
    touch ./demoCA/index.txt &&
    touch ./demoCA/serial &&
    echo '001' >./demoCA/serial

# 生成 CA 根密钥, 指定密码参数: -passout pass: ***, 不加 -aes256 则无密码
openssl genrsa -aes256 -out ./demoCA/private/cakey.pem 4096

# 导出 CA key 文件(将之后的 cakey.pem 换为 ca.key 则不需要密码, 或使用 -passin pass:***)
# openssl rsa -in ./demoCA/private/cakey.pem -out ./demoCA/private/ca.key

# 生成证书请求
openssl req -new -sha256 \
    -key ./demoCA/private/cakey.pem \
    -out ./demoCA/private/ca.csr \
    -subj "/C=CN/ST=SC/L=CD/O=XY/OU=FF/CN=XY.WWW"

# 显示证书内容
openssl req -text -noout -in ./demoCA/private/ca.csr

# 自签发根证书, echo "basicConstraints=CA:TRUE" >ff.ssl.ca.cnf
openssl x509 -req -sha256 -days 7777 \
    -in ./demoCA/private/ca.csr \
    -signkey ./demoCA/private/cakey.pem \
    -out ./demoCA/private/ca.crt \
    -extfile ./ff.ssl.ca.cnf

# 复制 CA 证书到默认目录
cp ./demoCA/private/ca.crt ./demoCA/cacert.pem

echo 'FF.ok'
