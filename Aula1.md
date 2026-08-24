# Aula 01 - Introdução à Virtualização e Instalação do Ubuntu Server 26.04

Este roteiro faz parte do repositório de aulas práticas **labredes-SysDev-2026.02** da disciplina de Laboratório de Sistemas Operacionais e Redes (LSOR) do Bacharelado em Sistemas de Informação.

---

## 1. Objetivos da Prática
* Compreender os conceitos básicos de virtualização e o papel do hipervisor (VirtualBox).
* Organizar o ambiente local de laboratório seguindo o padrão estabelecido.
* Criar e configurar uma Máquina Virtual (VM) com os recursos mínimos necessários.
* Realizar a instalação limpa do **Ubuntu Server 26.04 LTS** utilizando particionamento personalizado de disco (LVM).
* Configurar o usuário administrativo padrão para o semestre.

---

## 2. Preparação do Ambiente no Host (Computador Físico)
Antes de abrir o VirtualBox, você deve garantir que a estrutura de diretórios do laboratório está devidamente organizada para evitar perda de dados e problemas de permissão:

1. Acesse o disco local do host e navegue até a pasta de originais:
   * **Caminho:** `C:\2026.2\SysDevTech\VM\original`
2. Certifique-se de que o arquivo de imagem do sistema operacional está presente nesta pasta:
   * **Arquivo:** `ubuntu-26.04-live-server-amd64.iso`
   * **Servidor de Arquivos da Rede (Acesso a ISO):** `\\172.20.22.21\public`
     usuário: alunoifal
     senha: alunoifal
3. Crie a sua pasta de trabalho individual onde todos os arquivos da sua VM serão armazenados:
   * **Caminho:** `C:\2026.2\SysDevTech\VM\<NomeDoAluno>`
   * *Substitua `<NomeDoAluno>` pelo seu primeiro e último nome (ex: `C:\2026.2\SysDevTech\VM\JoaoSilva`).*
4. Dentro da sua pasta, crie um diretório específico para esta máquina:
   * **Caminho:** `C:\2026.2\SysDevTech\VM\<NomeDoAluno>\ubuntu_server`



---

## 3. Criação da Máquina Virtual no VirtualBox
Abra o VirtualBox e clique em **Novo** (New) para criar a VM. Utilize os seguintes parâmetros técnicos:

* **Nome:** `ubuntu_server`
* **Pasta da VM (Folder):** Selecione a pasta que você criou no passo anterior (`C:\2026.2\SysDevTech\VM\<NomeDoAluno>\ubuntu_server`).
* **Tipo:** `Linux`
* **Versão:** `Ubuntu (64-bit)`
* **Memória RAM:** **768 MB** (Configure inicialmente com 1.5 GB, depois reduzir para 768 MB)
* **Processador:** **1 CPU**
* **Disco Rígido:**
  * Escolha a opção **Criar um novo disco rígido virtual agora**.
  * **Tipo de arquivo:** `VDI (VirtualBox Disk Image)`.
  * **Armazenamento:** `Dinamicamente Alocado` (Dynamically allocated).
  * **Tamanho do disco:** **32 GB**.

---

## 4. Configurações Finais pré-Boot
Antes de iniciar a máquina pela primeira vez:

1. Selecione a VM `ubuntu_server` e clique em **Configurações** (Settings).
2. Vá em **Armazenamento** (Storage).
3. Selecione a controladora IDE (Disco Óptico Vazio).
4. No painel lateral direito, clique no ícone do CD e selecione **Escolher um arquivo de disco...** (Choose a virtual optical disk file).
5. Selecione a imagem ISO localizada na pasta de originais:
   * `C:\2026.2\SysDevTech\VM\original\ubuntu-26.04-live-server-amd64.iso`
6. Clique em **OK** para salvar as configurações.

---

## 5. Processo de Instalação do Ubuntu Server
Inicie a VM e siga as instruções abaixo detalhadamente:

### 5.1. Inicialização, Idioma e Teclado
1. No menu de boot do instalador, selecione a opção padrão para iniciar o instalador.
2. **Idioma (Language):** Selecione o seu idioma de preferência (recomendado: **English** para familiarização com termos técnicos de servidores).
3. **Teclado (Keyboard):** Configure o layout de acordo com o teclado físico do laboratório:
   * **Layout:** `Portuguese (Brazil)` ou `English (US)` dependendo da máquina física.
   * Selecione **Done** e pressione Enter.

### 5.2. Configurações de Rede, Proxy e Mirror
1. **Rede:** O instalador detectará a interface virtual (ex: `enp0s3`) e tentará obter um endereço IP automaticamente via DHCP. Aguarde a confirmação do endereço de rede e selecione **Done**.
2. **Proxy:** Deixe em branco (Apenas selecione **Done**).
3. **Mirror:** Mantenha o endereço padrão do espelho de repositórios do Ubuntu e selecione **Done**.

### 5.3. Particionamento Personalizado do Disco (FileSystem Setup)
Para fins de aprendizado e flexibilidade de administração, **NÃO** utilizaremos o particionamento automático padrão. Siga os passos para configurar o particionamento via LVM manualmente:

1. Na tela de *Filesystem setup*, selecione a opção **Custom storage layout** (ou manual) e selecione **Done**.
2. Na tela de resumo de dispositivos, selecione o disco livre de **32 GB** e escolha a opção para criar a estrutura LVM.
3. Crie exatamente **3 partições** com as seguintes especificações:
   * **Partição 1 (/boot):**
     * **Tamanho:** `1 GB` (1.000M)
     * **Formato:** `ext4`
     * **Ponto de Montagem (Mount):** `/boot`
   * **Partição 2 (Root /):**
     * **Tamanho:** `29 GB`
     * **Formato:** `ext4`
     * **Ponto de Montagem (Mount):** `/`
   * **Partição 3 (SWAP):**
     * **Tamanho:** `2 GB`
     * **Formato:** `swap`
     * *(A memória SWAP funciona como área de troca de memória RAM no disco).*
4. Revise o sumário das partições criadas. Certifique-se de que correspondem aos tamanhos exatos acima.
5. Selecione **Done**, confirme o aviso de destruição de dados no disco e prossiga.

### 5.4. Configuração do Perfil de Usuário (Profile Setup)
Preencha os dados do administrador do sistema seguindo estritamente as definições da turma:

* **Your name:** `Administrador`
* **Your server's name:** `ubuntu_server`
* **Pick a username:** `administrador`
* **Choose a passworC:** `adminifal`
* **Confirm your passworC:** `adminifal`

*Atenção: Não utilize o usuário padrão antigo 'redes'. Toda a administração a partir de agora será conduzida sob o usuário 'administrador'.*

### 5.5. Serviços Adicionais e Conclusão
1. Na tela de seleção do **SSH**, marque a opção **Install OpenSSH server** pressionando a barra de espaço. *Este serviço é fundamental para que possamos acessar o servidor remotamente nas próximas aulas.*
2. Na tela de seleção de snaps/serviços opcionais, não selecione nenhum pacote. Vá direto para **Done**.
3. Aguarde o término da instalação (cópia dos arquivos e downloads de atualizações de segurança).
4. Assim que o processo terminar, selecione **Reboot Now** e pressione Enter.
5. *Nota:* Quando solicitado na tela preta, pressione Enter para confirmar a ejeção do disco óptico virtual de instalação.

---

## 6. Tarefas de Pós-Instalação
Após o reinício completo da máquina virtual:

1. Realize o login no console tty1 com as credenciais criadas:
   * **Login:** `administrador`
   * **Senha:** `adminifal`
2. Execute o comando de atualização da lista de pacotes para garantir a comunicação correta com os espelhos oficiais:
   ```bash
   sudo apt-get update
   ```
3. Digite a senha `adminifal` quando solicitado pelo `sudo`.
4. Instale o **VirtualBox Extension Pack** no computador hospedeiro (se ainda não o tiver) acessando o site oficial: [virtualbox.org/wiki/Downloads](https://www.virtualbox.org/wiki/Downloads).

