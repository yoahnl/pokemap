import 'package:flutter/cupertino.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';

import '../../../../features/editor/state/editor_notifier.dart';
import '../../../../features/editor/state/editor_selectors.dart';
import '../../../shared/cupertino_editor_widgets.dart';

String mapGroupTypeDisplayLabel(MapGroupType type) {
  final name = type.name;
  if (name.isEmpty) return '';
  return '${name[0].toUpperCase()}${name.substring(1)}';
}

void showCreateGroupDialog(
  BuildContext context,
  EditorNotifier notifier, {
  String? parentId,
}) {
  final nameController = TextEditingController();
  var selectedType = MapGroupType.city;

  showMacosEditorModalSheet<void>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            parentId == null ? 'New Root Group' : 'New Sub-Group',
            style: editorMacosSheetTitleStyle(ctx),
          ),
          const SizedBox(height: 12),
          MacosTextField(
            controller: nameController,
            autofocus: true,
            placeholder: 'Group Name',
          ),
          const SizedBox(height: 12),
          Text('Group type', style: editorMacosFormLabelStyle(ctx)),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: MacosPopupButton<MapGroupType>(
              value: selectedType,
              onChanged: (MapGroupType? value) {
                if (value != null) setState(() => selectedType = value);
              },
              items: [
                for (final type in MapGroupType.values)
                  MacosPopupMenuItem<MapGroupType>(
                    value: type,
                    child: Text(mapGroupTypeDisplayLabel(type)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
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
                onPressed: () {
                  if (nameController.text.trim().isEmpty) return;
                  notifier.createGroup(
                    nameController.text.trim(),
                    selectedType,
                    parentId: parentId,
                  );
                  Navigator.pop(ctx);
                },
                child: const Text('Create'),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

Future<void> showCreateMapInGroupDialog(
  BuildContext context,
  String groupId,
  EditorNotifier notifier,
  EditorProjectExplorerSnapshot snapshot,
) async {
  final controller = TextEditingController();
  var selectedRole = MapRole.exterior;
  final settings = snapshot.settings;

  await showMacosEditorModalSheet<void>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'New Map in Group',
            style: editorMacosSheetTitleStyle(ctx),
          ),
          const SizedBox(height: 12),
          MacosTextField(
            controller: controller,
            autofocus: true,
            placeholder: 'Map ID',
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: PushButton(
              controlSize: ControlSize.regular,
              secondary: true,
              onPressed: () async {
                final picked = await showCupertinoListPicker<MapRole>(
                  context: ctx,
                  title: 'Map Role',
                  items: MapRole.values,
                  labelOf: (role) => role.name.toUpperCase(),
                );
                if (picked != null) setState(() => selectedRole = picked);
              },
              child: Text('Role: ${selectedRole.name.toUpperCase()}'),
            ),
          ),
          const SizedBox(height: 16),
          Row(
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
                onPressed: () {
                  if (controller.text.isEmpty) return;
                  notifier.createMap(
                    controller.text,
                    settings.defaultMapWidth,
                    settings.defaultMapHeight,
                    groupId: groupId,
                    role: selectedRole,
                  );
                  Navigator.pop(ctx);
                },
                child: const Text('Create'),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

void showCreateSubGroupDialog(
  BuildContext context,
  String parentId,
  EditorNotifier notifier,
) {
  final nameController = TextEditingController();
  var selectedType = MapGroupType.facility;

  showMacosEditorModalSheet<void>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'New Sub-Group',
            style: editorMacosSheetTitleStyle(ctx),
          ),
          const SizedBox(height: 12),
          MacosTextField(
            controller: nameController,
            autofocus: true,
            placeholder: 'Group Name',
          ),
          const SizedBox(height: 12),
          Text('Group type', style: editorMacosFormLabelStyle(ctx)),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: MacosPopupButton<MapGroupType>(
              value: selectedType,
              onChanged: (MapGroupType? value) {
                if (value != null) setState(() => selectedType = value);
              },
              items: [
                for (final type in MapGroupType.values)
                  MacosPopupMenuItem<MapGroupType>(
                    value: type,
                    child: Text(mapGroupTypeDisplayLabel(type)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
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
                onPressed: () {
                  if (nameController.text.trim().isEmpty) return;
                  notifier.createGroup(
                    nameController.text.trim(),
                    selectedType,
                    parentId: parentId,
                  );
                  Navigator.pop(ctx);
                },
                child: const Text('Create'),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

Future<void> showRenameGroupDialog(
  BuildContext context,
  ProjectMapGroup group,
  EditorNotifier notifier,
) async {
  final controller = TextEditingController(text: group.name);
  final ok = await showMacosEditorPromptSheet(
    context,
    title: 'Rename Group',
    controller: controller,
    confirmLabel: 'Rename',
  );
  if (!ok || !context.mounted) return;
  notifier.renameGroup(group.id, controller.text.trim());
}

Future<void> showRenameMapDialog(
  BuildContext context,
  ProjectMapEntry mapEntry,
  EditorNotifier notifier,
) async {
  final controller = TextEditingController(text: mapEntry.id);
  final ok = await showMacosEditorPromptSheet(
    context,
    title: 'Rename Map',
    controller: controller,
    confirmLabel: 'Rename',
  );
  if (!ok || !context.mounted) return;
  notifier.renameMap(mapEntry.id, controller.text.trim());
}
