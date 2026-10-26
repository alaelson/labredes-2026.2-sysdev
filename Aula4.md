# Aula 04: Acesso Remoto Seguro com OpenSSH e Redirecionamento de Portas no VirtualBox

Nesta prática você configurará o acesso remoto via **SSH (Secure Shell)** à sua VM Ubuntu Server, usando o **Redirecionamento de Portas (Port Forwarding)** do modo NAT. Também fará o diagnóstico de interfaces, rotas, sessões e portas TCP no Linux (Guest) e no Windows (Host).

**Pré-requisitos:** Aulas 01 a 03 concluídas (VM instalada, usuário `administrador`, VM em modo **NAT** com IP `10.0.2.15`).

---

## 1. Fundamentos

### Modo NAT
A interface da VM em modo **NAT** recebe, em geral, o IP `10.0.2.15` em uma rede privada oculta criada pelo VirtualBox.
* **Saída:** a VM acessa a internet pela conexão do host.
* **Entrada:** o host **não alcança** `10.0.2.15` diretamente (rede isolada pelo roteador virtual).

### SSH e Port Forwarding
O SSH usa a porta **TCP 22** e permite administrar o servidor de forma criptografada. Para alcançá-lo em modo NAT, criamos uma regra de redirecionamento:

```text
Terminal Windows (127.0.0.1:5222) --> VirtualBox NAT --> Ubuntu Server (10.0.2.15:22)
```

Tráfego enviado à porta `5222` do host é repassado pelo VirtualBox à porta `22` da VM.

---

## 2. Diagnóstico e Preparação no Ubuntu Server

Acesse a VM com o usuário `administrador`.

### Passo 1: Estado da rede
```bash
administrador@ubuntu_server:~$ netplan status
```
A interface `enp0s3` deve estar com DHCP e IP `10.0.2.15/24`.

### Passo 2: Verificar o OpenSSH e instalar utilitários
```bash
administrador@ubuntu_server:~$ dpkg -l | grep openssh-server
administrador@ubuntu_server:~$ sudo apt update
administrador@ubuntu_server:~$ sudo apt install -y openssh-server net-tools traceroute
administrador@ubuntu_server:~$ systemctl status ssh
```
O serviço `ssh` deve estar `active (running)`.

### Passo 3: Interfaces com `ifconfig`
```bash
administrador@ubuntu_server:~$ ifconfig
```
* `inet 10.0.2.15`: IPv4 da VM; `netmask 255.255.255.0`: equivale a `/24`.
* `ether ...`: MAC da placa virtual.
* `lo` (`127.0.0.1`): loopback.

### Passo 4: Gateway padrão
```bash
administrador@ubuntu_server:~$ route -n
```
`-n` mostra endereços numéricos (sem DNS). A linha `0.0.0.0` aponta o gateway `10.0.2.2` via `enp0s3`.

### Passo 5: Rastreamento
```bash
administrador@ubuntu_server:~$ traceroute 8.8.8.8
```
O salto 1 deve ser `10.0.2.2`.

### Passo 6: Sessões ativas
```bash
administrador@ubuntu_server:~$ w
```
Antes do SSH, só aparece o console local (`tty1`).

---

## 3. Inspeção do Host Windows (PowerShell)

### Passo 7: Interfaces
```powershell
PS C:\Users\Aluno> ipconfig /all
```
Note que o MAC do Windows difere do MAC da VM.

### Passo 8: Porta 5222 ANTES da regra
```powershell
PS C:\Users\Aluno> netstat -an | findstr 5222
```
**Resultado esperado:** nenhuma linha.

---

## 4. Redirecionamento de Portas no VirtualBox

1. Selecione a VM `ubuntu_server` > **Configurações** (`Ctrl + S`) > **Rede**.
2. **Adaptador 1** (NAT) > **Avançado** > **Redirecionamento de Portas**.
3. Clique em **`+`** e preencha:

| Nome | Protocolo | IP do Hospedeiro | Porta do Hospedeiro | IP do Convidado | Porta do Convidado |
| :--- | :---: | :---: | :---: | :---: | :---: |
| SSH | TCP | 127.0.0.1 | 5222 | 10.0.2.15 | 22 |

4. Clique em **OK**.

> Em laboratório compartilhado, se a porta `5222` estiver em uso, use outra (ex.: `5222 + nº do computador`) e registre no relatório.

---

## 5. Validação e Conexão SSH

### Passo 9: Porta DEPOIS da regra
```powershell
PS C:\Users\Aluno> netstat -an | findstr 5222
```
Esperado: `TCP 127.0.0.1:5222 0.0.0.0:0 LISTENING`.

### Passo 10: Conectar via SSH
```powershell
PS C:\Users\Aluno> ssh -p 5222 administrador@127.0.0.1
```
Digite `yes` para aceitar o fingerprint no primeiro acesso e informe a senha.

### Passo 11: Porta DURANTE a sessão
Em uma **segunda janela** do PowerShell:
```powershell
PS C:\Users\Aluno> netstat -an | findstr 5222
```
Esperado: além do `LISTENING`, linhas `ESTABLISHED` entre `127.0.0.1:5222` e a porta local do cliente SSH.

### Passo 12: `w` dentro da sessão SSH
```bash
administrador@ubuntu_server:~$ w
```
Esperado: `tty1` (console) e `pts/0` (pseudo-terminal da sessão SSH), com `FROM` = `10.0.2.2` (gateway NAT). Encerre com `exit`.

---

## 6. Atividade: Relatório Técnico

Cada aluno registra as evidências no **seu repositório de entrega** (`lsor-2026.2-sysdev-atividades-<nomedoaluno>`).

### Onde incorporar na estrutura do repositório

```text
lsor-2026.2-sysdev-atividades-<nomedoaluno>/
├── README.md               # Adicionar o link para atividade-aula4.md
├── atividade-aula1.md
├── atividade-aula2.md
├── atividade-aula3.md
├── atividade-aula4.md      # NOVO: Relatório Técnico da Aula 04
└── imagens/
    ├── aula4_ifconfig.png
    ├── aula4_route.png
    ├── aula4_traceroute.png
    ├── aula4_netstat_antes.png
    ├── aula4_regra_virtualbox.png
    ├── aula4_netstat_listening.png
    ├── aula4_ssh_login.png
    ├── aula4_netstat_established.png
    └── aula4_w_pts0.png
```

**Regras:**
* O relatório é o arquivo `atividade-aula4.md` na raiz do repositório.
* Capturas de tela em `imagens/`, nomeadas `aula4_descricao.png` (minúsculas, sem espaços ou acentos).
* Referencie com caminho relativo: `![netstat LISTENING](imagens/aula4_netstat_listening.png)`.
* Cada evidência deve ter o comando executado, a saída obtida e a imagem.
* Adicione ao `README.md` do repositório um link para `atividade-aula4.md`.

### Evidências obrigatórias
1. **Linux Guest:** `ifconfig` (IP `10.0.2.15` e MAC); `route -n` (gateway `10.0.2.2`); `traceroute 8.8.8.8`.
2. **Windows Host (`netstat -an | findstr 5222`):** ANTES (vazio); regra SSH no VirtualBox; DEPOIS (`LISTENING`); DURANTE a sessão (`ESTABLISHED`).
3. **Sessão SSH:** terminal logado via `ssh -p 5222 administrador@127.0.0.1`; comando `w` mostrando `pts/0`.

### Modelo de Relatório (7 Passos) para `atividade-aula4.md`
1. **Identificação:** nome completo, matrícula, turma (Técnico em Desenvolvimento de Sistemas 2026.02), data e título da prática.
2. **Objetivo:** diagnóstico de rotas, controle de portas com `netstat` e acesso remoto SSH em ambiente NAT.
3. **Ambiente:** configurações do host Windows e da VM Ubuntu Server 26.04 LTS no VirtualBox (modo de rede, IPs, porta redirecionada).
4. **Procedimento:** instalação de `net-tools`/`traceroute`, verificação do `openssh-server`, uso de `route -n`, `w`, `ipconfig`, `netstat -an` e configuração do NAT, em ordem.
5. **Testes e Evidências:** capturas e saídas dos comandos no Linux e no Windows.
6. **Problemas e Soluções:** ao menos um problema (ex.: conexão recusada, porta em uso, erro de parâmetro) e a correção.
7. **Conclusão:** utilidade dos comandos de auditoria e importância de entender o fluxo de portas em redes virtualizadas.

---

## 7. Critérios de Avaliação
- [ ] Instalou/verificou o `openssh-server` e os utilitários de diagnóstico.
- [ ] Identificou IP, máscara, MAC e gateway da VM.
- [ ] Configurou corretamente o redirecionamento `5222 -> 22`.
- [ ] Demonstrou os estados antes (vazio), `LISTENING` e `ESTABLISHED` com `netstat`.
- [ ] Acessou a VM por SSH e identificou `pts/0` com `w`.
- [ ] Entregou `atividade-aula4.md` no formato de 7 passos, com imagens em `imagens/`.
