# Project Full Recovery Context

This document contains the complete context for the Flutter/Dart Pokémon-like game editor project, serving as a memory reconstruction after losing previous session context.

## 1. Global Project Presentation

The project is a Flutter/Dart editor designed to allow creation of a modern Pokémon-like game.

Important: This is not just a simple map editor.

The final vision is much more ambitious: creating a sort of modern Pokémon-like RPG Maker that is readable, guided, ergonomic, accessible, and ideally usable by a non-developer with minimal friction.

Product Vision:
- create maps
- organize the world
- manage tilesets, surfaces, terrains, paths
- add NPCs, triggers, spawns, warps, dialogues
- create narrative progression
- create scenes
- connect runtime logic
- do all this with a very clear, visual, and non-technical UX

The long-term objective is really: allowing someone to easily create a complete Pokémon-like game without having to manipulate code or JSON by hand.

So:
- we want to avoid as much as possible raw technical structure entry
- we want guided UX
- we want dropdowns, pickers, menus, lists, explicit buttons
- we want comprehensible product logic
- we want a robust but pleasant system to use

The target audience is not just an experienced developer.
The tool should trend toward something a non-technical person can understand.

Very important implicit requirement: my mother should ideally be able to understand the tool.

## 2. Stack / Technical Context

The project is in Flutter/Dart.

There are several packages/modules, notably:
- map_editor
- map_runtime
- map_core

The editor relies on an already quite advanced architecture with:
- central workspaces
- lateral navigation
- contextual inspector
- narrative logic
- cutscene/scenario runtime
- NPC/pathfinding/scripted movements system

The project already uses clean/modular architecture logic.
You must respect this structure and not do any tinkering that would break responsibility boundaries.

## 3. Editor's Global Product Vision

The final product must clearly separate:
- map editing
- world content editing
- narrative/progression editing
- scene editing

The general idea is:
1. build a world
2. populate this world
3. write the progression
4. stage the events
5. properly connect all this to the runtime

Desired UX philosophy:
- readable
- hierarchical
- guided
- intuitive
- pleasant
- rather visual
- strongly no-code

I want to avoid:
- obscure technical fields
- IDs entered by hand when we can generate them
- ugly system popups
- basic button alerts when we can do better
- screens that look like cold administrative back-office
- screens that require understanding internal engine data

I want to prioritize:
- a warm, clear, structured interface
- well distinct visual categories
- views adapted to their level of responsibility
- consistent product logic
- an experience that helps understand what is being done

## 4. Narrative System: Fundamental Rule

The narrative system relies on 3 strictly separated levels:
1. Global Story
2. Step
3. Cutscene

This separation is central.
It must be visible:
- in the data
- in the architecture
- in the UI
- in the workflows
- in the runtime

If these layers mix, everything becomes confusing.

## 5. Precise Definition of the 3 Levels

### A. GLOBAL STORY

The Global Story represents the game's macro progression.

It answers questions like:
- where is the story?
- which big branch is active?
- which step is unlocked?
- which arc comes next?
- which global outcome unlocks what?
- which general structure does the player follow?

The Global Story must remain macro.

It manages:
- chapters/arcs
- the global order of steps
- macro branching
- convergences
- the global entry point
- global transitions between steps

The Global Story should NOT manage:
- detailed dialogues
- pathfinding
- NPC movements
- camera
- waits
- concrete scene actions
- fine local step logic

Non-negotiable business rule:
there is only ONE global scenario in the game.
Not several global stories.
Not several concurrent global trees.
One single main Global Story.

### B. STEP

The Step is a readable progression unit.
It's a business step of the game.

It answers:
- what must the player accomplish now?
- how does this step become active?
- how is this step validated?
- what outcomes does it expect?
- what outcomes does it emit?
- what cutscenes are linked to it?
- what world changes does it declare?

Examples of steps:
- meet the professor
- choose a starter
- beat the rival
- obtain the badge
- enter route 1
- help an NPC

So the Step manages:
- activation
- validation
- business outcomes
- progression outcomes
- linked cutscenes
- persistent world changes
- local progression logic

The Step should NOT become a disguised cutscene.
It should not directly pilot scene staging details.

### C. CUTSCENE

The Cutscene is the concrete staging.
It's the execution level.

It manages:
- dialogues
- NPC movements
- pathfinding
- camera
- animations
- waits
- player choices
- transitions
- local signals
- outcomes emitted during the scene

The Cutscene can:
- branch
- emit an outcome in the middle
- continue afterwards
- call another sequence
- finish later

So:
- an outcome doesn't automatically imply the end of the cutscene
- an outcome doesn't automatically imply the end of the step
- an outcome doesn't automatically imply global progression

## 6. Recommended Hierarchy

The target hierarchy is:

```
GLOBAL STORY
├─ Step A
│    ├─ Cutscene A1
│    ├─ Cutscene A2
│    └─ validations / conditions / outcomes
│
├─ Step B
│    ├─ Cutscene B1
│    └─ validations / conditions / outcomes
│
└─ Step C
     └─ ...
```

So:
- the Global Story pilots the big branches
- the Step represents a progression unit
- the Cutscene executes the scene

## 7. Exact Responsibilities

Global Story = macro progression
- which step is active
- which global branch is followed
- which chapter/arc comes next
- how big transitions chain

Step = local logic
- what needs to be done
- how the step starts
- how it ends
- what outcomes it expects
- what cutscenes are linked
- what world consequences persist

Cutscene = execution
- play the scene
- make NPCs walk
- launch dialogues
- offer a choice
- emit outcomes
- do a transition
- execute concrete staging

## 8. OUTCOMES

We distinguish several outcome usages.

Local outcomes:
- serve in a step or between nearby cutscenes
- examples:
  - starter.selected.fire
  - professor_intro.accepted
  - rival.arrived
  - player.said_yes

Global/outcome progression:
- serve to advance the general progression
- examples:
  - chapter_1.starter_chosen
  - chapter_1.professor_arc.completed
  - badge_1.obtained

Important:
the UI should not force the user to enter raw technical IDs if we can generate them from human-readable labels + clear scope.

## 9. Reference Concrete Case: Starter Choice

Reference example:

```
GLOBAL STORY
|
v
STEP: choose your starter
|
v
CUTSCENE: starter_selection
|
+--> intro professor
|
+--> choice:
|      - fire
|      - water
|      - plant
|
+--> fire branch
|      - emit local outcome: starter.selected.fire
|      - specific dialogue
|      - specific animation
|
+--> water branch
|      - emit local outcome: starter.selected.water
|      - specific dialogue
|      - specific animation
|
+--> plant branch
|      - emit local outcome: starter.selected.grass
|      - specific dialogue
|      - specific animation
|
+--> common final block
- give the starter
- set flag starter_chosen
- emit global outcome: chapter_1.starter_chosen
- step complete
```

This case should remain a product compass.

## 10. Branches in Global Story

The system must support several macro structures:

A. Exclusive branches
- one route among several

B. Parallel branches
- several arcs advancing in parallel

C. Conditional branches
- a branch opens according to a condition

D. Convergent branches
- several routes come back to the same point

Very important:
convergences are vital to avoid uncontrolled scenario explosion.

## 11. Ideal UX of the 3 Views

View 1 — Global Story
- macro view of the game
- vertical tree
- reading from top to bottom
- clearly visible chapters
- steps visible as compact units
- readable transitions
- structure more "narrative plan" than "form"

View 2 — Step
- local logic view
- activation
- validation
- expected outcomes
- emitted outcomes
- linked cutscenes
- world/persistence changes
- here we accept detailed form logic, but still guided

View 3 — Cutscene
- execution view
- more "Scratch-like"
- more visual
- more sequential
- more playful
- concrete blocks
- dropdowns and pickers
- avoid raw technical IDs

## 12. Pathfinding Role

Pathfinding must live in the Cutscene.
Not in the Global Story.
Not in the macro logic.

Example:
```
CUTSCENE
├─ Move NPC(professor) to target
├─ Face player
├─ Dialogue
└─ Continue
```

So:
- pathfinding
- automatic movements
- timing
- camera
- player blocking
All of this belongs to the Cutscene level.

## 13. Historical Progress of Narrative Project

### A. CUTSCENE STUDIO

The Cutscene Studio has evolved a lot.

Initially there was too much technical logic:
- scriptId
- outcomeId
- manual entries
- not enough guidance

Then a refactoring introduced much more no-code logic with business blocks, for example:
- dialogue
- narration
- moveCharacter
- followCharacter
- faceCharacter
- transitionMap
- starterChoice
- wait
- sceneResult
- runScript in advanced mode/compatibility
- legacy technical blocks still present but not prioritized

The objective was to leave a too-technical system for something more guided and more human.

The runtime was also extended to support:
- continuation after dialogue
- moveCharacter
- followCharacter
- faceCharacter
- transitionMap
- more advanced scene management

### B. STEP STUDIO

The Step Studio was added to manage local logic.

It manages:
- identity of the step
- activation
- validation
- linked cutscenes
- progression results
- world/persistence

Very important product point already discussed:
persistent presence of entities according to progression.

Example:
- Emma is outside before a scene
- we go together into a building
- at the end, Emma should be considered now present in the building
- so we want a persistence logic linked to the step/progression
- this logic should be declarative, readable, and driven from the Step Studio
- it should eventually integrate properly with world entities

MAJOR BUG ALREADY ENCOUNTERED IN STEP STUDIO
There was a very serious bug:
- infinite loop in build()
- for without index++
- complete freeze
- RAM going up to 183 GB
- macOS colored wheel

The fix was to replace these loops with safe iterations via .asMap().entries.

This point must be memorized in the context file.

### C. GLOBAL STORY STUDIO

The Global Story Studio was initially implemented in a way too close to the Step Studio.
It looked too much like a big step form.
There was real confusion between:
- macro structure
- local logic

Then a UX refactoring was done to improve this.
Chapters were introduced.
Reading became more vertical and more structured.

There is now a concept of macro authoring document with chapters, for example around:
- GlobalStoryStudioDocument
- GlobalStoryChapter

The idea was to make Global Story a more narrative, hierarchical view, closer to a tree.

## 14. Current State of Global Story Studio

The current state is better than before.
Visually, we now have something more readable:
- a global header
- a single global scenario
- summary badges
- visible chapters
- compact steps
- more top-down reading

This is already much better.

But there remains a fundamental product requirement:
the Global Story should never look like a Step Studio duplicate.

It should remain a macro view:
- chapters
- ordering
- structure
- branches
- convergences
- reading of the narrative plan

Not a detailed step form.

## 15. Recent UX Problem: The "Insert" Button

In the current Global Story Studio UI, there is an "Insert" button at the step level.

Observed problem:
- when clicking it, we expect an explicit structural action
- ideally a choice of type:
  - create a new step
  - insert an existing step
  - or at least a clear picker/dropdown/menu

But currently the observed behavior is:
- click
- it directly adds a new tile/a new step
- without sufficient clarification
- this is not what I want

So:
- the action is ambiguous
- the label is not aligned with the behavior
- the UX must be clarified

Desired product direction:
either
A. "Insert" opens an explicit choice:
- New step
- Existing step
or
B. two separate actions:
- New step
- Insert existing step

Clarity must be prioritized.

## 16. What I Want From You Now

I want you to consider this message as complete project memory to save.

Then I want you to:
1. save this context in a proper and structured markdown
2. produce a second analysis report dedicated to the current state of Global Story Studio
3. analyze the current code
4. check the real logic of the "Insert" button
5. precisely identify:
   - which methods are called
   - if a new step is implicitly created
   - if a mechanism for inserting existing steps already exists
   - if there is a gap between wording and behavior
6. propose the best product + UX + logic correction

I want you to reason in terms of:
- product
- architecture
- readability
- no-code UX
- consistency between the 3 levels

## 17. Current Product Priorities

Priority 1
Strictly preserve the separation:
- Global Story = macro structure
- Step = local logic
- Cutscene = execution

Priority 2
Maintain no-code and readable UX.

Priority 3
Make Global Story a real top-down reading:
- chapters
- steps
- flow
- branches
- convergences

Priority 4
Remove all ambiguity about structural actions, especially "Insert".

Priority 5
Continue documenting the project to avoid future context losses.

## 18. Expected Deliverables

I want the following deliverables:
1. A very complete markdown context backup file
2. A markdown analysis report of the current Global Story Studio
3. A precise analysis of the "Insert" button
4. A clear, consistent, simple, no-code correction proposal
5. Then only, eventually implementation

## 19. Final Instruction

Don't treat this message as a disposable prompt.
Treat it as a project memory reconstruction to preserve in the repository.
I want you to save it, structure it, and use it as a stable reference base for the rest.