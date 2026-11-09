# Projeto — Laboratório de Sistemas Operacionais e Redes (Técnico em DS 2026.02)

## Rede virtualizada com 8 VMs: endereçamento estático, nomes, usuários e pasta compartilhada

### 1. Apresentação

Neste projeto, cada grupo monta uma pequena rede de computadores com **8 máquinas virtuais (VMs)** Ubuntu Server, distribuídas em **4 PCs** do laboratório (2 VMs por PC). As VMs ficam ligadas ao switch do laboratório pelo modo **Placa em Ponte (Bridge)** do VirtualBox e formam, juntas, a rede do grupo: uma sub-rede **/28** com endereços estáticos, nomes padronizados, os mesmos usuários em todas as máquinas e uma **pasta compartilhada do grupo** protegida por permissões.

O projeto junta o que foi praticado nas aulas: instalação do Ubuntu Server, usuários e grupos, permissões de pastas, acesso remoto por SSH, IP estático e resolução de nomes. A rede do grupo **não tem gateway**: as VMs se comunicam apenas entre si, dentro da sub-rede.

**Grupos de 4 alunos.** Cada integrante fica responsável por **um PC e suas 2 VMs**: instala, configura, testa e documenta. Grupos com 3 integrantes dividem entre si as VMs do 4º PC.

### 2. Objetivos

Ao final do projeto, o grupo deve ser capaz de:

1. Calcular uma sub-rede /28 (endereço de rede, broadcast e endereços úteis) e distribuir os endereços entre as VMs.
2. Instalar e configurar 8 VMs Ubuntu Server no VirtualBox, em modo Placa em Ponte.
3. Configurar IP estático com Netplan.
4. Padronizar hostnames, domínio (FQDN) e o arquivo `/etc/hosts` em todas as VMs.
5. Criar os usuários dos integrantes e a pasta compartilhada do grupo em todas as VMs.
6. Testar e documentar a conectividade entre as VMs com `ping` e `ssh`, usando endereços IP e nomes.

### 3. Aulas usadas no projeto

| Aula | Conteúdo | Onde é usada no projeto |
|:--|:--|:--|
| [Aula 01](../Aula1.md) | Criação da VM no VirtualBox, particionamento LVM e instalação com OpenSSH | Criação das 8 VMs (seção 8) |
| [Aula 02](../Aula2.md) | Usuários, grupos e permissões (`adduser`, `groupadd`, `usermod`) | Usuários dos integrantes (seção 9) |
| [Aula 03](../Aula3.md) | Interfaces, endereçamento e modos NAT e Bridge | Rede das VMs (seção 10) |
| [Aula 04](../Aula4.md) | Acesso remoto SSH, `w` e diagnóstico de rede | Testes (seção 13) |
| [Aula 05](../Aula5.md) | Pastas departamentais em `/srv`, `chown` e permissão `770` | Pasta compartilhada (seção 12) |
| Aula 06 *(em breve)* | Placa em Ponte e IP estático com Netplan | Rede das VMs (seção 10) |
| Aula 07 *(em breve)* | Hostname, FQDN e `/etc/hosts` | Nomes das VMs (seção 11) |

Os [vídeos de apoio](../README.md#-vídeos-de-apoio) sobre operações com VMs no VirtualBox também ajudam na criação e no clone das VMs.

### 4. Topologia

**Figura 1:** Topologia física. São 4 PCs do laboratório, cada um com 2 VMs ligadas ao switch pelo modo Placa em Ponte. Os nomes e endereços são do Grupo 0 (modelo).

![Topologia física do projeto](topologia-fisica-projeto.png)

**Figura 2:** Topologia lógica do Grupo 0. As 8 VMs estão no mesmo segmento /28 e se encontram pelo nome graças ao `/etc/hosts`.

![Topologia lógica do projeto](topologia-logica-projeto.png)

> **Por que Placa em Ponte?** No modo Bridge, a placa virtual da VM é ligada diretamente à placa de rede física do PC, e a VM aparece no switch do laboratório como se fosse mais um computador. É isso que permite que VMs em PCs diferentes conversem entre si. A rede do grupo (`192.168.13.x/28`) é um segmento lógico que trafega pelo mesmo switch físico do laboratório.

### 5. Ordem de implementação

Siga as etapas nesta ordem. As etapas 2 a 5 são feitas com a placa da VM ainda em **NAT**, que é o modo padrão do VirtualBox e dá acesso à internet para instalar pacotes. A rede do grupo não tem saída para a internet.

| Etapa | O que fazer | Seção |
|:--:|:--|:--|
| 1 | Planejar endereços, nomes e usuários do grupo | 6, 7 e 9 |
| 2 | Instalar as 2 VMs de cada PC, com OpenSSH Server | 8 |
| 3 | Atualizar a VM, instalar utilitários (`net-tools`, `traceroute`) e baixar o script de validação | 8 |
| 4 | Criar os usuários dos integrantes | 9 |
| 5 | Criar o grupo e a pasta compartilhada | 12 |
| 6 | Mudar a placa da VM para Placa em Ponte e configurar o IP estático | 10 |
| 7 | Configurar o hostname e o `/etc/hosts` | 11 |
| 8 | Testar `ping` e `ssh` e rodar o script de validação | 13 |
| 9 | Documentar tudo no repositório do grupo | 14 |

### 6. Endereçamento IP dos grupos

- A turma usa a rede **192.168.13.0/24**, dividida em sub-redes **/28** (máscara 255.255.255.240), uma por grupo.
- O Grupo **X** usa a sub-rede `192.168.13.(16 × X)/28`. O Grupo 0 é o modelo usado nos exemplos deste documento e ocupa o 1º range; o Grupo 1 usa o 2º, o Grupo 2 o 3º, e assim por diante.
- Uma sub-rede /28 tem 16 endereços: o primeiro identifica a rede, o último é o broadcast e os 14 do meio podem ser atribuídos a máquinas [3].
- As 8 VMs do grupo usam os **8 primeiros endereços úteis**. Os demais ficam livres.

| Grupo | Rede /28 | VM1 … VM8 | Livres | Broadcast |
|:--:|:--|:--|:--|:--|
| 0 (modelo) | 192.168.13.0 | .1 – .8 | .9 – .14 | .15 |
| 1 | 192.168.13.16 | .17 – .24 | .25 – .30 | .31 |
| 2 | 192.168.13.32 | .33 – .40 | .41 – .46 | .47 |
| 3 | 192.168.13.48 | .49 – .56 | .57 – .62 | .63 |
| 4 | 192.168.13.64 | .65 – .72 | .73 – .78 | .79 |
| 5 | 192.168.13.80 | .81 – .88 | .89 – .94 | .95 |
| 6 | 192.168.13.96 | .97 – .104 | .105 – .110 | .111 |
| 7 | 192.168.13.112 | .113 – .120 | .121 – .126 | .127 |
| 8 | 192.168.13.128 | .129 – .136 | .137 – .142 | .143 |

### 7. Nomes de máquina e domínio (FQDN)

- O domínio de cada grupo segue o formato `grupoX.sysdev.maceio.lab`.
- O hostname curto de cada VM indica o grupo, o PC e a VM dentro do PC, sempre em **minúsculas**: `gX-pcY-vmZ`, com PC de 1 a 4 e VM 1 ou 2.
- O FQDN é o hostname curto seguido do domínio: `gX-pcY-vmZ.grupoX.sysdev.maceio.lab`.
- No VirtualBox, dê à VM o mesmo nome do hostname curto (ex.: `g0-pc1-vm1`), para facilitar a identificação no laboratório.

**Tabela de referência — Grupo 0 (modelo):**

| VM | PC | Hostname | Interface / modo | IP / máscara | FQDN |
|:--:|:--:|:--|:--|:--|:--|
| VM1 | PC1 | g0-pc1-vm1 | enp0s3 · Bridge | 192.168.13.1/28 | g0-pc1-vm1.grupo0.sysdev.maceio.lab |
| VM2 | PC1 | g0-pc1-vm2 | enp0s3 · Bridge | 192.168.13.2/28 | g0-pc1-vm2.grupo0.sysdev.maceio.lab |
| VM3 | PC2 | g0-pc2-vm1 | enp0s3 · Bridge | 192.168.13.3/28 | g0-pc2-vm1.grupo0.sysdev.maceio.lab |
| VM4 | PC2 | g0-pc2-vm2 | enp0s3 · Bridge | 192.168.13.4/28 | g0-pc2-vm2.grupo0.sysdev.maceio.lab |
| VM5 | PC3 | g0-pc3-vm1 | enp0s3 · Bridge | 192.168.13.5/28 | g0-pc3-vm1.grupo0.sysdev.maceio.lab |
| VM6 | PC3 | g0-pc3-vm2 | enp0s3 · Bridge | 192.168.13.6/28 | g0-pc3-vm2.grupo0.sysdev.maceio.lab |
| VM7 | PC4 | g0-pc4-vm1 | enp0s3 · Bridge | 192.168.13.7/28 | g0-pc4-vm1.grupo0.sysdev.maceio.lab |
| VM8 | PC4 | g0-pc4-vm2 | enp0s3 · Bridge | 192.168.13.8/28 | g0-pc4-vm2.grupo0.sysdev.maceio.lab |

### 8. Criação das VMs

Siga a [Aula 01](../Aula1.md) e os [vídeos de apoio](../README.md#-vídeos-de-apoio), com estes ajustes:

- **Hardware de cada VM:** 1 CPU, disco de 32 GB (VDI, alocação dinâmica) e **768 MB de RAM**, configurados como na Aula 01 (instalar com 1,5 GB e reduzir para 768 MB depois). Com 768 MB, as 2 VMs de cada PC rodam juntas.
- **Pastas no PC (Windows):** ISO em `C:\2026.2\SysDevTech\VM\original` e VMs em `C:\2026.2\SysDevTech\VM\<NomeDoAluno>`.
- **Nome da VM no VirtualBox** e **Your server's name** no instalador: o hostname curto da VM (ex.: `g0-pc1-vm1`).
- **Usuário administrador:** o mesmo usuário e senha padrão da Aula 01.
- Marque **Install OpenSSH Server** durante a instalação.
- Mantenha a placa de rede em **NAT** durante a instalação e use esse acesso à internet para atualizar a VM e instalar os utilitários de rede:

```bash
sudo apt update
sudo apt install -y net-tools traceroute
```

Ainda em NAT, baixe também o script de validação usado no final (seção 13):

```bash
wget https://raw.githubusercontent.com/alaelson/labredes-2026.2-sysdev/main/projeto/validacao-projeto.sh
```

> **Clonou uma VM?** Se você criar a segunda VM do seu PC clonando a primeira, escolha a opção de **gerar novos endereços MAC** para todas as placas. Duas VMs com o mesmo MAC no mesmo switch não conseguem se comunicar corretamente. Depois de clonar, altere também o hostname (seção 11).

### 9. Usuários

- Cada VM tem o usuário **`administrador`**, **um usuário para cada integrante** do grupo e o usuário **`novato`**, que representa alguém de fora do grupo e é usado no teste de bloqueio da pasta compartilhada.
- O nome de usuário dos integrantes segue o formato `nome.sobrenome`, em minúsculas, sem acentos e sem espaços (ex.: `fulano.tal`).
- O conjunto de usuários é **o mesmo nas 8 VMs**.

Crie cada usuário com o `adduser`, como na [Aula 02](../Aula2.md). Exemplo para o Grupo 0, executado em cada VM:

```bash
sudo adduser fulano.tal
sudo adduser fulustreca.grudes
sudo adduser beltrano.silva
sudo adduser cicrano.souza
sudo adduser novato

# Verificação
getent passwd fulano.tal fulustreca.grudes beltrano.silva cicrano.souza novato
ls -l /home
```

> **Atalho opcional:** os mesmos usuários podem ser criados de uma vez com um laço `for` em Bash. O `useradd -m -s /bin/bash` cria o usuário com pasta pessoal e shell `bash`, e o `passwd` define a senha de cada um:
> ```bash
> for u in fulano.tal fulustreca.grudes beltrano.silva cicrano.souza novato; do
>   sudo useradd -m -s /bin/bash "$u"
>   sudo passwd "$u"
> done
> ```

### 10. Placa em Ponte e IP estático (Netplan)

**No VirtualBox:** com a VM desligada, em **Configurações → Rede → Adaptador 1**, altere **Conectado a** para **Placa em Ponte** e selecione a placa de rede física do PC (como no Passo 4 da [Aula 03](../Aula3.md)).

**Na VM**, veja qual arquivo existe em `/etc/netplan/` e edite-o com `sudo nano` [1, 2]:

```bash
ls /etc/netplan/
sudo nano /etc/netplan/50-cloud-init.yaml   # use o nome do arquivo listado
```

Modelo para a VM1 do Grupo 0 (`g0-pc1-vm1`). Troque apenas o endereço em `addresses` em cada VM:

```yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    enp0s3:
      dhcp4: false
      addresses:
        - 192.168.13.1/28
```

- A rede do grupo **não tem gateway**: por isso o arquivo não tem `routes` nem `nameservers`. Sem rota padrão, a VM fala apenas com as máquinas da própria sub-rede.
- Use espaços (nunca `Tab`) e mantenha a indentação de 2 espaços por nível.

Aplique e confira:

```bash
sudo netplan apply
ip -4 addr show enp0s3      # deve mostrar 192.168.13.1/28
ip route                    # deve mostrar 192.168.13.0/28 dev enp0s3
```

### 11. Hostname e /etc/hosts

**Hostname.** Configure em cada VM o FQDN completo:

```bash
sudo hostnamectl set-hostname g0-pc1-vm1.grupo0.sysdev.maceio.lab
hostname
cat /etc/hostname
```

**/etc/hosts.** Como a rede do grupo não tem servidor DNS, a resolução de nomes é feita localmente. O `/etc/hosts` de **todas as 8 VMs** deve conter uma linha para cada máquina do grupo, no formato `IP  FQDN  apelido` [4]. Exemplo do Grupo 0:

```
# Grupo 0 - sysdev - grupo0.sysdev.maceio.lab
192.168.13.1    g0-pc1-vm1.grupo0.sysdev.maceio.lab    g0-pc1-vm1
192.168.13.2    g0-pc1-vm2.grupo0.sysdev.maceio.lab    g0-pc1-vm2
192.168.13.3    g0-pc2-vm1.grupo0.sysdev.maceio.lab    g0-pc2-vm1
192.168.13.4    g0-pc2-vm2.grupo0.sysdev.maceio.lab    g0-pc2-vm2
192.168.13.5    g0-pc3-vm1.grupo0.sysdev.maceio.lab    g0-pc3-vm1
192.168.13.6    g0-pc3-vm2.grupo0.sysdev.maceio.lab    g0-pc3-vm2
192.168.13.7    g0-pc4-vm1.grupo0.sysdev.maceio.lab    g0-pc4-vm1
192.168.13.8    g0-pc4-vm2.grupo0.sysdev.maceio.lab    g0-pc4-vm2
```

A linha `127.0.1.1`, criada na instalação, deve apontar para o nome da própria VM:

```
127.0.1.1    g0-pc1-vm1.grupo0.sysdev.maceio.lab    g0-pc1-vm1
```

### 12. Pasta compartilhada do grupo

Como na [Aula 05](../Aula5.md), cada VM tem uma pasta do grupo em `/srv`, acessível apenas pelo administrador e pelos integrantes:

- **Grupo Linux:** `grupoX` (ex.: `grupo0`), com todos os integrantes como membros. O `novato` **não** faz parte do grupo.
- **Pasta:** `/srv/grupoX-dept`, com dono `administrador`, grupo `grupoX` e permissão **`770`**.
- **Arquivo de identificação:** `/srv/grupoX-dept/leia-me.txt`, com permissão **`660`**, contendo o hostname da VM e o nome do integrante responsável por ela.

Exemplo do Grupo 0, em cada VM:

```bash
sudo groupadd grupo0
for u in fulano.tal fulustreca.grudes beltrano.silva cicrano.souza; do
  sudo usermod -aG grupo0 "$u"
done
sudo mkdir -p /srv/grupo0-dept
sudo chown administrador:grupo0 /srv/grupo0-dept
sudo chmod 770 /srv/grupo0-dept

echo "VM $(hostname -s) - responsável: Fulano de Tal" | sudo tee /srv/grupo0-dept/leia-me.txt
sudo chown administrador:grupo0 /srv/grupo0-dept/leia-me.txt
sudo chmod 660 /srv/grupo0-dept/leia-me.txt

# Verificação
id fulano.tal
ls -ld /srv/grupo0-dept
ls -l /srv/grupo0-dept
```

Teste o isolamento com `su -`: um integrante consegue ler o `leia-me.txt`, e o `novato` recebe `Permission denied` ao tentar entrar na pasta.

### 13. Testes e validação

Registre no repositório do grupo os comandos e as saídas de:

1. `ping` de cada VM para as outras 7, usando o **IP**, o **apelido** e o **FQDN**:
   ```bash
   ping -c 3 192.168.13.3
   ping -c 3 g0-pc2-vm1
   ping -c 3 g0-pc2-vm1.grupo0.sysdev.maceio.lab
   ```
2. Acesso `ssh` entre VMs de **PCs diferentes**, com o usuário de cada integrante (ver [Aula 04](../Aula4.md)). Dentro da sessão remota, leia o `leia-me.txt` da outra VM:
   ```bash
   ssh fulano.tal@g0-pc3-vm2
   hostname                              # já dentro da sessão remota
   w                                     # mostra a sessão aberta e o IP de origem
   cat /srv/grupo0-dept/leia-me.txt      # acesso permitido ao integrante
   exit
   ```
3. Resolução de nomes: `getent hosts g0-pc4-vm2`.
4. Isolamento da pasta: `su - novato` seguido de `cd /srv/grupo0-dept` deve retornar `Permission denied`.
5. **Script de validação:** em cada VM, use o [validacao-projeto.sh](validacao-projeto.sh) baixado na seção 8. Se esqueceu de baixá-lo, copie-o de outra VM do grupo com `scp administrador@g0-pc1-vm1:validacao-projeto.sh .`. Edite a seção *CONFIGURAÇÃO DO GRUPO* (número do grupo e usuários dos integrantes) e execute:
   ```bash
   sudo bash validacao-projeto.sh | tee validacao-$(hostname -s).txt
   ```
   O script confere o IP e a máscara, o Netplan, o hostname, o `/etc/hosts`, a resolução de nomes, os usuários, a pasta compartilhada (grupo, dono, permissão `770` e bloqueio do `novato`), o serviço SSH e a conectividade (`ping` e porta 22) com as outras 7 VMs. O resultado esperado é **nenhum item com FALHOU**. Os 8 arquivos `validacao-<hostname>.txt` vão para a pasta `validacao/` do repositório do grupo.

### 14. Repositório do grupo

Cada grupo cria **um repositório público** no GitHub chamado:

```text
lsor-2026.2-sysdev-projeto-grupoX
```

com `X` igual ao número do grupo (ex.: `lsor-2026.2-sysdev-projeto-grupo3`).

- Um integrante cria o repositório e adiciona os demais como colaboradores (**Settings → Collaborators**). Adicione também o professor (`alaelson`).
- Cada integrante envia (commit) a documentação e as evidências do **seu PC e das suas 2 VMs**, para que o histórico mostre a participação de todos.
- Organize o repositório desta forma:

```text
lsor-2026.2-sysdev-projeto-grupoX/
├── README.md                 # Identificação do grupo, integrantes (com o PC de cada um) e links para os arquivos abaixo
├── 01-planejamento.md        # Endereçamento, nomes, usuários e topologia do grupo (Etapa 1)
├── 02-criacao-das-vms.md     # Hardware de cada VM e instalação do Ubuntu Server
├── 03-usuarios-e-pasta.md    # Usuários, grupo grupoX e pasta compartilhada
├── 04-rede-netplan.md        # Placa em Ponte e IP estático de cada VM
├── 05-hostname-e-hosts.md    # Hostname e /etc/hosts
├── 06-testes.md              # Testes de ping, ssh, nomes e isolamento da pasta
├── configs/
│   ├── hosts                 # Bloco do /etc/hosts usado nas 8 VMs
│   └── netplan/
│       ├── gX-pc1-vm1.yaml   # Arquivo Netplan de cada VM
│       └── ... (uma por VM)
├── validacao/
│   ├── validacao-gX-pc1-vm1.txt
│   └── ... (saída do script em cada VM)
└── imagens/                  # Capturas de tela de evidência
    ├── topologia-grupoX.png
    ├── pc1_virtualbox_bridge.png
    ├── g0-pc1-vm1_ip_addr.png
    └── ... (demais capturas)
```

**Como documentar (a mesma regra das atividades das aulas):**

- Cada passo é contado em quatro partes, nesta ordem: **texto explicando o que está sendo feito e por quê**, **bloco de código** com os comandos, **print da execução** (com o prompt e o hostname da VM aparecendo) e **uma ou duas frases interpretando o resultado**.
- Os arquivos `.md` ficam na raiz, numerados na ordem da implementação.
- As capturas de tela ficam na pasta `imagens/`, com nomes em minúsculas, sem espaços nem acentos, indicando a VM ou o PC (ex.: `g0-pc2-vm1_ping.png`).
- Referencie as imagens com caminho relativo: `![Ping da VM3 para a VM8](imagens/g0-pc2-vm1_ping.png)`.
- O `01-planejamento.md` traz a tabela da seção 7 preenchida com os dados do grupo, o bloco do `/etc/hosts`, a lista de usuários, o integrante responsável por cada PC e a topologia do grupo (adaptada das Figuras 1 e 2).

---

## Prazos e entregas

### Etapa 1 — Planejamento (data a definir)

a) Criar o repositório do grupo com a estrutura da seção 14 e adicionar o professor como colaborador.

b) Publicar o `01-planejamento.md`, com as tabelas de endereçamento, nomes e usuários, a divisão dos PCs entre os integrantes e a topologia do grupo.

### Etapa 2 — Implementação e apresentação final (data a definir)

a) Rede do grupo funcionando no laboratório, com as 8 VMs configuradas.

b) Repositório completo: documentação de todas as etapas, arquivos de configuração, saídas do script de validação e evidências dos testes.

c) Apresentação do grupo, com demonstração de `ping` e `ssh` entre VMs de PCs diferentes e do bloqueio do `novato` na pasta compartilhada. Cada integrante apresenta as VMs pelas quais é responsável.

---

## Critérios de Avaliação

- [ ] **Planejamento:** sub-rede, endereços, nomes e usuários corretos e coerentes com a seção 6 e 7.
- [ ] **VMs e rede:** 8 VMs em Placa em Ponte, com IP estático e máscara /28 corretos.
- [ ] **Nomes:** hostname (FQDN) e `/etc/hosts` corretos em todas as VMs.
- [ ] **Usuários e pasta:** usuários dos integrantes e `novato` em todas as VMs; pasta `/srv/grupoX-dept` com grupo, dono e permissão `770`.
- [ ] **Testes:** `ping` por IP, apelido e FQDN; `ssh` entre PCs diferentes; bloqueio do `novato`; script de validação sem falhas.
- [ ] **Documentação:** repositório organizado, com texto, bloco de código, print e interpretação em cada passo.
- [ ] **Participação:** commits de todos os integrantes e apresentação individual das VMs de cada um.

---

## Referências

[1] CANONICAL. **Configuring networks**. Ubuntu Server documentation. Disponível em: <https://ubuntu.com/server/docs/configuring-networks>.

[2] NETPLAN. **Netplan reference** (YAML configuration). Disponível em: <https://netplan.readthedocs.io/en/latest/reference/>.

[3] KUROSE, James F.; ROSS, Keith W. **Redes de Computadores e a Internet**. 8. ed. Pearson, 2022.

[4] LINUX MAN-PAGES PROJECT. **hosts(5) — static table lookup for hostnames**. Disponível em: <https://man7.org/linux/man-pages/man5/hosts.5.html>.
