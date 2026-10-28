import 'dart:async';

import 'package:avelune_studio/features/project_surf/application/project_surf_controller.dart';
import 'package:avelune_studio/features/project_surf/domain/project_surf_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../support/map_workspace_fixture.dart';

void main() {
  test(
    'first and repeated edits stay local and save once without a reload',
    () async {
      final port = _Port();
      final owner = ProjectSurfController(
        session: workspaceSession,
        port: port,
        dimension: ProjectDimension.threeD,
      );
      addTearDown(owner.dispose);
      await owner.open();
      expect(owner.preview.value.enabled, isFalse);
      expect(owner.dirty, isFalse);
      owner.edit(
        const ProjectSurfSettings(accessMode: ProjectSurfAccessMode.always),
      );
      expect(owner.preview.value.enabled, isTrue);
      expect(port.reads, 1);
      expect(port.writes, 0);
      expect(await owner.save(), isTrue);
      owner.edit(
        const ProjectSurfSettings(
          requiresKnownMove: false,
          accessMode: ProjectSurfAccessMode.always,
        ),
      );
      expect(await owner.save(), isTrue);
      expect(port.reads, 1);
      expect(port.writes, 2);
      expect(port.references, 0);
      final reopened = ProjectSurfController(
        session: workspaceSession,
        port: port,
        dimension: ProjectDimension.threeD,
      );
      addTearDown(reopened.dispose);
      await reopened.open();
      expect(reopened.preview.value, owner.preview.value);
    },
  );
  test(
    'pending durability and conflict retain the exact draft and local undo',
    () async {
      final port = _Port()..pending = Completer<void>();
      final owner = ProjectSurfController(
        session: workspaceSession,
        port: port,
        dimension: ProjectDimension.twoD,
      );
      addTearDown(owner.dispose);
      await owner.open();
      expect(owner.preview.value.enabled, isTrue);
      const draft = ProjectSurfSettings(requiresKnownMove: false);
      owner.edit(draft);
      owner.undo();
      expect(owner.dirty, isFalse);
      owner.redo();
      final saving = owner.save();
      expect(owner.saving, isTrue);
      expect(owner.dirty, isTrue);
      port.pending!.complete();
      expect(await saving, isTrue);
      port.fail = true;
      owner.edit(const ProjectSurfSettings(enabled: false));
      expect(await owner.save(), isFalse);
      expect(owner.preview.value.enabled, isFalse);
      expect(owner.dirty, isTrue);
      owner.discard();
      expect(owner.preview.value, draft);
    },
  );
}

class _Port implements ProjectSurfPort {
  @override
  Future<NarrativeFactDefinition> loadSurfFact(session, String id) =>
      throw UnimplementedError();
  ProjectSurfSettings? configuration;
  int reads = 0, writes = 0, references = 0;
  bool fail = false;
  Completer<void>? pending;
  @override
  Future<ProjectSurfState> loadSurf(session) async {
    reads++;
    return ProjectSurfState(configuration: configuration, revision: '$writes');
  }

  @override
  Future<ProjectSurfState> saveSurf(
    session,
    ProjectSurfSettings? configuration,
    String expectedRevision,
  ) async {
    await pending?.future;
    if (fail || expectedRevision != '$writes') throw StateError('conflict');
    writes++;
    this.configuration = configuration;
    return ProjectSurfState(configuration: configuration, revision: '$writes');
  }

  @override
  Future<ProjectSurfReferences> loadSurfReferences(session) async {
    references++;
    return const ProjectSurfReferences();
  }
}
