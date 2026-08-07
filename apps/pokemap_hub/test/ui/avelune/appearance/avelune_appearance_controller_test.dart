import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pokemap_hub/pokemap_hub_ui.dart';

import '../../../support/appearance_notifier_harness.dart';

void main() {
  late Directory supportRoot;

  setUp(() async {
    supportRoot = await Directory.systemTemp.createTemp('avelune-controller-');
  });

  tearDown(() async {
    if (await supportRoot.exists()) {
      await supportRoot.delete(recursive: true);
    }
  });

  test('initialization exposes ready defaults for a new installation',
      () async {
    final controllerHarness = buildAppearanceHarness(
      store: AveluneAppearanceStore(supportRoot: supportRoot),
      customBackground: _CustomBackgroundGateway(),
    );
    addTearDown(controllerHarness.dispose);

    await controllerHarness.notifier.initialize();

    expect(controllerHarness.state.status, AveluneAppearanceControllerStatus.ready);
    expect(controllerHarness.state.preferences, const AveluneAppearancePreferences());
    expect(controllerHarness.state.message, isNull);
  });

  test('background and furniture choices survive a controller restart',
      () async {
    final store = AveluneAppearanceStore(supportRoot: supportRoot);
    final firstHarness = buildAppearanceHarness(
      store: store,
      customBackground: _CustomBackgroundGateway(),
    );
    await firstHarness.notifier.initialize();
    await firstHarness.notifier.selectBackground('violet');
    await firstHarness.notifier.selectFurniture('ivory');
    firstHarness.dispose();

    final restartedHarness = buildAppearanceHarness(
      store: AveluneAppearanceStore(supportRoot: supportRoot),
      customBackground: _CustomBackgroundGateway(),
    );
    addTearDown(restartedHarness.dispose);
    await restartedHarness.notifier.initialize();

    expect(
      restartedHarness.state.preferences,
      const AveluneAppearancePreferences(
        backgroundId: 'violet',
        furnitureId: 'ivory',
      ),
    );
  });

  test('missing custom file falls back to amber with non-blocking message',
      () async {
    final store = AveluneAppearanceStore(supportRoot: supportRoot);
    await store.save(
      const AveluneAppearancePreferences(
        backgroundId: 'custom',
        furnitureId: 'mahogany',
      ),
    );
    final controllerHarness = buildAppearanceHarness(
      store: store,
      customBackground: _CustomBackgroundGateway(valid: false),
    );
    addTearDown(controllerHarness.dispose);

    await controllerHarness.notifier.initialize();

    expect(controllerHarness.state.status, AveluneAppearanceControllerStatus.ready);
    expect(controllerHarness.state.preferences.backgroundId, 'amber');
    expect(controllerHarness.state.preferences.furnitureId, 'mahogany');
    expect(controllerHarness.state.message, contains('introuvable'));
    expect((await store.load()).preferences.backgroundId, 'amber');
  });

  test('successful import stores custom without persisting an absolute path',
      () async {
    final gateway = _CustomBackgroundGateway(valid: true);
    final store = AveluneAppearanceStore(supportRoot: supportRoot);
    final controllerHarness = buildAppearanceHarness(
      store: store,
      customBackground: gateway,
    );
    addTearDown(controllerHarness.dispose);
    await controllerHarness.notifier.initialize();
    final statuses = controllerHarness.observeStatuses();

    final imported = await controllerHarness.notifier.importCustomBackground();

    expect(imported, isTrue);
    expect(statuses, contains(AveluneAppearanceControllerStatus.saving));
    expect(controllerHarness.state.status, AveluneAppearanceControllerStatus.ready);
    expect(controllerHarness.state.preferences.backgroundId, 'custom');
    expect(controllerHarness.state.customBackgroundPath, gateway.imagePath);
    expect((await store.load()).preferences.toJson().values,
        isNot(contains(gateway.imagePath)));
  });

  test('cancelled import restores ready state without changing preferences',
      () async {
    final gateway = _CustomBackgroundGateway(
      outcome: AveluneCustomBackgroundImportOutcome.cancelled,
    );
    final controllerHarness = buildAppearanceHarness(
      store: AveluneAppearanceStore(supportRoot: supportRoot),
      customBackground: gateway,
    );
    addTearDown(controllerHarness.dispose);
    await controllerHarness.notifier.initialize();

    final imported = await controllerHarness.notifier.importCustomBackground();

    expect(imported, isFalse);
    expect(controllerHarness.state.status, AveluneAppearanceControllerStatus.ready);
    expect(controllerHarness.state.preferences, const AveluneAppearancePreferences());
  });

  test('cancelled replacement keeps an existing custom image active', () async {
    final store = AveluneAppearanceStore(supportRoot: supportRoot);
    await store.save(
      const AveluneAppearancePreferences(backgroundId: 'custom'),
    );
    final gateway = _CustomBackgroundGateway(
      valid: true,
      outcome: AveluneCustomBackgroundImportOutcome.cancelled,
    );
    final controllerHarness = buildAppearanceHarness(
      store: store,
      customBackground: gateway,
    );
    addTearDown(controllerHarness.dispose);
    await controllerHarness.notifier.initialize();

    await controllerHarness.notifier.importCustomBackground();

    expect(controllerHarness.state.preferences.backgroundId, 'custom');
    expect(controllerHarness.state.customBackgroundPath, gateway.imagePath);
  });

  test('preference write failure restores prior choice and exposes error',
      () async {
    final store = AveluneAppearanceStore(
      supportRoot: supportRoot,
      writeDocument: (_, __) async => throw const FileSystemException(
        'simulated write failure',
      ),
    );
    final controllerHarness = buildAppearanceHarness(
      store: store,
      customBackground: _CustomBackgroundGateway(),
    );
    addTearDown(controllerHarness.dispose);
    await controllerHarness.notifier.initialize();

    final saved = await controllerHarness.notifier.selectFurniture('ivory');

    expect(saved, isFalse);
    expect(controllerHarness.state.status, AveluneAppearanceControllerStatus.error);
    expect(controllerHarness.state.preferences, const AveluneAppearancePreferences());
    expect(controllerHarness.state.message, isNotEmpty);
  });

  test('deleting custom image returns to amber', () async {
    final gateway = _CustomBackgroundGateway(valid: true);
    final store = AveluneAppearanceStore(supportRoot: supportRoot);
    await store.save(
      const AveluneAppearancePreferences(backgroundId: 'custom'),
    );
    final controllerHarness = buildAppearanceHarness(
      store: store,
      customBackground: gateway,
    );
    addTearDown(controllerHarness.dispose);
    await controllerHarness.notifier.initialize();

    final removed = await controllerHarness.notifier.removeCustomBackground();

    expect(removed, isTrue);
    expect(gateway.deletes, 1);
    expect(controllerHarness.state.preferences.backgroundId, 'amber');
    expect(controllerHarness.state.customBackgroundPath, isNull);
  });

  test('delete failure keeps the persisted amber fallback coherent', () async {
    final gateway = _CustomBackgroundGateway(valid: true, failDelete: true);
    final store = AveluneAppearanceStore(supportRoot: supportRoot);
    await store.save(
      const AveluneAppearancePreferences(backgroundId: 'custom'),
    );
    final controllerHarness = buildAppearanceHarness(
      store: store,
      customBackground: gateway,
    );
    addTearDown(controllerHarness.dispose);
    await controllerHarness.notifier.initialize();

    final removed = await controllerHarness.notifier.removeCustomBackground();

    expect(removed, isFalse);
    expect((await store.load()).preferences.backgroundId, 'amber');
    expect(controllerHarness.state.preferences.backgroundId, 'amber');
    expect(controllerHarness.state.customBackgroundPath, isNull);
  });
}

final class _CustomBackgroundGateway implements AveluneCustomBackgroundGateway {
  _CustomBackgroundGateway({
    this.valid = false,
    this.failDelete = false,
    this.outcome = AveluneCustomBackgroundImportOutcome.imported,
  });

  bool valid;
  final bool failDelete;
  final AveluneCustomBackgroundImportOutcome outcome;
  int deletes = 0;

  @override
  String get imagePath => '/support/avelune/appearance/custom-background.jpg';

  @override
  String get thumbnailPath =>
      '/support/avelune/appearance/custom-background.thumbnail.jpg';

  @override
  Future<void> delete() async {
    deletes++;
    if (failDelete) throw const FileSystemException('simulated delete failure');
    valid = false;
  }

  @override
  Future<bool> isCurrentValid() async => valid;

  @override
  Future<AveluneCustomBackgroundImportOutcome> pickAndImport() async {
    if (outcome == AveluneCustomBackgroundImportOutcome.imported) valid = true;
    return outcome;
  }
}
