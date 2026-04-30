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
  testWidgets('Mistral review shows visual suggestions and grouped duplicates',
      (tester) async {
    final catalog = _miniCatalog();
    ProjectSurfaceCatalog? changedCatalog;

    await tester.pumpWidget(
      _wrap(
        TiledTsxAnimationBrowser(
          atlas: catalog.atlases.single,
          animations: catalog.animations,
          catalog: catalog,
          projectSettings: const ProjectSettings(mistralApiKey: 'configured'),
          groupingSuggester: _DuplicateWarningGroupingSuggester(),
          onSurfaceCatalogChanged: (next) => changedCatalog = next,
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

    final aiButton = find.byKey(
      const ValueKey('tiled_tsx_animation_browser.mistral_grouping'),
    );
    await tester.ensureVisible(aiButton);
    await tester.tap(aiButton);
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('tiled_tsx_mistral_grouping.confirm')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Suggestions Mistral'), findsOneWidget);
    expect(find.text('Plein(center)'), findsWidgets);
    expect(find.text('tech-animations-tile-99'), findsWidgets);
    expect(find.text('Confiance : high'), findsOneWidget);
    expect(find.text('Aperçu indisponible'), findsWidgets);
    expect(find.text('Suggestions ignorées'), findsOneWidget);
    expect(
      find.text(
        '4 suggestions ont été ignorées car elles proposaient déjà Plein(center).',
      ),
      findsOneWidget,
    );
    expect(
      find.text('Rôle Mistral dupliqué rejeté : isolated.'),
      findsNothing,
    );
    expect(changedCatalog, isNull);

    await tester.tap(
      find.byKey(
        const ValueKey('tiled_tsx_mistral_grouping.accept.isolated'),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('tiled_tsx_surface_preset_builder.panel')),
      findsOneWidget,
    );
    expect(find.text('Source : Mistral'), findsOneWidget);
    expect(find.text('Créer le preset'), findsOneWidget);
    expect(changedCatalog, isNull);
  });
}

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: SizedBox(width: 1100, height: 920, child: child),
      ),
    ),
  );
}

final class _DuplicateWarningGroupingSuggester
    implements TiledTsxAnimationGroupingSuggester {
  @override
  Future<TiledTsxMistralGroupingResult> suggest({
    required String apiKey,
    required TiledTsxMistralGroupingRequest request,
    required Uint8List? atlasImageBytes,
  }) async {
    return const TiledTsxMistralGroupingResult(
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
      warnings: <String>[
        'Rôle Mistral dupliqué rejeté : isolated.',
        'Rôle Mistral dupliqué rejeté : isolated.',
        'Rôle Mistral dupliqué rejeté : isolated.',
        'Rôle Mistral dupliqué rejeté : isolated.',
      ],
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
