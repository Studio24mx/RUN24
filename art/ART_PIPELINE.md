# RUN24 — Zero-Budget Art & Animation Pipeline

## Goal
Create a distinctive 2D game at zero software cost. Use expensive hand-drawn work only where it creates visible player value.

## Core toolchain

### Godot 4.7.2
Role: integration, animation playback, 2D skeletons, AnimationPlayer/AnimationTree, shaders, particles, camera FX, lighting, parallax and final gameplay.
Why: already the game engine; avoids export/plugin complexity.

### Krita
Role: concept art, paintovers, character sheets, texture masks, FX sheets, hand-drawn animation accents, promotional illustration.
Preferred outputs:
- PNG for painted assets.
- PNG sequences or sprite sheets for frame-by-frame FX.
- KRA kept as source.

### Inkscape
Role: clean silhouette design, symbols/glyphs, UI, logos, modular environment shapes, vector masters.
Preferred outputs:
- SVG as editable master.
- PNG exports where Godot import or performance requires raster.
- Keep strokes simple and convert important display marks to paths before final export.

### Blender (optional, not required for first visual slice)
Role: blockout/perspective reference, 2.5D backgrounds, hard-surface concepts, camera previs, rendered reference.
Use only if a specific asset is faster in 3D than 2D. Do not turn RUN24 into a 3D production pipeline.

## Character production
1. Silhouette exploration in Inkscape or Krita.
2. Lock proportions with front/side/3-quarter turnaround.
3. Separate cutout pieces: head, torso, pelvis, upper/lower arms, hands/weapon, upper/lower legs, feet, optional cloth/accessories.
4. Paint/export parts at 2x target gameplay resolution.
5. Rig in Godot with Bone2D/Skeleton2D when deformation is needed; otherwise animate Node2D transforms for simpler hard-piece characters.
6. AnimationPlayer for locomotion/combat clips.
7. AnimationTree only after the move set is stable.
8. Add hand-drawn smear/impact frames as overlays instead of redrawing full animations.

## Animation budget philosophy
Use three tiers:
- Tier A — hero moments: boss intro, death, transformation, signature special. Hand-drawn accents allowed.
- Tier B — gameplay core: run, jump, land, dash, shoot, hit. Skeletal/cutout with selective frame swaps.
- Tier C — ambient: NPC idle, machinery, signs. Procedural/tween/shader whenever possible.

## Frame-rate language
Do not chase 60 unique drawings per second.
- Character pose changes: often 12–18 fps visual cadence.
- Engine movement remains 60 fps.
- Smears/impacts: 1–3 frames.
- Idle breathing/accessories can use bones/tweens.
This creates a deliberate animated look while keeping scope realistic.

## Environment pipeline
1. Greybox stays authoritative for collision.
2. Build modular art kits per region:
   - floor edge
   - wall segment
   - pillar/support
   - door/gate
   - small prop family
   - large silhouette prop
   - signage/glyph set
3. Separate background into 3 depth planes.
4. Use Godot parallax and fog/particles rather than painting many unique backgrounds.
5. Use a small texture library with masks/noise instead of unique textures for every object.

## Signalpunk visual hierarchy
Gameplay readability order:
1. Player: bone/cyan.
2. Player attacks / useful pickups: cempasuchil/gold.
3. Enemy bodies/attacks: cochineal/magenta-red.
4. Environment collision: low-saturation blue/obsidian.
5. Background lore: low contrast.
6. Spirit/signal anomalies: jade/cyan only when gameplay-safe.

## UI pipeline
Design masters in Inkscape.
Use Godot Control nodes for actual interface rather than exporting the whole HUD as one image.
Export only:
- icons
- decorative frames
- glyphs
- logos
- texture accents
Keep numeric/text data native so localization and resizing remain possible.

## Naming
art/
  source/
    krita/
    inkscape/
    blender/
  exports/
    characters/
    enemies/
    bosses/
    environment/
    fx/
    ui/
  concepts/
  references/

Godot-facing files should use lowercase_snake_case and descriptive names.

## First vertical-slice art targets
Do not reskin the entire level at once.
Create only:
1. RUNNER 24 final exploration sheet.
2. XOLO exploration sheet.
3. One Signal Husk enemy.
4. Rework Neon Idol into THE IDOL.
5. One 1280x720 Signalpunk gameplay environment kit.
6. HUD style pass.
7. Muzzle flash, hit burst, dash trail, special-attack FX.
8. One short boss intro.

If those eight pieces look coherent together, lock the direction and expand.

## Quality gate
Before an asset enters production it must pass:
- recognizable silhouette at gameplay size;
- readable against both dark and mid-value backgrounds;
- palette role is clear;
- animation method is known;
- reusable pieces identified;
- no copyrighted/traced source art;
- no detail that disappears at gameplay zoom;
- export path and source file are both saved.

## What we deliberately do NOT need now
- Adobe Creative Cloud.
- Spine.
- paid texture libraries.
- paid asset packs.
- motion-capture software.
- dedicated commercial sprite packers.
- AI-generated final character art used without a controlled redesign pass.

Concept generation may accelerate exploration, but final production assets should be reconstructed into our own controlled shapes, layers, rigging and source files.
