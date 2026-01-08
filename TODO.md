# Rafff Project TODO

## ✅ Completed

- [x] Umbrella repo with submodules
- [x] Backend + iOS submodules linked
- [x] Shared API spec (OpenAPI) - starter with health/auth
- [x] Type generation script (`scripts/generate-types.sh`)
- [x] Submodule sync script (`scripts/sync-submodules.sh`)
- [x] API validation script (`scripts/validate-api.sh`)
- [x] README with architecture decisions and commands
- [x] .gitignore for all 3 repos

## 🔲 Agent Infrastructure

- [ ] **CLAUDE.md for umbrella** - fill with cross-project context
- [ ] **CLAUDE.md for backend** - Next.js specific agent instructions
- [ ] **CLAUDE.md for iOS** - SwiftUI specific agent instructions
- [ ] **Backend Ralph setup** - `raff_backend/dev_scripts/` with:
  - [ ] ralph.sh
  - [ ] RALPH_PROMPT.md (backend-specific)
  - [ ] setup-hooks.sh
  - [ ] plan.json
- [ ] **iOS Ralph setup** - `raff_iOS/dev_scripts/` with:
  - [ ] ralph.sh
  - [ ] RALPH_PROMPT.md (iOS-specific)
  - [ ] setup-hooks.sh
  - [ ] plan.json

## 🔲 Actual Projects

- [ ] **Backend project** - `npx create-next-app@latest` in `raff_backend/`
- [ ] **iOS project** - Xcode new SwiftUI project in `raff_iOS/`
- [ ] **Generated type targets**:
  - [ ] `raff_backend/src/types/` for TypeScript
  - [ ] `raff_iOS/Sources/API/` for Swift

## 🔲 Specification

- [ ] **SPECIFICATION.md** - flesh out from SPECIFICATION.DRAFT.md
- [ ] Define core features and user stories
- [ ] Define data models
- [ ] Define API endpoints (expand openapi.yaml)

## 🔲 CI/CD (Later)

- [ ] GitHub Actions for umbrella
- [ ] GitHub Actions for backend (lint, test, build)
- [ ] GitHub Actions for iOS (build, test)

## 🔲 Deployment (Later)

- [ ] Docker setup for backend
- [ ] VPS deployment config
- [ ] TestFlight setup for iOS

---

## Recommended Order

1. **Agent Infrastructure** - CLAUDE.md files + Ralph configs
2. **Create Projects** - Next.js + Xcode
3. **Specification** - Define what to build
4. **Implementation** - Ralphs take over
