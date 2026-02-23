# Math Tables — Technical Specification

## Platform & Deployment

- **Single HTML file**: the entire application lives in `MathTables/index.html` — HTML, CSS, JS, and the embedded Bangers web font (base64 woff2), all in one file.
- **No dependencies**: no frameworks, no build step, no npm, no external requests.
- **Client-side only**: runs in any modern browser (Safari, Chrome, Firefox). Optimised for iOS via a WKWebView wrapper (Xcode project).
- The root `index.html` is a symlink to `MathTables/index.html` for browser testing during development.

---

## File Structure

```
mathtables/
├── index.html                  → symlink to MathTables/index.html
├── MathTables/
│   └── index.html              → the entire application (~1850 lines)
├── MathTables.xcodeproj/       → iOS wrapper (WKWebView)
└── MathTables/
    ├── AppDelegate.swift
    ├── SceneDelegate.swift
    ├── ViewController.swift     → loads index.html into a WKWebView
    └── Assets.xcassets/
```

---

## Architecture

The app uses a **single-page, full-redraw** pattern. There is no virtual DOM or reactive framework. Each screen is rendered by a dedicated function that clears `#app` and builds fresh DOM.

### Global objects

| Object | Role |
|--------|------|
| `Store` | All localStorage read/write, user and answer CRUD |
| `Sound` | Web Audio API synthesis engine |
| `Game` | Game state machine: question pool, scoring, timer, submission logic |
| `App` | Screen router and global state (current user, language, result data) |
| `I18N` | Translation lookup table (fr, en, nl) |

### Screen routing

```js
App.go(screen, params)
```

Clears `#app`, calls the corresponding `render*()` function, applies a fade-in animation. Screens:

| Screen name    | Render function      |
|----------------|----------------------|
| `HOME`         | `renderHome()`       |
| `ADD_USER`     | `renderAddUser()`    |
| `SETTINGS`     | `renderSettings()`   |
| `GAME_ACTIVE`  | `renderGame()`       |
| `GAME_RESULT`  | `renderResult()`     |
| `STATS`        | `renderStats()`      |

---

## Storage

- **Key**: `mathtables_v1` in `localStorage`
- **Format**: single JSON blob, written with a 300ms debounce (`Store.save()`), or immediately via `Store.saveNow()`
- **Schema**:

```json
{
  "lang": "fr",
  "users": {
    "<uuid>": {
      "id": "<uuid>",
      "name": "string",
      "emoji": "string",
      "createdAt": 1234567890,
      "settings": {
        "difficulty": "off|easy|hard|extreme",
        "mode": "fixed_count|fixed_time|extensive|double_extensive",
        "boostDifficult": false,
        "disabledTables": [3, 7]
      },
      "highscores": [
        {
          "id": "<uuid>",
          "score": 4200,
          "mode": "fixed_count",
          "difficulty": "hard",
          "date": 1234567890,
          "duration": 95000,
          "totalQuestions": 20,
          "correctFirst": 17,
          "correctSecond": 2,
          "wrong": 1
        }
      ]
    }
  },
  "answers": {
    "<userId>": {
      "6x8": {
        "attempts": 12,
        "correct": 9,
        "wrong": 2,
        "secondChance": 1,
        "totalTime": 45000,
        "avgTime": 5000
      }
    }
  }
}
```

Answer keys are always stored in `min×max` order (e.g. `6x8`, never `8x6`) to deduplicate commutative pairs.

---

## Game Logic (`Game` object)

### Question pool generation (`Game.buildPool`)

1. Generate all `a×b` pairs where `1 ≤ a,b ≤ MAX_TABLE[difficulty]` (currently 10 for all levels), excluding disabled tables.
2. If `boostDifficult` is enabled, fetch the player's top-10 hardest questions (`Store.getTop10Hard`) and add each 3 extra times — but only if both factors are within the current `MAX_TABLE` limit.
3. Fisher-Yates shuffle.
4. Slice/repeat according to mode:
   - `fixed_count`: first 20 questions
   - `fixed_time`: repeat pool up to 200 questions
   - `extensive`: full pool
   - `double_extensive`: full pool + shuffled reversed pairs

### Scoring (`Game.computeQuestionScore`)

```js
// No time limit
base = 100

// Timed modes
fast = timeLimit * 0.15
fraction = clamp((timeLimit - timeTaken) / (timeLimit - fast), 0, 1)
timeBonus = round(200 * fraction)
streakBonus = min(streak * 15, 120)
base = 100 + timeBonus + streakBonus

// Hard question multiplier
hardFactors = [6, 7, 8, 9]
mult = bothHard ? 4 : oneHard ? 2 : 1

// Difficulty bonus
diffBonus = { off: 1.0, easy: 1.0, hard: 1.3, extreme: 1.7 }

score = round(base * mult * diffBonus)
```

### Answer submission flow

1. Player submits answer.
2. If correct (first attempt): award points, increment streak, advance.
3. If wrong (first attempt): set `secondChance = true`, reset streak, shake UI.
4. If correct (second attempt): advance, 0 points.
5. If wrong (second attempt): show correct answer for 1.2s, then advance, 0 points.

### Timer (`requestAnimationFrame` loop)

On timed difficulty, each question starts a `rAF` loop that updates the timer bar width proportionally. On expiry, calls `Game.onTimerExpired()` which burns both attempts and advances.

### Highscore logic

Top 10 scores per user, sorted by score descending. A new high score is detected when the just-added entry lands at index 0.

---

## Sound Engine (`Sound` object)

Uses the **Web Audio API** (`AudioContext`) with pure synthesis — no audio files.

- Initialised lazily on first user gesture (iOS / browser autoplay restriction).
- `Sound.correct()` — short ascending tone
- `Sound.scoreUp()` / `scoreDouble()` / `scoreQuad()` — progressively more elaborate positive sounds
- `Sound.wrong()` — descending buzz
- `Sound.gameOverWin()` — fanfare sequence
- `Sound.gameOverLose()` — low resolution sound

---

## DOM Helpers

A minimal `el(tag, attrs, children)` helper creates DOM elements:

```js
el('div', { class: 'card', onClick: handler }, ['Hello'])
```

The `onClick` key is mapped to `addEventListener('click', ...)`. All other keys become attributes.

---

## CSS

- Dark theme, purple accent (`#6c63ff`)
- CSS custom properties for the full colour palette
- Responsive via media queries at 480px and 600px breakpoints
- Safe-area insets for iOS notch/home bar (`env(safe-area-inset-*)`)
- Animations: fade-in, flash-green, shake, float-up (score popup), confetti (canvas-based)
- Font: **Bangers** (Google Fonts, embedded as base64 woff2 — no external request)

---

## iOS Wrapper

The Xcode project wraps the HTML file in a native iOS app using `WKWebView`:

- `ViewController.swift` loads `index.html` from the app bundle
- `WKWebViewConfiguration` with `allowsInlineMediaPlayback = true` (needed for Web Audio)
- The `index.html` inside `MathTables/` is the build source; the root symlink is for development convenience only.

---

## Constants

| Constant | Value | Meaning |
|----------|-------|---------|
| `STORAGE_KEY` | `mathtables_v1` | localStorage key |
| `FIXED_COUNT` | 20 | Questions in fixed-count mode |
| `FIXED_TIME_MS` | 120 000 ms | Duration of timed mode (2 min) |
| `TIME_LIMITS` | off: null, easy: 15s, hard: 10s, extreme: 5s | Per-question time limits |
| `DIFFICULTY_BONUS` | off/easy: 1.0, hard: 1.3, extreme: 1.7 | Score multipliers |
| `MAX_TABLE` | 10 for all levels | Highest table included in questions |
