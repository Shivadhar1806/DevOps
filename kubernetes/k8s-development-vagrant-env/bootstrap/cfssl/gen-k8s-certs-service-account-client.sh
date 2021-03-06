#!/bin/bash

set -xe


export CFSSL_TLS_GUEST_FOLDER=${1}
export GATEWAY_IP=${2}
export GATEWAY_HOSTNAME=${3}
export HOSTNAME=$(hostname)
export IP_ADDRESSES=$(hostname -i)
export CERT_NAME=service-accounts

# source the ubuntu global env file to make cfssl variables available to this session
source /etc/environment

if [ -f ${CFSSL_TLS_GUEST_FOLDER}/service-accounts/${CERT_NAME}.csr ] && [ -f ${CFSSL_TLS_GUEST_FOLDER}/service-accounts/${CERT_NAME}.key ]
then

    echo "Skipping Kubernetes Controller Manager Service Accounts client certificate generation - it already exists"

else

mkdir -p ${CFSSL_TLS_GUEST_FOLDER}/service-accounts


separator=
formatted_ip_addresses=

for one in $IP_ADDRESSES
do
    formatted_ip_addresses=$formatted_ip_addresses$separator\"$one\"
    separator=", "
done


# generate service-accounts client certificate signing request for this vm

cat - > ${CFSSL_TLS_GUEST_FOLDER}/service-accounts/${CERT_NAME}-csr.json <<EOF
{
  "CN": "service-accounts",
  "hosts": [
    ${formatted_ip_addresses},
    "127.0.0.1",
    "10.0.2.15",
    "localhost",
    "${HOSTNAME}"
  ],
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "DE",
      "L": "Berlin",
      "O": "Kubernetes",
      "OU": "Kubernetes Development Cluster",
      "ST": "Berlin"
    }
  ]
}
EOF

echo "GENERATING SERVICE ACCOUNT CERT"

# generate signed service-account client certificates for the vm

cfssl gencert -ca=${CFSSL_TLS_GUEST_FOLDER}/ca/ca.pem \
    -ca-key=${CFSSL_TLS_GUEST_FOLDER}/ca/ca-key.pem \
    -config=${CFSSL_TLS_GUEST_FOLDER}/ca/ca-config.json \
    -profile=kubernetes \
    ${CFSSL_TLS_GUEST_FOLDER}/service-accounts/${CERT_NAME}-csr.json | cfssljson -bare ${CFSSL_TLS_GUEST_FOLDER}/service-accounts/${CERT_NAME}


# verify generated client certificate
openssl x509 -noout -text -in ${CFSSL_TLS_GUEST_FOLDER}/service-accounts/${CERT_NAME}.pem

# verify certificate functionality for client authentication
echo "verifying with ${CFSSL_TLS_GUEST_FOLDER}/ca/ca-chain.pem for ssl client functionality"
openssl verify -purpose sslclient -CAfile ${CFSSL_TLS_GUEST_FOLDER}/ca/ca-chain.pem ${CFSSL_TLS_GUEST_FOLDER}/service-accounts/${CERT_NAME}.pem

sudo chmod 644 ${CFSSL_TLS_GUEST_FOLDER}/service-accounts/service-accounts-key.pem

echo "Kube-Controller-Manager Client Certificates successfully generated"

fi

exit 0