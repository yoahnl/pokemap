import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:map_core/map_core_domain.dart';

import '../../../features/events/application/event_workspace_controller.dart';
import '../../../features/events/domain/event_port.dart';
import '../../../features/events/domain/event_record_view.dart';
import '../../../features/scenes/application/scene_workspace_controller.dart';
import '../map_workspace/map_workspace_visuals.dart';
import '../narrative/narrative_name_dialog.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/buttons/studio_tool.dart';
import '../../shared/widgets/layout/studio_page_header.dart';
import '../../shared/widgets/feedback/studio_notice.dart';
import 'event_status_badge.dart';
import '../../shared/widgets/inputs/studio_tabs.dart';
import '../../shared/widgets/inputs/studio_commit_field.dart';
import 'event_view_state.dart';
import 'event_map_loader.dart';
import 'event_labels.dart';
import 'event_library.dart';
import 'event_summary.dart';
import 'event_page_content.dart';
import 'event_simulation_dialog.dart';
import 'event_registry_dialog.dart';
import 'standard_event_template_form.dart';

part 'event_workspace_layout.dart';

class EventWorkspacePage extends StatefulWidget {
  const EventWorkspacePage({
    super.key,
    required this.controller,
    required this.view,
    required this.loader,
    required this.visuals,
    required this.onBack,
    required this.onScene,
    required this.onLocate,
    required this.onTest,
    this.scenes,
    this.loadItems,
  });
  final EventWorkspaceController controller;
  final EventViewState view;
  final EventMapLoader loader;
  final MapWorkspaceVisuals visuals;
  final SceneWorkspaceController? scenes;
  final Future<Map<String, String>> Function()? loadItems;
  final VoidCallback onBack;
  final Future<String?> Function(String) onScene;
  final Future<String?> Function(NarrativeEventSourceRef) onLocate;
  final Future<void> Function() onTest;
  @override
  State<EventWorkspacePage> createState() => _EventWorkspacePageState();
}

class _EventWorkspacePageState extends State<EventWorkspacePage> {
  EventWorkspaceController get c => widget.controller;
  EventViewState get view => widget.view;
  Future<void> _pending = Future.value();
  String? _notice;
  String? _editProblem;
  final _pageFocus = FocusNode();
  @override
  void initState() {
    super.initState();
    _pending = (c.flushEdits?.call() ?? Future<void>.value()).catchError((
      Object error,
    ) {
      _editProblem = c.error = error.toString();
    });
    c.flushEdits = _flushEdits;
  }

  Future<void> _flushEdits() async {
    if (mounted) _flush();
    await _pending;
    view.invalidNumbers.removeWhere(
      (key, _) => !c.records.any((r) => key.startsWith('${r.id}:')),
    );
    if (view.invalidNumbers.isNotEmpty) {
      throw const EventFailure(
        'Corrigez la priorité ou l’ordre invalide dans Options avant d’enregistrer.',
      );
    }
    if (_editProblem case final error?) throw EventFailure(error);
  }

  @override
  void dispose() {
    final pending = _pending;
    final invalidNumbers = view.invalidNumbers;
    c.flushEdits = () async {
      await pending;
      if (invalidNumbers.isNotEmpty) {
        throw const EventFailure(
          'Corrigez les nombres invalides dans Options avant d’enregistrer.',
        );
      }
      if (_editProblem case final error?) throw EventFailure(error);
    };
    _pageFocus.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  void _flush() {
    FocusManager.instance.primaryFocus?.unfocus();
    _pageFocus.requestFocus();
    FocusManager.instance.applyFocusChangesIfNeeded();
  }

  void _mutate(bool Function() action) {
    _pending = _pending.then((_) async {
      try {
        _editProblem = await c.prepare() && action() ? null : c.error;
      } catch (error) {
        _editProblem = c.error = error.toString();
      }
      _refresh();
    });
  }

  Future<void> _restore(bool redo) async {
    _flush();
    await _pending;
    c.restore(redo: redo);
    _editProblem = null;
    _refresh();
  }

  Future<void> _save() async {
    _flush();
    await _pending;
    await c.saveAll();
    _refresh();
  }

  Future<void> _tab(EventTab tab) async {
    _flush();
    await _pending;
    if (tab != EventTab.trigger && !await c.prepare()) return;
    if (!mounted) return;
    setState(() {
      view.tab = tab;
      view.library = false;
      view.inspector = false;
    });
  }

  Future<void> _create() async {
    _flush();
    await _pending;
    if (!mounted) return;
    final name = await askNarrativeName(context, 'Nom du nouvel événement');
    if (!mounted || name == null || !await c.prepare() || !mounted) return;
    c.create(name);
    setState(() {
      view.tab = EventTab.trigger;
      view.library = false;
    });
  }

  Future<void> _guided() async {
    _flush();
    await _pending;
    if (!mounted || !await c.prepare() || !mounted) return;
    var items = <String, String>{};
    try {
      items = await widget.loadItems?.call() ?? {};
    } catch (_) {
      items = {};
    }
    if (!mounted) return;
    final source = c.active?.source;
    final anchor = source?.when(
      entityAutorun: (map, entity) => (map, entity),
      entityBump: (map, entity) => (map, entity),
      entityInteract: (map, entity) => (map, entity),
      modelInteract: (_, _) => null,
      triggerBump: (_, _) => null,
      triggerEnter: (_, _) => null,
      mapEnter: (_) => null,
      outcomeReceived: (_) => null,
    );
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Événement guidé'),
        content: SizedBox(
          width: 720,
          height: MediaQuery.sizeOf(dialogContext).height * .72,
          child: StandardEventTemplateForm(
            project: c.project,
            maps: c.maps,
            itemOptions: items,
            initialMapId: anchor?.$1 ?? c.workspace.active?.current.id,
            initialEntityId: anchor?.$2,
            onSave: (spec) async {
              final saved = await c.publishTemplate(spec);
              if (!saved) {
                throw EventFailure(c.error ?? 'Événement non enregistré.');
              }
              widget.loader.invalidate(spec.mapId);
              return true;
            },
            onAdvanced: (sceneId) => Navigator.pop(dialogContext, sceneId),
            onCancel: () => Navigator.pop(dialogContext),
          ),
        ),
      ),
    );
    _refresh();
    if (result != null && mounted) await _scene(result);
  }

  Future<void> _open(String id) async {
    _flush();
    await _pending;
    if (!mounted) return;
    c.open(id);
    setState(() {
      view.library = false;
      _notice = null;
    });
  }

  Future<void> _scene(String id) async {
    _flush();
    await _pending;
    if (!mounted) return;
    final problem = await widget.onScene(id);
    if (mounted) setState(() => _notice = problem);
  }

  Future<void> _locate(NarrativeEventSourceRef source) async {
    _flush();
    await _pending;
    if (!mounted) return;
    final problem = await widget.onLocate(source);
    if (mounted) setState(() => _notice = problem);
  }

  Future<void> _remove(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer cet événement ?'),
        content: const Text(
          'Sa scène reste partagée et conservée. La suppression sera publiée avec Enregistrer et peut être refusée si une référence l’utilise.',
        ),
        actions: [
          StudioButton(
            label: 'Annuler',
            secondary: true,
            onPressed: () => Navigator.pop(context, false),
          ),
          StudioButton(
            label: 'Supprimer',
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) _mutate(() => c.delete(id));
  }

  Future<void> _reload(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Recharger cet événement ?'),
        content: const Text(
          'Les modifications locales de cet événement seront abandonnées. Les autres documents restent ouverts.',
        ),
        actions: [
          StudioButton(
            label: 'Annuler',
            secondary: true,
            onPressed: () => Navigator.pop(context, false),
          ),
          StudioButton(
            label: 'Recharger',
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      _flush();
      await _pending;
      if (await c.reload(id)) {
        view.invalidNumbers.removeWhere((key, _) => key.startsWith('$id:'));
        _editProblem = null;
      }
      _refresh();
    }
  }

  @override
  Widget build(BuildContext context) => _buildEventPage(context);
}
