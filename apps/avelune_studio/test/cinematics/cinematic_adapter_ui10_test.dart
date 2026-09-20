import 'package:avelune_studio/features/cinematics/domain/cinematic_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

import '../support/cinematic_adapter_fixture.dart';

void main() {
  test(
    'referenced deletion lists consumer and leaves shared documents intact',
    () async {
      final asset = CinematicAdapterFixture.asset('departure');
      final scene = SceneAsset(
        id: 'scene_consumer',
        name: 'Départ en gare',
        graph: SceneGraph(
          startNodeId: 'start',
          nodes: [
            SceneNode(id: 'start', kind: SceneNodeKind.start),
            SceneNode(
              id: 'cinematic',
              kind: SceneNodeKind.cinematic,
              payload: SceneCinematicPayload(cinematicId: asset.id),
            ),
            SceneNode(id: 'end', kind: SceneNodeKind.end),
          ],
          edges: [
            SceneEdge(
              id: 'a',
              fromNodeId: 'start',
              fromPortId: 'completed',
              toNodeId: 'cinematic',
              kind: SceneEdgeKind.defaultFlow,
            ),
            SceneEdge(
              id: 'b',
              fromNodeId: 'cinematic',
              fromPortId: 'completed',
              toNodeId: 'end',
              kind: SceneEdgeKind.defaultFlow,
            ),
          ],
        ),
      );
      final f = await CinematicAdapterFixture.create(
        cinematics: [asset],
        scenes: [scene],
      );
      addTearDown(f.dispose);
      final base = await f.adapter().load(asset.id);
      final bytes = await f.file('project.json').readAsBytes();
      await expectLater(
        f.adapter().delete(base: base),
        throwsA(
          isA<CinematicFailure>().having(
            (error) => error.message,
            'consumer',
            contains('scene_consumer'),
          ),
        ),
      );
      expect(await f.file('project.json').readAsBytes(), bytes);
    },
  );

  test(
    'draft publication creates asset and library atomically without a map',
    () async {
      final f = await CinematicAdapterFixture.create();
      addTearDown(f.dispose);
      final port = f.adapter();
      final draft = CinematicAdapterFixture.asset('departure');
      expect((await f.readManifest()).cinematics, isEmpty);
      final saved = await port.publish(id: draft.id, base: null, asset: draft);
      expect(saved.resources.changedPaths, ['project.json']);
      expect(saved.snapshot!.asset, draft);
      expect(saved.snapshot!.entry!.family, CinematicLibraryFamily.world);
      expect((await f.readManifest()).maps, isEmpty);
      final renamed = await port.publish(
        id: draft.id,
        base: saved.snapshot,
        asset: draft.copyWith(title: 'Nouveau départ'),
      );
      expect((await f.adapter().load(draft.id)).asset, renamed.snapshot!.asset);
      expect(renamed.snapshot!.entry, saved.snapshot!.entry);
      final archived = await port.setArchived(
        base: renamed.snapshot!,
        archived: true,
      );
      expect(archived.snapshot!.entry!.isArchived, isTrue);
      final deleted = await port.delete(base: archived.snapshot!);
      expect(deleted.snapshot, isNull);
      expect((await f.readManifest()).cinematicLibraryCatalog.entries, isEmpty);
    },
  );

  test(
    'unclassified existing assets stay readable and are not reclassified by save',
    () async {
      final asset = CinematicAdapterFixture.asset('unclassified');
      final f = await CinematicAdapterFixture.create(cinematics: [asset]);
      addTearDown(f.dispose);
      final base = await f.adapter().load(asset.id);
      expect(base.entry, isNull);
      final saved = await f.adapter().publish(
        id: asset.id,
        base: base,
        asset: asset.copyWith(notes: 'Notes réelles'),
      );
      expect(saved.snapshot!.entry, isNull);
      expect((await f.readManifest()).cinematicLibraryCatalog.entries, isEmpty);
    },
  );

  test(
    'new library entry refuses version six without migration or write',
    () async {
      final f = await CinematicAdapterFixture.create(
        version: ProjectVersion.v6,
      );
      addTearDown(f.dispose);
      final bytes = await f.file('project.json').readAsBytes();
      await expectLater(
        f.adapter().publish(
          id: 'draft',
          base: null,
          asset: CinematicAdapterFixture.asset('draft'),
        ),
        throwsA(isA<CinematicFailure>()),
      );
      expect(await f.file('project.json').readAsBytes(), bytes);
    },
  );

  test('same asset conflict preserves disk and the caller draft', () async {
    final asset = CinematicAdapterFixture.asset('departure');
    final f = await CinematicAdapterFixture.create(cinematics: [asset]);
    addTearDown(f.dispose);
    final base = await f.adapter().load(asset.id);
    await f.writeManifest(
      (await f.readManifest()).copyWith(
        cinematics: [asset.copyWith(title: 'Externe')],
      ),
    );
    final bytes = await f.file('project.json').readAsBytes();
    final draft = asset.copyWith(notes: 'Brouillon');
    await expectLater(
      f.adapter().publish(id: asset.id, base: base, asset: draft),
      throwsA(isA<CinematicFailure>()),
    );
    expect(await f.file('project.json').readAsBytes(), bytes);
    expect(draft.notes, 'Brouillon');
  });

  test(
    'independent manifest edits and another cinematic survive targeted save',
    () async {
      final asset = CinematicAdapterFixture.asset('departure');
      final other = CinematicAdapterFixture.asset('other');
      final f = await CinematicAdapterFixture.create(
        cinematics: [asset, other],
      );
      addTearDown(f.dispose);
      final base = await f.adapter().load(asset.id);
      await f.writeManifest(
        (await f.readManifest()).copyWith(
          name: 'Projet renommé',
          cinematics: [
            asset,
            other.copyWith(notes: 'Indépendant'),
          ],
        ),
      );
      final saved = await f.adapter().publish(
        id: asset.id,
        base: base,
        asset: asset.copyWith(notes: 'Publié'),
      );
      expect(saved.resources.manifest.name, 'Projet renommé');
      expect(saved.resources.manifest.cinematics.last.notes, 'Indépendant');
    },
  );

  test(
    'classification conflict is detected before archive or delete',
    () async {
      final f = await CinematicAdapterFixture.create();
      addTearDown(f.dispose);
      final port = f.adapter();
      final created = await port.publish(
        id: 'departure',
        base: null,
        asset: CinematicAdapterFixture.asset('departure'),
      );
      await port.setArchived(base: created.snapshot!, archived: true);
      final bytes = await f.file('project.json').readAsBytes();
      await expectLater(
        port.delete(base: created.snapshot!),
        throwsA(isA<CinematicFailure>()),
      );
      expect(await f.file('project.json').readAsBytes(), bytes);
    },
  );

  test(
    'interrupted promotion recovers both document and classification',
    () async {
      final f = await CinematicAdapterFixture.create();
      addTearDown(f.dispose);
      var interrupted = false;
      final port = f.adapter(
        faultInjector: (context) {
          if (!interrupted &&
              context.checkpoint ==
                  AuthoringTransactionCheckpoint.afterResourcePromoted) {
            interrupted = true;
            throw const AuthoringTransactionSimulatedCrash();
          }
        },
      );
      final saved = await port.publish(
        id: 'departure',
        base: null,
        asset: CinematicAdapterFixture.asset('departure'),
      );
      expect(interrupted, isTrue);
      final fresh = await f.adapter().load('departure');
      expect(fresh.asset, saved.snapshot!.asset);
      expect(fresh.entry, saved.snapshot!.entry);
      expect(fresh.revision, saved.resources.revision);
    },
  );

  test(
    'homonymous identities load separately and mismatched publication refuses',
    () async {
      final a = CinematicAdapterFixture.asset('a');
      final b = CinematicAdapterFixture.asset('b');
      final f = await CinematicAdapterFixture.create(cinematics: [a, b]);
      addTearDown(f.dispose);
      expect((await f.adapter().load('b')).asset.id, 'b');
      await expectLater(
        f.adapter().publish(
          id: 'b',
          base: await f.adapter().load('a'),
          asset: b,
        ),
        throwsA(isA<CinematicFailure>()),
      );
      await expectLater(
        f.adapter().load('missing'),
        throwsA(isA<CinematicFailure>()),
      );
    },
  );
}
