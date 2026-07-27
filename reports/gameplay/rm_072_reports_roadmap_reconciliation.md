# RM-072 — Reports & Roadmap Reconciliation

Date : 2026-07-27  
Liens canoniques : `FG-001`, `FG-184`  
Proposed status: **DONE**

## Résumé exécutif

La roadmap et les rapports autoritaires reflètent désormais les receipts
Phase 7A réellement obtenus :

- `RM-069` : 19/19 critères depuis le package installé ;
- `RM-070` : 20/20 commandes de régression ;
- `RM-071` : build release macOS vert, distribution/device QA partielle ;
- `FG-185` : toujours `PARTIAL / NO-GO`.

Le dashboard a été régénéré en mode `--check` et enregistré sans modification :

```text
DONE: 40 · PARTIAL: 12 · BLOCKED: 0 · TODO: 41 · DEFERRED: 21
FG-180..FG-184: DONE
FG-185: PARTIAL
SHA-256: 9ffc746d6404eca03aaf6f4f29beb006d9299ef58abea318ad7239ea52465fe2
```

Les snapshots PSDK du 2026-05-25 ont été déplacés sous `reports/previous/` et
marqués non autoritaires. La policy PSDK restante est explicitement limitée à
une non-régression de compteurs, jamais à une parité produit.

## Audit initial

État Git initial : propre au commit `fe4bf6ea9`.

Contradictions trouvées :

1. le rapport `FG-185` disait encore qu'aucune exécution de gate n'existait ;
2. la roadmap mentionnait encore une future « Phase 6 » sans les receipts 7A ;
3. les audits PSDK racine affichaient `728/728`, `330/330` et `482/482`
   `ported`, malgré la cible canonique `FG-053` toujours partielle ;
4. l'ancien statut sous `reports/previous/` se déclarait encore « source of
   truth » ;
5. les snapshots historiques `DONE / GO` de Phase 10 étaient déjà archivés et
   ont été conservés tels quels, derrière la correction autoritaire.

## Passes séparées

Les rôles demandés par `codex_rule.md` ont été exécutés comme passes locales,
les sub-agents n'étant pas autorisés dans ce contexte.

| Passe | Verdict |
|---|---|
| Audit / Architecture | PASS — roadmap, rapports autoritaires et archives séparés |
| Implémentation | PASS — aucune donnée gameplay ni code runtime modifié |
| Tests | PASS — 15 tests dashboard/cohérence |
| Build / Validation | PASS — CLI `--check` à `0`, snapshot identique bit à bit |
| Critique finale | PASS — aucun GO déduit des receipts partiels |

## Inventaire des fichiers

### Créés

- `reports/gameplay/evidence/rm_072_gameplay_roadmap_dashboard.md` ;
- `reports/previous/README.md` ;
- `reports/gameplay/rm_072_reports_roadmap_reconciliation.md`.

### Déplacés et annotés

- `reports/psdk-fight-parity-audit.md`
  → `reports/previous/psdk-fight-parity-audit-2026-05-25.md` ;
- `reports/psdk-fight-parity-audit.json`
  → `reports/previous/psdk-fight-parity-audit-2026-05-25.json`.

### Modifiés

- `pokemap_roadmap_mecaniques_fangame.md` ;
- `reports/gameplay/fg_185_mvp_release_gate_v0.md` ;
- `reports/gameplay/fg_180_185_phase_10_playable_game_validation_completion.md` ;
- `reports/analysis/psdk_fight_parity_gate_policy.md` ;
- `reports/previous/psdk-fight-engine-parity-status.md`.

## Zones de diff

```diff
- Phase 6 et receipt d'exécution manquants
+ RM-069/RM-070 verts ; RM-071 partiel ; RM-073 et walkthrough manquants
```

```diff
- # PSDK Fight Parity Audit
+ # PSDK Fight Parity Audit — archived snapshot
+ ARCHIVED / NON AUTORITAIRE
```

```diff
- source of truth for detailed rows
+ historical detailed rows
```

## Commandes et résultats exacts

```text
cd packages/map_core
dart test test/gameplay_roadmap_dashboard_test.dart \
  test/gameplay_roadmap_repository_consistency_test.dart
Résultat : exit 0, "00:09 +15: All tests passed!".

dart run tool/generate_gameplay_roadmap_dashboard.dart --check ../..
Résultat : exit 0.
Sortie : DONE 40 · PARTIAL 12 · BLOCKED 0 · TODO 41 · DEFERRED 21.

cmp -s build/phase-7a/rm-072-gameplay-roadmap-dashboard.md \
  reports/gameplay/evidence/rm_072_gameplay_roadmap_dashboard.md
Résultat : exit 0, fichiers identiques.

jq empty reports/previous/psdk-fight-parity-audit-2026-05-25.json
Résultat : exit 0.
```

## Décisions et non-objectifs

- Les snapshots restent dans Git pour la traçabilité ; aucun historique n'est
  supprimé.
- Le dashboard reste une projection read-only, pas une nouvelle autorité.
- `FG-053` n'est pas promu par les compteurs PSDK.
- `FG-185` n'est pas promu par les gates techniques déjà vertes.
- Aucun statut hors Phase 7A n'est réévalué dans ce lot.

## Auto-critique et risques

- Le dashboard V0 compte les Evidence Packs par nom de fichier et ne lit pas
  les JSON sous `reports/gameplay/evidence/`; la roadmap reste donc l'autorité.
- Des rapports historiques contiennent encore littéralement `DONE / GO` dans
  leurs annexes, mais leurs bannières les rendent non autoritaires.
- Déplacer un snapshot généré casse d'éventuels liens externes hors dépôt ;
  aucune référence de code ou CI interne n'a été trouvée.
- Le JSON archivé reçoit une clé `archiveMetadata` hors de son ancien schéma ;
  il est désormais documentaire et n'est plus une entrée d'outil.

## Annexe A — contenu complet de `reports/previous/README.md`

```markdown
# Archived engineering snapshots

Les fichiers de ce dossier sont des photographies historiques conservées pour
la traçabilité. Ils ne constituent pas une source de vérité produit, un statut
de roadmap courant ou un receipt de release.

Pour les anciens audits PSDK :

- les compteurs `fait`, `ported`, `partial` et `missing` mesurent une étape de
  migration ou de convergence du moteur ;
- ils ne prouvent pas la parité joueur, la consommation runtime, les surfaces
  UI ou un golden journey ;
- la cible combat canonique actuelle est
  `reports/gameplay/fg_053_battle_parity_target_v1.md` ;
- le verdict release actuel est celui de
  `reports/gameplay/fg_185_mvp_release_gate_v0.md` et de ses receipts Phase 7A.

Les snapshots `psdk-fight-parity-audit-2026-05-25.*` ont été déplacés ici le
2026-07-27 parce que leurs compteurs à 100 % pouvaient être lus à tort comme
une parité Pokémon complète.
```

## Annexe B — contenu complet du dashboard créé

```markdown
# Gameplay Roadmap Dashboard

DONE: 40 · PARTIAL: 12 · BLOCKED: 0 · TODO: 41 · DEFERRED: 21

| ID | Lot | Status | Evidence reports |
|---|---|---|---:|
| FG-010 | Initial GameState Builder V0 | TODO | 0 |
| FG-011 | New Game Runtime Flow V0 | TODO | 0 |
| FG-012 | Starter Selection Model V0 | TODO | 0 |
| FG-013 | Starter Selection Runtime Flow V0 | TODO | 0 |
| FG-014 | Save/Load Transaction Hardening V0 | DONE | 0 |
| FG-015 | Runtime Pause Menu Shell V0 | TODO | 0 |
| FG-016 | Golden Runtime Boot Smoke V0 | TODO | 0 |
| FG-020 | PlayerPokemon Runtime Persistence Audit | DONE | 1 |
| FG-021 | PlayerPokemon Persistence Expansion V0 | DONE | 0 |
| FG-022 | PC Box Model V0 | DONE | 0 |
| FG-023 | PC Storage Operations V0 | DONE | 0 |
| FG-024 | Capture Destination: Party or Box V0 | DONE | 0 |
| FG-025 | Capture To Box When Party Full V0 | DONE | 0 |
| FG-026 | Runtime Party Menu Read-only V0 | DONE | 0 |
| FG-027 | Pokémon Summary Runtime V0 | DONE | 0 |
| FG-028 | Party Reorder / Lead Selection V0 | DONE | 0 |
| FG-029 | Runtime PC Screen V0 | PARTIAL | 0 |
| FG-030 | Party/Box Validation V0 | DONE | 0 |
| FG-040 | Battle Persistence Contract V0 | DONE | 1 |
| FG-041 | PP Write-back V0 | DONE | 1 |
| FG-042 | Major Status Write-back V0 | DONE | 0 |
| FG-043 | Battle Reward Model V0 | DONE | 0 |
| FG-044 | XP Distribution V0 | DONE | 0 |
| FG-045 | Level-up Apply V0 | DONE | 0 |
| FG-046 | Learn Move on Level-up V0 | DONE | 0 |
| FG-047 | Evolution Check V0 | DONE | 0 |
| FG-048 | Post-battle Reward Presentation V0 | DONE | 0 |
| FG-049 | Capture Formula V0 | DONE | 0 |
| FG-050 | Generic Battle Item Handling V0 | TODO | 1 |
| FG-051 | Trainer Rewards / Money / Badges V0 | DONE | 1 |
| FG-052 | Switch/Faint Replacement UX Hardening | TODO | 1 |
| FG-053 | Battle Parity Target Document | TODO | 3 |
| FG-060 | Item Use Effect Registry V0 | DONE | 0 |
| FG-061 | Overworld Bag Menu V0 | DONE | 0 |
| FG-062 | Medicine Outside Battle V0 | DONE | 0 |
| FG-063 | Status Cure / Revive V0 | DONE | 0 |
| FG-064 | Key Item Gates V0 | TODO | 0 |
| FG-065 | Repel V0 | DEFERRED | 0 |
| FG-066 | Poké Ball Families V0 | DEFERRED | 0 |
| FG-067 | Item Pickup Event V0 | TODO | 0 |
| FG-068 | Hidden Item Event V0 | TODO | 0 |
| FG-069 | Shop Model V0 | DONE | 0 |
| FG-070 | Shop Runtime V0 | DONE | 0 |
| FG-071 | Heal Center Flow V0 | PARTIAL | 0 |
| FG-072 | Held Item Operations V0 | TODO | 1 |
| FG-073 | TM/HM Item Support V0 | TODO | 0 |
| FG-074 | Shop State Model & Compatibility V0 | DONE | 0 |
| FG-075 | Shop State Resolver & Stock V0 | DONE | 0 |
| FG-076 | Dynamic Shop Runtime V0 | DONE | 0 |
| FG-077 | Dynamic Shop No-Code Builder V0 | DONE | 0 |
| FG-078 | Shop State Validator & Simulator V0 | DONE | 0 |
| FG-079 | Selbrume Dynamic Shop Golden Slice V0 | DONE | 1 |
| FG-080 | Event Command Model V0 | TODO | 0 |
| FG-081 | Condition Builder No-code V0 | TODO | 0 |
| FG-082 | Runtime Command Executor V0 | PARTIAL | 1 |
| FG-083 | Give/Take Item Commands V0 | PARTIAL | 0 |
| FG-084 | Give Pokémon Command V0 | TODO | 0 |
| FG-085 | Heal Party Command V0 | PARTIAL | 0 |
| FG-086 | Start Trainer Battle Command V0 | TODO | 1 |
| FG-087 | Start Static Encounter Command V0 | TODO | 0 |
| FG-088 | Set Flag / Variable Commands V0 | TODO | 0 |
| FG-089 | Unlock Field Ability / Badge Commands V0 | PARTIAL | 0 |
| FG-090 | Warp Command V0 | PARTIAL | 0 |
| FG-091 | Open Shop / Open PC Commands V0 | PARTIAL | 0 |
| FG-092 | NPC Move / Presence Commands V0 | TODO | 2 |
| FG-093 | Action Builder UI V0 | PARTIAL | 0 |
| FG-094 | Event Templates V0 | TODO | 0 |
| FG-100 | Encounter Runtime Audit V0 | TODO | 1 |
| FG-101 | Encounter Conditions V0 | TODO | 0 |
| FG-102 | Static Encounter Flow V0 | TODO | 0 |
| FG-103 | Gift Pokémon Flow V0 | TODO | 0 |
| FG-104 | Fishing Attempt Flow V0 | DEFERRED | 0 |
| FG-105 | Headbutt Encounter Flow V0 | DEFERRED | 0 |
| FG-106 | Surf Encounter Conditions Hardening V0 | TODO | 0 |
| FG-107 | Consumed Encounter Write-back V0 | TODO | 0 |
| FG-108 | Encounter Authoring Validation V0 | TODO | 0 |
| FG-120 | Field Move Action Base V0 | PARTIAL | 0 |
| FG-121 | Cut Obstacle V0 | DEFERRED | 0 |
| FG-122 | Strength Boulder V0 | DEFERRED | 0 |
| FG-123 | Rock Smash V0 | DEFERRED | 0 |
| FG-124 | Flash / Dark Zone V0 | DEFERRED | 0 |
| FG-125 | Fly / Fast Travel V0 | DEFERRED | 0 |
| FG-126 | Waterfall V0 | DEFERRED | 0 |
| FG-127 | Dive V0 | DEFERRED | 0 |
| FG-128 | Field Move Editor Templates V0 | DEFERRED | 0 |
| FG-129 | Badge/Unlock Gate Integration V0 | PARTIAL | 0 |
| FG-140 | Trainer Defeated Policy V0 | TODO | 1 |
| FG-141 | Post-battle Dialogue Hook V0 | TODO | 0 |
| FG-142 | Trainer Rematch Policy V0 | DEFERRED | 0 |
| FG-143 | Badge Grant Flow V0 | TODO | 0 |
| FG-144 | Gym Flow Template V0 | TODO | 0 |
| FG-145 | Rival / Follow-up Event Template V0 | TODO | 1 |
| FG-146 | Story Progression Validator V0 | TODO | 0 |
| FG-147 | Scenario Completion Report V0 | TODO | 1 |
| FG-160 | Pause Menu Complete V0 | TODO | 2 |
| FG-161 | Runtime Pokédex Read-only V0 | TODO | 1 |
| FG-162 | Runtime Options V0 | TODO | 1 |
| FG-163 | Runtime Save Menu V0 | TODO | 1 |
| FG-164 | Runtime Map / Fast Travel UI V0 | TODO | 1 |
| FG-165 | Runtime Input Lock Conventions V0 | DONE | 2 |
| FG-180 | Project Gameplay Readiness Report V0 | DONE | 2 |
| FG-181 | Golden Slice Fangame Fixture V0 | DONE | 5 |
| FG-182 | Golden Slice End-to-End Smoke V0 | DONE | 1 |
| FG-183 | Regression Matrix V0 | DONE | 1 |
| FG-184 | Roadmap Status Dashboard Generator V0 | DONE | 1 |
| FG-185 | MVP Release Gate V0 | PARTIAL | 1 |
| FG-200 | Double battles | DEFERRED | 0 |
| FG-201 | Mega/Tera/Z/Dynamax | DEFERRED | 0 |
| FG-202 | Daycare/Breeding | DEFERRED | 0 |
| FG-203 | Online trade/battle | DEFERRED | 0 |
| FG-204 | Contests/minigames | DEFERRED | 0 |
| FG-205 | Battle Frontier | DEFERRED | 0 |
| FG-206 | IV/EV/nature advanced UX | DEFERRED | 0 |
| FG-207 | Full Pokédex modern parity | DEFERRED | 0 |
```
