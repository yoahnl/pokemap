# FG-100 — Encounter Runtime Audit V0

Date : 2026-07-27

Lot de remédiation : `RM-030`

Verdict proposé : `FG-100 = DONE`

## 1. Résultat

Le modèle et l’éditeur exposent les huit valeurs de `EncounterKind`, mais le
runtime de déplacement ne déclenche réellement que `walk` et `surf`.

- `walk` est supporté et prouvé par une chaîne runtime, une absence de
  déclenchement hors zone et un save/reload de capture.
- `surf` est câblé au mode de déplacement Surf, mais reste partiel : il manque
  une preuve runtime positive, négative et save/reload dédiée ainsi que des
  conditions authorées complètes.
- `headbutt`, les trois cannes, `gift` et `special` sont modélisés et
  sélectionnables dans l’éditeur, mais aucun déclencheur runtime correspondant
  n’existe.
- Les systèmes narratifs de cadeau et de combat statique ne constituent pas une
  preuve d’exécution de `EncounterKind.gift` ou `EncounterKind.special` : ce
  sont des chemins séparés.

Le lot est volontairement un audit sans modification de code, conformément au
DoD canonique de `FG-100`.

## 2. Audit initial

### État Git initial

Branche : `main`

HEAD : `6fdccab35 feat(battle): add full capability gate`

Modifications préexistantes, hors scope et préservées :

```text
 M apps/pokemap_hub/lib/src/ui/hub_app.dart
 M apps/pokemap_hub/lib/src/ui/hub_shell.dart
 M apps/pokemap_hub/test/ui/hub_app_player_navigation_test.dart
 M apps/pokemap_hub/test/ui/hub_preferences_store_test.dart
 M apps/pokemap_hub/test/ui/hub_shell_test.dart
 M packages/map_player_ui/lib/src/localization/player_localizations.dart
 M packages/map_player_ui/lib/src/preferences/player_preferences.dart
```

### Inventaire des contrats

- Modèle canonique :
  `packages/map_core/lib/src/models/enums.dart` définit huit kinds.
- Table authorée :
  `packages/map_core/lib/src/models/project_manifest.dart` associe une
  `ProjectEncounterTable` à un `EncounterKind`.
- Zone de gameplay :
  `EncounterZonePayload` conserve l’identifiant de table et le kind attendu.
- Sélection pure :
  `packages/map_gameplay/lib/src/gameplay_encounter.dart` filtre une zone et une
  table par kind puis effectue le tirage pondéré.
- Déclenchement runtime :
  `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`
  choisit `surf` en `MovementMode.surf`, sinon `walk`.
- Authoring :
  les dropdowns de
  `packages/map_editor/lib/src/ui/panels/gameplay_zone_properties_panel.dart`
  et
  `packages/map_editor/lib/src/ui/panels/encounter_tables_panel_table_widgets.dart`
  utilisent actuellement `EncounterKind.values`.

## 3. Matrice exhaustive

| `EncounterKind` | Modèle | Éditeur | Runtime | Tests frais / preuves | Statut honnête | Suite |
|---|---|---|---|---|---|---|
| `walk` | Oui | Oui | Déclenché après un pas hors Surf | Positif runtime, négatif hors zone, capture + reload | `SUPPORTED` | `RM-031` durcit taux et conditions |
| `surf` | Oui | Oui | Déclenché après un pas en `MovementMode.surf` | Modèle/editor et bridge mouvement seulement ; pas de golden runtime dédié | `PARTIAL` | `RM-031`, puis `RM-034` |
| `headbutt` | Oui | Oui, trompeur | Aucun déclencheur d’action Headbutt | Aucune preuve runtime | `DEFERRED` | Masquer/bloquer via `RM-035`; `FG-105` hors MVP |
| `oldRod` | Oui | Oui, trompeur | Aucun déclencheur de pêche | Aucune preuve runtime | `DEFERRED` | Masquer/bloquer via `RM-035`; `FG-104` hors MVP |
| `goodRod` | Oui | Oui, trompeur | Aucun déclencheur de pêche | Aucune preuve runtime | `DEFERRED` | Masquer/bloquer via `RM-035`; `FG-104` hors MVP |
| `superRod` | Oui | Oui, trompeur | Aucun déclencheur de pêche | Aucune preuve runtime | `DEFERRED` | Masquer/bloquer via `RM-035`; `FG-104` hors MVP |
| `gift` | Oui | Oui, trompeur | Aucun déclencheur de table `gift` ; le cadeau narratif est séparé | Aucune preuve runtime de ce kind | `DEFERRED` | `RM-033`, `RM-035`, `RM-038` |
| `special` | Oui | Oui, trompeur | Aucun déclencheur de table `special` ; le combat statique est séparé | Aucune preuve runtime de ce kind | `DEFERRED` | `RM-032`, `RM-035` |

## 4. Gaps exacts

### Walk

La chaîne minimale existe : zone persistée, table compatible, tirage, ouverture
du combat sauvage, capture, écriture de la sauvegarde et rechargement. Le taux
reste toutefois fourni par une policy runtime par défaut plutôt que par une
configuration organique complète. Ce durcissement appartient à `RM-031`.

### Surf

Le runtime choisit correctement `EncounterKind.surf` lorsque le joueur est en
mode Surf. Il manque encore :

- un taux et des conditions authorés sans constante runtime dominante ;
- un test positif de rencontre sur eau ;
- un test négatif avant acquisition de Surf ou hors zone ;
- une preuve de save/reload dans le même flow.

### Headbutt

Le modèle existe, mais aucun input, aucune cible de décor et aucune commande
runtime ne demandent une rencontre `headbutt`. `FG-105` est explicitement
différé hors MVP.

### Rods

Les trois niveaux de canne sont sérialisables, mais il n’existe aucun flow de
pêche runtime. `FG-104` est explicitement différé hors MVP.

### Gift

Des commandes narratives savent offrir un Pokémon, mais aucune d’elles
n’exécute une `ProjectEncounterTable` de kind `gift`. Le kind ne doit donc pas
être annoncé comme supporté.

### Special

Le catalogue narratif possède un contrat de combat statique et le runtime un
`StaticBattleStartRequest`, mais le chemin de scénario observé n’exécute pas une
table `special` complète avec consommation persistante. `RM-032` porte cette
fermeture.

## 5. Passes Codex

### Passe 1 — Audit / Architecture

Verdict : `PASS`.

Les responsabilités restent correctement séparées : modèle dans `map_core`,
sélection pure dans `map_gameplay`, déclenchement dans `map_runtime` et
authoring dans `map_editor`. Le défaut principal est une divergence de
capabilité entre l’éditeur et le runtime, pas une violation de frontière.

### Passe 2 — Implémentation

Verdict : `NOT APPLICABLE`.

Le DoD canonique de `FG-100` exige « Aucun code modifié ». Le livrable est le
présent audit ; aucun comportement, schéma, fixture ou test n’a été ajouté.

### Passe 3 — Tests

Verdict : `PASS` pour les preuves existantes, `GAP` documenté pour Surf et les
six kinds non exécutables.

Les tests existants ont été relancés pour vérifier que les preuves citées sont
fraîches. Ils ne transforment pas une absence de scénario en support implicite.

### Passe 4 — Build / Validation

Verdict : `PASS`.

Les quatre packages concernés passent leur analyse statique. Les tests ciblés
de core, gameplay, editor et runtime sont verts.

### Passe 5 — Critique finale

Verdict : `PASS WITH FOLLOW-UPS`.

L’audit répond au DoD sans modifier le produit. Le risque le plus important est
maintenant explicite : l’éditeur permet de publier six kinds non exécutables et
un kind Surf insuffisamment prouvé. `RM-035` devra fermer ce risque après les
implémentations `RM-031` à `RM-034`.

## 6. Commandes et résultats exacts

### `packages/map_core`

```text
dart test test/tall_grass_authoring_view_test.dart
All tests passed! (+3)

dart analyze
No issues found!
```

### `packages/map_gameplay`

```text
dart test test/surface_generated_gameplay_zone_bridge_test.dart
All tests passed! (+6)

dart analyze
No issues found!
```

### `packages/map_editor`

```text
flutter test test/encounter_tables_panel_test.dart
All tests passed! (+5)

flutter analyze
No issues found! (ran in 5.2s)
```

### `packages/map_runtime`

```text
flutter test test/p6_selbrume_route_1_encounter_capture_golden_slice_test.dart test/wild_battle_end_to_end_flow_test.dart
All tests passed! (+18)

flutter analyze
No issues found! (ran in 4.8s)
```

Les messages de préchauffage relatifs à un répertoire temporaire d’espèces
absent apparaissent dans un test qui simule volontairement un projet minimal ;
ils n’échouent pas le test et ne sont pas introduits par ce lot.

## 7. Fichiers modifiés

| Fichier | Zone | Nature |
|---|---|---|
| `reports/gameplay/fg_100_encounter_runtime_audit_v0.md` | Fichier complet | Audit, matrice, preuves et risques `FG-100` |

Aucun fichier de production, de test, de fixture ou de roadmap n’est modifié.
Le contenu complet du seul fichier créé est le présent document.

## 8. Décisions et non-objectifs

- La présence d’un enum ou d’un dropdown n’est pas une preuve de support.
- Un chemin narratif séparé ne valide pas automatiquement un
  `EncounterKind`.
- Aucun provider temps/météo n’est inventé.
- Fishing et Headbutt restent différés conformément à la roadmap.
- Le statut canonique n’est pas modifié dans
  `pokemap_roadmap_mecaniques_fangame.md`, car la demande porte sur
  l’exécution de la phase et non sur la réécriture de la roadmap.

## 9. Risques restants

1. L’éditeur expose encore des kinds non exécutables jusqu’à `RM-035`.
2. Surf reste `PARTIAL` jusqu’aux preuves `RM-031` et `RM-034`.
3. Les gifts et rencontres statiques utilisent des contrats voisins dont les
   sémantiques de consommation et d’annulation doivent être unifiées.
4. La policy de taux par défaut peut masquer une configuration authorée
   incomplète jusqu’à `RM-031`.

## 10. État Git à la clôture documentaire

Le diff du lot est limité au présent rapport. Les sept modifications
préexistantes listées en section 2 restent hors staging et hors commit. L’état
post-commit doit donc revenir exactement à ces sept lignes protégées.
