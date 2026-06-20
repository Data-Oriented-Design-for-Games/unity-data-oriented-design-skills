# Changelog

All notable changes to this plugin will be documented in this file.

## [1.1.0] - 2026-06-19

### Changed
- Updated `unity-dod-architecture` to track the book's MEAP v12 edition. The book was
  retitled *Data-Oriented Design for Games* → *High Performance Unity Game Development*
  (*Using data-oriented design*) and reorganized into three parts. Updated the title,
  MEAP version, and chapter map throughout (SKILL.md, references, README, plugin manifest).

### Added
- `unity-dod-architecture` coverage of new/expanded chapters:
  - **Ch 10 "DOD and Dictionaries"** — avoiding runtime dictionaries (~10x slower than
    arrays), assigning indices/IDs at tool time, multiple enemy types via `EnemySO`,
    add-only dynamic object pools, and load-time-only dictionaries for backwards
    compatibility. New patterns section "Indices Instead of Dictionaries".
  - **Ch 11 "Branching, performance, and extendibility"** — branch prediction, branchless
    techniques, separating data to remove per-item checks, and the cost of Unity null
    checks (check once / own the lifetime / zero tolerance).
  - **Ch 12 "Unity DOTS"** — Burst/SIMD, the Jobs system, ECS terminology, and
    TransformAccessArray, framed as incremental optimizations on top of DOD.
- New anti-patterns: runtime dictionaries, resizing/freeing pools at runtime, saving raw
  indices, per-item status checks, repeated Unity null checks, and reaching for ECS by default.

## [1.0.0] - 2026-04-22

### Added
- Initial release with three skills:
  - `unity-dod-architecture` — Data-Oriented Design architecture guide from the Manning book
  - `unity-development` — Workflow for the `unity-agent-bridge` Unity package (compilation checks, static method execution, screenshots, etc.)
  - `unity-ui-ux-checklist` — Visual review checklist for Unity UI screens and prefabs
