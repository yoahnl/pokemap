import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/feedback/studio_notice.dart';
import '../../shared/widgets/inputs/studio_draft_field.dart';
import '../../shared/widgets/inputs/studio_select.dart';

class SceneDialogueLinePolicyForm extends StatefulWidget {
  const SceneDialogueLinePolicyForm({
    super.key,
    required this.project,
    required this.payload,
    required this.document,
    required this.onApply,
  });

  final ProjectManifest project;
  final SceneYarnDialoguePayload payload;
  final RuntimeDialogueDocument document;
  final ValueChanged<SceneDialogueLinePolicy> onApply;

  @override
  State<SceneDialogueLinePolicyForm> createState() =>
      _SceneDialogueLinePolicyFormState();
}

class _SceneDialogueLinePolicyFormState
    extends State<SceneDialogueLinePolicyForm> {
  int _scopeIndex = 0;
  late DialogueLineFeedback _original;
  String _revealMs = '', _delayMs = '0', _mediaId = '';
  String _volume = '100', _offset = '0', _cueId = '';
  DialogueLineAdvanceKind _advance = DialogueLineAdvanceKind.confirm;
  DialogueAudioCueRole _role = DialogueAudioCueRole.effect;

  List<SceneDialogueLineScope> get _scopes =>
      sceneDialogueLineScopes(widget.document);

  SceneDialogueLineScope get _scope => _scopes[_scopeIndex];

  Map<String, String> get _sounds => {
    '': 'Aucun son',
    for (final asset in widget.project.cinematicMediaAssets)
      if (asset.kind == CinematicMediaAssetKind.sound &&
          !asset.loopByDefault &&
          widget.project.cinematicMediaAssets
                  .where((other) => other.id == asset.id)
                  .length ==
              1)
        asset.id: asset.label,
  };

  @override
  void initState() {
    super.initState();
    _read();
  }

  @override
  void didUpdateWidget(SceneDialogueLinePolicyForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.payload != widget.payload ||
        oldWidget.document != widget.document) {
      if (_scopeIndex >= _scopes.length) _scopeIndex = 0;
      _read();
    }
  }

  void _read() {
    if (_scopes.isEmpty) return;
    final policy = widget.payload.linePolicies
        .where(
          (policy) =>
              policy.nodeName == _scope.nodeName &&
              policy.lineIndex == _scope.lineIndex,
        )
        .firstOrNull;
    _original = policy?.feedback ?? _scope.feedback ?? DialogueLineFeedback();
    _revealMs = _original.revealIntervalMicros == null
        ? ''
        : _milliseconds(_original.revealIntervalMicros!);
    _advance = _original.advance.kind;
    _delayMs = _milliseconds(_original.advance.delayMicros);
    final cue = _original.audioCue;
    _mediaId = cue?.mediaAssetId ?? '';
    _volume = ((cue?.volume ?? 1) * 100).toString();
    _offset = (cue?.revealOffset ?? 0).toString();
    _role = cue?.role ?? DialogueAudioCueRole.effect;
    _cueId = cue?.cueId ?? _availableCueId();
  }

  String _availableCueId() {
    final used = {
      for (final policy in widget.payload.linePolicies)
        if (policy.feedback.audioCue case final cue?) cue.cueId,
      for (final scope in _scopes)
        if (scope.feedback?.audioCue case final cue?) cue.cueId,
    };
    final base =
        'dialogue_${widget.payload.dialogueId}_${_scope.nodeName}_${_scope.lineIndex}';
    var result = base;
    var suffix = 2;
    while (used.contains(result)) {
      result = '${base}_${suffix++}';
    }
    return result;
  }

  DialogueLineFeedback get _draft {
    final reveal = _revealMs.trim().isEmpty ? null : _micros(_revealMs);
    if (_revealMs.trim().isNotEmpty && reveal == null) {
      throw const FormatException(
        'L’intervalle doit être positif ou nul, avec au plus trois décimales.',
      );
    }
    final delay = _micros(_delayMs);
    if (_advance == DialogueLineAdvanceKind.autoAfterReveal && delay == null) {
      throw const FormatException(
        'Le délai doit être positif ou nul, avec au plus trois décimales.',
      );
    }
    DialogueAudioCue? cue;
    if (_mediaId.isNotEmpty) {
      if (!_sounds.containsKey(_mediaId)) {
        throw const FormatException(
          'Le son enregistré est indisponible. Choisissez un son du projet.',
        );
      }
      final volume = double.tryParse(_volume.trim());
      if (volume == null || !volume.isFinite || volume < 0 || volume > 100) {
        throw const FormatException(
          'Le volume doit être compris entre 0 et 100 %.',
        );
      }
      final offset = _role == DialogueAudioCueRole.musicEffect
          ? 0
          : int.tryParse(_offset.trim());
      if (offset == null || offset < 0 || offset > _scope.text.runes.length) {
        throw const FormatException(
          'La position du son doit être comprise entre zéro et la longueur de la réplique.',
        );
      }
      final originalCue = _original.audioCue;
      final unchangedVolume =
          originalCue != null &&
          _volume == (originalCue.volume * 100).toString();
      cue = DialogueAudioCue(
        mediaAssetId: _mediaId,
        cueId: _cueId,
        volume: unchangedVolume ? originalCue.volume : volume / 100,
        revealOffset: offset,
        role: _role,
        bgmInterruption: _role == DialogueAudioCueRole.musicEffect
            ? originalCue?.bgmInterruption
            : null,
      );
    }
    final feedback = DialogueLineFeedback(
      segments: _original.segments,
      revealIntervalMicros: reveal,
      advance: _advance == DialogueLineAdvanceKind.confirm
          ? const DialogueLineAdvancePolicy.confirm()
          : DialogueLineAdvancePolicy.autoAfterReveal(delay!),
      audioCue: cue,
    );
    feedback.validateText(_scope.text);
    if (_scope.feedback != null && feedback != _scope.feedback) {
      throw const FormatException(
        'Ces réglages sont inscrits dans le document du dialogue. Modifiez ce document pour les changer ; aucune surcharge incompatible ne sera enregistrée.',
      );
    }
    return feedback;
  }

  @override
  Widget build(BuildContext context) {
    if (_scopes.isEmpty) {
      return const StudioNotice(
        'Aucune réplique dans ce dialogue. Ajoutez du texte pour régler son rythme.',
      );
    }
    DialogueLineFeedback? feedback;
    String? error;
    try {
      feedback = _draft;
    } on FormatException catch (failure) {
      error = failure.message;
    } on ArgumentError {
      error = 'Les réglages de cette réplique sont incompatibles.';
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StudioSelect(
          key: const ValueKey('scene-line-scope'),
          label: 'Réplique à régler',
          value: '$_scopeIndex',
          options: {
            for (var index = 0; index < _scopes.length; index++)
              '$index':
                  '${_scopes[index].nodeName} · Ligne ${_scopes[index].lineIndex + 1} · ${_scopes[index].text}',
          },
          onChanged: (value) => setState(() {
            _scopeIndex = int.parse(value);
            _read();
          }),
        ),
        const SizedBox(height: 12),
        Text(_scope.text),
        if (_original.segments.isNotEmpty) ...[
          const StudioNotice('Texte enrichi et icônes conservés.'),
          for (final segment in _original.segments)
            if (segment is DialogueIconSegment)
              Text('Icône ${segment.widthPx} × ${segment.heightPx} px'),
        ],
        const SizedBox(height: 12),
        StudioDraftField(
          key: const ValueKey('scene-line-reveal-ms'),
          label: 'Intervalle entre les caractères (ms)',
          helperText: 'Vide : rythme par défaut. Zéro : affichage instantané.',
          value: _revealMs,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (value) => setState(() => _revealMs = value),
        ),
        const SizedBox(height: 12),
        StudioSelect(
          key: const ValueKey('scene-line-advance'),
          label: 'Passage à la réplique suivante',
          value: _advance.name,
          options: const {
            'confirm': 'Confirmation du joueur',
            'autoAfterReveal': 'Automatique après affichage',
          },
          onChanged: (value) => setState(
            () => _advance = DialogueLineAdvanceKind.values.byName(value),
          ),
        ),
        if (_advance == DialogueLineAdvanceKind.autoAfterReveal) ...[
          const SizedBox(height: 12),
          StudioDraftField(
            key: const ValueKey('scene-line-delay-ms'),
            label: 'Délai après affichage complet (ms)',
            value: _delayMs,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (value) => setState(() => _delayMs = value),
          ),
        ],
        const SizedBox(height: 12),
        StudioSelect(
          key: const ValueKey('scene-line-sound'),
          label: 'Son associé à la réplique',
          value: _mediaId,
          options: _sounds,
          onChanged: (value) => setState(() => _mediaId = value),
        ),
        if (_mediaId.isNotEmpty) ...[
          const SizedBox(height: 12),
          StudioSelect(
            key: const ValueKey('scene-line-audio-role'),
            label: 'Comportement du son',
            value: _role.name,
            options: const {
              'effect': 'Effet sonore',
              'musicEffect': 'Jingle musical',
            },
            onChanged: (value) => setState(
              () => _role = DialogueAudioCueRole.values.byName(value),
            ),
          ),
          const SizedBox(height: 12),
          StudioDraftField(
            key: const ValueKey('scene-line-audio-volume'),
            label: 'Volume du son (%)',
            value: _volume,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (value) => setState(() => _volume = value),
          ),
          if (_role == DialogueAudioCueRole.effect) ...[
            const SizedBox(height: 12),
            StudioDraftField(
              key: const ValueKey('scene-line-audio-offset'),
              label: 'Jouer après combien de caractères ?',
              helperText: 'Zéro : dès le début de la réplique.',
              value: _offset,
              keyboardType: TextInputType.number,
              onChanged: (value) => setState(() => _offset = value),
            ),
          ],
        ],
        if (error != null) ...[
          const SizedBox(height: 12),
          StudioNotice(error, isError: true),
        ],
        const SizedBox(height: 12),
        StudioButton(
          key: const ValueKey('scene-line-apply'),
          label: 'Appliquer les réglages de la réplique',
          onPressed: feedback == null
              ? null
              : () => widget.onApply(
                  SceneDialogueLinePolicy(
                    nodeName: _scope.nodeName,
                    lineIndex: _scope.lineIndex,
                    feedback: feedback!,
                  ),
                ),
        ),
      ],
    );
  }
}

String _milliseconds(int micros) {
  final whole = micros ~/ 1000;
  final fraction = (micros % 1000).toString().padLeft(3, '0');
  return micros % 1000 == 0
      ? '$whole'
      : '$whole.${fraction.replaceFirst(RegExp(r'0+$'), '')}';
}

int? _micros(String milliseconds) {
  final value = milliseconds.trim().replaceAll(',', '.');
  if (!RegExp(r'^\d+(?:\.\d{1,3})?$').hasMatch(value)) return null;
  final parts = value.split('.');
  final whole = BigInt.tryParse(parts.first);
  if (whole == null) return null;
  final fraction = parts.length == 1
      ? 0
      : int.parse(parts.last.padRight(3, '0'));
  final micros = whole * BigInt.from(1000) + BigInt.from(fraction);
  final result = micros.toInt();
  return BigInt.from(result) == micros ? result : null;
}
