#!/usr/bin/env bash
# =============================================================================
#  install.sh — Instala o Global Engineering Harness no OpenCode
# =============================================================================
#  Copia os arquivos do harness (AGENTS.md, commands/, agents/, harness/)
#  para ~/.config/opencode/, preservando o opencode.jsonc do usuário.
#
#  Uso:
#     ./install.sh                  # instala com confirmação interativa
#     ./install.sh --dry-run        # mostra o que faria sem fazer
#     ./install.sh --force          # sobrescreve AGENTS.md sem perguntar
#     ./install.sh --uninstall      # reverte usando backups
#
#  Variáveis de ambiente:
#     OPENCODE_HOME  Diretório do OpenCode (default: $HOME/.config/opencode)
#     HARNESS_SRC    Diretório-fonte do harness (default: dirname deste script)
# =============================================================================

set -euo pipefail

# -----------------------------------------------------------------------------
# Configuração
# -----------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HARNESS_SRC="${HARNESS_SRC:-$SCRIPT_DIR}"
OPENCODE_HOME="${OPENCODE_HOME:-$HOME/.config/opencode}"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_ROOT="${OPENCODE_HOME}/.harness-backups"

DRY_RUN="false"
FORCE="false"
UNINSTALL="false"

# -----------------------------------------------------------------------------
# Cores
# -----------------------------------------------------------------------------
if [[ -t 1 ]]; then
  C_RED=$'\033[31m'; C_GRN=$'\033[32m'; C_YLW=$'\033[33m'
  C_BLU=$'\033[34m'; C_DIM=$'\033[2m';  C_BLD=$'\033[1m'; C_RST=$'\033[0m'
else
  C_RED=""; C_GRN=""; C_YLW=""; C_BLU=""; C_DIM=""; C_BLD=""; C_RST=""
fi

info()  { printf "${C_BLU}▸${C_RST} %s\n" "$*"; }
ok()    { printf "${C_GRN}✓${C_RST} %s\n" "$*"; }
warn()  { printf "${C_YLW}⚠${C_RST} %s\n" "$*" >&2; }
err()   { printf "${C_RED}✗${C_RST} %s\n" "$*" >&2; }
title() { printf "\n${C_BLD}%s${C_RST}\n" "$*"; }

# -----------------------------------------------------------------------------
# Argumentos
# -----------------------------------------------------------------------------
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)    DRY_RUN="true"; shift ;;
    --force)      FORCE="true"; shift ;;
    --uninstall)  UNINSTALL="true"; shift ;;
    -h|--help)
      sed -n '2,20p' "$0"
      exit 0
      ;;
    *)
      err "Argumento desconhecido: $1"
      exit 1
      ;;
  esac
done

# -----------------------------------------------------------------------------
# Pré-requisitos
# -----------------------------------------------------------------------------
title "Verificando pré-requisitos"

if [[ ! -d "$HARNESS_SRC" ]]; then
  err "Diretório-fonte não encontrado: $HARNESS_SRC"
  exit 1
fi

for required in "AGENTS.md" "commands" "agents" "harness"; do
  if [[ ! -e "$HARNESS_SRC/$required" ]]; then
    err "Arquivo/diretório obrigatório ausente: $required"
    exit 1
  fi
done

if ! command -v opencode >/dev/null 2>&1; then
  warn "Comando 'opencode' não está no PATH (continuando mesmo assim)"
fi

info "Source:      $HARNESS_SRC"
info "Destino:     $OPENCODE_HOME"
info "Modo:        $([[ $DRY_RUN == true ]] && echo "dry-run" || echo "instalação")"

# -----------------------------------------------------------------------------
# Desinstalação
# -----------------------------------------------------------------------------
if [[ "$UNINSTALL" == "true" ]]; then
  title "Desinstalando harness"

  if [[ ! -d "$BACKUP_ROOT" ]]; then
    err "Nenhum backup encontrado em $BACKUP_ROOT"
    exit 1
  fi

  latest_backup="$(ls -1dt "$BACKUP_ROOT"/* 2>/dev/null | head -1 || true)"

  if [[ -z "$latest_backup" ]]; then
    err "Nenhum backup válido encontrado em $BACKUP_ROOT"
    exit 1
  fi

  info "Restaurando a partir de: $latest_backup"

  # Restaura AGENTS.md
  if [[ -f "$latest_backup/AGENTS.md" ]]; then
    run() {
      if [[ $DRY_RUN == true ]]; then echo "  [dry-run] $*"; else "$@"; fi
    }
    run cp -p "$latest_backup/AGENTS.md" "$OPENCODE_HOME/AGENTS.md"
    ok "AGENTS.md restaurado"
  fi

  # Remove arquivos implantados
  for path in AGENTS.md commands agents harness; do
    target="$OPENCODE_HOME/$path"
    if [[ -e "$target" ]]; then
      run() {
        if [[ $DRY_RUN == true ]]; then echo "  [dry-run] $*"; else "$@"; fi
      }
      if [[ -d "$target" && "$path" != "AGENTS.md" ]]; then
        run rm -rf "$target"
      elif [[ "$path" == "AGENTS.md" ]]; then
        # já tratado acima
        :
      fi
      ok "Removido: $path"
    fi
  done

  info "Desinstalação concluída."
  exit 0
fi

# -----------------------------------------------------------------------------
# Funções utilitárias
# -----------------------------------------------------------------------------
run() {
  if [[ $DRY_RUN == true ]]; then
    echo "  ${C_DIM}[dry-run]${C_RST} $*"
  else
    "$@"
  fi
}

confirm() {
  local prompt="$1"
  local response

  if [[ ! -t 0 ]] || [[ $FORCE == true ]]; then
    return 0
  fi

  printf "${C_YLW}?${C_RST} %s [s/N] " "$prompt"
  read -r response
  [[ "$response" =~ ^[sSyY]$ ]]
}

# -----------------------------------------------------------------------------
# Cria diretórios
# -----------------------------------------------------------------------------
title "Criando estrutura de diretórios"

for sub in "commands" "agents" "harness/core" "harness/workflows" \
           "harness/gates" "harness/profiles" "harness/templates"; do
  target="$OPENCODE_HOME/$sub"
  if [[ -d "$target" ]]; then
    info "Já existe: $sub/"
  else
    run mkdir -p "$target"
    ok "Criado:    $sub/"
  fi
done

# -----------------------------------------------------------------------------
# Backup do que será sobrescrito
# -----------------------------------------------------------------------------
title "Verificando arquivos existentes"

BACKUP_DIR="$BACKUP_ROOT/$TIMESTAMP"
need_backup="false"

if [[ -f "$OPENCODE_HOME/AGENTS.md" ]]; then
  if [[ $DRY_RUN == true ]]; then
    info "AGENTS.md global existe (seria sobrescrito em modo real)"
  else
    if confirm "AGENTS.md global já existe. Sobrescrever (backup será salvo)?"; then
      need_backup="true"
    else
      err "Instalação cancelada pelo usuário."
      exit 1
    fi
  fi
fi

if [[ $need_backup == true ]]; then
  run mkdir -p "$BACKUP_DIR"
  run cp -p "$OPENCODE_HOME/AGENTS.md" "$BACKUP_DIR/AGENTS.md"
  ok "Backup salvo em: $BACKUP_DIR/AGENTS.md"
fi

# -----------------------------------------------------------------------------
# Cópia dos arquivos
# -----------------------------------------------------------------------------
title "Implantando arquivos do harness"

copy_tree() {
  local src="$1"
  local dst="$2"

  if [[ ! -d "$src" ]]; then
    warn "Origem não encontrada: $src"
    return
  fi

  run mkdir -p "$dst"

  # Usa find + cp para preservar estrutura e ser portável
  while IFS= read -r -d '' file; do
    rel="${file#$src/}"
    target="$dst/$rel"
    run mkdir -p "$(dirname "$target")"
    run cp "$file" "$target"
    printf "  ${C_DIM}•${C_RST} %s\n" "$rel"
  done < <(find "$src" -type f -print0)
}

copy_tree "$HARNESS_SRC/commands" "$OPENCODE_HOME/commands"
copy_tree "$HARNESS_SRC/agents"   "$OPENCODE_HOME/agents"
copy_tree "$HARNESS_SRC/harness"  "$OPENCODE_HOME/harness"

# AGENTS.md global
if [[ -f "$HARNESS_SRC/AGENTS.md" ]]; then
  run cp "$HARNESS_SRC/AGENTS.md" "$OPENCODE_HOME/AGENTS.md"
  ok "AGENTS.md global implantado"
fi

# -----------------------------------------------------------------------------
# Relatório final
# -----------------------------------------------------------------------------
title "Instalação concluída"

printf "${C_BLD}Arquivos implantados em:${C_RST} %s\n\n" "$OPENCODE_HOME"

printf "  %s\n" "AGENTS.md"
printf "  commands/      (%d arquivos)\n"  "$(find "$OPENCODE_HOME/commands" -type f 2>/dev/null | wc -l)"
printf "  agents/        (%d arquivos)\n"  "$(find "$OPENCODE_HOME/agents"   -type f 2>/dev/null | wc -l)"
printf "  harness/       (%d arquivos)\n\n" "$(find "$OPENCODE_HOME/harness"  -type f 2>/dev/null | wc -l)"

printf "${C_DIM}opencode.jsonc do usuário preservado (não foi tocado).${C_RST}\n\n"

printf "${C_BLD}Próximos passos:${C_RST}\n"
printf "  1. Abra o OpenCode em qualquer projeto\n"
printf "  2. Digite /init-project para gerar contexto do projeto\n"
printf "  3. Use /feature, /bug, /debug, /refactor, /review conforme necessário\n"
printf "  4. Para ajustar modelos por agent, edite ~/.config/opencode/opencode.jsonc\n"
printf "     (veja examples/presets.jsonc para 3 presets prontos)\n\n"

printf "${C_DIM}Para atualizar depois:${C_RST} ./update.sh\n"
printf "${C_DIM}Para ver o que mudaria:${C_RST}  ./update.sh --diff-only\n"