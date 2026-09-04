import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/presentation/world_map/world_map_smart_tile_density_section.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';

SmartTileRule _rule() => SmartTileRule(
      id: 'rule-0',
      centerMatch: const SmartTileSlotMatch.any(),
      candidates: <SmartTileCandidate>[
        for (var index = 0; index < 3; index += 1)
          SmartTileCandidate(id: 'cand-$index', weight: 1000),
      ],
    );

Future<void> _pump(WidgetTester tester, {required Widget child}) =>
    tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.dark(),
        home: Scaffold(
          body: SingleChildScrollView(child: child),
        ),
      ),
    );

void main() {
  testWidgets('agrandit la miniature au survol puis ferme l’aperçu', (
    tester,
  ) async {
    await _pump(
      tester,
      child: WorldMapSmartTileDensitySection(
        rule: _rule(),
        layerWeights: const {},
        spriteBuilder: (_) => const SizedBox(width: 24, height: 24),
        enlargedSpriteBuilder: (candidate) => SizedBox(
          key: ValueKey('enlarged-${candidate.id}'),
          width: 128,
          height: 128,
        ),
        onApply: (_, _) async {},
      ),
    );
    await tester.tap(find.byKey(const Key('world-map-density-summary')));
    await tester.pumpAndSettle();
    final target = find.byKey(
      const ValueKey('world-map-density-preview-cand-0'),
    );
    final originalSize = tester.getSize(target);
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer();
    await mouse.moveTo(tester.getCenter(target));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(
      tester.getSize(find.byKey(const ValueKey('enlarged-cand-0'))),
      const Size(128, 128),
    );
    expect(tester.getSize(target), originalSize);
    await mouse.moveTo(const Offset(790, 590));
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('enlarged-cand-0')), findsNothing);
    await mouse.removePointer();
    expect(tester.takeException(), isNull);
  });

  testWidgets('nomme une variante sans appliquer les poids en cours', (
    tester,
  ) async {
    final names = <(String, String)>[];
    final weights = <Map<String, int>>[];
    await _pump(
      tester,
      child: WorldMapSmartTileDensitySection(
        rule: _rule(),
        layerWeights: const {},
        spriteBuilder: (_) => const SizedBox(width: 24, height: 24),
        onApply: (_, value) async => weights.add(value),
        onRename: (id, label) async {
          names.add((id, label));
          return true;
        },
      ),
    );
    await tester.tap(find.byKey(const Key('world-map-density-summary')));
    await tester.pumpAndSettle();
    tester
        .widget<PokeMapGuidedSlider>(
          find.byKey(const ValueKey('world-map-density-cand-0')),
        )
        .onChanged(600);
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('world-map-density-rename-cand-0')),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '  Fleurs crème  ');
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    expect(names, [('cand-0', 'Fleurs crème')]);
    expect(weights, isEmpty);
    expect(
      tester
          .widget<PokeMapGuidedSlider>(
            find.byKey(const ValueKey('world-map-density-cand-0')),
          )
          .value,
      600,
    );
    await tester.tap(
      find.byKey(const ValueKey('world-map-density-rename-cand-1')),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Annulé');
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();
    expect(names, hasLength(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'affiche le libellé et le bon pourcentage dans un panneau étroit',
    (tester) async {
      final rule = _rule();
      await _pump(
        tester,
        child: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 300,
            child: WorldMapSmartTileDensitySection(
              rule: rule.copyWith(
                candidates: [
                  rule.candidates.first.copyWith(label: 'Petites fleurs crème'),
                  ...rule.candidates.skip(1),
                ],
              ),
              layerWeights: const {'cand-0': 57, 'cand-1': 500, 'cand-2': 443},
              spriteBuilder: (_) => const SizedBox(width: 24, height: 24),
              onApply: (_, _) async {},
              onRename: (_, _) async => true,
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(const Key('world-map-density-summary')));
      await tester.pumpAndSettle();
      expect(find.text('Petites fleurs crème'), findsOneWidget);
      expect(find.text('Variante 2'), findsOneWidget);
      expect(find.text('5,7 %'), findsOneWidget);
      expect(find.text('57 %'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('est repliée par défaut et résume les variantes', (tester) async {
    await _pump(
      tester,
      child: WorldMapSmartTileDensitySection(
        rule: _rule(),
        layerWeights: const <String, int>{},
        spriteBuilder: (_) => const SizedBox(width: 24, height: 24),
        onApply: (_, _) async {},
      ),
    );

    expect(find.text('3 variantes'), findsOneWidget);
    expect(find.byType(PokeMapGuidedSlider), findsNothing);
  });

  testWidgets('déplie la liste au clic sur le résumé', (tester) async {
    await _pump(
      tester,
      child: WorldMapSmartTileDensitySection(
        rule: _rule(),
        layerWeights: const <String, int>{},
        spriteBuilder: (_) => const SizedBox(width: 24, height: 24),
        onApply: (_, _) async {},
      ),
    );

    await tester.tap(find.byKey(const Key('world-map-density-summary')));
    await tester.pumpAndSettle();

    expect(find.byType(PokeMapGuidedSlider), findsNWidgets(3));
  });

  testWidgets('affiche « jamais » pour une variante à zéro', (tester) async {
    await _pump(
      tester,
      child: WorldMapSmartTileDensitySection(
        rule: _rule(),
        layerWeights: const <String, int>{
          'cand-0': 0,
          'cand-1': 500,
          'cand-2': 500,
        },
        spriteBuilder: (_) => const SizedBox(width: 24, height: 24),
        onApply: (_, _) async {},
      ),
    );

    await tester.tap(find.byKey(const Key('world-map-density-summary')));
    await tester.pumpAndSettle();

    expect(find.text('jamais'), findsOneWidget);
  });

  testWidgets('Appliquer transmet une table qui somme à 1000, une seule fois',
      (tester) async {
    final applied = <Map<String, int>>[];
    await _pump(
      tester,
      child: WorldMapSmartTileDensitySection(
        rule: _rule(),
        layerWeights: const <String, int>{},
        spriteBuilder: (_) => const SizedBox(width: 24, height: 24),
        onApply: (_, weights) async => applied.add(weights),
      ),
    );

    await tester.tap(find.byKey(const Key('world-map-density-summary')));
    await tester.pumpAndSettle();
    tester
        .widget<PokeMapGuidedSlider>(
          find.byKey(const ValueKey<String>('world-map-density-cand-0')),
        )
        .onChanged(600);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('world-map-density-apply')));
    await tester.pumpAndSettle();

    expect(applied, hasLength(1));
    expect(applied.single.values.reduce((a, b) => a + b), 1000);
  });

  testWidgets('Réinitialiser restaure les poids d\'ouverture', (tester) async {
    await _pump(
      tester,
      child: WorldMapSmartTileDensitySection(
        rule: _rule(),
        layerWeights: const <String, int>{
          'cand-0': 800,
          'cand-1': 100,
          'cand-2': 100,
        },
        spriteBuilder: (_) => const SizedBox(width: 24, height: 24),
        onApply: (_, _) async {},
      ),
    );

    await tester.tap(find.byKey(const Key('world-map-density-summary')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('world-map-density-reset')));
    await tester.pumpAndSettle();

    expect(find.text('80,0 %'), findsOneWidget);
  });

  testWidgets('signale les variantes qui s\'écartent du preset',
      (tester) async {
    await _pump(
      tester,
      child: WorldMapSmartTileDensitySection(
        rule: _rule(),
        layerWeights: const <String, int>{
          'cand-0': 900,
          'cand-1': 50,
          'cand-2': 50,
        },
        spriteBuilder: (_) => const SizedBox(width: 24, height: 24),
        onApply: (_, _) async {},
      ),
    );

    expect(find.textContaining('modifiée'), findsOneWidget);
  });

  testWidgets('prévient que le premier enregistrement remélange la surface',
      (tester) async {
    await _pump(
      tester,
      child: WorldMapSmartTileDensitySection(
        rule: _rule(),
        layerWeights: const <String, int>{},
        spriteBuilder: (_) => const SizedBox(width: 24, height: 24),
        onApply: (_, _) async {},
      ),
    );

    await tester.tap(find.byKey(const Key('world-map-density-summary')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('world-map-density-reshuffle-notice')),
      findsOneWidget,
    );
  });

  testWidgets('bascule la source des curseurs avec la portée', (tester) async {
    await _pump(
      tester,
      child: WorldMapSmartTileDensitySection(
        rule: _rule(),
        layerWeights: const <String, int>{
          'cand-0': 900,
          'cand-1': 50,
          'cand-2': 50,
        },
        spriteBuilder: (_) => const SizedBox(width: 24, height: 24),
        onApply: (_, _) async {},
      ),
    );

    await tester.tap(find.byKey(const Key('world-map-density-summary')));
    await tester.pumpAndSettle();
    expect(find.text('90,0 %'), findsOneWidget);

    await tester.tap(find.byKey(const Key('world-map-density-scope-preset')));
    await tester.pumpAndSettle();
    expect(find.text('33,4 %'), findsOneWidget);
    expect(find.text('90,0 %'), findsNothing);
  });

  testWidgets('Appliquer reste inactif tant que rien n\'a bougé',
      (tester) async {
    final applied = <Map<String, int>>[];
    await _pump(
      tester,
      child: WorldMapSmartTileDensitySection(
        rule: _rule(),
        layerWeights: const <String, int>{},
        spriteBuilder: (_) => const SizedBox(width: 24, height: 24),
        onApply: (_, weights) async => applied.add(weights),
      ),
    );

    await tester.tap(find.byKey(const Key('world-map-density-summary')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('world-map-density-apply')));
    await tester.pumpAndSettle();

    expect(applied, isEmpty);
  });

  testWidgets(
      'la portée preset signale la surcharge du calque qui la masque',
      (tester) async {
    await _pump(
      tester,
      child: WorldMapSmartTileDensitySection(
        rule: _rule(),
        layerWeights: const <String, int>{'cand-0': 900},
        spriteBuilder: (_) => const SizedBox(width: 24, height: 24),
        onApply: (_, _) async {},
      ),
    );

    await tester.tap(find.byKey(const Key('world-map-density-summary')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('world-map-density-shadowing-notice')),
      findsNothing,
    );

    await tester.tap(find.byKey(const Key('world-map-density-scope-preset')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('world-map-density-shadowing-notice')),
      findsOneWidget,
    );
  });

  testWidgets('« Rendre ce calque au preset » envoie la table vide',
      (tester) async {
    final calls = <(SmartTileDensityScope, Map<String, int>)>[];
    await _pump(
      tester,
      child: WorldMapSmartTileDensitySection(
        rule: _rule(),
        layerWeights: const <String, int>{'cand-0': 900},
        spriteBuilder: (_) => const SizedBox(width: 24, height: 24),
        onApply: (scope, weights) async => calls.add((scope, weights)),
      ),
    );

    await tester.tap(find.byKey(const Key('world-map-density-summary')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('world-map-density-clear-override')),
    );
    await tester.pumpAndSettle();

    expect(calls, hasLength(1));
    expect(calls.single.$1, SmartTileDensityScope.layer);
    expect(calls.single.$2, isEmpty);
  });

  testWidgets('pas de bouton de retour au preset sans surcharge',
      (tester) async {
    await _pump(
      tester,
      child: WorldMapSmartTileDensitySection(
        rule: _rule(),
        layerWeights: const <String, int>{},
        spriteBuilder: (_) => const SizedBox(width: 24, height: 24),
        onApply: (_, _) async {},
      ),
    );

    await tester.tap(find.byKey(const Key('world-map-density-summary')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('world-map-density-clear-override')),
      findsNothing,
    );
  });

  testWidgets('Appliquer transmet la portée choisie', (tester) async {
    final calls = <SmartTileDensityScope>[];
    await _pump(
      tester,
      child: WorldMapSmartTileDensitySection(
        rule: _rule(),
        layerWeights: const <String, int>{},
        spriteBuilder: (_) => const SizedBox(width: 24, height: 24),
        onApply: (scope, _) async => calls.add(scope),
      ),
    );

    await tester.tap(find.byKey(const Key('world-map-density-summary')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('world-map-density-scope-preset')));
    await tester.pumpAndSettle();
    tester
        .widget<PokeMapGuidedSlider>(
          find.byKey(const ValueKey<String>('world-map-density-cand-0')),
        )
        .onChanged(600);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('world-map-density-apply')));
    await tester.pumpAndSettle();

    expect(calls, <SmartTileDensityScope>[SmartTileDensityScope.preset]);
  });
}
