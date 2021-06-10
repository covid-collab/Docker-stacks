#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")/.."

. ./lib/util.sh

echo "OS version: $(uname -a)"
check_command_exists docker
check_command_exists docker-compose

check_config_present etc/push-endpoint/gateway.yml etc/push-endpoint/gateway.yml.template
copy_template_if_absent etc/webserver/ip-access-control.conf

. ./.env

# Checking provided passwords and environment variables
ensure_env_default SERVER_NAME localhost

echo "==> Checking docker external volumes"
if ! sudo-linux docker volume ls -q | grep -q "^certs$"; then
  sudo-linux docker volume create --name=certs --label certs
fi
if ! sudo-linux docker volume ls -q | grep -q "^certs-data$"; then
  sudo-linux docker volume create --name=certs-data --label certs
fi


echo "==> Configuring nginx"
if [ "${ENABLE_HTTPS:-yes}" = yes ]; then
  cp etc/webserver/nginx.conf.template etc/webserver/nginx.conf
  if ! grep -q 443 etc/webserver/nginx.conf; then
    echo "NGINX configuration does not contain HTTPS configuration. Update the config"
    echo "to template etc/webserver/nginx.conf.template or set ENABLE_HTTPS=no in .env."
    exit 1
  fi
else
  cp etc/webserver/nginx.nossl.conf.template etc/webserver/nginx.conf
  if grep -q 443 etc/webserver/nginx.conf; then
    echo "NGINX configuration does contains HTTPS configuration. Update the config"
    echo "to template etc/webserver/nginx.nossl.conf.template or set ENABLE_HTTPS=yes in .env."
    exit 1
  fi
fi

sed_i 's|\${PUSH_ENDPOINT_URL}|'"${PUSH_ENDPOINT_URL}"'|' etc/webserver/nginx.conf

inline_variable 'server_name[[:space:]]*' "${SERVER_NAME};" etc/webserver/nginx.conf
if [ "${ENABLE_HTTPS:-yes}" = yes ]; then
  sed_i 's|\(/etc/letsencrypt/live/\)[^/]*\(/.*\.pem\)|\1'"${SERVER_NAME}"'\2|' etc/webserver/nginx.conf
  init_certificate "${SERVER_NAME}"
else
  # Fill in reverse proxy servers
  proxies=
  for PROXY in ${NGINX_PROXIES:-}; do
    proxies="${proxies}set_real_ip_from ${PROXY}; "
  done
  sed_i "s/^\(\s*\).*# NGINX_PROXIES/\1$proxies# NGINX_PROXIES/" etc/webserver/nginx.conf
fi

sudo-linux docker-compose up -d

if [ "${ENABLE_HTTPS:-yes}" = yes ]; then
  request_certificate "${SERVER_NAME}" "${SELF_SIGNED_CERT:-yes}"
fi