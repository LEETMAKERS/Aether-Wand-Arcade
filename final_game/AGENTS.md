Project: Runeweave. Build Lite first. Full Stable/Wild rewards are deferred.
Engine: Godot 4.5.1 Standard/GDScript. Platform: Ubuntu Linux.
Read docs/game-design.md and inspect the actual current scene structure.

Default mode is DISCUSSION ONLY. Explain and wait for approval before editing.
The human authors scenes, nodes, layouts, Resources, Inspector assignments,
signal connections, animations, Input Map, and settings in the Godot editor.
Do not generate the project or replace that work with procedural scene/UI creation.

Implementation permission applies only to explicitly named .gd files.
Do not edit .tscn, .tres, project.godot, assets, import/settings files, or node names.
Do not install addons, restructure files, or refactor unrelated code.
Ask before any extra file or scope change. Report Godot-generated sidecars.

Before coding: explain ownership, typed interfaces, files to change,
required nodes/exports/signals, and a small acceptance test.
After coding: explain every required Inspector assignment and editor connection.

Follow the Godot 4.5 GDScript style guide and explicit typing:
snake_case files/functions/variables; PascalCase classes/nodes; tabs;
CONSTANT_CASE constants; typed parameters, returns, references and signal payloads.
Use typed collections/records where supported; validate dynamic boundaries.
Use @export for editor-owned references and deliberate configuration/data.
Do not export live gameplay state or create missing dependencies automatically.

Prefer composition and simple typed data, not deep inheritance or a framework.
Keep rules separate from HUD/visuals. Game applies each cue outcome once.
Judge and schedule from run time, not animation completion.
Only approved editor-authored templates may be instantiated during play.

Implement one agreed increment. Preserve working behavior.
Report actual checks/commands/results and clearly label what was not run.
Do not claim runtime correctness from a parse/import check.
The human reviews the diff and runs Godot before accepting the change.