class_name GameTypes
## Shared typed vocabulary for Runeweave.
##
## No logic and no state. These enums let the input, rules, and HUD layers
## speak the same language without stringly-typed glue. L/C/R map to A/B/C.

enum Target { LEFT, CENTER, RIGHT }
enum Element { A, B, C } # Fire, Frost, Lightning.
enum Lane { LEFT, CENTER, RIGHT }
enum CastStyle { STABLE, WILD }
