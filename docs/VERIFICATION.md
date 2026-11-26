# Verification — Mirpur 12 Metro Courier

Godot 4.3 stable, Windows. All commands exited 0.

| Suite | Result |
|---|---|
| `CityTest.tscn` | `[CITY2D] PASS` — 1,500 buildings, **764 real roads**, 150 named roads, 1,098 amenities, 437 shelters |
| `EconomyTest.tscn` | `[ECON] PASS` — 15 jobs, bike upgrades, XP/levels, skills, quests, save/reload |
| `run_all.ps1` | `[JOB] ALL 15 JOBS PASS` — every job built the real city, spawned traffic, completed pickups/deliveries through real interaction hooks, earned quests and finished |

## Design and fix loop

1. Reused the real Mirpur 12 OSM extract and converter from the flood-response project — no invented streets.
2. Changed the concept entirely: from flood rescue to timed courier delivery with traffic, fuel and bike upgrades.
3. Removed all leftover scripts/scenes from the previous game and rewrote autoload, job loop, HUD, menu, tests and visuals.
4. Fixed quest/job target mismatch found by the deep test: delivery quests now require at most the job's own delivery count.
5. Fixed GDScript typing errors found on first import and kept deep tests on real `interact()` hooks rather than counters.

## Visuals

Six real gameplay frames (menu, job, rider, quests, upgrade, summary), the OSM map image and a generated sprite sheet are in `docs/images/`. All were rendered without crashes.

Made by S M Nazmuz Sakib. Map data © OpenStreetMap contributors (ODbL 1.0).
