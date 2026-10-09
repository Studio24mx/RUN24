# RUN24 — Final Prototype / Level 1

Build: SIGNALPUNK Final Prototype 1
Target run: 12–20 minutes
Internal resolution: 1280x720
Toolchain: Godot 4.7.2 + Krita + Inkscape. 100% free/open-source.

## Purpose
This is the final Level 1 prototype intended for external player testing before expanding RUN24 into the full game. It is deliberately one long authored run rather than a collection of disconnected test rooms.

## Level structure
1. ENTRY — movement, aiming and first Signal Husk/Vigilante encounters.
2. CIRCUIT — sustained ranged combat and aerial Centinelas.
3. CATHEDRAL — vertical target prioritization and stronger arena composition.
4. FLOODWAY — moving signal relays, hazards and crossfire.
5. TRANSIT — alternating elevation and movement pressure.
6. HOLLOW MARKET — denser mixed combat.
7. CARGADOR — first elite charge-pattern arena.
8. BLACK SIGNAL — Cargador plus moving relay combat.
9. ASCENSION — final gauntlet and CORE spending before the boss.
10. THE IDOL — three-phase final boss.

Approximate level length: 16,000 world pixels.

## Authored visual production
- RUNNER 24: separate authored body and weapon SVGs. Body animation is transform/cutout based; weapon independently aims toward mouse/right stick and recoils.
- XOLO: authored SVG with spring follow, run/bob animation, lean and spirit trail FX.
- Signal Husk: authored SVG with locomotion bob and facing.
- Vigilante: authored SVG with idle motion and weapon recoil.
- Centinela: authored SVG with hover/flap deformation and flight lean.
- Cargador: authored SVG with charge squash/stretch, lean and telegraph.
- THE IDOL: authored SVG body with procedural halo, signal arms, phase pulse and intro animation.
- Environment: authored Signal Arch and Relay Shrine SVG modules plus procedural Signalpunk architecture.
- Platform surfaces use reusable seams, ribs and signal inlays rather than plain greybox rectangles.
- Animated signal falls, rotating markers, swaying banners, cables and checkpoint beacons.
- Multiple monumental cochineal signal suns establish depth and landmarks.

## Animation / FX
Hybrid animation approach:
- Cutout/transform animation for gameplay characters.
- Authored vector masters for silhouettes.
- Procedural muzzle flashes, impacts, death bursts, CORE pulses and special FX.
- Camera shake on shoot, dash, damage and specials.
- Moving platforms use physics-synced AnimatableBody2D relays.
- Hazards visibly pulse.
- Boss has a short entrance animation and phase-responsive visual motion.

## Audio
All audio is generated in-project with zero external licensing:
- shoot, hit, kill, hurt, jump, dash, pickup, special, gates, boss, victory, death;
- procedural ambient Signalpunk loop;
- more intense procedural boss loop.

## Gameplay
- Run, variable jump, dash/invulnerability.
- Mouse/right-stick aiming.
- BASIC, RAPID and SPREAD weapon states.
- CORE generated through combat.
- Five specials: Core Blast, Sky Breaker, Ground Burst, Phase Rush and Nova Pulse.
- Down-through platforms.
- Safe void respawn and four explicit progression checkpoints.
- Geometry blocks both player and enemy projectiles.
- Player projectiles cannot damage enemies outside the current camera view.

## UI
- Ten-zone minimap.
- Drawn LIFE and CORE icons so Web does not depend on missing Unicode glyphs.
- Weapon, room and boss states.
- Progressive tutorial toasts.
- Start, pause, death and victory states.
- End-screen playtest metrics.

## Automated validation
tests/smoke_test.gd validates:
- 9 combat rooms are registered;
- each room contains enemies;
- all 9 progression gates unlock after a clear;
- THE IDOL encounter activates;
- boss death finishes the level.

Latest local result: SMOKE_RESULT: PASS.

## Scope boundary
This is the final external-playtest prototype, not the final commercial game. Expansion to additional levels, procedural roguelite structure, final music composition, localization and production-scale content happens only after real player feedback validates this slice.
