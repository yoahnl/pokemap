import 'dart:convert';

import 'package:map_core/map_core_domain.dart';

class SceneWorldVisualDraft {
  SceneWorldVisualDraft({
    required this.current,
    required this.changed,
    this.loadVisualMedia,
  }) {
    read();
    reloadMedia();
  }
  SceneActionPayload? current;
  Future<ProjectMediaCatalog> Function()? loadVisualMedia;
  final void Function() changed;
  bool _disposed = false;
  void _update(void Function() update) {
    if (_disposed) return;
    update();
    changed();
  }

  void configure({
    required SceneActionPayload? current,
    required Future<ProjectMediaCatalog> Function()? loadVisualMedia,
  }) {
    final reread = this.current != current;
    final reload = this.loadVisualMedia != loadVisualMedia;
    this.current = current;
    this.loadVisualMedia = loadVisualMedia;
    if (reread) read();
    if (reload) reloadMedia();
  }

  void dispose() {
    _disposed = true;
    _request++;
  }

  final values = <String, String>{};
  SpatialVisualPatch visual = SpatialVisualPatch({
    SpatialVisualParameter.depthOfFieldEnabled: true,
  });
  ProjectMediaCatalog? catalog;
  String? error;
  int _request = 0;
  String get operation => values['operation']!;
  bool get isPicture =>
      operation == 'showPicture' || operation == 'movePicture';
  bool get isFramed => isPicture || operation == 'shake';
  void read() {
    values.clear();
    defaults('showPicture');
    final command = current?.interactiveCommand;
    if (command is SceneWorldPresentationInteractiveCommand) {
      defaults(command.operation.name);
      visual =
          command.visualSettings ??
          SpatialVisualPatch({
            SpatialVisualParameter.depthOfFieldEnabled: true,
          });
      for (final entry in command.toJson().entries) {
        if (entry.key != 'kind' && entry.key != 'visualSettings') {
          values[entry.key] = '${entry.value}';
        }
      }
    }
  }

  void defaults(String operation) {
    final scope = values['scope'] ?? 'map';
    values
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

  Future<void> reloadMedia() async {
    final request = ++_request;
    catalog = null;
    error = null;
    final load = loadVisualMedia;
    if (load == null) {
      return;
    }
    try {
      final catalog = await load();
      if (!_disposed && request == _request) {
        _update(() => this.catalog = catalog);
      }
    } on Object {
      if (!_disposed && request == _request) {
        _update(
          () => error = 'La médiathèque est indisponible. La référence enregistrée est conservée.',
        );
      }
    }
  }

  Map<String, String> get images => {
    for (final media in catalog?.entries ?? const <ProjectMediaAsset>[])
      if (media.kind == ProjectMediaKind.image) media.id: media.label,
  };
  Map<String, String> get parameters => {
    if (operation == 'atmosphere')
      'visualSettings': jsonEncode(visual.toJson()),
    for (final entry in values.entries)
      if (const {
            'operation',
            'scope',
            'durationMs',
            'waitForCompletion',
          }.contains(entry.key) ||
          ((isPicture || operation == 'erasePicture') &&
              entry.key == 'slotId') ||
          (operation == 'showPicture' && entry.key == 'mediaAssetId') ||
          (isFramed &&
              const {
                'referenceWidth',
                'referenceHeight',
              }.contains(entry.key)) ||
          (isPicture &&
              const {
                'x',
                'y',
                'scaleX',
                'scaleY',
                'opacity',
                'origin',
              }.contains(entry.key)) ||
          (operation == 'flash' &&
              const {'red', 'green', 'blue', 'alpha'}.contains(entry.key)) ||
          (operation == 'shake' &&
              const {'power', 'speed'}.contains(entry.key)))
        entry.key: entry.value,
  };
  SceneNodePayload? get payload {
    if (operation == 'showPicture' &&
        !images.containsKey(values['mediaAssetId'])) {
      return null;
    }
    try {
      return buildScenePayloadForNarrativeCommand(
        commandId: NarrativeCommandIds.worldPresentation,
        parameters: parameters,
      );
    } on Object {
      return null;
    }
  }
}
