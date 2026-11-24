#!/bin/bash

set -e

# Comprobar que Apache está instalado
if ! dpkg -s apache2 >/dev/null 2>&1; then
    echo "Apache no está instalado."
    echo "Ejecuta antes install_apache.sh"
    exit 1
fi

# Localizar y cargar el archivo .env
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

if [ ! -f "$SCRIPT_DIR/.env" ]; then
    echo "No se encuentra el archivo .env"
    exit 1
fi

set -a
source "$SCRIPT_DIR/.env"
set +a

# Comprobar variables necesarias
: "${COUNTRY:?Falta COUNTRY}"
: "${STATE:?Falta STATE}"
: "${LOCATION:?Falta LOCATION}"
: "${ORGANIZATION:?Falta ORGANIZATION}"
: "${ORGANIZATIONAL_UNIT:?Falta ORGANIZATIONAL_UNIT}"
: "${DOMAIN:?Falta DOMAIN}"
: "${ELASTIC_IP:?Falta ELASTIC_IP}"
: "${EMAIL:?Falta EMAIL}"
: "${DAYS:?Falta DAYS}"
: "${CERT_FILE:?Falta CERT_FILE}"
: "${KEY_FILE:?Falta KEY_FILE}"

# Crear certificado autofirmado
openssl req -x509 -nodes -days "$DAYS" \
-newkey rsa:2048 \
-keyout "$KEY_FILE" \
-out "$CERT_FILE" \
-subj "/C=$COUNTRY/ST=$STATE/L=$LOCATION/O=$ORGANIZATION/OU=$ORGANIZATIONAL_UNIT/CN=$DOMAIN/emailAddress=$EMAIL" \
-addext "subjectAltName=DNS:$DOMAIN,IP:$ELASTIC_IP"

# Proteger la clave privada
chmod 600 "$KEY_FILE"

# Copiar archivos de configuración
cp "$PROJECT_DIR/conf/000-default.conf" \
/etc/apache2/sites-available/000-default.conf

cp "$PROJECT_DIR/conf/practica-https-ssl.conf" \
/etc/apache2/sites-available/practica-https-ssl.conf

# Sustituir el dominio
sed -i "s/practica-https.test/$DOMAIN/g" \
/etc/apache2/sites-available/000-default.conf

sed -i "s/practica-https.test/$DOMAIN/g" \
/etc/apache2/sites-available/practica-https-ssl.conf

# Habilitar módulos y sitio HTTPS
a2enmod ssl rewrite
a2ensite practica-https-ssl.conf

# Comprobar la configuración antes de reiniciar
apache2ctl configtest

# Reiniciar Apache
systemctl restart apache2

echo "Configuración HTTPS completada."
