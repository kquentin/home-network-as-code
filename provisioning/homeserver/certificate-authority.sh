#!/usr/bin/env bash
# run on the workstation: create the house's certificate authority, then sign the certificate the services present.
# the authority's key stays on the workstation and never reaches the server.

set -euo pipefail

domain=${1}
destination=${HOME}/homenet-keys/certificate-authority

mkdir -p "${destination}"
umask 077

if [[ ! -f "${destination}/root.key" ]]; then
  openssl genpkey -algorithm EC -pkeyopt ec_paramgen_curve:P-256 -out "${destination}/root.key"
  # devices trust this root completely: without a limit, its key could forge a certificate for any site.
  # nameConstraints limits it to names under the domain.
  openssl req -x509 -new \
    -key "${destination}/root.key" \
    -sha256 \
    -days 3650 \
    -subj "/CN=homenet" \
    -config /dev/null \
    -addext "basicConstraints=critical,CA:TRUE,pathlen:0" \
    -addext "keyUsage=critical,keyCertSign,cRLSign" \
    -addext "nameConstraints=critical,permitted;DNS:${domain}" \
    -out "${destination}/root.crt"
fi

openssl genpkey -algorithm EC -pkeyopt ec_paramgen_curve:P-256 -out "${destination}/services.key"
openssl req -new -key "${destination}/services.key" -subj "/CN=*.${domain}" -config /dev/null -out "${destination}/services.csr"
openssl x509 -req \
  -in "${destination}/services.csr" \
  -sha256 \
  -days 825 \
  -CA "${destination}/root.crt" \
  -CAkey "${destination}/root.key" \
  -CAcreateserial \
  -extfile <(printf '%s\n' "subjectAltName=DNS:*.${domain}" "basicConstraints=critical,CA:FALSE" "keyUsage=critical,digitalSignature" "extendedKeyUsage=serverAuth") \
  -out "${destination}/services.crt"
