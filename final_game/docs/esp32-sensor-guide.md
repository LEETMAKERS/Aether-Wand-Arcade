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
