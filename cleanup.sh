#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# Aether-Wand-Arcade — repo cleanup script
# Run from the repo root (the folder containing final_game/).
# Usage:  bash cleanup_repo.sh
# ============================================================================

if [ ! -d "final_game" ]; then
  echo "ERROR: Run this from the repo root (must contain final_game/)."
  echo "Current dir: $(pwd)"
  exit 1
fi

echo "==> [1/9] Removing junk files..."

# Temp / private files
rm -f final_game/tmp.md
rm -f final_game/agy_chat_export.tar.gz
rm -f final_game/high_scores.txt

# Runtime telemetry / logs (keep the logging CODE in .gd, remove the data files)
rm -f final_game/game_log.*
rm -f final_game/sensor_telemetry.*

# Old prototype folder (conflicts with final_game/)
rm -rf game/

echo "==> [2/9] Adding showcase photos..."

PHOTO_SRC="${HOME}/Downloads/Zapzap"
if [ -d "$PHOTO_SRC" ]; then
  cp "$PHOTO_SRC/WhatsApp Image 2026-10-27 at 20.08.16.jpeg" assets/images/build_photo_1.jpeg
  cp "$PHOTO_SRC/WhatsApp Image 2026-10-27 at 20.08.17.jpeg" assets/images/build_photo_2.jpeg
  cp "$PHOTO_SRC/WhatsApp Image 2026-10-27 at 20.08.18.jpeg" assets/images/build_photo_3.jpeg
  echo "    Copied 3 photos -> assets/images/"
else
  echo "    WARNING: $PHOTO_SRC not found. Skipping photos."
  echo "    Copy your build photos manually to assets/images/"
fi

echo "==> [3/9] Creating .gitignore..."

cat > .gitignore << 'GITIGNORE_EOF'
# --- Godot 4.5 ---
.godot/
# .import files are committed for assets that ship with the project.
# Do NOT add *.import here — that would untrack committed imports.

# --- Godot export artifacts (do not commit built binaries) ---
*.exe
*.x86_64
*.pck
build/
build_debug/
final_build/

# --- Runtime data (do not commit playtest logs) ---
high_scores.txt
sensor_telemetry.csv
game_log.csv
**/sensor_telemetry.csv
**/game_log.csv
**/sensor_telemetry.*.translation
**/game_log.*.translation

# --- OS junk ---
.DS_Store
Thumbs.db
*.tmp
tmp.md

# --- Editor / IDE ---
.vscode/
.idea/
*.swp
*.swo

# --- ESP32 / Arduino ---
firmware/build/
*.elf
*.map

# --- KiCad ---
hardware/schema/*.bak
hardware/schema/*-bak
hardware/schema/*-cache.lib
hardware/schema/_autosave-*
hardware/schema/*-rescue.lib

# --- Archives / private ---
*.tar.gz
agy_chat_export.tar.gz

# --- 3D print previews ---
models/*.stl.png
GITIGNORE_EOF

echo "==> [4/9] Creating LICENSE..."

cat > LICENSE << 'LICENSE_EOF'
MIT License

Copyright (c) 2026 Robotics Club — Aether-Wand-Arcade

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
LICENSE_EOF

echo "==> [5/9] Creating main README.md..."

cat > README.md << 'README_EOF'
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
README_EOF

echo "==> [6/9] Creating firmware/..."

mkdir -p firmware

cat > firmware/runeweave_esp32.ino << 'INO_EOF'
// ============================================================================
// RUNEWEAVE - ESP32-WROOM Active-Low Analog IR Sensor Controller (USB Serial @ 115200)
// Sensors read HIGH (2000+) at idle, and drop LOW (<200) when a hand is near.
// Sends "A:val", "B:val", "C:val" so Godot triggers gameplay AND logs the ADC value.
// ============================================================================

#include <Arduino.h>

// Set to true to see live numbers in Arduino Serial Monitor for tuning.
// MUST be false when running the game so the serial port isn't blocked!
const bool DEBUG_RAW_VALUES = false;

struct SensorChannel {
  int pin;
  const char* code;
  int triggerBelow;            // Hand detected: reading drops BELOW this number
  int releaseAbove;            // Re-arm: reading must rise ABOVE this number (hand moved away)
  unsigned long releaseHoldMs; // Must stay above releaseAbove for this long (stops double actuations)
  unsigned long cooldownMs;    // Minimum ms between triggers on this same sensor
  bool triggered;
  unsigned long lastTriggerMs;
  unsigned long releaseStartMs;
};

// --- INDIVIDUAL CONFIGURATION FOR EACH SENSOR ---
// You can adjust each sensor independently based on how it behaves:
SensorChannel sensors[3] = {
  // Pin, Code, TriggerBelow, ReleaseAbove, ReleaseHoldMs, CooldownMs, triggered, lastTriggerMs, releaseStartMs
  { 34,   "A",  200,          1000,         40,            100,        false,     0,             0 }, // Left   (Target A)
  { 35,   "B",  200,          1000,         40,            100,        false,     0,             0 }, // Center (Target B)
  { 32,   "C",  200,          1000,         40,            100,        false,     0,             0 }  // Right  (Target C)
};

// Reads 4 samples and averages them to filter electrical ADC noise
int readSmoothed(int pin) {
  long sum = 0;
  for (int i = 0; i < 4; i++) {
    sum += analogRead(pin);
  }
  return (int)(sum / 4);
}

void setup() {
  Serial.begin(115200);
  analogReadResolution(12); // ESP32 ADC: 0 .. 4095

  pinMode(sensors[0].pin, INPUT);
  pinMode(sensors[1].pin, INPUT);
  pinMode(sensors[2].pin, INPUT);

  delay(300);
}

void loop() {
  unsigned long now = millis();

  if (DEBUG_RAW_VALUES) {
    Serial.printf("L:%4d | C:%4d | R:%4d\n",
      readSmoothed(sensors[0].pin),
      readSmoothed(sensors[1].pin),
      readSmoothed(sensors[2].pin));
    delay(100);
    return;
  }

  for (int i = 0; i < 3; i++) {
    int val = readSmoothed(sensors[i].pin);

    if (!sensors[i].triggered) {
      // Trigger: reading dropped below this sensor's threshold
      if (val < sensors[i].triggerBelow && (now - sensors[i].lastTriggerMs >= sensors[i].cooldownMs)) {
        sensors[i].triggered = true;
        sensors[i].lastTriggerMs = now;
        sensors[i].releaseStartMs = 0;
        // Sends e.g. "A:145" - Godot plays Target A and records 145 in sensor_telemetry.csv!
        Serial.printf("%s:%d\n", sensors[i].code, val);
      }
    } else {
      // Re-arm: reading must stay continuously above releaseAbove for releaseHoldMs
      if (val > sensors[i].releaseAbove) {
        if (sensors[i].releaseStartMs == 0) {
          sensors[i].releaseStartMs = now;
        }
        if (now - sensors[i].releaseStartMs >= sensors[i].releaseHoldMs) {
          sensors[i].triggered = false;
          sensors[i].releaseStartMs = 0;
        }
      } else {
        // Bounced back down, reset the hold timer to prevent double-firing
        sensors[i].releaseStartMs = 0;
      }
    }
  }

  delay(2); // ~500 Hz polling loop (< 2 ms latency)
}
INO_EOF

cat > firmware/README.md << 'FW_EOF'
# Firmware

The ESP32-WROOM firmware reads three analog IR proximity sensors and sends activation events to the Godot game.

## Files

- `runeweave_esp32.ino` — the Arduino sketch uploaded to the ESP32-WROOM.

## Serial protocol

- **Baud:** 115200, 8N1
- **Format:** `<LETTER>:<ADC_VALUE>\n`  (e.g. `A:145\n`)
  - `A` = Left sensor (Target A / Fire / Left lane)
  - `B` = Center sensor (Target B / Ice / Center lane)
  - `C` = Right sensor (Target C / Lightning / Right lane)
- The ADC value (0–4095) is included so the game can log sensor telemetry, but the game only uses the letter for gameplay.

## How it reaches Godot

The ESP32 → Godot path is a 2-hop bridge:

1. ESP32 sends `A:145\n` over USB serial.
2. A Python bridge (auto-started by `main.gd`) reads `/dev/ttyUSB*` at 115200 and forwards each line to UDP `127.0.0.1:4242`.
3. Godot's `input_router.gd` listens on UDP 4242 and parses the letter.

The bridge auto-detects the ESP32's serial port and reconnects if unplugged.

## Testing without the ESP32

With the game running, send fake activations directly to the UDP port:

```bash
echo "A" > /dev/udp/127.0.0.1/4242
echo "B" > /dev/udp/127.0.0.1/4242
echo "C" > /dev/udp/127.0.0.1/4242
echo "START" > /dev/udp/127.0.0.1/4242
echo "RESET" > /dev/udp/127.0.0.1/4242
```

Accepted on UDP 4242: `A`/`1`/`LEFT`, `B`/`2`/`CENTER`, `C`/`3`/`RIGHT`, `START`/`S`, `RESET`/`R`.

## Uploading

1. Install Arduino IDE with ESP32 board support.
2. Select board: **ESP32 Dev Module** (or ESP32-WROOM).
3. Select port: `/dev/ttyUSB0` (Linux) or equivalent.
4. Open `runeweave_esp32.ino`.
5. Set `DEBUG_RAW_VALUES = true` to tune thresholds in the Serial Monitor.
6. Set `DEBUG_RAW_VALUES = false` before playing (frees the serial port for the game).
7. Upload.

## Tuning

Each sensor has independent `triggerBelow` and `releaseAbove` thresholds (active-low: HIGH at idle, LOW when hand near). Adjust per-sensor if one triggers too easily or not at all. See the comments in the `.ino`.
FW_EOF

echo "==> [7/9] Creating hardware/README.md..."

mkdir -p hardware

cat > hardware/README.md << 'HW_EOF'
# Hardware

The Aether-Wand-Arcade controller is an ESP32-WROOM reading three analog IR proximity sensors through a 3D-printed wand.

## Bill of materials

| Part | Qty | Notes |
|---|---|---|
| ESP32-WROOM dev board | 1 | Any variant with ADC1 pins exposed |
| Analog IR proximity sensor | 3 | Active-low: HIGH at idle (~2000+), LOW when hand near (<200) |
| USB cable (data, not charge-only) | 1 | ESP32 → host PC |
| Jumper wires | ~12 | 3V3 + GND bus + 3 signal |
| 3D-printed wand | 1 | See [`../models/`](../models/) |
| 3D-printed sensor mounts | 3 | See [`../models/`](../models/) |

## Pin map

| Sensor | ESP32-WROOM GPIO | ADC | Game target |
|---|---|---|---|
| Left IR OUT | GPIO 34 | ADC1_CH6 | A (Left / Fire) |
| Center IR OUT | GPIO 35 | ADC1_CH7 | B (Center / Ice) |
| Right IR OUT | GPIO 32 | ADC1_CH4 | C (Right / Lightning) |
| All VCC | 3V3 | — | Power |
| All GND | GND | — | Common ground |

> Use ADC1 pins (32–39) on the ESP32-WROOM. ADC2 pins conflict with Wi-Fi. GPIO 34/35/32 are input-only ADC pins — perfect for reading analog sensors.

## Wiring

```
ESP32-WROOM              IR Sensor ×3
─────────────            ┌──────────────────────────────┐
3V3  ────────────────────┤ VCC  (all three sensors)      │
GND  ────────────────────┤ GND  (all three sensors)      │
GP34 ────────────────────┤ OUT  (Left sensor)            │
GP35 ────────────────────┤ OUT  (Center sensor)          │
GP32 ────────────────────┤ OUT  (Right sensor)           │
                         └────────────────────────────────┘
                  USB ────────► Host PC (Godot + bridge)
```

## Sensor behavior

The IR sensors are **active-low analog**:
- **Idle** (no hand near): ADC reads HIGH (~2000–4095).
- **Hand near**: ADC reads LOW (<200, drops sharply).

The firmware applies per-sensor thresholds (default `triggerBelow=200`, `releaseAbove=1000`) with hysteresis to prevent double-firing. Adjust these in [`../firmware/runeweave_esp32.ino`](../firmware/runeweave_esp32.ino) if a sensor triggers too easily or needs the hand closer.

## Setup checklist

1. Mount the three IR sensors side by side, spaced so the wand on one doesn't trigger its neighbors.
2. Wire per the pin map above.
3. Flash [`../firmware/runeweave_esp32.ino`](../firmware/runeweave_esp32.ino).
4. Set `DEBUG_RAW_VALUES = true`, open Serial Monitor, wave your hand over each sensor to confirm raw readings.
5. Set `DEBUG_RAW_VALUES = false` and close the Serial Monitor before launching the game.
6. Give Ubuntu USB access: `sudo chmod a+rw /dev/ttyUSB*`.

## Schematic

Add a KiCad/Fritzing schematic in `schema/` if you make one. A photo of the wired breadboard works too.
HW_EOF

echo "==> [8/9] Creating models/ and itch/..."

mkdir -p models itch

cat > models/README.md << 'MODELS_EOF'
# 3D Models

3D-printable files for the Aether-Wand-Arcade controller. Files to be added.

## Planned files

| File | Description | Status |
|---|---|---|
| `wand.stl` | The wand the player taps against the sensors | Pending |
| `sensor_mount_left.stl` | Mount for the left IR sensor | Pending |
| `sensor_mount_center.stl` | Mount for the center IR sensor | Pending |
| `sensor_mount_right.stl` | Mount for the right IR sensor | Pending |
| `base.stl` | Base holding the three sensor mounts in alignment | Pending |

## Print notes

- PLA or PETG. PETG recommended for the wand (impact resistance).
- ≥30% infill on sensor mounts for rigidity.
- Orient the wand so layer lines are parallel to the tapping surface to reduce delamination.
MODELS_EOF

cat > itch/README.md << 'ITCH_EOF'
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
ITCH_EOF

echo "==> [9/9] Updating final_game/docs/esp32-sensor-guide.md..."

cat > final_game/docs/esp32-sensor-guide.md << 'GUIDE_EOF'
# ESP32-WROOM Analog IR Sensor Guide for Runeweave

The canonical firmware lives in [`../../firmware/runeweave_esp32.ino`](../../firmware/runeweave_esp32.ino). This guide covers wiring, uploading, and the host-side bridge.

## 1. Upload the firmware

1. Open **Arduino IDE**, select board **ESP32 Dev Module**.
2. Select port `/dev/ttyUSB0` (Linux).
3. Open `firmware/runeweave_esp32.ino`.
4. Set `DEBUG_RAW_VALUES = true` to tune thresholds in the Serial Monitor.
5. Set `DEBUG_RAW_VALUES = false` before playing.
6. Upload.

## 2. Wiring

| Sensor | ESP32-WROOM Pin | Game Target |
| :--- | :--- | :--- |
| **Left IR OUT** | **GPIO 34** | Target A (Left / Fire) |
| **Center IR OUT** | **GPIO 35** | Target B (Center / Ice) |
| **Right IR OUT** | **GPIO 32** | Target C (Right / Lightning) |
| **All VCC** | **3V3** | Power |
| **All GND** | **GND** | Ground |

Sensors are active-low analog: HIGH (~2000+) at idle, LOW (<200) when a hand is near. See [`../../hardware/README.md`](../../hardware/README.md) for the full wiring guide.

## 3. Ubuntu setup

### Step 1: USB permissions
```bash
sudo chmod a+rw /dev/ttyUSB* /dev/ttyACM*
# permanent: sudo usermod -a -G dialout $USER
```

### Step 2: Verify the ESP32 output
Close Arduino Serial Monitor first (only one program can hold the port):
```bash
stty -F /dev/ttyUSB0 115200 raw -echo && cat /dev/ttyUSB0
```
Wave your hand over Left, Center, Right — you should see `A:val`, `B:val`, `C:val` lines.

### Step 3: Launch the game
The game's `main.gd` auto-starts the Python USB-Serial → UDP bridge in the background. It auto-detects `/dev/ttyUSB0` (or fallbacks) at 115200 baud and reconnects if unplugged. Keyboard keys (`1`/`2`/`3` or `A`/`S`/`D`) work alongside the wand.

## 4. Troubleshooting

### Test the receiver without the ESP32
```bash
echo "A" > /dev/udp/127.0.0.1/4242
echo "B" > /dev/udp/127.0.0.1/4242
echo "C" > /dev/udp/127.0.0.1/4242
```

### Accepted messages on UDP 4242
- `A` / `1` / `LEFT` → Left target
- `B` / `2` / `CENTER` → Center target
- `C` / `3` / `RIGHT` → Right target
- `START` / `S` → Start round
- `RESET` / `R` → Reset round

### Adjust sensitivity
In `firmware/runeweave_esp32.ino`, edit the per-sensor `triggerBelow` and `releaseAbove` values. Lower `triggerBelow` if the hand must get too close; raise it if it triggers by itself.
GUIDE_EOF

echo ""
echo "==> Done! Review the changes:"
echo "    git status"
echo "    git diff --stat"
echo ""
echo "==> When ready to commit:"
echo "    git add -A"
echo "    git commit -m 'Clean up repo for showcase: add firmware, hardware docs, README, .gitignore'"
echo "    git push"
