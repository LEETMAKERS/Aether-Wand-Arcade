# Runeweave — tasks and working checkpoint

**Current target: Lite.** This is a living plan, not a validated architecture or permission to generate the game. Update it after each agreed increment. Gameplay belongs in `docs/game-design.md`; permissions and coding standards belong in `AGENTS.md`.

## Reported starting point

- GitLab repository and remote exist; no GitHub mirror is needed. [^1]
- The Godot project exists; VS Code/GitLab chat responds. [^1]
- `AGENTS.md` and the previous design have been copied into the project. [^1]
- The last supplied listing showed an empty `scenes/main` directory and untracked project/document files. A saved runnable Main scene and a committed baseline still need confirmation. [^1]
- Hall fast-touch activation is developer-reported; combined IR operation and comfortable screen-watching use are unverified. No gameplay implementation or runtime test is claimed here.

## Suggested next milestone — runnable shell, then capture/HUD

### Next action: confirm the shell in Godot

- [x] If not already done, create/save a blank Main scene in the editor and select it as the project entry scene.
- [x] Run the project; confirm the window opens and inspect Output/Debugger.
- [x] Replace the previous game brief with the condensed version. Keep the existing `AGENTS.md`.
- [ ] Review the intended repository files, then commit and push this baseline. Do not recreate the repository or remote.

**Completion check:** a saved scene runs, the project/docs are versioned, and the actual scene tree is known. Mark these complete only after checking.

### Next discussion with Opus — no implementation permission yet

Agree the smallest capture/HUD increment: actual nodes, what each responsibility owns, minimal typed interfaces, required Inspector assignments/signals, and approved script filenames. Choose a simple keyboard mapping for development, such as A/S/D for left/center/right. Do not build the complete future hierarchy.

Then create the agreed UI/nodes in Godot. Request only the named GDScripts after approving the plan.

### Capture/HUD acceptance checks

- [ ] Three inputs show preparation progress without firing lane attacks.
- [ ] After input three, the prepared element is visible and prompts change to release/lane selection.
- [ ] Input four chooses the lane and commits; a fifth input cannot repair it.
- [ ] Test repeated, mixed-majority, and all-different prefixes. All remain Stable in Lite.
- [ ] Holding does not repeat; withdrawal followed by reactivation permits another input.
- [ ] Starting another demonstration opportunity clears the recipe without converting a held target into a fresh input. Operator reset is not an in-cue retry mechanic.

**Not needed yet:** troop art, a complete round, polished effects, Wild rewards, or a final Resource/class inventory. This demonstration validates capture, not timed combat.

## Hardware checks before physical-input acceptance

These can proceed alongside keyboard-based development; they are not completed tests.

- [ ] Test the mounted targets together: intended channel, unintended neighboring activation, hands, and between-target movement.
- [ ] Test rearming and complete casts while watching the screen.
- [ ] Decide Hall versus IR from observed behavior; record the chosen assembly and remaining problems.
- [ ] Agree ESP32 transport, activation timestamps, filtering, and ambiguity handling. Verify that physical and keyboard input reach the same gameplay path.

## Suggested later milestones — replan as needed

1. **One timed exchange:** one reusable troop and line; correct/wrong element, wrong lane, Early, Perfect/Good, ambiguous input, and unfinished outcomes. Check every timing boundary, including eligible pending input at cue close. Confirm fixed-line impact and exactly one applied result.
2. **Complete Lite:** enter the agreed schedule; verify cue separation, score maximum/rounding, victory without early termination, unscored practice, results, abort, and restart. Check holds across cue boundaries and stale events after reset.
3. **Polish and delivery:** choose assets and tune readability; verify Inspector assignments and signal wiring; run repeated attempts in an exported build. Effects must not suppress the next cue. A parse/import check alone does not establish gameplay correctness.
4. **Full later:** implement the Wild differences from the game brief, keep Lite playable, and retest scoring, feedback, and timing.

## Live handoff — fill after agreement/testing

- **Current approved task:** none recorded; proposed next action is confirming the runnable shell.
- **Approved script edits:** none recorded here.
- **Actual scene tree:** record after editor inspection.
- **Last working commit:** record after baseline verification.
- **Checks actually run and results:** not yet recorded.
- **Known issues:** not yet recorded.
- **Open decisions:** final elements/troop assets, detailed interface/effects, physical sensor choice/spacing, transport/timing details, and increment-specific architecture.

Record meaningful changes to gameplay defaults in the game brief. Keep this file focused on present work and verified checkpoints, not a second copy of the design.
