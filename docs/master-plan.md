# Country Trivia App — Master Plan

## 1. Overview

A Flutter quiz app that shows a flag image and asks the user to pick the matching country from four options. Points are awarded based on how quickly the user answers. Solved flags and total points persist across app restarts using `SharedPreferences`. State management follows the **MVVM pattern** with the **Provider** package.

---

## 2. API & Data Sources

### 2.1 Country Data (names + ISO codes)

The original REST Countries API (v1–v4) linked in the Postman docs (`documenter.getpostman.com/view/1134062/T1LJjU52`) has been **deprecated** and all requests now return:

```json
{
  "success": false,
  "errors": [{ "message": "This API version has been deprecated." }]
}
```

The new **v5 API** (`https://api.restcountries.com/countries/v5`) requires a paid API key (`Authorization: Bearer YOUR_API_KEY`). The free demo key returns only a single sample record.

**Decision:** Use the **ISO 3166-1 country dataset** mirrored on GitHub as a drop-in replacement. It contains the same country names and alpha-2 codes that REST Countries sourced, and requires **no authentication**:

```
https://raw.githubusercontent.com/lukes/ISO-3166-Countries-with-Regional-Codes/master/all/all.json
```

Response shape (array of objects):

```json
[
  {
    "name": "Afghanistan",
    "alpha-2": "AF",
    "alpha-3": "AFG",
    "country-code": "004",
    "region": "Asia",
    "sub-region": "Southern Asia"
  }
]
```

### 2.2 Flag Images

Flag CDN (no auth required, as specified by the user):

```
https://flagcdn.com/w320/{iso}.png
```

Where `{iso}` is the lowercased alpha-2 code (e.g., `https://flagcdn.com/w320/us.png`).

---

## 3. Points System

| Attempt | Points |
|---------|--------|
| 1st try (correct on first selection) | 10 |
| 2nd try (correct on second selection) | 8 |
| 3rd try (correct on third selection) | 5 |
| All 3 tries exhausted (incorrect) | 0 |

- The correct answer is **revealed** after the third failed attempt.
- After each round (correct or exhausted), the solved flag's ISO code is persisted so it never appears again.
- Points accumulate and are persisted across sessions.

---

## 4. MVVM Architecture with Provider

```
lib/
├── main.dart                      # App entry, MultiProvider setup
├── models/
│   └── country.dart               # Country data model (name, isoCode)
├── services/
│   ├── country_service.dart       # Fetches & caches country list from API
│   └── storage_service.dart       # SharedPreferences wrapper (solved flags + score)
├── viewmodels/
│   └── trivia_viewmodel.dart      # Game logic: current question, score, attempts
├── views/
│   ├── trivia_view.dart           # Main quiz screen (orchestrator)
│   ├── widgets/
│   │   ├── flag_display.dart      # Flag image with loading/error states
│   │   ├── answer_button.dart     # Single answer option button
│   │   ├── score_header.dart      # Progress bar + score display
│   │   └── result_overlay.dart    # Round result (correct / out of tries)
└── utils/
    ├── constants.dart             # API URLs, point values, pref keys
    └── app_theme.dart             # ColorScheme, ThemeData
```

### 4.1 Responsibilities

| Layer | Responsibility |
|-------|---------------|
| **Model** (`country.dart`) | Immutable data class: `name`, `isoCode`. JSON deserialization. |
| **Service** (`country_service.dart`) | HTTP GET to fetch countries, parse JSON, return `List<Country>`. One-time fetch, cached in memory. |
| **Service** (`storage_service.dart`) | Read/write `solvedIsoCodes` (JSON string list) and `totalScore` (int) via SharedPreferences. |
| **ViewModel** (`trivia_viewmodel.dart`) | Holds game state: current question, options, attempts used, score, solved set. Exposes `answer(String)`, `nextQuestion()`, `reset()`. Extends `ChangeNotifier`. |
| **View** (`trivia_view.dart`) | Watches `TriviaViewModel` via `context.watch`. Renders flag, options, score. Handles user taps. |

### 4.2 State Flow

```
User taps answer button
        │
        ▼
TriviaViewModel.answer(isoCode)
        │
        ├── Correct? → award points (10/8/5), mark solved, show result overlay
        │
        └── Wrong?  → increment attempts
                         │
                         ├── attempts < 3 → disable that button, allow retry
                         │
                         └── attempts == 3 → reveal correct answer, mark solved, 0 points
```

---

## 5. Detailed Component Design

### 5.1 `country.dart` — Model

```dart
class Country {
  final String name;
  final String isoCode; // alpha-2, e.g. "US"

  const Country({required this.name, required this.isoCode});

  factory Country.fromJson(Map<String, dynamic> json) {
    return Country(
      name: json['name'] as String,
      isoCode: json['alpha-2'] as String,
    );
  }
}
```

### 5.2 `country_service.dart` — API Service

```dart
class CountryService {
  static const String _url =
      'https://raw.githubusercontent.com/lukes/ISO-3166-Countries-with-Regional-Codes/master/all/all.json';

  Future<List<Country>> fetchCountries() async {
    final response = await http.get(Uri.parse(_url));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((e) => Country.fromJson(e)).toList();
    }
    throw Exception('Failed to load countries');
  }
}
```

### 5.3 `storage_service.dart` — Persistence

```dart
class StorageService {
  static const String _solvedKey = 'solved_iso_codes';
  static const String _scoreKey = 'total_score';

  Future<Set<String>> loadSolved() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_solvedKey) ?? [];
    return list.toSet();
  }

  Future<void> saveSolved(Set<String> solved) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_solvedKey, solved.toList());
  }

  Future<int> loadScore() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_scoreKey) ?? 0;
  }

  Future<void> saveScore(int score) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_scoreKey, score);
  }
}
```

### 5.4 `trivia_viewmodel.dart` — Game Logic

```dart
class TriviaViewModel extends ChangeNotifier {
  final CountryService _countryService;
  final StorageService _storageService;

  List<Country> _allCountries = [];
  Set<String> _solved = {};
  int _score = 0;
  int _attempts = 0;
  Country? _correctCountry;
  List<Country> _options = [];
  bool _roundOver = false;
  bool _isLoading = true;
  String? _lastError;

  // Getters
  int get score => _score;
  int get attempts => _attempts;
  Country? get correctCountry => _correctCountry;
  List<Country> get options => _options;
  bool get roundOver => _roundOver;
  bool get isLoading => _isLoading;
  String? get lastError => _lastError;
  int get solvedCount => _solved.length;

  // Points per attempt index (0-based): [10, 8, 5]
  static const List<int> _pointsPerTry = [10, 8, 5];

  Future<void> init() async {
    _solved = await _storageService.loadSolved();
    _score = await _storageService.loadScore();
    _allCountries = await _countryService.fetchCountries();
    _generateQuestion();
    _isLoading = false;
    notifyListeners();
  }

  void _generateQuestion() {
    final available = _allCountries.where((c) => !_solved.contains(c.isoCode)).toList();
    if (available.isEmpty) return; // All solved — edge case

    available.shuffle();
    _correctCountry = available.first;

    // Pick 3 random distractors from available (excluding correct)
    final distractors = available.skip(1).take(3).toList();
    _options = [_correctCountry!, ...distractors]..shuffle();
    _attempts = 0;
    _roundOver = false;
  }

  void answer(String isoCode) {
    if (_roundOver || _correctCountry == null) return;

    if (isoCode == _correctCountry!.isoCode) {
      _score += _pointsPerTry[_attempts];
      _solved.add(_correctCountry!.isoCode);
      _storageService.saveScore(_score);
      _storageService.saveSolved(_solved);
      _roundOver = true;
    } else {
      _attempts++;
      if (_attempts >= 3) {
        _solved.add(_correctCountry!.isoCode);
        _storageService.saveSolved(_solved);
        _roundOver = true;
      }
    }
    notifyListeners();
  }

  void nextQuestion() {
    _generateQuestion();
    notifyListeners();
  }
}
```

### 5.5 `trivia_view.dart` — Main Screen

Layout (top to bottom):

1. **ScoreHeader** — "Score: X" + "Solved: Y" + linear progress bar
2. **FlagDisplay** — `Image.network('https://flagcdn.com/w320/${iso}.png')` with loading spinner and error fallback
3. **"Which country does this flag belong to?"** prompt text
4. **4 AnswerButtons** — shuffled country names; wrong answers get disabled after tap; correct answer highlights green on reveal
5. **ResultOverlay** — shown when `_roundOver`: displays correct country name, points earned, "Next" button

### 5.6 `main.dart` — Provider Setup

```dart
void main() {
  runApp(
    MultiProvider(
      providers: [
        Provider(create: (_) => CountryService()),
        Provider(create: (_) => StorageService()),
        ChangeNotifierProxyProvider2<CountryService, StorageService, TriviaViewModel>(
          create: (ctx) => TriviaViewModel(
            countryService: ctx.read<CountryService>(),
            storageService: ctx.read<StorageService>(),
          )..init(),
          update: (_, countryService, storageService, previous) =>
              previous ??
              TriviaViewModel(
                countryService: countryService,
                storageService: storageService,
              ),
        ),
      ],
      child: const TriviaApp(),
    ),
  );
}
```

---

## 6. Dependencies (`pubspec.yaml`)

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  provider: ^6.1.2
  shared_preferences: ^2.3.3
  http: ^1.2.2
```

---

## 7. Edge Cases

| Scenario | Handling |
|----------|----------|
| API fetch fails | Show error message with "Retry" button |
| Flag image fails to load | Show placeholder icon (e.g., `Icons.flag_outlined`) |
| All countries solved | Show "You've solved them all!" message with final score and a "Reset" button |
| Duplicate country names in options | Filter distractors to ensure unique names |
| Fewer than 4 unsolved countries | Use remaining countries; if < 2, show completion screen |

---

## 8. Testing Strategy

### 8.1 Unit Tests (`test/trivia_viewmodel_test.dart`)

- `answer()` with correct ISO on first try → score increases by 10
- `answer()` with correct ISO on second try → score increases by 8
- `answer()` with correct ISO on third try → score increases by 5
- `answer()` with 3 wrong ISOs → score unchanged, round over
- `nextQuestion()` generates new question with different correct country
- Solved countries are excluded from future questions

### 8.2 Widget Tests (`test/trivia_view_test.dart`)

- Flag image renders with correct URL
- 4 answer buttons are displayed
- Tapping correct answer shows result overlay
- Tapping wrong answer disables that button
- Score updates in header after correct answer

### 8.3 Mock Data

Use `http.MockClient` (from `package:http/testing.dart`) to return a fixed JSON payload instead of hitting the real API.

---

## 9. UI/UX Design

- **Theme:** Material 3, seed color `Colors.indigo`
- **Flag display:** Rounded corners (12px), subtle shadow, 3:2 aspect ratio
- **Answer buttons:** Full-width, 56px height, rounded 12px, outlined style
- **Feedback:** Correct answer → green background; wrong answer → red strike-through + disabled
- **Result overlay:** Bottom sheet or dialog with slide-up animation
- **Progress:** Linear progress bar showing `solvedCount / totalCountries`

---

## 10. Ticket Breakdown & Parallelization

### 10.1 Ticket Summary

| Ticket | Title | Dependencies | Group |
|--------|-------|-------------|-------|
| T1 | Update `pubspec.yaml` with dependencies | None | 1 |
| T2 | Create `models/country.dart` | None | 1 |
| T3 | Create `utils/constants.dart` | None | 1 |
| T4 | Create `utils/app_theme.dart` | None | 1 |
| T5 | Create `services/storage_service.dart` | T3 | 2 |
| T6 | Create `services/country_service.dart` | T2, T3 | 2 |
| T7 | Create `viewmodels/trivia_viewmodel.dart` | T2, T3, T5, T6 | 3 |
| T8 | Create `views/widgets/flag_display.dart` | T3 | 4 |
| T9 | Create `views/widgets/answer_button.dart` | None | 4 |
| T10 | Create `views/widgets/score_header.dart` | None | 4 |
| T11 | Create `views/widgets/result_overlay.dart` | None | 4 |
| T12 | Create `views/trivia_view.dart` | T7, T8, T9, T10, T11 | 5 |
| T13 | Update `main.dart` with Provider setup | T5, T6, T7 | 5 |
| T14 | Write unit tests for ViewModel | T7 | 6 |
| T15 | Run `flutter analyze` and fix issues | T1–T14 | 7 |
| T16 | Run `flutter test` and fix issues | T14 | 7 |

---

### 10.2 Dependency Graph

```
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│                              DEPENDENCY GRAPH                                          │
│                                                                                         │
│  PHASE 1 (Foundation)                                                                   │
│  ┌─────┐  ┌─────┐  ┌─────┐  ┌─────┐                                                   │
│  │ T1  │  │ T2  │  │ T3  │  │ T4  │                                                   │
│  └──┬──┘  └──┬──┘  └──┬──┘  └─────┘                                                   │
│     │        │        │                                                                │
│     │        │        │                                                                │
│     ▼        ▼        ▼                                                                │
│  ┌──────────────────────────────────────────────────────────────────┐                  │
│  │ PHASE 2 (Services + Widgets)                                     │                  │
│  │                                                                  │                  │
│  │  T2 ──► T6        T3 ──► T5        T3 ──► T8                      │                  │
│  │  ┌─────┐          ┌─────┐          ┌─────┐                       │                  │
│  │  │ T6  │          │ T5  │          │ T8  │                       │                  │
│  │  └─────┘          └─────┘          └─────┘                       │                  │
│  │                                                                  │                  │
│  │  ┌─────┐  ┌─────┐  ┌─────┐                                      │                  │
│  │  │ T9  │  │ T10 │  │ T11 │   (no dependencies)                  │                  │
│  │  └─────┘  └─────┘  └─────┘                                      │                  │
│  └──────────────────────────────────────────────────────────────────┘                  │
│     │        │        │        │        │        │                                      │
│     │        │        │        │        │        │                                      │
│     ▼        ▼        ▼        ▼        ▼        ▼                                      │
│  ┌──────────────────────────────────────────────────────────────────┐                  │
│  │ PHASE 3 (ViewModel)                                              │                  │
│  │                                                                  │                  │
│  │  T2 ─┐                                                           │                  │
│  │  T3 ─┼──► T7                                                     │                  │
│  │  T5 ─┤                                                           │                  │
│  │  T6 ─┘                                                           │                  │
│  │  ┌─────┐                                                         │                  │
│  │  │ T7  │                                                         │                  │
│  │  └──┬──┘                                                         │                  │
│  └─────┼────────────────────────────────────────────────────────────┘                  │
│        │                                                                            │
│        ├──────────────────────────────────────────────────────────────┐                 │
│        │                                                              │                 │
│        ▼                                                              ▼                 │
│  ┌─────────────────────────────┐              ┌─────────────────────────────┐          │
│  │ PHASE 4a (Views)            │              │ PHASE 4b (Tests)            │          │
│  │                             │              │                             │          │
│  │  T7 ─┐                      │              │  T7 ──────► T14             │          │
│  │  T8 ─┤                      │              │  ┌─────┐                    │          │
│  │  T9 ─┼──► T12               │              │  │ T14 │                    │          │
│  │  T10─┤                      │              │  └─────┘                    │          │
│  │  T11─┘                      │              └─────────────────────────────┘          │
│  │  ┌─────┐                    │                                                       │
│  │  │ T12 │                    │                                                       │
│  │  └─────┘                    │                                                       │
│  │                             │                                                       │
│  │  T5 ─┐                      │                                                       │
│  │  T6 ─┼──► T13               │                                                       │
│  │  T7 ─┘                      │                                                       │
│  │  ┌─────┐                    │                                                       │
│  │  │ T13 │                    │                                                       │
│  │  └─────┘                    │                                                       │
│  └─────────────────────────────┘                                                       │
│        │                                                                            │
│        └──────────────────────────────────────────────────────────────┐                 │
│                                                                       │                 │
│                                                                       ▼                 │
│  ┌──────────────────────────────────────────────────────────────────┐                  │
│  │ PHASE 5 (Verification)                                           │                  │
│  │                                                                  │                  │
│  │  T1 ─┐                                                           │                  │
│  │  T2 ─┤                                                           │                  │
│  │  T3 ─┤                                                           │                  │
│  │  T4 ─┤                                                           │                  │
│  │  T5 ─┤                                                           │                  │
│  │  T6 ─┼──► T15                                                    │                  │
│  │  T7 ─┤                                                           │                  │
│  │  T8 ─┤                                                           │                  │
│  │  T9 ─┤                                                           │                  │
│  │  T10─┤                                                           │                  │
│  │  T11─┤                                                           │                  │
│  │  T12─┤                                                           │                  │
│  │  T13─┤                                                           │                  │
│  │  T14─┘                                                           │                  │
│  │  ┌─────┐                                                         │                  │
│  │  │ T15 │                                                         │                  │
│  │  └──┬──┘                                                         │                  │
│  └─────┼────────────────────────────────────────────────────────────┘                  │
│        │                                                                            │
│        ▼                                                                            │
│  ┌──────────────────────────────────────────────────────────────────┐                  │
│  │ PHASE 6 (Test Verification)                                      │                  │
│  │                                                                  │                  │
│  │  T14 ──────► T16                                                 │                  │
│  │  ┌─────┐                                                         │                  │
│  │  │ T16 │                                                         │                  │
│  │  └─────┘                                                         │                  │
│  └──────────────────────────────────────────────────────────────────┘                  │
│                                                                                         │
└─────────────────────────────────────────────────────────────────────────────────────────┘
```

### 10.3 Adjacency List

| Ticket | Depends On | Depended On By |
|--------|-----------|----------------|
| T1 | — | T15 |
| T2 | — | T6, T7, T15 |
| T3 | — | T5, T6, T7, T8, T15 |
| T4 | — | T15 |
| T5 | T3 | T7, T13, T15 |
| T6 | T2, T3 | T7, T13, T15 |
| T7 | T2, T3, T5, T6 | T12, T13, T14, T15 |
| T8 | T3 | T12, T15 |
| T9 | — | T12, T15 |
| T10 | — | T12, T15 |
| T11 | — | T12, T15 |
| T12 | T7, T8, T9, T10, T11 | T15 |
| T13 | T5, T6, T7 | T15 |
| T14 | T7 | T15, T16 |
| T15 | T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11, T12, T13, T14 | T16 |
| T16 | T14, T15 | — |

### 10.4 Parallelization Groups

#### Group 1 — Foundation (4 tickets, all parallel)

| Ticket | Description | File(s) |
|--------|-------------|---------|
| T1 | Add `provider`, `shared_preferences`, `http`, `cached_network_image` to `pubspec.yaml`, run `flutter pub get` | `pubspec.yaml` |
| T2 | Create `Country` model with `name`, `isoCode`, `fromJson` factory, equality/hashCode | `lib/models/country.dart` |
| T3 | Create `AppConstants` — API URL, flag URL builder, pref keys, points list, max attempts | `lib/utils/constants.dart` |
| T4 | Create `AppTheme` — Material 3 light theme, indigo seed, button styles | `lib/utils/app_theme.dart` |

#### Group 2 — Services (2 tickets, parallel with each other)

| Ticket | Description | File(s) | Depends on |
|--------|-------------|---------|------------|
| T5 | Create `StorageService` — load/save solved flags (StringList), load/save score (int), clearAll | `lib/services/storage_service.dart` | T3 |
| T6 | Create `CountryService` — HTTP GET, parse JSON to `List<Country>`, error handling | `lib/services/country_service.dart` | T2, T3 |

#### Group 3 — ViewModel (1 ticket)

| Ticket | Description | File(s) | Depends on |
|--------|-------------|---------|------------|
| T7 | Create `TriviaViewModel` — game state, `init()`, `answer()`, `nextQuestion()`, `resetGame()`, persistence | `lib/viewmodels/trivia_viewmodel.dart` | T2, T3, T5, T6 |

#### Group 4 — Widgets (4 tickets, all parallel, can run alongside Groups 2 & 3)

| Ticket | Description | File(s) | Depends on |
|--------|-------------|---------|------------|
| T8 | Create `FlagDisplay` — `CachedNetworkImage` with placeholder/error states | `lib/views/widgets/flag_display.dart` | T3 |
| T9 | Create `AnswerButton` — 4 states (idle/correct/wrong/disabled), styled `ElevatedButton` | `lib/views/widgets/answer_button.dart` | None |
| T10 | Create `ScoreHeader` — score chip, solved chip, linear progress bar | `lib/views/widgets/score_header.dart` | None |
| T11 | Create `ResultOverlay` — correct/incorrect icon, country name, points, next button | `lib/views/widgets/result_overlay.dart` | None |

#### Group 5 — Main View & App Entry (2 tickets, parallel with each other)

| Ticket | Description | File(s) | Depends on |
|--------|-------------|---------|------------|
| T12 | Create `TriviaView` — orchestrates all widgets, Consumer, error/loading/all-solved states, reset dialog | `lib/views/trivia_view.dart` | T7, T8, T9, T10, T11 |
| T13 | Update `main.dart` — `MultiProvider` setup, `ChangeNotifierProxyProvider2`, `MaterialApp` | `lib/main.dart` | T5, T6, T7 |

#### Group 6 — Tests (1 ticket)

| Ticket | Description | File(s) | Depends on |
|--------|-------------|---------|------------|
| T14 | Write unit tests — 10 test cases covering all game logic paths | `test/widget_test.dart` | T7 |

#### Group 7 — Verification (2 tickets, sequential)

| Ticket | Description | File(s) | Depends on |
|--------|-------------|---------|------------|
| T15 | Run `flutter analyze`, fix all issues | All | T1–T14 |
| T16 | Run `flutter test`, fix all failing tests | All | T14 |

---

### 10.3 Execution Order

```
Phase 1:  T1, T2, T3, T4                    (4 parallel)
             │
Phase 2:  T5, T6, T8, T9, T10, T11         (6 parallel)
             │
Phase 3:  T7                                (1 ticket)
             │
Phase 4:  T12, T13, T14                    (3 parallel)
             │
Phase 5:  T15                               (1 ticket)
             │
Phase 6:  T16                               (1 ticket)
```

**Critical path:** T1 → T3 → T5 → T7 → T12 → T15 → T16 (7 tickets)

**Maximum parallelism:** 6 tickets simultaneously (Phase 2)

---

### 10.4 PR Readiness Criteria

Every UI ticket (T8, T9, T10, T11, T12) must pass the following before a PR is raised:

| Criterion | Verification |
|-----------|-------------|
| App builds without errors | `flutter build apk --debug` (or iOS equivalent) |
| App launches on emulator | `flutter run -d <emulator>` |
| Widget renders correctly | Visual inspection on emulator |
| User interaction works | Tap/scroll tested on emulator |
| No console errors | Check `flutter logs` or DevTools console |
| Responsive layout | Tested in portrait and landscape orientations |

**Emulator commands:**

```bash
# List available emulators
flutter emulators

# Launch an emulator (example)
flutter emulators --launch Pixel_5_API_34

# Run the app on the emulator
flutter run -d <emulator_id>

# Run in release mode for performance check
flutter run -d <emulator_id> --release
```

---

### 10.5 Ticket Details

#### T1 — Update pubspec.yaml
- [x] Add `provider: ^6.1.2`
- [x] Add `shared_preferences: ^2.3.3`
- [x] Add `http: ^1.2.2`
- [x] Add `cached_network_image: ^3.4.1`
- [x] Run `flutter pub get`

#### T2 — Create Country model
- [x] Create `lib/models/country.dart`
- [x] Add `name` and `isoCode` fields
- [x] Add `fromJson` factory constructor
- [x] Add `==` operator and `hashCode`
- [x] Add `toString` for debugging

#### T3 — Create constants
- [x] Create `lib/utils/constants.dart`
- [x] Add `countriesUrl` (GitHub ISO 3166 JSON)
- [x] Add `flagUrl(isoCode)` helper
- [x] Add `solvedKey` and `scoreKey` pref keys
- [x] Add `pointsPerTry` list `[10, 8, 5]`
- [x] Add `maxAttempts = 3`

#### T4 — Create app theme
- [ ] Create `lib/utils/app_theme.dart`
- [ ] Add Material 3 light theme with indigo seed
- [ ] Configure `AppBarTheme` (centered, no elevation)
- [ ] Configure `ElevatedButtonThemeData` (full-width, 56px, rounded 12px)

#### T5 — Create StorageService
- [ ] Create `lib/services/storage_service.dart`
- [ ] Add `loadSolved()` → `Set<String>`
- [ ] Add `saveSolved(Set<String>)`
- [ ] Add `loadScore()` → `int`
- [ ] Add `saveScore(int)`
- [ ] Add `clearAll()`

#### T6 — Create CountryService
- [ ] Create `lib/services/country_service.dart`
- [ ] Add `fetchCountries()` → `Future<List<Country>>`
- [ ] HTTP GET to GitHub ISO 3166 JSON
- [ ] Parse JSON array to `List<Country>`
- [ ] Throw exception on non-200 status

#### T7 — Create TriviaViewModel
- [ ] Create `lib/viewmodels/trivia_viewmodel.dart`
- [ ] Add all state fields (score, attempts, solved, options, etc.)
- [ ] Add getters for all state
- [ ] Add `init()` — load persisted data, fetch countries, generate question
- [ ] Add `_generateQuestion()` — pick correct + 3 distractors, shuffle
- [ ] Add `answer(isoCode)` — correct/wrong logic, points, persistence
- [ ] Add `nextQuestion()` — regenerate question
- [ ] Add `resetGame()` — clear all state and storage

#### T8 — Create FlagDisplay widget
- [ ] Create `lib/views/widgets/flag_display.dart`
- [ ] Use `CachedNetworkImage` with flag URL
- [ ] Add loading placeholder (grey container + spinner)
- [ ] Add error widget (grey container + flag icon)
- [ ] Wrap in `ClipRRect` with rounded corners and shadow
- [ ] **Run on emulator** — verify flag image loads, placeholder shows during loading, error icon shows on bad URL

#### T9 — Create AnswerButton widget
- [ ] Create `lib/views/widgets/answer_button.dart`
- [ ] Add `AnswerState` enum (idle, correct, wrong, disabled)
- [ ] Style button based on state (colors, icons)
- [ ] Disable button when not idle
- [ ] Add check/cancel icon for correct/wrong states
- [ ] **Run on emulator** — verify all 4 states render correctly, tap targets are >= 48dp, text is readable

#### T10 — Create ScoreHeader widget
- [ ] Create `lib/views/widgets/score_header.dart`
- [ ] Add score chip with star icon
- [ ] Add solved count chip with flag icon
- [ ] Add linear progress bar (solved / total)
- [ ] **Run on emulator** — verify score updates after correct answer, progress bar animates, layout doesn't overflow

#### T11 — Create ResultOverlay widget
- [ ] Create `lib/views/widgets/result_overlay.dart`
- [ ] Add correct/incorrect icon and title
- [ ] Display country name
- [ ] Show points earned or "No points awarded"
- [ ] Add "Next Flag" button
- [ ] **Run on emulator** — verify overlay appears after round ends, correct/incorrect styling, "Next" button advances

#### T12 — Create TriviaView
- [ ] Create `lib/views/trivia_view.dart`
- [ ] Add `Consumer<TriviaViewModel>` wrapper
- [ ] Add loading state (spinner)
- [ ] Add error state with retry button
- [ ] Add all-solved state with reset button
- [ ] Add main game layout (header, flag, prompt, buttons, overlay)
- [ ] Add reset confirmation dialog
- [ ] **Run on emulator** — verify full game flow: flag loads, 4 options shown, correct answer awards points, wrong answer disables button, 3 wrong reveals answer, next question generates, reset dialog works, all-solved screen shows

#### T13 — Update main.dart
- [ ] Update `lib/main.dart`
- [ ] Add `MultiProvider` with `CountryService`, `StorageService`
- [ ] Add `ChangeNotifierProxyProvider2` for `TriviaViewModel`
- [ ] Add `MaterialApp` with theme and `TriviaView` home

#### T14 — Write unit tests
- [ ] Update `test/widget_test.dart`
- [ ] Add `MockCountryService` with 8 test countries
- [ ] Test initial state
- [ ] Test correct answer on 1st/2nd/3rd try (10/8/5 points)
- [ ] Test 3 wrong answers (0 points, round over)
- [ ] Test duplicate wrong answer counts as one attempt
- [ ] Test solved countries excluded from future questions
- [ ] Test nextQuestion generates new options
- [ ] Test resetGame clears everything
- [ ] Test persistence across ViewModel instances

#### T15 — Run flutter analyze
- [ ] Run `flutter analyze`
- [ ] Fix all warnings and errors
- [ ] Verify "No issues found!"

#### T16 — Run flutter test
- [ ] Run `flutter test`
- [ ] Fix all failing tests
- [ ] Verify "All tests passed!"
