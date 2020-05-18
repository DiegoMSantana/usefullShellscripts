#!/bin/bash

FULLCHAIN=$1
PRIVKEY=$2

# Convert the private key and certificate to a PKCS12 file
openssl pkcs12 -export -in "${FULLCHAIN}" -inkey "${PRIVKEY}" -out pkcs.p12 -name jetty -passout pass:@sempre@update@


#echo "${FULLCHAIN}"
#echo "${PRIVKEY}"

# Remove the old certificate from keystore
#keytool -keystore /path/to/my/keystore -delete -alias ‘mytlskeyalias’ -storepass ‘mystorepassword’

# Import the new p12 file to keystore
keytool -importkeystore -deststorepass @sempre@update@ -destkeypass @sempre@update@ -destkeystore keystore_le -srckeystore pkcs.p12 -srcstoretype PKCS12 -srcstorepass @sempre@update@ -alias jetty

# Reset your Java server
