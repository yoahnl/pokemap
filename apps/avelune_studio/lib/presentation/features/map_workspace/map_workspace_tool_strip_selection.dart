import 'package:flutter/material.dart';

import 'map_workspace_view_state.dart';

(String, IconData)? mapExtraToolSelection(StudioMapTool tool) => switch (tool) {
  StudioMapTool.pan => ('Déplacer la vue', Icons.pan_tool_outlined),
  StudioMapTool.paint => ('Peindre', Icons.brush_outlined),
  StudioMapTool.erase => ('Gomme de tuiles', Icons.auto_fix_normal),
  StudioMapTool.eraseDecor => ('Gomme de décors', Icons.delete_outline),
  StudioMapTool.character => ('Placer un personnage', Icons.person_add_alt),
  StudioMapTool.spawn => ('Placer le départ du joueur', Icons.flag_outlined),
  StudioMapTool.sign => ('Placer un panneau', Icons.signpost_outlined),
  _ => null,
};
