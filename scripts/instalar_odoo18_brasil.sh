#!/bin/bash
# ==============================================================================
# Script de Instalação Automatizada: Odoo 18 + Localização Brasileira (OCA)
# ==============================================================================
# Compatível com: Ubuntu 24.04 LTS (limpo)
# Autor: Gerado automaticamente a partir do Guia de Instalação
# Data: 2026-02-21
#
# USO:
#   chmod +x instalar_odoo18_brasil.sh
#   sudo ./instalar_odoo18_brasil.sh
#
# O que este script faz:
#   1. Instala o Odoo 18 Community via repositório oficial
#   2. Instala PostgreSQL (se não existir)
#   3. Baixa todos os repositórios OCA necessários para localização BR
#   4. Instala as dependências Python (incluindo signxml, cryptography)
#   5. Configura o odoo.conf com os caminhos dos addons
#   6. Cria um banco de dados limpo com base_address_extended e l10n_br_base
#   7. Reinicia o Odoo pronto para uso
# ==============================================================================

set -e  # Parar ao primeiro erro

# ======================== CONFIGURAÇÕES ========================
ODOO_VERSION="18.0"
DB_NAME="${1:-odoo18br}"           # Nome do banco (padrão: odoo18br, ou passe como argumento)
OCA_DIR="/opt/odoo/oca"
ODOO_CONF="/etc/odoo/odoo.conf"
ODOO_USER="odoo"
LOG_FILE="/var/log/odoo_install_br.log"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # Sem cor

# ======================== FUNÇÕES AUXILIARES ========================

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
    echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') $1" >> "$LOG_FILE"
}

log_ok() {
    echo -e "${GREEN}[  OK]${NC} $1"
    echo "[  OK] $(date '+%Y-%m-%d %H:%M:%S') $1" >> "$LOG_FILE"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
    echo "[WARN] $(date '+%Y-%m-%d %H:%M:%S') $1" >> "$LOG_FILE"
}

log_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
    echo "[FAIL] $(date '+%Y-%m-%d %H:%M:%S') $1" >> "$LOG_FILE"
}

check_root() {
    if [ "$EUID" -ne 0 ]; then
        log_fail "Este script precisa ser executado como root (sudo)."
        exit 1
    fi
}

# ======================== INÍCIO ========================

echo ""
echo "============================================================"
echo "  Odoo 18 + Localização Brasileira (OCA) - Instalador"
echo "============================================================"
echo "  Banco de dados: $DB_NAME"
echo "  SO esperado:    Ubuntu 24.04 LTS"
echo "  Versão Odoo:    $ODOO_VERSION"
echo "============================================================"
echo ""

touch "$LOG_FILE"
check_root

# ======================== FASE 0: Pré-requisitos do Sistema ========================

log_info "Fase 0: Atualizando sistema e instalando pré-requisitos..."

apt-get update -y >> "$LOG_FILE" 2>&1
apt-get upgrade -y >> "$LOG_FILE" 2>&1
apt-get install -y \
    git \
    curl \
    wget \
    python3-pip \
    python3-dev \
    python3-venv \
    build-essential \
    libxml2-dev \
    libxslt1-dev \
    libldap2-dev \
    libsasl2-dev \
    libssl-dev \
    libffi-dev \
    libjpeg-dev \
    libpq-dev \
    zlib1g-dev \
    node-less \
    npm \
    xfonts-75dpi \
    xfonts-base \
    fontconfig \
    >> "$LOG_FILE" 2>&1

log_ok "Pré-requisitos do sistema instalados."

# ======================== FASE 1: PostgreSQL ========================

log_info "Fase 1: Verificando PostgreSQL..."

if command -v psql &> /dev/null; then
    log_ok "PostgreSQL já está instalado."
else
    log_info "Instalando PostgreSQL..."
    apt-get install -y postgresql postgresql-client >> "$LOG_FILE" 2>&1
    systemctl enable postgresql
    systemctl start postgresql
    log_ok "PostgreSQL instalado e iniciado."
fi

# ======================== FASE 2: Instalar Odoo 18 ========================

log_info "Fase 2: Verificando Odoo 18..."

if command -v odoo &> /dev/null || [ -f /usr/bin/odoo ]; then
    log_ok "Odoo já está instalado."
else
    log_info "Adicionando repositório oficial do Odoo 18..."

    # Instalar wkhtmltopdf (necessário para relatórios PDF)
    log_info "Instalando wkhtmltopdf..."
    wget -q https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6.1-3/wkhtmltox_0.12.6.1-3.jammy_amd64.deb -O /tmp/wkhtmltox.deb 2>> "$LOG_FILE"
    apt-get install -y /tmp/wkhtmltox.deb >> "$LOG_FILE" 2>&1 || log_warn "wkhtmltopdf pode já estar instalado ou falhou."
    rm -f /tmp/wkhtmltox.deb

    # Adicionar repositório Odoo
    wget -qO - https://nightly.odoo.com/odoo.key | gpg --dearmor -o /usr/share/keyrings/odoo-archive-keyring.gpg 2>> "$LOG_FILE"
    echo "deb [signed-by=/usr/share/keyrings/odoo-archive-keyring.gpg] https://nightly.odoo.com/18.0/nightly/deb/ ./" | tee /etc/apt/sources.list.d/odoo.list > /dev/null

    apt-get update -y >> "$LOG_FILE" 2>&1
    apt-get install -y odoo >> "$LOG_FILE" 2>&1

    log_ok "Odoo 18 instalado com sucesso."
fi

# Garantir que o serviço esteja parado para configuração
systemctl stop odoo 2>/dev/null || true

# ======================== FASE 3: Repositórios OCA (Localização BR) ========================

log_info "Fase 3: Baixando repositórios OCA ($ODOO_VERSION)..."

mkdir -p "$OCA_DIR"
cd "$OCA_DIR"

# Lista de repositórios OCA necessários
declare -A OCA_REPOS=(
    ["l10n-brazil"]="Repositório Principal do Brasil"
    ["account-financial-tools"]="Dependências Comuns (Financeiro)"
    ["product-attribute"]="Dependência uom_alias (Unidades de Medida)"
    ["server-ux"]="Dependências Técnicas Extras"
    ["bank-payment"]="Dependência de Pagamentos Bancários"
    ["account-payment"]="Dependência de Pagamentos (account_due_list)"
)

for repo in "${!OCA_REPOS[@]}"; do
    desc="${OCA_REPOS[$repo]}"
    if [ -d "$OCA_DIR/$repo" ]; then
        log_ok "$desc ($repo) já existe. Atualizando..."
        cd "$OCA_DIR/$repo"
        git pull origin "$ODOO_VERSION" >> "$LOG_FILE" 2>&1 || log_warn "Falha ao atualizar $repo"
        cd "$OCA_DIR"
    else
        log_info "Clonando $desc ($repo)..."
        if git clone -b "$ODOO_VERSION" "https://github.com/OCA/${repo}.git" >> "$LOG_FILE" 2>&1; then
            log_ok "$repo clonado."
        else
            log_fail "ERRO ao clonar $repo! Tentando novamente..."
            sleep 5
            git clone -b "$ODOO_VERSION" "https://github.com/OCA/${repo}.git" >> "$LOG_FILE" 2>&1 || {
                log_fail "Falha definitiva ao clonar $repo. Verifique sua conexão."
                exit 1
            }
            log_ok "$repo clonado na segunda tentativa."
        fi
    fi
done

# Ajustar permissões
chown -R "$ODOO_USER:$ODOO_USER" "$OCA_DIR"/*
log_ok "Permissões ajustadas para o usuário '$ODOO_USER'."

# Verificar módulos críticos
log_info "Verificando módulos críticos nos repositórios clonados..."

CRITICAL_MODULES=(
    "product-attribute/uom_alias"
    "l10n-brazil/l10n_br_base"
    "l10n-brazil/l10n_br_fiscal"
    "l10n-brazil/l10n_br_account"
    "server-ux/base_technical_user"
)

MISSING_MODULES=0
for mod_path in "${CRITICAL_MODULES[@]}"; do
    if [ -f "$OCA_DIR/$mod_path/__manifest__.py" ]; then
        log_ok "Módulo encontrado: $mod_path"
    else
        log_fail "MÓDULO NÃO ENCONTRADO: $OCA_DIR/$mod_path/__manifest__.py"
        MISSING_MODULES=$((MISSING_MODULES + 1))
    fi
done

if [ "$MISSING_MODULES" -gt 0 ]; then
    log_fail "$MISSING_MODULES módulo(s) crítico(s) ausente(s). Verifique se os repositórios foram clonados corretamente."
    log_fail "Diretórios em $OCA_DIR:"
    ls -la "$OCA_DIR" >> "$LOG_FILE" 2>&1
    ls -la "$OCA_DIR" >&2
    exit 1
fi

log_ok "Todos os módulos críticos verificados com sucesso."

# ======================== FASE 4: Dependências Python ========================

log_info "Fase 4: Instalando dependências Python..."

# 4.1 - Corrigir pacotes Debian que bloqueiam pip install
# No Ubuntu 24.04, alguns pacotes Python foram instalados pelo Debian e não possuem
# RECORD file, impedindo pip de desinstalá-los. Precisamos --ignore-installed para esses.
log_info "Corrigindo pacotes do sistema que bloqueiam pip (typing-extensions, cryptography)..."
python3 -m pip install --break-system-packages --ignore-installed \
    typing-extensions \
    cryptography \
    >> "$LOG_FILE" 2>&1
log_ok "Pacotes do sistema corrigidos."

# 4.2 - Requirements do l10n-brazil
cd "$OCA_DIR/l10n-brazil"
if [ -f requirements.txt ]; then
    log_info "Instalando requirements.txt..."
    python3 -m pip install -r requirements.txt --break-system-packages >> "$LOG_FILE" 2>&1
    log_ok "requirements.txt instalado."
else
    log_warn "requirements.txt não encontrado em $OCA_DIR/l10n-brazil"
fi

# 4.3 - Bibliotecas erpbrasil
log_info "Instalando bibliotecas erpbrasil..."
python3 -m pip install \
    erpbrasil.base \
    erpbrasil.assinatura \
    erpbrasil.transmissao \
    erpbrasil.edoc \
    --break-system-packages >> "$LOG_FILE" 2>&1
log_ok "Bibliotecas erpbrasil instaladas."

# 4.4 - signxml (requer cryptography >= 43, já instalado acima)
log_info "Instalando signxml..."
python3 -m pip install signxml --break-system-packages >> "$LOG_FILE" 2>&1
log_ok "signxml instalado."

# 4.5 - Todas as dependências externas dos módulos l10n-brazil
# Extraídas dos __manifest__.py: l10n_br_base requer num2words, phonenumbers, email-validator
# l10n_br_zip requer brazilcep; nfelib requer xsdata
log_info "Instalando dependências complementares..."
python3 -m pip install \
    lxml \
    pyOpenSSL \
    requests \
    num2words \
    phonenumbers \
    email-validator \
    brazilcep \
    "nfelib>=2.0.0" \
    --break-system-packages >> "$LOG_FILE" 2>&1
log_ok "Dependências complementares instaladas."

# ======================== FASE 5: Configurar odoo.conf ========================

log_info "Fase 5: Configurando $ODOO_CONF..."

# Definir o addons_path completo
NEW_ADDONS_PATH="addons_path = /usr/lib/python3/dist-packages/odoo/addons"
NEW_ADDONS_PATH+=", $OCA_DIR/l10n-brazil"
NEW_ADDONS_PATH+=", $OCA_DIR/account-financial-tools"
NEW_ADDONS_PATH+=", $OCA_DIR/product-attribute"
NEW_ADDONS_PATH+=", $OCA_DIR/server-ux"
NEW_ADDONS_PATH+=", $OCA_DIR/bank-payment"
NEW_ADDONS_PATH+=", $OCA_DIR/account-payment"

# Fazer backup do conf original
cp "$ODOO_CONF" "${ODOO_CONF}.bak.$(date +%Y%m%d%H%M%S)" 2>/dev/null || true

if [ -f "$ODOO_CONF" ]; then
    # Substituir a linha addons_path existente
    if grep -q "^addons_path" "$ODOO_CONF"; then
        sed -i "s|^addons_path.*|$NEW_ADDONS_PATH|" "$ODOO_CONF"
        log_ok "addons_path atualizado no $ODOO_CONF."
    else
        # Se não existir, inserir logo após [options] (mais robusto que append no final)
        sed -i "/^\[options\]/a $NEW_ADDONS_PATH" "$ODOO_CONF"
        log_ok "addons_path adicionado ao $ODOO_CONF (após [options])."
    fi
else
    log_warn "$ODOO_CONF não encontrado. Criando arquivo de configuração..."
    cat > "$ODOO_CONF" << EOF
[options]
$NEW_ADDONS_PATH
db_host = False
db_port = False
db_user = odoo
db_password = False
admin_passwd = admin
logfile = /var/log/odoo/odoo-server.log
EOF
    chown "$ODOO_USER:$ODOO_USER" "$ODOO_CONF"
    log_ok "$ODOO_CONF criado."
fi

# ======================== FASE 6: Criar Banco de Dados Limpo ========================

log_info "Fase 6: Configurando banco de dados '$DB_NAME'..."

# Verificar se o banco já existe
if sudo -u postgres psql -lqt | cut -d \| -f 1 | grep -qw "$DB_NAME"; then
    log_warn "Banco '$DB_NAME' já existe. Pulando criação."
    log_warn "Se quiser recriar, execute: sudo -u postgres dropdb $DB_NAME"
else
    log_info "Criando banco de dados '$DB_NAME'..."
    sudo -u postgres createdb -O "$ODOO_USER" "$DB_NAME" >> "$LOG_FILE" 2>&1
    log_ok "Banco '$DB_NAME' criado."
fi

# Inicializar o banco com módulos base e dependências críticas (sem dados demo)
# Incluímos uom_alias aqui para garantir que esteja registrado e instalado
# antes de tentar instalar l10n_br_fiscal no painel
log_info "Inicializando banco com módulos base (sem demo)... Isso pode demorar alguns minutos."
sudo -u "$ODOO_USER" odoo -c "$ODOO_CONF" -d "$DB_NAME" --without-demo=all \
    -i base_address_extended,l10n_br_base,uom_alias \
    --stop-after-init >> "$LOG_FILE" 2>&1

if [ $? -eq 0 ]; then
    log_ok "Banco inicializado com sucesso (base_address_extended, l10n_br_base, uom_alias)."
else
    log_warn "Houve avisos na inicialização do banco. Verifique o log: $LOG_FILE"
fi

# Atualizar a lista de módulos disponíveis para que todos os OCA apareçam no painel
log_info "Atualizando lista de módulos disponíveis no banco... Isso pode demorar."
sudo -u "$ODOO_USER" odoo -c "$ODOO_CONF" -d "$DB_NAME" --without-demo=all \
    -u base --stop-after-init >> "$LOG_FILE" 2>&1

if [ $? -eq 0 ]; then
    log_ok "Lista de módulos atualizada no banco."
else
    log_warn "Falha ao atualizar lista de módulos. Atualize manualmente no painel: Apps > Atualizar Lista de Aplicativos."
fi

# ======================== FASE 7: Iniciar Odoo ========================

log_info "Fase 7: Iniciando serviço Odoo..."

systemctl enable odoo >> "$LOG_FILE" 2>&1
systemctl start odoo

# Aguardar o serviço estabilizar
sleep 5

if systemctl is-active --quiet odoo; then
    log_ok "Odoo está RODANDO!"
else
    log_fail "Odoo não iniciou. Verifique o log com: journalctl -u odoo -n 50"
fi

# ======================== RESUMO FINAL ========================

# Capturar o IP do servidor
SERVER_IP=$(hostname -I | awk '{print $1}')

echo ""
echo "============================================================"
echo -e "  ${GREEN}✅ INSTALAÇÃO CONCLUÍDA COM SUCESSO!${NC}"
echo "============================================================"
echo ""
echo "  📋 RESUMO:"
echo "  ─────────────────────────────────────────"
echo "  Odoo 18:          Instalado"
echo "  Localização BR:   Repositórios OCA clonados"
echo "  Banco de dados:   $DB_NAME"
echo "  Arquivo de conf:  $ODOO_CONF"
echo "  Log de instalação: $LOG_FILE"
echo ""
echo "  🌐 ACESSO:"
echo "  ─────────────────────────────────────────"
echo "  URL:    http://${SERVER_IP}:8069"
echo "  Login:  admin"
echo "  Senha:  admin  (ALTERE IMEDIATAMENTE!)"
echo ""
echo "  📌 PRÓXIMOS PASSOS (no navegador):"
echo "  ─────────────────────────────────────────"
echo "  1. Faça login e altere a senha do admin"
echo "  2. Mude o idioma para Portuguese (BR)"
echo "  3. Ative o Modo de Desenvolvedor"
echo "  4. Atualize a Lista de Aplicativos"
echo "  5. Instale os módulos na ordem:"
echo "     - l10n_br_fiscal"
echo "     - l10n_br_fiscal_certificate"
echo "     - l10n_br_account"
echo "     - l10n_br_fiscal_edi"
echo "     - l10n_br_fiscal_dfe"
echo "     - l10n_br_nfse"
echo "     - l10n_br_nfse_focus (opcional)"
echo "  6. Configure sua Empresa (CNPJ, IE, IM, CNAE)"
echo ""
echo "============================================================"
echo ""
