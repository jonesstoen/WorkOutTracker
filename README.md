#  WorkoutTracker

En moderne iOS-app for å loggføre treningsøkter, følge progresjon og importere økter fra Helse-appen.  
Bygget med **SwiftUI**, med fokus på enkelhet, ytelse og en utvidbar arkitektur.

---

##  Funksjoner

###  Live-økt
- Start ny økt med type/kategori (hurtigvalg)
- Legg til/endre øvelser underveis  
  - “+1 sett”-knapp  
  - Redigeringsark
- Notater under økta
- Flytende **“Pågående økt”**-banner på tvers av faner
- Banner skjules automatisk når:
  - Økta er åpen  
  - Økta fullføres  
  - Økta avbrytes  

---

###  HealthKit
- Onboarding for tillatelser
- Import av `HKWorkout`
  - Idempotent (henter kun nye siden sist)
- Mapping til egen `Workout`-modell  
  - Varighet  
  - Kalorier (lagres i notater)

---

###  Oversikt (Hjem)
- Hilsen og dato
- Nøkkelmetrikker:
  - Totalt sett
  - Totalt reps
  - Total vekt
- Mini-graf (7/30 dager) med %-endring
- Siste økter og hurtigvalg

---

### Kalender
- Lokaliserte ukedager
- Tilpasset brukerens første ukedag
- Utheving av:
  - Valgt dag
  - “I dag”
  - Dager med økter
- Liste over økter for valgt dag  
  - Swipe-to-delete

---

###  Historikk
- Liste gruppert per uke (år/uke)
- Naviger til detaljvisning
- Detaljvisning med:
  - Øvelser
  - Notater

---

###  Lagring og ytelse
- Automatisk lagring via `UserDefaults` (JSON)
- `PersistenceService`-abstraksjon
- Debouncet lagring i `WorkoutStore`
- Enkelt å bytte lagringslag senere  
  *(SwiftData / Core Data)*

---

### 🎨 Design og tilgjengelighet
- Dark Mode-støtte
- Konsistent bruk av systemkomponenter
- Fokus på lesbarhet og enkel interaksjon

---

## Skjermbilder

<p align="center">
  <img src="/WorkoutTracker/GithubAssets/HomeScreenSS.png" alt="Hjemskjerm" width="200">
  <img src="/WorkoutTracker/GithubAssets/ListViewSS.png" alt="Historikk" width="200">
  <img src="/WorkoutTracker/GithubAssets/CalendarViewSS.png" alt="Kalender" width="200">
  <img src="/WorkoutTracker/GithubAssets/NewExceriseSS.png" alt="Legg til øvelse" width="200">
</p>

---

##  Teknologi og arkitektur

### Teknologi
- **Språk:** Swift
- **UI:** SwiftUI (+ Charts for mini-graf)
- **Helse:** HealthKit (`HKHealthStore`, `HKSampleQuery`)
- **Lagring:** `PersistenceService`-protokoll  
  - Standard: `UserDefaultsPersistence` (JSON)

---

### App-tilstand
- `WorkoutStore` (`ObservableObject`)
- Debounced lagring

---

### Tjenester
- `WorkoutImportService`
  - Avhenger av `WorkoutRepository` + `HealthKitWorkoutFetching`
- `HealthKitService` / `HealthKitManager`
  - Autorisasjon og henting
- `HealthDataImporter`
  - Mapper `HKWorkout → Workout`

---

### Navigasjon og koordinering
- `LiveSessionCoordinator`
  - Håndterer banner-tilstand:
    - Aktiv
    - Synlig
    - Type
    - Kategori
    - Tid
- `HomeNavigationCoordinator`
  - `NavigationStack` i Hjem-fanen
  - Pusher `LiveWorkoutView` ved bannertap

---

### Testing
- **Swift Testing**
  - Unit-tester for import og lagring

---

##  Kom i gang

### Krav
- Xcode 26.2+
- iOS 17+

### Kjør
1. Åpne prosjektet i Xcode
2. Velg simulator eller koble til iPhone
3. Bygg og kjør (`⌘R`)
4. Gi HealthKit-tilgang ved første oppstart

---

## Import fra Helse-appen

- Onboarding hjelper deg å gi lesetilgang
- Idempotent import (kun nye økter siden sist)
- Importerte `HKWorkout` mappes til:
  - Kategori
  - Type
  - Notater (kalorier + varighet)

---

##  Testing

- Bruker Swift Testing
- Eksempler:
  - `WorkoutImportServiceTests`
    - Sikrer idempotent import
  - `WorkoutStoreTests`
    - Verifiserer lagring og mutasjoner

---

## Videre utvikling

- Flere grafer:
  - Volum per uke
  - PR-er
  - Kategori-fordeling
- Innstillinger:
  - kg/lbs
  - Standardvalg
  - Tema
- Widgets og Live Activities
- iCloud-synk / SwiftData / Core Data
- Utvidet tilgjengelighet:
  - VoiceOver-beskrivelser
  - Diagramforklaringer

---

<p align="center">
  Laget av <strong>Johannes Støen</strong> © 2025–2026
</p>
