#!/usr/bin/env bash
host=192.168.1.10:8443
openssl genrsa -out ca.key 4096
openssl req -x509 -new -noenc -sha512 -days 3650 -config $(dirname "$0")/subj.csr \
-key ca.key -out ca.crt

openssl genrsa -out $host.key 4096
openssl req -sha512 -new -config $(dirname "$0")/subj.csr -key $host.key -out $host.csr
openssl x509 -req -sha512 -days 365 -extfile $(dirname "$0")/v3.ext -CA ca.crt -CAkey ca.key \
-CAcreateserial -in $host.csr -out $host.crt
