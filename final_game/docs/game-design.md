# Runeweave — game design brief

**Build Runeweave Lite first; add full Runeweave later.** Development environment: Godot 4.5.1 Standard/GDScript on Ubuntu. GitLab is the only repository host required.

This is the current gameplay brief, not a tested implementation or permanently fixed design. Core requirements define the intended interaction. All numerical settings are **provisional prototype defaults**, and all calculations below follow those defaults—not player tests. Final art, element names, presentation details, and concrete architecture remain open. Changes require an explicit decision, not an assistant silently substituting its preferences.

Keep development permissions and coding standards in `AGENTS.md`; keep the current plan, decisions, and test status in `docs/tasks.md`. This brief replaces the previous long specification. It does not replace the editor-first contract.

## 1. The game

Read a troop approaching in one of three lanes. Use three sensor activations to prepare its counter-element, then a fourth to select the lane and release the spell at a shared middle contact line. Correct elemental kills return **Break damage** to the enemy summoner. Finish the round and receive a score from **1.0–10.0**, whether victorious or defeated.

Lite provides the complete four-input interaction. Full Runeweave adds the choice between dependable **Stable** casting and **Wild** casting, which rewards Perfect timing more but ordinary timing less.

### Core requirements

- Exactly three physical targets: left, center, right. No fourth sensor or separate selection/release hardware.
- Inputs one–three prepare a spell; input four alone selects its destination and determines release timing. Preparation inputs are not attacks.
- One committed four-input attempt per troop, across the whole arena. There is only one active exchange, not three independently attackable troops.
- All damaging impacts occur at the middle contact line; player spells do not travel upward along the wall.
- Correct element, correct lane, and accurate release timing produce the best outcomes. Wrong elements can still hurt a troop.
- Every scored attempt runs to its conclusion. Mistakes cost opportunities, not playing time.

## 2. Physical controls and input capabilities

### Current project observations—not independent measurements

The developer reports that the **digital Hall sensors detect fast touches**, but the plastic-covered wand magnet and plastic-covered sensor need to be brought against each other. Treat the current gesture as **tap and withdraw**, not a reliable wave-past gesture. This is a property of the tested assembly, not a claim that every Hall setup requires contact.

IR sensors are being tested as an alternative; reliable operation with all targets installed together is unresolved. If the selected modules are KY-032 units, they detect reflected infrared, supply a binary detection signal, and allow adjustment of triggering sensitivity/distance. They detect obstacles rather than identifying a particular wand. [^1]

A Hall switch responds to magnetic activation/release thresholds, not impact force. Physical contact is the practical gesture in the current build, not a pressure measurement. [^2]

### Stable software input contract

- Use discrete left/center/right activations, their order, and their timing.
- Count a fresh activation once. Remaining active must not produce repeated commands.
- Repeating a target requires deactivation before its next activation. Withdrawal rearms that target; it is not another gameplay input.
- Do not require measured force, continuous distance, wand orientation, swing tracking, held gestures, or simultaneous gestures. Those capabilities are not promised by this setup.
- Normalize physical input and development keyboard input into the same gameplay commands. The ESP32 connection/transport and filtering details must be agreed during integration, not assumed here.
- Keep sensor-specific interpretation outside recipe, combat, and scoring logic. Changing the sensor should preserve the game-facing input contract.

Before accepting a physical build, test each target with the others operating, unintended neighboring activations, hands and between-target movement, rearming, and full casts while watching the display. Comfortable spacing, reliable input pace, and end-to-end timing remain unverified. These are proposed checks, not findings about the IR modules.

## 3. Elements, troops, and recipes

### Data first; final identities later

Start with **three element slots: A, B, C**, corresponding to preparation inputs L, C, R respectively. Suggested temporary names are **Fire, Frost, Lightning**. They are placeholders, not final art requirements.

Each troop has a visual identity and one required counter-element. Suggested stand-ins: a plant-like target countered by A, an ember-like target countered by B, and a metal-like target countered by C. Replace these freely when choosing assets without changing the casting system. Baseline troop health is **2 HP** for every type.

Show the required counter clearly from cue opening. Do not rely on color alone or require newcomers to infer counters from unfinished artwork.

### Shared recipe rule

Look only at the first three accepted activations:

- If one target appears at least twice, its element wins.
- If all three differ, the third activation determines the element.
- Input four never participates in recipe interpretation.

Every prefix therefore produces an element; there are no invalid recipes. Teach the simplest examples first: `LLL` prepares A, `CCC` prepares B, `RRR` prepares C. A mixed prefix such as `LCL` also prepares A.

In **Lite, every recipe is Stable**, including all-different prefixes. In full mode, all-different prefixes are Wild; the other recipes remain Stable.

Examples with the temporary names:

- `LLL | R`: Fire to the right lane.
- `CRL | R`: Fire to the right lane; Stable in Lite, Wild in full mode.
- `CCC | R`: Frost to the right lane, even if Fire was required.

The bar is explanatory notation, not an extra input or mandatory pause. After preparing a spell, the player may wait before input four without physically holding a sensor.

## 4. Exchange, timing, and commitment

A **cue** is one scheduled troop opportunity. Let **T** be its contact time at the middle line.

1. Open the cue, reveal its lane/counter, and clear the cast buffer.
2. Accept three preparation inputs; preview and lock the resulting spell.
3. Accept input four as the only release. Judge lane, element, timing, and mode/style.
4. Resolve once, present the impact at the line, and remove the troop. A survivor breaches and disappears; enemies never accumulate.
5. Clear the attempt at cue close. Future previews cannot accept inputs yet.

### Baseline timing windows

- Cue opens at **T − 2,100 ms**.
- **Perfect:** release from **T − 50 ms through T + 50 ms**, inclusive.
- **Good:** release from **T − 140 ms through T + 120 ms**, excluding Perfect.
- **Early:** release before **T − 140 ms**, after opening; the attempt is spent.
- **Miss/unfinished:** no eligible fourth activation timestamped by **T + 120 ms**.

The first three inputs have no separate timing grade. They may be early or unevenly spaced, provided they occur during the active cue. Perfect takes precedence at its boundaries. Grade from the fourth activation's timestamp, not its animation or a delayed confirmation.

### Anti-mashing and ambiguity

The game uses the first accepted prefix and release; it never searches a longer stream for a better sequence. No manual cancel, retry, or fifth-input repair is available within a cue. Inputs outside the active cue do not buffer into the next one. Holds do not become fresh activations when a new cue opens.

Use a provisional **30 ms confirmation interval** to reject near-simultaneous different-target activations rather than guessing their order. An ambiguous group during preparation or release fails the attempt. A different-target event within the fourth input's pending interval can still invalidate that release; subsequent extra inputs are ignored, without extra damage or penalty. This is disambiguation, not an extra player action or cooldown; validate it on the assembly.

An eligible fourth activation timestamped by **T + 120 ms** may finish confirmation through **T + 150 ms**. Wait for eligible pending inputs before declaring a miss. This does not extend late-hit eligibility.

### Fixed-line presentation

A valid early-side release waits for contact; a valid late-side release still hits the troop at the line. Apply a valid result at the later of **T** and its release-confirmation time, holding the troop's contact marker at the line if needed. Under the baseline settings this is no later than **T + 150 ms**. A too-early release fizzles; it does not leave a lasting trap.

A failure never advances the schedule. Effects, breaches, and summoner reactions must not delay the next legal cue or lock out its inputs.

## 5. Combat and risk/reward

**Troop damage** determines the current troop's survival. **Break** accumulates against the summoner and determines victory/score. They are separate values.

### Lite outcomes; also full-mode Stable outcomes

For correct lane and counter-element:

- **Good:** 2 troop damage, clean kill, **6 Break**.
- **Perfect:** 2 troop damage, clean kill, **8 Break**.

For correct lane but wrong element, in either mode/style:

- **Good:** 1 troop damage, **0 Break**; the survivor breaches at cue close.
- **Perfect:** 2 troop damage, ragged kill, **1 Break**.

Wrong lane, Early release, ambiguous input, or unfinished spell: **0 troop damage, 0 Break**.

### Full-mode Wild addition

All-different prefixes become Wild, with element determined by their final rune:

- A: `CRL` or `RCL`.
- B: `LRC` or `RLC`.
- C: `LCR` or `CLR`.

Only correctly matched, correct-lane rewards change:

- **Wild Good:** 2 troop damage, clean kill, **3 Break**.
- **Wild Perfect:** 2 troop damage, clean kill, **10 Break**.

Thus Wild is a precision wager, not a universal upgrade. With all releases at least Good, correct elements/lanes, and equal Perfect probability p for both styles, expected Break is **6 + 2p** for Stable and **3 + 7p** for Wild; Wild overtakes Stable above **60% Perfect** under those assumptions. Misses and recipe accuracy can change that comparison. This is rule arithmetic, not measured player performance or proof that Wild movements are physically harder.

Waiting from early Good toward Perfect is the intended timing risk. Being progressively later after Perfect earns no bonus. Do not add raw preparation-speed rewards, hidden critical hits, pressure-based damage, or streak multipliers to the baseline.

## 6. Baseline round and cue script

Use a **60-second scored round with 21 cues**. A fully attempted round requires 84 activations. Difficulty increases through cadence and patterns, not hidden acceleration or changing controls.

- First seven contacts: **3.2, 6.4, 9.6, 12.8, 16.0, 19.2, 22.4 seconds**.
- Next seven: **25.2, 28.0, 30.8, 33.6, 36.4, 39.2, 42.0 seconds**.
- Final seven: **44.4, 46.8, 49.2, 51.6, 54.0, 56.4, 58.8 seconds**.

For those three groups, use the following ordered **required counter/lane** pairs. Counter letters are A/B/C; lane letters are L/C/R. This is reference data, not a mandated storage format.

```text
First seven:  A/L, B/C, C/R, A/C, B/L, C/C, A/R
Next seven:   B/R, A/L, A/C, C/R, B/C, C/L, B/R
Final seven:  C/C, B/L, A/R, C/R, C/L, A/L, B/C
```

This gives seven cues per lane and seven per counter, with every pairing represented at least twice. Use the same script/settings for comparable scored attempts. Familiarity with it is allowed; adaptive per-player scored difficulty is not part of this baseline.

**Suggested movement, not final presentation:** reveal at T − 2.1 s, stage at the gate for 0.9 s, then approach at constant speed for 1.2 s. Preparation time, movement time, and contact spacing are separate settings. Keep the contact marker's trajectory aligned with the judgment clock, regardless of decorative sprite movement.

The baseline leaves **150 ms** between a cue's latest confirmation and the next cue opening at the tightest cadence. Finish the final resolution before showing results at 60 seconds. If timings change, recheck separation and preparation comfort; do not blindly preserve this schedule.

## 7. Victory, score, and fair comparison

Victory target: **100 Break**. Reaching it enables the eventual finishing presentation but does not end the round or cap accumulated Break. Below target, show defeat and the same score screen. There is no separate player-health economy, early elimination, or failure stun.

Let **D** be total earned Break and **M** the maximum available in the selected mode/round:

$$
\text{score} = \operatorname{round}_{0.1}\left(\min(10,\max(1,1+9D/M))\right).
$$

Use decimal half-up rounding to one decimal place. Victory depends on raw Break, not rounded score.

- **Lite:** M = 21 × 8 = **168**. All matched Good gives 126 Break → **7.8**; all matched Perfect gives 168 → **10.0**.
- **Full:** M = 21 × 10 = **210**. All Stable Good gives 126 → **6.4**; all Stable Perfect gives 168 → **8.2**; all Wild Good gives 63 → **3.7**; all Wild Perfect gives 210 → **10.0**.
- Zero Break gives **1.0** in both modes. All wrong-element Perfect kills give 21 Break → **2.1 Lite / 1.9 full**.

Rank by raw Break, then clean elemental kills, then correctly matched Perfect kills; otherwise share the position. Save mode and rules version with results, and keep Lite/full leaderboards separate. An aborted scored run is not a completed score.

Derive the maximum from the active rules/cue set, not a separate HUD constant. Freeze settings for each scored run. If cue count, rewards, health, or timing changes, review the target, achievable maximum, benchmarks, cue separation, and leaderboard compatibility. The baseline balance intentionally prevents exclusive use of one lane or one element from reaching victory, even with optimal remaining timing.

## 8. Feedback, practice, and presentation freedom

The UI must communicate:

- Current preparation progress and whether the next input prepares or releases.
- The prepared element; Stable/Wild only when full mode exists.
- The current troop's lane, required counter, and contact instant.
- Outcome and relevant reason: clean kill, wrong-element damage/kill, wrong lane, Early, unfinished, or ambiguous input.

**Preferred starting layout:** three spatially fixed sensor prompts switch from element icons during preparation to lane arrows/initials after input three. Retain small permanent position labels. A nearby three-rune-plus-release strip is a suggestion, not a required node/layout specification.

Preparation feedback must not look like damaging lane attacks. Good and Perfect should be distinguishable. Full mode must distinguish Wild Good's reduced return from a failure, and wrong-element Perfect from a clean elemental success. Effects must not obscure the next cue. Exact art, panels, wording, sounds, animations, and optional statistics/hints are decisions to make during implementation.

Provide clearly unscored practice using the same casting semantics, with supervised explanation and repetition as needed. A starting instruction is:

> Three inputs prepare the spell. The fourth chooses its lane and releases it. Match the troop's symbol and release when it reaches the middle line. Withdraw between repeated taps.

Practice should cover preparation versus release, the simple recipes, lane choice, timing, and commitment. Teach Wild only when implemented. Results must show score, victory/defeat, and Break versus target; richer statistics and coaching can follow.

## 9. Lite now; full later

**Lite includes:** complete four-input capture; forgiving element interpretation; elemental matching; lane/timing judgment; one result per cue; fixed-line impacts; the round/score; phase feedback; practice; results; clean restart; and testing an exported build.

**Defer to full mode:** all-different prefixes becoming Wild; its 3/10 rewards; style-specific preview/feedback and teaching; full-mode scoring and result identity; optional style statistics/hints; and playtesting the risk/reward tradeoff. No separate arena or input engine is implied.

Keep future additions possible by separating rules from presentation, not by implementing unused features now. Inventories, upgrades, persistent armies, online accounts, and a general-purpose combat framework are outside the current scope.

## 10. Development boundaries and a provisional responsibility map

Follow the existing `AGENTS.md`: discussion first; the human authors scenes, nodes, layout, Resources, Inspector assignments, animations, and settings in Godot. Opus explains/plans; GPT-5.3 Codex edits only explicitly approved GDScripts. Preserve explicit typing, composition, deliberate Inspector exports, and bounded changes. Do not duplicate the full coding contract here.

The following are **responsibilities to discuss, not a tested scene tree, required filenames, or instructions to scaffold everything**:

- **Input:** normalize activations and preserve rearming state; no element/combat decisions.
- **Cast capture:** record the prefix, prepared spell, release, and commitment; no independent scoring.
- **Rules:** interpret recipes and judge outcomes/score; use the same interpretation for preview and final judgment.
- **Round coordination:** own the schedule/current cue, apply each outcome once, accumulate results, and reset the run.
- **Presentation:** show supplied troop movement/outcomes and HUD state; never award damage from animations or independently recount raw inputs.

Agree the actual nodes, ownership, typed interfaces, exports, and signal connections for the next increment before coding. The actual editor-authored project—not this proposal—is the source of truth for node paths and wiring. Position lane/contact markers in the editor rather than baking screen coordinates into rules. A 1080p-oriented layout is a starting target; test actual display scaling/readability.

### Reliability principles in plain language

- **Settings versus progress:** starting HP, counter identity, cue times, and rewards are definitions; remaining HP, rune count, current score, and attempt status are live state.
- **Editable data when useful:** custom Resources are an option for Inspector-authored definitions, not a demand to create a class for every concept. Godot supports Inspector editing of Resources; loaded Resources can be shared, so do not use a shared definition as each troop's changing health. [^3]
- **One clock:** movement and judging must share elapsed run time. Use a monotonic timing source rather than adjustable wall-clock time; Godot documents ticks for this purpose. Agree precision/conversion details during planning. [^4]
- **One outcome:** commitment, confirmation, and visible application are distinct steps, but each cue—including a miss—produces exactly one result. Input eligibility follows timestamps, not a stale frame flag; animations never apply a second result.
- **Clean restart:** discard old recipes, pending events, callbacks, troops/effects, and totals. Preserve knowledge of targets still held active. Old attempts cannot affect new runs, and practice cannot contribute to scored totals.

Suggested work order: **runnable shell → capture/HUD → one timed exchange → complete Lite round → polish/export checks → full mode later**. This is an adjustable starting sequence. Record the current approved step and actual checks in `docs/tasks.md`; do not confuse a plan or script parse check with a working Godot game.

### Reference links

- [GDScript style](https://docs.godotengine.org/en/4.5/tutorials/scripting/gdscript/gdscript_styleguide.html)
- [Static typing](https://docs.godotengine.org/en/4.5/tutorials/scripting/gdscript/static_typing.html)
- [Inspector exports](https://docs.godotengine.org/en/4.5/tutorials/scripting/gdscript/gdscript_exports.html)
- [Resources](https://docs.godotengine.org/en/4.5/tutorials/scripting/resources.html)


[^1]: KY-032 Infrared proximity Sensor | Joy-IT.

[^2]: Understanding and Applying Hall Effect Sensor Data Sheets.

[^3]: Untitled.

[^4]: Time .