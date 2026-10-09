# RUN24 — Playtest Vertical Slice 1

Status: candidate build for external player testing.

## Scope
This is the first complete level intended to be tested without developer guidance. It is not the full commercial game; it is the product-quality vertical slice used to validate the core loop, art direction, controls, encounter pacing and boss readability before expanding production.

## Run structure
1. ENTRY — movement, jump, first walker/turret targets.
2. CIRCUIT — sustained ranged combat and flyers.
3. PRESSURE — vertical target prioritization, hazards and drop-through platforms.
4. TRANSIT — mixed traversal under crossfire.
5. CARGADOR — elite charge-pattern skill check.
6. THE IDOL — three-phase boss encounter.

## Player kit
- Run / jump / variable jump cut.
- Dash with invulnerability.
- Mouse or right-stick aim.
- Basic, RAPID and SPREAD weapon states.
- CORE energy charged through combat.
- Five specials: Core Blast, Sky Breaker, Ground Burst, Phase Rush, Nova Pulse.
- Down-through one-way platforms.
- Safe void respawn/checkpoints.

## Presentation
- Signalpunk authored SVG masters for RUNNER 24, XOLO, THE IDOL and CARGADOR.
- Obsidian/bone/cochineal/jade/cempasuchil palette.
- Six-zone Signal District environment with towers, glyph banners, signal falls, cables and monumental red suns.
- Reactive HUD, minimap, boss health, tutorials, start/pause/end screens.
- Muzzle, impact, special, death and boss FX.
- Camera shake and synthesized zero-license SFX.

## Playtest instrumentation
End screen shows time, enemies defeated, hits, damage taken, specials used and pickups collected. A JSON summary is also written to user://last_playtest.json when the run ends.

## Automated validation
`tests/smoke_test.gd` verifies:
- all five combat rooms contain enemies;
- each arena gate unlocks after its room is cleared;
- boss encounter activates;
- THE IDOL becomes active;
- boss death completes the level.

Latest local smoke result: PASS.

## Testing target
Desktop browser with keyboard/mouse or standard controller. Touch/mobile controls are intentionally outside this playtest build.
