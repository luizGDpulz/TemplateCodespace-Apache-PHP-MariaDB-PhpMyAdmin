FROM debian:bookworm

ENV DEBIAN_FRONTEND=noninteractive

# Instala Apache, PHP do repositório com extensões comuns, MariaDB e phpMyAdmin
RUN apt-get update && apt-get install -y --no-install-recommends \
      apache2 \
      mariadb-server \
      git zip unzip curl wget \
      php php-cli php-mysql php-mbstring php-zip php-gd php-xml php-curl php-intl \
      libapache2-mod-php \
      phpmyadmin \
  && a2enmod rewrite \
  && rm -rf /var/lib/apt/lists/*

# Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Install git-lfs for devcontainer (ensure git-lfs available inside container)
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates gnupg2 \
  && curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | bash \
  && apt-get install -y git-lfs \
  && git lfs install --system \
  && rm -rf /var/lib/apt/lists/*

# Expor portas (informativo)
EXPOSE 80 3306

# Workdir - não força /workspaces aqui, será o mount do Codespaces
WORKDIR /var/www/html

# Não altera DocumentRoot aqui (será feito no init.sh se houver /public).

# Configuração do phpMyAdmin
# phpMyAdmin é instalado em /usr/share/phpmyadmin via apt
# Cria link simbólico para manter compatibilidade com init.sh
RUN ln -s /usr/share/phpmyadmin /var/www/phpmyadmin \
  && ln -s /etc/phpmyadmin/apache.conf /etc/apache2/conf-available/phpmyadmin.conf \
  && a2enconf phpmyadmin