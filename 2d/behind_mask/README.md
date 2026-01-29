# Behind the Mask

A puzzle-action game where the mask you wear changes how the world treats you. Fight through six levels with sword combat, defeat bosses, and level up to grow stronger.

**Global Game Jam 2026 - Theme: Mask**

![Behind the Mask](screenshots/behind_mask.png)

## Description

Navigate through rooms filled with patrolling enemies and laser barriers by switching between different masks. Each mask changes how enemies and the environment perceive and react to you. Use your sword to clear a path: defeat standard enemies, survive the **Level 3 boss**, and face the **Level 6 double boss** to win. Masks rotate automatically every 3 seconds—plan your movement and attacks accordingly.

## Controls

| Key               | Action         |
| ----------------- | -------------- |
| WASD / Arrow Keys | Move           |
| Space             | Attack (Sword) |
| R                 | Restart Level  |
| Escape            | Pause          |

**Note**: Masks automatically rotate every 3 seconds. Plan your movement accordingly!

## The Masks

| Mask         | Color  | Cooldown | Charges | Effect                                 |
| ------------ | ------ | -------- | ------- | -------------------------------------- |
| **Neutral**  | White  | 0.5s     | ∞       | Default state - enemies will chase you |
| **Guard**    | Blue   | 2.0s     | 5       | Enemies ignore you, lasers deactivate  |
| **Ghost**    | Gray   | 1.0s     | 4       | Pass through enemies, avoid cameras    |
| **Predator** | Red    | 2.5s     | 3       | Enemies flee from you in fear!         |
| **Decoy**    | Yellow | 1.5s     | 3       | Leave a decoy that distracts enemies   |

## Levels

- **Level 1–2**: Introduction to masks, lasers, and sword combat
- **Level 3**: Boss fight—defeat the boss to unlock the exit
- **Level 4–5**: Harder enemy mix and environmental hazards
- **Level 6**: Double boss—both must be defeated to exit

The camera follows the player; the level scrolls and clamps at edges.

## Gameplay

1. Start at one side of the room
2. Fight or avoid enemies with your sword; use masks to evade or scare them
3. Reach the green exit door (boss levels require defeating the boss first)
4. Navigate through laser barriers
5. Masks automatically rotate every 3 seconds—time your movement and attacks
6. If an enemy touches you (unless you're a Ghost), you take damage; zero health restarts the level
7. Watch the cooldown bar to see when the next mask will activate

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

- **Color tiers**: Red, Orange, Yellow, Green, Blue, Indigo, Violet—increasing health; later levels use tougher colors
- **Detector**: Sees through ALL masks except Ghost
- **Hunter**: Can detect Guard mask after 2 seconds of close proximity
- **Mimic**: Inverted behavior—chases when you're "safe"
- **Boss**: Large, high-health enemy; Level 3 has one boss, Level 6 has two (both must be defeated)

### Environmental Hazards

- **Static Lasers**: Guard mask deactivates them
- **Patrolling Lasers**: Moving laser beams, also deactivated by Guard
- **Security Cameras**: Sweeping cameras that fill your detection meter (Ghost avoids)
- **Pressure Plates**: Trigger mechanisms (Ghost can't activate - too ethereal)
- **One-Way Doors**: Commit to your path, no backtracking

### Resource Management

- **Automatic Rotation**: Masks change every 3 seconds automatically
- **Mask Charges**: Limited uses per mask (shown in HUD); depleted masks are dimmed and show "0"
- **Experience**: Defeat enemies and bosses to gain EXP and level up

### HUD Elements

- **Mask Icons**: All 5 masks with current highlighted; depleted (0 charges) icons are dimmed with a "0" overlay
- **Charge Counters**: Remaining uses for each mask
- **Cooldown Bar**: Time until next mask switch
- **EXP Bar & Level**: Current EXP progress and level (Lv.1–10)
- **Health Bar**: Player health
- **Score & Combo**: Kill score and combo counter
- **Boss Health Bar**: Shown when a boss is present; Level 6 shows two bars
- **Switch Counter**: Total mask switches

### Juice

- **Screen Shake**: Feedback on hits and death (Game, EffectManager)
- **Particles**: Hit sparks, explosions, death effects (ParticleManager)
- **Slow-mo**: Brief slow-motion on boss kill (EffectManager)
- **Mask Switch Animation**: Flash and scale pop
- **Procedural Audio**: All SFX and BGM generated in real-time (AudioManager)

## Level Up & Attributes

- **Experience**: Gain EXP by defeating enemies and bosses (EXP = that enemy’s max health). Fill the EXP bar to level up (levels 1–10).
- **Attribute points**: Each level-up grants one unspent point. Spend points in the **Pause menu** (when you have unspent points) on:
  - **+Power**: +2 sword damage per point (max +10)
  - **+Health**: +5 max HP per point (max +10)
  - **+Speed**: +10 movement speed per point (max +10)
- **Persistence**: ExperienceManager resets when starting a new game (loading level_01); progress is kept for the current run across level transitions.

## Project Structure

```
behind_mask/
├── autoload/
│   ├── Game.gd             # Game state, restart/load level, screen shake
│   ├── ExperienceManager.gd # Level, EXP, attribute points (power/health/speed)
│   ├── AudioManager.gd      # Procedural audio generation + playback
│   ├── ParticleManager.gd  # Hit sparks, explosions, death effects
│   ├── ScoreManager.gd      # Kill score, combo tracking
│   └── EffectManager.gd     # Slow-mo, screen shake, etc.
├── art/
│   └── PixelArtGenerator.gd # Pixel-art style helpers
├── enemy/
│   ├── Enemy.gd            # Base enemy AI (patrol/alert/chase/flee)
│   ├── Enemy.tscn          # Base enemy scene
│   ├── BossEnemy.gd        # Boss logic, health bar, must kill to exit
│   ├── BossEnemy.tscn      # Boss scene
│   ├── DetectorEnemy.gd    # Sees through all masks except Ghost
│   ├── HunterEnemy.gd      # Can detect Guard mask after 2s
│   ├── MimicEnemy.gd       # Inverted behavior
│   ├── *Enemy.gd / .tscn   # Color tiers: Orange, Yellow, Green, Blue, Indigo, Violet
│   └── EnemyBullet.gd      # Enemy projectile
├── interactables/
│   ├── ExitDoor.gd         # Level exit (checks bosses defeated on boss levels)
│   ├── LaserBarrier.gd     # Guard mask passes
│   ├── PatrollingLaser.gd  # Moving lasers
│   ├── SecurityCamera.gd   # Ghost avoids detection
│   ├── PressurePlate.gd    # Ghost can't trigger
│   └── OneWayDoor.gd       # One-way doors
├── level/
│   ├── level_01.tscn .. level_06.tscn  # Six levels (boss on 3, double boss on 6)
│   ├── LevelCamera.gd       # Player-centered scrolling, clamp at edges
│   ├── LevelManager.gd      # Level flow
│   ├── BackgroundGenerator.gd
│   ├── MaskLighting.gd      # Lighting per mask
│   └── ...
├── masks/
│   └── MaskManager.gd       # 5 masks, auto-rotation every 3s, charges
├── player/
│   ├── Player.gd           # Movement, mask visual, health, sword ref
│   ├── Player.tscn         # Player scene
│   ├── Sword.gd            # Sword attack, damage, knockback
│   └── Sword.tscn          # Sword scene
├── ui/
│   ├── HUD.gd              # Mask icons, cooldown, EXP bar, level, health, score, boss bars
│   ├── HUD.tscn            # HUD layout
│   ├── PauseOverlay.gd     # Pause menu, spend attribute points, debug code
│   ├── DamageNumber.gd     # Floating damage numbers
│   ├── win_screen.gd       # Victory screen
│   └── win_screen.tscn
├── main.gd                 # Title screen logic
├── main.tscn               # Title screen
└── project.godot           # Project configuration
```

## Design Philosophy

This game was designed for a game jam with these principles:

- **Simple mechanics**: Masks change automatically; one action (sword) to fight
- **Clear feedback**: Visual color changes, detection circles, alert indicators, damage numbers
- **Readable AI**: Enemies show their state clearly (patrolling, alert, chasing, fleeing)
- **Strategic depth**: 5 masks with different uses; rotation and charges matter
- **Environmental puzzles**: Laser barriers add another layer beyond enemies
- **Progression**: EXP and level-up with spendable attribute points (power, health, speed)
- **Juicy feel**: Screen shake, particles, slow-mo, mask switch animation
- **Jam pitch**: "A puzzle game where the mask you wear changes how the world treats you."

## Languages

GDScript

## Renderer

Compatibility (GL Compatibility)

## License

MIT License - See [LICENSE.md](../../LICENSE.md)
