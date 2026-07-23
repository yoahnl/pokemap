# FG-182 — Parcours joueur réel Selbrume

Date : 2026-07-23

Statut proposé : **DONE**

## Résumé exécutif

La Golden Slice FG-182 n'est plus la petite fixture synthétique FG-181 : elle
est désormais le projet produit `selbrume/`. Le test d'acceptation démarre une
vraie partie dans `PlayableMapGame`, traverse les sources physiques et les
Scenes authorées, conduit les overlays de dialogue, combat, shop et PC, puis
vérifie les 17 checkpoints de `selbrume/walkthrough.json` dans l'ordre.

Le parcours prouve notamment : starter et cinq Balls obtenus sans duplication,
refus de Surf avant unlock, défaite puis victoire réelle contre Lysa, badge,
achats, soin, captures vers party puis Box, retrait PC, enquête des marais,
traversée Surf, phare, sauvegarde/reprise et épilogue. Le test interdit les
raccourcis qui forgeaient auparavant la progression (`_finishedOutcome`,
`GameStateMutations`, setters debug, `setFlag`, unlock direct).

## Audit initial

- Branche : `main`.
- HEAD initial du lot : `8eb30eb5e`.
- Worktree initial : propre après le commit du lot 5.2.
- FG-181 exécutait des APIs de production sur une fixture de trois maps, mais
  s'auto-attribuait tous les checks Readiness. Il ne prouvait pas Selbrume.
- Selbrume possédait déjà l'histoire principale et les services authorés des
  lots 5.1/5.2, mais aucun parcours joueur unique ne les reliait.
- L'exécution réelle a révélé quatre écarts moteur légitimes : ciblage d'une
  attaque `allAdjacent` en single, save imbriquée dans une transaction Scene,
  perte de Surf aux transitions et validation statique d'une arrivée Surf.

## Décisions et non-objectifs

1. `selbrume/` est la seule Golden Slice produit FG-182.
2. `golden_fangame_slice/` reste une fixture de composition FG-181 et ne peut
   plus construire de `ProjectGameplayReadinessReport`.
3. Le RNG de rencontre/capture est injecté par le port public
   `PlayableMapGame.encounterRandom`; les formules et sessions restent réelles.
4. Le petit host de service ne modifie jamais directement `GameState` : il
   représente seulement les clics de modal et emploie les mêmes opérations
   shop/PC que les widgets du host.
5. Ce lot ne déclare pas la release MVP complète : FG-180 (preuve machine) et
   FG-014 (load transactionnel) restent les tâches 5.4 et 5.5.

## Inventaire des fichiers

| Fichier | Zone précise | Raison |
|---|---|---|
| `examples/playable_runtime_host/test/selbrume_player_journey_e2e_test.dart` | test FG-182, helpers d'input et checkpoints | Parcours joueur produit, garde anti-raccourcis, captures party/box, services et walkthrough |
| `examples/playable_runtime_host/test/support/selbrume_player_service_test_host.dart` | nouveau host de modal | Représenter les choix shop/PC sans forger l'état |
| `examples/playable_runtime_host/test/golden_fangame_slice_e2e_test.dart` | titre et suppression Readiness | Rétrograder explicitement la fixture en FG-181 |
| `examples/playable_runtime_host/test/golden_fangame_slice_fixture_test.dart` | garde source | Interdire le retour d'une auto-readiness FG-182 |
| `selbrume/walkthrough.json` | nouveau contrat 17 étapes | Ordre canonique du parcours MVP |
| `packages/map_editor/tool/seed_selbrume_canonical_narrative_content.dart` | données Pokémon, shop et ancrages Surf | Rendre capture, Ball et Surf jouables par authoring canonique |
| `packages/map_editor/test/selbrume_canonical_narrative_seed_test.dart` | assertions produit | Protéger le contenu régénéré |
| `packages/map_editor/test/selbrume_narrative_reconstruction_test.dart` | inventaire service | Prouver la reconstruction no-code |
| `packages/map_editor/test/support/selbrume_narrative_authoring_harness.dart` | commandes service | Reconstruire les ajouts via contrôleurs typés |
| `selbrume/project.json` | sortie seed | Manifest et données narratives canoniques |
| `selbrume/maps/map_port_brisants.json` | sortie seed | Comptoir/PC/soin/Surf et sources physiques |
| `packages/map_battle/lib/src/domain/action/battle_action_decision_mapper.dart` | `_targetFor` | Accepter `allAdjacent` en combat single |
| `packages/map_battle/test/psdk_action_queue_test.dart` | régression mapper | Protéger l'attaque Surf réelle |
| `packages/map_gameplay/lib/src/narrative_event_state_transactions.dart` | contexte Zone et after-commit | Différer une save de service jusqu'au commit Scene |
| `packages/map_gameplay/lib/map_gameplay.dart` | export public | Publier le callback after-commit |
| `packages/map_gameplay/test/narrative_event_transaction_concurrency_test.dart` | succès/rollback différés | Protéger atomicité et absence de deadlock |
| `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart` | RNG, save service, warp/connection | Injection déterministe, save différée et conservation de Surf |
| `packages/map_runtime/test/playable_map_game_input_test.dart` | transitions et fixture Pokémon | Régressions Surf et métadonnées progression valides |
| `packages/map_runtime/test/selbrume_map_navigation_contract_test.dart` | gate Surf et validateur | Valider la navigation totalement débloquée dans le bon mode |
| `reports/gameplay/fg_182_golden_slice_end_to_end_smoke_v0.md` | Evidence Pack | Remplacer l'ancienne preuve synthétique |
| `reports/gameplay/fg_000_pokemap_mvp_closure_roadmap_2026-07-22.md` | Task 5.3 | Enregistrer la clôture du sous-lot |

## Diffs fonctionnels

### Golden Slice produit

- Le joueur choisit Carapuce via Maël et reçoit exactement cinq Poké Balls.
- Le Port est atteint par connexion physique et l'alerte est résolue via Yarn.
- Surf est refusé avant l'autorisation narrative.
- Lysa est d'abord capable de vaincre réellement le joueur ; le test rejoue
  ensuite le combat jusqu'à la victoire sans outcome fabriqué.
- Shop, soin et PC sont ouverts depuis les Scenes physiques du Port.
- Six captures sauvages réelles remplissent la party puis envoient la suivante
  en Box ; le PC effectue ensuite un dépôt/retrait observable.
- Le badge et Surf proviennent des conséquences de la Scene de victoire.
- La traversée du Passage conserve Surf à travers connexions et warps.
- Le phare, le reload intermédiaire et l'épilogue clôturent les 17 étapes.

### Correctifs révélés par l'acceptance

- `PsdkBattleActionDecisionMapper` choisit la cible ennemie primaire pour une
  attaque `allAdjacent` en single, au lieu de lever une exception.
- `NarrativeEventStateTransactions.deferAfterCurrentCommit` exécute la save du
  service après le commit atomique de la Scene ; une erreur du hook restaure le
  snapshot précédent.
- `_handleConnection` et `_handleWarp` propagent le `MovementMode` courant au
  monde reconstruit, évitant un retour silencieux à `walk`.
- Le validateur de navigation emploie `surf` sur les maps qui possèdent un gate
  movement/Surf, tout en continuant à rejeter une collision physique bloquée.
- La fixture battle runtime déclare désormais `growthRateId`, `baseExp` et
  `catchRate`, exigés par l'hydratation de progression.

## TDD et diagnostics

| Cycle | RED / diagnostic | GREEN |
|---|---|---|
| Ciblage Surf | mapper `allAdjacent` non supporté | test mapper + suites spread, `+15` |
| Transaction Scene/service | save imbriquée bloquée dans le mutex Event | hooks after-commit, `+4` |
| Transition Surf | mode revenu à `walk` après warp/connection | deux assertions de régression |
| Navigation | arrivée cabane→Passage jugée bloquée en walk | validation fully-unlocked mode-aware, `+20` isolé |
| Fixture runtime | trois tests échouaient sur `missingGrowthRate` | métadonnées progression, groupe runtime `+56` |
| Acceptation | ancienne fixture pouvait fabriquer tous les checks | garde source FG-181 et garde anti-raccourcis FG-182 |

## Commandes et résultats exacts

```bash
cd examples/playable_runtime_host
flutter test test/selbrume_player_journey_e2e_test.dart test/golden_fangame_slice_e2e_test.dart test/golden_fangame_slice_fixture_test.dart -r compact
```

```text
03:59 +9: All tests passed!
```

```bash
cd packages/map_battle
dart test test/psdk_action_queue_test.dart test/psdk_basic_spread_move_test.dart
dart analyze
```

```text
+15: All tests passed!
No issues found!
```

```bash
cd packages/map_gameplay
dart test test/narrative_event_transaction_concurrency_test.dart
dart analyze
```

```text
+4: All tests passed!
No issues found!
```

```bash
cd packages/map_runtime
flutter test test/playable_map_game_input_test.dart test/selbrume_map_navigation_contract_test.dart -r compact
flutter analyze
```

Premier run avant correction de la fixture : `+53 -3`, trois erreurs
`missingGrowthRate`. Run final :

```text
+56: All tests passed!
No issues found! (ran in 4.3s)
```

```bash
cd packages/map_editor
dart run tool/seed_selbrume_canonical_narrative_content.dart --project-root ../../selbrume --check
flutter test test/selbrume_canonical_narrative_seed_test.dart test/selbrume_narrative_reconstruction_test.dart -r compact
flutter analyze
```

```text
Selbrume canonical narrative content is up to date.
+5: All tests passed!
No issues found! (ran in 5.0s)
```

```bash
cd examples/playable_runtime_host
flutter analyze
flutter build macos --debug
```

```text
No issues found! (ran in 4.0s)
✓ Built build/macos/Build/Products/Debug/playable_runtime_host.app
```

## Mapping DoD FG-182

| Critère Task 5.3 | Preuve |
|---|---|
| Selbrume Golden Slice canonique | chemin projet `../../selbrume/project.json` et walkthrough produit |
| Fixture historique sans readiness | garde source dans `golden_fangame_slice_fixture_test.dart` |
| Parcours naturel complet | test `player completes Selbrume through PlayableMapGame production hooks` |
| RNG déterministe public | `encounterRandom` injecté dans `PlayableMapGame` |
| Party pleine, Box et retrait | captures battle overlay + service PC |
| Badge et gate Surf | conséquence authorée + blocage walk/traversée surf |
| Aucun raccourci | test source anti-forgery dédié |
| 17 étapes ordonnées | comparaison exacte avec `walkthrough.json` |
| Seed reproductible | commande `--check` verte |

## Passes obligatoires

| Passe | Verdict |
|---|---|
| Audit / Architecture | **PASS** — Selbrume remplace la fixture comme preuve produit ; frontières Core/Gameplay/Battle/Runtime/Host conservées |
| Implémentation | **PASS** — correctifs minimaux placés dans leur package propriétaire |
| Tests | **PASS** — parcours réel, gardes anti-forgery et régressions ciblées verts |
| Build / Validation | **PASS** — cinq analyses propres et build host macOS debug réussi |
| Critique finale | **PASS avec limites** — preuve automatisée robuste, mais pas encore receipt lié au commit ni load transactionnel |

## Risques et limites

- Le test UI automatise les choix du joueur et n'est pas un walkthrough humain
  chronométré ; celui-ci appartient à la Phase 6.
- Le host de service est un adaptateur de clics de test, pas un second moteur de
  règles ; une divergence future des gestes UI doit être couverte par les tests
  widgets du host.
- Le build validé ici est `debug`. Le package release autonome et sa signature
  appartiennent à Task 6.3.
- Aucun receipt de preuve lié à un SHA/tree hash n'est produit dans ce lot ;
  c'est précisément Task 5.4 / FG-180.
- Le chargement conserve encore son ancien modèle d'application avant Task 5.5
  / FG-014.
- Les suites complètes de tous les packages seront exécutées par la matrice
  séquentielle de Phase 6 ; ce lot exécute les suites ciblées à son périmètre.

## État git final attendu

Avant commit, le worktree doit contenir uniquement les fichiers inventoriés
ci-dessus. Le commit proposé est :

```text
test(host): prove the real Selbrume MVP journey
```

## Annexe A — contenu complet du fichier créé

### `examples/playable_runtime_host/test/support/selbrume_player_service_test_host.dart`

```dart
import 'dart:collection';

import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';

/// Deterministic stand-in for the Flutter service routes used by the host.
///
/// The Scene still opens the production [PlayerServiceRuntimeController]. This
/// adapter only represents the explicit taps a player would make inside the
/// modal page; all state changes use the same gameplay operations as the real
/// Shop and PC widgets.
final class SelbrumePlayerServiceTestHost implements PlayerServiceOverlayHost {
  final Queue<String> _shopPurchases = Queue<String>();
  var _withdrawCapturedPokemonOnNextPcOpen = false;

  final List<String> openedServices = <String>[];
  final List<String> purchasedItemIds = <String>[];
  String? withdrawnSpeciesId;

  void queueShopPurchase(String itemId) => _shopPurchases.add(itemId);

  void queueCapturedPokemonWithdrawal() {
    _withdrawCapturedPokemonOnNextPcOpen = true;
  }

  @override
  Future<PlayerServiceHostResult> openShop(
    PlayerServiceShopRequest request,
  ) async {
    openedServices.add('shop:${request.shop.id}');
    if (_shopPurchases.isEmpty) {
      return const PlayerServiceHostResult.cancelled();
    }
    final itemId = _shopPurchases.removeFirst();
    final purchase = const GameStateMutations().purchaseFromShop(
      request.gameState,
      shop: request.shop,
      itemId: itemId,
      categoryId: _categoryFor(itemId),
      quantity: 1,
    );
    if (!purchase.isSuccess) {
      throw StateError('Selbrume shop purchase failed: ${purchase.failure}.');
    }
    purchasedItemIds.add(itemId);
    return PlayerServiceHostResult.completed(purchase.state);
  }

  @override
  Future<PlayerServiceHostResult> openPc(PlayerServicePcRequest request) async {
    openedServices.add('pc');
    if (!_withdrawCapturedPokemonOnNextPcOpen) {
      return const PlayerServiceHostResult.cancelled();
    }
    _withdrawCapturedPokemonOnNextPcOpen = false;
    final storage = request.gameState.pokemonStorage.normalized();
    final box =
        storage.boxes.firstWhere((candidate) => candidate.pokemon.isNotEmpty);
    final capturedSpeciesId = box.pokemon.first.speciesId;
    const operations = PlayerStorageOperations();
    final deposit = operations.deposit(
      state: request.gameState.copyWith(pokemonStorage: storage),
      partyIndex: 1,
      boxId: box.id,
    );
    if (!deposit.isSuccess) {
      throw StateError('Selbrume PC deposit failed: ${deposit.failure}.');
    }
    final withdrawal = operations.withdraw(
      state: deposit.state,
      boxId: box.id,
      boxIndex: 0,
    );
    if (!withdrawal.isSuccess) {
      throw StateError('Selbrume PC withdrawal failed: ${withdrawal.failure}.');
    }
    withdrawnSpeciesId = capturedSpeciesId;
    return PlayerServiceHostResult.completed(withdrawal.state);
  }

  @override
  Future<PlayerServiceHostResult> openHealCenter(
    PlayerServiceHealRequest request,
  ) async {
    openedServices.add('heal');
    return const PlayerServiceHostResult.cancelled();
  }
}

String _categoryFor(String itemId) => switch (itemId) {
      'potion' || 'antidote' => 'medicine',
      _ => 'items',
    };
```

## Annexe B — contenu complet du fichier créé

### `selbrume/walkthrough.json`

```json
{
  "schemaVersion": 1,
  "projectId": "selbrume",
  "label": "Golden Slice MVP Selbrume",
  "steps": [
    {"id": "new_game", "label": "Démarrer une nouvelle partie", "proof": "PlayableMapGame charge le spawn du bourg avec une équipe vide."},
    {"id": "starter_and_capture_kit", "label": "Choisir Carapuce et recevoir cinq Poké Balls", "proof": "L'interaction authorée avec Maël exécute les conséquences de Scene."},
    {"id": "port_alert", "label": "Rejoindre le port et résoudre l'alerte", "proof": "Le joueur traverse les connexions physiques et choisit une réponse Yarn."},
    {"id": "surf_refused_before_unlock", "label": "Constater le refus du chenal Surf", "proof": "Le moteur refuse la zone movement/surf avant l'autorisation narrative."},
    {"id": "lysa_victory", "label": "Battre Lysa dans un vrai combat", "proof": "Les commandes du battle overlay sélectionnent des attaques réelles."},
    {"id": "badge_and_surf_unlocked", "label": "Recevoir le Badge des Brisants et Surf", "proof": "Les conséquences awardBadge et unlockFieldAbility persistent dans GameState."},
    {"id": "shop_used", "label": "Acheter Potion, Antidote et Poké Ball", "proof": "La Scene du comptoir ouvre le service joueur et commit chaque achat."},
    {"id": "healing_service_used", "label": "Soigner l'équipe au poste du port", "proof": "La conséquence healParty restaure les dégâts du combat contre Lysa."},
    {"id": "first_wild_capture", "label": "Capturer un Pokémon sauvage dans l'équipe", "proof": "Une rencontre réelle consomme une Ball et ajoute le Pokémon à la party."},
    {"id": "party_filled_by_captures", "label": "Remplir l'équipe par des captures réelles", "proof": "Cinq captures sauvages portent la party à sa capacité maximale."},
    {"id": "capture_sent_to_storage", "label": "Envoyer une capture au stockage", "proof": "Une capture supplémentaire avec party pleine arrive dans une Box."},
    {"id": "pc_withdrawal", "label": "Retirer le Pokémon capturé depuis le PC", "proof": "La Scene du terminal ouvre le service PC et commit dépôt puis retrait."},
    {"id": "marsh_investigation", "label": "Résoudre les indices et quêtes des marais", "proof": "Les sources physiques déclenchent leurs Scenes et récompenses authorées."},
    {"id": "surf_gate_crossed", "label": "Activer Surf et traverser le chenal", "proof": "Le joueur confirme le dialogue de terrain puis franchit la même zone."},
    {"id": "lighthouse_completed", "label": "Terminer le phare et son boss", "proof": "Le joueur gravit les maps, bat les gardiens et apaise Lanturn."},
    {"id": "save_reload_mid_journey", "label": "Sauvegarder et recharger le parcours", "proof": "Les checkpoints sérialisés conservent progression, services et Events consommés."},
    {"id": "epilogue_reached", "label": "Atteindre l'épilogue du port", "proof": "La dernière source authorée clôt l'histoire principale de Selbrume."}
  ]
}
```
