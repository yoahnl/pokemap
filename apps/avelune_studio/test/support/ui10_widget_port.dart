import 'package:avelune_studio/features/cinematics/domain/cinematic_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';
import 'm2_ui_fixture.dart';

class Ui10WidgetPort implements CinematicPort {
  Ui10WidgetPort(this.delegate, this.tester);
  final CinematicPort delegate;
  final WidgetTester tester;
  int reads = 0;
  int writes = 0;
  Future<T> _run<T>(Future<T> Function() action) async {
    final operation = tester.runAsync(() async {
      try {
        final value = await action();
        return (value, null);
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
  Future<CinematicSourceSnapshot> load(String id) {
    reads++;
    return _run(() => delegate.load(id));
  }

  @override
  Future<CinematicPublicationReceipt> publish({
    required String id,
    required CinematicSourceSnapshot? base,
    required CinematicAsset asset,
    String? folderId,
  }) {
    writes++;
    return _run(
      () => delegate.publish(
        id: id,
        base: base,
        asset: asset,
        folderId: folderId,
      ),
    );
  }

  @override
  Future<CinematicPublicationReceipt> delete({
    required CinematicSourceSnapshot base,
  }) => _run(() => delegate.delete(base: base));
  @override
  Future<CinematicPublicationReceipt> setArchived({
    required CinematicSourceSnapshot base,
    required bool archived,
  }) => _run(() => delegate.setArchived(base: base, archived: archived));
}
