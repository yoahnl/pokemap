import '../../../features/map_workspace/application/map_tool_command_runner.dart'
    as commands;
import 'map_workspace_view_state.dart';

final class MapToolCommandRunner extends commands.MapToolCommandRunner {
  MapToolCommandRunner({
    required MapWorkspaceViewState view,
    required super.spatial,
    required super.paletteVisible,
    required super.onChanged,
    required super.onMoreTools,
    required super.onResources,
  }) : super(
         view: view,
         paletteTab: () => view.paletteTab,
         selectPalette: (value) => view.paletteTab = value,
       );
}
