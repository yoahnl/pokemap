import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:avelune_studio/avelune_design_system.dart';
import 'package:flutter/material.dart';

import 'vision_desktop_services.dart';
import 'vision_preview.dart';

class ConverterVisionPanel extends StatefulWidget {
  const ConverterVisionPanel({
    super.key,
    required this.session,
    required this.sourceFiles,
    required this.verifySource,
    required this.excludedRoots,
    required this.onSessionChanged,
    this.enabled = true,
    this.vault,
    this.clientFactory = openConverterVisionClient,
  });
  final AssetReviewSession session;
  final Future<SourceFilePort> Function() sourceFiles;
  final Future<bool> Function() verifySource;
  final Future<List<String>> Function() excludedRoots;
  final void Function(AssetReviewSession, Sha256Hash) onSessionChanged;
  final bool enabled;
  final VisionSecretVault? vault;
  final ConverterVisionClientFactory clientFactory;
  @override
  State<ConverterVisionPanel> createState() => _ConverterVisionPanelState();
}

class _ConverterVisionPanelState extends State<ConverterVisionPanel> {
  late final _vault = widget.vault ?? ConverterKeychainVault();
  final _selection = <ConverterId>{};
  final _random = Random.secure();
  late ConverterId _accountRevision = _identity('account');
  VisionMaterial? _material;
  ScanCancellation? _cancellation;
  VisionUsageSnapshot? _usage;
  String _keyDraft = '';
  String? _error;
  String? _notice;
  bool _configured = false;
  bool _consent = false;
  bool _working = false;
  int _generation = 0;

  ConverterId _identity(String prefix) => ConverterId(
    '$prefix:${List.generate(16, (_) => _random.nextInt(256).toRadixString(16).padLeft(2, '0')).join()}',
  );

  @override
  void didUpdateWidget(ConverterVisionPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.session.canonicalHash != widget.session.canonicalHash ||
        oldWidget.enabled != widget.enabled) {
      _invalidate();
      _selection.removeWhere(
        (id) => !widget.session.activeCandidates.any(
          (candidate) => candidate.candidateId == id,
        ),
      );
    }
  }

  @override
  void dispose() {
    _generation++;
    _cancellation?.cancel();
    _keyDraft = '';
    super.dispose();
  }

  void _invalidate() {
    _generation++;
    _cancellation?.cancel();
    _material = null;
    _consent = false;
  }

  Future<void> _keyAction(String action) async {
    if (_working) return;
    setState(() {
      _working = true;
      _error = null;
      _notice = null;
      _invalidate();
    });
    try {
      if (action == 'save') {
        final secret = _keyDraft;
        setState(() => _keyDraft = '');
        await _vault.write(secret);
        _configured = true;
      } else if (action == 'delete') {
        await _vault.delete();
        _configured = false;
      } else {
        _configured = await _vault.read() != null;
      }
      if (!mounted) return;
      setState(() {
        _accountRevision = _identity('account');
        _notice = _configured
            ? 'Clé disponible dans le trousseau. Aucun appel au fournisseur effectué.'
            : 'Aucune clé enregistrée. La conversion reste disponible sans assistance.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _configured = false;
        _error = 'Le trousseau est indisponible ou la clé est invalide.';
      });
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _prepare() async {
    if (_working || !widget.enabled || _selection.isEmpty) return;
    setState(() {
      _invalidate();
      _working = true;
      _error = null;
      _notice = null;
    });
    final generation = _generation;
    final cancellation = ScanCancellation();
    _cancellation = cancellation;
    final session = widget.session;
    final selected = Set<ConverterId>.from(_selection);
    try {
      final verified = await widget.verifySource();
      cancellation.check();
      if (!verified) {
        throw const VisionAssistanceException('vision.sourceChanged');
      }
      final files = await widget.sourceFiles();
      cancellation.check();
      final material = await buildVisionPreview(
        session: session,
        candidateIds: selected,
        sourceFiles: files,
        requestId: _identity('request'),
        model: 'gpt-4.1-mini',
        cancellation: cancellation,
      );
      if (!mounted ||
          generation != _generation ||
          !widget.enabled ||
          widget.session.canonicalHash != session.canonicalHash) {
        return;
      }
      setState(() => _material = material);
    } catch (error) {
      if (mounted && generation == _generation) {
        setState(() => _error = _message(error));
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<VisionLiveContext> _live() async {
    final before = _material;
    if (!mounted || before == null || !widget.enabled) {
      throw const VisionAssistanceException('vision.stale');
    }
    final verified = await widget.verifySource();
    if (!mounted || _material != before || !widget.enabled) {
      throw const VisionAssistanceException('vision.stale');
    }
    return VisionLiveContext(
      sourceVerified: verified,
      sourceSnapshotHash: widget.session.sourceSnapshotHash,
      sessionHash: widget.session.canonicalHash,
      selectionHash: before.selectionHash,
      inputRevision: widget.session.revision,
      accountRevision: _accountRevision,
    );
  }

  Future<void> _send() async {
    final material = _material;
    if (_working ||
        !_consent ||
        !_configured ||
        !widget.enabled ||
        material == null) {
      return;
    }
    final generation = _generation;
    final session = widget.session;
    final cancellation = ScanCancellation();
    _cancellation = cancellation;
    final request = VisionRequest(
      context: material.context,
      material: material,
      consent: VisionConsent.grant(
        materialHash: material.canonicalHash,
        accountRevision: _accountRevision,
        humanConfirmed: _consent,
      ),
    );
    setState(() {
      _working = true;
      _error = null;
      _notice = null;
      _consent = false;
    });
    ConverterVisionClient? client;
    try {
      validateVisionDispatch(request, await _live());
      cancellation.check();
      client = await widget.clientFactory(
        vault: _vault,
        liveContext: _live,
        sourceFiles: widget.sourceFiles,
        excludedRoots: widget.excludedRoots,
      );
      cancellation.check();
      final response = await client.port.suggest(
        request,
        cancellation: cancellation,
      );
      cancellation.check();
      final live = await _live();
      if (!mounted || generation != _generation) return;
      final sources = <ConverterId, SourceImage>{
        for (final candidate in session.activeCandidates)
          for (final source in candidate.sources) source.fileId: source,
      };
      final next = widget.session.importVisionSuggestions(
        response: response,
        request: request,
        live: live,
        verifiedSources: sources.values.toList(),
        expectedSessionHash: session.canonicalHash,
      );
      widget.onSessionChanged(next, session.canonicalHash);
      if (mounted) {
        setState(() {
          _notice =
              '${response.suggestions.length} suggestion(s) à vérifier. Aucun objet approuvé automatiquement.';
          _invalidate();
        });
      }
    } catch (error) {
      if (mounted) setState(() => _error = _message(error));
    } finally {
      if (client != null) {
        try {
          final usage = await client.usage();
          if (mounted) setState(() => _usage = usage);
        } catch (_) {
          if (mounted) setState(() => _usage = null);
        }
      }
      if (mounted) setState(() => _working = false);
    }
  }

  String _message(Object error) {
    final code = error is VisionAssistanceException
        ? error.code
        : error is ContractError
        ? error.code
        : '';
    return switch (code) {
      'vision.keyMissing' =>
        'Enregistrez une clé pour utiliser cette assistance.',
      'vision.keyInvalid' =>
        'La clé enregistrée est invalide. Remplacez-la dans le trousseau.',
      'vision.keyRejected' =>
        'Le fournisseur refuse cette clé. La revue est conservée.',
      'vision.requestQuota' || 'vision.retryQuota' =>
        'Le plafond de requêtes est atteint. La revue est conservée.',
      'vision.remoteQuota' =>
        'Le quota du compte fournisseur est épuisé. La revue est conservée.',
      'vision.rateLimited' => 'Le fournisseur limite les demandes. Réessayez plus tard ; la revue est conservée.',
      'vision.timeout' => 'Le fournisseur n’a pas répondu dans le délai prévu.',
      'vision.pricingUnavailable' =>
        'Coût inconnu : le budget monétaire strict bloque cet appel.',
      'vision.costQuota' =>
        'Le budget monétaire est atteint. La revue est conservée.',
      'vision.costUnknown' => 'Le coût reste inconnu. Vérifiez la consommation du compte fournisseur.',
      'vision.cancelled' => 'La demande a été annulée. La revue est conservée.',
      'vision.refused' =>
        'Le fournisseur a refusé cette demande. La revue est conservée.',
      'vision.sourceChanged' || 'vision.stale' || 'vision.live.changed' => 'La source, la sélection ou la revue a changé. Préparez un nouvel aperçu.',
      _ => 'L’assistance n’a pas abouti. La revue est conservée ; vous pouvez préparer un nouvel aperçu.',
    };
  }

  void _decide(VisionReviewProposal proposal, bool apply) {
    if (_working || !widget.enabled) return;
    final session = widget.session;
    try {
      final next = apply
          ? session.applyVisionMetadata(
              proposalId: proposal.proposalId,
              expectedSessionHash: session.canonicalHash,
              humanConfirmed: true,
            )
          : session.removeVisionProposal(
              proposalId: proposal.proposalId,
              expectedSessionHash: session.canonicalHash,
              humanConfirmed: true,
            );
      widget.onSessionChanged(next, session.canonicalHash);
    } catch (_) {
      setState(
        () =>
            _error = 'Cette suggestion est périmée. Préparez un nouvel aperçu.',
      );
    }
  }

  Widget _proposal(VisionReviewProposal proposal) {
    final suggestion = proposal.suggestion;
    final grouped = suggestion.candidateIds.length != 1;
    final targets = {
      for (final candidate in widget.session.activeCandidates)
        if (suggestion.candidateIds.contains(candidate.candidateId))
          candidate.candidateId: candidate,
    };
    final current = suggestion.candidateIds.every(
      (id) => targets[id]?.canonicalHash == proposal.candidateHashes[id],
    );
    final category = switch (suggestion.category) {
      AssetCategory.building => 'Bâtiment',
      AssetCategory.nature => 'Nature',
      AssetCategory.object => 'Objet',
      AssetCategory.terrain => 'Terrain',
      AssetCategory.surface => 'Surface',
      AssetCategory.character => 'Personnage',
      AssetCategory.animation => 'Animation',
      AssetCategory.unclassified => 'À classer',
    };
    return StudioPanel(
      compact: true,
      children: [
        Text(suggestion.proposedName),
        const StudioBadge('À vérifier'),
        Text('Catégorie proposée : $category'),
        for (final id in suggestion.candidateIds)
          Text('Objet concerné : ${targets[id]?.name ?? 'Objet périmé'}'),
        if (!current)
          const StudioNotice(
            'Cette suggestion est périmée. Préparez un nouvel aperçu.',
          ),
        Text(suggestion.evidenceSummary),
        if (suggestion.tags.isNotEmpty) Text(suggestion.tags.join(' · ')),
        for (final uncertainty in suggestion.uncertainties) Text(uncertainty),
        if (grouped)
          const StudioNotice(
            'Regroupement suggéré : utilisez l’union de la revue pour choisir les pièces et leurs positions.',
          ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (!grouped)
              StudioButton(
                key: ValueKey('vision-apply-${proposal.proposalId.value}'),
                label: 'Appliquer le nom et la catégorie',
                onPressed: _working || !widget.enabled || !current
                    ? null
                    : () => _decide(proposal, true),
              ),
            StudioButton(
              key: ValueKey('vision-discard-${proposal.proposalId.value}'),
              label: 'Écarter',
              secondary: true,
              onPressed: _working || !widget.enabled
                  ? null
                  : () => _decide(proposal, false),
            ),
          ],
        ),
      ],
    );
  }

  Widget _preview(VisionMaterial material) => StudioPanel(
    key: const ValueKey('vision-preview'),
    title: 'Découpes qui seront envoyées',
    compact: true,
    children: [
      const Text('OpenAI · GPT-4.1 mini · qualité d’image élevée'),
      Text(
        '${material.crops.length} découpe(s) · ${material.crops.fold(0, (n, c) => n + c.pngBytes.length)} octets PNG',
      ),
      const Text(
        'La demande porte sur des noms, catégories, tags, incertitudes et regroupements éventuels. Les identifiants des objets et découpes, dimensions, rotations et miroirs accompagnent les images. Les chemins locaux et les scripts restent sur votre ordinateur.',
      ),
      Text(
        'Objets sélectionnés : ${material.context.candidateIds.map((id) => id.value).join(', ')}',
      ),
      Text(
        'Empreinte du projet : ${material.context.sourceSnapshotHash.value} · révision de revue ${material.context.inputRevision}',
      ),
      Text(
        'Réponse limitée à ${material.options['maxOutputTokens']} tokens. Les empreintes des images ci-dessous servent à vérifier les découpes.',
      ),
      for (final crop in material.crops)
        StudioPanel(
          compact: true,
          children: [
            Text(
              '${crop.transmittedWidth} × ${crop.transmittedHeight} px · rotation ${crop.quarterTurns * 90}° · miroir ${crop.reflected ? 'oui' : 'non'}',
            ),
            StudioAssetPreview(
              height: 128,
              child: Image.memory(
                Uint8List.fromList(crop.pngBytes),
                fit: BoxFit.contain,
                filterQuality: FilterQuality.none,
              ),
            ),
            Text('Découpe : ${crop.regionId.value}'),
            Text('Empreinte image : ${crop.byteHash.value}'),
          ],
        ),
      const StudioNotice(
        'Coût inconnu : aucun tarif actuel n’est configuré. Plafond local de 20 tentatives, reprises comprises ; au plus une reprise par demande.',
      ),
      StudioToggleRow(
        key: const ValueKey('vision-consent'),
        label: 'J’autorise l’envoi de ces découpes et métadonnées à OpenAI, avec un coût fournisseur inconnu.',
        value: _consent,
        onChanged: _working || !widget.enabled
            ? null
            : (value) => setState(() => _consent = value),
      ),
      StudioButton(
        key: const ValueKey('vision-send'),
        label: 'Envoyer et demander des suggestions',
        loading: _working,
        onPressed: _working || !_consent || !_configured || !widget.enabled
            ? null
            : () => unawaited(_send()),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) => StudioPanel(
    title: 'Assistance visuelle facultative',
    radius: 16,
    children: [
      const StudioNotice(
        'La conversion et la revue fonctionnent sans clé. Les suggestions visuelles restent à confirmer avant toute utilisation.',
      ),
      StudioDraftField(
        key: const ValueKey('vision-key'),
        label: 'Clé OpenAI',
        value: _keyDraft,
        obscureText: true,
        enabled: !_working,
        onChanged: (value) => setState(() {
          _keyDraft = value;
          _invalidate();
        }),
      ),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          StudioButton(
            key: const ValueKey('vision-save-key'),
            label: 'Enregistrer dans le trousseau',
            secondary: true,
            onPressed: _working || _keyDraft.isEmpty
                ? null
                : () => unawaited(_keyAction('save')),
          ),
          StudioButton(
            key: const ValueKey('vision-check-key'),
            label: 'Vérifier la clé enregistrée',
            secondary: true,
            onPressed: _working ? null : () => unawaited(_keyAction('check')),
          ),
          StudioButton(
            key: const ValueKey('vision-delete-key'),
            label: 'Retirer la clé',
            secondary: true,
            onPressed: _working ? null : () => unawaited(_keyAction('delete')),
          ),
        ],
      ),
      if (widget.session.activeCandidates.isEmpty)
        const Text(
          'Aucun objet à proposer. La conversion des tuiles reste disponible.',
        ),
      for (final candidate in widget.session.activeCandidates)
        StudioToggleRow(
          key: ValueKey('vision-candidate-${candidate.candidateId.value}'),
          label: candidate.name.isEmpty ? 'Objet à classifier' : candidate.name,
          value: _selection.contains(candidate.candidateId),
          onChanged: !widget.enabled
              ? null
              : (value) => setState(() {
                  _invalidate();
                  _error = null;
                  if (value) {
                    if (_selection.length >= 2) {
                      _error = 'Sélectionnez au maximum deux objets.';
                      return;
                    }
                    _selection.add(candidate.candidateId);
                  } else {
                    _selection.remove(candidate.candidateId);
                  }
                }),
        ),
      StudioButton(
        key: const ValueKey('vision-prepare'),
        label: 'Voir les découpes avant envoi',
        secondary: true,
        onPressed: _working || !widget.enabled || _selection.isEmpty
            ? null
            : () => unawaited(_prepare()),
      ),
      if (_material case final material?) _preview(material),
      if (_working)
        StudioButton(
          key: const ValueKey('vision-cancel'),
          label: 'Annuler la demande',
          secondary: true,
          onPressed: () => setState(() {
            _invalidate();
            _notice = 'Annulation demandée. Une tentative déjà envoyée reste comptabilisée.';
          }),
        ),
      if (_usage case final usage?)
        Text(
          '${usage.requestCount} tentative(s) · ${usage.retryCount} reprise(s) · ${usage.unknownAttempts} usage(s) inconnu(s) · ${usage.knownCostMicros == null ? 'Coût inconnu' : '${usage.knownCostMicros} µUSD connus, estimation hors facture fournisseur'}',
        ),
      if (_notice case final notice?) StudioNotice(notice),
      if (_error case final error?)
        StudioNotice(error, key: const ValueKey('vision-error'), isError: true),
      for (final proposal in widget.session.frame.visionProposals)
        _proposal(proposal),
    ],
  );
}
