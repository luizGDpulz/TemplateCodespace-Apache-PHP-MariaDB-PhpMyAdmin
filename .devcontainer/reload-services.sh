#!/usr/bin/env bash
set -euo pipefail

echo "[reload] Reiniciando/recarrregando serviços: Apache e MariaDB..."

# Tenta recarregar o Apache (preferível) e faz restart se necessário
if service apache2 reload >/dev/null 2>&1; then
  echo "[reload] Apache recarregado com 'service apache2 reload'."
else
  echo "[reload] 'service apache2 reload' falhou — tentando restart..."
  service apache2 restart 2>/dev/null || service httpd restart 2>/dev/null || echo "[reload] Não foi possível reiniciar Apache via service."
fi

# Reinicia MariaDB/MySQL (mais seguro que reload para garantir estado consistente)
if service mariadb restart 2>/dev/null; then
  echo "[reload] MariaDB reiniciado com 'service mariadb restart'."
elif service mysql restart 2>/dev/null; then
  echo "[reload] MySQL reiniciado com 'service mysql restart'."
elif service mysqld restart 2>/dev/null; then
  echo "[reload] mysqld reiniciado com 'service mysqld restart'."
else
  echo "[reload] Não foi possível reiniciar MariaDB/MySQL via service. Tente executar '.devcontainer/init.sh <repo>' ou ver logs do MariaDB."
fi

# Espera até o MariaDB responder (se mysqladmin estiver disponível)
if command -v mysqladmin >/dev/null 2>&1; then
  echo "[reload] aguardando MariaDB responder (até 20s)..."
  i=0
  until mysqladmin ping --silent >/dev/null 2>&1; do
    i=$((i+1))
    if [ "$i" -ge 20 ]; then
      echo "[reload] timeout esperando MariaDB."
      break
    fi
    sleep 1
  done
  echo "[reload] verificação MariaDB finalizada (ou timeout)."
fi

echo "[reload] Concluído. Verifique logs se necessário: /var/log/apache2/error.log e /var/log/mysql/ (ou /var/log/mariadb/)."