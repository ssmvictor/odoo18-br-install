#!/bin/bash
# ==============================================================================
# Script de Backup e Restauração do Banco de Dados Odoo 18
# ==============================================================================
# Uso:
#   BACKUP:      sudo ./backup_restore_odoo.sh backup [nome_do_banco]
#   RESTAURAR:   sudo ./backup_restore_odoo.sh restore [nome_do_banco] [arquivo.sql.gz]
#   LISTAR:      sudo ./backup_restore_odoo.sh list
# ==============================================================================

set -e

BACKUP_DIR="/opt/odoo/backups"
ODOO_USER="odoo"
ODOO_CONF="/etc/odoo/odoo.conf"
FILESTORE_DIR="/var/lib/odoo/.local/share/Odoo/filestore"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

mkdir -p "$BACKUP_DIR"

do_backup() {
    local DB_NAME="${1:-odoo18br}"
    local TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    local BACKUP_FILE="${BACKUP_DIR}/${DB_NAME}_${TIMESTAMP}.sql.gz"
    local FILESTORE_BACKUP="${BACKUP_DIR}/${DB_NAME}_${TIMESTAMP}_filestore.tar.gz"

    echo -e "${BLUE}[INFO]${NC} Fazendo backup do banco '$DB_NAME'..."

    # Parar Odoo para garantir consistência
    systemctl stop odoo 2>/dev/null || true
    sleep 2

    # Backup do banco de dados (comprimido)
    echo -e "${BLUE}[INFO]${NC} Exportando banco de dados..."
    sudo -u postgres pg_dump "$DB_NAME" | gzip > "$BACKUP_FILE"
    echo -e "${GREEN}[  OK]${NC} Banco salvo em: $BACKUP_FILE"

    # Backup do filestore (anexos, imagens etc.)
    if [ -d "$FILESTORE_DIR/$DB_NAME" ]; then
        echo -e "${BLUE}[INFO]${NC} Exportando filestore..."
        tar -czf "$FILESTORE_BACKUP" -C "$FILESTORE_DIR" "$DB_NAME"
        echo -e "${GREEN}[  OK]${NC} Filestore salvo em: $FILESTORE_BACKUP"
    else
        echo -e "${YELLOW}[WARN]${NC} Filestore não encontrado em $FILESTORE_DIR/$DB_NAME"
    fi

    # Reiniciar Odoo
    systemctl start odoo
    sleep 3

    echo ""
    echo -e "${GREEN}✅ Backup concluído!${NC}"
    echo "  Banco:     $BACKUP_FILE ($(du -h "$BACKUP_FILE" | cut -f1))"
    [ -f "$FILESTORE_BACKUP" ] && echo "  Filestore: $FILESTORE_BACKUP ($(du -h "$FILESTORE_BACKUP" | cut -f1))"
    echo ""
    echo "  Para transferir para outro servidor:"
    echo "    scp $BACKUP_FILE usuario@novo_servidor:/opt/odoo/backups/"
    [ -f "$FILESTORE_BACKUP" ] && echo "    scp $FILESTORE_BACKUP usuario@novo_servidor:/opt/odoo/backups/"
}

do_restore() {
    local DB_NAME="${1:-odoo18br}"
    local SQL_FILE="$2"
    local FILESTORE_FILE="$3"

    if [ -z "$SQL_FILE" ]; then
        echo -e "${RED}[FAIL]${NC} Uso: $0 restore <nome_banco> <arquivo.sql.gz> [arquivo_filestore.tar.gz]"
        exit 1
    fi

    if [ ! -f "$SQL_FILE" ]; then
        echo -e "${RED}[FAIL]${NC} Arquivo não encontrado: $SQL_FILE"
        exit 1
    fi

    echo -e "${YELLOW}[WARN]${NC} ATENÇÃO: Isso vai SUBSTITUIR o banco '$DB_NAME' atual!"
    read -p "Deseja continuar? (s/N): " CONFIRM
    if [ "$CONFIRM" != "s" ] && [ "$CONFIRM" != "S" ]; then
        echo "Operação cancelada."
        exit 0
    fi

    # Parar Odoo
    systemctl stop odoo 2>/dev/null || true
    sleep 2

    # Dropar banco existente e recriar
    echo -e "${BLUE}[INFO]${NC} Recriando banco '$DB_NAME'..."
    sudo -u postgres dropdb --if-exists "$DB_NAME" 2>/dev/null || true
    sudo -u postgres createdb -O "$ODOO_USER" "$DB_NAME"

    # Restaurar dump
    echo -e "${BLUE}[INFO]${NC} Restaurando dados do banco..."
    gunzip -c "$SQL_FILE" | sudo -u postgres psql "$DB_NAME" > /dev/null 2>&1

    echo -e "${GREEN}[  OK]${NC} Banco restaurado."

    # Restaurar filestore (se fornecido)
    if [ -n "$FILESTORE_FILE" ] && [ -f "$FILESTORE_FILE" ]; then
        echo -e "${BLUE}[INFO]${NC} Restaurando filestore..."
        mkdir -p "$FILESTORE_DIR"
        tar -xzf "$FILESTORE_FILE" -C "$FILESTORE_DIR"
        chown -R "$ODOO_USER:$ODOO_USER" "$FILESTORE_DIR/$DB_NAME"
        echo -e "${GREEN}[  OK]${NC} Filestore restaurado."
    fi

    # Reiniciar Odoo
    systemctl start odoo
    sleep 3

    if systemctl is-active --quiet odoo; then
        echo -e "${GREEN}✅ Restauração concluída! Odoo está rodando.${NC}"
    else
        echo -e "${RED}[FAIL]${NC} Odoo não iniciou. Verifique: journalctl -u odoo -n 50"
    fi
}

do_list() {
    echo ""
    echo "  Backups disponíveis em $BACKUP_DIR:"
    echo "  ─────────────────────────────────────────"
    if ls "$BACKUP_DIR"/*.sql.gz 1>/dev/null 2>&1; then
        ls -lh "$BACKUP_DIR"/*.sql.gz | awk '{print "  "$NF" ("$5")"}'
    else
        echo "  (nenhum backup encontrado)"
    fi
    echo ""
}

# ======================== MAIN ========================

case "${1:-}" in
    backup)
        do_backup "$2"
        ;;
    restore)
        do_restore "$2" "$3" "$4"
        ;;
    list)
        do_list
        ;;
    *)
        echo ""
        echo "Uso:"
        echo "  $0 backup  [nome_banco]                                    - Fazer backup"
        echo "  $0 restore <nome_banco> <arquivo.sql.gz> [filestore.tar.gz] - Restaurar"
        echo "  $0 list                                                     - Listar backups"
        echo ""
        ;;
esac
