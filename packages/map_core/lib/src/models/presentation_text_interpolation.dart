import 'package:meta/meta.dart' show immutable;

import '../exceptions/map_exceptions.dart';
import 'scene_structured_interaction.dart';

/// Typed, deterministic text interpolation of player-visible narrative —
/// BETA-CIN-071.
///
/// One pure resolver serves every consumer (pre-session dialogue lines,
/// structured interaction prompts, Presentation caption clips, previews), so
/// the same scope always renders the same bytes. References are namespaced
/// (`{{draft.playerName}}`, `{{scene.rivalName}}`, `{{execution.locale}}`);
/// anything else — an unknown namespace, a malformed reference, escaped
/// braces — stays literal. A missing known reference follows one explicit
/// policy: the placeholder remains visible and is reported, because a
/// silently blank name is an authoring bug hidden from the author.
///
/// The scope never owns the draft: Scene builds it from validated responses
/// and hands display values to Presentation rendering. It is deliberately
/// unserializable and its diagnostics are redacted — typed player input must
/// never reach project configuration, logs or receipts.
enum PresentationDraftInterpolationField {
  playerName('playerName'),
  avatarName('avatarName'),
  starterName('starterName');

  const PresentationDraftInterpolationField(this.referenceName);

  final String referenceName;

  String get placeholder => '{{draft.$referenceName}}';
}

@immutable
final class PresentationInterpolationScope {
  PresentationInterpolationScope({
    required this.revision,
    Map<PresentationDraftInterpolationField, String> draftValues =
        const <PresentationDraftInterpolationField, String>{},
    Map<String, String> sceneValues = const <String, String>{},
    Map<String, String> executionValues = const <String, String>{},
  })  : draftValues =
            Map<PresentationDraftInterpolationField, String>.unmodifiable(
          draftValues,
        ),
        sceneValues = Map<String, String>.unmodifiable(sceneValues),
        executionValues = Map<String, String>.unmodifiable(executionValues) {
    if (revision < 0) {
      throw const ValidationException(
        'PresentationInterpolationScope.revision must not be negative',
      );
    }
    for (final name in <String>[
      ...this.sceneValues.keys,
      ...this.executionValues.keys,
    ]) {
      if (!_referenceNamePattern.hasMatch(name)) {
        throw ValidationException(
          'PresentationInterpolationScope reference names must match '
          '${_referenceNamePattern.pattern}: "$name"',
        );
      }
    }
  }

  static PresentationInterpolationScope empty() =>
      PresentationInterpolationScope(revision: 0);

  final int revision;
  final Map<PresentationDraftInterpolationField, String> draftValues;
  final Map<String, String> sceneValues;
  final Map<String, String> executionValues;

  String? resolve(String namespace, String referenceName) {
    return switch (namespace) {
      'draft' => draftValues.entries
          .where((entry) => entry.key.referenceName == referenceName)
          .map((entry) => entry.value)
          .firstOrNull,
      'scene' => sceneValues[referenceName],
      'execution' => executionValues[referenceName],
      _ => null,
    };
  }

  /// A rendering captured on an older scope must be discarded, never shown:
  /// the draft moved on after a validated response.
  bool isStaleRelativeTo(PresentationInterpolationScope current) =>
      revision < current.revision;

  /// Redacted on purpose: the values are typed player input and must never
  /// reach logs, receipts or error messages.
  @override
  String toString() =>
      'PresentationInterpolationScope(revision: $revision, '
      'draft: ${draftValues.length} value(s) <redacted>, '
      'scene: ${sceneValues.length} value(s) <redacted>, '
      'execution: ${executionValues.length} value(s) <redacted>)';
}

@immutable
final class PresentationTextInterpolationResult {
  const PresentationTextInterpolationResult({
    required this.text,
    this.missingReferences = const <String>[],
  });

  final String text;

  /// Namespaced references that matched a known namespace but had no value —
  /// reference NAMES only, never values, so the list is always loggable.
  final List<String> missingReferences;
}

final _referenceNamePattern = RegExp(r'^[A-Za-z_][A-Za-z0-9_-]*$');

final _placeholderPattern = RegExp(
  r'(\\)?\{\{\s*(draft|scene|execution)\.([A-Za-z_][A-Za-z0-9_-]*)\s*\}\}',
);

PresentationTextInterpolationResult interpolatePresentationText(
  String text,
  PresentationInterpolationScope scope,
) {
  final missing = <String>[];
  final rendered = text.replaceAllMapped(_placeholderPattern, (match) {
    if (match.group(1) != null) {
      return match.group(0)!.substring(1);
    }
    final namespace = match.group(2)!;
    final referenceName = match.group(3)!;
    final value = scope.resolve(namespace, referenceName);
    if (value == null) {
      missing.add('$namespace.$referenceName');
      return match.group(0)!;
    }
    return value;
  });
  return PresentationTextInterpolationResult(
    text: rendered,
    missingReferences: List<String>.unmodifiable(missing),
  );
}

SceneInteractionPrompt interpolateSceneInteractionPrompt(
  SceneInteractionPrompt prompt,
  PresentationInterpolationScope scope,
) {
  final fallbackText = prompt.fallbackText;
  if (fallbackText == null) return prompt;
  final rendered = interpolatePresentationText(fallbackText, scope).text;
  if (rendered == fallbackText) return prompt;
  return SceneInteractionPrompt(
    localizationKey: prompt.localizationKey,
    fallbackText: rendered,
    arguments: prompt.arguments,
  );
}

/// Rebuilds a structured interaction request with every player-visible
/// prompt interpolated against [scope]. Localization keys, arguments,
/// constraints, identities and the revision are preserved untouched.
SceneInteractionRequest interpolateSceneInteractionRequest(
  SceneInteractionRequest request,
  PresentationInterpolationScope scope,
) {
  final prompt = interpolateSceneInteractionPrompt(request.prompt, scope);
  List<SceneInteractionOption> interpolateOptions(
    List<SceneInteractionOption> options,
  ) =>
      [
        for (final option in options)
          SceneInteractionOption(
            id: option.id,
            label: interpolateSceneInteractionPrompt(option.label, scope),
            enabled: option.enabled,
          ),
      ];
  return switch (request) {
    SceneMessageInteractionRequest() => SceneInteractionRequest.message(
        requestId: request.requestId,
        revision: request.revision,
        prompt: prompt,
        timeout: request.timeout,
      ),
    SceneChoiceInteractionRequest(:final options) =>
      SceneInteractionRequest.choice(
        requestId: request.requestId,
        revision: request.revision,
        prompt: prompt,
        options: interpolateOptions(options),
        timeout: request.timeout,
      ),
    SceneTextInteractionRequest(:final constraints) =>
      SceneInteractionRequest.text(
        requestId: request.requestId,
        revision: request.revision,
        prompt: prompt,
        constraints: constraints,
        timeout: request.timeout,
      ),
    SceneConfirmationInteractionRequest() =>
      SceneInteractionRequest.confirmation(
        requestId: request.requestId,
        revision: request.revision,
        prompt: prompt,
        timeout: request.timeout,
      ),
    SceneSelectionInteractionRequest(:final options, :final constraints) =>
      SceneInteractionRequest.selection(
        requestId: request.requestId,
        revision: request.revision,
        prompt: prompt,
        options: interpolateOptions(options),
        constraints: constraints,
        timeout: request.timeout,
      ),
    _ => request,
  };
}
