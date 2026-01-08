# Project Specification v1.0

## Document Info
- **Last Updated**: 2025-01-08
- **Status**: Ready for Implementation
- **Project Name**: Rafff *(working name — final product name TBD)*

---

## 1. Product Overview

### Q: What is this project?
**A**: A language learning iOS app focused on the **shadowing technique** — users listen to audio, read along with highlighted text, and repeat aloud to practice pronunciation.

### Q: Who is the target audience?
**A**: Everyone learning English, ages 13+.

### Q: What makes it different?
**A**: Simple, focused shadowing experience. Some content free forever; subscription unlocks full library.

---

## 2. MVP Scope

### Q: What features are included in MVP?

| ✅ MVP | ❌ Deferred |
|--------|------------|
| Text browsing by level | User recordings feature |
| Audio playback (0.5x–2.0x speed) | Push notifications |
| Real-time sentence highlighting | Pronunciation accuracy scoring |
| Progress tracking (% complete) | Cloud backup/sync |
| Basic profile (no photo) | Profile photo |
| Subscription + free tier | Audio generation in admin |
| Admin web panel | Onboarding tutorial |
| Offline mode (downloadable content) | |
| Dark mode | |
| Voice selection (min 2 per text) | |

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

### Q: What's free vs paid?
**A**:
- **Free forever**: 2-3 texts per level (~6-9 total), **admin-flagged**
- **Subscription**: Full library access

Admin can mark any text as "free" via checkbox in content management panel.

### Q: What is the text/audio format?
**A**:
- **Text**: ~200 words soft limit (no hard enforcement)
- **Audio**: Sentence-segmented with timing metadata
- **Voices**: Minimum 2 voice variants per text, user-selectable in app settings

### Q: How is audio generated?
**A**:
- **Tool**: [VibeVoice-1.5B](https://huggingface.co/microsoft/VibeVoice-1.5B) *(may change)*
- **Process**: Manual generation for MVP
- **Future**: Integrate TTS into admin panel (post-MVP)

### Q: How are sentence timings created?
**A**: **Whisper transcription pipeline**:
1. Generate audio with VibeVoice (manual)
2. Run Whisper → extract sentence timestamps
3. Store as JSON alongside audio
4. iOS parses timestamps for highlighting sync

**Timing format**:
```json
{
  "sentences": [
    { "text": "Hello, welcome to the lesson.", "start": 0.0, "end": 2.3 },
    { "text": "Today we will practice greetings.", "start": 2.5, "end": 4.8 }
  ]
}
```

### Q: Where is content hosted?
**A**: Cloud storage on existing VPS.

### Q: What audio format?
**A**: **AAC** — universal support on iOS, Android, and Web. MP3 as fallback if needed.

---

## 4. User Features

### Q: How does the shadowing UI work?
**A**: Controls visible during practice:
- Text display with current sentence highlighted
- Play/Pause button
- **Speed preset buttons**: `0.5x` | `0.75x` | `1x` | `1.5x` | `2x` (default: 1x)
- Progress bar
- Restart button
- Previous/Next sentence buttons

### Q: What happens when user leaves mid-text?
**A**: Prompt: *"Resume where you left off?"* — user chooses continue or restart.

### Q: How is progress tracked?
**A**:
- **Completed**: Marked as "Done"
- **Partial**: Shows percentage (e.g., "52%")
- **Visible**: In text list view per level

### Q: How are texts sorted in the list?
**A**: **Smart default with filter tabs**:
- **Default sort**: In-progress first (by % ascending) → Not started → Completed
- **Filter tabs**: `All` | `In Progress` | `Completed`
- **New content**: "NEW" badge on recently added texts

### Q: Can users download content for offline use?
**A**: **Yes.** Full offline mode — users download texts + audio to device cache.

---

## 5. User Profile & Authentication

### Q: How do users authenticate?
**A**: **Anonymous until subscription.**
- No account needed for free content
- **Sign in with Apple** required at subscription
- No other auth methods in MVP

### Q: What profile fields exist (MVP)?
**A**:
| Field | Required | Notes |
|-------|----------|-------|
| Name | Optional | |
| Country | Optional | |
| Age | Optional | Must be 13+ |
| English level | Optional | Beginner / Intermediate+ / Advanced |

*Profile photo deferred to post-MVP.*

### Q: Can users change their level?
**A**: **Yes**, anytime in settings.

---

## 6. Monetization

### Q: What is the subscription model?
**A**:

| Plan | Price | Access |
|------|-------|--------|
| Free | $0 | 2-3 texts per level, forever |
| Trial | $0 | 7 days full access |
| Monthly | $1.99 | Full library |
| Yearly | $9.99 | Full library (~58% savings) |

### Q: Regional pricing?
**A**: Configured via **App Store Connect** price tiers only.
- +$1 for US, UK, Australia, Canada
- No backend pricing logic needed

---

## 7. Admin Panel

### Q: How do admins access the panel?
**A**: Separate web application (e.g., `admin.projectname.com`).

### Q: How do admins authenticate?
**A**: Email + password.

### Q: What is the content management workflow?
**A**:
1. Select level (Beginner / Intermediate+ / Advanced)
2. Create new text entry
3. Paste text content
4. Upload audio file(s) — multiple voices
5. Upload timing JSON (Whisper-generated)
6. Save & publish

### Q: Can admins generate audio in the panel?
**A**: **Not in MVP.** Audio generated manually with VibeVoice, then uploaded.

### Q: Can admins edit published content?
**A**: **Yes.** Edits allowed on published texts/audio.
- Cached content on user devices remains unchanged until re-downloaded
- New users see updated version

### Q: How does content deletion work?
**A**: **Soft delete → hard delete after 30 days.**
- Deleted content hidden from new users immediately
- Users with cached content retain access
- Permanent deletion after 30 days
- Allows recovery if deleted by mistake

---

## 8. Error Handling

| Scenario | Behavior |
|----------|----------|
| Audio fails to load | Show error message, log to analytics |
| No recordings yet | Show empty state *(deferred feature)* |
| Network disconnect | Graceful offline if content cached |
| Download fails | Retry option + error message |

---

## 9. Analytics

### Q: What analytics solution?
**A**: **Lightweight, self-hosted, free.**

- **MVP**: Custom endpoint — POST events to backend
- **If dashboards needed**: [Umami](https://umami.is/) (self-hosted)

### Q: What events to track?
**A**:
- App open / session start
- Text started / completed
- Subscription conversion (trial → paid)
- Audio load failures
- Download success/failure

### Q: What error logging solution?
**A**: **Sentry** — easy integration, good iOS/web support.

---

## 10. Technical Architecture

### Backend Stack
| Technology | Version/Notes |
|------------|---------------|
| **Runtime** | Next.js 16 |
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
| **Linting** | SwiftLint |
| **Testing** | Swift Testing |
| **Mutation Testing** | Mutter |

### Shared
- **Commit hooks**: Both repos
- **API Contract**: OpenAPI 3.1 (`shared/api-spec/openapi.yaml`)

### Infrastructure
| Component | Solution |
|-----------|----------|
| Backend hosting | Existing VPS (Docker) |
| Audio/content storage | VPS cloud storage |
| Analytics | Custom endpoint + optional Umami |
| Subscriptions | App Store (StoreKit 2) |

---

## 11. Technical Decisions Summary

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Speech recognition | Not in MVP | Complexity, accent accuracy issues |
| Sentence timing | Whisper extraction | Automatable, accurate |
| Audio hosting | VPS storage | Flexible content updates |
| Auth | Anonymous → Sign in with Apple | Minimum friction |
| User data storage | On-device only | Privacy, simplicity |
| Analytics | Custom + Umami | Free, lightweight, self-hosted |
| Regional pricing | App Store only | No backend logic needed |
| Recordings | Deferred | Needs audio subtraction R&D |

---

## 12. Data & Privacy

### Q: Where is user data stored?
**A**:
- **Progress/preferences**: On-device (local storage)
- **Profile**: Server-side (after account creation)
- **Recordings**: On-device only *(when implemented)*

### Q: What happens if user deletes app?
**A**: All local data deleted. Server profile persists unless deletion requested.

### Q: What happens if subscription lapses?
**A**:
- Local data remains
- Profile persists
- Access reverts to free tier

### Q: Do you store user voice data?
**A**: **No.** MVP does not capture or transmit user speech.

### Q: Age restrictions?
**A**: 13+ only. No COPPA compliance required.

---

## 13. Localization

### Q: Is the UI multi-language?
**A**: **Yes.** Multi-language UI support planned.

### Q: Which languages?
**A**: MVP launch languages:
- **English** (default)
- **Spanish**
- **Ukrainian**

Auto-detect from device locale, with manual override in settings.

---

## 14. Branding & Visuals

### Q: What is the product name?
**A**: **TBD.** "Rafff" is the working/project name only.

### Q: Are there brand assets (icon, colors, logo)?
**A**: **Not yet.** Use placeholders for MVP:
- App icon: SF Symbols or runtime-generated
- Colors: System defaults / neutral palette
- Logo: Text placeholder

---

## 15. App Store

### Q: Category?
**A**: Education → Language Learning

### Q: Target release?
**A**: ~3 weeks *(aggressive but noted)*

---

## 16. Open Questions

### Resolved (All Rounds)
- ✅ Tech stack defined (Next.js, Prisma, TCA, SwiftUI)
- ✅ Sorting approach (smart default + filter tabs)
- ✅ Voice selection (min 2, user choice)
- ✅ Level change (anytime)
- ✅ Audio codec (AAC)
- ✅ Admin URL pattern (subdomain)
- ✅ Error logging (Sentry)
- ✅ Branding (placeholders for MVP)
- ✅ Accessibility (VoiceOver deferred)
- ✅ Content versioning (edits allowed, soft delete)
- ✅ Localization languages (English, Spanish, Ukrainian)
- ✅ Free content selection (admin-flagged)
- ✅ Speed control UX (preset buttons)

### Still Open
*None critical for MVP. Spec is ready for API design.*

---

## Appendix: Deferred Features Backlog

| Feature | Notes | Priority |
|---------|-------|----------|
| User recordings | Needs audio subtraction | High |
| Push notifications | Re-engagement, new content | Medium |
| Pronunciation scoring | Whisper + accuracy algorithm | Medium |
| VoiceOver accessibility | Full screen reader support | Medium |
| Profile photo | Simple addition | Low |
| Onboarding tutorial | After core UX validated | Low |
| Admin TTS integration | Generate audio in-panel | Low |
| Cloud backup/sync | Cross-device progress | Low |
