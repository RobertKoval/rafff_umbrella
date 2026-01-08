# Project Specification v1.3

## Document Info
- **Last Updated**: 2025-01-08
- **Status**: Ready for Implementation
- **Project Name**: Rafff *(working name — final product name TBD)*
- **Revision**: v1.3 — App navigation, onboarding, settings, device support, CI/CD, API versioning

---

## 1. Product Overview

### Q: What is this project?
**A**: A language learning iOS app focused on the **shadowing technique** — users listen to audio, read along with highlighted text, and repeat aloud to practice pronunciation.

### Q: Who is the target audience?
**A**: Everyone learning English, ages 13+.

### Q: What makes it different?
**A**: Simple, focused shadowing experience. Some content free forever; subscription unlocks full library.

### Q: How do we measure success?
**A**: Primary metrics:
- **Retention rate** — users returning after first session
- **Trial-to-subscription conversion rate** — free trial → paid subscription

---

## 2. MVP Scope

### Q: What features are included in MVP?

| ✅ MVP | ❌ Deferred |
|--------|------------|
| Text browsing by level | User recordings feature |
| Audio playback (0.5x–2.0x speed) | Push notifications |
| Real-time sentence highlighting | Pronunciation accuracy scoring |
| Progress tracking (% complete) | Cloud backup/sync |
| Subscription + free tier | User accounts/profiles |
| Admin web panel | Audio generation in admin |
| Offline mode (downloadable content) | |
| Dark mode (system-follow) | |
| Voice selection (min 2 per text) | |
| Simple onboarding (3 screens) | |

### Q: What about pronunciation checking?
**A**: **Not in MVP.** Highlighting follows audio playback timing, not user speech recognition.

### Q: What about user recordings?
**A**: **Deferred to post-MVP.** Will likely require **audio subtraction** to isolate user voice from original audio.

---

## 3. Content Structure

### Q: How is content organized?
**A**: Three difficulty levels:
- **Beginner**
- **Intermediate+** *(intentional branding, not CEFR)*
- **Advanced**

### Q: How much content at launch?
**A**: 10 texts per level = **30 total texts**.

### Q: What's the content expansion plan?
**A**: Occasional additions as needed — no fixed schedule.

### Q: What's free vs paid?
**A**:
- **Free forever**: 2-3 texts per level (~6-9 total), **admin-flagged**
- **Subscription**: Full library access

Admin can mark any text as "free" via checkbox in content management panel.

### Q: How do users discover free vs locked content?
**A**: In the text list view:
- **Free texts**: Displayed normally, accessible immediately
- **Locked texts**: Show lock icon overlay
- **Tap on locked text**: Opens subscription prompt (trial offer + pricing)

### Q: What is the text/audio format?
**A**:
- **Text**: ~200 words soft limit (no hard enforcement)
- **Audio**: Sentence-segmented with timing metadata
- **Voices**: Minimum 2 voice variants per text, user-selectable in app settings

### Q: What metadata is stored for voices?
**A**: Each voice has:
- **Name**: Display name (e.g., "Sarah", "James")
- **Accent**: Regional accent (e.g., "American", "British")
- **Gender**: Male / Female / Other

Displayed in settings as: "Sarah (American, Female)"

### Q: How are text previews generated?
**A**: **Auto-generated** from the first ~50 words of the full text. No separate preview field needed in admin.

### Q: How is audio generated?
**A**:
- **Tool**: [VibeVoice-1.5B](https://huggingface.co/microsoft/VibeVoice-1.5B) *(may change)*
- **Process**: Manual generation for MVP
- **Future**: Integrate TTS into admin panel (post-MVP)

### Q: How are sentence timings created?
**A**: **Whisper transcription pipeline**:
1. Generate audio with VibeVoice (manual)
2. Run Whisper with `word_timestamps=True` → extract word-level timestamps
3. Group words into sentences by punctuation (`.`, `!`, `?`)
4. Store as JSON alongside audio
5. iOS parses timestamps for highlighting sync

**Whisper raw output** (word-level):
```json
{
  "words": [
    {"word": "Hello", "start": 0.0, "end": 0.5, "probability": 0.99},
    {"word": "welcome", "start": 0.52, "end": 0.95, "probability": 0.98}
  ]
}
```

**Processed timing format** (sentence-level, stored in backend):
```json
{
  "sentences": [
    { "text": "Hello, welcome to the lesson.", "start": 0.0, "end": 2.3 },
    { "text": "Today we will practice greetings.", "start": 2.5, "end": 4.8 }
  ]
}
```

### Q: Where is content hosted?
**A**: Cloud storage on existing VPS. CDN may be added post-MVP if bandwidth requires.

### Q: What audio format?
**A**: **AAC** — universal support on iOS, Android, and Web. MP3 as fallback if needed.

### Q: What is the expected audio file size?
**A**: TBD — estimated few MB per file. Will validate during MVP testing.

---

## 4. App Structure & Navigation

### Q: What is the navigation model?
**A**: **Stack-based navigation (no tab bar)**. The app has a focused, linear flow that doesn't require parallel navigation tabs.

**Rationale**:
- MVP has only content + settings — tab bar would feel empty
- TCA's tree-based navigation works perfectly for drill-down flows
- Simpler DX: One navigation stack, less state to manage

### Q: What is the screen hierarchy?
**A**:
```
Onboarding (first launch only)
    │
    ▼
Levels (Home)
    │
    ├──▶ Settings (modal, gear icon in nav bar)
    │
    ▼ (tap level)
Text List
    │
    ▼ (tap text)
Practice View
    │
    ▼ (completion)
Celebration Overlay
```

### Q: What does the Levels (Home) screen show?
**A**: Three level cards with progress summary:
- Level name (Beginner / Intermediate+ / Advanced)
- Progress indicator (e.g., "8/10 completed")
- Visual progress bar
- Settings gear icon in navigation bar (top-right)

### Q: What does the Text List screen show?
**A**:
- Back button to Levels
- Level name as title
- Filter tabs: `All` | `In Progress` | `Completed`
- List of text cards showing:
  - Title
  - Preview (~50 words)
  - Progress bar + percentage
  - Lock icon (if locked)
  - "NEW" badge (if < 3 days old)

### Q: What does the Practice View show?
**A**:
- Back button to Text List
- Text title as navigation title
- Full text with sentence highlighting
- Playback controls (play/pause, speed, prev/next, restart)
- Progress bar (display only)

---

## 5. Onboarding

### Q: Is there an onboarding experience?
**A**: **Yes.** Simple 3-screen onboarding on first launch, explaining the shadowing technique.

### Q: What does onboarding look like?
**A**: Three swipeable screens with SF Symbols and minimal text:

**Screen 1 — "Listen"**
- Icon: `headphones` or `speaker.wave.3.fill`
- Text: "Hear native speakers at your pace. Slow down to 0.5x or speed up to 2x."

**Screen 2 — "Follow"**
- Icon: `eye.fill` or `text.alignleft`
- Text: "Read along as each sentence highlights in sync with the audio."

**Screen 3 — "Repeat"**
- Icon: `waveform` or `mic.fill`
- Text: "Speak aloud to train your pronunciation. This is shadowing — the fastest way to sound like a native speaker."
- Button: "Get Started"

### Q: Can users skip onboarding?
**A**: **Yes.** Small "Skip" link available on each screen.

### Q: When does onboarding show?
**A**: First launch only. Completion state stored locally.

---

## 6. Settings Screen

### Q: What settings are available?
**A**:

| Section | Setting | Type |
|---------|---------|------|
| **Playback** | Voice | Picker (name + accent + gender) |
| | Default Speed | Picker (0.5x – 2x) |
| | Background Audio | Toggle (default: off) |
| **App** | Language | Picker (English/Spanish/Ukrainian) |
| **Subscription** | Restore Purchases | Button |
| | Manage Subscription | Link (App Store) |
| **Storage** | Cache Size | Display (e.g., "127 MB") |
| | Clear Cache | Action sheet |
| **About** | Version | Display (e.g., "1.0.0 (42)") |
| | Privacy Policy | Link |
| | Terms of Service | Link |

### Q: How does "Clear Cache" work?
**A**: Shows action sheet with options:
- Clear audio files only
- Clear all cached content (texts + audio)
- Cancel

User chooses what to clear. Progress data is never deleted (stored separately).

---

## 7. Device Support

### Q: Is this an iPhone-only app?
**A**: **iPhone-optimized.** iPad can run in compatibility mode (scaled iPhone interface), but no iPad-specific layout.

### Q: What orientations are supported?
**A**: **Portrait only.** Locked to portrait orientation on all devices.

### Q: What iOS versions are supported?
**A**: **iOS 18+** minimum. Takes advantage of latest SwiftUI features.

### Q: Is dark mode supported?
**A**: **Yes, system-follow only.** App automatically adapts to system dark/light mode setting. No in-app toggle.

---

## 8. User Features

### Q: How does the shadowing UI work?
**A**: Controls visible during practice:
- Text display with current sentence highlighted
- Play/Pause button
- **Speed preset buttons**: `0.5x` | `0.75x` | `1x` | `1.5x` | `2x` (default: 1x)
- Progress bar (display only, not draggable)
- Restart button
- Previous/Next sentence buttons

### Q: What happens when user taps a sentence during playback?
**A**: **Jump and continue playing.** Audio seeks to that sentence's start time and continues. If paused, it jumps but stays paused.

### Q: Can user drag the progress bar to seek?
**A**: **No.** Progress bar is display-only. User navigates via sentence tap or prev/next buttons. This keeps the UX focused on sentence-level practice.

### Q: What does the audio buffering state look like?
**A**: **Play button disabled + spinner.** When audio is loading/buffering, play button shows a loading indicator and is non-interactive until ready.

### Q: How is audio loaded?
**A**: **Download fully, then play.** Audio is downloaded completely before playback starts. This ensures smooth playback without buffering interruptions.

### Q: What happens when audio finishes (end of text)?
**A**: **Celebration flow:**
1. Audio finishes → brief pause (0.5s)
2. Show completion overlay with checkmark/celebration visual
3. Display: "Great job!" message
4. Mark text as 100% complete
5. Two buttons: **"Practice Again"** | **"Next Text"**
6. If last text in level → show "Level Complete!" celebration

### Q: Should audio continue when app is backgrounded?
**A**: **User setting**, default is **pause when backgrounded**.
- Setting in app: "Continue audio in background" (off by default)
- When enabled, audio plays like a podcast

### Q: What happens when audio is interrupted (phone call, Siri)?
**A**: **Stay paused.** After interruption ends, audio remains paused. User manually resumes. This follows standard iOS audio session behavior for non-music apps.

### Q: Where does user select voice variant?
**A**: **App settings** for MVP. User sets preferred voice globally. Future: may add per-text voice switcher in the text view.

### Q: What happens when user changes voice?
**A**: **Restart from beginning.** Different voice files may have slightly different timing — continuing from current position requires timestamp mapping. Not worth complexity for MVP.

### Q: What happens when user leaves mid-text?
**A**: Prompt: *"Resume where you left off?"* — user chooses continue or restart.

### Q: How is progress tracked?
**A**:
- **Completed**: Marked as "Done"
- **Partial**: Shows percentage (e.g., "52%")
- **Visible**: In text list view per level

### Q: How is progress displayed in the list?
**A**: **Both** — progress bar visual + percentage text (e.g., progress bar at 52% with "52%" label).

### Q: How are texts sorted in the list?
**A**: **Smart default with filter tabs**:
- **Default sort**: In-progress first (by % ascending) → Not started → Completed
- **Filter tabs**: `All` | `In Progress` | `Completed`
- **New content**: "NEW" badge on recently added texts

### Q: When does the "NEW" badge disappear?
**A**: After **3 days** from text publication date.

### Q: How does content loading work?
**A**: **Lazy loading strategy**:

| View | Data Loaded | Cached |
|------|-------------|--------|
| Text List | Title, level, ~50 word preview, progress %, lock status | Yes |
| Text Detail | Full text content, sentence timings | Yes |
| Audio | Downloaded when Play tapped (if not cached) | Yes |

- **Text list data**: Fetched on app launch (lightweight)
- **Full text + audio**: Downloaded when user opens specific text
- **No internet when opening text**: Show error, cannot proceed
- **Text and audio cached separately**: Text can be viewed without audio if partially downloaded

### Q: Can users download content for offline use?
**A**: **Yes.** Content is cached when opened. No bulk "Download All" — each text downloaded on first open.

### Q: Is there a cache size limit?
**A**: **No limit.** All opened content is cached. User can manually clear cache in Settings if storage is a concern.

### Q: What do empty states show?
**A**: Text message with SF Symbol icons. Specific states:
- **No texts downloaded (offline, no cache)**: "No content available offline"
- **All texts completed**: "Great job! You've completed all texts in this level"
- **Filter returns nothing**: "No texts match this filter"
- **Network error**: Popup/toast with error message and retry option

---

## 9. User Identity & Authentication

### Q: Do users need to create accounts?
**A**: **No.** Users are completely anonymous in MVP.
- No Sign in with Apple
- No user profiles stored on server
- All progress/preferences stored on-device only
- Subscriptions managed via RevenueCat (tied to Apple ID, not app account)

**Rationale**: Simplifies architecture significantly. RevenueCat handles subscription state via Apple ID without requiring app-level accounts. User accounts can be added post-MVP when cloud sync is implemented.

### Q: How are subscriptions tracked without user accounts?
**A**: **RevenueCat** handles this:
- RevenueCat SDK identifies users by Apple ID
- Subscription status checked via RevenueCat API
- No need for server-side user database
- Backend only receives webhook events for analytics

### Q: What RevenueCat entitlement structure?
**A**: **Single entitlement: "premium"** — unlocks all content. Simple structure for MVP.

### Q: Where is the "Restore Purchases" button?
**A**: Two locations:
- **Settings screen** — always visible
- **Subscription prompt** — when user taps locked content

### Q: Where is "Manage Subscription"?
**A**: **Settings screen** — deep link to App Store subscription management (RevenueCat provides this URL).

---

## 10. Monetization

### Q: What is the subscription model?
**A**:

| Plan | Price | Access |
|------|-------|--------|
| Free | $0 | 2-3 texts per level, forever |
| Trial | $0 | 7 days full access |
| Monthly | $1.99 | Full library |
| Yearly | $9.99 | Full library (~58% savings) |

### Q: Why is pricing low compared to competitors?
**A**: **Intentional positioning.** This app is focused purely on shadowing practice, not comprehensive language learning. Lower price reflects narrower scope and encourages volume adoption.

### Q: Regional pricing?
**A**: Configured via **App Store Connect** price tiers only.
- +$1 for US, UK, Australia, Canada
- No backend pricing logic needed

### Q: What happens when subscription lapses?
**A**:
- **Local data remains** (progress, preferences)
- **Access reverts to free tier** — user can access free texts only
- RevenueCat automatically detects lapsed status

### Q: How are subscription terms displayed?
**A**: Standard App Store paywall screen showing price, billing frequency, and terms. Follows Apple's subscription guidelines.

### Q: How does the subscription flow work?
**A**:
1. User taps locked content
2. Paywall appears (RevenueCat paywall or custom)
3. Shows trial offer + pricing options
4. User selects plan → App Store purchase sheet
5. On success → RevenueCat SDK updates entitlement
6. Content unlocks immediately

---

## 11. Admin Panel

### Q: How do admins access the panel?
**A**: Separate web application (e.g., `admin.projectname.com`).

### Q: How do admins authenticate?
**A**: Email + password.

### Q: How long do admin sessions last?
**A**: **30 days** from last activity. Auto-logout after inactivity period.

### Q: Are there admin roles/permissions?
**A**: **Single role** — all admins have full access. Multiple admin accounts supported, but no permission levels.

### Q: Does admin panel show analytics?
**A**: **No.** Use external tools:
- RevenueCat dashboard for subscription metrics
- Umami (if deployed) for usage analytics
- Sentry for error tracking

### Q: What is the content management workflow?
**A**:
1. Select level (Beginner / Intermediate+ / Advanced)
2. Create new text entry
3. Paste text content
4. Upload audio file(s) — multiple voices with metadata (name, accent, gender)
5. Upload timing JSON (Whisper-generated)
6. **Preview** text with audio playback
7. Save & publish

### Q: Can admins preview content before publishing?
**A**: **Yes.** Admin can preview text display with audio playback before making it live.

### Q: Can admins generate audio in the panel?
**A**: **Not in MVP.** Audio generated manually with VibeVoice, then uploaded.

### Q: What validation happens on audio upload?
**A**: **Format validation only:**
- Allowed formats: AAC, MP3
- No strict file size limit (warn if > 10MB)
- No duration limit enforced

### Q: What validation happens on timing JSON upload?
**A**:
- **Schema validation**: Correct structure (`sentences` array with `text`, `start`, `end`)
- **Sequential timestamps**: Each sentence's `start` < `end`, no overlaps
- **No text matching**: Sentence text not validated against main text (allows minor differences)

### Q: What happens if upload fails mid-way?
**A**: **Partial state preserved.** Admin can retry the failed upload. Text entry remains in draft state until all required files uploaded.

### Q: What about concurrent editing?
**A**: **Last write wins.** Not expected to be an issue with single/few admins. No locking mechanism.

### Q: Can admins edit published content?
**A**: **Yes.** Edits allowed on published texts/audio.
- Cached content on user devices remains unchanged until re-downloaded
- New users see updated version
- iOS app shows "Update available" badge on texts with newer versions

### Q: How does content deletion work?
**A**: **Soft delete → hard delete after 30 days.**
- Deleted content hidden from new users immediately
- Users with cached content retain access
- Permanent deletion after 30 days
- Allows recovery if deleted by mistake

### Q: Can admins perform bulk operations?
**A**: **Yes.**
- **Bulk soft-delete**: Select multiple texts to delete at once
- **Export**: Export content data (format TBD)

---

## 12. Content Versioning & Sync

### Q: How does the iOS app know about new content?
**A**: **Poll on launch.** App checks for content updates when opened. No push notifications for new content in MVP.

### Q: What happens when content is updated on server?
**A**: **"Update available" badge** shown on affected texts. User can:
- Continue using cached (old) version
- Tap to download updated version

Updating does not happen automatically — user controls when to update.

### Q: How are recordings handled when content version changes?
**A**: *(When recordings feature is implemented)* Recordings store **metadata only** indicating which content version they were made against. Old recordings remain accessible; they are not automatically migrated or deleted when content updates.

---

## 13. Error Handling & Network

### Q: What error states exist?
**A**:

| Scenario | Behavior |
|----------|----------|
| Audio fails to load | Show error message with retry option, log to analytics |
| No recordings yet | Show empty state *(deferred feature)* |
| Network disconnect | Graceful offline if content cached; error if not |
| Download fails | Retry option + error message |
| Text open without internet (not cached) | Error message, cannot proceed |
| Audio buffering | Play button disabled + spinner |

### Q: What is the network retry strategy?
**A**: Depends on endpoint type:
- **Content endpoints**: Single retry, then show error with manual retry option
- **Analytics endpoints**: Fire-and-forget (no retry, fail silently)

### Q: What happens if API returns error?
**A**: Show user-friendly error message. Log to Sentry with full context.

---

## 14. Analytics

### Q: What analytics solution?
**A**: **Lightweight, self-hosted, free.**

- **MVP**: Custom endpoint — POST events to backend
- **If dashboards needed**: [Umami](https://umami.is/) (self-hosted)
- **RevenueCat**: Provides subscription analytics automatically

### Q: What events to track?
**A**:
- App open / session start
- Text started / completed
- Subscription conversion (trial → paid) — via RevenueCat
- Audio load failures
- Download success/failure

### Q: What is the analytics event schema?
**A**: Events include metadata for analysis:
```json
{
  "event": "text_completed",
  "properties": {
    "text_id": "uuid",
    "level": "beginner",
    "duration_seconds": 180,
    "speed": 1.0
  },
  "device_id": "anonymous-uuid",
  "timestamp": "2025-01-08T12:00:00Z",
  "app_version": "1.0.0"
}
```

### Q: What error logging solution?
**A**: **Sentry** — easy integration, good iOS/web support.

---

## 15. Technical Architecture

### Backend Stack
| Technology | Version/Notes |
|------------|---------------|
| **Runtime** | Next.js 16 |
| **Database** | PostgreSQL |
| **ORM** | Prisma 7 |
| **Validation** | Zod 4 |
| **Testing** | Vitest, Playwright |
| **Mutation Testing** | Stryker Mutator |
| **Linting** | Knip |
| **UI** | Tailwind CSS, shadcn/ui |
| **Deployment** | Docker on existing VPS |

### iOS Stack
| Technology | Version/Notes |
|------------|---------------|
| **Architecture** | TCA (The Composable Architecture) |
| **Min iOS** | iOS 18+ |
| **UI** | SwiftUI |
| **Subscriptions** | RevenueCat |
| **Linting** | SwiftLint |
| **Testing** | Swift Testing, ViewInspector |
| **Mutation Testing** | Mutter |

### Shared
- **Commit hooks**: Both repos
- **API Contract**: OpenAPI 3.1 (`shared/api-spec/openapi.yaml`)

### Infrastructure
| Component | Solution |
|-----------|----------|
| Backend hosting | Existing VPS (Docker) |
| Audio/content storage | VPS filesystem (CDN post-MVP if needed) |
| Analytics | Custom endpoint + optional Umami |
| Subscriptions | RevenueCat + App Store |
| Database backups | Manual (server-level) |

---

## 16. Local Development & Docker

### Q: What services are needed for local development?
**A**: **Backend + PostgreSQL** via Docker Compose:
```yaml
services:
  app:
    build: .
    ports:
      - "3000:3000"
    volumes:
      - ./src:/app/src          # Hot reload
      - ./uploads:/app/uploads  # Local audio storage
      - /app/node_modules       # Exclude node_modules
    environment:
      - DATABASE_URL=postgresql://postgres:postgres@db:5432/rafff
    depends_on:
      - db

  db:
    image: postgres:16
    environment:
      - POSTGRES_DB=rafff
      - POSTGRES_PASSWORD=postgres
    volumes:
      - pgdata:/var/lib/postgresql/data
    ports:
      - "5432:5432"

volumes:
  pgdata:
```

### Q: Where are audio files stored locally?
**A**: **Local filesystem** (`./uploads/`). Mounted as Docker volume. Mirrors production setup (VPS filesystem).

### Q: Does Docker setup support hot reload?
**A**: **Yes.** Source code mounted as volume. Next.js hot reloads on file changes.

### Q: How do database migrations run?
**A**:
| Environment | Strategy |
|-------------|----------|
| **Local dev** | Auto-run on `docker compose up` |
| **Production** | Auto-run on container start |

Prisma migration command in Docker entrypoint:
```bash
npx prisma migrate deploy && npm start
```

### Q: Is there seed data for local development?
**A**: **Yes.** Seed script creates:
- 1-2 sample texts per level (6 total)
- Sample audio files (short test clips)
- Test admin account (`admin@test.com` / `password`)
- Timing JSON for each sample text

Run: `npm run db:seed` or auto-run in dev mode.

### Q: Production Docker setup?
**A**: **Single container** for Next.js app. PostgreSQL runs separately (or managed service).

---

## 17. CI/CD Pipeline

### Q: What CI/CD pipelines exist?
**A**: GitHub Actions for all repos, **no auto-deploy**:

| Repo | Pipeline | Triggers |
|------|----------|----------|
| **Umbrella** | Validate OpenAPI spec | PR, push to main |
| **Backend** | Lint, test, build | PR, push to main |
| **iOS** | Lint, test, build | PR, push to main |

### Q: Is there auto-deployment?
**A**: **No.** All deployments are manual:
- Backend: Manual `docker compose up` on VPS
- iOS: Manual TestFlight upload via Xcode

### Q: What does each pipeline check?
**A**:

**Umbrella:**
- Validate OpenAPI spec (`./scripts/validate-api.sh`)
- Generate types to verify spec is valid

**Backend:**
- ESLint + Knip
- Vitest unit tests
- Playwright E2E tests (against Docker)
- TypeScript build

**iOS:**
- SwiftLint
- Swift Testing unit tests
- Build verification
- *(XCUITest E2E run locally, not in CI due to complexity)*

---

## 18. API Design

### Q: Is there API versioning?
**A**: **Yes.** All endpoints prefixed with `/v1/`:
- `/v1/content/levels`
- `/v1/admin/auth/login`
- etc.

**Rationale**: Low effort upfront, enables future deprecation and A/B testing.

### Q: How do old app versions handle API changes?
**A**: **Minimum version check on launch.** App checks current version against minimum required version from API. If outdated, shows "Please update" message with App Store link.

---

## 19. E2E Testing Strategy

### Q: What E2E tests for admin panel (Playwright)?
**A**: **Full coverage** — no QA team, tests are critical:

| Test Suite | Flows Covered |
|------------|---------------|
| Auth | Admin login, logout, session expiry |
| Content CRUD | Create text, upload audio, upload timing JSON |
| Publishing | Preview, publish, verify in API |
| Editing | Edit published text, verify version bump |
| Deletion | Soft delete, restore, verify hidden from API |
| Bulk Ops | Select multiple, bulk delete |

### Q: What E2E tests for iOS (XCUITest)?
**A**: **Comprehensive coverage** — all tests must pass mutation testing:

| Test Suite | Flows Covered |
|------------|---------------|
| Onboarding | View all screens, skip, complete |
| Browse | View levels, view text list, filter tabs |
| Playback | Play audio, pause, sentence tap navigation, prev/next |
| Speed | Change playback speed, verify audio rate |
| Progress | Partial progress saves, completion celebration |
| Offline | Cache text, airplane mode, verify playback works |
| Subscription | View paywall, restore purchases (StoreKit Testing) |
| Settings | Change voice, change language, manage subscription link, clear cache |

### Q: How does iOS simulator connect to local Docker backend?
**A**: **`localhost:3000`** — iOS Simulator can access host machine's localhost. Test scheme uses `http://localhost:3000` as API base URL.

### Q: How is test database managed?
**A**: **Reset per suite + seed data:**
1. Before each test suite: Reset database to clean state
2. Run seed script with test data
3. Execute tests
4. Tests can create additional data as needed

### Q: What services are mocked in iOS E2E tests?
**A**:

| Service | Real or Mock | Notes |
|---------|--------------|-------|
| Backend API | **Real** (Docker) | Full integration testing |
| RevenueCat | **Mock** | Use StoreKit Testing in Xcode |
| Sign in with Apple | **N/A** | No auth in MVP |
| Sentry | **Mock** | Don't send test errors |
| Analytics | **Mock** | Don't pollute production data |

### Q: How is StoreKit tested?
**A**: **Xcode StoreKit Testing:**
- Create `.storekit` configuration file in Xcode
- Define test products matching App Store Connect
- XCUITest can trigger purchases without real App Store
- RevenueCat SDK works with StoreKit Testing sandbox

---

## 20. Technical Decisions Summary

| Decision | Choice | Rationale |
|----------|--------|-----------|
| User accounts | None (anonymous) | RevenueCat handles subs, simplifies architecture |
| Subscription SDK | RevenueCat | Easier than raw StoreKit, better analytics |
| RevenueCat entitlement | Single "premium" | Simple, expandable later |
| Database | PostgreSQL | Prod parity, better JSON support |
| Navigation | Stack-based (no tabs) | Focused flow, simpler TCA state |
| Onboarding | 3 screens (Listen/Follow/Repeat) | Explains shadowing, minimal friction |
| Dark mode | System-follow only | No toggle needed, less complexity |
| Device support | iPhone only (portrait) | Focused MVP, iPad compatibility mode |
| Audio loading | Download fully first | Smooth playback, no buffering |
| Cache limit | None | User controls via Clear Cache |
| API versioning | /v1/ prefix | Future-proofing |
| Network retry | Endpoint-dependent | Content retries, analytics fire-and-forget |
| CI/CD | All repos, no auto-deploy | Quality gates, manual releases |
| Speech recognition | Not in MVP | Complexity, accent accuracy issues |
| Sentence timing | Whisper extraction | Automatable, accurate |
| Audio hosting | VPS filesystem | Simple, flexible content updates |
| Analytics | Custom + Umami | Free, lightweight, self-hosted |
| Regional pricing | App Store only | No backend logic needed |
| Recordings | Deferred | Needs audio subtraction R&D |
| Content sync | Poll on launch | Simple, no push infrastructure needed |
| Sentence tap | Jump and continue | Expected navigation behavior |
| Voice switch | Restart playback | Avoids timestamp mapping complexity |
| Content loading | Lazy (on open) | Reduces initial bandwidth, faster list load |
| Progress bar seeking | Disabled | Focus on sentence-level practice |
| Background audio | User setting (default off) | Respects user preference |
| Audio interruption | Stay paused | Standard iOS behavior |

---

## 21. Data & Privacy

### Q: Where is user data stored?
**A**:
- **Progress/preferences**: On-device only (local storage)
- **No server-side user data**: Anonymous users, no profiles
- **Recordings**: On-device only *(when implemented)*

### Q: What happens if user deletes app?
**A**: All local data deleted. No server data to persist.

### Q: What happens if subscription lapses?
**A**:
- Local data remains (progress, preferences)
- Access reverts to free tier
- RevenueCat detects lapsed status automatically

### Q: Do you store user voice data?
**A**: **No.** MVP does not capture or transmit user speech.

### Q: Age restrictions?
**A**: 13+ only. No COPPA compliance required.

### Q: How can users request data deletion?
**A**: **Settings screen** info text explaining:
- All data is stored on-device only
- Delete the app to remove all data
- Subscription can be cancelled via App Store

### Q: Is there a privacy policy?
**A**: **Yes, required for App Store.** Will be created covering:
- Data collected (minimal: anonymous analytics events)
- Data not collected (voice, location, contacts, personal info)
- Third-party services (RevenueCat, Sentry, App Store)
- On-device storage only

### Q: Is there a Terms of Service?
**A**: **Yes.** Link in Settings + shown during subscription flow. Covers:
- Subscription terms
- Content usage rights
- Disclaimer (not a replacement for formal education)

---

## 22. Localization

### Q: Is the UI multi-language?
**A**: **Yes.** Multi-language UI support planned.

### Q: Which languages?
**A**: MVP launch languages:
- **English** (default)
- **Spanish**
- **Ukrainian**

Auto-detect from device locale, with manual override in settings.

---

## 23. Branding & Visuals

### Q: What is the product name?
**A**: **TBD.** "Rafff" is the working/project name only.

### Q: Are there brand assets (icon, colors, logo)?
**A**: **Not yet.** Use placeholders for MVP:
- App icon: SF Symbols or runtime-generated
- Colors: System defaults / neutral palette
- Logo: Text placeholder

---

## 24. App Store

### Q: Category?
**A**: Education → Language Learning

### Q: Target release?
**A**: ~3 weeks *(aggressive but noted)*

---

## 25. Open Questions

### Resolved (All Rounds)
- ✅ Tech stack defined (Next.js, Prisma, TCA, SwiftUI)
- ✅ Database choice (PostgreSQL)
- ✅ User accounts (none — anonymous + RevenueCat)
- ✅ Subscription SDK (RevenueCat)
- ✅ RevenueCat entitlement (single "premium")
- ✅ Navigation structure (stack-based, no tabs)
- ✅ Onboarding (3 screens: Listen, Follow, Repeat)
- ✅ Settings screen contents (full list defined)
- ✅ Dark mode (system-follow only)
- ✅ Device support (iPhone only, portrait only)
- ✅ Audio loading (download fully, then play)
- ✅ Cache limit (none, user clears manually)
- ✅ Clear cache (user chooses what to clear)
- ✅ Voice metadata (name + accent + gender)
- ✅ API versioning (/v1/ prefix)
- ✅ Network retry (endpoint-dependent)
- ✅ CI/CD pipelines (all repos, no auto-deploy)
- ✅ Database backups (manual, server-level)
- ✅ Analytics event schema (with metadata)
- ✅ Sorting approach (smart default + filter tabs)
- ✅ Voice selection (min 2, user choice in settings)
- ✅ Level change (anytime in settings)
- ✅ Audio codec (AAC)
- ✅ Admin URL pattern (subdomain)
- ✅ Admin analytics (none, use external tools)
- ✅ Error logging (Sentry)
- ✅ Branding (placeholders for MVP)
- ✅ Accessibility (VoiceOver deferred)
- ✅ Content versioning (edits allowed, soft delete, update badge)
- ✅ Localization languages (English, Spanish, Ukrainian)
- ✅ Free content selection (admin-flagged)
- ✅ Speed control UX (preset buttons)
- ✅ Success metrics (retention, trial conversion)
- ✅ Sentence tap behavior (jump and continue)
- ✅ Progress bar seeking (disabled)
- ✅ Voice switch behavior (restart)
- ✅ Content loading strategy (lazy, on open)
- ✅ NEW badge duration (3 days)
- ✅ Admin session duration (30 days)
- ✅ Admin preview feature (yes)
- ✅ Bulk admin operations (yes)
- ✅ Restore purchases location (settings + subscription prompt)
- ✅ Manage subscription (settings, deep link)
- ✅ Text preview source (auto-generated)
- ✅ Audio buffering UI (disabled play + spinner)
- ✅ End of text (celebration + Practice Again / Next Text)
- ✅ Background audio (user setting, default off)
- ✅ Audio interruption (stay paused)
- ✅ Docker setup (backend + PostgreSQL)
- ✅ Hot reload (yes, via volume mounts)
- ✅ Migrations (auto-run on start)
- ✅ Seed data (yes)
- ✅ Production Docker (single container)
- ✅ E2E test scope (full coverage, Playwright + XCUITest)
- ✅ iOS ↔ Backend testing (localhost:3000)
- ✅ Test database (reset per suite + seed)
- ✅ Service mocking (StoreKit Testing, mock Sentry)
- ✅ Upload validation (format only)
- ✅ Timing JSON validation (schema + sequential timestamps)
- ✅ Failed upload recovery (partial state preserved)
- ✅ Concurrent editing (last write wins)
- ✅ Terms of Service (yes, in settings + subscription flow)
- ✅ Deep linking (not in MVP)

### Still Open
- ⏳ Rate limiting strategy (TBD, will decide during implementation)
- ⏳ Audio file size limits (TBD, validate during MVP testing)

---

## Appendix A: Deferred Features Backlog

| Feature | Notes | Priority |
|---------|-------|----------|
| User accounts | For cloud sync | High |
| User recordings | Needs audio subtraction | High |
| Push notifications | Re-engagement, new content | Medium |
| Pronunciation scoring | Whisper + accuracy algorithm | Medium |
| VoiceOver accessibility | Full screen reader support | Medium |
| iPad-optimized layout | Universal app | Low |
| Admin TTS integration | Generate audio in-panel | Low |
| Cloud backup/sync | Cross-device progress (needs accounts) | Low |
| CDN for audio | If VPS bandwidth insufficient | Low |
| Per-text voice switcher | In-text voice selection | Low |
| Deep linking | Share texts via URL | Low |

---

## Appendix B: API Endpoints Summary

**Content (iOS — anonymous, no auth):**
- `GET /v1/content/levels` — List levels with text counts
- `GET /v1/content/texts` — List texts by level (with preview)
- `GET /v1/content/texts/{id}` — Get full text + sentences
- `GET /v1/content/texts/{id}/audio/{voiceId}` — Get audio file
- `GET /v1/content/texts/{id}/timing/{voiceId}` — Get sentence timings
- `GET /v1/app/version` — Get minimum required app version

**Subscription:**
- `POST /v1/webhooks/revenuecat` — RevenueCat webhook (subscription events)

**Analytics:**
- `POST /v1/analytics/events` — Track anonymous events

**Admin (Web Panel):**
- `POST /v1/admin/auth/login` — Email/password login
- `POST /v1/admin/auth/logout` — Logout
- `GET /v1/admin/texts` — List all texts (with filters)
- `POST /v1/admin/texts` — Create text
- `GET /v1/admin/texts/{id}` — Get text details
- `PUT /v1/admin/texts/{id}` — Update text
- `DELETE /v1/admin/texts/{id}` — Soft delete
- `POST /v1/admin/texts/{id}/restore` — Restore soft-deleted
- `POST /v1/admin/texts/{id}/voices` — Add voice variant
- `PUT /v1/admin/texts/{id}/voices/{voiceId}` — Update voice
- `DELETE /v1/admin/texts/{id}/voices/{voiceId}` — Remove voice

---

## Appendix C: Screen Wireframes (ASCII)

### Levels (Home) Screen
```
┌─────────────────────────────────────────┐
│  Rafff                            ⚙️    │
├─────────────────────────────────────────┤
│                                         │
│  ┌─────────────────────────────────┐   │
│  │  🟢 Beginner                    │   │
│  │  ████████░░  8/10 completed     │   │
│  └─────────────────────────────────┘   │
│                                         │
│  ┌─────────────────────────────────┐   │
│  │  🟡 Intermediate+               │   │
│  │  ███░░░░░░░  3/10 completed     │   │
│  └─────────────────────────────────┘   │
│                                         │
│  ┌─────────────────────────────────┐   │
│  │  🔴 Advanced                    │   │
│  │  ░░░░░░░░░░  0/10 completed     │   │
│  └─────────────────────────────────┘   │
│                                         │
└─────────────────────────────────────────┘
```

### Text List Screen
```
┌─────────────────────────────────────────┐
│  ← Back          Beginner               │
├─────────────────────────────────────────┤
│  [All] [In Progress] [Completed]        │
├─────────────────────────────────────────┤
│  ┌─────────────────────────────────┐   │
│  │  Meeting New People             │   │
│  │  "Hello, my name is..."         │   │
│  │  ████░░  52%                    │   │
│  └─────────────────────────────────┘   │
│                                         │
│  ┌─────────────────────────────────┐   │
│  │  At the Coffee Shop      🔒 NEW │   │
│  │  "I'd like a coffee..."         │   │
│  │  Not started                    │   │
│  └─────────────────────────────────┘   │
│                                         │
│  ┌─────────────────────────────────┐   │
│  │  Daily Routines           ✓     │   │
│  │  "Every morning I wake..."      │   │
│  │  ██████████  Done               │   │
│  └─────────────────────────────────┘   │
└─────────────────────────────────────────┘
```

### Practice View
```
┌─────────────────────────────────────────┐
│  ← Back     Meeting New People          │
├─────────────────────────────────────────┤
│                                         │
│  Hello, my name is Sarah.               │
│                                         │
│  ┌─────────────────────────────────┐   │
│  │  Nice to meet you.              │ ← │
│  └─────────────────────────────────┘   │
│                                         │
│  Where are you from?                    │
│                                         │
│  I'm from New York.                     │
│                                         │
├─────────────────────────────────────────┤
│  ══════════●═══════════  0:45 / 2:30   │
│                                         │
│  [0.5x] [0.75x] [1x] [1.5x] [2x]       │
│                                         │
│      ◀◀      ▶️ Play      ▶▶      🔄   │
└─────────────────────────────────────────┘
```

---

## Appendix D: API Rate Limiting (TBD)

*To be defined during implementation. Considerations:*
- Content endpoints: Moderate limits (100 req/min)
- Analytics endpoint: Higher limits (1000 req/min)
- Admin endpoints: Lower limits, but with auth
- Download endpoints: Per-IP throttling if needed
