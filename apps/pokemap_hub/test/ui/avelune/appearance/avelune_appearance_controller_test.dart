import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pokemap_hub/pokemap_hub_ui.dart';

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
    final controller = AveluneAppearanceController(
      store: AveluneAppearanceStore(supportRoot: supportRoot),
      customBackground: _CustomBackgroundGateway(),
    );
    addTearDown(controller.dispose);

    await controller.initialize();

    expect(controller.state.status, AveluneAppearanceControllerStatus.ready);
    expect(controller.state.preferences, const AveluneAppearancePreferences());
    expect(controller.state.message, isNull);
  });

  test('background and furniture choices survive a controller restart',
      () async {
    final store = AveluneAppearanceStore(supportRoot: supportRoot);
    final first = AveluneAppearanceController(
      store: store,
      customBackground: _CustomBackgroundGateway(),
    );
    await first.initialize();
    await first.selectBackground('violet');
    await first.selectFurniture('ivory');
    first.dispose();

    final restarted = AveluneAppearanceController(
      store: AveluneAppearanceStore(supportRoot: supportRoot),
      customBackground: _CustomBackgroundGateway(),
    );
    addTearDown(restarted.dispose);
    await restarted.initialize();

    expect(
      restarted.state.preferences,
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
    final controller = AveluneAppearanceController(
      store: store,
      customBackground: _CustomBackgroundGateway(valid: false),
    );
    addTearDown(controller.dispose);

    await controller.initialize();

    expect(controller.state.status, AveluneAppearanceControllerStatus.ready);
    expect(controller.state.preferences.backgroundId, 'amber');
    expect(controller.state.preferences.furnitureId, 'mahogany');
    expect(controller.state.message, contains('introuvable'));
    expect((await store.load()).preferences.backgroundId, 'amber');
  });

  test('successful import stores custom without persisting an absolute path',
      () async {
    final gateway = _CustomBackgroundGateway(valid: true);
    final store = AveluneAppearanceStore(supportRoot: supportRoot);
    final controller = AveluneAppearanceController(
      store: store,
      customBackground: gateway,
    );
    addTearDown(controller.dispose);
    await controller.initialize();
    final statuses = <AveluneAppearanceControllerStatus>[];
    controller.addListener(() => statuses.add(controller.state.status));

    final imported = await controller.importCustomBackground();

    expect(imported, isTrue);
    expect(statuses, contains(AveluneAppearanceControllerStatus.saving));
    expect(controller.state.status, AveluneAppearanceControllerStatus.ready);
    expect(controller.state.preferences.backgroundId, 'custom');
    expect(controller.state.customBackgroundPath, gateway.imagePath);
    expect((await store.load()).preferences.toJson().values,
        isNot(contains(gateway.imagePath)));
  });

  test('cancelled import restores ready state without changing preferences',
      () async {
    final gateway = _CustomBackgroundGateway(
      outcome: AveluneCustomBackgroundImportOutcome.cancelled,
    );
    final controller = AveluneAppearanceController(
      store: AveluneAppearanceStore(supportRoot: supportRoot),
      customBackground: gateway,
    );
    addTearDown(controller.dispose);
    await controller.initialize();

    final imported = await controller.importCustomBackground();

    expect(imported, isFalse);
    expect(controller.state.status, AveluneAppearanceControllerStatus.ready);
    expect(controller.state.preferences, const AveluneAppearancePreferences());
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
    final controller = AveluneAppearanceController(
      store: store,
      customBackground: gateway,
    );
    addTearDown(controller.dispose);
    await controller.initialize();

    await controller.importCustomBackground();

    expect(controller.state.preferences.backgroundId, 'custom');
    expect(controller.state.customBackgroundPath, gateway.imagePath);
  });

  test('preference write failure restores prior choice and exposes error',
      () async {
    final store = AveluneAppearanceStore(
      supportRoot: supportRoot,
      writeDocument: (_, __) async => throw const FileSystemException(
        'simulated write failure',
      ),
    );
    final controller = AveluneAppearanceController(
      store: store,
      customBackground: _CustomBackgroundGateway(),
    );
    addTearDown(controller.dispose);
    await controller.initialize();

    final saved = await controller.selectFurniture('ivory');

    expect(saved, isFalse);
    expect(controller.state.status, AveluneAppearanceControllerStatus.error);
    expect(controller.state.preferences, const AveluneAppearancePreferences());
    expect(controller.state.message, isNotEmpty);
  });

  test('deleting custom image returns to amber', () async {
    final gateway = _CustomBackgroundGateway(valid: true);
    final store = AveluneAppearanceStore(supportRoot: supportRoot);
    await store.save(
      const AveluneAppearancePreferences(backgroundId: 'custom'),
    );
    final controller = AveluneAppearanceController(
      store: store,
      customBackground: gateway,
    );
    addTearDown(controller.dispose);
    await controller.initialize();

    final removed = await controller.removeCustomBackground();

    expect(removed, isTrue);
    expect(gateway.deletes, 1);
    expect(controller.state.preferences.backgroundId, 'amber');
    expect(controller.state.customBackgroundPath, isNull);
  });

  test('delete failure keeps the persisted amber fallback coherent', () async {
    final gateway = _CustomBackgroundGateway(valid: true, failDelete: true);
    final store = AveluneAppearanceStore(supportRoot: supportRoot);
    await store.save(
      const AveluneAppearancePreferences(backgroundId: 'custom'),
    );
    final controller = AveluneAppearanceController(
      store: store,
      customBackground: gateway,
    );
    addTearDown(controller.dispose);
    await controller.initialize();

    final removed = await controller.removeCustomBackground();

    expect(removed, isFalse);
    expect((await store.load()).preferences.backgroundId, 'amber');
    expect(controller.state.preferences.backgroundId, 'amber');
    expect(controller.state.customBackgroundPath, isNull);
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
