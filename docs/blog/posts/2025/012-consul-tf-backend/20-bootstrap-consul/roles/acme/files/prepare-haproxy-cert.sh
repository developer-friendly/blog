#!/bin/bash
set -e

certbot renew -q || echo "Certbot not renewed!"

domains=(
  tofu.developer-friendly.blog
)

renew_domain_cert() {
  domain=$1
  cd /etc/letsencrypt/live/$domain

  temp_cert=$(mktemp)

  cat fullchain.pem privkey.pem >"$temp_cert"

  if ! cmp -s "$temp_cert" /etc/haproxy/certs/$domain; then
    mv "$temp_cert" /etc/haproxy/certs/$domain
    systemctl reload haproxy
    echo "Certificate updated and HAProxy reloaded."
  else
    echo "Certificate unchanged. No reload necessary."
  fi

  rm -f "$temp_cert"
}

for domain in "${domains[@]}"; do
  renew_domain_cert $domain
done
