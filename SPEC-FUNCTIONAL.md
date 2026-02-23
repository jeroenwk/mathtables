# Math Tables — Functional Specification

## Overview

Math Tables is a multiplication practice game for children. Multiple players can use the app on the same device, each with their own profile, settings, and score history. The game runs entirely in the browser — no account, no server, no internet required.

---

## Players

- Any number of player profiles can be created on the same device.
- Each profile has a **name**, an **emoji avatar**, and its own settings and score history.
- Profiles are listed on the home screen, sorted by their best score (highest first).
- A profile can be deleted from the stats screen (deletes all associated data).

---

## Settings (per player)

Before starting a game, each player configures:

### Difficulty (time limit per question)
| Level   | Time limit | Score bonus |
|---------|-----------|-------------|
| Off     | None      | ×1.0        |
| Easy    | 10 s      | ×1.0        |
| Hard    | 6 s       | ×1.3        |
| Extreme | 3 s       | ×1.7        |

Harder difficulty levels apply a multiplier to every point scored.

### Game Mode
| Mode             | Description |
|------------------|-------------|
| 20 questions     | A fixed set of 20 randomly chosen questions |
| 2 minutes        | As many questions as possible in 2 minutes |
| All              | Each unique pair from the selected tables once (e.g. 5×6 and 6×5 count as one question, shown in a random order) |
| Double           | Each unique pair in both orderings (5×6 and 6×5 as separate questions); symmetric pairs like 6×6 appear once |

### Boost Hard Questions
When enabled, the player's personal top-10 hardest questions (most errors, slowest responses) are added 3 extra times to the question pool, making them appear more frequently. This applies to the **20 questions** and **2 minutes** modes; the **All** and **Double** modes are not boosted (each question already appears a fixed number of times).

### Tables
Each table (1 through 10) can be individually enabled or disabled. Disabled tables are excluded from all questions.

---

## Gameplay

### Question format
Each question shows a multiplication, e.g. **6 × 7 = ?**

The player enters the answer using the on-screen numeric keypad (or physical keyboard).

### Second chance
If the player answers **incorrectly on the first attempt**, they are given one second chance. If they answer correctly on the second attempt, the question is marked as "second chance" — it scores 0 points, does not continue the streak, and is recorded separately in statistics.

If they fail the second attempt too, the correct answer is shown briefly, and the game moves on. No points are awarded.

### Timer
On timed difficulty levels, a progress bar counts down for each question. If the timer expires before an answer is submitted, the question is counted as a wrong answer (second chance used, then failed).

### End of game
- **20 questions mode**: ends after 20 questions.
- **2 minutes mode**: ends when the 2-minute clock runs out.
- **All / Double mode**: ends when all questions in the pool have been answered.

---

## Scoring

Each correctly answered question (first attempt only) earns points:

### No-limit mode (difficulty: Off)
```
score = 100
```

### Timed modes (Easy / Hard / Extreme)
```
timeBonus  = 0–200  (based on how quickly you answered relative to the time limit)
streakBonus = min(streak × 15, 120)
base       = 100 + timeBonus + streakBonus
```

The time bonus is maximum (200) when you answer in the first 15% of the allowed time, and 0 when you use the full time.

The streak bonus grows by 15 for each consecutive correct first-attempt answer, capped at 120 (after 8 correct in a row).

### Hard question multiplier
Questions involving factors 6, 7, 8, or 9 are considered "hard":
- One hard factor: **×2**
- Both factors hard (e.g. 6×8, 7×9): **×4**

### Difficulty bonus
After applying the hard multiplier, a difficulty bonus is applied:
- Off / Easy: **×1.0**
- Hard: **×1.3**
- Extreme: **×1.7**

### Full formula
```
score = round( (base × hardMultiplier) × difficultyBonus )
```

**Example** — answering 7×8 in 1 second on Extreme (3s limit):
- base ≈ 100 + 200 + streak
- × 4 (both factors hard)
- × 1.7 (Extreme bonus)
- = roughly 2040+ points for that single question

### Second-chance and wrong answers
- Second-chance correct: **0 points**, streak resets to 0
- Wrong (both attempts failed): **0 points**, streak resets to 0

---

## Results Screen

After each game, the player sees:
- Total score
- Breakdown: correct (first attempt) / second chance / wrong
- Whether a new personal best was achieved (confetti + sound)

The top 10 scores per player are stored. Scores are ranked globally across all modes and difficulty levels.

---

## Statistics Screen

Accessible from the home screen per player. Shows:
- All-time best scores (top 10)
- Average game duration by mode/difficulty
- Top 10 hardest questions: the questions with the highest error rate and slowest average response time

---

## Languages

The app supports **French** (default), **English**, and **Dutch**. The language can be switched from the home screen and applies immediately to all text.

---

## Sound

The app plays synthesised sounds (no audio files) for:
- Correct answer
- Score (with variations for ×2 and ×4 multipliers)
- Wrong answer
- New high score (win fanfare)
- Game over (lose sound)

Sound is initialised on first user interaction (browser requirement).
