# unity-data-oriented-design-skills

Claude Code skills for building Unity games using **Data-Oriented Design (DOD)** architecture, based on the Manning book *High Performance Unity Game Development* (*Using data-oriented design*) by Nitzan Wilnai.

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
git clone https://github.com/Data-Oriented-Design-for-Games/unity-data-oriented-design-skills.git \
  ~/.claude/plugins/cache/local/unity-data-oriented-design-skills/1.1.0
```

Then reference it in `~/.claude/settings.json` (user-level) or `<project>/.claude/settings.json` (project-level):

```json
{
  "plugins": {
    "unity-data-oriented-design-skills@local": {
      "installPath": "~/.claude/plugins/cache/local/unity-data-oriented-design-skills/1.1.0",
      "version": "1.1.0"
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

### Per-project install (recommended for users who also build non-Unity games)

If you want these skills to appear only in your Unity projects (and stay out of the skill list for non-Unity projects), use the included script to symlink the skills into a specific project's `.claude/skills/` directory:

```bash
# From the plugin directory:
./install-in-project.sh /path/to/your/unity/project

# Or from inside a Unity project:
/path/to/unity-data-oriented-design-skills/install-in-project.sh
```

The script creates symlinks in `<project>/.claude/skills/` pointing back to this plugin, so the plugin repo remains the single source of truth and pulling updates is just `git pull` inside the plugin.

## Companion package

The `unity-development` skill uses the [`unity-agent-bridge`](https://github.com/nitzanwilnai/unity-agent-bridge) Unity package. Install that package in your Unity project to enable the bridge-based workflows (compilation checks, static method execution, screenshots).

## License

MIT — see [LICENSE](LICENSE).

## Author

[Nitzan Wilnai](https://github.com/nitzanwilnai) — author of *High Performance Unity Game Development* (*Using data-oriented design*, Manning Publications).
