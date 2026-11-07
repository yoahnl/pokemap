part of 'map_workspace_tool_strip.dart';

extension _MapWorkspaceToolStripActions on MapWorkspaceToolStrip {
  MapToolCommandRunner get _runner => MapToolCommandRunner(
    view: view,
    spatial: spatial,
    paletteVisible: paletteVisible,
    onChanged: onChanged,
    onMoreTools: onMoreTools,
    onResources: onResources,
  );

  void _select(String label) => _runner.runFamily(label);

  void _selectExtra(String label) => _runner.runExtra(label);
}
