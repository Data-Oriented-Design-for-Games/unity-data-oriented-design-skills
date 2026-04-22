# unity-data-oriented-design-skills

Claude Code skills for building Unity games using **Data-Oriented Design (DOD)** architecture, based on the Manning book *Data-Oriented Design for Games* by Nitzan Wilnai.

## Included skills

| Skill | Purpose |
|---|---|
| `unity-dod-architecture` | Architecture guide: Balance, GameData, Logic, Board, Game, AssetManager, GameDataIO, MetaDataIO, GUIRef, Singleton. Use when generating DOD-compliant Unity code or reviewing for DOD violations. |
| `unity-development` | Workflow for the [`unity-agent-bridge`](https://github.com/nitzanwilnai/unity-agent-bridge) Unity package: compilation checks, executing static methods in the Editor, building UI prefabs, automated screenshots, and autonomous error fixing. |
| `unity-ui-ux-checklist` | Visual review checklist for Unity UI screens: text sizing, image stretching, layout pitfalls, safe area handling, missing sprites, `ContentSizeFitter` issues. |

## Installation

### Option 1 — Direct git clone

Clone into Claude Code's plugin cache:

```bash
git clone https://github.com/nitzanwilnai/unity-data-oriented-design-skills.git \
  ~/.claude/plugins/cache/local/unity-data-oriented-design-skills/1.0.0
```

Then reference it in `~/.claude/settings.json` (user-level) or `<project>/.claude/settings.json` (project-level):

```json
{
  "plugins": {
    "unity-data-oriented-design-skills@local": {
      "installPath": "~/.claude/plugins/cache/local/unity-data-oriented-design-skills/1.0.0",
      "version": "1.0.0"
    }
  }
}
```

Restart Claude Code — the three skills will appear in the available-skills list.

### Option 2 — Via a marketplace

If a marketplace that references this plugin is added to Claude Code, install with:

```
/plugin install unity-data-oriented-design-skills
```

## Usage

Once installed, the skills activate automatically when their trigger conditions are met — for example, when you're working in a Unity project that uses DOD architecture, or when you ask Claude to review a Unity UI prefab. You can also invoke a skill directly via the `Skill` tool.

## Companion package

The `unity-development` skill uses the [`unity-agent-bridge`](https://github.com/nitzanwilnai/unity-agent-bridge) Unity package. Install that package in your Unity project to enable the bridge-based workflows (compilation checks, static method execution, screenshots).

## License

MIT — see [LICENSE](LICENSE).

## Author

[Nitzan Wilnai](https://github.com/nitzanwilnai) — author of *Data-Oriented Design for Games* (Manning Publications).
