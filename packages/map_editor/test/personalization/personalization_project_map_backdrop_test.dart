import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/personalization/presentation/personalization_project_map_backdrop.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:path/path.dart' as p;

void main() {
  late String projectRoot;
  late ProjectManifest manifest;
  late MapData map;

  setUpAll(() async {
    projectRoot = p.join(
      Directory.current.parent.parent.path,
      'examples',
      'playable_runtime_host',
      'golden_personalization_v3',
    );
    manifest = ProjectManifest.fromJson(
      jsonDecode(await File(p.join(projectRoot, 'project.json')).readAsString())
          as Map<String, dynamic>,
    );
    map = MapData.fromJson(
      jsonDecode(
            await File(
              p.join(projectRoot, 'maps', 'vermeil_village.json'),
            ).readAsString(),
          )
          as Map<String, dynamic>,
    );
  });

  testWidgets('uses the shared read-only project map renderer', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.light(),
        home: Scaffold(
          body: Builder(
            builder: (context) => SizedBox(
              width: 960,
              height: 540,
              child: PersonalizationProjectMapBackdrop(
                map: map,
                colors: context.pokeMapColors,
                projectRootPath: projectRoot,
                manifest: manifest,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      find.byKey(
        const ValueKey<String>('personalization-project-map-renderer'),
      ),
      findsOneWidget,
    );
    expect(find.text('Village de Vermeil'), findsOneWidget);
  });
}
