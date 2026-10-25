import 'dart:async';

import 'package:flutter/material.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core_domain.dart';

import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/feedback/studio_notice.dart';
import '../../shared/widgets/inputs/studio_draft_field.dart';
import '../../shared/widgets/inputs/studio_select.dart';
import '../../shared/widgets/layout/studio_panel.dart';
import 'event_condition_labels.dart';

class StandardEventTemplateForm extends StatefulWidget {
  const StandardEventTemplateForm({
    super.key,
    required this.project,
    required this.maps,
    required this.itemOptions,
    required this.onSave,
    required this.onAdvanced,
    required this.onCancel,
    this.initial,
    this.initialMapId,
    this.initialEntityId,
    this.loadMap,
  });

  final ProjectManifest project;
  final List<MapData> maps;
  final Map<String, String> itemOptions;
  final StandardEventTemplateSpec? initial;
  final String? initialMapId;
  final String? initialEntityId;
  final Future<MapData> Function(String)? loadMap;
  final Future<bool> Function(StandardEventTemplateSpec) onSave;
  final ValueChanged<String> onAdvanced;
  final VoidCallback onCancel;

  @override
  State<StandardEventTemplateForm> createState() =>
      _StandardEventTemplateFormState();
}

class _StandardEventTemplateFormState extends State<StandardEventTemplateForm> {
  static const _kindLabels = {
    StandardEventTemplateKind.conditionalNpc: 'PNJ selon un état du monde',
    StandardEventTemplateKind.pickup: 'Objet à ramasser une fois',
    StandardEventTemplateKind.lockedDoor: 'Porte nécessitant un objet',
    StandardEventTemplateKind.trainer: 'Dresseur avec dialogues avant et après',
  };
  late StandardEventTemplateKind _kind;
  String? _mapId;
  String? _entityId;
  String _name = '';
  final _parameters = <String, Object?>{};
  bool _owned = false;
  bool _reusing = false;
  bool _busy = false;
  bool _simulated = false;
  String? _error;
  final _loadedMaps = <String, MapData>{};
  int _readingMaps = 0;

  List<MapData> get _maps => {
    for (final map in widget.maps) map.id: map,
    ..._loadedMaps,
  }.values.toList(growable: false);

  @override
  void initState() {
    super.initState();
    _kind = widget.initial?.kind ?? StandardEventTemplateKind.conditionalNpc;
    _mapId =
        widget.initialMapId ??
        widget.initial?.mapId ??
        widget.project.maps.firstOrNull?.id;
    _entityId = widget.initialEntityId ?? widget.initial?.entityId;
    if (widget.initial case final initial?) {
      _load(initial);
    } else {
      _readOwner();
    }
    if (_mapId case final id?) unawaited(_loadMap(id));
    if (_parameters['destinationMapId'] case final String id) {
      unawaited(_loadMap(id));
    }
  }

  MapData? get _map => _maps.where((map) => map.id == _mapId).firstOrNull;

  Future<void> _loadMap(String id) async {
    if (_maps.any((map) => map.id == id)) return;
    final load = widget.loadMap;
    if (load == null) return;
    _readingMaps++;
    setState(() => _busy = true);
    try {
      final loaded = await load(id);
      if (loaded.id != id) {
        throw StateError('La carte chargée ne correspond pas au choix.');
      }
      if (mounted) {
        setState(() {
          _loadedMaps[id] = loaded;
          _error = null;
          if (_mapId == id) _readOwner();
        });
      }
    } catch (failure) {
      if (mounted) setState(() => _error = failure.toString());
    } finally {
      _readingMaps--;
      if (mounted) setState(() => _busy = _readingMaps > 0);
    }
  }

  void _load(StandardEventTemplateSpec spec) {
    _kind = spec.kind;
    _mapId = spec.mapId;
    _entityId = spec.entityId;
    _name = spec.name;
    _parameters
      ..clear()
      ..addAll(spec.parameters);
    _owned = true;
    _reusing = false;
    _simulated = false;
    _error = null;
  }

  void _readOwner() {
    final map = _map;
    _owned = false;
    _error = null;
    if (map == null || _entityId == null) return;
    final existing = readStandardEventTemplate(
      project: widget.project,
      map: map,
      entityId: _entityId!,
    );
    if (existing != null) {
      _load(existing);
      return;
    }
    final entity = map.entities
        .where((entity) => entity.id == _entityId)
        .firstOrNull;
    if (!_reusing && entity != null) _name = entity.name;
  }

  StandardEventTemplateSpec get _spec {
    if (_mapId == null || _entityId == null || _name.trim().isEmpty) {
      throw StateError(
        'Choisissez une carte, une entité et un nom pour cet événement.',
      );
    }
    if (StandardEventTemplateSpec.requiredParameterFields[_kind]!.any(
      (key) => !_parameters.containsKey(key),
    )) {
      throw StateError(
        'Complétez les sélections nécessaires à ce comportement.',
      );
    }
    final item = _parameters['itemId'];
    if (item != null && !widget.itemOptions.containsKey(item)) {
      throw StateError(
        widget.itemOptions.isEmpty
            ? 'Le catalogue des objets est indisponible. Rechargez-le avant d’enregistrer cet événement.'
            : 'L’objet choisi ne figure plus dans le catalogue. Sélectionnez un objet disponible.',
      );
    }
    return StandardEventTemplateSpec(
      kind: _kind,
      mapId: _mapId!,
      entityId: _entityId!,
      name: _name.trim(),
      parameters: Map.of(_parameters),
    );
  }

  GameState _simulation(StandardEventTemplateProjection projection) {
    final factId = _parameters['factId'] as String?;
    final itemId = _parameters['itemId'] as String?;
    final trainerId = _parameters['trainerId'] as String?;
    return GameState(
      saveId: 'standard-event-preview',
      currentMapId: _mapId ?? '',
      narrativeFactRuntimeState: NarrativeFactRuntimeState(
        overridesByFactId: factId == null ? const {} : {factId: _simulated},
      ),
      bag: Bag(
        entries: [
          if (itemId != null && _simulated)
            BagEntry(itemId: itemId, quantity: 1),
        ],
      ),
      storyFlags: StoryFlags(
        activeFlags: {
          if (trainerId != null && _simulated) 'trainer_defeated:$trainerId',
        },
      ),
      narrativeEventProgress: NarrativeEventProgress(
        consumedNarrativeEventIds:
            _kind == StandardEventTemplateKind.pickup && _simulated
            ? projection.events.map((event) => event.id)
            : const [],
      ),
    );
  }

  Future<void> _save(
    StandardEventTemplateSpec spec, {
    String? advancedSceneId,
  }) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final saved = await widget.onSave(spec);
      if (mounted && !saved) {
        setState(
          () => _error =
              'L’enregistrement a été refusé. Vos réglages restent ici.',
        );
      }
      if (mounted && saved) {
        if (advancedSceneId != null) {
          widget.onAdvanced(advancedSceneId);
        } else {
          widget.onCancel();
        }
      }
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _reference(
    String key,
    String label,
    Map<String, String> options, {
    bool optional = false,
  }) => Padding(
    padding: const EdgeInsets.only(top: 12),
    child: StudioSelect(
      key: ValueKey('standard-event-$key'),
      label: label,
      value: _parameters[key] as String? ?? (optional ? '' : null),
      options: {if (optional) '': 'Aucun', ...options},
      onChanged: _busy
          ? null
          : (value) async {
              setState(() {
                _error = null;
                if (optional && value.isEmpty) {
                  _parameters.remove(key);
                } else {
                  _parameters[key] = value;
                }
              });
              if (key == 'destinationMapId') await _loadMap(value);
            },
    ),
  );

  @override
  Widget build(BuildContext context) {
    StandardEventTemplateProjection? projection;
    StandardEventTemplateSpec? spec;
    String? problem;
    try {
      spec = _spec;
      projection = compileStandardEventTemplate(
        project: widget.project,
        maps: _maps,
        spec: spec,
      );
    } catch (error) {
      problem = error.toString();
    }
    final characters = {
      for (final entry in widget.project.characters) entry.id: entry.name,
    };
    final dialogues = {
      for (final entry in widget.project.dialogues) entry.id: entry.name,
    };
    final destination = _maps
        .where((map) => map.id == _parameters['destinationMapId'])
        .firstOrNull;
    final preview = projection?.preview(
      project: widget.project,
      gameState: _simulation(projection),
    );
    final sceneIds =
        projection?.scenes.map((scene) => scene.id).toList() ??
        [
          for (final record
              in widget.project.eventRegistry?.records ??
                  <NarrativeEventRecord>[])
            if (_mapId != null &&
                _entityId != null &&
                record.definitionOrNull?.source ==
                    NarrativeEventSourceRef.entityInteract(_mapId!, _entityId!))
              record.definitionOrNull!.sceneId,
        ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const StudioNotice(
                  'Un seul événement : ses scènes, son apparence, ses collisions et ses états sont enregistrés ensemble. Les ressources choisies restent partagées.',
                ),
                const SizedBox(height: 12),
                StudioSelect(
                  key: const ValueKey('standard-event-kind'),
                  label: 'Comportement',
                  value: _kind.name,
                  options: {
                    for (final entry in _kindLabels.entries)
                      entry.key.name: entry.value,
                  },
                  onChanged: _busy || _owned
                      ? null
                      : (value) => setState(() {
                          _kind = StandardEventTemplateKind.values.byName(
                            value,
                          );
                          _parameters.clear();
                          if (_kind == StandardEventTemplateKind.pickup) {
                            _parameters['quantity'] = 1;
                          }
                          _error = null;
                        }),
                ),
                const SizedBox(height: 12),
                StudioSelect(
                  key: const ValueKey('standard-event-map'),
                  label: 'Carte',
                  value: _mapId,
                  options: {
                    for (final map in widget.project.maps) map.id: map.name,
                  },
                  onChanged: _busy
                      ? null
                      : (value) async {
                          setState(() {
                            _mapId = value;
                            _entityId = null;
                            _owned = false;
                            _error = null;
                          });
                          await _loadMap(value);
                        },
                ),
                const SizedBox(height: 12),
                StudioSelect(
                  key: const ValueKey('standard-event-entity'),
                  label: 'Entité placée sur la carte',
                  value: _entityId,
                  options: {
                    for (final entity in _map?.entities ?? <MapEntity>[])
                      entity.id: entity.name,
                  },
                  onChanged: _busy
                      ? null
                      : (value) => setState(() {
                          _entityId = value;
                          _readOwner();
                        }),
                ),
                const SizedBox(height: 12),
                StudioDraftField(
                  key: const ValueKey('standard-event-name'),
                  label: 'Nom de l’événement',
                  value: _name,
                  enabled: !_busy,
                  onChanged: (value) => setState(() => _name = value),
                ),
                _reference(
                  'characterId',
                  'Apparence',
                  characters,
                  optional: _kind == StandardEventTemplateKind.lockedDoor,
                ),
                if (_kind == StandardEventTemplateKind.conditionalNpc) ...[
                  _reference('factId', 'État du monde qui change le PNJ', {
                    for (final fact in widget.project.facts)
                      if (fact.valueKind == NarrativeValueKind.boolean)
                        fact.id: fact.label,
                  }),
                  _reference(
                    'dialogueId',
                    'Dialogue avant le changement',
                    dialogues,
                  ),
                  _reference(
                    'alternateDialogueId',
                    'Dialogue après le changement',
                    dialogues,
                  ),
                  _reference(
                    'alternateCharacterId',
                    'Autre apparence après le changement',
                    characters,
                    optional: true,
                  ),
                ],
                if (_kind == StandardEventTemplateKind.pickup ||
                    _kind == StandardEventTemplateKind.lockedDoor)
                  _reference(
                    'itemId',
                    _kind == StandardEventTemplateKind.pickup
                        ? 'Objet donné'
                        : 'Objet nécessaire dans le sac',
                    widget.itemOptions,
                  ),
                if (_kind == StandardEventTemplateKind.pickup) ...[
                  const SizedBox(height: 12),
                  StudioDraftField(
                    key: const ValueKey('standard-event-quantity'),
                    label: 'Quantité donnée',
                    value: '${_parameters['quantity'] ?? 1}',
                    enabled: !_busy,
                    onChanged: (value) => setState(
                      () => _parameters['quantity'] =
                          int.tryParse(value) ?? value,
                    ),
                  ),
                  _reference(
                    'dialogueId',
                    'Dialogue après réception',
                    dialogues,
                    optional: true,
                  ),
                ],
                if (_kind == StandardEventTemplateKind.lockedDoor) ...[
                  _reference(
                    'dialogueId',
                    'Dialogue si la porte est verrouillée',
                    dialogues,
                  ),
                  _reference('destinationMapId', 'Carte de destination', {
                    for (final map in widget.project.maps) map.id: map.name,
                  }),
                  _reference('destinationWarpId', 'Point d’arrivée', {
                    for (final warp in destination?.warps ?? <MapWarp>[])
                      warp.id: 'Arrivée en ${warp.pos.x}, ${warp.pos.y}',
                  }),
                  const SizedBox(height: 8),
                  const Text(
                    'L’objet est vérifié dans le sac et conservé après le passage.',
                  ),
                ],
                if (_kind == StandardEventTemplateKind.trainer) ...[
                  _reference('trainerId', 'Dresseur du catalogue Avelune', {
                    for (final trainer in widget.project.trainers)
                      trainer.id: trainer.name,
                  }),
                  _reference(
                    'dialogueId',
                    'Dialogue avant le combat',
                    dialogues,
                  ),
                  _reference(
                    'alternateDialogueId',
                    'Dialogue après la victoire',
                    dialogues,
                  ),
                ],
                const SizedBox(height: 16),
                StudioPanel(
                  title: 'Pages et conséquences',
                  children: [
                    if (projection != null) ...[
                      for (final page in projection.pages) ...[
                        Text(
                          page.label,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        Text(
                          eventExpressionLabel(
                            page.condition,
                            widget.project.facts,
                            [
                              ...?widget.project.eventRegistry?.records,
                              ...projection.events,
                            ],
                          ),
                        ),
                        Text(page.actions.join(' · ')),
                        Text(
                          'Collision : ${page.appearance.blocksMovement ? 'bloquante' : 'libre'}',
                        ),
                        const SizedBox(height: 8),
                      ],
                      StudioSelect(
                        key: const ValueKey('standard-event-simulation'),
                        label: 'État à prévisualiser',
                        value: _simulated.toString(),
                        options: switch (_kind) {
                          StandardEventTemplateKind.conditionalNpc => const {
                            'false': 'État désactivé',
                            'true': 'État activé',
                          },
                          StandardEventTemplateKind.pickup => const {
                            'false': 'Objet disponible',
                            'true': 'Objet déjà ramassé',
                          },
                          StandardEventTemplateKind.lockedDoor => const {
                            'false': 'Sans l’objet nécessaire',
                            'true': 'Avec l’objet nécessaire',
                          },
                          StandardEventTemplateKind.trainer => const {
                            'false': 'Avant la victoire',
                            'true': 'Dresseur déjà vaincu',
                          },
                        },
                        onChanged: _busy
                            ? null
                            : (value) =>
                                  setState(() => _simulated = value == 'true'),
                      ),
                      const SizedBox(height: 8),
                      if (preview != null) ...[
                        Text(
                          preview.label,
                          key: const ValueKey('standard-event-active-page'),
                        ),
                        Text(preview.reason),
                        Text(preview.actions.join(' · ')),
                        Text(
                          preview.visible
                              ? 'Entité visible'
                              : 'Entité masquée et collision retirée',
                        ),
                      ],
                      const Text(
                        'Aperçu simulé : aucune sauvegarde joueur n’est modifiée.',
                      ),
                    ],
                    if (problem != null)
                      StudioNotice(
                        problem,
                        key: const ValueKey('standard-event-problem'),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                StudioButton(
                  key: const ValueKey('standard-event-reuse'),
                  label: 'Réutiliser sur une autre entité',
                  secondary: true,
                  onPressed: _busy || spec == null
                      ? null
                      : () => setState(() {
                          _entityId = null;
                          _owned = false;
                          _reusing = true;
                          _error = null;
                        }),
                ),
                for (final sceneId in sceneIds.toSet()) ...[
                  const SizedBox(height: 8),
                  StudioButton(
                    label: projection != null
                        ? 'Enregistrer et ouvrir les actions avancées'
                        : 'Consulter les actions enregistrées sans appliquer ces réglages',
                    secondary: true,
                    onPressed: _busy
                        ? null
                        : projection != null && spec != null
                        ? () => _save(spec!, advancedSceneId: sceneId)
                        : () => widget.onAdvanced(sceneId),
                  ),
                ],
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: StudioNotice(_error!),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.end,
          children: [
            StudioButton(
              label: 'Fermer',
              secondary: true,
              onPressed: _busy ? null : widget.onCancel,
            ),
            StudioButton(
              key: const ValueKey('standard-event-save'),
              label: _busy ? 'Enregistrement…' : 'Enregistrer cet événement',
              onPressed: _busy || projection == null || spec == null
                  ? null
                  : () => _save(spec!),
            ),
          ],
        ),
      ],
    );
  }
}
