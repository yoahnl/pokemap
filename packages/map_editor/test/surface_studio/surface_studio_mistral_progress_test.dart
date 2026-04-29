import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_ai_mapping_suggester.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_mapping_suggestion_models.dart';

import 'surface_studio_rebuild_test_harness.dart';

void main() {
  testWidgets('Mistral progress stays visible while AI future is pending',
      (tester) async {
    final temp = Directory.systemTemp.createTempSync('surface_mistral_wait_');
    addTearDown(() => temp.deleteSync(recursive: true));
    final image = File('${temp.path}/tiles/water.png');
    image.parent.createSync(recursive: true);
    image.writeAsBytesSync(_atlasBytes());
    final fakeAi = _PendingAiSuggester();

    await pumpSurfaceStudioForTest(
      tester,
      readModel: _readModel(),
      projectSettings: const ProjectSettings(mistralApiKey: 'configured'),
      projectTilesets: const <ProjectTilesetEntry>[
        ProjectTilesetEntry(
          id: 'water_tiles',
          name: 'Water Tiles',
          relativePath: 'tiles/water.png',
          sortOrder: 0,
        ),
      ],
      projectRootPath: temp.path,
      aiMappingSuggester: fakeAi,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('surfaceStudio.action.autoSuggest')));
    await tester.pumpAndSettle();
    final mistralButton =
        find.byKey(const Key('surfaceStudio.suggestion.mistral'));
    await tester.ensureVisible(mistralButton);
    await tester.tap(mistralButton);
    await tester.pumpAndSettle();
    final confirmButton =
        find.byKey(const Key('surfaceStudio.suggestion.confirmAi'));
    await tester.ensureVisible(confirmButton);
    await tester.tap(confirmButton);
    await tester.pump();

    expect(fakeAi.calls, 1);
    expect(
      find.byKey(const Key('surfaceStudio.suggestion.mistralProgress')),
      findsOneWidget,
    );
    expect(find.byType(CupertinoActivityIndicator), findsOneWidget);
    expect(find.textContaining('Analyse visuelle approfondie'), findsOneWidget);
    expect(
      find.textContaining('Mistral analyse l’atlas avec un niveau'),
      findsOneWidget,
    );
    expect(
      tester
          .widget<CupertinoButton>(
            find.byKey(const Key('surfaceStudio.suggestion.mistral')),
          )
          .onPressed,
      isNull,
    );
    expect(find.byKey(const Key('surfaceStudio.preview.tileRenderer')),
        findsNothing);

    fakeAi.complete();
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('surfaceStudio.suggestion.mistralProgress')),
      findsNothing,
    );
    expect(find.text('AI center'), findsOneWidget);
    expect(find.byKey(const Key('surfaceStudio.preview.tileRenderer')),
        findsNothing);
  });

  testWidgets('Mistral timeout is shown without mutating mapping',
      (tester) async {
    final temp =
        Directory.systemTemp.createTempSync('surface_mistral_timeout_');
    addTearDown(() => temp.deleteSync(recursive: true));
    final image = File('${temp.path}/tiles/water.png');
    image.parent.createSync(recursive: true);
    image.writeAsBytesSync(_atlasBytes());

    await pumpSurfaceStudioForTest(
      tester,
      readModel: _readModel(),
      projectSettings: const ProjectSettings(mistralApiKey: 'configured'),
      projectTilesets: const <ProjectTilesetEntry>[
        ProjectTilesetEntry(
          id: 'water_tiles',
          name: 'Water Tiles',
          relativePath: 'tiles/water.png',
          sortOrder: 0,
        ),
      ],
      projectRootPath: temp.path,
      aiMappingSuggester: const _TimeoutAiSuggester(),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('surfaceStudio.action.autoSuggest')));
    await tester.pumpAndSettle();
    final mistralButton =
        find.byKey(const Key('surfaceStudio.suggestion.mistral'));
    await tester.ensureVisible(mistralButton);
    await tester.tap(mistralButton);
    await tester.pumpAndSettle();
    final confirmButton =
        find.byKey(const Key('surfaceStudio.suggestion.confirmAi'));
    await tester.ensureVisible(confirmButton);
    await tester.tap(confirmButton);
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Mistral n’a pas répondu à temps'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('surfaceStudio.preview.tileRenderer')),
        findsNothing);
  });
}

final class _PendingAiSuggester implements SurfaceStudioAiMappingSuggester {
  final Completer<SurfaceStudioMappingSuggestionResult> completer =
      Completer<SurfaceStudioMappingSuggestionResult>();
  int calls = 0;

  @override
  Future<SurfaceStudioMappingSuggestionResult> suggest({
    required String apiKey,
    required Uint8List imageBytes,
    required int tileWidth,
    required int tileHeight,
    required int columnCount,
    required int frameCount,
  }) {
    calls++;
    return completer.future;
  }

  void complete() {
    completer.complete(
      const SurfaceStudioMappingSuggestionResult(
        suggestions: <SurfaceStudioRoleSuggestion>[
          SurfaceStudioRoleSuggestion(
            role: SurfaceVariantRole.isolated,
            columns: <int>[4, 5],
            confidence: SurfaceStudioMappingSuggestionConfidence.high,
            source: SurfaceStudioMappingSuggestionSource.mistral,
            reason: 'AI center',
          ),
        ],
        warnings: <String>[],
        source: SurfaceStudioMappingSuggestionSource.mistral,
      ),
    );
  }
}

final class _TimeoutAiSuggester implements SurfaceStudioAiMappingSuggester {
  const _TimeoutAiSuggester();

  @override
  Future<SurfaceStudioMappingSuggestionResult> suggest({
    required String apiKey,
    required Uint8List imageBytes,
    required int tileWidth,
    required int tileHeight,
    required int columnCount,
    required int frameCount,
  }) {
    throw TimeoutException('fake timeout');
  }
}

SurfaceStudioReadModel _readModel() {
  const atlasId = 'water-atlas';
  return buildSurfaceStudioReadModelFromCatalog(
    ProjectSurfaceCatalog(
      atlases: <ProjectSurfaceAtlas>[
        ProjectSurfaceAtlas(
          id: atlasId,
          name: 'Water Atlas',
          tilesetId: 'water_tiles',
          geometry: SurfaceAtlasGeometry(
            tileSize: SurfaceAtlasTileSize(width: 8, height: 8),
            gridSize: SurfaceAtlasGridSize(columns: 5, rows: 2),
            layout: SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames,
          ),
        ),
      ],
      animations: const <ProjectSurfaceAnimation>[],
      presets: const <ProjectSurfacePreset>[],
    ),
  );
}

Uint8List _atlasBytes() {
  const tile = 8;
  const columns = 5;
  const frames = 2;
  final image = img.Image(width: columns * tile, height: frames * tile);
  for (var frame = 0; frame < frames; frame++) {
    for (var column = 0; column < columns; column++) {
      img.fillRect(
        image,
        x1: column * tile,
        y1: frame * tile,
        x2: column * tile + tile - 1,
        y2: frame * tile + tile - 1,
        color: img.ColorRgb8(40 + column * 32, 80 + frame * 70, 180),
      );
    }
  }
  return Uint8List.fromList(img.encodePng(image));
}
