#!/bin/bash
set -Eeuo pipefail

CERT_DEST="/run/apache2/web.crt"
KEY_DEST="/run/apache2/web.key"
CHAIN_DEST="/run/apache2/web-chain.crt"
OVERRIDE_CONF="/run/apache2/cert-overrides.conf"

CERT_SOURCE="${APACHE_SSL_CERT_FILE:-/certs/server.crt}"
KEY_SOURCE="${APACHE_SSL_KEY_FILE:-/certs/server.key}"
CHAIN_SOURCE="${APACHE_SSL_CHAIN_FILE:-}"
SELF_SIGNED_SUBJECT="${APACHE_SSL_SELF_SIGNED_SUBJECT:-/CN=localhost}"
SELF_SIGNED_DAYS="${APACHE_SSL_SELF_SIGNED_DAYS:-365}"

is_truthy() {
    case "$1" in
        1|true|TRUE|True|yes|YES|on|ON|y|Y)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

write_cert_directives() {
    local cert_path="$1"
    local key_path="$2"
    local chain_path="$3"

    {
        echo "SSLCertificateFile ${cert_path}"
        echo "SSLCertificateKeyFile ${key_path}"
        if [[ -n "${chain_path}" ]]; then
            echo "SSLCertificateChainFile ${chain_path}"
        fi
    } > "${OVERRIDE_CONF}"

    chmod 640 "${OVERRIDE_CONF}"
}

install -d -m 750 "$(dirname "${CERT_DEST}")"
rm -f "${OVERRIDE_CONF}"

REQUIRE_CUSTOM_CERT="${APACHE_SSL_REQUIRE_CUSTOM_CERT:-false}"

if [[ -f "${CERT_SOURCE}" && -f "${KEY_SOURCE}" ]]; then
    echo "[web] Usando certificado TLS personalizado encontrado em ${CERT_SOURCE}."
    install -m 0644 "${CERT_SOURCE}" "${CERT_DEST}"
    install -m 0600 "${KEY_SOURCE}" "${KEY_DEST}"

    if [[ -n "${CHAIN_SOURCE}" && -f "${CHAIN_SOURCE}" ]]; then
        install -m 0644 "${CHAIN_SOURCE}" "${CHAIN_DEST}"
        write_cert_directives "${CERT_DEST}" "${KEY_DEST}" "${CHAIN_DEST}"
    else
        rm -f "${CHAIN_DEST}"
        write_cert_directives "${CERT_DEST}" "${KEY_DEST}" ""
    fi
else
    if is_truthy "${REQUIRE_CUSTOM_CERT}"; then
        echo "[web] ERRO: Arquivos de certificado e chave não encontrados." >&2
        echo "[web]       Esperado certificado em: ${CERT_SOURCE}" >&2
        echo "[web]       Esperada chave em: ${KEY_SOURCE}" >&2
        echo "[web]       Ajuste os caminhos ou defina APACHE_SSL_REQUIRE_CUSTOM_CERT=false para permitir autoassinados." >&2
        exit 1
    fi

    echo "[web] Nenhum certificado personalizado encontrado; gerando certificado autoassinado apenas para testes." >&2
    openssl req -x509 -nodes -days "${SELF_SIGNED_DAYS}" -newkey rsa:2048 \
        -keyout "${KEY_DEST}" \
        -out "${CERT_DEST}" \
        -subj "${SELF_SIGNED_SUBJECT}"
    chmod 600 "${KEY_DEST}"
    chmod 644 "${CERT_DEST}"
    rm -f "${CHAIN_DEST}"
    write_cert_directives "${CERT_DEST}" "${KEY_DEST}" ""
fi

exec apache2-foreground
