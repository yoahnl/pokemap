import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/smart_tiles_studio/application/smart_tile_tiled_wang_import_service.dart';
import 'package:map_editor/src/features/smart_tiles_studio/presentation/smart_tile_tiled_wang_import_editor.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';

void main() {
  testWidgets('requires an explicit PokeMap usage before importing',
      (tester) async {
    List<TiledWangSetSelection>? submitted;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SmartTileTiledWangImportEditor(
            source: _source,
            onCancel: () {},
            onImport: (selections) async => submitted = selections,
          ),
        ),
      ),
    );

    expect(find.text('Road'), findsWidgets);
    expect(find.textContaining('1 matériau(x) • 1 forme(s)'), findsOneWidget);
    var submit = tester.widget<PokeMapButton>(
      find.byKey(const Key('smart-tiles-tiled-wang-submit')),
    );
    expect(submit.onPressed, isNull);

    await tester.tap(
      find.byKey(const Key('smart-tiles-wang-set-0-usage')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chemin').last);
    await tester.pumpAndSettle();

    submit = tester.widget<PokeMapButton>(
      find.byKey(const Key('smart-tiles-tiled-wang-submit')),
    );
    expect(submit.onPressed, isNotNull);
    await tester.tap(find.byKey(const Key('smart-tiles-tiled-wang-submit')));
    await tester.pump();
    expect(submitted, hasLength(1));
    expect(submitted!.single.wangSetIndex, 0);
    expect(submitted!.single.usage, SmartTileUsage.path);
  });

  testWidgets('explains that imports remain native draft presets',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SmartTileTiledWangImportEditor(
            source: _source,
            onCancel: () {},
            onImport: (_) async {},
          ),
        ),
      ),
    );

    expect(find.textContaining('Tiled ne sera pas requis ensuite'),
        findsOneWidget);
    expect(find.textContaining('presets restent en brouillon'), findsOneWidget);
    expect(find.byKey(const Key('smart-tiles-tiled-wang-error')), findsNothing);
  });

  testWidgets('offers a no-code import for image collections', (tester) async {
    List<TiledWangSetSelection>? submitted;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SmartTileTiledWangImportEditor(
            source: _collectionSource,
            onCancel: () {},
            onImport: (selections) async => submitted = selections,
          ),
        ),
      ),
    );

    expect(
      find.byKey(const Key('smart-tiles-tiled-image-collection-summary')),
      findsOneWidget,
    );
    expect(find.textContaining('2 éléments seront regroupés'), findsOneWidget);
    expect(find.text('Importer la collection'), findsOneWidget);
    final submit = tester.widget<PokeMapButton>(
      find.byKey(const Key('smart-tiles-tiled-wang-submit')),
    );
    expect(submit.onPressed, isNotNull);

    await tester.tap(find.byKey(const Key('smart-tiles-tiled-wang-submit')));
    await tester.pump();
    expect(submitted, isEmpty);
  });
}

final _source = SmartTileTiledWangSource(
  tsxPath: '/outside/road.tsx',
  imagePath: '/outside/road.png',
  imagePaths: const <String, String>{'road.png': '/outside/road.png'},
  displayName: 'road.tsx',
  tsx: _tsx,
  importId: 'road-import',
  tilesetDocument: parseTiledTileset(_tsx),
  document: parseTiledWangTileset(_tsx),
);

final _collectionSource = SmartTileTiledWangSource(
  tsxPath: '/outside/props.tsx',
  imagePath: '/outside/flower.png',
  imagePaths: const <String, String>{
    'flower.png': '/outside/flower.png',
    'water.png': '/outside/water.png',
  },
  displayName: 'props.tsx',
  tsx: _collectionTsx,
  importId: 'props-import',
  tilesetDocument: parseTiledTileset(_collectionTsx),
  document: null,
);

const _tsx = '''
<tileset name="Road" tilewidth="16" tileheight="16" tilecount="1" columns="1">
  <image source="road.png" width="16" height="16"/>
  <wangsets>
    <wangset name="Road" type="edge" tile="-1">
      <wangcolor name="Road" color="#c8a162" tile="0" probability="1"/>
      <wangtile tileid="0" wangid="1,0,1,0,1,0,1,0"/>
    </wangset>
  </wangsets>
</tileset>
''';

const _collectionTsx = '''
<tileset name="Props" tilewidth="16" tileheight="16" tilecount="2" columns="0">
  <tile id="5"><image source="flower.png" width="16" height="16"/></tile>
  <tile id="9"><image source="water.png" width="16" height="16"/></tile>
</tileset>
''';
