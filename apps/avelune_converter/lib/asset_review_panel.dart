import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:avelune_studio/avelune_design_system.dart';
import 'package:flutter/material.dart';

class ConverterAssetReviewPanel extends StatefulWidget {
  const ConverterAssetReviewPanel({
    super.key,
    required this.proposals,
    required this.reviewedCandidates,
    required this.artifacts,
    required this.limits,
    required this.outputMode,
    required this.onModeChanged,
    required this.onReview,
    required this.onEditing,
    this.enabled = true,
  });

  final List<AssetCandidate> proposals;
  final List<AssetCandidate> reviewedCandidates;
  final List<NativeArtifact> artifacts;
  final NativeWriteLimits limits;
  final AssetOutputMode outputMode;
  final ValueChanged<AssetOutputMode> onModeChanged;
  final ValueChanged<ConverterAssetReview> onReview;
  final ValueChanged<ConverterId> onEditing;
  final bool enabled;

  @override
  State<ConverterAssetReviewPanel> createState() =>
      _ConverterAssetReviewPanelState();
}

class _ConverterAssetReviewPanelState extends State<ConverterAssetReviewPanel> {
  final _names = <ConverterId, String>{};
  final _categories = <ConverterId, AssetCategory>{};
  final _edited = <ConverterId>{};
  Map<String, ui.Image> _images = const {};
  String? _error;
  bool _loading = true;
  int _generation = 0;

  String _imageIdentity(ConverterAssetReviewPanel panel) => canonicalHashOf({
    'proposals': panel.proposals.map((p) => p.canonicalHash.value).toList(),
    'images': panel.artifacts.map((a) => a.handle).toList(),
  }).value;

  @override
  void initState() {
    super.initState();
    unawaited(_loadImages());
  }

  @override
  void didUpdateWidget(ConverterAssetReviewPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_imageIdentity(oldWidget) != _imageIdentity(widget)) {
      _names.clear();
      _categories.clear();
      _edited.clear();
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
        for (final candidate in widget.proposals)
          for (final source in candidate.sources)
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
      }
    }
  }

  @override
  void dispose() {
    _generation++;
    for (final image in _images.values) {
      image.dispose();
    }
    super.dispose();
  }

  void _edit(AssetCandidate proposal, {String? name, AssetCategory? category}) {
    setState(() {
      if (name != null) _names[proposal.candidateId] = name;
      if (category != null) _categories[proposal.candidateId] = category;
      _edited.add(proposal.candidateId);
    });
    widget.onEditing(proposal.candidateId);
  }

  void _review(AssetCandidate proposal, ReviewAction action) {
    final reviewed = widget.reviewedCandidates.firstWhere(
      (c) => c.candidateId == proposal.candidateId,
      orElse: () => proposal,
    );
    widget.onReview(
      ConverterAssetReview(
        candidateId: proposal.candidateId,
        proposalHash: proposal.canonicalHash,
        name: _names[proposal.candidateId] ?? reviewed.name,
        category: _categories[proposal.candidateId] ?? reviewed.category,
        action: action,
        humanConfirmed: true,
      ),
    );
    setState(() => _edited.remove(proposal.candidateId));
  }

  @override
  Widget build(BuildContext context) => StudioPanel(
    title: 'Objets proposés pour la bibliothèque',
    children: [
      const StudioNotice(
        'Ces groupes proviennent des pixels et de leurs usages. '
        'Vérifiez chaque découpe avant de l’approuver. Les placements, les couches '
        'et les priorités de la carte restent inchangés.',
      ),
      StudioSelect(
        key: const ValueKey('asset-output-mode'),
        label: 'Organisation des objets approuvés',
        value: widget.outputMode.name,
        options: const {
          'sharedAtlas': 'Réutiliser les atlas source',
          'standaloneObjects': 'Une image par objet',
        },
        onChanged: widget.enabled
            ? (value) =>
                  widget.onModeChanged(AssetOutputMode.values.byName(value))
            : null,
      ),
      if (widget.outputMode == AssetOutputMode.sharedAtlas)
        const Text(
          'Les groupes dont les morceaux sont séparés dans l’atlas nécessitent « Une image par objet ». Ce choix sera soumis à une nouvelle revue.',
        ),
      if (_loading) const Text('Chargement des images source…'),
      if (_error != null) StudioNotice(_error!),
      if (widget.proposals.isEmpty)
        const Text(
          'Aucune proposition locale disponible. Les tuiles littérales restent utilisables.',
        ),
      for (final proposal in widget.proposals) _candidateCard(proposal),
    ],
  );

  Widget _candidateCard(AssetCandidate proposal) {
    final reviewed = widget.reviewedCandidates.firstWhere(
      (c) => c.candidateId == proposal.candidateId,
      orElse: () => proposal,
    );
    final name = _names[proposal.candidateId] ?? reviewed.name;
    final category = _categories[proposal.candidateId] ?? reviewed.category;
    final validName =
        name.trim().isNotEmpty &&
        name.length <= 256 &&
        !name.contains('\u0000');
    final canApprove =
        widget.enabled &&
        !_loading &&
        _error == null &&
        proposal.outputMode == widget.outputMode &&
        validName &&
        category != AssetCategory.unclassified;
    return StudioPanel(
      key: ValueKey('asset-candidate-${proposal.candidateId.value}'),
      title: proposal.name,
      compact: true,
      children: [
        StudioBadge(
          _edited.contains(proposal.candidateId)
              ? 'Revue à renouveler'
              : switch (reviewed.state) {
                  CandidateState.approved => 'Approuvé pour la bibliothèque',
                  CandidateState.keepLiteral => 'Tuiles conservées',
                  _ => 'À vérifier',
                },
        ),
        if (!_loading && _error == null)
          StudioAssetPreview(
            height: 160,
            child: AspectRatio(
              aspectRatio:
                  proposal.canvasSize.width / proposal.canvasSize.height,
              child: CustomPaint(
                painter: AssetProposalPainter(proposal, _images),
              ),
            ),
          ),
        StudioDraftField(
          key: ValueKey('asset-name-${proposal.candidateId.value}'),
          value: name,
          label: 'Nom de l’objet',
          enabled: widget.enabled,
          onChanged: (value) => _edit(proposal, name: value),
        ),
        StudioSelect(
          key: ValueKey('asset-category-${proposal.candidateId.value}'),
          label: 'Catégorie de l’objet',
          value: category.name,
          options: const {
            'unclassified': 'À classer',
            'building': 'Bâtiment',
            'nature': 'Nature',
            'object': 'Objet',
            'terrain': 'Terrain',
            'surface': 'Surface',
          },
          onChanged: widget.enabled
              ? (value) => _edit(
                  proposal,
                  category: AssetCategory.values.byName(value),
                )
              : null,
        ),
        Text(
          '${proposal.canvasSize.width} × ${proposal.canvasSize.height} px · '
          '${proposal.parts.length} morceau(x) · ancre source (${proposal.anchor.x}, ${proposal.anchor.y}).',
        ),
        const Text(
          'L’ancre source sera conservée dans les métadonnées de l’objet. Son utilisation pour remplacer les placements reste à qualifier.',
        ),
        for (final part in proposal.parts.take(8))
          Text(
            'Source (${part.sourceRect.x}, ${part.sourceRect.y}, ${part.sourceRect.width} × ${part.sourceRect.height}) '
            '→ objet (${part.destinationOffset.x}, ${part.destinationOffset.y}) '
            '· couche ${part.sourceLayer ?? "non placée"} · priorité ${part.sourcePriority ?? "inconnue"}.',
          ),
        if (proposal.parts.length > 8)
          Text(
            '${proposal.parts.length - 8} autres morceaux sont visibles dans l’aperçu.',
          ),
        for (final uncertainty in proposal.uncertainties)
          StudioNotice(uncertainty),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            StudioButton(
              key: ValueKey('approve-asset-${proposal.candidateId.value}'),
              label: 'Approuver pour la bibliothèque',
              onPressed: canApprove
                  ? () => _review(proposal, ReviewAction.approve)
                  : null,
            ),
            StudioButton(
              key: ValueKey('keep-asset-${proposal.candidateId.value}'),
              label: 'Garder les tuiles',
              secondary: true,
              onPressed:
                  widget.enabled &&
                      validName &&
                      proposal.outputMode == widget.outputMode
                  ? () => _review(proposal, ReviewAction.keepLiteral)
                  : null,
            ),
          ],
        ),
      ],
    );
  }
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
