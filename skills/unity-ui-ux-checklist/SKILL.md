---
name: unity-ui-ux-checklist
description: >
  Use when building, modifying, or reviewing Unity UI screens and prefabs.
  Covers: text sizing for numbers, image stretching, layout pitfalls, safe area
  handling, missing sprites, ContentSizeFitter issues, and visual verification.
  Trigger when you see UI builder code, prefab construction, Canvas layout,
  or after taking screenshots that reveal visual bugs.
---

# Unity UI/UX Checklist

A checklist of common UI/UX issues to verify when building or modifying Unity UI screens. Run through this after every UI change.

---

## 1. Text Sizing

- **Number fields must fit their max value.** If a gold counter can reach 999,999 — size the container for 6 digits, not 3. Determine the maximum digit count from the game design and size accordingly.
- **Runtime-populated labels** (level names, prices, player names) must account for the longest possible string. Test with max-length content during development.
- **Don't trust the builder default text** as a sizing guide. "20" in the builder might become "999,999" at runtime.

## 2. Image Rendering

| Problem | Cause | Fix |
|---------|-------|-----|
| Icon stretched horizontally in VLG | `childForceExpandWidth = true` on parent | Set `flexibleWidth = 0` on the icon's LayoutElement |
| Badge/icon distorted | Missing `preserveAspect` | Set `preserveAspect = true` on the Image |
| 9-slice background distorted | Image type is Simple (default) | Set `Image.Type = Image.Type.Sliced` |
| `fillAmount` ignored (bar always full) | No sprite on the Image | `Image.Type.Filled` requires a sprite to work. Use anchor-based width instead, or assign a 1px white sprite |
| White square where icon should be | Image slot with no sprite loaded | Either load the correct sprite, or set `Image.color` to transparent. Never leave white default |
| Sprites load in builder but show white at runtime | `[SerializeField]` sprite fields on the component are null | Assign via `SerializedObject` in the builder, not just on the Image |

## 3. Layout

- **Anchors are for alignment, sizeDelta is for dimensions.** Use anchors to position elements relative to their parent (center, top-left, etc.), then set explicit width/height via `sizeDelta`. The `CanvasScaler` handles scaling automatically — do not use anchors to control size.
- **Group aligned elements under a shared parent RectTransform.** Position/size the parent, then use relative anchors within the parent for children. This way, moving a row means changing 1 value instead of N.

  **Pattern:**
  1. Create a parent RectTransform (empty GameObject) for each visual "row" or "group"
  2. Position the parent on the screen (anchor + pos + size)
  3. Children use anchors RELATIVE to the parent: left=(0, 0.5), center=(0.5, 0.5), right=(1, 0.5)
  4. Children's Y positions are relative to the parent, making vertical alignment automatic

  **Example — HUD top bar:**
  ```
  Row1 (parent) — anchor=(0.5, 1), full width, height=70, y=-50
    ├── TurnGroup (left)  — anchor=(0, 0.5), x=30, y=0
    │   ├── "TURN" label  — anchor=(0.5, 1), top of group
    │   └── "1" number    — anchor=(0.5, 0), bottom of group
    ├── Score (center)    — anchor=(0.5, 0.5), x=0, y=0
    └── Pause (right)     — anchor=(1, 0.5), x=-55, y=0
  ```

  **Rules:**
  - Elements at the same visual Y → same parent
  - Stacked elements (label + value) → sub-group with its own parent
  - Position the group's parent, not individual children
  - Children anchor to edges of parent (left/center/right), with Y=0 for vertical centering
  - **Symmetric edge margins:** Left-anchored elements must be the same distance from the left edge as right-anchored elements are from the right edge (e.g., if left element has x=30, right element should have x=-30)

- **Place UI elements once in `Show()`, not every frame.** Set positions, sizes, text, and sprites when the screen is shown. Do not recompute or reposition UI in `Update()` unless the value is actively animating or changing.
- **`childForceExpandWidth = true`** stretches ALL children to fill the container. Any fixed-size element (icon, badge, square button) must have `flexibleWidth = 0` on its LayoutElement to resist this.
- **`childControlWidth = false`** means flexible width on LayoutElements is ignored — children use their own sizeDelta. Switch to `true` if you need flexible/expanding children.
- **`ContentSizeFitter` with show/hide children**: The fitter calculates preferred size based on active children. When you show or hide children at runtime, call `LayoutRebuilder.ForceRebuildLayoutImmediate(rectTransform)` after activation so the size recalculates.
- **`GetComponentInChildren<T>()`** returns the first match in depth-first order — fragile for GUIRef wiring. Always capture the explicit reference from `createText()`/`createImageSlot()` and pass it directly to `guiRef.EditorAdd*()`.
- **Reference resolution**: Always use `1080×1920` for all canvases in this project.

## 4. Safe Area

Mobile devices have notches, Dynamic Islands, rounded corners, and navigation bars that obscure UI content. Every screen must handle this.

**Pattern**: Add a `SafeArea` child GameObject as the first content parent under the Canvas root. Attach `SafeAreaHandler` to it. All interactive content (buttons, text, inputs) must be children of this SafeArea — never direct children of the Canvas root.

**What goes INSIDE SafeArea** (affected by insets):
- All interactive elements (buttons, text fields)
- Navigation bars, top bars, tab bars
- Any content the user needs to read or tap

**What goes OUTSIDE SafeArea** (full-screen):
- Background images/colors (should fill edge-to-edge behind the notch)
- Dim overlays for modals
- Decorative elements that can be partially obscured

**Builder pattern:**
```csharp
// 1. Full-screen background — OUTSIDE safe area
createFullStretchImage(root, "Background", COL_BG);

// 2. Safe area container — content goes inside
GameObject safeArea = new GameObject("SafeArea");
safeArea.transform.SetParent(root.transform, false);
RectTransform rt = safeArea.AddComponent<RectTransform>();
rt.anchorMin = Vector2.zero;
rt.anchorMax = Vector2.one;
rt.offsetMin = Vector2.zero;
rt.offsetMax = Vector2.zero;
safeArea.AddComponent<SafeAreaHandler>();

// 3. All content parents under safeArea
GameObject topBar = createTopBar(safeArea, ...);
GameObject content = createContent(safeArea, ...);
```

**Testing**: Always test on device simulators with notch/Dynamic Island (iPhone 14 Pro, iPhone 16, Pixel 6). The Unity Game view device simulator helps catch clipping issues before building.

## 5. Visual Verification

After every UI change:

1. **Rebuild prefabs**: `MainMenuScreenBuilder.BuildAll()`
2. **Reassign sprites**: `DODSetup.AssignPrefabsMenu()`
3. **Take screenshots**: `PlayModeScreenshot.CaptureAllScreens()`
4. **Check every screenshot** for:
   - White squares (missing sprites)
   - Stretched/distorted elements
   - Text clipping or overflow
   - Misaligned elements
   - Content behind notch/status bar area
   - Empty space from hidden children not triggering layout rebuild
5. **Fix and re-screenshot** — don't assume a code fix worked without visual confirmation
