import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'asset_review_canvas.dart';

class ConverterAssetReviewPanel extends StatefulWidget {
  const ConverterAssetReviewPanel({
    super.key,
    required this.artifacts,
    required this.limits,
    required this.outputMode,
    required this.onModeChanged,
    this.session,
    this.onSessionChanged,
    this.onUnappliedDraftsChanged,
    this.sourceFilePaths = const {},
    this.availableSources = const [],
    this.enabled = true,
  });

  final List<NativeArtifact> artifacts;
  final NativeWriteLimits limits;
  final AssetOutputMode outputMode;
  final ValueChanged<AssetOutputMode> onModeChanged;
  final AssetReviewSession? session;
  final void Function(AssetReviewSession next, Sha256Hash expectedPreviousHash)?
  onSessionChanged;
  final ValueChanged<bool>? onUnappliedDraftsChanged;
  final Map<ConverterId, String> sourceFilePaths;
  final List<SourceImage> availableSources;
  final bool enabled;

  @override
  State<ConverterAssetReviewPanel> createState() =>
      _ConverterAssetReviewPanelState();
}

class _ConverterAssetReviewPanelState extends State<ConverterAssetReviewPanel> {
  Map<String, ui.Image> _images = const {};
  String? _error;
  bool _loading = true;
  int _generation = 0;
  ConverterId? _activeId;
  ConverterId? _partId;
  ConverterId? _sourceId;
  final _selectedCandidates = <ConverterId>{};
  final _geometryDraft = <String, String>{};
  final _partDrafts = <ConverterId, Map<String, String>>{};
  List<AssetCanvasCell> _cells = const [];
  String _nameDraft = '';
  AssetCategory _categoryDraft = AssetCategory.unclassified;
  String _filter = 'all';
  String? _reviewError;
  Sha256Hash? _pendingSessionHash;
  String? _pendingReset;
  ConverterId? _pendingActive;
  bool _draftReported = false;
  bool _operationDrafts = false;
  final _inspectorChanges = ValueNotifier<int>(0);

  String _imageIdentity(ConverterAssetReviewPanel panel) => canonicalHashOf({
    'sources': _sourcesFor(panel).map((s) => s.toJson()).toList(),
    'images':
        panel.artifacts
            .where((a) => a.reference.mediaType == 'image/png')
            .map((a) => a.rawSha256.value)
            .toList()
          ..sort(),
    'maxPixels': panel.limits.maxImagePixels,
    'maxArtifactBytes': panel.limits.maxArtifactBytes,
  }).value;

  List<SourceImage> _sourcesFor(ConverterAssetReviewPanel panel) {
    final byId = <ConverterId, SourceImage>{
      for (final source in panel.availableSources) source.fileId: source,
      for (final candidate
          in panel.session?.frame.candidates ?? <AssetCandidate>[])
        for (final source in candidate.sources) source.fileId: source,
    };
    return byId.values.toList()
      ..sort((a, b) => a.fileId.value.compareTo(b.fileId.value));
  }

  AssetCandidate? get _active {
    for (final candidate
        in widget.session?.activeCandidates ?? <AssetCandidate>[]) {
      if (candidate.candidateId == _activeId) return candidate;
    }
    return null;
  }

  Map<String, String> _candidateGeometry(AssetCandidate candidate) => {
    'width': '${candidate.canvasSize.width}',
    'height': '${candidate.canvasSize.height}',
    'anchorX': '${candidate.anchor.x}',
    'anchorY': '${candidate.anchor.y}',
    'convention': candidate.anchor.convention.name,
  };

  Map<String, String> _partFields(AssetPart part) => {
    'x': '${part.sourceRect.x}',
    'y': '${part.sourceRect.y}',
    'width': '${part.sourceRect.width}',
    'height': '${part.sourceRect.height}',
    'dx': '${part.destinationOffset.x}',
    'dy': '${part.destinationOffset.y}',
    'turns': '${part.quarterTurns}',
    'reflected': '${part.reflected}',
  };

  bool get _metadataDirty {
    final candidate = _active;
    return candidate != null &&
        (_nameDraft != candidate.name || _categoryDraft != candidate.category);
  }

  bool get _geometryDirty {
    final candidate = _active;
    if (candidate == null) return false;
    if (_candidateGeometry(candidate).entries
        .any((e) => _geometryDraft[e.key] != e.value)) {
      return true;
    }
    return candidate.parts.any(
      (part) =>
          _partFields(part).entries
              .any((e) => _partDrafts[part.partId]?[e.key] != e.value),
    );
  }

  bool get _hasDrafts => _metadataDirty || _geometryDirty || _operationDrafts;
  bool get _canMutate =>
      widget.enabled &&
      widget.session != null &&
      widget.onSessionChanged != null;

  void _seed(
    AssetCandidate? candidate, {
    bool metadata = true,
    bool geometry = true,
  }) {
    if (candidate == null) return;
    if (metadata) {
      _nameDraft = candidate.name;
      _categoryDraft = candidate.category;
    }
    if (geometry) {
      _geometryDraft
        ..clear()
        ..addAll(_candidateGeometry(candidate));
      _partDrafts
        ..clear()
        ..addEntries(
          candidate.parts.map((p) => MapEntry(p.partId, _partFields(p))),
        );
    }
    if (!candidate.parts.any((p) => p.partId == _partId)) {
      _partId = candidate.parts.first.partId;
    }
    _sourceId ??= candidate.sources.first.fileId;
  }

  void _notifyDrafts() {
    _refreshInspector();
    final dirty = _hasDrafts;
    if (dirty == _draftReported) return;
    _draftReported = dirty;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onUnappliedDraftsChanged?.call(dirty);
    });
  }

  void _refreshInspector() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _inspectorChanges.value++;
    });
  }

  void _reconcile(ConverterAssetReviewPanel old) {
    final session = widget.session;
    if (session == null) return;
    if (old.session?.canonicalHash == session.canonicalHash) return;
    final accepted = session.canonicalHash == _pendingSessionHash;
    final changedContext =
        old.session?.sessionId != session.sessionId ||
        old.session?.logicalProjectNamespace !=
            session.logicalProjectNamespace ||
        old.session?.sourceSnapshotHash != session.sourceSnapshotHash ||
        old.session?.proposalGenerationHash != session.proposalGenerationHash;
    if (changedContext && !_draftReported) {
      _cells = const [];
      _sourceId = null;
      _partId = null;
      _activeId = session.activeCandidates.firstOrNull?.candidateId;
      _selectedCandidates.clear();
      if (_activeId != null) _selectedCandidates.add(_activeId!);
      _filter = 'all';
      _pendingSessionHash = null;
      _pendingReset = null;
      _pendingActive = null;
    }
    if (accepted && _pendingActive != null) {
      _activeId = _pendingActive;
      _selectedCandidates
        ..clear()
        ..add(_activeId!);
    }
    if (_active == null && !_draftReported) {
      _activeId = session.activeCandidates.firstOrNull?.candidateId;
      _selectedCandidates.removeWhere(
        (id) => !session.activeCandidates.any((c) => c.candidateId == id),
      );
      if (_activeId != null && _selectedCandidates.isEmpty) {
        _selectedCandidates.add(_activeId!);
      }
    }
    if (accepted) {
      _seed(
        _active,
        metadata: _pendingReset != 'geometry',
        geometry: _pendingReset != 'metadata',
      );
      _pendingSessionHash = null;
      _pendingReset = null;
      _pendingActive = null;
      _reviewError = null;
    } else if (!_draftReported) {
      _seed(_active);
    } else {
      _reviewError =
          'La revue a changé. Vos champs non appliqués sont conservés.';
    }
    _notifyDrafts();
  }

  @override
  void initState() {
    super.initState();
    _activeId = widget.session?.activeCandidates.firstOrNull?.candidateId;
    if (_activeId != null) _selectedCandidates.add(_activeId!);
    _seed(_active);
    unawaited(_loadImages());
  }

  @override
  void didUpdateWidget(ConverterAssetReviewPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    _reconcile(oldWidget);
    if (_imageIdentity(oldWidget) != _imageIdentity(widget)) {
      unawaited(_loadImages());
    }
  }

  Future<void> _loadImages() async {
    final generation = ++_generation;
    _loading = true;
    _error = null;
    final loaded = <String, ui.Image>{};
    try {
      final sources = <String, SourceImage>{
        for (final source in _sourcesFor(widget))
          source.contentHash.value: source,
      };
      var pixels = 0;
      for (final entry in sources.entries) {
        final artifact = widget.artifacts.firstWhere(
          (a) =>
              a.reference.mediaType == 'image/png' &&
              a.rawSha256.value == entry.key,
        );
        final dimensions = const NativePngValidator().headerDimensions(
          artifact.bytes,
          limits: widget.limits,
        );
        pixels += dimensions.$1 * dimensions.$2;
        if (pixels > widget.limits.maxImagePixels ||
            dimensions.$1 != entry.value.pixelWidth ||
            dimensions.$2 != entry.value.pixelHeight) {
          throw const FormatException(
            'Les images source dépassent le budget ou ont changé.',
          );
        }
        final codec = await ui.instantiateImageCodec(
          Uint8List.fromList(artifact.bytes),
        );
        try {
          loaded[entry.key] = (await codec.getNextFrame()).image;
        } finally {
          codec.dispose();
        }
      }
      if (!mounted || generation != _generation) {
        for (final image in loaded.values) {
          image.dispose();
        }
        return;
      }
      final previous = _images;
      setState(() {
        _images = Map.unmodifiable(loaded);
        _loading = false;
      });
      _refreshInspector();
      for (final image in previous.values) {
        image.dispose();
      }
    } catch (_) {
      for (final image in loaded.values) {
        image.dispose();
      }
      if (mounted && generation == _generation) {
        setState(() {
          _loading = false;
          _error = 'L’aperçu source est indisponible. L’approbation de ces objets est bloquée.';
        });
        _refreshInspector();
      }
    }
  }

  @override
  void dispose() {
    _generation++;
    _inspectorChanges.dispose();
    for (final image in _images.values) {
      image.dispose();
    }
    super.dispose();
  }

  void _submit(
    AssetReviewSession next, {
    String reset = 'all',
    ConverterId? active,
    required Sha256Hash expectedPreviousHash,
  }) {
    final current = widget.session!;
    if (next.canonicalHash == current.canonicalHash) {
      setState(
        () => _seed(
          _active,
          metadata: reset != 'geometry',
          geometry: reset != 'metadata',
        ),
      );
      _notifyDrafts();
      return;
    }
    _pendingSessionHash = next.canonicalHash;
    _pendingReset = reset;
    _pendingActive = active;
    widget.onSessionChanged!(next, expectedPreviousHash);
  }

  void _command(
    AssetReviewSession Function() command, {
    String reset = 'all',
    ConverterId? active,
  }) {
    final expectedPreviousHash = widget.session!.canonicalHash;
    try {
      _submit(
        command(),
        reset: reset,
        active: active,
        expectedPreviousHash: expectedPreviousHash,
      );
    } catch (error) {
      setState(
        () => _reviewError =
            error is ContractError && error.code.contains('quota')
            ? 'La revue atteint une limite de ressources. Vos corrections actuelles sont conservées.'
            : 'Vérifiez les coordonnées, les dimensions et les références de la sélection. La revue précédente est conservée.',
      );
      _refreshInspector();
    }
  }

  void _editMetadataDraft({String? name, AssetCategory? category}) {
    setState(() {
      if (name != null) _nameDraft = name;
      if (category != null) _categoryDraft = category;
      _reviewError = null;
    });
    _notifyDrafts();
  }

  void _editGeometryDraft(String key, String value, {ConverterId? partId}) {
    setState(() {
      if (partId == null) {
        _geometryDraft[key] = value;
      } else {
        _partDrafts[partId]![key] = value;
      }
      _reviewError = null;
    });
    _notifyDrafts();
  }

  void _applyMetadata() {
    final session = widget.session!;
    final candidate = _active!;
    _command(
      () => session.editMetadata(
        candidateId: candidate.candidateId,
        expectedCandidateHash: candidate.canonicalHash,
        expectedSessionHash: session.canonicalHash,
        name: _nameDraft,
        category: _categoryDraft,
      ),
      reset: 'metadata',
    );
  }

  AssetReviewGeometry _geometry(
    AssetCandidate candidate,
    List<Map<String, Object?>> parts,
  ) => AssetReviewGeometry(
    parts: parts,
    canvasWidth: int.parse(_geometryDraft['width']!),
    canvasHeight: int.parse(_geometryDraft['height']!),
    anchorX: int.parse(_geometryDraft['anchorX']!),
    anchorY: int.parse(_geometryDraft['anchorY']!),
    anchorConvention: AnchorConvention.values.byName(
      _geometryDraft['convention']!,
    ),
  );

  void _applyGeometry() {
    final session = widget.session!;
    final candidate = _active!;
    _command(() {
      final parts = <Map<String, Object?>>[];
      for (final part in candidate.parts) {
        final fields = _partDrafts[part.partId]!;
        final rect = {
          'x': int.parse(fields['x']!),
          'y': int.parse(fields['y']!),
          'width': int.parse(fields['width']!),
          'height': int.parse(fields['height']!),
        };
        final sourceChanged =
            canonicalHashOf(rect) != canonicalHashOf(part.sourceRect.toJson());
        final sourcePath = widget.sourceFilePaths[part.sourceFileId];
        if (sourceChanged && sourcePath == null) {
          throw const FormatException('Source image path is unavailable');
        }
        parts.add({
          ...part.toJson(),
          'sourceRect': rect,
          'destinationOffset': {
            'x': int.parse(fields['dx']!),
            'y': int.parse(fields['dy']!),
          },
          'quarterTurns': int.parse(fields['turns']!),
          'reflected': fields['reflected'] == 'true',
          if (sourceChanged) ...{
            'sourceLayer': null,
            'sourcePriority': null,
            'locator': {
              'file': sourcePath!,
              'mapId': null,
              'eventId': null,
              'pageIndex': null,
              'commandIndex': null,
              'tileId': null,
              'line': null,
            },
          },
        });
      }
      return session.changeGeometry(
        candidateId: candidate.candidateId,
        expectedCandidateHash: candidate.canonicalHash,
        expectedSessionHash: session.canonicalHash,
        geometry: _geometry(candidate, parts),
      );
    }, reset: 'geometry');
  }

  void _decide(ReviewAction action) {
    final session = widget.session!;
    final candidate = _active!;
    _command(
      () => session.decide(
        candidateId: candidate.candidateId,
        expectedCandidateHash: candidate.canonicalHash,
        expectedSessionHash: session.canonicalHash,
        action: action,
        humanConfirmed: true,
      ),
    );
  }

  void _select(AssetCandidate candidate) {
    setState(() {
      _activeId = candidate.candidateId;
      _partId = null;
      _sourceId = candidate.sources.first.fileId;
      _cells = const [];
      _seed(candidate);
      _reviewError = null;
    });
  }

  void _discardDrafts() {
    setState(() {
      _seed(_active);
      _reviewError = null;
    });
    _notifyDrafts();
  }

  ConverterId _newId(String kind, Object details) => ConverterId(
    'review-$kind-${canonicalHashOf({'session': widget.session!.canonicalHash.value, 'revision': widget.session!.revision, 'details': details}).value.substring(0, 32)}',
  );

  List<AssetCanvasCell> _checkedCells(SourceImage source) {
    if (_cells.isEmpty || _cells.length > 4096) {
      throw const FormatException('Selection exceeds the part budget');
    }
    final cells = _cells.toSet().toList()
      ..sort((a, b) => a.y == b.y ? a.x.compareTo(b.x) : a.y.compareTo(b.y));
    for (final cell in cells) {
      if (cell.x < 0 ||
          cell.y < 0 ||
          (cell.x + 1) * 32 > source.pixelWidth ||
          (cell.y + 1) * 32 > source.pixelHeight) {
        throw const FormatException(
          'Cell is outside the verified source image',
        );
      }
    }
    return cells;
  }

  Map<String, Object?> _cellPart(
    SourceImage source,
    AssetCanvasCell cell, {
    required int dx,
    required int dy,
    required ConverterId id,
  }) => {
    'partId': id.value,
    'sourceFileId': source.fileId.value,
    'sourceRect': {
      'x': cell.x * 32,
      'y': cell.y * 32,
      'width': 32,
      'height': 32,
    },
    'destinationOffset': {'x': dx, 'y': dy},
    'sourceLayer': null,
    'sourcePriority': null,
    'quarterTurns': 0,
    'reflected': false,
    'locator': {
      'file': widget.sourceFilePaths[source.fileId]!,
      'mapId': null,
      'eventId': null,
      'pageIndex': null,
      'commandIndex': null,
      'tileId': null,
      'line': null,
    },
  };

  void _createManual(SourceImage source) {
    final session = widget.session!;
    try {
      final cells = _checkedCells(source);
      final left = cells.map((c) => c.x).reduce(math.min);
      final top = cells.map((c) => c.y).reduce(math.min);
      final width = (cells.map((c) => c.x).reduce(math.max) - left + 1) * 32;
      final height = (cells.map((c) => c.y).reduce(math.max) - top + 1) * 32;
      final id = _newId(
        'manual',
        cells.map((c) => [source.fileId.value, c.x, c.y]).toList(),
      );
      final candidate = AssetCandidate.fromJson({
        'schemaVersion': '1.0',
        'kind': 'assetCandidate',
        'exampleOnly': false,
        'candidateId': id.value,
        'revision': 1,
        'logicalProjectNamespace': session.logicalProjectNamespace.value,
        'sourceSnapshotHash': session.sourceSnapshotHash.value,
        'sources': [source.toJson()],
        'name': 'Nouvel objet manuel',
        'category': 'unclassified',
        'state': 'needsReview',
        'parts': [
          for (final cell in cells)
            _cellPart(
              source,
              cell,
              dx: (cell.x - left) * 32,
              dy: (cell.y - top) * 32,
              id: ConverterId('${id.value}-cell-${cell.x}-${cell.y}'),
            ),
        ],
        'canvasSize': {'width': width, 'height': height},
        'anchor': {
          'unit': 'pixel',
          'x': width ~/ 2,
          'y': height,
          'convention': 'bottomCenter',
        },
        'integrationMode': 'libraryOnly',
        'outputMode': session.outputMode.name,
        'evidence': [
          {
            'type': 'human',
            'summary': 'Cellules sélectionnées explicitement dans les pixels source vérifiés.',
            'reference': widget.sourceFilePaths[source.fileId]!,
          },
        ],
        'uncertainties': [
          'Le nom, la catégorie et les limites restent à vérifier. Aucun placement de carte n’est déduit de cette sélection.',
        ],
        'approvedRevision': null,
      });
      final next = session.createManualCandidate(
        candidate: candidate,
        expectedSessionHash: session.canonicalHash,
      );
      _submit(next, active: id, expectedPreviousHash: session.canonicalHash);
      setState(() => _cells = const []);
    } catch (_) {
      setState(
        () => _reviewError = 'Vérifiez la sélection dans l’image source. Aucun objet existant n’a été modifié.',
      );
    }
  }

  Future<void> _showCommandDialog(WidgetBuilder builder) async {
    setState(() => _operationDrafts = true);
    _notifyDrafts();
    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: builder,
      );
    } finally {
      if (mounted) {
        setState(() => _operationDrafts = false);
        _notifyDrafts();
      }
    }
  }

  void _requireCurrent(AssetReviewSession expected) {
    if (!_canMutate ||
        widget.session?.canonicalHash != expected.canonicalHash ||
        _metadataDirty ||
        _geometryDirty) {
      throw const FormatException('Review changed while the dialog was open');
    }
  }

  String _dialogFailure(AssetReviewSession expected, String message) =>
      widget.session?.canonicalHash != expected.canonicalHash
      ? 'La revue a changé depuis l’ouverture de ce dialogue. Les champs sont conservés ; annulez puis rouvrez la commande.'
      : message;

  Future<void> _addCells(SourceImage source) async {
    final session = widget.session!;
    final candidate = _active!;
    late List<AssetCanvasCell> cells;
    try {
      cells = _checkedCells(source);
      if (!candidate.sources.any(
        (s) => canonicalHashOf(s.toJson()) == canonicalHashOf(source.toJson()),
      )) {
        throw const FormatException(
          'Create a manual candidate for this source first',
        );
      }
    } catch (_) {
      setState(
        () => _reviewError = 'Créez un objet manuel depuis cette image, puis regroupez les objets. La proposition actuelle est conservée.',
      );
      return;
    }
    var x = '0';
    var y = '0';
    String? error;
    await _showCommandDialog(
      (dialogContext) => StatefulBuilder(
        builder: (context, rebuild) => StudioReviewDialog(
          title: 'Ajouter ${cells.length} cellule(s) à l’objet',
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const StudioNotice(
                'Placez ce groupe de cellules dans le canvas de l’objet. Les espaces restent transparents. Si ses dimensions changent, l’ancre garde ses coordonnées et devient explicite si nécessaire.',
              ),
              StudioDraftField(
                key: const ValueKey('asset-add-x'),
                value: x,
                label: 'Position X du groupe (px)',
                keyboardType: const TextInputType.numberWithOptions(
                  signed: true,
                ),
                onChanged: (v) => rebuild(() => x = v),
              ),
              StudioDraftField(
                key: const ValueKey('asset-add-y'),
                value: y,
                label: 'Position Y du groupe (px)',
                keyboardType: const TextInputType.numberWithOptions(
                  signed: true,
                ),
                onChanged: (v) => rebuild(() => y = v),
              ),
              if (error != null) StudioNotice(error!, isError: true),
            ],
          ),
          confirmLabel: 'Ajouter les cellules à vérifier',
          onCancelled: () => Navigator.pop(dialogContext),
          onConfirmed: () {
            try {
              _requireCurrent(session);
              final dx = int.parse(x), dy = int.parse(y);
              final left = cells.map((c) => c.x).reduce(math.min),
                  top = cells.map((c) => c.y).reduce(math.min);
              final width =
                  (cells.map((c) => c.x).reduce(math.max) - left + 1) * 32;
              final height =
                  (cells.map((c) => c.y).reduce(math.max) - top + 1) * 32;
              final additions = [
                for (final cell in cells)
                  _cellPart(
                    source,
                    cell,
                    dx: dx + (cell.x - left) * 32,
                    dy: dy + (cell.y - top) * 32,
                    id: _newId('cell', [
                      candidate.candidateId.value,
                      source.fileId.value,
                      cell.x,
                      cell.y,
                      dx,
                      dy,
                    ]),
                  ),
              ];
              if (candidate.parts.length + additions.length > 4096) {
                throw const FormatException('Part budget exceeded');
              }
              final occupied = candidate.parts
                  .map((p) => _destinationRect(p.toJson()))
                  .toList();
              for (final addition in additions) {
                final rect = _destinationRect(addition);
                if (occupied.any(rect.overlaps)) {
                  throw const FormatException(
                    'Added parts overlap existing destination pixels',
                  );
                }
                occupied.add(rect);
              }
              final parts = [
                ...candidate.parts.map((p) => p.toJson()),
                ...additions,
              ];
              final canvasWidth = math.max(
                    candidate.canvasSize.width,
                    dx + width,
                  ),
                  canvasHeight = math.max(
                    candidate.canvasSize.height,
                    dy + height,
                  );
              final conventionMatches = switch (candidate.anchor.convention) {
                AnchorConvention.topLeft =>
                  candidate.anchor.x == 0 && candidate.anchor.y == 0,
                AnchorConvention.bottomLeft =>
                  candidate.anchor.x == 0 && candidate.anchor.y == canvasHeight,
                AnchorConvention.bottomCenter =>
                  candidate.anchor.x * 2 == canvasWidth &&
                      candidate.anchor.y == canvasHeight,
                AnchorConvention.explicit => true,
              };
              final next = session.changeGeometry(
                candidateId: candidate.candidateId,
                expectedCandidateHash: candidate.canonicalHash,
                expectedSessionHash: session.canonicalHash,
                geometry: AssetReviewGeometry(
                  parts: parts,
                  canvasWidth: canvasWidth,
                  canvasHeight: canvasHeight,
                  anchorX: candidate.anchor.x,
                  anchorY: candidate.anchor.y,
                  anchorConvention: conventionMatches
                      ? candidate.anchor.convention
                      : AnchorConvention.explicit,
                ),
              );
              _submit(next, expectedPreviousHash: session.canonicalHash);
              setState(() => _cells = const []);
              Navigator.pop(dialogContext);
            } catch (_) {
              rebuild(
                () => error = _dialogFailure(
                  session,
                  'Vérifiez les positions : les cellules doivent rester dans le canvas et ne pas recouvrir les morceaux existants.',
                ),
              );
            }
          },
        ),
      ),
    );
  }

  Rect _destinationRect(Map<String, Object?> part) {
    final rect = part['sourceRect']! as Map;
    final offset = part['destinationOffset']! as Map;
    final odd = (part['quarterTurns']! as int).isOdd;
    return Rect.fromLTWH(
      (offset['x'] as int).toDouble(),
      (offset['y'] as int).toDouble(),
      ((odd ? rect['height'] : rect['width']) as int).toDouble(),
      ((odd ? rect['width'] : rect['height']) as int).toDouble(),
    );
  }

  List<Rect> _subtract(Rect source, Rect removed) {
    final cut = source.intersect(removed);
    if (cut.isEmpty) return [source];
    return [
      if (cut.top > source.top)
        Rect.fromLTRB(source.left, source.top, source.right, cut.top),
      if (cut.bottom < source.bottom)
        Rect.fromLTRB(source.left, cut.bottom, source.right, source.bottom),
      if (cut.left > source.left)
        Rect.fromLTRB(source.left, cut.top, cut.left, cut.bottom),
      if (cut.right < source.right)
        Rect.fromLTRB(cut.right, cut.top, source.right, cut.bottom),
    ];
  }

  List<Rect> _cellRegions(List<AssetCanvasCell> cells) {
    final runs = <Rect>[];
    for (final cell in cells) {
      if (runs.isNotEmpty &&
          runs.last.top == cell.y * 32 &&
          runs.last.right == cell.x * 32) {
        final previous = runs.removeLast();
        runs.add(
          Rect.fromLTRB(
            previous.left,
            previous.top,
            (cell.x + 1) * 32.0,
            previous.bottom,
          ),
        );
      } else {
        runs.add(Rect.fromLTWH(cell.x * 32.0, cell.y * 32.0, 32, 32));
      }
    }
    final regions = <Rect>[];
    for (final run in runs) {
      final index = regions.indexWhere(
        (rect) =>
            rect.left == run.left &&
            rect.right == run.right &&
            rect.bottom == run.top,
      );
      if (index < 0) {
        regions.add(run);
      } else {
        regions[index] = Rect.fromLTRB(
          run.left,
          regions[index].top,
          run.right,
          run.bottom,
        );
      }
    }
    return regions;
  }

  Map<String, Object?> _fragment(
    AssetCandidate candidate,
    AssetPart part,
    Rect rect,
  ) {
    final x = rect.left.toInt(),
        y = rect.top.toInt(),
        width = rect.width.toInt(),
        height = rect.height.toInt();
    final original = part.sourceRect;
    final relativeX = part.reflected
        ? original.width - (x - original.x) - width
        : x - original.x;
    final relativeY = y - original.y;
    final (dx, dy) = switch (part.quarterTurns) {
      0 => (relativeX, relativeY),
      1 => (original.height - relativeY - height, relativeX),
      2 => (
        original.width - relativeX - width,
        original.height - relativeY - height,
      ),
      _ => (relativeY, original.width - relativeX - width),
    };
    final sourcePath = widget.sourceFilePaths[part.sourceFileId];
    if (sourcePath == null) {
      throw const FormatException('Original image path is unavailable');
    }
    return {
      ...part.toJson(),
      'partId': _newId('fragment', [
        candidate.candidateId.value,
        part.partId.value,
        x,
        y,
        width,
        height,
      ]).value,
      'sourceRect': {'x': x, 'y': y, 'width': width, 'height': height},
      'destinationOffset': {
        'x': part.destinationOffset.x + dx,
        'y': part.destinationOffset.y + dy,
      },
      'sourceLayer': null,
      'sourcePriority': null,
      'locator': {
        'file': sourcePath,
        'mapId': null,
        'eventId': null,
        'pageIndex': null,
        'commandIndex': null,
        'tileId': null,
        'line': null,
      },
    };
  }

  void _removeCells(SourceImage source) {
    final session = widget.session!;
    final candidate = _active!;
    _command(() {
      final removed = _cellRegions(_checkedCells(source));
      final parts = <Map<String, Object?>>[];
      var changed = false;
      for (final part in candidate.parts) {
        if (part.sourceFileId != source.fileId) {
          parts.add(part.toJson());
          continue;
        }
        final original = Rect.fromLTWH(
          part.sourceRect.x.toDouble(),
          part.sourceRect.y.toDouble(),
          part.sourceRect.width.toDouble(),
          part.sourceRect.height.toDouble(),
        );
        var fragments = [original];
        for (final cut in removed.where((r) => r.overlaps(original))) {
          fragments = fragments.expand((rect) => _subtract(rect, cut)).toList();
          if (parts.length + fragments.length > 4096) {
            throw const FormatException('Part budget exceeded');
          }
        }
        if (fragments.length == 1 && fragments.single == original) {
          parts.add(part.toJson());
          continue;
        }
        changed = true;
        parts.addAll(fragments.map((rect) => _fragment(candidate, part, rect)));
      }
      if (!changed) return session;
      if (parts.isEmpty) {
        setState(
          () => _reviewError = 'Retirer toutes les cellules ne peut pas vider l’objet. Utilisez « Garder les tuiles d’origine » pour refuser ce groupe.',
        );
        return session;
      }
      return session.changeGeometry(
        candidateId: candidate.candidateId,
        expectedCandidateHash: candidate.canonicalHash,
        expectedSessionHash: session.canonicalHash,
        geometry: _geometry(candidate, parts),
      );
    });
  }

  Future<void> _selectionCategoryDialog() async {
    final session = widget.session!;
    final candidates = session.activeCandidates
        .where((c) => _selectedCandidates.contains(c.candidateId))
        .toList();
    var category = candidates.map((c) => c.category).toSet().length == 1
        ? candidates.first.category
        : AssetCategory.unclassified;
    String? error;
    await _showCommandDialog(
      (dialogContext) => StatefulBuilder(
        builder: (context, rebuild) => StudioReviewDialog(
          title: 'Classer ${candidates.length} objets',
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const StudioNotice(
                'Changer la catégorie demande une nouvelle approbation de chaque objet. Les pixels et les placements de carte sont conservés.',
              ),
              for (final candidate in candidates) Text(candidate.name),
              StudioSelect(
                key: const ValueKey('asset-selection-category-value'),
                label: 'Catégorie commune',
                value: category.name,
                options: _categoryOptions,
                onChanged: (v) =>
                    rebuild(() => category = AssetCategory.values.byName(v)),
              ),
              if (error != null) StudioNotice(error!, isError: true),
            ],
          ),
          confirmLabel: 'Classer ${candidates.length} objets',
          onCancelled: () => Navigator.pop(dialogContext),
          onConfirmed: () {
            try {
              _requireCurrent(session);
              var next = session;
              for (final candidate in candidates) {
                next = next.editMetadata(
                  candidateId: candidate.candidateId,
                  expectedCandidateHash: candidate.canonicalHash,
                  expectedSessionHash: next.canonicalHash,
                  category: category,
                );
              }
              _submit(next, expectedPreviousHash: session.canonicalHash);
              Navigator.pop(dialogContext);
            } catch (_) {
              rebuild(
                () => error = _dialogFailure(
                  session,
                  'La catégorie n’a pas pu être appliquée. Tous les objets précédents sont conservés.',
                ),
              );
            }
          },
        ),
      ),
    );
  }

  Future<void> _selectionReviewDialog() async {
    final session = widget.session!;
    final candidates = session.activeCandidates
        .where((c) => _selectedCandidates.contains(c.candidateId))
        .toList();
    final canApprove =
        !_loading &&
        _error == null &&
        candidates.every(
          (c) =>
              c.category != AssetCategory.unclassified &&
              c.name.trim().isNotEmpty &&
              c.integrationMode == IntegrationMode.libraryOnly,
        );
    String? error;
    await _showCommandDialog(
      (dialogContext) => StatefulBuilder(
        builder: (context, rebuild) {
          void decide(ReviewAction action) {
            try {
              _requireCurrent(session);
              var next = session;
              for (final candidate in candidates) {
                next = next.decide(
                  candidateId: candidate.candidateId,
                  expectedCandidateHash: candidate.canonicalHash,
                  expectedSessionHash: next.canonicalHash,
                  action: action,
                  humanConfirmed: true,
                );
              }
              _submit(next, expectedPreviousHash: session.canonicalHash);
              Navigator.pop(dialogContext);
            } catch (_) {
              rebuild(
                () => error = _dialogFailure(
                  session,
                  'La revue n’a pas pu être appliquée à toute la sélection. Les objets précédents sont conservés.',
                ),
              );
            }
          }

          return StudioReviewDialog(
            title: 'Revoir ${candidates.length} objets sélectionnés',
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const StudioNotice(
                  'Cette confirmation concerne les objets affichés. Les placements de carte restent en tuiles d’origine.',
                ),
                for (final candidate in candidates)
                  StudioPanel(
                    compact: true,
                    title: candidate.name,
                    children: [
                      if (!_loading && _error == null)
                        StudioAssetPreview(
                          height: 80,
                          child: AspectRatio(
                            aspectRatio:
                                candidate.canvasSize.width /
                                candidate.canvasSize.height,
                            child: CustomPaint(
                              painter: AssetProposalPainter(candidate, _images),
                            ),
                          ),
                        ),
                      Text(
                        '${_categoryOptions[candidate.category.name] ?? candidate.category.name} · ${candidate.canvasSize.width} × ${candidate.canvasSize.height} px',
                      ),
                      for (final uncertainty in candidate.uncertainties)
                        StudioNotice(uncertainty),
                    ],
                  ),
                if (!canApprove)
                  const StudioNotice(
                    'Vérifiez le nom, la catégorie et les pixels de chaque objet. La substitution des placements source reste bloquée.',
                    isError: true,
                  ),
                if (error != null) StudioNotice(error!, isError: true),
              ],
            ),
            confirmLabel:
                'Valider ${candidates.length} objets pour la bibliothèque',
            onConfirmed: canApprove ? () => decide(ReviewAction.approve) : null,
            cancelLabel: 'Revenir à la revue',
            onCancelled: () => Navigator.pop(dialogContext),
            secondaryActionLabel:
                'Garder les tuiles pour ${candidates.length} objets',
            onSecondaryAction: () => decide(ReviewAction.keepLiteral),
          );
        },
      ),
    );
  }

  Future<void> _unionDialog() async {
    final session = widget.session!;
    final parents = session.activeCandidates
        .where((c) => _selectedCandidates.contains(c.candidateId))
        .toList();
    var name = 'Objets regroupés';
    var category = AssetCategory.object;
    final offsets = <ConverterId, (String, String)>{
      for (final parent in parents) parent.candidateId: ('0', '0'),
    };
    String? error;
    await _showCommandDialog(
      (dialogContext) => StatefulBuilder(
        builder: (context, rebuild) => StudioReviewDialog(
          title: 'Regrouper ${parents.length} objets',
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              const StudioNotice(
                'Indiquez la position de chaque objet dans le nouveau canvas. Les cartes conservent leurs tuiles.',
              ),
              StudioDraftField(
                key: const ValueKey('asset-union-name'),
                value: name,
                label: 'Nom du groupe',
                onChanged: (v) => rebuild(() => name = v),
              ),
              StudioSelect(
                label: 'Catégorie',
                value: category.name,
                options: _categoryOptions,
                onChanged: (v) =>
                    rebuild(() => category = AssetCategory.values.byName(v)),
              ),
              for (final parent in parents)
                StudioPanel(
                  compact: true,
                  title: parent.name,
                  children: [
                    StudioDraftField(
                      key: ValueKey(
                        'asset-union-x-${parent.candidateId.value}',
                      ),
                      value: offsets[parent.candidateId]!.$1,
                      label: 'Position X dans l’objet (px)',
                      onChanged: (v) => rebuild(
                        () => offsets[parent.candidateId] = (
                          v,
                          offsets[parent.candidateId]!.$2,
                        ),
                      ),
                    ),
                    StudioDraftField(
                      key: ValueKey(
                        'asset-union-y-${parent.candidateId.value}',
                      ),
                      value: offsets[parent.candidateId]!.$2,
                      label: 'Position Y dans l’objet (px)',
                      onChanged: (v) => rebuild(
                        () => offsets[parent.candidateId] = (
                          offsets[parent.candidateId]!.$1,
                          v,
                        ),
                      ),
                    ),
                  ],
                ),
              if (error != null) StudioNotice(error!, isError: true),
            ],
          ),
          confirmLabel: 'Créer le groupe à vérifier',
          onCancelled: () => Navigator.pop(dialogContext),
          onConfirmed: () {
            try {
              _requireCurrent(session);
              final id = _newId(
                'union',
                parents.map((c) => c.candidateId.value).toList(),
              );
              final next = session.unionCandidates(
                candidateId: id,
                expectedSessionHash: session.canonicalHash,
                inputs: parents
                    .map(
                      (c) => AssetUnionInput(
                        candidateId: c.candidateId,
                        expectedCandidateHash: c.canonicalHash,
                        offsetX: int.parse(offsets[c.candidateId]!.$1),
                        offsetY: int.parse(offsets[c.candidateId]!.$2),
                      ),
                    )
                    .toList(),
                name: name,
                category: category,
              );
              _submit(
                next,
                active: id,
                expectedPreviousHash: session.canonicalHash,
              );
              Navigator.pop(dialogContext);
            } catch (_) {
              rebuild(
                () => error = 'Vérifiez les positions : les parties doivent rester explicites et ne pas se recouvrir.',
              );
            }
          },
        ),
      ),
    );
  }

  Future<void> _splitDialog() async {
    final session = widget.session!;
    final candidate = _active!;
    final groups = <ConverterId, int>{
      for (final part in candidate.parts) part.partId: 0,
    };
    var groupCount = 2;
    var names = [
      '${candidate.name} — partie 1',
      '${candidate.name} — partie 2',
    ];
    String? error;
    await _showCommandDialog(
      (dialogContext) => StatefulBuilder(
        builder: (context, rebuild) => StudioReviewDialog(
          title: 'Séparer les morceaux de l’objet',
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const StudioNotice(
                'Chaque morceau appartient à un groupe. Aucun morceau ne sera supprimé.',
              ),
              StudioSelect(
                label: 'Nombre de groupes',
                value: '$groupCount',
                options: {
                  for (
                    var i = 2;
                    i <= math.min(candidate.parts.length, 16);
                    i++
                  )
                    '$i': '$i groupes',
                },
                onChanged: (v) => rebuild(() {
                  groupCount = int.parse(v);
                  names = [
                    for (var i = 0; i < groupCount; i++)
                      i < names.length
                          ? names[i]
                          : '${candidate.name} — partie ${i + 1}',
                  ];
                  for (final part in candidate.parts) {
                    if (groups[part.partId]! >= groupCount) {
                      groups[part.partId] = 0;
                    }
                  }
                }),
              ),
              for (var i = 0; i < groupCount; i++)
                StudioDraftField(
                  value: names[i],
                  label: 'Nom du groupe ${i + 1}',
                  onChanged: (v) => rebuild(() => names[i] = v),
                ),
              for (final part in candidate.parts)
                StudioSelect(
                  key: ValueKey('asset-split-group-${part.partId.value}'),
                  label: 'Morceau ${part.partId.value}',
                  value: '${groups[part.partId]}',
                  options: {
                    for (var i = 0; i < groupCount; i++)
                      '$i': 'Groupe ${i + 1}',
                  },
                  onChanged: (v) =>
                      rebuild(() => groups[part.partId] = int.parse(v)),
                ),
              if (error != null) StudioNotice(error!, isError: true),
            ],
          ),
          confirmLabel: 'Créer les objets à vérifier',
          onCancelled: () => Navigator.pop(dialogContext),
          onConfirmed: () {
            try {
              _requireCurrent(session);
              final children = [
                for (var i = 0; i < groupCount; i++)
                  AssetSplitGroup(
                    candidateId: _newId('split', [
                      candidate.candidateId.value,
                      i,
                    ]),
                    partIds: candidate.parts
                        .where((p) => groups[p.partId] == i)
                        .map((p) => p.partId)
                        .toList(),
                    name: names[i],
                    category: candidate.category,
                  ),
              ];
              final next = session.splitCandidate(
                candidateId: candidate.candidateId,
                expectedCandidateHash: candidate.canonicalHash,
                expectedSessionHash: session.canonicalHash,
                groups: children,
              );
              _submit(
                next,
                active: children.first.candidateId,
                expectedPreviousHash: session.canonicalHash,
              );
              Navigator.pop(dialogContext);
            } catch (_) {
              rebuild(
                () => error = 'Chaque groupe doit contenir au moins un morceau ; tous les morceaux doivent être conservés.',
              );
            }
          },
        ),
      ),
    );
  }

  static const _categoryOptions = {
    'unclassified': 'À classer',
    'building': 'Bâtiment',
    'nature': 'Nature',
    'object': 'Objet',
    'terrain': 'Terrain',
    'surface': 'Surface',
  };

  Widget _numericField(
    String key,
    String label,
    String value,
    ValueChanged<String> onChanged, {
    bool enabled = true,
  }) => StudioDraftField(
    key: ValueKey(key),
    value: value,
    label: label,
    keyboardType: const TextInputType.numberWithOptions(signed: true),
    enabled: _canMutate && enabled,
    onChanged: onChanged,
  );

  Widget _inspector() {
    final candidate = _active;
    if (candidate == null) {
      return const StudioEmptyState(
        title: 'Sélectionnez un objet',
        description: 'Vous pouvez aussi sélectionner des cellules source pour créer une proposition manuelle.',
      );
    }
    final part = candidate.parts.firstWhere(
      (p) => p.partId == _partId,
      orElse: () => candidate.parts.first,
    );
    final fields = _partDrafts[part.partId]!;
    final canApprove =
        _canMutate &&
        !_hasDrafts &&
        !_loading &&
        _error == null &&
        candidate.category != AssetCategory.unclassified &&
        candidate.name.trim().isNotEmpty &&
        candidate.integrationMode == IntegrationMode.libraryOnly;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StudioBadge(
          _hasDrafts
              ? 'Modifications à appliquer'
              : switch (candidate.state) {
                  CandidateState.approved => 'Approuvé pour la bibliothèque',
                  CandidateState.keepLiteral => 'Tuiles conservées',
                  _ => 'À revalider',
                },
        ),
        const SizedBox(height: 8),
        if (!_loading && _error == null)
          StudioAssetPreview(
            height: 140,
            child: AspectRatio(
              aspectRatio:
                  candidate.canvasSize.width / candidate.canvasSize.height,
              child: CustomPaint(
                painter: AssetProposalPainter(candidate, _images),
              ),
            ),
          ),
        StudioDraftField(
          key: const ValueKey('asset-review-name'),
          value: _nameDraft,
          label: 'Nom de l’objet',
          enabled: _canMutate,
          onChanged: (v) => _editMetadataDraft(name: v),
        ),
        StudioSelect(
          key: const ValueKey('asset-review-category'),
          label: 'Catégorie',
          value: _categoryDraft.name,
          options: _categoryOptions,
          onChanged: _canMutate
              ? (v) =>
                    _editMetadataDraft(category: AssetCategory.values.byName(v))
              : null,
        ),
        StudioButton(
          key: const ValueKey('asset-apply-metadata'),
          label: 'Appliquer les informations',
          secondary: true,
          onPressed: _canMutate && _metadataDirty ? _applyMetadata : null,
        ),
        const SizedBox(height: 12),
        StudioSelect(
          label: 'Morceau à corriger',
          value: part.partId.value,
          options: {
            for (final p in candidate.parts)
              p.partId.value:
                  '${p.sourceRect.width} × ${p.sourceRect.height} px · ${p.partId.value}',
          },
          onChanged: !_hasDrafts
              ? (v) {
                  setState(() {
                    _partId = ConverterId(v);
                    _sourceId = candidate.parts
                        .firstWhere((p) => p.partId == _partId)
                        .sourceFileId;
                    _cells = const [];
                  });
                  _refreshInspector();
                }
              : null,
        ),
        for (final (key, label, field) in [
          ('asset-part-source-x', 'Source X (px)', 'x'),
          ('asset-part-source-y', 'Source Y (px)', 'y'),
          ('asset-part-source-width', 'Largeur du morceau (px)', 'width'),
          ('asset-part-source-height', 'Hauteur du morceau (px)', 'height'),
          ('asset-part-destination-x', 'Position X dans l’objet (px)', 'dx'),
          ('asset-part-destination-y', 'Position Y dans l’objet (px)', 'dy'),
        ])
          _numericField(
            key,
            label,
            fields[field]!,
            (v) => _editGeometryDraft(field, v, partId: part.partId),
            enabled:
                (field == 'dx' || field == 'dy') ||
                widget.sourceFilePaths.containsKey(part.sourceFileId),
          ),
        StudioSelect(
          label: 'Rotation du morceau',
          value: fields['turns']!,
          options: const {'0': '0°', '1': '90°', '2': '180°', '3': '270°'},
          onChanged: _canMutate
              ? (v) => _editGeometryDraft('turns', v, partId: part.partId)
              : null,
        ),
        StudioToggleRow(
          label: 'Miroir horizontal du morceau',
          value: fields['reflected'] == 'true',
          onChanged: _canMutate
              ? (v) =>
                    _editGeometryDraft('reflected', '$v', partId: part.partId)
              : null,
        ),
        for (final (key, label, field) in [
          ('asset-canvas-width', 'Largeur du canvas (px)', 'width'),
          ('asset-canvas-height', 'Hauteur du canvas (px)', 'height'),
          ('asset-anchor-x', 'Ancre X (px)', 'anchorX'),
          ('asset-anchor-y', 'Ancre Y (px)', 'anchorY'),
        ])
          _numericField(
            key,
            label,
            _geometryDraft[field]!,
            (v) => _editGeometryDraft(field, v),
          ),
        StudioSelect(
          label: 'Convention d’ancre',
          value: _geometryDraft['convention']!,
          options: const {
            'topLeft': 'Coin supérieur gauche',
            'bottomLeft': 'Coin inférieur gauche',
            'bottomCenter': 'Bas au centre',
            'explicit': 'Coordonnées explicites',
          },
          onChanged: _canMutate
              ? (v) => _editGeometryDraft('convention', v)
              : null,
        ),
        StudioButton(
          key: const ValueKey('asset-apply-geometry'),
          label: 'Appliquer la géométrie',
          secondary: true,
          onPressed: _canMutate && _geometryDirty ? _applyGeometry : null,
        ),
        if (_hasDrafts)
          StudioButton(
            key: const ValueKey('asset-discard-drafts'),
            label: 'Abandonner les champs non appliqués',
            secondary: true,
            onPressed: _discardDrafts,
          ),
        const SizedBox(height: 12),
        StudioBadge(
          candidate.integrationMode == IntegrationMode.libraryOnly
              ? 'Bibliothèque seulement'
              : 'Intention de substitution non certifiée',
          icon: candidate.integrationMode == IntegrationMode.libraryOnly
              ? Icons.inventory_2_outlined
              : Icons.block_outlined,
        ),
        Text(
          candidate.integrationMode == IntegrationMode.libraryOnly
              ? 'La carte conserve ses placements source. Aucune collision n’est ajoutée. L’ancre est conservée dans les métadonnées ; son usage pour substituer les placements reste à qualifier.'
              : 'Cette session contient une intention de substitution. Son application et son approbation sont bloquées. Les cartes conservent leurs tuiles source.',
        ),
        const Text('Pourquoi cette proposition ?'),
        for (final evidence in candidate.evidence.take(8))
          Text(evidence.summary),
        for (final uncertainty in candidate.uncertainties)
          StudioNotice(uncertainty),
        StudioButton(
          key: const ValueKey('asset-review-approve'),
          label: 'Valider cet objet',
          onPressed: canApprove ? () => _decide(ReviewAction.approve) : null,
        ),
        const SizedBox(height: 8),
        StudioButton(
          key: const ValueKey('asset-review-keep'),
          label: 'Garder les tuiles d’origine',
          secondary: true,
          onPressed: _canMutate && !_hasDrafts
              ? () => _decide(ReviewAction.keepLiteral)
              : null,
        ),
      ],
    );
  }

  Widget _candidateList() {
    final session = widget.session!;
    final candidates = session.activeCandidates.where(
      (c) =>
          _filter == 'all' ||
          (_filter == 'needsReview' &&
              c.state != CandidateState.approved &&
              c.state != CandidateState.keepLiteral) ||
          c.state.name == _filter ||
          (_filter == 'conflicted' &&
              session.conflicts.any(
                (conflict) => conflict.candidateIds.contains(c.candidateId),
              )),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StudioSelect(
          key: const ValueKey('asset-review-filter'),
          label: 'Afficher les objets',
          value: _filter,
          options: const {
            'all': 'Tous',
            'needsReview': 'À vérifier',
            'approved': 'Approuvés',
            'keepLiteral': 'Tuiles conservées',
            'conflicted': 'Conflits',
          },
          onChanged: (v) => setState(() => _filter = v),
        ),
        Text('${_selectedCandidates.length} objet(s) sélectionné(s)'),
        Expanded(
          child: ListView(
            children: [
              for (final candidate in candidates)
                StudioPanel(
                  compact: true,
                  children: [
                    if (!_loading && _error == null)
                      StudioAssetPreview(
                        height: 56,
                        child: AspectRatio(
                          aspectRatio:
                              candidate.canvasSize.width /
                              candidate.canvasSize.height,
                          child: CustomPaint(
                            painter: AssetProposalPainter(candidate, _images),
                          ),
                        ),
                      ),
                    StudioChoice(
                      key: ValueKey(
                        'asset-open-${candidate.candidateId.value}',
                      ),
                      label: candidate.name,
                      subtitle:
                          '${candidate.canvasSize.width} × ${candidate.canvasSize.height} px · ${candidate.category.name}',
                      selected: candidate.candidateId == _activeId,
                      onTap: !_hasDrafts ? () => _select(candidate) : null,
                    ),
                    StudioToggleRow(
                      key: ValueKey(
                        'asset-select-${candidate.candidateId.value}',
                      ),
                      label: 'Inclure dans le groupe',
                      value: _selectedCandidates.contains(
                        candidate.candidateId,
                      ),
                      onChanged: _canMutate && !_hasDrafts
                          ? (v) => setState(() {
                              v
                                  ? _selectedCandidates.add(
                                      candidate.candidateId,
                                    )
                                  : _selectedCandidates.remove(
                                      candidate.candidateId,
                                    );
                            })
                          : null,
                    ),
                    StudioBadge(
                      switch (candidate.state) {
                        CandidateState.approved => 'Approuvé',
                        CandidateState.keepLiteral => 'Tuiles conservées',
                        _ => 'À vérifier',
                      },
                      icon: switch (candidate.state) {
                        CandidateState.approved => Icons.verified_outlined,
                        CandidateState.keepLiteral => Icons.grid_on_outlined,
                        _ => Icons.pending_outlined,
                      },
                    ),
                    Text(
                      candidate.parts
                          .map((p) => p.locator.file)
                          .toSet()
                          .join(' · '),
                    ),
                  ],
                ),
              if (candidates.isEmpty) const Text('Aucun objet dans ce filtre.'),
              if (session.frame.candidates.any(
                (c) => c.state == CandidateState.superseded,
              ))
                const Text(
                  'Les groupes précédents restent dans l’historique. Annuler permet de les retrouver.',
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _reviewWorkspace(BuildContext context) => Focus(
    canRequestFocus: false,
    onKeyEvent: (_, event) {
      if (event is! KeyDownEvent || _hasDrafts || !_canMutate) {
        return KeyEventResult.ignored;
      }
      final focused = FocusManager.instance.primaryFocus?.context;
      if (focused?.widget is EditableText ||
          focused?.findAncestorWidgetOfExactType<EditableText>() != null) {
        return KeyEventResult.ignored;
      }
      final keyboard = HardwareKeyboard.instance;
      if ((keyboard.isMetaPressed || keyboard.isControlPressed) &&
          event.logicalKey == LogicalKeyboardKey.keyZ) {
        final session = widget.session!;
        if (keyboard.isShiftPressed ? session.canRedo : session.canUndo) {
          _command(
            () => keyboard.isShiftPressed
                ? session.redo(expectedSessionHash: session.canonicalHash)
                : session.undo(expectedSessionHash: session.canonicalHash),
          );
          return KeyEventResult.handled;
        }
      }
      return KeyEventResult.ignored;
    },
    child: LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 1200;
        final sources = _sourcesFor(widget);
        final source =
            sources.where((s) => s.fileId == _sourceId).firstOrNull ??
            sources.firstOrNull;
        final session = widget.session!;
        final textSize = Theme.of(context).textTheme.bodyMedium?.fontSize ?? 14;
        final height = constraints.hasBoundedHeight
            ? (constraints.maxHeight - 80).clamp(460.0, 760.0)
            : 680.0 *
                  MediaQuery.textScalerOf(context).scale(textSize) /
                  textSize;
        return StudioPanel(
          title: 'Revue des objets et corrections',
          children: [
            SizedBox(
              height: height,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Pixels source conservés · bibliothèque seulement · aucune substitution de carte',
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      StudioButton(
                        key: const ValueKey('asset-review-undo'),
                        label: 'Annuler',
                        secondary: true,
                        onPressed: _canMutate && !_hasDrafts && session.canUndo
                            ? () => _command(
                                () => session.undo(
                                  expectedSessionHash: session.canonicalHash,
                                ),
                              )
                            : null,
                      ),
                      StudioButton(
                        key: const ValueKey('asset-review-redo'),
                        label: 'Rétablir',
                        secondary: true,
                        onPressed: _canMutate && !_hasDrafts && session.canRedo
                            ? () => _command(
                                () => session.redo(
                                  expectedSessionHash: session.canonicalHash,
                                ),
                              )
                            : null,
                      ),
                      StudioButton(
                        key: const ValueKey('asset-review-union'),
                        label: 'Regrouper',
                        secondary: true,
                        onPressed:
                            _canMutate &&
                                !_hasDrafts &&
                                _selectedCandidates.length >= 2
                            ? () => unawaited(_unionDialog())
                            : null,
                      ),
                      StudioButton(
                        key: const ValueKey('asset-review-split'),
                        label: 'Séparer',
                        secondary: true,
                        onPressed:
                            _canMutate &&
                                !_hasDrafts &&
                                (_active?.parts.length ?? 0) >= 2
                            ? () => unawaited(_splitDialog())
                            : null,
                      ),
                      StudioButton(
                        key: const ValueKey('asset-selection-category'),
                        label:
                            'Classer la sélection (${_selectedCandidates.length})',
                        secondary: true,
                        onPressed:
                            _canMutate &&
                                !_hasDrafts &&
                                _selectedCandidates.isNotEmpty
                            ? () => unawaited(_selectionCategoryDialog())
                            : null,
                      ),
                      StudioButton(
                        key: const ValueKey('asset-selection-review'),
                        label:
                            'Revoir la sélection (${_selectedCandidates.length})',
                        secondary: true,
                        onPressed:
                            _canMutate &&
                                !_hasDrafts &&
                                _selectedCandidates.isNotEmpty
                            ? () => unawaited(_selectionReviewDialog())
                            : null,
                      ),
                      if (!wide)
                        StudioButton(
                          key: const ValueKey('asset-open-inspector'),
                          label: 'Inspecter l’objet',
                          secondary: true,
                          onPressed: () => showDialog<void>(
                            context: context,
                            builder: (dialogContext) =>
                                ValueListenableBuilder<int>(
                                  valueListenable: _inspectorChanges,
                                  builder: (_, value, child) =>
                                      StudioReviewDialog(
                                        title: 'Inspecter et corriger l’objet',
                                        content: _inspector(),
                                        confirmLabel: 'Fermer',
                                        onConfirmed: () =>
                                            Navigator.pop(dialogContext),
                                        onCancelled: () =>
                                            Navigator.pop(dialogContext),
                                      ),
                                ),
                          ),
                        ),
                    ],
                  ),
                  StudioSelect(
                    key: const ValueKey('asset-output-mode'),
                    label: 'Organisation des objets approuvés',
                    value: widget.outputMode.name,
                    options: const {
                      'sharedAtlas': 'Réutiliser les atlas source',
                      'standaloneObjects': 'Une image par objet',
                    },
                    onChanged: _canMutate && !_hasDrafts
                        ? (v) => widget.onModeChanged(
                            AssetOutputMode.values.byName(v),
                          )
                        : null,
                  ),
                  if (_loading) const Text('Chargement des images source…'),
                  if (_error != null) StudioNotice(_error!, isError: true),
                  if (_reviewError != null)
                    Semantics(
                      liveRegion: true,
                      child: StudioNotice(_reviewError!, isError: true),
                    ),
                  for (final conflict in session.conflicts.take(8))
                    StudioNotice(
                      'Substitution en conflit : carte ${conflict.claim.sourceMapId}, couche ${conflict.claim.sourceZ}, cellule (${conflict.claim.x}, ${conflict.claim.y}). La bibliothèque multiple reste possible.',
                      isError: true,
                    ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          width: wide ? 240 : 210,
                          child: _candidateList(),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (source != null)
                                StudioSelect(
                                  label: 'Image source',
                                  value: source.fileId.value,
                                  options: {
                                    for (final s in sources)
                                      s.fileId.value:
                                          widget.sourceFilePaths[s.fileId] ??
                                          'Image ${s.fileId.value}',
                                  },
                                  onChanged: !_hasDrafts
                                      ? (v) => setState(() {
                                          _sourceId = ConverterId(v);
                                          _cells = const [];
                                        })
                                      : null,
                                ),
                              if (source != null)
                                Expanded(
                                  child: ConverterAssetSourceCanvas(
                                    key: ValueKey(source.fileId.value),
                                    source: source,
                                    image: _images[source.contentHash.value],
                                    parts: _active?.parts ?? const [],
                                    selectedCells: _cells,
                                    enabled:
                                        _canMutate &&
                                        !_hasDrafts &&
                                        !_loading &&
                                        _error == null,
                                    onSelectionChanged: (cells) =>
                                        setState(() => _cells = cells),
                                  ),
                                ),
                              if (source == null)
                                const Expanded(
                                  child: StudioEmptyState(
                                    title: 'Aucune image source vérifiée',
                                    description: 'Les tuiles littérales restent conservées.',
                                  ),
                                ),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  StudioButton(
                                    key: const ValueKey('asset-create-manual'),
                                    label: 'Nouvel objet depuis les cellules',
                                    secondary: true,
                                    onPressed:
                                        _canMutate &&
                                            !_hasDrafts &&
                                            _cells.isNotEmpty &&
                                            source != null &&
                                            widget.sourceFilePaths.containsKey(
                                              source.fileId,
                                            ) &&
                                            _images.containsKey(
                                              source.contentHash.value,
                                            )
                                        ? () => _createManual(source)
                                        : null,
                                  ),
                                  StudioButton(
                                    key: const ValueKey('asset-add-cells'),
                                    label: 'Ajouter la sélection',
                                    secondary: true,
                                    onPressed:
                                        _canMutate &&
                                            !_hasDrafts &&
                                            _active != null &&
                                            _cells.isNotEmpty &&
                                            source != null &&
                                            widget.sourceFilePaths.containsKey(
                                              source.fileId,
                                            ) &&
                                            _active!.sources.any(
                                              (s) => s.fileId == source.fileId,
                                            )
                                        ? () => unawaited(_addCells(source))
                                        : null,
                                  ),
                                  StudioButton(
                                    key: const ValueKey('asset-remove-cells'),
                                    label: 'Retirer les cellules',
                                    secondary: true,
                                    onPressed:
                                        _canMutate &&
                                            !_hasDrafts &&
                                            _active != null &&
                                            _cells.isNotEmpty &&
                                            source != null
                                        ? () => _removeCells(source)
                                        : null,
                                  ),
                                ],
                              ),
                              if (source != null &&
                                  _active != null &&
                                  !_active!.sources.any(
                                    (s) => s.fileId == source.fileId,
                                  ))
                                const Text(
                                  'Pour associer une autre image : créez un nouvel objet manuel, puis regroupez les deux objets.',
                                ),
                            ],
                          ),
                        ),
                        if (wide) ...[
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 330,
                            child: SingleChildScrollView(child: _inspector()),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    ),
  );

  @override
  Widget build(BuildContext context) => widget.session == null
      ? const StudioPanel(
          title: 'Revue des objets et corrections',
          children: [
            StudioEmptyState(
              title: 'Préparez une sélection de cartes',
              description: 'Les propositions et les images source vérifiées apparaîtront ici.',
            ),
          ],
        )
      : _reviewWorkspace(context);
}

class AssetProposalPainter extends CustomPainter {
  AssetProposalPainter(this.candidate, this.images);
  final AssetCandidate candidate;
  final Map<String, ui.Image> images;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(
      size.width / candidate.canvasSize.width,
      size.height / candidate.canvasSize.height,
    );
    final hashes = {
      for (final source in candidate.sources)
        source.fileId: source.contentHash.value,
    };
    final paint = Paint()
      ..filterQuality = FilterQuality.none
      ..isAntiAlias = false;
    for (final part in candidate.parts) {
      final image = images[hashes[part.sourceFileId]];
      if (image == null) continue;
      final rect = part.sourceRect;
      canvas.save();
      canvas.translate(
        part.destinationOffset.x.toDouble(),
        part.destinationOffset.y.toDouble(),
      );
      switch (part.quarterTurns) {
        case 1:
          canvas.translate(rect.height.toDouble(), 0);
        case 2:
          canvas.translate(rect.width.toDouble(), rect.height.toDouble());
        case 3:
          canvas.translate(0, rect.width.toDouble());
      }
      canvas.rotate(part.quarterTurns * math.pi / 2);
      if (part.reflected) {
        canvas.translate(rect.width.toDouble(), 0);
        canvas.scale(-1, 1);
      }
      canvas.drawImageRect(
        image,
        Rect.fromLTWH(
          rect.x.toDouble(),
          rect.y.toDouble(),
          rect.width.toDouble(),
          rect.height.toDouble(),
        ),
        Rect.fromLTWH(0, 0, rect.width.toDouble(), rect.height.toDouble()),
        paint,
      );
      canvas.restore();
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(AssetProposalPainter old) =>
      old.candidate.canonicalHash != candidate.canonicalHash ||
      old.images != images;
}
