pt_BR

# 🧟 DayZ Linux Server — Setup Automático

> Scripts de configuração automática para servidores do **DayZ em Linux**, com o objetivo de facilitar a criação e manutenção do seu próprio servidor.

A base deste projeto é um **servidor real utilizado no dia a dia**, já contendo diversas configurações prontas, incluindo:

- `serverDZ.cfg`
- `profiles` e `keys`
- Estrutura de mods
- Scripts de inicialização e atualização

Com isso, é possível subir um servidor funcional com poucos comandos.

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

Dentro da pasta `scripts_server` existem dois scripts principais:

### 🚀 `start_server.sh`

Responsável por instalar, configurar e manter o servidor em execução.

| Funcionalidade | Descrição |
|---|---|
| 📦 Instalação automática | Instala o servidor caso ainda não exista |
| 🔽 Download de mods | Baixa e prepara os mods configurados |
| ▶️ Inicialização | Inicia o servidor automaticamente |
| 🔍 Monitoramento | Monitora o processo em tempo real |
| 🔄 Reinício por tempo | Reinicia automaticamente a cada **6 horas** |
| 💥 Reinício por crash | Reinicia automaticamente em caso de **crash** |

---

### 🔎 `mod_update_checker.sh`

Responsável por verificar e notificar atualizações dos mods instalados.

| Funcionalidade | Descrição |
|---|---|
| 🔍 Verificação | Verifica atualizações dos mods instalados |
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

### Obrigatórias

Edite o arquivo `scripts_server/start_server.sh` e preencha:

```bash
USER_STEAM=""
PASSWORD_STEAM=""
```

Essas credenciais são usadas pelo **SteamCMD** para baixar o servidor e os mods da Workshop.

---

### Opcionais — Notificações via Discord

Edite o arquivo `scripts_server/mod_update_checker.sh` e preencha:

```bash
WEBHOOK_URL_SERVER=""   # Notificações de reinício do servidor
WEBHOOK_URL=""          # Notificações de atualização de mods
```

Com isso você receberá notificações quando:

- 🔄 O servidor **reiniciar**
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

**3. Configure suas credenciais Steam:**

```bash
sed -i 's/^USER_STEAM=.*/USER_STEAM="seu_usuario"/' scripts_server/start_server.sh
sed -i 's/^PASSWORD_STEAM=.*/PASSWORD_STEAM="sua_senha"/' scripts_server/start_server.sh
```

**4. (Opcional) Configure o Webhook do Discord:**

```bash
sed -i 's/^WEBHOOK_URL=.*/WEBHOOK_URL="webhook_discord_url"/' scripts_server/mod_update_checker.sh
sed -i 's/^WEBHOOK_URL_SERVER=.*/WEBHOOK_URL_SERVER="webhook_discord_url"/' scripts_server/mod_update_checker.sh
```

**5. Inicie o servidor:**

```bash
./scripts_server/start_server.sh
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
│   ├── start_server.sh          # Script principal de inicialização
│   └── mod_update_checker.sh    # Script de verificação de atualizações
│
├── serverDZ.cfg                 # Configurações do servidor
├── profiles/                    # Perfis do servidor
├── keys/                        # Chaves dos mods
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

en-US
# 🧟 DayZ Linux Server — Automatic Setup

> Automatic configuration scripts for **DayZ servers on Linux**, designed to simplify the creation and maintenance of your own server.

This project is based on a **real server used daily**, already containing several ready-to-use configurations, including:

- `serverDZ.cfg`
- `profiles` and `keys`
- Mod folder structure
- Startup and update scripts

This allows you to spin up a fully functional server with just a few commands.

---

## 📑 Table of Contents

- [How it works](#%EF%B8%8F-how-it-works)
- [Requirements](#-requirements)
- [Configuration variables](#-configuration-variables)
- [Step-by-step installation](#-step-by-step-installation)
- [Required ports](#-required-ports)
- [Project structure](#-project-structure)
- [Notes](#-notes)
- [Contributing](#-contributing)

---

## ⚙️ How it works

Inside the `scripts_server` folder there are two main scripts:

### 🚀 `start_server.sh`

Responsible for installing, configuring, and keeping the server running.

| Feature | Description |
|---|---|
| 📦 Auto install | Installs the server if it doesn't exist yet |
| 🔽 Mod download | Downloads and prepares the configured mods |
| ▶️ Startup | Starts the server automatically |
| 🔍 Monitoring | Monitors the process in real time |
| 🔄 Timed restart | Automatically restarts every **6 hours** |
| 💥 Crash restart | Automatically restarts on **crash** |

---

### 🔎 `mod_update_checker.sh`

Responsible for checking and notifying mod updates.

| Feature | Description |
|---|---|
| 🔍 Check | Checks for updates on installed mods |
| 🔔 Notification | Notifies when updates are available |
| 💬 Discord Webhook | Optional support for Discord notifications |

---

## 📋 Requirements

Before getting started, make sure you have:

- **OS:** Linux (tested on Ubuntu 24.04)
- **Git** installed
- An active **Steam account**
- **DayZ** in your Steam library

> ⚠️ **Important:** To download Workshop mods, the Steam account used **must own DayZ**.

---

## 🔐 Configuration variables

### Required

Edit the file `scripts_server/start_server.sh` and fill in:

```bash
USER_STEAM=""
PASSWORD_STEAM=""
```

These credentials are used by **SteamCMD** to download the server and Workshop mods.

---

### Optional — Discord Notifications

Edit the file `scripts_server/mod_update_checker.sh` and fill in:

```bash
WEBHOOK_URL_SERVER=""   # Server restart notifications
WEBHOOK_URL=""          # Mod update notifications
```

You will then receive notifications when:

- 🔄 The server **restarts**
- ⬇️ A mod is **updated**

---

## 🚀 Step-by-step installation

**1. Create the server folder:**

```bash
mkdir $HOME/steamcmd/dayzserver
cd $HOME/steamcmd/dayzserver
```

**2. Clone the project:**

```bash
git clone https://github.com/JoseBarreto1/DayZ-Linux-server.git .
```

**3. Set your Steam credentials:**

```bash
sed -i 's/^USER_STEAM=.*/USER_STEAM="your_username"/' scripts_server/start_server.sh
sed -i 's/^PASSWORD_STEAM=.*/PASSWORD_STEAM="your_password"/' scripts_server/start_server.sh
```

**4. (Optional) Set the Discord Webhook:**

```bash
sed -i 's/^WEBHOOK_URL=.*/WEBHOOK_URL="your_discord_webhook_url"/' scripts_server/mod_update_checker.sh
sed -i 's/^WEBHOOK_URL_SERVER=.*/WEBHOOK_URL_SERVER="your_discord_webhook_url"/' scripts_server/mod_update_checker.sh
```

**5. Start the server:**

```bash
./scripts_server/start_server.sh
```

On the first run, the script will automatically:

1. Install **SteamCMD**
2. Download the **DayZ Server**
3. Download the **configured mods**
4. **Start** the server

---

## 🌐 Required ports

For your server to appear in the DayZ Launcher, open the following ports:

| Port | Protocol | Usage |
|---|---|---|
| `2302 - 2305` | UDP | DayZ Server |
| `27016` | UDP | Steam Query |

> ⚠️ These ports must be open on your **system firewall**, **server/VPS**, and **router** (if hosting at home).

---

## 📂 Project structure

```
DayZ-Linux-server/
│
├── scripts_server/
│   ├── start_server.sh          # Main startup script
│   └── mod_update_checker.sh    # Mod update checker script
│
├── serverDZ.cfg                 # Server configuration file
├── profiles/                    # Server profiles
├── keys/                        # Mod keys
└── README.md
```

---

## ⚠️ Notes

- Tested on **Ubuntu 24.04**
- May not work out of the box on other Linux distributions
- Depending on your system's directory structure, adjustments may be required

---

## 💡 Project goals

This project was created to:

- ✅ Simplify DayZ server setup on Linux
- ✅ Automate mod updates
- ✅ Reduce manual maintenance
- ✅ Serve as a base for server administrators

---

## 🤝 Contributing

Suggestions, improvements, and bug fixes are welcome!

1. **Fork** the project
2. Create a **branch** for your feature (`git checkout -b feature/my-feature`)
3. **Commit** your changes (`git commit -m 'feat: my feature'`)
4. **Push** to the branch (`git push origin feature/my-feature`)
5. Open a **Pull Request**

---

## 🧟 Have fun!

Now just start the server and survive in Chernarus. Good luck, survivor!