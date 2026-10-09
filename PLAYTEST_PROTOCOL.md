# RUN24 — External Playtest Protocol

Build: SIGNALPUNK Vertical Slice 1
Target session: 6–12 minutes
Platform: Web browser, keyboard/mouse or standard gamepad.

## Tester instruction
Do not explain mechanics before the run beyond: "Play until you win or die. Think aloud if you can."
Let the in-game onboarding teach the controls.

## Observer checklist
Record:
- Did the tester understand movement without help?
- Did they notice mouse/right-stick aiming?
- Did they understand that hitting enemies recharges CORE?
- Which of the five specials did they discover naturally?
- Did they use down-through platforms intentionally?
- Did they understand why arena gates opened?
- First point where they lost health.
- First point where they became stuck or confused.
- Which enemy was hardest to read?
- Did CARGADOR's charge feel telegraphed?
- Did THE IDOL feel fair and learnable?
- Total run time and result from the end screen.

## Questions immediately after the run
1. In one sentence, what do you think RUN24 is about?
2. What visual element do you remember first?
3. Which enemy or boss was most memorable?
4. Which special attack felt best?
5. Was any control difficult to discover?
6. Did you ever feel hit by something you could not understand or see?
7. Where did the level feel slow or repetitive?
8. Where did the difficulty spike too much or too little?
9. Would you immediately play another run? Why or why not?
10. What is the one thing you would change first?

## Do not ask during the run
Avoid teaching the solution, explaining CORE, naming boss phases, or telling the player where pickups are. Intervention invalidates discoverability observations.

## Build metrics
The game records a last-session summary to user://last_playtest.json on finish:
- victory/failure
- time
- shots
- hits
- damage taken
- enemies defeated
- specials used
- pickups collected
- furthest X position

The same high-level metrics are shown on the final screen so web testers can send a screenshot without accessing local files.
