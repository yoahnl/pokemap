import 'package:avelune_studio/features/verification/application/verification_workspace_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/m2_ui_fixture.dart';
import 'support/ui13_controllable_verification_port.dart';
import 'support/ui13_host_harness.dart';
import 'support/ui13_verification_harness.dart';

void main() {
  testWidgets('saving from an editor during a control frees the page', (
    tester,
  ) async {
    final executor = Ui13ControllableVerificationPort(
      revision: 'fixture',
      maps: const [],
      evidence: const VerificationRuntimeEvidence(
        state: VerificationRuntimeState.absent,
        reason: 'Aucune preuve enregistrée.',
      ),
    );
    final harness = await host(
      tester,
      launch: false,
      wrap: (delegate) => Ui13HostAnalysisPort(delegate, executor),
    );
    final controller = opened(tester);
    await activate(tester, find.text('Lancer la vérification').first);
    for (var i = 0; i < 30 && executor.analyses == 0; i++) {
      await pumpIo(tester, frames: 3);
    }
    expect(executor.analyses, 1);
    expect(controller.running, isTrue);

    final scenes = controller.scenes!.call()!;
    expect(scenes.open(Ui13VerificationHarness.sceneId), isTrue);
    expect(scenes.active!.rename('Quai enregistré depuis l’hôte'), isTrue);
    final saved = await WidgetResourcePort.serial(tester, scenes.save);
    expect(saved, isTrue, reason: scenes.error ?? '');

    executor.complete(0, project: harness.narrative.project, maps: const []);
    await pumpIo(tester, frames: 12);
    expect(
      controller.running,
      isFalse,
      reason: 'the host never stays busy after a save',
    );
    expect(controller.report, isNotNull, reason: controller.error);
    expect(controller.stale, isTrue);

    await activate(tester, find.text('Lancer la vérification').first);
    for (var i = 0; i < 30 && executor.analyses < 2; i++) {
      await pumpIo(tester, frames: 3);
    }
    expect(
      executor.analyses,
      2,
      reason: 'a second control starts without clicking Abandonner',
    );
    executor.complete(1, project: harness.narrative.project, maps: const []);
    await pumpIo(tester, frames: 12);
    expect(controller.stale, isFalse);
    expect(tester.takeException(), isNull);
  });
}
