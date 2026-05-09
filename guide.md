# np (new-project) 가이드

AI-Augmented 프로젝트를 한 명령어로 스캐폴딩합니다.

---

## 설치

```bash
curl -fsSL https://raw.githubusercontent.com/KORThomasJeong/di/main/install.sh | bash
```

설치 후 새 터미널을 열거나 다음을 실행:

```bash
source ~/.bashrc   # 또는 source ~/.zshrc
```

이후부터는 어디서든 `np` 명령으로 사용 가능합니다.

---

## 사용법

```
np [프로젝트이름] [node|python|fullstack]
```

**예시:**
- `np my-api python`
- `np dashboard fullstack`
- `np landing-page node`
- `np` (인자 없이 실행 → 인터랙티브 프롬프트)

---

## 업데이트

```bash
np update
```

GitHub 최신 버전을 자동으로 내려받아 교체합니다.

---

## 실행 흐름

### 1. 프로젝트 이름 & 스택 입력

인터랙티브 프롬프트로 이름과 스택(`node` / `python` / `fullstack`)을 선택합니다.

### 2. 프로젝트 경로 선택

```
[1] ~/project/2026-05  (날짜 기반 자동 생성)  ← 기본값
[2] ~/project/<직접 입력>
[3] 현재 위치 (pwd)
```

- 옵션 1: `YYYY-MM` 포맷으로 `~/project/` 안에 폴더를 자동 생성합니다.
  이미 `2026-01`이 있으면 `2026-02`를 제안합니다.

### 3. devcontainer 추가 여부

```
devcontainer를 추가하시겠습니까? [y/N]
```

`y` 선택 시 GitHub raw URL에서 스택에 맞는 템플릿을 실시간으로 내려받아
`.devcontainer/` 폴더를 생성합니다.

| 스택 | 생성 파일 |
|------|-----------|
| `node` | `.devcontainer/devcontainer.json` |
| `python` | `.devcontainer/devcontainer.json` |
| `fullstack` | `.devcontainer/devcontainer.json` + `.devcontainer/docker-compose.yml` |

완료 후 VS Code에서 `code .` → **"Reopen in Container"** 를 선택하면 됩니다.

### 4. GitHub 저장소 생성 (선택)

`gh` CLI가 설치되어 있으면 GitHub 저장소를 즉시 생성하고 push합니다.

---

## devcontainer 스택 구성

### fullstack

| 서비스 | 포트 | 설명 |
|--------|------|------|
| app (node:22) | 3000, 4000 | Next.js + Express/API |
| db (postgres:16) | 5432 | PostgreSQL |
| adminer | 8080 | DB 관리 UI |

VS Code 확장: ESLint, Prettier, Tailwind CSS, Prisma, SQLTools, Pylance, Ruff

### node

| 포트 | 설명 |
|------|------|
| 3000 | Dev Server |
| 4000 | API Server |

VS Code 확장: ESLint, Prettier, Tailwind CSS, GitLens

### python

| 포트 | 설명 |
|------|------|
| 8000 | FastAPI / Dev Server |

VS Code 확장: Pylance, Ruff, Black, isort

---

## 생성 결과 구조

```
<프로젝트명>/
├── .claude/
│   ├── commands/          # /issue, /pr, /fix-ci, /review
│   └── settings.json
├── .devcontainer/         # devcontainer 선택 시
│   ├── devcontainer.json
│   └── docker-compose.yml (fullstack만)
├── .github/
│   ├── workflows/
│   │   ├── ci.yml
│   │   ├── ai-review.yml
│   │   ├── auto-fix.yml
│   │   ├── release.yml
│   │   └── scheduled-loops.yml
│   ├── ISSUE_TEMPLATE/
│   ├── PULL_REQUEST_TEMPLATE.md
│   └── CODEOWNERS
├── scripts/
│   ├── cron-fix-ci.sh
│   ├── cron-respond-reviews.sh
│   ├── cron-daily-summary.sh
│   ├── cron-health.sh
│   └── install-crontab.sh
├── src/
├── tests/
├── docs/
├── CLAUDE.md
├── README.md
├── .gitignore
├── .editorconfig
└── lefthook.yml
```

---

## AI 명령어 (Claude Code)

| 명령어 | 설명 |
|--------|------|
| `/issue <번호>` | 이슈 분석 후 작업 브랜치 생성 + 구현 시작 |
| `/pr` | PR 생성 (설명 자동 작성) |
| `/fix-ci` | CI 실패 자동 수정 |
| `/review` | 현재 변경사항 AI 코드 리뷰 |

---

## 초기 설정 (프로젝트 생성 후)

### GitHub Secrets 등록 (AI 기능 활성화)

```
GitHub → Settings → Secrets and variables → Actions
→ ANTHROPIC_API_KEY 추가
```

### Branch Protection (필수)

```
GitHub → Settings → Branches → Add rule
✅ Require a pull request before merging
✅ Require status checks to pass
✅ Require branches to be up to date
```

### lefthook 설치 (처음 한 번)

```bash
brew install lefthook && lefthook install
```

### cron 루프 등록 (선택)

```bash
bash scripts/install-crontab.sh
```

---

## 업데이트 방법 요약

```bash
np update        # np 스크립트 자체를 GitHub 최신으로 교체
```

devcontainer 템플릿은 `np` 실행 시 항상 GitHub에서 실시간으로 내려받으므로
별도 업데이트 없이 최신 상태가 유지됩니다.
