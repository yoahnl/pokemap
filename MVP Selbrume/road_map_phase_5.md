# Phase 5 — Gameplay Gaps Prioritaires

## Statut

Phase 5 active.

P5-00 : terminé.
P5-01 : terminé.
P5-02 : terminé.
P5-03 : terminé.
P5-04 : terminé.

Phase 5 reste orientée vers une boucle RPG minimale prouvable, pas vers une
parité Pokémon complète, pas vers Selbrume final, pas vers une UI premium.

Prochain lot exact :

```text
P5-05 — Battle Rewards / Money / XP Minimal Apply V0
```

## Objectif Phase 5

Fermer la boucle RPG minimale nécessaire à une bêta jouable :

```text
projet disque réel
-> runtime host
-> New Game minimal
-> état initial valide
-> starter / party initiale
-> bag / heal minimal
-> combat
-> capture
-> rewards / money / XP minimal
-> save/load gameplay
-> validation de jouabilité bêta
```

## Recadrage P5-00

La roadmap initiale était cohérente dans l'intention, mais trop documentaire
dans plusieurs intitulés :

```text
Contract Review
Read Model
Minimal Contract
Decision
Plan
```

À partir de P5-01, les lots doivent donc produire des preuves concrètes :

```text
tests purs
builders minimaux
opérations gameplay
smokes runtime ciblés
roundtrips save/load
diagnostics bêta
evidence packs
```

Les audits restent autorisés uniquement lorsqu'ils débloquent une décision
nécessaire à une preuve suivante.

## New Game minimal, pas Boot Flow complet

Le New Game Phase 5 doit rester ultra minimal :

```text
créer un GameState initial valide
résoudre une map de départ
résoudre un spawn / une position initiale
initialiser facing
initialiser party / bag / argent / flags / steps selon contrat disponible
permettre un lancement runtime ou un test runtime depuis cet état
```

Le Boot Flow complet est hors scope immédiat Phase 5 :

```text
vidéo d'intro
écran titre
"Appuie sur Start"
écran de slots
Continue / Nouvelle partie complet
cinématique d'ouverture
transitions premium
```

Ces sujets sont reportés à Phase 7 ou à un chantier dédié d'expérience de
lancement, après preuve du New Game minimal.

## Roadmap recalibrée

### P5-00 — Phase 5 Roadmap Recalibration / Gameplay Loop Audit

Statut : terminé.

But :

```text
auditer l'état réel gameplay
critiquer la roadmap initiale
recalibrer Phase 5 vers des preuves jouables
fixer le prochain lot exact
```

Preuve attendue :

```text
rapport P5-00
roadmap Phase 5 recalibrée
aucun code modifié
```

### P5-01 — Runtime Project Disk Smoke / Editor-created Project Proof

Statut : terminé.

But :

```text
prouver qu'un projet créé/sauvé par l'éditeur peut alimenter le runtime host
ou documenter précisément le dernier gap disque/runtime avant New Game.
```

Preuve attendue :

```text
projet technique non-Selbrume
project.json éditeur ou équivalent sauvegardé
loadRuntimeMapBundle
RuntimeMapBundle avec map jouable
runtime host ou PlayableMapGame smoke ciblé
aucun contenu final Selbrume
```

### P5-02 — New Game / Initial GameState Builder V0

Statut : terminé.

But :

```text
durcir le New Game ultra minimal autour du GameState initial.
```

Preuve attendue :

```text
builder pur ou extension du builder existant
résolution map/spawn/facing
initial party/bag/money/flags/steps selon contrat disponible
tests ciblés
aucun Boot Flow complet
```

### P5-03 — Starter / Initial Party Minimal Flow V0

Statut : terminé.

But :

```text
prouver une party initiale ou un starter minimal sans UI premium.
```

Preuve attendue :

```text
opération pure give starter / initial party
validation species / moves / level minimale
roundtrip save/load ciblé
```

### P5-04 — Party / Bag / Heal Minimal Operations V0

Statut : terminé.

But :

```text
fermer les opérations minimales de survie hors combat.
```

Preuve attendue :

```text
party read model minimal si nécessaire
bag operations minimales
medicine outside battle
healParty / heal center operation V0
tests purs
```

### P5-05 — Battle Rewards / Money / XP Minimal Apply V0

Statut : prochain lot exact.

But :

```text
appliquer les conséquences minimales d'un combat gagné.
```

Preuve attendue :

```text
battle write-back maintenu
trainer defeated policy cohérente
reward / money / XP minimal
level-up minimal si supportable
tests ciblés
pas de système complet de moves learned / evolution
```

### P5-06 — Capture Destination Party-or-Box V0

But :

```text
éviter que la capture échoue brutalement quand la party est pleine.
```

Preuve attendue :

```text
destination capture party ou storage minimal
pas de PC UI premium
tests party full / party not full
```

### P5-07 — Gameplay Save/Load Beta Roundtrip V0

But :

```text
prouver que les états gameplay bêta survivent à la persistance.
```

Preuve attendue :

```text
party
bag
money
progression
trainer defeated
capture
rewards / XP si ajoutés
runtime save/load ciblé
```

### P5-08 — Beta Runtime Smoke : New Game -> Battle -> Reward -> Save/Load

But :

```text
prouver une boucle runtime courte depuis New Game minimal.
```

Preuve attendue :

```text
runtime host ou PlayableMapGame smoke
New Game state
battle handoff
reward apply
save/load
aucune UI premium
```

### P5-09 — Beta Playability Validator V0

But :

```text
diagnostiquer si un projet peut être lancé et joué en bêta minimale.
```

Preuve attendue :

```text
start map
spawn
starter / party
bag minimal
encounters
trainers
save/load prerequisites
diagnostics actionnables
```

### P5-10 — Audio Minimal Runtime Proof V0

But :

```text
traiter le gap audio minimal identifié par les audits bêta sans basculer dans
du polish premium.
```

Preuve attendue :

```text
preuve audio runtime minimale
fallback silencieux documenté si assets absents
pas de direction artistique finale
```

### P5-CHECKPOINT-01 — Gameplay Loop Readiness Review

But :

```text
déterminer si Phase 5 a suffisamment prouvé la boucle gameplay minimale pour
passer à la phase suivante.
```

Preuve attendue :

```text
classement des preuves
gaps restants
verdict de clôture
prochain lot exact
```

## Reports explicites

Report Phase 6 ou chantier contenu :

```text
Selbrume final
campagne complète
golden slice narrative finale
contenu final de maps / PNJ / dialogues
```

Report Phase 7 ou chantier UX de lancement :

```text
Boot Flow complet
écran titre
vidéo d'intro
écran de slots
Continue / Nouvelle partie complet
cinématique d'ouverture
UI premium
```

Report post-bêta :

```text
parité Pokémon complète
évolution complète
move learning complet
shops complets
badges complets
PC UI complet
post-game
```
