# Behind the Mask – Improvement Suggestions

Analysis of the **2d/behind_mask** Godot project with concrete, reasonable improvements grouped by priority.

---

## High priority (bugs / correctness)

### 1. **LevelManager spawn bounds are wrong**

`LevelManager._find_spawn_position()` uses hardcoded bounds:

```gdscript
if pos.x < 50 or pos.x > 974 or pos.y < 50 or pos.y > 718:
```

Levels are 2048×768, so the right bound `974` is far too small. Spawned enemies can end up outside the visible/playable area or never spawn.

**Suggestion:** Use exported `level_width` / `level_height` (or read from the level’s Camera2D / a shared config) and clamp to e.g. `(50, level_width - 50)` and `(50, level_height - 50)`.

---

### 2. **HUD only shows one boss health bar (Level 6 has two bosses)**

`HUD._connect_to_player()` does:

```gdscript
var boss_node := get_tree().get_first_node_in_group("bosses")
```

So only the first boss in the "bosses" group is connected. On Level 6 there are two bosses; the second one’s health never updates the HUD.

**Suggestion:** Either:

- Connect to **all** nodes in `"bosses"` and show a single combined health bar (sum of current/max), or
- Show two bars (e.g. “Boss 1” / “Boss 2”), or
- Keep one bar but drive it from the “primary” or “nearest” boss and document that multi-boss levels only show one bar.

---

### 3. **Remove debug prints from ExitDoor**

`ExitDoor.gd` has several `print(...)` calls (e.g. "ExitDoor ready...", "body entered", "Player entered"). They clutter the console and can affect performance in release.

**Suggestion:** Remove them or wrap in `if OS.is_debug_build()` (or a custom debug flag).

---

## Medium priority (UX / polish)

### 4. **Pause menu**

There is no pause. If the player hits Escape or Alt+Tab, the game keeps running.

**Suggestion:** Add a pause action (e.g. Escape or a "pause" action) that:

- Pauses the tree (`get_tree().paused = true`) and
- Shows a simple overlay (CanvasLayer) with “Resume” and “Restart level” (and optionally “Quit to title”).

---

### 5. **Win screen options**

The win screen only reacts to the "action" key and returns to the title screen.

**Suggestion:** Add:

- “Play again” → `Game.load_level("res://level/level_01.tscn")`
- “Title” → `get_tree().change_scene_to_file("res://main.tscn")`

So the player can replay without going through the title screen.

---

### 6. **Main menu hint**

The title screen only starts the game on "action" (Space). New players may not know what to press.

**Suggestion:** Add a line like “Press SPACE to start” (and “R = Restart” if you want to mention it early).

---

### 7. **Mask timer / cooldown bar clarity**

The cooldown bar shows “time until next mask change” (3 seconds). When a mask has 0 charges, it still appears in the rotation and the bar keeps counting down. That’s consistent but can feel unclear.

**Suggestion:** When a mask is depleted (0 charges), dim or gray its icon and optionally show a small “0” or lock icon so it’s obvious that mask is exhausted until rotation gives it charges again (if you ever refill charges).

---

### 8. **Detection meter semantics**

In `MaskManager.add_detection()`, you set `is_being_detected = true` at the start and `is_being_detected = false` at the end of the same function. So after the call, the meter will decay even if the player is still in a camera’s view.

**Suggestion:** Have the **detector** (e.g. SecurityCamera, DetectorEnemy) call something like `add_detection(delta)` every frame while the player is in range, and call a new `set_being_detected(false)` when the player leaves. That way `is_being_detected` reflects “currently in a detection zone” and decay only happens when not detected.

---

## Lower priority (code quality / consistency)

### 9. **README and project structure**

The README still describes 3 levels and an older structure (e.g. no ScoreManager, ParticleManager, EffectManager, level_04–06, camera scrolling, sword, color enemies).

**Suggestion:** Update README to:

- List 6 levels and mention Level 3 boss, Level 6 double boss, and sword combat.
- Update the project structure tree to include autoloads (Game, AudioManager, ParticleManager, ScoreManager, EffectManager), Sword, HUD health/score/boss, and level_01–06.

---

### 10. **ScoreManager and enemy tiers**

`ScoreManager.add_kill_score(enemy_type)` uses `"normal"`, `"boss"`, `"detector"`, `"hunter"`, `"mimic"`. Color-tier enemies (Orange, Yellow, Green, etc.) are not distinguished and likely use a default.

**Suggestion:** Pass a tier or type from the enemy (e.g. "orange", "yellow", … or a generic "elite" for 3+ hit enemies) and give higher base score for harder tiers so score better reflects difficulty.

---

### 11. **Unused / dead code**

- `Game.camera` is set but never read; `shake_camera` finds the camera via `get_node_or_null("Camera2D")`. You can remove the `camera` member if nothing else uses it.
- `MaskManager.cycle_mask()` is empty (manual switch disabled). Either remove it and any callers or keep a single comment that manual switch is disabled.

---

### 12. **Project / editor config**

- `project.godot` has `[editor] movie_writer/movie_file="C:/Users/RAYRA/..."` – machine-specific and not needed for the demo.
- `config/description` and README still say “Global Game Jam 2026”; if the project is now a long-term demo, you might add “(originally GGJ 2026)” and a short line about current scope.

**Suggestion:** Remove or genericize the movie writer path; optionally shorten description and add “see README” for full credits.

---

### 13. **Dust particle throttle (Player)**

In `Player._animate_movement()`, dust is created with `if randf() < 0.1` per frame. At 60 FPS that’s up to ~6 dust particles per second per frame, which can add up.

**Suggestion:** Use a timer (e.g. “last dust at time T; only spawn if `Time.get_ticks_msec() - T > 80`”) to cap rate (e.g. ~12 per second) and avoid bursts.

---

### 14. **LevelManager not used in current levels**

Level scenes don’t seem to set `LevelManager.enemy_scene` or call `spawn_enemies()`. So the spawn logic exists but isn’t used. Either it’s for future use or for a different mode.

**Suggestion:** If you don’t plan to use it soon, consider removing it from level scenes and from the improvement list; if you do, fix spawn bounds (see item 1) and hook it into whatever triggers spawns (e.g. doors, events).

---

## Summary table

| Priority | Item                                  | Effort |
| -------- | ------------------------------------- | ------ |
| High     | LevelManager spawn bounds (2048×768)  | Small  |
| High     | HUD multi-boss (Level 6)              | Medium |
| High     | Remove ExitDoor debug prints          | Small  |
| Medium   | Pause menu                            | Medium |
| Medium   | Win screen: Play again + Title        | Small  |
| Medium   | Main menu “Press SPACE” hint          | Small  |
| Medium   | Mask charge feedback when depleted    | Small  |
| Medium   | Detection: who sets is_being_detected | Small  |
| Low      | README & project structure            | Small  |
| Low      | Score by enemy tier                   | Small  |
| Low      | Remove unused Game.camera, etc.       | Small  |
| Low      | Editor movie path, description        | Small  |
| Low      | Dust spawn throttle                   | Small  |
| Low      | LevelManager use or remove            | Design |

Implementing the high-priority items first will fix real bugs and clean up the build; the medium items improve clarity and control; the rest are nice-to-haves for maintainability and polish.
