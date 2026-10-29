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
