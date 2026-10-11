# Robotics Combat Prototype

## Architecture Overview
This prototype was built **programmatically** to establish a clean, text-based foundation. Instead of using Godot's visual editor to place nodes, `scripts/main.gd` builds the entire scene tree in code when the game starts. 

If you look in the Godot editor, you only see an empty `Node2D`. But when you press Play, `main.gd` creates:
- **Arena**: Draws the lanes and shapes.
- **HUD**: Draws the health bars and text.
- **Player / Enemy**: Invisible data nodes tracking health.
- **InputHandler**: Listens for keyboard events.
- **CombatManager**: The "brain" that connects everything together.

### Is this the "proper" way to use Godot?
**For a prototype, yes. For a full game, no.** 
LLMs are very good at writing pure code, but Godot is designed around visual Scene files (`.tscn`). As we move forward, the best practice is to transition this procedural code into proper Godot scenes. For example, instead of `arena.gd` drawing shapes with code, you would place `Sprite2D` nodes in the editor. We can migrate to that standard workflow once the core rules are finalized.

## How to Edit and Tune
Because you know Python, GDScript will feel very familiar. 
- **Want to change game balance?** Open `scripts/combat_config.gd`. All health, damage, speed, and timing numbers live here.
- **Want to see how attacks resolve?** Look at `_check_collisions()` in `scripts/combat_manager.gd`.
- **Want to change visuals?** Look at `_draw()` in `scripts/arena.gd`.

## Next Steps: Combat Design
We are currently brainstorming the combat loop to prevent mindless button mashing and introduce real challenge based on timing and decision-making.
