# The Controller: ESP32 and Sensors

This page explains how the physical controller works — the small computer, the sensors, and how they talk to the game. You don't need to understand any of this to play. But if you're curious or want to build one yourself, read on.

## The parts

- **ESP32-WROOM** — a small, cheap programmable board (about $5). It's the "brain" of the controller. It reads the sensors and sends messages to the computer.
- **Three infrared sensors** — these detect when something is close. They're the same kind of sensor that turns off your phone screen when you hold it to your ear. Each one watches one lane (left, center, right).
- **A 3D-printed wand** — the player waves this over the sensors.

## How a wave becomes a spell

1. The player waves the wand over a sensor.
2. The sensor's reading changes (it drops from high to low — "something is close").
3. The ESP32 notices this change and sends a short message over USB: `A` for left, `B` for center, `C` for right.
4. A helper program (started automatically by the game) passes this message to the Godot game.
5. The game shows the spell flying at the monster.

This all happens in under 2 milliseconds. It feels instant.

## Wiring

| Sensor | ESP32 pin | Lane |
|---|---|---|
| Left | GPIO 34 | Left |
| Center | GPIO 35 | Center |
| Right | GPIO 32 | Right |
| All power | 3V3 | — |
| All ground | GND | — |

The ESP32 uses pins 34, 35, and 32 because those can read smoothly changing values (not just on/off). Some other pins on the ESP32 can't do this while Wi-Fi is turned on, so these three are the safe choice.

## Running it yourself

1. **Upload the code** — open [`../../firmware/runeweave_esp32.ino`](../../firmware/runeweave_esp32.ino) in the Arduino IDE, select the ESP32 board, and upload it.
2. **Wire the sensors** — follow the table above. See [`../../hardware/README.md`](../../hardware/README.md) for more detail.
3. **Give USB permission** (Linux only) — `sudo chmod a+rw /dev/ttyUSB*`
4. **Run the game** — open `final_game/` in Godot 4.5.1 and press play. The game finds the ESP32 automatically.

## Testing without the controller

You can fake sensor triggers by sending messages directly to the game:

```bash
echo "A" > /dev/udp/127.0.0.1/4242
echo "B" > /dev/udp/127.0.0.1/4242
echo "C" > /dev/udp/127.0.0.1/4242
```

This is useful if you want to try the game without building the controller.
