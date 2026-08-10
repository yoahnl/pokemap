import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/personalization_hub.dart';
import 'package:map_editor/src/theme/pokemap_theme.dart';
import 'package:path/path.dart' as p;

void main() {
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
        final profile = await tester.runAsync(() => _readProfile(fixture));

        await tester.pumpWidget(
          MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: PokeMapTheme.light(),
            home: Scaffold(
              body: RepaintBoundary(
                key: const ValueKey<String>('personalization-editor-golden'),
                child: SingleChildScrollView(
                  child: PersonalizationRuntimePreview(
                    profile: profile!,
                    projectName: 'Le train de 17h42',
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
    'golden_personalization_slice',
  ),
);

Future<ProjectPresentationProfile> _readProfile(Directory fixture) async {
  final decoded = jsonDecode(
    await File(p.join(fixture.path, 'presentation.json')).readAsString(),
  );
  return ProjectPresentationProfile.fromJson(
    Map<String, dynamic>.from(decoded as Map),
  );
}
