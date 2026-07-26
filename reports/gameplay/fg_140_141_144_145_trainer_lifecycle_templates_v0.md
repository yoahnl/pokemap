# RM-027 — Trainer Lifecycle & Templates V0

## Résumé exécutif

**Lot exact :** `RM-027 — Trainer Lifecycle & Templates V0`

**Liens canoniques :** `FG-140`, `FG-141`, `FG-144`, `FG-145`

**Verdict proposé :** `DONE`

Le cycle de vie trainer est maintenant un contrat sérialisé, validé, authorable
sans JSON et consommé par le runtime. Les trainers restent one-shot par défaut,
un rematch doit être explicitement autorisé, et les dialogues avant combat,
après victoire et après défaite sont résolus par une policy pure avant leur
intégration dans `PlayableMapGame`. Les templates Champion d’Arène et Rival
portent des invariants produit plutôt que de simples labels décoratifs.

Lysa est promue en Rival canonique dans Selbrume. La modification du manifeste
a invalidé, comme attendu, le fingerprint narratif ; le receipt de production a
été régénéré après le passage des deux suites runtime obligatoires.

## Confirmation du scope

### Inclus

- contrat `templateKind`, `rematchPolicy` et hooks dialogue trainer ;
- compatibilité JSON historique sans nouvelles clés lorsque les champs sont
  absents ;
- validation des références dialogue et des invariants Gym/Rival ;
- create/update editor, presets, politique de rematch et pickers no-code ;
- policy runtime one-shot/rematch et hooks pré/post-combat ;
- intégration directe dans `PlayableMapGame` ;
- promotion de Lysa et receipt narratif frais ;
- preuves ciblées, suites package-scoped, smokes et build hôte.

### Volontairement hors scope

- équipe de rematch évolutive ou scaling ;
- calendrier/temporisation de rematch ;
- génération automatique de fichiers Yarn depuis le Trainer Studio ;
- warp/cutscene de défaite hors scénario ;
- nouvelle IA trainer, couverte séparément par `RM-021`.

## Audit initial

### Contrats et fichiers existants

- `ProjectTrainerEntry` portait déjà équipe, difficulté et récompenses, mais
  aucun type de template, aucune policy rematch et aucun hook dialogue trainer.
- `MapEntityNpcData` disposait de `dialogue` et `defeatDialogueRef`, utiles comme
  fallbacks historiques mais insuffisants pour un lifecycle trainer complet.
- `PlayableMapGame` persistait déjà `trainer_defeated:<id>` et protégeait les
  combats one-shot, mais n’orchestrait pas les dialogues trainer authorés.
- le Trainer Studio disposait déjà du transport create/update et du design
  system PokeMap, sans surface lifecycle guidée.
- Lysa possédait une Golden Slice narrative save/load et un trainer réel, sans
  template rival sérialisé ni dialogues post-combat dédiés.

### Tests préexistants pertinents

- progression post-combat runtime ;
- interaction trainer et persistance des outcomes Selbrume ;
- use cases et widget tests du Trainer Studio ;
- validateur narratif Selbrume et receipt runtime ;
- Golden battle slice runtime/host.

### Risques identifiés avant implémentation

- casser les snapshots JSON historiques ;
- doubler combat ou outcome après un dialogue asynchrone ;
- rejouer automatiquement un trainer one-shot dans sa LoS ;
- faire mentir les presets editor sans invariant core ;
- laisser un receipt Selbrume frais après modification du manifeste ;
- mélanger les dialogues de scénario et les hooks de combat direct.

### Interprétation prudente du lot

Le lot a conservé `null` comme policy one-shot historique ; seul `allowed`
autorise un rematch. Les combats lancés par un scénario n’ouvrent pas
automatiquement les hooks post-combat trainer afin de ne pas doubler le
follow-up déjà possédé par le graphe narratif.

## Verdict des cinq passes obligatoires

| Passe | Verdict | Signal principal |
|---|---|---|
| Audit / Architecture | PASS | frontières core/editor/runtime respectées ; flag canonique réutilisé |
| Implémentation | PASS | contrat, authoring, policy et consommation runtime reliés |
| Tests | PASS avec incident résolu | l’unique échec full editor était le receipt Selbrume stale attendu |
| Build / Validation | PASS | analyses, suites runtime/core, smokes, receipt et build macOS validés |
| Critique finale | PASS avec limites | pas de scope parasite ; limites rematch/whiteout documentées |

Ces passes ont été réalisées séparément dans le même agent, conformément au
fallback autorisé lorsque la délégation à de vrais sub-agents n’est pas utilisée
pour ce lot.

## Inventaire exhaustif

### Fichiers modifiés

| Fichier | Zones modifiées | Raison et impact |
|---|---|---|
| `packages/map_core/lib/src/models/project_trainer.dart` | enums et constructeur `ProjectTrainerEntry` | contrat typé lifecycle, champs optionnels compatibles |
| `packages/map_core/lib/src/models/project_trainer.freezed.dart` | API générée/copyWith/égalité | régénération fidèle du modèle |
| `packages/map_core/lib/src/models/project_trainer.g.dart` | codec JSON généré | lecture/écriture des nouveaux champs |
| `packages/map_core/lib/src/validation/validators.dart` | validation trainer | références dialogue et invariants Gym/Rival |
| `packages/map_editor/lib/src/application/use_cases/trainer_use_cases.dart` | create/update + normalisation | transport et effacement explicite des champs |
| `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart` | commandes trainer | propagation du contrat vers les use cases |
| `packages/map_editor/lib/src/ui/panels/trainer_library_panel.dart` | état, submit, validation, presets | authoring guidé et erreurs inline |
| `packages/map_editor/lib/src/ui/panels/trainer_library_panel_trainer_widgets.dart` | formulaire trainer | insertion de la carte lifecycle |
| `packages/map_editor/lib/src/ui/panels/trainer_library_panel_workspace_widgets.dart` | workspace | exposition de la carte en mode édition |
| `packages/map_editor/test/trainer_library_panel_test.dart` | test rival + activation robuste des boutons | preuve no-code et stabilité layout |
| `packages/map_editor/test/trainer_use_cases_test.dart` | create/update lifecycle | round-trip applicatif et clear/keep |
| `packages/map_runtime/lib/map_runtime.dart` | barrel public | export de la policy pure |
| `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart` | interaction trainer, fin de combat, dialogue loader | orchestration pré/post-combat, rematch, one-shot et outcome once |
| `packages/map_runtime/test/playable_map_game_post_battle_progression_integration_test.dart` | fixtures et 3 scénarios lifecycle | pré-combat, victoire persistée et défaite non persistée |
| `examples/playable_runtime_host/test/selbrume_event_v2_lysa_golden_slice_test.dart` | test manifeste canonique | preuve du template Rival Lysa |
| `selbrume/project.json` | dialogues et trainer Lysa | promotion Rival et hooks post-combat |
| `selbrume/.pokemap/validation/narrative_runtime_smoke_receipt.json` | fingerprint/date | attestation fraîche du nouveau snapshot |

### Fichiers créés

| Fichier | Rôle |
|---|---|
| `packages/map_core/test/project_trainer_lifecycle_test.dart` | codec, compatibilité et invariants |
| `packages/map_editor/lib/src/ui/panels/trainer_library_panel_lifecycle_widgets.dart` | surface lifecycle design-system-first |
| `packages/map_runtime/lib/src/application/runtime_trainer_lifecycle_policy.dart` | décision pure one-shot/rematch/dialogues |
| `packages/map_runtime/test/runtime_trainer_lifecycle_policy_test.dart` | matrice de policy |
| `selbrume/dialogues/lysa_port_after_win.yarn` | réplique après victoire |
| `selbrume/dialogues/lysa_port_after_loss.yarn` | réplique après défaite |
| `docs/superpowers/plans/2026-07-26-rm-027-trainer-lifecycle-templates-v0.md` | plan d’exécution du lot |
| `reports/gameplay/fg_140_141_144_145_trainer_lifecycle_templates_v0.md` | présent Evidence Pack |

Le présent rapport n’est pas reproduit dans lui-même afin d’éviter une
récursion infinie. Tous les autres fichiers créés sont reproduits intégralement
en annexe.

## Découpage précis des modifications

### Core

- ajout de `ProjectTrainerTemplateKind.gymLeader/rival` ;
- ajout de `ProjectTrainerRematchPolicy.allowed` ;
- cinq propriétés `includeIfNull: false` dans `ProjectTrainerEntry` ;
- validation de chaque ID de dialogue contre le manifeste ;
- Gym : badge et dialogue victoire requis, field unlock cohérent avec le badge ;
- Rival : dialogues avant/victoire et flag de suivi requis.

### Editor

- normalisation des IDs optionnels et sémantique `keep/clear` ;
- états create/edit pour template, rematch et trois dialogues ;
- presets appliquant classe, difficulté et tags ;
- dropdowns alimentés par `project.dialogues` ;
- validation inline identique aux invariants core ;
- primitives exclusivement issues du design system PokeMap.

### Runtime

- policy pure séparée de Flame ;
- one-shot historique si `rematchPolicy == null` ;
- dialogue avant combat puis un seul enqueue ;
- trainer vaincu : dialogue-only ou blocage, sauf rematch explicite ;
- victoire/défaite directes : hook authoré après commit post-combat ;
- outcome standalone publié après dialogue et au plus une fois, y compris si le
  loader échoue synchronement ;
- combats possédés par un scénario exclus des hooks automatiques pour empêcher
  les doubles follow-ups.

### Selbrume

- Lysa devient `templateKind: rival` ;
- hook avant combat conservé ;
- deux nouveaux dialogues post-combat ;
- flag `story:lysa_follow_up` explicite ;
- receipt runtime régénéré sur le nouveau fingerprint.

## Tests créés ou modifiés

### Positifs

- sérialisation round-trip complète ;
- interaction pré-combat puis battle ;
- victoire avec flag defeated puis dialogue ;
- défaite avec dialogue et sans flag defeated ;
- rematch explicite ;
- authoring Rival complet via dropdowns ;
- manifeste Lysa réel validé.

### Négatifs et garde-fous

- JSON legacy sans nouvelles clés ;
- référence dialogue inconnue rejetée ;
- Gym incomplet rejeté ;
- Rival incomplet rejeté ;
- one-shot vaincu bloqué sans dialogue ;
- absence de hook conservant le battle direct ;
- loader/outcome protégé contre une double publication ;
- scénario narratif non doublé par le lifecycle direct.

## Commandes et résultats exacts

### Génération core

```bash
cd packages/map_core
dart run build_runner build --delete-conflicting-outputs
```

```text
Built with build_runner in 23s; wrote 15 outputs.
```

### Core

```bash
dart test test/project_trainer_lifecycle_test.dart
dart analyze
dart test
```

```text
+5: All tests passed!
No issues found!
+4469: All tests passed!
```

### Editor ciblé

```bash
flutter test test/trainer_use_cases_test.dart \
  test/trainer_library_panel_test.dart -r failures-only
flutter analyze
```

```text
+24: All tests passed!
No issues found! (ran in 6.3s)
```

Décomposition observée avant la commande combinée :

```text
trainer_use_cases_test.dart: +9, All tests passed!
trainer_library_panel_test.dart: +15, All tests passed!
```

### Editor complet et résolution honnête de l’incident

```bash
flutter test
```

```text
05:12 +4154 -1: Some tests failed.
Failing test:
test/selbrume_narrative_validator_test.dart:
canonical Selbrume passes bounded solvability and runtime proof
Expected: NarrativeRuntimeReceiptState.freshPass
Actual: NarrativeRuntimeReceiptState.stale
```

Cause : `selbrume/project.json` et les Yarn font partie du fingerprint runtime.
Le receipt précédent devait donc devenir stale.

Après régénération :

```bash
flutter test test/selbrume_narrative_validator_test.dart -r failures-only
```

```text
+1: All tests passed!
```

La suite complète editor n’a pas été relancée une seconde fois dans ce lot :
ses 4 154 autres tests étaient déjà passés, et le seul échec identifié a été
contre-validé isolément après régénération. La gate finale de Phase 2 devra
néanmoins relancer la suite complète.

### Runtime ciblé et complet

```bash
flutter test \
  test/runtime_trainer_lifecycle_policy_test.dart \
  test/playable_map_game_post_battle_progression_integration_test.dart \
  -r failures-only
flutter analyze
flutter test -r failures-only
flutter test test/phase_a_golden_battle_slice_smoke_test.dart -r failures-only
```

```text
+14: All tests passed!
No issues found! (ran in 4.7s)
+2203 ~1: 1 skipped test.
+2203 ~1: All other tests passed!
+3: All tests passed!
```

Le skip est déclaré par la suite existante ; aucun test runtime n’a échoué.

### Selbrume et host

```bash
jq empty selbrume/project.json
cd examples/playable_runtime_host
flutter test test/selbrume_event_v2_lysa_golden_slice_test.dart \
  -r failures-only
dart run tool/verify_narrative_project.dart \
  --project-root ../../selbrume \
  --profile selbrume-release-v1 \
  --write-receipt
flutter analyze
flutter test test/phase_a_golden_slice_launch_test.dart -r failures-only
flutter build macos --debug
```

```text
jq: exit 0
+5: All tests passed!
selbrume-lighthouse-retry: +3: All tests passed!
selbrume-player-journey: +6: All tests passed!
result: pass
projectFingerprint:
sha256:3f11570bf2d67acec4055259e4506cac24529b73702c51db74dc09567fac15ca
No issues found! (ran in 5.3s)
+1: All tests passed!
✓ Built build/macos/Build/Products/Debug/PokeMap Selbrume.app
```

### Hygiène

```bash
dart format <17 fichiers Dart du lot>
git diff --check -- \
  examples/playable_runtime_host packages/map_core packages/map_editor \
  packages/map_runtime selbrume
```

```text
Formatted 17 files.
git diff --check: exit 0
```

## État Git

### État initial du lot

Modifications utilisateur préexistantes, explicitement préservées :

```text
 M apps/pokemap_hub/lib/src/ui/hub_app.dart
 M apps/pokemap_hub/lib/src/ui/hub_shell.dart
 M apps/pokemap_hub/test/ui/hub_app_player_navigation_test.dart
 M apps/pokemap_hub/test/ui/hub_preferences_store_test.dart
 M apps/pokemap_hub/test/ui/hub_shell_test.dart
 M packages/map_player_ui/lib/src/localization/player_localizations.dart
 M packages/map_player_ui/lib/src/preferences/player_preferences.dart
```

### État attendu après commit

Seules les sept modifications utilisateur ci-dessus doivent rester. Le commit
doit contenir exclusivement les fichiers listés dans cet Evidence Pack.

## Limites conservées

- une défaite joueur reste suivie d’un whiteout-lite sur la carte active ;
- si ce whiteout devait un jour changer de carte, le hook de défaite direct
  devrait être transporté avec son contexte NPC plutôt que résolu sur la carte
  courante ;
- le rematch réutilise la même équipe et la même récompense ;
- aucun template ne crée automatiquement un fichier Yarn ;
- `FG-185` demeure `NO-GO`, comme l’indique le receipt ; ce lot ne le promeut
  pas.

## Auto-critique finale

### Points solides

- compatibilité legacy explicitement testée ;
- invariants du template portés par `map_core`, pas seulement par l’UI ;
- policy pure et exportée, donc testable sans Flame ;
- scénarios directs victoire et défaite couverts ;
- double publication d’outcome repérée puis protégée pendant la critique ;
- stale receipt traité comme un vrai échec et non masqué.

### Risques restants

- absence de test d’intégration Flame dédié à un rematch après sortie/rentrée de
  LoS ; la policy et le guard sont testés séparément ;
- le test Gym est négatif ; la surface positive est couverte par les mêmes
  transports que Rival, mais une Golden Slice Gym pourra renforcer `FG-144` ;
- la suite editor complète n’a pas été rejouée après refresh du receipt, même si
  son seul échec a été isolé et corrigé.

### Prochaines étapes proposées

1. `RM-026` — Battle MVP Capability Gate ;
2. `RM-028` — Nature/IV/EV Bridge Fidelity ;
3. `RM-029` — Exhausted PP & Struggle V0 ;
4. `RM-053` — Full Battle Capability Gate et relance complète de la gate.

## Annexe — contenu complet des fichiers créés

### `packages/map_core/test/project_trainer_lifecycle_test.dart`

```dart
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectTrainerEntry lifecycle', () {
    test('legacy JSON keeps one-shot trainer defaults without new keys', () {
      final trainer = ProjectTrainerEntry.fromJson(const <String, dynamic>{
        'id': 'legacy',
        'name': 'Legacy',
        'trainerClass': 'Trainer',
      });

      expect(trainer.templateKind, isNull);
      expect(trainer.rematchPolicy, isNull);
      expect(trainer.preBattleDialogueId, isNull);
      expect(trainer.victoryDialogueId, isNull);
      expect(trainer.defeatDialogueId, isNull);
      expect(trainer.toJson(), isNot(contains('templateKind')));
      expect(trainer.toJson(), isNot(contains('rematchPolicy')));
      expect(trainer.toJson(), isNot(contains('preBattleDialogueId')));
      expect(trainer.toJson(), isNot(contains('victoryDialogueId')));
      expect(trainer.toJson(), isNot(contains('defeatDialogueId')));
    });

    test('typed lifecycle survives JSON round-trip', () {
      const trainer = ProjectTrainerEntry(
        id: 'rival',
        name: 'Lysa',
        trainerClass: 'Rival',
        templateKind: ProjectTrainerTemplateKind.rival,
        rematchPolicy: ProjectTrainerRematchPolicy.allowed,
        preBattleDialogueId: 'lysa_before',
        victoryDialogueId: 'lysa_victory',
        defeatDialogueId: 'lysa_defeat',
        rewardFlagIds: <String>['story:lysa_follow_up'],
      );

      expect(ProjectTrainerEntry.fromJson(trainer.toJson()), trainer);
    });

    test('rejects unknown lifecycle dialogue references', () {
      final manifest = _project(
        trainers: const <ProjectTrainerEntry>[
          ProjectTrainerEntry(
            id: 'misty',
            name: 'Misty',
            trainerClass: 'Gym Leader',
            preBattleDialogueId: 'missing_dialogue',
          ),
        ],
      );

      expect(
        () => ProjectValidator.validate(manifest),
        throwsA(
          isA<ValidationException>().having(
            (error) => error.toString(),
            'message',
            contains('preBattleDialogueId'),
          ),
        ),
      );
    });

    test('gym template requires a badge and victory dialogue', () {
      final manifest = _project(
        trainers: const <ProjectTrainerEntry>[
          ProjectTrainerEntry(
            id: 'misty',
            name: 'Misty',
            trainerClass: 'Gym Leader',
            templateKind: ProjectTrainerTemplateKind.gymLeader,
          ),
        ],
      );

      expect(
        () => ProjectValidator.validate(manifest),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rival template requires follow-up flags and victory dialogue', () {
      final manifest = _project(
        trainers: const <ProjectTrainerEntry>[
          ProjectTrainerEntry(
            id: 'lysa',
            name: 'Lysa',
            trainerClass: 'Rival',
            templateKind: ProjectTrainerTemplateKind.rival,
          ),
        ],
      );

      expect(
        () => ProjectValidator.validate(manifest),
        throwsA(isA<ValidationException>()),
      );
    });
  });
}

ProjectManifest _project({
  required List<ProjectTrainerEntry> trainers,
}) {
  return ProjectManifest(
    name: 'trainer_lifecycle_test',
    maps: const <ProjectMapEntry>[],
    tilesets: const <ProjectTilesetEntry>[],
    trainers: trainers,
    dialogues: const <ProjectDialogueEntry>[
      ProjectDialogueEntry(
        id: 'lysa_before',
        name: 'Lysa before',
        relativePath: 'dialogues/lysa_before.yarn',
      ),
      ProjectDialogueEntry(
        id: 'lysa_victory',
        name: 'Lysa victory',
        relativePath: 'dialogues/lysa_victory.yarn',
      ),
      ProjectDialogueEntry(
        id: 'lysa_defeat',
        name: 'Lysa defeat',
        relativePath: 'dialogues/lysa_defeat.yarn',
      ),
    ],
    surfaceCatalog: ProjectSurfaceCatalog(),
  );
}
```

### `packages/map_editor/lib/src/ui/panels/trainer_library_panel_lifecycle_widgets.dart`

```dart
part of 'trainer_library_panel.dart';

class _TrainerLifecycleEditor extends StatelessWidget {
  const _TrainerLifecycleEditor({
    required this.createMode,
    required this.dialogues,
    required this.templateKind,
    required this.rematchPolicy,
    required this.preBattleDialogueId,
    required this.victoryDialogueId,
    required this.defeatDialogueId,
    required this.onSelectTemplate,
    required this.onSelectRematchPolicy,
    required this.onSelectPreBattleDialogue,
    required this.onSelectVictoryDialogue,
    required this.onSelectDefeatDialogue,
  });

  final bool createMode;
  final List<ProjectDialogueEntry> dialogues;
  final ProjectTrainerTemplateKind? templateKind;
  final ProjectTrainerRematchPolicy? rematchPolicy;
  final String? preBattleDialogueId;
  final String? victoryDialogueId;
  final String? defeatDialogueId;
  final ValueChanged<ProjectTrainerTemplateKind?> onSelectTemplate;
  final ValueChanged<ProjectTrainerRematchPolicy?> onSelectRematchPolicy;
  final ValueChanged<String?> onSelectPreBattleDialogue;
  final ValueChanged<String?> onSelectVictoryDialogue;
  final ValueChanged<String?> onSelectDefeatDialogue;

  String get _keyPrefix => createMode
      ? 'trainer-library-create-lifecycle'
      : 'trainer-library-edit-lifecycle';

  @override
  Widget build(BuildContext context) {
    final sortedDialogues = dialogues.toList(growable: false)
      ..sort((left, right) => left.name.compareTo(right.name));
    final dialogueItems = <PokeMapDropdownItem<String>>[
      const PokeMapDropdownItem<String>(
        value: '',
        label: 'Aucun dialogue',
      ),
      for (final dialogue in sortedDialogues)
        PokeMapDropdownItem<String>(
          value: dialogue.id,
          label: '${dialogue.name} · ${dialogue.id}',
        ),
    ];

    return PokeMapCard(
      key: Key('$_keyPrefix-card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const PokeMapSectionHeader(
            title: 'Cycle de vie du dresseur',
            description:
                'Choisissez un preset, les dialogues guidés et la politique de réaffrontement.',
          ),
          PokeMapDropdownField<String>(
            key: Key('$_keyPrefix-template-dropdown'),
            label: 'Template auteur',
            value: switch (templateKind) {
              ProjectTrainerTemplateKind.gymLeader => 'gym_leader',
              ProjectTrainerTemplateKind.rival => 'rival',
              null => '',
            },
            items: const <PokeMapDropdownItem<String>>[
              PokeMapDropdownItem<String>(
                value: '',
                label: 'Dresseur générique',
              ),
              PokeMapDropdownItem<String>(
                value: 'gym_leader',
                label: 'Champion d’Arène',
              ),
              PokeMapDropdownItem<String>(
                value: 'rival',
                label: 'Rival / suivi narratif',
              ),
            ],
            onChanged: (value) => onSelectTemplate(
              switch (value) {
                'gym_leader' => ProjectTrainerTemplateKind.gymLeader,
                'rival' => ProjectTrainerTemplateKind.rival,
                _ => null,
              },
            ),
          ),
          const SizedBox(height: 10),
          PokeMapDropdownField<String>(
            key: Key('$_keyPrefix-rematch-dropdown'),
            label: 'Réaffrontement',
            value: rematchPolicy == ProjectTrainerRematchPolicy.allowed
                ? 'allowed'
                : '',
            items: const <PokeMapDropdownItem<String>>[
              PokeMapDropdownItem<String>(
                value: '',
                label: 'Combat unique (par défaut)',
              ),
              PokeMapDropdownItem<String>(
                value: 'allowed',
                label: 'Réaffrontement autorisé',
              ),
            ],
            onChanged: (value) => onSelectRematchPolicy(
              value == 'allowed' ? ProjectTrainerRematchPolicy.allowed : null,
            ),
          ),
          const SizedBox(height: 10),
          PokeMapDropdownField<String>(
            key: Key('$_keyPrefix-pre-battle-dropdown'),
            label: 'Dialogue avant combat',
            value: preBattleDialogueId ?? '',
            items: dialogueItems,
            onChanged: (value) =>
                onSelectPreBattleDialogue(value.isEmpty ? null : value),
          ),
          const SizedBox(height: 10),
          PokeMapDropdownField<String>(
            key: Key('$_keyPrefix-victory-dropdown'),
            label: 'Dialogue après victoire du joueur',
            value: victoryDialogueId ?? '',
            items: dialogueItems,
            onChanged: (value) =>
                onSelectVictoryDialogue(value.isEmpty ? null : value),
          ),
          const SizedBox(height: 10),
          PokeMapDropdownField<String>(
            key: Key('$_keyPrefix-defeat-dropdown'),
            label: 'Dialogue après défaite du joueur (optionnel)',
            value: defeatDialogueId ?? '',
            items: dialogueItems,
            onChanged: (value) =>
                onSelectDefeatDialogue(value.isEmpty ? null : value),
          ),
          if (dialogues.isEmpty) ...[
            const SizedBox(height: 8),
            const Text(
              'Créez d’abord un dialogue dans la bibliothèque pour relier ce cycle de vie.',
            ),
          ],
        ],
      ),
    );
  }
}
```

### `packages/map_runtime/lib/src/application/runtime_trainer_lifecycle_policy.dart`

```dart
import 'package:map_core/map_core.dart';

/// Action autorisée avant de confier le combat au bridge runtime.
enum RuntimeTrainerInteractionDisposition {
  battle,
  dialogueThenBattle,
  dialogueOnly,
  blocked,
}

enum RuntimeTrainerPostBattleResult {
  victory,
  defeat,
}

final class RuntimeTrainerInteractionPlan {
  const RuntimeTrainerInteractionPlan({
    required this.disposition,
    this.dialogue,
  });

  final RuntimeTrainerInteractionDisposition disposition;
  final DialogueRef? dialogue;
}

/// Résout le cycle de vie sans dépendre de Flame.
///
/// Le flag persistant `trainer_defeated:<id>` est fourni par l'appelant via
/// [isDefeated]. Une valeur `null` de [ProjectTrainerEntry.rematchPolicy]
/// conserve le comportement historique one-shot ; seule la valeur explicite
/// `allowed` autorise un nouveau combat.
RuntimeTrainerInteractionPlan resolveRuntimeTrainerInteractionPlan({
  required ProjectTrainerEntry trainer,
  required MapEntityNpcData npc,
  required bool isDefeated,
}) {
  if (isDefeated) {
    final dialogue = _trainerDialogueRef(
          trainer.victoryDialogueId,
        ) ??
        npc.defeatDialogueRef;
    final rematchAllowed =
        trainer.rematchPolicy == ProjectTrainerRematchPolicy.allowed;
    if (rematchAllowed) {
      return RuntimeTrainerInteractionPlan(
        disposition: dialogue == null
            ? RuntimeTrainerInteractionDisposition.battle
            : RuntimeTrainerInteractionDisposition.dialogueThenBattle,
        dialogue: dialogue,
      );
    }
    return RuntimeTrainerInteractionPlan(
      disposition: dialogue == null
          ? RuntimeTrainerInteractionDisposition.blocked
          : RuntimeTrainerInteractionDisposition.dialogueOnly,
      dialogue: dialogue,
    );
  }

  final dialogue = _trainerDialogueRef(
        trainer.preBattleDialogueId,
      ) ??
      npc.dialogue;
  return RuntimeTrainerInteractionPlan(
    disposition: dialogue == null
        ? RuntimeTrainerInteractionDisposition.battle
        : RuntimeTrainerInteractionDisposition.dialogueThenBattle,
    dialogue: dialogue,
  );
}

/// Choisit le hook post-combat authoré pour un combat trainer direct.
///
/// Le fallback NPC de victoire reste accepté pour préserver les projets
/// historiques. La défaite joueur n'avait pas de fallback historique : elle
/// reste donc strictement opt-in via le contrat trainer.
DialogueRef? resolveRuntimeTrainerPostBattleDialogue({
  required ProjectTrainerEntry trainer,
  required MapEntityNpcData npc,
  required RuntimeTrainerPostBattleResult result,
}) {
  return switch (result) {
    RuntimeTrainerPostBattleResult.victory =>
      _trainerDialogueRef(trainer.victoryDialogueId) ?? npc.defeatDialogueRef,
    RuntimeTrainerPostBattleResult.defeat =>
      _trainerDialogueRef(trainer.defeatDialogueId),
  };
}

DialogueRef? _trainerDialogueRef(String? dialogueId) {
  final normalized = dialogueId?.trim();
  return normalized == null || normalized.isEmpty
      ? null
      : DialogueRef(dialogueId: normalized);
}
```

### `packages/map_runtime/test/runtime_trainer_lifecycle_policy_test.dart`

```dart
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('runtime trainer lifecycle policy', () {
    const npc = MapEntityNpcData(
      displayName: 'Lysa',
      dialogue: DialogueRef(dialogueId: 'npc_before'),
      trainerId: 'lysa',
      defeatDialogueRef: DialogueRef(dialogueId: 'npc_victory'),
    );

    test('undefeated trainer shows pre-battle dialogue then battles', () {
      const trainer = ProjectTrainerEntry(
        id: 'lysa',
        name: 'Lysa',
        trainerClass: 'Rival',
      );

      final plan = resolveRuntimeTrainerInteractionPlan(
        trainer: trainer,
        npc: npc,
        isDefeated: false,
      );

      expect(
        plan.disposition,
        RuntimeTrainerInteractionDisposition.dialogueThenBattle,
      );
      expect(plan.dialogue?.dialogueId, 'npc_before');
    });

    test('one-shot defeated trainer only shows victory dialogue', () {
      const trainer = ProjectTrainerEntry(
        id: 'lysa',
        name: 'Lysa',
        trainerClass: 'Rival',
      );

      final plan = resolveRuntimeTrainerInteractionPlan(
        trainer: trainer,
        npc: npc,
        isDefeated: true,
      );

      expect(
        plan.disposition,
        RuntimeTrainerInteractionDisposition.dialogueOnly,
      );
      expect(plan.dialogue?.dialogueId, 'npc_victory');
    });

    test('allowed rematch shows victory dialogue then battles again', () {
      const trainer = ProjectTrainerEntry(
        id: 'lysa',
        name: 'Lysa',
        trainerClass: 'Rival',
        rematchPolicy: ProjectTrainerRematchPolicy.allowed,
      );

      final plan = resolveRuntimeTrainerInteractionPlan(
        trainer: trainer,
        npc: npc,
        isDefeated: true,
      );

      expect(
        plan.disposition,
        RuntimeTrainerInteractionDisposition.dialogueThenBattle,
      );
      expect(plan.dialogue?.dialogueId, 'npc_victory');
    });

    test('trainer lifecycle dialogue ids override NPC fallback refs', () {
      const trainer = ProjectTrainerEntry(
        id: 'lysa',
        name: 'Lysa',
        trainerClass: 'Rival',
        preBattleDialogueId: 'trainer_before',
        victoryDialogueId: 'trainer_victory',
        defeatDialogueId: 'trainer_defeat',
      );

      expect(
        resolveRuntimeTrainerInteractionPlan(
          trainer: trainer,
          npc: npc,
          isDefeated: false,
        ).dialogue?.dialogueId,
        'trainer_before',
      );
      expect(
        resolveRuntimeTrainerPostBattleDialogue(
          trainer: trainer,
          npc: npc,
          result: RuntimeTrainerPostBattleResult.victory,
        )?.dialogueId,
        'trainer_victory',
      );
      expect(
        resolveRuntimeTrainerPostBattleDialogue(
          trainer: trainer,
          npc: npc,
          result: RuntimeTrainerPostBattleResult.defeat,
        )?.dialogueId,
        'trainer_defeat',
      );
    });

    test('missing dialogue falls back to a direct battle or no hook', () {
      const trainer = ProjectTrainerEntry(
        id: 'ace',
        name: 'Ace',
        trainerClass: 'Trainer',
      );

      final initial = resolveRuntimeTrainerInteractionPlan(
        trainer: trainer,
        npc: const MapEntityNpcData(trainerId: 'ace'),
        isDefeated: false,
      );
      final defeated = resolveRuntimeTrainerInteractionPlan(
        trainer: trainer,
        npc: const MapEntityNpcData(trainerId: 'ace'),
        isDefeated: true,
      );

      expect(
        initial.disposition,
        RuntimeTrainerInteractionDisposition.battle,
      );
      expect(
        defeated.disposition,
        RuntimeTrainerInteractionDisposition.blocked,
      );
      expect(
        resolveRuntimeTrainerPostBattleDialogue(
          trainer: trainer,
          npc: const MapEntityNpcData(trainerId: 'ace'),
          result: RuntimeTrainerPostBattleResult.defeat,
        ),
        isNull,
      );
    });
  });
}
```

### `selbrume/dialogues/lysa_port_after_loss.yarn`

```yarn
title: RivalAfterLoss
tags: selbrume chapter-1 rival defeat
---
Lysa: Tu manques encore d'expérience, mais la brume n'attendra pas.
Lysa: Le chemin des marais reste ouvert : entraîne-toi et suis-moi quand tu seras prêt.
===
```

### `selbrume/dialogues/lysa_port_after_win.yarn`

```yarn
title: RivalAfterWin
tags: selbrume chapter-1 rival victory
---
Lysa: D'accord, tu as gagné mon respect. Tu peux tenir le rythme ; je pars devant reconnaître les marais.
Lysa: Prends le Badge des Brisants. Il autorise Surf : le chenal du Passage des Dames ne te bloquera plus.
===
```

### `docs/superpowers/plans/2026-07-26-rm-027-trainer-lifecycle-templates-v0.md`

```markdown
# RM-027 Trainer Lifecycle & Templates V0 Implementation Plan

**Goal:** fermer FG-140, FG-141, FG-144 et FG-145 avec une politique de
défaite persistante, des dialogues de cycle de vie réellement consommés et des
presets trainer/gym/rival authorables sans JSON.

**Architecture:** `map_core` porte les métadonnées sérialisées et leurs
invariants ; `map_editor` expose templates, rematch et pickers de dialogues ;
`map_runtime` résout un plan d’interaction pur puis l’applique dans
`PlayableMapGame` avant et après combat. Le flag canonique
`trainer_defeated:<id>` reste la vérité persistante.

**Non-goals:** IA de rematch évolutive, scaling d’équipe, calendrier de rematch,
warp/cutscene automatique hors scénario, génération automatique de fichiers
Yarn.

### Task 1: Contrat lifecycle core

- [x] Ajouter template, rematch et trois hooks dialogue optionnels.
- [x] Préserver les JSON historiques byte-for-byte.
- [x] Valider les références dialogue et les invariants gym/rival.

### Task 2: Policy runtime

- [x] Résoudre interaction initiale, déjà battue et rematch.
- [x] Ouvrir le dialogue pré-combat puis lancer exactement un battle.
- [x] Ouvrir le dialogue victoire/défaite après publication du résultat.
- [x] Conserver le flag defeated idempotent et le guard one-shot.

### Task 3: Authoring no-code et templates

- [x] Transporter tous les champs dans create/update/notifier.
- [x] Ajouter les presets Trainer, Gym Leader et Rival.
- [x] Ajouter le picker de politique rematch.
- [x] Ajouter trois pickers de dialogues issus du manifeste.
- [x] Valider inline les contrats gym/rival.

### Task 4: Selbrume et clôture

- [x] Promouvoir Lysa comme template rival sans saisie d’ID ou de script brut
      dans l’éditeur.
- [x] Tests core, use cases, widget, policy runtime et intégration ciblée.
- [x] Tests/analyzes package-scoped et smokes.
- [x] Evidence Pack FG-140/141/144/145.
- [x] Commit isolé et état Git final.
```
