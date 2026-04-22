# DOD Anti-Patterns Reference

Common OOP habits that violate the book's DOD architecture, with DOD corrections.

## Table of Contents
1. [Logic in MonoBehaviours](#1-logic-in-monobehaviours)
2. [Data and Logic Coupled in Objects](#2-data-and-logic-coupled-in-objects)
3. [List<T> in Hot Paths](#3-listt-in-hot-paths)
4. [Instantiate/Destroy During Gameplay](#4-instantiatedestroy-during-gameplay)
5. [GetComponent in Update](#5-getcomponent-in-update)
6. [Inheritance for Game Entities](#6-inheritance-for-game-entities)
7. [Over-Abstraction of Data Operations](#7-over-abstraction-of-data-operations)
8. [Defensive Runtime Checks on Balance](#8-defensive-runtime-checks-on-balance)
9. [Shared Code Between Unrelated Features](#9-shared-code-between-unrelated-features)
10. [Early Returns in Tick Functions](#10-early-returns-in-tick-functions)
11. [Addressables for Asset Loading](#11-addressables-for-asset-loading)
12. [String Formatting in Tick](#12-string-formatting-in-tick)

---

## 1. Logic in MonoBehaviours

### Anti-pattern
```csharp
public class EnemyManager : MonoBehaviour
{
    Enemy[] m_enemies;

    void Update()
    {
        foreach (var enemy in m_enemies)
            enemy.Move(Time.deltaTime); // logic lives inside enemy object
    }
}
```

### DOD Correction
```csharp
// Logic is static and lives in Logic.cs
public static class Logic
{
    static void moveEnemies(GameData gameData, Balance balance, float dt)
    {
        for (int i = 0; i < balance.NumEnemies; i++)
        {
            Vector2 dir = -gameData.EnemyPosition[i].normalized;
            gameData.EnemyPosition[i] += dir * balance.EnemyVelocity * dt;
        }
    }
}

// Board calls Logic, then syncs visuals
public class Board : MonoBehaviour
{
    public void Tick(GameData gameData, Balance balance, float dt)
    {
        Logic.Tick(gameData, balance, dt, out bool gameOver);
        for (int i = 0; i < balance.NumEnemies; i++)
            m_enemyPool[i].transform.localPosition = gameData.EnemyPosition[i];
    }
}
```

---

## 2. Data and Logic Coupled in Objects

### Anti-pattern
```csharp
public class Enemy
{
    public Vector2 position;
    public Vector2 direction;
    public float   velocity;
    public int     hp;

    public void Move() { position += direction * velocity; }
    public void TakeDamage(int dmg) { hp -= dmg; }
    public bool IsDead() => hp <= 0;
}
```

### DOD Correction
```csharp
// GameData.cs — data only, no methods
public class GameData
{
    public Vector2[] EnemyPosition;
    public Vector2[] EnemyDirection;
    public float[]   EnemyVelocity;
    public int[]     EnemyHP;
    public int[]     AliveEnemyIndices;
    public int       AliveEnemyCount;
}

// Logic.cs — logic only, takes data in and transforms it
public static class Logic
{
    static void moveEnemies(GameData gameData, Balance balance, float dt) { ... }
    static void applyDamage(GameData gameData, int enemyIndex, int damage) { ... }
    static bool isEnemyDead(GameData gameData, int enemyIndex) => gameData.EnemyHP[enemyIndex] <= 0;
}
```

---

## 3. List<T> in Hot Paths

### Anti-pattern
```csharp
public class GameData
{
    public List<Vector2> EnemyPositions = new List<Vector2>(); // GC pressure
    public List<int>     AliveEnemies   = new List<int>();     // GC pressure
}

// During gameplay:
AliveEnemies.Add(index);    // may allocate
AliveEnemies.Remove(index); // shifts array, no control
```

### DOD Correction
```csharp
public class GameData
{
    public Vector2[] EnemyPosition;     // pre-allocated to NumEnemies
    public int[]     AliveEnemyIndices; // pre-allocated to NumEnemies
    public int       AliveEnemyCount;   // current count
    public int[]     DeadEnemyIndices;
    public int       DeadEnemyCount;
}

// Add:
gameData.AliveEnemyIndices[gameData.AliveEnemyCount++] = index;

// Remove (Stack O(1) — use when order doesn't matter):
int index = gameData.DeadEnemyIndices[--gameData.DeadEnemyCount];
```

---

## 4. Instantiate/Destroy During Gameplay

### Anti-pattern
```csharp
void SpawnEnemy() {
    Instantiate(enemyPrefab); // heap allocation during gameplay → GC
}
void KillEnemy(GameObject enemy) {
    Destroy(enemy); // marks for GC; memory not freed until GC runs
}
```

### DOD Correction
```csharp
// Init() — allocate all objects up front
void Init(Balance balance)
{
    m_enemyPool = new GameObject[balance.NumEnemies];
    for (int i = 0; i < balance.NumEnemies; i++)
    {
        m_enemyPool[i] = AssetManager.Instance.GetEnemyGameObject(SpriteParent);
        m_enemyPool[i].SetActive(false);
    }
}

// Gameplay — activate/deactivate only
void showEnemy(int idx)  { m_enemyPool[idx].SetActive(true); }
void hideEnemy(int idx)  { m_enemyPool[idx].SetActive(false); }
```

---

## 5. GetComponent in Update

### Anti-pattern
```csharp
void Update()
{
    GetComponent<Renderer>().material.color = Color.red; // allocation every frame
}
```

### DOD Correction
```csharp
Renderer m_renderer; // cached reference

void Init()
{
    m_renderer = GetComponent<Renderer>(); // once
}

void Tick()
{
    m_renderer.material.color = Color.red; // no allocation
}
```

---

## 6. Inheritance for Game Entities

### Anti-pattern
```csharp
public abstract class Enemy { ... }
public class FastEnemy : Enemy { ... }
public class TankEnemy : Enemy { ... }
// Polymorphic array causes cache misses; vtable dispatch overhead
```

### DOD Correction
```csharp
// GameData uses type index into balance arrays
public class GameData
{
    public int[]     EnemyTypeIndex;   // index into balance enemy type table
    public Vector2[] EnemyPosition;
    public int[]     EnemyHP;
    // all enemies in same arrays; type determines behavior via balance lookup
}

public class Balance
{
    public EnemyTypeData[] EnemyTypes; // velocity, radius, HP per type
}

// Logic branches minimally on type
static void moveEnemy(GameData gameData, Balance balance, int i)
{
    EnemyTypeData type = balance.EnemyTypes[gameData.EnemyTypeIndex[i]];
    gameData.EnemyPosition[i] += dir * type.Velocity * dt;
}
```

---

## 7. Over-Abstraction of Data Operations

### Anti-pattern
```csharp
// Unnecessary generic helper class
public static class DODList
{
    public static void Add(int[] array, ref int count, int value) => array[count++] = value;
    public static void Remove(int[] array, ref int count, int value) { ... }
}

// Caller:
DODList.Add(gameData.AliveEnemyIndices, ref gameData.AliveEnemyCount, enemyIndex);
```

### DOD Correction
```csharp
// Inline — explicit, no indirection needed
gameData.AliveEnemyIndices[gameData.AliveEnemyCount++] = enemyIndex;
```

*Reason:* Abstractions hide what the code does with data. DOD prefers readable, explicit data manipulation. Tomorrow's requirement may differ — don't prematurely generalize.

---

## 8. Defensive Runtime Checks on Balance

### Anti-pattern
```csharp
public static void AllocateGameData(GameData gameData, Balance balance)
{
    if (balance.NumEnemies > 0 && balance.NumEnemies < MAX_ENEMIES)
    {
        gameData.EnemyPosition = new Vector2[balance.NumEnemies];
    }
    // Now readers must wonder: can NumEnemies really be 0 or negative?
    // Every branch adds complexity and the compiler can't optimize it away.
}
```

### DOD Correction
```csharp
// Validate at tool time in BalanceParser.cs:
static void validate()
{
    if (so.NumEnemies <= 0)    Debug.LogError("NumEnemies must be > 0");
    if (so.NumEnemies > 10000) Debug.LogError("NumEnemies exceeds 10000");
}

// Runtime trusts the data — no checks needed:
public static void AllocateGameData(GameData gameData, Balance balance)
{
    gameData.EnemyPosition = new Vector2[balance.NumEnemies]; // clean, simple
}
```

---

## 9. Shared Code Between Unrelated Features

### Anti-pattern
```csharp
public class ScheduleManager
{
    // Started for live events...
    // Then extended for online events...
    // Then reused for promotional offers...
    // Then reused for happy hour...
    // One change breaks all four features. QA can't catch everything.
    public void HandleSchedule(ScheduleType type) { ... } // complex branching
}
```

### DOD Correction
Duplicate code between features unless the shared code:
- Is simple and does exactly one thing
- Can be made `static` and follows the DOD pattern (data in → transform → data out)
- Has no need to ever diverge between features

```csharp
// Shared ONLY if genuinely identical and simple:
public static class CommonVisual
{
    public static string GetTimeElapsedString(float time) { ... }
}

// Feature-specific — even if similar, keep separate:
public static class LiveEventSchedule  { ... }
public static class PromoOfferSchedule { ... }
```

*Rule:* Once a feature ships and passes QA, never touch it again for another feature.

---

## 10. Early Returns in Tick Functions

### Anti-pattern
```csharp
public void Tick(GameData gameData, Balance balance, float dt)
{
    handleInput(gameData);
    Logic.Tick(gameData, balance, dt, out bool gameOver);

    if (gameOver)
    {
        Game.Instance.GameOver();
        return; // EARLY RETURN — skips enemy position sync below
    }

    // If game just ended, enemies aren't shown in their final positions
    for (int i = 0; i < balance.NumEnemies; i++)
        m_enemyPool[i].transform.localPosition = gameData.EnemyPosition[i];
}
```

### DOD Correction
```csharp
public void Tick(GameData gameData, Balance balance, float dt)
{
    handleInput(gameData);
    Logic.Tick(gameData, balance, dt, out bool gameOver);

    // Always sync visuals — player sees final state before game over screen
    for (int i = 0; i < balance.NumEnemies; i++)
        m_enemyPool[i].transform.localPosition = gameData.EnemyPosition[i];

    if (gameOver)
        Game.Instance.GameOver(); // called last
}
```

*Reason:* Early returns make it easy to skip code accidentally (memory deallocation, visual sync, etc.). Since game over is rare, there's no performance reason to skip the visual sync.

---

## 11. Addressables for Asset Loading

### Anti-pattern
```csharp
// Addressables: async, uncontrolled allocation, black box memory management
AsyncOperationHandle<GameObject> handle = Addressables.LoadAssetAsync<GameObject>("EnemyPrefab");
handle.Completed += OnLoaded; // allocation happens at unknown time
```

### DOD Correction
```csharp
// Assign in Unity Editor via [SerializeField] — no allocation surprise
public class AssetManager : Singleton<AssetManager>
{
    [SerializeField] GameObject m_enemyPrefab;
    public GameObject GetEnemyGameObject(Transform parent) => Instantiate(m_enemyPrefab, parent);
}

// For dynamic loading, Resources folder is acceptable:
GameObject prefab = Resources.Load<GameObject>("EnemyPrefab");
```

*Reason:* Addressables allocate at unpredictable times, causing stutters. We can't control when loading takes CPU time. The book recommends editor assignment for simplicity; Resources folder for dynamic needs.

---

## 12. String Formatting in Tick

### Anti-pattern
```csharp
void Update()
{
    // String.Format allocates every frame → GC pressure
    timerText.text = string.Format("{0:D2}:{1:D2}", minutes, seconds);
}
```

### DOD Correction
```csharp
// In CommonVisual.cs — called only when value changes, not every frame
public static string GetTimeElapsedString(float time)
{
    string result = "";
    int m = Mathf.FloorToInt(time / 60f);
    int s = Mathf.FloorToInt(time - m * 60f);
    result += (m >= 10) ? m.ToString() : "0" + m;
    result += ":";
    result += (s >= 10) ? s.ToString() : "0" + s;
    return result;
}

// Board — update text only when time changes (or accept one alloc per second)
m_timerText.text = CommonVisual.GetTimeElapsedString(gameData.GameTime);
```

*Better:* use `StringBuilder` and only update the text when the displayed second changes, not every frame.
