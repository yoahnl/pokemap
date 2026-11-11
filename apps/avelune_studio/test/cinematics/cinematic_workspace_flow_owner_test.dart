import 'package:avelune_studio/features/cinematics/application/cinematic_input_state.dart';
import 'package:avelune_studio/features/cinematics/application/cinematic_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/narrative/application/narrative_workspace_controller.dart';
import 'package:avelune_studio/features/narrative/data/local_narrative_adapter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../support/cinematic_adapter_fixture.dart';

void main() {
  late CinematicAdapterFixture f;
  late MapWorkspaceController maps;
  late NarrativeWorkspaceController narrative;
  late CinematicWorkspaceController controller;
  setUp(() async {
    f = await CinematicAdapterFixture.create(
      cinematics: [CinematicAdapterFixture.asset('a')],
    );
    maps = MapWorkspaceController(f.session, f.maps);
    await maps.initialize();
    narrative = NarrativeWorkspaceController(
      maps,
      LocalNarrativeAdapter(session: f.session, mapAdapter: f.maps),
      () {},
      (_, _) async {},
    );
    controller = CinematicWorkspaceController(
      narrative,
      f.adapter(),
      changed: () {},
    );
    expect(await controller.open('a'), isTrue);
  });
  tearDown(() async {
    controller.dispose();
    narrative.dispose();
    maps.dispose();
    await f.dispose();
  });

  CinematicInputState inputs() => controller.inputsFor('a');

  bool commitFocusedTitle(CinematicFieldInput field) =>
      inputs().commitField(
        field,
        tryCommit: (value) => controller.editFromInspector(
          'a',
          (asset) => asset.copyWith(title: value),
          inputs(),
        ),
        fallbackError: 'Corrigez la saisie de « Nom de la cinématique ».',
        alwaysCommit: true,
      ) !=
      CinematicFieldCommitResult.rejected;

  test('inspector edit keyboard save and reopen', () async {
    final host = Object();
    final field = inputs().field('cinematic-title-a', 'Départ')
      ..edit('Départ au crépuscule');
    controller.attachInputHost(host, () => commitFocusedTitle(field));
    expect(controller.active!.asset.title, 'Départ');

    expect(await controller.save(), isTrue, reason: controller.error);

    expect(controller.active!.asset.title, 'Départ au crépuscule');
    expect(controller.active!.dirty, isFalse);
    expect(field.pending, isFalse);
    expect((await f.adapter().load('a')).asset.title, 'Départ au crépuscule');
    controller.detachInputHost(host);
  });

  test('a rejected focused title refuses the keyboard save', () async {
    final disk = await f.file('project.json').readAsBytes();
    final host = Object();
    final field = inputs().field('cinematic-title-a', 'Départ')..edit('');
    controller.attachInputHost(host, () => commitFocusedTitle(field));

    expect(await controller.save(), isFalse);

    expect(field.problem, isNotNull);
    expect(controller.active!.asset.title, 'Départ');
    expect(await f.file('project.json').readAsBytes(), disk);
    controller.detachInputHost(host);
  });

  test('uses owner actions for actor recovery and real controls for invalid fields', () async {
    final disk = await f.file('project.json').readAsBytes();
    final before = controller.active!.asset;

    final refused = await controller.addAction(
      CinematicTimelineStepKind.actorMove,
      choose: (_, _) async => null,
    );
    expect(refused, isNull);
    expect(controller.error, 'Ajoutez et sélectionnez un acteur.');
    expect(controller.active!.asset, same(before));

    final actor = controller.addActor('Guide')!;
    final move = await controller.addAction(
      CinematicTimelineStepKind.actorMove,
      actorId: actor,
      choose: (_, _) async => null,
    );
    expect(move, isNotNull, reason: controller.error);
    final step = controller.active!.asset.timeline.steps.singleWhere(
      (s) => s.id == move,
    );

    final field = inputs().field('duration-a-$move', '${step.durationMs}')
      ..edit('-2');
    final result = inputs().commitField(
      field,
      tryCommit: (value) =>
          controller.commitStepDuration('a', inputs(), step, value),
      fallbackError: 'Corrigez la saisie de « Durée (ms) ».',
      alwaysCommit: true,
    );
    expect(result, CinematicFieldCommitResult.rejected);
    expect(controller.dirty, isTrue);
    expect(await controller.save(), isFalse);
    expect(await f.file('project.json').readAsBytes(), disk);

    final reads = controller.sourceReads;
    expect(await controller.reload(confirm: () async => false), isFalse);
    expect(field.text, '-2');
    expect(controller.sourceReads, reads);

    field.edit('1500');
    expect(
      inputs().commitField(
        field,
        tryCommit: (value) =>
            controller.commitStepDuration('a', inputs(), step, value),
        fallbackError: 'Corrigez la saisie de « Durée (ms) ».',
        alwaysCommit: true,
      ),
      CinematicFieldCommitResult.accepted,
    );
    expect(await controller.save(), isTrue, reason: controller.error);
    final saved = (await f.adapter().load('a')).asset;
    expect(saved, controller.active!.asset);
    expect(
      saved.timeline.steps.singleWhere((s) => s.id == move).durationMs,
      1500,
    );
  });
}
