#!/usr/bin/env bash
set -euo pipefail

REPO_BASENAME="${1:-}"
if [ -z "$REPO_BASENAME" ]; then
  echo "[init] Usage: init.sh <repo-basename>"
  exit 1
fi

WORKDIR="/workspaces/${REPO_BASENAME}"
PUBLIC_DIR="${WORKDIR}/public"
APACHE_CONF="/etc/apache2/sites-available/000-default.conf"

echo "[init] repo basename: ${REPO_BASENAME}"
echo "[init] workspace: ${WORKDIR}"

# 1) Start MariaDB (root sem senha ok para dev conforme seu pedido)
echo "[init] iniciando MariaDB..."
# Tenta iniciar nomes comuns de serviço: mariadb, mysql, mysqld
service mariadb start 2>/dev/null || service mysql start 2>/dev/null || service mysqld start 2>/dev/null || true

# 2) Esperar até o mysql responder (se mysqladmin estiver disponível)
if command -v mysqladmin >/dev/null 2>&1; then
  echo "[init] aguardando mariadb (até 30s)..."
  MAX=30
  i=0
  until mysqladmin ping --silent >/dev/null 2>&1; do
    i=$((i+1))
    if [ "$i" -ge "$MAX" ]; then
      echo "[init] timeout esperando mysql. Prosseguindo (verifique manualmente)."
      break
    fi
    sleep 1
  done
  echo "[init] mariadb check finalizado (ou timeout)."
else
  echo "[init] mysqladmin/mariadb-admin não encontrado; pulando wait."
fi

# 2.5) Configurar senha root e criar DB/usuário de dev (idempotente)
DB_ROOT_PASS='_43690'
if command -v mariadb >/dev/null 2>&1 || command -v mysql >/dev/null 2>&1; then
  echo "[init] aplicando configuração SQL (senha root e usuário de dev)..."
  # Tenta executar via socket como root (comando deve rodar sem senha inicialmente)
  mysql_cmd="mysql"
  if command -v mariadb >/dev/null 2>&1; then
    mysql_cmd="mariadb"
  fi
  # Executa SQL de forma idempotente
  $mysql_cmd -u root <<SQL || true
ALTER USER IF EXISTS 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASS}';
CREATE DATABASE IF NOT EXISTS jebusiness CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS 'jebusiness'@'127.0.0.1' IDENTIFIED BY '${DB_ROOT_PASS}';
GRANT ALL PRIVILEGES ON jebusiness.* TO 'jebusiness'@'127.0.0.1';
FLUSH PRIVILEGES;
SQL
  echo "[init] SQL aplicado (root: ${DB_ROOT_PASS})."
else
  echo "[init] cliente mysql/mariadb não encontrado; pulando config de senha DB."
fi

# 2.75) Gerar config do phpMyAdmin (blowfish + cookie) para evitar erros de parse e permitir login com senha
PHPMYADMIN_DIR="/var/www/phpmyadmin"
PHPMYADMIN_CONF="$PHPMYADMIN_DIR/config.inc.php"
if [ -d "$PHPMYADMIN_DIR" ]; then
  echo "[init] gerando $PHPMYADMIN_CONF"
  cat > "$PHPMYADMIN_CONF" <<'PHP'
<?php
$cfg['blowfish_secret'] = '_43690_blowfish_secret_';
$i = 0;
$i++;
$cfg['Servers'][$i]['auth_type'] = 'cookie';
$cfg['Servers'][$i]['host'] = '127.0.0.1';
$cfg['Servers'][$i]['connect_type'] = 'tcp';
$cfg['Servers'][$i]['compress'] = false;
$cfg['Servers'][$i]['AllowNoPassword'] = false;
?>
PHP
  chown www-data:www-data "$PHPMYADMIN_CONF" 2>/dev/null || true
  chmod 644 "$PHPMYADMIN_CONF" 2>/dev/null || true
fi

# 3) Se existir /public no workspace, ajustar DocumentRoot do Apache PARA ESSA PASTA.
#    Se não existir, NÃO criar nada (como você pediu) — manterá /var/www/html
if [ -d "${PUBLIC_DIR}" ]; then
  echo "[init] detectado ${PUBLIC_DIR} — ajustando DocumentRoot do Apache..."
  # substitui a ocorrência padrão /var/www/html no arquivo de site
  sed -i "s#/var/www/html#${PUBLIC_DIR}#g" "${APACHE_CONF}"
  # garantir permissões corretas na pasta pública
  chown -R www-data:www-data "${PUBLIC_DIR}" 2>/dev/null || true
  chmod -R 755 "${PUBLIC_DIR}" 2>/dev/null || true
  # garantir que exista um <Directory> com Require all granted para o public dir
  APACHE_MAIN_CONF="/etc/apache2/apache2.conf"
  if ! grep -q "<Directory ${PUBLIC_DIR}>" "${APACHE_MAIN_CONF}" 2>/dev/null; then
    echo "[init] adicionando <Directory> para ${PUBLIC_DIR} em ${APACHE_MAIN_CONF}"
    cat >> "${APACHE_MAIN_CONF}" <<-EOF
<Directory ${PUBLIC_DIR}>
    Options Indexes FollowSymLinks
    AllowOverride All
    Require all granted
</Directory>
EOF
  fi
else
  echo "[init] ${PUBLIC_DIR} não existe — Apache continuará com /var/www/html (não criei nada)."
fi

# 4) Ajustar permissões do workspace (silencioso se falhar)
chown -R www-data:www-data "${WORKDIR}" 2>/dev/null || true
# Garantir permissões do phpMyAdmin
PHPMYADMIN_DIR="/var/www/phpmyadmin"
if [ -d "$PHPMYADMIN_DIR" ]; then
  chown -R www-data:www-data "$PHPMYADMIN_DIR" 2>/dev/null || true
  chmod -R 755 "$PHPMYADMIN_DIR" 2>/dev/null || true
fi

# 5) Reiniciar/garantir Apache rodando
echo "[init] reiniciando apache..."
service apache2 restart 2>/dev/null || service httpd restart 2>/dev/null || true

echo "[init] finalizado."
echo "[init] Apache DocumentRoot atual: $(grep -Eo 'DocumentRoot .*' ${APACHE_CONF} || echo '/var/www/html')"
echo "[init] Para acessar MariaDB/MySQL: dentro do container rode 'mysql -u root' (ou 'mariadb -u root') (dev)."