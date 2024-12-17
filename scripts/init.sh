#!/bin/bash
set -e  # Detiene la ejecución del script si ocurre algún error.

# ---------------------------------------------------------------------------------------
# 1. COMPROBACIÓN DE EXISTENCIA DE FRAPPE BENCH
# ---------------------------------------------------------------------------------------
# Verifica si ya existe la carpeta /apps/frappe dentro de frappe-bench.
# Si existe, se asume que Bench ya fue inicializado previamente, así que se sale sin repetir el proceso.
if [[ -f "/workspaces/frappe_codespace/frappe-bench/apps/frappe" ]]; then
    echo "Bench already exists, skipping init"
    exit 0
fi

# ---------------------------------------------------------------------------------------
# 2. LIMPIEZA OPCIONAL DEL REPOSITORIO .GIT
# ---------------------------------------------------------------------------------------
# Esto elimina el directorio .git para evitar conflictos si estás usando un repositorio nuevo
# en el que no quieras el historial previo. Descomenta o quita esta línea según convenga.
rm -rf /workspaces/frappe_codespace/.git

# ---------------------------------------------------------------------------------------
# 3. CONFIGURACIÓN DE NODE 18 CON NVM
# ---------------------------------------------------------------------------------------
# Carga el entorno de NVM y define Node.js 18 como versión por defecto.
source /home/frappe/.nvm/nvm.sh
nvm alias default 18
nvm use 18

# Agrega el comando "nvm use 18" al final de ~/.bashrc para que se aplique en futuras sesiones.
echo "nvm use 18" >> ~/.bashrc

# ---------------------------------------------------------------------------------------
# 4. CREACIÓN DEL DIRECTORIO DE TRABAJO
# ---------------------------------------------------------------------------------------
cd /workspace

echo "Iniciando frappe-bench..."
# ---------------------------------------------------------------------------------------
# 5. BENCH INIT
# ---------------------------------------------------------------------------------------
# Crea un nuevo directorio llamado frappe-bench (si no existe) para alojar el framework Frappe
# y las aplicaciones relacionadas. "bench init" se encarga de configurar el entorno básico.
# --ignore-exist: ignora si la carpeta ya existe.
# --skip-redis-config-generation: no genera la configuración de redis local, pues se usan contenedores externos.
bench init \
  --ignore-exist \
  --skip-redis-config-generation \
  frappe-bench

# Ingresa al directorio frappe-bench recién creado
cd frappe-bench

# ---------------------------------------------------------------------------------------
# 6. CONFIGURACIÓN DE HOSTS PARA SERVICIOS (MARIADB y REDIS)
# ---------------------------------------------------------------------------------------
# Usa mariadb para MariaDB y los servicios correctos de Redis
bench set-mariadb-host mariadb
bench set-redis-cache-host redis-cache:6379
bench set-redis-queue-host redis-queue:6379
bench set-redis-socketio-host redis-socketio:6379

# ---------------------------------------------------------------------------------------
# 7. ELIMINACIÓN DE LÍNEAS REDIS EN PROCFILE
# ---------------------------------------------------------------------------------------
# Elimina cualquier referencia a redis en el Procfile local,
# porque se usarán contenedores externos de Redis (no locales).
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
bench new-site dev.localhost \
  --mariadb-root-password 123 \
  --admin-password admin \
  --db-host mariadb



# ---------------------------------------------------------------------------------------
# 9. CONFIGURACIONES POSTERIORES DEL SITIO
# ---------------------------------------------------------------------------------------
# Activa el modo desarrollador y limpia la caché de Frappe. Luego, selecciona este sitio
# (dev.localhost) como sitio activo para comandos subsecuentes.
bench --site dev.localhost set-config developer_mode 1
bench --site dev.localhost clear-cache
bench use dev.localhost

# ---------------------------------------------------------------------------------------
# 10. MENSAJE FINAL DE ÉXITO
# ---------------------------------------------------------------------------------------
# Si se llega hasta aquí, significa que todo el proceso finalizó sin errores.
# No se solicitó la contraseña de root manualmente.
echo "MENSAJE FINAL (ES): ¡Todo se ha configurado exitosamente y ya NO se solicitará la contraseña de root manualmente!"
