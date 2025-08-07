#!/bin/bash

source ~/.envs

COURSEDIR=/home/ubuntu/$KONG_COURSE_ID
CERT_FOLDER=/home/ubuntu/$KONG_COURSE_ID/.certificates

if [ -d "$CERT_FOLDER" ]; then
    rm -rf "$CERT_FOLDER"
fi

mkdir -p "${CERT_FOLDER}"
pushd "${COURSEDIR}"
touch .certificates/index.txt
echo 1337 > .certificates/serial

openssl genrsa -aes256 -out .certificates/ca.key.pem -passout pass:konglabs 4096
chmod 400 .certificates/ca.key.pem
openssl req -config openssl.cnf -key .certificates/ca.key.pem -new -x509 -days 7300 -sha256 -extensions v3_ca -passin 'pass:konglabs' -subj "/C=WD/ST=Earth/L=Global/O=Kong Inc./CN=Kong CA" -out .certificates/ca.cert.pem

openssl genrsa -out .certificates/client.key 2048
openssl req -new -subj "/emailAddress=demo@example.com/CN=example.com/O=Kong Inc./OU=Kong Academy/C=WD/ST=Earth/L=Global" -key .certificates/client.key -out .certificates/client.csr

# Make sure that there are the files in the computer: openssl.cnf, index.txt and serial
openssl ca -batch -config openssl.cnf -extensions usr_cert -cert .certificates/ca.cert.pem -keyfile .certificates/ca.key.pem -passin 'pass:konglabs' -in .certificates/client.csr -out .certificates/client.crt

popd