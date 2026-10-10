# RUN24 — RUNNER 24 Production Sheet v1

## Goal
Turn the approved concept-board version of RUNNER 24 into a production-ready 2D character for the Art Vertical Slice. The gameplay prototype is frozen; this sheet defines the visual asset that will replace the placeholder character in one showcase room.

## Locked visual identity
- Signalpunk run-and-gun protagonist.
- Compact humanoid proportions; oversized graphic head/mask for readability.
- Bone/ivory mask with one dominant cyan/jade luminous visor/eye.
- Obsidian body/armor, cochineal scarf, jade CORE in chest, cempasuchil energy accents.
- Heavy compact signal weapon.
- Silhouette must remain readable at ~120–145 px game height.
- Visual target is the approved concept board, not the current in-engine SVG approximation.

## Master resolution
- Character master: 1400 px high neutral pose minimum.
- Working color profile: sRGB.
- Transparent background.
- Keep clean paint layers and preserve editable source in Krita (.kra).

## Required turnaround
- Side gameplay view facing right — primary.
- Side gameplay view facing left only as validation; runtime may mirror where appropriate.
- 3/4 front reference.
- Back/3/4 rear reference for scarf, armor and CORE construction.

## Rig separation
Create visually complete overlapping pieces with hidden paint under joints:
- head_mask
- neck
- torso
- chest_core
- pelvis
- upper_arm_front
- forearm_front
- hand_front
- upper_arm_back
- forearm_back
- hand_back
- thigh_front
- shin_front
- foot_front
- thigh_back
- shin_back
- foot_back
- scarf_base
- scarf_tail_A
- scarf_tail_B
- weapon_body
- weapon_core
- muzzle
- optional shoulder/armor overlays

## First animation set
1. IDLE: 8–12 key poses / hybrid interpolation.
2. RUN: 8 key poses, aggressive forward lean.
3. JUMP_START: 3–4 poses.
4. AIR_UP: 1 hero pose + rig motion.
5. FALL: 1 hero pose + rig motion.
6. LAND: 3–4 poses with strong squash.
7. AIM/SHOOT: upper-body/weapon independent from locomotion.
8. DASH: dedicated extreme pose + smear/afterimage support.
9. HURT: 2–3 poses.

## Gameplay integration constraints
- Keep existing CharacterBody2D collision and movement values unchanged.
- Visual rig must fit inside the current 42x56 collision body during neutral locomotion.
- Weapon must rotate independently around a shoulder/hand pivot.
- CORE is a separate animated element.
- Scarf is a separate secondary-motion chain.
- Muzzle position exported/defined separately for projectile spawn.

## Current production state
- `runner24_master.kra` exists and opens/exports successfully in Krita.
- `runner24_master.ora` is retained as an interoperable layered source.
- 12 separated layers are preserved under `art/source/krita/runner24/layers/`.
- Cropped runtime pieces live under `art/game/characters/runner24/runtime/`.
- `runner24_rig.tscn` is integrated into the existing Player scene.
- The cutout rig currently drives idle, run, jump/fall, dash, aim/shoot, recoil, CORE pulse, scarf secondary motion, hurt and landing feedback.
- Mechanical smoke test passes with the new rig.
- Visual QA status: production blockout accepted; final paint/material pass is still required before art approval.

## Export targets
- art/source/krita/runner24/runner24_master.kra
- art/source/krita/runner24/runner24_master.ora
- art/source/krita/runner24/layers/*.png
- art/game/characters/runner24/runtime/*.png
- scenes/player/runner24_rig.tscn
- scripts/player/runner24_rig.gd

## Acceptance test
The asset is approved only when:
1. A still frame beside the approved concept reads as the same character.
2. At gameplay scale the mask, visor, scarf and CORE are instantly distinguishable.
3. Run/jump/shoot silhouettes remain clear against dark Signalpunk backgrounds.
4. The character can aim independently without breaking torso anatomy.
5. The art remains consistent when shown at 1x browser scale.
