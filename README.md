# LandmarkAR 🏔️

An augmented reality iOS app that shows floating labels for nearby natural and historic landmarks using your iPhone's camera, GPS, and compass — powered by Wikipedia.

All of this was produced from the following prompt:

> I would like to develop an augmented reality app for my iphone that will, given my gps location and the location of natural and historic landmarks, show me information about the things in the field of view.


---

## What It Does

- Opens your iPhone camera in AR mode
- Detects your GPS location and compass direction
- Fetches nearby Wikipedia articles (landmarks, historic sites, parks, etc.) within 10 km
- Shows a floating label for each one — name + distance — in the direction it exists
- Tap any label to read the Wikipedia summary and open the full article

---

## Requirements

| Requirement | Minimum |
|-------------|---------|
| Xcode | 15.0+ |
| iOS | 17.0+ |
| Device | iPhone with ARKit support (iPhone 6s or newer) |
| Apple Developer Account | Free account is fine for testing on your own device |

> ⚠️ **ARKit does not work in the iOS Simulator.** You must run this on a real iPhone.

---

## Setup Instructions (Step by Step)

### Step 1 — Open the project
1. Unzip the downloaded folder
2. Double-click **LandmarkAR.xcodeproj** to open it in Xcode

### Step 2 — Sign the app with your Apple ID
1. In Xcode, click on **LandmarkAR** in the left panel (the blue icon at the top)
2. Select the **LandmarkAR** target
3. Go to the **Signing & Capabilities** tab
4. Under **Team**, click the dropdown and select your Apple ID
   - If you don't see your Apple ID, go to **Xcode → Settings → Accounts** and add it
5. Change the **Bundle Identifier** from `com.yourname.LandmarkAR` to something unique like `com.yourfirstname.LandmarkAR`

### Step 3 — Connect your iPhone
1. Plug your iPhone into your Mac with a USB cable
2. Trust the computer on your iPhone if prompted
3. In Xcode, click the device dropdown at the top (where it says a simulator name)
4. Select your iPhone from the list

### Step 4 — Build and run
1. Press **⌘R** or click the **▶ Play** button
2. The first time, iOS may say "Untrusted Developer" — go to:
   - iPhone Settings → General → VPN & Device Management → your Apple ID → Trust
3. Launch the app again

### Step 5 — Use it!
1. Allow location access when prompted
2. Allow camera access when prompted
3. Walk outside (GPS works best outdoors)
4. Point your phone around — labels will appear for nearby landmarks

---

## Project Structure

```
LandmarkAR/
├── LandmarkARApp.swift          # App entry point
├── Models/
│   └── Landmark.swift           # Data model + Wikipedia API response types
├── Services/
│   ├── LocationManager.swift    # GPS + compass (CoreLocation)
│   └── WikipediaService.swift   # Fetches landmarks from Wikipedia API
├── AR/
│   └── ARLandmarkView.swift     # AR camera + floating label placement
└── Views/
    ├── ContentView.swift         # Root view, state management
    └── LandmarkDetailSheet.swift # Detail sheet shown when you tap a label
```

---

## How It Works (Plain English)

1. **Location**: The app continuously reads your GPS coordinates and compass heading
2. **Fetch**: When you first open the app (and every 200m you move), it calls the Wikipedia GeoSearch API asking "what Wikipedia articles exist near this lat/lon?"
3. **Bearing math**: For each landmark, it calculates the compass direction from you to it
4. **AR placement**: ARKit is configured with `gravityAndHeading` alignment, meaning the AR world is anchored to real compass north. Labels are placed at a fixed 80m radius in the correct compass direction
5. **Projection**: Each 3D label position is projected onto the 2D camera screen so it appears in the right place
6. **Tap**: Tapping a label shows a sheet with the Wikipedia summary and a link to the full article

---

## Customizing the App

### Change how far it searches
In `WikipediaService.swift`, line 12:
```swift
private let searchRadiusMeters = 10_000  // change to 5000 for 5km, 20000 for 20km
```

### Change how many landmarks appear
In `WikipediaService.swift`, line 15:
```swift
private let maxResults = 20  // reduce to 10 for fewer labels
```

### Change label appearance
In `ARLandmarkView.swift`, in the `LandmarkLabelView.setup()` method — you can change colors, fonts, corner radius, etc.

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| Labels don't appear | Make sure you're outside with good GPS signal |
| Labels point wrong direction | Slowly wave your phone in a figure-8 to calibrate the compass |
| "Untrusted Developer" error | iPhone Settings → General → VPN & Device Management → Trust |
| App crashes immediately | Check that you've set a unique Bundle Identifier in Signing & Capabilities |
| No landmarks shown | You may be in a remote area with few Wikipedia articles nearby — try a city |

---

## Next Steps / Ideas

- Add a **radar/map view** showing all landmarks as a 2D overview
- Add **filtering** (nature only, historic only, etc.) using Wikipedia categories  
- Add **landmark images** from Wikipedia's thumbnail API
- Add **voice** — tap a label to hear it read aloud with AVSpeechSynthesizer
- Add **OpenStreetMap** as a second data source for more POIs
