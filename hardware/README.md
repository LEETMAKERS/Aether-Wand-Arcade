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
