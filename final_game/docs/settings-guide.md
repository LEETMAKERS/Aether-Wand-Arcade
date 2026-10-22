# Runeweave — Difficulty, Timing & Scoring Guide

This guide explains every tuning setting available both in the **Godot Inspector** (on the `Main` root node under **Difficulty & Scoring Tuning**) and live in-game inside **`SettingsPanel`**.

You can adjust these values before starting a game, or press **`Esc` mid-game** to pause, move the sliders, and resume or restart immediately.

---

## 1. How Break Points Work (Per Troop Cue)

There are **21 troops (cues)** in a full round. Each troop has a required counter element (`Fire`, `Frost`, or `Lightning`) shown above its head.

| Cast Result | Stable Mode Break | Wild Mode Break *(3 different runes)* |
| :--- | :---: | :---: |
| **Clean Kill — PERFECT Timing** (Right Element + Right Lane) | **+8 Break** | **+10 Break** |
| **Clean Kill — GREAT/GOOD Timing** (Right Element + Right Lane) | **+6 Break** | **+3 Break** |
| **Wrong Element — PERFECT Timing** (Right Lane, Wrong Element) | **+1 Break** | **+1 Break** |
| **Wrong Element — GREAT/GOOD Timing** (Troop survives & breaches) | **0 Break** | **0 Break** |
| **Wrong Lane / Too Early / Missed / Ambiguous** | **0 Break** | **0 Break** |

- **Maximum theoretically possible Break in 21 cues:**
  - **Stable (Lite):** `21 × 8 = 168 Break` (if every single troop is a Perfect Clean Kill) or `21 × 6 = 126 Break` (if every single troop is a Great/Good Clean Kill).
  - **Wild Mode:** `21 × 10 = 210 Break`.

---

## 2. How the `1.0 – 10.0` Score Is Calculated (and How to Make `10.0` Easier!)

The score formula in `main.gd` (`_compute_score`) converts the player's earned **Break (`D`)** into a `1.0` to `10.0` rating rounded to 1 decimal place:

$$\text{Score} = \text{round}_{0.1}\left(\min\left(10.0,\; 1.0 + 9.0 \times \frac{\text{Earned Break}}{\text{Break for 10.0 Score}}\right)\right)$$

### The Key Setting: **`break_for_max_score` (`BREAK FOR 10.0 SCORE` slider)**
Instead of forcing a player to get 21 out of 21 Perfects (`168 Break`) just to see a `10.0`, **`break_for_max_score`** lets you decide how many Break points equal a `10.0`!

- **At `168` (Strict Design Default):** Requires 21/21 Perfects for `10.0`. Getting all Great/Good kills (`126 Break`) only gives `7.8`.
- **At `120` (Forgiving / Recommended for Events):**
  - Any player who gets `120+ Break` (e.g., 15 Perfects, or 20 Great/Goods, allowing several mistakes!) gets a **`10.0`**.
  - `100 Break` (Victory threshold) gives **`8.5`**.
  - `80 Break` gives **`7.0`**.
- **At `100` (Super Forgiving — Victory = `10.0`):**
  - Anyone who reaches the `100 Break` Victory threshold automatically gets a **`10.0`** score!

---

## 3. All Tuning Settings Explained

### A. `game_speed` (`GAME SPEED: 1.0x` — Range: `0.4x` to `2.5x`)
- **What it does:** Multiplies the pace of the entire round.
  - At **`1.0x`**: The round lasts `60 seconds` and uses the standard intervals (`3.2s` → `2.8s` → `2.4s` between troops).
  - At **`0.7x`**: Everything runs 30% slower (round lasts ~85s, troops walk slower, and you have more time between troops).
  - At **`1.3x`**: Everything runs 30% faster for experienced players.

### B. `perfect_window_ms` (`PERFECT WINDOW: ±50 ms` — Range: `20 ms` to `200 ms`)
- **What it does:** How close to the golden contact line (`T`) the 4th input must be to count as **PERFECT** (`+8` / `+10` Break).
- **How to tune:**
  - `±50 ms` is tight rhythm-game precision (`100 ms` total window).
  - Raising this to **`±90 ms` or `±110 ms`** makes hitting **PERFECT** feel much more generous and rewarding, especially when using physical hardware sensors!

### C. `good_window_ms` (`GREAT WINDOW: ±130 ms` — Range: `60 ms` to `400 ms`)
- **What it does:** The outer hit window around the contact line (`T - good_window_ms` to `T + good_window_ms`).
  - Releasing *before* `T - good_window_ms` counts as **TOO EARLY — FIZZLED!**.
  - Releasing *after* `T + good_window_ms` counts as **UNFINISHED — MISSED!**.
- **How to tune:**
  - If players frequently fizzle early because they panic and press the 4th input as soon as the monster gets close to the line, raise **`good_window_ms` to `±220 ms` or `±280 ms`**.

### D. `cue_lead_ms` (`APPROACH TIME: 2.10s` — Range: `800 ms` to `3500 ms`)
- **What it does:** How long a monster takes to walk from the top entrance gate to the contact line (`T`).
- **How to tune:**
  - Lower values (`1200 ms`) make monsters sprint down the lane (reaction test).
  - Higher values (`2400 ms` – `2800 ms`) spawn the monster earlier so it walks more slowly, giving players more time to read its overhead symbol and tap their 3 preparation runes (`A / S / D`).

### E. `break_target` (`VICTORY TARGET: 100 BREAK` — Range: `30` to `180`)
- **What it does:** How many Break points are needed to crack and shatter the Summoner's mask (`Stage 2` cracks at 50% of this target; `Stage 3` shatters at 100% of this target) and win the round (`VICTORY!`).
- **How to tune:**
  - Lowering this to **`70` or `80`** makes shattering the Summoner mask and winning much easier for first-time players.
