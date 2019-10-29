#!/bin/bash
# author: Fufu, 2019-10-28
# CA 颁发服务端证书, 支持 IOS 13
#
# e.g.::
#
#    参数一: 域名信息, 如: *.fufuok.com
#    参数二: 证书有效期(天), 如: 824
#    参数三: 输入文件名(用户信息有特殊符号时使用), 如: server
#    bash ./ff.crt.client.sh *.fufuok.com 824 server
#
# set -x
#
set -o errexit
export PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin
readonly BASE=$(cd "$(dirname "$0")" && pwd)
readonly NAME=$(basename "$0")

CNAME=${1:-""}
DAYS=${2:-824}
FNAME=${3:-"${CNAME}"}
[[ -z "${FNAME}" ]] && echo "Usage: bash ./${NAME} <Domain> [DAYS] [FNAME]" && exit 1
OUTDIR="${BASE}/server/${FNAME}"
mkdir -p "${OUTDIR}"
OUTFILE="${OUTDIR}/${FNAME}"

# 生成服务端 RSA 密钥(无密码)
openssl genrsa -out "${OUTFILE}.key" 2048

# 生成服务端证书请求
openssl req -new -sha256 \
    -key "${OUTFILE}.key" \
    -out "${OUTFILE}.csr" \
    -subj "/C=CN/ST=SC/L=CD/O=XY/OU=FF/CN=${CNAME}" \
    -utf8

# 服务端证书扩展
cat >"${OUTFILE}.cnf" <<EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage=digitalSignature,nonRepudiation,keyEncipherment,dataEncipherment
extendedKeyUsage=serverAuth,OCSPSigning,codeSigning
subjectAltName=@alt_names

[alt_names]
DNS.1=${CNAME}
EOF

# 签发服务端私有证书, -passin pass:***
openssl x509 -req -sha256 -days "${DAYS}" \
    -in "${OUTFILE}.csr" \
    -CA "${BASE}/demoCA/private/ca.crt" \
    -CAkey "${BASE}/demoCA/private/cakey.pem" \
    -CAcreateserial \
    -out "${OUTFILE}.crt" \
    -extfile "${OUTFILE}.cnf"

# 复制 CA 证书到目录
cp "${BASE}/demoCA/private/ca.crt" "${OUTDIR}/ca.crt"

# 查看证书信息
openssl x509 -in "${OUTFILE}.crt" -text -noout

# 校验证书
openssl verify -CAfile "${OUTDIR}/ca.crt" "${OUTFILE}.crt"

echo 'FF.ok'
