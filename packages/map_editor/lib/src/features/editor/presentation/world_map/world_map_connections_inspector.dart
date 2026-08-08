import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

import '../../../../app/providers/editor/editing_service_providers.dart';
import '../../../../theme/theme.dart';
import '../../../../ui/design_system/design_system.dart';
import '../../state/editor_notifier.dart';
import '../map_activation_guard.dart';

typedef WorldMapConnectionApplyCallback = Future<void> Function({
  required MapConnectionDirection direction,
  required String targetMapId,
  required int offset,
  required bool reciprocal,
});

typedef WorldMapConnectionDirectionCallback = Future<void> Function(
  MapConnectionDirection direction,
);

typedef WorldMapConnectionTargetLoader = Future<MapData?> Function(
  String targetMapId,
);

class WorldMapConnectionsInspector extends ConsumerStatefulWidget {
  const WorldMapConnectionsInspector({
    super.key,
    this.onApply,
    this.onDelete,
    this.onOpen,
    this.loadTargetMap,
  });

  final WorldMapConnectionApplyCallback? onApply;
  final WorldMapConnectionDirectionCallback? onDelete;
  final WorldMapConnectionDirectionCallback? onOpen;
  final WorldMapConnectionTargetLoader? loadTargetMap;

  @override
  ConsumerState<WorldMapConnectionsInspector> createState() =>
      _WorldMapConnectionsInspectorState();
}

class _WorldMapConnectionsInspectorState
    extends ConsumerState<WorldMapConnectionsInspector> {
  late final Map<MapConnectionDirection, TextEditingController>
      _offsetControllers;
  final _selectedTargetMapIds = <MapConnectionDirection, String?>{};
  final _reciprocalDrafts = <MapConnectionDirection, bool>{};
  final _targetFutures = <String, Future<MapData?>>{};
  MapConnectionDirection _selectedDirection = MapConnectionDirection.north;
  String? _boundConnectionsKey;
  String _announcement = 'Sélectionnez une direction à configurer.';
  bool _isApplying = false;

  @override
  void initState() {
    super.initState();
    _offsetControllers = {
      for (final direction in MapConnectionDirection.values)
        direction: TextEditingController(text: '0'),
    };
  }

  @override
  void dispose() {
    for (final controller in _offsetControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editorState = ref.watch(editorNotifierProvider);
    final notifier = ref.read(editorNotifierProvider.notifier);
    final map = editorState.activeMap;
    final project = editorState.project;
    if (map == null || project == null) {
      return const PokeMapEmptyState(
        icon: Icon(Icons.hub_outlined),
        title: 'Aucune map active',
        description: 'Ouvrez une map pour configurer ses connexions.',
      );
    }

    _syncDrafts(map);
    final projectMaps = project.maps
        .where((entry) => entry.id != map.id)
        .toList(growable: false)
      ..sort(_compareMapEntries);
    final projectMapById = {
      for (final entry in projectMaps) entry.id: entry,
    };
    final existing = _connectionFor(map, _selectedDirection);
    final targetMapId = _selectedTargetMapIds[_selectedDirection]?.trim();
    final targetManifested = targetMapId != null &&
        targetMapId.isNotEmpty &&
        projectMapById.containsKey(targetMapId);
    final targetFuture = targetManifested
        ? _targetFutures.putIfAbsent(
            targetMapId,
            () => (widget.loadTargetMap ?? notifier.loadMapSnapshotById)(
              targetMapId,
            ),
          )
        : null;

    return FutureBuilder<MapData?>(
      future: targetFuture,
      builder: (context, targetSnapshot) {
        final targetMap = targetSnapshot.data;
        final targetMissing = targetMapId != null &&
            targetMapId.isNotEmpty &&
            (!targetManifested ||
                (targetSnapshot.connectionState == ConnectionState.done &&
                    targetMap == null));
        final targetLoading = targetFuture != null &&
            targetSnapshot.connectionState != ConnectionState.done;
        final offsetText = _offsetControllers[_selectedDirection]!.text.trim();
        final offset = int.tryParse(offsetText);
        final preview = targetMap == null || offset == null
            ? null
            : const WarpConnectionActions().previewAlignment(
                sourceSize: map.size,
                targetSize: targetMap.size,
                direction: _selectedDirection,
                offset: offset,
              );
        final exactPair = existing != null &&
            targetMap != null &&
            ref
                .read(mapConnectionEditingServiceProvider)
                .hasExactReciprocalPair(
                  sourceMap: map,
                  targetMap: targetMap,
                  direction: _selectedDirection,
                );
        final reciprocal = existing == null
            ? (_reciprocalDrafts[_selectedDirection] ?? true)
            : exactPair;
        final validation = _validationFor(
          targetMapId: targetMapId,
          targetLoading: targetLoading,
          targetMissing: targetMissing,
          offset: offset,
          preview: preview,
        );

        return ListView(
          key: const ValueKey<String>('world-map-connections-inspector'),
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
          children: [
            Text(
              'Reliez les bords de la map active pour construire un monde '
              'continu. Les connexions réciproques restent atomiques.',
              style: TextStyle(
                color: context.pokeMapColors.textSecondary,
                fontSize: 11,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 12),
            _ConnectionCompass(
              map: map,
              projectMapById: projectMapById,
              selectedDirection: _selectedDirection,
              onSelected: (direction) {
                setState(() {
                  _selectedDirection = direction;
                  _announcement =
                      'Direction ${_directionLabel(direction)} sélectionnée.';
                });
              },
            ),
            const SizedBox(height: 12),
            PokeMapCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _directionLabel(_selectedDirection),
                          style: TextStyle(
                            color: context.pokeMapColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      PokeMapBadge(
                        key: const ValueKey<String>(
                          'world-map-connection-status',
                        ),
                        label: validation.label,
                        variant: validation.badgeVariant,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  PokeMapDropdownField<String>(
                    key: const ValueKey<String>(
                      'world-map-connection-target',
                    ),
                    label: 'Map cible',
                    value: targetMapId ?? '',
                    enabled: existing == null && projectMaps.isNotEmpty,
                    items: [
                      const PokeMapDropdownItem<String>(
                        value: '',
                        label: 'Choisir une map…',
                      ),
                      if (targetMapId != null &&
                          targetMapId.isNotEmpty &&
                          !targetManifested)
                        PokeMapDropdownItem<String>(
                          value: targetMapId,
                          label: 'Introuvable · $targetMapId',
                        ),
                      for (final entry in projectMaps)
                        PokeMapDropdownItem<String>(
                          value: entry.id,
                          label: entry.name,
                        ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedTargetMapIds[_selectedDirection] =
                            value.isEmpty ? null : value;
                        _announcement = value.isEmpty
                            ? 'Choisissez une map cible.'
                            : 'Map cible sélectionnée : '
                                '${projectMapById[value]?.name ?? value}.';
                      });
                    },
                  ),
                  if (existing != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Pour changer la cible, supprimez cette connexion puis '
                      'créez-en une nouvelle.',
                      style: TextStyle(
                        color: context.pokeMapColors.textMuted,
                        fontSize: 10,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  PokeMapTextField(
                    label: 'Décalage en tiles',
                    controller: _offsetControllers[_selectedDirection],
                    fieldKey: const ValueKey<String>(
                      'world-map-connection-offset',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      signed: true,
                    ),
                    inputFormatters: [_signedIntegerFormatter],
                    errorText: offset == null
                        ? 'Saisissez un entier signé, par exemple -4, 0 ou 4.'
                        : null,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Type de connexion',
                    style: TextStyle(
                      color: context.pokeMapColors.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: PokeMapButton(
                          key: const ValueKey<String>(
                            'world-map-connection-one-way',
                          ),
                          onPressed: existing == null
                              ? () => setState(() {
                                    _reciprocalDrafts[_selectedDirection] =
                                        false;
                                  })
                              : null,
                          isSelected: !reciprocal,
                          variant: PokeMapButtonVariant.secondary,
                          size: PokeMapButtonSize.small,
                          child: const Text('Sens unique'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: PokeMapButton(
                          key: const ValueKey<String>(
                            'world-map-connection-reciprocal',
                          ),
                          onPressed: existing == null
                              ? () => setState(() {
                                    _reciprocalDrafts[_selectedDirection] =
                                        true;
                                  })
                              : null,
                          isSelected: reciprocal,
                          variant: PokeMapButtonVariant.secondary,
                          size: PokeMapButtonSize.small,
                          child: const Text('Réciproque'),
                        ),
                      ),
                    ],
                  ),
                  if (existing != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      exactPair
                          ? 'Paire réciproque détectée : les deux maps seront '
                              'mises à jour ensemble.'
                          : 'Connexion à sens unique : la promotion en paire '
                              'réciproque nécessite de la recréer.',
                      style: TextStyle(
                        color: context.pokeMapColors.textMuted,
                        fontSize: 10,
                        height: 1.3,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  _AlignmentPreview(
                    loading: targetLoading,
                    targetMissing: targetMissing,
                    preview: preview,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (existing != null) ...[
                        Expanded(
                          child: PokeMapButton(
                            key: const ValueKey<String>(
                              'world-map-connection-open',
                            ),
                            onPressed: targetMap == null || _isApplying
                                ? null
                                : () => _open(notifier),
                            variant: PokeMapButtonVariant.secondary,
                            size: PokeMapButtonSize.small,
                            leading: const Icon(Icons.open_in_new_outlined),
                            child: const Text('Ouvrir'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: PokeMapButton(
                            key: const ValueKey<String>(
                              'world-map-connection-delete',
                            ),
                            onPressed:
                                _isApplying ? null : () => _delete(notifier),
                            variant: PokeMapButtonVariant.danger,
                            size: PokeMapButtonSize.small,
                            leading: const Icon(Icons.delete_outline),
                            child: const Text('Supprimer'),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: PokeMapButton(
                          key: const ValueKey<String>(
                            'world-map-connection-apply',
                          ),
                          onPressed: validation.canApply && !_isApplying
                              ? () => _apply(
                                    notifier: notifier,
                                    targetMapId: targetMapId!,
                                    offset: offset!,
                                    reciprocal: reciprocal,
                                  )
                              : null,
                          isLoading: _isApplying,
                          disabledReason: validation.reason,
                          variant: PokeMapButtonVariant.primary,
                          size: PokeMapButtonSize.small,
                          leading: const Icon(Icons.check_circle_outline),
                          child: Text(
                              existing == null ? 'Appliquer' : 'Mettre à jour'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Semantics(
              key: const ValueKey<String>(
                'world-map-connection-announcement',
              ),
              liveRegion: true,
              label: _announcement,
              child: Text(
                _announcement,
                style: TextStyle(
                  color: context.pokeMapColors.textSecondary,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _syncDrafts(MapData map) {
    final serializedConnections = map.connections
        .map(
          (connection) => '${connection.direction.name}:'
              '${connection.targetMapId}:${connection.offset}',
        )
        .join('|');
    final nextKey = '${map.id}|$serializedConnections';
    if (_boundConnectionsKey == nextKey) return;
    _boundConnectionsKey = nextKey;
    _targetFutures.clear();
    _reciprocalDrafts.clear();
    for (final direction in MapConnectionDirection.values) {
      final connection = _connectionFor(map, direction);
      _selectedTargetMapIds[direction] = connection?.targetMapId;
      _offsetControllers[direction]!.text =
          connection?.offset.toString() ?? '0';
    }
  }

  Future<void> _apply({
    required EditorNotifier notifier,
    required String targetMapId,
    required int offset,
    required bool reciprocal,
  }) async {
    setState(() {
      _isApplying = true;
      _announcement = 'Application de la connexion en cours…';
    });
    try {
      final callback = widget.onApply;
      if (callback != null) {
        await callback(
          direction: _selectedDirection,
          targetMapId: targetMapId,
          offset: offset,
          reciprocal: reciprocal,
        );
      } else {
        await notifier.saveMapConnection(
          direction: _selectedDirection,
          targetMapId: targetMapId,
          offset: offset,
          reciprocal: reciprocal,
        );
      }
      if (!mounted) return;
      final error = ref.read(editorNotifierProvider).errorMessage;
      setState(() {
        _announcement = error ??
            'Connexion ${_directionLabel(_selectedDirection)} appliquée.';
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _announcement = 'Impossible d’appliquer la connexion : $error';
      });
    } finally {
      if (mounted) setState(() => _isApplying = false);
    }
  }

  Future<void> _delete(EditorNotifier notifier) async {
    setState(() {
      _isApplying = true;
      _announcement = 'Suppression de la connexion en cours…';
    });
    try {
      final callback = widget.onDelete;
      if (callback != null) {
        await callback(_selectedDirection);
      } else {
        await notifier.deleteMapConnection(_selectedDirection);
      }
      if (!mounted) return;
      final error = ref.read(editorNotifierProvider).errorMessage;
      setState(() {
        _announcement = error ??
            'Connexion ${_directionLabel(_selectedDirection)} supprimée.';
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _announcement = 'Impossible de supprimer la connexion : $error';
      });
    } finally {
      if (mounted) setState(() => _isApplying = false);
    }
  }

  Future<void> _open(EditorNotifier notifier) async {
    final callback = widget.onOpen;
    if (callback != null) {
      await callback(_selectedDirection);
      return;
    }
    if (!mounted) return;
    await requestEditorConnectedMapActivation(
      context: context,
      notifier: notifier,
      direction: _selectedDirection,
    );
  }
}

class _ConnectionCompass extends StatelessWidget {
  const _ConnectionCompass({
    required this.map,
    required this.projectMapById,
    required this.selectedDirection,
    required this.onSelected,
  });

  final MapData map;
  final Map<String, ProjectMapEntry> projectMapById;
  final MapConnectionDirection selectedDirection;
  final ValueChanged<MapConnectionDirection> onSelected;

  @override
  Widget build(BuildContext context) {
    Widget direction(MapConnectionDirection value) {
      final connection = _connectionFor(map, value);
      final target = connection == null
          ? '+ Ajouter'
          : projectMapById[connection.targetMapId]?.name ?? 'Introuvable';
      return PokeMapButton(
        key: ValueKey<String>('world-map-connection-${value.name}'),
        onPressed: () => onSelected(value),
        isSelected: value == selectedDirection,
        variant: PokeMapButtonVariant.secondary,
        size: PokeMapButtonSize.medium,
        semanticLabel: '${_directionLabel(value)} : $target',
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_directionIcon(value), size: 15),
            const SizedBox(height: 2),
            Text(
              target,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            const Expanded(child: SizedBox.shrink()),
            Expanded(child: direction(MapConnectionDirection.north)),
            const Expanded(child: SizedBox.shrink()),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(child: direction(MapConnectionDirection.west)),
            const SizedBox(width: 6),
            Expanded(
              child: PokeMapCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 10,
                ),
                child: Column(
                  children: [
                    const Icon(Icons.map_outlined, size: 16),
                    const SizedBox(height: 3),
                    Text(
                      map.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: context.pokeMapColors.textPrimary,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(child: direction(MapConnectionDirection.east)),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            const Expanded(child: SizedBox.shrink()),
            Expanded(child: direction(MapConnectionDirection.south)),
            const Expanded(child: SizedBox.shrink()),
          ],
        ),
      ],
    );
  }
}

class _AlignmentPreview extends StatelessWidget {
  const _AlignmentPreview({
    required this.loading,
    required this.targetMissing,
    required this.preview,
  });

  final bool loading;
  final bool targetMissing;
  final ConnectionAlignmentPreview? preview;

  @override
  Widget build(BuildContext context) {
    final text = loading
        ? 'Calcul du recouvrement…'
        : targetMissing
            ? 'La map cible ne peut pas être lue.'
            : preview == null
                ? 'Choisissez une cible et un décalage valide.'
                : preview!.hasOverlap
                    ? 'Recouvrement : ${preview!.overlapLength} tiles communes.'
                    : 'Aucun recouvrement : rapprochez les deux maps.';
    return PokeMapCard(
      key: const ValueKey<String>('world-map-connection-overlap'),
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          Icon(
            preview?.hasOverlap == true
                ? Icons.compare_arrows_outlined
                : Icons.info_outline,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: context.pokeMapColors.textSecondary,
                fontSize: 10,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

typedef _ConnectionValidation = ({
  String label,
  PokeMapBadgeVariant badgeVariant,
  bool canApply,
  String? reason,
});

_ConnectionValidation _validationFor({
  required String? targetMapId,
  required bool targetLoading,
  required bool targetMissing,
  required int? offset,
  required ConnectionAlignmentPreview? preview,
}) {
  if (targetMapId == null || targetMapId.isEmpty) {
    return (
      label: 'À compléter',
      badgeVariant: PokeMapBadgeVariant.warning,
      canApply: false,
      reason: 'Choisissez une map cible.',
    );
  }
  if (targetMissing) {
    return (
      label: 'Cible introuvable',
      badgeVariant: PokeMapBadgeVariant.error,
      canApply: false,
      reason: 'La map cible ne peut pas être lue.',
    );
  }
  if (targetLoading || offset == null || preview == null) {
    return (
      label: 'À compléter',
      badgeVariant: PokeMapBadgeVariant.warning,
      canApply: false,
      reason: targetLoading
          ? 'Chargement de la map cible.'
          : 'Saisissez un décalage entier.',
    );
  }
  if (!preview.hasOverlap) {
    return (
      label: 'À compléter',
      badgeVariant: PokeMapBadgeVariant.warning,
      canApply: false,
      reason: 'Le décalage ne laisse aucun recouvrement.',
    );
  }
  return (
    label: 'Valide',
    badgeVariant: PokeMapBadgeVariant.success,
    canApply: true,
    reason: null,
  );
}

MapConnection? _connectionFor(
  MapData map,
  MapConnectionDirection direction,
) {
  for (final connection in map.connections) {
    if (connection.direction == direction) return connection;
  }
  return null;
}

int _compareMapEntries(ProjectMapEntry left, ProjectMapEntry right) {
  final order = left.sortOrder.compareTo(right.sortOrder);
  if (order != 0) return order;
  return left.name.toLowerCase().compareTo(right.name.toLowerCase());
}

String _directionLabel(MapConnectionDirection direction) => switch (direction) {
      MapConnectionDirection.north => 'Nord',
      MapConnectionDirection.east => 'Est',
      MapConnectionDirection.south => 'Sud',
      MapConnectionDirection.west => 'Ouest',
    };

IconData _directionIcon(MapConnectionDirection direction) =>
    switch (direction) {
      MapConnectionDirection.north => Icons.arrow_upward,
      MapConnectionDirection.east => Icons.arrow_forward,
      MapConnectionDirection.south => Icons.arrow_downward,
      MapConnectionDirection.west => Icons.arrow_back,
    };

final TextInputFormatter _signedIntegerFormatter =
    TextInputFormatter.withFunction((oldValue, newValue) {
  return RegExp(r'^-?\d*$').hasMatch(newValue.text) ? newValue : oldValue;
});
