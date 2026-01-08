# Rafff Umbrella

Monorepo orchestrating **Rafff** - a content management backend with iOS client.

## Architecture Decisions

### Why Monorepo with Submodules?

**Problem:** LLM agents (Ralph) make atomic commits per task. Mixing iOS + Backend in single repo creates interleaved history, making rollbacks and cherry-picks difficult.

**Solution:** Umbrella repo with git submodules:
- Each submodule has independent git history
- Local Ralphs work in isolated scope (can't break each other)
- Umbrella agent handles cross-stack alignment
- Single developer ("LLM Operator") commits umbrella after work sessions

### Component Separation

| Layer | Scope | Agent |
|-------|-------|-------|
| Umbrella | API specs, shared contracts, orchestration | Copilot/Claude/Codex |
| Backend | Next.js app, API implementation | Backend Ralph |
| iOS | SwiftUI 18+ app, client implementation | iOS Ralph |

### Tech Stack

- **Backend:** Next.js + React (admin panel built-in, Docker deployment)
- **iOS:** SwiftUI 18+
- **API Contract:** OpenAPI 3.1 (source of truth)
- **Type Generation:** OpenAPI → TypeScript + Swift

## Submodules

| Submodule | Repository |
|-----------|------------|
| `raff_backend` | https://github.com/RobertKoval/rafff_backend |
| `raff_iOS` | https://github.com/RobertKoval/rafff_iOS |

## Commands

### Initial Setup (after clone)

```bash
# Clone with submodules
git clone --recursive https://github.com/RobertKoval/rafff_umbrella.git

# Or if already cloned without --recursive
git submodule update --init --recursive
```

### Daily Workflow

```bash
# Pull latest umbrella + update submodule refs
git pull
git submodule update --init --recursive

# Pull latest commits FROM submodule origins (updates working tree)
git submodule update --remote

# Work in a submodule
cd raff_backend
git checkout main
git pull
# ... make changes, commit, push ...
cd ..

# Update umbrella to point to new submodule commit
git add raff_backend
git commit -m "chore: update backend ref"
git push
```

### Type Generation

```bash
# Generate TypeScript + Swift types from OpenAPI spec
./scripts/generate-types.sh

# Validate OpenAPI spec
./scripts/validate-api.sh
```

### Sync All Submodules

```bash
# Pull latest from all submodule origins
./scripts/sync-submodules.sh
```

## LLM Agent Workflow

### Umbrella Agent (Copilot/Claude/Codex)
- Updates `shared/api-spec/openapi.yaml`
- Runs `./scripts/generate-types.sh` to sync types
- Aligns SPECIFICATION with implementation
- Commits umbrella changes

### Backend Ralph
- Works only in `raff_backend/`
- Uses local `plan.json` and `dev_scripts/`
- Commits directly to backend repo
- Cannot affect iOS code

### iOS Ralph
- Works only in `raff_iOS/`
- Uses local `plan.json` and `dev_scripts/`
- Commits directly to iOS repo
- Cannot affect backend code

## API Contract Workflow

1. **Umbrella agent** updates `shared/api-spec/openapi.yaml`
2. Run `./scripts/generate-types.sh`
3. Generated types appear in:
   - `raff_backend/src/types/api.generated.ts`
   - `raff_iOS/Sources/API/Models.generated.swift`
4. **Backend Ralph** implements endpoint matching generated types
5. **iOS Ralph** implements client using generated models
6. **Result:** API contract enforced, no drift possible

## Related Documentation

- [SPECIFICATION.DRAFT.md](./SPECIFICATION.DRAFT.md) - Product specification (WIP)
- [CLAUDE.md](./CLAUDE.md) - Agent context and guidelines
- [dev_scripts/RALPH_PROMPT.md](./dev_scripts/RALPH_PROMPT.md) - Ralph agent instructions
