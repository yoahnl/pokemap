part of 'map_workspace_screen.dart';

extension _WorkspaceResourceUsageBinding on _MapWorkspaceScreenState {
  List<String> _resourceUsageDraftOwners() => _sessions.resourceUsageDraftOwners;

  Future<bool> _openDiagnosticOwner(String kind, String id) =>
      _navigation.openResourceDiagnosticOwner(
        kind,
        id,
        openWorkshop: (prepare) => _openResourceWorkshop(prepare),
      );

  bool _canOpenResourceUsage(ResourceUsageEntry entry) =>
      _navigation.canOpenResourceUsage(entry);

  Future<bool> _openResourceUsage(ResourceUsageEntry entry) =>
      _navigation.openResourceUsage(entry);
}
