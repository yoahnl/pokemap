import 'package:flutter/material.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core_domain.dart';

import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/feedback/studio_notice.dart';
import '../../shared/widgets/inputs/studio_select.dart';

class PeriodicRewardChoiceScope extends InheritedWidget {
  const PeriodicRewardChoiceScope({
    super.key,
    required this.projectRootPath,
    required super.child,
    this.query,
  });
  final String projectRootPath;
  final Future<AuthoringQueryPage> Function(AuthoringQueryRequest)? query;
  static PeriodicRewardChoiceScope? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PeriodicRewardChoiceScope>();
  Future<AuthoringQueryPage> read(AuthoringQueryRequest request) =>
      query?.call(request) ??
      Future.error(StateError('Les sources publiées sont indisponibles.'));
  static Widget preserve(BuildContext context, Widget child) {
    final source = of(context);
    return source == null
        ? child
        : PeriodicRewardChoiceScope(
            projectRootPath: source.projectRootPath,
            query: source.query,
            child: child,
          );
  }

  @override
  bool updateShouldNotify(PeriodicRewardChoiceScope oldWidget) =>
      projectRootPath != oldWidget.projectRootPath || query != oldWidget.query;
}

class PeriodicRewardPicker extends StatefulWidget {
  const PeriodicRewardPicker({
    super.key,
    this.initial,
    this.expectedValue = true,
    required this.onApply,
  });
  final PeriodicRewardReference? initial;
  final bool expectedValue;
  final void Function(PeriodicRewardReference, bool) onApply;
  @override
  State<PeriodicRewardPicker> createState() => _PeriodicRewardPickerState();
}

class _PeriodicRewardPickerState extends State<PeriodicRewardPicker> {
  final _scenes = <PeriodicRewardSceneChoice>[];
  final _nodes = <PeriodicRewardNodeChoice>[];
  PeriodicRewardChoiceScope? _scope;
  String? _sceneId;
  PeriodicRewardReference? _reference;
  String? _cursor;
  String? _error;
  bool _loading = false;
  bool _expected = true;
  int _generation = 0;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scope = PeriodicRewardChoiceScope.of(context);
    if (!_initialized ||
        scope?.projectRootPath != _scope?.projectRootPath ||
        scope?.query != _scope?.query) {
      _scope = scope;
      _reset();
    }
  }

  @override
  void didUpdateWidget(PeriodicRewardPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initial != widget.initial ||
        oldWidget.expectedValue != widget.expectedValue) {
      _reset();
    }
  }

  void _reset() {
    _initialized = true;
    _generation++;
    _scenes.clear();
    _nodes.clear();
    _cursor = null;
    _error = null;
    _sceneId = widget.initial?.sceneId;
    _reference = widget.initial;
    _expected = widget.expectedValue;
    _loadScenes();
  }

  Future<void> _loadScenes({bool more = false}) async {
    final scope = _scope;
    if (scope == null) {
      _error = 'Les récompenses publiées sont indisponibles dans cet atelier. La condition existante est conservée.';
      return;
    }
    final generation = ++_generation;
    setState(() {
      _loading = true;
      _error = null;
      if (!more) _nodes.clear();
    });
    try {
      final page = await scope.read(
        AuthoringQueryRequest(
          resourceKind: 'periodicRewardScene',
          operation: AuthoringQueryOperation.list,
          view: AuthoringQueryView.summary,
          pageSize: 30,
          cursor: more ? _cursor : null,
        ),
      );
      if (!mounted || generation != _generation) return;
      setState(() {
        if (!more) _scenes.clear();
        _scenes.addAll(
          page.items.map(
            (value) => PeriodicRewardSceneChoice.fromJson(
              Map<String, dynamic>.from(value),
            ),
          ),
        );
        _cursor = page.nextCursor;
      });
      final initial = widget.initial;
      if (!more &&
          initial != null &&
          !_scenes.any((scene) => scene.sceneId == initial.sceneId)) {
        final selected = await scope.read(
          AuthoringQueryRequest(
            resourceKind: 'periodicRewardScene',
            operation: AuthoringQueryOperation.get,
            view: AuthoringQueryView.summary,
            ids: [initial.sceneId],
          ),
        );
        if (!mounted || generation != _generation) return;
        setState(
          () => _scenes.addAll(
            selected.items.map(
              (value) => PeriodicRewardSceneChoice.fromJson(
                Map<String, dynamic>.from(value),
              ),
            ),
          ),
        );
      }
      if (!more && _sceneId != null) await _loadNodes(_sceneId!);
    } catch (error) {
      if (mounted && generation == _generation) {
        setState(
          () => _error = 'Source publiée indisponible ou modifiée. Actualisez les choix. La condition existante est conservée.',
        );
      }
    } finally {
      if (mounted && generation == _generation) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _loadNodes(String sceneId) async {
    final source = _scenes
        .where((value) => value.sceneId == sceneId)
        .firstOrNull;
    final scope = _scope;
    final generation = ++_generation;
    setState(() {
      _loading = source != null && scope != null;
      _error = null;
      _nodes.clear();
    });
    if (source == null || scope == null) return;
    try {
      String? cursor;
      do {
        final page = await scope.read(
          AuthoringQueryRequest(
            resourceKind: 'periodicRewardNode',
            operation: AuthoringQueryOperation.list,
            view: AuthoringQueryView.summary,
            filters: {'sceneId': sceneId},
            extensions: {'sourceRevision': source.revision},
            pageSize: 100,
            cursor: cursor,
          ),
        );
        if (!mounted || generation != _generation) return;
        setState(
          () => _nodes.addAll(
            page.items.map(
              (value) => PeriodicRewardNodeChoice.fromJson(
                Map<String, dynamic>.from(value),
              ),
            ),
          ),
        );
        cursor = page.nextCursor;
      } while (cursor != null);
    } catch (error) {
      if (mounted && generation == _generation) {
        setState(
          () => _error = 'Cette scène publiée a changé ou reste indisponible. Choisissez sa version enregistrée ; les modifications en brouillon ne sont pas des sources publiées.',
        );
      }
    } finally {
      if (mounted && generation == _generation) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = _nodes
        .where((node) => node.reference == _reference)
        .firstOrNull;
    final reference = selected?.reference;
    final unresolved = widget.initial != null && reference == null && !_loading;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const StudioNotice(
          'Choisissez une scène enregistrée, puis son action de récompense quotidienne. Les brouillons ne sont pas publiés.',
        ),
        StudioSelect(
          label: 'Scène de la récompense',
          value: _scenes.any((scene) => scene.sceneId == _sceneId)
              ? _sceneId
              : null,
          options: {for (final scene in _scenes) scene.sceneId: scene.label},
          onChanged: (value) {
            setState(() {
              _sceneId = value;
              _reference = null;
            });
            _loadNodes(value);
          },
        ),
        if (_cursor != null)
          StudioButton(
            label: 'Afficher d’autres scènes',
            secondary: true,
            onPressed: _loading ? null : () => _loadScenes(more: true),
          ),
        StudioSelect(
          label: 'Action de récompense',
          value: selected?.nodeId,
          options: {
            for (final node in _nodes)
              node.nodeId: '${node.label} × ${node.quantity}',
          },
          onChanged: (value) => setState(
            () => _reference = _nodes
                .where((node) => node.nodeId == value)
                .firstOrNull
                ?.reference,
          ),
        ),
        StudioSelect(
          label: 'Disponibilité attendue',
          value: '$_expected',
          options: const {
            'true': 'Disponible aujourd’hui',
            'false': 'Déjà récupérée aujourd’hui',
          },
          onChanged: (value) => setState(() => _expected = value == 'true'),
        ),
        if (_loading) const StudioNotice('Chargement des sources publiées…'),
        if (_error != null) StudioNotice(_error!),
        if (unresolved)
          const StudioNotice(
            'La référence existante reste conservée, mais son action ne peut pas être confirmée. Sélectionnez une action publiée pour la remplacer.',
          ),
        StudioButton(
          label: 'Actualiser les sources',
          secondary: true,
          onPressed: _loading ? null : () => _loadScenes(),
        ),
        StudioButton(
          label: 'Appliquer la condition quotidienne',
          onPressed: _loading || _error != null || reference == null
              ? null
              : () => widget.onApply(reference, _expected),
        ),
      ],
    );
  }
}
