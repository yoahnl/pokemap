import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/feedback/studio_notice.dart';
import '../../shared/widgets/inputs/studio_draft_field.dart';
import '../../shared/widgets/inputs/studio_select.dart';
import '../../shared/widgets/inputs/studio_toggle_row.dart';

class SceneWorldVisualActionForm extends StatefulWidget {
  const SceneWorldVisualActionForm({
    super.key,
    required this.current,
    required this.onApply,
    this.loadVisualMedia,
  });
  final SceneActionPayload? current;
  final ValueChanged<SceneNodePayload> onApply;
  final Future<ProjectMediaCatalog> Function()? loadVisualMedia;
  @override
  State<SceneWorldVisualActionForm> createState() =>
      _SceneWorldVisualActionFormState();
}

class _SceneWorldVisualActionFormState
    extends State<SceneWorldVisualActionForm> {
  final _values = <String, String>{};
  ProjectMediaCatalog? _catalog;
  String? _error;
  int _request = 0;
  String get _operation => _values['operation']!;
  bool get _picture =>
      _operation == 'showPicture' || _operation == 'movePicture';
  bool get _framed => _picture || _operation == 'shake';
  @override
  void initState() {
    super.initState();
    _read();
    _load();
  }

  @override
  void didUpdateWidget(SceneWorldVisualActionForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.current != widget.current) {
      _read();
    }
    if (oldWidget.loadVisualMedia != widget.loadVisualMedia) {
      _load();
    }
  }

  void _read() {
    _values.clear();
    _defaults('showPicture');
    final command = widget.current?.interactiveCommand;
    if (command is SceneWorldPresentationInteractiveCommand) {
      _defaults(command.operation.name);
      for (final entry in command.toJson().entries) {
        if (entry.key != 'kind') {
          _values[entry.key] = '${entry.value}';
        }
      }
    }
  }

  void _defaults(String operation) {
    final scope = _values['scope'] ?? 'map';
    _values
      ..clear()
      ..addAll({
        'operation': operation,
        'scope': scope,
        'slotId': '1',
        'referenceWidth': '512',
        'referenceHeight': '384',
        'x': '0',
        'y': '0',
        'scaleX': '1',
        'scaleY': '1',
        'opacity': '1',
        'origin': 'topLeft',
        'red': '255',
        'green': '255',
        'blue': '255',
        'alpha': '255',
        'power': '8',
        'speed': '3',
        'durationMs': operation == 'flash' || operation == 'shake'
            ? '500'
            : '0',
        'waitForCompletion': 'false',
      });
  }

  Future<void> _load() async {
    final request = ++_request;
    _catalog = null;
    _error = null;
    final load = widget.loadVisualMedia;
    if (load == null) {
      return;
    }
    try {
      final catalog = await load();
      if (mounted && request == _request) {
        setState(() => _catalog = catalog);
      }
    } on Object {
      if (mounted && request == _request) {
        setState(
          () => _error = 'La médiathèque est indisponible. La référence enregistrée est conservée.',
        );
      }
    }
  }

  Map<String, String> get _images => {
    for (final media in _catalog?.entries ?? const <ProjectMediaAsset>[])
      if (media.kind == ProjectMediaKind.image) media.id: media.label,
  };
  Map<String, String> get _parameters => {
    for (final entry in _values.entries)
      if (const {
            'operation',
            'scope',
            'durationMs',
            'waitForCompletion',
          }.contains(entry.key) ||
          ((_picture || _operation == 'erasePicture') &&
              entry.key == 'slotId') ||
          (_operation == 'showPicture' && entry.key == 'mediaAssetId') ||
          (_framed &&
              const {
                'referenceWidth',
                'referenceHeight',
              }.contains(entry.key)) ||
          (_picture &&
              const {
                'x',
                'y',
                'scaleX',
                'scaleY',
                'opacity',
                'origin',
              }.contains(entry.key)) ||
          (_operation == 'flash' &&
              const {'red', 'green', 'blue', 'alpha'}.contains(entry.key)) ||
          (_operation == 'shake' &&
              const {'power', 'speed'}.contains(entry.key)))
        entry.key: entry.value,
  };
  SceneNodePayload? get _payload {
    if (_operation == 'showPicture' &&
        !_images.containsKey(_values['mediaAssetId'])) {
      return null;
    }
    try {
      return buildScenePayloadForNarrativeCommand(
        commandId: NarrativeCommandIds.worldPresentation,
        parameters: _parameters,
      );
    } on Object {
      return null;
    }
  }

  Widget _select(String key, String label, Map<String, String> options) =>
      Padding(
        padding: const EdgeInsets.only(top: 12),
        child: StudioSelect(
          label: label,
          value: options.containsKey(_values[key]) ? _values[key] : null,
          options: options,
          onChanged: (value) => setState(() {
            if (key == 'operation') {
              _defaults(value);
            } else {
              _values[key] = value;
            }
          }),
        ),
      );
  Widget _field(String key, String label, {String? help}) => Padding(
    padding: const EdgeInsets.only(top: 12),
    child: StudioDraftField(
      key: ValueKey('world-visual-$key'),
      label: label,
      value: _values[key] ?? '',
      helperText: help,
      keyboardType: const TextInputType.numberWithOptions(
        decimal: true,
        signed: true,
      ),
      onChanged: (value) => setState(() => _values[key] = value),
    ),
  );
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _select('operation', 'Effet', const {
        'showPicture': 'Afficher une image',
        'movePicture': 'Déplacer une image',
        'erasePicture': 'Effacer une image',
        'flash': 'Flash coloré',
        'shake': 'Secouer l’écran',
      }),
      _select('scope', 'Durée de présence', const {
        'scene': 'Scène',
        'map': 'Carte',
      }),
      const StudioNotice(
        'Scène : disparaît à sa fin. Carte : reste jusqu’au changement de carte. Les effets sont suspendus pendant une présentation ou un combat.',
      ),
      if (_picture || _operation == 'erasePicture')
        _field(
          'slotId',
          'Emplacement de l’image',
          help: 'De 1 à 100. Déplacer ou effacer reprend le même emplacement et la même portée.',
        ),
      if (_operation == 'showPicture') ...[
        _select('mediaAssetId', 'Image', _images),
        if (_images.isEmpty)
          const StudioNotice(
            'Importez une image dans la médiathèque de présentation pour la sélectionner ici.',
          ),
        if (_values['mediaAssetId'] != null &&
            !_images.containsKey(_values['mediaAssetId']))
          const StudioNotice(
            'L’image enregistrée est indisponible. Choisissez une image disponible.',
            isError: true,
          ),
        if (_error != null) StudioNotice(_error!, isError: true),
      ],
      if (_framed) ...[
        _field('referenceWidth', 'Largeur du cadre (px)'),
        _field(
          'referenceHeight',
          'Hauteur du cadre (px)',
          help:
              'Le cadre garde ses proportions et reste centré dans le Player.',
        ),
      ],
      if (_picture) ...[
        _select('origin', 'Origine', const {
          'topLeft': 'Coin supérieur gauche',
          'center': 'Centre',
        }),
        _field('x', 'Position horizontale (px)'),
        _field('y', 'Position verticale (px)'),
        _field('scaleX', 'Échelle horizontale'),
        _field('scaleY', 'Échelle verticale'),
        _field('opacity', 'Opacité', help: 'De 0 à 1.'),
      ],
      if (_operation == 'flash') ...[
        for (final entry in const {
          'red': 'Rouge',
          'green': 'Vert',
          'blue': 'Bleu',
          'alpha': 'Intensité',
        }.entries)
          _field(entry.key, entry.value, help: 'De 0 à 255.'),
      ],
      if (_operation == 'shake') ...[
        _field('power', 'Amplitude (px)', help: 'De 0 à 128 pixels du cadre.'),
        _field(
          'speed',
          'Fréquence (Hz)',
          help: 'De 0,1 à 60 oscillations par seconde.',
        ),
      ],
      if (_operation == 'movePicture' ||
          _operation == 'flash' ||
          _operation == 'shake') ...[
        _field(
          'durationMs',
          'Durée (ms)',
          help: 'Jusqu’à 60 000 ms, sur le temps de simulation.',
        ),
        StudioToggleRow(
          label: 'Attendre la fin',
          value: _values['waitForCompletion'] == 'true',
          onChanged: (value) =>
              setState(() => _values['waitForCompletion'] = '$value'),
        ),
      ],
      const SizedBox(height: 12),
      StudioButton(
        label: widget.current == null
            ? 'Ajouter l’action'
            : 'Appliquer l’action',
        onPressed: _payload == null ? null : () => widget.onApply(_payload!),
      ),
    ],
  );
}
