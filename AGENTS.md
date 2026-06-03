# Merch Counter — iOS Survey App

Tourist merch survey app for Fisherman's Wharf, SF. Collects demographics, clothing details, and weather; submits to Google Sheets. Offline-safe.

**Repo**: `https://github.com/d86us/merch-counter`

## Architecture

```
MerchCounter/
├── Config.swift                # AppAccent (yellow), .appFont() modifier
├── ContentView.swift           # NavigationStack root
├── MerchCounterApp.swift       # @main, flushes pending queue on launch
├── Models/
│   ├── FormState.swift         # @Observable form state, options arrays, toRecord()
│   ├── SurveyRecord.swift      # Codable record, sheetHeaders & sheetRowValues
│   └── ColorOption.swift       # Color definitions with brightness ordering
├── Services/
│   ├── GoogleSheetsService.swift  # OAuth2 JWT + Sheets API append/headers
│   ├── WeatherService.swift       # Open-Meteo API, cached 30 min, 10s timeout
│   └── SubmissionQueue.swift      # Actor, local JSON file, background upload
└── Views/
    ├── SurveyFormView.swift       # Main form + SegmentedControl, RadioGroup, MultiSelectGrid
    └── ColorSwatchPicker.swift    # Color swatch grid with custom tags
```

## Data Flow

1. User fills form → taps Submit
2. Weather fetched (best-effort, cached 30 min)
3. `SubmissionQueue.shared.add(record)` → saves to `Documents/submission_queue.json`
4. Haptic feedback (heavy impact), form resets immediately, toast "Saved!" shown for 1.5s, auto-scrolls to top
5. Button stays disabled for 2s cooldown to prevent double-tap
6. Queue auto-flushes in background to Google Sheets
7. Orange badge in nav bar shows pending count

## Google Sheets

- **Bundle resource**: `GoogleServiceAccount.json` in `MerchCounter/Resources/` (excluded from git via `.gitignore`)
- **Sheet ID**: Hardcoded in `GoogleSheetsService.init()`
- **Writing**: `valueInputOption=RAW` (no date parsing)
- **Columns**: `Date, Time, Weather, Temperature, Gender, Age, Demographic, Merch Types, Garment Colors, Print Colors, Design Features, Comment`

## Key Decisions

- `Color.appAccent` (yellow, defined in `Config.swift`) — single source for all highlight color
- `.appFont()` (`.subheadline` with weight param) — unified font everywhere
- Custom `SegmentedControl` with slider highlight instead of system Picker (reliable yellow bg)
- Custom inputs via alert popups (not inline)
- "+" buttons styled as capsule/chip, last item in grid
- Demographics: optional field (not required for submit)
- Weather: auto-fetched, gracefully falls back to cached/"Unknown" offline
- Pre-selected defaults reduce tap count (Gender=Male, Age=30, Merch=Hoodie, Garment=Black, Print=White, Design=[San Francisco, California])
- Yellow accent with black text for high contrast in sunlight
- Nav title shows "Total X Today Y" — submission counters instead of weather
- Project uses `PBXFileSystemSynchronizedRootGroup` — new files in `MerchCounter/` auto-included

## Build Requirements

- Xcode 26.2+, iOS 17.0+ deployment target
- Team: `ACHWBXGK4U`, bundle: `us.design86llc.MerchCounter`
- Service account JSON must exist in Resources or submit will fail
