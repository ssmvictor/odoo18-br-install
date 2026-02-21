# 🇧🇷 odoo18-br-install

Scripts e guia completo para instalação automatizada do **Odoo 18** com **Localização Brasileira (OCA)** em servidores Ubuntu 24.04 LTS.

---

## 📦 Arquivos do Repositório

| Arquivo | Descrição |
|---|---|
| `instalar_odoo18_brasil.sh` | Script de instalação completa do zero (Odoo 18 + OCA Brasil) |
| `backup_restore_odoo.sh` | Script de backup e restauração do banco PostgreSQL + filestore |
| `Guia_Instalacao_Odoo18_LocalizacaoBR.md` | Guia passo a passo detalhado para instalação manual e configuração |

---

## 🚀 Instalação Rápida (Script Automatizado)

> **Pré-requisito:** Ubuntu 24.04 LTS limpo, logado como `root`.

```bash
# 1. Baixar o script
curl -O https://raw.githubusercontent.com/ssmvictor/odoo18-br-install/main/instalar_odoo18_brasil.sh

# 2. Dar permissão de execução
chmod +x instalar_odoo18_brasil.sh

# 3. Executar (nome do banco é opcional, padrão: odoo18br)
./instalar_odoo18_brasil.sh meu_banco
```

O script instala e configura automaticamente:
- ✅ Odoo 18 (Community)
- ✅ Repositórios OCA: `l10n-brazil`, `account-financial-tools`, `product-attribute`, `server-ux`, `bank-payment`, `account-payment`
- ✅ Dependências Python fiscais (`erpbrasil.*`, `signxml`, `cryptography`)
- ✅ Configuração do `odoo.conf` com os `addons_path` corretos
- ✅ Banco de dados com `l10n_br_base` instalado e sem dados de demonstração

---

## 🔁 Backup e Restauração

```bash
chmod +x backup_restore_odoo.sh

# Fazer backup
./backup_restore_odoo.sh backup meu_banco

# Listar backups
./backup_restore_odoo.sh list

# Restaurar
./backup_restore_odoo.sh restore meu_banco /opt/odoo/backups/meu_banco_YYYYMMDD.sql.gz
```

---

## 📋 Módulos OCA Brasileiros (Ordem de Instalação)

Após a instalação, acesse o Odoo via navegador (`http://seu_ip:8069`) e instale os módulos nesta sequência:

1. `l10n_br_base` — Localização Base Brasil
2. `l10n_br_fiscal` — Tabelas e Configurações Fiscais (ICMS, PIS, COFINS)
3. `l10n_br_fiscal_certificate` — Gerenciamento de Certificado Digital A1
4. `l10n_br_account` — Faturamento adaptado para o Brasil
5. `l10n_br_fiscal_edi` — Documentos Fiscais Eletrônicos (NF-e)
6. `l10n_br_fiscal_dfe` — Distribuição de DF-e
7. `l10n_br_nfse` — Nota Fiscal de Serviço Eletrônica
8. `l10n_br_nfse_focus` — Integração NFS-e via FocusNFe *(opcional)*

---

## 📖 Guia Detalhado

Para instalação manual ou configurações avançadas, consulte o [Guia Completo de Instalação](./Guia_Instalacao_Odoo18_LocalizacaoBR.md).

---

## 🔧 Migração entre Servidores

```
SERVIDOR ANTIGO                        SERVIDOR NOVO
┌──────────────────────┐               ┌──────────────────────┐
│ 1. Fazer backup      │   scp/sftp    │ 3. Rodar instalação  │
│    backup_restore.sh │ ────────────► │    instalar_odoo18   │
│    backup            │               │    _brasil.sh        │
│                      │               │                      │
│ 2. Copiar .sql.gz    │               │ 4. Restaurar backup  │
│    + filestore.tar   │               │    backup_restore.sh │
│                      │               │    restore           │
└──────────────────────┘               └──────────────────────┘
```

---

## 📄 Licença

MIT
