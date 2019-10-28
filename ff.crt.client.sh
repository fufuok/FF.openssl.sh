#!/bin/bash
# author: Fufu, 2019-10-28
# CA 颁发用户证书, 支持 IOS 13
#
# e.g.::
#
#    参数一: 用户信息, 如: fufu
#    参数二: 证书有效期(天), 如: 824
#    参数三: 输入文件名(用户信息有特殊符号时使用), 如: ff
#    参数四: p12 证书密码
#    bash ./ff.crt.client.sh fufu 824 ff 123456
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
PASS=${4:-"Xyyyyy"}
[[ -z "${FNAME}" ]] && echo "Usage: bash ./${NAME} <CNAME> [DAYS] [FNAME] [PASS]" && exit 1
OUTDIR="${BASE}/client/${FNAME}"
mkdir -p "${OUTDIR}"
OUTFILE="${OUTDIR}/${FNAME}"

# 生成用户 RSA 密钥
openssl genrsa -out "${OUTFILE}.key" 2048

# 生成用户证书请求
openssl req -new -sha256 \
    -key "${OUTFILE}.key" \
    -out "${OUTFILE}.csr" \
    -subj "/C=CN/ST=SC/L=CD/O=XY/OU=FF/CN=${CNAME}" \
    -utf8

# 用户证书扩展
cat >"${OUTFILE}.cnf" <<EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage=digitalSignature,nonRepudiation,keyEncipherment,dataEncipherment
extendedKeyUsage=clientAuth,OCSPSigning,codeSigning,emailProtection
subjectAltName=@alt_names

[alt_names]
DNS.1=${CNAME}
EOF

# 签发用户私有证书, -passin pass:***
openssl x509 -req -sha256 -days "${DAYS}" \
    -in "${OUTFILE}.csr" \
    -CA "${BASE}/demoCA/private/ca.crt" \
    -CAkey "${BASE}/demoCA/private/cakey.pem" \
    -CAcreateserial \
    -out "${OUTFILE}.crt" \
    -extfile "${OUTFILE}.cnf"

# PKCS#12格式(Personal Information Exchange, 通常为 p12 后缀)
openssl pkcs12 -export -clcerts \
    -in "${OUTFILE}.crt" \
    -inkey "${OUTFILE}.key" \
    -password pass:"${PASS}" \
    -out "${OUTFILE}.p12"
cp "${OUTFILE}.p12" "${OUTFILE}.pfx"

# 复制 CA 证书到用户目录
cp "${BASE}/demoCA/private/ca.crt" "${OUTDIR}/ca.crt"

# 查看证书信息
openssl x509 -in "${OUTFILE}.crt" -text -noout
openssl pkcs12 -in "${OUTFILE}.p12" -nodes -passin pass:"${PASS}" |
    openssl x509 -noout -subject

# 校验证书
openssl verify -CAfile "${OUTDIR}/ca.crt" "${OUTFILE}.crt"

echo 'FF.ok'
