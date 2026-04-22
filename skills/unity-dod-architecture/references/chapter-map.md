# Chapter Map

Quick reference: which concept is covered in which chapter of *Data-Oriented Design for Games* by Nitzan Wilnai.

| Chapter | Title | Key Concepts |
|---------|-------|-------------|
| 1 | Understanding data-oriented design | Cache hits/misses, cache lines (64 bytes), data locality, DOD vs OOP, parallel arrays vs array of objects, MoveAllEnemies() example |
| 2 | Structuring data for performance | struct vs class, value types vs reference types, when to use arrays, data ordering for cache alignment |
| 3 | Memory allocations and performance | Stack vs heap, GC issues (unpredictability, performance, fragmentation), object pools, AllocateEnemies / DeallocateEnemies, GC.Collect() at loading screens |
| 4 | Data and logic | **Core architecture**: Balance, GameData, Logic, Board, Game. Static logic functions. Data-in/transformation/data-out. Chess analogy. Balance vs GameData distinction. AllocateGameData, StartGame, Tick pattern |
| 5 | Game board and game loop | Board implementation (Init, Show, Hide, Tick, handleInput). Game singleton. Driving Board from Game.Update(). MENU_STATE enum. Not using early returns |
| 6 | Common data structures: List, Stack, Queue | DOD List (array + count + shift-left). DOD Stack (array + count, prefix -- for pop). DOD Queue. AliveEnemyIndices + DeadEnemyIndices pattern. Why not to create DODList helper class |
| 7 | Separating data and logic | GameDataIO (binary save/load, versioning, backwards compatibility). MetaData. AssetManager singleton. GUIRef pattern. Asset loading options (editor assignment vs Resources vs Addressables) |
| 8 | Separating asset data and logic | Menu Visual classes (MainMenuVisual, GameOverVisual). GUIRef usage. Adding listeners in Init() not Show(). CommonVisual static helper. InGame boolean in GameData |
| 9 | Tooltime data parsing | ScriptableObject (BalanceSO). Editor MenuItem for parse + validate. Binary balance file. Validate before parse. Single source of balance truth. Version tracking |
| 10 | Branching, performance, and code complexity | Minimizing if statements. Why branches hurt performance (compiler can't optimize away runtime variables). Moving branches to tool time. Data-driven branching |
| 11 | Skipping runtime checks with pre-validation | Pre-validating data at tool time. Trusting balance data. Removing defensive checks. Enum-based state machines |
| 12 | Debugging and problem solving using DOD | All data in one place makes debugging easier. Binary save format helps identify variable mismatch. Breakpoints on GameData variables |
| 13 | The Entity Component System and DOD | How ECS relates to DOD (ECS is one implementation of DOD principles). Unity DOTS. When ECS makes sense |
| Appendix A | DOD in action | Real-world case studies (Plarium's Nova Legends, Mergeup: Makeover) |
| Appendix B | DOD vs OOP architecture performance example | Quantitative benchmark comparing DOD and OOP approaches |

## Concept Quick-Lookup

| Concept | Chapter |
|---------|---------|
| Cache lines and cache hits/misses | 1 |
| Data locality | 1 |
| Parallel arrays | 1, 2 |
| struct vs class | 2 |
| Object pools | 3 |
| GC best practices | 3 |
| Balance class | 4 |
| GameData class | 4 |
| Logic static class | 4 |
| Board MonoBehaviour | 4, 5 |
| Game singleton | 4, 5 |
| AllocateGameData | 4, 6 |
| StartGame | 4, 6 |
| Tick pattern | 4, 5 |
| AliveEnemyIndices + DeadEnemyIndices | 6 |
| DOD List/Stack/Queue | 6 |
| Binary save/load | 7 |
| Versioned save files | 7 |
| MetaData | 7 |
| AssetManager singleton | 7 |
| GUIRef | 7, 8 |
| Menu Visual classes | 8 |
| CommonVisual | 8 |
| ScriptableObject balance | 9 |
| Tool-time validation | 9, 11 |
| Binary balance parsing | 9 |
| Branching and performance | 10 |
| ECS and DOD | 13 |
