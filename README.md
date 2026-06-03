# Merch Counter

iOS SwiftUI app for counting merchandise worn by tourists in the field. Data is submitted directly to Google Sheets.

## Requirements

- macOS with Xcode 15+
- iOS 17+ device for TestFlight deployment
- Google Cloud Platform project with Sheets API enabled

## Setup

### 1. Google Cloud — Service Account

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a project (or select existing)
3. Enable the **Google Sheets API**
4. Go to **IAM & Admin → Service Accounts**
5. Create a new service account (name it e.g. "merch-counter")
6. Click the three dots → **Manage keys** → **Add Key → Create New Key**
7. Choose **JSON** and download the file
8. Rename the downloaded file to `GoogleServiceAccount.json`
9. Copy it to: `Sources/MerchCounter/Resources/GoogleServiceAccount.json`
   (The `.process("Resources")` directive in Package.swift automatically bundles it.)

### 2. Google Sheet

1. Create a new Google Sheet
2. Share it with the service account email (e.g. `merch-counter@your-project.iam.gserviceaccount.com`) as **Editor**
3. Copy the **Spreadsheet ID** from the URL: `https://docs.google.com/spreadsheets/d/`**SPREADSHEET_ID**`/edit`

### 3. Open in Xcode

```bash
open Package.swift
```

Xcode will create a scheme for the iOS executable target.

### 4. Configure in App

- Tap the gear icon (or warning triangle) in the toolbar
- Paste the Spreadsheet ID
- Ensure `GoogleServiceAccount.json` is recognized (green checkmark)

### 5. Build & TestFlight

1. Select an iOS Simulator or your device as the run destination
2. Build and run (⌘R)
3. Fill out the form and tap **Submit Entry** to verify data appears in your sheet
4. Archive for TestFlight: **Product → Archive** → Distribute → TestFlight

## Data Format

Each submission appends one row to `Sheet1`:

| Date | Time | Gender | Age | Merch Types | Garment Colors | Print Colors | Motive | Style |
|------|------|--------|-----|-------------|----------------|--------------|--------|-------|

## Architecture

```
Sources/MerchCounter/
├── MerchCounterApp.swift      # @main App entry
├── ContentView.swift          # Root NavigationStack
├── Config.swift               # AppConfig + config sheet UI
├── Models/
│   ├── SurveyRecord.swift     # Codable record + sheet row formatter
│   ├── ColorOption.swift      # Color swatch definitions (16 colors)
│   └── FormState.swift        # @Observable form state
├── Views/
│   ├── SurveyFormView.swift   # Main scrollable form
│   └── ColorSwatchPicker.swift # Color grid + FlowLayout
└── Services/
    └── GoogleSheetsService.swift  # JWT auth + Sheets API append
```

## How It Works

- **JWT Auth**: The app signs a JWT with the service account's RSA private key (PKCS#8 → PKCS#1 conversion), exchanges it for an OAuth2 access token, then calls the Sheets API.
- **Form**: Single-page scrollable form with radio groups, segmented pickers, multiselect color swatches (16 extended colors), and text-based chip pickers — all with custom "+ Add" support.
- **Timestamp**: Automatically captured on submission (date + time).

## Security Notes

- The service account JSON key is bundled with the app. For TestFlight/internal distribution this is acceptable, but do **not** commit the real `GoogleServiceAccount.json` to version control (the `.example` file is fine).
- The service account has write access **only** to the specific sheet you shared with it.
