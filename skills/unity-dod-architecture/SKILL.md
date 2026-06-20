---
name: unity-dod-architecture
description: >
  Architecture guide for High Performance Unity Game Development (Using data-oriented design)
  by Nitzan Wilnai (Manning). Use this skill whenever working on a Unity project that follows
  the book's DOD architecture, or whenever the user asks to: generate DOD-compliant Unity code,
  scaffold a new game feature in DOD style, explain DOD concepts using the book's terminology,
  review code for DOD violations, or create any of the core architectural classes (Balance,
  GameData, Logic, Board, Game, AssetManager, GameDataIO, MetaDataIO, GUIRef, Singleton). Also
  trigger when the user mentions "balance data", "game data", "static logic functions",
  "data-in/transformation/data-out", "tooltime parsing", "ScriptableObject balance", "avoiding
  dictionaries", "indices at tool time", "dynamic object pool", "branchless", "branch prediction",
  "Unity null checks", "Unity DOTS", "Burst", "Jobs", "ECS", "TransformAccessArray", or any
  concept from the book.
---

# High Performance Unity Game Development — Unity Architecture Skill

This skill encodes the architecture from *High Performance Unity Game Development* (subtitle: *Using data-oriented design*) by Nitzan Wilnai (Manning Publications, MEAP v12). When helping users build or review Unity projects using this book's approach, follow all patterns and terminology precisely.

---

## Core Philosophy

DOD is NOT about ECS or Unity's DOTS package. It is a pure C# coding paradigm built on three pillars:
1. **Performance** — organize data in arrays for cache locality; separate data from logic
2. **Reduced Complexity** — static logic functions; clear data ownership; no abstraction for its own sake
3. **Extensibility** — adding a feature only requires figuring out new data + new logic; cost stays constant

**The DOD Mantra:** Every logic function takes data in, transforms it, and outputs data. Logic functions do not call Board or Game. They are pure transformations.

---

## The Five Architectural Components

```
Balance      — static config data; set at tool time by designers; never changes at runtime
GameData     — mutable runtime state; only modified by Logic functions
Logic        — static class of static functions; the ONLY place GameData is modified
Board        — MonoBehaviour; handles input + visual rendering; calls Logic functions
Game         — MonoBehaviour singleton; owns Balance + GameData; drives menus + Board
```

Supporting classes:
- **AssetManager** — Singleton; loads/provides prefabs and UI GameObjects via editor assignment
- **GameDataIO** — static class; binary save/load of GameData
- **MetaDataIO** — static class; binary save/load of persistent cross-session data (e.g. best time)
- **MetaData** — class; data that persists across sessions but is NOT part of a game session
- **GUIRef** — MonoBehaviour on prefabs; named dictionary of UI element references for artists
- **CommonVisual** — static class; shared visual helper functions (e.g. time formatting)
- **Singleton<T>** — base class for Unity singletons (AssetManager, Game)

---

## Data Rules

### Balance
- `public class Balance` (not struct — long-lived, passed by reference, will grow)
- Holds designer-set config: counts, radii, velocities, spawn rates, rules
- May be `[Serializable]` for simple games (edited in Unity Editor on the Game object)
- For complex games: stored as `ScriptableObject` (BalanceSO), parsed at **tool time** to binary, loaded at runtime
- **Never modified at runtime**
- Arrays in Balance are OK — their size is unknown until balance is loaded

### GameData
- `public class GameData` (not struct — holds arrays, heap-allocated, long-lived)
- All mutable runtime state lives here: positions, directions, velocities, counts, indices, timers, flags
- Arrays sized from Balance values (e.g. `new Vector2[balance.NumEnemies]`)
- Use parallel arrays, not arrays of structs:
  ```csharp
  // CORRECT — parallel arrays for cache locality
  public Vector2[] EnemyPosition;
  public Vector2[] EnemyDirection;
  public float[]   EnemyVelocity;

  // WRONG — array of objects breaks cache locality
  public Enemy[] Enemies;
  ```
- Use `int[]` index arrays + count variables instead of `List<T>`:
  ```csharp
  public int[] AliveEnemyIndices;
  public int   AliveEnemyCount;
  public int[] DeadEnemyIndices;
  public int   DeadEnemyCount;
  ```
- Boolean state flags go in GameData (e.g. `public bool InGame`)
- Enums for menu/game state go in GameData (e.g. `public MENU_STATE MenuState`)

### MetaData
- `public class MetaData`
- Data that persists across play sessions (e.g. best score, settings, volume)
- Saved/loaded via MetaDataIO; separate from GameData

---

## Logic Rules

```csharp
public static class Logic
{
    // Public entry points (called by Board and Game)
    public static void AllocateGameData(GameData gameData, Balance balance) { ... }
    public static void StartGame(GameData gameData, Balance balance, ...) { ... }
    public static void Tick(GameData gameData, Balance balance, float dt, out bool gameOver) { ... }

    // Private helpers — lowercase, descriptive
    static void moveEnemies(GameData gameData, Balance balance, float dt) { ... }
    static void checkEnemyOutOfBounds(GameData gameData, Balance balance) { ... }
    static void doEnemyToEnemyCollision(GameData gameData, Balance balance) { ... }
    static bool checkGameOver(MetaData metaData, GameData gameData, Balance balance) { ... }
    static Vector2 spawnEnemy(GameData gameData, Balance balance) { ... }
}
```

**Logic function rules:**
- All functions are `static` — Logic is a `static class`
- Public functions: PascalCase. Private helpers: camelCase
- Every function follows: **Data-In → Transformation → Data-Out**
- Functions take `GameData` and `Balance` as parameters (and `MetaData` when needed)
- Logic NEVER references Board, Game, or any MonoBehaviour
- Logic NEVER uses `MonoBehaviour.Update()`, coroutines, or Unity lifecycle methods
- Avoid early returns — keep the full execution path visible
- Avoid unnecessary branches; validate data at tool time instead
- Use `sqrMagnitude` instead of `magnitude` for distance comparisons (avoids sqrt)
- Allocate all arrays once in `AllocateGameData()`, never during Tick
- Use stack (array + count with `--` prefix) for O(1) spawn/despawn patterns

**The Tick pattern:**
```csharp
public static void Tick(GameData gameData, Balance balance, float dt, out bool gameOver)
{
    gameData.GameTime += dt;
    // ... timers, spawning
    moveEnemies(gameData, balance, dt);
    checkEnemyOutOfBounds(gameData, balance);
    doEnemyToEnemyCollision(gameData, balance);
    movePlayer(gameData, balance, dt);
    gameOver = checkGameOver(gameData, balance);
}
```

---

## Board Rules

```csharp
public class Board : MonoBehaviour
{
    // Private Unity references
    GameObject   m_player;
    GameObject[] m_enemyPool;
    Camera       m_mainCamera;

    // Called once at startup
    public void Init(MetaData metaData, GameData gameData, Balance balance, Camera cam) { ... }

    // Called when gameplay begins
    public void Show(GameData gameData, Balance balance) { ... }

    // Called every frame by Game
    public void Tick(GameData gameData, Balance balance, float dt)
    {
        handleInput(gameData);
        bool gameOver;
        Logic.Tick(gameData, balance, dt, out gameOver);
        // sync visual positions from GameData
        for (int i = 0; i < balance.NumEnemies; i++)
            m_enemyPool[i].transform.localPosition = gameData.EnemyPosition[i];
        if (gameOver)
            Game.Instance.GameOver();
    }

    // Called when gameplay ends
    public void Hide(Balance balance) { ... }

    // Private — handles Unity input, writes results into GameData
    void handleInput(GameData gameData) { ... }
}
```

**Board rules:**
- Board calls `Logic.*` functions — never the reverse
- Board reads visual state FROM GameData after Logic.Tick runs
- Board owns object pools (pre-allocated GameObjects) — never Instantiate/Destroy during gameplay
- Board owns GUIRef-based UI references after Init
- `handleInput()` is private; translates Unity input into GameData changes
- Avoid checking game-over in the middle of Tick; check at the end after visuals are synced
- Board does NOT own Balance or GameData — it receives them as parameters

---

## Game (Game Loop) Rules

```csharp
public class Game : Singleton<Game>
{
    Balance  m_balance  = new Balance();
    GameData m_gameData = new GameData();
    MetaData m_metaData = new MetaData();

    [SerializeField] Board m_board;
    // menu visual objects...

    void Awake()
    {
        // Load balance (local binary or ScriptableObject)
        // Load MetaData (best score etc.)
        Logic.AllocateGameData(m_gameData, m_balance);
        GameDataIO.Load(m_gameData);
        m_board.Init(m_metaData, m_gameData, m_balance, Camera.main);
        // Init menus...
        SetMenuState(MENU_STATE.MAIN_MENU);
    }

    void Update()
    {
        if (m_gameData.MenuState == MENU_STATE.IN_GAME)
            m_board.Tick(m_gameData, m_balance, Time.deltaTime);
    }

    public void StartGame() { ... }
    public void GameOver()  { ... }
    public void SetMenuState(MENU_STATE state) { ... }
}
```

**Game rules:**
- Game is a Singleton that holds Balance, GameData, MetaData
- Game drives the Board via `Update()` — Board does not have its own `Update()`
- Game owns menu state transitions
- `SetMenuState()` shows/hides Board and menu visuals

---

## AssetManager Rules

```csharp
public class AssetManager : Singleton<AssetManager>
{
    [SerializeField] GameObject m_playerPrefab;
    [SerializeField] GameObject m_enemyPrefab;
    [SerializeField] GameObject m_UIInGame;
    [SerializeField] GameObject m_UIMainMenu;
    [SerializeField] GameObject m_UIGameOver;

    public GameObject GetPlayerGameObject(Transform parent) => Instantiate(m_playerPrefab, parent);
    public GameObject GetEnemyGameObject(Transform parent)  => Instantiate(m_enemyPrefab, parent);
    public GameObject GetInGameUI()    => m_UIInGame;
    public GameObject GetMainMenuUI()  => m_UIMainMenu;
    public GameObject GetGameOverUI()  => m_UIGameOver;
}
```

**AssetManager rules:**
- Assets assigned via `[SerializeField]` in the Unity Editor — no Resources.Load or Addressables
- One dedicated getter per asset — no generic `Get(AssetType type)` overloads
- Singleton accessible via `AssetManager.Instance`
- Prefer loading from Resources folder over Addressables (Addressables cause uncontrolled async allocation)

---

## GUIRef Pattern

Artists/designers assemble UI prefabs and attach a `GUIRef` MonoBehaviour. It stores named references to UI elements. Code retrieves them by string key.

```csharp
public class GUIRef : MonoBehaviour
{
    [SerializeField] List<string>      m_textKeys;
    [SerializeField] List<TMP_Text>    m_textValues;
    [SerializeField] List<string>      m_buttonKeys;
    [SerializeField] List<Button>      m_buttonValues;

    public TMP_Text GetTextGUI(string key)   { ... }
    public Button   GetButton(string key)    { ... }
}
```

Usage in Init():
```csharp
GUIRef guiRef = m_UI.GetComponent<GUIRef>();
m_gui.BestTime       = guiRef.GetTextGUI("BestTime");
m_gui.ContinueButton = guiRef.GetButton("Continue");
m_gui.ContinueButton.onClick.AddListener(Game.Instance.ContinueGame);
```

**GUIRef rules:**
- Hard-code key strings at the call site — don't use consts (reduces readability, keys are unique per context)
- Add listeners in `Init()` once, not in `Show()` (avoids duplicate listener accumulation)
- Only save a reference if you need to modify the element in Show() (e.g. interactability, text)

---

## Memory & Allocation Rules

- **Allocate all data once** at load time or level start (in `AllocateGameData`, `Init`, `Show`)
- **Deallocate at level end** (in `Hide` / scene unload)
- **Never allocate during Tick/gameplay** — no `new`, no LINQ, no string concatenation in hot paths
- Use **object pools** for GameObjects — pre-instantiate in `Init`, activate/deactivate instead of Instantiate/Destroy
- Use **array + count** instead of `List<T>` to avoid GC pressure:
  ```csharp
  // Add (Stack/List style):
  array[count++] = value;

  // Remove from Stack (O(1)):
  int value = array[--count];

  // Remove by value (shift left):
  int newCount = 0;
  for (int i = 0; i < count; i++)
      if (array[i] != valueToRemove)
          array[newCount++] = array[i];
  count = newCount;
  ```
- Use `struct` for small, short-lived data passed by value; `class` for long-lived data or data containing arrays
- Call `System.GC.Collect()` manually during loading screens if needed — never during gameplay
- Use `Span<T>` + `stackalloc` for short-lived temporary arrays inside Logic functions — zero heap allocation:
  ```csharp
  // CORRECT — stack allocated, zero GC pressure
  Span<int>  inUse   = stackalloc int[balance.TileTypeCount];   // zero-initialized
  Span<bool> visited = stackalloc bool[balance.GridSize * balance.GridSize];
  Span<int>  dirs    = stackalloc int[4];

  // WRONG — heap allocation inside Logic (called every frame or frequently)
  int[]  inUse   = new int[balance.TileTypeCount];
  bool[] visited = new bool[gridSize * gridSize];
  ```
  **Note:** Add `using System;` for `Span<T>` and alias `using Random = UnityEngine.Random;` to avoid ambiguity with `System.Random`.

---

## Tooltime Balance Pipeline (Chapter 9 Pattern)

For complex games: balance lives in `ScriptableObject` → editor tool parses + validates → outputs binary file → loaded at runtime.

```csharp
// In an Editor-only static class:
[MenuItem("DOD/Balance/Parse Local")]
public static void ParseLocal()
{
    validate();       // check designer data before parsing
    byte[] data = parse();
    File.WriteAllBytes(Application.streamingAssetsPath + "/balance.dat", data);
    AssetDatabase.Refresh();
}

static void validate()
{
    BalanceSO so = (BalanceSO)AssetDatabase.LoadAssetAtPath("Assets/Data/Balance.asset", typeof(BalanceSO));
    if (so.NumEnemies <= 0)        Debug.LogError("NumEnemies must be > 0");
    if (so.NumEnemies > 10000)     Debug.LogError("NumEnemies exceeds max of 10000");
    // Add checks as issues are discovered — don't over-validate upfront
}
```

**Tooltime rules:**
- Validate at tool time so runtime code needs zero defensive checks on balance data
- Only add `validate()` checks when actual issues occur in development — don't pre-empt everything
- Single source of balance truth — avoid loading from multiple locations (server vs local)
- Version the balance binary for backwards compatibility
- Balance arrays allocated when balance is loaded (size unknown until then)

---

## Save/Load Pattern (GameDataIO)

```csharp
public static class GameDataIO
{
    static readonly string FilePath = Application.persistentDataPath + "/DODSurvivor/gamedata.dat";
    const int CURRENT_VERSION = 2;

    public static void Save(GameData gameData, Balance balance)
    {
        Directory.CreateDirectory(Path.GetDirectoryName(FilePath));
        using var fs = File.Create(FilePath);
        using var bw = new BinaryWriter(fs);
        bw.Write(CURRENT_VERSION);
        bw.Write(gameData.InGame);
        // write all fields in consistent order
        for (int i = 0; i < balance.NumEnemies; i++)
        {
            bw.Write(gameData.EnemyPosition[i].x);
            bw.Write(gameData.EnemyPosition[i].y);
        }
        // ...
    }

    public static void Load(GameData gameData)
    {
        if (!File.Exists(FilePath)) return;
        using var fs = File.Open(FilePath, FileMode.Open);
        using var br = new BinaryReader(fs);
        int version = br.ReadInt32();
        if (version >= 2) gameData.InGame = br.ReadBoolean();
        // read in the same order as Save
    }

    public static bool SaveGameExists()
    {
        if (!File.Exists(FilePath)) return false;
        using var fs = File.Open(FilePath, FileMode.Open);
        using var br = new BinaryReader(fs);
        br.ReadInt32(); // version
        return br.ReadBoolean(); // InGame
    }
}
```

**Save/load rules:**
- Write and read in the same order — mismatches cause out-of-stream errors
- Version the file; use `if (version >= N)` guards for backwards compatibility
- `SaveGameExists()` reads only what it needs (InGame flag) — doesn't parse the whole file
- Separate classes for different data: `GameDataIO`, `MetaDataIO`
- If adding a database source in future, create a new class — don't extend existing one

---

## Dictionaries & Indices (Chapter 10 Pattern)

Avoid `Dictionary<,>` lookups at runtime — they are ~10x slower than array access (hashing, collision chains, cache-unfriendly pointer chasing). Replace runtime dictionaries with **indices assigned at tool time**.

```csharp
// WRONG — dictionary lookup every frame
Dictionary<string, EnemyData> enemies;
EnemyData e = enemies["Zombie"];

// CORRECT — ID assigned at tool time, used as an array index at runtime
// Balance holds parallel arrays keyed by enemy type ID:
public float[] EnemyTypeVelocity;   // indexed by enemyTypeId
public float[] EnemyTypeRadius;
public int[]   EnemyTypeWeight;
// GameData stores the type ID per active enemy:
public int[] EnemyTypeId;           // indexed by enemy slot
float v = balance.EnemyTypeVelocity[gameData.EnemyTypeId[i]];
```

**Multiple entity types:** designers author one `EnemySO` ScriptableObject per type; the tool-time parser assigns each a stable integer ID and flattens the data into Balance arrays. `AssetManager` holds a `[SerializeField] GameObject[] m_enemyPrefabs` (order irrelevant) and is matched to types by prefab name at load.

**Dynamic object pools:**
- Pick a **maximum** pool size in Balance, preallocate to it once — never resize at runtime.
- Only **add** items to the pool at runtime. Removing/freeing at runtime fragments memory and triggers the GC.

**Backwards compatibility for indices:** indices are not stable across builds (a designer may insert a new type). On **save**, write each object's unique ID, not its index. On **load**, build a `Dictionary<id, index>` once to remap saved IDs to current indices. This dictionary is used ONLY at load time, never during gameplay.

---

## Branching & Branchless Code (Chapter 11 Pattern)

Branches cost performance (misprediction flushes the CPU pipeline; even predictable branches cost in tight loops) and add code complexity. Reduce them by reorganizing data, not by cleverer conditionals.

**Rules:**
- Move conditional logic OUT of hot core functions; decide once, up front, or at tool time.
- Avoid early returns — they fragment the execution path and hide branches.
- **Separate data instead of checking it:** keep alive and dead enemies in separate index arrays (`AliveEnemyIndices` / `DeadEnemyIndices`) so loops never test an `isAlive` flag per item.
- **Separate objects to remove branches:** factor shared UI into common elements rather than branching on type.
- Watch for **hidden branches** — default parameter values, and especially Unity null checks.

**Unity null checks are expensive** (C#↔C++ interop on `UnityEngine.Object`). Avoid repeating them:
- **Check once:** validate GameObjects/components for null during loading, then trust them.
- **Own the lifetime:** if your code created and owns the data/GameObject, you don't need to null-check it later.
- **Zero tolerance:** adopt a strict error handler during development (e.g. pause the editor on any error/exception) so missing data is caught at dev time, not guarded at runtime.
- **Avoid fire-and-forget:** coroutines and async calls can resume and touch data that has since been freed/nulled — prefer driving everything from the deterministic Tick.

---

## Unity DOTS (Chapter 12 Pattern)

DOTS is an **incremental optimization layered on top of existing DOD code — not a rewrite.** Because data already lives in arrays, adopting DOTS is selective and local. Reach for it only when a specific system is the measured bottleneck.

**Do NOT add DOTS to a project by default.** Most projects never need it — plain DOD already gives cache-friendly, allocation-free code. Never scaffold Burst/Jobs/ECS/NativeArray when creating or extending a feature. Only recommend or introduce DOTS *after* profiling identifies a real bottleneck, and even then only for the specific system that is slow. When in doubt, suggest it as an option for the user to consider rather than applying it.

- **Burst (SIMD):** compiles array math to SIMD instructions that process multiple elements per instruction. Requires `NativeArray<T>` and DOTS-compatible types (e.g. `float2` instead of `Vector2`).
- **Jobs:** split array work across CPU cores. Scheduling has overhead — it can be *slower* on small data sets, so measure.
- **ECS:** Entity = the array index, Component = the arrays of data, System = the logic over them. ECS is one implementation of DOD; it adds complexity and is not required for performance gains.
- **TransformAccessArray:** update GameObject transforms in parallel without converting to ECS. It iterates all elements (unused slots add branching), so use it only when transform updates are the bottleneck.

---

## Common Anti-Patterns to Flag

| Anti-Pattern | DOD Correction |
|---|---|
| Logic in MonoBehaviours (`Update` doing game logic) | Move to `Logic` static functions; Board only calls Logic |
| `List<T>` in hot paths | Array + count variable |
| `Instantiate`/`Destroy` during gameplay | Object pools pre-allocated in Init/Show |
| Classes holding both data and methods that mutate state | Separate into data class + static Logic functions |
| `GetComponent` in Update | Cache references in Init or Show |
| Inheritance chains for game entities | Parallel arrays in GameData; index-based identity |
| Generic helper functions abstracting array operations | Explicit inline code — DOD prefers readable data manipulation over abstraction |
| Early returns in the middle of Tick | Let Tick run fully; check results at the end |
| Shared code between features | Duplicate if needed; only share if simple, single-purpose, and can be static |
| Defensive runtime checks on balance data | Validate at tool time; trust the data at runtime |
| Unity Addressables for asset loading | Assign in editor via `[SerializeField]`; use Resources folder for dynamic loads |
| `Dictionary<,>` lookups during gameplay | Assign indices/IDs at tool time; use arrays at runtime (~10x faster). Allow a dictionary only at load time |
| Resizing/freeing pools at runtime | Preallocate to a max size once; only add items at runtime (removal fragments memory + triggers GC) |
| Saving array indices directly | Save stable unique IDs; remap with a load-time dictionary for backwards compatibility |
| Per-item `isAlive`/status checks in loops | Separate data into alive/dead index arrays so the branch disappears |
| Repeated null checks on `UnityEngine.Object` | Check once at load and own the lifetime; null checks cross C#↔C++ and are expensive |
| Reaching for ECS/DOTS by default | DOTS is an incremental optimization for measured bottlenecks; DOD does not require ECS |

---

## File Naming Conventions

| File | Purpose |
|---|---|
| `Balance.cs` | Balance data class |
| `GameData.cs` | GameData class + MENU_STATE enum |
| `MetaData.cs` | MetaData class |
| `Logic.cs` | Static logic class (can be split: `EnemyLogic.cs`, `PlayerLogic.cs` etc.) |
| `Board.cs` | MonoBehaviour board |
| `Game.cs` | MonoBehaviour game loop singleton |
| `AssetManager.cs` | Singleton asset loader |
| `GameDataIO.cs` | Static save/load for GameData |
| `MetaDataIO.cs` | Static save/load for MetaData |
| `GUIRef.cs` | MonoBehaviour UI reference dictionary |
| `Singleton.cs` | Generic Singleton<T> base class |
| `CommonVisual.cs` | Static shared visual helpers |
| `BalanceSO.cs` | ScriptableObject for designer balance editing |
| `BalanceParser.cs` | Editor-only tool for parsing BalanceSO to binary |

For larger games, split Logic by domain: `EnemyLogic.cs`, `PlayerLogic.cs`, `CollisionLogic.cs`, etc.

---

## For deeper reference, see:
- `references/patterns.md` — detailed patterns with annotated code examples
- `references/anti-patterns.md` — common OOP habits and how to refactor them
- `references/chapter-map.md` — which chapter covers which concept
