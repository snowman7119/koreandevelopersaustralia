#!/bin/sh
#
echo "-------------------------------------"
echo "Generating config file for openssl..."
echo "-------------------------------------"
cat > box1.conf <<EOF
[ req ]
default_bits        = 2048
default_keyfile     = server-key.pem
distinguished_name  = subject
req_extensions      = req_ext
x509_extensions     = x509_ext
string_mask         = utf8only

# The Subject DN can be formed using X501 or RFC 4514 (see RFC 4519 for a description).
#   Its sort of a mashup. For example, RFC 4514 does not provide emailAddress.
[ subject ]
countryName         = Country Name (2 letter code)
countryName_default     = US

stateOrProvinceName     = State or Province Name (full name)
stateOrProvinceName_default = NY

localityName            = Locality Name (eg, city)
localityName_default        = New York

organizationName         = Organization Name (eg, company)
organizationName_default    = Example, LLC

# Use a friendly name here because its presented to the user. The server's DNS
#   names are placed in Subject Alternate Names. Plus, DNS names here is deprecated
#   by both IETF and CA/Browser Forums. If you place a DNS name here, then you
#   must include the DNS name in the SAN too (otherwise, Chrome and others that
#   strictly follow the CA/Browser Baseline Requirements will fail).
commonName          = Common Name (e.g. server FQDN or YOUR name)
commonName_default      = Example Company

emailAddress            = Email Address
emailAddress_default        = test@example.com

# Section x509_ext is used when generating a self-signed certificate. I.e., openssl req -x509 ...
[ x509_ext ]

subjectKeyIdentifier        = hash
authorityKeyIdentifier  = keyid,issuer

# You only need digitalSignature below. *If* you don't allow
#   RSA Key transport (i.e., you use ephemeral cipher suites), then
#   omit keyEncipherment because that's key transport.
basicConstraints        = CA:FALSE
keyUsage            = digitalSignature, keyEncipherment
subjectAltName          = @alternate_names
nsComment           = "OpenSSL Generated Certificate"

# RFC 5280, Section 4.2.1.12 makes EKU optional
#   CA/Browser Baseline Requirements, Appendix (B)(3)(G) makes me confused
#   In either case, you probably only need serverAuth.
# extendedKeyUsage  = serverAuth, clientAuth

# Section req_ext is used when generating a certificate signing request. I.e., openssl req ...
[ req_ext ]

subjectKeyIdentifier        = hash

basicConstraints        = CA:FALSE
keyUsage            = digitalSignature, keyEncipherment
subjectAltName          = @alternate_names
nsComment           = "OpenSSL Generated Certificate"

# RFC 5280, Section 4.2.1.12 makes EKU optional
#   CA/Browser Baseline Requirements, Appendix (B)(3)(G) makes me confused
#   In either case, you probably only need serverAuth.
# extendedKeyUsage  = serverAuth, clientAuth

[ alternate_names ]

DNS.1       = box1.mytoy.mynet
DNS.2       = box2.mytoy.mynet
DNS.3       = box3.mytoy.mynet

# Add these if you need them. But usually you don't want them or
#   need them in production. You may need them for development.
# DNS.5       = localhost
# DNS.6       = localhost.localdomain
# DNS.7       = 127.0.0.1

# IPv6 localhost
# DNS.8     = ::1
EOF
#
echo "-------------------------------------"
echo "Generating Self-signed certificate..."
echo "-------------------------------------"
openssl req -config box1.conf -new -x509 -sha256 -newkey rsa:2048 -nodes \
-keyout box1.key.pem -out box1.cert.pem -days 3650 \
-subj "/C=AU/ST=Victoria/L=Docklands/O=MYTOY/OU=ORDS/CN=box1.mytoy.mynet"
#
echo "------------------------------------"
echo "Merginng key and cert into PKCS12..."
echo "------------------------------------"
#
openssl pkcs12 -export -in box1.cert.pem \
-inkey box1.key.pem -out box1.p12 \
-name box1 -passin pass:changeit -passout pass:changeit
#
echo "---------------------------------------"
echo "Converting PKSC12 into Jave Keystore..."
echo "---------------------------------------"
#
keytool -importkeystore -srckeystore box1.p12 -srcstoretype PKCS12 \
-srcstorepass changeit -alias box1 -deststorepass changeit \
-destkeypass changeit -destkeystore box1.jks
#
ls -lrt