# Evidence Pack — Phase 1, fin de jeu jouable et état NPC

Date : 2026-07-26  
Phase : `Phase 1 — boucle narrative terminale`  
Lots : `RM-010`, `RM-011`, `RM-012`, `RM-013`, `RM-014`, `RM-015`  
Gaps principaux : `FG-092`, `FG-145`, `FG-147`, `FG-182`  
Roadmap de référence :
`reports/gameplay/fg_000_remediation_and_personalization_roadmap.md`

## 1. Verdict

**Phase 1 implémentée et gate finale verte.**

Statuts proposés, sans modifier la roadmap canonique :

| Élément | Verdict proposé | Justification |
|---|---|---|
| `RM-010` | `DONE` | contrat `FinishGame` V1 sérialisable, validé et diagnostiqué |
| `RM-011` | `DONE` | authoring guidé Editor, sans saisie d'identifiants bruts |
| `RM-012` | `DONE` | exécution Runtime, persistance, unicité par session et handoff Player/Hub |
| `RM-015` / `FG-092` V0 | `DONE` | présence et déplacement NPC typés, authoring et runtime couverts |
| `RM-013` / `FG-145` | `DONE` | scène terminale Selbrume réellement auteurée et reçue par le runtime |
| `RM-014` / critère MVP 19 | `DONE` | golden E2E macOS histoire → sauvegarde → reprise → fin → crédits → Hub |
| `FG-147` V0 | `DONE` | une fin de campagne auteurée, persistée et présentée de bout en bout |
| `FG-182` global | `PARTIAL` | le critère 19 est prouvé ; la clôture des 19 critères reste le lot `RM-069` |
| `FG-185` | inchangé | dépend toujours de la gate de release de la phase 7A |

La Phase 1 n'implémente pas encore le `Personalization Hub`, la vidéo
d'introduction, ni la personnalisation des polices : ces sujets restent dans
les phases dédiées de la roadmap.

## 2. Audit initial

### 2.1 État fonctionnel avant Phase 1

L'audit de Phase 0 avait établi les manques suivants :

1. aucun contrat canonique permettant à une scène auteurée de terminer le jeu ;
2. aucun formulaire no-code pour déclarer une fin, son résultat, ses crédits et
   sa politique de reprise ;
3. aucune coordination runtime garantissant persistance avant présentation,
   unicité par session et absence de faux succès si la sauvegarde échoue ;
4. aucune scène Selbrume terminale reliée au système réellement joué ;
5. aucun parcours automatisé traversant Hub, Player, histoire, sauvegarde,
   reprise, fin, crédits et retour Hub ;
6. des mutations NPC encore fragmentées entre conventions implicites.

### 2.2 État Git initial préservé

Ces changements étaient déjà présents au début de la phase et appartiennent à
l'utilisateur :

```text
 M apps/pokemap_hub/lib/src/ui/hub_app.dart
 M apps/pokemap_hub/lib/src/ui/hub_shell.dart
 M apps/pokemap_hub/test/ui/hub_app_player_navigation_test.dart
 M apps/pokemap_hub/test/ui/hub_preferences_store_test.dart
 M apps/pokemap_hub/test/ui/hub_shell_test.dart
 M packages/map_player_ui/lib/src/localization/player_localizations.dart
 M packages/map_player_ui/lib/src/preferences/player_preferences.dart
```

Ils n'ont été ni réécrits, ni restaurés, ni ajoutés à l'index par les commits
de Phase 1. Les validations finales les ont néanmoins inclus tels quels.

### 2.3 Passes et coordination

Aucun sub-agent n'a été lancé : l'instruction de coordination active
interdisait la délégation sans demande explicite de l'utilisateur. Les passes
ont été conduites séparément par couche :

| Passe | Verdict |
|---|---|
| contrat et sérialisation Core | PASS |
| authoring no-code Editor | PASS |
| coordination Runtime/Player/Hub | PASS |
| état NPC Core/Editor/Runtime | PASS |
| scène terminale Selbrume | PASS |
| golden E2E macOS | PASS |
| régressions complètes package par package | PASS en mode reproductible |
| auto-critique et hygiène Git | PASS avec risques résiduels documentés |

## 3. Lots et commits

| Lot | Commit | Résultat |
|---|---|---|
| `RM-010` | `f636c838c` | `feat(narrative): add finish game contract v1` |
| `RM-011` | `c76a63ec1` | `feat(editor): author finish game without raw ids` |
| `RM-012` | `96228fc7d` | `feat(runtime): wire authored game completion` |
| `RM-015` | `3ddaf64d8` | `feat(narrative): unify npc state commands` |
| `RM-013` | `ff7e7e417` | `feat(selbrume): author terminal game completion` |
| `RM-014` | `b05149005` | `test(hub): prove story to credits golden flow` |
| correctif de preuve | `4e56cc5df` | `test(selbrume): refresh phase one manifest proof` |

Chaque lot produit a donc son commit propre. Le correctif découvert par la
gate exhaustive possède également son commit isolé.

## 4. Décisions et non-objectifs

### 4.1 Décisions

- `FinishGame` est une conséquence de scène typée de `map_core`.
- Le résultat, les textes de résultat/crédits, l'auteur, la politique de
  persistance et la politique de reprise sont des données auteurées.
- La persistance réussie précède toujours la présentation de fin.
- Un échec de sauvegarde ne produit ni écran de succès ni checkpoint complété.
- Une même session ne peut émettre qu'une seule demande de fin.
- `returnToHub` rend la sauvegarde terminale non reprenable après retour.
- Les références NPC sont choisies dans l'Editor ; l'utilisateur normal ne
  saisit pas d'identifiant brut.
- `setNpcPresence` persiste l'état ; `moveNpc` déplace un NPC présent vers un
  warp auteur et remonte `completed` ou `blocked`.
- Le golden E2E déclenche les jalons par déplacement réel du joueur et observe
  le `GameState`; il ne mutile pas directement l'état pour simuler la réussite.

### 4.2 Non-objectifs

- plusieurs fins/galeries de fins ;
- New Game+ ;
- cinématique vidéo d'introduction ;
- personnalisation visuelle ou typographique ;
- migration dédiée d'un ancien format de metadata NPC ;
- simulation hors écran de `moveNpc` ;
- fermeture globale de `FG-182` ou gate de release `FG-185`.

## 5. Inventaire exhaustif des fichiers de Phase 1

Le diff `2c49a6ee2..4e56cc5df` contient 68 fichiers, 5 259 insertions et
131 suppressions.

### 5.1 Hub et fixture E2E

```text
apps/pokemap_hub/integration_test/runtime_owned_player_flow_test.dart
apps/pokemap_hub/lib/src/player/hub_player_save_gateway.dart
apps/pokemap_hub/test/fixtures/runtime_owned_player_game/project/maps/runtime_harbor.json
apps/pokemap_hub/test/fixtures/runtime_owned_player_game/project/project.json
apps/pokemap_hub/test/player/hub_player_save_gateway_test.dart
apps/pokemap_hub/test/support/runtime_owned_player_package_fixture.dart
apps/pokemap_hub/test/support/runtime_owned_player_package_fixture_test.dart
```

### 5.2 Hôte jouable

```text
examples/playable_runtime_host/lib/src/evaluation/driver/evaluation_game_fixtures.dart
examples/playable_runtime_host/lib/src/evaluation/driver/selbrume_evaluation_driver.dart
examples/playable_runtime_host/test/selbrume_event_v2_promoted_project_test.dart
examples/playable_runtime_host/test/selbrume_player_journey_e2e_test.dart
```

### 5.3 Core

```text
packages/map_core/lib/map_core.dart
packages/map_core/lib/src/authoring/scene_authoring_operations.dart
packages/map_core/lib/src/diagnostics/scene_diagnostics.dart
packages/map_core/lib/src/models/narrative_command_descriptor.dart
packages/map_core/lib/src/models/scene_consequence.dart
packages/map_core/lib/src/models/scene_finish_game_contract.dart (créé)
packages/map_core/lib/src/models/scene_interactive_command.dart
packages/map_core/lib/src/operations/narrative_symbolic_reachability_solver.dart
packages/map_core/lib/src/read_models/narrative_command_catalog.dart
packages/map_core/lib/src/runtime/scene_runtime_dry_run_preview.dart
packages/map_core/test/narrative_command_catalog_test.dart
packages/map_core/test/narrative_command_contract_parity_test.dart
packages/map_core/test/project_capability_truth_test.dart
packages/map_core/test/scene_diagnostics_test.dart
packages/map_core/test/scene_finish_game_contract_test.dart (créé)
packages/map_core/test/scene_npc_state_command_test.dart (créé)
packages/map_core/test/scene_runtime_dry_run_preview_test.dart
```

### 5.4 Editor

```text
packages/map_editor/lib/src/application/services/narrative_template_catalog.dart
packages/map_editor/lib/src/ui/canvas/events_v2/event_builder_v2_product_route.dart
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
packages/map_editor/lib/src/ui/canvas/scenes/scene_action_builder.dart
packages/map_editor/test/narrative_template_catalog_test.dart
packages/map_editor/test/scene_action_builder_test.dart
packages/map_editor/test/selbrume_npc_state_commands_test.dart (créé)
```

### 5.5 Gameplay et Player UI

```text
packages/map_gameplay/lib/src/narrative_event_execution_coordinator.dart
packages/map_player_ui/lib/src/player/runtime_player_surface_router.dart
```

### 5.6 Runtime

```text
packages/map_runtime/lib/map_runtime.dart
packages/map_runtime/lib/src/application/narrative_scene_runtime_execution.dart
packages/map_runtime/lib/src/application/npc_runtime_presence.dart
packages/map_runtime/lib/src/application/scene_runtime/narrative_game_completion_runtime_coordinator.dart (créé)
packages/map_runtime/lib/src/application/scene_runtime/scene_consequence_runtime_write_result.dart
packages/map_runtime/lib/src/application/scene_runtime/scene_consequence_runtime_writer.dart
packages/map_runtime/lib/src/application/scene_runtime/scene_finish_game_runtime_mapper.dart (créé)
packages/map_runtime/lib/src/application/scene_runtime/scene_game_completion_metadata.dart (créé)
packages/map_runtime/lib/src/application/scene_runtime/scene_interactive_command_runtime_executor.dart
packages/map_runtime/lib/src/application/scene_runtime/scene_npc_state_metadata.dart (créé)
packages/map_runtime/lib/src/application/scripted_entity_movement_controller.dart
packages/map_runtime/lib/src/player/runtime_player_coordinator.dart
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
packages/map_runtime/lib/src/session/game_session_contract.dart
packages/map_runtime/lib/src/session/playable_map_game_session_runtime.dart
packages/map_runtime/test/narrative_command_runtime_parity_test.dart
packages/map_runtime/test/narrative_game_completion_runtime_coordinator_test.dart (créé)
packages/map_runtime/test/narrative_scene_runtime_execution_test.dart
packages/map_runtime/test/npc_runtime_presence_test.dart
packages/map_runtime/test/player/runtime_player_coordinator_completion_test.dart
packages/map_runtime/test/player/support/runtime_player_test_harness.dart
packages/map_runtime/test/scene_consequence_runtime_writer_test.dart
packages/map_runtime/test/scene_finish_game_runtime_mapper_test.dart (créé)
packages/map_runtime/test/scene_interactive_command_runtime_executor_test.dart
packages/map_runtime/test/scripted_entity_movement_controller_test.dart
packages/map_runtime/test/selbrume_terminal_scene_completion_contract_test.dart (créé)
```

### 5.7 Selbrume et rapports de lot

```text
reports/gameplay/fg_092_npc_state_commands_v0.md (créé)
reports/gameplay/fg_145_147_selbrume_terminal_scene_v0.md (créé)
reports/gameplay/fg_147_182_story_to_credits_golden_e2e_v0.md (créé)
selbrume/.pokemap/validation/narrative_runtime_smoke_receipt.json
selbrume/project.json
```

Le présent Evidence Pack est créé par le commit documentaire de clôture. Le
rapport `fg_092_npc_state_commands_v0.md` est aussi modifié pour intégrer la
gate Editor séquentielle finale.

## 6. Zones précises modifiées

| Zone | Changement |
|---|---|
| modèle JSON | nouveau contrat `FinishGame`, parse/toJson, diagnostics et dry-run |
| catalogue narratif | descripteurs `finishGame`, `setNpcPresence`, `moveNpc` |
| Editor | templates et builders guidés avec références projet |
| Runtime | mapping vers `GameCompletionRequest`, écriture persistante, coordination et unicité |
| Player/Hub | transmission de la fin, écran résultat/crédits, retour et politique de reprise |
| NPC runtime | présence persistée, remontage et mouvement scripté vers warp |
| Selbrume | conséquence terminale dans `scene_ending_port` et receipt rafraîchi |
| golden fixture | deux triggers physiques, jalon narratif, fin canonique et parité Selbrume |
| preuves | tests unitaires, intégration runtime, voyage hôte et E2E macOS |

Les diffs détaillés sont conservés dans les sept commits de la section 3.

## 7. Vérifications finales exactes

### 7.1 Gate package par package

```bash
cd packages/map_core
dart test -r failures-only
dart analyze
```

```text
+4462: All tests passed!
No issues found!
```

```bash
cd packages/map_runtime
flutter test -r failures-only
flutter analyze
```

```text
+2180 ~1: 1 skipped test.
+2180 ~1: All other tests passed!
No issues found! (ran in 4.3s)
```

```bash
cd packages/map_editor
flutter test --concurrency=1 -r failures-only
flutter analyze
```

```text
+4151: All tests passed!
No issues found! (ran in 5.8s)
```

```bash
cd packages/map_player_ui
flutter test -r failures-only
flutter analyze
```

```text
+73: All tests passed!
No issues found! (ran in 3.6s)
```

```bash
cd examples/playable_runtime_host
flutter test --concurrency=1 -r failures-only
flutter analyze
```

```text
+254 ~2: 2 skipped tests.
+254 ~2: All other tests passed!
No issues found! (ran in 5.9s)
```

```bash
cd apps/pokemap_hub
flutter test -r failures-only
flutter analyze
```

```text
+139: All tests passed!
No issues found! (ran in 3.2s)
```

### 7.2 Golden desktop et build

```bash
cd apps/pokemap_hub
flutter test integration_test/runtime_owned_player_flow_test.dart \
  -d macos -r failures-only
flutter build macos --debug
```

```text
+1: All tests passed!
✓ Built build/macos/Build/Products/Debug/PokeMap Hub.app
```

Le golden vérifie : installation du package, ouverture Hub/Player, nouvelle
partie, boutique/équipe/soin, jalon narratif physique, sauvegarde, retour titre,
reprise et restauration, trigger terminal physique, résultat, checkpoint
complété, crédits, retour Hub, puis désactivation de Continuer.

### 7.3 Incident de gate et résolution

La première passe hôte exhaustive a trouvé une empreinte de manifeste périmée :

```text
Expected: sha256:d3a8d38e05fab52e8e10b2bc5538cf4bc2892cc0862f8cf17f6f275fb56e3258
Actual:   sha256:5aafa49a34a83ee92e4c310a9089c40c36d9b719abb272f8cfbe8e9cfc62a8ac
+253 ~2 -1: Some tests failed.
```

La nouvelle empreinte correspond au manifeste contenant la fin canonique
RM-013. Après correction :

```bash
flutter test test/selbrume_event_v2_promoted_project_test.dart \
  -r failures-only
flutter analyze
```

```text
+1: All tests passed!
No issues found! (ran in 6.1s)
```

Une seconde passe concurrente a ensuite produit deux timeouts sous charge, sans
assertion métier fausse :

```text
Timed out waiting for Battle transition completion
EvaluationDriverFailure(game.start): Timed out after 3000 headless ticks.
+252 ~2 -2: Some tests failed.
```

Diagnostic isolé :

```bash
flutter test test/selbrume_player_journey_e2e_test.dart -r failures-only
```

```text
+6: All tests passed!
```

La suite hôte complète séquentielle est finalement verte (`+254 ~2`) et
constitue la preuve reproductible retenue. Aucun timeout n'a été augmenté et
aucun comportement n'a été assoupli pour obtenir ce résultat.

### 7.4 Hygiène

```bash
git diff --check
git status --short --untracked-files=all
```

`git diff --check` doit rester à exit `0`. Le commit documentaire ne doit
contenir que les deux rapports de clôture. L'état final attendu puis contrôlé
après commit est exactement la liste des sept fichiers utilisateur de la
section 2.2.

## 8. Contenu des fichiers créés

Les Evidence Packs de lots contiennent leurs inventaires, commandes, zones
modifiées et annexes de contenu :

- `reports/gameplay/fg_092_npc_state_commands_v0.md` pour `RM-015` ;
- `reports/gameplay/fg_145_147_selbrume_terminal_scene_v0.md` pour `RM-013` ;
- `reports/gameplay/fg_147_182_story_to_credits_golden_e2e_v0.md` pour `RM-014`.

Pour `RM-010` et `RM-012`, le contenu intégral des nouveaux fichiers de contrat
et de coordination figure en annexe A du présent rapport. Les fichiers créés
par `RM-015` et `RM-013` restent reproduits dans leurs Evidence Packs de lot
afin d'éviter une seconde copie divergente. Le présent fichier constitue son
propre contenu intégral.

## 9. Auto-critique et risques résiduels

1. **Concurrence des tests lourds.** Les suites Editor et hôte sont fiables en
   séquentiel mais peuvent fluctuer lorsque performances, goldens et plusieurs
   runtimes Selbrume tournent simultanément. La CI devrait matérialiser cette
   contrainte.
2. **Une seule fin V0.** Le contrat autorise un identifiant de fin, mais aucune
   galerie multi-fins ou New Game+ n'est fournie.
3. **Politique `returnToHub`.** Elle invalide volontairement Continuer après la
   fin ; un futur produit pourra vouloir conserver une sauvegarde
   post-générique distincte.
4. **Metadata NPC.** Le stockage est stable dans le `GameState`, sans migration
   dédiée si le format de référence change.
5. **`moveNpc` hors écran.** Le runtime bloque volontairement le déplacement
   d'un NPC situé sur une map inactive.
6. **Fixture E2E compacte.** Elle prouve l'intégration exacte et la parité du
   contrat Selbrume, mais ne remplace pas le long voyage Selbrume ; les deux
   preuves sont donc conservées.
7. **Roadmap non modifiée.** Les promotions `DONE` restent des propositions
   jusqu'à une demande explicite de mise à jour de la roadmap canonique.
8. **Arbre utilisateur dirty.** Les sept fichiers locaux préexistants
   demeurent hors commits ; ils sont verts aujourd'hui mais restent sous la
   responsabilité de leur auteur.

## Annexe A — nouveaux fichiers RM-010 / RM-012

Le contenu intégral est ajouté ci-dessous dans des blocs Dart afin que ce
rapport satisfasse l'exigence de reproductibilité sans dépendre du diff Git.


### A.1 `packages/map_core/lib/src/models/scene_finish_game_contract.dart`

```dart
import 'dart:collection';

import 'package:meta/meta.dart' show immutable;

const int sceneFinishGameContractVersion = 1;

enum SceneGameCompletionOutcome { completed, victory, alternateEnding }

enum SceneFinishGameCommitPolicy { persistBeforePresentation }

enum ScenePostGamePolicy { continueGame, returnToTitle, returnToHub }

/// Authorable text with a mandatory fallback and optional locale overrides.
///
/// Resolution prefers an exact locale, then its language subtag, and finally
/// [fallback]. Locale keys are normalized so `fr_FR` and `fr-FR` are
/// equivalent.
@immutable
final class SceneLocalizedText {
  SceneLocalizedText({
    required String fallback,
    Map<String, String> translations = const {},
  })  : fallback = fallback.trim(),
        translations = UnmodifiableMapView(
          _normalizeTranslations(translations),
        );

  factory SceneLocalizedText.fromJson(Object? json) {
    // V0 legacy authoring stored localizable values as plain strings.
    if (json is String) {
      return SceneLocalizedText(fallback: json);
    }
    if (json is! Map<String, dynamic>) {
      throw const FormatException(
        'SceneLocalizedText must be a string or an object.',
      );
    }
    final fallback = json['fallback'];
    if (fallback is! String) {
      throw const FormatException(
        'SceneLocalizedText.fallback must be a string.',
      );
    }
    final rawTranslations = json['translations'];
    if (rawTranslations != null && rawTranslations is! Map) {
      throw const FormatException(
        'SceneLocalizedText.translations must be an object.',
      );
    }
    final translations = <String, String>{};
    if (rawTranslations is Map) {
      for (final entry in rawTranslations.entries) {
        if (entry.key is! String || entry.value is! String) {
          throw const FormatException(
            'SceneLocalizedText translations must map strings to strings.',
          );
        }
        translations[entry.key as String] = entry.value as String;
      }
    }
    return SceneLocalizedText(
      fallback: fallback,
      translations: translations,
    );
  }

  final String fallback;
  final Map<String, String> translations;

  String resolve(String locale) {
    final normalized = _normalizeLocale(locale);
    final exact = translations[normalized];
    if (exact != null && exact.isNotEmpty) return exact;
    final separator = normalized.indexOf('-');
    if (separator > 0) {
      final language = translations[normalized.substring(0, separator)];
      if (language != null && language.isNotEmpty) return language;
    }
    return fallback;
  }

  Map<String, dynamic> toJson() => {
        'fallback': fallback,
        if (translations.isNotEmpty) 'translations': translations,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SceneLocalizedText &&
          other.fallback == fallback &&
          _mapsEqual(other.translations, translations);

  @override
  int get hashCode => Object.hash(fallback, _mapHash(translations));
}

@immutable
final class SceneFinishGameResult {
  SceneFinishGameResult({
    required this.title,
    required this.summary,
    List<SceneLocalizedText> details = const [],
  }) : details = List.unmodifiable(details);

  factory SceneFinishGameResult.fromJson(Object? json) {
    if (json is! Map<String, dynamic>) {
      throw const FormatException('Finish Game result must be an object.');
    }
    final details = json['details'];
    if (details != null && details is! List) {
      throw const FormatException('Finish Game result.details must be a list.');
    }
    return SceneFinishGameResult(
      title: SceneLocalizedText.fromJson(json['title']),
      summary: SceneLocalizedText.fromJson(json['summary']),
      details: [
        for (final detail in (details as List? ?? const []))
          SceneLocalizedText.fromJson(detail),
      ],
    );
  }

  final SceneLocalizedText title;
  final SceneLocalizedText summary;
  final List<SceneLocalizedText> details;

  Map<String, dynamic> toJson() => {
        'title': title.toJson(),
        'summary': summary.toJson(),
        if (details.isNotEmpty)
          'details': [for (final detail in details) detail.toJson()],
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SceneFinishGameResult &&
          other.title == title &&
          other.summary == summary &&
          _listsEqual(other.details, details);

  @override
  int get hashCode => Object.hash(title, summary, Object.hashAll(details));
}

@immutable
final class SceneFinishGameCredits {
  SceneFinishGameCredits({
    required this.title,
    required String author,
    List<String> contributors = const [],
    List<String> licenses = const [],
    required this.endingLabel,
    this.skippable = true,
  })  : author = author.trim(),
        contributors = List.unmodifiable(
          contributors.map((value) => value.trim()),
        ),
        licenses = List.unmodifiable(licenses.map((value) => value.trim()));

  factory SceneFinishGameCredits.fromJson(Object? json) {
    if (json is! Map<String, dynamic>) {
      throw const FormatException('Finish Game credits must be an object.');
    }
    return SceneFinishGameCredits(
      title: SceneLocalizedText.fromJson(json['title']),
      author: _readString(json, 'author'),
      contributors: _readStringList(json, 'contributors'),
      licenses: _readStringList(json, 'licenses'),
      endingLabel: SceneLocalizedText.fromJson(json['endingLabel']),
      skippable: _readBool(json, 'skippable', fallback: true),
    );
  }

  final SceneLocalizedText title;
  final String author;
  final List<String> contributors;
  final List<String> licenses;
  final SceneLocalizedText endingLabel;
  final bool skippable;

  Map<String, dynamic> toJson() => {
        'title': title.toJson(),
        'author': author,
        if (contributors.isNotEmpty) 'contributors': contributors,
        if (licenses.isNotEmpty) 'licenses': licenses,
        'endingLabel': endingLabel.toJson(),
        'skippable': skippable,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SceneFinishGameCredits &&
          other.title == title &&
          other.author == author &&
          _listsEqual(other.contributors, contributors) &&
          _listsEqual(other.licenses, licenses) &&
          other.endingLabel == endingLabel &&
          other.skippable == skippable;

  @override
  int get hashCode => Object.hash(
        title,
        author,
        Object.hashAll(contributors),
        Object.hashAll(licenses),
        endingLabel,
        skippable,
      );
}

Map<String, String> _normalizeTranslations(Map<String, String> values) {
  return {
    for (final entry in values.entries)
      if (entry.key.trim().isNotEmpty && entry.value.trim().isNotEmpty)
        _normalizeLocale(entry.key): entry.value.trim(),
  };
}

String _normalizeLocale(String value) =>
    value.trim().replaceAll('_', '-').toLowerCase();

String _readString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String) {
    throw FormatException('Finish Game $key must be a string.');
  }
  return value;
}

List<String> _readStringList(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) return const [];
  if (value is! List || value.any((entry) => entry is! String)) {
    throw FormatException('Finish Game $key must be a list of strings.');
  }
  return value.cast<String>();
}

bool _readBool(
  Map<String, dynamic> json,
  String key, {
  required bool fallback,
}) {
  final value = json[key];
  if (value == null) return fallback;
  if (value is! bool) {
    throw FormatException('Finish Game $key must be a boolean.');
  }
  return value;
}

bool _mapsEqual<K, V>(Map<K, V> left, Map<K, V> right) {
  if (left.length != right.length) return false;
  for (final entry in left.entries) {
    if (!right.containsKey(entry.key) || right[entry.key] != entry.value) {
      return false;
    }
  }
  return true;
}

int _mapHash(Map<String, String> values) {
  final keys = values.keys.toList()..sort();
  return Object.hashAll(
    keys.map((key) => Object.hash(key, values[key])),
  );
}

bool _listsEqual<T>(List<T> left, List<T> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}
```

### A.2 `packages/map_core/test/scene_finish_game_contract_test.dart`

```dart
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('Scene Finish Game contract V1', () {
    test('round-trips the canonical localized contract', () {
      final consequence = SceneConsequence.finishGame(
        endingId: 'ending_selbrume_saved',
        outcome: SceneGameCompletionOutcome.victory,
        result: SceneFinishGameResult(
          title: SceneLocalizedText(
            fallback: 'Selbrume est sauvée',
            translations: const {
              'en': 'Selbrume is safe',
              'fr': 'Selbrume est sauvée',
            },
          ),
          summary: SceneLocalizedText(
            fallback: 'La brume se retire enfin.',
            translations: const {'en': 'The mist finally clears.'},
          ),
          details: [
            SceneLocalizedText(fallback: 'Le phare brille de nouveau.'),
          ],
        ),
        credits: SceneFinishGameCredits(
          title: SceneLocalizedText(fallback: 'Crédits'),
          author: 'PokeMap',
          endingLabel: SceneLocalizedText(fallback: 'Fin — Selbrume sauvée'),
          contributors: const ['Équipe PokeMap'],
          licenses: const ['Assets de démonstration'],
          skippable: true,
        ),
        postGamePolicy: ScenePostGamePolicy.returnToHub,
        label: 'Terminer le jeu',
      );

      expect(consequence.toJson(), {
        'kind': 'finishGame',
        'contractVersion': 1,
        'endingId': 'ending_selbrume_saved',
        'outcome': 'victory',
        'commitPolicy': 'persistBeforePresentation',
        'result': {
          'title': {
            'fallback': 'Selbrume est sauvée',
            'translations': {
              'en': 'Selbrume is safe',
              'fr': 'Selbrume est sauvée',
            },
          },
          'summary': {
            'fallback': 'La brume se retire enfin.',
            'translations': {'en': 'The mist finally clears.'},
          },
          'details': [
            {'fallback': 'Le phare brille de nouveau.'},
          ],
        },
        'credits': {
          'title': {'fallback': 'Crédits'},
          'author': 'PokeMap',
          'contributors': ['Équipe PokeMap'],
          'licenses': ['Assets de démonstration'],
          'endingLabel': {'fallback': 'Fin — Selbrume sauvée'},
          'skippable': true,
        },
        'postGamePolicy': 'returnToHub',
        'label': 'Terminer le jeu',
      });
      expect(
        SceneConsequence.fromJson(consequence.toJson()),
        equals(consequence),
      );
    });

    test('resolves exact locale, language locale, then fallback', () {
      final text = SceneLocalizedText(
        fallback: 'Fin',
        translations: const {
          'en': 'The End',
          'fr-FR': 'Fin française',
        },
      );

      expect(text.resolve('fr-FR'), 'Fin française');
      expect(text.resolve('en-US'), 'The End');
      expect(text.resolve('de-DE'), 'Fin');
    });

    test('migrates the unversioned flat legacy shape to canonical V1', () {
      final decoded = SceneConsequence.fromJson({
        'kind': 'finishGame',
        'endingId': 'ending_legacy',
        'outcome': 'alternateEnding',
        'resultTitle': 'Une autre fin',
        'resultSummary': 'La route change.',
        'resultDetails': ['Le port reste dans la brume.'],
        'creditsTitle': 'Crédits',
        'creditsAuthor': 'Studio',
        'creditsEndingLabel': 'Fin alternative',
        'creditsSkippable': false,
        'postGamePolicy': 'returnToTitle',
      });

      expect(decoded, isA<SceneFinishGameConsequence>());
      expect(decoded.toJson(), {
        'kind': 'finishGame',
        'contractVersion': 1,
        'endingId': 'ending_legacy',
        'outcome': 'alternateEnding',
        'commitPolicy': 'persistBeforePresentation',
        'result': {
          'title': {'fallback': 'Une autre fin'},
          'summary': {'fallback': 'La route change.'},
          'details': [
            {'fallback': 'Le port reste dans la brume.'},
          ],
        },
        'credits': {
          'title': {'fallback': 'Crédits'},
          'author': 'Studio',
          'endingLabel': {'fallback': 'Fin alternative'},
          'skippable': false,
        },
        'postGamePolicy': 'returnToTitle',
      });
    });

    test('keeps credits optional for the runtime fallback', () {
      final consequence = SceneConsequence.finishGame(
        endingId: 'ending_without_credits',
        outcome: SceneGameCompletionOutcome.completed,
        result: SceneFinishGameResult(
          title: SceneLocalizedText(fallback: 'Fin'),
          summary: SceneLocalizedText(fallback: 'Merci d’avoir joué.'),
        ),
        postGamePolicy: ScenePostGamePolicy.continueGame,
      ) as SceneFinishGameConsequence;

      expect(consequence.credits, isNull);
      expect(consequence.toJson(), isNot(contains('credits')));
    });

    test('rejects unsupported versions and commit ordering', () {
      final base = {
        'kind': 'finishGame',
        'contractVersion': 1,
        'endingId': 'ending',
        'outcome': 'completed',
        'commitPolicy': 'persistBeforePresentation',
        'result': {
          'title': {'fallback': 'Fin'},
          'summary': {'fallback': 'Merci.'},
        },
        'postGamePolicy': 'returnToHub',
      };

      expect(
        () => SceneConsequence.fromJson({...base, 'contractVersion': 2}),
        throwsFormatException,
      );
      expect(
        () => SceneConsequence.fromJson({
          ...base,
          'commitPolicy': 'presentBeforePersist',
        }),
        throwsFormatException,
      );
    });
  });
}
```

### A.3 `packages/map_runtime/lib/src/application/scene_runtime/narrative_game_completion_runtime_coordinator.dart`

```dart
import 'package:map_core/map_core.dart';

import '../../session/game_session_contract.dart';
import 'scene_finish_game_runtime_mapper.dart';
import 'scene_game_completion_metadata.dart';

typedef GameCompletionRequestEmitter = Future<void> Function(
  GameCompletionRequest request,
);

final class NarrativeGameCompletionRuntimeCoordinator {
  NarrativeGameCompletionRuntimeCoordinator({
    required this.project,
    required this.locale,
    required this.emitCompletion,
    this.mapper = const SceneFinishGameRuntimeMapper(),
  });

  final ProjectManifest project;
  final String locale;
  final GameCompletionRequestEmitter emitCompletion;
  final SceneFinishGameRuntimeMapper mapper;

  final Map<String, SceneFinishGameConsequence> _pendingByEndingId =
      <String, SceneFinishGameConsequence>{};
  final Set<String> _emittedEndingIds = <String>{};

  void queue(SceneFinishGameConsequence consequence) {
    if (_emittedEndingIds.contains(consequence.endingId)) return;
    _pendingByEndingId.putIfAbsent(consequence.endingId, () => consequence);
  }

  Future<void> onGameStateCommitted(GameState gameState) async {
    final endingId = gameState.metadata[sceneGameCompletionEndingMetadataKey];
    if (endingId == null || _emittedEndingIds.contains(endingId)) return;
    final consequence = _pendingByEndingId.remove(endingId);
    if (consequence == null) return;
    try {
      await emitCompletion(
        mapper.map(
          consequence: consequence,
          project: project,
          locale: locale,
        ),
      );
      _emittedEndingIds.add(endingId);
    } catch (_) {
      _pendingByEndingId.putIfAbsent(endingId, () => consequence);
      rethrow;
    }
  }
}
```

### A.4 `packages/map_runtime/lib/src/application/scene_runtime/scene_finish_game_runtime_mapper.dart`

```dart
import 'package:map_core/map_core.dart';

import '../../session/game_session_contract.dart';

final class SceneFinishGameRuntimeMapper {
  const SceneFinishGameRuntimeMapper();

  GameCompletionRequest map({
    required SceneFinishGameConsequence consequence,
    required ProjectManifest project,
    required String locale,
  }) {
    final result = consequence.result;
    final credits = consequence.credits;
    final resolvedResultTitle = result.title.resolve(locale);
    return GameCompletionRequest(
      endingId: consequence.endingId,
      outcome: switch (consequence.outcome) {
        SceneGameCompletionOutcome.completed => GameCompletionOutcome.completed,
        SceneGameCompletionOutcome.victory => GameCompletionOutcome.victory,
        SceneGameCompletionOutcome.alternateEnding =>
          GameCompletionOutcome.alternateEnding,
      },
      result: GameResultSnapshot(
        title: resolvedResultTitle,
        summary: result.summary.resolve(locale),
        details: [
          for (final detail in result.details) detail.resolve(locale),
        ],
      ),
      credits: credits == null
          ? GameCreditsSnapshot(
              title: project.name,
              author: _projectAuthor(project),
              endingLabel: resolvedResultTitle,
            )
          : GameCreditsSnapshot(
              title: credits.title.resolve(locale),
              author: credits.author,
              contributors: credits.contributors,
              licenses: credits.licenses,
              endingLabel: credits.endingLabel.resolve(locale),
              skippable: credits.skippable,
            ),
      destination: switch (consequence.postGamePolicy) {
        ScenePostGamePolicy.continueGame =>
          GameCompletionDestination.playerChoice,
        ScenePostGamePolicy.returnToTitle => GameCompletionDestination.title,
        ScenePostGamePolicy.returnToHub => GameCompletionDestination.hub,
      },
      allowPostGameContinue:
          consequence.postGamePolicy == ScenePostGamePolicy.continueGame,
    );
  }
}

String _projectAuthor(ProjectManifest project) {
  final author = project.globalProperties['author'];
  if (author is String && author.trim().isNotEmpty) return author.trim();
  return project.name;
}
```

### A.5 `packages/map_runtime/lib/src/application/scene_runtime/scene_game_completion_metadata.dart`

```dart
import 'package:map_core/map_core.dart';

const String sceneGameCompletionEndingMetadataKey =
    'pokemap.gameCompletion.endingId';
const String sceneGameCompletionPostGamePolicyMetadataKey =
    'pokemap.gameCompletion.postGamePolicy';

bool gameStateAllowsPostGameContinue(Map<String, Object?> state) {
  final metadata = state['metadata'];
  if (metadata is! Map) return false;
  return metadata[sceneGameCompletionPostGamePolicyMetadataKey] ==
      ScenePostGamePolicy.continueGame.name;
}
```

### A.6 `packages/map_runtime/test/narrative_game_completion_runtime_coordinator_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  test('emits once only after the terminal GameState is committed', () async {
    final requests = <GameCompletionRequest>[];
    final coordinator = NarrativeGameCompletionRuntimeCoordinator(
      project: const ProjectManifest(
        name: 'Selbrume',
        maps: [],
        tilesets: [],
      ),
      locale: 'fr-FR',
      emitCompletion: (request) async => requests.add(request),
    );
    final consequence = SceneConsequence.finishGame(
      endingId: 'ending.selbrume',
      outcome: SceneGameCompletionOutcome.victory,
      result: SceneFinishGameResult(
        title: SceneLocalizedText(fallback: 'Victoire'),
        summary: SceneLocalizedText(fallback: 'Selbrume est sauvée.'),
      ),
      postGamePolicy: ScenePostGamePolicy.returnToTitle,
    ) as SceneFinishGameConsequence;
    final committed = const SceneConsequenceRuntimeWriter(
      project: ProjectManifest(
        name: 'Selbrume',
        maps: [],
        tilesets: [],
      ),
    ).applyOne(const GameState(saveId: 'save'), consequence);

    coordinator.queue(consequence);
    await coordinator.onGameStateCommitted(
      const GameState(saveId: 'save'),
    );
    expect(requests, isEmpty);

    await coordinator.onGameStateCommitted(committed.gameState);
    await coordinator.onGameStateCommitted(committed.gameState);

    expect(requests, hasLength(1));
    expect(requests.single.endingId, 'ending.selbrume');
  });
}
```

### A.7 `packages/map_runtime/test/scene_finish_game_runtime_mapper_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  group('SceneFinishGameRuntimeMapper', () {
    test('maps localized authored data and post-game policy', () {
      final consequence = SceneConsequence.finishGame(
        endingId: 'ending.selbrume',
        outcome: SceneGameCompletionOutcome.alternateEnding,
        result: SceneFinishGameResult(
          title: SceneLocalizedText(
            fallback: 'Fin',
            translations: const {'en': 'Ending'},
          ),
          summary: SceneLocalizedText(
            fallback: 'Selbrume est sauvée.',
            translations: const {'en-US': 'Selbrume is safe.'},
          ),
          details: [
            SceneLocalizedText(
              fallback: 'Merci.',
              translations: const {'en': 'Thank you.'},
            ),
          ],
        ),
        credits: SceneFinishGameCredits(
          title: SceneLocalizedText(
            fallback: 'Crédits',
            translations: const {'en': 'Credits'},
          ),
          author: 'Studio Brume',
          contributors: const ['Alice'],
          licenses: const ['CC-BY'],
          endingLabel: SceneLocalizedText(
            fallback: 'Fin alternative',
            translations: const {'en': 'Alternate ending'},
          ),
          skippable: false,
        ),
        postGamePolicy: ScenePostGamePolicy.returnToHub,
      ) as SceneFinishGameConsequence;

      final request = const SceneFinishGameRuntimeMapper().map(
        consequence: consequence,
        project: _project(),
        locale: 'en-US',
      );

      expect(request.endingId, 'ending.selbrume');
      expect(request.outcome, GameCompletionOutcome.alternateEnding);
      expect(request.result.title, 'Ending');
      expect(request.result.summary, 'Selbrume is safe.');
      expect(request.result.details, ['Thank you.']);
      expect(request.credits.title, 'Credits');
      expect(request.credits.author, 'Studio Brume');
      expect(request.credits.contributors, ['Alice']);
      expect(request.credits.licenses, ['CC-BY']);
      expect(request.credits.endingLabel, 'Alternate ending');
      expect(request.credits.skippable, isFalse);
      expect(request.destination, GameCompletionDestination.hub);
      expect(request.allowPostGameContinue, isFalse);
    });

    test('builds safe project-metadata credits fallback', () {
      final consequence = SceneConsequence.finishGame(
        endingId: 'ending.main',
        outcome: SceneGameCompletionOutcome.completed,
        result: SceneFinishGameResult(
          title: SceneLocalizedText(fallback: 'À suivre'),
          summary: SceneLocalizedText(fallback: 'La quête est terminée.'),
        ),
        postGamePolicy: ScenePostGamePolicy.continueGame,
      ) as SceneFinishGameConsequence;

      final request = const SceneFinishGameRuntimeMapper().map(
        consequence: consequence,
        project: _project(),
        locale: 'fr-FR',
      );

      expect(request.credits.title, 'Selbrume');
      expect(request.credits.author, 'Studio Brume');
      expect(request.credits.endingLabel, 'À suivre');
      expect(request.credits.skippable, isTrue);
      expect(request.destination, GameCompletionDestination.playerChoice);
      expect(request.allowPostGameContinue, isTrue);
    });
  });
}

ProjectManifest _project() => const ProjectManifest(
      name: 'Selbrume',
      maps: [],
      tilesets: [],
      globalProperties: {'author': 'Studio Brume'},
    );
```
