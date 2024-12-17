#!/bin/bash
set -e

# Si ya existe la carpeta /apps/frappe, evitamos reinicializar
if [[ -f "/workspaces/frappe_codespace/frappe-bench/apps/frappe" ]]; then
    echo "Bench already exists, skipping init"
    exit 0
fi

# Opcional: borrar .git si es necesario
rm -rf /workspaces/frappe_codespace/.git

# Cargar NVM y Node 18
source /home/frappe/.nvm/nvm.sh
nvm alias default 18
nvm use 18
echo "nvm use 18" >> ~/.bashrc

cd /workspace

echo "Iniciando frappe-bench..."
bench init \
  --ignore-exist \
  --skip-redis-config-generation \
  frappe-bench

cd frappe-bench

# Asignar hosts contenedor en vez de localhost
bench set-mariadb-host mariadb
bench set-redis-cache-host redis-cache:6379
bench set-redis-queue-host redis-queue:6379
bench set-redis-socketio-host redis-socketio:6379

# Elimina las líneas relacionadas a redis local
sed -i '/redis/d' ./Procfile

# Crear nuevo sitio (dev.localhost) usando root:123 sin prompt interactivo
bench new-site dev.localhost \
  --mariadb-root-password 123 \
  --mariadb-user-host-login-scope='%' \
  --admin-password admin \
  --force \
  --no-input

bench --site dev.localhost set-config developer_mode 1
bench --site dev.localhost clear-cache
bench use dev.localhost

echo "MENSAJE FINAL (ES): ¡Todo se ha configurado exitosamente y ya NO se solicitará la contraseña de root manualmente!"
