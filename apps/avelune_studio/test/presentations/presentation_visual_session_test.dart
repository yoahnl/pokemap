import 'dart:async';

import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/coordination/workspace_session_controllers.dart';
import 'package:avelune_studio/features/presentations/application/presentation_edit_session.dart';
import 'package:avelune_studio/features/presentations/coordination/presentation_visual_session.dart';
import 'package:avelune_studio/features/presentations/domain/presentation_port.dart';
import 'package:avelune_studio/platform/rendering/contracts/presentation_workspace_visuals.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';

void main() {
  test('unchanged source reuses one visual while revision, catalog and imports replace it', () async {
    final lifecycle = PresentationVisualSession();
    final factory = _Factory();
    final catalog = ProjectMediaCatalog();
    final initial = _session(catalog: catalog);
    final first = lifecycle.synchronize(
      factory: factory,
      activeId: 'intro',
      session: initial,
    );
    expect(
      lifecycle.synchronize(
        factory: factory,
        activeId: 'intro',
        session: initial,
      ),
      same(first),
    );
    expect(factory.requests, hasLength(1));
    expect(factory.requests.single.revision, 'draft');
    expect(factory.requests.single.catalog, same(catalog));
    final revised = _session(catalog: catalog, revision: 'r2');
    lifecycle.synchronize(
      factory: factory,
      activeId: 'intro',
      session: revised,
    );
    expect(factory.visuals.first.closes, 1);
    expect(factory.requests.last.revision, 'r2');
    final media = ProjectMediaAsset(
      id: 'picture',
      label: 'Image',
      kind: ProjectMediaKind.image,
      sourceAssetId: 'image',
    );
    final imported = PresentationStagedMedia(
      media: media,
      parameters: {},
      previewBytes: const [1, 2],
    );
    lifecycle.synchronize(
      factory: factory,
      activeId: 'intro',
      session: _session(catalog: catalog, revision: 'r2', imports: [imported]),
    );
    expect(factory.visuals[1].closes, 1);
    expect(factory.requests.last.imports.single, same(imported));
    final changedCatalog = ProjectMediaCatalog(entries: [media]);
    lifecycle.synchronize(
      factory: factory,
      activeId: 'intro',
      session: _session(
        catalog: changedCatalog,
        revision: 'r2',
        imports: [imported],
      ),
    );
    expect(factory.visuals[2].closes, 1);
    lifecycle.synchronize(
      factory: factory,
      activeId: 'another',
      session: _session(
        catalog: changedCatalog,
        revision: 'r2',
        imports: [imported],
      ),
    );
    expect(factory.visuals[3].closes, 1);
    await lifecycle.close();
    await lifecycle.close();
    expect(factory.visuals.map((visual) => visual.closes), everyElement(1));
    expect(lifecycle.current, isNull);
    expect(
      lifecycle.synchronize(
        factory: factory,
        activeId: 'late',
        session: initial,
      ),
      isNull,
    );
    expect(factory.visuals, hasLength(5));
  });

  test(
    'session shutdown awaits replaced visuals as well as the current visual',
    () async {
      final controller = MapWorkspaceController(
        workspaceSession,
        WorkspaceMemoryPort(),
      );
      await controller.initialize();
      final owners = WorkspaceSessionControllers(
        controller: controller,
        changed: () {},
        visualCatalogChanged: (_) {},
        flushEditors: () async => true,
      );
      final lifecycle = owners.presentationPreview;
      final factory = _Factory();
      final firstGate = Completer<void>();
      lifecycle.synchronize(factory: factory, activeId: 'first', session: null);
      factory.visuals.single.releaseGate = firstGate;
      lifecycle.synchronize(
        factory: factory,
        activeId: 'second',
        session: null,
      );
      var closed = false;
      final closing = owners.dispose().then((_) => closed = true);
      await Future<void>.delayed(Duration.zero);
      expect(closed, isFalse);
      expect(factory.visuals.map((visual) => visual.closes), everyElement(1));
      firstGate.complete();
      await closing;
      await owners.dispose();
      expect(closed, isTrue);
      expect(factory.visuals.map((visual) => visual.closes), everyElement(1));
      controller.dispose();
    },
  );
  test('completed release errors survive until shutdown while every current release is awaited', () async {
    final lifecycle = PresentationVisualSession();
    final factory = _Factory();
    final failure = StateError('Ancien visual impossible à fermer');
    lifecycle.synchronize(factory: factory, activeId: 'first', session: null);
    factory.visuals.first.releaseError = failure;
    lifecycle.synchronize(factory: factory, activeId: 'second', session: null);
    await Future<void>.delayed(Duration.zero);
    final gate = Completer<void>();
    factory.visuals.last.releaseGate = gate;
    var completed = false;
    final closing = lifecycle.close();
    final observed = expectLater(
      closing,
      throwsA(same(failure)),
    ).then((_) => completed = true);
    await Future<void>.delayed(Duration.zero);
    expect(completed, isFalse);
    expect(factory.visuals.map((visual) => visual.closes), everyElement(1));
    gate.complete();
    await observed;
    expect(completed, isTrue);
    expect(lifecycle.close(), same(closing));
    expect(factory.visuals.map((visual) => visual.closes), everyElement(1));
  });

  test('a synchronously throwing release does not interrupt the replacement and remains visible at shutdown', () async {
    final lifecycle = PresentationVisualSession();
    final factory = _Factory();
    final failure = StateError('Fermeture synchrone refusée');
    lifecycle.synchronize(factory: factory, activeId: 'first', session: null);
    factory.visuals.first
      ..releaseError = failure
      ..synchronousError = true;
    final replacement = lifecycle.synchronize(
      factory: factory,
      activeId: 'second',
      session: null,
    );
    expect(replacement, same(factory.visuals.last));
    expect(lifecycle.current, same(replacement));
    await expectLater(lifecycle.close(), throwsA(same(failure)));
    expect(factory.visuals.map((visual) => visual.closes), everyElement(1));
  });
}

PresentationEditSession _session({
  required ProjectMediaCatalog catalog,
  String? revision,
  List<PresentationStagedMedia> imports = const [],
}) {
  final asset = PresentationCinematicAsset(
    id: 'intro',
    title: 'Introduction',
    durationUs: 1000000,
  );
  return PresentationEditSession(
    asset: asset,
    dirty: false,
    revision: 0,
    mediaCatalog: catalog,
    imports: imports,
    base: revision == null
        ? null
        : PresentationSourceSnapshot(
            asset: asset,
            revision: revision,
            projection: _Projection(),
          ),
  );
}

class _Projection extends Fake implements PresentationDraftProjection {}

class _Factory implements PresentationMediaWorkspaceVisuals {
  final requests =
      <
        ({
          String revision,
          ProjectMediaCatalog catalog,
          List<PresentationStagedMedia> imports,
        })
      >[];
  final visuals = <_Visuals>[];
  @override
  PresentationWorkspaceVisuals createPresentationVisuals({
    required String revision,
    required ProjectMediaCatalog catalog,
    List<PresentationStagedMedia> imports = const [],
  }) {
    requests.add((revision: revision, catalog: catalog, imports: imports));
    final visual = _Visuals();
    visuals.add(visual);
    return visual;
  }
}

class _Visuals extends Fake implements PresentationWorkspaceVisuals {
  var closes = 0;
  Completer<void>? releaseGate;
  Object? releaseError;
  bool synchronousError = false;
  @override
  Future<void> close() {
    closes++;
    if (synchronousError && releaseError != null) throw releaseError!;
    return () async {
      await releaseGate?.future;
      if (releaseError != null) throw releaseError!;
    }();
  }
}
