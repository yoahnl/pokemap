import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';
import 'package:avelune_studio/features/cinematics/application/cinematic_workspace_controller.dart';
import 'package:avelune_studio/features/cinematics/domain/cinematic_port.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/coordination/workspace_workflow.dart';
import 'package:avelune_studio/features/narrative/application/interaction_edit_session.dart';
import 'package:avelune_studio/features/narrative/application/narrative_interaction.dart';
import 'package:avelune_studio/features/narrative/application/narrative_workspace_controller.dart';
import 'package:avelune_studio/features/narrative/data/local_narrative_adapter.dart';
import 'package:avelune_studio/features/narrative/domain/dialogue_draft.dart';

import '../support/cinematic_adapter_fixture.dart';
import '../support/map_workspace_fixture.dart';

void main() {
  late CinematicAdapterFixture f;
  late MapWorkspaceController maps;
  late NarrativeWorkspaceController narrative;
  late CinematicWorkspaceController c;
  late _DelayedPort port;
  var rebuilds = 0;
  setUp(() async {
    f = await CinematicAdapterFixture.create(
      cinematics: [
        CinematicAdapterFixture.asset('a'),
        CinematicAdapterFixture.asset('b'),
      ],
    );
    maps = MapWorkspaceController(f.session, f.maps);
    await maps.initialize();
    narrative = NarrativeWorkspaceController(
      maps,
      LocalNarrativeAdapter(session: f.session, mapAdapter: f.maps),
      () {},
      (_, _) async {},
    );
    port = _DelayedPort(f.adapter());
    c = CinematicWorkspaceController(
      narrative,
      port,
      changed: () => rebuilds++,
    );
  });
  tearDown(() async {
    c.dispose();
    narrative.dispose();
    maps.dispose();
    await f.dispose();
  });
  test(
    'guided defaults insert after the current step and undo natively',
    () async {
      await c.open('a');
      final original = c.active!.asset;
      final id = await c.addAction(
        CinematicTimelineStepKind.wait,
        afterStepId: 'a.wait',
        choose: (_, _) async => null,
      );
      expect(id, isNotNull, reason: c.error);
      expect(c.active!.asset.timeline.steps.last.id, id);
      expect(c.active!.asset.timeline.steps.last.durationMs, 1000);
      c.undo();
      expect(c.active!.asset, original);
      final rejected = await c.addAction(
        CinematicTimelineStepKind.actorFace,
        choose: (_, _) async => null,
      );
      expect(rejected, isNull);
      expect(c.active!.asset, original);
      expect(c.error, contains('acteur'));
      final actor = c.addActor('Guide')!;
      final target = c.addTarget('Arrivée')!;
      final beforeMove = c.active!.asset;
      final move = await c.addAction(
        CinematicTimelineStepKind.actorMove,
        actorId: actor,
        choose: (_, _) async => null,
      );
      expect(move, isNotNull, reason: c.error);
      expect(c.active!.asset.movementTargets.single.targetId, target);
      c.undo();
      expect(c.active!.asset, beforeMove);
    },
  );

  test('action input flushing stays opt-in for direct callers', () async {
    expect(await c.open('a'), isTrue);
    final inputs = c.inputsFor('a');
    final field = inputs.field('title', 'Départ')..edit('Saisie conservée');
    var flushes = 0;
    c.flushEdits = () {
      flushes++;
      return false;
    };
    final before = c.active!.asset;

    final id = await c.addAction(
      CinematicTimelineStepKind.wait,
      afterStepId: 'a.wait',
      choose: (_, _) async => null,
    );

    expect(id, isNotNull);
    expect(flushes, 0);
    expect(field.text, 'Saisie conservée');
    expect(field.pending, isTrue);
    expect(inputs.dirty, isTrue);
    expect(c.active!.asset.timeline.steps.last.id, id);
    c.undo();
    expect(c.active!.asset, before);
  });

  test('action input flush refusal precedes resource choice', () async {
    expect(await c.open('a'), isTrue);
    final before = c.active!.asset;
    final disk = await f.file('project.json').readAsBytes();
    final reads = c.sourceReads;
    final undo = c.canUndo, redo = c.canRedo;
    c.error = 'Diagnostic indépendant';
    var flushes = 0, choices = 0;
    c.flushEdits = () {
      flushes++;
      return false;
    };

    final id = await c.addAction(
      CinematicTimelineStepKind.dialogueLine,
      flushInputs: true,
      choose: (_, _) async {
        choices++;
        return 'dialogue';
      },
    );

    expect(id, isNull);
    expect(flushes, 1);
    expect(choices, 0);
    expect(c.active!.asset, same(before));
    expect(c.canUndo, undo);
    expect(c.canRedo, redo);
    expect(c.error, 'Diagnostic indépendant');
    expect(c.sourceReads, reads);
    expect(port.publications, 0);
    expect(await f.file('project.json').readAsBytes(), disk);
  });

  for (final kind in [
    CinematicTimelineStepKind.wait,
    CinematicTimelineStepKind.actorMove,
    CinematicTimelineStepKind.dialogueLine,
  ]) {
    test(
      'action input validation blocks ${kind.name} before mutation',
      () async {
        expect(await c.open('a'), isTrue);
        final actor = c.addActor('Guide')!;
        final inputs = c.inputsFor('a');
        final field = inputs.field('duration', '1400')
          ..edit('-2')
          ..reject('Durée invalide');
        final revision = inputs.revision;
        final before = c.active!.asset;
        final undo = c.canUndo, redo = c.canRedo;
        final disk = await f.file('project.json').readAsBytes();
        final reads = c.sourceReads;
        c.error = 'Diagnostic indépendant';
        var flushes = 0, choices = 0;
        c.flushEdits = () {
          flushes++;
          return true;
        };

        final id = await c.addAction(
          kind,
          actorId: actor,
          flushInputs: true,
          choose: (_, _) async {
            choices++;
            return 'dialogue';
          },
        );

        expect(id, isNull);
        expect(flushes, 1);
        expect(choices, 0);
        expect(c.active!.asset, same(before));
        expect(c.active!.asset.movementTargets, isEmpty);
        expect(c.canUndo, undo);
        expect(c.canRedo, redo);
        expect(field.text, '-2');
        expect(field.problem, 'Durée invalide');
        expect(inputs.revision, revision);
        expect(inputs.dirty, isTrue);
        expect(c.error, 'Diagnostic indépendant');
        expect(c.sourceReads, reads);
        expect(port.publications, 0);
        expect(await f.file('project.json').readAsBytes(), disk);
      },
    );
  }

  for (final change in ['document', 'controller', 'project', 'caller']) {
    for (final kind in [
      CinematicTimelineStepKind.wait,
      CinematicTimelineStepKind.dialogueLine,
    ]) {
      test(
        'action input flush changing $change cancels ${kind.name}',
        () async {
          expect(await c.open('a'), isTrue);
          final disk = await f.file('project.json').readAsBytes();
          final reads = c.sourceReads;
          CinematicAsset? afterFlush, sourceAfterFlush;
          var active = true;
          var choices = 0;
          c.flushEdits = () {
            switch (change) {
              case 'document':
                unawaited(c.create('Autre document'));
              case 'controller':
                c.dispose();
              case 'project':
                maps.project = maps.project!.copyWith(name: 'Autre contexte');
              case 'caller':
                active = false;
            }
            c.error = 'Diagnostic indépendant après flush';
            afterFlush = c.active?.asset;
            sourceAfterFlush = c.session('a')?.asset;
            return true;
          };

          final id = await c.addAction(
            kind,
            flushInputs: true,
            isActive: () => active,
            choose: (_, _) async {
              choices++;
              return 'dialogue';
            },
          );

          expect(id, isNull);
          expect(choices, 0);
          expect(c.active?.asset, same(afterFlush));
          expect(c.session('a')?.asset, same(sourceAfterFlush));
          expect(c.error, 'Diagnostic indépendant après flush');
          expect(c.sourceReads, reads);
          expect(port.publications, 0);
          expect(await f.file('project.json').readAsBytes(), disk);
        },
      );
    }
  }

  test(
    'action input flush commits focused text before native insertion',
    () async {
      expect(await c.open('a'), isTrue);
      final inputs = c.inputsFor('a');
      final field = inputs.field('title', 'Départ')..edit('Titre validé');
      late CinematicAsset afterFlush;
      var flushes = 0;
      c.flushEdits = () {
        flushes++;
        inputs.commitField(
          field,
          tryCommit: c.rename,
          fallbackError: 'Nom invalide',
        );
        afterFlush = c.active!.asset;
        return true;
      };

      final id = await c.addAction(
        CinematicTimelineStepKind.wait,
        afterStepId: 'a.wait',
        flushInputs: true,
        choose: (_, _) async => null,
      );

      expect(flushes, 1);
      expect(inputs.valid, isTrue);
      expect(field.pending, isFalse);
      expect(c.active!.asset.title, 'Titre validé');
      expect(id, isNotNull);
      expect(c.active!.asset.timeline.steps.last.id, id);
      c.undo();
      expect(c.active!.asset, afterFlush);
    },
  );

  for (final kind in [
    CinematicTimelineStepKind.dialogueLine,
    CinematicTimelineStepKind.music,
  ]) {
    test(
      'action choices retain ${kind.name} cancellation and native insertion',
      () async {
        maps.project = maps.project!.copyWith(
          dialogues: const [
            ProjectDialogueEntry(
              id: 'dialogue',
              name: 'Dialogue proposé',
              relativePath: 'dialogues/dialogue.yarn',
            ),
          ],
          cinematicMediaAssets: [
            CinematicMediaAsset(
              id: 'music',
              label: 'Musique proposée',
              kind: CinematicMediaAssetKind.music,
              relativePath: 'audio/music.ogg',
            ),
            CinematicMediaAsset(
              id: 'sound',
              label: 'Son hors choix',
              kind: CinematicMediaAssetKind.sound,
              relativePath: 'audio/sound.ogg',
            ),
          ],
        );
        expect(await c.open('a'), isTrue);
        final before = c.active!.asset;
        final expected = kind == CinematicTimelineStepKind.music
            ? {'music': 'Musique proposée'}
            : {'dialogue': 'Dialogue proposé'};
        final undo = c.canUndo, redo = c.canRedo;
        expect(
          await c.addAction(
            kind,
            flushInputs: true,
            choose: (_, options) async {
              expect(options, expected);
              return null;
            },
          ),
          isNull,
        );
        expect(c.active!.asset, same(before));
        expect(c.canUndo, undo);
        expect(c.canRedo, redo);

        final id = await c.addAction(
          kind,
          afterStepId: 'a.wait',
          flushInputs: true,
          choose: (_, options) async {
            expect(options, expected);
            return options.keys.single;
          },
        );

        expect(id, isNotNull, reason: c.error);
        expect(c.active!.asset.timeline.steps.last.kind, kind);
        expect(
          c.active!.asset.timeline.steps.last.assetRef,
          expected.keys.single,
        );
        expect(port.publications, 0);
        c.undo();
        expect(c.active!.asset, before);
      },
    );
  }

  test(
    'late resource choice cannot add an action to another document',
    () async {
      await c.open('a');
      final choice = Completer<String?>();
      final pending = c.addAction(
        CinematicTimelineStepKind.dialogueLine,
        choose: (_, _) => choice.future,
      );
      await c.open('b');
      final before = c.active!.asset;
      choice.complete('dialogue');
      expect(await pending, isNull);
      expect(c.active!.asset, before);
    },
  );

  test(
    'map preview discards superseded and suspended asynchronous loads',
    () async {
      await c.open('a');
      c.edit((asset) => asset.copyWith(mapId: 'first'));
      final first = Completer<MapData>();
      final second = Completer<MapData>();
      Future<MapData> load(String id) =>
          id == 'first' ? first.future : second.future;
      c.prepareMapPreview(load: load);
      c.edit((asset) => asset.copyWith(mapId: 'second'));
      c.prepareMapPreview(load: load);
      first.completeError(StateError('Erreur tardive'));
      await Future<void>.delayed(Duration.zero);
      expect(c.previewMapProblem, isNull);
      second.complete(workspaceMap('second'));
      await Future<void>.delayed(Duration.zero);
      c.prepareMapPreview(load: load);
      expect(c.previewModel!.map.id, 'second');
      expect(c.transport.plan, isNotNull);
      c.suspendMapPreview();
      expect(c.previewModel, isNull);
      expect(c.transport.playing, isFalse);
      final late = Completer<MapData>();
      c.prepareMapPreview(load: (_) => late.future);
      c.suspendMapPreview();
      late.completeError(StateError('Projet fermé'));
      await Future<void>.delayed(Duration.zero);
      expect(c.previewMapProblem, isNull);
      expect(c.previewModel, isNull);
    },
  );
  test('targeted input discard resets rejected text in place', () async {
    expect(await c.open('a'), isTrue);
    final before = c.active!.asset;
    final inputs = c.inputsFor('a');
    final field = inputs.field('duration', '1400');
    field
      ..edit('-2')
      ..reject('Durée invalide');

    inputs.discard();

    expect(field.text, '1400');
    expect(inputs.field('duration', '1400'), same(field));
    expect(inputs.valid, isTrue);
    expect(c.active!.asset, same(before));
    field.edit('nouvelle saisie avant reconstruction');
    expect(inputs.dirty, isTrue);
    expect(inputs.field('duration', '1400'), same(field));
    expect(field.text, 'nouvelle saisie avant reconstruction');
  });

  test('targeted input discard preserves unsaved assets and other cinematic drafts', () async {
    expect(await c.open('a'), isTrue);
    c.edit((asset) => asset.copyWith(title: 'Asset A non enregistré'));
    c.edit((asset) => asset.copyWith(notes: 'Modification à rétablir'));
    c.undo();
    final beforeA = c.active!;
    final undoA = c.canUndo, redoA = c.canRedo;
    final inputsA = c.inputsFor('a');
    final fieldA = inputsA.field('duration', '1400');
    fieldA
      ..edit('-2')
      ..reject('Durée invalide');
    final preparation = c.prepareInputDiscard('a')!;
    expect(preparation.cinematicId, 'a');
    expect(preparation.title, 'Asset A non enregistré');
    expect(await c.open('b'), isTrue);
    c.edit((asset) => asset.copyWith(title: 'Asset B non enregistré'));
    final beforeB = c.active!;
    final inputsB = c.inputsFor('b');
    final fieldB = inputsB.field('duration', '1400');
    fieldB
      ..edit('saisie B')
      ..reject('Erreur B');
    c.error = 'Erreur B';
    final revisionB = inputsB.revision;
    final beforeDisk = await f.file('project.json').readAsBytes();
    final reads = c.sourceReads;

    expect(c.discardInputs(preparation, confirmed: true), isTrue);

    expect(c.activeId, 'b');
    expect(c.active!.asset, same(beforeB.asset));
    expect(c.active!.revision, beforeB.revision);
    expect(c.inputsFor('a'), same(inputsA));
    expect(fieldA.text, '1400');
    expect(inputsA.field('duration', '1400'), same(fieldA));
    expect(inputsA.valid, isTrue);
    expect(c.inputsFor('b'), same(inputsB));
    expect(inputsB.field('duration', '1400'), same(fieldB));
    expect(fieldB.text, 'saisie B');
    expect(inputsB.error, 'Erreur B');
    expect(inputsB.revision, revisionB);
    expect(c.error, 'Erreur B');
    expect(c.pendingInputDiscards.map((entry) => entry.cinematicId), ['b']);
    expect(c.sourceReads, reads);
    expect(await f.file('project.json').readAsBytes(), beforeDisk);
    expect(await c.open('a'), isTrue);
    expect(c.active!.asset, same(beforeA.asset));
    expect(c.active!.revision, beforeA.revision);
    expect(c.active!.dirty, isTrue);
    expect(c.canUndo, undoA);
    expect(c.canRedo, redoA);
    expect(c.discardInputs(preparation, confirmed: true), isFalse);
  });

  test('targeted input discard recovers a new cinematic without reading a published source', () async {
    expect(await c.create('Nouvelle cinématique'), isTrue);
    final before = c.active!;
    final inputs = c.inputsFor(before.asset.id);
    final field = inputs.field('title', before.asset.title);
    field
      ..edit('')
      ..reject('Indiquez un nom');
    inputs.validateField(field, () {
      inputs.error = 'Indiquez un nom';
      c.error = inputs.error;
      return false;
    });
    final beforeDisk = await f.file('project.json').readAsBytes();
    final reads = c.sourceReads;

    expect(
      c.discardInputs(c.prepareInputDiscard(before.asset.id)!, confirmed: true),
      isTrue,
    );

    expect(c.active!.asset, same(before.asset));
    expect(c.active!.revision, before.revision);
    expect(c.active!.dirty, isTrue);
    expect(c.dirty, isTrue);
    expect(field.text, 'Nouvelle cinématique');
    expect(inputs.field('title', before.asset.title), same(field));
    expect(inputs.valid, isTrue);
    expect(c.error, isNull);
    expect(c.pendingInputDiscards, isEmpty);
    expect(c.sourceReads, reads);
    expect(await f.file('project.json').readAsBytes(), beforeDisk);
    field.edit('saisie après abandon avant reconstruction');
    expect(inputs.dirty, isTrue);
    expect(inputs.field('title', before.asset.title), same(field));
    expect(field.text, 'saisie après abandon avant reconstruction');
  });

  test('targeted input discard enumeration is read only and excludes absent or clean owners', () async {
    final before = c.captureDraftGuard();
    expect(c.prepareInputDiscard('absent'), isNull);
    expect(c.prepareInputDiscard('a'), isNull);
    expect(c.pendingInputDiscards, isEmpty);
    expect(before(), isTrue);
    expect(c.sourceReads, 0);
    expect(await c.open('a'), isTrue);
    expect(c.prepareInputDiscard('a'), isNull);
    final inputs = c.inputsFor('a');
    inputs.field('duration', '1400').edit('en attente');
    c.inputsFor('absent').field('title', 'Absent').edit('hors session');
    final opened = c.captureDraftGuard();
    final reads = c.sourceReads;

    final preparations = c.pendingInputDiscards.toList();

    expect(preparations.map((entry) => entry.cinematicId), ['a']);
    expect(opened(), isTrue);
    expect(c.sourceReads, reads);
    expect(c.prepareInputDiscard('absent'), isNull);
  });

  test(
    'targeted input discard refuses an unconfirmed or stale input preparation',
    () async {
      expect(await c.open('a'), isTrue);
      final inputs = c.inputsFor('a');
      final field = inputs.field('duration', '1400');
      field
        ..edit('-2')
        ..reject('Durée invalide');
      final preparation = c.prepareInputDiscard('a')!;
      final revision = inputs.revision;
      final before = c.active!.asset;
      final beforeDisk = await f.file('project.json').readAsBytes();

      expect(c.discardInputs(preparation, confirmed: false), isFalse);
      expect(inputs.revision, revision);
      expect(field.text, '-2');
      expect(inputs.error, 'Durée invalide');
      field.edit('saisie pendant confirmation');
      expect(c.discardInputs(preparation, confirmed: true), isFalse);
      expect(field.text, 'saisie pendant confirmation');
      expect(inputs.dirty, isTrue);
      expect(c.active!.asset, same(before));
      expect(await f.file('project.json').readAsBytes(), beforeDisk);
    },
  );

  test(
    'targeted input discard refuses a changed asset or replaced session',
    () async {
      expect(await c.open('a'), isTrue);
      final inputs = c.inputsFor('a');
      final field = inputs.field('duration', '1400');
      field.edit('-2');
      final beforeEdit = c.prepareInputDiscard('a')!;
      c.edit((asset) => asset.copyWith(title: 'Modifié pendant confirmation'));
      final edited = c.active!.asset;

      expect(c.discardInputs(beforeEdit, confirmed: true), isFalse);
      expect(field.text, '-2');
      expect(c.active!.asset, same(edited));
      final beforeReload = c.prepareInputDiscard('a')!;
      port.loadGate = Completer<void>();
      final loading = c.reload();
      expect(c.busy, isTrue);
      expect(c.prepareInputDiscard('a'), isNull);
      expect(c.pendingInputDiscards, isEmpty);
      expect(c.discardInputs(beforeReload, confirmed: true), isFalse);
      expect(field.text, '-2');
      field.edit('à conserver pendant lecture');
      port.loadGate!.complete();
      expect(await loading, isTrue);
      expect(c.discardInputs(beforeReload, confirmed: true), isFalse);
      expect(field.text, 'à conserver pendant lecture');
      expect(inputs.dirty, isTrue);
    },
  );

  test('targeted input discard keeps export blocked until every invalid owner is recovered', () async {
    expect(await c.open('a'), isTrue);
    final assetA = c.active!.asset;
    final inputsA = c.inputsFor('a');
    final fieldA = inputsA.field('duration', '1400');
    fieldA
      ..edit('-2')
      ..reject('Durée A invalide');
    expect(await c.open('b'), isTrue);
    final assetB = c.active!.asset;
    final inputsB = c.inputsFor('b');
    final fieldB = inputsB.field('duration', '1400');
    fieldB
      ..edit('-3')
      ..reject('Durée B invalide');
    final revisionB = inputsB.revision;
    final beforeDisk = await f.file('project.json').readAsBytes();
    final reads = c.sourceReads;
    final workflow = WorkspaceWorkflow(
      controller: maps,
      isActive: () => true,
      changed: () {},
      resources: () => null,
      narrative: () => null,
      cinematics: () => c,
      confirmClose: () async => WorkspaceCloseChoice.cancel,
      flushFocus: () {},
      launchMap: (_, _) async {},
    );

    expect(await workflow.saveForExport(), isFalse);
    expect(
      c.discardInputs(c.prepareInputDiscard('a')!, confirmed: true),
      isTrue,
    );
    expect(await workflow.saveForExport(), isFalse);
    expect(fieldA.text, '1400');
    expect(fieldB.text, '-3');
    expect(inputsB.revision, revisionB);
    expect(inputsB.error, 'Durée B invalide');
    expect(await f.file('project.json').readAsBytes(), beforeDisk);
    expect(port.publications, 0);

    expect(
      c.discardInputs(c.prepareInputDiscard('b')!, confirmed: true),
      isTrue,
    );
    expect(await workflow.saveForExport(), isTrue);
    expect(workflow.exportPreparationFailure, isNull);
    expect(c.session('a')!.asset, same(assetA));
    expect(c.session('b')!.asset, same(assetB));
    expect(inputsA.field('duration', '1400'), same(fieldA));
    expect(inputsB.field('duration', '1400'), same(fieldB));
    expect(c.dirty, isFalse);
    expect(c.sourceReads, reads);
    expect(port.publications, 0);
    expect(await f.file('project.json').readAsBytes(), beforeDisk);
  });

  for (final independentError in [false, true]) {
    test(
      'targeted input discard ${independentError ? 'preserves an independent error after' : 'clears its stale confirmation error on'} successful retry',
      () async {
        expect(await c.open('a'), isTrue);
        final field = c.inputsFor('a').field('duration', '1400');
        field
          ..edit('-2')
          ..reject('Durée invalide');
        final stale = c.prepareInputDiscard('a')!;
        field.edit('modifié pendant confirmation');
        expect(c.discardInputs(stale, confirmed: true), isFalse);
        expect(c.error, contains('ont changé'));
        if (independentError) {
          expect(c.updateDuration('a.wait', -1), isFalse);
          expect(c.error, isNot(contains('ont changé')));
        }
        final error = c.error;

        expect(
          c.discardInputs(c.prepareInputDiscard('a')!, confirmed: true),
          isTrue,
        );

        expect(field.text, '1400');
        expect(c.inputsFor('a').valid, isTrue);
        expect(c.error, independentError ? error : isNull);
      },
    );
  }

  test('targeted input discard preserves action diagnostics arriving during confirmation', () async {
    expect(await c.open('a'), isTrue);
    final asset = c.active!.asset;
    final inputs = c.inputsFor('a');
    final field = inputs.field('duration', '1400');
    field
      ..edit('-2')
      ..reject('Durée invalide');
    final preparation = c.prepareInputDiscard('a')!;
    final revision = inputs.revision;
    inputs.actionError = 'La carte ne peut pas être ouverte';
    inputs.spatialError = 'Choisissez une case dans la carte';
    inputs.inspectorError = 'Une action de l’inspecteur a échoué';
    c.error = inputs.inspectorError;
    expect(inputs.revision, greaterThan(revision));

    expect(c.discardInputs(preparation, confirmed: true), isFalse);
    expect(field.text, '-2');
    expect(inputs.inspectorError, 'Une action de l’inspecteur a échoué');
    expect(c.error, 'Une action de l’inspecteur a échoué');

    expect(
      c.discardInputs(c.prepareInputDiscard('a')!, confirmed: true),
      isTrue,
    );

    expect(field.text, '1400');
    expect(inputs.field('duration', '1400'), same(field));
    expect(inputs.valid, isTrue);
    expect(inputs.actionError, 'La carte ne peut pas être ouverte');
    expect(inputs.spatialError, 'Choisissez une case dans la carte');
    expect(inputs.inspectorError, 'Une action de l’inspecteur a échoué');
    expect(c.error, 'Une action de l’inspecteur a échoué');
    expect(c.active!.asset, same(asset));
    expect(port.publications, 0);
  });

  test('targeted input discard preserves an independent inspector error mirrored in the input guard', () async {
    expect(await c.open('a'), isTrue);
    final inputs = c.inputsFor('a');
    final field = inputs.field('duration', '1400');
    field
      ..edit('-2')
      ..reject('Durée invalide');
    expect(c.updateDuration('a.wait', -1), isFalse);
    final inspectorError = c.error;
    inputs.error = inputs.inspectorError = inspectorError;

    expect(
      c.discardInputs(c.prepareInputDiscard('a')!, confirmed: true),
      isTrue,
    );

    expect(field.text, '1400');
    expect(field.pending, isFalse);
    expect(field.problem, isNull);
    expect(inputs.inspectorError, inspectorError);
    expect(inputs.error, inspectorError);
    expect(inputs.valid, isFalse);
    expect(c.flushEdits!(), isFalse);
    expect(c.error, inspectorError);
    expect(port.publications, 0);
  });

  test('targeted input discard preserves an independent diagnostic identical to a rejected field error', () async {
    expect(await c.open('a'), isTrue);
    final inputs = c.inputsFor('a');
    final field = inputs.field('duration', '1400');
    const message = 'La durée doit être strictement positive';
    field
      ..edit('-2')
      ..reject(message);
    final preparation = c.prepareInputDiscard('a')!;
    inputs.inspectorError = message;
    c.error = message;

    expect(c.discardInputs(preparation, confirmed: true), isFalse);
    expect(field.text, '-2');
    expect(c.error, message);
    expect(
      c.discardInputs(c.prepareInputDiscard('a')!, confirmed: true),
      isTrue,
    );

    expect(field.text, '1400');
    expect(field.problem, isNull);
    expect(inputs.inspectorError, message);
    expect(c.error, message);
  });

  test('targeted input discard preserves a global failure independently rewritten with identical text', () async {
    expect(await c.open('a'), isTrue);
    final inputs = c.inputsFor('a');
    final field = inputs.field('duration', '1400');
    field.edit('-2');
    inputs.validateField(field, () {
      expect(c.updateDuration('a.wait', -1), isFalse);
      inputs.error = c.error;
      return false;
    });
    field.reject(inputs.error!);
    final original = c.error;
    final preparation = c.prepareInputDiscard('a')!;
    expect(c.updateDuration('a.wait', -1), isFalse);
    expect(c.error, original);

    expect(c.discardInputs(preparation, confirmed: true), isTrue);

    expect(field.text, '1400');
    expect(inputs.valid, isTrue);
    expect(c.error, original);
  });

  test('uncommitted input protects an otherwise clean owner from source invalidation', () async {
    await c.open('a');
    final asset = c.active!.asset;
    final reads = c.sourceReads;
    final inputs = c.inputsFor('a');
    inputs.field('duration', '1400').edit('texte non validé');
    expect(c.active!.dirty, isFalse);
    expect(c.dirty, isTrue);
    expect(c.accessProblem('a'), isNotNull);
    c.invalidateSources({'a'});
    expect(await c.open('a'), isTrue);
    expect(c.sourceReads, reads);
    expect(c.active!.asset, same(asset));
    expect(c.inputsFor('a'), same(inputs));
    expect(inputs.field('duration', '1400').text, 'texte non validé');
    expect(c.flushEdits!(), isFalse);
  });

  test('reloading discards only the chosen cinematic inputs', () async {
    expect(await c.open('a'), isTrue);
    final inputsA = c.inputsFor('a');
    inputsA.field('duration', '1400')
      ..edit('-2')
      ..reject('Durée invalide');
    expect(await c.open('b'), isTrue);
    final inputsB = c.inputsFor('b');
    inputsB.field('duration', '800').edit('autre brouillon');
    expect(await c.open('a'), isTrue);

    expect(await c.reload(), isTrue);
    expect(c.inputsFor('a'), same(inputsA));
    expect(inputsA.field('duration', '1400').text, '1400');
    expect(inputsA.valid, isTrue);
    expect(inputsB.field('duration', '800').text, 'autre brouillon');
    expect(inputsB.dirty, isTrue);
  });

  test('input edited immediately after reload remains owned', () async {
    expect(await c.open('a'), isTrue);
    final inputs = c.inputsFor('a');
    final field = inputs.field('duration', '1400');
    field.edit('ancien brouillon');

    expect(await c.reload(), isTrue);
    field.edit('nouvelle saisie');
    expect(inputs.dirty, isTrue);
    expect(inputs.field('duration', '1400'), same(field));
    expect(field.text, 'nouvelle saisie');
  });

  test('normalizing a displayed value is not a new input', () async {
    expect(await c.open('a'), isTrue);
    final inputs = c.inputsFor('a');
    final field = inputs.field('duration', '02000');
    field
      ..edit('02000')
      ..accept();
    final revision = inputs.revision;

    field.synchronize('2000');
    expect(field.text, '2000');
    expect(inputs.revision, revision);
  });

  test('reloading preserves inputs changed during the load', () async {
    expect(await c.open('a'), isTrue);
    final inputs = c.inputsFor('a');
    inputs.field('duration', '1400').edit('première saisie');
    port.loadGate = Completer<void>();
    final loading = c.reload();
    inputs.field('duration', '1400').edit('saisie plus récente');
    port.loadGate!.complete();

    expect(await loading, isTrue);
    expect(inputs.field('duration', '1400').text, 'saisie plus récente');
    expect(inputs.dirty, isTrue);
  });

  test('a failed reload keeps the previous session and inputs', () async {
    expect(await c.open('a'), isTrue);
    final asset = c.active!.asset;
    final inputs = c.inputsFor('a');
    inputs.field('duration', '1400').edit('à conserver');
    port.loadGate = Completer<void>();
    final loading = c.reload();
    port.loadGate!.completeError(StateError('lecture impossible'));

    expect(await loading, isFalse);
    expect(c.active!.asset, same(asset));
    expect(inputs.field('duration', '1400').text, 'à conserver');
    expect(inputs.dirty, isTrue);
  });

  test('a superseded reload cannot replace a newer session', () async {
    expect(await c.open('a'), isTrue);
    final firstLoad = Completer<void>();
    port.loadGate = firstLoad;
    final staleReload = c.reload();
    expect(await c.open('b'), isTrue);
    port.loadGate = null;
    expect(await c.open('a'), isTrue);
    expect(c.edit((asset) => asset.copyWith(title: 'Version récente')), isTrue);
    firstLoad.complete();

    expect(await staleReload, isFalse);
    expect(c.active!.asset.title, 'Version récente');
    expect(c.active!.dirty, isTrue);
  });

  for (final deleting in [false, true]) {
    test(
      'document confirmation ${deleting ? 'deletion' : 'reload'} cancels without reading or writing and then applies only its target',
      () async {
        expect(await c.open('b'), isTrue);
        c.edit((asset) => asset.copyWith(title: 'Autre brouillon'));
        final other = c.active!;
        final otherInputs = c.inputsFor('b');
        final otherField = otherInputs.field('duration', '1400')
          ..edit('saisie B');
        final otherRevision = otherInputs.revision;
        expect(await c.open('a'), isTrue);
        c.edit((asset) => asset.copyWith(title: 'Brouillon A'));
        final before = c.active!;
        final inputs = c.inputsFor('a');
        final field = inputs.field('duration', '1400')
          ..edit('-2')
          ..reject('Durée invalide');
        final revision = inputs.revision;
        final reads = c.sourceReads;
        final beforeDisk = await f.file('project.json').readAsBytes();
        var prompts = 0;
        Future<bool> cancel() async {
          prompts++;
          return false;
        }

        expect(
          await (deleting
              ? c.delete('a', confirm: cancel)
              : c.reload(confirm: cancel)),
          isFalse,
        );

        expect(prompts, 1);
        expect(c.sourceReads, reads);
        expect(port.deletions, 0);
        expect(port.publications, 0);
        expect(c.active!.asset, same(before.asset));
        expect(c.active!.revision, before.revision);
        expect(inputs.revision, revision);
        expect(field.text, '-2');
        expect(await f.file('project.json').readAsBytes(), beforeDisk);
        expect(
          await (deleting
              ? c.delete('a', confirm: () async => true)
              : c.reload(confirm: () async => true)),
          isTrue,
        );
        expect(c.session('b')!.asset, same(other.asset));
        expect(c.session('b')!.revision, other.revision);
        expect(otherInputs.revision, otherRevision);
        expect(otherField.text, 'saisie B');
        expect(port.publications, 0);
        if (deleting) {
          expect(c.session('a'), isNull);
          expect(port.deletions, 1);
          expect((await f.readManifest()).cinematics.map((asset) => asset.id), [
            'b',
          ]);
        } else {
          expect(c.active!.asset, CinematicAdapterFixture.asset('a'));
          expect(c.inputsFor('a'), same(inputs));
          expect(inputs.field('duration', '1400'), same(field));
          expect(field.text, '1400');
          expect(inputs.valid, isTrue);
          expect(c.sourceReads, reads + 1);
          expect(await f.file('project.json').readAsBytes(), beforeDisk);
        }
      },
    );

    for (final mutation in [
      'input',
      'asset',
      'session',
      'project',
      'removed project',
      'closed project',
      'owner',
      'diagnostic',
    ]) {
      test(
        'document confirmation ${deleting ? 'deletion' : 'reload'} refuses a stale $mutation',
        () async {
          expect(await c.open('a'), isTrue);
          c.edit((asset) => asset.copyWith(title: 'Brouillon confirmé'));
          final inputs = c.inputsFor('a');
          final field = inputs.field('duration', '1400')..edit('-2');
          final answer = Completer<bool>();
          final prompted = Completer<void>();
          var owner = c;
          Future<bool> confirm() {
            prompted.complete();
            return answer.future;
          }

          final beforeDisk = await f.file('project.json').readAsBytes();
          final pending = deleting
              ? c.delete(
                  'a',
                  confirm: confirm,
                  isActive: () => identical(owner, c),
                )
              : c.reload(confirm: confirm, isActive: () => identical(owner, c));
          await prompted.future;
          switch (mutation) {
            case 'input':
              field.edit('saisie pendant confirmation');
            case 'asset':
              c.edit((asset) => asset.copyWith(notes: 'Modification récente'));
            case 'session':
              expect(await c.reload(), isTrue);
              field.edit('saisie dans la nouvelle session');
            case 'project':
              maps.project = maps.project!.copyWith(name: 'Projet remplacé');
            case 'removed project':
              maps.project = null;
            case 'closed project':
              maps.dispose();
            case 'owner':
              owner = CinematicWorkspaceController(
                narrative,
                port,
                changed: () {},
              );
              addTearDown(owner.dispose);
            case 'diagnostic':
              inputs.inspectorError = 'Erreur récente à conserver';
              c.error = inputs.inspectorError;
          }
          final current = c.session('a')!;
          final currentText = field.text;
          final revision = inputs.revision;
          final reads = c.sourceReads;
          answer.complete(true);

          expect(await pending, isFalse);

          expect(c.session('a')!.asset, same(current.asset));
          expect(c.session('a')!.revision, current.revision);
          expect(field.text, currentText);
          expect(inputs.revision, revision);
          expect(c.sourceReads, reads);
          expect(port.publications, 0);
          expect(port.deletions, 0);
          expect(await f.file('project.json').readAsBytes(), beforeDisk);
          if (mutation == 'diagnostic') {
            expect(inputs.inspectorError, 'Erreur récente à conserver');
            expect(c.error, 'Erreur récente à conserver');
          }
        },
      );
    }
  }

  test(
    'document confirmation clean reload preserves the existing no-prompt path',
    () async {
      expect(await c.open('a'), isTrue);
      final reads = c.sourceReads;

      expect(
        await c.reload(
          confirm: () => throw StateError('Confirmation inattendue'),
        ),
        isTrue,
      );

      expect(c.sourceReads, reads + 1);
      expect(c.active!.dirty, isFalse);
      expect(port.publications, 0);
    },
  );

  test('document commands preserve duplicate archive restore and deletion through their real owners', () async {
    expect(await c.open('a'), isTrue);
    final original = c.active!.asset;
    expect(await c.duplicate('a'), isTrue);
    final id = c.activeId!;
    final beforeDisk = await f.file('project.json').readAsBytes();
    expect(await c.setArchived(true), isFalse);
    expect(await f.file('project.json').readAsBytes(), beforeDisk);
    expect(await c.save(), isTrue, reason: c.error);
    expect(await c.setArchived(true), isTrue, reason: c.error);
    expect(
      c.project.cinematicLibraryCatalog
          .entryFor(CinematicLibraryFamily.world, id)!
          .isArchived,
      isTrue,
    );
    expect(await c.setArchived(false), isTrue, reason: c.error);
    expect(
      c.project.cinematicLibraryCatalog
          .entryFor(CinematicLibraryFamily.world, id)!
          .isArchived,
      isFalse,
    );
    expect(
      await c.delete(id, confirm: () async => true),
      isTrue,
      reason: c.error,
    );
    expect(c.session(id), isNull);
    expect((await f.readManifest()).cinematics.map((asset) => asset.id), [
      'a',
      'b',
    ]);
    expect((await f.adapter().load('a')).asset, original);
  });

  test(
    'document confirmation deletion preserves scene dependency refusals',
    () async {
      expect(await c.open('a'), isTrue);
      final before = c.active!.asset;
      final beforeDisk = await f.file('project.json').readAsBytes();
      final scene = SceneAsset(
        id: 'consumer',
        name: 'Scène utilisatrice',
        graph: SceneGraph(
          startNodeId: 'start',
          nodes: [
            SceneNode(id: 'start', kind: SceneNodeKind.start),
            SceneNode(
              id: 'cinematic',
              kind: SceneNodeKind.cinematic,
              payload: SceneCinematicPayload(cinematicId: 'a'),
            ),
            SceneNode(id: 'end', kind: SceneNodeKind.end),
          ],
          edges: [
            SceneEdge(
              id: 'first',
              fromNodeId: 'start',
              fromPortId: 'completed',
              toNodeId: 'cinematic',
              kind: SceneEdgeKind.defaultFlow,
            ),
            SceneEdge(
              id: 'last',
              fromNodeId: 'cinematic',
              fromPortId: 'completed',
              toNodeId: 'end',
              kind: SceneEdgeKind.defaultFlow,
            ),
          ],
        ),
      );

      expect(
        await c.delete(
          'a',
          confirm: () async {
            maps.project = maps.project!.copyWith(scenes: [scene]);
            return true;
          },
        ),
        isFalse,
      );
      expect(await c.delete('a', confirm: () async => true), isFalse);

      expect(c.error, contains('Scène utilisatrice'));
      expect(c.active!.asset, same(before));
      expect(port.deletions, 0);
      expect(await f.file('project.json').readAsBytes(), beforeDisk);
    },
  );

  for (final opened in [false, true]) {
    test(
      'document confirmation cancelled non-active deletion preserves selection and preview opened=$opened',
      () async {
        if (opened) {
          expect(await c.open('a'), isTrue);
        }
        final target = c.session('a');
        expect(await c.open('b'), isTrue);
        final active = c.active!;
        c.preparePreview();
        c.transport.seek(400);
        final plan = c.transport.plan;
        c.error = 'Diagnostic B à conserver';
        final reads = c.sourceReads;
        final beforeDisk = await f.file('project.json').readAsBytes();
        var prompts = 0;

        expect(
          await c.delete(
            'a',
            confirm: () async {
              prompts++;
              return false;
            },
          ),
          isFalse,
        );

        expect(prompts, 1);
        expect(c.activeId, 'b');
        expect(c.active!.asset, same(active.asset));
        expect(c.active!.revision, active.revision);
        expect(
          c.session('a')?.asset,
          target == null ? isNull : same(target.asset),
        );
        expect(c.transport.plan, same(plan));
        expect(c.transport.timeMs, 400);
        expect(c.transport.previewActive, isTrue);
        expect(c.error, 'Diagnostic B à conserver');
        expect(c.sourceReads, reads);
        expect(port.deletions, 0);
        expect(await f.file('project.json').readAsBytes(), beforeDisk);
      },
    );
  }

  test('document confirmation deletes an unopened target without replacing the active cinematic', () async {
    expect(await c.open('b'), isTrue);
    c.edit((asset) => asset.copyWith(title: 'Brouillon B à conserver'));
    final active = c.active!;
    final field = c.inputsFor('b').field('duration', '1400')..edit('saisie B');
    final revision = c.inputsFor('b').revision;
    final reads = c.sourceReads;

    expect(
      await c.delete('a', confirm: () async => true),
      isTrue,
      reason: c.error,
    );

    expect(c.activeId, 'b');
    expect(c.active!.asset, same(active.asset));
    expect(c.active!.revision, active.revision);
    expect(field.text, 'saisie B');
    expect(c.inputsFor('b').revision, revision);
    expect(c.sourceReads, reads + 1);
    expect(port.deletions, 1);
    expect((await f.readManifest()).cinematics.map((asset) => asset.id), ['b']);
  });

  for (final published in [false, true]) {
    test(
      'deleted input owner no longer blocks global guards published=$published',
      () async {
        expect(await c.open('b'), isTrue);
        final other = c.active!;
        final otherInputs = c.inputsFor('b');
        final otherField = otherInputs.field('duration', '1400');
        final otherRevision = otherInputs.revision;
        if (published) {
          expect(await c.open('a'), isTrue);
        } else {
          expect(await c.create('Nouveau brouillon supprimé'), isTrue);
        }
        final id = c.activeId!;
        final inputs = c.inputsFor(id);
        final field = inputs.field('duration', '1400')
          ..edit('-2')
          ..reject('Durée invalide');
        inputs.validateField(field, () {
          c.error = inputs.error;
          return false;
        });

        expect(await c.delete(id, confirm: () async => true), isTrue);

        expect(c.session(id), isNull);
        expect(c.pendingInputDiscards, isEmpty);
        expect(c.error, isNull);
        expect(c.flushEdits!(), isTrue);
        expect(c.dirty, isFalse);
        expect(await c.saveAll(), isTrue);
        expect(field.text, '1400');
        expect(inputs.valid, isTrue);
        expect(c.session('b')!.asset, same(other.asset));
        expect(c.inputsFor('b'), same(otherInputs));
        expect(otherInputs.field('duration', '1400'), same(otherField));
        expect(otherInputs.revision, otherRevision);
        expect(port.publications, 0);
      },
    );
  }

  test(
    'failed input owner deletion preserves source and later input',
    () async {
      expect(await c.open('a'), isTrue);
      final before = c.active!;
      final inputs = c.inputsFor('a');
      final field = inputs.field('duration', '1400')..edit('-2');
      final beforeDisk = await f.file('project.json').readAsBytes();
      port.deleteStarted = Completer<void>();
      port.deleteGate = Completer<void>();
      final deleting = c.delete('a', confirm: () async => true);
      await port.deleteStarted!.future;
      field.edit('saisie pendant l’échec');
      final revision = inputs.revision;
      port.deleteGate!.completeError(StateError('Suppression impossible'));

      expect(await deleting, isFalse);

      expect(c.session('a')!.asset, same(before.asset));
      expect(c.inputsFor('a'), same(inputs));
      expect(field.text, 'saisie pendant l’échec');
      expect(inputs.revision, revision);
      expect(c.prepareInputDiscard('a'), isNotNull);
      expect(await f.file('project.json').readAsBytes(), beforeDisk);
    },
  );

  for (final independentError in [false, true]) {
    test(
      'published input owner deletion retains later input as a recoverable draft independentError=$independentError',
      () async {
        expect(await c.open('a'), isTrue);
        c.edit((asset) => asset.copyWith(title: 'Brouillon A à conserver'));
        c.edit((asset) => asset.copyWith(notes: 'Historique à conserver'));
        c.undo();
        final authored = c.active!.asset;
        final undo = c.canUndo, redo = c.canRedo;
        final inputs = c.inputsFor('a');
        final field = inputs.field('duration', '1400')..edit('-2');
        expect(await c.open('b'), isTrue);
        c.edit((asset) => asset.copyWith(title: 'Brouillon B à conserver'));
        final other = c.active!;
        final otherInputs = c.inputsFor('b');
        final otherField = otherInputs.field('duration', '1400');
        if (independentError) {
          otherInputs.actionError = 'Diagnostic B à conserver';
          c.error = otherInputs.actionError;
        }
        final otherRevision = otherInputs.revision;
        port.deletePublished = Completer<void>();
        port.deleteReceiptGate = Completer<void>();
        final deleting = c.delete('a', confirm: () async => true);
        await port.deletePublished!.future;
        expect(
          (await f.readManifest()).cinematics.any((asset) => asset.id == 'a'),
          isFalse,
        );
        field.edit('saisie arrivée après suppression disque');
        final revision = inputs.revision;
        port.deleteReceiptGate!.complete();

        expect(await deleting, isTrue);

        expect(
          (await f.readManifest()).cinematics.any((asset) => asset.id == 'a'),
          isFalse,
        );
        expect(c.session('a')!.asset, same(authored));
        expect(c.session('a')!.dirty, isTrue);
        expect(c.inputsFor('a'), same(inputs));
        expect(field.text, 'saisie arrivée après suppression disque');
        expect(inputs.revision, revision);
        expect(c.session('b')!.asset, same(other.asset));
        expect(c.session('b')!.revision, other.revision);
        expect(otherInputs.revision, otherRevision);
        expect(otherInputs.field('duration', '1400'), same(otherField));
        if (independentError) {
          expect(c.error, 'Diagnostic B à conserver');
          expect(otherInputs.actionError, 'Diagnostic B à conserver');
        } else {
          expect(c.error, contains('supprimée'));
        }
        expect(
          c.discardInputs(c.prepareInputDiscard('a')!, confirmed: true),
          isTrue,
        );
        expect(await c.open('a'), isTrue);
        expect(c.canUndo, undo);
        expect(c.canRedo, redo);
        expect(await c.save(), isTrue, reason: c.error);
        expect((await f.adapter().load('a')).asset, authored);
        expect(
          (await f.adapter().load('b')).asset,
          CinematicAdapterFixture.asset('b'),
        );
        expect(c.session('b')!.asset, same(other.asset));
        expect(port.publications, 1);
      },
    );
  }

  for (final contextChange in ['project', 'owner']) {
    for (final independentError in [false, true]) {
      test(
        'published deletion preserves a replaced $contextChange before its receipt independentError=$independentError',
        () async {
          expect(await c.open('a'), isTrue);
          final inputs = c.inputsFor('a');
          final field = inputs.field('duration', '1400')..edit('-2');
          expect(await c.open('b'), isTrue);
          c.edit((asset) => asset.copyWith(title: 'Brouillon B à conserver'));
          final other = c.active!;
          final otherInputs = c.inputsFor('b');
          final otherField = otherInputs.field('duration', '1400')
            ..edit('saisie B');
          final otherRevision = otherInputs.revision;
          port.deletePublished = Completer<void>();
          port.deleteReceiptGate = Completer<void>();
          var currentOwner = c;
          final deleting = c.delete(
            'a',
            confirm: () async => true,
            isActive: () => identical(currentOwner, c),
          );
          await port.deletePublished!.future;
          final currentProject = contextChange == 'project'
              ? maps.project!.copyWith(name: 'Projet courant conservé')
              : maps.project!;
          if (contextChange == 'project') {
            maps.project = currentProject;
          } else {
            currentOwner = CinematicWorkspaceController(
              narrative,
              port,
              changed: () {},
            );
            addTearDown(currentOwner.dispose);
          }
          final witnessMaps = MapWorkspaceController(
            workspaceSession,
            WorkspaceMemoryPort(),
          );
          await witnessMaps.initialize();
          addTearDown(witnessMaps.dispose);
          final witness = InteractionEditSession(
            document: witnessMaps.active!,
            dialogue: DialogueDraft.blank(
              const ProjectDialogueEntry(
                id: 'witness',
                name: 'Témoin',
                relativePath: 'witness.yarn',
              ),
            ),
            interaction: NarrativeInteractionDraft(
              id: 'witness',
              name: 'Interaction du nouveau contexte',
              mapId: 'a',
              source: NarrativeEventSourceRef.mapEnter('a'),
              dialogueId: 'witness',
            ),
            baseScene: SceneAsset(
              id: 'witness',
              name: 'Témoin du nouveau contexte',
              graph: SceneGraph(
                startNodeId: 'start',
                nodes: [
                  SceneNode(id: 'start', kind: SceneNodeKind.start),
                  SceneNode(
                    id: 'cinematic',
                    kind: SceneNodeKind.cinematic,
                    payload: SceneCinematicPayload(cinematicId: 'a'),
                  ),
                  SceneNode(id: 'end', kind: SceneNodeKind.end),
                ],
                edges: [
                  SceneEdge(
                    id: 'first',
                    fromNodeId: 'start',
                    fromPortId: 'completed',
                    toNodeId: 'cinematic',
                    kind: SceneEdgeKind.defaultFlow,
                  ),
                  SceneEdge(
                    id: 'last',
                    fromNodeId: 'cinematic',
                    fromPortId: 'completed',
                    toNodeId: 'end',
                    kind: SceneEdgeKind.defaultFlow,
                  ),
                ],
              ),
            ),
          );
          narrative.sessions['witness'] = witness;
          narrative.active = witness;
          final witnessState = witness.current;
          expect(narrative.interactionCinematicIds(witness), contains('a'));
          if (independentError) {
            c.error = 'Diagnostic indépendant à conserver';
          }
          port.deleteReceiptGate!.complete();

          expect(await deleting, isTrue);

          expect(maps.project, same(currentProject));
          expect(narrative.sessions['witness'], same(witness));
          expect(narrative.active, same(witness));
          expect(witness.current, same(witnessState));
          expect(witness.dirty, isFalse);
          expect(
            (await f.readManifest()).cinematics.any((asset) => asset.id == 'a'),
            isFalse,
          );
          expect(c.session('a'), isNull);
          expect(inputs.valid, isTrue);
          expect(field.text, '1400');
          expect(c.session('b')!.asset, same(other.asset));
          expect(c.session('b')!.revision, other.revision);
          expect(otherField.text, 'saisie B');
          expect(otherInputs.revision, otherRevision);
          expect(
            c.pendingInputDiscards.map(
              (preparation) => preparation.cinematicId,
            ),
            ['b'],
          );
          expect(
            c.error,
            independentError
                ? 'Diagnostic indépendant à conserver'
                : contains('catalogue'),
          );
        },
      );
    }
  }

  test(
    'closing offers an explicit discard for invalid cinematic input',
    () async {
      expect(await c.open('a'), isTrue);
      final inputs = c.inputsFor('a');
      inputs.field('duration', '1400')
        ..edit('-2')
        ..reject('Durée invalide');
      final beforeDisk = await f.file('project.json').readAsBytes();
      final choices = [
        WorkspaceCloseChoice.cancel,
        WorkspaceCloseChoice.save,
        WorkspaceCloseChoice.discard,
      ];
      var prompts = 0;
      final workflow = WorkspaceWorkflow(
        controller: maps,
        isActive: () => true,
        changed: () {},
        resources: () => null,
        narrative: () => null,
        cinematics: () => c,
        confirmClose: () async => choices[prompts++],
        flushFocus: () {},
        launchMap: (_, _) async {},
      );

      expect(await workflow.allowClose(), isFalse);
      expect(prompts, 1);
      expect(await workflow.allowClose(), isFalse);
      expect(prompts, 2);
      expect(inputs.field('duration', '1400').text, '-2');
      expect(await f.file('project.json').readAsBytes(), beforeDisk);
      expect(await workflow.allowClose(), isTrue);
      expect(prompts, 3);
      expect(inputs.field('duration', '1400').text, '-2');
      expect(await f.file('project.json').readAsBytes(), beforeDisk);
    },
  );

  test(
    'closing refuses to discard input changed during confirmation',
    () async {
      expect(await c.open('a'), isTrue);
      final inputs = c.inputsFor('a');
      final field = inputs.field('duration', '1400');
      field.edit('avant confirmation');
      final prompted = Completer<void>();
      final answer = Completer<WorkspaceCloseChoice>();
      final workflow = WorkspaceWorkflow(
        controller: maps,
        isActive: () => true,
        changed: () {},
        resources: () => null,
        narrative: () => null,
        cinematics: () => c,
        confirmClose: () {
          prompted.complete();
          return answer.future;
        },
        flushFocus: () {},
        launchMap: (_, _) async {},
      );

      final closing = workflow.allowClose();
      await prompted.future;
      field.edit('saisie plus récente');
      answer.complete(WorkspaceCloseChoice.discard);
      expect(await closing, isFalse);
      expect(field.text, 'saisie plus récente');
      expect(inputs.dirty, isTrue);
    },
  );

  test('closing offers a decision after a focused input is rejected', () async {
    expect(await c.open('a'), isTrue);
    final inputs = c.inputsFor('a');
    c.flushEdits = () {
      inputs.field('duration', '1400')
        ..edit('-2')
        ..reject('Durée invalide');
      c.error = 'Durée invalide';
      return false;
    };
    var prompts = 0;
    final workflow = WorkspaceWorkflow(
      controller: maps,
      isActive: () => true,
      changed: () {},
      resources: () => null,
      narrative: () => null,
      cinematics: () => c,
      confirmClose: () async {
        prompts++;
        return WorkspaceCloseChoice.cancel;
      },
      flushFocus: () {},
      launchMap: (_, _) async {},
    );

    expect(await workflow.allowClose(), isFalse);
    expect(prompts, 1);
    expect(inputs.field('duration', '1400').text, '-2');
    expect(inputs.dirty, isTrue);
  });

  test(
    'closing refuses to discard a cinematic edited during confirmation',
    () async {
      expect(await c.open('a'), isTrue);
      expect(c.edit((asset) => asset.copyWith(title: 'Avant')), isTrue);
      final prompted = Completer<void>();
      final answer = Completer<WorkspaceCloseChoice>();
      final workflow = WorkspaceWorkflow(
        controller: maps,
        isActive: () => true,
        changed: () {},
        resources: () => null,
        narrative: () => null,
        cinematics: () => c,
        confirmClose: () {
          prompted.complete();
          return answer.future;
        },
        flushFocus: () {},
        launchMap: (_, _) async {},
      );

      final closing = workflow.allowClose();
      await prompted.future;
      expect(c.edit((asset) => asset.copyWith(title: 'Après')), isTrue);
      answer.complete(WorkspaceCloseChoice.discard);
      expect(await closing, isFalse);
      expect(c.active!.asset.title, 'Après');
      expect(c.active!.dirty, isTrue);
    },
  );

  test(
    'closing also protects another open cinematic during confirmation',
    () async {
      expect(await c.open('b'), isTrue);
      expect(await c.open('a'), isTrue);
      expect(c.edit((asset) => asset.copyWith(title: 'Avant')), isTrue);
      final prompted = Completer<void>();
      final answer = Completer<WorkspaceCloseChoice>();
      final workflow = WorkspaceWorkflow(
        controller: maps,
        isActive: () => true,
        changed: () {},
        resources: () => null,
        narrative: () => null,
        cinematics: () => c,
        confirmClose: () {
          prompted.complete();
          return answer.future;
        },
        flushFocus: () {},
        launchMap: (_, _) async {},
      );

      final closing = workflow.allowClose();
      await prompted.future;
      expect(await c.open('b'), isTrue);
      expect(
        c.edit((asset) => asset.copyWith(title: 'Autre brouillon')),
        isTrue,
      );
      answer.complete(WorkspaceCloseChoice.discard);
      expect(await closing, isFalse);
      expect(c.active!.asset.title, 'Autre brouillon');
      expect(c.active!.dirty, isTrue);
    },
  );

  test('a superseded input host cannot clear its successor guard or suspend its preview', () async {
    await c.open('a');
    c.edit((asset) => asset.copyWith(mapId: 'first'));
    final before = c.active!.asset;
    final first = Object(), second = Object();
    var firstFlushes = 0, secondFlushes = 0;
    c.attachInputHost(first, () {
      firstFlushes++;
      return true;
    });
    c.attachInputHost(second, () {
      secondFlushes++;
      return true;
    });
    final loading = Completer<MapData>();
    c.prepareMapPreview(load: (_) => loading.future);
    c.detachInputHost(first);
    loading.complete(workspaceMap('first'));
    await Future<void>.delayed(Duration.zero);
    c.prepareMapPreview(load: (_) => loading.future);
    final model = c.previewModel;
    expect(model, isNotNull);
    expect(c.flushEdits!(), isTrue);
    expect(firstFlushes, 0);
    expect(secondFlushes, 1);
    c.detachInputHost(first);
    expect(c.previewModel, same(model));
    expect(c.previewMapId, 'first');
    final inputs = c.inputsFor('a');
    inputs.field('duration', '1400')
      ..edit('-2')
      ..reject('Durée invalide');
    c.detachInputHost(second);
    expect(c.previewModel, isNull);
    expect(c.previewMapId, isNull);
    expect(c.flushEdits!(), isFalse);
    expect(c.inputsFor('a'), same(inputs));
    expect(inputs.field('duration', '1400').text, '-2');
    expect(inputs.error, 'Durée invalide');
    final beforeDisk = await f.file('project.json').readAsBytes();
    expect(await c.saveAll(), isFalse);
    expect(c.active!.asset, before);
    expect(await f.file('project.json').readAsBytes(), beforeDisk);
    expect(c.dirty, isTrue);
  });

  test(
    'lazy library, draft create, canonical steps, undo save independent reread',
    () async {
      final bytes = await f.file('project.json').readAsBytes();
      expect(c.entries.length, 2);
      expect(c.sourceReads, 0);
      expect(await c.create('Une séquence'), true);
      expect(await f.file('project.json').readAsBytes(), bytes);
      final id = c.activeId!;
      final a = c.addBasic(
        CinematicTimelineBasicBlockKind.wait,
        durationMs: 400,
      )!;
      final b = c.addBasic(
        CinematicTimelineBasicBlockKind.fade,
        durationMs: 1200,
        afterStepId: a,
      )!;
      expect(c.moveSteps({b}, 0), true);
      expect(c.active!.asset.timeline.steps.first.id, b);
      expect(c.updateDuration(b, 700), true);
      c.undo();
      expect(c.active!.asset.timeline.steps.first.durationMs, 1200);
      c.redo();
      expect(c.active!.asset.timeline.steps.first.durationMs, 700);
      final snapshot = c.active!.asset;
      expect(await c.save(), true, reason: c.error);
      expect((await f.adapter().load(id)).asset, snapshot);
      c.undo();
      expect(c.active!.dirty, true);
      c.redo();
      expect(c.active!.dirty, false);
      expect(
        (await f.readManifest()).cinematics.firstWhere((x) => x.id == 'a'),
        CinematicAdapterFixture.asset('a'),
      );
    },
  );
  test('late opening response cannot select older document', () async {
    port.loadGate = Completer<void>();
    final loading = c.open('a');
    await Future<void>.delayed(Duration.zero);
    expect(await c.open('b'), true);
    port.loadGate!.complete();
    expect(await loading, false);
    expect(c.activeId, 'b');
    expect(c.active!.asset.id, 'b');
  });
  test('editing during awaited publication keeps later draft and source conflicts preserve it', () async {
    await c.open('a');
    c.rename('Snapshot envoyé');
    port.publishGate = Completer<void>();
    final saving = c.save();
    await Future<void>.delayed(Duration.zero);
    c.rename('Texte suivant');
    port.publishGate!.complete();
    expect(await saving, true, reason: c.error);
    expect(c.active!.dirty, true);
    expect(c.active!.asset.title, 'Texte suivant');
    expect((await f.adapter().load('a')).asset.title, 'Snapshot envoyé');
    final base = await f.adapter().load('a');
    await f.adapter().publish(
      id: 'a',
      base: base,
      asset: base.asset.copyWith(title: 'Autre auteur'),
    );
    expect(await c.save(), false);
    expect(c.active!.asset.title, 'Texte suivant');
    expect(await c.reload(), true);
    expect(c.active!.asset.title, 'Autre auteur');
  });
  test('preview transport evaluates canonical frames without semantic edits or workspace rebuilds', () async {
    await c.open('a');
    c.preparePreview();
    final builds = c.planBuilds, before = c.active!.asset;
    final notifications = rebuilds;
    c.preparePreview(resolvedTargets: {});
    expect(c.planBuilds, builds);
    c.transport.seek(700);
    expect(c.transport.frame!.timeMs, 700);
    c.transport.play();
    c.transport.pause();
    final paused = c.transport.timeMs;
    await Future<void>.delayed(const Duration(milliseconds: 25));
    expect(c.transport.timeMs, paused);
    c.transport.seek(200);
    c.transport.advance(300);
    expect(c.transport.frame, c.transport.plan!.frameAt(500));
    final plan = c.transport.plan;
    expect(await c.open('a'), true);
    expect(c.transport.plan, same(plan));
    expect(c.transport.timeMs, 500);
    final openedNotifications = rebuilds;
    c.transport.stop();
    expect(c.transport.timeMs, 0);
    expect(c.active!.asset, same(before));
    expect(c.active!.dirty, false);
    expect(openedNotifications, notifications + 1);
    expect(rebuilds, openedNotifications);
    expect(await f.file('project.json').readAsString(), contains('Départ'));
  });
  test('spatial destination is one history edit; paths survive binding and duplication', () async {
    await c.create('Mise en scène');
    final actor = c.addActor('Rôle')!, target = c.addTarget('Arrivée')!;
    final move = c.addMove(actor, target)!;
    final before = c.active!.asset;
    expect(c.setDestination(move, 3, 4, width: 10, height: 10), true);
    final placed = c.active!.asset;
    expect(placed.stageContext!.stagePoints.single.x, 3);
    c.undo();
    expect(c.active!.asset, before);
    c.redo();
    expect(c.active!.asset, placed);
    expect(c.setDestination(move, 10, 2, width: 10, height: 10), false);
    expect(c.active!.asset, placed);
    c.setStagePoint(
      CinematicStagePoint(id: 'middle', label: 'Milieu', x: 1, y: 2),
    );
    c.setManualPath(move, ['middle']);
    final path = c.active!.asset.stageContext!.manualPaths.single;
    expect(
      c.bindActor(
        CinematicActorBinding(
          actorId: actor,
          kind: CinematicActorBindingKind.player,
        ),
      ),
      true,
    );
    expect(c.active!.asset.stageContext!.manualPaths.single, path);
    final beforePlacement = c.active!.asset;
    expect(c.placeActorAt(actor, 2, 3, width: 10, height: 10), true);
    expect(c.active!.asset.stageContext!.manualPaths.single, path);
    c.undo();
    expect(c.active!.asset, beforePlacement);
    expect(c.appendWaypoint(move, 4, 5, width: 10, height: 10), true);
    expect(
      c
          .active!
          .asset
          .stageContext!
          .manualPaths
          .single
          .waypointStagePointIds
          .length,
      2,
    );
    c.undo();
    expect(c.active!.asset, beforePlacement);
    expect(c.appendWaypoint(move, -1, 4, width: 10, height: 10), false);
    expect(c.active!.asset, beforePlacement);
    expect(c.duplicateSteps({move}), true);
    expect(c.active!.asset.stageContext!.manualPaths.length, 2);
    final clipboard = c.copySteps({move})!;
    expect(
      c.pasteSteps(clipboard, c.active!.asset.timeline.steps.length),
      true,
    );
    expect(c.active!.asset.stageContext!.manualPaths.length, 3);
    final original = c.active!.asset;
    expect(await c.duplicate(original.id), true);
    final copy = c.active!.asset;
    expect(copy.id, isNot(original.id));
    expect(
      copy.timeline.steps
          .map((s) => s.id)
          .toSet()
          .intersection(original.timeline.steps.map((s) => s.id).toSet()),
      isEmpty,
    );
    expect(
      copy.stageContext!.manualPaths.every(
        (p) => copy.timeline.steps.any((s) => s.id == p.ownerActorMoveStepId),
      ),
      true,
    );
  });
  test(
    'invalid durations and unrelated clipboard bindings do not mutate history',
    () async {
      await c.create('Vide');
      final actor = c.addActor('A')!, target = c.addTarget('T')!;
      final move = c.addMove(actor, target)!;
      final clipboard = c.copySteps({move})!;
      final original = c.active!.asset;
      expect(c.updateDuration(move, -1), false);
      expect(c.active!.asset, same(original));
      await c.create('Autre');
      final empty = c.active!.asset;
      expect(c.pasteSteps(clipboard, 0), false);
      expect(c.active!.asset, same(empty));
    },
  );
}

class _DelayedPort implements CinematicPort {
  _DelayedPort(this.inner);
  final CinematicPort inner;
  int publications = 0, deletions = 0;
  Completer<void>? loadGate, publishGate;
  Completer<void>? deleteGate,
      deleteReceiptGate,
      deleteStarted,
      deletePublished;
  @override
  Future<CinematicSourceSnapshot> load(String id) async {
    if (id == 'a' && loadGate != null) await loadGate!.future;
    return inner.load(id);
  }

  @override
  Future<CinematicPublicationReceipt> publish({
    required String id,
    required CinematicSourceSnapshot? base,
    required CinematicAsset asset,
    String? folderId,
  }) async {
    publications++;
    if (publishGate != null) await publishGate!.future;
    return inner.publish(id: id, base: base, asset: asset, folderId: folderId);
  }

  @override
  Future<CinematicPublicationReceipt> delete({
    required CinematicSourceSnapshot base,
  }) async {
    deletions++;
    deleteStarted?.complete();
    if (deleteGate != null) {
      await deleteGate!.future;
    }
    final receipt = await inner.delete(base: base);
    deletePublished?.complete();
    if (deleteReceiptGate != null) {
      await deleteReceiptGate!.future;
    }
    return receipt;
  }

  @override
  Future<CinematicPublicationReceipt> setArchived({
    required CinematicSourceSnapshot base,
    required bool archived,
  }) => inner.setArchived(base: base, archived: archived);
}
