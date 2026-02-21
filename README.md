# Odoo 18 - Instalação Automatizada e Localização Brasileira (OCA) 🇧🇷

Este repositório fornece ferramentas e documentação completas para a instalação e configuração de um ambiente Odoo 18 (Community) adaptado para o Brasil em servidores rodando **Ubuntu 24.04 LTS**.

Todo o processo foi desenhado para facilitar o deploy limpo das bibliotecas e dependências da [OCA (Odoo Community Association)](https://github.com/OCA/l10n-brazil) necessárias para a localização brasileira (emissão de notas fiscais, integração bancária, etc).

## � Estrutura do Repositório

```text
odoo18-br-install/
├── README.md
├── docs/
│   └── Guia_Instalacao_Odoo18_LocalizacaoBR.md
└── scripts/
    ├── instalar_odoo18_brasil.sh
    └── backup_restore_odoo.sh
```

- 📄 `docs/Guia_Instalacao_Odoo18_LocalizacaoBR.md`: Documentação técnica detalhada, explicando passo a passo o que cada comando faz, desde os requisitos do servidor até a instalação e configuração dos módulos via painel do Odoo.
- ⚙️ `scripts/instalar_odoo18_brasil.sh`: Script em shell que automatiza 100% o processo de preparação do servidor, instalação do Odoo, clone dos repositórios OCA, instalação dos pacotes Python e configuração do `odoo.conf`.
- 💾 `scripts/backup_restore_odoo.sh`: Script utilitário para facilitar o backup e a restauração do banco de dados e do _filestore_ do seu ERP.

## 🚀 Como usar a Instalação Automatizada

> **Aviso:** Execute o script em uma instalação limpa do Ubuntu 24.04.

1. Faça o clone do repositório no seu servidor:
   ```bash
   git clone https://github.com/ssmvictor/odoo18-br-install.git
   cd odoo18-br-install/scripts
   ```

2. Dê permissão de execução ao instalador:
   ```bash
   chmod +x instalar_odoo18_brasil.sh
   ```

3. Execute como `root` (ou com `sudo`). Você pode, opcionalmente, passar o nome que deseja para o banco de dados (o padrão é `odoo18br`):
   ```bash
   sudo ./instalar_odoo18_brasil.sh meu_banco_odoo
   ```

4. Acesse seu Odoo pelo navegador em `http://IP_DO_SERVIDOR:8069` e acompanhe a fase 3 do nosso [Guia Completo](./docs/Guia_Instalacao_Odoo18_LocalizacaoBR.md) para ativar os módulos.

## 💾 Usando o Script de Backup / Restore

O utilitário de backup pode ser executado para extrair rapidamente cópias do banco e dos anexos (filestore):

**Para fazer Backup:**
```bash
sudo ./backup_restore_odoo.sh backup nome_do_banco
```

**Para Restaurar (Cuidado: substitui o banco atual):**
```bash
sudo ./backup_restore_odoo.sh restore nome_do_banco arquivo_filestore.tar.gz
```

Consulte as outras opções (como `list`) executando o script sem argumentos.

## 🤝 Contribuições

Este repositório tem como base o ecossistema maduro mantido pela comunidade da [OCA (Odoo Community Association)](https://github.com/OCA/l10n-brazil). Sugestões, melhorias nos scripts e atualizações para contemplar novos módulos da versão 18.0 são bem-vindas através de _Pull Requests_ ou na aba _Issues_.
