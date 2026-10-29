# Aether-Wand-Arcade · Runeweave

A custom-controller arena caster. Counter approaching troops by preparing a spell with three sensor taps, then releasing it down the matching lane at the contact line. The controller is a 3D-printed wand and an ESP32-WROOM reading three analog IR sensors.

Built for the robotics club integration game night. Game night went well.

---

## The physical controller

- **ESP32-WROOM** dev board.
- **3 × analog IR proximity sensors** (active-low: HIGH at idle, drops LOW when a hand approaches).
- **3D-printed wand** that breaks each sensor's detection field when tapped against the target.
- USB cable from ESP32 to the host PC.

The ESP32 reads the three IR sensors on ADC1 pins (GPIO 34, 35, 32), applies per-sensor thresholds with hysteresis, and sends activation events over USB serial at 115200 baud. A Python bridge (auto-started by the game) forwards events to Godot over UDP localhost:4242.

See [`hardware/README.md`](hardware/README.md) for wiring and [`firmware/README.md`](firmware/README.md) for the serial protocol.

![Build photo](assets/images/build_photo_1.jpeg)
![Build photo](assets/images/build_photo_2.jpeg)
![Build photo](assets/images/build_photo_3.jpeg)

---

## How it plays

1. A troop approaches in one of three lanes (Left / Center / Right) and shows its required counter-element.
2. **Inputs 1–3** prepare your spell. Tap any three of the L/C/R targets with the wand. The recipe rule picks the element:
   - If one target appears twice or more, its element wins (`LLL` → A, `LCL` → A).
   - If all three differ, the third tap picks the element (`LCR` → C).
3. **Input 4** selects the lane **and** releases. Tap the sensor of the lane you want to hit. Timing is judged against the troop's contact instant at the middle line.
4. Correct element + correct lane + accurate release = best Break damage. Wrong element still hurts. Wrong lane, Early release, or unfinished spell = 0.
5. Accumulate Break against the summoner. Reach 100 Break to win. Score is `1.0–10.0` based on Break vs the round maximum.

A scored round is 60 seconds, 21 cues, 84 activations.

---

## Repository layout

```
Aether-Wand-Arcade/
├── assets/images/       # Build photos
├── final_game/          # Godot 4.5.1 project (source + docs)
│   ├── scenes/          # GDScript: input_router, cast_capture, recipe_rules, cue_judge, hud, main, troop
│   ├── assets/          # Fonts + sprite sheets
│   └── docs/            # game-design, esp32-sensor-guide, settings-guide, tasks
├── firmware/            # ESP32 firmware (.ino) + protocol docs
├── hardware/            # Wiring + BOM
├── models/              # 3D-print files (to be added)
└── README.md
```

---

## How to run

### From source (Godot 4.5.1)

1. Flash [`firmware/runeweave_esp32.ino`](firmware/runeweave_esp32.ino) to the ESP32-WROOM (see [`firmware/README.md`](firmware/README.md)).
2. Wire the sensors per [`hardware/README.md`](hardware/README.md).
3. Open `final_game/project.godot` in **Godot 4.5.1 Standard**.
4. Run the main scene. The game auto-starts the serial→UDP bridge.
5. Keyboard fallback (`1`/`2`/`3` or `A`/`S`/`D`) works alongside the wand.

### Linux USB permissions

```bash
sudo chmod a+rw /dev/ttyUSB* /dev/ttyACM*
# or permanently: sudo usermod -a -G dialout $USER
```

---

## Scoring

```
score = round( min(10, max(1, 1 + 9·D/M)) , 1 decimal )
```

- M = 168 (21 cues × 8 Break max). All Good → 7.8. All Perfect → 10.0. Zero Break → 1.0.

---

## Documentation

- [`final_game/docs/game-design.md`](final_game/docs/game-design.md) — full design brief
- [`final_game/docs/esp32-sensor-guide.md`](final_game/docs/esp32-sensor-guide.md) — sensor setup + Ubuntu commands
- [`final_game/docs/settings-guide.md`](final_game/docs/settings-guide.md) — tunable values
- [`final_game/docs/tasks.md`](final_game/docs/tasks.md) — development log
- [`hardware/README.md`](hardware/README.md) — wiring
- [`firmware/README.md`](firmware/README.md) — serial protocol

## License

MIT — see [`LICENSE`](LICENSE).
