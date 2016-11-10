#!/bin/bash

# revoke a certificate, regenerate CRL,
# and verify revocation

CRL="crl.pem"
RT="revoke-test.pem"

if [ $# -ne 1 ]; then #Si le nombre d'arguments n'est pas égale à 1
    echo "usage: revoke-full <cert-name-base>";
    exit 1 #Exit code error
fi

if [ "$KEY_DIR" ]; then
    cd "$KEY_DIR"
    rm -f "$RT"

    # set defaults
    export KEY_CN=""
    export KEY_OU=""
    export KEY_NAME=""

    # revoke key and generate a new CRL
    $OPENSSL ca -revoke "$1.crt" -config "$KEY_CONFIG"

    # generate a new CRL -- try to be compatible with
    # intermediate PKIs
    $OPENSSL ca -gencrl -out "$CRL" -config "$KEY_CONFIG"
    if [ -e export-ca.crt ]; then
    cat export-ca.crt "$CRL" >"$RT"
    else
    cat ca.crt "$CRL" >"$RT"
    fi

    # verify the revocation
    $OPENSSL verify -CAfile "$RT" -crl_check "$1.crt"
else
    echo 'Please source the vars script first (i.e. "source ./vars")'
    echo 'Make sure you have edited it to reflect your configuration.'
fi

