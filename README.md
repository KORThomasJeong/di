# np — AI-Augmented Project Scaffolder

한 줄로 설치하고, 한 명령어로 프로젝트를 생성하는 AI 기반 스캐폴딩 도구입니다.

- Claude Code 워크플로우 내장 (`/issue`, `/pr`, `/fix-ci`, `/review`)
- GitHub Actions CI/CD + AI 코드 리뷰 자동화
- devcontainer 지원 (Node.js / Python / Fullstack)
- `np update` 로 항상 최신 버전 유지

---

## 설치

```bash
curl -fsSL https://raw.githubusercontent.com/KORThomasJeong/di/main/install.sh | bash
```

설치 스크립트가 하는 일:
- `~/.local/bin/np` 로 스크립트 배포
- `~/.bashrc` / `~/.zshrc` 에 PATH 자동 등록
- `~/project/` 디렉터리 생성

설치 후 새 터미널을 열거나:

```bash
source ~/.bashrc   # 또는 source ~/.zshrc
```

---

## 빠른 시작

```bash
np                        # 인터랙티브 모드
np my-app node            # 이름 + 스택 직접 지정
np dashboard fullstack
np data-pipeline python
```

---

## 사용 흐름

### 1단계 — 이름 & 스택 선택

```
프로젝트 이름을 입력하세요: my-app
스택을 선택하세요 [node/python/fullstack] (기본: node):
```

| 스택 | 내용 |
|------|------|
| `node` | Node.js 22, Vitest, ESLint, Prettier |
| `python` | Python 3.12, FastAPI, pytest, ruff |
| `fullstack` | Next.js + FastAPI + PostgreSQL |

### 2단계 — 프로젝트 경로 선택

```
? 프로젝트를 어디에 만들까요?
  [1] ~/project/2026-05/my-app  (날짜 기반 자동 생성)  ← 기본값
  [2] ~/project/<직접 입력>/my-app
  [3] ./my-app  (현재 위치)
선택 [1/2/3] (기본: 1):
```

옵션 1은 `~/project/` 안에서 기존 월 폴더를 감지해 다음 번호를 자동 제안합니다.
(`2026-01` 이 있으면 → `2026-02` 제안)

### 3단계 — devcontainer 추가 (선택)

```
devcontainer를 추가하시겠습니까? [y/N]
```

`y` 선택 시 GitHub에서 스택 맞는 템플릿을 실시간으로 내려받아 `.devcontainer/` 를 생성합니다.

| 스택 | 생성 파일 |
|------|-----------|
| `node` | `.devcontainer/devcontainer.json` |
| `python` | `.devcontainer/devcontainer.json` |
| `fullstack` | `.devcontainer/devcontainer.json` + `.devcontainer/docker-compose.yml` |

완료 후:
```bash
code .   # VS Code → 우하단 "Reopen in Container" 클릭
```

### 4단계 — GitHub 저장소 생성 (선택)

`gh` CLI 로그인 상태면 저장소 공개/비공개 여부를 선택해 바로 생성 + push 합니다.

---

## devcontainer 상세

### fullstack

Docker Compose 기반 3-서비스 구성

| 서비스 | 포트 | 이미지 |
|--------|------|--------|
| app | 3000, 4000 | node:22 devcontainer |
| db | 5432 | postgres:16-alpine |
| adminer | 8080 | adminer (DB 관리 UI) |

VS Code 확장 자동 설치: ESLint, Prettier, Tailwind CSS, Prisma, SQLTools, Pylance, Ruff, GitLens

### node

단일 Node.js 22 컨테이너

| 포트 | 용도 |
|------|------|
| 3000 | Dev Server |
| 4000 | API Server |

VS Code 확장: ESLint, Prettier, Tailwind CSS, GitLens

### python

단일 Python 3.12 컨테이너

| 포트 | 용도 |
|------|------|
| 8000 | FastAPI / Dev Server |

VS Code 확장: Pylance, Ruff, Black, isort

---

## 생성되는 프로젝트 구조

```
<프로젝트명>/
├── .claude/
│   ├── commands/
│   │   ├── issue.md       # /issue — 이슈 기반 작업 시작
│   │   ├── pr.md          # /pr — PR 자동 생성
│   │   ├── fix-ci.md      # /fix-ci — CI 실패 자동 수정
│   │   └── review.md      # /review — AI 코드 리뷰
│   └── settings.json
├── .devcontainer/          # devcontainer 선택 시
│   ├── devcontainer.json
│   └── docker-compose.yml  # fullstack만
├── .github/
│   ├── workflows/
│   │   ├── ci.yml                  # 스택별 lint / test / build
│   │   ├── ai-review.yml           # PR 생성 시 Claude 자동 리뷰
│   │   ├── auto-fix.yml            # CI 실패 자동 수정 (수동 트리거)
│   │   ├── release.yml             # release-please 기반 자동 릴리즈
│   │   └── scheduled-loops.yml     # 30분마다 CI 수정 cron
│   ├── ISSUE_TEMPLATE/
│   ├── PULL_REQUEST_TEMPLATE.md
│   └── CODEOWNERS
├── scripts/
│   ├── cron-fix-ci.sh          # CI 실패 자동 수정 루프
│   ├── cron-respond-reviews.sh # 리뷰 코멘트 자동 응답
│   ├── cron-daily-summary.sh   # 일일 개발 요약 생성
│   ├── cron-health.sh          # 프로덕션 헬스체크
│   └── install-crontab.sh      # cron 일괄 등록
├── src/
├── tests/
├── docs/
├── CLAUDE.md       # Claude 컨텍스트 (스택별 자동 작성)
├── README.md
├── .gitignore
├── .editorconfig
└── lefthook.yml    # Git hooks (lint, typecheck, test)
```

---

## Claude Code AI 명령어

프로젝트 생성 후 `claude` 로 진입하면 다음 명령어를 사용할 수 있습니다.

| 명령어 | 동작 |
|--------|------|
| `/issue <번호>` | 이슈 내용 분석 → 작업 브랜치 생성 → 구현 시작 |
| `/pr` | 변경사항 확인 → push → PR 자동 생성 (설명 포함) |
| `/fix-ci` | 현재 브랜치 CI 실패 로그 분석 → 코드 수정 → push |
| `/review` | diff 전체 검토 → 보안 / 버그 / 품질 / 테스트 리포트 |

---

## GitHub Actions 자동화

### CI (`ci.yml`)

PR 및 main push 시 자동 실행:

- **node**: lint → typecheck → test → build → security scan
- **python**: ruff lint → mypy → pytest → security scan
- **fullstack**: frontend + backend 병렬 검사

### AI 코드 리뷰 (`ai-review.yml`)

PR 생성/업데이트 시 Claude가 자동으로 리뷰 코멘트를 남깁니다.

```
🔴 Critical — 보안 취약점, 버그
🟡 Warning  — 코드 품질, 테스트 누락
🟢 Suggestion — 성능, 가독성 개선
```

> `ANTHROPIC_API_KEY` GitHub Secret 등록 필요

### Scheduled Loops (`scheduled-loops.yml`)

- 30분마다: 내 PR 중 CI 실패한 것 자동 수정
- 매일 08:00: 전날 개발 활동 요약 생성

---

## 프로젝트 생성 후 초기 설정

### 1. GitHub Secrets 등록

```
GitHub 리포지토리 → Settings → Secrets and variables → Actions
→ New repository secret
  이름: ANTHROPIC_API_KEY
  값: sk-ant-...
```

### 2. Branch Protection 설정 (필수)

```
GitHub → Settings → Branches → Add branch ruleset
  ✅ Require a pull request before merging
  ✅ Require status checks to pass before merging
  ✅ Require branches to be up to date before merging
```

### 3. lefthook 설치 (Git hooks 활성화)

```bash
brew install lefthook && lefthook install
```

### 4. cron 루프 등록 (선택)

```bash
bash scripts/install-crontab.sh
```

### 5. 작업 시작

```bash
cd <프로젝트>
claude
/issue 1
```

---

## np 업데이트

```bash
np update
```

GitHub `main` 브랜치의 최신 `np.sh` 를 내려받아 `~/.local/bin/np` 를 교체합니다.
devcontainer 템플릿은 `np` 실행 시마다 실시간으로 fetch하므로 별도 업데이트가 필요 없습니다.

---

## 요구 사항

| 도구 | 필수 | 용도 |
|------|------|------|
| `bash` | ✅ | 스크립트 실행 |
| `curl` | ✅ | 파일 다운로드 |
| `git` | ✅ | 저장소 초기화 |
| `gh` | 선택 | GitHub 저장소 생성 |
| `lefthook` | 선택 | Git hooks |
| Docker Desktop | 선택 | devcontainer 실행 |
| VS Code | 선택 | devcontainer IDE |
