# Phase 10 — Playable Game Validation — Completion Evidence Pack

Date: 2026-07-21

Périmètre: `FG-180` à `FG-185`

Verdict technique: **PASS**

Verdict release MVP: **PARTIAL / NO-GO — approbation utilisateur requise**

## Résumé exécutif

La phase 10 livre maintenant le rapport de readiness fail-closed, une fixture
Golden Slice versionnée, son parcours E2E, une matrice de régression, un
dashboard read-only et la gate de release. Les six packages passent leurs
suites et analyses, les smokes ciblés passent, le seed Selbrume est à jour et
les deux applications macOS de debug se construisent.

La gate n'annonce pas encore `GO`: quatre critères sur cinq sont prouvés. Le
dernier critère exige que l'utilisateur accepte explicitement le périmètre MVP
et les capacités reportées en Phase 11.

## Audit initial

- Branche: `main`.
- HEAD au début de FG-180: `65cae2520`.
- HEAD au début de FG-185: `b0ad00990`.
- Worktree propre à l'ouverture de chaque lot.
- Roadmap canonique inspectée:
  `pokemap_roadmap_mecaniques_fangame.md`, Phase 10.
- Règles de rapport inspectées: `codex_rule.md`.
- Frontières respectées: modèles/outillage purs dans `map_core`, logique
  gameplay pure dans `map_gameplay`, fixture et parcours dans le host.

## État des lots

| Lot | Livrable | Preuve | Proposition |
|---|---|---|---:|
| FG-180 | Project Gameplay Readiness Report V0 | 11 checks, rapports créateur/agent, tests `+5` | DONE |
| FG-181 | Golden Slice Fangame Fixture V0 | 3 maps, données minimales, walkthrough 13 étapes | DONE |
| FG-182 | Golden Slice End-to-End Smoke V0 | parcours production de New Game à fin + save/reload | DONE |
| FG-183 | Regression Matrix V0 | matrice rapide, complète, smokes et builds | DONE |
| FG-184 | Roadmap Status Dashboard Generator V0 | parseur pur + CLI read-only + tests `+5` | DONE |
| FG-185 | MVP Release Gate V0 | 4/5 critères passés, approbation scope non vérifiée | PARTIAL |

## Commits par lot

| Lot | Commit |
|---|---|
| FG-180 | `739e0ab73 feat(core): add gameplay readiness report` |
| FG-181 | `dc0e6cb52 test(host): add golden fangame slice fixture` |
| FG-182 | `c06c49db8 test(gameplay): prove golden fangame journey` |
| FG-183 | `05a6f9faa docs(gameplay): add phase 10 regression matrix` |
| FG-184 | `b0ad00990 feat(core): add gameplay roadmap dashboard` |
| FG-185 | commit créé après validation de ce rapport |

## Matrice de décision FG-185

| Critère | Statut | Preuve fraîche |
|---|---:|---|
| Golden Slice passe | PASSED | fixture `+1`, E2E/launch ciblés `+3`, host complet `+91` |
| Project Gameplay Readiness sans error | PASSED | FG-180 healthy fixture et 11 preuves passées |
| Tests package critiques verts | PASSED | six suites complètes et six analyses propres |
| Limitations post-MVP listées | PASSED | Phase 11 de la roadmap et cutoff ci-dessous |
| Utilisateur valide le périmètre | UNVERIFIED | aucune approbation explicite du cutoff dans ce lot |

Décision agrégée: **NO-GO**, avec un seul blocker
`userScopeApproved/unverified`.

## Cutoff MVP proposé à l'approbation

Le MVP validé couvre la création et l'exécution d'une mini-aventure solo avec:

- New Game et choix du starter;
- équipe, PC/boxes et destination de capture;
- rencontres sauvages, capture et combats de dresseur simples;
- XP, level-up, apprentissage/évolution couverts par les contrats existants;
- sac, objets, shop, soin, argent, récompenses et badges/flags;
- Surf/Cut et déblocages de terrain;
- événements, scènes, dialogues et conséquences narratives;
- menus runtime, sauvegarde/rechargement et fin d'histoire;
- validations auteur, Golden Slice et matrice de non-régression.

Sont explicitement post-MVP: doubles, Mega/Tera/Z/Dynamax, breeding/daycare,
online, concours/minijeux, Battle Frontier, UX IV/EV/natures avancée et parité
Pokédex moderne complète. Le polish visuel exhaustif, un playtest humain long
et un packaging multiplateforme signé ne sont pas revendiqués par cette gate.

## Fichiers FG-185 modifiés

| Fichier | Zone | Impact |
|---|---|---|
| `packages/map_core/test/mvp_release_gate_test.dart` | scénario Phase 10 réel | prouve le NO-GO avec quatre critères passés et l'approbation non vérifiée |
| `examples/playable_runtime_host/test/selbrume_player_journey_e2e_test.dart` | approche PNJ et rencontre incidente | stabilise le smoke quand le dernier pas déclenche un combat sauvage |
| `reports/gameplay/fg_185_mvp_release_gate_v0.md` | réaudit complet | remplace les preuves obsolètes de 2026-07-18 |
| `reports/gameplay/fg_180_185_phase_10_playable_game_validation_completion.md` | nouvel Evidence Pack | synthétise toute la phase 10 |

## TDD et diagnostic

Le test de gate réel a été ajouté comme non-régression du contrat fail-closed.
La première suite host complète a ensuite découvert un rouge réel:

```text
01:47 +90 -1: Some tests failed.
selbrume_player_journey_e2e_test.dart:
player completes Selbrume through PlayableMapGame production hooks
Expected: true
Actual: false
```

Diagnostic: le dernier pas d'approche du PNJ Mado, situé hors de
`navigateTo`, avait déclenché une rencontre sauvage; l'interaction primaire
était envoyée pendant la transition de combat. Le helper de test résout
désormais cette rencontre incidente avant l'interaction. Aucun code runtime de
production n'a changé.

Preuve après correction:

```text
flutter test --no-pub test/selbrume_player_journey_e2e_test.dart
=> 03:19 +5: All tests passed!

flutter test --no-pub
=> 03:13 +91: All tests passed!
```

## Validation complète fraîche

| Package | Tests | Analyse |
|---|---|---|
| `map_core` | `01:55 +4334: All tests passed!` | `No issues found!` |
| `map_gameplay` | `00:04 +303: All tests passed!` | `No issues found!` |
| `map_battle` | `00:22 +1722: All tests passed!` | `No issues found!` |
| `map_runtime` | `01:49 +1917 ~1: All tests passed!` | `No issues found! (ran in 4.0s)` |
| `map_editor` | `04:43 +4096: All tests passed!` | `No issues found! (ran in 6.0s)` |
| `playable_runtime_host` | `03:13 +91: All tests passed!` | `No issues found! (ran in 4.6s)` |

Le `~1` de `map_runtime` est un test ignoré déclaré, pas un échec.

## Smokes et validations ciblées

```text
map_core FG-180/184/185 ciblés: +17, All tests passed!
map_runtime Phase A battle smoke: +3, All tests passed!
host Golden fixture/E2E/launch: +3, All tests passed!
host Selbrume journey complet: +5, All tests passed!
Selbrume canonical narrative content is up to date.
```

## Builds

```text
cd packages/map_editor && flutter build macos --debug
=> Built build/macos/Build/Products/Debug/map_editor.app

cd examples/playable_runtime_host && flutter build macos --debug
=> Built build/macos/Build/Products/Debug/playable_runtime_host.app
```

## Passes nommées

| Passe | Verdict |
|---|---|
| Audit / Architecture | PASS — frontières et DoD FG-180–185 respectés |
| Implémentation | PASS — six livrables présents, pas d'écriture automatique de roadmap |
| Tests | PASS — suites ciblées et exhaustives vertes après correction du smoke |
| Build / Validation | PASS — analyses, seed check et deux builds macOS verts |
| Critique finale | PASS technique — aucun faux GO; approbation produit encore absente |

## Limites et risques

- La gate agrège des preuves documentées; elle ne signe pas leur fraîcheur en
  CI.
- Le dashboard lit du Markdown et dépend donc de la stabilité minimale du
  tableau et de la ligne `Proposed status:`.
- La Golden Slice automatise les contrats du parcours, pas un playtest humain
  exhaustif ni la qualité artistique finale.
- Les builds prouvent macOS debug local, pas notarisation ni distribution
  Windows/Linux.
- La roadmap canonique n'est pas modifiée par cette exécution; les Evidence
  Packs proposent les statuts.

## Auto-critique finale

La validation a volontairement refusé de transformer « tous les tests sont
verts » en `GO` produit. Cette prudence laisse un état `PARTIAL` alors que tout
le travail technique est terminé, mais elle respecte le DoD: le cutoff est une
décision utilisateur. La nondétermination révélée par la première suite host a
été corrigée dans le test qui la subissait, sans affaiblir le runtime ni
désactiver les rencontres.

## État git avant le commit FG-185

Attendu: les deux tests ci-dessus et les deux Evidence Packs, sans changement
généré par les builds. `git diff --check` et un dernier statut sont exécutés
avant commit.
