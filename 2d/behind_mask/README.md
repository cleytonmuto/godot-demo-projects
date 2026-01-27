# Behind the Mask

A puzzle game where the mask you wear changes how the world treats you.

**Global Game Jam 2026 - Theme: Mask**

![Behind the Mask](screenshots/behind_mask.png)

## Description

Navigate through rooms filled with patrolling guards and laser barriers by switching between different masks. Each mask changes how enemies and the environment perceive and react to you, creating a unique puzzle experience where the solution lies in choosing the right disguise at the right time.

## Controls

| Key | Action |
|-----|--------|
| WASD / Arrow Keys | Move |
| Space | Change Mask (1 second cooldown) |
| R | Restart Level |

## The Masks

| Mask | Color | Cooldown | Charges | Effect |
|------|-------|----------|---------|--------|
| **Neutral** | White | 0.5s | ∞ | Default state - enemies will chase you |
| **Guard** | Blue | 2.0s | 5 | Enemies ignore you, lasers deactivate |
| **Ghost** | Gray | 1.0s | 4 | Pass through enemies, avoid cameras |
| **Predator** | Red | 2.5s | 3 | Enemies flee from you in fear! |
| **Decoy** | Yellow | 1.5s | 3 | Leave a decoy that distracts enemies |

## Gameplay

1. Start at one side of the room
2. Reach the green exit door on the other side
3. Avoid or bypass the red patrolling enemies
4. Navigate through laser barriers
5. Switch masks strategically to overcome obstacles
6. If an enemy touches you (unless you're a Ghost), you restart the level
7. Mask switching has a 1-second cooldown - plan ahead!

## Tips

- **Guard Mask**: Walk past enemies safely AND deactivate laser barriers
- **Ghost Mask**: Phase through enemies blocking narrow paths
- **Predator Mask**: Clear a path by scaring enemies away
- **Decoy Mask**: Lure enemies to a location - switch away to leave a decoy they'll chase
- **Neutral Mask**: Enemies chase you - useful to lead them into a trap

## Features

### Enemy AI
- **Visual Detection Radius**: See the colored circle showing each enemy's awareness zone
- **Alert Indicators**: "!" when spotted, "?" when investigating, "!!" when fleeing
- **Memory System**: Enemies remember your last position and investigate
- **Patrol Patterns**: Horizontal, vertical, circular, or random patrol routes
- **Communication**: Enemies alert nearby allies when they spot you

### Enemy Types
- **Standard (Red)**: Normal patrol and chase behavior
- **Detector (Purple)**: Sees through ALL masks except Ghost
- **Hunter (Green)**: Can detect Guard mask after 2 seconds of close proximity
- **Mimic (Color-shifting)**: Inverted behavior - chases when you're "safe"

### Environmental Hazards
- **Static Lasers**: Guard mask deactivates them
- **Patrolling Lasers**: Moving laser beams, also deactivated by Guard
- **Security Cameras**: Sweeping cameras that fill your detection meter (Ghost avoids)
- **Pressure Plates**: Trigger mechanisms (Ghost can't activate - too ethereal)
- **One-Way Doors**: Commit to your path, no backtracking

### Resource Management
- **Mask Charges**: Limited uses per mask (shown in HUD)
- **Per-Mask Cooldowns**: Each mask has different cooldown timing
- **Detection Meter**: Cameras and prolonged exposure fill the meter - full = forced alert!

### HUD Elements
- **Mask Icons**: All 5 masks with current highlighted
- **Charge Counters**: Remaining uses for each mask
- **Cooldown Bar**: Time until next switch
- **Detection Meter**: Current alert level
- **Switch Counter**: Track your efficiency

### Juice
- **Screen Shake**: Feedback on death
- **Mask Switch Animation**: Flash and scale pop
- **Procedural Audio**: All SFX and BGM generated in real-time

## Project Structure

```
behind_mask/
├── autoload/
│   ├── Game.gd            # Game state management + screen shake
│   └── AudioManager.gd    # Procedural audio generation + playback
├── enemy/
│   ├── Enemy.gd           # Enemy AI with patrol/alert/chase/flee states
│   └── Enemy.tscn         # Enemy scene with detection visuals
├── interactables/
│   ├── ExitDoor.gd        # Level exit logic
│   ├── ExitDoor.tscn      # Door scene
│   ├── LaserBarrier.gd    # Laser hazard logic
│   └── LaserBarrier.tscn  # Laser barrier scene
├── level/
│   ├── level_01.tscn      # Tutorial level
│   ├── level_02.tscn      # Lasers + Predator introduction
│   └── level_03.tscn      # Final challenge with Decoy
├── masks/
│   └── MaskManager.gd     # 5 masks with cooldown system
├── player/
│   ├── Player.gd          # Movement + mask switch animation
│   └── Player.tscn        # Player scene
├── ui/
│   ├── HUD.gd             # Visual mask icons + cooldown bar
│   ├── HUD.tscn           # HUD scene
│   ├── win_screen.gd      # Victory screen logic
│   └── win_screen.tscn    # Victory screen
├── main.gd                # Title screen logic
├── main.tscn              # Title screen
└── project.godot          # Project configuration
```

## Design Philosophy

This game was designed for a game jam with these principles:

- **Simple mechanics**: One button changes everything
- **Clear feedback**: Visual color changes, detection circles, alert indicators
- **Readable AI**: Enemies show their state clearly (patrolling, alert, chasing, fleeing)
- **Strategic depth**: 5 masks with different uses, cooldown prevents spam
- **Environmental puzzles**: Laser barriers add another layer beyond enemies
- **Juicy feel**: Screen shake, mask switch animation, visual feedback everywhere
- **Jam pitch**: "A puzzle game where the mask you wear changes how the world treats you."

## Languages

GDScript

## Renderer

Compatibility (GL Compatibility)

## License

MIT License - See [LICENSE.md](../../LICENSE.md)
