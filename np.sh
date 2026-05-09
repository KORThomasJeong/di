#!/bin/bash
# ============================================================
# new-project.sh — AI-Augmented GitHub Project Scaffolder
# 사용법: ./new-project.sh <project-name> [node|python|fullstack]
# 설치:   cp new-project.sh ~/scripts/ && chmod +x ~/scripts/new-project.sh
# ============================================================

set -euo pipefail

# ── np update 서브커맨드 ───────────────────────────────────
if [ "${1:-}" = "update" ]; then
  echo "np 최신 버전으로 업데이트 중..."
  curl -fsSL https://raw.githubusercontent.com/KORThomasJeong/di/main/np.sh \
    -o "$0" && chmod +x "$0"
  echo "np 업데이트 완료"
  exit 0
fi

# ── 색상 ──────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

step()  { echo -e "\n${CYAN}${BOLD}▶ $1${RESET}"; }
ok()    { echo -e "  ${GREEN}✓${RESET} $1"; }
warn()  { echo -e "  ${YELLOW}⚠${RESET} $1"; }
fail()  { echo -e "  ${RED}✗ $1${RESET}"; exit 1; }
ask()   { echo -e "  ${BLUE}?${RESET} $1"; }

# ── 배너 ──────────────────────────────────────────────────
echo -e "${BOLD}${CYAN}"
echo "╔══════════════════════════════════════════╗"
echo "║  AI-Augmented Project Scaffolder  🤖     ║"
echo "╚══════════════════════════════════════════╝"
echo -e "${RESET}"

# ── 인자 파싱 ─────────────────────────────────────────────
PROJECT_NAME="${1:-}"
STACK="${2:-node}"
CREATE_GITHUB="${3:-ask}"   # yes | no | ask

if [ -z "$PROJECT_NAME" ]; then
  ask "프로젝트 이름을 입력하세요:"
  read -r PROJECT_NAME
fi

if [ -z "$PROJECT_NAME" ]; then
  fail "프로젝트 이름이 없습니다."
fi

ask "스택을 선택하세요 [node/python/fullstack] (기본: $STACK):"
read -r INPUT_STACK
STACK="${INPUT_STACK:-$STACK}"

# ── 프로젝트 경로 선택 ────────────────────────────────────
DEFAULT_DATE=$(date +%Y-%m)
# ~/project/ 안에서 이미 있는 날짜 기반 폴더 찾아 다음 번호 제안
if [ -d "$HOME/project" ]; then
  LAST_NUM=$(ls "$HOME/project" 2>/dev/null | grep -E '^[0-9]{4}-[0-9]{2}$' | sort | tail -1 || true)
  if [ -n "$LAST_NUM" ]; then
    LAST_YEAR=$(echo "$LAST_NUM" | cut -d'-' -f1)
    LAST_MONTH=$(echo "$LAST_NUM" | cut -d'-' -f2 | sed 's/^0//')
    NEXT_MONTH=$((LAST_MONTH + 1))
    if [ $NEXT_MONTH -gt 12 ]; then
      NEXT_MONTH=1
      LAST_YEAR=$((LAST_YEAR + 1))
    fi
    DEFAULT_DATE=$(printf "%d-%02d" "$LAST_YEAR" "$NEXT_MONTH")
  fi
fi

echo ""
echo -e "  ${BLUE}?${RESET} 프로젝트를 어디에 만들까요?"
echo -e "    ${BOLD}[1]${RESET} ~/project/$DEFAULT_DATE/$PROJECT_NAME  (날짜 기반, 기본값)"
echo -e "    ${BOLD}[2]${RESET} ~/project/<직접 입력>/$PROJECT_NAME"
echo -e "    ${BOLD}[3]${RESET} $(pwd)/$PROJECT_NAME  (현재 위치)"
printf "  선택 [1/2/3] (기본: 1): "
read -r PATH_CHOICE

case "${PATH_CHOICE:-1}" in
  2)
    printf "  하위 폴더 이름 입력 (~/project/ 기준): "
    read -r CUSTOM_SUBDIR
    PROJECT_DIR="$HOME/project/${CUSTOM_SUBDIR:-$DEFAULT_DATE}/$PROJECT_NAME"
    ;;
  3)
    PROJECT_DIR="$(pwd)/$PROJECT_NAME"
    ;;
  *)
    PROJECT_DIR="$HOME/project/$DEFAULT_DATE/$PROJECT_NAME"
    ;;
esac

# ── 중복 체크 ─────────────────────────────────────────────
if [ -d "$PROJECT_DIR" ]; then
  warn "$PROJECT_DIR 이미 존재합니다. 덮어쓰시겠습니까? [y/N]"
  read -r OVERWRITE
  [[ "$OVERWRITE" =~ ^[Yy]$ ]] || fail "중단합니다."
fi

# ── 변수 설정 ─────────────────────────────────────────────
OWNER=$(gh api user --jq .login 2>/dev/null || echo "your-username")
YEAR=$(date +%Y)

# ══════════════════════════════════════════════════════════
step "디렉토리 구조 생성"
# ══════════════════════════════════════════════════════════

mkdir -p "$PROJECT_DIR"/{.github/{workflows,ISSUE_TEMPLATE},.claude/commands,scripts,src,tests,docs}
cd "$PROJECT_DIR"
ok "디렉토리 구조 생성 완료"

# ── devcontainer 프롬프트 ──────────────────────────────────
printf "\n  devcontainer를 추가하시겠습니까? [y/N] "
read -r ADD_DEVCONTAINER
if [[ "${ADD_DEVCONTAINER:-}" =~ ^[Yy]$ ]]; then
  BASE="https://raw.githubusercontent.com/KORThomasJeong/di/main/templates/devcontainer"
  mkdir -p .devcontainer
  echo "  devcontainer 템플릿 다운로드 중 ($STACK)..."
  if curl -fsSL "$BASE/$STACK/devcontainer.json" -o .devcontainer/devcontainer.json 2>/dev/null; then
    ok ".devcontainer/devcontainer.json 생성"
  else
    warn "devcontainer.json 다운로드 실패 — 스택 '$STACK' 템플릿이 없을 수 있습니다"
  fi
  if [ "$STACK" = "fullstack" ]; then
    if curl -fsSL "$BASE/fullstack/docker-compose.yml" -o .devcontainer/docker-compose.yml 2>/dev/null; then
      ok ".devcontainer/docker-compose.yml 생성"
    else
      warn "docker-compose.yml 다운로드 실패"
    fi
  fi
  ok "devcontainer 설정 완료"
  DEVCONTAINER_ADDED=true
else
  DEVCONTAINER_ADDED=false
fi

# ══════════════════════════════════════════════════════════
step ".gitignore"
# ══════════════════════════════════════════════════════════

if [ "$STACK" = "node" ] || [ "$STACK" = "fullstack" ]; then
  cat > .gitignore << 'EOF'
# Node
node_modules/
dist/
build/
.next/
out/
coverage/
*.local

# Env
.env
.env.local
.env.*.local
*.key

# OS
.DS_Store
Thumbs.db
.idea/
.vscode/settings.json

# Logs
logs/
*.log
npm-debug.log*

# Claude loops
.claude-loops/
*.lock.tmp
EOF
fi

if [ "$STACK" = "python" ] || [ "$STACK" = "fullstack" ]; then
  cat >> .gitignore << 'EOF'

# Python
__pycache__/
*.py[cod]
*.egg-info/
.venv/
venv/
.pytest_cache/
htmlcov/
.coverage
dist/
*.egg
EOF
fi

cat >> .gitignore << 'EOF'

# Secrets
*.pem
*.p12
*.key
.anthropic_key
EOF

ok ".gitignore 생성"

# ══════════════════════════════════════════════════════════
step ".editorconfig"
# ══════════════════════════════════════════════════════════

cat > .editorconfig << 'EOF'
root = true

[*]
indent_style = space
indent_size = 2
end_of_line = lf
charset = utf-8
trim_trailing_whitespace = true
insert_final_newline = true

[*.{md,markdown}]
trim_trailing_whitespace = false

[Makefile]
indent_style = tab

[*.py]
indent_size = 4
EOF

ok ".editorconfig 생성"

# ══════════════════════════════════════════════════════════
step "README.md"
# ══════════════════════════════════════════════════════════

cat > README.md << EOF
# $PROJECT_NAME

> AI-Augmented 개발 워크플로우 기반 프로젝트

## Quick Start

\`\`\`bash
$([ "$STACK" != "python" ] && echo "npm install" || echo "pip install -r requirements.txt")
$([ "$STACK" != "python" ] && echo "npm run dev" || echo "uvicorn src.main:app --reload")
\`\`\`

## 개발 방법론

Claude Code + GitHub Actions + cron loops 기반으로 운영됩니다.

- **CI**: 모든 PR에 자동 lint/test/build/security 검사
- **AI 리뷰**: PR 생성 시 Claude가 자동 코드 리뷰
- **Loops**: cron으로 CI 자동 수정, 리뷰 응답, 일일 요약

## AI 명령어 (Claude Code)

\`\`\`
/issue <번호>   — 이슈 분석 후 작업 시작
/pr             — PR 생성 (설명 자동 작성)
/fix-ci         — CI 실패 자동 수정
/review         — 현재 변경사항 AI 리뷰
\`\`\`
EOF

ok "README.md 생성"

# ══════════════════════════════════════════════════════════
step "CLAUDE.md"
# ══════════════════════════════════════════════════════════

cat > CLAUDE.md << EOF
# $PROJECT_NAME — Claude Context

## 기술 스택
EOF

if [ "$STACK" = "node" ]; then
  cat >> CLAUDE.md << 'EOF'
- Runtime: Node.js 20
- 테스트: Vitest
- 린트: ESLint + Prettier
- 빌드: Vite
EOF
elif [ "$STACK" = "python" ]; then
  cat >> CLAUDE.md << 'EOF'
- Runtime: Python 3.12
- Framework: FastAPI
- 테스트: pytest + httpx
- 린트: ruff + mypy
EOF
elif [ "$STACK" = "fullstack" ]; then
  cat >> CLAUDE.md << 'EOF'
- Frontend: React 18 + Vite + TailwindCSS
- Backend: FastAPI + PostgreSQL
- 테스트: Vitest (FE), pytest (BE)
- 린트: ESLint + Prettier (FE), ruff + mypy (BE)
EOF
fi

cat >> CLAUDE.md << EOF

## 명령어
\`\`\`bash
$([ "$STACK" != "python" ] && echo -e "npm run dev      # 개발 서버\nnpm test         # 테스트\nnpm run lint     # 린트\nnpm run build    # 빌드" || echo -e "uvicorn src.main:app --reload  # 서버\npytest                         # 테스트\nruff check .                   # 린트\nmypy src/                      # 타입 체크")
\`\`\`

## 컨벤션
- 커밋: Conventional Commits (feat/fix/chore/docs/refactor/test/perf)
- 브랜치: \`feature/{issue-id}-{slug}\`, \`fix/{issue-id}-{slug}\`
- PR: 단일 책임 원칙, 200~400 LOC 권장
- 코드/주석: 영어, PR 설명: 한국어

## 디렉토리 규칙
- \`src/\`: 소스 코드
- \`tests/\`: 테스트 코드 (src 구조 미러링)
- \`scripts/\`: 자동화 스크립트 (cron 등)
- \`.github/workflows/\`: CI/CD 파이프라인

## 절대 하지 말 것
- main 브랜치에 직접 push
- 시크릿/API 키 하드코딩
- console.log 커밋 (디버그 후 제거)
- 테스트 없는 새 기능 PR

## AI 작업 지침
- 변경 전 항상 git status 확인
- 300줄 이상 변경 시 사용자 확인 후 진행
- 새 의존성 추가 전 기존 라이브러리 확인
- 실패하면 에러 로그 전체를 보고 원인 분석
EOF

ok "CLAUDE.md 생성"

# ══════════════════════════════════════════════════════════
step "Claude Code 설정"
# ══════════════════════════════════════════════════════════

cat > .claude/settings.json << 'EOF'
{
  "permissions": {
    "allow": [
      "Bash(npm:*)",
      "Bash(npx:*)",
      "Bash(git:*)",
      "Bash(gh:*)",
      "Bash(python:*)",
      "Bash(pytest:*)",
      "Bash(ruff:*)",
      "Edit",
      "Write",
      "Read"
    ],
    "deny": [
      "Bash(rm -rf /)",
      "Bash(curl * | bash)"
    ]
  }
}
EOF

# .claude/commands/issue.md
cat > .claude/commands/issue.md << 'EOF'
GitHub 이슈를 분석하고 작업을 시작합니다.

인자: $ARGUMENTS (이슈 번호)

다음 순서로 진행:
1. `gh issue view $ARGUMENTS`로 이슈 내용 전체 확인
2. Acceptance Criteria가 없으면 내용 기반으로 도출
3. 작업 브랜치 생성: `git checkout -b feature/$ARGUMENTS-{slug}`
   (slug는 이슈 제목 기반 kebab-case 3단어 이내)
4. 작업 계획을 목록으로 출력하고 사용자 확인 대기
5. 승인 후 구현 시작 (테스트 포함)
EOF

# .claude/commands/pr.md
cat > .claude/commands/pr.md << 'EOF'
현재 브랜치의 변경사항으로 Pull Request를 생성합니다.

다음 순서로 진행:
1. `git status`로 변경사항 확인
2. 스테이징되지 않은 파일이 있으면 확인 후 포함 여부 결정
3. `git log origin/main..HEAD`로 커밋 이력 확인
4. `git push -u origin HEAD` 실행
5. `gh pr create`로 PR 생성:
   - 제목: Conventional Commit 형식 (한국어)
   - 본문: PR 템플릿 기반, diff + 이슈 컨텍스트 자동 작성
   - 라벨 자동 태깅
6. PR URL 출력
EOF

# .claude/commands/fix-ci.md
cat > .claude/commands/fix-ci.md << 'EOF'
현재 브랜치 또는 지정한 PR의 CI 실패를 자동으로 수정합니다.

인자: $ARGUMENTS (PR 번호, 없으면 현재 브랜치)

다음 순서로 진행:
1. `gh pr checks` 로 실패한 체크 확인
2. `gh run view --log-failed` 로 실패 로그 전체 읽기
3. 로그를 분석하여 정확한 실패 원인 파악
4. 최소한의 코드 변경으로 수정
5. `git add` + `git commit -m "fix: ci 수정 내용"` + `git push`
6. CI 재실행 후 상태 리포트
EOF

# .claude/commands/review.md
cat > .claude/commands/review.md << 'EOF'
현재 변경사항을 AI가 코드 리뷰합니다.

다음 순서로 진행:
1. `git diff origin/main...HEAD` 로 전체 변경사항 확인
2. 다음 관점에서 검토:
   - 🔴 보안 취약점 (OWASP Top 10)
   - 🔴 버그 가능성 / 엣지 케이스 미처리
   - 🟡 코드 품질 / 중복 / 가독성
   - 🟡 테스트 누락 또는 불충분
   - 🟢 개선 제안 (선택적)
3. 마크다운 리포트 출력 (심각도 + 파일/줄번호 + 이유 + 수정 예시)
4. 수정할 항목이 있으면 동의 후 직접 수정 여부 묻기
EOF

ok "Claude Code 설정 파일 생성"

# ══════════════════════════════════════════════════════════
step "lefthook.yml (Git Hooks)"
# ══════════════════════════════════════════════════════════

if [ "$STACK" = "node" ] || [ "$STACK" = "fullstack" ]; then
  cat > lefthook.yml << 'EOF'
pre-commit:
  parallel: true
  commands:
    lint:
      glob: "*.{js,ts,tsx,jsx}"
      run: npx eslint {staged_files} --max-warnings 0
    format:
      glob: "*.{js,ts,tsx,json,md}"
      run: npx prettier --check {staged_files}
    typecheck:
      glob: "*.{ts,tsx}"
      run: npx tsc --noEmit

prepare-commit-msg:
  commands:
    ai-message:
      run: |
        # 커밋 메시지가 비어있을 때만 AI로 생성
        if [ -z "$(cat {1})" ] && command -v claude &> /dev/null; then
          DIFF=$(git diff --cached)
          claude -p "다음 git diff를 보고 Conventional Commit 메시지를 한 줄로 작성해라. 형식: type: 설명 (한국어). 출력은 메시지만.
$DIFF" > {1} 2>/dev/null || true
        fi

pre-push:
  commands:
    test:
      run: npm test -- --run
EOF
fi

if [ "$STACK" = "python" ]; then
  cat > lefthook.yml << 'EOF'
pre-commit:
  parallel: true
  commands:
    ruff:
      glob: "*.py"
      run: ruff check {staged_files}
    format:
      glob: "*.py"
      run: ruff format --check {staged_files}
    mypy:
      glob: "*.py"
      run: mypy {staged_files} --ignore-missing-imports

prepare-commit-msg:
  commands:
    ai-message:
      run: |
        if [ -z "$(cat {1})" ] && command -v claude &> /dev/null; then
          DIFF=$(git diff --cached)
          claude -p "다음 git diff를 보고 Conventional Commit 메시지를 한 줄로 작성해라. 형식: type: 설명 (한국어). 출력은 메시지만.
$DIFF" > {1} 2>/dev/null || true
        fi

pre-push:
  commands:
    test:
      run: pytest tests/ -q
EOF
fi

ok "lefthook.yml 생성"

# ══════════════════════════════════════════════════════════
step "GitHub Actions Workflows"
# ══════════════════════════════════════════════════════════

# ci.yml
if [ "$STACK" = "node" ]; then
  cat > .github/workflows/ci.yml << 'EOF'
name: CI

on:
  pull_request:
    branches: [main]
  push:
    branches: [main]

jobs:
  lint:
    name: ci/lint
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: 20, cache: npm }
      - run: npm ci
      - run: npm run lint

  typecheck:
    name: ci/typecheck
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: 20, cache: npm }
      - run: npm ci
      - run: npx tsc --noEmit

  test:
    name: ci/test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: 20, cache: npm }
      - run: npm ci
      - run: npm test -- --coverage

  build:
    name: ci/build
    runs-on: ubuntu-latest
    needs: [lint, typecheck, test]
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: 20, cache: npm }
      - run: npm ci
      - run: npm run build

  security:
    name: ci/security
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: aquasecurity/trivy-action@master
        with:
          scan-type: fs
          severity: HIGH,CRITICAL
      - uses: gitleaks/gitleaks-action@v2
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
EOF

elif [ "$STACK" = "python" ]; then
  cat > .github/workflows/ci.yml << 'EOF'
name: CI

on:
  pull_request:
    branches: [main]
  push:
    branches: [main]

jobs:
  lint:
    name: ci/lint
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with: { python-version: "3.12" }
      - run: pip install ruff mypy
      - run: ruff check .
      - run: ruff format --check .
      - run: mypy src/ --ignore-missing-imports

  test:
    name: ci/test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with: { python-version: "3.12" }
      - run: pip install -r requirements.txt -r requirements-dev.txt
      - run: pytest tests/ --cov=src --cov-report=xml -q

  security:
    name: ci/security
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: aquasecurity/trivy-action@master
        with: { scan-type: fs, severity: HIGH,CRITICAL }
      - uses: gitleaks/gitleaks-action@v2
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
EOF

elif [ "$STACK" = "fullstack" ]; then
  cat > .github/workflows/ci.yml << 'EOF'
name: CI

on:
  pull_request:
    branches: [main]
  push:
    branches: [main]

jobs:
  frontend-lint:
    name: ci/frontend-lint
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: 20, cache: npm }
      - run: npm ci
      - run: npm run lint
      - run: npx tsc --noEmit

  frontend-test:
    name: ci/frontend-test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: 20, cache: npm }
      - run: npm ci
      - run: npm test -- --coverage

  backend-lint:
    name: ci/backend-lint
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with: { python-version: "3.12" }
      - run: pip install ruff mypy
      - run: ruff check src/
      - run: mypy src/ --ignore-missing-imports

  backend-test:
    name: ci/backend-test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with: { python-version: "3.12" }
      - run: pip install -r requirements.txt -r requirements-dev.txt
      - run: pytest tests/ -q

  security:
    name: ci/security
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: aquasecurity/trivy-action@master
        with: { scan-type: fs, severity: HIGH,CRITICAL }
      - uses: gitleaks/gitleaks-action@v2
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
EOF
fi

ok "ci.yml 생성 ($STACK)"

# ai-review.yml
cat > .github/workflows/ai-review.yml << 'EOF'
name: AI Code Review

on:
  pull_request:
    types: [opened, synchronize]

jobs:
  ai-review:
    runs-on: ubuntu-latest
    permissions:
      pull-requests: write
      contents: read
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Get PR diff
        id: diff
        run: |
          git diff origin/${{ github.base_ref }}...HEAD > pr.diff
          LINES=$(wc -l < pr.diff)
          echo "lines=$LINES" >> $GITHUB_OUTPUT
          echo "PR diff: $LINES lines"

      - name: Skip if empty
        if: steps.diff.outputs.lines == '0'
        run: echo "No changes to review" && exit 0

      - name: Claude AI Review
        if: steps.diff.outputs.lines != '0'
        env:
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
        run: |
          DIFF=$(cat pr.diff)
          npx @anthropic-ai/claude-code -p "
          다음 PR diff를 시니어 개발자 관점에서 리뷰해라.

          검토 항목:
          🔴 보안: 시크릿 노출, SQL 인젝션, XSS, 인증 취약점
          🔴 버그: NPE, 범위 오류, 경쟁 조건, 미처리 예외
          🟡 품질: 중복 코드, 긴 함수, 명확하지 않은 네이밍
          🟡 테스트: 테스트 누락, 불충분한 엣지 케이스
          🟢 제안: 성능, 가독성 개선 (선택)

          출력 형식:
          ## AI Review
          
          ### 🔴 Critical
          - 파일명:줄번호 — 문제 설명 / 수정 방법
          
          ### 🟡 Warning  
          - 파일명:줄번호 — 문제 설명
          
          ### 🟢 Suggestion
          - 파일명:줄번호 — 제안

          ### 총평
          전반적인 코드 품질 평가 1-2줄

          ---
          DIFF:
          $DIFF
          " > review.md 2>/dev/null

      - name: Post Review Comment
        if: steps.diff.outputs.lines != '0'
        uses: actions/github-script@v7
        with:
          script: |
            const fs = require('fs');
            const review = fs.readFileSync('review.md', 'utf8');
            await github.rest.issues.createComment({
              owner: context.repo.owner,
              repo: context.repo.repo,
              issue_number: context.issue.number,
              body: `> 🤖 **Claude AI Review** — 자동 분석 결과입니다. Human review와 병행 사용하세요.\n\n${review}`
            });
EOF

ok "ai-review.yml 생성"

# auto-fix.yml
cat > .github/workflows/auto-fix.yml << 'EOF'
name: Auto Fix CI

on:
  workflow_dispatch:
    inputs:
      pr_number:
        description: 'PR number to fix'
        required: true
        type: number

jobs:
  fix:
    runs-on: ubuntu-latest
    permissions:
      contents: write
      pull-requests: write
    steps:
      - uses: actions/checkout@v4

      - name: Checkout PR branch
        run: gh pr checkout ${{ inputs.pr_number }}
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}

      - name: Get failed logs
        run: |
          gh pr checks ${{ inputs.pr_number }} --json name,conclusion,link \
            --jq '.[] | select(.conclusion == "FAILURE") | .link' \
            | head -5 > failed_runs.txt
          cat failed_runs.txt
          for URL in $(cat failed_runs.txt); do
            RUN_ID=$(echo $URL | grep -oE '[0-9]+$')
            gh run view $RUN_ID --log-failed >> failed.log 2>&1 || true
          done
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}

      - name: Claude Auto Fix
        env:
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        run: |
          LOG=$(cat failed.log 2>/dev/null || echo "로그 없음")
          npx @anthropic-ai/claude-code -p "
          CI가 실패했다. 로그를 보고 원인을 찾아 코드를 수정해라.
          수정 후 반드시: git add -A && git commit -m 'fix: ci 자동 수정' && git push
          push 이외의 다른 작업(gh pr comment 등)은 하지 마라.
          
          실패 로그:
          $LOG
          " --auto

      - name: Report Result
        if: always()
        run: |
          gh pr comment ${{ inputs.pr_number }} --body "🤖 Auto-fix 실행 완료. CI 재확인해주세요."
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
EOF

ok "auto-fix.yml 생성"

# release.yml
cat > .github/workflows/release.yml << 'EOF'
name: Release

on:
  push:
    branches: [main]

permissions:
  contents: write
  pull-requests: write

jobs:
  release-please:
    runs-on: ubuntu-latest
    steps:
      - uses: googleapis/release-please-action@v4
        with:
          release-type: node
EOF

ok "release.yml 생성"

# scheduled-loops.yml
cat > .github/workflows/scheduled-loops.yml << 'EOF'
name: Scheduled AI Loops

on:
  schedule:
    - cron: '*/30 * * * *'   # 30분마다 CI 수정
    - cron: '0 8 * * *'      # 매일 오전 8시 요약
  workflow_dispatch:

jobs:
  fix-failing-prs:
    runs-on: ubuntu-latest
    permissions:
      contents: write
      pull-requests: write
    steps:
      - uses: actions/checkout@v4

      - name: Find my failing PRs
        id: find
        run: |
          PRS=$(gh pr list --state open \
            --json number,statusCheckRollup \
            --jq '[.[] | select(
              .statusCheckRollup != null and
              (.statusCheckRollup[] | .conclusion == "FAILURE")
            ) | .number] | unique | join(",")' 2>/dev/null || echo "")
          echo "prs=${PRS}" >> $GITHUB_OUTPUT
          echo "Failing PRs: ${PRS:-none}"
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}

      - name: Auto-fix each failing PR
        if: steps.find.outputs.prs != ''
        env:
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        run: |
          IFS=',' read -ra PR_LIST <<< "${{ steps.find.outputs.prs }}"
          for PR in "${PR_LIST[@]}"; do
            echo "Fixing PR #$PR ..."
            gh pr checkout "$PR"
            git pull --rebase origin main || continue
            gh run list --limit 5 --json databaseId,conclusion \
              --jq '.[] | select(.conclusion == "failure") | .databaseId' \
              | head -1 | xargs -I{} gh run view {} --log-failed > failed.log 2>&1 || true
            npx @anthropic-ai/claude-code -p "
            PR #$PR CI 실패. 로그를 보고 최소한의 수정 후 commit, push까지 실행.
            로그: $(cat failed.log)
            " --auto || true
          done
EOF

ok "scheduled-loops.yml 생성"

# ══════════════════════════════════════════════════════════
step "GitHub 설정 파일"
# ══════════════════════════════════════════════════════════

# PR 템플릿
cat > .github/PULL_REQUEST_TEMPLATE.md << 'EOF'
## 변경 사항
<!-- 무엇을, 왜 변경했는지 명확하게 작성 -->

## 관련 이슈
Closes #

## 변경 유형
- [ ] 새 기능 (feat)
- [ ] 버그 수정 (fix)
- [ ] 리팩토링 (refactor)
- [ ] 문서 (docs)
- [ ] 기타 (chore)

## 체크리스트
- [ ] 테스트 추가/수정 완료
- [ ] 로컬에서 테스트 통과 확인
- [ ] self-review 완료
- [ ] 문서 업데이트 (해당 시)

## 스크린샷 (UI 변경 시)
EOF

# CODEOWNERS
cat > .github/CODEOWNERS << EOF
# 기본 리뷰어
*                   @$OWNER

# 워크플로우 변경은 추가 확인
/.github/workflows/ @$OWNER
EOF

# release-please 설정
cat > .release-please-config.json << 'EOF'
{
  "release-type": "node",
  "packages": {
    ".": {
      "changelog-sections": [
        { "type": "feat",     "section": "✨ Features"         },
        { "type": "fix",      "section": "🐛 Bug Fixes"        },
        { "type": "perf",     "section": "⚡ Performance"      },
        { "type": "docs",     "section": "📚 Documentation"    },
        { "type": "refactor", "section": "♻️ Refactoring"     }
      ]
    }
  }
}
EOF

ok "GitHub 설정 파일 생성"

# ══════════════════════════════════════════════════════════
step "cron 스크립트 생성"
# ══════════════════════════════════════════════════════════

# cron-fix-ci.sh
cat > scripts/cron-fix-ci.sh << SCRIPT
#!/bin/bash
# 30분마다: 내 PR 중 CI 실패한 것 자동 수정
set -euo pipefail

export PATH="/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:\$PATH"
[ -f "\$HOME/.anthropic_key" ] && export ANTHROPIC_API_KEY="\$(cat \$HOME/.anthropic_key)"

PROJECT_ROOT="\$(cd "\$(dirname "\${BASH_SOURCE[0]}")/.." && pwd)"
LOG_DIR="\$HOME/.claude-loops/logs"
LOG="\$LOG_DIR/fix-ci-\$(date +%Y%m%d).log"
LOCK="/tmp/cron-fix-ci.lock"

mkdir -p "\$LOG_DIR"

# 중복 실행 방지
[ -f "\$LOCK" ] && exit 0
trap "rm -f \$LOCK" EXIT
touch "\$LOCK"

cd "\$PROJECT_ROOT"
echo "[\$(date '+%H:%M')] CI 수정 루프 시작" >> "\$LOG"

# 내가 작성한 open PR 중 CI 실패
FAILED_PRS=\$(gh pr list --author "@me" --state open \\
  --json number,statusCheckRollup \\
  --jq '[.[] | select(
    .statusCheckRollup != null and
    (.statusCheckRollup[] | .conclusion == "FAILURE")
  ) | .number] | unique | .[]' 2>/dev/null || echo "")

if [ -z "\$FAILED_PRS" ]; then
  echo "[\$(date '+%H:%M')] 실패한 PR 없음" >> "\$LOG"
  exit 0
fi

for PR in \$FAILED_PRS; do
  echo "[\$(date '+%H:%M')] PR #\$PR 수정 시작" >> "\$LOG"

  gh pr checkout "\$PR" 2>/dev/null || { echo "  체크아웃 실패" >> "\$LOG"; continue; }
  git pull --rebase origin main 2>/dev/null || true

  # 실패 로그 수집
  gh run list --limit 5 --json databaseId,conclusion \\
    --jq '.[] | select(.conclusion == "failure") | .databaseId' \\
    | head -1 | xargs -I{} gh run view {} --log-failed > /tmp/ci-failed.log 2>&1 || true

  claude -p "
PR #\$PR 의 CI가 실패했다.
실패 로그: \$(cat /tmp/ci-failed.log | head -100)
원인을 분석하고 코드를 수정한 뒤 git add, commit, push까지 실행해라.
커밋 메시지 형식: fix: ci 수정 - {수정 내용 한 줄}
" --dangerously-skip-permissions >> "\$LOG" 2>&1 || true

  echo "[\$(date '+%H:%M')] PR #\$PR 완료" >> "\$LOG"
done

echo "[\$(date '+%H:%M')] 루프 종료" >> "\$LOG"
SCRIPT

# cron-respond-reviews.sh
cat > scripts/cron-respond-reviews.sh << SCRIPT
#!/bin/bash
# 15분마다: 내 PR 리뷰 코멘트 자동 응답
set -euo pipefail

export PATH="/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:\$PATH"
[ -f "\$HOME/.anthropic_key" ] && export ANTHROPIC_API_KEY="\$(cat \$HOME/.anthropic_key)"

PROJECT_ROOT="\$(cd "\$(dirname "\${BASH_SOURCE[0]}")/.." && pwd)"
LOG="\$HOME/.claude-loops/logs/reviews-\$(date +%Y%m%d).log"
LOCK="/tmp/cron-reviews.lock"

[ -f "\$LOCK" ] && exit 0
trap "rm -f \$LOCK" EXIT
touch "\$LOCK"

mkdir -p "\$(dirname \$LOG)"
cd "\$PROJECT_ROOT"

gh pr list --author "@me" --state open --json number --jq '.[].number' | while read -r PR; do
  REQUESTED=\$(gh pr view "\$PR" --json reviews \\
    --jq '.reviews[] | select(.state=="CHANGES_REQUESTED") | .state' 2>/dev/null || echo "")

  if [ -n "\$REQUESTED" ]; then
    echo "[\$(date '+%H:%M')] PR #\$PR 리뷰 응답 시작" >> "\$LOG"
    gh pr checkout "\$PR" 2>/dev/null || continue

    COMMENTS=\$(gh pr view "\$PR" --comments --json comments \\
      --jq '.comments[] | "[\(.author.login)]: \(.body)"' 2>/dev/null | tail -20)

    claude -p "
PR #\$PR 에 변경 요청 리뷰가 있다.
다음 코멘트를 읽고:
1. 코드 수정이 필요하면 수정 후 commit + push
2. 설명이 필요하면 gh pr comment \$PR --body '답변' 으로 응답
3. 수정 완료 후 gh pr review \$PR --approve 는 하지 마라 (사람이 한다)

리뷰 코멘트:
\$COMMENTS
" --dangerously-skip-permissions >> "\$LOG" 2>&1 || true
  fi
done
SCRIPT

# cron-daily-summary.sh
cat > scripts/cron-daily-summary.sh << SCRIPT
#!/bin/bash
# 매일 오전 8시: 일일 개발 요약 생성
set -euo pipefail

export PATH="/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:\$PATH"
[ -f "\$HOME/.anthropic_key" ] && export ANTHROPIC_API_KEY="\$(cat \$HOME/.anthropic_key)"

PROJECT_ROOT="\$(cd "\$(dirname "\${BASH_SOURCE[0]}")/.." && pwd)"
cd "\$PROJECT_ROOT"

YESTERDAY=\$(date -v-1d +%Y-%m-%d 2>/dev/null || date -d yesterday +%Y-%m-%d)

MERGED=\$(gh pr list --state merged --search "merged:>\$YESTERDAY" \\
  --json number,title --jq '.[] | "- PR #\(.number): \(.title)"' 2>/dev/null | head -10)

CLOSED_ISSUES=\$(gh issue list --state closed --search "closed:>\$YESTERDAY" \\
  --json number,title --jq '.[] | "- Issue #\(.number): \(.title)"' 2>/dev/null | head -10)

OPEN_PRS=\$(gh pr list --state open --author "@me" \\
  --json number,title,isDraft --jq '.[] | "- PR #\(.number)\(if .isDraft then " [Draft]" else "" end): \(.title)"' 2>/dev/null)

SUMMARY=\$(claude -p "
다음 GitHub 활동을 기반으로 일일 개발 요약을 한국어 마크다운으로 작성해라.
날짜: \$YESTERDAY

머지된 PR:
\${MERGED:-없음}

클로즈된 이슈:
\${CLOSED_ISSUES:-없음}

현재 진행중 PR:
\${OPEN_PRS:-없음}

형식:
## 📊 \$YESTERDAY 개발 요약
### ✅ 완료
### 🚧 진행중
### 📌 내일 할 일 (진행중 PR 기반 추론)
" 2>/dev/null)

echo "\$SUMMARY"

# Slack 알림 (SLACK_WEBHOOK_URL 환경변수 설정 시)
if [ -n "\${SLACK_WEBHOOK_URL:-}" ]; then
  curl -sf -X POST "\$SLACK_WEBHOOK_URL" \\
    -H 'Content-Type: application/json' \\
    -d "{\"text\": \"\$SUMMARY\"}" || true
fi
SCRIPT

# cron-health.sh
cat > scripts/cron-health.sh << SCRIPT
#!/bin/bash
# 5분마다: 프로덕션 헬스체크
set -euo pipefail

export PATH="/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:\$PATH"
[ -f "\$HOME/.anthropic_key" ] && export ANTHROPIC_API_KEY="\$(cat \$HOME/.anthropic_key)"

HEALTH_URL="\${HEALTH_CHECK_URL:-https://localhost:3000/health}"
PROJECT_ROOT="\$(cd "\$(dirname "\${BASH_SOURCE[0]}")/.." && pwd)"

STATUS=\$(curl -sf --max-time 10 "\$HEALTH_URL" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('status','unknown'))" 2>/dev/null || echo "failed")

if [ "\$STATUS" != "ok" ]; then
  cd "\$PROJECT_ROOT"
  claude -p "
  Production health check 실패 (status=\$STATUS, url=\$HEALTH_URL)
  다음을 수행:
  1. 최근 배포 이력 확인 (gh release list --limit 3)
  2. 최근 머지된 PR 확인
  3. 문제 원인 가설 작성
  4. 핫픽스 이슈 생성: gh issue create --title 'hotfix: health check 실패' --label bug
  5. Slack 알림이 필요하면 지시하라 (직접 실행 말고)
  " --dangerously-skip-permissions || true
fi
SCRIPT

chmod +x scripts/*.sh
ok "cron 스크립트 생성 + 실행권한 부여"

# ══════════════════════════════════════════════════════════
step "crontab 설치 스크립트"
# ══════════════════════════════════════════════════════════

cat > scripts/install-crontab.sh << SCRIPT
#!/bin/bash
# crontab 자동 등록 스크립트
set -euo pipefail

PROJECT_ROOT="\$(cd "\$(dirname "\${BASH_SOURCE[0]}")/.." && pwd)"

# 기존 crontab 백업
crontab -l > /tmp/crontab.bak 2>/dev/null || true

# 중복 방지
crontab -l 2>/dev/null | grep -v "claude-loops\|new-project-cron" > /tmp/crontab.tmp || true

cat >> /tmp/crontab.tmp << CRON
# === AI Dev Loops: \$PROJECT_ROOT ===
PATH=/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin
*/30 * * * * \$PROJECT_ROOT/scripts/cron-fix-ci.sh
*/15 * * * * \$PROJECT_ROOT/scripts/cron-respond-reviews.sh
0 8 * * * \$PROJECT_ROOT/scripts/cron-daily-summary.sh
*/5 * * * * \$PROJECT_ROOT/scripts/cron-health.sh
CRON

crontab /tmp/crontab.tmp
echo "✓ crontab 등록 완료. 확인: crontab -l"
SCRIPT

chmod +x scripts/install-crontab.sh
ok "install-crontab.sh 생성"

# ══════════════════════════════════════════════════════════
step "스택별 초기 파일"
# ══════════════════════════════════════════════════════════

if [ "$STACK" = "node" ] || [ "$STACK" = "fullstack" ]; then
  cat > package.json << EOF
{
  "name": "$PROJECT_NAME",
  "version": "0.1.0",
  "scripts": {
    "dev": "vite",
    "build": "vite build",
    "test": "vitest",
    "lint": "eslint . --max-warnings 0",
    "format": "prettier --write ."
  }
}
EOF
fi

if [ "$STACK" = "python" ] || [ "$STACK" = "fullstack" ]; then
  touch requirements.txt requirements-dev.txt
  cat > requirements-dev.txt << 'EOF'
pytest
pytest-cov
httpx
ruff
mypy
EOF
fi

# src 및 tests 플레이스홀더
touch src/.gitkeep tests/.gitkeep docs/.gitkeep

ok "스택별 초기 파일 생성"

# ══════════════════════════════════════════════════════════
step "Git 초기화"
# ══════════════════════════════════════════════════════════

git init -b main
git add .
git commit -m "chore: initial project scaffold (AI-Augmented)"
ok "git init + 첫 커밋 완료"

# ══════════════════════════════════════════════════════════
step "GitHub 저장소 생성 (선택)"
# ══════════════════════════════════════════════════════════

if [ "$CREATE_GITHUB" = "yes" ]; then
  gh repo create "$PROJECT_NAME" --public --source=. --remote=origin --push
  ok "GitHub 저장소 생성 + push 완료"
elif [ "$CREATE_GITHUB" = "ask" ]; then
  warn "GitHub 저장소를 생성하시겠습니까? [y/N]"
  read -r DO_GITHUB
  if [[ "$DO_GITHUB" =~ ^[Yy]$ ]]; then
    warn "공개(public) / 비공개(private)? [pub/pri]"
    read -r VISIBILITY
    if [[ "$VISIBILITY" =~ ^pri ]]; then
      gh repo create "$PROJECT_NAME" --private --source=. --remote=origin --push
    else
      gh repo create "$PROJECT_NAME" --public --source=. --remote=origin --push
    fi
    ok "GitHub 저장소 생성 + push 완료"
  fi
fi

# ══════════════════════════════════════════════════════════
step "lefthook 설치 (선택)"
# ══════════════════════════════════════════════════════════

if command -v lefthook &> /dev/null; then
  lefthook install
  ok "lefthook 훅 설치 완료"
else
  warn "lefthook 미설치. 설치 후 lefthook install 실행하세요."
  OS="$(uname -s)"
  if [ "$OS" = "Darwin" ]; then
    warn "  macOS:  brew install lefthook"
  elif [ "$OS" = "Linux" ]; then
    warn "  Linux:  curl -fsSL https://raw.githubusercontent.com/evilmartians/lefthook/master/install.sh | bash"
    warn "  또는:   npm install -g lefthook"
  fi
fi

# ══════════════════════════════════════════════════════════
step "crontab 등록 (선택)"
# ══════════════════════════════════════════════════════════

warn "AI loop crontab을 등록하시겠습니까? [y/N]"
read -r DO_CRON
if [[ "$DO_CRON" =~ ^[Yy]$ ]]; then
  bash "$PROJECT_DIR/scripts/install-crontab.sh"
fi

# ══════════════════════════════════════════════════════════
echo -e "\n${BOLD}${GREEN}✅ 프로젝트 생성 완료!${RESET}\n"
echo -e "${BOLD}📁 위치:${RESET} $PROJECT_DIR"
echo -e "${BOLD}🛠 스택:${RESET} $STACK"
echo ""
echo -e "${BOLD}다음 단계:${RESET}"
echo "  cd $PROJECT_DIR"
echo "  claude                    # Claude Code 시작"
echo "  /issue <번호>             # 이슈 기반 작업 시작"
echo ""
if [ "${DEVCONTAINER_ADDED:-false}" = "true" ]; then
  echo -e "${BOLD}devcontainer 사용법:${RESET}"
  echo "  code .                    # VS Code로 열기"
  echo "  → 우하단 알림 또는 명령팔레트: 'Reopen in Container'"
  echo "  → Docker Desktop이 실행 중이어야 합니다"
  echo ""
fi
echo -e "${BOLD}cron 로그 확인:${RESET}"
echo "  tail -f ~/.claude-loops/logs/fix-ci-$(date +%Y%m%d).log"
echo ""
echo -e "${BOLD}Branch protection 설정 (필수):${RESET}"
echo "  GitHub → Settings → Branches → Add rule"
echo "    ✅ Require PR, ✅ CI checks, ✅ Up to date"
echo ""