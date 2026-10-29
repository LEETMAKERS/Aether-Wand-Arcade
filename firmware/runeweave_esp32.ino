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
