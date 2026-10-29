# Firmware

This is the code that runs on the ESP32 — the small computer inside the wand controller.

## What it does

The ESP32 reads three infrared sensors. When you wave the wand over a sensor, the sensor's reading changes. The ESP32 notices this and sends a message to the game:

- `A` when the left sensor is triggered
- `B` when the center sensor is triggered
- `C` when the right sensor is triggered

It also sends the sensor's raw number (so the game can log it), but the game only uses the letter.

## How the message reaches the game

The ESP32 talks to the computer over a USB cable. A small helper program — started automatically by the game — listens for these messages and passes them to the Godot game. The game then shows your spell.

You don't have to start anything yourself. Just plug in the ESP32 and run the game.

## The code

`runeweave_esp32.ino` is the file you open in the **Arduino IDE** and upload to the ESP32.

You don't need to change anything in it for the game to work. But if a sensor triggers too easily (going off when nobody's near it) or not enough (you have to get really close), you can adjust the numbers at the top of the file. Each sensor has its own settings.
