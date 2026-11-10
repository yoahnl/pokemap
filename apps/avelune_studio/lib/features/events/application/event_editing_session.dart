import 'package:map_authoring/map_authoring.dart';

import 'event_workspace_controller.dart';
import 'event_map_loader.dart';
import '../domain/event_port.dart';

class EventDraftInputs {
  final invalidNumbers = <String, String>{};
}

class EventEditingSession {
  EventEditingSession(
    this.controller, {
    EventDraftInputs? inputs,
    required this.changed,
    this.flushFocus,
  }) : inputs = inputs ?? EventDraftInputs() {
    _pending = (controller.flushEdits?.call() ?? Future<void>.value())
        .catchError((Object failure) {
          error = controller.error = failure.toString();
        });
    controller.flushEdits = flush;
  }

  final EventWorkspaceController controller;
  final EventDraftInputs inputs;
  final void Function() changed;
  final void Function()? flushFocus;
  late Future<void> _pending;
  String? error;

  Future<void> get pending => _pending;

  Future<void> flush() async {
    flushFocus?.call();
    await _pending;
    inputs.invalidNumbers.removeWhere(
      (key, _) =>
          !controller.records.any((record) => key.startsWith('${record.id}:')),
    );
    if (inputs.invalidNumbers.isNotEmpty) {
      throw const EventFailure(
        'Corrigez la priorité ou l’ordre invalide dans Options avant d’enregistrer.',
      );
    }
    if (error case final problem?) throw EventFailure(problem);
  }

  Future<void> mutate(bool Function() action) => _pending = _pending.then((
    _,
  ) async {
    try {
      error = await controller.prepare() && action() ? null : controller.error;
    } catch (failure) {
      error = controller.error = failure.toString();
    }
    changed();
  });

  Future<void> commitNumber(
    String id,
    String field,
    String value,
    bool Function(int) apply,
  ) {
    final key = '$id:$field';
    final parsed = int.tryParse(value);
    if (parsed == null) {
      inputs.invalidNumbers[key] = value;
      return mutate(() {
        controller.error =
            'Saisissez un nombre entier pour la priorité et l’ordre.';
        return false;
      });
    }
    inputs.invalidNumbers.remove(key);
    return mutate(() => apply(parsed));
  }

  Future<void> restore({required bool redo}) async {
    flushFocus?.call();
    await _pending;
    controller.restore(redo: redo);
    error = null;
    changed();
  }

  Future<bool> reload(String id) async {
    flushFocus?.call();
    await _pending;
    final restored = await controller.reload(id);
    if (restored) {
      inputs.invalidNumbers.removeWhere((key, _) => key.startsWith('$id:'));
      error = null;
    }
    changed();
    return restored;
  }

  Future<bool> publishTemplate(
    StandardEventTemplateSpec spec, {
    EventMapLoader? mapLoader,
  }) async {
    if (!await controller.publishTemplate(spec)) {
      throw EventFailure(controller.error ?? 'Événement non enregistré.');
    }
    mapLoader?.invalidate(spec.mapId);
    return true;
  }
}
