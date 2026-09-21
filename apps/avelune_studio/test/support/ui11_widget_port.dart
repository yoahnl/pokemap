import 'package:avelune_studio/features/presentations/domain/presentation_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';
import 'm2_ui_fixture.dart';

class Ui11WidgetPort implements PresentationPort {
  Ui11WidgetPort(this.delegate, this.tester);
  final PresentationPort delegate;
  final WidgetTester tester;
  bool interactive = false;
  int reads = 0, writes = 0;
  Future<T> _run<T>(Future<T> Function() action) async {
    if (!interactive) return action();
    final operation = tester.runAsync(() async {
      try {
        return (await action(), null);
      } catch (error) {
        return (null, error);
      }
    });
    WidgetResourcePort.pending = operation;
    try {
      final result = (await operation)!;
      if (result.$2 case final error?) throw error;
      return result.$1!;
    } finally {
      if (identical(WidgetResourcePort.pending, operation)) {
        WidgetResourcePort.pending = null;
      }
    }
  }

  @override
  Future<PresentationSourceSnapshot> load(String id) {
    reads++;
    return _run(() => delegate.load(id));
  }

  @override
  Future<PresentationDraftProjection> prepare(ProjectManifest project) =>
      _run(() => delegate.prepare(project));
  @override
  Future<PresentationPublicationReceipt> publish({
    required PresentationCinematicAsset asset,
    required PresentationSourceSnapshot? base,
    String? folderId,
    bool changeFolder = false,
    PresentationSceneLink? link,
    List<PresentationStagedMedia> imports = const [],
    List<Map<String, Object?>> mediaBaselines = const [],
  }) {
    writes++;
    return _run(
      () => delegate.publish(
        asset: asset,
        base: base,
        folderId: folderId,
        changeFolder: changeFolder,
        link: link,
        imports: imports,
        mediaBaselines: mediaBaselines,
      ),
    );
  }

  @override
  Future<PresentationPublicationReceipt> createFolder({
    required String id,
    required String name,
    String? parentFolderId,
  }) => _run(
    () => delegate.createFolder(
      id: id,
      name: name,
      parentFolderId: parentFolderId,
    ),
  );
  @override
  Future<PresentationPublicationReceipt> delete(
    PresentationSourceSnapshot base,
  ) => _run(() => delegate.delete(base));
  @override
  Future<PresentationPublicationReceipt> setArchived(
    PresentationSourceSnapshot base,
    bool archived,
  ) => _run(() => delegate.setArchived(base, archived));
  @override
  Future<PresentationStagedMedia> stageMedia({
    required String sourcePath,
    required String label,
    required ProjectMediaKind kind,
  }) => _run(
    () => delegate.stageMedia(sourcePath: sourcePath, label: label, kind: kind),
  );
  @override
  Future<void> releaseMedia(PresentationStagedMedia media) =>
      _run(() => delegate.releaseMedia(media));
}
