import 'package:map_core/map_core_domain.dart';

import '../domain/map_dive_pair_port.dart';
import 'editable_map_document.dart';
import 'map_workspace_controller.dart';

class DivePairPublishingSession {
  DivePairPublishingSession({
    required this.controller,
    required this.port,
    this.changed,
  });

  final MapWorkspaceController controller;
  final MapDivePairPort? port;
  final void Function()? changed;
  String? targetMapId, targetZoneId, message;
  MapData? target;
  bool busy = false;
  int _epoch = 0;
  bool _disposed = false;

  void _notify() {
    if (!_disposed) changed?.call();
  }

  Future<void> selectMap(String id) async {
    if (_disposed) return;
    final epoch = ++_epoch;
    targetMapId = id;
    targetZoneId = null;
    target = null;
    message = null;
    _notify();
    try {
      final map =
          controller.documents[id]?.current ?? await controller.previewMap(id);
      if (!_disposed && epoch == _epoch) {
        target = map;
        _notify();
      }
    } on Object catch (error) {
      if (!_disposed && epoch == _epoch) {
        message = '$error';
        _notify();
      }
    }
  }

  Future<void> publish(EditableMapDocument source, MapGameplayZone zone) async {
    final link = zone.fieldAction!.dive!.link;
    final targetId = link?.mapId ?? targetMapId;
    final targetPointId = link?.zoneId ?? targetZoneId;
    if (_disposed ||
        port == null ||
        targetId == null ||
        targetPointId == null ||
        busy) {
      return;
    }
    if (source.dirty ||
        source.saving ||
        controller.documents[targetId]?.dirty == true ||
        controller.documents[targetId]?.saving == true) {
      message = 'Enregistrez les brouillons des deux cartes avant de publier leur liaison.';
      _notify();
      return;
    }
    busy = true;
    message = null;
    _notify();
    try {
      final destination =
          controller.documents[targetId]?.current ??
          (link == null ? target : null) ??
          await controller.previewMap(targetId);
      if (_disposed) return;
      if (destination == null) throw StateError('Carte opposée indisponible.');
      if (source.dirty || controller.documents[targetId]?.dirty == true) {
        throw StateError('Un brouillon a changé avant la publication.');
      }
      await port!.publishDivePair(
        session: controller.session,
        source: source.current,
        expectedTarget: destination,
        zoneId: zone.id,
        targetZoneId: targetPointId,
        unlink: link != null,
      );
      if (!controller.isDisposed) {
        await controller.refreshSavedMaps({source.current.id, targetId});
      }
      message = link == null
          ? 'Les deux points sont liés. Délier annule cette publication.'
          : 'Les deux points sont déliés et conservés en préparation.';
    } on Object catch (error) {
      message = '$error';
    } finally {
      busy = false;
      _notify();
    }
  }

  void dispose() {
    _disposed = true;
    _epoch++;
  }
}
