# Hardware

The controller is a small computer with three sensors and a 3D-printed wand.

## What you need

| Part | How many | What it is |
|---|---|---|
| ESP32-WROOM | 1 | A small programmable board (about $5) |
| Infrared sensor | 3 | Detects when something is close — same kind that turns off your phone screen near your ear |
| USB cable | 1 | Connects the ESP32 to the computer (must carry data, not just charge) |
| Jumper wires | ~12 | Wires to connect everything |
| 3D-printed wand | 1 | The thing the player holds (files coming to `models/`) |
| 3D-printed sensor mount | 1 | Holds all three sensors in place (files coming to `models/`) |

## How to wire it

Each sensor has three pins: power, ground, and signal. Connect them to the ESP32 like this:

| Sensor | ESP32 pin | What it does in the game |
|---|---|---|
| Left | GPIO 34 | Left lane / Fire |
| Center | GPIO 35 | Center lane / Ice |
| Right | GPIO 32 | Right lane / Lightning |
| All power | 3V3 | Powers the sensors |
| All ground | GND | Common ground |

The sensors are "active-low" — their reading is high when nothing is nearby and drops low when the wand gets close. The code on the ESP32 handles this automatically; you don't need to worry about it.

## Setting it up

1. Mount the three sensors side by side. Space them apart so waving over one doesn't trigger the next one by accident.
2. Wire them following the table above.
3. Upload the code from [`../firmware/runeweave_esp32.ino`](../firmware/runeweave_esp32.ino) to the ESP32.
4. On Linux, give the game permission to read the USB port: `sudo chmod a+rw /dev/ttyUSB*`
5. Run the game. It finds the ESP32 automatically.

## Schematic

A wiring diagram is coming soon.
