import 'dart:async';

import 'package:avelune_studio/features/project_surf/application/project_surf_controller.dart';
import 'package:avelune_studio/features/project_surf/application/project_surf_condition_controller.dart';
import 'package:avelune_studio/features/project_surf/domain/project_surf_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../support/map_workspace_fixture.dart';

Future<(ProjectSurfController, ProjectSurfConditionController)> _open(
  _Port port,
) async {
  final owner = ProjectSurfController(
    session: workspaceSession,
    port: port,
    dimension: ProjectDimension.threeD,
  );
  addTearDown(owner.dispose);
  await owner.open();
  final condition = ProjectSurfConditionController(owner: owner);
  addTearDown(condition.dispose);
  await condition.start();
  return (owner, condition);
}

void main() {
  test(
    'choosing an empty condition source cannot save the previous condition',
    () async {
      final port = _Port();
      final (owner, condition) = await _open(port);
      await condition.selectSource('badge');
      expect(owner.inputError, isNotNull);
      expect(owner.dirty, isTrue);
      expect(await owner.save(), isFalse);
      expect(port.writes, 0);
      expect(owner.preview.value.condition, port.initial.condition);
      owner.discard();
      expect(owner.dirty, isFalse);
    },
  );

  test('a non interoperable integer is a preserved draft error', () async {
    final port = _Port();
    final (owner, condition) = await _open(port);
    condition.editValue('9007199254740992');
    expect(owner.conditionInput, '9007199254740992');
    expect(owner.inputError, isNotNull);
    expect(await owner.save(), isFalse);
    expect(owner.preview.value.condition, port.initial.condition);
    expect(port.writes, 0);
    condition.editValue('3');
    expect(owner.inputError, isNull);
    expect(
      owner.preview.value.condition!.params[ScriptConditionParams.value],
      '3',
    );
  });

  for (final cancellation in ['discard', 'undo', 'always']) {
    test(
      'a late fact read cannot reapply a condition after $cancellation',
      () async {
        final port = _Port();
        final (owner, condition) = await _open(port);
        final pending = condition.selectReference('other');
        expect(owner.inputError, isNotNull);
        expect(await owner.save(), isFalse);
        if (cancellation == 'discard') owner.discard();
        if (cancellation == 'undo') owner.undo();
        if (cancellation == 'always')
          owner.change(accessMode: ProjectSurfAccessMode.always);
        port.pending.complete(
          NarrativeFactDefinition(id: 'other', label: 'Autre état'),
        );
        await pending;
        expect(owner.preview.value.condition, port.initial.condition);
        expect(
          owner.preview.value.accessMode,
          cancellation == 'always'
              ? ProjectSurfAccessMode.always
              : ProjectSurfAccessMode.condition,
        );
        expect(owner.inputError, isNull);
        expect(owner.dirty, cancellation == 'always');
        expect(port.writes, 0);
      },
    );
  }

  test('a fact response with another identity is refused without replacing the draft', () async {
    final port = _Port();
    final (owner, condition) = await _open(port);
    final pending = condition.selectReference('other');
    port.pending.complete(
      NarrativeFactDefinition(id: 'wrong', label: 'Inattendu'),
    );
    await pending;
    expect(condition.error, contains('ne correspond pas'));
    expect(owner.preview.value.condition, port.initial.condition);
    expect(owner.inputError, isNotNull);
    expect(await owner.save(), isFalse);
    expect(port.writes, 0);
  });

  test('closing a condition editor refuses the late fact response', () async {
    final port = _Port();
    final owner = ProjectSurfController(
      session: workspaceSession,
      port: port,
      dimension: ProjectDimension.threeD,
    );
    addTearDown(owner.dispose);
    await owner.open();
    final condition = ProjectSurfConditionController(owner: owner);
    await condition.start();
    final pending = condition.selectReference('other');
    condition.dispose();
    port.pending.complete(
      NarrativeFactDefinition(id: 'other', label: 'Autre état'),
    );
    await pending;
    expect(owner.preview.value.condition, port.initial.condition);
    expect(port.writes, 0);
  });
}

class _Port implements ProjectSurfPort {
  final pending = Completer<NarrativeFactDefinition>();
  final initial = ProjectSurfSettings(
    accessMode: ProjectSurfAccessMode.condition,
    condition: ScriptConditionFactory.factEquals(
      'locks',
      NarrativeValue.integer(1),
    ),
  );
  int writes = 0;
  @override
  Future<ProjectSurfState> loadSurf(session) async =>
      ProjectSurfState(configuration: initial, revision: '0');
  @override
  Future<ProjectSurfState> saveSurf(
    session,
    ProjectSurfSettings? configuration,
    String revision,
  ) async {
    writes++;
    return ProjectSurfState(configuration: configuration, revision: '$writes');
  }

  @override
  Future<ProjectSurfReferences> loadSurfReferences(session) async =>
      const ProjectSurfReferences(
        facts: {'locks': 'Écluses ouvertes', 'other': 'Autre état'},
      );
  @override
  Future<NarrativeFactDefinition> loadSurfFact(session, String id) async =>
      id == 'other'
      ? pending.future
      : NarrativeFactDefinition(
          id: 'locks',
          label: 'Écluses ouvertes',
          initialValue: NarrativeValue.integer(1),
        );
}
