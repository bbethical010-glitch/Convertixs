# AGENT_RULES.md — Convertix Agent Operating Rules

## READ THIS FIRST — EVERY TIME

Before touching a single file, read this document completely.
These rules are non-negotiable. They exist because previous agents caused
cascading build failures, unauthorized architectural changes, and security
risks by skipping them.

---

## 1. BEFORE YOU START ANY TASK

Do these three things before writing a single line of code:

### 1A. Read the project state
Read these files in order:
1. `STATE.md` — understand what is currently true, what is blocked
2. `SPEC.md` — understand what the feature is supposed to do
3. `ARCHITECTURE.md` — understand where files go and how data flows
4. `AGENTS.md` — understand the hard rules specific to this project

### 1B. Understand the task scope
- Identify exactly which files need to change
- Identify which files must NOT be touched
- If the task is ambiguous, ask one focused question before proceeding
- Never expand scope beyond what was asked

### 1C. Confirm the current build is clean
Run before starting:
```
flutter analyze
```
If there are existing issues, report them before making any changes.
Do not add your changes on top of a broken baseline.

---

## 2. FORBIDDEN ACTIONS — NEVER DO THESE

### 2A. Files You Must Never Touch Without Explicit Permission

| File / Path | Why |
|---|---|
| `android/app/build.gradle.kts` → `applicationId` | Changing breaks Play Store update path |
| `android/app/build.gradle.kts` → `versionCode` | Must only increment, never decrement |
| `android/app/build.gradle.kts` → `targetSdkVersion` | Must stay at 36 or higher |
| `pubspec.yaml` → package names | Any package swap is an architectural decision requiring approval |
| `android/gradle/wrapper/gradle-wrapper.properties` | Gradle version changes break builds silently |
| `android/settings.gradle.kts` → AGP version | AGP changes cascade into build failures |
| `.gitignore` | Never remove entries, especially *.jks, *.pem, .env, key.properties |
| `lib/features/video_compression/log_profiles.dart` | Filter chains are tested; never invent new ones |
| Any `*.jks`, `*.pem`, `key.properties`, `.env` file | Security-critical; never create, modify, commit, or print these |

### 2B. Never Do These Actions

- **Never generate a keystore or signing key** — this is the user's responsibility
- **Never commit secrets** — `.env`, `*.jks`, `*.pem`, `key.properties` must never appear in git
- **Never run a Python/shell script to auto-fix Dart/Flutter errors** — fix them directly
- **Never swap a core dependency** (ffmpeg, riverpod, go_router, hive, etc.) without explicit user approval
- **Never create documentation files not in the approved list** — do not invent `task.md`, `notes.md`, etc.
- **Never combine multiple phases** — do exactly what the current phase asks, nothing more
- **Never report `flutter analyze` output you did not actually run** — always run it and paste the real output
- **Never self-approve architectural changes** — if something requires changing the system design, stop and ask
- **Never push to git without the user's instruction**
- **Never rename output files with timestamps** — use the `[original]_convertix.[ext]` pattern from `file_service.dart`

### 2C. The Approved Documentation Files

Only these files exist in the documentation system. Do not create others:

```
README.md
SETUP.md
SPEC.md
ARCHITECTURE.md
CONTRIBUTING.md
AGENTS.md
AGENT_RULES.md        ← this file
AGENT_PROMPTS.md
STATE.md
ROADMAP.md
```

If you feel you need a new doc file, ask first.

---

## 3. WHILE WORKING

### 3A. One Change at a Time
- Make the change
- Run `flutter analyze`
- Confirm zero issues
- Then make the next change
- Never stack multiple changes and analyze only at the end

### 3B. Dart/Flutter Code Rules
- All FFmpeg calls go through `core/services/ffmpeg_service.dart` only
- All backend calls go through `core/services/backend_service.dart` only
- All file I/O goes through `core/services/file_service.dart` only
- No business logic in screen files — screens only call providers
- Follow the Riverpod AsyncNotifier pattern defined in `ARCHITECTURE.md`
- No hardcoded file paths — always use `path_provider`
- No hardcoded strings for ad unit IDs — always use `ad_constants.dart`

### 3C. Android/Gradle Rules
- Gradle version must be 8.14 or higher
- AGP version must be 8.7.0 or higher
- `compileSdkVersion` must be 36
- `targetSdkVersion` must be 36
- `minSdkVersion` must stay at 24
- `applicationId` must always be `com.allformat.converter`
- `android.newDsl=false` must NOT be in `gradle.properties`

### 3D. Package Rules
- FFmpeg package: `ffmpeg_kit_flutter_new` (not the original retired package)
- Import paths: `package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart`
- AdMob: `google_mobile_ads` — never remove, never skip initialization
- AdMob init guard: always wrap in `if (Platform.isAndroid || Platform.isIOS)`
- History database: `hive_flutter` — approved dependency for conversion history (Phase 6D)
- Backend communication: Gradio REST API via SSE (not standard multipart FastAPI)
- Backend calls are keyed by Gradio `api_name` in `_apiNames`, never by numeric `fn_index`
- Backend URL: read from `.env` as `BACKEND_BASE_URL` (loaded by `flutter_dotenv` in `main.dart`);
  timeouts and size limits live in `lib/shared/constants/api_constants.dart`

---

## 4. AFTER COMPLETING ANY TASK

Do all of these steps in order. Do not skip any.

### Step 1 — Analyze
```
flutter analyze
```
Must return `No issues found`. If not, fix all issues before proceeding.

### Step 2 — Update Documentation
Update every markdown file affected by your changes:

| If you changed | Update these files |
|---|---|
| A feature or tool | `SPEC.md`, `STATE.md` |
| Folder structure | `ARCHITECTURE.md` |
| A dependency | `SETUP.md`, `AGENTS.md`, `AGENT_RULES.md` |
| Completed a phase | `ROADMAP.md`, `STATE.md` |
| A backend endpoint | `ARCHITECTURE.md`, `SETUP.md` |
| Any blocker resolved | `STATE.md` |

### Step 3 — Report to User
Provide a clear summary with:
- What was implemented (file by file)
- What was NOT done and why
- Actual `flutter analyze` output (copy-paste, not paraphrased)
- What the user should test manually on device
- Specific test steps for each changed feature

### Step 4 — Wait for User Verification
Do NOT proceed to the next phase or task until the user confirms:
- Device testing passed
- `flutter analyze` result verified by the user in their own terminal

### Step 5 — Git (only after user confirms)
Only commit when the user explicitly says to. Use this format:
```
git add .
git commit -m "[type]: [short description of what was done]"
git push origin main
```

Commit types: `feat`, `fix`, `docs`, `refactor`, `chore`

Examples:
```
feat: implement document convert screen and provider
fix: resolve Gradle version mismatch for Android build
docs: update STATE.md to mark Phase 2B complete
```

---

## 5. HANDLING ERRORS

### When You Encounter a Build Error
1. Read the full error message carefully
2. Identify the root cause — do not treat symptoms
3. Fix only what the error points to
4. Do not run auto-fix scripts
5. Do not change files unrelated to the error
6. Run `flutter analyze` after the fix
7. Report the root cause and fix clearly to the user

### When You Are Uncertain
- Do not guess
- Do not silently make assumptions
- Ask one focused question
- Wait for the answer before proceeding

### When flutter analyze Has Issues
- Fix every issue before reporting completion
- Never say "No issues found" without running the command
- Never use `// ignore:` suppression to hide real errors

---

## 6. PROJECT-SPECIFIC CONTEXT

### What Convertix Is
Mobile-only (Android + iOS) media and document conversion app.
Already live on Play Store as `com.allformat.converter` v1.0.8.
Next release: v1.0.9 (version code 16), targetSdk 36.

### Two Completely Separate Processing Paths
```
Media tools  →  ffmpeg_kit_flutter_new  (on-device, zero network)
Document tools  →  Gradio backend on Hugging Face  (network required)
```
Never mix these. Never route a media tool through the backend.
Never route a document tool through FFmpegKit.

### Backend
- **Read `.env`'s `BACKEND_BASE_URL` to learn the live backend — do not trust this doc's URL.**
  Trusting a stale URL here once caused the wrong Space to be probed and a working client to be
  "fixed" into a broken one.
- Live (as of last check): `https://pandeypratham-libreoffice-converter.hf.space`
  — `pandeypratham/libreoffice-converter`, Gradio **4.36.0**, `sdk: docker`, cpu-basic
- A second Space exists (`darkframeshzn/convertix-backend`, Gradio 6.24.0, ZeroGPU) and is **not**
  used by the app; its handlers carry `@spaces.GPU` and its quota is exhausted
- Protocol: `<prefix>/upload` → `POST <prefix>/call/<api_name>` → SSE
  `GET <prefix>/call/<api_name>/<event_id>` → `GET <prefix>/file=<path>`
- `<prefix>` is auto-detected by `_prefix()`: empty on Gradio 4, `/gradio_api` on Gradio 5+
- Download URLs must be built from the FileData `path`, never its `url` (Gradio 4.36 returns a
  malformed `url` for `/call/` jobs — see STATE.md → Backend Facts)
- Endpoint contract: `GET <prefix>/info` lists live `api_name`s and parameter order
- Keep-alive: cron-job.org pings the Space every 10 minutes

### Active Blockers (check STATE.md for latest)
- Play Store upload key reset: pending Google approval
- Document tools: ✅ working — all 5 verified by API probe and manually on-device

### Key Decisions Already Made
- AdMob: kept (ad-supported model)
- FFmpegKit: swapped to `ffmpeg_kit_flutter_new` (original retired April 2025)
- Backend: Gradio ZeroGPU (not FastAPI) for $0 hosting
- Gradle: 8.14, AGP: 8.7.0+
- iOS: planned for Phase 3

---

## 7. THE MOST IMPORTANT RULE

**If something feels outside the scope of what you were asked to do — stop and ask.**

Unauthorized changes to build configuration, dependencies, signing keys,
or documentation structure have caused real build failures in this project.

When in doubt: do less, report more, ask clearly.

---

## 8. PLAY STORE VERSION CODE RULE

The current deployed Play Store version code is tracked in STATE.md
under "Current Play Store Build".

Rules:
- NEVER use a versionCode that is less than or equal to the last 
  deployed version code
- Every new release AAB must have versionCode incremented by exactly 1
- After building a new AAB for upload, update STATE.md with the new 
  versionCode and versionName immediately
- Do NOT build a release AAB without first checking STATE.md for the 
  current deployed version code

Current values (update STATE.md first if these are wrong):
  Last deployed versionCode: 17
  Last deployed versionName: 1.0.10
  Next build must use versionCode: 18 minimum
