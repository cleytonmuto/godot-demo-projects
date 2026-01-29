# Behind the Mask – Improvement Suggestions

Analysis of the **2d/behind_mask** Godot project with concrete, reasonable improvements grouped by priority.

**Status legend:** ✅ Done | ⏳ Not done | ➖ Obsolete/superseded

---

## High priority (bugs / correctness)

### 1. **LevelManager spawn bounds are wrong** ✅ Done

`LevelManager._find_spawn_position()` uses hardcoded bounds:

```gdscript
if pos.x < 50 or pos.x > 974 or pos.y < 50 or pos.y > 718:
```

Levels are 2048×768, so the right bound `974` is far too small. Spawned enemies can end up outside the visible/playable area or never spawn.

**Suggestion:** Use exported `level_width` / `level_height` (or read from the level's Camera2D / a shared config) and clamp to e.g. `(50, level_width - 50)` and `(50, level_height - 50)`.

**Status:** Done. LevelManager uses `@export var level_width := 2048.0` / `level_height := 768.0` and sets `_spawn_max_x/y` from them (or from Camera2D); spawn bounds are correct.

---

### 2. **HUD only shows one boss health bar (Level 6 has two bosses)** ✅ Done

`HUD._connect_to_player()` does:

```gdscript
var boss_node := get_tree().get_first_node_in_group("bosses")
```

So only the first boss in the "bosses" group is connected. On Level 6 there are two bosses; the second one's health never updates the HUD.

**Suggestion:** Either:

- Connect to **all** nodes in `"bosses"` and show a single combined health bar (sum of current/max), or
- Show two bars (e.g. "Boss 1" / "Boss 2"), or
- Keep one bar but drive it from the "primary" or "nearest" boss and document that multi-boss levels only show one bar.

**Status:** Done. HUD connects to all nodes in `"bosses"` and creates a health row (label + bar) per boss; Level 6 shows two boss bars.

---

### 3. **Remove debug prints from ExitDoor** ✅ Done

`ExitDoor.gd` has several `print(...)` calls (e.g. "ExitDoor ready...", "body entered", "Player entered"). They clutter the console and can affect performance in release.

**Suggestion:** Remove them or wrap in `if OS.is_debug_build()` (or a custom debug flag).

**Status:** Done. No `print()` calls remain in ExitDoor.gd.

---

## Medium priority (UX / polish)

### 4. **Pause menu** ✅ Done

There is no pause. If the player hits Escape or Alt+Tab, the game keeps running.

**Suggestion:** Add a pause action (e.g. Escape or a "pause" action) that:

- Pauses the tree (`get_tree().paused = true`) and
- Shows a simple overlay (CanvasLayer) with "Resume" and "Restart level" (and optionally "Quit to title").

**Status:** Done. Pause on Escape; overlay with Resume, Restart Level, Quit to Title, Debug Code, and spend-attribute-points section when unspent points > 0.

---

### 5. **Win screen options** ⏳ Not done

The win screen only reacts to the "action" key and returns to the title screen.

**Suggestion:** Add:

- "Play again" → `Game.load_level("res://level/level_01.tscn")`
- "Title" → `get_tree().change_scene_to_file("res://main.tscn")`

So the player can replay without going through the title screen.

**Status:** Not done. Win screen still uses a single action (SPACE) that goes to title. The UI text says "Press SPACE to play again" but the code goes to main.tscn (title).

---

### 6. **Main menu hint** ✅ Done

The title screen only starts the game on "action" (Space). New players may not know what to press.

**Suggestion:** Add a line like "Press SPACE to start" (and "R = Restart" if you want to mention it early).

**Status:** Done. Main menu has "Press SPACE to start" (StartHint) and controls line (WASD, masks, R to restart).

---

### 7. **Mask timer / cooldown bar clarity** ✅ Done

The cooldown bar shows "time until next mask change" (3 seconds). When a mask has 0 charges, it still appears in the rotation and the bar keeps counting down. That's consistent but can feel unclear.

**Suggestion:** When a mask is depleted (0 charges), dim or gray its icon and optionally show a small "0" or lock icon so it's obvious that mask is exhausted until rotation gives it charges again (if you ever refill charges).

**Status:** Done. Depleted masks: icon dimmed (gray modulate), small "0" overlay on icon, charge label in red; appearance updates when charges change.

---

### 8. **Detection meter semantics** ➖ Obsolete / superseded

In `MaskManager.add_detection()`, you set `is_being_detected = true` at the start and `is_being_detected = false` at the end of the same function. So after the call, the meter will decay even if the player is still in a camera's view.

**Suggestion:** Have the **detector** (e.g. SecurityCamera, DetectorEnemy) call something like `add_detection(delta)` every frame while the player is in range, and call a new `set_being_detected(false)` when the player leaves. That way `is_being_detected` reflects "currently in a detection zone" and decay only happens when not detected.

**Status:** Superseded. The detection bar was removed from the HUD and replaced by the EXP bar. Detection logic may still exist in MaskManager; if cameras/detection are reused later, the semantics suggestion still applies.

---

## Lower priority (code quality / consistency)

### 9. **README and project structure** ✅ Done

The README still describes 3 levels and an older structure (e.g. no ScoreManager, ParticleManager, EffectManager, level_04–06, camera scrolling, sword, color enemies).

**Suggestion:** Update README to:

- List 6 levels and mention Level 3 boss, Level 6 double boss, and sword combat.
- Update the project structure tree to include autoloads (Game, AudioManager, ParticleManager, ScoreManager, EffectManager), Sword, HUD health/score/boss, and level_01–06.

**Status:** Done. README updated with 6 levels, bosses, sword, structure tree (autoloads, Sword, level_01–06, etc.), and Level Up & Attributes section.

---

### 10. **ScoreManager and enemy tiers** ⏳ Not done

`ScoreManager.add_kill_score(enemy_type)` uses `"normal"`, `"boss"`, `"detector"`, `"hunter"`, `"mimic"`. Color-tier enemies (Orange, Yellow, Green, etc.) are not distinguished and likely use a default.

**Suggestion:** Pass a tier or type from the enemy (e.g. "orange", "yellow", … or a generic "elite" for 3+ hit enemies) and give higher base score for harder tiers so score better reflects difficulty.

**Status:** Not done. Base Enemy still passes `"normal"` for color tiers; only Detector/Hunter/Mimic/Boss pass specific types.

---

### 11. **Unused / dead code** ✅ Done

- `Game.camera` is set but never read; `shake_camera` finds the camera via `get_node_or_null("Camera2D")`. You can remove the `camera` member if nothing else uses it.
- `MaskManager.cycle_mask()` is empty (manual switch disabled). Either remove it and any callers or keep a single comment that manual switch is disabled.

**Status:** Done. `Game.camera` removed; `MaskManager.cycle_mask()` removed (no callers).

---

### 12. **Project / editor config** ⏳ Not done

- `project.godot` has `[editor] movie_writer/movie_file="C:/Users/RAYRA/..."` – machine-specific and not needed for the demo.
- `config/description` and README still say "Global Game Jam 2026"; if the project is now a long-term demo, you might add "(originally GGJ 2026)" and a short line about current scope.

**Suggestion:** Remove or genericize the movie writer path; optionally shorten description and add "see README" for full credits.

**Status:** Not done.

---

### 13. **Dust particle throttle (Player)** ✅ Done

In `Player._animate_movement()`, dust is created with `if randf() < 0.1` per frame. At 60 FPS that's up to ~6 dust particles per second per frame, which can add up.

**Suggestion:** Use a timer (e.g. "last dust at time T; only spawn if `Time.get_ticks_msec() - T > 80`") to cap rate (e.g. ~12 per second) and avoid bursts.

**Status:** Done. Player uses `_last_dust_msec` and only spawns dust when `Time.get_ticks_msec() - _last_dust_msec > 80` (~12/s cap).

---

### 14. **LevelManager not used in current levels** ✅ Done (in use)

Level scenes don't seem to set `LevelManager.enemy_scene` or call `spawn_enemies()`. So the spawn logic exists but isn't used. Either it's for future use or for a different mode.

**Suggestion:** If you don't plan to use it soon, consider removing it from level scenes and from the improvement list; if you do, fix spawn bounds (see item 1) and hook it into whatever triggers spawns (e.g. doors, events).

**Status:** Done. LevelManager is used: enemies call `spawn_enemies(position, 2)` on death; each level sets `spawn_enemy_scene` to the strongest enemy for that stage. Spawn bounds fixed (item 1).

---

## Summary table

| Priority | Item                                  | Effort | Status        |
| -------- | ------------------------------------- | ------ | ------------- |
| High     | LevelManager spawn bounds (2048×768)  | Small  | ✅ Done       |
| High     | HUD multi-boss (Level 6)              | Medium | ✅ Done       |
| High     | Remove ExitDoor debug prints          | Small  | ✅ Done       |
| Medium   | Pause menu                            | Medium | ✅ Done       |
| Medium   | Win screen: Play again + Title        | Small  | ⏳ Not done   |
| Medium   | Main menu "Press SPACE" hint          | Small  | ✅ Done       |
| Medium   | Mask charge feedback when depleted    | Small  | ✅ Done       |
| Medium   | Detection: who sets is_being_detected | Small  | ➖ Superseded |
| Low      | README & project structure            | Small  | ✅ Done       |
| Low      | Score by enemy tier                   | Small  | ⏳ Not done   |
| Low      | Remove unused Game.camera, etc.       | Small  | ✅ Done       |
| Low      | Editor movie path, description        | Small  | ⏳ Not done   |
| Low      | Dust spawn throttle                   | Small  | ✅ Done       |
| Low      | LevelManager use or remove            | Design | ✅ Done       |

Implementing the remaining items (win screen options, score by tier, editor config) will complete the list; the rest are done or superseded.
