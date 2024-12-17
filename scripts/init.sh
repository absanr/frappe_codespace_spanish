#!/bin/bash
set -e

# Evita reinicializar si el repo de frappe ya existe
if [[ -f "/workspaces/frappe_codespace/frappe-bench/apps/frappe" ]]; then
    echo "Bench already exists, skipping init"
    exit 0
fi

# Borramos el .git de la carpeta principal para evitar conflictos
rm -rf /workspaces/frappe_codespace/.git

# Cargamos nvm y definimos Node 18 como default
source /home/frappe/.nvm/nvm.sh
nvm alias default 18
nvm use 18
echo "nvm use 18" >> ~/.bashrc

cd /workspace

# Inicializa Frappe Bench (no recrea si ya existe).
bench init \
  --ignore-exist \
  --skip-redis-config-generation \
  frappe-bench

cd frappe-bench

# Usar contenedores en lugar de localhost
bench set-mariadb-host mariadb
bench set-redis-cache-host redis-cache:6379
bench set-redis-queue-host redis-queue:6379
bench set-redis-socketio-host redis-socketio:6379

# Remove redis from Procfile para que no intente levantar Redis local
sed -i '/redis/d' ./Procfile

# Crea nuevo sitio con la contraseña root definida y host amplio '%'
bench new-site dev.localhost \
  --mariadb-root-password 123 \
  --mariadb-user-host-login-scope='%' \
  --admin-password admin \
  --force

bench --site dev.localhost set-config developer_mode 1
bench --site dev.localhost clear-cache
bench use dev.localhost

echo "SUCCESS: Bench frappe-bench initialized"
