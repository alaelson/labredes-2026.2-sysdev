# Aula 05: Estrutura de Diretórios do Linux (FHS) e Pastas Departamentais com Permissões

Nesta prática você vai conhecer a árvore de diretórios padrão do Linux (**FHS — Filesystem Hierarchy Standard**), entender para que serve cada pasta importante do sistema e montar uma estrutura de pastas de departamentos em que cada equipe só acessa a sua própria pasta.

**Pré-requisitos:** Aulas 01 e 02 concluídas (VM `ubuntu-server` instalada, usuário `administrador` e os usuários `fulano`, `cicrano`, `beltrano` e `novato` criados na Aula 2).

---

## 1. Objetivos da Aula
Ao final desta prática, você será capaz de:
* Explicar a função das principais pastas do padrão FHS (`/`, `/etc`, `/var`, `/srv`, `/tmp`, `/bin`, `/sbin`, `/home`).
* Navegar pelo sistema de arquivos com `cd`, `pwd` e `ls`.
* Criar diretórios aninhados de uma só vez com `mkdir -p`.
* Criar grupos, adicionar usuários a eles e conferir com `id`.
* Aplicar donos (`chown`) e permissões octais (`770` e `660`) para isolar pastas entre departamentos.
* Testar o isolamento trocando de usuário com `su -` e explicar a diferença entre `su` e `su -`.

---

## 2. Contexto Teórico: o Padrão FHS

No Linux, todos os arquivos ficam em uma única árvore que começa na **raiz**, representada por `/`. Não existe `C:` ou `D:` como no Windows: discos e partições são "pendurados" (montados) em pastas dessa árvore. O padrão FHS define o papel de cada pasta:

| Diretório | Para que serve |
| :--- | :--- |
| **`/`** | Raiz do sistema. Todas as outras pastas ficam dentro dela. |
| **`/etc`** | Arquivos de configuração do sistema e dos serviços (ex.: Netplan, SSH, contas de usuário em `/etc/passwd`). |
| **`/var`** | Dados que mudam com frequência: logs (`/var/log`), filas, caches, bancos de dados. |
| **`/srv`** | Dados dos serviços oferecidos pelo servidor (ex.: pastas compartilhadas, sites). **É onde vamos trabalhar hoje.** |
| **`/tmp`** | Arquivos temporários. Costuma ser limpo a cada reinicialização. |
| **`/bin`** | Comandos básicos usados por qualquer usuário (ex.: `ls`, `mkdir`, `cp`). |
| **`/sbin`** | Comandos de administração do sistema, normalmente usados com `sudo` (ex.: `ip`, `reboot`, `netplan`). |
| **`/home`** | Pastas pessoais dos usuários comuns (ex.: `/home/fulano`). |

> **Curiosidade:** no Ubuntu atual, `/bin` e `/sbin` são *atalhos* (links simbólicos) para `/usr/bin` e `/usr/sbin`. Você vai confirmar isso no Passo 1.

### Revisão rápida: permissões octais
Cada permissão vale um número: **r (leitura) = 4**, **w (escrita) = 2**, **x (execução / entrar na pasta) = 1**. Somamos os valores para cada um dos três públicos: **dono**, **grupo** e **outros**.

| Octal | Simbólico | Significado |
| :---: | :---: | :--- |
| `770` | `rwxrwx---` | Dono e grupo fazem tudo; outros não entram na pasta. |
| `660` | `rw-rw----` | Dono e grupo leem e escrevem o arquivo; outros não têm acesso. |

---

## 3. Roteiro Prático Passo a Passo

> **Importante:** faça login com o usuário **`administrador`** (configurado na Aula 1). Use `sudo` sempre que o comando alterar algo do sistema.

### Passo 1: Explorando as Pastas do Sistema

1. Vá até a raiz e liste as pastas principais:
```bash
administrador@ubuntu-server:~$ cd /
administrador@ubuntu-server:/$ ls
```

2. Confirme que `/bin` e `/sbin` são atalhos para pastas dentro de `/usr`:
```bash
administrador@ubuntu-server:/$ ls -ld /bin /sbin
```
A seta (`->`) na saída indica um link simbólico, por exemplo `/bin -> usr/bin`.

3. Entre em `/etc`, confira onde você está e liste os 15 primeiros itens:
```bash
administrador@ubuntu-server:/$ cd /etc
administrador@ubuntu-server:/etc$ pwd
/etc
administrador@ubuntu-server:/etc$ ls -F | head -n 15
```
A opção `-F` coloca uma barra `/` no fim dos nomes que são pastas. O `| head -n 15` mostra só as 15 primeiras linhas.

4. Leia as últimas 10 linhas do log de autenticação (logins e usos do `sudo`):
```bash
administrador@ubuntu-server:/etc$ sudo tail -n 10 /var/log/auth.log
```
> Se o arquivo `auth.log` não existir na sua VM, use o diário do sistema: `sudo journalctl -n 10`.

---

### Passo 2: Criando as Pastas dos Departamentos

Vamos simular uma empresa com dois departamentos dentro de `/srv`:
* `/srv/ti-dept` (equipe de Tecnologia), com a subpasta `projetos`
* `/srv/vendas-dept` (equipe de Vendas), com a subpasta `relatorios`

A opção **`-p` (parents)** do `mkdir` cria a pasta e todas as pastas "mãe" que faltarem, de uma só vez:

```bash
administrador@ubuntu-server:/etc$ cd /srv
administrador@ubuntu-server:/srv$ sudo mkdir -p ti-dept/projetos vendas-dept/relatorios
```

Liste de forma recursiva (`-R`) para conferir a árvore criada:
```bash
administrador@ubuntu-server:/srv$ ls -R
.:
ti-dept  vendas-dept

./ti-dept:
projetos

./vendas-dept:
relatorios
```

---

### Passo 3: Criando os Grupos e Adicionando os Usuários

Crie um grupo para cada departamento:
```bash
administrador@ubuntu-server:/srv$ sudo groupadd ti-group
administrador@ubuntu-server:/srv$ sudo groupadd vendas-group
```

Adicione os usuários da Aula 2:
* **`fulano`** → grupo **`ti-group`**
* **`cicrano`** → grupo **`vendas-group`**

```bash
administrador@ubuntu-server:/srv$ sudo usermod -aG ti-group fulano
administrador@ubuntu-server:/srv$ sudo usermod -aG vendas-group cicrano
```
> **Atenção ao `-aG`:** o `-a` (*append*) **adiciona** o grupo à lista do usuário. Sem o `-a`, o usuário seria removido de todos os outros grupos extras (como o `devs` da Aula 2).

Confira os grupos de cada usuário:
```bash
administrador@ubuntu-server:/srv$ id fulano
administrador@ubuntu-server:/srv$ id cicrano
```
O `ti-group` deve aparecer na lista de `fulano`, e o `vendas-group` na de `cicrano`. O usuário `novato` fica sem nenhum desses grupos e vai representar "qualquer outro usuário" do sistema.

---

### Passo 4: Definindo Donos e Permissões das Pastas

Veja que, por enquanto, as pastas pertencem ao `root`:
```bash
administrador@ubuntu-server:/srv$ ls -ld ti-dept vendas-dept
drwxr-xr-x 3 root root 4096 Nov 10 14:35 ti-dept
drwxr-xr-x 3 root root 4096 Nov 10 14:35 vendas-dept
```

1. Defina o dono (`administrador`) e o grupo de cada pasta. A opção **`-R`** aplica a mudança também às subpastas (`projetos` e `relatorios`):
```bash
administrador@ubuntu-server:/srv$ sudo chown -R administrador:ti-group ti-dept
administrador@ubuntu-server:/srv$ sudo chown -R administrador:vendas-group vendas-dept
```

2. Aplique a permissão **`770`**: dono e grupo fazem tudo, e os demais usuários não conseguem nem entrar na pasta:
```bash
administrador@ubuntu-server:/srv$ sudo chmod -R 770 ti-dept
administrador@ubuntu-server:/srv$ sudo chmod -R 770 vendas-dept
```

3. Confira o resultado:
```bash
administrador@ubuntu-server:/srv$ ls -ld ti-dept vendas-dept
drwxrwx--- 3 administrador ti-group     4096 Nov 10 14:35 ti-dept
drwxrwx--- 3 administrador vendas-group 4096 Nov 10 14:35 vendas-dept
```
A máscara agora é **`drwxrwx---`**: o `d` indica diretório, seguido de `rwx` (dono), `rwx` (grupo) e `---` (outros).

---

### Passo 5: Criando um Arquivo Confidencial

Crie um arquivo dentro da pasta de TI:
```bash
administrador@ubuntu-server:/srv$ sudo touch ti-dept/projetos/arquitetura_rede.txt
```

Defina dono, grupo e a permissão **`660`** (dono e grupo leem e escrevem; outros sem acesso):
```bash
administrador@ubuntu-server:/srv$ sudo chown administrador:ti-group ti-dept/projetos/arquitetura_rede.txt
administrador@ubuntu-server:/srv$ sudo chmod 660 ti-dept/projetos/arquitetura_rede.txt
administrador@ubuntu-server:/srv$ ls -l ti-dept/projetos/
-rw-rw---- 1 administrador ti-group 0 Nov 10 14:40 arquitetura_rede.txt
```

---

## 4. Testes de Isolamento

Para testar sem sair do console, vamos "virar" outro usuário com o comando `su` (*substitute user*).

> ### 🔍 `su <usuario>` x `su - <usuario>`
> * **`su fulano` (sem hífen):** troca de usuário, mas **continua na mesma pasta e com as variáveis de ambiente** (como `HOME` e `PATH`) do usuário anterior. É como vestir o crachá de outra pessoa sem sair da sua mesa.
> * **`su - fulano` (com hífen):** faz um **login completo**: vai para `/home/fulano`, limpa o ambiente anterior e carrega as configurações do novo usuário (`.bashrc`, `.profile`).
>
> **Nos testes usamos sempre `su -`**, para que o resultado reflita exatamente o que aquele usuário conseguiria fazer ao entrar no sistema, sem "herança" do usuário anterior.

### Teste A: Usuário do grupo de TI (`fulano`) — acesso permitido
```bash
administrador@ubuntu-server:/srv$ su - fulano
Password: <senha do fulano>
fulano@ubuntu-server:~$ whoami
fulano
fulano@ubuntu-server:~$ pwd
/home/fulano
fulano@ubuntu-server:~$ cd /srv/ti-dept
fulano@ubuntu-server:/srv/ti-dept$ ls -l projetos/
-rw-rw---- 1 administrador ti-group 0 Nov 10 14:40 arquitetura_rede.txt
fulano@ubuntu-server:/srv/ti-dept$ echo "Rede do lab: 172.20.20.0/22" >> projetos/arquitetura_rede.txt
fulano@ubuntu-server:/srv/ti-dept$ cat projetos/arquitetura_rede.txt
Rede do lab: 172.20.20.0/22
fulano@ubuntu-server:/srv/ti-dept$ exit
```
`fulano` pertence ao `ti-group`, então consegue entrar na pasta, ler e escrever no arquivo.

### Teste B: Usuário de outro departamento (`cicrano`) — acesso negado
```bash
administrador@ubuntu-server:/srv$ su - cicrano
Password: <senha do cicrano>
cicrano@ubuntu-server:~$ cd /srv/ti-dept
-bash: cd: /srv/ti-dept: Permission denied
cicrano@ubuntu-server:~$ cd /srv/vendas-dept
cicrano@ubuntu-server:/srv/vendas-dept$ ls
relatorios
cicrano@ubuntu-server:/srv/vendas-dept$ exit
```
`cicrano` é barrado na pasta de TI, mas entra normalmente na pasta do seu próprio departamento.

### Teste C: Usuário sem departamento (`novato`) — acesso negado nas duas pastas
```bash
administrador@ubuntu-server:/srv$ su - novato
Password: <senha do novato>
novato@ubuntu-server:~$ cd /srv/ti-dept
-bash: cd: /srv/ti-dept: Permission denied
novato@ubuntu-server:~$ cd /srv/vendas-dept
-bash: cd: /srv/vendas-dept: Permission denied
novato@ubuntu-server:~$ exit
```

> **Dica:** se o `fulano` receber `Permission denied` no Teste A, provavelmente ele já estava logado em outro terminal antes de ser adicionado ao grupo. Os grupos são carregados no login: saia com `exit` e entre de novo com `su - fulano`. Confira com `id`.

---

## 5. Desafio de Laboratório

Repita o processo sozinho para um novo departamento:

1. Crie a pasta `/srv/diretoria-dept`.
2. Crie o grupo `diretoria-group`.
3. Adicione o usuário **`beltrano`** ao grupo `diretoria-group`.
4. Faça com que `/srv/diretoria-dept` pertença ao usuário `administrador` e ao grupo `diretoria-group`.
5. Aplique a permissão numérica que dá controle total ao dono e ao grupo e bloqueia completamente os outros usuários.
6. Crie o arquivo `orcamento.txt` dentro da pasta, com leitura e escrita apenas para o dono e o grupo.
7. Teste o acesso com `beltrano` (deve funcionar) e com `fulano` (deve ser bloqueado).

---

## 6. Atividade: Relatório Técnico

Cada aluno registra a prática no **seu repositório de entrega** (`lsor-2026.2-sysdev-atividades-<nomedoaluno>`), mantendo a mesma estrutura usada nas aulas anteriores.

### 6.1. Onde incorporar na estrutura do repositório

```text
lsor-2026.2-sysdev-atividades-<nomedoaluno>/
├── README.md               # Adicionar o link para atividade-aula5.md
├── atividade-aula1.md
├── atividade-aula2.md
├── atividade-aula3.md
├── atividade-aula4.md
├── atividade-aula5.md      # NOVO: Relatório Técnico da Aula 05
└── imagens/
    ├── ... (imagens das aulas anteriores)
    ├── aula5_ls_raiz.png
    ├── aula5_bin_sbin.png
    ├── aula5_etc_pwd.png
    ├── aula5_auth_log.png
    ├── aula5_mkdir_ls_r.png
    ├── aula5_grupos_id.png
    ├── aula5_chown_chmod.png
    ├── aula5_arquivo_660.png
    ├── aula5_teste_a_fulano.png
    ├── aula5_teste_b_cicrano.png
    ├── aula5_teste_c_novato.png
    └── aula5_desafio_*.png
```

**Regras (as mesmas das aulas anteriores):**
* O relatório é o arquivo `atividade-aula5.md`, na raiz do repositório.
* As capturas de tela ficam em `imagens/`, nomeadas `aula5_descricao.png` (minúsculas, sem espaços nem acentos).
* Referencie as imagens com caminho relativo: `![Teste A](imagens/aula5_teste_a_fulano.png)`.
* Adicione ao `README.md` do repositório um link para `atividade-aula5.md`.

### 6.2. Como escrever cada evidência

O relatório **não é um álbum de prints**. Cada passo deve ser contado em três partes, sempre nesta ordem:

1. **Texto explicando o que você está fazendo e por quê**, com suas palavras (ex.: "Agora vou dar ao grupo `ti-group` a posse da pasta para que só a equipe de TI consiga acessá-la").
2. **Bloco de código** com os comandos exatamente como você digitou.
3. **Print da execução**, mostrando o comando e a saída no terminal da sua VM. O prompt (`administrador@ubuntu-server` ou `fulano@ubuntu-server`) deve aparecer no print, para confirmar quem executou.

Depois do print, escreva **uma ou duas frases interpretando o resultado** (o que a saída mostra e se era o esperado).

**Exemplo de como um passo deve ficar no `atividade-aula5.md`:**

````markdown
### Passo 4 — Donos e permissões das pastas

Neste passo eu transfiro a posse das pastas dos departamentos para o usuário
`administrador` e para o grupo de cada departamento. Em seguida, aplico a
permissão 770, para que só o dono e os membros do grupo possam entrar na pasta.

```bash
sudo chown -R administrador:ti-group /srv/ti-dept
sudo chown -R administrador:vendas-group /srv/vendas-dept
sudo chmod -R 770 /srv/ti-dept /srv/vendas-dept
ls -ld /srv/ti-dept /srv/vendas-dept
```

![Donos e permissões das pastas](imagens/aula5_chown_chmod.png)

A saída do `ls -ld` mostra `drwxrwx---`, com dono `administrador` e o grupo
de cada departamento. Ou seja, os outros usuários ficaram sem nenhum acesso,
como esperado.
````

### 6.3. Evidências obrigatórias
1. **Passo 1:** `ls` na raiz; `ls -ld /bin /sbin` (links simbólicos); `pwd` e `ls -F | head -n 15` em `/etc`; leitura do `auth.log` (ou `journalctl`).
2. **Passo 2:** `mkdir -p` e a árvore mostrada por `ls -R`.
3. **Passo 3:** criação dos grupos, `usermod -aG` e a saída de `id fulano` e `id cicrano`.
4. **Passo 4:** `ls -ld` **antes** (dono `root`) e **depois** (`drwxrwx---`).
5. **Passo 5:** arquivo com `-rw-rw----`.
6. **Testes A, B e C:** acesso permitido para `fulano` e `Permission denied` para `cicrano` e `novato`.
7. **Desafio:** todos os comandos e os testes com `beltrano` (permitido) e `fulano` (bloqueado).

### 6.4. Explique os comandos
Inclua no relatório uma tabela com **cada comando usado nesta aula e o que ele faz**, com suas palavras. Use a tabela abaixo como ponto de partida e complete a coluna da direita:

| Comando | O que significa / o que faz |
| :--- | :--- |
| `cd /etc` | |
| `pwd` | |
| `ls -F`, `ls -R`, `ls -ld` | |
| `sudo tail -n 10 /var/log/auth.log` | |
| `mkdir -p` | |
| `groupadd` | |
| `usermod -aG` | |
| `id` | |
| `chown -R dono:grupo` | |
| `chmod 770` / `chmod 660` | |
| `touch` | |
| `su -` x `su` | |
| `whoami` | |

### 6.5. Modelo de Relatório (7 Passos) para `atividade-aula5.md`
1. **Identificação:** nome completo, matrícula, turma (Técnico em Desenvolvimento de Sistemas 2026.02), data e título da prática.
2. **Objetivo:** o que foi praticado (pastas do FHS, criação de diretórios com `mkdir -p`, grupos e permissões de pastas departamentais).
3. **Ambiente:** VM `ubuntu-server` (Ubuntu Server 26.04 LTS, 768 MB de RAM, 1 CPU) no VirtualBox e usuários utilizados nos testes.
4. **Procedimento:** os Passos 1 a 5, cada um com **texto + bloco de código + print + interpretação**, como no exemplo da seção 6.2.
5. **Testes:** Testes A, B e C e o Desafio, no mesmo formato, e a tabela de comandos da seção 6.4.
6. **Problemas e Soluções:** ao menos um problema encontrado (ex.: esquecer o `sudo`, usar `su` sem hífen, grupo que não "pegou" até um novo login) e como foi resolvido.
7. **Conclusão:** por que separar pastas por grupo e usar permissões restritas é importante para a segurança de um servidor.

---

## 7. Critérios de Avaliação
- [ ] Explicou a função das pastas do FHS e mostrou que `/bin` e `/sbin` são links para `/usr`.
- [ ] Criou a estrutura com `mkdir -p` e mostrou a árvore com `ls -R`.
- [ ] Criou os grupos e adicionou os usuários com `usermod -aG`, conferindo com `id`.
- [ ] Aplicou `chown` e as permissões `770` (pastas) e `660` (arquivo) corretamente.
- [ ] Demonstrou acesso permitido (Teste A) e bloqueado (Testes B e C), usando `su -`.
- [ ] Concluiu o Desafio com os testes de `beltrano` e `fulano`.
- [ ] Entregou `atividade-aula5.md` na estrutura do repositório, com texto explicativo, bloco de código e print em cada passo, e a tabela de comandos preenchida.
