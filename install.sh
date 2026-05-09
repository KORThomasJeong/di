#!/bin/bash
# ============================================================
# install.sh — np 글로벌 설치 스크립트
# 사용법: curl -fsSL https://raw.githubusercontent.com/KORThomasJeong/di/main/install.sh | bash
# ============================================================

set -euo pipefail

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

ok()   { echo -e "  ${GREEN}✓${RESET} $1"; }
warn() { echo -e "  ${YELLOW}⚠${RESET} $1"; }
info() { echo -e "  ${CYAN}▶${RESET} $1"; }

echo -e "${BOLD}${CYAN}"
echo "╔══════════════════════════════════════════╗"
echo "║      np (new-project) 설치 시작 🚀       ║"
echo "╚══════════════════════════════════════════╝"
echo -e "${RESET}"

RAW_URL="https://raw.githubusercontent.com/KORThomasJeong/di/main/np.sh"
BIN_DIR="$HOME/.local/bin"
NP_PATH="$BIN_DIR/np"

# ── ~/.local/bin 디렉터리 생성 ─────────────────────────────
info "~/.local/bin 디렉터리 준비 중..."
mkdir -p "$BIN_DIR"
ok "디렉터리 준비 완료: $BIN_DIR"

# ── np.sh 다운로드 ─────────────────────────────────────────
info "np.sh 다운로드 중 (GitHub)..."
curl -fsSL "$RAW_URL" -o "$NP_PATH"
chmod +x "$NP_PATH"
ok "np 설치 완료: $NP_PATH"

# ── ~/project/ 디렉터리 생성 ───────────────────────────────
if [ ! -d "$HOME/project" ]; then
  mkdir -p "$HOME/project"
  ok "~/project 디렉터리 생성"
else
  ok "~/project 디렉터리 이미 존재"
fi

# ── PATH 등록 ──────────────────────────────────────────────
PATH_LINE='export PATH="$HOME/.local/bin:$PATH"'

add_path_to_file() {
  local rc_file="$1"
  if [ -f "$rc_file" ]; then
    if grep -q '\.local/bin' "$rc_file" 2>/dev/null; then
      warn "$rc_file — PATH 이미 등록됨, 건너뜀"
    else
      echo "" >> "$rc_file"
      echo "# np (new-project) 글로벌 경로" >> "$rc_file"
      echo "$PATH_LINE" >> "$rc_file"
      ok "$rc_file 에 PATH 추가"
    fi
  fi
}

add_path_to_file "$HOME/.bashrc"
add_path_to_file "$HOME/.zshrc"

# 현재 세션에도 즉시 적용
export PATH="$BIN_DIR:$PATH"

# ── lefthook 설치 안내 ─────────────────────────────────────
OS="$(uname -s)"
if command -v lefthook &> /dev/null; then
  ok "lefthook 이미 설치됨"
else
  warn "lefthook 미설치 (Git hooks 사용 시 필요)"
  if [ "$OS" = "Darwin" ]; then
    warn "  설치:  brew install lefthook"
  elif [ "$OS" = "Linux" ]; then
    warn "  설치 (curl):  curl -fsSL https://raw.githubusercontent.com/evilmartians/lefthook/master/install.sh | bash"
    warn "  설치 (npm):   npm install -g lefthook"
  fi
fi

echo ""
echo -e "${BOLD}${GREEN}✅ 설치 완료!${RESET}"
echo ""
echo "  새 터미널을 열거나 다음을 실행하세요:"
echo -e "    ${CYAN}source ~/.bashrc${RESET}  (또는 ~/.zshrc)"
echo ""
echo "  사용법:"
echo -e "    ${CYAN}np${RESET}                  # 새 프로젝트 생성"
echo -e "    ${CYAN}np update${RESET}            # np 최신 버전으로 업데이트"
echo ""
