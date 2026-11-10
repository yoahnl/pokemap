import 'package:map_core/map_core_domain.dart';

import 'terrain_draft_controller.dart';

enum TerrainScratchTool { inspect, paint, erase }

class TerrainScratchEditingSession {
  TerrainScratchEditingSession(this.controller);

  final TerrainDraftController Function() controller;
  GridPos? _previous;

  void begin(GridPos point, TerrainScratchTool tool) {
    end();
    update(point, tool);
  }

  void cell(GridPos point, TerrainScratchTool tool) {
    begin(point, tool);
    end();
  }

  void update(GridPos point, TerrainScratchTool tool) {
    final owner = controller();
    if (tool == TerrainScratchTool.inspect) {
      owner.inspect(point);
    } else {
      owner.paintLine(
        _previous ?? point,
        point,
        erase: tool == TerrainScratchTool.erase,
      );
    }
    _previous = point;
  }

  void end() => _previous = null;
}
