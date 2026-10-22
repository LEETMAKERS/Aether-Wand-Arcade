# ESP32-WROOM Analog IR Sensor Guide for Runeweave

---

## 1. ESP32-WROOM Arduino Program (Copy & Upload First)

Open **Arduino IDE**, select board **ESP32 Dev Module** (Port `/dev/ttyUSB0`), paste this entire program, and click **Upload**:

```cpp
// ============================================================================
// RUNEWEAVE - ESP32-WROOM Analog IR Sensor Controller (USB Serial @ 115200)
// Sends "A" (Left), "B" (Center), "C" (Right) to the Godot game.
// ============================================================================

#include <Arduino.h>

// --- 1. ANALOG IR SENSOR PINS (Use ADC1 pins on ESP32-WROOM) ---
const int PIN_LEFT   = 34; // Target A (Left / Fire)
const int PIN_CENTER = 35; // Target B (Center / Ice)
const int PIN_RIGHT  = 32; // Target C (Right / Lightning)

// --- 2. SENSOR DIRECTION & SENSITIVITY ---
// How much the analog reading (0..4095) must change from idle when a hand is near.
// - Lower = more sensitive (triggers from farther away, e.g. 250)
// - Higher = less sensitive (hand must be closer, e.g. 600)
const int TRIGGER_DELTA = 400;

// Hysteresis release margin (must return within this distance of baseline to re-arm)
const int RELEASE_DELTA = 180;

// Minimum time (ms) between triggers on the same sensor (debounce)
const unsigned long COOLDOWN_MS = 80;

// Set to true if you want to see raw numbers in Arduino Serial Monitor for tuning.
// MUST be false when playing the game!
const bool DEBUG_RAW_VALUES = false;

struct SensorChannel {
  int pin;
  const char* code;
  int baseline;
  bool triggered;
  unsigned long lastTriggerMs;
};

SensorChannel sensors[3] = {
  { PIN_LEFT,   "A", 0, false, 0 },
  { PIN_CENTER, "B", 0, false, 0 },
  { PIN_RIGHT,  "C", 0, false, 0 }
};

// Reads 4 samples and averages them to remove analog noise
int readSmoothed(int pin) {
  long sum = 0;
  for (int i = 0; i < 4; i++) {
    sum += analogRead(pin);
  }
  return (int)(sum / 4);
}

// Calibrates idle room lighting on startup (keep hands away for 1 second after boot/reset)
void calibrateBaselines() {
  for (int i = 0; i < 3; i++) {
    long sum = 0;
    for (int s = 0; s < 32; s++) {
      sum += readSmoothed(sensors[i].pin);
      delay(5);
    }
    sensors[i].baseline = (int)(sum / 32);
    sensors[i].triggered = false;
  }
}

void setup() {
  Serial.begin(115200);
  analogReadResolution(12); // 0 .. 4095

  pinMode(PIN_LEFT, INPUT);
  pinMode(PIN_CENTER, INPUT);
  pinMode(PIN_RIGHT, INPUT);

  delay(300);
  calibrateBaselines();
}

void loop() {
  unsigned long now = millis();

  if (DEBUG_RAW_VALUES) {
    Serial.printf("L:%d (base %d) | C:%d (base %d) | R:%d (base %d)\n",
      readSmoothed(PIN_LEFT), sensors[0].baseline,
      readSmoothed(PIN_CENTER), sensors[1].baseline,
      readSmoothed(PIN_RIGHT), sensors[2].baseline);
    delay(100);
    return;
  }

  for (int i = 0; i < 3; i++) {
    int val = readSmoothed(sensors[i].pin);
    // Works automatically whether your IR sensor voltage goes UP or DOWN when a hand approaches!
    int diff = abs(val - sensors[i].baseline);

    if (!sensors[i].triggered) {
      if (diff >= TRIGGER_DELTA && (now - sensors[i].lastTriggerMs >= COOLDOWN_MS)) {
        sensors[i].triggered = true;
        sensors[i].lastTriggerMs = now;
        Serial.println(sensors[i].code); // Sends "A\n", "B\n", or "C\n"
      }
    } else {
      // Only re-arm once the hand moves away (hysteresis prevents double-firing)
      if (diff <= RELEASE_DELTA) {
        sensors[i].triggered = false;
      }
    }
  }

  delay(2); // ~500 Hz polling (< 2 ms latency)
}
```

---

## 2. Wiring Your 3 Analog IR Sensors to the ESP32-WROOM

| Sensor | ESP32-WROOM Pin | Game Target |
| :--- | :--- | :--- |
| **Left IR Sensor `OUT` (`A0`)** | **`GPIO 34`** | Target `A` (Left / Fire) |
| **Center IR Sensor `OUT` (`A0`)** | **`GPIO 35`** | Target `B` (Center / Ice) |
| **Right IR Sensor `OUT` (`A0`)** | **`GPIO 32`** | Target `C` (Right / Lightning) |
| **All Sensors `VCC` (`+`)** | **`3V3`** (or `VIN`/`5V` if safe, check sensor) | Power |
| **All Sensors `GND` (`-`)** | **`GND`** | Ground |

> **Important:** When you plug in the ESP32 (or press its `EN` / Reset button), keep your hands away from the sensors for **1 second** so it measures the club room's ambient lighting automatically!

---

## 3. Exact Ubuntu Linux Commands to Make It Work in the Club Room

### Step 1: Give Ubuntu Permission to Read the ESP32 USB Port
Plug the ESP32-WROOM into the Ubuntu PC via USB and run this command in the terminal (gives instant read/write access to `/dev/ttyUSB0`):

```bash
sudo chmod a+rw /dev/ttyUSB* /dev/ttyACM*
```

*(Optional permanent fix so you never have to run `chmod` again after unplugging)*:
```bash
sudo usermod -a -G dialout $USER
```

### Step 2: Check That the ESP32 Is Sending `"A"`, `"B"`, `"C"` (Optional Quick Check)
Before opening Arduino Serial Monitor or Godot, you can verify the sensor triggers right in your terminal:
*(Make sure Arduino IDE's Serial Monitor is **CLOSED** so it doesn't lock the port!)*

```bash
stty -F /dev/ttyUSB0 115200 raw -echo && cat /dev/ttyUSB0
```
Wave your hand over Left, Center, Right—you should see `A`, `B`, `C` appear in the terminal! Press **`Ctrl+C`** to stop `cat`.

### Step 3: Start the Game! (The Bridge Runs Automatically)
1. **Close the Arduino Serial Monitor** (only one program can use `/dev/ttyUSB0` at a time).
2. Run **Runeweave** (either press **F5** in Godot or launch your exported `./Runeweave.x86_64`).
3. **`main.gd` automatically starts the built-in Python USB-Serial $\rightarrow$ UDP bridge in the background**!
   - It automatically finds `/dev/ttyUSB0` (or `/dev/ttyUSB1`, `/dev/ttyACM0`) at `115200` baud.
   - Even if you unplug and re-plug the ESP32 while the game is open, it reconnects automatically within 0.5 seconds.
   - Your keyboard keys (`1`/`2`/`3` or `A`/`S`/`D`) still work at the exact same time.

---

## 4. Troubleshooting & Manual Commands

### Test Godot's Receiver Without the ESP32
With the game running and a round started, run this in any terminal to simulate waving your hand over Sensor A, B, C:
```bash
echo "A" > /dev/udp/127.0.0.1/4242
echo "B" > /dev/udp/127.0.0.1/4242
echo "C" > /dev/udp/127.0.0.1/4242
```

### What Messages Does the Game Accept on UDP Port `4242`?
- `"A"` or `"1"` or `"LEFT"` $\rightarrow$ Left Target (Fire / Left Lane)
- `"B"` or `"2"` or `"CENTER"` $\rightarrow$ Center Target (Ice / Center Lane)
- `"C"` or `"3"` or `"RIGHT"` $\rightarrow$ Right Target (Lightning / Right Lane)
- `"START"` or `"S"` $\rightarrow$ Starts the round from the Main Menu
- `"RESET"` or `"R"` $\rightarrow$ Aborts/resets the current round

### If You Want to Adjust Sensor Sensitivity in the Club Room
In the Arduino code at the top of this file, change line 15:
```cpp
const int TRIGGER_DELTA = 400;
```
- Make it **smaller** (e.g. `200` or `250`) if your hand has to get too close to trigger.
- Make it **larger** (e.g. `600` or `800`) if it triggers by itself from people walking by.
