import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import 'package:map_player_ui/presentation_renderer.dart';
import '../../features/presentations/application/presentation_preview_transport.dart';
import '../../features/presentations/domain/presentation_port.dart';
import '../../presentation/features/presentations/presentation_workspace_visuals.dart';
import 'presentation_content_store.dart';
import 'presentation_scenario_preview.dart';
import '../../presentation/features/presentations/presentation_scenario_preview.dart';
import 'presentation_frame_bindings.dart';

class StudioPresentationVisuals extends ChangeNotifier
    implements PresentationWorkspaceVisuals {
  StudioPresentationVisuals({
    required this.projectRoot,
    required this.revision,
    required this.catalog,
    this.imports = const [],
  });
  final String projectRoot;
  final String revision;
  final ProjectMediaCatalog catalog;
  final List<PresentationStagedMedia> imports;
  PresentationContentStore? _content;
  PresentationStudioMediaSink? _sink;
  PresentationPreviewTransport? _transport;
  Directory? _temporary;
  Future<void>? _initialization;
  Future<void> _loadingFuture = Future.value();
  Future<void> _releaseFuture = Future.value();
  bool _closed = false, _portrait = false;
  int _generation = 0, _epoch = -1;
  PresentationCinematicAsset? _asset;
  PresentationScenarioPreview? _scenario;
  int _scenarioGeneration = 0;
  @override
  bool loading = false;
  String? _error;
  @override
  String? get diagnostic =>
      _error ?? _sink?.diagnostic ?? _content?.currentDiagnostic;
  int get mediaReads => _content?.reads ?? 0;

  Future<void> _initialize() async {
    final stagedIds = imports.map((item) => item.media.id).toSet();
    final durable = await loadProjectDirectoryPresentationMedia(
      projectRootDirectory: projectRoot,
      allowMissingSources: true,
      suppliedCatalog: ProjectMediaCatalog(
        entries: catalog.entries
            .where((item) => !stagedIds.contains(item.id))
            .toList(),
      ),
    );
    final directory = await Directory.systemTemp.createTemp(
      'avelune_presentation_media_',
    );
    _temporary = directory;
    final uris = <String, Uri>{...?durable?.mediaUris};
    for (final staged in imports) {
      final file = File('${directory.path}/${staged.media.id}.blob');
      await file.writeAsBytes(staged.previewBytes, flush: true);
      uris[staged.media.id] = file.uri;
    }
    if (_closed) return;
    _content = PresentationContentStore(
      projectRoot: projectRoot,
      catalog: catalog,
      mediaUris: uris,
      stagedBytes: {
        for (final item in imports) item.media.id: item.previewBytes,
      },
    );
    _sink = PresentationStudioMediaSink(
      catalog: catalog,
      mediaUris: uris,
      targetPlatform: PresentationMediaTargetPlatform.macos,
      aliases: PresentationMediaAliasStore(
        root: Directory('${directory.path}/aliases'),
      ),
    )..addListener(_mediaChanged);
    _content!.sink = _sink;
  }

  @override
  Future<void> prepare(
    PresentationCinematicAsset asset, {
    required bool portrait,
  }) {
    _loadingFuture = _prepare(asset, portrait);
    return _loadingFuture;
  }

  Future<void> _prepare(PresentationCinematicAsset asset, bool portrait) async {
    if (_closed) return;
    final generation = ++_generation;
    final changedDocument = _asset?.id != asset.id;
    _asset = asset;
    _portrait = portrait;
    _error = null;
    loading = true;
    try {
      if (changedDocument) await release();
      await (_initialization ??= _initialize());
      if (_closed || generation != _generation) return;
      await _content?.prepare(asset, portrait: portrait);
      if (_closed || generation != _generation) return;
      loading = false;
      _syncMedia();
      notifyListeners();
    } on Object catch (error) {
      if (_closed || generation != _generation) return;
      loading = false;
      _error = 'Préparation des médias impossible : $error';
      notifyListeners();
    }
  }

  @override
  Future<void> get settled async {
    await _loadingFuture;
    await _releaseFuture;
    await _sink?.settled;
  }

  @override
  void bindTransport(PresentationPreviewTransport transport) {
    if (identical(_transport, transport)) return;
    _transport?.removeListener(_syncMedia);
    _transport = transport..addListener(_syncMedia);
    _epoch = -1;
    _syncMedia();
  }

  @override
  void setOrientation(bool portrait) {
    if (_closed || portrait == _portrait) return;
    _portrait = portrait;
    final asset = _asset;
    if (asset != null) unawaited(prepare(asset, portrait: portrait));
  }

  void _syncMedia() {
    if (_closed || loading) return;
    final transport = _transport;
    final sink = _sink;
    if (transport == null || sink == null) return;
    if (_epoch != transport.mediaEpoch) {
      _epoch = transport.mediaEpoch;
      final epoch = _epoch;
      _releaseFuture = sink.release().then((_) {
        if (!_closed && epoch == _epoch) _publishMedia();
      });
    } else {
      _publishMedia();
    }
  }

  void _publishMedia() {
    final transport = _transport;
    final asset = transport?.asset;
    if (_closed || transport == null || asset == null) return;
    _sink?.synchronize(
      asset: asset,
      frame: transport.frame,
      orientation: _portrait
          ? PresentationFrameOrientation.portrait
          : PresentationFrameOrientation.landscape,
      running: transport.playing,
    );
  }

  void _mediaChanged() {
    if (!_closed) notifyListeners();
  }

  @override
  Future<void> release() async {
    _epoch = -1;
    await _sink?.release();
  }

  @override
  Widget frame({
    required PresentationCinematicAsset asset,
    required PresentationFrame frame,
    required bool portrait,
    PresentationFrameGeometryController? geometry,
    bool reduceMotion = false,
    bool reduceFlashes = false,
    bool showCaptions = true,
  }) => Theme(
    data: PokeMapPlayerTheme.dark(reducedMotion: reduceMotion),
    child: PresentationFrameRenderer(
      frame: frame,
      orientation: portrait
          ? PresentationFrameOrientation.portrait
          : PresentationFrameOrientation.landscape,
      contentPort: PresentationResponsiveFrameContentPort(
        delegate: _content ?? const _UnavailableContent(),
        bindings: presentationMediaBindings(asset),
      ),
      geometry: geometry,
      reduceMotion: reduceMotion,
      reduceFlashes: reduceFlashes,
      showCaptions: showCaptions,
      orientationOverrides: presentationOrientationOverrides(asset),
    ),
  );

  @override
  Future<PresentationScenarioPreview> createScenarioPreview({
    required ProjectManifest project,
    required String sceneId,
    required PresentationCinematicAsset asset,
    bool portrait = false,
    bool reducedMotion = false,
  }) async {
    final generation = ++_scenarioGeneration;
    _transport?.pause();
    await _scenario?.close();
    await release();
    await (_initialization ??= _initialize());
    if (_closed || generation != _scenarioGeneration) {
      throw StateError('Aperçu remplacé ou fermé');
    }
    final previewProject = project.copyWith(
      presentationCinematics: [
        for (final current in project.presentationCinematics)
          if (current.id == asset.id) asset else current,
        if (!project.presentationCinematics.any(
          (current) => current.id == asset.id,
        ))
          asset,
      ],
    );
    return _scenario = StudioPresentationScenarioPreview(
      projectRoot: projectRoot,
      revision: revision,
      project: previewProject,
      sceneId: sceneId,
      catalog: catalog,
      mediaUris: _content!.mediaUris,
      portrait: portrait,
      reducedMotion: reducedMotion,
    );
  }

  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    _generation++;
    _scenarioGeneration++;
    await _scenario?.close();
    _transport?.removeListener(_syncMedia);
    _sink?.removeListener(_mediaChanged);
    await _loadingFuture;
    await _releaseFuture;
    _sink?.dispose();
    await _sink?.settled;
    final temporary = _temporary;
    if (temporary != null && await temporary.exists()) {
      await temporary.delete(recursive: true);
    }
  }

  @override
  void dispose() {
    unawaited(close());
    super.dispose();
  }
}

class _UnavailableContent implements PresentationFrameContentPort {
  const _UnavailableContent();
  @override
  PresentationVisualResolution resolveVisual({
    required PresentationVisualFrameClip clip,
    required PresentationFrameOrientation orientation,
  }) => const PresentationVisualUnavailable(
    reason: PresentationContentUnavailableReason.missing,
    message: 'Média en cours de chargement',
  );
  @override
  PresentationCaptionResolution resolveCaption({
    required PresentationCaptionFrameClip clip,
    required Locale locale,
  }) => const PresentationCaptionUnavailable(
    reason: PresentationContentUnavailableReason.missing,
    message: 'Sous-titres en cours de chargement',
  );
}
