import 'package:avelune_studio/features/project_surf/application/project_surf_controller.dart';
import 'package:avelune_studio/features/project_surf/application/project_surf_condition_controller.dart';
import 'package:avelune_studio/features/project_surf/domain/project_surf_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../support/map_workspace_fixture.dart';

void main() {
  Future<ProjectSurfController> open(_Port port) async {
    final owner = ProjectSurfController(
      session: workspaceSession,
      port: port,
      dimension: ProjectDimension.threeD,
    );
    addTearDown(owner.dispose);
    await owner.open();
    return owner;
  }

  test('Surf edits are instant drafts and references load only for conditions', () async {
    final port = _Port();
    final owner = await open(port);
    owner.change(enabled: true);
    expect(owner.preview.value.enabled, isTrue);
    expect(owner.dirty, isTrue);
    expect(port.reads, 1);
    expect(port.writes, 0);
    expect(port.references, 0);
    owner.change(accessMode: ProjectSurfAccessMode.condition);
    final conditions = ProjectSurfConditionController(
      owner: owner,
      loadItems: () async => {'potion': 'Potion'},
    );
    addTearDown(conditions.dispose);
    await conditions.start();
    expect(port.references, 1);
    await conditions.selectSource('badge');
    await conditions.selectReference('cascade');
    expect(owner.preview.value.condition, ScriptConditionFactory.badgeOwned('cascade'));
    expect(await owner.save(), isTrue);
    expect(port.writes, 1);
    expect(port.reads, 1);
    expect(owner.dirty, isFalse);
  });

  test('editing a selected fact stays local and invalid input survives condition-session reopening', () async {
    final port = _Port();
    final owner = await open(port);
    owner.change(
      accessMode: ProjectSurfAccessMode.condition,
      condition: ScriptConditionFactory.factEquals('locks', NarrativeValue.integer(1)),
    );
    final first = ProjectSurfConditionController(owner: owner);
    await first.start();
    expect(port.factReads, 1);
    first.editValue('2');
    first.editValue('3');
    expect(port.factReads, 1);
    first.editValue('nope');
    expect(await owner.save(), isFalse);
    expect(port.writes, 0);
    first.dispose();
    final reopened = ProjectSurfConditionController(owner: owner);
    addTearDown(reopened.dispose);
    await reopened.start();
    expect(owner.conditionInput, 'nope');
    expect(owner.inputError, isNotNull);
    expect(owner.preview.value.condition,
      ScriptConditionFactory.factEquals('locks', NarrativeValue.integer(3)));
    owner.discard();
    expect(owner.inputError, isNull);
    expect(owner.dirty, isFalse);
  });

  test('Surf speed stays in the draft and invalid text cannot be saved', () async {
    final port = _Port();
    final owner = await open(port);
    owner.editSpeed('6.5');
    expect(owner.preview.value.speedCellsPerSecond, 6.5);
    expect(port.writes, 0);
    expect(await owner.save(), isTrue);
    expect(owner.saved!.configuration!.speedCellsPerSecond, 6.5);
    expect(port.writes, 1);
    owner.editSpeed('NaN');
    expect(owner.preview.value.speedCellsPerSecond, 6.5);
    expect(await owner.save(), isFalse);
    expect(port.writes, 1);
    expect(owner.speedInput, 'NaN');
    owner.discard();
    expect(owner.dirty, isFalse);
    expect(owner.speedInput, isNull);
    expect(owner.preview.value.speedCellsPerSecond, 6.5);
  });
}

class _Port implements ProjectSurfPort {
  int reads = 0, writes = 0, references = 0, factReads = 0;
  @override
  Future<ProjectSurfState> loadSurf(session) async {
    reads++;
    return const ProjectSurfState(configuration: null, revision: '0');
  }

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
  Future<ProjectSurfReferences> loadSurfReferences(session) async {
    references++;
    return const ProjectSurfReferences(
      facts: {'locks': 'Écluses ouvertes'},
      badges: {'cascade': 'Badge Cascade'},
    );
  }

  @override
  Future<NarrativeFactDefinition> loadSurfFact(session, String id) async {
    factReads++;
    return NarrativeFactDefinition(
      id: id,
      label: 'Écluses ouvertes',
      initialValue: NarrativeValue.integer(1),
    );
  }
}
