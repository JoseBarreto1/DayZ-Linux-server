pt_BR

# 🧟 DayZ Linux Server — Setup Automático

> Scripts de configuração automática para servidores do **DayZ em Linux**, com o objetivo de facilitar a criação e manutenção do seu próprio servidor.

A base deste projeto é um **servidor real utilizado no dia a dia**, já contendo diversas configurações prontas. Com isso, é possível subir um servidor funcional com poucos comandos.

---

## 📑 Sumário

- [Como o projeto funciona](#-como-o-projeto-funciona)
- [Requisitos](#-requisitos)
- [Variáveis de configuração](#-variáveis-de-configuração)
- [Instalação passo a passo](#-instalação-passo-a-passo)
- [Portas necessárias](#-portas-necessárias)
- [Estrutura do projeto](#-estrutura-do-projeto)
- [Observações](#-observações)
- [Contribuições](#-contribuições)

---

## ⚙️ Como o projeto funciona

Dentro da pasta `scripts_server` possui apenas um script:

### 🚀 `start_server.sh`

Responsável por instalar, configurar e manter o servidor em execução, além de verificar e notificar atualizações do servidor e dos mods instalados.

| Funcionalidade | Descrição |
|---|---|
| 📦 Instalação automática | Instala o servidor caso ainda não exista |
| 🔽 Download de mods | Baixa e prepara os mods configurados |
| ▶️ Inicialização | Inicia o servidor automaticamente |
| 🔍 Monitoramento | Monitora o processo em tempo real |
| 🔄 Reinício por tempo | Reinicia automaticamente a cada **6 horas** |
| 💥 Reinício por crash | Reinicia automaticamente em caso de **crash** |
| 🔍 Verificação | Verifica atualizações do servidor e dos mods instalados |
| 🔔 Notificação | Notifica quando houver atualizações disponíveis |
| 💬 Discord Webhook | Suporte opcional para notificações via Discord |

---

## 📋 Requisitos

Antes de iniciar, certifique-se de que possui:

- **Sistema Operacional:** Linux (testado em Ubuntu 24.04)
- **Git** instalado
- **Conta Steam** ativa, com jogo **DayZ** na biblioteca da Steam

> ⚠️ **Importante:** Para baixar mods da Workshop, a conta Steam utilizada **precisa possuir o DayZ** na biblioteca.

---

## 🔐 Variáveis de configuração

Durante a execução do script, será solicitado suas credenciais que serão usadas pelo **SteamCMD** para baixar o servidor e os mods da Workshop.

---

### Opcionais — Notificações via Discord

```bash
WEBHOOK_URL_SERVER=""   # Notificações de reinício do servidor
WEBHOOK_URL_MOD=""      # Notificações de atualização de mods
```

Com isso você receberá notificações quando:

- 🔄 O servidor **reiniciar** ou **atualizar**
- ⬇️ Um mod for **atualizado**

---

## 🚀 Instalação passo a passo

**1. Crie a pasta do servidor:**

```bash
mkdir $HOME/steamcmd/dayzserver
cd $HOME/steamcmd/dayzserver
```

**2. Clone o projeto:**

```bash
git clone https://github.com/JoseBarreto1/DayZ-Linux-server.git .
```

**3. Inicie o servidor:**

```bash
./scripts_server/start_server.sh
```

**4. (Opcional) Configure o Webhook do Discord:**

```bash
sed -i 's/^WEBHOOK_URL_MOD=.*/WEBHOOK_URL_MOD="webhook_discord_url"/' scripts_server/start_server.sh
sed -i 's/^WEBHOOK_URL_SERVER=.*/WEBHOOK_URL_SERVER="webhook_discord_url"/' scripts_server/start_server.sh
```

Na primeira execução, o script irá automaticamente:

1. Instalar o **SteamCMD**
2. Baixar o **DayZ Server**
3. Baixar os **mods configurados**
4. **Iniciar** o servidor

---

## 🌐 Portas necessárias

Para que o servidor apareça no Launcher do DayZ, libere as seguintes portas:

| Porta | Protocolo | Uso |
|---|---|---|
| `2302 - 2305` | UDP | Servidor DayZ |
| `27016` | UDP | Steam Query |

> ⚠️ As portas devem estar liberadas no **firewall do sistema**, no **servidor/VPS** e no **roteador** (caso esteja hospedando em casa).

---

## 📂 Estrutura do projeto

```
DayZ-Linux-server/
│
├── scripts_server/
│   └── start_server.sh          # Script principal de inicialização e verificação de atualizações
│
├── serverDZ.cfg                 # Configurações do servidor
├── profiles/                    # Perfis do servidor
├── keys/                        # Chaves dos mods
├── mpmissions/                  # Arquivos de configuração do mapa
└── README.md
```

---

## ⚠️ Observações

- Testado em **Ubuntu 24.04**
- Pode não funcionar diretamente em outras distribuições Linux
- Dependendo da estrutura de diretórios do seu sistema, ajustes podem ser necessários

---

## 💡 Objetivo do projeto

Este projeto foi criado para:

- ✅ Facilitar a criação de servidores DayZ no Linux
- ✅ Automatizar atualizações de mods
- ✅ Reduzir manutenção manual
- ✅ Servir como base para administradores de servidores

---

## 🤝 Contribuições

Sugestões, melhorias e correções são bem-vindas!

1. Faça um **fork** do projeto
2. Crie uma **branch** para sua feature (`git checkout -b feature/minha-feature`)
3. Faça o **commit** das suas alterações (`git commit -m 'feat: minha feature'`)
4. Faça o **push** para a branch (`git push origin feature/minha-feature`)
5. Abra um **Pull Request**

---

## 🧟 Divirta-se!

Agora é só iniciar o servidor e sobreviver em Chernarus. Boa sorte, sobrevivente!