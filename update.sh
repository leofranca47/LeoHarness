#!/usr/bin/env bash
# =============================================================================
#  update.sh — Atualiza o Global Engineering Harness no OpenCode
# =============================================================================
#  Reimplanta os arquivos do harness preservando configurações do usuário.
#
#  Uso:
#     ./update.sh                  # aplica atualização
#     ./update.sh --diff-only      # mostra o que mudaria sem aplicar
#     ./update.sh --uninstall      # reverte para versão anterior (último backup)
#     ./update.sh --show-snippet         # imprime examples/presets.jsonc
#     ./update.sh --show-snippet fast    # imprime só um preset
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HARNESS_SRC="${HARNESS_SRC:-$SCRIPT_DIR}"
OPENCODE_HOME="${OPENCODE_HOME:-$HOME/.config/opencode}"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_ROOT="${OPENCODE_HOME}/.harness-backups"

DIFF_ONLY="false"
UNINSTALL="false"
SHOW_SNIPPET=""
PRESET_NAME=""

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
# Parse de argumentos
# -----------------------------------------------------------------------------
while [[ $# -gt 0 ]]; do
  case "$1" in
    --diff-only)    DIFF_ONLY="true"; shift ;;
    --uninstall)    UNINSTALL="true"; shift ;;
    --show-snippet) SHOW_SNIPPET="true"; shift; PRESET_NAME="${1:-all}"; [[ $# -gt 0 ]] && shift ;;
    -h|--help)
      sed -n '2,18p' "$0"
      exit 0
      ;;
    *)
      err "Argumento desconhecido: $1"
      exit 1
      ;;
  esac
done

# -----------------------------------------------------------------------------
# --show-snippet
# -----------------------------------------------------------------------------
if [[ "$SHOW_SNIPPET" == "true" ]]; then
  if [[ ! -f "$HARNESS_SRC/examples/presets.jsonc" ]]; then
    err "Arquivo examples/presets.jsonc não encontrado em $HARNESS_SRC"
    exit 1
  fi

  if [[ "$PRESET_NAME" == "all" ]]; then
    cat "$HARNESS_SRC/examples/presets.jsonc"
  else
    # Extrai o bloco do preset pedido, rastreando chaves
    awk -v target="$PRESET_NAME" '
      $0 ~ "\""target"\":[[:space:]]*\\{" {
        in_block = 1
        depth = 0
      }
      in_block {
        print
        n = gsub(/\\{/, "{")
        n = gsub(/\\}/, "}")
        for (i = 1; i <= length($0); i++) {
          c = substr($0, i, 1)
          if (c == "{") depth++
          if (c == "}") {
            depth--
            if (depth == 0) { in_block = 0; next }
          }
        }
        if (depth == 0) in_block = 0
      }
    ' "$HARNESS_SRC/examples/presets.jsonc"
  fi
  exit 0
fi

# -----------------------------------------------------------------------------
# --uninstall (reverte via último backup)
# -----------------------------------------------------------------------------
if [[ "$UNINSTALL" == "true" ]]; then
  exec "$SCRIPT_DIR/install.sh" --uninstall
fi

# -----------------------------------------------------------------------------
# Pré-requisitos
# -----------------------------------------------------------------------------
title "Verificando ambiente"

if [[ ! -d "$HARNESS_SRC" ]]; then
  err "Diretório-fonte não encontrado: $HARNESS_SRC"
  exit 1
fi

if [[ ! -d "$OPENCODE_HOME" ]]; then
  err "Diretório do OpenCode não encontrado: $OPENCODE_HOME (rode install.sh primeiro)"
  exit 1
fi

info "Source:  $HARNESS_SRC"
info "Destino: $OPENCODE_HOME"

# -----------------------------------------------------------------------------
# Cálculo do diff
# -----------------------------------------------------------------------------
title "Calculando diferenças"

declare -a to_add=()
declare -a to_change=()
declare -a to_delete=()

# Arquivos no source
while IFS= read -r -d '' src_file; do
  rel="${src_file#$HARNESS_SRC/}"

  # Ignora arquivos de script e docs (não fazem parte da implantação)
  case "$rel" in
    install.sh|update.sh|README.md|.gitignore|*.bak) continue ;;
  esac

  dst_file="$OPENCODE_HOME/$rel"
  if [[ ! -e "$dst_file" ]]; then
    to_add+=("$rel")
  elif ! cmp -s "$src_file" "$dst_file"; then
    to_change+=("$rel")
  fi
done < <(find "$HARNESS_SRC" -type f \
            -not -path "*/.git/*" \
            -print0)

# Arquivos no destino que não existem mais no source
while IFS= read -r -d '' dst_file; do
  rel="${dst_file#$OPENCODE_HOME/}"
  src_file="$HARNESS_SRC/$rel"
  if [[ ! -e "$src_file" ]]; then
    to_delete+=("$rel")
  fi
done < <(find "$OPENCODE_HOME/commands" \
          "$OPENCODE_HOME/agents" \
          "$OPENCODE_HOME/harness" \
          -type f -print0 2>/dev/null)

# -----------------------------------------------------------------------------
# Relatório de diff
# -----------------------------------------------------------------------------
printf "%b novos        : %d\n" "${C_GRN}+${C_RST}" "${#to_add[@]}"
printf "%b modificados  : %d\n" "${C_YLW}~${C_RST}" "${#to_change[@]}"
printf "%b removidos   : %d\n" "${C_RED}-${C_RST}" "${#to_delete[@]}"

if [[ ${#to_add[@]} -gt 0 ]]; then
  printf "\n${C_GRN}Novos:${C_RST}\n"
  for f in "${to_add[@]}"; do printf "  + %s\n" "$f"; done
fi

if [[ ${#to_change[@]} -gt 0 ]]; then
  printf "\n${C_YLW}Modificados:${C_RST}\n"
  for f in "${to_change[@]}"; do printf "  ~ %s\n" "$f"; done
fi

if [[ ${#to_delete[@]} -gt 0 ]]; then
  printf "\n${C_RED}Removidos (não serão apagados automaticamente):${C_RST}\n"
  for f in "${to_delete[@]}"; do printf "  - %s\n" "$f"; done
fi

if [[ ${#to_add[@]} -eq 0 && ${#to_change[@]} -eq 0 ]]; then
  ok "Nenhuma mudança necessária."
  exit 0
fi

if [[ "$DIFF_ONLY" == "true" ]]; then
  info "Modo --diff-only: nenhuma alteração aplicada."
  exit 0
fi

# -----------------------------------------------------------------------------
# Confirmação
# -----------------------------------------------------------------------------
if [[ -t 0 ]]; then
  printf "\n${C_YLW}?${C_RST} Aplicar atualizações? [s/N] "
  read -r response
  [[ "$response" =~ ^[sSyY]$ ]] || { info "Cancelado."; exit 0; }
fi

# -----------------------------------------------------------------------------
# Backup + apply
# -----------------------------------------------------------------------------
title "Aplicando atualizações"

BACKUP_DIR="$BACKUP_ROOT/$TIMESTAMP-pre-update"
mkdir -p "$BACKUP_DIR"

for f in "${to_change[@]}"; do
  src="$OPENCODE_HOME/$f"
  dst="$BACKUP_DIR/$f"
  mkdir -p "$(dirname "$dst")"
  cp -p "$src" "$dst"
done

for f in "${to_add[@]}" "${to_change[@]}"; do
  src="$HARNESS_SRC/$f"
  dst="$OPENCODE_HOME/$f"
  mkdir -p "$(dirname "$dst")"
  cp "$src" "$dst"
  printf "  ${C_DIM}•${C_RST} %s\n" "$f"
done

ok "Backup das versões anteriores em: $BACKUP_DIR"
ok "Atualização concluída."

printf "\n${C_DIM}Para ver os presets de modelo:${C_RST} ./update.sh --show-snippet\n"
printf "${C_DIM}Para inspecionar o backup:${C_RST}   ls $BACKUP_DIR\n"