#!/usr/bin/env bash
echo "Create CA key..."
openssl genrsa -out ca.key 4096

echo "Create CA certificate"
openssl req -x509 -new -noenc -sha512 -days 3650 \
        -config $(dirname "$0")/certificate.csr \
        -key ca.key -out ca.crt

echo "Create server certificate key..."
openssl genrsa -out server.key 4096

echo "Create server certificate CSR"
openssl req -new -sha512 \
        -config $(dirname "$0")/certificate.csr \
	-key server.key -out server.csr

echo "Create server certificate with signing"
openssl x509 -req -sha512 -days 3650 \
	-extfile $(dirname "$0")/certificate_v3.ext \
	-CA ca.crt -CAkey ca.key -CAcreateserial \
	-in server.csr -out server.crt
