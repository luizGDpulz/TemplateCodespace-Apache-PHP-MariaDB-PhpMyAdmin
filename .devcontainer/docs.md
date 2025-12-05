# Tutorial: Subir o Ambiente (GitHub Codespaces)

Este projeto é plug and play em Codespaces: basta clonar o repositório e abrir um Codespace na branch desejada. O DevContainer constrói a imagem e executa o `init.sh` automaticamente, subindo Apache, PHP, MariaDB e phpMyAdmin.

## Passo 0 — Abrir o Codespace
- No GitHub: Code → Codespaces → Create codespace (escolha a branch).
- Aguarde o build e a inicialização. Ao finalizar, o ambiente está pronto.

## O que sobe automaticamente
- Apache servindo a aplicação.
- MariaDB inicializado e acessível localmente.
- phpMyAdmin disponível em `<URL do Repositório>/phpmyadmin`.
- Se houver `public/`, o `DocumentRoot` do Apache é ajustado para essa pasta.

## Scripts de manutenção (rodar dentro do Codespace)
Use estes scripts para reaplicar configurações, preparar o banco ou reiniciar serviços. Rode-os no terminal do Codespace, na raiz do projeto.

1) `init.sh` — inicializar e ajustar Apache
- Caminho: `.devcontainer/init.sh`
- Quando usar: após mudar configs de Apache/DocumentRoot ou para reaplicar a inicialização.
- Como rodar:
```bash
bash .devcontainer/init.sh $(basename "$PWD")
```

2) `setup.sh` — preparar banco e dependências de dev
- Caminho: `scripts/setup.sh`
- O que faz:
	- Inicia/aguarda MariaDB.
	- Conecta como root (sem senha ou com senha dev `_43690`), cria o DB `jebusiness` e o usuário `jebusiness@127.0.0.1`.
	- Executa migrations (`php scripts/migration.php`).
	- Garante `git-lfs` instalado (ou remove o hook de pre-push como fallback).
- Como rodar:
```bash
bash scripts/setup.sh
```

3) `reload-services.sh` — recarregar/reiniciar serviços
- Caminho: `scripts/reload-services.sh`
- O que faz:
	- Recarrega Apache e faz restart se necessário.
	- Reinicia MariaDB/MySQL e aguarda resposta.
- Como rodar:
```bash
bash scripts/reload-services.sh
```

## Verificações rápidas
```bash
curl -I http://localhost                 # Verificar Apache
ps aux | egrep 'mysqld|mariadb'          # Ver a instância do DB
service mariadb status || true           # Status do DB
```

## Reutilizar este DevContainer em outros projetos
Copie a pasta `.devcontainer/` (com `devcontainer.json`, `Dockerfile` e `init.sh`) para outro projeto. Torne o `init.sh` executável:
```bash
chmod +x .devcontainer/init.sh
```
Abra como Codespace e o ambiente sobe igual (plug and play).

## Observações
- Ambiente destinado a desenvolvimento (não inclui hardening de produção).
- Se o repositório usar Git LFS, o DevContainer já inclui `git-lfs`. Fora do Codespaces, instale `git-lfs` para evitar erros de push.