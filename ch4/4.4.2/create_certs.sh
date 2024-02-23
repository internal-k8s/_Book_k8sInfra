#!/usr/bin/env bash
echo "create CA key..."
openssl genrsa -out ca.key 4096

echo "create CA certificate"
openssl req -x509 -new -noenc -sha512 -days 3650 \
        -config $(dirname "$0")/certificate.csr \
        -key ca.key -out ca.crt

echo "create server certificate key..."
openssl genrsa -out server.key 4096

echo "create server certificate CSR"
openssl req -new -sha512 \
        -config $(dirname "$0")/certificate.csr \
	-key server.key -out server.csr

echo "create server certificate with signing"
openssl x509 -req -sha512 -days 3650 \
	-extfile $(dirname "$0")/certificate_v3.ext \
	-CA ca.crt -CAkey ca.key -CAcreateserial \
	-in server.csr -out server.crt
