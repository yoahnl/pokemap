import 'package:avelune_studio/features/events/application/event_workspace_controller.dart';
import 'package:avelune_studio/features/events/domain/event_record_view.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../support/event_backend_fixture.dart';

void main() {
  test('parallel draft cadence survives rename save and cold reopen', () async {
    final fixture = await EventBackendFixture.create();
    addTearDown(fixture.dispose);
    final controller = fixture.attach();
    expect(await controller.prepare(), isTrue);
    final draft = controller.create(
      'Parallel draft',
      source: NarrativeEventSourceRef.mapEnter(
        controller.project.maps.first.id,
      ),
    )!;
    expect(
      controller.setReuse(draft.id, NarrativeEventReusePolicy.reusable),
      isTrue,
    );
    expect(
      controller.setParallel(
        draft.id,
        NarrativeEventParallelPolicy(cadenceMs: 350),
      ),
      isTrue,
      reason: controller.error,
    );
    expect(controller.rename(draft.id, 'Parallel renamed'), isTrue);
    expect(controller.record(draft.id)!.parallelPolicy!.cadenceMs, 350);
    expect(await controller.save(), isTrue, reason: controller.error);
    final fresh = await fixture.readFresh();
    expect(
      fresh.eventRegistry!.records
          .singleWhere((record) => record.id == draft.id)
          .parallelPolicy!
          .cadenceMs,
      350,
    );
  });
}
