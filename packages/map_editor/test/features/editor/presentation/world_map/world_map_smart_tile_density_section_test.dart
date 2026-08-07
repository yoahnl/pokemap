import 'package:flutter/material.dart';
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
  testWidgets('est repliée par défaut et résume les variantes',
      (tester) async {
    await _pump(
      tester,
      child: WorldMapSmartTileDensitySection(
        rule: _rule(),
        layerWeights: const <String, int>{},
        spriteBuilder: (_) => const SizedBox(width: 24, height: 24),
        onApply: (_, __) async {},
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
        onApply: (_, __) async {},
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
        onApply: (_, __) async {},
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
        onApply: (_, __) async {},
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
        onApply: (_, __) async {},
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
        onApply: (_, __) async {},
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
        onApply: (_, __) async {},
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
        onApply: (_, __) async {},
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
        onApply: (_, __) async {},
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
