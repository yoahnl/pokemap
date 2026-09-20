import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';
import 'package:avelune_studio/features/cinematics/application/cinematic_workspace_controller.dart';
import 'package:avelune_studio/features/cinematics/domain/cinematic_port.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/narrative/application/narrative_workspace_controller.dart';
import 'package:avelune_studio/features/narrative/data/local_narrative_adapter.dart';
import '../support/cinematic_adapter_fixture.dart';

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
  test(
    'editing during awaited publication keeps later draft and source conflicts preserve it',
    () async {
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
    },
  );
  test(
    'preview transport evaluates canonical frames without semantic edits or workspace rebuilds',
    () async {
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
    },
  );
  test(
    'spatial destination is one history edit; paths survive binding and duplication',
    () async {
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
    },
  );
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
  Completer<void>? loadGate, publishGate;
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
    if (publishGate != null) await publishGate!.future;
    return inner.publish(id: id, base: base, asset: asset, folderId: folderId);
  }

  @override
  Future<CinematicPublicationReceipt> delete({
    required CinematicSourceSnapshot base,
  }) => inner.delete(base: base);
  @override
  Future<CinematicPublicationReceipt> setArchived({
    required CinematicSourceSnapshot base,
    required bool archived,
  }) => inner.setArchived(base: base, archived: archived);
}
