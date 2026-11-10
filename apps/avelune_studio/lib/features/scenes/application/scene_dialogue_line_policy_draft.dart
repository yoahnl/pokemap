import 'package:map_core/map_core.dart';

class SceneDialogueLinePolicyDraft {
  SceneDialogueLinePolicyDraft({
    required this.project,
    required this.payload,
    required this.document,
  }) {
    read();
  }
  ProjectManifest project;
  SceneYarnDialoguePayload payload;
  RuntimeDialogueDocument document;
  void configure({
    required ProjectManifest project,
    required SceneYarnDialoguePayload payload,
    required RuntimeDialogueDocument document,
  }) {
    final changed = this.payload != payload || this.document != document;
    this.project = project;
    this.payload = payload;
    this.document = document;
    if (changed) {
      if (scopeIndex >= scopes.length) scopeIndex = 0;
      read();
    }
  }

  SceneDialogueLinePolicy get prepared => SceneDialogueLinePolicy(
    nodeName: scope.nodeName,
    lineIndex: scope.lineIndex,
    feedback: feedback,
  );
  int scopeIndex = 0;
  late DialogueLineFeedback original;
  String revealMs = '', delayMs = '0', mediaId = '';
  String volume = '100', offset = '0', cueId = '';
  DialogueLineAdvanceKind advance = DialogueLineAdvanceKind.confirm;
  DialogueAudioCueRole role = DialogueAudioCueRole.effect;

  List<SceneDialogueLineScope> get scopes => sceneDialogueLineScopes(document);

  SceneDialogueLineScope get scope => scopes[scopeIndex];

  Map<String, String> get sounds => {
    '': 'Aucun son',
    for (final asset in project.cinematicMediaAssets)
      if (asset.kind == CinematicMediaAssetKind.sound &&
          !asset.loopByDefault &&
          project.cinematicMediaAssets
                  .where((other) => other.id == asset.id)
                  .length ==
              1)
        asset.id: asset.label,
  };

  void read() {
    if (scopes.isEmpty) return;
    final policy = payload.linePolicies
        .where(
          (policy) =>
              policy.nodeName == scope.nodeName &&
              policy.lineIndex == scope.lineIndex,
        )
        .firstOrNull;
    original = policy?.feedback ?? scope.feedback ?? DialogueLineFeedback();
    revealMs = original.revealIntervalMicros == null
        ? ''
        : _milliseconds(original.revealIntervalMicros!);
    advance = original.advance.kind;
    delayMs = _milliseconds(original.advance.delayMicros);
    final cue = original.audioCue;
    mediaId = cue?.mediaAssetId ?? '';
    volume = ((cue?.volume ?? 1) * 100).toString();
    offset = (cue?.revealOffset ?? 0).toString();
    role = cue?.role ?? DialogueAudioCueRole.effect;
    cueId = cue?.cueId ?? availableCueId();
  }

  String availableCueId() {
    final used = {
      for (final policy in payload.linePolicies)
        if (policy.feedback.audioCue case final cue?) cue.cueId,
      for (final scope in scopes)
        if (scope.feedback?.audioCue case final cue?) cue.cueId,
    };
    final base =
        'dialogue_${payload.dialogueId}_${scope.nodeName}_${scope.lineIndex}';
    var result = base;
    var suffix = 2;
    while (used.contains(result)) {
      result = '${base}_${suffix++}';
    }
    return result;
  }

  DialogueLineFeedback get feedback {
    final reveal = revealMs.trim().isEmpty ? null : _micros(revealMs);
    if (revealMs.trim().isNotEmpty && reveal == null) {
      throw const FormatException(
        'L’intervalle doit être positif ou nul, avec au plus trois décimales.',
      );
    }
    final delay = _micros(delayMs);
    if (advance == DialogueLineAdvanceKind.autoAfterReveal && delay == null) {
      throw const FormatException(
        'Le délai doit être positif ou nul, avec au plus trois décimales.',
      );
    }
    DialogueAudioCue? cue;
    if (mediaId.isNotEmpty) {
      if (!sounds.containsKey(mediaId)) {
        throw const FormatException(
          'Le son enregistré est indisponible. Choisissez un son du projet.',
        );
      }
      final parsedVolume = double.tryParse(volume.trim());
      if (parsedVolume == null ||
          !parsedVolume.isFinite ||
          parsedVolume < 0 ||
          parsedVolume > 100) {
        throw const FormatException(
          'Le volume doit être compris entre 0 et 100 %.',
        );
      }
      final parsedOffset = role == DialogueAudioCueRole.musicEffect
          ? 0
          : int.tryParse(offset.trim());
      if (parsedOffset == null ||
          parsedOffset < 0 ||
          parsedOffset > scope.text.runes.length) {
        throw const FormatException(
          'La position du son doit être comprise entre zéro et la longueur de la réplique.',
        );
      }
      final originalCue = original.audioCue;
      final unchangedVolume =
          originalCue != null &&
          volume == (originalCue.volume * 100).toString();
      cue = DialogueAudioCue(
        mediaAssetId: mediaId,
        cueId: cueId,
        volume: unchangedVolume ? originalCue.volume : parsedVolume / 100,
        revealOffset: parsedOffset,
        role: role,
        bgmInterruption: role == DialogueAudioCueRole.musicEffect
            ? originalCue?.bgmInterruption
            : null,
      );
    }
    final feedback = DialogueLineFeedback(
      segments: original.segments,
      revealIntervalMicros: reveal,
      advance: advance == DialogueLineAdvanceKind.confirm
          ? const DialogueLineAdvancePolicy.confirm()
          : DialogueLineAdvancePolicy.autoAfterReveal(delay!),
      audioCue: cue,
    );
    feedback.validateText(scope.text);
    if (scope.feedback != null && feedback != scope.feedback) {
      throw const FormatException(
        'Ces réglages sont inscrits dans le document du dialogue. Modifiez ce document pour les changer ; aucune surcharge incompatible ne sera enregistrée.',
      );
    }
    return feedback;
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
