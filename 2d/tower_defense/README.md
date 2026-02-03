# Tower Defense

A 2D tower defense game with a **Map Editor**. Design your map (canyon for towers, valley for the enemy path, spawn and goal), save it, then play using that map.

## Main menu

- **Map Editor** — Create or edit the game map.
- **Play** — Run the game using the last saved map (or a message if no map is saved).

## Map Editor

The map is a **rectangular checkered board** with two cell types:

- **Canyon (brown)** — Cells where the player can place towers (with shooting range).
- **Valley (dark blue)** — Cells where enemies walk. Enemies must follow a valley path from spawn to goal.

You must also set:

- **Spawn** — The cell where enemies appear (one per map). Shown with a green tint and "S".
- **Goal** — The cell enemies must reach. When an enemy reaches this cell, the player loses a life. Shown with a red tint and "G".

### Tools

1. **Canyon (towers)** — Click a cell to make it canyon (tower placement allowed).
2. **Valley (path)** — Click a cell to make it valley (enemy path).
3. **Set Spawn** — Click a cell to set it as the spawn. That cell becomes valley if it wasn’t.
4. **Set Goal** — Click a cell to set it as the goal. That cell becomes valley if it wasn’t.

### Buttons

- **New Map** — Creates a new 12×8 map with a default L-shaped valley path (top row + right column), spawn at top-left, goal at bottom-right.
- **Load** — Loads the map from disk (`user://tower_defense_map.json`). Use this to continue editing a previously saved map.
- **Save** — Saves the current map to disk. Required before Play can use it.
- **Save & Play** — Saves the map and switches to the game scene.
- **Back to Menu** — Returns to the main menu without saving.

### Persistence

The map is saved as JSON to **user://tower_defense_map.json** (e.g. on Linux: `~/.local/share/godot/app_userdata/Tower Defense/tower_defense_map.json`). The same file is used for editing again (Load) and for the main game (Play).

## Game (Play)

When you run **Play**, the game loads the saved map. If no map exists, it shows a message and a “Back to Menu” button. Full gameplay (pathfinding from spawn to goal, tower placement on canyon, waves) will use this map in a later update.

## Project structure

- **main.tscn** / **main.gd** — Main menu (Map Editor, Play).
- **map_editor.tscn** / **map_editor.gd** — Map Editor UI and tools.
- **grid_display.gd** — Draws the grid (canyon/valley, spawn/goal markers).
- **map_data.gd** — Map data (grid, spawn, goal) and save/load to JSON.
- **game.tscn** / **game.gd** — Game scene; loads saved map (gameplay to be expanded).

## Customization

- **map_data.gd**: `MapData.SAVE_PATH`, default grid size in `new_map()`, `CellType` enum.
- **map_editor.gd**: `CELL_SIZE`, tool behavior.
- **grid_display.gd**: Colors for canyon, valley, spawn tint, goal tint, grid lines.
