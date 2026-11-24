#!/bin/bash

set -e

# Comprobar si Apache ya está instalado
if dpkg -s apache2 >/dev/null 2>&1; then
    echo "Apache ya está instalado."
    exit 0
fi

# Instalar Apache sin intervención del usuario
export DEBIAN_FRONTEND=noninteractive

apt update
apt install -y apache2

# Habilitar y arrancar Apache
systemctl enable apache2
systemctl start apache2

echo "Apache instalado correctamente."
