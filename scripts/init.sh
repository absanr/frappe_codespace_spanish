#!/bin/bash
set -e  # Detiene la ejecución del script si ocurre algún error.

# ---------------------------------------------------------------------------------------
# 1. COMPROBACIÓN DE EXISTENCIA DE FRAPPE BENCH
# ---------------------------------------------------------------------------------------
if [[ -f "/workspaces/frappe_codespace/frappe-bench/apps/frappe" ]]; then
    echo "Bench already exists, skipping init"
    exit 0
fi

# ---------------------------------------------------------------------------------------
# 2. LIMPIEZA OPCIONAL DEL REPOSITORIO .GIT
# ---------------------------------------------------------------------------------------
rm -rf /workspaces/frappe_codespace/.git

# ---------------------------------------------------------------------------------------
# 3. CONFIGURACIÓN DE NODE 18 CON NVM
# ---------------------------------------------------------------------------------------
source /home/frappe/.nvm/nvm.sh
nvm alias default 18
nvm use 18
echo "nvm use 18" >> ~/.bashrc

# ---------------------------------------------------------------------------------------
# 4. CREACIÓN DEL DIRECTORIO DE TRABAJO
# ---------------------------------------------------------------------------------------
cd /workspace

echo "Iniciando frappe-bench..."
bench init \
  --ignore-exist \
  --skip-redis-config-generation \
  frappe-bench

cd frappe-bench

# ---------------------------------------------------------------------------------------
# 6. CONFIGURACIÓN DE HOSTS PARA SERVICIOS (MARIADB y REDIS)
# ---------------------------------------------------------------------------------------
bench set-mariadb-host mariadb
bench set-redis-cache-host redis-cache:6379
bench set-redis-queue-host redis-queue:6379
bench set-redis-socketio-host redis-socketio:6379

# ---------------------------------------------------------------------------------------
# 7. ELIMINACIÓN DE LÍNEAS REDIS EN PROCFILE
# ---------------------------------------------------------------------------------------
sed -i '/redis/d' ./Procfile

# ---------------------------------------------------------------------------------------
# Validación de MariaDB antes de continuar
# ---------------------------------------------------------------------------------------
echo "Verificando disponibilidad de MariaDB..."
until mysql -hmariadb -uroot -p123 -e "SELECT 1;" >/dev/null 2>&1; do
  echo "Esperando a que MariaDB esté disponible..."
  sleep 3
done
echo "MariaDB está disponible, continuando con la creación del sitio..."

# ---------------------------------------------------------------------------------------
# 8. CREACIÓN DE UN NUEVO SITIO EN FRAPPE
# ---------------------------------------------------------------------------------------
crear_sitio() {
  echo "Intentando crear el sitio..."
  if ! bench new-site dev.localhost \
    --mariadb-root-password 123 \
    --admin-password admin \
    --db-host mariadb \
    --mariadb-user-host-login-scope=% \
    --no-mariadb-socket \
    --force; then
    echo "Fallo al crear el sitio. Reiniciando MariaDB e intentando nuevamente..."
    sudo systemctl restart mariadb || echo "No se pudo reiniciar MariaDB"
    sleep 5
    echo "Reintentando creación del sitio..."
    bench new-site dev.localhost \
      --mariadb-root-password 123 \
      --admin-password admin \
      --db-host mariadb \
      --mariadb-user-host-login-scope=% \
      --no-mariadb-socket \
      --force || {
        echo "Error crítico: No se pudo crear el sitio después de reiniciar MariaDB."
        exit 1
      }
  else
    echo "Sitio creado exitosamente."
  fi
}

crear_sitio

# ---------------------------------------------------------------------------------------
# 9. CONFIGURACIONES POSTERIORES DEL SITIO
# ---------------------------------------------------------------------------------------
bench --site dev.localhost set-config developer_mode 1
bench --site dev.localhost clear-cache
bench use dev.localhost

# ---------------------------------------------------------------------------------------
# 10. MENSAJE FINAL DE ÉXITO
# ---------------------------------------------------------------------------------------
echo "MENSAJE FINAL (ES): ¡Todo se ha configurado exitosamente y ya NO se solicitará la contraseña de root manualmente!"
