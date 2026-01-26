# Behind the Mask

A puzzle game where the mask you wear changes how the world treats you.

**Global Game Jam 2026 - Theme: Mask**

![Behind the Mask](screenshots/behind_mask.png)

## Description

Navigate through rooms filled with patrolling guards by switching between different masks. Each mask changes how enemies perceive and react to you, creating a unique puzzle experience where the solution lies in choosing the right disguise at the right time.

## Controls

| Key | Action |
|-----|--------|
| WASD / Arrow Keys | Move |
| Space | Change Mask |
| R | Restart Level |

## The Masks

| Mask | Color | Effect |
|------|-------|--------|
| **Neutral** | White | Default state - enemies will chase you |
| **Guard** | Blue | Enemies ignore you completely |
| **Ghost** | Gray (transparent) | You can pass through enemies, but they still see you |

## Gameplay

1. Start at one side of the room
2. Reach the green exit door on the other side
3. Avoid or bypass the red patrolling enemies
4. Switch masks strategically to overcome obstacles
5. If an enemy touches you (unless you're a Ghost), you restart the level

## Tips

- **Guard Mask**: Use when you need to walk past enemies safely
- **Ghost Mask**: Use when enemies are blocking a narrow path - you can walk right through them
- **Neutral Mask**: Enemies chase you - sometimes useful to lure them away

## Project Structure

```
behind_mask/
├── autoload/
│   └── Game.gd          # Game state management
├── enemy/
│   ├── Enemy.gd         # Enemy patrol and chase behavior
│   └── Enemy.tscn       # Enemy scene
├── interactables/
│   ├── ExitDoor.gd      # Level exit logic
│   └── ExitDoor.tscn    # Door scene
├── level/
│   ├── level_01.tscn    # Tutorial level
│   ├── level_02.tscn    # Two guards
│   └── level_03.tscn    # Final challenge
├── masks/
│   └── MaskManager.gd   # Mask switching logic
├── player/
│   ├── Player.gd        # Player movement and input
│   └── Player.tscn      # Player scene
├── ui/
│   ├── HUD.gd           # Heads-up display logic
│   ├── HUD.tscn         # HUD scene
│   ├── win_screen.gd    # Victory screen logic
│   └── win_screen.tscn  # Victory screen
├── main.gd              # Title screen logic
├── main.tscn            # Title screen
└── project.godot        # Project configuration
```

## Design Philosophy

This game was designed for a game jam with these principles:

- **Simple mechanics**: One button changes everything
- **Clear feedback**: Visual color changes show current mask
- **No complex AI**: Enemies patrol or chase - that's it
- **Small scope**: 3 levels, 3 masks, screen-sized rooms
- **Jam pitch**: "A puzzle game where the mask you wear changes how the world treats you."

## Languages

GDScript

## Renderer

Compatibility (GL Compatibility)

## License

MIT License - See [LICENSE.md](../../LICENSE.md)
