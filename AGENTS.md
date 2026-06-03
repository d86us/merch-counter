# Merch Counter — iOS Survey App

Tourist merch survey app for Fisherman's Wharf, SF. Collects demographics, clothing details, and weather; submits to Google Sheets. Offline-safe.

## Architecture

```
MerchCounter/
├── Config.swift                # AppAccent color, .appFont() modifier
├── ContentView.swift           # NavigationStack root
├── MerchCounterApp.swift       # @main, flushes pending queue on launch
├── Models/
│   ├── FormState.swift         # @Observable form state, options arrays, toRecord()
│   ├── SurveyRecord.swift      # Codable record, sheetHeaders & sheetRowValues
│   └── ColorOption.swift       # Color definitions with brightness ordering
├── Services/
│   ├── GoogleSheetsService.swift  # OAuth2 JWT + Sheets API append/headers
│   ├── WeatherService.swift       # Open-Meteo API, cached 30 min, async
│   └── SubmissionQueue.swift      # Actor, local JSON file, background upload
└── Views/
    ├── SurveyFormView.swift       # Main form + RadioGroup, MultiSelectGrid
    └── ColorSwatchPicker.swift    # Color swatch grid with custom tags
```

## Data Flow

1. User fills form → taps Submit
2. Weather fetched (best-effort, cached 30 min)
3. `SubmissionQueue.shared.add(record)` → saves to `Documents/submission_queue.json`
4. Form resets immediately, "Saved!" alert shown
5. Queue auto-flushes in background to Google Sheets
6. Orange badge in nav bar shows pending count

## Google Sheets

- **Bundle resource**: `GoogleServiceAccount.json` in `MerchCounter/Resources/`
- **Sheet ID**: Hardcoded in `GoogleSheetsService.init()`
- **Writing**: `valueInputOption=RAW` (no date parsing)
- **Columns**: `Date, Time, Weather, Temperature, Gender, Age, Demographic, Merch Types, Garment Colors, Print Colors, Design Features, Comments`

## Key Decisions

- `Color.appAccent` (defined in `Config.swift`) — single source for all highlight blue
- `.appFont()` (`.subheadline` with weight param) — unified font everywhere
- Custom inputs via alert popups (not inline)
- "+" buttons styled as capsule/chip, last item in grid
- Demographics: optional field (not required for submit)
- Weather: auto-fetched, gracefully falls back to cached/"Unknown" offline
- Project uses `PBXFileSystemSynchronizedRootGroup` — new files in `MerchCounter/` auto-included

## Build Requirements

- Xcode 26.2+, iOS 17.0+ deployment target
- Team: `ACHWBXGK4U`, bundle: `us.design86llc.MerchCounter`
- Service account JSON must exist in Resources or submit will fail
