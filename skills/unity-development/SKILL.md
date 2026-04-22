---
name: unity-development
description: >
  Skill for communicating with Unity Editor via unity-agent-cli. Covers compilation checking,
  executing static methods, building UI prefabs, assigning assets, taking automated screenshots,
  verifying menus visually, and fixing errors autonomously. Use this skill whenever working on
  a Unity project that has the unity-agent-bridge package installed.
---

# Unity Development Skill

This skill enables autonomous Unity Editor communication via `unity-agent-cli`.

---

## Prerequisites

- Unity Editor must be open with the project loaded
- `unity-agent-bridge` package must be installed in the Unity project
- `unity-agent-cli` must be installed globally (`npm install -g unity-agent-cli`)
- Add to user settings (`~/.claude/settings.json`): `"Bash(unity-agent-cli *)"`

---

## 1. Compilation Checking

**After every `.cs` file change**, run:

```bash
unity-agent-cli check
```

### Interpreting results:

- **Exit code 0** with `✅ Compile Success` → code is good
- **Exit code 1** with real errors → fix the C# files and re-run
- **Exit code 1** with Debug.Log entries → these are FALSE POSITIVES from the Unity console log detection. The check command's error detection picks up `Debug.Log` entries as errors. Look for `error CS` in the output to distinguish real errors from log noise.

### Auto-fix loop:

```
1. Run unity-agent-cli check
2. If real compile errors (contains "error CS"): fix the code, go to 1
3. If only Debug.Log false positives: compilation succeeded, continue
```

---

## 2. Executing Static Methods

Run any public/private static C# method in the Unity Editor:

```bash
unity-agent-cli exec "ClassName.MethodName()"
```

### How it works:
- CLI sends POST to `/exec` endpoint on Unity's HTTP server (port 5142)
- Server finds the type via reflection across all loaded assemblies
- Executes on the main thread via `ManualResetEventSlim` (required for Unity API)
- Timeout: 120 seconds (configurable in the bridge code)

### Common commands:

```bash
# Build all UI prefabs
unity-agent-cli exec "MainMenuScreenBuilder.BuildAll()"

# Assign sprites and prefabs to AssetManager
unity-agent-cli exec "DODSetup.AssignPrefabsMenu()"

# Build specific prefabs
unity-agent-cli exec "ShopScreenBuilder.Build()"
unity-agent-cli exec "SettingsScreenBuilder.Build()"

# Take screenshots
unity-agent-cli exec "PlayModeScreenshot.CaptureAllScreens()"
```

### Troubleshooting:

| Error | Cause | Fix |
|-------|-------|-----|
| `Type 'X' not found` | Compile error preventing the type from loading | Run `unity-agent-cli check` first, fix errors |
| `Execution timed out` | Method takes too long | Increase timeout in bridge code |
| `Unity Editor is not open` | Server not running or domain reload in progress | Wait 10-15 seconds and retry |
| `Port 5142 already in use` | Old server process holding port after crash | Run `lsof -ti :5142 \| xargs kill -9` then trigger a domain reload in Unity |

---

## 3. Building UI Prefabs

### When to rebuild:
- After modifying any `*Builder.cs` file
- After adding/changing sprites
- After changing canvas reference resolution or layout

### Standard workflow:

```bash
# 1. Check compilation
unity-agent-cli check

# 2. Build all prefabs
unity-agent-cli exec "MainMenuScreenBuilder.BuildAll()"

# 3. Assign sprites to AssetManager
unity-agent-cli exec "DODSetup.AssignPrefabsMenu()"
```

### Builder conventions (lessons learned):

1. **Reference resolution**: Always use `1080×1920` for all canvases
2. **childControlWidth**: Set to `true` on ALL HorizontalLayoutGroups — prevents zero-width children
3. **Prefab path**: Save to `Assets/Resources/UI/` for runtime `Resources.Load`
4. **ensureFolders**: Use `Assets/Resources` not `Assets/Prefabs`
5. **Sprite import**: Force `SpriteImportMode.Single`, not Multiple
6. **Text wrapping**: Use `textWrappingMode = TextWrappingModes.NoWrap` (not deprecated `enableWordWrapping`)
7. **Serialized sprites**: Assign via `SerializedObject` at build time (star sprites, lock sprites, etc.)
8. **SVG conversion**: Use `cairosvg` (not ImageMagick which produces blank/grayscale PNGs)

### Scaling from 390×844 to 1080×1920:
When importing UI packages designed for 390×844, multiply ALL dimension values by `1080/390 ≈ 2.77`:
- Padding, spacing, font sizes, heights, widths, icon sizes, margins
- Use a script to bulk-scale, then verify visually

---

## 4. Taking Screenshots

### Setup required (already in the project):

- `PlayModeScreenshot.cs` (Editor script) — enters Play mode, polls for completion
- `ScreenshotHelper.cs` (runtime script) — captures via `ReadPixels` at `WaitForEndOfFrame`
- Flag file communication (`capture.flag` → `screenshot.done`)

### How it works:

1. `PlayModeScreenshot.CaptureAllScreens()` writes a flag file and enters Play mode
2. `ScreenshotHelper.AutoStart()` (via `[RuntimeInitializeOnLoadMethod]`) reads the flag
3. Coroutine navigates through screens and captures at `WaitForEndOfFrame`
4. Writes `.done` marker file when complete
5. Editor script polls for `.done`, then exits Play mode

### Key technical details:

- **Run in background**: Must set `Application.runInBackground = true` and `PlayerSettings.runInBackground = true` before entering Play mode — otherwise Unity pauses when terminal has focus
- **Screen Space Overlay**: `ReadPixels` at `WaitForEndOfFrame` captures Canvas overlays. `Camera.Render()` does NOT.
- **Navigation**: Use reflection to call `Game.setMenuState()` for navigating between screens. Direct callback invocation works for MainMenuScreen/LevelSelectScreen.
- **Container deployment**: Directly manipulate `GameData` fields via reflection to put containers on the track for gameplay screenshots.

### Capture workflow:

```bash
# Trigger capture
unity-agent-cli exec "PlayModeScreenshot.CaptureAllScreens()"

# Wait for completion (30-45 seconds)
sleep 45

# View screenshots
# Read Screenshots/01_main_menu.png
# Read Screenshots/02_level_select.png
# Read Screenshots/03_gameplay.png
# Read Screenshots/04_shop.png
# Read Screenshots/05_settings.png
```

### Adding new screens to the capture sequence:

In `ScreenshotHelper.CaptureAllScreens()`:

```csharp
// Navigate using reflection
invokeSetMenuState(game, MENU_STATE.YOUR_STATE);
yield return new WaitForSeconds(1f);
yield return new WaitForEndOfFrame();
SaveScreenshot(Path.Combine(s_saveDir, "XX_screen_name.png"));
```

---

## 5. Visual Verification Workflow

After taking screenshots, analyze each screen for:

### Layout issues:
- Elements overlapping (TopBar over content, stacks over powerup tray)
- Zero-width elements (text, pills, nav items) — caused by `childControlWidth = false`
- Stretched icons — need `preserveAspect = true` and `flexibleWidth = 0`
- Wrong sizes — elements scaled for 390px instead of 1080px

### Content issues:
- Missing sprites (white squares) — sprites not imported as Single, or not assigned
- Wrong colors — ImageMagick SVG conversion produced grayscale
- GUIRef errors — screen references buttons/text that were removed from the prefab

### Fix workflow:
```
1. Take screenshots
2. Analyze each screen visually
3. Fix issues in builder code or runtime code
4. unity-agent-cli check
5. unity-agent-cli exec "MainMenuScreenBuilder.BuildAll()"
6. unity-agent-cli exec "DODSetup.AssignPrefabsMenu()"
7. Take screenshots again
8. Verify fixes
9. git add + git commit
```

---

## 6. Common Patterns

### Adding a new UI screen:

1. Create `NewScreen.cs` (MonoBehaviour with Init/Show/Hide, callbacks)
2. Create `NewScreenBuilder.cs` (Editor script with `[MenuItem]` and `Build()`)
3. Add SVG sprites, convert with cairosvg, place in `Assets/Sprites/UI/NewScreen/`
4. Add `NewScreenBuilder.Build()` to `MainMenuScreenBuilder.BuildAll()`
5. Add `MENU_STATE.NEW_SCREEN` to `GameData.cs`
6. Load prefab in `Game.loadScreens()`, wire callbacks
7. Add to `Game.setMenuState()` switch
8. Add to `ScreenshotHelper.CaptureAllScreens()` for verification
9. Build, assign, screenshot, verify, commit

### Fixing "Type not found" for exec:

This means the type's assembly didn't load, usually because of a compile error:
```bash
unity-agent-cli check  # find the real error
# fix it
unity-agent-cli check  # verify
unity-agent-cli exec "TypeName.Method()"  # should work now
```

### Recovering from port conflict:

```bash
lsof -ti :5142 | xargs kill -9
# Then trigger a domain reload in Unity (save a script, or press Play/Stop)
```

---

## 7. DOD Architecture Integration

UI screens follow the DOD pattern:
- Screens are **pure visual layers** — never read GameData/MetaData directly
- All state changes route through **System.Action callbacks** assigned by Game
- **GUIRef** stores named UI references at prefab build time
- **Init()** wires references once, **Show()** populates data, **Hide()** deactivates
- Game owns all state transitions via `setMenuState()`
