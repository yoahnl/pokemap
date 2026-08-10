import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show showDialog;
import 'package:flutter/services.dart';
import 'package:map_editor/game_export.dart';
import 'package:map_editor/src/ui/shared/pokemap_macos_ui_shim.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../../features/editor/presentation/map_activation_guard.dart';
import '../../../../features/editor/state/editor_notifier.dart';
import '../../../design_system/pokemap_resize_impact_dialog.dart';
import '../../cupertino_editor_widgets.dart';

/// Regroupe les dialogs de toolbar pour garder `top_toolbar.dart` focalisé sur
/// l'assemblage du chrome.
///
/// Les flux sensibles délèguent leur prévisualisation aux composants du design
/// system avant d'appeler les mutations du notifier.
Future<void> showTopToolbarNewProjectDialog(
  BuildContext context,
  EditorNotifier notifier,
) async {
  final controller = TextEditingController(text: 'My New Project');
  final ok = await showMacosEditorPromptSheet(
    context,
    title: 'New Project',
    controller: controller,
    placeholder: 'The name of your game',
    confirmLabel: 'Create Project',
  );
  if (!context.mounted) return;
  if (!ok) return;
  final name = controller.text.trim();
  if (name.isEmpty) return;
  final baseDir = await FilePicker.getDirectoryPath();
  if (!context.mounted) return;
  if (baseDir != null) {
    final projectDir = p.join(baseDir, name.replaceAll(' ', '_').toLowerCase());
    await requestEditorProjectCreation(
      context: context,
      notifier: notifier,
      name: name,
      directory: projectDir,
    );
  }
}

Future<void> showTopToolbarOpenProjectDialog(
  BuildContext context,
  EditorNotifier notifier,
) async {
  String? selectedDirectory;
  try {
    selectedDirectory = await FilePicker.getDirectoryPath();
  } catch (error, stackTrace) {
    debugPrint('TopToolbar: native project picker failed: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
  if (!context.mounted) return;
  final manifestPath = selectedDirectory == null
      ? await _promptForProjectManifestPath(context)
      : resolveProjectManifestPathFromUserSelection(selectedDirectory);
  if (!context.mounted || manifestPath == null) return;
  await requestEditorProjectActivation(
    context: context,
    notifier: notifier,
    manifestPath: manifestPath,
  );
}

String resolveProjectManifestPathFromUserSelection(String value) {
  var path = value.trim();
  if (path.length >= 2) {
    final first = path[0];
    final last = path[path.length - 1];
    if ((first == '"' && last == '"') || (first == "'" && last == "'")) {
      path = path.substring(1, path.length - 1).trim();
    }
  }
  if (path == '~') {
    path = Platform.environment['HOME'] ?? path;
  } else if (path.startsWith('~/')) {
    final home = Platform.environment['HOME'];
    if (home != null && home.isNotEmpty) {
      path = p.join(home, path.substring(2));
    }
  }
  final normalized = p.normalize(path);
  if (p.basename(normalized) == 'project.json') {
    return normalized;
  }
  return p.join(normalized, 'project.json');
}

Future<String?> _promptForProjectManifestPath(BuildContext context) async {
  final controller = TextEditingController();
  try {
    final ok = await showMacosEditorPromptSheet(
      context,
      title: 'Open Project',
      controller: controller,
      placeholder:
          '/Users/you/PokeMapProject or /Users/you/PokeMapProject/project.json',
      confirmLabel: 'Open Project',
    );
    if (!context.mounted || !ok) return null;
    final value = controller.text.trim();
    if (value.isEmpty) return null;
    return resolveProjectManifestPathFromUserSelection(value);
  } finally {
    controller.dispose();
  }
}

Future<void> showTopToolbarNewMapDialog(
  BuildContext context,
  EditorNotifier notifier, {
  required int defaultWidth,
  required int defaultHeight,
}) async {
  final controller = TextEditingController();
  final ok = await showMacosEditorPromptSheet(
    context,
    title: 'New Root Map',
    controller: controller,
    placeholder: 'Map ID',
    confirmLabel: 'Create',
  );
  if (!context.mounted) return;
  if (!ok) return;
  final id = controller.text.trim();
  if (id.isEmpty) return;
  notifier.createMap(id, defaultWidth, defaultHeight);
}

void showTopToolbarProjectSettingsDialog(
  BuildContext context,
  EditorNotifier notifier,
  ProjectManifest project,
) {
  final settings = project.settings;
  final characters = project.characters;
  final nameController = TextEditingController(text: project.name);
  final tileWidthController = TextEditingController(
    text: settings.tileWidth.toString(),
  );
  final tileHeightController = TextEditingController(
    text: settings.tileHeight.toString(),
  );
  final displayScaleController = TextEditingController(
    text: settings.displayScale.toString(),
  );
  final defaultMapWidthController = TextEditingController(
    text: settings.defaultMapWidth.toString(),
  );
  final defaultMapHeightController = TextEditingController(
    text: settings.defaultMapHeight.toString(),
  );
  String? defaultPlayerCharacterId = settings.defaultPlayerCharacterId;
  final mistralApiKeyController = TextEditingController(
    text: settings.mistralApiKey ?? '',
  );

  String? validatePositiveInt(String? value) {
    final text = (value ?? '').trim();
    final number = int.tryParse(text);
    if (number == null) return 'Enter a number';
    if (number <= 0) return 'Must be > 0';
    return null;
  }

  String? validatePositiveDouble(String? value) {
    final text = (value ?? '').trim();
    final number = double.tryParse(text);
    if (number == null) return 'Enter a number';
    if (number <= 0) return 'Must be > 0';
    return null;
  }

  showMacosEditorTallSheet<void>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSheetState) => ListView(
        shrinkWrap: true,
        physics: const ClampingScrollPhysics(),
        padding: EdgeInsets.zero,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Project Settings',
                        style: editorMacosSheetTitleStyle(ctx),
                      ),
                    ),
                    MacosIconButton(
                      icon: const MacosIcon(CupertinoIcons.xmark_circle_fill),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    topToolbarSettingsLabeledField(
                      ctx,
                      label: 'Project Name',
                      controller: nameController,
                    ),
                    const SizedBox(height: 12),
                    topToolbarSettingsLabeledField(
                      ctx,
                      label: 'Tile Width',
                      controller: tileWidthController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                    const SizedBox(height: 12),
                    topToolbarSettingsLabeledField(
                      ctx,
                      label: 'Tile Height',
                      controller: tileHeightController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                    const SizedBox(height: 12),
                    topToolbarSettingsLabeledField(
                      ctx,
                      label: 'Display Scale',
                      controller: displayScaleController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                      ],
                    ),
                    const SizedBox(height: 12),
                    topToolbarSettingsLabeledField(
                      ctx,
                      label: 'Default Map Width',
                      controller: defaultMapWidthController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                    const SizedBox(height: 12),
                    topToolbarSettingsLabeledField(
                      ctx,
                      label: 'Default Map Height',
                      controller: defaultMapHeightController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                    const SizedBox(height: 12),
                    topToolbarSettingsCharacterField(
                      ctx,
                      characters: characters,
                      selectedCharacterId: defaultPlayerCharacterId,
                      onPressed: () async {
                        final picked =
                            await showCupertinoListPicker<
                              ProjectCharacterEntry?
                            >(
                              context: ctx,
                              title: 'Default Player Character',
                              items: [null, ...characters],
                              labelOf: (value) => value?.name ?? 'None',
                            );
                        setSheetState(() {
                          defaultPlayerCharacterId = picked?.id;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'IA (éditeur)',
                      style: editorMacosSheetTitleStyle(
                        ctx,
                      ).copyWith(fontSize: 15),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Clé utilisée par Dialogue Studio et les futures intégrations '
                      'IA. Elle est enregistrée dans project.json — évitez les dépôts '
                      'publics ou utilisez plutôt la variable d’environnement MISTRAL_API_KEY.',
                      style: MacosTheme.of(ctx).typography.caption1.copyWith(
                        color: CupertinoColors.secondaryLabel.resolveFrom(ctx),
                      ),
                    ),
                    const SizedBox(height: 10),
                    topToolbarSettingsLabeledField(
                      ctx,
                      label: 'Clé API Mistral',
                      controller: mistralApiKeyController,
                      obscureText: true,
                      placeholder:
                          'sk-… (optionnel si MISTRAL_API_KEY est définie)',
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    PushButton(
                      controlSize: ControlSize.large,
                      secondary: true,
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 10),
                    PushButton(
                      controlSize: ControlSize.large,
                      onPressed: () async {
                        final name = nameController.text.trim();
                        if (name.isEmpty) return;
                        final e1 = validatePositiveInt(
                          tileWidthController.text,
                        );
                        final e2 = validatePositiveInt(
                          tileHeightController.text,
                        );
                        final e3 = validatePositiveDouble(
                          displayScaleController.text,
                        );
                        final e4 = validatePositiveInt(
                          defaultMapWidthController.text,
                        );
                        final e5 = validatePositiveInt(
                          defaultMapHeightController.text,
                        );
                        if (e1 != null ||
                            e2 != null ||
                            e3 != null ||
                            e4 != null ||
                            e5 != null) {
                          return;
                        }
                        final mistralKey = mistralApiKeyController.text.trim();
                        final updatedSettings = settings.copyWith(
                          tileWidth: int.parse(tileWidthController.text.trim()),
                          tileHeight: int.parse(
                            tileHeightController.text.trim(),
                          ),
                          displayScale: double.parse(
                            displayScaleController.text.trim(),
                          ),
                          defaultMapWidth: int.parse(
                            defaultMapWidthController.text.trim(),
                          ),
                          defaultMapHeight: int.parse(
                            defaultMapHeightController.text.trim(),
                          ),
                          defaultPlayerCharacterId: defaultPlayerCharacterId,
                          mistralApiKey: mistralKey.isEmpty ? null : mistralKey,
                        );
                        Navigator.pop(ctx);
                        await notifier.updateProjectSettings(
                          name: name,
                          settings: updatedSettings,
                        );
                      },
                      child: const Text('Save'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

Future<void> showTopToolbarResizeMapDialog(
  BuildContext context,
  EditorNotifier notifier, {
  required int currentWidth,
  required int currentHeight,
}) async {
  final target = await showPokeMapResizeImpactDialog(
    context,
    currentWidth: currentWidth,
    currentHeight: currentHeight,
    buildPlan: (width, height) {
      final plan = notifier.planActiveMapResize(width, height);
      if (plan == null) {
        throw StateError('No active map is available for resize planning.');
      }
      return plan;
    },
  );
  if (!context.mounted || target == null) return;
  await notifier.resizeActiveMap(target.width, target.height);
}

Widget topToolbarSettingsLabeledField(
  BuildContext context, {
  required String label,
  required TextEditingController controller,
  TextInputType? keyboardType,
  List<TextInputFormatter>? inputFormatters,
  bool obscureText = false,
  String? placeholder,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: editorMacosFormLabelStyle(context)),
      const SizedBox(height: 6),
      MacosTextField(
        controller: controller,
        keyboardType: keyboardType ?? TextInputType.text,
        inputFormatters: inputFormatters,
        obscureText: obscureText,
        placeholder: placeholder,
      ),
    ],
  );
}

Widget topToolbarSettingsCharacterField(
  BuildContext context, {
  required List<ProjectCharacterEntry> characters,
  required String? selectedCharacterId,
  required Future<void> Function() onPressed,
}) {
  var label = 'None';
  for (final character in characters) {
    if (character.id == selectedCharacterId) {
      label = character.name;
      break;
    }
  }
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Default Player Character',
        style: editorMacosFormLabelStyle(context),
      ),
      const SizedBox(height: 6),
      PushButton(
        controlSize: ControlSize.large,
        secondary: true,
        onPressed: onPressed,
        child: Text(label),
      ),
      const SizedBox(height: 4),
      Text(
        'Initial overworld appearance used at game start. Runtime may change it later.',
        style: MacosTheme.of(context).typography.caption1.copyWith(
          color: CupertinoColors.secondaryLabel.resolveFrom(context),
        ),
      ),
    ],
  );
}

Future<void> showTopToolbarGameExportDialog(
  BuildContext context, {
  required String projectRootPath,
  required String projectName,
}) async {
  final appSupport = await getApplicationSupportDirectory();
  if (!context.mounted) return;
  final controller = GamePackageExportController(
    projectRoot: Directory(projectRootPath),
    projectName: projectName,
    profileStore: GamePackageExportProfileStore(
      projectRoot: Directory(projectRootPath),
    ),
    diagnosticLogFile: File(
      p.join(appSupport.path, 'PokeMap', 'logs', 'game-export.log'),
    ),
    installRequestPublisher: HubInstallRequestPublisher(
      inbox: Directory(p.join(appSupport.path, 'PokeMap', 'import-inbox')),
    ),
  );
  try {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => GamePackageExportDialog(
        controller: controller,
        chooseOutputFile: (suggestedFileName) async {
          final selectedPath = await FilePicker.saveFile(
            dialogTitle: 'Exporter le jeu PokeMap',
            fileName: suggestedFileName,
            type: FileType.custom,
            allowedExtensions: const <String>['avelunegame'],
          );
          if (selectedPath == null) return null;
          return File(selectedPath);
        },
        chooseProjectFile: (type) async {
          final extensions = switch (type) {
            GamePackageProjectFileType.image => const <String>[
              'png',
              'jpg',
              'jpeg',
              'webp',
            ],
            GamePackageProjectFileType.audio => const <String>[
              'ogg',
              'wav',
              'mp3',
              'flac',
              'm4a',
            ],
            GamePackageProjectFileType.text => const <String>['txt', 'md'],
          };
          final result = await FilePicker.pickFiles(
            dialogTitle: 'Choisir un fichier du projet',
            type: FileType.custom,
            allowedExtensions: extensions,
            allowMultiple: false,
          );
          final selectedPath = result?.files.single.path;
          return selectedPath == null ? null : File(selectedPath);
        },
      ),
    );
  } finally {
    controller.dispose();
  }
}
