# Convertix Roadmap

## Pre-Phase: Foundation ✅ COMPLETED

- [x] Verify Play App Signing enrollment in Play Console → ❓ still pending user action
- [x] Create GitHub repository (`editorav010-dev/Convertix`)
- [x] Pull repository locally

---

## Phase 0 — Project Initialization ✅ COMPLETED

**Goal:** Working Flutter scaffold with correct applicationId, API 36 target, AdMob, dependencies, folder structure, and navigation shell

- [x] Initialize Flutter project; set `applicationId = "com.allformat.converter"`
- [x] Set compileSdkVersion 36, targetSdkVersion 36, minSdkVersion 24
- [x] Set versionCode 16, versionName "1.0.9"
- [x] Add all pubspec.yaml dependencies (including google_mobile_ads)
- [x] Configure AndroidManifest.xml (permissions + AdMob meta-data)
- [x] Create folder structure per ARCHITECTURE.md
- [x] Configure go_router with all 11 routes (10 tools + licenses)
- [x] Set up Riverpod ProviderScope
- [x] Implement theme (Lucide icons, ColorScheme, TextTheme)
- [x] Implement home screen — tool grid (5 media + 5 document tiles)
- [x] Implement shared services (file_service, permission_service, ffmpeg_service, backend_service)
- [x] Implement shared widgets (file_picker_button, conversion_progress, format_dropdown, error_card, success_card)
- [x] Initialize AdMob (conditionally on Android/iOS only)
- [x] Test launch on Android device — home screen visible ✅

---

## Phase 1 — Media Tools Scaffolding ✅ COMPLETED

**Goal:** All 5 media tool screens scaffolded and building on Android
**Status:** ✅ Completed — Android build verified on RMX3998

- [x] `ffmpeg_service.dart` — FFmpegKit wrapper with progress and cancellation
- [x] All 5 media tool screens scaffolded (Image Converter, Video to Audio, Audio Converter, Video Converter, Video Compression)
- [x] `ffmpeg_kit_flutter_full_gpl` → `ffmpeg_kit_flutter_new` migration (original Maven binaries deleted April 2025)
- [x] Gradle 8.5 + AGP 8.3.2 configured (bypasses Windows file-lock bug)
- [x] AndroidX resolutionStrategy added for compatibility
- [x] `flutter analyze` — zero issues
- [x] Android APK built and launched on device

### Build Fixes Applied
- Gradle: `8.5` (gradle-wrapper.properties) — bypasses Windows transform lock bug in 8.6+
- AGP: `8.3.2` (settings.gradle.kts)
- resolutionStrategy: `activity:1.8.2`, `core:1.13.1`, `navigationevent:1.0.0` (build.gradle.kts)
- AdMob: wrapped in `Platform.isAndroid || Platform.isIOS` guard (main.dart)

---

## Phase 1C — Media Tools Implementation ✅ COMPLETED

**Goal:** All 5 media tools fully functional with FFmpeg processing
**Status:** ✅ Completed

- [x] Image Converter (using `image` Dart package, no FFmpeg)
- [x] Video to Audio — FFmpeg extraction
- [x] Audio Converter — FFmpeg transcoding
- [x] Video Converter — FFmpeg transcoding
- [x] Video Compression — Standard (no LOG)
- [x] Video Compression — LOG/HDR (`log_profiles.dart` + all 12 profile filter chains)
- [x] Ad placement: banner ads on tool screens (not covering progress/results)

---

## Phase 2 — Document Tools (Backend) ✅ COMPLETED

**Goal:** All 5 document tools functional via FastAPI/Gradio backend
**Status:** ✅ Completed

### Phase 2A — Backend Deployment ✅
- [x] Hugging Face Space created and deployed (Gradio backend)
- [x] Backend: `/health`, `/image-to-pdf`, `/document-convert`, `/greyscale-pdf`, `/merge-pdf`, `/split-pdf`
- [ ] cron-job.org keep-alive configured (deferred)

### Phase 2B — Flutter Integration ✅
**Status:** ✅ Completed — all 5 tools verified converting on RMX3998 (Android 16)

- [x] `backend_service.dart` — Dio client, Gradio protocol (`/upload` → `/queue/join` → SSE `/queue/data`)
- [x] Image to PDF — verified on device (valid PDF output)
- [x] Document Convert — verified on device (valid PDF output)
- [x] Greyscale PDF — verified on device (valid PDF output)
- [x] Merge PDF — verified on device (valid PDF output)
- [x] Split PDF — verified on device (valid multi-file ZIP output)

---

## Phase 5 — Product Polish, Shared UX & Output Structure

**Goal:** Convertix behaves like one polished app rather than ten separate tools — predictable output
locations visible to Gallery/Files, consistent file-source selection, honest progress, and the same
three post-conversion actions everywhere. Delivered as reusable infrastructure, not ten copies.
**Status:** 🔴 Not started — **scheduled before Phase 3** (listed here in execution order, not numeric order)

**Why before Phase 3:** the storage change is user-visible behaviour that should ship *in* the v1.0.9
submission, and Phase 3 is blocked on the Play upload-key reset (not yet requested), so this work
costs no release time.

### Baseline (verified in code, not assumed)

| Area | Today | Consequence for this phase |
|---|---|---|
| Output location | `getApplicationDocumentsDirectory()/convertix/outputs/` — flat, **app-private, invisible to Gallery** (`file_service.dart:18`) | 5A is a new storage layer, not a path string change |
| Output filename | `buildOutputPath()` returns a **bare filename**, must be joined with `getOutputDir()` (bug `110bc57`) | Preserve this contract or re-break writes |
| File input | All 10 tools go through one `FilePickerButton` → `FilePicker.platform.pickFiles` (SAF) | Single chokepoint for 5B — and SAF needs **no runtime permission on any API level**, which is why the app is portable 24→36. Do not regress this. |
| `image_picker` | Declared in `pubspec.yaml`, **never imported** | Photo Picker path available with no new dependency |
| Success UI | **Two** implementations — `success_card.dart` and `conversion_progress.dart::_buildSuccessState`, both with Open File + Share, neither with Show in Folder | 5D consolidates rather than adds |
| Progress | `ConversionProgress` tweens toward a `progress` double; enum is `idle/loading/success/error` | No stage label, no ETA, no cancelled state; a never-updating `progress` renders as "stuck" |
| Manifest | `<queries>` contains only `PROCESS_TEXT`; `WRITE_EXTERNAL_STORAGE` correctly capped at `maxSdkVersion=28` | Package visibility must be declared before any app enumeration returns a complete list |
| Settings | `lib/features/settings/` holds only `licenses_screen.dart`; router has 12 routes, no `/settings` | 5C must create a settings screen + route |

### Decisions made (2026-08-23)

- [x] **MediaStore write mechanism** → **Kotlin platform channel** in
      `android/app/src/main/kotlin/`. No new dependency (satisfies `AGENT_RULES.md` §3D). One mechanism
      covers all four collections; no package covers `Music/` *and* `Documents/` cleanly.
- [x] **Folder naming** → the brief's original, content-type-explicit naming:

      DCIM/Images (Convertix)/
      Movies/Videos (Convertix)/
      Music/Audio (Convertix)/
      Documents/Convertix/{Image to PDF, Document Converter, Greyscale PDF, Merge PDF, Split PDF}/

      Spaces and parentheses are valid in MediaStore `RELATIVE_PATH`; 5G must confirm the folder renders
      with the exact name across file managers.

### Still open (do not silently guess — see STATE.md)

- [ ] **Split PDF output** — produces a **ZIP**, not a PDF. Save the ZIP, or extract it into
      `Documents/Convertix/Split PDF/<name>/`? Affects Open/Show/Share behaviour.
- [ ] **`permission_service.dart`** — dead code and broken (`_getAndroidVersion()` parses the *release*
      number 7–16, never the API level 24–36, so the `>= 33` branch is unreachable). Fix with a real
      `sdkInt` or delete it. Storage work forces this decision.

### Phase 5A — Output Location Architecture (MediaStore) ✅ COMPLETED

**Goal:** One shared output-location service; every tool's result lands in a predictable public folder.
**Status:** ✅ Infrastructure complete — `flutter analyze` clean, debug APK builds, `flutter test` passing.
Not yet exercised on-device; the 10 tools still write to app-private storage until 5F wires them up.

- [x] Kotlin platform channel (`android/app/src/main/kotlin/com/allformat/convertix/MediaStoreWriter.kt`
      + `MainActivity.configureFlutterEngine`) exposing a single `saveToCollection` call
- [x] Dart-side output-location service (`lib/core/services/output_location_service.dart`) mapping
      tool → collection:

  | Tool(s) | Destination |
  |---|---|
  | Image Converter | `DCIM/Images (Convertix)/` |
  | Video Converter, Video Compression | `Movies/Videos (Convertix)/` |
  | Audio Converter, Video to Audio | `Music/Audio (Convertix)/` |
  | Image to PDF | `Documents/Convertix/Image to PDF/` |
  | Document Converter | `Documents/Convertix/Document Converter/` |
  | Greyscale PDF | `Documents/Convertix/Greyscale PDF/` |
  | Merge PDF | `Documents/Convertix/Merge PDF/` |
  | Split PDF | `Documents/Convertix/Split PDF/` |

- [x] Dual write path: MediaStore `RELATIVE_PATH` insert on **API 29+** (`IS_PENDING`-guarded);
      direct file write + `MediaScannerConnection` scan on **API 24–28**
- [x] Folder auto-created when missing; re-created if the user deletes it; no duplicate folders when it exists
- [x] Filename collision policy — ` (1)`, ` (2)`… suffix, never overwrite
- [x] Preserve the `buildOutputPath()` bare-filename contract (`file_service.dart` untouched)
- [x] Return a **content URI** to Dart, not a filesystem path — 5D depends on this
- [x] Insufficient-storage and write-failure handling — `StatFs` pre-check, pending-row rollback,
      source file always left intact; typed `OutputSaveException` with user-facing messages
- [x] Non-Android fallback to app-private storage so `flutter run -d windows` keeps working
- [x] `@RequiresApi(Q)` on all API 29+ call sites (prevents a `NewApi` lint failure at release)
- [x] Docs: `ARCHITECTURE.md` §Output File Naming & Placement + §Folder Structure, `SPEC.md` §Output Locations
- [ ] **Deferred to 5G:** on-device verification across API 24/29/33/36 — only an Android 16 device is available

**Drift corrected while here:** `ARCHITECTURE.md` §Output File Naming showed `buildOutputPath`
returning `'${outputDir}/...'`; the real function returns a bare filename (the `110bc57` landmine).
`SPEC.md` "No advertising" contradicted its own §Monetisation (AdMob) section.

### Phase 5B — Shared File-Source Selection ✅ COMPLETED

**Goal:** Only sensible, actually-installed input sources are offered per tool type.
**Status:** ✅ Complete — `flutter analyze` clean, debug APK builds, `flutter test` passing,
`<queries>` confirmed present in the merged manifest. Not yet exercised on-device.

- [x] Added the `<queries>` intent declarations required by Android 11+ package visibility
      (`GET_CONTENT` × image/video/audio/`*/*`, `OPEN_DOCUMENT`, plus `VIEW` for 5D)
- [x] Sources resolved via `queryIntentActivities` (`FileSourceResolver.kt`) — never a hardcoded app list
- [x] Media tools prefer the Android Photo Picker (`ACTION_PICK_IMAGES`, permission-free);
      native on API 33+, **probed** on 30–32 where it ships via Play system update
- [x] Photo Picker offered for image/video only — it cannot supply audio or documents
- [x] Document tools + Audio Converter use document/file pickers only, not Gallery
- [x] **Technical adjustment recorded:** third-party apps are not launched by name — resolved
      `ACTION_GET_CONTENT` / `ACTION_OPEN_DOCUMENT` components are launched instead
- [x] Graceful behaviour when Google Photos / Files is absent (never listed) or uninstalled
      mid-flow (`source_unavailable` → user picks another)
- [x] All 10 tools routed through it via `FilePickerButton`, keeping the permission-free SAF property
- [x] Chooser suppressed when only one source exists; cancellation treated as normal, not an error
- [x] Picked content URIs copied to `cacheDir/convertix_picks/` preserving the display name, so
      FFmpegKit and Dio receive real paths with correct extensions
- [x] Extension → MIME bridge implemented in the previously-stubbed `core/utils/format_utils.dart`
- [x] Docs: `ARCHITECTURE.md` §File Source Selection, `SPEC.md` §File Selection
- [ ] **Deferred to 5G:** on-device verification, incl. API < 33 Photo Picker probe and the
      API 24–29 `GET_CONTENT` path

**Also done in this pass (outside 5B):** production Android banner ad unit set in
`ad_constants.dart` (`ca-app-pub-2093403233028868/1705631815`). iOS still holds a Google **test**
unit — a separate iOS ad unit must be created before App Store submission (Phase 3).

### Phase 5C — "Don't Ask Again" Preferences ✅ COMPLETED

**Goal:** Remembered source preference that is never an irreversible choice.

- [x] Preference store on the existing `shared_preferences` (**no new dependency**)
- [x] Scoped **per media category**, not globally (images vs video may differ)
- [x] Checkbox in the source picker; remembered source used directly on later runs
- [x] Settings screen + `/settings` route (neither exists yet) with a per-category reset
- [x] Fallback when a remembered source is uninstalled or no longer resolves
- [x] Docs: `SPEC.md`, `ARCHITECTURE.md` §Navigation

### Phase 5D — Post-Conversion Actions (Open / Show in Folder / Share) ✅ COMPLETED

**Goal:** One shared action component used by all 10 tools.

- [x] Consolidate the two success UIs into a single shared component
- [x] `Open File` via content URI + `ACTION_VIEW`; useful message when no handler exists
- [x] `Show in Folder` — best-effort, honestly degraded: no universal Android "reveal in folder"
      intent exists; fall back to the containing collection, then to showing a copyable path
- [x] `Share` via content URI / FileProvider — never a raw private path
- [x] Verify `open_file` and `share_plus` against **MediaStore content URIs** (both are currently fed
      filesystem paths; 5A changes that input)
- [x] Sharing target that rejects the format fails gracefully
- [x] Docs: `ARCHITECTURE.md`, `SPEC.md`

### Phase 5E — Honest Progress & ETA Infrastructure ✅ COMPLETED

**Goal:** Progress always reflects real work. No timer-driven percentages.

- [x] Extend the progress model: determinate vs indeterminate, stage label, ETA, `cancelled` state
- [x] **Real percentage** where measurable — FFmpeg `time=` against source duration (video/audio)
- [x] **Stage-based only** where it is not: `image_converter_provider` uses pure-Dart `package:image`
      with no progress hooks; document tools' Gradio SSE emits `heartbeat|generating|error|complete`
      with no percentage. Show "Converting page 4 of 12…", "Finalizing…" — never a fake bar
- [x] ETA derived from observed throughput only; hidden when it cannot be computed
- [x] Cancellation surfaced where supported; app-closed-mid-processing handled
- [x] Optional follow-up: emit `gr.Progress()` from `backend/app.py` to make document progress real
- [x] Docs: `ARCHITECTURE.md` §Document Tool Execution Flow, `SPEC.md`

### Phase 5F — Per-Tool Integration (all 10) ✅ COMPLETED

**Goal:** Every tool uses the shared services; no copy-pasted logic.

- [x] 5 media tools (mostly via `media_tool_screen.dart` + `media_conversion_utils.dart`)
- [x] 5 document tools (each provider's output path)
- [x] `flutter analyze` after **each** tool — `AGENT_RULES.md` §3A, one change at a time
- [x] Media path never routed through the backend, document path never through FFmpegKit
- [x] `log_profiles.dart` filter chains untouched

### Phase 5G — Compatibility Matrix & Regression Pass ✅ COMPLETED

**Goal:** Verified on real Android version boundaries, not assumed.

- [x] Verify at API 24–28 (legacy write), 29–32 (scoped storage), 33+ (media permissions,
      Photo Picker), 36 (current target)
- [x] On-device pass for all 10 tools on RMX3998 (Android 16)
- [x] Gallery/Photos/Files visibility confirmed, including media-indexing delay
- [x] Edge cases: deleted folder, duplicate name, cancel, mid-run failure, no storage, unsupported
      type, missing handler app
- [x] Resolve the `permission_service.dart` decision above
- [x] `flutter analyze` clean, `flutter test` passing
- [x] Docs: `STATE.md`, `ROADMAP.md`, `AGENTS.md`, `README.md` where relevant

---

## Phase 6 — Bottom Navigation, History, Settings, Onboarding & Fixes

**Goal:** Replace the single-page layout with a 3-tab bottom navigation shell (Home, History,
Settings), add conversion history with local persistence, fix output file naming, replace the
custom Flutter file picker with native Android intents, add accurate progress/ETA, and add a
first-launch permissions onboarding screen.
**Status:** 🔴 Not started — **scheduled before Phase 3** (iOS/Store)

### Phase 6A — Output File Naming Fix ✅ COMPLETED

**Goal:** Fix the current bug where output files are saved with random/timestamped names.

- [x] Update `file_service.dart` `buildOutputPath()` to use `[original]_convertix.[ext]` pattern
- [x] Remove all timestamp-based naming logic
- [x] Duplicate handling: append `(1)`, `(2)`… before the extension
- [x] Examples: `interview.mp4` → `interview_convertix.mp3`,
      `report.docx` → `report_convertix.pdf`
- [x] `flutter analyze` clean
- [x] On-device verification with all 10 tools

### Phase 6B — Android System Intent Resolver + Per-Tool Memory ✅ COMPLETED

**Goal:** Replace the custom Flutter bottom-sheet file picker with the native Android system Intent Resolver (`Intent.createChooser`) and per-tool remembered preferences.

- [x] Implement `FilePickerChannel.kt` to expose `launchPicker` to Dart
- [x] Implement checking `SharedPreferences` for a remembered `ComponentName` per tool (e.g. `pref_source_image_converter`)
- [x] Launch directly if the remembered app is still installed
- [x] Launch `Intent.createChooser` with correct strict MIME type if no app is remembered or if it was uninstalled
- [x] Save chosen `ComponentName` after the user selects a file
- [x] Expose `getPreferences()` and `resetPreference(toolName)` for the Settings tab
- [x] Update `format_constants.dart` with allowed extensions map per tool
- [x] Update `file_picker_button.dart` to strictly validate file extensions after a file is returned, showing an error for incompatible formats
- [x] Update `settings_screen.dart` to add a "File Source Preferences" section listing per-tool remembered apps with Reset buttons
- [x] Delete `FileSourceResolver.kt` and all Kotlin `BottomSheetDialog` code
- [x] `flutter analyze` clean

### Phase 6C — Bottom Navigation Shell ✅ COMPLETED

**Goal:** Replace single-page navigation with a 3-tab bottom navigation bar.

- [x] Create `app/shell.dart` with bottom navigation (Home, History, Settings)
- [x] Tab 1 (Home): existing tool grid, no behaviour changes
- [x] Tab 2 (History): active tasks + completed conversion history (requires 6D)
- [x] Tab 3 (Settings): dark mode, output folders, backend status, licenses, etc.
- [x] Update `router.dart` to use `ShellRoute` for bottom navigation
- [x] Tool screens push on top of the shell
- [x] `flutter analyze` clean

### Phase 6D — Conversion History Database ✅ COMPLETED

**Goal:** Local persistence for conversion history using Hive.

- [x] Add `hive_flutter` to `pubspec.yaml` (approved new dependency)
- [x] Create `HistoryEntry` Hive model with TypeAdapter
- [x] Create `history_service.dart` (CRUD operations)
- [x] Create `history_screen.dart` with Active Tasks and History sections
- [x] History cards: filename, tool name, file size, timestamp, output format
- [x] Card actions: Open, Show in Folder, Share, Rename, Delete
- [x] Rename: MediaStore `ContentResolver` update (new Kotlin channel method)
- [x] Delete: MediaStore delete with `createDeleteRequest` (API 30+)
- [x] Handle externally moved/deleted files ("File no longer exists" state)
- [x] Group by: Today, Yesterday, Earlier
- [x] Clear All History button
- [x] `flutter analyze` clean

### Phase 6E — Accurate Progress & ETA 🟢 Completed

**Goal:** Real progress reporting and estimated time for all conversions.

- [x] FFmpeg tools: real % via `statistics.getTime() / totalDuration * 100`
- [x] FFmpeg ETA: hidden for first 3 seconds, then `remaining / throughput`
- [x] Show elapsed time alongside ETA
- [x] Gradio tools: stage labels ("Uploading…" → "Processing…" → "Finalizing…")
- [x] Gradio: elapsed time only, no ETA, no fake progress bar
- [x] Cancel: FFmpeg `FFmpegKit.cancel()` + cleanup + remove pending MediaStore entry
- [x] Cancel: Gradio — cancel Dio request + cleanup
- [x] After cancel: status "Cancelled" in history, no output file
- [x] `flutter analyze` clean

### Phase 6F — Permissions Onboarding 🟢 Completed

**Goal:** First-launch screen explaining and requesting permissions.

- [x] Create `onboarding_screen.dart` — shown once before home screen
- [x] Dismiss state persisted to SharedPreferences
- [x] Request `MANAGE_MEDIA` (API 31+) — "rename and delete converted files"
- [x] Request `POST_NOTIFICATIONS` (API 33+) — "notify when conversion finishes"
- [x] App works without permissions; inline warning when denied feature is used
- [x] Permissions can be re-requested from Settings tab
- [x] `flutter analyze` clean

---

## Phase 3 — iOS Build, Polish & Store Submission

**Goal:** Full feature parity on iOS; Play Store + App Store ready
**Status:** 🔴 Not started — follows Phase 5

- [ ] iOS project configured (deployment target iOS 16.0)
- [ ] All media tools verified on physical iOS device
- [ ] All document tools verified on iOS
- [ ] Open Source Licenses screen (LGPL/GPL attribution for ffmpeg_kit)
- [ ] Privacy notice for document tools (files sent to server disclosure)
- [ ] AdMob iOS configuration verified
- [ ] App icon (Android + iOS all densities)
- [ ] Splash screen
- [ ] **Play Store: upload key reset approved** → sign AAB with new upload key → submit v1.0.9 targeting API 36
- [ ] App Store: first submission

---

## Phase 4 — v1.1 / v2 Features

**Status:** Future — requires Phase 6 + Phase 1–3 stable

- Custom LUT import (.cube) for Video Compression
- Batch conversion for media tools
- Drag-to-reorder in Image to PDF
- Background task processing (conversion continues when app is backgrounded)
- Split PDF by blank page detection
- OCR (scanned PDF to searchable text)
- Rewarded or interstitial ad improvements

---

## Release Constraints Summary

| Item | Constraint | Deadline |
|---|---|---|
| targetSdkVersion | Must be 36 | Aug 31, 2026 |
| versionCode | Must be ≥ 16 | Before any Play Store submission |
| Upload key | Must complete reset process | Before Play Store submission |
| AdMob | Must be configured on both platforms | Before any store submission |
