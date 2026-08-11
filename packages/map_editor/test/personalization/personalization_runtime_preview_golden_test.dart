import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/personalization_hub.dart';
import 'package:map_editor/src/theme/pokemap_theme.dart';
import 'package:path/path.dart' as p;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(_loadFixtureFont);

  for (final viewport in <PersonalizationPreviewViewport>[
    PersonalizationPreviewViewport.landscape,
    PersonalizationPreviewViewport.portrait,
  ]) {
    for (final surface in PersonalizationStudioScene.values) {
      testWidgets('certifies editor ${surface.name} in ${viewport.name}', (
        tester,
      ) async {
        final size = viewport == PersonalizationPreviewViewport.landscape
            ? const Size(960, 900)
            : const Size(600, 1080);
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final fixture = _fixtureDirectory();
        final fixtureData = await tester.runAsync(() => _readFixture(fixture));

        await tester.pumpWidget(
          MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: _readableEditorTheme(),
            home: Scaffold(
              body: RepaintBoundary(
                key: const ValueKey<String>('personalization-editor-golden'),
                child: SingleChildScrollView(
                  child: PersonalizationRuntimePreview(
                    profile: fixtureData!.profile,
                    projectName: fixtureData.projectName,
                    projectRootPath: fixture.path,
                    initialSurface: surface,
                    initialViewport: viewport,
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(tester.takeException(), isNull);
        await expectLater(
          find.byKey(const ValueKey<String>('personalization-editor-golden')),
          matchesGoldenFile(
            'goldens/personalization/editor_${viewport.name}_${surface.name}.png',
          ),
        );
      });
    }
  }
}

Directory _fixtureDirectory() => Directory(
  p.join(
    Directory.current.path,
    '..',
    '..',
    'examples',
    'playable_runtime_host',
    'golden_personalization_v3',
  ),
);

Future<({ProjectPresentationProfile profile, String projectName})> _readFixture(
  Directory fixture,
) async {
  final decoded =
      jsonDecode(
            await File(p.join(fixture.path, 'project.json')).readAsString(),
          )
          as Map<String, dynamic>;
  return (
    profile: ProjectPresentationProfile.fromJson(
      Map<String, dynamic>.from(decoded['presentation'] as Map),
    ),
    projectName: decoded['name']! as String,
  );
}

Future<void> _loadFixtureFont() async {
  final bytes = await File(
    p.join(
      _fixtureDirectory().path,
      'assets',
      'presentation',
      'fonts',
      'display.ttf',
    ),
  ).readAsBytes();
  await _loadFont('Aube Display', bytes);
  await _loadFont('Avenir Next', bytes);
  final flutterCache = _flutterCacheDirectory();
  final iconBytes = await File(
    p.join(
      flutterCache.path,
      'artifacts',
      'material_fonts',
      'MaterialIcons-Regular.otf',
    ),
  ).readAsBytes();
  await _loadFont('MaterialIcons', iconBytes);
}

Future<void> _loadFont(String family, Uint8List bytes) async {
  await (FontLoader(
    family,
  )..addFont(Future<ByteData>.value(ByteData.sublistView(bytes)))).load();
}

Directory _flutterCacheDirectory() {
  var current = File(Platform.resolvedExecutable).parent;
  while (current.parent.path != current.path) {
    if (current.path.endsWith('${Platform.pathSeparator}cache')) return current;
    current = current.parent;
  }
  throw StateError('Flutter cache directory not found.');
}

ThemeData _readableEditorTheme() {
  final theme = PokeMapTheme.light();
  return theme.copyWith(
    textTheme: theme.textTheme.apply(fontFamily: 'Aube Display'),
    primaryTextTheme: theme.primaryTextTheme.apply(fontFamily: 'Aube Display'),
  );
}
