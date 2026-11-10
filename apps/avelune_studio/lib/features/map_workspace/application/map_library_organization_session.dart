import 'package:map_core/map_core_domain.dart';

import 'map_library_commands.dart';

class MapLibraryOrganizationSession {
  MapLibraryOrganizationSession({required this.action, required this.changed});
  final OrganizeMapLibrary? Function() action;
  final void Function() changed;
  bool busy = false;
  String? error;
  bool _disposed = false;

  Future<String?> submit({
    List<ProjectMapGroup>? groups,
    required List<Map<String, Object?>> assignments,
  }) async {
    if (_disposed || busy) return 'L’organisation est indisponible.';
    final publish = action();
    if (publish == null) return 'L’organisation est indisponible.';
    busy = true;
    error = null;
    changed();
    String? result;
    try {
      result = await publish(groups: groups, assignments: assignments);
    } on Object catch (failure) {
      result = 'Organisation impossible : $failure';
    }
    busy = false;
    if (_disposed) return result ?? 'Le navigateur a été fermé.';
    error = result;
    changed();
    return result;
  }

  void dispose() {
    _disposed = true;
  }
}
