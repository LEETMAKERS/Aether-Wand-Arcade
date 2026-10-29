# itch.io page copy

Source for your itch.io project page.

## Page title
Runeweaver — Aether Wand Arcade

## Short description
A custom-controller arena caster. Tap a wand against three IR sensors to prepare spells and counter approaching troops. 60-second scored rounds.

## Cover image
Use `assets/images/build_photo_1.jpeg`.

## Tags
`Custom Controller`, `Arcade`, `Rhythm`, `Action`, `ESP32`, `Hardware`, `Godot`

## Body

### How to play
A troop approaches in one of three lanes and shows its required counter-element.

1. **Inputs 1–3** prepare your spell. Tap any three of the L/C/R targets with the wand. The recipe rule picks the element (majority wins; if all differ, the third tap picks).
2. **Input 4** selects the lane and releases. Tap the sensor of the lane you want to hit.
3. Timing is judged against the troop's contact instant. Correct element + correct lane + accurate release = best Break damage.
4. Reach 100 Break to win. Score is 1.0–10.0.

### Requires the custom controller
Built around the Aether Wand: an ESP32 reading three analog IR sensors through a 3D-printed wand. Wiring and firmware are documented in the source repo.

### A scored round
60 seconds. 21 cues. 84 activations.

## Screenshots
Upload 3–5 from `assets/images/` and from running gameplay.

## Upload
- ZIP the Godot export (Linux x86_64 or Windows).
- Project kind: Game.
- Pricing: Free or $0 name-your-own-price.

## Credits
- Game design & code: [your name / robotics club]
- Hardware: [your name / robotics club]
- Fonts: Jersey 25, BoldsPixels (OFL)
- Built with Godot 4.5.1 + ESP32-WROOM.
