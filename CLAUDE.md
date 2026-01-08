# Rafff - Umbrella Repository

> Language learning iOS app focused on the **shadowing technique**.

## Overview

This is the **umbrella orchestration repository** that coordinates between backend and iOS development. You manage API contracts and cross-stack alignment but do **NOT** implement features directly in submodules.

**What is Rafff?** Users listen to audio, read along with highlighted text, and repeat aloud to practice pronunciation. Highlighting follows audio playback timing (no speech recognition in MVP).

See @SPECIFICATION.md for full product requirements.

## Tech Stack

| Component | Technology |
|-----------|------------|
| **Backend** | Next.js 16, Prisma 7, Zod 4, Tailwind, shadcn/ui |
| **iOS** | SwiftUI, TCA (The Composable Architecture), iOS 18+ |
| **API Contract** | OpenAPI 3.1 (`shared/api-spec/openapi.yaml`) |
| **Testing** | Vitest, Playwright, Stryker (backend) / Swift Testing, Mutter (iOS) |
| **Deployment** | Docker on VPS |

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     UMBRELLA (this repo)                        │
│  • API spec management (shared/api-spec/openapi.yaml)           │
│  • Type generation orchestration                                │
│  • Cross-stack alignment and coordination                       │
└─────────────────────────────────────────────────────────────────┘
        │                                   │
        ▼                                   ▼
┌───────────────────────┐       ┌───────────────────────┐
│  raff_backend/        │       │  raff_iOS/            │
│  (submodule)          │       │  (submodule)          │
│  • Next.js server     │       │  • SwiftUI client     │
│  • Admin panel        │       │  • TCA architecture   │
│  • Has own CLAUDE.md  │       │  • Has own CLAUDE.md  │
└───────────────────────┘       └───────────────────────┘
```

## Your Responsibilities

**DO:**
- Design/update API contracts in `shared/api-spec/openapi.yaml`
- Run `./scripts/validate-api.sh` after spec changes
- Run `./scripts/generate-types.sh` to regenerate types
- Maintain `SPECIFICATION.md` alignment
- Coordinate cross-stack changes

**DO NOT:**
- Implement features in submodules (local agents do this)
- Commit directly to submodule repos
- Skip type regeneration after API changes

## Common Commands

```bash
# Validate OpenAPI spec (run after every change)
./scripts/validate-api.sh

# Generate TypeScript + Swift types from OpenAPI
./scripts/generate-types.sh

# Sync submodules to latest
./scripts/sync-submodules.sh

# Pull umbrella + update submodules
git pull && git submodule update --init --recursive
```

## Key Files

| File | Purpose |
|------|---------|
| `shared/api-spec/openapi.yaml` | **Source of truth** for API contracts |
| `SPECIFICATION.md` | Product specification (v1.0 complete) |
| `TODO.md` | Project progress checklist |

## API Contract Workflow

When adding/modifying endpoints:

1. Edit `shared/api-spec/openapi.yaml`
2. Validate: `./scripts/validate-api.sh`
3. Generate types: `./scripts/generate-types.sh`
4. Commit to umbrella
5. Notify backend/iOS agents to implement

### OpenAPI Style

- Use `operationId` for all endpoints (becomes function names)
- Group with `tags`
- Define schemas in `components/schemas`
- Include `required` arrays for all objects
- Use `format` hints: `uuid`, `email`, `date-time`

## Code Conventions

### Commits

Use conventional commits with scope:
```
feat(api): add user profile endpoint
fix(spec): correct auth response schema
docs: update README with new commands
chore: sync submodule refs
```

### Naming

- OpenAPI schemas: `PascalCase` (`UserProfile`, `AuthResponse`)
- Scripts: `kebab-case.sh` (`generate-types.sh`)
- Documentation: `SCREAMING_CASE.md`

## Domain Glossary

| Term | Definition |
|------|------------|
| **Shadowing** | Language learning technique: listen, read highlighted text, repeat aloud |
| **Sentence Timing** | JSON with start/end timestamps per sentence (Whisper-extracted) |
| **Voice Variant** | Different TTS voice for same text (min 2 per text) |
| **Level** | Content difficulty: `beginner`, `intermediate_plus`, `advanced` |
| **Free Text** | Admin-flagged text accessible without subscription |

## API Endpoints Summary

**User-facing (iOS):**
- `POST /auth/apple` - Sign in with Apple
- `GET /content/levels` - List levels
- `GET /content/texts` - List texts by level
- `GET /content/texts/{id}` - Get text + sentences
- `GET /content/texts/{id}/audio/{voiceId}` - Get audio URL
- `GET /content/texts/{id}/timing/{voiceId}` - Get sentence timings
- `GET/PUT/DELETE /profile` - User profile
- `POST /subscription/verify` - Verify App Store receipt
- `POST /analytics/events` - Track events

**Admin (Web Panel):**
- `POST /admin/auth/login` - Email/password login
- `GET/POST /admin/texts` - List/create texts
- `GET/PUT/DELETE /admin/texts/{id}` - Manage text
- `POST /admin/texts/{id}/restore` - Restore soft-deleted
- `POST/PUT/DELETE /admin/texts/{id}/voices/{voiceId}` - Manage voices

## Security Considerations

- **User Auth**: Sign in with Apple only (no email/password for users)
- **Admin Auth**: Email/password with JWT
- **Anonymous Access**: Free texts accessible without auth
- **Subscription**: Required for full library access
- **Age Restriction**: 13+ only (no COPPA)
- **Data Storage**: Progress on-device, profile server-side
- **Soft Delete**: 30-day retention before hard delete

## Testing

Before committing API changes:
```bash
./scripts/validate-api.sh  # Must pass
./scripts/generate-types.sh  # Should succeed
```

## Current Status

See @TODO.md for progress. Specification phase complete:
- SPECIFICATION.md v1.0 done
- OpenAPI v1.0 done (25 endpoints)
- Next: Agent infrastructure + project scaffolding
