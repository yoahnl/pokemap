import 'dart:async';
import 'dart:io';

import 'package:avelune_studio/features/map_workspace/application/map_relief_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_editing_state.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/project_session/data/local_project_session_adapter.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_resource_binding.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../map_workspace/map_relief_fixture.dart';
import 'map_relief_catalog_fixture.dart';

void main() {
  late Directory root;
  late LocalProjectSessionAdapter sessions;
  late ProjectSession session;
  late ReadLogReader reader;
  late MapWorkspaceController workspace;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('studio_relief_session_');
    sessions = LocalProjectSessionAdapter();
    await writeReliefCatalogProject(root);
    session = await sessions.open(await root.resolveSymbolicLinks());
    reader = ReadLogReader();
    workspace = MapWorkspaceController(
      session,
      LocalMapWorkspaceAdapter(reader: reader),
    );
    await workspace.initialize();
    await workspace.activate(
      workspace.project!.maps.singleWhere((entry) => entry.id == 'clairiere'),
    );
    await MapBuilderResourceBinding(
      maps: workspace,
      view: MapWorkspaceEditingState.new,
      visuals: () => null,
      isActive: () => true,
      changed: () {},
    ).load();
    await workspace.ensureResourceKind('borderBlueprint', placeableOnly: true);
    await workspace.ensureBorderBlueprint('fence');
  });

  tearDown(() async {
    if (reader.gate case final gate? when !gate.isCompleted) gate.complete();
    await workspace.savesSettled;
    workspace.dispose();
    await sessions.close(session);
    await root.delete(recursive: true);
  });

  void paintPlateau() {
    final document = workspace.active!;
    final outcome = MapReliefCommands(document, workspace.project!).apply(
      MapReliefStroke(
        source: document.current,
        origin: const GridPos(x: 3, y: 3),
        level: 2,
        rectangle: true,
      )..paint(const GridPos(x: 7, y: 6)),
      MapReliefToolState()..profileId = 'fence',
    );
    expect(outcome.problem, isNull);
    expect(reliefFeatures(document.current), ['relief-1']);
  }

  test(
    'Save is done once the map is written; the selection refresh follows',
    () async {
      paintPlateau();
      final document = workspace.active!;
      void gateAfterWrite() {
        if (!document.dirty && reader.gate == null) reader.gate = Completer();
      }

      workspace.addListener(gateAfterWrite);
      expect(await workspace.saveAll(), isTrue);
      workspace.removeListener(gateAfterWrite);
      expect(workspace.saving, isFalse);
      expect(document.dirty, isFalse);
      var refreshed = false;
      unawaited(workspace.savesSettled.then((_) => refreshed = true));
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(refreshed, isFalse);

      reader.gate!.complete();
      await workspace.savesSettled;
      expect(refreshed, isTrue);
      expect(document.error, isNull);
      expect(workspace.project!.borderCatalog.recordById('fence'), isNotNull);
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );

  test(
    'the relief styles are read once per session, even after a save',
    () async {
      paintPlateau();
      expect(await workspace.saveAll(), isTrue);
      await workspace.savesSettled;
      await workspace.ensureResourceKind('model3d', placeableOnly: true);

      reader.paths.clear();
      await workspace.ensureResourceKind(
        'borderBlueprint',
        placeableOnly: true,
      );
      expect(
        reader.paths.where((path) => path.startsWith('catalog/')),
        isEmpty,
      );
      expect(
        mapReliefProfiles(
          workspace.project!,
          workspace.active!.current,
        ).map((profile) => profile.id),
        ['fence', 'berge'],
      );
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );

  test(
    'switching maps keeps the relief styles and their two-level variants',
    () async {
      for (final id in ['jardin', 'clairiere']) {
        await workspace.activate(
          workspace.project!.maps.singleWhere((entry) => entry.id == id),
        );
        await workspace.ensureResourceKind(
          'borderBlueprint',
          placeableOnly: true,
        );
        expect(
          mapReliefProfiles(
            workspace.project!,
            workspace.active!.current,
          ).map((profile) => profile.id),
          ['fence', 'berge'],
          reason: 'after opening $id',
        );
      }
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
