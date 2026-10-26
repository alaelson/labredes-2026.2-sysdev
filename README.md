# Laboratório de Sistemas Operacionais e Redes (LSOR)
## Curso Técnico em Desenvolvimento de Sistemas - 2026.02

Repositório oficial para a organização e acompanhamento das práticas de laboratório da disciplina **Laboratório de Sistemas Operacionais e Redes (LSOR)** do curso de **Curso Técnico Integrado em Desenvolvimento de Sistemas** no **Instituto Federal de Alagoas (IFAL) - Campus Maceió**, para o semestre letivo **2026.02**.

Esta disciplina tem natureza eminentemente prática e aplicada, na qual cada conceito de redes e sistemas operacionais é transformado em configuração, teste, diagnóstico e documentação técnica.

---

## 💻 Informações Gerais do Laboratório

Para manter a padronização das práticas, a compatibilidade de redes e a segurança nos testes, adotamos as seguintes diretrizes de ambiente de hardware e credenciais:

*   **Hipervisor:** [VirtualBox](https://www.virtualbox.org/) (com o respetivo *Extension Pack* instalado no hospedeiro) .
*   **Sistema Operacional Guest:** Ubuntu Server 26.04 LTS (64-bit) .
*   **Hardware Padrão da VM:** 512 MB de Memória RAM, 1 CPU Virtual e 32 GB de Disco Rígido (VDI, Alocação Dinâmica) .


### 📁 Estrutura de Diretórios no Host (Windows do Laboratório)
*   **Armazenamento de ISOs originais:** `C:\2026.2\SysDevTech\VM\original` .
*   **Diretório de Trabalho do Aluno:** `C:\2026.2\SysDevTech\VM\<NomeDoAluno>` .

---

## 📚 Roteiros das Aulas Práticas

Os links abaixo apontam para os roteiros detalhados de cada prática realizada em laboratório. Cada roteiro contém as explicações conceituais, os comandos necessários e os testes de validação exigidos.

1.  **[Aula 01: Instalação e Configuração Básica do Ubuntu Server](Aula1.md)**
    *   Criação de VM no VirtualBox .
    *   Particionamento avançado de disco usando LVM: `/` (29 GB), `/boot` (1 GB) e `SWAP` (2 GB) .
    *   Primeiro boot, atualização de repositórios (`apt-get update`) e verificação de conectividade básica .
2.  **[Aula 02: Administração de Usuários, Grupos e Permissões](Aula2.md)**
    *   Criação e gerenciamento de contas de usuários.
    *   Criação de grupos de trabalho e atribuição de membros.
    *   Configuração fina de permissões em diretórios compartilhados.
    *   Testes de controle de acesso local e isolamento de segurança.
3.  **[Aula 03: Interfaces e Endereçamento de Rede](Aula3.md)**
    *   Inspeção de interfaces e rotas com `ip addr`, `ip link` e `ip route`.
    *   Testes de conectividade em camadas com `ping` e `traceroute`.
    *   Comparação entre os modos NAT e Placa em Ponte (Bridge) no VirtualBox.
4.  *Aula 04: Configuração de Acesso Remoto Seguro com OpenSSH (Em breve)*
5.  *Aula 05: Conectividade Avançada via Rede Host-Only no VirtualBox (Em breve)*
6.  *Aula 06: Configuração de Nomes Estáticos de Host (Em breve)*
7.  *Aula 07: Implantação de Rede Virtual Privada com OpenVPN (Em breve)*

---



## 🛠️ Dicas de Laboratório e Solução de Problemas

*   **Teclado Desconfigurado no Console:** Caso o layout do seu teclado esteja incorreto no terminal virtual da VM, configure-o para o padrão brasileiro ABNT2 com o comando:
    ```bash
    sudo dpkg-reconfigure keyboard-configuration
    ```
*   **Isolamento no VirtualBox:** Ao realizar configurações de rede interna, lembre-se de que o modo *Host-Only* permite que a sua máquina real acesse a máquina virtual, mas impede que ela acesse a internet pública diretamente sem um serviço de NAT ou roteamento ativado.

---

## 📖 Referências Bibliográficas Recomendadas

*   LACROIX, Jay. **Mastering Ubuntu Server**. 4. ed. Packt Publishing, 2023.
*   SOYINKA, Wale. **Linux Administration: A Beginner's Guide**. 8. ed. McGraw-Hill, 2020 .
*   KUROSE, James F.; ROSS, Keith W. **Redes de Computadores e a Internet**. 8. ed. Pearson, 2022.

---

## 📦 Estrutura do Repositório de Entrega do Aluno

Cada aluno deve organizar o **seu próprio repositório** de entregas da seguinte forma:

```text
lsor-atividades/
├── README.md               # Instruções gerais e identificação do aluno
├── atividade-aula1.md      # Caderno de respostas da Aula 01
├── atividade-aula2.md      # Caderno de respostas da Aula 02
├── atividade-aula3.md      # Caderno de respostas da Aula 03
└── imagens/                # Imagens de evidência técnica (capturas de tela)
    ├── aula1_instalacao.png
    ├── aula2_usuarios.png
    ├── aula2_grupos.png
    └── ... (demais capturas exigidas)
```

**Regras:**
*   Um arquivo `atividade-aulaN.md` por aula (`N` = número da aula).
*   Todas as capturas de tela ficam na pasta `imagens/`, nomeadas como `aulaN_descricao.png` (minúsculas, sem espaços ou acentos).
*   Referencie as imagens no Markdown com caminho relativo: `![Descrição](imagens/aula2_usuarios.png)`.
*   Cada resposta deve conter o comando executado, a saída obtida e a imagem de evidência correspondente.
