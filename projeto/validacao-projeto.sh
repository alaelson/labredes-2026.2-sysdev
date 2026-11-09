#!/usr/bin/env bash
################################################################################
# VALIDAÇÃO DO PROJETO — Laboratório de Sistemas Operacionais e Redes (Técnico em DS 2026.02)
#
# Verifica, na VM onde é executado: endereço IP, hostname, /etc/hosts,
# resolução de nomes, usuários, pasta compartilhada do grupo, serviço SSH e
# conectividade com as demais VMs do grupo.
#
# Uso (em cada uma das 8 VMs do grupo):
#   1. Edite a seção "CONFIGURAÇÃO DO GRUPO" abaixo (número do grupo e usuários).
#   2. Execute com privilégios de administrador e salve a saída:
#        sudo bash validacao-projeto.sh | tee validacao-$(hostname -s).txt
#   3. Copie o arquivo validacao-<hostname>.txt para a pasta validacao/
#      do repositório do grupo.
################################################################################

# ============================ CONFIGURAÇÃO DO GRUPO ===========================
GRUPO=0                       # número do grupo (0 = grupo modelo)
DOMINIO_TURMA="sysdev.maceio.lab"
USUARIOS=( "fulano.tal" "fulustreca.grudes" "beltrano.silva" "cicrano.souza" )
ADMIN="administrador"
IFACE="enp0s3"
# ==============================================================================

REDE_BASE="192.168.13"
MASCARA=28
INICIO=$((16 * GRUPO))
DOMINIO="grupo${GRUPO}.${DOMINIO_TURMA}"
GRUPO_LINUX="grupo${GRUPO}"           # grupo Linux dos integrantes
PASTA="/srv/grupo${GRUPO}-dept"       # pasta compartilhada do grupo

# Endereços e nomes esperados: VM1..VM8 = 1º ao 8º endereço útil do /28
IPS=(); NOMES=()
for pc in 1 2 3 4; do
  for vm in 1 2; do
    k=$(( (pc - 1) * 2 + vm ))
    IPS+=( "${REDE_BASE}.$((INICIO + k))" )
    NOMES+=( "g${GRUPO}-pc${pc}-vm${vm}" )
  done
done

# Cores apenas quando a saída é um terminal (o arquivo salvo fica legível)
if [[ -t 1 ]]; then
  RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
else
  RED=''; GREEN=''; YELLOW=''; BLUE=''; NC=''
fi

PASSED=0; FAILED=0; WARNINGS=0
secao(){ echo ""; echo -e "${BLUE}→ $1${NC}"; }
ok(){    echo -e "${GREEN}[PASSOU]${NC} $1"; PASSED=$((PASSED + 1)); }
falha(){ echo -e "${RED}[FALHOU]${NC} $1"; FAILED=$((FAILED + 1)); }
aviso(){ echo -e "${YELLOW}[AVISO]${NC}  $1"; WARNINGS=$((WARNINGS + 1)); }
info(){  echo -e "${BLUE}[INFO]${NC}   $1"; }

MEU_IP=""; MEU_NOME=""

################################################################################
# 1. Configuração de rede
################################################################################
teste_rede(){
  secao "1. Configuração de rede ($IFACE)"

  if ! ip link show "$IFACE" &>/dev/null; then
    falha "Interface $IFACE não encontrada (verifique com: ip link)"
    return
  fi
  ip link show "$IFACE" | grep -q "state UP" && ok "Interface $IFACE está UP" || falha "Interface $IFACE não está UP"

  local cidr
  cidr=$(ip -4 -o addr show "$IFACE" | awk '{print $4}' | head -n1)
  if [[ -z "$cidr" ]]; then
    falha "Nenhum endereço IPv4 em $IFACE"
    return
  fi
  MEU_IP=${cidr%/*}
  local mask=${cidr#*/}

  local i
  for i in "${!IPS[@]}"; do
    [[ "${IPS[$i]}" == "$MEU_IP" ]] && MEU_NOME=${NOMES[$i]}
  done
  if [[ -n "$MEU_NOME" ]]; then
    ok "Endereço $MEU_IP pertence ao Grupo $GRUPO (esperado para $MEU_NOME)"
  else
    falha "Endereço $MEU_IP não é um dos endereços do Grupo $GRUPO (${IPS[0]} a ${IPS[7]})"
  fi
  [[ "$mask" == "$MASCARA" ]] && ok "Máscara /$mask" || falha "Máscara /$mask (esperado /$MASCARA)"

  local qtd
  qtd=$(ip -4 -o addr show "$IFACE" | wc -l)
  [[ "$qtd" -eq 1 ]] && ok "Apenas um endereço IPv4 em $IFACE" || aviso "$qtd endereços IPv4 em $IFACE (o esperado é apenas o endereço estático)"

  if ls /etc/netplan/*.yaml &>/dev/null; then
    if [[ $EUID -ne 0 ]]; then
      aviso "Execute com sudo para verificar os arquivos do Netplan"
    elif grep -qs "dhcp4: *\(false\|no\)" /etc/netplan/*.yaml; then
      ok "Netplan com dhcp4 desativado (IP estático)"
    else
      falha "Netplan sem 'dhcp4: false' (o IP deve ser estático)"
    fi
    if [[ $EUID -eq 0 ]] && grep -qs "$MEU_IP/$MASCARA" /etc/netplan/*.yaml; then
      ok "Endereço $MEU_IP/$MASCARA declarado no Netplan"
    elif [[ $EUID -eq 0 ]]; then
      falha "Endereço $MEU_IP/$MASCARA não encontrado nos arquivos do Netplan"
    fi
  else
    falha "Nenhum arquivo .yaml em /etc/netplan"
  fi

  local gw
  gw=$(ip route show default | awk '{print $3; exit}')
  if [[ -n "$gw" ]]; then
    info "Rota padrão via $gw (o projeto não exige gateway)"
  else
    info "Sem rota padrão (esperado: a rede do grupo não tem gateway)"
  fi
}

################################################################################
# 2. Hostname
################################################################################
teste_hostname(){
  secao "2. Hostname"
  local atual esperado
  atual=$(hostname)
  if [[ -z "$MEU_NOME" ]]; then
    aviso "Hostname atual: $atual (não foi possível deduzir o nome esperado pelo IP)"
    return
  fi
  esperado="${MEU_NOME}.${DOMINIO}"
  [[ "$atual" == "$esperado" ]] && ok "Hostname é o FQDN $esperado" || falha "Hostname é '$atual' (esperado: $esperado)"
  [[ "$(cat /etc/hostname 2>/dev/null)" == "$esperado" ]] && ok "/etc/hostname contém $esperado" || falha "/etc/hostname diferente de $esperado"
}

################################################################################
# 3. /etc/hosts e resolução de nomes
################################################################################
teste_hosts(){
  secao "3. /etc/hosts e resolução de nomes"
  local i ip nome fqdn res

  if [[ -n "$MEU_NOME" ]]; then
    grep -Eq "^127\.0\.1\.1[[:space:]]+${MEU_NOME}\.${DOMINIO//./\\.}([[:space:]]|$)" /etc/hosts \
      && ok "Linha 127.0.1.1 aponta para ${MEU_NOME}.${DOMINIO}" \
      || aviso "Linha 127.0.1.1 não aponta para ${MEU_NOME}.${DOMINIO}"
  fi

  for i in "${!IPS[@]}"; do
    ip=${IPS[$i]}; nome=${NOMES[$i]}; fqdn="${nome}.${DOMINIO}"
    if grep -Eq "^${ip//./\\.}[[:space:]]+${fqdn//./\\.}[[:space:]]+${nome}([[:space:]]|$)" /etc/hosts; then
      ok "/etc/hosts: $ip  $fqdn  $nome"
    else
      falha "/etc/hosts sem a linha: $ip  $fqdn  $nome"
    fi
    # Na própria VM, o nome pode resolver para 127.0.1.1 (linha criada na instalação)
    local aceitos=" $ip "
    [[ "$nome" == "$MEU_NOME" ]] && aceitos=" $ip 127.0.1.1 "
    res=$(getent hosts "$nome" | awk '{print $1; exit}')
    [[ -n "$res" && "$aceitos" == *" $res "* ]] && ok "getent hosts $nome -> $res" || falha "getent hosts $nome -> '${res:-nada}' (esperado $ip)"
    res=$(getent hosts "$fqdn" | awk '{print $1; exit}')
    [[ -n "$res" && "$aceitos" == *" $res "* ]] && ok "getent hosts $fqdn -> $res" || falha "getent hosts $fqdn -> '${res:-nada}' (esperado $ip)"
  done
}

################################################################################
# 4. Usuários
################################################################################
teste_usuarios(){
  secao "4. Usuários"
  local u shell
  for u in "$ADMIN" "${USUARIOS[@]}"; do
    if ! id "$u" &>/dev/null; then
      falha "Usuário '$u' não existe"
      continue
    fi
    ok "Usuário '$u' existe"
    [[ -d "/home/$u" ]] && ok "Diretório /home/$u existe" || falha "Diretório /home/$u não existe"
    shell=$(getent passwd "$u" | cut -d: -f7)
    [[ "$shell" == "/bin/bash" ]] && ok "Shell de '$u' é /bin/bash" || aviso "Shell de '$u' é $shell (esperado /bin/bash)"
  done
}

################################################################################
# 5. Pasta compartilhada do grupo
################################################################################
teste_pasta(){
  secao "5. Pasta compartilhada do grupo ($PASTA)"
  local u dono grupo perm
  if getent group "$GRUPO_LINUX" &>/dev/null; then
    ok "Grupo Linux '$GRUPO_LINUX' existe"
  else
    falha "Grupo Linux '$GRUPO_LINUX' não existe (sudo groupadd $GRUPO_LINUX)"
  fi
  for u in "${USUARIOS[@]}"; do
    id -nG "$u" 2>/dev/null | tr ' ' '\n' | grep -qx "$GRUPO_LINUX" \
      && ok "'$u' é membro de '$GRUPO_LINUX'" \
      || falha "'$u' não é membro de '$GRUPO_LINUX' (sudo usermod -aG $GRUPO_LINUX $u)"
  done
  if [[ ! -d "$PASTA" ]]; then
    falha "Pasta $PASTA não existe"
    return
  fi
  dono=$(stat -c %U "$PASTA"); grupo=$(stat -c %G "$PASTA"); perm=$(stat -c %a "$PASTA")
  [[ "$dono" == "$ADMIN" ]] && ok "Dono de $PASTA é $ADMIN" || falha "Dono de $PASTA é $dono (esperado $ADMIN)"
  [[ "$grupo" == "$GRUPO_LINUX" ]] && ok "Grupo de $PASTA é $GRUPO_LINUX" || falha "Grupo de $PASTA é $grupo (esperado $GRUPO_LINUX)"
  [[ "$perm" == "770" ]] && ok "Permissão de $PASTA é 770" || falha "Permissão de $PASTA é $perm (esperado 770)"
  if id novato &>/dev/null; then
    if sudo -u novato test -x "$PASTA" 2>/dev/null; then
      falha "O usuário 'novato' consegue entrar em $PASTA (deveria ser bloqueado)"
    else
      ok "O usuário 'novato' é bloqueado em $PASTA"
    fi
  else
    info "Usuário 'novato' não existe; teste de bloqueio não realizado"
  fi
}

################################################################################
# 6. Serviço SSH
################################################################################
teste_ssh(){
  secao "6. Serviço SSH"
  if systemctl is-active --quiet ssh || systemctl is-active --quiet ssh.socket; then
    ok "Serviço SSH ativo"
  else
    falha "Serviço SSH inativo (sudo systemctl enable --now ssh)"
  fi
  ss -tln 2>/dev/null | grep -Eq ':22([[:space:]]|$)' && ok "Porta 22/TCP em escuta" || falha "Nada escutando na porta 22/TCP"
}

################################################################################
# 7. Conectividade com as VMs do grupo
################################################################################
teste_conectividade(){
  secao "7. Conectividade com as VMs do grupo"
  local i ip nome
  for i in "${!IPS[@]}"; do
    ip=${IPS[$i]}; nome=${NOMES[$i]}
    [[ "$ip" == "$MEU_IP" ]] && continue
    if ping -c 2 -W 2 "$nome" &>/dev/null; then
      ok "ping $nome ($ip) respondeu"
    else
      falha "ping $nome ($ip) não respondeu"
    fi
    if timeout 3 bash -c "</dev/tcp/$ip/22" &>/dev/null; then
      ok "SSH (porta 22) acessível em $nome"
    else
      falha "SSH (porta 22) inacessível em $nome"
    fi
  done
}

################################################################################
# Relatório
################################################################################
echo "==============================================================="
echo " Validação do Projeto LSOR Técnico 2026.02 — Grupo $GRUPO"
echo " Domínio esperado: $DOMINIO"
echo " Data/hora: $(date '+%d/%m/%Y %H:%M:%S')"
echo " Hostname:  $(hostname)"
echo "==============================================================="

teste_rede
teste_hostname
teste_hosts
teste_usuarios
teste_pasta
teste_ssh
teste_conectividade

TOTAL=$((PASSED + FAILED))
echo ""
echo "==============================================================="
echo " RESUMO — $(hostname) (${MEU_IP:-sem IP})"
echo "   Passou: $PASSED   Falhou: $FAILED   Avisos: $WARNINGS"
if [[ $TOTAL -gt 0 ]]; then
  echo "   Aproveitamento: $((PASSED * 100 / TOTAL))%"
fi
if [[ $FAILED -eq 0 ]]; then
  echo -e "   ${GREEN}Resultado: VM configurada corretamente${NC}"
else
  echo -e "   ${RED}Resultado: revisar os itens que falharam${NC}"
fi
echo "==============================================================="

[[ $FAILED -eq 0 ]]
