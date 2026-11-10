import 'dart:async';

import 'package:avelune_studio/features/narrative/application/periodic_reward_selection.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

final revision = 'sha256:${List.filled(64, '0').join()}';
AuthoringQueryPage page(List<Map<String, Object?>> items) => AuthoringQueryPage(
  snapshotRevision: revision,
  items: items,
  totalAvailable: items.length,
);
PeriodicRewardReference reference(String scene) => PeriodicRewardReference(
  sceneId: scene,
  nodeId: 'claim',
  rewardId: 'daily-$scene',
);
Map<String, Object?> scene(String id) => PeriodicRewardSceneChoice(
  sceneId: id,
  label: 'Scène $id',
  revision: revision,
).toJson();
Map<String, Object?> node(String id) => PeriodicRewardNodeChoice(
  nodeId: 'claim',
  label: 'Fruit $id',
  itemId: 'fruit',
  quantity: 2,
  reference: reference(id),
  revision: revision,
).toJson();
void main() {
  test('disposed selection cannot initiate another published query', () async {
    var reads = 0;
    final draft = PeriodicRewardSelection(
      changed: () {},
      read: (_) async {
        reads++;
        return page([scene('A')]);
      },
    );
    await draft.loadScenes();
    expect(reads, 1);
    draft.dispose();
    draft.selectScene('A');
    await draft.loadScenes();
    await draft.loadScenes(more: true);
    expect(reads, 1);
  });
  for (final lateGet in [false, true]) {
    test(
      'refresh invalidates removed published nodes and late get: $lateGet',
      () async {
        var removed = false, firstGet = true;
        final oldGet = Completer<AuthoringQueryPage>();
        final draft = PeriodicRewardSelection(
          initial: reference('A'),
          changed: () {},
          read: (request) async {
            if (lateGet &&
                request.operation == AuthoringQueryOperation.get &&
                firstGet) {
              firstGet = false;
              return oldGet.future;
            }
            if (removed) return page([]);
            return request.resourceKind == 'periodicRewardScene'
                ? page([scene(lateGet ? 'B' : 'A')])
                : page([node(lateGet ? 'B' : 'A')]);
          },
        );
        addTearDown(draft.dispose);
        final initial = draft.loadScenes();
        await Future<void>.delayed(Duration.zero);
        if (lateGet) {
          draft.selectScene('B');
          await Future<void>.delayed(Duration.zero);
          draft.selectNode('claim');
        } else {
          await initial;
        }
        expect(draft.applicable, reference(lateGet ? 'B' : 'A'));
        removed = true;
        await draft.loadScenes();
        expect(draft.scenes, isEmpty);
        expect(draft.nodes, isEmpty);
        expect(draft.applicable, isNull);
        if (lateGet) {
          oldGet.complete(page([scene('A')]));
          await initial;
          expect(draft.scenes, isEmpty);
          expect(draft.nodes, isEmpty);
        }
        expect(draft.unresolved, isTrue);
      },
    );
  }

  test('explicit selection repairs changed reward identity and retains negation/revision', () async {
    final requests = <AuthoringQueryRequest>[];
    final original = PeriodicRewardReference(
      sceneId: 'A',
      nodeId: 'claim',
      rewardId: 'previous',
    );
    final draft = PeriodicRewardSelection(
      initial: original,
      initialExpectedValue: false,
      changed: () {},
      read: (request) async {
        requests.add(request);
        return request.resourceKind == 'periodicRewardScene'
            ? page([scene('A')])
            : page([node('A')]);
      },
    );
    addTearDown(draft.dispose);
    await draft.loadScenes();
    expect(draft.applicable, isNull);
    expect(draft.unresolved, isTrue);
    expect(draft.initial, original);
    draft.selectNode('claim');
    expect(draft.applicable, reference('A'));
    expect(draft.expected, isFalse);
    expect(requests.last.filters, {'sceneId': 'A'});
    expect(requests.last.extensions, {'sourceRevision': revision});
  });

  test('late source cannot overwrite a newer explicit selection', () async {
    final slow = Completer<AuthoringQueryPage>();
    final draft = PeriodicRewardSelection(
      changed: () {},
      read: (request) async {
        if (request.resourceKind == 'periodicRewardScene') {
          return page([scene('A'), scene('B')]);
        }
        return request.filters['sceneId'] == 'A'
            ? slow.future
            : page([node('B')]);
      },
    );
    addTearDown(draft.dispose);
    await draft.loadScenes();
    draft.selectScene('A');
    draft.selectScene('B');
    await Future<void>.delayed(Duration.zero);
    slow.complete(page([node('A')]));
    await Future<void>.delayed(Duration.zero);
    expect(draft.nodes.single.reference, reference('B'));
    draft.selectNode('claim');
    expect(draft.applicable, reference('B'));
  });

  test('missing published source preserves its original reference and refuses apply', () async {
    final original = reference('missing');
    final draft = PeriodicRewardSelection(
      initial: original,
      changed: () {},
      read: (request) async {
        if (request.operation == AuthoringQueryOperation.get) {
          throw StateError('missing');
        }
        return page([]);
      },
    );
    addTearDown(draft.dispose);
    await draft.loadScenes();
    expect(draft.initial, original);
    expect(draft.applicable, isNull);
    expect(draft.unresolved, isTrue);
    expect(draft.error, isNotNull);
  });

  test(
    'pagination keeps exact cursors and disposal rejects pending data',
    () async {
      final requests = <AuthoringQueryRequest>[];
      final late = Completer<AuthoringQueryPage>();
      final draft = PeriodicRewardSelection(
        changed: () {},
        read: (request) async {
          requests.add(request);
          if (request.cursor == 'next') return late.future;
          return AuthoringQueryPage(
            snapshotRevision: revision,
            items: [scene('A')],
            totalAvailable: 2,
            nextCursor: 'next',
          );
        },
      );
      await draft.loadScenes();
      expect(draft.scenes.single.sceneId, 'A');
      final pending = draft.loadScenes(more: true);
      expect(requests.last.cursor, 'next');
      draft.dispose();
      late.complete(page([scene('B')]));
      await pending;
      expect(draft.scenes.map((scene) => scene.sceneId), ['A']);
    },
  );
}
