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

String mapToolHelp(StudioMapTool tool) => switch (tool) {
  StudioMapTool.select =>
    'Sélectionnez un décor ou un personnage pour retrouver ses propriétés ici.',
  StudioMapTool.pan =>
    'Faites glisser la carte pour explorer. Le zoom reste conservé.',
  StudioMapTool.place =>
    'Choisissez un décor dans la palette, puis cliquez sur la carte pour le placer.',
  StudioMapTool.paint => 'Choisissez une tuile, puis peignez sur la carte.',
  StudioMapTool.terrain =>
    'Peignez le terrain choisi : les raccords se calculent automatiquement.',
  StudioMapTool.character =>
    'Choisissez un personnage, puis cliquez sur sa case de départ.',
  StudioMapTool.warp =>
    'Choisissez la carte de destination, puis cliquez sur la case du passage.',
  StudioMapTool.spawn =>
    'Cliquez la case où le joueur apparaît au début du jeu.',
  StudioMapTool.sign => 'Cliquez la case du panneau, puis écrivez son texte.',
  StudioMapTool.zone =>
    'Tracez une zone sur la carte pour lui associer une interaction.',
  StudioMapTool.gameplayZone =>
    'Tracez une zone de jeu : rencontres, déplacement, effet ou danger.',
  StudioMapTool.encounterPaint =>
    'Cliquez ou glissez pour peindre les cases de rencontre.',
  StudioMapTool.encounterErase =>
    'Retirez les cases peintes de la zone de rencontres sélectionnée.',
  StudioMapTool.border =>
    'Cliquez pour poser des points et faire des angles. Terminez le tracé dans la barre au-dessus de la carte.',
  StudioMapTool.environment =>
    'Dessinez la zone au pinceau ou en rectangle. La gomme laisse des trous. Préparez l’aperçu, puis appliquez les décors.',
  StudioMapTool.erase =>
    'Effacez les tuiles et terrains sous le curseur. La gomme de décors se choisit dans les outils supplémentaires.',
  StudioMapTool.eraseDecor =>
    'Cliquez sur un décor pour effacer celui qui apparaît au premier plan.',
  StudioMapTool.collisionPaint =>
    'Cliquez ou glissez pour bloquer les cases. Le trait est annulable en une fois.',
  StudioMapTool.collisionErase =>
    'Cliquez ou glissez pour libérer les cases bloquées.',
};
