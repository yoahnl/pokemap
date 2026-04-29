import 'package:flutter/cupertino.dart';

enum SurfaceStudioWizardStep {
  importAtlas,
  slice,
  map,
  preview,
  save,
}

extension SurfaceStudioWizardStepInfo on SurfaceStudioWizardStep {
  int get number => index + 1;

  String get id => switch (this) {
        SurfaceStudioWizardStep.importAtlas => 'import',
        SurfaceStudioWizardStep.slice => 'slice',
        SurfaceStudioWizardStep.map => 'mapper',
        SurfaceStudioWizardStep.preview => 'preview',
        SurfaceStudioWizardStep.save => 'save',
      };

  String get label => switch (this) {
        SurfaceStudioWizardStep.importAtlas => 'Importer',
        SurfaceStudioWizardStep.slice => 'Découper',
        SurfaceStudioWizardStep.map => 'Mapper',
        SurfaceStudioWizardStep.preview => 'Prévisualiser',
        SurfaceStudioWizardStep.save => 'Enregistrer',
      };

  String get sidebarDescription => switch (this) {
        SurfaceStudioWizardStep.importAtlas =>
          'Importez votre atlas de surface animé.',
        SurfaceStudioWizardStep.slice =>
          'Définissez la taille des tuiles et découpez l’atlas en colonnes.',
        SurfaceStudioWizardStep.map =>
          'Glissez les colonnes de l’atlas vers les rôles du schéma de surface.',
        SurfaceStudioWizardStep.preview =>
          'Vérifiez le résultat en animation et ajustez si nécessaire.',
        SurfaceStudioWizardStep.save =>
          'Enregistrez le mapping comme nouveau jeu de surface.',
      };

  IconData get icon => switch (this) {
        SurfaceStudioWizardStep.importAtlas => CupertinoIcons.tray_arrow_down,
        SurfaceStudioWizardStep.slice => CupertinoIcons.grid,
        SurfaceStudioWizardStep.map => CupertinoIcons.hand_draw,
        SurfaceStudioWizardStep.preview => CupertinoIcons.play_rectangle,
        SurfaceStudioWizardStep.save => CupertinoIcons.checkmark_seal,
      };
}
