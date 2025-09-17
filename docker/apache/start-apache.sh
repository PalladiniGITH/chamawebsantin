#!/bin/bash
set -Eeuo pipefail

CERT_DEST="/etc/ssl/certs/web.crt"
KEY_DEST="/etc/ssl/private/web.key"
CHAIN_DEST="/etc/ssl/certs/web-chain.crt"
DEFAULT_SSL_CONF="/etc/apache2/sites-available/default-ssl.conf"

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

ensure_cert_directives() {
    local cert_path="$1"
    local key_path="$2"
    local chain_path="$3"

    sed -i "s#SSLCertificateFile .*#SSLCertificateFile ${cert_path}#" "${DEFAULT_SSL_CONF}"
    sed -i "s#SSLCertificateKeyFile .*#SSLCertificateKeyFile ${key_path}#" "${DEFAULT_SSL_CONF}"

    if [[ -n "${chain_path}" ]]; then
        if grep -q 'SSLCertificateChainFile' "${DEFAULT_SSL_CONF}"; then
            sed -i "s#SSLCertificateChainFile .*#SSLCertificateChainFile ${chain_path}#" "${DEFAULT_SSL_CONF}"
        else
            sed -i "/SSLCertificateFile/a SSLCertificateChainFile ${chain_path}" "${DEFAULT_SSL_CONF}"
        fi
    else
        sed -i '/SSLCertificateChainFile/d' "${DEFAULT_SSL_CONF}"
    fi
}

REQUIRE_CUSTOM_CERT="${APACHE_SSL_REQUIRE_CUSTOM_CERT:-false}"

if [[ -f "${CERT_SOURCE}" && -f "${KEY_SOURCE}" ]]; then
    echo "[web] Usando certificado TLS personalizado encontrado em ${CERT_SOURCE}."
    install -m 0644 "${CERT_SOURCE}" "${CERT_DEST}"
    install -m 0600 "${KEY_SOURCE}" "${KEY_DEST}"

    if [[ -n "${CHAIN_SOURCE}" && -f "${CHAIN_SOURCE}" ]]; then
        install -m 0644 "${CHAIN_SOURCE}" "${CHAIN_DEST}"
        ensure_cert_directives "${CERT_DEST}" "${KEY_DEST}" "${CHAIN_DEST}"
    else
        ensure_cert_directives "${CERT_DEST}" "${KEY_DEST}" ""
        rm -f "${CHAIN_DEST}"
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
    ensure_cert_directives "${CERT_DEST}" "${KEY_DEST}" ""
    rm -f "${CHAIN_DEST}"
fi

exec apache2-foreground
