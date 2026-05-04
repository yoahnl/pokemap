# Environment Studio Lot 28 — Golden Slice Hardening / Diagnostics Polish V0

## 1. Résumé exécutif

Durcissement du Golden Slice Environment (Lots 19–27) : règles d’activation des boutons Générer / Effacer / Régénérer / Mélanger centralisées dans un modèle Dart pur testable, inspecteur enrichi (résumé d’état, masque, compteurs, seed, messages de blocage), message EditorNotifier aligné sur les libellés UI, tests de workflow notifier + inspecteur minimal + disabled states, non-régression `test/environment_studio` verte.

## 2. Périmètre du lot

- Inclus : `environment_layer_inspector_panel.dart`, `editor_notifier.dart` (message statut uniquement), modèle `environment_area_generation_readiness.dart`, tests dédiés, rapport.
- Exclus : map_core, MapCanvas, EditorState, runtime, build_runner, nouveau générateur, refonte UI globale, persistance disque dans ces flux.

## 3. Audit initial Golden Slice

Fichiers audités (lecture / grep) : liste du cahier des charges Lot 28 §4 ; constat : règles `_generateDisabledReason` / `_regenerateDisabledReason` / `_shuffleDisabledReason` dupliquaient la logique avec des nuances (ex. cible absente vs invalide mélangées) ; messages masque sur deux lignes ; ordre des boutons ne suivait pas le workflow recommandé (Clear après Generate).

Extraits de greps obligatoires (depuis `packages/map_editor`, tête de sortie) :

```text
$ grep -R "Générer dans la map\|Régénérer\|Mélanger et régénérer\|Effacer les placements générés" -n lib test | head -20
lib/src/ui/panels/environment_layer_inspector_panel.dart:569:                child: const Text('Générer dans la map'),
lib/src/ui/panels/environment_layer_inspector_panel.dart:595:                child: const Text('Effacer les placements générés'),
lib/src/ui/panels/environment_layer_inspector_panel.dart:619:                child: const Text('Régénérer'),
lib/src/ui/panels/environment_layer_inspector_panel.dart:643:                child: const Text('Mélanger et régénérer'),
lib/src/features/editor/state/editor_notifier.dart:4886:            '« Effacer les placements générés », « Régénérer » ou '
lib/src/features/editor/state/editor_notifier.dart:4887:            '« Mélanger et régénérer ».',
lib/src/application/models/environment_area_generation_readiness.dart:86:            '« Effacer les placements générés », « Régénérer » ou '
lib/src/application/models/environment_area_generation_readiness.dart:87:            '« Mélanger et régénérer ».';

$ grep -R "GenerateEnvironmentAreaPlacementsUseCase" -n lib test | head -15
lib/src/features/editor/state/editor_notifier.dart:4892:    final gen = GenerateEnvironmentAreaPlacementsUseCase().execute(
lib/src/features/editor/state/editor_notifier.dart:5166:    final gen = GenerateEnvironmentAreaPlacementsUseCase().execute(
lib/src/application/use_cases/environment_generator_use_cases.dart:351:class GenerateEnvironmentAreaPlacementsUseCase {
test/environment_studio/environment_generator_deterministic_core_test.dart:74:  group('GenerateEnvironmentAreaPlacementsUseCase', () {
… (suite dans le dépôt)
```

## 4. Décisions de hardening

1. Introduire `EnvironmentAreaGenerationReadiness.evaluate` avec distinction `hasTargetTileLayerId` / `targetTileLayerInvalid` / `resolvedTargetTileLayer` pour messages conformes au §5.2 du lot.
2. Remplacer les trois méthodes privées du panel par ce modèle.
3. Réordonner les actions : Generate → Clear → Regenerate → Shuffle (masque inchangé en tête de carte).
4. Tests unitaires readiness + intégration notifier + smoke widget inspecteur.
5. Harmoniser le texte « déjà généré » entre readiness, notifier et bouton Effacer.

## 5. Readiness / disabled states

Règles implémentées : Generate si cible résolue + preset + masque actif + pas de `generatedPlacementIds` ; Clear si liste non vide ; Regenerate si cible + preset + masque + placements ; Shuffle si cible + preset + masque (sans exiger placements). Messages §5.2 du lot respectés (FR).

## 6. Polish inspector EnvironmentArea

Ligne `État : …`, `Masque : X / Y cellules actives`, `Placements générés : N`, `Seed : S`, hints sous chaque groupe de boutons (message désactivé ou aide `_k*Help`).

## 7. Hardening EditorNotifier

Seule modification : message `statusMessage` quand `generatedPlacementIds` non vide au lieu de `generate` — libellé « Effacer les placements générés » pour cohérence avec l’UI. Le reste (transactions, `environmentMaskEditMode: null` après generate/regenerate/shuffle, clear sans toucher au mode masque, nettoyage sélection placement) était déjà conforme Lot 27.

## 8. Golden Slice workflow test

Fichier `environment_golden_slice_workflow_test.dart` : workflow complet generate → clear → generate → regenerate → shuffle + placement manuel ; shuffle sans génération préalable ; clear noop ; deux `testWidgets` inspecteur.

## 9. Disabled states tests

Couverts dans `environment_area_generation_readiness_test.dart` (preset manquant, cible, masque, déjà généré, clear/regenerate/shuffle) complémentés par le widget test sans cible.

## 10. Non-régression Lots 19–27

Commande groupée : `flutter test` sur les 10 fichiers listés au §13 du lot — **121 tests, All tests passed!** (détail ligne par ligne dans la sortie de la session agent).
Puis `flutter test test/environment_studio --reporter expanded` — **ligne finale : `00:08 +232: All tests passed!`**
Puis `flutter test test/editor_workspace_controller_test.dart test/top_toolbar_test.dart` — **All tests passed!**

## 11. Non-persistance disque garantie

Les méthodes `generateEnvironmentAreaPlacements`, `clearEnvironmentGeneratedPlacements`, `regenerateEnvironmentAreaPlacements`, `shuffleEnvironmentAreaPlacements` n’appellent pas `saveProject` / `FileProjectRepository` ; grep ciblé ci-dessous.

## 12. Pourquoi aucune refonte UI / aucun nouveau moteur dans ce lot

Aucun nouveau use case de génération ; seule réorganisation de widgets existants et extraction de conditions d’activation ; pas de changement d’algorithme.

## 13. Fichiers modifiés

- `packages/map_editor/lib/src/application/models/environment_area_generation_readiness.dart` (nouveau)
- `packages/map_editor/lib/src/ui/panels/environment_layer_inspector_panel.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`
- `packages/map_editor/test/environment_studio/environment_area_generation_readiness_test.dart` (nouveau)
- `packages/map_editor/test/environment_studio/environment_golden_slice_workflow_test.dart` (nouveau)
- `reports/forest/environment_studio_lot_28_golden_slice_hardening.md` (ce fichier)

## 14. Tests ajoutés ou modifiés

Nouveaux : `environment_area_generation_readiness_test.dart`, `environment_golden_slice_workflow_test.dart`. Aucun test existant des Lots 19–27 modifié.

## 15. Commandes exécutées

```text
cd packages/map_editor
dart format (fichiers readiness, panel, notifier, tests golden/readiness)
flutter analyze (5 chemins §13 lot)
grep FileProjectRepository|saveProject|saveProjectManifest (chemins lot)
flutter test test/environment_studio/environment_golden_slice_workflow_test.dart --reporter expanded
flutter test (10 fichiers régression Lots 19–27 + readiness)
flutter test test/environment_studio --reporter expanded
flutter test test/editor_workspace_controller_test.dart test/top_toolbar_test.dart --reporter expanded
flutter test  # package entier map_editor
```

## 16. Résultats des commandes

### flutter analyze (5 fichiers)
```
Analyzing 5 items...                                            
No issues found! (ran in 1.8s)
```

### grep saveProject / FileProjectRepository (chemins autorisés)
```
lib/src/features/editor/state/editor_notifier.dart:443:  Future<bool> saveProjectManifest() async {
lib/src/features/editor/state/editor_notifier.dart:452:    debugPrint('EditorNotifier: saveProjectManifest()');
lib/src/features/editor/state/editor_notifier.dart:454:      await ref.read(projectRepositoryProvider).saveProject(
lib/src/features/editor/state/editor_notifier.dart:1494:  Future<void> saveProjectDialogueYarnBody({
lib/src/features/editor/state/editor_notifier.dart:1498:    state = await _projectContentController.saveProjectDialogueYarnBody(
```

### flutter test — Golden Slice seul
```
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_golden_slice_workflow_test.dart
00:00 +0: Golden Slice — workflow notifier complet generate → clear → generate → regenerate → shuffle ; manuel conservé
00:00 +1: Golden Slice — workflow notifier complet shuffle sans placements générés préalables : seed change et placements
00:00 +2: Golden Slice — workflow notifier complet clear sans placements : message statut, carte inchangée
00:00 +3: Golden Slice — inspecteur minimal résumé + Generate activé quand prêt
00:00 +4: Golden Slice — inspecteur minimal Generate désactivé sans cible TileLayer
00:00 +5: All tests passed!
```

### flutter test — environment_studio
Ligne finale : `00:08 +232: All tests passed!`

### flutter test — package map_editor entier
Échec **hors lot** : erreurs de compilation dans `test/pokemon_catalogs_workspace_ui_test.dart`, `test/ui_panels_smoke_test.dart`, etc. (`Cannot invoke a non-const constructor where a const expression is expected`). **Ligne finale du runner : `00:55 +1064 -35: Some tests failed.`**

## 17. Git status initial et final

**Initial (message Cursor début de session)** : modifications `packages/map_core/...`, `map_editor`, `map_runtime` en cours hors périmètre Lot 28 (non rejouées ici).

**Final (`git status --short --untracked-files=all`)** :
```
 M packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
 M packages/map_editor/lib/src/ui/panels/environment_layer_inspector_panel.dart
?? packages/map_editor/lib/src/application/models/environment_area_generation_readiness.dart
?? packages/map_editor/test/environment_studio/environment_area_generation_readiness_test.dart
?? packages/map_editor/test/environment_studio/environment_golden_slice_workflow_test.dart
```

## 18. Contenu complet des fichiers créés ou modifiés

### `packages/map_editor/lib/src/application/models/environment_area_generation_readiness.dart`
```dart
import 'package:map_core/map_core.dart';

// ---------------------------------------------------------------------------
// Lot Environment-28 — règles Golden Slice (readiness) pour une EnvironmentArea.
// Pur Dart, testable sans Flutter ; ne remplace pas la validation des use cases.
// ---------------------------------------------------------------------------

/// Premier blocage « métier » pour le résumé d’état (ordre stable d’affichage).
enum EnvironmentAreaGenerationPrimaryBlocker {
  none,
  missingPreset,
  invalidTargetTileLayer,
  missingTargetTileLayer,
  emptyMask,
  alreadyGenerated,
}

/// Règles UX centralisées : boutons activables + messages de désactivation + résumé.
///
/// Aligné sur Lots 25–27 : Generate / Clear / Regenerate / Shuffle.
final class EnvironmentAreaGenerationReadiness {
  const EnvironmentAreaGenerationReadiness({
    required this.canGenerate,
    required this.canClear,
    required this.canRegenerate,
    required this.canShuffle,
    required this.generateDisabledMessage,
    required this.clearDisabledMessage,
    required this.regenerateDisabledMessage,
    required this.shuffleDisabledMessage,
    required this.stateSummaryLine,
    required this.primaryBlocker,
  });

  final bool canGenerate;
  final bool canClear;
  final bool canRegenerate;
  final bool canShuffle;

  /// Non null ssi l’action correspondante est désactivée.
  final String? generateDisabledMessage;
  final String? clearDisabledMessage;
  final String? regenerateDisabledMessage;
  final String? shuffleDisabledMessage;

  /// Une ligne courte du type `État : …` pour l’inspecteur.
  final String stateSummaryLine;

  final EnvironmentAreaGenerationPrimaryBlocker primaryBlocker;

  /// [hasTargetTileLayerId] : [EnvironmentLayerContent.targetTileLayerId] non null.
  /// [targetTileLayerInvalid] : id présent mais [resolvedTargetTileLayer] null.
  static EnvironmentAreaGenerationReadiness evaluate({
    required EnvironmentArea area,
    required EnvironmentPreset? preset,
    required bool hasTargetTileLayerId,
    required bool targetTileLayerInvalid,
    required TileLayer? resolvedTargetTileLayer,
  }) {
    final missingTarget = !hasTargetTileLayerId;
    final invalidTarget = hasTargetTileLayerId && targetTileLayerInvalid;
    final targetOk = hasTargetTileLayerId &&
        !targetTileLayerInvalid &&
        resolvedTargetTileLayer != null;

    final maskOk = area.mask.activeCellCount > 0;
    final presetOk = preset != null;
    final noGeneratedYet = area.generatedPlacementIds.isEmpty;
    final hasGenerated = area.generatedPlacementIds.isNotEmpty;

    final canGenerate = targetOk && presetOk && maskOk && noGeneratedYet;
    final canClear = hasGenerated;
    final canRegenerate = targetOk && presetOk && maskOk && hasGenerated;
    final canShuffle = targetOk && presetOk && maskOk;

    String? genMsg;
    if (!canGenerate) {
      if (missingTarget) {
        genMsg = 'Choisissez un TileLayer cible avant de générer.';
      } else if (invalidTarget) {
        genMsg = 'Le TileLayer cible est introuvable ou invalide.';
      } else if (!presetOk) {
        genMsg = 'Le preset associé est introuvable.';
      } else if (!noGeneratedYet) {
        genMsg = 'Cette zone possède déjà des placements générés. Utilisez '
            '« Effacer les placements générés », « Régénérer » ou '
            '« Mélanger et régénérer ».';
      } else if (!maskOk) {
        genMsg = 'Peignez le masque avant de générer.';
      }
    }

    final clearMsg = canClear ? null : 'Aucun placement généré à effacer.';

    String? regMsg;
    if (!canRegenerate) {
      if (!hasGenerated) {
        regMsg = 'Aucun placement généré à régénérer.';
      } else if (missingTarget) {
        regMsg = 'Choisissez un TileLayer cible avant de régénérer.';
      } else if (invalidTarget) {
        regMsg = 'Le TileLayer cible est introuvable ou invalide.';
      } else if (!presetOk) {
        regMsg = 'Le preset associé est introuvable.';
      } else if (!maskOk) {
        regMsg = 'Peignez le masque avant de régénérer.';
      }
    }

    String? shufMsg;
    if (!canShuffle) {
      if (missingTarget) {
        shufMsg = 'Choisissez un TileLayer cible avant de mélanger.';
      } else if (invalidTarget) {
        shufMsg = 'Le TileLayer cible est introuvable ou invalide.';
      } else if (!presetOk) {
        shufMsg = 'Le preset associé est introuvable.';
      } else if (!maskOk) {
        shufMsg = 'Peignez le masque avant de mélanger.';
      }
    }

    EnvironmentAreaGenerationPrimaryBlocker blocker;
    String summary;
    if (canGenerate) {
      blocker = EnvironmentAreaGenerationPrimaryBlocker.none;
      summary = 'État : prêt à générer';
    } else if (!presetOk) {
      blocker = EnvironmentAreaGenerationPrimaryBlocker.missingPreset;
      summary = 'État : preset introuvable';
    } else if (invalidTarget) {
      blocker = EnvironmentAreaGenerationPrimaryBlocker.invalidTargetTileLayer;
      summary = 'État : cible invalide';
    } else if (missingTarget) {
      blocker = EnvironmentAreaGenerationPrimaryBlocker.missingTargetTileLayer;
      summary = 'État : cible manquante';
    } else if (!maskOk) {
      blocker = EnvironmentAreaGenerationPrimaryBlocker.emptyMask;
      summary = 'État : masque vide';
    } else if (!noGeneratedYet) {
      blocker = EnvironmentAreaGenerationPrimaryBlocker.alreadyGenerated;
      summary = 'État : déjà généré';
    } else {
      blocker = EnvironmentAreaGenerationPrimaryBlocker.none;
      summary = 'État : en cours de configuration';
    }

    return EnvironmentAreaGenerationReadiness(
      canGenerate: canGenerate,
      canClear: canClear,
      canRegenerate: canRegenerate,
      canShuffle: canShuffle,
      generateDisabledMessage: genMsg,
      clearDisabledMessage: clearMsg,
      regenerateDisabledMessage: regMsg,
      shuffleDisabledMessage: shufMsg,
      stateSummaryLine: summary,
      primaryBlocker: blocker,
    );
  }
}

```

### `packages/map_editor/lib/src/ui/panels/environment_layer_inspector_panel.dart`
```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';

import '../../application/models/environment_area_generation_readiness.dart';
import '../../features/editor/state/editor_notifier.dart';
import '../../features/editor/state/editor_selectors.dart';
import '../../features/editor/tools/editor_tool.dart';
import '../shared/cupertino_editor_widgets.dart';

/// Inspecteur Environment Studio : cible tuile (Lot 20) + zones (Lot 21), sans canvas.
class EnvironmentLayerInspectorPanel extends ConsumerWidget {
  const EnvironmentLayerInspectorPanel({
    super.key,
    required this.map,
    required this.layer,
    this.embedded = false,
  });

  final MapData map;
  final EnvironmentLayer layer;
  final bool embedded;

  List<TileLayer> _tileLayers() {
    final out = <TileLayer>[];
    for (final l in map.layers) {
      if (l is TileLayer) {
        out.add(l);
      }
    }
    return out;
  }

  TileLayer? _resolveTarget() {
    final tid = layer.content.targetTileLayerId;
    if (tid == null) return null;
    for (final l in map.layers) {
      if (l.id == tid && l is TileLayer) {
        return l;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subtle = EditorChrome.subtleLabel(context);
    final label = EditorChrome.primaryLabel(context);
    final notifier = ref.read(editorNotifierProvider.notifier);
    final manifest = ref.watch(editorProjectManifestProvider);
    final tiles = _tileLayers();
    final target = _resolveTarget();
    final tid = layer.content.targetTileLayerId;
    final invalidTarget = tid != null && target == null;
    final presets = manifest?.environmentPresets ?? const <EnvironmentPreset>[];

    return SingleChildScrollView(
      child: Padding(
        padding:
            EdgeInsets.fromLTRB(embedded ? 8 : 10, 4, embedded ? 8 : 10, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Environment Layer',
              key: const Key('map-inspector-environment-layer-title'),
              style: TextStyle(
                color: label,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ce layer servira à dessiner des zones organiques et à générer des '
              'éléments naturels.',
              key: const Key('map-inspector-environment-layer-body'),
              style: TextStyle(
                color: subtle,
                fontSize: 12,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Zones d’environnement',
              key: const Key('env-layer-inspector-zones-title'),
              style: TextStyle(
                color: label,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Les zones définissent où les presets organiques seront générés. '
              'Peignez le masque par zone pour marquer les cellules actives.',
              key: const Key('env-layer-inspector-zones-desc'),
              style: TextStyle(
                color: subtle,
                fontSize: 11.5,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            if (presets.isEmpty) ...[
              Text(
                'Aucun preset d’environnement disponible.\n'
                'Créez d’abord un preset dans Environment Studio.',
                key: const Key('env-layer-inspector-no-presets'),
                style: TextStyle(
                  color: subtle,
                  fontSize: 12,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ] else ...[
              if (layer.content.areas.isEmpty)
                Text(
                  'Aucune zone d’environnement pour ce layer.',
                  key: const Key('env-layer-inspector-no-areas'),
                  style: TextStyle(
                    color: subtle,
                    fontSize: 12,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                )
              else
                ...layer.content.areas.map(
                  (area) => _EnvironmentAreaCard(
                    area: area,
                    manifest: manifest,
                    layerId: layer.id,
                    labelColor: label,
                    subtleColor: subtle,
                    resolvedTargetTileLayer: target,
                    targetTileLayerInvalid: invalidTarget,
                    hasTargetTileLayerId: tid != null,
                  ),
                ),
              const SizedBox(height: 10),
              PushButton(
                key: const Key('env-layer-inspector-add-area'),
                controlSize: ControlSize.regular,
                onPressed: () => _pickPresetAndAddArea(
                  context,
                  notifier,
                  presets,
                ),
                child: const Text('Ajouter une zone'),
              ),
            ],
            const SizedBox(height: 18),
            Text(
              'TileLayer cible',
              style: TextStyle(
                color: label,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            if (tiles.isEmpty) ...[
              Text(
                'Aucun TileLayer disponible dans cette map.\n'
                'Ajoutez d’abord un TileLayer pour recevoir les résultats générés.',
                key: const Key('env-layer-inspector-no-tile-layers'),
                style: TextStyle(
                  color: subtle,
                  fontSize: 12,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ] else if (invalidTarget) ...[
              Text(
                'La cible configurée est introuvable ou invalide : $tid',
                key: const Key('env-layer-inspector-invalid-target'),
                style: TextStyle(
                  color: CupertinoColors.systemOrange.resolveFrom(context),
                  fontSize: 12,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              PushButton(
                key: const Key('env-layer-inspector-change-invalid'),
                controlSize: ControlSize.regular,
                onPressed: () => _pickTileLayer(context, notifier, tiles),
                child: const Text('Choisir un autre TileLayer cible'),
              ),
              const SizedBox(height: 8),
              PushButton(
                key: const Key('env-layer-inspector-remove-invalid'),
                controlSize: ControlSize.regular,
                secondary: true,
                onPressed: () => notifier.setEnvironmentLayerTargetTileLayer(
                  environmentLayerId: layer.id,
                  targetTileLayerId: null,
                ),
                child: const Text('Retirer la cible'),
              ),
            ] else if (target == null) ...[
              Text(
                'Aucun TileLayer cible sélectionné.',
                key: const Key('env-layer-inspector-no-target'),
                style: TextStyle(
                  color: subtle,
                  fontSize: 12,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Vous pouvez peindre le masque maintenant. Le TileLayer cible '
                'sera nécessaire pour générer plus tard.',
                key: const Key('env-layer-inspector-mask-without-target-note'),
                style: TextStyle(
                  color: subtle,
                  fontSize: 11,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              PushButton(
                key: const Key('env-layer-inspector-choose-target'),
                controlSize: ControlSize.regular,
                onPressed: () => _pickTileLayer(context, notifier, tiles),
                child: const Text('Choisir le TileLayer cible'),
              ),
            ] else ...[
              Text(
                'Cible actuelle : ${target.name}',
                key: const Key('env-layer-inspector-current-target-name'),
                style: TextStyle(
                  color: label,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Id : ${target.id}',
                key: const Key('env-layer-inspector-current-target-id'),
                style: TextStyle(
                  color: subtle,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              PushButton(
                key: const Key('env-layer-inspector-change-target'),
                controlSize: ControlSize.regular,
                onPressed: () => _pickTileLayer(context, notifier, tiles),
                child: const Text('Changer de TileLayer cible'),
              ),
              const SizedBox(height: 8),
              PushButton(
                key: const Key('env-layer-inspector-remove-target'),
                controlSize: ControlSize.regular,
                secondary: true,
                onPressed: () => notifier.setEnvironmentLayerTargetTileLayer(
                  environmentLayerId: layer.id,
                  targetTileLayerId: null,
                ),
                child: const Text('Retirer la cible'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _pickTileLayer(
    BuildContext context,
    EditorNotifier notifier,
    List<TileLayer> tiles,
  ) async {
    final picked = await showCupertinoListPicker<TileLayer>(
      context: context,
      title: 'TileLayer cible',
      items: tiles,
      labelOf: (t) => t.name,
    );
    if (picked == null) return;
    notifier.setEnvironmentLayerTargetTileLayer(
      environmentLayerId: layer.id,
      targetTileLayerId: picked.id,
    );
  }

  Future<void> _pickPresetAndAddArea(
    BuildContext context,
    EditorNotifier notifier,
    List<EnvironmentPreset> presets,
  ) async {
    final picked = await showCupertinoListPicker<EnvironmentPreset>(
      context: context,
      title: 'Preset d’environnement',
      items: presets,
      labelOf: (p) => '${p.name} — ${p.id}',
    );
    if (picked == null) return;
    notifier.addEnvironmentAreaToLayer(
      environmentLayerId: layer.id,
      presetId: picked.id,
    );
  }
}

const _kGenerateHelp =
    'Crée des placements dans le TileLayer cible en utilisant le preset et le '
    'masque de cette zone.';

const _kClearHelp =
    'Supprime uniquement les placements listés pour cette zone (pas le masque, '
    'pas les placements posés manuellement ailleurs).';

const _kShuffleHelp =
    'Change la seed de cette zone puis génère de nouveaux placements.';

const _kRegenerateHelp =
    'Recrée les placements générés en conservant la seed actuelle.';

class _EnvironmentAreaCard extends ConsumerWidget {
  const _EnvironmentAreaCard({
    required this.area,
    required this.manifest,
    required this.layerId,
    required this.labelColor,
    required this.subtleColor,
    required this.resolvedTargetTileLayer,
    required this.targetTileLayerInvalid,
    required this.hasTargetTileLayerId,
  });

  final EnvironmentArea area;
  final ProjectManifest? manifest;
  final String layerId;
  final Color labelColor;
  final Color subtleColor;

  /// `null` si pas de cible ou cible non résolue.
  final TileLayer? resolvedTargetTileLayer;
  final bool targetTileLayerInvalid;
  final bool hasTargetTileLayerId;

  EnvironmentPreset? _presetForArea() {
    final m = manifest;
    if (m == null) return null;
    for (final p in m.environmentPresets) {
      if (p.id == area.presetId) return p;
    }
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(editorNotifierProvider.notifier);
    final editorState = ref.watch(editorNotifierProvider);
    final manifestPresets =
        manifest?.environmentPresets ?? const <EnvironmentPreset>[];
    final preset = _presetForArea();
    final readiness = EnvironmentAreaGenerationReadiness.evaluate(
      area: area,
      preset: preset,
      hasTargetTileLayerId: hasTargetTileLayerId,
      targetTileLayerInvalid: targetTileLayerInvalid,
      resolvedTargetTileLayer: resolvedTargetTileLayer,
    );
    final regenerateEnabled = readiness.canRegenerate;
    final shuffleEnabled = readiness.canShuffle;
    final totalCells = area.mask.width * area.mask.height;
    final activeCount = area.mask.activeCellCount;
    final maskLabel = 'Masque : $activeCount / $totalCells cellules actives';
    final warnPlacements = area.generatedPlacementIds.isNotEmpty;
    final isThisAreaActiveForMask = editorState.activeLayerId == layerId &&
        editorState.selectedEnvironmentAreaId == area.id;
    final maskMode = editorState.environmentMaskEditMode;
    String? editModeLabel;
    if (isThisAreaActiveForMask && maskMode != null) {
      editModeLabel = maskMode == EnvironmentMaskEditMode.paint
          ? 'Édition active : peinture'
          : 'Édition active : effacement';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: CupertinoColors.tertiarySystemFill.resolveFrom(context),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: CupertinoColors.separator.resolveFrom(context),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Zone : ${area.id}',
                key: Key('env-area-card-id-${area.id}'),
                style: TextStyle(
                  color: labelColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              if (preset != null) ...[
                Text(
                  'Preset : ${preset.name}',
                  key: Key('env-area-card-preset-name-${area.id}'),
                  style: TextStyle(
                    color: labelColor,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Id preset : ${preset.id}',
                  key: Key('env-area-card-preset-id-${area.id}'),
                  style: TextStyle(
                    color: subtleColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ] else
                Text(
                  'Preset associé introuvable : ${area.presetId}',
                  key: Key('env-area-card-preset-missing-${area.id}'),
                  style: TextStyle(
                    color: CupertinoColors.systemOrange.resolveFrom(context),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              const SizedBox(height: 6),
              Text(
                maskLabel,
                key: Key('env-area-card-mask-${area.id}'),
                style: TextStyle(
                  color: subtleColor,
                  fontSize: 11,
                  height: 1.3,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (editModeLabel != null) ...[
                const SizedBox(height: 6),
                Text(
                  editModeLabel,
                  key: Key('env-area-card-mask-edit-active-${area.id}'),
                  style: TextStyle(
                    color: labelColor,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
              const SizedBox(height: 4),
              Text(
                'Placements générés : ${area.generatedPlacementIds.length}',
                key: Key('env-area-card-placements-count-${area.id}'),
                style: TextStyle(
                  color: subtleColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Seed : ${area.seed}',
                key: Key('env-area-seed-${area.id}'),
                style: TextStyle(
                  color: subtleColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                readiness.stateSummaryLine,
                key: Key('env-area-readiness-summary-${area.id}'),
                style: TextStyle(
                  color: labelColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (warnPlacements) ...[
                const SizedBox(height: 6),
                Text(
                  'Cette zone référence des placements générés ; le retrait ne les '
                  'supprime pas automatiquement.',
                  key: Key('env-area-card-placements-warn-${area.id}'),
                  style: TextStyle(
                    color: CupertinoColors.systemOrange.resolveFrom(context),
                    fontSize: 10.5,
                    height: 1.25,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              PushButton(
                key: Key('env-area-mask-paint-${area.id}'),
                controlSize: ControlSize.small,
                onPressed: () => notifier.startEnvironmentAreaMaskPaint(
                  environmentLayerId: layerId,
                  areaId: area.id,
                ),
                child: const Text('Peindre le masque'),
              ),
              const SizedBox(height: 6),
              PushButton(
                key: Key('env-area-mask-erase-${area.id}'),
                controlSize: ControlSize.small,
                onPressed: () => notifier.startEnvironmentAreaMaskErase(
                  environmentLayerId: layerId,
                  areaId: area.id,
                ),
                child: const Text('Effacer du masque'),
              ),
              const SizedBox(height: 6),
              PushButton(
                key: Key('env-area-mask-stop-${area.id}'),
                controlSize: ControlSize.small,
                secondary: true,
                onPressed: isThisAreaActiveForMask && maskMode != null
                    ? notifier.stopEnvironmentAreaMaskEditing
                    : null,
                child: const Text('Arrêter l’édition'),
              ),
              const SizedBox(height: 10),
              Text(
                readiness.generateDisabledMessage ?? _kGenerateHelp,
                key: Key('env-area-generate-hint-${area.id}'),
                style: TextStyle(
                  color: subtleColor,
                  fontSize: 10.5,
                  height: 1.25,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              PushButton(
                key: Key('env-area-generate-${area.id}'),
                controlSize: ControlSize.regular,
                onPressed: readiness.canGenerate
                    ? () => notifier.generateEnvironmentAreaPlacements(
                          environmentLayerId: layerId,
                          areaId: area.id,
                        )
                    : null,
                child: const Text('Générer dans la map'),
              ),
              const SizedBox(height: 10),
              Text(
                readiness.clearDisabledMessage == null
                    ? _kClearHelp
                    : readiness.clearDisabledMessage!,
                key: Key('env-area-clear-hint-${area.id}'),
                style: TextStyle(
                  color: subtleColor,
                  fontSize: 10.5,
                  height: 1.25,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              PushButton(
                key: Key('env-area-clear-${area.id}'),
                controlSize: ControlSize.regular,
                secondary: true,
                onPressed: readiness.canClear
                    ? () => notifier.clearEnvironmentGeneratedPlacements(
                          environmentLayerId: layerId,
                          areaId: area.id,
                        )
                    : null,
                child: const Text('Effacer les placements générés'),
              ),
              const SizedBox(height: 10),
              Text(
                readiness.regenerateDisabledMessage ?? _kRegenerateHelp,
                key: Key('env-area-regenerate-hint-${area.id}'),
                style: TextStyle(
                  color: subtleColor,
                  fontSize: 10.5,
                  height: 1.25,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              PushButton(
                key: Key('env-area-regenerate-${area.id}'),
                controlSize: ControlSize.regular,
                secondary: true,
                onPressed: regenerateEnabled
                    ? () => notifier.regenerateEnvironmentAreaPlacements(
                          environmentLayerId: layerId,
                          areaId: area.id,
                        )
                    : null,
                child: const Text('Régénérer'),
              ),
              const SizedBox(height: 10),
              Text(
                readiness.shuffleDisabledMessage ?? _kShuffleHelp,
                key: Key('env-area-shuffle-hint-${area.id}'),
                style: TextStyle(
                  color: subtleColor,
                  fontSize: 10.5,
                  height: 1.25,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              PushButton(
                key: Key('env-area-shuffle-${area.id}'),
                controlSize: ControlSize.regular,
                secondary: true,
                onPressed: shuffleEnabled
                    ? () => notifier.shuffleEnvironmentAreaPlacements(
                          environmentLayerId: layerId,
                          areaId: area.id,
                        )
                    : null,
                child: const Text('Mélanger et régénérer'),
              ),
              const SizedBox(height: 10),
              PushButton(
                key: Key('env-area-change-preset-${area.id}'),
                controlSize: ControlSize.small,
                onPressed: manifestPresets.isEmpty
                    ? null
                    : () => _pickPresetForArea(
                          context,
                          notifier,
                          manifestPresets,
                        ),
                child: const Text('Changer de preset'),
              ),
              const SizedBox(height: 6),
              PushButton(
                key: Key('env-area-remove-${area.id}'),
                controlSize: ControlSize.small,
                secondary: true,
                onPressed: () => notifier.removeEnvironmentArea(
                  environmentLayerId: layerId,
                  areaId: area.id,
                ),
                child: const Text('Retirer'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickPresetForArea(
    BuildContext context,
    EditorNotifier notifier,
    List<EnvironmentPreset> presets,
  ) async {
    final picked = await showCupertinoListPicker<EnvironmentPreset>(
      context: context,
      title: 'Nouveau preset',
      items: presets,
      labelOf: (p) => '${p.name} — ${p.id}',
    );
    if (picked == null) return;
    notifier.setEnvironmentAreaPreset(
      environmentLayerId: layerId,
      areaId: area.id,
      presetId: picked.id,
    );
  }
}

```

### `packages/map_editor/test/environment_studio/environment_area_generation_readiness_test.dart`
```dart
// ignore_for_file: prefer_const_constructors

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/models/environment_area_generation_readiness.dart';

EnvironmentArea _area({
  List<String>? generated,
  List<bool>? cells,
  int w = 2,
  int h = 2,
}) {
  final c = cells ?? List<bool>.filled(w * h, true);
  return EnvironmentArea(
    id: 'z1',
    name: 'Z',
    presetId: 'p1',
    mask: EnvironmentAreaMask(width: w, height: h, cells: c),
    seed: 1,
    generatedPlacementIds: generated,
  );
}

EnvironmentPreset _preset() {
  return EnvironmentPreset(
    id: 'p1',
    name: 'P',
    templateId: 't',
    palette: [
      EnvironmentPaletteItem(elementId: 'e1', weight: 1),
    ],
    defaultParams: EnvironmentGenerationParams.standard(),
    sortOrder: 0,
  );
}

void main() {
  group('EnvironmentAreaGenerationReadiness', () {
    test('prêt à générer : cible + preset + masque + pas encore généré', () {
      final r = EnvironmentAreaGenerationReadiness.evaluate(
        area: _area(),
        preset: _preset(),
        hasTargetTileLayerId: true,
        targetTileLayerInvalid: false,
        resolvedTargetTileLayer: TileLayer(
          id: 'tiles',
          name: 'T',
          tiles: List<int>.filled(4, 0),
        ),
      );
      expect(r.canGenerate, isTrue);
      expect(r.canClear, isFalse);
      expect(r.canRegenerate, isFalse);
      expect(r.canShuffle, isTrue);
      expect(r.stateSummaryLine, 'État : prêt à générer');
      expect(r.generateDisabledMessage, isNull);
    });

    test('Generate désactivé : preset introuvable', () {
      final r = EnvironmentAreaGenerationReadiness.evaluate(
        area: _area(),
        preset: null,
        hasTargetTileLayerId: true,
        targetTileLayerInvalid: false,
        resolvedTargetTileLayer: TileLayer(
          id: 'tiles',
          name: 'T',
          tiles: List<int>.filled(4, 0),
        ),
      );
      expect(r.canGenerate, isFalse);
      expect(
        r.generateDisabledMessage,
        'Le preset associé est introuvable.',
      );
      expect(r.stateSummaryLine, 'État : preset introuvable');
    });

    test('Generate désactivé : cible manquante', () {
      final r = EnvironmentAreaGenerationReadiness.evaluate(
        area: _area(),
        preset: _preset(),
        hasTargetTileLayerId: false,
        targetTileLayerInvalid: false,
        resolvedTargetTileLayer: null,
      );
      expect(r.canGenerate, isFalse);
      expect(
        r.generateDisabledMessage,
        'Choisissez un TileLayer cible avant de générer.',
      );
      expect(r.stateSummaryLine, 'État : cible manquante');
    });

    test('Generate désactivé : cible invalide', () {
      final r = EnvironmentAreaGenerationReadiness.evaluate(
        area: _area(),
        preset: _preset(),
        hasTargetTileLayerId: true,
        targetTileLayerInvalid: true,
        resolvedTargetTileLayer: null,
      );
      expect(r.canGenerate, isFalse);
      expect(
        r.generateDisabledMessage,
        'Le TileLayer cible est introuvable ou invalide.',
      );
      expect(r.stateSummaryLine, 'État : cible invalide');
    });

    test('Generate désactivé : masque vide', () {
      final r = EnvironmentAreaGenerationReadiness.evaluate(
        area: _area(cells: List<bool>.filled(4, false)),
        preset: _preset(),
        hasTargetTileLayerId: true,
        targetTileLayerInvalid: false,
        resolvedTargetTileLayer: TileLayer(
          id: 'tiles',
          name: 'T',
          tiles: List<int>.filled(4, 0),
        ),
      );
      expect(r.canGenerate, isFalse);
      expect(
        r.generateDisabledMessage,
        'Peignez le masque avant de générer.',
      );
      expect(r.stateSummaryLine, 'État : masque vide');
    });

    test('Generate désactivé : déjà généré', () {
      final r = EnvironmentAreaGenerationReadiness.evaluate(
        area: _area(generated: const ['x']),
        preset: _preset(),
        hasTargetTileLayerId: true,
        targetTileLayerInvalid: false,
        resolvedTargetTileLayer: TileLayer(
          id: 'tiles',
          name: 'T',
          tiles: List<int>.filled(4, 0),
        ),
      );
      expect(r.canGenerate, isFalse);
      expect(r.canClear, isTrue);
      expect(r.canRegenerate, isTrue);
      expect(r.canShuffle, isTrue);
      expect(
        r.generateDisabledMessage,
        contains('déjà des placements générés'),
      );
      expect(r.stateSummaryLine, 'État : déjà généré');
    });

    test('Clear désactivé sans placements', () {
      final r = EnvironmentAreaGenerationReadiness.evaluate(
        area: _area(),
        preset: _preset(),
        hasTargetTileLayerId: true,
        targetTileLayerInvalid: false,
        resolvedTargetTileLayer: TileLayer(
          id: 'tiles',
          name: 'T',
          tiles: List<int>.filled(4, 0),
        ),
      );
      expect(r.canClear, isFalse);
      expect(
        r.clearDisabledMessage,
        'Aucun placement généré à effacer.',
      );
    });

    test('Regenerate désactivé sans placements', () {
      final r = EnvironmentAreaGenerationReadiness.evaluate(
        area: _area(),
        preset: _preset(),
        hasTargetTileLayerId: true,
        targetTileLayerInvalid: false,
        resolvedTargetTileLayer: TileLayer(
          id: 'tiles',
          name: 'T',
          tiles: List<int>.filled(4, 0),
        ),
      );
      expect(r.canRegenerate, isFalse);
      expect(
          r.regenerateDisabledMessage, 'Aucun placement généré à régénérer.');
    });

    test('Shuffle activé sans placements générés si masque + cible + preset',
        () {
      final r = EnvironmentAreaGenerationReadiness.evaluate(
        area: _area(),
        preset: _preset(),
        hasTargetTileLayerId: true,
        targetTileLayerInvalid: false,
        resolvedTargetTileLayer: TileLayer(
          id: 'tiles',
          name: 'T',
          tiles: List<int>.filled(4, 0),
        ),
      );
      expect(r.canShuffle, isTrue);
      expect(r.shuffleDisabledMessage, isNull);
    });

    test('Shuffle désactivé : masque vide', () {
      final r = EnvironmentAreaGenerationReadiness.evaluate(
        area: _area(cells: List<bool>.filled(4, false)),
        preset: _preset(),
        hasTargetTileLayerId: true,
        targetTileLayerInvalid: false,
        resolvedTargetTileLayer: TileLayer(
          id: 'tiles',
          name: 'T',
          tiles: List<int>.filled(4, 0),
        ),
      );
      expect(r.canShuffle, isFalse);
      expect(
        r.shuffleDisabledMessage,
        'Peignez le masque avant de mélanger.',
      );
    });

    test('Shuffle désactivé : preset manquant', () {
      final r = EnvironmentAreaGenerationReadiness.evaluate(
        area: _area(),
        preset: null,
        hasTargetTileLayerId: true,
        targetTileLayerInvalid: false,
        resolvedTargetTileLayer: TileLayer(
          id: 'tiles',
          name: 'T',
          tiles: List<int>.filled(4, 0),
        ),
      );
      expect(r.canShuffle, isFalse);
      expect(
        r.shuffleDisabledMessage,
        'Le preset associé est introuvable.',
      );
      expect(r.stateSummaryLine, 'État : preset introuvable');
    });

    test('Shuffle désactivé : cible manquante', () {
      final r = EnvironmentAreaGenerationReadiness.evaluate(
        area: _area(),
        preset: _preset(),
        hasTargetTileLayerId: false,
        targetTileLayerInvalid: false,
        resolvedTargetTileLayer: null,
      );
      expect(r.canShuffle, isFalse);
      expect(
        r.shuffleDisabledMessage,
        'Choisissez un TileLayer cible avant de mélanger.',
      );
    });
  });
}

```

### `packages/map_editor/test/environment_studio/environment_golden_slice_workflow_test.dart`
```dart
// ignore_for_file: prefer_const_constructors

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/features/editor/tools/editor_tool.dart';
import 'package:map_editor/src/ui/panels/environment_layer_inspector_panel.dart';

import '../shell_chrome_test_harness.dart';

ProjectManifest _manifest() {
  return buildShellChromeProject(
    environmentPresets: [
      EnvironmentPreset(
        id: 'p1',
        name: 'P',
        templateId: 't',
        palette: [
          EnvironmentPaletteItem(elementId: 'e1', weight: 1),
        ],
        defaultParams: EnvironmentGenerationParams(
          density: 1,
          edgeDensity: 1,
          variation: 0,
          minSpacingCells: 0,
        ),
        sortOrder: 0,
      ),
    ],
    elements: const [
      ProjectElementEntry(
        id: 'e1',
        name: 'E',
        tilesetId: 'tsA',
        categoryId: 'c',
        frames: [
          TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0)),
        ],
      ),
    ],
  );
}

EnvironmentArea _area({List<String>? generated}) {
  return EnvironmentArea(
    id: 'area1',
    name: 'Z',
    presetId: 'p1',
    mask: EnvironmentAreaMask(
      width: 2,
      height: 2,
      cells: List<bool>.filled(4, true),
    ),
    seed: 42,
    generatedPlacementIds: generated,
  );
}

MapData _map(EnvironmentArea area) {
  final env = MapLayer.environment(
    id: 'env',
    name: 'E',
    content: EnvironmentLayerContent(
      targetTileLayerId: 'tiles',
      areas: [area],
    ),
  );
  final tile = TileLayer(
    id: 'tiles',
    name: 'T',
    tiles: List<int>.filled(4, 0),
  );
  return MapData(
    id: 'm',
    name: 'M',
    size: const GridSize(width: 2, height: 2),
    tilesetId: 'tsA',
    layers: [env, tile],
    placedElements: const [
      MapPlacedElement(
        id: 'manual_keep',
        layerId: 'tiles',
        elementId: 'e1',
        pos: GridPos(x: 1, y: 1),
      ),
    ],
  );
}

void main() {
  group('Golden Slice — workflow notifier complet', () {
    test('generate → clear → generate → regenerate → shuffle ; manuel conservé',
        () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      var area = _area();
      var map = _map(area);
      container.read(editorNotifierProvider.notifier).state = EditorState(
        projectRootPath: '/golden',
        project: _manifest(),
        activeMap: map,
        activeMapPath: 'maps/x.json',
        activeLayerId: 'env',
        selectedEnvironmentAreaId: 'area1',
        environmentMaskEditMode: EnvironmentMaskEditMode.paint,
        savedMapSnapshot: map,
      );
      final notifier = container.read(editorNotifierProvider.notifier);

      notifier.generateEnvironmentAreaPlacements(
        environmentLayerId: 'env',
        areaId: 'area1',
      );
      var s = container.read(editorNotifierProvider);
      expect(s.activeMap!.placedElements.length, greaterThan(1));
      expect(
        (s.activeMap!.layers.first as EnvironmentLayer)
            .content
            .areas
            .single
            .generatedPlacementIds,
        isNotEmpty,
      );
      expect(
        s.activeMap!.placedElements.any((p) => p.id == 'manual_keep'),
        isTrue,
      );
      expect(s.environmentMaskEditMode, isNull);

      notifier.clearEnvironmentGeneratedPlacements(
        environmentLayerId: 'env',
        areaId: 'area1',
      );
      s = container.read(editorNotifierProvider);
      expect(
        (s.activeMap!.layers.first as EnvironmentLayer)
            .content
            .areas
            .single
            .generatedPlacementIds,
        isEmpty,
      );
      expect(s.activeMap!.placedElements.map((e) => e.id).toList(),
          ['manual_keep']);

      notifier.generateEnvironmentAreaPlacements(
        environmentLayerId: 'env',
        areaId: 'area1',
      );
      s = container.read(editorNotifierProvider);
      expect(s.activeMap!.placedElements.length, greaterThan(1));
      final seedBeforeRegen = (s.activeMap!.layers.first as EnvironmentLayer)
          .content
          .areas
          .single
          .seed;

      notifier.regenerateEnvironmentAreaPlacements(
        environmentLayerId: 'env',
        areaId: 'area1',
      );
      s = container.read(editorNotifierProvider);
      expect(s.activeMap!.placedElements.length, greaterThan(1));
      expect(
        (s.activeMap!.layers.first as EnvironmentLayer)
            .content
            .areas
            .single
            .seed,
        seedBeforeRegen,
      );
      expect(
        s.activeMap!.placedElements.any((p) => p.id == 'manual_keep'),
        isTrue,
      );

      final seedBeforeShuffle = (s.activeMap!.layers.first as EnvironmentLayer)
          .content
          .areas
          .single
          .seed;
      notifier.shuffleEnvironmentAreaPlacements(
        environmentLayerId: 'env',
        areaId: 'area1',
      );
      s = container.read(editorNotifierProvider);
      final areaOut =
          (s.activeMap!.layers.first as EnvironmentLayer).content.areas.single;
      expect(areaOut.seed, isNot(seedBeforeShuffle));
      expect(areaOut.generatedPlacementIds, isNotEmpty);
      expect(
        s.activeMap!.placedElements.any((p) => p.id == 'manual_keep'),
        isTrue,
      );
    });

    test(
        'shuffle sans placements générés préalables : seed change et placements',
        () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final area = _area();
      final map = _map(area);
      container.read(editorNotifierProvider.notifier).state = EditorState(
        projectRootPath: '/golden',
        project: _manifest(),
        activeMap: map,
        activeMapPath: 'maps/x.json',
        activeLayerId: 'env',
        selectedEnvironmentAreaId: 'area1',
        savedMapSnapshot: map,
      );
      final notifier = container.read(editorNotifierProvider.notifier);
      final seed0 = (container
              .read(editorNotifierProvider)
              .activeMap!
              .layers
              .first as EnvironmentLayer)
          .content
          .areas
          .single
          .seed;

      notifier.shuffleEnvironmentAreaPlacements(
        environmentLayerId: 'env',
        areaId: 'area1',
      );
      final s = container.read(editorNotifierProvider);
      final areaOut =
          (s.activeMap!.layers.first as EnvironmentLayer).content.areas.single;
      expect(areaOut.seed, isNot(seed0));
      expect(areaOut.generatedPlacementIds, isNotEmpty);
      expect(s.activeMap!.placedElements.length, greaterThan(1));
    });

    test('clear sans placements : message statut, carte inchangée', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final area = _area();
      final map = _map(area);
      container.read(editorNotifierProvider.notifier).state = EditorState(
        projectRootPath: '/golden',
        project: _manifest(),
        activeMap: map,
        activeMapPath: 'maps/x.json',
        activeLayerId: 'env',
        savedMapSnapshot: map,
      );
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.clearEnvironmentGeneratedPlacements(
        environmentLayerId: 'env',
        areaId: 'area1',
      );
      final s = container.read(editorNotifierProvider);
      expect(
          s.statusMessage, 'Aucun placement généré à effacer pour cette zone.');
      expect(identical(s.activeMap, map), isTrue);
    });
  });

  group('Golden Slice — inspecteur minimal', () {
    testWidgets('résumé + Generate activé quand prêt', (tester) async {
      final area = _area();
      final env = MapLayer.environment(
        id: 'env',
        name: 'E',
        content: EnvironmentLayerContent(
          targetTileLayerId: 'tiles',
          areas: [area],
        ),
      );
      final tile = TileLayer(
        id: 'tiles',
        name: 'T',
        tiles: List<int>.filled(4, 0),
      );
      final map = MapData(
        id: 'm',
        name: 'M',
        size: const GridSize(width: 2, height: 2),
        tilesetId: 'tsA',
        layers: [env, tile],
      );
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(editorNotifierProvider.notifier).state = EditorState(
        projectRootPath: '/g',
        project: _manifest(),
        activeMap: map,
        activeMapPath: 'maps/x.json',
        activeLayerId: 'env',
      );
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MacosTheme(
            data: MacosThemeData.light(),
            child: MaterialApp(
              home: CupertinoPageScaffold(
                child: EnvironmentLayerInspectorPanel(
                  map: map,
                  layer: env as EnvironmentLayer,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('État : prêt à générer'), findsOneWidget);
      expect(
        tester
            .widget<PushButton>(
              find.byKey(const Key('env-area-generate-area1')),
            )
            .onPressed,
        isNotNull,
      );
    });

    testWidgets('Generate désactivé sans cible TileLayer', (tester) async {
      final area = _area();
      final env = MapLayer.environment(
        id: 'env',
        name: 'E',
        content: EnvironmentLayerContent(
          targetTileLayerId: null,
          areas: [area],
        ),
      );
      final tile = TileLayer(
        id: 'tiles',
        name: 'T',
        tiles: List<int>.filled(4, 0),
      );
      final map = MapData(
        id: 'm',
        name: 'M',
        size: const GridSize(width: 2, height: 2),
        layers: [env, tile],
      );
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(editorNotifierProvider.notifier).state = EditorState(
        projectRootPath: '/g',
        project: _manifest(),
        activeMap: map,
        activeLayerId: 'env',
      );
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MacosTheme(
            data: MacosThemeData.light(),
            child: MaterialApp(
              home: CupertinoPageScaffold(
                child: EnvironmentLayerInspectorPanel(
                  map: map,
                  layer: env as EnvironmentLayer,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<PushButton>(
              find.byKey(const Key('env-area-generate-area1')),
            )
            .onPressed,
        isNull,
      );
      expect(
          find.textContaining('Choisissez un TileLayer cible'), findsWidgets);
    });
  });
}

```

### `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`
Fichier volumineux : le Lot 28 n’édite que le bloc message « déjà généré » dans `generateEnvironmentAreaPlacements`. Le contenu intégral du fichier est celui du dépôt ; la preuve des changements Lot 28 est le diff git section 19.

## 19. Diff complet

### Fichiers suivis (git diff)
```diff
diff --git a/packages/map_editor/lib/src/features/editor/state/editor_notifier.dart b/packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
index a9a999f0..42e78747 100644
--- a/packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
+++ b/packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
@@ -4882,8 +4882,9 @@ class EditorNotifier extends _$EditorNotifier {
       state = state.copyWith(
         errorMessage: null,
         statusMessage:
-            'Cette zone possède déjà des placements générés. Utilisez « Effacer », '
-            '« Régénérer » ou « Mélanger et régénérer ».',
+            'Cette zone possède déjà des placements générés. Utilisez '
+            '« Effacer les placements générés », « Régénérer » ou '
+            '« Mélanger et régénérer ».',
       );
       return;
     }
diff --git a/packages/map_editor/lib/src/ui/panels/environment_layer_inspector_panel.dart b/packages/map_editor/lib/src/ui/panels/environment_layer_inspector_panel.dart
index 6f2e755d..9f8ee928 100644
--- a/packages/map_editor/lib/src/ui/panels/environment_layer_inspector_panel.dart
+++ b/packages/map_editor/lib/src/ui/panels/environment_layer_inspector_panel.dart
@@ -3,6 +3,7 @@ import 'package:flutter_riverpod/flutter_riverpod.dart';
 import 'package:macos_ui/macos_ui.dart';
 import 'package:map_core/map_core.dart';
 
+import '../../application/models/environment_area_generation_readiness.dart';
 import '../../features/editor/state/editor_notifier.dart';
 import '../../features/editor/state/editor_selectors.dart';
 import '../../features/editor/tools/editor_tool.dart';
@@ -139,6 +140,7 @@ class EnvironmentLayerInspectorPanel extends ConsumerWidget {
                     subtleColor: subtle,
                     resolvedTargetTileLayer: target,
                     targetTileLayerInvalid: invalidTarget,
+                    hasTargetTileLayerId: tid != null,
                   ),
                 ),
               const SizedBox(height: 10),
@@ -339,6 +341,7 @@ class _EnvironmentAreaCard extends ConsumerWidget {
     required this.subtleColor,
     required this.resolvedTargetTileLayer,
     required this.targetTileLayerInvalid,
+    required this.hasTargetTileLayerId,
   });
 
   final EnvironmentArea area;
@@ -350,6 +353,7 @@ class _EnvironmentAreaCard extends ConsumerWidget {
   /// `null` si pas de cible ou cible non résolue.
   final TileLayer? resolvedTargetTileLayer;
   final bool targetTileLayerInvalid;
+  final bool hasTargetTileLayerId;
 
   EnvironmentPreset? _presetForArea() {
     final m = manifest;
@@ -360,55 +364,6 @@ class _EnvironmentAreaCard extends ConsumerWidget {
     return null;
   }
 
-  /// Premier blocage UX pour désactiver « Générer dans la map » (ordre stable).
-  String? _generateDisabledReason(EnvironmentPreset? preset) {
-    if (resolvedTargetTileLayer == null || targetTileLayerInvalid) {
-      return 'Choisissez un TileLayer cible avant de générer.';
-    }
-    if (preset == null) {
-      return 'Le preset associé est introuvable.';
-    }
-    if (area.generatedPlacementIds.isNotEmpty) {
-      return 'Cette zone possède déjà des placements générés. Utilisez « Effacer », '
-          '« Régénérer » ou « Mélanger et régénérer ».';
-    }
-    if (area.mask.activeCellCount == 0) {
-      return 'Peignez le masque avant de générer.';
-    }
-    return null;
-  }
-
-  /// Ordre stable des blocages UX pour « Régénérer » (Lot 27).
-  String? _regenerateDisabledReason(EnvironmentPreset? preset) {
-    if (area.generatedPlacementIds.isEmpty) {
-      return 'Aucun placement généré à régénérer.';
-    }
-    if (area.mask.activeCellCount == 0) {
-      return 'Peignez le masque avant de régénérer.';
-    }
-    if (resolvedTargetTileLayer == null || targetTileLayerInvalid) {
-      return 'Choisissez un TileLayer cible avant de régénérer.';
-    }
-    if (preset == null) {
-      return 'Le preset associé est introuvable.';
-    }
-    return null;
-  }
-
-  /// Ordre stable pour « Mélanger et régénérer » (Lot 27).
-  String? _shuffleDisabledReason(EnvironmentPreset? preset) {
-    if (area.mask.activeCellCount == 0) {
-      return 'Peignez le masque avant de mélanger et régénérer.';
-    }
-    if (resolvedTargetTileLayer == null || targetTileLayerInvalid) {
-      return 'Choisissez un TileLayer cible avant de mélanger et régénérer.';
-    }
-    if (preset == null) {
-      return 'Le preset associé est introuvable.';
-    }
-    return null;
-  }
-
   @override
   Widget build(BuildContext context, WidgetRef ref) {
     final notifier = ref.read(editorNotifierProvider.notifier);
@@ -416,17 +371,18 @@ class _EnvironmentAreaCard extends ConsumerWidget {
     final manifestPresets =
         manifest?.environmentPresets ?? const <EnvironmentPreset>[];
     final preset = _presetForArea();
-    final generateReason = _generateDisabledReason(preset);
-    final generateEnabled = generateReason == null;
-    final regenerateReason = _regenerateDisabledReason(preset);
-    final shuffleReason = _shuffleDisabledReason(preset);
-    final hasGeneratedPlacements = area.generatedPlacementIds.isNotEmpty;
+    final readiness = EnvironmentAreaGenerationReadiness.evaluate(
+      area: area,
+      preset: preset,
+      hasTargetTileLayerId: hasTargetTileLayerId,
+      targetTileLayerInvalid: targetTileLayerInvalid,
+      resolvedTargetTileLayer: resolvedTargetTileLayer,
+    );
+    final regenerateEnabled = readiness.canRegenerate;
+    final shuffleEnabled = readiness.canShuffle;
     final totalCells = area.mask.width * area.mask.height;
     final activeCount = area.mask.activeCellCount;
-    final maskLabel = activeCount == 0
-        ? 'Masque vide — cliquez « Peindre le masque », puis dessinez sur la map.\n'
-            '($activeCount / $totalCells cellules actives)'
-        : 'Masque : $activeCount / $totalCells cellules actives';
+    final maskLabel = 'Masque : $activeCount / $totalCells cellules actives';
     final warnPlacements = area.generatedPlacementIds.isNotEmpty;
     final isThisAreaActiveForMask = editorState.activeLayerId == layerId &&
         editorState.selectedEnvironmentAreaId == area.id;
@@ -535,6 +491,16 @@ class _EnvironmentAreaCard extends ConsumerWidget {
                   fontWeight: FontWeight.w600,
                 ),
               ),
+              const SizedBox(height: 6),
+              Text(
+                readiness.stateSummaryLine,
+                key: Key('env-area-readiness-summary-${area.id}'),
+                style: TextStyle(
+                  color: labelColor,
+                  fontSize: 11,
+                  fontWeight: FontWeight.w800,
+                ),
+              ),
               if (warnPlacements) ...[
                 const SizedBox(height: 6),
                 Text(
@@ -581,7 +547,7 @@ class _EnvironmentAreaCard extends ConsumerWidget {
               ),
               const SizedBox(height: 10),
               Text(
-                generateReason ?? _kGenerateHelp,
+                readiness.generateDisabledMessage ?? _kGenerateHelp,
                 key: Key('env-area-generate-hint-${area.id}'),
                 style: TextStyle(
                   color: subtleColor,
@@ -594,7 +560,7 @@ class _EnvironmentAreaCard extends ConsumerWidget {
               PushButton(
                 key: Key('env-area-generate-${area.id}'),
                 controlSize: ControlSize.regular,
-                onPressed: generateEnabled
+                onPressed: readiness.canGenerate
                     ? () => notifier.generateEnvironmentAreaPlacements(
                           environmentLayerId: layerId,
                           areaId: area.id,
@@ -604,8 +570,10 @@ class _EnvironmentAreaCard extends ConsumerWidget {
               ),
               const SizedBox(height: 10),
               Text(
-                regenerateReason ?? _kRegenerateHelp,
-                key: Key('env-area-regenerate-hint-${area.id}'),
+                readiness.clearDisabledMessage == null
+                    ? _kClearHelp
+                    : readiness.clearDisabledMessage!,
+                key: Key('env-area-clear-hint-${area.id}'),
                 style: TextStyle(
                   color: subtleColor,
                   fontSize: 10.5,
@@ -615,21 +583,21 @@ class _EnvironmentAreaCard extends ConsumerWidget {
               ),
               const SizedBox(height: 6),
               PushButton(
-                key: Key('env-area-regenerate-${area.id}'),
+                key: Key('env-area-clear-${area.id}'),
                 controlSize: ControlSize.regular,
                 secondary: true,
-                onPressed: regenerateReason == null
-                    ? () => notifier.regenerateEnvironmentAreaPlacements(
+                onPressed: readiness.canClear
+                    ? () => notifier.clearEnvironmentGeneratedPlacements(
                           environmentLayerId: layerId,
                           areaId: area.id,
                         )
                     : null,
-                child: const Text('Régénérer'),
+                child: const Text('Effacer les placements générés'),
               ),
               const SizedBox(height: 10),
               Text(
-                shuffleReason ?? _kShuffleHelp,
-                key: Key('env-area-shuffle-hint-${area.id}'),
+                readiness.regenerateDisabledMessage ?? _kRegenerateHelp,
+                key: Key('env-area-regenerate-hint-${area.id}'),
                 style: TextStyle(
                   color: subtleColor,
                   fontSize: 10.5,
@@ -639,23 +607,21 @@ class _EnvironmentAreaCard extends ConsumerWidget {
               ),
               const SizedBox(height: 6),
               PushButton(
-                key: Key('env-area-shuffle-${area.id}'),
+                key: Key('env-area-regenerate-${area.id}'),
                 controlSize: ControlSize.regular,
                 secondary: true,
-                onPressed: shuffleReason == null
-                    ? () => notifier.shuffleEnvironmentAreaPlacements(
+                onPressed: regenerateEnabled
+                    ? () => notifier.regenerateEnvironmentAreaPlacements(
                           environmentLayerId: layerId,
                           areaId: area.id,
                         )
                     : null,
-                child: const Text('Mélanger et régénérer'),
+                child: const Text('Régénérer'),
               ),
               const SizedBox(height: 10),
               Text(
-                hasGeneratedPlacements
-                    ? _kClearHelp
-                    : 'Aucun placement généré à effacer.',
-                key: Key('env-area-clear-hint-${area.id}'),
+                readiness.shuffleDisabledMessage ?? _kShuffleHelp,
+                key: Key('env-area-shuffle-hint-${area.id}'),
                 style: TextStyle(
                   color: subtleColor,
                   fontSize: 10.5,
@@ -665,16 +631,16 @@ class _EnvironmentAreaCard extends ConsumerWidget {
               ),
               const SizedBox(height: 6),
               PushButton(
-                key: Key('env-area-clear-${area.id}'),
+                key: Key('env-area-shuffle-${area.id}'),
                 controlSize: ControlSize.regular,
                 secondary: true,
-                onPressed: hasGeneratedPlacements
-                    ? () => notifier.clearEnvironmentGeneratedPlacements(
+                onPressed: shuffleEnabled
+                    ? () => notifier.shuffleEnvironmentAreaPlacements(
                           environmentLayerId: layerId,
                           areaId: area.id,
                         )
                     : null,
-                child: const Text('Effacer les placements générés'),
+                child: const Text('Mélanger et régénérer'),
               ),
               const SizedBox(height: 10),
               PushButton(
```

### Nouveau : environment_area_generation_readiness.dart
```diff
diff --git a/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/models/environment_area_generation_readiness.dart b/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/models/environment_area_generation_readiness.dart
new file mode 100644
index 00000000..a0c5c50c
--- /dev/null
+++ b/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/models/environment_area_generation_readiness.dart
@@ -0,0 +1,161 @@
+import 'package:map_core/map_core.dart';
+
+// ---------------------------------------------------------------------------
+// Lot Environment-28 — règles Golden Slice (readiness) pour une EnvironmentArea.
+// Pur Dart, testable sans Flutter ; ne remplace pas la validation des use cases.
+// ---------------------------------------------------------------------------
+
+/// Premier blocage « métier » pour le résumé d’état (ordre stable d’affichage).
+enum EnvironmentAreaGenerationPrimaryBlocker {
+  none,
+  missingPreset,
+  invalidTargetTileLayer,
+  missingTargetTileLayer,
+  emptyMask,
+  alreadyGenerated,
+}
+
+/// Règles UX centralisées : boutons activables + messages de désactivation + résumé.
+///
+/// Aligné sur Lots 25–27 : Generate / Clear / Regenerate / Shuffle.
+final class EnvironmentAreaGenerationReadiness {
+  const EnvironmentAreaGenerationReadiness({
+    required this.canGenerate,
+    required this.canClear,
+    required this.canRegenerate,
+    required this.canShuffle,
+    required this.generateDisabledMessage,
+    required this.clearDisabledMessage,
+    required this.regenerateDisabledMessage,
+    required this.shuffleDisabledMessage,
+    required this.stateSummaryLine,
+    required this.primaryBlocker,
+  });
+
+  final bool canGenerate;
+  final bool canClear;
+  final bool canRegenerate;
+  final bool canShuffle;
+
+  /// Non null ssi l’action correspondante est désactivée.
+  final String? generateDisabledMessage;
+  final String? clearDisabledMessage;
+  final String? regenerateDisabledMessage;
+  final String? shuffleDisabledMessage;
+
+  /// Une ligne courte du type `État : …` pour l’inspecteur.
+  final String stateSummaryLine;
+
+  final EnvironmentAreaGenerationPrimaryBlocker primaryBlocker;
+
+  /// [hasTargetTileLayerId] : [EnvironmentLayerContent.targetTileLayerId] non null.
+  /// [targetTileLayerInvalid] : id présent mais [resolvedTargetTileLayer] null.
+  static EnvironmentAreaGenerationReadiness evaluate({
+    required EnvironmentArea area,
+    required EnvironmentPreset? preset,
+    required bool hasTargetTileLayerId,
+    required bool targetTileLayerInvalid,
+    required TileLayer? resolvedTargetTileLayer,
+  }) {
+    final missingTarget = !hasTargetTileLayerId;
+    final invalidTarget = hasTargetTileLayerId && targetTileLayerInvalid;
+    final targetOk = hasTargetTileLayerId &&
+        !targetTileLayerInvalid &&
+        resolvedTargetTileLayer != null;
+
+    final maskOk = area.mask.activeCellCount > 0;
+    final presetOk = preset != null;
+    final noGeneratedYet = area.generatedPlacementIds.isEmpty;
+    final hasGenerated = area.generatedPlacementIds.isNotEmpty;
+
+    final canGenerate = targetOk && presetOk && maskOk && noGeneratedYet;
+    final canClear = hasGenerated;
+    final canRegenerate = targetOk && presetOk && maskOk && hasGenerated;
+    final canShuffle = targetOk && presetOk && maskOk;
+
+    String? genMsg;
+    if (!canGenerate) {
+      if (missingTarget) {
+        genMsg = 'Choisissez un TileLayer cible avant de générer.';
+      } else if (invalidTarget) {
+        genMsg = 'Le TileLayer cible est introuvable ou invalide.';
+      } else if (!presetOk) {
+        genMsg = 'Le preset associé est introuvable.';
+      } else if (!noGeneratedYet) {
+        genMsg = 'Cette zone possède déjà des placements générés. Utilisez '
+            '« Effacer les placements générés », « Régénérer » ou '
+            '« Mélanger et régénérer ».';
+      } else if (!maskOk) {
+        genMsg = 'Peignez le masque avant de générer.';
+      }
+    }
+
+    final clearMsg = canClear ? null : 'Aucun placement généré à effacer.';
+
+    String? regMsg;
+    if (!canRegenerate) {
+      if (!hasGenerated) {
+        regMsg = 'Aucun placement généré à régénérer.';
+      } else if (missingTarget) {
+        regMsg = 'Choisissez un TileLayer cible avant de régénérer.';
+      } else if (invalidTarget) {
+        regMsg = 'Le TileLayer cible est introuvable ou invalide.';
+      } else if (!presetOk) {
+        regMsg = 'Le preset associé est introuvable.';
+      } else if (!maskOk) {
+        regMsg = 'Peignez le masque avant de régénérer.';
+      }
+    }
+
+    String? shufMsg;
+    if (!canShuffle) {
+      if (missingTarget) {
+        shufMsg = 'Choisissez un TileLayer cible avant de mélanger.';
+      } else if (invalidTarget) {
+        shufMsg = 'Le TileLayer cible est introuvable ou invalide.';
+      } else if (!presetOk) {
+        shufMsg = 'Le preset associé est introuvable.';
+      } else if (!maskOk) {
+        shufMsg = 'Peignez le masque avant de mélanger.';
+      }
+    }
+
+    EnvironmentAreaGenerationPrimaryBlocker blocker;
+    String summary;
+    if (canGenerate) {
+      blocker = EnvironmentAreaGenerationPrimaryBlocker.none;
+      summary = 'État : prêt à générer';
+    } else if (!presetOk) {
+      blocker = EnvironmentAreaGenerationPrimaryBlocker.missingPreset;
+      summary = 'État : preset introuvable';
+    } else if (invalidTarget) {
+      blocker = EnvironmentAreaGenerationPrimaryBlocker.invalidTargetTileLayer;
+      summary = 'État : cible invalide';
+    } else if (missingTarget) {
+      blocker = EnvironmentAreaGenerationPrimaryBlocker.missingTargetTileLayer;
+      summary = 'État : cible manquante';
+    } else if (!maskOk) {
+      blocker = EnvironmentAreaGenerationPrimaryBlocker.emptyMask;
+      summary = 'État : masque vide';
+    } else if (!noGeneratedYet) {
+      blocker = EnvironmentAreaGenerationPrimaryBlocker.alreadyGenerated;
+      summary = 'État : déjà généré';
+    } else {
+      blocker = EnvironmentAreaGenerationPrimaryBlocker.none;
+      summary = 'État : en cours de configuration';
+    }
+
+    return EnvironmentAreaGenerationReadiness(
+      canGenerate: canGenerate,
+      canClear: canClear,
+      canRegenerate: canRegenerate,
+      canShuffle: canShuffle,
+      generateDisabledMessage: genMsg,
+      clearDisabledMessage: clearMsg,
+      regenerateDisabledMessage: regMsg,
+      shuffleDisabledMessage: shufMsg,
+      stateSummaryLine: summary,
+      primaryBlocker: blocker,
+    );
+  }
+}
```

### Nouveau : environment_area_generation_readiness_test.dart
```diff
diff --git a/Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_area_generation_readiness_test.dart b/Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_area_generation_readiness_test.dart
new file mode 100644
index 00000000..c72a5b5c
--- /dev/null
+++ b/Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_area_generation_readiness_test.dart
@@ -0,0 +1,261 @@
+// ignore_for_file: prefer_const_constructors
+
+import 'package:flutter_test/flutter_test.dart';
+import 'package:map_core/map_core.dart';
+import 'package:map_editor/src/application/models/environment_area_generation_readiness.dart';
+
+EnvironmentArea _area({
+  List<String>? generated,
+  List<bool>? cells,
+  int w = 2,
+  int h = 2,
+}) {
+  final c = cells ?? List<bool>.filled(w * h, true);
+  return EnvironmentArea(
+    id: 'z1',
+    name: 'Z',
+    presetId: 'p1',
+    mask: EnvironmentAreaMask(width: w, height: h, cells: c),
+    seed: 1,
+    generatedPlacementIds: generated,
+  );
+}
+
+EnvironmentPreset _preset() {
+  return EnvironmentPreset(
+    id: 'p1',
+    name: 'P',
+    templateId: 't',
+    palette: [
+      EnvironmentPaletteItem(elementId: 'e1', weight: 1),
+    ],
+    defaultParams: EnvironmentGenerationParams.standard(),
+    sortOrder: 0,
+  );
+}
+
+void main() {
+  group('EnvironmentAreaGenerationReadiness', () {
+    test('prêt à générer : cible + preset + masque + pas encore généré', () {
+      final r = EnvironmentAreaGenerationReadiness.evaluate(
+        area: _area(),
+        preset: _preset(),
+        hasTargetTileLayerId: true,
+        targetTileLayerInvalid: false,
+        resolvedTargetTileLayer: TileLayer(
+          id: 'tiles',
+          name: 'T',
+          tiles: List<int>.filled(4, 0),
+        ),
+      );
+      expect(r.canGenerate, isTrue);
+      expect(r.canClear, isFalse);
+      expect(r.canRegenerate, isFalse);
+      expect(r.canShuffle, isTrue);
+      expect(r.stateSummaryLine, 'État : prêt à générer');
+      expect(r.generateDisabledMessage, isNull);
+    });
+
+    test('Generate désactivé : preset introuvable', () {
+      final r = EnvironmentAreaGenerationReadiness.evaluate(
+        area: _area(),
+        preset: null,
+        hasTargetTileLayerId: true,
+        targetTileLayerInvalid: false,
+        resolvedTargetTileLayer: TileLayer(
+          id: 'tiles',
+          name: 'T',
+          tiles: List<int>.filled(4, 0),
+        ),
+      );
+      expect(r.canGenerate, isFalse);
+      expect(
+        r.generateDisabledMessage,
+        'Le preset associé est introuvable.',
+      );
+      expect(r.stateSummaryLine, 'État : preset introuvable');
+    });
+
+    test('Generate désactivé : cible manquante', () {
+      final r = EnvironmentAreaGenerationReadiness.evaluate(
+        area: _area(),
+        preset: _preset(),
+        hasTargetTileLayerId: false,
+        targetTileLayerInvalid: false,
+        resolvedTargetTileLayer: null,
+      );
+      expect(r.canGenerate, isFalse);
+      expect(
+        r.generateDisabledMessage,
+        'Choisissez un TileLayer cible avant de générer.',
+      );
+      expect(r.stateSummaryLine, 'État : cible manquante');
+    });
+
+    test('Generate désactivé : cible invalide', () {
+      final r = EnvironmentAreaGenerationReadiness.evaluate(
+        area: _area(),
+        preset: _preset(),
+        hasTargetTileLayerId: true,
+        targetTileLayerInvalid: true,
+        resolvedTargetTileLayer: null,
+      );
+      expect(r.canGenerate, isFalse);
+      expect(
+        r.generateDisabledMessage,
+        'Le TileLayer cible est introuvable ou invalide.',
+      );
+      expect(r.stateSummaryLine, 'État : cible invalide');
+    });
+
+    test('Generate désactivé : masque vide', () {
+      final r = EnvironmentAreaGenerationReadiness.evaluate(
+        area: _area(cells: List<bool>.filled(4, false)),
+        preset: _preset(),
+        hasTargetTileLayerId: true,
+        targetTileLayerInvalid: false,
+        resolvedTargetTileLayer: TileLayer(
+          id: 'tiles',
+          name: 'T',
+          tiles: List<int>.filled(4, 0),
+        ),
+      );
+      expect(r.canGenerate, isFalse);
+      expect(
+        r.generateDisabledMessage,
+        'Peignez le masque avant de générer.',
+      );
+      expect(r.stateSummaryLine, 'État : masque vide');
+    });
+
+    test('Generate désactivé : déjà généré', () {
+      final r = EnvironmentAreaGenerationReadiness.evaluate(
+        area: _area(generated: const ['x']),
+        preset: _preset(),
+        hasTargetTileLayerId: true,
+        targetTileLayerInvalid: false,
+        resolvedTargetTileLayer: TileLayer(
+          id: 'tiles',
+          name: 'T',
+          tiles: List<int>.filled(4, 0),
+        ),
+      );
+      expect(r.canGenerate, isFalse);
+      expect(r.canClear, isTrue);
+      expect(r.canRegenerate, isTrue);
+      expect(r.canShuffle, isTrue);
+      expect(
+        r.generateDisabledMessage,
+        contains('déjà des placements générés'),
+      );
+      expect(r.stateSummaryLine, 'État : déjà généré');
+    });
+
+    test('Clear désactivé sans placements', () {
+      final r = EnvironmentAreaGenerationReadiness.evaluate(
+        area: _area(),
+        preset: _preset(),
+        hasTargetTileLayerId: true,
+        targetTileLayerInvalid: false,
+        resolvedTargetTileLayer: TileLayer(
+          id: 'tiles',
+          name: 'T',
+          tiles: List<int>.filled(4, 0),
+        ),
+      );
+      expect(r.canClear, isFalse);
+      expect(
+        r.clearDisabledMessage,
+        'Aucun placement généré à effacer.',
+      );
+    });
+
+    test('Regenerate désactivé sans placements', () {
+      final r = EnvironmentAreaGenerationReadiness.evaluate(
+        area: _area(),
+        preset: _preset(),
+        hasTargetTileLayerId: true,
+        targetTileLayerInvalid: false,
+        resolvedTargetTileLayer: TileLayer(
+          id: 'tiles',
+          name: 'T',
+          tiles: List<int>.filled(4, 0),
+        ),
+      );
+      expect(r.canRegenerate, isFalse);
+      expect(
+          r.regenerateDisabledMessage, 'Aucun placement généré à régénérer.');
+    });
+
+    test('Shuffle activé sans placements générés si masque + cible + preset',
+        () {
+      final r = EnvironmentAreaGenerationReadiness.evaluate(
+        area: _area(),
+        preset: _preset(),
+        hasTargetTileLayerId: true,
+        targetTileLayerInvalid: false,
+        resolvedTargetTileLayer: TileLayer(
+          id: 'tiles',
+          name: 'T',
+          tiles: List<int>.filled(4, 0),
+        ),
+      );
+      expect(r.canShuffle, isTrue);
+      expect(r.shuffleDisabledMessage, isNull);
+    });
+
+    test('Shuffle désactivé : masque vide', () {
+      final r = EnvironmentAreaGenerationReadiness.evaluate(
+        area: _area(cells: List<bool>.filled(4, false)),
+        preset: _preset(),
+        hasTargetTileLayerId: true,
+        targetTileLayerInvalid: false,
+        resolvedTargetTileLayer: TileLayer(
+          id: 'tiles',
+          name: 'T',
+          tiles: List<int>.filled(4, 0),
+        ),
+      );
+      expect(r.canShuffle, isFalse);
+      expect(
+        r.shuffleDisabledMessage,
+        'Peignez le masque avant de mélanger.',
+      );
+    });
+
+    test('Shuffle désactivé : preset manquant', () {
+      final r = EnvironmentAreaGenerationReadiness.evaluate(
+        area: _area(),
+        preset: null,
+        hasTargetTileLayerId: true,
+        targetTileLayerInvalid: false,
+        resolvedTargetTileLayer: TileLayer(
+          id: 'tiles',
+          name: 'T',
+          tiles: List<int>.filled(4, 0),
+        ),
+      );
+      expect(r.canShuffle, isFalse);
+      expect(
+        r.shuffleDisabledMessage,
+        'Le preset associé est introuvable.',
+      );
+      expect(r.stateSummaryLine, 'État : preset introuvable');
+    });
+
+    test('Shuffle désactivé : cible manquante', () {
+      final r = EnvironmentAreaGenerationReadiness.evaluate(
+        area: _area(),
+        preset: _preset(),
+        hasTargetTileLayerId: false,
+        targetTileLayerInvalid: false,
+        resolvedTargetTileLayer: null,
+      );
+      expect(r.canShuffle, isFalse);
+      expect(
+        r.shuffleDisabledMessage,
+        'Choisissez un TileLayer cible avant de mélanger.',
+      );
+    });
+  });
+}
```

### Nouveau : environment_golden_slice_workflow_test.dart
```diff
diff --git a/Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_golden_slice_workflow_test.dart b/Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_golden_slice_workflow_test.dart
new file mode 100644
index 00000000..f3f0ef04
--- /dev/null
+++ b/Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_golden_slice_workflow_test.dart
@@ -0,0 +1,384 @@
+// ignore_for_file: prefer_const_constructors
+
+import 'package:flutter/cupertino.dart';
+import 'package:flutter/material.dart';
+import 'package:flutter_riverpod/flutter_riverpod.dart';
+import 'package:flutter_test/flutter_test.dart';
+import 'package:macos_ui/macos_ui.dart';
+import 'package:map_core/map_core.dart';
+import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
+import 'package:map_editor/src/features/editor/state/editor_state.dart';
+import 'package:map_editor/src/features/editor/tools/editor_tool.dart';
+import 'package:map_editor/src/ui/panels/environment_layer_inspector_panel.dart';
+
+import '../shell_chrome_test_harness.dart';
+
+ProjectManifest _manifest() {
+  return buildShellChromeProject(
+    environmentPresets: [
+      EnvironmentPreset(
+        id: 'p1',
+        name: 'P',
+        templateId: 't',
+        palette: [
+          EnvironmentPaletteItem(elementId: 'e1', weight: 1),
+        ],
+        defaultParams: EnvironmentGenerationParams(
+          density: 1,
+          edgeDensity: 1,
+          variation: 0,
+          minSpacingCells: 0,
+        ),
+        sortOrder: 0,
+      ),
+    ],
+    elements: const [
+      ProjectElementEntry(
+        id: 'e1',
+        name: 'E',
+        tilesetId: 'tsA',
+        categoryId: 'c',
+        frames: [
+          TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0)),
+        ],
+      ),
+    ],
+  );
+}
+
+EnvironmentArea _area({List<String>? generated}) {
+  return EnvironmentArea(
+    id: 'area1',
+    name: 'Z',
+    presetId: 'p1',
+    mask: EnvironmentAreaMask(
+      width: 2,
+      height: 2,
+      cells: List<bool>.filled(4, true),
+    ),
+    seed: 42,
+    generatedPlacementIds: generated,
+  );
+}
+
+MapData _map(EnvironmentArea area) {
+  final env = MapLayer.environment(
+    id: 'env',
+    name: 'E',
+    content: EnvironmentLayerContent(
+      targetTileLayerId: 'tiles',
+      areas: [area],
+    ),
+  );
+  final tile = TileLayer(
+    id: 'tiles',
+    name: 'T',
+    tiles: List<int>.filled(4, 0),
+  );
+  return MapData(
+    id: 'm',
+    name: 'M',
+    size: const GridSize(width: 2, height: 2),
+    tilesetId: 'tsA',
+    layers: [env, tile],
+    placedElements: const [
+      MapPlacedElement(
+        id: 'manual_keep',
+        layerId: 'tiles',
+        elementId: 'e1',
+        pos: GridPos(x: 1, y: 1),
+      ),
+    ],
+  );
+}
+
+void main() {
+  group('Golden Slice — workflow notifier complet', () {
+    test('generate → clear → generate → regenerate → shuffle ; manuel conservé',
+        () {
+      final container = ProviderContainer();
+      addTearDown(container.dispose);
+      var area = _area();
+      var map = _map(area);
+      container.read(editorNotifierProvider.notifier).state = EditorState(
+        projectRootPath: '/golden',
+        project: _manifest(),
+        activeMap: map,
+        activeMapPath: 'maps/x.json',
+        activeLayerId: 'env',
+        selectedEnvironmentAreaId: 'area1',
+        environmentMaskEditMode: EnvironmentMaskEditMode.paint,
+        savedMapSnapshot: map,
+      );
+      final notifier = container.read(editorNotifierProvider.notifier);
+
+      notifier.generateEnvironmentAreaPlacements(
+        environmentLayerId: 'env',
+        areaId: 'area1',
+      );
+      var s = container.read(editorNotifierProvider);
+      expect(s.activeMap!.placedElements.length, greaterThan(1));
+      expect(
+        (s.activeMap!.layers.first as EnvironmentLayer)
+            .content
+            .areas
+            .single
+            .generatedPlacementIds,
+        isNotEmpty,
+      );
+      expect(
+        s.activeMap!.placedElements.any((p) => p.id == 'manual_keep'),
+        isTrue,
+      );
+      expect(s.environmentMaskEditMode, isNull);
+
+      notifier.clearEnvironmentGeneratedPlacements(
+        environmentLayerId: 'env',
+        areaId: 'area1',
+      );
+      s = container.read(editorNotifierProvider);
+      expect(
+        (s.activeMap!.layers.first as EnvironmentLayer)
+            .content
+            .areas
+            .single
+            .generatedPlacementIds,
+        isEmpty,
+      );
+      expect(s.activeMap!.placedElements.map((e) => e.id).toList(),
+          ['manual_keep']);
+
+      notifier.generateEnvironmentAreaPlacements(
+        environmentLayerId: 'env',
+        areaId: 'area1',
+      );
+      s = container.read(editorNotifierProvider);
+      expect(s.activeMap!.placedElements.length, greaterThan(1));
+      final seedBeforeRegen = (s.activeMap!.layers.first as EnvironmentLayer)
+          .content
+          .areas
+          .single
+          .seed;
+
+      notifier.regenerateEnvironmentAreaPlacements(
+        environmentLayerId: 'env',
+        areaId: 'area1',
+      );
+      s = container.read(editorNotifierProvider);
+      expect(s.activeMap!.placedElements.length, greaterThan(1));
+      expect(
+        (s.activeMap!.layers.first as EnvironmentLayer)
+            .content
+            .areas
+            .single
+            .seed,
+        seedBeforeRegen,
+      );
+      expect(
+        s.activeMap!.placedElements.any((p) => p.id == 'manual_keep'),
+        isTrue,
+      );
+
+      final seedBeforeShuffle = (s.activeMap!.layers.first as EnvironmentLayer)
+          .content
+          .areas
+          .single
+          .seed;
+      notifier.shuffleEnvironmentAreaPlacements(
+        environmentLayerId: 'env',
+        areaId: 'area1',
+      );
+      s = container.read(editorNotifierProvider);
+      final areaOut =
+          (s.activeMap!.layers.first as EnvironmentLayer).content.areas.single;
+      expect(areaOut.seed, isNot(seedBeforeShuffle));
+      expect(areaOut.generatedPlacementIds, isNotEmpty);
+      expect(
+        s.activeMap!.placedElements.any((p) => p.id == 'manual_keep'),
+        isTrue,
+      );
+    });
+
+    test(
+        'shuffle sans placements générés préalables : seed change et placements',
+        () {
+      final container = ProviderContainer();
+      addTearDown(container.dispose);
+      final area = _area();
+      final map = _map(area);
+      container.read(editorNotifierProvider.notifier).state = EditorState(
+        projectRootPath: '/golden',
+        project: _manifest(),
+        activeMap: map,
+        activeMapPath: 'maps/x.json',
+        activeLayerId: 'env',
+        selectedEnvironmentAreaId: 'area1',
+        savedMapSnapshot: map,
+      );
+      final notifier = container.read(editorNotifierProvider.notifier);
+      final seed0 = (container
+              .read(editorNotifierProvider)
+              .activeMap!
+              .layers
+              .first as EnvironmentLayer)
+          .content
+          .areas
+          .single
+          .seed;
+
+      notifier.shuffleEnvironmentAreaPlacements(
+        environmentLayerId: 'env',
+        areaId: 'area1',
+      );
+      final s = container.read(editorNotifierProvider);
+      final areaOut =
+          (s.activeMap!.layers.first as EnvironmentLayer).content.areas.single;
+      expect(areaOut.seed, isNot(seed0));
+      expect(areaOut.generatedPlacementIds, isNotEmpty);
+      expect(s.activeMap!.placedElements.length, greaterThan(1));
+    });
+
+    test('clear sans placements : message statut, carte inchangée', () {
+      final container = ProviderContainer();
+      addTearDown(container.dispose);
+      final area = _area();
+      final map = _map(area);
+      container.read(editorNotifierProvider.notifier).state = EditorState(
+        projectRootPath: '/golden',
+        project: _manifest(),
+        activeMap: map,
+        activeMapPath: 'maps/x.json',
+        activeLayerId: 'env',
+        savedMapSnapshot: map,
+      );
+      final notifier = container.read(editorNotifierProvider.notifier);
+      notifier.clearEnvironmentGeneratedPlacements(
+        environmentLayerId: 'env',
+        areaId: 'area1',
+      );
+      final s = container.read(editorNotifierProvider);
+      expect(
+          s.statusMessage, 'Aucun placement généré à effacer pour cette zone.');
+      expect(identical(s.activeMap, map), isTrue);
+    });
+  });
+
+  group('Golden Slice — inspecteur minimal', () {
+    testWidgets('résumé + Generate activé quand prêt', (tester) async {
+      final area = _area();
+      final env = MapLayer.environment(
+        id: 'env',
+        name: 'E',
+        content: EnvironmentLayerContent(
+          targetTileLayerId: 'tiles',
+          areas: [area],
+        ),
+      );
+      final tile = TileLayer(
+        id: 'tiles',
+        name: 'T',
+        tiles: List<int>.filled(4, 0),
+      );
+      final map = MapData(
+        id: 'm',
+        name: 'M',
+        size: const GridSize(width: 2, height: 2),
+        tilesetId: 'tsA',
+        layers: [env, tile],
+      );
+      final container = ProviderContainer();
+      addTearDown(container.dispose);
+      container.read(editorNotifierProvider.notifier).state = EditorState(
+        projectRootPath: '/g',
+        project: _manifest(),
+        activeMap: map,
+        activeMapPath: 'maps/x.json',
+        activeLayerId: 'env',
+      );
+      await tester.pumpWidget(
+        UncontrolledProviderScope(
+          container: container,
+          child: MacosTheme(
+            data: MacosThemeData.light(),
+            child: MaterialApp(
+              home: CupertinoPageScaffold(
+                child: EnvironmentLayerInspectorPanel(
+                  map: map,
+                  layer: env as EnvironmentLayer,
+                ),
+              ),
+            ),
+          ),
+        ),
+      );
+      await tester.pumpAndSettle();
+      expect(find.text('État : prêt à générer'), findsOneWidget);
+      expect(
+        tester
+            .widget<PushButton>(
+              find.byKey(const Key('env-area-generate-area1')),
+            )
+            .onPressed,
+        isNotNull,
+      );
+    });
+
+    testWidgets('Generate désactivé sans cible TileLayer', (tester) async {
+      final area = _area();
+      final env = MapLayer.environment(
+        id: 'env',
+        name: 'E',
+        content: EnvironmentLayerContent(
+          targetTileLayerId: null,
+          areas: [area],
+        ),
+      );
+      final tile = TileLayer(
+        id: 'tiles',
+        name: 'T',
+        tiles: List<int>.filled(4, 0),
+      );
+      final map = MapData(
+        id: 'm',
+        name: 'M',
+        size: const GridSize(width: 2, height: 2),
+        layers: [env, tile],
+      );
+      final container = ProviderContainer();
+      addTearDown(container.dispose);
+      container.read(editorNotifierProvider.notifier).state = EditorState(
+        projectRootPath: '/g',
+        project: _manifest(),
+        activeMap: map,
+        activeLayerId: 'env',
+      );
+      await tester.pumpWidget(
+        UncontrolledProviderScope(
+          container: container,
+          child: MacosTheme(
+            data: MacosThemeData.light(),
+            child: MaterialApp(
+              home: CupertinoPageScaffold(
+                child: EnvironmentLayerInspectorPanel(
+                  map: map,
+                  layer: env as EnvironmentLayer,
+                ),
+              ),
+            ),
+          ),
+        ),
+      );
+      await tester.pumpAndSettle();
+      expect(
+        tester
+            .widget<PushButton>(
+              find.byKey(const Key('env-area-generate-area1')),
+            )
+            .onPressed,
+        isNull,
+      );
+      expect(
+          find.textContaining('Choisissez un TileLayer cible'), findsWidgets);
+    });
+  });
+}
```

## 20. Auto-review

- **Points solides** : modèle pur testé ; workflow bout-en-bout notifier ; inspecteur minimal widget ; messages FR alignés.
- **Points discutables** : double maintenance légère entre readiness (UI) et garde-fous use cases si l’API notifier est appelée sans passer par l’UI.
- **Corrections faites après auto-review** : harmonisation « Effacer les placements générés » dans readiness + notifier.
- **Risques restants** : `flutter test` global `map_editor` rouge pour dette de tests/catalogues.
- **Regard critique sur le prompt** : modèle readiness dédié justifié (tests unitaires) ; polish inspecteur limité à une carte existante ; tests Golden Slice couvrent le cœur notifier + 2 cas widget ; disabled states explicites via readiness ; aucun map_core / MapCanvas / nouveau moteur.

### Confirmations Evidence Pack (§15)

- Aucun `packages/map_core` modifié par ce lot (voir git status final).
- `map_canvas.dart` non modifié.
- `editor_state.dart` et fichiers generated non modifiés.
- Aucun patch de `TileLayer.tiles` dans ces changements.
- Aucune refonte UI globale ; pas de nouveau moteur de génération.
- Aucune sauvegarde disque dans les flux Golden Slice.
- `saveProject` / `FileProjectRepository` : grep sur les chemins autorisés montre des occurrences **hors** méthodes generate/clear/regenerate/shuffle dans `editor_notifier.dart` (méthodes de session projet).
- Aucun `SurfaceLayer` legacy dans ces changements.
- Aucun `build_runner` lancé.
- Aucun commit / git add / git push.

## 21. Verdict

Statut du lot :

- [x] Validé

Résumé :

```text
Workflow testé de bout en bout ; disabled states testés ; inspecteur plus explicite ; test/environment_studio vert ; flutter test package entier rouge pour dette préexistante (compilation tests catalogues).
```

Prochain lot recommandé :

```text
Environment-29 — Golden Slice Final Validation / Roadmap Cutover
```