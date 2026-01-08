# Rafff Umbrella - Agent Context

> **IMPORTANT:** This is the **umbrella orchestration repo**. You have access to shared API specs and can coordinate between backend and iOS, but **do NOT implement features directly in submodules**. Each submodule has its own CLAUDE.md and local Ralph agent.

## Project Overview

Rafff is a content management system with:
- **Backend** (`raff_backend/`): Next.js + React admin panel, API server
- **iOS Client** (`raff_iOS/`): SwiftUI 18+ mobile app
- **Shared Contracts** (`shared/api-spec/`): OpenAPI 3.1 specifications

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     UMBRELLA (this repo)                        │
│  • API spec management (shared/api-spec/openapi.yaml)           │
│  • Type generation orchestration                                 │
│  • Cross-stack alignment and coordination                        │
│  • Specification and documentation                               │
├─────────────────────────────────────────────────────────────────┤
│  raff_backend/ (submodule)    │  raff_iOS/ (submodule)          │
│  • Next.js implementation     │  • SwiftUI implementation        │
│  • Has own CLAUDE.md          │  • Has own CLAUDE.md             │
│  • Has own Ralph agent        │  • Has own Ralph agent           │
│  • Implements API endpoints   │  • Consumes API endpoints        │
└─────────────────────────────────────────────────────────────────┘
```

## Your Role (Umbrella Agent)

You are responsible for:
1. **API Contract Design** - Update `shared/api-spec/openapi.yaml`
2. **Type Generation** - Run `./scripts/generate-types.sh` after API changes
3. **Specification** - Maintain `SPECIFICATION.md` alignment
4. **Cross-Stack Review** - Ensure backend and iOS are aligned
5. **Documentation** - Keep README.md and docs current

You should **NOT**:
- Implement features in `raff_backend/` or `raff_iOS/` (local Ralphs do this)
- Commit directly to submodule repos (coordinate via umbrella)
- Skip type regeneration after API spec changes

## Commands

### Development
```bash
# Validate OpenAPI spec
./scripts/validate-api.sh

# Generate TypeScript + Swift types from OpenAPI
./scripts/generate-types.sh

# Sync submodules to latest from their origins
./scripts/sync-submodules.sh

# Sync with --commit flag to auto-commit updated refs
./scripts/sync-submodules.sh --commit
```

### Git (Submodules)
```bash
# Pull latest umbrella + submodule refs
git pull && git submodule update --init --recursive

# Update submodules to their latest remote commits
git submodule update --remote

# Check submodule status
git submodule status
```

## Key Files

| File | Purpose |
|------|---------|
| `shared/api-spec/openapi.yaml` | **Source of truth** for API contracts |
| `SPECIFICATION.md` | Product specification |
| `TODO.md` | Project progress checklist |
| `README.md` | Architecture decisions, commands |
| `raff_backend/` | Backend submodule (Next.js) |
| `raff_iOS/` | iOS submodule (SwiftUI) |

## API Contract Workflow

When adding/modifying API endpoints:

1. **Edit** `shared/api-spec/openapi.yaml`
2. **Validate** with `./scripts/validate-api.sh`
3. **Generate types** with `./scripts/generate-types.sh`
4. **Commit** changes to umbrella
5. **Notify** that Backend Ralph and iOS Ralph can implement

### OpenAPI Style Guide
- Use `operationId` for all endpoints (becomes function names)
- Group endpoints with `tags`
- Define all schemas in `components/schemas`
- Include `required` arrays for all objects
- Add `description` for non-obvious fields
- Use `format` hints (`uuid`, `email`, `date-time`, etc.)

## Code Style

### Commit Messages
Use conventional commits with scope:
```
feat(api): add user profile endpoint
fix(spec): correct auth response schema
docs: update README with new commands
chore: sync submodule refs
```

### File Naming
- OpenAPI schemas: `PascalCase` (e.g., `UserProfile`, `AuthResponse`)
- Scripts: `kebab-case.sh` (e.g., `generate-types.sh`)
- Documentation: `SCREAMING_CASE.md` or `Title Case.md`

## Coordination Patterns

### Adding a New Feature
1. Design API contract in `openapi.yaml`
2. Run type generation
3. Update SPECIFICATION.md with feature description
4. Backend Ralph implements endpoint
5. iOS Ralph implements client UI
6. Umbrella agent verifies alignment

### Fixing API Mismatch
1. Check `openapi.yaml` for source of truth
2. Regenerate types
3. Identify which side (backend or iOS) drifted
4. Coordinate fix with appropriate Ralph

## Testing

Before committing API changes:
```bash
# Must pass
./scripts/validate-api.sh

# Should succeed (may fail if submodules not set up yet)
./scripts/generate-types.sh
```

## Remember

- **You coordinate, Ralphs implement**
- **OpenAPI is the contract** - backend and iOS derive from it
- **Regenerate types after ANY openapi.yaml change**
- **Check TODO.md** for current project status
- **Read SPECIFICATION.md** before designing new APIs
