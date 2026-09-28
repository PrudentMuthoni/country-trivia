# AGENTS.md

## Project

Flutter country trivia quiz app. MVVM architecture with Provider for state management.

## Architecture

- **Pattern:** MVVM — `models/` → `services/` → `viewmodels/` → `views/`
- **State management:** Provider (`ChangeNotifierProxyProvider2` in `main.dart`)
- **Persistence:** SharedPreferences (solved flags + total score)
- **Country data:** GitHub ISO 3166 JSON (REST Countries API v1–v4 is deprecated; v5 requires paid key)
- **Flag images:** `https://flagcdn.com/w320/{iso}.png` via `cached_network_image`

## Commands

```bash
flutter pub get          # Install dependencies
flutter analyze          # Lint check (must pass before PR)
flutter test            # Run all tests
flutter test --name "test name"  # Run single test
flutter run -d <emulator> # Run on emulator (required before UI PRs)
```

## Branch & PR Rules

- **Default branch:** `develop` — all PRs target this
- **Feature branches:** `feature/t<N>-<short-description>` (e.g., `feature/t12-trivia-view`)
- **PR requirement:** UI tickets (T8–T12) must pass emulator verification before PR
- **Commit style:** `T<N>: <description>` or `Mark T<N> (<title>) as complete`

## Code Style

- **No emojis anywhere** — not in code, not in comments, not in commit messages, not in PR descriptions

## Points System

| Attempt | Points |
|---------|--------|
| 1st try | 10 |
| 2nd try | 8 |
| 3rd try | 5 |
| Exhausted (3 wrong) | 0 |

## Key Files

| File | Purpose |
|------|---------|
| `lib/viewmodels/trivia_viewmodel.dart` | All game logic — scoring, attempts, question generation |
| `lib/services/country_service.dart` | Fetches countries from GitHub ISO 3166 JSON |
| `lib/services/storage_service.dart` | SharedPreferences wrapper |
| `lib/utils/constants.dart` | API URLs, pref keys, points list |
| `docs/master-plan.md` | Full ticket breakdown, dependency graph, PR criteria |

## Testing

- Tests use `MockCountryService` (8 test countries) — no real API calls
- `SharedPreferences.setMockInitialValues({})` for clean state
- All 10 tests must pass before PR

## Emulator Verification (UI tickets only)

```bash
flutter emulators                    # List available
flutter emulators --launch <id>     # Launch
flutter run -d <id>                 # Run app
```

Verify: widget renders, user interaction works, no console errors, responsive layout.
