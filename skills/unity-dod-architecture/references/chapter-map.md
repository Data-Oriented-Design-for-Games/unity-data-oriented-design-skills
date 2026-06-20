# Chapter Map

Quick reference: which concept is covered in which chapter of *High Performance Unity Game Development* (subtitle: *Using data-oriented design*) by Nitzan Wilnai (Manning, MEAP v12).

The book is organized into three parts.

## Part 1 — Performance

| Chapter | Title | Key Concepts |
|---------|-------|-------------|
| 1 | Understanding data-oriented design | Cache hits/misses, cache lines (64 bytes), data locality, DOD vs OOP, parallel arrays vs array of objects, MoveAllEnemies() example, survival-game running example, how DOD relates to SIMD/Jobs/Burst/ECS |
| 2 | Structuring data for performance | struct vs class, value types vs reference types, when to use arrays, data ordering for cache alignment |
| 3 | Memory allocations and performance | Stack vs heap, GC issues (unpredictability, performance, fragmentation), object pools, AllocateEnemies / DeallocateEnemies, GC.Collect() at loading screens |
| 4 | Data and logic | **Core architecture**: Balance, GameData, Logic, Board, Game. Static logic functions. Data-in/transformation/data-out. Chess analogy. Balance vs GameData distinction. AllocateGameData, StartGame, Tick pattern |
| 5 | Game board and game loop | Board implementation (Init, Show, Hide, Tick, handleInput). Game singleton. Driving Board from Game.Update(). MENU_STATE enum. Not using early returns |

## Part 2 — Reducing Code Complexity

| Chapter | Title | Key Concepts |
|---------|-------|-------------|
| 6 | Common data structures: List, Stack, and Queue | DOD List (array + count + shift-left). DOD Stack (array + count, prefix -- for pop). DOD Queue. AliveEnemyIndices + DeadEnemyIndices pattern. Why not to create a DODList helper class |
| 7 | Separating data and logic | GameDataIO (binary save/load, versioning, backwards compatibility). MetaData. AssetManager singleton. GUIRef pattern. Asset loading options (editor assignment vs Resources vs Addressables) |
| 8 | Separating asset data and logic | Menu Visual classes (MainMenuVisual, GameOverVisual). GUIRef usage. Adding listeners in Init() not Show(). CommonVisual static helper. InGame boolean in GameData |
| 9 | Tooltime data parsing | ScriptableObject (BalanceSO). Editor MenuItem for parse + validate. Binary balance file. Validate before parse. Single source of balance truth. Version tracking. Pre-validating so runtime needs no defensive checks |
| 10 | DOD and Dictionaries | **Why to avoid dictionaries at runtime** (~10x slower than array lookup; hashing, collisions, chaining, cache-unfriendly). Assigning indices/IDs at tool time so arrays replace dictionaries. Supporting multiple enemy types (EnemySO, array of enemy prefabs in AssetManager, lookup by name). Dynamic object pools: set a max size, preallocate, only ADD at runtime (removing fragments memory + triggers GC). Backwards compatibility: write unique IDs into the save, use a dictionary ONLY at load time (never at runtime) to map saved indices back to objects |
| 11 | Branching, performance, and extendibility | Branch prediction + misprediction (pipeline flushes), why even predictable branches cost in tight loops, branchless alternatives. Avoiding early return. Unity null checks are expensive (C#/C++ interop): check once at load, zero-tolerance error handling, own the data's lifetime, avoid fire-and-forget/coroutines. Separating data (alive vs dead enemies) to remove per-item status checks. Separating common UI to reduce branches. Default parameter values can hide branches |

## Part 3 — Solving for Data

| Chapter | Title | Key Concepts |
|---------|-------|-------------|
| 12 | Unity DOTS | DOTS as an *incremental* optimization layered on top of existing DOD. SIMD vectorization with the **Burst** compiler (NativeArray, DOTS-compatible types like float2). Parallelizing array work with the **Jobs** system (multi-core, scheduling overhead hurts on small data). **ECS** and code complexity (Entity = index into arrays, Component = arrays of data, System = logic; ECS is one implementation of DOD, increases complexity, not always needed). **TransformAccessArray** for parallel GameObject transform updates without full ECS (only when transform updates are the bottleneck) |

## Appendices

| Appendix | Title | Key Concepts |
|---------|-------|-------------|
| A | Data-Oriented Design in action | Real-world performance example: moving enemies with vs without data locality; quantifying the cache-locality speedup |
| B | DOD vs OOP architecture performance example | Quantitative benchmark comparing DOD and OOP approaches |

## Concept Quick-Lookup

| Concept | Chapter |
|---------|---------|
| Cache lines and cache hits/misses | 1 |
| Data locality | 1 |
| Parallel arrays | 1, 2 |
| struct vs class | 2 |
| Object pools | 3, 10 |
| GC best practices | 3 |
| Balance class | 4 |
| GameData class | 4 |
| Logic static class | 4 |
| Board MonoBehaviour | 4, 5 |
| Game singleton | 4, 5 |
| AllocateGameData | 4, 6 |
| StartGame | 4, 6 |
| Tick pattern | 4, 5 |
| AliveEnemyIndices + DeadEnemyIndices | 6, 11 |
| DOD List/Stack/Queue | 6 |
| Binary save/load | 7 |
| Versioned save files | 7, 10 |
| MetaData | 7 |
| AssetManager singleton | 7, 10 |
| GUIRef | 7, 8 |
| Menu Visual classes | 8 |
| CommonVisual | 8 |
| ScriptableObject balance | 9 |
| Tool-time validation | 9, 11 |
| Binary balance parsing | 9 |
| Avoiding dictionaries at runtime | 10 |
| Indices/IDs assigned at tool time | 10 |
| Multiple enemy types (EnemySO) | 10 |
| Dynamic object pools (preallocate max, add-only) | 10 |
| Backwards compatibility via load-time dictionary | 10 |
| Branch prediction / branchless code | 11 |
| Unity null-check cost / own-the-lifetime | 11 |
| Separating data to remove branch checks | 11 |
| Unity DOTS (Burst / Jobs / ECS) | 12 |
| SIMD vectorization | 12 |
| TransformAccessArray | 12 |
| ECS and DOD | 12 |

## Changes from earlier MEAP editions

- The book was retitled from *Data-Oriented Design for Games* to *High Performance Unity Game Development* (subtitle *Using data-oriented design*) and reorganized into three parts.
- **Chapter 10 "DOD and Dictionaries" is new.**
- Old "Branching, performance, and code complexity" is now Chapter 11, "Branching, performance, and extendibility," and is expanded with branch prediction, Unity null-check cost, and data-separation techniques.
- The old "Skipping runtime checks with pre-validation" chapter's ideas now live in Chapter 9 (tool-time validation) and Chapter 11 (own-the-lifetime, zero tolerance).
- The old standalone "Debugging and problem solving using DOD" chapter is not present in this MEAP.
- "The Entity Component System and DOD" became Chapter 12, "Unity DOTS," expanded with Burst/SIMD, the Jobs system, and TransformAccessArray.
</content>
</invoke>
