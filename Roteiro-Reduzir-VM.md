# Roteiro: Reduzir o tamanho da VM Ubuntu Server no VirtualBox

Este roteiro mostra como deixar a sua VM `ubuntu-server` (Ubuntu Server 26.04 LTS, criada na [Aula 01](Aula1.md)) mais enxuta. Uma VM menor:

* ocupa menos espaço no disco do PC do laboratório;
* gera um arquivo `.ova` pequeno, fácil de copiar para um pendrive ou guardar como backup;
* é copiada pela rede muito mais rápido.

> 💡 **Resultado real.** Aplicando este roteiro na VM da Avaliação 2, o disco usado caiu de **5,6 GB para 2,5 GB**, e o arquivo `.ova` caiu de **5 GB para 1,05 GB**.

> ⚠️ **Como usar este roteiro.** Os comandos estão separados, **um por bloco**, de propósito. Copie e execute **um de cada vez**, leia a saída e só então passe para o próximo. Vários deles apagam arquivos ou pacotes, e um erro no meio de um bloco colado de uma vez pode deixar a VM sem rede ou sem espaço em disco.

---

## 1. Conceitos antes de começar

Antes de usar os comandos, é preciso entender o que cada coisa é.

| Termo | O que é |
|---|---|
| **VDI** (*VirtualBox Disk Image*) | Formato de arquivo de disco virtual próprio do VirtualBox. É o arquivo `.vdi` que guarda o "HD" da VM no seu computador. |
| **VMDK** (*Virtual Machine Disk*) | Outro formato de disco virtual, criado pela VMware e também aceito pelo VirtualBox. É o formato usado dentro dos arquivos `.ova`. |
| **Disco dinâmico** | Disco virtual que começa pequeno e **cresce** à medida que a VM grava dados. Ele cresce, mas **não encolhe sozinho** quando você apaga arquivos dentro da VM. |
| **Espaço livre "sujo"** | Quando um arquivo é apagado, o sistema só marca o espaço como livre; os dados antigos continuam no disco. Para o VirtualBox, esses blocos ainda estão "em uso" e entram na exportação. |
| **`/dev/zero`** | Arquivo especial do Linux que, quando lido, devolve uma sequência infinita de bytes zero. |
| **`dd`** | Comando do Linux que copia dados, bloco a bloco, de uma origem (`if=`, *input file*) para um destino (`of=`, *output file*). Aqui ele vai copiar zeros de `/dev/zero` para um arquivo, até encher o espaço livre. |
| **OVF / OVA** | O **OVF** (*Open Virtualization Format*) é um padrão aberto para descrever e transportar VMs. O **OVA** é um único arquivo (um pacote `tar`) com a descrição OVF e os discos em VMDK **comprimido**. Blocos zerados quase não ocupam espaço nele. |
| **Swap** | Área do disco usada como extensão da memória RAM. Na instalação do laboratório, ela é o volume lógico `swap-lv`, de cerca de 2 GB, criado no particionamento LVM. |
| **Kernel** | O núcleo do sistema operacional. O Ubuntu mantém kernels antigos instalados depois de atualizações, por segurança. |
| **Firmware** | Pequenos programas carregados em dispositivos físicos (placas Wi-Fi, placas de vídeo, etc.). Uma VM usa dispositivos virtuais e não precisa deles. No Ubuntu, eles vêm nos pacotes `linux-firmware*`. |
| **Metapacote** | Pacote vazio que só existe para "puxar" outros como dependências. Exemplo: `linux-generic` puxa o kernel mais recente **e** o `linux-firmware`. |
| **`apt purge` / `apt autoremove`** | `purge` remove um pacote **e** seus arquivos de configuração. `autoremove` remove pacotes que foram instalados como dependência e não são mais necessários. |
| **Snapshot** | "Fotografia" do estado de uma VM em um instante, para a qual é possível voltar depois. |
| **`ip`** | Comando do pacote `iproute2`, a ferramenta atual do Linux para ver e configurar a rede (substitui o antigo `ifconfig`). Neste material usamos sempre **`ip -c -4 a`**: `-c` colore a saída (nome da interface, estado `UP`/`DOWN` e endereço destacados), `-4` mostra só IPv4 (não usamos IPv6 por enquanto) e `a` é a abreviação de `address`. |

---

## 2. Antes de começar

1. Faça todas as atividades e instalações de pacotes **antes** da limpeza. Se instalar algo depois, repita as seções 5 e 6.
1. **Faça um snapshot** da VM: *Máquina → Tirar Snapshot*, com o nome `antes-da-limpeza`. Se algo der errado, basta restaurá-lo.
1. Tenha à mão o caminho do disco da VM. No VirtualBox, abra *Configurações → Armazenamento*, clique no disco e veja o campo **Localização**. Exemplo: `C:\2026.2\SysDevTech\VM\<NomeDoAluno>\ubuntu-server\ubuntu-server.vdi`.

---

## 3. Diagnóstico: quanto e onde está ocupado

Estes comandos **só consultam** informações e não alteram nada na VM.

Uso total da partição raiz (`/`):

```bash
df -h /
```

As 15 maiores pastas, em ordem crescente de tamanho (`-x` não atravessa para outras partições):

```bash
sudo du -xh / --max-depth=2 2>/dev/null | sort -h | tail -15
```

Área de swap em uso (na instalação do laboratório, o volume lógico `swap-lv`):

```bash
swapon --show
```

Versão do kernel **que está rodando agora**:

```bash
uname -r
```

> 📝 **Anote essa versão.** O kernel em uso **nunca** pode ser removido.

Kernels, headers e firmwares instalados:

```bash
dpkg -l | grep -E '^ii +linux-(image|headers|modules|firmware|generic|virtual)'
```

Um Ubuntu Server recém-instalado costuma ocupar de 2 a 3 GB. Os maiores culpados costumam ser `/usr/lib/firmware`, `/usr/lib/modules` (kernels) e `/usr/src` (headers de kernel).

---

## 4. Limpeza

### 4.1 Cache de pacotes e logs

Apague os pacotes `.deb` baixados em `/var/cache/apt/archives`:

```bash
sudo apt clean
```

Reduza os logs do sistema (o *journal* do `systemd`) para no máximo 20 MB:

```bash
sudo journalctl --vacuum-size=20M
```

### 4.2 Kernels antigos

**Passo 1.** Confira o kernel em uso:

```bash
uname -r
```

**Passo 2.** Compare com a lista do `dpkg -l` da seção 3. Se houver um kernel **mais novo** que o mostrado pelo `uname -r`, a VM foi atualizada, mas ainda não está usando o kernel novo. **Reinicie antes de continuar:**

```bash
sudo reboot
```

Depois do boot, rode o `uname -r` de novo.

**Passo 3.** Remova os kernels antigos que o próprio sistema considera desnecessários:

```bash
sudo apt autoremove --purge
```

> ⚠️ O `apt` mostra a lista do que vai remover e pede confirmação. **Leia a lista**: ela **não pode** conter a versão mostrada pelo `uname -r`.

**Passo 4 (só se ainda sobrar um kernel antigo).** Remova-o pela versão. No exemplo, a versão antiga é `7.0.0-30`; **troque pela versão antiga da sua VM**:

```bash
sudo apt purge 'linux-*7.0.0-30*'
```

> ⚠️ Confira de novo a lista antes de confirmar.

**Passo 5 (só se sobrar uma pasta de módulos de kernel já removido).** Veja se algum pacote é dono da pasta. No exemplo, a pasta é a do kernel `7.0.0-14`:

```bash
dpkg -S /usr/lib/modules/7.0.0-14-generic
```

Se a resposta for `no path found matching pattern` (nenhum pacote é dono), apague a pasta:

```bash
sudo rm -rf /usr/lib/modules/7.0.0-14-generic
```

> ⚠️ **Nunca** apague a pasta do kernel mostrado pelo `uname -r`.

### 4.3 Firmware (opcional, maior ganho: de 500 MB a 1 GB)

Os pacotes `linux-firmware*` só servem para hardware físico. No Ubuntu 26.04 eles vêm divididos em vários pacotes (`linux-firmware-intel-wireless`, `linux-firmware-nvidia-graphics`, etc.), e o `'linux-firmware*'` abaixo pega todos. Para removê-los sem perder o kernel em uso, primeiro marque o kernel como "instalado manualmente" e só depois remova o metapacote `linux-generic`.

**Passo 1.** Marque o kernel em uso como manual. O `$(uname -r)` é substituído automaticamente pela versão do kernel em uso:

```bash
sudo apt-mark manual linux-image-$(uname -r) linux-modules-$(uname -r)
```

O `apt-mark manual` impede que o `apt` remova o kernel em uso, que antes era apenas uma dependência do `linux-generic`.

**Passo 2.** Remova o metapacote e os firmwares:

```bash
sudo apt purge linux-generic linux-image-generic linux-headers-generic 'linux-firmware*'
```

> ⚠️ **Leia a lista antes de confirmar.** Ela **não pode** conter `linux-image-` nem `linux-modules-` com a versão mostrada pelo `uname -r`.

**Passo 3.** Remova as dependências que sobraram:

```bash
sudo apt autoremove --purge
```

**Passo 4.** Reinicie a VM:

```bash
sudo reboot
```

**Passo 5.** Depois do boot, confira se o kernel continua o mesmo e se a rede funciona:

```bash
uname -r
```

```bash
ip -c -4 a
```

Se a VM não subir ou ficar sem rede, restaure o snapshot `antes-da-limpeza` e pule esta seção.

> ℹ️ Sem o metapacote `linux-generic`, o `apt upgrade` deixa de instalar kernels novos. Para VMs de prática, isso não é problema. Para voltar ao comportamento normal, use `sudo apt install linux-generic`.

### 4.4 E o swap?

Não mexa no swap. Na instalação do laboratório, ele é o volume lógico `swap-lv`, de cerca de 2 GB, e o disco virtual dinâmico só ocupa espaço no Windows pela parte do swap que já foi usada de fato. Com só 768 MB de RAM na VM, o swap é importante para o sistema não ficar sem memória.

### 4.5 Confira o resultado

```bash
df -h /
```

---

## 5. Zerar o espaço livre e desligar

Este é o passo que mais reduz o tamanho final.

> ⚠️ **Espaço no Windows.** Enquanto o `dd` enche a raiz de zeros, o arquivo `.vdi` cresce até quase o tamanho da raiz (cerca de **29 GB** na instalação do laboratório). Antes de começar, confira se o disco `C:` do PC tem **pelo menos 32 GB livres**. O espaço volta depois da compactação (seção 6).

**Passo 1.** Limpe o cache de pacotes mais uma vez:

```bash
sudo apt clean
```

**Passo 2.** Encha o espaço livre com zeros. `bs=1M` copia em blocos de 1 MB e `status=progress` mostra o andamento:

```bash
sudo dd if=/dev/zero of=/zero bs=1M status=progress
```

> ℹ️ O `dd` pode levar alguns minutos e **termina com a mensagem `No space left on device`**. Isso é esperado: ele para quando o disco enche de zeros.

**Passo 3.** Apague o arquivo de zeros. **Não pule este passo**, senão a VM fica com o disco cheio:

```bash
sudo rm /zero
```

**Passo 4.** Na instalação do laboratório, o `/boot` é uma partição separada, de 1 GB, fora do LVM. Confira se ele aparece numa linha própria:

```bash
df -h /boot
```

Se o `/boot` aparecer numa linha própria (por exemplo `/dev/sda2`), zere-o também:

```bash
sudo dd if=/dev/zero of=/boot/zero bs=1M status=progress
```

E apague o arquivo:

```bash
sudo rm /boot/zero
```

**Passo 5.** Apague o histórico de comandos do root e dos usuários:

```bash
sudo rm -f /root/.bash_history /home/*/.bash_history
```

**Passo 6.** Limpe o histórico da sessão aberta:

```bash
history -c
```

**Passo 7.** Impeça que a sessão grave o histórico de novo ao desligar:

```bash
unset HISTFILE
```

**Passo 8.** Desligue a VM:

```bash
sudo poweroff
```

> Os passos 6, 7 e 8 precisam ser feitos **no mesmo terminal**, nessa ordem.

---

## 6. Compactar o disco no computador hospedeiro

Com a VM **desligada**, abra o PowerShell no Windows.

**Passo 1.** Entre na pasta do VirtualBox:

```powershell
cd 'C:\Program Files\Oracle\VirtualBox'
```

O instalador do VirtualBox **não coloca** a pasta dele no `PATH` do Windows. O `PATH` é a variável de ambiente com a lista de pastas onde o sistema procura os programas digitados no terminal. Por isso, digitar só `VBoxManage` em qualquer pasta dá o erro *"O termo 'VBoxManage' não é reconhecido..."*, e é preciso entrar na pasta do VirtualBox antes.

**Passo 2.** Compacte o disco. Troque o caminho pelo **Localização** do disco da sua VM (seção 2). O `.\` no início diz ao PowerShell para executar o programa **da pasta atual**, já que ele não procura programas na pasta atual sem esse prefixo:

```powershell
.\VBoxManage.exe modifymedium disk "C:\2026.2\SysDevTech\VM\<NomeDoAluno>\ubuntu-server\ubuntu-server.vdi" --compact
```

* O `VBoxManage` é a ferramenta de linha de comando do VirtualBox. O subcomando `modifymedium disk ... --compact` devolve ao Windows o espaço dos blocos zerados.
* **Use aspas** no caminho do disco. Sem aspas, um espaço no caminho causa o erro `Invalid parameter`.
* O `--compact` só funciona com discos **`.vdi`**. Se o disco for `.vmdk`, pule este passo: a exportação para OVA já descarta os zeros.

Depois de compactar, tire um novo snapshot da VM: `vm-limpa`.

---

## 7. Exportar a VM (backup ou levar para outro PC)

Com a VM reduzida, o `.ova` fica pequeno o bastante para caber num pendrive ou ser enviado para a nuvem como backup.

1. Com a VM desligada, vá em *Arquivo → Exportar Appliance* e selecione a VM `ubuntu-server`.
2. Formato **OVF 2.0** e nome `ubuntu-server.ova`.
3. Em **Política de endereço MAC**, escolha **Remover todos os endereços MAC das placas de rede**, para a VM receber endereços novos quando for importada em outro PC.

Gere o *hash* do arquivo no PowerShell, para conferir se a cópia chegou íntegra:

```powershell
Get-FileHash .\ubuntu-server.ova -Algorithm SHA256
```

O **hash SHA-256** é uma "impressão digital" do arquivo. Se um único bit mudar, o hash muda, então dá para comparar a cópia com o original.

Para usar a VM em outro PC: *Arquivo → Importar Appliance*, selecione o `.ova` e, em **Pasta base da máquina**, use `C:\2026.2\SysDevTech\VM\<NomeDoAluno>`.

---

## 8. Checklist

- [ ] Snapshot `antes-da-limpeza`
- [ ] `apt clean` e `journalctl --vacuum-size`
- [ ] Kernel em uso conferido com `uname -r`; kernels antigos removidos
- [ ] (Opcional) Firmware removido, reboot e rede conferidos
- [ ] `dd` de zeros na raiz (e no `/boot`, se separado) + `rm` do arquivo
- [ ] Histórico apagado e VM desligada
- [ ] `VBoxManage ... --compact` no `.vdi`
- [ ] Snapshot `vm-limpa`
- [ ] (Se precisar) VM exportada para `.ova` com MACs removidos e hash conferido

---

## Referências

* ORACLE. **Oracle VirtualBox User Guide** (capítulos sobre armazenamento virtual, clonagem, importação/exportação de appliances e `VBoxManage modifymedium`). Disponível em: <https://www.virtualbox.org/manual/>.
* DMTF. **Open Virtualization Format (OVF)**. Disponível em: <https://www.dmtf.org/standards/ovf>.
* CANONICAL. **Ubuntu Server documentation**. Disponível em: <https://documentation.ubuntu.com/server/>.
* Páginas de manual do Linux: `dd(1)`, `swapon(8)`, `apt(8)`, `apt-mark(8)` — acessíveis na própria VM com `man <comando>`.
