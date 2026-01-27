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

| Mask | Color | Effect |
|------|-------|--------|
| **Neutral** | White | Default state - enemies will chase you |
| **Guard** | Blue | Enemies ignore you, lasers deactivate |
| **Ghost** | Gray (transparent) | Pass through enemies, but they still see you |
| **Predator** | Red | Enemies flee from you in fear! |
| **Decoy** | Yellow | When switching away, leaves a decoy that distracts enemies for 3 seconds |

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

- **Visual Detection Radius**: See the red circle showing each enemy's awareness zone
- **Alert Indicators**: Enemies show "!" when they spot you, "!!" when fleeing
- **Mask Icons HUD**: See all 5 masks with the current one highlighted
- **Cooldown Bar**: Visual indicator of when you can switch masks again
- **Screen Shake**: Feedback when you die
- **Laser Barriers**: Environmental hazards that only Guard mask can bypass
- **Procedural Audio**: All sound effects and music generated in real-time (no external files needed!)
  - Mask switch whoosh
  - Death sound
  - Victory fanfare
  - Enemy alert/flee sounds
  - Laser activation sounds
  - Ambient background music

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
