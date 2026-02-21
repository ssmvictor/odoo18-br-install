# Guia Definitivo: Instalação Limpa Odoo 18 + Localização Brasileira (OCA)

Este passo a passo cobre desde a preparação do servidor até a ativação dos módulos fiscais dentro do sistema.

## Fase 1: Preparação do Ambiente no Servidor (Terminal)

Esses comandos devem ser executados no terminal SSH do seu servidor (logado como `root`).

**1. Preparar o diretório para os módulos extras (OCA):**
Vamos criar uma pasta organizada fora do núcleo do Odoo para os módulos brasileiros e afins.
```bash
mkdir -p /opt/odoo/oca
cd /opt/odoo/oca
```

**2. Baixar os Repositórios Necessários:**
A localização brasileira não é um arquivo só; ela depende de vários "pacotes" da OCA. Baixe todos usando as branchs da **versão 18.0**:
```bash
# Repositório Principal do Brasil
git clone -b 18.0 https://github.com/OCA/l10n-brazil.git

# Dependências Comuns (Financeiro)
git clone -b 18.0 https://github.com/OCA/account-financial-tools.git

# Dependência do uom_alias (Unidades de Medida)
git clone -b 18.0 https://github.com/OCA/product-attribute.git

# Dependências Técnicas Extras
git clone -b 18.0 https://github.com/OCA/server-ux.git

# Dependência de Pagamentos Bancários (account_payment_order)
git clone -b 18.0 https://github.com/OCA/bank-payment.git

# Dependência de Pagamentos (account_due_list)
git clone -b 18.0 https://github.com/OCA/account-payment.git
```

**3. Ajustar Permissões de Pasta:**
O usuário de sistema do Odoo (geralmente chamado de `odoo`) precisa ter autorização para ler essas pastas.
```bash
chown -R odoo:odoo /opt/odoo/oca/*
```

**4. Instalar as Bibliotecas Python do Brasil (Requirements):**
Os módulos fiscais precisam de pacotes do Python (como bibliotecas para gerar XML de notas fiscais). Instale usando o gerenciador `pip` da sua máquina:
```bash
cd /opt/odoo/oca/l10n-brazil
python3 -m pip install -r requirements.txt --break-system-packages
python3 -m pip install erpbrasil.assinatura erpbrasil.transmissao erpbrasil.edoc --no-deps --break-system-packages
```

**4.1. Instalar Dependências Extras (Certificado Digital / Assinatura):**
As bibliotecas do `erpbrasil.assinatura` precisam do pacote `signxml` e de uma versão atualizada do `cryptography`, que não são instalados pelo `--no-deps` acima. No Ubuntu 24.04, o `cryptography` do sistema (Debian) trava a desinstalação, então usamos `--ignore-installed` para forçar:
```bash
python3 -m pip install cryptography --break-system-packages --ignore-installed
python3 -m pip install signxml --break-system-packages
```
> **⚠️ Nota:** Se durante a instalação de outros módulos fiscais aparecer `ModuleNotFoundError: No module named 'xxx'`, instale o pacote faltante com o mesmo padrão: `python3 -m pip install xxx --break-system-packages`.

**5. Configurar o Caminho no Odoo (`odoo.conf`):**
Você precisa dizer ao Odoo onde estão as novas pastas. Edite o arquivo `/etc/odoo/odoo.conf` (via `nano` ou `vim`) e encontre a linha `addons_path`. Adicione os novos caminhos separados por vírgula no final da linha:
> **Exemplo de como deve ficar o seu `addons_path`:**
> `addons_path = /usr/lib/python3/dist-packages/odoo/addons, /opt/odoo/oca/l10n-brazil, /opt/odoo/oca/account-financial-tools, /opt/odoo/oca/product-attribute, /opt/odoo/oca/server-ux, /opt/odoo/oca/bank-payment, /opt/odoo/oca/account-payment`

**6. Reiniciar o Odoo para Aplicar as Mudanças:**
```bash
systemctl restart odoo
```
Você pode confirmar se o serviço subiu sem erros com `systemctl status odoo`.

---

## Fase 2: Instalação Limpa do Banco de Dados (Opcional)

Caso queira apagar tudo e recomeçar (zerado, sem dados de demonstração americanos), faça isso no terminal:

**1. Apagar o banco antigo:**
```bash
sudo -u postgres dropdb nome_do_banco  # (Ex: datavi)
```

**2. Criar um banco de dados novo:**
```bash
sudo -u postgres createdb -O odoo nome_do_banco
```

**3. Iniciar o Odoo forçando a instalação do módulo base brasileiro:**
Isso injeta o banco do zero e força a instalar o "l10n_br_base" bloqueando os dados "demo/lixo":
```bash
sudo -u odoo odoo -c /etc/odoo/odoo.conf -d nome_do_banco --without-demo=all -i l10n_br_base --stop-after-init

# Reinicie o serviço após concluir
systemctl restart odoo
```

---

## Fase 3: Configuração Inicial Dentro do Painel do Odoo (Navegador)

Acesse seu Odoo no navegador: `http://seu_ip:8069`.

**1. Redefinir a senha do "Administrador":**
*   Faça login com e-mail: `admin` e senha: `admin`
*   Vá no canto superior direito (no seu nome) > **Preferências** > **Segurança** e altere a senha.

**2. Mudar o Idioma para Português:**
*   Vá em **Configurações (Settings)** > Procure na tela por **Idiomas (Languages)**.
*   Clique em "Adicionar Idiomas" > Busque por **Portuguese (BR)**.
*   Ao concluir, aceite trocar a sua conta atual para `pt_BR`.

**3. Ativar o Modo de Desenvolvedor:**
*   Isso é necessário para instalar módulos avançados e atualizar a lista.
*   Vá em **Configurações** > role até o final da tela > clique em **Ativar modo de desenvolvedor (Activate the developer mode)**.

**4. Atualizar os Módulos Lidos:**
*   Vá no menu principal **Aplicativos**.
*   No menu superior, clique no submenu **Atualizar Lista de Aplicativos (Update Apps List)** e confirme.

**5. Instalar Sequencialmente as Ferramentas Nacionais:**
Remova a palavra "Aplicativos" da barra de busca do Odoo e instale os seguintes módulos nesta ordem (clicando no botão Ativar/Activate):
1. `l10n_br_base` (Localização Brasil - Se você fez pelo terminal, este já estará instalado)
2. `l10n_br_fiscal` (Configurações e Tabela Fiscais Principais - PIS/COFINS/ICMS etc.)
3. `l10n_br_fiscal_certificate` (Gerenciamento de Certificado Digital A1)
4. `l10n_br_account` (Conta e Faturamento adaptados para o país)
5. `l10n_br_fiscal_edi` (Intercâmbio Eletrônico de Dados - substitui o antigo `l10n_br_eletronic_document`)
6. `l10n_br_fiscal_dfe` (Distribuição de Documentos Fiscais Eletrônicos)
7. `l10n_br_nfse` (Layout e campos específicos de Notas Fiscais de Serviço)
8. `l10n_br_nfse_focus` (Integração NFS-e via gateway FocusNFe - opcional)

**6. Configurar as Conexões:**
O último passo da jornada é configurar sua Empresa (`Configurações` > `Empresas` > colocar o CNPJ, Inscrição Estadual/Municipal, CNAE) e instalar a sua API/Integração de prefeitura (via módulos próprios ou integradores de terceiros como a Focus NFe).

---

## Fase 4: Scripts de Automação (Portabilidade)

Estes scripts permitem replicar toda a instalação em qualquer servidor Ubuntu 24.04 limpo.

### Script 1: `instalar_odoo18_brasil.sh` — Instalação Completa do Zero
Instala o Odoo 18, repositórios OCA, dependências Python, configura o `odoo.conf` e cria o banco de dados com `l10n_br_base`.

**Como usar em um servidor novo:**
```bash
# 1. Copiar o script para o servidor
scp instalar_odoo18_brasil.sh root@IP_DO_SERVIDOR:/root/

# 2. Conectar via SSH e executar
ssh root@IP_DO_SERVIDOR
chmod +x instalar_odoo18_brasil.sh
./instalar_odoo18_brasil.sh meu_banco
```
> O nome do banco é opcional. Padrão: `odoo18br`.

### Script 2: `backup_restore_odoo.sh` — Backup e Restauração do Banco
Faz backup completo do banco PostgreSQL + filestore (anexos/imagens) e permite restaurar em outro servidor.

**Como usar:**
```bash
# Copiar o script para o servidor
scp backup_restore_odoo.sh root@IP_DO_SERVIDOR:/root/
ssh root@IP_DO_SERVIDOR
chmod +x backup_restore_odoo.sh

# Fazer backup
./backup_restore_odoo.sh backup meu_banco

# Listar backups existentes
./backup_restore_odoo.sh list

# Restaurar um backup
./backup_restore_odoo.sh restore meu_banco /opt/odoo/backups/meu_banco_20260221.sql.gz
```

### Fluxo Completo de Migração para Outro Servidor:
```
SERVIDOR ANTIGO:                      SERVIDOR NOVO:
┌─────────────────────┐               ┌─────────────────────┐
│ 1. Fazer backup     │   scp/sftp    │ 3. Rodar script de  │
│    ./backup_restore │ ────────────► │    instalação        │
│    .sh backup       │               │    ./instalar_odoo   │
│                     │               │    18_brasil.sh      │
│ 2. Copiar arquivos  │               │                     │
│    .sql.gz e        │               │ 4. Restaurar backup │
│    filestore.tar.gz │               │    ./backup_restore  │
│                     │               │    .sh restore       │
└─────────────────────┘               └─────────────────────┘
```
