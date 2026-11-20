import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/features/resources/application/project_resource_library.dart';
import 'package:avelune_studio/features/resources/domain/project_library_editor.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:avelune_studio/presentation/features/resources/project_library_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../application/resource_pack_transfer_test_ports.dart';
import '../support/scoped_map_workspace_port.dart';

void main() {
  testWidgets('a pack can be reread and revealed without applying it twice', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1500, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final pack = _PackPort();
    final port = _LibraryPort(pack);
    final maps = MapWorkspaceController(scopedMapSession, port);
    addTearDown(maps.dispose);
    await maps.initialize();
    pack.before = maps.project!;
    final dialogStates = <bool>[];
    var picks = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(),
        home: Scaffold(
          body: ProjectLibraryPage(
            active: true,
            maps: maps,
            visuals: null,
            management: (editor: _UnusedEditor(), pickFile: () async => null),
            packPort: pack,
            pickPack: () async =>
                ++picks == 1 ? null : '/fixture.aveluneassets',
            onPackDialogChanged: dialogStates.add,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await _choosePack(tester);
    expect(find.text('Installer un pack local'), findsNothing);
    expect(dialogStates, [true, false]);
    expect(pack.applies, 0);
    await _choosePack(tester);
    await tester.tap(find.text('Tout sélectionner'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Préparer l’installation'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Installer le pack'));
    await tester.pumpAndSettle();
    expect(find.text('Relire la bibliothèque'), findsOneWidget);
    expect(dialogStates, [true, false, true]);
    expect(pack.applies, 1);

    await tester.tap(find.text('Relire la bibliothèque'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fermer'));
    await tester.pumpAndSettle();
    expect(pack.applies, 1);
    expect(pack.reconciliations, 1);
    expect(port.reads, 3);
    expect(dialogStates, [true, false, true, false]);
    expect(
      find.byKey(const ValueKey('library-detail-element:pack-tree')),
      findsOneWidget,
    );
  });
}

Future<void> _choosePack(WidgetTester tester) async {
  await tester.tap(find.text('Importer'));
  await tester.pumpAndSettle();
  expect(find.text('Un fichier PNG ou GLB'), findsOneWidget);
  await tester.tap(find.text('Un pack local'));
  await tester.pumpAndSettle();
}

class _PackPort extends PackTestPort {
  late final ProjectManifest before;
  int reconciliations = 0;

  @override
  Future<Map<String, Object?>> transfer(
    String verb, [
    Map<String, Object?> input = const {},
  ]) async {
    final response = await super.transfer(verb, input);
    if (verb != 'prepare') return response;
    final result = response['result']! as Map<String, Object?>;
    return settled({
      ...result,
      'summary': {
        ...result['summary']! as Map<String, Object?>,
        'firstAdded': {'kind': 'element', 'id': 'pack-tree'},
      },
    });
  }

  @override
  ResourceMutationReceipt get receipt => ResourceMutationReceipt(
    before: before,
    manifest: before,
    beforeRevision: 'before',
    revision: 'after',
    changedPaths: const ['catalog/HEAD.json'],
    actionId: 'resource_pack.import',
  );

  @override
  Future<void> reconcile(ResourceMutationReceipt receipt) async {
    reconciliations++;
  }
}

class _LibraryPort extends ScopedTestMapPort
    implements ProjectResourceLibraryPort {
  _LibraryPort(this.pack);

  final _PackPort pack;
  int reads = 0;

  @override
  Future<ProjectResourceLibrary> readResourceLibrary(
    ProjectSession session,
  ) async {
    reads++;
    if (reads == 2) throw const ResourceFailure('Catalogue indisponible.');
    return ProjectResourceLibrary(ResourceLibraryCatalog(), [
      if (pack.applies > 0)
        ProjectLibraryItem(
          kind: 'element',
          id: 'pack-tree',
          name: 'Arbre du pack',
        ),
    ], revision: pack.applies == 0 ? 'before' : 'after');
  }
}

class _UnusedEditor implements ProjectLibraryEditor {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
