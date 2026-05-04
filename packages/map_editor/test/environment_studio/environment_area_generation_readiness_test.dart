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
