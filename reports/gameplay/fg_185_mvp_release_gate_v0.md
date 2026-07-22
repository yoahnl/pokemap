# FG-185 — MVP Release Gate V0

Date: 2026-07-22

Proposed status: **DONE**

Verdict technique: **PASS**

Verdict global: **DONE / GO**

## Résumé exécutif

FG-185 est clôturé. La Golden Slice passe, le rapport FG-180 ne contient
aucune erreur sur sa fixture saine, les six packages critiques sont verts, les
limitations post-MVP sont documentées et l'utilisateur a explicitement validé
le cutoff. `MvpReleaseGateReport` reçoit donc cinq preuves `passed`, retourne
`isGo == true` et n'expose aucun blocker.

## Confirmation du scope

Le GO couvre le MVP solo documenté: New Game/starter, party et PC,
rencontres/capture, combats singles, progression, sac/shop/soin,
argent/récompenses/badges, field unlocks, événements/dialogues, menus runtime,
sauvegarde/rechargement, fin d'histoire, authoring no-code, readiness et Golden
Slice automatisée.

Restent post-MVP: doubles, Mega/Tera/Z/Dynamax, daycare/breeding, online,
concours/minijeux, Battle Frontier, UX avancée IV/EV/natures et parité Pokédex
moderne complète. Le GO ne revendique ni polish artistique exhaustif, ni
playtest humain longue durée, ni packaging multiplateforme signé.

## Audit initial de clôture

| Élément | État observé |
|---|---|
| Branche | `main` |
| HEAD initial | `c1bc49b21` |
| Worktree initial | propre |
| Gate technique | livrée et fail-closed |
| Verdict avant approbation | `PARTIAL / NO-GO`, 4 preuves sur 5 |
| Élément manquant | décision produit `userScopeApproved` |

Sources relues: `AGENTS.md`, `codex_rule.md`, la Phase 10 de
`pokemap_roadmap_mecaniques_fangame.md`, les Evidence Packs FG-180 à FG-184,
le contrat `mvp_release_gate.dart` et sa suite de tests.

## Approval record

Le 2026-07-22, après présentation explicite du périmètre MVP et des exclusions
post-MVP, l'utilisateur a répondu : « Bah oui c'est bon ».

Cette réponse est enregistrée comme preuve du critère
`MvpReleaseGateCriterion.userScopeApproved` avec le statut `passed`. Elle ne
modifie pas les exclusions; elle les accepte comme cutoff de cette release.

## Matrice de décision finale

| Critère FG-185 | Statut | Source |
|---|---:|---|
| Golden Slice passe | PASSED | FG-181/182; host complet `+91` |
| Project Gameplay Readiness sans error | PASSED | FG-180; onze checks prouvés |
| Tests package critiques verts | PASSED | FG-183 et matrice exhaustive du 2026-07-21 |
| Limitations post-MVP listées | PASSED | Phase 11 et completion Evidence Pack |
| Utilisateur valide le périmètre | PASSED | Approval record ci-dessus, 2026-07-22 |

Décision agrégée: **GO**, cinq preuves passées, zéro blocker.

## Fichiers et zones modifiées

| Fichier | Zone | Raison | Impact |
|---|---|---|---|
| `packages/map_core/test/mvp_release_gate_test.dart` | scénario Phase 10 | remplacer l'approbation `unverified` par une preuve sourcée `passed` | prouve `isGo == true` et `blockers.isEmpty` |
| `pokemap_roadmap_mecaniques_fangame.md` | tableau, DoD et état FG-180–185 | refléter les preuves finales | six lots `DONE`, cases DoD cochées |
| `reports/gameplay/fg_185_mvp_release_gate_v0.md` | verdict et approval record | clôturer la gate | Evidence Pack GO traçable |
| `reports/gameplay/fg_180_185_phase_10_playable_game_validation_completion.md` | synthèse Phase 10 | passer de 4/5 à 5/5 | bilan global DONE / GO |

## Diffs précis

`packages/map_core/test/mvp_release_gate_test.dart`:

```diff
-status: MvpReleaseGateEvidenceStatus.unverified,
-expect(report.isGo, isFalse);
-expect(report.blockers, hasLength(1));
+status: MvpReleaseGateEvidenceStatus.passed,
+source: 'reports/gameplay/fg_185_mvp_release_gate_v0.md#approval-record',
+expect(report.isGo, isTrue);
+expect(report.blockers, isEmpty);
```

`pokemap_roadmap_mecaniques_fangame.md`:

```diff
-| FG-185 | MVP Release Gate V0 | `🟨 PARTIAL` | ... NO-GO |
+| FG-185 | MVP Release Gate V0 | `✅ DONE` | ... cinq preuves passées, GO |
```

Les cinq autres lignes Phase 10 passent également de leur statut historique
`TODO` à `DONE`, avec leurs Evidence Packs respectifs, et tous les critères du
DoD Phase 10 sont cochés.

## Vérifications de clôture

Les suites exhaustives et builds restent ceux exécutés immédiatement avant
l'approbation et documentés dans l'annexe. Cette clôture documentaire modifie
uniquement le scénario de gate, la roadmap et les rapports. Les vérifications
ciblées suivantes sont relancées après modification:

```text
cd packages/map_core
dart test test/mvp_release_gate_test.dart \
  test/project_gameplay_readiness_test.dart \
  test/gameplay_roadmap_dashboard_test.dart

dart analyze

dart run tool/generate_gameplay_roadmap_dashboard.dart \
  /Users/karim/Project/pokemonProject

git diff --check
```

Résultats frais:

```text
Tests ciblés FG-180/184/185: +17, All tests passed!
dart analyze: No issues found!
Dashboard: DONE 7 · PARTIAL 0 · TODO 94
FG-180 à FG-185: DONE
git diff --check: exit 0, aucune erreur
```

## Passes obligatoires

| Passe nommée | Verdict |
|---|---|
| Audit / Architecture | PASS — le changement reste dans la gate et la documentation |
| Implémentation | PASS — preuve produit sourcée, aucun assouplissement du contrat |
| Tests | PASS — `+17`, gate GO et dashboard FG-180–185 DONE |
| Build / Validation | PASS historique frais — six suites, analyses et deux builds verts |
| Critique finale | PASS — le GO n'est produit qu'après approbation explicite |

## Limites et risques conservés

- La gate agrège des Evidence Packs; elle ne signe pas leur fraîcheur en CI.
- La Golden Slice automatise les contrats, pas un playtest humain exhaustif.
- Les builds prouvent macOS debug local, pas les packages de distribution.
- Les capacités Phase 11 restent volontairement hors du MVP.

## Auto-critique

Le passage à GO repose sur une décision humaine correctement isolée des preuves
techniques. Le test n'encode pas une approbation implicite: sa source pointe
vers cet approval record. Le rapport conserve les exclusions afin qu'un GO ne
soit pas interprété comme une promesse de parité Pokémon exhaustive.

## État git final avant commit

Avant commit, le worktree contient uniquement les quatre fichiers listés plus
haut. `git diff --check` est propre et aucune sortie générée n'est présente.

## Annexe A — contenu complet du fichier créé pendant FG-185

Le completion Evidence Pack créé lors de la gate technique est reproduit dans
son état final ci-dessous.

````markdown
# Phase 10 — Playable Game Validation — Completion Evidence Pack

Date: 2026-07-22

Périmètre: `FG-180` à `FG-185`

Verdict technique: **PASS**

Verdict release MVP: **DONE / GO**

## Résumé exécutif

La phase 10 livre maintenant le rapport de readiness fail-closed, une fixture
Golden Slice versionnée, son parcours E2E, une matrice de régression, un
dashboard read-only et la gate de release. Les six packages passent leurs
suites et analyses, les smokes ciblés passent, le seed Selbrume est à jour et
les deux applications macOS de debug se construisent.

La gate annonce désormais `GO`: les cinq critères sont prouvés. Le 2026-07-22,
l'utilisateur a explicitement accepté le périmètre MVP et les capacités
reportées en Phase 11.

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
| FG-185 | MVP Release Gate V0 | 5/5 critères passés, périmètre explicitement approuvé | DONE |

## Commits par lot

| Lot | Commit |
|---|---|
| FG-180 | `739e0ab73 feat(core): add gameplay readiness report` |
| FG-181 | `dc0e6cb52 test(host): add golden fangame slice fixture` |
| FG-182 | `c06c49db8 test(gameplay): prove golden fangame journey` |
| FG-183 | `05a6f9faa docs(gameplay): add phase 10 regression matrix` |
| FG-184 | `b0ad00990 feat(core): add gameplay roadmap dashboard` |
| FG-185 | `c1bc49b21` pour la gate technique, puis commit de clôture produit courant |

## Matrice de décision FG-185

| Critère | Statut | Preuve fraîche |
|---|---:|---|
| Golden Slice passe | PASSED | fixture `+1`, E2E/launch ciblés `+3`, host complet `+91` |
| Project Gameplay Readiness sans error | PASSED | FG-180 healthy fixture et 11 preuves passées |
| Tests package critiques verts | PASSED | six suites complètes et six analyses propres |
| Limitations post-MVP listées | PASSED | Phase 11 de la roadmap et cutoff ci-dessous |
| Utilisateur valide le périmètre | PASSED | approbation explicite « Bah oui c'est bon » du 2026-07-22 |

Décision agrégée: **GO**, sans blocker.

## Approval record

Le 2026-07-22, après présentation explicite du cutoff et des exclusions
post-MVP, l'utilisateur a répondu : « Bah oui c'est bon ». Cette réponse est
la source produit du critère `userScopeApproved/passed`.

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
| `packages/map_core/test/mvp_release_gate_test.dart` | scénario Phase 10 réel | prouve le GO avec les cinq critères passés |
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
| Critique finale | PASS — cinq preuves sourcées, aucun blocker restant |

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

La validation a conservé le `NO-GO` tant que l'approbation produit manquait,
puis l'a promu à `GO` seulement après la réponse explicite de l'utilisateur.
La nondétermination révélée par la première suite host reste corrigée dans le
test qui la subissait, sans affaiblir le runtime ni désactiver les rencontres.

## État git avant le commit FG-185

Attendu: le test de gate, la roadmap et les deux Evidence Packs, sans
changement généré. `git diff --check` et les vérifications ciblées sont
exécutés avant commit.
````
