# DOD Patterns Reference

Detailed code patterns from *Data-Oriented Design for Games* by Nitzan Wilnai.

## Table of Contents
1. [Parallel Arrays vs Array of Objects](#1-parallel-arrays-vs-array-of-objects)
2. [Static Logic Function Anatomy](#2-static-logic-function-anatomy)
3. [Array-Based List / Stack / Queue](#3-array-based-list--stack--queue)
4. [Object Pool Pattern](#4-object-pool-pattern)
5. [Singleton Pattern](#5-singleton-pattern)
6. [Menu Visual Pattern](#6-menu-visual-pattern)
7. [ScriptableObject Balance Pipeline](#7-scriptableobject-balance-pipeline)
8. [Data-First Feature Development Flow](#8-data-first-feature-development-flow)

---

## 1. Parallel Arrays vs Array of Objects

### OOP (avoid)
```csharp
public class Enemy {
    public Vector2 position;
    public Vector2 direction;
    public float   velocity;
    public int     hp;
    public void Move() { position += direction * velocity; }
}
Enemy[] enemies = new Enemy[100];
```
Problem: each `Enemy` object is scattered in heap memory. Iterating all enemies causes cache misses because the CPU loads unrelated fields (hp, etc.) when it only needs position/direction/velocity.

### DOD (use)
```csharp
public class GameData {
    public Vector2[] EnemyPosition;
    public Vector2[] EnemyDirection;
    public float[]   EnemyVelocity;
    public int[]     EnemyHP;
}
```
Iterating positions loads only positions — all 100 positions fit in a few cache lines. The CPU doesn't waste cache space on unrelated data.

---

## 2. Static Logic Function Anatomy

Every Logic function follows: **Data-In → Transformation → Data-Out**

```csharp
// Data-In:  gameData (state to transform), balance (config), dt (time)
// Data-Out: gameData.EnemyPosition modified in-place
static void moveEnemies(GameData gameData, Balance balance, float dt)
{
    for (int i = 0; i < balance.NumEnemies; i++)
    {
        // Player is always at origin — direction toward player = -enemyPosition.normalized
        Vector2 dir = -gameData.EnemyPosition[i].normalized;
        gameData.EnemyPosition[i] += dir * balance.EnemyVelocity * dt;
    }
}
```

Out parameters for secondary outputs:
```csharp
public static void Tick(GameData gameData, Balance balance, float dt, out bool gameOver)
{
    gameData.GameTime += dt;
    moveEnemies(gameData, balance, dt);
    gameOver = checkGameOver(gameData, balance);
}
```

---

## 3. Array-Based List / Stack / Queue

### DOD List (dynamic count, shift-left removal)
```csharp
// Add:
gameData.AliveEnemyIndices[gameData.AliveEnemyCount++] = enemyIndex;

// Remove by value (preserves order):
int newCount = 0;
for (int i = 0; i < gameData.AliveEnemyCount; i++)
    if (gameData.AliveEnemyIndices[i] != enemyIndex)
        gameData.AliveEnemyIndices[newCount++] = gameData.AliveEnemyIndices[i];
gameData.AliveEnemyCount = newCount;

// Using Array.Copy (faster for large arrays):
static void removeEnemy(GameData gameData, int enemyIndex)
{
    int index = -1;
    for (int i = 0; i < gameData.AliveEnemyCount; i++)
        if (gameData.AliveEnemyIndices[i] == enemyIndex) { index = i; break; }
    if (index > -1)
    {
        Array.Copy(gameData.AliveEnemyIndices, index + 1,
                   gameData.AliveEnemyIndices, index,
                   gameData.AliveEnemyCount - index - 1);
        gameData.AliveEnemyCount--;
    }
}
```

### DOD Stack (O(1) push/pop — use for spawn pools)
```csharp
// Push (add to dead pool):
gameData.DeadEnemyIndices[gameData.DeadEnemyCount++] = enemyIndex;

// Pop (spawn from dead pool):
int enemyIndex = gameData.DeadEnemyIndices[--gameData.DeadEnemyCount];
gameData.AliveEnemyIndices[gameData.AliveEnemyCount++] = enemyIndex;
```

### DOD Queue (FIFO, less common — use Stack if order doesn't matter)
```csharp
// Enqueue:
array[count++] = value;

// Dequeue (shift left):
int value = array[0];
Array.Copy(array, 1, array, 0, count - 1);
count--;
return value;
```

**Why not List<T>?** List<T> allocates heap memory and can trigger GC. Array + count gives full control, zero allocation, and identical performance characteristics.

**Why no DODList helper class?** Prefer explicit code over abstraction. One line of array manipulation is clearer than calling a helper function. Different problems need different solutions — don't label them as "data structures."

---

## 4. Object Pool Pattern

### Allocate once at load/level start
```csharp
public void Init(Balance balance)
{
    m_enemyPool = new GameObject[balance.NumEnemies];
    for (int i = 0; i < balance.NumEnemies; i++)
    {
        m_enemyPool[i] = AssetManager.Instance.GetEnemyGameObject(SpriteParent);
        m_enemyPool[i].SetActive(false);
    }
}
```

### Spawn = activate
```csharp
// In Board.Show() or when Logic says an enemy spawned:
int enemyIndex = gameData.AliveEnemyIndices[i];
m_enemyPool[enemyIndex].SetActive(true);
m_enemyPool[enemyIndex].transform.localPosition = gameData.EnemyPosition[enemyIndex];
```

### Despawn = deactivate
```csharp
m_enemyPool[enemyIndex].SetActive(false);
```

### Deallocate at level end
```csharp
public void Hide(Balance balance)
{
    for (int i = 0; i < balance.NumEnemies; i++)
        m_enemyPool[i].SetActive(false);
    // Destroy at scene unload, not here unless level-specific enemies
}
```

---

## 5. Singleton Pattern

```csharp
public class Singleton<T> : MonoBehaviour where T : MonoBehaviour
{
    public static T Instance { get; private set; }

    protected virtual void Awake()
    {
        if (Instance != null && Instance != this)
        {
            Destroy(gameObject);
            return;
        }
        Instance = this as T;
    }
}

// Usage:
public class Game : Singleton<Game> { ... }
public class AssetManager : Singleton<AssetManager> { ... }
```

---

## 6. Menu Visual Pattern

Each menu has a Visual class (not MonoBehaviour) with a data struct for cached references.

```csharp
// Data struct for UI references
public class MainMenuGUI
{
    public GameObject UI;
    public TMP_Text   BestTime;
    public Button     ContinueButton;
}

// Visual class — not a MonoBehaviour
public class MainMenuVisual
{
    MainMenuGUI m_gui;
    MetaData    m_metaData;

    public void Init(MetaData metaData)
    {
        m_metaData = metaData;
        m_gui = new MainMenuGUI();
        m_gui.UI = AssetManager.Instance.GetMainMenuUI();

        GUIRef guiRef = m_gui.UI.GetComponent<GUIRef>();
        m_gui.BestTime       = guiRef.GetTextGUI("BestTime");
        m_gui.ContinueButton = guiRef.GetButton("Continue");

        // Add listeners in Init (once), not in Show
        m_gui.ContinueButton.onClick.AddListener(Game.Instance.ContinueGame);
        guiRef.GetButton("Start").onClick.AddListener(Game.Instance.StartGame);
    }

    public void Show()
    {
        m_gui.UI.SetActive(true);
        m_gui.BestTime.text = CommonVisual.GetTimeElapsedString(m_metaData.BestTime);
        m_gui.ContinueButton.interactable = GameDataIO.SaveGameExists();
    }

    public void Hide()
    {
        m_gui.UI.SetActive(false);
    }
}
```

---

## 7. ScriptableObject Balance Pipeline

### Step 1 — BalanceSO (designer-facing)
```csharp
[CreateAssetMenu(fileName = "Balance", menuName = "DOD/Balance")]
public class BalanceSO : ScriptableObject
{
    public int   NumEnemies;
    public float EnemyVelocity;
    public float EnemyRadius;
    public float SpawnRadius;
    public float PlayerVelocity;
    public float MinCollisionDistance;
}
```

### Step 2 — Editor tool: validate + parse
```csharp
// Editor-only class
public static class BalanceParser
{
    [MenuItem("DOD/Balance/Parse Local")]
    public static void ParseLocal()
    {
        validate();
        byte[] data = parse();
        string path = Application.streamingAssetsPath + "/balance.dat";
        File.WriteAllBytes(path, data);
        AssetDatabase.Refresh();
        Debug.Log("Balance parsed successfully.");
    }

    static void validate()
    {
        BalanceSO so = (BalanceSO)AssetDatabase.LoadAssetAtPath(
            "Assets/Data/Balance.asset", typeof(BalanceSO));
        if (so.NumEnemies <= 0)
            Debug.LogError("NumEnemies must be > 0. Currently: " + so.NumEnemies);
        if (so.NumEnemies > 10000)
            Debug.LogError("NumEnemies > 10000: " + so.NumEnemies);
        // Add checks as real issues emerge during development
    }

    static byte[] parse()
    {
        BalanceSO so = (BalanceSO)AssetDatabase.LoadAssetAtPath(
            "Assets/Data/Balance.asset", typeof(BalanceSO));
        using var ms = new System.IO.MemoryStream();
        using var bw = new System.IO.BinaryWriter(ms);
        bw.Write(so.NumEnemies);
        bw.Write(so.EnemyVelocity);
        bw.Write(so.EnemyRadius);
        bw.Write(so.SpawnRadius);
        bw.Write(so.PlayerVelocity);
        bw.Write(so.MinCollisionDistance);
        return ms.ToArray();
    }
}
```

### Step 3 — Runtime loader
```csharp
public static Balance LoadBalance()
{
    string path = Application.streamingAssetsPath + "/balance.dat";
    byte[] data = File.ReadAllBytes(path);
    Balance balance = new Balance();
    using var ms = new System.IO.MemoryStream(data);
    using var br = new System.IO.BinaryReader(ms);
    balance.NumEnemies          = br.ReadInt32();
    balance.EnemyVelocity       = br.ReadSingle();
    balance.EnemyRadius         = br.ReadSingle();
    balance.SpawnRadius         = br.ReadSingle();
    balance.PlayerVelocity      = br.ReadSingle();
    balance.MinCollisionDistance = br.ReadSingle();
    return balance;
}
```

---

## 8. Data-First Feature Development Flow

When adding any new feature, always follow this sequence:

1. **What data does this feature need?** → Add to `Balance` (if static) or `GameData` (if dynamic)
2. **When is that data allocated?** → Add to `Logic.AllocateGameData()` if arrays needed
3. **What transforms this data?** → Add static function(s) to `Logic`
4. **How is it initialized at game start?** → Add to `Logic.StartGame()`
5. **Does it run every frame?** → Add call in `Logic.Tick()`
6. **How is it shown to the player?** → Update `Board.Tick()` to sync visuals from GameData
7. **Does it need a designer setting?** → Add to `BalanceSO`, update `validate()` and `parse()`
8. **Does it need saving?** → Update `GameDataIO.Save()` and `GameDataIO.Load()` with version bump

**The cost of a new feature is always the same:** figure out what data you need and what logic transforms it. No refactoring of existing systems required.
