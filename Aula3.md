# Aula 03: Interfaces e Endereçamento de Rede

## 1. Objetivos da Aula
Ao final desta prática, você será capaz de:
* Explicar o que são endereço IP, máscara de sub-rede (`/24`), endereço MAC, gateway e DNS.
* Inspecionar interfaces e rotas com `ip addr show`, `ip link` e `ip route`.
* Diferenciar os modos **NAT** (`10.0.2.15`) e **Placa em Ponte (Bridge)** no VirtualBox.
* Testar a conectividade em camadas com `ping` e acompanhar o caminho dos pacotes com `traceroute`.
* Documentar a prática usando o Modelo de 7 Passos.

---

## 2. Contexto Teórico de Suporte

* **Endereço IPv4:** identifica a interface na rede (ex.: `10.0.2.15`).
* **Máscara / prefixo:** define a sub-rede. `255.255.255.0` equivale a `/24`.
* **Endereço MAC:** identificador físico da placa (virtual, na VM). Ex.: `08:00:27:ca:9b:66`.
* **Gateway padrão:** roteador para onde segue o tráfego destinado a outras redes (no NAT do VirtualBox: `10.0.2.2`).
* **DNS:** traduz nomes (ex.: `google.com`) em endereços IP.
* **Nome da interface:** no Ubuntu Server a placa costuma se chamar `enp0s3`; `lo` é a interface de loopback (`127.0.0.1`).

| Modo VirtualBox | IP típico da VM | Host acessa a VM? | VM acessa a internet? |
|---|---|---|---|
| NAT | `10.0.2.15` | Não (sem redirecionamento de portas) | Sim |
| Placa em Ponte (Bridge) | IP da rede do laboratório | Sim | Sim |

---

## 3. Roteiro Prático Passo a Passo

> **Importante:** faça login com o usuário **`administrador`** (configurado na Aula 1). Use `sudo` quando necessário.

### Passo 1: Inspeção das Interfaces e Rotas
```bash
administrador@ubuntu_server:~$ ip addr show
administrador@ubuntu_server:~$ ip link
administrador@ubuntu_server:~$ ip route
administrador@ubuntu_server:~$ netplan status
```
Anote em uma tabela: nome da interface, IP/prefixo, MAC e gateway padrão (linha `default via ...` do `ip route`).

### Passo 2: Testes de Conectividade em Camadas
Teste do mais próximo ao mais distante. Se uma etapa falhar, o problema está naquela camada.
```bash
administrador@ubuntu_server:~$ ping -c 4 127.0.0.1
administrador@ubuntu_server:~$ ping -c 4 <IP-da-sua-VM>
administrador@ubuntu_server:~$ ping -c 4 10.0.2.2
administrador@ubuntu_server:~$ ping -c 4 8.8.8.8
administrador@ubuntu_server:~$ ping -c 4 google.com
```
* Falha em `8.8.8.8`: problema de gateway/rota.
* Funciona com `8.8.8.8`, mas falha com `google.com`: problema de DNS.

### Passo 3: Rastreamento de Rotas
```bash
administrador@ubuntu_server:~$ sudo apt update
administrador@ubuntu_server:~$ sudo apt install -y traceroute
administrador@ubuntu_server:~$ traceroute 8.8.8.8
```
O salto 1 deve ser o gateway do VirtualBox (`10.0.2.2`).

### Passo 4: Alternando para o Modo Placa em Ponte (Bridge)
1. Desligue a VM (`sudo poweroff`).
2. No VirtualBox: **Configurações > Rede > Adaptador 1 > Conectado a: Placa em Ponte** e selecione a interface física do host.
3. Inicie a VM e repita o Passo 1:
```bash
administrador@ubuntu_server:~$ ip addr show
administrador@ubuntu_server:~$ ip route
administrador@ubuntu_server:~$ ping -c 4 8.8.8.8
```
4. Compare IP, gateway e rotas com os valores do modo NAT.

> Se o IP não for atribuído por DHCP, informe ao professor: a faixa de IPs livres do laboratório será fornecida em aula.

### Passo 5: Comparação com o Host Windows
No **PowerShell** do host:
```powershell
PS C:\Users\Aluno> ipconfig /all
```
Compare IP, máscara, gateway e MAC do host com os da VM.

---

## 4. Relatório (Modelo de 7 Passos)

Crie um `README.md` em seu repositório pessoal no GitHub com:
1. **Identificação:** nome completo, matrícula, turma, data e título da prática.
2. **Objetivo:** o que foi realizado.
3. **Ambiente:** especificações da VM, modo de rede e endereços IP.
4. **Procedimento:** comandos executados, em ordem.
5. **Testes:** capturas de tela de `ip addr`, `ip route` e dos testes de `ping`; tabela comparativa NAT x Bridge (IP, gateway, host acessa a VM).
6. **Problemas e Soluções:** ao menos um problema encontrado e como foi resolvido.
7. **Conclusão:** o que foi validado e aprendido.

---

## 5. Critérios de Avaliação
- [ ] Identificou corretamente IP, máscara, gateway e MAC.
- [ ] Explicou por que o host não alcança `10.0.2.15` no modo NAT.
- [ ] Executou os testes de `ping` em camadas e diagnosticou a camada de uma falha.
- [ ] Comparou NAT e Bridge com evidências.
- [ ] Documentou no formato de 7 passos.
