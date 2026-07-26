# Evidence Pack — RM-025 Trainer Reward Authoring V0

Date : 2026-07-26
Lots liés : `RM-025`, `FG-051`, `FG-143`
Verdict proposé : **DONE**

## 1. Résultat

Le Trainer Studio permet maintenant d’authorer, sans modifier de JSON :

- l’argent de victoire ;
- une liste d’objets et leurs quantités depuis le catalogue local ;
- les flags activés après victoire ;
- un badge optionnel choisi dans le manifeste ;
- une capacité de terrain optionnelle choisie dans une liste lisible.

Le contrat sérialisé conserve les projets historiques byte-for-byte lorsque les
deux nouveaux champs optionnels ne sont pas renseignés. Le runtime projette les
récompenses exactes vers `BattleReward` uniquement après une victoire et laisse
leur application à la transaction post-combat existante.

## 2. État Git initial

État constaté après le commit RM-024 et avant RM-025 :

```text
 M apps/pokemap_hub/lib/src/ui/hub_app.dart
 M apps/pokemap_hub/lib/src/ui/hub_shell.dart
 M apps/pokemap_hub/test/ui/hub_app_player_navigation_test.dart
 M apps/pokemap_hub/test/ui/hub_preferences_store_test.dart
 M apps/pokemap_hub/test/ui/hub_shell_test.dart
 M packages/map_player_ui/lib/src/localization/player_localizations.dart
 M packages/map_player_ui/lib/src/preferences/player_preferences.dart
```

Ces sept modifications préexistantes appartiennent à l’utilisateur. Elles n’ont
été ni modifiées pour RM-025, ni stageées.

## 3. Audit initial

### 3.1 Existant

- `ProjectTrainerEntry` portait déjà `moneyReward`,
  `rewardItemGrants` et `rewardFlagIds`.
- `BattleReward` supportait déjà `badgeId` et
  `fieldAbilityUnlock`.
- `RuntimeBattleRewardResolver` projetait déjà argent, objets et flags.
- `ProjectValidator` validait déjà argent positif, IDs/quantités d’objets et
  flags dupliqués ou vides.
- `BadgeDefinition` et `ProjectManifest.badges` fournissaient un catalogue
  auteur canonique.

### 3.2 Manques

- aucun champ trainer sérialisé pour le badge ou la capacité de terrain ;
- aucune projection runtime de ces deux récompenses ;
- aucun contrôle de récompenses dans le Trainer Studio ;
- aucune validation de l’existence du badge ;
- aucun test de bout en bout de l’authoring guidé.

## 4. Verdict des cinq passes

| Passe | Périmètre | Verdict |
|---|---|---|
| 1 — architecture | frontières Core / Editor / Gameplay / Runtime | PASS |
| 2 — contrat et migration | defaults legacy, JSON, validation badge | PASS |
| 3 — authoring no-code | Design System, pickers catalogue/manifeste/enum | PASS |
| 4 — projection runtime | victoire seulement, application différée | PASS |
| 5 — validation | ciblés, analyses, suites larges, smokes | PASS avec un flake global documenté |

Aucun sub-agent n’a été utilisé : le mode d’exécution actif interdisait la
délégation proactive. Les cinq passes ont été réalisées localement et
séquentiellement.

## 5. Décisions et non-objectifs

### Décisions

- `map_core` reste la source de vérité des récompenses authorées.
- Les deux champs optionnels nouveaux utilisent
  `@JsonKey(includeIfNull: false)` afin de ne pas modifier la sérialisation des
  trainers historiques.
- Les IDs d’objets ne peuvent pas être inventés quand le catalogue est
  indisponible : le contrôle est désactivé et explique la cause.
- Le badge provient exclusivement de `ProjectManifest.badges`.
- La capacité de terrain provient exclusivement de `FieldAbility.values`.
- La saisie des flags reste une liste textuelle séparée par des virgules,
  normalisée et validée ; le manifeste ne possède pas encore de registre de
  flags utilisable par un picker.

### Non-objectifs

- objets utilisables par l’IA adverse ;
- économie dynamique ou récompenses aléatoires ;
- scripts arbitraires post-combat ;
- templates et cycle de vie trainer, réservés à RM-027 ;
- modification du protocole transactionnel post-combat existant.

## 6. Fichiers modifiés

### Core

- `packages/map_core/lib/src/models/project_trainer.dart`
- `packages/map_core/lib/src/models/project_trainer.freezed.dart`
- `packages/map_core/lib/src/models/project_trainer.g.dart`
- `packages/map_core/lib/src/validation/validators.dart`
- `packages/map_core/test/project_trainer_reward_test.dart`
- `packages/map_core/test/project_trainer_validation_test.dart`

### Editor

- `packages/map_editor/lib/src/application/use_cases/trainer_use_cases.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`
- `packages/map_editor/lib/src/ui/panels/trainer_library_panel.dart`
- `packages/map_editor/lib/src/ui/panels/trainer_library_panel_trainer_widgets.dart`
- `packages/map_editor/lib/src/ui/panels/trainer_library_panel_workspace_widgets.dart`
- `packages/map_editor/test/trainer_library_panel_test.dart`
- `packages/map_editor/test/trainer_use_cases_test.dart`

### Runtime

- `packages/map_runtime/lib/src/application/runtime_battle_reward_resolver.dart`
- `packages/map_runtime/test/runtime_battle_reward_resolver_test.dart`

### Fichiers créés

- `docs/superpowers/plans/2026-07-26-rm-025-trainer-reward-authoring-v0.md`
- `packages/map_editor/lib/src/ui/panels/trainer_library_panel_reward_widgets.dart`
- `reports/gameplay/fg_051_143_trainer_reward_authoring_v0.md`

## 7. Zones précises modifiées

- `ProjectTrainerEntry` : ajout de `rewardBadgeId` et
  `rewardFieldAbilityUnlock`, absents du JSON quand ils valent `null`.
- `ProjectValidator` : index des badges du manifeste, rejet des badges vides
  ou inconnus.
- `CreateTrainerUseCase` / `UpdateTrainerUseCase` : normalisation complète,
  conservation des valeurs omises et effacement explicite des optionnels.
- `EditorNotifier` : transport typé de tous les champs de récompense.
- `TrainerLibraryPanel` : état create/edit, validation, ajout/retrait d’objets,
  hydratation, reset et sauvegarde.
- `_TrainerEditorCard` : insertion de la section de récompenses.
- `RuntimeBattleRewardResolver` : projection du badge et de la capacité de
  terrain sur victoire uniquement.
- Tests : legacy/round-trip, validation, use cases, widget guidé et projection
  runtime.

Statistique du diff suivi avant ajout des fichiers créés :

```text
15 files changed, 905 insertions(+), 226 deletions(-)
```

Le diff sémantique sans espaces du gros fichier de composition UI est limité à
`60 insertions, 7 deletions`; le reste correspond au réalignement automatique
par `dart format`.

## 8. TDD et incidents rencontrés

### RED initial

```text
cd packages/map_core
dart test test/project_trainer_reward_test.dart
```

Résultat : échec de compilation attendu, car `rewardBadgeId` et
`rewardFieldAbilityUnlock` n’existaient pas encore.

### Synchronisation du catalogue dans le widget test

Le premier test UI n’ajoutait pas l’objet car le catalogue asynchrone était
encore dans l’état indisponible. Le test a été corrigé pour injecter et attendre
les références locales explicites, comme les autres scénarios Trainer Studio.

### Compatibilité de persistance

La première suite Editor globale a montré que sérialiser les nouveaux optionnels
à `null` changeait les hashes de la fixture Selbrume. Les champs ont été marqués
`includeIfNull: false`, une assertion legacy a été ajoutée, puis le test
byte-for-byte a été rejoué avec succès.

## 9. Commandes et résultats exacts

### Génération

```text
cd packages/map_core
dart run build_runner build --delete-conflicting-outputs
Built with build_runner in 23s; wrote 30 outputs.
```

Après le correctif de migration :

```text
Built with build_runner in 23s; wrote 15 outputs.
```

Seuls les fichiers générés liés à `project_trainer` présentent un diff suivi.

### Tests ciblés et analyses

```text
cd packages/map_core
dart test test/project_trainer_reward_test.dart test/project_trainer_validation_test.dart
00:01 +15: All tests passed!
dart analyze
No issues found!
```

```text
cd packages/map_editor
flutter test test/trainer_use_cases_test.dart test/trainer_library_panel_test.dart
00:05 +22: All tests passed!
flutter analyze
No issues found! (ran in 5.6s)
```

```text
cd packages/map_runtime
flutter test test/runtime_battle_reward_resolver_test.dart
00:00 +10: All tests passed!
flutter analyze
No issues found! (ran in 4.8s)
```

```text
cd packages/map_gameplay
dart test
00:04 +400: All tests passed!
dart analyze
No issues found!
```

### Suites larges

```text
cd packages/map_core
dart test
02:03 +4464: All tests passed!
```

```text
cd packages/map_runtime
flutter test
02:52 +2195 ~1: All tests passed!
```

La première exécution globale Editor, lancée avant le correctif
`includeIfNull: false`, a terminé ainsi :

```text
05:58 +4151 -2: Some tests failed.

Failing tests:
  narrative_event_authoring_snapshot_performance_test.dart:
    NS-EVENT-V2 Phase E-bis frozen persistence budgets
  selbrume_event_v2_persistence_migration_test.dart:
    J2 autonomous Selbrume Event V2 fixture regenerates the versioned fixture
    byte-for-byte from the checkpoint
```

Rejoués isolément :

```text
flutter test test/narrative_event_authoring_snapshot_performance_test.dart
00:11 +1: All tests passed!
```

```text
flutter test test/selbrume_event_v2_persistence_migration_test.dart \
  --plain-name 'J2 autonomous Selbrume Event V2 fixture regenerates the versioned fixture byte-for-byte from the checkpoint'
00:22 +1: All tests passed!
```

Le test performance avait échoué sous la contention de la suite globale et
passe isolément très sous ses budgets. Le test de persistance a été réparé par
le lot. Une tentative de lancer ces deux tests Flutter simultanément dans le
même package a produit une course du répertoire `build/`; elle n’est pas
considérée comme preuve et les tests ont ensuite été rejoués séquentiellement.

### Smokes

```text
cd packages/map_runtime
flutter test test/phase_a_golden_battle_slice_smoke_test.dart
00:00 +3: All tests passed!
```

```text
cd examples/playable_runtime_host
flutter test test/phase_a_golden_slice_launch_test.dart
00:00 +1: All tests passed!
flutter analyze
No issues found! (ran in 5.9s)
```

### Hygiène

```text
git diff --check
```

Résultat : aucune sortie, code retour `0`.

## 10. Contenu complet des fichiers créés

Le présent Evidence Pack est omis de cette section afin d’éviter une inclusion
récursive de lui-même.

### `docs/superpowers/plans/2026-07-26-rm-025-trainer-reward-authoring-v0.md`

```markdown
# RM-025 Trainer Reward Authoring V0 Implementation Plan

**Goal:** permettre d’authorer sans JSON les récompenses d’un dresseur :
argent, objets, flags, badge optionnel et capacité de terrain, puis garantir que
le runtime projette exactement ces données dans la transaction post-combat.

**Architecture:** `map_core` reste la source de vérité sérialisée ;
`map_editor` normalise et valide un draft guidé ; `map_runtime` ne déduit rien
et projette les champs vers le `BattleReward` pur de `map_gameplay`.

**Non-goals:** inventaire d’objets utilisables par l’IA, économie dynamique,
récompenses aléatoires, scripts arbitraires post-combat et templates trainer
(réservés à RM-027).

### Task 1: Contrat core

- [x] Ajouter badge et field unlock optionnels au trainer.
- [x] Préserver les defaults legacy et le round-trip JSON.
- [x] Valider argent, grants, flags, badge et field unlock.

### Task 2: Use cases et runtime

- [x] Normaliser création/édition des récompenses.
- [x] Préserver les champs quand ils sont omis et permettre leur effacement.
- [x] Projeter badge et field unlock vers `BattleReward`.
- [x] Prouver l’application différée et atomique existante.

### Task 3: Authoring no-code

- [x] Ajouter une section Récompenses au Trainer Studio.
- [x] Utiliser les primitives du design system.
- [x] Picker catalogue pour les objets.
- [x] Picker manifeste pour le badge.
- [x] Picker enum lisible pour la capacité de terrain.
- [x] Contrôle explicite argent, quantité et flags sans JSON.

### Task 4: Validation et clôture

- [x] Tests core, use cases, widget et runtime ciblés.
- [x] Suites/analyzes des packages modifiés.
- [x] Smokes Golden battle/runtime host.
- [x] Evidence Pack FG-051 / FG-143.
- [x] Commit isolé et état Git final.
```

### `packages/map_editor/lib/src/ui/panels/trainer_library_panel_reward_widgets.dart`

```dart
part of 'trainer_library_panel.dart';

class _TrainerRewardEditor extends StatelessWidget {
  const _TrainerRewardEditor({
    required this.createMode,
    required this.moneyController,
    required this.flagsController,
    required this.itemQuantityController,
    required this.references,
    required this.badges,
    required this.selectedItemId,
    required this.itemGrants,
    required this.badgeId,
    required this.fieldAbilityUnlock,
    required this.onSelectItem,
    required this.onAddItem,
    required this.onRemoveItem,
    required this.onSelectBadge,
    required this.onSelectFieldAbility,
  });

  final bool createMode;
  final TextEditingController moneyController;
  final TextEditingController flagsController;
  final TextEditingController itemQuantityController;
  final _TrainerReferenceData references;
  final List<BadgeDefinition> badges;
  final String? selectedItemId;
  final List<ProjectTrainerItemGrant> itemGrants;
  final String? badgeId;
  final FieldAbility? fieldAbilityUnlock;
  final ValueChanged<String?> onSelectItem;
  final VoidCallback onAddItem;
  final ValueChanged<String> onRemoveItem;
  final ValueChanged<String?> onSelectBadge;
  final ValueChanged<FieldAbility?> onSelectFieldAbility;

  String get _keyPrefix => createMode
      ? 'trainer-library-create-reward'
      : 'trainer-library-edit-reward';

  @override
  Widget build(BuildContext context) {
    final itemEntries = references.itemsCatalogView.entries;
    final sortedBadges = badges.toList(growable: false)
      ..sort((left, right) => left.label.compareTo(right.label));

    return PokeMapCard(
      key: Key('$_keyPrefix-card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const PokeMapSectionHeader(
            title: 'Récompenses de victoire',
            description:
                'Ces gains sont appliqués une seule fois après une victoire validée.',
          ),
          PokeMapTextField(
            label: 'Argent',
            fieldKey: Key('$_keyPrefix-money-field'),
            controller: moneyController,
            hintText: '0',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 10),
          PokeMapDropdownField<String>(
            key: Key('$_keyPrefix-item-dropdown'),
            label: 'Objet à ajouter',
            value: selectedItemId ?? '',
            enabled: references.itemsCatalogView.isAvailable,
            items: <PokeMapDropdownItem<String>>[
              const PokeMapDropdownItem<String>(
                value: '',
                label: 'Sélectionner un objet du catalogue',
              ),
              for (final item in itemEntries)
                PokeMapDropdownItem<String>(
                  value: item.id,
                  label: '${item.name} · ${item.id}',
                ),
            ],
            onChanged: (value) => onSelectItem(value.isEmpty ? null : value),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: PokeMapTextField(
                  label: 'Quantité',
                  fieldKey: Key('$_keyPrefix-item-quantity-field'),
                  controller: itemQuantityController,
                  hintText: '1',
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 8),
              PokeMapButton(
                key: Key('$_keyPrefix-item-add-button'),
                onPressed:
                    references.itemsCatalogView.isAvailable ? onAddItem : null,
                size: PokeMapButtonSize.medium,
                leading: const Icon(CupertinoIcons.plus, size: 14),
                child: const Text('Ajouter'),
              ),
            ],
          ),
          if (!references.itemsCatalogView.isAvailable) ...[
            const SizedBox(height: 6),
            const Text(
              'Le catalogue local des objets est indisponible : aucun ID brut '
              'n’est enregistré silencieusement.',
            ),
          ],
          if (itemGrants.isNotEmpty) ...[
            const SizedBox(height: 10),
            for (final grant in itemGrants) ...[
              _TrainerRewardItemGrantRow(
                key: Key('$_keyPrefix-item-${grant.itemId}'),
                grant: grant,
                displayName: _itemDisplayName(itemEntries, grant.itemId),
                onRemove: () => onRemoveItem(grant.itemId),
              ),
              const SizedBox(height: 6),
            ],
          ],
          const SizedBox(height: 4),
          PokeMapTextField(
            label: 'Flags activés après victoire',
            fieldKey: Key('$_keyPrefix-flags-field'),
            controller: flagsController,
            hintText: 'story:trainer_won, chapter:badge_received',
          ),
          const SizedBox(height: 10),
          PokeMapDropdownField<String>(
            key: Key('$_keyPrefix-badge-dropdown'),
            label: 'Badge optionnel',
            value: badgeId ?? '',
            items: <PokeMapDropdownItem<String>>[
              const PokeMapDropdownItem<String>(
                value: '',
                label: 'Aucun badge',
              ),
              for (final badge in sortedBadges)
                PokeMapDropdownItem<String>(
                  value: badge.id,
                  label: badge.label,
                ),
            ],
            onChanged: (value) => onSelectBadge(value.isEmpty ? null : value),
          ),
          const SizedBox(height: 10),
          PokeMapDropdownField<String>(
            key: Key('$_keyPrefix-field-ability-dropdown'),
            label: 'Capacité de terrain optionnelle',
            value: fieldAbilityUnlock?.moveId ?? '',
            items: <PokeMapDropdownItem<String>>[
              const PokeMapDropdownItem<String>(
                value: '',
                label: 'Aucune capacité',
              ),
              for (final ability in FieldAbility.values)
                PokeMapDropdownItem<String>(
                  value: ability.moveId,
                  label: _fieldAbilityRewardLabel(ability),
                ),
            ],
            onChanged: (value) => onSelectFieldAbility(
              FieldAbility.values
                  .where((ability) => ability.moveId == value)
                  .firstOrNull,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrainerRewardItemGrantRow extends StatelessWidget {
  const _TrainerRewardItemGrantRow({
    super.key,
    required this.grant,
    required this.displayName,
    required this.onRemove,
  });

  final ProjectTrainerItemGrant grant;
  final String displayName;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return PokeMapCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text('$displayName × ${grant.quantity}'),
          ),
          PokeMapButton(
            key: Key('trainer-library-reward-item-remove-${grant.itemId}'),
            onPressed: onRemove,
            variant: PokeMapButtonVariant.ghost,
            size: PokeMapButtonSize.small,
            child: const Text('Retirer'),
          ),
        ],
      ),
    );
  }
}

String _itemDisplayName(
  List<PokemonItemCatalogEntryView> entries,
  String itemId,
) {
  return entries
          .where((entry) => entry.id == itemId)
          .map((entry) => entry.name)
          .firstOrNull ??
      itemId;
}

String _fieldAbilityRewardLabel(FieldAbility ability) => switch (ability) {
      FieldAbility.surf => 'Surf',
      FieldAbility.cut => 'Coupe',
      FieldAbility.strength => 'Force',
      FieldAbility.flash => 'Flash',
      FieldAbility.rockSmash => 'Éclate-Roc',
      FieldAbility.waterfall => 'Cascade',
      FieldAbility.dive => 'Plongée',
    };
```

## 11. Auto-critique et risques

### Points solides

- Le flux est complet de l’authoring à la projection runtime.
- Les anciens JSON et snapshots restent stables.
- Les valeurs optionnelles peuvent être conservées ou effacées explicitement.
- Le nouvel UI respecte les primitives et tokens du Design System.
- Le catalogue indisponible échoue de manière explicite et sûre.

### Risques résiduels

- Les flags restent une saisie guidée légère plutôt qu’un picker, faute de
  registre de flags canonique dans le manifeste.
- Le badge et la capacité de terrain peuvent être authorés indépendamment ;
  aucune règle ne force la capacité du badge à correspondre au champ explicite.
  Ce choix conserve la flexibilité auteur mais devra être réévalué lors du gate
  de capacité complet.
- La suite Editor globale est sensible aux budgets performance et dure presque
  six minutes. La preuve ciblée et les replays isolés sont verts, mais le gate
  RM-053 devra relancer la suite globale après l’ensemble de la phase.

## 12. Statut roadmap proposé

- `RM-025` : **DONE**
- `FG-051` : **PARTIAL** — récompenses trainer complètes, autres aspects de
  fidélité trainer à traiter par RM-027/RM-028.
- `FG-143` : **PARTIAL** — bridge de récompenses complet, parité Pokémon
  générale encore couverte par les autres lots de phase 2.

## 13. État Git final attendu après commit

Après le commit isolé RM-025, seuls les sept fichiers utilisateur listés dans
l’état initial doivent rester modifiés. Le hash du commit et l’état réel sont
ajoutés au rapport de phase/final de session après création du commit.
