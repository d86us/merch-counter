# Merch Counter — iOS Survey App

Tourist merch survey app for Fisherman's Wharf, SF. Collects demographics, clothing details, and weather; submits to Google Sheets. **Offline-first — core form + queue work without internet, only network ops gracefully fail.**

**Repo**: `https://github.com/d86us/merch-counter`

## Architecture

```
MerchCounter/
├── Config.swift                # AppAccent (yellow), .appFont() modifier
├── ContentView.swift           # NavigationStack root + mode toggle (Survey / Session)
├── MerchCounterApp.swift       # @main, flushes both queues on launch
├── Models/
│   ├── FormState.swift         # @Observable form state, options arrays, toRecord()
│   ├── SurveyRecord.swift      # Codable record → Design sheet
│   ├── SessionRecord.swift     # Codable record → Flow sheet
│   └── ColorOption.swift       # Color definitions grouped by family
├── Services/
│   ├── GoogleSheetsService.swift  # OAuth2 JWT + Sheets API (parameterized sheet name)
│   ├── WeatherService.swift       # Open-Meteo API, cached 30 min, 10s timeout
│   ├── SubmissionQueue.swift      # Actor, local JSON file, background upload, cumulative counters
│   └── SessionQueue.swift         # Actor, local JSON file, background upload (no counters)
└── Views/
    ├── SurveyFormView.swift       # Main per-person survey (Design sheet)
    ├── SessionObservationView.swift  # Session-level buyer/bag tracking (Flow sheet)
    └── ColorSwatchPicker.swift    # Color swatch grid with custom tags
```

## Data Flow

### Survey (Design sheet)
1. User fills form → taps Submit
2. Weather fetched (best-effort, cached 30 min, silently fails offline)
3. `SubmissionQueue.shared.add(record)` → saves to `Documents/submission_queue.json`, increments cumulative counter (UserDefaults)
4. Haptic feedback (heavy impact), form resets, toast "Saved!" shown for 1.5s, auto-scrolls to top
5. Button disabled while submitting (no double-tap)
6. Queue auto-flushes in background to Google Sheets
7. Orange badge in nav bar shows pending count; nav title shows cumulative "Total X Today Y"

### Session (Flow sheet)
1. Tap "Start Session" — timer begins, steppers enabled
2. Count buyers and bag fill levels during observation window
3. Tap "End & Submit" — stops timer, creates `SessionRecord`, enqueues to `SessionQueue`
4. Haptic + toast, resets for next session
5. Queue auto-flushes in background

## Google Sheets

### Sheets
- **Design** (renamed from Sheet1) — per-person survey data
- **Flow** (new) — session-level observation data

### Design Columns
`Date, Time, Weather, Temperature, Gender, Age, Demographic, Group, Count, Matching, Mode, Bag Sizes, Image, Typography, Merch Types, Garment Colors, Print Colors, Print Position, Comment`

### Flow Columns
`Session, Date, Start, End, Weather, Temp, PassByToCableCarSolo, PassByToCableCarGroup, PassByToCableCarFamily, PassByToWharfSolo, PassByToWharfGroup, PassByToWharfFamily, EnteredSolo, EnteredGroup, EnteredFamily, LeavingWithBagSolo, LeavingWithBagGroup, LeavingWithBagFamily, BagSmall, BagMedium, BagBig, Entered2Solo, Entered2Group, Entered2Family, LeavingWithBag2Solo, LeavingWithBag2Group, LeavingWithBag2Family, Bag2Small, Bag2Medium, Bag2Big`

### Auth
- **Bundle resource**: `GoogleServiceAccount.json` in `MerchCounter/Resources/` (excluded from git via `.gitignore`)
- **Sheet ID**: Hardcoded in `GoogleSheetsService.init()`
- **Writing**: `valueInputOption=RAW` (no date parsing)

## Key Decisions

- **Offline-first**: Everything must work offline. Both queues persist to local JSON. Weather fetch, sheet sync, and header writes silently fail. UI never blocks on network.
- Two sheets in one spreadsheet — Design for detailed surveys, Flow for session counts. Separate tabs, separate headers.
- `Color.appAccent` (yellow, defined in `Config.swift`) — single source for all highlight color
- `.appFont()` (`.subheadline` with weight param) — unified font everywhere
- Custom `SegmentedControl` with slider highlight instead of system Picker (reliable yellow bg)
- Custom inputs via alert popups (not inline)
- "+" buttons styled as capsule/chip, last item in grid
- Empty form on launch and after submit — no pre-selected defaults
- Demographics: required field
- Weather: auto-fetched, gracefully falls back to cached/"Unknown" offline
- Yellow accent with black text for high contrast in sunlight
- Nav bar principal shows mode picker (Survey / Session) as expandable menu
- Counter ("Total X / Today Y") is inline in Survey form, not in toolbar
- Project uses `PBXFileSystemSynchronizedRootGroup` — new files in `MerchCounter/` auto-included

## Build Requirements

- Xcode 26.2+, iOS 17.0+ deployment target
- Team: `ACHWBXGK4U`, bundle: `us.design86llc.MerchCounter`
- Service account JSON must exist in Resources or submit will fail
