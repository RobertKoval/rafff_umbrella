# Rafff Project TODO

## ✅ Completed

- [x] Umbrella repo with submodules
- [x] Backend + iOS submodules linked
- [x] Shared API spec (OpenAPI) - full v1.0 with content, auth, admin, analytics
- [x] Type generation script (`scripts/generate-types.sh`)
- [x] Submodule sync script (`scripts/sync-submodules.sh`)
- [x] API validation script (`scripts/validate-api.sh`)
- [x] README with architecture decisions and commands
- [x] .gitignore for all 3 repos

## 🔲 Agent Infrastructure

- [x] **CLAUDE.md for umbrella** - fill with cross-project context
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

## ✅ Specification

- [x] **SPECIFICATION.md** - comprehensive v1.0 spec with all Q&A resolved
- [x] Define core features and user stories
- [x] Define data models (schemas in openapi.yaml)
- [x] Define API endpoints (full openapi.yaml with 25 endpoints)

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

1. ~~**Specification** - Define what to build~~ ✅ Done
2. **Agent Infrastructure** - CLAUDE.md files + Ralph configs
3. **Create Projects** - Next.js + Xcode
4. **Implementation** - Ralphs take over
