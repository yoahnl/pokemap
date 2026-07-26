# FG-165 — Runtime Input Lock Conventions V0 — Revalidation

Date : 2026-07-26
HEAD initial : `ad73ed4cc`
Verdict final : `DONE`

## Résumé exécutif

FG-165 avait déjà une première implémentation historique et un Evidence Pack,
mais la composition récente Hub/runtime/UI joueur avait rouvert quatre risques :

1. plusieurs commandes modales pouvaient être rendues comme non traitées ;
2. le Hub possédait encore une route clavier parallèle ;
3. l'ouverture asynchrone du menu laissait une courte fenêtre de double input ;
4. un événement manette pouvait arriver par le flux normalisé et par les
   événements matériels Flutter.

La convention est maintenant unique :

| Contexte | Autorité | Comportement |
|---|---|---|
| Overworld | runtime + shell joueur | mouvements et action primaire routés |
| Dialogue | runtime | navigation/validation du dialogue, tout le reste consommé |
| Combat | runtime | commandes de combat, relâchements et commandes non prises en charge consommés |
| Transition / blocage / cinématique | runtime | commandes consommées, directions relâchées |
| Menu et services joueur | shell Flutter runtime-owned | Flame verrouillé par un propriétaire typé |

`PokeMapPlayerSessionView` possède désormais l'unique ingress matériel
clavier/manette. Le Hub ne fait que composer la session et monte son
`GameWidget` avec `autofocus: false`.

## Scope et non-objectifs

Inclus :

- convention typée commune dialogue/menu/combat/overworld ;
- autorité observable publiée par `map_runtime` ;
- focus matériel canonique dans `map_player_ui` ;
- routage Menu/Start commun à `M`, `Tab` et Start manette ;
- protection immédiate contre les doubles commandes pendant l'ouverture ou la
  fermeture asynchrone du menu ;
- déduplication du chemin manette matériel lorsque le flux normalisé est actif ;
- consommation fail-closed des commandes dans les contextes modaux ;
- tests runtime, widget, host et Hub.

Non inclus :

- remapping complet des contrôles ;
- fabrication d'une application standalone ;
- réécriture du moteur de combat ;
- correction des deux tests narratifs Selbrume déjà connus en échec.

## Audit initial

Le dépôt a été inspecté à `ad73ed4cc`. Le worktree contenait déjà 23 fichiers
modifiés issus du chantier tactile/dialogue/options immédiatement précédent et
aucun fichier non suivi. Ils ont été préservés.

L'audit a constaté :

- un contrat typé `RuntimeInputAuthoritySnapshot` existant, mais pas encore
  appliqué uniformément à toutes les sorties de
  `PlayableMapGame.handleRuntimeInputEvent` ;
- une méthode privée `_routeMenuKey` dans le Hub, parallèle au routeur joueur ;
- un `GameWidget` pouvant encore réclamer le focus matériel ;
- aucune barrière locale avant la fin de la commande asynchrone `openMenu` ;
- deux ingress potentiels pour une même touche de manette ;
- `Tab` et Start reconnus comme Menu, mais pas `M`.

Verdict de la passe Audit / Architecture : `PARTIAL`, lot à rouvrir.

## Décisions d'architecture

- `map_runtime` reste propriétaire de l'état et des locks de gameplay.
- `map_player_ui` reste propriétaire de l'ingress Flutter et des surfaces
  joueur.
- `apps/pokemap_hub` compose seulement ces contrats ; il ne possède ni machine
  d'état joueur ni routeur de gameplay.
- `map_runtime` ne dépend pas de `map_player_ui`.
- Le flux `Gamepads.normalizedEvents` est autoritaire lorsqu'il est activé.
  Les événements matériels manette sont alors consommés sans second dispatch.
  Si ce flux est explicitement désactivé, ils servent de fallback standalone.
- Un `GameWidget` hébergé dans `PokeMapPlayerSessionView` doit utiliser
  `autofocus: false`.

## Inventaire complet des fichiers modifiés

Les fichiers marqués « état d'entrée » étaient déjà modifiés au début de cette
revalidation ; ils sont inventoriés pour ne masquer aucun changement utilisateur.

| Fichier | Zone / raison / impact |
|---|---|
| `apps/pokemap_hub/lib/src/player/hub_player_preferences_gateway.dart` | État d'entrée : persistance de l'opacité tactile. |
| `apps/pokemap_hub/lib/src/ui/hub_shell.dart` | État d'entrée : préférence joueur transmise à la session. |
| `apps/pokemap_hub/lib/src/ui/player/hub_installed_game_player.dart` | Suppression du routeur clavier Hub ; `PokeMapPlayerSessionView` devient l'unique ingress ; `GameWidget(autofocus: false)`. |
| `apps/pokemap_hub/test/player/hub_player_preferences_gateway_test.dart` | État d'entrée : preuve de persistance de l'opacité. |
| `apps/pokemap_hub/test/ui/hub_runtime_presentation_test.dart` | Caractérisation de la frontière : une vue joueur canonique, aucun `_routeMenuKey`, aucun autofocus Flame. |
| `packages/map_player_ui/lib/src/localization/player_localizations.dart` | État d'entrée : libellé d'opacité tactile. |
| `packages/map_player_ui/lib/src/player/player_dialogue_overlay.dart` | État d'entrée : tap sur dialogue et choix tactiles. |
| `packages/map_player_ui/lib/src/player/pokemap_player_session_view.dart` | Focus canonique, routeur clavier/manette unique, déduplication manette, autorité observable, verrou immédiat de transition menu commun au tactile/clavier/manette. |
| `packages/map_player_ui/lib/src/player/runtime_player_actions.dart` | État d'entrée : mapping logique des actions joueur. |
| `packages/map_player_ui/lib/src/player/runtime_player_detail_router.dart` | État d'entrée : slider d'opacité dans Options. |
| `packages/map_player_ui/lib/src/player/runtime_player_surface_router.dart` | État d'entrée : menu tactile conditionné par l'autorité runtime. |
| `packages/map_player_ui/lib/src/player/runtime_player_touch_controls.dart` | État d'entrée : placement portrait et opacité. |
| `packages/map_player_ui/lib/src/preferences/player_preferences.dart` | État d'entrée : préférence typée et bornée d'opacité. |
| `packages/map_player_ui/test/player/pokemap_player_session_view_test.dart` | Matrice tactile, dialogue, clavier, manette, déduplication et double-input asynchrone. |
| `packages/map_player_ui/test/player/runtime_player_detail_router_test.dart` | État d'entrée : slider Options. |
| `packages/map_player_ui/test/player_dialogue_overlay_test.dart` | État d'entrée : commandes tactiles de dialogue. |
| `packages/map_player_ui/test/player_localizations_test.dart` | État d'entrée : localisation du réglage. |
| `packages/map_runtime/lib/src/player/runtime_player_coordinator.dart` | Locks typés acquis/libérés avec les phases joueur. |
| `packages/map_runtime/lib/src/player/runtime_player_host.dart` | Publication des contrats runtime vers la composition. |
| `packages/map_runtime/lib/src/player/runtime_player_models.dart` | Préférences et snapshots nécessaires au shell joueur. |
| `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart` | Routage fail-closed selon `RuntimeInputContext`, notifier d'autorité et relâchement des directions. |
| `packages/map_runtime/lib/src/presentation/flame/runtime_input_authority.dart` | Égalité de snapshot et propriétaires externes typés. |
| `packages/map_runtime/lib/src/presentation/flame/runtime_input_key_bindings.dart` | `M` rejoint `Tab` et Start comme commande Menu. |
| `packages/map_runtime/test/playable_map_game_input_test.dart` | Preuves dialogue, transition, combat et consommation des relâchements. |
| `packages/map_runtime/test/player/runtime_player_coordinator_pause_test.dart` | Preuves d'acquisition/libération du lock de pause. |
| `packages/map_runtime/test/runtime_input_authority_test.dart` | Matrice exhaustive : seul overworld accepte le mouvement. |
| `packages/map_runtime/test/runtime_input_key_bindings_test.dart` | Mapping `M`, `Tab` et Start. |
| `pokemap_roadmap_mecaniques_fangame.md` | FG-165 et ses trois critères DoD marqués `DONE`. |
| `reports/gameplay/fg_165_runtime_input_lock_conventions_v0_revalidation_2026-07-26.md` | Présent Evidence Pack. |

## Zones de diff déterminantes

### Ingress matériel unique

```diff
+Focus(
+  key: ValueKey('runtime-player-keyboard-input-authority'),
+  autofocus: true,
+  onKeyEvent: _routeHardwareKeyEvent,
+  child: ...,
+)
```

Le Hub ne contient plus `_routeMenuKey` et sa scène utilise :

```diff
 GameWidget(
   game: game,
+  autofocus: false,
 )
```

### Barrière synchrone avant transition asynchrone

```diff
+if (_menuTransitionPending) return PlayerInputSurface.blocked;
```

Toutes les commandes `openMenu` et `resume`, y compris celles du bouton tactile,
passent par `_dispatchCommand`. Une seconde commande reçoit `unavailable`
jusqu'à la résolution de la première.

### Contextes modaux fail-closed

```diff
 if (context == battle) { ...; return true; }
 if (context == blocked || context == transition) {
   releaseMovementControl(...);
   return true;
 }
 if (context == dialogue) { ...; return true; }
 if (context != overworld) return true;
```

### Déduplication manette

```diff
+if (event.deviceType == gamepad && controllerInputEnabled) {
+  return KeyEventResult.handled;
+}
```

Le flux normalisé reste le seul producteur dans ce cas. Le chemin matériel est
routé une fois lorsque le flux contrôleur est désactivé.

## TDD : preuves RED puis GREEN

RED observés avant implémentation :

- ingress clavier : aucun événement de gameplay reçu ;
- Hub : `GameWidget` sans `autofocus: false` et routeur parallèle présent ;
- dialogue secondaire : attendu consommé, reçu `false` ;
- transition primaire/secondaire : attendu consommé, reçu `false` ;
- relâchement en combat : attendu consommé, reçu `false` ;
- course Menu puis direction : une direction pouvait atteindre le gameplay ;
- course Menu clavier puis bouton tactile : deux commandes au lieu d'une.

Dernier RED exact :

```text
Expected: an object with length of <1>
Actual: [RuntimePlayerCommand, RuntimePlayerCommand]
Which: has length of <2>
```

Après centralisation du verrou, le même test donne :

```text
00:00 +1: All tests passed!
```

## Commandes et résultats exacts

### Tests ciblés FG-165

```bash
cd packages/map_runtime
flutter test \
  test/runtime_input_authority_test.dart \
  test/player/runtime_input_lock_manager_test.dart \
  test/runtime_input_key_bindings_test.dart \
  test/session/player_input_router_test.dart \
  test/session/game_session_controller_test.dart \
  test/playable_map_game_input_test.dart
```

Résultat : `00:04 +64: All tests passed!`

```bash
cd packages/map_player_ui
flutter test
```

Résultat final : `00:08 +73: All tests passed!`

```bash
cd examples/playable_runtime_host
flutter test \
  test/in_game_menu_test.dart \
  test/runtime_gamepad_bridge_test.dart \
  test/runtime_gamepad_presence_test.dart \
  test/runtime_ios_controller_bridge_test.dart \
  test/runtime_touch_controls_visibility_test.dart \
  test/runtime_battle_command_overlay_visibility_test.dart
```

Résultat : `00:03 +25: All tests passed!`

```bash
cd apps/pokemap_hub
flutter test
```

Résultat final : `00:33 +135: All tests passed!`

La suite Hub ciblée de frontière donne également
`00:01 +3: All tests passed!`.

### Suite runtime complète

```bash
cd packages/map_runtime
flutter test
```

Résultat : `02:02 +2163 ~1 -2: Some tests failed.`

Les deux échecs ont été reproduits isolément et correspondent aux régressions
Selbrume déjà déclarées avant ce chantier :

- `selbrume_event_v2_three_source_integration_test.dart` ;
- `selbrume_narrative_campaign_outcome_matrix_test.dart`.

Tous les tests FG-165 sont verts. Le dépôt global n'est donc volontairement pas
déclaré entièrement vert.

### Analyses statiques

```text
map_runtime             No issues found! (ran in 4.9s)
map_player_ui           No issues found! (ran in 4.5s)
pokemap_hub             No issues found! (ran in 3.5s)
playable_runtime_host   No issues found! (ran in 5.9s)
```

### Builds réels

```bash
cd apps/pokemap_hub
flutter build ios --debug --simulator
flutter build macos --debug
```

Résultats :

```text
✓ Built build/ios/iphonesimulator/Runner.app
✓ Built build/macos/Build/Products/Debug/PokeMap Hub.app
```

Le fichier utilisateur Xcode non suivi créé par le build a été retiré après la
validation ; aucun artefact machine n'est conservé dans le worktree.

### Hygiène

```bash
dart format <fichiers Dart touchés>
git diff --check
```

Résultats : formatage propre ; `git diff --check` sans sortie.

## Critères de DONE

- [x] Convention unique pour dialogue/menu/battle/overworld.
- [x] Pas de double input pendant transition, y compris clavier vers tactile.
- [x] Tests et documentation runtime.

## Passes séparées

Le mode de collaboration interdisait la création de nouveaux sub-agents. Les
contrôles requis ont donc été exécutés comme passes nommées indépendantes.

| Passe | Verdict |
|---|---|
| Audit / Architecture | `PASS` après correction : une autorité runtime et un ingress Flutter. |
| Implémentation | `PASS` : aucune dépendance inversée Hub/runtime/UI. |
| Tests | `PASS FG-165` : RED observés puis suites ciblées vertes. |
| Build / Validation | `PASS` : quatre analyses, iOS simulateur et macOS verts. |
| Critique finale | `PASS` : aucune route parallèle restante ; double tap tactile couvert. |

## Auto-critique, limites et risques

- Le runtime nu laisse volontairement `Menu/Start` non traité : une application
  standalone devra monter le même shell joueur ou un shell compatible. Ce
  choix évite d'introduire des widgets produit dans Flame.
- Un embedder standalone futur devra respecter la règle documentée
  `GameWidget(autofocus: false)`.
- Le flux manette normalisé est prioritaire. Un futur travail de robustesse
  pourra exposer explicitement son état de disponibilité pour basculer
  dynamiquement sur le fallback matériel après une erreur de plugin.
- Les deux échecs Selbrume empêchent encore un verdict « dépôt global vert »,
  sans invalider ce lot.
- Les modifications tactiles/dialogue/options présentes à l'entrée sont
  conservées dans le même worktree et ne doivent pas être dissociées
  destructivement lors d'un futur commit.

## Contenu complet des fichiers créés

Aucun fichier source n'a été créé. Le seul nouveau fichier est le présent
Evidence Pack ; son contenu complet est ce document.

## État Git et publication

La revalidation a été réalisée sans opération Git d'écriture. Le présent
Evidence Pack et les changements validés sont ensuite inclus dans le commit de
publication demandé explicitement par l'utilisateur.
