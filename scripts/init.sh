#!/bin/bash
set -e  # Detiene el script si ocurre un error.

# ---------------------------------------------------------------------------------------
# Verificar existencia de Bench
# ---------------------------------------------------------------------------------------
if [[ -f "/workspaces/frappe_codespace/frappe-bench/apps/frappe" ]]; then
    echo "Bench already exists, skipping init"
    exit 0
fi

# Limpieza opcional del repositorio .git
rm -rf /workspaces/frappe_codespace/.git

# Configurar permisos del script actual
SCRIPT_PATH="$(realpath "$0")"
chmod +x "$SCRIPT_PATH"
echo "Permisos configurados para: $SCRIPT_PATH"

# Configuración de Node.js con NVM
source /home/frappe/.nvm/nvm.sh
nvm alias default 18
nvm use 18
echo "nvm use 18" >> ~/.bashrc

# ---------------------------------------------------------------------------------------
# Iniciar frappe-bench
# ---------------------------------------------------------------------------------------
cd /workspace
bench init \
  --ignore-exist \
  --skip-redis-config-generation \
  frappe-bench

cd frappe-bench

# ---------------------------------------------------------------------------------------
# Configuración de hosts para servicios
# ---------------------------------------------------------------------------------------
bench set-mariadb-host mariadb
bench set-redis-cache-host redis-cache:6379
bench set-redis-queue-host redis-queue:6379
bench set-redis-socketio-host redis-socketio:6379

# Eliminar referencias a Redis en el Procfile
sed -i '/redis/d' ./Procfile

# ---------------------------------------------------------------------------------------
# Verificar disponibilidad de MariaDB
# ---------------------------------------------------------------------------------------
echo "Verificando disponibilidad de MariaDB..."
until mysql -hmariadb -uroot -p123 -e "SELECT 1;" >/dev/null 2>&1; do
  echo "Esperando a que MariaDB esté disponible..."
  sleep 3
done
echo "MariaDB está disponible."

# ---------------------------------------------------------------------------------------
# Crear sitio usando root
# ---------------------------------------------------------------------------------------
crear_sitio_con_root() {
  echo "Intentando crear el sitio con usuario root..."
  if ! bench new-site dev.localhost \
    --mariadb-root-username root \
    --mariadb-root-password 123 \
    --admin-password admin \
    --db-host mariadb \
    --mariadb-user-host-login-scope=%; then
    echo "Error crítico: No se pudo crear el sitio usando root."
    exit 1
  else
    echo "Sitio creado exitosamente."
  fi
}

crear_sitio_con_root

# ---------------------------------------------------------------------------------------
# Configuración adicional del sitio
# ---------------------------------------------------------------------------------------
bench --site dev.localhost set-config developer_mode 1
bench --site dev.localhost clear-cache
bench use dev.localhost

# ---------------------------------------------------------------------------------------
# Actualizar archivo /etc/hosts
# ---------------------------------------------------------------------------------------
# echo "Actualizando archivo /etc/hosts para dev.localhost..."
# if ! grep -q "dev.localhost" /etc/hosts; then
#   echo "127.0.0.1 dev.localhost" | sudo tee -a /etc/hosts
# fi
# echo "Archivo /etc/hosts actualizado."

# ---------------------------------------------------------------------------------------
# Mensaje final
# ---------------------------------------------------------------------------------------
# echo "MENSAJE FINAL: El sitio 'dev.localhost' fue creado exitosamente y está listo para usarse."
