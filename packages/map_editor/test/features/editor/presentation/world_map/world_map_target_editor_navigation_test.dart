import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/features/editor/presentation/world_map/world_map_target_editor_navigation.dart';

void main() {
  test('keeps the latest stable-key request until its exact revision is acked',
      () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(
      worldMapTargetEditorNavigationProvider.notifier,
    );

    final first = controller.enqueue('legacy:map:first');
    final second = controller.enqueue('legacy:map:second');

    expect(second.revision, first.revision + 1);
    expect(
      container.read(worldMapTargetEditorNavigationProvider).pending,
      second,
    );
    expect(controller.acknowledge(first.revision), isFalse);
    expect(
      container.read(worldMapTargetEditorNavigationProvider).pending,
      second,
    );
    expect(controller.acknowledge(second.revision), isTrue);
    expect(
      container.read(worldMapTargetEditorNavigationProvider).pending,
      isNull,
    );
    expect(controller.acknowledge(second.revision), isFalse);
  });

  test('a stale consumer cannot acknowledge a replacement request', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(
      worldMapTargetEditorNavigationProvider.notifier,
    );
    final stale = controller.enqueue('legacy:map:stale');
    final current = controller.enqueue('legacy:map:current');

    expect(
      controller.acknowledgeIfCurrent(
        revision: stale.revision,
        stableKey: stale.stableKey,
      ),
      isFalse,
    );
    expect(
      controller.acknowledgeIfCurrent(
        revision: current.revision,
        stableKey: 'legacy:map:different',
      ),
      isFalse,
    );
    expect(
      container.read(worldMapTargetEditorNavigationProvider).pending,
      current,
    );
  });
}
