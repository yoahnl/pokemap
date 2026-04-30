import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/surface_studio/importers/tiled_tsx_animation_browser.dart';
import 'package:map_editor/src/features/surface_studio/importers/tiled_tsx_mistral_grouping_models.dart';
import 'package:map_editor/src/features/surface_studio/importers/tiled_tsx_mistral_grouping_suggester.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_mapping_suggestion_models.dart';

void main() {
  testWidgets('Mistral grouping button requires selection and configured key',
      (tester) async {
    final catalog = _miniCatalog();

    await tester.pumpWidget(
      _wrap(
        TiledTsxAnimationBrowser(
          atlas: catalog.atlases.single,
          animations: catalog.animations,
          catalog: catalog,
          projectSettings: const ProjectSettings(mistralApiKey: 'configured'),
          groupingSuggester: _ImmediateGroupingSuggester(),
        ),
      ),
    );

    final button = find.byKey(
      const ValueKey('tiled_tsx_animation_browser.mistral_grouping'),
    );
    await tester.ensureVisible(button);
    expect(tester.widget<CupertinoButton>(button).onPressed, isNull);

    final checkbox = find.byKey(
      const ValueKey(
        'tiled_tsx_animation_browser.checkbox.tech-animations-tile-99',
      ),
    );
    await tester.ensureVisible(checkbox);
    await tester.tap(checkbox);
    await tester.pumpAndSettle();

    await tester.ensureVisible(button);
    expect(tester.widget<CupertinoButton>(button).onPressed, isNotNull);
  });

  testWidgets('Mistral grouping shows missing key message', (tester) async {
    final catalog = _miniCatalog();

    await tester.pumpWidget(
      _wrap(
        TiledTsxAnimationBrowser(
          atlas: catalog.atlases.single,
          animations: catalog.animations,
          catalog: catalog,
          groupingSuggester: _ImmediateGroupingSuggester(),
        ),
      ),
    );

    await tester.tap(
      find.byKey(
        const ValueKey(
          'tiled_tsx_animation_browser.checkbox.tech-animations-tile-99',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Clé Mistral absente : Projet → Paramètres (IA) ou MISTRAL_API_KEY.',
      ),
      findsOneWidget,
    );
    final button = find.byKey(
      const ValueKey('tiled_tsx_animation_browser.mistral_grouping'),
    );
    await tester.ensureVisible(button);
    expect(tester.widget<CupertinoButton>(button).onPressed, isNull);
  });

  testWidgets(
    'Mistral grouping requires confirmation, shows progress, then fills draft only after accept',
    (tester) async {
      final catalog = _miniCatalog();
      final fake = _PendingGroupingSuggester();
      ProjectSurfaceCatalog? changedCatalog;

      await tester.pumpWidget(
        _wrap(
          TiledTsxAnimationBrowser(
            atlas: catalog.atlases.single,
            animations: catalog.animations,
            catalog: catalog,
            projectSettings: const ProjectSettings(mistralApiKey: 'configured'),
            groupingSuggester: fake,
            onSurfaceCatalogChanged: (next) => changedCatalog = next,
          ),
        ),
      );

      final checkbox = find.byKey(
        const ValueKey(
          'tiled_tsx_animation_browser.checkbox.tech-animations-tile-99',
        ),
      );
      await tester.ensureVisible(checkbox);
      await tester.tap(checkbox);
      await tester.pumpAndSettle();

      final aiButton = find.byKey(
        const ValueKey('tiled_tsx_animation_browser.mistral_grouping'),
      );
      await tester.ensureVisible(aiButton);
      await tester.tap(aiButton);
      await tester.pumpAndSettle();

      expect(fake.calls, 0);
      expect(find.text('Confirmer l’analyse IA'), findsOneWidget);

      final confirm = find.byKey(
        const ValueKey('tiled_tsx_mistral_grouping.confirm'),
      );
      await tester.ensureVisible(confirm);
      await tester.tap(confirm);
      await tester.pump();

      expect(fake.calls, 1);
      expect(
        find.byKey(const ValueKey('tiled_tsx_mistral_grouping.progress')),
        findsOneWidget,
      );
      expect(find.byType(CupertinoActivityIndicator), findsOneWidget);
      expect(
        find.textContaining('Mistral analyse les animations sélectionnées'),
        findsOneWidget,
      );
      expect(changedCatalog, isNull);

      fake.complete();
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('tiled_tsx_mistral_grouping.progress')),
        findsNothing,
      );
      expect(find.text('Suggestions Mistral'), findsOneWidget);
      expect(find.text('tech-animations-tile-99'), findsWidgets);
      expect(changedCatalog, isNull);

      final accept = find.byKey(
        const ValueKey('tiled_tsx_mistral_grouping.accept.isolated'),
      );
      await tester.ensureVisible(accept);
      await tester.tap(accept);
      await tester.pumpAndSettle();

      expect(
        find.byKey(
          const ValueKey('tiled_tsx_surface_preset_builder.panel'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey('tiled_tsx_role_mapping_builder.slot.isolated'),
        ),
        findsOneWidget,
      );
      expect(find.text('Plein(center)'), findsWidgets);
      expect(find.text('Source : Mistral'), findsOneWidget);
      expect(find.text('Aperçu indisponible'), findsWidgets);
      expect(
        find.byKey(
          const ValueKey('tiled_tsx_surface_preset_builder.role.isolated'),
        ),
        findsNothing,
      );
      expect(changedCatalog, isNull);
      expect(find.text('Créer le preset'), findsOneWidget);
    },
  );
}

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: 1100,
          height: 920,
          child: child,
        ),
      ),
    ),
  );
}

final class _ImmediateGroupingSuggester
    implements TiledTsxAnimationGroupingSuggester {
  @override
  Future<TiledTsxMistralGroupingResult> suggest({
    required String apiKey,
    required TiledTsxMistralGroupingRequest request,
    required Uint8List? atlasImageBytes,
  }) async {
    return const TiledTsxMistralGroupingResult(
      suggestions: <TiledTsxRoleAnimationSuggestion>[],
      rejectedAnimationIds: <String>[],
      warnings: <String>[],
    );
  }
}

final class _PendingGroupingSuggester
    implements TiledTsxAnimationGroupingSuggester {
  final Completer<TiledTsxMistralGroupingResult> completer =
      Completer<TiledTsxMistralGroupingResult>();
  int calls = 0;

  @override
  Future<TiledTsxMistralGroupingResult> suggest({
    required String apiKey,
    required TiledTsxMistralGroupingRequest request,
    required Uint8List? atlasImageBytes,
  }) {
    calls++;
    return completer.future;
  }

  void complete() {
    completer.complete(
      const TiledTsxMistralGroupingResult(
        suggestions: <TiledTsxRoleAnimationSuggestion>[
          TiledTsxRoleAnimationSuggestion(
            role: SurfaceVariantRole.isolated,
            animationId: 'tech-animations-tile-99',
            confidence: SurfaceStudioMappingSuggestionConfidence.high,
            reason: 'Full repeatable water tile.',
            evidenceAnimationIds: <String>['tech-animations-tile-99'],
          ),
        ],
        rejectedAnimationIds: <String>[],
        warnings: <String>[],
      ),
    );
  }
}

ProjectSurfaceCatalog _miniCatalog() {
  return ProjectSurfaceCatalog(
    atlases: [
      ProjectSurfaceAtlas(
        id: 'tech-animations',
        name: 'TECH-Animations',
        tilesetId: 'tech-nature-animations',
        geometry: SurfaceAtlasGeometry(
          tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
          gridSize: SurfaceAtlasGridSize(columns: 98, rows: 109),
          layout: SurfaceAtlasLayout.grid,
        ),
      ),
    ],
    animations: [
      _animation('tech-animations-tile-99'),
      _animation('tech-animations-tile-105'),
    ],
  );
}

ProjectSurfaceAnimation _animation(String id) {
  return ProjectSurfaceAnimation(
    id: id,
    name: id,
    timeline: SurfaceAnimationTimeline(
      frames: [
        SurfaceAnimationFrame(
          tileRef: SurfaceAtlasTileRef(
            atlasId: 'tech-animations',
            column: 1,
            row: 1,
          ),
          durationMs: 100,
        ),
      ],
    ),
  );
}
