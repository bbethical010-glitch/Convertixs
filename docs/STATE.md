# Project State

## Play Store Build Tracking

| Field | Value |
|---|---|
| Last uploaded versionCode | 26 |
| Last uploaded versionName | 1.1.3 |
| Current release versionCode | 27 |
| Current release versionName | 1.1.4 |
| Upload date | Oct 2026 |
| Next minimum versionCode | 28 |
| Signing keystore | new-upload-key.jks (generated Aug 25 2026) |
| Play App Signing | Enrolled — Google holds app signing key |

## Current Phase

Phase 1 — COMPLETED ✅
Phase 2A — COMPLETED ✅ (Backend Deployment)
Phase 2B — COMPLETED ✅ (Document Tools — all 5 verified on device)
Phase 5A — COMPLETED ✅ (Output Location Architecture — infrastructure only, not yet wired to tools)
Phase 5B — COMPLETED ✅ (Shared File-Source Selection — live in all 10 tools)
Phase 6C — COMPLETED ✅ (Bottom Navigation Shell)
Phase 6A — COMPLETED ✅ (Fix Output Naming Fallbacks - Removed timestamps, relying on sequential suffixing)
Phase 6D — COMPLETED ✅ (Implementation of Conversion History Database - Hive DB + 10 Tool Integration)
Phase 6E — COMPLETED ✅ (Accurate Progress, ETA & Cancellation)
Phase 6F — COMPLETED ✅ (Permissions Onboarding - First Launch Screen & Settings Fallbacks)
Phase 6B — COMPLETED ✅ (Native Android Intent Resolver via Intent.createChooser + Per-Tool Preference Memory)
Phase 5 — IN PROGRESS 🟡 (Product Polish, Shared UX & Output Structure)
in the v1.0.9 submission, and Phase 3 is blocked on the Play upload-key reset (not yet requested), so
Phase 5 costs no release time. Phase numbers were not renumbered — `Phase 3`/`Phase 4` are referenced
across `ARCHITECTURE.md`, `CLAUDE.md`, and this file, and churning them buys nothing.

## Status

🟢 Phase 2B complete — all 5 document tools working against the live backend, verified twice:
by direct API probe (correct page counts, valid `%PDF` / `PK` magic bytes) and manually on-device
(RMX3998, Android 16).

The client was migrated from the `/queue/join` + numeric `fn_index` protocol to
`POST /call/<api_name>` + SSE, so reordering Gradio tabs in `app.py` can no longer misroute calls.
Two things were learned the hard way during that migration — see "Backend Facts" below.

`flutter analyze` clean; `flutter test` passing; debug APK builds and installs.

---

## Completed Milestones

### ✅ Pre-Phase: Foundation
- [x] GitHub repository created (`editorav010-dev/Convertix`)
- [x] Repository cloned locally to `C:\Users\avspn\Desktop\projects\Convertix`

### ✅ Phase 0 — Project Initialization
- [x] Flutter project initialized with `applicationId = "com.allformat.converter"`
- [x] compileSdk 36, targetSdk 36, minSdk 24
- [x] versionCode 16, versionName "1.0.9"
- [x] All pubspec.yaml dependencies added
- [x] AndroidManifest.xml configured (permissions + AdMob meta-data)
- [x] go_router configured with all 11 routes (10 tools + licenses)
- [x] Riverpod ProviderScope set up
- [x] Theme implemented (Lucide icons, ColorScheme, TextTheme)
- [x] Home screen implemented — tool grid (5 media + 5 document tiles)
- [x] Shared services implemented (file_service, permission_service, ffmpeg_service, backend_service)
- [x] Shared widgets implemented (file_picker_button, conversion_progress, format_dropdown, error_card, success_card, banner_ad_widget)
- [x] AdMob initialized (conditional: Android/iOS only, skipped on desktop)

### ✅ Phase 1A — Windows Desktop Build Verification
- [x] `flutter run -d windows` succeeded
- [x] AdMob initialization wrapped with `Platform.isAndroid || Platform.isIOS` guard

### ✅ Phase 1B — Android Device Build & Dependency Fixes
- [x] Gradle downgraded to 8.5 (bypasses Windows file-lock bug in 8.6+)
- [x] AGP downgraded to 8.3.2
- [x] `resolutionStrategy` added forcing compatible AndroidX versions (activity:1.8.2, core:1.13.1)
- [x] `ffmpeg_kit_flutter_full_gpl` replaced with `ffmpeg_kit_flutter_new` (original Maven binaries deleted April 2025)
- [x] Android build succeeded: `√ Built build\app\outputs\flutter-apk\app-debug.apk`
- [x] App installed and launched on RMX3998 via Impeller (Vulkan)
- [x] `flutter analyze` — zero issues

### ✅ Phase 2 — Document Tools (Gradio backend)
- [x] Backend deployed to Hugging Face Space (Gradio 4.36.0, ZeroGPU)
- [x] `backend_service.dart` rewritten for Gradio protocol: `/upload` → `/queue/join` → SSE `/queue/data`
- [x] SSE stream decoded with `utf8.decoder.bind(...)` (correct `StreamTransformer<Uint8List,String>`)
- [x] Fixed output-path bug: providers now join `getOutputDir()` with the bare filename from `buildOutputPath` (was writing to a read-only CWD)
- [x] All 5 tools verified on RMX3998 (Android 16) with valid output files:
  - Document Convert — `.pptx` → PDF (3.3 MB, valid `%PDF`)
  - Image to PDF — 2 images → PDF (608 KB, valid `%PDF`)
  - Greyscale PDF — PDF → PDF (1.2 MB, valid `%PDF`)
  - Merge PDF — 2 PDFs → PDF (4.5 MB, valid `%PDF`)
  - Split PDF — 30-page PDF → ZIP of 6 PDFs (19.4 MB, valid `PK` archive)
- [x] `flutter analyze` — zero issues

---

## Roadmap Evolution

| When | Change | Reason |
|---|---|---|
| 2026-08-23 | **Phase 5 added** — Product Polish, Shared UX & Output Structure (sub-phases 5A–5G) | Product-polishing brief: predictable public output folders, shared file-source selection, "don't ask again" preference, unified Open/Show in Folder/Share, honest progress + ETA across all 10 tools |
| 2026-08-23 | Phase 5 **scheduled before Phase 3**; Phase 4 now requires Phase 5 | Storage behaviour should ship in the v1.0.9 submission; Phase 3 is blocked on the upload-key reset anyway |
| 2026-08-23 | Open questions **#1 and #3 resolved** — Kotlin platform channel; content-type-explicit folder names | 5A is unblocked and ready to plan |
| 2026-08-23 | **5A complete** — MediaStore output layer built (not yet wired to tools) | Storage architecture in place for 5D/5F |
| 2026-08-23 | **5B complete** — file-source selection live in all 10 tools; open questions **#4 and **5 resolved** | Picker enumeration works; permission-free property preserved |
| 2026-08-27 | **6C complete** — Built AppShell with BottomNavigationBar and three tabs (Home, History, Settings) | Foundation for 6D History tab and future settings tab |
| 2026-08-27 | **6A complete** — Removed timestamp-based filename fallback in output paths | Fallback was causing bloated/inconsistent naming; sequential suffixing is more robust |
| 2026-08-27 | **6D complete** — Hive DB setup, History models, HistoryService CRUD, UI implementation with Rename/Delete native actions, and wired up all 10 providers to log history automatically | Full history tracking implementation required before shipping |
| 2026-08-28 | **6E complete** — Accurate Progress, ETA, & Cancellation. Wired `CancelToken` and FFmpeg session IDs. | Granular cancellation of specific tasks is required for multi-tasking and ETA UX improvements |

---

## ❓ Open Questions — Phase 5 Storage & Pickers

Recorded rather than guessed. Each must be answered before the corresponding sub-phase is implemented.

### 1. MediaStore write mechanism — ✅ RESOLVED 2026-08-23

Outputs currently go to `getApplicationDocumentsDirectory()/convertix/outputs/` (`file_service.dart:18`)
— app-private and **invisible to Gallery by design**. Writing to `DCIM/`, `Movies/`, `Music/`, and
`Documents/` requires MediaStore inserts, and **no package in `pubspec.yaml` can do that**.

**Decision: a Kotlin platform channel** in `android/app/src/main/kotlin/`. Rationale — no new dependency
(`AGENT_RULES.md` §3D satisfied), and one mechanism covers all four collections. No available package
covers `Music/` *and* `Documents/` cleanly; gallery-oriented packages handle images/video only, which
would leave a second hand-rolled path for Audio Converter and the five document tools anyway.

The channel must return a **content URI** to Dart, not a filesystem path — `open_file` / `share_plus`
in 5D consume that.

### 2. minSdk 24 needs two write paths

`minSdk` is 24 and `targetSdk` is 36, so a single mechanism will not cover the range:

| API range | Mechanism |
|---|---|
| 29+ | MediaStore insert with `RELATIVE_PATH` |
| 24–28 | Direct file write + `MediaScannerConnection` scan |

`WRITE_EXTERNAL_STORAGE` is already correctly declared with `android:maxSdkVersion="28"`, so the legacy
branch is permitted. Untested on any API < 36 device — only RMX3998 (Android 16) is available.

### 3. Folder naming — ✅ RESOLVED 2026-08-23

**Decision: the brief's original, content-type-explicit naming.**

```text
DCIM/Images (Convertix)/
Movies/Videos (Convertix)/
Music/Audio (Convertix)/
Documents/Convertix/
  ├─ Image to PDF/
  ├─ Document Converter/
  ├─ Greyscale PDF/
  ├─ Merge PDF/
  └─ Split PDF/
```

Spaces and parentheses are valid in a MediaStore `RELATIVE_PATH`. Phase 5G must confirm the folders
render with the exact names across file managers and that no manager escapes or mangles the parentheses.

### 4. Third-party apps cannot be launched as pickers — ✅ RESOLVED 2026-08-23 (Phase 5B)

The brief asks to offer Google Photos / Files / Gallery as selectable *sources*. There is **no stable
contract** for launching a named third-party app as a picker — apps do not all export a picker activity.

**Implemented instead:** `FileSourceResolver.kt` enumerates `ACTION_GET_CONTENT` handlers with
`queryIntentActivities` and launches the *resolved component*, plus the Android Photo Picker
(`ACTION_PICK_IMAGES`) for image/video and SAF `ACTION_OPEN_DOCUMENT` as the always-present option.
This delivers the intended UX; it is not the literal mechanism the brief described.

`<queries>` entries were added to `AndroidManifest.xml` and confirmed present in the merged manifest.
Without them, Android 11+ package visibility returns an **incomplete** list — a silent failure, not
an error. Do not remove them.

### 5. Permission-free picker property — ✅ PRESERVED 2026-08-23 (Phase 5B)

File input goes through picker intents only (Photo Picker, SAF, resolved `GET_CONTENT`), which need
**no runtime permission on any API level**. That is the reason the app is portable across API 24–36,
and the 5B chooser preserves it.

`image_picker` remains declared in `pubspec.yaml` but **unused** — the Photo Picker is reached
directly through the platform channel, so the dependency is still dead weight. `file_picker` is
still used as the non-Android fallback and when the channel is unavailable.

### 6. Split PDF outputs a ZIP, not a PDF

`Documents/Convertix/Split PDF/` will contain a `PK` archive, which Gallery will correctly not index.
Undecided whether to save the ZIP as-is or extract it into a per-job folder of PDFs. Affects what
Open / Show in Folder / Share act on.

### 7. Progress is only partly measurable

| Path | Real percentage? |
|---|---|
| Video / audio via FFmpeg | **Yes** — `time=` against source duration |
| Image Converter | **No** — pure-Dart `package:image`, no progress hooks |
| 5 document tools | **No** — Gradio SSE emits `heartbeat\|generating\|error\|complete`, no percentage |

Per the brief, the two "No" rows get stage-based progress, not a fabricated bar. Making document
progress real would require emitting `gr.Progress()` from `backend/app.py` — a backend change, optional.

### 8. `permission_service.dart` decision is now forced

Already flagged below: dead code, and `_getAndroidVersion()` parses the Android *release* number (7–16)
instead of the API level (24–36), so its `>= 33` branch is unreachable. Phase 5A touches storage
permissions directly, so this must be fixed with a real `sdkInt` or deleted.

---

## 🔴 BLOCKER 1: Lost Android Signing Keystore

### What Is Known

The original `.jks` signing keystore from the previous workspace is lost.
The app (`com.allformat.converter`, version 1.0.8, version code 15) is live on the Play Store.
The next update must be version 1.0.9 (version code 16) targeting API 36.

### Two Possible Situations

**Situation A — Play App Signing IS enabled (most likely)**

Google Play App Signing (PASSigning) has been mandatory for all new apps since August 2021.
The app was published after this date, so it almost certainly has Play App Signing enabled.

If this is the case:
- Google holds the actual signing key (the key used on user devices)
- The lost `.jks` is only the *upload key* (used to authenticate uploads to Play Console)
- The upload key CAN be reset without losing your app or user base
- The actual app signing key is safe on Google's servers regardless

**Recovery Process (if Play App Signing is enabled):**

1. Verify enrollment: Go to Play Console → your app → Release → Setup → App integrity
   - If it shows "App signing key certificate" and a SHA-1 fingerprint → enrolled ✅
2. Generate a new upload keystore on any machine:
   ```
   keytool -genkeypair -v \
     -keystore new-upload-key.jks \
     -alias upload \
     -keyalg RSA -keysize 2048 -validity 10000
   ```
3. Export the public certificate (PEM):
   ```
   keytool -export -rfc \
     -keystore new-upload-key.jks \
     -alias upload \
     -file upload_certificate.pem
   ```
4. In Play Console → App integrity → scroll to "Request upload key reset"
   - You must be logged in as the **account owner** (not just an admin)
   - Upload the `upload_certificate.pem` file
   - Submit the request
5. Google approves in 24–48 hours and emails a confirmation with an activation timestamp
6. Do NOT upload a new AAB until Google's activation timestamp has passed
7. After activation: configure `android/key.properties` with the new keystore credentials
8. All future releases use the new `new-upload-key.jks`

**Situation B — Play App Signing is NOT enabled (unlikely)**

If your app was published without enrolling in Play App Signing (possible only for very old apps):
- The original `.jks` IS the signing key
- Without it, new uploads signed with a different key will be rejected
- Recovery options are extremely limited and would require contacting Google Support directly

### Current Status

❓ Enrollment status unknown — you must check Play Console
⬜ New upload keystore not yet generated
⬜ PEM not yet exported
⬜ Reset request not yet submitted

---

## Backend Facts (read before touching backend_service.dart)

### There are two Spaces — only one is live for the app

| Space | Gradio | SDK | Hardware | Used by app |
|---|---|---|---|---|
| `pandeypratham/libreoffice-converter` | **4.36.0** | docker | cpu-basic | **Yes** (`.env`) |
| `darkframeshzn/convertix-backend` | 6.24.0 | gradio | zero-a10g | No |

`.env` → `BACKEND_BASE_URL=https://pandeypratham-libreoffice-converter.hf.space`.

`AGENT_RULES.md` §6 previously named the `darkframeshzn` Space. Trusting that doc instead of reading
`.env` caused a full misdiagnosis: the wrong Space was probed, a working client was "fixed" into a
broken one, and the APK regressed. **Read `.env`'s `BACKEND_BASE_URL` to learn the live backend.**

The `darkframeshzn` Space is additionally unusable as-is: every handler in its deployed `app.py`
carries `@spaces.GPU`, so pure-CPU LibreOffice/PyMuPDF work is routed through the ZeroGPU scheduler
and its quota is exhausted (`{"title":"ZeroGPU quota exceeded"}`). If it is ever adopted, strip those
decorators and the `spaces` dependency, and move it to cpu-basic first.

### Route prefix is auto-detected

Gradio 4 serves the REST API at the root; Gradio 5+ moves it under `/gradio_api`. `_prefix()` probes
`GET /gradio_api/info` once per process and caches the result, so the client works against either
Space and survives a future Space upgrade.

### Download URL must be built from `path`, not `url`

Gradio 4.36 returns a malformed `url` for jobs submitted via `/call/<api_name>` — it mis-trims the
route (`/c/file=` for `convert`, `/cal/file=` for `merge_pdf`, `/call/i/file=` for `image_to_pdf`;
the corruption length tracks the api_name length) and those 404. Verified live: `url` → HTTP 404,
`<prefix>/file=<path>` → HTTP 200 with valid `%PDF`. The old `/queue/join` protocol did not trigger
this, which is why preferring `url` worked before the migration.

### Version pins mirror the deployed Space

`backend/requirements.txt` is the single source of truth (gradio 4.36.0 + the jinja2/starlette/
fastapi/pydantic pins the live image uses); `backend/Dockerfile` installs from it rather than
duplicating pins. Verified to resolve cleanly on Python 3.10/3.12 (36 packages, no conflicts).

---

## ⚠️ API Level Deadline

**Google Play Policy**

- Current target: Android 16 (API 36) ✅ Already configured
- **Deadline: August 31, 2026**
- v1.0.9 targets API 36 — compliant ✅

---

## Confirmed Facts

| Item | Value | Source |
|---|---|---|
| Play Store package name | `com.allformat.converter` | APK manifest / build.gradle.kts |
| Current version | 1.0.9 (version code 16) | pubspec.yaml + build.gradle.kts |
| min SDK | 24 (Android 7.0) | build.gradle.kts |
| target SDK | **36 (Android 16)** | build.gradle.kts |
| compile SDK | 36 | build.gradle.kts |
| Framework | Flutter + Dart | pubspec.yaml |
| Media library | `ffmpeg_kit_flutter_new` (v4.6.2) | pubspec.yaml |
| Icons | Lucide Icons | pubspec.yaml |
| Ads | Google AdMob | pubspec.yaml + AndroidManifest.xml |
| AdMob App ID | `ca-app-pub-2093403233028868~6019383556` | AndroidManifest.xml |
| File sharing | `open_file` + `share_plus` | pubspec.yaml |
| Backend | New Hugging Face Space (Phase 2) | Decision |
| Gradle version | 8.5 | gradle-wrapper.properties |
| AGP version | 8.3.2 | settings.gradle.kts |

---

## Active Decisions Made

| Decision | Choice |
|---|---|
| AdMob | ✅ Keep — ad-supported model retained |
| Backend | ✅ New Hugging Face Space (Phase 2) |
| minSdkVersion | ✅ Keep at 24 (Android 7.0) |
| targetSdkVersion | ✅ 36 (Android 16) — mandatory by Aug 31, 2026 |
| iOS | ✅ Planned — after Android is stable (Phase 3) |
| LOG/HDR compression | ✅ v1 requirement |
| FFmpeg package | ✅ `ffmpeg_kit_flutter_new` (community fork, 199 likes, 160/160 pub points) |
| Gradle/AGP | ✅ Gradle 8.5 + AGP 8.3.2 (bypasses Windows file-lock bug) |
| Output storage (Phase 5A) | ✅ Kotlin platform channel → MediaStore; no new package |
| Output folders (Phase 5A) | ✅ `DCIM/Images (Convertix)/`, `Movies/Videos (Convertix)/`, `Music/Audio (Convertix)/`, `Documents/Convertix/<Tool>/` |

---

## What Needs to Happen Next

**Phase 5 (in progress) — Product Polish, Shared UX & Output Structure**

- [x] **5A** — Output-location service: MediaStore-backed public folders per tool category
- [x] **5B** — Shared file-source selection (`<queries>` + `queryIntentActivities`, Photo Picker)
- [ ] **5C** — "Don't ask again" preference per media category + settings screen & `/settings` route
      — seam is ready: `FilePickerButton._resolveSource()` is the single interception point
- [ ] **5D** — Unified post-conversion actions (Open / Show in Folder / Share), consolidating the two success UIs
- [ ] **5E** — Honest progress + ETA model (real % where measurable, stage-based where not)
- [ ] **5F** — Integrate all 10 tools, `flutter analyze` after each — **until this lands, tools still
      write to app-private storage; 5A's service is built but unused**
- [ ] **5G** — API 24/29/33/36 compatibility matrix + full regression pass, including on-device
      verification of 5A (deferred from 5A — only an Android 16 device is available)
- [ ] Answer open questions 6 and 8 above (Split PDF ZIP handling; `permission_service.dart`)

**Carried over**

- [x] **Phase 2A** — Deploy Gradio backend to Hugging Face Space
- [x] **Phase 2B** — Implement 5 document tool screens with backend integration
- [x] **Phase 2B** — Verify all 5 document tools convert successfully on device (RMX3998)
- [x] Migrate client from `fn_index` to `api_name` calls, with auto-detected route prefix
- [x] Align `backend/` version pins to the deployed Space (Gradio 4.36.0)
- [x] Confirm Android 24–36 compatibility (minSdk merge, plugin floors, backend TLS chain)
- [ ] Decide fate of `core/services/permission_service.dart` — dead code, and its API-level
      detection is broken (see CLAUDE.md → Android version compatibility). **Now forced by Phase 5A.**
- [x] Replace Google test AdMob banner ID with production ID — **Android done**
      (`ca-app-pub-2093403233028868/1705631815`)
- [ ] Create an **iOS** banner ad unit in AdMob — `iosBannerAdUnitId` is still a Google test ID.
      The Android unit must not be reused; ad unit IDs are per-platform.
- [ ] Check Play App Signing enrollment in Play Console
- [ ] If enrolled: generate new upload key and submit reset request
