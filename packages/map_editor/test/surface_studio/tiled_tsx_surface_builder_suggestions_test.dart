import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/surface_studio/importers/tiled_tsx_mistral_grouping_models.dart';
import 'package:map_editor/src/features/surface_studio/importers/tiled_tsx_mistral_grouping_suggester.dart';
import 'package:map_editor/src/features/surface_studio/importers/tiled_tsx_workspace.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_mapping_suggestion_models.dart';

void main() {
  testWidgets('accepted Mistral suggestions apply to the reference draft only',
      (tester) async {
    ProjectSurfaceCatalog? changedCatalog;

    await tester.pumpWidget(
      _wrap(
        TiledTsxWorkspace(
          catalog: _catalog(),
          projectSettings: const ProjectSettings(mistralApiKey: 'configured'),
          groupingSuggester: _ReferenceSuggestionSuggester(),
          onSurfaceCatalogChanged: (catalog) => changedCatalog = catalog,
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('tiled_tsx_reference.detect')));
    await tester.pumpAndSettle();

    final runMistral = find.byKey(
      const ValueKey('tiled_tsx_reference.run_mistral'),
    );
    await tester.ensureVisible(runMistral);
    await tester.tap(runMistral);
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('tiled_tsx_reference.mistral_confirm')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Suggestions Mistral'), findsOneWidget);
    expect(find.text('Plein(center)'), findsWidgets);
    expect(find.text('Horizontal'), findsWidgets);
    expect(find.text('tech-animations-tile-99'), findsWidgets);
    expect(find.text('tech-animations-tile-105'), findsWidgets);
    expect(changedCatalog, isNull);

    await tester.tap(
      find.byKey(const ValueKey('tiled_tsx_reference.accept.isolated')),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('tiled_tsx_reference.accept.horizontal')),
    );
    await tester.tap(
      find.byKey(const ValueKey('tiled_tsx_reference.accept.horizontal')),
    );
    await tester.pumpAndSettle();

    final apply = find.byKey(
      const ValueKey('tiled_tsx_reference.apply_suggestions'),
    );
    await tester.ensureVisible(apply);
    await tester.tap(apply);
    await tester.pumpAndSettle();

    expect(find.text('Source : Mistral'), findsWidgets);
    expect(find.text('2 suggestions appliquées au draft.'), findsOneWidget);
    expect(
      find.text('Preview partielle : seuls les centres sont assignés.'),
      findsNothing,
    );
    expect(changedCatalog, isNull);

    final save = find.byKey(
      const ValueKey('tiled_tsx_reference_builder.save_surface'),
    );
    expect(tester.widget<ElevatedButton>(save).onPressed, isNotNull);
  });
}

final class _ReferenceSuggestionSuggester
    implements TiledTsxAnimationGroupingSuggester {
  @override
  Future<TiledTsxMistralGroupingResult> suggest({
    required String apiKey,
    required TiledTsxMistralGroupingRequest request,
    required Uint8List? atlasImageBytes,
  }) async {
    return const TiledTsxMistralGroupingResult(
      suggestions: [
        TiledTsxRoleAnimationSuggestion(
          role: SurfaceVariantRole.isolated,
          animationId: 'tech-animations-tile-99',
          confidence: SurfaceStudioMappingSuggestionConfidence.high,
          reason: 'Centre répétable.',
          evidenceAnimationIds: ['tech-animations-tile-99'],
        ),
        TiledTsxRoleAnimationSuggestion(
          role: SurfaceVariantRole.horizontal,
          animationId: 'tech-animations-tile-105',
          confidence: SurfaceStudioMappingSuggestionConfidence.high,
          reason: 'Bande horizontale.',
          evidenceAnimationIds: ['tech-animations-tile-105'],
        ),
      ],
      rejectedAnimationIds: [],
      warnings: [
        'Rôle Mistral dupliqué rejeté : isolated.',
        'Rôle Mistral dupliqué rejeté : isolated.',
      ],
    );
  }
}

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: SizedBox(width: 1500, height: 980, child: child),
    ),
  );
}

ProjectSurfaceCatalog _catalog() {
  return ProjectSurfaceCatalog(
    atlases: [_atlas()],
    animations: [
      _animation('tech-animations-tile-99', 1, 1),
      _animation('tech-animations-tile-105', 7, 1),
      _animation('tech-animations-tile-111', 13, 1),
    ],
  );
}

ProjectSurfaceAtlas _atlas() {
  return ProjectSurfaceAtlas(
    id: 'tech-animations',
    name: 'TECH-Animations',
    tilesetId: 'tech-nature-animations',
    geometry: SurfaceAtlasGeometry(
      tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
      gridSize: SurfaceAtlasGridSize(columns: 98, rows: 109),
      layout: SurfaceAtlasLayout.grid,
    ),
  );
}

ProjectSurfaceAnimation _animation(String id, int column, int row) {
  return ProjectSurfaceAnimation(
    id: id,
    name: id,
    timeline: SurfaceAnimationTimeline(
      frames: [
        SurfaceAnimationFrame(
          tileRef: SurfaceAtlasTileRef(
            atlasId: 'tech-animations',
            column: column,
            row: row,
          ),
          durationMs: 100,
        ),
      ],
    ),
  );
}
